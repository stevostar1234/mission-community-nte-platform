# Flow and declarative automation reference

All four packaged flows are active after-save record-triggered flows. Their start criteria and assignments are reproduced here so an administrator can rebuild the same control flow. No Apex trigger source is present in this package. The order within a flow is explicit; ordering relative to unrelated target-org automation must be assessed in that target.

## NTE Copy Converted Lead to Opportunity

API name: NTE_Copy_Converted_Lead_to_Opportunity. API version 67.0. Status Active.

Copies NTE application and event fields to the converted Opportunity and classifies the resulting Account and Contact for the NTE workspace. This avoids changing the org-wide LeadConvertSettings owned by another administrator.

Start: Lead Update; RecordAfterSave; changed-to-meet-criteria=true. Filter logic: 1 AND 2 AND (3 OR 4).


| Criterion | Field | Operator | Value |
| --- | --- | --- | --- |
| 1 | IsConverted | EqualTo | true |
| 2 | ConvertedOpportunityId | IsNull | false |
| 3 | Web_Form_Type__c | EqualTo | Partner / Sponsor Application |
| 4 | Web_Form_Type__c | EqualTo | Exhibitor Application |



Sequence: Price_Application_For_Conversion → Get_NTE_Opportunity_Record_Type → Update_Converted_Opportunity → Send_Exhibitor_Approval_Email → Classify_Converted_Account → Classify_Converted_Contact.

### Price Application For Conversion

Element type: actionCalls. Label: Calculate Current Application Price.

Apex action: NTEPricingService. Transaction: CurrentTransaction.


| Input | Value |
| --- | --- |
| leadId | $Record.Id |



Output pricedLead → Priced_Application.

### Get NTE Opportunity Record Type

Element type: recordLookups. Label: Get NTE Opportunity Record Type.

Object: RecordType. Filters: SobjectType EqualTo Opportunity; DeveloperName EqualTo NTE_Event_Opportunity.

First record only=true; store output automatically=true.

### Update Converted Opportunity

Element type: recordUpdates. Label: Update Converted Opportunity.

Object: Opportunity. Filters: Id EqualTo $Record.ConvertedOpportunityId.


| Destination field | Assigned value |
| --- | --- |
| RecordTypeId | Get_NTE_Opportunity_Record_Type.Id |
| Booking_Reference__c | $Record.Booking_Reference__c |
| NTE_Event_Code__c | $Record.NTE_Event_Code__c |
| NTE_Source_Form_Type__c | $Record.Web_Form_Type__c |
| NTE_Form_Version__c | $Record.Form_Version__c |
| NTE_Declaration_Date__c | $Record.Declaration_Date__c |
| NTE_Event_Contact_Name__c | $Record.Event_Contact_Name__c |
| NTE_Event_Contact_Title__c | $Record.Event_Contact_Title__c |
| NTE_Event_Contact_Email__c | $Record.Event_Contact_Email__c |
| NTE_Event_Contact_Mobile__c | $Record.Event_Contact_Mobile__c |
| NTE_Sponsored_Name__c | $Record.Sponsored_Name__c |
| NTE_Alternative_Organisation_Name__c | $Record.Alternative_Organisation_Name__c |
| NTE_Trading_Name__c | $Record.Trading_Name__c |
| NTE_Secondary_Contact_Prefix__c | $Record.Secondary_Contact_Prefix__c |
| NTE_Secondary_Contact_Name__c | $Record.Secondary_Contact_Name__c |
| NTE_Secondary_Contact_Title__c | $Record.Secondary_Contact_Title__c |
| NTE_Secondary_Contact_Email__c | $Record.Secondary_Contact_Email__c |
| NTE_Secondary_Contact_Mobile__c | $Record.Secondary_Contact_Mobile__c |
| NTE_Secondary_Contact_Phone__c | $Record.Secondary_Contact_Phone__c |
| NTE_Exhibitor_Hall_Schedule__c | $Record.Exhibitor_Hall_Schedule__c |
| NTE_Has_Special_Requirements__c | $Record.Has_Special_Requirements__c |
| NTE_Industry_Body_Details__c | $Record.Industry_Body_Details__c |
| NTE_Event_Discovery_Source__c | $Record.Event_Discovery_Source__c |
| NTE_Declaration_Name__c | $Record.Declaration_Name__c |
| NTE_Terms_Accepted__c | $Record.Terms_and_Conditions__c |
| NTE_Sponsor_Package__c | $Record.Sponsor_Package__c |
| NTE_Exhibitor_Organisation_Category__c | $Record.Exhibitor_Organisation_Category__c |
| NTE_Exhibitor_Space_Selections__c | $Record.Exhibitor_Space_Selections__c |
| NTE_Exhibitor_Space_Size__c | $Record.Exhibitor_Space_Size__c |
| NTE_Exhibitor_Space_Position__c | $Record.Exhibitor_Space_Position__c |
| NTE_Previous_Events__c | $Record.Previous_NTE_Events__c |
| NTE_Stand_Power__c | $Record.Stand_Power__c |
| NTE_Power_Socket_Count__c | $Record.Power_Socket_Count__c |
| NTE_Stand_Equipment__c | $Record.Stand_Equipment__c |
| NTE_Stand_Special_Requirements__c | $Record.Stand_Special_Requirements__c |
| NTE_Stand_Colleagues__c | $Record.Stand_Colleagues__c |
| NTE_Stand_Extra_Notes__c | $Record.Stand_Extra_Notes__c |
| NTE_Planned_Exhibitor_Count__c | $Record.Planned_Exhibitor_Count__c |
| NTE_Initial_Staff_Count__c | Priced_Application.Total_Staff_Count__c |
| NTE_Included_Staff_Count__c | Priced_Application.Included_Staff_Count__c |
| NTE_Total_Staff_Count__c | Priced_Application.Total_Staff_Count__c |
| NTE_Additional_Staff_Required__c | Priced_Application.Additional_Staff_Required__c |
| NTE_Additional_Staff_Count__c | Priced_Application.Additional_Staff_Count__c |
| NTE_Sponsor_Package_Total__c | Priced_Application.Sponsor_Package_Total__c |
| NTE_Exhibitor_Space_Price__c | Priced_Application.Exhibitor_Space_Price__c |
| NTE_Power_Socket_Unit_Price__c | Priced_Application.Power_Socket_Unit_Price__c |
| NTE_Power_Socket_Total__c | Priced_Application.Power_Socket_Total__c |
| NTE_Additional_Staff_Unit_Price__c | Priced_Application.Additional_Staff_Unit_Price__c |
| NTE_Additional_Staff_Total__c | Priced_Application.Additional_Staff_Total__c |
| NTE_Listed_Price_Total__c | Priced_Application.Listed_Price_Total__c |
| NTE_Pricing_Status__c | Priced_Application.Pricing_Status__c |
| NTE_Pricing_Version__c | Priced_Application.Pricing_Version__c |
| Amount | Priced_Application.Total_Including_VAT__c |
| NTE_VAT_Rate__c | Priced_Application.VAT_Rate__c |
| NTE_Heavy_Vehicle_Required__c | $Record.Heavy_Vehicle_Required__c |
| NTE_Invoice_Required__c | Priced_Application.Invoice_Required__c |
| NTE_Payment_Method__c | $Record.Payment_Method__c |
| NTE_Invoiced_Company__c | $Record.Invoiced_Company__c |
| NTE_Invoice_Address__c | $Record.Invoice_Address__c |
| NTE_Invoiced_Person__c | $Record.Invoiced_Person__c |
| NTE_Invoiced_Email__c | $Record.Invoiced_Email__c |
| NTE_Invoice_Contact_Phone__c | $Record.Invoice_Contact_Phone__c |
| NTE_Invoice_Additional_Information__c | $Record.Invoice_Additional_Information__c |
| NTE_Purchase_Order__c | $Record.Purchase_Order__c |
| NTE_Purchase_Order_Number__c | $Record.Purchase_Order_Number__c |
| NTE_Quote_Required_for_PO__c | $Record.Quote_Required_for_PO__c |
| NTE_Supplier_Agreement_Required__c | $Record.Supplier_Agreement_Required__c |



### Send Exhibitor Approval Email

Element type: actionCalls. Label: Queue NTE Provisional Email.

Apex action: NTEExhibitorApprovalEmailService. Transaction: CurrentTransaction.


| Input | Value |
| --- | --- |
| leadId | $Record.Id |
| opportunityId | $Record.ConvertedOpportunityId |



### Classify Converted Account

Element type: recordUpdates. Label: Classify Converted Account.

Object: Account. Filters: Id EqualTo $Record.ConvertedAccountId.


| Destination field | Assigned value |
| --- | --- |
| NTE_Participant__c | true |
| NTE_Event_Code__c | $Record.NTE_Event_Code__c |
| NTE_Source_Form_Type__c | $Record.Web_Form_Type__c |
| NTE_Booking_Reference__c | $Record.Booking_Reference__c |
| NTE_Last_Application_Date__c | $Flow.CurrentDateTime |



### Classify Converted Contact

Element type: recordUpdates. Label: Classify Converted Contact.

Object: Contact. Filters: Id EqualTo $Record.ConvertedContactId.


| Destination field | Assigned value |
| --- | --- |
| NTE_Participant__c | true |
| NTE_Event_Code__c | $Record.NTE_Event_Code__c |
| NTE_Source_Form_Type__c | $Record.Web_Form_Type__c |
| NTE_Booking_Reference__c | $Record.Booking_Reference__c |
| NTE_Last_Application_Date__c | $Flow.CurrentDateTime |
| NTE_Contact_Role__c | Applicant / event contact |



Flow variable: name=Priced_Application; dataType=SObject; isCollection=false; isInput=false; isOutput=false; objectType=Lead.

## NTE Inbound Lead Routing

API name: NTE_Inbound_Lead_Routing. API version 67.0. Status Active.

Routes new NTE expressions of interest, applications and guest registrations, then sends the appropriate acknowledgement and internal notification.

Start: Lead Create; RecordAfterSave; changed-to-meet-criteria=false. Filter logic: 1 OR 2 OR 3 OR 4 OR 5.


| Criterion | Field | Operator | Value |
| --- | --- | --- | --- |
| 1 | Web_Form_Type__c | EqualTo | Partner / Sponsor Expression of Interest |
| 2 | Web_Form_Type__c | EqualTo | Exhibitor Expression of Interest |
| 3 | Web_Form_Type__c | EqualTo | Partner / Sponsor Application |
| 4 | Web_Form_Type__c | EqualTo | Exhibitor Application |
| 5 | Web_Form_Type__c | EqualTo | Guest Registration |



Sequence: Run_NTE_Service.

### Run NTE Service

Element type: actionCalls. Label: NTE Inbound Lead Routing.

Apex action: NTEInboundLeadService. Transaction: CurrentTransaction.


| Input | Value |
| --- | --- |
| leadId | $Record.Id |
| isNewSubmission | true |



## NTE Supplementary Update Handler

API name: NTE_Supplementary_Update_Handler. API version 67.0. Status Active.

Applies staff, logistics and logo submissions to the NTE Opportunity matched by exact booking reference. Failed submissions are retained; only the existing staff and vehicle temporary Leads are removed after success.

Start: Lead Create; RecordAfterSave; changed-to-meet-criteria=false. Filter logic: 1 OR 2 OR 3 OR 4.


| Criterion | Field | Operator | Value |
| --- | --- | --- | --- |
| 1 | Web_Form_Type__c | EqualTo | Partner / Sponsor Staff Update |
| 2 | Web_Form_Type__c | EqualTo | Exhibitor Staff Update |
| 3 | Web_Form_Type__c | EqualTo | Heavy Vehicle Details |
| 4 | Web_Form_Type__c | EqualTo | Logo Update |



Sequence: Run_NTE_Service.

### Run NTE Service

Element type: actionCalls. Label: NTE Supplementary Update Handler.

Apex action: NTEUpdateSubmissionService. Transaction: CurrentTransaction.


| Input | Value |
| --- | --- |
| leadId | $Record.Id |



## Volunteer Application Notification

API name: Volunteer_Inbound_Lead_Notification. API version 67.0. Status Active.

Sends the internal notification for a new Mission Motorsport volunteer application.

Start: Lead Create; RecordAfterSave; changed-to-meet-criteria=false. Filter logic: 1 AND 2.


| Criterion | Field | Operator | Value |
| --- | --- | --- | --- |
| 1 | Web_Form_Type__c | EqualTo | Volunteer Application |
| 2 | LeadSource | EqualTo | Volunteer Application |



Sequence: Notify_Volunteer_Owner.

### Notify Volunteer Owner

Element type: actionCalls. Label: Notify Volunteer Owner.

Apex action: VolunteerInboundLeadService. Transaction: CurrentTransaction.


| Input | Value |
| --- | --- |
| leadId | $Record.Id |
| isNewSubmission | true |


