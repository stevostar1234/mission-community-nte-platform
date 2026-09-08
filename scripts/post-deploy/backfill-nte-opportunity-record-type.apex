RecordType nteOpportunityType = [
    SELECT Id
    FROM RecordType
    WHERE SobjectType = 'Opportunity'
      AND DeveloperName = 'NTE_Event_Opportunity'
    LIMIT 1
];

List<Opportunity> nteOpportunities = [
    SELECT Id, RecordTypeId
    FROM Opportunity
    WHERE NTE_Event_Code__c != null
      AND RecordTypeId != :nteOpportunityType.Id
];

for (Opportunity opportunityRecord : nteOpportunities) {
    opportunityRecord.RecordTypeId = nteOpportunityType.Id;
}

Database.SaveResult[] results = Database.update(nteOpportunities, false);
Integer updatedCount = 0;
List<String> failures = new List<String>();
for (Database.SaveResult result : results) {
    if (result.isSuccess()) {
        updatedCount++;
    } else {
        for (Database.Error error : result.getErrors()) {
            failures.add(String.valueOf(result.getId()) + ': ' + error.getMessage());
        }
    }
}

System.debug(LoggingLevel.INFO, 'NTE opportunity record types updated: ' + updatedCount);
System.assert(failures.isEmpty(), 'NTE opportunity record type backfill failures: ' + String.join(failures, ' | '));
