@IsTest
private class NTE_MasterPanelControllerTest {
    @TestSetup
    static void createData() {
        for (String permissionName : new List<String>{'NTE_Forms_Administration', 'NTE_Management_User'}) {
            PermissionSet permissionRecord = [SELECT Id FROM PermissionSet WHERE Name = :permissionName LIMIT 1];
            if ([SELECT COUNT() FROM PermissionSetAssignment WHERE AssigneeId = :UserInfo.getUserId() AND PermissionSetId = :permissionRecord.Id] == 0) {
                insert new PermissionSetAssignment(AssigneeId = UserInfo.getUserId(), PermissionSetId = permissionRecord.Id);
            }
        }

        User currentUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        System.runAs(currentUser) {
            Account accountRecord = new Account(Name = 'NTE Master Panel Test Organisation');
            insert accountRecord;
            String openStage = [SELECT MasterLabel FROM OpportunityStage WHERE IsActive = true AND IsClosed = false ORDER BY SortOrder LIMIT 1].MasterLabel;
            Datetime nowValue = System.now();
            List<Opportunity> bookings = new List<Opportunity>{
                booking(accountRecord.Id, openStage, 'Complete booking', 'NTE-MP-COMPLETE', 1200, false, false, true, true, false, 'Yes', nowValue, nowValue),
                booking(accountRecord.Id, openStage, 'Invoice booking', 'NTE-MP-INVOICE', 800, false, false, false, false, false, 'No', null, null),
                booking(accountRecord.Id, openStage, 'Quote booking', 'NTE-MP-QUOTE', 15000, true, false, false, false, false, 'No', null, nowValue),
                booking(accountRecord.Id, openStage, 'Free booking', 'NTE-MP-FREE', 0, false, false, false, false, false, 'No', null, null)
            };
            insert bookings;

            List<Contact> primaryContacts = new List<Contact>();
            for (Integer indexValue = 0; indexValue < bookings.size(); indexValue++) {
                primaryContacts.add(new Contact(
                    AccountId = accountRecord.Id,
                    FirstName = 'Primary',
                    LastName = 'Contact ' + indexValue,
                    Email = 'primary-contact-' + indexValue + '@example.invalid'
                ));
            }
            insert primaryContacts;
            List<OpportunityContactRole> primaryRoles = new List<OpportunityContactRole>();
            for (Integer indexValue = 0; indexValue < bookings.size(); indexValue++) {
                primaryRoles.add(new OpportunityContactRole(
                    OpportunityId = bookings[indexValue].Id,
                    ContactId = primaryContacts[indexValue].Id,
                    IsPrimary = true,
                    Role = 'Decision Maker'
                ));
            }
            insert primaryRoles;

            insert new List<Lead>{
                lead('Interest Person', 'Partner / Sponsor Expression of Interest', 'NTE2027'),
                lead('Application Person', 'Exhibitor Application', 'NTE2027'),
                lead('Guest Person', 'Guest Registration', 'NTE2027'),
                lead('Future Person', 'Exhibitor Expression of Interest', 'NTE2028')
            };
        }
    }

    private static Opportunity booking(Id accountId, String stageName, String name, String reference, Decimal amount,
        Boolean quoteRequired, Boolean quoteProvided, Boolean invoiceProvided, Boolean paid, Boolean pricingReviewRequired,
        String heavyRequired, Datetime heavyCompletedAt, Datetime staffCompletedAt) {
        return new Opportunity(
            RecordTypeId = nteOpportunityRecordTypeId(),
            Name = name,
            AccountId = accountId,
            StageName = stageName,
            CloseDate = Date.today().addDays(30),
            Booking_Reference__c = reference,
            NTE_Event_Code__c = 'NTE2027',
            NTE_Source_Form_Type__c = name.contains('Quote') ? 'Partner / Sponsor Application' : 'Exhibitor Application',
            NTE_Event_Contact_Name__c = 'Test Contact',
            NTE_Event_Contact_Email__c = 'master-panel@example.invalid',
            NTE_Event_Contact_Mobile__c = '+44 7700 900000',
            NTE_Listed_Price_Total__c = amount,
            Amount = amount,
            NTE_Pricing_Status__c = pricingReviewRequired ? 'Review required' : 'Calculated',
            NTE_Invoice_Required__c = (amount > 0 || pricingReviewRequired) ? 'Yes' : 'No',
            NTE_Quote_Required_for_PO__c = quoteRequired ? 'Yes' : 'No',
            NTE_Quote_Provided__c = quoteProvided,
            NTE_Invoice_Provided__c = invoiceProvided,
            NTE_Payment_Received__c = paid,
            NTE_Heavy_Vehicle_Required__c = heavyRequired,
            NTE_Heavy_Vehicle_Update_Completed_At__c = heavyCompletedAt,
            NTE_Staff_Update_Completed_At__c = staffCompletedAt,
            NTE_Logo_Update_Provided__c = staffCompletedAt != null
        );
    }

    private static Lead lead(String lastName, String formType, String eventCode) {
        Lead recordValue = new Lead(
            LastName = lastName,
            Company = 'NTE Master Panel ' + lastName,
            Email = lastName.replace(' ', '.').toLowerCase() + '@example.invalid',
            Phone = '+44 7700 900001',
            Status = 'New',
            Web_Form_Type__c = formType,
            NTE_Event_Code__c = eventCode
        );
        if (formType == 'Guest Registration') {
            recordValue.Accompanying_Guest_Name__c = 'Additional Guest';
            recordValue.Accompanying_Guest_Email__c = 'additional.guest@example.invalid';
            recordValue.Guest_Accessibility_Required__c = 'No';
        } else if (formType == 'Partner / Sponsor Expression of Interest') {
            recordValue.Partner_Interest_Type__c = 'Sponsorship';
            recordValue.Partner_Interest_Areas__c = 'Event zone sponsorship';
            recordValue.Partnership_Interest_Detail__c = 'Interested in a visible event partnership.';
            recordValue.Preferred_Contact_Method__c = 'Email';
            recordValue.Preferred_Contact_Time__c = 'Mornings';
        } else if (formType == 'Exhibitor Expression of Interest') {
            recordValue.Exhibitor_Interest_Detail__c = 'Maybe';
            recordValue.Exhibitor_Community_Contribution__c = 'CV workshops and STEM activities.';
            recordValue.Preferred_Contact_Method__c = 'Telephone';
            recordValue.Preferred_Contact_Time__c = 'Afternoons';
        } else if (formType == 'Exhibitor Application') {
            recordValue.Exhibitor_Space_Selections__c = 'Single Garage - Paddock Side with power - £800 + VAT';
            recordValue.Exhibitor_Organisation_Category__c = 'Employer - Automotive Sector';
            recordValue.Planned_Exhibitor_Count__c = '2';
            recordValue.Stand_Power__c = 'No';
            recordValue.Listed_Price_Total__c = 800;
            recordValue.Pricing_Status__c = 'Calculated';
        }
        return recordValue;
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
    static void dashboardReconcilesFiltersCountsPipelineAndRows() {
        Test.startTest();
        NTE_MasterPanelController.DashboardResponse response = NTE_MasterPanelController.getDashboard(
            'NTE2027', 'ALL', null, 'QUOTE_REQUIRED', 25, 0
        );
        Test.stopTest();

        System.assertEquals('NTE2027', response.selectedEventCode);
        System.assertEquals('ALL', response.selectedTimeRange);
        System.assertEquals('QUOTE_REQUIRED', response.selectedViewKey);
        System.assertEquals(1, response.totalRows);
        System.assertEquals(1, response.rows.size());
        System.assertEquals('Quote booking', response.rows[0].name);
        System.assertEquals(true, response.rows[0].canMarkQuote);
        System.assertEquals('Quote required', response.rows[0].financeStatus);
        System.assert(response.eventOptions.size() >= 2);
        System.assertEquals('NTE2028', response.eventOptions[0].value);
        System.assert(response.ownerOptions.size() >= 1);

        Map<String, Integer> summaryValues = new Map<String, Integer>();
        for (NTE_MasterPanelController.SummaryMetric metric : response.summary) summaryValues.put(metric.key, metric.value);
        System.assertEquals(3, summaryValues.get('submitted'));
        System.assertEquals(4, summaryValues.get('confirmed'));
        System.assertEquals(3, summaryValues.get('progress'));
        System.assertEquals(1, summaryValues.get('complete'));

        Map<String, Integer> queueValues = new Map<String, Integer>();
        for (NTE_MasterPanelController.WorkQueue queue : response.workQueues) queueValues.put(queue.key, queue.count);
        System.assertEquals(1, queueValues.get('QUOTE_REQUIRED'));
        System.assertEquals(1, queueValues.get('INVOICE_REQUIRED'));
        System.assertEquals(0, queueValues.get('PAYMENT_DUE'));
        System.assertEquals(1, queueValues.get('PAYMENT_COMPLETE'));
        System.assertEquals(0, queueValues.get('HEAVY_DUE'));
        System.assertEquals(2, queueValues.get('STAFF_DUE'));
        System.assertEquals(2, queueValues.get('LOGO_DUE'));
        System.assertEquals(2, queueValues.get('READINESS_DUE'));
        System.assertEquals(1, queueValues.get('APPLICATION_REVIEW'));
        System.assertEquals(1, queueValues.get('APPLICATION_EXHIBITOR'));
        System.assertEquals(0, queueValues.get('APPLICATION_PARTNER'));
        System.assertEquals(1, queueValues.get('INTEREST'));
        System.assertEquals(0, queueValues.get('INTEREST_EXHIBITOR'));
        System.assertEquals(1, queueValues.get('INTEREST_PARTNER'));
        System.assertEquals(3, queueValues.get('APPROVED_EXHIBITOR'));
        System.assertEquals(1, queueValues.get('APPROVED_PARTNER'));
        System.assertEquals(1, queueValues.get('GUESTS'));

        System.assertEquals(6, response.pipeline.size());
        System.assertEquals('Finances', response.pipeline[3].label);
        System.assertEquals('Updates', response.pipeline[4].label);
        System.assertEquals('Completed', response.pipeline[5].label);
        System.assertEquals('25% of approved bookings complete', response.pipeline[5].detail);

        Map<String, NTE_MasterPanelController.EventOverviewRow> overviewByKey = new Map<String, NTE_MasterPanelController.EventOverviewRow>();
        for (NTE_MasterPanelController.EventOverviewRow item : response.overview) overviewByKey.put(item.key, item);
        System.assertEquals(1, overviewByKey.get('guests').total);
        System.assertEquals(1, overviewByKey.get('guests').completed);
        System.assertEquals(5, overviewByKey.get('applications').total);
        System.assertEquals(1, overviewByKey.get('applications').inProgress);
        System.assertEquals(4, overviewByKey.get('applications').completed);
        System.assertEquals(4, overviewByKey.get('approved').total);
        System.assertEquals(3, overviewByKey.get('approved').inProgress);
        System.assertEquals(1, overviewByKey.get('approved').completed);
        System.assertEquals(1, overviewByKey.get('quotes').total);
        System.assertEquals(1, overviewByKey.get('quotes').inProgress);
        System.assertEquals(0, overviewByKey.get('quotes').completed);
        System.assertEquals(2, overviewByKey.get('invoices').total);
        System.assertEquals(1, overviewByKey.get('invoices').inProgress);
        System.assertEquals(1, overviewByKey.get('invoices').completed);
        System.assertEquals(1, overviewByKey.get('payments').total);
        System.assertEquals(0, overviewByKey.get('payments').inProgress);
        System.assertEquals(1, overviewByKey.get('payments').completed);
        System.assertEquals(4, overviewByKey.get('logos').total);
        System.assertEquals(2, overviewByKey.get('logos').inProgress);
        System.assertEquals(2, overviewByKey.get('logos').completed);
        System.assertEquals('LOGO_DUE', overviewByKey.get('logos').viewKey);
        System.assertEquals('Quotes required', response.selectedView.label);
    }

    @IsTest
    static void nonNteRecordTypesCannotContaminateMetricsRowsActionsOrEventFilters() {
        Id nonNteRecordTypeId = nonNteOpportunityRecordTypeId();
        if (nonNteRecordTypeId == null) {
            System.assertEquals(null, nonNteRecordTypeId,
                'This org has no second deployable Opportunity record type; the static regression test still verifies the shared query boundary.');
            return;
        }
        Account accountRecord = [SELECT Id FROM Account WHERE Name = 'NTE Master Panel Test Organisation' LIMIT 1];
        String openStage = [
            SELECT MasterLabel
            FROM OpportunityStage
            WHERE IsActive = true AND IsClosed = false
            ORDER BY SortOrder
            LIMIT 1
        ].MasterLabel;

        Opportunity sameEventContaminant = booking(
            accountRecord.Id, openStage, 'Regular CRM opportunity with NTE-shaped data',
            'REGULAR-CRM-NTE2027', 99999, true, false, false, false, false, 'Yes', null, null
        );
        sameEventContaminant.RecordTypeId = nonNteRecordTypeId;
        Opportunity futureEventContaminant = booking(
            accountRecord.Id, openStage, 'Regular CRM opportunity with future code',
            'REGULAR-CRM-NTE2099', 88888, false, false, false, false, false, 'No', null, null
        );
        futureEventContaminant.RecordTypeId = nonNteRecordTypeId;
        futureEventContaminant.NTE_Event_Code__c = 'NTE2099';
        insert new List<Opportunity>{sameEventContaminant, futureEventContaminant};

        Test.startTest();
        NTE_MasterPanelController.DashboardResponse dashboard =
            NTE_MasterPanelController.getDashboard('NTE2027', 'ALL', null, 'APPROVED', 25, 0);
        NTE_MasterPanelController.HomeDashboardResponse home =
            NTE_MasterPanelController.getHomeDashboard('NTE2027');
        Test.stopTest();

        System.assertEquals(4, dashboard.totalRows,
            'A regular CRM opportunity must not enter the NTE approved queue.');
        for (NTE_MasterPanelController.DashboardRow row : dashboard.rows) {
            System.assertNotEquals(sameEventContaminant.Id, row.recordId);
        }
        for (NTE_MasterPanelController.FilterOption option : dashboard.eventOptions) {
            System.assertNotEquals('NTE2099', option.value,
                'Event filters must only be sourced from NTE event opportunities and NTE leads.');
        }
        System.assertEquals(4, home.headlines[1].count,
            'The confirmed-applications headline must exclude regular CRM opportunities.');

        try {
            NTE_MasterPanelController.updateMilestone(sameEventContaminant.Id, 'QUOTE_PROVIDED');
            System.assert(false, 'Master Panel actions must reject regular CRM opportunities.');
        } catch (AuraHandledException expected) {
            System.assert(true);
        }
    }

    @IsTest
    static void homeDashboardReconcilesCountsValuesAndFinanceRequirements() {
        Lead unknownPriceApplication = lead('Unknown Price Application', 'Partner / Sponsor Application', 'NTE2027');
        unknownPriceApplication.Planned_Exhibitor_Count__c = '1';
        insert unknownPriceApplication;

        Account accountRecord = [SELECT Id FROM Account WHERE Name = 'NTE Master Panel Test Organisation' LIMIT 1];
        String openStage = [SELECT MasterLabel FROM OpportunityStage WHERE IsActive = true AND IsClosed = false ORDER BY SortOrder LIMIT 1].MasterLabel;
        Opportunity unknownPriceBooking = booking(accountRecord.Id, openStage, 'Unknown price booking',
            'NTE-MP-UNKNOWN-PRICE', 0, false, false, false, false, true, 'No', null, null);
        unknownPriceBooking.NTE_Source_Form_Type__c = 'Partner / Sponsor Application';
        unknownPriceBooking.NTE_Planned_Exhibitor_Count__c = '1';
        insert unknownPriceBooking;

        Test.startTest();
        NTE_MasterPanelController.HomeDashboardResponse response =
            NTE_MasterPanelController.getHomeDashboard('NTE2027');
        Test.stopTest();

        System.assertEquals('NTE2027', response.selectedEventCode);
        System.assertEquals(5, response.headlines.size());
        System.assertEquals('APPLICATIONS', response.headlines[0].key);
        System.assertEquals('CONFIRMED_APPLICATIONS', response.headlines[1].key);
        System.assertEquals('INVOICED', response.headlines[2].key);
        System.assertEquals('STILL_TO_COLLECT', response.headlines[3].key);
        System.assertEquals('PAID', response.headlines[4].key);
        System.assertEquals(6, response.pipeline.size());
        System.assertEquals(4, response.revenueReadiness.size());
        System.assertEquals(2, response.pricingReviewCount,
            'Applications and bookings with unknown pricing are counted and excluded from known value totals.');
        System.assertNotEquals(null, response.refreshedAt);

        Map<String, NTE_MasterPanelController.HomeMetric> headlineByKey =
            new Map<String, NTE_MasterPanelController.HomeMetric>();
        for (NTE_MasterPanelController.HomeMetric metric : response.headlines) {
            headlineByKey.put(metric.key, metric);
        }
        assertMetric(headlineByKey.get('APPLICATIONS'), 2, 800);
        assertMetric(headlineByKey.get('CONFIRMED_APPLICATIONS'), 5, 17000);
        assertMetric(headlineByKey.get('INVOICED'), 1, 1200);
        assertMetric(headlineByKey.get('PAID'), 1, 1200);
        assertMetric(headlineByKey.get('STILL_TO_COLLECT'), 3, 15800);
        System.assertEquals('Approved Applications', headlineByKey.get('CONFIRMED_APPLICATIONS').label);

        Map<String, NTE_MasterPanelController.HomeMetric> readinessByKey =
            new Map<String, NTE_MasterPanelController.HomeMetric>();
        Integer readinessCount = 0;
        for (NTE_MasterPanelController.HomeMetric metric : response.revenueReadiness) {
            readinessByKey.put(metric.key, metric);
            readinessCount += metric.count;
        }
        assertMetric(readinessByKey.get('QUOTE_REQUIRED'), 1, 15000);
        assertMetric(readinessByKey.get('INVOICE_REQUIRED'), 2, 800);
        assertMetric(readinessByKey.get('PAYMENT_REQUIRED'), 0, 0);
        assertMetric(readinessByKey.get('PAID'), 1, 1200);
        System.assertEquals(4, readinessCount, 'This fixture has four finance requirements; top-ups may create overlapping requirements.');

        Map<String, NTE_MasterPanelController.HomePipelineRow> pipelineByKey =
            new Map<String, NTE_MasterPanelController.HomePipelineRow>();
        for (NTE_MasterPanelController.HomePipelineRow row : response.pipeline) {
            pipelineByKey.put(row.key, row);
            System.assertEquals(row.count, row.exhibitorCount + row.partnerCount);
            System.assertEquals(row.totalValue, row.exhibitorValue + row.partnerValue);
        }
        assertPipeline(pipelineByKey.get('INTEREST'), 1, 0, 1, 0, 0);
        assertPipeline(pipelineByKey.get('APPLICATIONS'), 2, 1, 1, 800, 0);
        assertPipeline(pipelineByKey.get('APPROVED'), 5, 3, 2, 2000, 15000);
        assertPipeline(pipelineByKey.get('FINANCES'), 4, 2, 2, 2000, 15000);
        assertPipeline(pipelineByKey.get('UPDATES'), 3, 2, 1, 800, 0);
        assertPipeline(pipelineByKey.get('COMPLETED'), 1, 1, 0, 1200, 0);

        System.assertEquals(4, response.bookingMix.exhibitor.count);
        System.assertEquals(2800, response.bookingMix.exhibitor.value);
        System.assertEquals(700, response.bookingMix.exhibitor.averageValue);
        System.assertEquals(3, response.bookingMix.partner.count);
        System.assertEquals(15000, response.bookingMix.partner.value);
        System.assertEquals(5000, response.bookingMix.partner.averageValue);
    }

    @IsTest
    static void homeDashboardUsesDynamicEventSelectionAndEmptyFinancialTotals() {
        Test.startTest();
        NTE_MasterPanelController.HomeDashboardResponse response =
            NTE_MasterPanelController.getHomeDashboard('NTE2028');
        Test.stopTest();

        System.assertEquals('NTE2028', response.selectedEventCode);
        System.assertEquals('NTE2028', response.eventOptions[0].value);
        for (NTE_MasterPanelController.HomeMetric metric : response.headlines) {
            System.assertEquals(0, metric.count);
            System.assertEquals(0, metric.value);
        }
        System.assertEquals(1, response.pipeline[0].count);
        System.assertEquals(1, response.pipeline[0].exhibitorCount);
        System.assertEquals(0, response.pipeline[0].totalValue);
        System.assertEquals(0, response.bookingMix.exhibitor.count);
        System.assertEquals(0, response.bookingMix.partner.count);
    }

    private static void assertMetric(NTE_MasterPanelController.HomeMetric metric, Integer count, Decimal value) {
        System.assertNotEquals(null, metric);
        System.assertEquals(count, metric.count);
        System.assertEquals(value, metric.value);
    }

    private static void assertPipeline(NTE_MasterPanelController.HomePipelineRow row, Integer count,
        Integer exhibitorCount, Integer partnerCount, Decimal exhibitorValue, Decimal partnerValue) {
        System.assertNotEquals(null, row);
        System.assertEquals(count, row.count);
        System.assertEquals(exhibitorCount, row.exhibitorCount);
        System.assertEquals(partnerCount, row.partnerCount);
        System.assertEquals(exhibitorValue, row.exhibitorValue);
        System.assertEquals(partnerValue, row.partnerValue);
    }

    @IsTest
    static void ownerTimeAndLeadViewsAreApplied() {
        Lead applicationLead = [SELECT OwnerId FROM Lead WHERE LastName = 'Application Person' LIMIT 1];
        Test.startTest();
        NTE_MasterPanelController.DashboardResponse response = NTE_MasterPanelController.getDashboard(
            'NTE2027', 'TODAY', applicationLead.OwnerId, 'APPLICATION_REVIEW', 10, 0
        );
        Test.stopTest();
        System.assertEquals('TODAY', response.selectedTimeRange);
        System.assertEquals(String.valueOf(applicationLead.OwnerId), response.selectedOwnerId);
        System.assertEquals(1, response.rows.size());
        System.assertEquals('Lead', response.rows[0].objectApiName);
        System.assertEquals('Application review', response.rows[0].stage);
        System.assertEquals(false, response.rows[0].canMarkInvoice);
        System.assertEquals('Exhibitor', response.rows[0].typeLabel);
        System.assertEquals(800, response.rows[0].amount);
    }

    @IsTest
    static void applicationPaginationIsStableWhenRecordsShareATimestamp() {
        List<Lead> bulkApplications = new List<Lead>();
        for (Integer indexValue = 0; indexValue < 30; indexValue++) {
            bulkApplications.add(lead(
                'Stable Page ' + (indexValue < 10 ? '0' : '') + indexValue,
                Math.mod(indexValue, 2) == 0 ? 'Partner / Sponsor Application' : 'Exhibitor Application',
                'NTE2027'
            ));
        }
        insert bulkApplications;

        List<Lead> expectedRecords = [
            SELECT Id
            FROM Lead
            WHERE NTE_Event_Code__c = 'NTE2027'
              AND IsConverted = false
              AND Web_Form_Type__c IN ('Exhibitor Application', 'Partner / Sponsor Application')
            ORDER BY LastModifiedDate DESC, Id DESC
        ];
        System.assertEquals(31, expectedRecords.size());

        Test.startTest();
        NTE_MasterPanelController.DashboardResponse firstPage = NTE_MasterPanelController.getDashboard(
            'NTE2027', 'ALL', null, 'APPLICATION_REVIEW', 25, 0
        );
        NTE_MasterPanelController.DashboardResponse secondPage = NTE_MasterPanelController.getDashboard(
            'NTE2027', 'ALL', null, 'APPLICATION_REVIEW', 25, 25
        );
        Test.stopTest();

        List<String> actualIds = new List<String>();
        for (NTE_MasterPanelController.DashboardRow row : firstPage.rows) actualIds.add(row.recordId);
        for (NTE_MasterPanelController.DashboardRow row : secondPage.rows) actualIds.add(row.recordId);

        List<String> expectedIds = new List<String>();
        for (Lead expectedRecord : expectedRecords) expectedIds.add(String.valueOf(expectedRecord.Id));
        System.assertEquals(expectedIds, actualIds,
            'Equal-timestamp applications must retain one deterministic order across every page.');
        System.assertEquals(new Set<String>(expectedIds), new Set<String>(actualIds),
            'No application may be skipped or duplicated between pages.');
    }

    @IsTest
    static void guestQueueDetailsAreReturned() {
        NTE_MasterPanelController.DashboardResponse guestResponse = NTE_MasterPanelController.getDashboard(
            'NTE2027', 'ALL', null, 'GUESTS', 25, 0
        );
        System.assertEquals('Additional Guest', guestResponse.rows[0].accompanyingGuestName);
        System.assertEquals('additional.guest@example.invalid', guestResponse.rows[0].accompanyingGuestEmail);
        System.assertEquals('No', guestResponse.rows[0].guestAccessibility);
    }

    @IsTest
    static void partnerInterestQueueDetailsAreReturned() {
        NTE_MasterPanelController.DashboardResponse interestResponse = NTE_MasterPanelController.getDashboard(
            'NTE2027', 'ALL', null, 'INTEREST', 25, 0
        );
        System.assertEquals('Sponsorship', interestResponse.rows[0].interestType);
        System.assertEquals('Event zone sponsorship', interestResponse.rows[0].interestAreas);
        System.assertEquals('Email · Mornings', interestResponse.rows[0].preferredContact);
    }

    @IsTest
    static void exhibitorInterestQueueDetailsAreReturned() {
        NTE_MasterPanelController.DashboardResponse exhibitorInterestResponse = NTE_MasterPanelController.getDashboard(
            'NTE2028', 'ALL', null, 'INTEREST_EXHIBITOR', 25, 0
        );
        System.assertEquals('Exhibitor', exhibitorInterestResponse.rows[0].interestType);
        System.assertEquals('Maybe', exhibitorInterestResponse.rows[0].interestAreas);
        System.assertEquals('CV workshops and STEM activities.', exhibitorInterestResponse.rows[0].interestDetail);
        System.assertEquals('Telephone · Afternoons', exhibitorInterestResponse.rows[0].preferredContact);

    }

    @IsTest
    static void financeAggregateIsReturned() {
        NTE_MasterPanelController.DashboardResponse financeResponse = NTE_MasterPanelController.getDashboard(
            'NTE2027', 'ALL', null, 'FINANCE_DUE', 25, 0
        );
        System.assertEquals(3, financeResponse.totalRows);
        System.assertEquals('Finance records', financeResponse.selectedView.label);
    }

    @IsTest
    static void leadStageSubtypeViewsReturnCombinedAndNarrowedRows() {
        NTE_MasterPanelController.DashboardResponse interestCombined = NTE_MasterPanelController.getDashboard(
            'NTE2027', 'ALL', null, 'INTEREST', 25, 0
        );
        NTE_MasterPanelController.DashboardResponse interestPartner = NTE_MasterPanelController.getDashboard(
            'NTE2027', 'ALL', null, 'INTEREST_PARTNER', 25, 0
        );
        System.assertEquals(1, interestCombined.totalRows);
        System.assertEquals(1, interestPartner.totalRows);
        System.assertEquals('Partner / Sponsor Expression of Interest', interestPartner.rows[0].sourceFormType);
    }

    @IsTest
    static void applicationSubtypeViewReturnsNarrowedRows() {
        NTE_MasterPanelController.DashboardResponse applicationExhibitor = NTE_MasterPanelController.getDashboard(
            'NTE2027', 'ALL', null, 'APPLICATION_EXHIBITOR', 25, 0
        );
        System.assertEquals(1, applicationExhibitor.totalRows);
        System.assertEquals('Exhibitor', applicationExhibitor.rows[0].typeLabel);
    }

    @IsTest
    static void convertedApplicationMovesIntoApprovedMetrics() {
        Lead applicationLead = [
            SELECT Id, Company
            FROM Lead
            WHERE LastName = 'Application Person'
            LIMIT 1
        ];
        LeadStatus convertedStatus = [
            SELECT MasterLabel
            FROM LeadStatus
            WHERE IsConverted = true
            LIMIT 1
        ];
        Database.LeadConvert conversion = new Database.LeadConvert();
        conversion.setLeadId(applicationLead.Id);
        conversion.setConvertedStatus(convertedStatus.MasterLabel);
        conversion.setOpportunityName(applicationLead.Company + ' NTE booking');

        Test.startTest();
        Database.LeadConvertResult conversionResult = Database.convertLead(conversion);
        NTE_MasterPanelController.DashboardResponse response = NTE_MasterPanelController.getDashboard(
            'NTE2027', 'ALL', null, 'APPROVED', 25, 0
        );
        Test.stopTest();

        System.assertEquals(true, conversionResult.isSuccess());
        Map<String, Integer> queueValues = new Map<String, Integer>();
        for (NTE_MasterPanelController.WorkQueue queue : response.workQueues) queueValues.put(queue.key, queue.count);
        System.assertEquals(0, queueValues.get('APPLICATION_REVIEW'));
        System.assertEquals(5, queueValues.get('APPROVED'));
        System.assertEquals(4, queueValues.get('APPROVED_EXHIBITOR'));
        System.assertEquals(5, response.totalRows);
        System.assertEquals('Opportunity', response.rows[0].objectApiName);
    }

    @IsTest
    static void recentConvertedApplicationsShowTheirRecordedOutcome() {
        Lead source = [SELECT Id, Company FROM Lead WHERE LastName = 'Application Person' LIMIT 1];
        Database.LeadConvert conversion = new Database.LeadConvert();
        conversion.setLeadId(source.Id);
        conversion.setConvertedStatus([SELECT MasterLabel FROM LeadStatus WHERE IsConverted = true LIMIT 1].MasterLabel);
        conversion.setOpportunityName(source.Company + ' NTE booking');
        Database.LeadConvertResult result = Database.convertLead(conversion);
        System.assert(result.isSuccess());
        Test.startTest();
        NTE_MasterPanelController.DashboardResponse response = NTE_MasterPanelController.getDashboard(
            'NTE2027', 'ALL', null, 'RECENT', 25, 0);
        Test.stopTest();
        NTE_MasterPanelController.DashboardRow convertedRow;
        for (NTE_MasterPanelController.DashboardRow row : response.rows) {
            if (row.recordId == source.Id) convertedRow = row;
        }
        System.assertNotEquals(null, convertedRow, 'The original submission remains in recent-record history.');
        System.assertEquals('Converted', convertedRow.stage);
        for (NTE_MasterPanelController.WorkQueue queue : response.workQueues) {
            if (queue.key == 'APPLICATION_REVIEW') System.assertEquals(0, queue.count);
            if (queue.key == 'APPROVED') System.assertEquals(5, queue.count);
        }
    }

    @IsTest
    static void approvedStageSubtypeViewsReturnNarrowedRows() {
        NTE_MasterPanelController.DashboardResponse approvedExhibitor = NTE_MasterPanelController.getDashboard(
            'NTE2027', 'ALL', null, 'APPROVED_EXHIBITOR', 25, 0
        );
        NTE_MasterPanelController.DashboardResponse approvedPartner = NTE_MasterPanelController.getDashboard(
            'NTE2027', 'ALL', null, 'APPROVED_PARTNER', 25, 0
        );

        System.assertEquals(3, approvedExhibitor.totalRows);
        System.assertEquals(1, approvedPartner.totalRows);
    }

    @IsTest
    static void financeAndUpdateSubtypeViewsReturnNarrowedRows() {
        NTE_MasterPanelController.DashboardResponse paymentsComplete = NTE_MasterPanelController.getDashboard(
            'NTE2027', 'ALL', null, 'PAYMENT_COMPLETE', 25, 0
        );
        NTE_MasterPanelController.DashboardResponse updatesRequired = NTE_MasterPanelController.getDashboard(
            'NTE2027', 'ALL', null, 'READINESS_DUE', 25, 0
        );

        System.assertEquals(1, paymentsComplete.totalRows);
        System.assertEquals('Payment confirmed', paymentsComplete.rows[0].financeStatus);
        System.assertEquals(2, updatesRequired.totalRows);
    }

    @IsTest
    static void logoUpdateViewCountsFiltersAndRefreshesAfterStatusChange() {
        Opportunity suppliedLogo = [
            SELECT Id, NTE_Logo_Update_Provided__c, NTE_Logo_Update_Provided_At__c
            FROM Opportunity
            WHERE Name = 'Complete booking'
            LIMIT 1
        ];
        suppliedLogo.NTE_Logo_Update_Provided__c = true;
        suppliedLogo.NTE_Logo_Update_Provided_At__c = System.now();
        update suppliedLogo;

        NTE_MasterPanelController.DashboardResponse beforeSecondUpdate =
            NTE_MasterPanelController.getDashboard('NTE2027', 'ALL', null, 'LOGO_DUE', 25, 0);
        System.assertEquals(2, beforeSecondUpdate.totalRows);
        System.assertEquals('Logo updates', beforeSecondUpdate.selectedView.label);
        System.assertEquals('/lightning/o/Opportunity/list?filterName=NTE_Logo_Updates_Due',
            beforeSecondUpdate.selectedView.listUrl);
        for (NTE_MasterPanelController.DashboardRow row : beforeSecondUpdate.rows) {
            System.assertEquals('Opportunity', row.objectApiName);
            System.assertEquals(false, row.logoUpdateProvided);
            System.assertEquals('Update required', row.logoStatus);
        }

        Opportunity nextLogo = [
            SELECT Id, NTE_Logo_Update_Provided__c, NTE_Logo_Update_Provided_At__c
            FROM Opportunity
            WHERE Name = 'Invoice booking'
            LIMIT 1
        ];
        nextLogo.NTE_Logo_Update_Provided__c = true;
        nextLogo.NTE_Logo_Update_Provided_At__c = System.now();
        update nextLogo;

        Test.startTest();
        NTE_MasterPanelController.DashboardResponse afterSecondUpdate =
            NTE_MasterPanelController.getDashboard('NTE2027', 'ALL', null, 'LOGO_DUE', 25, 0);
        NTE_MasterPanelController.DashboardResponse otherEvent =
            NTE_MasterPanelController.getDashboard('NTE2028', 'ALL', null, 'LOGO_DUE', 25, 0);
        Test.stopTest();

        System.assertEquals(1, afterSecondUpdate.totalRows,
            'A supplied logo must leave the outstanding-logo refiner after refresh.');
        System.assertEquals(0, otherEvent.totalRows,
            'The logo refiner must remain isolated to the selected event code.');
    }

    @IsTest
    static void paymentRequiredViewSupportsMarkingPaid() {
        Account accountRecord = [SELECT Id FROM Account WHERE Name = 'NTE Master Panel Test Organisation' LIMIT 1];
        String openStage = [SELECT MasterLabel FROM OpportunityStage WHERE IsActive = true AND IsClosed = false ORDER BY SortOrder LIMIT 1].MasterLabel;
        insert booking(accountRecord.Id, openStage, 'Payment due booking', 'NTE-MP-PAYMENT-DUE', 500,
            false, false, true, false, false, 'No', null, System.now());

        NTE_MasterPanelController.DashboardResponse paymentRequired = NTE_MasterPanelController.getDashboard(
            'NTE2027', 'ALL', null, 'PAYMENT_DUE', 25, 0
        );
        System.assertEquals(1, paymentRequired.totalRows);
        System.assertEquals('Payment required', paymentRequired.selectedView.label);
        System.assertEquals(true, paymentRequired.rows[0].canMarkPaid);
        System.assertEquals('Booking payment required', paymentRequired.rows[0].financeStatus);
    }

    @IsTest
    static void topUpInvoiceAndPaymentAreTrackedAfterTheBooking() {
        Account accountRecord = [SELECT Id FROM Account WHERE Name = 'NTE Master Panel Test Organisation' LIMIT 1];
        String openStage = [SELECT MasterLabel FROM OpportunityStage WHERE IsActive = true AND IsClosed = false ORDER BY SortOrder LIMIT 1].MasterLabel;
        Opportunity topUpBooking = booking(accountRecord.Id, openStage, 'Top-up finance booking',
            'NTE-MP-TOPUP-FINANCE', 1000, false, false, true, true, false, 'No', null, System.now());
        topUpBooking.NTE_Initial_Staff_Count__c = 2;
        topUpBooking.NTE_Total_Staff_Count__c = 4;
        topUpBooking.NTE_Top_Up_Staff_Required__c = 'Yes';
        topUpBooking.NTE_Top_Up_Staff_Count__c = 2;
        topUpBooking.NTE_Top_Up_Staff_Total__c = 100;
        topUpBooking.NTE_Top_Up_Invoice_Required__c = true;
        insert topUpBooking;

        NTE_MasterPanelController.DashboardResponse invoiceQueue = NTE_MasterPanelController.getDashboard(
            'NTE2027', 'ALL', null, 'TOP_UP_INVOICE_REQUIRED', 25, 0
        );
        NTE_MasterPanelController.DashboardRow invoiceRow;
        for (NTE_MasterPanelController.DashboardRow row : invoiceQueue.rows) {
            if (row.recordId == topUpBooking.Id) invoiceRow = row;
        }
        System.assertNotEquals(null, invoiceRow);
        System.assertEquals(1100, invoiceRow.amount);
        System.assertEquals(100, invoiceRow.topUpAmount);
        System.assertEquals('Staff top-up invoice required', invoiceRow.financeStatus);
        System.assertEquals(false, invoiceRow.canMarkInvoice);
        System.assertEquals(true, invoiceRow.canMarkTopUpInvoice);

        NTE_MasterPanelController.ActionResult invoiceResult =
            NTE_MasterPanelController.updateMilestone(topUpBooking.Id, 'TOP_UP_INVOICE_PROVIDED');
        System.assertEquals('Staff top-up invoice marked as provided.', invoiceResult.message);

        NTE_MasterPanelController.DashboardResponse paymentQueue = NTE_MasterPanelController.getDashboard(
            'NTE2027', 'ALL', null, 'TOP_UP_PAYMENT_DUE', 25, 0
        );
        NTE_MasterPanelController.DashboardRow paymentRow;
        for (NTE_MasterPanelController.DashboardRow row : paymentQueue.rows) {
            if (row.recordId == topUpBooking.Id) paymentRow = row;
        }
        System.assertNotEquals(null, paymentRow);
        System.assertEquals('Staff top-up payment required', paymentRow.financeStatus);
        System.assertEquals(false, paymentRow.canMarkPaid);
        System.assertEquals(true, paymentRow.canMarkTopUpPaid);

        NTE_MasterPanelController.ActionResult paymentResult =
            NTE_MasterPanelController.updateMilestone(topUpBooking.Id, 'TOP_UP_PAYMENT_RECEIVED');
        System.assertEquals('Staff top-up payment marked as received.', paymentResult.message);
        Opportunity updated = [
            SELECT NTE_Invoice_Provided__c, NTE_Payment_Received__c,
                   NTE_Top_Up_Invoice_Provided__c, NTE_Top_Up_Payment_Received__c
            FROM Opportunity WHERE Id = :topUpBooking.Id
        ];
        System.assertEquals(true, updated.NTE_Invoice_Provided__c);
        System.assertEquals(true, updated.NTE_Payment_Received__c);
        System.assertEquals(true, updated.NTE_Top_Up_Invoice_Provided__c);
        System.assertEquals(true, updated.NTE_Top_Up_Payment_Received__c);
    }

    @IsTest
    static void unconfirmedLogisticsCannotBeCompleted() {
        Account accountRecord = [SELECT Id FROM Account WHERE Name = 'NTE Master Panel Test Organisation' LIMIT 1];
        String openStage = [SELECT MasterLabel FROM OpportunityStage WHERE IsActive = true AND IsClosed = false ORDER BY SortOrder LIMIT 1].MasterLabel;
        insert booking(accountRecord.Id, openStage, 'Unconfirmed logistics booking', 'NTE-MP-LOGISTICS-UNKNOWN', 100,
            false, false, true, true, false, 'Not known yet', System.now(), System.now());

        NTE_MasterPanelController.DashboardResponse completed = NTE_MasterPanelController.getDashboard(
            'NTE2027', 'ALL', null, 'COMPLETED', 25, 0
        );
        NTE_MasterPanelController.DashboardResponse logisticsOutstanding = NTE_MasterPanelController.getDashboard(
            'NTE2027', 'ALL', null, 'HEAVY_DUE', 25, 0
        );

        System.assertEquals(1, completed.totalRows, 'Unset logistics must never be counted as complete.');
        System.assertEquals(1, logisticsOutstanding.totalRows);
        System.assertEquals('Unconfirmed logistics booking', logisticsOutstanding.rows[0].name);
        System.assertEquals('Not confirmed', logisticsOutstanding.rows[0].logisticsStatus);
        System.assertEquals(false, logisticsOutstanding.rows[0].complete);
    }

    @IsTest
    static void completionRequiresEveryApplicableMilestone() {
        Opportunity quoteBooking = [
            SELECT Id, NTE_Quote_Provided__c, NTE_Invoice_Provided__c, NTE_Payment_Received__c
            FROM Opportunity WHERE Name = 'Quote booking' LIMIT 1
        ];
        quoteBooking.NTE_Invoice_Provided__c = true;
        quoteBooking.NTE_Payment_Received__c = true;
        update quoteBooking;

        NTE_MasterPanelController.DashboardResponse beforeQuote = NTE_MasterPanelController.getDashboard(
            'NTE2027', 'ALL', null, 'COMPLETED', 25, 0
        );
        System.assertEquals(1, beforeQuote.totalRows, 'A required quote must be provided before the booking is complete.');

        quoteBooking.NTE_Quote_Provided__c = true;
        update quoteBooking;
        NTE_MasterPanelController.DashboardResponse afterQuote = NTE_MasterPanelController.getDashboard(
            'NTE2027', 'ALL', null, 'COMPLETED', 25, 0
        );
        System.assertEquals(2, afterQuote.totalRows);
    }

    @IsTest
    static void milestonesEnforceOrderAndRecordAudit() {
        Opportunity quoteBooking = [SELECT Id FROM Opportunity WHERE Name = 'Quote booking' LIMIT 1];
        Boolean orderBlocked = false;
        try {
            NTE_MasterPanelController.updateMilestone(quoteBooking.Id, 'INVOICE_PROVIDED');
        } catch (AuraHandledException expected) {
            orderBlocked = true;
        }
        System.assertEquals(true, orderBlocked);

        Test.startTest();
        NTE_MasterPanelController.ActionResult quoteResult = NTE_MasterPanelController.updateMilestone(quoteBooking.Id, 'QUOTE_PROVIDED');
        NTE_MasterPanelController.ActionResult invoiceResult = NTE_MasterPanelController.updateMilestone(quoteBooking.Id, 'INVOICE_PROVIDED');
        NTE_MasterPanelController.ActionResult paymentResult = NTE_MasterPanelController.updateMilestone(quoteBooking.Id, 'PAYMENT_RECEIVED');
        Test.stopTest();

        System.assertEquals(true, quoteResult.success);
        System.assertEquals(true, invoiceResult.success);
        System.assertEquals(true, paymentResult.success);
        Opportunity updated = [
            SELECT NTE_Quote_Provided__c, NTE_Quote_Provided_At__c, NTE_Quote_Provided_By__c,
                   NTE_Invoice_Provided__c, NTE_Invoice_Provided_At__c, NTE_Invoice_Provided_By__c,
                   NTE_Payment_Received__c, NTE_Payment_Received_At__c, NTE_Payment_Recorded_By__c
            FROM Opportunity WHERE Id = :quoteBooking.Id
        ];
        System.assertEquals(true, updated.NTE_Quote_Provided__c);
        System.assertEquals(true, updated.NTE_Invoice_Provided__c);
        System.assertEquals(true, updated.NTE_Payment_Received__c);
        System.assertNotEquals(null, updated.NTE_Quote_Provided_At__c);
        System.assertNotEquals(null, updated.NTE_Invoice_Provided_At__c);
        System.assertNotEquals(null, updated.NTE_Payment_Received_At__c);
        System.assertEquals(UserInfo.getName(), updated.NTE_Quote_Provided_By__c);
        System.assertEquals(UserInfo.getName(), updated.NTE_Invoice_Provided_By__c);
        System.assertEquals(UserInfo.getName(), updated.NTE_Payment_Recorded_By__c);
    }

    @IsTest
    static void invalidActionsAreRejectedWithoutMutation() {
        Opportunity freeBooking = [SELECT Id FROM Opportunity WHERE Name = 'Free booking' LIMIT 1];
        for (String actionName : new List<String>{'PAYMENT_RECEIVED', 'NOT_REAL'}) {
            Boolean blocked = false;
            try {
                NTE_MasterPanelController.updateMilestone(freeBooking.Id, actionName);
            } catch (AuraHandledException expected) {
                blocked = true;
            }
            System.assertEquals(true, blocked);
        }
    }


    @IsTest
    static void rejectionLeavesActiveQueuesAndManualProgressIsRetired() {
        Lead interestLead = [
            SELECT Id, NTE_Interest_Progressed__c, NTE_Interest_Not_Progressed__c
            FROM Lead WHERE LastName = 'Interest Person' LIMIT 1
        ];
        Lead applicationLead = [
            SELECT Id, NTE_Application_Rejected__c
            FROM Lead WHERE LastName = 'Application Person' LIMIT 1
        ];

        Boolean manualProgressBlocked = false;
        try {
            NTE_MasterPanelController.updateLeadDecision(interestLead.Id, 'INTEREST_PROGRESSED');
        } catch (AuraHandledException expected) {
            manualProgressBlocked = true;
        }
        System.assert(manualProgressBlocked, 'Only the application invitation sender can record successful progress.');
        interestLead = [
            SELECT Id, NTE_Interest_Progressed__c, NTE_Interest_Not_Progressed__c
            FROM Lead WHERE Id = :interestLead.Id
        ];
        System.assertEquals(false, interestLead.NTE_Interest_Progressed__c);
        System.assertEquals(false, interestLead.NTE_Interest_Not_Progressed__c);
        NTE_MasterPanelController.ActionResult notProgressed =
            NTE_MasterPanelController.updateLeadDecision(interestLead.Id, 'INTEREST_NOT_PROGRESSED');
        System.assertEquals(true, notProgressed.success);
        interestLead = [
            SELECT Id, NTE_Interest_Progressed__c, NTE_Interest_Not_Progressed__c
            FROM Lead WHERE Id = :interestLead.Id
        ];
        System.assertEquals(false, interestLead.NTE_Interest_Progressed__c);
        System.assertEquals(true, interestLead.NTE_Interest_Not_Progressed__c);

        NTE_MasterPanelController.ActionResult rejected =
            NTE_MasterPanelController.updateLeadDecision(applicationLead.Id, 'APPLICATION_REJECTED');
        System.assertEquals(true, rejected.success);
        applicationLead = [
            SELECT Id, NTE_Application_Rejected__c FROM Lead WHERE Id = :applicationLead.Id
        ];
        System.assertEquals(true, applicationLead.NTE_Application_Rejected__c);
        System.assertEquals(0, NTE_MasterPanelController.getDashboard(
            'NTE2027', 'ALL', null, 'APPLICATION_REVIEW', 25, 0
        ).totalRows, 'A rejected application must leave the active queue without being deleted.');
        System.assertEquals(1, [SELECT COUNT() FROM Lead WHERE Id = :applicationLead.Id]);

        NTE_MasterPanelController.HomeDashboardResponse home =
            NTE_MasterPanelController.getHomeDashboard('NTE2027');
        Map<String, NTE_MasterPanelController.HomePipelineRow> homeRows =
            new Map<String, NTE_MasterPanelController.HomePipelineRow>();
        for (NTE_MasterPanelController.HomePipelineRow row : home.pipeline) homeRows.put(row.key, row);
        System.assertEquals(0, homeRows.get('INTEREST').count);
        System.assertEquals(0, homeRows.get('APPLICATIONS').count);

        Boolean invalidCombinationBlocked = false;
        try {
            update new Lead(
                Id = interestLead.Id,
                NTE_Interest_Progressed__c = true,
                NTE_Interest_Not_Progressed__c = true
            );
        } catch (DmlException expected) {
            invalidCombinationBlocked = true;
        }
        System.assertEquals(true, invalidCombinationBlocked,
            'The two interest decisions must remain mutually exclusive.');
    }

    @IsTest
    static void everyFinanceViewLinksToTheWeeklyAndCrossEventReports() {
        Set<String> financeViews = new Set<String>{
            'FINANCE_DUE', 'QUOTE_REQUIRED', 'INVOICE_REQUIRED', 'PAYMENT_DUE', 'PAYMENT_COMPLETE'
        };
        NTE_MasterPanelController.reportUrlOverride = new Map<String, String>{
            'NTE_06_Finance_and_Invoicing' => '/lightning/r/Report/00O000000000001AAA/view',
            'NTE_09_Weekly_Finance_Report' => '/lightning/r/Report/00O000000000002AAA/view'
        };
        NTE_MasterPanelController.DashboardResponse response =
            NTE_MasterPanelController.getDashboard('NTE2027', 'ALL', null, 'FINANCE_DUE', 25, 0);
        Integer checkedCount = 0;
        for (NTE_MasterPanelController.WorkQueue queue : response.workQueues) {
            if (!financeViews.contains(queue.key)) continue;
            checkedCount++;
            System.assert(String.isNotBlank(queue.reportUrl), queue.key + ' must link to the all-time finance report.');
            System.assert(String.isNotBlank(queue.weeklyReportUrl), queue.key + ' must link to the weekly finance report.');
            System.assert(queue.weeklyReportUrl.contains('/lightning/r/Report/'));
        }
        System.assertEquals(5, checkedCount);
    }

    @IsTest
    static void reminderDraftUsesPrimaryRecipientsAndOldSenderCannotDispatch() {
        List<Opportunity> staffDue = [
            SELECT Id, Name, NTE_Event_Contact_Email__c
            FROM Opportunity
            WHERE NTE_Event_Code__c = 'NTE2027'
              AND NTE_Staff_Update_Completed_At__c = null
              AND RecordType.DeveloperName = 'NTE_Event_Opportunity'
            ORDER BY Name
        ];
        System.assertEquals(2, staffDue.size());
        Map<Id, Id> primaryContactIdByBooking = new Map<Id, Id>();
        for (OpportunityContactRole roleRecord : [
            SELECT OpportunityId, ContactId
            FROM OpportunityContactRole
            WHERE OpportunityId IN :staffDue
              AND IsPrimary = true
        ]) {
            primaryContactIdByBooking.put(roleRecord.OpportunityId, roleRecord.ContactId);
        }
        System.assertEquals(2, primaryContactIdByBooking.size());
        update new Contact(Id = primaryContactIdByBooking.get(staffDue[0].Id), Email = null);
        System.assert(String.isNotBlank(staffDue[0].NTE_Event_Contact_Email__c),
            'The event-day email remains present so this test proves it is not used as a reminder fallback.');
        Integer opportunityCountBefore = [SELECT COUNT() FROM Opportunity];

        NTE_MasterPanelController.ReminderDraft draft = NTE_MasterPanelController.getReminderDraft(
            'NTE2027', 'ALL', null, 'STAFF_DUE'
        );
        System.assertEquals('Staff update reminders', draft.title);
        System.assertEquals(2, draft.matchingCount);
        System.assertEquals(1, draft.recipientCount);
        System.assertEquals(1, draft.missingEmailCount);
        System.assertEquals(true, draft.canSend);
        System.assert(draft.messageBody.contains('{BookingReference}'));

        Test.startTest();
        Boolean retiredSenderBlocked = false;
        try {
            NTE_MasterPanelController.sendUpdateReminders(
                'NTE2027', 'ALL', null, 'STAFF_DUE', draft.subject, draft.messageBody
            );
        } catch (AuraHandledException expected) {
            retiredSenderBlocked = true;
            System.assert(expected.getMessage().contains('recipient preview'));
        }
        System.assert(retiredSenderBlocked, 'The obsolete filter-based sender must not bypass recipient review.');
        System.assertEquals(0, Limits.getEmailInvocations());
        System.assertEquals(0, [SELECT COUNT() FROM Task WHERE Subject = 'NTE staff reminder sent']);
        Test.stopTest();
        System.assertEquals(opportunityCountBefore, [SELECT COUNT() FROM Opportunity]);

        Boolean unsupportedViewBlocked = false;
        try {
            NTE_MasterPanelController.getReminderDraft('NTE2027', 'ALL', null, 'FINANCE_DUE');
        } catch (AuraHandledException expected) {
            unsupportedViewBlocked = true;
        }
        System.assertEquals(true, unsupportedViewBlocked);
    }

    @IsTest
    static void reminderComposerSupportsFutureEventsWithoutHardCodedYears() {
        Account accountRecord = [SELECT Id FROM Account WHERE Name = 'NTE Master Panel Test Organisation' LIMIT 1];
        String openStage = [
            SELECT MasterLabel
            FROM OpportunityStage
            WHERE IsActive = true AND IsClosed = false
            ORDER BY SortOrder
            LIMIT 1
        ].MasterLabel;
        Opportunity futureBooking = booking(
            accountRecord.Id, openStage, 'Future staff booking', 'NTE-MP-2031', 2500,
            false, false, false, false, false, 'No', null, null
        );
        futureBooking.NTE_Event_Code__c = 'NTE2031';
        insert futureBooking;
        Contact futurePrimaryContact = new Contact(
            AccountId = accountRecord.Id,
            FirstName = 'Future',
            LastName = 'Primary Contact',
            Email = 'future-primary@example.invalid'
        );
        insert futurePrimaryContact;
        insert new OpportunityContactRole(
            OpportunityId = futureBooking.Id,
            ContactId = futurePrimaryContact.Id,
            IsPrimary = true,
            Role = 'Decision Maker'
        );

        NTE_MasterPanelController.ReminderDraft draft = NTE_MasterPanelController.getReminderDraft(
            'NTE2031', 'ALL', null, 'STAFF_DUE'
        );
        System.assertEquals(1, draft.matchingCount);
        System.assertEquals(1, draft.recipientCount);
        System.assertEquals(0, draft.missingEmailCount);
        System.assertEquals(true, draft.canSend);
    }
}
