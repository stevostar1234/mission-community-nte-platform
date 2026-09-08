@IsTest
private class NTERelatedOpportunityControllerTest {
    @TestSetup
    static void createRelationships() {
        Account accountRecord = new Account(Name = 'NTE Relationship Test');
        insert accountRecord;
        Contact primaryContact = new Contact(
            FirstName = 'Primary', LastName = 'Contact', AccountId = accountRecord.Id,
            Email = 'primary@example.invalid', Phone = '07700 900123', Title = 'Event Lead'
        );
        Contact otherContact = new Contact(
            FirstName = 'Other', LastName = 'Contact', AccountId = accountRecord.Id,
            Email = 'other@example.invalid'
        );
        insert new List<Contact>{ primaryContact, otherContact };

        Opportunity nteOpportunity = new Opportunity(
            RecordTypeId = nteOpportunityRecordTypeId(),
            Name = 'NTE Relationship Opportunity', AccountId = accountRecord.Id,
            StageName = 'Qualification', CloseDate = Date.today().addDays(30), Amount = 1250,
            NTE_Event_Code__c = 'NTE2027', NTE_Source_Form_Type__c = 'Exhibitor Application'
        );
        insert nteOpportunity;
        List<OpportunityContactRole> contactRoles = new List<OpportunityContactRole>{
            new OpportunityContactRole(
                OpportunityId = nteOpportunity.Id, ContactId = primaryContact.Id,
                IsPrimary = true, Role = 'Decision Maker'
            ),
            new OpportunityContactRole(
                OpportunityId = nteOpportunity.Id, ContactId = otherContact.Id,
                IsPrimary = false, Role = 'Business User'
            )
        };
        Id nonNteRecordTypeId = nonNteOpportunityRecordTypeId();
        if (nonNteRecordTypeId != null) {
            Opportunity regularOpportunity = new Opportunity(
                RecordTypeId = nonNteRecordTypeId,
                Name = 'Regular CRM Opportunity', AccountId = accountRecord.Id,
                StageName = 'Qualification', CloseDate = Date.today().addDays(30), Amount = 500,
                NTE_Event_Code__c = 'NTE2027', NTE_Source_Form_Type__c = 'Exhibitor Application'
            );
            insert regularOpportunity;
            contactRoles.add(new OpportunityContactRole(
                OpportunityId = regularOpportunity.Id, ContactId = primaryContact.Id,
                IsPrimary = false, Role = 'Business User'
            ));
        }
        insert contactRoles;
    }

    private static Id nteOpportunityRecordTypeId() {
        return Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName()
            .get('NTE_Event_Opportunity').getRecordTypeId();
    }

    private static Id nonNteOpportunityRecordTypeId() {
        for (Schema.RecordTypeInfo recordTypeInfo : Schema.SObjectType.Opportunity.getRecordTypeInfos()) {
            if (!recordTypeInfo.isMaster()
                && recordTypeInfo.getDeveloperName() != 'NTE_Event_Opportunity'
                && recordTypeInfo.isAvailable()) {
                return recordTypeInfo.getRecordTypeId();
            }
        }
        return null;
    }

    @IsTest
    static void accountReturnsOnlyNteOpportunities() {
        Account accountRecord = [SELECT Id FROM Account WHERE Name = 'NTE Relationship Test'];
        Test.startTest();
        NTERelatedOpportunityController.RelationshipResponse response =
            NTERelatedOpportunityController.getRelationships(accountRecord.Id, 'Account');
        Test.stopTest();
        System.assertEquals('opportunities', response.mode);
        System.assertEquals(1, response.opportunities.size());
        System.assertEquals('NTE2027', response.opportunities[0].eventCode);
    }

    @IsTest
    static void contactReturnsItsNteOpportunities() {
        Contact contactRecord = [SELECT Id FROM Contact WHERE Email = 'primary@example.invalid'];
        Test.startTest();
        NTERelatedOpportunityController.RelationshipResponse response =
            NTERelatedOpportunityController.getRelationships(contactRecord.Id, 'Contact');
        Test.stopTest();
        System.assertEquals(1, response.opportunities.size());
        System.assertEquals(true, response.opportunities[0].primaryContact);
    }

    @IsTest
    static void opportunityReturnsAccountAndContacts() {
        Opportunity opportunityRecord = [
            SELECT Id FROM Opportunity WHERE Name = 'NTE Relationship Opportunity'
        ];
        Test.startTest();
        NTERelatedOpportunityController.RelationshipResponse response =
            NTERelatedOpportunityController.getRelationships(opportunityRecord.Id, 'Opportunity');
        Test.stopTest();
        System.assertEquals('relationships', response.mode);
        System.assertEquals('NTE Relationship Test', response.account.name);
        System.assertEquals(2, response.contacts.size());
        System.assertEquals(true, response.contacts[0].primaryContact);
    }

    @IsTest
    static void regularCrmOpportunityCannotUseNteRelationshipMode() {
        List<Opportunity> opportunityRecords = [
            SELECT Id FROM Opportunity WHERE Name = 'Regular CRM Opportunity'
        ];
        if (opportunityRecords.isEmpty()) {
            System.assertEquals(null, nonNteOpportunityRecordTypeId(),
                'This org has no second deployable Opportunity record type; the static regression test still verifies the shared query boundary.');
            return;
        }
        try {
            NTERelatedOpportunityController.getRelationships(opportunityRecords[0].Id, 'Opportunity');
            System.assert(false, 'Regular CRM opportunities must not be exposed through the NTE relationship component.');
        } catch (AuraHandledException expected) {
            System.assert(true);
        }
    }

    @IsTest
    static void userModePreventsRestrictedUserFromBypassingCrudAndFieldAccess() {
        Profile restrictedProfile = [
            SELECT Id
            FROM Profile
            WHERE Name = 'Minimum Access - Salesforce'
            LIMIT 1
        ];
        User restrictedUser = new User(
            Alias = 'ntefls',
            Email = 'nte.relationship.fls@example.invalid',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Relationship FLS',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_GB',
            ProfileId = restrictedProfile.Id,
            TimeZoneSidKey = 'Europe/London',
            Username = 'nte.relationship.fls.' + System.now().getTime() + '@example.invalid'
        );
        insert restrictedUser;
        Account accountRecord = [SELECT Id FROM Account WHERE Name = 'NTE Relationship Test'];

        System.runAs(restrictedUser) {
            try {
                NTERelatedOpportunityController.getRelationships(accountRecord.Id, 'Account');
                System.assert(false, 'A user without Opportunity CRUD/FLS must not receive NTE relationship data.');
            } catch (AuraHandledException expected) {
                System.assert(true);
            }
        }
    }

    @IsTest
    static void invalidInputIsHandled() {
        try {
            NTERelatedOpportunityController.getRelationships(null, 'Account');
            System.assert(false, 'Expected an input error.');
        } catch (AuraHandledException expected) {
            System.assert(true);
        }
    }
}
