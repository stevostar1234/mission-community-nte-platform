# Manual finance and independent invoice choice — final audit

Internal release record, 13–14 September 2026 (Europe/London). Implementation, qualification, canonical preview publication and the exact older-fixture cleanup are complete. Production and the client's Stripe account remain separate releases.

## Resulting behaviour

Both paid application forms ask Payment Method first and independently ask whether an invoice is required. Stripe and bank transfer can request quotations, invoices, purchase orders/references, supplier agreements and additional billing details. The whole exhibitor finance section is hidden and disabled at a genuinely zero total; adding chargeable power or staff restores it. Partner finance remains visible. The new invoice preference survives Lead conversion and appears on the applicable Requirements checklist, record layouts, operational reports and internal application emails.

Conversion requires a new Opportunity and remains silent. It may reuse the Account and Contact. The manual Requirements action sends the selected Stripe, bank-transfer or complimentary message without ticking any procurement reminder. Payment required contains receipt actions; an accepted later staff top-up returns through Requirements and Payment required without clearing the original payment. Completed records use the manual Final joining instructions sent marker. The selected slate/navy and gold design, gold Open full record buttons and readable chart labels are retained.

## Critical review and corrections

Four independent reviews covered intake/pricing/preparation, finance/Stripe/dispatch, access/reports/deployment and obsolete metadata. Their findings are retained in [intake](NTE_FINAL_REVIEW_INTAKE_2026-09-13.md), [finance](NTE_FINAL_REVIEW_FINANCE_2026-09-13.md), [access/reporting](NTE_FINAL_REVIEW_ACCESS_REPORTS_2026-09-13.md) and [retirement](NTE_FINAL_REVIEW_RETIREMENT_2026-09-13.md).

- Saved staff top-ups now validate a positive whole quantity, positive saved unit price and quantity × unit price = net total before a Stripe request can be sent. Historical prices and request identity are preserved.
- Manual receipt shows the fresh gross amount being confirmed and warns when it differs from the latest delivered Stripe charge. Confirmation rechecks the amount while holding the booking lock; cancelling makes no change. Existing manual receipt routes remain available.
- Invoice preference is separate from the derived Payment Required flag. Old API fields containing “Invoice Required” remain because pricing and workflow use them; their visible labels describe Payment Required. Removing these functional fields would not be safe cosmetic cleanup.
- Reports 06 and 09 explicitly include only NTE application bookings with an event code and the selected open/won scope. Invoice preference is included in the relevant reports. Existing permission-group access is checked for the new fields.
- Obsolete VAT-era test expectations, stale workflow documentation and redundant private helpers were corrected. Added conversion tests cover non-NTE controls and a mixed accepted/rejected conversion batch.

## Obsolete items

The completed native retirement removed five fields: Opportunity's former Finance Invoice Due formula and Final Pack Recipient, plus the three routing fields for final-pack event code and exhibitor/partner pack URLs. It also removes five superseded invoice/top-up finance list views and the generic Staff Update Acknowledgement template. The two current audience-specific staff acknowledgements remain.

No entire Apex class or component bundle was proven unused. Dead private helpers were removed; public compatibility/retry entry points and uncertain shared fields remain. Backup copies and the exact deletion manifest are retained under `tmp/nte-final-audit-20260913/` and `manifest/retire-manual-finance.post-destructiveChanges.xml`.

Native dependency inspection covered classes/triggers, flows, permissions, layouts, report types, routing configuration and reports. Of 192 report entries, 183 were inspected; nine older CRM sample reports denied access and predate the retiring fields. This is an explicit access limit, not a claim that their contents were read. The permission-set-group aggregate is preserved and its recalculation is verified as Updated.

Completed older VAT/FIN dummy cleanup used an exact backed-up allowlist. The ten NTE-UI examples and the five new NTE-INVOICE cases remain active. Linked Accounts and Contacts are retained because duplicate-record and outgoing-email dependencies prevent a complete exclusivity proof. Paid Stripe history is retained; the seven verified active unpaid test links are now inactive. No real card charge or refund is part of this release.

## Remaining decisions and production dependencies

1. A changed base booking amount can still make its confirmation email fail the existing saved-Stripe-charge mismatch check, even after a reconciled bank transfer. The receipt warning exposes the difference but does not rewrite the original charge. Agree the confirmation/reconciliation rule before relying on that exception in production.
2. Supply the real logo upload destination and final NTE-hosted form URLs. The client preview remains the authorised sandbox destination.
3. Client Stripe sandbox/live access, credentials, merchant/Radar/receipt settings and a separately authorised live qualification remain necessary. This audit uses the owner's Stripe test account.
4. Formal quotation/invoice documents remain the client's finance process. The forms record requests; Payment Links do not create the requested formal invoice automatically.
5. An originally free booking has no initial invoice preference. If it later buys staff places, the team can record new document requests on the Opportunity. Asking those questions on the supplementary staff form would be an additional interface change.
6. Existing unselected decisions remain: feedback for rejected preparation/platform submissions, provisional retries after payment, and any new automatic cancellation/refund or top-up reduction behaviour. No change is inferred from the audit.

The review does not claim exhaustive simultaneous-worker testing, every possible mail-client/device combination or client production configuration. Historical successful submissions, sends and payments were not replayed. New regression tests and new isolated owner-addressed examples qualify the changed routes.

## Release evidence

- Full check-only `0AfAd00000SuVgvKAF`: **504 components, 351 local tests, zero errors or coverage warnings**. Actual sandbox release `0AfAd00000SuVllKAF` applied that unchanged package and its 11 retirements. The actual sandbox deployment uses NoTestRun after this exact full validation; no production quick-deploy or extra test claim is implied.
- All **568** frozen source/manifest hashes reconcile, and all **35** packaged native Apex bodies match source. The 297 original Lead, 35 Opportunity, nine request and 11 dispatch identities were preserved through deployment, along with every pre-existing Account/Contact/Task. Seven Opportunity edits and two added Tasks occurred at 22:28–22:31 UTC, before deployment began at 22:44:56 UTC; their exact changes are recorded separately and preserved. They are not attributed to the deployment.
- **Nine native reports**, exact source filters/columns/membership and **1,876 currency-cell checks** passed. The existing NTE Management Access group is Updated; Kate and Tony have effective access to all nine reviewed finance fields, including read/edit on the new invoice choices.
- Canonical preview commit **`692186823e7e668f17d38410d986bf4c26061199`**: all **21** intended hosted changes verified (19 byte-matching files and two removed pages returning 404).
- **Five fresh form submissions and five silent conversions** passed. Cases cover Stripe+invoice for exhibitor and partner, bank transfer without invoice for both, and a genuinely free exhibitor with finance values omitted. The Requirements cards match these choices. Nine paid UI examples received only a new invoice preference; their saved checks/history and historical Lead answers were preserved.
- One new manual Stripe action with **all five requirement boxes unticked** produced **£50 net + £10 VAT = £60**, one exact request and one received provisional email. It moved the booking to Payment required without auto-ticking anything. A native receipt dialog showed £60 including VAT; Cancel left its record timestamp, unpaid status and all checklist values unchanged. No card payment occurred.
- The **five actual internal application emails plus the one provisional email** pass HTML/plain-text, invoice-answer, currency-symbol, merge-output and multiline-detail checks.
- Local suites pass: **149 form-engine checks across 34,986 catalogue/boundary combinations**, **49 panel checks**, forms, metadata/reports, email presentation/assets, shared picklists and Stripe preflight. Selected design, blue checks, long/Unicode details, mobile card/chart overflow and smallest chart values are covered by the recorded UI13 and current native checks.

The first full check-only candidate had no component errors but five new test-fixture duplicate-contact failures. Its evidence is retained separately. A second check was cancelled to correct test email formatting before the passing final candidate; neither check changed native metadata or business records.

Evidence index: `tmp/nte-final-audit-20260913/release-qualified.json`, `reports-verified.json`, `access-verified.json`, `website-hosted-verification.json`, `invoice-cases-qualified.json`, `invoice-native-ui-qualified.json`, `ui-invoice-examples-qualified.json`, `form-browser-qa.json` and `ui13-native-responsive-qa.json`. Completed cleanup and final dashboard evidence are in `cleanup-qualified.json`, `final-fixtures-qualified.json` and `final-panel-qualified.json`.


## Final fixture cleanup — 14 September, Europe/London

At 23:20:47 UTC on 13 September (00:20:47 BST on 14 September), five ordinary delete statements recoverably removed exactly **38 old Leads, 25 Opportunities, 26 Tasks, 11 email-dispatch fixtures and nine payment-request fixtures: 109 direct records**. Their 25 Opportunity Contact Roles were independently observed deleted through the parent cascade. There were zero email invocations, queueable jobs or future calls in the delete transaction. No Account or Contact was deleted.

All seven exact unpaid obsolete Stripe test links were deactivated and individually verified. The two already-inactive paid links, five captured Checkout Sessions, two successful PaymentIntents and two paid Charges remain unchanged. No session was expired and no payment or refund was created. Provider history and exact Salesforce backups remain available.

Independent verification at 23:22:38 UTC confirms all 109 targets recoverably deleted, all 25 role cascades observed, and every protected core-record identity, deletion state and modification timestamp unchanged. The final active set is **15 bookings: ten UI examples and five independent-invoice examples**. Native data and the refreshed Master Panel both show **12 Requirements / three Payment required / zero Payment confirmed**, with no old VAT/FIN application Leads remaining active. The new £60 invoice-requested Stripe example remains unpaid in Payment required. The Requirements view is left open; its 12 cards, free-space card without a checklist, full-width slate headers and gold Open full record controls are visible.

The original cleanup attempt was rejected during compilation for a reserved Apex variable, before execution. Read-only recovery also identified an absent Lead.RecordTypeId field in this org; the corrected code requires native proof of its absence and null original values before omitting that nonexistent column. A native preview checked all targets and protected populations with zero DML before the single successful delete transaction. A local filename collision interrupted the follow-up evidence writer; a separate read-only verification completed the evidence without repeating deletion. Original failures, attempts, corrections and final reconciliation remain preserved. These were internal cleanup-script issues, not changes to deployed application logic.

No cleanup or successful application, conversion, send, receipt or payment should be replayed. The immutable preparation plan records what was proposed at capture time; `cleanup-plan/COMPLETE.md` and the final qualification files record the completed outcome.
