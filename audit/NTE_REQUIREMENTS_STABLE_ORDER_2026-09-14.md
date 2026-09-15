# Requirements card stability — local implementation

Internal implementation evidence, 14 September 2026 (Europe/London). The owner explicitly approved newest-created Requirements ordering and smoother checkbox saves after [the manual-exception audit](NTE_MANUAL_EXCEPTIONS_PANEL_2026-09-14.md). Local source and tests are complete. Native Apex/browser qualification and deployment remain with the main task; this note makes no native-release claim.

## Resulting behaviour

Requirements now queries Opportunities by `CreatedDate DESC, Id DESC`. The same ordering determines the server page boundary. The controller skips its last-modified merge sort only for Requirements; every other view retains its existing last-modified order. Page size, the 2,000-record cap, finance formulas and eligibility rules are unchanged by this scoped work.

A checklist tick updates its current card in place and calls the existing server checkbox endpoint. A successful independent tick no longer reloads the whole dashboard. Other card IDs, order, checked values, selected record and page offset stay in place. Rejected writes restore the prior value and reread the server. When a refresh of the same page fails, the current cards, selection and counts remain available with a warning. An unsuccessful request for a different view/filter/page still shows the unavailable state rather than presenting old rows under new filters.

After a checkbox save renders, focus returns to the same control without deliberate scrolling to the top. The stored viewport position is restored if rendering shifted the control. Restoration is skipped if the user scrolled or moved focus while waiting. Finance polling defers during a pending checkbox save, then resumes. A disconnected component clears pending focus restoration and does not start another dashboard read.

The existing server service still rechecks active-booking access and applicable requirements under a row lock and writes only the requested field plus its relevant audit values. Sends, receipts and joining instructions retain their existing separate actions. No automatic checklist completion or new stage restriction was introduced.

## Files and coordination

- [Controller](../force-app/main/default/classes/NTE_MasterPanelController.cls): only the Requirements order in `rows()`. No comparator or finance/receipt-rule edits from this subtask. The main task is separately editing finance fields and receipt/waiver logic in that shared class.
- [Controller tests](../force-app/main/default/classes/NTE_MasterPanelControllerTest.cls): `requirementsKeepCreationOrderAcrossPagesAndChecklistSaves`.
- [Panel JavaScript](../force-app/main/default/lwc/nteMasterPanel/nteMasterPanel.js): checkbox in-place save/rollback and focus position; same-page refresh retention; finance-poll deferral and disconnect guard.
- [Panel tests](../tests/panel-ui-stress.test.js): seven new behaviour checks.

No CSS, template, form, email, Salesforce, Stripe or publication change was made by this subtask. A read of the build scripts found no generator body for these controller/LWC implementations requiring synchronisation.

## Verification

`node --test --test-reporter=spec tests/panel-ui-stress.test.js`: **56/56 passed**, zero failures. New cases verify:

1. A page-two checkbox saves once, without a dashboard reload, reordered cards or changes to another requirement.
2. Same-page refresh failure retains cards, selection and counts; different-view failure does not mislabel old cards.
3. A rejected checkbox rolls back even when its recovery refresh also fails.
4. The same checkbox receives focus after saving and a shifted viewport anchor is restored once.
5. Focus and scroll restoration respect a user who moved away during the save.
6. A finance poll waits while the checkbox save is pending and resumes afterward.
7. Disconnect prevents focus restoration and a late recovery read.

The added Apex regression creates 31 isolated test bookings with deliberate creation-date ordering and a tied pair, checks both pages, saves a checkbox on page two and asserts unchanged page membership/order. It also verifies that Approved still follows last-modified order. It is source-complete but was **not run natively by this subtask**. Existing application-pagination and mixed-record Most recent tests remain unchanged. The main task must include the controller test class in its qualification.

`git diff --check` passed for the four changed implementation/test files. The VM tests simulate DOM focus and geometry; they do not replace the pending native browser check with long cards, page-two content, keyboard navigation and expanded details.

## Company display answer

The actual Lead row uses `Lead.Company`. The Opportunity row uses `Account.Name`, or null if the Account is absent. Requirements headings render `row.organisation` directly. There is currently no visible-heading fallback to the Opportunity name, invoiced company or trading name. Only the selection accessibility label falls back from organisation to record name. This was reported to the main task and left unchanged.

Other audit findings, including payment-route replacement and the inherited joining `Queued` filter, remain separate decisions. The original read-only snapshot and eight reproductions are preserved in the preceding audit; their 49-test count is historical, superseded for this local change by the 56-test result above.
