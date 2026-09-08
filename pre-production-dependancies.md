# Pre-production dependencies

Field inventory refreshed: 2 September 2026. Broader package dependency review: 8 September 2026.

The [8 September review](audit/NTE_PACKAGE_DEPENDENCY_REVIEW_2026-09-08.md) confirms all 46 inherited fields remain in source and the manifest, with no further missing custom fields in its scanned scope. It also identifies and closes the missing OpportunityStage metadata dependency, and records shared settings that require target-specific review. The historical inventory below is preserved; its original field-purpose prose is not authority to override the current Primary Contact or pricing rules. Use `scripts/audit-package-dependencies.py` for the current broader scan; the older field-only generator does not cover the full package.

Source org: Mission Motorsport MMUAT sandbox (`mission-mmuat`)

Scope: custom fields on Lead, Account, Contact and Opportunity that this solution inherited from pre-existing MMUAT metadata and therefore must carry into production without relying on the previous package.

## Result

The audit identified **46 inherited Lead fields**: **38 used by the NTE event journeys** and **8 shared with the isolated volunteer journey**. Before remediation, the repository contained 87 of the 133 Lead custom fields used by the complete source package; the 46 inherited fields represented 34.6% of that Lead-field surface.

All 46 field definitions are now present under `force-app/main/default/objects/Lead/fields`, are included in `manifest/production-package.xml`, and passed the complete MMUAT metadata validation. Production no longer needs the previous package to supply them.

The Web-to-Lead IDs below are sandbox-specific. Production fields receive different IDs, so the sole published form configuration in `stevostar1234/nte27-web-to-lead-demo` must be remapped after the production fields are deployed and before the production forms are published.

## Required deployment sequence

1. Validate `manifest/production-package.xml` against production without committing changes.
2. Deploy the complete package so fields, permissions, automation, pages and reports remain one versioned unit.
3. Retrieve the production Web-to-Lead organisation ID and field IDs and replace the MMUAT values in the canonical client forms repository.
4. Verify every Lead-to-Opportunity mapping below, then run controlled application, conversion, finance and supplementary-update tests.
5. Publish the production form URLs only after those tests pass.

## Core NTE field inventory

### 1. Additional Staff Count

- **Object and API name:** `Lead.Additional_Staff_Count__c`
- **Field label:** Additional Staff Count
- **Sandbox definition:** Picklist (restricted: true); required: No
- **Sandbox description:** Captured by the NTE27 exhibitor Web-to-Lead form.
- **Active values:** Every whole number from `0` through `99`
- **Sandbox Web-to-Lead field ID:** `00NAd00000Ham17MAB`
- **Conversion destination:** `Opportunity.NTE_Additional_Staff_Count__c`
- **Function in this solution:** Stores the number of chargeable staff places requested and drives the additional-staff price calculation, confirmations and conversion.
- **Referenced by:** public forms / Web-to-Lead mapping, pricing automation, lead conversion, supplementary updates, email templates, Salesforce UI, security or reporting, automated tests (27 project files)
- **Key references:** `assets/config.js`, `email-templates/source/exhibitor-application-applicant-confirmation.html`, `email-templates/source/exhibitor-application-internal-notification.html`, `email-templates/source/exhibitor-approved-confirmation.html`, `email-templates/source/exhibitor-staff-update-applicant-confirmation.html`, `email-templates/source/government-charity-approved-confirmation.html`, …
- **Production-package status:** Field metadata is included. Preserve its API name and definition, retain the documented conversion and permission references, and remap its Web-to-Lead ID in production.

### 2. Additional Staff Required

- **Object and API name:** `Lead.Additional_Staff_Required__c`
- **Field label:** Additional Staff Required
- **Sandbox definition:** Picklist (restricted: true); required: No
- **Sandbox description:** Captured by the NTE27 exhibitor Web-to-Lead form.
- **Active values:** `Yes`, `No`, `Don't know`
- **Sandbox Web-to-Lead field ID:** `00NAd00000Ham18MAB`
- **Conversion destination:** `Opportunity.NTE_Additional_Staff_Required__c`
- **Function in this solution:** Records whether the applicant needs staff places beyond the package allowance and controls the additional-staff pricing path.
- **Referenced by:** public forms / Web-to-Lead mapping, pricing automation, lead conversion, supplementary updates, email templates, Salesforce UI, security or reporting, automated tests (25 project files)
- **Key references:** `assets/config.js`, `email-templates/source/exhibitor-application-applicant-confirmation.html`, `email-templates/source/exhibitor-application-internal-notification.html`, `email-templates/source/exhibitor-approved-confirmation.html`, `email-templates/source/exhibitor-staff-update-applicant-confirmation.html`, `email-templates/source/government-charity-approved-confirmation.html`, …
- **Production-package status:** Field metadata is included. Preserve its API name and definition, retain the documented conversion and permission references, and remap its Web-to-Lead ID in production.

### 3. Alternative Organisation Name

- **Object and API name:** `Lead.Alternative_Organisation_Name__c`
- **Field label:** Alternative Organisation Name
- **Sandbox definition:** Text (length 255); required: No
- **Sandbox description:** Captured by the NTE27 exhibitor Web-to-Lead form.
- **Sandbox Web-to-Lead field ID:** `00NAd00000Ham19MAB`
- **Conversion destination:** `Opportunity.NTE_Alternative_Organisation_Name__c`
- **Function in this solution:** Preserves a former or alternative organisation name for legacy submissions and copies it to the approved booking.
- **Referenced by:** public forms / Web-to-Lead mapping, lead conversion, email templates, Salesforce UI, security or reporting, automated tests (10 project files)
- **Key references:** `assets/config.js`, `email-templates/source/exhibitor-application-internal-notification.html`, `force-app/main/default/classes/NTEConversionFlowTest.cls`, `force-app/main/default/flexipages/NTE_Management_Lead_Record_Page.flexipage-meta.xml`, `force-app/main/default/flows/NTE_Copy_Converted_Lead_to_Opportunity.flow-meta.xml`, `force-app/main/default/permissionsets/NTE_Forms_Administration.permissionset-meta.xml`, …
- **Production-package status:** Field metadata is included. Preserve its API name and definition, retain the documented conversion and permission references, and remap its Web-to-Lead ID in production.

### 4. Declaration Name

- **Object and API name:** `Lead.Declaration_Name__c`
- **Field label:** Declaration Name
- **Sandbox definition:** Text (length 200); required: No
- **Sandbox description:** Captured by the NTE27 exhibitor Web-to-Lead form.
- **Sandbox Web-to-Lead field ID:** `00NAd00000Ham1AMAR`
- **Conversion destination:** `Opportunity.NTE_Declaration_Name__c`
- **Function in this solution:** Stores the applicant's typed digital signature used by the application declaration and confirmation trail.
- **Referenced by:** public forms / Web-to-Lead mapping, lead conversion, Salesforce UI, security or reporting, automated tests (23 project files)
- **Key references:** `assets/config.js`, `exhibitor-application.html`, `exhibitor-interest.html`, `force-app/main/default/classes/NTEConversionFlowTest.cls`, `force-app/main/default/flexipages/NTE_Management_Lead_Record_Page.flexipage-meta.xml`, `force-app/main/default/flows/NTE_Copy_Converted_Lead_to_Opportunity.flow-meta.xml`, …
- **Production-package status:** Field metadata is included. Preserve its API name and definition, retain the documented conversion and permission references, and remap its Web-to-Lead ID in production.

### 5. Event Contact Email

- **Object and API name:** `Lead.Event_Contact_Email__c`
- **Field label:** Event Contact Email
- **Sandbox definition:** Email; required: No
- **Sandbox description:** No description is stored in the sandbox metadata.
- **Sandbox Web-to-Lead field ID:** `00NAd00000HZSVtMAP`
- **Conversion destination:** `Opportunity.NTE_Event_Contact_Email__c`
- **Function in this solution:** Stores the operational event contact email used by confirmations, update matching and the approved Opportunity.
- **Referenced by:** public forms / Web-to-Lead mapping, lead conversion, supplementary updates, email templates, Salesforce UI, security or reporting, automated tests (20 project files)
- **Key references:** `assets/config.js`, `email-templates/source/partner-sponsor-application-internal-notification.html`, `email-templates/source/partner-sponsor-application-received.html`, `exhibitor-application.html`, `force-app/main/default/classes/NTEConversionFlowTest.cls`, `force-app/main/default/classes/NTEUpdateSubmissionService.cls`, …
- **Production-package status:** Field metadata is included. Preserve its API name and definition, retain the documented conversion and permission references, and remap its Web-to-Lead ID in production.

### 6. Event Contact Mobile

- **Object and API name:** `Lead.Event_Contact_Mobile__c`
- **Field label:** Event Contact Mobile
- **Sandbox definition:** Phone; required: No
- **Sandbox description:** No description is stored in the sandbox metadata.
- **Sandbox Web-to-Lead field ID:** `00NAd00000HZSVuMAP`
- **Conversion destination:** `Opportunity.NTE_Event_Contact_Mobile__c`
- **Function in this solution:** Stores the operational event contact mobile number used by the event team and copied to the approved Opportunity.
- **Referenced by:** public forms / Web-to-Lead mapping, lead conversion, supplementary updates, Salesforce UI, security or reporting, automated tests (16 project files)
- **Key references:** `assets/config.js`, `exhibitor-application.html`, `force-app/main/default/classes/NTEConversionFlowTest.cls`, `force-app/main/default/classes/NTEUpdateSubmissionService.cls`, `force-app/main/default/flexipages/NTE_Management_Lead_Record_Page.flexipage-meta.xml`, `force-app/main/default/flows/NTE_Copy_Converted_Lead_to_Opportunity.flow-meta.xml`, …
- **Production-package status:** Field metadata is included. Preserve its API name and definition, retain the documented conversion and permission references, and remap its Web-to-Lead ID in production.

### 7. Event Contact Name

- **Object and API name:** `Lead.Event_Contact_Name__c`
- **Field label:** Event Contact Name
- **Sandbox definition:** Text (length 200); required: No
- **Sandbox description:** No description is stored in the sandbox metadata.
- **Sandbox Web-to-Lead field ID:** `00NAd00000HZSVvMAP`
- **Conversion destination:** `Opportunity.NTE_Event_Contact_Name__c`
- **Function in this solution:** Stores the named operational event contact and supports updates, notifications and conversion.
- **Referenced by:** public forms / Web-to-Lead mapping, lead conversion, supplementary updates, email templates, Salesforce UI, security or reporting, automated tests (20 project files)
- **Key references:** `assets/config.js`, `email-templates/source/partner-sponsor-application-internal-notification.html`, `email-templates/source/partner-sponsor-application-received.html`, `exhibitor-application.html`, `force-app/main/default/classes/NTEConversionFlowTest.cls`, `force-app/main/default/classes/NTEUpdateSubmissionService.cls`, …
- **Production-package status:** Field metadata is included. Preserve its API name and definition, retain the documented conversion and permission references, and remap its Web-to-Lead ID in production.

### 8. Sunday Setup Availability

- **Object and API name:** `Lead.Exhibitor_Hall_Schedule__c`
- **Field label:** Sunday Setup Availability
- **Sandbox definition:** Picklist (restricted: true); required: No
- **Sandbox description:** No description is stored in the sandbox metadata.
- **Active values:** `Yes`, `No`
- **Sandbox Web-to-Lead field ID:** `00NAd00000HZSVwMAP`
- **Conversion destination:** `Opportunity.NTE_Exhibitor_Hall_Schedule__c`
- **Function in this solution:** Records whether the exhibitor can set up on Sunday and carries that operational answer into the booking.
- **Referenced by:** public forms / Web-to-Lead mapping, lead conversion, email templates, Salesforce UI, security or reporting, automated tests (14 project files)
- **Key references:** `assets/config.js`, `email-templates/source/exhibitor-application-internal-notification.html`, `exhibitor-application.html`, `force-app/main/default/classes/NTEConversionFlowTest.cls`, `force-app/main/default/flexipages/NTE_Management_Lead_Record_Page.flexipage-meta.xml`, `force-app/main/default/flows/NTE_Copy_Converted_Lead_to_Opportunity.flow-meta.xml`, …
- **Production-package status:** Field metadata is included. Preserve its API name and definition, retain the documented conversion and permission references, and remap its Web-to-Lead ID in production.

### 9. Exhibitor Organisation Category

- **Object and API name:** `Lead.Exhibitor_Organisation_Category__c`
- **Field label:** Exhibitor Organisation Category
- **Sandbox definition:** Picklist (restricted: true); required: No
- **Sandbox description:** Captured by the NTE27 exhibitor Web-to-Lead form.
- **Active values:** `Charity - member of Cobseo`, `Charity - not a member of Cobseo`, `Employer - Automotive Sector`, `Employer - Manufacturing Sector`, `Employer - Renewable & Clean Energy Sector`, `Employer - Defence`, `Employer - Built Environment`, `Employer - Facilities Management`, `Employer - Financial and Professional Services`, `Employer - Digital & Technologies`, `Employer - Training Provider from any industry`, `Employer - Landbased industry`, `Employer - Blue Light & NHS`, `Employer - Other Sectors not denoted above`, `Government or Government Agency`, `Local Government or LG related`, `Trade Association`, `CIC or Not for Profit`, `Regular or Reserve Services, or Cadets`
- **Current display labels:** COBSEO is capitalised, and stored value `Employer - Defence` is displayed as `Employer - Defence & Security`; the stored values remain unchanged for data compatibility.
- **Sandbox Web-to-Lead field ID:** `00NAd00000Ham1CMAR`
- **Conversion destination:** `Opportunity.NTE_Exhibitor_Organisation_Category__c`
- **Function in this solution:** Classifies the exhibitor organisation, including eligibility and pricing categories used by the pricing service.
- **Referenced by:** public forms / Web-to-Lead mapping, pricing automation, lead conversion, email templates, Salesforce UI, security or reporting, automated tests (17 project files)
- **Key references:** `assets/config.js`, `email-templates/source/exhibitor-application-applicant-confirmation.html`, `email-templates/source/exhibitor-application-internal-notification.html`, `exhibitor-application.html`, `force-app/main/default/classes/NTEConversionFlowTest.cls`, `force-app/main/default/classes/NTEPricingService.cls`, …
- **Production-package status:** Field metadata is included. Preserve its API name and definition, retain the documented conversion and permission references, and remap its Web-to-Lead ID in production.

### 10. Exhibitor Space Position

- **Object and API name:** `Lead.Exhibitor_Space_Position__c`
- **Field label:** Exhibitor Space Position
- **Sandbox definition:** LongTextArea (length 1000, 5 visible lines); required: No
- **Sandbox description:** No description is stored in the sandbox metadata.
- **Sandbox Web-to-Lead field ID:** `00NAd00000HZSVxMAP`
- **Conversion destination:** `Opportunity.NTE_Exhibitor_Space_Position__c`
- **Function in this solution:** Stores the requested stand position and carries it into operational planning on the Opportunity.
- **Referenced by:** public forms / Web-to-Lead mapping, lead conversion, Salesforce UI, security or reporting (7 project files)
- **Key references:** `assets/config.js`, `force-app/main/default/flexipages/NTE_Management_Lead_Record_Page.flexipage-meta.xml`, `force-app/main/default/flows/NTE_Copy_Converted_Lead_to_Opportunity.flow-meta.xml`, `force-app/main/default/permissionsets/NTE_Forms_Administration.permissionset-meta.xml`, `force-app/main/default/permissionsets/NTE_Management_User.permissionset-meta.xml`, …
- **Production-package status:** Field metadata is included. Preserve its API name and definition, retain the documented conversion and permission references, and remap its Web-to-Lead ID in production.

### 11. Exhibitor Space Selections

- **Object and API name:** `Lead.Exhibitor_Space_Selections__c`
- **Field label:** Exhibitor Space Selections
- **Sandbox definition:** MultiselectPicklist (8 visible lines, restricted: true); required: No
- **Sandbox description:** Captured by the NTE27 exhibitor Web-to-Lead form.
- **Active values:** `Garage Space - reduced size with power - £600 + VAT`, `Single Garage - Paddock Side with power - £800 + VAT`, `Double Garage - Paddock Side with power - £1,300 + VAT`, `Single Garage - Track Side - £800 + VAT`, `Double Garage - Track Side - £1,300 + VAT`, `Clean Energy Zone - Single - £499 + VAT`, `Clean Energy Zone - Double - £849 + VAT`, `Built Environment Zone - Single - £499 + VAT`, `Built Environment Zone - Double - £849 + VAT`, `Manufacturing Zone - Single - £499 + VAT`, `Manufacturing Zone - Double - £849 + VAT`, `Defence & Security Zone - Single - £499 + VAT`, `Defence & Security Zone - Double - £849 + VAT`, `Digital and Technologies Zone - Single - £499 + VAT`, `Digital and Technologies Zone - Double - £849 + VAT`, `FM Zone - Single - £499 + VAT`, `FM Zone - Double - £849 + VAT`, `Professional & Financial Zone - Single - £499 + VAT`, `Professional & Financial Zone - Double - £849 + VAT`, `Training & Education Zone - Single - £499 + VAT`, `Any other business - Single - £499 + VAT`, `Any other business - Double - £849 + VAT`, `Local Government Authority - Single - £249.50 + VAT`, `Blue Light - Single - £249.50 + VAT`, `Trade Association - Single - £499 + VAT`, `COBSEO Charity - Single - Free`, `Non COBSEO Charity - Single - Free`
- **Sandbox Web-to-Lead field ID:** `00NAd00000Ham1DMAR`
- **Conversion destination:** `Opportunity.NTE_Exhibitor_Space_Selections__c`
- **Function in this solution:** Stores the selected exhibitor space or garage options and is a primary input to price calculation and confirmations.
- **Referenced by:** public forms / Web-to-Lead mapping, pricing automation, lead conversion, email templates, Salesforce UI, security or reporting, automated tests (22 project files)
- **Key references:** `assets/config.js`, `email-templates/source/exhibitor-application-applicant-confirmation.html`, `email-templates/source/exhibitor-application-internal-notification.html`, `email-templates/source/exhibitor-approved-confirmation.html`, `email-templates/source/government-charity-approved-confirmation.html`, `exhibitor-application.html`, …
- **Production-package status:** Field metadata is included. Preserve its API name and definition, retain the documented conversion and permission references, and remap its Web-to-Lead ID in production.

### 12. Exhibitor Space Size

- **Object and API name:** `Lead.Exhibitor_Space_Size__c`
- **Field label:** Exhibitor Space Size
- **Sandbox definition:** Picklist (restricted: true); required: No
- **Sandbox description:** No description is stored in the sandbox metadata.
- **Active values:** `Headline Partner - size and position to be confirmed with sponsor`, `Gold Partner - size and position to be confirmed with sponsor`, `Premier Partner - double exhibitor space (two trestle tables length)`, `Champion Partner - standard exhibitor space (one trestle table length)`, `Zone Sponsor - double exhibitor space (two trestle tables length)`, `Troops' Track Day Partner - standard exhibitor space (one trestle table length)`, `Standard exhibitor space (one trestle table length) - suitable for Community Stage, Event Guide Sponsor, Delegate Tote Bag and Karting Activity sponsors)`
- **Sandbox Web-to-Lead field ID:** `00NAd00000HZSVyMAP`
- **Conversion destination:** `Opportunity.NTE_Exhibitor_Space_Size__c`
- **Function in this solution:** Stores the requested exhibitor space size for booking and operational planning.
- **Referenced by:** public forms / Web-to-Lead mapping, lead conversion, Salesforce UI, security or reporting (7 project files)
- **Key references:** `assets/config.js`, `force-app/main/default/flexipages/NTE_Management_Lead_Record_Page.flexipage-meta.xml`, `force-app/main/default/flows/NTE_Copy_Converted_Lead_to_Opportunity.flow-meta.xml`, `force-app/main/default/permissionsets/NTE_Forms_Administration.permissionset-meta.xml`, `force-app/main/default/permissionsets/NTE_Management_User.permissionset-meta.xml`, …
- **Production-package status:** Field metadata is included. Preserve its API name and definition, retain the documented conversion and permission references, and remap its Web-to-Lead ID in production.

### 13. Has Special Requirements

- **Object and API name:** `Lead.Has_Special_Requirements__c`
- **Field label:** Has Special Requirements
- **Sandbox definition:** Picklist (restricted: true); required: No
- **Sandbox description:** Captured by the NTE27 exhibitor Web-to-Lead form.
- **Active values:** `Yes`, `No`
- **Sandbox Web-to-Lead field ID:** `00NAd00000Ham1EMAR`
- **Conversion destination:** `Opportunity.NTE_Has_Special_Requirements__c`
- **Function in this solution:** Flags whether accessibility or other special arrangements are required so details can be reviewed and transferred.
- **Referenced by:** public forms / Web-to-Lead mapping, lead conversion, email templates, Salesforce UI, security or reporting, automated tests (16 project files)
- **Key references:** `assets/config.js`, `email-templates/source/exhibitor-application-applicant-confirmation.html`, `email-templates/source/exhibitor-application-internal-notification.html`, `exhibitor-application.html`, `force-app/main/default/classes/NTEConversionFlowTest.cls`, `force-app/main/default/flexipages/NTE_Management_Lead_Record_Page.flexipage-meta.xml`, …
- **Production-package status:** Field metadata is included. Preserve its API name and definition, retain the documented conversion and permission references, and remap its Web-to-Lead ID in production.

### 14. Industry Body / Trade Association

- **Object and API name:** `Lead.Industry_Body_Details__c`
- **Field label:** Industry Body / Trade Association
- **Sandbox definition:** Text (length 255); required: No
- **Sandbox description:** Captured by the NTE27 exhibitor Web-to-Lead form.
- **Sandbox Web-to-Lead field ID:** `00NAd00000Ham1FMAR`
- **Conversion destination:** `Opportunity.NTE_Industry_Body_Details__c`
- **Function in this solution:** Stores relevant trade association or industry body membership used when assessing and managing the application.
- **Referenced by:** public forms / Web-to-Lead mapping, lead conversion, Salesforce UI, security or reporting, automated tests (10 project files)
- **Key references:** `assets/config.js`, `exhibitor-application.html`, `force-app/main/default/classes/NTEConversionFlowTest.cls`, `force-app/main/default/flexipages/NTE_Management_Lead_Record_Page.flexipage-meta.xml`, `force-app/main/default/flows/NTE_Copy_Converted_Lead_to_Opportunity.flow-meta.xml`, `force-app/main/default/permissionsets/NTE_Forms_Administration.permissionset-meta.xml`, …
- **Production-package status:** Field metadata is included. Preserve its API name and definition, retain the documented conversion and permission references, and remap its Web-to-Lead ID in production.

### 15. Invoice Address

- **Object and API name:** `Lead.Invoice_Address__c`
- **Field label:** Invoice Address
- **Sandbox definition:** LongTextArea (length 1000, 5 visible lines); required: No
- **Sandbox description:** No description is stored in the sandbox metadata.
- **Sandbox Web-to-Lead field ID:** `00NAd00000HZSVzMAP`
- **Conversion destination:** `Opportunity.NTE_Invoice_Address__c`
- **Function in this solution:** Stores the billing address supplied in the finance section and copies it to the approved Opportunity.
- **Referenced by:** public forms / Web-to-Lead mapping, lead conversion, email templates, Salesforce UI, security or reporting (17 project files)
- **Key references:** `assets/config.js`, `email-templates/source/exhibitor-application-applicant-confirmation.html`, `email-templates/source/exhibitor-application-internal-notification.html`, `email-templates/source/partner-sponsor-application-received.html`, `exhibitor-application.html`, `force-app/main/default/flexipages/NTE_Management_Lead_Record_Page.flexipage-meta.xml`, …
- **Production-package status:** Field metadata is included. Preserve its API name and definition, retain the documented conversion and permission references, and remap its Web-to-Lead ID in production.

### 16. Invoice Contact Phone

- **Object and API name:** `Lead.Invoice_Contact_Phone__c`
- **Field label:** Invoice Contact Phone
- **Sandbox definition:** Phone; required: No
- **Sandbox description:** Captured by the NTE27 exhibitor Web-to-Lead form.
- **Sandbox Web-to-Lead field ID:** `00NAd00000Ham1GMAR`
- **Conversion destination:** `Opportunity.NTE_Invoice_Contact_Phone__c`
- **Function in this solution:** Stores the finance contact phone number for quotation and invoicing follow-up.
- **Referenced by:** public forms / Web-to-Lead mapping, lead conversion, email templates, Salesforce UI, security or reporting (18 project files)
- **Key references:** `assets/config.js`, `email-templates/source/exhibitor-application-applicant-confirmation.html`, `email-templates/source/exhibitor-application-internal-notification.html`, `email-templates/source/partner-sponsor-application-received.html`, `exhibitor-application.html`, `force-app/main/default/flexipages/NTE_Management_Lead_Record_Page.flexipage-meta.xml`, …
- **Production-package status:** Field metadata is included. Preserve its API name and definition, retain the documented conversion and permission references, and remap its Web-to-Lead ID in production.

### 17. Invoice Required

- **Object and API name:** `Lead.Invoice_Required__c`
- **Field label:** Invoice Required
- **Sandbox definition:** Picklist (restricted: true); required: No
- **Sandbox description:** No description is stored in the sandbox metadata.
- **Active values:** `Yes`, `No`
- **Sandbox Web-to-Lead field ID:** `00NAd00000HZSW0MAP`
- **Conversion destination:** `Opportunity.NTE_Invoice_Required__c`
- **Function in this solution:** Records whether an invoice is required and drives finance status, reports and conversion.
- **Referenced by:** public forms / Web-to-Lead mapping, pricing automation, lead conversion, email templates, Salesforce UI, security or reporting, automated tests (23 project files)
- **Key references:** `assets/config.js`, `email-templates/source/exhibitor-application-applicant-confirmation.html`, `email-templates/source/exhibitor-application-internal-notification.html`, `email-templates/source/partner-sponsor-application-received.html`, `email-templates/source/partner-sponsor-approved-confirmation.html`, `exhibitor-application.html`, …
- **Production-package status:** Field metadata is included. Preserve its API name and definition, retain the documented conversion and permission references, and remap its Web-to-Lead ID in production.

### 18. Invoiced Company

- **Object and API name:** `Lead.Invoiced_Company__c`
- **Field label:** Invoiced Company
- **Sandbox definition:** Text (length 200); required: No
- **Sandbox description:** No description is stored in the sandbox metadata.
- **Sandbox Web-to-Lead field ID:** `00NAd00000HZSW1MAP`
- **Conversion destination:** `Opportunity.NTE_Invoiced_Company__c`
- **Function in this solution:** Stores the legal customer name that should appear on the quotation or invoice.
- **Referenced by:** public forms / Web-to-Lead mapping, lead conversion, email templates, Salesforce UI, security or reporting (18 project files)
- **Key references:** `assets/config.js`, `email-templates/source/exhibitor-application-applicant-confirmation.html`, `email-templates/source/exhibitor-application-internal-notification.html`, `email-templates/source/partner-sponsor-application-received.html`, `exhibitor-application.html`, `force-app/main/default/flexipages/NTE_Management_Lead_Record_Page.flexipage-meta.xml`, …
- **Production-package status:** Field metadata is included. Preserve its API name and definition, retain the documented conversion and permission references, and remap its Web-to-Lead ID in production.

### 19. Invoiced Email

- **Object and API name:** `Lead.Invoiced_Email__c`
- **Field label:** Invoiced Email
- **Sandbox definition:** Email; required: No
- **Sandbox description:** No description is stored in the sandbox metadata.
- **Sandbox Web-to-Lead field ID:** `00NAd00000HZSW2MAP`
- **Conversion destination:** `Opportunity.NTE_Invoiced_Email__c`
- **Function in this solution:** Stores the accounts-payable email address used for finance correspondence.
- **Referenced by:** public forms / Web-to-Lead mapping, lead conversion, email templates, Salesforce UI, security or reporting (17 project files)
- **Key references:** `assets/config.js`, `email-templates/source/exhibitor-application-applicant-confirmation.html`, `email-templates/source/exhibitor-application-internal-notification.html`, `email-templates/source/partner-sponsor-application-received.html`, `exhibitor-application.html`, `force-app/main/default/flexipages/NTE_Management_Lead_Record_Page.flexipage-meta.xml`, …
- **Production-package status:** Field metadata is included. Preserve its API name and definition, retain the documented conversion and permission references, and remap its Web-to-Lead ID in production.

### 20. Invoiced Person

- **Object and API name:** `Lead.Invoiced_Person__c`
- **Field label:** Invoiced Person
- **Sandbox definition:** Text (length 200); required: No
- **Sandbox description:** No description is stored in the sandbox metadata.
- **Sandbox Web-to-Lead field ID:** `00NAd00000HZSW3MAP`
- **Conversion destination:** `Opportunity.NTE_Invoiced_Person__c`
- **Function in this solution:** Stores the named finance contact responsible for the transaction.
- **Referenced by:** public forms / Web-to-Lead mapping, lead conversion, email templates, Salesforce UI, security or reporting (17 project files)
- **Key references:** `assets/config.js`, `email-templates/source/exhibitor-application-applicant-confirmation.html`, `email-templates/source/exhibitor-application-internal-notification.html`, `email-templates/source/partner-sponsor-application-received.html`, `exhibitor-application.html`, `force-app/main/default/flexipages/NTE_Management_Lead_Record_Page.flexipage-meta.xml`, …
- **Production-package status:** Field metadata is included. Preserve its API name and definition, retain the documented conversion and permission references, and remap its Web-to-Lead ID in production.

### 21. Planned Exhibitor Count

- **Object and API name:** `Lead.Planned_Exhibitor_Count__c`
- **Field label:** Planned Exhibitor Count
- **Sandbox definition:** Picklist (restricted: true); required: No
- **Sandbox description:** Captured by the NTE27 exhibitor Web-to-Lead form.
- **Active values:** Every whole number from `1` through `99`
- **Sandbox Web-to-Lead field ID:** `00NAd00000Ham1HMAR`
- **Conversion destination:** `Opportunity.NTE_Planned_Exhibitor_Count__c`
- **Function in this solution:** Stores the number of people initially planned for the booking; it is an input to the exhibitor's included/additional-staff calculation and remains separate from the final staff names supplied later.
- **Referenced by:** public forms / Web-to-Lead mapping, lead conversion, supplementary updates, email templates, Salesforce UI, security or reporting, automated tests (19 project files)
- **Key references:** `assets/config.js`, `email-templates/source/exhibitor-application-applicant-confirmation.html`, `email-templates/source/exhibitor-application-internal-notification.html`, `email-templates/source/exhibitor-staff-update-applicant-confirmation.html`, `exhibitor-application.html`, `force-app/main/default/classes/NTEUpdateSubmissionService.cls`, …
- **Production-package status:** Field metadata is included. Preserve its API name and definition, retain the documented conversion and permission references, and remap its Web-to-Lead ID in production.

### 22. Previous NTE Events

- **Object and API name:** `Lead.Previous_NTE_Events__c`
- **Field label:** Previous NTE Events
- **Sandbox definition:** MultiselectPicklist (4 visible lines, restricted: true); required: No
- **Sandbox description:** Captured by the NTE27 exhibitor Web-to-Lead form.
- **Active values:** `No`, `NTE2024`, `NTE2025`, `NTE2026`
- **Current display labels:** `NTE2024`, `NTE2025` and `NTE2026` display as `NTE24`, `NTE25` and `NTE26`; stored values remain unchanged for existing data.
- **Sandbox Web-to-Lead field ID:** `00NAd00000Ham1IMAR`
- **Conversion destination:** `Opportunity.NTE_Previous_Events__c`
- **Function in this solution:** Stores the previous NTE events attended for application review, reporting and conversion.
- **Referenced by:** public forms / Web-to-Lead mapping, lead conversion, email templates, Salesforce UI, security or reporting (14 project files)
- **Key references:** `assets/config.js`, `email-templates/source/exhibitor-application-internal-notification.html`, `exhibitor-application.html`, `exhibitor-interest.html`, `force-app/main/default/flexipages/NTE_Management_Lead_Record_Page.flexipage-meta.xml`, `force-app/main/default/flows/NTE_Copy_Converted_Lead_to_Opportunity.flow-meta.xml`, …
- **Production-package status:** Field metadata is included. Preserve its API name and definition, retain the documented conversion and permission references, and remap its Web-to-Lead ID in production.

### 23. Purchase Order

- **Object and API name:** `Lead.Purchase_Order__c`
- **Field label:** Purchase Order
- **Sandbox definition:** Picklist (restricted: true); required: No
- **Sandbox description:** No description is stored in the sandbox metadata.
- **Active values:** `Yes`, `No`
- **Sandbox Web-to-Lead field ID:** `00NAd00000HZSW4MAP`
- **Conversion destination:** `Opportunity.NTE_Purchase_Order__c`
- **Function in this solution:** Records whether the customer's organisation requires a purchase order.
- **Referenced by:** public forms / Web-to-Lead mapping, lead conversion, email templates, Salesforce UI, security or reporting (17 project files)
- **Key references:** `assets/config.js`, `email-templates/source/exhibitor-application-applicant-confirmation.html`, `email-templates/source/exhibitor-application-internal-notification.html`, `email-templates/source/partner-sponsor-application-received.html`, `exhibitor-application.html`, `force-app/main/default/flexipages/NTE_Management_Lead_Record_Page.flexipage-meta.xml`, …
- **Production-package status:** Field metadata is included. Preserve its API name and definition, retain the documented conversion and permission references, and remap its Web-to-Lead ID in production.

### 24. Purchase Order Number

- **Object and API name:** `Lead.Purchase_Order_Number__c`
- **Field label:** Purchase Order Number
- **Sandbox definition:** Text (length 100); required: No
- **Sandbox description:** Captured by the NTE27 exhibitor Web-to-Lead form.
- **Sandbox Web-to-Lead field ID:** `00NAd00000Ham1JMAR`
- **Conversion destination:** `Opportunity.NTE_Purchase_Order_Number__c`
- **Function in this solution:** Stores the customer purchase-order number where one has already been issued.
- **Referenced by:** public forms / Web-to-Lead mapping, lead conversion, email templates, Salesforce UI, security or reporting (18 project files)
- **Key references:** `assets/config.js`, `email-templates/source/exhibitor-application-applicant-confirmation.html`, `email-templates/source/exhibitor-application-internal-notification.html`, `email-templates/source/partner-sponsor-application-received.html`, `exhibitor-application.html`, `force-app/main/default/flexipages/NTE_Management_Lead_Record_Page.flexipage-meta.xml`, …
- **Production-package status:** Field metadata is included. Preserve its API name and definition, retain the documented conversion and permission references, and remap its Web-to-Lead ID in production.

### 25. Secondary Contact Email

- **Object and API name:** `Lead.Secondary_Contact_Email__c`
- **Field label:** Secondary Contact Email
- **Sandbox definition:** Email; required: No
- **Sandbox description:** Captured by the NTE27 exhibitor Web-to-Lead form.
- **Sandbox Web-to-Lead field ID:** `00NAd00000Ham1KMAR`
- **Conversion destination:** `Opportunity.NTE_Secondary_Contact_Email__c`
- **Function in this solution:** Stores the secondary event contact email used in notifications, operational follow-up and update matching.
- **Referenced by:** public forms / Web-to-Lead mapping, lead conversion, supplementary updates, email templates, Salesforce UI, security or reporting, automated tests (16 project files)
- **Key references:** `assets/config.js`, `email-templates/source/exhibitor-application-internal-notification.html`, `exhibitor-application.html`, `force-app/main/default/classes/NTEConversionFlowTest.cls`, `force-app/main/default/classes/NTEUpdateSubmissionService.cls`, `force-app/main/default/classes/NTEUpdateSubmissionServiceTest.cls`, …
- **Production-package status:** Field metadata is included. Preserve its API name and definition, retain the documented conversion and permission references, and remap its Web-to-Lead ID in production.

### 26. Secondary Contact Mobile

- **Object and API name:** `Lead.Secondary_Contact_Mobile__c`
- **Field label:** Secondary Contact Mobile
- **Sandbox definition:** Phone; required: No
- **Sandbox description:** Captured by the NTE27 exhibitor Web-to-Lead form.
- **Sandbox Web-to-Lead field ID:** `00NAd00000Ham1LMAR`
- **Conversion destination:** `Opportunity.NTE_Secondary_Contact_Mobile__c`
- **Function in this solution:** Stores the secondary event contact mobile number.
- **Referenced by:** public forms / Web-to-Lead mapping, lead conversion, supplementary updates, Salesforce UI, security or reporting, automated tests (11 project files)
- **Key references:** `assets/config.js`, `exhibitor-application.html`, `force-app/main/default/classes/NTEConversionFlowTest.cls`, `force-app/main/default/classes/NTEUpdateSubmissionService.cls`, `force-app/main/default/flexipages/NTE_Management_Lead_Record_Page.flexipage-meta.xml`, `force-app/main/default/flows/NTE_Copy_Converted_Lead_to_Opportunity.flow-meta.xml`, …
- **Production-package status:** Field metadata is included. Preserve its API name and definition, retain the documented conversion and permission references, and remap its Web-to-Lead ID in production.

### 27. Secondary Contact Full Name

- **Object and API name:** `Lead.Secondary_Contact_Name__c`
- **Field label:** Secondary Contact Full Name
- **Sandbox definition:** Text (length 200); required: No
- **Sandbox description:** Captured by the NTE27 exhibitor Web-to-Lead form.
- **Sandbox Web-to-Lead field ID:** `00NAd00000Ham1MMAR`
- **Conversion destination:** `Opportunity.NTE_Secondary_Contact_Name__c`
- **Function in this solution:** Stores the secondary operational contact name.
- **Referenced by:** public forms / Web-to-Lead mapping, lead conversion, supplementary updates, email templates, Salesforce UI, security or reporting, automated tests (16 project files)
- **Key references:** `assets/config.js`, `email-templates/source/exhibitor-application-internal-notification.html`, `exhibitor-application.html`, `force-app/main/default/classes/NTEConversionFlowTest.cls`, `force-app/main/default/classes/NTEUpdateSubmissionService.cls`, `force-app/main/default/classes/NTEUpdateSubmissionServiceTest.cls`, …
- **Production-package status:** Field metadata is included. Preserve its API name and definition, retain the documented conversion and permission references, and remap its Web-to-Lead ID in production.

### 28. Secondary Contact Work Phone

- **Object and API name:** `Lead.Secondary_Contact_Phone__c`
- **Field label:** Secondary Contact Work Phone
- **Sandbox definition:** Phone; required: No
- **Sandbox description:** Captured by the NTE27 exhibitor Web-to-Lead form.
- **Sandbox Web-to-Lead field ID:** `00NAd00000Ham1NMAR`
- **Conversion destination:** `Opportunity.NTE_Secondary_Contact_Phone__c`
- **Function in this solution:** Stores the secondary operational contact telephone number.
- **Referenced by:** public forms / Web-to-Lead mapping, lead conversion, supplementary updates, Salesforce UI, security or reporting, automated tests (14 project files)
- **Key references:** `assets/config.js`, `exhibitor-application.html`, `force-app/main/default/classes/NTEConversionFlowTest.cls`, `force-app/main/default/classes/NTEUpdateSubmissionService.cls`, `force-app/main/default/classes/NTEUpdateSubmissionServiceTest.cls`, `force-app/main/default/flexipages/NTE_Management_Lead_Record_Page.flexipage-meta.xml`, …
- **Production-package status:** Field metadata is included. Preserve its API name and definition, retain the documented conversion and permission references, and remap its Web-to-Lead ID in production.

### 29. Secondary Contact Prefix

- **Object and API name:** `Lead.Secondary_Contact_Prefix__c`
- **Field label:** Secondary Contact Prefix
- **Sandbox definition:** Text (length 40); required: No
- **Sandbox description:** Captured by the NTE27 exhibitor Web-to-Lead form.
- **Sandbox Web-to-Lead field ID:** `00NAd00000Ham1OMAR`
- **Conversion destination:** `Opportunity.NTE_Secondary_Contact_Prefix__c`
- **Function in this solution:** Stores the secondary contact's title or prefix.
- **Referenced by:** public forms / Web-to-Lead mapping, lead conversion, supplementary updates, Salesforce UI, security or reporting, automated tests (11 project files)
- **Key references:** `assets/config.js`, `exhibitor-application.html`, `force-app/main/default/classes/NTEConversionFlowTest.cls`, `force-app/main/default/classes/NTEUpdateSubmissionService.cls`, `force-app/main/default/flexipages/NTE_Management_Lead_Record_Page.flexipage-meta.xml`, `force-app/main/default/flows/NTE_Copy_Converted_Lead_to_Opportunity.flow-meta.xml`, …
- **Production-package status:** Field metadata is included. Preserve its API name and definition, retain the documented conversion and permission references, and remap its Web-to-Lead ID in production.

### 30. Secondary Contact Job Title

- **Object and API name:** `Lead.Secondary_Contact_Title__c`
- **Field label:** Secondary Contact Job Title
- **Sandbox definition:** Text (length 128); required: No
- **Sandbox description:** Captured by the NTE27 exhibitor Web-to-Lead form.
- **Sandbox Web-to-Lead field ID:** `00NAd00000Ham1PMAR`
- **Conversion destination:** `Opportunity.NTE_Secondary_Contact_Title__c`
- **Function in this solution:** Stores the secondary contact's job title.
- **Referenced by:** public forms / Web-to-Lead mapping, lead conversion, supplementary updates, Salesforce UI, security or reporting, automated tests (11 project files)
- **Key references:** `assets/config.js`, `exhibitor-application.html`, `force-app/main/default/classes/NTEConversionFlowTest.cls`, `force-app/main/default/classes/NTEUpdateSubmissionService.cls`, `force-app/main/default/flexipages/NTE_Management_Lead_Record_Page.flexipage-meta.xml`, `force-app/main/default/flows/NTE_Copy_Converted_Lead_to_Opportunity.flow-meta.xml`, …
- **Production-package status:** Field metadata is included. Preserve its API name and definition, retain the documented conversion and permission references, and remap its Web-to-Lead ID in production.

### 31. Sponsored Name

- **Object and API name:** `Lead.Sponsored_Name__c`
- **Field label:** Sponsored Name
- **Sandbox definition:** Text (length 200); required: No
- **Sandbox description:** Name of person applying for sponsorship.
- **Sandbox Web-to-Lead field ID:** `00NAd00000HZSW6MAP`
- **Conversion destination:** `Opportunity.NTE_Sponsored_Name__c`
- **Function in this solution:** Stores the organisation or activity name to be presented in NTE sponsorship material and booking records.
- **Referenced by:** public forms / Web-to-Lead mapping, lead conversion, Salesforce UI, security or reporting (9 project files)
- **Key references:** `assets/config.js`, `force-app/main/default/flexipages/NTE_Management_Lead_Record_Page.flexipage-meta.xml`, `force-app/main/default/flows/NTE_Copy_Converted_Lead_to_Opportunity.flow-meta.xml`, `force-app/main/default/permissionsets/NTE_Forms_Administration.permissionset-meta.xml`, `force-app/main/default/permissionsets/NTE_Management_User.permissionset-meta.xml`, …
- **Production-package status:** Field metadata is included. Preserve its API name and definition, retain the documented conversion and permission references, and remap its Web-to-Lead ID in production.

### 32. Stand Colleagues

- **Object and API name:** `Lead.Stand_Colleagues__c`
- **Field label:** Stand Colleagues
- **Sandbox definition:** LongTextArea (length 1000, 5 visible lines); required: No
- **Sandbox description:** No description is stored in the sandbox metadata.
- **Sandbox Web-to-Lead field ID:** `00NAd00000HZSW7MAP`
- **Conversion destination:** `Opportunity.NTE_Stand_Colleagues__c`
- **Function in this solution:** Stores the complete stand-attendee list and is replaced by successful staff update submissions.
- **Referenced by:** public forms / Web-to-Lead mapping, lead conversion, supplementary updates, email templates, Salesforce UI, security or reporting, automated tests (26 project files)
- **Key references:** `assets/config.js`, `email-templates/source/exhibitor-application-applicant-confirmation.html`, `email-templates/source/exhibitor-application-internal-notification.html`, `email-templates/source/exhibitor-staff-update-applicant-confirmation.html`, `email-templates/source/partner-sponsor-application-received.html`, `email-templates/source/partner-sponsor-approved-confirmation.html`, …
- **Production-package status:** Field metadata is included. Preserve its API name and definition, retain the documented conversion and permission references, and remap its Web-to-Lead ID in production.

### 33. Stand Equipment

- **Object and API name:** `Lead.Stand_Equipment__c`
- **Field label:** Stand Equipment
- **Sandbox definition:** LongTextArea (length 1000, 5 visible lines); required: No
- **Sandbox description:** No description is stored in the sandbox metadata.
- **Sandbox Web-to-Lead field ID:** `00NAd00000HZSW8MAP`
- **Conversion destination:** `Opportunity.NTE_Stand_Equipment__c`
- **Function in this solution:** Stores equipment requirements beyond standard display stands and laptops for operational planning.
- **Referenced by:** public forms / Web-to-Lead mapping, lead conversion, email templates, Salesforce UI, security or reporting (17 project files)
- **Key references:** `assets/config.js`, `email-templates/source/exhibitor-application-applicant-confirmation.html`, `email-templates/source/exhibitor-application-internal-notification.html`, `email-templates/source/partner-sponsor-application-received.html`, `exhibitor-application.html`, `force-app/main/default/flexipages/NTE_Management_Lead_Record_Page.flexipage-meta.xml`, …
- **Production-package status:** Field metadata is included. Preserve its API name and definition, retain the documented conversion and permission references, and remap its Web-to-Lead ID in production.

### 34. Stand Extra Notes

- **Object and API name:** `Lead.Stand_Extra_Notes__c`
- **Field label:** Stand Extra Notes
- **Sandbox definition:** LongTextArea (length 1000, 5 visible lines); required: No
- **Sandbox description:** No description is stored in the sandbox metadata.
- **Sandbox Web-to-Lead field ID:** `00NAd00000HZSW9MAP`
- **Conversion destination:** `Opportunity.NTE_Stand_Extra_Notes__c`
- **Function in this solution:** Stores additional information about the requested stand or space.
- **Referenced by:** public forms / Web-to-Lead mapping, lead conversion, Salesforce UI, security or reporting (9 project files)
- **Key references:** `assets/config.js`, `force-app/main/default/flexipages/NTE_Management_Lead_Record_Page.flexipage-meta.xml`, `force-app/main/default/flows/NTE_Copy_Converted_Lead_to_Opportunity.flow-meta.xml`, `force-app/main/default/permissionsets/NTE_Forms_Administration.permissionset-meta.xml`, `force-app/main/default/permissionsets/NTE_Management_User.permissionset-meta.xml`, …
- **Production-package status:** Field metadata is included. Preserve its API name and definition, retain the documented conversion and permission references, and remap its Web-to-Lead ID in production.

### 35. Stand Power

- **Object and API name:** `Lead.Stand_Power__c`
- **Field label:** Stand Power
- **Sandbox definition:** Picklist (restricted: true); required: No
- **Sandbox description:** No description is stored in the sandbox metadata.
- **Active values:** `Yes`, `No`
- **Sandbox Web-to-Lead field ID:** `00NAd00000HZSWAMA5`
- **Conversion destination:** `Opportunity.NTE_Stand_Power__c`
- **Function in this solution:** Records the stand power requirement and supports socket pricing, logistics and confirmations.
- **Referenced by:** public forms / Web-to-Lead mapping, pricing automation, lead conversion, email templates, Salesforce UI, security or reporting, automated tests (26 project files)
- **Key references:** `assets/config.js`, `email-templates/source/exhibitor-application-applicant-confirmation.html`, `email-templates/source/exhibitor-application-internal-notification.html`, `email-templates/source/exhibitor-approved-confirmation.html`, `email-templates/source/government-charity-approved-confirmation.html`, `email-templates/source/partner-sponsor-application-received.html`, …
- **Production-package status:** Field metadata is included. Preserve its API name and definition, retain the documented conversion and permission references, and remap its Web-to-Lead ID in production.

### 36. Stand Special Requirements

- **Object and API name:** `Lead.Stand_Special_Requirements__c`
- **Field label:** Stand Special Requirements
- **Sandbox definition:** LongTextArea (length 1000, 5 visible lines); required: No
- **Sandbox description:** No description is stored in the sandbox metadata.
- **Sandbox Web-to-Lead field ID:** `00NAd00000HZSWBMA5`
- **Conversion destination:** `Opportunity.NTE_Stand_Special_Requirements__c`
- **Function in this solution:** Stores the detailed accessibility or special-arrangement requirements for delivery planning.
- **Referenced by:** public forms / Web-to-Lead mapping, lead conversion, email templates, Salesforce UI, security or reporting (15 project files)
- **Key references:** `assets/config.js`, `email-templates/source/exhibitor-application-applicant-confirmation.html`, `email-templates/source/exhibitor-application-internal-notification.html`, `exhibitor-application.html`, `force-app/main/default/flexipages/NTE_Management_Lead_Record_Page.flexipage-meta.xml`, `force-app/main/default/flows/NTE_Copy_Converted_Lead_to_Opportunity.flow-meta.xml`, …
- **Production-package status:** Field metadata is included. Preserve its API name and definition, retain the documented conversion and permission references, and remap its Web-to-Lead ID in production.

### 37. Supplier Agreement Required

- **Object and API name:** `Lead.Supplier_Agreement_Required__c`
- **Field label:** Supplier Agreement Required
- **Sandbox definition:** Picklist (restricted: true); required: No
- **Sandbox description:** Captured by the NTE27 exhibitor Web-to-Lead form.
- **Active values:** `Yes`, `No`, `Don't know`
- **Sandbox Web-to-Lead field ID:** `00NAd00000Ham1QMAR`
- **Conversion destination:** `Opportunity.NTE_Supplier_Agreement_Required__c`
- **Function in this solution:** Records whether the customer requires a supplier agreement as part of procurement.
- **Referenced by:** public forms / Web-to-Lead mapping, lead conversion, email templates, Salesforce UI, security or reporting (18 project files)
- **Key references:** `assets/config.js`, `email-templates/source/exhibitor-application-applicant-confirmation.html`, `email-templates/source/exhibitor-application-internal-notification.html`, `email-templates/source/partner-sponsor-application-received.html`, `exhibitor-application.html`, `force-app/main/default/flexipages/NTE_Management_Lead_Record_Page.flexipage-meta.xml`, …
- **Production-package status:** Field metadata is included. Preserve its API name and definition, retain the documented conversion and permission references, and remap its Web-to-Lead ID in production.

### 38. Terms and Conditions

- **Object and API name:** `Lead.Terms_and_Conditions__c`
- **Field label:** Terms and Conditions
- **Sandbox definition:** Checkbox; required: No
- **Sandbox description:** No description is stored in the sandbox metadata.
- **Sandbox Web-to-Lead field ID:** `00NAd00000HZSWCMA5`
- **Conversion destination:** `Opportunity.NTE_Terms_Accepted__c`
- **Function in this solution:** Stores acceptance of the application terms and is copied to the Opportunity declaration record.
- **Referenced by:** public forms / Web-to-Lead mapping, lead conversion, Salesforce UI, security or reporting, automated tests (14 project files)
- **Key references:** `assets/config.js`, `assets/forms.js`, `exhibitor-application.html`, `force-app/main/default/classes/NTEConversionFlowTest.cls`, `force-app/main/default/flexipages/NTE_Management_Lead_Record_Page.flexipage-meta.xml`, `force-app/main/default/flows/NTE_Copy_Converted_Lead_to_Opportunity.flow-meta.xml`, …
- **Production-package status:** Field metadata is included. Preserve its API name and definition, retain the documented conversion and permission references, and remap its Web-to-Lead ID in production.

## Shared volunteer field inventory

These eight fields were also inherited from MMUAT and are required by the separately permissioned volunteer journey included in the complete production manifest.

| API name | Label | Definition | MMUAT Web-to-Lead ID | Function and dependencies |
| --- | --- | --- | --- | --- |
| `Lead.Consent_Contact__c` | Consent Contact | Checkbox, default false | `00NAd00000GpQiP` | Records permission to contact the volunteer; used by the volunteer form, permission set and retained Lead record. |
| `Lead.Consent_PII__c` | Consent PII | Checkbox, default false | `00NAd00000GpQYj` | Records the privacy consent submitted with the volunteer application. |
| `Lead.Consent_Promotion__c` | Consent Promotion | Checkbox, default false | `00NAd00000GpQwv` | Preserves the existing promotional-contact consent field used by the volunteer submission. |
| `Lead.Date_of_Birth__c` | Date of Birth | Date, optional in Salesforce | `00NAd00000Ecobd` | Captures the applicant's date of birth; the public volunteer form requires it. |
| `Lead.Interested_in_Volunteering__c` | Volunteering | Checkbox, default false | `00NAd00000Ecqbq` | Identifies a Lead as interested in volunteering and preserves compatibility with existing volunteer data. |
| `Lead.NOK_Name__c` | Next of Kin Name | Text(100) | `00NAd00000GpMy9` | Stores the volunteer's emergency-contact name. |
| `Lead.NOK_Phone__c` | Next of Kin Phone | Phone | `00NAd00000GpOwj` | Stores the volunteer's emergency-contact telephone number. |
| `Lead.NOK_Relationship__c` | Relationship to Next of Kin | Text(255) | `00NAd00000GpOyL` | Stores the applicant's relationship to the named emergency contact. |

All eight have field-level access in `Volunteer_Applications_User`. They do not map to NTE Opportunities and must remain outside NTE pipeline and finance metrics.

## Audit method and limitations

- The original audit compared a Metadata API snapshot from MMUAT with the then-current local field metadata and confirmed that each missing API name was referenced by the source project.
- The refreshed audit verifies that every inherited field now exists locally and is enumerated in the complete production manifest.
- Standard Salesforce fields are not listed because they do not need custom-field metadata in this package.
- Fields that exist in the sandbox but are not referenced by this project are deliberately excluded.
- This inventory is dependency documentation, not authority to copy unrelated coworker metadata into production.
