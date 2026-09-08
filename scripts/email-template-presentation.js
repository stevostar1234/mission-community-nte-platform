"use strict";

const {plainTextFromHtml} = require("./email-formatting");

// These authoring attributes compile to native Salesforce conditions. Field
// values stay ordinary merge fields, preserving native escaping and line breaks.
const fieldPattern = /\{!((?:Lead|Contact|Opportunity)\.[A-Za-z0-9_]+)\}/g;
const tokenPattern = /\{![\s\S]*?\}/g;
const hasValue = value => value != null && String(value).trim() !== "";
const literal = value => `"${value.replace(/\\/g, "\\\\").replace(/"/g, '\\"')}"`;
const blank = field => `ISBLANK(${field})`;
const allBlank = fields => fields.length === 1 ? blank(fields[0]) : `AND(${fields.map(blank).join(",")})`;
const nativeIf = (condition, yes, no) => `{!IF(${condition},${literal(yes)},${literal(no)})}`;

function presentation(source, readValue) {
  const preview = typeof readValue === "function";
  const joinValues = html => html.replace(/<td([^>]*?)\sdata-nte-join="([^"]+)"([^>]*)>([\s\S]*?)<\/td>/g,
    (whole, before, separator, after, body) => {
      const fields = [...body.matchAll(fieldPattern)].map(match => match[1]);
      if (fields.length < 2 || body !== fields.map(field => `{!${field}}`).join(separator)) {
        throw new Error("An email joined cell must contain only merge fields and its exact separator.");
      }
      let joined;
      if (preview) {
        joined = fields.filter(field => hasValue(readValue(field))).map(field => `{!${field}}`).join(separator);
      } else {
        joined = fields.map((field, index) => (index === 0 ? "" :
          nativeIf(`OR(${blank(field)},${allBlank(fields.slice(0, index))})`, "", separator)) + `{!${field}}`).join("");
      }
      return `<td${before}${after}>${joined}</td>`;
    });

  let result = source.replace(/<tr([^>]*?)\sdata-nte-optional="true"([^>]*)>([\s\S]*?)<\/tr>/g,
    (whole, before, after, body) => {
      const fields = [...new Set([...body.matchAll(fieldPattern)].map(match => match[1]))];
      if (!fields.length) throw new Error("An optional email row must contain at least one merge field.");
      const row = joinValues(`<tr${before}${after}>${body}</tr>`);
      if (preview) return fields.some(field => hasValue(readValue(field))) ? row : "";
      // Hide fixed row markup only. Supplied values are never put inside formula
      // literals or reinterpreted as template syntax.
      const empty = allBlank(fields);
      let copiedThrough = 0;
      let conditional = "";
      for (const token of row.matchAll(tokenPattern)) {
        if (token.index > copiedThrough) conditional += nativeIf(empty, "", row.slice(copiedThrough, token.index));
        conditional += token[0];
        copiedThrough = token.index + token[0].length;
      }
      if (copiedThrough < row.length) conditional += nativeIf(empty, "", row.slice(copiedThrough));
      return conditional;
    });
  result = joinValues(result);
  result = result.replace(/<!--NTE_GREETING:((?:Lead|Contact)\.FirstName)-->/g, (_, field) => {
    if (preview) return hasValue(readValue(field)) ? `Hi {!${field}},` : "Hello,";
    return nativeIf(blank(field), "Hello,", "Hi ") + `{!${field}}` + nativeIf(blank(field), "", ",");
  });
  if (/data-nte-(?:optional|join)|<!--NTE_GREETING:/.test(result)) {
    throw new Error("Invalid email presentation annotation.");
  }
  return result;
}

function compileEmailPresentation(source) { return presentation(source); }
function previewEmailPresentation(source, readValue) {
  if (typeof readValue !== "function") throw new Error("Email previews require a field-value reader.");
  return presentation(source, readValue);
}

function nativeEmailTextFromHtml(html) {
  return plainTextFromHtml(html).replace(tokenPattern, token => {
    // Salesforce drops formula results with literal newlines. Keep optional row
    // breaks as ordinary text; an omitted row can leave harmless blank spacing.
    const lineBreak = token.match(/^\{!IF\([^\r\n]*,"","(\n+)"\)\}$/);
    if (lineBreak) return lineBreak[1];
    if (/[\r\n]/.test(token)) throw new Error("Native email formulas cannot contain literal line breaks.");
    return token;
  });
}

module.exports = {compileEmailPresentation, previewEmailPresentation, nativeEmailTextFromHtml};
