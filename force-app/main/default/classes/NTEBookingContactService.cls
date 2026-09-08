public inherited sharing class NTEBookingContactService {
    public static Map<Id, Contact> primaryContacts(Set<Id> bookingIds, AccessLevel accessLevel) {
        return primaryContacts(bookingIds, accessLevel, false);
    }

    // Senders hold the booking lock first, then keep the selected role and Contact stable
    // until the dispatch transaction commits. Panel reads do not need these locks.
    public static Map<Id, Contact> primaryContacts(Set<Id> bookingIds, AccessLevel accessLevel, Boolean lockRecords) {
        Map<Id, Contact> result = new Map<Id, Contact>();
        if (bookingIds == null || bookingIds.isEmpty()) return result;
        List<OpportunityContactRole> roles = (List<OpportunityContactRole>)Database.queryWithBinds(
            'SELECT OpportunityId, ContactId FROM OpportunityContactRole '
            + 'WHERE OpportunityId IN :bookingIds AND IsPrimary = true' + (lockRecords == true ? ' FOR UPDATE' : ''),
            new Map<String, Object>{'bookingIds' => bookingIds}, accessLevel
        );
        Map<Id, Id> contactIdsByBooking = singlePrimaryContactIds(roles);
        Set<Id> contactIds = new Set<Id>(contactIdsByBooking.values());
        if (contactIds.isEmpty()) return result;
        Map<Id, Contact> contacts = new Map<Id, Contact>((List<Contact>)Database.queryWithBinds(
            'SELECT Id, Name, FirstName, LastName, Email, Phone, MobilePhone FROM Contact WHERE Id IN :contactIds'
            + (lockRecords == true ? ' FOR UPDATE' : ''),
            new Map<String, Object>{'contactIds' => contactIds}, accessLevel
        ));
        for (Id bookingId : contactIdsByBooking.keySet()) {
            Contact primary = contacts.get(contactIdsByBooking.get(bookingId));
            if (primary != null) result.put(bookingId, primary);
        }
        return result;
    }

    @TestVisible
    private static Map<Id, Id> singlePrimaryContactIds(List<OpportunityContactRole> roles) {
        Map<Id, Id> result = new Map<Id, Id>();
        Set<Id> seen = new Set<Id>();
        Set<Id> ambiguous = new Set<Id>();
        for (OpportunityContactRole role : roles) {
            if (seen.contains(role.OpportunityId)) ambiguous.add(role.OpportunityId);
            seen.add(role.OpportunityId);
            if (role.ContactId != null) result.put(role.OpportunityId, role.ContactId);
        }
        for (Id bookingId : ambiguous) result.remove(bookingId);
        return result;
    }
}
