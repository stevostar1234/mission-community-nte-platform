public with sharing class NTEUpdateSubmissionService {
    @TestVisible private static Boolean bypassEmailDelivery = false;
    @TestVisible private static String acknowledgementFailureOverride;
    @TestVisible private static Map<Id, String> acknowledgementRecipientByLeadId = new Map<Id, String>();
    @TestVisible private static Boolean failNextAcknowledgementAuditSave = false;
    @TestVisible private static EmailSender emailSender = new SalesforceEmailSender();
    private static Set<Id> initializedLeadIds = new Set<Id>();
    private static final Integer EMAIL_BATCH_SIZE = 10;
    private static final Integer MAX_EMAILS_PER_TRANSACTION = 100;

    @TestVisible private interface EmailSender {
        List<Messaging.SendEmailResult> send(List<Messaging.SingleEmailMessage> messages);
    }
    private class SalesforceEmailSender implements EmailSender {
        public List<Messaging.SendEmailResult> send(List<Messaging.SingleEmailMessage> messages) {
            return Messaging.sendEmail(messages, false);
        }
    }
    private class AcknowledgementAuditException extends Exception {}

    public class Request {
        @InvocableVariable(required=true label='Lead ID')
        public Id leadId;
        @InvocableVariable(label='New submission')
        public Boolean isNewSubmission;
    }

    @TestVisible
    private class OpportunityMatchIndex {
        @TestVisible private Map<String, Opportunity> opportunitiesByReference = new Map<String, Opportunity>();
        @TestVisible private Set<String> ambiguousReferences = new Set<String>();
    }

    public class AcknowledgementRetryResult {
        @AuraEnabled public Boolean success;
        @AuraEnabled public String message;
        @AuraEnabled public Id leadId;
    }

    private class OrderedSubmission implements Comparable {
        public Lead submission;
        public OrderedSubmission(Lead submission) { this.submission = submission; }
        public Integer compareTo(Object otherValue) {
            Lead other = ((OrderedSubmission)otherValue).submission;
            if (submission.CreatedDate < other.CreatedDate) return -1;
            if (submission.CreatedDate > other.CreatedDate) return 1;
            return String.valueOf(submission.Id).compareTo(String.valueOf(other.Id));
        }
    }

    @InvocableMethod(
        label='Apply NTE Supplementary Submission'
        description='Matches an NTE staff, vehicle or logo submission by exact booking reference and updates the Opportunity. Successful logo submissions are retained as Lead audit records.'
    )
    public static void applyUpdates(List<Request> requests) {
        if (requests == null) return;
        Set<Id> leadIds = new Set<Id>();
        Set<Id> newLeadIds = new Set<Id>();
        for (Request request : requests) {
            if (request == null || request.leadId == null) continue;
            if (request.isNewSubmission == true) {
                if (initializedLeadIds.contains(request.leadId)) continue;
                newLeadIds.add(request.leadId);
            }
            leadIds.add(request.leadId);
        }
        if (leadIds.isEmpty()) return;

        // Only the create Flow claims new-submission semantics. Public form fields
        // cannot supply its trusted input or the identity used by acknowledgement retries.
        try {
            Set<Id> retryIds = new Set<Id>(leadIds);
            retryIds.removeAll(newLeadIds);
            leadIds = new Set<Id>(newLeadIds);
            if (!retryIds.isEmpty()) {
                for (Lead submission : (List<Lead>)Database.queryWithBinds(
                    'SELECT Id FROM Lead WHERE Id IN :retryIds '
                    + 'AND NTE_Update_Status__c = \'Matched and Applied\' '
                    + 'AND NTE_Applicant_Email_Status__c = \'Failed\' FOR UPDATE',
                    new Map<String, Object>{'retryIds' => retryIds}, AccessLevel.SYSTEM_MODE
                )) leadIds.add(submission.Id);
            }
            if (leadIds.isEmpty()) return;
            List<Lead> pendingSubmissions = new List<Lead>();
            for (Id leadId : newLeadIds) pendingSubmissions.add(new Lead(
                Id = leadId, NTE_Update_Status__c = 'Pending', NTE_Update_Error__c = null,
                NTE_Update_Booking_Id__c = null, NTE_Applicant_Email_Status__c = null, NTE_Email_Error__c = null
            ));
            if (!pendingSubmissions.isEmpty()) Database.update(pendingSubmissions, true, AccessLevel.SYSTEM_MODE);
            initializedLeadIds.addAll(newLeadIds);
            // The temporary Lead must commit before it can be emailed and deleted.
            List<String> serializedLeadIds = new List<String>();
            for (Id leadId : leadIds) serializedLeadIds.add(String.valueOf(leadId));
            System.enqueueJob(new NTEUpdateSubmissionJob(String.join(serializedLeadIds, ','), bypassEmailDelivery));
        } catch (Exception exceptionValue) {
            recordUnexpectedFailure(leadIds, exceptionValue);
        }
    }

    public static void recordUnexpectedFailure(Set<Id> leadIds, Exception exceptionValue) {
        if (leadIds == null || leadIds.isEmpty()) return;
        String message = exceptionValue == null || String.isBlank(exceptionValue.getMessage())
            ? 'The supplementary update could not be queued or processed.'
            : exceptionValue.getTypeName() + ': ' + exceptionValue.getMessage();
        if (exceptionValue != null && String.isNotBlank(exceptionValue.getStackTraceString())) {
            message += '\n' + exceptionValue.getStackTraceString();
        }
        if (message.length() > 32000) message = message.substring(0, 32000);
        try {
            List<Lead> currentLeads = (List<Lead>)Database.queryWithBinds(
                'SELECT Id, NTE_Update_Status__c, NTE_Applicant_Email_Status__c FROM Lead WHERE Id IN :leadIds',
                new Map<String, Object>{'leadIds' => leadIds}, AccessLevel.SYSTEM_MODE
            );
            List<Lead> failures = new List<Lead>();
            for (Lead current : currentLeads) {
                Lead failure = new Lead(Id = current.Id, NTE_Update_Error__c = message);
                if (current.NTE_Update_Status__c == 'Matched and Applied') {
                    if (current.NTE_Applicant_Email_Status__c != 'Accepted by Salesforce') {
                        failure.NTE_Applicant_Email_Status__c = 'Failed';
                        failure.NTE_Email_Error__c = message;
                    }
                } else {
                    failure.NTE_Update_Status__c = 'Failed';
                }
                failures.add(failure);
            }
            Database.update(failures, false, AccessLevel.SYSTEM_MODE);
        } catch (Exception ignored) {
            // The queue must end cleanly even if a record was removed concurrently.
        }
    }

    @TestVisible
    public static void processLeadIds(Set<Id> leadIds, Boolean skipEmailDelivery) {
        if (leadIds == null || leadIds.isEmpty()) return;
        String leadQuery =
            'SELECT Id, CreatedDate, Email, Phone, Web_Form_Type__c, Form_Version__c, Target_Booking_Reference__c, '
            + 'NTE_Update_Status__c, NTE_Applicant_Email_Status__c, NTE_Update_Booking_Id__c, '
            + 'Event_Contact_Name__c, Event_Contact_Title__c, Event_Contact_Email__c, Event_Contact_Mobile__c, '
            + 'Secondary_Contact_Prefix__c, Secondary_Contact_Name__c, Secondary_Contact_Title__c, '
            + 'Secondary_Contact_Email__c, Secondary_Contact_Mobile__c, Secondary_Contact_Phone__c, '
            + 'Planned_Exhibitor_Count__c, Total_Staff_Count__c, Staff_Update_Audience__c, Staff_Base_Names__c, '
            + 'Top_Up_Staff_Required__c, Top_Up_Staff_Count__c, Top_Up_Staff_Names__c, '
            + 'Additional_Staff_Required__c, Additional_Staff_Count__c, Stand_Colleagues__c, '
            + 'Declaration_Name__c, Declaration_Date__c, '
            + 'Delivery_Window__c, '
            + 'Heavy_Item_1_Description__c, Heavy_Item_1_Registration__c, Heavy_Item_1_Dimensions__c, Heavy_Item_1_Gross_Weight__c, '
            + 'Heavy_Item_2_Description__c, Heavy_Item_2_Registration__c, Heavy_Item_2_Dimensions__c, Heavy_Item_2_Gross_Weight__c, '
            + 'Heavy_Item_3_Description__c, Heavy_Item_3_Registration__c, Heavy_Item_3_Dimensions__c, Heavy_Item_3_Gross_Weight__c, '
            + 'Haulier_Name__c, Haulier_Staff__c, Haulier_Vehicle_Type__c, Haulier_Vehicle_Gross_Weight__c, '
            + 'Haulier_Vehicle_Dimensions__c, Haulier_Vehicle_Registration__c '
            + 'FROM Lead WHERE Id IN :leadIds FOR UPDATE';
        List<Lead> leads = (List<Lead>)Database.queryWithBinds(
            leadQuery,
            new Map<String, Object>{'leadIds' => leadIds},
            AccessLevel.SYSTEM_MODE
        );
        List<OrderedSubmission> ordered = new List<OrderedSubmission>();
        for (Lead lead : leads) ordered.add(new OrderedSubmission(lead));
        ordered.sort();
        leads.clear();
        for (OrderedSubmission entry : ordered) leads.add(entry.submission);

        Set<String> references = new Set<String>();
        Set<Id> appliedBookingIds = new Set<Id>();
        for (Lead lead : leads) {
            if (isValidBookingReference(lead.Target_Booking_Reference__c)) {
                references.add(lead.Target_Booking_Reference__c.trim());
            }
            Id appliedId = appliedBookingId(lead);
            if (lead.NTE_Update_Status__c == 'Matched and Applied' && appliedId != null) appliedBookingIds.add(appliedId);
        }
        OpportunityMatchIndex opportunityMatches = new OpportunityMatchIndex();
        Map<Id, Opportunity> opportunitiesById = new Map<Id, Opportunity>();
        if (!references.isEmpty() || !appliedBookingIds.isEmpty()) {
            List<Opportunity> matchedOpportunities = (List<Opportunity>)Database.queryWithBinds(
                'SELECT Id, Booking_Reference__c, NTE_Event_Code__c, NTE_Source_Form_Type__c, NTE_Planned_Exhibitor_Count__c, '
                + 'NTE_Initial_Staff_Count__c, NTE_Total_Staff_Count__c, NTE_Stand_Colleagues__c, '
                + 'NTE_Top_Up_Staff_Required__c, NTE_Top_Up_Staff_Count__c, NTE_Top_Up_Staff_Names__c, '
                + 'NTE_Top_Up_Staff_Unit_Price__c, NTE_Top_Up_VAT_Rate__c, NTE_Top_Up_Staff_Total__c, NTE_Top_Up_Invoice_Required__c, NTE_Top_Up_Invoice_Provided__c, '
                + 'NTE_Top_Up_Invoice_At__c, NTE_Top_Up_Invoice_By__c, NTE_Top_Up_Payment_Received__c, '
                + 'NTE_Top_Up_Payment_At__c, NTE_Top_Up_Payment_By__c, '
                + 'NTE_Sponsor_Package_Total__c, NTE_Exhibitor_Space_Price__c, '
                + 'NTE_Power_Socket_Total__c, NTE_Additional_Staff_Total__c, NTE_Listed_Price_Total__c, Amount, '
                + 'NTE_Pricing_Status__c, NTE_Invoice_Provided__c, NTE_Invoice_Provided_At__c, '
                + 'NTE_Invoice_Provided_By__c, NTE_Payment_Received__c, NTE_Payment_Received_At__c, NTE_Payment_Recorded_By__c, '
                + 'NTE_Logo_Update_Provided__c, NTE_Logo_Update_Provided_At__c '
                + 'FROM Opportunity WHERE (Booking_Reference__c IN :references OR Id IN :appliedBookingIds) '
                + 'AND RecordType.DeveloperName = \'NTE_Event_Opportunity\' AND NTE_Event_Code__c != null '
                + 'AND NTE_Source_Form_Type__c IN (\'Exhibitor Application\', \'Partner / Sponsor Application\') '
                + 'FOR UPDATE',
                new Map<String, Object>{'references' => references, 'appliedBookingIds' => appliedBookingIds},
                AccessLevel.SYSTEM_MODE
            );
            opportunityMatches = buildOpportunityMatchIndex(matchedOpportunities);
            opportunitiesById = new Map<Id, Opportunity>(matchedOpportunities);
        }

        List<Lead> unmatched = new List<Lead>();
        List<Lead> matchedLeads = new List<Lead>();
        List<Lead> acknowledgementLeads = new List<Lead>();
        List<Lead> temporaryLeadsToDelete = new List<Lead>();
        Map<Id, Opportunity> updatesByOpportunityId = new Map<Id, Opportunity>();
        Map<Id, String> templateByLeadId = new Map<Id, String>();
        Map<Id, Id> bookingIdByLeadId = new Map<Id, Id>();
        Map<Id, Lead> appliedAuditsByLeadId = new Map<Id, Lead>();
        for (Lead lead : leads) {
            if (lead.NTE_Update_Status__c == 'Matched and Applied') {
                String templateName = acknowledgementTemplate(lead.Web_Form_Type__c);
                if (templateName != null && lead.NTE_Applicant_Email_Status__c == 'Failed') {
                    Opportunity appliedBooking = opportunitiesById.get(appliedBookingId(lead));
                    if (!matchesAppliedBooking(lead, appliedBooking)) {
                        unmatched.add(acknowledgementAudit(lead.Id,
                            'The acknowledgement was not sent because its saved booking identity and reference could not be verified. The saved booking details were not changed.'));
                    } else {
                        acknowledgementLeads.add(lead);
                        templateByLeadId.put(lead.Id, templateName);
                        bookingIdByLeadId.put(lead.Id, appliedBooking.Id);
                    }
                }
                continue;
            }
            if (!isValidBookingReference(lead.Target_Booking_Reference__c)) {
                unmatched.add(new Lead(Id = lead.Id, NTE_Update_Status__c = 'Failed',
                    NTE_Update_Error__c = 'Enter the exact booking reference beginning NTE-. No Opportunity was changed.'));
                continue;
            }
            String reference = lead.Target_Booking_Reference__c.trim().toLowerCase();
            if (reference != null && opportunityMatches.ambiguousReferences.contains(reference)) {
                unmatched.add(new Lead(Id = lead.Id, NTE_Update_Status__c = 'Ambiguous Booking Reference',
                    NTE_Update_Error__c = 'More than one NTE Opportunity has the booking reference supplied. No Opportunity was changed.'));
                continue;
            }
            Opportunity existing = reference == null ? null : opportunityMatches.opportunitiesByReference.get(reference);
            if (existing == null) {
                unmatched.add(new Lead(Id = lead.Id, NTE_Update_Status__c = 'No Matching Booking',
                    NTE_Update_Error__c = 'No Opportunity matched the exact booking reference supplied. No Opportunity was changed.'));
                continue;
            }

            String validationError = validationErrorFor(lead, existing);
            if (validationError != null) {
                unmatched.add(new Lead(Id = lead.Id, NTE_Update_Status__c = 'Failed', NTE_Update_Error__c = validationError));
                continue;
            }

            Opportunity updateRecord = updatesByOpportunityId.get(existing.Id);
            if (updateRecord == null) {
                updateRecord = new Opportunity(Id = existing.Id);
                updatesByOpportunityId.put(existing.Id, updateRecord);
            }
            if (lead.Web_Form_Type__c == 'Partner / Sponsor Staff Update') {
                applyPartnerStaffFields(updateRecord, lead);
                templateByLeadId.put(lead.Id, 'NTE_Partner_Staff_Update_Acknowledgement');
                temporaryLeadsToDelete.add(lead);
            } else if (lead.Web_Form_Type__c == 'Exhibitor Staff Update') {
                applyExhibitorStaffFields(updateRecord, lead, existing);
                templateByLeadId.put(lead.Id, 'NTE_Exhibitor_Staff_Update_Acknowledgement');
                temporaryLeadsToDelete.add(lead);
            } else if (lead.Web_Form_Type__c == 'Heavy Vehicle Details') {
                applyHeavyFields(updateRecord, lead);
                templateByLeadId.put(lead.Id, 'NTE_Heavy_Vehicle_Acknowledgement');
                temporaryLeadsToDelete.add(lead);
            } else if (lead.Web_Form_Type__c == 'Logo Update') {
                applyLogoFields(updateRecord, existing);
            } else {
                unmatched.add(new Lead(Id = lead.Id, NTE_Update_Status__c = 'Failed',
                    NTE_Update_Error__c = 'Unsupported supplementary form type. No Opportunity was changed.'));
                continue;
            }
            updateRecord.NTE_Last_Update_Type__c = lead.Web_Form_Type__c;
            updateRecord.NTE_Last_Update_Form_Version__c = lead.Form_Version__c;
            updateRecord.NTE_Last_Update_Processed_At__c = System.now();
            updateRecord.NTE_Last_Update_Declaration_Name__c = lead.Declaration_Name__c;
            updateRecord.NTE_Last_Update_Declaration_Date__c = lead.Declaration_Date__c;
            updateRecord.NTE_Last_Update_Error__c = null;
            matchedLeads.add(lead);
            if (templateByLeadId.containsKey(lead.Id)) {
                acknowledgementLeads.add(lead);
                bookingIdByLeadId.put(lead.Id, existing.Id);
            }
            // Later submissions in this same batch must see the first accepted
            // purchase and its milestones, not the original queried snapshot.
            for (String fieldName : updateRecord.getPopulatedFieldsAsMap().keySet()) {
                if (fieldName != 'Id') existing.put(fieldName, updateRecord.get(fieldName));
            }
            Lead appliedAudit = new Lead(Id = lead.Id, NTE_Update_Status__c = 'Matched and Applied',
                NTE_Update_Error__c = null, NTE_Event_Code__c = existing.NTE_Event_Code__c,
                NTE_Update_Booking_Id__c = String.valueOf(existing.Id));
            if (lead.Web_Form_Type__c == 'Exhibitor Staff Update') {
                // Confirm the saved purchase, including when a names-only update
                // supplied no new top-up values or an obsolete browser price.
                appliedAudit.Top_Up_Staff_Required__c = existing.NTE_Top_Up_Staff_Required__c;
                appliedAudit.Top_Up_Staff_Count__c = existing.NTE_Top_Up_Staff_Count__c;
                appliedAudit.Top_Up_Staff_Names__c = existing.NTE_Top_Up_Staff_Names__c;
                appliedAudit.Top_Up_Staff_Unit_Price__c = existing.NTE_Top_Up_Staff_Unit_Price__c;
                appliedAudit.Top_Up_Staff_Total__c = existing.NTE_Top_Up_Staff_Total__c;
                appliedAudit.VAT_Rate__c = NTEVat.rate(existing.NTE_Top_Up_VAT_Rate__c);
            }
            appliedAuditsByLeadId.put(lead.Id, appliedAudit);
        }

        if (!unmatched.isEmpty()) Database.update(unmatched, true, AccessLevel.SYSTEM_MODE);
        if (matchedLeads.isEmpty() && acknowledgementLeads.isEmpty()) return;

        Savepoint savepoint = Database.setSavepoint();
        try {
            if (!updatesByOpportunityId.isEmpty()) {
                Database.update(updatesByOpportunityId.values(), true, AccessLevel.SYSTEM_MODE);
            }
            if (!appliedAuditsByLeadId.isEmpty()) Database.update(appliedAuditsByLeadId.values(), true, AccessLevel.SYSTEM_MODE);
        } catch (Exception exceptionValue) {
            Database.rollback(savepoint);
            String message = String.isBlank(exceptionValue.getMessage()) ? 'The supplementary update could not be completed.' : exceptionValue.getMessage();
            if (message.length() > 32000) message = message.substring(0, 32000);
            List<Lead> failures = new List<Lead>();
            for (Lead lead : matchedLeads) failures.add(new Lead(Id = lead.Id, NTE_Update_Status__c = 'Failed', NTE_Update_Error__c = message));
            if (!failures.isEmpty()) Database.update(failures, true, AccessLevel.SYSTEM_MODE);
            return;
        }

        // A missing contact or email failure must not undo accepted booking data.
        Map<Id, String> emailErrors = dispatchAndRecordAcknowledgements(acknowledgementLeads, templateByLeadId,
            bookingIdByLeadId, skipEmailDelivery, AccessLevel.SYSTEM_MODE);
        List<Lead> acceptedTemporaryLeads = new List<Lead>();
        for (Lead lead : temporaryLeadsToDelete) {
            if (!emailErrors.containsKey(lead.Id)) acceptedTemporaryLeads.add(lead);
        }
        if (!acceptedTemporaryLeads.isEmpty()) Database.delete(acceptedTemporaryLeads, false, AccessLevel.SYSTEM_MODE);
    }

    @TestVisible
    private static OpportunityMatchIndex buildOpportunityMatchIndex(List<Opportunity> matchedOpportunities) {
        OpportunityMatchIndex opportunityMatches = new OpportunityMatchIndex();
        if (matchedOpportunities == null) return opportunityMatches;

        for (Opportunity opportunity : matchedOpportunities) {
            if (opportunity == null || String.isBlank(opportunity.Booking_Reference__c)) continue;
            String normalizedReference = opportunity.Booking_Reference__c.trim().toLowerCase();
            if (opportunityMatches.opportunitiesByReference.containsKey(normalizedReference)) {
                opportunityMatches.opportunitiesByReference.remove(normalizedReference);
                opportunityMatches.ambiguousReferences.add(normalizedReference);
            } else if (!opportunityMatches.ambiguousReferences.contains(normalizedReference)) {
                opportunityMatches.opportunitiesByReference.put(normalizedReference, opportunity);
            }
        }
        return opportunityMatches;
    }

    private static void applyPartnerStaffFields(Opportunity target, Lead source) {
        target.NTE_Staff_Update_Completed_At__c = System.now();
        target.NTE_Planned_Exhibitor_Count__c = String.valueOf(source.Total_Staff_Count__c.intValue());
        target.NTE_Total_Staff_Count__c = source.Total_Staff_Count__c;
        target.NTE_Stand_Colleagues__c = source.Staff_Base_Names__c;
    }

    private static void applyExhibitorStaffFields(Opportunity target, Lead source, Opportunity existing) {
        Decimal previousTopUpCount = existing.NTE_Top_Up_Staff_Count__c == null ? 0 : existing.NTE_Top_Up_Staff_Count__c;
        Boolean requestsTopUp = source.Top_Up_Staff_Required__c == 'Yes';
        Decimal requestedTopUpCount = requestsTopUp ? source.Top_Up_Staff_Count__c : previousTopUpCount;
        String requestedTopUpNames = requestsTopUp ? source.Top_Up_Staff_Names__c : existing.NTE_Top_Up_Staff_Names__c;

        target.NTE_Staff_Update_Completed_At__c = System.now();
        target.NTE_Top_Up_Staff_Required__c = requestedTopUpCount > 0 ? 'Yes' : 'No';
        target.NTE_Top_Up_Staff_Count__c = requestedTopUpCount;
        target.NTE_Top_Up_Staff_Names__c = requestedTopUpNames;
        target.NTE_Stand_Colleagues__c = combineNames(source.Staff_Base_Names__c, requestedTopUpNames);

        if (previousTopUpCount == 0) {
            target.NTE_Top_Up_VAT_Rate__c = NTEVat.RATE;
            target.NTE_Top_Up_Staff_Unit_Price__c = requestedTopUpCount > 0 ? NTEPricingService.ADDITIONAL_STAFF_PRICE : 0;
            target.NTE_Top_Up_Staff_Total__c = requestedTopUpCount * NTEPricingService.ADDITIONAL_STAFF_PRICE;
        }
        if (previousTopUpCount == 0 && requestedTopUpCount > 0) {
            // A names-only update must not rewrite the booked quantity. A new
            // purchase adds its explicit quantity only when the old total is known.
            Decimal existingCount = existing.NTE_Total_Staff_Count__c == null
                ? initialStaffCount(existing) : existing.NTE_Total_Staff_Count__c;
            if (existingCount != null && existingCount >= 0 && existingCount == existingCount.setScale(0)
                && existingCount + requestedTopUpCount <= 999) {
                target.NTE_Total_Staff_Count__c = existingCount + requestedTopUpCount;
            }
            target.NTE_Top_Up_Invoice_Required__c = true;
            target.NTE_Top_Up_Invoice_Provided__c = false;
            target.NTE_Top_Up_Invoice_At__c = null;
            target.NTE_Top_Up_Invoice_By__c = null;
            target.NTE_Top_Up_Payment_Received__c = false;
            target.NTE_Top_Up_Payment_At__c = null;
            target.NTE_Top_Up_Payment_By__c = null;
        }
    }

    private static Decimal initialStaffCount(Opportunity existing) {
        if (existing.NTE_Initial_Staff_Count__c != null) return existing.NTE_Initial_Staff_Count__c;
        return decimalFromText(existing.NTE_Planned_Exhibitor_Count__c);
    }

    private static String combineNames(String baseNames, String topUpNames) {
        List<String> sections = new List<String>();
        if (String.isNotBlank(baseNames)) sections.add(baseNames.trim());
        if (String.isNotBlank(topUpNames)) sections.add(topUpNames.trim());
        return String.join(sections, '\n');
    }

    private static Decimal decimalFromText(String value) {
        if (String.isBlank(value)) return null;
        try {
            return Decimal.valueOf(value.trim());
        } catch (Exception ignored) {
            return null;
        }
    }

    private static String validationErrorFor(Lead source, Opportunity existing) {
        if (!new Set<String>{'Partner / Sponsor Staff Update', 'Exhibitor Staff Update', 'Heavy Vehicle Details', 'Logo Update'}.contains(source.Web_Form_Type__c)) {
            return 'Unsupported supplementary form type. No Opportunity was changed.';
        }
        // Logo confirmation uses the booking reference and submitter details;
        // the owner retired its separate declaration on 10 September 2026.
        if (source.Web_Form_Type__c == 'Logo Update') return null;
        if (String.isBlank(source.Declaration_Name__c) || source.Declaration_Date__c == null) {
            return 'A digital signature and declaration date are required. No Opportunity was changed.';
        }
        if (source.Web_Form_Type__c == 'Partner / Sponsor Staff Update') {
            if (existing.NTE_Source_Form_Type__c != 'Partner / Sponsor Application') {
                return 'This staff form does not match the booking type. No Opportunity was changed.';
            }
            Decimal totalCount = source.Total_Staff_Count__c;
            if (totalCount == null || totalCount < 1 || totalCount > 99 || totalCount != totalCount.setScale(0)) {
                return 'The final attendee total must be a whole number between 1 and 99. No Opportunity was changed.';
            }
            if (String.isBlank(source.Staff_Base_Names__c)) {
                return 'Enter the staff names. No Opportunity was changed.';
            }
            return null;
        }
        if (source.Web_Form_Type__c == 'Exhibitor Staff Update') {
            if (existing.NTE_Source_Form_Type__c != 'Exhibitor Application') {
                return 'This staff form does not match the booking type. No Opportunity was changed.';
            }
            if (String.isBlank(source.Staff_Base_Names__c)) {
                return 'Enter the staff names. No Opportunity was changed.';
            }
            if (!new Set<String>{'Yes', 'No'}.contains(source.Top_Up_Staff_Required__c)) {
                return 'Select whether additional top-up staff places are required. No Opportunity was changed.';
            }
            if (source.Top_Up_Staff_Required__c == 'Yes') {
                Decimal topUpCount = source.Top_Up_Staff_Count__c;
                Integer existingTopUpCount = existing.NTE_Top_Up_Staff_Count__c == null ? 0 : existing.NTE_Top_Up_Staff_Count__c.intValue();
                if (topUpCount == null || topUpCount < 1 || topUpCount > 99 || topUpCount != topUpCount.setScale(0)) {
                    return 'The top-up total must be a whole number between 1 and 99. No Opportunity was changed.';
                }
                if (String.isBlank(source.Top_Up_Staff_Names__c)) {
                    return 'Enter the top-up staff names. No Opportunity was changed.';
                }
                if (topUpCount < existingTopUpCount) {
                    return 'Existing top-up places cannot be reduced with this form. Contact the NTE team to change or cancel paid places.';
                }
                if (existingTopUpCount > 0 && topUpCount > existingTopUpCount) {
                    return 'Additional staff can only be requested once for this booking. You can update the staff names without changing that purchase. Contact the NTE team about other changes.';
                }
            }
            String topUpNames = source.Top_Up_Staff_Required__c == 'Yes'
                ? source.Top_Up_Staff_Names__c : existing.NTE_Top_Up_Staff_Names__c;
            if (combineNames(source.Staff_Base_Names__c, topUpNames).length()
                > Opportunity.NTE_Stand_Colleagues__c.getDescribe().getLength()) {
                return 'The combined staff name list is too long. Shorten each entry and submit again. No Opportunity was changed.';
            }
            return null;
        }
        if (source.Web_Form_Type__c == 'Heavy Vehicle Details') {
            if (String.isBlank(source.Event_Contact_Name__c) || String.isBlank(source.Email) || String.isBlank(source.Phone)
                || String.isBlank(source.Secondary_Contact_Name__c) || String.isBlank(source.Secondary_Contact_Email__c)
                || String.isBlank(source.Secondary_Contact_Phone__c) || String.isBlank(source.Delivery_Window__c)
                || String.isBlank(source.Heavy_Item_1_Description__c) || String.isBlank(source.Heavy_Item_1_Dimensions__c)
                || String.isBlank(source.Heavy_Item_1_Gross_Weight__c) || String.isBlank(source.Haulier_Name__c)
                || String.isBlank(source.Haulier_Vehicle_Type__c) || String.isBlank(source.Haulier_Vehicle_Gross_Weight__c)
                || String.isBlank(source.Haulier_Vehicle_Dimensions__c)) {
                return 'The required contact, delivery, first-item and haulier details are incomplete. No Opportunity was changed.';
            }
            if (incompleteOptionalItem(source.Heavy_Item_2_Description__c, source.Heavy_Item_2_Registration__c,
                source.Heavy_Item_2_Dimensions__c, source.Heavy_Item_2_Gross_Weight__c)
                || incompleteOptionalItem(source.Heavy_Item_3_Description__c, source.Heavy_Item_3_Registration__c,
                    source.Heavy_Item_3_Dimensions__c, source.Heavy_Item_3_Gross_Weight__c)
                || (String.isBlank(source.Heavy_Item_2_Description__c) && String.isNotBlank(source.Heavy_Item_3_Description__c))) {
                return 'Each additional item needs a description, dimensions and gross weight, in order. No Opportunity was changed.';
            }
        }
        return null;
    }

    private static Boolean incompleteOptionalItem(String description, String registration, String dimensions, String weight) {
        Boolean anyValue = String.isNotBlank(description) || String.isNotBlank(registration)
            || String.isNotBlank(dimensions) || String.isNotBlank(weight);
        return anyValue && (String.isBlank(description) || String.isBlank(dimensions) || String.isBlank(weight));
    }

    private static void applyHeavyFields(Opportunity target, Lead source) {
        target.NTE_Heavy_Vehicle_Required__c = 'Yes';
        target.NTE_Heavy_Vehicle_Update_Completed_At__c = System.now();
        // The logistics form collects its own two contacts. They are kept on the booking because the
        // temporary Lead is deleted after a successful update, and they must not overwrite the
        // application's event and secondary contacts.
        target.NTE_Logistics_Contact_Name__c = source.Event_Contact_Name__c;
        target.NTE_Logistics_Contact_Email__c = source.Email;
        target.NTE_Logistics_Contact_Phone__c = source.Phone;
        target.NTE_Logistics_Second_Contact_Name__c = source.Secondary_Contact_Name__c;
        target.NTE_Logistics_Second_Contact_Email__c = source.Secondary_Contact_Email__c;
        target.NTE_Logistics_Second_Contact_Phone__c = source.Secondary_Contact_Phone__c;
        target.NTE_Delivery_Window__c = source.Delivery_Window__c;
        target.NTE_Heavy_Item_1_Description__c = source.Heavy_Item_1_Description__c;
        target.NTE_Heavy_Item_1_Registration__c = source.Heavy_Item_1_Registration__c;
        target.NTE_Heavy_Item_1_Dimensions__c = source.Heavy_Item_1_Dimensions__c;
        target.NTE_Heavy_Item_1_Gross_Weight__c = source.Heavy_Item_1_Gross_Weight__c;
        target.NTE_Heavy_Item_2_Description__c = source.Heavy_Item_2_Description__c;
        target.NTE_Heavy_Item_2_Registration__c = source.Heavy_Item_2_Registration__c;
        target.NTE_Heavy_Item_2_Dimensions__c = source.Heavy_Item_2_Dimensions__c;
        target.NTE_Heavy_Item_2_Gross_Weight__c = source.Heavy_Item_2_Gross_Weight__c;
        target.NTE_Heavy_Item_3_Description__c = source.Heavy_Item_3_Description__c;
        target.NTE_Heavy_Item_3_Registration__c = source.Heavy_Item_3_Registration__c;
        target.NTE_Heavy_Item_3_Dimensions__c = source.Heavy_Item_3_Dimensions__c;
        target.NTE_Heavy_Item_3_Gross_Weight__c = source.Heavy_Item_3_Gross_Weight__c;
        target.NTE_Haulier_Name__c = source.Haulier_Name__c;
        target.NTE_Haulier_Staff__c = source.Haulier_Staff__c;
        target.NTE_Haulier_Vehicle_Type__c = source.Haulier_Vehicle_Type__c;
        target.NTE_Haulier_Vehicle_Gross_Weight__c = source.Haulier_Vehicle_Gross_Weight__c;
        target.NTE_Haulier_Vehicle_Dimensions__c = source.Haulier_Vehicle_Dimensions__c;
        target.NTE_Haulier_Vehicle_Registration__c = source.Haulier_Vehicle_Registration__c;
    }

    private static void applyLogoFields(Opportunity target, Opportunity existing) {
        target.NTE_Logo_Update_Provided__c = true;
        if (!existing.NTE_Logo_Update_Provided__c || existing.NTE_Logo_Update_Provided_At__c == null) {
            target.NTE_Logo_Update_Provided_At__c = System.now();
        }
    }

    @TestVisible
    private static Boolean isValidBookingReference(String suppliedReference) {
        if (String.isBlank(suppliedReference)) return false;
        String reference = suppliedReference.trim();
        return reference.length() <= 80
            && Pattern.matches('(?i)^NTE-[A-Z0-9][A-Z0-9-]{1,74}[A-Z0-9]$', reference);
    }

    private static String acknowledgementTemplate(String formType) {
        if (formType == 'Exhibitor Staff Update') return 'NTE_Exhibitor_Staff_Update_Acknowledgement';
        if (formType == 'Partner / Sponsor Staff Update') return 'NTE_Partner_Staff_Update_Acknowledgement';
        if (formType == 'Heavy Vehicle Details') return 'NTE_Heavy_Vehicle_Acknowledgement';
        return null;
    }

    private static Id appliedBookingId(Lead submission) {
        if (String.isBlank(submission.NTE_Update_Booking_Id__c)) return null;
        try {
            Id bookingId = (Id)submission.NTE_Update_Booking_Id__c;
            return bookingId.getSObjectType() == Opportunity.SObjectType ? bookingId : null;
        } catch (Exception ignored) {
            return null;
        }
    }

    private static Boolean matchesAppliedBooking(Lead submission, Opportunity booking) {
        return booking != null && appliedBookingId(submission) == booking.Id
            && isValidBookingReference(submission.Target_Booking_Reference__c)
            && String.isNotBlank(booking.Booking_Reference__c)
            && submission.Target_Booking_Reference__c.trim().equalsIgnoreCase(booking.Booking_Reference__c.trim());
    }

    private static Lead acknowledgementAudit(Id leadId, String error) {
        return new Lead(
            Id = leadId,
            NTE_Update_Status__c = 'Matched and Applied',
            NTE_Update_Error__c = null,
            NTE_Applicant_Email_Status__c = error == null ? 'Accepted by Salesforce' : 'Failed',
            NTE_Email_Error__c = error == null ? null : error.left(32000)
        );
    }

    private static void writeAcknowledgementAudits(List<Lead> audits, AccessLevel accessLevel) {
        if (audits.isEmpty()) return;
        if (Test.isRunningTest() && failNextAcknowledgementAuditSave) {
            failNextAcknowledgementAuditSave = false;
            throw new AcknowledgementAuditException('The acknowledgement result could not be saved.');
        }
        Database.update(audits, true, accessLevel);
    }

    private static Map<Id, String> dispatchAndRecordAcknowledgements(List<Lead> leads,
        Map<Id, String> templateByLeadId, Map<Id, Id> bookingIdByLeadId,
        Boolean skipEmailDelivery, AccessLevel accessLevel) {
        Map<Id, String> errors = new Map<Id, String>();
        if (leads.isEmpty()) return errors;
        // Keep the accepted booking update; only this email attempt and its audit
        // must commit together. A retry is safe only after the attempt is rolled back.
        Savepoint emailSavepoint = Database.setSavepoint();
        try {
            errors = sendAcknowledgements(leads, templateByLeadId, bookingIdByLeadId, skipEmailDelivery, accessLevel);
            List<Lead> audits = new List<Lead>();
            for (Lead lead : leads) audits.add(acknowledgementAudit(lead.Id, errors.get(lead.Id)));
            writeAcknowledgementAudits(audits, accessLevel);
        } catch (Exception auditFailure) {
            Database.rollback(emailSavepoint);
            errors.clear();
            List<Lead> failures = new List<Lead>();
            String error = ('The booking details were saved, but the acknowledgement was not sent because its result could not be saved. '
                + auditFailure.getMessage()).left(32000);
            for (Lead lead : leads) {
                errors.put(lead.Id, error);
                failures.add(acknowledgementAudit(lead.Id, error));
            }
            writeAcknowledgementAudits(failures, accessLevel);
        } finally {
            Database.releaseSavepoint(emailSavepoint);
        }
        return errors;
    }

    @TestVisible
    private static Messaging.SingleEmailMessage acknowledgementMessage(Id mergeLeadId, Id templateId, String primaryEmail) {
        Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
        message.setTargetObjectId(mergeLeadId);
        message.setTreatTargetObjectAsRecipient(false);
        message.setToAddresses(new List<String>{primaryEmail});
        message.setTemplateId(templateId);
        message.setSaveAsActivity(false);
        return message;
    }

    private static Map<Id, String> sendAcknowledgements(List<Lead> leads, Map<Id, String> templateByLeadId,
        Map<Id, Id> bookingIdByLeadId, Boolean skipEmailDelivery, AccessLevel contactAccessLevel) {
        Map<Id, String> errors = new Map<Id, String>();
        if (leads.isEmpty()) return errors;
        if (leads.size() > MAX_EMAILS_PER_TRANSACTION) {
            for (Lead lead : leads) errors.put(lead.Id, 'The booking details were saved. Retry this acknowledgement separately because this batch exceeds the 100-email limit.');
            return errors;
        }
        try {
            Map<Id, Contact> contacts = NTEBookingContactService.primaryContacts(
                new Set<Id>(bookingIdByLeadId.values()), contactAccessLevel, true);
            Map<String, Id> templateIdsByName = templateIds(new Set<String>(templateByLeadId.values()));
            List<Messaging.SingleEmailMessage> messages = new List<Messaging.SingleEmailMessage>();
            List<Id> messageLeadIds = new List<Id>();
            for (Lead lead : leads) {
                Contact primaryContact = contacts.get(bookingIdByLeadId.get(lead.Id));
                Id templateId = templateIdsByName.get(templateByLeadId.get(lead.Id));
                if (primaryContact == null || String.isBlank(primaryContact.Email)) {
                    errors.put(lead.Id, 'The booking details were saved, but the acknowledgement was not sent because the Opportunity has no usable Primary Contact email. Set its Primary Contact and retry the acknowledgement.');
                } else if (templateId == null) {
                    errors.put(lead.Id, 'The booking details were saved, but the required acknowledgement template was not found.');
                } else {
                    if (Test.isRunningTest()) acknowledgementRecipientByLeadId.put(lead.Id, primaryContact.Email);
                    if (skipEmailDelivery == true) {
                        if (String.isNotBlank(acknowledgementFailureOverride)) errors.put(lead.Id, acknowledgementFailureOverride);
                        continue;
                    }
                    messages.add(acknowledgementMessage(lead.Id, templateId, primaryContact.Email));
                    messageLeadIds.add(lead.Id);
                }
            }
            for (Integer startIndex = 0; startIndex < messages.size(); startIndex += EMAIL_BATCH_SIZE) {
                Integer endIndex = Math.min(startIndex + EMAIL_BATCH_SIZE, messages.size());
                List<Messaging.SingleEmailMessage> batch = new List<Messaging.SingleEmailMessage>();
                for (Integer index = startIndex; index < endIndex; index++) batch.add(messages[index]);
                try {
                    List<Messaging.SendEmailResult> results = emailSender.send(batch);
                    for (Integer index = 0; index < results.size(); index++) {
                        if (!results[index].isSuccess()) {
                            String error = results[index].getErrors().isEmpty()
                                ? 'Salesforce did not accept the acknowledgement email.'
                                : results[index].getErrors()[0].getMessage();
                            errors.put(messageLeadIds[startIndex + index], error);
                        }
                    }
                } catch (Exception emailFailure) {
                    String message = String.isBlank(emailFailure.getMessage())
                        ? 'Salesforce did not accept the acknowledgement email.' : emailFailure.getMessage();
                    for (Integer index = startIndex; index < endIndex; index++) errors.put(messageLeadIds[index], message);
                }
            }
        } catch (Exception preparationFailure) {
            for (Lead lead : leads) errors.put(lead.Id, 'The booking details were saved, but the acknowledgement could not be prepared. ' + preparationFailure.getMessage());
        }
        return errors;
    }

    @AuraEnabled
    public static AcknowledgementRetryResult retryAcknowledgement(Id leadId) {
        if (leadId == null || leadId.getSObjectType() != Lead.SObjectType) {
            throw new AuraHandledException('Select a supplementary submission to retry.');
        }
        if (!Lead.SObjectType.getDescribe().isUpdateable()) {
            throw new AuraHandledException('You do not have permission to update this submission.');
        }
        for (Schema.SObjectField field : new List<Schema.SObjectField>{
            Lead.NTE_Update_Status__c, Lead.NTE_Update_Error__c,
            Lead.NTE_Applicant_Email_Status__c, Lead.NTE_Email_Error__c
        }) {
            if (!field.getDescribe().isUpdateable()) throw new AuraHandledException('You do not have permission to record the acknowledgement result.');
        }
        List<Lead> submissions = (List<Lead>)Database.queryWithBinds(
            'SELECT Id, Web_Form_Type__c, Target_Booking_Reference__c, NTE_Update_Status__c, NTE_Applicant_Email_Status__c, NTE_Update_Booking_Id__c '
            + 'FROM Lead WHERE Id = :leadId FOR UPDATE',
            new Map<String, Object>{'leadId' => leadId}, AccessLevel.USER_MODE);
        if (submissions.isEmpty()) throw new AuraHandledException('This submission is not available.');
        Lead submission = submissions[0];
        String templateName = acknowledgementTemplate(submission.Web_Form_Type__c);
        if (templateName == null || submission.NTE_Update_Status__c != 'Matched and Applied'
            || submission.NTE_Applicant_Email_Status__c != 'Failed') {
            throw new AuraHandledException('Only a failed acknowledgement for an already applied update can be retried.');
        }
        AcknowledgementRetryResult result = new AcknowledgementRetryResult();
        result.leadId = leadId;
        String error;
        List<Opportunity> bookings = new List<Opportunity>();
        Id bookingId = appliedBookingId(submission);
        if (bookingId != null) {
            bookings = (List<Opportunity>)Database.queryWithBinds(
                'SELECT Id, Booking_Reference__c FROM Opportunity WHERE Id = :bookingId '
                + 'AND RecordType.DeveloperName = \'NTE_Event_Opportunity\' AND NTE_Event_Code__c != null '
                + 'AND NTE_Source_Form_Type__c IN (\'Exhibitor Application\', \'Partner / Sponsor Application\') FOR UPDATE',
                new Map<String, Object>{'bookingId' => bookingId}, AccessLevel.USER_MODE);
        }
        if (bookings.size() != 1 || !matchesAppliedBooking(submission, bookings[0])) {
            error = 'The acknowledgement was not sent because its saved booking identity and reference could not be verified. The saved booking details were not changed.';
        } else {
            Map<Id, String> errors = dispatchAndRecordAcknowledgements(submissions, new Map<Id, String>{leadId => templateName},
                new Map<Id, Id>{leadId => bookings[0].Id}, bypassEmailDelivery, AccessLevel.USER_MODE);
            error = errors.get(leadId);
        }
        if (bookings.size() != 1 || !matchesAppliedBooking(submission, bookings[0])) {
            writeAcknowledgementAudits(new List<Lead>{acknowledgementAudit(leadId, error)}, AccessLevel.USER_MODE);
        }
        result.success = error == null;
        result.message = error == null ? 'Booking update acknowledgement accepted by Salesforce.' : error;
        return result;
    }

    private static Map<String, Id> templateIds(Set<String> developerNames) {
        Map<String, Id> result = new Map<String, Id>();
        List<EmailTemplate> templates = (List<EmailTemplate>)Database.queryWithBinds(
            'SELECT Id, DeveloperName FROM EmailTemplate WHERE DeveloperName IN :developerNames',
            new Map<String, Object>{'developerNames' => developerNames},
            AccessLevel.SYSTEM_MODE
        );
        for (EmailTemplate templateRecord : templates) result.put(templateRecord.DeveloperName, templateRecord.Id);
        return result;
    }
}
