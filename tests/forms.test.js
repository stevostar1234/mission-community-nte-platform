"use strict";

const assert = require("assert");
const fs = require("fs");
const path = require("path");
const vm = require("vm");
const {currencyPreview, plainTextFromHtml} = require("../scripts/email-formatting");
const {compileEmailPresentation, previewEmailPresentation, nativeEmailTextFromHtml} = require("../scripts/email-template-presentation");
require("./email-assets.test");
require("./email-template-presentation.test");

const root = path.resolve(__dirname, "..");
const documentStub = {
  querySelectorAll: () => [],
  querySelector: () => null
};
const context = {
  window: {},
  document: documentStub,
  Intl,
  Date,
  Uint8Array,
  URL,
  Math,
  console
};
context.window.crypto = require("crypto").webcrypto;
context.window.location = {href: "https://stevostar1234.github.io/nte27-web-to-lead-demo/volunteer-application.html"};
vm.createContext(context);
vm.runInContext(fs.readFileSync(path.join(root, "assets", "config.js"), "utf8"), context);
vm.runInContext(fs.readFileSync(path.join(root, "assets", "forms.js"), "utf8"), context);

const utils = context.window.NTEFormUtils;
assert(utils, "NTE form utilities should be available");
assert.strictEqual(context.window.NTE_CONFIG.mode, "sandbox", "the hosted QA build must post to the Salesforce sandbox");
assert.strictEqual(
  context.window.NTE_CONFIG.endpoint,
  "https://missionmotorsportnpc--mmuat.sandbox.my.salesforce.com/servlet/servlet.WebToLead?encoding=UTF-8",
  "the hosted QA build must use the MMUAT My Domain Web-to-Lead endpoint"
);
assert.strictEqual(context.window.NTE_CONFIG.eventCodeOverride, "", "the hosted build should calculate the event code unless an override is explicitly configured");
assert.strictEqual(context.window.NTE_CONFIG.eventCodeTimeZone, "Europe/London", "event-year boundaries must follow the event's local time zone");
assert(context.window.NTE_CONFIG.returnUrl.includes("github.io/nte27-web-to-lead-demo/thank-you.html"));
assert.strictEqual(context.window.NTE_CONFIG.termsUrl, "https://www.nationaltransitionevent.com/privacy");

for (let year = 2026; year <= 2032; year += 1) {
  assert.strictEqual(utils.eventCodeFor(`${year}-01-01`), `NTE${year}`, `${year}: January must stay in the current event year`);
  assert.strictEqual(utils.eventCodeFor(`${year}-03-31`), `NTE${year}`, `${year}: 31 March must stay in the current event year`);
  assert.strictEqual(utils.eventCodeFor(`${year}-04-01`), `NTE${year + 1}`, `${year}: 1 April must start the next event year`);
  assert.strictEqual(utils.eventCodeFor(`${year}-12-31`), `NTE${year + 1}`, `${year}: December must use the next event year`);
  assert.strictEqual(utils.eventCodeFor(new Date(`${year}-03-31T22:59:59.999Z`), "Europe/London"), `NTE${year}`, `${year}: final instant before the London boundary`);
  assert.strictEqual(utils.eventCodeFor(new Date(`${year}-03-31T23:00:00.000Z`), "Europe/London"), `NTE${year + 1}`, `${year}: first instant at the London boundary`);
}

for (const leapYear of [2028, 2032]) {
  assert.strictEqual(utils.eventCodeFor(`${leapYear}-02-28`), `NTE${leapYear}`);
  assert.strictEqual(utils.eventCodeFor(`${leapYear}-02-29`), `NTE${leapYear}`);
  assert.strictEqual(utils.eventCodeFor(`${leapYear}-03-01`), `NTE${leapYear}`);
}
for (const nonLeapYear of [2026, 2027, 2029, 2030, 2031]) {
  assert.strictEqual(utils.eventCodeFor(`${nonLeapYear}-02-28`), `NTE${nonLeapYear}`);
  assert.strictEqual(utils.eventCodeFor(`${nonLeapYear}-03-01`), `NTE${nonLeapYear}`);
}
assert.throws(() => utils.eventCodeFor("2027-02-29"), /Invalid calendar date/);
assert.throws(() => utils.eventCodeFor("2032-13-01"), /Invalid calendar date/);
assert.throws(() => utils.eventCodeFor(new Date("invalid")), /valid Date/);

const crossZoneInstant = new Date("2028-04-01T00:30:00.000Z");
for (const zone of ["UTC", "Europe/London", "Pacific/Auckland"]) {
  assert.strictEqual(utils.eventCodeFor(crossZoneInstant, zone), "NTE2029", `${zone}: instant is on 1 April 2028 locally`);
}
for (const zone of ["America/New_York", "America/Los_Angeles", "Pacific/Honolulu"]) {
  assert.strictEqual(utils.eventCodeFor(crossZoneInstant, zone), "NTE2028", `${zone}: instant is still on 31 March 2028 locally`);
}

assert.strictEqual(utils.resolveEventCode("2027-03-31"), "NTE2027", "blank override must use the automatic rule");
context.window.NTE_CONFIG.eventCodeOverride = " NTE2099 ";
assert.strictEqual(utils.resolveEventCode("2027-03-31"), "NTE2099", "configured override must take precedence");
context.window.NTE_CONFIG.eventCodeOverride = "NTE-2099";
assert.throws(() => utils.resolveEventCode("2027-03-31"), /format NTEYYYY/);
context.window.NTE_CONFIG.eventCodeOverride = "";
assert.strictEqual(utils.formatWebToLeadDate("2026-08-19"), "19/08/2026");
assert.strictEqual(utils.formatWebToLeadDate("not-a-date"), "not-a-date");
assert.strictEqual(utils.resolveReturnUrl({dataset: {returnPath: "volunteer-thank-you.html"}}), "https://stevostar1234.github.io/nte27-web-to-lead-demo/volunteer-thank-you.html");
assert.strictEqual(utils.resolveReturnUrl({dataset: {returnPath: "https://example.com/redirect"}}), context.window.NTE_CONFIG.returnUrl, "form return paths must remain on the current site origin");

const references = new Set(Array.from({length: 100}, () => utils.bookingReference()));
assert.strictEqual(references.size, 100, "booking references should be unique in the sample");
for (const reference of references) assert(/^NTE-\d{13}-[A-HJ-NP-Z2-9]{8}$/.test(reference), `invalid booking reference: ${reference}`);

const htmlFiles = [
  "partner-sponsor-interest.html",
  "exhibitor-interest.html",
  "partner-sponsor-application.html",
  "exhibitor-application.html",
  "guest-registration.html",
  "partner-sponsor-staff-update.html",
  "exhibitor-staff-update.html",
  "heavy-vehicle-details.html",
  "volunteer-application.html"
];
const expectedEmailPreviews = {
  "partner-sponsor-interest.html": [
    "partner-sponsor-interest-applicant-confirmation.html",
    "partner-sponsor-interest-internal-notification.html"
  ],
  "exhibitor-interest.html": [
    "exhibitor-interest-applicant-confirmation.html",
    "exhibitor-interest-internal-notification.html"
  ],
  "partner-sponsor-application.html": [
    "partner-sponsor-application-internal-notification.html",
    "partner-sponsor-approved-confirmation.html",
    "partner-sponsor-payment-confirmed.html"
  ],
  "exhibitor-application.html": [
    "exhibitor-application-internal-notification.html",
    "exhibitor-approved-confirmation.html",
    "government-charity-approved-confirmation.html",
    "exhibitor-payment-confirmed.html"
  ],
  "guest-registration.html": [
    "guest-registration-applicant-confirmation.html",
    "guest-registration-internal-notification.html"
  ],
  "partner-sponsor-staff-update.html": ["partner-sponsor-staff-update-applicant-confirmation.html"],
  "exhibitor-staff-update.html": ["exhibitor-staff-update-applicant-confirmation.html"],
  "heavy-vehicle-details.html": ["heavy-vehicle-details-applicant-confirmation.html"],
  "volunteer-application.html": [
    "volunteer-application-applicant-confirmation.html",
    "volunteer-application-internal-notification.html"
  ]
};
const customFieldIds = context.window.NTE_CONFIG.customFieldIds;
const fieldLimits = context.window.NTE_CONFIG.fieldLimits;
const expectedAssetVersion = "20260908-1";
for (const file of htmlFiles) {
  const html = fs.readFileSync(path.join(root, file), "utf8");
  const vatForm = ["partner-sponsor-application.html", "exhibitor-application.html", "exhibitor-staff-update.html"].includes(file);
  const expectedScriptVersion = "20260915-spaces-1";
  assert(html.includes("assets/config.js?v=20260913-finance-2"), `${file}: config asset version is stale`);
  assert(html.includes(`assets/forms.js?v=${expectedScriptVersion}`), `${file}: forms asset version is stale`);
  assert(html.includes(`assets/styles.css?v=${vatForm ? "20260913-vat" : expectedAssetVersion}`), `${file}: stylesheet asset version is stale`);
  assert(html.includes('data-use-default-rule="0"'), `${file}: Salesforce default auto-response must remain disabled`);
  if (file === "volunteer-application.html") {
    assert(html.includes('data-lead-source="Volunteer Application"'), "the volunteer form must use its isolated Lead source");
    assert(!html.includes('data-sf-field="NTE_Event_Code__c"'), "the volunteer form must not enter the NTE data model");
    assert(html.includes('data-return-path="volunteer-thank-you.html"'), "the volunteer form must use its own acknowledgement page");
  } else {
    assert(html.includes('data-lead-source="Customer Event"'), `${file} must use the NTE-specific event source`);
    assert(html.includes('data-sf-field="NTE_Event_Code__c"'), `${file} must supply the calculated event code`);
  }
  assert(/<label class="required" for="[^"]+">Digital signature \(full name\)<\/label><input[^>]+required[^>]+data-sf-field="Declaration_Name__c"/.test(html), `${file} must require a digital signature`);
  assert(/<label class="required" for="[^"]+">Date<\/label><input[^>]+type="date"[^>]+required[^>]+data-sf-field="Declaration_Date__c"/.test(html), `${file} must require a declaration date`);
  assert(html.includes('class="email-preview-panel"'), `${file}: current email previews must be visible below the form`);
  for (const preview of expectedEmailPreviews[file]) {
    assert(html.includes(`href="email-templates/examples/${preview}"`), `${file}: missing email preview ${preview}`);
  }
  const fields = [...html.matchAll(/data-sf-field="([A-Za-z0-9_]+)"/g)].map((match) => match[1]);
  for (const api of fields.filter((field) => field.endsWith("__c"))) {
    assert(Object.prototype.hasOwnProperty.call(customFieldIds, api), `${file}: missing config entry for ${api}`);
  }

  const ids = [...html.matchAll(/\sid="([^"]+)"/g)].map((match) => match[1]);
  assert.strictEqual(new Set(ids).size, ids.length, `${file}: every HTML id must be unique`);
  for (const labelTarget of [...html.matchAll(/<label\b[^>]*\sfor="([^"]+)"/g)].map((match) => match[1])) {
    assert(ids.includes(labelTarget), `${file}: label points to missing control #${labelTarget}`);
  }
  for (const sourceId of [...html.matchAll(/data-conditional-for="([^"]+)"/g)].map((match) => match[1])) {
    assert(ids.includes(sourceId), `${file}: conditional section points to missing source #${sourceId}`);
  }
  const copySources = [
    ...[...html.matchAll(/data-copy-value-from="([^"]+)"/g)].map((match) => match[1]),
    ...[...html.matchAll(/data-combine-fields="([^"]+)"/g)].flatMap((match) => match[1].split(",")),
    ...[...html.matchAll(/data-checkbox-copy-from="([^"]+)"/g)].map((match) => match[1])
  ];
  for (const sourceId of copySources) assert(ids.includes(sourceId.trim()), `${file}: copy rule points to missing source #${sourceId}`);

  for (const match of html.matchAll(/<(input|textarea)\b([^>]*)data-sf-field="([A-Za-z0-9_]+)"([^>]*)>/g)) {
    const attributes = match[2] + match[4];
    const api = match[3];
    if (/type="(?:hidden|checkbox|radio|number|date)"/.test(attributes) || !api.endsWith("__c")) continue;
    assert(Number.isInteger(fieldLimits[api]), `${file}: text field ${api} must have an exact Salesforce maxlength`);
  }

  for (const href of [...html.matchAll(/\shref="([^"]+\.html(?:#[^"]*)?)"/g)].map((match) => match[1].split("#")[0])) {
    assert(fs.existsSync(path.join(root, href)), `${file}: local link target ${href} must exist`);
  }
}

const logoUpdateHtml = fs.readFileSync(path.join(root, "logo-upload.html"), "utf8");
assert(logoUpdateHtml.includes('data-use-default-rule="0"'), "logo update must not trigger the generic Web-to-Lead response");
assert(!logoUpdateHtml.includes('data-sf-field="Declaration_Name__c"'), "logo update no longer collects a signature");
assert(!logoUpdateHtml.includes('data-sf-field="Declaration_Date__c"'), "logo update no longer collects a declaration date");
assert(!logoUpdateHtml.includes('type="checkbox"'), "logo update no longer requires an upload checkbox");

const emailSourceDirectory = path.join(root, "email-templates", "source");
const emailExampleDirectory = path.join(root, "email-templates", "examples");
const emailSourceFiles = fs.readdirSync(emailSourceDirectory).filter((file) => file.endsWith(".html")).sort();
const metadataGenerator = fs.readFileSync(path.join(root, "scripts", "build-metadata.js"), "utf8");
const templateDeclarations = metadataGenerator.match(/const templates = \{([\s\S]*?)\n\};/);
assert(templateDeclarations, "the metadata generator must define its email source mapping");
const templateMappings = [...templateDeclarations[1].matchAll(/\b([A-Za-z0-9_]+): \["([^"]+\.html)"/g)]
  .map((match) => [match[2], match[1]]);
const templateApiBySourceFile = new Map(templateMappings);
assert.strictEqual(emailSourceFiles.length, 20, "all active NTE and volunteer email templates must remain available for preview generation");
assert.strictEqual(templateMappings.length, emailSourceFiles.length, "source templates must not be duplicated under multiple generated names");
assert.deepStrictEqual([...templateApiBySourceFile.keys()].sort(), emailSourceFiles, "every email source must map to exactly one generated Salesforce template");
for (const file of emailSourceFiles) {
  const source = fs.readFileSync(path.join(emailSourceDirectory, file), "utf8");
  const templatePath = path.join(root, "force-app", "main", "default", "email", "unfiled$public", `${templateApiBySourceFile.get(file)}.email`);
  assert.strictEqual(fs.readFileSync(templatePath, "utf8"), compileEmailPresentation(source), `${file}: the deployed template must match its maintained source and native presentation conditions`);
  const examplePath = path.join(emailExampleDirectory, file);
  assert(fs.existsSync(examplePath), `${file}: a current browser preview must be generated`);
  const example = fs.readFileSync(examplePath, "utf8");
  assert(!/(?:£|&pound;|&#163;)\s*(?:£|&pound;|&#163;)/i.test(example), `${file}: preview must not duplicate the Salesforce currency symbol`);
  assert(!/white-space:\s*pre(?:-line|-wrap)?/.test(source), `${file}: native Salesforce line breaks must not be doubled by preserved whitespace`);
  const templateMetadata = fs.readFileSync(`${templatePath}-meta.xml`, "utf8");
  const textAlternative = templateMetadata.match(/<textOnly>([\s\S]*?)<\/textOnly>/);
  assert(textAlternative && textAlternative[1].trim(), `${file}: provide a readable text alternative instead of Salesforce's tag-stripped fallback`);
  const expectedText = nativeEmailTextFromHtml(compileEmailPresentation(source)).replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;").replace(/'/g, "&apos;").replace(/"/g, "&quot;");
  assert.strictEqual(textAlternative[1], expectedText, `${file}: generated text must use native-safe conditional row separation`);
  assert(!/email-shell|@media|&lt;\/?(?:table|td|p|style)\b/.test(textAlternative[1]), `${file}: text alternative must not contain email markup or styles`);
  assert(!/\{![^}]+\}/.test(example), `${file}: browser preview must not expose unresolved Salesforce merge fields`);
  assert(!/\{NTE_[A-Z_]+\}/.test(example), `${file}: browser preview must not expose unresolved booking content tokens`);
  const previewPattern = previewEmailPresentation(source, () => "populated").split(/(\{![^}]+\}|<!--NTE_TOKEN:\{NTE_[A-Z_]+\}-->|\{NTE_[A-Z_]+\})/g).map((part) => {
    if (/^(?:\{(?:!|NTE_)|<!--NTE_TOKEN:)/.test(part)) return "[\\s\\S]*?";
    return part.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
  }).join("");
  assert(new RegExp(`^${previewPattern}$`).test(example), `${file}: preview copy must match the source outside its explicit merge tokens`);
}
assert.strictEqual(currencyPreview("1234.5"), "£1,234.50");
assert.strictEqual(currencyPreview("0.00"), "£0.00");
assert.strictEqual(currencyPreview("-50"), "-£50.00");
assert.throws(() => currencyPreview("£50.00"), /Invalid currency preview value/);
const staffEmailPreview = fs.readFileSync(path.join(emailExampleDirectory, "exhibitor-staff-update-applicant-confirmation.html"), "utf8");
assert(staffEmailPreview.includes(">£100.00</td>") && staffEmailPreview.includes(">£20.00</td>") && staffEmailPreview.includes(">£120.00</td>"), "top-up currency must include exactly Salesforce's one pound symbol");
assert(staffEmailPreview.includes("Alex Morgan\n<br>Jordan Lee\n<br>Priya Shah\n<br>Daniel Evans"), "staff preview must reproduce Salesforce's HTML line-break merging");
const internalExhibitorPreview = fs.readFileSync(path.join(emailExampleDirectory, "exhibitor-application-internal-notification.html"), "utf8");
assert(internalExhibitorPreview.includes("2 at £50.00 each"), "the staff unit-price merge must retain one pound symbol in the internal notification");
assert.strictEqual(plainTextFromHtml('<head><title>Hidden title</title><style>.hidden{display:none}</style></head><div class="preheader">Hidden preview</div><p>Hello &lt;Team&gt; &amp; friends.</p><table><tr><td>Names</td><td>Alex<br>Jo</td></tr><tr><td>Total</td><td>&pound;1,234.50</td></tr></table><p><a href="https://example.com/?a=1&amp;b=2">Open booking</a></p>'),
  'Hello <Team> & friends.\n\nNames Alex\nJo\nTotal £1,234.50\n\nOpen booking (https://example.com/?a=1&b=2)',
  "text email must separate rows and paragraphs, preserve names and links, and decode entities once");
const staffTextMetadata = fs.readFileSync(path.join(root, "force-app", "main", "default", "email", "unfiled$public", "NTE_Exhibitor_Staff_Update_Acknowledgement.email-meta.xml"), "utf8");
assert(staffTextMetadata.includes("Staff names {!Lead.Staff_Base_Names__c}\nTop-up places {!Lead.Top_Up_Staff_Count__c}\nTop-up names {!Lead.Top_Up_Staff_Names__c}\nSubtotal (ex VAT) {!Lead.Top_Up_Staff_Total__c}\nVAT (20%) {!Lead.Top_Up_VAT_Total__c}\nTop-up total (inc VAT) {!Lead.Top_Up_Total_Inc_VAT__c}"),
  "deployed staff acknowledgement must keep separate readable rows and unprefixed native currency merging");
const previewLinkCount = Object.values(expectedEmailPreviews).reduce((total, previews) => total + previews.length, 0);
assert.strictEqual(previewLinkCount, 18, "the nine submission forms must expose every relevant non-duplicate email preview");

const indexHtml = fs.readFileSync(path.join(root, "index.html"), "utf8");
assert(indexHtml.includes('href="partner-sponsor-application.html"'), "partner application must be listed on the public hub");
assert(indexHtml.includes('href="exhibitor-interest.html"'), "exhibitor expression of interest must be listed on the public hub");
assert(indexHtml.includes('href="volunteer-application.html"'), "the volunteer application must be listed separately on the public hub");
assert(!fs.readFileSync(path.join(root, "partner-sponsor-application.html"), "utf8").includes('content="noindex,nofollow"'));
assert(fs.readFileSync(path.join(root, "partner-sponsor-staff-update.html"), "utf8").includes('data-sf-field="Target_Booking_Reference__c"'));
assert(fs.readFileSync(path.join(root, "exhibitor-staff-update.html"), "utf8").includes('data-sf-field="Target_Booking_Reference__c"'));
assert(fs.readFileSync(path.join(root, "heavy-vehicle-details.html"), "utf8").includes('data-sf-field="Target_Booking_Reference__c"'));
assert(fs.existsSync(path.join(root, "sandbox-testing-terms.html")), "sandbox terms must be published with the QA site");
assert(fs.existsSync(path.join(root, "thank-you.html")), "the Salesforce return page must be published with the QA site");
const thankYouHtml = fs.readFileSync(path.join(root, "thank-you.html"), "utf8");
assert(!/sent to the email address you provided/i.test(thankYouHtml), "the shared return page must not promise supplementary receipts to the submitter instead of the booking contact");
assert(fs.existsSync(path.join(root, "volunteer-thank-you.html")), "the volunteer return page must be published with the QA site");

const exhibitorHtml = fs.readFileSync(path.join(root, "exhibitor-application.html"), "utf8");
for (const salutation of ["Mr.", "Ms.", "Mrs.", "Dr.", "Prof.", "Mx."]) assert(exhibitorHtml.includes(`<option>${salutation}</option>`));
assert(!exhibitorHtml.includes('id="alternative-name"'), "the former organisation-name question must not remain on the public form");
assert(exhibitorHtml.includes('value="Employer - Defence">Employer - Defence &amp; Security</option>'), "the client-facing Defence & Security label must retain the deployed picklist value");
assert(exhibitorHtml.indexOf("Local Government or LG related") < exhibitorHtml.indexOf("Regular or Reserve Services, or Cadets"), "Services and Cadets must follow Local Government");
assert(exhibitorHtml.indexOf("Trade Association") < exhibitorHtml.indexOf("Charity - member of Cobseo"), "COBSEO charity membership must follow Trade Association");
assert(exhibitorHtml.indexOf("Charity - member of Cobseo") < exhibitorHtml.indexOf("Charity - not a member of Cobseo"), "charity categories must use the client-approved order");
for (const [value, label] of [["NTE2024", "NTE24"], ["NTE2025", "NTE25"], ["NTE2026", "NTE26"]]) {
  assert(exhibitorHtml.includes(`value="${value}" data-sf-field="Previous_NTE_Events__c"> ${label}`), `${label} must retain the deployed ${value} value`);
}
assert(!exhibitorHtml.includes("No included power"), "garage-space wording must not use the rejected phrase");
assert(exhibitorHtml.includes("No power included"), "garage spaces must state that no power is included");
assert(exhibitorHtml.includes("Where payment is required, exhibitor space will only be confirmed once full payment has been received."), "the exhibitor introduction must not promise an invoice independently of the applicant choice");
assert(exhibitorHtml.includes("Entering your name confirms that the information supplied is accurate and you have authority to proceed with booking."), "the declaration must use Kate's approved wording");
for (const field of ["Invoice_Requested__c", "Trading_Name__c", "Invoice_Contact_Phone__c", "Invoice_Additional_Information__c", "Supplier_Agreement_Required__c"]) {
  assert(exhibitorHtml.includes(`data-sf-field="${field}"`), `exhibitor finance section must capture ${field}`);
}
assert(exhibitorHtml.includes("Do you require a purchase order or reference?"), "exhibitor finance section must capture the revised PO or reference requirement");
assert(exhibitorHtml.includes("Do you require a quotation?"), "exhibitor finance section must ask separately about a quotation");
assert(exhibitorHtml.includes("Payment Method"), "exhibitor finance section must ask separately about bank transfer or Stripe");
assert(exhibitorHtml.includes("Legal organisation name for quotation and invoicing"), "exhibitor finance section must request the legal organisation name");
assert(exhibitorHtml.includes("<strong>Please provide the finance contact below, this should be different to the main contact if possible.</strong>"), "exhibitor finance-contact guidance must be prominent");
assert(exhibitorHtml.includes('id="invoice-required" type="hidden" value="No" data-sf-field="Invoice_Required__c"'), "exhibitor pricing must control whether payment and finance questions apply");
assert(exhibitorHtml.includes('id="payment-method" data-required-when-visible data-sf-field="Payment_Method__c"'), "exhibitor applications must capture the selected payment method");
assert(exhibitorHtml.includes('<option>Bank transfer</option>'), "exhibitor applications must offer bank transfer");
assert(exhibitorHtml.includes('<option>Stripe</option>'), "exhibitor applications must offer Stripe");
assert(exhibitorHtml.indexOf('id="payment-method"') < exhibitorHtml.indexOf('id="invoice-requested"') && exhibitorHtml.indexOf('id="invoice-requested"') < exhibitorHtml.indexOf('id="quote-for-po"'), "payment method must precede independent invoice and quotation choices");
assert(exhibitorHtml.indexOf('id="payment-method"') < exhibitorHtml.indexOf('id="purchase-order"'), "the exhibitor payment choice must precede purchase-order details");
assert(exhibitorHtml.indexOf('id="purchase-order"') < exhibitorHtml.indexOf('id="supplier-agreement"'), "the exhibitor purchase-order choice must precede the supplier-agreement choice");
assert(exhibitorHtml.includes('data-copy-value-from="job-title" data-sf-field="Event_Contact_Title__c"'));
assert(exhibitorHtml.includes('data-estimate'), "exhibitor pricing output must be present in the page");
assert(!exhibitorHtml.includes('data-price="poa"'), "application options must all have defined prices");
assert(/id="planned-count"[^>]+type="number"[^>]+min="1"[^>]+max="99"/.test(exhibitorHtml), "exhibitor applications must capture a 1-99 planned staff total");
assert(!exhibitorHtml.includes('data-sf-field="Stand_Colleagues__c"'), "exhibitor applications must not collect staff names before the later update");
for (const field of ["Exhibitor_Space_Price__c", "Power_Socket_Unit_Price__c", "Power_Socket_Total__c", "Included_Staff_Count__c", "Total_Staff_Count__c", "Additional_Staff_Unit_Price__c", "Additional_Staff_Total__c", "Listed_Price_Total__c", "Pricing_Status__c", "Pricing_Version__c"]) {
  assert(exhibitorHtml.includes(`data-sf-field="${field}"`), `exhibitor application must submit ${field}`);
}
const partnerHtml = fs.readFileSync(path.join(root, "partner-sponsor-application.html"), "utf8");
assert(partnerHtml.includes("NTE creates meaningful connections, encourages collaboration and develops long lasting relationships"), "the partner form must use Kate's 15 September introduction");
assert(partnerHtml.includes("All package benefits are listed in the NTE27 Partner and Sponsor Brochure."), "the package section must refer to the brochure");
assert(partnerHtml.includes("There is no additional staff charge for partners and sponsors."), "partner staff guidance must state that additional people are free");
assert(/id="partner-planned-count"[^>]+type="number"[^>]+min="1"[^>]+max="99"/.test(partnerHtml), "partner applications must capture a 1-99 planned staff total");
assert(!partnerHtml.includes('data-sf-field="Stand_Colleagues__c"'), "partner applications must not collect staff names before the later update");
for (const [file, html] of [["partner-sponsor-application.html", partnerHtml], ["exhibitor-application.html", exhibitorHtml]]) {
  const receiptPreview = html.match(/data-confirmation-preview="([^"]+)"/);
  assert(receiptPreview && receiptPreview[1].includes("We have received") && receiptPreview[1].includes("The NTE team will review it"), `${file}: submission must acknowledge an application awaiting review`);
  assert(!/is confirmed|has been approved/i.test(receiptPreview[1]), `${file}: submitting an application must not confirm or approve the booking`);
}
assert(partnerHtml.includes('data-sf-field="Sponsor_Package_Total__c"'), "partner application must submit a numeric package total");
assert(partnerHtml.includes('value="Yes" data-sf-field="Invoice_Required__c"'), "priced partner applications must always require payment");
assert(partnerHtml.includes('id="partner-quote" required data-sf-field="Quote_Required_for_PO__c"'), "quotation preference must not be confused with invoice requirement");
for (const field of ["Invoice_Requested__c", "Trading_Name__c", "Invoice_Contact_Phone__c", "Invoice_Additional_Information__c", "Supplier_Agreement_Required__c", "Declaration_Name__c"]) {
  assert(partnerHtml.includes(`data-sf-field="${field}"`), `partner finance and declaration sections must capture ${field}`);
}
assert(partnerHtml.includes("Do you require a purchase order or reference?"), "partner finance section must capture the revised PO or reference requirement");
assert(partnerHtml.includes("Do you require a quotation?"), "partner finance section must ask separately about a quotation");
assert(partnerHtml.includes("Payment Method"), "partner finance section must ask separately about bank transfer or Stripe");
assert(partnerHtml.includes("Legal organisation name for quotation and invoicing"), "partner finance section must request the legal organisation name");
assert(partnerHtml.includes("<strong>Please provide the finance contact below, this should be different to the main contact if possible.</strong>"), "partner finance-contact guidance must be prominent");
assert(partnerHtml.includes('id="partner-payment-method" required data-sf-field="Payment_Method__c"'), "partner applications must require a payment method");
assert(partnerHtml.includes('<option>Bank transfer</option>'), "partner applications must offer bank transfer");
assert(partnerHtml.includes('<option>Stripe</option>'), "partner applications must offer Stripe");
assert(partnerHtml.indexOf('id="partner-payment-method"') < partnerHtml.indexOf('id="partner-invoice-requested"') && partnerHtml.indexOf('id="partner-invoice-requested"') < partnerHtml.indexOf('id="partner-quote"'), "partner payment method must precede independent invoice and quotation choices");
assert(partnerHtml.indexOf('id="partner-payment-method"') < partnerHtml.indexOf('id="partner-po"'), "the partner payment choice must precede purchase-order details");
assert(partnerHtml.indexOf('id="partner-po"') < partnerHtml.indexOf('id="partner-supplier-agreement"'), "the partner purchase-order choice must precede the supplier-agreement choice");
for (const [id, limit] of [["partner-day-first-name", 40], ["partner-day-last-name", 80], ["partner-day-title", 128], ["partner-day-email", 80], ["partner-day-mobile", 40]]) {
  assert(new RegExp(`id="${id}"[^>]*maxlength="${limit}"`).test(partnerHtml), `${id} must respect its destination field length`);
}
const guestHtml = fs.readFileSync(path.join(root, "guest-registration.html"), "utf8");
for (const [id, limit] of [["guest-companion-first-name", 40], ["guest-companion-last-name", 80]]) {
  assert(new RegExp(`id="${id}"[^>]*maxlength="${limit}"`).test(guestHtml), `${id} must respect its combined destination field length`);
}
const heavyHtml = fs.readFileSync(path.join(root, "heavy-vehicle-details.html"), "utf8");
const formsJs = fs.readFileSync(path.join(root, "assets", "forms.js"), "utf8");
assert(heavyHtml.includes('data-copy-value-from="vehicle-email" data-sf-field="Event_Contact_Email__c"'));
assert(heavyHtml.includes('data-copy-value-from="vehicle-phone" data-sf-field="Event_Contact_Mobile__c"'));
assert(heavyHtml.includes("Manufacturer and model, or a clear description of the item being exhibited"), "heavy-vehicle item wording must be unambiguous");
assert(heavyHtml.includes("Each submission replaces your previous logistics details"), "the logistics form must explain that the complete replacement must include items still attending");
const staffHubHtml = fs.readFileSync(path.join(root, "staff-update.html"), "utf8");
const partnerStaffHtml = fs.readFileSync(path.join(root, "partner-sponsor-staff-update.html"), "utf8");
const exhibitorStaffHtml = fs.readFileSync(path.join(root, "exhibitor-staff-update.html"), "utf8");
assert(staffHubHtml.includes('href="exhibitor-staff-update.html"') && staffHubHtml.includes('href="partner-sponsor-staff-update.html"'), "the staff hub must route each booking type to its correct form");
assert(partnerStaffHtml.includes("Partners and sponsors are not charged for additional staff places."), "partner staff updates must remain free");
assert(/id="partner-staff-total"[^>]+type="number"[^>]+min="1"[^>]+max="99"/.test(partnerStaffHtml), "partner updates must capture the final 1-99 attendance total");
assert(partnerStaffHtml.includes('data-sf-field="Staff_Base_Names__c"'), "partner updates must provide the final roster source of truth");
assert(exhibitorStaffHtml.includes("Top-up places cost £50 + VAT per person and are paid separately by Stripe."), "exhibitor top-ups must explain their separate charge");
assert(exhibitorStaffHtml.includes("You can request additional staff once for this booking."), "the staff form must explain the one-time purchase before submission");
assert(exhibitorStaffHtml.includes("You can still update names afterwards."), "the one-time purchase must still allow roster corrections");
assert(exhibitorStaffHtml.includes("enter the same number of places"), "a names correction must explain how to retain the accepted quantity");
assert(exhibitorStaffHtml.includes('data-sf-field="Top_Up_Staff_Count__c"') && exhibitorStaffHtml.includes('data-sf-field="Top_Up_Staff_Names__c"'), "exhibitor updates must collect top-up count and names separately");
for (const [html, id] of [[partnerStaffHtml, "partner-staff-reference"], [exhibitorStaffHtml, "exhibitor-staff-reference"]]) {
  const pattern = html.match(new RegExp(`id="${id}"[^>]+pattern="([^"]+)"`))[1];
  const referenceValidator = new RegExp(`^(?:${pattern})$`, "v");
  assert(referenceValidator.test("NTE-12345-ABCDE") && !referenceValidator.test("NTE--AB") && !referenceValidator.test("NTE-AB-") && !referenceValidator.test(`NTE-${"A".repeat(77)}`), `${id} must enforce the supported reference format with modern HTML pattern syntax`);
}
const logoHtml = fs.readFileSync(path.join(root, "logo-upload.html"), "utf8");
assert(logoHtml.includes("Start every file name with your organisation name"), "logo upload must give clear organisation-first naming guidance");
assert(logoHtml.includes("data-web-to-lead"), "logo confirmation must submit through Web-to-Lead");
assert(logoHtml.includes('value="Logo Update" data-sf-field="Web_Form_Type__c"'), "logo confirmation must have a stable supplementary form type");
assert(logoHtml.includes('data-sf-field="Target_Booking_Reference__c"'), "logo confirmation must capture the exact booking reference");
assert(logoHtml.includes('pattern="NTE-[A-Za-z0-9][A-Za-z0-9\\-]{1,74}[A-Za-z0-9]"'), "logo confirmation must reject malformed booking references in the browser");
const volunteerHtml = fs.readFileSync(path.join(root, "volunteer-application.html"), "utf8");
const conductSource = JSON.parse(fs.readFileSync(path.join(root, "config/volunteer-code-of-conduct.json"), "utf8"));
const conductReader = volunteerHtml.match(/<div[^>]*data-conduct-reader[^>]*>([\s\S]*?)<\/div>/)[1];
const conductParagraphs = [...conductReader.matchAll(/<(p|h3|h4|li)(?:\s[^>]*)?>(.*?)<\/\1>/g)].map(([, , content]) => content.replace(/&amp;/g, "&").replace(/&lt;/g, "<").replace(/&gt;/g, ">").trim());
assert.deepStrictEqual(conductParagraphs, ["Version " + conductSource.version, ...conductSource.paragraphs.filter(paragraph => !paragraph.omitFromReader).map(paragraph => paragraph.text.trim())], "the reader must preserve every approved Code of Conduct paragraph, in order");
assert(volunteerHtml.includes('Hours willing to give per month</legend>'), "availability must state the client-supplied monthly period");
assert(volunteerHtml.includes(`data-conduct-document="${conductSource.version}"`), "the stored acknowledgement must identify the document shown");
assert(volunteerHtml.includes('data-conduct-reader tabindex="0" role="region"'), "the scroll reader must support keyboard focus and have a region label");
for (const field of ["Date_of_Birth__c", "NOK_Name__c", "NOK_Relationship__c", "NOK_Phone__c", "Volunteer_Armed_Forces_Service__c", "Volunteer_Service_Details__c", "Volunteer_Service_Dates__c", "Volunteer_Opportunities__c", "Volunteer_Skills__c", "Volunteer_Travel_Regions__c", "Volunteer_DBS_Willing__c", "Volunteer_Consent__c", "Volunteer_Form_Version__c", "Declaration_Name__c", "Declaration_Date__c"]) {
  assert(volunteerHtml.includes(`data-sf-field="${field}"`), `volunteer application must capture ${field}`);
}
assert(!volunteerHtml.includes('data-sf-field="Company"'), "volunteer applications must leave Company blank for native Person Account conversion");
assert(volunteerHtml.includes('value="Volunteer Application" data-sf-field="Web_Form_Type__c"'), "volunteer Leads must use a stable isolated form type");
assert(volunteerHtml.includes('value="North East England"'), "volunteer regions must retain the source form wording");
assert(volunteerHtml.includes('value="South West England"'), "volunteer regions must retain the source form wording");
assert.strictEqual((volunteerHtml.match(/value="Mentoring &amp; Coaching" data-sf-field="Volunteer_Opportunities__c"/g) || []).length, 1, "the duplicate mentoring opportunity must be represented once");
assert(volunteerHtml.includes('data-checkbox-copy-from="volunteer-consent" data-sf-field="Consent_PII__c"'), "the source consent answer must populate the existing privacy-consent field");
assert(formsJs.includes('Street: "street"'), "street address must use Salesforce Web-to-Lead's standard field name");
assert(formsJs.includes('PostalCode: "zip"'), "postcode must use Salesforce Web-to-Lead's standard field name");
assert(formsJs.includes('[data-checkbox-copy-from]'), "consent copy fields must be synchronized before submission");
assert(logoHtml.includes('type="submit">Confirm logo upload</button>'), "logo updates retain an explicit submission action");
assert(heavyHtml.includes('pattern="NTE-[A-Za-z0-9][A-Za-z0-9\\-]{1,74}[A-Za-z0-9]"'), "heavy-vehicle updates must validate booking-reference shape");
assert(formsJs.includes("normalizeBookingReferences"), "supplementary booking references must be trimmed and normalized before matching");
assert(formsJs.includes('form.dataset.formKind === "partner-staff-update"'), "partner staff updates retain validation of their declared quantity");
assert(formsJs.includes('form.dataset.formKind === "exhibitor-staff-update"'), "exhibitor staff updates retain purchased-quantity and field-length validation");
assert(formsJs.includes("validateHeavyItems"), "optional heavy-item groups must be complete and ordered");
assert(formsJs.includes("control.max = londonDate"), "declaration dates must reject future dates");

for (const retiredSource of ["partner-sponsor-application-received.html", "exhibitor-application-applicant-confirmation.html"]) {
  assert(!emailSourceFiles.includes(retiredSource), "retired application receipts must only remain in the restoration backup");
}
const exhibitorApplicationNotice = fs.readFileSync(path.join(root, "email-templates", "source", "exhibitor-application-internal-notification.html"), "utf8");
assert(exhibitorApplicationNotice.includes("{!Lead.Payment_Method__c}"), "the exhibitor internal notice must retain the submitted payment choice");
for (const filename of ["partner-sponsor-approved-confirmation.html", "exhibitor-approved-confirmation.html", "government-charity-approved-confirmation.html", "partner-sponsor-payment-confirmed.html", "exhibitor-payment-confirmed.html"]) {
  const email = fs.readFileSync(path.join(root, "email-templates", "source", filename), "utf8");
  assert(compileEmailPresentation(email).includes("{!Contact.FirstName}") && email.includes("{!Opportunity.Booking_Reference__c}"), `${filename}: approval must use the booking and its Primary Contact as merge context`);
  assert(!email.includes("{!Lead."), `${filename}: post-conversion approval must not merge a potentially stale Lead snapshot`);
  const requiredTokens = [filename === "partner-sponsor-approved-confirmation.html" ? "NTE_EVENT_SHORT_LABEL" : "NTE_EVENT_LABEL", "NTE_ORGANISATION", "NTE_FINANCE_SUMMARY", "NTE_PREPARATION_LINKS"];
  const emailPreview = fs.readFileSync(path.join(root, "email-templates", "examples", filename), "utf8");
  assert(emailPreview.includes("NTE27") && !emailPreview.includes("NTE2027"), `${filename}: event branding is static presentation, separate from booking identity`);
  if (!filename.includes("payment-confirmed")) requiredTokens.push("NTE_PAYMENT_NOTE");
  for (const token of requiredTokens) {
    assert(email.includes(`{${token}}`), `${filename}: approval must include the current ${token} content`);
  }
}
for (const filename of ["exhibitor-approved-confirmation.html", "government-charity-approved-confirmation.html", "exhibitor-payment-confirmed.html"]) {
  const email = fs.readFileSync(path.join(emailSourceDirectory, filename), "utf8");
  for (const wording of ["Final event details will be sent approximately two weeks before the event.", "Livery Bay", "website logo montage", "Use your booking reference to provide the final staff names.", "additional staff places as separately charged top-ups if required"]) {
    assert(email.includes(wording), `${filename}: restored client wording must preserve ${wording}`);
  }
  assert(email.indexOf("Use your booking reference to provide the final staff names.") < email.indexOf("{NTE_PREPARATION_LINKS}"), `${filename}: preparation buttons must follow the staff guidance`);
}
for (const filename of ["partner-sponsor-approved-confirmation.html", "partner-sponsor-payment-confirmed.html"]) {
  const email = fs.readFileSync(path.join(emailSourceDirectory, filename), "utf8");
  const preview = fs.readFileSync(path.join(root, 'email-templates', 'examples', filename), 'utf8');
  assert(preview.includes("partnership / sponsorship agreement") && /signing|signed/.test(preview), `${filename}: rendered signing-agreement guidance must remain available`);
  for (const field of ["NTE_Stand_Equipment__c", "NTE_Total_Staff_Count__c", "NTE_Invoice_Address__c", "NTE_Invoiced_Email__c", "NTE_Purchase_Order_Number__c", "NTE_Supplier_Agreement_Required__c"]) {
    assert(email.includes(`{!Opportunity.${field}}`), `${filename}: retain the current booking's ${field} detail`);
  }
  assert(email.indexOf("When your final attendee list is ready") < email.indexOf("{NTE_PREPARATION_LINKS}"), `${filename}: preparation buttons must follow the staff guidance`);
}
for (const filename of ["exhibitor-payment-confirmed.html", "partner-sponsor-payment-confirmed.html"]) {
  const email = fs.readFileSync(path.join(emailSourceDirectory, filename), "utf8");
  assert(email.includes("Thank you for your booking payment."), `${filename}: payment confirmation must identify its trigger`);
  assert(!/provisionally reserved|invoice will be issued|invoice will follow|payment instructions/i.test(email), `${filename}: confirmed email must not request the booking payment again`);
  assert(!email.includes("Booking payment received") && !email.includes("{NTE_PAYMENT_NOTE}"), `${filename}: remove the repeated payment-status box`);
}
for (const filename of fs.readdirSync(emailSourceDirectory).filter(name => name.endsWith('.html'))) {
  const email = fs.readFileSync(path.join(emailSourceDirectory, filename), 'utf8');
  assert(!/>CRM<|\{!(?:Lead|Opportunity|Contact|Account)\.(?:Id|OwnerId)\}/i.test(email), `${filename}: email content must not expose CRM record identifiers`);
}
for (const participant of ['exhibitor', 'partner-sponsor']) {
  for (const confirmed of [false, true]) {
    const name = `${participant}-stripe-${confirmed ? 'payment-confirmed' : 'provisional'}.html`;
    const email = fs.readFileSync(path.join(root, 'email-templates', 'examples', name), 'utf8');
    const prep = email.indexOf('Staff details and event preparation');
    const charges = email.indexOf(confirmed ? 'Your booking charges' : 'Allocation and charges');
    const details = email.indexOf(participant === 'partner-sponsor' ? 'Organisation and contact' : confirmed ? 'Your confirmed booking' : 'Your provisional booking');
    assert(confirmed ? prep < charges && charges < details : charges < prep && prep < details, `${name}: section order must follow the owner annotations`);
    assert(email.includes(confirmed ? 'Total paid' : 'Total payable'), `${name}: distinguish paid and payable amounts`);
    if (confirmed) assert(!/Pay Now|Total payable|data-nte-payment-button/.test(email), `${name}: a payment confirmation must not request payment`);
    else {
      assert(email.includes('Pay Now') && email.includes('assets/stripe-icon.png') && email.includes('aria-disabled="true"'), `${name}: show the branded preview control without a payment destination`);
      assert(!/href="https:\/\/buy\.stripe\.com/.test(email), `${name}: public previews cannot collect a payment`);
    }
  }
}
for (const filename of ["volunteer-application-applicant-confirmation.html", "volunteer-application-internal-notification.html"]) {
  const email = fs.readFileSync(path.join(emailSourceDirectory, filename), "utf8");
  assert(email.includes('assets/mission-motorsport-logo.png') && email.includes('alt="Mission Motorsport"'), `${filename}: volunteer emails must use the official Mission Motorsport logo`);
  assert(!/nte-logo|nationaltransitionevent|The National Transition Event|NTE27/.test(email), `${filename}: volunteer emails must retain their own identity`);
}
for (const filename of ["exhibitor-staff-update-applicant-confirmation.html", "partner-sponsor-staff-update-applicant-confirmation.html", "heavy-vehicle-details-applicant-confirmation.html"]) {
  const email = fs.readFileSync(path.join(root, "email-templates", "source", filename), "utf8");
  assert(email.includes("Hello,"), `${filename}: acknowledgement greeting must suit the booking contact receiving someone else's submission`);
  assert(!/(?:Hi|Hello|Dear)\s+\{!Lead\.FirstName\}/.test(email), `${filename}: receipt must not greet the Primary Contact by the form submitter's name`);
  assert(email.includes("{!Lead.Target_Booking_Reference__c}"), `${filename}: receipt must identify the updated booking`);
}

assert(formsJs.includes('form.dataset.submitting === "true"'), "forms must reject replay while a submission is in progress");
assert(formsJs.includes('button.disabled = true'), "submit controls must lock before Web-to-Lead navigation");
assert(formsJs.includes('honeypot.value'), "forms must reject the bot honeypot");
assert(formsJs.includes('value = value.trim()'), "form values must be trimmed before posting");
assert(formsJs.includes('String(control.value || "").trim() === ""'), "required text fields must reject whitespace-only values");
assert(formsJs.includes('control.closest("[data-conditional-for]") !== target'), "nested conditionals must not be re-enabled by their parent section");
assert.deepStrictEqual(JSON.parse(JSON.stringify(utils.calculatePartnerPricing(["6000", "5000"]))), {packageTotal: 11000, total: 11000});
assert.strictEqual(utils.includedStaffForSpace("Single Garage - Track Side - £799 + VAT"), 2);
assert.strictEqual(utils.includedStaffForSpace("Double Garage - Track Side - £1,299 + VAT"), 4);
assert.strictEqual(utils.includedStaffForSpace("Unknown space"), null);
const commercialPricing = JSON.parse(JSON.stringify(utils.calculateExhibitorPricing({spacePrice: "800", category: "Employer - Automotive Sector", powerRequired: "Yes", socketCount: 2, plannedStaffCount: 7, includedStaffCount: 2})));
assert.strictEqual(commercialPricing.total, 1250);
assert.strictEqual(commercialPricing.powerUnitPrice, 100);
assert.strictEqual(commercialPricing.additionalStaffCount, 5);
assert.strictEqual(commercialPricing.invoiceRequired, true);
const charityPricing = JSON.parse(JSON.stringify(utils.calculateExhibitorPricing({spacePrice: "0", category: "Charity - member of Cobseo", powerRequired: "Yes", socketCount: 3, plannedStaffCount: 2, includedStaffCount: 2})));
assert.strictEqual(charityPricing.total, 150);
assert.strictEqual(charityPricing.powerUnitPrice, 50);
assert.strictEqual(charityPricing.invoiceRequired, true);
const freePricing = JSON.parse(JSON.stringify(utils.calculateExhibitorPricing({spacePrice: "0", category: "Charity - not a member of Cobseo", powerRequired: "No", socketCount: 0, plannedStaffCount: 2, includedStaffCount: 2})));
assert.strictEqual(freePricing.total, 0);
assert.strictEqual(freePricing.invoiceRequired, false);
for (const invalidPrice of [undefined, null, "", " ", "unknown", "poa", -1, NaN, Infinity]) {
  assert.throws(() => utils.calculatePartnerPricing(["3000", invalidPrice]), /price/i, "unknown package prices must block calculation");
  assert.throws(() => utils.calculateExhibitorPricing({spacePrice: invalidPrice, category: "Employer - Manufacturing Sector", powerRequired: "No", socketCount: 0, plannedStaffCount: 2, includedStaffCount: 2}), /price/i, "unknown space prices must never become complimentary");
}
assert(formsJs.includes('invoiceValue = pricing.invoiceRequired ? "Yes" : "No"'), "exhibitor pricing must identify whether payment is required");
assert(exhibitorHtml.includes('id="billing" data-conditional-for="invoice-required" data-conditional-value="Yes" hidden'), "all exhibitor finance questions must belong to the conditional paid-booking section");
const paymentConversionFlow = fs.readFileSync(path.join(root, "force-app", "main", "default", "flows", "NTE_Copy_Converted_Lead_to_Opportunity.flow-meta.xml"), "utf8");
assert(paymentConversionFlow.includes("<field>NTE_Payment_Method__c</field>"), "Lead conversion must populate the Opportunity payment method");
assert(paymentConversionFlow.includes("<elementReference>$Record.Payment_Method__c</elementReference>"), "Lead conversion must source the applicant's payment choice");
assert(paymentConversionFlow.includes("<field>NTE_Invoice_Requested__c</field>") && paymentConversionFlow.includes("<elementReference>$Record.Invoice_Requested__c</elementReference>"), "Lead conversion must preserve the independent invoice request");
const paymentMasterPanelHtml = fs.readFileSync(path.join(root, "force-app", "main", "default", "lwc", "nteMasterPanel", "nteMasterPanel.html"), "utf8");
for (const label of ["Send Stripe link", "Final joining instructions sent", "Booking payment received", "Staff top-up payment received"]) {
  assert(paymentMasterPanelHtml.includes(label), `finance actions must identify their charge: ${label}`);
}
for (const report of ["NTE_02_Partner_Sponsor_Event_Operations", "NTE_03_Exhibitor_Event_Operations", "NTE_06_Finance_and_Invoicing", "NTE_08_Event_Delivery_Readiness"]) {
  const xml = fs.readFileSync(path.join(root, "force-app", "main", "default", "reports", "NTE_Operations", `${report}.report-meta.xml`), "utf8");
  assert(xml.includes("Opportunity.NTE_Payment_Method__c"), `${report} must include the Opportunity payment method`);
  assert(xml.includes("Opportunity.NTE_Invoice_Requested__c"), `${report} must include the independent invoice request`);
}
assert(fs.readFileSync(path.join(root, "force-app", "main", "default", "reports", "NTE_Operations", "NTE_07_Application_and_EOI_Pipeline.report-meta.xml"), "utf8").includes("Lead.Payment_Method__c"), "the application pipeline report must include the Lead payment method");
assert(exhibitorHtml.includes('data-sf-field="Logo_Upload_URL__c"'), "exhibitor application must store the configured logo-upload URL for confirmation emails");
assert(partnerHtml.includes('data-sf-field="Logo_Upload_URL__c"'), "partner application must store the configured logo-upload URL for confirmation emails");

const stylesCss = fs.readFileSync(path.join(root, "assets", "styles.css"), "utf8");
assert(!/body\s*\{[^}]*min-width\s*:\s*320px/.test(stylesCss), "the public forms must reflow without a forced 320px body width");

const exhibitorInterestHtml = fs.readFileSync(path.join(root, "exhibitor-interest.html"), "utf8");
const partnerInterestHtml = fs.readFileSync(path.join(root, "partner-sponsor-interest.html"), "utf8");
const expectedOrganisationTypes = [
  "Charity - COBSEO member",
  "Charity - Non COBSEO member",
  "Government Department or Agency",
  "Industry Body / Trade Association",
  "Employer - Automotive",
  "Employer - Clean Energy",
  "Employer - Blue Light Services / NHS",
  "Employer - Built Environment",
  "Employer - Manufacturing",
  "Employer - Defence and Security",
  "Employer - Financial and Professional Services",
  "Employer - Digital and Technologies",
  "Employer - Training and Education",
  "Employer - Land-based",
  "Employer - Other sector"
];
function selectOptionLabels(html, id) {
  const selectMatch = html.match(new RegExp(`<select id="${id}"[^>]*>([\\s\\S]*?)<\\/select>`));
  assert(selectMatch, `missing select #${id}`);
  return [...selectMatch[1].matchAll(/<option(?:\s[^>]*)?>([^<]*)<\/option>/g)]
    .map((match) => match[1].trim())
    .filter((label) => label !== "Select");
}
assert(exhibitorInterestHtml.includes('value="Exhibitor Expression of Interest"'), "exhibitor EOI must have its own stable form type");
assert(exhibitorInterestHtml.includes('value="exhibitor-interest-v3"'), "exhibitor EOI schema changes must use form version 3");
assert(!/£|data-price|package-price/i.test(exhibitorInterestHtml), "exhibitor EOI must not expose pricing");
for (const field of ["Exhibitor_Interest_Detail__c", "Exhibitor_Community_Contribution__c", "Preferred_Contact_Method__c", "Contact_Consent__c"]) {
  assert(exhibitorInterestHtml.includes(`data-sf-field="${field}"`), `exhibitor EOI must capture ${field}`);
}
assert.deepStrictEqual(selectOptionLabels(exhibitorInterestHtml, "exhibitor-interest-type"), expectedOrganisationTypes, "exhibitor EOI must show the supplied organisation types in order");
assert.deepStrictEqual(selectOptionLabels(partnerInterestHtml, "eoi-organisation-type"), expectedOrganisationTypes, "partner/sponsor EOI must show the supplied organisation types in order");
assert(!exhibitorInterestHtml.includes("What you would bring to NTE27"), "the removed exhibitor contribution section heading must not remain");
assert(!exhibitorInterestHtml.includes('data-sf-field="Exhibitor_Interest_Areas__c"'), "exhibitor EOI must not ask for the removed areas of interest");
assert(!exhibitorInterestHtml.includes('data-sf-field="Previous_NTE_Events__c"'), "exhibitor EOI must not retain event-history controls from the removed section");
assert(exhibitorInterestHtml.includes("Are you interested in Sponsorship Opportunities?"), "exhibitor EOI must use the supplied sponsorship question");
assert(exhibitorInterestHtml.includes("We work with a number of organisations that host value-adding activities such as workshops and skills advice at NTE. Is this something you could offer the event?"), "exhibitor EOI must use the supplied activities question");
for (const answer of ["Yes", "No", "Maybe"]) {
  assert(exhibitorInterestHtml.includes(`name="exhibitor-sponsorship-interest" value="${answer}"`), `exhibitor EOI must offer sponsorship answer ${answer}`);
}
assert(/name="exhibitor-sponsorship-interest" value="Yes" required data-sf-field="Exhibitor_Interest_Detail__c"/.test(exhibitorInterestHtml), "sponsorship interest must be required and stored in the deployed exhibitor detail field");
const activitiesTextarea = exhibitorInterestHtml.match(/<textarea id="exhibitor-value-adding-activities"[^>]*>/);
assert(activitiesTextarea, "exhibitor EOI must include the value-adding activities answer");
assert(!/\brequired\b/.test(activitiesTextarea[0]), "value-adding activities must remain optional as supplied");

const organisationTypeMetadata = fs.readFileSync(path.join(root, "force-app", "main", "default", "objects", "Lead", "fields", "Organisation_Type__c.field-meta.xml"), "utf8");
for (const value of expectedOrganisationTypes) assert(organisationTypeMetadata.includes(`<fullName>${value}</fullName>`), `Salesforce organisation type metadata must accept ${value}`);
for (const legacyValue of ["Commercial business", "Charity or non-profit", "Government or public body", "Industry body or trade association", "Education or training provider", "Other"]) {
  assert(organisationTypeMetadata.includes(`<fullName>${legacyValue}</fullName>`), `Salesforce organisation type metadata must preserve legacy value ${legacyValue}`);
}

const metadataRoot = path.join(root, "force-app", "main", "default");
const appMetadata = fs.readFileSync(path.join(metadataRoot, "applications", "NTE_Management.app-meta.xml"), "utf8");
assert(appMetadata.includes("<label>NTE Management</label>"), "the NTE Management app must be generated");
assert(appMetadata.includes("<logo>NTE_Management_Logo</logo>"), "the NTE app must use the supplied logo asset");
assert(appMetadata.includes("<defaultLandingTab>standard-home</defaultLandingTab>"), "the NTE app must open on Home");
assert(appMetadata.indexOf("<tabs>standard-home</tabs>") < appMetadata.indexOf("<tabs>NTE_Master_Panel</tabs>"), "Home must appear before Master Panel in the app navigation");
for (const tab of ["standard-Lead", "standard-Account", "standard-Contact", "standard-Opportunity"]) {
  assert(appMetadata.includes(`<tabs>${tab}</tabs>`), `the NTE app must include ${tab}`);
}
assert(!appMetadata.includes("NTE_Forms_Hub"), "the NTE app must not expose a hosted-forms tab");
assert(!fs.existsSync(path.join(metadataRoot, "tabs", "NTE_Forms_Hub.tab-meta.xml")), "the hosted-forms tab metadata must not ship");
assert(!fs.existsSync(path.join(metadataRoot, "lwc", "nteFormsHub")), "the hosted-forms component must not ship");
for (const page of ["Lead", "Account", "Contact", "Opportunity"]) {
  const pageMetadata = fs.readFileSync(path.join(metadataRoot, "flexipages", `NTE_Management_${page}_Record_Page.flexipage-meta.xml`), "utf8");
  assert(pageMetadata.includes("<componentName>force:highlightsPanel</componentName>"), `${page} page must use the standard Salesforce highlights panel`);
  assert(pageMetadata.includes("<name>enableActionsConfiguration</name>\n                    <value>true</value>"), `${page} page must define portable record actions instead of depending on a target-org layout`);
  assert(pageMetadata.includes("<name>actionNames</name>"), `${page} page must define a non-empty action list`);
  assert(pageMetadata.includes("<value>Edit</value>"), `${page} page must expose Edit when the user has permission`);
  if (page === "Lead") assert(pageMetadata.includes("<value>Convert</value>"), "the NTE Lead page must expose Salesforce Lead conversion");
  assert(!pageMetadata.includes("<componentName>record_flexipage:dynamicHighlights</componentName>"), `${page} page must not use an unconfigured Dynamic Highlights panel`);
  assert(pageMetadata.includes("<componentName>force:relatedListContainer</componentName>"), `${page} page must include working related lists`);
  assert(pageMetadata.includes("<componentName>runtime_sales_activities:activityPanel</componentName>"), `${page} page must include activities`);
  assert(pageMetadata.includes("<componentName>force:relatedListQuickLinksContainer</componentName>"), `${page} page must include related-list quick links`);
}
const accountList = fs.readFileSync(path.join(metadataRoot, "objects", "Account", "listViews", "NTE_Organisations.listView-meta.xml"), "utf8");
const contactList = fs.readFileSync(path.join(metadataRoot, "objects", "Contact", "listViews", "NTE_Contacts.listView-meta.xml"), "utf8");
assert(accountList.includes("<field>NTE_Participant__c</field>"), "NTE organisations must use an explicit classification field");
assert(contactList.includes("<field>NTE_Participant__c</field>"), "NTE contacts must use an explicit classification field");
const managementPermission = fs.readFileSync(path.join(metadataRoot, "permissionsets", "NTE_Management_User.permissionset-meta.xml"), "utf8");
assert(managementPermission.includes("<application>NTE_Management</application>"), "the user permission set must expose the app");
for (const objectName of ["Lead", "Account", "Contact", "Opportunity", "Task", "Event"]) {
  assert(managementPermission.includes(`<object>${objectName}</object>`), `the user permission set must grant scoped ${objectName} access`);
}
assert(managementPermission.includes("<name>ConvertLeads</name>"), "the user permission set must permit Lead conversion");
assert(managementPermission.includes("<name>EditTask</name>"), "the user permission set must include Salesforce's task-edit prerequisite for Lead conversion");
assert(managementPermission.includes("<name>RunReports</name>"), "the user permission set must permit report access");
const homePage = fs.readFileSync(path.join(metadataRoot, "flexipages", "NTE_Management_Home.flexipage-meta.xml"), "utf8");
assert(homePage.includes("<name>c:NTE_OneRegionHomeTemplate</name>"), "the NTE home page must use the package-owned full-width template");
assert(homePage.includes("<name>main</name>"), "the NTE dashboard must occupy the full-width home region");
assert(!homePage.includes("industries_common:"), "the NTE home page must not require an Industries managed package");
const homeTemplateDir = path.join(metadataRoot, "aura", "NTE_OneRegionHomeTemplate");
const homeTemplateComponent = fs.readFileSync(path.join(homeTemplateDir, "NTE_OneRegionHomeTemplate.cmp"), "utf8");
const homeTemplateDesign = fs.readFileSync(path.join(homeTemplateDir, "NTE_OneRegionHomeTemplate.design"), "utf8");
assert(homeTemplateComponent.includes('implements="lightning:homeTemplate"'), "the package-owned template must implement Salesforce's Home template contract");
assert(homeTemplateComponent.includes('name="main" type="Aura.Component[]"'), "the Home template must render one full-width component region");
assert(homeTemplateDesign.includes('name="main"') && homeTemplateDesign.includes('defaultWidth="LARGE"'), "the Home template must expose its region as large");
const productionManifest = fs.readFileSync(path.join(root, "manifest", "production-package.xml"), "utf8");
for (const block of productionManifest.matchAll(/<types>([\s\S]*?)<\/types>/g)) {
  if (block[1].includes("<name>EmailTemplate</name>")) {
    for (const member of block[1].matchAll(/<members>([^<]+)<\/members>/g)) {
      for (const extension of [".email", ".email-meta.xml"]) {
        assert(fs.existsSync(path.join(metadataRoot, "email", `${member[1]}${extension}`)), `manifest email has no deployable source: ${member[1]}${extension}`);
      }
    }
  }
  if (!block[1].includes("<name>CustomField</name>")) continue;
  for (const member of block[1].matchAll(/<members>([^<]+)<\/members>/g)) {
    const [object, field] = member[1].split(".");
    assert(fs.existsSync(path.join(metadataRoot, "objects", object, "fields", `${field}.field-meta.xml`)), `manifest field has no deployable source: ${member[1]}`);
  }
}
assert(productionManifest.includes("<members>NTE_OneRegionHomeTemplate</members>"), "the production package must include the full-width Home template");
const conversionFlow = fs.readFileSync(path.join(metadataRoot, "flows", "NTE_Copy_Converted_Lead_to_Opportunity.flow-meta.xml"), "utf8");
assert(conversionFlow.includes("<name>Classify_Converted_Account</name>"), "conversion must classify NTE accounts");
assert(conversionFlow.includes("<name>Classify_Converted_Contact</name>"), "conversion must classify NTE contacts");
assert(!conversionFlow.includes("<actionName>NTEExhibitorApprovalEmailService</actionName>"), "conversion must remain silent until an explicit finance action");
assert(conversionFlow.includes("<doesRequireRecordChangedToMeetCriteria>true</doesRequireRecordChangedToMeetCriteria>"), "conversion automation must run when the Lead enters the converted criteria");
const approvalEmailService = fs.readFileSync(path.join(metadataRoot, "classes", "NTEExhibitorApprovalEmailService.cls"), "utf8");
assert(approvalEmailService.includes("implements Queueable"), "approval mail must be prepared after the conversion transaction commits");
assert(approvalEmailService.includes("NTE_Approval_Email_Batch__c = :batchKey"), "approval jobs must stay within their explicitly queued booking batch");
assert(!approvalEmailService.includes("LastModifiedDate"), "approval jobs must not discover unrelated converted Leads from a recent-activity sweep");
assert(approvalEmailService.includes("NTEBookingContactService.primaryContacts"), "approval mail must resolve the Opportunity Primary Contact");
assert(approvalEmailService.includes("Messaging.renderStoredEmailTemplate(templateId, recipient.Id, booking.Id)"), "approval templates must render from the current booking and its Primary Contact");
assert(approvalEmailService.includes("setHtmlBody(") && approvalEmailService.includes("setPlainTextBody("), "approval mail must provide HTML and a plain text alternative");
assert(fs.existsSync(path.join(metadataRoot, "contentassets", "NTE_Management_Logo.asset")), "the app logo content asset must exist");

const reportFolderMetadata = fs.readFileSync(path.join(metadataRoot, "reports", "NTE_Operations.reportFolder-meta.xml"), "utf8");
assert(reportFolderMetadata.includes("<sharedTo>AllInternalUsers</sharedTo>"), "the NTE report folder must be shared to all internal users");
const expectedReports = [
  "NTE_01_Guest_Check_In_and_Accessibility",
  "NTE_02_Partner_Sponsor_Event_Operations",
  "NTE_03_Exhibitor_Event_Operations",
  "NTE_04_Staff_and_Accreditation_Roster",
  "NTE_05_Heavy_Vehicles_and_Logistics",
  "NTE_06_Finance_and_Invoicing",
  "NTE_07_Application_and_EOI_Pipeline",
  "NTE_08_Event_Delivery_Readiness",
  "NTE_09_Weekly_Finance_Report"
];
for (const report of expectedReports) {
  const reportMetadata = fs.readFileSync(path.join(metadataRoot, "reports", "NTE_Operations", `${report}.report-meta.xml`), "utf8");
  assert(reportMetadata.includes("<scope>organization</scope>") || reportMetadata.includes("<scope>org</scope>"), `${report} must report across the organisation`);
  if (report !== "NTE_09_Weekly_Finance_Report") {
    assert(reportMetadata.includes("<interval>INTERVAL_CUSTOM</interval>"), `${report} must use an evergreen date range`);
    assert(reportMetadata.includes("<startDate>2000-01-01</startDate>"), `${report} must include all NTE editions by default`);
  }
  assert(reportMetadata.includes("NTE_Event_Code__c"), `${report} must expose or group by the evergreen NTE event code`);
}
const guestReport = fs.readFileSync(path.join(metadataRoot, "reports", "NTE_Operations", "NTE_01_Guest_Check_In_and_Accessibility.report-meta.xml"), "utf8");
for (const field of ["Lead.Accompanying_Guest_Name__c", "Lead.Guest_Accessibility_Details__c", "Lead.Guest_Information_Declaration__c"]) assert(guestReport.includes(field), `guest report must contain ${field}`);
const vehicleReport = fs.readFileSync(path.join(metadataRoot, "reports", "NTE_Operations", "NTE_05_Heavy_Vehicles_and_Logistics.report-meta.xml"), "utf8");
for (const field of ["Opportunity.NTE_Heavy_Item_1_Description__c", "Opportunity.NTE_Heavy_Item_2_Description__c", "Opportunity.NTE_Heavy_Item_3_Description__c", "Opportunity.NTE_Haulier_Vehicle_Registration__c"]) assert(vehicleReport.includes(field), `vehicle report must contain ${field}`);
const financeReport = fs.readFileSync(path.join(metadataRoot, "reports", "NTE_Operations", "NTE_06_Finance_and_Invoicing.report-meta.xml"), "utf8");
for (const field of ["Opportunity.NTE_Sponsor_Package__c", "Opportunity.NTE_Sponsor_Package_Total__c", "Opportunity.NTE_Exhibitor_Space_Selections__c", "Opportunity.NTE_Exhibitor_Space_Price__c", "Opportunity.NTE_Power_Socket_Count__c", "Opportunity.NTE_Power_Socket_Unit_Price__c", "Opportunity.NTE_Power_Socket_Total__c", "Opportunity.NTE_Additional_Staff_Count__c", "Opportunity.NTE_Additional_Staff_Unit_Price__c", "Opportunity.NTE_Additional_Staff_Total__c", "Opportunity.NTE_Listed_Price_Total__c", "Opportunity.NTE_Pricing_Status__c", "Opportunity.NTE_Invoice_Address__c", "Opportunity.NTE_Purchase_Order_Number__c", "Opportunity.NTE_Confirmed_Value__c"]) assert(financeReport.includes(field), `finance report must contain ${field}`);
assert(financeReport.includes("<aggregateTypes>Sum</aggregateTypes>"), "finance report must sum the confirmed Opportunity value");
const weeklyFinanceReport = fs.readFileSync(path.join(metadataRoot, "reports", "NTE_Operations", "NTE_09_Weekly_Finance_Report.report-meta.xml"), "utf8");
assert(weeklyFinanceReport.includes("<name>Weekly Finance Report</name>"), "the weekly Finance report must use its requested display name");
assert(weeklyFinanceReport.includes("<dateColumn>LAST_UPDATE</dateColumn>"), "the weekly Finance window must use Opportunity Last Modified Date");
assert(weeklyFinanceReport.includes("<interval>INTERVAL_LAST7</interval>"), "the weekly Finance report must cover Salesforce's rolling last-seven-days interval");
assert(!weeklyFinanceReport.includes("<startDate>"), "the rolling weekly Finance interval must not be pinned to a fixed start date");
assert(weeklyFinanceReport.includes("<sortColumn>LAST_UPDATE</sortColumn>") && weeklyFinanceReport.includes("<sortOrder>Desc</sortOrder>"), "the weekly Finance report must show the most recently changed bookings first");
assert(weeklyFinanceReport.includes("<booleanFilter>(1 OR 2) AND 3 AND 4 AND (5 OR 6)</booleanFilter>"), "weekly finance must scope active and won application bookings to a populated event");
assert(/<column>CLOSED<\/column>[\s\S]*?<value>false<\/value>/.test(weeklyFinanceReport) && /<column>WON<\/column>[\s\S]*?<value>true<\/value>/.test(weeklyFinanceReport), "weekly finance must exclude closed losses by semantic flags while retaining won bookings");
assert(/<column>RECORDTYPE<\/column>[\s\S]*?<isUnlocked>false<\/isUnlocked>[\s\S]*?<value>Opportunity\.NTE_Event_Opportunity<\/value>/.test(weeklyFinanceReport), "the weekly Finance report must lock its scope to NTE Opportunities");
assert(weeklyFinanceReport.includes("Use NTE 06 - Finance &amp; Invoicing for the complete all-time finance view."), "the weekly Finance report description must direct users to the complementary all-time report");
for (const field of ["Opportunity.NTE_Confirmed_Value__c", "Opportunity.NTE_Quote_Provided__c", "Opportunity.NTE_Quote_Provided_At__c", "Opportunity.NTE_Invoice_Provided__c", "Opportunity.NTE_Invoice_Provided_At__c", "Opportunity.NTE_Payment_Received__c", "Opportunity.NTE_Payment_Received_At__c", "Opportunity.NTE_Top_Up_Staff_Total__c", "Opportunity.NTE_Invoiced_Company__c", "Opportunity.NTE_Invoiced_Email__c", "Opportunity.NTE_Purchase_Order_Number__c"]) assert(weeklyFinanceReport.includes(field), `weekly Finance report must contain ${field}`);
assert(weeklyFinanceReport.includes("<aggregateTypes>Sum</aggregateTypes>"), "the weekly Finance report must total its monetary columns");
const confirmedValueField = fs.readFileSync(path.join(metadataRoot, "objects", "Opportunity", "fields", "NTE_Confirmed_Value__c.field-meta.xml"), "utf8");
assert(confirmedValueField.includes("NOT(NTE_Pricing_Ready__c)"), "confirmed value must exclude bookings needing a pricing check using shared readiness");

const logoProvidedField = fs.readFileSync(path.join(metadataRoot, "objects", "Opportunity", "fields", "NTE_Logo_Update_Provided__c.field-meta.xml"), "utf8");
const logoProvidedAtField = fs.readFileSync(path.join(metadataRoot, "objects", "Opportunity", "fields", "NTE_Logo_Update_Provided_At__c.field-meta.xml"), "utf8");
assert(logoProvidedField.includes("<defaultValue>false</defaultValue>"), "new NTE bookings must begin with a logo update outstanding");
assert(logoProvidedAtField.includes("<type>DateTime</type>"), "the first matched logo update must be timestamped");
const logoDueList = fs.readFileSync(path.join(metadataRoot, "objects", "Opportunity", "listViews", "NTE_Logo_Updates_Due.listView-meta.xml"), "utf8");
assert(logoDueList.includes("NTE_Logo_Update_Provided__c"), "the logo-update list view must filter on the booking status field");
assert(logoDueList.includes("<value>0</value>"), "the logo-update list view must show only outstanding bookings");
const supplementaryFlow = fs.readFileSync(path.join(metadataRoot, "flows", "NTE_Supplementary_Update_Handler.flow-meta.xml"), "utf8");
assert(supplementaryFlow.includes("<stringValue>Logo Update</stringValue>"), "logo confirmations must enter the supplementary update service");
const updateService = fs.readFileSync(path.join(metadataRoot, "classes", "NTEUpdateSubmissionService.cls"), "utf8");
const logoApplication = updateService.match(/else if \(lead\.Web_Form_Type__c == 'Logo Update'\) \{([\s\S]*?)\n            \}/);
assert(logoApplication && !logoApplication[1].includes("temporaryLeadsToDelete.add"), "successful logo submissions must be retained for audit");
assert(updateService.includes("if (!emailErrors.containsKey(lead.Id)) acceptedTemporaryLeads.add(lead)"), "failed update acknowledgements must retain their applied submission for retry");
assert(updateService.includes("Database.delete(acceptedTemporaryLeads, false, AccessLevel.SYSTEM_MODE)"), "only temporary submissions with accepted acknowledgements may be removed");
assert(!/\btarget\.NTE_(?:Event_Contact|Secondary_Contact)_[A-Za-z0-9_]+\s*=/.test(updateService), "supplementary updates must preserve the booking's existing day and secondary contacts");
for (const [target, source] of [["NTE_Delivery_Window__c", "Delivery_Window__c"], ["NTE_Heavy_Item_2_Description__c", "Heavy_Item_2_Description__c"], ["NTE_Heavy_Item_3_Description__c", "Heavy_Item_3_Description__c"], ["NTE_Haulier_Vehicle_Registration__c", "Haulier_Vehicle_Registration__c"]]) {
  assert(updateService.includes(`target.${target} = source.${source};`), `${target}: logistics replacement must apply supplied values including blanks`);
}
assert(updateService.includes("existingTopUpCount > 0 && topUpCount > existingTopUpCount"), "Salesforce must reject a second increase after the first accepted top-up purchase");
assert(updateService.includes("previousTopUpCount == 0 && requestedTopUpCount > 0"), "only the first positive purchase may initialize top-up finance milestones");
assert(updateService.includes("FOR UPDATE") && updateService.includes("existing.put(fieldName, updateRecord.get(fieldName))"), "top-up validation must use locked booking data and the accepted state of earlier submissions in the batch");
assert(updateService.includes("NTEBookingContactService.primaryContacts"), "update acknowledgements must use the booking's Primary Contact");
assert(updateService.includes("setTargetObjectId(mergeLeadId)") && updateService.includes("setTreatTargetObjectAsRecipient(false)")
  && updateService.includes("setToAddresses(new List<String>{primaryEmail})"), "supplementary Leads may supply merge values but must not become the email recipient");
assert(updateService.includes("retryAcknowledgement(Id leadId)") && updateService.includes("Only a failed acknowledgement for an already applied update can be retried."), "applied updates must provide an acknowledgement-only retry");
const bookingContactService = fs.readFileSync(path.join(metadataRoot, "classes", "NTEBookingContactService.cls"), "utf8");
assert(bookingContactService.includes("FROM OpportunityContactRole") && bookingContactService.includes("IsPrimary = true"), "booking recipients must come from the Primary Contact Role");
assert(!bookingContactService.includes("NTE_Event_Contact_") && !bookingContactService.includes("NTE_Invoiced_Email__c"), "booking recipients must not fall back to day or billing email fields");
const masterPanelController = fs.readFileSync(path.join(metadataRoot, "classes", "NTE_MasterPanelController.cls"), "utf8");
const masterPanelJs = fs.readFileSync(path.join(metadataRoot, "lwc", "nteMasterPanel", "nteMasterPanel.js"), "utf8");
const masterPanelHtml = fs.readFileSync(path.join(metadataRoot, "lwc", "nteMasterPanel", "nteMasterPanel.html"), "utf8");
for (const source of [masterPanelController, masterPanelJs]) {
  assert(source.includes("LOGO_DUE"), "the Master Panel must expose an outstanding-logo refiner and count");
}
assert(masterPanelHtml.includes("isLogoView"), "the Master Panel must render purpose-built logo-update columns");
assert(masterPanelHtml.includes("logoStatus"), "the booking detail must show whether the logo has been provided");
const completedBookingClause = masterPanelController.match(/private static String completeClause\(\) \{([\s\S]*?)\n    \}/);
assert(completedBookingClause && completedBookingClause[1].includes("NTE_Logo_Update_Provided__c = true"), "Completed must require the booking's logo confirmation as well as staff, logistics and finance");
for (const view of ["FINAL_PACK_DUE", "FINAL_PACK_SENT"]) {
  assert(masterPanelController.includes(view) && masterPanelJs.includes(view), `Completed must expose the ${view} refiner`);
}

for (const fieldName of ["NTE_Interest_Progressed__c", "NTE_Interest_Not_Progressed__c", "NTE_Application_Rejected__c"]) {
  const fieldMetadata = fs.readFileSync(path.join(metadataRoot, "objects", "Lead", "fields", `${fieldName}.field-meta.xml`), "utf8");
  assert(fieldMetadata.includes("<type>Checkbox</type>"), `${fieldName} must be a reversible Lead checkbox`);
  assert(fieldMetadata.includes("<defaultValue>false</defaultValue>"), `${fieldName} must default to false`);
  for (const permissionSetName of ["NTE_Forms_Administration", "NTE_Management_User"]) {
    const permissionSet = fs.readFileSync(path.join(metadataRoot, "permissionsets", `${permissionSetName}.permissionset-meta.xml`), "utf8");
    assert(permissionSet.includes(`<field>Lead.${fieldName}</field>`), `${permissionSetName} must grant access to ${fieldName}`);
  }
}
const interestDecisionRule = fs.readFileSync(path.join(metadataRoot, "objects", "Lead", "validationRules", "NTE_Interest_Decision_Exclusive.validationRule-meta.xml"), "utf8");
assert(interestDecisionRule.includes("AND(NTE_Interest_Progressed__c, NTE_Interest_Not_Progressed__c)"), "interest decisions must remain mutually exclusive");
const interestListView = fs.readFileSync(path.join(metadataRoot, "objects", "Lead", "listViews", "NTE_Expressions_of_Interest.listView-meta.xml"), "utf8");
for (const fieldName of ["NTE_Interest_Progressed__c", "NTE_Interest_Not_Progressed__c"]) {
  assert(interestListView.includes(`<columns>${fieldName}</columns>`), `the expression-of-interest list must expose ${fieldName}`);
}
const applicationListView = fs.readFileSync(path.join(metadataRoot, "objects", "Lead", "listViews", "NTE_Applications.listView-meta.xml"), "utf8");
assert(applicationListView.includes("<columns>NTE_Application_Rejected__c</columns>"), "the applications list must expose the reversible rejection decision");
const leadRecordPage = fs.readFileSync(path.join(metadataRoot, "flexipages", "NTE_Management_Lead_Record_Page.flexipage-meta.xml"), "utf8");
for (const fieldName of ["NTE_Interest_Progressed__c", "NTE_Interest_Not_Progressed__c", "NTE_Application_Rejected__c"]) {
  assert(leadRecordPage.includes(`Record.${fieldName}`), `the NTE Lead record page must expose ${fieldName}`);
}

assert(masterPanelController.includes("updateLeadDecision"), "the Master Panel must provide reversible Lead decisions");
assert(masterPanelController.includes("activeInterestClause()"), "decided interest Leads must leave active Master Panel queues");
assert(masterPanelController.includes("activeApplicationClause()"), "rejected applications must leave active Master Panel queues");
const dispatchService = fs.readFileSync(path.join(metadataRoot, "classes", "NTEEmailDispatchService.cls"), "utf8");
for (const method of ["buildDraft", "previewMessageJson", "queueMessagesJson", "recentDispatches", "retryFailed"]) {
  assert(dispatchService.includes(` ${method}(`), `the shared sender must expose ${method}`);
  if (["buildDraft", "previewMessageJson", "queueMessagesJson"].includes(method)) {
    assert(masterPanelJs.includes(`@salesforce/apex/NTEEmailDispatchService.${method}`), `the Master Panel must wire ${method} to the shared sender`);
  }
}
assert(dispatchService.includes("JSON.deserializeStrict(requestJson, DraftRequest.class)")
  && dispatchService.includes("requestJson.length() > MAX_REQUEST_JSON_LENGTH"), "email request JSON must be strictly parsed within a bounded size");
for (const method of ["previewMessage", "queueMessages"]) {
  assert(!new RegExp(`@AuraEnabled(?:\\([^)]*\\))?\\s+public static [\\w<>]+ ${method}\\(DraftRequest`).test(dispatchService), "inner-class email request parameters must not be exposed to Lightning");
}
assert(masterPanelJs.includes("previewMessageJson({ requestJson: JSON.stringify(this.communicationRequest())")
  && masterPanelJs.includes("queueMessagesJson({ requestJson: JSON.stringify(request) })")
  && masterPanelJs.includes("JSON.parse(await queueMessagesJson("), "preview and send must exchange primitive JSON strings with Apex");
assert(!/@AuraEnabled\(cacheable=true\)\s+public static DraftDTO buildDraft/.test(dispatchService), "recipient previews must always use current booking data");
const dispatchPageSize = dispatchService.match(/Integer PAGE_SIZE = (\d+)/);
assert(dispatchPageSize && Number(dispatchPageSize[1]) <= 100, "each asynchronous email page must stay within the 100-email transaction limit");
assert(dispatchService.includes("implements Queueable") && dispatchService.includes("Database.insert(dispatches, true, AccessLevel.USER_MODE)"), "queued bulk sends must persist recipient-level audit rows with user-mode access");
assert(dispatchService.includes("NTEBookingContactService.primaryContacts") && masterPanelController.includes("NTEBookingContactService.primaryContacts"), "the sender and panel must use the same Primary Contact source");
assert(dispatchService.includes("setHtmlBody(") && dispatchService.includes("setPlainTextBody(") && dispatchService.includes("escapeHtml4()"), "bulk mail must include escaped HTML and a plain text alternative");
assert(dispatchService.includes("validLink(recipient.link)"), "bulk mail must exclude recipients whose configured action link is blank or invalid");
assert(dispatchService.includes("recipient.fingerprint != fingerprints.get(recipient.recordId)"), "sending must reject a recipient changed since the reviewed preview");
assert(dispatchService.includes("dispatch.Status__c != 'Failed'") && dispatchService.includes("existingKeys.contains(key)"), "retry and duplicate guards must preserve previously accepted sends");
const dispatchKeyMetadata = fs.readFileSync(path.join(metadataRoot, "objects", "NTE_Email_Dispatch__c", "fields", "Dispatch_Key__c.field-meta.xml"), "utf8");
assert(dispatchKeyMetadata.includes("<unique>true</unique>"), "the durable recipient/run key must be unique even when two sends race");
const failedUpdateEmails = fs.readFileSync(path.join(metadataRoot, "objects", "Lead", "listViews", "NTE_Update_Emails_Failed.listView-meta.xml"), "utf8");
assert(failedUpdateEmails.includes("Matched and Applied") && failedUpdateEmails.includes("NTE_Applicant_Email_Status__c")
  && failedUpdateEmails.includes("Failed"), "the failed-email list must expose saved updates whose acknowledgement needs retry");
for (const permissionSetName of ["NTE_Management_User", "NTE_Forms_Administration"]) {
  const permissionSet = fs.readFileSync(path.join(metadataRoot, "permissionsets", `${permissionSetName}.permissionset-meta.xml`), "utf8");
  for (const api of ["NTEEmailDispatchService", "NTEUpdateSubmissionService"]) {
    assert(permissionSet.includes(`<apexClass>${api}</apexClass>`), `${permissionSetName}: new email actions must have deployed class access to ${api}`);
    assert(productionManifest.includes(`<members>${api}</members>`), `${api}: the production manifest must include the email action dependency`);
  }
}
for (const routingField of ["Heavy_Vehicle_Form_URL__c", "Exhibitor_Staff_Form_URL__c", "Partner_Staff_Form_URL__c", "Logo_Update_Form_URL__c", "Exhibitor_Application_URL__c", "Partner_Application_URL__c"]) {
  assert(dispatchService.includes(routingField), `bulk mail must use configured ${routingField}`);
  const routingFieldMetadata = fs.readFileSync(path.join(metadataRoot, "objects", "NTE_Routing_Config__mdt", "fields", `${routingField}.field-meta.xml`), "utf8");
  assert(routingFieldMetadata.includes("<type>Text</type>"), `${routingField} must be deployable configuration metadata`);
}
for (const expectedCopy of ["Decision", "Send Application", "Reject", "Remind All", "View Weekly Finance Report"]) {
  assert(masterPanelHtml.includes(expectedCopy), `the Master Panel must render ${expectedCopy}`);
}
assert(!masterPanelHtml.includes('data-decision="INTEREST_PROGRESSED"'), "progressing an interest must open an invitation draft instead of immediately hiding the Lead");
assert(masterPanelJs.includes("INTEREST_NOT_PROGRESSED"), "the client must retain the reject decision for interests");
assert(masterPanelJs.includes("APPLICATION_REJECTED"), "the client must wire application rejection");
assert(masterPanelJs.includes("LightningConfirm.open"), "destructive-looking queue decisions and bulk sends must require confirmation");

assert(masterPanelController.includes("RecordType.DeveloperName = \\'NTE_Event_Opportunity\\'"), "Master Panel Opportunity queries must be isolated by NTE record type");
const relatedOpportunityController = fs.readFileSync(path.join(metadataRoot, "classes", "NTERelatedOpportunityController.cls"), "utf8");
assert(relatedOpportunityController.includes("RecordType.DeveloperName = 'NTE_Event_Opportunity'"), "NTE related lists must exclude regular CRM opportunities");
assert(relatedOpportunityController.includes("WITH USER_MODE"), "NTE related lists must enforce user-mode access");
assert(relatedOpportunityController.includes("Security.stripInaccessible(AccessType.READABLE"), "NTE related lists must sanitize fields before returning them to the UI");

for (const listView of ["NTE_Event_Participation", "NTE_Requirements", "NTE_Payment_Confirmed", "NTE_Payments_Due", "NTE_Heavy_Vehicle_Updates_Due", "NTE_Staff_Updates_Due", "NTE_Logo_Updates_Due"]) {
  const listMetadata = fs.readFileSync(path.join(metadataRoot, "objects", "Opportunity", "listViews", `${listView}.listView-meta.xml`), "utf8");
  assert(listMetadata.includes("<field>OPPORTUNITY.RECORDTYPE</field>"), `${listView} must filter by Opportunity record type`);
  assert(listMetadata.includes("<value>Opportunity.NTE_Event_Opportunity</value>"), `${listView} must select only the NTE Event Opportunity record type`);
}
for (const report of expectedReports.filter((name) => !name.startsWith("NTE_01") && !name.startsWith("NTE_07"))) {
  const reportMetadata = fs.readFileSync(path.join(metadataRoot, "reports", "NTE_Operations", `${report}.report-meta.xml`), "utf8");
  assert(reportMetadata.includes("<column>RECORDTYPE</column>"), `${report} must filter by Opportunity record type`);
  assert(reportMetadata.includes("<value>Opportunity.NTE_Event_Opportunity</value>"), `${report} must select only the NTE Event Opportunity record type`);
}
const opportunitySharing = fs.readFileSync(path.join(metadataRoot, "sharingRules", "Opportunity.sharingRules-meta.xml"), "utf8");
assert(opportunitySharing.includes("<field>RecordTypeId</field>"), "internal NTE Opportunity sharing must be record-type constrained");
assert(opportunitySharing.includes("<value>NTE Event Opportunity</value>"), "internal NTE Opportunity sharing must use the portable record-type label");

assert(masterPanelHtml.includes("Open global list"), "cross-event list navigation must be labelled as global");
assert(masterPanelHtml.includes("View cross-event report"), "cross-event report navigation must state its scope");
assert(masterPanelHtml.includes('tabindex="0"') && masterPanelHtml.includes("onkeydown={handleRowKeyDown}"), "selectable Master Panel rows must be keyboard operable");
assert(masterPanelJs.includes("event.key !== 'Enter' && event.key !== ' '"), "row keyboard handling must support Enter and Space");
assert(!masterPanelJs.includes("conversionWindow.opener = null"), "lead conversion must preserve its opener so Salesforce Cancel can return safely");
assert(!masterPanelJs.includes("NavigationMixin.Navigate](this.leadConversionPageReference"), "lead conversion must not strand users in a same-tab fallback");
const masterPanelCss = fs.readFileSync(path.join(metadataRoot, "lwc", "nteMasterPanel", "nteMasterPanel.css"), "utf8");
for (const match of masterPanelCss.matchAll(/font-size:\s*([0-9.]+)rem/g)) {
  assert(Number(match[1]) >= 0.75, `operational Master Panel text must not use sub-0.75rem sizes (found ${match[1]}rem)`);
}
assert(masterPanelCss.includes(".data-row:focus-visible"), "keyboard-selected rows must have a visible focus treatment");
assert(masterPanelHtml.includes('class="reminder-message"'), "the reminder message editor must expose a dedicated sizing hook");
assert(masterPanelCss.includes("--slds-c-textarea-sizing-min-height: 15rem"), "the reminder message editor must show the complete default copy with editing room");
assert(/primary contact email (?:address|required)/i.test(masterPanelHtml + masterPanelController + dispatchService), "booking guidance must identify the Primary Contact email requirement");
assert(/recipient email address is missing/i.test(dispatchService), "the recipient preview must explain when an email address is missing");

// Payable totals use one aggregate VAT charge, including half-penny rounding.
for (const [net, vat, gross] of [[799,159.80,958.80],[349.50,69.90,419.40],[0,0,0],[100,20,120],[5000,1000,6000],[2.53,0.51,3.04]]) {
  assert.deepStrictEqual(JSON.parse(JSON.stringify(utils.vatTotals(net))), {net,vat,gross});
}
assert(utils.totalText(799).includes("£799.00 + £159.80 VAT (20%)"));
assert(utils.totalText(799).includes("£958.80 including VAT"));

// Exercise the public form handler in the inert DOM used by the stress suite.
// Its submit method captures data in memory and never makes an HTTP request.
const emailHarnessSource = fs.readFileSync(path.join(root, "tests/stress-form-engine.test.js"), "utf8");
const emailHarness = new (require("node:module"))(path.join(root, "tests/email-parity-harness.js"), module);
emailHarness.filename = path.join(root, "tests/email-parity-harness.js");
emailHarness.paths = module.paths;
emailHarness._compile(emailHarnessSource.slice(0, emailHarnessSource.indexOf('test("all current public forms are covered"'))
  + "\nmodule.exports = {fixture,set,complete,filenames};", emailHarness.filename);
const emailForms = emailHarness.exports;
for (const filename of emailForms.filenames) {
  const f = emailForms.complete(emailForms.fixture(filename));
  const email = f.form.querySelector('[data-sf-field="Email"]');
  emailForms.set(f, email, "name@singlelabel");
  f.form.requestSubmit();
  assert.strictEqual(f.document.posts.length, 0, filename + ": native-invalid email must be rejected before transport");
  assert.strictEqual(f.document.activeElement, email, filename + ": focus the email that needs correcting");
  assert.match(email.validationMessage, /complete email address/i);
  emailForms.set(f, email, "alex.bennett+nte@example.invalid");
  f.form.requestSubmit();
  assert.strictEqual(f.document.posts.length, 1, filename + ": correcting the address permits submission");
}
for (const [filename, sourceId, toggleId, toggleValue] of [
  ["exhibitor-application.html", "invoice-email", null, null],
  ["exhibitor-application.html", "second-email", "second-contact-toggle", "Yes"],
  ["partner-sponsor-application.html", "partner-invoice-email", null, null],
  ["partner-sponsor-application.html", "partner-day-email", "partner-day-contact-same", "No"],
  ["guest-registration.html", "guest-companion-email", "guest-accompanying", "Yes"],
  ["heavy-vehicle-details.html", "vehicle-second-email", null, null]
]) {
  const f = emailForms.complete(emailForms.fixture(filename));
  if (toggleId) emailForms.set(f, toggleId, toggleValue);
  emailForms.complete(f);
  emailForms.set(f, sourceId, "name@singlelabel");
  f.form.requestSubmit();
  assert.strictEqual(f.document.posts.length, 0, sourceId + ": native Email targets have the same address rule");
  assert.strictEqual(f.document.activeElement, f.get(sourceId));
}
for (const address of ["alex.bennett+nte@example.invalid", "o'hara@example.invalid", "UPPER.Case@sub-domain.example.invalid",
  "customer/department=shipping@example.invalid", "person_2027@example.travel"]) {
  const f = emailForms.complete(emailForms.fixture("exhibitor-interest.html"));
  emailForms.set(f, f.form.querySelector('[data-sf-field="Email"]'), address);
  f.form.requestSubmit();
  assert.strictEqual(f.document.posts.length, 1, "Preserve native-qualified address variant: " + address);
  assert.strictEqual(f.document.posts[0].email, address);
}
{
  const f = emailForms.complete(emailForms.fixture("exhibitor-application.html"));
  emailForms.set(f, "invoice-email", "name@singlelabel");
  emailForms.set(f, "organisation-category", "Charity - member of Cobseo");
  emailForms.set(f, f.form.querySelectorAll('[name="exhibitor-space"]').find(c => c.value === "COBSEO Charity - Single - Free"), true);
  emailForms.set(f, f.form.querySelectorAll('[name="power-required"]').find(c => c.value === "No"), true);
  emailForms.set(f, "planned-count", 2);
  f.form.requestSubmit();
  assert.strictEqual(f.document.posts.length, 1, "A disabled old finance address must not block a complimentary application");
}
{
  const f = emailForms.complete(emailForms.fixture("exhibitor-application.html"));
  emailForms.set(f, "second-contact-toggle", "Yes");
  emailForms.complete(f);
  emailForms.set(f, "second-email", "");
  f.form.requestSubmit();
  assert.strictEqual(f.document.posts.length, 1, "An optional blank secondary email remains optional");
}

console.log("NTE form tests passed.");
