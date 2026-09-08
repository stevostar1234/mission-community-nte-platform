@IsTest
private class VolunteerInboundLeadServiceTest {
    private static final String ACCEPTED = 'Accepted by Salesforce';

    private class SenderFailureException extends Exception {}

    private class StubSender implements VolunteerInboundLeadService.EmailSender {
        Integer calls = 0;
        List<Messaging.SingleEmailMessage> messages = new List<Messaging.SingleEmailMessage>();
        Boolean rejectInternal = false;
        Boolean throwFailure = false;
        Boolean omitLastResult = false;
        public List<Messaging.SendEmailResult> send(List<Messaging.SingleEmailMessage> outgoing) {
            calls++;
            messages.addAll(outgoing);
            if (throwFailure) throw new SenderFailureException('Email service is unavailable.');
            List<Messaging.SendEmailResult> results = new List<Messaging.SendEmailResult>();
            for (Integer index = 0; index < outgoing.size(); index++) {
                if (omitLastResult && index == outgoing.size() - 1) continue;
                Boolean internalMessage = outgoing[index].getToAddresses() != null && !outgoing[index].getToAddresses().isEmpty();
                results.add((Messaging.SendEmailResult)JSON.deserialize(
                    rejectInternal && internalMessage ? '{"success":false,"errors":[]}' : '{"success":true,"errors":[]}',
                    Messaging.SendEmailResult.class));
            }
            return results;
        }
    }

    private static Lead volunteerLead(String suffix) {
        return new Lead(FirstName = 'Jamie', LastName = 'Palmer', Company = 'Individual Volunteer',
            Email = 'volunteer-' + suffix + '@example.invalid', LeadSource = 'Volunteer Application',
            Web_Form_Type__c = 'Volunteer Application');
    }

    private static Lead pendingLead(String suffix) {
        VolunteerInboundLeadService.bypassEmailDelivery = true;
        Lead lead = volunteerLead(suffix);
        Database.insert(lead, AccessLevel.SYSTEM_MODE);
        VolunteerInboundLeadService.bypassEmailDelivery = false;
        return lead;
    }

    private static VolunteerInboundLeadService.Request requestFor(Id leadId) {
        VolunteerInboundLeadService.Request request = new VolunteerInboundLeadService.Request();
        request.leadId = leadId;
        return request;
    }

    private static Lead auditFor(Id leadId) {
        return [SELECT OwnerId, Volunteer_Applicant_Email_Status__c, Volunteer_Internal_Email_Status__c,
            Volunteer_Email_Error__c FROM Lead WHERE Id = :leadId];
    }

    @IsTest
    static void recordsBlankApplicantEmailThenRetriesOnlyThatMessage() {
        Lead lead = pendingLead('blank');
        Database.update(new Lead(Id = lead.Id, Email = null), AccessLevel.SYSTEM_MODE);
        StubSender sender = new StubSender();
        VolunteerInboundLeadService.emailSender = sender;
        Test.startTest();
        VolunteerInboundLeadService.notifyOwner(new List<VolunteerInboundLeadService.Request>{requestFor(lead.Id)});
        Lead failed = auditFor(lead.Id);
        System.assertEquals('Failed', failed.Volunteer_Applicant_Email_Status__c);
        System.assertEquals(ACCEPTED, failed.Volunteer_Internal_Email_Status__c);
        System.assert(failed.Volunteer_Email_Error__c.contains('email address is blank'));
        System.assertEquals(1, sender.messages.size());

        Database.update(new Lead(Id = lead.Id, Email = 'alex.bennett@example.invalid'), AccessLevel.SYSTEM_MODE);
        VolunteerInboundLeadService.notifyOwner(new List<VolunteerInboundLeadService.Request>{requestFor(lead.Id)});
        Test.stopTest();
        Lead recovered = auditFor(lead.Id);
        System.assertEquals(ACCEPTED, recovered.Volunteer_Applicant_Email_Status__c);
        System.assertEquals(ACCEPTED, recovered.Volunteer_Internal_Email_Status__c);
        System.assertEquals(null, recovered.Volunteer_Email_Error__c);
        System.assertEquals(2, sender.messages.size(), 'The accepted owner notification must not be repeated.');
    }

    @IsTest
    static void recordsSalesforceAcceptanceWithoutDuplicateInvocation() {
        Lead lead = pendingLead('accepted');
        VolunteerInboundLeadService.Request request = requestFor(lead.Id);
        request.isNewSubmission = true;
        Test.startTest();
        VolunteerInboundLeadService.notifyOwner(new List<VolunteerInboundLeadService.Request>{request, request, null});
        System.assertEquals(1, Limits.getEmailInvocations());
        VolunteerInboundLeadService.notifyOwner(new List<VolunteerInboundLeadService.Request>{request});
        System.assertEquals(1, Limits.getEmailInvocations(), 'Repeated create or retry calls must not resend accepted messages.');
        Test.stopTest();
        Lead audited = auditFor(lead.Id);
        System.assertEquals(ACCEPTED, audited.Volunteer_Applicant_Email_Status__c);
        System.assertEquals(ACCEPTED, audited.Volunteer_Internal_Email_Status__c);
        System.assertEquals(null, audited.Volunteer_Email_Error__c);
    }

    @IsTest
    static void partialRejectionAndMissingResultsRemainRetryable() {
        Lead lead = pendingLead('partial');
        StubSender sender = new StubSender();
        sender.rejectInternal = true;
        VolunteerInboundLeadService.emailSender = sender;
        Test.startTest();
        VolunteerInboundLeadService.notifyOwner(new List<VolunteerInboundLeadService.Request>{requestFor(lead.Id)});
        Lead failed = auditFor(lead.Id);
        System.assertEquals(ACCEPTED, failed.Volunteer_Applicant_Email_Status__c);
        System.assertEquals('Failed', failed.Volunteer_Internal_Email_Status__c);
        sender.rejectInternal = false;
        sender.omitLastResult = true;
        VolunteerInboundLeadService.notifyOwner(new List<VolunteerInboundLeadService.Request>{requestFor(lead.Id)});
        System.assertEquals('Failed', auditFor(lead.Id).Volunteer_Internal_Email_Status__c);
        sender.omitLastResult = false;
        VolunteerInboundLeadService.notifyOwner(new List<VolunteerInboundLeadService.Request>{requestFor(lead.Id)});
        Test.stopTest();
        System.assertEquals(ACCEPTED, auditFor(lead.Id).Volunteer_Internal_Email_Status__c);
        System.assertEquals(4, sender.messages.size(), 'Only the failed internal message is retried.');
    }

    @IsTest
    static void thrownSendFailureRetainsLeadAndCanRecover() {
        Lead lead = pendingLead('unavailable');
        StubSender sender = new StubSender();
        sender.throwFailure = true;
        VolunteerInboundLeadService.emailSender = sender;
        Test.startTest();
        VolunteerInboundLeadService.notifyOwner(new List<VolunteerInboundLeadService.Request>{requestFor(lead.Id)});
        Lead failed = auditFor(lead.Id);
        System.assertEquals('Failed', failed.Volunteer_Applicant_Email_Status__c);
        System.assertEquals('Failed', failed.Volunteer_Internal_Email_Status__c);
        System.assert(failed.Volunteer_Email_Error__c.contains('unavailable'));
        sender.throwFailure = false;
        VolunteerInboundLeadService.notifyOwner(new List<VolunteerInboundLeadService.Request>{requestFor(lead.Id)});
        Test.stopTest();
        System.assertEquals(ACCEPTED, auditFor(lead.Id).Volunteer_Applicant_Email_Status__c);
        System.assertEquals(1, [SELECT COUNT() FROM Lead WHERE Id = :lead.Id ALL ROWS]);
    }

    @IsTest
    static void exhaustedInvocationBudgetRecordsFailureInsteadOfRollingBackIntake() {
        Lead lead = pendingLead('capacity');
        Messaging.SingleEmailMessage filler = new Messaging.SingleEmailMessage();
        filler.setToAddresses(new List<String>{'capacity@example.invalid'});
        filler.setSubject('Availability');
        filler.setPlainTextBody('Availability');
        Test.startTest();
        for (Integer index = 0; index < Limits.getLimitEmailInvocations(); index++) Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{filler});
        VolunteerInboundLeadService.notifyOwner(new List<VolunteerInboundLeadService.Request>{requestFor(lead.Id)});
        System.assertEquals(Limits.getLimitEmailInvocations(), Limits.getEmailInvocations());
        Test.stopTest();
        Lead failed = auditFor(lead.Id);
        System.assertEquals('Failed', failed.Volunteer_Applicant_Email_Status__c);
        System.assertEquals('Failed', failed.Volunteer_Internal_Email_Status__c);
        System.assert(failed.Volunteer_Email_Error__c.contains('no email requests remaining'));
    }

    @IsTest
    static void failedAuditSaveCancelsAttemptAndRetainsRecoverableFailure() {
        Lead lead = pendingLead('audit-save');
        VolunteerInboundLeadService.failNextAuditSave = true;
        Test.startTest();
        VolunteerInboundLeadService.notifyOwner(new List<VolunteerInboundLeadService.Request>{requestFor(lead.Id)});
        Lead failed = auditFor(lead.Id);
        System.assertEquals('Failed', failed.Volunteer_Applicant_Email_Status__c);
        System.assertEquals('Failed', failed.Volunteer_Internal_Email_Status__c);
        System.assert(failed.Volunteer_Email_Error__c.contains('result could not be saved'));
        VolunteerInboundLeadService.notifyOwner(new List<VolunteerInboundLeadService.Request>{requestFor(lead.Id)});
        Test.stopTest();
        System.assertEquals(ACCEPTED, auditFor(lead.Id).Volunteer_Applicant_Email_Status__c);
        System.assertEquals(null, auditFor(lead.Id).Volunteer_Email_Error__c);
    }

    @IsTest
    static void emptyAndNullRequestsAndUnsupportedFormsAreNoOps() {
        Lead lead = new Lead(LastName = 'Morgan', Company = 'Brookfield Services', Email = 'morgan@example.invalid');
        insert lead;
        Test.startTest();
        VolunteerInboundLeadService.notifyOwner(null);
        VolunteerInboundLeadService.notifyOwner(new List<VolunteerInboundLeadService.Request>());
        VolunteerInboundLeadService.notifyOwner(new List<VolunteerInboundLeadService.Request>{null, requestFor(null), requestFor(lead.Id)});
        System.assertEquals(0, Limits.getDmlRows());
        System.assertEquals(0, Limits.getEmailInvocations());
        Test.stopTest();
    }

    @IsTest
    static void emailValidationRejectsMissingOrMalformedAddresses() {
        for (String invalid : new List<String>{null, '', '   ', 'missing-at.example.com', 'two@@example.com', 'alex@example', 'alex\n@example.com'}) {
            System.assertEquals(false, VolunteerInboundLeadService.isUsableEmail(invalid), 'Invalid address: ' + String.valueOf(invalid));
        }
        System.assertEquals(true, VolunteerInboundLeadService.isUsableEmail('alex.bennett+nte@example.invalid'));
    }
    @IsTest
    static void bypassRecordsNotAttemptedAndRetainsLead() {
        VolunteerInboundLeadService.bypassEmailDelivery = true;
        Lead lead = volunteerLead('bypass');
        Test.startTest();
        insert lead;
        VolunteerInboundLeadService.notifyOwner(new List<VolunteerInboundLeadService.Request>{requestFor(lead.Id)});
        Test.stopTest();
        Lead result = auditFor(lead.Id);
        System.assertEquals('Not Attempted', result.Volunteer_Applicant_Email_Status__c);
        System.assertEquals('Not Attempted', result.Volunteer_Internal_Email_Status__c);
        System.assertEquals(null, result.Volunteer_Email_Error__c);
        System.assertEquals(1, [SELECT COUNT() FROM Lead WHERE Id = :lead.Id ALL ROWS]);
    }

    @IsTest
    static void usesLeadRecipientAndCurrentActiveOwnerOnly() {
        StubSender sender = new StubSender();
        VolunteerInboundLeadService.emailSender = sender;
        Lead lead = volunteerLead('recipients');
        Test.startTest();
        insert lead;
        Test.stopTest();
        System.assertEquals(2, sender.messages.size());
        String ownerEmail = [SELECT Email FROM User WHERE Id = :UserInfo.getUserId()].Email;
        Map<Id, EmailTemplate> templates = new Map<Id, EmailTemplate>([SELECT Id, DeveloperName FROM EmailTemplate]);
        for (Messaging.SingleEmailMessage message : sender.messages) {
            System.assertEquals(lead.Id, message.getTargetObjectId());
            Boolean internalMessage = message.getToAddresses() != null && !message.getToAddresses().isEmpty();
            System.assertEquals(internalMessage ? 'Volunteer_Application_Internal' : 'Volunteer_Application_Acknowledgement',
                templates.get(message.getTemplateId()).DeveloperName);
            if (internalMessage) System.assertEquals(new List<String>{ownerEmail}, message.getToAddresses());
        }
    }

    @IsTest
    static void missingOwnerEmailRetainsLeadAndRetriesOnlyInternalNotification() {
        Group queueRecord = new Group(Name = 'Volunteer Intake Queue', Type = 'Queue');
        insert queueRecord;
        insert new QueueSobject(QueueId = queueRecord.Id, SobjectType = 'Lead');
        StubSender sender = new StubSender();
        VolunteerInboundLeadService.emailSender = sender;
        Lead lead = volunteerLead('queue');
        lead.OwnerId = queueRecord.Id;
        Test.startTest();
        insert lead;
        Lead failed = auditFor(lead.Id);
        System.assertEquals(ACCEPTED, failed.Volunteer_Applicant_Email_Status__c);
        System.assertEquals('Failed', failed.Volunteer_Internal_Email_Status__c);
        System.assert(failed.Volunteer_Email_Error__c.contains('owner has no available email'));
        System.assertEquals(1, sender.messages.size());
        Database.update(new Lead(Id = lead.Id, OwnerId = UserInfo.getUserId()), AccessLevel.SYSTEM_MODE);
        VolunteerInboundLeadService.notifyOwner(new List<VolunteerInboundLeadService.Request>{requestFor(lead.Id)});
        Test.stopTest();
        System.assertEquals(ACCEPTED, auditFor(lead.Id).Volunteer_Internal_Email_Status__c);
        System.assertEquals(2, sender.messages.size());
        System.assertEquals(1, [SELECT COUNT() FROM Lead WHERE Id = :lead.Id ALL ROWS]);
    }

    @IsTest
    static void ignoresNonVolunteerAndMismatchedSourceRecords() {
        Lead ordinary = new Lead(LastName = 'Dawson', Company = 'Oakfield Studio', Email = 'dawson@example.invalid');
        Lead mismatched = volunteerLead('mismatched');
        mismatched.LeadSource = 'Other';
        insert new List<Lead>{ordinary, mismatched};
        Test.startTest();
        VolunteerInboundLeadService.notifyOwner(new List<VolunteerInboundLeadService.Request>{requestFor(ordinary.Id), requestFor(mismatched.Id)});
        System.assertEquals(0, Limits.getEmailInvocations());
        Test.stopTest();
        for (Lead result : new List<Lead>{auditFor(ordinary.Id), auditFor(mismatched.Id)}) {
            System.assertEquals(null, result.Volunteer_Applicant_Email_Status__c);
            System.assertEquals(null, result.Volunteer_Internal_Email_Status__c);
            System.assertEquals(null, result.Volunteer_Email_Error__c);
        }
    }

    @IsTest
    static void forgedCreationAcceptanceCannotSuppressAcknowledgements() {
        VolunteerInboundLeadService.bypassEmailDelivery = true;
        Lead lead = volunteerLead('forged');
        lead.Volunteer_Applicant_Email_Status__c = ACCEPTED;
        lead.Volunteer_Internal_Email_Status__c = ACCEPTED;
        lead.Volunteer_Email_Error__c = 'Supplied status';
        Test.startTest();
        insert lead;
        Lead fresh = auditFor(lead.Id);
        System.assertEquals('Not Attempted', fresh.Volunteer_Applicant_Email_Status__c);
        System.assertEquals('Not Attempted', fresh.Volunteer_Internal_Email_Status__c);
        System.assertEquals(null, fresh.Volunteer_Email_Error__c);
        VolunteerInboundLeadService.bypassEmailDelivery = false;
        StubSender sender = new StubSender();
        VolunteerInboundLeadService.emailSender = sender;
        VolunteerInboundLeadService.notifyOwner(new List<VolunteerInboundLeadService.Request>{requestFor(lead.Id)});
        Test.stopTest();
        System.assertEquals(2, sender.messages.size());
        System.assertEquals(ACCEPTED, auditFor(lead.Id).Volunteer_Applicant_Email_Status__c);
    }

    @IsTest
    static void mixedNteAndVolunteerBatchSharesPlatformBudgetWithoutDroppingMessages() {
        NTEInboundLeadService.ownerUsernameOverride = '';
        List<Lead> leads = new List<Lead>();
        for (Integer index = 0; index < 60; index++) {
            leads.add(volunteerLead('batch-' + index));
            leads.add(new Lead(FirstName = 'Morgan', LastName = 'Reed', Company = 'Fernhill Works',
                Email = 'guest-' + index + '@example.invalid', Web_Form_Type__c = 'Guest Registration', NTE_Event_Code__c = 'NTE2027'));
        }
        Test.startTest();
        Database.insert(leads, AccessLevel.SYSTEM_MODE);
        System.assertEquals(2, Limits.getEmailInvocations(), '240 messages across both intake services need only two calls.');
        Test.stopTest();
        Set<Id> leadIds = new Map<Id, Lead>(leads).keySet();
        System.assertEquals(60, [SELECT COUNT() FROM Lead WHERE Id IN :leadIds
            AND Volunteer_Applicant_Email_Status__c = :ACCEPTED AND Volunteer_Internal_Email_Status__c = :ACCEPTED]);
        System.assertEquals(60, [SELECT COUNT() FROM Lead WHERE Id IN :leadIds
            AND NTE_Applicant_Email_Status__c = :ACCEPTED AND NTE_Internal_Email_Status__c = :ACCEPTED]);
    }

    @IsTest
    static void fullTriggerBatchRetainsEveryIndividualResult() {
        StubSender sender = new StubSender();
        VolunteerInboundLeadService.emailSender = sender;
        List<Lead> leads = new List<Lead>();
        for (Integer index = 0; index < 200; index++) leads.add(volunteerLead('full-' + index));
        Test.startTest();
        Database.insert(leads, AccessLevel.SYSTEM_MODE);
        Test.stopTest();
        System.assertEquals(1, sender.calls);
        System.assertEquals(400, sender.messages.size());
        Set<Id> leadIds = new Map<Id, Lead>(leads).keySet();
        System.assertEquals(200, [SELECT COUNT() FROM Lead WHERE Id IN :leadIds
            AND Volunteer_Applicant_Email_Status__c = :ACCEPTED AND Volunteer_Internal_Email_Status__c = :ACCEPTED]);
    }
}
