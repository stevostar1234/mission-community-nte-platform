@IsTest
private class NTEEmailDispatchServiceTest {
    private static final String EVENT_CODE = 'NTE2027';

    @TestSetup
    static void createData() {
        NTEInboundLeadService.bypassEmailDelivery = true;
        for (String permissionName : new List<String>{'NTE_Forms_Administration', 'NTE_Management_User'}) {
            PermissionSet permissionRecord = [SELECT Id FROM PermissionSet WHERE Name = :permissionName LIMIT 1];
            if ([SELECT COUNT() FROM PermissionSetAssignment WHERE AssigneeId = :UserInfo.getUserId()
                AND PermissionSetId = :permissionRecord.Id] == 0) {
                insert new PermissionSetAssignment(AssigneeId = UserInfo.getUserId(), PermissionSetId = permissionRecord.Id);
            }
        }
        User currentUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        System.runAs(currentUser) {
            Account organisation = new Account(Name = 'Dispatch <Organisation> & Partners');
            insert organisation;
            Id recordTypeId = [SELECT Id FROM RecordType WHERE SobjectType = 'Opportunity'
                AND DeveloperName = 'NTE_Event_Opportunity' LIMIT 1].Id;
            String stage = [SELECT MasterLabel FROM OpportunityStage WHERE IsActive = true AND IsClosed = false
                ORDER BY SortOrder LIMIT 1].MasterLabel;
            List<Opportunity> bookings = new List<Opportunity>();
            for (String name : new List<String>{'EXHIBITOR', 'PARTNER', 'COMPLETE', 'MISSING-CONTACT'}) {
                bookings.add(new Opportunity(
                    AccountId = organisation.Id, RecordTypeId = recordTypeId, Name = 'DISPATCH-' + name,
                    StageName = stage, CloseDate = Date.today().addDays(30), NTE_Event_Code__c = EVENT_CODE,
                    Booking_Reference__c = 'NTE-DISPATCH-' + name,
                    NTE_Source_Form_Type__c = name == 'PARTNER' ? 'Partner / Sponsor Application' : 'Exhibitor Application',
                    NTE_Event_Contact_Email__c = 'event-day-fallback@example.invalid',
                    NTE_Exhibitor_Space_Selections__c = name == 'PARTNER' ? null : 'COBSEO Charity - Single - Free',
                    NTE_Exhibitor_Organisation_Category__c = name == 'PARTNER' ? null : 'Charity - member of Cobseo',
                    NTE_Sponsor_Package__c = name == 'PARTNER' ? 'Champion Partner' : null,
                    NTE_Sponsor_Package_Total__c = name == 'PARTNER' ? 2000 : 0,
                    NTE_Exhibitor_Space_Price__c = 0, NTE_Stand_Power__c = 'No',
                    NTE_Total_Staff_Count__c = 2, NTE_Initial_Staff_Count__c = 2,
                    NTE_Invoice_Required__c = name == 'PARTNER' ? 'Yes' : 'No',
                    NTE_Listed_Price_Total__c = name == 'PARTNER' ? 2000 : 0, Amount = name == 'PARTNER' ? 2400 : 0,
                    NTE_Pricing_Status__c = 'Calculated', NTE_Quote_Required_for_PO__c = 'No',
                    NTE_Heavy_Vehicle_Required__c = name == 'COMPLETE' ? 'No' : 'Not known yet',
                    NTE_Staff_Update_Completed_At__c = name == 'COMPLETE' ? System.now() : null,
                    NTE_Logo_Update_Provided__c = name == 'COMPLETE'
                ));
            }
            insert bookings;
            List<Contact> contacts = new List<Contact>();
            for (Integer index = 0; index < 3; index++) contacts.add(new Contact(
                AccountId = organisation.Id, FirstName = 'Primary', LastName = '<Contact ' + index + '>',
                Email = 'dispatch-primary-' + index + '@example.invalid'));
            insert contacts;
            List<OpportunityContactRole> roles = new List<OpportunityContactRole>();
            for (Integer index = 0; index < 3; index++) roles.add(new OpportunityContactRole(
                OpportunityId = bookings[index].Id, ContactId = contacts[index].Id, IsPrimary = true, Role = 'Decision Maker'));
            insert roles;
            insert new List<Lead>{
                interest('EXHIBITOR', 'Exhibitor Expression of Interest', EVENT_CODE),
                interest('PARTNER', 'Partner / Sponsor Expression of Interest', EVENT_CODE),
                interest('REJECTED', 'Exhibitor Expression of Interest', EVENT_CODE),
                interest('FUTURE-EVENT', 'Exhibitor Expression of Interest', 'NTE2030')
            };
            Lead rejected = [SELECT Id FROM Lead WHERE LastName = 'DISPATCH-REJECTED' LIMIT 1];
            update new Lead(Id = rejected.Id, NTE_Interest_Not_Progressed__c = true);
        }
    }

    private static Lead interest(String name, String type, String eventCode) {
        return new Lead(FirstName = 'Interested', LastName = 'DISPATCH-' + name, Company = 'Interest ' + name,
            Email = 'dispatch-interest-' + name.toLowerCase() + '@example.invalid', Status = 'New',
            Web_Form_Type__c = type, NTE_Event_Code__c = eventCode);
    }
    private static void configure() {
        NTEEmailDispatchService.skipEnqueue = true;
        NTEEmailDispatchService.bypassEmailDelivery = true;
        NTEEmailDispatchService.routingOverride = new NTE_Routing_Config__mdt(
            Exhibitor_Application_URL__c = 'https://forms.example.invalid/exhibitor-application',
            Partner_Application_URL__c = 'https://forms.example.invalid/partner-application',
            Exhibitor_Staff_Form_URL__c = 'https://forms.example.invalid/exhibitor-staff',
            Partner_Staff_Form_URL__c = 'https://forms.example.invalid/partner-staff',
            Heavy_Vehicle_Form_URL__c = 'https://forms.example.invalid/logistics',
            Logo_Update_Form_URL__c = 'https://forms.example.invalid/logo'
        );
    }

    @IsTest
    static void invitationDraftRoutesEachInterestAndExplainsExclusions() {
        configure();
        Id exhibitor = leadId('EXHIBITOR'); Id partner = leadId('PARTNER');
        NTEEmailDispatchService.DraftDTO draft = NTEEmailDispatchService.buildDraft('INVITATION',
            new List<Id>{exhibitor, partner, leadId('REJECTED'), leadId('FUTURE-EVENT')});
        System.assertEquals(3, draft.recipientCount);
        System.assertEquals(1, draft.skippedCount);
        System.assertEquals(500, draft.recipientLimit);
        System.assertEquals(true, draft.canSend);
        System.assertEquals('https://forms.example.invalid/exhibitor-application', draft.recipients[0].link);
        System.assertEquals('https://forms.example.invalid/partner-application', draft.recipients[1].link);
        System.assertEquals('dispatch-interest-exhibitor@example.invalid', draft.recipients[0].email);
        System.assertEquals(false, draft.recipients[2].eligible);
        System.assert(draft.recipients[2].issue.contains('not progressed'));
        System.assertEquals(true, draft.recipients[3].eligible);
        System.assertEquals('NTE2030', draft.recipients[3].eventCode);
        System.assertEquals(draft.recipients[0].link, draft.recipients[3].link);
        System.assert(!draft.previewHtml.contains('{ContactName}'));
        System.assert(!draft.previewHtml.contains('{UpdateLink}'));
    }

    @IsTest
    static void futureEventInvitationsUseReusableParticipantLinks() {
        configure();
        Id exhibitor = leadId('FUTURE-EVENT'); Id partner = leadId('PARTNER');
        Set<Id> selectedIds = new Set<Id>{exhibitor, partner};
        update new Lead(Id = partner, NTE_Event_Code__c = 'NTE2030');
        NTEEmailDispatchService.DraftDTO draft = NTEEmailDispatchService.buildDraft('INVITATION', new List<Id>{exhibitor, partner});
        System.assertEquals(2, draft.recipientCount);
        System.assertEquals('https://forms.example.invalid/exhibitor-application', draft.recipients[0].link);
        System.assertEquals('https://forms.example.invalid/partner-application', draft.recipients[1].link);
        NTEEmailDispatchService.DraftRequest previewRequest = requestFor(draft, selectedIds);
        System.assert(NTEEmailDispatchService.previewMessage(previewRequest, exhibitor).contains('NTE27 &bull; Exhibitors'));
        System.assert(NTEEmailDispatchService.previewMessage(previewRequest, partner).contains('NTE27 &bull; Partners &amp; sponsors'));
        System.assert(!NTEEmailDispatchService.previewMessage(previewRequest, exhibitor).contains('NTE2030'));
        previewRequest.messageBody += '\nExplicit event: {EventCode}';
        System.assert(NTEEmailDispatchService.previewMessage(previewRequest, exhibitor).contains('Explicit event: NTE2030'));

        Test.startTest();
        System.assertEquals(2, NTEEmailDispatchService.queueMessages(requestFor(draft, selectedIds)).queuedCount);
        List<Id> dispatchIds = dispatchIdsFor(exhibitor);
        dispatchIds.addAll(dispatchIdsFor(partner));
        NTEEmailDispatchService.processQueued(dispatchIds, true);
        Test.stopTest();
        for (NTE_Email_Dispatch__c dispatch : [SELECT Lead__c, Event_Code__c, Link__c, Status__c
            FROM NTE_Email_Dispatch__c WHERE Id IN :dispatchIds]) {
            System.assertEquals('Sent', dispatch.Status__c);
            System.assertEquals('NTE2030', dispatch.Event_Code__c);
            System.assertEquals(dispatch.Lead__c == exhibitor
                ? 'https://forms.example.invalid/exhibitor-application'
                : 'https://forms.example.invalid/partner-application', dispatch.Link__c);
        }
        for (Lead interest : [SELECT NTE_Interest_Progressed__c, NTE_Invitation_Status__c
            FROM Lead WHERE Id IN :selectedIds]) {
            System.assertEquals(true, interest.NTE_Interest_Progressed__c);
            System.assertEquals('Sent', interest.NTE_Invitation_Status__c);
        }
    }

    @IsTest
    static void exactSelectionIsIdempotentAndProgressesOnlyAfterAcceptedSend() {
        configure();
        Id selected = leadId('EXHIBITOR'); Id unselected = leadId('PARTNER');
        NTEEmailDispatchService.DraftDTO draft = NTEEmailDispatchService.buildDraft('INVITATION', new List<Id>{selected, unselected});
        NTEEmailDispatchService.DraftRequest request = requestFor(draft, new Set<Id>{selected});
        Test.startTest();
        System.assertEquals(1, NTEEmailDispatchService.queueMessages(request).queuedCount);
        System.assertEquals(0, NTEEmailDispatchService.queueMessages(request).queuedCount);
        Lead queued = [SELECT NTE_Interest_Progressed__c, NTE_Invitation_Status__c FROM Lead WHERE Id = :selected];
        System.assertEquals(false, queued.NTE_Interest_Progressed__c);
        System.assertEquals('Queued', queued.NTE_Invitation_Status__c);
        List<Id> dispatchIds = dispatchIdsFor(selected);
        System.assertEquals(1, dispatchIds.size());
        NTEEmailDispatchService.processQueued(dispatchIds, true);
        NTEEmailDispatchService.processQueued(dispatchIds, true);
        Test.stopTest();
        Lead sent = [SELECT NTE_Interest_Progressed__c, NTE_Invitation_Status__c, NTE_Invitation_Sent_At__c,
            NTE_Invitation_Recipient__c FROM Lead WHERE Id = :selected];
        System.assertEquals(true, sent.NTE_Interest_Progressed__c);
        System.assertEquals('Sent', sent.NTE_Invitation_Status__c);
        System.assertNotEquals(null, sent.NTE_Invitation_Sent_At__c);
        System.assertEquals('dispatch-interest-exhibitor@example.invalid', sent.NTE_Invitation_Recipient__c);
        System.assertEquals(0, dispatchIdsFor(unselected).size());
        System.assertEquals(false, [SELECT NTE_Interest_Progressed__c FROM Lead WHERE Id = :unselected].NTE_Interest_Progressed__c);
        List<NTEEmailDispatchService.HistoryDTO> history = NTEEmailDispatchService.recentDispatches(new List<Id>{selected});
        System.assertEquals(1, history.size());
        System.assertEquals('Sent', history[0].status);
        System.assertEquals(false, history[0].canRetry);
    }

    @IsTest
    static void changedEmailBeforeQueueRequiresAnotherReviewedDraft() {
        configure();
        Id selected = leadId('EXHIBITOR');
        NTEEmailDispatchService.DraftDTO draft = NTEEmailDispatchService.buildDraft('INVITATION', new List<Id>{selected});
        update new Lead(Id = selected, Email = 'changed@example.invalid');
        NTEEmailDispatchService.QueueResponse result = NTEEmailDispatchService.queueMessages(requestFor(draft, new Set<Id>{selected}));
        System.assertEquals(0, result.queuedCount);
        System.assertEquals(1, result.skippedCount);
        System.assertEquals(0, dispatchIdsFor(selected).size());
    }

    @IsTest
    static void changedPrimaryContactAfterQueueDoesNotReceiveTheFrozenEmail() {
        configure();
        Id selected = bookingId('EXHIBITOR');
        NTEEmailDispatchService.DraftDTO draft = NTEEmailDispatchService.buildDraft('STAFF_DUE', new List<Id>{selected});
        System.assertEquals('dispatch-primary-0@example.invalid', draft.recipients[0].email);
        NTEEmailDispatchService.queueMessages(requestFor(draft, new Set<Id>{selected}));
        Contact primary = [SELECT Id FROM Contact WHERE Email = 'dispatch-primary-0@example.invalid' LIMIT 1];
        update new Contact(Id = primary.Id, Email = 'different-primary@example.invalid');
        NTEEmailDispatchService.processQueued(dispatchIdsFor(selected), true);
        NTE_Email_Dispatch__c dispatch = dispatchFor(selected);
        System.assertEquals('Skipped', dispatch.Status__c);
        System.assertEquals('dispatch-primary-0@example.invalid', dispatch.Recipient__c);
        System.assertEquals(null, dispatch.Sent_At__c);
        System.assert(!NTEEmailDispatchService.renderedHtml.containsKey(selected));
    }

    @IsTest
    static void failedOnlyRetryReusesDispatchAndPreservesSuccessfulHistory() {
        configure();
        Id success = leadId('EXHIBITOR'); Id failure = leadId('PARTNER');
        NTEEmailDispatchService.DraftDTO draft = NTEEmailDispatchService.buildDraft('INVITATION', new List<Id>{success, failure});
        NTEEmailDispatchService.queueMessages(requestFor(draft, new Set<Id>{success, failure}));
        List<Id> dispatchIds = dispatchIdsFor(success); dispatchIds.addAll(dispatchIdsFor(failure));
        NTEEmailDispatchService.simulatedFailures.add(failure);
        Test.startTest();
        NTEEmailDispatchService.processQueued(dispatchIds, true);
        Datetime firstSentAt = dispatchFor(success).Sent_At__c;
        Id originalFailedId = dispatchFor(failure).Id;
        System.assertEquals('Failed', dispatchFor(failure).Status__c);
        System.assertEquals(false, [SELECT NTE_Interest_Progressed__c FROM Lead WHERE Id = :failure].NTE_Interest_Progressed__c);
        NTEEmailDispatchService.QueueResponse retry = NTEEmailDispatchService.retryFailed(dispatchIds);
        System.assertEquals(1, retry.queuedCount);
        System.assertEquals(1, retry.skippedCount);
        NTEEmailDispatchService.simulatedFailures.clear();
        NTEEmailDispatchService.processQueued(dispatchIds, true);
        Test.stopTest();
        System.assertEquals(firstSentAt, dispatchFor(success).Sent_At__c);
        System.assertEquals(originalFailedId, dispatchFor(failure).Id);
        System.assertEquals('Sent', dispatchFor(failure).Status__c);
        System.assertEquals(2, [SELECT COUNT() FROM NTE_Email_Dispatch__c]);
    }

    @IsTest
    static void failedRetryDoesNotSilentlySwitchToANewRecipient() {
        configure();
        Id selected = leadId('EXHIBITOR');
        NTEEmailDispatchService.DraftDTO draft = NTEEmailDispatchService.buildDraft('INVITATION', new List<Id>{selected});
        NTEEmailDispatchService.queueMessages(requestFor(draft, new Set<Id>{selected}));
        List<Id> dispatchIds = dispatchIdsFor(selected);
        NTEEmailDispatchService.simulatedFailures.add(selected);
        NTEEmailDispatchService.processQueued(dispatchIds, true);
        update new Lead(Id = selected, Email = 'replacement-recipient@example.invalid');
        NTEEmailDispatchService.QueueResponse result = NTEEmailDispatchService.retryFailed(dispatchIds);
        System.assertEquals(0, result.queuedCount);
        System.assertEquals(1, result.skippedCount);
        System.assertEquals('Skipped', dispatchFor(selected).Status__c);
        System.assertEquals('dispatch-interest-exhibitor@example.invalid', dispatchFor(selected).Recipient__c);
        System.assertEquals(null, dispatchFor(selected).Sent_At__c);
        System.assertEquals(false, [SELECT NTE_Interest_Progressed__c FROM Lead WHERE Id = :selected].NTE_Interest_Progressed__c);
    }

    @IsTest
    static void queuedJobProcessesOnlyItsSavedSelectionWithDeliveryBypassed() {
        configure();
        NTEEmailDispatchService.skipEnqueue = false;
        NTEEmailDispatchService.routingOverride = null;
        Id selected = leadId('EXHIBITOR');
        NTEEmailDispatchService.DraftDTO draft = NTEEmailDispatchService.buildDraft('INVITATION', new List<Id>{selected});
        Test.startTest();
        System.assertEquals(1, NTEEmailDispatchService.queueMessages(requestFor(draft, new Set<Id>{selected})).queuedCount);
        System.assertEquals(1, Limits.getQueueableJobs());
        Test.stopTest();
        System.assertEquals('Sent', dispatchFor(selected).Status__c);
        System.assertEquals(1, [SELECT COUNT() FROM NTE_Email_Dispatch__c]);
    }

    @IsTest
    static void completedDetailsAndMissingPrimaryContactAreSkipped() {
        configure();
        Id selected = bookingId('EXHIBITOR');
        NTEEmailDispatchService.DraftDTO draft = NTEEmailDispatchService.buildDraft('STAFF_DUE',
            new List<Id>{selected, bookingId('COMPLETE'), bookingId('MISSING-CONTACT')});
        System.assertEquals(1, draft.recipientCount);
        System.assertEquals(2, draft.skippedCount);
        System.assert(draft.recipients[2].issue.contains('primary Contact'));
        NTEEmailDispatchService.queueMessages(requestFor(draft, new Set<Id>{selected}));
        update new Opportunity(Id = selected, NTE_Staff_Update_Completed_At__c = System.now());
        NTEEmailDispatchService.processQueued(dispatchIdsFor(selected), true);
        System.assertEquals('Skipped', dispatchFor(selected).Status__c);
        System.assertEquals(null, dispatchFor(selected).Sent_At__c);
    }

    @IsTest
    static void retiredFinalPackTypeCannotPrepareAnyBooking() {
        configure(); Id selected=bookingId('COMPLETE');
        Boolean rejected=false;
        try { NTEEmailDispatchService.buildDraft('FINAL_PACK',new List<Id>{selected}); } catch (AuraHandledException expected) { rejected=true; }
        System.assert(rejected); System.assertEquals(0,dispatchIdsFor(selected).size());
    }

    @IsTest
    static void joiningInstructionsMarkIsManualAndIdempotent() {
        configure(); Id selected=bookingId('COMPLETE');
        Integer emailCount=Limits.getEmailInvocations();
        NTEFinanceService.setJoiningInstructions(selected,true);
        Datetime first=[SELECT NTE_Final_Pack_Sent_At__c FROM Opportunity WHERE Id=:selected].NTE_Final_Pack_Sent_At__c;
        System.assertNotEquals(null,first);
        NTEFinanceService.setJoiningInstructions(selected,true);
        System.assertEquals(first,[SELECT NTE_Final_Pack_Sent_At__c FROM Opportunity WHERE Id=:selected].NTE_Final_Pack_Sent_At__c);
        System.assertEquals(emailCount,Limits.getEmailInvocations()); System.assertEquals(0,dispatchIdsFor(selected).size());
        update new Opportunity(Id=selected,NTE_Logo_Update_Provided__c=false);
        System.assertEquals('Sent',[SELECT NTE_Final_Pack_Status__c FROM Opportunity WHERE Id=:selected].NTE_Final_Pack_Status__c);
    }

    @IsTest
    static void previewEscapesEditableTextAndRoutesEachUpdateType() {
        configure();
        Id selected = bookingId('PARTNER');
        NTEEmailDispatchService.DraftDTO staff = NTEEmailDispatchService.buildDraft('STAFF_DUE', new List<Id>{selected});
        System.assertEquals('https://forms.example.invalid/partner-staff', staff.recipients[0].link);
        NTEEmailDispatchService.DraftRequest request = requestFor(staff, new Set<Id>{selected});
        request.messageBody = 'Hello {ContactName},\n\n<script>alert(1)</script>\n{Organisation}\n{BookingReference}\n{UpdateLink}';
        String preview = NTEEmailDispatchService.previewMessage(request, selected);
        System.assert(!preview.contains('<script>'));
        System.assert(preview.contains('&lt;script&gt;'));
        System.assert(preview.contains('&lt;Contact 1&gt;'));
        System.assert(preview.contains('Dispatch &lt;Organisation&gt; &amp; Partners'));
        System.assert(preview.contains('href="https://forms.example.invalid/partner-staff"'));
        System.assertEquals('https://forms.example.invalid/logistics', NTEEmailDispatchService.buildDraft('HEAVY_DUE', new List<Id>{selected}).recipients[0].link);
        System.assertEquals('https://forms.example.invalid/logo', NTEEmailDispatchService.buildDraft('LOGO_DUE', new List<Id>{selected}).recipients[0].link);
        request.messageBody = 'Hello {UnknownToken}';
        Boolean rejected = false;
        try { NTEEmailDispatchService.previewMessage(request, selected); }
        catch (AuraHandledException expected) { rejected = true; }
        System.assert(rejected, 'Unknown placeholders must not be sent as raw tokens.');
    }

    @IsTest
    static void oversizedSelectionAndMissingOrUnsafeLinkCannotQueue() {
        configure();
        Id selected = leadId('FUTURE-EVENT');
        List<Id> tooMany = new List<Id>();
        for (Integer index = 0; index < 501; index++) tooMany.add(selected);
        Boolean rejected = false;
        try { NTEEmailDispatchService.buildDraft('INVITATION', tooMany); }
        catch (AuraHandledException expected) { rejected = true; }
        System.assert(rejected);
        NTEEmailDispatchService.DraftDTO draft = NTEEmailDispatchService.buildDraft('INVITATION', new List<Id>{selected});
        NTEEmailDispatchService.DraftRequest request = requestFor(draft, new Set<Id>{selected});
        for (String invalidLink : new List<String>{null, 'javascript:alert(1)', 'http://forms.example.invalid/application',
            'https://', 'https:///missing-host', 'https://user:password@forms.example.invalid/application',
            'https://forms.example.invalid/with space', 'https://forms.example.invalid/with\ttab'}) {
            NTEEmailDispatchService.routingOverride.Exhibitor_Application_URL__c = invalidLink;
            NTEEmailDispatchService.DraftDTO blocked = NTEEmailDispatchService.buildDraft('INVITATION', new List<Id>{selected});
            System.assertEquals(false, blocked.canSend);
            System.assert(blocked.recipients[0].issue.contains('valid HTTPS link'));
            System.assertEquals(0, NTEEmailDispatchService.queueMessages(request).queuedCount);
        }
        System.assertEquals(0, [SELECT COUNT() FROM NTE_Email_Dispatch__c]);
    }

    @IsTest
    static void jsonPreviewAndQueuePreserveBrowserPayloadAndExactSelection() {
        configure();
        Id selected = leadId('EXHIBITOR'); Id unselected = leadId('PARTNER');
        NTEEmailDispatchService.DraftDTO draft = NTEEmailDispatchService.buildDraft('INVITATION', new List<Id>{selected, unselected});
        NTEEmailDispatchService.DraftRequest request = requestFor(draft, new Set<Id>{selected});
        request.subject = 'NTE "review" & next steps';
        request.messageBody = 'Hello {ContactName},\n\nPlease review <details> & your résumé.\n\n{UpdateLink}';
        String payload = JSON.serialize(request);

        Test.startTest();
        String preview = NTEEmailDispatchService.previewMessageJson(payload, selected);
        System.assert(preview.contains('&lt;details&gt; &amp;'));
        System.assert(preview.contains('href="https://forms.example.invalid/exhibitor-application"'));
        System.assert(!preview.contains('{ContactName}'));
        NTEEmailDispatchService.QueueResponse queued = (NTEEmailDispatchService.QueueResponse)JSON.deserialize(
            NTEEmailDispatchService.queueMessagesJson(payload), NTEEmailDispatchService.QueueResponse.class);
        System.assertEquals(1, queued.queuedCount);
        NTEEmailDispatchService.QueueResponse repeated = (NTEEmailDispatchService.QueueResponse)JSON.deserialize(
            NTEEmailDispatchService.queueMessagesJson(payload), NTEEmailDispatchService.QueueResponse.class);
        System.assertEquals(0, repeated.queuedCount);
        Test.stopTest();

        NTE_Email_Dispatch__c saved = [SELECT Kind__c, Lead__c, Subject__c, Message__c, Run_Id__c, Fingerprint__c,
            Status__c FROM NTE_Email_Dispatch__c WHERE Lead__c = :selected LIMIT 1];
        System.assertEquals('INVITATION', saved.Kind__c);
        System.assertEquals(selected, saved.Lead__c);
        System.assertEquals(request.subject, saved.Subject__c);
        System.assertEquals(request.messageBody, saved.Message__c);
        System.assertEquals(request.runId, saved.Run_Id__c);
        System.assertEquals(request.recipients[0].fingerprint, saved.Fingerprint__c);
        System.assertEquals('Queued', saved.Status__c);
        System.assertEquals(0, dispatchIdsFor(unselected).size());
        System.assertEquals(1, [SELECT COUNT() FROM NTE_Email_Dispatch__c]);
        System.assertEquals(false, [SELECT NTE_Interest_Progressed__c FROM Lead WHERE Id = :selected].NTE_Interest_Progressed__c);
    }

    @IsTest
    static void jsonBoundaryRejectsMalformedUnknownAndOversizedRequests() {
        configure();
        Id selected = leadId('EXHIBITOR');
        for (String invalid : new List<String>{null, '', '{', 'null', '[]', 'true', '{}'}) {
            assertJsonRejectedByBoth(invalid, selected);
        }
        NTEEmailDispatchService.DraftDTO draft = NTEEmailDispatchService.buildDraft('INVITATION', new List<Id>{selected});
        NTEEmailDispatchService.DraftRequest request = requestFor(draft, new Set<Id>{selected});
        Map<String, Object> payload = (Map<String, Object>)JSON.deserializeUntyped(JSON.serialize(request));
        payload.put('linkOverride', 'https://other.example.invalid/application');
        assertJsonRejectedByBoth(JSON.serialize(payload), selected);
        payload.remove('linkOverride');
        List<Object> selections = (List<Object>)payload.get('recipients');
        Map<String, Object> selection = (Map<String, Object>)selections[0];
        selection.put('email', 'unreviewed@example.invalid');
        assertJsonRejectedByBoth(JSON.serialize(payload), selected);

        request.recipients[0].fingerprint = null;
        assertJsonRejectedByBoth(JSON.serialize(request), selected);
        String oversized = 'x';
        while (oversized.length() <= 300000) oversized += oversized;
        assertJsonRejectedByBoth(oversized, selected);
        System.assertEquals(0, [SELECT COUNT() FROM NTE_Email_Dispatch__c]);
    }

    @IsTest
    static void jsonBoundaryRetainsRecipientChangeChecks() {
        configure();
        Id selected = leadId('EXHIBITOR');
        NTEEmailDispatchService.DraftDTO draft = NTEEmailDispatchService.buildDraft('INVITATION', new List<Id>{selected});
        String payload = JSON.serialize(requestFor(draft, new Set<Id>{selected}));
        update new Lead(Id = selected, Email = 'changed-after-preview@example.invalid');
        Boolean rejectedPreview = false;
        try { NTEEmailDispatchService.previewMessageJson(payload, selected); }
        catch (AuraHandledException expected) { rejectedPreview = true; }
        System.assert(rejectedPreview);
        NTEEmailDispatchService.QueueResponse queued = (NTEEmailDispatchService.QueueResponse)JSON.deserialize(
            NTEEmailDispatchService.queueMessagesJson(payload), NTEEmailDispatchService.QueueResponse.class);
        System.assertEquals(0, queued.queuedCount);
        System.assertEquals(1, queued.skippedCount);
        System.assertEquals(0, dispatchIdsFor(selected).size());
    }

    @IsTest
    static void largestDraftAndQueueKeepOnlyOneHtmlPreview() {
        configure();
        List<Lead> interests = bulkInterests(500);
        List<Id> ids = new List<Id>(new Map<Id, Lead>(interests).keySet());
        Test.startTest();
        NTEEmailDispatchService.DraftDTO draft = NTEEmailDispatchService.buildDraft('INVITATION', ids);
        System.assertEquals(500, draft.recipientCount);
        System.assertNotEquals(null, draft.previewHtml);
        System.assert(JSON.serialize(draft).length() < 750000,
            'A 500-recipient draft must not contain a complete HTML email for every recipient.');
        for (NTEEmailDispatchService.RecipientDTO recipient : draft.recipients) {
            System.assertEquals(null, recipient.previewHtml, 'Individual previews are requested when selected.');
        }
        NTEEmailDispatchService.DraftRequest request = requestFor(draft, new Set<Id>(ids));
        Integer heapBeforeQueue = Limits.getHeapSize();
        System.assertEquals(500, NTEEmailDispatchService.queueMessages(request).queuedCount);
        System.debug(LoggingLevel.INFO, 'NTE dispatch default-500 heap: before=' + heapBeforeQueue
            + ', after=' + Limits.getHeapSize() + ', limit=' + Limits.getLimitHeapSize());
        System.assertEquals(0, Limits.getEmailInvocations());
        Test.stopTest();
        System.assertEquals(500, [SELECT COUNT() FROM NTE_Email_Dispatch__c WHERE Status__c = 'Queued']);
        System.assertEquals(0, [SELECT COUNT() FROM Lead WHERE Id IN :ids AND NTE_Interest_Progressed__c = true]);
    }

    @IsTest
    static void maximumMessageAndSelectionFailBeforeRowsThenAllowASmallerSelection() {
        configure();
        List<Lead> interests = bulkInterests(500);
        List<Id> ids = new List<Id>(new Map<Id, Lead>(interests).keySet());
        Test.startTest();
        NTEEmailDispatchService.DraftDTO draft = NTEEmailDispatchService.buildDraft('INVITATION', ids);
        NTEEmailDispatchService.DraftRequest request = requestFor(draft, new Set<Id>(ids));
        request.messageBody = repeatedText('M', 32000);
        System.assertEquals(32000, request.messageBody.length());
        System.assert(request.messageBody.length() * request.recipients.size() > Limits.getLimitHeapSize(),
            'The raw repeated content alone exceeds synchronous heap even at one byte per character.');
        Boolean rejected = false;
        try { NTEEmailDispatchService.queueMessages(request); }
        catch (AuraHandledException expected) {
            rejected = true;
            System.assert(expected.getMessage().contains('Shorten the message or select fewer recipients'));
        }
        System.assert(rejected, 'An oversized combination must fail before retaining all dispatch records.');
        System.assertEquals(0, [SELECT COUNT() FROM NTE_Email_Dispatch__c]);
        System.assertEquals(0, [SELECT COUNT() FROM Lead WHERE Id IN :ids AND NTE_Invitation_Status__c = 'Queued']);
        System.assertEquals(0, Limits.getQueueableJobs());
        System.assertEquals(0, Limits.getEmailInvocations());
        Set<Id> smallerSelection = new Set<Id>{ids[0], ids[1]};
        request = requestFor(draft, smallerSelection);
        request.messageBody = repeatedText('M', 32000);
        System.assertEquals(2, NTEEmailDispatchService.queueMessages(request).queuedCount,
            'Maximum-length text remains supported for a sufficiently small reviewed selection.');
        Test.stopTest();
        System.assertEquals(2, [SELECT COUNT() FROM NTE_Email_Dispatch__c WHERE Status__c = 'Queued']);
        for (NTE_Email_Dispatch__c dispatch : [SELECT Lead__c, Message__c FROM NTE_Email_Dispatch__c]) {
            System.assert(smallerSelection.contains(dispatch.Lead__c));
            System.assertEquals(32000, dispatch.Message__c.length());
        }
    }

    @IsTest
    static void combinedPersonalisationBudgetRejectsOtherwiseValidIndividualMessages() {
        configure();
        Integer personalisedCharacters = 240 * 100 + 99;
        Integer recipientCount = (Limits.getLimitHeapSize() / (4 * personalisedCharacters)) + 2;
        System.assert(recipientCount <= 500, 'The heap-derived fixture must fit the supported recipient limit.');
        List<Lead> interests = bulkInterests(recipientCount);
        List<Lead> updates = new List<Lead>();
        String company = repeatedText('M', 240);
        for (Lead interest : interests) updates.add(new Lead(Id = interest.Id, Company = company));
        update updates;
        Set<Id> ids = new Map<Id, Lead>(interests).keySet();
        Test.startTest();
        NTEEmailDispatchService.DraftDTO draft = NTEEmailDispatchService.buildDraft('INVITATION', new List<Id>(ids));
        System.assertEquals(recipientCount, draft.recipientCount, 'Every size-test recipient must be eligible.');
        NTEEmailDispatchService.DraftRequest request = requestFor(draft, ids);
        List<String> words = new List<String>();
        for (Integer index = 0; index < 100; index++) words.add('{Organisation}');
        request.messageBody = String.join(words, ' ');
        System.assert(request.messageBody.length() * request.recipients.size() * 4 < Limits.getLimitHeapSize(),
            'The raw draft must fit; this case exercises aggregate personalized content.');
        System.assert(personalisedCharacters * request.recipients.size() * 4 > Limits.getLimitHeapSize(),
            'The expanded fixture must exceed the actual transaction heap: limit=' + Limits.getLimitHeapSize()
            + ', recipients=' + recipientCount + ', expandedCharacters=' + personalisedCharacters);
        System.assert(NTEEmailDispatchService.previewMessage(request, interests[0].Id).contains(company),
            'An individual personalized message remains within its 32,000-character limit.');
        Boolean rejected = false;
        try { NTEEmailDispatchService.queueMessages(request); }
        catch (AuraHandledException expected) {
            rejected = true;
            System.assert(expected.getMessage().contains('Shorten the message or select fewer recipients'));
        }
        System.assert(rejected, 'The oversized personalized batch must be rejected: limit=' + Limits.getLimitHeapSize()
            + ', recipients=' + recipientCount + ', expandedCharacters=' + personalisedCharacters);
        System.assertEquals(0, [SELECT COUNT() FROM NTE_Email_Dispatch__c]);
        System.assertEquals(0, [SELECT COUNT() FROM Lead WHERE Id IN :ids AND NTE_Invitation_Status__c = 'Queued']);
        System.assertEquals(0, Limits.getQueueableJobs());
        System.assertEquals(0, Limits.getEmailInvocations());
        Test.stopTest();
    }

    @IsTest
    static void combinedHtmlEscapingBudgetProtectsTheWorkerPayload() {
        configure();
        String messageBody = repeatedText('&', 4000);
        Integer escapedCharacters = messageBody.escapeHtml4().length();
        System.assert(escapedCharacters > messageBody.length(), 'The fixture must expand when HTML-escaped.');
        Integer recipientCount = (Limits.getLimitHeapSize() / (4 * escapedCharacters)) + 2;
        System.assert(recipientCount <= 500, 'The heap-derived fixture must fit the supported recipient limit.');
        List<Lead> interests = bulkInterests(recipientCount);
        Set<Id> ids = new Map<Id, Lead>(interests).keySet();
        Test.startTest();
        NTEEmailDispatchService.DraftDTO draft = NTEEmailDispatchService.buildDraft('INVITATION', new List<Id>(ids));
        System.assertEquals(recipientCount, draft.recipientCount, 'Every size-test recipient must be eligible.');
        NTEEmailDispatchService.DraftRequest request = requestFor(draft, ids);
        request.messageBody = messageBody;
        System.assert(request.messageBody.length() * ids.size() * 4 < Limits.getLimitHeapSize());
        System.assert(request.messageBody.escapeHtml4().length() * ids.size() * 4 > Limits.getLimitHeapSize(),
            'Escaped content must exceed the actual transaction heap: limit=' + Limits.getLimitHeapSize()
            + ', recipients=' + recipientCount + ', escapedCharacters=' + escapedCharacters);
        Boolean rejected = false;
        try { NTEEmailDispatchService.queueMessages(request); }
        catch (AuraHandledException expected) {
            rejected = true;
            System.assert(expected.getMessage().contains('Shorten the message or select fewer recipients'));
        }
        System.assert(rejected, 'The oversized escaped batch must be rejected: limit=' + Limits.getLimitHeapSize()
            + ', recipients=' + recipientCount + ', escapedCharacters=' + escapedCharacters);
        System.assertEquals(0, [SELECT COUNT() FROM NTE_Email_Dispatch__c]);
        System.assertEquals(0, Limits.getEmailInvocations());
        Test.stopTest();
    }

    @IsTest
    static void fullWorkerPageMapsFailuresAndSkipsToTheirOwnRecipients() {
        configure();
        List<Lead> interests = bulkInterests(41);
        Set<Id> selected = new Map<Id, Lead>(interests).keySet();
        NTEEmailDispatchService.DraftDTO draft = NTEEmailDispatchService.buildDraft('INVITATION', new List<Id>(selected));
        NTEEmailDispatchService.queueMessages(requestFor(draft, selected));
        List<NTE_Email_Dispatch__c> queued = [SELECT Id, Lead__c FROM NTE_Email_Dispatch__c ORDER BY Id];
        Set<Id> failures = new Set<Id>{queued[9].Lead__c, queued[19].Lead__c, queued[29].Lead__c, queued[39].Lead__c};
        NTEEmailDispatchService.simulatedFailures.addAll(failures);
        Id changed = queued[4].Lead__c;
        update new Lead(Id = changed, Email = 'changed-selection@example.invalid');
        List<Id> firstPage = new List<Id>();
        for (Integer index = 0; index < 40; index++) firstPage.add(queued[index].Id);
        Test.startTest();
        NTEEmailDispatchService.processQueued(firstPage, true);
        System.assertEquals('Queued', dispatchFor(queued[40].Lead__c).Status__c);
        NTEEmailDispatchService.processQueued(new List<Id>{queued[40].Id}, true);
        Test.stopTest();
        for (NTE_Email_Dispatch__c dispatch : [SELECT Lead__c, Status__c, Sent_At__c FROM NTE_Email_Dispatch__c]) {
            String expected = dispatch.Lead__c == changed ? 'Skipped' : failures.contains(dispatch.Lead__c) ? 'Failed' : 'Sent';
            System.assertEquals(expected, dispatch.Status__c, 'Outcomes must follow sendable records after a skipped entry.');
            System.assertEquals(expected == 'Sent', dispatch.Sent_At__c != null);
        }
        System.assertEquals(36, [SELECT COUNT() FROM Lead WHERE Id IN :selected AND NTE_Interest_Progressed__c = true]);
        System.assertEquals(0, Limits.getEmailInvocations());
    }

    @IsTest
    static void queuedSourceRejectsAnotherDraftEvenWithAnotherRunId() {
        configure();
        Id selected = leadId('EXHIBITOR');
        NTEEmailDispatchService.DraftDTO first = NTEEmailDispatchService.buildDraft('INVITATION', new List<Id>{selected});
        NTEEmailDispatchService.DraftDTO second = NTEEmailDispatchService.buildDraft('INVITATION', new List<Id>{selected});
        System.assertNotEquals(first.runId, second.runId);
        Test.startTest();
        System.assertEquals(1, NTEEmailDispatchService.queueMessages(requestFor(first, new Set<Id>{selected})).queuedCount);
        System.assertEquals(0, NTEEmailDispatchService.queueMessages(requestFor(second, new Set<Id>{selected})).queuedCount);
        NTEEmailDispatchService.processQueued(dispatchIdsFor(selected), true);
        System.assertEquals(0, NTEEmailDispatchService.queueMessages(requestFor(second, new Set<Id>{selected})).queuedCount);
        Test.stopTest();
        System.assertEquals(1, dispatchIdsFor(selected).size());
        System.assertEquals('Sent', dispatchFor(selected).Status__c);
    }

    @IsTest
    static void reminderKindsRemainIndependentAndRepeatableUntilComplete() {
        configure();
        Id selected = bookingId('PARTNER');
        Test.startTest();
        for (String kind : new List<String>{'STAFF_DUE', 'HEAVY_DUE', 'LOGO_DUE'}) {
            NTEEmailDispatchService.DraftDTO draft = NTEEmailDispatchService.buildDraft(kind, new List<Id>{selected});
            System.assertEquals('dispatch-primary-1@example.invalid', draft.recipients[0].email);
            System.assertEquals(1, NTEEmailDispatchService.queueMessages(requestFor(draft, new Set<Id>{selected})).queuedCount);
        }
        NTEEmailDispatchService.processQueued(dispatchIdsFor(selected), true);
        NTEEmailDispatchService.DraftDTO repeat = NTEEmailDispatchService.buildDraft('STAFF_DUE', new List<Id>{selected});
        System.assert(repeat.canSend);
        System.assertNotEquals(null, repeat.recipients[0].lastSentAt);
        System.assertEquals(1, NTEEmailDispatchService.queueMessages(requestFor(repeat, new Set<Id>{selected})).queuedCount);
        NTEEmailDispatchService.processQueued(dispatchIdsFor(selected), true);
        Test.stopTest();
        System.assertEquals(4, [SELECT COUNT() FROM NTE_Email_Dispatch__c WHERE Status__c = 'Sent']);
        update new Opportunity(Id = selected, NTE_Staff_Update_Completed_At__c = System.now(),
            NTE_Heavy_Vehicle_Required__c = 'Yes', NTE_Heavy_Vehicle_Update_Completed_At__c = System.now(), NTE_Logo_Update_Provided__c = true);
        for (String kind : new List<String>{'STAFF_DUE', 'HEAVY_DUE', 'LOGO_DUE'}) {
            System.assertEquals(false, NTEEmailDispatchService.buildDraft(kind, new List<Id>{selected}).canSend);
        }
    }

    @IsTest
    static void manualJoiningMarkCanBeCorrectedWithoutSending() {
        configure(); Id selected=bookingId('COMPLETE');
        NTEFinanceService.setJoiningInstructions(selected,true); NTEFinanceService.setJoiningInstructions(selected,false);
        Opportunity saved=[SELECT NTE_Final_Pack_Status__c,NTE_Final_Pack_Sent_At__c,NTE_Joining_Instructions_By__c FROM Opportunity WHERE Id=:selected];
        System.assertEquals(null,saved.NTE_Final_Pack_Status__c); System.assertEquals(null,saved.NTE_Final_Pack_Sent_At__c);
        System.assertEquals(null,saved.NTE_Joining_Instructions_By__c); System.assertEquals(0,dispatchIdsFor(selected).size());
    }

    @IsTest
    static void tokenLookingDataStaysLiteralAndTextKeepsParagraphs() {
        configure();
        Id selected = leadId('EXHIBITOR');
        update new Lead(Id = selected, FirstName = '{Organisation}', Company = 'Marsh {FinalPackLink} & Co');
        NTEEmailDispatchService.DraftDTO draft = NTEEmailDispatchService.buildDraft('INVITATION', new List<Id>{selected});
        NTEEmailDispatchService.DraftRequest request = requestFor(draft, new Set<Id>{selected});
        request.messageBody = 'Hello {ContactName},\r\r{Organisation}\r<one & two>\r{UpdateLink}';
        NTEEmailDispatchService.queueMessages(request);
        NTEEmailDispatchService.processQueued(dispatchIdsFor(selected), true);
        String html = NTEEmailDispatchService.renderedHtml.get(selected);
        String plain = NTEEmailDispatchService.renderedText.get(selected);
        System.assert(html.contains('Hello {Organisation} DISPATCH-EXHIBITOR,'));
        System.assert(html.contains('Marsh {FinalPackLink} &amp; Co'));
        System.assert(html.contains('<br><br>Marsh'));
        System.assert(html.contains('&lt;one &amp; two&gt;'));
        System.assert(plain.contains('\n\nMarsh {FinalPackLink} & Co\n<one & two>\n'));
        System.assert(plain.contains('https://forms.example.invalid/exhibitor-application'));
        System.assert(!plain.contains('<br>'));
    }

    @IsTest
    static void contactRolesUseExactlyOnePrimaryAndNeverFallback() {
        configure();
        Id selected = bookingId('EXHIBITOR');
        Id withoutPrimary = bookingId('MISSING-CONTACT');
        Contact primary = [SELECT Id, Email FROM Contact WHERE Email = 'dispatch-primary-0@example.invalid' LIMIT 1];
        Contact other = [SELECT Id FROM Contact WHERE Email = 'dispatch-primary-1@example.invalid' LIMIT 1];
        insert new OpportunityContactRole(OpportunityId = selected, ContactId = other.Id, IsPrimary = false);
        Map<Id, Contact> contacts = NTEBookingContactService.primaryContacts(new Set<Id>{selected, withoutPrimary}, AccessLevel.USER_MODE, true);
        System.assertEquals(primary.Id, contacts.get(selected).Id);
        System.assertEquals(false, contacts.containsKey(withoutPrimary));
        System.assertEquals(0, NTEBookingContactService.primaryContacts(null, AccessLevel.USER_MODE).size());
        System.assertEquals(0, NTEBookingContactService.primaryContacts(new Set<Id>(), AccessLevel.USER_MODE, true).size());
        Map<Id, Id> unique = NTEBookingContactService.singlePrimaryContactIds(new List<OpportunityContactRole>{
            new OpportunityContactRole(OpportunityId = selected, ContactId = primary.Id),
            new OpportunityContactRole(OpportunityId = selected, ContactId = other.Id),
            new OpportunityContactRole(OpportunityId = withoutPrimary, ContactId = null),
            new OpportunityContactRole(OpportunityId = withoutPrimary, ContactId = other.Id)
        });
        System.assertEquals(0, unique.size(), 'Ambiguous roles must never resolve by row order, even if one Contact is absent.');
        update new Contact(Id = primary.Id, Email = null);
        NTEEmailDispatchService.DraftDTO blocked = NTEEmailDispatchService.buildDraft('STAFF_DUE', new List<Id>{selected});
        System.assertEquals(false, blocked.canSend);
        System.assert(blocked.recipients[0].issue.contains('email address is missing'));
        System.assertEquals(null, blocked.recipients[0].email, 'Do not substitute another role or the event-day address.');
    }

    @IsTest
    static void mergedBookingDetailsChangedAfterPaymentRequireRetry() {
        configure();
        Id selected = bookingId('PARTNER');
        update new Opportunity(Id = selected, NTE_Invoice_Provided__c = true,
            NTE_Payment_Received__c = true, NTE_Payment_Received_At__c = System.now());
        System.assertEquals(1, NTEEmailDispatchService.queueBookingConfirmation(selected).queuedCount);
        Id originalDispatch = dispatchFor(selected).Id;
        update new Opportunity(Id = selected, NTE_Invoice_Address__c = '12 Green Road\nManchester');
        NTEEmailDispatchService.processQueued(new List<Id>{originalDispatch}, true);
        System.assertEquals('Failed', dispatchFor(selected).Status__c);
        System.assertEquals(null, dispatchFor(selected).Sent_At__c);
        System.assert(!NTEEmailDispatchService.renderedHtml.containsKey(selected));
        System.assertEquals(true, [SELECT NTE_Payment_Received__c FROM Opportunity WHERE Id = :selected].NTE_Payment_Received__c);
        System.assertEquals(1, NTEEmailDispatchService.retryDispatch(originalDispatch).queuedCount);
        NTEEmailDispatchService.processQueued(new List<Id>{originalDispatch}, true);
        System.assertEquals('Sent', dispatchFor(selected).Status__c);
        System.assertEquals(originalDispatch, dispatchFor(selected).Id);
        System.assert(NTEEmailDispatchService.renderedHtml.get(selected).contains('12 Green Road'));
    }

    @IsTest
    static void tamperedSelectionDoesNotCrossRecordsOrEmailKinds() {
        configure();
        Id selected = leadId('EXHIBITOR'); Id other = leadId('PARTNER');
        NTEEmailDispatchService.DraftDTO draft = NTEEmailDispatchService.buildDraft('INVITATION', new List<Id>{selected, other});
        NTEEmailDispatchService.DraftRequest request = requestFor(draft, new Set<Id>{selected});
        request.recipients[0].recordId = other;
        System.assertEquals(0, NTEEmailDispatchService.queueMessages(request).queuedCount);
        request.kind = 'BOOKING_CONFIRMED';
        assertJsonRejectedByBoth(JSON.serialize(request), other);
        request.kind = 'STAFF_DUE';
        assertJsonRejectedByBoth(JSON.serialize(request), other);
        request = requestFor(draft, new Set<Id>{selected});
        request.recipients.add(request.recipients[0]);
        assertJsonRejectedByBoth(JSON.serialize(request), selected);
        request = requestFor(draft, new Set<Id>{selected});
        request.subject = 'Invitation\r\nBcc: unrelated@example.invalid';
        assertJsonRejectedByBoth(JSON.serialize(request), selected);
        System.assertEquals(0, [SELECT COUNT() FROM NTE_Email_Dispatch__c]);
    }

    @IsTest
    static void expandedSubjectAndMessageMustStillFitTheirLimits() {
        configure();
        Id selected = leadId('EXHIBITOR');
        String company = '';
        for (Integer index = 0; index < 240; index++) company += 'M';
        update new Lead(Id = selected, Company = company);
        NTEEmailDispatchService.DraftDTO draft = NTEEmailDispatchService.buildDraft('INVITATION', new List<Id>{selected});
        NTEEmailDispatchService.DraftRequest request = requestFor(draft, new Set<Id>{selected});
        request.subject = 'Your application invitation for {Organisation}';
        assertJsonRejectedByBoth(JSON.serialize(request), selected);
        request.subject = 'Your invitation';
        List<String> repeated = new List<String>();
        for (Integer index = 0; index < 140; index++) repeated.add('{Organisation}');
        request.messageBody = String.join(repeated, '\n');
        assertJsonRejectedByBoth(JSON.serialize(request), selected);
        System.assertEquals(0, dispatchIdsFor(selected).size());
    }

    @IsTest
    static void confirmationStillSendsWhenProvisionalFailedAndQueueFailureIsRecoverable() {
        configure();
        Id selected = bookingId('PARTNER');
        update new Opportunity(Id = selected, NTE_Invoice_Provided__c = true,
            NTE_Payment_Received__c = true, NTE_Payment_Received_At__c = System.now(), NTE_Approval_Email_Status__c = 'Failed');
        NTEEmailDispatchService.simulateEnqueueFailure = true;
        NTEEmailDispatchService.QueueResponse failed = NTEEmailDispatchService.queueBookingConfirmation(selected);
        NTE_Email_Dispatch__c dispatch = dispatchFor(selected);
        System.assertEquals(0, failed.queuedCount);
        System.assertEquals('Failed', dispatch.Status__c);
        System.assert(dispatch.Error__c.contains('could not be queued'));
        System.assertEquals(true, [SELECT NTE_Payment_Received__c FROM Opportunity WHERE Id = :selected].NTE_Payment_Received__c);
        NTEEmailDispatchService.simulateEnqueueFailure = false;
        System.assertEquals(1, NTEEmailDispatchService.retryDispatch(dispatch.Id).queuedCount);
        NTEEmailDispatchService.processQueued(new List<Id>{dispatch.Id}, true);
        System.assertEquals('Sent', dispatchFor(selected).Status__c,
            'The confirmed immediate payment notification must not wait for a failed provisional email.');
        System.assertEquals('Failed', [SELECT NTE_Approval_Email_Status__c FROM Opportunity WHERE Id = :selected].NTE_Approval_Email_Status__c);
        System.assertEquals(1, dispatchIdsFor(selected).size());
    }

    @IsTest
    static void manualJoiningHistoryStaysOnItsExactBookingAfterTopUp() {
        configure(); Id early=bookingId('COMPLETE'); Id late=bookingId('EXHIBITOR');
        NTEFinanceService.setJoiningInstructions(early,true);
        Datetime first=[SELECT NTE_Final_Pack_Sent_At__c FROM Opportunity WHERE Id=:early].NTE_Final_Pack_Sent_At__c;
        System.assertEquals(null,[SELECT NTE_Final_Pack_Sent_At__c FROM Opportunity WHERE Id=:late].NTE_Final_Pack_Sent_At__c);
        NTEFinanceService.setJoiningInstructions(late,true);
        update new Opportunity(Id=early,NTE_Top_Up_Staff_Total__c=50,NTE_Top_Up_Invoice_Required__c=true);
        System.assertEquals(first,[SELECT NTE_Final_Pack_Sent_At__c FROM Opportunity WHERE Id=:early].NTE_Final_Pack_Sent_At__c);
        System.assertEquals(0,[SELECT COUNT() FROM NTE_Email_Dispatch__c]);
    }

    @IsTest
    static void unusableBookingReferenceCannotCreatePreparationMailOrAPack() {
        configure();
        Id reminder = bookingId('PARTNER'); Id pack = bookingId('COMPLETE');
        update new List<Opportunity>{new Opportunity(Id = reminder, Booking_Reference__c = 'BROKEN'),
            new Opportunity(Id = pack, Booking_Reference__c = 'NTE-')};
        for (String kind : new List<String>{'STAFF_DUE', 'HEAVY_DUE', 'LOGO_DUE'}) {
            NTEEmailDispatchService.DraftDTO draft = NTEEmailDispatchService.buildDraft(kind, new List<Id>{reminder});
            System.assertEquals(false, draft.canSend);
            System.assert(draft.recipients[0].issue.contains('booking reference is invalid'));
            System.assertEquals(0, NTEEmailDispatchService.queueMessages(requestFor(draft, new Set<Id>{reminder})).queuedCount);
        }
        System.assertEquals(0, [SELECT COUNT() FROM NTE_Email_Dispatch__c]);
    }

    private static List<Lead> bulkInterests(Integer count) {
        NTEInboundLeadService.bypassEmailDelivery = true;
        List<Lead> interests = new List<Lead>();
        for (Integer index = 0; index < count; index++) interests.add(new Lead(
            FirstName = 'Alex', LastName = 'Morgan ' + index, Company = 'Juniper Engineering ' + index,
            Email = 'dispatch-' + index + '@example.invalid', Status = 'New',
            Web_Form_Type__c = 'Exhibitor Expression of Interest', NTE_Event_Code__c = EVENT_CODE));
        insert interests;
        return interests;
    }

    private static String repeatedText(String value, Integer length) {
        String result = value;
        while (result.length() < length) result += result;
        return result.left(length);
    }

    private static void assertJsonRejectedByBoth(String payload, Id recordId) {
        Boolean previewRejected = false;
        Boolean sendRejected = false;
        try { NTEEmailDispatchService.previewMessageJson(payload, recordId); }
        catch (AuraHandledException expected) { previewRejected = true; }
        try { NTEEmailDispatchService.queueMessagesJson(payload); }
        catch (AuraHandledException expected) { sendRejected = true; }
        System.assert(previewRejected, 'Preview must reject an invalid email request.');
        System.assert(sendRejected, 'Sending must reject the same invalid email request.');
    }

    @IsTest
    static void nativeInvitationAndReminderSendsAcceptTheirActivityLinks() {
        configure();
        Id interestId = leadId('EXHIBITOR'); Id opportunityId = bookingId('EXHIBITOR');
        NTEEmailDispatchService.DraftDTO invitation = NTEEmailDispatchService.buildDraft('INVITATION', new List<Id>{interestId});
        NTEEmailDispatchService.DraftDTO reminder = NTEEmailDispatchService.buildDraft('STAFF_DUE', new List<Id>{opportunityId});
        Test.startTest();
        System.assertEquals(1, NTEEmailDispatchService.queueMessages(requestFor(invitation, new Set<Id>{interestId})).queuedCount);
        System.assertEquals(1, NTEEmailDispatchService.queueMessages(requestFor(reminder, new Set<Id>{opportunityId})).queuedCount);
        List<Id> dispatchIds = dispatchIdsFor(interestId); dispatchIds.addAll(dispatchIdsFor(opportunityId));
        NTEEmailDispatchService.processQueued(dispatchIds, false);
        System.assertEquals(1, Limits.getEmailInvocations());
        for (NTE_Email_Dispatch__c dispatch : [SELECT Status__c, Error__c, Recipient__c FROM NTE_Email_Dispatch__c WHERE Id IN :dispatchIds]) {
            System.assertEquals('Sent', dispatch.Status__c, 'Native dispatch: ' + dispatch.Error__c);
            System.assert(dispatch.Recipient__c.startsWith('dispatch-'));
        }
        Test.stopTest();
    }

    private static NTEEmailDispatchService.DraftRequest requestFor(NTEEmailDispatchService.DraftDTO draft, Set<Id> selected) {
        NTEEmailDispatchService.DraftRequest request = new NTEEmailDispatchService.DraftRequest();
        request.kind = draft.kind; request.runId = draft.runId; request.subject = draft.subject; request.messageBody = draft.messageBody;
        request.recipients = new List<NTEEmailDispatchService.Selection>();
        for (NTEEmailDispatchService.RecipientDTO recipient : draft.recipients) {
            if (!selected.contains(recipient.recordId)) continue;
            NTEEmailDispatchService.Selection selection = new NTEEmailDispatchService.Selection();
            selection.recordId = recipient.recordId; selection.fingerprint = recipient.fingerprint;
            request.recipients.add(selection);
        }
        return request;
    }
    private static Id leadId(String name) {
        String lastName = 'DISPATCH-' + name;
        return [SELECT Id FROM Lead WHERE LastName = :lastName LIMIT 1].Id;
    }
    private static Id bookingId(String name) {
        String bookingName = 'DISPATCH-' + name;
        return [SELECT Id FROM Opportunity WHERE Name = :bookingName LIMIT 1].Id;
    }
    private static List<Id> dispatchIdsFor(Id recordId) {
        List<Id> ids = new List<Id>();
        for (NTE_Email_Dispatch__c dispatch : [SELECT Id FROM NTE_Email_Dispatch__c
            WHERE Lead__c = :recordId OR Opportunity__c = :recordId]) ids.add(dispatch.Id);
        return ids;
    }
    private static NTE_Email_Dispatch__c dispatchFor(Id recordId) {
        return [SELECT Id, Status__c, Sent_At__c, Recipient__c, Error__c FROM NTE_Email_Dispatch__c
            WHERE Lead__c = :recordId OR Opportunity__c = :recordId LIMIT 1];
    }
}
