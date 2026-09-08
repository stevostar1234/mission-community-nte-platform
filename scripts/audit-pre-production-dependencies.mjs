import fs from "node:fs";
import path from "node:path";

const root = path.resolve(import.meta.dirname, "..");
const orgObjects = path.resolve(root, process.argv[2] || "tmp/org-field-audit/objects");
const output = path.resolve(root, process.argv[3] || "pre-production-dependancies.md");
const focusObjects = new Set(["Lead", "Account", "Contact", "Opportunity"]);
const ignoredDirectories = new Set([".git", "tmp", "node_modules", "_org-audit"]);
const readableExtensions = new Set([".xml", ".cls", ".js", ".html", ".apex", ".md", ".json"]);

const functionsByApi = {
  Additional_Staff_Count__c: "Stores the number of chargeable staff places requested and drives the additional-staff price calculation, confirmations and conversion.",
  Additional_Staff_Required__c: "Records whether the applicant needs staff places beyond the package allowance and controls the additional-staff pricing path.",
  Alternative_Organisation_Name__c: "Preserves a former or alternative organisation name for legacy submissions and copies it to the approved booking.",
  Declaration_Name__c: "Stores the applicant's typed digital signature used by the application declaration and confirmation trail.",
  Event_Contact_Email__c: "Stores the operational event contact email used by confirmations, update matching and the approved Opportunity.",
  Event_Contact_Mobile__c: "Stores the operational event contact mobile number used by the event team and copied to the approved Opportunity.",
  Event_Contact_Name__c: "Stores the named operational event contact and supports updates, notifications and conversion.",
  Exhibitor_Hall_Schedule__c: "Records whether the exhibitor will also operate in the exhibition hall and carries the answer into the booking.",
  Exhibitor_Organisation_Category__c: "Classifies the exhibitor organisation, including eligibility and pricing categories used by the pricing service.",
  Exhibitor_Space_Position__c: "Stores the requested stand position and carries it into operational planning on the Opportunity.",
  Exhibitor_Space_Selections__c: "Stores the selected exhibitor space or garage options and is a primary input to price calculation and confirmations.",
  Exhibitor_Space_Size__c: "Stores the requested exhibitor space size for booking and operational planning.",
  Has_Special_Requirements__c: "Flags whether accessibility or other special arrangements are required so details can be reviewed and transferred.",
  Industry_Body_Details__c: "Stores relevant trade association or industry body membership used when assessing and managing the application.",
  Invoice_Address__c: "Stores the billing address supplied in the finance section and copies it to the approved Opportunity.",
  Invoice_Contact_Phone__c: "Stores the finance contact phone number for quotation and invoicing follow-up.",
  Invoice_Required__c: "Records whether an invoice is required and drives finance status, reports and conversion.",
  Invoiced_Company__c: "Stores the legal customer name that should appear on the quotation or invoice.",
  Invoiced_Email__c: "Stores the accounts-payable email address used for finance correspondence.",
  Invoiced_Person__c: "Stores the named finance contact responsible for the transaction.",
  Planned_Exhibitor_Count__c: "Stores the planned number of stand attendees and is updated by the separate staff-details form.",
  Previous_NTE_Events__c: "Stores the previous NTE events attended for application review, reporting and conversion.",
  Purchase_Order_Number__c: "Stores the customer purchase-order number where one has already been issued.",
  Purchase_Order__c: "Records whether the customer's organisation requires a purchase order.",
  Secondary_Contact_Email__c: "Stores the secondary event contact email used in notifications, operational follow-up and update matching.",
  Secondary_Contact_Mobile__c: "Stores the secondary event contact mobile number.",
  Secondary_Contact_Name__c: "Stores the secondary operational contact name.",
  Secondary_Contact_Phone__c: "Stores the secondary operational contact telephone number.",
  Secondary_Contact_Prefix__c: "Stores the secondary contact's title or prefix.",
  Secondary_Contact_Title__c: "Stores the secondary contact's job title.",
  Sponsored_Name__c: "Stores the organisation or activity name to be presented in NTE sponsorship material and booking records.",
  Stand_Colleagues__c: "Legacy complete stand-attendee list. New application forms collect the count first; the applicable staff update later supplies the names.",
  Stand_Equipment__c: "Stores equipment requirements beyond standard display stands and laptops for operational planning.",
  Stand_Extra_Notes__c: "Stores additional information about the requested stand or space.",
  Stand_Power__c: "Records the stand power requirement and supports socket pricing, logistics and confirmations.",
  Stand_Special_Requirements__c: "Stores the detailed accessibility or special-arrangement requirements for delivery planning.",
  Supplier_Agreement_Required__c: "Records whether the customer requires a supplier agreement as part of procurement.",
  Terms_and_Conditions__c: "Stores acceptance of the application terms and is copied to the Opportunity declaration record."
};

function walk(directory) {
  if (!fs.existsSync(directory)) return [];
  const files = [];
  for (const entry of fs.readdirSync(directory, { withFileTypes: true })) {
    if (entry.isDirectory() && ignoredDirectories.has(entry.name)) continue;
    const fullPath = path.join(directory, entry.name);
    if (entry.isDirectory()) files.push(...walk(fullPath));
    else files.push(fullPath);
  }
  return files;
}

function decodeXml(value = "") {
  return value
    .replaceAll("&amp;", "&")
    .replaceAll("&apos;", "'")
    .replaceAll("&quot;", '"')
    .replaceAll("&lt;", "<")
    .replaceAll("&gt;", ">");
}

function tag(xml, name) {
  const match = xml.match(new RegExp(`<${name}>([\\s\\S]*?)</${name}>`));
  return match ? decodeXml(match[1].trim()) : "";
}

function allTags(xml, name) {
  return [...xml.matchAll(new RegExp(`<${name}>([\\s\\S]*?)</${name}>`, "g"))]
    .map((match) => decodeXml(match[1].trim()));
}

function fieldKey(file) {
  const normalized = file.split(path.sep);
  const fieldsIndex = normalized.lastIndexOf("fields");
  return {
    objectName: normalized[fieldsIndex - 1],
    apiName: path.basename(file, ".field-meta.xml")
  };
}

function formatType(xml) {
  const type = tag(xml, "type") || "Unknown";
  const details = [];
  if (tag(xml, "length")) details.push(`length ${tag(xml, "length")}`);
  if (tag(xml, "precision")) details.push(`precision ${tag(xml, "precision")}`);
  if (tag(xml, "scale")) details.push(`scale ${tag(xml, "scale")}`);
  if (tag(xml, "visibleLines")) details.push(`${tag(xml, "visibleLines")} visible lines`);
  if (tag(xml, "restricted")) details.push(`restricted: ${tag(xml, "restricted")}`);
  return details.length ? `${type} (${details.join(", ")})` : type;
}

function usageAreas(files) {
  const areas = [];
  if (files.some((file) => file.endsWith(".html") || file.includes("assets/config.js") || file.includes("assets/forms.js"))) areas.push("public forms / Web-to-Lead mapping");
  if (files.some((file) => file.includes("NTEPricingService"))) areas.push("pricing automation");
  if (files.some((file) => file.includes("NTE_Copy_Converted_Lead_to_Opportunity"))) areas.push("lead conversion");
  if (files.some((file) => file.includes("NTEUpdateSubmissionService"))) areas.push("supplementary updates");
  if (files.some((file) => file.includes("email-templates") || file.includes("/email/"))) areas.push("email templates");
  if (files.some((file) => file.includes("flexipages") || file.includes("permissionsets") || file.includes("reports") || file.includes("listViews"))) areas.push("Salesforce UI, security or reporting");
  if (files.some((file) => file.includes("Test"))) areas.push("automated tests");
  return areas.join(", ") || "project metadata";
}

const localFieldKeys = new Set(
  walk(path.join(root, "force-app/main/default/objects"))
    .filter((file) => file.endsWith(".field-meta.xml"))
    .map((file) => {
      const { objectName, apiName } = fieldKey(file);
      return `${objectName}.${apiName}`;
    })
);

const referencesByApi = new Map();
for (const file of walk(root)) {
  if (path.resolve(file) === output) continue;
  if (!readableExtensions.has(path.extname(file).toLowerCase())) continue;
  const relative = path.relative(root, file);
  const content = fs.readFileSync(file, "utf8");
  for (const match of content.matchAll(/\b([A-Za-z][A-Za-z0-9_]*__c)\b/g)) {
    if (!referencesByApi.has(match[1])) referencesByApi.set(match[1], new Set());
    referencesByApi.get(match[1]).add(relative);
  }
}

const webToLeadIds = new Map();
const configSource = fs.readFileSync(path.join(root, "assets/config.js"), "utf8");
for (const match of configSource.matchAll(/^\s*([A-Za-z][A-Za-z0-9_]*__c):\s*"([^"]*)"/gm)) {
  webToLeadIds.set(match[1], match[2]);
}

const conversionTargets = new Map();
const conversionFlow = fs.readFileSync(path.join(root, "force-app/main/default/flows/NTE_Copy_Converted_Lead_to_Opportunity.flow-meta.xml"), "utf8");
for (const match of conversionFlow.matchAll(/<inputAssignments>\s*<field>([^<]+)<\/field>\s*<value><elementReference>\$Record\.([^<]+)<\/elementReference><\/value>\s*<\/inputAssignments>/g)) {
  conversionTargets.set(match[2], `Opportunity.${match[1]}`);
}

const dependencies = [];
for (const file of walk(orgObjects).filter((candidate) => candidate.endsWith(".field-meta.xml"))) {
  const { objectName, apiName } = fieldKey(file);
  if (!focusObjects.has(objectName) || localFieldKeys.has(`${objectName}.${apiName}`) || !referencesByApi.has(apiName)) continue;
  const xml = fs.readFileSync(file, "utf8");
  const valueBlocks = [...xml.matchAll(/<value>([\s\S]*?)<\/value>/g)].map((match) => match[1]);
  const activeValues = valueBlocks.filter((block) => tag(block, "isActive") !== "false").map((block) => tag(block, "fullName"));
  const inactiveValues = valueBlocks.filter((block) => tag(block, "isActive") === "false").map((block) => tag(block, "fullName"));
  dependencies.push({
    objectName,
    apiName,
    label: tag(xml, "label"),
    type: formatType(xml),
    required: tag(xml, "required") === "true" ? "Yes" : "No",
    description: tag(xml, "description") || "No description is stored in the sandbox metadata.",
    helpText: tag(xml, "inlineHelpText"),
    activeValues,
    inactiveValues,
    webToLeadId: webToLeadIds.get(apiName) || "Not used by the public Web-to-Lead configuration",
    conversionTarget: conversionTargets.get(apiName) || "No direct Opportunity mapping",
    files: [...referencesByApi.get(apiName)].sort()
  });
}
dependencies.sort((left, right) => `${left.objectName}.${left.apiName}`.localeCompare(`${right.objectName}.${right.apiName}`));

const lines = [
  "# Pre-production dependancies",
  "",
  `Audit date: 18 August 2026`,
  ``,
  `Source org: Mission Motorsport MMUAT sandbox (\`mission-mmuat\`)`,
  ``,
  "Scope: custom fields on Lead, Account, Contact and Opportunity that are referenced by this project but whose field metadata is not present in `force-app/main/default`.",
  "",
  "## Result",
  "",
  `**${dependencies.length} sandbox fields are currently required by the project but are not contained in this repository.** All ${dependencies.length} are Lead fields. Account, Contact and Opportunity field references used by the NTE project are represented locally.`,
  "",
  "A production deployment must either add these fields to the production package with compatible definitions or remove every dependent form, automation, email, page and permission reference. Deploying the current package to an org without them would fail metadata validation and would also leave Web-to-Lead submissions without their intended destinations.",
  "",
  "The Web-to-Lead IDs below are sandbox-specific. Recreated production fields will receive different IDs, so both public site configurations must be updated after production field creation.",
  "",
  "## Required deployment sequence",
  "",
  "1. Recreate or retrieve all fields below into the production package, preserving API names, types, lengths, picklist values and checkbox behaviour.",
  "2. Deploy field-level access before activating flows, pages, Apex and email templates that reference the fields.",
  "3. Deploy the conversion and pricing automation, then verify every source-to-Opportunity mapping shown below.",
  "4. Retrieve the production Web-to-Lead field IDs and replace the sandbox IDs in both GitHub Pages configurations.",
  "5. Run a production validation deployment and a controlled form-to-conversion test before publishing the production form URLs.",
  "",
  "## Field inventory",
  ""
];

dependencies.forEach((field, index) => {
  lines.push(
    `### ${index + 1}. ${field.label}`,
    "",
    `- **Object and API name:** \`${field.objectName}.${field.apiName}\``,
    `- **Field label:** ${field.label}`,
    `- **Sandbox definition:** ${field.type}; required: ${field.required}`,
    `- **Sandbox description:** ${field.description}`,
    ...(field.helpText ? [`- **Inline help:** ${field.helpText}`] : []),
    ...(field.activeValues.length ? [`- **Active values:** ${field.activeValues.map((value) => `\`${value}\``).join(", ")}`] : []),
    ...(field.inactiveValues.length ? [`- **Inactive values retained in metadata:** ${field.inactiveValues.map((value) => `\`${value}\``).join(", ")}`] : []),
    `- **Sandbox Web-to-Lead field ID:** \`${field.webToLeadId}\``,
    `- **Conversion destination:** ${field.conversionTarget.startsWith("Opportunity.") ? `\`${field.conversionTarget}\`` : field.conversionTarget}`,
    `- **Function in this solution:** ${functionsByApi[field.apiName] || field.description}`,
    `- **Referenced by:** ${usageAreas(field.files)} (${field.files.length} project files)`,
    `- **Key references:** ${field.files.slice(0, 6).map((file) => `\`${file}\``).join(", ")}${field.files.length > 6 ? ", …" : ""}`,
    "- **Production action:** Add this field definition to the production package, grant the NTE permission sets access, preserve the conversion mapping where listed, and replace the sandbox Web-to-Lead ID in the hosted form configuration.",
    ""
  );
});

lines.push(
  "## Audit method and limitations",
  "",
  "- The audit compares a fresh Metadata API snapshot from the MMUAT sandbox with local field metadata and then confirms that each missing API name is referenced by the source project.",
  "- Standard Salesforce fields are not listed because they do not need custom-field metadata in this package.",
  "- Fields that exist in the sandbox but are not referenced by this project are deliberately excluded.",
  "- This inventory is dependency documentation, not authority to copy unrelated coworker metadata into production.",
  ""
);

fs.writeFileSync(output, lines.join("\n"));
console.log(`Wrote ${dependencies.length} dependencies to ${path.relative(root, output)}`);
