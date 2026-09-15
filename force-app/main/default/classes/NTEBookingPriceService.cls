/** Keep an existing booking's agreed gross total and visible net adjustment together. */
public without sharing class NTEBookingPriceService {
    private static final Set<String> APPLICATION_TYPES = new Set<String>{
        'Exhibitor Application', 'Partner / Sponsor Application'
    };
    private static final List<String> ITEMISED_FIELDS = new List<String>{
        'NTE_Listed_Price_Total__c', 'NTE_Price_Adjustment__c',
        'NTE_Sponsor_Package_Total__c', 'NTE_Exhibitor_Space_Price__c',
        'NTE_Power_Socket_Count__c', 'NTE_Power_Socket_Unit_Price__c', 'NTE_Power_Socket_Total__c',
        'NTE_Additional_Staff_Count__c', 'NTE_Additional_Staff_Unit_Price__c', 'NTE_Additional_Staff_Total__c'
    };

    public static void applyAmountChanges(List<Opportunity> records, Map<Id, Opportunity> before) {
        for (Opportunity booking : records) {
            Opportunity previous = before.get(booking.Id);
            if (!isBooking(previous) || !isBooking(booking) || previous.Amount == booking.Amount
                || itemisedPriceChanged(booking, previous)) continue;
            if (booking.Amount == null || booking.Amount < 0) {
                booking.Amount.addError('Enter a booking total including VAT of £0 or more.');
                continue;
            }
            if (NTEVat.rate(booking.NTE_VAT_Rate__c) < 0 || NTEVat.rate(booking.NTE_VAT_Rate__c) > 100) {
                booking.NTE_VAT_Rate__c.addError('Enter a VAT rate between 0 and 100 before changing the booking total.');
                continue;
            }
            booking.Amount = booking.Amount.setScale(2, RoundingMode.HALF_UP);
            Decimal net = NTEVat.netFromGross(booking.Amount, booking.NTE_VAT_Rate__c);
            booking.NTE_Listed_Price_Total__c = net;
            booking.NTE_Price_Adjustment__c = net - NTEPricingService.componentTotal(
                booking.NTE_Sponsor_Package_Total__c, booking.NTE_Exhibitor_Space_Price__c,
                booking.NTE_Power_Socket_Total__c, booking.NTE_Additional_Staff_Total__c);
            booking.NTE_Invoice_Required__c = booking.Amount > 0 ? 'Yes' : 'No';
        }
    }

    private static Boolean isBooking(Opportunity booking) {
        return booking != null && APPLICATION_TYPES.contains(booking.NTE_Source_Form_Type__c)
            && String.isNotBlank(booking.NTE_Event_Code__c);
    }

    private static Boolean itemisedPriceChanged(Opportunity booking, Opportunity previous) {
        // An explicit itemised edit retains its own values and existing integrity checks.
        for (String fieldName : ITEMISED_FIELDS) {
            if (booking.get(fieldName) != previous.get(fieldName)) return true;
        }
        return false;
    }
}
