# Configuration and workspace reference

These definitions complete the reconstruction specification around the runtime services. Exact lists are retained where order or filters affect the user experience. Source paths identify the matching deployable metadata in the archive.

## Pricing policy

Source: config/nte-pricing.json. Version NTE27-2026-09-13-VAT, vatRate=20. scripts/build-vat.js generates the authoritative NTEVat rate and browser rate/version. Package and item prices stay net; VAT is calculated once on the discounted charge subtotal. This rate is also used by the generated Stripe default configuration. Production credentials and merchant identity remain environment-specific.

## Runtime configuration records

### NTE Routing Config

Source: force-app/main/default/customMetadata/NTE_Routing_Config.Default.md-meta.xml.


| Setting | Value |
| --- | --- |
| label | Default |
| protected | false |
| values | field=Owner_Username__c; value=steven.skyba@euroforce.com.mmuat; field=Heavy_Vehicle_Form_URL__c; value=https://stevostar1234.github.io/nte27-web-to-lead-demo/heavy-vehicle-details.html; field=Exhibitor_Staff_Form_URL__c; value=https://stevostar1234.github.io/nte27-web-to-lead-demo/exhibitor-staff-update.html; field=Partner_Staff_Form_URL__c; value=https://stevostar1234.github.io/nte27-web-to-lead-demo/partner-sponsor-staff-update.html; field=Logo_Update_Form_URL__c; value=https://stevostar1234.github.io/nte27-web-to-lead-demo/logo-upload.html; field=Application_Event_Code__c; value=NTE2027; field=Exhibitor_Application_URL__c; value=https://stevostar1234.github.io/nte27-web-to-lead-demo/exhibitor-application.html; field=Partner_Application_URL__c; value=https://stevostar1234.github.io/nte27-web-to-lead-demo/partner-sponsor-application.html; field=Exhibitor_Final_Pack_URL__c; value=; field=Partner_Final_Pack_URL__c; value= |



### NTE Stripe Config

Source: force-app/main/default/customMetadata/NTE_Stripe_Config.Default.md-meta.xml.


| Setting | Value |
| --- | --- |
| label | Default |
| protected | false |
| values | field=Enabled__c; value=true; field=Expected_Account_Id__c; value=acct_1UD8GwBcW1MkMYQ1; field=Expected_Org_Id__c; value=00DAd00000A95VlMAJ; field=Reference_Prefix__c; value=; field=Allowed_Email__c; value=; field=Tax_Rate__c; value=20; field=Live_Mode__c; value=false |



## Named credentials

### NTE Stripe Live

Source: force-app/main/default/namedCredentials/NTE_Stripe_Live.namedCredential-meta.xml.


| Setting | Value |
| --- | --- |
| allowMergeFieldsInBody | false |
| allowMergeFieldsInHeader | true |
| calloutStatus | Enabled |
| generateAuthorizationHeader | false |
| label | NTE Stripe Live |
| namedCredentialParameters | parameterName=Url; parameterType=Url; parameterValue=https://api.stripe.com; externalCredential=NTE_Stripe_Live; parameterName=ExternalCredential; parameterType=Authentication |
| namedCredentialType | SecuredEndpoint |



### NTE Stripe Test

Source: force-app/main/default/namedCredentials/NTE_Stripe_Test.namedCredential-meta.xml.


| Setting | Value |
| --- | --- |
| allowMergeFieldsInBody | false |
| allowMergeFieldsInHeader | true |
| calloutStatus | Enabled |
| generateAuthorizationHeader | false |
| label | NTE Stripe Test |
| namedCredentialParameters | parameterName=Url; parameterType=Url; parameterValue=https://api.stripe.com; externalCredential=NTE_Stripe_Test; parameterName=ExternalCredential; parameterType=Authentication |
| namedCredentialType | SecuredEndpoint |



## External credentials

### NTE Stripe Live

Source: force-app/main/default/externalCredentials/NTE_Stripe_Live.externalCredential-meta.xml.


| Setting | Value |
| --- | --- |
| authenticationProtocol | Custom |
| description | Stripe live account. Populate the ApiKey authentication parameter securely on the NTEApplication principal. |
| externalCredentialParameters | parameterName=NTEApplication; parameterType=NamedPrincipal; sequenceNumber=1; parameterName=Authorization; parameterType=AuthHeader; parameterValue={!'Bearer ' & $Credential.NTE_Stripe_Live.ApiKey}; sequenceNumber=1 |
| label | NTE Stripe Live |



### NTE Stripe Test

Source: force-app/main/default/externalCredentials/NTE_Stripe_Test.externalCredential-meta.xml.


| Setting | Value |
| --- | --- |
| authenticationProtocol | Custom |
| description | Stripe test account. Populate the ApiKey authentication parameter securely on the NTEApplication principal. |
| externalCredentialParameters | parameterName=NTEApplication; parameterType=NamedPrincipal; sequenceNumber=1; parameterName=Authorization; parameterType=AuthHeader; parameterValue={!'Bearer ' & $Credential.NTE_Stripe_Test.ApiKey}; sequenceNumber=1 |
| label | NTE Stripe Test |



## Permission set group

### NTE Management Access

Source: force-app/main/default/permissionsetgroups/NTE_Management_Access.permissionsetgroup-meta.xml.


| Setting | Value |
| --- | --- |
| description | Assign to administrators and authorised staff who manage NTE enquiries, applications, bookings, communications and payments. Uses the configured NTE Stripe test connection. |
| hasActivationRequired | false |
| label | NTE Management Access |
| permissionSets | NTE_Management_User; NTE_Stripe_Test_Operator |
| status | Updated |



## Permission sets

### NTE Forms Administration

Source: force-app/main/default/permissionsets/NTE_Forms_Administration.permissionset-meta.xml.

The complete custom field grants appear beside every field in the data dictionary.


| Setting | Value |
| --- | --- |
| applicationVisibilities | application=NTE_Management; visible=true |
| description | Manage NTE forms, bookings and finance. |
| classAccesses | apexClass=NTE_MasterPanelController; enabled=true; apexClass=NTEExhibitorApprovalEmailService; enabled=true; apexClass=NTERelatedOpportunityController; enabled=true; apexClass=NTEEmailDispatchService; enabled=true; apexClass=NTEUpdateSubmissionService; enabled=true |
| recordTypeVisibilities | recordType=Opportunity.NTE_Event_Opportunity; visible=true |
| userPermissions | enabled=true; name=EditTask; enabled=true; name=ConvertLeads; enabled=true; name=RunReports |
| hasActivationRequired | false |
| label | NTE Forms Administration |
| objectPermissions | allowCreate=true; allowDelete=false; allowEdit=true; allowRead=true; modifyAllRecords=false; object=Lead; viewAllFields=false; viewAllRecords=false; allowCreate=true; allowDelete=false; allowEdit=true; allowRead=true; modifyAllRecords=false; object=Account; viewAllFields=false; viewAllRecords=false; allowCreate=true; allowDelete=false; allowEdit=true; allowRead=true; modifyAllRecords=false; object=Contact; viewAllFields=false; viewAllRecords=false; allowCreate=true; allowDelete=false; allowEdit=true; allowRead=true; modifyAllRecords=false; object=Opportunity; viewAllFields=false; viewAllRecords=false; allowCreate=true; allowDelete=false; allowEdit=true; allowRead=true; modifyAllRecords=false; object=Task; viewAllFields=false; viewAllRecords=false; allowCreate=true; allowDelete=false; allowEdit=true; allowRead=true; modifyAllRecords=false; object=Event; viewAllFields=false; viewAllRecords=false; allowCreate=true; allowDelete=false; allowEdit=true; allowRead=true; modifyAllRecords=false; object=NTE_Email_Dispatch__c; viewAllRecords=false; allowCreate=false; allowDelete=false; allowEdit=false; allowRead=true; modifyAllRecords=false; object=NTE_Payment_Request__c; viewAllRecords=false |



### NTE Management User

Source: force-app/main/default/permissionsets/NTE_Management_User.permissionset-meta.xml.

The complete custom field grants appear beside every field in the data dictionary.


| Setting | Value |
| --- | --- |
| applicationVisibilities | application=NTE_Management; visible=true |
| description | Access the NTE Management app, its navigation, NTE event records, conversion actions and reports. Sharing continues to control which records are visible. |
| classAccesses | apexClass=NTEExhibitorApprovalEmailService; enabled=true; apexClass=NTE_MasterPanelController; enabled=true; apexClass=NTERelatedOpportunityController; enabled=true; apexClass=NTEEmailDispatchService; enabled=true; apexClass=NTEUpdateSubmissionService; enabled=true |
| recordTypeVisibilities | recordType=Opportunity.NTE_Event_Opportunity; visible=true |
| tabSettings | tab=standard-Lead; visibility=Visible; tab=standard-Account; visibility=Visible; tab=standard-Contact; visibility=Visible; tab=standard-Opportunity; visibility=Visible; tab=NTE_Master_Panel; visibility=Visible |
| userPermissions | enabled=true; name=EditTask; enabled=true; name=ConvertLeads; enabled=true; name=RunReports |
| hasActivationRequired | false |
| label | NTE Management User |
| objectPermissions | allowCreate=true; allowDelete=false; allowEdit=true; allowRead=true; modifyAllRecords=false; object=Lead; viewAllFields=false; viewAllRecords=false; allowCreate=true; allowDelete=false; allowEdit=true; allowRead=true; modifyAllRecords=false; object=Account; viewAllFields=false; viewAllRecords=false; allowCreate=true; allowDelete=false; allowEdit=true; allowRead=true; modifyAllRecords=false; object=Contact; viewAllFields=false; viewAllRecords=false; allowCreate=true; allowDelete=false; allowEdit=true; allowRead=true; modifyAllRecords=false; object=Opportunity; viewAllFields=false; viewAllRecords=false; allowCreate=true; allowDelete=false; allowEdit=true; allowRead=true; modifyAllRecords=false; object=Task; viewAllFields=false; viewAllRecords=false; allowCreate=true; allowDelete=false; allowEdit=true; allowRead=true; modifyAllRecords=false; object=Event; viewAllFields=false; viewAllRecords=false; allowCreate=true; allowDelete=false; allowEdit=true; allowRead=true; modifyAllRecords=false; object=NTE_Email_Dispatch__c; viewAllRecords=false; allowCreate=false; allowDelete=false; allowEdit=false; allowRead=true; modifyAllRecords=false; object=NTE_Payment_Request__c; viewAllRecords=false |



### NTE Stripe Test Operator

Source: force-app/main/default/permissionsets/NTE_Stripe_Test_Operator.permissionset-meta.xml.

The complete custom field grants appear beside every field in the data dictionary.


| Setting | Value |
| --- | --- |
| classAccesses | apexClass=NTEStripeClient; enabled=true |
| description | Allows an authorised NTE operator to use the configured Stripe payment principals. |
| externalCredentialPrincipalAccesses | enabled=true; externalCredentialPrincipal=NTE_Stripe_Test-NTEApplication; enabled=true; externalCredentialPrincipal=NTE_Stripe_Live-NTEApplication |
| label | NTE Stripe Payment Operator |
| objectPermissions | allowCreate=false; allowDelete=false; allowEdit=false; allowRead=true; modifyAllRecords=false; object=NTE_Payment_Request__c; viewAllRecords=false |



### Volunteer Applications User

Source: force-app/main/default/permissionsets/Volunteer_Applications_User.permissionset-meta.xml.

The complete custom field grants appear beside every field in the data dictionary.


| Setting | Value |
| --- | --- |
| classAccesses | apexClass=VolunteerInboundLeadService; enabled=true |
| description | Access Mission Motorsport volunteer applications and their application details. |
| objectPermissions | allowCreate=true; allowDelete=false; allowEdit=true; allowRead=true; modifyAllRecords=false; object=Lead; viewAllFields=false; viewAllRecords=false |
| hasActivationRequired | false |
| label | Volunteer Applications User |



## Lightning application

### NTE Management

Source: force-app/main/default/applications/NTE_Management.app-meta.xml.


| Setting | Value |
| --- | --- |
| actionOverrides | actionName=Tab; content=NTE_Management_Home; formFactor=Large; skipRecordTypeSelect=false; type=Flexipage; pageOrSobjectType=standard-home; actionName=View; content=NTE_Management_Lead_Record_Page; formFactor=Large; skipRecordTypeSelect=false; type=Flexipage; pageOrSobjectType=Lead; actionName=View; content=NTE_Management_Lead_Record_Page; formFactor=Small; skipRecordTypeSelect=false; type=Flexipage; pageOrSobjectType=Lead; actionName=View; content=NTE_Management_Account_Record_Page; formFactor=Large; skipRecordTypeSelect=false; type=Flexipage; pageOrSobjectType=Account; actionName=View; content=NTE_Management_Account_Record_Page; formFactor=Small; skipRecordTypeSelect=false; type=Flexipage; pageOrSobjectType=Account; actionName=View; content=NTE_Management_Contact_Record_Page; formFactor=Large; skipRecordTypeSelect=false; type=Flexipage; pageOrSobjectType=Contact; actionName=View; content=NTE_Management_Contact_Record_Page; formFactor=Small; skipRecordTypeSelect=false; type=Flexipage; pageOrSobjectType=Contact; actionName=View; content=NTE_Management_Opportunity_Record_Page; formFactor=Large; skipRecordTypeSelect=false; type=Flexipage; pageOrSobjectType=Opportunity; actionName=View; content=NTE_Management_Opportunity_Record_Page; formFactor=Small; skipRecordTypeSelect=false; type=Flexipage; pageOrSobjectType=Opportunity |
| brand | footerColor=#8E793F; headerColor=#071D2B; logo=NTE_Management_Logo; logoVersion=1; shouldOverrideOrgTheme=true |
| defaultLandingTab | standard-home |
| description | Daily workspace for National Transition Event enquiries, applications, participants, bookings, logistics and follow-up. |
| formFactors | Small; Large |
| isNavAutoTempTabsDisabled | false |
| isNavPersonalizationDisabled | true |
| isNavTabPersistenceDisabled | false |
| isOmniPinnedViewEnabled | false |
| label | NTE Management |
| navType | Standard |
| tabs | standard-home; NTE_Master_Panel; standard-Lead; standard-Account; standard-Contact; standard-Opportunity; standard-Task; standard-Event; standard-Dashboard; standard-report |
| uiType | Lightning |



## Record actions

### Lead

Source: force-app/main/default/quickActions/Lead.Retry_Update_Email.quickAction-meta.xml.


| Setting | Value |
| --- | --- |
| label | Retry update email |
| lightningWebComponent | nteRetryEmail |
| optionsCreateFeedItem | false |
| type | LightningWebComponent |



### NTE Email Dispatch

Source: force-app/main/default/quickActions/NTE_Email_Dispatch__c.Retry_Email.quickAction-meta.xml.


| Setting | Value |
| --- | --- |
| label | Retry email |
| lightningWebComponent | nteRetryEmail |
| optionsCreateFeedItem | false |
| type | LightningWebComponent |



### Opportunity

Source: force-app/main/default/quickActions/Opportunity.Retry_Booking_Email.quickAction-meta.xml.


| Setting | Value |
| --- | --- |
| label | Retry booking email |
| lightningWebComponent | nteRetryEmail |
| optionsCreateFeedItem | false |
| type | LightningWebComponent |



## Sharing rule

### Opportunity

Source: force-app/main/default/sharingRules/Opportunity.sharingRules-meta.xml.


| Setting | Value |
| --- | --- |
| sharingCriteriaRules | fullName=NTE_Opportunities_Internal_Edit; accessLevel=Edit; label=NTE Opportunities - Internal Edit Access; sharedTo=allInternalUsers=; criteriaItems=field=RecordTypeId; operation=equals; value=NTE Event Opportunity |



## Duplicate rules

### Lead

Source: force-app/main/default/duplicateRules/Lead.NTE_Web_to_Lead_Duplicate_Report.duplicateRule-meta.xml.


| Setting | Value |
| --- | --- |
| actionOnInsert | Allow |
| actionOnUpdate | Allow |
| description | Allows NTE Web-to-Lead submissions that match an existing Contact while retaining duplicate reporting. |
| duplicateRuleFilter | booleanFilter=1; duplicateRuleFilterItems=field=LeadSource; operation=equals; sortOrder=1; table=Lead; value=Customer Event |
| duplicateRuleMatchRules | matchRuleSObjectType=Contact; matchingRule=Standard_Contact_Match_Rule_v1_1; objectMapping=inputObject=Lead; mappingFields=inputField=FirstName; outputField=FirstName; inputField=LastName; outputField=LastName; inputField=Phone; outputField=Phone; inputField=Email; outputField=Email; inputField=City; outputField=MailingCity; inputField=Street; outputField=MailingStreet; inputField=PostalCode; outputField=MailingPostalCode; inputField=Title; outputField=Title; inputField=Company; outputField=AccountId; outputObject=Contact |
| isActive | true |
| masterLabel | NTE Web-to-Lead Duplicate Report |
| operationsOnInsert | Report |
| operationsOnUpdate | Report |
| securityOption | EnforceSharingRules |
| sortOrder | 3 |



### Lead

Source: force-app/main/default/duplicateRules/Lead.Standard_Rule_for_Leads_with_Duplicate_Contacts.duplicateRule-meta.xml.


| Setting | Value |
| --- | --- |
| actionOnInsert | Allow |
| actionOnUpdate | Allow |
| alertText | Use one of these records? |
| description | Identify leads with duplicate contacts. |
| duplicateRuleFilter | booleanFilter=1; duplicateRuleFilterItems=field=LeadSource; operation=notEqual; sortOrder=1; table=Lead; value=Customer Event |
| duplicateRuleMatchRules | matchRuleSObjectType=Contact; matchingRule=Standard_Contact_Match_Rule_v1_1; objectMapping=inputObject=Lead; mappingFields=inputField=FirstName; outputField=FirstName; inputField=LastName; outputField=LastName; inputField=Phone; outputField=Phone; inputField=Email; outputField=Email; inputField=City; outputField=MailingCity; inputField=Street; outputField=MailingStreet; inputField=PostalCode; outputField=MailingPostalCode; inputField=Title; outputField=Title; inputField=Company; outputField=AccountId; outputObject=Contact |
| isActive | true |
| masterLabel | Standard Rule for Leads with Duplicate Contacts |
| operationsOnInsert | Alert; Report |
| operationsOnUpdate | Report |
| securityOption | EnforceSharingRules |
| sortOrder | 2 |



## Shared standard picklists

### LeadSource

Source: force-app/main/default/standardValueSets/LeadSource.standardValueSet-meta.xml.

Sorted=false.


| API value | Attributes |
| --- | --- |
| Advertisement | default=false; label=Advertisement |
| Customer Event | default=false; label=Customer Event |
| Employee Referral | default=false; label=Employee Referral |
| External Referral | default=false; label=External Referral |
| Google AdWords | default=false; label=Google AdWords |
| Other | default=false; label=Other |
| Partner | default=false; label=Partner |
| Purchased List | default=false; label=Purchased List |
| Trade Show | default=false; label=Trade Show |
| Webinar | default=false; label=Webinar |
| Website | default=false; label=Website |
| Partner Sponsor Exhibition Space Questions | default=false; label=Partner Sponsor Exhibition Space Questions |
| Partner Sponsor Application Form | default=false; label=Partner Sponsor Application Form |
| Volunteer Application | default=false; label=Volunteer Application |



### OpportunityStage

Source: force-app/main/default/standardValueSets/OpportunityStage.standardValueSet-meta.xml.

Sorted=false.


| API value | Attributes |
| --- | --- |
| Qualification | default=false; description=You've contacted the prospect and they're interested.; label=Qualification; closed=false; forecastCategory=Pipeline; probability=10; won=false |
| Needs Analysis | default=false; description=You're defining the prospect's needs.; label=Needs Analysis; closed=false; forecastCategory=Pipeline; probability=35; won=false |
| Proposal | default=false; description=You're developing a sales proposal for the prospect.; label=Proposal; closed=false; forecastCategory=BestCase; probability=75; won=false |
| Negotiation | default=false; description=You're working with the prospect on the proposal you delivered.; label=Negotiation; closed=false; forecastCategory=Forecast; probability=90; won=false |
| Closed Won | default=false; description=Sold!; label=Closed Won; closed=true; forecastCategory=Closed; probability=100; won=true |
| Closed Lost | default=false; description=No sale.; label=Closed Lost; closed=true; forecastCategory=Omitted; probability=0; won=false |



## Reports

Native report filters apply to the report definition itself; navigating from a panel does not automatically replace every native report filter with the panel owner/time scope. The weekly report uses Last Update in the last seven days; other report date baselines and exact criteria follow.

### NTE 01   Guest Check in   Accessibility

Source: force-app/main/default/reports/NTE_Operations/NTE_01_Guest_Check_In_and_Accessibility.report-meta.xml.

On-the-day guest register, accompanying guest details and accessibility arrangements for every NTE edition.


| Setting | Value |
| --- | --- |
| reportType | LeadList |
| format | Summary |
| scope | org |
| filter | criteriaItems=column=Lead.Web_Form_Type__c; columnToColumn=false; isUnlocked=true; operator=equals; value=Guest Registration |
| timeFrameFilter | dateColumn=CREATED_DATE; interval=INTERVAL_CUSTOM; startDate=2000-01-01 |
| groupingsDown | dateGranularity=Day; field=Lead.NTE_Event_Code__c; sortOrder=Asc |
| sortColumn | LAST_NAME |
| sortOrder | Asc |
| showDetails | true |
| showGrandTotal | true |
| showSubTotals | true |



Columns in order: FIRST_NAME; LAST_NAME; COMPANY; TITLE; EMAIL; PHONE; Lead.Guest_Accompanying__c; Lead.Accompanying_Guest_Name__c; Lead.Accompanying_Guest_Email__c; Lead.Guest_Accessibility_Required__c; Lead.Guest_Accessibility_Details__c; Lead.Guest_Information_Declaration__c; STATUS; OWNER; CREATED_DATE.

### NTE 02   Partner Sponsor Operations

Source: force-app/main/default/reports/NTE_Operations/NTE_02_Partner_Sponsor_Event_Operations.report-meta.xml.

Complete partner and sponsor operating sheet covering contacts, packages, confirmed value, previous events, staff, stand needs, accessibility and vehicle logistics.


| Setting | Value |
| --- | --- |
| reportType | Opportunity |
| format | Summary |
| scope | organization |
| filter | booleanFilter=(1 AND (2 OR 3)) AND 4; criteriaItems=column=Opportunity.NTE_Source_Form_Type__c; columnToColumn=false; isUnlocked=true; operator=equals; value=Partner / Sponsor Application; column=CLOSED; columnToColumn=false; isUnlocked=true; operator=equals; value=false; column=WON; columnToColumn=false; isUnlocked=true; operator=equals; value=true; column=RECORDTYPE; columnToColumn=false; isUnlocked=false; operator=equals; value=Opportunity.NTE_Event_Opportunity |
| timeFrameFilter | dateColumn=CLOSE_DATE; interval=INTERVAL_CUSTOM; startDate=2000-01-01 |
| groupingsDown | dateGranularity=Day; field=Opportunity.NTE_Event_Code__c; sortOrder=Asc |
| sortColumn | ACCOUNT_NAME |
| sortOrder | Asc |
| showDetails | true |
| showGrandTotal | true |
| showSubTotals | true |



Columns in order: ACCOUNT_NAME; CONTACT; OPPORTUNITY_NAME; Opportunity.Booking_Reference__c; STAGE_NAME; Opportunity.NTE_Attendance_Status__c; Opportunity.NTE_Sponsor_Package__c; Opportunity.NTE_Sponsor_Package_Total__c; Opportunity.NTE_Previous_Events__c; Opportunity.NTE_Event_Contact_Name__c; Opportunity.NTE_Event_Contact_Title__c; Opportunity.NTE_Event_Contact_Email__c; Opportunity.NTE_Event_Contact_Mobile__c; Opportunity.NTE_Secondary_Contact_Name__c; Opportunity.NTE_Secondary_Contact_Email__c; Opportunity.NTE_Secondary_Contact_Mobile__c; Opportunity.NTE_Stand_Colleagues__c; Opportunity.NTE_Planned_Exhibitor_Count__c; Opportunity.NTE_Additional_Staff_Required__c; Opportunity.NTE_Additional_Staff_Count__c; Opportunity.NTE_Additional_Staff_Unit_Price__c; Opportunity.NTE_Additional_Staff_Total__c; Opportunity.NTE_Listed_Price_Total__c; Opportunity.NTE_VAT_Rate__c; Opportunity.NTE_VAT_Total__c; Opportunity.NTE_Total_Including_VAT__c; Opportunity.NTE_Pricing_Status__c; Opportunity.NTE_Initial_Staff_Count__c; Opportunity.NTE_Included_Staff_Count__c; Opportunity.NTE_Total_Staff_Count__c; Opportunity.NTE_Top_Up_Staff_Required__c; Opportunity.NTE_Top_Up_Staff_Count__c; Opportunity.NTE_Top_Up_Staff_Names__c; Opportunity.NTE_Top_Up_Staff_Unit_Price__c; Opportunity.NTE_Top_Up_Staff_Total__c; Opportunity.NTE_Top_Up_VAT_Total__c; Opportunity.NTE_Top_Up_Total_Inc_VAT__c; Opportunity.NTE_Top_Up_Invoice_Required__c; Opportunity.NTE_Top_Up_Invoice_Provided__c; Opportunity.NTE_Top_Up_Invoice_At__c; Opportunity.NTE_Top_Up_Invoice_By__c; Opportunity.NTE_Top_Up_Payment_Received__c; Opportunity.NTE_Top_Up_Payment_At__c; Opportunity.NTE_Top_Up_Payment_By__c; Opportunity.NTE_Confirmed_Value__c; Opportunity.NTE_Invoice_Required__c; Opportunity.NTE_Payment_Method__c; Opportunity.NTE_Quote_Required_for_PO__c; Opportunity.NTE_Quote_Provided__c; Opportunity.NTE_Invoice_Provided__c; Opportunity.NTE_Payment_Received__c; Opportunity.NTE_Stand_Power__c; Opportunity.NTE_Stand_Equipment__c; Opportunity.NTE_Stand_Special_Requirements__c; Opportunity.NTE_Stand_Extra_Notes__c; Opportunity.NTE_Exhibitor_Hall_Schedule__c; Opportunity.NTE_Heavy_Vehicle_Required__c; Opportunity.NTE_Delivery_Window__c; Opportunity.NTE_Heavy_Item_1_Description__c; Opportunity.NTE_Heavy_Item_1_Registration__c; Opportunity.NTE_Heavy_Item_2_Description__c; Opportunity.NTE_Heavy_Item_2_Registration__c; Opportunity.NTE_Heavy_Item_3_Description__c; Opportunity.NTE_Heavy_Item_3_Registration__c; Opportunity.NTE_Haulier_Name__c; Opportunity.NTE_Haulier_Staff__c; Opportunity.NTE_Haulier_Vehicle_Type__c; Opportunity.NTE_Haulier_Vehicle_Registration__c; Opportunity.NTE_Last_Update_Processed_At__c; FULL_NAME; Opportunity.NTE_Logo_Update_Provided__c; Opportunity.NTE_Logo_Update_Provided_At__c; Opportunity.NTE_Final_Pack_Status__c; Opportunity.NTE_Final_Pack_Sent_At__c.

### NTE 03   Exhibitor Event Operations

Source: force-app/main/default/reports/NTE_Operations/NTE_03_Exhibitor_Event_Operations.report-meta.xml.

Complete exhibitor operating sheet for check-in, confirmed value, space allocation, power, sockets, equipment, staff, accessibility, setup and vehicle logistics.


| Setting | Value |
| --- | --- |
| reportType | Opportunity |
| format | Summary |
| scope | organization |
| filter | booleanFilter=(1 AND (2 OR 3)) AND 4; criteriaItems=column=Opportunity.NTE_Source_Form_Type__c; columnToColumn=false; isUnlocked=true; operator=equals; value=Exhibitor Application; column=CLOSED; columnToColumn=false; isUnlocked=true; operator=equals; value=false; column=WON; columnToColumn=false; isUnlocked=true; operator=equals; value=true; column=RECORDTYPE; columnToColumn=false; isUnlocked=false; operator=equals; value=Opportunity.NTE_Event_Opportunity |
| timeFrameFilter | dateColumn=CLOSE_DATE; interval=INTERVAL_CUSTOM; startDate=2000-01-01 |
| groupingsDown | dateGranularity=Day; field=Opportunity.NTE_Event_Code__c; sortOrder=Asc |
| sortColumn | ACCOUNT_NAME |
| sortOrder | Asc |
| showDetails | true |
| showGrandTotal | true |
| showSubTotals | true |



Columns in order: ACCOUNT_NAME; CONTACT; OPPORTUNITY_NAME; Opportunity.Booking_Reference__c; STAGE_NAME; Opportunity.NTE_Attendance_Status__c; Opportunity.NTE_Exhibitor_Organisation_Category__c; Opportunity.NTE_Exhibitor_Space_Selections__c; Opportunity.NTE_Exhibitor_Space_Price__c; Opportunity.NTE_Previous_Events__c; Opportunity.NTE_Event_Contact_Name__c; Opportunity.NTE_Event_Contact_Email__c; Opportunity.NTE_Event_Contact_Mobile__c; Opportunity.NTE_Secondary_Contact_Name__c; Opportunity.NTE_Secondary_Contact_Email__c; Opportunity.NTE_Secondary_Contact_Mobile__c; Opportunity.NTE_Stand_Colleagues__c; Opportunity.NTE_Planned_Exhibitor_Count__c; Opportunity.NTE_Additional_Staff_Required__c; Opportunity.NTE_Additional_Staff_Count__c; Opportunity.NTE_Additional_Staff_Unit_Price__c; Opportunity.NTE_Additional_Staff_Total__c; Opportunity.NTE_Stand_Power__c; Opportunity.NTE_Power_Socket_Count__c; Opportunity.NTE_Power_Socket_Unit_Price__c; Opportunity.NTE_Power_Socket_Total__c; Opportunity.NTE_Listed_Price_Total__c; Opportunity.NTE_VAT_Rate__c; Opportunity.NTE_VAT_Total__c; Opportunity.NTE_Total_Including_VAT__c; Opportunity.NTE_Pricing_Status__c; Opportunity.NTE_Initial_Staff_Count__c; Opportunity.NTE_Included_Staff_Count__c; Opportunity.NTE_Total_Staff_Count__c; Opportunity.NTE_Top_Up_Staff_Required__c; Opportunity.NTE_Top_Up_Staff_Count__c; Opportunity.NTE_Top_Up_Staff_Names__c; Opportunity.NTE_Top_Up_Staff_Unit_Price__c; Opportunity.NTE_Top_Up_Staff_Total__c; Opportunity.NTE_Top_Up_VAT_Total__c; Opportunity.NTE_Top_Up_Total_Inc_VAT__c; Opportunity.NTE_Top_Up_Invoice_Required__c; Opportunity.NTE_Top_Up_Invoice_Provided__c; Opportunity.NTE_Top_Up_Invoice_At__c; Opportunity.NTE_Top_Up_Invoice_By__c; Opportunity.NTE_Top_Up_Payment_Received__c; Opportunity.NTE_Top_Up_Payment_At__c; Opportunity.NTE_Top_Up_Payment_By__c; Opportunity.NTE_Confirmed_Value__c; Opportunity.NTE_Invoice_Required__c; Opportunity.NTE_Payment_Method__c; Opportunity.NTE_Quote_Required_for_PO__c; Opportunity.NTE_Quote_Provided__c; Opportunity.NTE_Invoice_Provided__c; Opportunity.NTE_Payment_Received__c; Opportunity.NTE_Stand_Equipment__c; Opportunity.NTE_Stand_Special_Requirements__c; Opportunity.NTE_Stand_Extra_Notes__c; Opportunity.NTE_Exhibitor_Hall_Schedule__c; Opportunity.NTE_Heavy_Vehicle_Required__c; Opportunity.NTE_Delivery_Window__c; Opportunity.NTE_Heavy_Item_1_Description__c; Opportunity.NTE_Heavy_Item_1_Registration__c; Opportunity.NTE_Heavy_Item_2_Description__c; Opportunity.NTE_Heavy_Item_2_Registration__c; Opportunity.NTE_Heavy_Item_3_Description__c; Opportunity.NTE_Heavy_Item_3_Registration__c; Opportunity.NTE_Haulier_Name__c; Opportunity.NTE_Haulier_Staff__c; Opportunity.NTE_Haulier_Vehicle_Type__c; Opportunity.NTE_Haulier_Vehicle_Registration__c; Opportunity.NTE_Last_Update_Processed_At__c; FULL_NAME; Opportunity.NTE_Logo_Update_Provided__c; Opportunity.NTE_Logo_Update_Provided_At__c; Opportunity.NTE_Final_Pack_Status__c; Opportunity.NTE_Final_Pack_Sent_At__c.

### NTE 04   Staff   Accreditation Roster

Source: force-app/main/default/reports/NTE_Operations/NTE_04_Staff_and_Accreditation_Roster.report-meta.xml.

Partner, sponsor, exhibitor and haulier people roster with primary contacts, expected headcount and accessibility notes.


| Setting | Value |
| --- | --- |
| reportType | Opportunity |
| format | Summary |
| scope | organization |
| filter | booleanFilter=((1 OR 2) AND (3 OR 4)) AND 5; criteriaItems=column=Opportunity.NTE_Source_Form_Type__c; columnToColumn=false; isUnlocked=true; operator=equals; value=Partner / Sponsor Application; column=Opportunity.NTE_Source_Form_Type__c; columnToColumn=false; isUnlocked=true; operator=equals; value=Exhibitor Application; column=CLOSED; columnToColumn=false; isUnlocked=true; operator=equals; value=false; column=WON; columnToColumn=false; isUnlocked=true; operator=equals; value=true; column=RECORDTYPE; columnToColumn=false; isUnlocked=false; operator=equals; value=Opportunity.NTE_Event_Opportunity |
| timeFrameFilter | dateColumn=CLOSE_DATE; interval=INTERVAL_CUSTOM; startDate=2000-01-01 |
| groupingsDown | dateGranularity=Day; field=Opportunity.NTE_Event_Code__c; sortOrder=Asc; dateGranularity=Day; field=Opportunity.NTE_Source_Form_Type__c; sortOrder=Asc |
| sortColumn | ACCOUNT_NAME |
| sortOrder | Asc |
| showDetails | true |
| showGrandTotal | true |
| showSubTotals | true |



Columns in order: Opportunity.NTE_Initial_Staff_Count__c; Opportunity.NTE_Included_Staff_Count__c; Opportunity.NTE_Total_Staff_Count__c; Opportunity.NTE_Top_Up_Staff_Required__c; Opportunity.NTE_Top_Up_Staff_Count__c; Opportunity.NTE_Top_Up_Staff_Names__c; Opportunity.NTE_Top_Up_Staff_Unit_Price__c; Opportunity.NTE_Top_Up_Staff_Total__c; Opportunity.NTE_Top_Up_VAT_Total__c; Opportunity.NTE_Top_Up_Total_Inc_VAT__c; Opportunity.NTE_Top_Up_Invoice_Required__c; Opportunity.NTE_Top_Up_Invoice_Provided__c; Opportunity.NTE_Top_Up_Invoice_At__c; Opportunity.NTE_Top_Up_Invoice_By__c; Opportunity.NTE_Top_Up_Payment_Received__c; Opportunity.NTE_Top_Up_Payment_At__c; Opportunity.NTE_Top_Up_Payment_By__c; ACCOUNT_NAME; CONTACT; OPPORTUNITY_NAME; Opportunity.Booking_Reference__c; Opportunity.NTE_Attendance_Status__c; Opportunity.NTE_Event_Contact_Name__c; Opportunity.NTE_Event_Contact_Email__c; Opportunity.NTE_Event_Contact_Mobile__c; Opportunity.NTE_Secondary_Contact_Name__c; Opportunity.NTE_Secondary_Contact_Email__c; Opportunity.NTE_Secondary_Contact_Mobile__c; Opportunity.NTE_Stand_Colleagues__c; Opportunity.NTE_Planned_Exhibitor_Count__c; Opportunity.NTE_Additional_Staff_Required__c; Opportunity.NTE_Additional_Staff_Count__c; Opportunity.NTE_Haulier_Staff__c; Opportunity.NTE_Has_Special_Requirements__c; Opportunity.NTE_Stand_Special_Requirements__c; Opportunity.NTE_Staff_Update_Completed_At__c.

### NTE 05   Heavy Vehicles   Logistics

Source: force-app/main/default/reports/NTE_Operations/NTE_05_Heavy_Vehicles_and_Logistics.report-meta.xml.

All NTE bookings requiring heavy-item or vehicle logistics, with every submitted item, registration, dimension, weight, delivery window and haulier detail.


| Setting | Value |
| --- | --- |
| reportType | Opportunity |
| format | Summary |
| scope | organization |
| filter | booleanFilter=(1 AND (2 OR 3)) AND 4; criteriaItems=column=Opportunity.NTE_Heavy_Vehicle_Required__c; columnToColumn=false; isUnlocked=true; operator=equals; value=Yes; column=CLOSED; columnToColumn=false; isUnlocked=true; operator=equals; value=false; column=WON; columnToColumn=false; isUnlocked=true; operator=equals; value=true; column=RECORDTYPE; columnToColumn=false; isUnlocked=false; operator=equals; value=Opportunity.NTE_Event_Opportunity |
| timeFrameFilter | dateColumn=CLOSE_DATE; interval=INTERVAL_CUSTOM; startDate=2000-01-01 |
| groupingsDown | dateGranularity=Day; field=Opportunity.NTE_Event_Code__c; sortOrder=Asc |
| sortColumn | ACCOUNT_NAME |
| sortOrder | Asc |
| showDetails | true |
| showGrandTotal | true |
| showSubTotals | true |



Columns in order: ACCOUNT_NAME; CONTACT; OPPORTUNITY_NAME; Opportunity.Booking_Reference__c; Opportunity.NTE_Source_Form_Type__c; Opportunity.NTE_Attendance_Status__c; Opportunity.NTE_Heavy_Vehicle_Required__c; Opportunity.NTE_Event_Contact_Name__c; Opportunity.NTE_Event_Contact_Email__c; Opportunity.NTE_Event_Contact_Mobile__c; Opportunity.NTE_Secondary_Contact_Name__c; Opportunity.NTE_Secondary_Contact_Email__c; Opportunity.NTE_Secondary_Contact_Mobile__c; Opportunity.NTE_Delivery_Window__c; Opportunity.NTE_Heavy_Item_1_Description__c; Opportunity.NTE_Heavy_Item_1_Registration__c; Opportunity.NTE_Heavy_Item_1_Dimensions__c; Opportunity.NTE_Heavy_Item_1_Gross_Weight__c; Opportunity.NTE_Heavy_Item_2_Description__c; Opportunity.NTE_Heavy_Item_2_Registration__c; Opportunity.NTE_Heavy_Item_2_Dimensions__c; Opportunity.NTE_Heavy_Item_2_Gross_Weight__c; Opportunity.NTE_Heavy_Item_3_Description__c; Opportunity.NTE_Heavy_Item_3_Registration__c; Opportunity.NTE_Heavy_Item_3_Dimensions__c; Opportunity.NTE_Heavy_Item_3_Gross_Weight__c; Opportunity.NTE_Haulier_Name__c; Opportunity.NTE_Haulier_Staff__c; Opportunity.NTE_Haulier_Vehicle_Type__c; Opportunity.NTE_Haulier_Vehicle_Registration__c; Opportunity.NTE_Haulier_Vehicle_Dimensions__c; Opportunity.NTE_Haulier_Vehicle_Gross_Weight__c; Opportunity.NTE_Last_Update_Processed_At__c; Opportunity.NTE_Heavy_Vehicle_Update_Completed_At__c.

### NTE 06   Finance   Invoicing

Source: force-app/main/default/reports/NTE_Operations/NTE_06_Finance_and_Invoicing.report-meta.xml.

NTE finance work with pricing checks, quotations, booking and staff top-up charges, payment milestones and billing details. Confirmed value excludes VAT.


| Setting | Value |
| --- | --- |
| reportType | Opportunity |
| format | Summary |
| scope | organization |
| filter | booleanFilter=((1 OR 2 OR 3 OR 4 OR 6 OR 7) AND (5 OR 8)) AND 9; criteriaItems=column=Opportunity.NTE_Invoice_Required__c; columnToColumn=false; isUnlocked=true; operator=equals; value=Yes; column=Opportunity.NTE_Listed_Price_Total__c; columnToColumn=false; isUnlocked=true; operator=greaterThan; value=0; column=Opportunity.NTE_Top_Up_Invoice_Required__c; columnToColumn=false; isUnlocked=true; operator=equals; value=true; column=Opportunity.NTE_Top_Up_Staff_Total__c; columnToColumn=false; isUnlocked=true; operator=greaterThan; value=0; column=CLOSED; columnToColumn=false; isUnlocked=true; operator=equals; value=false; column=Opportunity.NTE_Quote_Required_for_PO__c; columnToColumn=false; isUnlocked=true; operator=equals; value=Yes; column=Opportunity.NTE_Pricing_Ready__c; columnToColumn=false; isUnlocked=true; operator=equals; value=false; column=WON; columnToColumn=false; isUnlocked=true; operator=equals; value=true; column=RECORDTYPE; columnToColumn=false; isUnlocked=false; operator=equals; value=Opportunity.NTE_Event_Opportunity |
| timeFrameFilter | dateColumn=CLOSE_DATE; interval=INTERVAL_CUSTOM; startDate=2000-01-01 |
| groupingsDown | dateGranularity=Day; field=Opportunity.NTE_Event_Code__c; sortOrder=Asc; dateGranularity=Day; field=Opportunity.NTE_Source_Form_Type__c; sortOrder=Asc |
| sortColumn | ACCOUNT_NAME |
| sortOrder | Asc |
| showDetails | true |
| showGrandTotal | true |
| showSubTotals | true |



Columns in order: ACCOUNT_NAME; CONTACT; OPPORTUNITY_NAME; Opportunity.Booking_Reference__c; STAGE_NAME; Opportunity.NTE_Sponsor_Package__c; Opportunity.NTE_Sponsor_Package_Total__c; Opportunity.NTE_Exhibitor_Space_Selections__c; Opportunity.NTE_Exhibitor_Space_Price__c; Opportunity.NTE_Power_Socket_Count__c; Opportunity.NTE_Power_Socket_Unit_Price__c; Opportunity.NTE_Power_Socket_Total__c; Opportunity.NTE_Additional_Staff_Count__c; Opportunity.NTE_Additional_Staff_Unit_Price__c; Opportunity.NTE_Additional_Staff_Total__c; Opportunity.NTE_Listed_Price_Total__c; Opportunity.NTE_VAT_Rate__c; Opportunity.NTE_VAT_Total__c; Opportunity.NTE_Total_Including_VAT__c; Opportunity.NTE_Pricing_Status__c; Opportunity.NTE_Pricing_Version__c; Opportunity.NTE_Initial_Staff_Count__c; Opportunity.NTE_Included_Staff_Count__c; Opportunity.NTE_Total_Staff_Count__c; Opportunity.NTE_Top_Up_Staff_Required__c; Opportunity.NTE_Top_Up_Staff_Count__c; Opportunity.NTE_Top_Up_Staff_Names__c; Opportunity.NTE_Top_Up_Staff_Unit_Price__c; Opportunity.NTE_Top_Up_Staff_Total__c; Opportunity.NTE_Top_Up_VAT_Total__c; Opportunity.NTE_Top_Up_Total_Inc_VAT__c; Opportunity.NTE_Top_Up_Invoice_Required__c; Opportunity.NTE_Top_Up_Invoice_Provided__c; Opportunity.NTE_Top_Up_Invoice_At__c; Opportunity.NTE_Top_Up_Invoice_By__c; Opportunity.NTE_Top_Up_Payment_Received__c; Opportunity.NTE_Top_Up_Payment_At__c; Opportunity.NTE_Top_Up_Payment_By__c; Opportunity.NTE_Confirmed_Value__c; Opportunity.NTE_Invoice_Required__c; Opportunity.NTE_Payment_Method__c; Opportunity.NTE_Quote_Required_for_PO__c; Opportunity.NTE_Quote_Provided__c; Opportunity.NTE_Quote_Provided_At__c; Opportunity.NTE_Quote_Provided_By__c; Opportunity.NTE_Invoice_Provided__c; Opportunity.NTE_Invoice_Provided_At__c; Opportunity.NTE_Invoice_Provided_By__c; Opportunity.NTE_Payment_Received__c; Opportunity.NTE_Payment_Received_At__c; Opportunity.NTE_Payment_Recorded_By__c; Opportunity.NTE_Invoiced_Company__c; Opportunity.NTE_Trading_Name__c; Opportunity.NTE_Invoiced_Person__c; Opportunity.NTE_Invoice_Address__c; Opportunity.NTE_Invoiced_Email__c; Opportunity.NTE_Invoice_Contact_Phone__c; Opportunity.NTE_Purchase_Order__c; Opportunity.NTE_Purchase_Order_Number__c; Opportunity.NTE_Invoice_Additional_Information__c; Opportunity.NTE_Supplier_Agreement_Required__c; CLOSE_DATE; FULL_NAME; Opportunity.NTE_Pricing_Ready__c; Opportunity.NTE_Finance_Invoice_Due__c; Opportunity.NTE_Finance_Payment_Due__c; Opportunity.NTE_Finance_Payment_Confirmed__c.

### NTE 07   Application   EOI Pipeline

Source: force-app/main/default/reports/NTE_Operations/NTE_07_Application_and_EOI_Pipeline.report-meta.xml.

Unconverted NTE expressions of interest and applications, including recorded decisions, package choices, price components and finance requirements.


| Setting | Value |
| --- | --- |
| reportType | LeadList |
| format | Summary |
| scope | org |
| filter | booleanFilter=(1 OR 2 OR 3 OR 4) AND 5; criteriaItems=column=Lead.Web_Form_Type__c; columnToColumn=false; isUnlocked=true; operator=equals; value=Partner / Sponsor Expression of Interest; column=Lead.Web_Form_Type__c; columnToColumn=false; isUnlocked=true; operator=equals; value=Exhibitor Expression of Interest; column=Lead.Web_Form_Type__c; columnToColumn=false; isUnlocked=true; operator=equals; value=Partner / Sponsor Application; column=Lead.Web_Form_Type__c; columnToColumn=false; isUnlocked=true; operator=equals; value=Exhibitor Application; column=CONVERTED; columnToColumn=false; isUnlocked=true; operator=equals; value=false |
| timeFrameFilter | dateColumn=CREATED_DATE; interval=INTERVAL_CUSTOM; startDate=2000-01-01 |
| groupingsDown | dateGranularity=Day; field=Lead.NTE_Event_Code__c; sortOrder=Asc; dateGranularity=Day; field=Lead.Web_Form_Type__c; sortOrder=Asc |
| sortColumn | CREATED_DATE |
| sortOrder | Asc |
| showDetails | true |
| showGrandTotal | true |
| showSubTotals | true |



Columns in order: FIRST_NAME; LAST_NAME; COMPANY; TITLE; EMAIL; PHONE; Lead.Booking_Reference__c; STATUS; OWNER; Lead.NTE_Interest_Progressed__c; Lead.NTE_Interest_Not_Progressed__c; Lead.NTE_Application_Rejected__c; Lead.Organisation_Type__c; Lead.Partner_Interest_Type__c; Lead.Partner_Interest_Areas__c; Lead.Exhibitor_Interest_Detail__c; Lead.Exhibitor_Community_Contribution__c; Lead.Sponsor_Package__c; Lead.Exhibitor_Organisation_Category__c; Lead.Exhibitor_Space_Selections__c; Lead.Sponsor_Package_Total__c; Lead.Exhibitor_Space_Price__c; Lead.Power_Socket_Count__c; Lead.Power_Socket_Unit_Price__c; Lead.Power_Socket_Total__c; Lead.Additional_Staff_Count__c; Lead.Additional_Staff_Unit_Price__c; Lead.Additional_Staff_Total__c; Lead.Listed_Price_Total__c; Lead.VAT_Rate__c; Lead.VAT_Total__c; Lead.Total_Including_VAT__c; Lead.Pricing_Status__c; Lead.Invoice_Required__c; Lead.Payment_Method__c; Lead.Quote_Required_for_PO__c; Lead.NTE_Applicant_Email_Status__c; Lead.NTE_Internal_Email_Status__c; CREATED_DATE.

### NTE 08   Event Delivery Readiness

Source: force-app/main/default/reports/NTE_Operations/NTE_08_Event_Delivery_Readiness.report-meta.xml.

Cross-event NTE booking readiness, including primary and event contacts, staffing, logistics, logos, finance and final-pack history.


| Setting | Value |
| --- | --- |
| reportType | Opportunity |
| format | Summary |
| scope | organization |
| filter | booleanFilter=((1 OR 2) AND (3 OR 4)) AND 5; criteriaItems=column=Opportunity.NTE_Source_Form_Type__c; columnToColumn=false; isUnlocked=true; operator=equals; value=Partner / Sponsor Application; column=Opportunity.NTE_Source_Form_Type__c; columnToColumn=false; isUnlocked=true; operator=equals; value=Exhibitor Application; column=CLOSED; columnToColumn=false; isUnlocked=true; operator=equals; value=false; column=WON; columnToColumn=false; isUnlocked=true; operator=equals; value=true; column=RECORDTYPE; columnToColumn=false; isUnlocked=false; operator=equals; value=Opportunity.NTE_Event_Opportunity |
| timeFrameFilter | dateColumn=CLOSE_DATE; interval=INTERVAL_CUSTOM; startDate=2000-01-01 |
| groupingsDown | dateGranularity=Day; field=Opportunity.NTE_Event_Code__c; sortOrder=Asc; dateGranularity=Day; field=Opportunity.NTE_Source_Form_Type__c; sortOrder=Asc |
| sortColumn | ACCOUNT_NAME |
| sortOrder | Asc |
| showDetails | true |
| showGrandTotal | true |
| showSubTotals | true |



Columns in order: ACCOUNT_NAME; CONTACT; OPPORTUNITY_NAME; Opportunity.Booking_Reference__c; STAGE_NAME; Opportunity.NTE_Attendance_Status__c; Opportunity.NTE_Event_Contact_Name__c; Opportunity.NTE_Event_Contact_Mobile__c; Opportunity.NTE_Stand_Colleagues__c; Opportunity.NTE_Planned_Exhibitor_Count__c; Opportunity.NTE_Staff_Update_Completed_At__c; Opportunity.NTE_Exhibitor_Space_Selections__c; Opportunity.NTE_Stand_Power__c; Opportunity.NTE_Power_Socket_Count__c; Opportunity.NTE_Stand_Equipment__c; Opportunity.NTE_Has_Special_Requirements__c; Opportunity.NTE_Stand_Special_Requirements__c; Opportunity.NTE_Heavy_Vehicle_Required__c; Opportunity.NTE_Heavy_Vehicle_Update_Completed_At__c; Opportunity.NTE_Last_Update_Type__c; Opportunity.NTE_Last_Update_Processed_At__c; Opportunity.NTE_Listed_Price_Total__c; Opportunity.NTE_VAT_Rate__c; Opportunity.NTE_VAT_Total__c; Opportunity.NTE_Total_Including_VAT__c; Opportunity.NTE_Pricing_Status__c; Opportunity.NTE_Invoice_Required__c; Opportunity.NTE_Payment_Method__c; Opportunity.NTE_Quote_Required_for_PO__c; Opportunity.NTE_Quote_Provided__c; Opportunity.NTE_Invoice_Provided__c; Opportunity.NTE_Payment_Received__c; Opportunity.NTE_Initial_Staff_Count__c; Opportunity.NTE_Included_Staff_Count__c; Opportunity.NTE_Total_Staff_Count__c; Opportunity.NTE_Top_Up_Staff_Required__c; Opportunity.NTE_Top_Up_Staff_Count__c; Opportunity.NTE_Top_Up_Staff_Names__c; Opportunity.NTE_Top_Up_Staff_Unit_Price__c; Opportunity.NTE_Top_Up_Staff_Total__c; Opportunity.NTE_Top_Up_VAT_Total__c; Opportunity.NTE_Top_Up_Total_Inc_VAT__c; Opportunity.NTE_Top_Up_Invoice_Required__c; Opportunity.NTE_Top_Up_Invoice_Provided__c; Opportunity.NTE_Top_Up_Invoice_At__c; Opportunity.NTE_Top_Up_Invoice_By__c; Opportunity.NTE_Top_Up_Payment_Received__c; Opportunity.NTE_Top_Up_Payment_At__c; Opportunity.NTE_Top_Up_Payment_By__c; Opportunity.NTE_Confirmed_Value__c; FULL_NAME; Opportunity.NTE_Logo_Update_Provided__c; Opportunity.NTE_Logo_Update_Provided_At__c; Opportunity.NTE_Final_Pack_Status__c; Opportunity.NTE_Final_Pack_Sent_At__c.

### Weekly Finance Report

Source: force-app/main/default/reports/NTE_Operations/NTE_09_Weekly_Finance_Report.report-meta.xml.

Rolling seven-day Finance handoff for recently changed NTE bookings, with current quotation, invoice, payment, billing-contact and confirmed-value details. Use NTE 06 - Finance & Invoicing for the complete all-time finance view.


| Setting | Value |
| --- | --- |
| reportType | Opportunity |
| format | Summary |
| scope | organization |
| filter | booleanFilter=((1 OR 2 OR 3 OR 4 OR 6 OR 7) AND (5 OR 8)) AND 9; criteriaItems=column=Opportunity.NTE_Invoice_Required__c; columnToColumn=false; isUnlocked=true; operator=equals; value=Yes; column=Opportunity.NTE_Listed_Price_Total__c; columnToColumn=false; isUnlocked=true; operator=greaterThan; value=0; column=Opportunity.NTE_Top_Up_Invoice_Required__c; columnToColumn=false; isUnlocked=true; operator=equals; value=true; column=Opportunity.NTE_Top_Up_Staff_Total__c; columnToColumn=false; isUnlocked=true; operator=greaterThan; value=0; column=CLOSED; columnToColumn=false; isUnlocked=true; operator=equals; value=false; column=Opportunity.NTE_Quote_Required_for_PO__c; columnToColumn=false; isUnlocked=true; operator=equals; value=Yes; column=Opportunity.NTE_Pricing_Ready__c; columnToColumn=false; isUnlocked=true; operator=equals; value=false; column=WON; columnToColumn=false; isUnlocked=true; operator=equals; value=true; column=RECORDTYPE; columnToColumn=false; isUnlocked=false; operator=equals; value=Opportunity.NTE_Event_Opportunity |
| timeFrameFilter | dateColumn=LAST_UPDATE; interval=INTERVAL_LAST7 |
| groupingsDown | dateGranularity=Day; field=Opportunity.NTE_Event_Code__c; sortOrder=Asc; dateGranularity=Day; field=Opportunity.NTE_Source_Form_Type__c; sortOrder=Asc |
| sortColumn | LAST_UPDATE |
| sortOrder | Desc |
| showDetails | true |
| showGrandTotal | true |
| showSubTotals | true |



Columns in order: ACCOUNT_NAME; CONTACT; OPPORTUNITY_NAME; Opportunity.Booking_Reference__c; STAGE_NAME; Opportunity.NTE_Sponsor_Package__c; Opportunity.NTE_Sponsor_Package_Total__c; Opportunity.NTE_Exhibitor_Space_Selections__c; Opportunity.NTE_Exhibitor_Space_Price__c; Opportunity.NTE_Power_Socket_Count__c; Opportunity.NTE_Power_Socket_Unit_Price__c; Opportunity.NTE_Power_Socket_Total__c; Opportunity.NTE_Initial_Staff_Count__c; Opportunity.NTE_Included_Staff_Count__c; Opportunity.NTE_Additional_Staff_Count__c; Opportunity.NTE_Additional_Staff_Unit_Price__c; Opportunity.NTE_Additional_Staff_Total__c; Opportunity.NTE_Total_Staff_Count__c; Opportunity.NTE_Top_Up_Staff_Required__c; Opportunity.NTE_Top_Up_Staff_Count__c; Opportunity.NTE_Top_Up_Staff_Unit_Price__c; Opportunity.NTE_Top_Up_Staff_Total__c; Opportunity.NTE_Top_Up_VAT_Total__c; Opportunity.NTE_Top_Up_Total_Inc_VAT__c; Opportunity.NTE_Listed_Price_Total__c; Opportunity.NTE_VAT_Rate__c; Opportunity.NTE_VAT_Total__c; Opportunity.NTE_Total_Including_VAT__c; Opportunity.NTE_Confirmed_Value__c; Opportunity.NTE_Pricing_Status__c; Opportunity.NTE_Pricing_Version__c; Opportunity.NTE_Invoice_Required__c; Opportunity.NTE_Payment_Method__c; Opportunity.NTE_Quote_Required_for_PO__c; Opportunity.NTE_Quote_Provided__c; Opportunity.NTE_Quote_Provided_At__c; Opportunity.NTE_Quote_Provided_By__c; Opportunity.NTE_Invoice_Provided__c; Opportunity.NTE_Invoice_Provided_At__c; Opportunity.NTE_Invoice_Provided_By__c; Opportunity.NTE_Payment_Received__c; Opportunity.NTE_Payment_Received_At__c; Opportunity.NTE_Payment_Recorded_By__c; Opportunity.NTE_Top_Up_Invoice_Required__c; Opportunity.NTE_Top_Up_Invoice_Provided__c; Opportunity.NTE_Top_Up_Invoice_At__c; Opportunity.NTE_Top_Up_Invoice_By__c; Opportunity.NTE_Top_Up_Payment_Received__c; Opportunity.NTE_Top_Up_Payment_At__c; Opportunity.NTE_Top_Up_Payment_By__c; Opportunity.NTE_Invoiced_Company__c; Opportunity.NTE_Trading_Name__c; Opportunity.NTE_Invoiced_Person__c; Opportunity.NTE_Invoice_Address__c; Opportunity.NTE_Invoiced_Email__c; Opportunity.NTE_Invoice_Contact_Phone__c; Opportunity.NTE_Purchase_Order__c; Opportunity.NTE_Purchase_Order_Number__c; Opportunity.NTE_Supplier_Agreement_Required__c; Opportunity.NTE_Invoice_Additional_Information__c; LAST_UPDATE; FULL_NAME; Opportunity.NTE_Pricing_Ready__c; Opportunity.NTE_Finance_Invoice_Due__c; Opportunity.NTE_Finance_Payment_Due__c; Opportunity.NTE_Finance_Payment_Confirmed__c.

### NTE Operations   Finance

Source: force-app/main/default/reports/NTE_Operations.reportFolder-meta.xml.

folderShares=accessLevel=View; sharedTo=AllInternalUsers; sharedToType=Organization; name=NTE Operations & Finance

## Native list views

These are all 25 packaged views, including the three retained legacy separate top-up views. Native lists operate on their own scope; their existence does not add new Master Panel stages.

### NTE Organisations

Object Account. API NTE_Organisations. Scope Everything.

Filter logic: AND. Criteria: field=NTE_Participant__c; operation=equals; value=1.

Columns: ACCOUNT.NAME; ACCOUNT.TYPE; NTE_Event_Code__c; NTE_Source_Form_Type__c; NTE_Booking_Reference__c; NTE_Last_Application_Date__c.

### NTE Contacts

Object Contact. API NTE_Contacts. Scope Everything.

Filter logic: AND. Criteria: field=NTE_Participant__c; operation=equals; value=1.

Columns: FULL_NAME; CONTACT.TITLE; CONTACT.EMAIL; NTE_Event_Code__c; NTE_Source_Form_Type__c; NTE_Booking_Reference__c; NTE_Last_Application_Date__c.

### NTE All Web Submissions

Object Lead. API NTE_All_Web_Submissions. Scope Everything.

Filter logic: AND. Criteria: field=NTE_Event_Code__c; operation=notEqual.

Columns: FULL_NAME; LEAD.COMPANY; LEAD.EMAIL; Web_Form_Type__c; NTE_Event_Code__c; Booking_Reference__c; Target_Booking_Reference__c; LEAD.STATUS; LEAD.CREATED_DATE.

### NTE Applications

Object Lead. API NTE_Applications. Scope Everything.

Filter logic: AND. Criteria: field=Web_Form_Type__c; operation=equals; value=Partner / Sponsor Application,Exhibitor Application; field=LEAD.CONVERTED; operation=equals; value=0; field=NTE_Application_Rejected__c; operation=equals; value=0; field=NTE_Event_Code__c; operation=notEqual.

Columns: FULL_NAME; LEAD.COMPANY; LEAD.EMAIL; Web_Form_Type__c; Booking_Reference__c; Payment_Method__c; NTE_Event_Code__c; NTE_Application_Rejected__c; LEAD.STATUS; LEAD.CREATED_DATE.

### NTE Exhibitor Applications

Object Lead. API NTE_Exhibitor_Applications. Scope Everything.

Filter logic: AND. Criteria: field=Web_Form_Type__c; operation=equals; value=Exhibitor Application; field=LEAD.CONVERTED; operation=equals; value=0; field=NTE_Application_Rejected__c; operation=equals; value=0; field=NTE_Event_Code__c; operation=notEqual.

Columns: FULL_NAME; LEAD.COMPANY; LEAD.EMAIL; Booking_Reference__c; Payment_Method__c; NTE_Event_Code__c; NTE_Application_Rejected__c; LEAD.STATUS; LEAD.CREATED_DATE.

### NTE Expressions of Interest

Object Lead. API NTE_Expressions_of_Interest. Scope Everything.

Filter logic: AND. Criteria: field=Web_Form_Type__c; operation=equals; value=Partner / Sponsor Expression of Interest,Exhibitor Expression of Interest; field=LEAD.CONVERTED; operation=equals; value=0; field=NTE_Interest_Progressed__c; operation=equals; value=0; field=NTE_Interest_Not_Progressed__c; operation=equals; value=0; field=NTE_Event_Code__c; operation=notEqual.

Columns: FULL_NAME; LEAD.COMPANY; LEAD.EMAIL; Web_Form_Type__c; NTE_Event_Code__c; NTE_Interest_Progressed__c; NTE_Interest_Not_Progressed__c; LEAD.STATUS; LEAD.CREATED_DATE.

### NTE Guest Registrations

Object Lead. API NTE_Guest_Registrations. Scope Everything.

Filter logic: AND. Criteria: field=Web_Form_Type__c; operation=equals; value=Guest Registration; field=LEAD.CONVERTED; operation=equals; value=0.

Columns: FULL_NAME; LEAD.COMPANY; LEAD.EMAIL; NTE_Event_Code__c; LEAD.STATUS; LEAD.CREATED_DATE.

### NTE Partner   Sponsor Applications

Object Lead. API NTE_Partner_Sponsor_Applications. Scope Everything.

Filter logic: AND. Criteria: field=Web_Form_Type__c; operation=equals; value=Partner / Sponsor Application; field=LEAD.CONVERTED; operation=equals; value=0; field=NTE_Application_Rejected__c; operation=equals; value=0; field=NTE_Event_Code__c; operation=notEqual.

Columns: FULL_NAME; LEAD.COMPANY; LEAD.EMAIL; Booking_Reference__c; Payment_Method__c; NTE_Event_Code__c; NTE_Application_Rejected__c; LEAD.STATUS; LEAD.CREATED_DATE.

### NTE Unmatched Updates

Object Lead. API NTE_Unmatched_Updates. Scope Everything.

Filter logic: AND. Criteria: field=NTE_Update_Status__c; operation=equals; value=No Matching Booking,Ambiguous Booking Reference,Failed.

Columns: FULL_NAME; LEAD.COMPANY; LEAD.EMAIL; Web_Form_Type__c; Target_Booking_Reference__c; NTE_Update_Status__c; NTE_Update_Error__c; LEAD.CREATED_DATE.

### NTE Update Emails Failed

Object Lead. API NTE_Update_Emails_Failed. Scope Everything.

Filter logic: AND. Criteria: field=NTE_Update_Status__c; operation=equals; value=Matched and Applied; field=NTE_Applicant_Email_Status__c; operation=equals; value=Failed.

Columns: FULL_NAME; LEAD.COMPANY; Web_Form_Type__c; Target_Booking_Reference__c; NTE_Update_Status__c; NTE_Applicant_Email_Status__c; LEAD.CREATED_DATE.

### Volunteer Applications

Object Lead. API Volunteer_Applications. Scope Everything.

Filter logic: AND. Criteria: field=Web_Form_Type__c; operation=equals; value=Volunteer Application.

Columns: FULL_NAME; LEAD.EMAIL; LEAD.MOBILE_PHONE; Volunteer_Opportunities__c; Volunteer_Travel_Regions__c; Volunteer_DBS_Willing__c; LEAD.STATUS; LEAD.CREATED_DATE.

### NTE Email Failures

Object NTE_Email_Dispatch__c. API NTE_Email_Failures. Scope Everything.

Filter logic: AND. Criteria: field=Status__c; operation=equals; value=Failed.

Columns: NAME; Kind__c; Recipient__c; Event_Code__c; Status__c; Opportunity__c; Lead__c; CREATED_DATE.

### NTE Recent Emails

Object NTE_Email_Dispatch__c. API NTE_Recent_Emails. Scope Everything.

Filter logic: AND. Criteria: .

Columns: NAME; Kind__c; Recipient__c; Status__c; Sent_At__c; Opportunity__c; Lead__c; CREATED_DATE.

### NTE Payment Requests

Object NTE_Payment_Request__c. API NTE_Payment_Requests. Scope Everything.

Filter logic: AND. Criteria: .

Columns: NAME; Opportunity__c; Kind__c; Status__c; Reference__c; Delivered_At__c.

### NTE Event Participation

Object Opportunity. API NTE_Event_Participation. Scope Everything.

Filter logic: AND. Criteria: field=OPPORTUNITY.RECORDTYPE; operation=equals; value=Opportunity.NTE_Event_Opportunity; field=NTE_Event_Code__c; operation=notEqual.

Columns: OPPORTUNITY.NAME; ACCOUNT.NAME; NTE_Event_Code__c; NTE_Source_Form_Type__c; Booking_Reference__c; NTE_Attendance_Status__c; OPPORTUNITY.STAGE_NAME; OPPORTUNITY.CLOSE_DATE.

### NTE Heavy Vehicle Updates Due

Object Opportunity. API NTE_Heavy_Vehicle_Updates_Due. Scope Everything.

Filter logic: 1 AND 2 AND 3 AND (4 OR 5) AND ((6 AND 7) OR 8 OR (9 AND 10)). Criteria: field=OPPORTUNITY.RECORDTYPE; operation=equals; value=Opportunity.NTE_Event_Opportunity; field=NTE_Event_Code__c; operation=notEqual; field=NTE_Source_Form_Type__c; operation=equals; value=Exhibitor Application,Partner / Sponsor Application; field=OPPORTUNITY.CLOSED; operation=equals; value=0; field=OPPORTUNITY.WON; operation=equals; value=1; field=NTE_Heavy_Vehicle_Required__c; operation=notEqual; value=Yes; field=NTE_Heavy_Vehicle_Required__c; operation=notEqual; value=No; field=NTE_Heavy_Vehicle_Required__c; operation=equals; value=; field=NTE_Heavy_Vehicle_Required__c; operation=equals; value=Yes; field=NTE_Heavy_Vehicle_Update_Completed_At__c; operation=equals; value=.

Columns: OPPORTUNITY.NAME; ACCOUNT.NAME; NTE_Event_Code__c; Booking_Reference__c; NTE_Heavy_Vehicle_Required__c; NTE_Heavy_Vehicle_Update_Completed_At__c.

### NTE Invoice Required

Object Opportunity. API NTE_Invoices_Required. Scope Everything.

Filter logic: 1 AND 2 AND 3 AND (4 OR 5) AND (6). Criteria: field=OPPORTUNITY.RECORDTYPE; operation=equals; value=Opportunity.NTE_Event_Opportunity; field=NTE_Event_Code__c; operation=notEqual; field=NTE_Source_Form_Type__c; operation=equals; value=Exhibitor Application,Partner / Sponsor Application; field=OPPORTUNITY.CLOSED; operation=equals; value=0; field=OPPORTUNITY.WON; operation=equals; value=1; field=NTE_Finance_Invoice_Due__c; operation=equals; value=1.

Columns: OPPORTUNITY.NAME; ACCOUNT.NAME; NTE_Event_Code__c; NTE_Total_Including_VAT__c; NTE_Top_Up_Total_Inc_VAT__c; NTE_Invoice_Provided__c; NTE_Top_Up_Invoice_Provided__c; NTE_Payment_Received__c; NTE_Top_Up_Payment_Received__c; NTE_Pricing_Status__c.

### NTE Logo Updates Due

Object Opportunity. API NTE_Logo_Updates_Due. Scope Everything.

Filter logic: 1 AND 2 AND 3 AND (4 OR 5) AND (6). Criteria: field=OPPORTUNITY.RECORDTYPE; operation=equals; value=Opportunity.NTE_Event_Opportunity; field=NTE_Event_Code__c; operation=notEqual; field=NTE_Source_Form_Type__c; operation=equals; value=Exhibitor Application,Partner / Sponsor Application; field=OPPORTUNITY.CLOSED; operation=equals; value=0; field=OPPORTUNITY.WON; operation=equals; value=1; field=NTE_Logo_Update_Provided__c; operation=equals; value=0.

Columns: OPPORTUNITY.NAME; ACCOUNT.NAME; NTE_Event_Code__c; Booking_Reference__c; NTE_Source_Form_Type__c; NTE_Logo_Update_Provided__c; NTE_Logo_Update_Provided_At__c.

### NTE Payment Confirmed

Object Opportunity. API NTE_Payment_Confirmed. Scope Everything.

Filter logic: 1 AND 2 AND 3 AND (4 OR 5) AND (6). Criteria: field=OPPORTUNITY.RECORDTYPE; operation=equals; value=Opportunity.NTE_Event_Opportunity; field=NTE_Event_Code__c; operation=notEqual; field=NTE_Source_Form_Type__c; operation=equals; value=Exhibitor Application,Partner / Sponsor Application; field=OPPORTUNITY.CLOSED; operation=equals; value=0; field=OPPORTUNITY.WON; operation=equals; value=1; field=NTE_Finance_Payment_Confirmed__c; operation=equals; value=1.

Columns: OPPORTUNITY.NAME; ACCOUNT.NAME; NTE_Event_Code__c; NTE_Total_Including_VAT__c; NTE_Top_Up_Total_Inc_VAT__c; NTE_Invoice_Provided__c; NTE_Top_Up_Invoice_Provided__c; NTE_Payment_Received__c; NTE_Top_Up_Payment_Received__c; NTE_Pricing_Status__c.

### NTE Payment Required

Object Opportunity. API NTE_Payments_Due. Scope Everything.

Filter logic: 1 AND 2 AND 3 AND (4 OR 5) AND (6). Criteria: field=OPPORTUNITY.RECORDTYPE; operation=equals; value=Opportunity.NTE_Event_Opportunity; field=NTE_Event_Code__c; operation=notEqual; field=NTE_Source_Form_Type__c; operation=equals; value=Exhibitor Application,Partner / Sponsor Application; field=OPPORTUNITY.CLOSED; operation=equals; value=0; field=OPPORTUNITY.WON; operation=equals; value=1; field=NTE_Finance_Payment_Due__c; operation=equals; value=1.

Columns: OPPORTUNITY.NAME; ACCOUNT.NAME; NTE_Event_Code__c; NTE_Total_Including_VAT__c; NTE_Top_Up_Total_Inc_VAT__c; NTE_Invoice_Provided__c; NTE_Top_Up_Invoice_Provided__c; NTE_Payment_Received__c; NTE_Top_Up_Payment_Received__c; NTE_Pricing_Status__c.

### NTE Quotes Required

Object Opportunity. API NTE_Quotes_Required. Scope Everything.

Filter logic: 1 AND 2 AND 3 AND (4 OR 5) AND (6 AND 7). Criteria: field=OPPORTUNITY.RECORDTYPE; operation=equals; value=Opportunity.NTE_Event_Opportunity; field=NTE_Event_Code__c; operation=notEqual; field=NTE_Source_Form_Type__c; operation=equals; value=Exhibitor Application,Partner / Sponsor Application; field=OPPORTUNITY.CLOSED; operation=equals; value=0; field=OPPORTUNITY.WON; operation=equals; value=1; field=NTE_Quote_Required_for_PO__c; operation=equals; value=Yes; field=NTE_Quote_Provided__c; operation=equals; value=0.

Columns: OPPORTUNITY.NAME; ACCOUNT.NAME; NTE_Event_Code__c; NTE_Quote_Required_for_PO__c; NTE_Quote_Provided__c; NTE_Total_Including_VAT__c; NTE_Pricing_Status__c.

### NTE Staff Updates Due

Object Opportunity. API NTE_Staff_Updates_Due. Scope Everything.

Filter logic: 1 AND 2 AND 3 AND (4 OR 5) AND (6). Criteria: field=OPPORTUNITY.RECORDTYPE; operation=equals; value=Opportunity.NTE_Event_Opportunity; field=NTE_Event_Code__c; operation=notEqual; field=NTE_Source_Form_Type__c; operation=equals; value=Exhibitor Application,Partner / Sponsor Application; field=OPPORTUNITY.CLOSED; operation=equals; value=0; field=OPPORTUNITY.WON; operation=equals; value=1; field=NTE_Staff_Update_Completed_At__c; operation=equals; value=.

Columns: OPPORTUNITY.NAME; ACCOUNT.NAME; NTE_Event_Code__c; Booking_Reference__c; NTE_Staff_Update_Completed_At__c.

### NTE Staff Top up Invoices Required

Object Opportunity. API NTE_Top_Up_Invoices_Required. Scope Everything.

Filter logic: 1 AND 2 AND 3 AND (4 OR 5) AND 6. Criteria: field=OPPORTUNITY.RECORDTYPE; operation=equals; value=Opportunity.NTE_Event_Opportunity; field=NTE_Event_Code__c; operation=notEqual; field=OPPORTUNITY.STAGE_NAME; operation=notEqual; value=Closed Lost; field=NTE_Top_Up_Invoice_Required__c; operation=equals; value=1; field=NTE_Top_Up_Staff_Total__c; operation=greaterThan; value=0; field=NTE_Top_Up_Invoice_Provided__c; operation=equals; value=0.

Columns: OPPORTUNITY.NAME; ACCOUNT.NAME; NTE_Event_Code__c; NTE_Top_Up_Staff_Total__c; NTE_Top_Up_Invoice_Provided__c; NTE_Top_Up_Payment_Received__c.

### NTE Staff Top up Paid

Object Opportunity. API NTE_Top_Up_Paid. Scope Everything.

Filter logic: 1 AND 2 AND 3 AND (4 OR 5) AND 6 AND 7. Criteria: field=OPPORTUNITY.RECORDTYPE; operation=equals; value=Opportunity.NTE_Event_Opportunity; field=NTE_Event_Code__c; operation=notEqual; field=OPPORTUNITY.STAGE_NAME; operation=notEqual; value=Closed Lost; field=NTE_Top_Up_Invoice_Required__c; operation=equals; value=1; field=NTE_Top_Up_Staff_Total__c; operation=greaterThan; value=0; field=NTE_Top_Up_Invoice_Provided__c; operation=equals; value=1; field=NTE_Top_Up_Payment_Received__c; operation=equals; value=1.

Columns: OPPORTUNITY.NAME; ACCOUNT.NAME; NTE_Event_Code__c; NTE_Top_Up_Staff_Total__c; NTE_Top_Up_Invoice_Provided__c; NTE_Top_Up_Payment_Received__c.

### NTE Staff Top up Payments Due

Object Opportunity. API NTE_Top_Up_Payments_Due. Scope Everything.

Filter logic: 1 AND 2 AND 3 AND (4 OR 5) AND 6 AND 7. Criteria: field=OPPORTUNITY.RECORDTYPE; operation=equals; value=Opportunity.NTE_Event_Opportunity; field=NTE_Event_Code__c; operation=notEqual; field=OPPORTUNITY.STAGE_NAME; operation=notEqual; value=Closed Lost; field=NTE_Top_Up_Invoice_Required__c; operation=equals; value=1; field=NTE_Top_Up_Staff_Total__c; operation=greaterThan; value=0; field=NTE_Top_Up_Invoice_Provided__c; operation=equals; value=1; field=NTE_Top_Up_Payment_Received__c; operation=equals; value=0.

Columns: OPPORTUNITY.NAME; ACCOUNT.NAME; NTE_Event_Code__c; NTE_Top_Up_Staff_Total__c; NTE_Top_Up_Invoice_Provided__c; NTE_Top_Up_Payment_Received__c.

## Record pages and layouts

Dynamic Forms sections below list their actual field order by region. Standard highlights, tabs, related lists and activity components coexist with the custom relationship component. The NTE Management Home uses the supplied full-width Aura template; that template defines one region and no business logic.

### NTE OneRegionHomeTemplate

Source: force-app/main/default/aura/NTE_OneRegionHomeTemplate/NTE_OneRegionHomeTemplate.cmp-meta.xml.

apiVersion=67.0; description=Full-width one-region Home template for the NTE Management app.

### NTE Management Logo

Source: force-app/main/default/contentassets/NTE_Management_Logo.asset-meta.xml.

format=Original; isVisibleByExternalUsers=false; language=en_US; masterLabel=NTE Management Logo; relationships=organization=access=VIEWER; versions=version=number=1; pathOnClient=NTE_Management_Logo.png

### NTE Management Account Record Page

Source: force-app/main/default/flexipages/NTE_Management_Account_Record_Page.flexipage-meta.xml.

Page settings: description=App-scoped NTE workspace for Account records, organised in the order the event team works.; masterLabel=NTE Management Account Record Page; sobjectType=Account; template=name=flexipage:recordHomeTemplateDesktop; type=RecordPage.


| Region | Fields and components in order |
| --- | --- |
| header / Region | force:highlightsPanel: name=actionNames; valueList=valueListItems=value=Edit; value=Global.NewContact; value=Global.NewOpportunity; value=ChangeOwnerOne; value=Global.NewTask; value=Global.NewEvent; value=Delete; name=collapsed; value=false; name=enableActionsConfiguration; value=true; name=enableActionsInNative; value=true; name=hideChatterActions; value=false; name=hideSlackAction; value=false; name=numVisibleActions; value=5 |
| NTE_Section_1_Left / Facet | Record.NTE_Participant__c (name=uiBehavior; value=none); Record.NTE_Source_Form_Type__c (name=uiBehavior; value=none); Record.NTE_Last_Application_Date__c (name=uiBehavior; value=none) |
| NTE_Section_1_Right / Facet | Record.NTE_Event_Code__c (name=uiBehavior; value=none); Record.NTE_Booking_Reference__c (name=uiBehavior; value=none); Record.OwnerId (name=uiBehavior; value=none) |
| NTE_Section_1_Columns / Facet | flexipage:column: name=body; value=NTE_Section_1_Left; flexipage:column: name=body; value=NTE_Section_1_Right |
| NTE_Section_2_Left / Facet | Record.Name (name=uiBehavior; value=none); Record.Type (name=uiBehavior; value=none); Record.AccountSource (name=uiBehavior; value=none); Record.Website (name=uiBehavior; value=none); Record.AnnualRevenue (name=uiBehavior; value=none) |
| NTE_Section_2_Right / Facet | Record.ParentId (name=uiBehavior; value=none); Record.Industry (name=uiBehavior; value=none); Record.Phone (name=uiBehavior; value=none); Record.NumberOfEmployees (name=uiBehavior; value=none); Record.Description (name=uiBehavior; value=none) |
| NTE_Section_2_Columns / Facet | flexipage:column: name=body; value=NTE_Section_2_Left; flexipage:column: name=body; value=NTE_Section_2_Right |
| NTE_Section_3_Left / Facet | Record.RecordTypeId (name=uiBehavior; value=none); Record.LastModifiedById (name=uiBehavior; value=none) |
| NTE_Section_3_Right / Facet | Record.CreatedById (name=uiBehavior; value=none) |
| NTE_Section_3_Columns / Facet | flexipage:column: name=body; value=NTE_Section_3_Left; flexipage:column: name=body; value=NTE_Section_3_Right |
| NTE_Detail_Tab_Content / Facet | flexipage:fieldSection: name=columns; value=NTE_Section_1_Columns; name=horizontalAlignment; value=false; name=label; value=NTE participation; flexipage:fieldSection: name=columns; value=NTE_Section_2_Columns; name=horizontalAlignment; value=false; name=label; value=Organisation details; flexipage:fieldSection: name=columns; value=NTE_Section_3_Columns; name=horizontalAlignment; value=false; name=label; value=Record information; force:recordDetailPanelMobile:  |
| NTE_Related_Tab_Content / Facet | nteRelatedOpportunities: ; force:relatedListContainer: name=relatedListComponentOverride; value=NONE; name=rowsToDisplay; value=10; name=showActionBar; value=true |
| NTE_Main_Tabs / Facet | flexipage:tab: name=active; value=true; name=body; value=NTE_Detail_Tab_Content; name=title; value=Standard.Tab.detail; flexipage:tab: name=body; value=NTE_Related_Tab_Content; name=title; value=Standard.Tab.relatedLists |
| main / Region | flexipage:tabset: name=tabs; value=NTE_Main_Tabs |
| sidebar / Region | runtime_sales_activities:activityPanel: name=showLegacyActivityComposer; value=false; force:relatedListQuickLinksContainer: name=hideHeader; value=false |



### NTE Management Contact Record Page

Source: force-app/main/default/flexipages/NTE_Management_Contact_Record_Page.flexipage-meta.xml.

Page settings: description=App-scoped NTE workspace for Contact records, organised in the order the event team works.; masterLabel=NTE Management Contact Record Page; sobjectType=Contact; template=name=flexipage:recordHomeTemplateDesktop; type=RecordPage.


| Region | Fields and components in order |
| --- | --- |
| header / Region | force:highlightsPanel: name=actionNames; valueList=valueListItems=value=Edit; value=Global.NewTask; value=Global.NewEvent; value=Clone; value=ChangeOwnerOne; value=Delete; name=collapsed; value=false; name=enableActionsConfiguration; value=true; name=enableActionsInNative; value=true; name=hideChatterActions; value=false; name=hideSlackAction; value=false; name=numVisibleActions; value=5 |
| NTE_Section_1_Left / Facet | Record.NTE_Participant__c (name=uiBehavior; value=none); Record.NTE_Source_Form_Type__c (name=uiBehavior; value=none); Record.NTE_Last_Application_Date__c (name=uiBehavior; value=none) |
| NTE_Section_1_Right / Facet | Record.NTE_Event_Code__c (name=uiBehavior; value=none); Record.NTE_Booking_Reference__c (name=uiBehavior; value=none); Record.NTE_Contact_Role__c (name=uiBehavior; value=none) |
| NTE_Section_1_Columns / Facet | flexipage:column: name=body; value=NTE_Section_1_Left; flexipage:column: name=body; value=NTE_Section_1_Right |
| NTE_Section_2_Left / Facet | Record.Name (name=uiBehavior; value=none); Record.Title (name=uiBehavior; value=none); Record.Email (name=uiBehavior; value=none); Record.MobilePhone (name=uiBehavior; value=none); Record.ReportsToId (name=uiBehavior; value=none); Record.AssistantPhone (name=uiBehavior; value=none); Record.OwnerId (name=uiBehavior; value=none) |
| NTE_Section_2_Right / Facet | Record.AccountId (name=uiBehavior; value=none); Record.Department (name=uiBehavior; value=none); Record.Phone (name=uiBehavior; value=none); Record.LeadSource (name=uiBehavior; value=none); Record.AssistantName (name=uiBehavior; value=none); Record.Description (name=uiBehavior; value=none) |
| NTE_Section_2_Columns / Facet | flexipage:column: name=body; value=NTE_Section_2_Left; flexipage:column: name=body; value=NTE_Section_2_Right |
| NTE_Section_3_Left / Facet | Record.RecordTypeId (name=uiBehavior; value=none); Record.LastModifiedById (name=uiBehavior; value=none) |
| NTE_Section_3_Right / Facet | Record.CreatedById (name=uiBehavior; value=none) |
| NTE_Section_3_Columns / Facet | flexipage:column: name=body; value=NTE_Section_3_Left; flexipage:column: name=body; value=NTE_Section_3_Right |
| NTE_Detail_Tab_Content / Facet | flexipage:fieldSection: name=columns; value=NTE_Section_1_Columns; name=horizontalAlignment; value=false; name=label; value=NTE participation; flexipage:fieldSection: name=columns; value=NTE_Section_2_Columns; name=horizontalAlignment; value=false; name=label; value=Contact details; flexipage:fieldSection: name=columns; value=NTE_Section_3_Columns; name=horizontalAlignment; value=false; name=label; value=Record information; force:recordDetailPanelMobile:  |
| NTE_Related_Tab_Content / Facet | nteRelatedOpportunities: ; force:relatedListContainer: name=relatedListComponentOverride; value=NONE; name=rowsToDisplay; value=10; name=showActionBar; value=true |
| NTE_Main_Tabs / Facet | flexipage:tab: name=active; value=true; name=body; value=NTE_Detail_Tab_Content; name=title; value=Standard.Tab.detail; flexipage:tab: name=body; value=NTE_Related_Tab_Content; name=title; value=Standard.Tab.relatedLists |
| main / Region | flexipage:tabset: name=tabs; value=NTE_Main_Tabs |
| sidebar / Region | runtime_sales_activities:activityPanel: name=showLegacyActivityComposer; value=false; force:relatedListQuickLinksContainer: name=hideHeader; value=false |



### NTE Management Home

Source: force-app/main/default/flexipages/NTE_Management_Home.flexipage-meta.xml.

Page settings: masterLabel=NTE Management Home; template=name=c:NTE_OneRegionHomeTemplate; type=HomePage.


| Region | Fields and components in order |
| --- | --- |
| main / Region | nteManagementHome:  |



### NTE Management Lead Record Page

Source: force-app/main/default/flexipages/NTE_Management_Lead_Record_Page.flexipage-meta.xml.

Page settings: description=App-scoped NTE workspace for Lead records, organised in the order the event team works.; masterLabel=NTE Management Lead Record Page; sobjectType=Lead; template=name=flexipage:recordHomeTemplateDesktop; type=RecordPage.


| Region | Fields and components in order |
| --- | --- |
| header / Region | force:highlightsPanel: name=actionNames; valueList=valueListItems=value=Convert; value=Edit; value=Clone; value=ChangeOwnerOne; value=ChangeRecordType; value=Global.NewTask; value=Global.NewEvent; value=Delete; value=Lead.Retry_Update_Email; name=collapsed; value=false; name=enableActionsConfiguration; value=true; name=enableActionsInNative; value=true; name=hideChatterActions; value=false; name=hideSlackAction; value=false; name=numVisibleActions; value=5 |
| NTE_Section_1_Left / Facet | Record.Web_Form_Type__c (name=uiBehavior; value=none); Record.Form_Version__c (name=uiBehavior; value=none); Record.Booking_Reference__c (name=uiBehavior; value=none); Record.NTE_Interest_Progressed__c (name=uiBehavior; value=none); Record.NTE_Application_Rejected__c (name=uiBehavior; value=none); Record.NTE_Applicant_Email_Status__c (name=uiBehavior; value=none); Record.NTE_Email_Error__c (name=uiBehavior; value=none) |
| NTE_Section_1_Right / Facet | Record.NTE_Event_Code__c (name=uiBehavior; value=none); Record.LeadSource (name=uiBehavior; value=none); Record.Status (name=uiBehavior; value=none); Record.NTE_Interest_Not_Progressed__c (name=uiBehavior; value=none); Record.OwnerId (name=uiBehavior; value=none); Record.NTE_Internal_Email_Status__c (name=uiBehavior; value=none) |
| NTE_Section_1_Columns / Facet | flexipage:column: name=body; value=NTE_Section_1_Left; flexipage:column: name=body; value=NTE_Section_1_Right |
| NTE_Section_2_Left / Facet | Record.Name (name=uiBehavior; value=none); Record.Title (name=uiBehavior; value=none); Record.Phone (name=uiBehavior; value=none); Record.Website (name=uiBehavior; value=none); Record.Sponsored_Name__c (name=uiBehavior; value=none) |
| NTE_Section_2_Right / Facet | Record.Company (name=uiBehavior; value=none); Record.Email (name=uiBehavior; value=none); Record.MobilePhone (name=uiBehavior; value=none); Record.Organisation_Type__c (name=uiBehavior; value=none); Record.Alternative_Organisation_Name__c (name=uiBehavior; value=none) |
| NTE_Section_2_Columns / Facet | flexipage:column: name=body; value=NTE_Section_2_Left; flexipage:column: name=body; value=NTE_Section_2_Right |
| NTE_Section_3_Left / Facet | Record.Event_Contact_Name__c (name=uiBehavior; value=none); Record.Event_Contact_Email__c (name=uiBehavior; value=none); Record.Secondary_Contact_Prefix__c (name=uiBehavior; value=none); Record.Secondary_Contact_Title__c (name=uiBehavior; value=none); Record.Secondary_Contact_Mobile__c (name=uiBehavior; value=none) |
| NTE_Section_3_Right / Facet | Record.Event_Contact_Title__c (name=uiBehavior; value=none); Record.Event_Contact_Mobile__c (name=uiBehavior; value=none); Record.Secondary_Contact_Name__c (name=uiBehavior; value=none); Record.Secondary_Contact_Email__c (name=uiBehavior; value=none); Record.Secondary_Contact_Phone__c (name=uiBehavior; value=none) |
| NTE_Section_3_Columns / Facet | flexipage:column: name=body; value=NTE_Section_3_Left; flexipage:column: name=body; value=NTE_Section_3_Right |
| NTE_Section_4_Left / Facet | Record.Partner_Interest_Type__c (name=uiBehavior; value=none); Record.Partnership_Interest_Detail__c (name=uiBehavior; value=none); Record.Exhibitor_Interest_Detail__c (name=uiBehavior; value=none); Record.Preferred_Contact_Method__c (name=uiBehavior; value=none); Record.Contact_Consent__c (name=uiBehavior; value=none); Record.Industry_Body_Details__c (name=uiBehavior; value=none) |
| NTE_Section_4_Right / Facet | Record.Partner_Interest_Areas__c (name=uiBehavior; value=none); Record.Exhibitor_Interest_Areas__c (name=uiBehavior; value=none); Record.Exhibitor_Community_Contribution__c (name=uiBehavior; value=none); Record.Preferred_Contact_Time__c (name=uiBehavior; value=none); Record.Event_Discovery_Source__c (name=uiBehavior; value=none) |
| NTE_Section_4_Columns / Facet | flexipage:column: name=body; value=NTE_Section_4_Left; flexipage:column: name=body; value=NTE_Section_4_Right |
| NTE_Section_5_Left / Facet | Record.Sponsor_Package__c (name=uiBehavior; value=none); Record.Exhibitor_Space_Selections__c (name=uiBehavior; value=none); Record.Exhibitor_Space_Position__c (name=uiBehavior; value=none); Record.Previous_NTE_Events__c (name=uiBehavior; value=none); Record.Power_Socket_Count__c (name=uiBehavior; value=none); Record.Stand_Special_Requirements__c (name=uiBehavior; value=none); Record.Stand_Extra_Notes__c (name=uiBehavior; value=none); Record.Total_Staff_Count__c (name=uiBehavior; value=none); Record.Additional_Staff_Required__c (name=uiBehavior; value=none); Record.Staff_Update_Audience__c (name=uiBehavior; value=none); Record.Top_Up_Staff_Required__c (name=uiBehavior; value=none); Record.Top_Up_Staff_Names__c (name=uiBehavior; value=none); Record.Has_Special_Requirements__c (name=uiBehavior; value=none); Record.Declaration_Name__c (name=uiBehavior; value=none); Record.Terms_and_Conditions__c (name=uiBehavior; value=none) |
| NTE_Section_5_Right / Facet | Record.Exhibitor_Organisation_Category__c (name=uiBehavior; value=none); Record.Exhibitor_Space_Size__c (name=uiBehavior; value=none); Record.Exhibitor_Hall_Schedule__c (name=uiBehavior; value=none); Record.Stand_Power__c (name=uiBehavior; value=none); Record.Stand_Equipment__c (name=uiBehavior; value=none); Record.Stand_Colleagues__c (name=uiBehavior; value=none); Record.Planned_Exhibitor_Count__c (name=uiBehavior; value=none); Record.Included_Staff_Count__c (name=uiBehavior; value=none); Record.Additional_Staff_Count__c (name=uiBehavior; value=none); Record.Staff_Base_Names__c (name=uiBehavior; value=none); Record.Top_Up_Staff_Count__c (name=uiBehavior; value=none); Record.Heavy_Vehicle_Required__c (name=uiBehavior; value=none); Record.Logo_Upload_URL__c (name=uiBehavior; value=none); Record.Declaration_Date__c (name=uiBehavior; value=none) |
| NTE_Section_5_Columns / Facet | flexipage:column: name=body; value=NTE_Section_5_Left; flexipage:column: name=body; value=NTE_Section_5_Right |
| NTE_Section_6_Left / Facet | Record.Guest_Accompanying__c (name=uiBehavior; value=none); Record.Accompanying_Guest_Email__c (name=uiBehavior; value=none); Record.Guest_Accessibility_Details__c (name=uiBehavior; value=none) |
| NTE_Section_6_Right / Facet | Record.Accompanying_Guest_Name__c (name=uiBehavior; value=none); Record.Guest_Accessibility_Required__c (name=uiBehavior; value=none); Record.Guest_Information_Declaration__c (name=uiBehavior; value=none) |
| NTE_Section_6_Columns / Facet | flexipage:column: name=body; value=NTE_Section_6_Left; flexipage:column: name=body; value=NTE_Section_6_Right |
| NTE_Section_7_Left / Facet | Record.Sponsor_Package_Total__c (name=uiBehavior; value=none); Record.Power_Socket_Unit_Price__c (name=uiBehavior; value=none); Record.Additional_Staff_Unit_Price__c (name=uiBehavior; value=none); Record.Top_Up_Staff_Unit_Price__c (name=uiBehavior; value=none); Record.Listed_Price_Total__c (name=uiBehavior; value=none); Record.VAT_Total__c (name=uiBehavior; value=none); Record.Top_Up_VAT_Total__c (name=uiBehavior; value=none); Record.Pricing_Status__c (name=uiBehavior; value=none) |
| NTE_Section_7_Right / Facet | Record.Exhibitor_Space_Price__c (name=uiBehavior; value=none); Record.Power_Socket_Total__c (name=uiBehavior; value=none); Record.Additional_Staff_Total__c (name=uiBehavior; value=none); Record.Top_Up_Staff_Total__c (name=uiBehavior; value=none); Record.VAT_Rate__c (name=uiBehavior; value=none); Record.Total_Including_VAT__c (name=uiBehavior; value=none); Record.Top_Up_Total_Inc_VAT__c (name=uiBehavior; value=none); Record.Pricing_Version__c (name=uiBehavior; value=none) |
| NTE_Section_7_Columns / Facet | flexipage:column: name=body; value=NTE_Section_7_Left; flexipage:column: name=body; value=NTE_Section_7_Right |
| NTE_Section_8_Left / Facet | Record.Invoice_Required__c (name=uiBehavior; value=none); Record.Invoiced_Company__c (name=uiBehavior; value=none); Record.Invoice_Address__c (name=uiBehavior; value=none); Record.Invoiced_Email__c (name=uiBehavior; value=none); Record.Purchase_Order__c (name=uiBehavior; value=none); Record.Quote_Required_for_PO__c (name=uiBehavior; value=none); Record.Supplier_Agreement_Required__c (name=uiBehavior; value=none) |
| NTE_Section_8_Right / Facet | Record.Payment_Method__c (name=uiBehavior; value=none); Record.Trading_Name__c (name=uiBehavior; value=none); Record.Invoiced_Person__c (name=uiBehavior; value=none); Record.Invoice_Contact_Phone__c (name=uiBehavior; value=none); Record.Purchase_Order_Number__c (name=uiBehavior; value=none); Record.Invoice_Additional_Information__c (name=uiBehavior; value=none) |
| NTE_Section_8_Columns / Facet | flexipage:column: name=body; value=NTE_Section_8_Left; flexipage:column: name=body; value=NTE_Section_8_Right |
| NTE_Section_9_Left / Facet | Record.Delivery_Window__c (name=uiBehavior; value=none); Record.Heavy_Item_1_Registration__c (name=uiBehavior; value=none); Record.Heavy_Item_1_Gross_Weight__c (name=uiBehavior; value=none); Record.Heavy_Item_2_Registration__c (name=uiBehavior; value=none); Record.Heavy_Item_2_Gross_Weight__c (name=uiBehavior; value=none); Record.Heavy_Item_3_Registration__c (name=uiBehavior; value=none); Record.Heavy_Item_3_Gross_Weight__c (name=uiBehavior; value=none); Record.Haulier_Staff__c (name=uiBehavior; value=none); Record.Haulier_Vehicle_Gross_Weight__c (name=uiBehavior; value=none); Record.Haulier_Vehicle_Registration__c (name=uiBehavior; value=none) |
| NTE_Section_9_Right / Facet | Record.Heavy_Item_1_Description__c (name=uiBehavior; value=none); Record.Heavy_Item_1_Dimensions__c (name=uiBehavior; value=none); Record.Heavy_Item_2_Description__c (name=uiBehavior; value=none); Record.Heavy_Item_2_Dimensions__c (name=uiBehavior; value=none); Record.Heavy_Item_3_Description__c (name=uiBehavior; value=none); Record.Heavy_Item_3_Dimensions__c (name=uiBehavior; value=none); Record.Haulier_Name__c (name=uiBehavior; value=none); Record.Haulier_Vehicle_Type__c (name=uiBehavior; value=none); Record.Haulier_Vehicle_Dimensions__c (name=uiBehavior; value=none) |
| NTE_Section_9_Columns / Facet | flexipage:column: name=body; value=NTE_Section_9_Left; flexipage:column: name=body; value=NTE_Section_9_Right |
| NTE_Section_10_Left / Facet | Record.Target_Booking_Reference__c (name=uiBehavior; value=none); Record.NTE_Update_Booking_Id__c (name=uiBehavior; value=readonly); Record.CreatedById (name=uiBehavior; value=none) |
| NTE_Section_10_Right / Facet | Record.NTE_Update_Status__c (name=uiBehavior; value=none); Record.NTE_Update_Error__c (name=uiBehavior; value=none); Record.LastModifiedById (name=uiBehavior; value=none) |
| NTE_Section_10_Columns / Facet | flexipage:column: name=body; value=NTE_Section_10_Left; flexipage:column: name=body; value=NTE_Section_10_Right |
| NTE_Detail_Tab_Content / Facet | flexipage:fieldSection: name=columns; value=NTE_Section_1_Columns; name=horizontalAlignment; value=false; name=label; value=Submission and ownership; flexipage:fieldSection: name=columns; value=NTE_Section_2_Columns; name=horizontalAlignment; value=false; name=label; value=Person and organisation; flexipage:fieldSection: name=columns; value=NTE_Section_3_Columns; name=horizontalAlignment; value=false; name=label; value=Event contacts; flexipage:fieldSection: name=columns; value=NTE_Section_4_Columns; name=horizontalAlignment; value=false; name=label; value=Expressions of interest; flexipage:fieldSection: name=columns; value=NTE_Section_5_Columns; name=horizontalAlignment; value=false; name=label; value=Partnership and exhibition application; flexipage:fieldSection: name=columns; value=NTE_Section_6_Columns; name=horizontalAlignment; value=false; name=label; value=Guest registration; flexipage:fieldSection: name=columns; value=NTE_Section_7_Columns; name=horizontalAlignment; value=false; name=label; value=Pricing; flexipage:fieldSection: name=columns; value=NTE_Section_8_Columns; name=horizontalAlignment; value=false; name=label; value=Invoicing and procurement; flexipage:fieldSection: name=columns; value=NTE_Section_9_Columns; name=horizontalAlignment; value=false; name=label; value=Heavy vehicle and logistics; flexipage:fieldSection: name=columns; value=NTE_Section_10_Columns; name=horizontalAlignment; value=false; name=label; value=Processing and conversion; force:recordDetailPanelMobile:  |
| NTE_Related_Tab_Content / Facet | force:relatedListContainer: name=relatedListComponentOverride; value=NONE; name=rowsToDisplay; value=10; name=showActionBar; value=true |
| NTE_Main_Tabs / Facet | flexipage:tab: name=active; value=true; name=body; value=NTE_Detail_Tab_Content; name=title; value=Standard.Tab.detail; flexipage:tab: name=body; value=NTE_Related_Tab_Content; name=title; value=Standard.Tab.relatedLists |
| main / Region | flexipage:tabset: name=tabs; value=NTE_Main_Tabs |
| sidebar / Region | runtime_sales_activities:activityPanel: name=showLegacyActivityComposer; value=false; force:relatedListQuickLinksContainer: name=hideHeader; value=false |



### NTE Management Opportunity Record Page

Source: force-app/main/default/flexipages/NTE_Management_Opportunity_Record_Page.flexipage-meta.xml.

Page settings: description=App-scoped NTE workspace for Opportunity records, organised in the order the event team works.; masterLabel=NTE Management Opportunity Record Page; sobjectType=Opportunity; template=name=flexipage:recordHomeTemplateDesktop; type=RecordPage.


| Region | Fields and components in order |
| --- | --- |
| header / Region | force:highlightsPanel: name=actionNames; valueList=valueListItems=value=Edit; value=Clone; value=ChangeOwnerOne; value=ChangeRecordType; value=Global.NewTask; value=Global.NewEvent; value=Delete; value=Opportunity.Retry_Booking_Email; name=collapsed; value=false; name=enableActionsConfiguration; value=true; name=enableActionsInNative; value=true; name=hideChatterActions; value=false; name=hideSlackAction; value=false; name=numVisibleActions; value=5 |
| NTE_Section_1_Left / Facet | Record.AccountId (name=uiBehavior; value=none); Record.CloseDate (name=uiBehavior; value=none); Record.Type (name=uiBehavior; value=none); Record.CampaignId (name=uiBehavior; value=none); Record.Booking_Reference__c (name=uiBehavior; value=none); Record.NTE_Source_Form_Type__c (name=uiBehavior; value=none); Record.NTE_Attendance_Status__c (name=uiBehavior; value=none); Record.ForecastCategoryName (name=uiBehavior; value=none) |
| NTE_Section_1_Right / Facet | Record.StageName (name=uiBehavior; value=none); Record.Amount (name=uiBehavior; value=none); Record.LeadSource (name=uiBehavior; value=none); Record.OwnerId (name=uiBehavior; value=none); Record.NTE_Event_Code__c (name=uiBehavior; value=none); Record.NTE_Form_Version__c (name=uiBehavior; value=none); Record.Probability (name=uiBehavior; value=none); Record.NextStep (name=uiBehavior; value=none) |
| NTE_Section_1_Columns / Facet | flexipage:column: name=body; value=NTE_Section_1_Left; flexipage:column: name=body; value=NTE_Section_1_Right |
| NTE_Section_2_Left / Facet | Record.NTE_Event_Contact_Name__c (name=uiBehavior; value=none); Record.NTE_Event_Contact_Email__c (name=uiBehavior; value=none); Record.NTE_Secondary_Contact_Prefix__c (name=uiBehavior; value=none); Record.NTE_Secondary_Contact_Title__c (name=uiBehavior; value=none); Record.NTE_Secondary_Contact_Mobile__c (name=uiBehavior; value=none) |
| NTE_Section_2_Right / Facet | Record.NTE_Event_Contact_Title__c (name=uiBehavior; value=none); Record.NTE_Event_Contact_Mobile__c (name=uiBehavior; value=none); Record.NTE_Secondary_Contact_Name__c (name=uiBehavior; value=none); Record.NTE_Secondary_Contact_Email__c (name=uiBehavior; value=none); Record.NTE_Secondary_Contact_Phone__c (name=uiBehavior; value=none) |
| NTE_Section_2_Columns / Facet | flexipage:column: name=body; value=NTE_Section_2_Left; flexipage:column: name=body; value=NTE_Section_2_Right |
| NTE_Section_3_Left / Facet | Record.NTE_Sponsored_Name__c (name=uiBehavior; value=none); Record.NTE_Sponsor_Package__c (name=uiBehavior; value=none); Record.NTE_Industry_Body_Details__c (name=uiBehavior; value=none); Record.NTE_Declaration_Date__c (name=uiBehavior; value=none) |
| NTE_Section_3_Right / Facet | Record.NTE_Alternative_Organisation_Name__c (name=uiBehavior; value=none); Record.NTE_Event_Discovery_Source__c (name=uiBehavior; value=none); Record.NTE_Declaration_Name__c (name=uiBehavior; value=none); Record.NTE_Terms_Accepted__c (name=uiBehavior; value=none) |
| NTE_Section_3_Columns / Facet | flexipage:column: name=body; value=NTE_Section_3_Left; flexipage:column: name=body; value=NTE_Section_3_Right |
| NTE_Section_4_Left / Facet | Record.NTE_Exhibitor_Organisation_Category__c (name=uiBehavior; value=none); Record.NTE_Exhibitor_Space_Size__c (name=uiBehavior; value=none); Record.NTE_Exhibitor_Hall_Schedule__c (name=uiBehavior; value=none); Record.NTE_Has_Special_Requirements__c (name=uiBehavior; value=none) |
| NTE_Section_4_Right / Facet | Record.NTE_Exhibitor_Space_Selections__c (name=uiBehavior; value=none); Record.NTE_Exhibitor_Space_Position__c (name=uiBehavior; value=none); Record.NTE_Previous_Events__c (name=uiBehavior; value=none) |
| NTE_Section_4_Columns / Facet | flexipage:column: name=body; value=NTE_Section_4_Left; flexipage:column: name=body; value=NTE_Section_4_Right |
| NTE_Section_5_Left / Facet | Record.NTE_Stand_Power__c (name=uiBehavior; value=none); Record.NTE_Stand_Equipment__c (name=uiBehavior; value=none); Record.NTE_Stand_Colleagues__c (name=uiBehavior; value=none); Record.NTE_Planned_Exhibitor_Count__c (name=uiBehavior; value=none); Record.NTE_Included_Staff_Count__c (name=uiBehavior; value=none); Record.NTE_Additional_Staff_Required__c (name=uiBehavior; value=none); Record.NTE_Top_Up_Staff_Required__c (name=uiBehavior; value=none); Record.NTE_Top_Up_Staff_Names__c (name=uiBehavior; value=none) |
| NTE_Section_5_Right / Facet | Record.NTE_Power_Socket_Count__c (name=uiBehavior; value=none); Record.NTE_Stand_Special_Requirements__c (name=uiBehavior; value=none); Record.NTE_Stand_Extra_Notes__c (name=uiBehavior; value=none); Record.NTE_Initial_Staff_Count__c (name=uiBehavior; value=none); Record.NTE_Total_Staff_Count__c (name=uiBehavior; value=none); Record.NTE_Additional_Staff_Count__c (name=uiBehavior; value=none); Record.NTE_Top_Up_Staff_Count__c (name=uiBehavior; value=none); Record.NTE_Heavy_Vehicle_Required__c (name=uiBehavior; value=none) |
| NTE_Section_5_Columns / Facet | flexipage:column: name=body; value=NTE_Section_5_Left; flexipage:column: name=body; value=NTE_Section_5_Right |
| NTE_Section_6_Left / Facet | Record.NTE_Sponsor_Package_Total__c (name=uiBehavior; value=none); Record.NTE_Power_Socket_Unit_Price__c (name=uiBehavior; value=none); Record.NTE_Additional_Staff_Unit_Price__c (name=uiBehavior; value=none); Record.NTE_Top_Up_Staff_Unit_Price__c (name=uiBehavior; value=none); Record.NTE_Listed_Price_Total__c (name=uiBehavior; value=none); Record.NTE_VAT_Total__c (name=uiBehavior; value=none); Record.NTE_Top_Up_VAT_Rate__c (name=uiBehavior; value=none); Record.NTE_Top_Up_Total_Inc_VAT__c (name=uiBehavior; value=none); Record.NTE_Pricing_Version__c (name=uiBehavior; value=none) |
| NTE_Section_6_Right / Facet | Record.NTE_Exhibitor_Space_Price__c (name=uiBehavior; value=none); Record.NTE_Power_Socket_Total__c (name=uiBehavior; value=none); Record.NTE_Additional_Staff_Total__c (name=uiBehavior; value=none); Record.NTE_Top_Up_Staff_Total__c (name=uiBehavior; value=none); Record.NTE_VAT_Rate__c (name=uiBehavior; value=none); Record.NTE_Total_Including_VAT__c (name=uiBehavior; value=none); Record.NTE_Top_Up_VAT_Total__c (name=uiBehavior; value=none); Record.NTE_Pricing_Status__c (name=uiBehavior; value=none) |
| NTE_Section_6_Columns / Facet | flexipage:column: name=body; value=NTE_Section_6_Left; flexipage:column: name=body; value=NTE_Section_6_Right |
| NTE_Section_7_Left / Facet | Record.NTE_Invoice_Required__c (name=uiBehavior; value=none); Record.NTE_Invoiced_Company__c (name=uiBehavior; value=none); Record.NTE_Invoice_Address__c (name=uiBehavior; value=none); Record.NTE_Invoiced_Email__c (name=uiBehavior; value=none); Record.NTE_Purchase_Order__c (name=uiBehavior; value=none); Record.NTE_Quote_Required_for_PO__c (name=uiBehavior; value=none); Record.NTE_Supplier_Agreement_Required__c (name=uiBehavior; value=none); Record.NTE_Quote_Provided_At__c (name=uiBehavior; value=none); Record.NTE_Invoice_Provided__c (name=uiBehavior; value=none); Record.NTE_Invoice_Provided_By__c (name=uiBehavior; value=none); Record.NTE_Payment_Received_At__c (name=uiBehavior; value=none); Record.NTE_Top_Up_Invoice_Required__c (name=uiBehavior; value=none); Record.NTE_Top_Up_Invoice_At__c (name=uiBehavior; value=none); Record.NTE_Top_Up_Payment_Received__c (name=uiBehavior; value=none); Record.NTE_Top_Up_Payment_By__c (name=uiBehavior; value=none) |
| NTE_Section_7_Right / Facet | Record.NTE_Payment_Method__c (name=uiBehavior; value=none); Record.NTE_Trading_Name__c (name=uiBehavior; value=none); Record.NTE_Invoiced_Person__c (name=uiBehavior; value=none); Record.NTE_Invoice_Contact_Phone__c (name=uiBehavior; value=none); Record.NTE_Purchase_Order_Number__c (name=uiBehavior; value=none); Record.NTE_Invoice_Additional_Information__c (name=uiBehavior; value=none); Record.NTE_Quote_Provided__c (name=uiBehavior; value=none); Record.NTE_Quote_Provided_By__c (name=uiBehavior; value=none); Record.NTE_Invoice_Provided_At__c (name=uiBehavior; value=none); Record.NTE_Payment_Received__c (name=uiBehavior; value=none); Record.NTE_Payment_Recorded_By__c (name=uiBehavior; value=none); Record.NTE_Top_Up_Invoice_Provided__c (name=uiBehavior; value=none); Record.NTE_Top_Up_Invoice_By__c (name=uiBehavior; value=none); Record.NTE_Top_Up_Payment_At__c (name=uiBehavior; value=none) |
| NTE_Section_7_Columns / Facet | flexipage:column: name=body; value=NTE_Section_7_Left; flexipage:column: name=body; value=NTE_Section_7_Right |
| NTE_Section_8_Left / Facet | Record.NTE_Delivery_Window__c (name=uiBehavior; value=none); Record.NTE_Heavy_Item_1_Registration__c (name=uiBehavior; value=none); Record.NTE_Heavy_Item_1_Gross_Weight__c (name=uiBehavior; value=none); Record.NTE_Heavy_Item_2_Registration__c (name=uiBehavior; value=none); Record.NTE_Heavy_Item_2_Gross_Weight__c (name=uiBehavior; value=none); Record.NTE_Heavy_Item_3_Registration__c (name=uiBehavior; value=none); Record.NTE_Heavy_Item_3_Gross_Weight__c (name=uiBehavior; value=none); Record.NTE_Haulier_Staff__c (name=uiBehavior; value=none); Record.NTE_Haulier_Vehicle_Gross_Weight__c (name=uiBehavior; value=none); Record.NTE_Haulier_Vehicle_Registration__c (name=uiBehavior; value=none) |
| NTE_Section_8_Right / Facet | Record.NTE_Heavy_Item_1_Description__c (name=uiBehavior; value=none); Record.NTE_Heavy_Item_1_Dimensions__c (name=uiBehavior; value=none); Record.NTE_Heavy_Item_2_Description__c (name=uiBehavior; value=none); Record.NTE_Heavy_Item_2_Dimensions__c (name=uiBehavior; value=none); Record.NTE_Heavy_Item_3_Description__c (name=uiBehavior; value=none); Record.NTE_Heavy_Item_3_Dimensions__c (name=uiBehavior; value=none); Record.NTE_Haulier_Name__c (name=uiBehavior; value=none); Record.NTE_Haulier_Vehicle_Type__c (name=uiBehavior; value=none); Record.NTE_Haulier_Vehicle_Dimensions__c (name=uiBehavior; value=none) |
| NTE_Section_8_Columns / Facet | flexipage:column: name=body; value=NTE_Section_8_Left; flexipage:column: name=body; value=NTE_Section_8_Right |
| NTE_Section_9_Left / Facet | Record.NTE_Staff_Update_Completed_At__c (name=uiBehavior; value=none); Record.NTE_Logo_Update_Provided__c (name=uiBehavior; value=none); Record.NTE_Last_Update_Type__c (name=uiBehavior; value=none); Record.NTE_Last_Update_Processed_At__c (name=uiBehavior; value=none); Record.NTE_Last_Update_Declaration_Date__c (name=uiBehavior; value=none); Record.Description (name=uiBehavior; value=none); Record.LastModifiedById (name=uiBehavior; value=none) |
| NTE_Section_9_Right / Facet | Record.NTE_Heavy_Vehicle_Update_Completed_At__c (name=uiBehavior; value=none); Record.NTE_Logo_Update_Provided_At__c (name=uiBehavior; value=none); Record.NTE_Last_Update_Form_Version__c (name=uiBehavior; value=none); Record.NTE_Last_Update_Declaration_Name__c (name=uiBehavior; value=none); Record.NTE_Last_Update_Error__c (name=uiBehavior; value=none); Record.CreatedById (name=uiBehavior; value=none) |
| NTE_Section_9_Columns / Facet | flexipage:column: name=body; value=NTE_Section_9_Left; flexipage:column: name=body; value=NTE_Section_9_Right |
| NTE_Detail_Tab_Content / Facet | flexipage:fieldSection: name=columns; value=NTE_Section_1_Columns; name=horizontalAlignment; value=false; name=label; value=Booking and commercial status; flexipage:fieldSection: name=columns; value=NTE_Section_2_Columns; name=horizontalAlignment; value=false; name=label; value=Event contacts; flexipage:fieldSection: name=columns; value=NTE_Section_3_Columns; name=horizontalAlignment; value=false; name=label; value=Partnership and sponsorship; flexipage:fieldSection: name=columns; value=NTE_Section_4_Columns; name=horizontalAlignment; value=false; name=label; value=Exhibition space; flexipage:fieldSection: name=columns; value=NTE_Section_5_Columns; name=horizontalAlignment; value=false; name=label; value=Stand requirements and staff; flexipage:fieldSection: name=columns; value=NTE_Section_6_Columns; name=horizontalAlignment; value=false; name=label; value=Pricing; flexipage:fieldSection: name=columns; value=NTE_Section_7_Columns; name=horizontalAlignment; value=false; name=label; value=Invoicing and procurement; flexipage:fieldSection: name=columns; value=NTE_Section_8_Columns; name=horizontalAlignment; value=false; name=label; value=Heavy vehicle and logistics; flexipage:fieldSection: name=columns; value=NTE_Section_9_Columns; name=horizontalAlignment; value=false; name=label; value=Update audit; force:recordDetailPanelMobile:  |
| NTE_Related_Tab_Content / Facet | nteRelatedOpportunities: ; force:relatedListContainer: name=relatedListComponentOverride; value=NONE; name=rowsToDisplay; value=10; name=showActionBar; value=true |
| NTE_Main_Tabs / Facet | flexipage:tab: name=active; value=true; name=body; value=NTE_Detail_Tab_Content; name=title; value=Standard.Tab.detail; flexipage:tab: name=body; value=NTE_Related_Tab_Content; name=title; value=Standard.Tab.relatedLists |
| main / Region | flexipage:tabset: name=tabs; value=NTE_Main_Tabs |
| sidebar / Region | runtime_sales_activities:activityPanel: name=showLegacyActivityComposer; value=false; force:relatedListQuickLinksContainer: name=hideHeader; value=false |



### NTE Email Dispatch-NTE Email Dispatch

Source: force-app/main/default/layouts/NTE_Email_Dispatch__c-NTE Email Dispatch.layout-meta.xml.

Section Email details; OneColumn.

Column 1: layoutItems=behavior=Readonly; field=Name; behavior=Readonly; field=Kind__c; behavior=Readonly; field=Status__c; behavior=Readonly; field=Recipient__c; behavior=Readonly; field=Contact__c; behavior=Readonly; field=Lead__c; behavior=Readonly; field=Opportunity__c; behavior=Readonly; field=Event_Code__c; behavior=Readonly; field=Subject__c; behavior=Readonly; field=Message__c; behavior=Readonly; field=Link__c; behavior=Readonly; field=Sent_At__c; behavior=Readonly; field=Error__c.

Other layout settings: platformActionList=actionListContext=Record; platformActionListItems=actionName=NTE_Email_Dispatch__c.Retry_Email; actionType=QuickAction; sortOrder=0; showEmailCheckbox=false; showHighlightsPanel=false; showInteractionLogPanel=false; showRunAssignmentRulesCheckbox=false; showSubmitAndAttachButton=false.

### NTE Payment Request-NTE Payment Request

Source: force-app/main/default/layouts/NTE_Payment_Request__c-NTE Payment Request.layout-meta.xml.

Section Payment request; OneColumn.

Column 1: layoutItems=behavior=Readonly; field=Name; behavior=Readonly; field=Opportunity__c; behavior=Readonly; field=Charge_Key__c; behavior=Readonly; field=Kind__c; behavior=Readonly; field=Status__c; behavior=Readonly; field=Live_Mode__c; behavior=Readonly; field=Amount_Minor__c; behavior=Readonly; field=Net_Minor__c; behavior=Readonly; field=Tax_Rate__c; behavior=Readonly; field=Currency__c; behavior=Readonly; field=Stripe_Account__c; behavior=Readonly; field=Source_Fingerprint__c; behavior=Readonly; field=Source_Lead_Id__c; behavior=Readonly; field=Reference__c; behavior=Readonly; field=Description__c; behavior=Readonly; field=Price_Id__c; behavior=Readonly; field=Link_Id__c; behavior=Readonly; field=Payment_URL__c; behavior=Readonly; field=First_Attempt_At__c; behavior=Readonly; field=Verified_At__c; behavior=Readonly; field=Error__c; behavior=Readonly; field=Delivered_At__c; behavior=Readonly; field=Recipient__c; behavior=Readonly; field=Batch_Key__c.

Other layout settings: showEmailCheckbox=false; showHighlightsPanel=false; showInteractionLogPanel=false; showRunAssignmentRulesCheckbox=false; showSubmitAndAttachButton=false.

### NTE Management Logo

Source: force-app/main/default/staticresources/NTE_Management_Logo.resource-meta.xml.

cacheControl=Public; contentType=image/png

### NTE Master Panel

Source: force-app/main/default/tabs/NTE_Master_Panel.tab-meta.xml.

label=Master Panel; lwcComponent=nteMasterPanel; motif=Custom75: Ticket
