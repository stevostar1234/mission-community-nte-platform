/** Routes a booking's retry action to its existing confirmation workflow. */
public with sharing class NTEBookingEmailRetryService {
    private static final Set<String> APPLICATION_TYPES = new Set<String>{
        'Exhibitor Application', 'Partner / Sponsor Application'
    };

    @AuraEnabled
    public static NTEEmailDispatchService.QueueResponse retryBookingEmail(Id opportunityId) {
        if (opportunityId == null || opportunityId.getSObjectType() != Opportunity.SObjectType
            || !Schema.sObjectType.Opportunity.isUpdateable()) {
            throw handled('Select an NTE booking you can update.');
        }
        List<Opportunity> bookings;
        try {
            bookings = [SELECT Id, NTE_Payment_Received__c FROM Opportunity
                WHERE Id = :opportunityId AND RecordType.DeveloperName = 'NTE_Event_Opportunity'
                AND NTE_Source_Form_Type__c IN :APPLICATION_TYPES AND NTE_Event_Code__c != null
                AND (IsClosed = false OR IsWon = true) WITH USER_MODE];
        } catch (QueryException accessFailure) {
            throw handled('Select an NTE booking you can update.');
        }
        if (bookings.isEmpty()) throw handled('Select an active NTE booking you can update.');

        if (!bookings[0].NTE_Payment_Received__c) {
            NTEExhibitorApprovalEmailService.ApprovalRetryResult approval =
                NTEExhibitorApprovalEmailService.retryApprovalEmail(opportunityId);
            NTEEmailDispatchService.QueueResponse result = new NTEEmailDispatchService.QueueResponse();
            result.queuedCount = approval.queuedCount;
            result.skippedCount = approval.queuedCount > 0 ? 0 : 1;
            result.message = approval.message;
            return result;
        }

        List<NTE_Email_Dispatch__c> confirmations = [SELECT Id, Status__c, Sent_At__c
            FROM NTE_Email_Dispatch__c WHERE Opportunity__c = :opportunityId
            AND Kind__c = 'BOOKING_CONFIRMED' AND Run_Id__c = 'BOOKING_PAYMENT'
            WITH USER_MODE LIMIT 2];
        if (confirmations.isEmpty()) return NTEEmailDispatchService.queueBookingConfirmation(opportunityId);
        if (confirmations.size() > 1) {
            throw handled('More than one booking confirmation was found. Review the booking email history.');
        }
        NTE_Email_Dispatch__c confirmation = confirmations[0];
        if (confirmation.Status__c == 'Sent' || confirmation.Sent_At__c != null) {
            return unchanged('The booking confirmation has already been sent. Forward the original email if another copy is needed.');
        }
        if (confirmation.Status__c == 'Queued') return unchanged('The booking confirmation is already queued.');
        if (confirmation.Status__c == 'Failed') return NTEEmailDispatchService.retryDispatch(confirmation.Id);
        return unchanged('Check the booking confirmation in NTE Email Failures before retrying.');
    }

    private static NTEEmailDispatchService.QueueResponse unchanged(String message) {
        NTEEmailDispatchService.QueueResponse result = new NTEEmailDispatchService.QueueResponse();
        result.queuedCount = 0;
        result.skippedCount = 1;
        result.message = message;
        return result;
    }

    private static AuraHandledException handled(String message) {
        AuraHandledException failure = new AuraHandledException(message);
        failure.setMessage(message);
        return failure;
    }
}
