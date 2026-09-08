#!/usr/bin/env python3
"""Count maintained project text with explicit categories; no dependency install.

Physical lines include blank lines and comments. Also reports nonblank lines.
Documentation, audit exports, temporary files, binaries and Git history are not
counted as code. Generated metadata and email examples remain separate categories.
"""
import argparse
from collections import defaultdict
import hashlib
import json
from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[1]


def category(path, content):
    rel = path.relative_to(ROOT).as_posix()
    if rel.startswith("force-app/main/default/"):
        if path.suffix == ".cls":
            return "Apex tests" if re.search(r"(?im)^\s*@IsTest\b", content) else "Apex application"
        if path.name.endswith(".xml"):
            return "Salesforce metadata"
        if path.suffix == ".email":
            return "Salesforce email templates"
        if "/lwc/" in rel or "/aura/" in rel:
            return "Salesforce interface"
    if path.parent == ROOT and path.suffix == ".html" or rel.startswith("assets/") and path.suffix in (".js", ".css", ".svg"):
        return "Public forms and assets"
    if rel.startswith("email-templates/") and path.suffix == ".html":
        return "Email sources and previews"
    if rel.startswith("tests/") and path.suffix in (".js", ".py", ".mjs"):
        return "Local tests"
    if rel.startswith("scripts/") and path.suffix in (".js", ".py", ".mjs", ".apex"):
        return "Build, audit and deployment scripts"
    if rel.startswith(("manifest/", "config/")) and path.suffix in (".json", ".xml") or rel in ("package.json", "sfdx-project.json"):
        return "Project configuration and manifests"
    return None


def measure():
    groups = defaultdict(lambda: {"files": 0, "physical_lines": 0, "nonblank_lines": 0})
    inventory = []
    candidates = list(ROOT.glob("*.html")) + [ROOT / "package.json", ROOT / "sfdx-project.json"]
    for folder in ("force-app", "assets", "email-templates", "tests", "scripts", "manifest", "config"):
        candidates.extend(p for p in (ROOT / folder).rglob("*") if p.is_file() and "__pycache__" not in p.parts)
    for path in sorted(set(candidates)):
        data = path.read_bytes()
        try:
            text = data.decode("utf-8")
        except UnicodeDecodeError:
            continue
        group = category(path, text)
        if not group:
            continue
        values = {"files": 1, "physical_lines": len(text.splitlines()),
                  "nonblank_lines": sum(bool(line.strip()) for line in text.splitlines())}
        for key, value in values.items():
            groups[group][key] += value
        inventory.append({"path": path.relative_to(ROOT).as_posix(), "category": group,
                          "sha256": hashlib.sha256(data).hexdigest(), **values})
    totals = {k: sum(v[k] for v in groups.values()) for k in ("files", "physical_lines", "nonblank_lines")}
    return {"method": "Physical lines including blanks/comments; nonblank lines also supplied. No claim of comment-stripped logical LOC.",
            "excluded": ["Documentation", "audit records and screenshots", "temporary snapshots", "binaries", "Git history", "installed dependencies"],
            "categories": dict(sorted(groups.items())), "totals": totals, "files": inventory}


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()
    result = measure()
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(result, indent=2) + "\n")
    print(json.dumps({"categories": result["categories"], "totals": result["totals"]}, indent=2))
