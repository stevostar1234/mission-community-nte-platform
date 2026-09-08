"use strict";

const gbp = new Intl.NumberFormat("en-GB", {style: "currency", currency: "GBP"});

// Classic Salesforce currency merge fields include their currency symbol.
function currencyPreview(value) {
  const amount = Number(value);
  if (!Number.isFinite(amount)) throw new Error(`Invalid currency preview value: ${value}`);
  return gbp.format(amount);
}

function decodeEntities(text) {
  const entities = {amp: "&", lt: "<", gt: ">", quot: '"', apos: "'", nbsp: " ", pound: "£", bull: "•", middot: "·", times: "×", ndash: "–", mdash: "—", rsquo: "’", lsquo: "‘", rdquo: "”", ldquo: "“"};
  return text.replace(/&(#x[0-9a-f]+|#\d+|[a-z]+);/gi, (entity, name) => {
    if (name.startsWith("#")) {
      const hex = name[1].toLowerCase() === "x";
      const code = parseInt(name.slice(hex ? 2 : 1), hex ? 16 : 10);
      return code > 0 && code <= 0x10ffff ? String.fromCodePoint(code) : entity;
    }
    return Object.prototype.hasOwnProperty.call(entities, name) ? entities[name] : entity;
  });
}

// Build the text alternative from the maintained email, preserving its rows,
// paragraphs and usable links without exposing CSS, the title or hidden preheader.
function plainTextFromHtml(html) {
  return decodeEntities(html
    .replace(/<(head|style|script)\b[^>]*>[\s\S]*?<\/\1>/gi, "")
    .replace(/<!--NTE_TOKEN:(\{NTE_[A-Z_]+\})-->/g, "$1")
    .replace(/<!--[^]*?-->/g, "")
    .replace(/<div\b[^>]*class=["']preheader["'][^>]*>[\s\S]*?<\/div>/gi, "")
    .replace(/<a\b[^>]*href=(["'])(.*?)\1[^>]*>([\s\S]*?)<\/a>/gi, (_, quote, href, label) =>
      label.replace(/<[^>]+>/g, "").trim() ? `${label} (${href})` : "")
    .replace(/<li\b[^>]*>/gi, "\n• ")
    .replace(/[\r\n]+[ \t]*(?=<br\s*\/?>)/gi, "")
    .replace(/<br\s*\/?>|<\/li>/gi, "\n")
    .replace(/<\/(?:p|h[1-6]|div|ul|ol|table)>/gi, "\n\n")
    .replace(/<\/tr>/gi, "\n")
    .replace(/<\/t[dh]>/gi, "  ")
    .replace(/<[^>]+>/g, ""))
    .replace(/\r\n?/g, "\n")
    .replace(/[^\S\n]+/g, " ")
    .replace(/ *\n */g, "\n")
    .replace(/\n{3,}/g, "\n\n")
    .trim();
}

module.exports = {currencyPreview, plainTextFromHtml};
