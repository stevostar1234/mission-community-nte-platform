"use strict";

// Runs the maintained HTML and JavaScript against an isolated DOM fixture. Native
// browser behaviour and visual rendering are checked separately in the run log.
const assert = require("node:assert/strict");
const fs = require("node:fs");
const path = require("node:path");
const vm = require("node:vm");
const root = process.env.NTE_FORM_SOURCE_ROOT ? path.resolve(process.env.NTE_FORM_SOURCE_ROOT) : path.resolve(__dirname, "..");
const filenames = fs.readdirSync(root).filter(name => name.endsWith(".html") && /data-web-to-lead/.test(fs.readFileSync(path.join(root, name), "utf8")));
const decode = text => text.replace(/&(?:amp|quot|apos|lt|gt|pound|#39|#163);/g, value => ({"&amp;":"&", "&quot;":'"', "&apos;":"'", "&lt;":"<", "&gt;":">", "&pound;":"£", "&#39;":"'", "&#163;":"£"})[value]);

class FixtureEvent {
  constructor(type, options = {}) { this.type = type; this.bubbles = !!options.bubbles; this.defaultPrevented = false; Object.assign(this, options); }
  preventDefault() { this.defaultPrevented = true; }
}

class Element {
  constructor(tagName, doc) {
    this.tagName = tagName.toUpperCase(); this.ownerDocument = doc; this.attributes = {}; this.dataset = {}; this.children = []; this.listeners = {}; this.style = {}; this._value = undefined; this._text = ""; this._checked = false; this.validationMessage = "";
    this.classList = {toggle: (name, enabled) => { const names = new Set(this.className.split(/\s+/).filter(Boolean)); enabled ? names.add(name) : names.delete(name); this.className = [...names].join(" "); }};
  }
  setAttribute(name, value) { this.attributes[name] = String(value); if (name.startsWith("data-")) this.dataset[name.slice(5).replace(/-([a-z])/g, (_, letter) => letter.toUpperCase())] = String(value); }
  getAttribute(name) { return Object.hasOwn(this.attributes, name) ? this.attributes[name] : null; }
  hasAttribute(name) { return Object.hasOwn(this.attributes, name); }
  removeAttribute(name) { delete this.attributes[name]; }
  appendChild(child) { child.parentElement = child.parentNode = this; this.children.push(child); return child; }
  insertBefore(child, before) { child.parentElement = child.parentNode = this; this.children.splice(this.children.indexOf(before), 0, child); }
  remove() { if (this.parentNode) this.parentNode.children.splice(this.parentNode.children.indexOf(this), 1); }
  get textContent() { return this._text + this.children.map(child => child.textContent).join(""); }
  set textContent(value) { this._text = String(value); this.children = []; }
  get value() {
    if (this._value !== undefined) return this._value;
    if (this.tagName === "SELECT") { const option = this.querySelector("option[selected]") || this.querySelector("option"); return option ? option.value : ""; }
    if (this.tagName === "OPTION") return this.getAttribute("value") ?? this.textContent;
    if (this.tagName === "TEXTAREA") return this.textContent;
    return this.getAttribute("value") ?? (/^(checkbox|radio)$/.test(this.type) ? "on" : "");
  }
  set value(value) { this._value = String(value); }
  get checked() { return this._checked; }
  set checked(value) { if (value && this.type === "radio" && this.name) this.form?.querySelectorAll('input[type="radio"]').filter(other => other.name === this.name).forEach(other => { other._checked = false; }); this._checked = !!value; }
  get type() { return this.getAttribute("type") || (this.tagName === "INPUT" ? "text" : this.tagName === "BUTTON" ? "submit" : ""); }
  set type(value) { this.setAttribute("type", value); }
  get form() { return this.closest("form"); }
  matches(selector) {
    selector = selector.trim();
    const attrs = [...selector.matchAll(/\[([^\]=]+)(?:="([^"]*)")?\]/g)];
    selector = selector.replace(/\[[^\]]*\]/g, "");
    if (selector.includes(":checked") && !this.checked) return false;
    if (selector.includes(":disabled") && !this.disabled) return false;
    if (selector.includes(":enabled") && this.disabled) return false;
    selector = selector.replace(/:(checked|disabled|enabled)/g, "");
    const id = selector.match(/#([\w-]+)/); if (id && this.id !== id[1]) return false;
    const tag = selector.match(/^[a-z]+/i); if (tag && this.tagName !== tag[0].toUpperCase()) return false;
    return attrs.every(([, name, value]) => this.hasAttribute(name) && (value === undefined || this.getAttribute(name) === value));
  }
  querySelectorAll(selectors) { const list = selectors.split(/,(?=(?:[^"]*"[^"]*")*[^"]*$)/); const matches = []; const visit = node => node.children.forEach(child => { if (list.some(selector => child.matches(selector))) matches.push(child); visit(child); }); visit(this); return matches; }
  querySelector(selector) { return this.querySelectorAll(selector)[0] || null; }
  closest(selector) { return this.matches(selector) ? this : this.parentElement?.closest(selector) || null; }
  addEventListener(name, callback) { (this.listeners[name] ||= []).push(callback); }
  dispatchEvent(event) { event.target ||= this; (this.listeners[event.type] || []).forEach(listener => listener(event)); if (event.bubbles) this.parentElement?.dispatchEvent(event); return !event.defaultPrevented; }
  focus() { this.ownerDocument.activeElement = this; }
  setCustomValidity(message) { this.validationMessage = message; }
  checkValidity() {
    if (this.tagName === "FORM") return this.querySelectorAll("input, select, textarea").every(control => control.checkValidity());
    if (this.disabled || this.type === "hidden") return true;
    if (this.validationMessage) return false;
    if (this.required && (this.type === "radio" ? !this.form.querySelectorAll('input[type="radio"]').some(other => other.name === this.name && other.checked && !other.disabled) : this.type === "checkbox" ? !this.checked : !this.value)) return false;
    if (!this.value || /^(checkbox|radio)$/.test(this.type)) return true;
    if (this.type === "email" && !/^[^\s@]+@[^\s@]+$/.test(this.value)) return false;
    if (this.type === "url") { try { new URL(this.value); } catch { return false; } }
    if (this.tagName === "SELECT" && !this.querySelectorAll("option").some(option => option.value === this.value)) return false;
    if (this.type === "number") { const value = Number(this.value); if (!Number.isFinite(value) || (this.min !== "" && value < Number(this.min)) || (this.max !== "" && value > Number(this.max)) || (this.step !== "any" && (value - Number(this.min || 0)) % Number(this.step || 1))) return false; }
    if (this.type === "date" && (!/^\d{4}-\d{2}-\d{2}$/.test(this.value) || (this.min && this.value < this.min) || (this.max && this.value > this.max))) return false;
    if (this.pattern) { try { if (!new RegExp("^(?:" + this.pattern + ")$", "v").test(this.value)) return false; } catch {} }
    // Browsers do not enforce maxlength on values written by script/autofill.
    return true;
  }
  reportValidity() { const invalid = this.tagName === "FORM" ? this.querySelectorAll("input, select, textarea").find(control => !control.checkValidity()) : !this.checkValidity() && this; if (invalid) invalid.focus(); return !invalid; }
  requestSubmit() { if (this.noValidate || this.reportValidity()) this.dispatchEvent(new FixtureEvent("submit", {bubbles: true})); }
  submit() { if (this.ownerDocument.failSubmit) throw new Error("Navigation unavailable"); this.ownerDocument.posts.push(Object.fromEntries(this.querySelectorAll("input").map(input => [input.name, input.value]))); }
}
for (const name of ["required", "disabled", "hidden", "noValidate"]) Object.defineProperty(Element.prototype, name, {get() { return this.hasAttribute(name.toLowerCase()); }, set(value) { value ? this.setAttribute(name.toLowerCase(), "") : this.removeAttribute(name.toLowerCase()); }});
for (const name of ["id", "name", "min", "max", "step", "pattern", "className", "action", "method", "href"]) { const attr = name === "className" ? "class" : name; Object.defineProperty(Element.prototype, name, {get() { return this.getAttribute(attr) || ""; }, set(value) { this.setAttribute(attr, value); }}); }
Object.defineProperty(Element.prototype, "maxLength", {get() { return this.hasAttribute("maxlength") ? Number(this.getAttribute("maxlength")) : -1; }, set(value) { this.setAttribute("maxlength", value); }});

function parse(html) {
  const doc = new Element("document", null); doc.ownerDocument = doc; doc.posts = []; doc.createElement = tag => new Element(tag, doc); doc.getElementById = id => doc.querySelector("#" + id);
  const stack = [doc]; const voids = /^(area|base|br|col|embed|hr|img|input|link|meta|param|source|track|wbr)$/i;
  for (const token of html.matchAll(/<!--[\s\S]*?-->|<![^>]*>|<\/?[a-z][^>]*>|[^<]+/gi)) {
    const text = token[0]; if (/^<!/.test(text)) continue;
    if (text.startsWith("</")) { const tag = text.match(/^<\/([\w-]+)/)[1].toUpperCase(); while (stack.length > 1 && stack.pop().tagName !== tag) {} continue; }
    if (text.startsWith("<")) { const tag = text.match(/^<([\w-]+)/)[1]; const node = doc.createElement(tag); for (const match of text.slice(tag.length + 1, -1).matchAll(/([^\s=/>]+)(?:\s*=\s*(?:"([^"]*)"|'([^']*)'|([^\s>]+)))?/g)) node.setAttribute(match[1], decode(match[2] ?? match[3] ?? match[4] ?? "")); stack.at(-1).appendChild(node); if (!voids.test(tag)) stack.push(node); }
    else stack.at(-1)._text += decode(text);
  }
  doc.body = doc.querySelector("body"); return doc;
}

function fixture(filename, options = {}, runtime = {}) {
  const document = parse(fs.readFileSync(path.join(root, filename), "utf8"));
  const window = new Element("window", document); window.crypto = require("node:crypto").webcrypto; window.location = {href: "https://stevostar1234.github.io/nte27-web-to-lead-demo/" + filename};
  let currentTime = runtime.now ? Date.parse(runtime.now) : Date.now();
  class FixtureDate extends Date {
    constructor(...args) { super(...(args.length ? args : [currentTime])); }
    static now() { return currentTime; }
  }
  const context = vm.createContext({window, document, Intl, Date: runtime.now ? FixtureDate : Date, Uint8Array, URL, Math, Event: FixtureEvent, console});
  vm.runInContext(fs.readFileSync(path.join(root, "assets/config.js"), "utf8"), context);
  Object.assign(window.NTE_CONFIG, options);
  const source = fs.readFileSync(process.env.NTE_FORM_SCRIPT_PATH || path.join(root, "assets/forms.js"), "utf8").replace(/\}\(\)\);\s*$/, "window.NTEFormTestUtils = {collectFields, validateHeavyItems, validateStaffUpdate, syncCombinedFields, exhibitorSpacePrices: typeof exhibitorSpacePrices === 'undefined' ? null : exhibitorSpacePrices, sponsorPackagePrices: typeof sponsorPackagePrices === 'undefined' ? null : sponsorPackagePrices}; }());");
  vm.runInContext(source, context);
  return {document, window, form: document.querySelector("form[data-web-to-lead]"), utils: window.NTEFormUtils, internals: window.NTEFormTestUtils, get: id => document.getElementById(id), advanceTo: instant => { currentTime = Date.parse(instant); }};
}

function set(f, id, value, notify = true) { const control = typeof id === "string" ? f.get(id) : id; assert(control, "fixture control exists: " + id); if (/^(checkbox|radio)$/.test(control.type)) control.checked = value; else control.value = value; if (notify) { control.dispatchEvent(new FixtureEvent("input", {bubbles: true})); control.dispatchEvent(new FixtureEvent("change", {bubbles: true})); } return control; }
function complete(f) {
  for (let round = 0; round < 4; round++) {
    for (const control of f.form.querySelectorAll("input, select, textarea")) {
      if (!control.required || control.disabled || control.type === "hidden" || control.value && !/^(radio|checkbox)$/.test(control.type)) continue;
      if (control.type === "radio") { if (!f.form.querySelectorAll('input[type="radio"]').some(other => other.name === control.name && other.checked)) set(f, control, true); }
      else if (control.type === "checkbox") set(f, control, true);
      else if (control.tagName === "SELECT") set(f, control, control.querySelectorAll("option").some(option => option.value === "No") ? "No" : control.querySelectorAll("option").find(option => option.value)?.value || "");
      else set(f, control, control.type === "email" ? "elodie@example.invalid" : control.type === "number" ? control.min || "1" : control.type === "date" ? "2026-09-01" : control.dataset.sfField === "Target_Booking_Reference__c" ? "NTE-1788777600000-ABCDEFGH" : control.type === "tel" ? "+44 7700 900123" : "Élodie O’Neill");
    }
    f.form.querySelectorAll("[data-required-checkbox-group]").forEach(group => { if (!group.querySelector('input[type="checkbox"]:checked')) set(f, group.querySelector('input[type="checkbox"]'), true); });
  }
  return f;
}

let passed = 0; let failed = 0; let matrixCases = 0; const results = [];
function test(name, fn) { if (process.env.NTE_FORM_TEST_FILTER && !name.includes(process.env.NTE_FORM_TEST_FILTER)) return; try { fn(); passed++; results.push({name, passed:true}); } catch (error) { failed++; results.push({name, passed:false, error:error.message}); console.error("FAIL", name, "\n ", error.message); } }
const single = fixture("exhibitor-application.html");
const fieldName = (f, api) => f.window.NTE_CONFIG.customFieldIds[api] || ({Company:"company", FirstName:"first_name", LastName:"last_name", Email:"email"})[api] || api;
const payload = f => f.document.posts.at(-1);

test("all current public forms are covered", () => assert.equal(filenames.length, 10));
for (const filename of filenames) {
  test(filename + ": required schema routes a valid isolated submission once", () => {
    const f = complete(fixture(filename)); f.form.requestSubmit(); assert.equal(f.document.posts.length, 1, f.form.querySelector("[data-form-status]").textContent); f.form.requestSubmit(); assert.equal(f.document.posts.length, 1); assert.equal(payload(f).oid, "00DAd00000A95Vl"); assert.equal(payload(f).useDefaultRule, "0"); assert.equal(payload(f).lead_source, filename === "volunteer-application.html" ? "Volunteer Application" : "Customer Event"); assert.equal(payload(f).retURL.endsWith(filename === "volunteer-application.html" ? "/volunteer-thank-you.html" : "/thank-you.html"), true);
  });
  test(filename + ": blank or malformed required values never reach the transport", () => {
    const f = complete(fixture(filename)); const name = f.form.querySelector('input[data-sf-field="LastName"]'); set(f, name, " \t "); f.form.requestSubmit(); assert.equal(f.document.posts.length, 0); set(f, name, "O’Neill"); set(f, f.form.querySelector('input[type="email"]'), "no-email"); f.form.requestSubmit(); assert.equal(f.document.posts.length, 0);
  });
  test(filename + ": script-assigned overlong text is rejected without truncation", () => {
    const f = complete(fixture(filename)); const name = f.form.querySelector('[data-sf-field="FirstName"]'); set(f, name, "É".repeat(41)); f.form.requestSubmit(); assert.equal(f.document.posts.length, 0); assert.equal(name.value.length, 41); set(f, name, "É".repeat(40)); f.form.requestSubmit(); assert.equal(f.document.posts.length, 1);
  });
  test(filename + ": future and out-of-range signature dates are rejected", () => {
    const f = complete(fixture(filename)); const date = f.form.querySelector('[data-sf-field="Declaration_Date__c"]'); for (const value of ["2099-01-01", "2025-12-31"]) { set(f, date, value); f.form.requestSubmit(); assert.equal(f.document.posts.length, 0); } set(f, date, "2026-09-01"); f.form.requestSubmit(); assert.equal(payload(f)[fieldName(f, "Declaration_Date__c")], "01/09/2026");
  });
  test(filename + ": transport exceptions clear busy state and permit retry", () => {
    const f = complete(fixture(filename)); f.document.failSubmit = true; assert.doesNotThrow(() => f.form.requestSubmit()); assert.notEqual(f.form.dataset.submitting, "true"); assert.equal(f.form.querySelector('[type="submit"]').disabled, false); f.document.failSubmit = false; f.form.requestSubmit(); assert.equal(f.document.posts.length, 1);
  });
  test(filename + ": restored pages leave submit available", () => {
    const f = complete(fixture(filename)); f.form.requestSubmit(); f.window.dispatchEvent(new FixtureEvent("pageshow", {persisted:true})); assert.notEqual(f.form.dataset.submitting, "true"); assert.equal(f.form.querySelector('[type="submit"]').disabled, false);
  });
  test(filename + ": malicious-looking Unicode remains literal form data", () => {
    const f = complete(fixture(filename)); const value = 'Élodie <script>alert("&");</script> 李'; set(f, f.form.querySelector('[data-sf-field="LastName"]'), value); f.form.requestSubmit(); assert.equal(payload(f).last_name, value); assert.equal(f.document.querySelectorAll("script").length, 2);
  });
}

test("all reference patterns are valid under the HTML v flag and reject punctuation", () => {
  for (const filename of filenames) for (const control of fixture(filename).form.querySelectorAll('[data-sf-field="Target_Booking_Reference__c"]')) { const regex = new RegExp("^(?:" + control.pattern + ")$", "v"); assert(regex.test("NTE-1788777600000-ABCDEFGH")); for (const value of ["NTE-***", "NTE-", "NTE-A--", "NTE-" + "A".repeat(77)]) assert(!regex.test(value), value); }
});
test("supplementary references normalise before native validation", () => {
  for (const filename of filenames) { const f = complete(fixture(filename)); const ref = f.form.querySelector('[data-sf-field="Target_Booking_Reference__c"]'); if (!ref) continue; set(f, ref, " nte-1788777600000-abcdefgh "); f.form.requestSubmit(); assert.equal(payload(f)?.[fieldName(f, "Target_Booking_Reference__c")], "NTE-1788777600000-ABCDEFGH"); }
});
test("disabled guest name sources cannot leak through a hidden combined field", () => {
  const f = complete(fixture("guest-registration.html")); set(f, "guest-accompanying", "Yes"); set(f, "guest-companion-first-name", "Ana"); set(f, "guest-companion-last-name", "García"); set(f, "guest-companion-email", "ana@example.invalid"); set(f, "guest-accompanying", "No"); f.form.requestSubmit(); for (const api of ["Accompanying_Guest_Name__c", "Accompanying_Guest_Email__c"]) assert.equal(payload(f)[fieldName(f, api)], undefined);
});
test("guest conditionals are synchronised at submit even without change events", () => {
  const f = complete(fixture("guest-registration.html")); set(f, "guest-accompanying", "Yes", false); f.form.requestSubmit(); assert.equal(f.document.posts.length, 0); assert.equal(f.get("guest-companion-first-name").required, true);
});
test("partner count correction clears the name-count validation error", () => {
  const f = complete(fixture("partner-sponsor-staff-update.html")); set(f, "partner-staff-total", "2"); f.form.requestSubmit(); assert.equal(f.document.posts.length, 0); set(f, "partner-staff-total", "1"); f.form.requestSubmit(); assert.equal(f.document.posts.length, 1);
});
test("clearing an incomplete optional heavy item permits submission", () => {
  const f = complete(fixture("heavy-vehicle-details.html")); set(f, "item2-registration", "AB12 CDE"); f.form.requestSubmit(); assert.equal(f.document.posts.length, 0); set(f, "item2-registration", ""); f.form.requestSubmit(); assert.equal(f.document.posts.length, 1);
});
test("staff name sources respect every copied target limit", () => {
  for (const filename of ["exhibitor-staff-update.html", "partner-sponsor-staff-update.html"]) { const f = complete(fixture(filename)); const id = filename.startsWith("partner") ? "partner-staff-names" : "exhibitor-staff-names"; const max = 32768; assert.equal(f.get(id).maxLength, max); set(f, id, "A".repeat(max + 1)); f.form.requestSubmit(); assert.equal(f.document.posts.length, 0); }
});
test("optional heavy item combinations enforce completeness and ordering", () => {
  for (let bits = 0; bits < 16; bits++) { const f = complete(fixture("heavy-vehicle-details.html")); ["description", "registration", "dimensions", "weight"].forEach((part, index) => set(f, "item2-" + part, bits & (1 << index) ? "Value" : "")); const expected = bits === 0 || (bits & 13) === 13; assert.equal(f.internals.validateHeavyItems(f.form), expected, "item2 mask " + bits); matrixCases++; }
  const f = complete(fixture("heavy-vehicle-details.html")); ["description", "dimensions", "weight"].forEach(part => set(f, "item3-" + part, "Value")); assert.equal(f.internals.validateHeavyItems(f.form), false);
});
test("staff counts validate integer bounds and exact name lines", () => {
  for (const count of [0,1,2,99,100,1.5]) for (const names of [0,1,2,99,100]) { const f = complete(fixture("partner-sponsor-staff-update.html")); set(f, "partner-staff-total", String(count)); set(f, "partner-staff-names", Array.from({length:names}, (_, i) => "Person " + i).join("\r\n")); assert.equal(f.internals.validateStaffUpdate(f.form), Number.isInteger(count) && count >= 1 && count <= 99 && count === names); matrixCases++; }
});
test("all package combinations serialize the exact catalogue total", () => {
  const packages = fixture("partner-sponsor-application.html").form.querySelectorAll("[data-package-price]").map(control => Number(control.dataset.packagePrice));
  for (let mask = 0; mask < 2 ** packages.length; mask++) { const selected = packages.filter((_, index) => mask & 2 ** index); assert.equal(single.utils.calculatePartnerPricing(selected).total, selected.reduce((sum, value) => sum + value, 0)); matrixCases++; }
});
test("every exhibitor space, category and count/power boundary has the expected total", () => {
  const f = fixture("exhibitor-application.html"); const spaces = f.form.querySelectorAll('[name="exhibitor-space"]'); const categories = f.get("organisation-category").querySelectorAll("option").map(option => option.value).filter(Boolean);
  for (const space of spaces) for (const category of categories) for (const staff of [1,2,3,4,5,99]) for (const power of ["Yes","No"]) for (const sockets of [1,2,20]) {
    const included = /Double Garage| - Double -/.test(space.value) ? 4 : 2; const unit = power === "Yes" ? /Charity|Government|Blue Light/i.test(category) ? 50 : 100 : 0; const expected = Number(space.dataset.price) + Math.max(staff - included, 0) * 50 + sockets * unit;
    const result = f.utils.calculateExhibitorPricing({spacePrice:space.dataset.price, category, powerRequired:power, socketCount:sockets, plannedStaffCount:staff, includedStaffCount:included}); assert.equal(result.total, expected); assert.equal(f.utils.includedStaffForSpace(space.value), included); matrixCases++;
  }
});
test("invalid quantities cannot produce NaN, infinite or fractional prices", () => {
  for (const field of ["socketCount", "plannedStaffCount", "includedStaffCount", "staffCount"]) for (const value of [-1, 1.5, Infinity, NaN, "many"]) { const options = {spacePrice:800, powerRequired:"Yes", socketCount:1, plannedStaffCount:2, includedStaffCount:2}; if (field === "staffCount") { delete options.plannedStaffCount; delete options.includedStaffCount; } options[field] = value; assert.throws(() => single.utils.calculateExhibitorPricing(options), /number|whole|count|quantity|staff|socket/i, field + "=" + value); matrixCases++; }
});
test("catalogue name prefixes with extra suffixes are rejected", () => { for (const space of single.form.querySelectorAll('[name="exhibitor-space"]')) assert.equal(single.utils.includedStaffForSpace(space.value + " removed"), null); });
test("submit recomputes altered package and exhibitor totals", () => {
  const partner = complete(fixture("partner-sponsor-application.html")); partner.form.querySelector('[data-sf-field="Listed_Price_Total__c"]').value = "0"; partner.form.requestSubmit(); assert.equal(payload(partner)[fieldName(partner,"Listed_Price_Total__c")], "30000");
  const f = complete(fixture("exhibitor-application.html")); set(f,f.form.querySelectorAll('[name="power-required"]').find(control => control.value === "No"),true); set(f,"planned-count","5",false); f.form.requestSubmit(); assert.equal(payload(f)[fieldName(f,"Listed_Price_Total__c")], "750"); assert.equal(payload(f)[fieldName(f,"Additional_Staff_Count__c")], "3");
});
test("nested invoice details are excluded after complimentary selection", () => {
  const f = complete(fixture("exhibitor-application.html")); set(f,"purchase-order","Yes"); set(f,"purchase-order-number","PO-123"); set(f,"invoice-additional-required","Yes"); set(f,"invoice-additional-information","Cost centre 8"); set(f,"organisation-category","Charity - member of Cobseo"); set(f,f.form.querySelectorAll('[name="exhibitor-space"]').find(space => space.value === "COBSEO Charity - Single - Free"),true); set(f,"power-required-yes",false); set(f,f.form.querySelectorAll('[name="power-required"]').find(control => control.value === "No"),true); set(f,"planned-count","2"); f.form.requestSubmit(); for (const api of ["Purchase_Order_Number__c","Invoice_Additional_Information__c","Invoiced_Company__c","Payment_Method__c"]) assert.equal(payload(f)[fieldName(f,api)],undefined); assert.equal(payload(f)[fieldName(f,"Listed_Price_Total__c")], "0");
});

test("client fixed catalogues exactly match current Salesforce names and prices", () => {
  const apex = fs.readFileSync(path.join(root, "force-app/main/default/classes/NTEPricingService.cls"), "utf8");
  for (const [name, actual] of [["EXHIBITOR_SPACE_PRICES",single.internals.exhibitorSpacePrices],["SPONSOR_PACKAGE_PRICES",single.internals.sponsorPackagePrices]]) { const body = apex.match(new RegExp(name + " = new Map<String, Decimal>\\{([\\s\\S]*?)\\n    \\};"))[1]; const expected = Object.fromEntries([...body.matchAll(/'([^']+)'\s*=>\s*([\d.]+)/g)].map(([,key,value]) => [key,Number(value)])); assert.deepEqual(JSON.parse(JSON.stringify(actual)), expected); }
});
test("removed or changed-priced package/space choices fail closed", () => {
  for (const filename of ["exhibitor-application.html", "partner-sponsor-application.html"]) for (const changed of ["name","price"]) { const f=complete(fixture(filename)); const control = f.form.querySelector('[name="exhibitor-space"]:checked') || f.form.querySelector('[data-package-price]:checked'); if (changed === "name") control.value += " retired"; else control.dataset[filename.startsWith("exhibitor") ? "price" : "packagePrice"] = "0"; f.form.requestSubmit(); assert.equal(f.document.posts.length,0); }
  for (const category of ["Fake Charity", "not Government", "Employer - Blue Light & NHS extra", "__proto__"]) assert.equal(single.utils.qualifiesForPowerDiscount(category),false);
});
test("missing configuration and field mappings show a recipient-facing error", () => {
  for (const options of [{orgId:""},{customFieldIds:{}}]) { const f=complete(fixture("guest-registration.html",options)); f.form.requestSubmit(); assert.equal(f.document.posts.length,0); const status=f.form.querySelector("[data-form-status]").textContent; assert.match(status,/unavailable/); assert.doesNotMatch(status,/Salesforce|__c|configuration|production/); }
});
test("honeypot and review modes never create a transport payload", () => {
  const f=complete(fixture("guest-registration.html")); set(f,f.form.querySelector('input[name="website_confirm"]'),"bot"); f.form.requestSubmit(); assert.equal(f.document.posts.length,0);
  const preview=complete(fixture("guest-registration.html",{mode:"review"})); preview.form.requestSubmit(); assert.equal(preview.document.posts.length,0); assert.match(preview.form.querySelector("[data-form-status]").className,/success/);
});
test("malformed initial hidden references fail before posting", () => {
  const f=complete(fixture("exhibitor-application.html")); f.form.querySelector('[data-sf-field="Booking_Reference__c"]').value="BOOKING-001"; f.form.requestSubmit(); assert.equal(f.document.posts.length,0); assert.match(f.form.querySelector("[data-form-status]").textContent,/reference/);
});
test("copied field length boundaries preserve Unicode and multiline values", () => {
  for (const filename of ["partner-sponsor-staff-update.html","exhibitor-staff-update.html"]) { const f=complete(fixture(filename)); const id=filename.startsWith("partner")?"partner-staff-names":"exhibitor-staff-names"; const value="李".repeat(f.get(id).maxLength); set(f,id,value); f.form.requestSubmit(); assert.equal(payload(f)[fieldName(f,"Staff_Base_Names__c")],value); }
});
test("combined exhibitor names respect the final booking field limit", () => {
  const f=complete(fixture("exhibitor-staff-update.html")); set(f,"exhibitor-staff-names","A".repeat(20000)); set(f,"top-up-required","Yes"); set(f,"top-up-count","1"); set(f,"top-up-names","B".repeat(12768)); f.form.requestSubmit(); assert.equal(f.document.posts.length,0); set(f,"top-up-names","B".repeat(12767)); f.form.requestSubmit(); assert.equal(f.document.posts.length,1);
});
test("decimal prices sum in pence and oversized values are rejected", () => { assert.equal(single.utils.calculatePartnerPricing(["0.10","0.20"]).total,0.3); assert.throws(()=>single.utils.calculatePartnerPricing(["9007199254740991"]),/price/); });

test("all partner yes/no billing, accessibility and contact combinations preserve branch payloads", () => {
  const fields=["partner-day-contact-same","partner-accessibility","partner-po","partner-invoice-additional-required","partner-quote"];
  for (let mask=0;mask<64;mask++) { const f=complete(fixture("partner-sponsor-application.html")); fields.forEach((id,index)=>set(f,id,mask & (1<<index) ? "Yes":"No")); set(f,"partner-first-name","Ana"); set(f,"partner-last-name","Smith"); set(f,"partner-day-first-name","Ravi"); set(f,"partner-day-last-name","Patel"); set(f,"partner-payment-method",mask &32 ? "Stripe":"Bank transfer"); complete(f); f.form.requestSubmit(); assert.equal(f.document.posts.length,1,"partner branch mask "+mask+": "+f.form.querySelector("[data-form-status]").textContent); const post=payload(f); for (const [index,api] of [[1,"Stand_Special_Requirements__c"],[2,"Purchase_Order_Number__c"],[3,"Invoice_Additional_Information__c"]]) assert.equal(!!post[fieldName(f,api)],!!(mask &(1<<index)),api+" mask "+mask); assert.equal(post[fieldName(f,"Event_Contact_Name__c")],mask&1 ? "Ana Smith":"Ravi Patel"); matrixCases++; }
});
test("guest yes/no combinations include only chosen companion and accessibility data", () => {
  for (let mask=0;mask<4;mask++) { const f=complete(fixture("guest-registration.html")); set(f,"guest-accompanying","Yes"); set(f,"guest-accessibility","Yes"); complete(f); if (!(mask&1)) set(f,"guest-accompanying","No"); if (!(mask&2)) set(f,"guest-accessibility","No"); f.form.requestSubmit(); assert.equal(f.document.posts.length,1); assert.equal(!!payload(f)[fieldName(f,"Accompanying_Guest_Name__c")],!!(mask&1)); assert.equal(!!payload(f)[fieldName(f,"Guest_Accessibility_Details__c")],!!(mask&2)); matrixCases++; }
});
test("checkbox and radio groups have programmatic group names", () => {
  for (const filename of filenames) { const f=fixture(filename); for (const group of f.form.querySelectorAll("[data-required-checkbox-group], [role=\"radiogroup\"]")) { if (group.tagName === "FIELDSET") assert(group.querySelector("legend")); else { assert(["group","radiogroup"].includes(group.getAttribute("role")),filename); assert(f.get(group.getAttribute("aria-labelledby")),filename); } } }
});
test("invalid event configuration keeps the form unavailable without throwing", () => { const f=complete(fixture("guest-registration.html",{eventCodeOverride:"NTE-next"})); assert.doesNotThrow(()=>f.form.requestSubmit()); assert.equal(f.document.posts.length,0); assert.match(f.form.querySelector("[data-form-status]").textContent,/unavailable/); });
test("native scientific notation counts serialize as ordinary decimal values", () => { const f=complete(fixture("exhibitor-application.html")); set(f,"planned-count","1e1"); set(f,"power-count","1e1"); f.form.requestSubmit(); for (const api of ["Planned_Exhibitor_Count__c","Total_Staff_Count__c","Power_Socket_Count__c"]) assert.equal(payload(f)[fieldName(f,api)],"10"); assert.equal(payload(f)[fieldName(f,"Listed_Price_Total__c")],"2000"); });

for (const boundary of [
  {zone:"BST", before:"2026-09-07T22:59:59.999Z", after:"2026-09-07T23:00:00.000Z", previousDay:"2026-09-07", today:"2026-09-08", tomorrow:"2026-09-09", serialized:"08/09/2026"},
  {zone:"GMT", before:"2027-01-07T23:59:59.999Z", after:"2027-01-08T00:00:00.000Z", previousDay:"2027-01-07", today:"2027-01-08", tomorrow:"2027-01-09", serialized:"08/01/2027"}
]) {
  for (const filename of filenames) {
    test(filename + ": London midnight " + boundary.zone + " refreshes date bounds before submission", () => {
      const f=complete(fixture(filename, {}, {now:boundary.before}));
      const date=f.form.querySelector('[data-sf-field="Declaration_Date__c"]');
      assert.equal(date.max,boundary.previousDay);
      set(f,date,boundary.today);
      f.form.requestSubmit();
      assert.equal(f.document.posts.length,0,"tomorrow must be blocked before midnight");
      f.advanceTo(boundary.after);
      // No input, change or pageshow event occurs between the clock change and Submit.
      f.form.requestSubmit();
      assert.equal(date.max,boundary.today,"max must use the new London day");
      assert.equal(date.value,boundary.today,"the signed date must not be overwritten");
      assert.equal(f.document.posts.length,1,"the new date is valid after midnight");
      assert.equal(payload(f)[fieldName(f,"Declaration_Date__c")],boundary.serialized);
      const dob=f.form.querySelector('[data-sf-field="Date_of_Birth__c"]');
      if(dob) assert.equal(dob.max,boundary.today);
    });
  }
  test("London midnight " + boundary.zone + " preserves earlier valid signatures and still rejects future dates", () => {
    const f=complete(fixture("exhibitor-interest.html", {}, {now:boundary.before}));
    const date=f.form.querySelector('[data-sf-field="Declaration_Date__c"]');
    f.advanceTo(boundary.after);
    set(f,date,boundary.tomorrow);
    f.form.requestSubmit();
    assert.equal(f.document.posts.length,0);
    assert.equal(date.max,boundary.today);
    assert.equal(date.value,boundary.tomorrow,"invalid values stay available for correction");
    set(f,date,boundary.previousDay);
    f.form.requestSubmit();
    assert.equal(f.document.posts.length,1);
    assert.equal(date.value,boundary.previousDay,"a signature entered before midnight remains unchanged");
  });
  test("London midnight " + boundary.zone + " refreshes the date picker on focus without changing the value", () => {
    const f=complete(fixture("volunteer-application.html", {}, {now:boundary.before}));
    const date=f.get("volunteer-dob"); set(f,date,"1988-06-12");
    f.advanceTo(boundary.after);
    date.dispatchEvent(new FixtureEvent("focusin",{bubbles:true}));
    assert.equal(date.max,boundary.today);
    assert.equal(date.value,"1988-06-12");
    assert.equal(f.form.querySelector('[data-sf-field="Declaration_Date__c"]').max,boundary.today);
    assert.equal(f.document.posts.length,0);
  });
}

if (process.env.NTE_FORM_SCHEMA) fs.writeFileSync(path.resolve(process.env.NTE_FORM_SCHEMA), JSON.stringify(filenames.map(filename => { const f=fixture(filename); return {filename, formKind:f.form.dataset.formKind || null, webFormType:f.form.querySelector('[data-sf-field="Web_Form_Type__c"]').value, leadSource:f.form.dataset.leadSource, controls:f.form.querySelectorAll("input, select, textarea").filter(control=>!control.dataset.formHoneypot).map(control=>({id:control.id || null, type:control.type || control.tagName.toLowerCase(), salesforceField:control.dataset.sfField || null, required:control.required, requiredWhenVisible:control.hasAttribute("data-required-when-visible"), maxlength:control.maxLength, min:control.min || null,max:control.max || null,pattern:control.pattern || null,conditionalSource:control.closest("[data-conditional-for]")?.dataset.conditionalFor || null, options:control.tagName === "SELECT" ? control.querySelectorAll("option").map(option=>option.value) : undefined}))}; }),null,2)+"\n");

console.log(`Form engine stress: ${passed} checks passed; ${failed} failed; ${matrixCases} catalogue/boundary combinations.`);
if (process.env.NTE_FORM_RESULTS) fs.writeFileSync(path.resolve(process.env.NTE_FORM_RESULTS), JSON.stringify({sourceRoot:root, generatedAt:new Date().toISOString(), passed,failed,matrixCases,results},null,2)+"\n");
if (failed) process.exitCode = 1;
