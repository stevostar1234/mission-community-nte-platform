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
import getPaymentReceiptPreview from '@salesforce/apex/NTE_MasterPanelController.getPaymentReceiptPreview';
import recordReviewedPayment from '@salesforce/apex/NTE_MasterPanelController.recordReviewedPayment';
import setRequirement from '@salesforce/apex/NTEFinanceService.setRequirement';
import setJoiningInstructions from '@salesforce/apex/NTEFinanceService.setJoiningInstructions';
import sendFinanceAction from '@salesforce/apex/NTEFinanceService.sendFinanceAction';

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
        views: ['FINANCE_DUE', 'REQUIREMENTS', 'PAYMENT_DUE', 'PAYMENT_COMPLETE'],
        options: ['REQUIREMENTS', 'PAYMENT_DUE', 'PAYMENT_COMPLETE']
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
    knownUpdateIssueCount;
    rows = [];
    selectedRecordId;
    isLoading = true;
    isActionPending = false;
    errorMessage;
    requestSequence = 0;
    refreshTimer;
    financeRefreshTimer;
    financePollsRemaining = 0;
    requirementPosition;
    isDisconnected = false;
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
    workbenchFocusView;

    timeOptions = [
        { label: 'All time', value: 'ALL' },
        { label: 'Today', value: 'TODAY' },
        { label: 'Last 7 days', value: 'LAST_7' },
        { label: 'Last 30 days', value: 'LAST_30' },
        { label: 'Last 90 days', value: 'LAST_90' }
    ];

    connectedCallback() {
        this.isDisconnected = false;
        window.addEventListener('focus', this.handleWindowFocus);
        document.addEventListener('visibilitychange', this.handleVisibilityChange);
        this.loadDashboard();
    }

    disconnectedCallback() {
        this.isDisconnected = true;
        this.requirementPosition = undefined;
        this.workbenchFocusView = undefined;
        window.removeEventListener('focus', this.handleWindowFocus);
        document.removeEventListener('visibilitychange', this.handleVisibilityChange);
        window.clearTimeout(this.refreshTimer);
        window.clearTimeout(this.financeRefreshTimer);
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
        if (this.workbenchFocusView && !this.panelControlsDisabled) {
            const requestedView = this.workbenchFocusView;
            this.workbenchFocusView = undefined;
            if (!this.isDisconnected && this.viewKey === requestedView) {
                const heading = this.template.querySelector('[data-workbench-heading]');
                heading?.focus({ preventScroll: true });
                heading?.scrollIntoView({ block: 'start' });
            }
        }
        if (this.requirementPosition && !this.panelControlsDisabled) {
            const position = this.requirementPosition;
            this.requirementPosition = undefined;
            const control = this.template.querySelector(`[data-id="${position.id}"][data-requirement="${position.requirement}"]`);
            if (!control || window.scrollX !== position.scrollX || window.scrollY !== position.scrollY) return;
            if (this.template.activeElement && this.template.activeElement !== control) return;
            if (document.activeElement !== position.activeElement && document.activeElement !== document.body) return;
            control.focus({ preventScroll: true });
            const top = control.getBoundingClientRect?.().top;
            if (Number.isFinite(position.top) && Number.isFinite(top) && top !== position.top) {
                window.scrollBy(0, top - position.top);
            }
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

    get requirementsBreakdown() {
        return this.buildBreakdownMetric('requirements', 'awaiting action', 'requested or confirmed');
    }

    get paymentBreakdown() {
        return this.buildBreakdownMetric('payments', 'outstanding', 'confirmed');
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

    get updateIssuesBreakdown() {
        const count = Math.max(0, Number(this.response?.updateIssueCount ?? this.knownUpdateIssueCount) || 0);
        return {
            count,
            countLabel: count === 1 ? 'issue' : 'issues',
            cssClass: `submission-metric update-issues-metric${count > 0 ? ' update-issues-metric-attention' : ''}`,
            fillStyle: `width: ${count > 0 ? 100 : 0}%;`,
            ariaLabel: `Update issues: ${count} ${count === 1 ? 'issue' : 'issues'} across all events, all time and all owners`,
            ariaPressed: this.isUpdateIssuesView ? 'true' : 'false'
        };
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
        return Object.keys(STAGE_CONFIGURATION).find((key) => STAGE_CONFIGURATION[key].views.includes(this.viewKey));
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
        return this.response?.selectedView || (this.isUpdateIssuesView
            ? { label: 'Update issues', detail: 'Across all events, dates and owners' }
            : { label: 'NTE records', detail: 'Records matching the selected filters' });
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

    get isRequirementsView() { return this.viewKey === 'REQUIREMENTS'; }

    get isUpdateIssuesView() { return this.viewKey === 'UPDATE_ISSUES'; }

    get workbenchClass() {
        if (this.isUpdateIssuesView) return 'workbench update-issues-workbench';
        return this.isRequirementsView ? 'workbench requirements-workbench' : 'workbench';
    }

    get showDetailPanel() { return !this.isRequirementsView && !this.isUpdateIssuesView; }

    get emptyQueueTitle() { return this.isUpdateIssuesView ? 'No update issues' : 'No records in this queue'; }

    get emptyQueueDetail() {
        return this.isUpdateIssuesView ? 'No update issues across any event, time or owner.'
            : 'Nothing matches the selected event, time and owner filters.';
    }

    get financeAmountLabel() {
        return 'Amount (inc VAT)';
    }

    get hasRowActions() {
        if (this.isUpdateIssuesView) return false;
        return this.isCompletedView || this.rows.some(row => row.showInterestDecision || row.showApplicationDecision || row.canSendBase || row.canSendTopUp || row.showMarkPaid || row.showMarkTopUpPaid || row.bookingEmailPending || row.topUpEmailPending || row.approvalEmailError || row.topUpEmailError);
    }

    get showOwnerColumn() { return !this.isFinanceView; }

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


    get communicationBusy() {
        return this.isPreparingCommunication || this.isSendingCommunication;
    }

    get panelControlsDisabled() {
        return this.isLoading || this.isActionPending || this.communicationBusy || this.isCommunicationModalOpen;
    }

    get filterControlsDisabled() {
        return this.panelControlsDisabled || this.isUpdateIssuesView;
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

    async loadDashboard({ preserveSelection = true, showRefreshWarning = true } = {}) {
        if (this.isDisconnected || this.isCommunicationModalOpen || this.communicationBusy) return false;
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
            if (requestId !== this.requestSequence) return false;
            this.response = result;
            if (result.updateIssueCount != null) this.knownUpdateIssueCount = result.updateIssueCount;
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
            window.clearTimeout(this.financeRefreshTimer);
            if (this.financePollsRemaining > 0 && this.rows.some(row => row.bookingEmailPending || row.topUpEmailPending)) {
                this.financePollsRemaining--;
                this.scheduleFinanceRefresh();
            }
            return true;
        } catch (error) {
            if (requestId !== this.requestSequence) return false;
            const samePage = this.response && this.rows.length
                && this.response.selectedEventCode === this.eventCode
                && this.response.selectedTimeRange === this.timeRange
                && (this.response.selectedOwnerId || '') === (this.ownerId || '')
                && this.response.selectedViewKey === this.viewKey
                && (this.response.offsetRows || 0) === this.offsetRows;
            if (samePage) {
                if (showRefreshWarning) this.dispatchEvent(new ShowToastEvent({title: 'Refresh failed', message: this.readError(error), variant: 'warning'}));
            } else {
                this.response = undefined;
                this.rows = [];
                this.selectedRecordId = undefined;
                this.errorMessage = this.readError(error);
            }
            return false;
        } finally {
            if (requestId === this.requestSequence) {
                this.isLoading = false;
            }
        }
    }

    scheduleFinanceRefresh() {
        this.financeRefreshTimer = window.setTimeout(() => {
            this.financeRefreshTimer = undefined;
            if (this.isDisconnected) return;
            if (this.isActionPending) this.scheduleFinanceRefresh();
            else this.loadDashboard({preserveSelection: true});
        }, 4000);
    }

    decorateRow(row, selectedId) {
        if (this.isUpdateIssuesView) return this.decorateUpdateIssueRow(row);
        const isGuest = row.sourceFormType === 'Guest Registration';
        const isInterest = (row.sourceFormType || '').includes('Expression of Interest');
        const isApplicationLead = row.objectApiName === 'Lead' && (row.sourceFormType || '').includes('Application');
        const isOpportunity = row.objectApiName === 'Opportunity';
        const scopedFinanceStatus = this.financeStatusForView(row);
        const showRequirementActions = isOpportunity && this.isRequirementsView;
        const showPaymentActions = isOpportunity && this.viewKey === 'PAYMENT_DUE' && !row.requirementsDue;
        const hasOutstandingTopUp = Number(row.topUpAmount) > 0 && !row.topUpPaymentReceived;
        const onlyTopUpPayable = hasOutstandingTopUp && (row.basePaymentReceived
            || (Number(row.baseAmount) === 0 && !row.pricingReviewRequired));
        const requirementPaymentMethod = onlyTopUpPayable ? 'Stripe'
            : row.baseAmount != null && Number(row.baseAmount) === 0 && !row.pricingReviewRequired
                ? 'No payment required'
                : hasOutstandingTopUp && row.paymentMethod === 'Bank transfer' ? 'Bank transfer; Stripe for staff top-up'
                    : row.paymentMethod;
        return {
            ...row,
            requirements: (row.requirements || []).map(requirement => ({
                ...requirement,
                detailIsLong: Boolean(requirement.detail && (requirement.detail.length > 280 || requirement.detail.split('\n').length > 4)),
                detailPreview: requirement.detail ? requirement.detail.slice(0, 180).trimEnd() + '…' : ''
            })),
            canSendBase: Boolean(row.canSendBase && showRequirementActions),
            canSendTopUp: Boolean(row.canSendTopUp && showRequirementActions),
            bookingEmailPending: row.approvalEmailStatus === 'Pending',
            approvalEmailError: row.basePaymentReceived ? null : row.approvalEmailError,
            topUpEmailPending: row.topUpEmailStatus === 'Queued',
            joiningSent: row.finalPackStatus === 'Sent',
            hasRequirements: Boolean(row.requirements?.length),
            requirementCardClass: row.requirements?.length ? 'requirement-card' : 'requirement-card requirement-card-compact',
            requirementBookingType: onlyTopUpPayable
                ? 'Staff top-up' : Number(row.baseAmount) === 0 && !row.pricingReviewRequired
                    ? 'Complimentary space' : row.sourceFormType === 'Partner / Sponsor Application'
                        ? (row.packageOrSpace || 'Partner / sponsor').replace(/;\s*/g, ' · ') : 'Exhibitor booking',
            requirementAmountLabel: onlyTopUpPayable
                ? 'Outstanding (inc VAT)' : 'Total (inc VAT)',
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
            showMarkQuote: false,
            showMarkInvoice: false,
            showMarkPaid: showPaymentActions && row.canMarkPaid,
            showMarkTopUpInvoice: false,
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
            paymentMethodDisplay: (this.isRequirementsView ? requirementPaymentMethod : row.paymentMethod)
                || (row.invoiceRequired ? 'Not stated' : 'No payment required'),
            vehicleTypeDisplay: row.vehicleType || 'Not supplied',
            vehicleRegistrationDisplay: row.vehicleRegistration || 'Registration not supplied',
            vehicleDimensionsDisplay: row.vehicleDimensions || 'Dimensions not supplied',
            haulierNameDisplay: row.haulierName || 'Haulier not supplied',
            keyDetail: row.packageOrSpace || row.interestAreas || row.accompanyingGuestName || row.financeStatus || 'No additional detail',
            contactDisplay: row.email || row.phone || 'Not supplied'
        };
    }

    decorateUpdateIssueRow(row) {
        const details = (row.updateDetails || []).filter(detail => detail.value != null && String(detail.value).trim() !== '')
            .map(detail => {
                const value = String(detail.value);
                return {
                    ...detail,
                    value,
                    detailIsLong: value.length > 280 || value.split('\n').length > 4,
                    detailPreview: value.slice(0, 180).trimEnd() + '…'
                };
            });
        return {
            ...row,
            organisation: row.organisation || 'Organisation not supplied',
            contactName: row.contactName || row.name || 'Not supplied',
            hasEmail: Boolean(row.email),
            emailUrl: row.email ? `mailto:${row.email}` : null,
            hasPhone: Boolean(row.phone),
            phoneUrl: row.phone ? `tel:${row.phone.replace(/\s/g, '')}` : null,
            updateReferenceDisplay: row.bookingReference || 'Not supplied',
            updateTypeDisplay: row.sourceFormType || 'Not supplied',
            updateEventDisplay: row.eventCode || 'Not supplied',
            updateStatusDisplay: row.updateStatus || 'Not recorded',
            updateDetails: details,
            hasUpdateDetails: details.length > 0
        };
    }

    financeStatusForView(row) {
        if (row.pricingReviewRequired) return 'Check pricing';
        if (this.viewKey === 'REQUIREMENTS') return 'Requirements';
        if (this.viewKey === 'PAYMENT_DUE') return 'Payment required';
        if (this.viewKey === 'PAYMENT_COMPLETE') return 'Payment confirmed';
        return row.financeStatus;
    }

    financeAmountForView(row) {
        if (this.viewKey === 'REQUIREMENTS') return (!row.basePaymentReceived ? Number(row.baseAmount) : 0)
            + (!row.topUpPaymentReceived ? Number(row.topUpAmount) : 0);
        if (this.viewKey === 'PAYMENT_DUE') return (row.canMarkPaid ? Number(row.baseAmount) : 0) + (row.canMarkTopUpPaid ? Number(row.topUpAmount) : 0);
        return row.amount;
    }

    handleControlClick(event) { event.stopPropagation(); }

    async handleRequirement(event) {
        event.stopPropagation();
        if (this.panelControlsDisabled) return;
        const {id, requirement} = event.currentTarget.dataset;
        const completed = event.target.checked;
        const previous = this.rows.find(row => row.recordId === id)?.requirements?.find(item => item.key === requirement)?.completed;
        this.requirementPosition = {
            id, requirement, top: event.currentTarget.getBoundingClientRect?.().top,
            scrollX: window.scrollX, scrollY: window.scrollY, activeElement: document.activeElement
        };
        this.isActionPending = true;
        this.updateRequirementValue(id, requirement, completed);
        try {
            await setRequirement({opportunityId: id, requirement, completed});
        } catch (error) {
            if (this.isDisconnected) return;
            this.updateRequirementValue(id, requirement, previous);
            event.target.checked = previous;
            const refreshed = await this.loadDashboard({preserveSelection: true, showRefreshWarning: false});
            if (this.isDisconnected) return;
            const savedValue = refreshed
                ? this.rows.find(row => row.recordId === id)?.requirements?.find(item => item.key === requirement)?.completed
                : undefined;
            if (typeof savedValue === 'boolean') {
                event.target.checked = savedValue;
                this.dispatchEvent(new ShowToastEvent(savedValue === completed
                    ? {title: 'Requirement saved', message: 'Your change is saved.', variant: 'success'}
                    : {title: 'Update not saved', message: this.readError(error), variant: 'error', mode: 'sticky'}));
            } else {
                this.dispatchEvent(new ShowToastEvent({title: 'Update could not be confirmed',
                    message: 'Refresh the record to check whether your change was saved.', variant: 'warning', mode: 'sticky'}));
            }
        } finally {
            this.isActionPending = false;
        }
    }
    updateRequirementValue(id, requirement, completed) {
        this.rows = this.rows.map(row => row.recordId === id ? {
            ...row,
            requirements: (row.requirements || []).map(item => item.key === requirement ? {...item, completed} : item)
        } : row);
    }
    async handleJoiningInstructions(event) {
        event.stopPropagation();
        const id = event.currentTarget.dataset.id;
        const completed = event.target.checked;
        const previous = this.rows.find(row => row.recordId === id)?.joiningSent;
        const outcome = await this.saveFinanceChange(id, () => setJoiningInstructions({opportunityId: id, completed}), {
            onSaved: () => {
                this.rows = this.rows.map(row => row.recordId === id ? {...row, joiningSent: completed} : row);
            },
            reconcileSaved: row => typeof row?.joiningSent === 'boolean' ? row.joiningSent === completed : undefined,
            savedMessage: 'The joining instructions marker is saved.'
        });
        if (this.isDisconnected) return;
        const current = this.rows.find(row => row.recordId === id)?.joiningSent;
        event.target.checked = outcome?.saved === true ? completed : typeof current === 'boolean' ? current : previous;
    }
    async handleFinanceAction(event) {
        event.stopPropagation();
        const {id, action} = event.currentTarget.dataset;
        await this.saveFinanceChange(id, async () => {
            const result = await sendFinanceAction({opportunityId: id, actionName: action});
            this.financePollsRemaining = result.queuedCount > 0 ? 15 : 0;
            if (!this.isDisconnected) this.dispatchEvent(new ShowToastEvent({title: result.queuedCount > 0 ? 'Email queued' : 'Email not queued', message: result.message, variant: result.queuedCount > 0 ? 'success' : 'error'}));
        }, {
            recoverPolling: true,
            reconcileSaved: row => {
                if (action === 'TOP_UP') return row?.topUpRequested || row?.topUpEmailPending ? true : undefined;
                return row?.bookingEmailPending ? true : undefined;
            },
            savedMessage: 'The payment email request is recorded. Check its current status.'
        });
    }
    async saveFinanceChange(id, save, {onSaved, reconcileSaved, savedMessage, recoverPolling = false} = {}) {
        if (this.panelControlsDisabled) return;
        this.isActionPending = true;
        try {
            await save();
            if (this.isDisconnected) return;
            onSaved?.();
            this.selectedRecordId = id;
            await this.loadDashboard({preserveSelection: true});
            return {saved: true};
        }
        catch (error) {
            if (this.isDisconnected) return;
            if (recoverPolling) this.financePollsRemaining = Math.max(this.financePollsRemaining, 15);
            const refreshed = await this.loadDashboard({preserveSelection: true, showRefreshWarning: false});
            if (this.isDisconnected) return;
            const saved = refreshed ? reconcileSaved?.(this.rows.find(row => row.recordId === id)) : undefined;
            this.dispatchEvent(new ShowToastEvent(saved === true
                ? {title: 'Update confirmed', message: savedMessage, variant: 'success'}
                : saved === false || error?.body?.message
                    ? {title: 'Update not saved', message: this.readError(error), variant: 'error', mode: 'sticky'}
                    : {title: 'Update could not be confirmed',
                        message: 'Check the full record before trying again. ' + this.readError(error), variant: 'warning', mode: 'sticky'}));
            return {saved};
        } finally { this.isActionPending = false; }
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
        if (this.filterControlsDisabled) return;
        this.eventCode = event.detail.value;
        this.resetAndLoad();
    }

    handleTimeChange(event) {
        if (this.filterControlsDisabled) return;
        this.timeRange = event.detail.value;
        this.resetAndLoad();
    }

    handleOwnerChange(event) {
        if (this.filterControlsDisabled) return;
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
        if (this.isUpdateIssuesView) this.workbenchFocusView = this.viewKey;
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
            if (this.isDisconnected) return;
            await this.loadDashboard({preserveSelection: true, showRefreshWarning: false});
            if (this.isDisconnected) return;
            this.dispatchEvent(new ShowToastEvent({
                title: 'Decision needs attention',
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
            const isPayment = actionName === 'PAYMENT_RECEIVED' || actionName === 'TOP_UP_PAYMENT_RECEIVED';
            let receipt;
            let message = `Record “${labels[actionName]}” for this booking?`;
            if (isPayment) {
                receipt = await getPaymentReceiptPreview({ opportunityId, actionName });
                const currency = new Intl.NumberFormat('en-GB', { style: 'currency', currency: 'GBP' });
                const charge = actionName === 'PAYMENT_RECEIVED' ? 'the booking' : 'the staff top-up';
                message = `Record ${currency.format(receipt.amount)} including VAT as received for ${charge}?`;
                if (receipt.stripeAmountDiffers) {
                    message += `\n\nIssued Stripe request: ${currency.format(receipt.issuedStripeAmount)} including VAT.`
                        + '\nOnly confirm once the full current amount has been received.';
                }
            }
            const confirmed = await LightningConfirm.open({
                label: labels[actionName],
                message,
                theme: 'warning'
            });
            if (!confirmed) return;
            this.isLoading = true;
            const result = isPayment
                ? await recordReviewedPayment({ opportunityId, actionName, expectedAmount: receipt.amount })
                : await updateMilestone({ opportunityId, actionName });
            this.dispatchEvent(new ShowToastEvent({
                title: labels[actionName],
                message: result.message,
                variant: 'success'
            }));
            this.selectedRecordId = opportunityId;
            await this.loadDashboard({ preserveSelection: true });
        } catch (error) {
            if (this.isDisconnected) return;
            await this.loadDashboard({preserveSelection: true, showRefreshWarning: false});
            if (this.isDisconnected) return;
            this.dispatchEvent(new ShowToastEvent({
                title: 'Update needs attention',
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
