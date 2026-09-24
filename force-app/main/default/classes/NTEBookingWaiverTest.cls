@IsTest
private class NTEBookingWaiverTest {
    private class Fixture {
        Id bookingId;
        Id leadId;
        Decimal originalNet;
        Decimal originalGross;
        Datetime priorSentAt;
        Id priorTaskId;
    }

    @TestSetup static void access() {
        PermissionSet permission = [SELECT Id FROM PermissionSet WHERE Name = 'NTE_Forms_Administration'];
        if ([SELECT COUNT() FROM PermissionSetAssignment WHERE AssigneeId = :UserInfo.getUserId()
            AND PermissionSetId = :permission.Id] == 0) {
            insert new PermissionSetAssignment(AssigneeId = UserInfo.getUserId(), PermissionSetId = permission.Id);
        }
    }

    private static Fixture application(String key, Boolean partner) {
        return application(key, partner, true);
    }

    private static Fixture application(String key, Boolean partner, Boolean priorProvisionalSent) {
        NTEInboundLeadService.bypassEmailDelivery = true;
        NTEExhibitorApprovalEmailService.bypassEmailDelivery = true;
        Lead application = new Lead(FirstName = 'Waiver', LastName = key, Company = 'Waiver fixture ' + key,
            Email = 'waiver.' + key.toLowerCase() + '@example.invalid', NTE_Event_Code__c = 'NTE2099',
            Booking_Reference__c = 'NTE-WAIVER-' + key,
            Web_Form_Type__c = partner ? 'Partner / Sponsor Application' : 'Exhibitor Application',
            Exhibitor_Organisation_Category__c = partner ? null : 'CIC or Not for Profit',
            Exhibitor_Space_Selections__c = partner ? null : 'Single Garage - Track Side - £799 + VAT',
            Sponsor_Package__c = partner ? 'Champion Partner' : null, Planned_Exhibitor_Count__c = '2',
            Total_Staff_Count__c = 2, Stand_Power__c = 'No', Heavy_Vehicle_Required__c = 'No',
            Payment_Method__c = 'Bank transfer');
        insert application;
        Database.LeadConvert request = new Database.LeadConvert();
        request.setLeadId(application.Id);
        request.setConvertedStatus([SELECT MasterLabel FROM LeadStatus WHERE IsConverted = true LIMIT 1].MasterLabel);
        request.setOpportunityName(application.Company);
        Database.LeadConvertResult conversion = Database.convertLead(request);
        System.assert(conversion.isSuccess(), String.valueOf(conversion.getErrors()));
        Fixture result = new Fixture();
        result.bookingId = conversion.getOpportunityId(); result.leadId = application.Id;
        Opportunity booking = state(result.bookingId);
        result.originalNet = booking.NTE_Listed_Price_Total__c; result.originalGross = booking.Amount;
        System.assert(result.originalNet > 0, 'The fixture must begin with a chargeable allocation.');
        if (!priorProvisionalSent) {
            System.assertNotEquals('Sent', booking.NTE_Approval_Email_Status__c);
            System.assertEquals(null, booking.NTE_Approval_Email_Sent_At__c);
            System.assertEquals(0, [SELECT COUNT() FROM Task WHERE WhatId = :result.bookingId
                AND Subject IN ('NTE booking provisional email - sent', 'NTE free-space confirmation email - sent')]);
            return result;
        }
        result.priorSentAt = System.now().addDays(-2);
        update new Opportunity(Id = result.bookingId, NTE_Approval_Email_Status__c = 'Sent',
            NTE_Approval_Email_Sent_At__c = result.priorSentAt,
            NTE_Approval_Email_Recipient__c = 'original-recipient@example.invalid');
        Task prior = new Task(WhatId = result.bookingId, Subject = 'NTE booking provisional email - sent',
            Status = [SELECT MasterLabel FROM TaskStatus WHERE IsClosed = true ORDER BY SortOrder LIMIT 1].MasterLabel,
            Priority = 'Normal', Description = 'Original provisional email accepted before the waiver.');
        insert prior; result.priorTaskId = prior.Id;
        return result;
    }

    private static void waive(Fixture fixture) {
        update new Opportunity(Id = fixture.bookingId, NTE_Price_Adjustment__c = -fixture.originalNet,
            NTE_Listed_Price_Total__c = 0, Amount = 0);
    }

    private static Opportunity state(Id bookingId) {
        return [SELECT Id, Amount, NTE_Listed_Price_Total__c, NTE_Price_Adjustment__c,
            NTE_VAT_Rate__c, NTE_VAT_Total__c, NTE_Invoice_Required__c,
            NTE_Approval_Email_Status__c, NTE_Approval_Email_Kind__c, NTE_Approval_Email_Error__c,
            NTE_Approval_Email_Batch__c, NTE_Approval_Email_Sent_At__c, NTE_Approval_Email_Recipient__c,
            NTE_Free_Space_Confirmed__c, NTE_Payment_Received__c, NTE_Payment_Received_At__c,
            NTE_Top_Up_Payment_Received__c, NTE_Top_Up_Payment_At__c, NTE_Quote_Provided__c,
            NTE_Invoice_Provided__c, NTE_Final_Pack_Status__c, LastModifiedDate
            FROM Opportunity WHERE Id = :bookingId];
    }

    private static Id historicalRequest(Fixture fixture) {
        NTE_Payment_Request__c payment = new NTE_Payment_Request__c(Opportunity__c = fixture.bookingId,
            Charge_Key__c = UserInfo.getOrganizationId() + ':' + fixture.bookingId + ':Booking',
            Kind__c = 'Booking', Status__c = 'Ready', Net_Minor__c = fixture.originalNet * 100,
            Amount_Minor__c = fixture.originalGross * 100, Tax_Rate__c = 20, Currency__c = 'gbp',
            Live_Mode__c = false, Stripe_Account__c = 'acct_waiver_history', Source_Fingerprint__c = 'original-fingerprint',
            Source_Lead_Id__c = String.valueOf(fixture.leadId), Reference__c = 'NTE-WAIVER-HISTORY',
            Description__c = 'Original booking charge', Price_Id__c = 'price_waiver_history', Link_Id__c = 'plink_waiver_history',
            Payment_URL__c = 'https://buy.stripe.com/test_waiver_history', Verified_At__c = fixture.priorSentAt,
            Delivered_At__c = fixture.priorSentAt, Recipient__c = 'original-recipient@example.invalid');
        insert payment;
        return payment.Id;
    }

    private static String requestSnapshot(Id paymentId) {
        return JSON.serialize([SELECT Id, Opportunity__c, Charge_Key__c, Kind__c, Status__c, Net_Minor__c,
            Amount_Minor__c, Tax_Rate__c, Currency__c, Live_Mode__c, Stripe_Account__c, Source_Fingerprint__c,
            Source_Lead_Id__c, Reference__c, Description__c, Price_Id__c, Link_Id__c, Payment_URL__c,
            First_Attempt_At__c, Verified_At__c, Error__c, Delivered_At__c, Recipient__c, Batch_Key__c, LastModifiedDate
            FROM NTE_Payment_Request__c WHERE Id = :paymentId]);
    }

    private static NTEExhibitorApprovalEmailService.Request emailRequest(Fixture fixture) {
        NTEExhibitorApprovalEmailService.Request result = new NTEExhibitorApprovalEmailService.Request();
        result.leadId = fixture.leadId; result.opportunityId = fixture.bookingId;
        return result;
    }

    private static void assertFreeBlocked(Id bookingId) {
        Boolean blocked = false;
        try { NTEFinanceService.sendFinanceAction(bookingId, 'FREE'); }
        catch (AuraHandledException expected) { blocked = true; }
        System.assert(blocked, 'A completed or pending confirmation must not queue another free confirmation.');
    }

    private static void assertHistory(Fixture fixture, Boolean expectedFree) {
        Opportunity booking = state(fixture.bookingId);
        System.assertEquals(expectedFree, booking.NTE_Free_Space_Confirmed__c);
        System.assertEquals(fixture.priorSentAt, booking.NTE_Approval_Email_Sent_At__c,
            'A waiver must preserve the original provisional send timestamp. Its new Task records the free send.');
        System.assertEquals(false, booking.NTE_Payment_Received__c, 'Free confirmation must not invent a payment.');
        System.assertEquals(null, booking.NTE_Payment_Received_At__c);
        if (fixture.priorTaskId == null) {
            System.assertEquals(0, [SELECT COUNT() FROM Task WHERE WhatId = :fixture.bookingId
                AND Subject IN ('NTE booking provisional email - sent', 'NTE free-space confirmation email - sent')],
                'An unsent request whose intent changed must not acquire accepted-send history.');
        } else {
            System.assertEquals('Original provisional email accepted before the waiver.',
                [SELECT Description FROM Task WHERE Id = :fixture.priorTaskId].Description);
        }
        System.assertEquals(false, booking.NTE_Quote_Provided__c);
        System.assertEquals(false, booking.NTE_Invoice_Provided__c);
    }

    @IsTest static void exhibitorWaiverAfterSentProvisionalPreservesRequestAndPreventsDuplicates() {
        Fixture fixture = application('EXHIBITOR', false);
        Id paymentId = historicalRequest(fixture);
        Datetime topUpPaidAt = fixture.priorSentAt.addHours(1);
        update new Opportunity(Id = fixture.bookingId, NTE_Payment_Method__c = 'Stripe',
            NTE_Top_Up_Payment_Received__c = true, NTE_Top_Up_Payment_At__c = topUpPaidAt);
        waive(fixture);
        String beforeRequest = requestSnapshot(paymentId);
        Test.startTest();
        System.assertEquals(1, NTEFinanceService.sendFinanceAction(fixture.bookingId, 'FREE').queuedCount);
        Opportunity pending = state(fixture.bookingId);
        System.assertEquals('Pending', pending.NTE_Approval_Email_Status__c);
        System.assertEquals('Free confirmation', pending.NTE_Approval_Email_Kind__c);
        System.assertEquals(false, pending.NTE_Free_Space_Confirmed__c);
        assertFreeBlocked(fixture.bookingId);
        System.assertEquals(false, NTEStripeBookingService.prepareProvisionalBatch(pending.NTE_Approval_Email_Batch__c, true, false));
        NTEExhibitorApprovalEmailService.processPendingBatch(pending.NTE_Approval_Email_Batch__c, true, false);
        String html = NTEExhibitorApprovalEmailService.htmlByOpportunityId.get(fixture.bookingId);
        System.assert(html.contains('Your complimentary space is confirmed.'));
        System.assert(html.contains('No payment is due.'));
        System.assert(!html.contains('buy.stripe.com'));
        System.assertEquals('NTE_Complimentary_Exhibitor_Approved',
            NTEExhibitorApprovalEmailService.selectedTemplateByOpportunityId.get(fixture.bookingId));
        NTEExhibitorApprovalEmailService.processPendingBatch(pending.NTE_Approval_Email_Batch__c, true, false);
        assertFreeBlocked(fixture.bookingId);
        Test.stopTest();
        assertHistory(fixture, true);
        System.assertEquals('Sent', state(fixture.bookingId).NTE_Approval_Email_Status__c);
        System.assertEquals(topUpPaidAt, state(fixture.bookingId).NTE_Top_Up_Payment_At__c);
        System.assertEquals(true, state(fixture.bookingId).NTE_Top_Up_Payment_Received__c);
        System.assertEquals(beforeRequest, requestSnapshot(paymentId));
        System.assertEquals(1, [SELECT COUNT() FROM NTE_Payment_Request__c]);
        System.assertEquals(2, [SELECT COUNT() FROM Task WHERE WhatId = :fixture.bookingId AND Subject IN ('NTE booking provisional email - sent', 'NTE free-space confirmation email - sent')]);
        System.assertEquals(0, [SELECT COUNT() FROM NTE_Email_Dispatch__c]);
    }

    @IsTest static void partnerWaiverUsesConfirmedPackageWordingAndCorrectPreparationLink() {
        Fixture fixture = application('PARTNER', true); waive(fixture);
        Test.startTest();
        NTEFinanceService.sendFinanceAction(fixture.bookingId, 'FREE');
        NTEExhibitorApprovalEmailService.processPendingBatch(state(fixture.bookingId).NTE_Approval_Email_Batch__c, true, false);
        String html = NTEExhibitorApprovalEmailService.htmlByOpportunityId.get(fixture.bookingId);
        System.assertEquals('NTE_Partner_Sponsor_Free_Confirmed',
            NTEExhibitorApprovalEmailService.selectedTemplateByOpportunityId.get(fixture.bookingId));
        System.assert(html.contains('Champion Partner'));
        System.assert(html.contains('partner-sponsor-staff-update.html'));
        System.assert(html.contains('No payment is due.'));
        System.assert(!html.contains('provisionally reserved'));
        System.assert(!html.contains('once payment has been received'));
        System.assert(!html.contains('buy.stripe.com'));
        Test.stopTest();
        assertHistory(fixture, true);
        System.assertEquals(0, [SELECT COUNT() FROM NTE_Payment_Request__c]);
    }

    @IsTest static void failedWaiverDeliveryDoesNotConfirmOrEraseEarlierHistory() {
        Fixture fixture = application('FAILED-SEND', false); waive(fixture);
        Test.startTest();
        NTEFinanceService.sendFinanceAction(fixture.bookingId, 'FREE');
        NTEExhibitorApprovalEmailService.simulateSendFailure = true;
        NTEExhibitorApprovalEmailService.processPendingBatch(state(fixture.bookingId).NTE_Approval_Email_Batch__c, true, false);
        NTEExhibitorApprovalEmailService.simulateSendFailure = false;
        Test.stopTest();
        assertHistory(fixture, false);
        System.assertEquals('Failed', state(fixture.bookingId).NTE_Approval_Email_Status__c);
        System.assertEquals(1, [SELECT COUNT() FROM Task WHERE WhatId = :fixture.bookingId AND Subject IN ('NTE booking provisional email - sent', 'NTE free-space confirmation email - sent')]);
        System.assertEquals(1, [SELECT COUNT() FROM Task WHERE WhatId = :fixture.bookingId AND Subject IN ('NTE booking provisional email - failed', 'NTE free-space confirmation email - failed')]);
    }

    @IsTest static void failedWaiverCanUseExistingRetryWithoutTouchingOriginalRequest() {
        Fixture fixture = application('RETRY', true); waive(fixture);
        Id paymentId = historicalRequest(fixture);
        update new Opportunity(Id = fixture.bookingId, NTE_Approval_Email_Status__c = 'Failed',
            NTE_Approval_Email_Kind__c = 'Free confirmation', NTE_Approval_Email_Error__c = 'The previous free confirmation was not accepted.');
        String beforeRequest = requestSnapshot(paymentId);
        Test.startTest();
        System.assertEquals(1, NTEExhibitorApprovalEmailService.retryApprovalEmail(fixture.bookingId).queuedCount);
        Test.stopTest();
        assertHistory(fixture, true);
        System.assertEquals('Sent', state(fixture.bookingId).NTE_Approval_Email_Status__c,
            'Saved error: ' + state(fixture.bookingId).NTE_Approval_Email_Error__c);
        System.assertEquals(beforeRequest, requestSnapshot(paymentId));
    }

    @IsTest static void acceptedFreeMarkerProtectsManualRetryAndLegacyQueueEntries() {
        Fixture fixture = application('CONFIRMED', false); waive(fixture);
        update new Opportunity(Id = fixture.bookingId, NTE_Free_Space_Confirmed__c = true);
        String before = JSON.serialize(state(fixture.bookingId));
        Test.startTest();
        assertFreeBlocked(fixture.bookingId);
        Boolean retryBlocked = false;
        try { NTEExhibitorApprovalEmailService.retryApprovalEmail(fixture.bookingId); }
        catch (AuraHandledException expected) { retryBlocked = true; }
        System.assert(retryBlocked);
        Boolean manualBlocked = false;
        try { NTEExhibitorApprovalEmailService.sendManually(fixture.bookingId); }
        catch (AuraHandledException expected) { manualBlocked = true; }
        System.assert(manualBlocked);
        NTEExhibitorApprovalEmailService.sendApprovalConfirmation(new List<NTEExhibitorApprovalEmailService.Request>{emailRequest(fixture)});
        System.assertEquals(0, Limits.getQueueableJobs());
        Test.stopTest();
        System.assertEquals(before, JSON.serialize(state(fixture.bookingId)));
        System.assertEquals(1, [SELECT COUNT() FROM Task WHERE WhatId = :fixture.bookingId]);
    }

    @IsTest static void earlierPaidOrQueuedConfirmationCannotBeRepeatedAsFree() {
        Fixture paid = application('PAID', false); waive(paid);
        Fixture sent = application('PAID-SENT', false); waive(sent);
        Fixture queued = application('PAID-QUEUED', false); waive(queued);
        update new Opportunity(Id = paid.bookingId, NTE_Payment_Received__c = true,
            NTE_Payment_Received_At__c = paid.priorSentAt, NTE_Approval_Email_Status__c = 'Failed');
        insert new List<NTE_Email_Dispatch__c>{
            new NTE_Email_Dispatch__c(Opportunity__c = sent.bookingId, Kind__c = 'BOOKING_CONFIRMED', Status__c = 'Sent',
                Dispatch_Key__c = 'WAIVER-PAID-SENT'),
            new NTE_Email_Dispatch__c(Opportunity__c = queued.bookingId, Kind__c = 'BOOKING_CONFIRMED', Status__c = 'Queued',
                Dispatch_Key__c = 'WAIVER-PAID-QUEUED')
        };
        Test.startTest();
        assertFreeBlocked(paid.bookingId); assertFreeBlocked(sent.bookingId); assertFreeBlocked(queued.bookingId);
        NTEExhibitorApprovalEmailService.sendApprovalConfirmation(new List<NTEExhibitorApprovalEmailService.Request>{
            emailRequest(paid), emailRequest(sent), emailRequest(queued)
        });
        System.assertEquals(0, Limits.getQueueableJobs());
        Test.stopTest();
        System.assertEquals(true, state(paid.bookingId).NTE_Payment_Received__c);
        System.assertEquals(paid.priorSentAt, state(paid.bookingId).NTE_Payment_Received_At__c);
        for (Fixture fixture : new List<Fixture>{paid, sent, queued}) {
            System.assertEquals(false, state(fixture.bookingId).NTE_Free_Space_Confirmed__c);
            System.assertEquals(fixture == paid ? 'Failed' : 'Sent', state(fixture.bookingId).NTE_Approval_Email_Status__c);
            System.assertEquals(fixture.priorSentAt, state(fixture.bookingId).NTE_Approval_Email_Sent_At__c);
        }
        System.assertEquals(2, [SELECT COUNT() FROM NTE_Email_Dispatch__c]);
    }

    @IsTest static void changedFreeOrPaidIntentFailsWithoutSendingOrChangingSavedStripeHistory() {
        Fixture free = application('BECOMES-PAID', false); waive(free);
        Fixture paid = application('BECOMES-FREE', true, false);
        Id paymentId = historicalRequest(free);
        String beforeRequest = requestSnapshot(paymentId);
        Test.startTest();
        NTEFinanceService.sendFinanceAction(free.bookingId, 'FREE');
        NTEFinanceService.sendFinanceAction(paid.bookingId, 'BANK');
        String batch = state(free.bookingId).NTE_Approval_Email_Batch__c;
        System.assertEquals(batch, state(paid.bookingId).NTE_Approval_Email_Batch__c);
        update new Opportunity(Id = free.bookingId, NTE_Price_Adjustment__c = 0,
            NTE_Listed_Price_Total__c = free.originalNet, Amount = free.originalGross, NTE_Payment_Method__c = 'Stripe');
        waive(paid);
        System.assertEquals(false, NTEStripeBookingService.prepareProvisionalBatch(batch, true, false));
        NTEExhibitorApprovalEmailService.processPendingBatch(batch, true, false);
        System.assertEquals(0, NTEExhibitorApprovalEmailService.acceptedDispatchCount);
        Test.stopTest();
        for (Fixture fixture : new List<Fixture>{free, paid}) {
            assertHistory(fixture, false);
            System.assertEquals('Failed', state(fixture.bookingId).NTE_Approval_Email_Status__c);
            System.assert(state(fixture.bookingId).NTE_Approval_Email_Error__c.contains('price changed'));
        }
        System.assertEquals(beforeRequest, requestSnapshot(paymentId));
        System.assertEquals(1, [SELECT COUNT() FROM NTE_Payment_Request__c]);
        System.assertEquals(1, [SELECT COUNT() FROM Task WHERE Subject IN ('NTE booking provisional email - sent', 'NTE free-space confirmation email - sent')],
            'Only the earlier provisional for the waiver fixture remains; neither changed request was sent.');
    }

    @IsTest static void positiveGrossWithRoundedZeroNetIsBankProvisionalForBothBookingTypes() {
        Fixture exhibitor = application('PENNY-EXHIBITOR', false, false);
        Fixture partner = application('PENNY-PARTNER', true, false);
        List<Fixture> fixtures = new List<Fixture>{exhibitor, partner};
        update new List<Opportunity>{
            new Opportunity(Id = exhibitor.bookingId, Amount = 0.01, NTE_VAT_Rate__c = 100),
            new Opportunity(Id = partner.bookingId, Amount = 0.01, NTE_VAT_Rate__c = 100)
        };
        for (Fixture fixture : fixtures) {
            Opportunity booking = state(fixture.bookingId);
            System.assertEquals(0, booking.NTE_Listed_Price_Total__c);
            System.assertEquals(-fixture.originalNet, booking.NTE_Price_Adjustment__c);
            System.assertEquals(0.01, booking.Amount);
            System.assertEquals(0.01, booking.NTE_VAT_Total__c);
            System.assertEquals('Yes', booking.NTE_Invoice_Required__c);
            System.assertEquals(booking.Amount, booking.NTE_Listed_Price_Total__c + booking.NTE_VAT_Total__c);
            System.assertEquals(0.01, NTEVat.bookingGross(booking.NTE_Listed_Price_Total__c, booking.NTE_VAT_Rate__c, booking.Amount));
            System.assertEquals(0.01, NTEVat.bookingTax(booking.NTE_Listed_Price_Total__c, booking.NTE_VAT_Rate__c, booking.Amount));
        }
        Test.startTest();
        for (Fixture fixture : fixtures) {
            Boolean freeBlocked = false;
            try { NTEFinanceService.sendFinanceAction(fixture.bookingId, 'FREE'); }
            catch (AuraHandledException expected) { freeBlocked = true; }
            System.assert(freeBlocked, 'A positive gross total must not offer a free confirmation.');
            System.assertEquals(1, NTEFinanceService.sendFinanceAction(fixture.bookingId, 'BANK').queuedCount);
            System.assertEquals('Provisional', state(fixture.bookingId).NTE_Approval_Email_Kind__c);
        }
        NTEExhibitorApprovalEmailService.processPendingBatch(state(exhibitor.bookingId).NTE_Approval_Email_Batch__c, true, false);
        for (Fixture fixture : fixtures) {
            System.assertEquals(fixture == exhibitor ? 'NTE_Exhibitor_Approved' : 'NTE_Partner_Sponsor_Approved',
                NTEExhibitorApprovalEmailService.selectedTemplateByOpportunityId.get(fixture.bookingId));
            String html = NTEExhibitorApprovalEmailService.htmlByOpportunityId.get(fixture.bookingId);
            System.assert(html.contains('provisionally reserved'));
            System.assert(html.contains('VAT (100%)'));
            System.assert(html.contains('£0.01'));
            System.assert(!html.contains('No payment is due.'));
            System.assertEquals(false, state(fixture.bookingId).NTE_Free_Space_Confirmed__c);
            System.assertEquals(false, state(fixture.bookingId).NTE_Payment_Received__c);
        }
        System.assertEquals(0, Limits.getEmailInvocations(), 'The regression renders with delivery bypassed.');
        Test.stopTest();
        for (Fixture fixture : fixtures) System.assertEquals('Sent', state(fixture.bookingId).NTE_Approval_Email_Status__c);
        System.assertEquals(0, [SELECT COUNT() FROM NTE_Payment_Request__c]);
    }
}
