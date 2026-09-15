/** Route the existing Lead retry action to its failed notification channel(s). */
public with sharing class NTELeadEmailRetryService {
    private static final String ACCEPTED = 'Accepted by Salesforce';
    private static final Set<String> INTAKE_TYPES = new Set<String>{
        'Exhibitor Expression of Interest', 'Partner / Sponsor Expression of Interest',
        'Exhibitor Application', 'Partner / Sponsor Application', 'Guest Registration'
    };
    private static final Set<String> UPDATE_TYPES = new Set<String>{
        'Exhibitor Staff Update', 'Partner / Sponsor Staff Update', 'Heavy Vehicle Details', 'Logo Update'
    };

    public class RetryResult {
        @AuraEnabled public Boolean success;
        @AuraEnabled public Boolean partialSuccess;
        @AuraEnabled public String message;
        @AuraEnabled public String applicantStatus;
        @AuraEnabled public String internalStatus;
    }

    @AuraEnabled
    public static RetryResult retryFailedEmails(Id leadId) {
        if (leadId == null || leadId.getSObjectType() != Lead.SObjectType
            || !Lead.SObjectType.getDescribe().isUpdateable()) {
            throw handled('Select a submission you can update.');
        }
        List<Lead> sources = [SELECT Id, Web_Form_Type__c, LeadSource, IsConverted, Email, OwnerId
            FROM Lead WHERE Id = :leadId WITH USER_MODE FOR UPDATE];
        if (sources.isEmpty()) throw handled('This submission is not available.');
        Lead source = sources[0];
        if (UPDATE_TYPES.contains(source.Web_Form_Type__c)) {
            NTEUpdateSubmissionService.AcknowledgementRetryResult acknowledgement =
                NTEUpdateSubmissionService.retryAcknowledgement(leadId);
            RetryResult result = new RetryResult();
            result.success = acknowledgement.success; result.partialSuccess = false;
            result.message = acknowledgement.message;
            return result;
        }

        Boolean volunteer = source.Web_Form_Type__c == 'Volunteer Application'
            && source.LeadSource == 'Volunteer Application';
        if (!volunteer && !INTAKE_TYPES.contains(source.Web_Form_Type__c)) {
            throw handled('This submission does not use an NTE or volunteer notification route.');
        }
        List<Schema.SObjectField> auditFields = volunteer
            ? new List<Schema.SObjectField>{Lead.Volunteer_Applicant_Email_Status__c,
                Lead.Volunteer_Internal_Email_Status__c, Lead.Volunteer_Email_Error__c}
            : new List<Schema.SObjectField>{Lead.NTE_Applicant_Email_Status__c,
                Lead.NTE_Internal_Email_Status__c, Lead.NTE_Email_Error__c};
        for (Schema.SObjectField field : auditFields) {
            if (!field.getDescribe().isAccessible() || !field.getDescribe().isUpdateable()) {
                throw handled('You do not have permission to record this email result.');
            }
        }
        String applicantField = volunteer ? 'Volunteer_Applicant_Email_Status__c' : 'NTE_Applicant_Email_Status__c';
        String internalField = volunteer ? 'Volunteer_Internal_Email_Status__c' : 'NTE_Internal_Email_Status__c';
        String errorField = volunteer ? 'Volunteer_Email_Error__c' : 'NTE_Email_Error__c';
        Lead before = readAudit(leadId, applicantField, internalField, errorField);
        if (before.get(applicantField) != 'Failed' && before.get(internalField) != 'Failed') {
            throw handled('There are no failed emails to retry. Previously accepted emails will not be resent.');
        }

        // Existing senders retain accepted channels and validate current recipients.
        // This is explicitly a retry; it must never reset first-intake state.
        if (volunteer) {
            VolunteerInboundLeadService.Request request = new VolunteerInboundLeadService.Request();
            request.leadId = leadId; request.isNewSubmission = false;
            VolunteerInboundLeadService.notifyOwner(new List<VolunteerInboundLeadService.Request>{request});
        } else {
            NTEInboundLeadService.Request request = new NTEInboundLeadService.Request();
            request.leadId = leadId; request.isNewSubmission = false;
            NTEInboundLeadService.routeAndAcknowledge(new List<NTEInboundLeadService.Request>{request});
        }
        Lead after = readAudit(leadId, applicantField, internalField, errorField);
        RetryResult result = new RetryResult();
        result.applicantStatus = (String)after.get(applicantField);
        result.internalStatus = (String)after.get(internalField);
        result.success = new Set<String>{ACCEPTED, 'Not required'}.contains(result.applicantStatus)
            && result.internalStatus == ACCEPTED;
        result.partialSuccess = !result.success
            && ((before.get(applicantField) != ACCEPTED && result.applicantStatus == ACCEPTED)
                || (before.get(internalField) != ACCEPTED && result.internalStatus == ACCEPTED));
        String error = (String)after.get(errorField);
        if (result.success) result.message = 'Failed email notifications accepted by Salesforce. Previously accepted messages were not resent.';
        else if (source.IsConverted) result.message = 'This submission has been converted. The intake email sender did not retry it. Use the booking email actions or contact the recipient directly.';
        else result.message = (result.partialSuccess ? 'Some notifications were accepted. ' : '')
            + (String.isBlank(error) ? 'A notification still needs attention. Check the email status and recipient details.' : error);
        return result;
    }

    private static Lead readAudit(Id leadId, String applicantField, String internalField, String errorField) {
        return ((List<Lead>)Database.queryWithBinds('SELECT Id,' + applicantField + ',' + internalField + ',' + errorField
            + ' FROM Lead WHERE Id = :leadId', new Map<String, Object>{'leadId' => leadId}, AccessLevel.USER_MODE))[0];
    }

    private static AuraHandledException handled(String message) {
        AuraHandledException error = new AuraHandledException(message); error.setMessage(message); return error;
    }
}
