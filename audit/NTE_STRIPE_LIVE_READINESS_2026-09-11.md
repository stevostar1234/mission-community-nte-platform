# Stripe live-mode readiness and focused remaining checks

Completed 11 September 2026 under proposal 20. This is internal release evidence. Source and MMUAT were changed; no production org, client Stripe account, live credential or real-money payment was used.

## Released behavior

The owner approved removing the blanket live-payment rejection, while preserving the fixed-price Payment Links integration and manual Salesforce confirmation. The release uses explicit `Live_Mode__c` configuration and a saved mode on each payment request. `NTE_Stripe_Test` and `NTE_Stripe_Live` are separate Named/External Credentials. The expected Salesforce org, Stripe merchant, returned environment, resource identities, fixed amount/currency, metadata and hosted URL must still match. Live accounts must report `charges_enabled=true`.

MMUAT remains enabled in test mode for `acct_1UD8GwBcW1MkMYQ1`, with the existing test credential, GBP, 20% provisional tax, and blank optional recipient/reference filters. New live credential definitions are deployed; this task did not populate a live secret or activate live collection. Existing request fingerprints and payloads are preserved; explicit saved-mode checks prevent test requests being relabelled during a later config switch.

The existing permission-set API name `NTE_Stripe_Test_Operator` is preserved to keep group assignments intact. Its label is now **NTE Stripe Payment Operator**, granting use of the appropriate test/live principal through the existing **NTE Management Access** group. This is credential-use permission, not disclosure of the secret or Stripe Dashboard access. Target credentials must be populated separately during the authorised account transition.

The Python preflight now supports explicit test/live configuration and matching key types. It only reads account/balance state; it neither activates collection nor proves Price/Link creation. `config/stripe-live.example.json` is disabled and contains placeholders, not live account settings or secrets.

## Release qualification

| Check | Result |
| --- | --- |
| Corrected actual MMUAT deployment | `0AfAd00000StiwNKAR`: 17 components, 51 affected Apex tests, zero errors |
| Complete production manifest, check-only against MMUAT | `0AfAd00000SttlJKAR`: 474 components, 314 RunLocalTests, zero errors |
| Exact package reconciliation | All 474 canonical member identities and 538 canonical source/manifest hashes match the final candidate |
| Native Apex parity | All five changed Apex bodies match source |
| Local build/validation | `npm run validate` passed; direct Python preflight suite passed 7 tests |
| Existing payment requests | All nine captured records retain their prior fields and timestamps; new mode defaults false |
| Existing business/history records | 166 Opportunities, 795 Leads, 727 Accounts, 818 Contacts and 107 email dispatches retain captured timestamps/deletion state |
| Public site | No public form/email-preview changes; no publication needed |

Canonical aggregate SHA256: `dd25528817f95098b45d242f0f107d5ce61ae6341d21ab7a5d378b8c08a9f2e8`. The raw capture also contains the unchanged `.gitkeep`, giving 539 captured paths; it is excluded from the canonical deployment-source count. Salesforce reports the manifest's `Report:NTE_Operations/` folder as `ReportFolder:NTE_Operations`; reconciliation normalizes that identity explicitly.

The first actual attempt, `0AfAd00000StZmdKAF`, rolled back after one new live test fixture incorrectly combined request creation and a callout in one test transaction. The fixture was moved into committed test setup to match the asynchronous production boundary. The corrected deployment and full validation passed without removing the assertion. Retain `tmp/nte-stripe-launch-readiness-20260911/attempt-1/` as evidence; do not replay it.

The maintained public-copy scan checked 86 captured HTML/email/JavaScript files and found no reviewer/prototype commentary. The repository-wide `git diff --check` is not clean because of generated whitespace, including blank indented lines in the permission files; this is recorded in the task log and was not expanded into an unrelated formatting release.

New/expanded automated cases cover valid live API responses and email URLs, wrong environment/account, a live merchant unable to charge, 401/403/429 responses, timeouts and malformed responses, a timeout after Price creation with stable recovery, environment changes before/after verification, failed-email reuse of the saved link, and past-date/Closed Won eligibility. Mocked live success is not a live merchant acceptance test. Existing secrets were not revoked to manufacture these failures.

## One new application and checkout

Fenwick Mobility Systems Ltd / Fenwick Mobility, Amelia Hargreaves, uses only the owner's test email `steven.skyba@anthrion.com`.

| Identity | Value |
| --- | --- |
| Lead | `00QAd00000UZXcXMAX` |
| Opportunity | `006Ad00000UoJPZIA3` |
| Account / Contact | `001Ad000019Jk9XIAS` / `003Ad00001ABYhdIAH` |
| Booking reference | `NTE-1789144940429-AWK58CK2` |
| Payment request | `a09Ad00000P3TyfIAF` |
| Stripe Price / Payment Link | `price_1UEXY2BcW1MkMYQ17KLzp4wO` / `plink_1UEXY3BcW1MkMYQ1v25Kq4XY` |
| PaymentIntent | `pi_3UEXimBcW1MkMYQ104cKzsDr` |
| Successful Charge | `ch_3UEXimBcW1MkMYQ10zv6dxON` |

The current form payload was submitted once through Web-to-Lead and converted once with `Database.convertLead` into a new booking. Only this new Opportunity was assigned `CloseDate=2026-06-11`, three months before the test. It stayed in Qualification and open. The normal asynchronous process created a verified test link and sent the provisional reservation at 16:43:36 UTC. The actual received HTML/plain-text email has £799.00 net, £159.80 VAT and £958.80 payable, one currency symbol per amount, the correct reference and exact saved test URL. Gmail message `1a0915a682198c42` verifies delivery.

Chrome checkout used Stripe's published 3DS sandbox card ending 3220, with fictional billing details. Cancelling the bank-authentication window produced `payment_intent_authentication_failure`, `requires_payment_method`, zero amount received and zero Charges. The link remained active with zero completed uses. Retrying the same checkout and completing authentication produced the **same PaymentIntent**, one authenticated Charge for 95,880 pence, a paid/complete session, and an inactive Payment Link with one of one uses. The hosted success page displayed the agreed staff-confirmation message. No real card was used or saved.

Salesforce still shows payment not received, finance payment due and Qualification after Stripe succeeds, exactly as the selected manual-confirmation workflow requires. The new paid-in-Stripe booking is available for the owner's manual confirmation demonstration. Earlier payment/refund/dispute records were not replayed.

A 390 × 844 viewport showed readable mobile layout, amount, card fields and Pay button. Apple Pay was visible, but no actual wallet/device payment was attempted. Bitwarden autofill intermittently blocked browser automation; Chrome's native controls dismissed the popup and dummy card-saving prompts. The completed mobile test tab was closed; the original Chrome tab remains at normal size on sandbox Transactions.

## NTE-only Stripe notifications

A native Dashboard Workflow, **NTE booking payment received**, was created temporarily in the owner sandbox:

- Trigger: Payment intent succeeded.
- Condition: Payment intent metadata `nte_charge_kind` equals `Booking`.
- True branch: Email team member, Steven Skyba / owner email only.
- False branch: no action.
- Body: “An NTE booking payment has been received. Review the payment in Stripe before recording receipt in Salesforce.”

Workflow ID: `wf_test_61VNvYRKvATggSuZt16VMWEI38SQZq4ZJLRDaFVSi3lg`. Its two runs are retained and the Workflow is **Inactive** after testing.

1. The native **Test workflow** action created Stripe's generic $20 fixture, `pi_3UEXcSBcW1MkMYQ11UOnITiU`, Charge `ch_3UEXcSBcW1MkMYQ11FoKobHx`, with empty metadata. Run `wfrun_test_61VNvZqe3EhVSmw8Y16VMWEI38SQZq4ZJLRDaFVSiK5g` completed with **condition false / Email team member did not run**.
2. Fenwick's genuine sandbox checkout produced run `wfrun_test_61VNvhnf2g4DVihgP16VMWEI38SQZq4ZJLRDaFVSiWmW`: **condition true / Email team member step completed**. One email reached the owner at 16:56:29 UTC, Gmail `1a09166356545c4b`, subject `[Sandbox] NTE booking payment received Notification`.

This demonstrates a native NTE-only payment-success notification without a custom Salesforce webhook service. Kate was not invited to Stripe or subscribed by this test. Configure the client recipient and confirm feature availability/terms before activating there. The demonstrated alert is a brief notification, not a transaction summary; useful dynamic reference/amount fields can be considered during configuration. Other teams' notifications and global Radar/payment settings were not changed. Notification filtering is distinct from Dashboard data access: a Stripe role is not an NTE-only row-visibility filter. Refund/dispute events require separate filtering tests if requested.

## Dates, revised prices and cancellations

Native investigation found no NTE automatic closure: all four active non-survey flows are Lead record-after-save flows with no CloseDate/scheduled path, there are no active Apex triggers or Opportunity workflow rules, and the five scheduled jobs are platform maintenance. Current converted bookings default to 30 September, the end of the fiscal quarter, not a one-month expiry.

- Passing Close Date does not set Won/Lost or close a Stripe link. The actual overdue booking and new automated date tests verify this.
- Closed Won stays included in active NTE views, subject to other booking conditions.
- Closed Lost is excluded from active NTE views and blocks new payment requests; it does not itself refund a charge or deactivate an issued link.
- Stripe success/refund/dispute state does not automatically update Salesforce; preserve the agreed staff verification step. The inspected weekly finance report excludes Closed Lost and the confirmed-value formula has no refund subtraction. Use Stripe for refund reconciliation and retain the booking/refund reference; the Salesforce fields are not a refund ledger.

The owner's manual bank-transfer fallback is practical, but **a changed net booking total with an existing Stripe request also stops the automatic payment-confirmation email**, because `NTEExhibitorApprovalEmailService` compares the saved net amount with the current booking. Receipt can still be recorded. The exception needs an agreed manual confirmation or separately approved reconciliation support; this release does not silently remove the financial consistency check.

The issued NTE link's Price is fixed. The Dashboard's **More options → Edit** is disabled on the inspected active NTE link. Changing Salesforce will not change that emailed link. Use a new Price/link under an agreed replacement process or manual bank transfer, closing the superseded unpaid link. Stripe permits editing some link settings, so this is not a claim that every Stripe link setting is immutable. [Stripe Price rules](https://docs.stripe.com/products-prices/manage-prices).

For paid cancellations, a deliberate Dashboard refund and Closed Lost are reasonable separate actions. Retain the original payment and refund history; a refund can be pending or fail. Partial refunds do not necessarily mean cancellation. Deactivate unused cancelled links to prevent accidental late payment; no automatic repricing, deactivation, refund synchronization or new reminders were added.

## Remaining launch work

The client can grant live and sandbox access together before their colleague's holiday. Developer plus Sandbox Administrator supports live technical work and all account sandboxes. Administrator is appropriate if setup also includes team invitations and bank/payout settings, with access reviewed afterwards; ownership is unnecessary. Live Developer alone does not automatically open every private sandbox. [Sandbox access](https://docs.stripe.com/sandboxes/dashboard/manage-access), [role permissions](https://docs.stripe.com/get-started/account/teams/roles).

The code now supports live collection. The remaining account transition is explicit configuration: qualified client test/live credentials, expected account/org identifiers, selected mode, approved rate and payment settings, merchant activation, actual NTE user access, sender/deliverability, production form IDs/destinations, and the separately authorised production release. No test link/object becomes live. Radar settings are not copied automatically into a new sandbox or kept synchronized; compare live and test deliberately. [Sandbox settings](https://docs.stripe.com/sandboxes/dashboard/sandbox-settings).

Client-specific restricted-key permission checks, representative exhibitor/partner journeys, actual wallet/device checks and chosen receipts/notification categories remain. Existing P01/P03 decisions, real logo/final-pack destinations and production owner routing remain tracked in the project handover. The latest request does not approve unrelated open changes.

Stripe's current guidance prohibits testing live mode using real card details, including a nominal self-payment solely for testing. Use sandbox cards, read-only live setup checks and checkout inspection, then reconcile the first genuine authorised booking. [Stripe testing guidance](https://docs.stripe.com/testing).

## Retained evidence

- [Qualification JSON](NTE_STRIPE_LIVE_READINESS_QUALIFICATION_2026-09-11.json).
- [Final release/source/record verification](../tmp/nte-stripe-launch-readiness-20260911/final-verification.json).
- [Interrupted checkout](../tmp/nte-stripe-launch-readiness-20260911/checkout-interrupted.json) and [successful retry](../tmp/nte-stripe-launch-readiness-20260911/checkout-completed.json).
- [Provisional inbox evidence](../tmp/nte-stripe-launch-readiness-20260911/email-provisional-evidence.json) and [Stripe notification inbox evidence](../tmp/nte-stripe-launch-readiness-20260911/email-workflow-evidence.json).
- [Current access and launch handover](../NTE_STRIPE_CLIENT_HANDOVER_2026-09-11.md).

Do not rerun the seed/conversion/Test workflow/payment actions. The `seed-ledger.json`, `conversion-ledger.json` and retained Stripe IDs are completion evidence, not pending work.
