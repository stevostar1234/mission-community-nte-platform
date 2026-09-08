@IsTest
private class NTEMetadataReportStressTest {
    private static final String OPEN_STAGE = [SELECT MasterLabel FROM OpportunityStage
        WHERE IsActive = true AND IsClosed = false ORDER BY SortOrder LIMIT 1].MasterLabel;
    private static Opportunity booking(String name, Decimal listed, String pricingStatus,
        Boolean bookingInvoice, Boolean bookingPaid, Decimal topUp,
        Boolean topUpInvoice, Boolean topUpPaid) {
        return new Opportunity(
            Name = name, StageName = OPEN_STAGE, CloseDate = Date.today().addDays(30),
            NTE_Event_Code__c = 'NTE2097', Amount = listed,
            NTE_Listed_Price_Total__c = listed, NTE_Pricing_Status__c = pricingStatus,
            NTE_Invoice_Required__c = listed != null && listed > 0 ? 'Yes' : 'No',
            NTE_Quote_Required_for_PO__c = 'No', NTE_Invoice_Provided__c = bookingInvoice,
            NTE_Payment_Received__c = bookingPaid, NTE_Top_Up_Staff_Total__c = topUp,
            NTE_Top_Up_Invoice_Required__c = topUp != null && topUp > 0,
            NTE_Top_Up_Invoice_Provided__c = topUpInvoice,
            NTE_Top_Up_Payment_Received__c = topUpPaid
        );
    }

    @IsTest
    static void confirmedValueExcludesMissingAndInvalidPrices() {
        List<Opportunity> bookings = new List<Opportunity>{
            booking('Missing catalogue total', null, 'Calculated', false, false, 50, false, false),
            booking('Missing price and status', null, null, false, false, null, false, false),
            booking('Negative catalogue total', -10, 'Calculated', false, false, 50, false, false),
            booking('Unverified zero price', 0, null, false, false, 50, false, false),
            booking('Confirmed complimentary space', 0, 'Calculated', false, false, null, false, false),
            booking('Historical known price', 800, null, true, true, null, false, false),
            booking('Saved booking with top-up', 800, 'Calculated', true, true, 50, true, true),
            booking('Price needs review', 800, 'Review required', true, true, 50, true, true)
        };
        bookings[6].Amount = 700;
        insert bookings;
        Map<Id, Opportunity> actual = new Map<Id, Opportunity>([
            SELECT NTE_Confirmed_Value__c, NTE_Pricing_Ready__c,
                NTE_Finance_Invoice_Due__c, NTE_Finance_Payment_Due__c,
                NTE_Finance_Payment_Confirmed__c
            FROM Opportunity WHERE Id IN :bookings
        ]);
        for (Integer index : new List<Integer>{0, 1, 2, 3, 7}) {
            Opportunity record = actual.get(bookings[index].Id);
            System.assertEquals(null, record.NTE_Confirmed_Value__c, bookings[index].Name);
            System.assertEquals(false, record.NTE_Pricing_Ready__c, bookings[index].Name);
            System.assertEquals(true, record.NTE_Finance_Invoice_Due__c, bookings[index].Name);
            System.assertEquals(false, record.NTE_Finance_Payment_Due__c, bookings[index].Name);
            System.assertEquals(false, record.NTE_Finance_Payment_Confirmed__c, bookings[index].Name);
        }
        System.assertEquals(0, actual.get(bookings[4].Id).NTE_Confirmed_Value__c);
        System.assertEquals(800, actual.get(bookings[5].Id).NTE_Confirmed_Value__c);
        System.assertEquals(750, actual.get(bookings[6].Id).NTE_Confirmed_Value__c,
            'Keep the saved booking amount and add the accepted top-up exactly once.');
    }

    @IsTest
    static void nativeFinanceViewsFollowBothChargesAndBookingFirstOrder() {
        List<Opportunity> bookings = new List<Opportunity>{
            booking('Both invoices outstanding', 800, 'Calculated', false, false, 50, false, false),
            booking('Booking invoice and top-up invoice work', 800, 'Calculated', true, false, 50, false, false),
            booking('Paid booking needs top-up invoice', 800, 'Calculated', true, true, 50, false, false),
            booking('Paid booking needs top-up payment', 800, 'Calculated', true, true, 50, true, false),
            booking('Both invoiced and unpaid', 800, 'Calculated', true, false, 50, true, false),
            booking('All paid', 800, 'Calculated', true, true, 50, true, true),
            booking('Fully complimentary', 0, 'Calculated', false, false, 0, false, false),
            booking('Complimentary space with top-up invoice work', 0, 'Calculated', false, false, 50, false, false),
            booking('Complimentary space with top-up payment work', 0, 'Calculated', false, false, 50, true, false),
            booking('Complimentary space and paid top-up', 0, 'Calculated', false, false, 50, true, true),
            booking('Quote needed first', 800, 'Calculated', false, false, 0, false, false),
            booking('Top-up invoiced ahead of booking', 800, 'Calculated', false, false, 50, true, false),
            booking('Payment with missing invoice evidence', 800, 'Calculated', false, true, 0, false, false)
        };
        bookings[10].NTE_Quote_Required_for_PO__c = 'Yes';
        insert bookings;
        Set<String> invoiceExpected = new Set<String>{bookings[0].Name, bookings[1].Name,
            bookings[2].Name, bookings[7].Name, bookings[11].Name, bookings[12].Name};
        Set<String> paymentExpected = new Set<String>{bookings[1].Name, bookings[3].Name,
            bookings[4].Name, bookings[8].Name};
        Set<String> confirmedExpected = new Set<String>{bookings[5].Name, bookings[9].Name};
        System.assertEquals(invoiceExpected, names([
            SELECT Name FROM Opportunity WHERE Id IN :bookings AND NTE_Finance_Invoice_Due__c = true
        ]));
        System.assertEquals(paymentExpected, names([
            SELECT Name FROM Opportunity WHERE Id IN :bookings AND NTE_Finance_Payment_Due__c = true
        ]));
        System.assertEquals(confirmedExpected, names([
            SELECT Name FROM Opportunity WHERE Id IN :bookings AND NTE_Finance_Payment_Confirmed__c = true
        ]));
    }

    private static Set<String> names(List<Opportunity> records) {
        Set<String> result = new Set<String>();
        for (Opportunity record : records) result.add(record.Name);
        return result;
    }
}
