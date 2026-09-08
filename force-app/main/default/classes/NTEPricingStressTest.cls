@IsTest
private class NTEPricingStressTest {
    private static final String EXHIBITOR = 'Exhibitor Application';
    private static final String PARTNER = 'Partner / Sponsor Application';
    private static final String COMMERCIAL = 'Employer - Automotive Sector';
    private static final String SINGLE = 'Single Garage - Track Side - £800 + VAT';
    private static final String FREE = 'COBSEO Charity - Single - Free';
    private static final Map<String, Decimal> SPACE_PRICES = new Map<String, Decimal>{
        'Garage Space - reduced size with power - £600 + VAT' => 600,
        'Single Garage - Paddock Side with power - £800 + VAT' => 800,
        'Double Garage - Paddock Side with power - £1,300 + VAT' => 1300,
        'Single Garage - Track Side - £800 + VAT' => 800,
        'Double Garage - Track Side - £1,300 + VAT' => 1300,
        'Clean Energy Zone - Single - £499 + VAT' => 499,
        'Clean Energy Zone - Double - £849 + VAT' => 849,
        'Built Environment Zone - Single - £499 + VAT' => 499,
        'Built Environment Zone - Double - £849 + VAT' => 849,
        'Manufacturing Zone - Single - £499 + VAT' => 499,
        'Manufacturing Zone - Double - £849 + VAT' => 849,
        'Defence & Security Zone - Single - £499 + VAT' => 499,
        'Defence & Security Zone - Double - £849 + VAT' => 849,
        'Digital and Technologies Zone - Single - £499 + VAT' => 499,
        'Digital and Technologies Zone - Double - £849 + VAT' => 849,
        'FM Zone - Single - £499 + VAT' => 499,
        'FM Zone - Double - £849 + VAT' => 849,
        'Professional & Financial Zone - Single - £499 + VAT' => 499,
        'Professional & Financial Zone - Double - £849 + VAT' => 849,
        'Training & Education Zone - Single - £499 + VAT' => 499,
        'Any other business - Single - £499 + VAT' => 499,
        'Any other business - Double - £849 + VAT' => 849,
        'Local Government Authority - Single - £249.50 + VAT' => 249.50,
        'Blue Light - Single - £249.50 + VAT' => 249.50,
        'Trade Association - Single - £499 + VAT' => 499,
        'COBSEO Charity - Single - Free' => 0,
        'Non COBSEO Charity - Single - Free' => 0
    };
    private static final Map<String, String> RESTRICTED_CATEGORIES = new Map<String, String>{
        'Local Government Authority - Single - £249.50 + VAT' => 'Local Government or LG related',
        'Blue Light - Single - £249.50 + VAT' => 'Employer - Blue Light & NHS',
        'Trade Association - Single - £499 + VAT' => 'Trade Association',
        'COBSEO Charity - Single - Free' => 'Charity - member of Cobseo',
        'Non COBSEO Charity - Single - Free' => 'Charity - not a member of Cobseo'
    };
    private static final Map<String, Decimal> PACKAGE_PRICES = new Map<String, Decimal>{
        'Headline Partner' => 30000, 'Gold Partner' => 15000, 'Premier Partner' => 7000,
        'Champion Partner' => 2000, 'Zone Sponsor' => 5000, 'Community Stage Sponsor' => 6000,
        'Podcast Corner Sponsor' => 6000, 'Event Guide Sponsor' => 5000,
        'Delegate Tote Bag Sponsor' => 5000, 'Helmet Bay Sponsor' => 3000,
        'Auditorium Sponsor' => 5000, 'Live Stream Sponsor' => 6000,
        'Wristband Sponsor' => 3000, 'Escapade Sponsor' => 9000
    };
    private static final Set<String> DISCOUNTED_CATEGORIES = new Set<String>{
        'Charity - member of Cobseo', 'Charity - not a member of Cobseo',
        'Government or Government Agency', 'Local Government or LG related',
        'Employer - Blue Light & NHS'
    };

    @IsTest
    static void everySpaceHasConsistentLeadAndBookingComponents() {
        Integer cases = 0;
        for (String space : SPACE_PRICES.keySet()) {
            Integer included = space.contains('Double') ? 4 : 2;
            String category = RESTRICTED_CATEGORIES.containsKey(space) ? RESTRICTED_CATEGORIES.get(space) : COMMERCIAL;
            for (Integer staff : new List<Integer>{1, included, included + 1, 99}) {
                for (Integer sockets : new List<Integer>{0, 1, 20}) {
                    Lead application = exhibitor(space, category, String.valueOf(staff), sockets == 0 ? 'No' : 'Yes', sockets);
                    Opportunity booking = bookingFrom(application);
                    NTEPricingService.applyLeadPricing(application);
                    NTEPricingService.applyOpportunityPricing(booking);
                    Decimal extraStaff = Math.max(0, staff - included);
                    Decimal socketRate = DISCOUNTED_CATEGORIES.contains(category) ? 50 : 100;
                    Decimal expected = SPACE_PRICES.get(space) + extraStaff * 50 + sockets * socketRate;
                    String label = space + ': ' + staff + ' people / ' + sockets + ' sockets';
                    System.assertEquals('Calculated', application.Pricing_Status__c, label);
                    System.assertEquals(included, application.Included_Staff_Count__c, label);
                    System.assertEquals(extraStaff * 50, application.Additional_Staff_Total__c, label);
                    System.assertEquals(sockets * socketRate, application.Power_Socket_Total__c, label);
                    System.assertEquals(expected, application.Listed_Price_Total__c, label);
                    System.assertEquals(expected, booking.Amount, label);
                    System.assertEquals(application.Listed_Price_Total__c, booking.NTE_Listed_Price_Total__c, label);
                    System.assertEquals(application.Invoice_Required__c, booking.NTE_Invoice_Required__c, label);
                    System.assertEquals(expected > 0 ? 'Yes' : 'No', application.Invoice_Required__c, label);
                    System.assertEquals(staff, booking.NTE_Initial_Staff_Count__c, label);
                    System.assertEquals(staff, booking.NTE_Total_Staff_Count__c, label);
                    cases++;
                }
            }
        }
        System.assertEquals(324, cases);
    }

    @IsTest
    static void everyCategoryUsesExactDiscountAndRestrictedSpaceRules() {
        List<String> categories = new List<String>();
        for (Schema.PicklistEntry entry : Lead.Exhibitor_Organisation_Category__c.getDescribe().getPicklistValues()) {
            if (entry.isActive()) categories.add(entry.getValue());
        }
        System.assertEquals(19, categories.size(), 'A new category needs its pricing eligibility reviewed.');
        for (String category : categories) {
            for (String space : SPACE_PRICES.keySet()) {
                Lead application = exhibitor(space, category, '4', 'Yes', 1);
                NTEPricingService.applyLeadPricing(application);
                Boolean eligible = !RESTRICTED_CATEGORIES.containsKey(space) || RESTRICTED_CATEGORIES.get(space) == category;
                System.assertEquals(eligible ? 'Calculated' : 'Review required', application.Pricing_Status__c, category + ' / ' + space);
                System.assertEquals(DISCOUNTED_CATEGORIES.contains(category) ? 50 : 100,
                    application.Power_Socket_Unit_Price__c, 'Power discount category: ' + String.valueOf(category));
                System.assertEquals('Yes', application.Invoice_Required__c);
            }
        }
    }

    @IsTest
    static void everySponsorAndPairUsesFixedPricesWithNoStaffOrPowerCharge() {
        List<String> names = new List<String>(PACKAGE_PRICES.keySet());
        Decimal allTotal = 0;
        for (Integer first = 0; first < names.size(); first++) {
            allTotal += PACKAGE_PRICES.get(names[first]);
            for (Integer second = first; second < names.size(); second++) {
                String selected = first == second ? names[first] : names[first] + ';' + names[second];
                Decimal expected = PACKAGE_PRICES.get(names[first]) + (first == second ? 0 : PACKAGE_PRICES.get(names[second]));
                assertPartnerPrice(selected, expected);
            }
        }
        assertPartnerPrice(String.join(names, ';'), allTotal);
        System.assertEquals(107000, allTotal);
    }

    @IsTest
    static void malformedDuplicateMissingAndRemovedPackagesCannotBecomeCalculated() {
        for (String selected : new List<String>{null, '', ' ', ';', ';;', 'Unknown Package',
            'Troops\' Track Day Partner', 'Champion Partner;Unknown Package',
            'Champion Partner;Champion Partner', 'Champion Partner; Champion Partner ',
            ';Champion Partner', 'Champion Partner;', 'Champion Partner;;Gold Partner'}) {
            Lead application = partner(selected);
            NTEPricingService.applyLeadPricing(application);
            System.assertEquals('Review required', application.Pricing_Status__c, 'Sponsor selection: ' + String.valueOf(selected));
            System.assertEquals('Yes', application.Invoice_Required__c, 'Sponsor selection: ' + String.valueOf(selected));
        }
        Lead duplicate = partner('Champion Partner;Champion Partner');
        NTEPricingService.applyLeadPricing(duplicate);
        System.assertEquals(2000, duplicate.Sponsor_Package_Total__c, 'Duplicated selections must not double the known package price.');
        assertPartnerPrice(' Champion Partner ; Gold Partner ', 17000);
    }

    @IsTest
    static void invalidStaffCountsNeverProduceComplimentaryOrNegativePricing() {
        for (String count : new List<String>{null, '', ' ', '-1', '0', '0.5', '1.5', '99.5', '100',
            '99999999999999999999999999999999999999999999999', 'NaN', 'Infinity', 'three', '£2', '2 people'}) {
            for (String formType : new List<String>{EXHIBITOR, PARTNER}) {
                Lead application = formType == EXHIBITOR
                    ? exhibitor(FREE, 'Charity - member of Cobseo', count, 'No', null) : partner('Champion Partner');
                application.Planned_Exhibitor_Count__c = count;
                NTEPricingService.applyLeadPricing(application);
                System.assertEquals('Review required', application.Pricing_Status__c, formType + ' / ' + count);
                System.assertEquals('Yes', application.Invoice_Required__c);
                System.assertEquals(0, application.Total_Staff_Count__c);
                System.assertEquals(0, application.Additional_Staff_Total__c);
                System.assert(application.Listed_Price_Total__c >= 0);
            }
        }
    }

    @IsTest
    static void invalidPowerCountsAreReviewWorkAndNoPowerIgnoresStaleCounts() {
        for (Decimal sockets : new List<Decimal>{null, -1, 0, 0.5, 1.5, 20.5, 21, 1000000000}) {
            Lead requested = exhibitor(FREE, 'Charity - member of Cobseo', '2', 'Yes', sockets);
            NTEPricingService.applyLeadPricing(requested);
            System.assertEquals('Review required', requested.Pricing_Status__c, 'Socket count: ' + String.valueOf(sockets));
            System.assertEquals('Yes', requested.Invoice_Required__c);
            System.assertEquals(0, requested.Power_Socket_Total__c);
            Lead notRequested = exhibitor(FREE, 'Charity - member of Cobseo', '2', 'No', sockets);
            NTEPricingService.applyLeadPricing(notRequested);
            System.assertEquals('Calculated', notRequested.Pricing_Status__c);
            System.assertEquals(0, notRequested.Listed_Price_Total__c);
            System.assertEquals('No', notRequested.Invoice_Required__c);
        }
        for (String answer : new List<String>{null, '', 'Unknown'}) {
            Lead application = exhibitor(SINGLE, COMMERCIAL, '2', answer, 1);
            NTEPricingService.applyLeadPricing(application);
            System.assertEquals('Review required', application.Pricing_Status__c, 'Power answer: ' + String.valueOf(answer));
        }
    }

    @IsTest
    static void missingUnknownOrLookalikeCategoriesCannotClaimAPowerDiscount() {
        for (String category : new List<String>{null, '', ' ', 'Charity', 'Government impostor',
            'Employer - Blue Light & NHS extra', 'Charity - member of COBSEO', 'charity - member of cobseo'}) {
            Lead application = exhibitor(SINGLE, category, '2', 'Yes', 1);
            Opportunity booking = bookingFrom(application);
            NTEPricingService.applyLeadPricing(application);
            NTEPricingService.applyOpportunityPricing(booking);
            System.assertEquals('Review required', application.Pricing_Status__c, 'Organisation category: ' + String.valueOf(category));
            System.assertEquals('Review required', booking.NTE_Pricing_Status__c, 'Organisation category: ' + String.valueOf(category));
            System.assertEquals(100, application.Power_Socket_Unit_Price__c, 'Organisation category: ' + String.valueOf(category));
            System.assertEquals('Yes', booking.NTE_Invoice_Required__c);
        }
    }

    @IsTest
    static void missingRemovedOrAlteredSpaceLabelsNeverInventFreePrices() {
        for (String space : new List<String>{null, '', 'Unknown Space', 'Extra Large Exhibitor Space - POA',
            'Single Garage - Track Side - £1 + VAT', SINGLE + ' ', SINGLE + ';' + FREE}) {
            Lead application = exhibitor(space, COMMERCIAL, '2', 'No', null);
            NTEPricingService.applyLeadPricing(application);
            System.assertEquals('Review required', application.Pricing_Status__c, 'Space selection: ' + String.valueOf(space));
            System.assertEquals('Yes', application.Invoice_Required__c);
            System.assertEquals(null, NTEPricingService.includedStaffForSpace(space));
        }
    }

    @IsTest
    static void applicantEnteredCountOverridesForgedDerivedTotalsAndPrices() {
        Lead application = exhibitor(SINGLE, COMMERCIAL, '7', 'Yes', 2);
        application.Total_Staff_Count__c = 2;
        application.Included_Staff_Count__c = 99;
        application.Additional_Staff_Count__c = '0';
        application.Additional_Staff_Required__c = 'No';
        application.Additional_Staff_Unit_Price__c = -999;
        application.Additional_Staff_Total__c = -999;
        application.Sponsor_Package_Total__c = -999;
        application.Exhibitor_Space_Price__c = 1;
        application.Power_Socket_Unit_Price__c = 0;
        application.Power_Socket_Total__c = 0;
        application.Listed_Price_Total__c = 1;
        application.Pricing_Status__c = 'Calculated';
        application.Pricing_Version__c = 'Forged version';
        application.Invoice_Required__c = 'No';
        NTEPricingService.applyLeadPricing(application);
        System.assertEquals(7, application.Total_Staff_Count__c);
        System.assertEquals(2, application.Included_Staff_Count__c);
        System.assertEquals('5', application.Additional_Staff_Count__c);
        System.assertEquals(250, application.Additional_Staff_Total__c);
        System.assertEquals(200, application.Power_Socket_Total__c);
        System.assertEquals(0, application.Sponsor_Package_Total__c);
        System.assertEquals(1250, application.Listed_Price_Total__c);
        System.assertEquals('Yes', application.Invoice_Required__c);
        System.assertEquals(NTEPricingService.CATALOG_VERSION, application.Pricing_Version__c);
        application.Planned_Exhibitor_Count__c = 'not a count';
        application.Total_Staff_Count__c = 2;
        NTEPricingService.applyLeadPricing(application);
        System.assertEquals('Review required', application.Pricing_Status__c,
            'A forged numeric hidden count cannot conceal an invalid visible count.');
    }

    @IsTest
    static void bookedInitialStaffAndSeparateFinanceFactsSurviveRecalculation() {
        Account organisation = new Account(Name = 'Alder Engineering');
        insert organisation;
        Datetime recordedAt = Datetime.newInstanceGMT(2026, 8, 12, 10, 30, 0);
        Opportunity booking = bookingFrom(exhibitor(SINGLE, COMMERCIAL, '9', 'Yes', 2));
        booking.AccountId = organisation.Id;
        booking.Name = 'Alder Engineering event booking';
        booking.StageName = [SELECT MasterLabel FROM OpportunityStage WHERE IsActive = true AND IsClosed = false ORDER BY SortOrder LIMIT 1].MasterLabel;
        booking.CloseDate = Date.today().addDays(30);
        booking.NTE_Initial_Staff_Count__c = 3;
        booking.NTE_Total_Staff_Count__c = 5;
        booking.NTE_Top_Up_Staff_Count__c = 2;
        booking.NTE_Top_Up_Staff_Unit_Price__c = 50;
        booking.NTE_Top_Up_Staff_Total__c = 100;
        booking.NTE_Invoice_Provided__c = true;
        booking.NTE_Invoice_Provided_At__c = recordedAt;
        booking.NTE_Invoice_Provided_By__c = 'Morgan Ellis';
        booking.NTE_Payment_Received__c = true;
        booking.NTE_Payment_Received_At__c = recordedAt;
        booking.NTE_Payment_Recorded_By__c = 'Morgan Ellis';
        booking.NTE_Top_Up_Invoice_Provided__c = true;
        booking.NTE_Top_Up_Invoice_At__c = recordedAt;
        booking.NTE_Top_Up_Invoice_By__c = 'Morgan Ellis';
        booking.NTE_Top_Up_Payment_Received__c = true;
        booking.NTE_Top_Up_Payment_At__c = recordedAt;
        booking.NTE_Top_Up_Payment_By__c = 'Morgan Ellis';
        booking.NTE_Final_Pack_Status__c = 'Sent';
        booking.Amount = 1050;
        booking.NTE_Listed_Price_Total__c = 1050;
        insert booking;
        Test.startTest();
        NTEPricingService.recalculateOpportunities(new Set<Id>{booking.Id});
        Test.stopTest();
        Opportunity saved = [SELECT Amount, NTE_Listed_Price_Total__c, NTE_Pricing_Status__c,
            NTE_Initial_Staff_Count__c, NTE_Total_Staff_Count__c, NTE_Additional_Staff_Total__c,
            NTE_Top_Up_Staff_Count__c, NTE_Top_Up_Staff_Unit_Price__c, NTE_Top_Up_Staff_Total__c,
            NTE_Invoice_Provided__c, NTE_Invoice_Provided_At__c, NTE_Invoice_Provided_By__c,
            NTE_Payment_Received__c, NTE_Payment_Received_At__c, NTE_Payment_Recorded_By__c,
            NTE_Top_Up_Invoice_Provided__c, NTE_Top_Up_Invoice_At__c, NTE_Top_Up_Invoice_By__c,
            NTE_Top_Up_Payment_Received__c, NTE_Top_Up_Payment_At__c, NTE_Top_Up_Payment_By__c,
            NTE_Final_Pack_Status__c, NTE_Confirmed_Value__c FROM Opportunity WHERE Id = :booking.Id];
        System.assertEquals('Calculated', saved.NTE_Pricing_Status__c);
        System.assertEquals(1050, saved.Amount);
        System.assertEquals(1050, saved.NTE_Listed_Price_Total__c);
        System.assertEquals(50, saved.NTE_Additional_Staff_Total__c);
        System.assertEquals(3, saved.NTE_Initial_Staff_Count__c);
        System.assertEquals(5, saved.NTE_Total_Staff_Count__c);
        System.assertEquals(2, saved.NTE_Top_Up_Staff_Count__c);
        System.assertEquals(50, saved.NTE_Top_Up_Staff_Unit_Price__c);
        System.assertEquals(100, saved.NTE_Top_Up_Staff_Total__c);
        System.assertEquals(1150, saved.NTE_Confirmed_Value__c);
        System.assertEquals(true, saved.NTE_Invoice_Provided__c);
        System.assertEquals(recordedAt, saved.NTE_Invoice_Provided_At__c);
        System.assertEquals('Morgan Ellis', saved.NTE_Invoice_Provided_By__c);
        System.assertEquals(true, saved.NTE_Payment_Received__c);
        System.assertEquals(recordedAt, saved.NTE_Payment_Received_At__c);
        System.assertEquals('Morgan Ellis', saved.NTE_Payment_Recorded_By__c);
        System.assertEquals(true, saved.NTE_Top_Up_Invoice_Provided__c);
        System.assertEquals(recordedAt, saved.NTE_Top_Up_Invoice_At__c);
        System.assertEquals('Morgan Ellis', saved.NTE_Top_Up_Invoice_By__c);
        System.assertEquals(true, saved.NTE_Top_Up_Payment_Received__c);
        System.assertEquals(recordedAt, saved.NTE_Top_Up_Payment_At__c);
        System.assertEquals('Morgan Ellis', saved.NTE_Top_Up_Payment_By__c);
        System.assertEquals('Sent', saved.NTE_Final_Pack_Status__c);
    }

    @IsTest
    static void bulkPersistedLeadPricingRestoresAllDerivedValues() {
        NTEInboundLeadService.bypassEmailDelivery = true;
        List<Lead> applications = new List<Lead>();
        for (Integer index = 0; index < 200; index++) {
            Lead application = exhibitor(SINGLE, COMMERCIAL, String.valueOf(Math.mod(index, 99) + 1), 'No', null);
            application.FirstName = 'Avery';
            application.LastName = 'Morgan';
            application.Company = 'Birch Design ' + index;
            application.Email = 'avery-' + index + '@example.invalid';
            applications.add(application);
        }
        insert applications;
        List<Lead> forged = new List<Lead>();
        for (Lead application : applications) {
            forged.add(new Lead(Id = application.Id, Total_Staff_Count__c = 1, Included_Staff_Count__c = 99,
                Listed_Price_Total__c = -1, Exhibitor_Space_Price__c = -1, Invoice_Required__c = 'No'));
        }
        update forged;
        Set<Id> ids = new Map<Id, Lead>(applications).keySet();
        Test.startTest();
        NTEPricingService.recalculateLeads(ids);
        Test.stopTest();
        List<Lead> saved = [SELECT Planned_Exhibitor_Count__c, Total_Staff_Count__c, Included_Staff_Count__c,
            Listed_Price_Total__c, Additional_Staff_Total__c, Pricing_Status__c, Invoice_Required__c FROM Lead WHERE Id IN :ids];
        System.assertEquals(200, saved.size());
        for (Lead application : saved) {
            Decimal people = Decimal.valueOf(application.Planned_Exhibitor_Count__c);
            System.assertEquals(people, application.Total_Staff_Count__c);
            System.assertEquals(2, application.Included_Staff_Count__c);
            System.assertEquals(Math.max(0, people - 2) * 50, application.Additional_Staff_Total__c);
            System.assertEquals(800 + Math.max(0, people - 2) * 50, application.Listed_Price_Total__c);
            System.assertEquals('Calculated', application.Pricing_Status__c);
            System.assertEquals('Yes', application.Invoice_Required__c);
        }
    }

    @IsTest
    static void conversionPricingUsesCurrentInputsInRequestOrderWithoutSaving() {
        NTEInboundLeadService.bypassEmailDelivery = true;
        Lead first = exhibitor(SINGLE, COMMERCIAL, '2', 'No', null);
        first.FirstName = 'Jordan'; first.LastName = 'Reed'; first.Company = 'Cedar Manufacturing';
        first.Email = 'jordan.reed@example.invalid';
        Lead second = partner('Champion Partner');
        second.FirstName = 'Robin'; second.LastName = 'Ellis'; second.Company = 'Elm Consulting';
        second.Email = 'robin.ellis@example.invalid';
        insert new List<Lead>{first, second};
        update new List<Lead>{
            new Lead(Id = first.Id, Planned_Exhibitor_Count__c = '7', Total_Staff_Count__c = 2,
                Listed_Price_Total__c = 1, Additional_Staff_Total__c = 0),
            new Lead(Id = second.Id, Sponsor_Package__c = 'Gold Partner;Champion Partner',
                Listed_Price_Total__c = 1, Sponsor_Package_Total__c = 1)
        };
        List<NTEPricingService.ConversionPricingRequest> requests = new List<NTEPricingService.ConversionPricingRequest>();
        for (Id leadId : new List<Id>{second.Id, first.Id, second.Id}) {
            NTEPricingService.ConversionPricingRequest request = new NTEPricingService.ConversionPricingRequest();
            request.leadId = leadId;
            requests.add(request);
        }
        Test.startTest();
        List<NTEPricingService.ConversionPricingResponse> responses = NTEPricingService.priceApplicationsForConversion(requests);
        Test.stopTest();
        System.assertEquals(3, responses.size());
        System.assertEquals(second.Id, responses[0].pricedLead.Id);
        System.assertEquals(17000, responses[0].pricedLead.Listed_Price_Total__c);
        System.assertEquals(first.Id, responses[1].pricedLead.Id);
        System.assertEquals(1050, responses[1].pricedLead.Listed_Price_Total__c);
        System.assertEquals(7, responses[1].pricedLead.Total_Staff_Count__c);
        System.assertEquals(250, responses[1].pricedLead.Additional_Staff_Total__c);
        System.assertEquals(second.Id, responses[2].pricedLead.Id);
        System.assertEquals(17000, responses[2].pricedLead.Listed_Price_Total__c);
        Set<Id> leadIds = new Set<Id>{first.Id, second.Id};
        for (Lead saved : [SELECT Listed_Price_Total__c FROM Lead WHERE Id IN :leadIds]) {
            System.assertEquals(1, saved.Listed_Price_Total__c, 'Conversion pricing returns a snapshot without changing source audit data.');
        }
    }

    @IsTest
    static void conversionPricingRejectsMissingOrNonApplicationRequests() {
        System.assertEquals(0, NTEPricingService.priceApplicationsForConversion(null).size());
        System.assertEquals(0, NTEPricingService.priceApplicationsForConversion(new List<NTEPricingService.ConversionPricingRequest>()).size());
        for (NTEPricingService.ConversionPricingRequest invalid : new List<NTEPricingService.ConversionPricingRequest>{null,
            new NTEPricingService.ConversionPricingRequest()}) {
            Boolean rejected = false;
            try { NTEPricingService.priceApplicationsForConversion(new List<NTEPricingService.ConversionPricingRequest>{invalid}); }
            catch (NTEPricingService.ConversionPricingException expected) { rejected = true; }
            System.assertEquals(true, rejected);
        }
        Lead unrelated = new Lead(FirstName = 'Alex', LastName = 'Lane', Company = 'Willow Services',
            Email = 'alex.lane@example.invalid');
        insert unrelated;
        NTEPricingService.ConversionPricingRequest request = new NTEPricingService.ConversionPricingRequest();
        request.leadId = unrelated.Id;
        Boolean rejected = false;
        try { NTEPricingService.priceApplicationsForConversion(new List<NTEPricingService.ConversionPricingRequest>{request}); }
        catch (NTEPricingService.ConversionPricingException expected) { rejected = true; }
        System.assertEquals(true, rejected);
    }

    @IsTest
    static void nonApplicationsNullInputsAndNumericLegacyCountsAreSafe() {
        NTEPricingService.recalculateLeads(null);
        NTEPricingService.recalculateLeads(new Set<Id>());
        NTEPricingService.recalculateOpportunities(null);
        NTEPricingService.recalculateOpportunities(new Set<Id>());
        NTEPricingService.applyLeadPricing(null);
        NTEPricingService.applyOpportunityPricing(null);
        Lead interest = new Lead(Web_Form_Type__c = 'Exhibitor Expression of Interest', Listed_Price_Total__c = 123);
        NTEPricingService.applyLeadPricing(interest);
        System.assertEquals(123, interest.Listed_Price_Total__c);
        Opportunity unrelated = new Opportunity(Amount = 321);
        NTEPricingService.applyOpportunityPricing(unrelated);
        System.assertEquals(321, unrelated.Amount);
        Lead legacy = exhibitor(SINGLE, COMMERCIAL, null, 'No', null);
        legacy.Total_Staff_Count__c = 3;
        NTEPricingService.applyLeadPricing(legacy);
        System.assertEquals(850, legacy.Listed_Price_Total__c);
        System.assertEquals('Calculated', legacy.Pricing_Status__c);
        System.assertEquals(249.50, NTEPricingService.componentTotal(null, 249.50, null, null));
        System.assertEquals(0, NTEPricingService.componentTotal(null, null, null, null));
    }

    private static Lead exhibitor(String space, String category, String staff, String power, Decimal sockets) {
        return new Lead(Web_Form_Type__c = EXHIBITOR, NTE_Event_Code__c = 'NTE2027', Exhibitor_Space_Selections__c = space,
            Exhibitor_Organisation_Category__c = category, Planned_Exhibitor_Count__c = staff,
            Stand_Power__c = power, Power_Socket_Count__c = sockets);
    }

    private static Lead partner(String packages) {
        return new Lead(Web_Form_Type__c = PARTNER, NTE_Event_Code__c = 'NTE2027', Sponsor_Package__c = packages,
            Planned_Exhibitor_Count__c = '99', Stand_Power__c = 'Yes', Power_Socket_Count__c = 20,
            Additional_Staff_Count__c = '97', Additional_Staff_Total__c = 4850);
    }

    private static void assertPartnerPrice(String selected, Decimal expected) {
        Lead application = partner(selected);
        Opportunity booking = bookingFrom(application);
        NTEPricingService.applyLeadPricing(application);
        NTEPricingService.applyOpportunityPricing(booking);
        System.assertEquals('Calculated', application.Pricing_Status__c, 'Sponsor selection: ' + String.valueOf(selected));
        System.assertEquals(expected, application.Sponsor_Package_Total__c, 'Sponsor selection: ' + String.valueOf(selected));
        System.assertEquals(expected, application.Listed_Price_Total__c, 'Sponsor selection: ' + String.valueOf(selected));
        System.assertEquals(0, application.Power_Socket_Total__c, 'Sponsor selection: ' + String.valueOf(selected));
        System.assertEquals(0, application.Additional_Staff_Total__c, 'Sponsor selection: ' + String.valueOf(selected));
        System.assertEquals(expected, booking.Amount, 'Sponsor selection: ' + String.valueOf(selected));
        System.assertEquals('Yes', booking.NTE_Invoice_Required__c, 'Sponsor selection: ' + String.valueOf(selected));
    }

    private static Opportunity bookingFrom(Lead application) {
        return new Opportunity(NTE_Source_Form_Type__c = application.Web_Form_Type__c, NTE_Event_Code__c = application.NTE_Event_Code__c,
            NTE_Sponsor_Package__c = application.Sponsor_Package__c,
            NTE_Exhibitor_Space_Selections__c = application.Exhibitor_Space_Selections__c,
            NTE_Exhibitor_Organisation_Category__c = application.Exhibitor_Organisation_Category__c,
            NTE_Stand_Power__c = application.Stand_Power__c,
            NTE_Power_Socket_Count__c = application.Power_Socket_Count__c,
            NTE_Planned_Exhibitor_Count__c = application.Planned_Exhibitor_Count__c);
    }
}
