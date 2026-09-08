// Idempotent post-deploy classification for NTE Accounts and Contacts created before
// the NTE Management conversion flow began maintaining these fields.
Map<Id, Lead> latestByAccount = new Map<Id, Lead>();
Map<Id, Lead> latestByContact = new Map<Id, Lead>();

for (Lead converted : [
    SELECT ConvertedAccountId, ConvertedContactId, Booking_Reference__c,
           NTE_Event_Code__c, Web_Form_Type__c, ConvertedDate
    FROM Lead
    WHERE IsConverted = true
      AND ConvertedAccountId != null
      AND ConvertedContactId != null
      AND Web_Form_Type__c IN ('Partner / Sponsor Application', 'Exhibitor Application')
    ORDER BY ConvertedDate ASC, CreatedDate ASC
]) {
    latestByAccount.put(converted.ConvertedAccountId, converted);
    latestByContact.put(converted.ConvertedContactId, converted);
}

List<Account> accounts = new List<Account>();
for (Id accountId : latestByAccount.keySet()) {
    Lead source = latestByAccount.get(accountId);
    accounts.add(new Account(
        Id = accountId,
        NTE_Participant__c = true,
        NTE_Event_Code__c = source.NTE_Event_Code__c,
        NTE_Source_Form_Type__c = source.Web_Form_Type__c,
        NTE_Booking_Reference__c = source.Booking_Reference__c,
        NTE_Last_Application_Date__c = DateTime.newInstance(source.ConvertedDate, Time.newInstance(0, 0, 0, 0))
    ));
}

List<Contact> contacts = new List<Contact>();
for (Id contactId : latestByContact.keySet()) {
    Lead source = latestByContact.get(contactId);
    contacts.add(new Contact(
        Id = contactId,
        NTE_Participant__c = true,
        NTE_Event_Code__c = source.NTE_Event_Code__c,
        NTE_Source_Form_Type__c = source.Web_Form_Type__c,
        NTE_Booking_Reference__c = source.Booking_Reference__c,
        NTE_Last_Application_Date__c = DateTime.newInstance(source.ConvertedDate, Time.newInstance(0, 0, 0, 0)),
        NTE_Contact_Role__c = 'Applicant / event contact'
    ));
}

Database.SaveResult[] accountResults = Database.update(accounts, false);
Database.SaveResult[] contactResults = Database.update(contacts, false);
Integer accountFailures = 0;
Integer contactFailures = 0;
for (Database.SaveResult result : accountResults) if (!result.isSuccess()) accountFailures++;
for (Database.SaveResult result : contactResults) if (!result.isSuccess()) contactFailures++;

System.debug(LoggingLevel.INFO, 'NTE account classification: ' + accounts.size() + ' attempted, ' + accountFailures + ' failed.');
System.debug(LoggingLevel.INFO, 'NTE contact classification: ' + contacts.size() + ' attempted, ' + contactFailures + ' failed.');
System.assertEquals(0, accountFailures, 'All NTE Accounts must be classified.');
System.assertEquals(0, contactFailures, 'All NTE Contacts must be classified.');
