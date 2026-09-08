#!/usr/bin/env python3
"""Audit the package against a local, read-only Salesforce metadata snapshot.

Uses exact object/field identities where available. Does not connect to an org,
overwrite the historical dependency inventory, or claim the Tooling graph covers
all Salesforce metadata. Output contains metadata references, not record exports.
"""
from __future__ import annotations

import argparse
from collections import Counter, defaultdict
import hashlib
import json
from pathlib import Path
import re
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[1]
NS = {"m": "http://soap.sforce.com/2006/04/metadata"}
CORE = {"Lead", "Account", "Contact", "Opportunity"}


def manifest(path):
    return {node.findtext("m:name", namespaces=NS): {v.text for v in node.findall("m:members", NS)}
            for node in ET.parse(path).getroot().findall("m:types", NS)}


def records(path):
    result = json.loads(path.read_text())
    if result.get("status") != 0 or not result.get("result", {}).get("done", False):
        raise ValueError(f"Incomplete or failed query: {path.name}")
    return result["result"]["records"]


def audit(snapshot):
    source = ROOT / "force-app/main/default"
    members = manifest(ROOT / "manifest/production-package.xml")
    inherited = manifest(ROOT / "manifest/production-external-dependencies.xml")["CustomField"]
    field_paths = {f"{p.parts[-3]}.{p.name.removesuffix('.field-meta.xml')}": p
                   for p in (source / "objects").glob("*/fields/*.field-meta.xml")}
    missing = [{"kind": "manifest_field_without_source", "name": name}
               for name in sorted(members["CustomField"] - field_paths.keys())]
    missing += [{"kind": "source_field_not_in_manifest", "name": name}
                for name in sorted(field_paths.keys() - members["CustomField"])]
    missing += [{"kind": "inherited_field_missing", "name": name}
                for name in sorted(inherited - (field_paths.keys() & members["CustomField"]))]

    object_ids = {r["Id"]: r["DeveloperName"] for r in records(snapshot / "custom-object-identities.json")}
    custom_objects = {p.name.rsplit("__", 1)[0]: p.name for p in (source / "objects").iterdir() if "__" in p.name}
    field_ids = {}
    for row in records(snapshot / "custom-field-identities.json"):
        table = row["TableEnumOrId"]
        obj = custom_objects.get(object_ids.get(table), table)
        field_ids[row["Id"]] = f"{obj}.{row['DeveloperName']}__c"
    selected, platform, external = [], set(), defaultdict(set)
    graph = records(snapshot / "component-dependencies.json")
    for row in graph:
        kind, name = row["MetadataComponentType"], row["MetadataComponentName"]
        if kind == "CustomField":
            ours = field_ids.get(row["MetadataComponentId"]) in members.get(kind, set())
        elif kind == "EmailTemplate":
            ours = name in {v.rsplit("/", 1)[-1] for v in members.get(kind, set())}
        elif kind == "Layout":
            ours = any(v.endswith("-" + name) for v in members.get(kind, set()))
        else:
            ours = name in members.get(kind, set())
        if not ours:
            continue
        selected.append(row)
        ref_kind, ref_name, ref_id = (row["RefMetadataComponentType"], row["RefMetadataComponentName"],
                                      row["RefMetadataComponentId"])
        if ref_kind == "StandardEntity" or ref_id == ref_name:
            platform.add(ref_name)
            continue
        if ref_kind == "CustomField":
            qualified = field_ids.get(ref_id, "UNRESOLVED:" + ref_name)
        elif ref_kind == "CustomObject":
            qualified = custom_objects.get(ref_name, ref_name + "__c")
        else:
            qualified = ref_name
        covered = qualified in members.get(ref_kind, set())
        if ref_kind in ("EmailTemplate", "RecordType"):
            separator = "/" if ref_kind == "EmailTemplate" else "."
            covered |= any(v.endswith(separator + ref_name) for v in members.get(ref_kind, set()))
        if not covered:
            external[(ref_kind, qualified)].add(f"{kind}:{name}")

    runtime_files = [p for directory in (source, ROOT / "assets", ROOT / "email-templates", ROOT / "tests")
                     for p in directory.rglob("*") if p.is_file() and p.suffix in (".cls", ".xml", ".js", ".html", ".cmp")]
    runtime_files += list(ROOT.glob("*.html"))
    tokens = set()
    for path in runtime_files:
        tokens.update(re.findall(r"\b[A-Za-z][A-Za-z0-9_]*__c\b", path.read_text(errors="replace")))
    local_names = {v.split(".", 1)[1] for v in field_paths}
    lexical_missing = []
    retrieved = snapshot / "org-snapshot/force-app/main/default"
    for path in (retrieved / "objects").glob("*/fields/*.field-meta.xml"):
        api = path.name.removesuffix(".field-meta.xml")
        if path.parts[-3] in CORE and api in tokens and api not in local_names:
            lexical_missing.append(f"{path.parts[-3]}.{api}")

    stages = [v.text for v in ET.parse(source / "objects/Opportunity/businessProcesses/NTE_Sales_Process.businessProcess-meta.xml").getroot().findall("m:values/m:fullName", NS)]
    stage_file = source / "standardValueSets/OpportunityStage.standardValueSet-meta.xml"
    packaged_stages = set()
    if stage_file.exists():
        packaged_stages = {v.text for v in ET.parse(stage_file).getroot().findall("m:standardValue/m:fullName", NS)}
    if "OpportunityStage" not in members.get("StandardValueSet", set()) or set(stages) - packaged_stages:
        missing.append({"kind": "sales_stage_dependency", "name": "OpportunityStage", "required_values": stages})
    value_sets = sorted({v.text for p in field_paths.values()
                         for v in ET.parse(p).getroot().findall(".//m:valueSetName", NS)})
    for name in value_sets:
        if name not in members.get("GlobalValueSet", set()):
            missing.append({"kind": "global_value_set", "name": name})
    matching = [{k: r[k] for k in ("DeveloperName", "SobjectType", "RuleStatus")}
                for r in records(snapshot / "matching-rule-inventory.json")]
    active_flows = [r["DeveloperName"] for r in records(snapshot / "flow-inventory.json") if r.get("ActiveVersionId")]
    unresolved = [{"kind": kind, "name": name, "sources": sorted(sources)}
                  for (kind, name), sources in sorted(external.items())]
    return {
        "status": "no_unresolved_scanned_metadata_dependencies" if not (missing or unresolved or lexical_missing) else "needs_review",
        "inherited_fields": {"expected": len(inherited), "present_in_source_and_manifest": len(inherited & field_paths.keys() & members["CustomField"])},
        "package_custom_fields": len(field_paths), "custom_fields_by_object": dict(sorted(Counter(k.split('.')[0] for k in field_paths).items())),
        "tooling_graph": {"total_edges": len(graph), "exact_package_edges": len(selected),
                          "indexed_source_types": sorted({r['MetadataComponentType'] for r in selected}),
                          "platform_entities": sorted(platform)},
        "missing_manifest_or_schema": missing, "external_graph_references": unresolved,
        "unpackaged_referenced_snapshot_fields": sorted(lexical_missing), "global_value_sets_referenced": value_sets,
        "sales_process_values": stages, "required_standard_matching_rule": "Contact.Standard_Contact_Match_Rule_v1_1",
        "matching_rule_observations": matching, "unmanaged_triggers_observed": len(records(snapshot / "trigger-inventory.json")),
        "active_flows_outside_package": sorted(set(active_flows) - members.get("Flow", set())),
        "evidence_sha256": {p.name: hashlib.sha256(p.read_bytes()).hexdigest() for p in sorted(snapshot.glob("*-identities.json")) + sorted(snapshot.glob("*-inventory.json")) + [snapshot / "component-dependencies.json"]},
        "limitations": ["Source and MMUAT snapshot only; production has not been inspected.",
                        "The Tooling graph is partial and does not cover every Flow, LWC, dynamic reference or org setting.",
                        "Shared picklists, duplicate/matching rules, routing, permissions and sender settings need target-specific preflight.",
                        "A successful existing sandbox is not proof of installation in a clean or production org."]
    }


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--snapshot", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()
    report = audit(args.snapshot)
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(report, indent=2) + "\n")
    print(json.dumps({k: report[k] for k in ("status", "inherited_fields", "package_custom_fields", "tooling_graph", "missing_manifest_or_schema", "external_graph_references")}))
    return 0 if report["status"].startswith("no_unresolved") else 1


if __name__ == "__main__":
    raise SystemExit(main())
