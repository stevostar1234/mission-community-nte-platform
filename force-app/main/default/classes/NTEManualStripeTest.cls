@IsTest
private class NTEManualStripeTest {
    private static void configure() {
        NTEStripeBookingService.configurationOverride=new NTE_Stripe_Config__mdt(Enabled__c=true,Live_Mode__c=false,
            Expected_Account_Id__c='acct_NTETest',Expected_Org_Id__c=UserInfo.getOrganizationId(),Tax_Rate__c=20);
        NTEStripeBookingService.suppressEnqueue=true;
        NTEInboundLeadService.bypassEmailDelivery=true;
    }
    @TestSetup static void fixture() {
        PermissionSet permission=[SELECT Id FROM PermissionSet WHERE Name='NTE_Forms_Administration'];
        if ([SELECT COUNT() FROM PermissionSetAssignment WHERE AssigneeId=:UserInfo.getUserId() AND PermissionSetId=:permission.Id]==0)
            insert new PermissionSetAssignment(AssigneeId=UserInfo.getUserId(),PermissionSetId=permission.Id);
        System.runAs(new User(Id=UserInfo.getUserId())) {
            configure();
            Id bookingId = newTopUpBooking('STRIPE', 2, 50, 100);
            NTEFinanceService.sendFinanceAction(bookingId,'TOP_UP');
        }
    }
    private static Id newTopUpBooking(String key, Decimal quantity, Decimal unitPrice, Decimal total) {
        Lead lead = new Lead(FirstName='Asha', LastName='TopUp '+key, Company='Manual Stripe Top-up '+key,
            Email='topup-'+key.toLowerCase()+'@example.invalid', Web_Form_Type__c='Exhibitor Application',
            NTE_Event_Code__c='NTE2099', Booking_Reference__c='NTE-MANUAL-TOPUP-'+key,
            Exhibitor_Organisation_Category__c='CIC or Not for Profit',
            Exhibitor_Space_Selections__c='Single Garage - Track Side - £799 + VAT',
            Planned_Exhibitor_Count__c='2', Total_Staff_Count__c=2, Stand_Power__c='No',
            Heavy_Vehicle_Required__c='No', Payment_Method__c='Bank transfer');
        insert lead;
        Database.LeadConvert conversion = new Database.LeadConvert(); conversion.setLeadId(lead.Id);
        conversion.setConvertedStatus([SELECT MasterLabel FROM LeadStatus WHERE IsConverted=true LIMIT 1].MasterLabel);
        Id bookingId = Database.convertLead(conversion).getOpportunityId();
        update new Opportunity(Id=bookingId, NTE_Top_Up_Staff_Count__c=quantity,
            NTE_Top_Up_Staff_Unit_Price__c=unitPrice, NTE_Top_Up_Staff_Total__c=total, NTE_Top_Up_VAT_Rate__c=20);
        return bookingId;
    }
    private static NTE_Payment_Request__c payment() {
        return payment([SELECT Opportunity__c FROM NTE_Payment_Request__c LIMIT 1].Opportunity__c);
    }
    private static NTE_Payment_Request__c payment(Id bookingId) {
        return [SELECT Id,Opportunity__c,Kind__c,Charge_Key__c,Status__c,Net_Minor__c,Amount_Minor__c,Tax_Rate__c,Live_Mode__c,
            Description__c,Reference__c,Price_Id__c,Link_Id__c,Payment_URL__c,Delivered_At__c,Error__c,Verified_At__c,Recipient__c,
            Source_Fingerprint__c FROM NTE_Payment_Request__c WHERE Opportunity__c=:bookingId LIMIT 1];
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
                String descriptionField = path.contains('/prices') ? 'product_data[name]' : 'payment_intent_data[description]';
                System.assert(request.getBody().contains(EncodingUtil.urlEncode(descriptionField, 'UTF-8') + '='
                    + EncodingUtil.urlEncode(payment.Description__c, 'UTF-8')), 'Stripe receives the saved wording on both initial requests and retries.');
            }
            System.assert(path.startsWith('callout:NTE_Stripe_' + (payment.Live_Mode__c == true ? 'Live' : 'Test') + '/v1/'));
            if (scenario == 'linkTimeout' && request.getMethod() == 'POST' && path.contains('/payment_links')) throw new CalloutException('Synthetic timeout');
            if (path.endsWith('/account')) body = new Map<String, Object>{'id' => 'acct_NTETest', 'charges_enabled' => true};
            else if (path.endsWith('/balance')) body = new Map<String, Object>{'livemode' => payment.Live_Mode__c == true};
            else if (path.contains('/prices')) body = price();
            else if (path.contains('/line_items')) body = new Map<String, Object>{'has_more' => false, 'data' => new List<Object>{
                new Map<String, Object>{'quantity' => 1, 'amount_total' => payment.Amount_Minor__c, 'amount_subtotal' => payment.Amount_Minor__c,
                    'currency' => 'gbp', 'price' => price(), 'adjustable_quantity' => new Map<String, Object>{'enabled' => false}}}};
            else body = new Map<String, Object>{'id' => 'plink_Test', 'active' => scenario != 'inactive', 'livemode' => payment.Live_Mode__c == true,
                'url' => payment.Live_Mode__c == true ? 'https://buy.stripe.com/LiveExample123' : 'https://buy.stripe.com/test_Test', 'currency' => 'gbp', 'allow_promotion_codes' => false,
                'payment_method_types' => new List<String>{'card'}, 'invoice_creation' => new Map<String, Object>{'enabled' => false},
                'automatic_tax' => new Map<String, Object>{'enabled' => false},
                'restrictions' => new Map<String, Object>{'completed_sessions' => new Map<String, Object>{'limit' => 1}},
                'metadata' => new Map<String, Object>{'nte_operation' => payment.Charge_Key__c, 'nte_booking' => payment.Reference__c, 'nte_charge_kind' => payment.Kind__c, 'nte_net_minor' => String.valueOf(payment.Net_Minor__c.longValue()), 'nte_vat_minor' => String.valueOf((payment.Amount_Minor__c - payment.Net_Minor__c).longValue()), 'nte_vat_rate' => String.valueOf(payment.Tax_Rate__c.setScale(2))},
                'custom_text' => new Map<String,Object>{'submit' => new Map<String,Object>{'message' => 'Subtotal £' + String.valueOf((payment.Net_Minor__c / 100).setScale(2)) + ' + £' + String.valueOf(((payment.Amount_Minor__c-payment.Net_Minor__c) / 100).setScale(2)) + ' VAT (20%). Total £' + String.valueOf((payment.Amount_Minor__c / 100).setScale(2)) + ' including VAT.'}}};
            HttpResponse response = new HttpResponse(); response.setStatusCode(scenario == 'outage' ? 503 : 200);
            response.setBody(JSON.serialize(body)); return response;
        }
        private Map<String, Object> price() {
            return new Map<String, Object>{'id' => 'price_Test', 'active' => true, 'livemode' => payment.Live_Mode__c == true, 'currency' => 'gbp',
                'unit_amount' => payment.Amount_Minor__c, 'type' => 'one_time', 'tax_behavior' => 'inclusive',
                'metadata' => new Map<String, Object>{'nte_operation' => payment.Charge_Key__c}};
        }
    }
    @IsTest static void topUpUsesOwnGrossChargeAndDoesNotTouchBaseOrChecklist() {
        configure();NTE_Payment_Request__c request=payment();Mock mock=new Mock(request,'normal');Test.setMock(HttpCalloutMock.class,mock);
        Test.startTest();NTEStripeBookingService.processPayment(request.Id,false);NTEStripeBookingService.deliverTopUp(request.Id,true);NTEStripeBookingService.deliverTopUp(request.Id,true);Test.stopTest();
        request=payment();System.assertEquals('Sent',request.Status__c,'Top-up delivery: '+request.Error__c);System.assertEquals(10000,request.Net_Minor__c);System.assertEquals(12000,request.Amount_Minor__c);
        System.assertNotEquals(null,request.Delivered_At__c);System.assert(request.Charge_Key__c.endsWith(':TopUp'));System.assertEquals(2,mock.writes);
        Opportunity booking=[SELECT NTE_Payment_Received__c,NTE_Quote_Provided__c,NTE_Invoice_Provided__c,NTE_Top_Up_Invoice_Provided__c,NTE_Top_Up_Payment_Requested_At__c,NTE_Finance_Requirements_Due__c,NTE_Finance_Payment_Due__c FROM Opportunity WHERE Id=:request.Opportunity__c];
        System.assert(!booking.NTE_Payment_Received__c);System.assert(!booking.NTE_Invoice_Provided__c);System.assert(!booking.NTE_Quote_Provided__c);System.assert(!booking.NTE_Top_Up_Invoice_Provided__c);
        System.assertNotEquals(null,booking.NTE_Top_Up_Payment_Requested_At__c);System.assert(booking.NTE_Finance_Requirements_Due__c);System.assert(!booking.NTE_Finance_Payment_Due__c,'The original booking still needs its request.');
        System.assertEquals(0,[SELECT COUNT() FROM NTE_Payment_Request__c WHERE Kind__c='Booking']);
        System.assertEquals(1,[SELECT COUNT() FROM Task WHERE Subject='NTE staff top-up payment email - sent']);
    }
    @IsTest static void topUpOutageLeavesNoIssuedPaymentAndCanBeRetried() {
        configure();NTE_Payment_Request__c request=payment();Test.setMock(HttpCalloutMock.class,new Mock(request,'outage'));
        Test.startTest();NTEStripeBookingService.processPayment(request.Id,false);Test.stopTest();
        System.assertEquals('Needs review',payment().Status__c);System.assertEquals(null,payment().Delivered_At__c);
        NTEFinanceService.sendFinanceAction(request.Opportunity__c,'TOP_UP');System.assertEquals('Queued',payment().Status__c);
        System.assertEquals(request.Id,payment().Id);System.assertEquals(1,[SELECT COUNT() FROM NTE_Payment_Request__c]);
    }
    @IsTest static void topUpCannotQueueTwiceOrRequestAnAlreadyPaidCharge() {
        configure();NTE_Payment_Request__c request=payment();Boolean blocked=false;
        try { NTEFinanceService.sendFinanceAction(request.Opportunity__c,'TOP_UP'); } catch (AuraHandledException expected) { blocked=true; }
        System.assert(blocked);update new Opportunity(Id=request.Opportunity__c,NTE_Top_Up_Payment_Received__c=true);
        blocked=false;try { NTEFinanceService.sendFinanceAction(request.Opportunity__c,'TOP_UP'); } catch (AuraHandledException expected) { blocked=true; }
        System.assert(blocked);System.assertEquals(1,[SELECT COUNT() FROM NTE_Payment_Request__c]);
    }
    @IsTest static void changedTopUpDoesNotCreateASecondLink() {
        configure();NTE_Payment_Request__c request=payment();update new Opportunity(Id=request.Opportunity__c,NTE_Top_Up_Staff_Total__c=150);
        Test.startTest();NTEStripeBookingService.processPayment(request.Id,false);Test.stopTest();
        System.assertEquals('Needs review',payment().Status__c);System.assertEquals(null,payment().Link_Id__c);
        Boolean blocked=false;try { NTEFinanceService.sendFinanceAction(request.Opportunity__c,'TOP_UP'); } catch (AuraHandledException expected) { blocked=true; }
        System.assert(blocked);System.assertEquals(request.Amount_Minor__c,payment().Amount_Minor__c);
    }
    @IsTest static void existingDeliveredTopUpReusesItsVerifiedResourceIds() {
        configure();NTE_Payment_Request__c request=payment();
        update new NTE_Payment_Request__c(Id=request.Id,Price_Id__c='price_Test',Link_Id__c='plink_Test',Delivered_At__c=System.now().addDays(-1));
        Mock mock=new Mock(request,'normal');Test.setMock(HttpCalloutMock.class,mock);
        Test.startTest();NTEStripeBookingService.processPayment(request.Id,false);NTEStripeBookingService.deliverTopUp(request.Id,true);Test.stopTest();
        System.assertEquals(0,mock.writes);System.assertEquals('Sent',payment().Status__c);System.assertEquals(request.Id,payment().Id);
        System.assert(payment().Delivered_At__c < System.now().addHours(-23));
    }
    @IsTest static void inactiveTopUpCannotBeEmailedOrReplaced() {
        configure();NTE_Payment_Request__c request=payment();update new NTE_Payment_Request__c(Id=request.Id,Price_Id__c='price_Test',Link_Id__c='plink_Test');
        Mock mock=new Mock(request,'inactive');Test.setMock(HttpCalloutMock.class,mock);
        Test.startTest();NTEStripeBookingService.processPayment(request.Id,false);NTEStripeBookingService.deliverTopUp(request.Id,true);Test.stopTest();
        System.assertEquals(0,mock.writes);System.assertEquals('Needs review',payment().Status__c);System.assertEquals(null,payment().Delivered_At__c);
    }
    @IsTest static void topUpPricingRequiresAWholeQuantityAndConsistentSavedPrices() {
        List<Opportunity> invalid = new List<Opportunity>{
            new Opportunity(NTE_Top_Up_Staff_Unit_Price__c=50, NTE_Top_Up_Staff_Total__c=100),
            new Opportunity(NTE_Top_Up_Staff_Count__c=0, NTE_Top_Up_Staff_Unit_Price__c=50, NTE_Top_Up_Staff_Total__c=100),
            new Opportunity(NTE_Top_Up_Staff_Count__c=-2, NTE_Top_Up_Staff_Unit_Price__c=50, NTE_Top_Up_Staff_Total__c=100),
            new Opportunity(NTE_Top_Up_Staff_Count__c=1.5, NTE_Top_Up_Staff_Unit_Price__c=50, NTE_Top_Up_Staff_Total__c=75),
            new Opportunity(NTE_Top_Up_Staff_Count__c=2, NTE_Top_Up_Staff_Total__c=100),
            new Opportunity(NTE_Top_Up_Staff_Count__c=2, NTE_Top_Up_Staff_Unit_Price__c=0, NTE_Top_Up_Staff_Total__c=100),
            new Opportunity(NTE_Top_Up_Staff_Count__c=2, NTE_Top_Up_Staff_Unit_Price__c=-50, NTE_Top_Up_Staff_Total__c=100),
            new Opportunity(NTE_Top_Up_Staff_Count__c=2, NTE_Top_Up_Staff_Unit_Price__c=50),
            new Opportunity(NTE_Top_Up_Staff_Count__c=2, NTE_Top_Up_Staff_Unit_Price__c=50, NTE_Top_Up_Staff_Total__c=0),
            new Opportunity(NTE_Top_Up_Staff_Count__c=2, NTE_Top_Up_Staff_Unit_Price__c=50, NTE_Top_Up_Staff_Total__c=-100),
            new Opportunity(NTE_Top_Up_Staff_Count__c=2, NTE_Top_Up_Staff_Unit_Price__c=50, NTE_Top_Up_Staff_Total__c=100.01)
        };
        for (Opportunity booking : invalid) {
            System.assertEquals(false, NTEStripeBookingService.validTopUpPricing(booking), JSON.serialize(booking));
        }
        System.assert(NTEStripeBookingService.validTopUpPricing(new Opportunity(
            NTE_Top_Up_Staff_Count__c=3, NTE_Top_Up_Staff_Unit_Price__c=42.35, NTE_Top_Up_Staff_Total__c=127.05)),
            'Accepted historical unit prices and exact pennies must remain valid.');
        System.assert(NTEStripeBookingService.validTopUpPricing(new Opportunity(
            NTE_Top_Up_Staff_Count__c=3, NTE_Top_Up_Staff_Unit_Price__c=0.335, NTE_Top_Up_Staff_Total__c=1.01)),
            'Arithmetic rounds the net charge to normal currency precision.');
    }
    @IsTest static void inconsistentTopUpCannotCreateARequestOrChangeRecordedFacts() {
        configure(); Id bookingId = newTopUpBooking('INCONSISTENT', 2, 50, 150);
        Datetime originalPayment = System.now().addDays(-1);
        update new Opportunity(Id=bookingId, NTE_Payment_Received__c=true,
            NTE_Payment_Received_At__c=originalPayment, NTE_PO_Confirmed__c=true);
        Integer queuedBefore = Limits.getQueueableJobs(); Boolean blocked = false;
        try { NTEFinanceService.sendFinanceAction(bookingId, 'TOP_UP'); }
        catch (AuraHandledException expected) { blocked = expected.getMessage().contains('quantity, unit price and total'); }
        System.assert(blocked, 'An inconsistent first top-up must fail before saving a Stripe request.');
        System.assertEquals(queuedBefore, Limits.getQueueableJobs());
        System.assertEquals(0, [SELECT COUNT() FROM NTE_Payment_Request__c WHERE Opportunity__c=:bookingId]);
        Opportunity booking = [SELECT NTE_Payment_Received__c, NTE_Payment_Received_At__c, NTE_PO_Confirmed__c,
            NTE_Top_Up_Payment_Received__c, NTE_Top_Up_Payment_Requested_At__c, NTE_Top_Up_Staff_Total__c
            FROM Opportunity WHERE Id=:bookingId];
        System.assert(booking.NTE_Payment_Received__c); System.assertEquals(originalPayment, booking.NTE_Payment_Received_At__c);
        System.assert(booking.NTE_PO_Confirmed__c); System.assert(!booking.NTE_Top_Up_Payment_Received__c);
        System.assertEquals(null, booking.NTE_Top_Up_Payment_Requested_At__c); System.assertEquals(150, booking.NTE_Top_Up_Staff_Total__c);
    }
    @IsTest static void queuedTopUpUnitPriceChangeStopsBeforeCallouts() {
        configure(); NTE_Payment_Request__c original = payment();
        update new Opportunity(Id=original.Opportunity__c, NTE_Top_Up_Staff_Unit_Price__c=60);
        Mock mock = new Mock(original, 'normal'); Test.setMock(HttpCalloutMock.class, mock);
        Test.startTest(); NTEStripeBookingService.processPayment(original.Id, false); Test.stopTest();
        NTE_Payment_Request__c held = payment();
        System.assertEquals(0, mock.calls); System.assertEquals('Needs review', held.Status__c);
        System.assert(held.Error__c.contains('quantity, unit price and total'));
        System.assertEquals(original.Id, held.Id); System.assertEquals(original.Source_Fingerprint__c, held.Source_Fingerprint__c);
        System.assertEquals(original.Net_Minor__c, held.Net_Minor__c); System.assertEquals(original.Amount_Minor__c, held.Amount_Minor__c);
        System.assertEquals(null, held.Link_Id__c); System.assertEquals(null, held.Delivered_At__c);
    }
    @IsTest static void topUpUnitPriceChangeAfterVerificationStopsDelivery() {
        configure(); NTE_Payment_Request__c original = payment();
        Mock mock = new Mock(original, 'normal'); Test.setMock(HttpCalloutMock.class, mock);
        Test.startTest();
        NTEStripeBookingService.processPayment(original.Id, false);
        update new Opportunity(Id=original.Opportunity__c, NTE_Top_Up_Staff_Unit_Price__c=60);
        NTEStripeBookingService.deliverTopUp(original.Id, true);
        Test.stopTest();
        NTE_Payment_Request__c held = payment();
        System.assertEquals('Needs review', held.Status__c); System.assert(held.Error__c.contains('quantity, unit price and total'));
        System.assertEquals('price_Test', held.Price_Id__c); System.assertEquals('plink_Test', held.Link_Id__c);
        System.assertEquals(original.Amount_Minor__c, held.Amount_Minor__c); System.assertEquals(null, held.Delivered_At__c);
        System.assertEquals(null, [SELECT NTE_Top_Up_Payment_Requested_At__c FROM Opportunity WHERE Id=:original.Opportunity__c].NTE_Top_Up_Payment_Requested_At__c);
        System.assertEquals(0, [SELECT COUNT() FROM Task WHERE Subject='NTE staff top-up payment email - sent']);
    }
    @IsTest static void historicalUnitPriceKeepsTheSameRequestOnRetry() {
        configure(); Id bookingId = newTopUpBooking('HISTORICAL', 3, 42.35, 127.05);
        NTEFinanceService.sendFinanceAction(bookingId, 'TOP_UP');
        NTE_Payment_Request__c original = payment(bookingId);
        System.assertEquals(12705, original.Net_Minor__c); System.assertEquals(15246, original.Amount_Minor__c);
        update new NTE_Payment_Request__c(Id=original.Id, Status__c='Needs review');
        NTEFinanceService.sendFinanceAction(bookingId, 'TOP_UP');
        NTE_Payment_Request__c retried = payment(bookingId);
        System.assertEquals('Queued', retried.Status__c); System.assertEquals(original.Id, retried.Id);
        System.assertEquals(original.Source_Fingerprint__c, retried.Source_Fingerprint__c);
        System.assertEquals(original.Net_Minor__c, retried.Net_Minor__c); System.assertEquals(original.Amount_Minor__c, retried.Amount_Minor__c);
        System.assertEquals(1, [SELECT COUNT() FROM NTE_Payment_Request__c WHERE Opportunity__c=:bookingId]);
        System.assertEquals(42.35, [SELECT NTE_Top_Up_Staff_Unit_Price__c FROM Opportunity WHERE Id=:bookingId].NTE_Top_Up_Staff_Unit_Price__c);
    }
}
