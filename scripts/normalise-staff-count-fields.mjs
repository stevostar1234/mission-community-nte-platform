import { writeFileSync } from "node:fs";
import { resolve } from "node:path";

const metadataNamespace = "http://soap.sforce.com/2006/04/metadata";
const fieldsDirectory = resolve("force-app/main/default/objects/Lead/fields");

function picklistField({ apiName, label, description, values }) {
  const valueXml = values.map((value) => [
    "            <value>",
    `                <fullName>${value}</fullName>`,
    "                <default>false</default>",
    `                <label>${value}</label>`,
    "            </value>"
  ].join("\n")).join("\n");

  return [
    '<?xml version="1.0" encoding="UTF-8"?>',
    `<CustomField xmlns="${metadataNamespace}">`,
    `    <fullName>${apiName}</fullName>`,
    `    <description>${description}</description>`,
    `    <label>${label}</label>`,
    "    <required>false</required>",
    "    <trackFeedHistory>false</trackFeedHistory>",
    "    <type>Picklist</type>",
    "    <valueSet>",
    "        <restricted>true</restricted>",
    "        <valueSetDefinition>",
    "            <sorted>false</sorted>",
    valueXml,
    "        </valueSetDefinition>",
    "    </valueSet>",
    "</CustomField>",
    ""
  ].join("\n");
}

const oneToNinetyNine = Array.from({ length: 99 }, (_, index) => String(index + 1));
const zeroToNinetyNine = Array.from({ length: 100 }, (_, index) => String(index));

writeFileSync(
  resolve(fieldsDirectory, "Planned_Exhibitor_Count__c.field-meta.xml"),
  picklistField({
    apiName: "Planned_Exhibitor_Count__c",
    label: "Planned Exhibitor Count",
    description: "Total people initially planned for the NTE booking. Accepts the public form range from 1 to 99.",
    values: [...oneToNinetyNine, "More than 9"]
  })
);

writeFileSync(
  resolve(fieldsDirectory, "Additional_Staff_Count__c.field-meta.xml"),
  picklistField({
    apiName: "Additional_Staff_Count__c",
    label: "Additional Staff Count",
    description: "Initial chargeable staff above the package allowance. Accepts calculated values from 0 to 99.",
    values: zeroToNinetyNine
  })
);

console.log("Expanded the reused NTE staff-count picklists to match the public form ranges.");
