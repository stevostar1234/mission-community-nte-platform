# NTE stress audit — completed handoff

Updated 8 September 2026. **The audit and approved corrections are complete for the recorded scope.** All allocated live runs, final reports/preservation, actual sandbox releases, full-package validation and canonical preview publication have settled. Do not restart the completed test run or resend its emails. The report explicitly records finite coverage and untested dimensions; completion is not a claim that every possible permutation or production environment was tested.

## Read before follow-up work

1. [Desired workflow](NTE_DESIRED_WORKFLOW.md) and [approved implementation proposals](NTE_CHANGE_PROPOSALS.md).
2. [Final audit: 34 fixes, remaining decisions and 20 feature ideas](audit/NTE_STRESS_TEST_AND_IMPROVEMENTS_2026-09-07.md).
3. [Current package/release baseline](PRODUCTION_PACKAGE_SYNC.md).
4. The exact domain evidence below when continuing a particular booking or feature.

The audit uses **F01–F34** for implemented corrections, **P01–P17** for decisions/limitations and **U01–U20** for optional future features. These do not renumber the previously approved implementation proposals 1–12. No P/U item becomes authorised just because it appears in the audit.

**Latest follow-up, 8 September:** after requesting research into both confirmation routes, the owner selected **manual payment confirmation** and asked for client-equivalent sandbox setup and extensive pre-production testing. The client still needs to grant them Stripe access. [The manual setup and test plan](NTE_STRIPE_MANUAL_SETUP_AND_TEST_PLAN_2026-09-08.md) specifies responsibilities, configuration comparison and 60 planned scenarios; none has been executed. [The architecture plan](NTE_STRIPE_IMPLEMENTATION_PLAN_2026-09-08.md) retains automatic/assisted alternatives for reference. Proposal 11 now records the manual selection, with account access, financial configuration and existing policy decisions awaited. A read-only native query verified MMUAT is Enterprise Edition. No Stripe connection, charge, webhook setup, email send, sandbox change or publication occurred. This follow-up does not reopen the completed stress audit.

**Later 8 September — Payment Links, dependency review and GitHub checkpoint:** the owner selected **Payment Links only**, excluding Stripe Invoicing, and will supply the remaining configuration. They authorised reviewing/integrating missing package dependencies and uploading all current project work to a new repository. The [broader review](audit/NTE_PACKAGE_DEPENDENCY_REVIEW_2026-09-08.md) confirms all 46 inherited fields are included and no further custom fields are missing in the scanned scope. It adds the previously omitted OpportunityStage component and a tool to preserve the target's shared picklists. Actual MMUAT deployment `0AfAd00000SqBTtKAN` succeeded; full check-only `0AfAd00000SqBX7KAN` passed **424 components and 281 tests**, with 486 matching hashes. No record journey, email send or old audit was replayed. [Production and Stripe account-transition plan](NTE_PRODUCTION_DEPLOYMENT_PLAN_2026-09-08.md); production access/deployment remains unexecuted. The new repository publication is recorded separately when verified.

**Preserved audit decisions:** do not account for names beginning with `=`. P10 is closed as declined; leave the names and report-export setting unchanged, with no further probes planned. Historical CSV evidence remains internal. **P03 remains unanswered:** whether every NTE application conversion must create a new booking while permitting reuse of existing Accounts and Contacts. No new conversion guard has been implemented. The old native existing-Opportunity and no-Opportunity options remain available; the Stripe plan identifies this as a decision to resolve before live collection.

## Release baseline — verified, not pending

- Actual full MMUAT deployment `0AfAd00000SpIFhKAN`: 423/423 components, 278/278 tests passed.
- Subsequent actual F34 v2 email deployment `0AfAd00000SpkOrKAJ`: 15/15 components and 24/24 tests passed at 10:04:43 UTC, including three new actual stored-template tests. The earlier v1 attempt `0AfAd00000SpiOfKAJ` failed one parity assertion and rolled back. Its evidence is retained; v2 fixes the native plain-text newline issue with the assertions preserved.
- **Final full check-only `0AfAd00000Spkn3KAB`: 423/423 components, 281/281 RunLocalTests, zero errors**, completed 10:14:56 UTC. All 485 source/manifest hashes match; no missing/extra component members or source paths. Aggregate SHA256 `c128cbb66de6d6cc52625cadfc606a58e11f8fdb4d8fdf0d38037cad5e9adb77`. [Exact summary](tmp/nte-stress-20260907/metadata-f34-v2-qualification-20260908/summary.json).
- Canonical preview `stevostar1234/nte27-web-to-lead-demo` main commit **`8d1f7c19f4f18f73905147669e7a9147ed62d14c`**. All 59 intended hosted files byte-match the current root/website source, verified 10:13:01 UTC. The final commit changes only 14 email-source HTML files; all 21 normal examples are unchanged. [Publication evidence](tmp/nte-stress-20260907/f34-website-release.json).
- `assets/forms.js` remains revision `20260908-1`, SHA256 `b3cd702e54e0353ab5c61bfc91fbac2fdb91d1da94a738b3f16355e8960ecf03`.
- The corrected Mission Motorsport logo is an opaque RGB PNG, 1500 × 767, SHA256 `91395bf1b56bee68fa758b9dc37dcebadc93b0a9c2ea141ccdc9164b6ede2d39`, URL revision `20260907-png`. One actual corrected volunteer receipt was verified. Do not re-create or redraw the logo.
- All temporary final-pack configuration is restored exactly: both actual pack URLs blank, global Queued count zero, routing metadata SHA256 `731087d1b28c53f981615437a6ec3a1a50c343da11e2ca05c0b326ab6f615687`. [Final pack/restoration result](tmp/nte-stress-20260907/dispatch-final-pack-plan/final-mechanism-result.json).
- No production deployment, actual Stripe charge, client logo upload or real client final-pack contents were tested or released.

## Completed live scope — never replay from an old registry status

- Initial harness: 74 HTTP POST attempts → 73 exactly correlated Leads and one proven platform rejection before Lead creation. No unknown outcome.
- Preparation harness: 70 normal + 28 edge/restoration POSTs = **98/98 reconciled**, 93 Applied and five expected Rejected, with all 98 preservation guards passed and no repeated POST. One read timeout was resolved by exact record correlation without resubmission.
- All 34 valid bulk applications converted and reached Completed after the normal phase, and again after edge testing. The 33 paid base bookings total £212,397. Three paid top-ups total £5,100; combined bulk recorded finance is £217,497 excluding VAT. Each paid base booking has one confirmation; top-up payment created no additional booking confirmation.
- All 16 allocated bulk EOI invitations are Sent and progressed exactly once; three allocated application/interest rejects completed. Two duplicate observations and two pricing-review holds remain unconverted intentionally.
- Three reserved-recipient final packs are Sent. Repeated requests queued zero extra messages. EX005's late completion received only its own pack. EX002's subsequent first top-up reopened finance, then returned to Completed without changing original booking payment or any pack history.
- Four separate representative preparation journeys reached Completed: Harbour, Cedarhaven, Willowbridge and Fenmere. Actual inbox verification covers 24 root application-onward messages plus three Fenmere lifecycle messages. Invitation, volunteer and guest messages are separately evidenced. All messages are retained; no resends are required for the later formatting correction.
- The original 140-case catalogue records **110 live observations, 14 browser-scenario-only, ten local-source-only and six without an exact execution mapping**. Seventy-four additional indexed form cases are outside that denominator. Two exact live gaps (first one-person top-up before base payment; ambiguous duplicate reference) have related isolated native tests; four representative preparation IDs remain unbound. Do not relabel related cases as exact coverage.

Final evidence:

- [Immutable catalogue manifest](tmp/nte-stress-20260907/catalog/coverage/final-01/FINAL_MANIFEST.json) and [coverage qualifications](tmp/nte-stress-20260907/catalog/coverage/final-01/coverage-qualifications.md).
- [All 98 preparation outcomes](tmp/nte-stress-20260907/bulk-harness/preparation/all98-completed/summary.json).
- [Final bulk booking/finance results](tmp/nte-stress-20260907/panel-live-driver/FINAL_RESULTS.json) and [exact final fixture fragment](tmp/nte-stress-20260907/panel-live-driver/FINAL_REGISTRY_FRAGMENT.json).
- [Representative journal](audit/NTE_REPRESENTATIVE_JOURNEY_JOURNAL_2026-09-08.md), [root final readback](tmp/nte-stress-20260907/root-representatives-final.json) and [Fenmere final lifecycle](tmp/nte-stress-20260907/conversion-live-001/lifecycle-02/lifecycle-result.json).
- [Actual inbox ledger](tmp/nte-stress-20260907/email-quality/inbox-journeys/final-phase-ledger.json).

`tmp/nte-stress-20260907/catalog/fixture_registry.json` preserves original allocations and older snapshots, plus final evidence pointers. Its old per-fixture “planned” statuses are historical, not instructions to create or replay records. The immutable final catalogue binds its own input snapshots. Do not blanket-merge older private fragments over newer actual state.

## Final UI, reporting and preservation

- Selected native desktop/phone Master/Home controls passed, including recipient selection preservation, pinned Send, focus wrap/Escape, pagination, finance precedence, exact Primary Contact and event selection. Actual NTE2027 Master: 38/38 Complete, zero updates/invoice/payment outstanding, 35 packs unsent and three Sent. Home: £249,347 approved/invoiced/paid, £0 still to collect, four pending applications totalling £2,800. This global population differs from the 34-booking bulk group.
- All nine native reports reconcile with exact filters, rows, Primary Contacts and amounts. Row counts: 8/18/22/40/7/40/27/40/38. Across 12,314 detail cells, 12,301 match in full and 13 match Salesforce's documented long-text display limit. Zero unexplained mismatches.
- Native Details Only CSV / UTF-8 for Report 08 passes all 2,080 source-cell comparisons across 40 rows/52 columns, preserving every name in the 99/101-person rosters. Use CSV for a full roster: native report display and certain Excel formats truncate long text. This export-format guidance is separate from the declined P10 prefix proposal.
- All 2,057 retained pre-run records have unchanged audit timestamps: 664 Accounts, 757 Contacts, 537 Leads and 99 Opportunities. All 103 exact protected-walkthrough comparisons pass; zero new dispatches or Tasks target that booking/contact. These statements concern retained queryAll records and available snapshots, not records outside retention.

[Native UI journal](tmp/nte-stress-20260907/root-ui-resumed-20260908.json), [final report/preservation result](tmp/nte-stress-20260907/metadata-final-reconciliation-20260908/RESULT.md), [full CSV reconciliation](tmp/nte-stress-20260907/metadata-final-reconciliation-20260908/native-csv-reconciliation.json).

## Protected records and fixed rules

Preserve the earlier completed Anthrion walkthrough: Opportunity `006Ad00000UcnmPIAR`, Account `001Ad0000192WHhIAM`, Primary Contact `003Ad000019lSnxIAE`, converted Lead `00QAd00000UQsWXMA1`, EOI `00QAd00000UQg6gMAD`, reference `NTE-1788793164136-7MGGTZFU`. Its £800 base and one £50 top-up remain paid. Retain rejected second top-up `00QAd00000UQtfVMAT` and logo attestation `00QAd00000UQtE5MAL`. All genuine legacy records and inbox messages remain protected.

- All booking emails and panel identity use the exact Opportunity Primary Contact; event-day and billing contacts are separate and preserved. No silent fallback or added CC/BCC.
- One accepted positive top-up locks quantity, while same-quantity name corrections remain allowed. Preserve accepted price and finance history. No self-service reductions or refunds were approved.
- Valid heavy updates replace all heavy details, clearing omitted optional information without overwriting contacts or unrelated booking facts.
- Cancelled bookings continue accepting preparation updates. Recording booking payment sends its confirmation immediately even if provisional dispatch failed. A later provisional retry after payment remains undecided (P01).
- Application receipt is under review; paid conversion is provisional; complimentary conversion is confirmed. Four finance refiners retain booking-first precedence. Pricing-on-request remains retired.
- Application form URLs are stable per type across years. Final-pack URLs remain per-event. Real client destinations, Stripe and financial-document decisions are still dependencies.
- P02/P17 feedback, P03 conversion options, P16 default event and other open report proposals require the owner's decisions. Open access remains the client's accepted model.

## Environment and safe continuation

- Workspace: `/Users/stevo/Downloads/mission community updated datamodel`; sandbox alias `mission-mmuat`, org `00DAd00000A95VlMAJ`.
- CLI: `SF_DISABLE_LOG_FILE=true SF_DISABLE_TELEMETRY=true node /Users/stevo/.hermes/node/lib/node_modules/@salesforce/cli/bin/run.js`. Network/keychain may require scoped escalation; never print credentials.
- User `005Ad00000TyedVIAR` is Steven. Native Default Lead Creator/Owner and NTE routing are aligned to Steven; Notify Default Lead Owner is false. Only obsolete volunteer native auto-response entry `01RAd000003M01F` is disabled with formula FALSE; four unrelated entries are unchanged. Native settings require separate verification for production.
- Many existing dirty/untracked files predate this audit. Preserve them; do not reset, stage all or push this Salesforce workspace to the forms repository. The isolated canonical website checkout is `tmp/nte-stress-20260907/website`, main, clean after publication.
- No live mutation/sending runner or temporary routing configuration remains. Final Salesforce check-only is complete. Browser inventory/bindings may change after restart; discover actual tabs instead of assuming old IDs. The last user-visible surface is the native Report 08 export; no viewport override remains.
- No reset credit was redeemed. The owner's continuity request is satisfied by this handoff and immutable domain results, not an automation. New work resumes from the owner's next chosen scope.

The earlier detailed pause/resume history is preserved at [historical checkpoint](tmp/nte-stress-20260907/root-resume-before-final-release.md). Its pending instructions are superseded by this completed handoff and final actual evidence.
