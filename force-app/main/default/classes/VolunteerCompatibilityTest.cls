@IsTest
private class VolunteerCompatibilityTest {
    @TestSetup static void volunteerAccess() {
        PermissionSet permission = [SELECT Id FROM PermissionSet WHERE Name='Volunteer_Applications_User'];
        if ([SELECT COUNT() FROM PermissionSetAssignment WHERE AssigneeId=:UserInfo.getUserId() AND PermissionSetId=:permission.Id] == 0)
            insert new PermissionSetAssignment(AssigneeId=UserInfo.getUserId(),PermissionSetId=permission.Id);
    }
    private static Lead application(String suffix) {
        VolunteerInboundLeadService.bypassEmailDelivery = true;
        NTEInboundLeadService.bypassEmailDelivery = true;
        return new Lead(FirstName='Harriet', LastName='Volunteer '+suffix, Email='volunteer.'+suffix+'@example.invalid',
            MobilePhone='07700 900730', Phone='01632 960730', Street='28 Meadow Lane', PostalCode='B1 1AA',
            LeadSource='Volunteer Application', Web_Form_Type__c='Volunteer Application',
            Interested_in_Volunteering__c=true, Date_of_Birth__c=Date.newInstance(1985,6,18),
            NOK_Name__c='Daniel Cresswell', NOK_Relationship__c='Friend', NOK_Phone__c='07700 900731',
            NOK_Address__c='14 Meadow Lane\nBirmingham', NOK_Postcode__c='B1 1AB',
            Volunteer_Armed_Forces_Service__c='Yes', Volunteer_Service_Details__c='Army; logistics unit',
            Volunteer_Service_Dates__c='2004–2012', Volunteer_Opportunities__c='Marshalling;Pop up shop',
            Volunteer_Skills__c='Transport and Logistics;Marshalling', Volunteer_Hours__c='4-8',
            Volunteer_Availability__c='Weekdays;Weekends', Volunteer_Travel_Regions__c='West Midlands;Wales',
            Volunteer_DBS_Willing__c='Yes', Volunteer_Consent__c='Yes', Volunteer_Code_Consent__c=true,
            Volunteer_Code_Version__c='September 2026', Volunteer_Form_Version__c='volunteer-application-v3',
            Consent_PII__c=true, Consent_Contact__c=true, Consent_Promotion__c=true,
            Declaration_Name__c='Harriet Volunteer', Declaration_Date__c=Date.today());
    }
    private static Database.LeadConvert request(Lead lead, Id accountId) {
        Database.LeadConvert request = new Database.LeadConvert();
        request.setLeadId(lead.Id);
        request.setConvertedStatus([SELECT MasterLabel FROM LeadStatus WHERE IsConverted=true LIMIT 1].MasterLabel);
        request.setDoNotCreateOpportunity(true);
        if (accountId != null) request.setAccountId(accountId);
        return request;
    }
    private static Database.LeadConvertResult convert(Lead lead, Id accountId) {
        Database.LeadConvertResult result = Database.convertLead(request(lead, accountId), false);
        System.assert(result.isSuccess(), JSON.serialize(result.getErrors()));
        System.assertEquals(null, result.getOpportunityId(), 'Volunteers do not require an Opportunity.');
        return result;
    }
    private static Account person(String suffix, String type) {
        RecordType recordType = [SELECT Id FROM RecordType WHERE SobjectType='Account' AND DeveloperName=:type AND IsPersonType=true LIMIT 1];
        Account record = new Account(RecordTypeId=recordType.Id, FirstName='Harriet', LastName='Existing '+suffix,
            PersonEmail='existing.'+suffix+'@example.invalid', Phone='01632 960735',
            Birthdate__pc=Date.newInstance(1978,1,23), NOK_Name__pc='Existing emergency contact',
            Skills_Profile__pc='<p>Existing professional experience</p>');
        insert record;
        return [SELECT Id,RecordTypeId,PersonContactId,Is_Volunteer__pc,PersonEmail,Phone,Birthdate__pc,NOK_Name__pc,Skills_Profile__pc FROM Account WHERE Id=:record.Id];
    }
    private static Contact answers(Id id) {
        return [SELECT Id,Is_Volunteer__c,Birthdate__c,NOK_Name__c,NOK_Relationship__c,NOK_Phone__c,NOK_Address__c,NOK_Postcode__c,
            Volunteer_Armed_Forces_Service__c,Volunteer_Service_Details__c,Volunteer_Service_Dates__c,
            Volunteer_Opportunities__c,Volunteer_Skills__c,Volunteer_Hours__c,Volunteer_Availability__c,
            Volunteer_Travel_Regions__c,Volunteer_DBS_Willing__c,Volunteer_Consent__c,Volunteer_Code_Consent__c,
            Volunteer_Code_Version__c,Volunteer_Form_Version__c,Volunteer_Declaration_Name__c,Volunteer_Declaration_Date__c
            FROM Contact WHERE Id=:id];
    }
    @IsTest static void newApplicationMapsAllAnswersToPersonAccount() {
        Lead lead=application('new'); insert lead;
        Test.startTest(); Database.LeadConvertResult result=convert(lead,null); Test.stopTest();
        Account saved=[SELECT IsPersonAccount,Is_Volunteer__pc,Volunteer_Hours__pc,PersonMobilePhone,Phone FROM Account WHERE Id=:result.getAccountId()];
        System.assert(saved.IsPersonAccount, 'A blank Company must create a Person Account.');
        System.assert(saved.Is_Volunteer__pc, 'New volunteer must be in the existing Volunteers register.');
        System.assertEquals('4-8',saved.Volunteer_Hours__pc);
        System.assertEquals(lead.MobilePhone,saved.PersonMobilePhone); System.assertEquals(lead.Phone,saved.Phone);
        Contact contact=answers(result.getContactId());
        for (String field : new List<String>{'NOK_Name__c','NOK_Relationship__c','NOK_Phone__c','NOK_Address__c','NOK_Postcode__c',
            'Volunteer_Armed_Forces_Service__c','Volunteer_Service_Details__c','Volunteer_Service_Dates__c',
            'Volunteer_Opportunities__c','Volunteer_Skills__c','Volunteer_Hours__c','Volunteer_Availability__c',
            'Volunteer_Travel_Regions__c','Volunteer_DBS_Willing__c','Volunteer_Consent__c','Volunteer_Code_Consent__c',
            'Volunteer_Code_Version__c','Volunteer_Form_Version__c'}) {
            if (Schema.SObjectType.Lead.fields.getMap().get(field).getDescribe().getType() == Schema.DisplayType.MultiPicklist)
                System.assertEquals(new Set<String>(String.valueOf(lead.get(field)).split(';')),
                    new Set<String>(String.valueOf(contact.get(field)).split(';')), 'Missing selected answers: '+field);
            else System.assertEquals(lead.get(field),contact.get(field),'Missing conversion answer: '+field);
        }
        System.assertEquals(lead.Date_of_Birth__c,contact.Birthdate__c,'Preserve the established date-of-birth mapping.');
        System.assertEquals(lead.Declaration_Name__c,contact.Volunteer_Declaration_Name__c);
        System.assertEquals(lead.Declaration_Date__c,contact.Volunteer_Declaration_Date__c);
        System.assertEquals(0,[SELECT COUNT() FROM Opportunity]);
        System.assertEquals(0,[SELECT COUNT() FROM NTE_Email_Dispatch__c]);
        System.assertEquals(0,[SELECT COUNT() FROM NTE_Payment_Request__c]);
    }
    @IsTest static void existingBeneficiaryKeepsInformationAndGainsVolunteerAnswers() {
        Account before=person('beneficiary','Beneficiary');
        Lead lead=application('reuse'); insert lead;
        Test.startTest(); Database.LeadConvertResult result=convert(lead,before.Id); Test.stopTest();
        System.assertEquals(before.Id,result.getAccountId()); System.assertEquals(before.PersonContactId,result.getContactId());
        Account after=[SELECT RecordTypeId,Is_Volunteer__pc,PersonEmail,Phone,Birthdate__pc,NOK_Name__pc,Skills_Profile__pc,
            Volunteer_Hours__pc,Volunteer_Declaration_Name__pc FROM Account WHERE Id=:before.Id];
        for (String api : new List<String>{'RecordTypeId','PersonEmail','Phone','Birthdate__pc','NOK_Name__pc','Skills_Profile__pc'})
            System.assertEquals(before.get(api),after.get(api),'Existing value was replaced: '+api);
        System.assert(after.Is_Volunteer__pc,'Volunteering is an additional role, not a replacement Account type.');
        System.assertEquals('4-8',after.Volunteer_Hours__pc);
        System.assertEquals(lead.Declaration_Name__c,after.Volunteer_Declaration_Name__pc);
        System.assertEquals(1,[SELECT COUNT() FROM Account]);
        System.assertEquals(1,[SELECT COUNT() FROM Contact]);
    }
    @IsTest static void existingVolunteerAnswersAndDeclarationAreNotOverwritten() {
        Account existing=person('volunteer','Volunteer');
        Database.update(new Account(Id=existing.Id, Volunteer_Hours__pc='16+', Volunteer_Skills__pc='Fundraising',
            Volunteer_Declaration_Name__pc='Original volunteer signature',
            Volunteer_Declaration_Date__pc=Date.newInstance(2024,2,20),
            Volunteer_Code_Consent__pc=true, Volunteer_Code_Version__pc='Original retained version'), AccessLevel.SYSTEM_MODE);
        Lead lead=application('retained'); insert lead;
        Test.startTest(); Database.LeadConvertResult result=convert(lead,existing.Id); Test.stopTest();
        Contact after=answers(result.getContactId());
        System.assertEquals('16+',after.Volunteer_Hours__c);
        System.assertEquals('Fundraising',after.Volunteer_Skills__c);
        System.assertEquals('Original volunteer signature',after.Volunteer_Declaration_Name__c);
        System.assertEquals(Date.newInstance(2024,2,20),after.Volunteer_Declaration_Date__c);
        System.assertEquals('Original retained version',after.Volunteer_Code_Version__c);
        System.assertEquals(lead.Declaration_Name__c,[SELECT Declaration_Name__c FROM Lead WHERE Id=:lead.Id].Declaration_Name__c,
            'The new application evidence must remain on its source Lead.');
    }
    @IsTest static void legacyManualVolunteerNeedsNoNewAnswers() {
        Lead lead=new Lead(FirstName='Amelia',LastName='Legacy volunteer',Interested_in_Volunteering__c=true);
        insert lead; lead.Phone='01632 960736'; update lead;
        Test.startTest(); Database.LeadConvertResult result=convert(lead,null); Test.stopTest();
        Contact contact=answers(result.getContactId());
        System.assert(contact.Is_Volunteer__c);
        System.assertEquals(null,contact.Volunteer_Hours__c);
        System.assertEquals(null,contact.Volunteer_Declaration_Name__c);
        System.assertEquals(false,contact.Volunteer_Code_Consent__c,'Do not invent historic acknowledgements.');
    }
    @IsTest static void sourceOnlyVolunteerCanUseExistingPersonAccount() {
        Account existing=person('source','Beneficiary');
        Lead lead=application('source'); lead.Web_Form_Type__c=null; lead.Interested_in_Volunteering__c=false; insert lead;
        Test.startTest(); Database.LeadConvertResult result=convert(lead,existing.Id); Test.stopTest();
        Contact contact=answers(result.getContactId());
        System.assert(contact.Is_Volunteer__c);
        System.assertEquals(lead.Declaration_Name__c,contact.Volunteer_Declaration_Name__c);
    }
    @IsTest static void unrelatedDeclarationsDoNotBecomeVolunteerDeclarations() {
        Lead ordinary=new Lead(FirstName='Oliver',LastName='Business applicant',Company='Ordinary organisation',
            Declaration_Name__c='Unrelated application',Declaration_Date__c=Date.today());
        insert ordinary;
        Test.startTest(); Database.LeadConvertResult result=convert(ordinary,null); Test.stopTest();
        Contact contact=answers(result.getContactId());
        System.assertEquals(false,contact.Is_Volunteer__c);
        System.assertEquals(null,contact.Volunteer_Declaration_Name__c);
        System.assertEquals(null,contact.Volunteer_Declaration_Date__c);
    }
    @IsTest static void nteTypeWithVolunteerFlagDoesNotCopyNteDeclaration() {
        NTEInboundLeadService.bypassEmailDelivery=true;
        Lead lead=new Lead(FirstName='NTE',LastName='Also volunteers',Company='NTE organisation',
            Web_Form_Type__c='Exhibitor Expression of Interest',NTE_Event_Code__c='NTE2099',
            Interested_in_Volunteering__c=true,Declaration_Name__c='NTE signature',Declaration_Date__c=Date.today());
        insert lead;
        Test.startTest(); Database.LeadConvertResult result=convert(lead,null); Test.stopTest();
        Contact contact=answers(result.getContactId());
        System.assertEquals(null,contact.Volunteer_Declaration_Name__c);
        System.assertEquals(null,contact.Volunteer_Declaration_Date__c);
        System.assert(contact.Is_Volunteer__c,'The existing role mapping remains independent from the declaration.');
    }
}
