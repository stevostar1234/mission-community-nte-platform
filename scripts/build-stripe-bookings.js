// Durable test payment requests and explicit sandbox rollout settings.
const fs = require('fs');
const path = require('path');
const root = path.resolve(__dirname, '..');
const md = path.join(root, 'force-app/main/default');
const ns = 'http://soap.sforce.com/2006/04/metadata';
const esc = value => String(value).replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;');
const members = {};
const register = (type, name) => (members[type] ||= []).push(name);
function write(relative, type, body) {
    const file = path.join(md, relative); fs.mkdirSync(path.dirname(file), {recursive: true});
    fs.writeFileSync(file, `<?xml version="1.0" encoding="UTF-8"?>\n<${type} xmlns="${ns}">\n${body}\n</${type}>\n`);
}
const object = 'NTE_Payment_Request__c';
write(`objects/${object}/${object}.object-meta.xml`, 'CustomObject', `    <deploymentStatus>Deployed</deploymentStatus>
    <description>Saved NTE payment request identities, charge snapshots and Stripe outcomes.</description>
    <enableActivities>false</enableActivities><enableHistory>true</enableHistory><enableReports>true</enableReports>
    <label>NTE Payment Request</label>
    <nameField><displayFormat>NTE-PAY-{000000}</displayFormat><label>Payment Request</label><type>AutoNumber</type></nameField>
    <pluralLabel>NTE Payment Requests</pluralLabel><sharingModel>ReadWrite</sharingModel>`);
register('CustomObject', object);
const fields = [
    ['Opportunity__c', 'Booking', 'Lookup'], ['Charge_Key__c', 'Charge Key', 'Text', 100],
    ['Kind__c', 'Charge Type', 'Text', 20], ['Status__c', 'Status', 'Text', 30],
    ['Amount_Minor__c', 'Amount in Minor Units', 'Number'], ['Net_Minor__c', 'Net in Minor Units', 'Number'],
    ['Tax_Rate__c', 'Tax Rate', 'Number', 2], ['Currency__c', 'Currency', 'Text', 3],
    ['Stripe_Account__c', 'Stripe Account', 'Text', 60], ['Source_Fingerprint__c', 'Charge Snapshot', 'Text', 64],
    ['Source_Lead_Id__c', 'Application ID', 'Text', 18], ['Reference__c', 'Booking Reference', 'Text', 80],
    ['Description__c', 'Charge Description', 'Text', 255], ['Price_Id__c', 'Stripe Price ID', 'Text', 100],
    ['Link_Id__c', 'Stripe Payment Link ID', 'Text', 100], ['Payment_URL__c', 'Payment Link', 'Url'],
    ['First_Attempt_At__c', 'First Attempt At', 'DateTime'], ['Verified_At__c', 'Verified At', 'DateTime'],
    ['Error__c', 'Error', 'LongTextArea', 4000], ['Delivered_At__c', 'Payment Email Sent At', 'DateTime'],
    ['Recipient__c', 'Payment Email Recipient', 'Email'], ['Batch_Key__c', 'Email Batch', 'Text', 64]
];
for (const [api, label, type, length] of fields) {
    const body = [`<fullName>${api}</fullName>`, `<label>${esc(label)}</label>`];
    if (type === 'Lookup') body.push('<deleteConstraint>SetNull</deleteConstraint><referenceTo>Opportunity</referenceTo><relationshipLabel>NTE Payment Requests</relationshipLabel><relationshipName>NTE_Payment_Requests</relationshipName>');
    if (api === 'Charge_Key__c') body.push('<externalId>true</externalId><unique>true</unique>');
    if (type === 'Text' || type === 'LongTextArea') body.push(`<length>${length}</length>`);
    if (type === 'Number') body.push(`<precision>18</precision><scale>${length || 0}</scale>`);
    if (type === 'LongTextArea') body.push('<visibleLines>3</visibleLines>');
    body.push(`<type>${type}</type>`);
    write(`objects/${object}/fields/${api}.field-meta.xml`, 'CustomField', `    ${body.join('\n    ')}`);
    register('CustomField', `${object}.${api}`);
}
const config = 'NTE_Stripe_Config__mdt';
write(`objects/${config}/${config}.object-meta.xml`, 'CustomObject', '    <label>NTE Stripe Configuration</label><pluralLabel>NTE Stripe Configurations</pluralLabel><visibility>Public</visibility>');
register('CustomObject', config);
const settings = [
    ['Enabled__c', 'Enabled', 'Checkbox', false],
    ['Expected_Account_Id__c', 'Expected Stripe Account', 'Text', 'acct_1UD8GwBcW1MkMYQ1'],
    ['Expected_Org_Id__c', 'Expected Salesforce Org', 'Text', '00DAd00000A95VlMAJ'],
    ['Reference_Prefix__c', 'Test Booking Reference Prefix', 'Text', 'NTE-STRIPE-'],
    ['Allowed_Email__c', 'Allowed Test Email', 'Text', 'steven.skyba@anthrion.com'],
    ['Tax_Rate__c', 'Provisional Test Tax Rate', 'Number', 20]
];
for (const [api, label, type] of settings) {
    write(`objects/${config}/fields/${api}.field-meta.xml`, 'CustomField', `    <fullName>${api}</fullName>
    ${type === 'Checkbox' ? '<defaultValue>false</defaultValue>' : ''}
    <fieldManageability>DeveloperControlled</fieldManageability><label>${label}</label>
    ${type === 'Text' ? '<length>255</length>' : type === 'Number' ? '<precision>5</precision><scale>2</scale>' : ''}
    <type>${type}</type>`);
    register('CustomField', `${config}.${api}`);
}
const configFile = path.join(md, 'customMetadata/NTE_Stripe_Config.Default.md-meta.xml');
if (!fs.existsSync(configFile)) fs.writeFileSync(configFile, `<?xml version="1.0" encoding="UTF-8"?>
<CustomMetadata xmlns="${ns}" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">
    <label>Default</label><protected>false</protected>
${settings.map(([api, , type, value]) => `    <values><field>${api}</field><value xsi:type="xsd:${type === 'Checkbox' ? 'boolean' : type === 'Number' ? 'double' : 'string'}">${esc(value)}</value></values>`).join('\n')}
</CustomMetadata>\n`);
register('CustomMetadata', 'NTE_Stripe_Config.Default');
write(`layouts/${object}-NTE Payment Request.layout-meta.xml`, 'Layout', `    <layoutSections><customLabel>true</customLabel><detailHeading>true</detailHeading><editHeading>false</editHeading><label>Payment request</label><layoutColumns>
${['Name', ...fields.map(([api]) => api)].map(api => `        <layoutItems><behavior>Readonly</behavior><field>${api}</field></layoutItems>`).join('\n')}
    </layoutColumns><style>OneColumn</style></layoutSections>
    <showEmailCheckbox>false</showEmailCheckbox><showHighlightsPanel>false</showHighlightsPanel><showInteractionLogPanel>false</showInteractionLogPanel><showRunAssignmentRulesCheckbox>false</showRunAssignmentRulesCheckbox><showSubmitAndAttachButton>false</showSubmitAndAttachButton>`);
register('Layout', `${object}-NTE Payment Request`);
write(`objects/${object}/listViews/NTE_Payment_Requests.listView-meta.xml`, 'ListView', `    <fullName>NTE_Payment_Requests</fullName>
    <columns>NAME</columns><columns>Opportunity__c</columns><columns>Kind__c</columns><columns>Status__c</columns><columns>Reference__c</columns><columns>Delivered_At__c</columns>
    <filterScope>Everything</filterScope><label>NTE Payment Requests</label>`);
register('ListView', `${object}.NTE_Payment_Requests`);
for (const permission of ['NTE_Forms_Administration', 'NTE_Management_User', 'NTE_Stripe_Test_Operator']) {
    const file = path.join(md, `permissionsets/${permission}.permissionset-meta.xml`);
    let contents = fs.readFileSync(file, 'utf8');
    const additions = fields.map(([api]) => `<fieldPermissions><editable>false</editable><field>${object}.${api}</field><readable>true</readable></fieldPermissions>`);
    additions.push(`<objectPermissions><allowCreate>false</allowCreate><allowDelete>false</allowDelete><allowEdit>false</allowEdit><allowRead>true</allowRead><modifyAllRecords>false</modifyAllRecords><object>${object}</object><viewAllRecords>false</viewAllRecords></objectPermissions>`);
    contents = contents.replace('</PermissionSet>', `    ${additions.join('\n    ')}\n</PermissionSet>`);
    for (const tag of ['fieldPermissions', 'objectPermissions']) {
        const pattern = new RegExp(`<${tag}>[\\s\\S]*?<\\/${tag}>`, 'g');
        const blocks = contents.match(pattern) || [];
        contents = contents.replace(pattern, '');
        contents = contents.replace('</PermissionSet>', `${blocks.join('\n    ')}\n</PermissionSet>`);
    }
    fs.writeFileSync(file, contents);
    register('PermissionSet', permission);
}
for (const name of ['NTEStripeBookingService', 'NTEStripeBookingServiceTest']) register('ApexClass', name);
const manifestPath = path.join(root, 'manifest/production-package.xml');
let manifest = fs.readFileSync(manifestPath, 'utf8');
for (const [type, names] of Object.entries(members)) {
    const block = (manifest.match(/<types>[\s\S]*?<\/types>/g) || []).find(value => value.includes(`<name>${type}</name>`));
    const added = [...new Set(names)].filter(name => !block?.includes(`<members>${name}</members>`));
    if (!added.length) continue;
    const lines = added.map(name => `        <members>${name}</members>`).join('\n');
    if (block) manifest = manifest.replace(block, block.replace(`        <name>${type}</name>`, `${lines}\n        <name>${type}</name>`));
    else manifest = manifest.replace('    <version>', `    <types>\n${lines}\n        <name>${type}</name>\n    </types>\n    <version>`);
}
fs.writeFileSync(manifestPath, manifest);
