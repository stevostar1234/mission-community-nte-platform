import { LightningElement } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';
import LightningConfirm from 'lightning/confirm';
import NTE_LOGO from '@salesforce/resourceUrl/NTE_Management_Logo';
import getDashboard from '@salesforce/apex/NTE_MasterPanelController.getDashboard';
import getCommunicationRecordIds from '@salesforce/apex/NTE_MasterPanelController.getCommunicationRecordIds';
import buildDraft from '@salesforce/apex/NTEEmailDispatchService.buildDraft';
import previewMessageJson from '@salesforce/apex/NTEEmailDispatchService.previewMessageJson';
import queueMessagesJson from '@salesforce/apex/NTEEmailDispatchService.queueMessagesJson';
import updateLeadDecision from '@salesforce/apex/NTE_MasterPanelController.updateLeadDecision';
import updateMilestone from '@salesforce/apex/NTE_MasterPanelController.updateMilestone';

const PAGE_SIZE = 25;
const STAGE_CONFIGURATION = {
    interest: {
        combinedView: 'INTEREST',
        views: ['INTEREST', 'INTEREST_EXHIBITOR', 'INTEREST_PARTNER'],
        options: ['INTEREST_EXHIBITOR', 'INTEREST_PARTNER']
    },
    applications: {
        combinedView: 'APPLICATION_REVIEW',
        views: ['APPLICATION_REVIEW', 'APPLICATION_EXHIBITOR', 'APPLICATION_PARTNER'],
        options: ['APPLICATION_EXHIBITOR', 'APPLICATION_PARTNER']
    },
    approved: {
        combinedView: 'APPROVED',
        views: ['APPROVED', 'APPROVED_EXHIBITOR', 'APPROVED_PARTNER'],
        options: ['APPROVED_EXHIBITOR', 'APPROVED_PARTNER']
    },
    finance: {
        combinedView: 'FINANCE_DUE',
        views: ['FINANCE_DUE', 'QUOTE_REQUIRED', 'INVOICE_REQUIRED', 'PAYMENT_DUE', 'PAYMENT_COMPLETE'],
        options: ['QUOTE_REQUIRED', 'INVOICE_REQUIRED', 'PAYMENT_DUE', 'PAYMENT_COMPLETE']
    },
    readiness: {
        combinedView: 'READINESS_DUE',
        views: ['READINESS_DUE', 'HEAVY_DUE', 'STAFF_DUE', 'LOGO_DUE'],
        options: ['HEAVY_DUE', 'STAFF_DUE', 'LOGO_DUE']
    },
    complete: {
        combinedView: 'COMPLETED',
        views: ['COMPLETED', 'FINAL_PACK_DUE', 'FINAL_PACK_SENT'],
        options: ['FINAL_PACK_DUE', 'FINAL_PACK_SENT']
    }
};

export default class NteMasterPanel extends NavigationMixin(LightningElement) {
    logoUrl = NTE_LOGO;
    eventCode;
    timeRange = 'ALL';
    ownerId = '';
    viewKey = 'INTEREST';
    offsetRows = 0;
    response;
    rows = [];
    selectedRecordId;
    isLoading = true;
    isActionPending = false;
    errorMessage;
    requestSequence = 0;
    refreshTimer;
    conversionMonitor;
    communicationDraft;
    communicationSubject = '';
    communicationMessage = '';
    communicationRecipients = [];
    communicationRecordIds = [];
    isCommunicationModalOpen = false;
    isPreparingCommunication = false;
    isSendingCommunication = false;
    communicationError;
    previewRecipientId;
    communicationPreviewHtml = '';
    isPreviewLoading = false;
    previewReady = false;
    previewSequence = 0;
    previewTimer;
    communicationVersion = 0;
    communicationSequence = 0;
    communicationDraftFresh = false;
    modalReturnFocus;
    modalFocusTarget;
    modalTabBackwards = false;
    modalNeedsFocus = false;

    timeOptions = [
        { label: 'All time', value: 'ALL' },
        { label: 'Today', value: 'TODAY' },
        { label: 'Last 7 days', value: 'LAST_7' },
        { label: 'Last 30 days', value: 'LAST_30' },
        { label: 'Last 90 days', value: 'LAST_90' }
    ];

    connectedCallback() {
        window.addEventListener('focus', this.handleWindowFocus);
        document.addEventListener('visibilitychange', this.handleVisibilityChange);
        this.loadDashboard();
    }

    disconnectedCallback() {
        window.removeEventListener('focus', this.handleWindowFocus);
        document.removeEventListener('visibilitychange', this.handleVisibilityChange);
        window.clearTimeout(this.refreshTimer);
        window.clearInterval(this.conversionMonitor);
        window.clearTimeout(this.previewTimer);
        this.requestSequence++;
        this.communicationSequence++;
        this.previewSequence++;
        this.isPreparingCommunication = false;
        this.isSendingCommunication = false;
        this.isCommunicationModalOpen = false;
        this.communicationDraftFresh = false;
    }

    renderedCallback() {
        if (this.modalNeedsFocus) {
            this.modalNeedsFocus = false;
            this.template.querySelector('[data-modal-focus]')?.focus();
        }
    }

    handleWindowFocus = () => {
        this.scheduleLiveRefresh();
    };

    handleVisibilityChange = () => {
        if (document.visibilityState === 'visible') {
            this.scheduleLiveRefresh();
        }
    };

    scheduleLiveRefresh() {
        if (this.isActionPending || this.isCommunicationModalOpen || this.communicationBusy) return;
        window.clearTimeout(this.refreshTimer);
        this.refreshTimer = window.setTimeout(() => {
            this.refreshTimer = undefined;
            if (!this.isActionPending && !this.isCommunicationModalOpen && !this.communicationBusy) {
                this.loadDashboard({ preserveSelection: true });
            }
        }, 150);
    }

    get eventOptions() {
        return this.response?.eventOptions || [];
    }

    get ownerOptions() {
        return this.response?.ownerOptions || [{ label: 'All owners', value: '' }];
    }

    get guestBreakdown() {
        return this.buildBreakdownMetric('guests', 'pending', 'captured');
    }

    get interestBreakdown() {
        return this.buildBreakdownMetric('interest', 'open', 'decided');
    }

    get applicationBreakdown() {
        return this.buildBreakdownMetric('applications', 'awaiting review', 'approved');
    }

    get bookingBreakdown() {
        const metric = this.buildBreakdownMetric('approved', 'still in progress', 'fully complete');
        const completionPercent = metric.total === 0 ? 0 : Math.round((metric.completed / metric.total) * 100);
        return {
            ...metric,
            completionPercent,
            donutStyle: `--completion-angle: ${completionPercent * 3.6}deg;`,
            ariaLabel: `${metric.total} approved bookings: ${metric.completed} fully complete and ${metric.inProgress} still in progress`
        };
    }

    get quoteBreakdown() {
        return this.buildBreakdownMetric('quotes', 'outstanding', 'provided');
    }

    get invoiceBreakdown() {
        return this.buildBreakdownMetric('invoices', 'outstanding', 'provided');
    }

    get paymentBreakdown() {
        return this.buildBreakdownMetric('payments', 'outstanding', 'received');
    }

    get logisticsBreakdown() {
        return this.buildBreakdownMetric('heavy', 'outstanding', 'completed');
    }

    get staffBreakdown() {
        return this.buildBreakdownMetric('staff', 'outstanding', 'completed');
    }

    get logoBreakdown() {
        return this.buildBreakdownMetric('logos', 'outstanding', 'completed');
    }

    buildBreakdownMetric(key, inProgressLabel, completedLabel) {
        const source = (this.response?.overview || []).find((item) => item.key === key) || {};
        const total = Number(source.total) || 0;
        const inProgress = Number(source.inProgress) || 0;
        const completed = Number(source.completed) || 0;
        const percent = (value) => (total === 0 ? 0 : Math.max(0, Math.min(100, (value / total) * 100)));
        return {
            ...source,
            total,
            inProgress,
            completed,
            inProgressLabel,
            completedLabel,
            inProgressStyle: `width: ${percent(inProgress)}%;`,
            completedStyle: `width: ${percent(completed)}%;`,
            ariaLabel: `${source.label || key}: ${total} total, ${inProgress} ${inProgressLabel}, ${completed} ${completedLabel}`
        };
    }

    get pipeline() {
        const activeStage = this.activeStage;
        const completion = (this.response?.summary || []).find((metric) => metric.key === 'complete');
        return (this.response?.pipeline || []).map((item) => ({
            ...item,
            displayCount: item.key === 'complete' ? `${item.count} · ${completion?.displayValue || '0%'}` : item.count,
            pathClass: `slds-path__item ${item.key === activeStage ? 'slds-is-current slds-is-active' : 'slds-is-incomplete'}`,
            ariaPressed: item.key === activeStage ? 'true' : 'false'
        }));
    }

    get activeStage() {
        return Object.keys(STAGE_CONFIGURATION).find((key) => STAGE_CONFIGURATION[key].views.includes(this.viewKey)) || 'interest';
    }

    get stageOptions() {
        const queueByKey = new Map((this.response?.workQueues || []).map((queue) => [queue.key, queue]));
        return (STAGE_CONFIGURATION[this.activeStage]?.options || []).map((key) => {
            const queue = queueByKey.get(key) || { key, label: key, count: 0, icon: 'standard:record' };
            const active = key === this.viewKey;
            return {
                ...queue,
                cssClass: `stage-option${active ? ' stage-option-active' : ''}`,
                ariaPressed: active ? 'true' : 'false'
            };
        });
    }

    get hasStageOptions() {
        return this.stageOptions.length > 0;
    }

    get selectedQueue() {
        return this.response?.selectedView || {
            label: 'NTE records',
            detail: 'Records matching the selected filters'
        };
    }

    get isGuestView() {
        return this.viewKey === 'GUESTS';
    }

    get isInterestView() {
        return ['INTEREST', 'INTEREST_EXHIBITOR', 'INTEREST_PARTNER'].includes(this.viewKey);
    }

    get isApplicationView() {
        return ['APPLICATION_REVIEW', 'APPLICATION_EXHIBITOR', 'APPLICATION_PARTNER'].includes(this.viewKey);
    }

    get isFinanceView() {
        return STAGE_CONFIGURATION.finance.views.includes(this.viewKey);
    }

    get financeAmountLabel() {
        return 'Amount (ex VAT)';
    }

    get hasRowActions() {
        return this.rows.some((row) => row.showInterestDecision || row.showApplicationDecision
            || row.showMarkQuote || row.showMarkInvoice || row.showMarkPaid
            || row.showMarkTopUpInvoice || row.showMarkTopUpPaid);
    }

    get isApprovedView() {
        return ['APPROVED', 'APPROVED_EXHIBITOR', 'APPROVED_PARTNER'].includes(this.viewKey);
    }

    get isCompletedView() {
        return STAGE_CONFIGURATION.complete.views.includes(this.viewKey);
    }

    get isHeavyView() {
        return this.viewKey === 'HEAVY_DUE';
    }

    get isStaffView() {
        return this.viewKey === 'STAFF_DUE';
    }

    get isLogoView() {
        return this.viewKey === 'LOGO_DUE';
    }

    get isUpdatesView() {
        return this.viewKey === 'READINESS_DUE';
    }

    get isRecentView() {
        return this.viewKey === 'RECENT';
    }

    get actionColumnLabel() {
        return this.isInterestView ? 'Decision' : 'Action';
    }

    get canRemindAll() {
        return ['HEAVY_DUE', 'STAFF_DUE', 'LOGO_DUE'].includes(this.viewKey);
    }

    get canDistributeFinalPack() {
        return ['COMPLETED', 'FINAL_PACK_DUE'].includes(this.viewKey);
    }

    get communicationBusy() {
        return this.isPreparingCommunication || this.isSendingCommunication;
    }

    get panelControlsDisabled() {
        return this.isLoading || this.isActionPending || this.communicationBusy || this.isCommunicationModalOpen;
    }

    get visibleRows() {
        return this.rows.map((row) => ({
            ...row,
            actionDisabled: this.panelControlsDisabled,
            invitationActionDisabled: this.panelControlsDisabled || row.invitationActionDisabled
        }));
    }

    get visibleCommunicationRecipients() {
        return this.communicationRecipients.map((recipient) => ({ ...recipient, disabled: this.communicationBusy || !recipient.eligible }));
    }

    get selectedEmailRecipients() {
        return this.communicationRecipients.filter((recipient) => recipient.selected && recipient.eligible);
    }

    get selectedEmailRecipientCount() {
        return this.selectedEmailRecipients.length;
    }

    get availableRecipientCount() {
        return this.communicationRecipients.filter((recipient) => recipient.eligible).length;
    }

    get sendCommunicationDisabled() {
        return this.communicationBusy || !this.communicationDraftFresh || !this.communicationDraft?.canSend
            || this.selectedEmailRecipientCount === 0
            || this.selectedEmailRecipientCount > (this.communicationDraft?.recipientLimit || 500)
            || !(this.communicationSubject || '').trim() || !(this.communicationMessage || '').trim()
            || !this.previewReady || this.isPreviewLoading;
    }

    get sendCommunicationLabel() {
        return this.isSendingCommunication ? 'Queuing emails…' : `Send to ${this.selectedEmailRecipientCount}`;
    }

    get recipientOptions() {
        return this.selectedEmailRecipients.map((recipient) => ({
            label: [recipient.company, recipient.name].filter((value, index, values) => value && values.indexOf(value) === index).join(' · ') || 'Recipient',
            value: recipient.recordId
        }));
    }

    get hasSelectedEmailRecipients() {
        return this.selectedEmailRecipientCount > 0;
    }

    get tableClass() {
        return `data-table data-table-${this.viewKey.toLowerCase().replace(/_/g, '-')}`;
    }

    get selectedRecord() {
        return this.rows.find((row) => row.recordId === this.selectedRecordId);
    }

    get hasRows() {
        return this.rows.length > 0;
    }

    get hasPrevious() {
        return this.offsetRows > 0;
    }

    get hasNext() {
        return this.response?.hasNextPage ?? this.offsetRows + PAGE_SIZE < (this.response?.totalRows || 0);
    }

    get previousDisabled() {
        return this.panelControlsDisabled || !this.hasPrevious;
    }

    get nextDisabled() {
        return this.panelControlsDisabled || !this.hasNext;
    }

    get pageLabel() {
        const total = this.response?.totalRows || 0;
        if (!total) return '0 records';
        const start = this.offsetRows + 1;
        const end = Math.min(this.offsetRows + this.rows.length, total);
        return `${start}–${end} of ${total}${this.response?.rowsLimited ? ` · Latest ${this.response.accessibleRows.toLocaleString('en-GB')} available` : ''}`;
    }

    async loadDashboard({ preserveSelection = true } = {}) {
        if (this.isCommunicationModalOpen || this.communicationBusy) return;
        const requestId = ++this.requestSequence;
        this.isLoading = true;
        this.errorMessage = undefined;
        const previousSelection = preserveSelection ? this.selectedRecordId : undefined;
        try {
            const result = await getDashboard({
                eventCode: this.eventCode,
                timeRange: this.timeRange,
                ownerId: this.ownerId || null,
                viewKey: this.viewKey,
                pageSize: PAGE_SIZE,
                offsetRows: this.offsetRows
            });
            if (requestId !== this.requestSequence) return;
            this.response = result;
            this.eventCode = result.selectedEventCode;
            this.timeRange = result.selectedTimeRange;
            this.ownerId = result.selectedOwnerId || '';
            this.viewKey = result.selectedViewKey;
            this.offsetRows = result.offsetRows ?? this.offsetRows;
            this.rows = (result.rows || []).map((row) => this.decorateRow(row, previousSelection));
            this.selectedRecordId = this.rows.some((row) => row.recordId === previousSelection)
                ? previousSelection
                : this.rows[0]?.recordId;
            this.decorateRows();
        } catch (error) {
            if (requestId !== this.requestSequence) return;
            this.response = undefined;
            this.rows = [];
            this.selectedRecordId = undefined;
            this.errorMessage = this.readError(error);
        } finally {
            if (requestId === this.requestSequence) {
                this.isLoading = false;
            }
        }
    }

    decorateRow(row, selectedId) {
        const isGuest = row.sourceFormType === 'Guest Registration';
        const isInterest = (row.sourceFormType || '').includes('Expression of Interest');
        const isApplicationLead = row.objectApiName === 'Lead' && (row.sourceFormType || '').includes('Application');
        const isOpportunity = row.objectApiName === 'Opportunity';
        const scopedFinanceStatus = this.financeStatusForView(row);
        const showQuoteActions = ['FINANCE_DUE', 'QUOTE_REQUIRED'].includes(this.viewKey);
        const showInvoiceActions = ['FINANCE_DUE', 'INVOICE_REQUIRED'].includes(this.viewKey);
        const showPaymentActions = ['FINANCE_DUE', 'PAYMENT_DUE'].includes(this.viewKey);
        return {
            ...row,
            rowClass: `data-row${row.recordId === selectedId ? ' data-row-selected' : ''}`,
            selectAriaLabel: `Select ${row.typeLabel || 'record'} ${row.organisation || row.name || ''}`.trim(),
            financeClass: this.statusClass(row.financeStatus),
            scopedFinanceStatus,
            scopedFinanceClass: this.statusClass(scopedFinanceStatus),
            financeAmount: this.financeAmountForView(row),
            hasTopUpAmount: Number(row.topUpAmount) > 0,
            staffClass: this.statusClass(row.staffStatus),
            logisticsClass: this.statusClass(row.logisticsStatus),
            logoClass: this.statusClass(row.logoStatus),
            emailUrl: row.email ? `mailto:${row.email}` : null,
            phoneUrl: row.phone ? `tel:${row.phone.replace(/\s/g, '')}` : null,
            accompanyingGuestEmailUrl: row.accompanyingGuestEmail ? `mailto:${row.accompanyingGuestEmail}` : null,
            hasAccompanyingGuest: Boolean(row.accompanyingGuestName),
            hasEmail: Boolean(row.email),
            hasPhone: Boolean(row.phone),
            hasInterestAreas: Boolean(row.interestAreas),
            hasInterestDetail: Boolean(row.interestDetail),
            hasPackageOrSpace: Boolean(row.packageOrSpace),
            hasVehicleDetails: Boolean(row.vehicleType || row.vehicleRegistration || row.vehicleDimensions || row.haulierName),
            showMarkQuote: showQuoteActions && row.canMarkQuote,
            showMarkInvoice: showInvoiceActions && row.canMarkInvoice,
            showMarkPaid: showPaymentActions && row.canMarkPaid,
            showMarkTopUpInvoice: showInvoiceActions && row.canMarkTopUpInvoice,
            showMarkTopUpPaid: showPaymentActions && row.canMarkTopUpPaid,
            showInterestDecision: this.isInterestView && isInterest,
            showApplicationDecision: this.isApplicationView && isApplicationLead,
            isGuest,
            isInterest,
            isApplicationLead,
            isOpportunity,
            contactSectionLabel: isOpportunity ? 'Primary contact' : 'Contact',
            hasEventDayContact: isOpportunity && Boolean(row.eventDayContactName || row.eventDayContactEmail || row.eventDayContactPhone),
            eventDayEmailUrl: row.eventDayContactEmail ? `mailto:${row.eventDayContactEmail}` : null,
            eventDayPhoneUrl: row.eventDayContactPhone ? `tel:${row.eventDayContactPhone.replace(/\s/g, '')}` : null,
            invitationStatusDisplay: row.invitationStatus || 'Not sent',
            invitationClass: this.emailStatusClass(row.invitationStatus),
            invitationActionDisabled: ['Queued', 'Sent'].includes(row.invitationStatus),
            plannedStaffDisplay: row.plannedStaffCount || 'Not stated',
            additionalStaffDisplay: row.additionalStaffCount || 'None',
            accompanyingGuestDisplay: row.accompanyingGuestName || 'None',
            accompanyingGuestEmailDisplay: row.accompanyingGuestEmail || '—',
            interestTypeDisplay: row.interestType || row.typeLabel,
            interestAreasDisplay: row.interestAreas || 'Not stated',
            interestDetailDisplay: row.interestDetail || 'No additional detail',
            packageOrSpaceDisplay: row.packageOrSpace || 'Not stated',
            paymentMethodDisplay: row.paymentMethod || (row.invoiceRequired ? 'Not stated' : 'No payment required'),
            vehicleTypeDisplay: row.vehicleType || 'Not supplied',
            vehicleRegistrationDisplay: row.vehicleRegistration || 'Registration not supplied',
            vehicleDimensionsDisplay: row.vehicleDimensions || 'Dimensions not supplied',
            haulierNameDisplay: row.haulierName || 'Haulier not supplied',
            keyDetail: row.packageOrSpace || row.interestAreas || row.accompanyingGuestName || row.financeStatus || 'No additional detail',
            contactDisplay: row.email || row.phone || 'Not supplied'
        };
    }

    financeStatusForView(row) {
        if (row.pricingReviewRequired) return 'Check pricing';
        if (this.viewKey === 'QUOTE_REQUIRED') return 'Quote required';
        if (this.viewKey === 'INVOICE_REQUIRED') {
            return row.baseInvoiceRequired && !row.baseInvoiceProvided
                ? 'Booking invoice required' : 'Staff top-up invoice required';
        }
        if (this.viewKey === 'PAYMENT_DUE') {
            return row.baseInvoiceRequired && !row.basePaymentReceived
                ? 'Booking payment required' : 'Staff top-up payment required';
        }
        if (this.viewKey === 'PAYMENT_COMPLETE') return 'Payment confirmed';
        return row.financeStatus;
    }

    financeAmountForView(row) {
        if (this.viewKey === 'QUOTE_REQUIRED') return row.baseAmount;
        if (this.viewKey === 'INVOICE_REQUIRED') {
            return row.baseInvoiceRequired && !row.baseInvoiceProvided ? row.baseAmount : row.topUpAmount;
        }
        if (this.viewKey === 'PAYMENT_DUE') {
            return row.baseInvoiceRequired && !row.basePaymentReceived ? row.baseAmount : row.topUpAmount;
        }
        if (this.viewKey === 'FINANCE_DUE') {
            if (row.canMarkQuote || row.canMarkInvoice) return row.baseAmount;
            if (row.canMarkTopUpInvoice) return row.topUpAmount;
            if (row.canMarkPaid) return row.baseAmount;
            if (row.canMarkTopUpPaid) return row.topUpAmount;
        }
        return row.amount;
    }

    decorateRows() {
        this.rows = this.rows.map((row) => ({
            ...row,
            rowClass: `data-row${row.recordId === this.selectedRecordId ? ' data-row-selected' : ''}`,
            selectAriaLabel: row.selectAriaLabel
                || `Select ${row.typeLabel || 'record'} ${row.organisation || row.name || ''}`.trim()
        }));
    }

    leadConversionPageReference(leadId) {
        return {
            type: 'standard__component',
            attributes: {
                componentName: 'runtime_sales_lead__convertDesktopConsole'
            },
            state: {
                leadConvert__leadId: leadId
            }
        };
    }

    statusClass(value) {
        const normalized = (value || '').toLowerCase();
        if (normalized === 'complete' || normalized === 'provided' || normalized === 'paid' || normalized === 'payment confirmed' || normalized === 'not required' || normalized === 'not applicable') {
            return 'status-pill status-complete';
        }
        if (normalized === 'check pricing' || normalized.includes('required') || normalized.includes('due') || normalized.includes('confirmed')) {
            return 'status-pill status-due';
        }
        return 'status-pill status-neutral';
    }

    emailStatusClass(status) {
        if (status === 'Sent') return 'status-pill status-complete';
        if (status === 'Failed') return 'status-pill status-failed';
        if (['Pending', 'Queued'].includes(status)) return 'status-pill status-due';
        return 'status-pill status-neutral';
    }

    handleEventChange(event) {
        if (this.panelControlsDisabled) return;
        this.eventCode = event.detail.value;
        this.resetAndLoad();
    }

    handleTimeChange(event) {
        if (this.panelControlsDisabled) return;
        this.timeRange = event.detail.value;
        this.resetAndLoad();
    }

    handleOwnerChange(event) {
        if (this.panelControlsDisabled) return;
        this.ownerId = event.detail.value;
        this.resetAndLoad();
    }

    handleStageOptionSelect(event) {
        if (this.panelControlsDisabled) return;
        this.viewKey = event.currentTarget.dataset.view;
        this.resetAndLoad();
    }

    handlePipelineSelect(event) {
        event.preventDefault();
        if (this.panelControlsDisabled) return;
        const stageKey = event.currentTarget.dataset.stage;
        this.viewKey = STAGE_CONFIGURATION[stageKey]?.combinedView || event.currentTarget.dataset.view;
        this.resetAndLoad();
    }

    handleOverviewSelect(event) {
        if (this.panelControlsDisabled) return;
        this.viewKey = event.currentTarget.dataset.view;
        this.resetAndLoad();
    }

    handleSelectRow(event) {
        const nestedControl = event.currentTarget !== event.target
            && event.target.closest?.('a, button, input, select, textarea');
        if (nestedControl) return;
        this.selectRecord(event.currentTarget.dataset.id);
    }

    handleRowKeyDown(event) {
        if (event.key !== 'Enter' && event.key !== ' ') return;
        if (event.currentTarget !== event.target) return;
        event.preventDefault();
        this.selectRecord(event.currentTarget.dataset.id);
    }

    selectRecord(recordId) {
        if (this.panelControlsDisabled) return;
        this.selectedRecordId = recordId;
        this.decorateRows();
    }

    handlePrevious() {
        if (this.previousDisabled) return;
        this.offsetRows = Math.max(0, this.offsetRows - PAGE_SIZE);
        this.loadDashboard({ preserveSelection: false });
    }

    handleNext() {
        if (this.nextDisabled) return;
        this.offsetRows += PAGE_SIZE;
        this.loadDashboard({ preserveSelection: false });
    }

    handleRefresh() {
        if (this.panelControlsDisabled) return;
        this.loadDashboard();
    }

    async handleConvertLead(event) {
        event.preventDefault();
        event.stopPropagation();
        if (this.panelControlsDisabled) return;
        const leadId = event.currentTarget.dataset.id;
        if (!leadId) return;
        const conversionWindow = window.open('', '_blank');
        if (!conversionWindow) {
            this.dispatchEvent(new ShowToastEvent({
                title: 'Allow pop-ups to convert this application',
                message: 'Please allow pop-ups for Salesforce, then try Convert again.',
                variant: 'warning',
                mode: 'sticky'
            }));
            return;
        }
        this.isActionPending = true;
        try {
            const conversionUrl = await this[NavigationMixin.GenerateUrl](this.leadConversionPageReference(leadId));
            conversionWindow.location.href = conversionUrl;
            conversionWindow.focus();
            window.clearInterval(this.conversionMonitor);
            this.conversionMonitor = window.setInterval(() => {
                if (!conversionWindow.closed) return;
                window.clearInterval(this.conversionMonitor);
                this.conversionMonitor = undefined;
                this.scheduleLiveRefresh();
            }, 750);
        } catch (error) {
            conversionWindow.close();
            this.dispatchEvent(new ShowToastEvent({
                title: 'Conversion screen not opened',
                message: this.readError(error),
                variant: 'error',
                mode: 'sticky'
            }));
        } finally {
            this.isActionPending = false;
        }
    }

    async handleLeadDecision(event) {
        event.preventDefault();
        event.stopPropagation();
        if (this.panelControlsDisabled) return;
        const leadId = event.currentTarget.dataset.id;
        const decisionName = event.currentTarget.dataset.decision;
        const labels = {
            INTEREST_NOT_PROGRESSED: 'Reject interest',
            APPLICATION_REJECTED: 'Reject application'
        };
        const messages = {
            INTEREST_NOT_PROGRESSED: 'Reject this expression of interest and remove it from the current queue? The Lead will remain available in Salesforce.',
            APPLICATION_REJECTED: 'Mark this application as rejected and remove it from the current queue? The Lead will remain available in Salesforce.'
        };
        if (!leadId || !labels[decisionName]) return;
        this.isActionPending = true;
        try {
            const confirmed = await LightningConfirm.open({
                label: labels[decisionName],
                message: messages[decisionName],
                theme: 'error'
            });
            if (!confirmed) return;
            this.isLoading = true;
            const result = await updateLeadDecision({ leadId, decisionName });
            this.dispatchEvent(new ShowToastEvent({
                title: labels[decisionName],
                message: result.message,
                variant: 'success'
            }));
            await this.loadDashboard({ preserveSelection: false });
        } catch (error) {
            this.isLoading = false;
            this.dispatchEvent(new ShowToastEvent({
                title: 'Decision not saved',
                message: this.readError(error),
                variant: 'error',
                mode: 'sticky'
            }));
        } finally {
            this.isActionPending = false;
        }
    }

    handleOpenReminders(event) {
        this.openCommunication(this.viewKey, event);
    }

    handleOpenInvitations(event) {
        event.preventDefault();
        event.stopPropagation();
        this.openCommunication('INVITATION', event, event.currentTarget.dataset.id);
    }

    handleOpenFinalPack(event) {
        this.openCommunication('FINAL_PACK', event);
    }

    async openCommunication(kind, event, recordId) {
        if (this.panelControlsDisabled) return;
        const sequence = ++this.communicationSequence;
        this.requestSequence++;
        this.modalReturnFocus = event.currentTarget;
        this.isPreparingCommunication = true;
        this.isLoading = true;
        window.clearTimeout(this.refreshTimer);
        try {
            const recordIds = recordId ? [recordId] : await getCommunicationRecordIds({
                eventCode: this.eventCode,
                timeRange: this.timeRange,
                ownerId: this.ownerId || null,
                viewKey: this.viewKey
            });
            if (sequence !== this.communicationSequence) return;
            if (!recordIds.length) throw new Error('No records match the selected filters.');
            if (recordIds.length > 500) throw new Error('More than 500 records match this view. Narrow the event, time or owner filters before preparing emails.');
            const draft = await buildDraft({ kind, recordIds });
            if (sequence !== this.communicationSequence) return;
            this.communicationRecordIds = [...recordIds];
            this.applyCommunicationDraft(draft, true);
            this.isCommunicationModalOpen = true;
            this.modalNeedsFocus = true;
        } catch (error) {
            if (sequence !== this.communicationSequence) return;
            this.showEmailToast('Emails not prepared', this.readError(error), 'error');
        } finally {
            if (sequence === this.communicationSequence) {
                this.isPreparingCommunication = false;
                this.isLoading = false;
            }
        }
    }

    applyCommunicationDraft(draft, selectEligible, selectedIds) {
        this.communicationDraft = draft;
        this.communicationDraftFresh = true;
        this.communicationSubject = draft.subject || '';
        this.communicationMessage = draft.messageBody || '';
        this.communicationRecipients = (draft.recipients || []).map((recipient) => ({
            ...recipient,
            selected: Boolean(recipient.eligible && (selectedIds ? selectedIds.has(recipient.recordId) : selectEligible)),
            disabled: !recipient.eligible,
            selectionLabel: `Send to ${recipient.name || recipient.company || 'recipient'} at ${recipient.email || 'no email address'}`,
            displayName: recipient.name || 'Name not supplied',
            rowClass: `email-recipient${recipient.eligible ? '' : ' email-recipient-skipped'}`
        }));
        this.communicationError = undefined;
        this.previewRecipientId = this.selectedEmailRecipients[0]?.recordId;
        this.queueCommunicationPreview(0);
    }

    async handleRefreshCommunication() {
        if (this.communicationBusy || !this.isCommunicationModalOpen) return;
        const sequence = ++this.communicationSequence;
        this.isPreparingCommunication = true;
        this.communicationDraftFresh = false;
        this.invalidateCommunicationPreview();
        const selectedIds = new Set(this.selectedEmailRecipients.map((recipient) => recipient.recordId));
        const subject = this.communicationSubject;
        const messageBody = this.communicationMessage;
        try {
            const draft = await buildDraft({ kind: this.communicationDraft.kind, recordIds: this.communicationRecordIds });
            if (sequence !== this.communicationSequence) return;
            this.applyCommunicationDraft(draft, false, selectedIds);
            this.communicationSubject = subject;
            this.communicationMessage = messageBody;
            this.queueCommunicationPreview(0);
        } catch (error) {
            if (sequence !== this.communicationSequence) return;
            this.communicationError = this.readError(error);
        } finally {
            if (sequence === this.communicationSequence) this.isPreparingCommunication = false;
        }
    }

    handleCommunicationSubjectChange(event) {
        if (this.communicationBusy) return;
        this.communicationSubject = event.detail?.value ?? event.target.value;
        this.queueCommunicationPreview();
    }

    handleCommunicationMessageChange(event) {
        if (this.communicationBusy) return;
        this.communicationMessage = event.detail?.value ?? event.target.value;
        this.queueCommunicationPreview();
    }

    handleRecipientSelection(event) {
        if (this.communicationBusy) return;
        const recordId = event.currentTarget.dataset.id;
        const selected = event.target.checked;
        this.communicationRecipients = this.communicationRecipients.map((recipient) => ({
            ...recipient,
            selected: recipient.recordId === recordId ? Boolean(selected && recipient.eligible) : recipient.selected
        }));
        this.queueCommunicationPreview(0);
    }

    handleSelectEligibleRecipients() {
        if (this.communicationBusy) return;
        this.communicationRecipients = this.communicationRecipients.map((recipient) => ({ ...recipient, selected: Boolean(recipient.eligible) }));
        this.queueCommunicationPreview(0);
    }

    handleClearRecipients() {
        if (this.communicationBusy) return;
        this.communicationRecipients = this.communicationRecipients.map((recipient) => ({ ...recipient, selected: false }));
        this.queueCommunicationPreview(0);
    }

    handlePreviewRecipientChange(event) {
        if (this.communicationBusy) return;
        this.previewRecipientId = event.detail.value;
        this.queueCommunicationPreview(0);
    }

    communicationRequest() {
        return {
            kind: this.communicationDraft.kind,
            runId: this.communicationDraft.runId,
            subject: this.communicationSubject,
            messageBody: this.communicationMessage,
            recipients: this.selectedEmailRecipients.map(({ recordId, fingerprint }) => ({ recordId, fingerprint }))
        };
    }

    invalidateCommunicationPreview() {
        window.clearTimeout(this.previewTimer);
        this.previewSequence++;
        this.communicationVersion++;
        this.previewReady = false;
        this.communicationPreviewHtml = '';
        this.isPreviewLoading = false;
    }

    queueCommunicationPreview(delay = 300) {
        this.invalidateCommunicationPreview();
        if (!this.communicationDraftFresh) return;
        this.communicationError = undefined;
        if (!this.selectedEmailRecipients.some((recipient) => recipient.recordId === this.previewRecipientId)) {
            this.previewRecipientId = this.selectedEmailRecipients[0]?.recordId;
        }
        if (!this.previewRecipientId || !(this.communicationSubject || '').trim() || !(this.communicationMessage || '').trim()) return;
        this.isPreviewLoading = true;
        const sequence = this.previewSequence;
        this.previewTimer = window.setTimeout(() => this.renderCommunicationPreview(sequence), delay);
    }

    async renderCommunicationPreview(sequence) {
        if (sequence !== this.previewSequence || !this.isCommunicationModalOpen) return;
        try {
            const html = await previewMessageJson({ requestJson: JSON.stringify(this.communicationRequest()), recordId: this.previewRecipientId });
            if (sequence !== this.previewSequence || !this.isCommunicationModalOpen) return;
            // The Salesforce preview uses a trusted local image and its available column width.
            this.communicationPreviewHtml = (html || '')
                .replace('https://stevostar1234.github.io/nte27-web-to-lead-demo/assets/nte-logo-white.png', this.logoUrl)
                .replace('width:680px;max-width:680px;', 'width:100%;max-width:680px;');
            this.previewReady = Boolean(html);
        } catch (error) {
            if (sequence !== this.previewSequence || !this.isCommunicationModalOpen) return;
            this.communicationError = this.readError(error);
            this.previewReady = false;
        } finally {
            if (sequence === this.previewSequence) this.isPreviewLoading = false;
        }
    }

    handleCloseCommunication({ deferFocus = false } = {}) {
        if (this.communicationBusy) return;
        this.isCommunicationModalOpen = false;
        this.invalidateCommunicationPreview();
        this.communicationDraft = undefined;
        this.communicationDraftFresh = false;
        this.communicationSequence++;
        this.communicationRecipients = [];
        this.communicationRecordIds = [];
        this.communicationError = undefined;
        if (!deferFocus) this.restoreModalFocus();
    }

    async handleSendCommunication() {
        if (this.sendCommunicationDisabled) return;
        const request = this.communicationRequest();
        const version = this.communicationVersion;
        const sequence = this.communicationSequence;
        const count = request.recipients.length;
        this.isSendingCommunication = true;
        try {
            const confirmed = await LightningConfirm.open({
                label: 'Send emails',
                message: `Send this email to the ${count} ${count === 1 ? 'selected recipient' : 'selected recipients'}?`,
                theme: 'warning'
            });
            if (!confirmed || version !== this.communicationVersion || sequence !== this.communicationSequence || !this.previewReady) return;
            const result = JSON.parse(await queueMessagesJson({ requestJson: JSON.stringify(request) }));
            if (sequence !== this.communicationSequence) return;
            if (!result.queuedCount) {
                this.communicationDraftFresh = false;
                this.invalidateCommunicationPreview();
                this.communicationError = `${result.message} Refresh recipients to review their current status.`;
                this.showEmailToast('No emails queued', result.message, 'warning');
                return;
            }
            this.isSendingCommunication = false;
            this.handleCloseCommunication({ deferFocus: true });
            this.showEmailToast('Emails queued', result.message, result.skippedCount > 0 ? 'warning' : 'success');
            await this.loadDashboard({ preserveSelection: true });
            this.restoreModalFocus();
        } catch (error) {
            if (sequence !== this.communicationSequence) return;
            this.communicationError = this.readError(error);
            this.showEmailToast('Emails not queued', this.communicationError, 'error');
        } finally {
            if (sequence === this.communicationSequence) this.isSendingCommunication = false;
        }
    }

    showEmailToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant, mode: variant === 'error' ? 'sticky' : 'dismissible' }));
    }

    handleModalFocus(event) {
        this.modalFocusTarget = event.target;
    }

    handleModalKeyDown(event) {
        if (event.key === 'Escape') {
            event.preventDefault();
            if (this.isCommunicationModalOpen) this.handleCloseCommunication();
            return;
        }
        if (event.key !== 'Tab') return;
        this.modalTabBackwards = event.shiftKey;
        const controls = this.modalFocusableControls(event.currentTarget);
        if (!controls.length) return;
        const first = controls[0];
        const last = controls[controls.length - 1];
        const current = this.modalFocusTarget;
        if (event.shiftKey && current === first) {
            event.preventDefault();
            last.focus();
        } else if (!event.shiftKey && current === last) {
            event.preventDefault();
            first.focus();
        }
    }

    modalFocusableControls(dialog) {
        return [...dialog.querySelectorAll('button:not([disabled]), lightning-input:not([disabled]), lightning-textarea:not([disabled]), lightning-combobox:not([disabled]), a[href], [tabindex="0"]')]
            .filter((control) => !control.disabled && control.getClientRects().length > 0);
    }

    handleModalFocusOut(event) {
        if (!this.isCommunicationModalOpen || this.communicationBusy || !event.relatedTarget
            || event.currentTarget.contains(event.relatedTarget)) return;
        const controls = this.modalFocusableControls(event.currentTarget);
        (this.modalTabBackwards ? controls[controls.length - 1] : controls[0])?.focus();
    }

    restoreModalFocus() {
        const returnTarget = this.modalReturnFocus;
        this.modalReturnFocus = undefined;
        window.setTimeout(() => {
            if (returnTarget?.isConnected) returnTarget.focus();
            else this.template.querySelector('.header-actions lightning-button-icon')?.focus();
        }, 0);
    }

    resetAndLoad() {
        this.offsetRows = 0;
        this.loadDashboard({ preserveSelection: false });
    }

    async handleMilestone(event) {
        event.stopPropagation();
        if (this.panelControlsDisabled) return;
        const actionName = event.currentTarget.dataset.action;
        const opportunityId = event.currentTarget.dataset.id;
        const labels = {
            QUOTE_PROVIDED: 'Quote provided',
            INVOICE_PROVIDED: 'Booking invoice provided',
            PAYMENT_RECEIVED: 'Booking payment received',
            TOP_UP_INVOICE_PROVIDED: 'Staff top-up invoice provided',
            TOP_UP_PAYMENT_RECEIVED: 'Staff top-up payment received'
        };
        if (!opportunityId || !labels[actionName]) return;
        this.isActionPending = true;
        try {
            const confirmed = await LightningConfirm.open({
                label: labels[actionName],
                message: `Record “${labels[actionName]}” for this booking?`,
                theme: 'warning'
            });
            if (!confirmed) return;
            this.isLoading = true;
            const result = await updateMilestone({ opportunityId, actionName });
            this.dispatchEvent(new ShowToastEvent({
                title: labels[actionName],
                message: result.message,
                variant: 'success'
            }));
            this.selectedRecordId = opportunityId;
            await this.loadDashboard({ preserveSelection: true });
        } catch (error) {
            this.isLoading = false;
            this.dispatchEvent(new ShowToastEvent({
                title: 'Update not saved',
                message: this.readError(error),
                variant: 'error',
                mode: 'sticky'
            }));
        } finally {
            this.isActionPending = false;
        }
    }

    readError(error) {
        return error?.body?.message || error?.message || 'Something went wrong while loading the Master Panel.';
    }
}
