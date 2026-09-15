// Additive volunteer fields and conversion support. Shared target pages/mappings
// are extended separately by build-volunteer-overlay.py from a fresh retrieval.
const fs = require('fs');
const path = require('path');
const root = path.resolve(__dirname, '..');
const md = path.join(root, 'force-app/main/default');
const ns = 'http://soap.sforce.com/2006/04/metadata';
const answers = [
  'NOK_Address__c', 'NOK_Postcode__c', 'Volunteer_Armed_Forces_Service__c',
  'Volunteer_Service_Details__c', 'Volunteer_Service_Dates__c', 'Volunteer_Opportunities__c',
  'Volunteer_Skills__c', 'Volunteer_Hours__c', 'Volunteer_Availability__c',
  'Volunteer_Travel_Regions__c', 'Volunteer_DBS_Willing__c', 'Volunteer_Consent__c',
  'Volunteer_Code_Consent__c', 'Volunteer_Code_Version__c', 'Volunteer_Form_Version__c'
];
const declarations = ['Volunteer_Declaration_Name__c', 'Volunteer_Declaration_Date__c'];
fs.mkdirSync(path.join(md, 'objects/Contact/fields'), {recursive: true});
for (const api of answers) {
  fs.copyFileSync(path.join(md, `objects/Lead/fields/${api}.field-meta.xml`),
    path.join(md, `objects/Contact/fields/${api}.field-meta.xml`));
}
for (const [api, source, label] of [
  [declarations[0], 'Declaration_Name__c', 'Volunteer Declaration Name'],
  [declarations[1], 'Declaration_Date__c', 'Volunteer Declaration Date']
]) {
  const xml = fs.readFileSync(path.join(md, `objects/Lead/fields/${source}.field-meta.xml`), 'utf8')
    .replace(`<fullName>${source}</fullName>`, `<fullName>${api}</fullName>`)
    .replace(/<label>.*?<\/label>/, `<label>${label}</label>`);
  fs.writeFileSync(path.join(md, `objects/Contact/fields/${api}.field-meta.xml`), xml);
}

const permissionFile = path.join(md, 'permissionsets/Volunteer_Applications_User.permissionset-meta.xml');
let permission = fs.readFileSync(permissionFile, 'utf8');
const inherited = ['Birthdate__c', 'NOK_Name__c', 'NOK_Relationship__c', 'NOK_Phone__c',
  'Is_Volunteer__c', 'Consent_PII__c', 'Consent_Contact__c', 'Consent_Promotion__c'];
const fields = [...answers, ...declarations, ...inherited].map(api =>
  `    <fieldPermissions><editable>true</editable><field>Contact.${api}</field><readable>true</readable></fieldPermissions>`).join('\n');
permission = permission.replace('    <objectPermissions>', fields + '\n    <objectPermissions>');
const objects = ['Account', 'Contact'].map(object => `    <objectPermissions>
        <allowCreate>true</allowCreate><allowDelete>false</allowDelete><allowEdit>true</allowEdit><allowRead>true</allowRead>
        <modifyAllRecords>false</modifyAllRecords><object>${object}</object><viewAllFields>false</viewAllFields><viewAllRecords>false</viewAllRecords>
    </objectPermissions>`).join('\n');
permission = permission.replace('    <hasActivationRequired>', objects + '\n    <hasActivationRequired>')
  .replace('</PermissionSet>', '    <userPermissions><enabled>true</enabled><name>ConvertLeads</name></userPermissions>\n    <userPermissions><enabled>true</enabled><name>EditTask</name></userPermissions>\n</PermissionSet>');
fs.writeFileSync(permissionFile, permission);

// Shared NTE declaration fields must not have a global volunteer mapping.
// This after-conversion flow copies them only for volunteer intake, fills blank
// destinations and adds the volunteer role without changing the Account type.
const esc = value => value.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;');
const isApplication = 'OR(TEXT({!$Record.Web_Form_Type__c}) = "Volunteer Application", AND(ISBLANK(TEXT({!$Record.Web_Form_Type__c})), TEXT({!$Record.LeadSource}) = "Volunteer Application"))';
const formula = (name, dataType, expression) => `    <formulas><name>${name}</name><dataType>${dataType}</dataType><expression>${esc(expression)}</expression></formulas>`;
const flow = `<?xml version="1.0" encoding="UTF-8"?>
<Flow xmlns="${ns}">
    <apiVersion>67.0</apiVersion>
    <areMetricsLoggedToDataCloud>false</areMetricsLoggedToDataCloud>
    <decisions>
        <name>Needs_Volunteer_Details</name><label>New volunteer details to retain</label><locationX>176</locationX><locationY>276</locationY>
        <defaultConnectorLabel>Existing details retained</defaultConnectorLabel>
        <rules><name>Fill_Blanks</name><conditionLogic>and</conditionLogic>
            <conditions><leftValueReference>NeedsUpdate</leftValueReference><operator>EqualTo</operator><rightValue><booleanValue>true</booleanValue></rightValue></conditions>
            <connector><targetReference>Save_Volunteer_Details</targetReference></connector><label>Save new details</label>
        </rules>
    </decisions>
    <description>Adds the volunteer role and fills blank volunteer declaration details at conversion. Existing values and Account classification are preserved; unrelated application declarations are excluded.</description>
    <environments>Default</environments>
${formula('IsVolunteerApplication', 'Boolean', isApplication)}
${formula('DeclarationName', 'String', 'IF(AND({!IsVolunteerApplication}, ISBLANK({!Converted_Contact.Volunteer_Declaration_Name__c})), {!$Record.Declaration_Name__c}, {!Converted_Contact.Volunteer_Declaration_Name__c})')}
${formula('DeclarationDate', 'Date', 'IF(AND({!IsVolunteerApplication}, ISBLANK({!Converted_Contact.Volunteer_Declaration_Date__c})), {!$Record.Declaration_Date__c}, {!Converted_Contact.Volunteer_Declaration_Date__c})')}
${formula('NeedsUpdate', 'Boolean', 'AND(NOT(ISBLANK({!Converted_Contact.Id})), OR(NOT({!Converted_Contact.Is_Volunteer__c}), AND({!IsVolunteerApplication}, OR(AND(ISBLANK({!Converted_Contact.Volunteer_Declaration_Name__c}), NOT(ISBLANK({!$Record.Declaration_Name__c}))), AND(ISBLANK({!Converted_Contact.Volunteer_Declaration_Date__c}), NOT(ISBLANK({!$Record.Declaration_Date__c})))))))')}
    <interviewLabel>Volunteer Conversion Details {!$Flow.CurrentDateTime}</interviewLabel>
    <label>Volunteer Conversion Details</label>
    <processMetadataValues><name>BuilderType</name><value><stringValue>LightningFlowBuilder</stringValue></value></processMetadataValues>
    <processMetadataValues><name>CanvasMode</name><value><stringValue>AUTO_LAYOUT_CANVAS</stringValue></value></processMetadataValues>
    <processType>AutoLaunchedFlow</processType>
    <recordLookups>
        <name>Converted_Contact</name><label>Converted contact</label><locationX>176</locationX><locationY>176</locationY>
        <assignNullValuesIfNoRecordsFound>false</assignNullValuesIfNoRecordsFound>
        <connector><targetReference>Needs_Volunteer_Details</targetReference></connector><filterLogic>and</filterLogic>
        <filters><field>Id</field><operator>EqualTo</operator><value><elementReference>$Record.ConvertedContactId</elementReference></value></filters>
        <getFirstRecordOnly>true</getFirstRecordOnly><object>Contact</object><storeOutputAutomatically>true</storeOutputAutomatically>
    </recordLookups>
    <recordUpdates>
        <name>Save_Volunteer_Details</name><label>Save new volunteer details</label><locationX>176</locationX><locationY>376</locationY>
        <filterLogic>and</filterLogic><filters><field>Id</field><operator>EqualTo</operator><value><elementReference>Converted_Contact.Id</elementReference></value></filters>
        <inputAssignments><field>Is_Volunteer__c</field><value><booleanValue>true</booleanValue></value></inputAssignments>
        <inputAssignments><field>Volunteer_Declaration_Name__c</field><value><elementReference>DeclarationName</elementReference></value></inputAssignments>
        <inputAssignments><field>Volunteer_Declaration_Date__c</field><value><elementReference>DeclarationDate</elementReference></value></inputAssignments>
        <object>Contact</object>
    </recordUpdates>
    <start>
        <locationX>50</locationX><locationY>0</locationY><connector><targetReference>Converted_Contact</targetReference></connector>
        <filterFormula>${esc('AND({!$Record.IsConverted}, NOT({!$Record__Prior.IsConverted}), OR(TEXT({!$Record.Web_Form_Type__c}) = "Volunteer Application", AND(ISBLANK(TEXT({!$Record.Web_Form_Type__c})), OR({!$Record.Interested_in_Volunteering__c}, TEXT({!$Record.LeadSource}) = "Volunteer Application"))))')}</filterFormula>
        <object>Lead</object><recordTriggerType>Update</recordTriggerType><triggerType>RecordAfterSave</triggerType>
    </start>
    <status>Active</status>
</Flow>
`;
fs.writeFileSync(path.join(md, 'flows/Volunteer_Conversion_Details.flow-meta.xml'), flow);

const manifestFile = path.join(root, 'manifest/production-package.xml');
let manifest = fs.readFileSync(manifestFile, 'utf8');
for (const [type, members] of Object.entries({
  CustomField: [...answers, ...declarations].map(api => 'Contact.' + api),
  Flow: ['Volunteer_Conversion_Details'], ApexClass: ['VolunteerCompatibilityTest']
})) {
  const block = manifest.match(/<types>[\s\S]*?<\/types>/g).find(x => x.includes(`<name>${type}</name>`));
  const additions = members.filter(x => !block.includes(`<members>${x}</members>`))
    .map(x => `        <members>${x}</members>`).join('\n');
  if (additions) manifest = manifest.replace(block, block.replace(`        <name>${type}</name>`, `${additions}\n        <name>${type}</name>`));
}
fs.writeFileSync(manifestFile, manifest);
console.log(`Generated ${answers.length + declarations.length} optional volunteer Contact fields and volunteer-only conversion support.`);
