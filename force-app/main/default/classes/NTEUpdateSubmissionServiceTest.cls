@IsTest
private class NTEUpdateSubmissionServiceTest {
    @TestSetup
    static void assignFieldAccess() {
        PermissionSet permissionSetRecord = [SELECT Id FROM PermissionSet WHERE Name = 'NTE_Forms_Administration' LIMIT 1];
        if ([SELECT COUNT() FROM PermissionSetAssignment WHERE AssigneeId = :UserInfo.getUserId() AND PermissionSetId = :permissionSetRecord.Id] == 0) {
            insert new PermissionSetAssignment(AssigneeId = UserInfo.getUserId(), PermissionSetId = permissionSetRecord.Id);
        }
    }

    private static Lead newLead(String targetReference) {
        Lead lead = new Lead(
            FirstName = 'NTE',
            LastName = 'Automation Test',
            Company = 'NTE Automation Test Organisation',
            Email = 'nte-automation-test@example.invalid',
            Target_Booking_Reference__c = targetReference
        );
        Database.insert(lead, AccessLevel.SYSTEM_MODE);
        return lead;
    }

    private static NTEUpdateSubmissionService.Request requestFor(Id leadId) {
        NTEUpdateSubmissionService.Request requestValue = new NTEUpdateSubmissionService.Request();
        requestValue.leadId = leadId;
        requestValue.isNewSubmission = true;
        return requestValue;
    }

    private static Opportunity newNteOpportunity(Id accountId, String name, String reference) {
        return new Opportunity(
            Name = name,
            AccountId = accountId,
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30),
            RecordTypeId = [SELECT Id FROM RecordType WHERE SobjectType = 'Opportunity'
                AND DeveloperName = 'NTE_Event_Opportunity' LIMIT 1].Id,
            Booking_Reference__c = reference,
            NTE_Event_Code__c = 'NTE27',
            NTE_Source_Form_Type__c = 'Exhibitor Application'
        );
    }

    private static Contact addPrimaryContact(Opportunity booking) {
        Contact primaryContact = new Contact(
            AccountId = booking.AccountId, FirstName = 'Booking', LastName = 'Primary Contact',
            Email = 'booking.' + String.valueOf(booking.Id).toLowerCase() + '@example.invalid',
            Phone = '+44 20 7946 0123', MobilePhone = '+44 7700 900321'
        );
        insert primaryContact;
        insert new OpportunityContactRole(OpportunityId = booking.Id, ContactId = primaryContact.Id, IsPrimary = true);
        return primaryContact;
    }

    private static void populateRequiredHeavyFields(Lead lead) {
        lead.Web_Form_Type__c = 'Heavy Vehicle Details';
        lead.Event_Contact_Name__c = 'NTE Logistics Contact';
        lead.Email = 'logistics@example.invalid';
        lead.Phone = '+44 7700 900123';
        lead.Secondary_Contact_Name__c = 'NTE Secondary Logistics';
        lead.Secondary_Contact_Email__c = 'secondary-logistics@example.invalid';
        lead.Secondary_Contact_Phone__c = '+44 20 7946 0999';
        lead.Delivery_Window__c = 'Sunday 28 February between 14:00 - 18:00';
        lead.Heavy_Item_1_Description__c = 'QA demonstration vehicle';
        lead.Heavy_Item_1_Dimensions__c = '5m x 2m x 2m';
        lead.Heavy_Item_1_Gross_Weight__c = '3,000 kg';
        lead.Haulier_Name__c = 'NTE QA Haulier';
        lead.Haulier_Vehicle_Type__c = 'Flatbed';
        lead.Haulier_Vehicle_Gross_Weight__c = '7,500 kg';
        lead.Haulier_Vehicle_Dimensions__c = '8m x 2.5m x 3m';
        lead.Declaration_Name__c = 'NTE Logistics Contact';
        lead.Declaration_Date__c = Date.today();
    }

    private static void populateRequiredExhibitorStaffFields(Lead lead) {
        lead.Web_Form_Type__c = 'Exhibitor Staff Update';
        lead.Staff_Update_Audience__c = 'Exhibitor';
        lead.Total_Staff_Count__c = 2;
        lead.Staff_Base_Names__c = 'Alex Example\nSam Example';
        lead.Top_Up_Staff_Required__c = 'No';
        lead.Declaration_Name__c = 'Alex Example';
        lead.Declaration_Date__c = Date.today();
    }

    private static void populateRequiredPartnerStaffFields(Lead lead, Integer total, String names) {
        lead.Web_Form_Type__c = 'Partner / Sponsor Staff Update';
        lead.Staff_Update_Audience__c = 'Partner / sponsor';
        lead.Total_Staff_Count__c = total;
        lead.Staff_Base_Names__c = names;
        lead.Declaration_Name__c = 'Alex Example';
        lead.Declaration_Date__c = Date.today();
    }

    private static void populateLogoUpdate(Lead lead) {
        lead.Web_Form_Type__c = 'Logo Update';
        lead.Form_Version__c = 'logo-update-v1';
        lead.Declaration_Name__c = 'Alex Morgan';
        lead.Declaration_Date__c = Date.today();
    }

    @IsTest
    static void logoUpdateMatchesEveryEventCodeAndRetainsAuditLeads() {
        Account accountRecord = new Account(Name = 'NTE Logo Event Code Account');
        insert accountRecord;
        List<String> eventCodes = new List<String>{'NTE27', 'NTE2028', 'NTE2029', 'NTE2030'};
        List<Opportunity> bookings = new List<Opportunity>();
        for (Integer index = 0; index < eventCodes.size(); index++) {
            Opportunity booking = newNteOpportunity(
                accountRecord.Id,
                'NTE Logo Booking ' + eventCodes[index],
                'NTE-LOGO-' + eventCodes[index]
            );
            booking.NTE_Event_Code__c = eventCodes[index];
            bookings.add(booking);
        }
        Database.insert(bookings, AccessLevel.SYSTEM_MODE);

        Set<Id> leadIds = new Set<Id>();
        List<NTEUpdateSubmissionService.Request> requests = new List<NTEUpdateSubmissionService.Request>();
        for (Integer index = 0; index < eventCodes.size(); index++) {
            Lead logoLead = newLead(' nte-logo-' + eventCodes[index].toLowerCase() + ' ');
            populateLogoUpdate(logoLead);
            logoLead.NTE_Event_Code__c = eventCodes[index];
            Database.update(logoLead, AccessLevel.SYSTEM_MODE);
            leadIds.add(logoLead.Id);
            requests.add(requestFor(logoLead.Id));
        }

        NTEUpdateSubmissionService.bypassEmailDelivery = true;
        Test.startTest();
        NTEUpdateSubmissionService.applyUpdates(requests);
        Test.stopTest();

        Set<Id> bookingIds = new Map<Id, Opportunity>(bookings).keySet();
        for (Opportunity booking : [
            SELECT NTE_Logo_Update_Provided__c, NTE_Logo_Update_Provided_At__c,
                   NTE_Last_Update_Type__c, NTE_Last_Update_Form_Version__c
            FROM Opportunity WHERE Id IN :bookingIds
        ]) {
            System.assertEquals(true, booking.NTE_Logo_Update_Provided__c);
            System.assertNotEquals(null, booking.NTE_Logo_Update_Provided_At__c);
            System.assertEquals('Logo Update', booking.NTE_Last_Update_Type__c);
            System.assertEquals('logo-update-v1', booking.NTE_Last_Update_Form_Version__c);
        }
        System.assertEquals(4, [SELECT COUNT() FROM Lead WHERE Id IN :leadIds]);
        for (Lead retained : [
            SELECT NTE_Update_Status__c, NTE_Update_Error__c FROM Lead WHERE Id IN :leadIds
        ]) {
            System.assertEquals('Matched and Applied', retained.NTE_Update_Status__c);
            System.assertEquals(null, retained.NTE_Update_Error__c);
        }
    }

    @IsTest
    static void repeatedLogoUpdateIsIdempotentAndRetained() {
        Account accountRecord = new Account(Name = 'NTE Repeat Logo Account');
        insert accountRecord;
        Opportunity booking = newNteOpportunity(
            accountRecord.Id,
            'NTE Repeat Logo Booking',
            'NTE-LOGO-REPEAT'
        );
        Database.insert(booking, AccessLevel.SYSTEM_MODE);

        Lead firstLead = newLead('NTE-LOGO-REPEAT');
        populateLogoUpdate(firstLead);
        Lead repeatLead = newLead('nte-logo-repeat');
        populateLogoUpdate(repeatLead);
        Database.update(new List<Lead>{firstLead, repeatLead}, AccessLevel.SYSTEM_MODE);

        NTEUpdateSubmissionService.processLeadIds(new Set<Id>{firstLead.Id}, true);
        Datetime firstReceivedAt = [
            SELECT NTE_Logo_Update_Provided_At__c FROM Opportunity WHERE Id = :booking.Id
        ].NTE_Logo_Update_Provided_At__c;
        Test.startTest();
        NTEUpdateSubmissionService.processLeadIds(new Set<Id>{repeatLead.Id}, true);
        Test.stopTest();

        Opportunity updated = [
            SELECT NTE_Logo_Update_Provided__c, NTE_Logo_Update_Provided_At__c
            FROM Opportunity WHERE Id = :booking.Id
        ];
        System.assertEquals(true, updated.NTE_Logo_Update_Provided__c);
        System.assertEquals(firstReceivedAt, updated.NTE_Logo_Update_Provided_At__c,
            'A repeat confirmation must retain the first received date.');
        Set<Id> leadIds = new Set<Id>{firstLead.Id, repeatLead.Id};
        System.assertEquals(2, [SELECT COUNT() FROM Lead WHERE Id IN :leadIds]);
        for (Lead retained : [SELECT NTE_Update_Status__c FROM Lead WHERE Id IN :leadIds]) {
            System.assertEquals('Matched and Applied', retained.NTE_Update_Status__c);
        }
    }

    @IsTest
    static void invalidLogoReferencesAreRetainedWithoutChangingBookings() {
        String overLengthReference = 'NTE-';
        for (Integer index = 0; index < 77; index++) overLengthReference += 'A';
        System.assertEquals(false, NTEUpdateSubmissionService.isValidBookingReference(overLengthReference));
        List<String> invalidReferences = new List<String>{
            null, '', 'NTE', 'ABC-123', 'NTE-A', 'NTE--AB', 'NTE-AB-',
            'NTE-ABC_DEF', 'NTE-ABC OR 1=1'
        };
        List<Lead> logoLeads = new List<Lead>();
        List<NTEUpdateSubmissionService.Request> requests = new List<NTEUpdateSubmissionService.Request>();
        for (String invalidReference : invalidReferences) {
            Lead logoLead = newLead(invalidReference);
            populateLogoUpdate(logoLead);
            Database.update(logoLead, AccessLevel.SYSTEM_MODE);
            logoLeads.add(logoLead);
            requests.add(requestFor(logoLead.Id));
        }

        NTEUpdateSubmissionService.bypassEmailDelivery = true;
        Test.startTest();
        NTEUpdateSubmissionService.applyUpdates(requests);
        Test.stopTest();

        Set<Id> leadIds = new Map<Id, Lead>(logoLeads).keySet();
        System.assertEquals(invalidReferences.size(), [SELECT COUNT() FROM Lead WHERE Id IN :leadIds]);
        for (Lead retained : [
            SELECT NTE_Update_Status__c, NTE_Update_Error__c FROM Lead WHERE Id IN :leadIds
        ]) {
            System.assertEquals('Failed', retained.NTE_Update_Status__c);
            System.assert(retained.NTE_Update_Error__c.contains('exact booking reference'));
        }
    }

    @IsTest
    static void logoUpdateCannotTargetRegularOrIncompleteNteOpportunities() {
        Account accountRecord = new Account(Name = 'NTE Logo Target Safety Account');
        insert accountRecord;
        Opportunity regularOpportunity = new Opportunity(
            Name = 'Regular CRM Logo Target',
            AccountId = accountRecord.Id,
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30),
            Booking_Reference__c = 'NTE-LOGO-REGULAR'
        );
        insert regularOpportunity;
        Opportunity missingEventCode = newNteOpportunity(
            accountRecord.Id,
            'NTE Logo Target Missing Event',
            'NTE-LOGO-NO-EVENT'
        );
        missingEventCode.NTE_Event_Code__c = null;
        Opportunity wrongSource = newNteOpportunity(
            accountRecord.Id,
            'NTE Logo Target Wrong Source',
            'NTE-LOGO-WRONG-SOURCE'
        );
        wrongSource.NTE_Source_Form_Type__c = 'Guest Registration';
        insert new List<Opportunity>{missingEventCode, wrongSource};

        List<Lead> logoLeads = new List<Lead>();
        for (String reference : new List<String>{'NTE-LOGO-REGULAR', 'NTE-LOGO-NO-EVENT', 'NTE-LOGO-WRONG-SOURCE', 'NTE-LOGO-NO-MATCH'}) {
            Lead logoLead = newLead(reference);
            populateLogoUpdate(logoLead);
            Database.update(logoLead, AccessLevel.SYSTEM_MODE);
            logoLeads.add(logoLead);
        }
        List<NTEUpdateSubmissionService.Request> requests = new List<NTEUpdateSubmissionService.Request>();
        for (Lead logoLead : logoLeads) requests.add(requestFor(logoLead.Id));

        NTEUpdateSubmissionService.bypassEmailDelivery = true;
        Test.startTest();
        NTEUpdateSubmissionService.applyUpdates(requests);
        Test.stopTest();

        Set<Id> leadIds = new Map<Id, Lead>(logoLeads).keySet();
        for (Lead retained : [SELECT NTE_Update_Status__c FROM Lead WHERE Id IN :leadIds]) {
            System.assertEquals('No Matching Booking', retained.NTE_Update_Status__c);
        }
        Set<Id> opportunityIds = new Set<Id>{regularOpportunity.Id, missingEventCode.Id, wrongSource.Id};
        for (Opportunity unchanged : [
            SELECT NTE_Logo_Update_Provided__c, NTE_Logo_Update_Provided_At__c
            FROM Opportunity WHERE Id IN :opportunityIds
        ]) {
            System.assertEquals(false, unchanged.NTE_Logo_Update_Provided__c);
            System.assertEquals(null, unchanged.NTE_Logo_Update_Provided_At__c);
        }
    }

    @IsTest
    static void unmatchedReferenceRetainsLeadWithoutChangingOpportunity() {
        Lead lead = newLead('NTE-TEST-NO-MATCH');
        lead.Web_Form_Type__c = 'Exhibitor Staff Update';
        Database.update(lead, AccessLevel.SYSTEM_MODE);

        Test.startTest();
        NTEUpdateSubmissionService.applyUpdates(new List<NTEUpdateSubmissionService.Request>{requestFor(lead.Id)});
        Test.stopTest();

        Lead retained = [SELECT NTE_Update_Status__c, NTE_Update_Error__c FROM Lead WHERE Id = :lead.Id];
        System.assertEquals('No Matching Booking', retained.NTE_Update_Status__c);
        System.assert(retained.NTE_Update_Error__c.contains('No Opportunity matched'));
    }

    @IsTest
    static void nonNteOpportunityWithMatchingReferenceIsNotEligible() {
        Account accountRecord = new Account(Name = 'Non NTE Target Test Account');
        insert accountRecord;
        Opportunity nonNteOpportunity = new Opportunity(
            Name = 'Regular CRM Opportunity',
            AccountId = accountRecord.Id,
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30),
            Booking_Reference__c = 'NTE-TEST-NON-NTE-TARGET'
        );
        insert nonNteOpportunity;
        Opportunity missingEventCode = newNteOpportunity(
            accountRecord.Id,
            'NTE Booking Without Event Code',
            'NTE-TEST-MISSING-EVENT'
        );
        missingEventCode.NTE_Event_Code__c = null;
        Opportunity wrongSource = newNteOpportunity(
            accountRecord.Id,
            'NTE Booking With Wrong Source',
            'NTE-TEST-WRONG-SOURCE'
        );
        wrongSource.NTE_Source_Form_Type__c = 'Guest Registration';
        insert new List<Opportunity>{missingEventCode, wrongSource};

        Lead lead = newLead('NTE-TEST-NON-NTE-TARGET');
        populateRequiredExhibitorStaffFields(lead);
        Lead missingEventLead = newLead('NTE-TEST-MISSING-EVENT');
        populateRequiredExhibitorStaffFields(missingEventLead);
        Lead wrongSourceLead = newLead('NTE-TEST-WRONG-SOURCE');
        populateRequiredExhibitorStaffFields(wrongSourceLead);
        Database.update(new List<Lead>{lead, missingEventLead, wrongSourceLead}, AccessLevel.SYSTEM_MODE);

        NTEUpdateSubmissionService.bypassEmailDelivery = true;
        Test.startTest();
        NTEUpdateSubmissionService.applyUpdates(new List<NTEUpdateSubmissionService.Request>{
            requestFor(lead.Id), requestFor(missingEventLead.Id), requestFor(wrongSourceLead.Id)
        });
        Test.stopTest();

        Set<Id> leadIds = new Set<Id>{lead.Id, missingEventLead.Id, wrongSourceLead.Id};
        for (Lead retained : [
            SELECT NTE_Update_Status__c, NTE_Update_Error__c FROM Lead WHERE Id IN :leadIds
        ]) {
            System.assertEquals('No Matching Booking', retained.NTE_Update_Status__c);
            System.assert(retained.NTE_Update_Error__c.contains('No Opportunity matched'));
        }
        Set<Id> opportunityIds = new Set<Id>{nonNteOpportunity.Id, missingEventCode.Id, wrongSource.Id};
        for (Opportunity unchanged : [
            SELECT NTE_Staff_Update_Completed_At__c FROM Opportunity WHERE Id IN :opportunityIds
        ]) {
            System.assertEquals(null, unchanged.NTE_Staff_Update_Completed_At__c);
        }
    }

    @IsTest
    static void opportunityMatchIndexRejectsAmbiguousReference() {
        List<Opportunity> candidates = new List<Opportunity>{
            new Opportunity(Booking_Reference__c = ' NTE-TEST-AMBIGUOUS '),
            new Opportunity(Booking_Reference__c = 'nte-test-ambiguous'),
            new Opportunity(Booking_Reference__c = 'NTE-TEST-UNIQUE'),
            new Opportunity(),
            null
        };

        NTEUpdateSubmissionService.OpportunityMatchIndex opportunityMatches =
            NTEUpdateSubmissionService.buildOpportunityMatchIndex(candidates);

        System.assert(opportunityMatches.ambiguousReferences.contains('nte-test-ambiguous'));
        System.assertEquals(false, opportunityMatches.opportunitiesByReference.containsKey('nte-test-ambiguous'));
        System.assertEquals(candidates[2], opportunityMatches.opportunitiesByReference.get('nte-test-unique'));
        System.assertEquals(1, opportunityMatches.opportunitiesByReference.size());

        NTEUpdateSubmissionService.OpportunityMatchIndex emptyMatches =
            NTEUpdateSubmissionService.buildOpportunityMatchIndex(null);
        System.assertEquals(0, emptyMatches.opportunitiesByReference.size());
        System.assertEquals(0, emptyMatches.ambiguousReferences.size());
    }

    @IsTest
    static void exhibitorTopUpIsSeparatedFromInitialBookingValue() {
        Account accountRecord = new Account(Name = 'NTE Automation Test Account');
        insert accountRecord;
        Opportunity opportunity = newNteOpportunity(accountRecord.Id, 'NTE Automation Test Participation', 'NTE-TEST-EXACT-MATCH');
        opportunity.NTE_Sponsor_Package_Total__c = 6000;
        opportunity.NTE_Exhibitor_Space_Price__c = 500;
        opportunity.NTE_Power_Socket_Total__c = 200;
        opportunity.NTE_Initial_Staff_Count__c = 3;
        opportunity.NTE_Total_Staff_Count__c = 3;
        opportunity.NTE_Planned_Exhibitor_Count__c = '3';
        opportunity.NTE_Additional_Staff_Count__c = '1';
        opportunity.NTE_Additional_Staff_Total__c = 50;
        opportunity.NTE_Listed_Price_Total__c = 6750;
        opportunity.Amount = 6750;
        opportunity.NTE_Invoice_Provided__c = true;
        opportunity.NTE_Payment_Received__c = true;
        opportunity.NTE_Pricing_Status__c = 'Calculated';
        Database.insert(opportunity, AccessLevel.SYSTEM_MODE);
        addPrimaryContact(opportunity);

        Lead lead = newLead('NTE-TEST-EXACT-MATCH');
        lead.Web_Form_Type__c = 'Exhibitor Staff Update';
        lead.Staff_Update_Audience__c = 'Exhibitor';
        lead.Total_Staff_Count__c = 3;
        lead.Staff_Base_Names__c = 'Alex Example\nSam Example\nTaylor Example';
        lead.Top_Up_Staff_Required__c = 'Yes';
        lead.Top_Up_Staff_Count__c = 2;
        lead.Top_Up_Staff_Names__c = 'Jordan Topup\nRobin Topup';
        lead.Declaration_Name__c = 'NTE Automation Test';
        lead.Declaration_Date__c = Date.today();
        Database.update(lead, AccessLevel.SYSTEM_MODE);

        NTEUpdateSubmissionService.bypassEmailDelivery = true;
        Test.startTest();
        NTEUpdateSubmissionService.applyUpdates(new List<NTEUpdateSubmissionService.Request>{requestFor(lead.Id)});
        Test.stopTest();

        Opportunity updated = [
            SELECT NTE_Planned_Exhibitor_Count__c, NTE_Initial_Staff_Count__c,
                   NTE_Total_Staff_Count__c, NTE_Additional_Staff_Count__c,
                   NTE_Additional_Staff_Total__c, NTE_Stand_Colleagues__c,
                   NTE_Listed_Price_Total__c, Amount, NTE_Invoice_Provided__c,
                   NTE_Payment_Received__c, NTE_Top_Up_Staff_Required__c,
                   NTE_Top_Up_Staff_Count__c, NTE_Top_Up_Staff_Total__c,
                   NTE_Top_Up_Invoice_Required__c, NTE_Top_Up_Invoice_Provided__c,
                   NTE_Top_Up_Payment_Received__c,
                   NTE_Staff_Update_Completed_At__c, NTE_Last_Update_Declaration_Name__c,
                   NTE_Last_Update_Declaration_Date__c
            FROM Opportunity WHERE Id = :opportunity.Id
        ];
        System.assertEquals('3', updated.NTE_Planned_Exhibitor_Count__c);
        System.assertEquals(3, updated.NTE_Initial_Staff_Count__c);
        System.assertEquals(5, updated.NTE_Total_Staff_Count__c);
        System.assertEquals('1', updated.NTE_Additional_Staff_Count__c);
        System.assertEquals(50, updated.NTE_Additional_Staff_Total__c);
        System.assert(updated.NTE_Stand_Colleagues__c.contains('Taylor Example'));
        System.assert(updated.NTE_Stand_Colleagues__c.contains('Robin Topup'));
        System.assertEquals(6750, updated.NTE_Listed_Price_Total__c);
        System.assertEquals(6750, updated.Amount);
        System.assertEquals(true, updated.NTE_Invoice_Provided__c);
        System.assertEquals(true, updated.NTE_Payment_Received__c);
        System.assertEquals('Yes', updated.NTE_Top_Up_Staff_Required__c);
        System.assertEquals(2, updated.NTE_Top_Up_Staff_Count__c);
        System.assertEquals(100, updated.NTE_Top_Up_Staff_Total__c);
        System.assertEquals(true, updated.NTE_Top_Up_Invoice_Required__c);
        System.assertEquals(false, updated.NTE_Top_Up_Invoice_Provided__c);
        System.assertEquals(false, updated.NTE_Top_Up_Payment_Received__c);
        System.assertNotEquals(null, updated.NTE_Staff_Update_Completed_At__c);
        System.assertEquals('NTE Automation Test', updated.NTE_Last_Update_Declaration_Name__c);
        System.assertEquals(Date.today(), updated.NTE_Last_Update_Declaration_Date__c);
        Lead deletedLead = [SELECT IsDeleted FROM Lead WHERE Id = :lead.Id ALL ROWS];
        System.assertEquals(true, deletedLead.IsDeleted);
    }

    @IsTest
    static void exactReferenceAppliesHeavyVehicleDetails() {
        Account accountRecord = new Account(Name = 'NTE Heavy Automation Test Account');
        insert accountRecord;
        Opportunity opportunity = newNteOpportunity(accountRecord.Id, 'NTE Heavy Automation Test Participation', 'NTE-TEST-HEAVY-MATCH');
        opportunity.NTE_Event_Contact_Name__c = 'Existing Event Contact';
        opportunity.NTE_Event_Contact_Title__c = 'Event Manager';
        opportunity.NTE_Event_Contact_Email__c = 'event-contact@example.invalid';
        opportunity.NTE_Event_Contact_Mobile__c = '+44 7700 900111';
        opportunity.NTE_Secondary_Contact_Prefix__c = 'Dr';
        opportunity.NTE_Secondary_Contact_Name__c = 'Existing Secondary Contact';
        opportunity.NTE_Secondary_Contact_Title__c = 'Operations Manager';
        opportunity.NTE_Secondary_Contact_Email__c = 'second-contact@example.invalid';
        opportunity.NTE_Secondary_Contact_Mobile__c = '+44 7700 900222';
        opportunity.NTE_Secondary_Contact_Phone__c = '+44 20 7946 0222';
        opportunity.NTE_Heavy_Item_2_Description__c = 'Previous second item';
        opportunity.NTE_Heavy_Item_2_Registration__c = 'OLD 2';
        opportunity.NTE_Heavy_Item_3_Description__c = 'Previous third item';
        opportunity.NTE_Haulier_Staff__c = 'Previous driver';
        opportunity.NTE_Haulier_Vehicle_Registration__c = 'OLD TRUCK';
        opportunity.NTE_Stand_Colleagues__c = 'Existing Staff One\nExisting Staff Two';
        opportunity.NTE_Invoiced_Email__c = 'billing@example.invalid';
        opportunity.Amount = 1200;
        opportunity.NTE_Invoice_Provided__c = true;
        opportunity.NTE_Payment_Received__c = true;
        Database.insert(opportunity, AccessLevel.SYSTEM_MODE);
        addPrimaryContact(opportunity);
        OpportunityContactRole roleBefore = [SELECT Id, ContactId FROM OpportunityContactRole WHERE OpportunityId = :opportunity.Id AND IsPrimary = true];
        Contact contactBefore = [SELECT Name, Email, Phone, MobilePhone FROM Contact WHERE Id = :roleBefore.ContactId];

        Lead lead = newLead('NTE-TEST-HEAVY-MATCH');
        populateRequiredHeavyFields(lead);
        lead.Form_Version__c = 'heavy-vehicle-details-v3';
        lead.Email = 'logistics-fallback@example.invalid';
        lead.Heavy_Item_1_Registration__c = 'QA27 NTE';
        Database.update(lead, AccessLevel.SYSTEM_MODE);

        NTEUpdateSubmissionService.bypassEmailDelivery = true;
        Test.startTest();
        NTEUpdateSubmissionService.applyUpdates(new List<NTEUpdateSubmissionService.Request>{requestFor(lead.Id)});
        Test.stopTest();

        Opportunity updated = [
            SELECT NTE_Event_Contact_Name__c, NTE_Event_Contact_Title__c, NTE_Event_Contact_Email__c, NTE_Event_Contact_Mobile__c,
                   NTE_Secondary_Contact_Prefix__c, NTE_Secondary_Contact_Name__c, NTE_Secondary_Contact_Title__c,
                   NTE_Secondary_Contact_Email__c, NTE_Secondary_Contact_Mobile__c, NTE_Secondary_Contact_Phone__c,
                   NTE_Delivery_Window__c, NTE_Heavy_Item_1_Description__c, NTE_Heavy_Item_1_Registration__c,
                   NTE_Haulier_Name__c, NTE_Haulier_Vehicle_Type__c, NTE_Last_Update_Type__c,
                   NTE_Last_Update_Form_Version__c, NTE_Last_Update_Processed_At__c,
                   NTE_Heavy_Vehicle_Required__c, NTE_Heavy_Vehicle_Update_Completed_At__c,
                   NTE_Heavy_Item_2_Description__c, NTE_Heavy_Item_2_Registration__c, NTE_Heavy_Item_3_Description__c,
                   NTE_Haulier_Staff__c, NTE_Haulier_Vehicle_Registration__c, NTE_Stand_Colleagues__c,
                   NTE_Invoiced_Email__c, Amount, NTE_Invoice_Provided__c, NTE_Payment_Received__c,
                   NTE_Logistics_Contact_Name__c, NTE_Logistics_Contact_Email__c, NTE_Logistics_Contact_Phone__c,
                   NTE_Logistics_Second_Contact_Name__c, NTE_Logistics_Second_Contact_Email__c, NTE_Logistics_Second_Contact_Phone__c
            FROM Opportunity WHERE Id = :opportunity.Id
        ];
        System.assertEquals('NTE Logistics Contact', updated.NTE_Logistics_Contact_Name__c, 'The logistics main contact is kept on the booking.');
        System.assertEquals('logistics-fallback@example.invalid', updated.NTE_Logistics_Contact_Email__c);
        System.assertEquals('+44 7700 900123', updated.NTE_Logistics_Contact_Phone__c);
        System.assertEquals('NTE Secondary Logistics', updated.NTE_Logistics_Second_Contact_Name__c, 'The required second contact is no longer discarded with the temporary Lead.');
        System.assertEquals('secondary-logistics@example.invalid', updated.NTE_Logistics_Second_Contact_Email__c);
        System.assertEquals('+44 20 7946 0999', updated.NTE_Logistics_Second_Contact_Phone__c);
        System.assertEquals(opportunity.NTE_Event_Contact_Name__c, updated.NTE_Event_Contact_Name__c);
        System.assertEquals(opportunity.NTE_Event_Contact_Title__c, updated.NTE_Event_Contact_Title__c);
        System.assertEquals(opportunity.NTE_Event_Contact_Email__c, updated.NTE_Event_Contact_Email__c);
        System.assertEquals(opportunity.NTE_Event_Contact_Mobile__c, updated.NTE_Event_Contact_Mobile__c);
        System.assertEquals(opportunity.NTE_Secondary_Contact_Prefix__c, updated.NTE_Secondary_Contact_Prefix__c);
        System.assertEquals(opportunity.NTE_Secondary_Contact_Name__c, updated.NTE_Secondary_Contact_Name__c);
        System.assertEquals(opportunity.NTE_Secondary_Contact_Title__c, updated.NTE_Secondary_Contact_Title__c);
        System.assertEquals(opportunity.NTE_Secondary_Contact_Email__c, updated.NTE_Secondary_Contact_Email__c);
        System.assertEquals(opportunity.NTE_Secondary_Contact_Mobile__c, updated.NTE_Secondary_Contact_Mobile__c);
        System.assertEquals(opportunity.NTE_Secondary_Contact_Phone__c, updated.NTE_Secondary_Contact_Phone__c);
        System.assertEquals(null, updated.NTE_Heavy_Item_2_Description__c);
        System.assertEquals(null, updated.NTE_Heavy_Item_2_Registration__c);
        System.assertEquals(null, updated.NTE_Heavy_Item_3_Description__c);
        System.assertEquals(null, updated.NTE_Haulier_Staff__c);
        System.assertEquals(null, updated.NTE_Haulier_Vehicle_Registration__c);
        System.assertEquals(opportunity.NTE_Stand_Colleagues__c, updated.NTE_Stand_Colleagues__c);
        System.assertEquals(opportunity.NTE_Invoiced_Email__c, updated.NTE_Invoiced_Email__c);
        System.assertEquals(1200, updated.Amount);
        System.assertEquals(true, updated.NTE_Invoice_Provided__c);
        System.assertEquals(true, updated.NTE_Payment_Received__c);
        System.assertEquals(contactBefore, [SELECT Name, Email, Phone, MobilePhone FROM Contact WHERE Id = :roleBefore.ContactId]);
        System.assertEquals(roleBefore.Id, [SELECT Id FROM OpportunityContactRole WHERE OpportunityId = :opportunity.Id AND IsPrimary = true].Id);
        System.assertEquals('QA demonstration vehicle', updated.NTE_Heavy_Item_1_Description__c);
        System.assertEquals('QA27 NTE', updated.NTE_Heavy_Item_1_Registration__c);
        System.assertEquals('NTE QA Haulier', updated.NTE_Haulier_Name__c);
        System.assertEquals('Flatbed', updated.NTE_Haulier_Vehicle_Type__c);
        System.assertEquals('Heavy Vehicle Details', updated.NTE_Last_Update_Type__c);
        System.assertEquals('heavy-vehicle-details-v3', updated.NTE_Last_Update_Form_Version__c);
        System.assertNotEquals(null, updated.NTE_Last_Update_Processed_At__c);
        System.assertEquals('Yes', updated.NTE_Heavy_Vehicle_Required__c);
        System.assertNotEquals(null, updated.NTE_Heavy_Vehicle_Update_Completed_At__c);
        Lead deletedLead = [SELECT IsDeleted FROM Lead WHERE Id = :lead.Id ALL ROWS];
        System.assertEquals(true, deletedLead.IsDeleted);
    }

    @IsTest
    static void heavySubmissionSetsRequirementYesForEveryPriorState() {
        Account accountRecord = new Account(Name = 'NTE Heavy Requirement Test Account');
        insert accountRecord;

        List<String> priorStates = new List<String>{null, 'Not known yet', 'No'};
        List<Opportunity> opportunities = new List<Opportunity>();
        for (Integer index = 0; index < priorStates.size(); index++) {
            Opportunity opportunity = newNteOpportunity(
                accountRecord.Id,
                'NTE Heavy Requirement Test ' + index,
                'NTE-TEST-HEAVY-STATE-' + index
            );
            opportunity.NTE_Heavy_Vehicle_Required__c = priorStates[index];
            opportunities.add(opportunity);
        }
        Database.insert(opportunities, AccessLevel.SYSTEM_MODE);
        for (Opportunity booking : opportunities) addPrimaryContact(booking);
        Set<Id> opportunityIds = new Map<Id, Opportunity>(opportunities).keySet();

        List<NTEUpdateSubmissionService.Request> requests = new List<NTEUpdateSubmissionService.Request>();
        Set<Id> leadIds = new Set<Id>();
        for (Integer index = 0; index < priorStates.size(); index++) {
            Lead lead = newLead('NTE-TEST-HEAVY-STATE-' + index);
            populateRequiredHeavyFields(lead);
            lead.Email = 'heavy-state-' + index + '@example.invalid';
            Database.update(lead, AccessLevel.SYSTEM_MODE);
            leadIds.add(lead.Id);
            requests.add(requestFor(lead.Id));
        }

        NTEUpdateSubmissionService.bypassEmailDelivery = true;
        Test.startTest();
        NTEUpdateSubmissionService.applyUpdates(requests);
        Test.stopTest();

        for (Opportunity updated : [
            SELECT NTE_Heavy_Vehicle_Required__c, NTE_Heavy_Vehicle_Update_Completed_At__c
            FROM Opportunity WHERE Id IN :opportunityIds
        ]) {
            System.assertEquals('Yes', updated.NTE_Heavy_Vehicle_Required__c);
            System.assertNotEquals(null, updated.NTE_Heavy_Vehicle_Update_Completed_At__c);
        }
        System.assertEquals(3, [SELECT COUNT() FROM Lead WHERE Id IN :leadIds AND IsDeleted = true ALL ROWS]);
    }

    @IsTest
    static void bulkStaffAndHeavyUpdatesForOneBookingAreMergedWithoutDuplicateIdFailure() {
        Account accountRecord = new Account(Name = 'NTE Bulk Merge Test Account');
        insert accountRecord;
        Opportunity opportunity = newNteOpportunity(accountRecord.Id, 'NTE Bulk Merge Test Participation', 'NTE-TEST-BULK-MERGE');
        opportunity.NTE_Initial_Staff_Count__c = 4;
        opportunity.NTE_Total_Staff_Count__c = 4;
        opportunity.NTE_Planned_Exhibitor_Count__c = '4';
        opportunity.NTE_Event_Contact_Email__c = 'existing-event@example.invalid';
        Database.insert(opportunity, AccessLevel.SYSTEM_MODE);
        addPrimaryContact(opportunity);

        Lead staff = newLead(' nte-test-bulk-merge ');
        staff.Web_Form_Type__c = 'Exhibitor Staff Update';
        staff.Staff_Update_Audience__c = 'Exhibitor';
        staff.Total_Staff_Count__c = 4;
        staff.Staff_Base_Names__c = 'One Example\nTwo Example\nThree Example\nFour Example';
        staff.Top_Up_Staff_Required__c = 'No';
        staff.Declaration_Name__c = 'NTE Staff Contact';
        staff.Declaration_Date__c = Date.today();
        Database.update(staff, AccessLevel.SYSTEM_MODE);
        Lead heavy = newLead('NTE-TEST-BULK-MERGE');
        populateRequiredHeavyFields(heavy);
        heavy.Email = 'bulk-heavy@example.invalid';
        heavy.Heavy_Item_1_Description__c = 'Bulk merge vehicle';
        Database.update(heavy, AccessLevel.SYSTEM_MODE);

        NTEUpdateSubmissionService.bypassEmailDelivery = true;
        Test.startTest();
        NTEUpdateSubmissionService.applyUpdates(new List<NTEUpdateSubmissionService.Request>{requestFor(staff.Id), requestFor(heavy.Id)});
        Test.stopTest();

        Opportunity updated = [SELECT NTE_Planned_Exhibitor_Count__c, NTE_Total_Staff_Count__c, NTE_Stand_Colleagues__c,
            NTE_Heavy_Item_1_Description__c, NTE_Event_Contact_Email__c,
            NTE_Staff_Update_Completed_At__c, NTE_Heavy_Vehicle_Update_Completed_At__c
            FROM Opportunity WHERE Id = :opportunity.Id];
        System.assertEquals('4', updated.NTE_Planned_Exhibitor_Count__c);
        System.assertEquals(4, updated.NTE_Total_Staff_Count__c);
        System.assert(updated.NTE_Stand_Colleagues__c.contains('Four Example'));
        System.assertEquals('Bulk merge vehicle', updated.NTE_Heavy_Item_1_Description__c);
        System.assertEquals('existing-event@example.invalid', updated.NTE_Event_Contact_Email__c);
        System.assertNotEquals(null, updated.NTE_Staff_Update_Completed_At__c);
        System.assertNotEquals(null, updated.NTE_Heavy_Vehicle_Update_Completed_At__c);
        Set<Id> processedLeadIds = new Set<Id>{staff.Id, heavy.Id};
        System.assertEquals(2, [SELECT COUNT() FROM Lead WHERE Id IN :processedLeadIds AND IsDeleted = true ALL ROWS]);
    }

    @IsTest
    static void emptyAndUnsupportedRequestsAreHandledSafely() {
        Lead blankReference = newLead(null);
        blankReference.Web_Form_Type__c = 'Exhibitor Staff Update';
        Database.update(blankReference, AccessLevel.SYSTEM_MODE);

        Account accountRecord = new Account(Name = 'NTE Unsupported Test Account');
        insert accountRecord;
        Opportunity opportunity = newNteOpportunity(accountRecord.Id, 'NTE Unsupported Test Participation', 'NTE-TEST-UNSUPPORTED');
        Database.insert(opportunity, AccessLevel.SYSTEM_MODE);
        addPrimaryContact(opportunity);
        Lead lead = newLead('NTE-TEST-UNSUPPORTED');
        lead.Web_Form_Type__c = 'Staff Details Update';
        Database.update(lead, AccessLevel.SYSTEM_MODE);

        Test.startTest();
        NTEUpdateSubmissionService.applyUpdates(null);
        NTEUpdateSubmissionService.processLeadIds(null, true);
        NTEUpdateSubmissionService.processLeadIds(new Set<Id>(), true);
        NTEUpdateSubmissionService.applyUpdates(new List<NTEUpdateSubmissionService.Request>());
        NTEUpdateSubmissionService.applyUpdates(new List<NTEUpdateSubmissionService.Request>{null});
        NTEUpdateSubmissionService.applyUpdates(new List<NTEUpdateSubmissionService.Request>{
            requestFor(blankReference.Id), requestFor(lead.Id)
        });
        Test.stopTest();

        Lead blankReferenceResult = [SELECT NTE_Update_Status__c FROM Lead WHERE Id = :blankReference.Id];
        System.assertEquals('Failed', blankReferenceResult.NTE_Update_Status__c);
        Lead retained = [SELECT NTE_Update_Status__c, NTE_Update_Error__c FROM Lead WHERE Id = :lead.Id];
        System.assertEquals('Failed', retained.NTE_Update_Status__c);
        System.assertEquals('Unsupported supplementary form type. No Opportunity was changed.', retained.NTE_Update_Error__c);
    }

    @IsTest
    static void blankStaffNamesAreRetainedWithoutMarkingBookingComplete() {
        Account accountRecord = new Account(Name = 'NTE Invalid Update Account');
        insert accountRecord;
        Opportunity opportunity = newNteOpportunity(accountRecord.Id, 'NTE Invalid Update Booking', 'NTE-TEST-INVALID-PAYLOAD');
        opportunity.NTE_Initial_Staff_Count__c = 2;
        opportunity.NTE_Total_Staff_Count__c = 2;
        insert opportunity;
        addPrimaryContact(opportunity);
        Lead lead = newLead('NTE-TEST-INVALID-PAYLOAD');
        lead.Web_Form_Type__c = 'Exhibitor Staff Update';
        lead.Staff_Update_Audience__c = 'Exhibitor';
        lead.Total_Staff_Count__c = 1;
        lead.Staff_Base_Names__c = ' \n\t ';
        lead.Top_Up_Staff_Required__c = 'No';
        lead.Declaration_Name__c = 'Only One Name';
        lead.Declaration_Date__c = Date.today();
        update lead;

        NTEUpdateSubmissionService.bypassEmailDelivery = true;
        Test.startTest();
        NTEUpdateSubmissionService.applyUpdates(new List<NTEUpdateSubmissionService.Request>{requestFor(lead.Id)});
        Test.stopTest();

        Lead retained = [SELECT NTE_Update_Status__c, NTE_Update_Error__c FROM Lead WHERE Id = :lead.Id];
        System.assertEquals('Failed', retained.NTE_Update_Status__c);
        System.assert(retained.NTE_Update_Error__c.contains('Enter the staff names'));
        System.assertEquals(null, [SELECT NTE_Staff_Update_Completed_At__c FROM Opportunity WHERE Id = :opportunity.Id].NTE_Staff_Update_Completed_At__c);
    }

    @IsTest
    static void incompleteHeavyPayloadIsRetainedWithoutMarkingLogisticsComplete() {
        Account accountRecord = new Account(Name = 'NTE Invalid Heavy Update Account');
        insert accountRecord;
        Opportunity opportunity = newNteOpportunity(
            accountRecord.Id,
            'NTE Invalid Heavy Update Booking',
            'NTE-TEST-INVALID-HEAVY'
        );
        opportunity.NTE_Heavy_Vehicle_Required__c = 'Not known yet';
        opportunity.NTE_Heavy_Item_1_Description__c = 'Retained vehicle';
        opportunity.NTE_Event_Contact_Email__c = 'retained-contact@example.invalid';
        insert opportunity;
        addPrimaryContact(opportunity);

        Lead lead = newLead('NTE-TEST-INVALID-HEAVY');
        populateRequiredHeavyFields(lead);
        lead.Heavy_Item_1_Gross_Weight__c = null;
        Database.update(lead, AccessLevel.SYSTEM_MODE);

        NTEUpdateSubmissionService.bypassEmailDelivery = true;
        Test.startTest();
        NTEUpdateSubmissionService.applyUpdates(new List<NTEUpdateSubmissionService.Request>{requestFor(lead.Id)});
        Test.stopTest();

        Lead retained = [SELECT NTE_Update_Status__c, NTE_Update_Error__c FROM Lead WHERE Id = :lead.Id];
        System.assertEquals('Failed', retained.NTE_Update_Status__c);
        System.assert(retained.NTE_Update_Error__c.contains('first-item'));
        Opportunity unchanged = [
            SELECT NTE_Heavy_Vehicle_Required__c, NTE_Heavy_Vehicle_Update_Completed_At__c,
                   NTE_Heavy_Item_1_Description__c, NTE_Event_Contact_Email__c
            FROM Opportunity WHERE Id = :opportunity.Id
        ];
        System.assertEquals('Not known yet', unchanged.NTE_Heavy_Vehicle_Required__c);
        System.assertEquals(null, unchanged.NTE_Heavy_Vehicle_Update_Completed_At__c);
        System.assertEquals('Retained vehicle', unchanged.NTE_Heavy_Item_1_Description__c);
        System.assertEquals('retained-contact@example.invalid', unchanged.NTE_Event_Contact_Email__c);
    }

    @IsTest
    static void missingTopUpAnswerRemainsOutstandingAndRetainsLead() {
        Account accountRecord = new Account(Name = 'NTE Unknown Staff Update Account');
        insert accountRecord;
        Opportunity opportunity = newNteOpportunity(
            accountRecord.Id,
            'NTE Unknown Staff Update Booking',
            'NTE-TEST-STAFF-UNKNOWN'
        );
        opportunity.NTE_Initial_Staff_Count__c = 2;
        opportunity.NTE_Total_Staff_Count__c = 2;
        insert opportunity;
        addPrimaryContact(opportunity);

        Lead lead = newLead('NTE-TEST-STAFF-UNKNOWN');
        populateRequiredExhibitorStaffFields(lead);
        lead.Top_Up_Staff_Required__c = null;
        Database.update(lead, AccessLevel.SYSTEM_MODE);

        NTEUpdateSubmissionService.bypassEmailDelivery = true;
        Test.startTest();
        NTEUpdateSubmissionService.applyUpdates(new List<NTEUpdateSubmissionService.Request>{requestFor(lead.Id)});
        Test.stopTest();

        Lead retained = [SELECT NTE_Update_Status__c, NTE_Update_Error__c FROM Lead WHERE Id = :lead.Id];
        System.assertEquals('Failed', retained.NTE_Update_Status__c);
        System.assert(retained.NTE_Update_Error__c.contains('Select whether additional top-up'));
        Opportunity unchanged = [
            SELECT NTE_Top_Up_Staff_Required__c, NTE_Staff_Update_Completed_At__c
            FROM Opportunity WHERE Id = :opportunity.Id
        ];
        System.assertEquals(null, unchanged.NTE_Top_Up_Staff_Required__c);
        System.assertEquals(null, unchanged.NTE_Staff_Update_Completed_At__c);
    }

    @IsTest
    static void partnerStaffUpdateIsFreeAndBecomesTheRosterSourceOfTruth() {
        Account accountRecord = new Account(Name = 'NTE Partner Staff Account');
        insert accountRecord;
        Opportunity opportunity = newNteOpportunity(
            accountRecord.Id,
            'NTE Partner Staff Booking',
            'NTE-TEST-PARTNER-STAFF'
        );
        opportunity.NTE_Source_Form_Type__c = 'Partner / Sponsor Application';
        opportunity.NTE_Initial_Staff_Count__c = 3;
        opportunity.NTE_Total_Staff_Count__c = 3;
        opportunity.NTE_Sponsor_Package_Total__c = 5000;
        opportunity.NTE_Listed_Price_Total__c = 5000;
        opportunity.Amount = 5000;
        opportunity.NTE_Invoice_Provided__c = true;
        opportunity.NTE_Payment_Received__c = true;
        insert opportunity;
        addPrimaryContact(opportunity);

        String names = 'Person 1\nPerson 2\nPerson 3\nPerson 4\nPerson 5\nPerson 6\n'
            + 'Person 7\nPerson 8\nPerson 9\nPerson 10\nPerson 11\nPerson 12';
        Lead lead = newLead('NTE-TEST-PARTNER-STAFF');
        populateRequiredPartnerStaffFields(lead, 12, names);
        update lead;

        NTEUpdateSubmissionService.bypassEmailDelivery = true;
        Test.startTest();
        NTEUpdateSubmissionService.applyUpdates(new List<NTEUpdateSubmissionService.Request>{requestFor(lead.Id)});
        Test.stopTest();

        Opportunity updated = [
            SELECT NTE_Planned_Exhibitor_Count__c, NTE_Total_Staff_Count__c,
                   NTE_Stand_Colleagues__c, NTE_Top_Up_Staff_Total__c,
                   NTE_Invoice_Provided__c, NTE_Payment_Received__c,
                   NTE_Staff_Update_Completed_At__c, Amount
            FROM Opportunity WHERE Id = :opportunity.Id
        ];
        System.assertEquals('12', updated.NTE_Planned_Exhibitor_Count__c);
        System.assertEquals(12, updated.NTE_Total_Staff_Count__c);
        System.assertEquals(names, updated.NTE_Stand_Colleagues__c);
        System.assertEquals(null, updated.NTE_Top_Up_Staff_Total__c);
        System.assertEquals(5000, updated.Amount);
        System.assertEquals(true, updated.NTE_Invoice_Provided__c);
        System.assertEquals(true, updated.NTE_Payment_Received__c);
        System.assertNotEquals(null, updated.NTE_Staff_Update_Completed_At__c);
        System.assertEquals(1, [SELECT COUNT() FROM Lead WHERE Id = :lead.Id AND IsDeleted = true ALL ROWS]);
    }

    @IsTest
    static void staffFormsCannotUpdateTheWrongBookingType() {
        Account accountRecord = new Account(Name = 'NTE Staff Type Safety Account');
        insert accountRecord;
        Opportunity partnerBooking = newNteOpportunity(accountRecord.Id, 'NTE Partner Type Safety', 'NTE-TYPE-PARTNER');
        partnerBooking.NTE_Source_Form_Type__c = 'Partner / Sponsor Application';
        partnerBooking.NTE_Initial_Staff_Count__c = 2;
        Opportunity exhibitorBooking = newNteOpportunity(accountRecord.Id, 'NTE Exhibitor Type Safety', 'NTE-TYPE-EXHIBITOR');
        exhibitorBooking.NTE_Initial_Staff_Count__c = 2;
        insert new List<Opportunity>{partnerBooking, exhibitorBooking};

        Lead exhibitorForm = newLead('NTE-TYPE-PARTNER');
        populateRequiredExhibitorStaffFields(exhibitorForm);
        Lead partnerForm = newLead('NTE-TYPE-EXHIBITOR');
        populateRequiredPartnerStaffFields(partnerForm, 2, 'One Person\nTwo Person');
        update new List<Lead>{exhibitorForm, partnerForm};

        Set<Id> leadIds = new Set<Id>{exhibitorForm.Id, partnerForm.Id};
        Set<Id> opportunityIds = new Set<Id>{partnerBooking.Id, exhibitorBooking.Id};
        NTEUpdateSubmissionService.processLeadIds(leadIds, true);

        for (Lead retained : [
            SELECT NTE_Update_Status__c, NTE_Update_Error__c
            FROM Lead WHERE Id IN :leadIds
        ]) {
            System.assertEquals('Failed', retained.NTE_Update_Status__c);
            System.assert(retained.NTE_Update_Error__c.contains('does not match the booking type'));
        }
        for (Opportunity unchanged : [
            SELECT NTE_Staff_Update_Completed_At__c
            FROM Opportunity WHERE Id IN :opportunityIds
        ]) {
            System.assertEquals(null, unchanged.NTE_Staff_Update_Completed_At__c);
        }
    }

    @IsTest
    static void acceptedTopUpRejectsQuantityChangesAndPreservesFinanceOnNameCorrections() {
        Account accountRecord = new Account(Name = 'NTE Finance Reopen Account');
        insert accountRecord;
        Opportunity opportunity = newNteOpportunity(accountRecord.Id, 'NTE Finance Reopen Booking', 'NTE-TEST-FINANCE-REOPEN');
        opportunity.NTE_Initial_Staff_Count__c = 3;
        opportunity.NTE_Total_Staff_Count__c = 5;
        opportunity.NTE_Listed_Price_Total__c = 1000;
        opportunity.Amount = 1000;
        opportunity.NTE_Top_Up_Staff_Required__c = 'Yes';
        opportunity.NTE_Top_Up_Staff_Count__c = 2;
        opportunity.NTE_Top_Up_Staff_Names__c = 'Old Topup 1\nOld Topup 2';
        opportunity.NTE_Top_Up_Staff_Unit_Price__c = 60;
        opportunity.NTE_Top_Up_Staff_Total__c = 120;
        opportunity.NTE_Top_Up_Invoice_Required__c = true;
        opportunity.NTE_Top_Up_Invoice_Provided__c = true;
        opportunity.NTE_Top_Up_Invoice_At__c = System.now();
        opportunity.NTE_Top_Up_Invoice_By__c = 'Finance Tester';
        opportunity.NTE_Top_Up_Payment_Received__c = true;
        opportunity.NTE_Top_Up_Payment_At__c = System.now();
        opportunity.NTE_Top_Up_Payment_By__c = 'Finance Tester';
        opportunity.NTE_Invoice_Provided__c = true;
        opportunity.NTE_Invoice_Provided_At__c = System.now();
        opportunity.NTE_Invoice_Provided_By__c = 'Finance Tester';
        opportunity.NTE_Payment_Received__c = true;
        opportunity.NTE_Payment_Received_At__c = System.now();
        opportunity.NTE_Payment_Recorded_By__c = 'Finance Tester';
        insert opportunity;
        addPrimaryContact(opportunity);
        Lead lead = newLead('NTE-TEST-FINANCE-REOPEN');
        populateRequiredExhibitorStaffFields(lead);
        lead.Staff_Base_Names__c = 'One Person\nTwo Person\nThree Person';
        lead.Top_Up_Staff_Required__c = 'Yes';
        lead.Top_Up_Staff_Count__c = 3;
        lead.Top_Up_Staff_Names__c = 'Topup 1\nTopup 2\nTopup 3';
        lead.Declaration_Name__c = 'One Person';
        lead.Declaration_Date__c = Date.today();
        update lead;

        NTEUpdateSubmissionService.bypassEmailDelivery = true;
        Test.startTest();
        NTEUpdateSubmissionService.processLeadIds(new Set<Id>{lead.Id}, true);
        Test.stopTest();

        Opportunity updated = [SELECT Amount, NTE_Invoice_Provided__c, NTE_Invoice_Provided_At__c,
            NTE_Payment_Received__c, NTE_Payment_Received_At__c, NTE_Total_Staff_Count__c,
            NTE_Top_Up_Staff_Count__c, NTE_Top_Up_Staff_Total__c,
            NTE_Top_Up_Invoice_Provided__c, NTE_Top_Up_Invoice_At__c,
            NTE_Top_Up_Payment_Received__c, NTE_Top_Up_Payment_At__c
            FROM Opportunity WHERE Id = :opportunity.Id];
        System.assertEquals(1000, updated.Amount);
        System.assertEquals(true, updated.NTE_Invoice_Provided__c);
        System.assertNotEquals(null, updated.NTE_Invoice_Provided_At__c);
        System.assertEquals(true, updated.NTE_Payment_Received__c);
        System.assertNotEquals(null, updated.NTE_Payment_Received_At__c);
        System.assertEquals(5, updated.NTE_Total_Staff_Count__c);
        System.assertEquals(2, updated.NTE_Top_Up_Staff_Count__c);
        System.assertEquals(120, updated.NTE_Top_Up_Staff_Total__c);
        System.assertEquals(true, updated.NTE_Top_Up_Invoice_Provided__c);
        System.assertEquals(opportunity.NTE_Top_Up_Invoice_At__c, updated.NTE_Top_Up_Invoice_At__c);
        System.assertEquals(true, updated.NTE_Top_Up_Payment_Received__c);
        System.assertEquals(opportunity.NTE_Top_Up_Payment_At__c, updated.NTE_Top_Up_Payment_At__c);
        Lead rejectedIncrease = [SELECT NTE_Update_Status__c, NTE_Update_Error__c FROM Lead WHERE Id = :lead.Id];
        System.assertEquals('Failed', rejectedIncrease.NTE_Update_Status__c);
        System.assert(rejectedIncrease.NTE_Update_Error__c.contains('only be requested once'));

        Lead reduction = newLead('NTE-TEST-FINANCE-REOPEN');
        populateRequiredExhibitorStaffFields(reduction);
        reduction.Staff_Base_Names__c = 'One Person\nTwo Person\nThree Person';
        reduction.Top_Up_Staff_Required__c = 'Yes';
        reduction.Top_Up_Staff_Count__c = 1;
        reduction.Top_Up_Staff_Names__c = 'Topup 1';
        update reduction;
        NTEUpdateSubmissionService.processLeadIds(new Set<Id>{reduction.Id}, true);
        Lead rejected = [SELECT NTE_Update_Status__c, NTE_Update_Error__c FROM Lead WHERE Id = :reduction.Id];
        System.assertEquals('Failed', rejected.NTE_Update_Status__c);
        System.assert(rejected.NTE_Update_Error__c.contains('cannot be reduced'));
        System.assertEquals(2, [SELECT NTE_Top_Up_Staff_Count__c FROM Opportunity WHERE Id = :opportunity.Id].NTE_Top_Up_Staff_Count__c);

        Lead correction = newLead('NTE-TEST-FINANCE-REOPEN');
        populateRequiredExhibitorStaffFields(correction);
        correction.Staff_Base_Names__c = 'One Person\nTwo Person\nThree Person';
        correction.Top_Up_Staff_Required__c = 'Yes';
        correction.Top_Up_Staff_Count__c = 2;
        correction.Top_Up_Staff_Names__c = 'Corrected Name One\nCorrected Name Two';
        correction.Top_Up_Staff_Unit_Price__c = 1;
        correction.Top_Up_Staff_Total__c = 2;
        update correction;
        NTEUpdateSubmissionService.processLeadIds(new Set<Id>{correction.Id}, true);
        Opportunity corrected = [
            SELECT NTE_Top_Up_Staff_Count__c, NTE_Top_Up_Staff_Names__c, NTE_Top_Up_Staff_Unit_Price__c,
                NTE_Top_Up_Staff_Total__c, NTE_Top_Up_Invoice_Provided__c, NTE_Top_Up_Invoice_At__c,
                NTE_Top_Up_Invoice_By__c, NTE_Top_Up_Payment_Received__c, NTE_Top_Up_Payment_At__c,
                NTE_Top_Up_Payment_By__c, NTE_Payment_Received__c, Amount
            FROM Opportunity WHERE Id = :opportunity.Id
        ];
        System.assertEquals(2, corrected.NTE_Top_Up_Staff_Count__c);
        System.assertEquals(correction.Top_Up_Staff_Names__c, corrected.NTE_Top_Up_Staff_Names__c);
        System.assertEquals(60, corrected.NTE_Top_Up_Staff_Unit_Price__c);
        System.assertEquals(120, corrected.NTE_Top_Up_Staff_Total__c);
        System.assertEquals(true, corrected.NTE_Top_Up_Invoice_Provided__c);
        System.assertEquals(opportunity.NTE_Top_Up_Invoice_At__c, corrected.NTE_Top_Up_Invoice_At__c);
        System.assertEquals('Finance Tester', corrected.NTE_Top_Up_Invoice_By__c);
        System.assertEquals(true, corrected.NTE_Top_Up_Payment_Received__c);
        System.assertEquals(opportunity.NTE_Top_Up_Payment_At__c, corrected.NTE_Top_Up_Payment_At__c);
        System.assertEquals('Finance Tester', corrected.NTE_Top_Up_Payment_By__c);
        System.assertEquals(true, corrected.NTE_Payment_Received__c);
        System.assertEquals(1000, corrected.Amount);
        Lead receipt = [SELECT Top_Up_Staff_Unit_Price__c, Top_Up_Staff_Total__c FROM Lead WHERE Id = :correction.Id ALL ROWS];
        System.assertEquals(60, receipt.Top_Up_Staff_Unit_Price__c);
        System.assertEquals(120, receipt.Top_Up_Staff_Total__c);
    }

    @IsTest
    static void missingPrimaryRetainsAppliedUpdateAndRetryDoesNotReplayItsData() {
        Account accountRecord = new Account(Name = 'NTE Receipt Retry Account');
        insert accountRecord;
        Opportunity booking = newNteOpportunity(accountRecord.Id, 'NTE Receipt Retry Booking', 'NTE-TEST-RECEIPT-RETRY');
        booking.NTE_Event_Contact_Email__c = 'event-fallback@example.invalid';
        insert booking;
        Lead submission = newLead(booking.Booking_Reference__c);
        populateRequiredHeavyFields(submission);
        update submission;

        NTEUpdateSubmissionService.processLeadIds(new Set<Id>{submission.Id}, true);
        Lead retained = [SELECT NTE_Update_Status__c, NTE_Applicant_Email_Status__c, NTE_Email_Error__c FROM Lead WHERE Id = :submission.Id];
        System.assertEquals('Matched and Applied', retained.NTE_Update_Status__c);
        System.assertEquals('Failed', retained.NTE_Applicant_Email_Status__c);
        System.assert(retained.NTE_Email_Error__c.contains('Primary Contact'));
        Opportunity saved = [SELECT NTE_Heavy_Item_1_Description__c, NTE_Event_Contact_Email__c FROM Opportunity WHERE Id = :booking.Id];
        System.assertEquals('QA demonstration vehicle', saved.NTE_Heavy_Item_1_Description__c);
        System.assertEquals('event-fallback@example.invalid', saved.NTE_Event_Contact_Email__c);
        System.assertEquals(false, NTEUpdateSubmissionService.acknowledgementRecipientByLeadId.containsKey(submission.Id));

        Contact primaryContact = addPrimaryContact(booking);
        update new Opportunity(Id = booking.Id, NTE_Heavy_Item_1_Description__c = 'More recent vehicle details');
        NTEUpdateSubmissionService.bypassEmailDelivery = true;
        NTEUpdateSubmissionService.AcknowledgementRetryResult result = NTEUpdateSubmissionService.retryAcknowledgement(submission.Id);
        System.assertEquals(true, result.success);
        System.assertEquals(submission.Id, result.leadId);
        System.assertEquals(primaryContact.Email, NTEUpdateSubmissionService.acknowledgementRecipientByLeadId.get(submission.Id));
        System.assertEquals('More recent vehicle details', [SELECT NTE_Heavy_Item_1_Description__c FROM Opportunity WHERE Id = :booking.Id].NTE_Heavy_Item_1_Description__c);
        retained = [SELECT NTE_Update_Status__c, NTE_Applicant_Email_Status__c, NTE_Email_Error__c FROM Lead WHERE Id = :submission.Id];
        System.assertEquals('Matched and Applied', retained.NTE_Update_Status__c);
        System.assertEquals('Accepted by Salesforce', retained.NTE_Applicant_Email_Status__c);
        System.assertEquals(null, retained.NTE_Email_Error__c);
        Boolean blocked = false;
        try {
            NTEUpdateSubmissionService.retryAcknowledgement(submission.Id);
        } catch (AuraHandledException expected) {
            blocked = true;
        }
        System.assertEquals(true, blocked, 'A successful acknowledgement must not be retried by the failure action.');
        System.assertEquals(0, Limits.getEmailInvocations(), 'Synthetic tests must not invoke email delivery.');
    }

    @IsTest
    static void blankPrimaryEmailDoesNotFallBackToEventContactOrSubmitter() {
        Account accountRecord = new Account(Name = 'NTE Blank Primary Email Account');
        insert accountRecord;
        Opportunity booking = newNteOpportunity(accountRecord.Id, 'NTE Blank Primary Email Booking', 'NTE-TEST-BLANK-PRIMARY');
        booking.NTE_Initial_Staff_Count__c = 2;
        booking.NTE_Event_Contact_Email__c = 'day-contact@example.invalid';
        insert booking;
        Contact primaryContact = addPrimaryContact(booking);
        primaryContact.Email = null;
        update primaryContact;
        Lead submission = newLead(booking.Booking_Reference__c);
        populateRequiredExhibitorStaffFields(submission);
        update submission;

        NTEUpdateSubmissionService.processLeadIds(new Set<Id>{submission.Id}, true);
        Lead retained = [SELECT NTE_Update_Status__c, NTE_Applicant_Email_Status__c FROM Lead WHERE Id = :submission.Id];
        System.assertEquals('Matched and Applied', retained.NTE_Update_Status__c);
        System.assertEquals('Failed', retained.NTE_Applicant_Email_Status__c);
        System.assertNotEquals(null, [SELECT NTE_Staff_Update_Completed_At__c FROM Opportunity WHERE Id = :booking.Id].NTE_Staff_Update_Completed_At__c);
        System.assertEquals(false, NTEUpdateSubmissionService.acknowledgementRecipientByLeadId.containsKey(submission.Id));
        System.assertEquals(0, Limits.getEmailInvocations());
    }

    @IsTest
    static void emailRefusalKeepsSavedDetailsAndRetriesOnlyTheReceipt() {
        Account accountRecord = new Account(Name = 'NTE Email Refusal Account');
        insert accountRecord;
        Opportunity booking = newNteOpportunity(accountRecord.Id, 'NTE Email Refusal Booking', 'NTE-TEST-EMAIL-REFUSAL');
        booking.NTE_Initial_Staff_Count__c = 2;
        insert booking;
        Contact primaryContact = addPrimaryContact(booking);
        Lead submission = newLead(booking.Booking_Reference__c);
        populateRequiredExhibitorStaffFields(submission);
        update submission;

        NTEUpdateSubmissionService.acknowledgementFailureOverride = 'Synthetic email refusal';
        NTEUpdateSubmissionService.processLeadIds(new Set<Id>{submission.Id}, true);
        Lead retained = [SELECT NTE_Update_Status__c, NTE_Applicant_Email_Status__c, NTE_Email_Error__c FROM Lead WHERE Id = :submission.Id];
        System.assertEquals('Matched and Applied', retained.NTE_Update_Status__c);
        System.assertEquals('Failed', retained.NTE_Applicant_Email_Status__c);
        System.assertEquals('Synthetic email refusal', retained.NTE_Email_Error__c);
        System.assertEquals(primaryContact.Email, NTEUpdateSubmissionService.acknowledgementRecipientByLeadId.get(submission.Id));
        update new Opportunity(Id = booking.Id, NTE_Stand_Colleagues__c = 'Later Name One\nLater Name Two');
        NTEUpdateSubmissionService.acknowledgementFailureOverride = null;
        NTEUpdateSubmissionService.processLeadIds(new Set<Id>{submission.Id}, true);
        System.assertEquals('Later Name One\nLater Name Two', [SELECT NTE_Stand_Colleagues__c FROM Opportunity WHERE Id = :booking.Id].NTE_Stand_Colleagues__c);
        System.assertEquals('Accepted by Salesforce', [SELECT NTE_Applicant_Email_Status__c FROM Lead WHERE Id = :submission.Id].NTE_Applicant_Email_Status__c);
        System.assertEquals(0, Limits.getEmailInvocations());
    }

    @IsTest
    static void sameBatchTopUpsUseTheFirstValidAcceptedPurchase() {
        Account accountRecord = new Account(Name = 'NTE Same Batch Top-up Account');
        insert accountRecord;
        Opportunity booking = newNteOpportunity(accountRecord.Id, 'NTE Same Batch Top-up Booking', 'NTE-TEST-SAME-BATCH-TOPUP');
        booking.NTE_Initial_Staff_Count__c = 2;
        booking.NTE_Payment_Received__c = true;
        insert booking;
        addPrimaryContact(booking);
        List<Lead> submissions = new List<Lead>();
        for (Integer index = 0; index < 5; index++) {
            Lead submission = newLead(booking.Booking_Reference__c);
            populateRequiredExhibitorStaffFields(submission);
            if (index != 1) {
                submission.Top_Up_Staff_Required__c = 'Yes';
                submission.Top_Up_Staff_Count__c = index == 3 ? 3 : 2;
                submission.Top_Up_Staff_Names__c = index == 0 ? ' \n\t '
                    : (index == 3 ? 'First\nSecond\nThird'
                        : (index == 4 ? 'Corrected One\nCorrected Two' : 'Top-up One\nTop-up Two'));
            }
            update submission;
            Test.setCreatedDate(submission.Id, Datetime.newInstance(2026, 1, 1, 12, 0, 0).addSeconds(index));
            submissions.add(submission);
        }
        Set<Id> leadIds = new Map<Id, Lead>(submissions).keySet();
        NTEUpdateSubmissionService.processLeadIds(leadIds, true);
        Opportunity saved = [
            SELECT NTE_Top_Up_Staff_Count__c, NTE_Top_Up_Staff_Names__c, NTE_Top_Up_Staff_Total__c,
                NTE_Total_Staff_Count__c, NTE_Top_Up_Invoice_Required__c, NTE_Payment_Received__c
            FROM Opportunity WHERE Id = :booking.Id
        ];
        System.assertEquals(2, saved.NTE_Top_Up_Staff_Count__c);
        System.assertEquals('Corrected One\nCorrected Two', saved.NTE_Top_Up_Staff_Names__c);
        System.assertEquals(100, saved.NTE_Top_Up_Staff_Total__c);
        System.assertEquals(4, saved.NTE_Total_Staff_Count__c);
        System.assertEquals(true, saved.NTE_Top_Up_Invoice_Required__c);
        System.assertEquals(true, saved.NTE_Payment_Received__c);
        Map<Id, Lead> retained = new Map<Id, Lead>([SELECT NTE_Update_Status__c, NTE_Update_Error__c FROM Lead WHERE Id IN :leadIds]);
        System.assertEquals(2, retained.size());
        System.assertEquals('Failed', retained.get(submissions[0].Id).NTE_Update_Status__c);
        System.assert(retained.get(submissions[3].Id).NTE_Update_Error__c.contains('only be requested once'));
    }

    @IsTest
    static void oversizedTopUpDoesNotConsumeThePurchase() {
        Account accountRecord = new Account(Name = 'NTE Rolled Back Top-up Account');
        insert accountRecord;
        Opportunity booking = newNteOpportunity(accountRecord.Id, 'NTE Rolled Back Top-up Booking', 'NTE-TEST-ROLLED-BACK-TOPUP');
        booking.NTE_Initial_Staff_Count__c = 2;
        insert booking;
        addPrimaryContact(booking);
        Lead oversized = newLead(booking.Booking_Reference__c);
        populateRequiredExhibitorStaffFields(oversized);
        String longName = 'Name';
        while (longName.length() < 16000) longName += longName;
        longName = longName.left(16000);
        oversized.Staff_Base_Names__c = longName + '\n' + longName;
        oversized.Top_Up_Staff_Required__c = 'Yes';
        oversized.Top_Up_Staff_Count__c = 1;
        oversized.Top_Up_Staff_Names__c = longName.left(1000);
        update oversized;
        NTEUpdateSubmissionService.processLeadIds(new Set<Id>{oversized.Id}, true);
        System.assertEquals('Failed', [SELECT NTE_Update_Status__c FROM Lead WHERE Id = :oversized.Id].NTE_Update_Status__c);
        System.assertEquals(null, [SELECT NTE_Top_Up_Staff_Count__c FROM Opportunity WHERE Id = :booking.Id].NTE_Top_Up_Staff_Count__c);

        Lead valid = newLead(booking.Booking_Reference__c);
        populateRequiredExhibitorStaffFields(valid);
        valid.Top_Up_Staff_Required__c = 'Yes';
        valid.Top_Up_Staff_Count__c = 1;
        valid.Top_Up_Staff_Names__c = 'Accepted Additional Person';
        update valid;
        NTEUpdateSubmissionService.processLeadIds(new Set<Id>{valid.Id}, true);
        System.assertEquals(1, [SELECT NTE_Top_Up_Staff_Count__c FROM Opportunity WHERE Id = :booking.Id].NTE_Top_Up_Staff_Count__c);
    }

    @IsTest
    static void oversizedBatchEntryCannotLockTopUpOrRollBackOtherBookings() {
        Account company = new Account(Name = 'Birchwood Engineering');
        insert company;
        Opportunity firstBooking = newNteOpportunity(company.Id, 'Birchwood Engineering', 'NTE-STRESS-SUPP-LENGTH-A');
        firstBooking.NTE_Initial_Staff_Count__c = 2;
        Opportunity otherBooking = newNteOpportunity(company.Id, 'Birchwood Engineering Display', 'NTE-STRESS-SUPP-LENGTH-B');
        otherBooking.NTE_Initial_Staff_Count__c = 2;
        insert new List<Opportunity>{firstBooking, otherBooking};
        addPrimaryContact(firstBooking);
        addPrimaryContact(otherBooking);

        Lead oversized = newLead(firstBooking.Booking_Reference__c);
        populateRequiredExhibitorStaffFields(oversized);
        String longName = 'Name';
        while (longName.length() < 16000) longName += longName;
        longName = longName.left(16000);
        oversized.Staff_Base_Names__c = longName + '\n' + longName;
        oversized.Top_Up_Staff_Required__c = 'Yes';
        oversized.Top_Up_Staff_Count__c = 2;
        oversized.Top_Up_Staff_Names__c = longName.left(1000) + '\n' + longName.left(1000);
        Lead valid = newLead(firstBooking.Booking_Reference__c);
        populateRequiredExhibitorStaffFields(valid);
        valid.Top_Up_Staff_Required__c = 'Yes';
        valid.Top_Up_Staff_Count__c = 1;
        valid.Top_Up_Staff_Names__c = 'Grace Palmer';
        Lead other = newLead(otherBooking.Booking_Reference__c);
        populateRequiredExhibitorStaffFields(other);
        Lead logo = newLead(otherBooking.Booking_Reference__c);
        populateLogoUpdate(logo);
        update new List<Lead>{oversized, valid, other, logo};
        Test.setCreatedDate(oversized.Id, Datetime.newInstance(2026, 1, 1, 10, 0, 0));
        Test.setCreatedDate(valid.Id, Datetime.newInstance(2026, 1, 1, 10, 0, 1));

        Test.startTest();
        NTEUpdateSubmissionService.processLeadIds(new Set<Id>{oversized.Id, valid.Id, other.Id, logo.Id}, true);
        Test.stopTest();

        Opportunity accepted = [SELECT NTE_Top_Up_Staff_Count__c, NTE_Top_Up_Staff_Names__c,
            NTE_Top_Up_Staff_Total__c, NTE_Total_Staff_Count__c FROM Opportunity WHERE Id = :firstBooking.Id];
        System.assertEquals(1, accepted.NTE_Top_Up_Staff_Count__c, 'An invalid earlier entry must not consume the one purchase.');
        System.assertEquals('Grace Palmer', accepted.NTE_Top_Up_Staff_Names__c);
        System.assertEquals(50, accepted.NTE_Top_Up_Staff_Total__c);
        System.assertEquals(3, accepted.NTE_Total_Staff_Count__c);
        Opportunity independent = [SELECT NTE_Staff_Update_Completed_At__c, NTE_Logo_Update_Provided__c
            FROM Opportunity WHERE Id = :otherBooking.Id];
        System.assertNotEquals(null, independent.NTE_Staff_Update_Completed_At__c);
        System.assertEquals(true, independent.NTE_Logo_Update_Provided__c);
        Lead rejected = [SELECT NTE_Update_Status__c, NTE_Update_Error__c FROM Lead WHERE Id = :oversized.Id];
        System.assertEquals('Failed', rejected.NTE_Update_Status__c);
        System.assert(rejected.NTE_Update_Error__c.contains('combined staff name list is too long'));
        Set<Id> acceptedTemporaryIds = new Set<Id>{valid.Id, other.Id};
        System.assertEquals(2, [SELECT COUNT() FROM Lead WHERE Id IN :acceptedTemporaryIds AND IsDeleted = true ALL ROWS]);
        System.assertEquals('Matched and Applied', [SELECT NTE_Update_Status__c FROM Lead WHERE Id = :logo.Id].NTE_Update_Status__c);
        System.assertEquals(0, Limits.getEmailInvocations());
    }

    @IsTest
    static void namesUpdatesPreserveLegacyAllocationValues() {
        Account company = new Account(Name = 'Rowan Works');
        insert company;
        List<String> invalidCounts = new List<String>{null, '', 'Unknown', '0', '-1', '2.5', '100', '999999999999999999999999999999'};
        List<Opportunity> bookings = new List<Opportunity>();
        for (Integer index = 0; index < invalidCounts.size(); index++) {
            Opportunity booking = newNteOpportunity(company.Id, 'Rowan Works Display', 'NTE-STRESS-SUPP-COUNT-' + index);
            booking.NTE_Planned_Exhibitor_Count__c = invalidCounts[index];
            booking.NTE_Stand_Colleagues__c = 'Existing roster';
            bookings.add(booking);
        }
        insert bookings;
        Map<Id, Opportunity> originals = new Map<Id, Opportunity>([SELECT Id, NTE_Planned_Exhibitor_Count__c,
            NTE_Initial_Staff_Count__c, NTE_Total_Staff_Count__c FROM Opportunity WHERE Id IN :bookings]);
        List<Lead> submissions = new List<Lead>();
        for (Opportunity booking : bookings) {
            addPrimaryContact(booking);
            Lead submission = newLead(booking.Booking_Reference__c);
            populateRequiredExhibitorStaffFields(submission);
            submissions.add(submission);
        }
        update submissions;
        Set<Id> submissionIds = new Map<Id, Lead>(submissions).keySet();

        Test.startTest();
        NTEUpdateSubmissionService.processLeadIds(submissionIds, true);
        Test.stopTest();

        for (Lead accepted : [SELECT NTE_Update_Status__c, NTE_Update_Error__c FROM Lead WHERE Id IN :submissionIds ALL ROWS]) {
            System.assertEquals('Matched and Applied', accepted.NTE_Update_Status__c);
            System.assertEquals(null, accepted.NTE_Update_Error__c);
        }
        Set<Id> bookingIds = new Map<Id, Opportunity>(bookings).keySet();
        for (Opportunity unchanged : [SELECT Id, NTE_Staff_Update_Completed_At__c, NTE_Stand_Colleagues__c,
            NTE_Planned_Exhibitor_Count__c, NTE_Initial_Staff_Count__c, NTE_Total_Staff_Count__c
            FROM Opportunity WHERE Id IN :bookingIds]) {
            System.assertNotEquals(null, unchanged.NTE_Staff_Update_Completed_At__c);
            System.assertEquals('Alex Example\nSam Example', unchanged.NTE_Stand_Colleagues__c);
            Opportunity original = originals.get(unchanged.Id);
            System.assertEquals(original.NTE_Planned_Exhibitor_Count__c, unchanged.NTE_Planned_Exhibitor_Count__c);
            System.assertEquals(original.NTE_Initial_Staff_Count__c, unchanged.NTE_Initial_Staff_Count__c);
            System.assertEquals(original.NTE_Total_Staff_Count__c, unchanged.NTE_Total_Staff_Count__c);
        }
    }

    @IsTest
    static void receiptsUseTheMatchedBookingEventAcrossStaffAndVehicleForms() {
        Account company = new Account(Name = 'Ashford Mobility');
        insert company;
        List<Opportunity> bookings = new List<Opportunity>();
        List<String> eventCodes = new List<String>{'NTE2028', 'NTE2029', 'NTE2030'};
        for (Integer index = 0; index < eventCodes.size(); index++) {
            Opportunity booking = newNteOpportunity(company.Id, 'Ashford Mobility Display', 'NTE-STRESS-SUPP-EVENT-' + index);
            booking.NTE_Event_Code__c = eventCodes[index];
            booking.NTE_Initial_Staff_Count__c = 2;
            if (index == 1) booking.NTE_Source_Form_Type__c = 'Partner / Sponsor Application';
            bookings.add(booking);
        }
        insert bookings;
        List<Lead> submissions = new List<Lead>();
        Map<Id, String> expectedEvents = new Map<Id, String>();
        Map<Id, String> expectedRecipients = new Map<Id, String>();
        for (Integer index = 0; index < bookings.size(); index++) {
            Contact primary = addPrimaryContact(bookings[index]);
            Lead submission = newLead(' ' + bookings[index].Booking_Reference__c.toLowerCase() + ' ');
            if (index == 0) populateRequiredExhibitorStaffFields(submission);
            if (index == 1) populateRequiredPartnerStaffFields(submission, 2, 'Elliot Hughes\nRuth Fisher');
            if (index == 2) populateRequiredHeavyFields(submission);
            submission.NTE_Event_Code__c = 'NTE27';
            submissions.add(submission);
            expectedEvents.put(submission.Id, bookings[index].NTE_Event_Code__c);
            expectedRecipients.put(submission.Id, primary.Email);
        }
        update submissions;
        Set<Id> submissionIds = new Map<Id, Lead>(submissions).keySet();

        Test.startTest();
        NTEUpdateSubmissionService.processLeadIds(submissionIds, true);
        Test.stopTest();

        for (Lead receipt : [SELECT NTE_Update_Status__c, NTE_Event_Code__c, IsDeleted FROM Lead WHERE Id IN :submissionIds ALL ROWS]) {
            System.assertEquals('Matched and Applied', receipt.NTE_Update_Status__c);
            System.assertEquals(expectedEvents.get(receipt.Id), receipt.NTE_Event_Code__c);
            System.assertEquals(expectedRecipients.get(receipt.Id), NTEUpdateSubmissionService.acknowledgementRecipientByLeadId.get(receipt.Id));
            System.assertEquals(true, receipt.IsDeleted);
        }
        System.assertEquals(0, Limits.getEmailInvocations());
    }

    @IsTest
    static void logoConfirmationsDoNotRequireSignatureOrDate() {
        Account company = new Account(Name = 'Westfield Components');
        insert company;
        Opportunity booking = newNteOpportunity(company.Id, 'Westfield Components', 'NTE-STRESS-SUPP-LOGO-SIGN');
        booking.NTE_Event_Contact_Name__c = 'Existing event contact';
        booking.NTE_Payment_Received__c = true;
        booking.NTE_Invoice_Provided__c = true;
        booking.Amount = 777;
        insert booking;
        List<Lead> submissions = new List<Lead>();
        for (Integer index = 0; index < 3; index++) {
            Lead submission = newLead(booking.Booking_Reference__c);
            populateLogoUpdate(submission);
            if (index != 1) submission.Declaration_Name__c = index == 2 ? '   ' : null;
            if (index != 0) submission.Declaration_Date__c = null;
            submissions.add(submission);
        }
        update submissions;
        Set<Id> submissionIds = new Map<Id, Lead>(submissions).keySet();

        Test.startTest();
        NTEUpdateSubmissionService.processLeadIds(submissionIds, true);
        Test.stopTest();

        for (Lead retained : [SELECT NTE_Update_Status__c, NTE_Update_Error__c FROM Lead WHERE Id IN :submissionIds]) {
            System.assertEquals('Matched and Applied', retained.NTE_Update_Status__c);
            System.assertEquals(null, retained.NTE_Update_Error__c);
        }
        Opportunity updated = [SELECT NTE_Logo_Update_Provided__c, NTE_Logo_Update_Provided_At__c,
            NTE_Last_Update_Processed_At__c, NTE_Event_Contact_Name__c, NTE_Payment_Received__c,
            NTE_Invoice_Provided__c, Amount FROM Opportunity WHERE Id = :booking.Id];
        System.assertEquals(true, updated.NTE_Logo_Update_Provided__c);
        System.assertNotEquals(null, updated.NTE_Logo_Update_Provided_At__c);
        System.assertNotEquals(null, updated.NTE_Last_Update_Processed_At__c);
        System.assertEquals('Existing event contact', updated.NTE_Event_Contact_Name__c);
        System.assertEquals(true, updated.NTE_Payment_Received__c);
        System.assertEquals(true, updated.NTE_Invoice_Provided__c);
        System.assertEquals(777, updated.Amount);
        System.assertEquals(0, Limits.getEmailInvocations(), 'Logo updates have no separate acknowledgement.');
    }

    @IsTest
    static void otherPreparationFormsStillRequireTheirDeclarations() {
        Account company = new Account(Name = 'Declaration Preservation');
        insert company;
        Opportunity booking = newNteOpportunity(company.Id, 'Declaration Preservation', 'NTE-DECLARATION-PRESERVE');
        insert booking;
        List<Lead> submissions = new List<Lead>();
        for (String formType : new List<String>{'Exhibitor Staff Update', 'Partner / Sponsor Staff Update', 'Heavy Vehicle Details'}) {
            Lead submission = newLead(booking.Booking_Reference__c);
            submission.Web_Form_Type__c = formType;
            submission.Declaration_Name__c = null;
            submission.Declaration_Date__c = null;
            submissions.add(submission);
        }
        update submissions;
        Set<Id> ids = new Map<Id, Lead>(submissions).keySet();
        Test.startTest();
        NTEUpdateSubmissionService.processLeadIds(ids, true);
        Test.stopTest();
        for (Lead submission : [SELECT NTE_Update_Status__c, NTE_Update_Error__c FROM Lead WHERE Id IN :ids]) {
            System.assertEquals('Failed', submission.NTE_Update_Status__c);
            System.assert(submission.NTE_Update_Error__c.contains('signature and declaration date'));
        }
        System.assertEquals(null, [SELECT NTE_Last_Update_Processed_At__c FROM Opportunity WHERE Id = :booking.Id].NTE_Last_Update_Processed_At__c);
    }

    @IsTest
    static void appliedReceiptCannotBeRetargetedByEditingItsReference() {
        Account company = new Account(Name = 'Alder Precision');
        insert company;
        Opportunity acceptedBooking = newNteOpportunity(company.Id, 'Alder Precision', 'NTE-STRESS-SUPP-IDENTITY-A');
        acceptedBooking.NTE_Initial_Staff_Count__c = 2;
        Opportunity differentBooking = newNteOpportunity(company.Id, 'Alder Precision Workshop', 'NTE-STRESS-SUPP-IDENTITY-B');
        differentBooking.NTE_Initial_Staff_Count__c = 2;
        insert new List<Opportunity>{acceptedBooking, differentBooking};
        Contact primary = addPrimaryContact(acceptedBooking);
        addPrimaryContact(differentBooking);
        Lead submission = newLead(acceptedBooking.Booking_Reference__c);
        populateRequiredExhibitorStaffFields(submission);
        submission.NTE_Update_Booking_Id__c = String.valueOf(differentBooking.Id);
        update submission;
        NTEUpdateSubmissionService.bypassEmailDelivery = true;
        NTEUpdateSubmissionService.acknowledgementFailureOverride = 'Receipt unavailable';
        NTEUpdateSubmissionService.processLeadIds(new Set<Id>{submission.Id}, true);
        System.assertEquals(String.valueOf(acceptedBooking.Id), [SELECT NTE_Update_Booking_Id__c
            FROM Lead WHERE Id = :submission.Id].NTE_Update_Booking_Id__c, 'The server must replace any supplied booking ID.');

        NTEUpdateSubmissionService.acknowledgementFailureOverride = null;
        NTEUpdateSubmissionService.acknowledgementRecipientByLeadId.clear();
        update new Lead(Id = submission.Id, Target_Booking_Reference__c = differentBooking.Booking_Reference__c);
        Test.startTest();
        NTEUpdateSubmissionService.AcknowledgementRetryResult rejected = NTEUpdateSubmissionService.retryAcknowledgement(submission.Id);
        System.assertEquals(false, rejected.success);
        NTEUpdateSubmissionService.processLeadIds(new Set<Id>{submission.Id}, true);
        Test.stopTest();
        System.assertEquals(false, NTEUpdateSubmissionService.acknowledgementRecipientByLeadId.containsKey(submission.Id));
        System.assertEquals(null, [SELECT NTE_Staff_Update_Completed_At__c FROM Opportunity WHERE Id = :differentBooking.Id].NTE_Staff_Update_Completed_At__c);
        Lead failed = [SELECT NTE_Update_Status__c, NTE_Applicant_Email_Status__c, NTE_Email_Error__c FROM Lead WHERE Id = :submission.Id];
        System.assertEquals('Matched and Applied', failed.NTE_Update_Status__c);
        System.assertEquals('Failed', failed.NTE_Applicant_Email_Status__c);
        System.assert(failed.NTE_Email_Error__c.contains('saved booking identity and reference'));

        update new Lead(Id = submission.Id, Target_Booking_Reference__c = acceptedBooking.Booking_Reference__c);
        NTEUpdateSubmissionService.AcknowledgementRetryResult recovered = NTEUpdateSubmissionService.retryAcknowledgement(submission.Id);
        System.assertEquals(true, recovered.success);
        System.assertEquals(primary.Email, NTEUpdateSubmissionService.acknowledgementRecipientByLeadId.get(submission.Id));
        System.assertEquals(0, Limits.getEmailInvocations());
    }

    @IsTest
    static void receiptWithoutVerifiedAppliedIdentityCannotRematchAnotherBooking() {
        Account company = new Account(Name = 'Elmbridge Systems');
        insert company;
        Opportunity booking = newNteOpportunity(company.Id, 'Elmbridge Systems', 'NTE-STRESS-SUPP-MISSING-ID');
        booking.NTE_Initial_Staff_Count__c = 2;
        insert booking;
        addPrimaryContact(booking);
        List<Lead> receipts = new List<Lead>();
        for (String suppliedId : new List<String>{null, 'not-an-id', String.valueOf(company.Id)}) {
            Lead receipt = newLead(booking.Booking_Reference__c);
            populateRequiredExhibitorStaffFields(receipt);
            receipt.NTE_Update_Status__c = 'Matched and Applied';
            receipt.NTE_Applicant_Email_Status__c = 'Failed';
            receipt.NTE_Update_Booking_Id__c = suppliedId;
            receipts.add(receipt);
        }
        update receipts;
        NTEUpdateSubmissionService.bypassEmailDelivery = true;

        Test.startTest();
        NTEUpdateSubmissionService.processLeadIds(new Map<Id, Lead>(receipts).keySet(), true);
        for (Lead receipt : receipts) {
            System.assertEquals(false, NTEUpdateSubmissionService.retryAcknowledgement(receipt.Id).success);
            System.assertEquals(false, NTEUpdateSubmissionService.acknowledgementRecipientByLeadId.containsKey(receipt.Id));
        }
        Test.stopTest();
        System.assertEquals(null, [SELECT NTE_Staff_Update_Completed_At__c FROM Opportunity WHERE Id = :booking.Id].NTE_Staff_Update_Completed_At__c);
        System.assertEquals(0, Limits.getEmailInvocations());
    }

    @IsTest
    static void createFlowIgnoresSubmittedSuccessAndBookingIdentity() {
        Account company = new Account(Name = 'Fairhaven Design');
        insert company;
        Opportunity booking = newNteOpportunity(company.Id, 'Fairhaven Design', 'NTE-STRESS-SUPP-INTAKE');
        booking.NTE_Initial_Staff_Count__c = 2;
        insert booking;
        addPrimaryContact(booking);
        Lead submission = new Lead(FirstName = 'Ruth', LastName = 'Hughes', Company = company.Name,
            Email = 'ruth.hughes@example.invalid', Web_Form_Type__c = 'Exhibitor Staff Update',
            Target_Booking_Reference__c = booking.Booking_Reference__c,
            NTE_Update_Status__c = 'Matched and Applied', NTE_Applicant_Email_Status__c = 'Failed',
            NTE_Update_Booking_Id__c = String.valueOf(booking.Id), NTE_Update_Error__c = 'Supplied audit text',
            NTE_Email_Error__c = 'Supplied email text', Staff_Base_Names__c = 'Ruth Hughes',
            Top_Up_Staff_Required__c = 'No');
        NTEUpdateSubmissionService.bypassEmailDelivery = true;

        Test.startTest();
        insert submission;
        Lead queued = [SELECT NTE_Update_Status__c, NTE_Applicant_Email_Status__c, NTE_Update_Booking_Id__c,
            NTE_Update_Error__c, NTE_Email_Error__c FROM Lead WHERE Id = :submission.Id];
        System.assertEquals('Pending', queued.NTE_Update_Status__c);
        System.assertEquals(null, queued.NTE_Applicant_Email_Status__c);
        System.assertEquals(null, queued.NTE_Update_Booking_Id__c);
        System.assertEquals(null, queued.NTE_Update_Error__c);
        System.assertEquals(null, queued.NTE_Email_Error__c);
        Test.stopTest();

        Lead rejected = [SELECT NTE_Update_Status__c, NTE_Update_Error__c, NTE_Applicant_Email_Status__c,
            NTE_Update_Booking_Id__c FROM Lead WHERE Id = :submission.Id];
        System.assertEquals('Failed', rejected.NTE_Update_Status__c);
        System.assert(rejected.NTE_Update_Error__c.contains('signature and declaration date'));
        System.assertEquals(null, rejected.NTE_Applicant_Email_Status__c);
        System.assertEquals(null, rejected.NTE_Update_Booking_Id__c);
        System.assertEquals(null, [SELECT NTE_Staff_Update_Completed_At__c FROM Opportunity WHERE Id = :booking.Id].NTE_Staff_Update_Completed_At__c);
        System.assertEquals(0, Limits.getEmailInvocations());
    }

    @IsTest
    static void closedLostBookingAcceptsFirstTopUpHeavyAndLogoAfterPackWasSent() {
        Account company = new Account(Name = 'Northgate Manufacturing');
        insert company;
        Opportunity booking = newNteOpportunity(company.Id, 'Northgate Manufacturing', 'NTE-STRESS-SUPP-CLOSED');
        booking.StageName = 'Closed Lost';
        booking.NTE_Initial_Staff_Count__c = 2;
        booking.Amount = 800;
        booking.NTE_Invoice_Provided__c = true;
        booking.NTE_Payment_Received__c = true;
        booking.NTE_Payment_Received_At__c = System.now().addDays(-4);
        booking.NTE_Payment_Recorded_By__c = 'Helen Archer';
        booking.NTE_Final_Pack_Status__c = 'Sent';
        booking.NTE_Final_Pack_Sent_At__c = System.now().addDays(-2);
        booking.NTE_Joining_Instructions_By__c = 'Helen Archer';
        insert booking;
        Contact primary = addPrimaryContact(booking);
        Lead staff = newLead(booking.Booking_Reference__c);
        populateRequiredExhibitorStaffFields(staff);
        staff.Top_Up_Staff_Required__c = 'Yes';
        staff.Top_Up_Staff_Count__c = 1;
        staff.Top_Up_Staff_Names__c = 'Owen Carter';
        Lead heavy = newLead(booking.Booking_Reference__c);
        populateRequiredHeavyFields(heavy);
        Lead logo = newLead(booking.Booking_Reference__c);
        populateLogoUpdate(logo);
        update new List<Lead>{staff, heavy, logo};

        Test.startTest();
        NTEUpdateSubmissionService.processLeadIds(new Set<Id>{staff.Id, heavy.Id, logo.Id}, true);
        Test.stopTest();

        Opportunity saved = [SELECT StageName, Amount, NTE_Invoice_Provided__c, NTE_Payment_Received__c,
            NTE_Payment_Received_At__c, NTE_Payment_Recorded_By__c, NTE_Top_Up_Staff_Count__c, NTE_Top_Up_Staff_Total__c,
            NTE_Top_Up_Invoice_Required__c, NTE_Top_Up_Invoice_Provided__c, NTE_Top_Up_Payment_Received__c,
            NTE_Staff_Update_Completed_At__c, NTE_Heavy_Vehicle_Update_Completed_At__c, NTE_Logo_Update_Provided__c,
            NTE_Final_Pack_Status__c, NTE_Final_Pack_Sent_At__c, NTE_Joining_Instructions_By__c
            FROM Opportunity WHERE Id = :booking.Id];
        System.assertEquals('Closed Lost', saved.StageName);
        System.assertEquals(800, saved.Amount);
        System.assertEquals(true, saved.NTE_Invoice_Provided__c);
        System.assertEquals(true, saved.NTE_Payment_Received__c);
        System.assertEquals(booking.NTE_Payment_Received_At__c, saved.NTE_Payment_Received_At__c);
        System.assertEquals('Helen Archer', saved.NTE_Payment_Recorded_By__c);
        System.assertEquals(1, saved.NTE_Top_Up_Staff_Count__c);
        System.assertEquals(50, saved.NTE_Top_Up_Staff_Total__c);
        System.assertEquals(true, saved.NTE_Top_Up_Invoice_Required__c);
        System.assertEquals(false, saved.NTE_Top_Up_Invoice_Provided__c);
        System.assertEquals(false, saved.NTE_Top_Up_Payment_Received__c);
        System.assertNotEquals(null, saved.NTE_Staff_Update_Completed_At__c);
        System.assertNotEquals(null, saved.NTE_Heavy_Vehicle_Update_Completed_At__c);
        System.assertEquals(true, saved.NTE_Logo_Update_Provided__c);
        System.assertEquals('Sent', saved.NTE_Final_Pack_Status__c);
        System.assertEquals(booking.NTE_Final_Pack_Sent_At__c, saved.NTE_Final_Pack_Sent_At__c);
        System.assertEquals(booking.NTE_Joining_Instructions_By__c, saved.NTE_Joining_Instructions_By__c);
        System.assertEquals(primary.Email, NTEUpdateSubmissionService.acknowledgementRecipientByLeadId.get(staff.Id));
        System.assertEquals(primary.Email, NTEUpdateSubmissionService.acknowledgementRecipientByLeadId.get(heavy.Id));
        System.assertEquals('Matched and Applied', [SELECT NTE_Update_Status__c FROM Lead WHERE Id = :logo.Id].NTE_Update_Status__c);
        System.assertEquals(0, Limits.getEmailInvocations());
    }

    @IsTest
    static void noNewTopUpCorrectsBaseNamesWithoutChangingAcceptedPurchaseOrContacts() {
        Account company = new Account(Name = 'Hartwell Fabrication');
        insert company;
        Opportunity booking = newNteOpportunity(company.Id, 'Hartwell Fabrication', 'NTE-STRESS-SUPP-NO-TOPUP');
        booking.NTE_Initial_Staff_Count__c = 2;
        booking.NTE_Total_Staff_Count__c = 3;
        booking.NTE_Top_Up_Staff_Required__c = 'Yes';
        booking.NTE_Top_Up_Staff_Count__c = 1;
        booking.NTE_Top_Up_Staff_Names__c = 'Isla Stewart';
        booking.NTE_Top_Up_Staff_Unit_Price__c = 60;
        booking.NTE_Top_Up_Staff_Total__c = 60;
        booking.NTE_Top_Up_Invoice_Required__c = true;
        booking.NTE_Top_Up_Invoice_Provided__c = true;
        booking.NTE_Top_Up_Invoice_At__c = System.now().addDays(-3);
        booking.NTE_Top_Up_Invoice_By__c = 'Mary Fleming';
        booking.NTE_Top_Up_Payment_Received__c = true;
        booking.NTE_Top_Up_Payment_At__c = System.now().addDays(-1);
        booking.NTE_Top_Up_Payment_By__c = 'Mary Fleming';
        booking.NTE_Event_Contact_Name__c = 'Tom Gardner';
        booking.NTE_Event_Contact_Email__c = 'tom.gardner@example.invalid';
        booking.NTE_Secondary_Contact_Name__c = 'June Dawson';
        booking.NTE_Secondary_Contact_Email__c = 'june.dawson@example.invalid';
        booking.NTE_Invoiced_Email__c = 'accounts@example.invalid';
        insert booking;
        Contact primary = addPrimaryContact(booking);
        Lead submission = newLead(booking.Booking_Reference__c);
        populateRequiredExhibitorStaffFields(submission);
        submission.Staff_Base_Names__c = 'Nora Ellis\nJack Thompson';
        submission.Top_Up_Staff_Count__c = 99;
        submission.Top_Up_Staff_Names__c = 'Ignored hidden names';
        submission.Event_Contact_Name__c = 'Replacement event name';
        submission.Event_Contact_Email__c = 'replacement-event@example.invalid';
        submission.Secondary_Contact_Name__c = 'Replacement secondary name';
        submission.Secondary_Contact_Email__c = 'replacement-secondary@example.invalid';
        update submission;

        Test.startTest();
        NTEUpdateSubmissionService.processLeadIds(new Set<Id>{submission.Id}, true);
        Test.stopTest();

        Opportunity saved = [SELECT NTE_Total_Staff_Count__c, NTE_Stand_Colleagues__c, NTE_Top_Up_Staff_Required__c, NTE_Top_Up_Staff_Count__c,
            NTE_Top_Up_Staff_Names__c, NTE_Top_Up_Staff_Unit_Price__c, NTE_Top_Up_Staff_Total__c,
            NTE_Top_Up_Invoice_Required__c, NTE_Top_Up_Invoice_Provided__c, NTE_Top_Up_Invoice_At__c,
            NTE_Top_Up_Invoice_By__c, NTE_Top_Up_Payment_Received__c, NTE_Top_Up_Payment_At__c,
            NTE_Top_Up_Payment_By__c, NTE_Event_Contact_Name__c, NTE_Event_Contact_Email__c,
            NTE_Secondary_Contact_Name__c, NTE_Secondary_Contact_Email__c, NTE_Invoiced_Email__c
            FROM Opportunity WHERE Id = :booking.Id];
        System.assertEquals(3, saved.NTE_Total_Staff_Count__c);
        System.assertEquals('Nora Ellis\nJack Thompson\nIsla Stewart', saved.NTE_Stand_Colleagues__c);
        for (String fieldName : booking.getPopulatedFieldsAsMap().keySet()) {
            if (fieldName.startsWith('NTE_Top_Up_') || fieldName.startsWith('NTE_Event_Contact_')
                || fieldName.startsWith('NTE_Secondary_Contact_') || fieldName == 'NTE_Invoiced_Email__c') {
                System.assertEquals(booking.get(fieldName), saved.get(fieldName), fieldName + ' must be preserved.');
            }
        }
        Contact unchanged = [SELECT Email, Phone, MobilePhone FROM Contact WHERE Id = :primary.Id];
        System.assertEquals(primary.Email, unchanged.Email);
        System.assertEquals(primary.Phone, unchanged.Phone);
        System.assertEquals(primary.MobilePhone, unchanged.MobilePhone);
        System.assertEquals(primary.Id, [SELECT ContactId FROM OpportunityContactRole WHERE OpportunityId = :booking.Id AND IsPrimary = true].ContactId);
        Lead receipt = [SELECT Top_Up_Staff_Count__c, Top_Up_Staff_Names__c, Top_Up_Staff_Total__c FROM Lead WHERE Id = :submission.Id ALL ROWS];
        System.assertEquals(1, receipt.Top_Up_Staff_Count__c);
        System.assertEquals('Isla Stewart', receipt.Top_Up_Staff_Names__c);
        System.assertEquals(60, receipt.Top_Up_Staff_Total__c);
    }

    @IsTest
    static void incompleteOptionalHeavyItemsPreserveTheFullPreviousReplacement() {
        Account company = new Account(Name = 'Lakeside Transport');
        insert company;
        Opportunity booking = newNteOpportunity(company.Id, 'Lakeside Transport', 'NTE-STRESS-SUPP-HEAVY-OPTIONAL');
        booking.NTE_Heavy_Vehicle_Required__c = 'Yes';
        booking.NTE_Heavy_Vehicle_Update_Completed_At__c = System.now().addDays(-2);
        booking.NTE_Delivery_Window__c = 'Previous delivery window';
        booking.NTE_Haulier_Name__c = 'Lakeside Transport';
        booking.NTE_Haulier_Staff__c = 'Edith Moore';
        booking.NTE_Haulier_Vehicle_Type__c = 'Previous truck';
        booking.NTE_Haulier_Vehicle_Gross_Weight__c = '10,000 kg';
        booking.NTE_Haulier_Vehicle_Dimensions__c = '9m x 3m x 4m';
        booking.NTE_Haulier_Vehicle_Registration__c = 'AB26 CDE';
        booking.NTE_Logistics_Contact_Name__c = 'Previous Logistics Lead';
        booking.NTE_Logistics_Contact_Email__c = 'previous-logistics@example.invalid';
        booking.NTE_Logistics_Contact_Phone__c = '+44 7700 900800';
        booking.NTE_Logistics_Second_Contact_Name__c = 'Previous Second Contact';
        booking.NTE_Logistics_Second_Contact_Email__c = 'previous-second@example.invalid';
        booking.NTE_Logistics_Second_Contact_Phone__c = '+44 7700 900801';
        List<String> snapshotFields = new List<String>{'NTE_Heavy_Vehicle_Required__c', 'NTE_Heavy_Vehicle_Update_Completed_At__c',
            'NTE_Delivery_Window__c', 'NTE_Haulier_Name__c', 'NTE_Haulier_Staff__c', 'NTE_Haulier_Vehicle_Type__c',
            'NTE_Haulier_Vehicle_Gross_Weight__c', 'NTE_Haulier_Vehicle_Dimensions__c', 'NTE_Haulier_Vehicle_Registration__c',
            'NTE_Logistics_Contact_Name__c', 'NTE_Logistics_Contact_Email__c', 'NTE_Logistics_Contact_Phone__c',
            'NTE_Logistics_Second_Contact_Name__c', 'NTE_Logistics_Second_Contact_Email__c', 'NTE_Logistics_Second_Contact_Phone__c'};
        for (Integer index = 1; index <= 3; index++) {
            String prefix = 'NTE_Heavy_Item_' + index + '_';
            booking.put(prefix + 'Description__c', 'Existing vehicle ' + index);
            booking.put(prefix + 'Registration__c', 'AB2' + index + ' XYZ');
            booking.put(prefix + 'Dimensions__c', '5m x 2m x 2m');
            booking.put(prefix + 'Gross_Weight__c', '3,000 kg');
            for (String suffix : new List<String>{'Description__c', 'Registration__c', 'Dimensions__c', 'Gross_Weight__c'}) {
                snapshotFields.add(prefix + suffix);
            }
        }
        insert booking;
        addPrimaryContact(booking);
        String snapshotQuery = 'SELECT Id, ' + String.join(snapshotFields, ',') + ' FROM Opportunity WHERE Id = :bookingId';
        Id bookingId = booking.Id;
        Opportunity beforeUpdate = Database.query(snapshotQuery);
        List<Lead> invalidSubmissions = new List<Lead>();
        for (Integer index = 0; index < 4; index++) {
            Lead submission = newLead(booking.Booking_Reference__c);
            populateRequiredHeavyFields(submission);
            if (index == 0) submission.Heavy_Item_2_Registration__c = 'Registration only';
            if (index == 1) submission.Heavy_Item_2_Description__c = 'Description only';
            if (index == 2) {
                submission.Heavy_Item_3_Description__c = 'Third item without second';
                submission.Heavy_Item_3_Dimensions__c = '2m x 2m x 2m';
                submission.Heavy_Item_3_Gross_Weight__c = '1,000 kg';
            }
            if (index == 3) {
                submission.Heavy_Item_2_Description__c = 'Second item without weight';
                submission.Heavy_Item_2_Dimensions__c = '2m x 2m x 2m';
            }
            invalidSubmissions.add(submission);
        }
        update invalidSubmissions;
        Set<Id> submissionIds = new Map<Id, Lead>(invalidSubmissions).keySet();

        Test.startTest();
        NTEUpdateSubmissionService.processLeadIds(submissionIds, true);
        Test.stopTest();
        System.assertEquals(beforeUpdate, Database.query(snapshotQuery), 'No fragment of an invalid replacement may be applied.');
        for (Lead rejected : [SELECT NTE_Update_Status__c, NTE_Update_Error__c FROM Lead WHERE Id IN :submissionIds]) {
            System.assertEquals('Failed', rejected.NTE_Update_Status__c);
            System.assert(rejected.NTE_Update_Error__c.contains('Each additional item'));
        }

        Lead replacement = newLead(booking.Booking_Reference__c);
        populateRequiredHeavyFields(replacement);
        update replacement;
        NTEUpdateSubmissionService.processLeadIds(new Set<Id>{replacement.Id}, true);
        Opportunity replaced = Database.query(snapshotQuery);
        for (Integer index = 2; index <= 3; index++) {
            for (String suffix : new List<String>{'Description__c', 'Registration__c', 'Dimensions__c', 'Gross_Weight__c'}) {
                String fieldName = 'NTE_Heavy_Item_' + index + '_' + suffix;
                System.assertEquals(null, replaced.get(fieldName), fieldName + ' must clear in a complete replacement.');
            }
        }
        System.assertEquals(null, replaced.NTE_Heavy_Item_1_Registration__c);
        System.assertEquals(null, replaced.NTE_Haulier_Staff__c);
        System.assertEquals(null, replaced.NTE_Haulier_Vehicle_Registration__c);
        System.assertEquals(replacement.Delivery_Window__c, replaced.NTE_Delivery_Window__c);
        System.assertEquals(replacement.Haulier_Name__c, replaced.NTE_Haulier_Name__c);
        System.assertEquals(replacement.Event_Contact_Name__c, replaced.NTE_Logistics_Contact_Name__c, 'A complete replacement supplies the current logistics contacts.');
        System.assertEquals(replacement.Email, replaced.NTE_Logistics_Contact_Email__c);
        System.assertEquals(replacement.Phone, replaced.NTE_Logistics_Contact_Phone__c);
        System.assertEquals(replacement.Secondary_Contact_Name__c, replaced.NTE_Logistics_Second_Contact_Name__c);
        System.assertEquals(replacement.Secondary_Contact_Email__c, replaced.NTE_Logistics_Second_Contact_Email__c);
        System.assertEquals(replacement.Secondary_Contact_Phone__c, replaced.NTE_Logistics_Second_Contact_Phone__c);
    }

    @IsTest
    static void partnerRejectsInvalidQuantityOrBlankNames() {
        Account company = new Account(Name = 'Hillcrest Partners');
        insert company;
        Opportunity booking = newNteOpportunity(company.Id, 'Hillcrest Partners', 'NTE-STRESS-SUPP-PARTNER-COUNT');
        booking.NTE_Source_Form_Type__c = 'Partner / Sponsor Application';
        booking.NTE_Total_Staff_Count__c = 3;
        booking.NTE_Stand_Colleagues__c = 'Alice Hunter\nLiam Roberts\nRose Phillips';
        booking.Amount = 5000;
        insert booking;
        List<Integer> invalidCounts = new List<Integer>{null, 0, -1, 1};
        List<Lead> submissions = new List<Lead>();
        for (Integer index = 0; index < invalidCounts.size(); index++) {
            Lead submission = newLead(booking.Booking_Reference__c);
            populateRequiredPartnerStaffFields(submission, invalidCounts[index], index == 3 ? ' \n\t\n ' : 'Alice Hunter');
            submissions.add(submission);
        }
        update submissions;
        Set<Id> submissionIds = new Map<Id, Lead>(submissions).keySet();

        Test.startTest();
        NTEUpdateSubmissionService.processLeadIds(submissionIds, true);
        Test.stopTest();

        for (Lead rejected : [SELECT NTE_Update_Status__c, NTE_Update_Error__c FROM Lead WHERE Id IN :submissionIds]) {
            System.assertEquals('Failed', rejected.NTE_Update_Status__c);
            System.assert(rejected.NTE_Update_Error__c.contains('final attendee total')
                || rejected.NTE_Update_Error__c.contains('Enter the staff names'));
        }
        Opportunity unchanged = [SELECT NTE_Total_Staff_Count__c, NTE_Stand_Colleagues__c,
            NTE_Staff_Update_Completed_At__c, Amount FROM Opportunity WHERE Id = :booking.Id];
        System.assertEquals(3, unchanged.NTE_Total_Staff_Count__c);
        System.assertEquals(booking.NTE_Stand_Colleagues__c, unchanged.NTE_Stand_Colleagues__c);
        System.assertEquals(null, unchanged.NTE_Staff_Update_Completed_At__c);
        System.assertEquals(5000, unchanged.Amount);
    }

    @IsTest
    static void unexpectedQueueFailureIsRecordedWithoutThrowing() {
        Lead lead = newLead('NTE-TEST-FAILURE-AUDIT');

        Test.startTest();
        NTEUpdateSubmissionService.recordUnexpectedFailure(
            new Set<Id>{lead.Id},
            new NTEUpdateSubmissionServiceTestException('Synthetic queue failure')
        );
        Test.stopTest();

        Lead retained = [SELECT NTE_Update_Status__c, NTE_Update_Error__c FROM Lead WHERE Id = :lead.Id];
        System.assertEquals('Failed', retained.NTE_Update_Status__c);
        System.assert(retained.NTE_Update_Error__c.contains('Synthetic queue failure'));
    }

    private class NTEUpdateSubmissionServiceTestException extends Exception {}
}
