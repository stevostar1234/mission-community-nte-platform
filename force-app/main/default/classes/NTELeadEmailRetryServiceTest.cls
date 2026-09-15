@IsTest
private class NTELeadEmailRetryServiceTest {
    @TestSetup
    static void assignAccess() {
        PermissionSet access = [SELECT Id FROM PermissionSet WHERE Name = 'NTE_Forms_Administration' LIMIT 1];
        if ([SELECT COUNT() FROM PermissionSetAssignment WHERE AssigneeId = :UserInfo.getUserId()
            AND PermissionSetId = :access.Id] == 0) {
            insert new PermissionSetAssignment(AssigneeId = UserInfo.getUserId(), PermissionSetId = access.Id);
        }
    }
    private class Sender implements NTEInboundLeadService.EmailSender, VolunteerInboundLeadService.EmailSender,
        NTEUpdateSubmissionService.EmailSender {
        List<Messaging.SingleEmailMessage> messages = new List<Messaging.SingleEmailMessage>();
        public List<Messaging.SendEmailResult> send(List<Messaging.SingleEmailMessage> outgoing) {
            messages.addAll(outgoing);
            List<Messaging.SendEmailResult> results = new List<Messaging.SendEmailResult>();
            for (Messaging.SingleEmailMessage message : outgoing) results.add((Messaging.SendEmailResult)JSON.deserialize(
                '{"success":true,"errors":[]}', Messaging.SendEmailResult.class));
            return results;
        }
    }
    private static Lead submission(String type) {
        NTEInboundLeadService.bypassEmailDelivery = true;
        NTEInboundLeadService.ownerUsernameOverride = '';
        VolunteerInboundLeadService.bypassEmailDelivery = true;
        Lead lead = new Lead(FirstName = 'Harriet', LastName = 'Bancroft', Company = 'Willow Engineering',
            Email = 'harriet@example.invalid', Web_Form_Type__c = type, NTE_Event_Code__c = 'NTE2027',
            LeadSource = type == 'Volunteer Application' ? 'Volunteer Application' : 'Customer Event');
        insert lead;
        NTEInboundLeadService.bypassEmailDelivery = false;
        VolunteerInboundLeadService.bypassEmailDelivery = false;
        return lead;
    }
    private static Sender sender() {
        Sender value = new Sender(); NTEInboundLeadService.emailSender = value;
        VolunteerInboundLeadService.emailSender = value; NTEUpdateSubmissionService.emailSender = value; return value;
    }

    @IsTest
    static void guestApplicantRetryUsesCorrectedEmailWithoutRepeatingOwner() {
        Lead lead = submission('Guest Registration');
        update new Lead(Id = lead.Id, Email = 'corrected@example.invalid',
            NTE_Applicant_Email_Status__c = 'Failed', NTE_Internal_Email_Status__c = 'Accepted by Salesforce');
        Sender value = sender();
        Test.startTest();
        NTELeadEmailRetryService.RetryResult result = NTELeadEmailRetryService.retryFailedEmails(lead.Id);
        Test.stopTest();
        System.assertEquals(true, result.success); System.assertEquals(1, value.messages.size());
        System.assertEquals(lead.Id, value.messages[0].getTargetObjectId());
        System.assert(value.messages[0].getToAddresses() == null || value.messages[0].getToAddresses().isEmpty(),
            'The corrected Lead email is used by the template recipient.');
        System.assertEquals('corrected@example.invalid', [SELECT Email FROM Lead WHERE Id = :lead.Id].Email);
        System.assertEquals('Accepted by Salesforce', result.internalStatus);
    }

    @IsTest
    static void internalRetryDoesNotRepeatApplicantOrResetInterestDecision() {
        Lead lead = submission('Exhibitor Expression of Interest');
        update new Lead(Id = lead.Id, NTE_Applicant_Email_Status__c = 'Accepted by Salesforce',
            NTE_Internal_Email_Status__c = 'Failed', NTE_Interest_Progressed__c = true);
        Sender value = sender();
        Test.startTest();
        System.assertEquals(true, NTELeadEmailRetryService.retryFailedEmails(lead.Id).success);
        Test.stopTest();
        System.assertEquals(1, value.messages.size());
        System.assertEquals(1, value.messages[0].getToAddresses().size());
        System.assertEquals(new List<String>{[SELECT Email FROM User WHERE Id = :UserInfo.getUserId()].Email},
            value.messages[0].getToAddresses());
        System.assertEquals(true, [SELECT NTE_Interest_Progressed__c FROM Lead WHERE Id = :lead.Id].NTE_Interest_Progressed__c);
    }

    @IsTest
    static void applicationRetryNeverRevivesRetiredAcknowledgement() {
        Lead lead = submission('Partner / Sponsor Application');
        update new Lead(Id = lead.Id, NTE_Applicant_Email_Status__c = 'Failed', NTE_Internal_Email_Status__c = 'Failed');
        Sender value = sender();
        Test.startTest();
        NTELeadEmailRetryService.RetryResult result = NTELeadEmailRetryService.retryFailedEmails(lead.Id);
        Test.stopTest();
        System.assertEquals(true, result.success);
        System.assertEquals('Not required', result.applicantStatus);
        System.assertEquals(1, value.messages.size());
        System.assertEquals(new List<String>{[SELECT Email FROM User WHERE Id = :UserInfo.getUserId()].Email},
            value.messages[0].getToAddresses());
    }

    @IsTest
    static void volunteerRetryPreservesAcceptedApplicant() {
        Lead lead = submission('Volunteer Application');
        update new Lead(Id = lead.Id, Volunteer_Applicant_Email_Status__c = 'Accepted by Salesforce',
            Volunteer_Internal_Email_Status__c = 'Failed');
        Sender value = sender();
        Test.startTest();
        NTELeadEmailRetryService.RetryResult result = NTELeadEmailRetryService.retryFailedEmails(lead.Id);
        Test.stopTest();
        System.assertEquals(true, result.success); System.assertEquals(1, value.messages.size());
        System.assertEquals(new List<String>{[SELECT Email FROM User WHERE Id = :UserInfo.getUserId()].Email},
            value.messages[0].getToAddresses());
    }

    @IsTest
    static void remainingInvalidRecipientIsReportedWithoutClaimingSuccess() {
        Lead lead = submission('Guest Registration');
        update new Lead(Id = lead.Id, Email = null, NTE_Applicant_Email_Status__c = 'Failed', NTE_Internal_Email_Status__c = 'Failed');
        Sender value = sender();
        Test.startTest();
        NTELeadEmailRetryService.RetryResult result = NTELeadEmailRetryService.retryFailedEmails(lead.Id);
        Test.stopTest();
        System.assertEquals(false, result.success); System.assertEquals(true, result.partialSuccess);
        System.assertEquals('Failed', result.applicantStatus); System.assertEquals(1, value.messages.size());
        System.assert(result.message.contains('blank'));
    }

    @IsTest
    static void acceptedAndUnsupportedRecordsCannotBeResent() {
        Lead lead = submission('Guest Registration');
        update new Lead(Id = lead.Id, NTE_Applicant_Email_Status__c = 'Accepted by Salesforce', NTE_Internal_Email_Status__c = 'Accepted by Salesforce');
        Sender value = sender();
        Test.startTest();
        Boolean rejected = false;
        try { NTELeadEmailRetryService.retryFailedEmails(lead.Id); } catch (AuraHandledException expected) { rejected = true; }
        System.assert(rejected);
        update new Lead(Id = lead.Id, Web_Form_Type__c = null);
        rejected = false;
        try { NTELeadEmailRetryService.retryFailedEmails(lead.Id); } catch (AuraHandledException expected) { rejected = true; }
        System.assert(rejected);
        rejected = false;
        try { NTELeadEmailRetryService.retryFailedEmails(null); } catch (AuraHandledException expected) { rejected = true; }
        System.assert(rejected);
        Test.stopTest();
        System.assertEquals(0, value.messages.size());
    }

    @IsTest
    static void supplementaryRetryUsesCurrentPrimaryContactWithoutReapplyingData() {
        Account company = new Account(Name = 'Willow Supplementary Recovery'); insert company;
        Opportunity booking = new Opportunity(Name = company.Name, AccountId = company.Id,
            StageName = 'Prospecting', CloseDate = Date.today().addDays(30),
            RecordTypeId = [SELECT Id FROM RecordType WHERE SobjectType = 'Opportunity'
                AND DeveloperName = 'NTE_Event_Opportunity' LIMIT 1].Id,
            Booking_Reference__c = 'NTE-RETRY-SUPPLEMENTARY', NTE_Event_Code__c = 'NTE2027',
            NTE_Source_Form_Type__c = 'Exhibitor Application', Amount = 120,
            NTE_Listed_Price_Total__c = 100, NTE_VAT_Rate__c = 20,
            NTE_Stand_Colleagues__c = 'Newer accepted staff details');
        insert booking;
        Contact primary = new Contact(AccountId = company.Id, LastName = 'Primary', Email = 'corrected-primary@example.invalid');
        insert primary;
        insert new OpportunityContactRole(OpportunityId = booking.Id, ContactId = primary.Id, IsPrimary = true);
        Lead lead = submission(null);
        update new Lead(Id = lead.Id, Web_Form_Type__c = 'Exhibitor Staff Update',
            Target_Booking_Reference__c = booking.Booking_Reference__c,
            NTE_Update_Booking_Id__c = String.valueOf(booking.Id), NTE_Update_Status__c = 'Matched and Applied',
            NTE_Applicant_Email_Status__c = 'Failed', Staff_Base_Names__c = 'Older source names');
        Sender value = sender();
        Test.startTest();
        NTELeadEmailRetryService.RetryResult result = NTELeadEmailRetryService.retryFailedEmails(lead.Id);
        Boolean acceptedRetryRejected = false;
        try { NTELeadEmailRetryService.retryFailedEmails(lead.Id); }
        catch (AuraHandledException expected) { acceptedRetryRejected = true; }
        Test.stopTest();
        System.assertEquals(true, result.success); System.assertEquals(false, result.partialSuccess);
        System.assertEquals(1, value.messages.size());
        System.assertEquals(new List<String>{primary.Email}, value.messages[0].getToAddresses());
        System.assertEquals('Newer accepted staff details', [SELECT NTE_Stand_Colleagues__c
            FROM Opportunity WHERE Id = :booking.Id].NTE_Stand_Colleagues__c);
        System.assert(acceptedRetryRejected);
    }
}
