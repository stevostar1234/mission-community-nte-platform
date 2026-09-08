# Desired NTE workflow

Last updated: 8 September 2026. Business owner: the project owner, conveying the NTE / Mission Community team's requirements.

This is the current record of the intended workflow. Read it before proposing, implementing, testing or reviewing NTE changes. Confirmed requirements describe the target behaviour; they do not imply that the current package already implements it. [NTE_CHANGE_PROPOSALS.md](NTE_CHANGE_PROPOSALS.md) records implementation proposals and their approval status. The dated audit contains source evidence and historical discussion, some of which has been superseded here.

When the project owner supplies a changed brief, update the relevant rule here, record the change in the decision history, and update affected proposal statuses/dependencies. Record unknowns as undecided. Do not treat an assistant suggestion as an accepted business rule. Current explicit user instructions take precedence over this document. Do not assume client changes have occurred unless they are communicated or otherwise authorised for discovery.

## Confirmed journey

| Stage | Intended behaviour |
| --- | --- |
| Expression of interest | An organisation expresses interest in exhibiting or partnering/sponsoring. Staff nurture it, communicate with it, assess suitability and decide whether to invite an application. |
| Earlier manual interest decision | Progressed meant outreach had finished and the application invitation had already been sent. Not progressed recorded the other outcome. Either removed the interest from the active working queue to prevent duplicate effort. That past-tense wording was intentional; the approved invitation action now records that outcome after sending. |
| Application invitation | Preserve the human decision. Each interest has Send Application and Reject. Send Application opens a draft with only that interest selected; accepted dispatch records Progressed. Reject closes the interest without sending an invitation. The bulk toolbar action is Send to all: it opens a draft with all eligible interests matching the current filters selected, and staff can deselect before sending. Opening the draft does not send anything. No Mark as already invited action is needed. |
| Application submitted | Applicants can arrive through an EOI invitation or an external database/direct application route. Acknowledge that the application is being reviewed. No provisional/confirmed-space wording or preparation links at this stage. |
| Team decision | The team converts/approves or rejects at its discretion. Conversion creates the event booking. Paid spaces are provisionally reserved; fully complimentary spaces are confirmed immediately. |
| Post-conversion email | Send the provisional reservation, booking details, itemised quote/invoice information, applicable payment button and staff/heavy-vehicle/logo links together. The project owner expressly confirmed that preparation links first arrive after conversion, alongside payment. |
| Booking payment | The owner selected manual payment confirmation for Stripe on 8 September. Staff verify the exact successful Stripe payment and record Booking payment received. A successful Stripe payment alone does not confirm the booking in Salesforce. That staff action confirms the original space and sends one confirmation email to the Opportunity's primary Contact. Failed notification must not undo the recorded payment. A later staff top-up must not clear this original payment or undo the original space confirmation. Fully complimentary bookings need suitable handling without waiting for a non-existent charge. |
| Preparation updates | Applicants provide/correct staff names, applicable heavy-vehicle details and their logo. Preparation updates are allowed before initial payment is recorded. Match supplementary submissions using the booking reference. |
| Completed | All applicable finance, staff, heavy-vehicle and logo requirements are satisfied. The table, counters, refiners and final-pack eligibility must use a consistent definition. |
| Final pack | The team controls distribution once final instructions are ready. Completed has Final pack not sent / Final pack sent refiners. Distribute only to eligible bookings still needing that pack. A late completer enters the unsent group without resending to earlier recipients. Approved for implementation; final content and links are awaited. |

## Contact and form-update rules

The project owner confirmed that **the Opportunity's Primary Contact Role** is the source for the Master Panel's main contact name, email and phone and for **all post-conversion booking emails**, including reminders, provisional/payment messages, final packs and booking-update acknowledgements. Event-day contacts are for event operations and must remain separately identified.

- Pre-conversion acknowledgements and EOI invitations continue to use their Lead recipient because no Opportunity exists yet.
- If there is no usable Primary Contact Role/email, show the issue and leave the email unsent. Do not silently substitute an event-day, billing or form-submitter address.
- Supplementary staff, heavy-vehicle and logo forms must not overwrite actual Contact records, Opportunity contact roles, or existing booking event-day/secondary contact details.
- A valid heavy-vehicle submission **replaces the booking's full vehicle/equipment and associated delivery/haulier details**. Optional items omitted in the replacement should clear the previous corresponding items. Replacement is intentional; preserve unrelated contact, billing, staff and finance information.
- Invalid submissions must retain the existing data unchanged. The submitted identity/signature may remain audit information without changing the established contacts.
- Whether to copy separate billing contacts or form submitters on any email is undecided. The confirmed primary recipient rule does not authorise extra recipients.

## One-time staff top-up

The project owner confirmed: **lock further increases after the first valid positive top-up request; continue allowing name corrections**.

- One accepted purchase of additional staff per booking. This replaces the earlier proposal to support multiple separately billed top-ups; do not add a multi-purchase ledger to satisfy the current brief.
- An ordinary staff-name submission with no top-up does not consume the allowance. Invalid or rolled-back requests do not consume it.
- Once the first valid positive request is accepted, retain its quantity, unit price and total. A repeat at the same quantity may correct names but must not reset the invoice/payment flags or their dates/users.
- Reject later increases without changing the accepted purchase, contacts or payment history. Enforce the rule in Salesforce, including concurrent requests and multiple submissions for one booking in a single batch. The static form explains the one-time rule; it does not claim to check the live booking state.
- Self-service reductions, cancellation or a staff override are not approved new features; the existing restrictions must not be weakened or automatic refunds introduced without a decision.
- No deadline or cutoff after pack distribution has been requested. A first positive top-up can therefore occur after a pack was sent; its finance requirements reopen while the pack's sent history remains intact.

## Finance refiners and pricing

Use exactly four finance refiners, in this order:

| Refiner | Next action |
| --- | --- |
| Quotes required | Quote provided |
| Invoice required | Booking invoice provided, then Staff top-up invoice provided if applicable |
| Payment required | Booking payment received, then Staff top-up payment received if applicable |
| Payment confirmed | All applicable booking and staff top-up charges paid |

Keep booking and staff top-up amounts, invoice/payment flags, dates and users separate. Combine their work into the same refiners, counting a booking once in each relevant view. When both invoices are outstanding, show the booking invoice action first; after it is recorded, show the staff top-up invoice action on that booking. Apply the same booking-first order to payments. Label these charges **Booking**, not Initial.

Payment required contains actionable unpaid charges whose own invoice has been provided. An unpaid invoiced booking may be paid while its top-up invoice is still outstanding. A booking already paid with an uninvoiced top-up belongs in Invoice required; after that invoice is provided it enters Payment required. Existing booking payment must never be cleared by top-up work. Payment confirmed means every applicable charge is paid and excludes fully complimentary bookings with no payment to record. Quotes precede invoices when required. Once Stripe is introduced, an accepted payment-email send may fulfil the corresponding invoice/link milestone. Payment recording remains manual, including the Stripe route selected by the owner on 8 September after reviewing the manual and automatic alternatives.

The client retired pricing by request on 6 September 2026 and explicitly authorised removing that feature from forms, Salesforce, the panel and supporting implementation. Remove manual agreed-price entry, its flags/audit fields, email waiting paths and active catalogue choices without a defined price. Existing saved monetary and payment facts are preserved; do not mass-reprice old test bookings. In the absence of replacement fixed prices, the extra-large exhibitor space and Troops’ Track Day Partner application choices are removed. Informational event descriptions and EOI topics remain. Unknown, removed or incomplete pricing must fail validation or remain Check pricing work, never be treated as a complimentary booking or sent an unpriced approval email.

The Event breakdown includes logistics, staff and logo updates. The detail pane shows booking/readiness information with Open full record. The 7 September instruction removes the per-record Email activity button and its panel dialog/functionality; retain operational dispatch records and failed-send recovery outside that dialog. Do not repeat row decisions or finance actions there, repeat the cross-event report shortcut, or restore the Booking emails summary. Email history, failed-message retries, repeatable outstanding-update reminders and final-pack refiners remain functional. Finance uses its cross-event report as the wider reporting route; a separate global-list shortcut must not take users back to the former split booking/top-up queues.

## Email presentation and dispatch

Use the partner/sponsor interest acknowledgement as the shared visual reference: navy headings, white content, restrained accent colours and readable booking-detail sections. Use coherent category colours to distinguish partner/sponsor, exhibitor and complimentary messages. Preserve the client's wording and terms recovered from the last complete templates; visual standardisation does not authorise deleting substantive sections. Staff-update guidance sits above its action buttons, arranged horizontally where the email client permits and stacked on narrow screens. Include a plain-text alternative. Apply the same family to the custom Remind All sender, invitations, final packs and custom panel emails.

Keep application acknowledgements and conversion approvals as separate templates/routes for both paid participant types. The former says under review; the latter says provisional space reserved and retains the complete booking, staff, logo, logistics and client-agreement information. Complimentary conversion emails confirm the space immediately and preserve their client wording without a payment prerequisite.

Proposal 12 is now approved: when the team records the booking payment as received, send one paid-exhibitor or partner/sponsor confirmation using that exact Opportunity and its primary Contact. Do not use most-recently-modified matching. Repeated payment clicks, later staff top-up payments and retries must not generate a second accepted confirmation. Keep failed notifications recoverable without clearing the payment milestone. No historical payment backfill is requested. The normal sequence is provisional email → payment → confirmation email. The owner subsequently confirmed an exception: if staff record payment while the provisional email has failed, send the payment confirmation immediately. Preserve the recorded payment and separate failed provisional history; do not make payment confirmation depend on that retry succeeding.

Mission Motorsport volunteer forms and emails use the official Mission Motorsport logo and their own coherent style, without NTE branding. Remind All uses the same button colour as View cross-event report.

Invitations map Exhibitor Expression of Interest to the exhibitor application, and Partner / Sponsor Expression of Interest to the partner/sponsor application for all subtypes. The client intends one enduring URL for each application type on its own NTE website, with annual wording/content updated at the same destinations. Configure these reusable URLs once and change them only if their destinations move. An interest's event year must not block an otherwise valid invitation or select a different form. Missing or invalid HTTPS destinations still stop the affected send rather than select another form. Until the client supplies the final URLs, keep the existing GitHub preview destinations for sandbox use.

An enduring invitation URL does not itself choose the submitted application event. The form uses its current edition configuration (the existing London-date calculation or explicit event override). Future-year dummy interests can receive invitations today, but submitting that link still creates an application for the edition currently configured in the form. Do not silently add per-interest event overrides or assume annual content/prices update themselves.

The shared mass-email dialog should be compact and visually clear. Keep one selected/available counter in its own blue box beside the recipient list. Gold Select all, red Clear and blue Refresh are separate controls outside that box. Remove repeated counts, event codes, raw links, recipient addresses and generic instructions; personalised content and its action link remain available in the preview. Align Subject with Preview for, keep the Send action visible outside the scrolling content, and preserve meaningful recipient errors, send states and accessible labels. This applies to invitations, reminders and final packs.

Preview actual recipients and personalised content before deliberate bulk sends. Use the reviewed selection, recheck current eligibility and prevent concurrent duplicate sends. Log the recipient, time, initiating user and individual result. Salesforce accepting an email request is not proof of delivery or opening. Failed sends remain visible and retryable.

Final-pack dispatch is a separate fact from readiness and is stored per booking/event. Queued and already-sent records must not receive another ordinary dispatch. A later top-up or staff correction must not erase sent history. Corrected packs require an explicit resend; separately versioned packs are an optional future requirement.

Final-pack destinations remain event-specific. The existing `Application_Event_Code__c` routing field retains its API name for compatibility but is labelled **Final Pack Event Code** and guards final packs only. The enduring-form decision does not authorise sending a different year's final pack.

## Desired Stripe sequence

On 8 September 2026 the owner reconfirmed the target: an exhibitor or partner/sponsor selects Stripe on the application; Mission Community converts it in NTE Management/Master Panel; the provisional-allocation email includes the payment link for the amount owed alongside the existing details; payment produces the agreed notifications. The owner subsequently selected manual payment confirmation and requested a client-equivalent test setup and extensive qualification before production. [The implementation plan](NTE_STRIPE_IMPLEMENTATION_PLAN_2026-09-08.md) retains the researched alternatives; [the manual setup and test plan](NTE_STRIPE_MANUAL_SETUP_AND_TEST_PLAN_2026-09-08.md) governs the current preparation. The client still needs to grant Stripe access.

The team has agreed that a single itemised post-conversion email can provide the quote/invoice information and Stripe button together. Do not assume that a separate manual quote email must precede every Stripe request. Where the agreed document fulfils a requested quote, its accepted send can also fulfil Quote provided. Sending the email does not establish that an actual PO has been received.

Shared target sequence: conversion committed → correct payment request created → returned link and verified charge details saved → combined HTML email sent → invoice/link-provided milestone recorded → applicant pays on Stripe.

The selected final confirmation step is **manual**: staff check the successful Stripe payment against the exact saved booking charge, then record Booking payment received using the existing Salesforce action and its single space-confirmation email. Plan the straightforward Dashboard-verification route (A1); selecting manual does not require a webhook receiver or imply an assisted-verification feature. The previously researched automatic and assisted-manual routes remain future alternatives, not the current build requirement. Notifications, payer receipts, internal recipients and exceptions must still be specified rather than inferred from “relevant notifications”.

The present conversion email trigger must be replaced or redirected into that coordinated sequence for the Stripe route, so an older path cannot send a premature or duplicate message. Use explicit booking IDs. A missing link, unknown price, inconsistent amount or API failure leaves pending/failed work and does not send an incomplete Stripe payment email.

Salesforce supplies an approved saved amount, currency, description/line items and booking/charge identity. For GBP, monetary API amounts use pence. Current catalogue totals are excluding VAT; settle the intended net/tax/gross treatment before implementation. Use the same saved amount for Stripe and the email, with fixed quantities and controlled discounts. Verify the returned payment request, including its line items, currency, active status and test/live mode, before making it eligible to send. Save its Stripe ID and reuse it on retries. Detect price changes during processing rather than emailing an obsolete request.

Authenticate directly to the client's intended Stripe account using secure Salesforce credentials. Record and verify the expected Stripe account ID. Mission Community's payout bank account is configured within that Stripe account, not supplied as a bank destination in each Payment Link request. Stripe payment and bank payout are separate events. The actual Stripe account, payout bank configuration and credentials have not been verified or changed during this review.

The owner selected **Stripe Payment Links only, with no Stripe Invoicing**, later on 8 September. Keep optional post-payment invoice creation disabled; formal invoice ownership and document details remain with the client's separate finance process to specify. The earlier Invoicing/Checkout comparisons are historical alternatives. Current Stripe documentation says Adaptive Pricing is always enabled for Payment Links, so GBP-only presentation cannot be assumed. Seller details, tax treatment, currency presentation, notifications and invoice-process details remain awaited.

Bank-transfer milestones remain available unless the client expressly retires that route. Automatic payment verification/webhooks were researched as an alternative and are not required for the selected manual route. Refund automation and a participant portal remain outside the requested implementation scope. Resolve the existing P03 conversion policy, P01 paid-booking provisional retry, top-up payment ordering and cancellation/late-payment handling before enabling the affected collection routes; recommendations in the plan do not decide those policies.

Technical references checked on 5 September 2026: [Stripe Payment Link API](https://docs.stripe.com/api/payment-link/create), [currency units](https://docs.stripe.com/currencies), [authenticated account identity](https://docs.stripe.com/api/accounts/retrieve), [bank payouts](https://docs.stripe.com/payouts), [retry idempotency](https://docs.stripe.com/api/idempotent_requests). These support the proposed integration mechanics; they do not verify the client's actual account configuration.

Refreshed 8 September 2026: current Stripe and Salesforce sources, manual/automatic feasibility, credentials, accounting/notification dependencies and qualification gates are recorded in [the Stripe plan](NTE_STRIPE_IMPLEMENTATION_PLAN_2026-09-08.md). A read-only native query verified MMUAT as Enterprise Edition; it did not verify the client's Stripe account, future integration user, production configuration or a working payment integration.

## Accepted constraints and undecided items

Accepted: the client currently wants open internal access; restrictions may be requested later. The GitHub site is an intentional client review site for forms/email examples; final forms are destined for the NTE website. Keep booking-reference matching. Recent-date ordering is adequate. Do not invent urgency/overdue classifications. Capacity management is deferred. Old dummy records may reflect obsolete briefs and must not drive silent migrations.

The owner explicitly declined special handling for company names beginning with `=` after the native CSV observation in stress-audit P10. Preserve the supplied name and the existing export setting. P10 is closed as declined, with no further implementation or testing planned; its historical observation is retained only as internal evidence.

The owner has given standing permission to keep the existing GitHub preview site current whenever approved changes affect its forms or email examples. Publish the relevant files to `stevostar1234/nte27-web-to-lead-demo` as part of the same work, verify the hosted result, and record the commit/deployment. Routine updates within that scope do not need another publication question. Preserve unrelated repository content and keep Salesforce package files out of that website release.

| Undecided / awaited | Consequence |
| --- | --- |
| Final SharePoint logo upload URL and final NTE form destinations | Configure when supplied; do not remove the review site because it is not production hosting. |
| Stripe account connection and verified payout bank | Required before enabling live Stripe requests. Do not guess the merchant account. |
| Client invitation to a dedicated Stripe sandbox | The owner confirmed access is still awaited. Use a sandbox copied from the intended client merchant, then compare settings; local mocks can proceed before access. |
| VAT policy and the client's separate invoice/proforma process | Payment Links is selected and Stripe Invoicing excluded. Confirm the payable amount and who supplies any formal financial document. |
| Final-pack content/links and participant-type differences | Needed before actual distribution; structure can be prepared earlier. |
| Optional copies to billing contact or form submitter | No additional recipients authorised by the primary-contact rule. |
| Contact/staff override, top-up reductions/cancellation, booking cancellation/refunds | No new automatic behaviour without a client decision. |
| Public way to change heavy-vehicle requirement from unknown to not required | Current form requires an item; decide whether to add a self-service route or retain staff handling. |
| Native conversion to an existing Opportunity or without an Opportunity | P03: decide whether to require a new booking for every NTE application while retaining existing Account/Contact reuse. No new conversion guard is implemented. |
| Feedback for rejected preparation updates and platform-rejected applications | P02/P17: decide the response and permitted recipient; a static thank-you redirect alone cannot prove acceptance. |
| Which edition Home and the Master Panel open by default | P16: current behaviour selects the highest valid event; a configured current edition is proposed but not approved. |
| Retrying a failed provisional email after payment confirmation | P01: payment confirmation already sends immediately; the later retry's suppression or replacement remains undecided. |

## Approval, verification and maintenance

The owner has now authorised implementation of proposals 1, 2, 3, 4, 5, 6, 8, 10 and revised 9. Proposal 7 is approved with server enforcement and explanatory form copy; proposal 11 now has a selected manual route and requested setup/qualification planning, with client sandbox access and financial configuration awaited; 12 was explicitly approved on 7 September 2026. A confirmed target rule is not blanket approval for all related implementation. The selected scope is recorded in NTE_CHANGE_PROPOSALS.md. Complete the approved scope and apply the existing source/MMUAT synchronisation process; production release remains separately authorised.

Later tests should use fresh synthetic records reflecting the current rules. The owner permits verified example addresses or their own email variants in the sandbox. Check the actual Primary Contact and any internal notification recipients too. Do not send tests to genuine legacy Contacts/Accounts. A separate unrelated-legacy regression project is not requested. Tests that assert old contact-overwrite or repeat-top-up behaviour must be revised with those approved changes.

Decision history, 5 September 2026:

1. Recorded the manual meaning of Progressed and the under-review → provisional → paid/confirmed sequence.
2. Confirmed preparation links arrive after conversion alongside payment.
3. Agreed the combined itemised financial email and automatic Stripe-link generation before dispatch.
4. Requested separate staff top-up invoice, payment-required and paid refiners/actions.
5. Confirmed Opportunity Primary Contact Role for the panel and all post-conversion booking emails; event-day contact remains separate.
6. Confirmed contact preservation with complete heavy-vehicle/detail replacement.
7. Confirmed one positive staff top-up purchase, locked at the first valid request, with names still editable. This supersedes the earlier multiple-top-up-bill proposal.
8. Requested a maintained desired-workflow record and numbered changes for approval.
9. Approved 1–6, 8, 10 and revised 9 (Send Application / Reject; no already-invited action). Asked about static form enforcement before approving 7. Held 11 for client details; declined a separate payment-confirmed email (12) for now.
10. Implementation of the approved scope began. Until Stripe integration is enabled, send provisional preparation information with the existing manual payment follow-up; do not wait indefinitely for a Stripe link the held integration cannot create.

11. Approved proposal 7 after clarification. Salesforce enforces the one-time top-up; the static form explains it and does not claim live booking-state enforcement.
12. Authorised publishing the prepared form/email-preview updates and keeping the existing GitHub preview site current whenever relevant approved changes are made. This is an ongoing working rule, not a request for scheduled monitoring or production deployment.

Decision history, 6 September 2026:

1. Confirmed enduring exhibitor and partner/sponsor application URLs on the future client site, with annual content changes at those URLs. Approved removing the invitation year gate, including for future-year sandbox interests. Final-pack year checks remain separate.
2. Approved Send to all as the bulk Interests action, initially selecting every eligible interest in the current filtered view; individual Send Application selects only that interest. Staff still review/deselect and explicitly send.
3. Approved the annotated mass-email UI cleanup, one counter, compact recipient controls, aligned editor/preview and always-visible Send. Asked for a global preference for sleek interfaces with minimal explanatory copy.
4. After seeing the revised interface, requested that Select all, Clear and Refresh sit outside the counter's blue box as separate buttons.

Latest decision: implement these mass-email and enduring-link refinements while preserving recipient eligibility, primary-contact routing and deliberate dispatch. Keep the standing client-preview publication rule whenever public forms or email examples change.

Implementation status, 6 September: these refinements are deployed and browser-verified in MMUAT. Final full-package validation passed 410 components and 163 tests; see [the release record](audit/NTE_EMAIL_UI_REFINEMENT_2026-09-06.md). No production release or live email dispatch was performed.
5. Client retired pricing by request across the forms, Master Panel and Salesforce; owner authorised comprehensive removal. With no replacement fixed prices supplied, remove the two affected application choices, preserve historical money/payment facts and reject unknown prices instead of treating them as free.
6. Replaced separate booking/top-up finance refiners with Quotes required → Invoice required → Payment required → Payment confirmed. Preserve separate finance histories and show booking actions before their top-up equivalents.
7. Approved logo progress in the Event breakdown; removed the redundant detail cross-event link, Booking emails summary and duplicated row/detail actions. Reminder sending remains repeatable while the required updates are outstanding.


Decision history, 7 September 2026:

1. Restore the last complete client wording for partner/sponsor, paid-exhibitor and complimentary conversion emails. Keep the separate under-review acknowledgements. Paid conversion is provisional; complimentary conversion is confirmed. Standardise all template and custom-sender designs to the supplied EOI example with coordinated participant colours and horizontal preparation buttons where practical.
2. Explicitly approved proposal 12: send the appropriate space-confirmed email once booking payment is recorded; do not repeat it for top-ups or send a historical backfill. Preserve primary-Contact/exact-booking routing and verify the reported recent-record mismatch.
3. Remove individual Master Panel Email activity UI and change Remind All to match the cross-event report button. Restyle the Mission Motorsport volunteer form with its official logo and no NTE brand.
4. Authorised cleanup of only verified dummy records in every Master Panel view/year after implementation. Back up exact candidates, preserve genuine legacy records and associations, use recoverable deletion, and leave any unverified identities pending clarification. No blanket deletion of all sandbox Accounts/Contacts is authorised.
5. Requested a read-only check of native Apex Blob.toPdf support and an explanation of production compatibility; document generation itself is a future feature, not part of this release.

Implementation status for these 7 September refinements: implemented and deployed to MMUAT. Final check-only validation passed 413/413 components and 180/180 Apex tests. All 48 approved website files are published and byte-verified at preview commit `9f19c00cf23ba593183b26ac393b97fbedbea23a`. The approved 277 dummy Leads, 96 dummy bookings and 16 attached email histories were recoverably deleted; every Account/Contact was preserved and all panel row scopes are empty. See [7 September release evidence](audit/NTE_EMAIL_RESTORATION_2026-09-07.md).

7 September clarification: the owner confirmed that applicants receive the provisional message before paying. Preserve that order; do not add the suggested early-payment/superseded-provisional alternate flow.

7 September sandbox routing decision: Matthew is no longer on this project. The owner requested that Steven remain the sandbox Web-to-Lead creator and NTE owner. MMUAT uses Steven Skyba as Default Lead Creator and `steven.skyba@euroforce.com.mmuat` as the NTE routing owner override. Creator and owner are separate settings; a blank NTE override can retain a different fallback owner and send that owner the internal notification. Production requires its own verified active owner username. This change does not deactivate users or change unrelated records.

7 September walkthrough approval: create one new exhibitor journey using the owner's verified Anthrion address, perform the invitation, application, conversion, finance milestones, reminders and updates through the browser, and retain the resulting records and inbox emails for review. The earlier dummy cleanup must not remove this new walkthrough.

7 September walkthrough outcome: the owner also requested staff top-up testing. One £50 top-up, its separate invoice/payment, names-only correction and rejection of a second increase were verified through the browser and Salesforce evidence. The booking reached Completed; 13 journey emails remain in the inbox. Logo confirmation was simulated because the client upload destination is absent. Formatting, rejection-feedback and supplementary audit-owner findings are recorded in [the walkthrough report](audit/NTE_BROWSER_WALKTHROUGH_2026-09-07.md); they are findings, not additional implementation approvals.

7 September email-formatting approval: the owner requested a review and correction of duplicated pound symbols and authorised fixing email formatting issues whenever found. Preserve client wording and the established workflow. Keep currency merge formatting, multiline details, HTML and plain-text versions aligned, and publish matching client examples. This does not approve unrelated workflow changes, new email sends or a production release.

7 September copy refinement: remove the paragraph about separate first top-up invoicing and name corrections from the exhibitor staff acknowledgement, as explicitly requested in the browser review. This is a copy-only removal; the one-time top-up and separate finance milestones remain as agreed.

7 September email-formatting outcome: implemented in MMUAT and the public previews, including the requested staff-acknowledgement paragraph removal. Final full-package validation `0AfAd00000SotIyKAJ` passed 413 components and 181 tests. Preview commit `18171e8d80751272971acf4012a1611de976c53e` is built and all 42 email source/examples are byte-verified. Render-only checks sent no emails and changed no records. See [formatting release evidence](audit/NTE_EMAIL_FORMATTING_2026-09-07.md). The separate update-rejection feedback and supplementary-owner findings remain unchanged.

7 September stress-run approval: the owner authorised a broad sandbox form, workflow, UI, reporting and email audit, realistic synthetic records, fixes for demonstrated defects against confirmed requirements, and a numbered report separating completed fixes from uncertain proposals and 20 future feature ideas. Use representative journeys in the owner's Anthrion inbox and reserved example addresses for the bulk. Preserve real legacy records and the prior completed walkthrough. This does not authorise production deployment or new feature implementation.

8 September continuity request: save a durable checkpoint before usage exhaustion and resume the remaining audit after the owner's reset. [NTE_AUDIT_RESUME.md](NTE_AUDIT_RESUME.md) records exact completed journeys, known issues, remaining tests, protected records and restoration evidence. A usage pause does not mark the audit complete and does not authorise redeeming a reset credit.

8 September export decision: the owner said not to account for names beginning with `=`. Decline stress-audit P10's proposed org-wide export-setting change and leave intake names and exports unchanged. Do not keep presenting this as an outstanding production decision.

7 September stress-run clarifications: continue accepting staff, vehicle and logo preparation updates for Closed Lost/cancelled bookings. If staff record booking payment while the provisional email has failed, send the payment confirmation immediately; do not block that confirmation on provisional-email success. This clarifies the exceptional failure case while preserving the usual provisional-before-payment journey. Whether a later provisional retry should be replaced/suppressed after payment remains undecided.

7 September stress-run routing: before live submissions, the sandbox Default Lead Owner was aligned with Steven (in addition to the existing Default Lead Creator and NTE routing override). This prevents volunteer/internal notifications inheriting the legacy fallback owner. Notify Default Lead Owner remains disabled; no existing record ownership changed. Production must use its own agreed active owner. A real unchanged volunteer-form submission with useDefaultRule=0 produced two distinct applicant receipts, proving overlap with the native auto-response. Only the sandbox volunteer entry is now disabled using formula FALSE; all four unrelated native entries and their senders/templates are unchanged. The Apex applicant/internal acknowledgements remain active. Verify one applicant receipt on the next controlled submission and inspect the corresponding native setup separately before production release.

8 September stress-audit outcome: the approved corrections and recorded test scope are complete. [The numbered audit](audit/NTE_STRESS_TEST_AND_IMPROVEMENTS_2026-09-07.md) records 34 implemented fixes, remaining P-numbered decisions/limitations and 20 unimplemented U-numbered ideas. All 34 valid bulk and four separate representative preparation journeys reached Completed, including one-time top-ups, names-only corrections, full logistics replacement, exact Primary Contact routing and preserved final-pack history. The corrected volunteer route produced one actual receipt and its Mission Motorsport logo uses a valid PNG. All nine reports and the full native roster CSV reconcile; all 2,057 retained pre-run records remain unchanged and the owner's inbox messages are retained.

Final release evidence: actual full deployment `0AfAd00000SpIFhKAN` (423 components/278 tests), followed by email-formatting deployment `0AfAd00000SpkOrKAJ` (15 components/24 tests), and final complete-manifest check-only `0AfAd00000Spkn3KAB` (423 components/281 tests, zero errors). All 485 source/manifest hashes match. Canonical preview commit `8d1f7c19f4f18f73905147669e7a9147ed62d14c` is published, with 59/59 intended hosted files byte-verified. Temporary final-pack URLs are restored to blank and no test sends are pending. The final [handoff](NTE_AUDIT_RESUME.md) identifies exact results and finite coverage; do not repeat completed submissions from older registry snapshots. No production release, real logo upload, real client final pack or Stripe charge is implied.

8 September Stripe planning request: the owner said Stripe is nearly signed off and requested a comprehensive plan for both application types: Stripe selected on application → Mission Community conversion/provisional allocation → existing detailed email with the correct payment link → payment and agreed notifications. This authorises research and documentation, not activation, implementation, payment collection or deployment. Proposal 11 retains its number and pending implementation status.

8 September earlier confirmation-route clarification: the owner would discuss manual versus automatic payment confirmation with the client and explicitly requested diverging, researched routes for both to avoid choosing an unsupported Salesforce design. Both remained unselected at that point. [The dated plan](NTE_STRIPE_IMPLEMENTATION_PLAN_2026-09-08.md) records supported platform building blocks, the read-only Enterprise Edition observation, required test-mode feasibility gates and unresolved financial/operational decisions. No new sends, charges, sandbox changes, website publication or production release occurred.

8 September later route selection and test-setup request: the owner chose manual confirmation and requested the setup steps, division of responsibilities and extensive pre-production testing. They confirmed that the client still needs to grant Stripe access. The [manual setup and qualification plan](NTE_STRIPE_MANUAL_SETUP_AND_TEST_PLAN_2026-09-08.md) specifies a dedicated client-owned Stripe sandbox, MMUAT, secure credentials, configuration comparison and 60 planned test scenarios. Automatic request creation/email remains the target; successful Stripe payment must leave Salesforce provisional until staff verify and record it. The scenarios have not been run. No Stripe sandbox/key/request/payment, code change, email send, deployment or publication was performed in this planning follow-up. This selection does not settle product/tax, P03/P01, top-up-order or cancellation policies.

8 September Payment Links and production-checkpoint request: the owner selected Stripe Payment Links only, excluding Stripe Invoicing, and will confirm the remaining financial configuration. They asked about test-to-live migration and using their own account for initial tests; this is not a request to create a Stripe account yet. They also authorised a fresh dependency check, inclusion of genuinely required missing metadata, and uploading the complete project checkpoint to a new GitHub repository. Production access/deployment was discussed as an option, not authorised for execution. Preserve unrelated team metadata and report any shared-setting conflicts; the later message reaffirmed that no additions are needed if the dependencies are already complete.
