#!/usr/bin/env python3
"""Extend freshly retrieved Mission pages/mappings without replacing old content.

Output is a separate, target-specific deployment, never part of the NTE core
manifest. Rebuild against the actual target immediately before qualification.
"""
import argparse
import copy
import hashlib
import json
from pathlib import Path
import re
import xml.etree.ElementTree as ET

URI = 'http://soap.sforce.com/2006/04/metadata'
NS = {'m': URI}
ET.register_namespace('', URI)
ANSWERS = [
    'NOK_Address__c', 'NOK_Postcode__c', 'Volunteer_Armed_Forces_Service__c',
    'Volunteer_Service_Details__c', 'Volunteer_Service_Dates__c', 'Volunteer_Opportunities__c',
    'Volunteer_Skills__c', 'Volunteer_Hours__c', 'Volunteer_Availability__c',
    'Volunteer_Travel_Regions__c', 'Volunteer_DBS_Willing__c', 'Volunteer_Consent__c',
    'Volunteer_Code_Consent__c', 'Volunteer_Code_Version__c', 'Volunteer_Form_Version__c',
]
GROUPS = [
    ('Volunteer application', ['Volunteer_Opportunities__c', 'Volunteer_Skills__c',
     'Volunteer_Hours__c', 'Volunteer_Availability__c', 'Volunteer_Travel_Regions__c', 'Volunteer_DBS_Willing__c']),
    ('Volunteer service details', ['Volunteer_Armed_Forces_Service__c', 'Volunteer_Service_Details__c', 'Volunteer_Service_Dates__c']),
    ('Volunteer emergency contact', ['NOK_Name__c', 'NOK_Relationship__c', 'NOK_Phone__c', 'NOK_Address__c', 'NOK_Postcode__c']),
    ('Volunteer declaration', ['Volunteer_Consent__c', 'Volunteer_Code_Consent__c', 'Volunteer_Code_Version__c',
     'Volunteer_Declaration_Name__c', 'Volunteer_Declaration_Date__c', 'Volunteer_Form_Version__c']),
]
DEFAULT_CONFIG = {
    'layouts': {'Lead-Lead Layout': 'Lead', 'Contact-Contact Layout': 'Contact',
                'PersonAccount-Person Account Layout': 'PersonAccount'},
    'pages': ['Beneficiary_Two_Column', 'Donor_Two_Column', 'Account_Record_Page_Two_Column'],
}


def sub(parent, tag, text=None):
    item = ET.SubElement(parent, '{' + URI + '}' + tag)
    if text is not None:
        item.text = text
    return item


def canon(item):
    return [item.tag, sorted(item.attrib.items()), (item.text or '').strip(), [canon(x) for x in item]]


def digest(item):
    return hashlib.sha256(json.dumps(canon(item)).encode()).hexdigest()


def groups_for(obj):
    groups = copy.deepcopy(GROUPS)
    personal = ['MobilePhone', 'Date_of_Birth__c', 'Interested_in_Volunteering__c'] if obj == 'Lead' else [
        'MobilePhone' if obj == 'Contact' else 'PersonMobilePhone', 'Birthdate__c', 'Is_Volunteer__c']
    groups.insert(0, ('Volunteer contact and consent', personal + ['Consent_PII__c', 'Consent_Contact__c', 'Consent_Promotion__c']))
    if obj == 'Lead':
        groups = [(label, [x.replace('Volunteer_Declaration_', 'Declaration_') for x in fields]) for label, fields in groups]
        groups.append(('Volunteer application messages', ['Volunteer_Applicant_Email_Status__c', 'Volunteer_Internal_Email_Status__c', 'Volunteer_Email_Error__c']))
    if obj == 'PersonAccount':
        groups = [(label, [x[:-3] + '__pc' if x.endswith('__c') else x for x in fields]) for label, fields in groups]
    return groups


def extend_layout(original, obj):
    result = copy.deepcopy(original)
    existing = {x.text for x in result.findall('.//m:field', NS)}
    # Add beside the current sections without rewriting any existing section.
    insertion = max(i for i, x in enumerate(result) if x.tag.endswith('}layoutSections')) + 1
    for label, fields in groups_for(obj):
        missing = [x for x in fields if x not in existing]
        if not missing:
            continue
        if any(x.findtext('m:label', namespaces=NS) == label for x in result.findall('m:layoutSections', NS)):
            raise ValueError('Existing section needs review rather than replacement: ' + label)
        section = ET.Element('{' + URI + '}layoutSections')
        for tag, value in [('customLabel', 'true'), ('detailHeading', 'true'), ('editHeading', 'true'), ('label', label)]:
            sub(section, tag, value)
        for column_fields in (missing[::2], missing[1::2]):
            column = sub(section, 'layoutColumns')
            for field in column_fields:
                item = sub(column, 'layoutItems')
                sub(item, 'behavior', 'Edit')
                sub(item, 'field', field)
        sub(section, 'style', 'TwoColumnsLeftToRight')
        result.insert(insertion, section)
        insertion += 1
        existing.update(missing)
    return result


def component(parent, name, identifier, props):
    comp = sub(sub(parent, 'itemInstances'), 'componentInstance')
    for key, value in props:
        prop = sub(comp, 'componentInstanceProperties')
        sub(prop, 'name', key)
        sub(prop, 'value', value)
    sub(comp, 'componentName', name)
    sub(comp, 'identifier', identifier)
    return comp


def extend_page(original, volunteer_record_type='Volunteer'):
    if original.findtext('m:sobjectType', namespaces=NS) != 'Account':
        raise ValueError('Volunteer Person Account extension must target an Account page')
    result = copy.deepcopy(original)
    tabs = []
    for comp in result.findall('.//m:componentInstance', NS):
        if comp.findtext('m:componentName', namespaces=NS) != 'flexipage:tab':
            continue
        props = {x.findtext('m:name', namespaces=NS): x.findtext('m:value', namespaces=NS)
                 for x in comp.findall('m:componentInstanceProperties', NS)}
        if props.get('title') == 'Standard.Tab.detail':
            tabs.append(props.get('body'))
    if len(tabs) != 1:
        raise ValueError('Expected one existing Details tab; review this target page manually')
    region = next(x for x in result.findall('m:flexiPageRegions', NS) if x.findtext('m:name', namespaces=NS) == tabs[0])
    existing = {x.text.removeprefix('Record.') for x in result.findall('.//m:fieldItem', NS)}
    insertion = max(i for i, x in enumerate(result) if x.tag.endswith('}flexiPageRegions')) + 1
    for index, (label, fields) in enumerate(groups_for('PersonAccount')):
        missing = [x for x in fields if x not in existing]
        if not missing:
            continue
        prefix = 'MMVolunteerExtension' + str(index)
        if result.find(f'.//m:identifier[.="{prefix}Section"]', NS) is not None:
            raise ValueError('Existing volunteer section needs review: ' + label)
        field_regions = []
        for side, column_fields in enumerate((missing[::2], missing[1::2])):
            new_region = ET.Element('{' + URI + '}flexiPageRegions')
            for field in column_fields:
                item = sub(sub(new_region, 'itemInstances'), 'fieldInstance')
                prop = sub(item, 'fieldInstanceProperties')
                sub(prop, 'name', 'uiBehavior')
                sub(prop, 'value', 'none')
                sub(item, 'fieldItem', 'Record.' + field)
                sub(item, 'identifier', prefix + re.sub('[^A-Za-z0-9]', '', field))
            sub(new_region, 'name', prefix + 'Fields' + str(side))
            sub(new_region, 'type', 'Facet')
            field_regions.append(new_region)
        columns = ET.Element('{' + URI + '}flexiPageRegions')
        for side in range(2):
            component(columns, 'flexipage:column', prefix + 'Column' + str(side), [('body', prefix + 'Fields' + str(side))])
        sub(columns, 'name', prefix + 'Columns')
        sub(columns, 'type', 'Facet')
        holder = ET.Element('{' + URI + '}flexiPageRegions')
        section = component(holder, 'flexipage:fieldSection', prefix + 'Section',
                            [('columns', prefix + 'Columns'), ('horizontalAlignment', 'true'), ('label', label)])
        visibility = sub(section, 'visibilityRule')
        sub(visibility, 'booleanFilter', '1 OR 2')
        for field, value in [('Record.Is_Volunteer__pc', 'true'), ('Record.RecordType.DeveloperName', volunteer_record_type)]:
            rule = sub(visibility, 'criteria')
            sub(rule, 'leftValue', '{!' + field + '}')
            sub(rule, 'operator', 'EQUAL')
            sub(rule, 'rightValue', value)
        items = region.findall('m:itemInstances', NS)
        region.insert(len(items), holder[0])
        for new_region in field_regions + [columns]:
            result.insert(insertion, new_region)
            insertion += 1
        existing.update(missing)
    return result


def extend_mappings(original):
    result = copy.deepcopy(original)
    groups = [x for x in result.findall('m:objectMapping', NS)
              if x.findtext('m:inputObject', namespaces=NS) == 'Lead'
              and x.findtext('m:outputObject', namespaces=NS) == 'Contact']
    if len(groups) != 1:
        raise ValueError('Expected the existing Lead-to-Contact mapping; do not replace target settings')
    group = groups[0]
    existing = [(x.findtext('m:inputField', namespaces=NS), x.findtext('m:outputField', namespaces=NS))
                for x in group.findall('m:mappingFields', NS)]
    for api in ANSWERS:
        if (api, api) in existing:
            continue
        if any(api in pair for pair in existing):
            raise ValueError('An existing mapping conflicts with the requested volunteer mapping: ' + api)
        item = ET.Element('{' + URI + '}mappingFields')
        sub(item, 'inputField', api)
        sub(item, 'outputField', api)
        group.insert(list(group).index(group.find('m:outputObject', NS)), item)
    return result


def write_xml(path, root):
    path.parent.mkdir(parents=True, exist_ok=True)
    ET.indent(root, space='    ')
    path.write_text('<?xml version="1.0" encoding="UTF-8"?>\n' + ET.tostring(root, encoding='unicode') + '\n')


def build(source, output, record_type_id, config=DEFAULT_CONFIG):
    if not re.fullmatch(r'012[A-Za-z0-9]{12}(?:[A-Za-z0-9]{3})?', record_type_id):
        raise ValueError('Use the Volunteer Person Account record type ID from this target')
    paths = [(f'layouts/{name}.layout-meta.xml', 'Layout', name, lambda x, o=obj: extend_layout(x, o))
             for name, obj in config['layouts'].items()]
    paths += [(f'flexipages/{name}.flexipage-meta.xml', 'FlexiPage', name, extend_page)
              for name in config['pages']]
    paths += [('LeadConvertSettings/LeadConvertSettings.LeadConvertSetting-meta.xml', 'LeadConvertSettings',
               'LeadConvertSettings', extend_mappings)]
    manifest = ET.Element('{' + URI + '}Package')
    report = {'schema': 1, 'recordTypeId': record_type_id, 'files': {}}
    members = {}
    for relative, kind, member, transform in paths:
        file = source / relative
        before = ET.parse(file).getroot()
        after = transform(before)
        report['files'][relative] = {'before': digest(before), 'after': digest(after), 'changed': canon(before) != canon(after)}
        if canon(before) == canon(after):
            continue
        write_xml(output / 'force-app/main/default' / relative, after)
        members.setdefault(kind, []).append(member)
    for kind, names in members.items():
        group = sub(manifest, 'types')
        for member in names:
            sub(group, 'members', member)
        sub(group, 'name', kind)
    sub(manifest, 'version', '67.0')
    write_xml(output / 'manifest/package.xml', manifest)
    (output / 'sfdx-project.json').write_text(json.dumps({'packageDirectories': [{'path': 'force-app', 'default': True}], 'namespace': '', 'sourceApiVersion': '67.0'}, indent=2) + '\n')
    (output / 'overlay-evidence.json').write_text(json.dumps(report, indent=2) + '\n')
    return report


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--source', type=Path, required=True, help='Fresh target force-app/main/default')
    parser.add_argument('--output', type=Path, required=True, help='Empty separate candidate directory')
    parser.add_argument('--record-types-json', type=Path, required=True, help='Target sf data query JSON with Id, DeveloperName and IsPersonType for Account RecordTypes')
    parser.add_argument('--config', type=Path, help='Reviewed target-specific layout names and Account pages')
    args = parser.parse_args()
    if args.output.exists() and any(args.output.iterdir()):
        parser.error('Output must be empty; never leave stale deployment files in a rebuilt candidate')
    rows = json.loads(args.record_types_json.read_text())['result']['records']
    matches = [x for x in rows if x['DeveloperName'] == 'Volunteer' and x['IsPersonType'] and x.get('IsActive', True)]
    if len(matches) != 1:
        parser.error('Expected one active existing Volunteer Person Account type; review target classification')
    report = build(args.source, args.output, matches[0]['Id'], json.loads(args.config.read_text()) if args.config else DEFAULT_CONFIG)
    print(json.dumps({'changed': sum(x['changed'] for x in report['files'].values()), 'output': str(args.output)}))
