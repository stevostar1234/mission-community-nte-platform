@IsTest
private class NTEPricingServiceTest {
    @IsTest
    static void calculatesPartnerPackagesAndFlagsUnavailableSelections() {
        Lead priced = new Lead(
            Web_Form_Type__c = 'Partner / Sponsor Application',
            Sponsor_Package__c = 'Community Stage Sponsor;Delegate Tote Bag Sponsor',
            Planned_Exhibitor_Count__c = '7',
            Invoice_Required__c = 'No'
        );
        NTEPricingService.applyLeadPricing(priced);
        System.assertEquals(11000, priced.Sponsor_Package_Total__c);
        System.assertEquals(11000, priced.Listed_Price_Total__c);
        System.assertEquals('Calculated', priced.Pricing_Status__c);
        System.assertEquals('Yes', priced.Invoice_Required__c);

        Lead unavailable = new Lead(
            Web_Form_Type__c = 'Partner / Sponsor Application',
            Sponsor_Package__c = 'Troops\' Track Day Partner;Helmet Bay Sponsor',
            Planned_Exhibitor_Count__c = '12'
        );
        NTEPricingService.applyLeadPricing(unavailable);
        System.assertEquals(3000, unavailable.Sponsor_Package_Total__c);
        System.assertEquals(3000, unavailable.Listed_Price_Total__c);
        System.assertEquals('Review required', unavailable.Pricing_Status__c);
        System.assertEquals('Yes', unavailable.Invoice_Required__c, 'The known component is not the final price of an unsupported selection.');
    }

    @IsTest
    static void calculatesExhibitorComponentsAndDiscounts() {
        Lead commercial = new Lead(
            Web_Form_Type__c = 'Exhibitor Application',
            Exhibitor_Space_Selections__c = 'Single Garage - Paddock Side with power - £800 + VAT',
            Exhibitor_Organisation_Category__c = 'Employer - Automotive Sector',
            Stand_Power__c = 'Yes',
            Power_Socket_Count__c = 2,
            Planned_Exhibitor_Count__c = '7',
            Additional_Staff_Required__c = 'Yes',
            Additional_Staff_Count__c = '99'
        );
        NTEPricingService.applyLeadPricing(commercial);
        System.assertEquals(800, commercial.Exhibitor_Space_Price__c);
        System.assertEquals(100, commercial.Power_Socket_Unit_Price__c);
        System.assertEquals(200, commercial.Power_Socket_Total__c);
        System.assertEquals(50, commercial.Additional_Staff_Unit_Price__c);
        System.assertEquals(250, commercial.Additional_Staff_Total__c);
        System.assertEquals(2, commercial.Included_Staff_Count__c);
        System.assertEquals(7, commercial.Total_Staff_Count__c);
        System.assertEquals('5', commercial.Additional_Staff_Count__c);
        System.assertEquals(1250, commercial.Listed_Price_Total__c);

        Lead charity = new Lead(
            Web_Form_Type__c = 'Exhibitor Application',
            Exhibitor_Space_Selections__c = 'COBSEO Charity - Single - Free',
            Exhibitor_Organisation_Category__c = 'Charity - member of Cobseo',
            Stand_Power__c = 'Yes',
            Power_Socket_Count__c = 3,
            Planned_Exhibitor_Count__c = '2',
            Additional_Staff_Required__c = 'No',
            Invoice_Required__c = 'No'
        );
        NTEPricingService.applyLeadPricing(charity);
        System.assertEquals(0, charity.Exhibitor_Space_Price__c);
        System.assertEquals(50, charity.Power_Socket_Unit_Price__c);
        System.assertEquals(150, charity.Power_Socket_Total__c);
        System.assertEquals(150, charity.Listed_Price_Total__c);
        System.assertEquals('Yes', charity.Invoice_Required__c);

        Lead free = new Lead(
            Web_Form_Type__c = 'Exhibitor Application',
            Exhibitor_Space_Selections__c = 'Non COBSEO Charity - Single - Free',
            Exhibitor_Organisation_Category__c = 'Charity - not a member of Cobseo',
            Stand_Power__c = 'No',
            Planned_Exhibitor_Count__c = '2',
            Additional_Staff_Required__c = 'No',
            Invoice_Required__c = 'No'
        );
        NTEPricingService.applyLeadPricing(free);
        System.assertEquals(0, free.Listed_Price_Total__c);
        System.assertEquals('No', free.Invoice_Required__c);
    }

    @IsTest
    static void flagsUnknownSelectionsInsteadOfInventingPrices() {
        Lead lead = new Lead(
            Web_Form_Type__c = 'Exhibitor Application',
            Exhibitor_Space_Selections__c = 'Future space awaiting catalogue setup',
            Stand_Power__c = 'No',
            Planned_Exhibitor_Count__c = '2',
            Additional_Staff_Required__c = 'No'
        );
        NTEPricingService.applyLeadPricing(lead);
        System.assertEquals(0, lead.Listed_Price_Total__c);
        System.assertEquals('Review required', lead.Pricing_Status__c);
        System.assertEquals(NTEPricingService.CATALOG_VERSION, lead.Pricing_Version__c);
        System.assertEquals('Yes', lead.Invoice_Required__c);

        Opportunity unavailable = new Opportunity(
            NTE_Source_Form_Type__c = 'Exhibitor Application',
            NTE_Exhibitor_Space_Selections__c = 'Extra Large Exhibitor Space - POA',
            NTE_Exhibitor_Organisation_Category__c = 'CIC or Not for Profit',
            NTE_Stand_Power__c = 'No',
            NTE_Planned_Exhibitor_Count__c = '2',
            NTE_Invoice_Required__c = 'No'
        );
        NTEPricingService.applyOpportunityPricing(unavailable);
        System.assertEquals('Review required', unavailable.NTE_Pricing_Status__c);
        System.assertEquals('Yes', unavailable.NTE_Invoice_Required__c, 'A removed space is not a complimentary booking.');
        System.assertEquals(0, unavailable.Amount);
        System.assertEquals(NTEPricingService.CATALOG_VERSION, unavailable.NTE_Pricing_Version__c);
        System.assertEquals(null, NTEPricingService.includedStaffForSpace(unavailable.NTE_Exhibitor_Space_Selections__c));
    }

    @IsTest
    static void preventsRestrictedSpaceEligibilityBypass() {
        Lead ineligibleFreeSpace = new Lead(
            Web_Form_Type__c = 'Exhibitor Application',
            Exhibitor_Space_Selections__c = 'COBSEO Charity - Single - Free',
            Exhibitor_Organisation_Category__c = 'Employer - Automotive Sector',
            Stand_Power__c = 'No',
            Planned_Exhibitor_Count__c = '2',
            Additional_Staff_Required__c = 'No',
            Invoice_Required__c = 'No'
        );
        NTEPricingService.applyLeadPricing(ineligibleFreeSpace);
        System.assertEquals('Review required', ineligibleFreeSpace.Pricing_Status__c);
        System.assertEquals('Yes', ineligibleFreeSpace.Invoice_Required__c);

        Opportunity ineligibleDiscount = new Opportunity(
            NTE_Source_Form_Type__c = 'Exhibitor Application',
            NTE_Exhibitor_Space_Selections__c = 'Blue Light - Single - £249.50 + VAT',
            NTE_Exhibitor_Organisation_Category__c = 'Employer - Manufacturing Sector',
            NTE_Stand_Power__c = 'No',
            NTE_Planned_Exhibitor_Count__c = '2',
            NTE_Additional_Staff_Required__c = 'No',
            NTE_Invoice_Required__c = 'No'
        );
        NTEPricingService.applyOpportunityPricing(ineligibleDiscount);
        System.assertEquals('Review required', ineligibleDiscount.NTE_Pricing_Status__c);
        System.assertEquals('Yes', ineligibleDiscount.NTE_Invoice_Required__c);
    }

    @IsTest
    static void derivesLargeSpaceAllowanceAndRejectsInvalidStaffTotals() {
        Lead large = new Lead(
            Web_Form_Type__c = 'Exhibitor Application',
            Exhibitor_Space_Selections__c = 'Double Garage - Track Side - £1,300 + VAT',
            Exhibitor_Organisation_Category__c = 'Employer - Automotive Sector',
            Stand_Power__c = 'No',
            Planned_Exhibitor_Count__c = '7'
        );
        NTEPricingService.applyLeadPricing(large);
        System.assertEquals(4, large.Included_Staff_Count__c);
        System.assertEquals('3', large.Additional_Staff_Count__c);
        System.assertEquals(150, large.Additional_Staff_Total__c);
        System.assertEquals(1450, large.Listed_Price_Total__c);

        Lead invalid = new Lead(
            Web_Form_Type__c = 'Exhibitor Application',
            Exhibitor_Space_Selections__c = 'Single Garage - Track Side - £800 + VAT',
            Exhibitor_Organisation_Category__c = 'Employer - Automotive Sector',
            Stand_Power__c = 'No',
            Planned_Exhibitor_Count__c = '100'
        );
        NTEPricingService.applyLeadPricing(invalid);
        System.assertEquals('Review required', invalid.Pricing_Status__c);
    }
}
