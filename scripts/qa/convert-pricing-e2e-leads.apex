LeadStatus convertedStatus = [
    SELECT MasterLabel
    FROM LeadStatus
    WHERE IsConverted = true
    LIMIT 1
];

Set<String> targetEmails = new Set<String>{
    'skybasteven+nte-exhibitor-paid-0817@gmail.com',
    'skybasteven+nte-exhibitor-discount-0817@gmail.com',
    'skybasteven+nte-partner-multi-0817@gmail.com',
    'nte-partner-fixed-0906@example.invalid'
};

List<Lead> targetLeads = [
    SELECT Id, Company, Email, Web_Form_Type__c
    FROM Lead
    WHERE Email IN :targetEmails
    AND IsConverted = false
    ORDER BY Email
];

System.assertEquals(4, targetLeads.size(), 'Expected exactly the four named pricing E2E application Leads.');
for (Lead targetLead : targetLeads) {
    System.assert(
        targetLead.Web_Form_Type__c == 'Exhibitor Application'
        || targetLead.Web_Form_Type__c == 'Partner / Sponsor Application',
        'Only full application Leads may be converted.'
    );
}

List<Database.LeadConvert> requests = new List<Database.LeadConvert>();
for (Lead targetLead : targetLeads) {
    Database.LeadConvert request = new Database.LeadConvert();
    request.setLeadId(targetLead.Id);
    request.setConvertedStatus(convertedStatus.MasterLabel);
    request.setOpportunityName('NTE2027 E2E - ' + targetLead.Company);
    requests.add(request);
}

List<Database.LeadConvertResult> results = Database.convertLead(requests, false);
for (Integer index = 0; index < results.size(); index++) {
    Database.LeadConvertResult result = results[index];
    System.debug(LoggingLevel.ERROR,
        'NTE_PRICING_E2E_CONVERSION|' + targetLeads[index].Email
        + '|success=' + result.isSuccess()
        + '|account=' + result.getAccountId()
        + '|contact=' + result.getContactId()
        + '|opportunity=' + result.getOpportunityId()
        + '|errors=' + result.getErrors()
    );
    System.assert(result.isSuccess(), 'Pricing E2E conversion failed: ' + result.getErrors());
}
