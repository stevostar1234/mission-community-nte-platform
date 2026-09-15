"use strict";

const fs = require("fs");
const path = require("path");
const policy = require("../config/nte-pricing.json");
const root = path.resolve(__dirname, "..");
if (!Number.isFinite(policy.vatRate) || policy.vatRate < 0 || policy.vatRate > 100) throw new Error("Invalid NTE VAT rate");
const classPath = path.join(root, "force-app/main/default/classes/NTEVat");
fs.writeFileSync(classPath + ".cls", `/** GBP VAT for net catalogue charges and saved inclusive booking amounts. */
public class NTEVat {
    public static final Decimal RATE = ${policy.vatRate};
    public static Decimal rate(Decimal savedRate) { return savedRate == null ? RATE : savedRate; }
    public static Decimal tax(Decimal net, Decimal savedRate) {
        return net == null ? null : (net * rate(savedRate) / 100).setScale(2, RoundingMode.HALF_UP);
    }
    public static Decimal gross(Decimal net, Decimal savedRate) {
        return net == null ? null : net + tax(net, savedRate);
    }
    public static Decimal taxFromGross(Decimal grossAmount, Decimal savedRate) {
        Decimal vatRate = rate(savedRate);
        return grossAmount == null ? null : (grossAmount * vatRate / (100 + vatRate)).setScale(2, RoundingMode.HALF_UP);
    }
    public static Decimal netFromGross(Decimal grossAmount, Decimal savedRate) {
        return grossAmount == null ? null : grossAmount - taxFromGross(grossAmount, savedRate);
    }
    public static Decimal bookingGross(Decimal net, Decimal savedRate, Decimal savedAmount) {
        return savedAmount == null ? gross(net, savedRate) : savedAmount;
    }
    public static Decimal bookingTax(Decimal net, Decimal savedRate, Decimal savedAmount) {
        Decimal grossAmount = bookingGross(net, savedRate, savedAmount);
        return net == null || grossAmount == null ? null : grossAmount - net;
    }
    public static Boolean consistentTotal(Decimal net, Decimal savedRate, Decimal grossAmount) {
        return grossAmount == null || gross(net, savedRate) == grossAmount || netFromGross(grossAmount, savedRate) == net;
    }
}
`);
fs.writeFileSync(classPath + ".cls-meta.xml", '<?xml version="1.0" encoding="UTF-8"?>\n<ApexClass xmlns="http://soap.sforce.com/2006/04/metadata"><apiVersion>67.0</apiVersion><status>Active</status></ApexClass>\n');
for (const [file, replacements] of [
  ["assets/forms.js", [[/var pricingVersion = "[^"]+";/, `var pricingVersion = "${policy.version}";`], [/var vatRate = [\d.]+;/, `var vatRate = ${policy.vatRate};`]]],
  ["force-app/main/default/classes/NTEPricingService.cls", [[/CATALOG_VERSION = '[^']+';/, `CATALOG_VERSION = '${policy.version}';`]]]
]) {
  const location = path.join(root, file);
  let source = fs.readFileSync(location, "utf8");
  for (const [pattern, replacement] of replacements) source = source.replace(pattern, replacement);
  fs.writeFileSync(location, source);
}
module.exports = policy;
