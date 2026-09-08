@IsTest
private class NTEMasterPanelFinanceTest {
    private static final String EVENT_CODE = 'NTE2096';
    private static final Datetime ORIGINAL_RECORDED_AT = Datetime.newInstanceGMT(2026, 8, 1, 10, 0, 0);

    @TestSetup
    static void createFinanceBookings() {
        for (String permissionName : new List<String>{'NTE_Forms_Administration', 'NTE_Management_User'}) {
            PermissionSet permissions = [SELECT Id FROM PermissionSet WHERE Name = :permissionName LIMIT 1];
            if ([SELECT COUNT() FROM PermissionSetAssignment WHERE AssigneeId = :UserInfo.getUserId()
                AND PermissionSetId = :permissions.Id] == 0) {
                insert new PermissionSetAssignment(AssigneeId = UserInfo.getUserId(), PermissionSetId = permissions.Id);
            }
        }
        System.runAs(new User(Id = UserInfo.getUserId())) {
            Account organisation = new Account(Name = 'NTE Combined Finance Test');
            insert organisation;
            Id recordTypeId = [SELECT Id FROM RecordType WHERE SobjectType = 'Opportunity'
                AND DeveloperName = 'NTE_Event_Opportunity' LIMIT 1].Id;
            String stageName = [SELECT MasterLabel FROM OpportunityStage WHERE IsActive = true
                AND IsClosed = false ORDER BY SortOrder LIMIT 1].MasterLabel;
            insert new List<Opportunity>{
                booking(organisation.Id, recordTypeId, stageName, 'BOTH-INVOICES', 1000, false, false, 100, false, false),
                booking(organisation.Id, recordTypeId, stageName, 'BOTH-PAYMENTS', 1000, true, false, 100, true, false),
                booking(organisation.Id, recordTypeId, stageName, 'BOOKING-PAYMENT', 1000, true, false, 100, false, false),
                booking(organisation.Id, recordTypeId, stageName, 'TOPUP-INVOICED-FIRST', 1000, false, false, 100, true, false),
                booking(organisation.Id, recordTypeId, stageName, 'ALL-PAID', 1000, true, true, 100, true, true),
                booking(organisation.Id, recordTypeId, stageName, 'FREE', 0, false, false, 0, false, false),
                booking(organisation.Id, recordTypeId, stageName, 'TOPUP-ONLY', 0, false, false, 100, false, false),
                booking(organisation.Id, recordTypeId, stageName, 'BOOKING-PAID', 1000, true, true, 100, false, false)
            };
        }
    }

    private static Opportunity booking(Id accountId, Id recordTypeId, String stageName, String name,
        Decimal baseAmount, Boolean baseInvoiced, Boolean basePaid, Decimal topUpAmount,
        Boolean topUpInvoiced, Boolean topUpPaid) {
        return new Opportunity(
            AccountId = accountId, RecordTypeId = recordTypeId, Name = name, StageName = stageName,
            CloseDate = Date.today().addDays(30), Booking_Reference__c = 'NTE-FINANCE-' + name,
            NTE_Event_Code__c = EVENT_CODE, NTE_Source_Form_Type__c = 'Exhibitor Application',
            Amount = baseAmount, NTE_Listed_Price_Total__c = baseAmount, NTE_Pricing_Status__c = 'Calculated',
            NTE_Quote_Required_for_PO__c = 'No', NTE_Invoice_Required__c = baseAmount > 0 ? 'Yes' : 'No',
            NTE_Invoice_Provided__c = baseInvoiced,
            NTE_Invoice_Provided_At__c = baseInvoiced ? ORIGINAL_RECORDED_AT : null,
            NTE_Invoice_Provided_By__c = baseInvoiced ? 'Original finance user' : null,
            NTE_Payment_Received__c = basePaid,
            NTE_Payment_Received_At__c = basePaid ? ORIGINAL_RECORDED_AT : null,
            NTE_Payment_Recorded_By__c = basePaid ? 'Original finance user' : null,
            NTE_Top_Up_Staff_Total__c = topUpAmount, NTE_Top_Up_Invoice_Required__c = topUpAmount > 0,
            NTE_Top_Up_Invoice_Provided__c = topUpInvoiced,
            NTE_Top_Up_Invoice_At__c = topUpInvoiced ? ORIGINAL_RECORDED_AT : null,
            NTE_Top_Up_Invoice_By__c = topUpInvoiced ? 'Original finance user' : null,
            NTE_Top_Up_Payment_Received__c = topUpPaid,
            NTE_Top_Up_Payment_At__c = topUpPaid ? ORIGINAL_RECORDED_AT : null,
            NTE_Top_Up_Payment_By__c = topUpPaid ? 'Original finance user' : null,
            NTE_Heavy_Vehicle_Required__c = 'No', NTE_Staff_Update_Completed_At__c = ORIGINAL_RECORDED_AT,
            NTE_Logo_Update_Provided__c = true
        );
    }

    @IsTest
    static void combinedRefinersAndOverviewCountEachBookingOnce() {
        Test.startTest();
        NTE_MasterPanelController.DashboardResponse response = dashboard('TOP_UP_INVOICE_REQUIRED');
        Test.stopTest();
        System.assertEquals('INVOICE_REQUIRED', response.selectedViewKey);
        System.assertEquals(new Set<String>{'BOTH-INVOICES', 'BOOKING-PAYMENT', 'TOPUP-INVOICED-FIRST',
            'TOPUP-ONLY', 'BOOKING-PAID'}, names(response));
        Map<String, Integer> queueCounts = counts(response);
        System.assertEquals(0, queueCounts.get('QUOTE_REQUIRED'));
        System.assertEquals(5, queueCounts.get('INVOICE_REQUIRED'));
        System.assertEquals(2, queueCounts.get('PAYMENT_DUE'));
        System.assertEquals(1, queueCounts.get('PAYMENT_COMPLETE'));
        System.assertEquals(7, queueCounts.get('FINANCE_DUE'));
        for (String alias : new List<String>{'TOP_UP_INVOICE_REQUIRED', 'TOP_UP_PAYMENT_DUE', 'TOP_UP_PAYMENT_COMPLETE'}) {
            System.assertEquals(false, queueCounts.containsKey(alias));
        }
        List<String> financeLabels = new List<String>();
        for (NTE_MasterPanelController.WorkQueue queue : response.workQueues) {
            if (new Set<String>{'QUOTE_REQUIRED', 'INVOICE_REQUIRED', 'PAYMENT_DUE', 'PAYMENT_COMPLETE'}.contains(queue.key)) {
                financeLabels.add(queue.label);
                System.assertEquals(null, queue.listUrl);
            }
        }
        System.assertEquals(new List<String>{'Quotes required', 'Invoice required', 'Payment required', 'Payment confirmed'}, financeLabels);
        for (NTE_MasterPanelController.EventOverviewRow item : response.overview) {
            if (item.key == 'invoices') {
                System.assertEquals(7, item.total);
                System.assertEquals(response.totalRows, item.inProgress);
                System.assertEquals(2, item.completed);
                System.assertEquals('INVOICE_REQUIRED', item.viewKey);
            } else if (item.key == 'payments') {
                System.assertEquals(3, item.total);
                System.assertEquals(2, item.inProgress);
                System.assertEquals(1, item.completed);
                System.assertEquals('PAYMENT_DUE', item.viewKey);
            }
        }
    }

    @IsTest
    static void paymentRequiredContainsOnlyAnActionableNextPayment() {
        Test.startTest();
        NTE_MasterPanelController.DashboardResponse due = dashboard('TOP_UP_PAYMENT_DUE');
        NTE_MasterPanelController.DashboardResponse confirmed = dashboard('TOP_UP_PAYMENT_COMPLETE');
        Test.stopTest();
        System.assertEquals('PAYMENT_DUE', due.selectedViewKey);
        System.assertEquals(new Set<String>{'BOTH-PAYMENTS', 'BOOKING-PAYMENT'}, names(due),
            'An old booking invoice must not make an uninvoiced top-up payable, or bypass booking-first order.');
        for (NTE_MasterPanelController.DashboardRow item : due.rows) {
            System.assertEquals(true, item.canMarkPaid);
            System.assertEquals(false, item.canMarkTopUpPaid);
            System.assertEquals(false, item.paymentReceived);
        }
        System.assertEquals('PAYMENT_COMPLETE', confirmed.selectedViewKey);
        System.assertEquals(new Set<String>{'ALL-PAID'}, names(confirmed));
        System.assertEquals(true, confirmed.rows[0].paymentReceived);
        System.assertEquals(1100, confirmed.rows[0].amount);
    }

    @IsTest
    static void bookingInvoicePrecedesTopUpWithoutCombiningStoredMilestones() {
        Opportunity source = financeBooking('BOTH-INVOICES');
        NTE_MasterPanelController.DashboardRow before = row(dashboard('INVOICE_REQUIRED'), source.Name);
        System.assertEquals(true, before.canMarkInvoice);
        System.assertEquals(false, before.canMarkTopUpInvoice);
        expectRejected(source.Id, 'TOP_UP_INVOICE_PROVIDED');
        Test.startTest();
        NTE_MasterPanelController.ActionResult bookingInvoice = NTE_MasterPanelController.updateMilestone(source.Id, 'INVOICE_PROVIDED');
        NTE_MasterPanelController.DashboardRow after = row(dashboard('INVOICE_REQUIRED'), source.Name);
        System.assertEquals(false, after.canMarkInvoice);
        System.assertEquals(true, after.canMarkTopUpInvoice);
        System.assertEquals(true, after.baseInvoiceProvided);
        System.assertEquals(false, after.topUpInvoiceProvided);
        System.assertEquals(false, after.invoiceProvided);
        Opportunity bookingOnly = financeBooking(source.Name);
        NTE_MasterPanelController.updateMilestone(source.Id, 'TOP_UP_INVOICE_PROVIDED');
        Test.stopTest();
        Opportunity updated = financeBooking(source.Name);
        System.assertEquals(true, bookingInvoice.success);
        System.assertNotEquals(null, bookingOnly.NTE_Invoice_Provided_At__c);
        System.assertEquals(bookingOnly.NTE_Invoice_Provided_At__c, updated.NTE_Invoice_Provided_At__c);
        System.assertEquals(UserInfo.getName(), updated.NTE_Invoice_Provided_By__c);
        System.assertNotEquals(null, updated.NTE_Top_Up_Invoice_At__c);
        System.assertEquals(UserInfo.getName(), updated.NTE_Top_Up_Invoice_By__c);
        System.assertEquals(false, updated.NTE_Payment_Received__c);
        System.assertEquals(false, updated.NTE_Top_Up_Payment_Received__c);
    }

    @IsTest
    static void bookingPaymentPrecedesTopUpAndPreservesSpaceConfirmation() {
        Opportunity source = financeBooking('BOTH-PAYMENTS');
        NTE_MasterPanelController.DashboardRow before = row(dashboard('PAYMENT_DUE'), source.Name);
        System.assertEquals(true, before.canMarkPaid);
        System.assertEquals(false, before.canMarkTopUpPaid);
        expectRejected(source.Id, 'TOP_UP_PAYMENT_RECEIVED');
        Test.startTest();
        NTE_MasterPanelController.ActionResult bookingPayment = NTE_MasterPanelController.updateMilestone(source.Id, 'PAYMENT_RECEIVED');
        NTE_MasterPanelController.DashboardRow after = row(dashboard('PAYMENT_DUE'), source.Name);
        System.assertEquals(false, after.canMarkPaid);
        System.assertEquals(true, after.canMarkTopUpPaid);
        System.assertEquals(true, after.basePaymentReceived);
        System.assertEquals(false, after.paymentReceived);
        Opportunity bookingOnly = financeBooking(source.Name);
        NTE_MasterPanelController.updateMilestone(source.Id, 'TOP_UP_PAYMENT_RECEIVED');
        Test.stopTest();
        Opportunity updated = financeBooking(source.Name);
        System.assertEquals(true, bookingPayment.success);
        System.assertNotEquals(null, bookingOnly.NTE_Payment_Received_At__c);
        System.assertEquals(bookingOnly.NTE_Payment_Received_At__c, updated.NTE_Payment_Received_At__c);
        System.assertEquals(UserInfo.getName(), updated.NTE_Payment_Recorded_By__c);
        System.assertEquals(true, updated.NTE_Payment_Received__c);
        System.assertEquals(true, updated.NTE_Top_Up_Payment_Received__c);
        System.assertEquals(ORIGINAL_RECORDED_AT, updated.NTE_Invoice_Provided_At__c);
        System.assertEquals(ORIGINAL_RECORDED_AT, updated.NTE_Top_Up_Invoice_At__c);
        System.assertEquals(true, NTE_MasterPanelController.isComplete(updated));
    }

    @IsTest
    static void bookingPaymentDoesNotWaitForTheTopUpInvoice() {
        Opportunity source = financeBooking('BOOKING-PAYMENT');
        NTE_MasterPanelController.DashboardRow before = row(dashboard('PAYMENT_DUE'), source.Name);
        System.assertEquals(true, before.canMarkPaid);
        System.assertEquals(true, before.canMarkTopUpInvoice);
        System.assertEquals(false, before.invoiceProvided);
        System.assertEquals(1000, before.baseAmount);
        System.assertEquals(100, before.topUpAmount);
        Test.startTest();
        NTE_MasterPanelController.updateMilestone(source.Id, 'PAYMENT_RECEIVED');
        NTE_MasterPanelController.DashboardResponse after = dashboard('INVOICE_REQUIRED');
        Test.stopTest();
        NTE_MasterPanelController.DashboardRow remaining = row(after, source.Name);
        System.assertEquals(true, remaining.basePaymentReceived);
        System.assertEquals(true, remaining.canMarkTopUpInvoice);
        System.assertEquals(false, remaining.canMarkTopUpPaid);
        System.assertEquals(1, counts(after).get('PAYMENT_DUE'));
        System.assertEquals(1, counts(after).get('PAYMENT_COMPLETE'));
        Opportunity updated = financeBooking(source.Name);
        System.assertEquals(true, updated.NTE_Payment_Received__c);
        System.assertEquals(ORIGINAL_RECORDED_AT, updated.NTE_Invoice_Provided_At__c);
        System.assertEquals(false, updated.NTE_Top_Up_Invoice_Provided__c);
        System.assertEquals(false, updated.NTE_Top_Up_Payment_Received__c);
        System.assertEquals(null, updated.NTE_Top_Up_Payment_At__c);
    }

    @IsTest
    static void prematurelyInvoicedTopUpStillWaitsForBookingPayment() {
        Opportunity source = financeBooking('TOPUP-INVOICED-FIRST');
        expectRejected(source.Id, 'TOP_UP_PAYMENT_RECEIVED');
        NTE_MasterPanelController.updateMilestone(source.Id, 'INVOICE_PROVIDED');
        NTE_MasterPanelController.DashboardRow bookingDue = row(dashboard('PAYMENT_DUE'), source.Name);
        System.assertEquals(true, bookingDue.canMarkPaid);
        System.assertEquals(false, bookingDue.canMarkTopUpPaid);
        Test.startTest();
        NTE_MasterPanelController.updateMilestone(source.Id, 'PAYMENT_RECEIVED');
        NTE_MasterPanelController.DashboardRow topUpDue = row(dashboard('PAYMENT_DUE'), source.Name);
        System.assertEquals(false, topUpDue.canMarkPaid);
        System.assertEquals(true, topUpDue.canMarkTopUpPaid);
        NTE_MasterPanelController.updateMilestone(source.Id, 'TOP_UP_PAYMENT_RECEIVED');
        Test.stopTest();
        Opportunity updated = financeBooking(source.Name);
        System.assertEquals(ORIGINAL_RECORDED_AT, updated.NTE_Top_Up_Invoice_At__c);
        System.assertEquals('Original finance user', updated.NTE_Top_Up_Invoice_By__c);
        System.assertEquals(true, NTE_MasterPanelController.isComplete(updated));
    }

    @IsTest
    static void complimentaryBookingSkipsOnlyItsOwnFinanceMilestones() {
        Opportunity source = financeBooking('TOPUP-ONLY');
        System.assertEquals(true, NTE_MasterPanelController.isComplete(financeBooking('FREE')));
        NTE_MasterPanelController.DashboardRow before = row(dashboard('INVOICE_REQUIRED'), source.Name);
        System.assertEquals(false, before.canMarkInvoice);
        System.assertEquals(false, before.canMarkPaid);
        System.assertEquals(true, before.canMarkTopUpInvoice);
        expectRejected(source.Id, 'INVOICE_PROVIDED');
        expectRejected(source.Id, 'PAYMENT_RECEIVED');
        expectRejected(source.Id, 'TOP_UP_PAYMENT_RECEIVED');
        Test.startTest();
        NTE_MasterPanelController.updateMilestone(source.Id, 'TOP_UP_INVOICE_PROVIDED');
        NTE_MasterPanelController.updateMilestone(source.Id, 'TOP_UP_PAYMENT_RECEIVED');
        NTE_MasterPanelController.DashboardResponse completed = dashboard('COMPLETED');
        Test.stopTest();
        System.assertEquals(new Set<String>{'ALL-PAID', 'FREE', 'TOPUP-ONLY'}, names(completed));
        Opportunity updated = financeBooking(source.Name);
        System.assertEquals(false, updated.NTE_Invoice_Provided__c);
        System.assertEquals(false, updated.NTE_Payment_Received__c);
        System.assertEquals(true, updated.NTE_Top_Up_Invoice_Provided__c);
        System.assertEquals(true, updated.NTE_Top_Up_Payment_Received__c);
        System.assertEquals(true, NTE_MasterPanelController.isComplete(updated));
    }

    @IsTest
    static void quoteMustBeProvidedBeforeEitherInvoiceCanBeRecorded() {
        Opportunity source = financeBooking('BOTH-INVOICES');
        update new Opportunity(Id = source.Id, NTE_Quote_Required_for_PO__c = 'Yes');
        NTE_MasterPanelController.DashboardResponse before = dashboard('QUOTE_REQUIRED');
        System.assertEquals(new Set<String>{source.Name}, names(before));
        System.assertEquals(4, counts(before).get('INVOICE_REQUIRED'));
        expectRejected(source.Id, 'INVOICE_PROVIDED');
        expectRejected(source.Id, 'TOP_UP_INVOICE_PROVIDED');
        Test.startTest();
        NTE_MasterPanelController.updateMilestone(source.Id, 'QUOTE_PROVIDED');
        NTE_MasterPanelController.DashboardResponse after = dashboard('INVOICE_REQUIRED');
        Test.stopTest();
        System.assertEquals(5, after.totalRows);
        System.assertEquals(true, row(after, source.Name).canMarkInvoice);
        System.assertEquals(false, row(after, source.Name).canMarkTopUpInvoice);
    }

    @IsTest
    static void repeatedActionsPreserveRecordedDatesUsersAndSeparateFlags() {
        Opportunity paid = financeBooking('ALL-PAID');
        Opportunity bookingPaid = financeBooking('BOOKING-PAID');
        Opportunity free = financeBooking('FREE');
        Test.startTest();
        for (String action : new List<String>{'INVOICE_PROVIDED', 'PAYMENT_RECEIVED',
            'TOP_UP_INVOICE_PROVIDED', 'TOP_UP_PAYMENT_RECEIVED'}) {
            expectRejected(paid.Id, action);
            expectRejected(free.Id, action);
        }
        expectRejected(bookingPaid.Id, 'INVOICE_PROVIDED');
        expectRejected(bookingPaid.Id, 'PAYMENT_RECEIVED');
        Test.stopTest();
        Opportunity updated = financeBooking(paid.Name);
        System.assertEquals(ORIGINAL_RECORDED_AT, updated.NTE_Invoice_Provided_At__c);
        System.assertEquals(ORIGINAL_RECORDED_AT, updated.NTE_Payment_Received_At__c);
        System.assertEquals(ORIGINAL_RECORDED_AT, updated.NTE_Top_Up_Invoice_At__c);
        System.assertEquals(ORIGINAL_RECORDED_AT, updated.NTE_Top_Up_Payment_At__c);
        System.assertEquals('Original finance user', updated.NTE_Invoice_Provided_By__c);
        System.assertEquals('Original finance user', updated.NTE_Payment_Recorded_By__c);
        System.assertEquals('Original finance user', updated.NTE_Top_Up_Invoice_By__c);
        System.assertEquals('Original finance user', updated.NTE_Top_Up_Payment_By__c);
        Opportunity unchanged = financeBooking(bookingPaid.Name);
        System.assertEquals(false, unchanged.NTE_Top_Up_Invoice_Provided__c);
        System.assertEquals(false, unchanged.NTE_Top_Up_Payment_Received__c);
        System.assertEquals(null, unchanged.NTE_Top_Up_Invoice_At__c);
        System.assertEquals(null, unchanged.NTE_Top_Up_Payment_At__c);
    }

    @IsTest
    static void unknownPricingCannotAppearFreeConfirmedOrPayableEvenWithOldFlags() {
        Opportunity review = financeBooking('ALL-PAID');
        Opportunity unknownZero = financeBooking('FREE');
        Opportunity missingTotal = financeBooking('TOPUP-ONLY');
        Opportunity negativeTotal = financeBooking('BOOKING-PAID');
        update new List<Opportunity>{
            new Opportunity(Id = review.Id, NTE_Pricing_Status__c = 'Review required'),
            new Opportunity(Id = unknownZero.Id, NTE_Pricing_Status__c = null),
            new Opportunity(Id = missingTotal.Id, NTE_Listed_Price_Total__c = null, Amount = null),
            new Opportunity(Id = negativeTotal.Id, NTE_Listed_Price_Total__c = -1, Amount = -1)
        };
        Set<String> invalidNames = new Set<String>{review.Name, unknownZero.Name, missingTotal.Name, negativeTotal.Name};
        Test.startTest();
        NTE_MasterPanelController.DashboardResponse response = dashboard('INVOICE_REQUIRED');
        for (String name : invalidNames) {
            NTE_MasterPanelController.DashboardRow invalid = row(response, name);
            System.assertEquals(true, invalid.pricingReviewRequired);
            System.assertEquals('Pricing review required', invalid.financeStatus);
            System.assertEquals(false, invalid.invoiceProvided);
            System.assertEquals(false, invalid.paymentReceived);
            System.assertEquals(false, invalid.complete);
            System.assertEquals(null, invalid.baseAmount);
            System.assertEquals(false, invalid.canMarkInvoice);
            System.assertEquals(false, invalid.canMarkPaid);
            System.assertEquals(false, invalid.canMarkTopUpInvoice);
            System.assertEquals(false, invalid.canMarkTopUpPaid);
            for (String action : new List<String>{'INVOICE_PROVIDED', 'PAYMENT_RECEIVED',
                'TOP_UP_INVOICE_PROVIDED', 'TOP_UP_PAYMENT_RECEIVED'}) expectRejected(invalid.recordId, action);
        }
        System.assertEquals(7, response.totalRows);
        System.assertEquals(0, counts(response).get('PAYMENT_COMPLETE'));
        System.assertEquals(0, counts(response).get('COMPLETED'));
        NTE_MasterPanelController.HomeDashboardResponse home = NTE_MasterPanelController.getHomeDashboard(EVENT_CODE);
        Test.stopTest();
        System.assertEquals(4, home.pricingReviewCount);
        for (NTE_MasterPanelController.HomeMetric metric : home.headlines) {
            if (metric.key == 'PAID') System.assertEquals(0, metric.count);
        }
        Opportunity unchanged = financeBooking(review.Name);
        System.assertEquals(true, unchanged.NTE_Payment_Received__c);
        System.assertEquals(true, unchanged.NTE_Top_Up_Payment_Received__c);
        System.assertEquals(ORIGINAL_RECORDED_AT, unchanged.NTE_Payment_Received_At__c);
        unchanged.NTE_Pricing_Status__c = 'Unrecognised historical status';
        System.assertEquals(false, NTE_MasterPanelController.isComplete(unchanged));
    }

    @IsTest
    static void homePreservesPaidBookingMoneyWhenTopUpIsStillOutstanding() {
        Test.startTest();
        NTE_MasterPanelController.HomeDashboardResponse home = NTE_MasterPanelController.getHomeDashboard(EVENT_CODE);
        NTE_MasterPanelController.DashboardResponse panel = dashboard('INVOICE_REQUIRED');
        Test.stopTest();
        Map<String, NTE_MasterPanelController.HomeMetric> headlines = homeMetrics(home.headlines);
        System.assertEquals(6700, headlines.get('CONFIRMED_APPLICATIONS').value);
        System.assertEquals(5, headlines.get('INVOICED').count);
        System.assertEquals(4300, headlines.get('INVOICED').value,
            'Only issued booking and top-up invoices contribute their own charge amounts.');
        System.assertEquals(2, headlines.get('PAID').count);
        System.assertEquals(2100, headlines.get('PAID').value,
            'A paid booking keeps its paid value when its top-up still needs an invoice.');
        System.assertEquals(6, headlines.get('STILL_TO_COLLECT').count);
        System.assertEquals(4600, headlines.get('STILL_TO_COLLECT').value);
        System.assertEquals(headlines.get('CONFIRMED_APPLICATIONS').value,
            headlines.get('PAID').value + headlines.get('STILL_TO_COLLECT').value);
        Map<String, NTE_MasterPanelController.HomeMetric> readiness = homeMetrics(home.revenueReadiness);
        Map<String, Integer> panelCounts = counts(panel);
        System.assertEquals(panelCounts.get('QUOTE_REQUIRED'), readiness.get('QUOTE_REQUIRED').count);
        System.assertEquals(panelCounts.get('INVOICE_REQUIRED'), readiness.get('INVOICE_REQUIRED').count);
        System.assertEquals(panelCounts.get('PAYMENT_DUE'), readiness.get('PAYMENT_REQUIRED').count);
        System.assertEquals(panelCounts.get('PAYMENT_COMPLETE'), readiness.get('PAID').count);
        System.assertEquals(2400, readiness.get('INVOICE_REQUIRED').value);
        System.assertEquals(2100, readiness.get('PAYMENT_REQUIRED').value);
        System.assertEquals(1100, readiness.get('PAID').value);
        System.assertEquals(1, readiness.get('PAID').count,
            'Payment confirmed remains the bookings whose applicable charges are all invoiced and paid.');
    }

    @IsTest
    static void complimentaryQuoteRemainsVisibleWithoutInventingAPayment() {
        Opportunity free = financeBooking('FREE');
        update new Opportunity(Id = free.Id, NTE_Quote_Required_for_PO__c = 'Yes');
        Test.startTest();
        NTE_MasterPanelController.DashboardResponse quoteView = dashboard('QUOTE_REQUIRED');
        NTE_MasterPanelController.HomeDashboardResponse home = NTE_MasterPanelController.getHomeDashboard(EVENT_CODE);
        Test.stopTest();
        NTE_MasterPanelController.DashboardRow quote = row(quoteView, free.Name);
        System.assertEquals('Quote required', quote.financeStatus);
        System.assertEquals(true, quote.canMarkQuote);
        System.assertEquals(false, quote.invoiceRequired);
        System.assertEquals(false, quote.canMarkPaid);
        System.assertEquals(false, quote.complete);
        System.assertEquals(1, homeMetrics(home.revenueReadiness).get('QUOTE_REQUIRED').count);
        NTE_MasterPanelController.updateMilestone(free.Id, 'QUOTE_PROVIDED');
        Opportunity quoted = financeBooking('FREE');
        System.assertEquals(true, NTE_MasterPanelController.isComplete(quoted));
        System.assertEquals(false, quoted.NTE_Invoice_Provided__c);
        System.assertEquals(false, quoted.NTE_Payment_Received__c);
    }

    @IsTest
    static void everyStoredInvoicePaymentCombinationKeepsActionsAndCountsConsistent() {
        Opportunity seed = financeBooking('BOTH-INVOICES');
        Opportunity details = [SELECT AccountId, RecordTypeId, StageName FROM Opportunity WHERE Id = :seed.Id];
        List<Opportunity> matrix = new List<Opportunity>();
        for (Integer mask = 0; mask < 16; mask++) {
            Opportunity item = booking(details.AccountId, details.RecordTypeId, details.StageName,
                'Finance permutation ' + mask, 1000, Math.mod(mask, 2) == 1, Math.mod(mask / 2, 2) == 1,
                100, Math.mod(mask / 4, 2) == 1, Math.mod(mask / 8, 2) == 1);
            item.NTE_Event_Code__c = 'NTE2097';
            matrix.add(item);
        }
        insert matrix;
        Test.startTest();
        NTE_MasterPanelController.DashboardResponse response = NTE_MasterPanelController.getDashboard(
            'NTE2097', 'ALL', null, 'APPROVED', 25, 0);
        NTE_MasterPanelController.HomeDashboardResponse home = NTE_MasterPanelController.getHomeDashboard('NTE2097');
        Test.stopTest();
        Map<Id, Opportunity> byId = new Map<Id, Opportunity>(matrix);
        System.assertEquals(16, response.rows.size());
        for (NTE_MasterPanelController.DashboardRow item : response.rows) {
            Opportunity stored = byId.get(item.recordId);
            System.assertEquals(!stored.NTE_Invoice_Provided__c, item.canMarkInvoice);
            System.assertEquals(stored.NTE_Invoice_Provided__c && !stored.NTE_Payment_Received__c, item.canMarkPaid);
            System.assertEquals(stored.NTE_Invoice_Provided__c && !stored.NTE_Top_Up_Invoice_Provided__c,
                item.canMarkTopUpInvoice);
            System.assertEquals(stored.NTE_Payment_Received__c && stored.NTE_Top_Up_Invoice_Provided__c
                && !stored.NTE_Top_Up_Payment_Received__c, item.canMarkTopUpPaid);
            Boolean complete = stored.NTE_Invoice_Provided__c && stored.NTE_Payment_Received__c
                && stored.NTE_Top_Up_Invoice_Provided__c && stored.NTE_Top_Up_Payment_Received__c;
            System.assertEquals(complete, item.complete, stored.Name);
        }
        Map<String, Integer> panelCounts = counts(response);
        System.assertEquals(12, panelCounts.get('INVOICE_REQUIRED'));
        System.assertEquals(6, panelCounts.get('PAYMENT_DUE'));
        System.assertEquals(1, panelCounts.get('PAYMENT_COMPLETE'));
        System.assertEquals(1, panelCounts.get('COMPLETED'));
        Map<String, NTE_MasterPanelController.HomeMetric> readiness = homeMetrics(home.revenueReadiness);
        System.assertEquals(12, readiness.get('INVOICE_REQUIRED').count);
        System.assertEquals(6, readiness.get('PAYMENT_REQUIRED').count);
        System.assertEquals(1, readiness.get('PAID').count);
        Map<String, NTE_MasterPanelController.HomeMetric> headlines = homeMetrics(home.headlines);
        System.assertEquals(8800, headlines.get('PAID').value);
        System.assertEquals(8800, headlines.get('STILL_TO_COLLECT').value);
        System.assertEquals(17600, headlines.get('CONFIRMED_APPLICATIONS').value);
    }

    @IsTest
    static void knownPositiveLegacyChargeDoesNotRequireAMigration() {
        Opportunity source = financeBooking('BOOKING-PAYMENT');
        update new Opportunity(Id = source.Id, NTE_Pricing_Status__c = null);
        Test.startTest();
        NTE_MasterPanelController.DashboardRow payable = row(dashboard('PAYMENT_DUE'), source.Name);
        System.assertEquals(false, payable.pricingReviewRequired);
        System.assertEquals(true, payable.canMarkPaid);
        NTE_MasterPanelController.updateMilestone(source.Id, 'PAYMENT_RECEIVED');
        Test.stopTest();
        Opportunity updated = financeBooking(source.Name);
        System.assertEquals(null, updated.NTE_Pricing_Status__c);
        System.assertEquals(true, updated.NTE_Payment_Received__c);
        System.assertEquals(false, updated.NTE_Top_Up_Invoice_Provided__c);
    }

    private static NTE_MasterPanelController.DashboardResponse dashboard(String viewKey) {
        return NTE_MasterPanelController.getDashboard(EVENT_CODE, 'ALL', null, viewKey, 25, 0);
    }
    private static Map<String, NTE_MasterPanelController.HomeMetric> homeMetrics(List<NTE_MasterPanelController.HomeMetric> metrics) {
        Map<String, NTE_MasterPanelController.HomeMetric> result = new Map<String, NTE_MasterPanelController.HomeMetric>();
        for (NTE_MasterPanelController.HomeMetric metric : metrics) result.put(metric.key, metric);
        return result;
    }
    private static NTE_MasterPanelController.DashboardRow row(NTE_MasterPanelController.DashboardResponse response, String name) {
        for (NTE_MasterPanelController.DashboardRow item : response.rows) if (item.name == name) return item;
        System.assert(false, name + ' must be present in ' + response.selectedViewKey);
        return null;
    }
    private static Set<String> names(NTE_MasterPanelController.DashboardResponse response) {
        Set<String> result = new Set<String>();
        for (NTE_MasterPanelController.DashboardRow item : response.rows) result.add(item.name);
        System.assertEquals(response.rows.size(), result.size(), 'A booking must appear only once in a combined refiner.');
        System.assertEquals(response.totalRows, response.rows.size(), 'The counter and rows must describe the same selection.');
        return result;
    }
    private static Map<String, Integer> counts(NTE_MasterPanelController.DashboardResponse response) {
        Map<String, Integer> result = new Map<String, Integer>();
        for (NTE_MasterPanelController.WorkQueue queue : response.workQueues) result.put(queue.key, queue.count);
        return result;
    }
    private static Opportunity financeBooking(String name) {
        return [SELECT Id, Name, NTE_Pricing_Status__c, NTE_Listed_Price_Total__c, NTE_Invoice_Required__c,
            NTE_Quote_Required_for_PO__c, NTE_Quote_Provided__c,
            NTE_Invoice_Provided__c, NTE_Invoice_Provided_At__c, NTE_Invoice_Provided_By__c,
            NTE_Payment_Received__c, NTE_Payment_Received_At__c, NTE_Payment_Recorded_By__c,
            NTE_Top_Up_Invoice_Required__c, NTE_Top_Up_Staff_Total__c,
            NTE_Top_Up_Invoice_Provided__c, NTE_Top_Up_Invoice_At__c, NTE_Top_Up_Invoice_By__c,
            NTE_Top_Up_Payment_Received__c, NTE_Top_Up_Payment_At__c, NTE_Top_Up_Payment_By__c,
            NTE_Heavy_Vehicle_Required__c, NTE_Heavy_Vehicle_Update_Completed_At__c,
            NTE_Staff_Update_Completed_At__c, NTE_Logo_Update_Provided__c
            FROM Opportunity WHERE Name = :name AND NTE_Event_Code__c = :EVENT_CODE LIMIT 1];
    }
    private static void expectRejected(Id bookingId, String action) {
        Boolean rejected = false;
        try {
            NTE_MasterPanelController.updateMilestone(bookingId, action);
        } catch (AuraHandledException expected) {
            rejected = true;
        }
        System.assertEquals(true, rejected, action + ' must not change an ineligible or completed milestone.');
    }
}
