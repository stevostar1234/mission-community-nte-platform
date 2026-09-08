# Salesforce deployment and support notes

## Architecture

- Public forms create Leads through Salesforce Web-to-Lead.
- Expressions of interest and guest registrations remain Leads.
- Browser-side price summaries are advisory. `NTEPricingService` recalculates every recognised package, exhibitor space, socket and additional-staff amount from a server-side allowlist before the values are used downstream.
- Approved partner / sponsor and exhibitor Leads are converted manually using Salesforce's standard conversion screen. The user selects the correct Account and Contact and creates/names the Opportunity.
- `NTE Copy Converted Lead to Opportunity` copies event/application and pricing data to that Opportunity, sets Opportunity Amount to the listed ex-VAT total, and does not change the org-wide Lead conversion mapping.
- Staff and heavy-vehicle submissions create temporary Leads. `NTE Supplementary Update Handler` matches the Opportunity solely by the exact target booking reference. It deletes the temporary Lead only after the Opportunity update and acknowledgement email both succeed. Unmatched or failed submissions remain in the NTE Unmatched Updates list view.
- The NTE Management app opens on Home, followed by Master Panel. Home provides the commercial-value portfolio; Master Panel provides operational queues and event delivery breakdowns.
- `NTE Operations & Finance/Weekly Finance Report` is an Opportunity report filtered to the rolling last seven days, NTE Event Opportunities and finance-relevant records. It includes pricing components, confirmed value, quote/invoice/payment milestones and billing details.
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

For production, follow [the current release plan](NTE_PRODUCTION_DEPLOYMENT_PLAN_2026-09-08.md). Retrieve and reconcile the shared LeadSource/OpportunityStage definitions before validation. Apply any reviewed target overlay after the generator runs, then freeze and validate that exact candidate. Production access and release are separate from sandbox qualification.

## Lifecycle checks

Use clearly labelled `NTE QA` data and a test-controlled email address.

1. Submit both kinds of expression of interest and confirm each remains a Lead, is routed correctly, and receives its acknowledgement.
2. Submit a partner / sponsor application and an exhibitor application. Confirm each has a unique booking reference and the reference appears in the acknowledgement.
3. Manually convert an application Lead to a deliberately selected test Account/Contact and a new test Opportunity. Confirm the NTE fields copy to that Opportunity.
4. Submit a staff update with the exact booking reference. Confirm the Opportunity changes and the temporary Lead is removed only after success.
5. Submit a heavy-vehicle update with the exact reference and repeat the same checks.
6. Submit a supplementary form with a deliberately unmatched reference. Confirm no Opportunity changes and the Lead remains in NTE Unmatched Updates.
7. Submit a guest registration and confirm it remains a Lead in NTE Guest Registrations.
8. For paid, discounted and complimentary variants, plus invalid-price rejection, compare the browser summary, Lead numeric fields, converted Opportunity numeric fields, Opportunity Amount and finance report totals.
9. Verify the existing assignment rules, auto-response rules, duplicate rules, old NTE custom objects and unrelated flows are unchanged.

## Volunteer acknowledgement after deployment

When `Volunteer_Inbound_Lead_Notification` and `VolunteerInboundLeadService` are installed, the service sends and audits the volunteer applicant acknowledgement and the internal owner notification. Check for a matching native Lead auto-response so an applicant receives one acknowledgement.

1. Inspect the target org's active Lead auto-response rule and Web-to-Lead Default Response Template. Identify any entry that matches `LeadSource = Volunteer Application` and `Web_Form_Type__c = Volunteer Application` and sends the volunteer acknowledgement. Record the existing entry and surrounding rules before changing it.
2. Disable only the overlapping volunteer entry, for example by changing its formula criteria to `FALSE`. Preserve the active rule, unrelated entries, sender addresses and templates. Inspect the target org's actual criteria rather than relying on an entry number. A failed whole-rule metadata update caused by an unrelated legacy sender does not justify changing that sender.
3. In MMUAT on 7 September 2026, entry 5 of `Web to Lead Auto Response External` was disabled through the UI with formula `FALSE`; its sender/template and the other four entries were preserved. Retrieve the rule and verify the saved criteria and unchanged entries as release evidence. Production requires its own inspection and separately authorised configuration change.
4. Submit the canonical volunteer form to a controlled inbox, with the intended controlled Lead creator and owner. Verify one applicant acknowledgement, the expected internal notification, and the service's saved acceptance statuses. Check distinct inbox message IDs and native response Tasks/Activity History; also confirm the Default Response Template does not introduce a replacement duplicate.

The canonical volunteer form posts `useDefaultRule=0`. In the MMUAT baseline this still produced two applicant receipts and a native response Task when the overlapping entry was enabled. Neither that parameter nor passing Apex tests replaces the Web-to-Lead/inbox check. The rule change above is the narrow exception to lifecycle check 9; unrelated assignment and auto-response behaviour remains intact.

## Pricing backfill

`scripts/post-deploy/backfill-nte-pricing.apex` recalculates existing NTE application Leads and Opportunities using the deployed pricing catalogue. It is update-only and performs no deletes, but it changes saved monetary values. It is not a routine release step. Use it only for an explicitly authorised, inventoried migration with financial-history preservation and before/after reconciliation; do not reprice historical bookings merely because code was deployed.
