"use strict";

const assert = require("assert");
const fs = require("fs");
const path = require("path");
const {compileEmailPresentation, previewEmailPresentation, nativeEmailTextFromHtml} = require("../scripts/email-template-presentation");
const {plainTextFromHtml} = require("../scripts/email-formatting");
const row = '<tr data-nte-optional="true"><td class="field-label">Finance contact</td><td class="field-value" data-nte-join=" · ">{!Lead.Invoiced_Person__c} · {!Lead.Invoiced_Email__c} · {!Lead.Invoice_Contact_Phone__c}</td></tr>';
const fields = ["Lead.Invoiced_Person__c", "Lead.Invoiced_Email__c", "Lead.Invoice_Contact_Phone__c"];
const preview = values => previewEmailPresentation(row, field => values[fields.indexOf(field)]);
assert.strictEqual(preview([null, "", undefined]), "", "Wholly absent optional information has no row or separators");
assert.strictEqual(preview(["", "finance@example.com", ""]), '<tr><td class="field-label">Finance contact</td><td class="field-value">{!Lead.Invoiced_Email__c}</td></tr>', "A partial contact retains its supplied email without leading/trailing separators");
assert.strictEqual(preview(["Alex", "", "07700 900123"]), '<tr><td class="field-label">Finance contact</td><td class="field-value">{!Lead.Invoiced_Person__c} · {!Lead.Invoice_Contact_Phone__c}</td></tr>', "An absent middle component does not leave doubled separators");
assert.strictEqual(preview(["Alex", "finance@example.com", "07700 900123"]), row.replace(' data-nte-optional="true"', "").replace(' data-nte-join=" · "', ""), "Populated rows preserve existing client-visible wording and markup");
assert(preview([0, false, ""]).includes("{!Lead.Invoiced_Person__c} · {!Lead.Invoiced_Email__c}"), "Zero and false are data, not missing information");
const unusual = ['A <b>& {NTE_FINANCE_SUMMARY} "quote"', "x@example.com", "first\nsecond"];
assert.strictEqual(preview(unusual), preview(["Alex", "x@example.com", "07700 900123"]), "Presentation selection never interpolates or reinterprets recipient text");
for (const object of ["Lead", "Contact"]) {
  const greeting = `<!--NTE_GREETING:${object}.FirstName-->`;
  assert.strictEqual(previewEmailPresentation(greeting, () => null), "Hello,");
  assert.strictEqual(previewEmailPresentation(greeting, () => "Alex"), `Hi {!${object}.FirstName},`);
  assert.strictEqual(previewEmailPresentation(greeting, () => 'A <b>&{x}</b>'), `Hi {!${object}.FirstName},`, "Escaping remains the existing native/preview field-merge responsibility");
  assert.strictEqual(compileEmailPresentation(greeting), `{!IF(ISBLANK(${object}.FirstName),"Hello,","Hi ")}{!${object}.FirstName}{!IF(ISBLANK(${object}.FirstName),"",",")}`);
}
const native = compileEmailPresentation(row);
assert(!native.includes("data-nte-"), "Authoring attributes never ship in deployed templates");
for (const field of fields) assert.strictEqual(native.split(`{!${field}}`).length - 1, 1, "Keep each field as one ordinary native merge token");
assert(!native.includes("HTMLENCODE"), "Do not place field data inside formula-generated markup or double-escape it");
const text = nativeEmailTextFromHtml(native);
assert(!/<(?:tr|td)\b/.test(text), "The text alternative contains conditional text, never conditional HTML markup");
assert(text.includes('"Finance contact ")'), "The optional row label is conditional in the text alternative too");
assert(text.endsWith("{!Lead.Invoice_Contact_Phone__c}\n"), "Native row separation is ordinary text, outside the optional formula");
const adjacentRows = nativeEmailTextFromHtml(native + '<tr><td>Quotation required</td><td>{!Lead.Quote_Required_for_PO__c}</td></tr>');
assert(adjacentRows.includes("{!Lead.Invoice_Contact_Phone__c}\nQuotation required "), "Populated optional rows cannot run into the following row");
assert.strictEqual(nativeEmailTextFromHtml('<p>Unconditional</p><p>{!Lead.FirstName}</p>'), plainTextFromHtml('<p>Unconditional</p><p>{!Lead.FirstName}</p>'), "Unconditional text alternatives remain unchanged");
assert.throws(() => nativeEmailTextFromHtml('{!IF(ISBLANK(Lead.FirstName),"","First<br>Second")}'), /cannot contain literal line breaks/, "Reject unsupported multiline formula literals before deployment");
assert.throws(() => compileEmailPresentation('<tr data-nte-optional="true"><td>No field</td></tr>'), /at least one merge field/);
assert.throws(() => compileEmailPresentation(row.replace('data-nte-join=" · "', 'data-nte-join=" - "')), /exact separator/);
assert.throws(() => compileEmailPresentation('<tr data-nte-optional="yes"></tr>'), /Invalid email presentation annotation/);
assert.throws(() => previewEmailPresentation(row), /field-value reader/);

// Classic native formula support varies by field type. These cosmetic conditions
// are deliberately limited to text-valued fields; numerical/checkbox/picklist
// status rows keep their existing unconditioned markup and meaningful values.
const root = path.resolve(__dirname, "..");
for (const filename of fs.readdirSync(path.join(root, "email-templates/source"))) {
  const source = fs.readFileSync(path.join(root, "email-templates/source", filename), "utf8");
  for (const token of nativeEmailTextFromHtml(compileEmailPresentation(source)).matchAll(/\{![\s\S]*?\}/g)) {
    assert(!/[\r\n]/.test(token[0]), `${filename}: native text has no unsupported multiline formula`);
  }
  for (const annotated of source.matchAll(/<(tr|td)[^>]*data-nte-(?:optional|join)=[^>]*>([\s\S]*?)<\/\1>/g)) {
    for (const field of annotated[2].matchAll(/\{!((?:Lead|Opportunity)\.([A-Za-z0-9_]+))\}/g)) {
      const [object, api] = field[1].split(".");
      const xml = fs.readFileSync(path.join(root, "force-app/main/default/objects", object, "fields", `${api}.field-meta.xml`), "utf8");
      const type = xml.match(/<type>([^<]+)<\/type>/)[1];
      assert(["Text", "LongTextArea", "Email", "Phone"].includes(type), `${filename}: ${field[1]} must keep unconditional markup for ${type} values`);
    }
  }
}

module.exports = {row, fields};
console.log("Email presentation: empty/partial/full rows, greeting fallbacks, meaningful zero/false values and native merge boundaries pass.");
