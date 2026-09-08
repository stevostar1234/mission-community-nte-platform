import fs from "node:fs";
import vm from "node:vm";

if (!process.argv.includes("--execute")) {
  console.error("Dry guard: pass --execute to create the six named NTE pricing/EOI test Leads.");
  process.exit(2);
}

const context = { window: {} };
vm.runInNewContext(fs.readFileSync(new URL("../../assets/config.js", import.meta.url), "utf8"), context);
const config = context.window.NTE_CONFIG;
const ids = config.customFieldIds;

function custom(target, apiName, value) {
  if (!ids[apiName]) throw new Error(`Missing Web-to-Lead mapping for ${apiName}`);
  target[ids[apiName]] = String(value);
}

function common({ company, firstName, lastName, email, formType, version, bookingReference }) {
  const fields = {
    oid: config.orgId,
    retURL: config.returnUrl,
    lead_source: "Customer Event",
    company,
    first_name: firstName,
    last_name: lastName,
    title: "NTE integration tester",
    email,
    phone: "07700 900817"
  };
  custom(fields, "Web_Form_Type__c", formType);
  custom(fields, "Form_Version__c", version);
  custom(fields, "NTE_Event_Code__c", "NTE2027");
  if (bookingReference) custom(fields, "Booking_Reference__c", bookingReference);
  return fields;
}

function exhibitor({ company, firstName, email, bookingReference, category, space, power, sockets, staff, staffCount, invoice, tamperPrices = true }) {
  const fields = common({ company, firstName, lastName: "Pricing Test", email, formType: "Exhibitor Application", version: "exhibitor-application-v3", bookingReference });
  custom(fields, "Exhibitor_Organisation_Category__c", category);
  custom(fields, "Exhibitor_Space_Selections__c", space);
  custom(fields, "Planned_Exhibitor_Count__c", staff === "Yes" ? "7" : "1");
  custom(fields, "Stand_Power__c", power);
  if (Number(sockets) > 0) custom(fields, "Power_Socket_Count__c", sockets);
  custom(fields, "Additional_Staff_Required__c", staff);
  if (Number(staffCount) > 0) custom(fields, "Additional_Staff_Count__c", staffCount);
  custom(fields, "Stand_Colleagues__c", `${firstName} Pricing Test`);
  custom(fields, "Exhibitor_Hall_Schedule__c", "Yes");
  custom(fields, "Stand_Equipment__c", "None - automated end-to-end pricing test");
  custom(fields, "Heavy_Vehicle_Required__c", "No");
  custom(fields, "Has_Special_Requirements__c", "No");
  custom(fields, "Stand_Extra_Notes__c", "NTE pricing release verification record - retain for review");
  custom(fields, "Invoice_Required__c", invoice);
  custom(fields, "Invoiced_Company__c", company);
  custom(fields, "Invoiced_Person__c", `${firstName} Pricing Test`);
  custom(fields, "Invoice_Address__c", "1 Test Way, Silverstone, NN12 8TN");
  custom(fields, "Invoiced_Email__c", email);
  custom(fields, "Purchase_Order__c", "No");
  custom(fields, "Supplier_Agreement_Required__c", "No");
  custom(fields, "Industry_Body_Details__c", "No");
  custom(fields, "Event_Discovery_Source__c", "Website");
  custom(fields, "Declaration_Name__c", `${firstName} Pricing Test`);
  custom(fields, "Terms_and_Conditions__c", "1");
  custom(fields, "Event_Contact_Name__c", `${firstName} Pricing Test`);
  custom(fields, "Event_Contact_Title__c", "NTE integration tester");
  custom(fields, "Event_Contact_Email__c", email);
  custom(fields, "Event_Contact_Mobile__c", "07700 900817");
  // Paid scenarios deliberately send incorrect client values to prove Salesforce is authoritative.
  for (const api of ["Sponsor_Package_Total__c", "Exhibitor_Space_Price__c", "Power_Socket_Unit_Price__c", "Power_Socket_Total__c", "Additional_Staff_Unit_Price__c", "Additional_Staff_Total__c", "Listed_Price_Total__c"]) custom(fields, api, tamperPrices ? "1" : "0");
  custom(fields, "Pricing_Status__c", tamperPrices ? "Review required" : "Calculated");
  custom(fields, "Pricing_Version__c", tamperPrices ? "tampered-client-test" : "NTE27-2026-09-06");
  return fields;
}

function partner({ company, firstName, email, bookingReference, packages }) {
  const fields = common({ company, firstName, lastName: "Pricing Test", email, formType: "Partner / Sponsor Application", version: "partner-sponsor-application-v5", bookingReference });
  custom(fields, "Sponsor_Package__c", packages.join(";"));
  custom(fields, "Sponsored_Name__c", `${firstName} Pricing Test`);
  custom(fields, "Invoice_Required__c", "Yes");
  custom(fields, "Quote_Required_for_PO__c", "No");
  custom(fields, "Invoiced_Company__c", company);
  custom(fields, "Invoiced_Person__c", `${firstName} Pricing Test`);
  custom(fields, "Invoice_Address__c", "2 Sponsor Avenue, Silverstone, NN12 8TN");
  custom(fields, "Invoiced_Email__c", email);
  custom(fields, "Purchase_Order__c", "No");
  custom(fields, "Exhibitor_Hall_Schedule__c", "Yes");
  custom(fields, "Stand_Power__c", "Yes");
  custom(fields, "Stand_Equipment__c", "None - automated end-to-end pricing test");
  custom(fields, "Heavy_Vehicle_Required__c", "No");
  custom(fields, "Has_Special_Requirements__c", "No");
  custom(fields, "Stand_Colleagues__c", `${firstName} Pricing Test`);
  custom(fields, "Stand_Extra_Notes__c", "NTE pricing release verification record - retain for review");
  custom(fields, "Terms_and_Conditions__c", "1");
  custom(fields, "Event_Contact_Name__c", `${firstName} Pricing Test`);
  custom(fields, "Event_Contact_Title__c", "NTE integration tester");
  custom(fields, "Event_Contact_Email__c", email);
  custom(fields, "Event_Contact_Mobile__c", "07700 900817");
  custom(fields, "Sponsor_Package_Total__c", "1");
  custom(fields, "Listed_Price_Total__c", "1");
  custom(fields, "Pricing_Status__c", "Review required");
  custom(fields, "Pricing_Version__c", "tampered-client-test");
  return fields;
}

function expressionOfInterest() {
  const fields = common({
    company: "NTE E2E Exhibitor Interest 0817",
    firstName: "Elena",
    lastName: "Interest Test",
    email: "skybasteven+nte-exhibitor-eoi-0817@gmail.com",
    formType: "Exhibitor Expression of Interest",
    version: "exhibitor-interest-v3"
  });
  fields.URL = "https://example.org";
  custom(fields, "Organisation_Type__c", "Employer - Automotive");
  custom(fields, "Exhibitor_Interest_Detail__c", "Yes");
  custom(fields, "Exhibitor_Community_Contribution__c", "Free CV workshops, LinkedIn advice and practical STEM activities for attendees.");
  custom(fields, "Preferred_Contact_Method__c", "Email");
  custom(fields, "Preferred_Contact_Time__c", "Weekday mornings");
  custom(fields, "Event_Discovery_Source__c", "National Transition Event website");
  custom(fields, "Contact_Consent__c", "1");
  return fields;
}

const scenarios = [
  ["paid exhibitor", exhibitor({
    company: "NTE E2E Paid Garage 0817", firstName: "Parker", email: "skybasteven+nte-exhibitor-paid-0817@gmail.com", bookingReference: "NTE27-E2E-EX-PAID-0817",
    category: "Employer - Automotive Sector", space: "Single Garage - Paddock Side with power - £800 + VAT", power: "Yes", sockets: 2, staff: "Yes", staffCount: 5, invoice: "Yes"
  })],
  ["discounted exhibitor", exhibitor({
    company: "NTE E2E Local Government 0817", firstName: "Drew", email: "skybasteven+nte-exhibitor-discount-0817@gmail.com", bookingReference: "NTE27-E2E-EX-DISCOUNT-0817",
    category: "Local Government or LG related", space: "Local Government Authority - Single - £249.50 + VAT", power: "Yes", sockets: 3, staff: "Yes", staffCount: 2, invoice: "Yes"
  })],
  ["free charity exhibitor", exhibitor({
    company: "NTE E2E Free Charity 0817", firstName: "Freya", email: "skybasteven+nte-exhibitor-free-0817@gmail.com", bookingReference: "NTE27-E2E-EX-FREE-0817",
    category: "Charity - not a member of Cobseo", space: "Non COBSEO Charity - Single - Free", power: "No", sockets: 0, staff: "No", staffCount: 0, invoice: "No", tamperPrices: false
  })],
  ["multi-package partner", partner({
    company: "NTE E2E Gold Zone Partner 0817", firstName: "Morgan", email: "skybasteven+nte-partner-multi-0817@gmail.com", bookingReference: "NTE27-E2E-PS-MULTI-0817", packages: ["Gold Partner", "Zone Sponsor"]
  })],
  ["single-package sponsor", partner({
    company: "NTE E2E Wristband Sponsor 0906", firstName: "Taylor", email: "nte-partner-fixed-0906@example.invalid", bookingReference: "NTE27-E2E-PS-FIXED-0906", packages: ["Wristband Sponsor"]
  })],
  ["exhibitor expression of interest", expressionOfInterest()]
];

const selectedScenarios = process.argv.includes("--free-only") ? scenarios.filter(([name]) => name === "free charity exhibitor") : scenarios;

for (const [name, fields] of selectedScenarios) {
  const response = await fetch(config.endpoint, {
    method: "POST",
    redirect: "manual",
    headers: { "content-type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams(fields)
  });
  console.log(JSON.stringify({ name, status: response.status, location: response.headers.get("location") }));
  if (process.argv.includes("--inspect-response")) console.log((await response.text()).slice(0, 2000));
  if (![200, 302, 303].includes(response.status)) throw new Error(`${name} failed with HTTP ${response.status}`);
}
