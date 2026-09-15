"""Protect real shared layouts/assignments, including negatively tested candidates."""
import copy
from pathlib import Path
import runpy
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
api = runpy.run_path(str(ROOT / "scripts/check-nte-page-isolation.py"))
NS = "http://soap.sforce.com/2006/04/metadata"


def write(root, relative, body):
    path = root / relative
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(body)
    return path


def xml(kind, body=""):
    return f'<{kind} xmlns="{NS}">{body}</{kind}>'


class PageIsolationTests(unittest.TestCase):
    def test_current_complete_candidate(self):
        result = api["candidate"](ROOT / "force-app/main/default", ROOT / "manifest/production-package.xml")
        self.assertTrue(result["passed"], result)

    def test_reject_shared_manifest_components_and_wildcards(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            for kind, member in (("Profile", "Admin"), ("Layout", "Lead-Lead Layout"),
                                 ("CustomApplication", "Mission"), ("FlexiPage", "Lead_Record_Page"),
                                 ("CustomObject", "Account"), ("CompactLayout", "Contact.Compact"),
                                 ("Layout", "*"), ("CustomApplication", "*")):
                with self.subTest(kind=kind, member=member):
                    manifest = write(root, "package.xml", xml("Package", f"<types><members>{member}</members><name>{kind}</name></types>"))
                    self.assertFalse(api["candidate"](root, manifest)["passed"])

    def test_reject_shared_source_even_if_not_in_manifest(self):
        paths = ["profiles/Admin.profile-meta.xml", "layouts/Lead-Lead Layout.layout-meta.xml",
                 "applications/Mission.app-meta.xml", "flexipages/Lead_Record_Page.flexipage-meta.xml",
                 "objects/Account/Account.object-meta.xml", "objects/Contact/compactLayouts/Contact.compactLayout-meta.xml"]
        for path in paths:
            with self.subTest(path=path), tempfile.TemporaryDirectory() as tmp:
                root = Path(tmp)
                manifest = write(root, "package.xml", xml("Package"))
                write(root, path, xml("Any"))
                self.assertFalse(api["candidate"](root, manifest)["passed"])

    def test_reject_wrong_object_assignment(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            manifest = write(root, "package.xml", xml("Package"))
            write(root, "applications/NTE_Management.app-meta.xml", xml("CustomApplication",
                  "<actionOverrides><content>NTE_Management_Account_Record_Page</content><pageOrSobjectType>Contact</pageOrSobjectType></actionOverrides>"))
            self.assertFalse(api["candidate"](root, manifest)["passed"])

    def test_preservation_detects_changes_to_each_shared_definition(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            fixture = {
                "applications/Mission.app-meta.xml": xml("CustomApplication", "<tabs>standard-Lead</tabs>"),
                "flexipages/Donor.flexipage-meta.xml": xml("FlexiPage", "<masterLabel>Donor</masterLabel>"),
                "layouts/Lead-Lead Layout.layout-meta.xml": xml("Layout", "<layoutSections><label>Volunteer</label></layoutSections>"),
                "profiles/Admin.profile-meta.xml": xml("Profile", "<layoutAssignments><layout>Lead-Lead Layout</layout></layoutAssignments>"),
                **{f"objects/{obj}/{obj}.object-meta.xml": xml("CustomObject", "<actionOverrides><actionName>View</actionName><type>Default</type></actionOverrides>")
                   for obj in ("Lead", "Account", "Contact", "Opportunity")},
            }
            for path, body in fixture.items():
                write(root, path, body)
            baseline = api["snapshot"](root)
            self.assertTrue(api["compare"](baseline, api["snapshot"](root))["passed"])
            for path, body in fixture.items():
                with self.subTest(path=path):
                    write(root, path, body.replace("Lead-Lead Layout", "Lead-NTE Layout") if path.startswith("profiles")
                          else body.replace("</", "<changed>true</changed></", 1))
                    result = api["compare"](baseline, api["snapshot"](root))
                    self.assertFalse(result["passed"])
                    self.assertEqual(result["changed"], [path])
                    write(root, path, body)
            current = copy.deepcopy(baseline)
            del current["files"]["layouts/Lead-Lead Layout.layout-meta.xml"]
            self.assertFalse(api["compare"](baseline, current)["passed"])

    def test_incomplete_baseline_is_not_evidence(self):
        with tempfile.TemporaryDirectory() as tmp:
            with self.assertRaises(ValueError):
                api["snapshot"](Path(tmp))
        with self.assertRaises(ValueError):
            api["compare"]({"schema": 1, "files": {}}, {"schema": 1, "files": {}})


if __name__ == "__main__":
    unittest.main()
