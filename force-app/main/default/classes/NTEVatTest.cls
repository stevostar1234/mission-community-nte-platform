@IsTest
private class NTEVatTest {
    @IsTest static void taxRoundsOncePerCharge() {
        System.assertEquals(0.51, NTEVat.tax(2.53, 20));
        System.assertEquals(3.04, NTEVat.gross(2.53, 20));
        System.assertEquals(17.50, NTEVat.tax(100, 17.5));
        System.assertEquals(0, NTEVat.gross(0, 20));
        System.assertEquals(null, NTEVat.gross(null, 20));
    }
    @IsTest static void inclusiveVatAcceptsPenceThatNetFirstRoundingCannotProduce() {
        System.assertEquals(0.01, NTEVat.taxFromGross(0.03, 20));
        System.assertEquals(0.02, NTEVat.netFromGross(0.03, 20));
        System.assertEquals(0.09, NTEVat.taxFromGross(0.51, null));
        System.assertEquals(0.42, NTEVat.netFromGross(0.51, null));
        System.assertEquals(0.50, NTEVat.gross(0.42, 20), 'The original catalogue calculation stays net first.');
        System.assertEquals(0.51, NTEVat.bookingGross(0.42, 20, 0.51));
        System.assertEquals(0.09, NTEVat.bookingTax(0.42, 20, 0.51));
        System.assert(NTEVat.consistentTotal(0.02, 20, 0.03));
        System.assert(NTEVat.consistentTotal(0.42, 20, 0.51));
        System.assert(!NTEVat.consistentTotal(0.41, 20, 0.51));
        System.assert(!NTEVat.consistentTotal(0.01, 20, 0.03));
        System.assertEquals(17.50, NTEVat.taxFromGross(117.50, 17.5));
        System.assertEquals(100, NTEVat.netFromGross(117.50, 17.5));
    }
    @IsTest static void inclusiveVatMatchesIntegerOracleAcrossEveryPennyAndSavedRate() {
        for (Integer ratePoints : new List<Integer>{0, 250, 500, 1750, 2000, 9999, 10000}) {
            Decimal savedRate = ratePoints; savedRate /= 100;
            Integer divisor = 10000 + ratePoints;
            for (Integer pennies = 0; pennies <= 1000; pennies++) {
                Decimal inclusive = pennies; inclusive /= 100;
                // Independent integer-ratio oracle: positive integer division truncates.
                Integer taxPennies = (2 * pennies * ratePoints + divisor) / (2 * divisor);
                Decimal expectedTax = taxPennies; expectedTax /= 100;
                Decimal net = NTEVat.netFromGross(inclusive, savedRate);
                System.assertEquals(expectedTax, NTEVat.taxFromGross(inclusive, savedRate), 'Gross=' + inclusive + ', rate=' + savedRate);
                System.assertEquals(inclusive, net + expectedTax);
                System.assertEquals(inclusive, NTEVat.bookingGross(net, savedRate, inclusive));
                System.assertEquals(expectedTax, NTEVat.bookingTax(net, savedRate, inclusive));
                System.assert(NTEVat.consistentTotal(net, savedRate, inclusive));
            }
        }
    }
    @IsTest static void netFirstVatRemainsConsistentAcrossEveryPennyAndSavedRate() {
        for (Integer ratePoints : new List<Integer>{0, 250, 500, 1750, 2000, 9999, 10000}) {
            Decimal savedRate = ratePoints; savedRate /= 100;
            for (Integer pennies = 0; pennies <= 1000; pennies++) {
                Decimal net = pennies; net /= 100;
                Integer taxPennies = (2 * pennies * ratePoints + 10000) / 20000;
                Decimal expectedTax = taxPennies; expectedTax /= 100;
                Decimal inclusive = net + expectedTax;
                System.assertEquals(expectedTax, NTEVat.tax(net, savedRate));
                System.assertEquals(inclusive, NTEVat.gross(net, savedRate));
                System.assertEquals(inclusive, NTEVat.bookingGross(net, savedRate, null));
                System.assertEquals(expectedTax, NTEVat.bookingTax(net, savedRate, null));
                System.assert(NTEVat.consistentTotal(net, savedRate, inclusive));
            }
        }
    }
    @IsTest static void savedGrossZeroAndMissingValuesKeepTheirMeaning() {
        System.assertEquals(0, NTEVat.taxFromGross(0, null));
        System.assertEquals(0, NTEVat.netFromGross(0, null));
        System.assertEquals(0, NTEVat.bookingGross(0, null, 0));
        System.assertEquals(0, NTEVat.bookingTax(0, null, 0));
        System.assertEquals(0, NTEVat.bookingGross(100, 20, 0), 'A supplied zero must not fall back to the catalogue amount.');
        System.assertEquals(120, NTEVat.bookingGross(100, null, null));
        System.assertEquals(20, NTEVat.bookingTax(100, null, null));
        System.assertEquals(null, NTEVat.taxFromGross(null, 20));
        System.assertEquals(null, NTEVat.netFromGross(null, 20));
        System.assertEquals(null, NTEVat.bookingTax(null, 20, 1));
        System.assertEquals(null, NTEVat.bookingGross(null, 20, null));
        System.assert(NTEVat.consistentTotal(100, 20, null));
        System.assert(!NTEVat.consistentTotal(null, 20, 1));
        System.assert(!NTEVat.consistentTotal(100, 20, 119.99));
        System.assert(!NTEVat.consistentTotal(100, 20, 120.01));
    }
    @IsTest static void applicationsApplyDiscountsBeforeVatAndKeepCatalogueNet() {
        List<Lead> cases = new List<Lead>{
            exhibitor('Single Garage - Track Side - £799 + VAT', 'Employer - Automotive Sector', 'No', 0, '2'),
            exhibitor('Blue Light - Single - £249.50 + VAT', 'Employer - Blue Light & NHS', 'Yes', 1, '3'),
            exhibitor('COBSEO Charity - Single - Free', 'Charity - member of Cobseo', 'No', 0, '2'),
            exhibitor('COBSEO Charity - Single - Free', 'Charity - member of Cobseo', 'Yes', 1, '3'),
            new Lead(Web_Form_Type__c='Partner / Sponsor Application', Sponsor_Package__c='Champion Partner;Helmet Bay Sponsor', Planned_Exhibitor_Count__c='8')
        };
        List<Decimal> nets = new List<Decimal>{799,349.50,0,100,5000};
        List<Decimal> taxes = new List<Decimal>{159.80,69.90,0,20,1000};
        List<Decimal> gross = new List<Decimal>{958.80,419.40,0,120,6000};
        for (Integer i=0;i<cases.size();i++) {
            Lead application=cases[i];application.VAT_Rate__c=0;application.VAT_Total__c=1;application.Total_Including_VAT__c=1;
            NTEPricingService.applyLeadPricing(application);
            System.assertEquals('Calculated', application.Pricing_Status__c);
            System.assertEquals(nets[i], application.Listed_Price_Total__c);
            System.assertEquals(20, application.VAT_Rate__c);
            System.assertEquals(taxes[i], application.VAT_Total__c);
            System.assertEquals(gross[i], application.Total_Including_VAT__c);
            NTEPricingService.applyLeadPricing(application);
            System.assertEquals(gross[i], application.Total_Including_VAT__c, 'Recalculation must not add VAT twice.');
        }
        System.assertEquals(249.50,cases[1].Exhibitor_Space_Price__c);
        System.assertEquals(50,cases[1].Power_Socket_Unit_Price__c);
        System.assertEquals(5000,cases[4].Sponsor_Package_Total__c);
    }
    @IsTest static void unknownPriceDoesNotShowPayableVatTotal() {
        Lead application=new Lead(Web_Form_Type__c='Partner / Sponsor Application', Sponsor_Package__c='Unknown;Champion Partner', Planned_Exhibitor_Count__c='2');
        NTEPricingService.applyLeadPricing(application);
        System.assertEquals('Review required',application.Pricing_Status__c);
        System.assertEquals(null,application.VAT_Total__c);
        System.assertEquals(null,application.Total_Including_VAT__c);
    }
    @IsTest static void nativeTotalsRetainSeparateBookingAndTopUpTaxFacts() {
        String stage=[SELECT MasterLabel FROM OpportunityStage WHERE IsActive=true AND IsClosed=false ORDER BY SortOrder LIMIT 1].MasterLabel;
        List<Opportunity> bookings=new List<Opportunity>{
            new Opportunity(Name='VAT saved rates',StageName=stage,CloseDate=Date.today(),NTE_Listed_Price_Total__c=100,NTE_Pricing_Status__c='Calculated',NTE_VAT_Rate__c=17.5,Amount=117.5,NTE_Top_Up_Staff_Total__c=50,NTE_Top_Up_VAT_Rate__c=20),
            new Opportunity(Name='VAT penny rounding',StageName=stage,CloseDate=Date.today(),NTE_Listed_Price_Total__c=0.03,NTE_Pricing_Status__c='Calculated',NTE_VAT_Rate__c=20,Amount=0.04,NTE_Top_Up_Staff_Total__c=0.03,NTE_Top_Up_VAT_Rate__c=20)
        };
        insert bookings;
        Map<Id,Opportunity> actual=new Map<Id,Opportunity>([SELECT NTE_VAT_Total__c,NTE_Total_Including_VAT__c,NTE_Top_Up_VAT_Total__c,NTE_Top_Up_Total_Inc_VAT__c,NTE_Confirmed_Value__c FROM Opportunity WHERE Id IN :bookings]);
        Opportunity rates=actual.get(bookings[0].Id);
        System.assertEquals(17.5,rates.NTE_VAT_Total__c);System.assertEquals(117.5,rates.NTE_Total_Including_VAT__c);
        System.assertEquals(10,rates.NTE_Top_Up_VAT_Total__c);System.assertEquals(60,rates.NTE_Top_Up_Total_Inc_VAT__c);System.assertEquals(177.5,rates.NTE_Confirmed_Value__c);
        System.assertEquals(0.08,actual.get(bookings[1].Id).NTE_Confirmed_Value__c,'Round each separately invoiced charge once.');
    }
    private static Lead exhibitor(String space,String category,String power,Decimal sockets,String staff) {
        return new Lead(Web_Form_Type__c='Exhibitor Application',Exhibitor_Space_Selections__c=space,Exhibitor_Organisation_Category__c=category,Stand_Power__c=power,Power_Socket_Count__c=sockets,Planned_Exhibitor_Count__c=staff);
    }
}
