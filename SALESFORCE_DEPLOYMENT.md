# Salesforce deployment and support notes

Operational workflow updated 13 September 2026. Proposal 22's independent Invoice Requested refinement and final review are released and qualified in MMUAT. Full validation `0AfAd00000SuVgvKAF` passed 351 tests; actual release `0AfAd00000SuVllKAF` applied the unchanged package and 11 safe metadata retirements. Older-fixture cleanup is recorded separately; production remains a distinct release. [Current checkpoint](NTE_AUDIT_RESUME.md).

## Architecture

- Public forms create Leads through Salesforce Web-to-Lead.
- Expressions of interest and guest registrations remain Leads.
- Browser-side price summaries are advisory. `NTEPricingService` recalculates every recognised package, exhibitor space, socket and additional-staff amount from a server-side allowlist before the values are used downstream.
- Approved partner / sponsor and exhibitor Leads are converted manually using Salesforce's standard conversion screen. Every application must create a new Opportunity; Account/Contact reuse is allowed. The new booking name ends with the saved event code. No-booking and existing-booking conversion choices must fail before copying application fields or queuing work.
- `NTE Copy Converted Lead to Opportunity` copies event/application and pricing data to that new Opportunity, sets Opportunity Amount to the recalculated total including VAT, and does not change the org-wide Lead conversion mapping. Conversion sends no email, creates no Stripe request and confirms no space.
- The approved Invoice Requested refinement records a separate applicant Yes/No choice, independently of Stripe or bank transfer. Keep it distinct from billable-price flags. Payment Method comes first; the whole exhibitor finance section is hidden and disabled at £0 and restored by a chargeable space, socket or staff extra. Partner finance remains visible. Form-to-Lead-to-Opportunity propagation, native permissions/reports, actual emails and hosted pages are qualified in the final audit.
- Finance uses Requirements, Payment required and Payment confirmed. Requirements contains the applicable manual booking/free-space/top-up action and independent checklists. Sending does not tick requirements. Accepted payment requests move to Payment required once no other charge awaits release; staff record the exact base or top-up receipt there. A later positive top-up reopens Requirements without changing the original payment or its confirmation history.
- Completed requires valid pricing, original paid/free confirmation, all actual charges paid and applicable staff/vehicle/logo preparation. Procurement checkboxes do not gate it. Staff send customised joining instructions themselves and record the manual marker from Completed; automated final-pack distribution is retired from the workflow.
- Staff and heavy-vehicle submissions create temporary Leads. `NTE Supplementary Update Handler` matches the Opportunity solely by the exact target booking reference. It deletes the temporary Lead only after the Opportunity update and acknowledgement email both succeed. Unmatched or failed submissions remain in the NTE Unmatched Updates list view.
- The NTE Management app opens on Home, followed by Master Panel. Home provides the commercial-value portfolio; Master Panel provides operational queues and event delivery breakdowns.
- `NTE Operations & Finance/Weekly Finance Report` uses the rolling last seven days by Last Modified Date for active/won NTE Event Opportunities. It includes pricing components, VAT/gross totals, finance states, independent requirement/payment history and billing details. Reconcile the final report scope and columns with the qualified manual-finance candidate.
- The previous `NTE_Event_Registration__c` and `NTE_Registration_Attendee__c` implementation is intentionally untouched.

## Safe deployment

Build and test locally:

```sh
npm run validate
```

Validate against a sandbox:

```sh
sf project deploy start --source-dir force-app --target-org mission-mmuat --dry-run --test-level RunSpecifiedTests --tests NTEPricingServiceTest --tests NTEInboundLeadServiceTest --tests NTEUpdateSubmissionServiceTest --tests NTEConversionFlowTest
```

Validate the complete production package and all local Apex tests:

```sh
sf project deploy start --manifest manifest/production-package.xml --target-org mission-mmuat --dry-run --test-level RunLocalTests
```

Deploy only after the validation succeeds. The manual-pricing retirement manifest exists for a separately reviewed schema migration; it is not a routine installation step. Preserve target data and inspect dependencies before any destructive change.
Follow the paired source/MMUAT process in `PRODUCTION_PACKAGE_SYNC.md` for every approved change.

For production, follow [the current release plan](NTE_PRODUCTION_DEPLOYMENT_PLAN_2026-09-08.md). Retrieve and reconcile the shared LeadSource/OpportunityStage definitions before validation. Preserve existing business layouts and page assignments using [the required page-isolation checks](deployment/NTE_PAGE_ISOLATION.md). Only NTE Management receives the NTE record pages; no shared layout, Profile, other app or global page default is deployed. Apply any reviewed target overlay after the generator runs, then freeze and validate that exact candidate. Production access and release are separate from sandbox qualification.

## Lifecycle checks

Use fresh, explicitly authorised QA data and test-controlled email addresses. Preserve existing audit ledgers and all ten NTE-UI-20260913 fixtures. These are future qualification steps, not instructions to repeat successful historical submissions, sends or receipts.

1. Submit both kinds of expression of interest and confirm each remains a Lead, is routed correctly, and receives its acknowledgement.
2. Submit a partner / sponsor application and an exhibitor application. Confirm unique booking references, on-screen receipt and internal notification, with no applicant application-received email. Verify independent Invoice Requested answers with both payment methods and the exhibitor £0 finance-section boundaries.
3. Convert to a deliberately selected Account/Contact and a new Opportunity. Confirm copied application/invoice-choice fields, VAT amount and event-code name suffix, with no email, request or space confirmation. Verify no-booking/existing-booking refusals and rollback using isolated authorised cases; preserve non-NTE conversion behaviour.
4. From Requirements, save checklist ticks independently and release the applicable Stripe, bank-transfer or free-space action with unticked requirements. Verify the accepted request/explicit free confirmation, actual Primary Contact email and unchanged checklist values. A queued or failed send is not a delivered message.
5. In Payment required, record an independently verified base receipt once. Confirm the single booking-confirmation request and preservation of the payment if its notification fails. Verify separate top-up receipt handling without repeating that base confirmation.
6. Submit a staff update with the exact booking reference. For the one permitted positive top-up after base payment, verify Requirements → manual Send Stripe link → Payment required → manual top-up receipt → Payment confirmed. Preserve original payment, checklist ticks and one-time purchase history; a name correction must not create another purchase.
7. Submit a heavy-vehicle update with the exact reference and verify its intended replacement fields. Submit a deliberately unmatched supplementary reference and confirm no booking changes while the failed submission remains available for review.
8. Complete applicable staff/vehicle/logo preparation. Verify Completed ignores procurement ticks and that the joining-instructions marker records only the staff action, without sending an email or making the marker an entry condition.
9. Submit a guest registration and confirm it remains a Lead in NTE Guest Registrations. For paid, discounted and complimentary applications, plus invalid-price rejection, compare browser, Lead, Opportunity, saved Stripe charge and report amounts including VAT.
10. Verify the existing assignment rules, auto-response rules, duplicate rules, old NTE custom objects and unrelated flows are unchanged except for separately approved, precisely recorded changes.

## Volunteer acknowledgement after deployment

When `Volunteer_Inbound_Lead_Notification` and `VolunteerInboundLeadService` are installed, the service sends and audits the volunteer applicant acknowledgement and the internal owner notification. Check for a matching native Lead auto-response so an applicant receives one acknowledgement.

1. Inspect the target org's active Lead auto-response rule and Web-to-Lead Default Response Template. Identify any entry that matches `LeadSource = Volunteer Application` and `Web_Form_Type__c = Volunteer Application` and sends the volunteer acknowledgement. Record the existing entry and surrounding rules before changing it.
2. Disable only the overlapping volunteer entry, for example by changing its formula criteria to `FALSE`. Preserve the active rule, unrelated entries, sender addresses and templates. Inspect the target org's actual criteria rather than relying on an entry number. A failed whole-rule metadata update caused by an unrelated legacy sender does not justify changing that sender.
3. In MMUAT on 7 September 2026, entry 5 of `Web to Lead Auto Response External` was disabled through the UI with formula `FALSE`; its sender/template and the other four entries were preserved. Retrieve the rule and verify the saved criteria and unchanged entries as release evidence. Production requires its own inspection and separately authorised configuration change.
4. Submit the canonical volunteer form to a controlled inbox, with the intended controlled Lead creator and owner. Verify one applicant acknowledgement, the expected internal notification, and the service's saved acceptance statuses. Check distinct inbox message IDs and native response Tasks/Activity History; also confirm the Default Response Template does not introduce a replacement duplicate.

The canonical volunteer form posts `useDefaultRule=0`. In the MMUAT baseline this still produced two applicant receipts and a native response Task when the overlapping entry was enabled. Neither that parameter nor passing Apex tests replaces the Web-to-Lead/inbox check. The rule change above is the narrow exception to lifecycle check 10; unrelated assignment and auto-response behaviour remains intact.

## Pricing backfill

`scripts/post-deploy/backfill-nte-pricing.apex` recalculates existing NTE application Leads and Opportunities using the deployed pricing catalogue. It is update-only and performs no deletes, but it changes saved monetary values. It is not a routine release step. Use it only for an explicitly authorised, inventoried migration with financial-history preservation and before/after reconciliation; do not reprice historical bookings merely because code was deployed.
