LeadStatus convertedStatus = [
    SELECT MasterLabel
    FROM LeadStatus
    WHERE IsConverted = true
    LIMIT 1
];

List<Lead> qaLeads = [
    SELECT Id, Company, Email, Web_Form_Type__c
    FROM Lead
    WHERE (
        Email LIKE 'skybasteven+nte-qa-exhib-%@gmail.com'
        OR Email LIKE 'skybasteven+nte-qa-partner-%@gmail.com'
    )
    AND Email NOT IN (
        'skybasteven+nte-qa-exhib-06@gmail.com',
        'skybasteven+nte-qa-partner-06@gmail.com'
    )
    AND IsConverted = false
    ORDER BY Email
];

System.assertEquals(10, qaLeads.size(), 'Expected exactly ten unconverted QA application Leads.');

List<Database.LeadConvert> requests = new List<Database.LeadConvert>();
for (Lead qaLead : qaLeads) {
    Database.LeadConvert request = new Database.LeadConvert();
    request.setLeadId(qaLead.Id);
    request.setConvertedStatus(convertedStatus.MasterLabel);
    request.setOpportunityName('NTE27 QA - ' + qaLead.Company);
    requests.add(request);
}

List<Database.LeadConvertResult> results = Database.convertLead(requests, false);
for (Integer index = 0; index < results.size(); index++) {
    Database.LeadConvertResult result = results[index];
    System.debug(LoggingLevel.ERROR,
        'NTE_QA_CONVERSION|' + qaLeads[index].Email
        + '|success=' + result.isSuccess()
        + '|account=' + result.getAccountId()
        + '|contact=' + result.getContactId()
        + '|opportunity=' + result.getOpportunityId()
        + '|errors=' + result.getErrors()
    );
}

for (Database.LeadConvertResult result : results) {
    System.assert(result.isSuccess(), 'Every requested QA conversion must succeed: ' + result.getErrors());
}
