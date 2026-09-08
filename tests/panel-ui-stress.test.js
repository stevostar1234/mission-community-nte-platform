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
        retryApprovalEmail: async () => ({ queuedCount: 1, message: 'Booking email queued.' }),
        retryAcknowledgement: async () => ({ success: true, message: 'Acknowledgement accepted by Salesforce.' }),
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
    ['handleMilestone', { id: '006booking', action: 'PAYMENT_RECEIVED' }, 'updateMilestone']
]) {
    test(`${method} locks before confirmation and submits once`, async () => {
        const confirmation = deferred(); let confirms = 0; let writes = 0;
        const { component } = mount('nteMasterPanel', {
            LightningConfirm: { open: () => { confirms++; return confirmation.promise; } },
            [endpoint]: async () => { writes++; return { success: true, message: 'Saved.' }; }
        });
        const first = component[method](actionEvent(dataset));
        const duplicate = component[method](actionEvent(dataset));
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

test('finance refinement presents the amount for its actionable charge', () => {
    const { component } = mount();
    const unpaid = { baseAmount: 800, topUpAmount: 50, amount: 850, baseInvoiceRequired: true, baseInvoiceProvided: true, basePaymentReceived: false, canMarkPaid: true, canMarkTopUpInvoice: true };
    component.viewKey = 'PAYMENT_DUE';
    assert.equal(component.financeAmountForView(unpaid), 800);
    assert.equal(component.financeStatusForView(unpaid), 'Booking payment required');
    component.viewKey = 'INVOICE_REQUIRED';
    assert.equal(component.financeAmountForView(unpaid), 50);
    assert.equal(component.financeStatusForView(unpaid), 'Staff top-up invoice required');
    component.viewKey = 'PAYMENT_DUE';
    assert.equal(component.financeAmountForView({ ...unpaid, basePaymentReceived: true }), 50);
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
    const { component, events } = mount('nteRetryEmail', { retryApprovalEmail: async () => ({ queuedCount: 0, message: 'The email could not be queued. Retry the provisional email from the booking.' }) });
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

test('Home readiness fallback uses the same four labels as finance refiners', () => {
    const { component } = mount('nteManagementHome');
    const labels = component.normalizeReadiness({}).map((item) => item.label);
    assert.equal(JSON.stringify(labels), JSON.stringify(['Quotes required', 'Invoice required', 'Payment required', 'Payment confirmed']));
    assert.equal(component.normalizeHeadline([]).at(-1).label, 'Paid');
});
