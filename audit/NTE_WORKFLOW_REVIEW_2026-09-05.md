# NTE workflow review — 5 September 2026

**Historical review: the current desired behaviour is maintained in [NTE_DESIRED_WORKFLOW.md](../NTE_DESIRED_WORKFLOW.md), with numbered approvals in [NTE_CHANGE_PROPOSALS.md](../NTE_CHANGE_PROPOSALS.md).** Later owner decisions supersede recommendations below: use the Opportunity's Primary Contact Role for the panel and all post-conversion booking emails; preserve contacts while replacing heavy-vehicle details; allow only one positive staff top-up request, locked at its first valid acceptance with names still editable. The earlier recommendation to support multiple billed top-ups is no longer the target design. The source findings remain historical evidence, not proof that fixes have been applied.

Internal review and decision record. No proposed implementation in this document has been applied. This records the client's workflow as clarified by the project owner and supersedes conflicting assumptions in the earlier audit. Source findings refer to the current local package; this follow-up did not execute conversions, send emails, run org tests or change Salesforce records.

Latest clarification, also on 5 September: the project owner wants separate staff top-up refiners and sequential invoice-sent/payment-received buttons. The team has agreed that the post-conversion email should contain the itemised quote/invoice information and automatically generated Stripe payment link together. This replaces the earlier suggestion of routinely sending a separate quote followed by a later Stripe email. Product implementation remains pending.

## Agreed workflow and boundaries

| Stage | Meaning and communication |
| --- | --- |
| Expression of interest | Staff assess suitability, communicate with the organisation and decide whether to invite it to apply. |
| Progressed | Under the existing manual process, outreach is finished and the application invitation has already been sent. The past-tense label is correct. Not progressed closes the other outcome. |
| Application submitted | Send an acknowledgement that the application is being reviewed. External applicants can enter directly at this stage. |
| Application approved and converted | The space is provisionally reserved. The applicant first receives staff, applicable heavy-vehicle and logo update links at this point, alongside the payment link where a payment request is ready. The project owner explicitly confirmed this timing. |
| Payment recorded | The space is confirmed. The proposed initial Stripe integration retains manual payment verification and the team's Has paid action. |
| Completed | All applicable finance and preparation requirements are satisfied, including the agreed logo requirement. |
| Final pack | The team distributes the event instructions to completed bookings that have not received the pack. Completion and pack distribution remain separate facts. |

Intentional decisions, rather than current defects:

- The client currently wants open internal access. Restriction may be requested later; retain this as a future decision, without changing access now.
- The GitHub site is for client review of forms and email examples. Final forms will be hosted on the NTE site. Keep the review site and configure production destinations when provided.
- The SharePoint logo upload link is still a client dependency.
- Booking-reference matching is intentional. An optional future convenience is prefilling that same reference in update links; the current form script does not implement that prefilling.
- Recent-date ordering is adequate. Do not add urgency or overdue classifications without the business data to support them.
- A participant portal is not requested. Space-capacity management remains deferred.
- Old dummy data may reflect earlier briefs. Its missing fields or timestamps do not establish a current code defect and do not justify automatic backfilling.
- Dummy records with verified example addresses or the project owner's email variants may be used in a later authorised test. Real legacy Contacts and Accounts must not receive test messages. A separate unrelated-legacy regression exercise is not requested.

## Proposed invitation action

Keep the human suitability decision. Add **Send application invitation** (or **Progress & send invite**) after outreach, with **Mark as already invited** preserving manual handling. Existing progressed records must remain unchanged and receive no installation-triggered email.

Use an explicit form-type mapping:

| Interest type | Application destination |
| --- | --- |
| Exhibitor Expression of Interest | Exhibitor application |
| Partner / Sponsor Expression of Interest | Partner / sponsor application, for every partnership/sponsorship subtype |

Add the two application destinations to routing configuration and associate them with the intended event. Do not derive a destination from free text or silently fall back to another form. Current public forms assign the event from the date/configuration; adding an event query parameter alone would not make an invitation event-specific.

Allow individual invitations and, if wanted, invitations to a selected group that staff have reviewed. Preview actual recipients, the event, content and destination links. Send against those selected record IDs, rechecking current eligibility before dispatch. A change of recipient or event should require a refreshed preview.

Claim queued work so two staff members cannot send the same invitation concurrently. Set Progressed only after Salesforce accepts that record's email request. Keep a failed invitation actionable. Record the recipient, initiating staff member, time, template/link and outcome. Accepted for delivery does not prove inbox delivery or reading.

This is a bounded extension of existing panel controls and Apex services. It does not require automatically inviting every incoming interest or building a broader nurturing platform.

## Proposed HTML reminders

The custom Remind All implementation currently uses `setPlainTextBody()` in `NTE_MasterPanelController.cls:680`. The polished approval templates are a separate feature and do not change those reminders.

Retain the current staff, heavy-vehicle and logo refiners. Use a reusable branded HTML layout with a plain-text alternative: logo/header, personal greeting, concise request, booking reference, appropriate action button and NTE contact details. Staff can edit approved text fields without editing HTML. Escape inserted values and validate configured links.

Preview a fully personalised example and the exact recipient list, rather than only a recipient count and unresolved placeholders. Each booking receives an individual message. Recheck that the requested update is still outstanding before sending. Freeze the reviewed audience instead of adding new matching records between preview and dispatch.

Show last reminder time and outcome. Prevent simultaneous duplicate sends; an intentional later reminder must remain possible because reminders can legitimately recur. Support background batches within the org's email limits when the audience exceeds the current 100-recipient action limit. Surface individual failures and allow targeted retries.

The existing sender uses the Opportunity's primary Contact email, whereas the panel displays the booking's event-contact email. Make the intended operational recipient explicit and use it consistently; do not assume those addresses always match. Prefer the booking contact for event communications unless the client chooses otherwise. Record who actually received each message.

## Proposed final-pack refiners

Use **Completed → Final pack not sent / Final pack sent**, with **Distribute final pack** acting on the selected eligible bookings.

Track dispatch per booking/Opportunity and event, rather than per Account, email address or whole event. A minimal status is Not sent, Queued, Sent or Failed, supported by sent time/recipient/initiating user, attempt time, job ownership and the last error.

The not-sent refiner may display queued and failed rows with clear status badges. The initial send acts only on completed Not sent rows; Retry failed acts only on completed Failed rows. Queued and Sent rows cannot enter another ordinary send. Recheck readiness before sending, and mark each success individually after Salesforce accepts it.

Example: 50 completed bookings receive their packs. A 51st booking completes tomorrow. Only that new booking enters the ordinary unsent audience; the earlier 50 keep their sent history.

The pack can be a useful HTML email containing arrival, parking, setup, contacts and relevant document links. It does not have to be a PDF attachment. Its event and participant-type content must be checked just like application invitations. The team still controls when final instructions are ready for distribution.

Later staff changes or top-ups may reopen readiness. They must not erase the earlier pack dispatch or automatically resend it when the booking completes again. A corrected pack should be an explicit targeted resend. Pack-version tracking is optional if the client needs revised editions separately tracked.

## Proposed first Stripe integration

Recommend a dedicated, fixed-price Stripe Payment Link per booking and charge, created automatically after conversion when the commercial details are ready. Put that stored URL directly in the branded provisional email. The button opens Stripe's payment page; there is no need for an additional NTE participant/payment portal.

The agreed email now combines the provisional reservation, itemised quote/invoice information, payment button and preparation links. Generate the Stripe URL before rendering and sending that email. Use the same saved charge amounts for both the email and Stripe. The email should include supplier and customer billing details, appropriate document number and dates, descriptions, quantities, net amounts, applicable tax and total payable. Finance should determine the document's formal designation and numbering. If it is an issued invoice, follow the applicable invoice-content requirements; HTML delivery does not remove those requirements. [GOV.UK invoice contents](https://www.gov.uk/invoicing-and-taking-payment-from-customers/invoices-what-they-must-include)

Implementation proposal: the existing conversion Flow queues an Apex callout job after the booking has committed. That job authenticates to Stripe through Salesforce Named/External Credentials, creates the fixed-price Payment Link, and saves the returned Stripe ID and URL against the specific charge. A subsequent email job renders the combined document and records the send outcome. The local package currently records Stripe as a payment method but contains no Stripe link-creation code or packaged Named/External Credentials. One-time account/credential setup is therefore part of the integration. [Salesforce credentials](https://developer.salesforce.com/docs/platform/named-credentials/guide/get-started.html), [Queueable Apex](https://trailhead.salesforce.com/content/learn/modules/asynchronous_apex/async_apex_queueable)

Sequence: approved booking committed → create and store its payment link and amount → send its provisional email → record Invoice / Stripe link provided only after acceptance of the email request → staff verify the successful Stripe payment and record Has paid, with its reference and date.

A brief space-confirmed email after the initial Has paid action would complete the applicant's communication sequence for both Stripe and bank transfer. Send it once for the initial confirmation. If that notification fails, retain the true payment record and retry the notification separately.

Generate links server-side using secure Stripe credentials. Retain the Stripe ID, booking/event identity, charge purpose/version, amount, currency and tax treatment. Retry failed email sending with the same stored payment link. Creation retries need both Stripe idempotency and durable Salesforce records to avoid duplicate payment requests. A clicked link or completed checkout is not itself sufficient evidence for manual payment confirmation.

Use approved fixed amounts and quantities. The current catalogue expresses amounts excluding VAT; the payable amount and tax treatment must be agreed with the client's finance team and configured deliberately. Do not accidentally charge the ex-VAT figure as the full payable amount or add component prices again to an agreed whole-booking price.

Freeze the initial charge. Additional staff purchased later need their own top-up charge/link. Configure limited link reuse, and close obsolete card-payment routes when a booking is cancelled, repriced or switched to bank transfer. A one-completed-checkout limit helps prevent repeat use but does not establish that an asynchronous payment has succeeded.

| Situation | Proposed handling |
| --- | --- |
| Fixed price, Stripe, ready to request payment | Provisional email includes Pay with Stripe and the preparation links. |
| Quote / PO process required | The combined email contains the agreed itemised document and Stripe button. Where that document satisfies the quote request, its successful send can also fulfil Quote provided. Do not automatically mark an actual PO received merely because the email was sent. |
| Price on request | A final payable amount is still required. To keep a single combined email, hold it until staff record the agreed price. If every email must be immediate upon conversion, move price agreement into the approval step. Current Confirm agreed price works on an already converted Opportunity. |
| Bank transfer | Preserve the existing quote/invoice route and manual payment recording. |
| No payment due | Omit the payment request and use a suitable complimentary confirmation; do not leave the booking waiting for a payment that is not required. |
| Stripe generation/send failure | Keep visible pending/failed work and the payment-link-provided milestone incomplete; retry without issuing a second independent charge. |

Payment Links fit an email people may open days later. Raw Checkout Session URLs expire within 24 hours, so using those directly would need reissue handling or a stable redirect. Stripe Invoicing and Stripe Quotes are optional products, not prerequisites for a payment button. Existing external quotes can coexist with Stripe payments. Automatic Has paid through webhooks can be a later phase; manual Salesforce verification does not mean manual capture of the card payment.

If finance wants Stripe to issue and number the invoice itself, use Stripe Invoicing as an alternative to a Payment Link: create and finalise the invoice, retrieve its number, hosted payment URL and PDF URL, then insert those into the same NTE email. Configure delivery so this does not also trigger an unintended separate Stripe invoice email. Both approaches support the agreed single-email experience. [Invoice finalisation](https://docs.stripe.com/api/invoices/finalize), [hosted invoice and custom delivery](https://docs.stripe.com/invoicing/hosted-invoice-page)

## Separate staff top-up finance

The latest requested refiners and manual buttons are:

| Finance refiner | Action |
| --- | --- |
| Staff top-up invoice required | Staff top-up invoice sent |
| Staff top-up payment required | Staff top-up payment received |
| Staff top-up paid | Show recorded payment details |

Each action advances that specific top-up bill. It must neither depend on nor change the original booking payment. A booking with several top-up bills can appear in more than one outstanding refiner; show the relevant bill and amount clearly. The paid refiner should retain paid top-up bills even when another bill for the same booking is outstanding.

Once Stripe sending is implemented for top-ups, a successful automated email can record Staff top-up invoice sent. Staff top-up payment received remains manual until payment synchronisation is separately added. The visible business stages can stay the same through that integration.

Fresh source finding: `NTEUpdateSubmissionService.cls:234–257` treats the form's top-up count as cumulative, replaces its total with cumulative count × £50, and clears invoice/payment flags, timestamps and responsible users whenever the count increases. There is no separate paid-top-up amount in this model. The existing test `increasingTopUpReopensOnlyTopUpFinanceAndReductionIsRejected` at `NTEUpdateSubmissionServiceTest.cls:785` explicitly asserts that reset behaviour; it was read, not executed.

Example excluding VAT: two extra staff cost £100 and are paid. The applicant then adds one more, making the cumulative count three. The code stores £150 and marks top-up payment outstanding. A new Stripe link made from that cumulative total would request £150 again; the correct new request is £50. No automatic Stripe charge exists in the current package, so this finding describes the amount/history defect and its integration consequence, not an observed duplicate charge.

Preserve a small charge record per separately billed top-up: newly added places, unit price, net/tax/gross amounts, invoice/link identity, and invoice/payment dates and responsible users. Opportunity fields remain aggregate summaries. Keep Top-up 1 (two places, £100, paid) and Top-up 2 (one place, £50, awaiting invoice) separately. A draft may be consolidated before issue; once issued or paid, retain it and create another charge for additions. A names-only correction creates no charge. Creating charges must also be safe against repeated form processing and simultaneous submissions.

Relevant validation when this feature is implemented: pay for two extra places, add one more, preserve the original £100 payment and request only £50 more. Also cover additions while an earlier invoice is still unpaid, names-only changes, and independent original/top-up payment recording.

Primary references checked on 5 September 2026: [Payment Link creation](https://docs.stripe.com/payment-links/create), [Payment Link API](https://docs.stripe.com/api/payment-link/create), [Checkout Session expiry](https://docs.stripe.com/api/checkout/sessions/create), [link limits](https://docs.stripe.com/payment-links/customize), [link deactivation](https://docs.stripe.com/payment-links/share), [tax treatment](https://docs.stripe.com/tax/products-prices-tax-codes-tax-behavior), [Stripe Quotes](https://docs.stripe.com/quotes).

## Source findings that remain relevant

1. **Logo completion is omitted.** Both `isComplete()` at controller line 1183 and `completeClause()` at line 1378 omit `NTE_Logo_Update_Provided__c`. The combined update refiner also omits it. Align table status, counters, refiners and final-pack eligibility with the agreed readiness rule once the logo process is ready. Ensure every query supplying that calculation selects the logo field. This omission is independent of old test records.
2. **Initial and top-up payments are coupled.** `updateMilestone()` at controller lines 779–790 requires every applicable invoice before recording either payment, then selects the first unpaid charge. Since update links go out before initial payment, a staff top-up can block recording a verified initial payment. Make the action target the original charge or the top-up explicitly; allow each to be recorded against its own payment request. Do not invalidate an already confirmed base space because a later extra is unpaid, although final readiness may require that extra to be resolved.
3. **The partner receipt confirms too early.** `email-templates/source/partner-sponsor-application-received.html:19` says partnership/sponsorship confirmed and already includes a logo button. Revise it to under review and move preparation links to the post-conversion message. The existing exhibitor application receipt is a usable starting point; all wording, buttons and preview examples need to follow the revised timing.
4. **The current conversion email service handles exhibitors only.** `NTEExhibitorApprovalEmailService.cls:186` excludes other source types. Wire the partner/sponsor provisional message into the intended conversion route. Use current booking values for future payment requests, rather than relying on stale original Lead values.
5. **The approval entry point ignores its explicit IDs.** At service lines 49–58 it schedules a 15-minute sweep of recently modified converted exhibitor Leads. Narrow that selection to the requested conversions when changing this service. This is not evidence that any unrelated person has been emailed, and does not justify a separate legacy remediation project.
6. **Reminder recipient and displayed contact can differ.** Controller line 1604 selects primary Contact email; the panel uses event-contact fields. Resolve the intended operational contact and expose the actual address before sending.
7. **Logistics updates replace fields absent from the form.** `NTEUpdateSubmissionService.cls:369` replaces all three vehicle slots and clears some contact title/prefix/mobile values the form does not collect. The form instruction at `heavy-vehicle-details.html:13` can encourage separate submissions per item. Preserve unedited contact fields and make whole-list replacement versus adding items explicit.

A further workflow detail to settle during implementation: an applicant who originally answered that heavy-vehicle requirements were unknown must be able to tell the team that no heavy vehicle is needed. The present public logistics form always records Yes and requires an item. Staff can resolve this operationally; a small Not required route would reduce needless reminders if self-service is wanted.

## Proportionate scope and validation

HTML reminder presentation is the smallest change. Invitation sending and final-pack distribution are moderate extensions because their recipient review, status tracking, concurrency and failure handling matter. Automatic Stripe link creation is a separate integration with more financial configuration and recovery work. They can share branding and dispatch components without becoming one large redesign.

Useful optional additions are a communication history showing recipient/date/outcome, and a Being handled by marker on interests while outreach is underway. The existing Progressed action already resolves ownership once outreach has finished.

Retain focused automated tests for current conversion and email rules. A new unrelated-legacy suite is unnecessary. Test fixtures should create fresh synthetic records matching the current form/pricing version, including synthetic pre-existing Account/Contact matches when that path is relevant. Later acceptance checks should cover both invitation routes, manual already-invited handling, failed and simultaneous sends, a newly completed booking after pack distribution, logo readiness, quote/POA/complimentary branches, and independent base/top-up payments. Inspect all intended email recipients, including internal notifications, before any later interactive sandbox submission or conversion.

This document records decisions and recommendations only. Product source, Salesforce configuration and records have not been changed by this follow-up review.
