"use strict";

const {vatRate} = require("./build-vat");
const fs = require("fs");
const path = require("path");
const {currencyPreview} = require("./email-formatting");
const {compileEmailPresentation, previewEmailPresentation, nativeEmailTextFromHtml} = require("./email-template-presentation");

const root = path.resolve(__dirname, "..");
const md = path.join(root, "force-app", "main", "default");
const ns = "http://soap.sforce.com/2006/04/metadata";

function esc(value) {
  return String(value).replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;").replace(/'/g, "&apos;").replace(/\"/g, "&quot;");
}

function write(file, body) {
  fs.mkdirSync(path.dirname(file), {recursive: true});
  fs.writeFileSync(file, body);
}

const text = (api, label, length = 255, extra = {}) => ({api, label, type: "Text", length, ...extra});
const email = (api, label) => ({api, label, type: "Email"});
const phone = (api, label) => ({api, label, type: "Phone"});
const checkbox = (api, label) => ({api, label, type: "Checkbox", defaultValue: false});
const number = (api, label, precision = 3, scale = 0) => ({api, label, type: "Number", precision, scale});
const currency = (api, label, precision = 18, scale = 2) => ({api, label, type: "Currency", precision, scale});
const formulaCurrency = (api, label, formula, description) => ({api, label, type: "Currency", precision: 18, scale: 2, formula, formulaTreatBlanksAs: "BlankAsBlank", description});
const formulaCheckbox = (api, label, formula, description) => ({api, label, type: "Checkbox", formula, formulaTreatBlanksAs: "BlankAsBlank", description});
const longtext = (api, label, length = 32768, visibleLines = 4) => ({api, label, type: "LongTextArea", length, visibleLines});
const picklist = (api, label, values) => ({api, label, type: "Picklist", values});
const multipick = (api, label, values, visibleLines = 4) => ({api, label, type: "MultiselectPicklist", values, visibleLines});
const date = (api, label) => ({api, label, type: "Date"});
const datetime = (api, label) => ({api, label, type: "DateTime"});

// Match the panel's finance predicates without exceeding native list-view filter limits.
const pricingReadyFormula = 'AND(NOT(ISBLANK(NTE_Listed_Price_Total__c)), NTE_Listed_Price_Total__c >= 0, OR(ISPICKVAL(NTE_Pricing_Status__c, "Calculated"), AND(ISBLANK(TEXT(NTE_Pricing_Status__c)), NTE_Listed_Price_Total__c > 0)))';
const baseBillableFormula = 'OR(NTE_Invoice_Required__c = "Yes", NTE_Listed_Price_Total__c > 0, NOT(NTE_Pricing_Ready__c))';
const topUpBillableFormula = 'OR(NTE_Top_Up_Invoice_Required__c, BLANKVALUE(NTE_Top_Up_Staff_Total__c, 0) > 0)';
const allPaymentsFormula = `AND(IF(${baseBillableFormula}, NTE_Payment_Received__c, OR(NTE_Free_Space_Confirmed__c, NTE_Payment_Received__c)), OR(NOT(${topUpBillableFormula}), NTE_Top_Up_Payment_Received__c))`;
const paymentDueFormula = `AND(NTE_Pricing_Ready__c, NOT(NTE_Finance_Requirements_Due__c), OR(AND(${baseBillableFormula}, NOT(ISBLANK(NTE_Approval_Email_Sent_At__c)), NOT(NTE_Payment_Received__c)), AND(${topUpBillableFormula}, NOT(ISBLANK(NTE_Top_Up_Payment_Requested_At__c)), NOT(NTE_Top_Up_Payment_Received__c))))`;
const paymentConfirmedFormula = `AND(NTE_Pricing_Ready__c, ${allPaymentsFormula})`;
const requirementsDueFormula = `OR(NOT(NTE_Pricing_Ready__c), AND(NOT(NTE_Payment_Received__c), IF(${baseBillableFormula}, ISBLANK(NTE_Approval_Email_Sent_At__c), NOT(NTE_Free_Space_Confirmed__c))), AND(${topUpBillableFormula}, ISBLANK(NTE_Top_Up_Payment_Requested_At__c), NOT(NTE_Top_Up_Payment_Received__c)))`;

function fieldXml(field) {
  const lines = [
    '<?xml version="1.0" encoding="UTF-8"?>',
    `<CustomField xmlns="${ns}">`,
    `    <fullName>${esc(field.api)}</fullName>`,
    field.caseSensitive !== undefined ? `    <caseSensitive>${field.caseSensitive}</caseSensitive>` : "",
    field.description ? `    <description>${esc(field.description)}</description>` : "",
    field.defaultValue !== undefined ? `    <defaultValue>${field.defaultValue}</defaultValue>` : "",
    field.externalId !== undefined ? `    <externalId>${field.externalId}</externalId>` : "",
    field.formula ? `    <formula>${esc(field.formula)}</formula>` : "",
    field.formulaTreatBlanksAs ? `    <formulaTreatBlanksAs>${field.formulaTreatBlanksAs}</formulaTreatBlanksAs>` : "",
    `    <label>${esc(field.label)}</label>`,
    field.length ? `    <length>${field.length}</length>` : "",
    field.precision ? `    <precision>${field.precision}</precision>` : "",
    "    <required>false</required>",
    field.scale !== undefined ? `    <scale>${field.scale}</scale>` : "",
    field.formula ? "    <trackHistory>false</trackHistory>" : "    <trackFeedHistory>false</trackFeedHistory>",
    `    <type>${field.type}</type>`,
    field.unique !== undefined ? `    <unique>${field.unique}</unique>` : "",
    field.visibleLines ? `    <visibleLines>${field.visibleLines}</visibleLines>` : ""
  ].filter(Boolean);
  if (field.values) {
    lines.push("    <valueSet>", "        <restricted>true</restricted>", "        <valueSetDefinition>", "            <sorted>false</sorted>");
    field.values.forEach((value) => {
      lines.push("            <value>", `                <fullName>${esc(value)}</fullName>`, "                <default>false</default>", `                <label>${esc(value)}</label>`, "            </value>");
    });
    (field.inactiveValues || []).forEach((value) => {
      lines.push("            <value>", `                <fullName>${esc(value)}</fullName>`, "                <default>false</default>", "                <isActive>false</isActive>", `                <label>${esc(value)}</label>`, "            </value>");
    });
    lines.push("        </valueSetDefinition>", "    </valueSet>");
  }
  lines.push("</CustomField>", "");
  return lines.join("\n");
}

const yesNo = ["Yes", "No"];
const yesNoUnknown = ["Yes", "No", "Don't know"];
const organisationTypes = [
  "Charity - COBSEO member",
  "Charity - Non COBSEO member",
  "Government Department or Agency",
  "Industry Body / Trade Association",
  "Employer - Automotive",
  "Employer - Clean Energy",
  "Employer - Blue Light Services / NHS",
  "Employer - Built Environment",
  "Employer - Manufacturing",
  "Employer - Defence and Security",
  "Employer - Financial and Professional Services",
  "Employer - Digital and Technologies",
  "Employer - Training and Education",
  "Employer - Land-based",
  "Employer - Other sector",
  // Retained for existing records and integrations; the public EOI forms show the current choices above.
  "Commercial business",
  "Charity or non-profit",
  "Government or public body",
  "Industry body or trade association",
  "Education or training provider",
  "Other"
];
const booking = text("Booking_Reference__c", "NTE Booking Reference", 80, {
  description: "Unique browser-generated reference for the original NTE application.",
  caseSensitive: false,
  externalId: true,
  unique: true
});
const targetBooking = text("Target_Booking_Reference__c", "Target NTE Booking Reference", 80, {
  description: "Exact original booking reference supplied on an NTE supplementary form.",
  caseSensitive: false,
  externalId: false,
  unique: false
});

const leadFields = [
  booking,
  targetBooking,
  text("NTE_Event_Code__c", "NTE Event Code", 20, {description: "Evergreen NTE edition code calculated in Europe/London, for example NTE27.", externalId: true, unique: false}),
  text("Form_Version__c", "NTE Form Version", 80),
  checkbox("NTE_Interest_Progressed__c", "Interest Progressed"),
  checkbox("NTE_Interest_Not_Progressed__c", "Interest Not Progressed"),
  checkbox("NTE_Application_Rejected__c", "Application Rejected"),
  date("Declaration_Date__c", "Declaration Date"),
  text("Event_Contact_Title__c", "Event Contact Job Title", 128),
  picklist("Organisation_Type__c", "Organisation Type", organisationTypes),
  picklist("Partner_Interest_Type__c", "Partner Interest Type", ["Partnership", "Sponsorship", "Both - open to discussion", "Not sure - I would like advice"]),
  multipick("Partner_Interest_Areas__c", "Partner Interest Areas", ["Strategic event partnership", "Event zone sponsorship", "Stage, content or thought leadership", "Branding and delegate experience", "Troops' Track Day", "Other or not sure"]),
  longtext("Partnership_Interest_Detail__c", "Partnership Interest Detail"),
  picklist("Preferred_Contact_Method__c", "Preferred Contact Method", ["Email", "Telephone", "Video call", "No preference"]),
  text("Preferred_Contact_Time__c", "Preferred Contact Time", 255),
  multipick("Exhibitor_Interest_Areas__c", "Exhibitor Interest Areas", ["Careers and recruitment", "Training and education", "Automotive and mobility", "Manufacturing and engineering", "Renewable and clean energy", "Defence and security", "Built environment and facilities", "Financial and professional services", "Digital and technology", "Armed Forces charity or support", "Other"]),
  longtext("Exhibitor_Interest_Detail__c", "Exhibitor Interest Detail"),
  longtext("Exhibitor_Community_Contribution__c", "Exhibitor Community Contribution"),
  checkbox("Contact_Consent__c", "NTE Contact Consent"),
  picklist("Guest_Accompanying__c", "Guest Accompanying", yesNo),
  text("Accompanying_Guest_Name__c", "Accompanying Guest Name", 200),
  email("Accompanying_Guest_Email__c", "Accompanying Guest Email"),
  picklist("Guest_Accessibility_Required__c", "Guest Accessibility Required", yesNo),
  longtext("Guest_Accessibility_Details__c", "Guest Accessibility Details"),
  checkbox("Guest_Information_Declaration__c", "Guest Information Declaration"),
  text("Logo_Upload_URL__c", "NTE Logo Upload URL", 255),
  text("Trading_Name__c", "Trading Name", 255),
  longtext("Invoice_Additional_Information__c", "Invoice Additional Information", 32768, 4),
  number("Power_Socket_Count__c", "Power Socket Count", 2, 0),
  number("Total_Staff_Count__c", "Total Staff Count", 2, 0),
  number("Included_Staff_Count__c", "Included Staff Count", 2, 0),
  picklist("Staff_Update_Audience__c", "Staff Update Audience", ["Exhibitor", "Partner / sponsor"]),
  longtext("Staff_Base_Names__c", "Staff Names Covered by Booking", 32768, 8),
  picklist("Top_Up_Staff_Required__c", "Top-up Staff Required", yesNo),
  number("Top_Up_Staff_Count__c", "Top-up Staff Count", 2, 0),
  longtext("Top_Up_Staff_Names__c", "Top-up Staff Names", 32768, 6),
  currency("Top_Up_Staff_Unit_Price__c", "Top-up Staff Unit Price (ex VAT)"),
  currency("Top_Up_Staff_Total__c", "Top-up Staff Total (ex VAT)"),
  picklist("Quote_Required_for_PO__c", "Quotation Required for PO", yesNo),
  picklist("Payment_Method__c", "Payment Method", ["Bank transfer", "Stripe"]),
  picklist("Invoice_Requested__c", "Invoice Requested", yesNo),
  picklist("Heavy_Vehicle_Required__c", "Heavy Vehicle Required", ["Yes", "No", "Not known yet"]),
  picklist("Delivery_Window__c", "Delivery Window", ["Sunday 28 February between 14:00 - 18:00", "Monday 1 March between 06:30 - 07:15"]),
  text("Heavy_Item_1_Description__c", "Heavy Item 1 Description"),
  text("Heavy_Item_1_Registration__c", "Heavy Item 1 Registration", 80),
  text("Heavy_Item_1_Dimensions__c", "Heavy Item 1 Dimensions", 120),
  text("Heavy_Item_1_Gross_Weight__c", "Heavy Item 1 Gross Weight", 120),
  text("Heavy_Item_2_Description__c", "Heavy Item 2 Description"),
  text("Heavy_Item_2_Registration__c", "Heavy Item 2 Registration", 80),
  text("Heavy_Item_2_Dimensions__c", "Heavy Item 2 Dimensions", 120),
  text("Heavy_Item_2_Gross_Weight__c", "Heavy Item 2 Gross Weight", 120),
  text("Heavy_Item_3_Description__c", "Heavy Item 3 Description"),
  text("Heavy_Item_3_Registration__c", "Heavy Item 3 Registration", 80),
  text("Heavy_Item_3_Dimensions__c", "Heavy Item 3 Dimensions", 120),
  text("Heavy_Item_3_Gross_Weight__c", "Heavy Item 3 Gross Weight", 120),
  text("Haulier_Name__c", "Haulier Name"),
  longtext("Haulier_Staff__c", "Haulier Staff"),
  text("Haulier_Vehicle_Type__c", "Haulier Vehicle Type"),
  text("Haulier_Vehicle_Gross_Weight__c", "Haulier Vehicle Gross Weight", 120),
  text("Haulier_Vehicle_Dimensions__c", "Haulier Vehicle Dimensions", 120),
  text("Haulier_Vehicle_Registration__c", "Haulier Vehicle Registration", 80),
  picklist("NTE_Update_Status__c", "NTE Update Status", ["Pending", "Matched and Applied", "No Matching Booking", "Ambiguous Booking Reference", "Failed"]),
  text("NTE_Update_Booking_Id__c", "Applied NTE Booking ID", 18, {readOnly: true, description: "Opportunity ID recorded by the supplementary update service when the update is accepted. Acknowledgement retries use this booking and must never rematch to a different reference."}),
  longtext("NTE_Update_Error__c", "NTE Update Error", 32768, 3),
  picklist("NTE_Applicant_Email_Status__c", "NTE Applicant Email Status", ["Accepted by Salesforce", "Failed", "Not Attempted", "Not required"]),
  picklist("NTE_Internal_Email_Status__c", "NTE Internal Email Status", ["Accepted by Salesforce", "Failed", "Not Attempted"]),
  longtext("NTE_Email_Error__c", "NTE Email Error", 32768, 3)
  ,currency("Sponsor_Package_Total__c", "Sponsor Package Total (ex VAT)")
  ,currency("Exhibitor_Space_Price__c", "Exhibitor Space Price (ex VAT)")
  ,currency("Power_Socket_Unit_Price__c", "Power Socket Unit Price (ex VAT)")
  ,currency("Power_Socket_Total__c", "Power Socket Total (ex VAT)")
  ,currency("Additional_Staff_Unit_Price__c", "Additional Staff Unit Price (ex VAT)")
  ,currency("Additional_Staff_Total__c", "Additional Staff Total (ex VAT)")
  ,currency("Listed_Price_Total__c", "Booking Total (ex VAT)")
  ,{...number("VAT_Rate__c", "VAT Rate (%)", 5, 2), defaultValue: vatRate}
  ,{...currency("VAT_Total__c", "Booking VAT"), readOnly: true}
  ,{...currency("Total_Including_VAT__c", "Booking Total (inc VAT)"), readOnly: true}
  ,formulaCurrency("Top_Up_VAT_Total__c", "Top-up VAT", `ROUND(BLANKVALUE(Top_Up_Staff_Total__c, 0) * BLANKVALUE(VAT_Rate__c, ${vatRate}) / 100, 2)`)
  ,formulaCurrency("Top_Up_Total_Inc_VAT__c", "Top-up Total (inc VAT)", "BLANKVALUE(Top_Up_Staff_Total__c, 0) + Top_Up_VAT_Total__c")
  ,picklist("Pricing_Status__c", "Pricing Status", ["Calculated", "Review required"])
  ,text("Pricing_Version__c", "Pricing Version", 80)
];

const volunteerChoices = [
  "Fundraising",
  "Transport and Logistics",
  "Motorsport Event Support",
  "Marshalling",
  "Community Outreach / Awareness",
  "Professional Skills",
  "Mentoring & Coaching",
  "Team Area Co-Ordinator",
  "Vehicle Maintenance / Repairs (Wantage)",
  "Pop up shop",
  "Storekeeping (Wantage)",
  "Maintenance / DIY (Wantage)"
];
const volunteerLeadFields = [
  longtext("NOK_Address__c", "Emergency Contact Address", 1000, 4),
  text("NOK_Postcode__c", "Emergency Contact Postcode", 20),
  picklist("Volunteer_Armed_Forces_Service__c", "Armed Forces Service", yesNo),
  longtext("Volunteer_Service_Details__c", "Service, Unit, Station or Ship", 1000, 4),
  text("Volunteer_Service_Dates__c", "Dates in Service", 255),
  {...multipick("Volunteer_Opportunities__c", "Volunteering Opportunities", volunteerChoices, 6), inactiveValues: ["Driving / Transport", "Charity Merchandise / Shop Support"]},
  {...multipick("Volunteer_Skills__c", "Volunteer Skills and Experience", volunteerChoices, 6), inactiveValues: ["Driving / Transport", "Charity Merchandise / Shop Support"]},
  picklist("Volunteer_Hours__c", "Hours Willing to Give per Month", ["0-4", "4-8", "8-16", "16+", "Don't know"]),
  multipick("Volunteer_Availability__c", "Volunteer Availability Preference", ["Weekdays", "Weekends", "Any"], 3),
  multipick("Volunteer_Travel_Regions__c", "Volunteer Travel Regions", ["East Midlands", "Greater London", "North East England", "North West England", "Scotland", "South West England", "South East England", "Wales", "West Midlands", "Yorkshire & the Humber"], 6),
  picklist("Volunteer_DBS_Willing__c", "Willing to Complete DBS Check", yesNo),
  picklist("Volunteer_Consent__c", "Volunteer Consent", yesNo),
  checkbox("Volunteer_Code_Consent__c", "Code of Conduct Acknowledged"),
  text("Volunteer_Code_Version__c", "Code of Conduct Version", 80),
  text("Volunteer_Form_Version__c", "Volunteer Form Version", 80),
  picklist("Volunteer_Applicant_Email_Status__c", "Volunteer Applicant Email Status", ["Accepted by Salesforce", "Failed", "Not Attempted"]),
  picklist("Volunteer_Internal_Email_Status__c", "Volunteer Internal Email Status", ["Accepted by Salesforce", "Failed", "Not Attempted"]),
  longtext("Volunteer_Email_Error__c", "Volunteer Email Error", 32768, 4)
];

const opportunityFields = [
  booking,
  text("NTE_Event_Code__c", "NTE Event Code", 20, {externalId: true, unique: false}),
  text("NTE_Source_Form_Type__c", "NTE Source Form Type", 100),
  text("NTE_Form_Version__c", "NTE Form Version", 80),
  date("NTE_Declaration_Date__c", "NTE Declaration Date"),
  text("NTE_Last_Update_Declaration_Name__c", "NTE Last Update Declaration Name", 200),
  date("NTE_Last_Update_Declaration_Date__c", "NTE Last Update Declaration Date"),
  picklist("NTE_Attendance_Status__c", "NTE Attendance Status", ["Planned", "Attended", "Did Not Attend", "Cancelled"]),
  text("NTE_Event_Contact_Name__c", "NTE Event Contact Name", 200),
  text("NTE_Event_Contact_Title__c", "NTE Event Contact Job Title", 128),
  email("NTE_Event_Contact_Email__c", "NTE Event Contact Email"),
  phone("NTE_Event_Contact_Mobile__c", "NTE Event Contact Mobile"),
  text("NTE_Sponsored_Name__c", "NTE Sponsored Name", 200),
  text("NTE_Alternative_Organisation_Name__c", "NTE Alternative Organisation Name"),
  text("NTE_Trading_Name__c", "NTE Trading Name", 255),
  text("NTE_Secondary_Contact_Prefix__c", "NTE Secondary Contact Prefix", 40),
  text("NTE_Secondary_Contact_Name__c", "NTE Secondary Contact Name", 200),
  text("NTE_Secondary_Contact_Title__c", "NTE Secondary Contact Job Title", 128),
  email("NTE_Secondary_Contact_Email__c", "NTE Secondary Contact Email"),
  phone("NTE_Secondary_Contact_Mobile__c", "NTE Secondary Contact Mobile"),
  phone("NTE_Secondary_Contact_Phone__c", "NTE Secondary Contact Work Phone"),
  text("NTE_Exhibitor_Hall_Schedule__c", "NTE Sunday Setup Availability", 40),
  text("NTE_Has_Special_Requirements__c", "NTE Has Special Requirements", 40),
  text("NTE_Industry_Body_Details__c", "NTE Industry Body Details"),
  text("NTE_Event_Discovery_Source__c", "NTE Event Discovery Source"),
  text("NTE_Declaration_Name__c", "NTE Declaration Name", 200),
  checkbox("NTE_Terms_Accepted__c", "NTE Terms Accepted"),
  multipick("NTE_Sponsor_Package__c", "NTE Sponsorship Package", ["Headline Partner", "Gold Partner", "Premier Partner", "Champion Partner", "Zone Sponsor", "Community Stage Sponsor", "Podcast Corner Sponsor", "Event Guide Sponsor", "Delegate Tote Bag Sponsor", "Helmet Bay Sponsor", "Auditorium Sponsor", "Live Stream Sponsor", "Wristband Sponsor", "Escapade Sponsor"]),
  text("NTE_Exhibitor_Organisation_Category__c", "NTE Exhibitor Organisation Category", 255),
  longtext("NTE_Exhibitor_Space_Selections__c", "NTE Exhibitor Space Selection", 32768, 3),
  text("NTE_Exhibitor_Space_Size__c", "NTE Exhibitor Space Size", 255),
  // Same capacity as the Lead field it is converted from (LongTextArea 1,000).
  longtext("NTE_Exhibitor_Space_Position__c", "NTE Exhibitor Space Position", 1000, 3),
  text("NTE_Previous_Events__c", "Previous NTE Events", 255),
  text("NTE_Stand_Power__c", "NTE Stand Power", 40),
  number("NTE_Power_Socket_Count__c", "NTE Power Socket Count", 2, 0),
  longtext("NTE_Stand_Equipment__c", "NTE Stand Equipment"),
  longtext("NTE_Stand_Special_Requirements__c", "NTE Stand Special Requirements"),
  longtext("NTE_Stand_Colleagues__c", "NTE Stand Colleagues"),
  longtext("NTE_Stand_Extra_Notes__c", "NTE Stand Extra Notes"),
  text("NTE_Planned_Exhibitor_Count__c", "NTE Planned Exhibitor Count", 40),
  number("NTE_Initial_Staff_Count__c", "NTE Initial Staff Count", 2, 0),
  number("NTE_Included_Staff_Count__c", "NTE Included Staff Count", 2, 0),
  number("NTE_Total_Staff_Count__c", "NTE Total Staff Count", 3, 0),
  text("NTE_Additional_Staff_Required__c", "NTE Additional Staff Required", 40),
  text("NTE_Additional_Staff_Count__c", "NTE Additional Staff Count", 40),
  text("NTE_Top_Up_Staff_Required__c", "NTE Top-up Staff Required", 40),
  number("NTE_Top_Up_Staff_Count__c", "NTE Top-up Staff Count", 2, 0),
  longtext("NTE_Top_Up_Staff_Names__c", "NTE Top-up Staff Names", 32768, 6),
  text("NTE_Heavy_Vehicle_Required__c", "NTE Heavy Vehicle Required", 40),
  text("NTE_Invoice_Required__c", "NTE Payment Required", 40, {description: "Calculated billable status; applicant invoice preference is recorded separately in NTE Invoice Requested."}),
  picklist("NTE_Payment_Method__c", "NTE Payment Method", ["Bank transfer", "Stripe"]),
  picklist("NTE_Invoice_Requested__c", "NTE Invoice Requested", yesNo),
  text("NTE_Invoiced_Company__c", "NTE Invoiced Company"),
  longtext("NTE_Invoice_Address__c", "NTE Invoice Address"),
  text("NTE_Invoiced_Person__c", "NTE Invoiced Person"),
  email("NTE_Invoiced_Email__c", "NTE Invoiced Email"),
  phone("NTE_Invoice_Contact_Phone__c", "NTE Invoice Contact Phone"),
  longtext("NTE_Invoice_Additional_Information__c", "NTE Invoice Additional Information", 32768, 4),
  text("NTE_Purchase_Order__c", "NTE Purchase Order Required", 40),
  text("NTE_Purchase_Order_Number__c", "NTE Purchase Order Number", 120),
  text("NTE_Quote_Required_for_PO__c", "NTE Quotation Required for PO", 40),
  text("NTE_Supplier_Agreement_Required__c", "NTE Supplier Agreement Required", 40),
  text("NTE_Delivery_Window__c", "NTE Delivery Window", 255),
  text("NTE_Heavy_Item_1_Description__c", "NTE Heavy Item 1 Description"),
  text("NTE_Heavy_Item_1_Registration__c", "NTE Heavy Item 1 Registration", 80),
  text("NTE_Heavy_Item_1_Dimensions__c", "NTE Heavy Item 1 Dimensions", 120),
  text("NTE_Heavy_Item_1_Gross_Weight__c", "NTE Heavy Item 1 Gross Weight", 120),
  text("NTE_Heavy_Item_2_Description__c", "NTE Heavy Item 2 Description"),
  text("NTE_Heavy_Item_2_Registration__c", "NTE Heavy Item 2 Registration", 80),
  text("NTE_Heavy_Item_2_Dimensions__c", "NTE Heavy Item 2 Dimensions", 120),
  text("NTE_Heavy_Item_2_Gross_Weight__c", "NTE Heavy Item 2 Gross Weight", 120),
  text("NTE_Heavy_Item_3_Description__c", "NTE Heavy Item 3 Description"),
  text("NTE_Heavy_Item_3_Registration__c", "NTE Heavy Item 3 Registration", 80),
  text("NTE_Heavy_Item_3_Dimensions__c", "NTE Heavy Item 3 Dimensions", 120),
  text("NTE_Heavy_Item_3_Gross_Weight__c", "NTE Heavy Item 3 Gross Weight", 120),
  text("NTE_Haulier_Name__c", "NTE Haulier Name"),
  longtext("NTE_Haulier_Staff__c", "NTE Haulier Staff"),
  text("NTE_Haulier_Vehicle_Type__c", "NTE Haulier Vehicle Type"),
  text("NTE_Haulier_Vehicle_Gross_Weight__c", "NTE Haulier Vehicle Gross Weight", 120),
  text("NTE_Haulier_Vehicle_Dimensions__c", "NTE Haulier Vehicle Dimensions", 120),
  text("NTE_Haulier_Vehicle_Registration__c", "NTE Haulier Vehicle Registration", 80),
  text("NTE_Last_Update_Type__c", "NTE Last Update Type", 100),
  text("NTE_Last_Update_Form_Version__c", "NTE Last Update Form Version", 80),
  {api: "NTE_Last_Update_Processed_At__c", label: "NTE Last Update Processed At", type: "DateTime"},
  longtext("NTE_Last_Update_Error__c", "NTE Last Update Error", 32768, 3),
  currency("NTE_Sponsor_Package_Total__c", "NTE Sponsor Package Total (ex VAT)"),
  currency("NTE_Exhibitor_Space_Price__c", "NTE Exhibitor Space Price (ex VAT)"),
  currency("NTE_Power_Socket_Unit_Price__c", "NTE Power Socket Unit Price (ex VAT)"),
  currency("NTE_Power_Socket_Total__c", "NTE Power Socket Total (ex VAT)"),
  currency("NTE_Additional_Staff_Unit_Price__c", "NTE Additional Staff Unit Price (ex VAT)"),
  currency("NTE_Additional_Staff_Total__c", "NTE Additional Staff Total (ex VAT)"),
  currency("NTE_Top_Up_Staff_Unit_Price__c", "NTE Top-up Staff Unit Price (ex VAT)"),
  currency("NTE_Top_Up_Staff_Total__c", "NTE Top-up Staff Total (ex VAT)"),
  currency("NTE_Listed_Price_Total__c", "NTE Booking Total (ex VAT)"),
  {...currency("NTE_Price_Adjustment__c", "NTE Booking Adjustment (ex VAT)"), defaultValue: 0, readOnly: true, description: "Difference between the original item charges and the revised net booking total. To revise the booking price, edit Amount including VAT."},
  {...text("NTE_Approval_Email_Kind__c", "NTE Booking Email Kind", 40), readOnly: true, description: "The requested kind of booking email, retained while the manual send is processed."},
  {...checkbox("NTE_Free_Space_Confirmed__c", "NTE Free Space Confirmed"), description: "A free booking or waived booking has had its confirmation accepted for sending. Set by the Master Panel action; staff may tick or untick it on the record as a manual fallback."},
  {...number("NTE_VAT_Rate__c", "NTE Booking VAT Rate (%)", 5, 2), defaultValue: vatRate},
  formulaCurrency("NTE_VAT_Total__c", "NTE Booking VAT", `IF(NOT(NTE_Pricing_Ready__c), NULL, IF(ISBLANK(Amount), ROUND(NTE_Listed_Price_Total__c * BLANKVALUE(NTE_VAT_Rate__c, ${vatRate}) / 100, 2), Amount - NTE_Listed_Price_Total__c))`),
  formulaCurrency("NTE_Total_Including_VAT__c", "NTE Booking Total (inc VAT)", "IF(NOT(NTE_Pricing_Ready__c), NULL, BLANKVALUE(Amount, NTE_Listed_Price_Total__c + NTE_VAT_Total__c))"),
  {...number("NTE_Top_Up_VAT_Rate__c", "NTE Top-up VAT Rate (%)", 5, 2), defaultValue: vatRate},
  formulaCurrency("NTE_Top_Up_VAT_Total__c", "NTE Top-up VAT", `ROUND(BLANKVALUE(NTE_Top_Up_Staff_Total__c, 0) * BLANKVALUE(NTE_Top_Up_VAT_Rate__c, ${vatRate}) / 100, 2)`),
  formulaCurrency("NTE_Top_Up_Total_Inc_VAT__c", "NTE Top-up Total (inc VAT)", "BLANKVALUE(NTE_Top_Up_Staff_Total__c, 0) + NTE_Top_Up_VAT_Total__c"),
  formulaCheckbox("NTE_Pricing_Ready__c", "NTE Pricing Ready", pricingReadyFormula, "Whether the saved booking price can be used for finance and readiness."),
  formulaCheckbox("NTE_Finance_Payment_Due__c", "NTE Payment Required", paymentDueFormula, "An unpaid booking or staff top-up has an accepted manual payment request."),
  formulaCheckbox("NTE_Finance_Payment_Confirmed__c", "NTE Payment Confirmed", paymentConfirmedFormula, "Every applicable payment is recorded; complimentary bookings have their confirmation sent. Procurement ticks do not gate this status."),
  formulaCurrency(
    "NTE_Confirmed_Value__c",
    "NTE Confirmed Value (inc VAT)",
    "IF(NOT(NTE_Pricing_Ready__c), NULL, IF(AND(NOT(ISBLANK(Amount)), Amount > 0), Amount, NTE_Total_Including_VAT__c) + NTE_Top_Up_Total_Inc_VAT__c)",
    "Booking value including VAT and separately rounded staff top-ups. Bookings needing a pricing check are excluded."
  ),
  picklist("NTE_Pricing_Status__c", "NTE Pricing Status", ["Calculated", "Review required"]),
  text("NTE_Pricing_Version__c", "NTE Pricing Version", 80),
  formulaCheckbox("NTE_Finance_Requirements_Due__c", "NTE Finance Requirements", requirementsDueFormula, "Awaiting a manual booking confirmation or payment request; checklist ticks do not control this status."),
  checkbox("NTE_PO_Confirmed__c", "NTE Purchase Order Confirmed"),
  checkbox("NTE_Agreement_Provided__c", "NTE Supplier Agreement Provided"),
  checkbox("NTE_Invoice_Details_Included__c", "NTE Invoice Details Included"),
  checkbox("NTE_Bank_Details_Provided__c", "NTE Bank Details Provided"),
  datetime("NTE_Top_Up_Payment_Requested_At__c", "NTE Top-up Payment Requested At"),
  text("NTE_Joining_Instructions_By__c", "NTE Joining Instructions Recorded By", 120),
  checkbox("NTE_Quote_Provided__c", "NTE Quote Provided"),
  datetime("NTE_Quote_Provided_At__c", "NTE Quote Provided At"),
  text("NTE_Quote_Provided_By__c", "NTE Quote Provided By", 120),
  checkbox("NTE_Invoice_Provided__c", "NTE Invoice Provided"),
  datetime("NTE_Invoice_Provided_At__c", "NTE Invoice Provided At"),
  text("NTE_Invoice_Provided_By__c", "NTE Invoice Provided By", 120),
  checkbox("NTE_Payment_Received__c", "NTE Payment Received"),
  datetime("NTE_Payment_Received_At__c", "NTE Payment Received At"),
  text("NTE_Payment_Recorded_By__c", "NTE Payment Recorded By", 120),
  checkbox("NTE_Top_Up_Invoice_Required__c", "NTE Top-up Payment Required"),
  checkbox("NTE_Top_Up_Invoice_Provided__c", "NTE Top-up Invoice Provided"),
  datetime("NTE_Top_Up_Invoice_At__c", "NTE Top-up Invoice Provided At"),
  text("NTE_Top_Up_Invoice_By__c", "NTE Top-up Invoice Provided By", 120),
  checkbox("NTE_Top_Up_Payment_Received__c", "NTE Top-up Payment Received"),
  datetime("NTE_Top_Up_Payment_At__c", "NTE Top-up Payment Received At"),
  text("NTE_Top_Up_Payment_By__c", "NTE Top-up Payment Received By", 120),
  datetime("NTE_Staff_Update_Completed_At__c", "NTE Staff Update Completed At"),
  datetime("NTE_Heavy_Vehicle_Update_Completed_At__c", "NTE Heavy Vehicle Update Completed At"),
  checkbox("NTE_Logo_Update_Provided__c", "NTE Logo Update Provided"),
  datetime("NTE_Logo_Update_Provided_At__c", "NTE Logo Update Provided At")
];

for (const field of opportunityFields) {
  if (field.api === "NTE_Quote_Provided__c") field.description = "Selected from the NTE Master Panel after the quote has been sent.";
  if (field.api === "NTE_Invoice_Provided__c") field.description = "Selected from the NTE Master Panel after the invoice has been provided. Payment requests are recorded separately.";
  if (field.api === "NTE_Payment_Received__c") field.description = "Selected from the NTE Master Panel after payment has been confirmed.";
  if (field.api === "NTE_Staff_Update_Completed_At__c") field.description = "Set automatically after the applicable exhibitor or partner / sponsor staff update has been applied successfully.";
  if (field.api === "NTE_Heavy_Vehicle_Update_Completed_At__c") field.description = "Set automatically after a Heavy Vehicle Details submission has been applied successfully.";
  if (field.api === "NTE_Logo_Update_Provided__c") field.description = "Selected automatically after a Logo Update submission has been matched to this NTE booking.";
  if (field.api === "NTE_Logo_Update_Provided_At__c") field.description = "The date and time the first matched Logo Update submission was received.";
}

const accountFields = [
  checkbox("NTE_Participant__c", "NTE Organisation"),
  text("NTE_Event_Code__c", "Latest NTE Event Code", 20),
  text("NTE_Source_Form_Type__c", "Latest NTE Source Form", 100),
  text("NTE_Booking_Reference__c", "Latest NTE Booking Reference", 80),
  datetime("NTE_Last_Application_Date__c", "Latest NTE Application Date")
];
accountFields[0].description = "Identifies an organisation created or updated from a converted NTE application.";

const contactFields = [
  checkbox("NTE_Participant__c", "NTE Contact"),
  text("NTE_Event_Code__c", "Latest NTE Event Code", 20),
  text("NTE_Source_Form_Type__c", "Latest NTE Source Form", 100),
  text("NTE_Booking_Reference__c", "Latest NTE Booking Reference", 80),
  datetime("NTE_Last_Application_Date__c", "Latest NTE Application Date"),
  text("NTE_Contact_Role__c", "NTE Contact Role", 100)
];
contactFields[0].description = "Identifies a person created or updated from a converted NTE application.";

for (const [objectName, fields] of [["Lead", [...leadFields, ...volunteerLeadFields]], ["Opportunity", opportunityFields], ["Account", accountFields], ["Contact", contactFields]]) {
  fields.forEach((field) => write(path.join(md, "objects", objectName, "fields", `${field.api}.field-meta.xml`), fieldXml(field)));
}

write(path.join(md, "objects", "Lead", "validationRules", "NTE_Interest_Decision_Exclusive.validationRule-meta.xml"), [
  '<?xml version="1.0" encoding="UTF-8"?>',
  `<ValidationRule xmlns="${ns}">`,
  "    <fullName>NTE_Interest_Decision_Exclusive</fullName>",
  "    <active>true</active>",
  "    <description>An expression of interest cannot be both progressed and not progressed.</description>",
  "    <errorConditionFormula>AND(NTE_Interest_Progressed__c, NTE_Interest_Not_Progressed__c)</errorConditionFormula>",
  "    <errorMessage>Choose either Progressed or Not Progressed, not both.</errorMessage>",
  "</ValidationRule>",
  ""
].join("\n"));

write(path.join(md, "objects", "Lead", "validationRules", "NTE_Intake_Event_Code.validationRule-meta.xml"), [
  '<?xml version="1.0" encoding="UTF-8"?>',
  `<ValidationRule xmlns="${ns}">`,
  "    <fullName>NTE_Intake_Event_Code</fullName>",
  "    <active>true</active>",
  "    <description>New or changed NTE interest, application and guest event codes must identify a four-digit edition. Unrelated edits to historical records are preserved.</description>",
  `    <errorConditionFormula>${esc('AND(OR(ISNEW(), ISCHANGED(NTE_Event_Code__c), ISCHANGED(Web_Form_Type__c)), OR(ISPICKVAL(Web_Form_Type__c, "Partner / Sponsor Expression of Interest"), ISPICKVAL(Web_Form_Type__c, "Exhibitor Expression of Interest"), ISPICKVAL(Web_Form_Type__c, "Partner / Sponsor Application"), ISPICKVAL(Web_Form_Type__c, "Exhibitor Application"), ISPICKVAL(Web_Form_Type__c, "Guest Registration")), NOT(REGEX(NTE_Event_Code__c, "^NTE[0-9]{4}$")))')}</errorConditionFormula>`,
  "    <errorDisplayField>NTE_Event_Code__c</errorDisplayField>",
  "    <errorMessage>Enter an event code in the format NTE2027.</errorMessage>",
  "</ValidationRule>",
  ""
].join("\n"));

write(path.join(md, "objects", "Lead", "validationRules", "Volunteer_Code_Required.validationRule-meta.xml"), [
  '<?xml version="1.0" encoding="UTF-8"?>',
  `<ValidationRule xmlns="${ns}">`,
  "    <fullName>Volunteer_Code_Required</fullName>",
  "    <active>true</active>",
  "    <description>New v3 volunteer applications must acknowledge the supplied September 2026 Code of Conduct. Historical applications are unchanged.</description>",
  `    <errorConditionFormula>${esc('AND(ISNEW(), ISPICKVAL(Web_Form_Type__c, "Volunteer Application"), Volunteer_Form_Version__c = "volunteer-application-v3", OR(NOT(Volunteer_Code_Consent__c), Volunteer_Code_Version__c <> "September 2026"))')}</errorConditionFormula>`,
  "    <errorDisplayField>Volunteer_Code_Consent__c</errorDisplayField>",
  "    <errorMessage>Please read and acknowledge the September 2026 Code of Conduct.</errorMessage>",
  "</ValidationRule>",
  ""
].join("\n"));

const requiredStandardValues = JSON.parse(fs.readFileSync(path.join(root, "config", "salesforce-standard-values.json"), "utf8"));
for (const [valueSet, values] of Object.entries(requiredStandardValues)) {
  write(path.join(md, "standardValueSets", `${valueSet}.standardValueSet-meta.xml`), [
    '<?xml version="1.0" encoding="UTF-8"?>',
    `<StandardValueSet xmlns="${ns}">`,
    "    <sorted>false</sorted>",
    ...values.flatMap((value) => [
      "    <standardValue>",
      ...Object.entries(value).map(([key, content]) => `        <${key}>${esc(content)}</${key}>`),
      "    </standardValue>"
    ]),
    "</StandardValueSet>",
    ""
  ].join("\n"));
}

write(path.join(md, "objects", "Opportunity", "businessProcesses", "NTE_Sales_Process.businessProcess-meta.xml"), [
  '<?xml version="1.0" encoding="UTF-8"?>',
  `<BusinessProcess xmlns="${ns}">`,
  "    <fullName>NTE_Sales_Process</fullName>",
  "    <description>Sales process used by National Transition Event opportunities.</description>",
  "    <isActive>true</isActive>",
  ...requiredStandardValues.OpportunityStage.map((value) => value.fullName).flatMap((value) => [
    "    <values>",
    `        <fullName>${value}</fullName>`,
    "    </values>"
  ]),
  "</BusinessProcess>",
  ""
].join("\n"));

write(path.join(md, "objects", "Opportunity", "recordTypes", "NTE_Event_Opportunity.recordType-meta.xml"), [
  '<?xml version="1.0" encoding="UTF-8"?>',
  `<RecordType xmlns="${ns}">`,
  "    <fullName>NTE_Event_Opportunity</fullName>",
  "    <active>true</active>",
  "    <businessProcess>NTE_Sales_Process</businessProcess>",
  "    <description>National Transition Event exhibitor, partner and sponsor opportunities.</description>",
  "    <label>NTE Event Opportunity</label>",
  "</RecordType>",
  ""
].join("\n"));

const existingLeadFields = [
  picklist("Web_Form_Type__c", "Web Form Type", [
    "Partner Sponsor Application Form",
    "Partner Sponsor Exhibition Space Questions",
    "Partner / Sponsor Expression of Interest",
    "Exhibitor Expression of Interest",
    "Partner / Sponsor Application",
    "Exhibitor Application",
    "Guest Registration",
    "Staff Details Update",
    "Partner / Sponsor Staff Update",
    "Exhibitor Staff Update",
    "Heavy Vehicle Details",
    "Logo Update",
    "Volunteer Application"
  ]),
  picklist("Event_Discovery_Source__c", "Event Discovery Source", [
    "Previous exhibitor",
    "E-mail invitation",
    "Word of mouth from previous exhibitor",
    "Word of mouth from previous attendees",
    "Website",
    "LinkedIn",
    "Facebook",
    "Instagram",
    "Previous NTE event",
    "NTE webinar or brochure",
    "Email invitation",
    "Recommendation or word of mouth",
    "National Transition Event website",
    "Mission Community website",
    "Other social media",
    "Other"
  ]),
  multipick("Sponsor_Package__c", "Sponsorship Package", [
    "Headline Partner",
    "Gold Partner",
    "Premier Partner",
    "Champion Partner",
    "Zone Sponsor",
    "Community Stage Sponsor",
    "Podcast Corner Sponsor",
    "Event Guide Sponsor",
    "Delegate Tote Bag Sponsor",
    "Helmet Bay Sponsor",
    "Auditorium Sponsor",
    "Live Stream Sponsor",
    "Wristband Sponsor",
    "Escapade Sponsor"
  ])
];
existingLeadFields[0].description = "Identifies the public form that created the Lead. Stable across NTE editions.";
existingLeadFields[1].description = "How the person discovered the National Transition Event.";
existingLeadFields[2].description = "Sponsorship packages selected by the applicant.";
existingLeadFields[2].visibleLines = 5;
existingLeadFields.forEach((field) => write(path.join(md, "objects", "Lead", "fields", `${field.api}.field-meta.xml`), fieldXml(field)));

const leadSourceValues = [
  "Advertisement",
  "Customer Event",
  "Employee Referral",
  "External Referral",
  "Google AdWords",
  "Other",
  "Partner",
  "Purchased List",
  "Trade Show",
  "Webinar",
  "Website",
  "Partner Sponsor Exhibition Space Questions",
  "Partner Sponsor Application Form",
  "Volunteer Application"
];
write(path.join(md, "standardValueSets", "LeadSource.standardValueSet-meta.xml"), [
  '<?xml version="1.0" encoding="UTF-8"?>',
  `<StandardValueSet xmlns="${ns}">`,
  "    <sorted>false</sorted>",
  ...leadSourceValues.map((value) => `    <standardValue><fullName>${esc(value)}</fullName><default>false</default><label>${esc(value)}</label></standardValue>`),
  "</StandardValueSet>",
  ""
].join("\n"));

const reusedLeadFieldApis = [
  "Sponsored_Name__c", "Invoice_Required__c", "Invoiced_Company__c", "Invoice_Address__c", "Invoiced_Person__c",
  "Invoiced_Email__c", "Purchase_Order__c", "Event_Contact_Name__c", "Event_Contact_Email__c", "Event_Contact_Mobile__c",
  "Exhibitor_Hall_Schedule__c", "Stand_Power__c", "Stand_Equipment__c", "Stand_Special_Requirements__c", "Stand_Colleagues__c",
  "Terms_and_Conditions__c", "Alternative_Organisation_Name__c", "Exhibitor_Organisation_Category__c",
  "Secondary_Contact_Prefix__c", "Secondary_Contact_Name__c", "Secondary_Contact_Title__c", "Secondary_Contact_Email__c",
  "Secondary_Contact_Mobile__c", "Secondary_Contact_Phone__c", "Previous_NTE_Events__c", "Planned_Exhibitor_Count__c",
  "Exhibitor_Space_Selections__c", "Additional_Staff_Required__c", "Additional_Staff_Count__c", "Has_Special_Requirements__c",
  "Invoice_Contact_Phone__c", "Purchase_Order_Number__c", "Supplier_Agreement_Required__c", "Industry_Body_Details__c",
  "Event_Discovery_Source__c", "Declaration_Name__c", "Exhibitor_Space_Size__c", "Exhibitor_Space_Position__c",
  "Stand_Extra_Notes__c"
];

const reusedVolunteerLeadFieldApis = [
  "Date_of_Birth__c",
  "NOK_Name__c",
  "NOK_Relationship__c",
  "NOK_Phone__c",
  "Interested_in_Volunteering__c",
  "Consent_PII__c",
  "Consent_Contact__c",
  "Consent_Promotion__c",
  "Declaration_Name__c",
  "Declaration_Date__c"
];

function listViewXml(api, label, columns, filters, booleanFilter) {
  const lines = ['<?xml version="1.0" encoding="UTF-8"?>', `<ListView xmlns="${ns}">`, `    <fullName>${esc(api)}</fullName>`];
  if (booleanFilter) lines.push(`    <booleanFilter>${esc(booleanFilter)}</booleanFilter>`);
  columns.forEach((column) => lines.push(`    <columns>${esc(column)}</columns>`));
  lines.push("    <filterScope>Everything</filterScope>");
  filters.forEach((filter) => {
    lines.push("    <filters>", `        <field>${esc(filter.field)}</field>`, `        <operation>${filter.operation}</operation>`);
    if (filter.value !== undefined) lines.push(`        <value>${esc(filter.value)}</value>`);
    lines.push("    </filters>");
  });
  lines.push(`    <label>${esc(label)}</label>`, "</ListView>", "");
  return lines.join("\n");
}

const nteOpportunityRecordTypeListFilter = {
  field: "OPPORTUNITY.RECORDTYPE",
  operation: "equals",
  value: "Opportunity.NTE_Event_Opportunity"
};

function nteOpportunityListFilters(filters) {
  return [nteOpportunityRecordTypeListFilter, ...filters];
}

const leadListViews = {
  NTE_Expressions_of_Interest: ["NTE Expressions of Interest", ["FULL_NAME", "LEAD.COMPANY", "LEAD.EMAIL", "Web_Form_Type__c", "NTE_Event_Code__c", "NTE_Interest_Progressed__c", "NTE_Interest_Not_Progressed__c", "LEAD.STATUS", "LEAD.CREATED_DATE"], [{field: "Web_Form_Type__c", operation: "equals", value: "Partner / Sponsor Expression of Interest,Exhibitor Expression of Interest"}, {field: "LEAD.CONVERTED", operation: "equals", value: "0"}]],
  NTE_Applications: ["NTE Applications", ["FULL_NAME", "LEAD.COMPANY", "LEAD.EMAIL", "Web_Form_Type__c", "Booking_Reference__c", "Payment_Method__c", "NTE_Event_Code__c", "NTE_Application_Rejected__c", "LEAD.STATUS", "LEAD.CREATED_DATE"], [{field: "Web_Form_Type__c", operation: "equals", value: "Partner / Sponsor Application,Exhibitor Application"}, {field: "LEAD.CONVERTED", operation: "equals", value: "0"}]],
  NTE_Partner_Sponsor_Applications: ["NTE Partner / Sponsor Applications", ["FULL_NAME", "LEAD.COMPANY", "LEAD.EMAIL", "Booking_Reference__c", "Payment_Method__c", "NTE_Event_Code__c", "NTE_Application_Rejected__c", "LEAD.STATUS", "LEAD.CREATED_DATE"], [{field: "Web_Form_Type__c", operation: "equals", value: "Partner / Sponsor Application"}, {field: "LEAD.CONVERTED", operation: "equals", value: "0"}]],
  NTE_Exhibitor_Applications: ["NTE Exhibitor Applications", ["FULL_NAME", "LEAD.COMPANY", "LEAD.EMAIL", "Booking_Reference__c", "Payment_Method__c", "NTE_Event_Code__c", "NTE_Application_Rejected__c", "LEAD.STATUS", "LEAD.CREATED_DATE"], [{field: "Web_Form_Type__c", operation: "equals", value: "Exhibitor Application"}, {field: "LEAD.CONVERTED", operation: "equals", value: "0"}]],
  NTE_Guest_Registrations: ["NTE Guest Registrations", ["FULL_NAME", "LEAD.COMPANY", "LEAD.EMAIL", "NTE_Event_Code__c", "LEAD.STATUS", "LEAD.CREATED_DATE"], [{field: "Web_Form_Type__c", operation: "equals", value: "Guest Registration"}, {field: "LEAD.CONVERTED", operation: "equals", value: "0"}]],
  NTE_Unmatched_Updates: ["NTE Update Issues", ["FULL_NAME", "LEAD.COMPANY", "LEAD.EMAIL", "Web_Form_Type__c", "Target_Booking_Reference__c", "NTE_Update_Status__c", "NTE_Update_Error__c", "NTE_Applicant_Email_Status__c", "NTE_Email_Error__c", "LEAD.CREATED_DATE"], [
    {field: "Web_Form_Type__c", operation: "equals", value: "Partner / Sponsor Staff Update,Exhibitor Staff Update,Heavy Vehicle Details,Logo Update"},
    {field: "NTE_Update_Status__c", operation: "equals", value: "No Matching Booking,Ambiguous Booking Reference,Failed"},
    {field: "NTE_Update_Status__c", operation: "equals", value: "Matched and Applied"},
    {field: "NTE_Applicant_Email_Status__c", operation: "equals", value: "Failed"}
  ], "1 AND (2 OR (3 AND 4))"],
  NTE_All_Web_Submissions: ["NTE All Web Submissions", ["FULL_NAME", "LEAD.COMPANY", "LEAD.EMAIL", "Web_Form_Type__c", "NTE_Event_Code__c", "Booking_Reference__c", "Target_Booking_Reference__c", "LEAD.STATUS", "LEAD.CREATED_DATE"], [{field: "NTE_Event_Code__c", operation: "notEqual"}]],
  Volunteer_Applications: ["Volunteer Applications", ["FULL_NAME", "LEAD.EMAIL", "LEAD.MOBILE_PHONE", "Volunteer_Opportunities__c", "Volunteer_Travel_Regions__c", "Volunteer_DBS_Willing__c", "LEAD.STATUS", "LEAD.CREATED_DATE"], [
    {field: "Web_Form_Type__c", operation: "equals", value: "Volunteer Application"},
    {field: "Interested_in_Volunteering__c", operation: "equals", value: "1"},
    {field: "LEAD.LEAD_SOURCE", operation: "equals", value: "Volunteer Application"}
  ], "1 OR 2 OR 3"]
};
leadListViews.NTE_Expressions_of_Interest[2].push(
  {field: "NTE_Interest_Progressed__c", operation: "equals", value: "0"},
  {field: "NTE_Interest_Not_Progressed__c", operation: "equals", value: "0"},
  {field: "NTE_Event_Code__c", operation: "notEqual"}
);
for (const api of ["NTE_Applications", "NTE_Partner_Sponsor_Applications", "NTE_Exhibitor_Applications"]) {
  leadListViews[api][2].push({field: "NTE_Application_Rejected__c", operation: "equals", value: "0"},
    {field: "NTE_Event_Code__c", operation: "notEqual"});
}
Object.entries(leadListViews).forEach(([api, [label, columns, filters, booleanFilter]]) => write(path.join(md, "objects", "Lead", "listViews", `${api}.listView-meta.xml`), listViewXml(api, label, columns, filters, booleanFilter)));

write(path.join(md, "objects", "Opportunity", "listViews", "NTE_Event_Participation.listView-meta.xml"), listViewXml(
  "NTE_Event_Participation",
  "NTE Event Participation",
  ["OPPORTUNITY.NAME", "ACCOUNT.NAME", "NTE_Event_Code__c", "NTE_Source_Form_Type__c", "Booking_Reference__c", "NTE_Attendance_Status__c", "OPPORTUNITY.STAGE_NAME", "OPPORTUNITY.CLOSE_DATE"],
  nteOpportunityListFilters([{field: "NTE_Event_Code__c", operation: "notEqual"}])
));

const financeListColumns = ["OPPORTUNITY.NAME", "ACCOUNT.NAME", "NTE_Event_Code__c", "NTE_Total_Including_VAT__c", "NTE_Top_Up_Total_Inc_VAT__c", "NTE_Invoice_Provided__c", "NTE_Top_Up_Invoice_Provided__c", "NTE_Payment_Received__c", "NTE_Top_Up_Payment_Received__c", "NTE_Pricing_Status__c"];
const masterPanelOpportunityViews = {
  NTE_Requirements: ["NTE Requirements", financeListColumns, [{field: "NTE_Finance_Requirements_Due__c", operation: "equals", value: "1"}]],
  NTE_Payments_Due: ["NTE Payment Required", financeListColumns, [{field: "NTE_Finance_Payment_Due__c", operation: "equals", value: "1"}]],
  NTE_Payment_Confirmed: ["NTE Payment Confirmed", financeListColumns, [{field: "NTE_Finance_Payment_Confirmed__c", operation: "equals", value: "1"}]],
  NTE_Heavy_Vehicle_Updates_Due: ["NTE Heavy Vehicle Updates Due", ["OPPORTUNITY.NAME", "ACCOUNT.NAME", "NTE_Event_Code__c", "Booking_Reference__c", "NTE_Heavy_Vehicle_Required__c", "NTE_Heavy_Vehicle_Update_Completed_At__c"], [{field: "NTE_Heavy_Vehicle_Required__c", operation: "notEqual", value: "Yes"}, {field: "NTE_Heavy_Vehicle_Required__c", operation: "notEqual", value: "No"}, {field: "NTE_Heavy_Vehicle_Required__c", operation: "equals", value: ""}, {field: "NTE_Heavy_Vehicle_Required__c", operation: "equals", value: "Yes"}, {field: "NTE_Heavy_Vehicle_Update_Completed_At__c", operation: "equals", value: ""}], "(1 AND 2) OR 3 OR (4 AND 5)"],
  NTE_Staff_Updates_Due: ["NTE Staff Updates Due", ["OPPORTUNITY.NAME", "ACCOUNT.NAME", "NTE_Event_Code__c", "Booking_Reference__c", "NTE_Staff_Update_Completed_At__c"], [{field: "NTE_Staff_Update_Completed_At__c", operation: "equals", value: ""}]],
  NTE_Logo_Updates_Due: ["NTE Logo Updates Due", ["OPPORTUNITY.NAME", "ACCOUNT.NAME", "NTE_Event_Code__c", "Booking_Reference__c", "NTE_Source_Form_Type__c", "NTE_Logo_Update_Provided__c", "NTE_Logo_Update_Provided_At__c"], [{field: "NTE_Logo_Update_Provided__c", operation: "equals", value: "0"}]]
};
const activeBookingListFilters = [
  nteOpportunityRecordTypeListFilter,
  {field: "NTE_Event_Code__c", operation: "notEqual"},
  {field: "NTE_Source_Form_Type__c", operation: "equals", value: "Exhibitor Application,Partner / Sponsor Application"},
  {field: "OPPORTUNITY.CLOSED", operation: "equals", value: "0"},
  {field: "OPPORTUNITY.WON", operation: "equals", value: "1"}
];
Object.entries(masterPanelOpportunityViews).forEach(([api, [label, columns, filters, booleanFilter]]) => {
  const localLogic = booleanFilter || filters.map((_, index) => index + 1).join(" AND ");
  const shiftedLogic = localLogic.replace(/\d+/g, index => Number(index) + activeBookingListFilters.length);
  write(path.join(md, "objects", "Opportunity", "listViews", `${api}.listView-meta.xml`),
    listViewXml(api, label, columns, [...activeBookingListFilters, ...filters], `1 AND 2 AND 3 AND (4 OR 5) AND (${shiftedLogic})`));
});

write(path.join(md, "sharingRules", "Opportunity.sharingRules-meta.xml"), [
  '<?xml version="1.0" encoding="UTF-8"?>',
  `<SharingRules xmlns="${ns}">`,
  "    <sharingCriteriaRules>",
  "        <fullName>NTE_Opportunities_Internal_Edit</fullName>",
  "        <accessLevel>Edit</accessLevel>",
  "        <label>NTE Opportunities - Internal Edit Access</label>",
  "        <sharedTo>",
  "            <allInternalUsers></allInternalUsers>",
  "        </sharedTo>",
  "        <criteriaItems>",
  "            <field>RecordTypeId</field>",
  "            <operation>equals</operation>",
  "            <value>NTE Event Opportunity</value>",
  "        </criteriaItems>",
  "    </sharingCriteriaRules>",
  "</SharingRules>",
  ""
].join("\n"));

write(path.join(md, "objects", "Account", "listViews", "NTE_Organisations.listView-meta.xml"), listViewXml(
  "NTE_Organisations",
  "NTE Organisations",
  ["ACCOUNT.NAME", "ACCOUNT.TYPE", "NTE_Event_Code__c", "NTE_Source_Form_Type__c", "NTE_Booking_Reference__c", "NTE_Last_Application_Date__c"],
  [{field: "NTE_Participant__c", operation: "equals", value: "1"}]
));

write(path.join(md, "objects", "Contact", "listViews", "NTE_Contacts.listView-meta.xml"), listViewXml(
  "NTE_Contacts",
  "NTE Contacts",
  ["FULL_NAME", "CONTACT.TITLE", "CONTACT.EMAIL", "NTE_Event_Code__c", "NTE_Source_Form_Type__c", "NTE_Booking_Reference__c", "NTE_Last_Application_Date__c"],
  [{field: "NTE_Participant__c", operation: "equals", value: "1"}]
));

function reportXml({name, description, reportType, columns, filters, booleanFilter, groupings, timeColumn, timeInterval = "INTERVAL_CUSTOM", startDate, sortColumn, sortOrder = "Asc", amountColumns = []}) {
  const resolvedStartDate = startDate === undefined && timeInterval === "INTERVAL_CUSTOM" ? "2000-01-01" : startDate;
  const lines = ['<?xml version="1.0" encoding="UTF-8"?>', `<Report xmlns="${ns}">`];
  for (const column of columns.filter((column) => !groupings.includes(column))) {
    lines.push("    <columns>");
    if (amountColumns.includes(column)) lines.push("        <aggregateTypes>Sum</aggregateTypes>");
    lines.push(`        <field>${esc(column)}</field>`, "    </columns>");
  }
  lines.push(`    <description>${esc(description)}</description>`);
  if (filters.length) {
    lines.push("    <filter>");
    if (booleanFilter) lines.push(`        <booleanFilter>${esc(booleanFilter)}</booleanFilter>`);
    for (const filter of filters) {
      lines.push(
        "        <criteriaItems>",
        `            <column>${esc(filter.column)}</column>`,
        "            <columnToColumn>false</columnToColumn>",
        `            <isUnlocked>${filter.isUnlocked === false ? "false" : "true"}</isUnlocked>`,
        `            <operator>${filter.operator || "equals"}</operator>`,
        `            <value>${esc(filter.value)}</value>`,
        "        </criteriaItems>"
      );
    }
    lines.push("    </filter>");
  }
  lines.push(`    <format>${groupings.length ? "Summary" : "Tabular"}</format>`);
  for (const grouping of groupings) {
    lines.push(
      "    <groupingsDown>",
      "        <dateGranularity>Day</dateGranularity>",
      `        <field>${esc(grouping)}</field>`,
      "        <sortOrder>Asc</sortOrder>",
      "    </groupingsDown>"
    );
  }
  lines.push(
    `    <name>${esc(name)}</name>`,
    "    <params>",
    "        <name>co</name>",
    "        <value>1</value>",
    "    </params>",
    `    <reportType>${reportType}</reportType>`,
    `    <scope>${reportType === "LeadList" ? "org" : "organization"}</scope>`,
    "    <showDetails>true</showDetails>",
    "    <showGrandTotal>true</showGrandTotal>",
    "    <showSubTotals>true</showSubTotals>",
    `    <sortColumn>${esc(sortColumn)}</sortColumn>`,
    `    <sortOrder>${esc(sortOrder)}</sortOrder>`,
    "    <timeFrameFilter>",
    `        <dateColumn>${esc(timeColumn)}</dateColumn>`,
    `        <interval>${esc(timeInterval)}</interval>`
  );
  if (resolvedStartDate) lines.push(`        <startDate>${esc(resolvedStartDate)}</startDate>`);
  lines.push(
    "    </timeFrameFilter>",
    "</Report>",
    ""
  );
  return lines.join("\n");
}

const reportFolder = path.join(md, "reports", "NTE_Operations");
write(path.join(md, "reports", "NTE_Operations.reportFolder-meta.xml"), [
  '<?xml version="1.0" encoding="UTF-8"?>',
  `<ReportFolder xmlns="${ns}">`,
  "    <folderShares>",
  "        <accessLevel>View</accessLevel>",
  "        <sharedTo>AllInternalUsers</sharedTo>",
  "        <sharedToType>Organization</sharedToType>",
  "    </folderShares>",
  "    <name>NTE Operations &amp; Finance</name>",
  "</ReportFolder>",
  ""
].join("\n"));

const nteReports = {
  NTE_01_Guest_Check_In_and_Accessibility: {
    name: "NTE 01 - Guest Check-in & Accessibility",
    description: "On-the-day guest register, accompanying guest details and accessibility arrangements for every NTE edition.",
    reportType: "LeadList",
    columns: ["Lead.NTE_Event_Code__c", "FIRST_NAME", "LAST_NAME", "COMPANY", "TITLE", "EMAIL", "PHONE", "Lead.Guest_Accompanying__c", "Lead.Accompanying_Guest_Name__c", "Lead.Accompanying_Guest_Email__c", "Lead.Guest_Accessibility_Required__c", "Lead.Guest_Accessibility_Details__c", "Lead.Guest_Information_Declaration__c", "STATUS", "OWNER", "CREATED_DATE"],
    filters: [{column: "Lead.Web_Form_Type__c", value: "Guest Registration"}],
    groupings: ["Lead.NTE_Event_Code__c"],
    timeColumn: "CREATED_DATE",
    sortColumn: "LAST_NAME"
  },
  NTE_02_Partner_Sponsor_Event_Operations: {
    name: "NTE 02 - Partner Sponsor Operations",
    description: "Complete partner and sponsor operating sheet covering contacts, packages, confirmed value, previous events, staff, stand needs, accessibility and vehicle logistics.",
    reportType: "Opportunity",
    columns: ["Opportunity.NTE_Event_Code__c", "ACCOUNT_NAME", "OPPORTUNITY_NAME", "Opportunity.Booking_Reference__c", "STAGE_NAME", "Opportunity.NTE_Attendance_Status__c", "Opportunity.NTE_Sponsor_Package__c", "Opportunity.NTE_Sponsor_Package_Total__c", "Opportunity.NTE_Previous_Events__c", "Opportunity.NTE_Event_Contact_Name__c", "Opportunity.NTE_Event_Contact_Title__c", "Opportunity.NTE_Event_Contact_Email__c", "Opportunity.NTE_Event_Contact_Mobile__c", "Opportunity.NTE_Secondary_Contact_Name__c", "Opportunity.NTE_Secondary_Contact_Email__c", "Opportunity.NTE_Secondary_Contact_Mobile__c", "Opportunity.NTE_Stand_Colleagues__c", "Opportunity.NTE_Planned_Exhibitor_Count__c", "Opportunity.NTE_Additional_Staff_Required__c", "Opportunity.NTE_Additional_Staff_Count__c", "Opportunity.NTE_Additional_Staff_Unit_Price__c", "Opportunity.NTE_Additional_Staff_Total__c", "Opportunity.NTE_Listed_Price_Total__c", "Opportunity.NTE_Pricing_Status__c", "Opportunity.NTE_Confirmed_Value__c", "Opportunity.NTE_Invoice_Required__c", "Opportunity.NTE_Quote_Required_for_PO__c", "Opportunity.NTE_Quote_Provided__c", "Opportunity.NTE_Invoice_Provided__c", "Opportunity.NTE_Payment_Received__c", "Opportunity.NTE_Stand_Power__c", "Opportunity.NTE_Stand_Equipment__c", "Opportunity.NTE_Stand_Special_Requirements__c", "Opportunity.NTE_Stand_Extra_Notes__c", "Opportunity.NTE_Exhibitor_Hall_Schedule__c", "Opportunity.NTE_Heavy_Vehicle_Required__c", "Opportunity.NTE_Delivery_Window__c", "Opportunity.NTE_Heavy_Item_1_Description__c", "Opportunity.NTE_Heavy_Item_1_Registration__c", "Opportunity.NTE_Heavy_Item_2_Description__c", "Opportunity.NTE_Heavy_Item_2_Registration__c", "Opportunity.NTE_Heavy_Item_3_Description__c", "Opportunity.NTE_Heavy_Item_3_Registration__c", "Opportunity.NTE_Haulier_Name__c", "Opportunity.NTE_Haulier_Staff__c", "Opportunity.NTE_Haulier_Vehicle_Type__c", "Opportunity.NTE_Haulier_Vehicle_Registration__c", "Opportunity.NTE_Last_Update_Processed_At__c", "FULL_NAME"],
    filters: [{column: "Opportunity.NTE_Source_Form_Type__c", value: "Partner / Sponsor Application"}, {column: "STAGE_NAME", operator: "notEqual", value: "Closed Lost"}],
    groupings: ["Opportunity.NTE_Event_Code__c"],
    timeColumn: "CLOSE_DATE",
    sortColumn: "ACCOUNT_NAME",
    amountColumns: ["Opportunity.NTE_Sponsor_Package_Total__c", "Opportunity.NTE_Additional_Staff_Total__c", "Opportunity.NTE_Listed_Price_Total__c", "Opportunity.NTE_Confirmed_Value__c"]
  },
  NTE_03_Exhibitor_Event_Operations: {
    name: "NTE 03 - Exhibitor Event Operations",
    description: "Complete exhibitor operating sheet for check-in, confirmed value, space allocation, power, sockets, equipment, staff, accessibility, setup and vehicle logistics.",
    reportType: "Opportunity",
    columns: ["Opportunity.NTE_Event_Code__c", "ACCOUNT_NAME", "OPPORTUNITY_NAME", "Opportunity.Booking_Reference__c", "STAGE_NAME", "Opportunity.NTE_Attendance_Status__c", "Opportunity.NTE_Exhibitor_Organisation_Category__c", "Opportunity.NTE_Exhibitor_Space_Selections__c", "Opportunity.NTE_Exhibitor_Space_Price__c", "Opportunity.NTE_Previous_Events__c", "Opportunity.NTE_Event_Contact_Name__c", "Opportunity.NTE_Event_Contact_Email__c", "Opportunity.NTE_Event_Contact_Mobile__c", "Opportunity.NTE_Secondary_Contact_Name__c", "Opportunity.NTE_Secondary_Contact_Email__c", "Opportunity.NTE_Secondary_Contact_Mobile__c", "Opportunity.NTE_Stand_Colleagues__c", "Opportunity.NTE_Planned_Exhibitor_Count__c", "Opportunity.NTE_Additional_Staff_Required__c", "Opportunity.NTE_Additional_Staff_Count__c", "Opportunity.NTE_Additional_Staff_Unit_Price__c", "Opportunity.NTE_Additional_Staff_Total__c", "Opportunity.NTE_Stand_Power__c", "Opportunity.NTE_Power_Socket_Count__c", "Opportunity.NTE_Power_Socket_Unit_Price__c", "Opportunity.NTE_Power_Socket_Total__c", "Opportunity.NTE_Listed_Price_Total__c", "Opportunity.NTE_Pricing_Status__c", "Opportunity.NTE_Confirmed_Value__c", "Opportunity.NTE_Invoice_Required__c", "Opportunity.NTE_Quote_Required_for_PO__c", "Opportunity.NTE_Quote_Provided__c", "Opportunity.NTE_Invoice_Provided__c", "Opportunity.NTE_Payment_Received__c", "Opportunity.NTE_Stand_Equipment__c", "Opportunity.NTE_Stand_Special_Requirements__c", "Opportunity.NTE_Stand_Extra_Notes__c", "Opportunity.NTE_Exhibitor_Hall_Schedule__c", "Opportunity.NTE_Heavy_Vehicle_Required__c", "Opportunity.NTE_Delivery_Window__c", "Opportunity.NTE_Heavy_Item_1_Description__c", "Opportunity.NTE_Heavy_Item_1_Registration__c", "Opportunity.NTE_Heavy_Item_2_Description__c", "Opportunity.NTE_Heavy_Item_2_Registration__c", "Opportunity.NTE_Heavy_Item_3_Description__c", "Opportunity.NTE_Heavy_Item_3_Registration__c", "Opportunity.NTE_Haulier_Name__c", "Opportunity.NTE_Haulier_Staff__c", "Opportunity.NTE_Haulier_Vehicle_Type__c", "Opportunity.NTE_Haulier_Vehicle_Registration__c", "Opportunity.NTE_Last_Update_Processed_At__c", "FULL_NAME"],
    filters: [{column: "Opportunity.NTE_Source_Form_Type__c", value: "Exhibitor Application"}, {column: "STAGE_NAME", operator: "notEqual", value: "Closed Lost"}],
    groupings: ["Opportunity.NTE_Event_Code__c"],
    timeColumn: "CLOSE_DATE",
    sortColumn: "ACCOUNT_NAME",
    amountColumns: ["Opportunity.NTE_Exhibitor_Space_Price__c", "Opportunity.NTE_Power_Socket_Count__c", "Opportunity.NTE_Additional_Staff_Total__c", "Opportunity.NTE_Power_Socket_Total__c", "Opportunity.NTE_Listed_Price_Total__c", "Opportunity.NTE_Confirmed_Value__c"]
  },
  NTE_04_Staff_and_Accreditation_Roster: {
    name: "NTE 04 - Staff & Accreditation Roster",
    description: "Partner, sponsor, exhibitor and haulier people roster with primary contacts, expected headcount and accessibility notes.",
    reportType: "Opportunity",
    columns: ["Opportunity.NTE_Event_Code__c", "Opportunity.NTE_Source_Form_Type__c", "ACCOUNT_NAME", "OPPORTUNITY_NAME", "Opportunity.Booking_Reference__c", "Opportunity.NTE_Attendance_Status__c", "Opportunity.NTE_Event_Contact_Name__c", "Opportunity.NTE_Event_Contact_Email__c", "Opportunity.NTE_Event_Contact_Mobile__c", "Opportunity.NTE_Secondary_Contact_Name__c", "Opportunity.NTE_Secondary_Contact_Email__c", "Opportunity.NTE_Secondary_Contact_Mobile__c", "Opportunity.NTE_Stand_Colleagues__c", "Opportunity.NTE_Planned_Exhibitor_Count__c", "Opportunity.NTE_Additional_Staff_Required__c", "Opportunity.NTE_Additional_Staff_Count__c", "Opportunity.NTE_Haulier_Staff__c", "Opportunity.NTE_Has_Special_Requirements__c", "Opportunity.NTE_Stand_Special_Requirements__c", "Opportunity.NTE_Staff_Update_Completed_At__c"],
    filters: [{column: "Opportunity.NTE_Source_Form_Type__c", value: "Partner / Sponsor Application"}, {column: "Opportunity.NTE_Source_Form_Type__c", value: "Exhibitor Application"}, {column: "STAGE_NAME", operator: "notEqual", value: "Closed Lost"}],
    booleanFilter: "(1 OR 2) AND 3",
    groupings: ["Opportunity.NTE_Event_Code__c", "Opportunity.NTE_Source_Form_Type__c"],
    timeColumn: "CLOSE_DATE",
    sortColumn: "ACCOUNT_NAME"
  },
  NTE_05_Heavy_Vehicles_and_Logistics: {
    name: "NTE 05 - Heavy Vehicles & Logistics",
    description: "All NTE bookings requiring heavy-item or vehicle logistics, with every submitted item, registration, dimension, weight, delivery window and haulier detail.",
    reportType: "Opportunity",
    columns: ["Opportunity.NTE_Event_Code__c", "ACCOUNT_NAME", "OPPORTUNITY_NAME", "Opportunity.Booking_Reference__c", "Opportunity.NTE_Source_Form_Type__c", "Opportunity.NTE_Attendance_Status__c", "Opportunity.NTE_Heavy_Vehicle_Required__c", "Opportunity.NTE_Event_Contact_Name__c", "Opportunity.NTE_Event_Contact_Email__c", "Opportunity.NTE_Event_Contact_Mobile__c", "Opportunity.NTE_Secondary_Contact_Name__c", "Opportunity.NTE_Secondary_Contact_Email__c", "Opportunity.NTE_Secondary_Contact_Mobile__c", "Opportunity.NTE_Delivery_Window__c", "Opportunity.NTE_Heavy_Item_1_Description__c", "Opportunity.NTE_Heavy_Item_1_Registration__c", "Opportunity.NTE_Heavy_Item_1_Dimensions__c", "Opportunity.NTE_Heavy_Item_1_Gross_Weight__c", "Opportunity.NTE_Heavy_Item_2_Description__c", "Opportunity.NTE_Heavy_Item_2_Registration__c", "Opportunity.NTE_Heavy_Item_2_Dimensions__c", "Opportunity.NTE_Heavy_Item_2_Gross_Weight__c", "Opportunity.NTE_Heavy_Item_3_Description__c", "Opportunity.NTE_Heavy_Item_3_Registration__c", "Opportunity.NTE_Heavy_Item_3_Dimensions__c", "Opportunity.NTE_Heavy_Item_3_Gross_Weight__c", "Opportunity.NTE_Haulier_Name__c", "Opportunity.NTE_Haulier_Staff__c", "Opportunity.NTE_Haulier_Vehicle_Type__c", "Opportunity.NTE_Haulier_Vehicle_Registration__c", "Opportunity.NTE_Haulier_Vehicle_Dimensions__c", "Opportunity.NTE_Haulier_Vehicle_Gross_Weight__c", "Opportunity.NTE_Last_Update_Processed_At__c", "Opportunity.NTE_Heavy_Vehicle_Update_Completed_At__c"],
    filters: [{column: "Opportunity.NTE_Heavy_Vehicle_Required__c", value: "Yes"}, {column: "STAGE_NAME", operator: "notEqual", value: "Closed Lost"}],
    groupings: ["Opportunity.NTE_Event_Code__c"],
    timeColumn: "CLOSE_DATE",
    sortColumn: "ACCOUNT_NAME"
  },
  NTE_06_Finance_and_Invoicing: {
    name: "NTE 06 - Finance & Invoicing",
    description: "NTE finance work with pricing checks, quotations, booking and staff top-up charges, payment milestones and billing details. Confirmed value includes VAT. Package and item columns exclude VAT; VAT and gross totals are shown separately.",
    reportType: "Opportunity",
    columns: ["Opportunity.NTE_Event_Code__c", "Opportunity.NTE_Source_Form_Type__c", "ACCOUNT_NAME", "OPPORTUNITY_NAME", "Opportunity.Booking_Reference__c", "STAGE_NAME", "Opportunity.NTE_Sponsor_Package__c", "Opportunity.NTE_Sponsor_Package_Total__c", "Opportunity.NTE_Exhibitor_Space_Selections__c", "Opportunity.NTE_Exhibitor_Space_Price__c", "Opportunity.NTE_Power_Socket_Count__c", "Opportunity.NTE_Power_Socket_Unit_Price__c", "Opportunity.NTE_Power_Socket_Total__c", "Opportunity.NTE_Additional_Staff_Count__c", "Opportunity.NTE_Additional_Staff_Unit_Price__c", "Opportunity.NTE_Additional_Staff_Total__c", "Opportunity.NTE_Listed_Price_Total__c", "Opportunity.NTE_Pricing_Status__c", "Opportunity.NTE_Pricing_Version__c", "Opportunity.NTE_Confirmed_Value__c", "Opportunity.NTE_Invoice_Required__c", "Opportunity.NTE_Quote_Required_for_PO__c", "Opportunity.NTE_Quote_Provided__c", "Opportunity.NTE_Quote_Provided_At__c", "Opportunity.NTE_Quote_Provided_By__c", "Opportunity.NTE_Invoice_Provided__c", "Opportunity.NTE_Invoice_Provided_At__c", "Opportunity.NTE_Invoice_Provided_By__c", "Opportunity.NTE_Payment_Received__c", "Opportunity.NTE_Payment_Received_At__c", "Opportunity.NTE_Payment_Recorded_By__c", "Opportunity.NTE_Invoiced_Company__c", "Opportunity.NTE_Trading_Name__c", "Opportunity.NTE_Invoiced_Person__c", "Opportunity.NTE_Invoice_Address__c", "Opportunity.NTE_Invoiced_Email__c", "Opportunity.NTE_Invoice_Contact_Phone__c", "Opportunity.NTE_Purchase_Order__c", "Opportunity.NTE_Purchase_Order_Number__c", "Opportunity.NTE_Invoice_Additional_Information__c", "Opportunity.NTE_Supplier_Agreement_Required__c", "CLOSE_DATE", "FULL_NAME"],
    filters: [
      {column: "Opportunity.NTE_Invoice_Required__c", value: "Yes"},
      {column: "Opportunity.NTE_Listed_Price_Total__c", operator: "greaterThan", value: "0"},
      {column: "Opportunity.NTE_Top_Up_Invoice_Required__c", value: "true"},
      {column: "Opportunity.NTE_Top_Up_Staff_Total__c", operator: "greaterThan", value: "0"},
      {column: "STAGE_NAME", operator: "notEqual", value: "Closed Lost"}
    ],
    booleanFilter: "(1 OR 2 OR 3 OR 4) AND 5",
    groupings: ["Opportunity.NTE_Event_Code__c", "Opportunity.NTE_Source_Form_Type__c"],
    timeColumn: "CLOSE_DATE",
    sortColumn: "ACCOUNT_NAME",
    amountColumns: ["Opportunity.NTE_Sponsor_Package_Total__c", "Opportunity.NTE_Exhibitor_Space_Price__c", "Opportunity.NTE_Power_Socket_Total__c", "Opportunity.NTE_Additional_Staff_Total__c", "Opportunity.NTE_Listed_Price_Total__c", "Opportunity.NTE_Confirmed_Value__c"]
  },
  NTE_07_Application_and_EOI_Pipeline: {
    name: "NTE 07 - Application & EOI Pipeline",
    description: "Unconverted NTE expressions of interest and applications, including recorded decisions, package choices, price components and finance requirements.",
    reportType: "LeadList",
    columns: ["Lead.NTE_Event_Code__c", "Lead.Web_Form_Type__c", "FIRST_NAME", "LAST_NAME", "COMPANY", "TITLE", "EMAIL", "PHONE", "Lead.Booking_Reference__c", "STATUS", "OWNER", "Lead.NTE_Interest_Progressed__c", "Lead.NTE_Interest_Not_Progressed__c", "Lead.NTE_Application_Rejected__c", "Lead.Organisation_Type__c", "Lead.Partner_Interest_Type__c", "Lead.Partner_Interest_Areas__c", "Lead.Exhibitor_Interest_Detail__c", "Lead.Exhibitor_Community_Contribution__c", "Lead.Sponsor_Package__c", "Lead.Exhibitor_Organisation_Category__c", "Lead.Exhibitor_Space_Selections__c", "Lead.Sponsor_Package_Total__c", "Lead.Exhibitor_Space_Price__c", "Lead.Power_Socket_Count__c", "Lead.Power_Socket_Unit_Price__c", "Lead.Power_Socket_Total__c", "Lead.Additional_Staff_Count__c", "Lead.Additional_Staff_Unit_Price__c", "Lead.Additional_Staff_Total__c", "Lead.Listed_Price_Total__c", "Lead.Pricing_Status__c", "Lead.Invoice_Required__c", "Lead.Quote_Required_for_PO__c", "Lead.NTE_Applicant_Email_Status__c", "Lead.NTE_Internal_Email_Status__c", "CREATED_DATE"],
    filters: [{column: "Lead.Web_Form_Type__c", value: "Partner / Sponsor Expression of Interest"}, {column: "Lead.Web_Form_Type__c", value: "Exhibitor Expression of Interest"}, {column: "Lead.Web_Form_Type__c", value: "Partner / Sponsor Application"}, {column: "Lead.Web_Form_Type__c", value: "Exhibitor Application"}, {column: "CONVERTED", value: "false"}],
    booleanFilter: "(1 OR 2 OR 3 OR 4) AND 5",
    groupings: ["Lead.NTE_Event_Code__c", "Lead.Web_Form_Type__c"],
    timeColumn: "CREATED_DATE",
    sortColumn: "CREATED_DATE",
    amountColumns: ["Lead.Sponsor_Package_Total__c", "Lead.Exhibitor_Space_Price__c", "Lead.Power_Socket_Total__c", "Lead.Additional_Staff_Total__c", "Lead.Listed_Price_Total__c"]
  },
  NTE_08_Event_Delivery_Readiness: {
    name: "NTE 08 - Event Delivery Readiness",
    description: "Cross-event NTE booking readiness, including primary and event contacts, staffing, logistics, logos, finance and final-pack history.",
    reportType: "Opportunity",
    columns: ["Opportunity.NTE_Event_Code__c", "Opportunity.NTE_Source_Form_Type__c", "ACCOUNT_NAME", "OPPORTUNITY_NAME", "Opportunity.Booking_Reference__c", "STAGE_NAME", "Opportunity.NTE_Attendance_Status__c", "Opportunity.NTE_Event_Contact_Name__c", "Opportunity.NTE_Event_Contact_Mobile__c", "Opportunity.NTE_Stand_Colleagues__c", "Opportunity.NTE_Planned_Exhibitor_Count__c", "Opportunity.NTE_Staff_Update_Completed_At__c", "Opportunity.NTE_Exhibitor_Space_Selections__c", "Opportunity.NTE_Stand_Power__c", "Opportunity.NTE_Power_Socket_Count__c", "Opportunity.NTE_Stand_Equipment__c", "Opportunity.NTE_Has_Special_Requirements__c", "Opportunity.NTE_Stand_Special_Requirements__c", "Opportunity.NTE_Heavy_Vehicle_Required__c", "Opportunity.NTE_Heavy_Vehicle_Update_Completed_At__c", "Opportunity.NTE_Last_Update_Type__c", "Opportunity.NTE_Last_Update_Processed_At__c", "Opportunity.NTE_Listed_Price_Total__c", "Opportunity.NTE_Pricing_Status__c", "Opportunity.NTE_Invoice_Required__c", "Opportunity.NTE_Quote_Required_for_PO__c", "Opportunity.NTE_Quote_Provided__c", "Opportunity.NTE_Invoice_Provided__c", "Opportunity.NTE_Payment_Received__c", "Opportunity.NTE_Confirmed_Value__c", "FULL_NAME"],
    filters: [{column: "Opportunity.NTE_Source_Form_Type__c", value: "Partner / Sponsor Application"}, {column: "Opportunity.NTE_Source_Form_Type__c", value: "Exhibitor Application"}, {column: "STAGE_NAME", operator: "notEqual", value: "Closed Lost"}],
    booleanFilter: "(1 OR 2) AND 3",
    groupings: ["Opportunity.NTE_Event_Code__c", "Opportunity.NTE_Source_Form_Type__c"],
    timeColumn: "CLOSE_DATE",
    sortColumn: "ACCOUNT_NAME",
    amountColumns: ["Opportunity.NTE_Listed_Price_Total__c", "Opportunity.NTE_Confirmed_Value__c"]
  },
  NTE_09_Weekly_Finance_Report: {
    name: "Weekly Finance Report",
    description: "Rolling seven-day Finance handoff for recently changed NTE bookings, with current quotation, invoice, payment, billing-contact and confirmed-value details. Use NTE 06 - Finance & Invoicing for the complete all-time finance view.",
    reportType: "Opportunity",
    columns: [
      "Opportunity.NTE_Event_Code__c",
      "Opportunity.NTE_Source_Form_Type__c",
      "ACCOUNT_NAME",
      "OPPORTUNITY_NAME",
      "Opportunity.Booking_Reference__c",
      "STAGE_NAME",
      "Opportunity.NTE_Sponsor_Package__c",
      "Opportunity.NTE_Sponsor_Package_Total__c",
      "Opportunity.NTE_Exhibitor_Space_Selections__c",
      "Opportunity.NTE_Exhibitor_Space_Price__c",
      "Opportunity.NTE_Power_Socket_Count__c",
      "Opportunity.NTE_Power_Socket_Unit_Price__c",
      "Opportunity.NTE_Power_Socket_Total__c",
      "Opportunity.NTE_Initial_Staff_Count__c",
      "Opportunity.NTE_Included_Staff_Count__c",
      "Opportunity.NTE_Additional_Staff_Count__c",
      "Opportunity.NTE_Additional_Staff_Unit_Price__c",
      "Opportunity.NTE_Additional_Staff_Total__c",
      "Opportunity.NTE_Total_Staff_Count__c",
      "Opportunity.NTE_Top_Up_Staff_Required__c",
      "Opportunity.NTE_Top_Up_Staff_Count__c",
      "Opportunity.NTE_Top_Up_Staff_Unit_Price__c",
      "Opportunity.NTE_Top_Up_Staff_Total__c",
      "Opportunity.NTE_Listed_Price_Total__c",
      "Opportunity.NTE_Confirmed_Value__c",
      "Opportunity.NTE_Pricing_Status__c",
      "Opportunity.NTE_Pricing_Version__c",
      "Opportunity.NTE_Invoice_Required__c",
      "Opportunity.NTE_Payment_Method__c",
      "Opportunity.NTE_Invoice_Requested__c",
      "Opportunity.NTE_Quote_Required_for_PO__c",
      "Opportunity.NTE_Quote_Provided__c",
      "Opportunity.NTE_Quote_Provided_At__c",
      "Opportunity.NTE_Quote_Provided_By__c",
      "Opportunity.NTE_Invoice_Provided__c",
      "Opportunity.NTE_Invoice_Provided_At__c",
      "Opportunity.NTE_Invoice_Provided_By__c",
      "Opportunity.NTE_Payment_Received__c",
      "Opportunity.NTE_Payment_Received_At__c",
      "Opportunity.NTE_Payment_Recorded_By__c",
      "Opportunity.NTE_Top_Up_Invoice_Required__c",
      "Opportunity.NTE_Top_Up_Invoice_Provided__c",
      "Opportunity.NTE_Top_Up_Invoice_At__c",
      "Opportunity.NTE_Top_Up_Invoice_By__c",
      "Opportunity.NTE_Top_Up_Payment_Received__c",
      "Opportunity.NTE_Top_Up_Payment_At__c",
      "Opportunity.NTE_Top_Up_Payment_By__c",
      "Opportunity.NTE_Invoiced_Company__c",
      "Opportunity.NTE_Trading_Name__c",
      "Opportunity.NTE_Invoiced_Person__c",
      "Opportunity.NTE_Invoice_Address__c",
      "Opportunity.NTE_Invoiced_Email__c",
      "Opportunity.NTE_Invoice_Contact_Phone__c",
      "Opportunity.NTE_Purchase_Order__c",
      "Opportunity.NTE_Purchase_Order_Number__c",
      "Opportunity.NTE_Supplier_Agreement_Required__c",
      "Opportunity.NTE_Invoice_Additional_Information__c",
      "LAST_UPDATE",
      "FULL_NAME"
    ],
    filters: [
      {column: "Opportunity.NTE_Invoice_Required__c", value: "Yes"},
      {column: "Opportunity.NTE_Listed_Price_Total__c", operator: "greaterThan", value: "0"},
      {column: "Opportunity.NTE_Top_Up_Invoice_Required__c", value: "true"},
      {column: "Opportunity.NTE_Top_Up_Staff_Total__c", operator: "greaterThan", value: "0"},
      {column: "STAGE_NAME", operator: "notEqual", value: "Closed Lost"}
    ],
    booleanFilter: "(1 OR 2 OR 3 OR 4) AND 5",
    groupings: ["Opportunity.NTE_Event_Code__c", "Opportunity.NTE_Source_Form_Type__c"],
    timeColumn: "LAST_UPDATE",
    timeInterval: "INTERVAL_LAST7",
    sortColumn: "LAST_UPDATE",
    sortOrder: "Desc",
    amountColumns: [
      "Opportunity.NTE_Sponsor_Package_Total__c",
      "Opportunity.NTE_Exhibitor_Space_Price__c",
      "Opportunity.NTE_Power_Socket_Total__c",
      "Opportunity.NTE_Additional_Staff_Total__c",
      "Opportunity.NTE_Top_Up_Staff_Total__c",
      "Opportunity.NTE_Listed_Price_Total__c",
      "Opportunity.NTE_Confirmed_Value__c"
    ]
  }
};
for (const reportApi of ["NTE_02_Partner_Sponsor_Event_Operations", "NTE_03_Exhibitor_Event_Operations", "NTE_06_Finance_and_Invoicing", "NTE_08_Event_Delivery_Readiness"]) {
  const columns = nteReports[reportApi].columns;
  const invoiceIndex = columns.indexOf("Opportunity.NTE_Invoice_Required__c");
  if (invoiceIndex >= 0) columns.splice(invoiceIndex + 1, 0, "Opportunity.NTE_Payment_Method__c", "Opportunity.NTE_Invoice_Requested__c");
}
const topUpReportColumns = [
  "Opportunity.NTE_Initial_Staff_Count__c",
  "Opportunity.NTE_Included_Staff_Count__c",
  "Opportunity.NTE_Total_Staff_Count__c",
  "Opportunity.NTE_Top_Up_Staff_Required__c",
  "Opportunity.NTE_Top_Up_Staff_Count__c",
  "Opportunity.NTE_Top_Up_Staff_Names__c",
  "Opportunity.NTE_Top_Up_Staff_Unit_Price__c",
  "Opportunity.NTE_Top_Up_Staff_Total__c",
  "Opportunity.NTE_Top_Up_Invoice_Required__c",
  "Opportunity.NTE_Top_Up_Invoice_Provided__c",
  "Opportunity.NTE_Top_Up_Invoice_At__c",
  "Opportunity.NTE_Top_Up_Invoice_By__c",
  "Opportunity.NTE_Top_Up_Payment_Received__c",
  "Opportunity.NTE_Top_Up_Payment_At__c",
  "Opportunity.NTE_Top_Up_Payment_By__c"
];
for (const reportApi of ["NTE_02_Partner_Sponsor_Event_Operations", "NTE_03_Exhibitor_Event_Operations", "NTE_04_Staff_and_Accreditation_Roster", "NTE_06_Finance_and_Invoicing", "NTE_08_Event_Delivery_Readiness"]) {
  const report = nteReports[reportApi];
  const insertAt = Math.max(0, report.columns.indexOf("Opportunity.NTE_Confirmed_Value__c"));
  report.columns.splice(insertAt, 0, ...topUpReportColumns.filter((column) => !report.columns.includes(column)));
}
for (const reportApi of ["NTE_02_Partner_Sponsor_Event_Operations", "NTE_03_Exhibitor_Event_Operations", "NTE_06_Finance_and_Invoicing", "NTE_08_Event_Delivery_Readiness"]) {
  const amountColumns = nteReports[reportApi].amountColumns;
  if (amountColumns && !amountColumns.includes("Opportunity.NTE_Top_Up_Staff_Total__c")) {
    amountColumns.splice(Math.max(0, amountColumns.length - 1), 0, "Opportunity.NTE_Top_Up_Staff_Total__c");
  }
}
{
  const columns = nteReports.NTE_07_Application_and_EOI_Pipeline.columns;
  const invoiceIndex = columns.indexOf("Lead.Invoice_Required__c");
  if (invoiceIndex >= 0) columns.splice(invoiceIndex + 1, 0, "Lead.Payment_Method__c", "Lead.Invoice_Requested__c");
}
for (const reportApi of ["NTE_02_Partner_Sponsor_Event_Operations", "NTE_03_Exhibitor_Event_Operations", "NTE_08_Event_Delivery_Readiness"]) {
  const report = nteReports[reportApi];
  report.columns.push("Opportunity.NTE_Logo_Update_Provided__c", "Opportunity.NTE_Logo_Update_Provided_At__c", "Opportunity.NTE_Final_Pack_Status__c", "Opportunity.NTE_Final_Pack_Sent_At__c");
}
for (const reportApi of ["NTE_06_Finance_and_Invoicing", "NTE_09_Weekly_Finance_Report"]) {
  const report = nteReports[reportApi];
  report.filters.push({column: "Opportunity.NTE_Quote_Required_for_PO__c", value: "Yes"}, {column: "Opportunity.NTE_Pricing_Ready__c", value: "false"});
  report.booleanFilter = "(1 OR 2 OR 3 OR 4 OR 6 OR 7) AND 5";
  report.columns.push("Opportunity.NTE_Pricing_Ready__c", "Opportunity.NTE_Finance_Payment_Due__c", "Opportunity.NTE_Finance_Payment_Confirmed__c");
}
for (const definition of Object.values(nteReports)) {
  if (definition.reportType !== "Opportunity") continue;
  // Salesforce's CONTACT column is the Primary Contact; FULL_NAME is the owner.
  definition.columns.splice(Math.max(0, definition.columns.indexOf("ACCOUNT_NAME") + 1), 0, "CONTACT");
  const lostStageIndex = definition.filters.findIndex(filter => filter.column === "STAGE_NAME" && filter.operator === "notEqual" && filter.value === "Closed Lost");
  if (lostStageIndex >= 0) {
    const previousLogic = definition.booleanFilter || definition.filters.map((_, index) => index + 1).join(" AND ");
    const closedFilterIndex = lostStageIndex + 1;
    const wonFilterIndex = definition.filters.length + 1;
    definition.filters[lostStageIndex] = {column: "CLOSED", value: "false"};
    definition.filters.push({column: "WON", value: "true"});
    definition.booleanFilter = previousLogic.replace(/\d+/g, index => Number(index) === closedFilterIndex ? `(${closedFilterIndex} OR ${wonFilterIndex})` : index);
  }
  const recordTypeFilterIndex = definition.filters.length + 1;
  if (definition.booleanFilter) {
    definition.booleanFilter = `(${definition.booleanFilter}) AND ${recordTypeFilterIndex}`;
  }
  definition.filters.push({
    column: "RECORDTYPE",
    value: "Opportunity.NTE_Event_Opportunity",
    isUnlocked: false
  });
}
for (const definition of Object.values(nteReports)) {
  for (const [net, extras] of [
    ["Lead.Listed_Price_Total__c", ["Lead.VAT_Rate__c", "Lead.VAT_Total__c", "Lead.Total_Including_VAT__c"]],
    ["Opportunity.NTE_Listed_Price_Total__c", ["Opportunity.NTE_Price_Adjustment__c", "Opportunity.NTE_VAT_Rate__c", "Opportunity.NTE_VAT_Total__c", "Opportunity.NTE_Total_Including_VAT__c"]],
    ["Opportunity.NTE_Top_Up_Staff_Total__c", ["Opportunity.NTE_Top_Up_VAT_Total__c", "Opportunity.NTE_Top_Up_Total_Inc_VAT__c"]]
  ]) {
    if (!definition.columns.includes(net)) continue;
    definition.columns.splice(definition.columns.indexOf(net) + 1, 0, ...extras);
    if (definition.amountColumns) definition.amountColumns.push(...extras.filter(field => !field.endsWith("Rate__c")));
  }
}
for (const name of ["NTE_06_Finance_and_Invoicing", "NTE_09_Weekly_Finance_Report"]) {
  const report = nteReports[name];
  report.columns.push(...["Opportunity.NTE_Finance_Requirements_Due__c", "Opportunity.NTE_Finance_Payment_Due__c", "Opportunity.NTE_Finance_Payment_Confirmed__c", "Opportunity.NTE_PO_Confirmed__c", "Opportunity.NTE_Agreement_Provided__c", "Opportunity.NTE_Invoice_Details_Included__c", "Opportunity.NTE_Bank_Details_Provided__c", "Opportunity.NTE_Approval_Email_Sent_At__c", "Opportunity.NTE_Top_Up_Payment_Requested_At__c"]);
  report.columns = [...new Set(report.columns)];
  report.filters = [{column: "CLOSED", value: "false"}, {column: "WON", value: "true"}, {column: "RECORDTYPE", value: "Opportunity.NTE_Event_Opportunity", isUnlocked: false}, {column: "Opportunity.NTE_Event_Code__c", operator: "notEqual", value: ""}, {column: "Opportunity.NTE_Source_Form_Type__c", value: "Exhibitor Application"}, {column: "Opportunity.NTE_Source_Form_Type__c", value: "Partner / Sponsor Application"}];
  report.booleanFilter = "(1 OR 2) AND 3 AND 4 AND (5 OR 6)";
}
for (const [api, definition] of Object.entries(nteReports)) write(path.join(reportFolder, `${api}.report-meta.xml`), reportXml(definition));

function appendObjectPermissions(lines, objectNames) {
  for (const objectName of objectNames) {
    lines.push(
      "    <objectPermissions>",
      "        <allowCreate>true</allowCreate>",
      "        <allowDelete>false</allowDelete>",
      "        <allowEdit>true</allowEdit>",
      "        <allowRead>true</allowRead>",
      "        <modifyAllRecords>false</modifyAllRecords>",
      `        <object>${objectName}</object>`,
      "        <viewAllFields>false</viewAllFields>",
      "        <viewAllRecords>false</viewAllRecords>",
      "    </objectPermissions>"
    );
  }
}

const permissionLines = [
  '<?xml version="1.0" encoding="UTF-8"?>',
  `<PermissionSet xmlns="${ns}">`,
  "    <applicationVisibilities><application>NTE_Management</application><visible>true</visible></applicationVisibilities>",
  "    <description>Manage NTE forms, bookings and finance.</description>"
];
for (const [objectName, fields] of [["Lead", [...leadFields, ...existingLeadFields]], ["Opportunity", opportunityFields], ["Account", accountFields], ["Contact", contactFields]]) {
  [...new Map(fields.map((field) => [field.api, field])).values()].forEach((field) => permissionLines.push(
    "    <fieldPermissions>",
    `        <editable>${field.formula || field.readOnly ? "false" : "true"}</editable>`,
    `        <field>${objectName}.${field.api}</field>`,
    "        <readable>true</readable>",
    "    </fieldPermissions>"
  ));
}
[...new Set(reusedLeadFieldApis)].filter((api) => ![...leadFields, ...existingLeadFields].some((field) => field.api === api)).forEach((api) => permissionLines.push(
  "    <fieldPermissions>",
  "        <editable>true</editable>",
  `        <field>Lead.${api}</field>`,
  "        <readable>true</readable>",
  "    </fieldPermissions>"
));
permissionLines.push(
  "    <classAccesses><apexClass>NTE_MasterPanelController</apexClass><enabled>true</enabled></classAccesses>",
  "    <classAccesses>",
  "        <apexClass>NTEExhibitorApprovalEmailService</apexClass>",
  "        <enabled>true</enabled>",
  "    </classAccesses>",
  "    <classAccesses>",
  "        <apexClass>NTERelatedOpportunityController</apexClass>",
  "        <enabled>true</enabled>",
  "    </classAccesses>",
  "    <recordTypeVisibilities>",
  "        <recordType>Opportunity.NTE_Event_Opportunity</recordType>",
  "        <visible>true</visible>",
  "    </recordTypeVisibilities>"
);
appendObjectPermissions(permissionLines, ["Lead", "Account", "Contact", "Opportunity", "Task", "Event"]);
permissionLines.push(
  "    <userPermissions><enabled>true</enabled><name>EditTask</name></userPermissions>",
  "    <userPermissions><enabled>true</enabled><name>ConvertLeads</name></userPermissions>",
  "    <userPermissions><enabled>true</enabled><name>RunReports</name></userPermissions>"
);
permissionLines.push("    <hasActivationRequired>false</hasActivationRequired>", "    <label>NTE Forms Administration</label>", "</PermissionSet>", "");
write(path.join(md, "permissionsets", "NTE_Forms_Administration.permissionset-meta.xml"), permissionLines.join("\n"));

const managementPermissionLines = [
  '<?xml version="1.0" encoding="UTF-8"?>',
  `<PermissionSet xmlns="${ns}">`,
  "    <applicationVisibilities>",
  "        <application>NTE_Management</application>",
  "        <visible>true</visible>",
  "    </applicationVisibilities>",
  "    <description>Access the NTE Management app, its navigation, NTE event records, conversion actions and reports. Sharing continues to control which records are visible.</description>"
];
for (const [objectName, fields] of [["Lead", [...leadFields, ...existingLeadFields]], ["Opportunity", opportunityFields], ["Account", accountFields], ["Contact", contactFields]]) {
  [...new Map(fields.map((field) => [field.api, field])).values()].forEach((field) => managementPermissionLines.push(
    "    <fieldPermissions>",
    `        <editable>${field.formula || field.readOnly ? "false" : "true"}</editable>`,
    `        <field>${objectName}.${field.api}</field>`,
    "        <readable>true</readable>",
    "    </fieldPermissions>"
  ));
}
[...new Set(reusedLeadFieldApis)].filter((api) => ![...leadFields, ...existingLeadFields].some((field) => field.api === api)).forEach((api) => managementPermissionLines.push(
  "    <fieldPermissions>",
  "        <editable>true</editable>",
  `        <field>Lead.${api}</field>`,
  "        <readable>true</readable>",
  "    </fieldPermissions>"
));
managementPermissionLines.push(
  "    <classAccesses>",
  "        <apexClass>NTEExhibitorApprovalEmailService</apexClass>",
  "        <enabled>true</enabled>",
  "    </classAccesses>",
  "    <classAccesses>",
  "        <apexClass>NTE_MasterPanelController</apexClass>",
  "        <enabled>true</enabled>",
  "    </classAccesses>",
  "    <classAccesses>",
  "        <apexClass>NTERelatedOpportunityController</apexClass>",
  "        <enabled>true</enabled>",
  "    </classAccesses>",
  "    <recordTypeVisibilities>",
  "        <recordType>Opportunity.NTE_Event_Opportunity</recordType>",
  "        <visible>true</visible>",
  "    </recordTypeVisibilities>"
);
appendObjectPermissions(managementPermissionLines, ["Lead", "Account", "Contact", "Opportunity", "Task", "Event"]);
for (const tab of ["standard-Lead", "standard-Account", "standard-Contact", "standard-Opportunity", "NTE_Master_Panel"]) {
  managementPermissionLines.push(
    "    <tabSettings>",
    `        <tab>${tab}</tab>`,
    "        <visibility>Visible</visibility>",
    "    </tabSettings>"
  );
}
managementPermissionLines.push(
  "    <userPermissions><enabled>true</enabled><name>EditTask</name></userPermissions>",
  "    <userPermissions><enabled>true</enabled><name>ConvertLeads</name></userPermissions>",
  "    <userPermissions><enabled>true</enabled><name>RunReports</name></userPermissions>",
  "    <hasActivationRequired>false</hasActivationRequired>",
  "    <label>NTE Management User</label>",
  "</PermissionSet>",
  ""
);
write(path.join(md, "permissionsets", "NTE_Management_User.permissionset-meta.xml"), managementPermissionLines.join("\n"));

write(path.join(md, "permissionsetgroups", "NTE_Management_Access.permissionsetgroup-meta.xml"), [
  '<?xml version="1.0" encoding="UTF-8"?>',
  `<PermissionSetGroup xmlns="${ns}">`,
  "    <description>Assign to administrators and authorised staff who manage NTE enquiries, applications, bookings, communications and payments. Uses the configured NTE Stripe test connection.</description>",
  "    <hasActivationRequired>false</hasActivationRequired>",
  "    <label>NTE Management Access</label>",
  "    <permissionSets>NTE_Management_User</permissionSets>",
  "    <permissionSets>NTE_Stripe_Test_Operator</permissionSets>",
  "    <status>Updated</status>",
  "</PermissionSetGroup>",
  ""
].join("\n"));

const volunteerPermissionLines = [
  '<?xml version="1.0" encoding="UTF-8"?>',
  `<PermissionSet xmlns="${ns}">`,
  "    <classAccesses><apexClass>VolunteerInboundLeadService</apexClass><enabled>true</enabled></classAccesses>",
  "    <classAccesses><apexClass>NTELeadEmailRetryService</apexClass><enabled>true</enabled></classAccesses>",
  "    <description>Access Mission Motorsport volunteer applications and their application details.</description>"
];
for (const field of [existingLeadFields[0], ...volunteerLeadFields]) {
  volunteerPermissionLines.push(
    "    <fieldPermissions>",
    "        <editable>true</editable>",
    `        <field>Lead.${field.api}</field>`,
    "        <readable>true</readable>",
    "    </fieldPermissions>"
  );
}
for (const api of reusedVolunteerLeadFieldApis) {
  volunteerPermissionLines.push(
    "    <fieldPermissions>",
    "        <editable>true</editable>",
    `        <field>Lead.${api}</field>`,
    "        <readable>true</readable>",
    "    </fieldPermissions>"
  );
}
volunteerPermissionLines.push(
  "    <objectPermissions>",
  "        <allowCreate>true</allowCreate>",
  "        <allowDelete>false</allowDelete>",
  "        <allowEdit>true</allowEdit>",
  "        <allowRead>true</allowRead>",
  "        <modifyAllRecords>false</modifyAllRecords>",
  "        <object>Lead</object>",
  "        <viewAllFields>false</viewAllFields>",
  "        <viewAllRecords>false</viewAllRecords>",
  "    </objectPermissions>",
  "    <hasActivationRequired>false</hasActivationRequired>",
  "    <label>Volunteer Applications User</label>",
  "</PermissionSet>",
  ""
);
write(path.join(md, "permissionsets", "Volunteer_Applications_User.permissionset-meta.xml"), volunteerPermissionLines.join("\n"));

const templates = {
  NTE_Staff_Top_Up_Payment: ["staff-top-up-payment.html", "Your NTE staff top-up payment", "NTE staff top-up payment request"],
  NTE_Partner_Sponsor_EOI_Acknowledgement: ["partner-sponsor-interest-applicant-confirmation.html", "NTE expression of interest received", "NTE expression of interest acknowledgement"],
  NTE_Partner_Sponsor_EOI_Internal: ["partner-sponsor-interest-internal-notification.html", "New NTE partner / sponsor expression of interest", "Internal NTE expression of interest notification"],
  NTE_Exhibitor_EOI_Acknowledgement: ["exhibitor-interest-applicant-confirmation.html", "NTE exhibitor interest received", "NTE exhibitor expression of interest acknowledgement"],
  NTE_Exhibitor_EOI_Internal: ["exhibitor-interest-internal-notification.html", "New NTE exhibitor expression of interest", "Internal NTE exhibitor expression of interest notification"],
  NTE_Partner_Sponsor_Application_Internal: ["partner-sponsor-application-internal-notification.html", "New NTE partner / sponsor application", "Internal NTE partner / sponsor application notification"],
  NTE_Exhibitor_Application_Internal: ["exhibitor-application-internal-notification.html", "New NTE exhibitor application", "Internal NTE exhibitor application notification"],
  NTE_Guest_Registration_Acknowledgement: ["guest-registration-applicant-confirmation.html", "NTE guest registration received", "NTE guest registration acknowledgement"],
  NTE_Guest_Registration_Internal: ["guest-registration-internal-notification.html", "New NTE guest registration", "Internal NTE guest registration notification"],
  NTE_Exhibitor_Staff_Update_Acknowledgement: ["exhibitor-staff-update-applicant-confirmation.html", "NTE exhibitor staff details updated", "NTE exhibitor staff update acknowledgement"],
  NTE_Partner_Staff_Update_Acknowledgement: ["partner-sponsor-staff-update-applicant-confirmation.html", "NTE partner / sponsor staff details updated", "NTE partner / sponsor staff update acknowledgement"],
  NTE_Heavy_Vehicle_Acknowledgement: ["heavy-vehicle-details-applicant-confirmation.html", "NTE vehicle and logistics details received", "NTE vehicle and logistics acknowledgement"],
  NTE_Partner_Sponsor_Approved: ["partner-sponsor-approved-confirmation.html", "Your NTE space is provisionally reserved", "NTE approved partner / sponsor confirmation"],
  NTE_Partner_Sponsor_Free_Confirmed: ["partner-sponsor-free-confirmed.html", "Your NTE partnership / sponsorship is confirmed", "NTE partner / sponsor waived booking confirmation"],
  NTE_Exhibitor_Approved: ["exhibitor-approved-confirmation.html", "Your NTE space is provisionally reserved", "NTE approved exhibitor confirmation"],
  NTE_Complimentary_Exhibitor_Approved: ["government-charity-approved-confirmation.html", "Your complimentary NTE space is confirmed", "NTE complimentary exhibitor confirmation"],
  NTE_Partner_Sponsor_Payment_Confirmed: ["partner-sponsor-payment-confirmed.html", "Your NTE partnership / sponsorship is confirmed", "NTE partner / sponsor booking payment confirmation"],
  NTE_Exhibitor_Payment_Confirmed: ["exhibitor-payment-confirmed.html", "Your NTE exhibition space is confirmed", "NTE exhibitor booking payment confirmation"],
  Volunteer_Application_Acknowledgement: ["volunteer-application-applicant-confirmation.html", "We’ve received your volunteer application", "Volunteer application acknowledgement"],
  Volunteer_Application_Internal: ["volunteer-application-internal-notification.html", "New volunteer application: {!Lead.FirstName} {!Lead.LastName}", "Internal volunteer application notification"]
};

const emailPreviewValues = {
  Accompanying_Guest_Email__c: "jamie.taylor@example.com",
  Accompanying_Guest_Name__c: "Jamie Taylor",
  Additional_Staff_Count__c: "2",
  Additional_Staff_Required__c: "Yes",
  Additional_Staff_Total__c: "100.00",
  Additional_Staff_Unit_Price__c: "50.00",
  Alternative_Organisation_Name__c: "Horizon Engineering",
  Booking_Reference__c: "NTE-2027-EX-0001",
  Company: "Horizon Mobility Ltd",
  Delivery_Window__c: "Sunday 28 February between 14:00 - 18:00",
  Email: "alex.morgan@example.com",
  Event_Contact_Email__c: "events@horizonmobility.example",
  Event_Contact_Name__c: "Alex Morgan",
  Event_Discovery_Source__c: "Recommendation or word of mouth",
  Exhibitor_Community_Contribution__c: "Free CV workshops, LinkedIn advice and practical STEM activities for attendees.",
  Exhibitor_Hall_Schedule__c: "Yes",
  Exhibitor_Interest_Areas__c: "Automotive and mobility; Manufacturing and engineering",
  Exhibitor_Interest_Detail__c: "Yes",
  Exhibitor_Organisation_Category__c: "Employer - Automotive Sector",
  Exhibitor_Space_Price__c: "799.00",
  Exhibitor_Space_Selections__c: "Single Garage - Paddock Side with power - £799 + VAT",
  FirstName: "Alex",
  Guest_Accessibility_Details__c: "Step-free access and a reserved seat",
  Guest_Accessibility_Required__c: "Yes",
  Guest_Accompanying__c: "Yes",
  Haulier_Name__c: "Silverline Logistics",
  Haulier_Staff__c: "Jordan Lee; Sam Patel",
  Haulier_Vehicle_Dimensions__c: "8.0m × 2.5m × 3.4m",
  Haulier_Vehicle_Gross_Weight__c: "18,000 kg",
  Haulier_Vehicle_Registration__c: "AB27 NTE",
  Haulier_Vehicle_Type__c: "Rigid flatbed lorry",
  Has_Special_Requirements__c: "No",
  Heavy_Item_1_Description__c: "Horizon HX electric demonstration vehicle",
  Heavy_Item_1_Dimensions__c: "4.8m × 2.0m × 1.8m",
  Heavy_Item_1_Gross_Weight__c: "2,400 kg",
  Heavy_Item_1_Registration__c: "HX27 NTE",
  Heavy_Item_2_Description__c: "Battery technology display unit",
  Heavy_Item_2_Dimensions__c: "2.0m × 1.2m × 1.5m",
  Heavy_Item_2_Gross_Weight__c: "650 kg",
  Heavy_Item_2_Registration__c: "Not applicable",
  Heavy_Item_3_Description__c: "Not applicable",
  Heavy_Item_3_Dimensions__c: "Not applicable",
  Heavy_Item_3_Gross_Weight__c: "Not applicable",
  Heavy_Item_3_Registration__c: "Not applicable",
  Heavy_Vehicle_Required__c: "Yes",
  Id: "00Q000000000001AAA",
  Invoice_Additional_Information__c: "Please show the booking reference on all documents.",
  Invoice_Address__c: "10 Innovation Way, Coventry, CV1 2AB",
  Invoice_Contact_Phone__c: "024 7600 1234",
  Invoice_Required__c: "Yes",
  Invoice_Requested__c: "Yes",
  Included_Staff_Count__c: "2",
  Listed_Price_Total__c: "1099.00",
  VAT_Rate__c: String(vatRate), VAT_Total__c: "219.80", Total_Including_VAT__c: "1318.80",
  Top_Up_VAT_Total__c: "20.00", Top_Up_Total_Inc_VAT__c: "120.00",
  Payment_Method__c: "Bank transfer",
  Invoiced_Company__c: "Horizon Mobility Ltd",
  Invoiced_Email__c: "finance@horizonmobility.example",
  Invoiced_Person__c: "Sam Taylor",
  LastName: "Morgan",
  Logo_Upload_URL__c: "https://stevostar1234.github.io/nte27-web-to-lead-demo/logo-upload.html",
  NTE_Event_Code__c: "NTE2027",
  Organisation_Type__c: "Employer - Automotive",
  Partner_Interest_Areas__c: "Strategic event partnership; Event zone sponsorship",
  Partner_Interest_Type__c: "Both - open to discussion",
  Partnership_Interest_Detail__c: "We would like to support employment pathways and engineering opportunities for the Armed Forces community.",
  Phone: "024 7600 1200",
  Planned_Exhibitor_Count__c: "4",
  Power_Socket_Count__c: "2",
  Power_Socket_Total__c: "200.00",
  Power_Socket_Unit_Price__c: "100.00",
  Preferred_Contact_Method__c: "Email",
  Preferred_Contact_Time__c: "Weekday afternoons",
  Previous_NTE_Events__c: "NTE2025; NTE2026",
  Purchase_Order_Number__c: "PO-2027-1042",
  Purchase_Order__c: "Yes",
  Quote_Required_for_PO__c: "Yes",
  Secondary_Contact_Email__c: "operations@horizonmobility.example",
  Secondary_Contact_Name__c: "Jordan Lee",
  Sponsor_Package__c: "Gold Partner; Event Guide Sponsor",
  Sponsor_Package_Total__c: "20000.00",
  Stand_Colleagues__c: "Alex Morgan; Jordan Lee; Priya Shah; Daniel Evans",
  Staff_Base_Names__c: "Alex Morgan\nJordan Lee\nPriya Shah\nDaniel Evans",
  Stand_Equipment__c: "Two tables, four chairs and a display screen",
  Stand_Power__c: "Yes",
  Stand_Special_Requirements__c: "None",
  Supplier_Agreement_Required__c: "No",
  Target_Booking_Reference__c: "NTE-2027-EX-0001",
  Total_Staff_Count__c: "4",
  Top_Up_Staff_Count__c: "2",
  Top_Up_Staff_Names__c: "Morgan Reed\nTaylor Price",
  Top_Up_Staff_Total__c: "100.00",
  Total_Staff_Count__c: "4",
  Title: "Partnerships Director",
  Trading_Name__c: "Horizon Mobility",
  MobilePhone: "07700 900123",
  PostalCode: "OX12 9TF",
  Volunteer_Armed_Forces_Service__c: "Yes",
  Volunteer_Service_Details__c: "Royal Navy, Portsmouth Naval Base",
  Volunteer_Service_Dates__c: "2008 to 2016",
  Volunteer_Opportunities__c: "Motorsport Event Support; Community Outreach / Awareness",
  Volunteer_Skills__c: "Transport and Logistics; Marshalling",
  Volunteer_Hours__c: "4-8",
  Volunteer_Availability__c: "Weekends",
  Volunteer_Travel_Regions__c: "South East England; Greater London",
  Volunteer_DBS_Willing__c: "Yes",
  Web_Form_Type__c: "Exhibitor Application",
  Website: "https://www.horizonmobility.example"
};

const currencyMergeFields = new Set([
  ...leadFields.filter(field => field.type === "Currency").map(field => `Lead.${field.api}`),
  ...opportunityFields.filter(field => field.type === "Currency").map(field => `Opportunity.${field.api}`)
]);

function emailPreviewHtml(sourceFile, stripe = false) {
  const maintainedSource = fs.readFileSync(path.join(root, "email-templates", "source", sourceFile), "utf8");
  const complimentary = sourceFile === "government-charity-approved-confirmation.html";
  const partner = sourceFile.includes("partner-sponsor");
  const paymentConfirmed = sourceFile.includes("payment-confirmed");
  const waived = sourceFile === "partner-sponsor-free-confirmed.html";
  const values = {...emailPreviewValues};
  if (stripe) values.Payment_Method__c = 'Stripe';
  if (partner) {
    values.Booking_Reference__c = "NTE-2027-PS-0001";
    values.Target_Booking_Reference__c = values.Booking_Reference__c;
    values.Listed_Price_Total__c = values.Sponsor_Package_Total__c;
    values.Web_Form_Type__c = "Partner / Sponsor Application";
  }
  if (complimentary) {
    values.Company = "Forces Community Support";
    values.Exhibitor_Space_Selections__c = "COBSEO Charity - Single - Free";
    values.Total_Staff_Count__c = "2";
    values.Listed_Price_Total__c = "0.00";
    values.Exhibitor_Space_Price__c = "0.00";
    values.Power_Socket_Count__c = "0";
    values.Power_Socket_Total__c = "0.00";
    values.Additional_Staff_Count__c = "0";
    values.Additional_Staff_Total__c = "0.00";
    values.Heavy_Vehicle_Required__c = "No";
  }
  if (waived) { values.Listed_Price_Total__c = "0.00"; values.Invoice_Required__c = "No"; }
  values.VAT_Total__c = (Math.round(Number(values.Listed_Price_Total__c) * vatRate) / 100).toFixed(2);
  values.Total_Including_VAT__c = (Number(values.Listed_Price_Total__c) + Number(values.VAT_Total__c)).toFixed(2);
  const source = previewEmailPresentation(maintainedSource, qualifiedField => {
    let field = qualifiedField.split(".")[1];
    if (field.startsWith("NTE_") && !Object.prototype.hasOwnProperty.call(values, field)) field = field.slice(4);
    if (!Object.prototype.hasOwnProperty.call(values, field)) throw new Error(`No email preview value for ${qualifiedField}`);
    return values[field];
  });
  const escapePreview = value => String(value).replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;").replace(/"/g, "&quot;");
  const mergePreviewField = (token, object, field) => {
    const isCurrency = currencyMergeFields.has(`${object}.${field}`);
    if (field.startsWith("NTE_") && !Object.prototype.hasOwnProperty.call(values, field)) field = field.slice(4);
    if (!Object.prototype.hasOwnProperty.call(values, field)) {
      throw new Error(`No email preview value is configured for ${token} in ${sourceFile}`);
    }
    // Salesforce's HTML merge already adds a <br> for each stored line break.
    // Match that here; pre-line CSS would display the newline and <br> twice.
    return escapePreview(isCurrency ? currencyPreview(values[field]) : values[field]).replace(/\r\n?|\n/g, "\n<br>");
  };
  const colour = partner ? "#0b668f" : complimentary ? "#176f66" : "#856624";
  const actions = [
    ["Provide staff details", partner ? "partner-sponsor-staff-update.html" : "exhibitor-staff-update.html"],
    ["Upload your logo", "logo-upload.html"]
  ];
  if (values.Heavy_Vehicle_Required__c !== "No") actions.push(["Vehicle details", "heavy-vehicle-details.html"]);
  const preparationLinks = '<table role="presentation" width="100%" cellspacing="0" cellpadding="0" border="0" style="width:100%;table-layout:fixed;"><tr>' + actions.map(([label, page]) =>
    `<td class="action-column" width="${actions.length === 3 ? '33.33%' : '50%'}" valign="top" style="padding:0 4px 8px;"><table role="presentation" width="100%" cellspacing="0" cellpadding="0" border="0"><tr><td align="center" bgcolor="${colour}" style="background-color:${colour};border-radius:7px;"><a class="email-button" href="https://stevostar1234.github.io/nte27-web-to-lead-demo/${page}" style="display:block;padding:14px 10px;background-color:${colour};color:#ffffff;text-decoration:none;border-radius:7px;font-size:14px;line-height:21px;font-weight:bold;">${label}</a></td></tr></table></td>`
  ).join("") + '</tr></table>';
  const moneyRow = (label, value) => `<tr><td style="padding:12px 18px;border-bottom:1px solid #e4edf2;">${escapePreview(label)}</td><td align="right" style="padding:12px 18px;border-bottom:1px solid #e4edf2;white-space:nowrap;">${Number(value) < 0 ? "-£" : "£"}${Math.abs(Number(value)).toFixed(2)}</td></tr>`;
  let financeRows = partner
    ? moneyRow(!paymentConfirmed && values.Sponsor_Package__c ? values.Sponsor_Package__c.replace(/;/g, " + ") : "Partner / sponsor package", values.Sponsor_Package_Total__c)
    : moneyRow("Exhibition space", values.Exhibitor_Space_Price__c);
  if (!partner && Number(values.Power_Socket_Total__c) > 0) financeRows += moneyRow(`Power sockets · ${values.Power_Socket_Count__c} × £${values.Power_Socket_Unit_Price__c}`, values.Power_Socket_Total__c);
  if (!partner && Number(values.Additional_Staff_Total__c) > 0) financeRows += moneyRow(`Additional staff · ${values.Additional_Staff_Count__c} × £${values.Additional_Staff_Unit_Price__c}`, values.Additional_Staff_Total__c);
  if (waived) financeRows += moneyRow("Booking adjustment", -Number(values.Sponsor_Package_Total__c));
  financeRows += moneyRow("Subtotal (ex VAT)", values.Listed_Price_Total__c);
  {
    const net = Number(values.Listed_Price_Total__c);
    const tax = Math.round(net * vatRate) / 100;
    financeRows += moneyRow(`VAT (${vatRate}%)`, tax) + moneyRow(paymentConfirmed ? 'Total paid (inc VAT)' : 'Total payable (inc VAT)', net + tax);
  }
  const paymentButton = stripe && !paymentConfirmed
    ? '<table data-nte-payment-button="true" role="presentation" align="center" width="100%" cellspacing="0" cellpadding="0" border="0" style="width:100%;max-width:420px;margin:26px auto 10px;"><tr><td align="center" bgcolor="#0b668f" style="background-color:#0b668f;border-radius:10px;"><a role="link" aria-disabled="true" aria-label="Pay Now with Stripe" style="display:block;padding:19px 20px;border-radius:10px;color:#ffffff;text-decoration:none;font-family:Arial,sans-serif;font-size:0;line-height:0;text-align:left;"><span style="display:inline-block;width:56%;vertical-align:middle;font-size:21px;font-weight:bold;line-height:28px;">Pay Now </span><span style="display:inline-block;width:44%;vertical-align:middle;text-align:right;line-height:0;"><span style="display:inline-block;vertical-align:middle;padding:4px 0 4px 14px;border-left:1px solid #b8d9e8;font-size:17px;font-weight:bold;line-height:26px;white-space:nowrap;"><img src="https://stevostar1234.github.io/nte27-web-to-lead-demo/assets/stripe-icon.png?v=20260909-1" width="22" height="22" alt="" role="presentation" style="display:inline-block;width:22px;height:22px;margin-right:7px;border:0;border-radius:4px;vertical-align:middle;">Stripe</span></span></a></td></tr></table>' : '';
  const tokens = {
    NTE_EVENT_LABEL: "NTE27",
    NTE_EVENT_SHORT_LABEL: "NTE27",
    NTE_ORGANISATION: escapePreview(values.Company),
    NTE_AGREEMENT_NOTE: stripe
      ? 'Please return your signed partnership / sponsorship agreement if you have not already done so.'
      : 'Please return your signed partnership / sponsorship agreement if you have not already done so.',
    NTE_PREPARATION_LINKS: preparationLinks,
    NTE_VEHICLE_NOTE: values.Heavy_Vehicle_Required__c !== 'No'
      ? '<p style="margin:0 0 18px;font-size:17px;line-height:28px;color:#263746;">If you are bringing any heavy vehicles or items on flatbed trailers use the <strong>Vehicle details</strong> link nearer to the event when information is known.</p>' : '',
    NTE_PAYMENT_NOTE: paymentConfirmed
      ? "Your payment has been recorded and your space is confirmed."
      : complimentary || waived
        ? "Your booking is complimentary and your space is confirmed. No payment is due."
        : partner
          ? 'Your exhibitor space is provisionally reserved. '
            + (stripe ? 'Please use the secure payment link below. ' : 'Please pay by bank transfer using the payment instructions provided by the NTE team. ')
            + 'Your partner / sponsor package will be confirmed once payment has been received.'
        : stripe
          ? "Your space is provisionally reserved. Please use the secure payment link below. Your space will be confirmed by the NTE Team."
          : "Your space is provisionally reserved. Please pay by bank transfer using the payment instructions provided by the NTE team. Your space will be confirmed when payment is recorded.",
    NTE_FINANCE_SUMMARY: '<table role="presentation" width="100%" cellspacing="0" cellpadding="0" border="0" style="width:100%;border:1px solid #dce7ed;border-radius:10px;overflow:hidden;">' + financeRows + '</table>' + paymentButton
  };
  const templateTokenPattern = /\{!(Lead|Contact|Opportunity)\.([A-Za-z0-9_]+)\}|<!--NTE_TOKEN:\{(NTE_[A-Z_]+)\}-->/g;
  if (/\{![^}]+\}|\{NTE_[A-Z_]+\}/.test(source.replace(templateTokenPattern, ""))) {
    throw new Error(`Unrecognised field in email preview source ${sourceFile}`);
  }
  // Replace source placeholders once; literal brace text in merged values stays data.
  return source.replace(templateTokenPattern, (token, object, field, customToken) => {
    if (!customToken) return mergePreviewField(token, object, field);
    if (!Object.prototype.hasOwnProperty.call(tokens, customToken)) throw new Error(`No preview value for ${customToken}`);
    return tokens[customToken];
  });
}

for (const type of ['exhibitor', 'partner-sponsor']) {
  write(path.join(root, 'email-templates', 'examples', `${type}-stripe-provisional.html`),
    emailPreviewHtml(`${type}-approved-confirmation.html`, true));
  write(path.join(root, 'email-templates', 'examples', `${type}-stripe-payment-confirmed.html`),
    emailPreviewHtml(`${type}-payment-confirmed.html`, true));
}

for (const [api, [sourceFile, subject, description]] of Object.entries(templates)) {
  const emailDir = path.join(md, "email", "unfiled$public");
  const html = compileEmailPresentation(fs.readFileSync(path.join(root, "email-templates", "source", sourceFile), "utf8"));
  write(path.join(emailDir, `${api}.email`), html);
  write(path.join(root, "email-templates", "examples", sourceFile), emailPreviewHtml(sourceFile));
  write(path.join(emailDir, `${api}.email-meta.xml`), [
    '<?xml version="1.0" encoding="UTF-8"?>',
    `<EmailTemplate xmlns="${ns}">`,
    "    <available>true</available>",
    `    <description>${esc(description)}</description>`,
    "    <encodingKey>UTF-8</encodingKey>",
    `    <name>${esc(description)}</name>`,
    "    <style>none</style>",
    `    <subject>${esc(subject)}</subject>`,
    `    <textOnly>${esc(nativeEmailTextFromHtml(html))}</textOnly>`,
    "    <type>custom</type>",
    "    <uiType>Aloha</uiType>",
    "</EmailTemplate>",
    ""
  ].join("\n"));
}

function apexActionFlow(api, label, description, actionName, acceptedTypes, isNewSubmission = false) {
  const filters = acceptedTypes.map((type) => [
    "        <filters>",
    "            <field>Web_Form_Type__c</field>",
    "            <operator>EqualTo</operator>",
    "            <value>",
    `                <stringValue>${esc(type)}</stringValue>`,
    "            </value>",
    "        </filters>"
  ].join("\n")).join("\n");
  return [
    '<?xml version="1.0" encoding="UTF-8"?>',
    `<Flow xmlns="${ns}">`,
    "    <actionCalls>",
    "        <name>Run_NTE_Service</name>",
    `        <label>${esc(label)}</label>`,
    "        <locationX>176</locationX>",
    "        <locationY>276</locationY>",
    `        <actionName>${actionName}</actionName>`,
    "        <actionType>apex</actionType>",
    "        <flowTransactionModel>CurrentTransaction</flowTransactionModel>",
    "        <inputParameters>",
    "            <name>leadId</name>",
    "            <value><elementReference>$Record.Id</elementReference></value>",
    "        </inputParameters>",
    ...(isNewSubmission ? ["        <inputParameters><name>isNewSubmission</name><value><booleanValue>true</booleanValue></value></inputParameters>"] : []),
    `        <nameSegment>${actionName}</nameSegment>`,
    "    </actionCalls>",
    "    <apiVersion>67.0</apiVersion>",
    "    <areMetricsLoggedToDataCloud>false</areMetricsLoggedToDataCloud>",
    `    <description>${esc(description)}</description>`,
    "    <environments>Default</environments>",
    `    <interviewLabel>${esc(label)} {!$Flow.CurrentDateTime}</interviewLabel>`,
    `    <label>${esc(label)}</label>`,
    "    <processMetadataValues><name>BuilderType</name><value><stringValue>LightningFlowBuilder</stringValue></value></processMetadataValues>",
    "    <processMetadataValues><name>CanvasMode</name><value><stringValue>AUTO_LAYOUT_CANVAS</stringValue></value></processMetadataValues>",
    "    <processType>AutoLaunchedFlow</processType>",
    "    <start>",
    "        <locationX>50</locationX>",
    "        <locationY>0</locationY>",
    "        <connector><targetReference>Run_NTE_Service</targetReference></connector>",
    `        <filterLogic>${acceptedTypes.map((_, index) => index + 1).join(" OR ")}</filterLogic>`,
    filters,
    "        <object>Lead</object>",
    "        <recordTriggerType>Create</recordTriggerType>",
    "        <triggerType>RecordAfterSave</triggerType>",
    "    </start>",
    "    <status>Active</status>",
    "</Flow>",
    ""
  ].join("\n");
}

write(path.join(md, "flows", "NTE_Inbound_Lead_Routing.flow-meta.xml"), apexActionFlow(
  "NTE_Inbound_Lead_Routing",
  "NTE Inbound Lead Routing",
  "Routes new NTE expressions of interest, applications and guest registrations, then sends the appropriate acknowledgement and internal notification.",
  "NTEInboundLeadService",
  ["Partner / Sponsor Expression of Interest", "Exhibitor Expression of Interest", "Partner / Sponsor Application", "Exhibitor Application", "Guest Registration"],
  true
));
write(path.join(md, "flows", "NTE_Supplementary_Update_Handler.flow-meta.xml"), apexActionFlow(
  "NTE_Supplementary_Update_Handler",
  "NTE Supplementary Update Handler",
  "Applies staff, logistics and logo submissions to the NTE Opportunity matched by exact booking reference. Failed submissions are retained; only the existing staff and vehicle temporary Leads are removed after success.",
  "NTEUpdateSubmissionService",
  ["Partner / Sponsor Staff Update", "Exhibitor Staff Update", "Heavy Vehicle Details", "Logo Update"],
  true
));
write(path.join(md, "flows", "Volunteer_Inbound_Lead_Notification.flow-meta.xml"), [
  '<?xml version="1.0" encoding="UTF-8"?>',
  `<Flow xmlns="${ns}">`,
  "    <actionCalls>",
  "        <name>Notify_Volunteer_Owner</name>",
  "        <label>Notify Volunteer Owner</label>",
  "        <locationX>176</locationX>",
  "        <locationY>276</locationY>",
  "        <actionName>VolunteerInboundLeadService</actionName>",
  "        <actionType>apex</actionType>",
  "        <flowTransactionModel>CurrentTransaction</flowTransactionModel>",
  "        <inputParameters><name>leadId</name><value><elementReference>$Record.Id</elementReference></value></inputParameters>",
  "        <inputParameters><name>isNewSubmission</name><value><booleanValue>true</booleanValue></value></inputParameters>",
  "        <nameSegment>VolunteerInboundLeadService</nameSegment>",
  "    </actionCalls>",
  "    <apiVersion>67.0</apiVersion>",
  "    <areMetricsLoggedToDataCloud>false</areMetricsLoggedToDataCloud>",
  "    <description>Sends the internal notification for a new Mission Motorsport volunteer application.</description>",
  "    <environments>Default</environments>",
  "    <interviewLabel>Volunteer Application Notification {!$Flow.CurrentDateTime}</interviewLabel>",
  "    <label>Volunteer Application Notification</label>",
  "    <processMetadataValues><name>BuilderType</name><value><stringValue>LightningFlowBuilder</stringValue></value></processMetadataValues>",
  "    <processMetadataValues><name>CanvasMode</name><value><stringValue>AUTO_LAYOUT_CANVAS</stringValue></value></processMetadataValues>",
  "    <processType>AutoLaunchedFlow</processType>",
  "    <start>",
  "        <locationX>50</locationX>",
  "        <locationY>0</locationY>",
  "        <connector><targetReference>Notify_Volunteer_Owner</targetReference></connector>",
  "        <filterLogic>1 AND 2</filterLogic>",
  "        <filters><field>Web_Form_Type__c</field><operator>EqualTo</operator><value><stringValue>Volunteer Application</stringValue></value></filters>",
  "        <filters><field>LeadSource</field><operator>EqualTo</operator><value><stringValue>Volunteer Application</stringValue></value></filters>",
  "        <object>Lead</object>",
  "        <recordTriggerType>Create</recordTriggerType>",
  "        <triggerType>RecordAfterSave</triggerType>",
  "    </start>",
  "    <status>Active</status>",
  "</Flow>",
  ""
].join("\n"));

const conversionMappings = [
  ["Booking_Reference__c", "Booking_Reference__c"],
  ["NTE_Event_Code__c", "NTE_Event_Code__c"],
  ["NTE_Source_Form_Type__c", "Web_Form_Type__c"],
  ["NTE_Form_Version__c", "Form_Version__c"],
  ["NTE_Declaration_Date__c", "Declaration_Date__c"],
  ["NTE_Event_Contact_Name__c", "Event_Contact_Name__c"],
  ["NTE_Event_Contact_Title__c", "Event_Contact_Title__c"],
  ["NTE_Event_Contact_Email__c", "Event_Contact_Email__c"],
  ["NTE_Event_Contact_Mobile__c", "Event_Contact_Mobile__c"],
  ["NTE_Sponsored_Name__c", "Sponsored_Name__c"],
  ["NTE_Alternative_Organisation_Name__c", "Alternative_Organisation_Name__c"],
  ["NTE_Trading_Name__c", "Trading_Name__c"],
  ["NTE_Secondary_Contact_Prefix__c", "Secondary_Contact_Prefix__c"],
  ["NTE_Secondary_Contact_Name__c", "Secondary_Contact_Name__c"],
  ["NTE_Secondary_Contact_Title__c", "Secondary_Contact_Title__c"],
  ["NTE_Secondary_Contact_Email__c", "Secondary_Contact_Email__c"],
  ["NTE_Secondary_Contact_Mobile__c", "Secondary_Contact_Mobile__c"],
  ["NTE_Secondary_Contact_Phone__c", "Secondary_Contact_Phone__c"],
  ["NTE_Exhibitor_Hall_Schedule__c", "Exhibitor_Hall_Schedule__c"],
  ["NTE_Has_Special_Requirements__c", "Has_Special_Requirements__c"],
  ["NTE_Industry_Body_Details__c", "Industry_Body_Details__c"],
  ["NTE_Event_Discovery_Source__c", "Event_Discovery_Source__c"],
  ["NTE_Declaration_Name__c", "Declaration_Name__c"],
  ["NTE_Terms_Accepted__c", "Terms_and_Conditions__c"],
  ["NTE_Sponsor_Package__c", "Sponsor_Package__c"],
  ["NTE_Exhibitor_Organisation_Category__c", "Exhibitor_Organisation_Category__c"],
  ["NTE_Exhibitor_Space_Selections__c", "Exhibitor_Space_Selections__c"],
  ["NTE_Exhibitor_Space_Size__c", "Exhibitor_Space_Size__c"],
  ["NTE_Exhibitor_Space_Position__c", "Exhibitor_Space_Position__c"],
  ["NTE_Previous_Events__c", "Previous_NTE_Events__c"],
  ["NTE_Stand_Power__c", "Stand_Power__c"],
  ["NTE_Power_Socket_Count__c", "Power_Socket_Count__c"],
  ["NTE_Stand_Equipment__c", "Stand_Equipment__c"],
  ["NTE_Stand_Special_Requirements__c", "Stand_Special_Requirements__c"],
  ["NTE_Stand_Colleagues__c", "Stand_Colleagues__c"],
  ["NTE_Stand_Extra_Notes__c", "Stand_Extra_Notes__c"],
  ["NTE_Planned_Exhibitor_Count__c", "Planned_Exhibitor_Count__c"],
  ["NTE_Initial_Staff_Count__c", "Total_Staff_Count__c"],
  ["NTE_Included_Staff_Count__c", "Included_Staff_Count__c"],
  ["NTE_Total_Staff_Count__c", "Total_Staff_Count__c"],
  ["NTE_Additional_Staff_Required__c", "Additional_Staff_Required__c"],
  ["NTE_Additional_Staff_Count__c", "Additional_Staff_Count__c"],
  ["NTE_Sponsor_Package_Total__c", "Sponsor_Package_Total__c"],
  ["NTE_Exhibitor_Space_Price__c", "Exhibitor_Space_Price__c"],
  ["NTE_Power_Socket_Unit_Price__c", "Power_Socket_Unit_Price__c"],
  ["NTE_Power_Socket_Total__c", "Power_Socket_Total__c"],
  ["NTE_Additional_Staff_Unit_Price__c", "Additional_Staff_Unit_Price__c"],
  ["NTE_Additional_Staff_Total__c", "Additional_Staff_Total__c"],
  ["NTE_Listed_Price_Total__c", "Listed_Price_Total__c"],
  ["NTE_Pricing_Status__c", "Pricing_Status__c"],
  ["NTE_Pricing_Version__c", "Pricing_Version__c"],
  ["NTE_VAT_Rate__c", "VAT_Rate__c"],
  ["Amount", "Total_Including_VAT__c"],
  ["NTE_Heavy_Vehicle_Required__c", "Heavy_Vehicle_Required__c"],
  ["NTE_Invoice_Required__c", "Invoice_Required__c"],
  ["NTE_Payment_Method__c", "Payment_Method__c"],
  ["NTE_Invoice_Requested__c", "Invoice_Requested__c"],
  ["NTE_Invoiced_Company__c", "Invoiced_Company__c"],
  ["NTE_Invoice_Address__c", "Invoice_Address__c"],
  ["NTE_Invoiced_Person__c", "Invoiced_Person__c"],
  ["NTE_Invoiced_Email__c", "Invoiced_Email__c"],
  ["NTE_Invoice_Contact_Phone__c", "Invoice_Contact_Phone__c"],
  ["NTE_Invoice_Additional_Information__c", "Invoice_Additional_Information__c"],
  ["NTE_Purchase_Order__c", "Purchase_Order__c"],
  ["NTE_Purchase_Order_Number__c", "Purchase_Order_Number__c"],
  ["NTE_Quote_Required_for_PO__c", "Quote_Required_for_PO__c"],
  ["NTE_Supplier_Agreement_Required__c", "Supplier_Agreement_Required__c"]
];
const repricedConversionFields = new Set([
  "Total_Staff_Count__c", "Included_Staff_Count__c", "Additional_Staff_Required__c", "Additional_Staff_Count__c",
  "Sponsor_Package_Total__c", "Exhibitor_Space_Price__c", "Power_Socket_Unit_Price__c", "Power_Socket_Total__c",
  "Additional_Staff_Unit_Price__c", "Additional_Staff_Total__c", "Listed_Price_Total__c", "Pricing_Status__c",
  "Pricing_Version__c", "Invoice_Required__c", "VAT_Rate__c", "VAT_Total__c", "Total_Including_VAT__c"
]);
const assignmentXml = conversionMappings.map(([target, source]) => [
  "        <inputAssignments>",
  `            <field>${target}</field>`,
  `            <value><elementReference>${repricedConversionFields.has(source) ? "Priced_Application" : "$Record"}.${source}</elementReference></value>`,
  "        </inputAssignments>"
].join("\n")).join("\n");
write(path.join(md, "flows", "NTE_Copy_Converted_Lead_to_Opportunity.flow-meta.xml"), [
  '<?xml version="1.0" encoding="UTF-8"?>',
  `<Flow xmlns="${ns}">`,
  "    <actionCalls>",
  "        <name>Price_Application_For_Conversion</name>",
  "        <label>Calculate Current Application Price</label>",
  "        <locationX>176</locationX>",
  "        <locationY>36</locationY>",
  "        <actionName>NTEPricingService</actionName>",
  "        <actionType>apex</actionType>",
  "        <connector><targetReference>Get_NTE_Opportunity_Record_Type</targetReference></connector>",
  "        <flowTransactionModel>CurrentTransaction</flowTransactionModel>",
  "        <inputParameters><name>leadId</name><value><elementReference>$Record.Id</elementReference></value></inputParameters>",
  "        <nameSegment>NTEPricingService</nameSegment>",
  "        <outputParameters><assignToReference>Priced_Application</assignToReference><name>pricedLead</name></outputParameters>",
  "    </actionCalls>",
  "    <apiVersion>67.0</apiVersion>",
  "    <areMetricsLoggedToDataCloud>false</areMetricsLoggedToDataCloud>",
  "    <decisions>",
  "        <name>Conversion_Just_Completed</name>",
  "        <label>Application Just Converted</label>",
  "        <locationX>176</locationX>",
  "        <locationY>12</locationY>",
  "        <defaultConnectorLabel>Already converted</defaultConnectorLabel>",
  "        <rules>",
  "            <name>New_Conversion</name>",
  "            <conditionLogic>and</conditionLogic>",
  "            <conditions><leftValueReference>$Record__Prior.IsConverted</leftValueReference><operator>EqualTo</operator><rightValue><booleanValue>false</booleanValue></rightValue></conditions>",
  "            <connector><targetReference>Price_Application_For_Conversion</targetReference></connector>",
  "            <label>New conversion</label>",
  "        </rules>",
  "    </decisions>",
  "    <description>Copies and prices an NTE application only when it first converts, then classifies the resulting Account and Contact. Later converted-Lead edits preserve the reviewed booking.</description>",
  "    <environments>Default</environments>",
  "    <interviewLabel>NTE Copy Converted Lead to Opportunity {!$Flow.CurrentDateTime}</interviewLabel>",
  "    <label>NTE Copy Converted Lead to Opportunity</label>",
  "    <processMetadataValues><name>BuilderType</name><value><stringValue>LightningFlowBuilder</stringValue></value></processMetadataValues>",
  "    <processMetadataValues><name>CanvasMode</name><value><stringValue>AUTO_LAYOUT_CANVAS</stringValue></value></processMetadataValues>",
  "    <processType>AutoLaunchedFlow</processType>",
  "    <recordLookups>",
  "        <name>Get_NTE_Opportunity_Record_Type</name>",
  "        <label>Get NTE Opportunity Record Type</label>",
  "        <locationX>176</locationX>",
  "        <locationY>156</locationY>",
  "        <connector><targetReference>Update_Converted_Opportunity</targetReference></connector>",
  "        <filterLogic>1 AND 2</filterLogic>",
  "        <filters><field>SobjectType</field><operator>EqualTo</operator><value><stringValue>Opportunity</stringValue></value></filters>",
  "        <filters><field>DeveloperName</field><operator>EqualTo</operator><value><stringValue>NTE_Event_Opportunity</stringValue></value></filters>",
  "        <getFirstRecordOnly>true</getFirstRecordOnly>",
  "        <object>RecordType</object>",
  "        <storeOutputAutomatically>true</storeOutputAutomatically>",
  "    </recordLookups>",
  "    <recordUpdates>",
  "        <name>Update_Converted_Opportunity</name>",
  "        <label>Update Converted Opportunity</label>",
  "        <locationX>176</locationX>",
  "        <locationY>276</locationY>",
  "        <connector><targetReference>Classify_Converted_Account</targetReference></connector>",
  "        <inputAssignments><field>RecordTypeId</field><value><elementReference>Get_NTE_Opportunity_Record_Type.Id</elementReference></value></inputAssignments>",
  assignmentXml,
  "        <inputAssignments><field>NTE_Approval_Email_Lead_Id__c</field><value><elementReference>$Record.Id</elementReference></value></inputAssignments>",
  "        <filters>",
  "            <field>Id</field>",
  "            <operator>EqualTo</operator>",
  "            <value><elementReference>$Record.ConvertedOpportunityId</elementReference></value>",
  "        </filters>",
  "        <object>Opportunity</object>",
  "    </recordUpdates>",
  "    <recordUpdates>",
  "        <name>Classify_Converted_Account</name>",
  "        <label>Classify Converted Account</label>",
  "        <locationX>176</locationX>",
  "        <locationY>396</locationY>",
  "        <connector><targetReference>Classify_Converted_Contact</targetReference></connector>",
  "        <inputAssignments><field>NTE_Participant__c</field><value><booleanValue>true</booleanValue></value></inputAssignments>",
  "        <inputAssignments><field>NTE_Event_Code__c</field><value><elementReference>$Record.NTE_Event_Code__c</elementReference></value></inputAssignments>",
  "        <inputAssignments><field>NTE_Source_Form_Type__c</field><value><elementReference>$Record.Web_Form_Type__c</elementReference></value></inputAssignments>",
  "        <inputAssignments><field>NTE_Booking_Reference__c</field><value><elementReference>$Record.Booking_Reference__c</elementReference></value></inputAssignments>",
  "        <inputAssignments><field>NTE_Last_Application_Date__c</field><value><elementReference>$Flow.CurrentDateTime</elementReference></value></inputAssignments>",
  "        <filters><field>Id</field><operator>EqualTo</operator><value><elementReference>$Record.ConvertedAccountId</elementReference></value></filters>",
  "        <object>Account</object>",
  "    </recordUpdates>",
  "    <recordUpdates>",
  "        <name>Classify_Converted_Contact</name>",
  "        <label>Classify Converted Contact</label>",
  "        <locationX>176</locationX>",
  "        <locationY>516</locationY>",
  "        <inputAssignments><field>NTE_Participant__c</field><value><booleanValue>true</booleanValue></value></inputAssignments>",
  "        <inputAssignments><field>NTE_Event_Code__c</field><value><elementReference>$Record.NTE_Event_Code__c</elementReference></value></inputAssignments>",
  "        <inputAssignments><field>NTE_Source_Form_Type__c</field><value><elementReference>$Record.Web_Form_Type__c</elementReference></value></inputAssignments>",
  "        <inputAssignments><field>NTE_Booking_Reference__c</field><value><elementReference>$Record.Booking_Reference__c</elementReference></value></inputAssignments>",
  "        <inputAssignments><field>NTE_Last_Application_Date__c</field><value><elementReference>$Flow.CurrentDateTime</elementReference></value></inputAssignments>",
  "        <inputAssignments><field>NTE_Contact_Role__c</field><value><stringValue>Applicant / event contact</stringValue></value></inputAssignments>",
  "        <filters><field>Id</field><operator>EqualTo</operator><value><elementReference>$Record.ConvertedContactId</elementReference></value></filters>",
  "        <object>Contact</object>",
  "    </recordUpdates>",
  "    <start>",
  "        <locationX>50</locationX>",
  "        <locationY>0</locationY>",
  "        <connector><targetReference>Conversion_Just_Completed</targetReference></connector>",
  "        <doesRequireRecordChangedToMeetCriteria>true</doesRequireRecordChangedToMeetCriteria>",
  "        <filterLogic>1 AND 2 AND (3 OR 4)</filterLogic>",
  "        <filters><field>IsConverted</field><operator>EqualTo</operator><value><booleanValue>true</booleanValue></value></filters>",
  "        <filters><field>ConvertedOpportunityId</field><operator>IsNull</operator><value><booleanValue>false</booleanValue></value></filters>",
  "        <filters><field>Web_Form_Type__c</field><operator>EqualTo</operator><value><stringValue>Partner / Sponsor Application</stringValue></value></filters>",
  "        <filters><field>Web_Form_Type__c</field><operator>EqualTo</operator><value><stringValue>Exhibitor Application</stringValue></value></filters>",
  "        <object>Lead</object>",
  "        <recordTriggerType>Update</recordTriggerType>",
  "        <triggerType>RecordAfterSave</triggerType>",
  "    </start>",
  "    <status>Active</status>",
  "    <variables><name>Priced_Application</name><dataType>SObject</dataType><isCollection>false</isCollection><isInput>false</isInput><isOutput>false</isOutput><objectType>Lead</objectType></variables>",
  "</Flow>",
  ""
].join("\n"));

function fieldInstanceXml(api, identifier, behavior = "none") {
  if (["NTE_Update_Booking_Id__c", "NTE_Price_Adjustment__c", "NTE_Approval_Email_Kind__c"].includes(api)) behavior = "readonly";
  return [
    "        <itemInstances>",
    "            <fieldInstance>",
    "                <fieldInstanceProperties>",
    "                    <name>uiBehavior</name>",
    `                    <value>${behavior}</value>`,
    "                </fieldInstanceProperties>",
    `                <fieldItem>Record.${api}</fieldItem>`,
    `                <identifier>${identifier}</identifier>`,
    "            </fieldInstance>",
    "        </itemInstances>"
  ].join("\n");
}

function componentItemXml(componentName, identifier, properties = []) {
  const lines = ["        <itemInstances>", "            <componentInstance>"];
  for (const [name, value] of properties) {
    lines.push("                <componentInstanceProperties>", `                    <name>${name}</name>`);
    if (Array.isArray(value)) {
      lines.push("                    <valueList>");
      for (const item of value) {
        lines.push("                        <valueListItems>", `                            <value>${esc(item)}</value>`, "                        </valueListItems>");
      }
      lines.push("                    </valueList>");
    } else {
      lines.push(`                    <value>${esc(value)}</value>`);
    }
    lines.push("                </componentInstanceProperties>");
  }
  lines.push(`                <componentName>${componentName}</componentName>`, `                <identifier>${identifier}</identifier>`, "            </componentInstance>", "        </itemInstances>");
  return lines.join("\n");
}

function regionXml(name, items, type = "Facet") {
  return ["    <flexiPageRegions>", ...items, `        <name>${name}</name>`, `        <type>${type}</type>`, "    </flexiPageRegions>"].join("\n");
}

function recordPageXml({label, objectName, sections}) {
  const lines = ['<?xml version="1.0" encoding="UTF-8"?>', `<FlexiPage xmlns="${ns}">`];
  const actionNamesByObject = {
    Lead: ["Convert", "Edit", "Clone", "ChangeOwnerOne", "ChangeRecordType", "Global.NewTask", "Global.NewEvent", "Delete", "Lead.Retry_Update_Email"],
    Account: ["Edit", "Global.NewContact", "Global.NewOpportunity", "ChangeOwnerOne", "Global.NewTask", "Global.NewEvent", "Delete"],
    Contact: ["Edit", "Global.NewTask", "Global.NewEvent", "Clone", "ChangeOwnerOne", "Delete"],
    Opportunity: ["Edit", "Clone", "ChangeOwnerOne", "ChangeRecordType", "Global.NewTask", "Global.NewEvent", "Delete", "Opportunity.Retry_Booking_Email"]
  };
  lines.push(regionXml("header", [componentItemXml("force:highlightsPanel", "force_highlightsPanel", [
    ["actionNames", actionNamesByObject[objectName]],
    ["collapsed", "false"],
    ["enableActionsConfiguration", "true"],
    ["enableActionsInNative", "true"],
    ["hideChatterActions", "false"],
    ["hideSlackAction", "false"],
    ["numVisibleActions", "5"]
  ])], "Region"));

  const sectionItems = [];
  sections.forEach((section, sectionIndex) => {
    const sectionKey = `NTE_Section_${sectionIndex + 1}`;
    const [leftFields, rightFields] = section.columns || [section.fields.slice(0, Math.ceil(section.fields.length / 2)), section.fields.slice(Math.ceil(section.fields.length / 2))];
    lines.push(regionXml(`${sectionKey}_Left`, leftFields.map((api, index) => fieldInstanceXml(api, `Record${api.replace(/[^A-Za-z0-9]/g, "_")}${sectionIndex}L${index}`))));
    lines.push(regionXml(`${sectionKey}_Right`, rightFields.map((api, index) => fieldInstanceXml(api, `Record${api.replace(/[^A-Za-z0-9]/g, "_")}${sectionIndex}R${index}`))));
    lines.push(regionXml(`${sectionKey}_Columns`, [
      componentItemXml("flexipage:column", `${sectionKey}_Column_Left`, [["body", `${sectionKey}_Left`]]),
      componentItemXml("flexipage:column", `${sectionKey}_Column_Right`, [["body", `${sectionKey}_Right`]])
    ]));
    sectionItems.push(componentItemXml("flexipage:fieldSection", `${sectionKey}_FieldSection`, [
      ["columns", `${sectionKey}_Columns`],
      ["horizontalAlignment", "false"],
      ["label", section.label]
    ]));
  });
  sectionItems.push(componentItemXml("force:recordDetailPanelMobile", "nte_recordDetailPanelMobile"));
  lines.push(regionXml("NTE_Detail_Tab_Content", sectionItems));
  const relatedItems = [];
  if (["Account", "Contact", "Opportunity"].includes(objectName)) {
    relatedItems.push(componentItemXml("nteRelatedOpportunities", "nte_opportunityRelationships"));
  }
  relatedItems.push(componentItemXml("force:relatedListContainer", "nte_relatedLists", [
    ["relatedListComponentOverride", "NONE"],
    ["rowsToDisplay", "10"],
    ["showActionBar", "true"]
  ]));
  lines.push(regionXml("NTE_Related_Tab_Content", relatedItems));
  lines.push(regionXml("NTE_Main_Tabs", [
    componentItemXml("flexipage:tab", "nte_detailTab", [["active", "true"], ["body", "NTE_Detail_Tab_Content"], ["title", "Standard.Tab.detail"]]),
    componentItemXml("flexipage:tab", "nte_relatedTab", [["body", "NTE_Related_Tab_Content"], ["title", "Standard.Tab.relatedLists"]])
  ]));
  lines.push(regionXml("main", [componentItemXml("flexipage:tabset", "nte_mainTabset", [["tabs", "NTE_Main_Tabs"]])], "Region"));
  lines.push(regionXml("sidebar", [
    componentItemXml("runtime_sales_activities:activityPanel", "nte_activityPanel", [["showLegacyActivityComposer", "false"]]),
    componentItemXml("force:relatedListQuickLinksContainer", "nte_relatedQuickLinks", [["hideHeader", "false"]])
  ], "Region"));
  lines.push(`    <description>App-scoped NTE workspace for ${esc(objectName)} records, organised in the order the event team works.</description>`);
  lines.push(`    <masterLabel>${esc(label)}</masterLabel>`, `    <sobjectType>${objectName}</sobjectType>`, "    <template>", "        <name>flexipage:recordHomeTemplateDesktop</name>", "    </template>", "    <type>RecordPage</type>", "</FlexiPage>", "");
  return lines.join("\n");
}

const leadSections = [
  {label: "Submission and ownership", fields: ["Web_Form_Type__c", "NTE_Event_Code__c", "Form_Version__c", "LeadSource", "Booking_Reference__c", "Status", "NTE_Interest_Progressed__c", "NTE_Interest_Not_Progressed__c", "NTE_Application_Rejected__c", "OwnerId", "NTE_Applicant_Email_Status__c", "NTE_Internal_Email_Status__c", "NTE_Email_Error__c"]},
  {label: "Person and organisation", fields: ["Name", "Company", "Title", "Email", "Phone", "MobilePhone", "Website", "Organisation_Type__c", "Sponsored_Name__c", "Alternative_Organisation_Name__c"]},
  {label: "Event contacts", fields: ["Event_Contact_Name__c", "Event_Contact_Title__c", "Event_Contact_Email__c", "Event_Contact_Mobile__c", "Secondary_Contact_Prefix__c", "Secondary_Contact_Name__c", "Secondary_Contact_Title__c", "Secondary_Contact_Email__c", "Secondary_Contact_Mobile__c", "Secondary_Contact_Phone__c"]},
  {label: "Expressions of interest", fields: ["Partner_Interest_Type__c", "Partner_Interest_Areas__c", "Partnership_Interest_Detail__c", "Exhibitor_Interest_Areas__c", "Exhibitor_Interest_Detail__c", "Exhibitor_Community_Contribution__c", "Preferred_Contact_Method__c", "Preferred_Contact_Time__c", "Contact_Consent__c", "Event_Discovery_Source__c", "Industry_Body_Details__c"]},
  {label: "Partnership and exhibition application", fields: ["Sponsor_Package__c", "Exhibitor_Organisation_Category__c", "Exhibitor_Space_Selections__c", "Exhibitor_Space_Size__c", "Exhibitor_Space_Position__c", "Exhibitor_Hall_Schedule__c", "Previous_NTE_Events__c", "Stand_Power__c", "Power_Socket_Count__c", "Stand_Equipment__c", "Stand_Special_Requirements__c", "Stand_Colleagues__c", "Stand_Extra_Notes__c", "Planned_Exhibitor_Count__c", "Total_Staff_Count__c", "Included_Staff_Count__c", "Additional_Staff_Required__c", "Additional_Staff_Count__c", "Staff_Update_Audience__c", "Staff_Base_Names__c", "Top_Up_Staff_Required__c", "Top_Up_Staff_Count__c", "Top_Up_Staff_Names__c", "Heavy_Vehicle_Required__c", "Has_Special_Requirements__c", "Logo_Upload_URL__c", "Declaration_Name__c", "Declaration_Date__c", "Terms_and_Conditions__c"]},
  {label: "Guest registration", fields: ["Guest_Accompanying__c", "Accompanying_Guest_Name__c", "Accompanying_Guest_Email__c", "Guest_Accessibility_Required__c", "Guest_Accessibility_Details__c", "Guest_Information_Declaration__c"]},
  {label: "Pricing", fields: ["Sponsor_Package_Total__c", "Exhibitor_Space_Price__c", "Power_Socket_Unit_Price__c", "Power_Socket_Total__c", "Additional_Staff_Unit_Price__c", "Additional_Staff_Total__c", "Top_Up_Staff_Unit_Price__c", "Top_Up_Staff_Total__c", "Listed_Price_Total__c", "VAT_Rate__c", "VAT_Total__c", "Total_Including_VAT__c", "Top_Up_VAT_Total__c", "Top_Up_Total_Inc_VAT__c", "Pricing_Status__c", "Pricing_Version__c"]},
  {label: "Invoicing and procurement", fields: ["Invoice_Required__c", "Payment_Method__c", "Invoice_Requested__c", "Invoiced_Company__c", "Trading_Name__c", "Invoice_Address__c", "Invoiced_Person__c", "Invoiced_Email__c", "Invoice_Contact_Phone__c", "Purchase_Order__c", "Purchase_Order_Number__c", "Quote_Required_for_PO__c", "Invoice_Additional_Information__c", "Supplier_Agreement_Required__c"]},
  {label: "Heavy vehicle and logistics", fields: ["Delivery_Window__c", "Heavy_Item_1_Description__c", "Heavy_Item_1_Registration__c", "Heavy_Item_1_Dimensions__c", "Heavy_Item_1_Gross_Weight__c", "Heavy_Item_2_Description__c", "Heavy_Item_2_Registration__c", "Heavy_Item_2_Dimensions__c", "Heavy_Item_2_Gross_Weight__c", "Heavy_Item_3_Description__c", "Heavy_Item_3_Registration__c", "Heavy_Item_3_Dimensions__c", "Heavy_Item_3_Gross_Weight__c", "Haulier_Name__c", "Haulier_Staff__c", "Haulier_Vehicle_Type__c", "Haulier_Vehicle_Gross_Weight__c", "Haulier_Vehicle_Dimensions__c", "Haulier_Vehicle_Registration__c"]},
  {label: "Processing and conversion", fields: ["Target_Booking_Reference__c", "NTE_Update_Status__c", "NTE_Update_Booking_Id__c", "NTE_Update_Error__c", "CreatedById", "LastModifiedById"]}
];

const opportunitySections = [
  {label: "Booking and commercial status", fields: ["AccountId", "StageName", "CloseDate", "Amount", "Type", "LeadSource", "CampaignId", "OwnerId", "Booking_Reference__c", "NTE_Event_Code__c", "NTE_Source_Form_Type__c", "NTE_Form_Version__c", "NTE_Attendance_Status__c", "Probability", "ForecastCategoryName", "NextStep"]},
  {label: "Event contacts", fields: ["NTE_Event_Contact_Name__c", "NTE_Event_Contact_Title__c", "NTE_Event_Contact_Email__c", "NTE_Event_Contact_Mobile__c", "NTE_Secondary_Contact_Prefix__c", "NTE_Secondary_Contact_Name__c", "NTE_Secondary_Contact_Title__c", "NTE_Secondary_Contact_Email__c", "NTE_Secondary_Contact_Mobile__c", "NTE_Secondary_Contact_Phone__c"]},
  {label: "Partnership and sponsorship", fields: ["NTE_Sponsored_Name__c", "NTE_Alternative_Organisation_Name__c", "NTE_Sponsor_Package__c", "NTE_Event_Discovery_Source__c", "NTE_Industry_Body_Details__c", "NTE_Declaration_Name__c", "NTE_Declaration_Date__c", "NTE_Terms_Accepted__c"]},
  {label: "Exhibition space", fields: ["NTE_Exhibitor_Organisation_Category__c", "NTE_Exhibitor_Space_Selections__c", "NTE_Exhibitor_Space_Size__c", "NTE_Exhibitor_Space_Position__c", "NTE_Exhibitor_Hall_Schedule__c", "NTE_Previous_Events__c", "NTE_Has_Special_Requirements__c"]},
  {label: "Stand requirements and staff", fields: ["NTE_Stand_Power__c", "NTE_Power_Socket_Count__c", "NTE_Stand_Equipment__c", "NTE_Stand_Special_Requirements__c", "NTE_Stand_Colleagues__c", "NTE_Stand_Extra_Notes__c", "NTE_Planned_Exhibitor_Count__c", "NTE_Initial_Staff_Count__c", "NTE_Included_Staff_Count__c", "NTE_Total_Staff_Count__c", "NTE_Additional_Staff_Required__c", "NTE_Additional_Staff_Count__c", "NTE_Top_Up_Staff_Required__c", "NTE_Top_Up_Staff_Count__c", "NTE_Top_Up_Staff_Names__c", "NTE_Heavy_Vehicle_Required__c"]},
  {label: "Pricing", fields: ["NTE_Sponsor_Package_Total__c", "NTE_Exhibitor_Space_Price__c", "NTE_Power_Socket_Unit_Price__c", "NTE_Power_Socket_Total__c", "NTE_Additional_Staff_Unit_Price__c", "NTE_Additional_Staff_Total__c", "NTE_Top_Up_Staff_Unit_Price__c", "NTE_Top_Up_Staff_Total__c", "NTE_Price_Adjustment__c", "NTE_Listed_Price_Total__c", "NTE_VAT_Rate__c", "NTE_VAT_Total__c", "NTE_Total_Including_VAT__c", "NTE_Top_Up_VAT_Rate__c", "NTE_Top_Up_VAT_Total__c", "NTE_Top_Up_Total_Inc_VAT__c", "NTE_Pricing_Status__c", "NTE_Pricing_Version__c"]},
  {label: "Invoicing and procurement", fields: ["NTE_Invoice_Required__c", "NTE_Payment_Method__c", "NTE_Invoice_Requested__c", "NTE_Invoiced_Company__c", "NTE_Trading_Name__c", "NTE_Invoice_Address__c", "NTE_Invoiced_Person__c", "NTE_Invoiced_Email__c", "NTE_Invoice_Contact_Phone__c", "NTE_Purchase_Order__c", "NTE_Purchase_Order_Number__c", "NTE_Quote_Required_for_PO__c", "NTE_Invoice_Additional_Information__c", "NTE_Supplier_Agreement_Required__c", "NTE_Quote_Provided__c", "NTE_Quote_Provided_At__c", "NTE_Quote_Provided_By__c", "NTE_Invoice_Provided__c", "NTE_Invoice_Provided_At__c", "NTE_Invoice_Provided_By__c", "NTE_Payment_Received__c", "NTE_Payment_Received_At__c", "NTE_Payment_Recorded_By__c", "NTE_Free_Space_Confirmed__c", "NTE_Top_Up_Invoice_Required__c", "NTE_Top_Up_Invoice_Provided__c", "NTE_Top_Up_Invoice_At__c", "NTE_Top_Up_Invoice_By__c", "NTE_Top_Up_Payment_Received__c", "NTE_Top_Up_Payment_At__c", "NTE_Top_Up_Payment_By__c"]},
  {label: "Heavy vehicle and logistics", fields: ["NTE_Delivery_Window__c", "NTE_Heavy_Item_1_Description__c", "NTE_Heavy_Item_1_Registration__c", "NTE_Heavy_Item_1_Dimensions__c", "NTE_Heavy_Item_1_Gross_Weight__c", "NTE_Heavy_Item_2_Description__c", "NTE_Heavy_Item_2_Registration__c", "NTE_Heavy_Item_2_Dimensions__c", "NTE_Heavy_Item_2_Gross_Weight__c", "NTE_Heavy_Item_3_Description__c", "NTE_Heavy_Item_3_Registration__c", "NTE_Heavy_Item_3_Dimensions__c", "NTE_Heavy_Item_3_Gross_Weight__c", "NTE_Haulier_Name__c", "NTE_Haulier_Staff__c", "NTE_Haulier_Vehicle_Type__c", "NTE_Haulier_Vehicle_Gross_Weight__c", "NTE_Haulier_Vehicle_Dimensions__c", "NTE_Haulier_Vehicle_Registration__c"]},
  {label: "Update audit", fields: ["NTE_Staff_Update_Completed_At__c", "NTE_Heavy_Vehicle_Update_Completed_At__c", "NTE_Logo_Update_Provided__c", "NTE_Logo_Update_Provided_At__c", "NTE_Last_Update_Type__c", "NTE_Last_Update_Form_Version__c", "NTE_Last_Update_Processed_At__c", "NTE_Last_Update_Declaration_Name__c", "NTE_Last_Update_Declaration_Date__c", "NTE_Last_Update_Error__c", "Description", "CreatedById", "LastModifiedById"]}
];

const accountSections = [
  {label: "NTE participation", fields: ["NTE_Participant__c", "NTE_Event_Code__c", "NTE_Source_Form_Type__c", "NTE_Booking_Reference__c", "NTE_Last_Application_Date__c", "OwnerId"]},
  {label: "Organisation details", fields: ["Name", "ParentId", "Type", "Industry", "AccountSource", "Phone", "Website", "NumberOfEmployees", "AnnualRevenue", "Description"]},
  {label: "Record information", fields: ["RecordTypeId", "CreatedById", "LastModifiedById"]}
];

const contactSections = [
  {label: "NTE participation", fields: ["NTE_Participant__c", "NTE_Event_Code__c", "NTE_Source_Form_Type__c", "NTE_Booking_Reference__c", "NTE_Last_Application_Date__c", "NTE_Contact_Role__c"]},
  {label: "Contact details", fields: ["Name", "AccountId", "Title", "Department", "Email", "Phone", "MobilePhone", "LeadSource", "ReportsToId", "AssistantName", "AssistantPhone", "Description", "OwnerId"]},
  {label: "Record information", fields: ["RecordTypeId", "CreatedById", "LastModifiedById"]}
];

function coherentColumns(section, left, right) {
  const original = new Set(section.fields);
  const supplied = [...left, ...right];
  for (const field of supplied) if (!original.has(field)) throw new Error(`Unknown layout field ${field}`);
  const rest = section.fields.filter(field => !supplied.includes(field));
  section.columns = [left, [...right, ...rest]];
}
for (const [sections, prefix] of [[leadSections, ""], [opportunitySections, "NTE_"]]) {
  const contacts = sections.find(section => section.label === "Event contacts");
  coherentColumns(contacts, contacts.fields.filter(field => !field.includes("Secondary_")), contacts.fields.filter(field => field.includes("Secondary_")));
  const finance = sections.find(section => section.label === "Invoicing and procurement");
  const billing = ["Invoiced_Company__c", "Trading_Name__c", "Invoice_Address__c", "Invoiced_Person__c", "Invoiced_Email__c", "Invoice_Contact_Phone__c"].map(field => prefix + field);
  const procurement = ["Payment_Method__c", "Invoice_Requested__c", "Invoice_Required__c", "Quote_Required_for_PO__c", "Purchase_Order__c", "Purchase_Order_Number__c", "Supplier_Agreement_Required__c", "Invoice_Additional_Information__c"].map(field => prefix + field);
  coherentColumns(finance, billing, procurement);
}
const financeSection = opportunitySections.find(section => section.label === "Invoicing and procurement");
const milestones = financeSection.fields.filter(field => !financeSection.columns[0].includes(field) && !["NTE_Payment_Method__c", "NTE_Invoice_Requested__c", "NTE_Invoice_Required__c", "NTE_Quote_Required_for_PO__c", "NTE_Purchase_Order__c", "NTE_Purchase_Order_Number__c", "NTE_Supplier_Agreement_Required__c", "NTE_Invoice_Additional_Information__c"].includes(field));
financeSection.fields = financeSection.fields.filter(field => !milestones.includes(field));
financeSection.columns[1] = financeSection.columns[1].filter(field => !milestones.includes(field));
const newRequirementFields = ["NTE_PO_Confirmed__c", "NTE_Agreement_Provided__c", "NTE_Invoice_Details_Included__c", "NTE_Bank_Details_Provided__c"];
const baseMilestones = milestones.filter(field => !field.includes("Top_Up"));
const topUpMilestones = milestones.filter(field => field.includes("Top_Up"));
opportunitySections.splice(opportunitySections.indexOf(financeSection) + 1, 0, {label: "Finance requirements and payments", fields: [...milestones, ...newRequirementFields, "NTE_Top_Up_Payment_Requested_At__c"], columns: [[...newRequirementFields, ...baseMilestones], [...topUpMilestones, "NTE_Top_Up_Payment_Requested_At__c"]]});
opportunitySections.find(section => section.label === "Update audit").fields.push("NTE_Joining_Instructions_By__c");

opportunitySections.push({label: "Booking correspondence", fields: ["NTE_Approval_Email_Kind__c", "NTE_Approval_Email_Status__c", "NTE_Approval_Email_Requested_At__c", "NTE_Approval_Email_Requested_By__c", "NTE_Approval_Email_Sent_At__c", "NTE_Approval_Email_Recipient__c", "NTE_Approval_Email_Error__c", "NTE_Final_Pack_Status__c", "NTE_Final_Pack_Sent_At__c"], columns: [["NTE_Approval_Email_Kind__c", "NTE_Approval_Email_Status__c", "NTE_Approval_Email_Sent_At__c", "NTE_Approval_Email_Recipient__c", "NTE_Approval_Email_Error__c"], ["NTE_Approval_Email_Requested_At__c", "NTE_Approval_Email_Requested_By__c", "NTE_Final_Pack_Status__c", "NTE_Final_Pack_Sent_At__c"]]});
coherentColumns(leadSections.find(section => section.label === "Person and organisation"), ["Name", "Title", "Email", "Phone", "MobilePhone"], ["Company", "Website", "Organisation_Type__c", "Sponsored_Name__c", "Alternative_Organisation_Name__c"]);
for (const sections of [leadSections, opportunitySections]) {
  const logistics = sections.find(section => section.label === "Heavy vehicle and logistics");
  coherentColumns(logistics, logistics.fields.filter(field => !field.includes("Haulier_")), logistics.fields.filter(field => field.includes("Haulier_")));
}

const recordPages = [
  ["NTE_Management_Lead_Record_Page", {label: "NTE Management Lead Record Page", objectName: "Lead", sections: leadSections}],
  ["NTE_Management_Opportunity_Record_Page", {label: "NTE Management Opportunity Record Page", objectName: "Opportunity", sections: opportunitySections}],
  ["NTE_Management_Account_Record_Page", {label: "NTE Management Account Record Page", objectName: "Account", sections: accountSections}],
  ["NTE_Management_Contact_Record_Page", {label: "NTE Management Contact Record Page", objectName: "Contact", sections: contactSections}]
];
for (const [api, definition] of recordPages) write(path.join(md, "flexipages", `${api}.flexipage-meta.xml`), recordPageXml(definition));

const homeTemplateDir = path.join(md, "aura", "NTE_OneRegionHomeTemplate");
write(path.join(homeTemplateDir, "NTE_OneRegionHomeTemplate.cmp"), [
  '<aura:component implements="lightning:homeTemplate" description="Full-width one-region Home template for the NTE Management app">',
  '    <aura:attribute name="main" type="Aura.Component[]" />',
  '    <div class="nte-full-width-home" role="main">',
  '        {!v.main}',
  '    </div>',
  '</aura:component>',
  ''
].join("\n"));
write(path.join(homeTemplateDir, "NTE_OneRegionHomeTemplate.design"), [
  '<design:component label="NTE Full-Width Home">',
  '    <flexipage:template>',
  '        <flexipage:region name="main" label="Main" defaultWidth="LARGE" />',
  '    </flexipage:template>',
  '</design:component>',
  ''
].join("\n"));
write(path.join(homeTemplateDir, "NTE_OneRegionHomeTemplate.css"), [
  '.THIS.nte-full-width-home {',
  '    width: 100%;',
  '    min-width: 0;',
  '}',
  ''
].join("\n"));
write(path.join(homeTemplateDir, "NTE_OneRegionHomeTemplate.cmp-meta.xml"), [
  '<?xml version="1.0" encoding="UTF-8"?>',
  `<AuraDefinitionBundle xmlns="${ns}">`,
  '    <apiVersion>67.0</apiVersion>',
  '    <description>Full-width one-region Home template for the NTE Management app.</description>',
  '</AuraDefinitionBundle>',
  ''
].join("\n"));

write(path.join(md, "flexipages", "NTE_Management_Home.flexipage-meta.xml"), [
  '<?xml version="1.0" encoding="UTF-8"?>',
  `<FlexiPage xmlns="${ns}">`,
  "    <flexiPageRegions>",
  "        <itemInstances>",
  "            <componentInstance>",
  "                <componentName>nteManagementHome</componentName>",
  "                <identifier>c_nteManagementHome</identifier>",
  "            </componentInstance>",
  "        </itemInstances>",
  "        <name>main</name>",
  "        <type>Region</type>",
  "    </flexiPageRegions>",
  "    <masterLabel>NTE Management Home</masterLabel>",
  "    <template><name>c:NTE_OneRegionHomeTemplate</name></template>",
  "    <type>HomePage</type>",
  "</FlexiPage>",
  ""
].join("\n"));

const appOverrides = [
  ["Tab", "NTE_Management_Home", "Large", "standard-home"],
  ["View", "NTE_Management_Lead_Record_Page", "Large", "Lead"],
  ["View", "NTE_Management_Lead_Record_Page", "Small", "Lead"],
  ["View", "NTE_Management_Account_Record_Page", "Large", "Account"],
  ["View", "NTE_Management_Account_Record_Page", "Small", "Account"],
  ["View", "NTE_Management_Contact_Record_Page", "Large", "Contact"],
  ["View", "NTE_Management_Contact_Record_Page", "Small", "Contact"],
  ["View", "NTE_Management_Opportunity_Record_Page", "Large", "Opportunity"],
  ["View", "NTE_Management_Opportunity_Record_Page", "Small", "Opportunity"]
];
const appLines = ['<?xml version="1.0" encoding="UTF-8"?>', `<CustomApplication xmlns="${ns}">`];
for (const [actionName, content, formFactor, pageOrSobjectType] of appOverrides) {
  appLines.push(
    "    <actionOverrides>",
    `        <actionName>${actionName}</actionName>`,
    `        <content>${content}</content>`,
    `        <formFactor>${formFactor}</formFactor>`,
    "        <skipRecordTypeSelect>false</skipRecordTypeSelect>",
    "        <type>Flexipage</type>",
    `        <pageOrSobjectType>${pageOrSobjectType}</pageOrSobjectType>`,
    "    </actionOverrides>"
  );
}
appLines.push(
  "    <brand>",
  "        <footerColor>#8E793F</footerColor>",
  "        <headerColor>#071D2B</headerColor>",
  "        <logo>NTE_Management_Logo</logo>",
  "        <logoVersion>1</logoVersion>",
  "        <shouldOverrideOrgTheme>true</shouldOverrideOrgTheme>",
  "    </brand>",
  "    <defaultLandingTab>standard-home</defaultLandingTab>",
  "    <description>Daily workspace for National Transition Event enquiries, applications, participants, bookings, logistics and follow-up.</description>",
  "    <formFactors>Small</formFactors>",
  "    <formFactors>Large</formFactors>",
  "    <isNavAutoTempTabsDisabled>false</isNavAutoTempTabsDisabled>",
  "    <isNavPersonalizationDisabled>true</isNavPersonalizationDisabled>",
  "    <isNavTabPersistenceDisabled>false</isNavTabPersistenceDisabled>",
  "    <isOmniPinnedViewEnabled>false</isOmniPinnedViewEnabled>",
  "    <label>NTE Management</label>",
  "    <navType>Standard</navType>"
);
for (const tab of ["standard-home", "NTE_Master_Panel", "standard-Lead", "standard-Account", "standard-Contact", "standard-Opportunity", "standard-Task", "standard-Event", "standard-Dashboard", "standard-report"]) appLines.push(`    <tabs>${tab}</tabs>`);
appLines.push("    <uiType>Lightning</uiType>", "</CustomApplication>", "");
write(path.join(md, "applications", "NTE_Management.app-meta.xml"), appLines.join("\n"));

write(path.join(md, "tabs", "NTE_Master_Panel.tab-meta.xml"), [
  '<?xml version="1.0" encoding="UTF-8"?>',
  `<CustomTab xmlns="${ns}">`,
  "    <label>Master Panel</label>",
  "    <lwcComponent>nteMasterPanel</lwcComponent>",
  "    <motif>Custom75: Ticket</motif>",
  "</CustomTab>",
  ""
].join("\n"));

const staticResourceDir = path.join(md, "staticresources");
fs.mkdirSync(staticResourceDir, {recursive: true});
fs.copyFileSync(path.join(root, "assets", "nte-logo-white.png"), path.join(staticResourceDir, "NTE_Management_Logo.resource"));
write(path.join(staticResourceDir, "NTE_Management_Logo.resource-meta.xml"), [
  '<?xml version="1.0" encoding="UTF-8"?>',
  `<StaticResource xmlns="${ns}">`,
  "    <cacheControl>Public</cacheControl>",
  "    <contentType>image/png</contentType>",
  "</StaticResource>",
  ""
].join("\n"));

const contentAssetDir = path.join(md, "contentassets");
fs.mkdirSync(contentAssetDir, {recursive: true});
fs.copyFileSync(path.join(root, "assets", "nte-logo-white.png"), path.join(contentAssetDir, "NTE_Management_Logo.asset"));
write(path.join(contentAssetDir, "NTE_Management_Logo.asset-meta.xml"), [
  '<?xml version="1.0" encoding="UTF-8"?>',
  `<ContentAsset xmlns="${ns}">`,
  "    <format>Original</format>",
  "    <isVisibleByExternalUsers>false</isVisibleByExternalUsers>",
  "    <language>en_US</language>",
  "    <masterLabel>NTE Management Logo</masterLabel>",
  "    <relationships><organization><access>VIEWER</access></organization></relationships>",
  "    <versions><version><number>1</number><pathOnClient>NTE_Management_Logo.png</pathOnClient></version></versions>",
  "</ContentAsset>",
  ""
].join("\n"));

console.log(`Generated fields, ${Object.keys(leadListViews).length + Object.keys(masterPanelOpportunityViews).length + 3} list views, ${Object.keys(nteReports).length} reports, ${Object.keys(templates).length} email templates, 4 flows, 3 permission sets, the NTE Management app, and 5 Lightning pages.`);

require("./build-communications");
require("./build-stripe");
require("./build-stripe-bookings");

require("./build-manual-finance");
require("./build-volunteer-compatibility");
