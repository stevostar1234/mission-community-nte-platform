@IsTest
private class NTEPanelStressTest {
    private static final String EVENT_CODE = 'NTE2027';

    @TestSetup
    static void fixtures() {
        for (PermissionSet permissions : [SELECT Id FROM PermissionSet
            WHERE Name IN ('NTE_Forms_Administration', 'NTE_Management_User')]) {
            if ([SELECT COUNT() FROM PermissionSetAssignment WHERE AssigneeId = :UserInfo.getUserId()
                AND PermissionSetId = :permissions.Id] == 0) {
                insert new PermissionSetAssignment(AssigneeId = UserInfo.getUserId(), PermissionSetId = permissions.Id);
            }
        }
        System.runAs(new User(Id = UserInfo.getUserId())) {
            NTEInboundLeadService.bypassEmailDelivery = true;
            Account organisation = new Account(Name = 'Ashcombe Engineering');
            insert organisation;
            insert new List<Opportunity>{
                booking(organisation.Id, 'Ashcombe Engineering', EVENT_CODE),
                booking(organisation.Id, 'Linden Logistics', 'NTE2099')
            };
            List<Lead> leads = new List<Lead>{
                new Lead(FirstName = 'Anna', LastName = 'Ellis', Company = 'Ashcombe Engineering', Email = 'anna.ellis@example.invalid'),
                new Lead(FirstName = 'Ben', LastName = 'Morgan', Company = 'Linden Logistics', Email = 'ben.morgan@example.invalid')
            };
            insert leads;
            leads[0].Web_Form_Type__c = 'Exhibitor Expression of Interest';
            leads[0].NTE_Event_Code__c = EVENT_CODE;
            leads[1].Web_Form_Type__c = 'Partner / Sponsor Expression of Interest';
            leads[1].NTE_Event_Code__c = 'NTE2099';
            update leads;
        }
    }

    @IsTest
    static void inactiveAndWrongSourceBookingsRejectEveryStaleFinanceAction() {
        Opportunity original = [SELECT Id, AccountId FROM Opportunity WHERE Name = 'Ashcombe Engineering'];
        Opportunity unrelated = booking(original.AccountId, 'Cedar Motor Works', EVENT_CODE);
        unrelated.NTE_Source_Form_Type__c = 'Guest Registration';
        insert unrelated;
        Set<Id> invalidIds = new Set<Id>{original.Id, unrelated.Id};
        update new Opportunity(Id = original.Id, StageName = 'Closed Lost');
        for (Id idValue : new List<Id>{original.Id, unrelated.Id}) {
            for (String action : new List<String>{'QUOTE_PROVIDED', 'INVOICE_PROVIDED', 'PAYMENT_RECEIVED',
                'TOP_UP_INVOICE_PROVIDED', 'TOP_UP_PAYMENT_RECEIVED'}) {
                Boolean blocked = false;
                try { NTE_MasterPanelController.updateMilestone(idValue, action); }
                catch (AuraHandledException expected) { blocked = true; }
                System.assert(blocked, action + ' must recheck that the selected record remains an active NTE booking.');
            }
        }
        Test.startTest();
        NTE_MasterPanelController.DashboardResponse response = dashboard('APPROVED', 25, 0);
        NTE_MasterPanelController.HomeDashboardResponse home = NTE_MasterPanelController.getHomeDashboard(EVENT_CODE);
        Test.stopTest();
        System.assertEquals(0, response.totalRows);
        System.assertEquals(0, home.headlines[1].count);
        System.assertEquals(0, [SELECT COUNT() FROM NTE_Email_Dispatch__c WHERE Opportunity__c IN :invalidIds]);
        for (Opportunity unchanged : [SELECT NTE_Quote_Provided__c, NTE_Invoice_Provided__c,
            NTE_Payment_Received__c, NTE_Top_Up_Invoice_Provided__c, NTE_Top_Up_Payment_Received__c
            FROM Opportunity WHERE Id IN :invalidIds]) {
            System.assertEquals(false, unchanged.NTE_Quote_Provided__c);
            System.assertEquals(false, unchanged.NTE_Invoice_Provided__c);
            System.assertEquals(false, unchanged.NTE_Payment_Received__c);
            System.assertEquals(false, unchanged.NTE_Top_Up_Invoice_Provided__c);
            System.assertEquals(false, unchanged.NTE_Top_Up_Payment_Received__c);
        }
    }

    @IsTest
    static void closedWonBookingsKeepLegitimateFinanceWork() {
        Opportunity source = [SELECT Id FROM Opportunity WHERE Name = 'Ashcombe Engineering'];
        update new Opportunity(Id = source.Id, StageName = 'Closed Won');
        Test.startTest();
        NTE_MasterPanelController.DashboardResponse response = dashboard('INVOICE_REQUIRED', 25, 0);
        NTE_MasterPanelController.ActionResult result = NTE_MasterPanelController.updateMilestone(source.Id, 'INVOICE_PROVIDED');
        Test.stopTest();
        System.assertEquals(1, response.totalRows);
        System.assertEquals(source.Id, response.rows[0].recordId);
        System.assertEquals(true, result.success);
        System.assertEquals(true, [SELECT NTE_Invoice_Provided__c FROM Opportunity WHERE Id = :source.Id].NTE_Invoice_Provided__c);
    }

    @IsTest
    static void staleCommunicationFiltersCannotSelectAnotherEventOrAllOwners() {
        Id accountId = [SELECT Id FROM Account LIMIT 1].Id;
        for (List<String> filters : new List<List<String>>{
            new List<String>{'NTE2028', 'ALL', null},
            new List<String>{null, 'ALL', null},
            new List<String>{EVENT_CODE, 'ALL', 'not-an-owner'},
            new List<String>{EVENT_CODE, 'ALL', String.valueOf(accountId)},
            new List<String>{EVENT_CODE, 'LAST_365', null}
        }) {
            Boolean blocked = false;
            try { NTE_MasterPanelController.getCommunicationRecordIds(filters[0], filters[1], filters[2], 'INTEREST'); }
            catch (AuraHandledException expected) { blocked = true; }
            System.assert(blocked, 'A stale or invalid filter must not broaden a deliberate recipient selection.');
        }
        Test.startTest();
        List<Id> current = NTE_MasterPanelController.getCommunicationRecordIds(EVENT_CODE, 'ALL', UserInfo.getUserId(), 'INTEREST');
        List<Id> future = NTE_MasterPanelController.getCommunicationRecordIds('NTE2099', 'ALL', UserInfo.getUserId(), 'INTEREST');
        Test.stopTest();
        System.assertEquals(new Set<Id>{[SELECT Id FROM Lead WHERE LastName = 'Ellis'].Id}, new Set<Id>(current));
        System.assertEquals(new Set<Id>{[SELECT Id FROM Lead WHERE LastName = 'Morgan'].Id}, new Set<Id>(future));
    }

    @IsTest
    static void unrelatedAndSupplementaryEventsDoNotBecomeEmptyDefaultChoices() {
        Lead unrelated = new Lead(LastName = 'Carter', Company = 'Bracken Consulting', Email = 'dana.carter@example.invalid');
        Lead updateSubmission = new Lead(LastName = 'Reed', Company = 'Reed Transport', Email = 'fran.reed@example.invalid');
        insert new List<Lead>{unrelated, updateSubmission};
        unrelated.NTE_Event_Code__c = 'NTE9999';
        updateSubmission.NTE_Event_Code__c = 'NTE9998';
        updateSubmission.Web_Form_Type__c = 'Heavy Vehicle Details';
        update new List<Lead>{unrelated, updateSubmission};
        Test.startTest();
        NTE_MasterPanelController.HomeDashboardResponse home = NTE_MasterPanelController.getHomeDashboard(null);
        Test.stopTest();
        System.assertEquals('NTE2099', home.selectedEventCode);
        System.assertEquals(new Set<String>{EVENT_CODE, 'NTE2099'}, eventCodes(home.eventOptions));
    }

    @IsTest
    static void validYearDefaultPreservesExplicitHistoricalCodeSelection() {
        Id accountId = [SELECT Id FROM Account LIMIT 1].Id;
        insert booking(accountId, 'Bracken Consulting', 'ZZZZ-LEGACY');
        Test.startTest();
        NTE_MasterPanelController.HomeDashboardResponse home = NTE_MasterPanelController.getHomeDashboard(null);
        NTE_MasterPanelController.DashboardResponse historical = NTE_MasterPanelController.getDashboard(
            'ZZZZ-LEGACY', 'ALL', null, 'APPROVED', 25, 0);
        Test.stopTest();
        System.assertEquals('NTE2099', home.selectedEventCode);
        System.assert(eventCodes(home.eventOptions).contains('ZZZZ-LEGACY'),
            'An irregular historical event stays visible for explicit selection and correction.');
        System.assertEquals('ZZZZ-LEGACY', historical.selectedEventCode);
        System.assertEquals(1, historical.totalRows);
        System.assertEquals('Bracken Consulting', historical.rows[0].name);
    }

    @IsTest
    static void recentRowsShowDecisionsInsteadOfReopeningReviewInTheirStatus() {
        Lead interest = [SELECT Id FROM Lead WHERE LastName = 'Ellis'];
        Lead rejected = new Lead(LastName = 'Brooks', Company = 'Bramley Design', Email = 'jamie.brooks@example.invalid');
        insert rejected;
        update new Lead(Id = rejected.Id, Web_Form_Type__c = 'Partner / Sponsor Application',
            NTE_Event_Code__c = EVENT_CODE, NTE_Application_Rejected__c = true);
        update new Lead(Id = interest.Id, NTE_Interest_Progressed__c = true, NTE_Invitation_Status__c = 'Sent');
        Test.startTest();
        NTE_MasterPanelController.DashboardResponse response = dashboard('RECENT', 25, 0);
        Test.stopTest();
        Map<Id, String> stages = new Map<Id, String>();
        for (NTE_MasterPanelController.DashboardRow row : response.rows) stages.put(row.recordId, row.stage);
        System.assertEquals('Application invited', stages.get(interest.Id));
        System.assertEquals('Rejected', stages.get(rejected.Id));
        System.assertEquals(0, queueCounts(response).get('INTEREST'));
        System.assertEquals(0, queueCounts(response).get('APPLICATION_REVIEW'));
    }

    @IsTest
    static void repeatedRejectionCannotWriteASecondDecision() {
        Lead interest = [SELECT Id FROM Lead WHERE LastName = 'Ellis'];
        NTE_MasterPanelController.updateLeadDecision(interest.Id, 'INTEREST_NOT_PROGRESSED');
        Integer beforeDml = Limits.getDmlStatements();
        Boolean rejected = false;
        try { NTE_MasterPanelController.updateLeadDecision(interest.Id, 'INTEREST_NOT_PROGRESSED'); }
        catch (AuraHandledException expected) { rejected = true; }
        System.assert(rejected);
        System.assertEquals(beforeDml, Limits.getDmlStatements());
        System.assertEquals(true, [SELECT NTE_Interest_Not_Progressed__c FROM Lead WHERE Id = :interest.Id].NTE_Interest_Not_Progressed__c);
    }

    @IsTest
    static void paginationLimitAndShrinkingQueuesHaveAnExplicitStableLastPage() {
        // total, page size, requested offset, accepted offset, accessible rows, final offset
        for (List<Integer> scenario : new List<List<Integer>>{
            new List<Integer>{0, 25, 500, 0, 0, 0},
            new List<Integer>{26, 25, 0, 0, 26, 25},
            new List<Integer>{26, 25, 500, 25, 26, 25},
            new List<Integer>{50, 25, 50, 25, 50, 25},
            new List<Integer>{51, 50, 500, 50, 51, 50},
            new List<Integer>{1999, 25, 25000, 1975, 1999, 1975},
            new List<Integer>{2000, 25, 1975, 1975, 2000, 1975},
            new List<Integer>{2001, 25, 2000, 1975, 2000, 1975},
            new List<Integer>{15000, 50, 25000, 1950, 2000, 1950},
            new List<Integer>{15000, 10, 25000, 1990, 2000, 1990},
            new List<Integer>{26, 25, -50, 0, 26, 25}
        }) {
            NTE_MasterPanelController.DashboardResponse response = new NTE_MasterPanelController.DashboardResponse();
            response.totalRows = scenario[0];
            response.pageSize = scenario[1];
            NTE_MasterPanelController.configurePagination(response, scenario[2]);
            System.assertEquals(scenario[3], response.offsetRows, JSON.serialize(scenario));
            System.assertEquals(scenario[4], response.accessibleRows);
            System.assertEquals(scenario[5], response.maxOffsetRows);
            System.assertEquals(scenario[0] > 2000, response.rowsLimited);
            System.assertEquals(scenario[3] < scenario[5], response.hasNextPage);
        }
        Test.startTest();
        NTE_MasterPanelController.DashboardResponse actual = dashboard('APPROVED', 25, 500);
        Test.stopTest();
        System.assertEquals(0, actual.offsetRows);
        System.assertEquals(1, actual.rows.size(), 'A queue that shrank still returns its remaining current page.');
        System.assertEquals(false, actual.hasNextPage);
    }

    @IsTest
    static void mergedRecentPagesRemainDeterministicAcrossBothRecordObjects() {
        Id accountId = [SELECT Id FROM Account LIMIT 1].Id;
        List<Opportunity> bookings = new List<Opportunity>();
        List<Lead> interests = new List<Lead>();
        for (Integer index = 0; index < 12; index++) {
            bookings.add(booking(accountId, 'Ashcombe ' + index, EVENT_CODE));
            interests.add(new Lead(LastName = 'Ellis ' + index, Company = 'Ashcombe Engineering',
                Email = 'ellis.' + index + '@example.invalid'));
        }
        insert bookings;
        insert interests;
        for (Lead interest : interests) {
            interest.NTE_Event_Code__c = EVENT_CODE;
            interest.Web_Form_Type__c = 'Exhibitor Expression of Interest';
        }
        update interests;
        Map<Id, Datetime> modifiedById = new Map<Id, Datetime>();
        for (Lead source : [SELECT Id, LastModifiedDate FROM Lead WHERE NTE_Event_Code__c = :EVENT_CODE]) modifiedById.put(source.Id, source.LastModifiedDate);
        for (Opportunity source : [SELECT Id, LastModifiedDate FROM Opportunity WHERE NTE_Event_Code__c = :EVENT_CODE]) modifiedById.put(source.Id, source.LastModifiedDate);
        Test.startTest();
        NTE_MasterPanelController.DashboardResponse first = dashboard('RECENT', 25, 0);
        NTE_MasterPanelController.DashboardResponse second = dashboard('RECENT', 25, 25);
        Test.stopTest();
        List<Id> actual = new List<Id>();
        for (NTE_MasterPanelController.DashboardRow row : first.rows) actual.add(row.recordId);
        for (NTE_MasterPanelController.DashboardRow row : second.rows) actual.add(row.recordId);
        System.assertEquals(26, first.totalRows);
        System.assertEquals(true, first.hasNextPage);
        System.assertEquals(false, second.hasNextPage);
        System.assertEquals(modifiedById.keySet(), new Set<Id>(actual));
        System.assertEquals(actual.size(), new Set<Id>(actual).size());
        for (Integer index = 1; index < actual.size(); index++) {
            Datetime earlier = modifiedById.get(actual[index - 1]);
            Datetime later = modifiedById.get(actual[index]);
            System.assert(earlier >= later, 'Recent rows remain newest first across object and page boundaries.');
            if (earlier == later) System.assert(String.valueOf(actual[index - 1]).compareTo(String.valueOf(actual[index])) > 0,
                'Equal timestamps use descending record IDs across page boundaries.');
        }
    }

    @IsTest
    static void timeFiltersUseSubmissionCreationAndLeaveFutureYearsIndependent() {
        Lead oldInterest = [SELECT Id FROM Lead WHERE LastName = 'Ellis'];
        Test.setCreatedDate(oldInterest.Id, System.now().addDays(-31));
        Test.startTest();
        NTE_MasterPanelController.DashboardResponse recent = NTE_MasterPanelController.getDashboard(
            EVENT_CODE, 'LAST_30', UserInfo.getUserId(), 'INTEREST', 25, 0);
        NTE_MasterPanelController.DashboardResponse fullRange = dashboard('INTEREST', 25, 0);
        Test.stopTest();
        System.assertEquals(0, recent.totalRows);
        System.assertEquals(1, fullRange.totalRows);
        System.assertEquals(oldInterest.Id, fullRange.rows[0].recordId);
    }

    @IsTest
    static void userModeRejectsRestrictedReadsAndActionsWithoutMutation() {
        User restrictedUser = new User(Alias = 'ntepan', Email = 'nia.foster@example.invalid',
            EmailEncodingKey = 'UTF-8', LastName = 'Foster', LanguageLocaleKey = 'en_US', LocaleSidKey = 'en_GB',
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'Minimum Access - Salesforce' LIMIT 1].Id,
            TimeZoneSidKey = 'Europe/London', Username = 'nia.foster.' + System.now().getTime() + '@example.invalid');
        insert restrictedUser;
        Opportunity target = [SELECT Id FROM Opportunity WHERE Name = 'Ashcombe Engineering'];
        Lead interest = [SELECT Id FROM Lead WHERE LastName = 'Ellis'];
        System.runAs(restrictedUser) {
            Boolean readBlocked = false;
            try { NTE_MasterPanelController.getHomeDashboard(EVENT_CODE); }
            catch (AuraHandledException expected) { readBlocked = true; }
            System.assert(readBlocked, 'User mode must enforce object and field access.');
            Boolean milestoneBlocked = false;
            try { NTE_MasterPanelController.updateMilestone(target.Id, 'INVOICE_PROVIDED'); }
            catch (AuraHandledException expected) { milestoneBlocked = true; }
            System.assert(milestoneBlocked);
            Boolean decisionBlocked = false;
            try { NTE_MasterPanelController.updateLeadDecision(interest.Id, 'INTEREST_NOT_PROGRESSED'); }
            catch (AuraHandledException expected) { decisionBlocked = true; }
            System.assert(decisionBlocked);
        }
        System.assertEquals(false, [SELECT NTE_Invoice_Provided__c FROM Opportunity WHERE Id = :target.Id].NTE_Invoice_Provided__c);
        System.assertEquals(false, [SELECT NTE_Interest_Not_Progressed__c FROM Lead WHERE Id = :interest.Id].NTE_Interest_Not_Progressed__c);
    }

    private static Opportunity booking(Id accountId, String name, String eventCode) {
        return new Opportunity(AccountId = accountId, Name = name, CloseDate = Date.today().addDays(30),
            RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('NTE_Event_Opportunity').getRecordTypeId(),
            StageName = 'Qualification', NTE_Source_Form_Type__c = 'Exhibitor Application', NTE_Event_Code__c = eventCode,
            Booking_Reference__c = 'NTE-PANEL-' + eventCode + '-' + name, Amount = 1000,
            NTE_Listed_Price_Total__c = 1000, NTE_Pricing_Status__c = 'Calculated',
            NTE_Invoice_Required__c = 'Yes', NTE_Quote_Required_for_PO__c = 'No',
            NTE_Heavy_Vehicle_Required__c = 'No', NTE_Staff_Update_Completed_At__c = System.now(),
            NTE_Logo_Update_Provided__c = true);
    }

    private static NTE_MasterPanelController.DashboardResponse dashboard(String view, Integer size, Integer offset) {
        return NTE_MasterPanelController.getDashboard(EVENT_CODE, 'ALL', null, view, size, offset);
    }
    private static Set<String> eventCodes(List<NTE_MasterPanelController.FilterOption> options) {
        Set<String> result = new Set<String>();
        for (NTE_MasterPanelController.FilterOption option : options) result.add(option.value);
        return result;
    }
    private static Map<String, Integer> queueCounts(NTE_MasterPanelController.DashboardResponse response) {
        Map<String, Integer> result = new Map<String, Integer>();
        for (NTE_MasterPanelController.WorkQueue queue : response.workQueues) result.put(queue.key, queue.count);
        return result;
    }
}
