#!/usr/bin/env python3
"""Prepare an explicitly approved, target-derived staff field-visibility overlay.

This does not assign permission sets or change record sharing, object access,
page layouts or app assignments. Keep its output outside the NTE core source.
"""
import argparse
import copy
import importlib.util
import json
from pathlib import Path
import xml.etree.ElementTree as ET

spec = importlib.util.spec_from_file_location('volunteer_overlay', Path(__file__).with_name('build-volunteer-overlay.py'))
overlay = importlib.util.module_from_spec(spec)
spec.loader.exec_module(overlay)
NS, URI = overlay.NS, overlay.URI


def build(source, output, profiles):
    if output.exists() and any(output.iterdir()):
        raise ValueError('Output must be empty')
    names = {
        'Lead': overlay.ANSWERS + ['Declaration_Name__c', 'Declaration_Date__c',
                                 'Volunteer_Applicant_Email_Status__c', 'Volunteer_Internal_Email_Status__c', 'Volunteer_Email_Error__c'],
        'Contact': overlay.ANSWERS + ['Volunteer_Declaration_Name__c', 'Volunteer_Declaration_Date__c'],
    }
    fields = {obj + '.' + name for obj, values in names.items() for name in values}
    for obj, values in names.items():
        for name in values:
            if not (source / 'objects' / obj / 'fields' / (name + '.field-meta.xml')).exists():
                raise ValueError('Fresh target field definition missing: ' + obj + '.' + name)
    report = {'profiles': {}, 'fieldScope': sorted(fields)}
    for name in profiles:
        path = source / 'profiles' / (name + '.profile-meta.xml')
        before = ET.parse(path).getroot()
        after = copy.deepcopy(before)
        existing = {x.findtext('m:field', namespaces=NS): x for x in after.findall('m:fieldPermissions', NS)}
        changed = []
        for field in sorted(fields):
            item = existing.get(field)
            if item is None:
                item = ET.Element('{' + URI + '}fieldPermissions')
                for tag, value in [('editable', 'false'), ('field', field), ('readable', 'false')]:
                    overlay.sub(item, tag, value)
                idx = max((i for i,x in enumerate(after) if x.tag.endswith('}fieldPermissions')), default=0)
                after.insert(idx+1, item)
            old = overlay.canon(item)
            item.find('m:readable', NS).text = 'true'
            # Email delivery status is operational evidence, not an applicant answer.
            item.find('m:editable', NS).text = 'false' if field in {
                'Lead.Volunteer_Applicant_Email_Status__c', 'Lead.Volunteer_Internal_Email_Status__c', 'Lead.Volunteer_Email_Error__c'
            } else 'true'
            if old != overlay.canon(item):
                changed.append(field)
        def unaffected(root):
            return [overlay.canon(x) for x in root if not (x.tag.endswith('}fieldPermissions') and x.findtext('m:field', namespaces=NS) in fields)]
        assert unaffected(before) == unaffected(after), 'An unrelated profile setting changed'
        report['profiles'][name] = {'changedFields': changed, 'otherSettingsPreserved': True, 'before': overlay.digest(before), 'after': overlay.digest(after)}
        overlay.write_xml(output/'force-app/main/default/profiles'/(name+'.profile-meta.xml'), after)
    package = ET.Element('{' + URI + '}Package')
    group = overlay.sub(package, 'types')
    for name in profiles:
        overlay.sub(group, 'members', name)
    overlay.sub(group, 'name', 'Profile')
    overlay.sub(package, 'version', '67.0')
    overlay.write_xml(output/'manifest/package.xml', package)
    (output/'sfdx-project.json').write_text(json.dumps({'packageDirectories':[{'path':'force-app','default':True}], 'namespace':'', 'sourceApiVersion':'67.0'}, indent=2)+'\n')
    (output/'access-evidence.json').write_text(json.dumps(report, indent=2)+'\n')
    return report


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--source', type=Path, required=True)
    parser.add_argument('--output', type=Path, required=True)
    parser.add_argument('--profiles', nargs='+', required=True, help='Explicitly approved existing internal staff profile names')
    args = parser.parse_args()
    result = build(args.source, args.output, args.profiles)
    print(json.dumps({name:len(row['changedFields']) for name,row in result['profiles'].items()}))
