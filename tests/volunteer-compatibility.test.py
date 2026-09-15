import copy
import importlib.util
from pathlib import Path
import unittest
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location('volunteer_overlay', ROOT / 'scripts/build-volunteer-overlay.py')
overlay = importlib.util.module_from_spec(spec)
spec.loader.exec_module(overlay)
NS = overlay.NS


def xml(body, tag):
    return ET.fromstring(f'<{tag} xmlns="{overlay.URI}">{body}</{tag}>')


class VolunteerCompatibility(unittest.TestCase):
    def test_existing_layout_content_and_requiredness_are_preserved(self):
        before = xml('<layoutSections><label>Personal details</label><layoutColumns><layoutItems>'
                     '<behavior>Required</behavior><field>Name</field></layoutItems><layoutItems>'
                     '<behavior>Edit</behavior><field>Date_of_Birth__c</field></layoutItems></layoutColumns>'
                     '<style>OneColumn</style></layoutSections><showEmailCheckbox>true</showEmailCheckbox>', 'Layout')
        after = overlay.extend_layout(before, 'Lead')
        self.assertEqual(overlay.canon(before[0]), overlay.canon(after[0]))
        self.assertEqual(overlay.canon(before[-1]), overlay.canon(after[-1]))
        old_count = len(before.findall('.//m:field', NS))
        self.assertGreater(len(after.findall('.//m:field', NS)), old_count)
        self.assertEqual(1, len(after.findall('.//m:behavior[.="Required"]', NS)))
        self.assertEqual(1, len(after.findall('.//m:field[.="Date_of_Birth__c"]', NS)))
        self.assertEqual(overlay.canon(after), overlay.canon(overlay.extend_layout(after, 'Lead')))

    def test_person_accounts_use_contact_aliases_not_duplicate_account_fields(self):
        fields = [field for _, fields in overlay.groups_for('PersonAccount') for field in fields]
        self.assertIn('Volunteer_Hours__pc', fields)
        self.assertIn('Birthdate__pc', fields)
        self.assertIn('PersonMobilePhone', fields)
        self.assertFalse(any(field.endswith('__c') for field in fields))

    def test_all_new_answers_have_optional_compatible_destinations(self):
        base = ROOT / 'force-app/main/default/objects'
        for api in overlay.ANSWERS:
            lead = ET.parse(base / 'Lead/fields' / (api + '.field-meta.xml')).getroot()
            contact = ET.parse(base / 'Contact/fields' / (api + '.field-meta.xml')).getroot()
            self.assertEqual(overlay.canon(lead), overlay.canon(contact), api)
            self.assertEqual('false', contact.findtext('m:required', namespaces=NS), api)
        self.assertNotIn('Declaration_Name__c', overlay.ANSWERS)
        self.assertNotIn('Declaration_Date__c', overlay.ANSWERS)
        self.assertNotIn('Volunteer_Email_Error__c', overlay.ANSWERS)

    def test_conversion_appends_without_changing_existing_mappings(self):
        before = xml('<allowOwnerChange>true</allowOwnerChange><objectMapping><inputObject>Lead</inputObject>'
                     '<mappingFields><inputField>Date_of_Birth__c</inputField><outputField>Birthdate__c</outputField></mappingFields>'
                     '<outputObject>Contact</outputObject></objectMapping><opportunityCreationOptions>VisibleOptional</opportunityCreationOptions>',
                     'LeadConvertSettings')
        after = overlay.extend_mappings(before)
        self.assertEqual(overlay.canon(before.find('.//m:mappingFields', NS)), overlay.canon(after.find('.//m:mappingFields', NS)))
        self.assertEqual('VisibleOptional', after.findtext('m:opportunityCreationOptions', namespaces=NS))
        self.assertEqual(16, len(after.findall('.//m:mappingFields', NS)))
        self.assertEqual(overlay.canon(after), overlay.canon(overlay.extend_mappings(after)))
        conflict = copy.deepcopy(before)
        conflict.find('.//m:inputField', NS).text = 'Volunteer_Hours__c'
        with self.assertRaisesRegex(ValueError, 'conflicts'):
            overlay.extend_mappings(conflict)

    def test_dynamic_form_extensions_preserve_old_sections_and_app_scope(self):
        before = xml('<flexiPageRegions><itemInstances><componentInstance>'
                     '<componentInstanceProperties><name>body</name><value>Details</value></componentInstanceProperties>'
                     '<componentInstanceProperties><name>title</name><value>Standard.Tab.detail</value></componentInstanceProperties>'
                     '<componentName>flexipage:tab</componentName><identifier>OriginalTab</identifier></componentInstance></itemInstances>'
                     '<name>Tabs</name><type>Facet</type></flexiPageRegions>'
                     '<flexiPageRegions><itemInstances><componentInstance><componentName>force:detailPanel</componentName>'
                     '<identifier>OriginalDetails</identifier></componentInstance></itemInstances><name>Details</name><type>Facet</type></flexiPageRegions>'
                     '<masterLabel>Existing Mission page</masterLabel><sobjectType>Account</sobjectType><type>RecordPage</type>', 'FlexiPage')
        after = overlay.extend_page(before)
        self.assertEqual(overlay.canon(before[0]), overlay.canon(after[0]))
        self.assertEqual(overlay.canon(before[1][0]), overlay.canon(after[1][0]))
        self.assertEqual('Existing Mission page', after.findtext('m:masterLabel', namespaces=NS))
        rules = after.findall('.//m:visibilityRule', NS)
        self.assertTrue(rules)
        for rule in rules:
            self.assertEqual('1 OR 2', rule.findtext('m:booleanFilter', namespaces=NS))
            self.assertEqual(['{!Record.Is_Volunteer__pc}', '{!Record.RecordType.DeveloperName}'], [x.text for x in rule.findall('.//m:leftValue', NS)])
        self.assertFalse(after.findall('.//m:value[.="required"]', NS))
        self.assertEqual(overlay.canon(after), overlay.canon(overlay.extend_page(after)))

    def test_form_and_lists_cover_new_and_legacy_routes(self):
        form = (ROOT / 'volunteer-application.html').read_text()
        self.assertNotIn('data-sf-field="Company"', form)
        self.assertIn('data-sf-field="Date_of_Birth__c"', form)
        self.assertIn('data-sf-field="Interested_in_Volunteering__c"', form)
        view = ET.parse(ROOT / 'force-app/main/default/objects/Lead/listViews/Volunteer_Applications.listView-meta.xml').getroot()
        self.assertEqual('1 OR 2 OR 3', view.findtext('m:booleanFilter', namespaces=NS))
        self.assertEqual(['Web_Form_Type__c', 'Interested_in_Volunteering__c', 'LEAD.LEAD_SOURCE'],
                         [x.text for x in view.findall('m:filters/m:field', NS)])


if __name__ == '__main__':
    unittest.main()
