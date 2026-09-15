# Manual exceptions and Master Panel position review

Internal review, 14 September 2026 (Europe/London). The initial read-only phase below supplied findings and UX advice and changed only this report. No Salesforce records, generators, credentials, Stripe resources or published pages were changed. All protected UI and invoice examples remain outside the mutation scope.

**Subsequent owner approval:** Requirements is to use newest-created order so checkbox saves do not move cards. The main task explicitly authorised that scoped source change and position/error recovery work. Local implementation and 56 passing panel tests are recorded in [the implementation note](NTE_REQUIREMENTS_STABLE_ORDER_2026-09-14.md); native Apex/browser qualification and release remain with the main task. The findings below retain their original pre-change source evidence. This approval does not extend to the other business exceptions or the joining-filter change described below.

The confirmed proposal 22 workflow is the reference: independent procurement reminders; manual sends from Requirements; receipt actions in Payment required; Payment confirmed without finance actions; later staff top-ups return through Requirements and Payment required while the original receipt remains recorded; manual joining instructions on Completed. The separate 14 September current-price confirmation clarification is approved and being handled by the main task. Its implementation and release are not qualified by this report.

## Assessment

Keep an edited Requirements card in its working position. The current last-modified ordering makes every checkbox save reorder the booking. Scrolling to the top after each save would follow that movement but would still interrupt checking the remaining items. Stable order, an in-place saved value and preserved keyboard focus are the stronger approach.

The review found one direct explanation for the reported jump, several reproducible refresh/recovery weaknesses and a leftover joining-status filter. It also identified a genuine manual payment-route recovery gap that needs an explicit workflow decision. It did not find a reason to restore automatic checklist ticks or impose stronger blanket stage restrictions on the existing manual endpoints.

## Evidence and reproduction boundary

Source was read from the shared working tree. The existing local `node --test tests/panel-ui-stress.test.js` suite passed **49/49**. Eight additional inline Node assertions used that suite's VM harness to execute the actual LWC source, with mocked Apex responses and a 60-record last-modified-sorted data set. All eight passed. These are behavioural reproductions, not eight new committed tests or native Salesforce/browser tests.

| Reproduction | Observed result |
| --- | --- |
| Tick record r20 on the first page | Its index changed from 19 to 0; selection remained r20. |
| Tick record r40 on the second page | Its index changed from 14 to absent; offset stayed 25 and selection became r25. |
| Save succeeds, subsequent dashboard read fails | One write, zero displayed rows, `Refresh unavailable`, no save-failure toast. |
| Save explicitly rejects, subsequent read succeeds | The saved false value was restored and `Update not saved` was shown. |
| Simulated response loss after the server committed a tick | The successful read showed true while the toast still said `Update not saved`. |
| A pending save finishes after component disconnection | A new dashboard read started after disconnection. |
| An existing finance poll fires during a pending checkbox save | One dashboard read occurred while that write was unresolved. |
| Receipt rejects because another operator already recorded it | No automatic reread occurred; the stale receipt button remained visible. |

The first two reproductions implement the ordering and page slicing found in the Apex source; they do not execute SOQL locally. Browser scroll anchoring, exact native checkbox focus behaviour and preservation of expanded `<details>` were not measured in this run. The user's observed scroll problem and the source ordering establish the cause; actual browser verification is needed for any later position/focus fix. No simultaneous native-user transactions or network outage were induced.

Source identifiers used below:

- **LWC:** [nteMasterPanel.js](../force-app/main/default/lwc/nteMasterPanel/nteMasterPanel.js), with [HTML](../force-app/main/default/lwc/nteMasterPanel/nteMasterPanel.html).
- **Controller:** [NTE_MasterPanelController.cls](../force-app/main/default/classes/NTE_MasterPanelController.cls).
- **Finance:** [NTEFinanceService.cls](../force-app/main/default/classes/NTEFinanceService.cls).
- **Approval:** [NTEExhibitorApprovalEmailService.cls](../force-app/main/default/classes/NTEExhibitorApprovalEmailService.cls).
- **Stripe:** [NTEStripeBookingService.cls](../force-app/main/default/classes/NTEStripeBookingService.cls).

## Confirmed panel and recovery findings

### ME01 — A checkbox save moves the card and can remove it from the current page

**Impact:** frequent interruption during checklist work; on later pages the edited card cannot be found on the page that just saved it.

Both Opportunity SOQL and the combined row comparator use `LastModifiedDate DESC, Id DESC` (Controller 231–244, 1028–1091). `setRequirement` writes the Opportunity, and `saveFinanceChange` reloads the entire dashboard at the current offset (Finance 46–60; LWC 568–596). The load retains the selected ID only if that ID is in the returned page; otherwise it silently selects the first returned record (LWC 443–447). There is no checklist viewport or focus restoration: `renderedCallback` handles only modal focus (LWC 124–128).

The 25-row page size compounds the problem. Sorting only the 25 returned cards differently would not fix it: a changed record on page two is already absent from the returned server slice. Unrelated record updates and another user's saves also affect this ordering.

**Recommendation, not implementation approval:** keep Requirements ordering stable during checklist work. Save the changed field, reconcile its authoritative value and update that card in place. A checklist tick should not imply a new position or refiner. Explicit refresh, filter changes and pagination can reconcile the working set. If automatic refresh remains, merge updated fields without shuffling existing cards merely because their modified timestamps changed. Choose the underlying stable order deliberately—for example creation order plus ID—rather than assuming that the current “most recently edited” order is useful for a work queue. Keep true Most recent views separate from that decision.

### ME02 — A refresh failure discards useful context after a successful save

**Impact:** the user loses the list and reading position even though the tick may have saved successfully.

On any current dashboard read failure, `loadDashboard` clears the response, rows and selected record (LWC 453–458). HTML 138–149 replaces the cards with the unavailable state. `loadDashboard` catches its own error, so the successful save is not incorrectly reported as a rejected save, but the user receives no positive saved-state context for an ordinary checkbox.

**Recommendation:** retain the last known cards and the confirmed saved value if only the refresh fails; show a concise refresh error and make dependent actions wait for a successful reread where current eligibility matters. Distinguish this from an actual rejected write. The existing explicit-rejection path correctly rereads and restores the server value, which should be retained.

For a transport failure after commit, `saveFinanceChange` currently says `Update not saved` even when its recovery read proves the tick is true. The fault simulation reproduces that contradiction. If the outcome is initially unknown, say it could not be confirmed, then reconcile by reading. Do not automatically repeat a finance send to resolve an uncertain response. This is an error-state improvement, not evidence that real sends duplicated during this review.

### ME03 — Finance polling bypasses the save guard

**Impact:** after queuing a finance action on one card, its background polling can replace the list while a later checklist save on another card is still pending.

Focus/visibility refresh checks `isActionPending` before scheduling and again before loading (LWC 141–149). The finance timer directly calls `loadDashboard`, whose entry guard checks only communication state (LWC 421–422, 448–451). The inline reproduction confirms that a pre-existing finance timer starts a read during an unresolved checkbox write. The later write still reloads the dashboard, so this is not demonstrated data loss; it is avoidable display movement and competing refresh work.

**Recommendation:** apply a consistent pending-save rule to passive refreshes and defer/coalesce them until the save resolves. Any in-place save design must merge later responses without overwriting a pending value. Preserve the existing request-sequence protection that prevents an older response from replacing a newer one.

`disconnectedCallback` invalidates existing read requests and clears current timers, but an unresolved save can subsequently invoke a fresh read and recreate timers (LWC 108–121, 589–596). The inline reproduction confirms the fresh read after disconnection. Ignore post-disconnect UI work while allowing a submitted server mutation to finish. This is a lifecycle issue, not a reason to cancel or retry the underlying save.

### ME04 — A rejected stale receipt leaves the stale action in place

**Impact:** when another operator has already recorded a receipt or changed eligibility, the user can see the error and the same obsolete button until a later refresh.

The receipt handler's failure branch shows an error and clears loading, but does not reread the booking (LWC `handleMilestone`, 1084 onward). The reproduction that rejects with “already received” leaves `showMarkPaid` true. By contrast, the checklist failure path reloads.

**Recommendation:** after a server-reported stale-state rejection, reconcile the record and current refiner membership while preserving the surrounding position. Do not automatically retry the receipt or bypass the existing fresh-amount review. The server lock, amount comparison and already-received check are useful integrity protections; the missing recovery refresh is the issue.

### ME05 — The retired automated-pack `Queued` value falls between the joining refiners

**Impact:** a completed booking whose joining status is `Queued` is in all Completed bookings but in neither Joining instructions sent nor the unsent refiner.

`FINAL_PACK_DUE` excludes both `Sent` and `Queued`, while `FINAL_PACK_SENT` includes only `Sent` (Controller 1457–1459). The current manual marker writes `Sent` or null and queues no email (Finance 62–69). [NTE_Final_Pack_Status__c](../force-app/main/default/objects/Opportunity/fields/NTE_Final_Pack_Status__c.field-meta.xml) is an editable text field, also exposed on the Opportunity record page. The old `Queued` exclusion therefore has no corresponding current manual joining action that completes it.

**Recommendation:** the unsent refiner should consistently mean “manual Sent marker not recorded,” including any inherited `Queued` state. Confirm this as removal of an obsolete filter assumption; no mass rewriting or deletion of historical statuses is needed. This is a source-confirmed membership gap. No affected native record was asserted or changed in this review.

## Manual changes: recovery gaps versus agreed restrictions

| Concrete scenario | Current behaviour and evidence | Decision distinction |
| --- | --- | --- |
| The team sends a bank-transfer provisional email, then the applicant asks to use Stripe before paying. | The saved send timestamp remains. `canSendBase` requires it to be null, so the record stays out of Requirements and has no panel Stripe-send action (Controller 1229–1232 and finance formulas). The ordinary record Retry also refuses status `Sent` (Approval 76–90); its LWC calls that ordinary endpoint. | A real recovery gap if switching the payment route after sending must be supported. Define an explicit reviewed resend/reissue route that preserves the original request and recipient history. Do not clear sent timestamps merely to make a button appear. Supporting this is an additional exception decision, not blanket approval to add resends to Payment required. |
| Correct the primary Contact or email after a Stripe request exists, then retry a failed send. | Stripe fingerprints include recipient identity/email and compare the saved request before processing; a changed snapshot becomes Needs review or rejects top-up retry (Stripe 63–81, 298–328). | Preserving the original recipient/request identity is useful. Recovery needs a clear reviewed replacement procedure when the saved request is no longer right; silently changing its snapshot or loosening all recipient checks is not justified. The changed-price confirmation rule does not automatically approve new charge replacement. |
| A new unpaid top-up exists while the already-requested base payment arrives. | Requirements takes precedence while that top-up still needs its separate request. Payment receipt buttons are hidden in Requirements, including the original base receipt (LWC 472–473, 517–519; finance formulas). | This follows the explicitly agreed mutually exclusive refiners. If staff need to record the earlier receipt before sending the top-up request, decide how that exception is exposed. Do not classify the agreed stage presentation itself as a bug or add a stronger backend stage veto. |
| Change Invoice Requested, supplier agreement, PO/reference or Payment Method while another operator has the old checklist open. | `setRequirement` locks and rebuilds the applicable list before accepting that field. A now-inapplicable item rejects and the UI rereads. Existing provided flags are retained when preferences change; sends do not auto-complete them. | Appropriate stale-form revalidation. Automatically clearing or re-ticking provided flags would alter the independent-reminder model. If a new document version should invalidate an old tick, that needs its own decision. |
| Two operators update different requirements on the same booking. | The service locks the booking and writes only the requested checkbox and its own audit fields. It does not write an entire stale booking object (Finance 37–60). Same-value requests are no-ops. | Existing partial writes protect independent changes. There is no last-seen-field/version argument, so competing changes to the same field use the final successful write. Native concurrency was not tested here. If conflict feedback is wanted, target the same field; a blanket LastModifiedDate veto would unnecessarily block unrelated edits. |
| Manually edit request timestamps, a paid flag or its audit fields on the full record to move a booking to another refiner. | These fields are editable in the management permission set and record page. Finance membership derives from saved request/receipt facts. Setting a paid flag directly bypasses the controller action that also writes the receipt date/user and queues the confirmation; clearing a sent timestamp can make an already-sent booking eligible for another manual send. | These are facts with side effects in the action route, not interchangeable workflow-stage controls. Preserve manual correction capability, but define the supported correction procedure so a status change does not accidentally omit a confirmation or misstate its audit fields. This review does not recommend broadly locking staff out of the record. |

The single converted-application identity, correct commercial record type/source, active open/won scope, known coherent pricing and single primary Contact remain purposeful send guards. A missing or ambiguous Contact can be corrected, then the failed action retried. The review does not propose bypassing those checks or reviving declined self-service reductions/cancellation/refund automation.

## Visibility, reports and access

Manual edits to event code, owner, record type, source or closed-lost state can legitimately remove a booking from the current panel. The base query requires an NTE commercial application Opportunity with a nonblank event code and open/won status, plus the selected event/owner (Controller 1554–1564). Save endpoints recheck core eligibility. That protects against acting on an obsolete card; a refresh should explain a genuine move or provide a direct record link rather than silently selecting an unrelated card as though nothing happened.

The time filter means **CreatedDate**, even though the list is ordered by LastModifiedDate. An old booking edited today is still absent from Last 7 days. The weekly finance report means Last Update in the last seven days. These different date semantics are source-confirmed, not a newly observed record discrepancy. Keep operational work on All time when handling older bookings, and consider whether the time control needs a clearer label. Do not silently change its defined date basis.

The panel exposes at most **2,000** matching records in pages of **25**. It states “Latest 2,000 available” when capped, and the existing tests cover the cap and offset clamping. This is a real availability limit, not pagination data loss. If a working queue grows beyond it, use narrower event/owner filters or the wider report. A stable-order change must account for this server limit and page membership; it should not merely rearrange the displayed page or imply all matching records were loaded.

Finance reports 06 and 09 now constrain record type, commercial source, nonblank event code and open/won scope. The report link is a plain report URL and does not copy the panel's event, owner or refiner into report filters (Controller 1629–1638). **This is not flagged as a defect:** the desired workflow explicitly calls for the cross-event finance report as the wider reporting route. Report 09's last-update period also remains deliberate. Previous broader finance-source findings from the 13 September access audit have been corrected and should not be repeated as current defects.

The packaged `NTE_Management_Access` group contains `NTE_Management_User` and `NTE_Stripe_Test_Operator`. A source read confirmed explicit read/edit grants for the invoice preference, seven reminder checkboxes, quotation/invoice/top-up audit fields, joining marker/date/user and the request timestamps reviewed here; no missing permission entry was found for those dependencies. The 13–14 September release record separately records native Kate/Tony verification. This task did not rerun or extend that native access claim.

Exact dependencies matter if a later role is restricted:

- Finance's shared current-booking query reads its full `FIELDS` list, including billing/address/contact/procurement fields, even for a joining-marker write. It uses USER_MODE and Opportunity update access. Quote/invoice ticks also write their associated date and user fields; joining writes status, date and user together.
- The dashboard uses USER_MODE for the Opportunity fields, primary OpportunityContactRole/Contact read, dispatch reminder rollup and top-up payment-request status. The Contact query selects Name, FirstName, LastName, Email, Phone and MobilePhone ([NTEBookingContactService](../force-app/main/default/classes/NTEBookingContactService.cls), 11–23). Missing read access in a future custom role can fail the whole load, rather than merely hide one checklist column.
- Receipt preview additionally needs payment-request amount/identity/delivery fields, and the receipt write needs its date/user fields. Granting only a checkbox does not establish an operable custom role. Conversely, operators have read-only payment-request metadata permissions; manual workflow flexibility is not permission to rewrite Stripe request history.

These are documented access contracts and regression targets for a future custom role. They are not a present denial for the verified management group, and removing USER_MODE checks is not a remedy.

## Recommended UX behaviour to approve before implementation

1. **Checkbox work stays in place.** Keep the card's order, expanded details, the same checkbox focus and its visual position after a save. Capture a stable record/control identity and its viewport offset; restoring only the absolute scroll coordinate is insufficient when content above it changes. Do not scroll the whole panel to the top or force focus on passive refresh.
2. **Real progression still updates membership.** A successful send, receipt or joining marker may correctly move a record out of the current refiner. Remove it when the server confirms that transition, keep the nearest surviving neighbour in position, and provide concise outcome/record access. Do not leave it indefinitely in a refiner it no longer matches merely to preserve position.
3. **Refresh and save have clear ownership.** Reconcile successful writes in place, defer passive refresh during an unresolved write, ignore post-disconnect UI work, and retain usable context after a failed refresh. Read back an uncertain write before suggesting another action; never auto-repeat sends or receipts.
4. **Avoid extra workflow obstacles.** Retain independent ticks, manual joining and manual receipt flexibility. Per-control or per-card pending states could avoid disabling the whole panel for every tick, but require deliberate handling of overlapping saves; the existing global lock already prevents local duplicate clicks. This is an optional UX refinement, not a reason to introduce a new Save button or compulsory checklist completion.

Suggested later verification is narrow and relevant: keyboard and pointer ticking near the bottom of a long card; page-two edits; open long details; a queued send polling while another card is edited; refresh failure after a successful tick; a record leaving a filter; and two users changing the same versus different requirements. Confirm the resulting native focus/position, counts, selection and persisted values. Existing successful fixture sends, payments and conversions must not be replayed to test these behaviours.

## Source snapshot

SHA-256 at the review read boundary (the main task may subsequently change separate receipt/confirmation code):

| Source | SHA-256 |
| --- | --- |
| `nteMasterPanel.js` | `4e3648117c0d6941360facefddba0d0ab630fc1d12f5b04e78d2707cfd4c418c` |
| `nteMasterPanel.html` | `091ba4a1c79e8a08cdaf5b4d3bca9feff3f0d0b85ce3c77252e4ba255c44e14a` |
| `NTE_MasterPanelController.cls` | `9089185eadd1ced559cacf6a561e345971a3aea48a170c120fc2bbd3ca439771` |
| `NTEFinanceService.cls` | `f63423a47c76fb2ab2885715047e0db61e7ad8f0c6498b251f097aeab823d2c4` |
| `NTEStripeBookingService.cls` | `fcb3c506d63111dae3de20433151e8492adc5a76b047461e0050c335aa8ef3bf` |
