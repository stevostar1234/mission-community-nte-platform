@IsTest
private class NTEUpdateSubmissionReliabilityTest {
    private static final String ACCEPTANCE_MARKER = 'NTE acknowledgement transaction probe';

    @TestSetup
    static void assignAccess() {
        PermissionSet access = [SELECT Id FROM PermissionSet WHERE Name = 'NTE_Forms_Administration' LIMIT 1];
        if ([SELECT COUNT() FROM PermissionSetAssignment WHERE AssigneeId = :UserInfo.getUserId()
            AND PermissionSetId = :access.Id] == 0) {
            insert new PermissionSetAssignment(AssigneeId = UserInfo.getUserId(), PermissionSetId = access.Id);
        }
    }

    private class Fixture {
        Opportunity booking;
        Lead submission;
    }

    private class TransactionalSender implements NTEUpdateSubmissionService.EmailSender {
        Integer attempts = 0;
        public List<Messaging.SendEmailResult> send(List<Messaging.SingleEmailMessage> messages) {
            List<Messaging.SendEmailResult> results = new List<Messaging.SendEmailResult>();
            List<Task> committedAttempts = new List<Task>();
            for (Messaging.SingleEmailMessage message : messages) {
                attempts++;
                // Like Salesforce's queued email, this marker only survives if the
                // transaction commits. It distinguishes rollback from a status-only fix.
                committedAttempts.add(new Task(Subject = ACCEPTANCE_MARKER));
                results.add((Messaging.SendEmailResult)JSON.deserialize('{"success":true,"errors":[]}',
                    Messaging.SendEmailResult.class));
            }
            insert committedAttempts;
            return results;
        }
    }

    private static Fixture fixture(String suffix) {
        Account company = new Account(Name = 'Northfield Engineering ' + suffix);
        insert company;
        Fixture value = new Fixture();
        value.booking = new Opportunity(Name = company.Name, AccountId = company.Id, StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30), Booking_Reference__c = 'NTE-RELIABILITY-' + suffix,
            RecordTypeId = [SELECT Id FROM RecordType WHERE SobjectType = 'Opportunity'
                AND DeveloperName = 'NTE_Event_Opportunity' LIMIT 1].Id,
            NTE_Event_Code__c = 'NTE2027', NTE_Source_Form_Type__c = 'Exhibitor Application',
            NTE_Initial_Staff_Count__c = 2, NTE_Total_Staff_Count__c = 2, Amount = 120,
            NTE_Listed_Price_Total__c = 100, NTE_VAT_Rate__c = 20,
            NTE_Payment_Received__c = true, NTE_Payment_Received_At__c = System.now().addDays(-2),
            NTE_Payment_Recorded_By__c = 'Existing payment recorder', NTE_Stand_Colleagues__c = 'Older names');
        insert value.booking;
        Contact primary = new Contact(AccountId = company.Id, FirstName = 'Helen', LastName = 'Bancroft',
            Email = 'primary-' + suffix.toLowerCase() + '@example.invalid');
        insert primary;
        insert new OpportunityContactRole(OpportunityId = value.booking.Id, ContactId = primary.Id, IsPrimary = true);
        value.submission = new Lead(FirstName = 'Different', LastName = 'Submitter', Company = company.Name,
            Email = 'submitter@example.invalid', Target_Booking_Reference__c = value.booking.Booking_Reference__c);
        insert value.submission;
        // Simulate the create Flow explicitly below, rather than enqueueing a second job here.
        value.submission.Web_Form_Type__c = 'Exhibitor Staff Update';
        value.submission.Staff_Base_Names__c = 'Helen Bancroft\nOliver Carter';
        value.submission.Top_Up_Staff_Required__c = 'No';
        value.submission.Declaration_Name__c = 'Helen Bancroft';
        value.submission.Declaration_Date__c = Date.today();
        update value.submission;
        return value;
    }

    private static Lead audit(Id id) {
        return [SELECT Id, IsDeleted, NTE_Update_Status__c, NTE_Update_Error__c, NTE_Update_Booking_Id__c,
            NTE_Applicant_Email_Status__c, NTE_Email_Error__c FROM Lead WHERE Id = :id ALL ROWS];
    }

    private static Opportunity savedBooking(Id id) {
        return [SELECT NTE_Stand_Colleagues__c, NTE_Staff_Update_Completed_At__c,
            NTE_Total_Staff_Count__c, NTE_Payment_Received__c, NTE_Payment_Received_At__c,
            NTE_Payment_Recorded_By__c, Amount FROM Opportunity WHERE Id = :id];
    }

    private static NTEUpdateSubmissionService.Request request(Id id, Boolean isNew) {
        NTEUpdateSubmissionService.Request value = new NTEUpdateSubmissionService.Request();
        value.leadId = id; value.isNewSubmission = isNew; return value;
    }

    @IsTest
    static void failedAuditRollsBackAcceptedSendButKeepsBookingUpdate() {
        Fixture value = fixture('AUDIT');
        TransactionalSender sender = new TransactionalSender();
        NTEUpdateSubmissionService.emailSender = sender;
        NTEUpdateSubmissionService.failNextAcknowledgementAuditSave = true;

        Test.startTest();
        // Reproduce the queue's existing catch-and-record behaviour as well as the sender.
        try { NTEUpdateSubmissionService.processLeadIds(new Set<Id>{value.submission.Id}, false); }
        catch (Exception failure) { NTEUpdateSubmissionService.recordUnexpectedFailure(new Set<Id>{value.submission.Id}, failure); }
        System.assertEquals(1, sender.attempts);
        System.assertEquals(0, [SELECT COUNT() FROM Task WHERE Subject = :ACCEPTANCE_MARKER],
            'An accepted send must be rolled back before its audit can be marked failed.');
        Lead failed = audit(value.submission.Id);
        System.assertEquals('Matched and Applied', failed.NTE_Update_Status__c);
        System.assertEquals('Failed', failed.NTE_Applicant_Email_Status__c);
        System.assertEquals(false, failed.IsDeleted);
        System.assert(failed.NTE_Email_Error__c.contains('result could not be saved'));
        Opportunity applied = savedBooking(value.booking.Id);
        System.assertEquals(value.submission.Staff_Base_Names__c, applied.NTE_Stand_Colleagues__c);
        System.assertEquals(value.booking.NTE_Payment_Received_At__c, applied.NTE_Payment_Received_At__c);
        System.assertEquals(true, applied.NTE_Payment_Received__c);
        Datetime appliedAt = applied.NTE_Staff_Update_Completed_At__c;

        System.assertEquals(true, NTEUpdateSubmissionService.retryAcknowledgement(value.submission.Id).success);
        NTEUpdateSubmissionService.processLeadIds(new Set<Id>{value.submission.Id}, false);
        Test.stopTest();
        System.assertEquals(2, sender.attempts, 'There is one rolled-back attempt and one accepted retry.');
        System.assertEquals(1, [SELECT COUNT() FROM Task WHERE Subject = :ACCEPTANCE_MARKER]);
        System.assertEquals('Accepted by Salesforce', audit(value.submission.Id).NTE_Applicant_Email_Status__c);
        System.assertEquals(appliedAt, savedBooking(value.booking.Id).NTE_Staff_Update_Completed_At__c,
            'Acknowledgement recovery must not reapply staff details.');
    }

    @IsTest
    static void retryAuditFailureAlsoRollsBackItsAttempt() {
        Fixture value = fixture('RETRY');
        NTEUpdateSubmissionService.acknowledgementFailureOverride = 'Initial email refusal';
        NTEUpdateSubmissionService.processLeadIds(new Set<Id>{value.submission.Id}, true);
        NTEUpdateSubmissionService.acknowledgementFailureOverride = null;
        TransactionalSender sender = new TransactionalSender();
        NTEUpdateSubmissionService.emailSender = sender;
        NTEUpdateSubmissionService.failNextAcknowledgementAuditSave = true;
        Datetime appliedAt = savedBooking(value.booking.Id).NTE_Staff_Update_Completed_At__c;

        Test.startTest();
        System.assertEquals(false, NTEUpdateSubmissionService.retryAcknowledgement(value.submission.Id).success);
        System.assertEquals(0, [SELECT COUNT() FROM Task WHERE Subject = :ACCEPTANCE_MARKER]);
        System.assertEquals('Failed', audit(value.submission.Id).NTE_Applicant_Email_Status__c);
        System.assertEquals(true, NTEUpdateSubmissionService.retryAcknowledgement(value.submission.Id).success);
        Boolean duplicateRejected = false;
        try { NTEUpdateSubmissionService.retryAcknowledgement(value.submission.Id); }
        catch (AuraHandledException expected) { duplicateRejected = true; }
        Test.stopTest();
        System.assert(duplicateRejected);
        System.assertEquals(1, [SELECT COUNT() FROM Task WHERE Subject = :ACCEPTANCE_MARKER]);
        System.assertEquals(2, sender.attempts);
        System.assertEquals(appliedAt, savedBooking(value.booking.Id).NTE_Staff_Update_Completed_At__c);
    }

    @IsTest
    static void batchAuditFailureKeepsBothUpdatesAndRetriesOnlySelectedReceipt() {
        Fixture first = fixture('BATCH1'); Fixture second = fixture('BATCH2');
        TransactionalSender sender = new TransactionalSender(); NTEUpdateSubmissionService.emailSender = sender;
        NTEUpdateSubmissionService.failNextAcknowledgementAuditSave = true;
        Test.startTest();
        NTEUpdateSubmissionService.processLeadIds(new Set<Id>{first.submission.Id, second.submission.Id}, false);
        System.assertEquals(0, [SELECT COUNT() FROM Task WHERE Subject = :ACCEPTANCE_MARKER]);
        for (Fixture value : new List<Fixture>{first, second}) {
            System.assertEquals(value.submission.Staff_Base_Names__c, savedBooking(value.booking.Id).NTE_Stand_Colleagues__c);
            System.assertEquals('Failed', audit(value.submission.Id).NTE_Applicant_Email_Status__c);
        }
        System.assertEquals(true, NTEUpdateSubmissionService.retryAcknowledgement(first.submission.Id).success);
        Test.stopTest();
        System.assertEquals(1, [SELECT COUNT() FROM Task WHERE Subject = :ACCEPTANCE_MARKER]);
        System.assertEquals('Failed', audit(second.submission.Id).NTE_Applicant_Email_Status__c);
    }

    @IsTest
    static void defaultApplyDoesNotReplayAcceptedOrRejectedData() {
        Fixture accepted = fixture('ACCEPTED'); Fixture rejected = fixture('REJECTED');
        update new List<Lead>{
            new Lead(Id = accepted.submission.Id, NTE_Update_Status__c = 'Matched and Applied',
                NTE_Update_Booking_Id__c = String.valueOf(accepted.booking.Id), NTE_Applicant_Email_Status__c = 'Accepted by Salesforce'),
            new Lead(Id = rejected.submission.Id, NTE_Update_Status__c = 'No Matching Booking', NTE_Update_Error__c = 'Original unmatched submission')
        };
        update new Opportunity(Id = accepted.booking.Id, NTE_Stand_Colleagues__c = 'Newer accepted names');
        NTEUpdateSubmissionService.bypassEmailDelivery = true;
        Test.startTest();
        NTEUpdateSubmissionService.applyUpdates(new List<NTEUpdateSubmissionService.Request>{
            request(accepted.submission.Id, false), request(rejected.submission.Id, false)
        });
        System.assertEquals(0, Limits.getQueueableJobs());
        Test.stopTest();
        System.assertEquals('Newer accepted names', savedBooking(accepted.booking.Id).NTE_Stand_Colleagues__c);
        System.assertEquals('Accepted by Salesforce', audit(accepted.submission.Id).NTE_Applicant_Email_Status__c);
        System.assertEquals(String.valueOf(accepted.booking.Id), audit(accepted.submission.Id).NTE_Update_Booking_Id__c);
        System.assertEquals(false, audit(accepted.submission.Id).IsDeleted);
        System.assertEquals('Older names', savedBooking(rejected.booking.Id).NTE_Stand_Colleagues__c);
        System.assertEquals('No Matching Booking', audit(rejected.submission.Id).NTE_Update_Status__c);
        System.assertEquals('Original unmatched submission', audit(rejected.submission.Id).NTE_Update_Error__c);
    }

    @IsTest
    static void createEntryClearsForgedAuditAndQueuesOnce() {
        Fixture value = fixture('CREATE');
        update new Lead(Id = value.submission.Id, NTE_Update_Status__c = 'Matched and Applied',
            NTE_Update_Booking_Id__c = '006000000000001', NTE_Applicant_Email_Status__c = 'Accepted by Salesforce');
        NTEUpdateSubmissionService.bypassEmailDelivery = true;
        NTEUpdateSubmissionService.Request newRequest = request(value.submission.Id, true);
        Test.startTest();
        NTEUpdateSubmissionService.applyUpdates(new List<NTEUpdateSubmissionService.Request>{newRequest, newRequest});
        Lead pending = audit(value.submission.Id);
        System.assertEquals('Pending', pending.NTE_Update_Status__c);
        System.assertEquals(null, pending.NTE_Update_Booking_Id__c);
        System.assertEquals(null, pending.NTE_Applicant_Email_Status__c);
        NTEUpdateSubmissionService.applyUpdates(new List<NTEUpdateSubmissionService.Request>{newRequest});
        System.assertEquals(1, Limits.getQueueableJobs());
        Test.stopTest();
        System.assertEquals(value.submission.Staff_Base_Names__c, savedBooking(value.booking.Id).NTE_Stand_Colleagues__c);
        System.assertEquals(String.valueOf(value.booking.Id), audit(value.submission.Id).NTE_Update_Booking_Id__c);
        System.assertEquals('Accepted by Salesforce', audit(value.submission.Id).NTE_Applicant_Email_Status__c);
    }

    @IsTest
    static void terminalJobFailureOnlyMarksItsStillPendingSubmissions() {
        List<Lead> rows = new List<Lead>();
        for (Integer index = 0; index < 4; index++) rows.add(new Lead(LastName = 'Job ' + index, Company = 'Queue audit'));
        insert rows;
        update new List<Lead>{
            new Lead(Id = rows[0].Id, NTE_Update_Status__c = 'Pending'),
            new Lead(Id = rows[1].Id, NTE_Update_Status__c = 'Matched and Applied', NTE_Applicant_Email_Status__c = 'Accepted by Salesforce',
                NTE_Update_Booking_Id__c = '006000000000001'),
            new Lead(Id = rows[2].Id, NTE_Update_Status__c = 'Failed', NTE_Update_Error__c = 'Existing rejection'),
            new Lead(Id = rows[3].Id, NTE_Update_Status__c = 'Pending')
        };
        Test.startTest();
        NTEUpdateSubmissionJob.recordTerminalFailure(new Set<Id>{rows[0].Id, rows[1].Id, rows[2].Id}, 'CPU limit exceeded');
        NTEUpdateSubmissionJob.recordTerminalFailure(new Set<Id>{rows[0].Id}, 'A repeated finalizer');
        NTEUpdateSubmissionJob.recordTerminalFailure(null, null);
        NTEUpdateSubmissionJob.recordTerminalFailure(new Set<Id>(), null);
        Test.stopTest();
        System.assertEquals('Failed', audit(rows[0].Id).NTE_Update_Status__c);
        System.assert(audit(rows[0].Id).NTE_Update_Error__c.contains('CPU limit exceeded'));
        System.assertEquals('Matched and Applied', audit(rows[1].Id).NTE_Update_Status__c);
        System.assertEquals('Accepted by Salesforce', audit(rows[1].Id).NTE_Applicant_Email_Status__c);
        System.assertEquals('006000000000001', audit(rows[1].Id).NTE_Update_Booking_Id__c);
        System.assertEquals('Existing rejection', audit(rows[2].Id).NTE_Update_Error__c);
        System.assertEquals('Pending', audit(rows[3].Id).NTE_Update_Status__c);
    }
}
