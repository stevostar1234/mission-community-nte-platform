const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const vm = require('node:vm');

const projectRoot = path.resolve(__dirname, '..');
const sourceRoot = process.env.PANEL_UI_SOURCE_ROOT || projectRoot;

function deferred() {
    let resolve;
    let reject;
    const promise = new Promise((yes, no) => { resolve = yes; reject = no; });
    return { promise, resolve, reject };
}

function mount(name = 'nteMasterPanel', overrides = {}) {
    const timers = new Map();
    let nextTimer = 0;
    const events = [];
    const Base = class {
        template = { querySelector: () => null };
        dispatchEvent(event) { events.push(event); }
    };
    const NavigationMixin = (type) => type;
    NavigationMixin.GenerateUrl = Symbol('GenerateUrl');
    const context = vm.createContext({
        LightningElement: Base,
        NavigationMixin,
        ShowToastEvent: class { constructor(options) { Object.assign(this, options); } },
        LightningConfirm: { open: async () => true },
        NTE_LOGO: '/nte-logo.png',
        window: {
            addEventListener() {}, removeEventListener() {},
            setTimeout(callback) { const id = ++nextTimer; timers.set(id, callback); return id; },
            clearTimeout(id) { timers.delete(id); },
            setInterval(callback) { const id = ++nextTimer; timers.set(id, callback); return id; },
            clearInterval(id) { timers.delete(id); }
        },
        document: { addEventListener() {}, removeEventListener() {}, visibilityState: 'visible' },
        getDashboard: async () => dashboard(),
        getHomeDashboard: async () => ({}),
        getCommunicationRecordIds: async () => ['a', 'b'],
        buildDraft: async () => draft(),
        previewMessageJson: async () => '<p>Preview</p>',
        queueMessagesJson: async () => JSON.stringify({ queuedCount: 1, skippedCount: 0, message: '1 email queued.' }),
        updateLeadDecision: async () => ({ success: true, message: 'Decision saved.' }),
        updateMilestone: async () => ({ success: true, message: 'Milestone saved.' }),
        getPaymentReceiptPreview: async () => ({ amount: 960, issuedStripeAmount: null, stripeAmountDiffers: false }),
        recordReviewedPayment: async () => ({ success: true, message: 'Payment recorded.' }),
        retryBookingEmail: async () => ({ queuedCount: 1, message: 'Booking email queued.' }),
        retryFailedEmails: async () => ({ success: true, partialSuccess: false, message: 'Failed email notifications accepted by Salesforce.' }),
        retryDispatch: async () => ({ queuedCount: 1, message: 'Email queued.' }),
        notifyRecordUpdateAvailable: async () => {},
        ...overrides
    });
    const source = fs.readFileSync(path.join(sourceRoot, 'force-app/main/default/lwc', name, `${name}.js`), 'utf8');
    vm.runInContext(source.replace(/^import .*;\s*$/gm, '').replace(/@api\s*/g, '')
        .replace(/export default class (\w+)/, 'this.Component = class $1'), context);
    const component = new context.Component();
    component.isLoading = false;
    return {
        component, context, events, timers,
        async flushTimers() {
            const pending = [...timers.values()];
            timers.clear();
            await Promise.all(pending.map((callback) => callback()));
        }
    };
}

function dashboard(extra = {}) {
    return {
        selectedEventCode: 'NTE2027', selectedTimeRange: 'ALL', selectedOwnerId: '', selectedViewKey: 'INTEREST',
        rows: [{ recordId: 'a', organisation: 'Alder Engineering' }, { recordId: 'b', organisation: 'Beech Fabrication' }],
        offsetRows: 0, pageSize: 25, totalRows: 2, hasNextPage: false, ...extra
    };
}

function draft(extra = {}) {
    return {
        kind: 'INVITATION', runId: 'run-a', title: 'Send applications', subject: 'Your application',
        messageBody: 'Please apply.', canSend: true, recipientLimit: 500,
        recipients: [
            { recordId: 'a', name: 'Helen Marsh', company: 'Alder Engineering', email: 'helen@example.invalid', eligible: true, fingerprint: 'a-v1' },
            { recordId: 'b', name: 'Jamie Reed', company: 'Beech Fabrication', email: 'jamie@example.invalid', eligible: true, fingerprint: 'b-v1' },
            { recordId: 'c', name: 'Sam Wells', company: 'Cedar Marine', eligible: false, issue: 'No email address.' }
        ], ...extra
    };
}

function actionEvent(dataset) {
    return { currentTarget: { dataset }, preventDefault() {}, stopPropagation() {} };
}

function openReadyDraft(component) {
    component.isCommunicationModalOpen = true;
    component.communicationRecordIds = ['a', 'b', 'c'];
    component.applyCommunicationDraft(draft(), true);
    component.previewReady = true;
    component.isPreviewLoading = false;
}

test('latest dashboard wins and a late failed request cannot erase it', async () => {
    const first = deferred(); const second = deferred(); let calls = 0;
    const { component } = mount('nteMasterPanel', { getDashboard: () => (++calls === 1 ? first : second).promise });
    const oldRequest = component.loadDashboard();
    const latestRequest = component.loadDashboard();
    second.resolve(dashboard({ selectedEventCode: 'NTE2028' }));
    await latestRequest;
    first.reject(new Error('Outdated request failed'));
    await oldRequest;
    assert.equal(component.eventCode, 'NTE2028');
    assert.equal(component.rows.length, 2);
    assert.equal(component.errorMessage, undefined);
    assert.equal(component.isLoading, false);
});

test('repeated Next while loading does not skip pages', async () => {
    const response = deferred(); const offsets = [];
    const { component } = mount('nteMasterPanel', { getDashboard: (request) => { offsets.push(request.offsetRows); return response.promise; } });
    component.response = dashboard({ totalRows: 80, hasNextPage: true });
    component.handleNext(); component.handleNext();
    assert.deepEqual(offsets, [25]);
    assert.equal(component.nextDisabled, true);
    response.resolve(dashboard({ totalRows: 80, offsetRows: 25, hasNextPage: true }));
    await Promise.resolve();
    assert.equal(component.offsetRows, 25);
});

test('server accepted offset corrects a stale final page', async () => {
    const { component } = mount('nteMasterPanel', { getDashboard: async () => dashboard({ totalRows: 1, rows: [{ recordId: 'b' }], offsetRows: 0 }) });
    component.offsetRows = 25;
    await component.loadDashboard();
    assert.equal(component.offsetRows, 0);
    assert.equal(component.pageLabel, '1–1 of 1');
    assert.equal(component.previousDisabled, true);
});

test('capped pagination stops at accessible records and states its limit', async () => {
    const rows = Array.from({ length: 25 }, (_, index) => ({ recordId: `record-${index}` }));
    const { component } = mount('nteMasterPanel', { getDashboard: async () => dashboard({ rows, offsetRows: 1975, totalRows: 2501, accessibleRows: 2000, rowsLimited: true, hasNextPage: false }) });
    await component.loadDashboard();
    assert.equal(component.offsetRows, 1975);
    assert.equal(component.nextDisabled, true);
    assert.equal(component.pageLabel, '1976–2000 of 2501 · Latest 2,000 available');
});

test('window focus refresh retains the selected record when still present', async () => {
    const harness = mount();
    await harness.component.loadDashboard();
    harness.component.selectRecord('b');
    harness.component.scheduleLiveRefresh();
    await harness.flushTimers();
    assert.equal(harness.component.selectedRecordId, 'b');
});

test('a scheduled refresh cannot replace the panel while a draft opens', async () => {
    const pending = deferred(); let dashboardCalls = 0;
    const harness = mount('nteMasterPanel', { buildDraft: () => pending.promise, getDashboard: async () => { dashboardCalls++; return dashboard(); } });
    harness.component.scheduleLiveRefresh();
    const preparing = harness.component.openCommunication('INVITATION', actionEvent({}), 'a');
    harness.component.handleTimeChange({ detail: { value: 'TODAY' } });
    await harness.flushTimers();
    assert.equal(dashboardCalls, 0);
    assert.equal(harness.component.timeRange, 'ALL');
    pending.resolve(draft()); await preparing;
    assert.equal(harness.component.isCommunicationModalOpen, true);
});

for (const [method, dataset, endpoint] of [
    ['handleLeadDecision', { id: '00Qbooking', decision: 'APPLICATION_REJECTED' }, 'updateLeadDecision'],
    ['handleMilestone', { id: '006booking', action: 'PAYMENT_RECEIVED' }, 'recordReviewedPayment']
]) {
    test(`${method} locks before confirmation and submits once`, async () => {
        const confirmation = deferred(); let confirms = 0; let writes = 0;
        const { component } = mount('nteMasterPanel', {
            LightningConfirm: { open: () => { confirms++; return confirmation.promise; } },
            [endpoint]: async () => { writes++; return { success: true, message: 'Saved.' }; }
        });
        const first = component[method](actionEvent(dataset));
        const duplicate = component[method](actionEvent(dataset));
        await new Promise(setImmediate);
        assert.equal(confirms, 1); assert.equal(writes, 0); assert.equal(component.panelControlsDisabled, true);
        confirmation.resolve(true); await Promise.all([first, duplicate]);
        assert.equal(writes, 1); assert.equal(component.panelControlsDisabled, false);
    });

    test(`${method} cancel and failed confirmation leave no pending action`, async () => {
        let writes = 0;
        const { component, context, events } = mount('nteMasterPanel', {
            LightningConfirm: { open: async () => false },
            [endpoint]: async () => { writes++; return { message: 'Saved.' }; }
        });
        await component[method](actionEvent(dataset));
        assert.equal(writes, 0); assert.equal(component.panelControlsDisabled, false);
        context.LightningConfirm.open = async () => { throw new Error('Confirmation could not open'); };
        await component[method](actionEvent(dataset));
        assert.equal(writes, 0); assert.equal(component.panelControlsDisabled, false);
        assert.equal(events.at(-1).variant, 'error');
    });
}

for (const [action, label, charge, amount] of [
    ['PAYMENT_RECEIVED', 'Booking payment received', 'the booking', 960],
    ['TOP_UP_PAYMENT_RECEIVED', 'Staff top-up payment received', 'the staff top-up', 180.06]
]) {
    for (const [requestState, issuedStripeAmount] of [['no', null], ['matching', amount], ['different', 120]]) {
        test(`${label} reviews the fresh gross amount with ${requestState} issued Stripe request`, async () => {
            const reads = []; const writes = []; const dialogs = []; let legacyWrites = 0;
            const preview = { amount, issuedStripeAmount, stripeAmountDiffers: issuedStripeAmount !== null && issuedStripeAmount !== amount };
            const { component } = mount('nteMasterPanel', {
                getPaymentReceiptPreview: async (args) => { reads.push({ ...args }); return preview; },
                LightningConfirm: { open: async (args) => { dialogs.push({ ...args }); return true; } },
                recordReviewedPayment: async (args) => { writes.push({ ...args }); return { message: 'Payment recorded.' }; },
                updateMilestone: async () => { legacyWrites++; }
            });
            component.rows = [{ recordId: '006booking', amount: 9999, baseAmount: 8888, topUpAmount: 7777 }];
            component.selectedRecordId = '006booking';
            await component.handleMilestone(actionEvent({ id: '006booking', action }));
            assert.deepEqual(reads, [{ opportunityId: '006booking', actionName: action }]);
            assert.equal(dialogs[0].label, label);
            assert.equal(dialogs[0].theme, 'warning');
            const currentAmount = `£${amount.toFixed(2)}`;
            assert(dialogs[0].message.startsWith(`Record ${currentAmount} including VAT as received for ${charge}?`));
            assert.equal(dialogs[0].message.includes('Issued Stripe request:'), preview.stripeAmountDiffers);
            assert.equal(dialogs[0].message.includes('Only confirm once the full current amount has been received.'), preview.stripeAmountDiffers);
            if (preview.stripeAmountDiffers) assert(dialogs[0].message.includes('Issued Stripe request: £120.00 including VAT.'));
            assert.deepEqual(writes, [{ opportunityId: '006booking', actionName: action, expectedAmount: amount }]);
            assert.equal(legacyWrites, 0);
            assert.equal(component.panelControlsDisabled, false);
        });
    }

    test(`${label} cancellation leaves the issued request and payment untouched`, async () => {
        let reads = 0; let writes = 0;
        const { component } = mount('nteMasterPanel', {
            getPaymentReceiptPreview: async () => { reads++; return { amount, issuedStripeAmount: 120, stripeAmountDiffers: true }; },
            LightningConfirm: { open: async () => false },
            recordReviewedPayment: async () => { writes++; },
            updateMilestone: async () => { writes++; }
        });
        await component.handleMilestone(actionEvent({ id: '006booking', action }));
        assert.equal(reads, 1); assert.equal(writes, 0);
        assert.equal(component.panelControlsDisabled, false);
    });
}

test('receipt preview locks the row until fresh amounts arrive and never writes if the read fails', async () => {
    const preview = deferred(); let reads = 0; let dialogs = 0; let writes = 0;
    const { component, events } = mount('nteMasterPanel', {
        getPaymentReceiptPreview: () => { reads++; return preview.promise; },
        LightningConfirm: { open: async () => { dialogs++; return true; } },
        recordReviewedPayment: async () => { writes++; }
    });
    const first = component.handleMilestone(actionEvent({ id: '006booking', action: 'PAYMENT_RECEIVED' }));
    await component.handleMilestone(actionEvent({ id: '006booking', action: 'PAYMENT_RECEIVED' }));
    assert.equal(reads, 1); assert.equal(dialogs, 0); assert.equal(component.panelControlsDisabled, true);
    preview.reject(new Error('The payment amount could not be loaded.'));
    await first;
    assert.equal(dialogs, 0); assert.equal(writes, 0); assert.equal(component.panelControlsDisabled, false);
    assert.equal(events.at(-1).variant, 'error');
});

test('a changed current amount requires another review without an automatic receipt retry', async () => {
    let writes = 0; let reads = 0;
    const { component, events } = mount('nteMasterPanel', {
        getPaymentReceiptPreview: async () => { reads++; return { amount: 180, issuedStripeAmount: 120, stripeAmountDiffers: true }; },
        recordReviewedPayment: async ({ expectedAmount }) => {
            writes++; assert.equal(expectedAmount, 180);
            throw { body: { message: 'The payment amount has changed. Review the current amount before recording receipt.' } };
        }
    });
    await component.handleMilestone(actionEvent({ id: '006booking', action: 'TOP_UP_PAYMENT_RECEIVED' }));
    assert.equal(reads, 1); assert.equal(writes, 1); assert.equal(component.panelControlsDisabled, false);
    assert.equal(events.some((event) => event.variant === 'success'), false);
    assert.equal(events.at(-1).variant, 'error'); assert.equal(events.at(-1).mode, 'sticky');
    assert.match(events.at(-1).message, /payment amount has changed/);
});

test('invoice milestones retain the original confirmation and save API', async () => {
    let previews = 0; const writes = []; const dialogs = [];
    const { component } = mount('nteMasterPanel', {
        getPaymentReceiptPreview: async () => { previews++; },
        LightningConfirm: { open: async (args) => { dialogs.push({ ...args }); return true; } },
        updateMilestone: async (args) => { writes.push({ ...args }); return { message: 'Invoice provided.' }; },
        recordReviewedPayment: async () => { assert.fail('An invoice is not a payment receipt.'); }
    });
    await component.handleMilestone(actionEvent({ id: '006booking', action: 'INVOICE_PROVIDED' }));
    assert.equal(previews, 0);
    assert.equal(dialogs[0].message, 'Record “Booking invoice provided” for this booking?');
    assert.deepEqual(writes, [{ opportunityId: '006booking', actionName: 'INVOICE_PROVIDED' }]);
});

test('single invitation prepares only that row without sending', async () => {
    const builtIds = []; let sends = 0;
    const harness = mount('nteMasterPanel', {
        buildDraft: async ({ recordIds }) => { builtIds.push(...recordIds); return draft({ recipients: [draft().recipients[0]] }); },
        queueMessagesJson: async () => { sends++; }
    });
    await harness.component.openCommunication('INVITATION', actionEvent({}), 'a');
    await harness.flushTimers();
    assert.deepEqual(builtIds, ['a']);
    assert.equal(harness.component.selectedEmailRecipientCount, 1);
    assert.equal(harness.component.previewReady, true);
    assert.equal(sends, 0);
});

test('bulk draft selects eligible recipients only and Clear/Select all are accurate', () => {
    const { component } = mount(); openReadyDraft(component);
    assert.equal(component.selectedEmailRecipientCount, 2);
    assert.equal(component.availableRecipientCount, 2);
    component.handleClearRecipients(); assert.equal(component.selectedEmailRecipientCount, 0);
    assert.equal(component.sendCommunicationDisabled, true);
    component.handleSelectEligibleRecipients(); assert.equal(component.selectedEmailRecipientCount, 2);
    assert.equal(component.communicationRecipients[2].selected, false);
    assert.equal(component.recipientOptions.some((option) => option.label.includes('@')), false);
});

test('failed refresh cannot be bypassed by editing the old draft', async () => {
    const harness = mount('nteMasterPanel', { buildDraft: async () => { throw new Error('Recipient refresh unavailable'); } });
    openReadyDraft(harness.component);
    await harness.component.handleRefreshCommunication();
    harness.component.handleCommunicationSubjectChange({ detail: { value: 'Edited subject' } });
    await harness.flushTimers();
    assert.equal(harness.component.sendCommunicationDisabled, true);
    assert.equal(harness.component.previewReady, false);
    assert.equal(harness.component.communicationError, 'Recipient refresh unavailable');
});

test('successful refresh preserves edited text and reviewed subset with fresh fingerprints', async () => {
    const harness = mount('nteMasterPanel', {
        buildDraft: async () => draft({ runId: 'run-b', recipients: draft().recipients.map((item) => ({ ...item, fingerprint: `${item.recordId}-v2` })) })
    });
    openReadyDraft(harness.component);
    harness.component.communicationSubject = 'Personal subject'; harness.component.communicationMessage = 'Personal message';
    harness.component.handleRecipientSelection({ currentTarget: { dataset: { id: 'b' } }, target: { checked: false } });
    await harness.component.handleRefreshCommunication(); await harness.flushTimers();
    assert.equal(harness.component.communicationSubject, 'Personal subject');
    assert.equal(harness.component.communicationMessage, 'Personal message');
    assert.equal(harness.component.selectedEmailRecipientCount, 1);
    assert.equal(harness.component.selectedEmailRecipients[0].fingerprint, 'a-v2');
    assert.equal(harness.component.sendCommunicationDisabled, false);
});

test('late preview responses never replace the latest personalised preview', async () => {
    const oldPreview = deferred(); const newPreview = deferred(); let count = 0;
    const { component } = mount('nteMasterPanel', { previewMessageJson: () => (++count === 1 ? oldPreview : newPreview).promise });
    openReadyDraft(component);
    const first = component.renderCommunicationPreview(component.previewSequence);
    component.handlePreviewRecipientChange({ detail: { value: 'b' } });
    const second = component.renderCommunicationPreview(component.previewSequence);
    newPreview.resolve('<p>Beech Fabrication</p>'); await second;
    oldPreview.resolve('<p>Alder Engineering</p>'); await first;
    assert.equal(component.communicationPreviewHtml, '<p>Beech Fabrication</p>');
    assert.equal(component.previewRecipientId, 'b');
    assert.equal(component.previewReady, true);
});

test('send confirmation freezes the exact reviewed selection and text', async () => {
    const confirmation = deferred(); let prompts = 0; const requests = [];
    const { component } = mount('nteMasterPanel', {
        LightningConfirm: { open: () => { prompts++; return confirmation.promise; } },
        queueMessagesJson: async ({ requestJson }) => { requests.push(JSON.parse(requestJson)); return JSON.stringify({ queuedCount: 2, skippedCount: 0, message: '2 emails queued.' }); }
    });
    openReadyDraft(component);
    const originalVersion = component.communicationVersion;
    const sending = component.handleSendCommunication();
    component.handleClearRecipients();
    component.handleCommunicationSubjectChange({ detail: { value: 'Unreviewed subject' } });
    await component.handleSendCommunication();
    assert.equal(component.communicationVersion, originalVersion);
    assert.equal(component.communicationSubject, 'Your application');
    assert.equal(component.selectedEmailRecipientCount, 2);
    assert.equal(prompts, 1);
    confirmation.resolve(true); await sending;
    assert.equal(requests.length, 1);
    assert.equal(requests[0].subject, 'Your application');
    assert.equal(requests[0].recipients.length, 2);
});

test('zero queued keeps the draft open and requires refreshed recipients', async () => {
    const { component, events } = mount('nteMasterPanel', { queueMessagesJson: async () => JSON.stringify({ queuedCount: 0, skippedCount: 2, message: '0 emails queued. 2 skipped.' }) });
    openReadyDraft(component); await component.handleSendCommunication();
    assert.equal(component.isCommunicationModalOpen, true);
    assert.equal(component.sendCommunicationDisabled, true);
    assert.equal(events.at(-1).title, 'No emails queued');
    assert.match(component.communicationError, /Refresh recipients/);
});

test('cancelled send preserves the draft and never reaches the queue endpoint', async () => {
    let writes = 0;
    const { component } = mount('nteMasterPanel', { LightningConfirm: { open: async () => false }, queueMessagesJson: async () => { writes++; } });
    openReadyDraft(component); await component.handleSendCommunication();
    assert.equal(writes, 0); assert.equal(component.isSendingCommunication, false);
    assert.equal(component.isCommunicationModalOpen, true); assert.equal(component.sendCommunicationDisabled, false);
});

test('unreviewed or blank email drafts cannot send', async () => {
    let prompts = 0;
    const { component } = mount('nteMasterPanel', { LightningConfirm: { open: async () => { prompts++; return true; } } });
    openReadyDraft(component); component.previewReady = false; await component.handleSendCommunication();
    component.previewReady = true; component.communicationSubject = ' '; await component.handleSendCommunication();
    component.communicationSubject = 'Your application'; component.communicationMessage = ''; await component.handleSendCommunication();
    assert.equal(prompts, 0);
});

test('closing the composer invalidates an in-flight preview', async () => {
    const preview = deferred(); const { component } = mount('nteMasterPanel', { previewMessageJson: () => preview.promise });
    openReadyDraft(component);
    const rendering = component.renderCommunicationPreview(component.previewSequence);
    component.handleCloseCommunication(); preview.resolve('<p>Late preview</p>'); await rendering;
    assert.equal(component.communicationPreviewHtml, ''); assert.equal(component.previewReady, false);
});

test('focus escaping a nested preview link returns to the dialog without trapping confirmation', () => {
    const { component } = mount(); openReadyDraft(component); let focused = 0;
    const control = { disabled: false, getClientRects: () => [{}], focus: () => { focused++; } };
    const dialog = { querySelectorAll: () => [control], contains: () => false };
    component.handleModalFocusOut({ currentTarget: dialog, relatedTarget: {} });
    assert.equal(focused, 1);
    component.isSendingCommunication = true;
    component.handleModalFocusOut({ currentTarget: dialog, relatedTarget: {} });
    assert.equal(focused, 1);
});

test('finance refiners distinguish released charges from requirements', () => {
    const { component } = mount();
    const unpaid = { baseAmount: 800, topUpAmount: 50, amount: 850, baseInvoiceRequired: true, basePaymentReceived: false, topUpPaymentReceived: false, approvalEmailSentAt: '2026-09-13T12:00:00Z', canMarkPaid: true, topUpRequested: false };
    component.viewKey = 'PAYMENT_DUE';
    assert.equal(component.financeAmountForView(unpaid), 800);
    assert.equal(component.financeStatusForView(unpaid), 'Payment required');
    component.viewKey = 'REQUIREMENTS';
    assert.equal(component.financeAmountForView(unpaid), 850);
    component.viewKey = 'PAYMENT_DUE';
    assert.equal(component.financeAmountForView({ ...unpaid, basePaymentReceived: true, canMarkPaid: false, topUpRequested: true, canMarkTopUpPaid: true }), 50);
});

test('Home labels approvals correctly and maps backend uppercase metric keys', () => {
    const { component } = mount('nteManagementHome');
    component.applyDashboard({ headlines: [{ key: 'CONFIRMED_APPLICATIONS', count: 3, value: 2400 }] });
    const approved = component.headlineMetrics.find((metric) => metric.key === 'confirmedApplications');
    assert.equal(approved.label, 'Approved applications'); assert.equal(approved.formattedValue, '£2,400');
    assert.equal(approved.recordText, '3 records');
});

test('Home ignores a response delivered after disconnect', async () => {
    const result = deferred(); const { component } = mount('nteManagementHome', { getHomeDashboard: () => result.promise });
    const loading = component.loadDashboard(); component.disconnectedCallback();
    result.resolve({ selectedEventCode: 'NTE2028', headlines: [] }); await loading;
    assert.equal(component.hasDashboard, false); assert.equal(component.selectedEventCode, '');
});

test('retry reports an enqueue failure returned by the booking service', async () => {
    const { component, events } = mount('nteRetryEmail', { retryBookingEmail: async () => ({ queuedCount: 0, message: 'The email could not be queued. Check the booking email status.' }) });
    component.recordId = '006booking'; await component.invoke();
    assert.equal(events[0].title, 'Email needs attention'); assert.equal(events[0].variant, 'warning');
    assert.match(events[0].message, /could not be queued/);
});

test('a record refresh failure does not misreport an accepted retry as a failed email', async () => {
    const { component, events } = mount('nteRetryEmail', { notifyRecordUpdateAvailable: async () => { throw new Error('Refresh failed'); } });
    component.recordId = '006booking'; await component.invoke();
    assert.equal(events.length, 1); assert.equal(events[0].title, 'Email queued'); assert.equal(events[0].variant, 'warning');
    assert.match(events[0].message, /Refresh the page/); assert.equal(component.running, false);
});

test('retry refreshes the invoked record and suppresses concurrent invocations', async () => {
    const retry = deferred(); let calls = 0; const refreshed = [];
    const { component } = mount('nteRetryEmail', {
        retryDispatch: () => { calls++; return retry.promise; },
        notifyRecordUpdateAvailable: async (records) => { refreshed.push(records[0].recordId); }
    });
    component.recordId = 'a0Ddispatch'; const pending = component.invoke();
    component.recordId = 'a0Dother'; await component.invoke();
    retry.resolve({ queuedCount: 1, message: 'Email queued.' }); await pending;
    assert.equal(calls, 1); assert.deepEqual(refreshed, ['a0Ddispatch']);
});

for (const [recordId, endpoint, parameter, expectedTitle] of [
    ['006booking','retryBookingEmail','opportunityId','Email queued'],
    ['00Qsubmission','retryFailedEmails','leadId','Email processed'],
    ['a0Ddispatch','retryDispatch','dispatchId','Email queued']
]) {
    test(`retry routes ${recordId} only through its appropriate gateway and refreshes that record`, async () => {
        const calls = []; const refreshed = [];
        const {component,events} = mount('nteRetryEmail', {
            retryBookingEmail: async args => { calls.push(['retryBookingEmail',{...args}]); return {queuedCount:1,message:'Booking confirmation queued.'}; },
            retryFailedEmails: async args => { calls.push(['retryFailedEmails',{...args}]); return {success:true,partialSuccess:false,message:'Failed notifications accepted.',applicantStatus:'Not required',internalStatus:'Accepted by Salesforce'}; },
            retryDispatch: async args => { calls.push(['retryDispatch',{...args}]); return {queuedCount:1,message:'The selected dispatch was queued.'}; },
            notifyRecordUpdateAvailable: async records => { refreshed.push(records[0].recordId); }
        });
        component.recordId = recordId;
        await component.invoke();
        assert.deepEqual(calls,[[endpoint,{[parameter]:recordId}]]);
        assert.deepEqual(refreshed,[recordId]);
        assert.equal(events.length,1); assert.equal(events[0].title,expectedTitle);
        assert.equal(events[0].variant,'success'); assert.equal(component.running,false);
    });
}

for (const [applicantStatus,internalStatus,message] of [
    ['Failed','Accepted by Salesforce','Internal notification accepted. The applicant address still needs attention.'],
    ['Accepted by Salesforce','Failed','Applicant notification accepted. The internal recipient still needs attention.']
]) {
    test(`a partly recovered Lead retry retains its ${applicantStatus === 'Failed' ? 'applicant' : 'internal'} failure warning`, async () => {
        let calls = 0; const refreshed = [];
        const {component,events} = mount('nteRetryEmail', {
            retryFailedEmails: async ({leadId}) => {
                calls++; assert.equal(leadId,'00Qsubmission');
                return {success:false,partialSuccess:true,message,applicantStatus,internalStatus};
            },
            notifyRecordUpdateAvailable: async records => { refreshed.push(records[0].recordId); }
        });
        component.recordId = '00Qsubmission';
        await component.invoke();
        assert.equal(calls,1); assert.deepEqual(refreshed,['00Qsubmission']);
        assert.equal(events.length,1); assert.equal(events[0].title,'Email needs attention');
        assert.equal(events[0].variant,'warning'); assert.equal(events[0].message,message);
        assert.equal(component.running,false);
    });
}

test('a fully failed Lead retry is not presented as accepted or retried automatically', async () => {
    let calls = 0;
    const {component,events} = mount('nteRetryEmail', {
        retryFailedEmails: async () => {
            calls++;
            return {success:false,partialSuccess:false,message:'Check both notification recipients.',applicantStatus:'Failed',internalStatus:'Failed'};
        }
    });
    component.recordId = '00Qsubmission'; await component.invoke();
    assert.equal(calls,1); assert.equal(events.length,1);
    assert.equal(events[0].title,'Email needs attention'); assert.equal(events[0].variant,'warning');
    assert.equal(events[0].message,'Check both notification recipients.'); assert.equal(component.running,false);
});

test('a Lead gateway failure preserves the actionable error and releases the retry lock', async () => {
    let calls = 0; let refreshes = 0;
    const {component,events} = mount('nteRetryEmail', {
        retryFailedEmails: async () => { calls++; throw {body:{message:'There are no failed emails to retry. Previously accepted emails will not be resent.'}}; },
        notifyRecordUpdateAvailable: async () => { refreshes++; }
    });
    component.recordId = '00Qsubmission'; await component.invoke();
    assert.equal(calls,1); assert.equal(refreshes,0); assert.equal(component.running,false);
    assert.equal(events.length,1); assert.equal(events[0].variant,'error');
    assert.match(events[0].message,/Previously accepted emails will not be resent/);
});

test('pipeline stages use native button keyboard semantics and mobile Home has three controls', () => {
    const panelHtml = fs.readFileSync(path.join(sourceRoot, 'force-app/main/default/lwc/nteMasterPanel/nteMasterPanel.html'), 'utf8');
    const homeCss = fs.readFileSync(path.join(sourceRoot, 'force-app/main/default/lwc/nteManagementHome/nteManagementHome.css'), 'utf8');
    assert.match(panelHtml, /<button\s+type="button"\s+class="slds-path__link pipeline-path-link"/);
    assert.doesNotMatch(panelHtml, /role="listbox"/);
    assert.match(homeCss, /@media \(max-width: 32rem\)\s*\{[\s\S]*?\.control-divider \{ display: none; \}/);
});

test('a conversion return can refresh an older dashboard request still in flight', async () => {
    const earlier = deferred(); let calls = 0;
    const harness = mount('nteMasterPanel', { getDashboard: () => ++calls === 1 ? earlier.promise : Promise.resolve(dashboard({ rows: [{ recordId: 'booking' }], totalRows: 1 })) });
    const oldRequest = harness.component.loadDashboard();
    harness.component.scheduleLiveRefresh(); await harness.flushTimers();
    earlier.resolve(dashboard()); await oldRequest;
    assert.equal(calls, 2); assert.equal(harness.component.rows[0].recordId, 'booking');
});

test('successful send restores focus after refreshed controls become available', async () => {
    const dashboardResult = deferred(); const focusStates = [];
    const harness = mount('nteMasterPanel', { getDashboard: () => dashboardResult.promise });
    openReadyDraft(harness.component);
    harness.component.modalReturnFocus = { isConnected: true, focus: () => { focusStates.push(harness.component.panelControlsDisabled); } };
    const sending = harness.component.handleSendCommunication();
    await Promise.resolve(); await Promise.resolve(); await harness.flushTimers();
    assert.equal(focusStates.length, 0);
    dashboardResult.resolve(dashboard()); await sending; await harness.flushTimers();
    assert.deepEqual(focusStates, [false]);
});

test('combined Updates exposes the missing logo status in its own table column', () => {
    const panelHtml = fs.readFileSync(path.join(sourceRoot, 'force-app/main/default/lwc/nteMasterPanel/nteMasterPanel.html'), 'utf8');
    const updatesSections = [...panelHtml.matchAll(/<template lwc:elseif=\{isUpdatesView\}>([\s\S]*?)<\/template>/g)].map((match) => match[1]);
    assert.equal(updatesSections.length, 2);
    assert.match(updatesSections[0], /<th[^>]+>Logo<\/th>/);
    assert.match(updatesSections[1], /class=\{row.logoClass\}>\{row.logoStatus\}/);
    const { component } = mount(); component.viewKey = 'READINESS_DUE';
    const row = component.decorateRow({ recordId: 'a', objectApiName: 'Opportunity', staffStatus: 'Complete', logisticsStatus: 'Not required', logoStatus: 'Update required' });
    assert.equal(row.logoClass, 'status-pill status-due');
    assert.equal(row.staffClass, 'status-pill status-complete');
});

test('Home readiness fallback uses the same three labels as finance refiners', () => {
    const { component } = mount('nteManagementHome');
    const labels = component.normalizeReadiness({}).map((item) => item.label);
    assert.equal(JSON.stringify(labels), JSON.stringify(['Requirements', 'Payment required', 'Payment confirmed']));
    assert.equal(component.normalizeHeadline([]).at(-1).label, 'Paid');
});

test('finance send leaves checklist values untouched and reports rejected queue truthfully', async () => {
    const writes = [];
    const row = { recordId: 'booking', objectApiName: 'Opportunity', canSendBase: true, requirements: [{ key: 'NTE_Invoice_Provided__c', completed: false }] };
    const { component, events } = mount('nteMasterPanel', {
        sendFinanceAction: async args => { writes.push(args); return { queuedCount: 0, message: 'The primary Contact needs an email address.' }; },
        setRequirement: async () => { throw new Error('Sending must never tick a requirement'); },
        getDashboard: async () => dashboard({ rows: [row], selectedViewKey: 'REQUIREMENTS' })
    });
    component.viewKey = 'REQUIREMENTS'; component.rows = [row];
    await component.handleFinanceAction(actionEvent({ id: 'booking', action: 'BANK' }));
    assert.equal(writes.length, 1); assert.equal(writes[0].actionName, 'BANK');
    assert.equal(component.rows[0].requirements[0].completed, false);
    assert.equal(events.at(-1).variant, 'error'); assert.equal(component.financePollsRemaining, 0);
});

test('checklist changes persist independently and joining instructions use no email endpoint', async () => {
    const calls = [];
    const { component } = mount('nteMasterPanel', {
        setRequirement: async args => calls.push(['requirement', args]),
        setJoiningInstructions: async args => calls.push(['joining', args]),
        sendFinanceAction: async () => { throw new Error('A checkbox must never send an email'); }
    });
    const check = actionEvent({ id: 'booking', requirement: 'NTE_PO_Confirmed__c' }); check.target = { checked: true };
    await component.handleRequirement(check);
    await component.handleJoiningInstructions(check);
    assert.equal(calls.length, 2); assert.equal(calls[0][1].completed, true); assert.equal(calls[0][1].requirement, 'NTE_PO_Confirmed__c');
    assert.equal(calls[1][0], 'joining'); assert.equal(calls[1][1].completed, true);
});

test('a Requirements checkbox saves in place on page two without reloading or disturbing other ticks', async () => {
    const saving = deferred(); let reads = 0; let writes = 0;
    const rows = Array.from({length: 25}, (_,index) => ({recordId: `booking-${index + 26}`, objectApiName: 'Opportunity',
        requirements: [{key: 'NTE_Invoice_Provided__c', completed: false}, {key: 'NTE_PO_Confirmed__c', completed: true}]}));
    const {component} = mount('nteMasterPanel', {
        getDashboard: async () => { reads++; return dashboard({selectedViewKey: 'REQUIREMENTS', offsetRows: 25, totalRows: 60, rows}); },
        setRequirement: () => { writes++; return saving.promise; }
    });
    await component.loadDashboard(); component.selectedRecordId = 'booking-27';
    const before = component.rows.map(row => row.recordId).join(',');
    const check = actionEvent({id: 'booking-40', requirement: 'NTE_Invoice_Provided__c'}); check.target = {checked: true};
    const pending = component.handleRequirement(check);
    await component.handleRequirement(check);
    assert.equal(component.isActionPending, true); assert.equal(writes, 1);
    assert.equal(component.rows.find(row => row.recordId === 'booking-40').requirements[0].completed, true);
    saving.resolve(); await pending;
    assert.equal(reads, 1, 'A successful independent tick must not fetch and replace the page.');
    assert.equal(component.rows.map(row => row.recordId).join(','), before);
    assert.equal(component.rows.find(row => row.recordId === 'booking-40').requirements[1].completed, true);
    assert.equal(component.selectedRecordId, 'booking-27'); assert.equal(component.offsetRows, 25);
    assert.equal(component.isActionPending, false);
});

test('a failed same-page refresh retains cards, selection and counts with a warning', async () => {
    let reads = 0;
    const {component, events} = mount('nteMasterPanel', {getDashboard: async () => {
        if (++reads > 1) throw new Error('Connection unavailable');
        return dashboard({selectedViewKey: 'REQUIREMENTS', offsetRows: 25, totalRows: 60});
    }});
    await component.loadDashboard(); component.selectedRecordId = 'b';
    const rows = component.rows; const response = component.response;
    await component.loadDashboard();
    assert.equal(component.rows, rows); assert.equal(component.response, response);
    assert.equal(component.selectedRecordId, 'b'); assert.equal(component.offsetRows, 25);
    assert.equal(component.errorMessage, undefined); assert.equal(component.isLoading, false);
    assert.equal(events.at(-1).title, 'Refresh failed'); assert.equal(events.at(-1).variant, 'warning');
    component.viewKey = 'PAYMENT_DUE'; await component.loadDashboard();
    assert.equal(component.rows.length, 0, 'A failed different-view request must not label the old cards as the new view.');
    assert.equal(component.errorMessage, 'Connection unavailable');
});

test('an unconfirmed checkbox rolls back while a failed recovery refresh keeps its card available', async () => {
    let reads = 0;
    const row = {recordId: 'booking', objectApiName: 'Opportunity', requirements: [{key: 'NTE_PO_Confirmed__c', completed: false, detail: 'PO-123'}]};
    const {component, events} = mount('nteMasterPanel', {
        getDashboard: async () => { if (++reads > 1) throw new Error('Refresh unavailable'); return dashboard({selectedViewKey: 'REQUIREMENTS', rows: [row]}); },
        setRequirement: async () => { throw new Error('Save rejected'); }
    });
    await component.loadDashboard();
    const check = actionEvent({id: 'booking', requirement: 'NTE_PO_Confirmed__c'}); check.target = {checked: true};
    await component.handleRequirement(check);
    assert.equal(check.target.checked, false); assert.equal(component.rows[0].requirements[0].completed, false);
    assert.equal(component.rows[0].requirements[0].detail, 'PO-123'); assert.equal(component.rows.length, 1);
    assert.equal(events.map(event => event.title).join(','), 'Update could not be confirmed');
    assert.equal(events[0].variant, 'warning');
    assert.equal(component.isActionPending, false);
});

test('a lost checkbox response reports success when a fresh read confirms the requested value', async () => {
    for (const completed of [true, false]) {
        let savedValue = !completed; let writes = 0; let reads = 0;
        const {component, events} = mount('nteMasterPanel', {
            getDashboard: async () => { reads++; return dashboard({selectedViewKey: 'REQUIREMENTS', rows: [{
                recordId: 'booking', objectApiName: 'Opportunity', requirements: [{key: 'NTE_PO_Confirmed__c', completed: savedValue}]
            }]}); },
            setRequirement: async args => { writes++; savedValue = args.completed; throw new Error('Response lost after commit'); }
        });
        assert.equal(await component.loadDashboard(), true);
        const check = actionEvent({id: 'booking', requirement: 'NTE_PO_Confirmed__c'}); check.target = {checked: completed};
        await component.handleRequirement(check);
        assert.equal(writes, 1, 'Recovery reads the result and never repeats the write.');
        assert.equal(reads, 2); assert.equal(check.target.checked, completed);
        assert.equal(component.rows[0].requirements[0].completed, completed);
        assert.equal(events.length, 1); assert.equal(events[0].title, 'Requirement saved');
        assert.equal(events[0].variant, 'success'); assert.equal(component.isActionPending, false);
    }
});

test('a rejected checkbox reports unsaved only after a fresh read confirms the opposite value', async () => {
    const {component, events} = mount('nteMasterPanel', {
        getDashboard: async () => dashboard({selectedViewKey: 'REQUIREMENTS', rows: [{recordId: 'booking', objectApiName: 'Opportunity',
            requirements: [{key: 'NTE_PO_Confirmed__c', completed: false}]}]}),
        setRequirement: async () => { throw new Error('Save rejected'); }
    });
    await component.loadDashboard();
    const check = actionEvent({id: 'booking', requirement: 'NTE_PO_Confirmed__c'}); check.target = {checked: true};
    await component.handleRequirement(check);
    assert.equal(check.target.checked, false); assert.equal(component.rows[0].requirements[0].completed, false);
    assert.equal(events.length, 1); assert.equal(events[0].title, 'Update not saved'); assert.equal(events[0].variant, 'error');
});

test('a requirement absent from the recovery read is unconfirmed rather than reported unsaved', async () => {
    let reads = 0;
    const {component, events} = mount('nteMasterPanel', {
        getDashboard: async () => dashboard({selectedViewKey: 'REQUIREMENTS', rows: [{recordId: 'booking', objectApiName: 'Opportunity',
            requirements: ++reads === 1 ? [{key: 'NTE_PO_Confirmed__c', completed: false}] : []}]}),
        setRequirement: async () => { throw new Error('The requirement no longer applies'); }
    });
    await component.loadDashboard();
    const check = actionEvent({id: 'booking', requirement: 'NTE_PO_Confirmed__c'}); check.target = {checked: true};
    await component.handleRequirement(check);
    assert.equal(component.rows.length, 1); assert.equal(component.rows[0].requirements.length, 0);
    assert.equal(events.length, 1); assert.equal(events[0].title, 'Update could not be confirmed');
});

test('checkbox focus returns without a page jump after the saved card renders', async () => {
    const saving = deferred(); const focused = []; const scrolled = []; let top = 420;
    const {component, context} = mount('nteMasterPanel', {setRequirement: () => saving.promise});
    context.window.scrollX = 0; context.window.scrollY = 900;
    context.window.scrollBy = (x,y) => scrolled.push([x,y]);
    context.document.body = {}; context.document.activeElement = {};
    const control = {dataset: {id: 'booking', requirement: 'NTE_PO_Confirmed__c'}, getBoundingClientRect: () => ({top}), focus: options => focused.push(options)};
    component.template.querySelector = selector => selector.includes('data-requirement') ? control : null;
    const check = {...actionEvent(control.dataset), currentTarget: control, target: {checked: true}};
    const pending = component.handleRequirement(check);
    component.renderedCallback(); assert.equal(focused.length, 0, 'Do not focus a disabled pending control.');
    top = 460; context.document.activeElement = context.document.body;
    saving.resolve(); await pending; component.renderedCallback();
    assert.equal(focused.length, 1); assert.equal(focused[0].preventScroll, true);
    assert.deepEqual(scrolled, [[0,40]]);
    component.renderedCallback(); assert.equal(focused.length, 1, 'Restore once, not on subsequent renders.');
});

test('checkbox completion respects a user who scrolls or moves focus while saving', async () => {
    for (const move of ['scroll', 'focus']) {
        const saving = deferred(); let focused = 0;
        const {component, context} = mount('nteMasterPanel', {setRequirement: () => saving.promise});
        context.window.scrollX = 0; context.window.scrollY = 900;
        context.document.body = {}; context.document.activeElement = {};
        const control = {dataset: {id: 'booking', requirement: 'NTE_PO_Confirmed__c'}, focus: () => focused++};
        component.template.querySelector = () => control;
        const pending = component.handleRequirement({...actionEvent(control.dataset), currentTarget: control, target: {checked: true}});
        if (move === 'scroll') context.window.scrollY = 1100;
        else context.document.activeElement = {};
        saving.resolve(); await pending; component.renderedCallback();
        assert.equal(focused, 0, `${move} must not be undone when the save finishes.`);
    }
});

test('finance polling waits for a pending checkbox and resumes afterwards', async () => {
    const saving = deferred(); let reads = 0;
    const {component, flushTimers} = mount('nteMasterPanel', {
        getDashboard: async () => { reads++; return dashboard({selectedViewKey: 'REQUIREMENTS', rows: [{recordId: 'booking', approvalEmailStatus: 'Pending'}]}); },
        setRequirement: () => saving.promise
    });
    component.financePollsRemaining = 2; await component.loadDashboard();
    const check = actionEvent({id: 'booking', requirement: 'NTE_PO_Confirmed__c'}); check.target = {checked: true};
    const pending = component.handleRequirement(check);
    await flushTimers(); assert.equal(reads, 1, 'A finance timer must not replace the page during a checkbox write.');
    saving.resolve(); await pending; await flushTimers();
    assert.equal(reads, 2, 'The queued finance status still refreshes after the checkbox save.');
});

test('a disconnected panel does not restore checkbox focus or start a new recovery read', async () => {
    const saving = deferred(); let reads = 0;
    const {component, timers} = mount('nteMasterPanel', {getDashboard: async () => { reads++; return dashboard(); }, setRequirement: () => saving.promise});
    const check = actionEvent({id: 'booking', requirement: 'NTE_PO_Confirmed__c'}); check.target = {checked: true};
    const pending = component.handleRequirement(check); component.disconnectedCallback();
    saving.reject(new Error('Late response')); await pending;
    assert.equal(component.requirementPosition, undefined); assert.equal(reads, 0); assert.equal(timers.size, 0);
});

test('queued and failed finance requests remain visible when no other row action is available', () => {
    const { component } = mount(); component.viewKey = 'REQUIREMENTS';
    for (const state of [{approvalEmailStatus: 'Pending'}, {topUpEmailStatus: 'Queued'}, {approvalEmailError: 'Payment request needs review'}, {topUpEmailError: 'Stripe is unavailable'}]) {
        component.rows = [component.decorateRow({recordId: 'booking', objectApiName: 'Opportunity', ...state})];
        assert.equal(component.hasRowActions, true);
    }
});

test('finance overview uses requirements and does not imply checklist completion after sending', () => {
    const { component } = mount();
    component.response = {overview: [{key:'requirements',label:'Requirements',total:5,inProgress:2,completed:3,viewKey:'REQUIREMENTS'}]};
    assert.equal(component.requirementsBreakdown.label,'Requirements');
    assert.equal(component.requirementsBreakdown.viewKey,'REQUIREMENTS');
    assert.equal(component.requirementsBreakdown.inProgress,2);
    assert.match(component.requirementsBreakdown.ariaLabel,/requested or confirmed/);
    const html=fs.readFileSync(path.join(sourceRoot,'force-app/main/default/lwc/nteMasterPanel/nteMasterPanel.html'),'utf8');
    assert(!html.includes('quoteBreakdown')); assert(!html.includes('invoiceBreakdown'));
});

test('finance actions follow their stage and never offer a send in payment required', () => {
    const {component} = mount();
    const booking = {recordId:'booking', objectApiName:'Opportunity', canSendBase:true, canSendTopUp:true, canMarkPaid:true, canMarkTopUpPaid:true};
    component.viewKey='PAYMENT_DUE';
    let row=component.decorateRow({...booking,requirementsDue:false,financeStatus:'Payment required'});
    assert.equal(row.canSendBase,false);assert.equal(row.canSendTopUp,false);assert.equal(row.showMarkPaid,true);assert.equal(row.showMarkTopUpPaid,true);
    component.viewKey='REQUIREMENTS';
    row=component.decorateRow({...booking,requirementsDue:true,financeStatus:'Requirements'});
    assert.equal(row.canSendBase,true);assert.equal(row.canSendTopUp,true);assert.equal(row.showMarkPaid,false);assert.equal(row.showMarkTopUpPaid,false);
    component.viewKey='PAYMENT_COMPLETE';
    row=component.decorateRow({...booking,requirementsDue:false,financeStatus:'Payment confirmed'});
    assert.equal(row.canSendBase,false);assert.equal(row.canSendTopUp,false);assert.equal(row.showMarkPaid,false);assert.equal(row.showMarkTopUpPaid,false);
    component.viewKey='FINANCE_DUE';
    row=component.decorateRow({...booking,requirementsDue:true,financeStatus:'Requirements'});
    assert.equal(row.canSendTopUp,false);assert.equal(row.showMarkPaid,false);assert.equal(row.showMarkTopUpPaid,false);
    for (const view of ['PAYMENT_DUE','PAYMENT_COMPLETE','FINANCE_DUE','APPROVED','COMPLETED']) {
        component.viewKey=view;assert.equal(component.isRequirementsView,false);
    }
    component.viewKey='REQUIREMENTS';assert.equal(component.isRequirementsView,true);
    const html=fs.readFileSync(path.join(sourceRoot,'force-app/main/default/lwc/nteMasterPanel/nteMasterPanel.html'),'utf8');
    assert.match(html, /<template lwc:elseif=\{isRequirementsView\}>\s*<div class="requirements-cards"/);
    assert.match(html, /<template lwc:if=\{showDetailPanel\}>\s*<aside class="detail-panel"/);
    assert.equal(component.showDetailPanel,false);
    component.viewKey='PAYMENT_DUE'; assert.equal(component.showDetailPanel,true);
});


test('Requirements preserves long applicant details and labels unpaid top-ups independently', () => {
    const {component} = mount(); component.viewKey='REQUIREMENTS';
    const detail='Cost centre: A&B <Careers>\n' + 'Additional procurement information. '.repeat(90);
    const row=component.decorateRow({recordId:'booking',objectApiName:'Opportunity',basePaymentReceived:true,baseAmount:1200,topUpAmount:60,topUpPaymentReceived:false,canSendTopUp:true,requirements:[{key:'notes',label:'Additional invoice details',detail,completed:true}]});
    assert.equal(row.financeAmount,60); assert.equal(row.requirementBookingType,'Staff top-up');
    assert.equal(row.requirements[0].detail,detail); assert.equal(row.requirements[0].detailIsLong,true); assert.equal(row.requirements[0].completed,true);
    assert(row.requirements[0].detailPreview.length<200); assert.equal(row.canSendTopUp,true);
    const free=component.decorateRow({objectApiName:'Opportunity',baseAmount:0,requirements:[]});
    assert.equal(free.requirementBookingType,'Complimentary space'); assert.equal(free.hasRequirements,false);
});

test('Requirements labels the current Stripe top-up without rewriting the base payment method', () => {
    const {component} = mount(); component.viewKey = 'REQUIREMENTS';
    const paid = component.decorateRow({objectApiName:'Opportunity', basePaymentReceived:true,
        baseAmount:958.8, topUpAmount:60, topUpPaymentReceived:false, paymentMethod:'Bank transfer',
        canSendTopUp:true, pricingReviewRequired:false});
    assert.equal(paid.requirementBookingType,'Staff top-up');
    assert.equal(paid.paymentMethodDisplay,'Stripe');
    assert.equal(paid.paymentMethod,'Bank transfer');
    assert.equal(paid.financeAmount,60);
    assert.equal(paid.requirementAmountLabel,'Outstanding (inc VAT)');
    const free = component.decorateRow({objectApiName:'Opportunity', basePaymentReceived:false,
        baseAmount:0, topUpAmount:60, topUpPaymentReceived:false, paymentMethod:null,
        invoiceRequired:true, canSendTopUp:true, pricingReviewRequired:false});
    assert.equal(free.requirementBookingType,'Staff top-up');
    assert.equal(free.paymentMethodDisplay,'Stripe');
    assert.equal(free.paymentMethod,null);
    assert.equal(free.financeAmount,60);
    component.viewKey = 'PAYMENT_COMPLETE';
    assert.equal(component.decorateRow({...paid,topUpPaymentReceived:true}).paymentMethodDisplay,'Bank transfer');
});

test('Requirements identifies both routes when the base and its staff top-up are still unpaid', () => {
    const {component} = mount(); component.viewKey = 'REQUIREMENTS';
    const row = component.decorateRow({objectApiName:'Opportunity', sourceFormType:'Exhibitor Application',
        basePaymentReceived:false, baseAmount:958.8, topUpAmount:60, topUpPaymentReceived:false,
        paymentMethod:'Bank transfer', pricingReviewRequired:false});
    assert.equal(row.requirementBookingType,'Exhibitor booking');
    assert.equal(row.paymentMethodDisplay,'Bank transfer; Stripe for staff top-up');
    assert.equal(row.financeAmount,1018.8);
    assert.equal(row.paymentMethod,'Bank transfer');
});

for (const [method, dataset, endpoint] of [
    ['handleLeadDecision',{id:'00Qbooking',decision:'APPLICATION_REJECTED'},'updateLeadDecision'],
    ['handleMilestone',{id:'006booking',action:'PAYMENT_RECEIVED'},'recordReviewedPayment']
]) {
    test(`${method} reconciles a stale row after failure and never repeats the write`, async () => {
        let writes = 0; let reads = 0;
        const {component,events} = mount('nteMasterPanel', {
            [endpoint]: async () => { writes++; throw {body:{message:'This record was already handled. Refresh its current status.'}}; },
            getDashboard: async () => { reads++; return dashboard({rows:[{recordId:'survivor'}]}); }
        });
        component.rows = [{recordId:dataset.id},{recordId:'survivor'}];
        component.selectedRecordId = 'survivor';
        await component[method](actionEvent(dataset));
        assert.equal(writes,1); assert.equal(reads,1);
        assert.equal(component.rows.some(row => row.recordId === dataset.id),false);
        assert.equal(component.selectedRecordId,'survivor');
        assert.match(events.at(-1).message,/already handled/);
        assert.equal(events.at(-1).variant,'error');
        assert.equal(component.panelControlsDisabled,false);
    });

    test(`${method} retains a genuine rejection when its recovery refresh also fails`, async () => {
        let writes = 0; let reads = 0;
        const {component,events} = mount('nteMasterPanel', {
            [endpoint]: async () => { writes++; throw {body:{message:'Your access to update this record has changed.'}}; },
            getDashboard: async () => { reads++; throw new Error('Network unavailable'); }
        });
        component.eventCode = 'NTE2027'; component.response = dashboard();
        component.rows = [{recordId:dataset.id}]; component.selectedRecordId = dataset.id;
        await component[method](actionEvent(dataset));
        assert.equal(writes,1); assert.equal(reads,1);
        assert.equal(component.rows[0].recordId,dataset.id);
        assert.equal(events.length,1); assert.match(events[0].message,/access to update/);
        assert.equal(component.panelControlsDisabled,false);
    });
}

for (const savedState of [true,false,undefined]) {
    test(`joining marker reconciles a lost response with saved state ${savedState}`, async () => {
        let writes = 0; let reads = 0;
        const {component,events} = mount('nteMasterPanel', {
            setJoiningInstructions: async () => { writes++; throw new Error('Connection lost'); },
            getDashboard: async () => {
                reads++;
                if (savedState === undefined) throw new Error('Refresh unavailable');
                return dashboard({selectedViewKey:'COMPLETED',rows:[{recordId:'006booking',finalPackStatus:savedState ? 'Sent' : null}]});
            }
        });
        component.viewKey = 'COMPLETED'; component.eventCode = 'NTE2027';
        component.response = dashboard({selectedViewKey:'COMPLETED'});
        component.rows = [{recordId:'006booking',joiningSent:false}];
        const event = actionEvent({id:'006booking'}); event.target = {checked:true};
        await component.handleJoiningInstructions(event);
        assert.equal(writes,1); assert.equal(reads,1);
        assert.equal(event.target.checked,savedState === true);
        assert.equal(component.rows[0].joiningSent,savedState === true);
        assert.equal(events.at(-1).variant,savedState === true ? 'success' : savedState === false ? 'error' : 'warning');
        assert.equal(events.at(-1).title,savedState === true ? 'Update confirmed' : savedState === false ? 'Update not saved' : 'Update could not be confirmed');
    });
}

test('a confirmed joining-marker save survives a failed refresh with its checkbox checked', async () => {
    let writes = 0;
    const {component,events} = mount('nteMasterPanel', {
        setJoiningInstructions: async () => { writes++; },
        getDashboard: async () => { throw new Error('Refresh unavailable'); }
    });
    component.viewKey = 'COMPLETED'; component.eventCode = 'NTE2027';
    component.response = dashboard({selectedViewKey:'COMPLETED'});
    component.rows = [{recordId:'006booking',joiningSent:false}];
    const event = actionEvent({id:'006booking'}); event.target = {checked:true};
    await component.handleJoiningInstructions(event);
    assert.equal(writes,1); assert.equal(component.rows[0].joiningSent,true);
    assert.equal(event.target.checked,true); assert.equal(events.at(-1).title,'Refresh failed');
});

for (const [action,status] of [['BANK',{approvalEmailStatus:'Pending'}],['TOP_UP',{topUpEmailStatus:'Queued'}]]) {
    test(`${action} restores pending-email polling after a committed request loses its response`, async () => {
        let writes = 0; let reads = 0;
        const {component,events,timers} = mount('nteMasterPanel', {
            sendFinanceAction: async () => { writes++; throw new Error('Connection lost'); },
            getDashboard: async () => { reads++; return dashboard({selectedViewKey:'REQUIREMENTS',rows:[{recordId:'006booking',...status}]}); }
        });
        component.viewKey = 'REQUIREMENTS';
        await component.handleFinanceAction(actionEvent({id:'006booking',action}));
        assert.equal(writes,1); assert.equal(reads,1);
        assert.equal(events.at(-1).title,'Update confirmed'); assert.equal(events.at(-1).variant,'success');
        assert(component.financePollsRemaining > 0); assert.equal(timers.size,1);
    });
}

test('a missing row after an uncertain finance send never proves the email was sent or unsent', async () => {
    let writes = 0;
    const {component,events} = mount('nteMasterPanel', {
        sendFinanceAction: async () => { writes++; throw new Error('Connection lost'); },
        getDashboard: async () => dashboard({selectedViewKey:'REQUIREMENTS',rows:[]})
    });
    component.viewKey = 'REQUIREMENTS';
    await component.handleFinanceAction(actionEvent({id:'006booking',action:'STRIPE'}));
    assert.equal(writes,1); assert.equal(events.at(-1).title,'Update could not be confirmed');
    assert.equal(events.at(-1).variant,'warning'); assert.equal(component.rows.length,0);
});

test('a finance action that resolves after disconnect does not start recovery reads or issue toasts', async () => {
    for (const failure of [true,false]) {
        const saving = deferred(); let reads = 0;
        const {component,events} = mount('nteMasterPanel', {
            sendFinanceAction: () => saving.promise,
            getDashboard: async () => { reads++; return dashboard(); }
        });
        const pending = component.handleFinanceAction(actionEvent({id:'006booking',action:'BANK'}));
        component.disconnectedCallback();
        if (failure) saving.reject(new Error('Late failure'));
        else saving.resolve({queuedCount:1,message:'Queued'});
        await pending;
        assert.equal(reads,0); assert.equal(events.length,0);
    }
});

test('guest and recent views never present an unrelated commercial stage or refiner', async () => {
    const stageViews = {interest:'INTEREST',applications:'APPLICATION_REVIEW',approved:'APPROVED',finance:'FINANCE_DUE',readiness:'READINESS_DUE',complete:'COMPLETED'};
    const pipeline = Object.entries(stageViews).map(([key,viewKey]) => ({key,viewKey,count:1}));
    const {component} = mount('nteMasterPanel', {getDashboard: async request => dashboard({selectedViewKey:request.viewKey,pipeline})});
    for (const view of ['GUESTS','RECENT']) {
        component.handleOverviewSelect(actionEvent({view}));
        await new Promise(setImmediate);
        assert.equal(component.activeStage,undefined);
        assert.equal(component.hasStageOptions,false);
        assert.equal(component.pipeline.some(step => step.ariaPressed === 'true'),false);
    }
    for (const [stage,view] of Object.entries(stageViews)) {
        component.viewKey = view;
        assert.equal(component.activeStage,stage);
        assert.equal(component.hasStageOptions,true);
        assert.equal(component.pipeline.filter(step => step.ariaPressed === 'true').length,1);
    }
});

test('the Update issues graph is available with a readable zero or global issue count in every ordinary view', () => {
    const {component} = mount();
    for (const view of ['INTEREST','APPLICATION_REVIEW','APPROVED','REQUIREMENTS','PAYMENT_DUE','STAFF_DUE','COMPLETED']) {
        component.viewKey = view;
        component.response = dashboard({selectedViewKey:view,updateIssueCount:0});
        assert.equal(component.updateIssuesBreakdown.count,0);
        assert.equal(component.updateIssuesBreakdown.fillStyle,'width: 0%;');
        assert.equal(component.updateIssuesBreakdown.ariaPressed,'false');
        component.response.updateIssueCount = 26;
        assert.equal(component.updateIssuesBreakdown.count,26);
        assert.match(component.updateIssuesBreakdown.ariaLabel,/26 issues across all events, all time and all owners/);
    }
    const html = fs.readFileSync(path.join(sourceRoot,'force-app/main/default/lwc/nteMasterPanel/nteMasterPanel.html'),'utf8');
    assert(html.indexOf('class="update-issues-breakdown"') > html.indexOf('data-view={logoBreakdown.viewKey}'));
    assert.match(html,/<button[^>]+type="button"[^>]+data-view="UPDATE_ISSUES"[^>]+onclick=\{handleOverviewSelect\}[^>]+aria-label=\{updateIssuesBreakdown.ariaLabel\}/);
    assert.match(html,/<span class="metric-total"><strong>\{updateIssuesBreakdown.count\}<\/strong>/);
});

test('opening global update issues locks filters and returning to a normal stage restores their existing scope', async () => {
    const requests = []; let mutations = 0;
    const pipeline = ['interest','applications','approved','finance','readiness','complete'].map((key,index) => ({key,count:index + 1}));
    const {component} = mount('nteMasterPanel', {
        getDashboard: async request => {
            requests.push({...request});
            return dashboard({selectedViewKey:request.viewKey,selectedEventCode:request.eventCode,selectedTimeRange:request.timeRange,
                selectedOwnerId:request.ownerId,pipeline,updateIssueCount:1,rows:[{recordId:'00Qissue',objectApiName:'Lead',organisation:'Alder Marine'}]});
        },
        updateLeadDecision: async () => { mutations++; },
        sendFinanceAction: async () => { mutations++; },
        retryFailedEmails: async () => { mutations++; }
    });
    Object.assign(component,{eventCode:'NTE2027',timeRange:'TODAY',ownerId:'005team',offsetRows:25});
    component.handleOverviewSelect(actionEvent({view:'UPDATE_ISSUES'}));
    await new Promise(setImmediate);
    assert.equal(requests[0].viewKey,'UPDATE_ISSUES');
    assert.equal(requests[0].offsetRows,0);
    assert.equal(component.filterControlsDisabled,true);
    assert.equal(component.panelControlsDisabled,false);
    assert.equal(component.hasStageOptions,false);
    assert.equal(component.activeStage,undefined);
    assert.equal(component.pipeline.length,6);
    assert.equal(component.pipeline.some(step => step.ariaPressed === 'true'),false);
    component.handleEventChange({detail:{value:'NTE2028'}});
    component.handleTimeChange({detail:{value:'ALL'}});
    component.handleOwnerChange({detail:{value:''}});
    assert.equal(requests.length,1);
    assert.equal(component.eventCode,'NTE2027'); assert.equal(component.timeRange,'TODAY'); assert.equal(component.ownerId,'005team');
    component.handlePipelineSelect(actionEvent({stage:'approved'}));
    await new Promise(setImmediate);
    assert.equal(requests[1].viewKey,'APPROVED');
    assert.equal(requests[1].eventCode,'NTE2027'); assert.equal(requests[1].timeRange,'TODAY'); assert.equal(requests[1].ownerId,'005team');
    assert.equal(component.filterControlsDisabled,false);
    assert.equal(component.activeStage,'approved');
    assert.equal(component.pipeline.filter(step => step.ariaPressed === 'true').length,1);
    assert.equal(mutations,0);
});

test('Update issues paging and refresh stay in the read-only global queue', async () => {
    const requests = [];
    const {component} = mount('nteMasterPanel', {getDashboard: async request => {
        requests.push({...request});
        const rows = Array.from({length:request.offsetRows ? 1 : 25},(_,index) => ({recordId:`00Qissue${request.offsetRows + index}`,organisation:'Alder Marine'}));
        return dashboard({selectedViewKey:request.viewKey,rows,offsetRows:request.offsetRows,totalRows:26,updateIssueCount:26,hasNextPage:!request.offsetRows});
    }});
    component.viewKey = 'UPDATE_ISSUES'; await component.loadDashboard();
    component.handleNext(); await new Promise(setImmediate);
    assert.equal(component.pageLabel,'26–26 of 26'); assert.equal(component.nextDisabled,true);
    assert.equal(component.updateIssuesBreakdown.count,26);
    component.handleRefresh(); await new Promise(setImmediate);
    component.handlePrevious(); await new Promise(setImmediate);
    assert.deepEqual(requests.map(request => request.offsetRows),[0,25,25,0]);
    assert.equal(requests.every(request => request.viewKey === 'UPDATE_ISSUES'),true);
    assert.equal(component.showDetailPanel,false); assert.equal(component.hasRowActions,false);
});

test('Update issues retain the submitted text, zero values and multiline content without inventing missing references', () => {
    const {component} = mount(); component.viewKey = 'UPDATE_ISSUES';
    const longValue = 'Élan & Partners <script>alert("x")</script>\n' + 'Reference & details '.repeat(80);
    const input = {recordId:'00Qissue',organisation:'Élan & Partners',name:'Zoë Beaumont',bookingReference:null,eventCode:null,
        updateStatus:'Error',updateIssueKind:'NOT_APPLIED',updateIssueLabel:'Update not applied',updateIssueReason:'No matching booking.',
        sourceFormType:'Staff Confirmation',submittedAt:'2026-09-14T11:15:00.000Z',updateDetails:[
            {key:'notes',label:'Additional details',value:longValue},
            {key:'staff',label:'Additional staff',value:0},
            {key:'empty',label:'Empty',value:'  '}
        ]};
    const row = component.decorateRow(input);
    assert.equal(row.contactName,'Zoë Beaumont');
    assert.equal(row.updateReferenceDisplay,'Not supplied'); assert.equal(row.updateEventDisplay,'Not supplied');
    assert.equal(row.updateDetails.length,2); assert.equal(row.updateDetails[0].value,longValue);
    assert.equal(row.updateDetails[0].detailIsLong,true); assert.equal(row.updateDetails[1].value,'0');
    assert.equal(row.updateStatusDisplay,'Error'); assert.equal(row.updateIssueReason,'No matching booking.');
    assert.equal(input.updateDetails.length,3); assert.equal(input.updateDetails[1].value,0);
    assert.equal(row.hasUpdateDetails,true);
});

test('both unapplied updates and failed acknowledgements expose only safe full-record navigation in the issue workbench', () => {
    const {component} = mount(); component.viewKey = 'UPDATE_ISSUES';
    for (const kind of ['NOT_APPLIED','EMAIL_FAILED']) {
        component.rows = [component.decorateRow({recordId:'00Qissue',objectApiName:'Lead',updateIssueKind:kind,
            updateStatus:kind === 'EMAIL_FAILED' ? 'Updated' : 'Error',recordUrl:'/lightning/r/Lead/00Qissue/view'})];
        assert.equal(component.hasRowActions,false); assert.equal(component.showDetailPanel,false);
        assert.equal(component.canRemindAll,false); assert.equal(component.isApplicationView,false); assert.equal(component.isInterestView,false);
    }
    const html = fs.readFileSync(path.join(sourceRoot,'force-app/main/default/lwc/nteMasterPanel/nteMasterPanel.html'),'utf8');
    const issueMarkup = html.split('<template lwc:if={isUpdateIssuesView}>')[1].split('<template lwc:elseif={isRequirementsView}>')[0];
    assert.match(issueMarkup,/<a[^>]+href=\{row.recordUrl\}>Open full record<\/a>/);
    for (const binding of ['row.submittedAt','row.updateReferenceDisplay','row.updateTypeDisplay','row.updateStatusDisplay','row.updateIssueReason','detail.value']) {
        assert(issueMarkup.includes(`{${binding}}`),`Missing issue evidence: ${binding}`);
    }
    assert.doesNotMatch(issueMarkup,/onclick=|onchange=|nte-retry|lightning-input|lightning-formatted-rich-text|lwc:dom|innerHTML/);
    assert.match(issueMarkup,/<details[^>]*>\s*<summary>/);
    assert.match(issueMarkup,/<div class="requirement-full-detail" tabindex="0">\{detail.value\}<\/div>/);
});

test('the Update issues graph focuses its loaded workbench once without moving focus during later refreshes', async () => {
    const waiting = deferred(); let focuses = 0; let scrolls = 0;
    const {component} = mount('nteMasterPanel',{getDashboard:() => waiting.promise});
    component.template.querySelector = selector => selector === '[data-workbench-heading]' ? {
        focus(options) { assert.equal(options.preventScroll,true); focuses++; },
        scrollIntoView(options) { assert.equal(options.block,'start'); scrolls++; }
    } : null;
    component.handleOverviewSelect(actionEvent({view:'UPDATE_ISSUES'}));
    component.renderedCallback(); assert.equal(focuses,0);
    waiting.resolve(dashboard({selectedViewKey:'UPDATE_ISSUES',updateIssueCount:0,rows:[]}));
    await new Promise(setImmediate);
    component.renderedCallback(); assert.equal(focuses,1); assert.equal(scrolls,1);
    await component.loadDashboard(); component.renderedCallback();
    assert.equal(focuses,1); assert.equal(scrolls,1);
    component.workbenchFocusView = 'UPDATE_ISSUES'; component.disconnectedCallback(); component.renderedCallback();
    assert.equal(focuses,1);
});

test('an unavailable issues queue keeps its last known attention count instead of falsely clearing it', async () => {
    let fails = false;
    const {component} = mount('nteMasterPanel',{getDashboard:async request => {
        if (fails) throw new Error('Unable to load update issues');
        return dashboard({selectedViewKey:request.viewKey,updateIssueCount:3});
    }});
    await component.loadDashboard(); assert.equal(component.updateIssuesBreakdown.count,3);
    fails = true; component.handleOverviewSelect(actionEvent({view:'UPDATE_ISSUES'}));
    await new Promise(setImmediate);
    assert.equal(component.errorMessage,'Unable to load update issues');
    assert.equal(component.rows.length,0); assert.equal(component.updateIssuesBreakdown.count,3);
    assert.equal(component.selectedQueue.label,'Update issues');
    assert.match(component.selectedQueue.detail,/all events, dates and owners/);
});

test('an empty Update issues view states global scope while ordinary queues retain their filter wording', () => {
    const {component} = mount(); component.viewKey = 'UPDATE_ISSUES';
    assert.equal(component.emptyQueueTitle,'No update issues');
    assert.equal(component.emptyQueueDetail,'No update issues across any event, time or owner.');
    component.viewKey = 'PAYMENT_DUE';
    assert.equal(component.emptyQueueTitle,'No records in this queue');
    assert.equal(component.emptyQueueDetail,'Nothing matches the selected event, time and owner filters.');
});

test('logistics fallback and the payment-method hint follow their views', () => {
    const {component} = mount();
    const booking = {recordId: 'booking', objectApiName: 'Opportunity', canConfirmNoHeavyVehicle: true, financeActionIssue: 'Select the payment method'};
    component.viewKey = 'HEAVY_DUE';
    const row = component.decorateRow(booking);
    assert.equal(row.showConfirmNoHeavyVehicle, true);
    assert.equal(row.financeActionIssue, 'Select the payment method');
    component.rows = [row];
    assert.equal(component.hasRowActions, true, 'Logistics outstanding renders its action column');
    component.rows = [component.decorateRow({...booking, canConfirmNoHeavyVehicle: false})];
    assert.equal(component.hasRowActions, false, 'no action column when nothing can be confirmed');
    assert.equal(component.decorateRow({...booking, canConfirmNoHeavyVehicle: false}).showConfirmNoHeavyVehicle, false);
    assert.equal(component.decorateRow({...booking, objectApiName: 'Lead'}).showConfirmNoHeavyVehicle, false);
    for (const viewKey of ['READINESS_DUE', 'STAFF_DUE', 'LOGO_DUE', 'COMPLETED', 'REQUIREMENTS']) {
        component.viewKey = viewKey;
        assert.equal(component.decorateRow(booking).showConfirmNoHeavyVehicle, false, viewKey + ' offers no logistics confirmation');
    }
    const html = fs.readFileSync(path.join(sourceRoot, 'force-app/main/default/lwc/nteMasterPanel/nteMasterPanel.html'), 'utf8');
    assert(html.includes('{row.financeActionIssue}'), 'Requirements cards show why no request action is offered');
    assert(html.includes('onclick={handleConfirmNoHeavyVehicle}'), 'the logistics confirmation is wired to its handler');
});
