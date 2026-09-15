@IsTest
private class NTEStaffRosterFlexibilityTest {
    private static final String PRESERVED_FIELDS = 'Id, Amount, StageName, AccountId, NTE_Initial_Staff_Count__c, '
        + 'NTE_Listed_Price_Total__c, NTE_VAT_Rate__c, NTE_VAT_Total__c, NTE_Price_Adjustment__c, '
        + 'NTE_Invoice_Provided__c, NTE_Payment_Received__c, NTE_Payment_Received_At__c, NTE_Payment_Recorded_By__c, '
        + 'NTE_Event_Contact_Name__c, NTE_Event_Contact_Email__c, NTE_Secondary_Contact_Name__c, '
        + 'NTE_Secondary_Contact_Email__c, NTE_Invoiced_Email__c';
    private static final String TOP_UP_FIELDS = 'NTE_Top_Up_Staff_Required__c, NTE_Top_Up_Staff_Count__c, '
        + 'NTE_Top_Up_Staff_Unit_Price__c, NTE_Top_Up_Staff_Total__c, NTE_Top_Up_VAT_Rate__c, '
        + 'NTE_Top_Up_VAT_Total__c, NTE_Top_Up_Total_Inc_VAT__c, NTE_Top_Up_Invoice_Required__c, '
        + 'NTE_Top_Up_Invoice_Provided__c, NTE_Top_Up_Invoice_At__c, NTE_Top_Up_Invoice_By__c, '
        + 'NTE_Top_Up_Payment_Received__c, NTE_Top_Up_Payment_At__c, NTE_Top_Up_Payment_By__c, '
        + 'NTE_Top_Up_Payment_Requested_At__c';

    @TestSetup
    static void assignAccess() {
        PermissionSet access = [SELECT Id FROM PermissionSet WHERE Name = 'NTE_Forms_Administration' LIMIT 1];
        if ([SELECT COUNT() FROM PermissionSetAssignment WHERE AssigneeId = :UserInfo.getUserId()
            AND PermissionSetId = :access.Id] == 0) {
            insert new PermissionSetAssignment(AssigneeId = UserInfo.getUserId(), PermissionSetId = access.Id);
        }
    }

    private class Fixture {
        Opportunity booking;
        Contact primary;
    }
    private static Fixture fixture(String suffix, Boolean partner) {
        Account company = new Account(Name = 'Willowbrook Roster ' + suffix); insert company;
        Fixture value = new Fixture();
        value.booking = new Opportunity(Name = company.Name, AccountId = company.Id,
            StageName = 'Prospecting', CloseDate = Date.today().addDays(30),
            RecordTypeId = [SELECT Id FROM RecordType WHERE SobjectType = 'Opportunity'
                AND DeveloperName = 'NTE_Event_Opportunity' LIMIT 1].Id,
            Booking_Reference__c = 'NTE-ROSTER-FLEX-' + suffix, NTE_Event_Code__c = 'NTE2027',
            NTE_Source_Form_Type__c = partner ? 'Partner / Sponsor Application' : 'Exhibitor Application',
            NTE_Initial_Staff_Count__c = 2, NTE_Total_Staff_Count__c = 2, NTE_Planned_Exhibitor_Count__c = '2',
            Amount = partner ? 2400 : 120, NTE_Listed_Price_Total__c = partner ? 2000 : 100,
            NTE_VAT_Rate__c = 20, NTE_Invoice_Provided__c = true, NTE_Payment_Received__c = true,
            NTE_Payment_Received_At__c = System.now().addDays(-4), NTE_Payment_Recorded_By__c = 'Original finance recorder',
            NTE_Event_Contact_Name__c = 'Original operations contact', NTE_Event_Contact_Email__c = 'operations@example.invalid',
            NTE_Secondary_Contact_Name__c = 'Original secondary contact', NTE_Secondary_Contact_Email__c = 'secondary@example.invalid',
            NTE_Invoiced_Email__c = 'billing@example.invalid', NTE_Stand_Colleagues__c = 'Earlier saved staff details');
        insert value.booking;
        value.primary = new Contact(AccountId = company.Id, FirstName = 'Helen', LastName = 'Bancroft',
            Email = 'primary@example.invalid', Phone = '07700 900710', MobilePhone = '07700 900711');
        insert value.primary;
        insert new OpportunityContactRole(OpportunityId = value.booking.Id, ContactId = value.primary.Id, IsPrimary = true);
        return value;
    }

    private static Opportunity snapshot(Id bookingId, Boolean includeTopUp) {
        return Database.query('SELECT ' + PRESERVED_FIELDS + (includeTopUp ? ', ' + TOP_UP_FIELDS : '')
            + ' FROM Opportunity WHERE Id = :bookingId');
    }
    private static void verifyIdentity(Fixture value) {
        Contact primary = [SELECT Email, Phone, MobilePhone FROM Contact WHERE Id = :value.primary.Id];
        System.assertEquals(value.primary.Email, primary.Email);
        System.assertEquals(value.primary.Phone, primary.Phone);
        System.assertEquals(value.primary.MobilePhone, primary.MobilePhone);
        System.assertEquals(value.primary.Id, [SELECT ContactId FROM OpportunityContactRole
            WHERE OpportunityId = :value.booking.Id AND IsPrimary = true].ContactId);
    }
    private static Lead submission(Fixture value, String names) {
        Lead source = new Lead(LastName = 'Independent submitter', Company = value.booking.Name,
            Email = 'submitter@example.invalid', Target_Booking_Reference__c = value.booking.Booking_Reference__c);
        insert source;
        source.Web_Form_Type__c = value.booking.NTE_Source_Form_Type__c == 'Partner / Sponsor Application'
            ? 'Partner / Sponsor Staff Update' : 'Exhibitor Staff Update';
        source.Staff_Base_Names__c = names;
        source.Top_Up_Staff_Required__c = 'No';
        source.Declaration_Name__c = 'Independent submitter'; source.Declaration_Date__c = Date.today();
        source.Event_Contact_Name__c = 'Not a replacement for the saved contact';
        source.Event_Contact_Email__c = 'different-operations@example.invalid';
        source.Secondary_Contact_Email__c = 'different-secondary@example.invalid';
        // Exhibitor forms no longer derive or submit a base quantity from names.
        update source;
        return source;
    }
    private static void apply(Lead source) {
        NTEUpdateSubmissionService.processLeadIds(new Set<Id>{source.Id}, true);
        Lead applied = [SELECT NTE_Update_Status__c, NTE_Applicant_Email_Status__c FROM Lead WHERE Id = :source.Id ALL ROWS];
        System.assertEquals('Matched and Applied', applied.NTE_Update_Status__c);
        System.assertEquals('Accepted by Salesforce', applied.NTE_Applicant_Email_Status__c);
    }

    @IsTest
    static void fewerAndMoreBaseNamesPreserveBookedQuantityAndPaidHistory() {
        Fixture value = fixture('BASE', false);
        Opportunity original = snapshot(value.booking.Id, false);
        Lead fewer = submission(value, 'Helen Bancroft');
        Lead more = submission(value, 'Helen Bancroft\nOliver Carter\nZoë Fairfax\nImogen Carstairs');
        Test.startTest();
        apply(fewer);
        Opportunity first = [SELECT NTE_Stand_Colleagues__c, NTE_Total_Staff_Count__c FROM Opportunity WHERE Id = :value.booking.Id];
        System.assertEquals(fewer.Staff_Base_Names__c, first.NTE_Stand_Colleagues__c);
        System.assertEquals(2, first.NTE_Total_Staff_Count__c);
        System.assertEquals(original, snapshot(value.booking.Id, false));
        apply(more);
        Test.stopTest();
        Opportunity second = [SELECT NTE_Stand_Colleagues__c, NTE_Total_Staff_Count__c, NTE_Planned_Exhibitor_Count__c
            FROM Opportunity WHERE Id = :value.booking.Id];
        System.assertEquals(more.Staff_Base_Names__c, second.NTE_Stand_Colleagues__c);
        System.assertEquals(2, second.NTE_Total_Staff_Count__c);
        System.assertEquals('2', second.NTE_Planned_Exhibitor_Count__c);
        System.assertEquals(original, snapshot(value.booking.Id, false));
        verifyIdentity(value);
        System.assertEquals(0, Limits.getEmailInvocations());
    }

    @IsTest
    static void topUpNamesDoNotRepricePurchasedPlacesOrResetTheirReceipt() {
        Fixture value = fixture('TOPUP', false);
        Opportunity original = snapshot(value.booking.Id, false);
        Lead first = submission(value, 'Helen Bancroft');
        first.Top_Up_Staff_Required__c = 'Yes'; first.Top_Up_Staff_Count__c = 2;
        first.Top_Up_Staff_Names__c = 'Oliver Carter'; update first;
        Test.startTest();
        apply(first);
        Opportunity purchased = [SELECT NTE_Total_Staff_Count__c, NTE_Top_Up_Staff_Count__c,
            NTE_Top_Up_Staff_Total__c, NTE_Top_Up_VAT_Total__c, NTE_Top_Up_Total_Inc_VAT__c
            FROM Opportunity WHERE Id = :value.booking.Id];
        System.assertEquals(2, purchased.NTE_Top_Up_Staff_Count__c);
        System.assertEquals(4, purchased.NTE_Total_Staff_Count__c);
        System.assertEquals(100, purchased.NTE_Top_Up_Staff_Total__c);
        System.assertEquals(20, purchased.NTE_Top_Up_VAT_Total__c);
        System.assertEquals(120, purchased.NTE_Top_Up_Total_Inc_VAT__c);
        System.assertEquals(original, snapshot(value.booking.Id, false));
        update new Opportunity(Id = value.booking.Id, NTE_Top_Up_Invoice_Provided__c = true,
            NTE_Top_Up_Invoice_At__c = System.now().addDays(-2), NTE_Top_Up_Invoice_By__c = 'Top-up finance recorder',
            NTE_Top_Up_Payment_Requested_At__c = System.now().addDays(-2), NTE_Top_Up_Payment_Received__c = true,
            NTE_Top_Up_Payment_At__c = System.now().addDays(-1), NTE_Top_Up_Payment_By__c = 'Top-up finance recorder');
        Opportunity paidPurchase = snapshot(value.booking.Id, true);
        Lead correction = submission(value, 'Helen Bancroft\nZoë Fairfax\nImogen Carstairs');
        correction.Top_Up_Staff_Required__c = 'Yes'; correction.Top_Up_Staff_Count__c = 2;
        correction.Top_Up_Staff_Names__c = 'Oliver Carter\nHarriet Redfern\nAisha Mercer\nClara Beaumont';
        update correction; apply(correction);
        Test.stopTest();
        System.assertEquals(paidPurchase, snapshot(value.booking.Id, true),
            'A names-only correction must preserve quantity, price, tax, document and payment history.');
        Opportunity corrected = [SELECT NTE_Total_Staff_Count__c, NTE_Stand_Colleagues__c, NTE_Top_Up_Staff_Names__c
            FROM Opportunity WHERE Id = :value.booking.Id];
        System.assertEquals(4, corrected.NTE_Total_Staff_Count__c);
        System.assertEquals(correction.Top_Up_Staff_Names__c, corrected.NTE_Top_Up_Staff_Names__c);
        System.assertEquals(correction.Staff_Base_Names__c + '\n' + correction.Top_Up_Staff_Names__c, corrected.NTE_Stand_Colleagues__c);
        verifyIdentity(value);
        System.assertEquals(0, [SELECT COUNT() FROM NTE_Payment_Request__c WHERE Opportunity__c = :value.booking.Id]);
        System.assertEquals(0, Limits.getEmailInvocations());
    }

    @IsTest
    static void missingLegacyAllocationDoesNotBlockAnExplicitPricedTopUp() {
        Fixture value = fixture('LEGACY', false);
        update new Opportunity(Id = value.booking.Id, NTE_Initial_Staff_Count__c = null,
            NTE_Total_Staff_Count__c = null, NTE_Planned_Exhibitor_Count__c = 'Unknown');
        Opportunity original = snapshot(value.booking.Id, false);
        Lead source = submission(value, 'Helen Bancroft\nOliver Carter\nZoë Fairfax');
        source.Top_Up_Staff_Required__c = 'Yes'; source.Top_Up_Staff_Count__c = 2;
        source.Top_Up_Staff_Names__c = 'Imogen Carstairs'; update source;

        Test.startTest();
        apply(source);
        Test.stopTest();

        Opportunity updated = [SELECT NTE_Total_Staff_Count__c, NTE_Planned_Exhibitor_Count__c,
            NTE_Top_Up_Staff_Count__c, NTE_Top_Up_Staff_Total__c, NTE_Top_Up_VAT_Total__c,
            NTE_Top_Up_Total_Inc_VAT__c, NTE_Top_Up_Payment_Received__c, NTE_Stand_Colleagues__c
            FROM Opportunity WHERE Id = :value.booking.Id];
        System.assertEquals(null, updated.NTE_Total_Staff_Count__c,
            'Unknown legacy allocation must not be inferred from the supplied names.');
        System.assertEquals('Unknown', updated.NTE_Planned_Exhibitor_Count__c);
        System.assertEquals(2, updated.NTE_Top_Up_Staff_Count__c);
        System.assertEquals(100, updated.NTE_Top_Up_Staff_Total__c);
        System.assertEquals(20, updated.NTE_Top_Up_VAT_Total__c);
        System.assertEquals(120, updated.NTE_Top_Up_Total_Inc_VAT__c);
        System.assertEquals(false, updated.NTE_Top_Up_Payment_Received__c);
        System.assertEquals(source.Staff_Base_Names__c + '\n' + source.Top_Up_Staff_Names__c, updated.NTE_Stand_Colleagues__c);
        System.assertEquals(original, snapshot(value.booking.Id, false));
        verifyIdentity(value);
        System.assertEquals(0, [SELECT COUNT() FROM NTE_Payment_Request__c WHERE Opportunity__c = :value.booking.Id]);
        System.assertEquals(0, Limits.getEmailInvocations());
    }

    @IsTest
    static void partnerUsesEnteredTotalIndependentlyOfFewerAndMoreNames() {
        Fixture value = fixture('PARTNER', true);
        Opportunity original = snapshot(value.booking.Id, false);
        Lead fewer = submission(value, 'Helen Bancroft'); fewer.Total_Staff_Count__c = 3; update fewer;
        Lead more = submission(value, 'Helen Bancroft\nOliver Carter\nZoë Fairfax\nImogen Carstairs\nAisha Mercer');
        more.Total_Staff_Count__c = 3; update more;
        Test.startTest();
        apply(fewer);
        System.assertEquals(3, [SELECT NTE_Total_Staff_Count__c FROM Opportunity WHERE Id = :value.booking.Id].NTE_Total_Staff_Count__c);
        System.assertEquals(fewer.Staff_Base_Names__c, [SELECT NTE_Stand_Colleagues__c FROM Opportunity WHERE Id = :value.booking.Id].NTE_Stand_Colleagues__c);
        apply(more);
        Test.stopTest();
        Opportunity updated = [SELECT NTE_Total_Staff_Count__c, NTE_Planned_Exhibitor_Count__c, NTE_Stand_Colleagues__c,
            NTE_Top_Up_Staff_Total__c FROM Opportunity WHERE Id = :value.booking.Id];
        System.assertEquals(3, updated.NTE_Total_Staff_Count__c);
        System.assertEquals('3', updated.NTE_Planned_Exhibitor_Count__c);
        System.assertEquals(more.Staff_Base_Names__c, updated.NTE_Stand_Colleagues__c);
        System.assertEquals(null, updated.NTE_Top_Up_Staff_Total__c);
        System.assertEquals(original, snapshot(value.booking.Id, false));
        verifyIdentity(value);
        System.assertEquals(0, Limits.getEmailInvocations());
    }
}
