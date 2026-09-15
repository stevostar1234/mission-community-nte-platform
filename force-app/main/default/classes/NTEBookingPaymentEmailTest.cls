@IsTest
private class NTEBookingPaymentEmailTest {
    private static final String EVENT_CODE = 'NTE2099';

    @TestSetup
    static void createData() {
        PermissionSet permissions = [SELECT Id FROM PermissionSet WHERE Name = 'NTE_Forms_Administration' LIMIT 1];
        if ([SELECT COUNT() FROM PermissionSetAssignment WHERE AssigneeId = :UserInfo.getUserId()
            AND PermissionSetId = :permissions.Id] == 0) {
            insert new PermissionSetAssignment(AssigneeId = UserInfo.getUserId(), PermissionSetId = permissions.Id);
        }
        System.runAs(new User(Id = UserInfo.getUserId())) {
            Account organisation = new Account(Name = 'Booking Confirmation <Organisation>');
            insert organisation;
            Id recordTypeId = [SELECT Id FROM RecordType WHERE SobjectType = 'Opportunity'
                AND DeveloperName = 'NTE_Event_Opportunity' LIMIT 1].Id;
            String stage = [SELECT MasterLabel FROM OpportunityStage WHERE IsActive = true AND IsClosed = false
                ORDER BY SortOrder LIMIT 1].MasterLabel;
            List<Opportunity> bookings = new List<Opportunity>();
            for (String name : new List<String>{'EXHIBITOR', 'PARTNER', 'UNRELATED', 'COMPLIMENTARY', 'NO-CONTACT'}) {
                Boolean partner = name == 'PARTNER';
                Boolean free = name == 'COMPLIMENTARY';
                Decimal price = free ? 0 : partner ? 2000 : 800;
                bookings.add(new Opportunity(Name = 'PAYMENT-EMAIL-' + name, AccountId = organisation.Id,
                    RecordTypeId = recordTypeId, StageName = stage, CloseDate = Date.today().addDays(30),
                    Booking_Reference__c = 'NTE-PAYMENT-' + name, NTE_Event_Code__c = EVENT_CODE,
                    NTE_Source_Form_Type__c = partner ? 'Partner / Sponsor Application' : 'Exhibitor Application',
                    NTE_Exhibitor_Space_Selections__c = partner ? null : free ? 'COBSEO Charity - Single - Free' : 'Single Garage - Track Side - £799 + VAT',
                    NTE_Exhibitor_Organisation_Category__c = free ? 'Charity - member of Cobseo' : 'CIC or Not for Profit',
                    NTE_Sponsor_Package__c = partner ? 'Champion Partner' : null,
                    NTE_Exhibitor_Space_Price__c = partner ? 0 : price, NTE_Sponsor_Package_Total__c = partner ? price : 0,
                    Amount = price * 1.2, NTE_Listed_Price_Total__c = price, NTE_Pricing_Status__c = 'Calculated',
                    NTE_Invoice_Required__c = free ? 'No' : 'Yes', NTE_Invoice_Provided__c = !free,
                    NTE_Quote_Required_for_PO__c = 'No', NTE_Payment_Method__c = 'Bank transfer',
                    NTE_Heavy_Vehicle_Required__c = 'Yes', NTE_Initial_Staff_Count__c = 2,
                    NTE_Total_Staff_Count__c = 2, NTE_Included_Staff_Count__c = 2,
                    NTE_Event_Contact_Name__c = 'Different Event-Day Contact', NTE_Event_Contact_Email__c = 'event-day@example.invalid'));
            }
            insert bookings;
            List<Contact> contacts = new List<Contact>();
            for (Integer index = 0; index < 4; index++) contacts.add(new Contact(AccountId = organisation.Id,
                FirstName = 'Primary', LastName = 'Payment ' + index, Email = 'payment-primary-' + index + '@example.invalid'));
            insert contacts;
            List<OpportunityContactRole> roles = new List<OpportunityContactRole>();
            for (Integer index = 0; index < 4; index++) roles.add(new OpportunityContactRole(
                OpportunityId = bookings[index].Id, ContactId = contacts[index].Id, IsPrimary = true));
            insert roles;
        }
    }

    private static void configure() {
        NTEInboundLeadService.bypassEmailDelivery = true;
        NTEEmailDispatchService.skipEnqueue = true;
        NTEEmailDispatchService.bypassEmailDelivery = true;
        NTEEmailDispatchService.routingOverride = new NTE_Routing_Config__mdt(
            Exhibitor_Staff_Form_URL__c = 'https://forms.example.invalid/exhibitor-staff',
            Partner_Staff_Form_URL__c = 'https://forms.example.invalid/partner-staff',
            Heavy_Vehicle_Form_URL__c = 'https://forms.example.invalid/logistics',
            Logo_Update_Form_URL__c = 'https://forms.example.invalid/logo'
        );
    }

    @IsTest
    static void bookingPaymentConfirmsEachExactPrimaryAndParticipantTemplateOnce() {
        configure();
        Id exhibitor = bookingId('EXHIBITOR'); Id partner = bookingId('PARTNER'); Id unrelated = bookingId('UNRELATED');
        Test.startTest();
        NTE_MasterPanelController.ActionResult first = NTE_MasterPanelController.updateMilestone(exhibitor, 'PAYMENT_RECEIVED');
        NTE_MasterPanelController.ActionResult second = NTE_MasterPanelController.updateMilestone(partner, 'PAYMENT_RECEIVED');
        update new Opportunity(Id = unrelated, Description = 'Most recently modified booking; never selected for payment.');
        System.assertEquals(0, Limits.getEmailInvocations());
        List<Id> ids = new List<Id>{dispatchFor(exhibitor).Id, dispatchFor(partner).Id};
        NTEEmailDispatchService.processQueued(ids, true);
        NTEEmailDispatchService.processQueued(ids, true);
        System.assertEquals(0, NTEEmailDispatchService.queueBookingConfirmation(exhibitor).queuedCount);
        Test.stopTest();
        System.assert(first.success && second.success);
        System.assertEquals('Sent', dispatchFor(exhibitor).Status__c);
        System.assertEquals('payment-primary-0@example.invalid', dispatchFor(exhibitor).Recipient__c);
        System.assertEquals('Sent', dispatchFor(partner).Status__c);
        System.assertEquals('payment-primary-1@example.invalid', dispatchFor(partner).Recipient__c);
        System.assertEquals(0, dispatchCount(unrelated));
        String exhibitorHtml = NTEEmailDispatchService.renderedHtml.get(exhibitor);
        String partnerHtml = NTEEmailDispatchService.renderedHtml.get(partner);
        System.assert(exhibitorHtml.contains('NTE-PAYMENT-EXHIBITOR'));
        System.assert(exhibitorHtml.contains('exhibitor-staff'));
        System.assert(!exhibitorHtml.contains('partner-staff'));
        System.assert(partnerHtml.contains('NTE-PAYMENT-PARTNER'));
        System.assert(partnerHtml.contains('partner-staff'));
        System.assert(!partnerHtml.contains('exhibitor-staff'));
        assertPaidPresentation(exhibitorHtml, false);
        assertPaidPresentation(partnerHtml, true);
        System.assert(NTEExhibitorApprovalEmailService.plainTextFromHtml(exhibitorHtml).contains('Total paid (inc VAT)'));
        System.assert(NTEExhibitorApprovalEmailService.plainTextFromHtml(partnerHtml).contains('Total paid (inc VAT)'));
        System.assert(exhibitorHtml.contains('action-column') && partnerHtml.contains('action-column'));
        System.assert(!exhibitorHtml.contains('event-day@example.invalid'));
        System.assert(partnerHtml.contains('Event contact') && partnerHtml.contains('Different Event-Day Contact')
            && partnerHtml.contains('event-day@example.invalid'), 'Event-day details remain labelled booking information; the dispatch recipient must remain the primary Contact.');
        System.assert(partnerHtml.contains('Primary contact') && partnerHtml.contains('payment-primary-1@example.invalid'));
        System.assert(!exhibitorHtml.contains('{NTE_') && !partnerHtml.contains('{NTE_'));
    }

    @IsTest
    static void stripeConfirmationsShowCurrentPaidTotalsWithoutAnotherPaymentRequest() {
        configure();
        List<Id> bookingIds = new List<Id>{bookingId('EXHIBITOR'), bookingId('PARTNER')};
        List<NTE_Payment_Request__c> payments = new List<NTE_Payment_Request__c>();
        for (Integer i = 0; i < bookingIds.size(); i++) {
            Decimal net = i == 0 ? 80000 : 200000;
            payments.add(new NTE_Payment_Request__c(Opportunity__c = bookingIds[i],
                Charge_Key__c = 'PAID-PRESENTATION-' + bookingIds[i], Kind__c = 'Booking', Status__c = 'Ready',
                Net_Minor__c = net, Amount_Minor__c = net * 1.2, Tax_Rate__c = 20, Currency__c = 'gbp'));
            update new Opportunity(Id = bookingIds[i], NTE_Payment_Method__c = 'Stripe');
        }
        insert payments;
        Test.startTest();
        List<Id> dispatchIds = new List<Id>();
        for (Id selected : bookingIds) {
            System.assert(NTE_MasterPanelController.updateMilestone(selected, 'PAYMENT_RECEIVED').success);
            dispatchIds.add(dispatchFor(selected).Id);
        }
        NTEEmailDispatchService.processQueued(dispatchIds, true);
        Test.stopTest();
        for (Integer i = 0; i < bookingIds.size(); i++) {
            System.assertEquals('Sent', dispatchFor(bookingIds[i]).Status__c);
            String html = NTEEmailDispatchService.renderedHtml.get(bookingIds[i]);
            assertPaidPresentation(html, i == 1);
            String text = NTEExhibitorApprovalEmailService.plainTextFromHtml(html);
            System.assert(text.contains(i == 0 ? '£960.00' : '£2400.00'));
            System.assert(text.contains(i == 0 ? '£160.00' : '£400.00'));
            System.assert(text.contains('Total paid') && !text.contains('Total payable'));
            System.assertEquals(1, dispatchCount(bookingIds[i]));
        }
    }

    @IsTest
    static void repricedStripeExhibitorConfirmsCurrentChargesAndPreservesIssuedLink() {
        configure(); Id selected = bookingId('EXHIBITOR');
        NTE_Payment_Request__c issued = savedRequest(selected, 'Booking', 960, System.now().addDays(-1), 'reconciled-increase');
        String history = requestHistory(issued.Id);
        update new Opportunity(Id = selected, NTE_Payment_Method__c = 'Stripe',
            Amount = 1080.01);
        Test.startTest();
        NTE_MasterPanelController.PaymentReceiptPreview preview = NTE_MasterPanelController.getPaymentReceiptPreview(selected, 'PAYMENT_RECEIVED');
        System.assertEquals(1080.01, preview.amount); System.assertEquals(960, preview.issuedStripeAmount);
        System.assert(preview.stripeAmountDiffers);
        System.assert(NTE_MasterPanelController.recordReviewedPayment(selected, 'PAYMENT_RECEIVED', preview.amount).success);
        NTEEmailDispatchService.processQueued(new List<Id>{dispatchFor(selected).Id}, true);
        Test.stopTest();
        System.assertEquals('Sent', dispatchFor(selected).Status__c);
        String html = NTEEmailDispatchService.renderedHtml.get(selected);
        assertPaidPresentation(html, false);
        String text = NTEExhibitorApprovalEmailService.plainTextFromHtml(html);
        System.assert(text.contains('Booking adjustment') && text.contains('£100.01') && text.contains('£800.00'));
        System.assert(text.contains('£900.01') && text.contains('£180.00') && text.contains('£1080.01'));
        System.assert(!text.contains('£960.00'), 'The earlier Stripe price is history, not the reconciled paid total.');
        System.assertEquals(history, requestHistory(issued.Id));
        System.assertEquals(1, dispatchCount(selected));
        System.assertEquals(1, [SELECT COUNT() FROM NTE_Payment_Request__c WHERE Opportunity__c = :selected]);
        System.assertEquals(0, Limits.getCallouts(), 'Manual confirmation must not modify or depend on Stripe.');
    }

    @IsTest
    static void reducedStripePartnerConfirmsCurrentChargesAndPreservesIssuedLink() {
        configure(); Id selected = bookingId('PARTNER');
        NTE_Payment_Request__c issued = savedRequest(selected, 'Booking', 2400, System.now().addDays(-1), 'reconciled-reduction');
        String history = requestHistory(issued.Id);
        update new Opportunity(Id = selected, NTE_Payment_Method__c = 'Stripe',
            Amount = 1800);
        Test.startTest();
        System.assert(NTE_MasterPanelController.updateMilestone(selected, 'PAYMENT_RECEIVED').success);
        NTEEmailDispatchService.processQueued(new List<Id>{dispatchFor(selected).Id}, true);
        Test.stopTest();
        System.assertEquals('Sent', dispatchFor(selected).Status__c);
        String html = NTEEmailDispatchService.renderedHtml.get(selected);
        assertPaidPresentation(html, true);
        String text = NTEExhibitorApprovalEmailService.plainTextFromHtml(html);
        System.assert(text.contains('Booking adjustment') && text.contains('-£500.00') && text.contains('£2000.00'));
        System.assert(text.contains('£1500.00') && text.contains('£300.00') && text.contains('£1800.00'));
        System.assert(!text.contains('£2400.00'));
        System.assertEquals(history, requestHistory(issued.Id), 'Any refund is reconciled by the team, never by the confirmation action.');
        System.assertEquals(1, dispatchCount(selected));
        System.assertEquals(1, [SELECT COUNT() FROM NTE_Payment_Request__c WHERE Opportunity__c = :selected]);
        System.assertEquals(0, Limits.getCallouts());
    }

    private static void assertPaidPresentation(String html, Boolean partner) {
        System.assert(html.contains('Thank you for your booking payment.'));
        System.assert(!html.contains('Booking payment received'), 'The repeated paid-status box was removed by the owner.');
        System.assert(!html.contains('Total payable') && !html.contains('Pay Now') && !html.contains('buy.stripe.com'));
        Integer preparation = html.indexOf('Staff details and event preparation');
        Integer charges = html.indexOf('Your booking charges');
        Integer details = html.indexOf(partner ? 'Organisation and contact' : 'Your confirmed booking');
        System.assert(preparation >= 0 && preparation < charges && charges < details, 'Preparation, charges and booking details must follow the approved order.');
    }

    @IsTest
    static void staffTopUpNeverRepeatsTheBookingConfirmation() {
        configure(); Id selected = bookingId('EXHIBITOR');
        update new Opportunity(Id = selected, NTE_Top_Up_Invoice_Required__c = true,
            NTE_Top_Up_Staff_Total__c = 100, NTE_Top_Up_Invoice_Provided__c = true);
        Test.startTest();
        NTE_MasterPanelController.updateMilestone(selected, 'PAYMENT_RECEIVED');
        NTE_Email_Dispatch__c dispatch = dispatchFor(selected);
        NTEEmailDispatchService.processQueued(new List<Id>{dispatch.Id}, true);
        Datetime sentAt = dispatchFor(selected).Sent_At__c;
        NTE_MasterPanelController.updateMilestone(selected, 'TOP_UP_PAYMENT_RECEIVED');
        Test.stopTest();
        System.assertEquals(1, dispatchCount(selected));
        System.assertEquals(sentAt, dispatchFor(selected).Sent_At__c);
        Opportunity booked = [SELECT NTE_Payment_Received__c, NTE_Top_Up_Payment_Received__c FROM Opportunity WHERE Id = :selected];
        System.assert(booked.NTE_Payment_Received__c && booked.NTE_Top_Up_Payment_Received__c);
    }

    @IsTest
    static void failedProvisionalDoesNotDelayRecordedPaymentConfirmation() {
        configure(); Id selected = bookingId('EXHIBITOR');
        update new Opportunity(Id = selected, NTE_Approval_Email_Status__c = 'Failed',
            NTE_Approval_Email_Error__c = 'The previous email was not accepted.');
        Test.startTest();
        NTE_MasterPanelController.ActionResult saved = NTE_MasterPanelController.updateMilestone(selected, 'PAYMENT_RECEIVED');
        NTE_Email_Dispatch__c dispatch = dispatchFor(selected);
        System.assertEquals('Queued', dispatch.Status__c,
            'The owner approved immediate confirmation when payment is recorded even if the provisional email failed.');
        NTEEmailDispatchService.processQueued(new List<Id>{dispatch.Id}, true);
        Boolean repeatedClickRejected = false;
        try { NTE_MasterPanelController.updateMilestone(selected, 'PAYMENT_RECEIVED'); }
        catch (AuraHandledException expected) { repeatedClickRejected = true; }
        Test.stopTest();
        System.assert(saved.success);
        System.assert(repeatedClickRejected);
        System.assertEquals('Sent', dispatchFor(selected).Status__c);
        System.assertEquals(1, dispatchCount(selected));
        Opportunity booking = [SELECT NTE_Payment_Received__c, NTE_Approval_Email_Status__c, NTE_Approval_Email_Error__c
            FROM Opportunity WHERE Id = :selected];
        System.assertEquals(true, booking.NTE_Payment_Received__c);
        System.assertEquals('Failed', booking.NTE_Approval_Email_Status__c);
        System.assertEquals('The previous email was not accepted.', booking.NTE_Approval_Email_Error__c);
    }

    @IsTest
    static void unusablePreparationReferenceKeepsPaymentAndARecoverableConfirmation() {
        configure(); Id selected = bookingId('EXHIBITOR');
        update new Opportunity(Id = selected, Booking_Reference__c = 'BOOKING-001');
        Test.startTest();
        NTE_MasterPanelController.ActionResult saved = NTE_MasterPanelController.updateMilestone(selected, 'PAYMENT_RECEIVED');
        NTE_Email_Dispatch__c failed = dispatchFor(selected);
        System.assert(saved.success);
        System.assertEquals('Failed', failed.Status__c);
        System.assert(failed.Error__c.contains('booking reference'));
        System.assertEquals(true, [SELECT NTE_Payment_Received__c FROM Opportunity WHERE Id = :selected].NTE_Payment_Received__c);
        System.assertEquals('BOOKING-001', [SELECT Booking_Reference__c FROM Opportunity WHERE Id = :selected].Booking_Reference__c);
        update new Opportunity(Id = selected, Booking_Reference__c = 'NTE-REFERENCE-REPAIRED');
        System.assertEquals(1, NTEEmailDispatchService.retryDispatch(failed.Id).queuedCount);
        NTEEmailDispatchService.processQueued(new List<Id>{failed.Id}, true);
        Test.stopTest();
        System.assertEquals('Sent', dispatchFor(selected).Status__c);
        System.assertEquals(failed.Id, dispatchFor(selected).Id);
        System.assertEquals(1, dispatchCount(selected));
    }

    @IsTest
    static void inconsistentItemisationCannotBeSentAsAPaidConfirmation() {
        configure(); Id selected = bookingId('PARTNER');
        update new Opportunity(Id = selected, NTE_Additional_Staff_Count__c = '2', NTE_Additional_Staff_Unit_Price__c = 50,
            NTE_Additional_Staff_Total__c = 50, NTE_Listed_Price_Total__c = 2050, Amount = 2460,
            NTE_Payment_Received__c = true);
        Test.startTest();
        NTEEmailDispatchService.queueBookingConfirmation(selected);
        NTE_Email_Dispatch__c dispatch = dispatchFor(selected);
        Test.stopTest();
        System.assertEquals('Failed', dispatch.Status__c);
        System.assert(dispatch.Error__c.contains('price needs review'));
        System.assertEquals(null, dispatch.Sent_At__c);
        System.assertEquals(true, [SELECT NTE_Payment_Received__c FROM Opportunity WHERE Id = :selected].NTE_Payment_Received__c);
        System.assertEquals(2460, [SELECT Amount FROM Opportunity WHERE Id = :selected].Amount);
    }

    @IsTest
    static void complimentaryTopUpPaymentDoesNotCreateABookingEmail() {
        configure(); Id selected = bookingId('COMPLIMENTARY');
        update new Opportunity(Id = selected, NTE_Top_Up_Invoice_Required__c = true,
            NTE_Top_Up_Staff_Total__c = 100, NTE_Top_Up_Invoice_Provided__c = true);
        Test.startTest();
        NTE_MasterPanelController.updateMilestone(selected, 'TOP_UP_PAYMENT_RECEIVED');
        Test.stopTest();
        System.assertEquals(0, dispatchCount(selected));
        System.assertEquals(false, [SELECT NTE_Payment_Received__c FROM Opportunity WHERE Id = :selected].NTE_Payment_Received__c);
    }

    @IsTest
    static void missingPrimaryKeepsPaymentAndFailedRequestThenRetriesAfterRepair() {
        configure(); Id selected = bookingId('NO-CONTACT');
        Test.startTest();
        NTE_MasterPanelController.ActionResult saved = NTE_MasterPanelController.updateMilestone(selected, 'PAYMENT_RECEIVED');
        NTE_Email_Dispatch__c failed = dispatchFor(selected);
        System.assert(saved.success);
        System.assert(saved.message.contains('Booking payment recorded'));
        System.assertEquals('Failed', failed.Status__c);
        System.assert(failed.Error__c.contains('primary Contact'));
        Contact primary = [SELECT Id FROM Contact WHERE Email = 'payment-primary-0@example.invalid' LIMIT 1];
        insert new OpportunityContactRole(OpportunityId = selected, ContactId = primary.Id, IsPrimary = true);
        System.assertEquals(1, NTEEmailDispatchService.retryDispatch(failed.Id).queuedCount);
        NTEEmailDispatchService.processQueued(new List<Id>{failed.Id}, true);
        Test.stopTest();
        System.assertEquals(true, [SELECT NTE_Payment_Received__c FROM Opportunity WHERE Id = :selected].NTE_Payment_Received__c);
        System.assertEquals('Sent', dispatchFor(selected).Status__c);
        System.assertEquals(failed.Id, dispatchFor(selected).Id);
        System.assertEquals('payment-primary-0@example.invalid', dispatchFor(selected).Recipient__c);
    }

    @IsTest
    static void sendFailureKeepsPaymentAndRetryUsesTheSameDispatchOnlyOnce() {
        configure(); Id selected = bookingId('EXHIBITOR');
        Test.startTest();
        NTE_MasterPanelController.updateMilestone(selected, 'PAYMENT_RECEIVED');
        NTE_Email_Dispatch__c dispatch = dispatchFor(selected);
        NTEEmailDispatchService.simulatedFailures.add(selected);
        NTEEmailDispatchService.processQueued(new List<Id>{dispatch.Id}, true);
        System.assertEquals('Failed', dispatchFor(selected).Status__c);
        System.assertEquals(true, [SELECT NTE_Payment_Received__c FROM Opportunity WHERE Id = :selected].NTE_Payment_Received__c);
        NTEEmailDispatchService.simulatedFailures.clear();
        System.assertEquals(1, NTEEmailDispatchService.retryDispatch(dispatch.Id).queuedCount);
        NTEEmailDispatchService.processQueued(new List<Id>{dispatch.Id}, true);
        System.assertEquals(0, NTEEmailDispatchService.retryDispatch(dispatch.Id).queuedCount);
        Test.stopTest();
        System.assertEquals('Sent', dispatchFor(selected).Status__c);
        System.assertEquals(1, dispatchCount(selected));
    }

    @IsTest
    static void missingTemplateIsRetryableWithoutChangingPayment() {
        configure(); Id selected = bookingId('PARTNER');
        Test.startTest();
        NTE_MasterPanelController.updateMilestone(selected, 'PAYMENT_RECEIVED');
        NTE_Email_Dispatch__c dispatch = dispatchFor(selected);
        NTEEmailDispatchService.confirmationTemplateOverride = new Map<String, Id>();
        NTEEmailDispatchService.processQueued(new List<Id>{dispatch.Id}, true);
        System.assertEquals('Failed', dispatchFor(selected).Status__c);
        System.assert(dispatchFor(selected).Error__c.contains('template is missing'));
        NTEEmailDispatchService.confirmationTemplateOverride = null;
        System.assertEquals(1, NTEEmailDispatchService.retryDispatch(dispatch.Id).queuedCount);
        NTEEmailDispatchService.processQueued(new List<Id>{dispatch.Id}, true);
        Test.stopTest();
        System.assertEquals('Sent', dispatchFor(selected).Status__c);
        System.assertEquals(true, [SELECT NTE_Payment_Received__c FROM Opportunity WHERE Id = :selected].NTE_Payment_Received__c);
    }

    @IsTest
    static void changedPrimaryNeverReceivesAnOldQueuedSnapshot() {
        configure(); Id selected = bookingId('EXHIBITOR');
        Test.startTest();
        NTE_MasterPanelController.updateMilestone(selected, 'PAYMENT_RECEIVED');
        NTE_Email_Dispatch__c dispatch = dispatchFor(selected);
        update new Contact(Id = dispatch.Contact__c, Email = 'new-approved-primary@example.invalid');
        NTEEmailDispatchService.processQueued(new List<Id>{dispatch.Id}, true);
        System.assertEquals('Failed', dispatchFor(selected).Status__c);
        System.assertEquals(null, dispatchFor(selected).Sent_At__c);
        System.assert(!NTEEmailDispatchService.renderedHtml.containsKey(selected));
        System.assertEquals(1, NTEEmailDispatchService.retryDispatch(dispatch.Id).queuedCount);
        NTEEmailDispatchService.processQueued(new List<Id>{dispatch.Id}, true);
        Test.stopTest();
        System.assertEquals('Sent', dispatchFor(selected).Status__c);
        System.assertEquals('new-approved-primary@example.invalid', dispatchFor(selected).Recipient__c);
        System.assertEquals(1, dispatchCount(selected));
    }

    @IsTest
    static void changedBookedAmountLeavesThePaymentConfirmationUnsent() {
        configure(); Id selected = bookingId('EXHIBITOR');
        Test.startTest();
        NTE_MasterPanelController.updateMilestone(selected, 'PAYMENT_RECEIVED');
        NTE_Email_Dispatch__c dispatch = dispatchFor(selected);
        update new Opportunity(Id = selected, Amount = 1080, NTE_Listed_Price_Total__c = 900, NTE_Exhibitor_Space_Price__c = 900);
        NTEEmailDispatchService.processQueued(new List<Id>{dispatch.Id}, true);
        Test.stopTest();
        System.assertEquals('Failed', dispatchFor(selected).Status__c);
        System.assertEquals(null, dispatchFor(selected).Sent_At__c);
        System.assertEquals(true, [SELECT NTE_Payment_Received__c FROM Opportunity WHERE Id = :selected].NTE_Payment_Received__c);
    }

    @IsTest
    static void paidConfirmationCannotBeSentThroughTheEditableMassDraft() {
        configure(); Boolean rejected = false;
        try { NTEEmailDispatchService.buildDraft('BOOKING_CONFIRMED', new List<Id>{bookingId('EXHIBITOR')}); }
        catch (AuraHandledException expected) { rejected = true; }
        System.assert(rejected, 'Only recording booking payment can create the automatic confirmation.');
        System.assertEquals(0, [SELECT COUNT() FROM NTE_Email_Dispatch__c]);
    }

    @IsTest
    static void milestoneQueuesAnAfterCommitWorker() {
        configure(); NTEEmailDispatchService.skipEnqueue = false; Id selected = bookingId('PARTNER');
        Test.startTest();
        NTE_MasterPanelController.updateMilestone(selected, 'PAYMENT_RECEIVED');
        System.assertEquals(1, Limits.getQueueableJobs());
        System.assertEquals(0, Limits.getEmailInvocations());
        System.assertEquals('Queued', dispatchFor(selected).Status__c);
        Test.stopTest();
        System.assertEquals('Sent', dispatchFor(selected).Status__c, 'Confirmation error: ' + dispatchFor(selected).Error__c);
    }

    @IsTest
    static void receiptPreviewSeparatesBaseAndTopUpWithoutWriting() {
        configure(); Id selected = bookingId('EXHIBITOR');
        update new Opportunity(Id = selected, NTE_Top_Up_Staff_Total__c = 150.01, NTE_Top_Up_VAT_Rate__c = 5);
        Test.startTest();
        Integer writes = Limits.getDmlStatements();
        NTE_MasterPanelController.PaymentReceiptPreview base = NTE_MasterPanelController.getPaymentReceiptPreview(selected, 'PAYMENT_RECEIVED');
        NTE_MasterPanelController.PaymentReceiptPreview topUp = NTE_MasterPanelController.getPaymentReceiptPreview(selected, 'TOP_UP_PAYMENT_RECEIVED');
        System.assertEquals(writes, Limits.getDmlStatements(), 'Opening receipt review must not write or send anything.');
        System.assertEquals(0, Limits.getQueueableJobs()); System.assertEquals(0, Limits.getEmailInvocations());
        Test.stopTest();
        System.assertEquals(960, base.amount); System.assertEquals(157.51, topUp.amount, 'Use this charge\'s saved VAT rate and currency rounding.');
        System.assertEquals(null, base.issuedStripeAmount); System.assertEquals(null, topUp.issuedStripeAmount);
        System.assertEquals(false, base.stripeAmountDiffers); System.assertEquals(false, topUp.stripeAmountDiffers);
        System.assertEquals(0, dispatchCount(selected));
        Opportunity booking = [SELECT NTE_Payment_Received__c, NTE_Top_Up_Payment_Received__c FROM Opportunity WHERE Id = :selected];
        System.assert(!booking.NTE_Payment_Received__c && !booking.NTE_Top_Up_Payment_Received__c);
    }

    @IsTest
    static void receiptPreviewUsesLatestIssuedRequestForTheSelectedCharge() {
        configure(); Id selected = bookingId('EXHIBITOR');
        update new Opportunity(Id = selected, NTE_Top_Up_Staff_Total__c = 150, NTE_Top_Up_VAT_Rate__c = 20);
        Datetime issuedAt = System.now().addDays(-1);
        savedRequest(selected, 'Booking', 960, issuedAt.addDays(-1), 'older');
        NTE_Payment_Request__c latest = savedRequest(selected, 'Booking', 840, issuedAt, 'latest');
        update new NTE_Payment_Request__c(Id = latest.Id, Status__c = 'Needs review');
        savedRequest(selected, 'Booking', 960, null, 'unsent');
        savedRequest(selected, 'Staff top-up', 180, issuedAt, 'top-up');
        savedRequest(selected, 'Staff top-up', 120, null, 'top-up-unsent');
        savedRequest(bookingId('UNRELATED'), 'Booking', 120, System.now(), 'other-booking');
        Test.startTest();
        NTE_MasterPanelController.PaymentReceiptPreview base = NTE_MasterPanelController.getPaymentReceiptPreview(selected, 'PAYMENT_RECEIVED');
        NTE_MasterPanelController.PaymentReceiptPreview topUp = NTE_MasterPanelController.getPaymentReceiptPreview(selected, 'TOP_UP_PAYMENT_RECEIVED');
        System.assertEquals(960, base.amount); System.assertEquals(840, base.issuedStripeAmount);
        System.assertEquals(true, base.stripeAmountDiffers, 'A retry status must not hide the previously issued amount.');
        System.assertEquals(180, topUp.amount); System.assertEquals(180, topUp.issuedStripeAmount);
        System.assertEquals(false, topUp.stripeAmountDiffers);
        update new Opportunity(Id = selected, Amount = 840, NTE_Listed_Price_Total__c = 700,
            NTE_Exhibitor_Space_Price__c = 700, NTE_Top_Up_Staff_Total__c = 200);
        base = NTE_MasterPanelController.getPaymentReceiptPreview(selected, 'PAYMENT_RECEIVED');
        topUp = NTE_MasterPanelController.getPaymentReceiptPreview(selected, 'TOP_UP_PAYMENT_RECEIVED');
        Test.stopTest();
        System.assertEquals(840, base.amount); System.assertEquals(false, base.stripeAmountDiffers);
        System.assertEquals(240, topUp.amount); System.assertEquals(180, topUp.issuedStripeAmount);
        System.assertEquals(true, topUp.stripeAmountDiffers);
        System.assertEquals(0, dispatchCount(selected));
    }

    @IsTest
    static void reviewedBaseReceiptAllowsReconciledTransferAfterFailedProvisional() {
        configure(); Id selected = bookingId('EXHIBITOR');
        update new Opportunity(Id = selected, NTE_Payment_Method__c = 'Bank transfer', NTE_Invoice_Provided__c = false,
            NTE_Approval_Email_Status__c = 'Failed', NTE_Approval_Email_Error__c = 'The previous email was not accepted.');
        NTE_Payment_Request__c issued = savedRequest(selected, 'Booking', 840, System.now().addDays(-1), 'manual-base');
        String history = requestHistory(issued.Id);
        Test.startTest();
        NTE_MasterPanelController.PaymentReceiptPreview preview = NTE_MasterPanelController.getPaymentReceiptPreview(selected, 'PAYMENT_RECEIVED');
        System.assertEquals(960, preview.amount); System.assertEquals(840, preview.issuedStripeAmount);
        System.assertEquals(true, preview.stripeAmountDiffers);
        System.assert(NTE_MasterPanelController.recordReviewedPayment(selected, 'PAYMENT_RECEIVED', preview.amount).success);
        NTEEmailDispatchService.processQueued(new List<Id>{dispatchFor(selected).Id}, true);
        Test.stopTest();
        Opportunity booking = [SELECT NTE_Payment_Received__c, NTE_Invoice_Provided__c, NTE_Approval_Email_Status__c,
            NTE_Approval_Email_Error__c, NTE_Approval_Email_Sent_At__c FROM Opportunity WHERE Id = :selected];
        System.assertEquals(true, booking.NTE_Payment_Received__c);
        System.assertEquals(false, booking.NTE_Invoice_Provided__c);
        System.assertEquals('Failed', booking.NTE_Approval_Email_Status__c);
        System.assertEquals('The previous email was not accepted.', booking.NTE_Approval_Email_Error__c);
        System.assertEquals(null, booking.NTE_Approval_Email_Sent_At__c);
        System.assertEquals(1, dispatchCount(selected));
        System.assertEquals('Sent', dispatchFor(selected).Status__c, 'An earlier Stripe amount must not block a reconciled bank-transfer confirmation.');
        String confirmation = NTEExhibitorApprovalEmailService.plainTextFromHtml(NTEEmailDispatchService.renderedHtml.get(selected));
        System.assert(confirmation.contains('£960.00') && confirmation.contains('£160.00'));
        System.assert(!confirmation.contains('£840.00') && !confirmation.contains('Pay Now'));
        System.assertEquals(history, requestHistory(issued.Id), 'Manual reconciliation must retain the issued Stripe request.');
    }

    @IsTest
    static void reviewedTopUpReceiptPreservesBaseConfirmationAndRequestHistory() {
        configure(); Id selected = bookingId('EXHIBITOR');
        NTE_MasterPanelController.updateMilestone(selected, 'PAYMENT_RECEIVED');
        NTEEmailDispatchService.processQueued(new List<Id>{dispatchFor(selected).Id}, true);
        Datetime confirmationAt = dispatchFor(selected).Sent_At__c;
        Datetime paidAt = [SELECT NTE_Payment_Received_At__c FROM Opportunity WHERE Id = :selected].NTE_Payment_Received_At__c;
        update new Opportunity(Id = selected, NTE_Top_Up_Staff_Total__c = 150, NTE_Top_Up_VAT_Rate__c = 20);
        NTE_Payment_Request__c issued = savedRequest(selected, 'Staff top-up', 120, System.now().addDays(-1), 'manual-top-up');
        String history = requestHistory(issued.Id);
        Test.startTest();
        NTE_MasterPanelController.PaymentReceiptPreview preview = NTE_MasterPanelController.getPaymentReceiptPreview(selected, 'TOP_UP_PAYMENT_RECEIVED');
        System.assertEquals(180, preview.amount); System.assertEquals(120, preview.issuedStripeAmount);
        System.assertEquals(true, preview.stripeAmountDiffers);
        System.assert(NTE_MasterPanelController.recordReviewedPayment(selected, 'TOP_UP_PAYMENT_RECEIVED', preview.amount).success);
        Test.stopTest();
        Opportunity booking = [SELECT NTE_Payment_Received__c, NTE_Payment_Received_At__c, NTE_Top_Up_Payment_Received__c,
            NTE_Top_Up_Payment_At__c, NTE_Top_Up_Payment_Requested_At__c FROM Opportunity WHERE Id = :selected];
        System.assert(booking.NTE_Payment_Received__c && booking.NTE_Top_Up_Payment_Received__c);
        System.assertEquals(paidAt, booking.NTE_Payment_Received_At__c);
        System.assertNotEquals(null, booking.NTE_Top_Up_Payment_At__c);
        System.assertEquals(null, booking.NTE_Top_Up_Payment_Requested_At__c, 'Receipt does not require a successful earlier request.');
        System.assertEquals('Sent', dispatchFor(selected).Status__c);
        System.assertEquals(confirmationAt, dispatchFor(selected).Sent_At__c);
        System.assertEquals(1, dispatchCount(selected));
        System.assertEquals(history, requestHistory(issued.Id));
    }

    @IsTest
    static void reviewedReceiptRejectsStaleCurrentAmountsBeforeWriting() {
        configure();
        Test.startTest();
        for (String action : new List<String>{'PAYMENT_RECEIVED', 'TOP_UP_PAYMENT_RECEIVED'}) {
            Boolean base = action == 'PAYMENT_RECEIVED';
            Id selected = bookingId(base ? 'EXHIBITOR' : 'PARTNER');
            if (!base) update new Opportunity(Id = selected, NTE_Top_Up_Staff_Total__c = 100, NTE_Top_Up_VAT_Rate__c = 20);
            NTE_MasterPanelController.PaymentReceiptPreview preview = NTE_MasterPanelController.getPaymentReceiptPreview(selected, action);
            if (base) update new Opportunity(Id = selected, Amount = 1080, NTE_Listed_Price_Total__c = 900, NTE_Exhibitor_Space_Price__c = 900);
            else update new Opportunity(Id = selected, NTE_Top_Up_Staff_Total__c = 150);
            Integer writes = Limits.getDmlStatements(); Boolean rejected = false;
            try { NTE_MasterPanelController.recordReviewedPayment(selected, action, preview.amount); }
            catch (AuraHandledException expected) { rejected = expected.getMessage().contains('payment amount has changed'); }
            System.assert(rejected, 'An amount changed while the dialog was open must be reviewed again.');
            System.assertEquals(writes, Limits.getDmlStatements());
            System.assertEquals(0, dispatchCount(selected));
            Opportunity unchanged = [SELECT NTE_Payment_Received__c, NTE_Top_Up_Payment_Received__c FROM Opportunity WHERE Id = :selected];
            System.assert(!unchanged.NTE_Payment_Received__c && !unchanged.NTE_Top_Up_Payment_Received__c);
            preview = NTE_MasterPanelController.getPaymentReceiptPreview(selected, action);
            System.assertEquals(base ? 1080 : 180, preview.amount);
            System.assert(NTE_MasterPanelController.recordReviewedPayment(selected, action, preview.amount).success);
        }
        Test.stopTest();
        System.assertEquals(1, dispatchCount(bookingId('EXHIBITOR')));
        System.assertEquals(0, dispatchCount(bookingId('PARTNER')));
    }

    @IsTest
    static void reviewedReceiptRequiresAnAmountAndAReceiptAction() {
        configure(); Id selected = bookingId('EXHIBITOR');
        Integer writes = Limits.getDmlStatements(); Integer rejected = 0;
        try { NTE_MasterPanelController.recordReviewedPayment(selected, 'PAYMENT_RECEIVED', null); }
        catch (AuraHandledException expected) { rejected++; }
        try { NTE_MasterPanelController.recordReviewedPayment(selected, 'INVOICE_PROVIDED', 960); }
        catch (AuraHandledException expected) { rejected++; }
        try { NTE_MasterPanelController.getPaymentReceiptPreview(selected, 'QUOTE_PROVIDED'); }
        catch (AuraHandledException expected) { rejected++; }
        System.assertEquals(3, rejected); System.assertEquals(writes, Limits.getDmlStatements());
        System.assertEquals(0, dispatchCount(selected));
    }

    @IsTest
    static void failedPaidConfirmationCanRetryAsWaivedConfirmation() {
        configure();
        List<Id> bookingIds = new List<Id>{bookingId('EXHIBITOR'), bookingId('PARTNER')};
        Datetime originalProvisionalAt = Datetime.newInstanceGMT(2026, 8, 1, 10, 0, 0);
        Map<Id, Id> requestByBooking = new Map<Id, Id>();
        Map<Id, String> originalRequests = new Map<Id, String>();
        List<Opportunity> prepared = new List<Opportunity>();
        for (Integer index = 0; index < bookingIds.size(); index++) {
            Id selected = bookingIds[index];
            NTE_Payment_Request__c original = savedRequest(selected, 'Booking', index == 0 ? 960 : 2400,
                originalProvisionalAt, 'waiver-recovery');
            requestByBooking.put(selected, original.Id);
            originalRequests.put(selected, requestHistory(original.Id));
            prepared.add(new Opportunity(Id = selected, NTE_Payment_Method__c = 'Stripe',
                NTE_Invoice_Requested__c = 'Yes', NTE_Approval_Email_Status__c = 'Sent',
                NTE_Approval_Email_Sent_At__c = originalProvisionalAt));
        }
        update prepared;
        Test.startTest();
        Map<Id, Id> dispatchByBooking = new Map<Id, Id>();
        List<Id> dispatchIds = new List<Id>();
        for (Id selected : bookingIds) {
            System.assert(NTE_MasterPanelController.updateMilestone(selected, 'PAYMENT_RECEIVED').success);
            Id dispatchId = dispatchFor(selected).Id;
            dispatchByBooking.put(selected, dispatchId); dispatchIds.add(dispatchId);
            NTEEmailDispatchService.simulatedFailures.add(selected);
        }
        Map<Id, Opportunity> received = new Map<Id, Opportunity>([SELECT Id, NTE_Payment_Received__c,
            NTE_Payment_Received_At__c, NTE_Payment_Recorded_By__c FROM Opportunity WHERE Id IN :bookingIds]);
        NTEEmailDispatchService.processQueued(dispatchIds, true);
        for (Id selected : bookingIds) {
            System.assertEquals('Failed', dispatchFor(selected).Status__c);
            System.assertEquals(null, dispatchFor(selected).Sent_At__c);
        }
        NTEEmailDispatchService.simulatedFailures.clear();
        update new List<Opportunity>{new Opportunity(Id = bookingIds[0], Amount = 0), new Opportunity(Id = bookingIds[1], Amount = 0)};
        System.assertEquals(2, NTEEmailDispatchService.retryFailed(dispatchIds).queuedCount,
            'A failed paid confirmation must remain recoverable after the agreed total is waived.');
        NTEEmailDispatchService.processQueued(dispatchIds, true);
        NTEEmailDispatchService.processQueued(dispatchIds, true);
        System.assertEquals(0, NTEEmailDispatchService.retryFailed(dispatchIds).queuedCount);
        Test.stopTest();
        Map<Id, Opportunity> waived = new Map<Id, Opportunity>([SELECT Id, Amount, NTE_Listed_Price_Total__c,
            NTE_Price_Adjustment__c, NTE_Exhibitor_Space_Price__c, NTE_Sponsor_Package_Total__c,
            NTE_Free_Space_Confirmed__c, NTE_Invoice_Requested__c, NTE_Payment_Received__c,
            NTE_Payment_Received_At__c, NTE_Payment_Recorded_By__c, NTE_Approval_Email_Status__c,
            NTE_Approval_Email_Sent_At__c FROM Opportunity WHERE Id IN :bookingIds]);
        for (Integer index = 0; index < bookingIds.size(); index++) {
            Id selected = bookingIds[index]; Boolean partner = index == 1;
            NTE_Email_Dispatch__c dispatch = dispatchFor(selected);
            System.assertEquals(dispatchByBooking.get(selected), dispatch.Id, 'Retry reuses the original dispatch.');
            System.assertEquals('Sent', dispatch.Status__c);
            System.assertNotEquals(null, dispatch.Sent_At__c);
            System.assertEquals(partner ? 'payment-primary-1@example.invalid' : 'payment-primary-0@example.invalid', dispatch.Recipient__c);
            System.assertEquals(1, dispatchCount(selected));
            Opportunity saved = waived.get(selected);
            System.assertEquals(0, saved.Amount); System.assertEquals(0, saved.NTE_Listed_Price_Total__c);
            System.assertEquals(partner ? -2000 : -800, saved.NTE_Price_Adjustment__c);
            System.assertEquals(partner ? 0 : 800, saved.NTE_Exhibitor_Space_Price__c);
            System.assertEquals(partner ? 2000 : 0, saved.NTE_Sponsor_Package_Total__c);
            System.assertEquals(true, saved.NTE_Free_Space_Confirmed__c);
            System.assertEquals('Yes', saved.NTE_Invoice_Requested__c);
            System.assertEquals(true, saved.NTE_Payment_Received__c);
            System.assertEquals(received.get(selected).NTE_Payment_Received_At__c, saved.NTE_Payment_Received_At__c);
            System.assertEquals(received.get(selected).NTE_Payment_Recorded_By__c, saved.NTE_Payment_Recorded_By__c);
            System.assertEquals('Sent', saved.NTE_Approval_Email_Status__c);
            System.assertEquals(originalProvisionalAt, saved.NTE_Approval_Email_Sent_At__c);
            System.assertEquals(originalRequests.get(selected), requestHistory(requestByBooking.get(selected)));
            String html = NTEEmailDispatchService.renderedHtml.get(selected);
            String text = NTEExhibitorApprovalEmailService.plainTextFromHtml(html);
            System.assert(text.contains('No payment is due.') && text.contains('Booking adjustment') && text.contains('£0.00'));
            System.assert(!text.contains('Total paid') && !text.contains('Thank you for your booking payment'));
            System.assert(!html.contains('Pay Now') && !html.contains('buy.stripe.com') && !html.contains('{NTE_'));
            System.assert(html.contains(partner ? 'partner-staff' : 'exhibitor-staff'));
            System.assert(text.contains(partner ? 'Champion Partner' : 'Your complimentary space is confirmed.'));
        }
        System.assertEquals(2, [SELECT COUNT() FROM NTE_Email_Dispatch__c]);
        System.assertEquals(2, [SELECT COUNT() FROM NTE_Payment_Request__c]);
    }

    private static NTE_Payment_Request__c savedRequest(Id bookingId, String kind, Decimal gross, Datetime deliveredAt, String key) {
        NTE_Payment_Request__c request = new NTE_Payment_Request__c(Opportunity__c = bookingId,
            Charge_Key__c = 'RECEIPT-' + bookingId + '-' + key, Kind__c = kind, Status__c = 'Ready',
            Net_Minor__c = (gross / 1.2 * 100).setScale(0), Amount_Minor__c = gross * 100,
            Tax_Rate__c = 20, Currency__c = 'gbp', Delivered_At__c = deliveredAt,
            Price_Id__c = 'price_Receipt', Link_Id__c = 'plink_Receipt',
            Payment_URL__c = 'https://buy.stripe.com/test_receipt', Source_Fingerprint__c = 'preserved-receipt-request');
        insert request;
        return request;
    }

    private static String requestHistory(Id requestId) {
        return JSON.serialize([SELECT Id, Charge_Key__c, Kind__c, Status__c, Net_Minor__c, Amount_Minor__c,
            Tax_Rate__c, Currency__c, Delivered_At__c, Price_Id__c, Link_Id__c, Payment_URL__c, Source_Fingerprint__c
            FROM NTE_Payment_Request__c WHERE Id = :requestId]);
    }

    private static Id bookingId(String name) {
        String bookingName = 'PAYMENT-EMAIL-' + name;
        return [SELECT Id FROM Opportunity WHERE Name = :bookingName LIMIT 1].Id;
    }
    private static NTE_Email_Dispatch__c dispatchFor(Id bookingId) {
        return [SELECT Id, Status__c, Recipient__c, Contact__c, Sent_At__c, Error__c, Subject__c
            FROM NTE_Email_Dispatch__c WHERE Opportunity__c = :bookingId AND Kind__c = 'BOOKING_CONFIRMED' LIMIT 1];
    }
    private static Integer dispatchCount(Id bookingId) {
        return [SELECT COUNT() FROM NTE_Email_Dispatch__c WHERE Opportunity__c = :bookingId AND Kind__c = 'BOOKING_CONFIRMED'];
    }
}
