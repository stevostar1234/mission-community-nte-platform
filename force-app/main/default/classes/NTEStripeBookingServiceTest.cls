@IsTest
private class NTEStripeBookingServiceTest {
    private static final String EMAIL = 'stripe-owner@example.invalid';
    private class Fixture { Opportunity booking; Contact contact; Lead application; }
    @TestSetup static void permissions() {
        PermissionSet permission = [SELECT Id FROM PermissionSet WHERE Name = 'NTE_Forms_Administration'];
        if ([SELECT COUNT() FROM PermissionSetAssignment WHERE AssigneeId = :UserInfo.getUserId() AND PermissionSetId = :permission.Id] == 0) {
            insert new PermissionSetAssignment(AssigneeId = UserInfo.getUserId(), PermissionSetId = permission.Id);
        }
        System.runAs(new User(Id = UserInfo.getUserId())) {
            Fixture exhibitor = fixture('EXHIBITOR', false); Fixture partner = fixture('PARTNER', true);
            update new Opportunity(Id = partner.booking.Id, NTE_Quote_Required_for_PO__c = 'Yes');
            NTEStripeBookingService.prepareProvisionalBatch('EXHIBITOR', true, true);
            NTEStripeBookingService.prepareProvisionalBatch('PARTNER', true, true);
        }
    }
    private static void configure() {
        NTEStripeBookingService.configurationOverride = new NTE_Stripe_Config__mdt(Enabled__c = true,
            Expected_Account_Id__c = 'acct_NTETest', Expected_Org_Id__c = UserInfo.getOrganizationId(),
            Reference_Prefix__c = 'NTE-STRIPE-', Allowed_Email__c = EMAIL, Tax_Rate__c = 20);
        NTEStripeBookingService.suppressEnqueue = true;
        NTEInboundLeadService.bypassEmailDelivery = true;
        NTEExhibitorApprovalEmailService.bypassEmailDelivery = true;
        NTEExhibitorApprovalEmailService.allowUnconvertedLeadForTests = true;
    }
    private static Fixture fixture(String suffix, Boolean partner) {
        configure(); Fixture f = new Fixture();
        String form = partner ? 'Partner / Sponsor Application' : 'Exhibitor Application';
        f.application = new Lead(FirstName = 'Stripe', LastName = suffix, Company = 'NTE Synthetic Stripe ' + suffix,
            Email = EMAIL, Web_Form_Type__c = form, NTE_Event_Code__c = 'NTE2099', Booking_Reference__c = 'NTE-STRIPE-' + suffix,
            Planned_Exhibitor_Count__c = '2', Total_Staff_Count__c = 2, Stand_Power__c = 'No',
            Exhibitor_Space_Selections__c = partner ? null : 'Single Garage - Track Side - £800 + VAT',
            Exhibitor_Organisation_Category__c = partner ? null : 'CIC or Not for Profit',
            Sponsor_Package__c = partner ? 'Champion Partner' : null);
        insert f.application;
        Account a = new Account(Name = f.application.Company); insert a;
        f.contact = new Contact(FirstName = 'Primary', LastName = suffix, AccountId = a.Id, Email = EMAIL); insert f.contact;
        f.booking = new Opportunity(Name = a.Name, AccountId = a.Id,
            StageName = [SELECT MasterLabel FROM OpportunityStage WHERE IsActive = true ORDER BY SortOrder LIMIT 1].MasterLabel,
            CloseDate = Date.today().addDays(30), NTE_Source_Form_Type__c = form, NTE_Event_Code__c = 'NTE2099',
            Booking_Reference__c = f.application.Booking_Reference__c, NTE_Payment_Method__c = 'Stripe',
            NTE_Exhibitor_Space_Selections__c = f.application.Exhibitor_Space_Selections__c,
            NTE_Exhibitor_Organisation_Category__c = f.application.Exhibitor_Organisation_Category__c,
            NTE_Sponsor_Package__c = f.application.Sponsor_Package__c,
            NTE_Sponsor_Package_Total__c = partner ? 2000 : 0, NTE_Exhibitor_Space_Price__c = partner ? 0 : 800,
            NTE_Listed_Price_Total__c = partner ? 2000 : 800, Amount = partner ? 2000 : 800,
            NTE_Total_Staff_Count__c = 2, NTE_Initial_Staff_Count__c = 2, NTE_Included_Staff_Count__c = 2,
            NTE_Heavy_Vehicle_Required__c = 'Yes', NTE_Pricing_Status__c = 'Calculated',
            NTE_Approval_Email_Status__c = 'Pending', NTE_Approval_Email_Batch__c = suffix,
            NTE_Approval_Email_Lead_Id__c = f.application.Id);
        insert f.booking; insert new OpportunityContactRole(OpportunityId = f.booking.Id, ContactId = f.contact.Id, IsPrimary = true);
        return f;
    }
    private static NTE_Payment_Request__c requestFor(Id bookingId) {
        return [SELECT Id, Status__c, Charge_Key__c, Reference__c, Amount_Minor__c, Net_Minor__c, Tax_Rate__c,
            Price_Id__c, Link_Id__c, Payment_URL__c, Error__c, Delivered_At__c, Verified_At__c, First_Attempt_At__c
            FROM NTE_Payment_Request__c WHERE Opportunity__c = :bookingId];
    }
    private static Fixture savedFixture(String batch) {
        configure(); Fixture f = new Fixture();
        f.booking = [SELECT Id, AccountId, Booking_Reference__c, NTE_Approval_Email_Lead_Id__c FROM Opportunity WHERE NTE_Approval_Email_Batch__c = :batch];
        f.contact = [SELECT Id, Email FROM Contact WHERE Id IN (SELECT ContactId FROM OpportunityContactRole WHERE OpportunityId = :f.booking.Id AND IsPrimary = true)];
        f.application = [SELECT Id FROM Lead WHERE Id = :f.booking.NTE_Approval_Email_Lead_Id__c];
        return f;
    }
    private class RetryWork implements Queueable, Database.AllowsCallouts {
        Id requestId; RetryWork(Id value) { requestId = value; }
        public void execute(QueueableContext context) { configure(); NTEStripeBookingService.processPayment(requestId, true); }
    }
    private static Opportunity state(Id bookingId) {
        return [SELECT NTE_Approval_Email_Status__c, NTE_Approval_Email_Error__c, NTE_Invoice_Provided__c,
            NTE_Payment_Received__c, NTE_Quote_Provided__c FROM Opportunity WHERE Id = :bookingId];
    }
    private class Mock implements HttpCalloutMock {
        NTE_Payment_Request__c payment; String scenario; Integer writes = 0; Integer calls = 0;
        List<String> keys = new List<String>();
        Mock(NTE_Payment_Request__c value, String variant) { payment = value; scenario = variant; }
        public HttpResponse respond(HttpRequest request) {
            calls++; Object body; String path = request.getEndpoint();
            if (request.getMethod() == 'POST') {
                writes++; keys.add(request.getHeader('Idempotency-Key'));
                System.assertEquals(payment.Charge_Key__c + (path.contains('/prices') ? ':price' : ':link'), request.getHeader('Idempotency-Key'));
            }
            if (path.endsWith('/account')) body = new Map<String, Object>{'id' => 'acct_NTETest'};
            else if (path.endsWith('/balance')) body = new Map<String, Object>{'livemode' => false};
            else if (path.contains('/prices')) body = price();
            else if (path.contains('/line_items')) body = new Map<String, Object>{'has_more' => false, 'data' => new List<Object>{
                new Map<String, Object>{'quantity' => 1, 'amount_total' => payment.Amount_Minor__c, 'amount_subtotal' => payment.Amount_Minor__c,
                    'currency' => 'gbp', 'price' => price(), 'adjustable_quantity' => new Map<String, Object>{'enabled' => false}}}};
            else body = new Map<String, Object>{'id' => 'plink_Test', 'active' => scenario != 'inactive', 'livemode' => false,
                'url' => 'https://buy.stripe.com/test_Test', 'currency' => 'gbp', 'allow_promotion_codes' => false,
                'payment_method_types' => new List<String>{'card'}, 'invoice_creation' => new Map<String, Object>{'enabled' => false},
                'automatic_tax' => new Map<String, Object>{'enabled' => false},
                'restrictions' => new Map<String, Object>{'completed_sessions' => new Map<String, Object>{'limit' => 1}},
                'metadata' => new Map<String, Object>{'nte_operation' => payment.Charge_Key__c, 'nte_booking' => payment.Reference__c, 'nte_charge_kind' => 'Booking'}};
            HttpResponse response = new HttpResponse(); response.setStatusCode(scenario == 'outage' ? 503 : 200);
            response.setBody(JSON.serialize(body)); return response;
        }
        private Map<String, Object> price() {
            return new Map<String, Object>{'id' => 'price_Test', 'active' => true, 'livemode' => false, 'currency' => 'gbp',
                'unit_amount' => payment.Amount_Minor__c, 'type' => 'one_time', 'tax_behavior' => 'inclusive',
                'metadata' => new Map<String, Object>{'nte_operation' => payment.Charge_Key__c}};
        }
    }
    @IsTest static void exhibitorRequestEmailPreservesManualPaymentAndExactGross() {
        Fixture f = savedFixture('EXHIBITOR');
        Test.startTest();
        NTE_Payment_Request__c payment = requestFor(f.booking.Id);
        System.assertEquals('Queued', payment.Status__c); System.assertEquals(96000, payment.Amount_Minor__c);
        System.assertEquals(80000, payment.Net_Minor__c); System.assertEquals(0, Limits.getEmailInvocations());
        Mock mock = new Mock(payment, 'normal'); Test.setMock(HttpCalloutMock.class, mock);
        NTEStripeBookingService.processPayment(payment.Id, true);
        System.assertEquals('Ready', requestFor(f.booking.Id).Status__c);
        NTEExhibitorApprovalEmailService.finishStripeBooking(payment.Id, 'EXHIBITOR', true, true);
        NTEExhibitorApprovalEmailService.finishStripeBooking(payment.Id, 'EXHIBITOR', true, true);
        Test.stopTest();
        Opportunity booking = state(f.booking.Id);
        System.assertEquals('Sent', booking.NTE_Approval_Email_Status__c);
        System.assertEquals(true, booking.NTE_Invoice_Provided__c); System.assertEquals(false, booking.NTE_Payment_Received__c);
        System.assertEquals(false, booking.NTE_Quote_Provided__c); System.assertNotEquals(null, requestFor(f.booking.Id).Delivered_At__c);
        String html = NTEExhibitorApprovalEmailService.htmlByOpportunityId.get(f.booking.Id);
        String plain = NTEExhibitorApprovalEmailService.plainTextFromHtml(html);
        System.assert(plain.contains('£960.00') && plain.contains('£160.00') && plain.contains('£800.00'));
        System.assert(plain.contains('https://buy.stripe.com/test_Test') && plain.contains('exhibitor-staff-update.html'));
        System.assert(!plain.contains('££') && !plain.contains('{NTE_'));
        System.assertEquals(1, NTEExhibitorApprovalEmailService.acceptedDispatchCount); System.assertEquals(2, mock.writes);
    }
    @IsTest static void partnerEmailKeepsPartnerPreparationAndSavedAmount() {
        Fixture f = savedFixture('PARTNER');
        Test.startTest();
        NTE_Payment_Request__c payment = requestFor(f.booking.Id); Test.setMock(HttpCalloutMock.class, new Mock(payment, 'normal'));
        NTEStripeBookingService.processPayment(payment.Id, true);
        NTEExhibitorApprovalEmailService.finishStripeBooking(payment.Id, 'PARTNER', true, true); Test.stopTest();
        System.assertEquals(240000, payment.Amount_Minor__c);
        String html = NTEExhibitorApprovalEmailService.htmlByOpportunityId.get(f.booking.Id);
        System.assert(html.contains('partner-sponsor-staff-update.html') && html.contains('buy.stripe.com'));
        System.assert(!html.contains('along with a quotation or invoice'), 'The combined Stripe email must not promise another quote.');
        System.assert(!html.contains('exhibitor-staff-update.html')); System.assertEquals(false, state(f.booking.Id).NTE_Payment_Received__c);
        System.assertEquals(true, state(f.booking.Id).NTE_Quote_Provided__c, 'The agreed combined itemised email supplies the requested quote.');
    }
    @IsTest static void outageBlocksEmailWithoutChangingPayment() {
        Fixture f = savedFixture('EXHIBITOR'); Test.startTest();
        NTE_Payment_Request__c original = requestFor(f.booking.Id);
        Test.setMock(HttpCalloutMock.class, new Mock(original, 'outage')); NTEStripeBookingService.processPayment(original.Id, true);
        System.assertEquals('Needs review', requestFor(f.booking.Id).Status__c); System.assertEquals('Failed', state(f.booking.Id).NTE_Approval_Email_Status__c);
        System.assertEquals(false, state(f.booking.Id).NTE_Invoice_Provided__c);
        Test.stopTest(); System.assertEquals(original.Id, requestFor(f.booking.Id).Id);
        System.assertEquals(false, state(f.booking.Id).NTE_Payment_Received__c); System.assertEquals(0, Limits.getEmailInvocations());
    }
    @IsTest static void retryUsesCommittedRequestAndTheOriginalIdempotencyKeys() {
        Fixture f = savedFixture('EXHIBITOR'); NTE_Payment_Request__c original = requestFor(f.booking.Id);
        update new NTE_Payment_Request__c(Id = original.Id, Status__c = 'Needs review');
        Test.startTest(); NTEStripeBookingService.prepareProvisionalBatch('EXHIBITOR', true, true);
        Test.setMock(HttpCalloutMock.class, new Mock(original, 'normal')); System.enqueueJob(new RetryWork(original.Id)); Test.stopTest();
        System.assertEquals(original.Id, requestFor(f.booking.Id).Id); System.assertEquals('Ready', requestFor(f.booking.Id).Status__c);
        System.assertEquals(original.Charge_Key__c, requestFor(f.booking.Id).Charge_Key__c);
    }
    @IsTest static void failedEmailReusesVerifiedLinkWithoutAnotherCharge() {
        Fixture f = savedFixture('EXHIBITOR'); Test.startTest();
        NTE_Payment_Request__c payment = requestFor(f.booking.Id); Mock mock = new Mock(payment, 'normal'); Test.setMock(HttpCalloutMock.class, mock);
        NTEStripeBookingService.processPayment(payment.Id, true); NTEExhibitorApprovalEmailService.simulateSendFailure = true;
        NTEExhibitorApprovalEmailService.finishStripeBooking(payment.Id, 'EXHIBITOR', true, true);
        System.assertEquals(false, state(f.booking.Id).NTE_Invoice_Provided__c); System.assertEquals(null, requestFor(f.booking.Id).Delivered_At__c);
        update new Opportunity(Id = f.booking.Id, NTE_Approval_Email_Status__c = 'Pending');
        System.assertEquals(false, NTEStripeBookingService.prepareProvisionalBatch('EXHIBITOR', true, true));
        NTEExhibitorApprovalEmailService.simulateSendFailure = false;
        NTEExhibitorApprovalEmailService.finishStripeBooking(payment.Id, 'EXHIBITOR', true, true); Test.stopTest();
        System.assertEquals('Sent', state(f.booking.Id).NTE_Approval_Email_Status__c); System.assertEquals(2, mock.writes);
    }
    @IsTest static void changedAmountOrRecipientCannotUseAnOldRequest() {
        Fixture f = fixture('CHANGED', false); Test.startTest(); NTEStripeBookingService.prepareProvisionalBatch('CHANGED', true, true);
        NTE_Payment_Request__c payment = requestFor(f.booking.Id);
        update new Opportunity(Id = f.booking.Id, Amount = 900, NTE_Listed_Price_Total__c = 900, NTE_Exhibitor_Space_Price__c = 900);
        Mock mock = new Mock(payment, 'normal'); Test.setMock(HttpCalloutMock.class, mock); NTEStripeBookingService.processPayment(payment.Id, true);
        Test.stopTest(); System.assertEquals(0, mock.calls); System.assertEquals('Needs review', requestFor(f.booking.Id).Status__c);
        System.assertEquals(96000, requestFor(f.booking.Id).Amount_Minor__c); System.assertEquals(false, state(f.booking.Id).NTE_Invoice_Provided__c);
    }
    @IsTest static void ambiguousCreationOlderThanIdempotencyWindowRequiresReview() {
        Fixture f = fixture('OLD', false); Test.startTest(); NTEStripeBookingService.prepareProvisionalBatch('OLD', true, true);
        NTE_Payment_Request__c payment = requestFor(f.booking.Id); update new NTE_Payment_Request__c(Id = payment.Id, First_Attempt_At__c = System.now().addHours(-24));
        Mock mock = new Mock(payment, 'normal'); Test.setMock(HttpCalloutMock.class, mock); NTEStripeBookingService.processPayment(payment.Id, true); Test.stopTest();
        System.assertEquals(0, mock.calls); System.assert(requestFor(f.booking.Id).Error__c.contains('reconciliation'));
    }
    @IsTest static void recipientChangeAfterVerificationHoldsEmail() {
        Fixture f = savedFixture('EXHIBITOR'); Test.startTest();
        NTE_Payment_Request__c payment = requestFor(f.booking.Id); Test.setMock(HttpCalloutMock.class, new Mock(payment, 'normal'));
        NTEStripeBookingService.processPayment(payment.Id, true);
        update new Contact(Id = f.contact.Id, Email = 'different@example.invalid');
        NTEExhibitorApprovalEmailService.finishStripeBooking(payment.Id, 'EXHIBITOR', true, true); Test.stopTest();
        System.assertEquals('Failed', state(f.booking.Id).NTE_Approval_Email_Status__c); System.assertEquals(null, requestFor(f.booking.Id).Delivered_At__c);
    }
    @IsTest static void disabledOutOfScopeAndUnconvertedBookingsCannotCreateLinks() {
        Fixture f = fixture('SCOPE', false); Test.startTest();
        NTEStripeBookingService.configurationOverride.Enabled__c = false;
        System.assertEquals(false, NTEStripeBookingService.prepareProvisionalBatch('SCOPE', true, true));
        NTEStripeBookingService.configurationOverride.Enabled__c = true;
        System.assertEquals(false, NTEStripeBookingService.prepareProvisionalBatch('SCOPE', true, false));
        Test.stopTest(); System.assertEquals(0, [SELECT COUNT() FROM NTE_Payment_Request__c WHERE Opportunity__c = :f.booking.Id]);
        System.assert(state(f.booking.Id).NTE_Approval_Email_Error__c.contains('single converted application'));
    }
    @IsTest static void paidCancelledAndWrongOrgHoldTheRequest() {
        Fixture paid = fixture('PAID', false); Fixture cancelled = fixture('CANCEL', false); Fixture wrongOrg = fixture('ORG', true);
        update new Opportunity(Id = paid.booking.Id, NTE_Payment_Received__c = true);
        update new Opportunity(Id = cancelled.booking.Id, StageName = 'Closed Lost');
        Test.startTest();
        for (String batch : new List<String>{'PAID', 'CANCEL'}) System.assertEquals(false, NTEStripeBookingService.prepareProvisionalBatch(batch, true, true));
        NTEStripeBookingService.configurationOverride.Expected_Org_Id__c = '00D000000000001';
        System.assertEquals(false, NTEStripeBookingService.prepareProvisionalBatch('ORG', true, true));
        Test.stopTest(); System.assertEquals(0, [SELECT COUNT() FROM NTE_Payment_Request__c WHERE Batch_Key__c IN ('PAID', 'CANCEL', 'ORG')]);
        System.assert(state(wrongOrg.booking.Id).NTE_Approval_Email_Error__c.contains('Salesforce sandbox'));
    }
    @IsTest static void bulkPreparationDoesNotQueryPerBooking() {
        Fixture seed = fixture('BULK', false); List<Opportunity> additions = new List<Opportunity>();
        for (Integer i = 1; i < 100; i++) {
            Opportunity next = seed.booking.clone(false, false, false, false); next.Name += i; next.Booking_Reference__c += i; additions.add(next);
        }
        insert additions; List<OpportunityContactRole> roles = new List<OpportunityContactRole>();
        for (Opportunity booking : additions) roles.add(new OpportunityContactRole(OpportunityId = booking.Id, ContactId = seed.contact.Id, IsPrimary = true)); insert roles;
        Test.startTest(); Integer beforeQueries = Limits.getQueries();
        System.assert(NTEStripeBookingService.prepareProvisionalBatch('BULK', true, true));
        System.assert(Limits.getQueries() - beforeQueries < 15, 'Preparation must use a bounded number of queries.');
        Test.stopTest(); System.assertEquals(100, [SELECT COUNT() FROM NTE_Payment_Request__c WHERE Batch_Key__c = 'BULK']);
    }
    @IsTest static void nextYearUsesNewOpportunityWithTheSameAccountAndContact() {
        Fixture old = savedFixture('EXHIBITOR'); NTE_Payment_Request__c oldPayment = requestFor(old.booking.Id);
        update new Opportunity(Id = old.booking.Id, NTE_Payment_Received__c = true, NTE_Invoice_Provided__c = true,
            NTE_Approval_Email_Status__c = 'Sent', NTE_Event_Code__c = 'NTE2027');
        update new NTE_Payment_Request__c(Id = oldPayment.Id, Status__c = 'Ready', Link_Id__c = 'plink_PreviousYear',
            Payment_URL__c = 'https://buy.stripe.com/test_PreviousYear', Delivered_At__c = System.now());
        Lead nextYear = new Lead(FirstName = 'Returning', LastName = 'Exhibitor', Company = 'Returning Organisation',
            Email = EMAIL, Web_Form_Type__c = 'Exhibitor Application', NTE_Event_Code__c = 'NTE2028',
            Booking_Reference__c = 'NTE-STRIPE-NEXT-YEAR', Payment_Method__c = 'Stripe', Invoice_Required__c = 'Yes',
            Exhibitor_Space_Selections__c = 'Single Garage - Track Side - £800 + VAT',
            Exhibitor_Organisation_Category__c = 'CIC or Not for Profit', Planned_Exhibitor_Count__c = '2',
            Total_Staff_Count__c = 2, Stand_Power__c = 'No');
        insert nextYear;
        Database.LeadConvert conversion = new Database.LeadConvert(); conversion.setLeadId(nextYear.Id);
        conversion.setAccountId(old.booking.AccountId); conversion.setContactId(old.contact.Id);
        conversion.setConvertedStatus([SELECT MasterLabel FROM LeadStatus WHERE IsConverted = true LIMIT 1].MasterLabel);
        conversion.setOpportunityName('Returning Organisation NTE2028');
        Test.startTest(); Database.LeadConvertResult converted = Database.convertLead(conversion);
        System.assert(converted.isSuccess()); System.assertNotEquals(old.booking.Id, converted.getOpportunityId());
        Opportunity fresh = [SELECT Id, AccountId, NTE_Event_Code__c, NTE_Approval_Email_Batch__c FROM Opportunity WHERE Id = :converted.getOpportunityId()];
        System.assertEquals(old.booking.AccountId, fresh.AccountId); System.assertEquals(old.contact.Id, converted.getContactId());
        System.assert(NTEStripeBookingService.prepareProvisionalBatch(fresh.NTE_Approval_Email_Batch__c, true, false));
        NTE_Payment_Request__c newPayment = requestFor(fresh.Id);
        System.assertNotEquals(oldPayment.Id, newPayment.Id); System.assertNotEquals(oldPayment.Charge_Key__c, newPayment.Charge_Key__c);
        System.assertEquals('NTE-STRIPE-NEXT-YEAR', newPayment.Reference__c); System.assertEquals(null, newPayment.Link_Id__c);
        Test.stopTest();
        System.assertEquals('plink_PreviousYear', requestFor(old.booking.Id).Link_Id__c);
        System.assertEquals(true, state(old.booking.Id).NTE_Payment_Received__c);
        System.assertEquals(false, state(fresh.Id).NTE_Payment_Received__c);
    }
}
