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
for (const name of ["required", "disabled", "hidden", "noValidate", "open"]) Object.defineProperty(Element.prototype, name, {get() { return this.hasAttribute(name.toLowerCase()); }, set(value) { value ? this.setAttribute(name.toLowerCase(), "") : this.removeAttribute(name.toLowerCase()); }});
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
function complete(f, options = {}) {
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
  if (f.form.hasAttribute("data-require-code-of-conduct") && options.conduct !== false) {
    readConduct(f);
    set(f, "volunteer-conduct-acknowledgement", true);
  }
  return f;
}

function readConduct(f, scrollTop = 800) {
  const details = f.form.querySelector("[data-conduct-document]");
  const reader = f.form.querySelector("[data-conduct-reader]");
  reader.clientHeight = 400; reader.scrollHeight = 1200; reader.scrollTop = 0;
  details.open = true; details.dispatchEvent(new FixtureEvent("toggle"));
  reader.scrollTop = scrollTop; reader.dispatchEvent(new FixtureEvent("scroll"));
  return reader;
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
  if (filename !== "logo-upload.html") test(filename + ": future and out-of-range signature dates are rejected", () => {
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
test("partner quantity correction permits submission with an independent staff list", () => {
  const f = complete(fixture("partner-sponsor-staff-update.html")); set(f, "partner-staff-total", "100"); f.form.requestSubmit(); assert.equal(f.document.posts.length, 0); assert.equal(f.document.activeElement?.id, "partner-staff-total"); set(f, "partner-staff-total", "2"); f.form.requestSubmit(); assert.equal(f.document.posts.length, 1);
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
test("partner quantities and required staff text validate independently", () => {
  for (const count of [0,1,2,99,100,1.5]) for (const names of [0,1,2,99,100]) {
    const f = complete(fixture("partner-sponsor-staff-update.html"));
    const text = Array.from({length:names}, (_, i) => "Person " + i).join("\r\n");
    set(f, "partner-staff-total", String(count)); set(f, "partner-staff-names", text); f.form.requestSubmit();
    const valid = Number.isInteger(count) && count >= 1 && count <= 99 && names > 0;
    assert.equal(f.document.posts.length, valid ? 1 : 0, "declared quantity " + count + ", roster lines " + names);
    if (valid) {
      assert.equal(payload(f)[fieldName(f,"Total_Staff_Count__c")], String(count));
      assert.equal(payload(f)[fieldName(f,"Planned_Exhibitor_Count__c")], String(count));
      assert.equal(payload(f)[fieldName(f,"Staff_Base_Names__c")], text);
    }
    matrixCases++;
  }
});
test("exhibitor rosters never infer or submit staffing quantities", () => {
  for (const text of ["Alex", "Alex\nBea\nChris", Array.from({length:101}, (_, i) => "Person " + i).join("\n"), "Alex and Bea; Chris", "Alex\n\nBea"]) {
    const f = complete(fixture("exhibitor-staff-update.html")); set(f,"exhibitor-staff-names",text); f.form.requestSubmit();
    assert.equal(f.document.posts.length,1);
    assert.equal(payload(f)[fieldName(f,"Staff_Base_Names__c")],text);
    for (const api of ["Total_Staff_Count__c","Planned_Exhibitor_Count__c","Additional_Staff_Count__c"]) assert.equal(payload(f)[fieldName(f,api)],undefined,api);
    assert.equal(payload(f)[fieldName(f,"Top_Up_Staff_Total__c")],"0");
    matrixCases++;
  }
});
test("top-up charges use purchased quantity regardless of staff names", () => {
  for (const count of [0,1,2,99,100,1.5]) for (const text of ["", "Alex", "Alex\nBea\nChris", Array.from({length:100}, (_, i) => "Person " + i).join("\n")]) {
    const f = complete(fixture("exhibitor-staff-update.html"));
    set(f,"top-up-required","Yes"); set(f,"top-up-count",String(count)); set(f,"top-up-names",text); f.form.requestSubmit();
    const valid = Number.isInteger(count) && count >= 1 && count <= 99 && !!text;
    assert.equal(f.document.posts.length, valid ? 1 : 0, "purchased quantity " + count + ", staff text " + text.slice(0,20));
    if (valid) {
      assert.equal(payload(f)[fieldName(f,"Top_Up_Staff_Count__c")],String(count));
      assert.equal(payload(f)[fieldName(f,"Top_Up_Staff_Unit_Price__c")],"50");
      assert.equal(payload(f)[fieldName(f,"Top_Up_Staff_Total__c")],String(count * 50));
      assert.equal(payload(f)[fieldName(f,"Top_Up_Staff_Names__c")],text);
      assert.equal(f.form.querySelector("[data-top-up-estimate]").textContent,f.utils.totalText(count * 50));
    }
    matrixCases++;
  }
});
test("blank staff names remain invalid and hidden top-up names stay excluded", () => {
  for (const [filename,id] of [["partner-sponsor-staff-update.html","partner-staff-names"],["exhibitor-staff-update.html","exhibitor-staff-names"]]) {
    const f=complete(fixture(filename)); set(f,id," \r\n \t"); f.form.requestSubmit(); assert.equal(f.document.posts.length,0); assert.equal(f.document.activeElement?.id,id);
    set(f,id,"Alex and Bea"); f.form.requestSubmit(); assert.equal(f.document.posts.length,1);
  }
  const f=complete(fixture("exhibitor-staff-update.html")); set(f,"top-up-required","Yes"); set(f,"top-up-count","2"); set(f,"top-up-names"," \n "); f.form.requestSubmit(); assert.equal(f.document.posts.length,0);
  set(f,"top-up-required","No"); f.form.requestSubmit(); assert.equal(f.document.posts.length,1);
  for (const api of ["Top_Up_Staff_Count__c","Top_Up_Staff_Names__c"]) assert.equal(payload(f)[fieldName(f,api)],undefined,api);
  assert.equal(payload(f)[fieldName(f,"Top_Up_Staff_Total__c")],"0");
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
  const f = complete(fixture("exhibitor-application.html")); set(f,f.form.querySelectorAll('[name="power-required"]').find(control => control.value === "No"),true); set(f,"planned-count","5",false); f.form.requestSubmit(); assert.equal(payload(f)[fieldName(f,"Listed_Price_Total__c")], "749"); assert.equal(payload(f)[fieldName(f,"Additional_Staff_Count__c")], "3");
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
test("native scientific notation counts serialize as ordinary decimal values", () => { const f=complete(fixture("exhibitor-application.html")); set(f,"planned-count","1e1"); set(f,"power-count","1e1"); f.form.requestSubmit(); for (const api of ["Planned_Exhibitor_Count__c","Total_Staff_Count__c","Power_Socket_Count__c"]) assert.equal(payload(f)[fieldName(f,api)],"10"); assert.equal(payload(f)[fieldName(f,"Listed_Price_Total__c")],"1999"); });

for (const boundary of [
  {zone:"BST", before:"2026-09-07T22:59:59.999Z", after:"2026-09-07T23:00:00.000Z", previousDay:"2026-09-07", today:"2026-09-08", tomorrow:"2026-09-09", serialized:"08/09/2026"},
  {zone:"GMT", before:"2027-01-07T23:59:59.999Z", after:"2027-01-08T00:00:00.000Z", previousDay:"2027-01-07", today:"2027-01-08", tomorrow:"2027-01-09", serialized:"08/01/2027"}
]) {
  for (const filename of filenames.filter(name => name !== "logo-upload.html")) {
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

test("volunteer emergency address requires separate details unless same-address is selected", () => {
  const f = complete(fixture("volunteer-application.html"));
  set(f, "volunteer-emergency-address", ""); set(f, "volunteer-emergency-postcode", "");
  f.form.requestSubmit(); assert.equal(f.document.posts.length, 0);
  set(f, "volunteer-address", "14 Meadow Lane\nBristol"); set(f, "volunteer-postcode", "BS1 4AA");
  set(f, "volunteer-emergency-same-address", true);
  assert.equal(f.get("volunteer-emergency-address").disabled, true);
  assert.equal(f.get("volunteer-emergency-address").required, false);
  f.form.requestSubmit(); assert.equal(f.document.posts.length, 1);
  assert.equal(payload(f)[fieldName(f, "NOK_Address__c")], "14 Meadow Lane\nBristol");
  assert.equal(payload(f)[fieldName(f, "NOK_Postcode__c")], "BS1 4AA");
});
test("volunteer same-address submits latest address even without change events", () => {
  const f = complete(fixture("volunteer-application.html"));
  set(f, "volunteer-emergency-address", "Separate address"); set(f, "volunteer-emergency-postcode", "OX12 9AA");
  set(f, "volunteer-emergency-same-address", true, false);
  set(f, "volunteer-address", "22 River Road\nYork", false); set(f, "volunteer-postcode", "YO1 1AA", false);
  f.form.requestSubmit(); assert.equal(f.document.posts.length, 1);
  assert.equal(payload(f)[fieldName(f, "NOK_Address__c")], "22 River Road\nYork");
  assert.equal(payload(f)[fieldName(f, "NOK_Postcode__c")], "YO1 1AA");
});
test("volunteer unticking same-address restores the separate address without overwriting it", () => {
  const f = complete(fixture("volunteer-application.html"));
  set(f, "volunteer-emergency-address", "8 Oak Street\nLeeds"); set(f, "volunteer-emergency-postcode", "LS1 1AA");
  set(f, "volunteer-emergency-same-address", true); set(f, "volunteer-emergency-same-address", false);
  assert.equal(f.get("volunteer-emergency-address").required, true);
  assert.equal(f.get("volunteer-emergency-address").disabled, false);
  f.form.requestSubmit(); assert.equal(f.document.posts.length, 1);
  assert.equal(payload(f)[fieldName(f, "NOK_Address__c")], "8 Oak Street\nLeeds");
  assert.equal(payload(f)[fieldName(f, "NOK_Postcode__c")], "LS1 1AA");
});
test("volunteer address requirements refresh after a restored page", () => {
  const f = complete(fixture("volunteer-application.html")); set(f, "volunteer-emergency-same-address", true, false);
  f.window.dispatchEvent(new FixtureEvent("pageshow", {persisted:true}));
  assert.equal(f.get("volunteer-emergency-address-field").hidden, true);
  set(f, "volunteer-emergency-same-address", false, false); set(f, "volunteer-emergency-address", "", false);
  f.form.requestSubmit(); assert.equal(f.document.posts.length, 0);
  assert.equal(f.get("volunteer-emergency-address").required, true);
});
test("volunteer separate emergency address rejects overlong values before transport", () => {
  for (const [id, limit] of [["volunteer-emergency-address",1000],["volunteer-emergency-postcode",20]]) {
    const f=complete(fixture("volunteer-application.html"));set(f,id,"A".repeat(limit+1));f.form.requestSubmit();assert.equal(f.document.posts.length,0);
    set(f,id,"A".repeat(limit));f.form.requestSubmit();assert.equal(f.document.posts.length,1);
  }
});
test("volunteer hour checkboxes select one range and preserve every requested value", () => {
  for (const value of ["0-4","4-8","8-16","16+","Don't know"]) {
    const f=complete(fixture("volunteer-application.html"));
    const choices=f.form.querySelectorAll('[data-sf-field="Volunteer_Hours__c"]');
    set(f,choices.find(control=>control.value===value),true);
    assert.deepEqual(choices.filter(control=>control.checked).map(control=>control.value),[value]);
    f.form.requestSubmit();assert.equal(f.document.posts.length,1);
    assert.equal(payload(f)[fieldName(f,"Volunteer_Hours__c")],value);
  }
});
test("volunteer availability allows weekdays and weekends while keeping Any exclusive", () => {
  const f=complete(fixture("volunteer-application.html"));
  const choices=f.form.querySelectorAll('[data-sf-field="Volunteer_Availability__c"]');
  const choose=value=>set(f,choices.find(control=>control.value===value),true);
  choose("Weekdays");choose("Weekends");assert.equal(choices.filter(control=>control.checked).length,2);
  choose("Any");assert.deepEqual(choices.filter(control=>control.checked).map(control=>control.value),["Any"]);
  choose("Weekends");assert.deepEqual(choices.filter(control=>control.checked).map(control=>control.value),["Weekends"]);
  choose("Weekdays");f.form.requestSubmit();assert.equal(f.document.posts.length,1);
  assert.equal(payload(f)[fieldName(f,"Volunteer_Availability__c")],"Weekdays;Weekends");
});
test("volunteer missing or conflicting availability never reaches transport", () => {
  for (const api of ["Volunteer_Hours__c","Volunteer_Availability__c"]) {
    const f=complete(fixture("volunteer-application.html"));const choices=f.form.querySelectorAll('[data-sf-field="'+api+'"]');
    choices.forEach(control=>set(f,control,false));f.form.requestSubmit();assert.equal(f.document.posts.length,0);
    set(f,choices[0],true,false);set(f,choices.at(-1),true,false);f.form.requestSubmit();assert.equal(f.document.posts.length,0);
  }
});
test("volunteer revised opportunities and skills reach their own Salesforce fields", () => {
  const f=complete(fixture("volunteer-application.html"));
  for (const api of ["Volunteer_Opportunities__c","Volunteer_Skills__c"]) {
    const choices=f.form.querySelectorAll('[data-sf-field="'+api+'"]');choices.forEach(control=>set(f,control,false));
    for (const value of ["Transport and Logistics","Marshalling","Pop up shop"]) set(f,choices.find(control=>control.value===value),true);
    assert.equal(choices.some(control=>["Driving / Transport","Charity Merchandise / Shop Support"].includes(control.value)),false);
  }
  f.form.requestSubmit();assert.equal(f.document.posts.length,1);
  for (const api of ["Volunteer_Opportunities__c","Volunteer_Skills__c"]) assert.equal(payload(f)[fieldName(f,api)],"Transport and Logistics;Marshalling;Pop up shop");
});

test("all organisation categories can select every space without losing their selection", () => {
  const f = complete(fixture("exhibitor-application.html"));
  const spaces = f.form.querySelectorAll('[name="exhibitor-space"]');
  const categories = f.get("organisation-category").querySelectorAll("option").map(option => option.value).filter(Boolean);
  assert.equal(categories.length, 19); assert.equal(spaces.length, 27);
  set(f, "planned-count", "2");
  set(f, f.form.querySelectorAll('[name="power-required"]').find(node => node.value === "No"), true);
  for (const category of categories) {
    set(f, "organisation-category", category);
    for (const space of spaces) {
      assert.equal(space.disabled, false, category + " / " + space.value);
      set(f, space, true);
      assert.equal(space.checked, true);
      assert.equal(f.form.querySelector('[data-sf-field="Listed_Price_Total__c"]').value, String(Number(space.dataset.price)));
      assert.equal(f.get("billing").hidden, Number(space.dataset.price) === 0);
      assert.equal(f.form.querySelector('[data-complimentary-benefits]').hidden, Number(space.dataset.price) !== 0);
      if (Number(space.dataset.price) === 249.5) assert.match(f.form.querySelector('[data-discount-savings]').textContent, /£299\.40 including VAT on your space\./);
      matrixCases++;
    }
    assert.equal(spaces.at(-1).checked, true);
  }
});

test("commercial applicants submit either free space with zero finance or full paid-extra requirements", () => {
  for (const spaceName of ["COBSEO Charity - Single - Free", "Non COBSEO Charity - Single - Free"]) {
    for (const method of ["Bank transfer", "Stripe"]) for (const extra of [false, true]) {
      const f = complete(fixture("exhibitor-application.html"));
      set(f, "organisation-category", "Employer - Automotive Sector");
      set(f, f.form.querySelectorAll('[name="exhibitor-space"]').find(node => node.value === spaceName), true);
      set(f, "planned-count", "2");
      set(f, f.form.querySelectorAll('[name="power-required"]').find(node => node.value === "No"), true);
      if (extra) { set(f, "power-required-yes", true); set(f, "power-count", "1"); }
      complete(f);
      if (extra) set(f, "payment-method", method);
      f.form.requestSubmit();
      assert.equal(f.document.posts.length, 1, spaceName + " / " + method + " / extras=" + extra);
      assert.equal(payload(f)[fieldName(f,"Exhibitor_Space_Selections__c")], spaceName);
      assert.equal(payload(f)[fieldName(f,"Listed_Price_Total__c")], extra ? "100" : "0");
      assert.equal(payload(f)[fieldName(f,"Payment_Method__c")], extra ? method : undefined);
      assert.equal(f.get("billing").hidden, !extra);
      matrixCases++;
    }
  }
});

test("complimentary benefits remain selected across organisation changes while paid extras remain chargeable", () => {
  const f = complete(fixture("exhibitor-application.html"));
  const benefits = f.form.querySelector("[data-complimentary-benefits]");
  assert.equal(benefits.hidden, true);
  set(f, "organisation-category", "Charity - member of Cobseo");
  set(f, f.form.querySelectorAll('[name="exhibitor-space"]').find(node => node.value === "COBSEO Charity - Single - Free"), true);
  set(f, "planned-count", "3");
  set(f, "power-required-yes", true);
  set(f, "power-count", "1");
  assert.equal(benefits.hidden, false);
  assert.match(benefits.textContent, /one 6ft trestle table, one chair and two staff places/);
  assert.equal(f.form.querySelector('[data-sf-field="Listed_Price_Total__c"]').value, "100");
  assert.match(f.form.querySelector("[data-estimate]").textContent, /£100.00/);
  set(f, "organisation-category", "Employer - Automotive Sector");
  assert.equal(benefits.hidden, false);
  assert.match(benefits.textContent, /- worth £499 \+ VAT/);
  assert.equal(f.form.querySelector('[data-sf-field="Listed_Price_Total__c"]').value, "150", "Only the category-based power rate changes");
  assert.equal(f.form.querySelector('[name="exhibitor-space"]:checked').value, "COBSEO Charity - Single - Free");
});

test("discount savings follow the selected space independently of the category-based power reduction", () => {
  const f = complete(fixture("exhibitor-application.html"));
  const savings = f.form.querySelector("[data-discount-savings]");
  const selectSpace = value => set(f, f.form.querySelectorAll('[name="exhibitor-space"]').find(node => node.value === value), true);
  assert.equal(savings.hidden, true);
  set(f, "organisation-category", "Employer - Blue Light & NHS");
  selectSpace("Blue Light - Single - £249.50 + VAT");
  set(f, "power-required-yes", true); set(f, "power-count", "2");
  assert.equal(savings.hidden, false);
  assert.match(savings.textContent, /50% discount applied: you save £419\.40 including VAT on your space and power sockets\./);
  set(f, f.form.querySelectorAll('[name="power-required"]').find(node => node.value === "No"), true);
  assert.match(savings.textContent, /save £299\.40 including VAT/); assert(!savings.textContent.includes("socket"));
  set(f, "organisation-category", "Local Government or LG related");
  assert.equal(savings.hidden, false);
  assert.match(savings.textContent, /save £299\.40 including VAT on your space\./);
  selectSpace("Local Government Authority - Single - £249.50 + VAT");
  assert.match(savings.textContent, /save £299\.40 including VAT/);
  set(f, "organisation-category", "Charity - member of Cobseo");
  selectSpace("COBSEO Charity - Single - Free");
  assert.equal(savings.hidden, true, "A free allocation must not invent a 50% saving");
  set(f, "power-required-yes", true); set(f, "power-count", "3");
  assert.match(savings.textContent, /save £180\.00 including VAT on power sockets\./);
  set(f, "organisation-category", "Employer - Automotive Sector");
  selectSpace("Any other business - Single - £499 + VAT");
  assert.equal(savings.hidden, true); assert.equal(savings.textContent, "");
});

test("logo submission keeps identity and booking reference without a declaration or checkbox", () => {
  const f = complete(fixture("logo-upload.html"));
  assert.equal(f.form.querySelector('[data-sf-field="Declaration_Name__c"]'), null);
  assert.equal(f.form.querySelector('[data-sf-field="Declaration_Date__c"]'), null);
  assert.equal(f.form.querySelector('[type="checkbox"]'), null);
  f.form.requestSubmit();
  assert.equal(f.document.posts.length, 1);
  assert.match(payload(f)[fieldName(f, "Target_Booking_Reference__c")], /^NTE-/);
  assert(payload(f).company && payload(f).first_name && payload(f).last_name && payload(f).email);
});

test("volunteer conduct: closed and partially scrolled readers cannot unlock or submit", () => {
  const f = complete(fixture("volunteer-application.html"), {conduct:false});
  const box = f.get("volunteer-conduct-acknowledgement");
  const reader = f.form.querySelector("[data-conduct-reader]");
  reader.clientHeight = 0; reader.scrollHeight = 0; reader.scrollTop = 0;
  reader.dispatchEvent(new FixtureEvent("scroll"));
  f.window.dispatchEvent(new FixtureEvent("resize"));
  assert.equal(box.disabled, true);
  f.form.requestSubmit(); assert.equal(f.document.posts.length, 0);
  assert.equal(f.document.activeElement, reader);
  readConduct(f, 799 - 2); assert.equal(box.disabled, true);
  f.form.requestSubmit(); assert.equal(f.document.posts.length, 0);
});
test("volunteer conduct: reaching the end unlocks without auto-ticking; explicit acknowledgement is required", () => {
  const f = complete(fixture("volunteer-application.html"), {conduct:false});
  const box = f.get("volunteer-conduct-acknowledgement");
  readConduct(f, 799.5);
  assert.equal(box.disabled, false); assert.equal(box.checked, false);
  f.form.requestSubmit(); assert.equal(f.document.posts.length, 0);
  assert.equal(f.document.activeElement, box);
  set(f, box, true); f.form.requestSubmit();
  assert.equal(f.document.posts.length, 1);
  assert.equal(payload(f)[fieldName(f, "Volunteer_Code_Consent__c")], "1");
  assert.equal(payload(f)[fieldName(f, "Volunteer_Code_Version__c")], "September 2026");
  assert.equal(payload(f)[fieldName(f, "Volunteer_Form_Version__c")], "volunteer-application-v3");
});
test("volunteer conduct: prefilled acknowledgement and hidden version cannot bypass reading", () => {
  const f = complete(fixture("volunteer-application.html"), {conduct:false});
  const box = f.get("volunteer-conduct-acknowledgement");
  box.disabled = false; box.checked = true;
  const version = f.form.querySelector("[data-conduct-version]"); version.disabled = false; version.value = "September 2026";
  f.form.requestSubmit(); assert.equal(f.document.posts.length, 0);
  assert.equal(box.checked, false); assert.equal(box.disabled, true);
  assert.equal(version.value, ""); assert.equal(version.disabled, true);
});
test("volunteer conduct: reopening and restoring a completed reader preserve an explicit acknowledgement", () => {
  const f = complete(fixture("volunteer-application.html"));
  const details = f.form.querySelector("[data-conduct-document]");
  details.open = false; details.dispatchEvent(new FixtureEvent("toggle"));
  details.open = true; details.dispatchEvent(new FixtureEvent("toggle"));
  f.window.dispatchEvent(new FixtureEvent("pageshow", {persisted:true}));
  assert.equal(f.get("volunteer-conduct-acknowledgement").checked, true);
  f.form.requestSubmit(); assert.equal(f.document.posts.length, 1);
});
test("volunteer conduct: fresh page restoration clears browser-restored ticks", () => {
  const f = complete(fixture("volunteer-application.html"), {conduct:false});
  f.get("volunteer-conduct-acknowledgement").checked = true;
  f.window.dispatchEvent(new FixtureEvent("pageshow", {persisted:false}));
  assert.equal(f.get("volunteer-conduct-acknowledgement").checked, false);
  f.form.requestSubmit(); assert.equal(f.document.posts.length, 0);
});
test("volunteer conduct: unticking and form reset remove acknowledgement evidence", () => {
  const f = complete(fixture("volunteer-application.html"));
  set(f, "volunteer-conduct-acknowledgement", false);
  const version = f.form.querySelector("[data-conduct-version]");
  assert.equal(version.disabled, true); assert.equal(version.value, "");
  f.form.requestSubmit(); assert.equal(f.document.posts.length, 0);
  set(f, "volunteer-conduct-acknowledgement", true);
  f.form.dispatchEvent(new FixtureEvent("reset"));
  assert.equal(f.get("volunteer-conduct-acknowledgement").checked, false);
  assert.equal(f.get("volunteer-conduct-acknowledgement").disabled, true);
  assert.equal(f.form.querySelector("[data-conduct-document]").open, false);
  assert.equal(f.form.querySelector("[data-conduct-reader]").scrollTop, 0);
  f.form.requestSubmit(); assert.equal(f.document.posts.length, 0);
});
test("volunteer conduct: a fully visible document still requires opening and a separate tick", () => {
  const f = complete(fixture("volunteer-application.html"), {conduct:false});
  const reader = f.form.querySelector("[data-conduct-reader]");
  reader.clientHeight = 400; reader.scrollHeight = 400; reader.scrollTop = 0;
  f.window.dispatchEvent(new FixtureEvent("resize"));
  assert.equal(f.get("volunteer-conduct-acknowledgement").disabled, true);
  const details = f.form.querySelector("[data-conduct-document]");
  details.open = true; details.dispatchEvent(new FixtureEvent("toggle"));
  assert.equal(f.get("volunteer-conduct-acknowledgement").disabled, false);
  assert.equal(f.get("volunteer-conduct-acknowledgement").checked, false);
  assert.equal(f.document.activeElement, reader);
});
test("volunteer conduct: submission restores the actual document version", () => {
  const f = complete(fixture("volunteer-application.html"));
  const version = f.form.querySelector("[data-conduct-version]"); version.disabled = true; version.value = "Outdated";
  f.form.requestSubmit(); assert.equal(f.document.posts.length, 1);
  assert.equal(payload(f)[fieldName(f, "Volunteer_Code_Version__c")], "September 2026");
});


for (const filename of ['exhibitor-application.html','partner-sponsor-application.html']) {
  for (const method of ['Stripe','Bank transfer']) for (const invoice of ['Yes','No']) {
    test(filename + ': ' + method + ' and invoice ' + invoice + ' are independent', () => {
      const f=complete(fixture(filename));
      set(f,f.form.querySelector('[data-sf-field="Payment_Method__c"]'),method);
      set(f,f.form.querySelector('[data-sf-field="Invoice_Requested__c"]'),invoice);
      set(f,f.form.querySelector('[data-sf-field="Quote_Required_for_PO__c"]'),'Yes');
      f.form.requestSubmit();
      assert.equal(f.document.posts.length,1,f.form.querySelector('[data-form-status]').textContent);
      assert.equal(payload(f)[fieldName(f,'Payment_Method__c')],method);
      assert.equal(payload(f)[fieldName(f,'Invoice_Requested__c')],invoice);
      assert.equal(payload(f)[fieldName(f,'Quote_Required_for_PO__c')],'Yes');
      const choices=f.form.querySelectorAll('select').filter(c=>['Payment_Method__c','Invoice_Requested__c','Quote_Required_for_PO__c'].includes(c.dataset.sfField));
      assert.equal(choices[0].dataset.sfField,'Payment_Method__c');
    });
  }
}
test('free exhibitor hides and omits finance; paid extras restore all independent choices', () => {
  const f=complete(fixture('exhibitor-application.html'));
  set(f,'organisation-category','Charity - member of Cobseo');
  set(f,f.form.querySelectorAll('[name="exhibitor-space"]').find(c=>c.value==='COBSEO Charity - Single - Free'),true);
  set(f,'planned-count','2');
  set(f,f.form.querySelectorAll('[name="power-required"]').find(c=>c.value==='No'),true);
  const billing=f.document.getElementById('billing');
  assert.equal(billing.hidden,true);
  for (const control of billing.querySelectorAll('input, select, textarea')) assert.equal(control.disabled,true);
  const quote=f.document.getElementById('quote-for-po'); quote.value='Yes';
  const invoice=f.document.getElementById('invoice-requested'); invoice.value='Yes';
  set(f,'power-required-yes',true); set(f,'power-count','1');
  assert.equal(billing.hidden,false); assert.equal(quote.required,true); assert.equal(invoice.required,true);
  set(f,'payment-method','Stripe'); set(f,'invoice-requested','Yes');
  set(f,f.form.querySelectorAll('[name="power-required"]').find(c=>c.value==='No'),true);
  assert.equal(billing.hidden,true);
  set(f,'planned-count','3'); assert.equal(billing.hidden,false,'A paid staff extra enables all requirements.');
  set(f,'planned-count','2'); assert.equal(billing.hidden,true);
  f.form.requestSubmit(); assert.equal(f.document.posts.length,1);
  for (const api of ['Invoice_Requested__c','Quote_Required_for_PO__c','Payment_Method__c','Purchase_Order__c','Supplier_Agreement_Required__c','Invoice_Additional_Information__c']) assert.equal(payload(f)[fieldName(f,api)],undefined,api);
  assert.equal(payload(f)[fieldName(f,'Listed_Price_Total__c')],'0');
});

if (process.env.NTE_FORM_SCHEMA) fs.writeFileSync(path.resolve(process.env.NTE_FORM_SCHEMA), JSON.stringify(filenames.map(filename => { const f=fixture(filename); return {filename, formKind:f.form.dataset.formKind || null, webFormType:f.form.querySelector('[data-sf-field="Web_Form_Type__c"]').value, leadSource:f.form.dataset.leadSource, controls:f.form.querySelectorAll("input, select, textarea").filter(control=>!control.dataset.formHoneypot).map(control=>({id:control.id || null, type:control.type || control.tagName.toLowerCase(), salesforceField:control.dataset.sfField || null, required:control.required, requiredWhenVisible:control.hasAttribute("data-required-when-visible"), maxlength:control.maxLength, min:control.min || null,max:control.max || null,pattern:control.pattern || null,conditionalSource:control.closest("[data-conditional-for]")?.dataset.conditionalFor || null, options:control.tagName === "SELECT" ? control.querySelectorAll("option").map(option=>option.value) : undefined}))}; }),null,2)+"\n");

console.log(`Form engine stress: ${passed} checks passed; ${failed} failed; ${matrixCases} catalogue/boundary combinations.`);
if (process.env.NTE_FORM_RESULTS) fs.writeFileSync(path.resolve(process.env.NTE_FORM_RESULTS), JSON.stringify({sourceRoot:root, generatedAt:new Date().toISOString(), passed,failed,matrixCases,results},null,2)+"\n");
if (failed) process.exitCode = 1;
