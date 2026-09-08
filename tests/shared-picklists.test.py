"""Check that production overlays preserve existing CRM semantics."""
import importlib.util
from pathlib import Path
import tempfile
import unittest
import xml.etree.ElementTree as ET

MODULE = Path(__file__).resolve().parents[1] / "scripts/prepare-shared-picklists.py"
SPEC = importlib.util.spec_from_file_location("picklists", MODULE)
picklists = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(picklists)


def values(*entries):
    root = ET.Element(picklists.tag("StandardValueSet"))
    ET.SubElement(root, picklists.tag("sorted")).text = "false"
    for entry in entries:
        value = ET.SubElement(root, picklists.tag("standardValue"))
        for key, content in entry.items():
            ET.SubElement(value, picklists.tag(key)).text = content
    return root


class SharedPicklistsTest(unittest.TestCase):
    def test_keeps_target_values_default_and_probability(self):
        required = values(dict(fullName="Qualification", default="false", closed="false", won="false", probability="10"),
                          dict(fullName="Proposal", default="false", closed="false", won="false", probability="75"))
        target = values(dict(fullName="Qualification", default="false", closed="false", won="false", probability="20"),
                        dict(fullName="Other team stage", default="true", closed="false", won="false", probability="5"))
        before = ET.tostring(target)
        merged, report = picklists.merge_values(required, target, "OpportunityStage")
        index = picklists.index_values(merged)
        self.assertEqual(index["Qualification"].findtext(picklists.tag("probability")), "20")
        self.assertEqual(index["Other team stage"].findtext(picklists.tag("default")), "true")
        self.assertEqual(report["added"], ["Proposal"])
        self.assertEqual(ET.tostring(target), before)
        self.assertEqual(report["retained_differences"][0]["target_attributes_preserved"], ["probability"])

    def test_rejects_conflicting_won_semantics(self):
        required = values(dict(fullName="Closed Won", closed="true", won="true"))
        target = values(dict(fullName="Closed Won", closed="true", won="false"))
        with self.assertRaisesRegex(ValueError, "incompatible won"):
            picklists.merge_values(required, target, "OpportunityStage")

    def test_rejects_duplicate_names(self):
        with self.assertRaisesRegex(ValueError, "duplicate"):
            picklists.index_values(values(dict(fullName="A"), dict(fullName="A")))

    def test_new_value_cannot_replace_target_default(self):
        required = values(dict(fullName="Customer Event", default="true"))
        target = values(dict(fullName="Existing", default="true"))
        merged, _ = picklists.merge_values(required, target, "LeadSource")
        self.assertEqual(picklists.index_values(merged)["Customer Event"].findtext(picklists.tag("default")), "false")

    def test_missing_snapshot_leaves_no_partial_overlay(self):
        with tempfile.TemporaryDirectory() as directory:
            base = Path(directory)
            for kind in ("required", "target"):
                file = picklists.metadata_file(base / kind, "LeadSource")
                file.parent.mkdir(parents=True)
                ET.ElementTree(values(dict(fullName="Customer Event"))).write(file)
            with self.assertRaisesRegex(ValueError, "retrieve the complete target"):
                picklists.prepare(base / "required", base / "target", base / "output")
            self.assertFalse((base / "output").exists())


if __name__ == "__main__":
    unittest.main()
