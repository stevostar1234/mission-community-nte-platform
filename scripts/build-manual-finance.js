// Manual finance workflow metadata extensions. The main build recreates its inputs.
const fs = require('fs');
const path = require('path');
const {compileEmailPresentation, nativeEmailTextFromHtml} = require('./email-template-presentation');
const root = path.resolve(__dirname, '..');
const md = path.join(root, 'force-app/main/default');
const esc = value => String(value).replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/'/g, '&apos;').replace(/"/g, '&quot;');
const source = fs.readFileSync(path.join(root, 'email-templates/source/staff-top-up-payment.html'), 'utf8');
const html = compileEmailPresentation(source);
const email = path.join(md, 'email/unfiled$public/NTE_Staff_Top_Up_Payment');
fs.writeFileSync(email + '.email', html);
fs.writeFileSync(email + '.email-meta.xml', `<?xml version="1.0" encoding="UTF-8"?>
<EmailTemplate xmlns="http://soap.sforce.com/2006/04/metadata">
<available>true</available><description>NTE staff top-up payment request</description><encodingKey>UTF-8</encodingKey>
<name>NTE staff top-up payment request</name><style>none</style><subject>Your NTE staff top-up payment</subject>
<textOnly>${esc(nativeEmailTextFromHtml(html))}</textOnly><type>custom</type><uiType>Aloha</uiType>
</EmailTemplate>\n`);
const paymentButton = fs.readFileSync(path.join(root, 'email-templates/examples/exhibitor-stripe-provisional.html'), 'utf8').match(/<table data-nte-payment-button="true"[\s\S]*?<\/table>/)[0];
const previewMoneyRow = (label, amount) => `<tr><td style="padding:12px 18px;border-bottom:1px solid #e4edf2;">${label}</td><td align="right" style="padding:12px 18px;border-bottom:1px solid #e4edf2;white-space:nowrap;">£${amount.toFixed(2)}</td></tr>`;
const topUpSummary = '<table role="presentation" width="100%" cellspacing="0" cellpadding="0">' + previewMoneyRow('Staff top-up', 100) + previewMoneyRow('VAT (20%)', 20) + previewMoneyRow('Total including VAT', 120) + '</table>' + paymentButton;
let preview = html.replace(/\{!IF\(ISBLANK\(Contact.FirstName\),"Hello,","Hi "\)\}\{!Contact.FirstName\}\{!IF\(ISBLANK\(Contact.FirstName\),"",","\)\}/g, 'Hi Alex,')
    .replaceAll('{!Opportunity.Booking_Reference__c}', 'NTE-2027-EX-0001')
    .replaceAll('<!--NTE_TOKEN:{NTE_ORGANISATION}-->', 'Example Engineering Ltd')
    .replaceAll('<!--NTE_TOKEN:{NTE_FINANCE_SUMMARY}-->', topUpSummary);
fs.writeFileSync(path.join(root, 'email-templates/examples/staff-top-up-payment.html'), preview);
for (const permission of ['NTE_Forms_Administration', 'NTE_Management_User']) {
    const file = path.join(md, `permissionsets/${permission}.permissionset-meta.xml`);
    let xml = fs.readFileSync(file, 'utf8');
    const index = xml.lastIndexOf('</classAccesses>') + '</classAccesses>'.length;
    xml = xml.slice(0,index) + '\n<classAccesses><apexClass>NTEFinanceService</apexClass><enabled>true</enabled></classAccesses>' + xml.slice(index);
    fs.writeFileSync(file,xml);
}
const manifestFile = path.join(root, 'manifest/production-package.xml');
let manifest = fs.readFileSync(manifestFile, 'utf8');
const additions = {CustomField: ['NTE_Price_Adjustment__c', 'NTE_Free_Space_Confirmed__c', 'NTE_Approval_Email_Kind__c', 'NTE_Finance_Requirements_Due__c', 'NTE_PO_Confirmed__c', 'NTE_Agreement_Provided__c', 'NTE_Invoice_Details_Included__c', 'NTE_Bank_Details_Provided__c', 'NTE_Top_Up_Payment_Requested_At__c', 'NTE_Joining_Instructions_By__c'].map(field => 'Opportunity.' + field).concat(['Lead.Invoice_Requested__c', 'Opportunity.NTE_Invoice_Requested__c']), ListView: ['Opportunity.NTE_Requirements'], ApexClass: ['NTEBookingPriceService', 'NTEBookingPriceServiceTest', 'NTEBookingWaiverTest', 'NTEFinanceService', 'NTEConversionGuard', 'NTEManualFinanceTest', 'NTEManualStripeTest'], ApexTrigger: ['NTEOpportunityConversionGuard', 'NTELeadConversionGuard'], EmailTemplate: ['unfiled$public/NTE_Staff_Top_Up_Payment', 'unfiled$public/NTE_Partner_Sponsor_Free_Confirmed']};
for (const [type,names] of Object.entries(additions)) {
    const block=(manifest.match(/<types>[\s\S]*?<\/types>/g)||[]).find(b=>b.includes(`<name>${type}</name>`));
    const lines=names.filter(n=>!block?.includes(`<members>${n}</members>`)).map(n=>`        <members>${n}</members>`).join('\n');
    if (!lines) continue;
    if (block) manifest=manifest.replace(block,block.replace(`        <name>${type}</name>`,`${lines}\n        <name>${type}</name>`));
    else manifest=manifest.replace('    <version>',`    <types>\n${lines}\n        <name>${type}</name>\n    </types>\n    <version>`);
}
fs.writeFileSync(manifestFile,manifest);
