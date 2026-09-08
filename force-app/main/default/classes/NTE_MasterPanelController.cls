public with sharing class NTE_MasterPanelController {
    private static final Set<String> APPLICATION_TYPES = new Set<String>{
        'Partner / Sponsor Application', 'Exhibitor Application'
    };
    private static final Set<String> INTEREST_TYPES = new Set<String>{
        'Partner / Sponsor Expression of Interest', 'Exhibitor Expression of Interest'
    };
    private static final Set<String> MAIN_SUBMISSION_TYPES = new Set<String>{
        'Partner / Sponsor Expression of Interest', 'Exhibitor Expression of Interest',
        'Partner / Sponsor Application', 'Exhibitor Application', 'Guest Registration'
    };
    private static final Set<String> OPPORTUNITY_VIEWS = new Set<String>{
        'QUOTE_REQUIRED', 'INVOICE_REQUIRED', 'PAYMENT_DUE', 'HEAVY_DUE',
        'PAYMENT_COMPLETE',
        'STAFF_DUE', 'LOGO_DUE', 'APPROVED', 'APPROVED_EXHIBITOR',
        'APPROVED_PARTNER', 'FINANCE_DUE', 'READINESS_DUE', 'COMPLETED', 'FINAL_PACK_DUE', 'FINAL_PACK_SENT'
    };
    private static final Set<String> LEAD_VIEWS = new Set<String>{
        'APPLICATION_REVIEW', 'APPLICATION_EXHIBITOR', 'APPLICATION_PARTNER',
        'INTEREST', 'INTEREST_EXHIBITOR', 'INTEREST_PARTNER', 'GUESTS'
    };
    private static final Set<String> FINANCE_VIEWS = new Set<String>{
        'FINANCE_DUE', 'QUOTE_REQUIRED', 'INVOICE_REQUIRED', 'PAYMENT_DUE', 'PAYMENT_COMPLETE'
    };
    private static final Set<String> REMINDER_VIEWS = new Set<String>{
        'HEAVY_DUE', 'STAFF_DUE', 'LOGO_DUE'
    };
    private static final String WEEKLY_FINANCE_REPORT = 'NTE_09_Weekly_Finance_Report';
    private static final Integer REMINDER_LIMIT = 100;
    private static final Integer DASHBOARD_ROW_LIMIT = 2000;
    @TestVisible private static Boolean bypassReminderDelivery = false;
    @TestVisible private static String cachedClosedTaskStatus;
    @TestVisible private static Map<String, String> reportUrlOverride;
    private static final Map<String, String> REPORT_BY_VIEW = new Map<String, String>{
        'QUOTE_REQUIRED' => 'NTE_06_Finance_and_Invoicing',
        'INVOICE_REQUIRED' => 'NTE_06_Finance_and_Invoicing',
        'PAYMENT_DUE' => 'NTE_06_Finance_and_Invoicing',
        'PAYMENT_COMPLETE' => 'NTE_06_Finance_and_Invoicing',
        'FINANCE_DUE' => 'NTE_06_Finance_and_Invoicing',
        'HEAVY_DUE' => 'NTE_05_Heavy_Vehicles_and_Logistics',
        'STAFF_DUE' => 'NTE_04_Staff_and_Accreditation_Roster',
        'APPLICATION_REVIEW' => 'NTE_07_Application_and_EOI_Pipeline',
        'APPLICATION_EXHIBITOR' => 'NTE_07_Application_and_EOI_Pipeline',
        'APPLICATION_PARTNER' => 'NTE_07_Application_and_EOI_Pipeline',
        'INTEREST' => 'NTE_07_Application_and_EOI_Pipeline',
        'INTEREST_EXHIBITOR' => 'NTE_07_Application_and_EOI_Pipeline',
        'INTEREST_PARTNER' => 'NTE_07_Application_and_EOI_Pipeline',
        'GUESTS' => 'NTE_01_Guest_Check_In_and_Accessibility',
        'APPROVED' => 'NTE_08_Event_Delivery_Readiness',
        'APPROVED_EXHIBITOR' => 'NTE_08_Event_Delivery_Readiness',
        'APPROVED_PARTNER' => 'NTE_08_Event_Delivery_Readiness',
        'READINESS_DUE' => 'NTE_08_Event_Delivery_Readiness',
        'COMPLETED' => 'NTE_08_Event_Delivery_Readiness',
        'FINAL_PACK_DUE' => 'NTE_08_Event_Delivery_Readiness',
        'FINAL_PACK_SENT' => 'NTE_08_Event_Delivery_Readiness',
        'RECENT' => 'NTE_08_Event_Delivery_Readiness'
    };

    public class FilterOption {
        @AuraEnabled public String label;
        @AuraEnabled public String value;
        public FilterOption(String labelValue, String storedValue) {
            label = labelValue;
            value = storedValue;
        }
    }

    public class SummaryMetric {
        @AuraEnabled public String key;
        @AuraEnabled public String label;
        @AuraEnabled public Integer value;
        @AuraEnabled public String displayValue;
        @AuraEnabled public String detail;
        @AuraEnabled public String icon;
        public SummaryMetric(String metricKey, String metricLabel, Integer metricValue, String display, String metricDetail, String iconName) {
            key = metricKey;
            label = metricLabel;
            value = metricValue;
            displayValue = display;
            detail = metricDetail;
            icon = iconName;
        }
    }

    public class EventOverviewRow {
        @AuraEnabled public String key;
        @AuraEnabled public String groupKey;
        @AuraEnabled public String label;
        @AuraEnabled public Integer total;
        @AuraEnabled public Integer inProgress;
        @AuraEnabled public Integer completed;
        @AuraEnabled public String detail;
        @AuraEnabled public String icon;
        @AuraEnabled public String viewKey;
        public EventOverviewRow(String rowKey, String rowGroup, String rowLabel, Integer totalValue,
            Integer progressValue, Integer completedValue, String rowDetail, String iconName, String targetView) {
            key = rowKey;
            groupKey = rowGroup;
            label = rowLabel;
            total = totalValue;
            inProgress = progressValue;
            completed = completedValue;
            detail = rowDetail;
            icon = iconName;
            viewKey = targetView;
        }
    }

    public class PipelineStep {
        @AuraEnabled public String key;
        @AuraEnabled public String label;
        @AuraEnabled public Integer count;
        @AuraEnabled public String detail;
        @AuraEnabled public String icon;
        @AuraEnabled public String viewKey;
        public PipelineStep(String stepKey, String stepLabel, Integer stepCount, String stepDetail, String iconName, String targetView) {
            key = stepKey;
            label = stepLabel;
            count = stepCount;
            detail = stepDetail;
            icon = iconName;
            viewKey = targetView;
        }
    }

    public class WorkQueue {
        @AuraEnabled public String key;
        @AuraEnabled public String label;
        @AuraEnabled public Integer count;
        @AuraEnabled public String detail;
        @AuraEnabled public String icon;
        @AuraEnabled public String reportUrl;
        @AuraEnabled public String weeklyReportUrl;
        @AuraEnabled public String listUrl;
        public WorkQueue(String queueKey, String queueLabel, Integer queueCount, String queueDetail, String iconName, String relatedReportUrl, String relatedListUrl) {
            key = queueKey;
            label = queueLabel;
            count = queueCount;
            detail = queueDetail;
            icon = iconName;
            reportUrl = relatedReportUrl;
            listUrl = relatedListUrl;
        }
    }

    public class DashboardRow implements Comparable {
        @AuraEnabled public Id recordId;
        @AuraEnabled public String objectApiName;
        @AuraEnabled public String recordUrl;
        @AuraEnabled public String typeLabel;
        @AuraEnabled public String typeIcon;
        @AuraEnabled public String name;
        @AuraEnabled public String organisation;
        @AuraEnabled public String stage;
        @AuraEnabled public String eventCode;
        @AuraEnabled public String ownerName;
        @AuraEnabled public String bookingReference;
        @AuraEnabled public String contactName;
        @AuraEnabled public String contactIssue;
        @AuraEnabled public String eventDayContactName;
        @AuraEnabled public String eventDayContactEmail;
        @AuraEnabled public String eventDayContactPhone;
        @AuraEnabled public String approvalEmailStatus;
        @AuraEnabled public String approvalEmailError;
        @AuraEnabled public Datetime approvalEmailSentAt;
        @AuraEnabled public String finalPackStatus;
        @AuraEnabled public Datetime finalPackSentAt;
        @AuraEnabled public String invitationStatus;
        @AuraEnabled public Datetime invitationSentAt;
        @AuraEnabled public Datetime lastReminderSentAt;
        @AuraEnabled public String email;
        @AuraEnabled public String phone;
        @AuraEnabled public String packageOrSpace;
        @AuraEnabled public Decimal amount;
        @AuraEnabled public Decimal baseAmount;
        @AuraEnabled public Decimal topUpAmount;
        @AuraEnabled public Boolean pricingReviewRequired;
        @AuraEnabled public String financeStatus;
        @AuraEnabled public String staffStatus;
        @AuraEnabled public String logisticsStatus;
        @AuraEnabled public String logoStatus;
        @AuraEnabled public Boolean logoUpdateProvided;
        @AuraEnabled public Datetime logoUpdateProvidedAt;
        @AuraEnabled public Boolean quoteRequired;
        @AuraEnabled public Boolean quoteProvided;
        @AuraEnabled public Boolean invoiceRequired;
        @AuraEnabled public Boolean invoiceProvided;
        @AuraEnabled public Boolean paymentReceived;
        @AuraEnabled public Boolean baseInvoiceRequired;
        @AuraEnabled public Boolean baseInvoiceProvided;
        @AuraEnabled public Boolean basePaymentReceived;
        @AuraEnabled public Boolean topUpInvoiceRequired;
        @AuraEnabled public Boolean topUpInvoiceProvided;
        @AuraEnabled public Boolean topUpPaymentReceived;
        @AuraEnabled public Boolean canMarkQuote;
        @AuraEnabled public Boolean canMarkInvoice;
        @AuraEnabled public Boolean canMarkPaid;
        @AuraEnabled public Boolean canMarkTopUpInvoice;
        @AuraEnabled public Boolean canMarkTopUpPaid;
        @AuraEnabled public Boolean complete;
        @AuraEnabled public Datetime modifiedAt;
        @AuraEnabled public String reportUrl;
        @AuraEnabled public String sourceFormType;
        @AuraEnabled public String accompanyingGuestName;
        @AuraEnabled public String accompanyingGuestEmail;
        @AuraEnabled public String guestAccessibility;
        @AuraEnabled public String interestType;
        @AuraEnabled public String interestAreas;
        @AuraEnabled public String interestDetail;
        @AuraEnabled public String preferredContact;
        @AuraEnabled public String quoteRequirement;
        @AuraEnabled public String paymentMethod;
        @AuraEnabled public String plannedStaffCount;
        @AuraEnabled public String additionalStaffCount;
        @AuraEnabled public String heavyVehicleRequirement;
        @AuraEnabled public String vehicleType;
        @AuraEnabled public String vehicleRegistration;
        @AuraEnabled public String vehicleDimensions;
        @AuraEnabled public String haulierName;

        public Integer compareTo(Object value) {
            DashboardRow other = (DashboardRow)value;
            if (modifiedAt == other.modifiedAt) return compareRecordIds(other);
            if (modifiedAt == null) return 1;
            if (other.modifiedAt == null) return -1;
            if (modifiedAt.getTime() == other.modifiedAt.getTime()) return compareRecordIds(other);
            return modifiedAt.getTime() > other.modifiedAt.getTime() ? -1 : 1;
        }

        private Integer compareRecordIds(DashboardRow other) {
            String thisId = String.valueOf(recordId);
            String otherId = String.valueOf(other.recordId);
            Integer comparison = thisId.compareTo(otherId);
            return comparison == 0 ? 0 : (comparison > 0 ? -1 : 1);
        }
    }

    public class DashboardResponse {
        @AuraEnabled public String selectedEventCode;
        @AuraEnabled public String selectedTimeRange;
        @AuraEnabled public String selectedOwnerId;
        @AuraEnabled public String selectedViewKey;
        @AuraEnabled public List<FilterOption> eventOptions;
        @AuraEnabled public List<FilterOption> ownerOptions;
        @AuraEnabled public List<SummaryMetric> summary;
        @AuraEnabled public List<EventOverviewRow> overview;
        @AuraEnabled public List<PipelineStep> pipeline;
        @AuraEnabled public List<WorkQueue> workQueues;
        @AuraEnabled public WorkQueue selectedView;
        @AuraEnabled public List<DashboardRow> rows;
        @AuraEnabled public Integer totalRows;
        @AuraEnabled public Integer pageSize;
        @AuraEnabled public Integer offsetRows;
        @AuraEnabled public Integer accessibleRows;
        @AuraEnabled public Integer maxOffsetRows;
        @AuraEnabled public Boolean hasNextPage;
        @AuraEnabled public Boolean rowsLimited;
        @AuraEnabled public Datetime refreshedAt;
    }

    public class HomeMetric {
        @AuraEnabled public String key;
        @AuraEnabled public String label;
        @AuraEnabled public Integer count;
        @AuraEnabled public Decimal value;
        public HomeMetric(String metricKey, String metricLabel, Integer metricCount, Decimal metricValue) {
            key = metricKey;
            label = metricLabel;
            count = metricCount;
            value = metricValue;
        }
    }

    public class HomePipelineRow {
        @AuraEnabled public String key;
        @AuraEnabled public String label;
        @AuraEnabled public Integer count;
        @AuraEnabled public Integer exhibitorCount;
        @AuraEnabled public Integer partnerCount;
        @AuraEnabled public Decimal exhibitorValue;
        @AuraEnabled public Decimal partnerValue;
        @AuraEnabled public Decimal totalValue;
        public HomePipelineRow(String rowKey, String rowLabel) {
            key = rowKey;
            label = rowLabel;
            count = 0;
            exhibitorCount = 0;
            partnerCount = 0;
            exhibitorValue = 0;
            partnerValue = 0;
            totalValue = 0;
        }
    }

    public class HomeBookingMixSegment {
        @AuraEnabled public Integer count;
        @AuraEnabled public Decimal value;
        @AuraEnabled public Decimal averageValue;
        public HomeBookingMixSegment() {
            count = 0;
            value = 0;
            averageValue = 0;
        }
    }

    public class HomeBookingMix {
        @AuraEnabled public HomeBookingMixSegment exhibitor;
        @AuraEnabled public HomeBookingMixSegment partner;
        public HomeBookingMix() {
            exhibitor = new HomeBookingMixSegment();
            partner = new HomeBookingMixSegment();
        }
    }

    public class HomeDashboardResponse {
        @AuraEnabled public String selectedEventCode;
        @AuraEnabled public List<FilterOption> eventOptions;
        @AuraEnabled public List<HomeMetric> headlines;
        @AuraEnabled public List<HomePipelineRow> pipeline;
        @AuraEnabled public List<HomeMetric> revenueReadiness;
        @AuraEnabled public HomeBookingMix bookingMix;
        @AuraEnabled public Integer pricingReviewCount;
        @AuraEnabled public Datetime refreshedAt;
    }

    public class ActionResult {
        @AuraEnabled public Boolean success;
        @AuraEnabled public String message;
        @AuraEnabled public Datetime completedAt;
    }

    public class ReminderDraft {
        @AuraEnabled public String viewKey;
        @AuraEnabled public String title;
        @AuraEnabled public Integer matchingCount;
        @AuraEnabled public Integer recipientCount;
        @AuraEnabled public Integer missingEmailCount;
        @AuraEnabled public Integer recipientLimit;
        @AuraEnabled public Boolean canSend;
        @AuraEnabled public String subject;
        @AuraEnabled public String messageBody;
    }

    public class ReminderSendResult {
        @AuraEnabled public Boolean success;
        @AuraEnabled public Integer sentCount;
        @AuraEnabled public Integer failedCount;
        @AuraEnabled public Integer skippedCount;
        @AuraEnabled public String message;
        @AuraEnabled public Datetime completedAt;
    }

    private class ReminderRecipient {
        public Opportunity booking;
        public Contact primaryContact;
        public String updateUrl;
        public ReminderRecipient(Opportunity bookingValue, Contact primaryContactValue, String formUrl) {
            booking = bookingValue;
            primaryContact = primaryContactValue;
            updateUrl = formUrl;
        }
    }

    @AuraEnabled
    public static HomeDashboardResponse getHomeDashboard(String eventCode) {
        try {
            HomeDashboardResponse response = new HomeDashboardResponse();
            response.eventOptions = eventOptions();
            response.selectedEventCode = resolveEventCode(eventCode, response.eventOptions);
            response.bookingMix = new HomeBookingMix();
            response.pricingReviewCount = 0;

            Map<String, HomeMetric> headlineByKey = new Map<String, HomeMetric>{
                'APPLICATIONS' => new HomeMetric('APPLICATIONS', 'Applications', 0, 0),
                'CONFIRMED_APPLICATIONS' => new HomeMetric('CONFIRMED_APPLICATIONS', 'Approved Applications', 0, 0),
                'INVOICED' => new HomeMetric('INVOICED', 'Invoiced', 0, 0),
                'STILL_TO_COLLECT' => new HomeMetric('STILL_TO_COLLECT', 'Still to collect', 0, 0),
                'PAID' => new HomeMetric('PAID', 'Paid', 0, 0)
            };
            Map<String, HomePipelineRow> pipelineByKey = new Map<String, HomePipelineRow>{
                'INTEREST' => new HomePipelineRow('INTEREST', 'Interest'),
                'APPLICATIONS' => new HomePipelineRow('APPLICATIONS', 'Applications'),
                'APPROVED' => new HomePipelineRow('APPROVED', 'Approved'),
                'FINANCES' => new HomePipelineRow('FINANCES', 'Finances'),
                'UPDATES' => new HomePipelineRow('UPDATES', 'Updates'),
                'COMPLETED' => new HomePipelineRow('COMPLETED', 'Completed')
            };
            Map<String, HomeMetric> readinessByKey = new Map<String, HomeMetric>{
                'QUOTE_REQUIRED' => new HomeMetric('QUOTE_REQUIRED', 'Quotes required', 0, 0),
                'INVOICE_REQUIRED' => new HomeMetric('INVOICE_REQUIRED', 'Invoice required', 0, 0),
                'PAYMENT_REQUIRED' => new HomeMetric('PAYMENT_REQUIRED', 'Payment required', 0, 0),
                'PAID' => new HomeMetric('PAID', 'Payment confirmed', 0, 0)
            };

            Map<String, Object> leadBinds = new Map<String, Object>{
                'eventCode' => response.selectedEventCode,
                'commercialLeadTypes' => new Set<String>{
                    'Partner / Sponsor Expression of Interest', 'Exhibitor Expression of Interest',
                    'Partner / Sponsor Application', 'Exhibitor Application'
                }
            };
            String selectedLeadWhere = leadBaseWhere(response.selectedEventCode, null, null)
                + ' AND IsConverted = false AND Web_Form_Type__c IN :commercialLeadTypes';
            List<Lead> leadRecords = (List<Lead>)Database.queryWithBinds(
                'SELECT Web_Form_Type__c, Listed_Price_Total__c, Pricing_Status__c, '
                + 'NTE_Interest_Progressed__c, NTE_Interest_Not_Progressed__c, NTE_Application_Rejected__c '
                + 'FROM Lead WHERE ' + selectedLeadWhere,
                leadBinds,
                AccessLevel.USER_MODE
            );
            for (Lead leadRecord : leadRecords) {
                if (INTEREST_TYPES.contains(leadRecord.Web_Form_Type__c)
                    && (leadRecord.NTE_Interest_Progressed__c || leadRecord.NTE_Interest_Not_Progressed__c)) {
                    continue;
                }
                if (APPLICATION_TYPES.contains(leadRecord.Web_Form_Type__c)
                    && leadRecord.NTE_Application_Rejected__c) {
                    continue;
                }
                Decimal value = knownLeadValue(leadRecord);
                Boolean exhibitor = leadRecord.Web_Form_Type__c != null
                    && leadRecord.Web_Form_Type__c.startsWith('Exhibitor');
                String pipelineKey = APPLICATION_TYPES.contains(leadRecord.Web_Form_Type__c)
                    ? 'APPLICATIONS' : 'INTEREST';
                addToPipeline(pipelineByKey.get(pipelineKey), exhibitor, value);
                if (pipelineKey == 'APPLICATIONS') {
                    addToBookingMix(response.bookingMix, exhibitor, value);
                    addToMetric(headlineByKey.get('APPLICATIONS'), value);
                    if (leadPricingNeedsReview(leadRecord)) response.pricingReviewCount++;
                }
            }

            Map<String, Object> opportunityBinds = new Map<String, Object>{
                'eventCode' => response.selectedEventCode
            };
            String selectedOpportunityWhere = opportunityBaseWhere(response.selectedEventCode, null, null);
            List<Opportunity> opportunityRecords = (List<Opportunity>)Database.queryWithBinds(
                'SELECT NTE_Source_Form_Type__c, NTE_Listed_Price_Total__c, Amount, NTE_Pricing_Status__c, '
                + 'NTE_Invoice_Required__c, NTE_Quote_Required_for_PO__c, NTE_Quote_Provided__c, '
                + 'NTE_Invoice_Provided__c, NTE_Payment_Received__c, NTE_Top_Up_Staff_Total__c, '
                + 'NTE_Top_Up_Invoice_Required__c, NTE_Top_Up_Invoice_Provided__c, NTE_Top_Up_Payment_Received__c, '
                + 'NTE_Heavy_Vehicle_Required__c, '
                + 'NTE_Heavy_Vehicle_Update_Completed_At__c, NTE_Staff_Update_Completed_At__c, NTE_Logo_Update_Provided__c '
                + 'FROM Opportunity WHERE ' + selectedOpportunityWhere,
                opportunityBinds,
                AccessLevel.USER_MODE
            );
            for (Opportunity opportunityRecord : opportunityRecords) {
                Decimal value = knownOpportunityValue(opportunityRecord);
                Boolean exhibitor = opportunityRecord.NTE_Source_Form_Type__c == 'Exhibitor Application';
                Boolean billable = isBillable(opportunityRecord);
                Boolean complete = isComplete(opportunityRecord);
                Boolean updateRequired = isUpdateRequired(opportunityRecord);

                addToMetric(headlineByKey.get('CONFIRMED_APPLICATIONS'), value);
                addToPipeline(pipelineByKey.get('APPROVED'), exhibitor, value);
                addToBookingMix(response.bookingMix, exhibitor, value);

                if (billable || opportunityRecord.NTE_Quote_Required_for_PO__c == 'Yes') {
                    addToPipeline(pipelineByKey.get('FINANCES'), exhibitor, value);
                }
                if (updateRequired) addToPipeline(pipelineByKey.get('UPDATES'), exhibitor, value);
                if (complete) addToPipeline(pipelineByKey.get('COMPLETED'), exhibitor, value);

                Boolean pricingReady = !pricingNeedsReview(opportunityRecord);
                Boolean invoicesComplete = pricingReady && baseInvoiceComplete(opportunityRecord) && topUpInvoiceComplete(opportunityRecord);
                Boolean paymentsComplete = invoicesComplete && basePaymentComplete(opportunityRecord) && topUpPaymentComplete(opportunityRecord);
                Boolean baseBillable = isBaseBillable(opportunityRecord);
                Boolean topUpBillable = isTopUpBillable(opportunityRecord);
                Decimal baseValue = pricingReady ? knownBaseOpportunityValue(opportunityRecord) : 0;
                Decimal topUpValue = pricingReady ? valueOrZero(opportunityRecord.NTE_Top_Up_Staff_Total__c) : 0;
                Decimal invoicedValue = (baseBillable && opportunityRecord.NTE_Invoice_Provided__c ? baseValue : 0)
                    + (topUpBillable && opportunityRecord.NTE_Top_Up_Invoice_Provided__c ? topUpValue : 0);
                Decimal paidValue = (baseBillable && opportunityRecord.NTE_Payment_Received__c ? baseValue : 0)
                    + (topUpBillable && opportunityRecord.NTE_Top_Up_Payment_Received__c ? topUpValue : 0);
                if (pricingReady && ((baseBillable && opportunityRecord.NTE_Invoice_Provided__c)
                    || (topUpBillable && opportunityRecord.NTE_Top_Up_Invoice_Provided__c))) {
                    addToMetric(headlineByKey.get('INVOICED'), invoicedValue);
                }
                if (pricingReady && ((baseBillable && opportunityRecord.NTE_Payment_Received__c)
                    || (topUpBillable && opportunityRecord.NTE_Top_Up_Payment_Received__c))) {
                    addToMetric(headlineByKey.get('PAID'), paidValue);
                }
                if (billable && (!pricingReady || !basePaymentComplete(opportunityRecord) || !topUpPaymentComplete(opportunityRecord))) {
                    Decimal outstandingValue = (baseBillable && !opportunityRecord.NTE_Payment_Received__c ? baseValue : 0)
                        + (topUpBillable && !opportunityRecord.NTE_Top_Up_Payment_Received__c ? topUpValue : 0);
                    addToMetric(headlineByKey.get('STILL_TO_COLLECT'), outstandingValue);
                }
                if (!pricingReady) response.pricingReviewCount++;

                Boolean quoteOutstanding = opportunityRecord.NTE_Quote_Required_for_PO__c == 'Yes'
                    && !opportunityRecord.NTE_Quote_Provided__c;
                if (quoteOutstanding) addToMetric(readinessByKey.get('QUOTE_REQUIRED'), baseValue);
                if (!pricingReady || (!quoteOutstanding && !invoicesComplete)) {
                    Decimal invoiceValue = (baseBillable && !opportunityRecord.NTE_Invoice_Provided__c ? baseValue : 0)
                        + (topUpBillable && !opportunityRecord.NTE_Top_Up_Invoice_Provided__c ? topUpValue : 0);
                    addToMetric(readinessByKey.get('INVOICE_REQUIRED'), invoiceValue);
                }
                Boolean actionablePayment = (baseBillable && opportunityRecord.NTE_Invoice_Provided__c
                        && !opportunityRecord.NTE_Payment_Received__c)
                    || (basePaymentComplete(opportunityRecord) && topUpBillable
                        && opportunityRecord.NTE_Top_Up_Invoice_Provided__c && !opportunityRecord.NTE_Top_Up_Payment_Received__c);
                if (pricingReady && actionablePayment) {
                    Decimal paymentValue = (baseBillable && opportunityRecord.NTE_Invoice_Provided__c
                            && !opportunityRecord.NTE_Payment_Received__c ? baseValue : 0)
                        + (topUpBillable && opportunityRecord.NTE_Top_Up_Invoice_Provided__c
                            && !opportunityRecord.NTE_Top_Up_Payment_Received__c ? topUpValue : 0);
                    addToMetric(readinessByKey.get('PAYMENT_REQUIRED'), paymentValue);
                }
                if (billable && paymentsComplete) addToMetric(readinessByKey.get('PAID'), value);
            }

            finalizeBookingMix(response.bookingMix);
            response.headlines = orderedMetrics(headlineByKey, new List<String>{
                'APPLICATIONS', 'CONFIRMED_APPLICATIONS', 'INVOICED', 'STILL_TO_COLLECT', 'PAID'
            });
            response.pipeline = orderedPipeline(pipelineByKey, new List<String>{
                'INTEREST', 'APPLICATIONS', 'APPROVED', 'FINANCES', 'UPDATES', 'COMPLETED'
            });
            response.revenueReadiness = orderedMetrics(readinessByKey, new List<String>{
                'QUOTE_REQUIRED', 'INVOICE_REQUIRED', 'PAYMENT_REQUIRED', 'PAID'
            });
            response.refreshedAt = System.now();
            return response;
        } catch (Exception exceptionValue) {
            throw handled('The NTE home page could not load. ' + safeMessage(exceptionValue));
        }
    }

    @AuraEnabled
    public static DashboardResponse getDashboard(String eventCode, String timeRange, String ownerId, String viewKey, Integer pageSize, Integer offsetRows) {
        try {
            DashboardResponse response = new DashboardResponse();
            response.eventOptions = eventOptions();
            response.selectedEventCode = resolveEventCode(eventCode, response.eventOptions);
            response.selectedTimeRange = normalizeTimeRange(timeRange);
            response.selectedOwnerId = normalizeOwnerId(ownerId);
            response.selectedViewKey = normalizeViewKey(viewKey);
            response.pageSize = pageSize == null ? 25 : Math.max(10, Math.min(50, pageSize));
            response.ownerOptions = ownerOptions();

            Datetime sinceAt = sinceAt(response.selectedTimeRange);
            Map<String, Object> leadBinds = baseBinds(response.selectedEventCode, response.selectedOwnerId, sinceAt);
            Map<String, Object> opportunityBinds = baseBinds(response.selectedEventCode, response.selectedOwnerId, sinceAt);
            String leadBase = leadBaseWhere(response.selectedEventCode, response.selectedOwnerId, sinceAt);
            String opportunityBase = opportunityBaseWhere(response.selectedEventCode, response.selectedOwnerId, sinceAt);
            Map<String, Integer> counts = counts(leadBase, opportunityBase, leadBinds, opportunityBinds);
            Map<String, String> reportUrls = reportUrls();

            response.summary = summary(counts);
            response.overview = overview(counts);
            response.pipeline = pipeline(counts);
            response.workQueues = workQueues(counts, reportUrls);
            response.selectedView = selectedView(response.selectedViewKey, counts, reportUrls, response.workQueues);
            response.totalRows = viewCount(response.selectedViewKey, counts);
            configurePagination(response, offsetRows);
            response.rows = rows(response.selectedViewKey, leadBase, opportunityBase, leadBinds, opportunityBinds,
                response.pageSize, response.offsetRows, reportUrls.get(REPORT_BY_VIEW.get(response.selectedViewKey)));
            response.refreshedAt = System.now();
            return response;
        } catch (Exception exceptionValue) {
            throw handled('The Master Panel could not load. ' + safeMessage(exceptionValue));
        }
    }

    @AuraEnabled
    public static List<Id> getCommunicationRecordIds(String eventCode, String timeRange, String ownerId, String viewKey) {
        String selectedEvent = communicationEventCode(eventCode);
        String owner = normalizeOwnerId(ownerId);
        if (String.isNotBlank(ownerId) && owner == null) {
            throw handled('The selected owner is no longer valid. Refresh the panel before preparing recipients.');
        }
        Datetime since = sinceAt(communicationTimeRange(timeRange));
        String view = normalizeViewKey(viewKey);
        Boolean interest = new Set<String>{'INTEREST', 'INTEREST_EXHIBITOR', 'INTEREST_PARTNER'}.contains(view);
        if (!interest && !REMINDER_VIEWS.contains(view) && view != 'FINAL_PACK_DUE' && view != 'COMPLETED') {
            throw handled('Choose an interest, outstanding update or final-pack view.');
        }
        String query = interest
            ? 'SELECT Id FROM Lead WHERE ' + leadBaseWhere(selectedEvent, owner, since) + leadViewClause(view)
            : 'SELECT Id FROM Opportunity WHERE ' + opportunityBaseWhere(selectedEvent, owner, since)
                + opportunityViewClause(view == 'COMPLETED' ? 'FINAL_PACK_DUE' : view);
        List<Id> ids = new List<Id>();
        for (SObject record : Database.queryWithBinds(query + ' ORDER BY LastModifiedDate DESC, Id DESC LIMIT 501',
            baseBinds(selectedEvent, owner, since), AccessLevel.USER_MODE)) ids.add(record.Id);
        return ids;
    }

    public class UpdateEmailIssue {
        @AuraEnabled public Id leadId;
        @AuraEnabled public String formType;
        @AuraEnabled public String error;
    }

    @AuraEnabled
    public static List<UpdateEmailIssue> getUpdateEmailIssues(Id opportunityId) {
        List<UpdateEmailIssue> result = new List<UpdateEmailIssue>();
        if (opportunityId == null || opportunityId.getSObjectType() != Opportunity.SObjectType) return result;
        Opportunity booking = [SELECT Booking_Reference__c, NTE_Event_Code__c FROM Opportunity
            WHERE Id = :opportunityId AND RecordType.DeveloperName = 'NTE_Event_Opportunity' WITH USER_MODE LIMIT 1];
        if (String.isBlank(booking.Booking_Reference__c)) return result;
        for (Lead submission : [SELECT Id, Web_Form_Type__c, NTE_Email_Error__c FROM Lead
            WHERE Target_Booking_Reference__c = :booking.Booking_Reference__c
            AND NTE_Update_Status__c = 'Matched and Applied' AND NTE_Applicant_Email_Status__c = 'Failed'
            WITH USER_MODE ORDER BY CreatedDate DESC LIMIT 100]) {
            UpdateEmailIssue issue = new UpdateEmailIssue();
            issue.leadId = submission.Id; issue.formType = submission.Web_Form_Type__c; issue.error = submission.NTE_Email_Error__c;
            result.add(issue);
        }
        return result;
    }

    @AuraEnabled
    public static ActionResult updateLeadDecision(Id leadId, String decisionName) {
        if (leadId == null || leadId.getSObjectType() != Lead.SObjectType) {
            throw handled('Select an NTE Lead before recording a decision.');
        }
        String normalizedDecision = String.isBlank(decisionName) ? '' : decisionName.trim().toUpperCase();
        Set<String> allowedDecisions = new Set<String>{
            'INTEREST_NOT_PROGRESSED', 'APPLICATION_REJECTED'
        };
        if (!allowedDecisions.contains(normalizedDecision)) {
            throw handled('That decision is not supported.');
        }
        try {
            Lead sourceLead = [
                SELECT Id, IsConverted, Web_Form_Type__c, NTE_Event_Code__c,
                       NTE_Interest_Progressed__c, NTE_Interest_Not_Progressed__c,
                       NTE_Application_Rejected__c, NTE_Invitation_Status__c
                FROM Lead
                WHERE Id = :leadId
                WITH USER_MODE
                LIMIT 1
                FOR UPDATE
            ];
            if (sourceLead.IsConverted || String.isBlank(sourceLead.NTE_Event_Code__c)) {
                throw handled('Only an open NTE Lead can be updated from the Master Panel.');
            }

            Lead updateRecord = new Lead(Id = sourceLead.Id);
            String message;
            if (normalizedDecision == 'INTEREST_NOT_PROGRESSED') {
                if (!INTEREST_TYPES.contains(sourceLead.Web_Form_Type__c)) {
                    throw handled('Reject is only available for an expression of interest.');
                }
                if (sourceLead.NTE_Invitation_Status__c == 'Queued' || sourceLead.NTE_Invitation_Status__c == 'Sent' || sourceLead.NTE_Interest_Progressed__c) {
                    throw handled('This interest already has an invitation queued or sent. Refresh the panel to see its current status.');
                }
                if (sourceLead.NTE_Interest_Not_Progressed__c) throw handled('This interest has already been rejected.');
                updateRecord.NTE_Interest_Progressed__c = false;
                updateRecord.NTE_Interest_Not_Progressed__c = true;
                message = 'Expression of interest rejected.';
            } else {
                if (!APPLICATION_TYPES.contains(sourceLead.Web_Form_Type__c)) {
                    throw handled('Reject is only available for an application.');
                }
                if (sourceLead.NTE_Application_Rejected__c) throw handled('This application has already been rejected.');
                updateRecord.NTE_Application_Rejected__c = true;
                message = 'Application marked as rejected.';
            }
            Database.update(updateRecord, AccessLevel.USER_MODE);

            ActionResult result = new ActionResult();
            result.success = true;
            result.message = message;
            result.completedAt = System.now();
            return result;
        } catch (AuraHandledException handledException) {
            throw handledException;
        } catch (Exception exceptionValue) {
            throw handled('The decision could not be saved. ' + safeMessage(exceptionValue));
        }
    }

    @AuraEnabled
    public static ReminderDraft getReminderDraft(String eventCode, String timeRange, String ownerId, String viewKey) {
        try {
            String normalizedView = normalizeReminderView(viewKey);
            List<Opportunity> bookings = reminderBookings(eventCode, timeRange, ownerId, normalizedView);
            NTE_Routing_Config__mdt routing = NTE_Routing_Config__mdt.getInstance('Default');

            ReminderDraft draft = new ReminderDraft();
            draft.viewKey = normalizedView;
            draft.title = reminderTitle(normalizedView);
            draft.matchingCount = bookings.size();
            draft.recipientCount = 0;
            draft.missingEmailCount = 0;
            draft.recipientLimit = REMINDER_LIMIT;
            Boolean missingConfiguration = false;
            Map<Id, Contact> primaryContacts = primaryContactsByOpportunity(bookings);
            for (Opportunity booking : bookings) {
                Contact primaryContact = primaryContacts.get(booking.Id);
                if (primaryContact == null || String.isBlank(primaryContact.Email)) {
                    draft.missingEmailCount++;
                    continue;
                }
                if (String.isBlank(reminderUrl(normalizedView, booking.NTE_Source_Form_Type__c, routing))) {
                    missingConfiguration = true;
                    continue;
                }
                draft.recipientCount++;
            }
            draft.subject = reminderSubject(normalizedView);
            draft.messageBody = reminderBody(normalizedView);
            draft.canSend = draft.recipientCount > 0
                && draft.recipientCount <= REMINDER_LIMIT
                && !missingConfiguration;
            return draft;
        } catch (AuraHandledException handledException) {
            throw handledException;
        } catch (Exception exceptionValue) {
            throw handled('The reminder list could not be prepared. ' + safeMessage(exceptionValue));
        }
    }

    @AuraEnabled
    public static ReminderSendResult sendUpdateReminders(String eventCode, String timeRange, String ownerId,
        String viewKey, String subject, String messageBody) {
        throw handled('Open the recipient preview before sending reminders.');
    }

    @AuraEnabled
    public static ActionResult updateMilestone(Id opportunityId, String actionName) {
        if (opportunityId == null || opportunityId.getSObjectType() != Opportunity.SObjectType) {
            throw handled('Select an NTE Opportunity before updating a milestone.');
        }
        String normalizedAction = String.isBlank(actionName) ? '' : actionName.trim().toUpperCase();
        if (!new Set<String>{'QUOTE_PROVIDED', 'INVOICE_PROVIDED', 'PAYMENT_RECEIVED',
            'TOP_UP_INVOICE_PROVIDED', 'TOP_UP_PAYMENT_RECEIVED'}.contains(normalizedAction)) {
            throw handled('That Master Panel action is not supported.');
        }
        try {
            List<Opportunity> currentBookings = [
                SELECT Id, NTE_Event_Code__c, NTE_Invoice_Required__c, NTE_Quote_Required_for_PO__c,
                       NTE_Quote_Provided__c, NTE_Invoice_Provided__c, NTE_Payment_Received__c,
                       NTE_Listed_Price_Total__c, NTE_Pricing_Status__c,
                       NTE_Top_Up_Staff_Total__c, NTE_Top_Up_Invoice_Required__c,
                       NTE_Top_Up_Invoice_Provided__c, NTE_Top_Up_Payment_Received__c
                FROM Opportunity
                WHERE Id = :opportunityId
                  AND RecordType.DeveloperName = 'NTE_Event_Opportunity'
                  AND NTE_Event_Code__c != null
                  AND NTE_Source_Form_Type__c IN :APPLICATION_TYPES
                  AND (IsClosed = false OR IsWon = true)
                WITH USER_MODE
                LIMIT 1
                FOR UPDATE
            ];
            if (currentBookings.isEmpty()) {
                throw handled('This booking is no longer available in the panel. Refresh and select an active booking.');
            }
            Opportunity booking = currentBookings[0];
            Datetime completedAt = System.now();
            String completedBy = UserInfo.getName();
            Opportunity updateRecord = new Opportunity(Id = booking.Id);
            String message;
            if (pricingNeedsReview(booking)) {
                throw handled('Check the booking pricing before recording a finance milestone.');
            }
            if (normalizedAction == 'QUOTE_PROVIDED') {
                if (booking.NTE_Quote_Required_for_PO__c != 'Yes') throw handled('This booking does not require a quote.');
                if (booking.NTE_Quote_Provided__c) throw handled('The quote has already been recorded.');
                updateRecord.NTE_Quote_Provided__c = true;
                updateRecord.NTE_Quote_Provided_At__c = completedAt;
                updateRecord.NTE_Quote_Provided_By__c = completedBy;
                message = 'Quote marked as provided.';
            } else if (normalizedAction == 'INVOICE_PROVIDED') {
                if (!isBaseBillable(booking)) throw handled('This booking has no booking invoice requirement.');
                if (booking.NTE_Quote_Required_for_PO__c == 'Yes' && !booking.NTE_Quote_Provided__c) {
                    throw handled('Mark the required quote as provided before recording the invoice.');
                }
                if (booking.NTE_Invoice_Provided__c) throw handled('The booking invoice / payment link has already been recorded.');
                updateRecord.NTE_Invoice_Provided__c = true;
                updateRecord.NTE_Invoice_Provided_At__c = completedAt;
                updateRecord.NTE_Invoice_Provided_By__c = completedBy;
                message = 'Booking invoice / Stripe link marked as provided.';
            } else if (normalizedAction == 'PAYMENT_RECEIVED') {
                if (!isBaseBillable(booking)) throw handled('This booking has no booking payment requirement.');
                if (!booking.NTE_Invoice_Provided__c) {
                    throw handled('Mark the booking invoice / payment link as provided before recording its payment.');
                }
                if (booking.NTE_Payment_Received__c) throw handled('The booking payment has already been recorded.');
                updateRecord.NTE_Payment_Received__c = true;
                updateRecord.NTE_Payment_Received_At__c = completedAt;
                updateRecord.NTE_Payment_Recorded_By__c = completedBy;
                message = 'Booking payment marked as received.';
            } else if (normalizedAction == 'TOP_UP_INVOICE_PROVIDED') {
                if (!isTopUpBillable(booking)) throw handled('This booking has no staff top-up invoice requirement.');
                if (!baseInvoiceComplete(booking)) {
                    throw handled('Mark the booking invoice as provided before the staff top-up invoice.');
                }
                if (booking.NTE_Quote_Required_for_PO__c == 'Yes' && !booking.NTE_Quote_Provided__c) {
                    throw handled('Mark the required quote as provided before recording the invoice.');
                }
                if (booking.NTE_Top_Up_Invoice_Provided__c) throw handled('The staff top-up invoice has already been recorded.');
                updateRecord.NTE_Top_Up_Invoice_Provided__c = true;
                updateRecord.NTE_Top_Up_Invoice_At__c = completedAt;
                updateRecord.NTE_Top_Up_Invoice_By__c = completedBy;
                message = 'Staff top-up invoice marked as provided.';
            } else if (normalizedAction == 'TOP_UP_PAYMENT_RECEIVED') {
                if (!isTopUpBillable(booking)) throw handled('This booking has no staff top-up payment requirement.');
                if (!basePaymentComplete(booking)) {
                    throw handled('Record the booking payment before the staff top-up payment.');
                }
                if (!booking.NTE_Top_Up_Invoice_Provided__c) {
                    throw handled('Mark the staff top-up invoice as provided before recording its payment.');
                }
                if (booking.NTE_Top_Up_Payment_Received__c) throw handled('The staff top-up payment has already been recorded.');
                updateRecord.NTE_Top_Up_Payment_Received__c = true;
                updateRecord.NTE_Top_Up_Payment_At__c = completedAt;
                updateRecord.NTE_Top_Up_Payment_By__c = completedBy;
                message = 'Staff top-up payment marked as received.';
            }
            Database.update(updateRecord, AccessLevel.USER_MODE);
            if (normalizedAction == 'PAYMENT_RECEIVED') {
                try {
                    NTEEmailDispatchService.QueueResponse confirmation = NTEEmailDispatchService.queueBookingConfirmation(booking.Id);
                    message = confirmation.queuedCount > 0 ? 'Booking payment recorded. Confirmation email queued.' : confirmation.message;
                } catch (Exception notificationFailure) {
                    message = 'Booking payment recorded. The confirmation email could not be prepared: ' + safeMessage(notificationFailure);
                }
            }
            ActionResult result = new ActionResult();
            result.success = true;
            result.message = message;
            result.completedAt = completedAt;
            return result;
        } catch (AuraHandledException handledException) {
            throw handledException;
        } catch (Exception exceptionValue) {
            throw handled('The milestone could not be updated. ' + safeMessage(exceptionValue));
        }
    }

    private static Map<String, Integer> counts(String leadBase, String opportunityBase, Map<String, Object> leadBinds, Map<String, Object> opportunityBinds) {
        Map<String, Integer> result = new Map<String, Integer>();
        result.put('TOTAL_SUBMITTED', countLead(leadBase + ' AND Web_Form_Type__c IN :mainTypes', copyBindsWith(leadBinds, 'mainTypes', MAIN_SUBMISSION_TYPES)));
        result.put('INTEREST_TOTAL', countLead(leadBase + ' AND Web_Form_Type__c IN :interestTypes', copyBindsWith(leadBinds, 'interestTypes', INTEREST_TYPES)));
        result.put('INTEREST', countLead(leadBase + activeInterestClause() + ' AND Web_Form_Type__c IN :interestTypes', copyBindsWith(leadBinds, 'interestTypes', INTEREST_TYPES)));
        result.put('INTEREST_EXHIBITOR', countLead(leadBase + activeInterestClause() + ' AND Web_Form_Type__c = \'Exhibitor Expression of Interest\'', leadBinds));
        result.put('INTEREST_PARTNER', countLead(leadBase + activeInterestClause() + ' AND Web_Form_Type__c = \'Partner / Sponsor Expression of Interest\'', leadBinds));
        result.put('APPLICATION_REVIEW', countLead(leadBase + activeApplicationClause() + ' AND Web_Form_Type__c IN :applicationTypes', copyBindsWith(leadBinds, 'applicationTypes', APPLICATION_TYPES)));
        result.put('APPLICATION_EXHIBITOR', countLead(leadBase + activeApplicationClause() + ' AND Web_Form_Type__c = \'Exhibitor Application\'', leadBinds));
        result.put('APPLICATION_PARTNER', countLead(leadBase + activeApplicationClause() + ' AND Web_Form_Type__c = \'Partner / Sponsor Application\'', leadBinds));
        result.put('GUESTS', countLead(leadBase + ' AND IsConverted = false AND Web_Form_Type__c = \'Guest Registration\'', leadBinds));
        result.put('GUEST_TOTAL', countLead(leadBase + ' AND Web_Form_Type__c = \'Guest Registration\'', leadBinds));
        result.put('APPROVED', countOpportunity(opportunityBase, opportunityBinds));
        result.put('APPROVED_EXHIBITOR', countOpportunity(opportunityBase + ' AND NTE_Source_Form_Type__c = \'Exhibitor Application\'', opportunityBinds));
        result.put('APPROVED_PARTNER', countOpportunity(opportunityBase + ' AND NTE_Source_Form_Type__c = \'Partner / Sponsor Application\'', opportunityBinds));
        result.put('QUOTE_TOTAL', countOpportunity(opportunityBase + ' AND NTE_Quote_Required_for_PO__c = \'Yes\'', opportunityBinds));
        result.put('QUOTE_REQUIRED', countOpportunity(opportunityBase + ' AND NTE_Quote_Required_for_PO__c = \'Yes\' AND NTE_Quote_Provided__c = false', opportunityBinds));
        result.put('INVOICE_REQUIRED', countOpportunity(opportunityBase + opportunityViewClause('INVOICE_REQUIRED'), opportunityBinds));
        result.put('INVOICE_COMPLETE', countOpportunity(opportunityBase + ' AND ' + pricingReadyClause()
            + ' AND ' + billableClause() + ' AND ' + allInvoicesProvidedClause(), opportunityBinds));
        result.put('PAYMENT_DUE', countOpportunity(opportunityBase + opportunityViewClause('PAYMENT_DUE'), opportunityBinds));
        result.put('PAYMENT_COMPLETE', countOpportunity(opportunityBase + opportunityViewClause('PAYMENT_COMPLETE'), opportunityBinds));
        result.put('FINANCE_DUE', countOpportunity(opportunityBase + ' AND (NTE_Quote_Required_for_PO__c = \'Yes\' OR ' + billableClause() + ')', opportunityBinds));
        result.put('HEAVY_DUE', countOpportunity(opportunityBase + opportunityViewClause('HEAVY_DUE'), opportunityBinds));
        result.put('HEAVY_TOTAL', result.get('APPROVED'));
        result.put('STAFF_DUE', countOpportunity(opportunityBase + ' AND NTE_Staff_Update_Completed_At__c = null', opportunityBinds));
        result.put('LOGO_DUE', countOpportunity(opportunityBase + ' AND NTE_Logo_Update_Provided__c = false', opportunityBinds));
        result.put('READINESS_DUE', countOpportunity(opportunityBase + opportunityViewClause('READINESS_DUE'), opportunityBinds));
        result.put('COMPLETED', countOpportunity(opportunityBase + completeClause(), opportunityBinds));
        result.put('FINAL_PACK_DUE', countOpportunity(opportunityBase + opportunityViewClause('FINAL_PACK_DUE'), opportunityBinds));
        result.put('FINAL_PACK_SENT', countOpportunity(opportunityBase + opportunityViewClause('FINAL_PACK_SENT'), opportunityBinds));
        result.put('RECENT', result.get('TOTAL_SUBMITTED') + result.get('APPROVED'));
        result.put('IN_PROGRESS', Math.max(0, result.get('APPROVED') - result.get('COMPLETED')));
        result.put('INTEREST_COMPLETED', Math.max(0, result.get('INTEREST_TOTAL') - result.get('INTEREST')));
        result.put('APPLICATION_TOTAL', result.get('APPLICATION_REVIEW') + result.get('APPROVED'));
        result.put('PAYMENT_TOTAL', result.get('PAYMENT_DUE') + result.get('PAYMENT_COMPLETE'));
        result.put('INVOICE_TOTAL', result.get('INVOICE_REQUIRED') + result.get('INVOICE_COMPLETE'));
        result.put('QUOTE_COMPLETE', Math.max(0, result.get('QUOTE_TOTAL') - result.get('QUOTE_REQUIRED')));
        result.put('HEAVY_COMPLETE', Math.max(0, result.get('HEAVY_TOTAL') - result.get('HEAVY_DUE')));
        result.put('STAFF_COMPLETE', Math.max(0, result.get('APPROVED') - result.get('STAFF_DUE')));
        result.put('LOGO_COMPLETE', Math.max(0, result.get('APPROVED') - result.get('LOGO_DUE')));
        return result;
    }

    private static List<SummaryMetric> summary(Map<String, Integer> counts) {
        Integer approved = counts.get('APPROVED');
        Integer completed = counts.get('COMPLETED');
        Integer percentage = approved == 0 ? 0 : (completed * 100) / approved;
        return new List<SummaryMetric>{
            new SummaryMetric('submitted', 'Total submitted', counts.get('TOTAL_SUBMITTED'), String.valueOf(counts.get('TOTAL_SUBMITTED')), 'Interest, applications and guests', 'standard:lead'),
            new SummaryMetric('confirmed', 'Approved bookings', approved, String.valueOf(approved), 'Converted exhibitor and partner bookings', 'standard:approval'),
            new SummaryMetric('progress', 'In progress', counts.get('IN_PROGRESS'), String.valueOf(counts.get('IN_PROGRESS')), 'Approved bookings with work remaining', 'standard:work_order'),
            new SummaryMetric('complete', 'Complete', completed, percentage + '%', completed + ' of ' + approved + ' approved bookings', 'standard:task2')
        };
    }

    private static List<EventOverviewRow> overview(Map<String, Integer> counts) {
        return new List<EventOverviewRow>{
            new EventOverviewRow('guests', 'SUBMISSIONS', 'Guest registrations', counts.get('GUEST_TOTAL'), 0,
                counts.get('GUEST_TOTAL'), 'Registrations captured for the selected event', 'standard:people', 'GUESTS'),
            new EventOverviewRow('interest', 'SUBMISSIONS', 'Expressions of interest', counts.get('INTEREST_TOTAL'),
                counts.get('INTEREST'), counts.get('INTEREST_COMPLETED'), 'Open and decided expressions of interest', 'standard:contact_request', 'INTEREST'),
            new EventOverviewRow('applications', 'SUBMISSIONS', 'Applications', counts.get('APPLICATION_TOTAL'),
                counts.get('APPLICATION_REVIEW'), counts.get('APPROVED'), 'Awaiting review and converted to approved bookings', 'standard:lead', 'APPLICATION_REVIEW'),
            new EventOverviewRow('quotes', 'FINANCE', 'Quotes required', counts.get('QUOTE_TOTAL'),
                counts.get('QUOTE_REQUIRED'), counts.get('QUOTE_COMPLETE'), 'Required quotes awaiting issue or already provided', 'standard:quotes', 'QUOTE_REQUIRED'),
            new EventOverviewRow('invoices', 'FINANCE', 'Invoice required', counts.get('INVOICE_TOTAL'),
                counts.get('INVOICE_REQUIRED'), counts.get('INVOICE_COMPLETE'), 'Booking and staff top-up invoices awaiting issue or provided', 'standard:orders', 'INVOICE_REQUIRED'),
            new EventOverviewRow('payments', 'FINANCE', 'Payment required', counts.get('PAYMENT_TOTAL'),
                counts.get('PAYMENT_DUE'), counts.get('PAYMENT_COMPLETE'), 'Booking and staff top-up payments outstanding or confirmed', 'standard:currency', 'PAYMENT_DUE'),
            new EventOverviewRow('approved', 'DELIVERY', 'Approved bookings', counts.get('APPROVED'),
                counts.get('IN_PROGRESS'), counts.get('COMPLETED'), 'Approved bookings still in progress or fully complete', 'standard:approval', 'APPROVED'),
            new EventOverviewRow('heavy', 'DELIVERY', 'Logistics confirmation', counts.get('HEAVY_TOTAL'),
                counts.get('HEAVY_DUE'), counts.get('HEAVY_COMPLETE'), 'Bookings with vehicle requirements confirmed and details supplied where needed', 'standard:shipment', 'HEAVY_DUE'),
            new EventOverviewRow('staff', 'DELIVERY', 'Staff updates', counts.get('APPROVED'),
                counts.get('STAFF_DUE'), counts.get('STAFF_COMPLETE'), 'Approved bookings with staff details outstanding or complete', 'standard:people', 'STAFF_DUE'),
            new EventOverviewRow('logos', 'DELIVERY', 'Logo updates', counts.get('APPROVED'),
                counts.get('LOGO_DUE'), counts.get('LOGO_COMPLETE'), 'Approved bookings with logos outstanding or provided', 'standard:photo', 'LOGO_DUE')
        };
    }

    private static List<PipelineStep> pipeline(Map<String, Integer> counts) {
        Integer approved = counts.get('APPROVED');
        Integer completed = counts.get('COMPLETED');
        Integer percentage = approved == 0 ? 0 : (completed * 100) / approved;
        return new List<PipelineStep>{
            new PipelineStep('interest', 'Interest', counts.get('INTEREST'), 'Expressions of interest', 'standard:contact_request', 'INTEREST'),
            new PipelineStep('applications', 'Applications', counts.get('APPLICATION_REVIEW'), 'Applications awaiting conversion', 'standard:lead', 'APPLICATION_REVIEW'),
            new PipelineStep('approved', 'Approved', counts.get('APPROVED'), 'Approved bookings', 'standard:approval', 'APPROVED'),
            new PipelineStep('finance', 'Finances', counts.get('FINANCE_DUE'), 'Bookings with quote, invoice or payment activity', 'standard:currency', 'FINANCE_DUE'),
            new PipelineStep('readiness', 'Updates', counts.get('READINESS_DUE'), 'Staff, vehicle or logo details outstanding', 'standard:people', 'READINESS_DUE'),
            new PipelineStep('complete', 'Completed', completed, percentage + '% of approved bookings complete', 'standard:task2', 'COMPLETED')
        };
    }

    private static List<WorkQueue> workQueues(Map<String, Integer> counts, Map<String, String> reports) {
        return new List<WorkQueue>{
            queue('INTEREST', 'Expressions of interest', counts, 'Combined exhibitor and partner / sponsor interest', 'standard:contact_request', reports, '/lightning/o/Lead/list?filterName=NTE_Expressions_of_Interest'),
            queue('INTEREST_EXHIBITOR', 'Exhibitor interest', counts, 'Expressions of interest from prospective exhibitors', 'standard:store_group', reports, null),
            queue('INTEREST_PARTNER', 'Partner / sponsor interest', counts, 'Expressions of interest from prospective partners and sponsors', 'standard:people', reports, null),
            queue('APPLICATION_REVIEW', 'Applications', counts, 'Combined exhibitor and partner / sponsor applications', 'standard:lead', reports, '/lightning/o/Lead/list?filterName=NTE_Applications'),
            queue('APPLICATION_EXHIBITOR', 'Exhibitor applications', counts, 'Exhibitor applications awaiting review', 'standard:store_group', reports, null),
            queue('APPLICATION_PARTNER', 'Partner / sponsor applications', counts, 'Partner and sponsor applications awaiting review', 'standard:people', reports, null),
            queue('APPROVED', 'Approved bookings', counts, 'Combined approved exhibitor and partner / sponsor bookings', 'standard:approval', reports, '/lightning/o/Opportunity/list?filterName=NTE_Event_Participation'),
            queue('APPROVED_EXHIBITOR', 'Approved exhibitors', counts, 'Approved exhibitor bookings', 'standard:store_group', reports, null),
            queue('APPROVED_PARTNER', 'Approved partners / sponsors', counts, 'Approved partner and sponsor bookings', 'standard:people', reports, null),
            queue('QUOTE_REQUIRED', 'Quotes required', counts, 'Required quotes not yet provided', 'standard:quotes', reports, null),
            queue('INVOICE_REQUIRED', 'Invoice required', counts, 'Booking or staff top-up invoice not yet provided', 'standard:orders', reports, null),
            queue('PAYMENT_DUE', 'Payment required', counts, 'An invoice has been provided and payment is outstanding', 'standard:currency', reports, null),
            queue('PAYMENT_COMPLETE', 'Payment confirmed', counts, 'All applicable booking and staff top-up payments confirmed', 'standard:currency', reports, null),
            queue('FINANCE_DUE', 'Finance records', counts, 'Bookings with quote, invoice or payment activity', 'standard:currency', reports, null),
            queue('READINESS_DUE', 'Updates required', counts, 'Bookings awaiting staff, heavy-vehicle or logo details', 'standard:work_order', reports, null),
            queue('HEAVY_DUE', 'Logistics outstanding', counts, 'Vehicle requirements or details still need confirmation', 'standard:shipment', reports, '/lightning/o/Opportunity/list?filterName=NTE_Heavy_Vehicle_Updates_Due'),
            queue('STAFF_DUE', 'Staff updates', counts, 'Staff details still required', 'standard:people', reports, '/lightning/o/Opportunity/list?filterName=NTE_Staff_Updates_Due'),
            queue('LOGO_DUE', 'Logo updates', counts, 'Bookings awaiting the latest organisation logo', 'standard:photo', reports, '/lightning/o/Opportunity/list?filterName=NTE_Logo_Updates_Due'),
            queue('FINAL_PACK_DUE', 'Final pack not sent', counts, 'Completed bookings still needing their final pack', 'utility:email', reports, null),
            queue('FINAL_PACK_SENT', 'Final pack sent', counts, 'Completed bookings with their final pack sent', 'utility:email', reports, null),
            queue('COMPLETED', 'Completed bookings', counts, 'Bookings with every applicable step complete', 'standard:task2', reports, null),
            queue('GUESTS', 'Guest list', counts, 'Registered guests', 'standard:people', reports, '/lightning/o/Lead/list?filterName=NTE_Guest_Registrations'),
            queue('RECENT', 'Most recent', counts, 'Latest NTE records across the selected view', 'standard:recent', reports, null)
        };
    }

    private static WorkQueue queue(String key, String label, Map<String, Integer> counts, String detail, String icon, Map<String, String> reports, String listUrl) {
        WorkQueue result = new WorkQueue(key, label, counts.get(key), detail, icon, reports.get(REPORT_BY_VIEW.get(key)), listUrl);
        if (FINANCE_VIEWS.contains(key)) result.weeklyReportUrl = reports.get(WEEKLY_FINANCE_REPORT);
        return result;
    }

    private static WorkQueue selectedView(String viewKey, Map<String, Integer> counts, Map<String, String> reports, List<WorkQueue> queues) {
        for (WorkQueue queueValue : queues) if (queueValue.key == viewKey) return queueValue;
        return queue('RECENT', 'Most recent', counts, 'Latest NTE records matching the selected filters', 'standard:recent', reports, null);
    }

    private static List<DashboardRow> rows(String viewKey, String leadBase, String opportunityBase,
        Map<String, Object> leadBinds, Map<String, Object> opportunityBinds, Integer pageSize, Integer offsetRows, String reportUrl) {
        List<DashboardRow> allRows = new List<DashboardRow>();
        Integer queryLimit = Math.min(DASHBOARD_ROW_LIMIT, offsetRows + pageSize);
        if (LEAD_VIEWS.contains(viewKey) || viewKey == 'RECENT') {
            String leadExtra = leadViewClause(viewKey);
            Map<String, Object> binds = new Map<String, Object>(leadBinds);
            binds.put('interestTypes', INTEREST_TYPES);
            binds.put('applicationTypes', APPLICATION_TYPES);
            binds.put('mainTypes', MAIN_SUBMISSION_TYPES);
            binds.put('queryLimit', queryLimit);
            List<Lead> records = (List<Lead>)Database.queryWithBinds(
                'SELECT Id, Name, Company, Email, Phone, Web_Form_Type__c, Status, IsConverted, '
                + 'NTE_Interest_Progressed__c, NTE_Interest_Not_Progressed__c, NTE_Application_Rejected__c, NTE_Event_Code__c, Owner.Name, '
                + 'NTE_Invitation_Status__c, NTE_Invitation_Sent_At__c, '
                + 'Booking_Reference__c, Accompanying_Guest_Name__c, Accompanying_Guest_Email__c, '
                + 'Guest_Accessibility_Required__c, Partner_Interest_Type__c, Partner_Interest_Areas__c, '
                + 'Partnership_Interest_Detail__c, Exhibitor_Interest_Areas__c, Exhibitor_Interest_Detail__c, '
                + 'Exhibitor_Community_Contribution__c, '
                + 'Preferred_Contact_Method__c, Preferred_Contact_Time__c, Sponsor_Package__c, '
                + 'Exhibitor_Space_Selections__c, Listed_Price_Total__c, Pricing_Status__c, '
                + 'Quote_Required_for_PO__c, Payment_Method__c, Additional_Staff_Count__c, Power_Socket_Count__c, '
                + 'CreatedDate, LastModifiedDate FROM Lead WHERE ' + leadBase + leadExtra
                + ' ORDER BY LastModifiedDate DESC, Id DESC LIMIT :queryLimit', binds, AccessLevel.USER_MODE
            );
            for (Lead recordValue : records) allRows.add(leadRow(recordValue, reportUrl));
        }
        if (OPPORTUNITY_VIEWS.contains(viewKey) || viewKey == 'RECENT') {
            String opportunityExtra = opportunityViewClause(viewKey);
            Map<String, Object> binds = new Map<String, Object>(opportunityBinds);
            binds.put('queryLimit', queryLimit);
            List<Opportunity> records = (List<Opportunity>)Database.queryWithBinds(
                'SELECT Id, Name, Account.Name, StageName, NTE_Event_Code__c, NTE_Source_Form_Type__c, Owner.Name, '
                + 'Booking_Reference__c, NTE_Event_Contact_Name__c, NTE_Event_Contact_Email__c, NTE_Event_Contact_Mobile__c, '
                + 'NTE_Sponsor_Package__c, NTE_Exhibitor_Space_Selections__c, NTE_Power_Socket_Count__c, '
                + 'NTE_Additional_Staff_Count__c, NTE_Planned_Exhibitor_Count__c, NTE_Total_Staff_Count__c, '
                + 'NTE_Top_Up_Staff_Count__c, NTE_Top_Up_Staff_Total__c, NTE_Listed_Price_Total__c, NTE_Pricing_Status__c, Amount, '
                + 'NTE_Invoice_Required__c, NTE_Payment_Method__c, NTE_Quote_Required_for_PO__c, NTE_Quote_Provided__c, '
                + 'NTE_Invoice_Provided__c, NTE_Payment_Received__c, NTE_Top_Up_Invoice_Required__c, '
                + 'NTE_Top_Up_Invoice_Provided__c, NTE_Top_Up_Payment_Received__c, NTE_Heavy_Vehicle_Required__c, '
                + 'NTE_Heavy_Vehicle_Update_Completed_At__c, NTE_Staff_Update_Completed_At__c, '
                + 'NTE_Logo_Update_Provided__c, NTE_Logo_Update_Provided_At__c, '
                + 'NTE_Approval_Email_Status__c, NTE_Approval_Email_Error__c, NTE_Approval_Email_Sent_At__c, '
                + 'NTE_Final_Pack_Status__c, NTE_Final_Pack_Sent_At__c, '
                + 'NTE_Haulier_Vehicle_Type__c, NTE_Haulier_Vehicle_Registration__c, '
                + 'NTE_Haulier_Vehicle_Dimensions__c, NTE_Haulier_Name__c, LastModifiedDate '
                + 'FROM Opportunity WHERE ' + opportunityBase + opportunityExtra
                + ' ORDER BY LastModifiedDate DESC, Id DESC LIMIT :queryLimit', binds, AccessLevel.USER_MODE
            );
            Map<Id, Contact> contacts = NTEBookingContactService.primaryContacts(new Map<Id, Opportunity>(records).keySet(), AccessLevel.USER_MODE);
            for (Opportunity recordValue : records) {
                DashboardRow row = opportunityRow(recordValue, reportUrl);
                Contact primary = contacts.get(recordValue.Id);
                row.contactName = primary == null ? null : primary.Name;
                row.email = primary == null ? null : primary.Email;
                row.phone = primary == null ? null : (String.isBlank(primary.Phone) ? primary.MobilePhone : primary.Phone);
                row.contactIssue = primary == null ? 'Primary contact required' : (String.isBlank(primary.Email) ? 'Primary contact email required' : null);
                allRows.add(row);
            }
        }
        allRows.sort();
        List<DashboardRow> pagedRows = new List<DashboardRow>();
        Integer endIndex = Math.min(allRows.size(), offsetRows + pageSize);
        for (Integer index = offsetRows; index < endIndex; index++) pagedRows.add(allRows[index]);
        Set<Id> pageIds = new Set<Id>();
        Map<Id, DashboardRow> pageById = new Map<Id, DashboardRow>();
        for (DashboardRow row : pagedRows) { pageIds.add(row.recordId); pageById.put(row.recordId, row); }
        for (AggregateResult result : [SELECT Opportunity__c booking, MAX(Sent_At__c) latest
            FROM NTE_Email_Dispatch__c WHERE Opportunity__c IN :pageIds AND Status__c = 'Sent'
            AND Kind__c IN ('STAFF_DUE', 'HEAVY_DUE', 'LOGO_DUE') WITH USER_MODE GROUP BY Opportunity__c]) {
            pageById.get((Id)result.get('booking')).lastReminderSentAt = (Datetime)result.get('latest');
        }
        return pagedRows;
    }

    private static DashboardRow leadRow(Lead recordValue, String reportUrl) {
        DashboardRow row = new DashboardRow();
        row.recordId = recordValue.Id;
        row.objectApiName = 'Lead';
        row.sourceFormType = recordValue.Web_Form_Type__c;
        row.recordUrl = '/lightning/r/Lead/' + recordValue.Id + '/view';
        row.typeLabel = typeLabel(recordValue.Web_Form_Type__c);
        row.typeIcon = typeIcon(recordValue.Web_Form_Type__c);
        row.name = recordValue.Name;
        row.organisation = recordValue.Company;
        row.stage = leadStage(recordValue);
        row.eventCode = recordValue.NTE_Event_Code__c;
        row.ownerName = recordValue.Owner == null ? null : recordValue.Owner.Name;
        row.bookingReference = recordValue.Booking_Reference__c;
        row.contactName = recordValue.Name;
        row.invitationStatus = recordValue.NTE_Invitation_Status__c;
        row.invitationSentAt = recordValue.NTE_Invitation_Sent_At__c;
        row.email = recordValue.Email;
        row.phone = recordValue.Phone;
        row.accompanyingGuestName = recordValue.Accompanying_Guest_Name__c;
        row.accompanyingGuestEmail = recordValue.Accompanying_Guest_Email__c;
        row.guestAccessibility = String.isBlank(recordValue.Guest_Accessibility_Required__c)
            ? 'Not stated' : recordValue.Guest_Accessibility_Required__c;
        row.interestType = recordValue.Web_Form_Type__c == 'Exhibitor Expression of Interest'
            ? 'Exhibitor' : recordValue.Partner_Interest_Type__c;
        row.interestAreas = recordValue.Web_Form_Type__c == 'Exhibitor Expression of Interest'
            ? recordValue.Exhibitor_Interest_Detail__c : recordValue.Partner_Interest_Areas__c;
        row.interestDetail = recordValue.Web_Form_Type__c == 'Exhibitor Expression of Interest'
            ? recordValue.Exhibitor_Community_Contribution__c : recordValue.Partnership_Interest_Detail__c;
        row.preferredContact = preferredContact(recordValue.Preferred_Contact_Method__c, recordValue.Preferred_Contact_Time__c);
        row.packageOrSpace = String.isNotBlank(recordValue.Sponsor_Package__c)
            ? recordValue.Sponsor_Package__c : recordValue.Exhibitor_Space_Selections__c;
        row.amount = recordValue.Listed_Price_Total__c;
        row.baseAmount = row.amount;
        row.topUpAmount = 0;
        row.pricingReviewRequired = leadPricingNeedsReview(recordValue);
        row.quoteRequirement = recordValue.Quote_Required_for_PO__c == 'Yes' ? 'Required' : 'Not requested';
        row.paymentMethod = recordValue.Payment_Method__c;
        row.additionalStaffCount = recordValue.Additional_Staff_Count__c;
        row.financeStatus = 'Not applicable';
        row.staffStatus = 'Not applicable';
        row.logisticsStatus = 'Not applicable';
        row.quoteRequired = false;
        row.quoteProvided = false;
        row.invoiceRequired = false;
        row.invoiceProvided = false;
        row.paymentReceived = false;
        row.canMarkQuote = false;
        row.canMarkInvoice = false;
        row.canMarkPaid = false;
        row.canMarkTopUpInvoice = false;
        row.canMarkTopUpPaid = false;
        row.complete = false;
        row.modifiedAt = recordValue.LastModifiedDate;
        row.reportUrl = reportUrl;
        return row;
    }

    private static DashboardRow opportunityRow(Opportunity recordValue, String reportUrl) {
        DashboardRow row = new DashboardRow();
        row.recordId = recordValue.Id;
        row.objectApiName = 'Opportunity';
        row.sourceFormType = recordValue.NTE_Source_Form_Type__c;
        row.recordUrl = '/lightning/r/Opportunity/' + recordValue.Id + '/view';
        row.typeLabel = typeLabel(recordValue.NTE_Source_Form_Type__c);
        row.typeIcon = typeIcon(recordValue.NTE_Source_Form_Type__c);
        row.name = recordValue.Name;
        row.organisation = recordValue.Account == null ? null : recordValue.Account.Name;
        row.stage = 'Approved';
        row.eventCode = recordValue.NTE_Event_Code__c;
        row.ownerName = recordValue.Owner == null ? null : recordValue.Owner.Name;
        row.bookingReference = recordValue.Booking_Reference__c;
        row.eventDayContactName = recordValue.NTE_Event_Contact_Name__c;
        row.eventDayContactEmail = recordValue.NTE_Event_Contact_Email__c;
        row.eventDayContactPhone = recordValue.NTE_Event_Contact_Mobile__c;
        row.approvalEmailStatus = recordValue.NTE_Approval_Email_Status__c;
        row.approvalEmailError = recordValue.NTE_Approval_Email_Error__c;
        row.approvalEmailSentAt = recordValue.NTE_Approval_Email_Sent_At__c;
        row.finalPackStatus = String.isBlank(recordValue.NTE_Final_Pack_Status__c) ? 'Not sent' : recordValue.NTE_Final_Pack_Status__c;
        row.finalPackSentAt = recordValue.NTE_Final_Pack_Sent_At__c;
        row.packageOrSpace = String.isNotBlank(recordValue.NTE_Sponsor_Package__c)
            ? recordValue.NTE_Sponsor_Package__c
            : recordValue.NTE_Exhibitor_Space_Selections__c;
        row.amount = knownOpportunityValue(recordValue);
        row.topUpAmount = valueOrZero(recordValue.NTE_Top_Up_Staff_Total__c);
        row.pricingReviewRequired = pricingNeedsReview(recordValue);
        row.baseAmount = row.pricingReviewRequired ? null : row.amount - row.topUpAmount;
        row.quoteRequirement = recordValue.NTE_Quote_Required_for_PO__c == 'Yes' ? 'Required' : 'Not requested';
        row.paymentMethod = recordValue.NTE_Payment_Method__c;
        row.plannedStaffCount = recordValue.NTE_Total_Staff_Count__c == null
            ? recordValue.NTE_Planned_Exhibitor_Count__c
            : String.valueOf(recordValue.NTE_Total_Staff_Count__c.intValue());
        row.additionalStaffCount = recordValue.NTE_Additional_Staff_Count__c;
        row.heavyVehicleRequirement = String.isBlank(recordValue.NTE_Heavy_Vehicle_Required__c)
            ? 'Not confirmed' : recordValue.NTE_Heavy_Vehicle_Required__c;
        row.vehicleType = recordValue.NTE_Haulier_Vehicle_Type__c;
        row.vehicleRegistration = recordValue.NTE_Haulier_Vehicle_Registration__c;
        row.vehicleDimensions = recordValue.NTE_Haulier_Vehicle_Dimensions__c;
        row.haulierName = recordValue.NTE_Haulier_Name__c;
        row.quoteRequired = recordValue.NTE_Quote_Required_for_PO__c == 'Yes';
        row.quoteProvided = recordValue.NTE_Quote_Provided__c;
        row.invoiceRequired = isBillable(recordValue);
        row.baseInvoiceRequired = isBaseBillable(recordValue);
        row.baseInvoiceProvided = recordValue.NTE_Invoice_Provided__c;
        row.basePaymentReceived = recordValue.NTE_Payment_Received__c;
        row.topUpInvoiceRequired = isTopUpBillable(recordValue);
        row.topUpInvoiceProvided = recordValue.NTE_Top_Up_Invoice_Provided__c;
        row.topUpPaymentReceived = recordValue.NTE_Top_Up_Payment_Received__c;
        row.invoiceProvided = !row.pricingReviewRequired && baseInvoiceComplete(recordValue) && topUpInvoiceComplete(recordValue);
        row.paymentReceived = row.invoiceProvided && basePaymentComplete(recordValue) && topUpPaymentComplete(recordValue);
        row.canMarkQuote = !row.pricingReviewRequired && row.quoteRequired && !row.quoteProvided;
        row.canMarkInvoice = row.baseInvoiceRequired && !row.pricingReviewRequired && !row.baseInvoiceProvided && (!row.quoteRequired || row.quoteProvided);
        row.canMarkPaid = row.baseInvoiceRequired && !row.pricingReviewRequired && row.baseInvoiceProvided && !row.basePaymentReceived;
        row.canMarkTopUpInvoice = !row.pricingReviewRequired && row.topUpInvoiceRequired && !row.topUpInvoiceProvided
            && baseInvoiceComplete(recordValue) && (!row.quoteRequired || row.quoteProvided);
        row.canMarkTopUpPaid = !row.pricingReviewRequired && row.topUpInvoiceRequired && row.topUpInvoiceProvided
            && !row.topUpPaymentReceived && basePaymentComplete(recordValue);
        row.financeStatus = financeStatus(row);
        row.staffStatus = recordValue.NTE_Staff_Update_Completed_At__c == null ? 'Update required' : 'Complete';
        row.logoUpdateProvided = recordValue.NTE_Logo_Update_Provided__c;
        row.logoUpdateProvidedAt = recordValue.NTE_Logo_Update_Provided_At__c;
        row.logoStatus = row.logoUpdateProvided ? 'Provided' : 'Update required';
        if (recordValue.NTE_Heavy_Vehicle_Required__c == 'Yes') {
            row.logisticsStatus = recordValue.NTE_Heavy_Vehicle_Update_Completed_At__c == null ? 'Update required' : 'Complete';
        } else if (recordValue.NTE_Heavy_Vehicle_Required__c == 'No') {
            row.logisticsStatus = 'Not required';
        } else {
            row.logisticsStatus = 'Not confirmed';
        }
        row.complete = isComplete(recordValue);
        if (row.complete) row.stage = 'Completed';
        row.modifiedAt = recordValue.LastModifiedDate;
        row.reportUrl = reportUrl;
        return row;
    }

    public static Boolean isComplete(Opportunity booking) {
        if (pricingNeedsReview(booking)) return false;
        Boolean quoteReady = booking.NTE_Quote_Required_for_PO__c != 'Yes' || booking.NTE_Quote_Provided__c;
        Boolean financeReady = !isBillable(booking)
            || (baseInvoiceComplete(booking) && topUpInvoiceComplete(booking)
                && basePaymentComplete(booking) && topUpPaymentComplete(booking));
        Boolean logisticsReady = booking.NTE_Heavy_Vehicle_Required__c == 'No'
            || (booking.NTE_Heavy_Vehicle_Required__c == 'Yes' && booking.NTE_Heavy_Vehicle_Update_Completed_At__c != null);
        return quoteReady && financeReady && logisticsReady && booking.NTE_Staff_Update_Completed_At__c != null
            && booking.NTE_Logo_Update_Provided__c;
    }

    private static Boolean isUpdateRequired(Opportunity booking) {
        Boolean logisticsRequired = booking.NTE_Heavy_Vehicle_Required__c != 'No'
            && !(booking.NTE_Heavy_Vehicle_Required__c == 'Yes'
                && booking.NTE_Heavy_Vehicle_Update_Completed_At__c != null);
        return logisticsRequired || booking.NTE_Staff_Update_Completed_At__c == null || !booking.NTE_Logo_Update_Provided__c;
    }

    private static Decimal knownLeadValue(Lead recordValue) {
        if (leadPricingNeedsReview(recordValue)) return 0;
        return recordValue.Listed_Price_Total__c != null && recordValue.Listed_Price_Total__c > 0
            ? recordValue.Listed_Price_Total__c : 0;
    }

    private static Decimal knownOpportunityValue(Opportunity recordValue) {
        if (pricingNeedsReview(recordValue)) return 0;
        return knownBaseOpportunityValue(recordValue) + valueOrZero(recordValue.NTE_Top_Up_Staff_Total__c);
    }

    private static Decimal knownBaseOpportunityValue(Opportunity recordValue) {
        return recordValue.Amount != null && recordValue.Amount > 0
            ? recordValue.Amount
            : (recordValue.NTE_Listed_Price_Total__c != null && recordValue.NTE_Listed_Price_Total__c > 0
                ? recordValue.NTE_Listed_Price_Total__c : 0);
    }

    private static void addToMetric(HomeMetric metric, Decimal value) {
        metric.count++;
        metric.value += value == null ? 0 : value;
    }

    private static void addToPipeline(HomePipelineRow row, Boolean exhibitor, Decimal value) {
        Decimal knownValue = value == null ? 0 : value;
        row.count++;
        row.totalValue += knownValue;
        if (exhibitor) {
            row.exhibitorCount++;
            row.exhibitorValue += knownValue;
        } else {
            row.partnerCount++;
            row.partnerValue += knownValue;
        }
    }

    private static void addToBookingMix(HomeBookingMix mix, Boolean exhibitor, Decimal value) {
        HomeBookingMixSegment segment = exhibitor ? mix.exhibitor : mix.partner;
        segment.count++;
        segment.value += value == null ? 0 : value;
    }

    private static void finalizeBookingMix(HomeBookingMix mix) {
        mix.exhibitor.averageValue = mix.exhibitor.count == 0
            ? 0 : mix.exhibitor.value / mix.exhibitor.count;
        mix.partner.averageValue = mix.partner.count == 0
            ? 0 : mix.partner.value / mix.partner.count;
    }

    private static List<HomeMetric> orderedMetrics(Map<String, HomeMetric> metrics, List<String> keys) {
        List<HomeMetric> ordered = new List<HomeMetric>();
        for (String key : keys) ordered.add(metrics.get(key));
        return ordered;
    }

    private static List<HomePipelineRow> orderedPipeline(Map<String, HomePipelineRow> rowsByKey, List<String> keys) {
        List<HomePipelineRow> ordered = new List<HomePipelineRow>();
        for (String key : keys) ordered.add(rowsByKey.get(key));
        return ordered;
    }

    private static Boolean isBaseBillable(Opportunity booking) {
        return booking.NTE_Invoice_Required__c == 'Yes'
            || (booking.NTE_Listed_Price_Total__c != null && booking.NTE_Listed_Price_Total__c > 0)
            || pricingNeedsReview(booking);
    }

    private static Boolean leadPricingNeedsReview(Lead recordValue) {
        return APPLICATION_TYPES.contains(recordValue.Web_Form_Type__c)
            && !hasKnownPricing(recordValue.Pricing_Status__c, recordValue.Listed_Price_Total__c);
    }

    private static Boolean pricingNeedsReview(Opportunity booking) {
        return !hasKnownPricing(booking.NTE_Pricing_Status__c, booking.NTE_Listed_Price_Total__c);
    }

    private static Boolean hasKnownPricing(String pricingStatus, Decimal listedTotal) {
        if (listedTotal == null || listedTotal < 0) return false;
        if (String.isNotBlank(pricingStatus)) return pricingStatus == 'Calculated';
        return listedTotal > 0;
    }

    private static Boolean isTopUpBillable(Opportunity booking) {
        return booking.NTE_Top_Up_Invoice_Required__c
            || (booking.NTE_Top_Up_Staff_Total__c != null && booking.NTE_Top_Up_Staff_Total__c > 0);
    }

    private static Boolean isBillable(Opportunity booking) {
        return isBaseBillable(booking) || isTopUpBillable(booking);
    }

    private static Boolean baseInvoiceComplete(Opportunity booking) {
        return !isBaseBillable(booking) || booking.NTE_Invoice_Provided__c;
    }

    private static Boolean topUpInvoiceComplete(Opportunity booking) {
        return !isTopUpBillable(booking) || booking.NTE_Top_Up_Invoice_Provided__c;
    }

    private static Boolean basePaymentComplete(Opportunity booking) {
        return !isBaseBillable(booking) || booking.NTE_Payment_Received__c;
    }

    private static Boolean topUpPaymentComplete(Opportunity booking) {
        return !isTopUpBillable(booking) || booking.NTE_Top_Up_Payment_Received__c;
    }

    private static Decimal valueOrZero(Decimal value) {
        return value == null ? 0 : value;
    }

    private static String financeStatus(DashboardRow row) {
        if (row.pricingReviewRequired) return 'Pricing review required';
        if (row.quoteRequired && !row.quoteProvided) return 'Quote required';
        if (!row.invoiceRequired) return 'Not required';
        if (row.baseInvoiceRequired && !row.baseInvoiceProvided) return 'Booking invoice required';
        if (row.topUpInvoiceRequired && !row.topUpInvoiceProvided) return 'Staff top-up invoice required';
        if (row.baseInvoiceRequired && !row.basePaymentReceived) return 'Booking payment required';
        if (row.topUpInvoiceRequired && !row.topUpPaymentReceived) return 'Staff top-up payment required';
        return 'Payment confirmed';
    }

    private static String typeLabel(String formType) {
        if (formType == 'Partner / Sponsor Application') return 'Partner / sponsor';
        if (formType == 'Exhibitor Application') return 'Exhibitor';
        if (formType == 'Guest Registration') return 'Guest';
        if (formType != null && formType.contains('Expression of Interest')) return 'Expression of interest';
        return 'NTE record';
    }

    private static String typeIcon(String formType) {
        if (formType == 'Partner / Sponsor Application') return 'standard:partner_fund_request';
        if (formType == 'Exhibitor Application') return 'standard:store';
        if (formType == 'Guest Registration') return 'standard:people';
        if (formType != null && formType.contains('Expression of Interest')) return 'standard:contact_request';
        return 'standard:record';
    }

    private static String leadStage(Lead recordValue) {
        String formType = recordValue.Web_Form_Type__c;
        if (recordValue.IsConverted) return 'Converted';
        if (recordValue.NTE_Application_Rejected__c || recordValue.NTE_Interest_Not_Progressed__c) return 'Rejected';
        if (INTEREST_TYPES.contains(formType)) {
            if (recordValue.NTE_Invitation_Status__c == 'Queued') return 'Invitation queued';
            if (recordValue.NTE_Invitation_Status__c == 'Sent' || recordValue.NTE_Interest_Progressed__c) return 'Application invited';
        }
        if (formType != null && formType.contains('Expression of Interest')) return 'Interest';
        if (APPLICATION_TYPES.contains(formType)) return 'Application review';
        if (formType == 'Guest Registration') return 'Registered';
        return recordValue.Status;
    }

    private static String preferredContact(String method, String timeValue) {
        if (String.isBlank(method)) return String.isBlank(timeValue) ? 'Not stated' : timeValue;
        return String.isBlank(timeValue) ? method : method + ' · ' + timeValue;
    }

    private static String leadViewClause(String viewKey) {
        if (viewKey == 'INTEREST') return activeInterestClause() + ' AND Web_Form_Type__c IN :interestTypes';
        if (viewKey == 'INTEREST_EXHIBITOR') return activeInterestClause() + ' AND Web_Form_Type__c = \'Exhibitor Expression of Interest\'';
        if (viewKey == 'INTEREST_PARTNER') return activeInterestClause() + ' AND Web_Form_Type__c = \'Partner / Sponsor Expression of Interest\'';
        if (viewKey == 'APPLICATION_REVIEW') return activeApplicationClause() + ' AND Web_Form_Type__c IN :applicationTypes';
        if (viewKey == 'APPLICATION_EXHIBITOR') return activeApplicationClause() + ' AND Web_Form_Type__c = \'Exhibitor Application\'';
        if (viewKey == 'APPLICATION_PARTNER') return activeApplicationClause() + ' AND Web_Form_Type__c = \'Partner / Sponsor Application\'';
        if (viewKey == 'GUESTS') return ' AND IsConverted = false AND Web_Form_Type__c = \'Guest Registration\'';
        return ' AND Web_Form_Type__c IN :mainTypes';
    }

    private static String activeInterestClause() {
        return ' AND IsConverted = false AND NTE_Interest_Progressed__c = false'
            + ' AND NTE_Interest_Not_Progressed__c = false';
    }

    private static String activeApplicationClause() {
        return ' AND IsConverted = false AND NTE_Application_Rejected__c = false';
    }

    private static String opportunityViewClause(String viewKey) {
        if (viewKey == 'APPROVED_EXHIBITOR') return ' AND NTE_Source_Form_Type__c = \'Exhibitor Application\'';
        if (viewKey == 'APPROVED_PARTNER') return ' AND NTE_Source_Form_Type__c = \'Partner / Sponsor Application\'';
        if (viewKey == 'QUOTE_REQUIRED') return ' AND NTE_Quote_Required_for_PO__c = \'Yes\' AND NTE_Quote_Provided__c = false';
        if (viewKey == 'INVOICE_REQUIRED') return ' AND (' + pricingReviewClause()
            + ' OR (' + quoteResolvedClause() + ' AND ' + anyInvoiceOutstandingClause() + '))';
        if (viewKey == 'PAYMENT_DUE') return ' AND ' + pricingReadyClause() + ' AND '
            + actionablePaymentClause();
        if (viewKey == 'PAYMENT_COMPLETE') return ' AND ' + pricingReadyClause() + ' AND ' + billableClause()
            + ' AND ' + allInvoicesProvidedClause() + ' AND ' + allPaymentsReceivedClause();
        if (viewKey == 'FINANCE_DUE') return ' AND (NTE_Quote_Required_for_PO__c = \'Yes\' OR ' + billableClause() + ')';
        if (viewKey == 'HEAVY_DUE') return ' AND ' + logisticsOutstandingClause();
        if (viewKey == 'STAFF_DUE') return ' AND NTE_Staff_Update_Completed_At__c = null';
        if (viewKey == 'LOGO_DUE') return ' AND NTE_Logo_Update_Provided__c = false';
        if (viewKey == 'READINESS_DUE') return ' AND (NTE_Logo_Update_Provided__c = false OR NTE_Staff_Update_Completed_At__c = null OR '
            + logisticsOutstandingClause() + ')';
        if (viewKey == 'COMPLETED') return completeClause();
        if (viewKey == 'FINAL_PACK_DUE') return completeClause()
            + ' AND (NTE_Final_Pack_Status__c = null OR NTE_Final_Pack_Status__c NOT IN (\'Sent\', \'Queued\'))';
        if (viewKey == 'FINAL_PACK_SENT') return completeClause() + ' AND NTE_Final_Pack_Status__c = \'Sent\'';
        return '';
    }

    private static String logisticsOutstandingClause() {
        return '(NTE_Heavy_Vehicle_Required__c = null OR NTE_Heavy_Vehicle_Required__c NOT IN (\'Yes\', \'No\')'
            + ' OR (NTE_Heavy_Vehicle_Required__c = \'Yes\' AND NTE_Heavy_Vehicle_Update_Completed_At__c = null))';
    }

    private static String completeClause() {
        return ' AND ' + pricingReadyClause()
            + ' AND (NTE_Quote_Required_for_PO__c != \'Yes\' OR NTE_Quote_Required_for_PO__c = null OR NTE_Quote_Provided__c = true)'
            + ' AND (' + notBillableClause() + ' OR (' + allInvoicesProvidedClause() + ' AND ' + allPaymentsReceivedClause() + '))'
            + ' AND (NTE_Heavy_Vehicle_Required__c = \'No\' OR '
            + '(NTE_Heavy_Vehicle_Required__c = \'Yes\' AND NTE_Heavy_Vehicle_Update_Completed_At__c != null))'
            + ' AND NTE_Staff_Update_Completed_At__c != null AND NTE_Logo_Update_Provided__c = true';
    }

    private static String billableClause() {
        return '(' + baseBillableClause() + ' OR ' + topUpBillableClause() + ')';
    }

    private static String baseBillableClause() {
        return '(NTE_Invoice_Required__c = \'Yes\' OR NTE_Listed_Price_Total__c > 0 OR ' + pricingReviewClause() + ')';
    }

    private static String pricingReadyClause() {
        return '((NTE_Pricing_Status__c = \'Calculated\' AND NTE_Listed_Price_Total__c >= 0)'
            + ' OR (NTE_Pricing_Status__c = null AND NTE_Listed_Price_Total__c > 0))';
    }

    private static String pricingReviewClause() {
        return '(NTE_Listed_Price_Total__c = null OR NTE_Listed_Price_Total__c < 0'
            + ' OR (NTE_Pricing_Status__c != null AND NTE_Pricing_Status__c != \'Calculated\')'
            + ' OR (NTE_Pricing_Status__c = null AND NTE_Listed_Price_Total__c = 0))';
    }

    private static String topUpBillableClause() {
        return '(NTE_Top_Up_Invoice_Required__c = true OR NTE_Top_Up_Staff_Total__c > 0)';
    }

    private static String anyInvoiceOutstandingClause() {
        return '((' + baseBillableClause() + ' AND NTE_Invoice_Provided__c = false) OR ('
            + topUpBillableClause() + ' AND NTE_Top_Up_Invoice_Provided__c = false))';
    }

    private static String allInvoicesProvidedClause() {
        return '((' + baseNotBillableClause() + ' OR NTE_Invoice_Provided__c = true) AND ('
            + topUpNotBillableClause() + ' OR NTE_Top_Up_Invoice_Provided__c = true))';
    }

    private static String actionablePaymentClause() {
        return '((' + baseBillableClause() + ' AND NTE_Invoice_Provided__c = true AND NTE_Payment_Received__c = false) OR ('
            + '(' + baseNotBillableClause() + ' OR NTE_Payment_Received__c = true) AND '
            + topUpBillableClause() + ' AND NTE_Top_Up_Invoice_Provided__c = true AND NTE_Top_Up_Payment_Received__c = false))';
    }

    private static String allPaymentsReceivedClause() {
        return '((' + baseNotBillableClause() + ' OR NTE_Payment_Received__c = true) AND ('
            + topUpNotBillableClause() + ' OR NTE_Top_Up_Payment_Received__c = true))';
    }

    private static String quoteResolvedClause() {
        return '(NTE_Quote_Required_for_PO__c != \'Yes\' OR NTE_Quote_Required_for_PO__c = null OR NTE_Quote_Provided__c = true)';
    }

    private static String notBillableClause() {
        return '(' + baseNotBillableClause() + ' AND ' + topUpNotBillableClause() + ')';
    }

    private static String baseNotBillableClause() {
        return '((NTE_Invoice_Required__c != \'Yes\' OR NTE_Invoice_Required__c = null)'
            + ' AND (NTE_Listed_Price_Total__c <= 0 OR NTE_Listed_Price_Total__c = null)'
            + ' AND ' + pricingReadyClause() + ')';
    }

    private static String topUpNotBillableClause() {
        return '((NTE_Top_Up_Invoice_Required__c = false OR NTE_Top_Up_Invoice_Required__c = null)'
            + ' AND (NTE_Top_Up_Staff_Total__c <= 0 OR NTE_Top_Up_Staff_Total__c = null))';
    }

    private static Integer viewCount(String viewKey, Map<String, Integer> counts) {
        return counts.containsKey(viewKey) ? counts.get(viewKey) : counts.get('RECENT');
    }

    @TestVisible
    private static void configurePagination(DashboardResponse response, Integer requestedOffset) {
        response.accessibleRows = Math.min(response.totalRows, DASHBOARD_ROW_LIMIT);
        response.rowsLimited = response.totalRows > response.accessibleRows;
        response.maxOffsetRows = response.accessibleRows == 0 ? 0
            : ((response.accessibleRows - 1) / response.pageSize) * response.pageSize;
        Integer offset = requestedOffset == null ? 0 : Math.max(0, requestedOffset);
        response.offsetRows = Math.min(response.maxOffsetRows, (offset / response.pageSize) * response.pageSize);
        response.hasNextPage = response.offsetRows + response.pageSize < response.accessibleRows;
    }

    private static Integer countLead(String whereClause, Map<String, Object> binds) {
        return Database.countQueryWithBinds('SELECT COUNT() FROM Lead WHERE ' + whereClause, binds, AccessLevel.USER_MODE);
    }

    private static Integer countOpportunity(String whereClause, Map<String, Object> binds) {
        return Database.countQueryWithBinds('SELECT COUNT() FROM Opportunity WHERE ' + whereClause, binds, AccessLevel.USER_MODE);
    }

    private static String leadBaseWhere(String eventCode, String ownerId, Datetime sinceAt) {
        List<String> clauses = new List<String>{'NTE_Event_Code__c != null'};
        if (String.isNotBlank(eventCode)) clauses.add('NTE_Event_Code__c = :eventCode');
        if (String.isNotBlank(ownerId)) clauses.add('OwnerId = :ownerId');
        if (sinceAt != null) clauses.add('CreatedDate >= :sinceAt');
        return String.join(clauses, ' AND ');
    }

    private static String opportunityBaseWhere(String eventCode, String ownerId, Datetime sinceAt) {
        List<String> clauses = new List<String>{
            'RecordType.DeveloperName = \'NTE_Event_Opportunity\'',
            'NTE_Event_Code__c != null',
            'NTE_Source_Form_Type__c IN (\'Partner / Sponsor Application\', \'Exhibitor Application\')',
            '(IsClosed = false OR IsWon = true)'
        };
        if (String.isNotBlank(eventCode)) clauses.add('NTE_Event_Code__c = :eventCode');
        if (String.isNotBlank(ownerId)) clauses.add('OwnerId = :ownerId');
        if (sinceAt != null) clauses.add('CreatedDate >= :sinceAt');
        return String.join(clauses, ' AND ');
    }

    private static Map<String, Object> baseBinds(String eventCode, String ownerId, Datetime sinceAt) {
        Map<String, Object> binds = new Map<String, Object>{
            'eventCode' => eventCode,
            'ownerId' => ownerId,
            'sinceAt' => sinceAt,
            'mainTypes' => MAIN_SUBMISSION_TYPES,
            'interestTypes' => INTEREST_TYPES,
            'applicationTypes' => APPLICATION_TYPES
        };
        return binds;
    }

    private static Map<String, Object> copyBindsWith(Map<String, Object> source, String bindName, Object bindValue) {
        Map<String, Object> result = new Map<String, Object>();
        result.putAll(source);
        result.put(bindName, bindValue);
        return result;
    }

    private static List<FilterOption> eventOptions() {
        Set<String> values = new Set<String>();
        for (AggregateResult result : [
            SELECT NTE_Event_Code__c code
            FROM Lead
            WHERE NTE_Event_Code__c != null AND Web_Form_Type__c IN :MAIN_SUBMISSION_TYPES
            WITH USER_MODE
            GROUP BY NTE_Event_Code__c
        ]) {
            values.add((String)result.get('code'));
        }
        for (AggregateResult result : [
            SELECT NTE_Event_Code__c code
            FROM Opportunity
            WHERE NTE_Event_Code__c != null
              AND RecordType.DeveloperName = 'NTE_Event_Opportunity'
              AND NTE_Source_Form_Type__c IN :APPLICATION_TYPES
              AND (IsClosed = false OR IsWon = true)
            WITH USER_MODE
            GROUP BY NTE_Event_Code__c
        ]) {
            values.add((String)result.get('code'));
        }
        List<String> sortedValues = new List<String>(values);
        sortedValues.sort();
        List<FilterOption> options = new List<FilterOption>();
        for (Integer index = sortedValues.size() - 1; index >= 0; index--) {
            options.add(new FilterOption(sortedValues[index], sortedValues[index]));
        }
        return options;
    }

    private static List<FilterOption> ownerOptions() {
        List<FilterOption> options = new List<FilterOption>{new FilterOption('All owners', '')};
        for (User userRecord : [SELECT Id, Name FROM User WHERE IsActive = true AND UserType = 'Standard' WITH USER_MODE ORDER BY Name]) {
            options.add(new FilterOption(userRecord.Name, userRecord.Id));
        }
        for (Group queueRecord : [SELECT Id, Name FROM Group WHERE Type = 'Queue' WITH USER_MODE ORDER BY Name]) {
            options.add(new FilterOption('Queue: ' + queueRecord.Name, queueRecord.Id));
        }
        return options;
    }

    private static Map<String, String> reportUrls() {
        if (Test.isRunningTest() && reportUrlOverride != null) {
            return new Map<String, String>(reportUrlOverride);
        }
        Set<String> developerNames = new Set<String>(REPORT_BY_VIEW.values());
        developerNames.add(WEEKLY_FINANCE_REPORT);
        Map<String, String> result = new Map<String, String>();
        for (Report reportRecord : [SELECT Id, DeveloperName FROM Report WHERE DeveloperName IN :developerNames WITH USER_MODE]) {
            result.put(reportRecord.DeveloperName, '/lightning/r/Report/' + reportRecord.Id + '/view');
        }
        return result;
    }

    private static String resolveEventCode(String requested, List<FilterOption> options) {
        if (String.isNotBlank(requested)) {
            for (FilterOption option : options) if (option.value == requested) return requested;
        }
        for (FilterOption option : options) {
            if (Pattern.matches('^NTE[0-9]{4}$', option.value)) return option.value;
        }
        return options.isEmpty() ? null : options[0].value;
    }

    private static String communicationEventCode(String requested) {
        if (String.isNotBlank(requested)) {
            for (FilterOption option : eventOptions()) if (option.value == requested) return requested;
        }
        throw handled('The selected event is no longer available. Refresh the panel before preparing recipients.');
    }

    private static String normalizeTimeRange(String value) {
        String normalized = String.isBlank(value) ? 'ALL' : value.trim().toUpperCase();
        return new Set<String>{'ALL', 'TODAY', 'LAST_7', 'LAST_30', 'LAST_90'}.contains(normalized) ? normalized : 'ALL';
    }

    private static String communicationTimeRange(String requested) {
        String normalized = normalizeTimeRange(requested);
        if (String.isNotBlank(requested) && normalized != requested.trim().toUpperCase()) {
            throw handled('The selected date range is no longer valid. Refresh the panel before preparing recipients.');
        }
        return normalized;
    }

    private static String normalizeViewKey(String value) {
        String normalized = String.isBlank(value) ? 'INVOICE_REQUIRED' : value.trim().toUpperCase();
        Map<String, String> legacyViews = new Map<String, String>{
            'TOP_UP_INVOICE_REQUIRED' => 'INVOICE_REQUIRED',
            'TOP_UP_PAYMENT_DUE' => 'PAYMENT_DUE',
            'TOP_UP_PAYMENT_COMPLETE' => 'PAYMENT_COMPLETE'
        };
        if (legacyViews.containsKey(normalized)) normalized = legacyViews.get(normalized);
        Set<String> allowed = new Set<String>();
        allowed.addAll(OPPORTUNITY_VIEWS);
        allowed.addAll(LEAD_VIEWS);
        allowed.add('RECENT');
        return allowed.contains(normalized) ? normalized : 'INVOICE_REQUIRED';
    }

    private static String normalizeOwnerId(String value) {
        if (String.isBlank(value)) return null;
        try {
            Id parsed = (Id)value;
            Schema.SObjectType ownerType = parsed.getSObjectType();
            return ownerType == User.SObjectType || ownerType == Group.SObjectType ? String.valueOf(parsed) : null;
        } catch (Exception ignored) {
            return null;
        }
    }

    private static String normalizeReminderView(String value) {
        String normalized = String.isBlank(value) ? '' : value.trim().toUpperCase();
        if (!REMINDER_VIEWS.contains(normalized)) {
            throw handled('Remind All is available for logistics, staff and logo updates.');
        }
        return normalized;
    }

    private static List<Opportunity> reminderBookings(String eventCode, String timeRange, String ownerId, String viewKey) {
        String selectedEventCode = communicationEventCode(eventCode);
        String selectedOwnerId = normalizeOwnerId(ownerId);
        if (String.isNotBlank(ownerId) && selectedOwnerId == null) {
            throw handled('The selected owner is no longer valid. Refresh the panel before preparing recipients.');
        }
        Datetime selectedSinceAt = sinceAt(communicationTimeRange(timeRange));
        Map<String, Object> binds = baseBinds(selectedEventCode, selectedOwnerId, selectedSinceAt);
        String whereClause = opportunityBaseWhere(selectedEventCode, selectedOwnerId, selectedSinceAt)
            + opportunityViewClause(viewKey);
        return (List<Opportunity>)Database.queryWithBinds(
            'SELECT Id, Name, Account.Name, OwnerId, Booking_Reference__c, NTE_Source_Form_Type__c, '
            + 'NTE_Event_Contact_Name__c, NTE_Event_Contact_Email__c '
            + 'FROM Opportunity WHERE ' + whereClause + ' ORDER BY Account.Name, Name LIMIT 2000',
            binds,
            AccessLevel.USER_MODE
        );
    }

    private static Map<Id, Contact> primaryContactsByOpportunity(List<Opportunity> bookings) {
        Set<Id> bookingIds = new Set<Id>();
        for (Opportunity booking : bookings) {
            if (booking.Id != null) bookingIds.add(booking.Id);
        }
        return NTEBookingContactService.primaryContacts(bookingIds, AccessLevel.USER_MODE);
    }

    private static String reminderTitle(String viewKey) {
        if (viewKey == 'HEAVY_DUE') return 'Logistics reminders';
        if (viewKey == 'STAFF_DUE') return 'Staff update reminders';
        return 'Logo reminders';
    }

    private static String reminderSubject(String viewKey) {
        if (viewKey == 'HEAVY_DUE') return 'NTE logistics details reminder';
        if (viewKey == 'STAFF_DUE') return 'NTE staff details reminder';
        return 'NTE logo reminder';
    }

    private static String reminderBody(String viewKey) {
        String requestedDetails;
        if (viewKey == 'HEAVY_DUE') {
            requestedDetails = 'Please complete the outstanding logistics details for {Organisation}. Your booking reference is {BookingReference}.';
        } else if (viewKey == 'STAFF_DUE') {
            requestedDetails = 'Please provide the final staff details for {Organisation}. Your booking reference is {BookingReference}.';
        } else {
            requestedDetails = 'Please upload the latest logo for {Organisation}. Your booking reference is {BookingReference}.';
        }
        return 'Hello {ContactName},\n\n' + requestedDetails
            + '\n\n{UpdateLink}\n\nMany thanks,\nNTE team';
    }

    private static String reminderUrl(String viewKey, String sourceFormType, NTE_Routing_Config__mdt routing) {
        if (routing == null) return null;
        if (viewKey == 'HEAVY_DUE') return routing.Heavy_Vehicle_Form_URL__c;
        if (viewKey == 'LOGO_DUE') return routing.Logo_Update_Form_URL__c;
        return sourceFormType == 'Partner / Sponsor Application'
            ? routing.Partner_Staff_Form_URL__c
            : routing.Exhibitor_Staff_Form_URL__c;
    }

    private static String personaliseReminder(String templateBody, ReminderRecipient recipient) {
        Opportunity booking = recipient.booking;
        String contactName = recipient.primaryContact == null || String.isBlank(recipient.primaryContact.Name)
            ? 'there' : recipient.primaryContact.Name;
        String organisation = booking.Account == null || String.isBlank(booking.Account.Name)
            ? 'your organisation' : booking.Account.Name;
        String reference = String.isBlank(booking.Booking_Reference__c) ? 'not supplied' : booking.Booking_Reference__c;
        return templateBody
            .replace('{ContactName}', contactName)
            .replace('{Organisation}', organisation)
            .replace('{BookingReference}', reference)
            .replace('{UpdateLink}', recipient.updateUrl);
    }

    private static Task reminderAuditTask(ReminderRecipient recipient, String viewKey, String subject,
        Boolean sent, String errorMessage) {
        Opportunity booking = recipient.booking;
        Contact primaryContact = recipient.primaryContact;
        String category = viewKey == 'HEAVY_DUE' ? 'logistics'
            : (viewKey == 'STAFF_DUE' ? 'staff' : 'logo');
        String outcome = sent ? 'sent' : 'failed';
        String description = sent
            ? 'Reminder email sent to ' + primaryContact.Email + '.\nSubject: ' + subject
            : 'Reminder email could not be sent to ' + primaryContact.Email
                + '.\nSubject: ' + subject + '\nReason: ' + errorMessage;
        return new Task(
            Subject = 'NTE ' + category + ' reminder ' + outcome,
            WhatId = booking.Id,
            WhoId = primaryContact.Id,
            OwnerId = UserInfo.getUserId(),
            Status = closedTaskStatus(),
            Priority = 'Normal',
            ActivityDate = Date.today(),
            Description = description
        );
    }

    private static String closedTaskStatus() {
        if (String.isBlank(cachedClosedTaskStatus)) {
            cachedClosedTaskStatus = [
                SELECT MasterLabel
                FROM TaskStatus
                WHERE IsClosed = true
                ORDER BY SortOrder
                LIMIT 1
            ].MasterLabel;
        }
        return cachedClosedTaskStatus;
    }

    private static Datetime sinceAt(String timeRange) {
        if (timeRange == 'TODAY') return Datetime.newInstance(Date.today(), Time.newInstance(0, 0, 0, 0));
        if (timeRange == 'LAST_7') return System.now().addDays(-7);
        if (timeRange == 'LAST_30') return System.now().addDays(-30);
        if (timeRange == 'LAST_90') return System.now().addDays(-90);
        return null;
    }

    private static String safeMessage(Exception exceptionValue) {
        if (exceptionValue == null || String.isBlank(exceptionValue.getMessage())) return 'Please try again or contact your Salesforce administrator.';
        String message = exceptionValue.getMessage();
        return message.length() > 240 ? message.substring(0, 240) : message;
    }

    private static AuraHandledException handled(String message) {
        AuraHandledException failure = new AuraHandledException(message);
        failure.setMessage(message);
        return failure;
    }
}
