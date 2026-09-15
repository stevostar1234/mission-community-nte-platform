@IsTest
private class NTEInboundLeadServiceTest {
    private static final String ACCEPTED = 'Accepted by Salesforce';

    @TestSetup
    static void assignFieldAccess() {
        PermissionSet permissionSetRecord = [SELECT Id FROM PermissionSet WHERE Name = 'NTE_Forms_Administration' LIMIT 1];
        if ([SELECT COUNT() FROM PermissionSetAssignment WHERE AssigneeId = :UserInfo.getUserId() AND PermissionSetId = :permissionSetRecord.Id] == 0) {
            insert new PermissionSetAssignment(AssigneeId = UserInfo.getUserId(), PermissionSetId = permissionSetRecord.Id);
        }
    }

    private class SenderFailureException extends Exception {}

    private class StubSender implements NTEInboundLeadService.EmailSender {
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

    private static Lead intakeLead(String suffix, String formType) {
        return new Lead(FirstName = 'Alex', LastName = 'Bennett', Company = 'Willow Engineering',
            Email = 'intake-' + suffix + '@example.invalid', Web_Form_Type__c = formType, NTE_Event_Code__c = 'NTE2027');
    }

    private static Lead pendingLead(String suffix, String formType) {
        NTEInboundLeadService.bypassEmailDelivery = true;
        NTEInboundLeadService.ownerUsernameOverride = '';
        Lead lead = intakeLead(suffix, formType);
        Database.insert(lead, AccessLevel.SYSTEM_MODE);
        NTEInboundLeadService.bypassEmailDelivery = false;
        return lead;
    }

    private static NTEInboundLeadService.Request requestFor(Id leadId) {
        NTEInboundLeadService.Request request = new NTEInboundLeadService.Request();
        request.leadId = leadId;
        return request;
    }

    private static List<NTEInboundLeadService.Request> requestsFor(List<Lead> leads) {
        List<NTEInboundLeadService.Request> requests = new List<NTEInboundLeadService.Request>();
        for (Lead lead : leads) requests.add(requestFor(lead.Id));
        return requests;
    }

    private static Lead auditFor(Id leadId) {
        return [SELECT OwnerId, Web_Form_Type__c, NTE_Applicant_Email_Status__c, NTE_Internal_Email_Status__c,
            NTE_Email_Error__c FROM Lead WHERE Id = :leadId];
    }

    @IsTest
    static void routesSupportedLeadAndBuildsNotifications() {
        Lead lead = pendingLead('routing', 'Partner / Sponsor Expression of Interest');
        NTEInboundLeadService.ownerUsernameOverride = null;
        NTEInboundLeadService.bypassEmailDelivery = true;
        Test.startTest();
        NTEInboundLeadService.routeAndAcknowledge(new List<NTEInboundLeadService.Request>{requestFor(lead.Id)});
        Test.stopTest();

        Lead routed = auditFor(lead.Id);
        NTE_Routing_Config__mdt routingConfig = NTE_Routing_Config__mdt.getInstance('Default');
        List<User> intendedOwners = routingConfig == null || String.isBlank(routingConfig.Owner_Username__c)
            ? new List<User>() : [SELECT Id FROM User WHERE Username = :routingConfig.Owner_Username__c AND IsActive = true LIMIT 1];
        System.assertEquals(intendedOwners.isEmpty() ? UserInfo.getUserId() : intendedOwners[0].Id, routed.OwnerId);
        System.assertEquals('Not Attempted', routed.NTE_Applicant_Email_Status__c);
        System.assertEquals('Not Attempted', routed.NTE_Internal_Email_Status__c);
        System.assertEquals(null, routed.NTE_Email_Error__c);
    }

    @IsTest
    static void recordsBlankApplicantEmailThenRetriesOnlyThatMessage() {
        Lead lead = pendingLead('blank', 'Guest Registration');
        Database.update(new Lead(Id = lead.Id, Email = null), AccessLevel.SYSTEM_MODE);
        StubSender sender = new StubSender();
        NTEInboundLeadService.emailSender = sender;
        Test.startTest();
        NTEInboundLeadService.routeAndAcknowledge(new List<NTEInboundLeadService.Request>{requestFor(lead.Id)});
        Lead failed = auditFor(lead.Id);
        System.assertEquals('Failed', failed.NTE_Applicant_Email_Status__c);
        System.assertEquals(ACCEPTED, failed.NTE_Internal_Email_Status__c);
        System.assert(failed.NTE_Email_Error__c.contains('email address is blank'));
        System.assertEquals(1, sender.messages.size());

        Database.update(new Lead(Id = lead.Id, Email = 'alex.bennett@example.invalid'), AccessLevel.SYSTEM_MODE);
        NTEInboundLeadService.routeAndAcknowledge(new List<NTEInboundLeadService.Request>{requestFor(lead.Id)});
        Test.stopTest();
        Lead recovered = auditFor(lead.Id);
        System.assertEquals(ACCEPTED, recovered.NTE_Applicant_Email_Status__c);
        System.assertEquals(ACCEPTED, recovered.NTE_Internal_Email_Status__c);
        System.assertEquals(null, recovered.NTE_Email_Error__c);
        System.assertEquals(2, sender.messages.size(), 'The accepted owner notification must not be repeated.');
    }

    @IsTest
    static void invalidConfiguredOwnerDoesNotFallBackToAnotherRecipient() {
        Lead lead = pendingLead('missing-owner', 'Guest Registration');
        NTEInboundLeadService.ownerUsernameOverride = 'unavailable-routing-owner@example.invalid';
        StubSender sender = new StubSender();
        NTEInboundLeadService.emailSender = sender;
        Test.startTest();
        NTEInboundLeadService.routeAndAcknowledge(new List<NTEInboundLeadService.Request>{requestFor(lead.Id)});
        Lead failed = auditFor(lead.Id);
        System.assertEquals(UserInfo.getUserId(), failed.OwnerId);
        System.assertEquals(ACCEPTED, failed.NTE_Applicant_Email_Status__c);
        System.assertEquals('Failed', failed.NTE_Internal_Email_Status__c);
        System.assert(failed.NTE_Email_Error__c.contains('configured NTE owner is unavailable'));
        System.assertEquals(1, sender.messages.size());
        NTEInboundLeadService.ownerUsernameOverride = '';
        NTEInboundLeadService.routeAndAcknowledge(new List<NTEInboundLeadService.Request>{requestFor(lead.Id)});
        Test.stopTest();
        System.assertEquals(ACCEPTED, auditFor(lead.Id).NTE_Internal_Email_Status__c);
        System.assertEquals(2, sender.messages.size(), 'Repairing the owner retries only its failed message.');
    }

    @IsTest
    static void recordsSalesforceAcceptanceWithoutDuplicateInvocation() {
        Lead lead = pendingLead('accepted', 'Exhibitor Application');
        NTEInboundLeadService.Request request = requestFor(lead.Id);
        request.isNewSubmission = true;
        Test.startTest();
        NTEInboundLeadService.routeAndAcknowledge(new List<NTEInboundLeadService.Request>{request, request, null});
        System.assertEquals(1, Limits.getEmailInvocations());
        NTEInboundLeadService.routeAndAcknowledge(new List<NTEInboundLeadService.Request>{request});
        System.assertEquals(1, Limits.getEmailInvocations(), 'Repeated create or retry calls must not resend accepted messages.');
        Test.stopTest();
        Lead audited = auditFor(lead.Id);
        System.assertEquals('Not required', audited.NTE_Applicant_Email_Status__c);
        System.assertEquals(ACCEPTED, audited.NTE_Internal_Email_Status__c);
        System.assertEquals(null, audited.NTE_Email_Error__c);
    }

    @IsTest
    static void allFiveRoutesUseTheirMatchingApplicantAndOwnerTemplates() {
        NTEInboundLeadService.ownerUsernameOverride = '';
        StubSender sender = new StubSender();
        NTEInboundLeadService.emailSender = sender;
        List<String> forms = new List<String>{'Exhibitor Expression of Interest', 'Partner / Sponsor Expression of Interest',
            'Exhibitor Application', 'Partner / Sponsor Application', 'Guest Registration'};
        List<String> prefixes = new List<String>{'NTE_Exhibitor_EOI', 'NTE_Partner_Sponsor_EOI',
            'NTE_Exhibitor_Application', 'NTE_Partner_Sponsor_Application', 'NTE_Guest_Registration'};
        List<Lead> leads = new List<Lead>();
        for (Integer index = 0; index < forms.size(); index++) leads.add(intakeLead('route-' + index, forms[index]));
        Test.startTest();
        Database.insert(leads, AccessLevel.SYSTEM_MODE);
        Test.stopTest();
        Map<Id, String> prefixByLead = new Map<Id, String>();
        for (Integer index = 0; index < leads.size(); index++) prefixByLead.put(leads[index].Id, prefixes[index]);
        Map<Id, EmailTemplate> templates = new Map<Id, EmailTemplate>([SELECT Id, DeveloperName FROM EmailTemplate]);
        String ownerEmail = [SELECT Email FROM User WHERE Id = :UserInfo.getUserId()].Email;
        System.assertEquals(8, sender.messages.size());
        System.assertEquals(1, sender.calls);
        for (Messaging.SingleEmailMessage message : sender.messages) {
            Boolean internalMessage = message.getToAddresses() != null && !message.getToAddresses().isEmpty();
            System.assertEquals(prefixByLead.get(message.getTargetObjectId()) + (internalMessage ? '_Internal' : '_Acknowledgement'),
                templates.get(message.getTemplateId()).DeveloperName);
            if (internalMessage) System.assertEquals(new List<String>{ownerEmail}, message.getToAddresses());
        }
    }

    @IsTest
    static void largeMixedIntakeUsesOnePlatformEmailInvocation() {
        NTEInboundLeadService.ownerUsernameOverride = '';
        List<String> forms = new List<String>{'Exhibitor Expression of Interest', 'Partner / Sponsor Expression of Interest',
            'Exhibitor Application', 'Partner / Sponsor Application', 'Guest Registration'};
        List<Lead> leads = new List<Lead>();
        for (Integer index = 0; index < 60; index++) leads.add(intakeLead('batch-' + index, forms[Math.mod(index, forms.size())]));
        Test.startTest();
        Database.insert(leads, AccessLevel.SYSTEM_MODE);
        System.assertEquals(1, Limits.getEmailInvocations(), '96 required messages must use one platform invocation.');
        Test.stopTest();
        Set<Id> leadIds = new Map<Id, Lead>(leads).keySet();
        System.assertEquals(60, [SELECT COUNT() FROM Lead WHERE Id IN :leadIds
            AND NTE_Applicant_Email_Status__c IN ('Accepted by Salesforce', 'Not required') AND NTE_Internal_Email_Status__c = :ACCEPTED]);
    }

    @IsTest
    static void partialRejectionAndMissingResultsRemainRetryable() {
        Lead lead = pendingLead('partial', 'Exhibitor Expression of Interest');
        StubSender sender = new StubSender();
        sender.rejectInternal = true;
        NTEInboundLeadService.emailSender = sender;
        Test.startTest();
        NTEInboundLeadService.routeAndAcknowledge(new List<NTEInboundLeadService.Request>{requestFor(lead.Id)});
        Lead failed = auditFor(lead.Id);
        System.assertEquals(ACCEPTED, failed.NTE_Applicant_Email_Status__c);
        System.assertEquals('Failed', failed.NTE_Internal_Email_Status__c);
        sender.rejectInternal = false;
        sender.omitLastResult = true;
        NTEInboundLeadService.routeAndAcknowledge(new List<NTEInboundLeadService.Request>{requestFor(lead.Id)});
        System.assertEquals('Failed', auditFor(lead.Id).NTE_Internal_Email_Status__c);
        sender.omitLastResult = false;
        NTEInboundLeadService.routeAndAcknowledge(new List<NTEInboundLeadService.Request>{requestFor(lead.Id)});
        Test.stopTest();
        System.assertEquals(ACCEPTED, auditFor(lead.Id).NTE_Internal_Email_Status__c);
        System.assertEquals(4, sender.messages.size(), 'Only the failed internal message is retried.');
    }

    @IsTest
    static void retiredApplicationReceiptsStaySuppressedDuringInternalRetry() {
        Lead exhibitor = pendingLead('retired-exhibitor', 'Exhibitor Application');
        Lead partner = pendingLead('retired-partner', 'Partner / Sponsor Application');
        update new List<Lead>{
            new Lead(Id = exhibitor.Id, NTE_Applicant_Email_Status__c = 'Failed', NTE_Internal_Email_Status__c = 'Failed'),
            new Lead(Id = partner.Id, NTE_Applicant_Email_Status__c = ACCEPTED, NTE_Internal_Email_Status__c = 'Failed')
        };
        StubSender sender = new StubSender();
        sender.rejectInternal = true;
        NTEInboundLeadService.emailSender = sender;
        List<NTEInboundLeadService.Request> requests = requestsFor(new List<Lead>{exhibitor, partner});
        Test.startTest();
        NTEInboundLeadService.routeAndAcknowledge(requests);
        System.assertEquals('Not required', auditFor(exhibitor.Id).NTE_Applicant_Email_Status__c);
        System.assertEquals(ACCEPTED, auditFor(partner.Id).NTE_Applicant_Email_Status__c, 'Retain the historical accepted receipt.');
        System.assertEquals('Failed', auditFor(exhibitor.Id).NTE_Internal_Email_Status__c);
        sender.rejectInternal = false;
        NTEInboundLeadService.routeAndAcknowledge(requests);
        NTEInboundLeadService.routeAndAcknowledge(requests);
        Test.stopTest();
        System.assertEquals(4, sender.messages.size(), 'Only two internal notices and their failed retries are dispatched.');
        for (Messaging.SingleEmailMessage message : sender.messages) {
            System.assert(message.getToAddresses() != null && !message.getToAddresses().isEmpty(), 'No applicant receipt may be revived.');
        }
        System.assertEquals(ACCEPTED, auditFor(exhibitor.Id).NTE_Internal_Email_Status__c);
        System.assertEquals(ACCEPTED, auditFor(partner.Id).NTE_Internal_Email_Status__c);
        System.assertEquals('Not required', auditFor(exhibitor.Id).NTE_Applicant_Email_Status__c);
    }

    @IsTest
    static void thrownSendFailureRetainsLeadAndCanRecover() {
        Lead lead = pendingLead('unavailable', 'Guest Registration');
        StubSender sender = new StubSender();
        sender.throwFailure = true;
        NTEInboundLeadService.emailSender = sender;
        Test.startTest();
        NTEInboundLeadService.routeAndAcknowledge(new List<NTEInboundLeadService.Request>{requestFor(lead.Id)});
        Lead failed = auditFor(lead.Id);
        System.assertEquals('Failed', failed.NTE_Applicant_Email_Status__c);
        System.assertEquals('Failed', failed.NTE_Internal_Email_Status__c);
        System.assert(failed.NTE_Email_Error__c.contains('unavailable'));
        sender.throwFailure = false;
        NTEInboundLeadService.routeAndAcknowledge(new List<NTEInboundLeadService.Request>{requestFor(lead.Id)});
        Test.stopTest();
        System.assertEquals(ACCEPTED, auditFor(lead.Id).NTE_Applicant_Email_Status__c);
        System.assertEquals(1, [SELECT COUNT() FROM Lead WHERE Id = :lead.Id ALL ROWS]);
    }

    @IsTest
    static void exhaustedInvocationBudgetRecordsFailureInsteadOfRollingBackIntake() {
        Lead lead = pendingLead('capacity', 'Guest Registration');
        Messaging.SingleEmailMessage filler = new Messaging.SingleEmailMessage();
        filler.setToAddresses(new List<String>{'capacity@example.invalid'});
        filler.setSubject('Availability');
        filler.setPlainTextBody('Availability');
        Test.startTest();
        for (Integer index = 0; index < Limits.getLimitEmailInvocations(); index++) Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{filler});
        NTEInboundLeadService.routeAndAcknowledge(new List<NTEInboundLeadService.Request>{requestFor(lead.Id)});
        System.assertEquals(Limits.getLimitEmailInvocations(), Limits.getEmailInvocations());
        Test.stopTest();
        Lead failed = auditFor(lead.Id);
        System.assertEquals('Failed', failed.NTE_Applicant_Email_Status__c);
        System.assertEquals('Failed', failed.NTE_Internal_Email_Status__c);
        System.assert(failed.NTE_Email_Error__c.contains('no email requests remaining'));
    }

    @IsTest
    static void failedAuditSaveCancelsAttemptAndRetainsRecoverableFailure() {
        Lead lead = pendingLead('audit-save', 'Guest Registration');
        NTEInboundLeadService.failNextAuditSave = true;
        Test.startTest();
        NTEInboundLeadService.routeAndAcknowledge(new List<NTEInboundLeadService.Request>{requestFor(lead.Id)});
        Lead failed = auditFor(lead.Id);
        System.assertEquals('Failed', failed.NTE_Applicant_Email_Status__c);
        System.assertEquals('Failed', failed.NTE_Internal_Email_Status__c);
        System.assert(failed.NTE_Email_Error__c.contains('result could not be saved'));
        NTEInboundLeadService.routeAndAcknowledge(new List<NTEInboundLeadService.Request>{requestFor(lead.Id)});
        Test.stopTest();
        System.assertEquals(ACCEPTED, auditFor(lead.Id).NTE_Applicant_Email_Status__c);
        System.assertEquals(null, auditFor(lead.Id).NTE_Email_Error__c);
    }

    @IsTest
    static void forgedCreationDecisionsCannotHideFreshInterestOrApplication() {
        NTEInboundLeadService.bypassEmailDelivery = true;
        NTEInboundLeadService.ownerUsernameOverride = '';
        Lead progressed = intakeLead('forged-progress', 'Exhibitor Expression of Interest');
        progressed.NTE_Interest_Progressed__c = true;
        progressed.NTE_Invitation_Status__c = 'Sent';
        progressed.NTE_Invitation_Sent_At__c = System.now();
        progressed.NTE_Invitation_Recipient__c = 'someone.else@example.invalid';
        progressed.NTE_Applicant_Email_Status__c = ACCEPTED;
        progressed.NTE_Internal_Email_Status__c = ACCEPTED;
        Lead rejected = intakeLead('forged-reject', 'Partner / Sponsor Expression of Interest');
        rejected.NTE_Interest_Not_Progressed__c = true;
        Lead application = intakeLead('forged-application', 'Exhibitor Application');
        application.NTE_Application_Rejected__c = true;
        Test.startTest();
        Database.insert(new List<Lead>{progressed, rejected, application}, AccessLevel.SYSTEM_MODE);
        List<Id> activeInterests = NTE_MasterPanelController.getCommunicationRecordIds('NTE2027', 'ALL', null, 'INTEREST');
        Test.stopTest();
        System.assert(activeInterests.contains(progressed.Id), 'A supplied Progressed flag must not remove a new interest from the panel.');
        System.assert(activeInterests.contains(rejected.Id), 'A supplied rejection must not remove a new interest from the panel.');
        Lead fresh = [SELECT NTE_Invitation_Status__c, NTE_Invitation_Sent_At__c, NTE_Invitation_Recipient__c,
            NTE_Applicant_Email_Status__c, NTE_Internal_Email_Status__c FROM Lead WHERE Id = :progressed.Id];
        System.assertEquals(null, fresh.NTE_Invitation_Status__c);
        System.assertEquals(null, fresh.NTE_Invitation_Sent_At__c);
        System.assertEquals(null, fresh.NTE_Invitation_Recipient__c);
        System.assertEquals('Not Attempted', fresh.NTE_Applicant_Email_Status__c);
        System.assertEquals('Not Attempted', fresh.NTE_Internal_Email_Status__c);
        System.assertEquals(false, [SELECT NTE_Application_Rejected__c FROM Lead WHERE Id = :application.Id].NTE_Application_Rejected__c);
    }

    @IsTest
    static void retryPreservesLaterStaffDecisionAndInvitationHistory() {
        Lead lead = pendingLead('later-decision', 'Exhibitor Expression of Interest');
        Datetime sentAt = System.now().addMinutes(-5);
        Database.update(new Lead(Id = lead.Id, NTE_Interest_Progressed__c = true, NTE_Invitation_Status__c = 'Sent',
            NTE_Invitation_Sent_At__c = sentAt, NTE_Invitation_Recipient__c = lead.Email), AccessLevel.SYSTEM_MODE);
        StubSender sender = new StubSender();
        NTEInboundLeadService.emailSender = sender;
        Test.startTest();
        NTEInboundLeadService.routeAndAcknowledge(new List<NTEInboundLeadService.Request>{requestFor(lead.Id)});
        Test.stopTest();
        Lead retained = [SELECT NTE_Interest_Progressed__c, NTE_Invitation_Status__c, NTE_Invitation_Sent_At__c,
            NTE_Invitation_Recipient__c FROM Lead WHERE Id = :lead.Id];
        System.assertEquals(true, retained.NTE_Interest_Progressed__c);
        System.assertEquals('Sent', retained.NTE_Invitation_Status__c);
        System.assertEquals(sentAt, retained.NTE_Invitation_Sent_At__c);
        System.assertEquals(lead.Email, retained.NTE_Invitation_Recipient__c);
    }

    @IsTest
    static void emptyAndNullRequestsAndUnsupportedFormsAreNoOps() {
        Lead lead = new Lead(LastName = 'Morgan', Company = 'Brookfield Services', Email = 'morgan@example.invalid');
        insert lead;
        Test.startTest();
        NTEInboundLeadService.routeAndAcknowledge(null);
        NTEInboundLeadService.routeAndAcknowledge(new List<NTEInboundLeadService.Request>());
        NTEInboundLeadService.routeAndAcknowledge(new List<NTEInboundLeadService.Request>{null, requestFor(null), requestFor(lead.Id)});
        System.assertEquals(0, Limits.getDmlRows());
        System.assertEquals(0, Limits.getEmailInvocations());
        Test.stopTest();
    }

    @IsTest
    static void emailValidationRejectsMissingOrMalformedAddresses() {
        for (String invalid : new List<String>{null, '', '   ', 'missing-at.example.com', 'two@@example.com', 'alex@example', 'alex\n@example.com'}) {
            System.assertEquals(false, NTEInboundLeadService.isUsableEmail(invalid), 'Invalid address: ' + String.valueOf(invalid));
        }
        System.assertEquals(true, NTEInboundLeadService.isUsableEmail('alex.bennett+nte@example.invalid'));
    }
}
