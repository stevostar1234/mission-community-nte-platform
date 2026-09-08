#!/usr/bin/env python3
"""Prepare a local release overlay without removing target-org picklist values.

Read only local metadata snapshots. No Salesforce login, deployment or data writes.
The output must be inspected and applied to a separate release working copy before
that exact copy is validated. Never apply the MMUAT baseline blindly to production.
"""
from __future__ import annotations

import argparse
import copy
import hashlib
import json
from pathlib import Path
import xml.etree.ElementTree as ET

NS = "http://soap.sforce.com/2006/04/metadata"
ET.register_namespace("", NS)
SETS = ("LeadSource", "OpportunityStage")
CRITICAL = {"OpportunityStage": ("closed", "won"), "LeadSource": ()}


def tag(name: str) -> str:
    return f"{{{NS}}}{name}"


def index_values(root: ET.Element) -> dict[str, ET.Element]:
    values = {}
    for value in root.findall(tag("standardValue")):
        name = value.findtext(tag("fullName"))
        if not name or name in values:
            raise ValueError(f"Missing or duplicate picklist API name: {name!r}")
        values[name] = value
    return values


def merge_values(required: ET.Element, target: ET.Element, name: str):
    if required.tag != tag("StandardValueSet") or target.tag != required.tag:
        raise ValueError(f"{name}: expected StandardValueSet metadata")
    required_values, target_values = index_values(required), index_values(target)
    merged = copy.deepcopy(target)
    added, retained_differences = [], []
    for api, value in required_values.items():
        if api in target_values:
            current = target_values[api]
            for key in CRITICAL[name]:
                expected = value.findtext(tag(key))
                actual = current.findtext(tag(key))
                if expected != actual:
                    raise ValueError(f"{name}.{api}: incompatible {key}: expected {expected!r}, target {actual!r}")
            expected_values = {c.tag: c.text for c in value}
            actual_values = {c.tag: c.text for c in current}
            changed = [k.split("}")[-1] for k in set(expected_values) | set(actual_values)
                       if expected_values.get(k) != actual_values.get(k)]
            if changed:
                retained_differences.append({"value": api, "target_attributes_preserved": sorted(changed)})
        else:
            extra = copy.deepcopy(value)
            default = extra.find(tag("default"))
            if default is not None:
                default.text = "false"
            merged.append(extra)
            added.append(api)
    return merged, {"added": added, "target_values_preserved": len(target_values),
                    "retained_differences": retained_differences}


def metadata_file(base: Path, name: str) -> Path:
    return base / "standardValueSets" / f"{name}.standardValueSet-meta.xml"


def prepare(required_dir: Path, target_dir: Path, output_dir: Path):
    for original in (required_dir, target_dir):
        if output_dir.resolve() == original.resolve() or original.resolve() in output_dir.resolve().parents:
            raise ValueError("Write the overlay outside both source metadata directories")
    if output_dir.exists() and any(output_dir.iterdir()):
        raise ValueError("Use a new or empty output directory; existing release evidence is preserved")
    prepared, results = {}, {}
    for name in SETS:
        required_path, target_path = metadata_file(required_dir, name), metadata_file(target_dir, name)
        if not required_path.is_file() or not target_path.is_file():
            raise ValueError(f"{name}: retrieve the complete target value set before preparing an overlay")
        required_bytes, target_bytes = required_path.read_bytes(), target_path.read_bytes()
        merged, detail = merge_values(ET.fromstring(required_bytes), ET.fromstring(target_bytes), name)
        ET.indent(merged, space="    ")
        prepared[name] = ET.tostring(merged, encoding="utf-8", xml_declaration=True) + b"\n"
        results[name] = {**detail, "required_sha256": hashlib.sha256(required_bytes).hexdigest(),
                         "target_sha256": hashlib.sha256(target_bytes).hexdigest(),
                         "output_sha256": hashlib.sha256(prepared[name]).hexdigest()}
    # Validate every set before writing any overlay. Conflicts leave no candidate.
    output_dir.mkdir(parents=True, exist_ok=True)
    for name, data in prepared.items():
        output = metadata_file(output_dir, name)
        output.parent.mkdir(parents=True, exist_ok=True)
        output.write_bytes(data)
    report = {"status": "prepared_for_review", "sets": results,
              "next_step": "Inspect retained differences, apply to an isolated release copy, and validate that exact copy against the target org."}
    (output_dir / "merge-report.json").write_text(json.dumps(report, indent=2) + "\n")
    return report


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--required-dir", type=Path, default=Path(__file__).resolve().parents[1] / "force-app/main/default")
    parser.add_argument("--target-dir", type=Path, required=True, help="Retrieved target force-app/main/default")
    parser.add_argument("--output-dir", type=Path, required=True, help="New local overlay directory")
    args = parser.parse_args()
    try:
        report = prepare(args.required_dir, args.target_dir, args.output_dir)
    except (ValueError, OSError, ET.ParseError) as error:
        parser.exit(1, f"Overlay not prepared: {error}\n")
    print(json.dumps(report, indent=2))


if __name__ == "__main__":
    main()
