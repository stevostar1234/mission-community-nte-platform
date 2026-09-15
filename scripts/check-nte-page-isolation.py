#!/usr/bin/env python3
"""Check the NTE candidate and preserve the target's existing page configuration."""
import argparse
import hashlib
import json
from pathlib import Path
import sys
import xml.etree.ElementTree as ET

NS = {"m": "http://soap.sforce.com/2006/04/metadata"}
OWNED_OBJECTS = {"NTE_Email_Dispatch__c", "NTE_Payment_Request__c", "NTE_Routing_Config__mdt", "NTE_Stripe_Config__mdt"}
PAGES = {
    "NTE_Management_Home": "standard-home",
    **{f"NTE_Management_{obj}_Record_Page": obj for obj in ("Lead", "Account", "Contact", "Opportunity")},
}
LAYOUTS = {"NTE_Email_Dispatch__c-NTE Email Dispatch", "NTE_Payment_Request__c-NTE Payment Request"}
ALLOWED = {"CustomApplication": {"NTE_Management"}, "FlexiPage": set(PAGES), "Layout": LAYOUTS,
           "Profile": set(), "CustomObject": OWNED_OBJECTS, "CompactLayout": set()}


def parse(path):
    return ET.parse(path).getroot()


def candidate(source, manifest):
    errors = []
    for group in parse(manifest).findall("m:types", NS):
        kind = group.findtext("m:name", namespaces=NS)
        if kind in ALLOWED:
            for member in group.findall("m:members", NS):
                if member.text not in ALLOWED[kind]:
                    errors.append(f"Manifest must not deploy existing/shared {kind}: {member.text}")
    folders = {"applications": (".app-meta.xml", "CustomApplication"),
               "flexipages": (".flexipage-meta.xml", "FlexiPage"),
               "layouts": (".layout-meta.xml", "Layout"), "profiles": (".profile-meta.xml", "Profile")}
    for folder, (suffix, kind) in folders.items():
        for path in (source / folder).glob("*" + suffix):
            name = path.name.removesuffix(suffix)
            if name not in ALLOWED[kind]:
                errors.append(f"Source contains an existing/shared {kind}: {path.relative_to(source)}")
    for path in (source / "objects").glob("*/*.object-meta.xml"):
        if path.parent.name not in OWNED_OBJECTS:
            errors.append(f"Source must not overwrite shared object defaults: {path.relative_to(source)}")
    for path in (source / "objects").glob("*/compactLayouts/*.compactLayout-meta.xml"):
        errors.append(f"Source must not replace compact layouts: {path.relative_to(source)}")
    app_path = source / "applications/NTE_Management.app-meta.xml"
    if app_path.exists():
        app = parse(app_path)
        for tag in ("actionOverrides", "profileActionOverrides"):
            for override in app.findall("m:" + tag, NS):
                content = override.findtext("m:content", namespaces=NS)
                target = override.findtext("m:pageOrSobjectType", namespaces=NS)
                if content and (content not in PAGES or PAGES[content] != target):
                    errors.append(f"Unexpected NTE app page assignment: {target} -> {content}")
    for page, obj in PAGES.items():
        path = source / "flexipages" / (page + ".flexipage-meta.xml")
        if path.exists() and obj != "standard-home" and parse(path).findtext("m:sobjectType", namespaces=NS) != obj:
            errors.append(f"NTE page targets the wrong object: {page}")
    return {"passed": not errors, "errors": errors}


def canonical(element):
    return [element.tag, sorted(element.attrib.items()), (element.text or "").strip(),
            [canonical(child) for child in element]]


def snapshot(source):
    files = {}
    for folder, suffix, owned in (
        ("applications", ".app-meta.xml", {"NTE_Management"}),
        ("flexipages", ".flexipage-meta.xml", set(PAGES)),
        ("layouts", ".layout-meta.xml", LAYOUTS),
        ("profiles", ".profile-meta.xml", set()),
    ):
        for path in sorted((source / folder).glob("*" + suffix)):
            if path.name.removesuffix(suffix) in owned:
                continue
            root = parse(path)
            if folder == "profiles":
                # FLS additions are separate from the existing page assignments.
                value = sorted([canonical(x) for tag in ("layoutAssignments", "profileActionOverrides")
                                for x in root.findall("m:" + tag, NS)], key=lambda x: json.dumps(x))
            else:
                value = canonical(root)
            files[str(path.relative_to(source))] = hashlib.sha256(json.dumps(value).encode()).hexdigest()
    for path in sorted((source / "objects").glob("*/*.object-meta.xml")):
        if path.parent.name in OWNED_OBJECTS:
            continue
        root = parse(path)
        value = sorted([canonical(x) for tag in ("actionOverrides", "compactLayoutAssignment", "searchLayouts")
                        for x in root.findall("m:" + tag, NS)], key=lambda x: json.dumps(x))
        files[str(path.relative_to(source))] = hashlib.sha256(json.dumps(value).encode()).hexdigest()
    # These types must actually have been retrieved; an empty backup is not proof.
    missing = [folder for folder in ("applications", "flexipages", "layouts", "profiles")
               if not any(name.startswith(folder + "/") for name in files)]
    for obj in ("Lead", "Account", "Contact", "Opportunity"):
        if f"objects/{obj}/{obj}.object-meta.xml" not in files:
            missing.append(obj + " object defaults")
    if missing:
        raise ValueError("Incomplete target retrieval: " + ", ".join(missing))
    return {"schema": 1, "files": files}


def compare(baseline, current):
    if baseline.get("schema") != 1 or not baseline.get("files"):
        raise ValueError("Invalid or empty page baseline")
    missing = sorted(set(baseline["files"]) - set(current["files"]))
    changed = sorted(name for name, value in baseline["files"].items()
                     if name in current["files"] and current["files"][name] != value)
    added = sorted(set(current["files"]) - set(baseline["files"]))
    return {"passed": not (missing or changed or added), "compared": len(baseline["files"]),
            "missing": missing, "changed": changed, "addedSharedDefinitions": added}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("mode", choices=("candidate", "snapshot", "compare"))
    parser.add_argument("--source-dir", type=Path, required=True)
    parser.add_argument("--manifest", type=Path)
    parser.add_argument("--baseline", type=Path)
    parser.add_argument("--output", type=Path)
    args = parser.parse_args()
    try:
        if args.mode == "candidate":
            if not args.manifest:
                parser.error("candidate requires --manifest")
            result = candidate(args.source_dir, args.manifest)
        else:
            current = snapshot(args.source_dir)
            if args.mode == "snapshot":
                if not args.output:
                    parser.error("snapshot requires --output")
                if args.output.exists():
                    raise ValueError("Do not overwrite the saved target baseline")
                result = current
            else:
                if not args.baseline:
                    parser.error("compare requires --baseline")
                result = compare(json.loads(args.baseline.read_text()), current)
        if args.output:
            args.output.write_text(json.dumps(result, indent=2) + "\n")
        print(json.dumps({"captured": len(result["files"])} if "files" in result else result))
        return 0 if result.get("passed", True) else 1
    except (ET.ParseError, OSError, ValueError) as error:
        print(json.dumps({"passed": False, "errors": [str(error)]}))
        return 1


if __name__ == "__main__":
    sys.exit(main())
