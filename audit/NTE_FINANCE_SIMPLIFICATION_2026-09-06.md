# NTE finance simplification and pricing retirement — 6 September 2026

## Approved scope and outcome

The owner requested four combined finance refiners, booking-first invoice/payment actions, removal of pricing by request across the implementation, logo progress in the Event breakdown, and removal of redundant panel controls and the Booking emails detail block. This was authorised MMUAT implementation and routine client-preview publication. Production deployment and Stripe integration remain separately held.

Implemented:

- **Quotes required → Invoice required → Payment required → Payment confirmed.** Booking and staff top-up finance facts remain independent. A record occurs once in each applicable queue. Its booking invoice appears before the top-up invoice, and its booking payment before the top-up payment. Payment required contains actionable invoiced charges; an uninvoiced top-up does not block recording an already-invoiced booking payment. Fully complimentary bookings have no payment to mark.
- Actions use **Booking invoice provided / Staff top-up invoice provided / Booking payment received / Staff top-up payment received**. The displayed status, amount and action agree, including the combined Finance view. A milestone preserves the selected record while it still belongs in the queue. Old top-up view keys normalize to the combined equivalents.
- Logo updates now have a delivery progress bar and open the outstanding-logo view. Removed the Booking emails detail summary, duplicate detail cross-event report and duplicated row/detail decision/finance buttons. The detail pane retains Email activity and Open full record; non-actionable views omit the empty Action column. The redundant finance global-list shortcut was removed because its older separate lists do not represent the combined queues. Wider finance reporting remains available.
- Removed the pricing-by-request calculator branches, manual agreed-price endpoint/editor, old flags/audit fields, report/formula/flow/permission references and active unpriced application choices. Removed extra-large exhibitor space and Troops’ Track Day Partner from paid application choices because no replacement fixed prices were supplied; informational event/EOI content remains. Current browser/Apex catalogue version is `NTE27-2026-09-06`.
- Fixed prices, eligible complimentary spaces, add-ons, primary-contact addressing, one-time top-ups, contact preservation, update replacement, email retries, repeatable reminders and final-pack readiness/history remain covered. Unknown or incomplete pricing stays review work and never silently becomes a free booking. Historical records were not mass-repriced.

## Deployment and validation

| Check | Evidence |
| --- | --- |
| Active MMUAT release | `0AfAd00000So0r7KAB` — 406/406 components, 169/169 tests |
| Four-field removal | `0AfAd00000So24vKAB` — 4/4 fields, no purge |
| Final full check-only validation after removal | `0AfAd00000So29lKAB` — 406/406 components, 169/169 tests |
| Local generation and form tests | `npm run validate` passed |
| Source consistency | All 406 manifest components reported by final validation; all 461 source/manifest snapshot files unchanged |
| UI logic | 18/18 Node VM cases on actual LWC source; refiners, priority, labels, amounts, status colours, hidden Action column, logo totals |
| Live panel reads | All four finance views and Logo updates passed separate read-only Apex checks |
| Public site | 17/17 served files match source byte-for-byte |

The final source is in `force-app/main/default`; the complete manifest is `manifest/production-package.xml`. Field retirement is recorded separately in `manifest/retire-manual-pricing.post-destructiveChanges.xml`. Machine-readable evidence, command results, snapshots and archives are under `tmp/nte-finance-20260906/`.

The live NTE2027 snapshot returned 11 quote-required, 36 invoice-required, 5 payment-required and 19 payment-confirmed records. Logo progress reconciled to 77 approved bookings: 69 outstanding, 8 provided. Some older dummy applications/bookings contain incomplete or retired prices and therefore remain review work; they were not silently migrated. Live checks performed no record DML, email invocation or form submission. An initial combined diagnostic exceeded the SOQL limit because it loaded several dashboards in one transaction; the successful checks use one transaction per view, matching normal UI behaviour.

**Visual limitation:** the Mac was locked and CUA could not access the browser. The owner was asked to unlock it. Source logic, Salesforce compilation, API results and hosted bytes are verified; no fresh visual browser verification is claimed for this release.

## Retired schema and historical dependencies

Retired active fields: `Lead.Price_On_Request__c`, `Opportunity.NTE_Price_On_Request__c`, `Opportunity.NTE_Price_Agreed_At__c`, `Opportunity.NTE_Price_Agreed_By__c`. A metadata ZIP and all nonempty flag/audit values were backed up first (31 Lead records and 37 Opportunity records). Amounts, invoice/payment facts, Contacts and booking records were preserved. Final describes confirm all four fields absent from the active schema and the unpriced choices absent from active picklists.

Salesforce blocked field removal because obsolete conversion-flow versions still held the old assignment. Versions 6–19 were fully archived and then removed; versions 1–5 and newly active version 20 (`301Ad000018za1VIAQ`) remain. Version 20 was verified active and free of the retired mappings before cleanup and remained active afterwards.

Version 10 was additionally blocked by 32 historical **Error** interviews from 23 August, all at the approval-email step. Their full 18 exposed fields, exact IDs, ownership, timestamps and errors were archived before deletion. Twenty-three recorded SOQL-limit errors and nine email-invocation-limit errors. Their labels did not prove they were synthetic, so they are recorded as historical failed histories, not claimed as dummy tests. No associated Lead/Opportunity IDs or FlowRecordRelation rows were exposed. The archive preserves available audit evidence, not restorable execution state. Only those exact Error histories were removed; none was resumed or replayed. No live/paused interviews were removed.

The initial interview query incorrectly supplied 18-character IDs to `FlowInterview.FlowVersionViewId`, which stores a 15-character string here. The corrected filter, explicit-ID checks and unfiltered query-all reconciled the same 32 records. Future cleanup must normalize the value and cross-check the inventory. Archive SHA-256: `762ba9c46a5aba5490adad796615301b8ea2a7cbdab9d6ca7a411b431b34beac`.

Earlier release attempts rolled back: one retained obsolete manifest members and encountered historical Flow references; two exposed stale test-fixture details (an inactive sponsorship choice, then missing current staff/power inputs); one metadata-directory deletion attempt lacked a ZIP-root package manifest. The manifest and fixtures were corrected, and the final explicitly packaged deletion succeeded. The successful checks above cover the final source and retired schema.

## Client preview and decisions

Published only the 15 root HTML pages and two shared pricing/configuration scripts to the current canonical website main branch. The prior head was `a355fb8c1b5985061fb74e57d3a88d56c72a055e`; the new commit is [5125e20](https://github.com/stevostar1234/nte27-web-to-lead-demo/commit/5125e2039ae954717c6273fcdc29dd21610004db). GitHub Pages reported built, and all 17 served files were verified. Shared asset query version is `20260906-1`. No Salesforce package files or private evidence were published to the website.

Current requirements and the supersession of separate top-up refiners are recorded in `NTE_DESIRED_WORKFLOW.md` and `NTE_CHANGE_PROPOSALS.md`. Current maintenance/provenance/release guidance was updated; dated audit evidence remains historical. No production release, Stripe integration, payment-confirmation email or genuine-recipient test send was performed.
