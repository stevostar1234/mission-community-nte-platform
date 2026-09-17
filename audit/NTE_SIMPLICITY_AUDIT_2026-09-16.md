# Whole-implementation simplicity and functional-risk audit

16 September 2026 · Internal review for the project owner · Findings only

## Overall assessment

**There are issues worth addressing. The clearest deployment blocker is an old charity-category check that still prevents some now-permitted £0 bookings from being confirmed.** Several other controls correctly stop unsafe work but leave ordinary corrections unnecessarily difficult. There are also separate correctness, maintenance and conditional volume risks.

I did **not** find a case for a wholesale rewrite, removing Salesforce access controls, replacing the Stripe integration, introducing a portal, or discarding the existing validation. Much of the defensive code protects real payment, recipient and historical-data boundaries. The useful simplicity work is narrower: remove stale business rules, separate unrelated responsibilities, and make legitimate recovery usable.

This review covers the **current working files, including uncommitted and untracked implementation**, rather than Git HEAD alone. Six domain reviews were consolidated and important cross-layer findings checked independently. No implementation, public pages, Salesforce configuration or business records were changed. No live submission, email, payment, conversion, deployment or historic test was replayed.

Each recommendation below identifies what it must preserve and how it should be verified. These are bounded proposed fixes, not a claim that unimplemented changes have zero regression risk. **We should select changes together before implementation.**

## Priority order

- **P1:** resolve before deployment of the affected workflow.
- **P2:** important operational risk; fix or agree a concrete operating limit/workaround before the affected use.
- **P3:** smaller, infrequent or future maintenance improvement.
- **Confirmed** means the behaviour is established in source or an isolated probe. It does not mean a real applicant experienced it.
- **Conditional** identifies the necessary trigger, such as an administrative edit, delayed job, large dataset or particular merchant setting.

S/O/C/R identifiers belong to this report. They do not renumber existing proposals, the September F/P/U audit, or the 15 September R-numbered restrictions. Existing P10 remains declined.

The table is the overall review order; detailed findings are split into simplicity/control issues and other problems as requested.

| Order | ID | Priority | Finding / exposure |
|---:|---|---|---|
| 1 | S01 | P1 | Old charity rule blocks valid free-space confirmation. |
| 2 | O01 | P2 | A delayed preparation job can overwrite a newer manual correction. |
| 3 | O02 | P2 | Clearing a top-up quantity can let a later form reset paid history. |
| 4 | S02 | P2 | Correcting the Primary Contact can strand an unsuccessful Stripe request. |
| 5 | S03 | P2 | The 23-hour hold also blocks failures that occurred before any creation request. |
| 6 | O03 | P2 | Missing/startup-failed JavaScript leaves an apparently usable form without working submission. |
| 7 | O04 | P2 | Retrying an intake email can undo staff reassignment of the Lead. |
| 8 | O05 | P2 | A valid 256–1,000-character Lead note cannot fit its conversion destination. |
| 9 | O06 | P2 | A relationship-card load failure can leave the previous record's contacts visible. |
| 10 | O07 | P2, administrative | Dispatch-record retry can ignore evidence that a confirmation was already accepted. |
| 11 | S04 | P2, volume | More than 500 matches can prevent opening the reminder recipient selector. |
| 12 | S05 | P2, bulk import | More than 100 supplementary acknowledgements causes every receipt to fail locally. |
| 13 | S06 | P2, volume/content | A small page loads/enriches all earlier rows; Home loads the whole event. |
| 14 | S07 | P2, recovery friction | Exceptional payment receipt needs manual field edits and a separate retry. |
| 15 | O08 | P2, native entry | A manually entered application can convert without a usable booking reference. |
| 16 | O09 | P2, known limit | The thank-you screen cannot distinguish acceptance from rejection. |
| 17 | O10 | P2 | The standard validation command omits strong existing tests. |
| 18 | O11 | P2 | Active handover instructions retain superseded restrictions/status. |
| 19 | O12 | P2 if executed | A dormant broad backfill can overwrite agreed prices and misreport success. |
| 20 | O13 | P2, policy decision | Future-year records can change the default working event. |
| 21 | C01–C04 | P2, policy review | PO timing, logistics requirements, volunteer choices and classification questions can exclude legitimate answers. |
| 22 | R02 | P2 if applicable | A legitimate Stripe custom payment domain is rejected. |
| 23 | S08–S11, O14–O20, C05 | P3 | Smaller recovery, display, source-ownership and conditional integration issues. |

## A. Simplicity, excessive restrictions and recovery

### S01 — An obsolete category check blocks valid complimentary confirmations

**P1 · Confirmed defect · Conflicts with approved proposal 23.**

The browser and pricing service permit every organisation category to request either free space. The email service still permits a naturally free booking only when the charity category matches the old charity-space pairing. Requirements offers Confirm Free space, but the worker rejects its valid price. The same helper also controls template choice, payment wording and top-up eligibility.

**Example / consequence:** an Employer - Automotive Sector organisation requests COBSEO Charity - Single - Free, two staff and no power. Staff approve it. Pricing and conversion produce £0, but Confirm Free space fails with “The booking price needs review.” No confirmation is sent, the free-confirmation marker remains false, and normal completion is blocked. Selecting the other charity-labelled space can also fail for a charity. This can encourage staff to misclassify a valid organisation to bypass the error.

**Evidence:** [obsolete helper](</Users/stevo/Downloads/mission community updated datamodel/force-app/main/default/classes/NTEExhibitorApprovalEmailService.cls:642>), [saved-price veto](</Users/stevo/Downloads/mission community updated datamodel/force-app/main/default/classes/NTEExhibitorApprovalEmailService.cls:469>), [template selection](</Users/stevo/Downloads/mission community updated datamodel/force-app/main/default/classes/NTEExhibitorApprovalEmailService.cls:463>), [manual action](</Users/stevo/Downloads/mission community updated datamodel/force-app/main/default/classes/NTEFinanceService.cls:79>), [top-up dependency](</Users/stevo/Downloads/mission community updated datamodel/force-app/main/default/classes/NTEStripeBookingService.cls:285>). Current [inert payload evidence](</Users/stevo/Downloads/mission community updated datamodel/tmp/simplicity-audit-20260916/forms-probes.json>) confirms both free choices submit with net zero, hidden finance and no payment method for that real permitted category.

**Smallest safe fix:** remove only the superseded category conjunction from the shared complimentary rule. Retain recognised free-space choices, coherent saved totals, Calculated status, explicit full waivers, human confirmation, Primary Contact routing and duplicate protection. Update every use of the helper; changing just the error check would leave template selection wrong. Preserve the separate category-based socket discount.

**Verify:** all 19 categories × both free spaces through downstream confirmation, not just pricing; free space with paid extras; paid and waived bookings of both types; unknown/inconsistent zero prices still refused; correct HTML/text and one accepted confirmation. Do not reprice or reclassify existing records.

### S02 — Recipient corrections are mixed into immutable Stripe charge identity

**P2 · Confirmed recovery restriction; triggered by a recipient change after request creation.**

The saved request fingerprint combines the financial/provider identity with Contact ID/email. A stale email should be held, but retry compares against the same old fingerprint indefinitely. There is no supported same-charge rebind to the corrected Primary Contact. A base booking may use the agreed manual/bank alternative; a Stripe-only top-up has less convenient recovery.

**Example / consequence:** a £120 staff top-up request fails before its email is accepted. Staff correct accounts@exmaple.org to accounts@example.org. Send Stripe link now continually reports changed booking/configuration even though the purchase is unchanged. Restoring the typo or editing a hash is not an acceptable workaround.

**Evidence:** [base fingerprint](</Users/stevo/Downloads/mission community updated datamodel/force-app/main/default/classes/NTEStripeBookingService.cls:143>), [base mismatch](</Users/stevo/Downloads/mission community updated datamodel/force-app/main/default/classes/NTEStripeBookingService.cls:75>), [top-up fingerprint/retry](</Users/stevo/Downloads/mission community updated datamodel/force-app/main/default/classes/NTEStripeBookingService.cls:301>).

**Bounded fix:** separate charge identity from the email-recipient snapshot. Extend the existing failed/unsent action to deliberately verify and rebind the same request to the current Primary Contact, under the booking lock. Keep the same operation key, Price and Link IDs and preserve old/new recipient evidence. Handle existing saved fingerprints explicitly; do not blanket-recompute historical hashes.

**Verify:** corrected email and changed Primary Contact before/after provider verification; failed versus accepted send; a second contact change during retry; amount/account/mode/currency changes still held; no new charge or second base confirmation. Existing successful-email copies remain manual forwarding. Related to the earlier manual-exceptions review and proposal 22 recovery principles.

### S03 — The 23-hour safety window starts before an external creation attempt

**P2 · Confirmed mechanism; conditional on a delayed retry or queue.**

First Attempt is set when Salesforce saves/queues the request. Once it is more than 23 hours old, a missing Link ID triggers reconciliation even when the only attempt failed during GET-only account/connection checks, before any creation POST.

**Example / consequence:** Friday's account check fails because of a credential permission. It is repaired on Monday. Retry still refuses to proceed because the request is old, although that attempt never created a Price or Payment Link. A normal connection repair becomes specialist reconciliation.

**Evidence:** [timestamp creation](</Users/stevo/Downloads/mission community updated datamodel/force-app/main/default/classes/NTEStripeBookingService.cls:95>), [cutoff before preflight/create](</Users/stevo/Downloads/mission community updated datamodel/force-app/main/default/classes/NTEStripeBookingService.cls:203>), [GET-only preflight](</Users/stevo/Downloads/mission community updated datamodel/force-app/main/default/classes/NTEStripeClient.cls:34>).

**Bounded fix:** distinguish a conclusively never-started/pre-creation failure from a possibly successful external write. Allow a fresh window only for proven no-write work, with no earlier ambiguous attempt. Preserve the existing queue/callout transaction boundary: do not introduce a database write immediately before an Apex callout. An unknown crash/timeout must remain conservative, even if a later GET fails.

**Verify:** GET-only failure followed by a 24+ hour retry; delayed unstarted work; Price/Link POST timeout; crash after external creation but before local save; earlier ambiguous attempt followed by preflight failure; known IDs reused after days. Keep the hold for genuinely unknown old outcomes: [Stripe documents that idempotency keys may be removed after at least 24 hours](https://docs.stripe.com/api/idempotent_requests).

### S04 — The recipient limit prevents access to the control that could reduce the selection

**P2 · Confirmed refusal; conditional on more than 500 matching records.**

The panel fetches 501 IDs and refuses the whole reminder operation before opening selection. The available filters cannot always make a smaller set, and there is no individual reminder action.

**Example / consequence:** 501 bookings need logos, all for the same event, created on the same day and owned by the same person. Every useful filter leaves 501 or zero. “Narrow the filters” is ineffective, and staff cannot open the chooser to select even one recipient.

**Evidence:** [501-ID query](</Users/stevo/Downloads/mission community updated datamodel/force-app/main/default/classes/NTE_MasterPanelController.cls:607>), [pre-selection refusal](</Users/stevo/Downloads/mission community updated datamodel/force-app/main/default/lwc/nteMasterPanel/nteMasterPanel.js:1008>), [in-memory reproduction](</Users/stevo/Downloads/mission community updated datamodel/tmp/simplicity-audit-20260916/staff-ui-probes.json>).

**Smallest safe fix:** retain the send/content limits but allow a deliberately selected page/subset, or an individual reminder using the existing reviewed composer. Do not silently take the first 500 or automatically widen/send the remainder.

**Verify:** 0/1/500/501 matches, a same-day/same-owner population, exact reviewed IDs, permissions, stale eligibility and duplicate sends. This extends the known P05/P06 volume limits; no present 501-booking outage was observed.

### S05 — The supplementary email cap fails the entire batch

**P2 · Confirmed code branch; bulk/import exposure.**

More than 100 supplementary acknowledgements causes all of them to be marked Failed. Below the ceiling, ten-message batches consume up to ten send invocations. The NTE/volunteer intake senders already use a less wasteful collection approach.

**Example / consequence:** an import creates 101 valid staff updates in one trigger batch. Booking data can save, but all 101 acknowledgements fail locally, creating unnecessary manual recovery. This does not mean 101 independent public submissions automatically form one such job.

**Evidence:** [ceiling and batching](</Users/stevo/Downloads/mission community updated datamodel/force-app/main/default/classes/NTEUpdateSubmissionService.cls:625>), [constants](</Users/stevo/Downloads/mission community updated datamodel/force-app/main/default/classes/NTEUpdateSubmissionService.cls:8>).

**Bounded fix:** process bounded receipt chunks with durable outcomes and continue the remaining intended sends. Consolidate a supported chunk into one sendEmail call. Never reapply booking data or resend an already accepted receipt. [Salesforce recommends collecting messages and sending outside the loop](https://help.salesforce.com/s/articleView?id=000385111&language=en_US&type=1); separate daily, recipient and memory limits still apply.

**Verify:** 99/100/101/200, partial send failures, continuation failure, existing invocation usage, exact-once acceptance and cleanup after audit persistence. Prior mocks of hundreds of messages are not proof of unlimited native sending. This is the retained supplementary part of P05.

### S06 — Small pages do unnecessarily large amounts of work

**P2 · Confirmed algorithm; performance failure threshold not measured.**

At offset 975, the 25-row page retrieves and constructs 1,000 records, resolves their contacts and loads billing details before discarding the first 975. Some billing fields allow 32,768 characters. Home separately loads every matching event Lead/Opportunity into memory. Master Panel navigation is capped at 2,000.

**Example / consequence:** page 40 with lengthy legitimate procurement notes may become slow or exhaust memory although staff see only 25 rows. Above 2,000 matching records, older work cannot be reached in that panel. No exact production failure volume is claimed.

**Evidence:** [page retrieval/enrichment](</Users/stevo/Downloads/mission community updated datamodel/force-app/main/default/classes/NTE_MasterPanelController.cls:1060>), [full-event Home reads](</Users/stevo/Downloads/mission community updated datamodel/force-app/main/default/classes/NTE_MasterPanelController.cls:442>), [2,000 boundary](</Users/stevo/Downloads/mission community updated datamodel/force-app/main/default/classes/NTE_MasterPanelController.cls:1571>).

**Bounded fix:** first select page IDs/sort keys and enrich only the displayed records. Use aligned server aggregates for Home. Consider cursor paging only if the expected volume requires removing the existing ceiling; simply raising limits is not a fix.

**Verify:** exact counts/amounts against all nine reports, stable newest-created Requirements order, equal timestamps, moved/deleted rows, long data, permissions and independent base/top-up money. Profile a representative synthetic volume before promising capacity. This is P06 with a specific unnecessary-work cause, not a reason to rewrite the whole controller.

### S07 — The normal payment action is unavailable for an accepted exception

**P2 · Recovery friction; a manual workaround exists.**

The backend permits payment receipt while the provisional email failed. The panel hides receipt actions until the request-sent state and Payment required view apply. Another charge still in Requirements can also hide the normal receipt action.

**Example / consequence:** staff have verified a bank payment after the provisional email failed. Instead of the usual amount-review/receipt action, they must edit the payment flag and its audit fields on the full record and then use Retry Booking Email. Forgetting the second step leaves the confirmation unsent; omitting date/by fields makes the history incomplete.

**Evidence:** [UI eligibility](</Users/stevo/Downloads/mission community updated datamodel/force-app/main/default/classes/NTE_MasterPanelController.cls:1314>), [backend allows receipt](</Users/stevo/Downloads/mission community updated datamodel/force-app/main/default/classes/NTE_MasterPanelController.cls:826>), [existing missing-confirmation recovery](</Users/stevo/Downloads/mission community updated datamodel/force-app/main/default/classes/NTEBookingEmailRetryService.cls:24>).

**Bounded fix:** expose a contextual full-record receipt action that reuses the existing amount review, locked save, timestamps and confirmation queue. Preserve ordinary stage-specific controls; this is an explicit exception route, not a new requirement checklist or automatic payment confirmation.

**Verify:** failed provisional, base receipt while top-up remains in Requirements, changed reviewed amount, missing Primary Contact, already-paid and Closed Lost cases. Payment must persist if notification fails. The latest recovery rule supports the exception; UI placement still needs selection.

### Smaller simplicity opportunities

| ID / priority | Issue and concrete consequence | Bounded remedy and checks |
|---|---|---|
| **S08 · P3** | [Stripe errors](</Users/stevo/Downloads/mission community updated datamodel/force-app/main/default/classes/NTEStripeClient.cls:220>) retain only HTTP status and generic guidance. A missing permission and provider incident can look alike, making ordinary repair slower. | Save an internal safe Request-Id, operation stage and whitelisted error code. Keep credentials/raw bodies/personal data out. Test permission, validation, rate-limit, timeout and malformed responses. |
| **S09 · P3** | A failed invitation/reminder whose recipient or merged details change becomes Skipped and requires reconstructing a fresh draft; it leaves the Failed list. A corrected typo can lose convenient access to custom wording. [Retry path](</Users/stevo/Downloads/mission community updated datamodel/force-app/main/default/classes/NTEEmailDispatchService.cls:301>). | Offer a fresh reviewed draft seeded from the unsent message and a relevant needs-attention link. Keep old history, current eligibility and deliberate sending. Do not automatically redirect frozen messages or resend accepted ones. Check changed recipient/link and completed preparation. |
| **S10 · P3** | [Old reminder APIs](</Users/stevo/Downloads/mission community updated datamodel/force-app/main/default/classes/NTE_MasterPanelController.cls:703>), obsolete invoice-action branches and [redundant post-USER_MODE stripping](</Users/stevo/Downloads/mission community updated datamodel/force-app/main/default/classes/NTERelatedOpportunityController.cls:169>) add alternate paths/copies. A maintainer can fix the unused 100-recipient route while the actual 500-recipient composer remains unchanged. No access failure caused by the extra stripping was proved. | Inventory real callers, including target automation, before retiring unused paths. Keep one explicit read-access strategy, current receipt actions and historic fields. Run current UI/dispatch/access tests. This can wait; file size alone is not a defect. |
| **S11 · P3, conditional** | The [offscreen honeypot](</Users/stevo/Downloads/mission community updated datamodel/assets/forms.js:774>) rejects any value and tells the user to reload. An aggressive autofill extension could repeatedly fill it with no visible recovery. The branch is proved; a real autofill occurrence is not. | Reproduce with relevant autofill software before changing the guard. If needed, correct autofill semantics or provide a value-preserving retry. Preserve bot handling and no duplicate POST; do not add CAPTCHA/login to solve this uncertainty. |

## B. Other functional and implementation problems

### O01 — Delayed preparation writes can replace newer staff corrections

**P2 · Source-confirmed timing vulnerability; no new live race reproduction.**

An update is saved Pending, then applied by a later job. The worker sorts only its own payload and unconditionally writes the roster/full logistics replacement under a lock. A lock prevents simultaneous writes; it does not prove the old source is still current.

**Example / consequence:** a lorry form waits in the queue. The organiser phones with a correction, and staff save the new registration on the booking. The delayed form later replaces it with the old registration and records the current processing time. Two separately queued forms processed in the opposite effective order have a related risk.

**Evidence:** [queue creation](</Users/stevo/Downloads/mission community updated datamodel/force-app/main/default/classes/NTEUpdateSubmissionService.cls:84>), [apply and processing timestamp](</Users/stevo/Downloads/mission community updated datamodel/force-app/main/default/classes/NTEUpdateSubmissionService.cls:252>), [full vehicle replacement](</Users/stevo/Downloads/mission community updated datamodel/force-app/main/default/classes/NTEUpdateSubmissionService.cls:498>). [Salesforce's asynchronous timing is not guaranteed](https://help.salesforce.com/s/articleView?id=000384188&language=en_US&type=1).

**Fix to qualify:** preserve freshness per update topic under the existing booking lock, including relevant manual corrections as well as newer forms, and retain conflicting old submissions for staff review. A global LastModifiedDate veto would wrongly block a roster because someone ticked a finance box. Alternatively, applying data in the original transaction and deferring only email/cleanup could remove the late-write phase, but that is a larger transaction change and should not be slipped into a pre-release patch.

**Verify:** delayed form versus manual correction; two rapid forms; independent staff/vehicle/logo updates; first top-up order; data survives email failure; no blind replay. Preserve the approved full-replacement semantics and manual/fresh-form recovery. A proposed freshness rule must not silently discard an older genuine top-up purchase.

### O02 — A mutable quantity is being used as proof that no top-up purchase exists

**P2 · Conditional on a manual/integration quantity edit.**

The top-up guard treats null/zero current count as no previous purchase. The apply path then initialises charges, increments attendance and clears receipt/invoice facts, even if accepted request/payment history already exists.

**Example / consequence:** two extra places are paid. Staff accidentally clear the optional quantity while editing. A subsequent positive two-place names correction is treated as a first purchase: the local paid flag/date/user can be cleared and attendance incremented again.

**Evidence:** [initialisation and resets](</Users/stevo/Downloads/mission community updated datamodel/force-app/main/default/classes/NTEUpdateSubmissionService.cls:358>), [quantity-only guard](</Users/stevo/Downloads/mission community updated datamodel/force-app/main/default/classes/NTEUpdateSubmissionService.cls:447>), [editable field permission](</Users/stevo/Downloads/mission community updated datamodel/force-app/main/default/permissionsets/NTE_Management_User.permissionset-meta.xml:1032>).

**Bounded fix:** recognise an accepted purchase using durable accepted/request/receipt facts, not mutable count alone. If they disagree, preserve money/history and permit safe names-only correction while exposing the quantity inconsistency for staff repair. Do not add a blanket ban on manual edits.

**Verify:** accepted unpaid/paid/requested top-ups with null/zero count; genuine first purchase; same-quantity and No/name-only corrections; attendance and history preserved; concurrent first purchases and Closed Lost.

**Important limit:** the retained Stripe request guard can still prevent a second provider link. This finding demonstrates possible local-history/reporting corruption, **not a demonstrated duplicate Stripe charge**.

### O03 — Forms have no safe initial state when their engine fails to load

**P2 · Conditional trigger; confirmed markup/startup behaviour.**

All ten forms initially have enabled submit controls, no action/method and no static unavailable state. Most data controls have data-sf-field rather than native submission names. The correct POST depends on JavaScript installing its handler.

**Example / consequence:** the logo page loads but forms.js fails. An applicant completes the five questions and clicks Confirm logo upload. Native fallback navigates to the same page with a GET; it does not submit the booking confirmation to Salesforce. Other forms may instead block on conditional questions that JavaScript never hid.

**Evidence:** [logo markup](</Users/stevo/Downloads/mission community updated datamodel/logo-upload.html:11>), [handler installation](</Users/stevo/Downloads/mission community updated datamodel/assets/forms.js:763>), [native POST construction](</Users/stevo/Downloads/mission community updated datamodel/assets/forms.js:704>).

**Smallest safe fix:** disable submission until handler installation/setup succeeds, with a concise static loading/unavailable state and no-JavaScript contact route. Preserve entered values on normal transport errors. No second API, framework or draft database is needed.

**Verify:** blocked/missing script, missing config, initialiser exception, normal load and Back/forward restoration in a real browser as well as the inert model. Enable only after complete setup; preserve accessible status and duplicate-click handling.

### O04 — Retrying an intake notification also changes ownership

**P2 · Confirmed retry call chain; previously noted and still present.**

Retry email passes isNewSubmission=false, but the inbound service still assigns pending Leads back to the configured central owner.

**Example / consequence:** an EOI is assigned to Kate. After she fixes an email typo, Retry email sends the acknowledgement and moves the Lead away from her. It can vanish from her filtered queue or be worked twice.

**Evidence:** [retry request](</Users/stevo/Downloads/mission community updated datamodel/force-app/main/default/classes/NTELeadEmailRetryService.cls:69>), [unconditional reassignment](</Users/stevo/Downloads/mission community updated datamodel/force-app/main/default/classes/NTEInboundLeadService.cls:109>).

**Smallest safe fix:** limit initial owner assignment to actual new intake. Preserve current OwnerId on retries. Keep the existing initial routing and internal-recipient policy unless separately changed.

**Verify:** applicant-only/internal-only failure after reassignment, accepted sides not resent, EOI decisions preserved, no-op retry causes no owner write. This does not authorise changing the global owner override.

### O05 — Lead and Opportunity text capacities disagree

**P2 · Confirmed metadata and direct assignment.**

Exhibitor Space Position is LongTextArea(1,000) on Lead and Text(255) on Opportunity. Conversion copies it unchanged.

**Example / consequence:** a 300-character placement note saves on a native Lead but cannot fit the booking field during conversion. Approval is blocked until staff shorten or relocate the valid note.

**Evidence:** [Lead field](</Users/stevo/Downloads/mission community updated datamodel/force-app/main/default/objects/Lead/fields/Exhibitor_Space_Position__c.field-meta.xml:5>), [Opportunity field](</Users/stevo/Downloads/mission community updated datamodel/force-app/main/default/objects/Opportunity/fields/NTE_Exhibitor_Space_Position__c.field-meta.xml:5>), [Flow copy](</Users/stevo/Downloads/mission community updated datamodel/force-app/main/default/flows/NTE_Copy_Converted_Lead_to_Opportunity.flow-meta.xml:172>), [generator](</Users/stevo/Downloads/mission community updated datamodel/scripts/build-metadata.js:270>).

**Bounded fix:** preserve the full note in an appropriately sized destination and update the generator. Check target dependencies before changing Text to LongTextArea; use an appropriate additive destination if formulas/reporting prevent conversion. Do not truncate or shrink existing Lead data.

**Verify:** 255/256/1,000 characters, multiline text, normal web applications, current space-price choice, generated metadata and target formulas/reports/layouts. The independent [mapping-capacity check](</Users/stevo/Downloads/mission community updated datamodel/tmp/simplicity-audit-20260916/conversion-mapping-capacities.json>) corroborates this mismatch.

### O06 — Relationship cards retain old data after a load failure

**P2 · Reproduced with current LWC methods in memory.**

The error handler sets an error but does not clear the previous account, contacts, opportunities or display mode. Those values render independently of the error.

**Example / consequence:** the component loads booking A, receives booking B's record ID, and B's load fails. A's contact links can remain under B's record context, creating a wrong-person lookup/contact risk.

**Evidence:** [wire handler](</Users/stevo/Downloads/mission community updated datamodel/force-app/main/default/lwc/nteRelatedOpportunities/nteRelatedOpportunities.js:30>), [independent rendering](</Users/stevo/Downloads/mission community updated datamodel/force-app/main/default/lwc/nteRelatedOpportunities/nteRelatedOpportunities.html:54>), [probe](</Users/stevo/Downloads/mission community updated datamodel/tmp/simplicity-audit-20260916/staff-ui-probes.json>).

**Smallest safe fix:** bind displayed state to its loaded record/object identity. Clear different-record data on context change/error and provide a retry. Retain same-record stale data only if clearly marked. Keep existing sharing/FLS.

**Verify:** A→B success/error, initial error, same-record refresh failure and recovery, plus actual Lightning navigation. No schema or business-workflow change is required.

### O07 — Retry endpoints disagree about previously accepted mail

**P2 · Administrative recovery case, not ordinary double-click duplication.**

Opportunity Retry Booking Email treats either Sent status or Sent At as accepted evidence. Dispatch-record Retry email checks only Failed status, despite reading Sent At. Its worker/history path also relies on current status.

**Example / consequence:** an administrator changes an accepted confirmation's status to Failed after a delivery complaint, preserving its accepted timestamp. The Opportunity action says to forward the original, but the dispatch action can queue/send it again and replace the timestamp.

**Evidence:** [correct Opportunity guard](</Users/stevo/Downloads/mission community updated datamodel/force-app/main/default/classes/NTEBookingEmailRetryService.cls:43>), [dispatch retry](</Users/stevo/Downloads/mission community updated datamodel/force-app/main/default/classes/NTEEmailDispatchService.cls:278>), [current test of the administrative scenario](</Users/stevo/Downloads/mission community updated datamodel/force-app/main/default/classes/NTEBookingEmailRetryServiceTest.cls:127>).

**Smallest safe fix:** share the accepted-send predicate across retry availability, retry execution and worker execution. Preserve accepted timestamps even if status was manually changed. Return the existing forwarding guidance.

**Verify:** Sent→Failed with timestamp through both endpoints and worker; real failed-before-acceptance recovery; contact correction; new reminder runs remain allowed. Normal operators' dispatch layout is read-only, which limits exposure.

### O08 — Native application entry can create a reference-less booking

**P2 if native NTE application entry is used; browser-created applications already generate a reference.**

The optional Lead Booking Reference is supplied by browser JavaScript. Initial routing and conversion do not fill a missing value; conversion copies it blank, and downstream email/matching then refuses it.

**Example / consequence:** staff record a telephone application directly in Salesforce with valid catalogue/event/finance details. It saves and converts, but the booking email fails and there is no usable reference for preparation forms.

**Evidence:** [browser generation](</Users/stevo/Downloads/mission community updated datamodel/assets/forms.js:272>), [optional field](</Users/stevo/Downloads/mission community updated datamodel/force-app/main/default/objects/Lead/fields/Booking_Reference__c.field-meta.xml:8>), [conversion copy](</Users/stevo/Downloads/mission community updated datamodel/force-app/main/default/flows/NTE_Copy_Converted_Lead_to_Opportunity.flow-meta.xml:60>), [downstream rejection](</Users/stevo/Downloads/mission community updated datamodel/force-app/main/default/classes/NTEExhibitorApprovalEmailService.cls:288>).

**Bounded fix:** if native entry is supported, generate a valid unique reference only when absent on a new NTE application. Preserve supplied browser and historical references; exclude volunteers. Otherwise explicitly document the supported entry path.

**Verify:** native exhibitor/partner entry, bulk uniqueness, supplied reference unchanged, conversion and later matching, no historical backfill or extra sends.

**Related boundary:** manually creating an Opportunity directly is a different case. The initial Stripe/bank/free booking email action requires one retained converted application Lead; payment-confirmation and reminder routes are separate. Preserve those source Leads; adding source-less booking/import support is a separate scope, not implied by supplementary manual recovery. [Source dependency](</Users/stevo/Downloads/mission community updated datamodel/force-app/main/default/classes/NTEExhibitorApprovalEmailService.cls:100>).

### O09 — A positive-looking receipt is not an acceptance result

**P2 · Existing P02/P17 limitation, still relevant.**

Web-to-Lead supplies a static return URL. Neither it nor the thank-you page verifies Lead creation or application of a supplementary update.

**Example / consequence:** an applicant uses a well-formed but incorrect booking reference and sees Submission received, while their update remains unapplied. A platform rejection before Lead creation cannot appear in Update issues at all. The earlier audit proved an obsolete-picklist rejection; this review did not reproduce a new valid-form loss.

**Evidence:** [transport](</Users/stevo/Downloads/mission community updated datamodel/assets/forms.js:704>), [receipt copy](</Users/stevo/Downloads/mission community updated datamodel/thank-you.html:13>), [issue scope](</Users/stevo/Downloads/mission community updated datamodel/force-app/main/default/classes/NTE_MasterPanelController.cls:1142>).

**Proportionate remedy:** make receipt copy accurately describe submission/processing and provide a support route; define staff follow-up for matched and unmatched failures. Keep manual correction/fresh submission. Guaranteed applicant-visible acceptance would need a separately designed status service; copy alone cannot deliver it.

**Verify:** applied, retained-rejected, acknowledgement-failed and no-Lead-created cases. Owner must choose permitted rejection recipients/content. Do not silently send booking details to a submitter or add back the removed application-received emails.

### O10 — The normal validation command leaves existing regression tests unused

**P2 · Confirmed by an isolated mutation experiment.**

npm test / npm run validate omit the full form stress suite, 89 panel behavioural tests, generated metadata/report checks, shared-picklist and Stripe-preflight suites. Email asset/presentation tests are already included through forms.test.js.

**Example / consequence:** in the isolated copy, removing the panel's server-corrected page-offset assignment still left npm test green; the existing targeted panel test failed. Following the usual release command can therefore miss an already-tested pagination defect.

**Evidence:** [package scripts](</Users/stevo/Downloads/mission community updated datamodel/package.json:5>), [documented release command](</Users/stevo/Downloads/mission community updated datamodel/PRODUCTION_PACKAGE_SYNC.md:33>), [experiment/results](</Users/stevo/Downloads/mission community updated datamodel/tmp/simplicity-audit-20260916/omitted-suite-offset-mutation-proof.json>).

**Smallest safe fix:** one release test entry point should run the existing independent suites, including the metadata --generated branch. Keep a faster development command if useful. No new framework or live replay is required.

**Verify:** every intended test file is covered; an injected failure propagates a nonzero exit; no submission/backfill/deployment runner is included. The complete existing suites pass today.

### O11 — Active handover documents contradict the completed workflow

**P2 · Confirmed documentation defect.**

The active Stripe handover still says changed totals block confirmation and need a further reconciliation decision. It also calls completed invoice work “in progress”; other active guides repeat that status.

**Example / consequence:** after an agreed price adjustment and external settlement, a colleague reads the old instructions and avoids the supported current-price confirmation action, or a maintainer restores the old veto.

**Evidence:** [Stripe handover](</Users/stevo/Downloads/mission community updated datamodel/NTE_STRIPE_CLIENT_HANDOVER_2026-09-11.md:145>), [same table](</Users/stevo/Downloads/mission community updated datamodel/NTE_STRIPE_CLIENT_HANDOVER_2026-09-11.md:160>), [current confirmed rule](</Users/stevo/Downloads/mission community updated datamodel/NTE_DESIRED_WORKFLOW.md:139>).

**Smallest safe fix:** correct operative instructions and link changing release status to one current checkpoint. Preserve immutable dated audits and explicitly historical reconstruction manuals. Do not change implementation to match stale prose.

**Verify:** active guides agree on silent conversion, independent invoice/requirements, Amount-only adjustment, current-price receipt, one top-up and manual joining instructions. No org operation is needed.

### O12 — The retained pricing backfill is dangerous if treated as a routine tool

**P2 when executed · Dormant administrative risk; current instructions already warn against routine use.**

The script selects all supported application Leads/Opportunities. Recalculation can replace catalogue prices, VAT, adjustment and Amount, including historical or paid bookings. Partial-save results are ignored, while selected counts are logged as “updated”.

**Example / consequence:** a booking agreed at £600 gross, with original £799 net items and a −£299 adjustment, can become £958.80 with adjustment zero while old receipt facts remain. Another row may fail to save and still be counted as updated.

**Evidence:** [unbounded script](</Users/stevo/Downloads/mission community updated datamodel/scripts/post-deploy/backfill-nte-pricing.apex:3>), [ignored save results](</Users/stevo/Downloads/mission community updated datamodel/force-app/main/default/classes/NTEPricingService.cls:132>), [amount/adjustment replacement](</Users/stevo/Downloads/mission community updated datamodel/force-app/main/default/classes/NTEPricingService.cls:220>), [existing warning](</Users/stevo/Downloads/mission community updated datamodel/SALESFORCE_DEPLOYMENT.md:73>).

**Bounded fix:** retire it from ordinary post-deploy tooling or require an approved exact ID list and default to no-write preview. Report each SaveResult. Any historical migration should be designed from actual old/new facts rather than an expanding set of guessed exclusions.

**Verify:** empty scope cannot write, dry run makes no changes, permitted rows reconcile, partial failures are truthful, paid/adjusted/waived/top-up history preserved unless that exact migration is approved. Do not run it to test this report. Related to P14.

### O13 — Default event selection follows the highest year, not the working edition

**P2, conditional · Existing P16 policy decision.**

**Example / consequence:** a future NTE2028 EOI is entered while staff work on NTE2027. Fresh Home/Master navigation selects 2028 and current work appears absent until the selector is noticed. Previous dummy cleanup removed that symptom, not its underlying rule.

**Evidence:** [sort and resolver](</Users/stevo/Downloads/mission community updated datamodel/force-app/main/default/classes/NTE_MasterPanelController.cls:1629>), [default choice](</Users/stevo/Downloads/mission community updated datamodel/force-app/main/default/classes/NTE_MasterPanelController.cls:1685>).

**If selected:** prefer an explicitly maintained current edition while preserving deliberate historic/future selection. Verify empty/inaccessible configured events, explicit filters and rollover. Do not restore an invitation-year gate or invent a current edition without an owner decision.

### Smaller correctness and maintenance issues

| ID / priority | Issue and concrete consequence | Bounded remedy and checks |
|---|---|---|
| **O14 · P3, rare queue case** | [Job ID is discarded](</Users/stevo/Downloads/mission community updated datamodel/force-app/main/default/classes/NTEUpdateSubmissionService.cls:94>), and the [finalizer starts inside execute](</Users/stevo/Downloads/mission community updated datamodel/force-app/main/default/classes/NTEUpdateSubmissionJob.cls:18>). A job cancelled before starting can leave Pending outside Update issues. Error writers also ignore failed saves. | Retain job identity and expose aged Pending for inspection, or provide an owned administrative Pending view. Distinguish queued/running from aborted. Check failure SaveResults; no automatic replay. Test before-start cancellation and after-start failure. The current finalizer does exist; most of older AUTO-04 is fixed. |
| **O15 · P3, scale** | [Related queries cap at 200](</Users/stevo/Downloads/mission community updated datamodel/force-app/main/default/classes/NTERelatedOpportunityController.cls:83>) without a hasMore/continuation indicator. A 201st organisation booking can disappear from an apparently complete relationship list. | Fetch one extra indicator and provide View all/native report or bounded paging. Verify 199/200/201, ordering and access. Keep bounds rather than loading everything. |
| **O16 · P3** | [Home rounds money to whole pounds](</Users/stevo/Downloads/mission community updated datamodel/force-app/main/default/lwc/nteManagementHome/nteManagementHome.js:4>): the current probe shows £598.80 as £599 and £0.49 as £0. Underlying values are intact. | Show pence, or clearly identify rounding with exact values available. Check small/large totals and narrow layout. Change presentation only. |
| **O17 · P3** | [Annual instructions](</Users/stevo/Downloads/mission community updated datamodel/FUTURE_NTE_MAINTENANCE.md:10>) tell maintainers to edit generated pricing-version constants; [build-vat](</Users/stevo/Downloads/mission community updated datamodel/scripts/build-vat.js:40>) restores them from config. The isolated new-version experiment was silently reset. | Document config/nte-pricing.json as version/rate source, then build/check both outputs. Verify one config change updates both constants and a second build is stable; never rewrite historic saved versions. |
| **O18 · P3** | [Volunteer footer colour](</Users/stevo/Downloads/mission community updated datamodel/assets/volunteer-styles.css:46>) becomes #625c60 on #242124, measured at 2.44:1 contrast. Footer identity is difficult to read under low vision/glare. | Restore the existing light footer text or a suitable light foreground. Inspect both volunteer pages, links/focus and narrow widths; no global palette change is needed. |
| **O19 · P3, API-only boundary** | [Conversion provenance](</Users/stevo/Downloads/mission community updated datamodel/force-app/main/default/classes/NTEConversionGuard.cls:5>) records every Opportunity inserted in the transaction. A custom integration can insert a clean non-NTE Opportunity and then pass its ID to conversion, satisfying the transaction-local checks without conversion itself creating it. This is source-derived, not a live exploit or ordinary native-modal failure. | Check whether such a caller exists. Require supported integration conversion to omit OpportunityId and test that negative case. Keep the native guard; do not build a large custom conversion framework solely for an unused path. This qualifies the strict P03 guarantee. |

| **O20 · P3, exposed/wrong-reference case** | [Supplementary matching](</Users/stevo/Downloads/mission community updated datamodel/force-app/main/default/classes/NTEUpdateSubmissionService.cls:223>) uses the exact booking reference without checking submitter ownership. Someone using another booking’s valid reference can replace its roster/logistics; a forwarded reference also permits a delegated submitter to act. This is the accepted reference-based model, not a newly demonstrated exploit. | Personalised reference prefill (U01) reduces accidental copying errors. Treat references accordingly in operational handling. If the client requires stronger control, assess a booking-specific signed link that retains legitimate delegation and manual recovery; do not require submitter email to equal the Primary Contact or add a login by default. Verify wrong, forwarded and invalid links before selecting a change. |

Two further ownership details are worth retaining in maintenance notes:

- **Converted Lead retention:** deleting the source application can block later initial booking-request/free-confirmation emails even when its Opportunity is intact (O08). Keep it until the dependency is deliberately removed.
- **Editable Contact role text:** [conversion overwrites NTE Contact Role](</Users/stevo/Downloads/mission community updated datamodel/force-app/main/default/flows/NTE_Copy_Converted_Lead_to_Opportunity.flow-meta.xml:359>) with Applicant / event contact on reuse. If staff curate this text, their value is lost. Decide whether it is a system-owned latest summary or staff data; label/preserve it accordingly and test reuse. Actual Primary Contact Roles are separate and should remain untouched.

## C. Client questions that may be unnecessarily compulsory

These behaviours are confirmed, but **the desired relaxation is a business decision**, not a discovered permission to alter supplied requirements. They are ranked by likely ordinary-user friction. The existing [full restrictions inventory](</Users/stevo/Downloads/mission community updated datamodel/audit/NTE_FORM_RESTRICTIONS_2026-09-15.md>) remains useful; its old “logo destination missing” statement is superseded.

| ID / priority | Current problem and concrete example | Smallest useful option / what must be preserved |
|---|---|---|
| **C01 · P2** | PO=Yes requires its reference immediately, even when quotation=Yes. A council may need the quote before it can raise that PO. It must abandon, answer inaccurately or type “To follow”. [Exhibitor](</Users/stevo/Downloads/mission community updated datamodel/exhibitor-application.html:157>), [partner](</Users/stevo/Downloads/mission community updated datamodel/partner-sponsor-application.html:114>). | Make reference “if available” while retaining PO=Yes and its outstanding staff reminder, or explicitly allow pending details. Check both payment methods, conversion and optional email rows. Do not auto-tick procurement. Existing R07. |
| **C02 · P2** | Logistics requires second-contact/haulier details, item 1 and at most three items. A solo self-delivering exhibitor lacks a second contact; an unknown→none case cannot close itself; a four-vehicle plan cannot fit. [Form](</Users/stevo/Downloads/mission community updated datamodel/heavy-vehicle-details.html:23>), [server](</Users/stevo/Downloads/mission community updated datamodel/force-app/main/default/classes/NTEUpdateSubmissionService.cls:471>). | Decide whether the second contact is essential; make genuinely inapplicable haulier data optional for self-delivery in both layers. Retain main contact, real item dimensions/weight and full replacement. Use staff handling for fourth items/none unless U20 is selected; empty data must not silently delete earlier vehicles. Existing R17–R20/U20. |
| **C03 · P2** | Required volunteer skills/travel lists have no no-experience/willing-to-learn or remote-only answer and omit Northern Ireland. Some otherwise willing applicants cannot answer truthfully. [Choices](</Users/stevo/Downloads/mission community updated datamodel/volunteer-application.html:101>). | Confirm recruitment scope. If these applicants are wanted, make the relevant preference optional or add one accurate choice, coordinating Lead/Contact values, conversion and emails. Preserve historical data, conduct consent and Mission/NTE separation. Do not infer an eligibility policy. |
| **C04 · P2** | EOIs omit CIC/not-for-profit/neutral Other although the full application accepts CICs; required exhibitor discovery choices omit Other and the webinar route. Applicants may misclassify themselves just to proceed. [EOI](</Users/stevo/Downloads/mission community updated datamodel/exhibitor-interest.html:31>), [application discovery](</Users/stevo/Downloads/mission community updated datamodel/exhibitor-application.html:177>). | Reuse an appropriate already-supported fallback or make nonessential attribution optional. Check target active picklists/reporting and exact-list tests; preserve power pricing and old values. Existing R13 plus the discovery mismatch. |
| **C05 · P3** | Mobile-only exhibitors must repeat a number as work phone; same-person finance details must be retyped; optional-sounding comments need “None”; companions require their own email. [Contact](</Users/stevo/Downloads/mission community updated datamodel/exhibitor-application.html:66>), [finance](</Users/stevo/Downloads/mission community updated datamodel/exhibitor-application.html:161>), [partner comments](</Users/stevo/Downloads/mission community updated datamodel/partner-sponsor-application.html:105>), [companion](</Users/stevo/Downloads/mission community updated datamodel/guest-registration.html:44>). | Prefer one usable telephone, a same-as-main convenience and optional genuinely additional prose where agreed. Check mappings and email omissions. Required finance information was expressly preserved by proposal 24; do not remove it wholesale or invent companion addresses. |

**Small form wording fix:** an optional website such as www.example.com fails native URL validation but receives a required-fields message. [Website input](</Users/stevo/Downloads/mission community updated datamodel/exhibitor-application.html:56>), [generic error](</Users/stevo/Downloads/mission community updated datamodel/assets/forms.js:814>). A field-specific example/error is the smallest remedy; carefully scoped HTTPS normalisation is optional. Verify blank, full URL, bare hostname and malformed input in a real browser. No domain allowlist is needed.

**Convenience rather than a new gate:** U01 could prefill the editable booking reference in preparation links, reducing copy/paste errors. Preserve exact server matching and forwarded-link behaviour; do not add contact lookup or treat prefill as authentication.

## D. Production prerequisites and limits to keep explicit

These are not newly discovered production failures: this audit did not access the target production org or the client's merchant account.

| ID | Dependency / consequence if ignored | Proportionate next step |
|---|---|---|
| **R01 — target configuration and recipient pages** | [Current config](</Users/stevo/Downloads/mission community updated datamodel/assets/config.js:2>) intentionally targets MMUAT. Nine forms retain client-review email-preview panels. Copying them unchanged to production would use the wrong org and expose review-oriented controls. | Prepare the approved production org/field IDs, owner/creator/locale, return/terms/preparation URLs, sender/access and recipient-only pages. Keep the authorised client preview intact. Use existing target-preserving deployment tools; no additional general approval layer is needed. |
| **R02 — Stripe custom domain, conditional P2** | [URL validation](</Users/stevo/Downloads/mission community updated datamodel/force-app/main/default/classes/NTEStripeClient.cls:148>) accepts only buy.stripe.com. [Stripe supports custom-domain Payment Links](https://docs.stripe.com/payments/checkout/custom-domains); a client setting such as payments.client.example can make a correctly verified request fail its URL check. | Inspect the actual returned origin during client qualification. If used, permit one explicitly verified HTTPS origin alongside the standard one. Keep exact host/resource/account/mode checks; never allow arbitrary or substring-matched domains. If unused, document the boundary rather than add configuration without need. |
| **R03 — production test fixtures** | Browser tests assert MMUAT-specific mode/org/URLs. Changing only the mode to production makes them fail before reusable behavioural checks; green sandbox tests do not validate the final remapping. | Separate preview assertions from parameterised target fixtures. Run inert behavioural tests for both environments with exact approved target expectations; do not simply delete target checks. [Proof](</Users/stevo/Downloads/mission community updated datamodel/tmp/simplicity-audit-20260916/build-targeted-proofs.json>). |
| **R04 — logo confirmation remains a declaration** | The real SharePoint upload link is now configured and opens separately. Confirming the form still cannot prove the file arrived or associate it automatically with the booking. | Retain the selected declaration workflow and identify the staff file-verification process. A future file association is U16, not a reason to restore removed signature/date/tickbox controls. |
| **R05 — annual and operational ownership** | Automatic event identity does not update NTE27 copy, prices or delivery windows. Volunteer copy promises two-year retention/renewed consent; this review did not establish the existing operational process behind it. | Use the annual content/config review and identify the responsible existing consent/retention process. Do not infer automated deletion/renewal or introduce a new job. This is an unverified operational dependency, not a legal finding. |

Future Stripe API-version changes also need request compatibility: the global API version is part of saved fingerprints ([base](</Users/stevo/Downloads/mission community updated datamodel/force-app/main/default/classes/NTEStripeBookingService.cls:153>), [top-up](</Users/stevo/Downloads/mission community updated datamodel/force-app/main/default/classes/NTEStripeBookingService.cls:306>)). A version-only upgrade can strand unsent requests. Preserve/version existing contracts during a planned upgrade rather than silently changing old request semantics.

## E. Safeguards and decisions that should remain

- **Exact Primary Contact routing and unique booking matching.** These prevent wrong-person messages and wrong-booking updates. Missing/ambiguous identity must remain visible; billing/event-day/submitter fallback is not authorised.
- **Server price validation, VAT/item consistency and provider verification.** Browser fields can be changed. Unknown prices must not become free; account/mode/amount/charge identity and uncertain-outcome protections have concrete purposes.
- **Recorded payment survives email failure.** Duplicate accepted confirmation prevention, reviewed recipient snapshots, row locks, audit persistence and bounded asynchronous work should remain. S02/S03 concern usable recovery, not removing these boundaries.
- **Independent requirements and separate base/top-up history.** No current accidental checkbox gate was found. Amount-only adjustments/full waivers work through their selected path; they do not imply arbitrary top-up repricing or automated refunds.
- **Explicitly accepted policies.** One positive top-up, manual Stripe receipt, manual joining instructions, manual forwarding of accepted mail, manual correction/fresh forms, native Account/Contact matching, Closed Lost preparation updates and volunteer scroll acknowledgement remain selected rules. They are not new defects merely because they constrain behaviour.
- **Target-preserving release tools and app isolation.** Preserving production layouts, Profiles, conversion mappings, picklist defaults and shared sales stages prevents real collateral changes. These release checks do not add applicant steps.
- **Current browser simplicity.** No applicant login, CAPTCHA, broad organisation allowlist, ASCII-only name filter or UK-only phone pattern was found. Hidden inapplicable inputs are disabled/omitted, same main/finance person is permitted, free exhibitors omit finance and paid extras restore it.
- **Historic limits stay qualified.** Native Details Only CSV is the established complete-roster export route; do not reopen declined P10 prefix handling. Reference-only update matching is not proof of submitter ownership; it remains the accepted workflow, not a reason to silently add an authentication journey.

The generator is verbose but deterministic today. A shared catalogue/ownership map and a normal exported test-fixture module could reduce future duplicated rules and the fragile test-source slicing at [forms.test.js](</Users/stevo/Downloads/mission community updated datamodel/tests/forms.test.js:844>). These are maintenance opportunities after the concrete defects, not grounds for a broad last-minute rewrite.

## F. What was verified and what was not

Reviewed all ten submission forms and shared engine, supporting pages, 18 runtime Apex classes and relevant tests, both triggers, five Flows, four LWC bundles, related schema/validation/permissions, nine reports, generator/release tools and current workflow/decision records. The source inventory contains 48 Apex classes overall, including 30 test classes.

| Check performed in this audit | Result / scope |
|---|---|
| Isolated first and repeat build | Exact reproduction: no changed/added/removed files across the 775-file isolated input. No retired metadata recreated. |
| Current qualified source comparison | All 614 source/manifest hashes from the latest volunteer qualification match current disk. This is parity with dated qualification, not a new native validation. |
| Manifest and XML checks | 528 unique member identities; all 613 deployable source files resolve; no missing members or retired active overlap; 542 XML files parse. This does not establish target-org dependencies. |
| npm test | Pass, including form checks, email presentation/assets, six page-isolation and six volunteer-compatibility tests. |
| Full inert form engine | 154 checks pass; 35,536 catalogue/boundary combinations. No real POST. |
| Panel/component/metadata checks | 89 panel tests pass; combined Node run reports 92 tests and zero suites because three other files each contribute one file-level subtest. Generated metadata branch also passes. Do not add these as independent live tests. |
| Additional existing Python suites | Five shared-picklist and seven Stripe-preflight tests pass with inert fixtures. |
| Targeted probes | Free-space payloads, compulsory-field branches, script-startup markup, stale related state, 501-recipient refusal, Home rounding, conversion capacity, omitted-test mutation, version reset and production-fixture incompatibility. Exact boundaries are in the domain reports. |
| Root source preservation | Existing implementation files compared with the audit-start hash baseline; no product edits authorised or made. |

No new native Apex run, production metadata retrieval, actual browser/device/assistive-technology matrix, concurrent live transaction, provider checkout or real inbox test was performed. Existing September successful sends/submissions remain preserved. The findings should guide **fresh, narrowly selected verification after a fix is approved**, rather than replaying completed fixtures.

### Detailed evidence

- [Forms review](</Users/stevo/Downloads/mission community updated datamodel/tmp/simplicity-audit-20260916/forms.md>) and [targeted payloads](</Users/stevo/Downloads/mission community updated datamodel/tmp/simplicity-audit-20260916/forms-probes.json>).
- [Intake/conversion/update review](</Users/stevo/Downloads/mission community updated datamodel/tmp/simplicity-audit-20260916/intake-updates.md>).
- [Finance/Stripe review](</Users/stevo/Downloads/mission community updated datamodel/tmp/simplicity-audit-20260916/finance-stripe.md>).
- [Email review](</Users/stevo/Downloads/mission community updated datamodel/tmp/simplicity-audit-20260916/email.md>).
- [Staff interface/access/report review](</Users/stevo/Downloads/mission community updated datamodel/tmp/simplicity-audit-20260916/staff-interface.md>) and [UI probe results](</Users/stevo/Downloads/mission community updated datamodel/tmp/simplicity-audit-20260916/staff-ui-probes.json>).
- [Build/release review](</Users/stevo/Downloads/mission community updated datamodel/tmp/simplicity-audit-20260916/build-release.md>), [test results](</Users/stevo/Downloads/mission community updated datamodel/tmp/simplicity-audit-20260916/test-results/results.json>) and [targeted build/test proofs](</Users/stevo/Downloads/mission community updated datamodel/tmp/simplicity-audit-20260916/build-targeted-proofs.json>).

The report itself contains the actionable findings; the ignored local evidence directory supplies additional detail. Existing audit/proposal IDs and historical results remain unchanged. No finding here is an implementation or deployment approval.
