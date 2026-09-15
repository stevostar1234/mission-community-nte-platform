/** Require an unused Opportunity created in the conversion transaction for each NTE application. */
public without sharing class NTEConversionGuard {
    private static Set<Id> insertedBookings = new Set<Id>();
    private static Set<Id> claimedBookings = new Set<Id>();
    public static void remember(List<Opportunity> records) {
        for (Opportunity booking : records) insertedBookings.add(booking.Id);
    }
    public static void validate(List<Lead> records, Map<Id, Lead> before) {
        List<Lead> applications = new List<Lead>();
        Set<Id> ids = new Set<Id>();
        for (Lead application : records) {
            if (!application.IsConverted || before.get(application.Id).IsConverted
                || !new Set<String>{'Exhibitor Application', 'Partner / Sponsor Application'}.contains(application.Web_Form_Type__c)) continue;
            applications.add(application);
            if (application.ConvertedOpportunityId != null) ids.add(application.ConvertedOpportunityId);
        }
        if (applications.isEmpty()) return;
        Map<Id, Opportunity> bookings = new Map<Id, Opportunity>([SELECT Id, Name, AccountId,
            Booking_Reference__c, NTE_Source_Form_Type__c, NTE_Approval_Email_Lead_Id__c,
            NTE_Payment_Received__c, NTE_Top_Up_Payment_Received__c, NTE_Approval_Email_Sent_At__c
            FROM Opportunity WHERE Id IN :ids]);
        Set<Id> previouslyUsed = new Set<Id>();
        Set<Id> currentIds = new Map<Id, Lead>(applications).keySet();
        for (Lead other : [SELECT ConvertedOpportunityId FROM Lead WHERE IsConverted = true
            AND ConvertedOpportunityId IN :ids AND Id NOT IN :currentIds]) previouslyUsed.add(other.ConvertedOpportunityId);
        for (NTE_Payment_Request__c payment : [SELECT Opportunity__c FROM NTE_Payment_Request__c
            WHERE Opportunity__c IN :ids]) previouslyUsed.add(payment.Opportunity__c);
        List<Opportunity> names = new List<Opportunity>();
        for (Lead application : applications) {
            Opportunity booking = bookings.get(application.ConvertedOpportunityId);
            if (booking == null || !insertedBookings.contains(booking.Id) || claimedBookings.contains(booking.Id)
                || previouslyUsed.contains(booking.Id) || booking.AccountId != application.ConvertedAccountId
                || String.isNotBlank(booking.Booking_Reference__c) || String.isNotBlank(booking.NTE_Source_Form_Type__c)
                || String.isNotBlank(booking.NTE_Approval_Email_Lead_Id__c) || booking.NTE_Payment_Received__c
                || booking.NTE_Top_Up_Payment_Received__c || booking.NTE_Approval_Email_Sent_At__c != null) {
                application.addError('Create a new Opportunity for each NTE application. You can reuse the existing Account and Contact.');
                continue;
            }
            claimedBookings.add(booking.Id);
            if (String.isNotBlank(application.NTE_Event_Code__c)) {
                String suffix = ' - ' + application.NTE_Event_Code__c;
                String name = booking.Name;
                // Salesforce's untouched conversion form defaults to Company + '-'.
                if (name == application.Company + '-') name = application.Company;
                if (name != application.NTE_Event_Code__c && !name.endsWith(suffix) && !name.endsWith(' ' + application.NTE_Event_Code__c)) name = name.left(120 - suffix.length()) + suffix;
                names.add(new Opportunity(Id = booking.Id, Name = name));
            }
        }
        if (!names.isEmpty()) update names;
    }
}
