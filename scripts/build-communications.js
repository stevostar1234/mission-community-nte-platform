// Internal release generation for NTE communication tracking and configuration.
const fs = require('fs');
const path = require('path');
const root = path.resolve(__dirname, '..');
const md = path.join(root, 'force-app/main/default');
const ns = 'http://soap.sforce.com/2006/04/metadata';
const escape = value => String(value).replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;');
const write = (relative, contents) => {
    const file = path.join(md, relative);
    fs.mkdirSync(path.dirname(file), {recursive: true});
    fs.writeFileSync(file, contents + '\n');
};
const componentMembers = {};
const register = (type, name) => (componentMembers[type] ||= []).push(name);
const fields = [];
function field(object, api, label, type = 'Text', length = 255, referenceTo) {
    const body = [`<fullName>${api}</fullName>`, `<label>${escape(label)}</label>`];
    if (type === 'Lookup') body.push('<deleteConstraint>SetNull</deleteConstraint>', `<referenceTo>${referenceTo}</referenceTo>`,
        '<relationshipLabel>NTE email dispatches</relationshipLabel>', `<relationshipName>NTE_Email_Dispatches_${referenceTo}</relationshipName>`);
    if (type === 'Text' || type === 'LongTextArea') body.push(`<length>${length}</length>`);
    if (api === 'Dispatch_Key__c') body.push('<externalId>true</externalId>', '<unique>true</unique>');
    if (type === 'LongTextArea') body.push('<visibleLines>4</visibleLines>');
    body.push(`<type>${type}</type>`);
    if (object.endsWith('__mdt')) body.push('<fieldManageability>DeveloperControlled</fieldManageability>');
    write(`objects/${object}/fields/${api}.field-meta.xml`, `<?xml version="1.0" encoding="UTF-8"?>\n<CustomField xmlns="${ns}">\n    ${body.join('\n    ')}\n</CustomField>`);
    fields.push(`${object}.${api}`);
    register('CustomField', `${object}.${api}`);
}
for (const [api, label, type, length] of [
    ['NTE_Invitation_Status__c', 'NTE Invitation Status', 'Text', 20],
    ['NTE_Invitation_Sent_At__c', 'NTE Invitation Sent At', 'DateTime'],
    ['NTE_Invitation_Recipient__c', 'NTE Invitation Recipient', 'Email']
]) field('Lead', api, label, type, length);
for (const [api, label, type, length] of [
    ['NTE_Final_Pack_Status__c', 'NTE Joining Instructions Status', 'Text', 20],
    ['NTE_Final_Pack_Sent_At__c', 'NTE Joining Instructions Sent At', 'DateTime'],
    ['NTE_Approval_Email_Status__c', 'NTE Provisional Email Status', 'Text', 40],
    ['NTE_Approval_Email_Batch__c', 'NTE Provisional Email Batch', 'Text', 64],
    ['NTE_Approval_Email_Lead_Id__c', 'NTE Provisional Email Lead ID', 'Text', 18],
    ['NTE_Approval_Email_Requested_At__c', 'NTE Provisional Email Requested At', 'DateTime'],
    ['NTE_Approval_Email_Requested_By__c', 'NTE Provisional Email Requested By', 'Text', 255],
    ['NTE_Approval_Email_Sent_At__c', 'NTE Provisional Email Sent At', 'DateTime'],
    ['NTE_Approval_Email_Recipient__c', 'NTE Provisional Email Recipient', 'Email'],
    ['NTE_Approval_Email_Error__c', 'NTE Provisional Email Error', 'LongTextArea', 32768]
]) field('Opportunity', api, label, type, length);

const dispatchObject = 'NTE_Email_Dispatch__c';
write(`objects/${dispatchObject}/${dispatchObject}.object-meta.xml`, `<?xml version="1.0" encoding="UTF-8"?>
<CustomObject xmlns="${ns}">
    <deploymentStatus>Deployed</deploymentStatus>
    <description>Individual NTE invitation, reminder, booking-confirmation and email requests and outcomes.</description>
    <enableActivities>false</enableActivities>
    <enableHistory>true</enableHistory>
    <enableReports>true</enableReports>
    <label>NTE Email Dispatch</label>
    <nameField><displayFormat>NTE-EMAIL-{000000}</displayFormat><label>Dispatch Number</label><type>AutoNumber</type></nameField>
    <pluralLabel>NTE Email Dispatches</pluralLabel>
    <sharingModel>ReadWrite</sharingModel>
</CustomObject>`);
register('CustomObject', dispatchObject);
for (const [api, label, type, length, target] of [
    ['Kind__c', 'Email Type', 'Text', 40], ['Lead__c', 'Interest', 'Lookup', null, 'Lead'],
    ['Opportunity__c', 'Booking', 'Lookup', null, 'Opportunity'], ['Contact__c', 'Recipient Contact', 'Lookup', null, 'Contact'],
    ['Recipient__c', 'Email Address', 'Email'], ['Event_Code__c', 'Event Code', 'Text', 20],
    ['Status__c', 'Status', 'Text', 20], ['Subject__c', 'Subject', 'Text', 255],
    ['Message__c', 'Message', 'LongTextArea', 32768], ['Link__c', 'Action Link', 'Text', 255],
    ['Run_Id__c', 'Send Batch', 'Text', 64], ['Dispatch_Key__c', 'Dispatch Key', 'Text', 100],
    ['Sent_At__c', 'Sent At', 'DateTime'], ['Error__c', 'Send Error', 'LongTextArea', 32768],
    ['Fingerprint__c', 'Recipient Snapshot', 'Text', 64]
]) field(dispatchObject, api, label, type, length, target);

const routing = {
    Exhibitor_Application_URL__c: ['Exhibitor Application URL', 'https://stevostar1234.github.io/nte27-web-to-lead-demo/exhibitor-application.html', 255],
    Partner_Application_URL__c: ['Partner Application URL', 'https://stevostar1234.github.io/nte27-web-to-lead-demo/partner-sponsor-application.html', 255],
};
const configFile = path.join(md, 'customMetadata/NTE_Routing_Config.Default.md-meta.xml');
let config = fs.readFileSync(configFile, 'utf8');
for (const [api, [label, value, length]] of Object.entries(routing)) {
    field('NTE_Routing_Config__mdt', api, label, 'Text', length);
    // Keep explicitly configured destinations; only seed newly introduced settings.
    if (!config.includes(`<field>${api}</field>`)) config = config.replace('</CustomMetadata>',
        `    <values><field>${api}</field><value xsi:type="xsd:string">${escape(value)}</value></values>\n</CustomMetadata>`);
}
fs.writeFileSync(configFile, config);
register('CustomMetadata', 'NTE_Routing_Config.Default');

function listView(object, api, label, columns, filters, booleanFilter) {
    write(`objects/${object}/listViews/${api}.listView-meta.xml`, `<?xml version="1.0" encoding="UTF-8"?>
<ListView xmlns="${ns}">
    <fullName>${api}</fullName>
    ${booleanFilter ? `<booleanFilter>${escape(booleanFilter)}</booleanFilter>` : ''}
    ${columns.map(column => `<columns>${column}</columns>`).join('\n    ')}
    <filterScope>Everything</filterScope>
    ${filters.map(([api, operation, value]) => `<filters><field>${api}</field><operation>${operation}</operation>${value === undefined ? '' : `<value>${escape(value)}</value>`}</filters>`).join('\n    ')}
    <label>${label}</label>
</ListView>`);
    register('ListView', `${object}.${api}`);
}
listView('Lead', 'NTE_Update_Emails_Failed', 'NTE Update Emails Failed',
    ['FULL_NAME', 'LEAD.COMPANY', 'Web_Form_Type__c', 'Target_Booking_Reference__c', 'NTE_Update_Status__c', 'NTE_Applicant_Email_Status__c', 'LEAD.CREATED_DATE'],
    [['NTE_Update_Status__c', 'equals', 'Matched and Applied'], ['NTE_Applicant_Email_Status__c', 'equals', 'Failed']]);
listView(dispatchObject, 'NTE_Email_Failures', 'NTE Email Failures',
    ['NAME', 'Kind__c', 'Recipient__c', 'Event_Code__c', 'Status__c', 'Opportunity__c', 'Lead__c', 'CREATED_DATE'], [['Status__c', 'equals', 'Failed']]);
listView(dispatchObject, 'NTE_Recent_Emails', 'NTE Recent Emails',
    ['NAME', 'Kind__c', 'Recipient__c', 'Status__c', 'Sent_At__c', 'Opportunity__c', 'Lead__c', 'CREATED_DATE'], []);
// The main generator owns the three combined finance views; do not overwrite them
// with the former booking-only definitions.
register('ListView', 'Opportunity.NTE_Payment_Confirmed');
for (const api of ['NTE_Pricing_Ready__c', 'NTE_Finance_Payment_Due__c', 'NTE_Finance_Payment_Confirmed__c']) {
    register('CustomField', `Opportunity.${api}`);
}
register('CustomField', 'Lead.NTE_Update_Booking_Id__c');
register('ValidationRule', 'Lead.NTE_Intake_Event_Code');

write(`layouts/${dispatchObject}-NTE Email Dispatch.layout-meta.xml`, `<?xml version="1.0" encoding="UTF-8"?>
<Layout xmlns="${ns}">
    <layoutSections><customLabel>true</customLabel><detailHeading>true</detailHeading><editHeading>true</editHeading><label>Email details</label>
        <layoutColumns>${['Name', 'Kind__c', 'Status__c', 'Recipient__c', 'Contact__c', 'Lead__c', 'Opportunity__c', 'Event_Code__c', 'Subject__c', 'Message__c', 'Link__c', 'Sent_At__c', 'Error__c'].map(api => `<layoutItems><behavior>Readonly</behavior><field>${api}</field></layoutItems>`).join('')}</layoutColumns>
        <style>OneColumn</style>
    </layoutSections>
    <platformActionList><actionListContext>Record</actionListContext><platformActionListItems><actionName>NTE_Email_Dispatch__c.Retry_Email</actionName><actionType>QuickAction</actionType><sortOrder>0</sortOrder></platformActionListItems></platformActionList>
    <showEmailCheckbox>false</showEmailCheckbox><showHighlightsPanel>false</showHighlightsPanel><showInteractionLogPanel>false</showInteractionLogPanel><showRunAssignmentRulesCheckbox>false</showRunAssignmentRulesCheckbox><showSubmitAndAttachButton>false</showSubmitAndAttachButton>
</Layout>`);
register('Layout', `${dispatchObject}-NTE Email Dispatch`);
register('LightningComponentBundle', 'nteRetryEmail');
for (const [api, label] of [
    ['NTE_Email_Dispatch__c.Retry_Email', 'Retry email'],
    ['Opportunity.Retry_Booking_Email', 'Retry booking email'],
    ['Lead.Retry_Update_Email', 'Retry email']
]) {
    write(`quickActions/${api}.quickAction-meta.xml`, `<?xml version="1.0" encoding="UTF-8"?>
<QuickAction xmlns="${ns}">
    <label>${label}</label>
    <lightningWebComponent>nteRetryEmail</lightningWebComponent>
    <optionsCreateFeedItem>false</optionsCreateFeedItem>
    <type>LightningWebComponent</type>
</QuickAction>`);
    register('QuickAction', api);
}
for (const permission of ['NTE_Forms_Administration', 'NTE_Management_User']) {
    const file = path.join(md, `permissionsets/${permission}.permissionset-meta.xml`);
    let contents = fs.readFileSync(file, 'utf8');
    const additions = [];
    for (const api of fields.filter(api => !api.startsWith('NTE_Routing_Config__mdt.'))) if (!contents.includes(`<field>${api}</field>`))
        additions.push(`<fieldPermissions><editable>true</editable><field>${api}</field><readable>true</readable></fieldPermissions>`);
    for (const cls of ['NTEEmailDispatchService', 'NTEUpdateSubmissionService', 'NTELeadEmailRetryService', 'NTEBookingEmailRetryService']) if (!contents.includes(`<apexClass>${cls}</apexClass>`))
        additions.push(`<classAccesses><apexClass>${cls}</apexClass><enabled>true</enabled></classAccesses>`);
    additions.push(`<objectPermissions><allowCreate>true</allowCreate><allowDelete>false</allowDelete><allowEdit>true</allowEdit><allowRead>true</allowRead><modifyAllRecords>false</modifyAllRecords><object>${dispatchObject}</object><viewAllRecords>false</viewAllRecords></objectPermissions>`);
    // The main generator recreates these files before this extension runs.
    for (const tag of ['fieldPermissions', 'classAccesses', 'objectPermissions']) {
        const group = additions.filter(value => value.startsWith(`<${tag}>`));
        if (!group.length) continue;
        const last = contents.lastIndexOf(`</${tag}>`);
        if (last >= 0) {
            const end = last + tag.length + 3;
            contents = contents.slice(0, end) + `\n    ${group.join('\n    ')}` + contents.slice(end);
        } else contents = contents.replace('</PermissionSet>', `    ${group.join('\n    ')}\n</PermissionSet>`);
    }
    fs.writeFileSync(file, contents);
}
for (const cls of ['NTEBookingContactService', 'NTEEmailDispatchService', 'NTEEmailDispatchServiceTest', 'NTEBookingPaymentEmailTest', 'NTEMasterPanelFinanceTest', 'NTEMasterPanelReadinessTest', 'NTEPricingStressTest', 'NTEPanelStressTest', 'NTEMetadataReportStressTest']) register('ApexClass', cls);
// Add these components without removing any pre-existing package selections.
const manifestPath = path.join(root, 'manifest/production-package.xml');
let manifest = fs.readFileSync(manifestPath, 'utf8');
for (const [type, names] of Object.entries(componentMembers)) {
    const blocks = manifest.match(/<types>[\s\S]*?<\/types>/g) || [];
    const block = blocks.find(block => block.includes(`<name>${type}</name>`));
    const additions = [...new Set(names)].filter(name => !block?.includes(`<members>${name}</members>`)).sort();
    if (!additions.length) continue;
    const lines = additions.map(name => `        <members>${name}</members>`).join('\n');
    if (block) manifest = manifest.replace(block, block.replace(`        <name>${type}</name>`, `${lines}\n        <name>${type}</name>`));
    else manifest = manifest.replace('    <version>', `    <types>\n${lines}\n        <name>${type}</name>\n    </types>\n    <version>`);
}
fs.writeFileSync(manifestPath, manifest);
