public without sharing class NTEPricingService {
    public static final String CATALOG_VERSION = 'NTE27-2026-09-13-VAT';
    public static final Decimal POWER_STANDARD_PRICE = 100;
    public static final Decimal POWER_DISCOUNTED_PRICE = 50;
    public static final Decimal ADDITIONAL_STAFF_PRICE = 50;

    private static final Set<String> DISCOUNTED_POWER_CATEGORIES = new Set<String>{
        'Charity - member of Cobseo', 'Charity - not a member of Cobseo',
        'Government or Government Agency', 'Local Government or LG related',
        'Employer - Blue Light & NHS'
    };
    private static Set<String> activeExhibitorCategories;

    private static final Map<String, Decimal> SPONSOR_PACKAGE_PRICES = new Map<String, Decimal>{
        'Headline Partner' => 30000,
        'Gold Partner' => 15000,
        'Premier Partner' => 7000,
        'Champion Partner' => 2000,
        'Zone Sponsor' => 5000,
        'Community Stage Sponsor' => 6000,
        'Podcast Corner Sponsor' => 6000,
        'Event Guide Sponsor' => 5000,
        'Delegate Tote Bag Sponsor' => 5000,
        'Helmet Bay Sponsor' => 3000,
        'Auditorium Sponsor' => 5000,
        'Live Stream Sponsor' => 6000,
        'Wristband Sponsor' => 3000,
        'Escapade Sponsor' => 9000
    };

    private static final Map<String, Decimal> EXHIBITOR_SPACE_PRICES = new Map<String, Decimal>{
        'Garage Space - reduced size with power - £599 + VAT' => 599,
        'Single Garage - Paddock Side with power - £799 + VAT' => 799,
        'Double Garage - Paddock Side with power - £1,299 + VAT' => 1299,
        'Single Garage - Track Side - £799 + VAT' => 799,
        'Double Garage - Track Side - £1,299 + VAT' => 1299,
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
    private static final Set<String> FOUR_STAFF_SPACES = new Set<String>{
        'Double Garage - Paddock Side with power - £1,299 + VAT',
        'Double Garage - Track Side - £1,299 + VAT',
        'Clean Energy Zone - Double - £849 + VAT',
        'Built Environment Zone - Double - £849 + VAT',
        'Manufacturing Zone - Double - £849 + VAT',
        'Defence & Security Zone - Double - £849 + VAT',
        'Digital and Technologies Zone - Double - £849 + VAT',
        'FM Zone - Double - £849 + VAT',
        'Professional & Financial Zone - Double - £849 + VAT',
        'Any other business - Double - £849 + VAT'
    };

    private class PricingResult {
        Decimal sponsorTotal = 0;
        Decimal spacePrice = 0;
        Decimal powerUnitPrice = 0;
        Decimal powerTotal = 0;
        Decimal staffUnitPrice = 0;
        Decimal staffTotal = 0;
        Decimal includedStaffCount = 0;
        Decimal totalStaffCount = 0;
        Decimal additionalStaffCount = 0;
        Decimal listedTotal = 0;
        Boolean reviewRequired = false;

        String status() {
            if (reviewRequired) return 'Review required';
            return 'Calculated';
        }
    }

    public class ConversionPricingRequest {
        @InvocableVariable(required=true label='Application Lead ID')
        public Id leadId;
    }

    public class ConversionPricingResponse {
        @InvocableVariable(label='Priced application')
        public Lead pricedLead;
    }

    public class ConversionPricingException extends Exception {}

    @InvocableMethod(
        label='Calculate NTE Conversion Pricing'
        description='Calculates current application pricing for conversion without changing the Lead or an existing booking.'
    )
    public static List<ConversionPricingResponse> priceApplicationsForConversion(List<ConversionPricingRequest> requests) {
        List<ConversionPricingResponse> responses = new List<ConversionPricingResponse>();
        if (requests == null || requests.isEmpty()) return responses;
        Set<Id> leadIds = new Set<Id>();
        for (ConversionPricingRequest request : requests) {
            if (request == null || request.leadId == null) {
                throw new ConversionPricingException('An application Lead is required to calculate the booking price.');
            }
            leadIds.add(request.leadId);
        }
        Map<Id, Lead> applications = new Map<Id, Lead>(loadLeadsForPricing(leadIds));
        for (Lead application : applications.values()) applyLeadPricing(application);
        for (ConversionPricingRequest request : requests) {
            Lead application = applications.get(request.leadId);
            if (application == null || !isApplication(application.Web_Form_Type__c)) {
                throw new ConversionPricingException('The NTE application could not be found for booking pricing.');
            }
            ConversionPricingResponse response = new ConversionPricingResponse();
            response.pricedLead = application;
            responses.add(response);
        }
        return responses;
    }

    public static void recalculateLeads(Set<Id> leadIds) {
        if (leadIds == null || leadIds.isEmpty()) return;
        List<Lead> leads = loadLeadsForPricing(leadIds);
        for (Lead lead : leads) applyLeadPricing(lead);
        if (!leads.isEmpty()) Database.update(leads, false, AccessLevel.SYSTEM_MODE);
    }

    private static List<Lead> loadLeadsForPricing(Set<Id> leadIds) {
        return [
            SELECT Id, Web_Form_Type__c, Sponsor_Package__c, Exhibitor_Space_Selections__c,
                Exhibitor_Organisation_Category__c, Stand_Power__c, Power_Socket_Count__c,
                Planned_Exhibitor_Count__c, Total_Staff_Count__c, Included_Staff_Count__c,
                Additional_Staff_Required__c, Additional_Staff_Count__c, Invoice_Required__c
            FROM Lead WHERE Id IN :leadIds
        ];
    }

    public static void recalculateOpportunities(Set<Id> opportunityIds) {
        if (opportunityIds == null || opportunityIds.isEmpty()) return;
        List<Opportunity> opportunities = [
            SELECT Id, NTE_Source_Form_Type__c, NTE_Sponsor_Package__c, NTE_Exhibitor_Space_Selections__c,
                NTE_Exhibitor_Organisation_Category__c, NTE_Stand_Power__c, NTE_Power_Socket_Count__c,
                NTE_Planned_Exhibitor_Count__c, NTE_Initial_Staff_Count__c, NTE_Included_Staff_Count__c,
                NTE_Total_Staff_Count__c,
                NTE_Additional_Staff_Required__c, NTE_Additional_Staff_Count__c, NTE_Invoice_Required__c
            FROM Opportunity WHERE Id IN :opportunityIds
        ];
        for (Opportunity opportunity : opportunities) applyOpportunityPricing(opportunity);
        if (!opportunities.isEmpty()) Database.update(opportunities, false, AccessLevel.SYSTEM_MODE);
    }

    @TestVisible
    private static void applyLeadPricing(Lead lead) {
        if (lead == null || !isApplication(lead.Web_Form_Type__c)) return;
        PricingResult pricing = calculate(
            lead.Web_Form_Type__c,
            lead.Sponsor_Package__c,
            lead.Exhibitor_Space_Selections__c,
            lead.Exhibitor_Organisation_Category__c,
            lead.Stand_Power__c,
            lead.Power_Socket_Count__c,
            String.isNotBlank(lead.Planned_Exhibitor_Count__c)
                ? lead.Planned_Exhibitor_Count__c : String.valueOf(lead.Total_Staff_Count__c)
        );
        lead.Sponsor_Package_Total__c = pricing.sponsorTotal;
        lead.Exhibitor_Space_Price__c = pricing.spacePrice;
        lead.Power_Socket_Unit_Price__c = pricing.powerUnitPrice;
        lead.Power_Socket_Total__c = pricing.powerTotal;
        lead.Additional_Staff_Unit_Price__c = pricing.staffUnitPrice;
        lead.Additional_Staff_Total__c = pricing.staffTotal;
        lead.Total_Staff_Count__c = pricing.totalStaffCount;
        lead.Included_Staff_Count__c = pricing.includedStaffCount;
        lead.Additional_Staff_Required__c = pricing.additionalStaffCount > 0 ? 'Yes' : 'No';
        lead.Additional_Staff_Count__c = String.valueOf(pricing.additionalStaffCount.intValue());
        lead.Listed_Price_Total__c = pricing.listedTotal;
        lead.VAT_Rate__c = NTEVat.RATE;
        lead.VAT_Total__c = pricing.reviewRequired ? null : NTEVat.tax(pricing.listedTotal, lead.VAT_Rate__c);
        lead.Total_Including_VAT__c = pricing.reviewRequired ? null : NTEVat.gross(pricing.listedTotal, lead.VAT_Rate__c);
        lead.Pricing_Status__c = pricing.status();
        lead.Pricing_Version__c = CATALOG_VERSION;
        lead.Invoice_Required__c = pricing.listedTotal > 0 || pricing.reviewRequired ? 'Yes' : 'No';
    }

    @TestVisible
    private static void applyOpportunityPricing(Opportunity opportunity) {
        if (opportunity == null || !isApplication(opportunity.NTE_Source_Form_Type__c)) return;
        PricingResult pricing = calculate(
            opportunity.NTE_Source_Form_Type__c,
            opportunity.NTE_Sponsor_Package__c,
            opportunity.NTE_Exhibitor_Space_Selections__c,
            opportunity.NTE_Exhibitor_Organisation_Category__c,
            opportunity.NTE_Stand_Power__c,
            opportunity.NTE_Power_Socket_Count__c,
            opportunity.NTE_Initial_Staff_Count__c == null
                ? opportunity.NTE_Planned_Exhibitor_Count__c
                : String.valueOf(opportunity.NTE_Initial_Staff_Count__c)
        );
        opportunity.NTE_Sponsor_Package_Total__c = pricing.sponsorTotal;
        opportunity.NTE_Exhibitor_Space_Price__c = pricing.spacePrice;
        opportunity.NTE_Power_Socket_Unit_Price__c = pricing.powerUnitPrice;
        opportunity.NTE_Power_Socket_Total__c = pricing.powerTotal;
        opportunity.NTE_Additional_Staff_Unit_Price__c = pricing.staffUnitPrice;
        opportunity.NTE_Additional_Staff_Total__c = pricing.staffTotal;
        opportunity.NTE_Initial_Staff_Count__c = pricing.totalStaffCount;
        opportunity.NTE_Included_Staff_Count__c = pricing.includedStaffCount;
        opportunity.NTE_Additional_Staff_Required__c = pricing.additionalStaffCount > 0 ? 'Yes' : 'No';
        opportunity.NTE_Additional_Staff_Count__c = String.valueOf(pricing.additionalStaffCount.intValue());
        if (opportunity.NTE_Total_Staff_Count__c == null) opportunity.NTE_Total_Staff_Count__c = pricing.totalStaffCount;
        opportunity.NTE_Price_Adjustment__c = 0;
        opportunity.NTE_Listed_Price_Total__c = pricing.listedTotal;
        opportunity.NTE_Pricing_Status__c = pricing.status();
        opportunity.NTE_Pricing_Version__c = CATALOG_VERSION;
        opportunity.NTE_VAT_Rate__c = NTEVat.RATE;
        opportunity.Amount = pricing.reviewRequired ? null : NTEVat.gross(pricing.listedTotal, opportunity.NTE_VAT_Rate__c);
        opportunity.NTE_Invoice_Required__c = pricing.listedTotal > 0 || pricing.reviewRequired ? 'Yes' : 'No';
    }

    public static Decimal componentTotal(Decimal sponsorTotal, Decimal spacePrice, Decimal powerTotal, Decimal staffTotal) {
        return valueOrZero(sponsorTotal) + valueOrZero(spacePrice) + valueOrZero(powerTotal) + valueOrZero(staffTotal);
    }

    private static PricingResult calculate(
        String formType,
        String sponsorPackages,
        String exhibitorSpace,
        String category,
        String powerRequired,
        Decimal socketCount,
        String plannedStaffCount
    ) {
        PricingResult result = new PricingResult();
        result.totalStaffCount = decimalFromText(plannedStaffCount);
        if (result.totalStaffCount < 1 || result.totalStaffCount > 99 || result.totalStaffCount != result.totalStaffCount.setScale(0)) {
            result.reviewRequired = true;
            result.totalStaffCount = 0;
        }
        if (formType == 'Partner / Sponsor Application') {
            if (String.isBlank(sponsorPackages)) {
                result.reviewRequired = true;
            } else {
                Set<String> selectedPackages = new Set<String>();
                if (sponsorPackages.trim().startsWith(';') || sponsorPackages.trim().endsWith(';')) {
                    result.reviewRequired = true;
                }
                for (String packageName : sponsorPackages.split(';')) {
                    String normalized = packageName == null ? null : packageName.trim();
                    if (!SPONSOR_PACKAGE_PRICES.containsKey(normalized) || selectedPackages.contains(normalized)) {
                        result.reviewRequired = true;
                    } else {
                        selectedPackages.add(normalized);
                        result.sponsorTotal += SPONSOR_PACKAGE_PRICES.get(normalized);
                    }
                }
                if (selectedPackages.isEmpty()) result.reviewRequired = true;
            }
        } else if (formType == 'Exhibitor Application') {
            if (EXHIBITOR_SPACE_PRICES.containsKey(exhibitorSpace)) result.spacePrice = EXHIBITOR_SPACE_PRICES.get(exhibitorSpace);
            else result.reviewRequired = true;

            if (!isKnownExhibitorCategory(category)) {
                result.reviewRequired = true;
            }

            if (powerRequired == 'Yes') {
                Decimal validatedSocketCount = valueOrZero(socketCount);
                if (validatedSocketCount < 1 || validatedSocketCount > 20
                    || validatedSocketCount != validatedSocketCount.setScale(0)) {
                    result.reviewRequired = true;
                } else {
                    result.powerUnitPrice = qualifiesForPowerDiscount(category) ? POWER_DISCOUNTED_PRICE : POWER_STANDARD_PRICE;
                    result.powerTotal = result.powerUnitPrice * validatedSocketCount;
                }
            } else if (powerRequired != 'No') {
                result.reviewRequired = true;
            }
            Decimal includedStaff = includedStaffForSpace(exhibitorSpace);
            if (includedStaff != null) {
                result.includedStaffCount = includedStaff;
                result.additionalStaffCount = Math.max(0, result.totalStaffCount - includedStaff);
                result.staffUnitPrice = result.additionalStaffCount > 0 ? ADDITIONAL_STAFF_PRICE : 0;
                result.staffTotal = ADDITIONAL_STAFF_PRICE * result.additionalStaffCount;
            }
        }
        result.listedTotal = componentTotal(result.sponsorTotal, result.spacePrice, result.powerTotal, result.staffTotal);
        return result;
    }

    @TestVisible
    private static Decimal includedStaffForSpace(String spaceName) {
        if (String.isBlank(spaceName)) return null;
        if (!EXHIBITOR_SPACE_PRICES.containsKey(spaceName)) return null;
        return FOUR_STAFF_SPACES.contains(spaceName) ? 4 : 2;
    }

    private static Boolean isApplication(String formType) {
        return formType == 'Partner / Sponsor Application' || formType == 'Exhibitor Application';
    }

    private static Boolean qualifiesForPowerDiscount(String category) {
        return DISCOUNTED_POWER_CATEGORIES.contains(category);
    }

    private static Boolean isKnownExhibitorCategory(String category) {
        if (activeExhibitorCategories == null) {
            activeExhibitorCategories = new Set<String>();
            for (Schema.PicklistEntry entry : Lead.Exhibitor_Organisation_Category__c.getDescribe().getPicklistValues()) {
                if (entry.isActive()) activeExhibitorCategories.add(entry.getValue());
            }
        }
        return activeExhibitorCategories.contains(category);
    }

    private static Decimal decimalFromText(String value) {
        if (String.isBlank(value)) return 0;
        try {
            return Decimal.valueOf(value.trim());
        } catch (Exception ignored) {
            return 0;
        }
    }

    private static Decimal valueOrZero(Decimal value) {
        return value == null ? 0 : value;
    }
}
