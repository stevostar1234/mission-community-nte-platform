public with sharing class NTEUpdateSubmissionJob implements Queueable {
    private String leadIdPayload;
    private Boolean skipEmailDelivery;

    public NTEUpdateSubmissionJob(String leadIdPayload, Boolean skipEmailDelivery) {
        this.leadIdPayload = leadIdPayload;
        this.skipEmailDelivery = skipEmailDelivery == true;
    }

    public void execute(QueueableContext context) {
        if (String.isBlank(leadIdPayload)) return;
        Set<Id> leadIds = new Set<Id>();
        try {
            for (String serializedLeadId : leadIdPayload.split(',')) {
                if (String.isNotBlank(serializedLeadId)) leadIds.add((Id)serializedLeadId.trim());
            }
            if (leadIds.isEmpty()) return;
            System.attachFinalizer(new UpdateFinalizer(leadIds));
            NTEUpdateSubmissionService.processLeadIds(leadIds, skipEmailDelivery);
        } catch (Exception exceptionValue) {
            NTEUpdateSubmissionService.recordUnexpectedFailure(leadIds, exceptionValue);
        }
    }

    private class UpdateFinalizer implements Finalizer {
        private Set<Id> leadIds;
        UpdateFinalizer(Set<Id> submissionIds) { leadIds = submissionIds; }
        public void execute(FinalizerContext context) {
            if (context.getResult() == ParentJobResult.SUCCESS) return;
            Exception failure = context.getException();
            recordTerminalFailure(leadIds, failure == null ? null : failure.getMessage());
        }
    }

    @TestVisible
    private static void recordTerminalFailure(Set<Id> leadIds, String error) {
        if (leadIds == null || leadIds.isEmpty()) return;
        List<Lead> pending = (List<Lead>)Database.queryWithBinds(
            'SELECT Id FROM Lead WHERE Id IN :leadIds AND NTE_Update_Status__c = \'Pending\' FOR UPDATE',
            new Map<String, Object>{'leadIds' => leadIds}, AccessLevel.SYSTEM_MODE);
        String message = ('The supplementary update job failed before its changes were saved. Review this submission. '
            + (String.isBlank(error) ? '' : error)).left(32000);
        for (Lead submission : pending) {
            submission.NTE_Update_Status__c = 'Failed';
            submission.NTE_Update_Error__c = message;
        }
        if (!pending.isEmpty()) Database.update(pending, false, AccessLevel.SYSTEM_MODE);
    }
}
