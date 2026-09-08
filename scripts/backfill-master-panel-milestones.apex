// One-time, idempotent MMUAT backfill for the eight documented release-qualification
// bookings that successfully completed both supplementary update forms on 2026-08-15.
Set<String> qualifiedBookingReferences = new Set<String>{
    'NTE-1786799885244-XSDKUCJ8',
    'NTE-1786799887533-NZ2R8DAS',
    'NTE-1786799889885-8XYMWE98',
    'NTE-1786799891618-6DCL5SMW',
    'NTE-1786799973244-BZV486XJ',
    'NTE-1786799974363-9HLYTNMW',
    'NTE-1786799975792-NDRBV6BJ',
    'NTE-1786799977222-7PHVVLQ9'
};

List<Opportunity> qualifiedBookings = [
    SELECT Id, Booking_Reference__c, NTE_Last_Update_Processed_At__c,
           NTE_Staff_Update_Completed_At__c, NTE_Heavy_Vehicle_Update_Completed_At__c
    FROM Opportunity
    WHERE Booking_Reference__c IN :qualifiedBookingReferences
];
System.assertEquals(8, qualifiedBookings.size(), 'All eight documented MMUAT qualification bookings must be present.');

List<Opportunity> updates = new List<Opportunity>();
for (Opportunity booking : qualifiedBookings) {
    System.assertNotEquals(null, booking.NTE_Last_Update_Processed_At__c,
        'A documented qualification booking must have a successful update audit time.');
    Opportunity updateRecord = new Opportunity(Id = booking.Id);
    Boolean changed = false;
    if (booking.NTE_Staff_Update_Completed_At__c == null) {
        updateRecord.NTE_Staff_Update_Completed_At__c = booking.NTE_Last_Update_Processed_At__c;
        changed = true;
    }
    if (booking.NTE_Heavy_Vehicle_Update_Completed_At__c == null) {
        updateRecord.NTE_Heavy_Vehicle_Update_Completed_At__c = booking.NTE_Last_Update_Processed_At__c;
        changed = true;
    }
    if (changed) updates.add(updateRecord);
}

if (!updates.isEmpty()) update updates;
System.debug(LoggingLevel.INFO, 'NTE Master Panel milestone backfill updated ' + updates.size() + ' bookings.');
