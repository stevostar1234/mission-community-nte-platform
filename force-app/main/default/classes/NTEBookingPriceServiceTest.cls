@IsTest
private class NTEBookingPriceServiceTest {
    private static final String EXHIBITOR = 'Exhibitor Application';
    private static final String PARTNER = 'Partner / Sponsor Application';
    private static final Datetime RECORDED_AT = Datetime.newInstanceGMT(2026, 8, 1, 10, 0, 0);

    @TestSetup
    static void setup() {
        PermissionSet permission = [SELECT Id FROM PermissionSet WHERE Name = 'NTE_Forms_Administration' LIMIT 1];
        if ([SELECT COUNT() FROM PermissionSetAssignment WHERE AssigneeId = :UserInfo.getUserId()
            AND PermissionSetId = :permission.Id] == 0) {
            insert new PermissionSetAssignment(AssigneeId = UserInfo.getUserId(), PermissionSetId = permission.Id);
        }
        System.runAs(new User(Id = UserInfo.getUserId())) {
            Account organisation = new Account(Name = 'NTE Revised Price Test');
            insert organisation;
            Id recordTypeId = [SELECT Id FROM RecordType WHERE SobjectType = 'Opportunity'
                AND DeveloperName = 'NTE_Event_Opportunity' LIMIT 1].Id;
            String stage = [SELECT MasterLabel FROM OpportunityStage WHERE IsActive = true AND IsClosed = false
                ORDER BY SortOrder LIMIT 1].MasterLabel;
            insert new List<Opportunity>{
                booking(organisation.Id, recordTypeId, stage, 'EXHIBITOR', EXHIBITOR),
                booking(organisation.Id, recordTypeId, stage, 'PARTNER', PARTNER)
            };
        }
    }

    private static Opportunity booking(Id accountId, Id recordTypeId, String stage, String name, String formType) {
        Boolean partner = formType == PARTNER;
        Decimal net = partner ? 2100 : 1000;
        return new Opportunity(AccountId = accountId, RecordTypeId = recordTypeId, Name = name,
            StageName = stage, CloseDate = Date.today().addDays(30), NTE_Event_Code__c = 'NTE2097',
            NTE_Source_Form_Type__c = formType, Booking_Reference__c = 'NTE-PRICE-' + name,
            Amount = net * 1.2, NTE_Listed_Price_Total__c = net, NTE_VAT_Rate__c = 20,
            NTE_Price_Adjustment__c = 0, NTE_Pricing_Status__c = 'Calculated',
            NTE_Sponsor_Package_Total__c = partner ? 2000 : 0, NTE_Exhibitor_Space_Price__c = partner ? 0 : 800,
            NTE_Power_Socket_Count__c = 2, NTE_Power_Socket_Unit_Price__c = 50, NTE_Power_Socket_Total__c = 100,
            NTE_Additional_Staff_Count__c = partner ? '0' : '2', NTE_Additional_Staff_Unit_Price__c = partner ? 0 : 50,
            NTE_Additional_Staff_Total__c = partner ? 0 : 100,
            NTE_Invoice_Required__c = 'Yes', NTE_Invoice_Requested__c = 'Yes',
            NTE_Payment_Method__c = 'Bank transfer');
    }

    private static Opportunity state(String name) {
        return [SELECT Id, Name, AccountId, RecordTypeId, StageName, CloseDate, NTE_Source_Form_Type__c,
            NTE_Event_Code__c, Amount, NTE_Listed_Price_Total__c, NTE_VAT_Rate__c, NTE_Price_Adjustment__c,
            NTE_VAT_Total__c, NTE_Total_Including_VAT__c, NTE_Pricing_Status__c,
            NTE_Sponsor_Package_Total__c, NTE_Exhibitor_Space_Price__c,
            NTE_Power_Socket_Count__c, NTE_Power_Socket_Unit_Price__c, NTE_Power_Socket_Total__c,
            NTE_Additional_Staff_Count__c, NTE_Additional_Staff_Unit_Price__c, NTE_Additional_Staff_Total__c,
            NTE_Invoice_Required__c, NTE_Invoice_Requested__c, NTE_Payment_Received__c,
            NTE_Approval_Email_Status__c, NTE_Approval_Email_Sent_At__c
            FROM Opportunity WHERE Name = :name LIMIT 1];
    }

    @IsTest
    static void amountOnlyEditsReplaceTheAdjustmentWithoutRepricingItems() {
        Opportunity original = state('EXHIBITOR');
        Test.startTest();
        update new Opportunity(Id = original.Id, Amount = 840);
        Opportunity reduced = state('EXHIBITOR');
        System.assertEquals(700, reduced.NTE_Listed_Price_Total__c);
        System.assertEquals(-300, reduced.NTE_Price_Adjustment__c);
        System.assertEquals(840, reduced.Amount);
        update new Opportunity(Id = original.Id, Amount = 1320);
        Opportunity increased = state('EXHIBITOR');
        System.assertEquals(1100, increased.NTE_Listed_Price_Total__c);
        System.assertEquals(100, increased.NTE_Price_Adjustment__c, 'A second edit is relative to original items, not the previous adjustment.');
        update new Opportunity(Id = original.Id, Amount = 1200);
        Test.stopTest();
        Opportunity restored = state('EXHIBITOR');
        System.assertEquals(1000, restored.NTE_Listed_Price_Total__c);
        System.assertEquals(0, restored.NTE_Price_Adjustment__c);
        for (String fieldName : new List<String>{'NTE_Sponsor_Package_Total__c', 'NTE_Exhibitor_Space_Price__c',
            'NTE_Power_Socket_Count__c', 'NTE_Power_Socket_Unit_Price__c', 'NTE_Power_Socket_Total__c',
            'NTE_Additional_Staff_Count__c', 'NTE_Additional_Staff_Unit_Price__c', 'NTE_Additional_Staff_Total__c'}) {
            System.assertEquals(original.get(fieldName), restored.get(fieldName), fieldName);
        }
        System.assertEquals('Yes', restored.NTE_Invoice_Required__c);
        System.assertEquals('Yes', restored.NTE_Invoice_Requested__c);
        System.assertEquals(0, [SELECT COUNT() FROM NTE_Payment_Request__c]);
        System.assertEquals(0, [SELECT COUNT() FROM NTE_Email_Dispatch__c]);
    }

    @IsTest
    static void exhibitorAndPartnerCanBeWaivedAndLaterRepriced() {
        Opportunity exhibitor = state('EXHIBITOR');
        Opportunity partner = state('PARTNER');
        Test.startTest();
        update new List<Opportunity>{new Opportunity(Id = exhibitor.Id, Amount = 0), new Opportunity(Id = partner.Id, Amount = 0)};
        for (String name : new List<String>{'EXHIBITOR', 'PARTNER'}) {
            Opportunity waived = state(name);
            System.assertEquals(0, waived.Amount);
            System.assertEquals(0, waived.NTE_Listed_Price_Total__c);
            System.assertEquals(name == 'PARTNER' ? -2100 : -1000, waived.NTE_Price_Adjustment__c);
            System.assertEquals('No', waived.NTE_Invoice_Required__c);
            System.assertEquals('Yes', waived.NTE_Invoice_Requested__c, 'Invoice preference is independent of whether money is due.');
            System.assertEquals(false, waived.NTE_Payment_Received__c);
            System.assertEquals(null, waived.NTE_Approval_Email_Sent_At__c, 'A waiver does not send a confirmation.');
        }
        update new Opportunity(Id = partner.Id, Amount = 120);
        Test.stopTest();
        Opportunity repriced = state('PARTNER');
        System.assertEquals(100, repriced.NTE_Listed_Price_Total__c);
        System.assertEquals(-2000, repriced.NTE_Price_Adjustment__c);
        System.assertEquals(2000, repriced.NTE_Sponsor_Package_Total__c);
        System.assertEquals('Yes', repriced.NTE_Invoice_Required__c);
        System.assertEquals(0, [SELECT COUNT() FROM NTE_Email_Dispatch__c]);
    }

    @IsTest
    static void inclusivePenceAndSavedVatRatesRemainExact() {
        Opportunity original = state('EXHIBITOR');
        List<Opportunity> examples = new List<Opportunity>();
        for (String name : new List<String>{'PENCE-03', 'PENCE-51', 'HISTORICAL-RATE', 'ZERO-RATE'}) {
            examples.add(booking(original.AccountId, original.RecordTypeId, original.StageName, name, EXHIBITOR));
        }
        insert examples;
        Test.startTest();
        update new List<Opportunity>{
            new Opportunity(Id = examples[0].Id, Amount = 0.03),
            new Opportunity(Id = examples[1].Id, Amount = 0.51, NTE_VAT_Rate__c = null),
            new Opportunity(Id = examples[2].Id, Amount = 117.50, NTE_VAT_Rate__c = 17.5),
            new Opportunity(Id = examples[3].Id, Amount = 123.45, NTE_VAT_Rate__c = 0)
        };
        Test.stopTest();
        Map<String, Decimal> nets = new Map<String, Decimal>{'PENCE-03' => 0.02, 'PENCE-51' => 0.42, 'HISTORICAL-RATE' => 100, 'ZERO-RATE' => 123.45};
        Map<String, Decimal> taxes = new Map<String, Decimal>{'PENCE-03' => 0.01, 'PENCE-51' => 0.09, 'HISTORICAL-RATE' => 17.50, 'ZERO-RATE' => 0};
        for (String name : nets.keySet()) {
            Opportunity revised = state(name);
            System.assertEquals(nets.get(name), revised.NTE_Listed_Price_Total__c, name);
            System.assertEquals(nets.get(name) - 1000, revised.NTE_Price_Adjustment__c, name);
            System.assertEquals(taxes.get(name), revised.NTE_VAT_Total__c, name);
            System.assertEquals(revised.Amount, revised.NTE_Total_Including_VAT__c, name);
        }
    }

    @IsTest
    static void unrelatedAndUnchangedUpdatesDoNotResolveOrRepriceTheBooking() {
        Opportunity original = state('EXHIBITOR');
        update new Opportunity(Id = original.Id, NTE_Pricing_Status__c = 'Review required');
        Test.startTest();
        update new Opportunity(Id = original.Id, Description = 'Staff checked delivery arrangements.', Amount = original.Amount);
        Opportunity unchanged = state('EXHIBITOR');
        System.assertEquals(original.NTE_Listed_Price_Total__c, unchanged.NTE_Listed_Price_Total__c);
        System.assertEquals(0, unchanged.NTE_Price_Adjustment__c);
        update new Opportunity(Id = original.Id, Amount = 840);
        Test.stopTest();
        Opportunity revised = state('EXHIBITOR');
        System.assertEquals(700, revised.NTE_Listed_Price_Total__c);
        System.assertEquals('Review required', revised.NTE_Pricing_Status__c, 'A total edit must not silently approve unresolved selection checks.');
    }

    @IsTest
    static void ordinaryAndNewlyClassifiedOpportunitiesStayOutsideTheSynchroniser() {
        Opportunity original = state('EXHIBITOR');
        List<Opportunity> examples = new List<Opportunity>();
        for (String name : new List<String>{'ORDINARY', 'NO-EVENT', 'BECOMING-NTE', 'LEAVING-NTE'}) {
            examples.add(booking(original.AccountId, original.RecordTypeId, original.StageName, name, EXHIBITOR));
        }
        examples[0].NTE_Source_Form_Type__c = null;
        examples[1].NTE_Event_Code__c = null;
        examples[2].NTE_Source_Form_Type__c = null;
        examples[2].NTE_Event_Code__c = null;
        insert examples;
        Test.startTest();
        update new List<Opportunity>{
            new Opportunity(Id = examples[0].Id, Amount = -10),
            new Opportunity(Id = examples[1].Id, Amount = 840),
            new Opportunity(Id = examples[2].Id, Amount = 840, NTE_Source_Form_Type__c = EXHIBITOR, NTE_Event_Code__c = 'NTE2097'),
            new Opportunity(Id = examples[3].Id, Amount = 840, NTE_Source_Form_Type__c = null)
        };
        Test.stopTest();
        for (Opportunity example : examples) {
            Opportunity saved = state(example.Name);
            System.assertEquals(1000, saved.NTE_Listed_Price_Total__c, example.Name);
            System.assertEquals(0, saved.NTE_Price_Adjustment__c, example.Name);
        }
        System.assertEquals(-10, state('ORDINARY').Amount, 'The NTE Amount rule must not constrain an ordinary Opportunity.');
    }

    @IsTest
    static void initialNativeConversionKeepsCataloguePricingAndItsNewBookingGuard() {
        NTEInboundLeadService.bypassEmailDelivery = true;
        NTEExhibitorApprovalEmailService.bypassEmailDelivery = true;
        Lead application = new Lead(FirstName = 'Alex', LastName = 'Price Conversion', Company = 'Price Conversion',
            Email = 'price.conversion@example.invalid', Web_Form_Type__c = EXHIBITOR,
            NTE_Event_Code__c = 'NTE2097', Booking_Reference__c = 'NTE-PRICE-CONVERSION',
            Exhibitor_Organisation_Category__c = 'CIC or Not for Profit',
            Exhibitor_Space_Selections__c = 'Single Garage - Track Side - £799 + VAT',
            Planned_Exhibitor_Count__c = '2', Total_Staff_Count__c = 2, Stand_Power__c = 'No',
            Heavy_Vehicle_Required__c = 'No', Payment_Method__c = 'Bank transfer', Invoice_Requested__c = 'Yes');
        insert application;
        Database.LeadConvert conversion = new Database.LeadConvert();
        conversion.setLeadId(application.Id);
        conversion.setConvertedStatus([SELECT MasterLabel FROM LeadStatus WHERE IsConverted = true LIMIT 1].MasterLabel);
        conversion.setOpportunityName('Price Conversion');
        Test.startTest();
        Database.LeadConvertResult result = Database.convertLead(conversion);
        Test.stopTest();
        System.assert(result.isSuccess(), String.valueOf(result.getErrors()));
        Opportunity converted = state('Price Conversion - NTE2097');
        System.assertEquals(result.getOpportunityId(), converted.Id);
        System.assertEquals(799, converted.NTE_Exhibitor_Space_Price__c);
        System.assertEquals(799, converted.NTE_Listed_Price_Total__c);
        System.assertEquals(958.80, converted.Amount);
        System.assertEquals(0, converted.NTE_Price_Adjustment__c);
        System.assertEquals(null, converted.NTE_Approval_Email_Sent_At__c);
        System.assertEquals(0, [SELECT COUNT() FROM NTE_Payment_Request__c]);
        System.assertEquals(0, [SELECT COUNT() FROM NTE_Email_Dispatch__c]);
    }

    @IsTest
    static void explicitItemisedEditsArePreservedAndInvalidOnesAreNotDisguised() {
        Opportunity exhibitor = state('EXHIBITOR');
        Opportunity partner = state('PARTNER');
        Test.startTest();
        update new Opportunity(Id = exhibitor.Id, NTE_Exhibitor_Space_Price__c = 700,
            NTE_Listed_Price_Total__c = 900, Amount = 1080);
        Opportunity coherent = state('EXHIBITOR');
        System.assertEquals(700, coherent.NTE_Exhibitor_Space_Price__c);
        System.assertEquals(900, coherent.NTE_Listed_Price_Total__c);
        System.assertEquals(0, coherent.NTE_Price_Adjustment__c);
        update new Opportunity(Id = partner.Id, NTE_Sponsor_Package_Total__c = 1900, Amount = 1200);
        Opportunity inconsistent = state('PARTNER');
        System.assertEquals(1900, inconsistent.NTE_Sponsor_Package_Total__c);
        System.assertEquals(2100, inconsistent.NTE_Listed_Price_Total__c, 'A partially itemised edit must not manufacture a balancing discount.');
        System.assertEquals(0, inconsistent.NTE_Price_Adjustment__c);
        update new Opportunity(Id = exhibitor.Id, NTE_Power_Socket_Unit_Price__c = 75, Amount = 1200);
        Test.stopTest();
        Opportunity changedUnit = state('EXHIBITOR');
        System.assertEquals(75, changedUnit.NTE_Power_Socket_Unit_Price__c);
        System.assertEquals(100, changedUnit.NTE_Power_Socket_Total__c);
        System.assertEquals(900, changedUnit.NTE_Listed_Price_Total__c);
        System.assertEquals(0, changedUnit.NTE_Price_Adjustment__c);
    }

    @IsTest
    static void invalidRevisedTotalsFailOnlyTheirRowsWithoutMutatingPrices() {
        Opportunity exhibitor = state('EXHIBITOR');
        Opportunity partner = state('PARTNER');
        Test.startTest();
        Database.SaveResult[] results = Database.update(new List<Opportunity>{
            new Opportunity(Id = exhibitor.Id, Amount = null),
            new Opportunity(Id = partner.Id, Amount = 120)
        }, false);
        System.assertEquals(false, results[0].isSuccess());
        System.assert(results[0].getErrors()[0].getMessage().contains('booking total including VAT of £0 or more'));
        System.assertEquals(true, results[1].isSuccess());
        Database.SaveResult negative = Database.update(new Opportunity(Id = exhibitor.Id, Amount = -0.01), false);
        System.assertEquals(false, negative.isSuccess());
        Database.SaveResult invalidRate = Database.update(new Opportunity(Id = exhibitor.Id, Amount = 840, NTE_VAT_Rate__c = -100), false);
        System.assertEquals(false, invalidRate.isSuccess());
        System.assert(invalidRate.getErrors()[0].getMessage().contains('VAT rate between 0 and 100'));
        Test.stopTest();
        Opportunity unchanged = state('EXHIBITOR');
        System.assertEquals(1200, unchanged.Amount);
        System.assertEquals(1000, unchanged.NTE_Listed_Price_Total__c);
        System.assertEquals(20, unchanged.NTE_VAT_Rate__c);
        System.assertEquals(0, unchanged.NTE_Price_Adjustment__c);
        System.assertEquals(100, state('PARTNER').NTE_Listed_Price_Total__c);
    }

    @IsTest
    static void revisionsPreservePaidFactsTopUpsRequestsAndDispatchHistory() {
        Opportunity original = state('EXHIBITOR');
        update new Opportunity(Id = original.Id, NTE_Quote_Provided__c = true, NTE_Quote_Provided_At__c = RECORDED_AT,
            NTE_Quote_Provided_By__c = 'Original finance user', NTE_Invoice_Provided__c = true,
            NTE_Invoice_Provided_At__c = RECORDED_AT, NTE_Invoice_Provided_By__c = 'Original finance user',
            NTE_Payment_Received__c = true, NTE_Payment_Received_At__c = RECORDED_AT, NTE_Payment_Recorded_By__c = 'Original finance user',
            NTE_Approval_Email_Status__c = 'Sent', NTE_Approval_Email_Sent_At__c = RECORDED_AT,
            NTE_Top_Up_Staff_Required__c = 'Yes', NTE_Top_Up_Staff_Count__c = 2, NTE_Top_Up_Staff_Unit_Price__c = 60,
            NTE_Top_Up_Staff_Total__c = 120, NTE_Top_Up_VAT_Rate__c = 17.5, NTE_Top_Up_Staff_Names__c = 'Alex Smith\nJamie Jones',
            NTE_Top_Up_Invoice_Required__c = true, NTE_Top_Up_Invoice_Provided__c = true,
            NTE_Top_Up_Invoice_At__c = RECORDED_AT, NTE_Top_Up_Invoice_By__c = 'Original finance user',
            NTE_Top_Up_Payment_Requested_At__c = RECORDED_AT, NTE_Top_Up_Payment_Received__c = true,
            NTE_Top_Up_Payment_At__c = RECORDED_AT, NTE_Top_Up_Payment_By__c = 'Original finance user');
        insert new List<NTE_Payment_Request__c>{
            new NTE_Payment_Request__c(Opportunity__c = original.Id, Charge_Key__c = 'PRICE-ORIGINAL-BOOKING',
                Kind__c = 'Booking', Status__c = 'Ready', Net_Minor__c = 100000, Amount_Minor__c = 120000,
                Tax_Rate__c = 20, Currency__c = 'gbp', Delivered_At__c = RECORDED_AT, Source_Fingerprint__c = 'original-booking'),
            new NTE_Payment_Request__c(Opportunity__c = original.Id, Charge_Key__c = 'PRICE-ORIGINAL-TOPUP',
                Kind__c = 'Staff top-up', Status__c = 'Ready', Net_Minor__c = 12000, Amount_Minor__c = 14100,
                Tax_Rate__c = 17.5, Currency__c = 'gbp', Delivered_At__c = RECORDED_AT, Source_Fingerprint__c = 'original-topup')
        };
        insert new NTE_Email_Dispatch__c(Opportunity__c = original.Id, Dispatch_Key__c = 'PRICE-ORIGINAL-DISPATCH',
            Kind__c = 'Booking confirmation', Status__c = 'Sent', Recipient__c = 'original@example.invalid',
            Sent_At__c = RECORDED_AT, Subject__c = 'Original confirmation', Fingerprint__c = 'original-dispatch');
        String beforeFacts = financeFacts(original.Id);
        String beforeHistory = relatedHistory(original.Id);
        Test.startTest();
        update new Opportunity(Id = original.Id, Amount = 1440);
        update new Opportunity(Id = original.Id, Amount = 0);
        System.assertEquals(0, Limits.getEmailInvocations());
        System.assertEquals(0, Limits.getQueueableJobs());
        System.assertEquals(0, Limits.getCallouts());
        Test.stopTest();
        System.assertEquals(beforeFacts, financeFacts(original.Id));
        System.assertEquals(beforeHistory, relatedHistory(original.Id));
        Opportunity waived = state('EXHIBITOR');
        System.assertEquals(0, waived.Amount);
        System.assertEquals(-1000, waived.NTE_Price_Adjustment__c);
        System.assertEquals('No', waived.NTE_Invoice_Required__c);
        System.assertEquals(true, waived.NTE_Payment_Received__c);
        System.assertEquals('Yes', waived.NTE_Invoice_Requested__c);
    }

    private static String financeFacts(Id bookingId) {
        return JSON.serialize([SELECT NTE_Quote_Provided__c, NTE_Quote_Provided_At__c, NTE_Quote_Provided_By__c,
            NTE_Invoice_Provided__c, NTE_Invoice_Provided_At__c, NTE_Invoice_Provided_By__c,
            NTE_Invoice_Requested__c, NTE_Payment_Received__c, NTE_Payment_Received_At__c, NTE_Payment_Recorded_By__c,
            NTE_Approval_Email_Status__c, NTE_Approval_Email_Sent_At__c,
            NTE_Top_Up_Staff_Required__c, NTE_Top_Up_Staff_Count__c, NTE_Top_Up_Staff_Unit_Price__c,
            NTE_Top_Up_Staff_Total__c, NTE_Top_Up_VAT_Rate__c, NTE_Top_Up_Staff_Names__c,
            NTE_Top_Up_Invoice_Required__c, NTE_Top_Up_Invoice_Provided__c, NTE_Top_Up_Invoice_At__c, NTE_Top_Up_Invoice_By__c,
            NTE_Top_Up_Payment_Requested_At__c, NTE_Top_Up_Payment_Received__c, NTE_Top_Up_Payment_At__c, NTE_Top_Up_Payment_By__c
            FROM Opportunity WHERE Id = :bookingId]);
    }

    private static String relatedHistory(Id bookingId) {
        return JSON.serialize(new List<Object>{
            [SELECT Id, Charge_Key__c, Kind__c, Status__c, Net_Minor__c, Amount_Minor__c, Tax_Rate__c, Currency__c,
                Delivered_At__c, Source_Fingerprint__c, LastModifiedDate FROM NTE_Payment_Request__c
                WHERE Opportunity__c = :bookingId ORDER BY Id],
            [SELECT Id, Dispatch_Key__c, Kind__c, Status__c, Recipient__c, Sent_At__c, Subject__c, Fingerprint__c,
                LastModifiedDate FROM NTE_Email_Dispatch__c WHERE Opportunity__c = :bookingId ORDER BY Id]
        });
    }
}
