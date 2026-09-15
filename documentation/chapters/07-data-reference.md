# Salesforce data dictionary

This reference contains all 353 packaged custom field definitions across six record objects and two custom metadata types. Standard object behaviour is described where the project uses it; unrelated Salesforce standard fields are not added as filler. API names, type limits, defaults, formula text, picklist values and relationships below come directly from the frozen source metadata.

A field without a required declaration below is optional at schema level; public form and Apex validation can impose stronger conditional requirements. R means explicit readable-only field access, E means readable and editable, and a dash means this permission set does not grant the field. Other assigned permissions can still grant access. Permission order is Management User / Forms Administration / Volunteer Application User / Stripe Payment Operator. Formula fields remain calculated regardless of a form or caller. Picklist catalogue identifiers refer to the exact reusable sets later in this chapter.

## VAT fields — 13 September 2026

Package and component prices remain net. These 11 fields store or calculate aggregate VAT and gross totals. Formula fields are read-only; stored booking rates preserve accepted charges. The standard Opportunity Amount holds the gross initial booking and excludes later top-ups.

| Field | Definition and access | Role |
| --- | --- | --- |
| Lead.Top_Up_Total_Inc_VAT__c<br>Top-up Total (inc VAT) | Currency(18,2); Formula; blanks=BlankAsBlank; field access R/R/–/– |  |
| Lead.Top_Up_VAT_Total__c<br>Top-up VAT | Currency(18,2); Formula; blanks=BlankAsBlank; field access R/R/–/– |  |
| Lead.Total_Including_VAT__c<br>Booking Total (inc VAT) | Currency(18,2); Stored; field access R/R/–/– |  Fresh conversion pricing maps this value to Opportunity.Amount. |
| Lead.VAT_Rate__c<br>VAT Rate (%) | Number(5,2); Stored; default=20; field access E/E/–/– |  Fresh conversion pricing maps this rate to Opportunity.NTE_VAT_Rate__c. |
| Lead.VAT_Total__c<br>Booking VAT | Currency(18,2); Stored; field access R/R/–/– |  |
| Opportunity.NTE_Top_Up_Total_Inc_VAT__c<br>NTE Top-up Total (inc VAT) | Currency(18,2); Formula; blanks=BlankAsBlank; field access R/R/–/– |  |
| Opportunity.NTE_Top_Up_VAT_Rate__c<br>NTE Top-up VAT Rate (%) | Number(5,2); Stored; default=20; field access E/E/–/– |  |
| Opportunity.NTE_Top_Up_VAT_Total__c<br>NTE Top-up VAT | Currency(18,2); Formula; blanks=BlankAsBlank; field access R/R/–/– |  |
| Opportunity.NTE_Total_Including_VAT__c<br>NTE Booking Total (inc VAT) | Currency(18,2); Formula; blanks=BlankAsBlank; field access R/R/–/– |  |
| Opportunity.NTE_VAT_Rate__c<br>NTE Booking VAT Rate (%) | Number(5,2); Stored; default=20; field access E/E/–/– |  |
| Opportunity.NTE_VAT_Total__c<br>NTE Booking VAT | Currency(18,2); Formula; blanks=BlankAsBlank; field access R/R/–/– |  |

### Lead.Top_Up_Total_Inc_VAT__c

```text
BLANKVALUE(Top_Up_Staff_Total__c, 0) + Top_Up_VAT_Total__c
```

### Lead.Top_Up_VAT_Total__c

```text
ROUND(BLANKVALUE(Top_Up_Staff_Total__c, 0) * BLANKVALUE(VAT_Rate__c, 20) / 100, 2)
```

### Opportunity.NTE_Top_Up_Total_Inc_VAT__c

```text
BLANKVALUE(NTE_Top_Up_Staff_Total__c, 0) + NTE_Top_Up_VAT_Total__c
```

### Opportunity.NTE_Top_Up_VAT_Total__c

```text
ROUND(BLANKVALUE(NTE_Top_Up_Staff_Total__c, 0) * BLANKVALUE(NTE_Top_Up_VAT_Rate__c, 20) / 100, 2)
```

### Opportunity.NTE_Total_Including_VAT__c

```text
IF(NOT(NTE_Pricing_Ready__c), NULL, NTE_Listed_Price_Total__c + NTE_VAT_Total__c)
```

### Opportunity.NTE_VAT_Total__c

```text
IF(NOT(NTE_Pricing_Ready__c), NULL, ROUND(NTE_Listed_Price_Total__c * BLANKVALUE(NTE_VAT_Rate__c, 20) / 100, 2))
```

## Standard objects and fields used


| Object | Relevant standard fields | Project role |
| --- | --- | --- |
| Lead | Id, Company, FirstName, LastName, Email, Phone, MobilePhone, Title, Website, Salutation, Street, PostalCode | Applicant identity and public form standard HTTP mappings. |
| Lead | LeadSource, Status, OwnerId, CreatedDate, LastModifiedDate | Route discrimination, native review state, ownership and dashboard creation-date filtering. |
| Lead | IsConverted, ConvertedOpportunityId, ConvertedAccountId, ConvertedContactId | Exact native conversion outputs consumed by the after-save conversion flow; they are not guessed from latest related records. |
| Opportunity | Id, AccountId, Name, Amount, CloseDate, StageName, IsClosed, IsWon, RecordTypeId, OwnerId | Booking identity and native sales context. Amount is the initial booking total including VAT; stage/close date are native values, separate from payment and readiness flags. |
| OpportunityContactRole | OpportunityId, ContactId, IsPrimary, Role | Many booking/person associations, with exactly one usable Primary required by this code. The native schema alone does not guarantee that invariant. |
| Account and Contact | Id, Name, AccountId on Contact, Email/Phone where applicable, OwnerId | Reusable organisation/person identity and record navigation. Contact.AccountId does not substitute for its booking role. |
| Task | WhoId, WhatId, Subject, Description, Status, ActivityDate | Approval/legacy communication audit and ordinary activities. The controller discovers a closed Task status for compatibility. |
| User and RecordType | User.Username, Email, IsActive; RecordType.DeveloperName, SobjectType | Exact routing and NTE_Event_Opportunity discrimination. |
| EmailTemplate and Report | DeveloperName and Id | Runtime resolves portable developer names to destination-specific record IDs. Report IDs and template IDs are not hardcoded into the UI. |



## Lead

API name: Lead. 150 packaged fields. One public submission, not one permanent participant. Main applications remain here until native conversion; EOI and guests remain Leads. Supplementary staff/vehicle Leads are temporary only after both applied data and accepted receipt; logo Leads remain as audit records. Applicant and internal email outcomes are independent. Form fields record submitted facts; pricing/audit fields are overwritten by their authoritative services. Volunteer fields share this object but use the distinct volunteer flow/source and do not enter NTE edition queues.


| Field and exact definition | Meaning and data lineage |
| --- | --- |
| Accompanying_Guest_Email__c<br>Accompanying Guest Email<br>Email; required=false; trackFeedHistory=false<br>Field access E/E/–/– | Submitted by: guest-registration.html |
| Accompanying_Guest_Name__c<br>Accompanying Guest Name<br>Text(200); required=false; trackFeedHistory=false<br>Field access E/E/–/– | Submitted by: guest-registration.html |
| Additional_Staff_Count__c<br>Additional Staff Count<br>Picklist; required=false; trackFeedHistory=false; values PL01, restricted=true<br>Field access E/E/–/– | Initial chargeable staff above the package allowance. Accepts calculated values from 0 to 99. Submitted by: exhibitor-application.html, partner-sponsor-application.html Conversion destinations: Opportunity.NTE_Additional_Staff_Count__c |
| Additional_Staff_Required__c<br>Additional Staff Required<br>Picklist; required=false; trackFeedHistory=false; values PL02, restricted=true<br>Field access E/E/–/– | Captured by the NTE27 exhibitor Web-to-Lead form. Submitted by: exhibitor-application.html, partner-sponsor-application.html Conversion destinations: Opportunity.NTE_Additional_Staff_Required__c |
| Additional_Staff_Total__c<br>Additional Staff Total (ex VAT)<br>Currency(18,2); required=false; trackFeedHistory=false<br>Field access E/E/–/– | Submitted by: exhibitor-application.html, partner-sponsor-application.html Conversion destinations: Opportunity.NTE_Additional_Staff_Total__c |
| Additional_Staff_Unit_Price__c<br>Additional Staff Unit Price (ex VAT)<br>Currency(18,2); required=false; trackFeedHistory=false<br>Field access E/E/–/– | Submitted by: exhibitor-application.html, partner-sponsor-application.html Conversion destinations: Opportunity.NTE_Additional_Staff_Unit_Price__c |
| Alternative_Organisation_Name__c<br>Alternative Organisation Name<br>Text(255); required=false; unique=false; externalId=false; trackFeedHistory=false<br>Field access E/E/–/– | Captured by the NTE27 exhibitor Web-to-Lead form. Conversion destinations: Opportunity.NTE_Alternative_Organisation_Name__c |
| Booking_Reference__c<br>NTE Booking Reference<br>Text(80); required=false; unique=true; externalId=true; caseSensitive=false; trackFeedHistory=false<br>Field access E/E/–/– | Unique browser-generated reference for the original NTE application. Submitted by: exhibitor-application.html, partner-sponsor-application.html Conversion destinations: Opportunity.Booking_Reference__c, Account.NTE_Booking_Reference__c, Contact.NTE_Booking_Reference__c |
| Consent_Contact__c<br>Consent Contact<br>Checkbox; required=false; defaultValue=false; trackFeedHistory=false<br>Field access –/–/E/– | Submitted by: volunteer-application.html |
| Consent_PII__c<br>Consent PII<br>Checkbox; required=false; defaultValue=false; trackFeedHistory=false<br>Field access –/–/E/– | Submitted by: volunteer-application.html |
| Consent_Promotion__c<br>Consent Promotion<br>Checkbox; required=false; defaultValue=false; trackFeedHistory=false<br>Field access –/–/E/– | Submitted by: volunteer-application.html |
| Contact_Consent__c<br>NTE Contact Consent<br>Checkbox; required=false; defaultValue=false; trackFeedHistory=false<br>Field access E/E/–/– | Submitted by: exhibitor-interest.html, partner-sponsor-interest.html |
| Date_of_Birth__c<br>Date of Birth<br>Date; required=false; trackFeedHistory=false<br>Field access –/–/E/– | Help: DOB needed for info validaton Submitted by: volunteer-application.html |
| Declaration_Date__c<br>Declaration Date<br>Date; required=false; trackFeedHistory=false<br>Field access E/E/E/– | Submitted by: exhibitor-application.html, exhibitor-interest.html, exhibitor-staff-update.html, guest-registration.html, heavy-vehicle-details.html, partner-sponsor-application.html, partner-sponsor-interest.html, partner-sponsor-staff-update.html, volunteer-application.html Conversion destinations: Opportunity.NTE_Declaration_Date__c |
| Declaration_Name__c<br>Declaration Name<br>Text(200); required=false; unique=false; externalId=false; trackFeedHistory=false<br>Field access E/E/E/– | Captured by the NTE27 exhibitor Web-to-Lead form. Submitted by: exhibitor-application.html, exhibitor-interest.html, exhibitor-staff-update.html, guest-registration.html, heavy-vehicle-details.html, partner-sponsor-application.html, partner-sponsor-interest.html, partner-sponsor-staff-update.html, volunteer-application.html Conversion destinations: Opportunity.NTE_Declaration_Name__c |
| Delivery_Window__c<br>Delivery Window<br>Picklist; required=false; trackFeedHistory=false; values PL03, restricted=true<br>Field access E/E/–/– | Submitted by: heavy-vehicle-details.html |
| Event_Contact_Email__c<br>Event Contact Email<br>Email; required=false; unique=false; externalId=false; trackFeedHistory=false<br>Field access E/E/–/– | Submitted by: exhibitor-application.html, heavy-vehicle-details.html, partner-sponsor-application.html Conversion destinations: Opportunity.NTE_Event_Contact_Email__c |
| Event_Contact_Mobile__c<br>Event Contact Mobile<br>Phone; required=false; trackFeedHistory=false<br>Field access E/E/–/– | Submitted by: exhibitor-application.html, heavy-vehicle-details.html, partner-sponsor-application.html Conversion destinations: Opportunity.NTE_Event_Contact_Mobile__c |
| Event_Contact_Name__c<br>Event Contact Name<br>Text(200); required=false; unique=false; externalId=false; trackFeedHistory=false<br>Field access E/E/–/– | Submitted by: exhibitor-application.html, heavy-vehicle-details.html, partner-sponsor-application.html Conversion destinations: Opportunity.NTE_Event_Contact_Name__c |
| Event_Contact_Title__c<br>Event Contact Job Title<br>Text(128); required=false; trackFeedHistory=false<br>Field access E/E/–/– | Submitted by: exhibitor-application.html, partner-sponsor-application.html Conversion destinations: Opportunity.NTE_Event_Contact_Title__c |
| Event_Discovery_Source__c<br>Event Discovery Source<br>Picklist; required=false; trackFeedHistory=false; values PL04, restricted=true<br>Field access E/E/–/– | How the person discovered the National Transition Event. Submitted by: exhibitor-application.html, exhibitor-interest.html, partner-sponsor-interest.html Conversion destinations: Opportunity.NTE_Event_Discovery_Source__c |
| Exhibitor_Community_Contribution__c<br>Exhibitor Community Contribution<br>LongTextArea(32768); required=false; trackFeedHistory=false; visibleLines=4<br>Field access E/E/–/– | Submitted by: exhibitor-interest.html |
| Exhibitor_Hall_Schedule__c<br>Sunday Setup Availability<br>Picklist; required=false; trackFeedHistory=false; values PL05, restricted=true<br>Field access E/E/–/– | Submitted by: exhibitor-application.html, partner-sponsor-application.html Conversion destinations: Opportunity.NTE_Exhibitor_Hall_Schedule__c |
| Exhibitor_Interest_Areas__c<br>Exhibitor Interest Areas<br>MultiselectPicklist; required=false; trackFeedHistory=false; visibleLines=4; values PL06, restricted=true<br>Field access E/E/–/– | Retained interest classification field. The current exhibitor-interest page uses the detailed interest/contribution questions instead; do not add this control solely because the field remains packaged. |
| Exhibitor_Interest_Detail__c<br>Exhibitor Interest Detail<br>LongTextArea(32768); required=false; trackFeedHistory=false; visibleLines=4<br>Field access E/E/–/– | Submitted by: exhibitor-interest.html |
| Exhibitor_Organisation_Category__c<br>Exhibitor Organisation Category<br>Picklist; required=false; trackFeedHistory=false; values PL07, restricted=true<br>Field access E/E/–/– | Captured by the NTE27 exhibitor Web-to-Lead form. Submitted by: exhibitor-application.html Conversion destinations: Opportunity.NTE_Exhibitor_Organisation_Category__c |
| Exhibitor_Space_Position__c<br>Exhibitor Space Position<br>LongTextArea(1000); required=false; trackFeedHistory=false; visibleLines=5<br>Field access E/E/–/– | Retained older space-position value for compatibility. Current pricing uses the single exact Exhibitor_Space_Selections__c choice. Conversion destinations: Opportunity.NTE_Exhibitor_Space_Position__c |
| Exhibitor_Space_Price__c<br>Exhibitor Space Price (ex VAT)<br>Currency(18,2); required=false; trackFeedHistory=false<br>Field access E/E/–/– | Submitted by: exhibitor-application.html, partner-sponsor-application.html Conversion destinations: Opportunity.NTE_Exhibitor_Space_Price__c |
| Exhibitor_Space_Selections__c<br>Exhibitor Space Selections<br>MultiselectPicklist; required=false; trackFeedHistory=false; visibleLines=8; values PL08, restricted=true<br>Field access E/E/–/– | Captured by the NTE27 exhibitor Web-to-Lead form. Submitted by: exhibitor-application.html Conversion destinations: Opportunity.NTE_Exhibitor_Space_Selections__c |
| Exhibitor_Space_Size__c<br>Exhibitor Space Size<br>Picklist; required=false; trackFeedHistory=false; values PL09, restricted=true<br>Field access E/E/–/– | Retained older space-size value for compatibility. Current pricing and staff allowance use the selected catalogue space. Conversion destinations: Opportunity.NTE_Exhibitor_Space_Size__c |
| Form_Version__c<br>NTE Form Version<br>Text(80); required=false; trackFeedHistory=false<br>Field access E/E/–/– | Submitted by: exhibitor-application.html, exhibitor-interest.html, exhibitor-staff-update.html, guest-registration.html, heavy-vehicle-details.html, logo-upload.html, partner-sponsor-application.html, partner-sponsor-interest.html, partner-sponsor-staff-update.html Conversion destinations: Opportunity.NTE_Form_Version__c |
| Guest_Accessibility_Details__c<br>Guest Accessibility Details<br>LongTextArea(32768); required=false; trackFeedHistory=false; visibleLines=4<br>Field access E/E/–/– | Submitted by: guest-registration.html |
| Guest_Accessibility_Required__c<br>Guest Accessibility Required<br>Picklist; required=false; trackFeedHistory=false; values PL05, restricted=true<br>Field access E/E/–/– | Submitted by: guest-registration.html |
| Guest_Accompanying__c<br>Guest Accompanying<br>Picklist; required=false; trackFeedHistory=false; values PL05, restricted=true<br>Field access E/E/–/– | Submitted by: guest-registration.html |
| Guest_Information_Declaration__c<br>Guest Information Declaration<br>Checkbox; required=false; defaultValue=false; trackFeedHistory=false<br>Field access E/E/–/– | Submitted by: guest-registration.html |
| Has_Special_Requirements__c<br>Has Special Requirements<br>Picklist; required=false; trackFeedHistory=false; values PL05, restricted=true<br>Field access E/E/–/– | Captured by the NTE27 exhibitor Web-to-Lead form. Submitted by: exhibitor-application.html, partner-sponsor-application.html Conversion destinations: Opportunity.NTE_Has_Special_Requirements__c |
| Haulier_Name__c<br>Haulier Name<br>Text(255); required=false; trackFeedHistory=false<br>Field access E/E/–/– | Submitted by: heavy-vehicle-details.html |
| Haulier_Staff__c<br>Haulier Staff<br>LongTextArea(32768); required=false; trackFeedHistory=false; visibleLines=4<br>Field access E/E/–/– | Submitted by: heavy-vehicle-details.html |
| Haulier_Vehicle_Dimensions__c<br>Haulier Vehicle Dimensions<br>Text(120); required=false; trackFeedHistory=false<br>Field access E/E/–/– | Submitted by: heavy-vehicle-details.html |
| Haulier_Vehicle_Gross_Weight__c<br>Haulier Vehicle Gross Weight<br>Text(120); required=false; trackFeedHistory=false<br>Field access E/E/–/– | Submitted by: heavy-vehicle-details.html |
| Haulier_Vehicle_Registration__c<br>Haulier Vehicle Registration<br>Text(80); required=false; trackFeedHistory=false<br>Field access E/E/–/– | Submitted by: heavy-vehicle-details.html |
| Haulier_Vehicle_Type__c<br>Haulier Vehicle Type<br>Text(255); required=false; trackFeedHistory=false<br>Field access E/E/–/– | Submitted by: heavy-vehicle-details.html |
| Heavy_Item_1_Description__c<br>Heavy Item 1 Description<br>Text(255); required=false; trackFeedHistory=false<br>Field access E/E/–/– | Submitted by: heavy-vehicle-details.html |
| Heavy_Item_1_Dimensions__c<br>Heavy Item 1 Dimensions<br>Text(120); required=false; trackFeedHistory=false<br>Field access E/E/–/– | Submitted by: heavy-vehicle-details.html |
| Heavy_Item_1_Gross_Weight__c<br>Heavy Item 1 Gross Weight<br>Text(120); required=false; trackFeedHistory=false<br>Field access E/E/–/– | Submitted by: heavy-vehicle-details.html |
| Heavy_Item_1_Registration__c<br>Heavy Item 1 Registration<br>Text(80); required=false; trackFeedHistory=false<br>Field access E/E/–/– | Submitted by: heavy-vehicle-details.html |
| Heavy_Item_2_Description__c<br>Heavy Item 2 Description<br>Text(255); required=false; trackFeedHistory=false<br>Field access E/E/–/– | Submitted by: heavy-vehicle-details.html |
| Heavy_Item_2_Dimensions__c<br>Heavy Item 2 Dimensions<br>Text(120); required=false; trackFeedHistory=false<br>Field access E/E/–/– | Submitted by: heavy-vehicle-details.html |
| Heavy_Item_2_Gross_Weight__c<br>Heavy Item 2 Gross Weight<br>Text(120); required=false; trackFeedHistory=false<br>Field access E/E/–/– | Submitted by: heavy-vehicle-details.html |
| Heavy_Item_2_Registration__c<br>Heavy Item 2 Registration<br>Text(80); required=false; trackFeedHistory=false<br>Field access E/E/–/– | Submitted by: heavy-vehicle-details.html |
| Heavy_Item_3_Description__c<br>Heavy Item 3 Description<br>Text(255); required=false; trackFeedHistory=false<br>Field access E/E/–/– | Submitted by: heavy-vehicle-details.html |
| Heavy_Item_3_Dimensions__c<br>Heavy Item 3 Dimensions<br>Text(120); required=false; trackFeedHistory=false<br>Field access E/E/–/– | Submitted by: heavy-vehicle-details.html |
| Heavy_Item_3_Gross_Weight__c<br>Heavy Item 3 Gross Weight<br>Text(120); required=false; trackFeedHistory=false<br>Field access E/E/–/– | Submitted by: heavy-vehicle-details.html |
| Heavy_Item_3_Registration__c<br>Heavy Item 3 Registration<br>Text(80); required=false; trackFeedHistory=false<br>Field access E/E/–/– | Submitted by: heavy-vehicle-details.html |
| Heavy_Vehicle_Required__c<br>Heavy Vehicle Required<br>Picklist; required=false; trackFeedHistory=false; values PL10, restricted=true<br>Field access E/E/–/– | Submitted by: exhibitor-application.html, partner-sponsor-application.html Conversion destinations: Opportunity.NTE_Heavy_Vehicle_Required__c |
| Included_Staff_Count__c<br>Included Staff Count<br>Number(2,0); required=false; trackFeedHistory=false<br>Field access E/E/–/– | Submitted by: exhibitor-application.html, partner-sponsor-application.html Conversion destinations: Opportunity.NTE_Included_Staff_Count__c |
| Industry_Body_Details__c<br>Industry Body / Trade Association<br>Text(255); required=false; unique=false; externalId=false; trackFeedHistory=false<br>Field access E/E/–/– | Captured by the NTE27 exhibitor Web-to-Lead form. Submitted by: exhibitor-application.html Conversion destinations: Opportunity.NTE_Industry_Body_Details__c |
| Interested_in_Volunteering__c<br>Volunteering<br>Checkbox; required=false; defaultValue=false; trackFeedHistory=false<br>Field access –/–/E/– | Submitted by: volunteer-application.html |
| Invoice_Additional_Information__c<br>Invoice Additional Information<br>LongTextArea(32768); required=false; trackFeedHistory=false; visibleLines=4<br>Field access E/E/–/– | Submitted by: exhibitor-application.html, partner-sponsor-application.html Conversion destinations: Opportunity.NTE_Invoice_Additional_Information__c |
| Invoice_Address__c<br>Invoice Address<br>LongTextArea(1000); required=false; trackFeedHistory=false; visibleLines=5<br>Field access E/E/–/– | Submitted by: exhibitor-application.html, partner-sponsor-application.html Conversion destinations: Opportunity.NTE_Invoice_Address__c |
| Invoice_Contact_Phone__c<br>Invoice Contact Phone<br>Phone; required=false; trackFeedHistory=false<br>Field access E/E/–/– | Captured by the NTE27 exhibitor Web-to-Lead form. Submitted by: exhibitor-application.html, partner-sponsor-application.html Conversion destinations: Opportunity.NTE_Invoice_Contact_Phone__c |
| Invoice_Required__c<br>Invoice Required<br>Picklist; required=false; trackFeedHistory=false; values PL05, restricted=true<br>Field access E/E/–/– | Submitted by: exhibitor-application.html, partner-sponsor-application.html Conversion destinations: Opportunity.NTE_Invoice_Required__c |
| Invoiced_Company__c<br>Invoiced Company<br>Text(200); required=false; unique=false; externalId=false; trackFeedHistory=false<br>Field access E/E/–/– | Submitted by: exhibitor-application.html, partner-sponsor-application.html Conversion destinations: Opportunity.NTE_Invoiced_Company__c |
| Invoiced_Email__c<br>Invoiced Email<br>Email; required=false; unique=false; externalId=false; trackFeedHistory=false<br>Field access E/E/–/– | Submitted by: exhibitor-application.html, partner-sponsor-application.html Conversion destinations: Opportunity.NTE_Invoiced_Email__c |
| Invoiced_Person__c<br>Invoiced Person<br>Text(200); required=false; unique=false; externalId=false; trackFeedHistory=false<br>Field access E/E/–/– | Submitted by: exhibitor-application.html, partner-sponsor-application.html Conversion destinations: Opportunity.NTE_Invoiced_Person__c |
| Listed_Price_Total__c<br>Booking Total (ex VAT)<br>Currency(18,2); required=false; trackFeedHistory=false<br>Field access E/E/–/– | Submitted by: exhibitor-application.html, partner-sponsor-application.html Conversion destinations: Opportunity.NTE_Listed_Price_Total__c |
| Logo_Upload_URL__c<br>NTE Logo Upload URL<br>Text(255); required=false; trackFeedHistory=false<br>Field access E/E/–/– | Submitted by: exhibitor-application.html, partner-sponsor-application.html |
| NOK_Address__c<br>Emergency Contact Address<br>LongTextArea(1000); required=false; trackFeedHistory=false; visibleLines=4<br>Field access –/–/E/– | Submitted by: volunteer-application.html |
| NOK_Name__c<br>Next of Kin Name<br>Text(100); required=false; unique=false; externalId=false; trackFeedHistory=false<br>Field access –/–/E/– | Submitted by: volunteer-application.html |
| NOK_Phone__c<br>Next of Kin Phone<br>Phone; required=false; trackFeedHistory=false<br>Field access –/–/E/– | Submitted by: volunteer-application.html |
| NOK_Postcode__c<br>Emergency Contact Postcode<br>Text(20); required=false; trackFeedHistory=false<br>Field access –/–/E/– | Submitted by: volunteer-application.html |
| NOK_Relationship__c<br>Relationship to Next of Kin<br>Text(255); required=false; unique=false; externalId=false; trackFeedHistory=false<br>Field access –/–/E/– | Submitted by: volunteer-application.html |
| NTE_Applicant_Email_Status__c<br>NTE Applicant Email Status<br>Picklist; required=false; trackFeedHistory=false; values PL11, restricted=true<br>Field access E/E/–/– | Applicant-side initial NTE receipt outcome. Applications deliberately have no applicant receipt here; EOI/guest use their route template. A later retry must preserve an accepted side. |
| NTE_Application_Rejected__c<br>Application Rejected<br>Checkbox; required=false; defaultValue=false; trackFeedHistory=false<br>Field access E/E/–/– | Operator rejection removes an unconverted application from active panel/list review while retaining the Lead for history. |
| NTE_Email_Error__c<br>NTE Email Error<br>LongTextArea(32768); required=false; trackFeedHistory=false; visibleLines=3<br>Field access E/E/–/– | Combined failed-side errors for initial NTE intake; it does not describe the separate supplementary or approval email path. |
| NTE_Event_Code__c<br>NTE Event Code<br>Text(20); required=false; unique=false; externalId=true; trackFeedHistory=false<br>Field access E/E/–/– | Evergreen NTE edition code calculated in Europe/London, for example NTE27. Submitted by: exhibitor-application.html, exhibitor-interest.html, exhibitor-staff-update.html, guest-registration.html, heavy-vehicle-details.html, logo-upload.html, partner-sponsor-application.html, partner-sponsor-interest.html, partner-sponsor-staff-update.html Conversion destinations: Opportunity.NTE_Event_Code__c, Account.NTE_Event_Code__c, Contact.NTE_Event_Code__c |
| NTE_Interest_Not_Progressed__c<br>Interest Not Progressed<br>Checkbox; required=false; defaultValue=false; trackFeedHistory=false<br>Field access E/E/–/– | Recorded rejection/not-progressed decision for an interest. Mutually exclusive with progressed; no Lead deletion occurs. |
| NTE_Interest_Progressed__c<br>Interest Progressed<br>Checkbox; required=false; defaultValue=false; trackFeedHistory=false<br>Field access E/E/–/– | Interest has progressed after accepted application invitation. The retired manual progression action cannot substitute for a send. |
| NTE_Internal_Email_Status__c<br>NTE Internal Email Status<br>Picklist; required=false; trackFeedHistory=false; values PL12, restricted=true<br>Field access E/E/–/– | Independent outcome of the internal NTE intake notification to the configured routing user. |
| NTE_Invitation_Recipient__c<br>NTE Invitation Recipient<br>Email; required=false<br>Field access E/E/–/– | Address recorded for the accepted invitation, preserving whom that progression reached. |
| NTE_Invitation_Sent_At__c<br>NTE Invitation Sent At<br>DateTime; required=false<br>Field access E/E/–/– | Timestamp of Salesforce acceptance for the invitation; not an inbox-open or delivery receipt. |
| NTE_Invitation_Status__c<br>NTE Invitation Status<br>Text(20); required=false<br>Field access E/E/–/– | Mirrors the invitation dispatch lifecycle. Queued/Sent prevents stale rejection or another overlapping invitation request. |
| NTE_Update_Booking_Id__c<br>Applied NTE Booking ID<br>Text(18); required=false; trackFeedHistory=false<br>Field access R/R/–/– | Opportunity ID recorded by the supplementary update service when the update is accepted. Acknowledgement retries use this booking and must never rematch to a different reference. |
| NTE_Update_Error__c<br>NTE Update Error<br>LongTextArea(32768); required=false; trackFeedHistory=false; visibleLines=3<br>Field access E/E/–/– | Reason an update could not match/apply or an unexpected worker failed; retained for administrative recovery. |
| NTE_Update_Status__c<br>NTE Update Status<br>Picklist; required=false; trackFeedHistory=false; values PL13, restricted=true<br>Field access E/E/–/– | Supplementary matching/application outcome. A matched or applied update is separate from its acknowledgement email outcome. |
| Organisation_Type__c<br>Organisation Type<br>Picklist; required=false; trackFeedHistory=false; values PL14, restricted=true<br>Field access E/E/–/– | Submitted by: exhibitor-interest.html, partner-sponsor-interest.html |
| Partner_Interest_Areas__c<br>Partner Interest Areas<br>MultiselectPicklist; required=false; trackFeedHistory=false; visibleLines=4; values PL15, restricted=true<br>Field access E/E/–/– | Submitted by: partner-sponsor-interest.html |
| Partner_Interest_Type__c<br>Partner Interest Type<br>Picklist; required=false; trackFeedHistory=false; values PL16, restricted=true<br>Field access E/E/–/– | Submitted by: partner-sponsor-interest.html |
| Partnership_Interest_Detail__c<br>Partnership Interest Detail<br>LongTextArea(32768); required=false; trackFeedHistory=false; visibleLines=4<br>Field access E/E/–/– | Submitted by: partner-sponsor-interest.html |
| Payment_Method__c<br>Payment Method<br>Picklist; required=false; trackFeedHistory=false; values PL17, restricted=true<br>Field access E/E/–/– | Submitted by: exhibitor-application.html, partner-sponsor-application.html Conversion destinations: Opportunity.NTE_Payment_Method__c |
| Planned_Exhibitor_Count__c<br>Planned Exhibitor Count<br>Picklist; required=false; trackFeedHistory=false; values PL18, restricted=true<br>Field access E/E/–/– | Total people initially planned for the NTE booking. Accepts the public form range from 1 to 99. Submitted by: exhibitor-application.html, exhibitor-staff-update.html, partner-sponsor-application.html, partner-sponsor-staff-update.html Conversion destinations: Opportunity.NTE_Planned_Exhibitor_Count__c |
| Power_Socket_Count__c<br>Power Socket Count<br>Number(2,0); required=false; trackFeedHistory=false<br>Field access E/E/–/– | Submitted by: exhibitor-application.html Conversion destinations: Opportunity.NTE_Power_Socket_Count__c |
| Power_Socket_Total__c<br>Power Socket Total (ex VAT)<br>Currency(18,2); required=false; trackFeedHistory=false<br>Field access E/E/–/– | Submitted by: exhibitor-application.html, partner-sponsor-application.html Conversion destinations: Opportunity.NTE_Power_Socket_Total__c |
| Power_Socket_Unit_Price__c<br>Power Socket Unit Price (ex VAT)<br>Currency(18,2); required=false; trackFeedHistory=false<br>Field access E/E/–/– | Submitted by: exhibitor-application.html, partner-sponsor-application.html Conversion destinations: Opportunity.NTE_Power_Socket_Unit_Price__c |
| Preferred_Contact_Method__c<br>Preferred Contact Method<br>Picklist; required=false; trackFeedHistory=false; values PL19, restricted=true<br>Field access E/E/–/– | Submitted by: exhibitor-interest.html, partner-sponsor-interest.html |
| Preferred_Contact_Time__c<br>Preferred Contact Time<br>Text(255); required=false; trackFeedHistory=false<br>Field access E/E/–/– | Submitted by: exhibitor-interest.html, partner-sponsor-interest.html |
| Previous_NTE_Events__c<br>Previous NTE Events<br>MultiselectPicklist; required=false; trackFeedHistory=false; visibleLines=4; values PL20, restricted=true<br>Field access E/E/–/– | Captured by the NTE27 exhibitor Web-to-Lead form. Submitted by: exhibitor-application.html Conversion destinations: Opportunity.NTE_Previous_Events__c |
| Pricing_Status__c<br>Pricing Status<br>Picklist; required=false; trackFeedHistory=false; values PL21, restricted=true<br>Field access E/E/–/– | Submitted by: exhibitor-application.html, partner-sponsor-application.html Conversion destinations: Opportunity.NTE_Pricing_Status__c |
| Pricing_Version__c<br>Pricing Version<br>Text(80); required=false; trackFeedHistory=false<br>Field access E/E/–/– | Submitted by: exhibitor-application.html, partner-sponsor-application.html Conversion destinations: Opportunity.NTE_Pricing_Version__c |
| Purchase_Order_Number__c<br>Purchase Order Number<br>Text(100); required=false; unique=false; externalId=false; trackFeedHistory=false<br>Field access E/E/–/– | Captured by the NTE27 exhibitor Web-to-Lead form. Submitted by: exhibitor-application.html, partner-sponsor-application.html Conversion destinations: Opportunity.NTE_Purchase_Order_Number__c |
| Purchase_Order__c<br>Purchase Order<br>Picklist; required=false; trackFeedHistory=false; values PL05, restricted=true<br>Field access E/E/–/– | Submitted by: exhibitor-application.html, partner-sponsor-application.html Conversion destinations: Opportunity.NTE_Purchase_Order__c |
| Quote_Required_for_PO__c<br>Quotation Required for PO<br>Picklist; required=false; trackFeedHistory=false; values PL05, restricted=true<br>Field access E/E/–/– | Submitted by: exhibitor-application.html, partner-sponsor-application.html Conversion destinations: Opportunity.NTE_Quote_Required_for_PO__c |
| Secondary_Contact_Email__c<br>Secondary Contact Email<br>Email; required=false; unique=false; externalId=false; trackFeedHistory=false<br>Field access E/E/–/– | Captured by the NTE27 exhibitor Web-to-Lead form. Submitted by: exhibitor-application.html, heavy-vehicle-details.html Conversion destinations: Opportunity.NTE_Secondary_Contact_Email__c |
| Secondary_Contact_Mobile__c<br>Secondary Contact Mobile<br>Phone; required=false; trackFeedHistory=false<br>Field access E/E/–/– | Captured by the NTE27 exhibitor Web-to-Lead form. Submitted by: exhibitor-application.html Conversion destinations: Opportunity.NTE_Secondary_Contact_Mobile__c |
| Secondary_Contact_Name__c<br>Secondary Contact Full Name<br>Text(200); required=false; unique=false; externalId=false; trackFeedHistory=false<br>Field access E/E/–/– | Captured by the NTE27 exhibitor Web-to-Lead form. Submitted by: exhibitor-application.html, heavy-vehicle-details.html Conversion destinations: Opportunity.NTE_Secondary_Contact_Name__c |
| Secondary_Contact_Phone__c<br>Secondary Contact Work Phone<br>Phone; required=false; trackFeedHistory=false<br>Field access E/E/–/– | Captured by the NTE27 exhibitor Web-to-Lead form. Submitted by: exhibitor-application.html, heavy-vehicle-details.html Conversion destinations: Opportunity.NTE_Secondary_Contact_Phone__c |
| Secondary_Contact_Prefix__c<br>Secondary Contact Prefix<br>Text(40); required=false; unique=false; externalId=false; trackFeedHistory=false<br>Field access E/E/–/– | Captured by the NTE27 exhibitor Web-to-Lead form. Submitted by: exhibitor-application.html Conversion destinations: Opportunity.NTE_Secondary_Contact_Prefix__c |
| Secondary_Contact_Title__c<br>Secondary Contact Job Title<br>Text(128); required=false; unique=false; externalId=false; trackFeedHistory=false<br>Field access E/E/–/– | Captured by the NTE27 exhibitor Web-to-Lead form. Submitted by: exhibitor-application.html Conversion destinations: Opportunity.NTE_Secondary_Contact_Title__c |
| Sponsor_Package_Total__c<br>Sponsor Package Total (ex VAT)<br>Currency(18,2); required=false; trackFeedHistory=false<br>Field access E/E/–/– | Submitted by: exhibitor-application.html, partner-sponsor-application.html Conversion destinations: Opportunity.NTE_Sponsor_Package_Total__c |
| Sponsor_Package__c<br>Sponsorship Package<br>MultiselectPicklist; required=false; trackFeedHistory=false; visibleLines=5; values PL22, restricted=true<br>Field access E/E/–/– | Sponsorship packages selected by the applicant. Submitted by: partner-sponsor-application.html Conversion destinations: Opportunity.NTE_Sponsor_Package__c |
| Sponsored_Name__c<br>Sponsored Name<br>Text(200); required=false; unique=false; externalId=false; trackFeedHistory=false<br>Field access E/E/–/– | Name of person applying for sponsorship. Submitted by: partner-sponsor-application.html Conversion destinations: Opportunity.NTE_Sponsored_Name__c |
| Staff_Base_Names__c<br>Staff Names Covered by Booking<br>LongTextArea(32768); required=false; trackFeedHistory=false; visibleLines=8<br>Field access E/E/–/– | Submitted by: exhibitor-staff-update.html, partner-sponsor-staff-update.html |
| Staff_Update_Audience__c<br>Staff Update Audience<br>Picklist; required=false; trackFeedHistory=false; values PL23, restricted=true<br>Field access E/E/–/– | Submitted by: exhibitor-staff-update.html, partner-sponsor-staff-update.html |
| Stand_Colleagues__c<br>Stand Colleagues<br>LongTextArea(1000); required=false; trackFeedHistory=false; visibleLines=5<br>Field access E/E/–/– | Retained older submitted staff-name field. Current supplementary forms use separate initial/top-up roster fields; the Opportunity consolidated roster remains operational. Conversion destinations: Opportunity.NTE_Stand_Colleagues__c |
| Stand_Equipment__c<br>Stand Equipment<br>LongTextArea(1000); required=false; trackFeedHistory=false; visibleLines=5<br>Field access E/E/–/– | Submitted by: exhibitor-application.html, partner-sponsor-application.html Conversion destinations: Opportunity.NTE_Stand_Equipment__c |
| Stand_Extra_Notes__c<br>Stand Extra Notes<br>LongTextArea(1000); required=false; trackFeedHistory=false; visibleLines=5<br>Field access E/E/–/– | Submitted by: partner-sponsor-application.html Conversion destinations: Opportunity.NTE_Stand_Extra_Notes__c |
| Stand_Power__c<br>Stand Power<br>Picklist; required=false; trackFeedHistory=false; values PL05, restricted=true<br>Field access E/E/–/– | Submitted by: exhibitor-application.html, partner-sponsor-application.html Conversion destinations: Opportunity.NTE_Stand_Power__c |
| Stand_Special_Requirements__c<br>Stand Special Requirements<br>LongTextArea(1000); required=false; trackFeedHistory=false; visibleLines=5<br>Field access E/E/–/– | Submitted by: exhibitor-application.html, partner-sponsor-application.html Conversion destinations: Opportunity.NTE_Stand_Special_Requirements__c |
| Supplier_Agreement_Required__c<br>Supplier Agreement Required<br>Picklist; required=false; trackFeedHistory=false; values PL02, restricted=true<br>Field access E/E/–/– | Captured by the NTE27 exhibitor Web-to-Lead form. Submitted by: exhibitor-application.html, partner-sponsor-application.html Conversion destinations: Opportunity.NTE_Supplier_Agreement_Required__c |
| Target_Booking_Reference__c<br>Target NTE Booking Reference<br>Text(80); required=false; unique=false; externalId=false; caseSensitive=false; trackFeedHistory=false<br>Field access E/E/–/– | Exact original booking reference supplied on an NTE supplementary form. Submitted by: exhibitor-staff-update.html, heavy-vehicle-details.html, logo-upload.html, partner-sponsor-staff-update.html |
| Terms_and_Conditions__c<br>Terms and Conditions<br>Checkbox; required=false; defaultValue=false; trackFeedHistory=false<br>Field access E/E/–/– | Submitted by: exhibitor-application.html, partner-sponsor-application.html Conversion destinations: Opportunity.NTE_Terms_Accepted__c |
| Top_Up_Staff_Count__c<br>Top-up Staff Count<br>Number(2,0); required=false; trackFeedHistory=false<br>Field access E/E/–/– | Submitted by: exhibitor-staff-update.html |
| Top_Up_Staff_Names__c<br>Top-up Staff Names<br>LongTextArea(32768); required=false; trackFeedHistory=false; visibleLines=6<br>Field access E/E/–/– | Submitted by: exhibitor-staff-update.html |
| Top_Up_Staff_Required__c<br>Top-up Staff Required<br>Picklist; required=false; trackFeedHistory=false; values PL05, restricted=true<br>Field access E/E/–/– | Submitted by: exhibitor-staff-update.html |
| Top_Up_Staff_Total__c<br>Top-up Staff Total (ex VAT)<br>Currency(18,2); required=false; trackFeedHistory=false<br>Field access E/E/–/– | Submitted by: exhibitor-staff-update.html |
| Top_Up_Staff_Unit_Price__c<br>Top-up Staff Unit Price (ex VAT)<br>Currency(18,2); required=false; trackFeedHistory=false<br>Field access E/E/–/– | Submitted by: exhibitor-staff-update.html |
| Total_Staff_Count__c<br>Total Staff Count<br>Number(2,0); required=false; trackFeedHistory=false<br>Field access E/E/–/– | Submitted by: exhibitor-application.html, exhibitor-staff-update.html, partner-sponsor-application.html, partner-sponsor-staff-update.html Conversion destinations: Opportunity.NTE_Initial_Staff_Count__c, Opportunity.NTE_Total_Staff_Count__c |
| Trading_Name__c<br>Trading Name<br>Text(255); required=false; trackFeedHistory=false<br>Field access E/E/–/– | Submitted by: exhibitor-application.html, partner-sponsor-application.html Conversion destinations: Opportunity.NTE_Trading_Name__c |
| Volunteer_Applicant_Email_Status__c<br>Volunteer Applicant Email Status<br>Picklist; required=false; trackFeedHistory=false; values PL12, restricted=true<br>Field access –/–/E/– | Volunteer applicant acknowledgement result, independent of the owner notification. |
| Volunteer_Armed_Forces_Service__c<br>Armed Forces Service<br>Picklist; required=false; trackFeedHistory=false; values PL05, restricted=true<br>Field access –/–/E/– | Submitted by: volunteer-application.html |
| Volunteer_Availability__c<br>Volunteer Availability Preference<br>MultiselectPicklist; required=false; trackFeedHistory=false; visibleLines=3; values PL24, restricted=true<br>Field access –/–/E/– | Submitted by: volunteer-application.html |
| Volunteer_Code_Consent__c<br>Code of Conduct Acknowledged<br>Checkbox; required=false; defaultValue=false; trackFeedHistory=false<br>Field access –/–/E/– | Submitted by: volunteer-application.html |
| Volunteer_Code_Version__c<br>Code of Conduct Version<br>Text(80); required=false; trackFeedHistory=false<br>Field access –/–/E/– | Submitted by: volunteer-application.html |
| Volunteer_Consent__c<br>Volunteer Consent<br>Picklist; required=false; trackFeedHistory=false; values PL05, restricted=true<br>Field access –/–/E/– | Submitted by: volunteer-application.html |
| Volunteer_DBS_Willing__c<br>Willing to Complete DBS Check<br>Picklist; required=false; trackFeedHistory=false; values PL05, restricted=true<br>Field access –/–/E/– | Submitted by: volunteer-application.html |
| Volunteer_Email_Error__c<br>Volunteer Email Error<br>LongTextArea(32768); required=false; trackFeedHistory=false; visibleLines=4<br>Field access –/–/E/– | Per-Lead volunteer delivery errors; accepted sides survive retry of the other side. |
| Volunteer_Form_Version__c<br>Volunteer Form Version<br>Text(80); required=false; trackFeedHistory=false<br>Field access –/–/E/– | Submitted by: volunteer-application.html |
| Volunteer_Hours__c<br>Hours Willing to Give per Month<br>Picklist; required=false; trackFeedHistory=false; values PL25, restricted=true<br>Field access –/–/E/– | Submitted by: volunteer-application.html |
| Volunteer_Internal_Email_Status__c<br>Volunteer Internal Email Status<br>Picklist; required=false; trackFeedHistory=false; values PL12, restricted=true<br>Field access –/–/E/– | Volunteer current-owner notification result; it does not use the NTE routing username. |
| Volunteer_Opportunities__c<br>Volunteering Opportunities<br>MultiselectPicklist; required=false; trackFeedHistory=false; visibleLines=6; values PL26, restricted=true<br>Field access –/–/E/– | Submitted by: volunteer-application.html |
| Volunteer_Service_Dates__c<br>Dates in Service<br>Text(255); required=false; trackFeedHistory=false<br>Field access –/–/E/– | Submitted by: volunteer-application.html |
| Volunteer_Service_Details__c<br>Service, Unit, Station or Ship<br>LongTextArea(1000); required=false; trackFeedHistory=false; visibleLines=4<br>Field access –/–/E/– | Submitted by: volunteer-application.html |
| Volunteer_Skills__c<br>Volunteer Skills and Experience<br>MultiselectPicklist; required=false; trackFeedHistory=false; visibleLines=6; values PL26, restricted=true<br>Field access –/–/E/– | Submitted by: volunteer-application.html |
| Volunteer_Travel_Regions__c<br>Volunteer Travel Regions<br>MultiselectPicklist; required=false; trackFeedHistory=false; visibleLines=6; values PL27, restricted=true<br>Field access –/–/E/– | Submitted by: volunteer-application.html |
| Web_Form_Type__c<br>Web Form Type<br>Picklist; required=false; trackFeedHistory=false; values PL28, restricted=true<br>Field access E/E/E/– | Identifies the public form that created the Lead. Stable across NTE editions. Submitted by: exhibitor-application.html, exhibitor-interest.html, exhibitor-staff-update.html, guest-registration.html, heavy-vehicle-details.html, logo-upload.html, partner-sponsor-application.html, partner-sponsor-interest.html, partner-sponsor-staff-update.html, volunteer-application.html Conversion destinations: Opportunity.NTE_Source_Form_Type__c, Account.NTE_Source_Form_Type__c, Contact.NTE_Source_Form_Type__c |



### NTE Intake Event Code

Source: force-app/main/default/objects/Lead/validationRules/NTE_Intake_Event_Code.validationRule-meta.xml.

fullName: NTE_Intake_Event_Code.

active: true.

description: New or changed NTE interest, application and guest event codes must identify a four-digit edition. Unrelated edits to historical records are preserved.

Validation formula:

```text
AND(OR(ISNEW(), ISCHANGED(NTE_Event_Code__c), ISCHANGED(Web_Form_Type__c)), OR(ISPICKVAL(Web_Form_Type__c, "Partner / Sponsor Expression of Interest"), ISPICKVAL(Web_Form_Type__c, "Exhibitor Expression of Interest"), ISPICKVAL(Web_Form_Type__c, "Partner / Sponsor Application"), ISPICKVAL(Web_Form_Type__c, "Exhibitor Application"), ISPICKVAL(Web_Form_Type__c, "Guest Registration")), NOT(REGEX(NTE_Event_Code__c, "^NTE[0-9]{4}$")))
```

errorDisplayField: NTE_Event_Code__c.

errorMessage: Enter an event code in the format NTE2027.

### NTE Interest Decision Exclusive

Source: force-app/main/default/objects/Lead/validationRules/NTE_Interest_Decision_Exclusive.validationRule-meta.xml.

fullName: NTE_Interest_Decision_Exclusive.

active: true.

description: An expression of interest cannot be both progressed and not progressed.

Validation formula:

```text
AND(NTE_Interest_Progressed__c, NTE_Interest_Not_Progressed__c)
```

errorMessage: Choose either Progressed or Not Progressed, not both.

### Volunteer Code Required

Source: force-app/main/default/objects/Lead/validationRules/Volunteer_Code_Required.validationRule-meta.xml.

fullName: Volunteer_Code_Required.

active: true.

description: New v3 volunteer applications must acknowledge the supplied September 2026 Code of Conduct. Historical applications are unchanged.

Validation formula:

```text
AND(ISNEW(), ISPICKVAL(Web_Form_Type__c, "Volunteer Application"), Volunteer_Form_Version__c = "volunteer-application-v3", OR(NOT(Volunteer_Code_Consent__c), Volunteer_Code_Version__c <> "September 2026"))
```

errorDisplayField: Volunteer_Code_Consent__c.

errorMessage: Please read and acknowledge the September 2026 Code of Conduct.

## Opportunity

API name: Opportunity. 137 packaged fields. One NTE event booking and its durable application snapshot. Initial commercial fields are copied by the conversion flow; subsequent preparation fields are changed by the supplementary service. Invoice/payment flags are independent for the base booking and later exhibitor staff top-up. Timestamps and By text record the action evidence. Approval and final-pack states describe email outcomes, not booking completion or actual payment processing.


| Field and exact definition | Meaning and data lineage |
| --- | --- |
| Booking_Reference__c<br>NTE Booking Reference<br>Text(80); required=false; unique=true; externalId=true; caseSensitive=false; trackFeedHistory=false<br>Field access E/E/–/– | Unique browser-generated reference for the original NTE application. Conversion source: $Record.Booking_Reference__c |
| NTE_Additional_Staff_Count__c<br>NTE Additional Staff Count<br>Text(40); required=false; trackFeedHistory=false<br>Field access E/E/–/– | Conversion source: Priced_Application.Additional_Staff_Count__c |
| NTE_Additional_Staff_Required__c<br>NTE Additional Staff Required<br>Text(40); required=false; trackFeedHistory=false<br>Field access E/E/–/– | Conversion source: Priced_Application.Additional_Staff_Required__c |
| NTE_Additional_Staff_Total__c<br>NTE Additional Staff Total (ex VAT)<br>Currency(18,2); required=false; trackFeedHistory=false<br>Field access E/E/–/– | Conversion source: Priced_Application.Additional_Staff_Total__c |
| NTE_Additional_Staff_Unit_Price__c<br>NTE Additional Staff Unit Price (ex VAT)<br>Currency(18,2); required=false; trackFeedHistory=false<br>Field access E/E/–/– | Conversion source: Priced_Application.Additional_Staff_Unit_Price__c |
| NTE_Alternative_Organisation_Name__c<br>NTE Alternative Organisation Name<br>Text(255); required=false; trackFeedHistory=false<br>Field access E/E/–/– | Conversion source: $Record.Alternative_Organisation_Name__c |
| NTE_Approval_Email_Batch__c<br>NTE Provisional Email Batch<br>Text(64); required=false<br>Field access E/E/–/– | Random saved batch identity joining an exact set of pending conversion email requests and their queue/finalizer continuation. |
| NTE_Approval_Email_Error__c<br>NTE Provisional Email Error<br>LongTextArea(32768); required=false; visibleLines=4<br>Field access E/E/–/– | Last approval/provisional failure reason; correct that cause before using the booking retry action. |
| NTE_Approval_Email_Lead_Id__c<br>NTE Provisional Email Lead ID<br>Text(18); required=false<br>Field access E/E/–/– | Text identity of the exact converted source Lead. The approval service verifies the Lead-to-Opportunity association; this field is not a lookup relationship. |
| NTE_Approval_Email_Recipient__c<br>NTE Provisional Email Recipient<br>Email; required=false<br>Field access E/E/–/– | Primary Contact address recorded for accepted provisional/complimentary delivery. |
| NTE_Approval_Email_Requested_At__c<br>NTE Provisional Email Requested At<br>DateTime; required=false<br>Field access E/E/–/– | Time the conversion/retry saved a pending approval request, before background delivery. |
| NTE_Approval_Email_Requested_By__c<br>NTE Provisional Email Requested By<br>Text(255); required=false<br>Field access E/E/–/– | Requesting user identity captured with the pending approval request. |
| NTE_Approval_Email_Sent_At__c<br>NTE Provisional Email Sent At<br>DateTime; required=false<br>Field access E/E/–/– | Salesforce acceptance timestamp of the provisional/complimentary message. |
| NTE_Approval_Email_Status__c<br>NTE Provisional Email Status<br>Text(40); required=false<br>Field access E/E/–/– | Pending, Sent or Failed approval email state; separate from paid confirmation dispatch and native Opportunity stage. |
| NTE_Attendance_Status__c<br>NTE Attendance Status<br>Picklist; required=false; trackFeedHistory=false; values PL29, restricted=true<br>Field access E/E/–/– | Manual attendance classification retained on the booking. It is not the Master Panel calculated Completed flag or a payment milestone. |
| NTE_Confirmed_Value__c<br>NTE Confirmed Value (inc VAT)<br>Currency(18,2); required=false; trackHistory=false; formula below; blanks=BlankAsBlank<br>Field access R/R/–/– | Booking value including VAT and separately rounded staff top-ups. Bookings needing a pricing check are excluded. |
| NTE_Declaration_Date__c<br>NTE Declaration Date<br>Date; required=false; trackFeedHistory=false<br>Field access E/E/–/– | Conversion source: $Record.Declaration_Date__c |
| NTE_Declaration_Name__c<br>NTE Declaration Name<br>Text(200); required=false; trackFeedHistory=false<br>Field access E/E/–/– | Conversion source: $Record.Declaration_Name__c |
| NTE_Delivery_Window__c<br>NTE Delivery Window<br>Text(255); required=false; trackFeedHistory=false<br>Field access E/E/–/– | Delivery timing copied from Lead.Delivery_Window__c by an accepted Heavy Vehicle Details submission; later valid logistics submissions replace it. |
| NTE_Event_Code__c<br>NTE Event Code<br>Text(20); required=false; unique=false; externalId=true; trackFeedHistory=false<br>Field access E/E/–/– | Conversion source: $Record.NTE_Event_Code__c |
| NTE_Event_Contact_Email__c<br>NTE Event Contact Email<br>Email; required=false; trackFeedHistory=false<br>Field access E/E/–/– | Descriptive event-day or secondary contact detail from the application/logistics submission. It is not an email-recipient fallback for a missing Primary Contact. Conversion source: $Record.Event_Contact_Email__c |
| NTE_Event_Contact_Mobile__c<br>NTE Event Contact Mobile<br>Phone; required=false; trackFeedHistory=false<br>Field access E/E/–/– | Descriptive event-day or secondary contact detail from the application/logistics submission. It is not an email-recipient fallback for a missing Primary Contact. Conversion source: $Record.Event_Contact_Mobile__c |
| NTE_Event_Contact_Name__c<br>NTE Event Contact Name<br>Text(200); required=false; trackFeedHistory=false<br>Field access E/E/–/– | Descriptive event-day or secondary contact detail from the application/logistics submission. It is not an email-recipient fallback for a missing Primary Contact. Conversion source: $Record.Event_Contact_Name__c |
| NTE_Event_Contact_Title__c<br>NTE Event Contact Job Title<br>Text(128); required=false; trackFeedHistory=false<br>Field access E/E/–/– | Descriptive event-day or secondary contact detail from the application/logistics submission. It is not an email-recipient fallback for a missing Primary Contact. Conversion source: $Record.Event_Contact_Title__c |
| NTE_Event_Discovery_Source__c<br>NTE Event Discovery Source<br>Text(255); required=false; trackFeedHistory=false<br>Field access E/E/–/– | Conversion source: $Record.Event_Discovery_Source__c |
| NTE_Exhibitor_Hall_Schedule__c<br>NTE Sunday Setup Availability<br>Text(40); required=false; trackFeedHistory=false<br>Field access E/E/–/– | Conversion source: $Record.Exhibitor_Hall_Schedule__c |
| NTE_Exhibitor_Organisation_Category__c<br>NTE Exhibitor Organisation Category<br>Text(255); required=false; trackFeedHistory=false<br>Field access E/E/–/– | Conversion source: $Record.Exhibitor_Organisation_Category__c |
| NTE_Exhibitor_Space_Position__c<br>NTE Exhibitor Space Position<br>Text(255); required=false; trackFeedHistory=false<br>Field access E/E/–/– | Conversion source: $Record.Exhibitor_Space_Position__c |
| NTE_Exhibitor_Space_Price__c<br>NTE Exhibitor Space Price (ex VAT)<br>Currency(18,2); required=false; trackFeedHistory=false<br>Field access E/E/–/– | Conversion source: Priced_Application.Exhibitor_Space_Price__c |
| NTE_Exhibitor_Space_Selections__c<br>NTE Exhibitor Space Selection<br>LongTextArea(32768); required=false; trackFeedHistory=false; visibleLines=3<br>Field access E/E/–/– | Conversion source: $Record.Exhibitor_Space_Selections__c |
| NTE_Exhibitor_Space_Size__c<br>NTE Exhibitor Space Size<br>Text(255); required=false; trackFeedHistory=false<br>Field access E/E/–/– | Conversion source: $Record.Exhibitor_Space_Size__c |
| NTE_Final_Pack_Recipient__c<br>NTE Final Pack Recipient<br>Email; required=false<br>Field access E/E/–/– | Address recorded for the accepted final event information email. |
| NTE_Final_Pack_Sent_At__c<br>NTE Final Pack Sent At<br>DateTime; required=false<br>Field access E/E/–/– | Acceptance timestamp of the final pack, retained when later top-up work reopens booking readiness. |
| NTE_Final_Pack_Status__c<br>NTE Final Pack Status<br>Text(20); required=false<br>Field access E/E/–/– | Final-pack dispatch state. Completed bookings do not automatically set Sent; later preparation/finance changes preserve prior pack history. |
| NTE_Finance_Invoice_Due__c<br>NTE Finance Invoice Required<br>Checkbox; required=false; trackHistory=false; formula below; blanks=BlankAsBlank<br>Field access R/R/–/– | Booking or staff top-up invoice work, including unresolved pricing. |
| NTE_Finance_Payment_Confirmed__c<br>NTE Payment Confirmed<br>Checkbox; required=false; trackHistory=false; formula below; blanks=BlankAsBlank<br>Field access R/R/–/– | Every applicable booking and staff top-up invoice and payment is complete. Fully complimentary bookings are excluded. |
| NTE_Finance_Payment_Due__c<br>NTE Payment Required<br>Checkbox; required=false; trackHistory=false; formula below; blanks=BlankAsBlank<br>Field access R/R/–/– | An unpaid charge has its own invoice provided, following the booking-first payment order. |
| NTE_Form_Version__c<br>NTE Form Version<br>Text(80); required=false; trackFeedHistory=false<br>Field access E/E/–/– | Conversion source: $Record.Form_Version__c |
| NTE_Has_Special_Requirements__c<br>NTE Has Special Requirements<br>Text(40); required=false; trackFeedHistory=false<br>Field access E/E/–/– | Conversion source: $Record.Has_Special_Requirements__c |
| NTE_Haulier_Name__c<br>NTE Haulier Name<br>Text(255); required=false; trackFeedHistory=false<br>Field access E/E/–/– | Saved logistics replacement supplied by a valid Heavy Vehicle Details submission. Optional item groups must be complete if started; omitted optional groups clear their prior values. |
| NTE_Haulier_Staff__c<br>NTE Haulier Staff<br>LongTextArea(32768); required=false; trackFeedHistory=false; visibleLines=4<br>Field access E/E/–/– | Saved logistics replacement supplied by a valid Heavy Vehicle Details submission. Optional item groups must be complete if started; omitted optional groups clear their prior values. |
| NTE_Haulier_Vehicle_Dimensions__c<br>NTE Haulier Vehicle Dimensions<br>Text(120); required=false; trackFeedHistory=false<br>Field access E/E/–/– | Saved logistics replacement supplied by a valid Heavy Vehicle Details submission. Optional item groups must be complete if started; omitted optional groups clear their prior values. |
| NTE_Haulier_Vehicle_Gross_Weight__c<br>NTE Haulier Vehicle Gross Weight<br>Text(120); required=false; trackFeedHistory=false<br>Field access E/E/–/– | Saved logistics replacement supplied by a valid Heavy Vehicle Details submission. Optional item groups must be complete if started; omitted optional groups clear their prior values. |
| NTE_Haulier_Vehicle_Registration__c<br>NTE Haulier Vehicle Registration<br>Text(80); required=false; trackFeedHistory=false<br>Field access E/E/–/– | Saved logistics replacement supplied by a valid Heavy Vehicle Details submission. Optional item groups must be complete if started; omitted optional groups clear their prior values. |
| NTE_Haulier_Vehicle_Type__c<br>NTE Haulier Vehicle Type<br>Text(255); required=false; trackFeedHistory=false<br>Field access E/E/–/– | Saved logistics replacement supplied by a valid Heavy Vehicle Details submission. Optional item groups must be complete if started; omitted optional groups clear their prior values. |
| NTE_Heavy_Item_1_Description__c<br>NTE Heavy Item 1 Description<br>Text(255); required=false; trackFeedHistory=false<br>Field access E/E/–/– | Saved logistics replacement supplied by a valid Heavy Vehicle Details submission. Optional item groups must be complete if started; omitted optional groups clear their prior values. |
| NTE_Heavy_Item_1_Dimensions__c<br>NTE Heavy Item 1 Dimensions<br>Text(120); required=false; trackFeedHistory=false<br>Field access E/E/–/– | Saved logistics replacement supplied by a valid Heavy Vehicle Details submission. Optional item groups must be complete if started; omitted optional groups clear their prior values. |
| NTE_Heavy_Item_1_Gross_Weight__c<br>NTE Heavy Item 1 Gross Weight<br>Text(120); required=false; trackFeedHistory=false<br>Field access E/E/–/– | Saved logistics replacement supplied by a valid Heavy Vehicle Details submission. Optional item groups must be complete if started; omitted optional groups clear their prior values. |
| NTE_Heavy_Item_1_Registration__c<br>NTE Heavy Item 1 Registration<br>Text(80); required=false; trackFeedHistory=false<br>Field access E/E/–/– | Saved logistics replacement supplied by a valid Heavy Vehicle Details submission. Optional item groups must be complete if started; omitted optional groups clear their prior values. |
| NTE_Heavy_Item_2_Description__c<br>NTE Heavy Item 2 Description<br>Text(255); required=false; trackFeedHistory=false<br>Field access E/E/–/– | Saved logistics replacement supplied by a valid Heavy Vehicle Details submission. Optional item groups must be complete if started; omitted optional groups clear their prior values. |
| NTE_Heavy_Item_2_Dimensions__c<br>NTE Heavy Item 2 Dimensions<br>Text(120); required=false; trackFeedHistory=false<br>Field access E/E/–/– | Saved logistics replacement supplied by a valid Heavy Vehicle Details submission. Optional item groups must be complete if started; omitted optional groups clear their prior values. |
| NTE_Heavy_Item_2_Gross_Weight__c<br>NTE Heavy Item 2 Gross Weight<br>Text(120); required=false; trackFeedHistory=false<br>Field access E/E/–/– | Saved logistics replacement supplied by a valid Heavy Vehicle Details submission. Optional item groups must be complete if started; omitted optional groups clear their prior values. |
| NTE_Heavy_Item_2_Registration__c<br>NTE Heavy Item 2 Registration<br>Text(80); required=false; trackFeedHistory=false<br>Field access E/E/–/– | Saved logistics replacement supplied by a valid Heavy Vehicle Details submission. Optional item groups must be complete if started; omitted optional groups clear their prior values. |
| NTE_Heavy_Item_3_Description__c<br>NTE Heavy Item 3 Description<br>Text(255); required=false; trackFeedHistory=false<br>Field access E/E/–/– | Saved logistics replacement supplied by a valid Heavy Vehicle Details submission. Optional item groups must be complete if started; omitted optional groups clear their prior values. |
| NTE_Heavy_Item_3_Dimensions__c<br>NTE Heavy Item 3 Dimensions<br>Text(120); required=false; trackFeedHistory=false<br>Field access E/E/–/– | Saved logistics replacement supplied by a valid Heavy Vehicle Details submission. Optional item groups must be complete if started; omitted optional groups clear their prior values. |
| NTE_Heavy_Item_3_Gross_Weight__c<br>NTE Heavy Item 3 Gross Weight<br>Text(120); required=false; trackFeedHistory=false<br>Field access E/E/–/– | Saved logistics replacement supplied by a valid Heavy Vehicle Details submission. Optional item groups must be complete if started; omitted optional groups clear their prior values. |
| NTE_Heavy_Item_3_Registration__c<br>NTE Heavy Item 3 Registration<br>Text(80); required=false; trackFeedHistory=false<br>Field access E/E/–/– | Saved logistics replacement supplied by a valid Heavy Vehicle Details submission. Optional item groups must be complete if started; omitted optional groups clear their prior values. |
| NTE_Heavy_Vehicle_Required__c<br>NTE Heavy Vehicle Required<br>Text(40); required=false; trackFeedHistory=false<br>Field access E/E/–/– | Conversion source: $Record.Heavy_Vehicle_Required__c |
| NTE_Heavy_Vehicle_Update_Completed_At__c<br>NTE Heavy Vehicle Update Completed At<br>DateTime; required=false; trackFeedHistory=false<br>Field access E/E/–/– | Set automatically after a Heavy Vehicle Details submission has been applied successfully. |
| NTE_Included_Staff_Count__c<br>NTE Included Staff Count<br>Number(2,0); required=false; trackFeedHistory=false<br>Field access E/E/–/– | Catalogue allowance, two or four for the current exhibitor space. It is part of the initial count, not an additional allocation. Conversion source: Priced_Application.Included_Staff_Count__c |
| NTE_Industry_Body_Details__c<br>NTE Industry Body Details<br>Text(255); required=false; trackFeedHistory=false<br>Field access E/E/–/– | Conversion source: $Record.Industry_Body_Details__c |
| NTE_Initial_Staff_Count__c<br>NTE Initial Staff Count<br>Number(2,0); required=false; trackFeedHistory=false<br>Field access E/E/–/– | Immutable initial purchased allocation copied from the conversion pricing result, including included and initially charged places. Conversion source: Priced_Application.Total_Staff_Count__c |
| NTE_Invoice_Additional_Information__c<br>NTE Invoice Additional Information<br>LongTextArea(32768); required=false; trackFeedHistory=false; visibleLines=4<br>Field access E/E/–/– | Saved billing/procurement detail for the manual finance process and reports. Collecting it does not create a Salesforce or Stripe invoice. Conversion source: $Record.Invoice_Additional_Information__c |
| NTE_Invoice_Address__c<br>NTE Invoice Address<br>LongTextArea(32768); required=false; trackFeedHistory=false; visibleLines=4<br>Field access E/E/–/– | Saved billing/procurement detail for the manual finance process and reports. Collecting it does not create a Salesforce or Stripe invoice. Conversion source: $Record.Invoice_Address__c |
| NTE_Invoice_Contact_Phone__c<br>NTE Invoice Contact Phone<br>Phone; required=false; trackFeedHistory=false<br>Field access E/E/–/– | Saved billing/procurement detail for the manual finance process and reports. Collecting it does not create a Salesforce or Stripe invoice. Conversion source: $Record.Invoice_Contact_Phone__c |
| NTE_Invoice_Provided_At__c<br>NTE Invoice / Stripe Link Provided At<br>DateTime; required=false; trackFeedHistory=false<br>Field access E/E/–/– | Initial booking milestone evidence stamped by the validated finance action; names/times are preserved on rejected repeated actions. |
| NTE_Invoice_Provided_By__c<br>NTE Invoice / Stripe Link Provided By<br>Text(120); required=false; trackFeedHistory=false<br>Field access E/E/–/– | Initial booking milestone evidence stamped by the validated finance action; names/times are preserved on rejected repeated actions. |
| NTE_Invoice_Provided__c<br>NTE Invoice / Stripe Link Provided<br>Checkbox; required=false; defaultValue=false; trackFeedHistory=false<br>Field access E/E/–/– | Initial booking milestone evidence stamped by the validated finance action; names/times are preserved on rejected repeated actions. Selected from the NTE Master Panel after the invoice or Stripe payment link has been sent. |
| NTE_Invoice_Required__c<br>NTE Invoice Required<br>Text(40); required=false; trackFeedHistory=false<br>Field access E/E/–/– | Conversion source: Priced_Application.Invoice_Required__c |
| NTE_Invoiced_Company__c<br>NTE Invoiced Company<br>Text(255); required=false; trackFeedHistory=false<br>Field access E/E/–/– | Saved billing/procurement detail for the manual finance process and reports. Collecting it does not create a Salesforce or Stripe invoice. Conversion source: $Record.Invoiced_Company__c |
| NTE_Invoiced_Email__c<br>NTE Invoiced Email<br>Email; required=false; trackFeedHistory=false<br>Field access E/E/–/– | Saved billing/procurement detail for the manual finance process and reports. Collecting it does not create a Salesforce or Stripe invoice. Conversion source: $Record.Invoiced_Email__c |
| NTE_Invoiced_Person__c<br>NTE Invoiced Person<br>Text(255); required=false; trackFeedHistory=false<br>Field access E/E/–/– | Saved billing/procurement detail for the manual finance process and reports. Collecting it does not create a Salesforce or Stripe invoice. Conversion source: $Record.Invoiced_Person__c |
| NTE_Last_Update_Declaration_Date__c<br>NTE Last Update Declaration Date<br>Date; required=false; trackFeedHistory=false<br>Field access E/E/–/– | Audit of the last accepted supplementary update: its form/type, declaration, processing time or error. Distinct from the original application declaration and separate receipt outcome. |
| NTE_Last_Update_Declaration_Name__c<br>NTE Last Update Declaration Name<br>Text(200); required=false; trackFeedHistory=false<br>Field access E/E/–/– | Audit of the last accepted supplementary update: its form/type, declaration, processing time or error. Distinct from the original application declaration and separate receipt outcome. |
| NTE_Last_Update_Error__c<br>NTE Last Update Error<br>LongTextArea(32768); required=false; trackFeedHistory=false; visibleLines=3<br>Field access E/E/–/– | Audit of the last accepted supplementary update: its form/type, declaration, processing time or error. Distinct from the original application declaration and separate receipt outcome. |
| NTE_Last_Update_Form_Version__c<br>NTE Last Update Form Version<br>Text(80); required=false; trackFeedHistory=false<br>Field access E/E/–/– | Audit of the last accepted supplementary update: its form/type, declaration, processing time or error. Distinct from the original application declaration and separate receipt outcome. |
| NTE_Last_Update_Processed_At__c<br>NTE Last Update Processed At<br>DateTime; required=false; trackFeedHistory=false<br>Field access E/E/–/– | Audit of the last accepted supplementary update: its form/type, declaration, processing time or error. Distinct from the original application declaration and separate receipt outcome. |
| NTE_Last_Update_Type__c<br>NTE Last Update Type<br>Text(100); required=false; trackFeedHistory=false<br>Field access E/E/–/– | Audit of the last accepted supplementary update: its form/type, declaration, processing time or error. Distinct from the original application declaration and separate receipt outcome. |
| NTE_Listed_Price_Total__c<br>NTE Booking Total (ex VAT)<br>Currency(18,2); required=false; trackFeedHistory=false<br>Field access E/E/–/– | Conversion source: Priced_Application.Listed_Price_Total__c |
| NTE_Logo_Update_Provided_At__c<br>NTE Logo Update Provided At<br>DateTime; required=false; trackFeedHistory=false<br>Field access E/E/–/– | The date and time the first matched Logo Update submission was received. |
| NTE_Logo_Update_Provided__c<br>NTE Logo Update Provided<br>Checkbox; required=false; defaultValue=false; trackFeedHistory=false<br>Field access E/E/–/– | Selected automatically after a Logo Update submission has been matched to this NTE booking. |
| NTE_Payment_Method__c<br>NTE Payment Method<br>Picklist; required=false; trackFeedHistory=false; values PL17, restricted=true<br>Field access E/E/–/– | Conversion source: $Record.Payment_Method__c |
| NTE_Payment_Received_At__c<br>NTE Payment Received At<br>DateTime; required=false; trackFeedHistory=false<br>Field access E/E/–/– | Initial booking milestone evidence stamped by the validated finance action; names/times are preserved on rejected repeated actions. |
| NTE_Payment_Received__c<br>NTE Payment Received<br>Checkbox; required=false; defaultValue=false; trackFeedHistory=false<br>Field access E/E/–/– | Initial booking milestone evidence stamped by the validated finance action; names/times are preserved on rejected repeated actions. Selected from the NTE Master Panel after payment has been confirmed. |
| NTE_Payment_Recorded_By__c<br>NTE Payment Recorded By<br>Text(120); required=false; trackFeedHistory=false<br>Field access E/E/–/– | Initial booking milestone evidence stamped by the validated finance action; names/times are preserved on rejected repeated actions. |
| NTE_Planned_Exhibitor_Count__c<br>NTE Planned Exhibitor Count<br>Text(40); required=false; trackFeedHistory=false<br>Field access E/E/–/– | Conversion source: $Record.Planned_Exhibitor_Count__c |
| NTE_Power_Socket_Count__c<br>NTE Power Socket Count<br>Number(2,0); required=false; trackFeedHistory=false<br>Field access E/E/–/– | Conversion source: $Record.Power_Socket_Count__c |
| NTE_Power_Socket_Total__c<br>NTE Power Socket Total (ex VAT)<br>Currency(18,2); required=false; trackFeedHistory=false<br>Field access E/E/–/– | Conversion source: Priced_Application.Power_Socket_Total__c |
| NTE_Power_Socket_Unit_Price__c<br>NTE Power Socket Unit Price (ex VAT)<br>Currency(18,2); required=false; trackFeedHistory=false<br>Field access E/E/–/– | Conversion source: Priced_Application.Power_Socket_Unit_Price__c |
| NTE_Previous_Events__c<br>Previous NTE Events<br>Text(255); required=false; trackFeedHistory=false<br>Field access E/E/–/– | Conversion source: $Record.Previous_NTE_Events__c |
| NTE_Pricing_Ready__c<br>NTE Pricing Ready<br>Checkbox; required=false; trackHistory=false; formula below; blanks=BlankAsBlank<br>Field access R/R/–/– | Whether the saved booking price can be used for finance and readiness. |
| NTE_Pricing_Status__c<br>NTE Pricing Status<br>Picklist; required=false; trackFeedHistory=false; values PL21, restricted=true<br>Field access E/E/–/– | Conversion source: Priced_Application.Pricing_Status__c |
| NTE_Pricing_Version__c<br>NTE Pricing Version<br>Text(80); required=false; trackFeedHistory=false<br>Field access E/E/–/– | Conversion source: Priced_Application.Pricing_Version__c |
| NTE_Purchase_Order_Number__c<br>NTE Purchase Order Number<br>Text(120); required=false; trackFeedHistory=false<br>Field access E/E/–/– | Saved billing/procurement detail for the manual finance process and reports. Collecting it does not create a Salesforce or Stripe invoice. Conversion source: $Record.Purchase_Order_Number__c |
| NTE_Purchase_Order__c<br>NTE Purchase Order Required<br>Text(40); required=false; trackFeedHistory=false<br>Field access E/E/–/– | Saved billing/procurement detail for the manual finance process and reports. Collecting it does not create a Salesforce or Stripe invoice. Conversion source: $Record.Purchase_Order__c |
| NTE_Quote_Provided_At__c<br>NTE Quote Provided At<br>DateTime; required=false; trackFeedHistory=false<br>Field access E/E/–/– | Initial booking milestone evidence stamped by the validated finance action; names/times are preserved on rejected repeated actions. |
| NTE_Quote_Provided_By__c<br>NTE Quote Provided By<br>Text(120); required=false; trackFeedHistory=false<br>Field access E/E/–/– | Initial booking milestone evidence stamped by the validated finance action; names/times are preserved on rejected repeated actions. |
| NTE_Quote_Provided__c<br>NTE Quote Provided<br>Checkbox; required=false; defaultValue=false; trackFeedHistory=false<br>Field access E/E/–/– | Initial booking milestone evidence stamped by the validated finance action; names/times are preserved on rejected repeated actions. Selected from the NTE Master Panel after the quote has been sent. |
| NTE_Quote_Required_for_PO__c<br>NTE Quotation Required for PO<br>Text(40); required=false; trackFeedHistory=false<br>Field access E/E/–/– | Conversion source: $Record.Quote_Required_for_PO__c |
| NTE_Secondary_Contact_Email__c<br>NTE Secondary Contact Email<br>Email; required=false; trackFeedHistory=false<br>Field access E/E/–/– | Descriptive event-day or secondary contact detail from the application/logistics submission. It is not an email-recipient fallback for a missing Primary Contact. Conversion source: $Record.Secondary_Contact_Email__c |
| NTE_Secondary_Contact_Mobile__c<br>NTE Secondary Contact Mobile<br>Phone; required=false; trackFeedHistory=false<br>Field access E/E/–/– | Descriptive event-day or secondary contact detail from the application/logistics submission. It is not an email-recipient fallback for a missing Primary Contact. Conversion source: $Record.Secondary_Contact_Mobile__c |
| NTE_Secondary_Contact_Name__c<br>NTE Secondary Contact Name<br>Text(200); required=false; trackFeedHistory=false<br>Field access E/E/–/– | Descriptive event-day or secondary contact detail from the application/logistics submission. It is not an email-recipient fallback for a missing Primary Contact. Conversion source: $Record.Secondary_Contact_Name__c |
| NTE_Secondary_Contact_Phone__c<br>NTE Secondary Contact Work Phone<br>Phone; required=false; trackFeedHistory=false<br>Field access E/E/–/– | Descriptive event-day or secondary contact detail from the application/logistics submission. It is not an email-recipient fallback for a missing Primary Contact. Conversion source: $Record.Secondary_Contact_Phone__c |
| NTE_Secondary_Contact_Prefix__c<br>NTE Secondary Contact Prefix<br>Text(40); required=false; trackFeedHistory=false<br>Field access E/E/–/– | Descriptive event-day or secondary contact detail from the application/logistics submission. It is not an email-recipient fallback for a missing Primary Contact. Conversion source: $Record.Secondary_Contact_Prefix__c |
| NTE_Secondary_Contact_Title__c<br>NTE Secondary Contact Job Title<br>Text(128); required=false; trackFeedHistory=false<br>Field access E/E/–/– | Descriptive event-day or secondary contact detail from the application/logistics submission. It is not an email-recipient fallback for a missing Primary Contact. Conversion source: $Record.Secondary_Contact_Title__c |
| NTE_Source_Form_Type__c<br>NTE Source Form Type<br>Text(100); required=false; trackFeedHistory=false<br>Field access E/E/–/– | Conversion source: $Record.Web_Form_Type__c |
| NTE_Sponsor_Package_Total__c<br>NTE Sponsor Package Total (ex VAT)<br>Currency(18,2); required=false; trackFeedHistory=false<br>Field access E/E/–/– | Conversion source: Priced_Application.Sponsor_Package_Total__c |
| NTE_Sponsor_Package__c<br>NTE Sponsorship Package<br>MultiselectPicklist; required=false; trackFeedHistory=false; visibleLines=4; values PL22, restricted=true<br>Field access E/E/–/– | Conversion source: $Record.Sponsor_Package__c |
| NTE_Sponsored_Name__c<br>NTE Sponsored Name<br>Text(200); required=false; trackFeedHistory=false<br>Field access E/E/–/– | Conversion source: $Record.Sponsored_Name__c |
| NTE_Staff_Update_Completed_At__c<br>NTE Staff Update Completed At<br>DateTime; required=false; trackFeedHistory=false<br>Field access E/E/–/– | Set automatically after the applicable exhibitor or partner / sponsor staff update has been applied successfully. |
| NTE_Stand_Colleagues__c<br>NTE Stand Colleagues<br>LongTextArea(32768); required=false; trackFeedHistory=false; visibleLines=4<br>Field access E/E/–/– | Current consolidated roster, one nonblank person per line. Exhibitor initial and top-up names are joined; partner updates replace the free roster. Conversion source: $Record.Stand_Colleagues__c |
| NTE_Stand_Equipment__c<br>NTE Stand Equipment<br>LongTextArea(32768); required=false; trackFeedHistory=false; visibleLines=4<br>Field access E/E/–/– | Conversion source: $Record.Stand_Equipment__c |
| NTE_Stand_Extra_Notes__c<br>NTE Stand Extra Notes<br>LongTextArea(32768); required=false; trackFeedHistory=false; visibleLines=4<br>Field access E/E/–/– | Conversion source: $Record.Stand_Extra_Notes__c |
| NTE_Stand_Power__c<br>NTE Stand Power<br>Text(40); required=false; trackFeedHistory=false<br>Field access E/E/–/– | Conversion source: $Record.Stand_Power__c |
| NTE_Stand_Special_Requirements__c<br>NTE Stand Special Requirements<br>LongTextArea(32768); required=false; trackFeedHistory=false; visibleLines=4<br>Field access E/E/–/– | Conversion source: $Record.Stand_Special_Requirements__c |
| NTE_Supplier_Agreement_Required__c<br>NTE Supplier Agreement Required<br>Text(40); required=false; trackFeedHistory=false<br>Field access E/E/–/– | Saved billing/procurement detail for the manual finance process and reports. Collecting it does not create a Salesforce or Stripe invoice. Conversion source: $Record.Supplier_Agreement_Required__c |
| NTE_Terms_Accepted__c<br>NTE Terms Accepted<br>Checkbox; required=false; defaultValue=false; trackFeedHistory=false<br>Field access E/E/–/– | Conversion source: $Record.Terms_and_Conditions__c |
| NTE_Top_Up_Invoice_At__c<br>NTE Top-up Invoice Provided At<br>DateTime; required=false; trackFeedHistory=false<br>Field access E/E/–/– | Timestamp or actor for the separate staff top-up milestone. Initial booking finance stamps are preserved. |
| NTE_Top_Up_Invoice_By__c<br>NTE Top-up Invoice Provided By<br>Text(120); required=false; trackFeedHistory=false<br>Field access E/E/–/– | Timestamp or actor for the separate staff top-up milestone. Initial booking finance stamps are preserved. |
| NTE_Top_Up_Invoice_Provided__c<br>NTE Top-up Invoice Provided<br>Checkbox; required=false; defaultValue=false; trackFeedHistory=false<br>Field access E/E/–/– | The separate staff invoice was provided. Does not mean the original booking invoice was provided. |
| NTE_Top_Up_Invoice_Required__c<br>NTE Top-up Invoice Required<br>Checkbox; required=false; defaultValue=false; trackFeedHistory=false<br>Field access E/E/–/– | The separate staff charge requires an invoice/payment workflow; set on first valid positive top-up. |
| NTE_Top_Up_Payment_At__c<br>NTE Top-up Payment Received At<br>DateTime; required=false; trackFeedHistory=false<br>Field access E/E/–/– | Timestamp or actor for the separate staff top-up milestone. Initial booking finance stamps are preserved. |
| NTE_Top_Up_Payment_By__c<br>NTE Top-up Payment Received By<br>Text(120); required=false; trackFeedHistory=false<br>Field access E/E/–/– | Timestamp or actor for the separate staff top-up milestone. Initial booking finance stamps are preserved. |
| NTE_Top_Up_Payment_Received__c<br>NTE Top-up Payment Received<br>Checkbox; required=false; defaultValue=false; trackFeedHistory=false<br>Field access E/E/–/– | Manual receipt of the separate staff payment. Does not send another initial-booking confirmation. |
| NTE_Top_Up_Staff_Count__c<br>NTE Top-up Staff Count<br>Number(2,0); required=false; trackFeedHistory=false<br>Field access E/E/–/– | Quantity of the first valid accepted exhibitor top-up purchase. Public later corrections cannot increase or decrease it. |
| NTE_Top_Up_Staff_Names__c<br>NTE Top-up Staff Names<br>LongTextArea(32768); required=false; trackFeedHistory=false; visibleLines=6<br>Field access E/E/–/– | Names for the accepted top-up quantity. Names can be corrected without changing the quantity or its paid/invoice history. |
| NTE_Top_Up_Staff_Required__c<br>NTE Top-up Staff Required<br>Text(40); required=false; trackFeedHistory=false<br>Field access E/E/–/– | Saved top-up answer. A later No cannot erase an already accepted positive top-up purchase. |
| NTE_Top_Up_Staff_Total__c<br>NTE Top-up Staff Total (ex VAT)<br>Currency(18,2); required=false; trackFeedHistory=false<br>Field access E/E/–/– | Separate net top-up obligation. Its total including VAT is added to committed value; the top-up never overwrites Opportunity.Amount or base payment. |
| NTE_Top_Up_Staff_Unit_Price__c<br>NTE Top-up Staff Unit Price (ex VAT)<br>Currency(18,2); required=false; trackFeedHistory=false<br>Field access E/E/–/– | Saved net price per later staff place, currently GBP 50; not the initial additional-staff unit field. |
| NTE_Total_Staff_Count__c<br>NTE Total Staff Count<br>Number(3,0); required=false; trackFeedHistory=false<br>Field access E/E/–/– | Current roster total after accepted supplementary updates; includes any separately purchased exhibitor top-up. Conversion source: Priced_Application.Total_Staff_Count__c |
| NTE_Trading_Name__c<br>NTE Trading Name<br>Text(255); required=false; trackFeedHistory=false<br>Field access E/E/–/– | Saved billing/procurement detail for the manual finance process and reports. Collecting it does not create a Salesforce or Stripe invoice. Conversion source: $Record.Trading_Name__c |



### NTE Confirmed Value formula

API name: Opportunity.NTE_Confirmed_Value__c.

```text
IF(NOT(NTE_Pricing_Ready__c), NULL, IF(AND(NOT(ISBLANK(Amount)), Amount > 0), Amount, NTE_Total_Including_VAT__c) + NTE_Top_Up_Total_Inc_VAT__c)
```

### NTE Finance Invoice Due formula

API name: Opportunity.NTE_Finance_Invoice_Due__c.

```text
OR(NOT(NTE_Pricing_Ready__c), AND(OR(NTE_Quote_Required_for_PO__c <> "Yes", NTE_Quote_Provided__c), OR(AND(OR(NTE_Invoice_Required__c = "Yes", NTE_Listed_Price_Total__c > 0, NOT(NTE_Pricing_Ready__c)), NOT(NTE_Invoice_Provided__c)), AND(OR(NTE_Top_Up_Invoice_Required__c, BLANKVALUE(NTE_Top_Up_Staff_Total__c, 0) > 0), NOT(NTE_Top_Up_Invoice_Provided__c)))))
```

### NTE Finance Payment Confirmed formula

API name: Opportunity.NTE_Finance_Payment_Confirmed__c.

```text
AND(NTE_Pricing_Ready__c, OR(OR(NTE_Invoice_Required__c = "Yes", NTE_Listed_Price_Total__c > 0, NOT(NTE_Pricing_Ready__c)), OR(NTE_Top_Up_Invoice_Required__c, BLANKVALUE(NTE_Top_Up_Staff_Total__c, 0) > 0)), AND(OR(NOT(OR(NTE_Invoice_Required__c = "Yes", NTE_Listed_Price_Total__c > 0, NOT(NTE_Pricing_Ready__c))), NTE_Invoice_Provided__c), OR(NOT(OR(NTE_Top_Up_Invoice_Required__c, BLANKVALUE(NTE_Top_Up_Staff_Total__c, 0) > 0)), NTE_Top_Up_Invoice_Provided__c)), AND(OR(NOT(OR(NTE_Invoice_Required__c = "Yes", NTE_Listed_Price_Total__c > 0, NOT(NTE_Pricing_Ready__c))), NTE_Payment_Received__c), OR(NOT(OR(NTE_Top_Up_Invoice_Required__c, BLANKVALUE(NTE_Top_Up_Staff_Total__c, 0) > 0)), NTE_Top_Up_Payment_Received__c)))
```

### NTE Finance Payment Due formula

API name: Opportunity.NTE_Finance_Payment_Due__c.

```text
AND(NTE_Pricing_Ready__c, OR(AND(OR(NTE_Invoice_Required__c = "Yes", NTE_Listed_Price_Total__c > 0, NOT(NTE_Pricing_Ready__c)), NTE_Invoice_Provided__c, NOT(NTE_Payment_Received__c)), AND(OR(NOT(OR(NTE_Invoice_Required__c = "Yes", NTE_Listed_Price_Total__c > 0, NOT(NTE_Pricing_Ready__c))), NTE_Payment_Received__c), OR(NTE_Top_Up_Invoice_Required__c, BLANKVALUE(NTE_Top_Up_Staff_Total__c, 0) > 0), NTE_Top_Up_Invoice_Provided__c, NOT(NTE_Top_Up_Payment_Received__c))))
```

### NTE Pricing Ready formula

API name: Opportunity.NTE_Pricing_Ready__c.

```text
AND(NOT(ISBLANK(NTE_Listed_Price_Total__c)), NTE_Listed_Price_Total__c >= 0, OR(ISPICKVAL(NTE_Pricing_Status__c, "Calculated"), AND(ISBLANK(TEXT(NTE_Pricing_Status__c)), NTE_Listed_Price_Total__c > 0)))
```

### NTE Sales Process

Source: force-app/main/default/objects/Opportunity/businessProcesses/NTE_Sales_Process.businessProcess-meta.xml.

fullName: NTE_Sales_Process.

description: Sales process used by National Transition Event opportunities.

isActive: true.

values: fullName=Qualification; fullName=Needs Analysis; fullName=Proposal; fullName=Negotiation; fullName=Closed Won; fullName=Closed Lost.

### NTE Event Opportunity

Source: force-app/main/default/objects/Opportunity/recordTypes/NTE_Event_Opportunity.recordType-meta.xml.

fullName: NTE_Event_Opportunity.

active: true.

businessProcess: NTE_Sales_Process.

description: National Transition Event exhibitor, partner and sponsor opportunities.

label: NTE Event Opportunity.

## Account

API name: Account. 5 packaged fields. The standard organisation identity can be reused across editions. Five custom fields are the latest NTE classification summary. A later conversion may replace those summaries; use related Opportunities for the event history. Core Account identity is selected through native conversion rather than overwritten by the supplementary service.


| Field and exact definition | Meaning and data lineage |
| --- | --- |
| NTE_Booking_Reference__c<br>Latest NTE Booking Reference<br>Text(80); required=false; trackFeedHistory=false<br>Field access E/E/–/– | Latest classified application booking reference copied during conversion; a text summary, not the relationship to that booking. |
| NTE_Event_Code__c<br>Latest NTE Event Code<br>Text(20); required=false; trackFeedHistory=false<br>Field access E/E/–/– | Latest classified application edition copied during conversion; earlier event history remains on related Opportunities. |
| NTE_Last_Application_Date__c<br>Latest NTE Application Date<br>DateTime; required=false; trackFeedHistory=false<br>Field access E/E/–/– | Conversion Flow execution timestamp from $Flow.CurrentDateTime; later conversions replace this latest-application summary. |
| NTE_Participant__c<br>NTE Organisation<br>Checkbox; required=false; defaultValue=false; trackFeedHistory=false<br>Field access E/E/–/– | Identifies an organisation created or updated from a converted NTE application. |
| NTE_Source_Form_Type__c<br>Latest NTE Source Form<br>Text(100); required=false; trackFeedHistory=false<br>Field access E/E/–/– | Latest converted commercial application type copied from Lead.Web_Form_Type__c. |



## Contact

API name: Contact. 6 packaged fields. The standard person identity can be reused across editions. Six custom fields summarise the latest NTE application/classification. OpportunityContactRole supplies each booking association and Primary choice. Event-day and billing contact details on the booking are descriptive fields and are not alternate email recipients.


| Field and exact definition | Meaning and data lineage |
| --- | --- |
| NTE_Booking_Reference__c<br>Latest NTE Booking Reference<br>Text(80); required=false; trackFeedHistory=false<br>Field access E/E/–/– | Latest classified application booking reference copied during conversion; a text summary, not the relationship to that booking. |
| NTE_Contact_Role__c<br>NTE Contact Role<br>Text(100); required=false; trackFeedHistory=false<br>Field access E/E/–/– | Classification text set to Applicant / event contact during conversion. The independent OpportunityContactRole record controls the booking Primary Contact. |
| NTE_Event_Code__c<br>Latest NTE Event Code<br>Text(20); required=false; trackFeedHistory=false<br>Field access E/E/–/– | Latest classified application edition copied during conversion; earlier event history remains on related Opportunities. |
| NTE_Last_Application_Date__c<br>Latest NTE Application Date<br>DateTime; required=false; trackFeedHistory=false<br>Field access E/E/–/– | Conversion Flow execution timestamp from $Flow.CurrentDateTime; later conversions replace this latest-application summary. |
| NTE_Participant__c<br>NTE Contact<br>Checkbox; required=false; defaultValue=false; trackFeedHistory=false<br>Field access E/E/–/– | Identifies a person created or updated from a converted NTE application. |
| NTE_Source_Form_Type__c<br>Latest NTE Source Form<br>Text(100); required=false; trackFeedHistory=false<br>Field access E/E/–/– | Latest converted commercial application type copied from Lead.Web_Form_Type__c. |



## NTE Email Dispatch

API name: NTE_Email_Dispatch__c. 15 packaged fields. One durable request/outcome per communication kind, run and source target. Its unique key makes queue/retry behaviour idempotent. It stores a reviewed recipient/content snapshot and later processing result. Invitation/final-pack outcomes synchronise selected source fields; reminders do not complete preparation. Booking-payment confirmation uses its fixed run identity.

Object settings: deploymentStatus=Deployed; description=Individual NTE invitation, reminder, booking-confirmation and final-pack email requests and outcomes.; enableActivities=false; enableHistory=true; enableReports=true; label=NTE Email Dispatch; nameField=displayFormat=NTE-EMAIL-{000000}; label=Dispatch Number; type=AutoNumber; pluralLabel=NTE Email Dispatches; sharingModel=ReadWrite.


| Field and exact definition | Meaning and data lineage |
| --- | --- |
| Contact__c<br>Recipient Contact<br>Lookup; required=false; lookup to Contact; delete=SetNull; relationship=NTE_Email_Dispatches_Contact; label=NTE email dispatches<br>Field access E/E/–/– | Optional snapshot association to the booking Primary Contact selected for this email. The email address and fingerprint are saved separately. |
| Dispatch_Key__c<br>Dispatch Key<br>Text(100); required=false; unique=true; externalId=true<br>Field access E/E/–/– | Unique external SHA256 identity of kind, run and target. Repeated queue/retry uses the same row rather than generating another send. |
| Error__c<br>Send Error<br>LongTextArea(32768); required=false; visibleLines=4<br>Field access E/E/–/– | Specific preparation, changed-snapshot, queue or send failure retained for retry review. |
| Event_Code__c<br>Event Code<br>Text(20); required=false<br>Field access E/E/–/– | Edition captured for the reviewed message, checked against current eligibility before delivery. |
| Fingerprint__c<br>Recipient Snapshot<br>Text(64); required=false<br>Field access E/E/–/– | Hash of recipient and merged booking/route facts. A change after review prevents sending stale content. |
| Kind__c<br>Email Type<br>Text(40); required=false<br>Field access E/E/–/– | One implemented invitation, staff/vehicle/logo reminder, final-pack or booking-payment-confirmation route. |
| Lead__c<br>Interest<br>Lookup; required=false; lookup to Lead; delete=SetNull; relationship=NTE_Email_Dispatches_Lead; label=NTE email dispatches<br>Field access E/E/–/– | Optional source interest Lead for invitations; mutually contextual with the booking target in application logic. |
| Link__c<br>Action Link<br>Text(255); required=false<br>Field access E/E/–/– | Saved participant-specific application/update/final-pack HTTPS action destination. |
| Message__c<br>Message<br>LongTextArea(32768); required=false; visibleLines=4<br>Field access E/E/–/– | Saved reviewed plain-text message content, including its supported personalisation tokens; HTML is rendered by the service. |
| Opportunity__c<br>Booking<br>Lookup; required=false; lookup to Opportunity; delete=SetNull; relationship=NTE_Email_Dispatches_Opportunity; label=NTE email dispatches<br>Field access E/E/–/– | Optional booking target for preparation, pack or paid-confirmation messages. |
| Recipient__c<br>Email Address<br>Email; required=false<br>Field access E/E/–/– | The saved email address being reviewed/sent; arbitrary fallback contact addresses are not used. |
| Run_Id__c<br>Send Batch<br>Text(64); required=false<br>Field access E/E/–/– | One composer run identity; independent reminder runs can occur while preparation remains outstanding. Payment confirmation has a fixed run identity. |
| Sent_At__c<br>Sent At<br>DateTime; required=false<br>Field access E/E/–/– | Time Salesforce accepted this individual message, not final recipient inbox delivery. |
| Status__c<br>Status<br>Text(20); required=false<br>Field access E/E/–/– | Queued, Sent, Failed or Skipped request outcome. Only supported failed rows are retryable. |
| Subject__c<br>Subject<br>Text(255); required=false<br>Field access E/E/–/– | Saved reviewed subject, revalidated after personalisation for length and content. |



## NTE Payment Request

API name: NTE_Payment_Request__c. 23 packaged fields. One initial booking charge snapshot per Salesforce org and Opportunity. Amounts in minor units are integer pence; tax rate and net/gross values are saved with source identity, merchant/mode and stable Stripe resource/idempotency keys. Ready describes a verified request, not collected payment. Existing test resources are never relabelled as live resources.

Object settings: deploymentStatus=Deployed; description=Saved NTE payment request identities, charge snapshots and Stripe outcomes.; enableActivities=false; enableHistory=true; enableReports=true; label=NTE Payment Request; nameField=displayFormat=NTE-PAY-{000000}; label=Payment Request; type=AutoNumber; pluralLabel=NTE Payment Requests; sharingModel=ReadWrite.


| Field and exact definition | Meaning and data lineage |
| --- | --- |
| Amount_Minor__c<br>Amount in Minor Units<br>Number(18,0); required=false<br>Field access R/R/–/R | Fixed gross charge including saved VAT, in integer GBP pence. This is the Stripe Price amount. |
| Batch_Key__c<br>Email Batch<br>Text(64); required=false<br>Field access R/R/–/R | Approval batch that should resume after this request completes or fails. |
| Charge_Key__c<br>Charge Key<br>Text(100); required=false; unique=true; externalId=true<br>Field access R/R/–/R | Unique external org ID plus Opportunity ID plus Booking identity. Also anchors the stable Price/Link idempotency keys. |
| Currency__c<br>Currency<br>Text(3); required=false<br>Field access R/R/–/R | Saved Stripe currency code; this implementation requires gbp. |
| Delivered_At__c<br>Payment Email Sent At<br>DateTime; required=false<br>Field access R/R/–/R | Acceptance time of the provisional email containing this verified link, not payment collection time. |
| Description__c<br>Charge Description<br>Text(255); required=false<br>Field access R/R/–/R | Year-neutral NTE booking description containing the booking reference; used as the new Stripe Product name. |
| Error__c<br>Error<br>LongTextArea(4000); required=false; visibleLines=3<br>Field access R/R/–/R | Last preparation/reverification or ambiguous external outcome requiring repair or manual review. |
| First_Attempt_At__c<br>First Attempt At<br>DateTime; required=false<br>Field access R/R/–/R | First external creation attempt. An ambiguous request older than 23 hours is held for review. |
| Kind__c<br>Charge Type<br>Text(20); required=false<br>Field access R/R/–/R | Charge kind. The active coordinator creates Booking requests; low-level staff top-up support is not automatic orchestration. |
| Link_Id__c<br>Stripe Payment Link ID<br>Text(100); required=false<br>Field access R/R/–/R | Persisted Stripe Payment Link identity used for verification and safe reuse on email retry. |
| Live_Mode__c<br>Live Payment<br>Checkbox; required=false; defaultValue=false<br>Field access R/R/–/R | Saved environment binding. A test request cannot be reused after switching configuration to live. |
| Net_Minor__c<br>Net in Minor Units<br>Number(18,0); required=false<br>Field access R/R/–/R | Saved initial net booking amount in pence, excluding VAT and later separate top-ups. |
| Opportunity__c<br>Booking<br>Lookup; required=false; lookup to Opportunity; delete=SetNull; relationship=NTE_Payment_Requests; label=NTE Payment Requests<br>Field access R/R/–/R | Booking lookup for this charge. Custom lookup deletion is SetNull; the remaining snapshot preserves request evidence. |
| Payment_URL__c<br>Payment Link<br>Url; required=false<br>Field access R/R/–/R | Verified buy.stripe.com URL inserted into the Pay Now button after all readiness checks. |
| Price_Id__c<br>Stripe Price ID<br>Text(100); required=false<br>Field access R/R/–/R | Persisted fixed Stripe Price identity; retained if link creation fails so retry can reuse it. |
| Recipient__c<br>Payment Email Recipient<br>Email; required=false<br>Field access R/R/–/R | Exact saved Primary Contact address bound to the charge/email snapshot. |
| Reference__c<br>Booking Reference<br>Text(80); required=false<br>Field access R/R/–/R | Saved booking reference copied into Stripe resource metadata and the recipient message. |
| Source_Fingerprint__c<br>Charge Snapshot<br>Text(64); required=false<br>Field access R/R/–/R | Hash of source identity, components, recipient and payment configuration. Changes prevent reusing an old issued proposal. |
| Source_Lead_Id__c<br>Application ID<br>Text(18); required=false<br>Field access R/R/–/R | Text ID of the converted application source, validated by the coordinator; not a metadata lookup. |
| Status__c<br>Status<br>Text(30); required=false<br>Field access R/R/–/R | External request preparation status. Ready means recently verified and usable for email, not paid. |
| Stripe_Account__c<br>Stripe Account<br>Text(60); required=false<br>Field access R/R/–/R | Saved expected acct_ merchant identity verified before resource creation. |
| Tax_Rate__c<br>Tax Rate<br>Number(18,2); required=false<br>Field access R/R/–/R | Saved percentage used to calculate the gross fixed request. The client confirmed 20% VAT on 13 September; preserve the rate saved on the request. |
| Verified_At__c<br>Verified At<br>DateTime; required=false<br>Field access R/R/–/R | Time the resource contract was checked; email requires a matching recent verification within five minutes. |



## NTE Routing Config Configuration

API name: NTE_Routing_Config__mdt. 10 packaged fields. Public custom metadata holding environment-specific owner and participant destinations. The code uses the Default record. Empty final-pack destinations deliberately make affected recipients ineligible; source field names alone do not provide the missing event information.

Object settings: description=Environment-specific owner routing for National Transition Event submissions.; label=NTE Routing Configuration; pluralLabel=NTE Routing Configurations; visibility=Public.


| Field and exact definition | Meaning and data lineage |
| --- | --- |
| Application_Event_Code__c<br>Final Pack Event Code<br>Text(20); required=false<br>Field access –/–/–/– | Exact edition required for final-pack eligibility. The API retains its earlier Application name; current invitation links are not gated by this value. |
| Exhibitor_Application_URL__c<br>Exhibitor Application URL<br>Text(255); required=false<br>Field access –/–/–/– | HTTPS exhibitor application destination personalised into an invitation to an exhibitor expression of interest. |
| Exhibitor_Final_Pack_URL__c<br>Exhibitor Final Pack URL<br>Text(255); required=false<br>Field access –/–/–/– | HTTPS final event information destination for eligible completed exhibitor bookings; blank makes that route ineligible. |
| Exhibitor_Staff_Form_URL__c<br>Exhibitor Staff Form URL<br>Text(255); required=false<br>Field access –/–/–/– | Public form used by exhibitors to provide or update their NTE staff details. |
| Heavy_Vehicle_Form_URL__c<br>Heavy Vehicle Form URL<br>Text(255); required=false<br>Field access –/–/–/– | Public form used to collect outstanding NTE heavy vehicle and logistics details. |
| Logo_Update_Form_URL__c<br>Logo Update Form URL<br>Text(255); required=false<br>Field access –/–/–/– | Public form used by confirmed NTE organisations to provide their latest logo. |
| Owner_Username__c<br>Owner Username<br>Text(255); required=false<br>Field access –/–/–/– | Username of the active Salesforce user who owns NTE submissions and receives internal notifications in this environment. |
| Partner_Application_URL__c<br>Partner Application URL<br>Text(255); required=false<br>Field access –/–/–/– | HTTPS partner/sponsor application destination personalised into an invitation to a partner/sponsor expression of interest. |
| Partner_Final_Pack_URL__c<br>Partner Final Pack URL<br>Text(255); required=false<br>Field access –/–/–/– | HTTPS final event information destination for eligible completed partner/sponsor bookings; blank makes that route ineligible. |
| Partner_Staff_Form_URL__c<br>Partner Staff Form URL<br>Text(255); required=false<br>Field access –/–/–/– | Public form used by partners and sponsors to provide or update their NTE staff details. |



## NTE Stripe Config Configuration

API name: NTE_Stripe_Config__mdt. 7 packaged fields. Public custom metadata controlling activation, exact target org/merchant, environment, tax and optional scope. It contains no secret API key. The code uses Default; the two example JSON files serve the separate preflight helper, not runtime configuration.

Object settings: label=NTE Stripe Configuration; pluralLabel=NTE Stripe Configurations; visibility=Public.


| Field and exact definition | Meaning and data lineage |
| --- | --- |
| Allowed_Email__c<br>Recipient Email Filter<br>Text(255); required=false<br>Field access –/–/–/– | Optional case-insensitive exact Primary Contact email filter. Blank permits any otherwise eligible recipient; a mismatch blocks payment preparation. |
| Enabled__c<br>Enabled<br>Checkbox; required=false; defaultValue=false<br>Field access –/–/–/– | Activation switch for the Stripe booking coordinator. It is considered with payment method, positive booking value and optional reference prefix. |
| Expected_Account_Id__c<br>Expected Stripe Account<br>Text(255); required=false<br>Field access –/–/–/– | Expected acct_ merchant identity. The Stripe client reads and verifies the actual account before creating or reusing payment resources. |
| Expected_Org_Id__c<br>Expected Salesforce Org<br>Text(255); required=false<br>Field access –/–/–/– | Exact 18-character destination Salesforce organisation ID; a different org cannot operate this saved configuration. |
| Live_Mode__c<br>Live Payments<br>Checkbox; required=false; defaultValue=false<br>Field access –/–/–/– | Selects the test or live named credential and required Stripe environment. Existing payment requests retain their original environment binding. |
| Reference_Prefix__c<br>Booking Reference Filter<br>Text(255); required=false<br>Field access –/–/–/– | Optional case-sensitive booking-reference prefix used to select the enabled rollout scope. Blank imposes no prefix restriction. |
| Tax_Rate__c<br>Tax Rate (%)<br>Number(5,2); required=false<br>Field access –/–/–/– | Percentage between 0 and 100 used to derive the saved gross fixed charge from net GBP pence; the rate is snapshotted on each payment request. |



## Picklist value catalogue

The API value is the stored value. Unless a different label is shown, the displayed label is identical. Explicit inactive values and defaults are retained exactly. Consecutive numeric strings are expressed as an inclusive range only when every member is present with the same default/active treatment.

### PL01 values

Used by: Lead.Additional_Staff_Count__c. Sorted: false.

Every integer string from 0 through 99 inclusive, in ascending order. default=false; active=not explicitly overridden.

### PL02 values

Used by: Lead.Additional_Staff_Required__c, Lead.Supplier_Agreement_Required__c. Sorted: false.

Yes; No; Don't know.

### PL03 values

Used by: Lead.Delivery_Window__c. Sorted: false.

Sunday 28 February between 14:00 - 18:00; Monday 1 March between 06:30 - 07:15.

### PL04 values

Used by: Lead.Event_Discovery_Source__c. Sorted: false.

Previous exhibitor; E-mail invitation; Word of mouth from previous exhibitor; Word of mouth from previous attendees; Website; LinkedIn; Facebook; Instagram; Previous NTE event; NTE webinar or brochure; Email invitation; Recommendation or word of mouth; National Transition Event website; Mission Community website; Other social media; Other.

### PL05 values

Used by: Lead.Exhibitor_Hall_Schedule__c, Lead.Guest_Accessibility_Required__c, Lead.Guest_Accompanying__c, Lead.Has_Special_Requirements__c, Lead.Invoice_Required__c, Lead.Purchase_Order__c, Lead.Quote_Required_for_PO__c, Lead.Stand_Power__c, Lead.Top_Up_Staff_Required__c, Lead.Volunteer_Armed_Forces_Service__c, Lead.Volunteer_Consent__c, Lead.Volunteer_DBS_Willing__c. Sorted: false.

Yes; No.

### PL06 values

Used by: Lead.Exhibitor_Interest_Areas__c. Sorted: false.

Careers and recruitment; Training and education; Automotive and mobility; Manufacturing and engineering; Renewable and clean energy; Defence and security; Built environment and facilities; Financial and professional services; Digital and technology; Armed Forces charity or support; Other.

### PL07 values

Used by: Lead.Exhibitor_Organisation_Category__c. Sorted: false.

Charity - member of Cobseo → Charity - member of COBSEO; Charity - not a member of Cobseo → Charity - not a member of COBSEO; Employer - Automotive Sector; Employer - Manufacturing Sector; Employer - Renewable & Clean Energy Sector; Employer - Defence → Employer - Defence & Security; Employer - Built Environment; Employer - Facilities Management; Employer - Financial and Professional Services; Employer - Digital & Technologies; Employer - Training Provider from any industry; Employer - Landbased industry; Employer - Blue Light & NHS; Employer - Other Sectors not denoted above; Government or Government Agency; Local Government or LG related; Trade Association; CIC or Not for Profit; Regular or Reserve Services, or Cadets.

### PL08 values

Used by: Lead.Exhibitor_Space_Selections__c. Sorted: false.

Garage Space - reduced size with power - £599 + VAT; Single Garage - Paddock Side with power - £799 + VAT; Double Garage - Paddock Side with power - £1,299 + VAT; Single Garage - Track Side - £799 + VAT; Double Garage - Track Side - £1,299 + VAT; Clean Energy Zone - Single - £499 + VAT; Clean Energy Zone - Double - £849 + VAT; Built Environment Zone - Single - £499 + VAT; Built Environment Zone - Double - £849 + VAT; Manufacturing Zone - Single - £499 + VAT; Manufacturing Zone - Double - £849 + VAT; Defence & Security Zone - Single - £499 + VAT; Defence & Security Zone - Double - £849 + VAT; Digital and Technologies Zone - Single - £499 + VAT; Digital and Technologies Zone - Double - £849 + VAT; FM Zone - Single - £499 + VAT; FM Zone - Double - £849 + VAT; Professional & Financial Zone - Single - £499 + VAT; Professional & Financial Zone - Double - £849 + VAT; Training & Education Zone - Single - £499 + VAT; Any other business - Single - £499 + VAT; Any other business - Double - £849 + VAT; Local Government Authority - Single - £249.50 + VAT; Blue Light - Single - £249.50 + VAT; Trade Association - Single - £499 + VAT; COBSEO Charity - Single - Free; Non COBSEO Charity - Single - Free.

### PL09 values

Used by: Lead.Exhibitor_Space_Size__c. Sorted: false.

Headline Partner - size and position to be confirmed with sponsor; Gold Partner - size and position to be confirmed with sponsor; Premier Partner - double exhibitor space (two trestle tables length); Champion Partner - standard exhibitor space (one trestle table length); Zone Sponsor - double exhibitor space (two trestle tables length); Troops' Track Day Partner - standard exhibitor space (one trestle table length); Standard exhibitor space (one trestle table length) - suitable for Community Stage, Event Guide Sponsor, Delegate Tote Bag and Karting Activity sponsors); 10m × 6m [inactive]; 11m × 7m [inactive]; 12m × 4m [inactive]; 13m × 5m [inactive]; 14m × 6m [inactive]; 15m × 7m [inactive]; 16m × 4m [inactive]; 17m × 5m [inactive]; 18m × 6m [inactive]; 19m × 7m [inactive]; 20m × 4m [inactive]; 9m × 5m [inactive]; As specified in selected space [inactive].

### PL10 values

Used by: Lead.Heavy_Vehicle_Required__c. Sorted: false.

Yes; No; Not known yet.

### PL11 values

Used by: Lead.NTE_Applicant_Email_Status__c. Sorted: false.

Accepted by Salesforce; Failed; Not Attempted; Not required.

### PL12 values

Used by: Lead.NTE_Internal_Email_Status__c, Lead.Volunteer_Applicant_Email_Status__c, Lead.Volunteer_Internal_Email_Status__c. Sorted: false.

Accepted by Salesforce; Failed; Not Attempted.

### PL13 values

Used by: Lead.NTE_Update_Status__c. Sorted: false.

Pending; Matched and Applied; No Matching Booking; Ambiguous Booking Reference; Failed.

### PL14 values

Used by: Lead.Organisation_Type__c. Sorted: false.

Charity - COBSEO member; Charity - Non COBSEO member; Government Department or Agency; Industry Body / Trade Association; Employer - Automotive; Employer - Clean Energy; Employer - Blue Light Services / NHS; Employer - Built Environment; Employer - Manufacturing; Employer - Defence and Security; Employer - Financial and Professional Services; Employer - Digital and Technologies; Employer - Training and Education; Employer - Land-based; Employer - Other sector; Commercial business; Charity or non-profit; Government or public body; Industry body or trade association; Education or training provider; Other.

### PL15 values

Used by: Lead.Partner_Interest_Areas__c. Sorted: false.

Strategic event partnership; Event zone sponsorship; Stage, content or thought leadership; Branding and delegate experience; Troops' Track Day; Other or not sure.

### PL16 values

Used by: Lead.Partner_Interest_Type__c. Sorted: false.

Partnership; Sponsorship; Both - open to discussion; Not sure - I would like advice.

### PL17 values

Used by: Lead.Payment_Method__c, Opportunity.NTE_Payment_Method__c. Sorted: false.

Bank transfer; Stripe.

### PL18 values

Used by: Lead.Planned_Exhibitor_Count__c. Sorted: false.

1; 2; 3; 4; 5; 6; 7; 8; 9; 10; 11; 12; 13; 14; 15; 16; 17; 18; 19; 20; 21; 22; 23; 24; 25; 26; 27; 28; 29; 30; 31; 32; 33; 34; 35; 36; 37; 38; 39; 40; 41; 42; 43; 44; 45; 46; 47; 48; 49; 50; 51; 52; 53; 54; 55; 56; 57; 58; 59; 60; 61; 62; 63; 64; 65; 66; 67; 68; 69; 70; 71; 72; 73; 74; 75; 76; 77; 78; 79; 80; 81; 82; 83; 84; 85; 86; 87; 88; 89; 90; 91; 92; 93; 94; 95; 96; 97; 98; 99; More than 9.

### PL19 values

Used by: Lead.Preferred_Contact_Method__c. Sorted: false.

Email; Telephone; Video call; No preference.

### PL20 values

Used by: Lead.Previous_NTE_Events__c. Sorted: false.

No; NTE2024 → NTE24; NTE2025 → NTE25; NTE2026 → NTE26.

### PL21 values

Used by: Lead.Pricing_Status__c, Opportunity.NTE_Pricing_Status__c. Sorted: false.

Calculated; Review required.

### PL22 values

Used by: Lead.Sponsor_Package__c, Opportunity.NTE_Sponsor_Package__c. Sorted: false.

Headline Partner; Gold Partner; Premier Partner; Champion Partner; Zone Sponsor; Community Stage Sponsor; Podcast Corner Sponsor; Event Guide Sponsor; Delegate Tote Bag Sponsor; Helmet Bay Sponsor; Auditorium Sponsor; Live Stream Sponsor; Wristband Sponsor; Escapade Sponsor.

### PL23 values

Used by: Lead.Staff_Update_Audience__c. Sorted: false.

Exhibitor; Partner / sponsor.

### PL24 values

Used by: Lead.Volunteer_Availability__c. Sorted: false.

Weekdays; Weekends; Any.

### PL25 values

Used by: Lead.Volunteer_Hours__c. Sorted: false.

0-4; 4-8; 8-16; 16+; Don't know.

### PL26 values

Used by: Lead.Volunteer_Opportunities__c, Lead.Volunteer_Skills__c. Sorted: false.

Fundraising; Transport and Logistics; Motorsport Event Support; Marshalling; Community Outreach / Awareness; Professional Skills; Mentoring & Coaching; Team Area Co-Ordinator; Vehicle Maintenance / Repairs (Wantage); Pop up shop; Storekeeping (Wantage); Maintenance / DIY (Wantage); Driving / Transport [inactive]; Charity Merchandise / Shop Support [inactive].

### PL27 values

Used by: Lead.Volunteer_Travel_Regions__c. Sorted: false.

East Midlands; Greater London; North East England; North West England; Scotland; South West England; South East England; Wales; West Midlands; Yorkshire & the Humber.

### PL28 values

Used by: Lead.Web_Form_Type__c. Sorted: false.

Partner Sponsor Application Form; Partner Sponsor Exhibition Space Questions; Partner / Sponsor Expression of Interest; Exhibitor Expression of Interest; Partner / Sponsor Application; Exhibitor Application; Guest Registration; Staff Details Update; Partner / Sponsor Staff Update; Exhibitor Staff Update; Heavy Vehicle Details; Logo Update; Volunteer Application.

### PL29 values

Used by: Opportunity.NTE_Attendance_Status__c. Sorted: false.

Planned; Attended; Did Not Attend; Cancelled.
