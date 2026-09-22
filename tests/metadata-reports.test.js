"use strict";

const assert = require("assert");
const fs = require("fs");
const path = require("path");
const vm = require("vm");
const {currencyPreview} = require("../scripts/email-formatting");
const {previewEmailPresentation} = require("../scripts/email-template-presentation");
const root = path.resolve(__dirname, "..");
const source = fs.readFileSync(path.join(root, "scripts/build-metadata.js"), "utf8");

// Inspect only pure definitions. This test does not execute either generator.
function definitions(start, end, result, context = {}) {
  const from = source.indexOf(start);
  const to = source.indexOf(end, from);
  assert(from >= 0 && to > from, `Missing definition boundaries: ${start}`);
  return vm.runInNewContext(`${source.slice(from, to)}\n${result}`, context);
}
const reports = definitions("const nteReports = {", "for (const [api, definition] of Object.entries(nteReports))", "nteReports");
assert.strictEqual(Object.keys(reports).length, 9);
const leadLists = definitions("const leadListViews = {", "Object.entries(leadListViews).forEach", "leadListViews");
for (const field of ["NTE_Interest_Progressed__c", "NTE_Interest_Not_Progressed__c"]) {
  assert(leadLists.NTE_Expressions_of_Interest[2].some(filter => filter.field === field && filter.value === "0"), "The global interest list excludes recorded decisions");
}
for (const api of ["NTE_Applications", "NTE_Partner_Sponsor_Applications", "NTE_Exhibitor_Applications"]) {
  assert(leadLists[api][2].some(filter => filter.field === "NTE_Application_Rejected__c" && filter.value === "0"), `${api} excludes rejected applications`);
}

function reportIncludes(report, row) {
  const result = report.filters.map(filter => {
    const value = row[filter.column];
    const wanted = filter.value;
    if (filter.operator === "greaterThan") return value != null && Number(value) > Number(wanted);
    if (filter.operator === "notEqual") return String(value) !== wanted;
    return String(value) === wanted;
  });
  const logic = (report.booleanFilter || result.map((_, index) => index + 1).join(" AND "))
    .replace(/\d+/g, index => {
      assert(Number(index) >= 1 && Number(index) <= result.length, "Every Boolean filter index must exist");
      return String(result[Number(index) - 1]);
    }).replace(/AND/g, "&&").replace(/OR/g, "||");
  return vm.runInNewContext(logic);
}
const base = {
  RECORDTYPE: "Opportunity.NTE_Event_Opportunity", CLOSED: false, WON: false,
  "Opportunity.NTE_Source_Form_Type__c": "Exhibitor Application",
  "Opportunity.NTE_Invoice_Required__c": "Yes",
  "Opportunity.NTE_Listed_Price_Total__c": 800,
  "Opportunity.NTE_Top_Up_Invoice_Required__c": false,
  "Opportunity.NTE_Top_Up_Staff_Total__c": 0,
  "Opportunity.NTE_Pricing_Ready__c": true,
  "Opportunity.NTE_Heavy_Vehicle_Required__c": "Yes"
};
for (const [api, report] of Object.entries(reports)) {
  assert(report.groupings.some(field => field.endsWith("NTE_Event_Code__c")), `${api} groups by event`);
  if (report.reportType !== "Opportunity") continue;
  assert(report.columns.includes("CONTACT"), `${api} includes the actual Primary Contact column`);
  const scope = report.filters.find(filter => filter.column === "RECORDTYPE");
  assert(scope && scope.isUnlocked === false, `${api} locks the NTE record type`);
  const row = {...base};
  if (api.startsWith("NTE_02")) row["Opportunity.NTE_Source_Form_Type__c"] = "Partner / Sponsor Application";
  assert(reportIncludes(report, row), `${api} includes its ordinary booking`);
  assert(!reportIncludes(report, {...row, RECORDTYPE: "Opportunity.Other"}), `${api} excludes another record type`);
  assert(!reportIncludes(report, {...row, CLOSED: true, WON: false, STAGE_NAME: "Declined"}), `${api} excludes any closed loss`);
  assert(reportIncludes(report, {...row, CLOSED: true, WON: true}), `${api} retains a won booking`);
  assert(reportIncludes(report, {...row, "Opportunity.NTE_Event_Code__c": "NTE2099"}), `${api} retains future editions`);
}
for (const api of ["NTE_06_Finance_and_Invoicing", "NTE_09_Weekly_Finance_Report"]) {
  const report = reports[api];
  const free = {...base, "Opportunity.NTE_Invoice_Required__c": "No", "Opportunity.NTE_Listed_Price_Total__c": 0};
  assert(reportIncludes(report, free), `${api}: complimentary bookings remain visible for their explicit confirmation`);
  assert(reportIncludes(report, {...free, "Opportunity.NTE_Top_Up_Staff_Total__c": 50}), `${api}: include top-up-only charges`);
  assert(reportIncludes(report, {...free, "Opportunity.NTE_Quote_Required_for_PO__c": "Yes"}), `${api}: include quote-only work`);
  assert(reportIncludes(report, {...free, "Opportunity.NTE_Pricing_Ready__c": false}), `${api}: include missing/invalid pricing`);
  assert(report.columns.includes("Opportunity.NTE_Top_Up_Invoice_By__c"), `${api}: retain top-up invoice audit user`);
  assert(report.columns.includes("Opportunity.NTE_Top_Up_Payment_By__c"), `${api}: retain top-up payment audit user`);
}
const readiness = reports.NTE_08_Event_Delivery_Readiness;
for (const field of ["NTE_Logo_Update_Provided__c", "NTE_Logo_Update_Provided_At__c", "NTE_Final_Pack_Status__c", "NTE_Final_Pack_Sent_At__c"]) {
  assert(readiness.columns.includes(`Opportunity.${field}`), `Readiness includes ${field}`);
}
const pipeline = reports.NTE_07_Application_and_EOI_Pipeline;
assert(reportIncludes(pipeline, {"Lead.Web_Form_Type__c": "Exhibitor Application", CONVERTED: false, "Lead.NTE_Application_Rejected__c": true}), "Pipeline retains recorded decisions for historical reporting");
assert(!reportIncludes(pipeline, {"Lead.Web_Form_Type__c": "Exhibitor Application", CONVERTED: true}), "Pipeline excludes converted Leads");
assert.strictEqual(reports.NTE_09_Weekly_Finance_Report.timeInterval, "INTERVAL_LAST7");

const currencyFields = object => fs.readdirSync(path.join(root, "force-app/main/default/objects", object, "fields"))
  .filter(file => fs.readFileSync(path.join(root, "force-app/main/default/objects", object, "fields", file), "utf8").includes("<type>Currency</type>"))
  .map(file => ({api: file.replace(".field-meta.xml", ""), type: "Currency"}));
const previewContext = {vatRate: require("../config/nte-pricing.json").vatRate, fs, path, root, currencyPreview, previewEmailPresentation, leadFields: currencyFields("Lead"), opportunityFields: currencyFields("Opportunity")};
definitions("const emailPreviewValues = {", "for (const type of ['exhibitor', 'partner-sponsor'])", `
  emailPreviewValues.Company = 'Meridian {NTE_FINANCE_SUMMARY} {!Contact.Email}';
  this.preview = emailPreviewHtml('exhibitor-approved-confirmation.html');
`, previewContext);
assert(previewContext.preview.includes("Meridian {NTE_FINANCE_SUMMARY} {!Contact.Email}"), "Literal template-like text is neither recursively replaced nor rejected");
assert(!previewContext.preview.includes("<!--NTE_TOKEN:"), "Source-owned template markers are all resolved");
assert(previewContext.preview.includes("NTE-2027-EX-0001"), "Preview booking references use the accepted grammar");

if (process.argv.includes("--generated")) {
  const md = path.join(root, "force-app/main/default");
  const manifest = fs.readFileSync(path.join(root, "manifest/production-package.xml"), "utf8");
  for (const api of ["NTE_Pricing_Ready__c", "NTE_Finance_Requirements_Due__c", "NTE_Finance_Payment_Due__c", "NTE_Finance_Payment_Confirmed__c"]) {
    assert(fs.existsSync(path.join(md, "objects/Opportunity/fields", `${api}.field-meta.xml`)), `${api}: generated field exists`);
    assert(manifest.includes(`<members>Opportunity.${api}</members>`), `${api}: package includes formula`);
    for (const permission of ["NTE_Forms_Administration", "NTE_Management_User"]) {
      const xml = fs.readFileSync(path.join(md, "permissionsets", `${permission}.permissionset-meta.xml`), "utf8");
      assert(xml.includes(`<editable>false</editable>\n        <field>Opportunity.${api}</field>`), `${permission}: formula is readable and not editable`);
    }
  }
  for (const [api, predicate] of [["NTE_Requirements", "NTE_Finance_Requirements_Due__c"], ["NTE_Payments_Due", "NTE_Finance_Payment_Due__c"], ["NTE_Payment_Confirmed", "NTE_Finance_Payment_Confirmed__c"]]) {
    const xml = fs.readFileSync(path.join(md, "objects/Opportunity/listViews", `${api}.listView-meta.xml`), "utf8");
    assert(xml.includes(`<field>${predicate}</field>`), `${api}: final generator output keeps combined charge filter`);
    assert(xml.includes("NTE_Top_Up_Total_Inc_VAT__c"), `${api}: both charges are visible`);
    assert((xml.match(/<filters>/g) || []).length <= 10, `${api}: respects native list-view filter limit`);
  }
  for (const permission of ["NTE_Forms_Administration", "NTE_Management_User"]) {
    const xml = fs.readFileSync(path.join(md, "permissionsets", `${permission}.permissionset-meta.xml`), "utf8");
    assert(xml.includes("<editable>false</editable>\n        <field>Lead.NTE_Update_Booking_Id__c</field>"), `${permission}: accepted update identity is read-only`);
    assert(xml.includes("<editable>true</editable>\n        <field>Opportunity.NTE_Free_Space_Confirmed__c</field>"), `${permission}: the free-space confirmation stays editable as a manual fallback`);
    assert(xml.includes("<apexClass>NTE_MasterPanelController</apexClass>"), `${permission}: panel access is self-contained`);
    assert(xml.includes("<application>NTE_Management</application>"), `${permission}: app access is self-contained`);
  }
  const recordPage = fs.readFileSync(path.join(md, "flexipages/NTE_Management_Opportunity_Record_Page.flexipage-meta.xml"), "utf8");
  assert(recordPage.includes("<fieldItem>Record.NTE_Free_Space_Confirmed__c</fieldItem>"), "the record page shows the free-space confirmation");
  assert(!/<value>readonly<\/value>\s*<\/fieldInstanceProperties>\s*<fieldItem>Record\.NTE_Free_Space_Confirmed__c<\/fieldItem>/.test(recordPage), "the record page no longer locks the free-space confirmation");
  const conversion = fs.readFileSync(path.join(md, "flows/NTE_Copy_Converted_Lead_to_Opportunity.flow-meta.xml"), "utf8");
  assert(/<start>[\s\S]*?<targetReference>Conversion_Just_Completed<\/targetReference>/.test(conversion), "Conversion checks the actual transition before copying application data");
  assert(conversion.includes("<leftValueReference>$Record__Prior.IsConverted</leftValueReference><operator>EqualTo</operator><rightValue><booleanValue>false</booleanValue></rightValue>"), "Later converted-Lead edits cannot overwrite the reviewed booking");
  assert(/<name>New_Conversion<\/name>[\s\S]*?<targetReference>Price_Application_For_Conversion<\/targetReference>/.test(conversion), "A new conversion still reprices before copying stored Lead values");
  assert(conversion.includes("<assignToReference>Priced_Application</assignToReference><name>pricedLead</name>"), "Conversion captures the invocable's priced snapshot");
  for (const target of ["Amount", "NTE_Listed_Price_Total__c", "NTE_Initial_Staff_Count__c", "NTE_Invoice_Required__c"]) {
    assert(new RegExp(`<field>${target}</field>\\s*<value><elementReference>Priced_Application\\.`).test(conversion), `${target}: maps calculated conversion values`);
  }
  assert(conversion.includes("<elementReference>$Record.Event_Contact_Email__c</elementReference>"), "Repricing does not replace contact inputs");
  for (const api of ["NTE_Inbound_Lead_Routing", "Volunteer_Inbound_Lead_Notification", "NTE_Supplementary_Update_Handler"]) {
    assert(fs.readFileSync(path.join(md, "flows", `${api}.flow-meta.xml`), "utf8").includes("<name>isNewSubmission</name>"), `${api}: identifies first intake for audit normalization`);
  }
}
console.log("Metadata/report semantics and literal email-token preview checks passed.");
