/** Independent procurement checklist and explicit finance actions for NTE bookings. */
public with sharing class NTEFinanceService {
    public static final String FIELDS = 'NTE_Invoice_Requested__c, NTE_PO_Confirmed__c, NTE_Agreement_Provided__c, NTE_Invoice_Details_Included__c, '
        + 'NTE_Bank_Details_Provided__c, NTE_Purchase_Order__c, NTE_Purchase_Order_Number__c, '
        + 'NTE_Supplier_Agreement_Required__c, NTE_Invoice_Additional_Information__c, '
        + 'NTE_Invoiced_Company__c, NTE_Trading_Name__c, NTE_Invoice_Address__c, '
        + 'NTE_Invoiced_Person__c, NTE_Invoiced_Email__c, NTE_Invoice_Contact_Phone__c, '
        + 'NTE_Top_Up_Payment_Requested_At__c, NTE_Finance_Requirements_Due__c';
    public class Requirement {
        @AuraEnabled public String key;
        @AuraEnabled public String label;
        @AuraEnabled public String detail;
        @AuraEnabled public Boolean completed;
        public Requirement(String api, String text, String value, Boolean done) {
            key = api; label = text; detail = value; completed = done == true;
        }
    }
    public static List<Requirement> requirements(Opportunity booking) {
        List<Requirement> result = new List<Requirement>();
        String documentNames = billingNames(booking);
        if (booking.NTE_Quote_Required_for_PO__c == 'Yes') result.add(new Requirement('NTE_Quote_Provided__c', 'Quotation', documentNames, booking.NTE_Quote_Provided__c));
        if (booking.NTE_Invoice_Requested__c == 'Yes' && (booking.NTE_Listed_Price_Total__c > 0 || booking.Amount > 0)) result.add(new Requirement('NTE_Invoice_Provided__c', 'Invoice', documentNames, booking.NTE_Invoice_Provided__c));
        if (booking.NTE_Purchase_Order__c == 'Yes' || String.isNotBlank(booking.NTE_Purchase_Order_Number__c)) result.add(new Requirement('NTE_PO_Confirmed__c', 'Purchase order / reference', booking.NTE_Purchase_Order_Number__c, booking.NTE_PO_Confirmed__c));
        if (booking.NTE_Supplier_Agreement_Required__c == 'Yes' || booking.NTE_Supplier_Agreement_Required__c == 'Don\'t know') result.add(new Requirement('NTE_Agreement_Provided__c', 'Supplier agreement', booking.NTE_Supplier_Agreement_Required__c == 'Yes' ? 'Supplier agreement requested' : 'Applicant unsure', booking.NTE_Agreement_Provided__c));
        if (String.isNotBlank(booking.NTE_Invoice_Additional_Information__c)) result.add(new Requirement('NTE_Invoice_Details_Included__c', 'Additional quotation / invoice details', booking.NTE_Invoice_Additional_Information__c, booking.NTE_Invoice_Details_Included__c));
        if (booking.NTE_Top_Up_Staff_Total__c > 0 && booking.NTE_Invoice_Requested__c == 'Yes') result.add(new Requirement('NTE_Top_Up_Invoice_Provided__c', 'Staff top-up invoice', documentNames, booking.NTE_Top_Up_Invoice_Provided__c));
        if (booking.NTE_Payment_Method__c == 'Bank transfer' && (booking.NTE_Listed_Price_Total__c > 0 || booking.Amount > 0)) result.add(new Requirement('NTE_Bank_Details_Provided__c', 'Provided Bank details for Bank transfer', null, booking.NTE_Bank_Details_Provided__c));
        return result;
    }
    private static String billingNames(Opportunity booking) {
        List<String> names = new List<String>();
        if (String.isNotBlank(booking.NTE_Invoiced_Company__c)) names.add('Name: ' + booking.NTE_Invoiced_Company__c.trim());
        if (String.isNotBlank(booking.NTE_Trading_Name__c)) names.add('Trading name: ' + booking.NTE_Trading_Name__c.trim());
        return names.isEmpty() ? null : String.join(names, '\n');
    }
    public static String billingDetails(Opportunity booking) {
        List<String> values = new List<String>();
        for (String api : new List<String>{'NTE_Invoiced_Company__c', 'NTE_Trading_Name__c', 'NTE_Invoice_Address__c', 'NTE_Invoiced_Person__c', 'NTE_Invoiced_Email__c', 'NTE_Invoice_Contact_Phone__c'}) {
            String value = (String)booking.get(api);
            if (String.isNotBlank(value)) values.add(value);
        }
        return String.join(values, '\n');
    }
    private static Opportunity current(Id bookingId) {
        if (bookingId == null || bookingId.getSObjectType() != Opportunity.SObjectType) throw handled('Select an NTE booking.');
        List<Opportunity> found = (List<Opportunity>)Database.queryWithBinds('SELECT Id, ' + FIELDS + ', '
            + 'NTE_Quote_Required_for_PO__c, NTE_Quote_Provided__c, NTE_Invoice_Provided__c, NTE_Top_Up_Invoice_Provided__c, '
            + 'NTE_Listed_Price_Total__c, Amount, NTE_VAT_Rate__c, NTE_Pricing_Status__c, NTE_Payment_Method__c, NTE_Payment_Received__c, '
            + 'NTE_Top_Up_Staff_Total__c, NTE_Top_Up_Payment_Received__c, NTE_Approval_Email_Status__c, NTE_Approval_Email_Sent_At__c, NTE_Free_Space_Confirmed__c, '
            + 'NTE_Final_Pack_Status__c FROM Opportunity WHERE Id = :id AND RecordType.DeveloperName = \'NTE_Event_Opportunity\' '
            + 'AND NTE_Event_Code__c != null AND NTE_Source_Form_Type__c IN (\'Exhibitor Application\', \'Partner / Sponsor Application\') '
            + 'AND (IsClosed = false OR IsWon = true) FOR UPDATE', new Map<String,Object>{'id'=>bookingId}, AccessLevel.USER_MODE);
        if (found.isEmpty() || !Schema.sObjectType.Opportunity.isUpdateable()) throw handled('Select an active NTE booking you can update.');
        return found[0];
    }
    @AuraEnabled public static void setRequirement(Id opportunityId, String requirement, Boolean completed) {
        Opportunity booking = current(opportunityId);
        Boolean found = false;
        for (Requirement item : requirements(booking)) if (item.key == requirement) found = true;
        if (!found || completed == null) throw handled('This requirement does not apply to the booking. Refresh and try again.');
        if ((Boolean)booking.get(requirement) == completed) return;
        Opportunity change = new Opportunity(Id=booking.Id); change.put(requirement, completed);
        Map<String,List<String>> audit = new Map<String,List<String>>{
            'NTE_Quote_Provided__c'=>new List<String>{'NTE_Quote_Provided_At__c','NTE_Quote_Provided_By__c'},
            'NTE_Invoice_Provided__c'=>new List<String>{'NTE_Invoice_Provided_At__c','NTE_Invoice_Provided_By__c'},
            'NTE_Top_Up_Invoice_Provided__c'=>new List<String>{'NTE_Top_Up_Invoice_At__c','NTE_Top_Up_Invoice_By__c'}
        };
        if (audit.containsKey(requirement)) { change.put(audit.get(requirement)[0], completed ? System.now() : null); change.put(audit.get(requirement)[1], completed ? UserInfo.getName() : null); }
        Database.update(change, AccessLevel.USER_MODE);
    }
    @AuraEnabled public static void setJoiningInstructions(Id opportunityId, Boolean completed) {
        Opportunity booking = current(opportunityId);
        if (completed == null) throw handled('Select whether the joining instructions have been sent.');
        if ((booking.NTE_Final_Pack_Status__c == 'Sent') == completed) return;
        Database.update(new Opportunity(Id=booking.Id, NTE_Final_Pack_Status__c=completed ? 'Sent' : null,
            NTE_Final_Pack_Sent_At__c=completed ? System.now() : null,
            NTE_Joining_Instructions_By__c=completed ? UserInfo.getName() : null), AccessLevel.USER_MODE);
    }
    @AuraEnabled public static NTEExhibitorApprovalEmailService.ApprovalRetryResult sendFinanceAction(Id opportunityId, String actionName) {
        Opportunity booking = current(opportunityId);
        Decimal gross = NTEVat.bookingGross(booking.NTE_Listed_Price_Total__c, booking.NTE_VAT_Rate__c, booking.Amount);
        if (booking.NTE_Listed_Price_Total__c == null || booking.NTE_Listed_Price_Total__c < 0
            || (booking.NTE_Pricing_Status__c != 'Calculated' && !(String.isBlank(booking.NTE_Pricing_Status__c) && gross > 0))) throw handled('Check the booking pricing before sending.');
        if (actionName == 'TOP_UP') {
            try { NTEStripeBookingService.requestTopUp(booking.Id); } catch (NTEStripeBookingService.TopUpException failure) { throw handled(failure.getMessage()); }
            NTEExhibitorApprovalEmailService.ApprovalRetryResult result=new NTEExhibitorApprovalEmailService.ApprovalRetryResult();
            result.queuedCount=1; result.message='Staff top-up payment email queued.'; return result;
        }
        String expected = gross == 0 ? 'FREE' : booking.NTE_Payment_Method__c == 'Stripe' ? 'STRIPE' : booking.NTE_Payment_Method__c == 'Bank transfer' ? 'BANK' : null;
        if (expected == null || actionName != expected) throw handled('The payment method changed. Refresh the booking before sending.');
        if (expected == 'FREE' && booking.NTE_Free_Space_Confirmed__c) throw handled('The free space has already been confirmed.');
        if (booking.NTE_Payment_Received__c) throw handled('The booking payment has already been received.');
        if (expected != 'FREE' && (booking.NTE_Approval_Email_Status__c == 'Sent' || booking.NTE_Approval_Email_Sent_At__c != null))
            throw handled('The booking payment request has already been sent. Refresh to record payment when it is received.');
        return NTEExhibitorApprovalEmailService.sendManually(booking.Id);
    }
    private static AuraHandledException handled(String message) { AuraHandledException error = new AuraHandledException(message); error.setMessage(message); return error; }
}
