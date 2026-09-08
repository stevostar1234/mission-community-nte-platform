"use strict";

const assert = require("assert");
const fs = require("fs");
const path = require("path");
const root = path.resolve(__dirname, "..");
const logo = fs.readFileSync(path.join(root, "assets", "mission-motorsport-logo.png"));

// The file extension drives its hosted MIME type; a renamed WebP passes browser
// previews but can be corrupted by email image proxies.
assert.strictEqual(logo.subarray(0, 8).toString("hex"), "89504e470d0a1a0a",
  "the Mission Motorsport email logo must contain real PNG bytes");
assert.strictEqual(logo.toString("ascii", 12, 16), "IHDR", "the logo must have a PNG image header");
assert.strictEqual(logo.readUInt32BE(16), 1500, "preserve the official artwork width");
assert.strictEqual(logo.readUInt32BE(20), 767, "preserve the official artwork height");
assert.strictEqual(logo[24], 8, "the email logo must use standard 8-bit channels");
assert.strictEqual(logo[25], 2, "the white-header email logo must use opaque RGB pixels");
assert.strictEqual(logo[28], 0, "the email logo must use a non-interlaced PNG");

for (const filename of ["volunteer-application-applicant-confirmation.html", "volunteer-application-internal-notification.html"]) {
  const html = fs.readFileSync(path.join(root, "email-templates", "source", filename), "utf8");
  assert(html.includes('assets/mission-motorsport-logo.png?v=20260907-png"'),
    `${filename}: use the corrected logo version to avoid an older cached image`);
}
