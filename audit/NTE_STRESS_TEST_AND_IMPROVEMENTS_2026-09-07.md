# NTE stress test, corrections and future improvements — 7 September 2026

**Allocated sandbox audit complete, finalized 8 September 2026.** All 34 intended valid bulk applications have converted and passed the actual Completed calculation after 70 normal preparation submissions and again after the 28 edge/restoration submissions. Their 33 paid bookings have one booking-payment confirmation each, while the complimentary booking needs no invented payment. Sixteen bulk invitations are Sent and their interests are progressed. The initial two final packs and one later completer's pack are Sent; repeating those requests queued no additional messages, and the temporary configuration is restored. The four separately tracked representative preparation journeys are also Completed, with 27 application-onward messages verified in the controlled inbox.

**F01–F34 are implemented in the sandbox and relevant public previews are published.** The initial actual package deployment passed 423 components/278 tests; F34's actual narrow deployment then passed 15 components/24 class tests. The final combined **check-only qualification passed 423/423 components and 281/281 tests**, with all 485 source/manifest hashes unchanged and all 48 reviewed F34 hashes exact. Canonical preview `8d1f7c19f4f18f73905147669e7a9147ed62d14c` has all 59 intended files byte-verified. All nine final reports reconcile, native CSV retains the full large rosters, and all 2,057 retained pre-run records have unchanged audit timestamps. There is no execution or release work left for this allocated run. The separately numbered decisions and unproved dimensions remain explicit; Salesforce Sent/acceptance statuses for reserved example addresses are not inbox-delivery claims.

The review found material weaknesses in price calculation at conversion, preservation of paid money on Home, update-receipt identity, intake retries, batch handling and stale recipient/action handling. It also found recoverable form-validation failures, a real tab-crossing-midnight failure and presentation problems with long or unusual but valid data. The corrected package has passed its coordinated Salesforce deployment tests; source checks, protected browser reproductions and the separately identified live cases provide complementary evidence. They do not prove every live journey or concurrency condition.

F01–F34 identify implemented corrections. P01–P17 preserve decisions, limitations and proposed follow-up, including the current-edition default and rejected-request feedback questions exposed by live testing; P10 is explicitly declined and P15 records completed qualification with remaining coverage limits. U01–U20 remain exactly twenty optional future features. These IDs do not renumber the existing approved proposals 1–12 in `NTE_CHANGE_PROPOSALS.md`.

### Decisions to review

These remain separate from the implemented fixes. A policy choice and any implementation approval must be recorded before the corresponding change proceeds.

| ID | Status | Decision and practical effect |
| --- | --- | --- |
| P03 | Undecided | Require every approved application to create its own new booking while allowing Account/Contact reuse. Native conversion currently permits no booking or an existing booking; the latter can overwrite its application fields while retaining old payment flags. A strict guard needs the separately described design/rollback qualification. |
| P02 / P17 | Undecided | Decide how applicants learn that an update or intake was rejected, and who may receive the explanation. A generic thank-you redirect currently cannot prove acceptance; booking-matched feedback and unmatched submissions need distinct recipient/content rules. |
| P16 | Undecided | Choose the current working edition for Home/Master defaults. Both currently choose the highest available year, so future fixtures can open NTE2029 while the team is working on NTE2027. |
| P13 | Client dependencies | Supply final application/pack/logo destinations and settle production finance/Stripe details. The demonstrated sandbox declarations, manual payment milestones and pack mechanism do not supply those external assets or merchant decisions. |
| P10 | Declined; no action | The owner explicitly declined special handling for names starting with `=`. Keep the existing input/export settings. The separate full-roster CSV export route is verified. |

The remaining P entries retain narrower limitations and recovery choices. U01–U20 are optional ideas only; none is implemented by this report.

## Decisions and scope held throughout the run

- The verified sandbox is `mission-mmuat`, org `00DAd00000A95VlMAJ`, `IsSandbox=true`. No production release is implied.
- **The user has decided that booking-payment confirmation should send immediately when payment is recorded, even if the provisional email failed.** Payment and its confirmation must not wait for a repaired provisional send. Normal successful conversion still sends the provisional email first. What to do with a later provisional retry after confirmation remains P01.
- **The user has decided that preparation updates remain accepted on Closed Lost/cancelled bookings**, including an otherwise valid first top-up after a pack was sent. Preserve the booking stage, original payment and pack history. This is not an open policy question. Active finance actions and operational queues may still exclude closed losses; that is a separate scope from preparation submissions.
- The one-time top-up, exact booking-reference matching, Primary Contact recipient rule, contact preservation and current fixed-price catalogue remain intact. No contact fallback, repeated purchase, automatic refund, urgency classification, capacity system or historical repricing was introduced.
- Live-test routing was restricted to root-allocated synthetic records and the owner's controlled `steven.skyba@anthrion.com` inbox or verified alias `steven.skyba@euroforce.com`. Bulk fixtures use reserved example addresses. The root saved and verified Steven Skyba as Default Lead Owner as well as the already verified Default Lead Creator; the NTE override remains Steven's MMUAT username. Genuine legacy recipients, genuine Accounts/Contacts and the retained Anthrion walkthrough are protected. The controlled pre-fix volunteer case in F14 produced two actual applicant receipts and an internal notice to Steven only; its verified post-fix case produced one applicant receipt. Earlier domain reviews used isolated/read-only work; final live-run totals and preservation reconciliation are recorded below. See [routing safety](../tmp/nte-stress-20260907/routing-safety.json).

## What has actually been checked

The following measures describe different kinds of evidence and **must not be added together as a live-test total**.

| Evidence | Verified result | What it does and does not establish |
| --- | --- | --- |
| Finite case catalogue | 140 original form cases across ten submission forms; final coverage records **110 with live-submission observations, 14 browser-scenario-only, ten local-source-only and six without an exact execution mapping**. Separately planned: four staff-hub navigation checks, 14 linked journeys and 2,414 isolated matrix cases/checks. | A live observation can be an expected rejection and is not a blanket scenario pass. Of the six unmapped cases, two are explicit exact live gaps and four lack a bound representative fixture mapping. Seventy-four additional indexed form cases are separate from the 140: 68 normal, two restorations, three Fenmere cases and the native CSV probe. Three further root action observations remain unbound, so these are not an exhaustive global POST count. |
| Form-engine source harness | **123 checks pass, zero fail, with 34,986 catalogue/boundary combinations.** The original 99-check suite gave 49 passes/50 failures against the run baseline. The added 24 midnight checks all fail against the frozen pre-midnight-fix script and all pass after correction. | Executes maintained HTML/JavaScript with inert transport. Midnight coverage spans ten forms in BST/GMT plus preservation and focus cases. It proves selected payload/recovery/date behaviour, not Salesforce acceptance; baseline failure counts are not independent defect counts. |
| Pricing utility/catalogue matrix | 879,417 exhibitor calculations, 16,383 non-empty sponsor subsets and 22 invalid price cases pass. All 27 spaces, 14 packages and 19 categories reconcile with the server catalogue. | Bounded arithmetic/source agreement, not 895,000 applications or native conversion runs. Limits and source hashes are saved. |
| Public-form browser checks | Both form reviewers cover all ten forms and the staff chooser. The exhibitor reviewer exercised 54 explicit space/staff/power combinations; partner testing toggled all 14 packages. Paired before/after recovery and reference cases were reproduced. | Positive corrected-source submissions ran only on protected loopback previews with no Salesforce endpoint, blocked form action and rejected POST. They are local review successes, not live receipts. |
| Responsive forms | Three exhibitor routes and eight other routes measured 390 × 844 inner documents, with no page-level horizontal overflow in the tested states. | Real CSS-width checks in iframes, not a physical phone or virtual-keyboard test. A viewport tool that returned success without changing width was discarded as evidence. |
| Panel JavaScript suite | 32/32 pass; baseline 9 pass/23 fail. | Actual component JavaScript with mocked Salesforce endpoints verifies state and request handling. It does not prove Lightning focus, layout or Apex operation in MMUAT. |
| Email source/render checks | 311 assertions across 21 sources and 84 fixtures. Long/Unicode fixtures fit 375 and 768 px; three custom sender categories also fit after correction. | Source-derived browser rendering and text/merge contracts. Native merge escaping/comment handling and real mail-client rendering remain separate release checks. |
| Input-integrity probes | Six local checks completed. | Some checks reproduce weaknesses; “completed” does not mean six product protections passed. No hostile live submission or complete external exploit was demonstrated. |
| Read-only native reports | **All nine final reports reconcile** with stable source filters, membership, columns, Primary Contacts and monetary aggregates: row counts 8/18/22/40/7/40/27/40/38. Across 12,314 detail cells, 12,301 match in full and 13 match the native long-text prefix limitation; zero unexplained differences. All 42 pricing/finance helper rows reconcile. | These are native API report results, not nine browser screenshots. The 13 truncated display cells were separately qualified against full native CSV export. Cross-event reports total £252,147; their population includes historical, protected and root bookings beyond the £217,497 bulk group. Same row counts can have different finance/readiness membership. |
| Native spreadsheet exports | Three formatted XLSX exports preserve `=1+1`, `+1+1`, `-1+1` and `@SUM(1,1)` as explicit text, with zero formula nodes or external links. The **final native report 08 CSV passes all 2,080 source-cell comparisons** across 40 rows/52 headers, including every 99/101-name roster. A separate actual form/CSV probe exports synthetic Company `=1+1` without a protective prefix. | No spreadsheet was opened and no formula executed. Full-roster CSV export passed, with only line-ending normalization and native minute-precision date comparison. The owner has explicitly declined further CSV-prefix work under P10. Four differences in the earlier 39-row export were later staff changes, not corruption. The extra formula-name Lead is outside the original 140 cases. |
| Actual Lightning panel checks | Bulk selection, clear, deselection/refresh preservation, the fixed send footer, pagination/refiner reset, Primary versus event-day display, Home event/refresh, report opening and the native EX010 finance sequence passed. Final native NTE2027 Master shows **38/38 Complete**, zero updates/invoice/payment outstanding and 35 packs not sent/three sent. Home shows **£249,347** approved/invoiced/paid, 38 approved bookings, 36 paid bookings and zero still to collect; four pending applications total £2,800. | These global NTE2027 figures include the protected and root journeys, so they are distinct from the 34-booking, two-event bulk group and its £217,497 total. The actual final desktop screenshot was inspected at 1082 × 911. Selected phone layouts were checked separately; physical-device, full assistive-technology, all-control and concurrent-transaction matrices are not claimed. |
| Prior deployed Apex baseline | Focused run `707Ad00001QZ1ryIAD`: 31 reported passes, comprising 28 named behavioural cases plus three setup fixtures. The pre-run full-package baseline was 413 components/181 tests at `0AfAd00000SotIyKAJ`. | These predate this run's new corrections. They must not be cited as validation of the changed package. |
| Domain Apex inventory at source handoff | Pricing: 14 methods; conversion/payment/approval: 47 behavioural cases including 19 added; dispatch: initially 29 methods including 13 added, followed by three aggregate-size regressions; intake: 14 NTE + 15 volunteer; supplementary: 11 new; panel-related classes: 63 methods including 17 new; metadata/report fixtures added. | Inventory counts overlap existing suites and use different setup conventions. The initial 278-test deployment and final 281-test qualification below are the authoritative aggregate results for their respective source versions. |
| Earlier check-only attempts | `0AfAd00000SpI1BKAV`: 269 passed, six new null-assertion fixture failures. `0AfAd00000SpICTKA3`: 276 passed, two aggregate-size fixture failures; both report zero component errors. | Neither earlier validation succeeded. Null assertion messages and the heap-sized fixtures were corrected without weakening the guard. All 278 tests then passed in the actual deployment. |
| Actual package deployment | Final result for `0AfAd00000SpIFhKAN`, completed `2026-09-07T23:05:33Z`: **Succeeded, 423/423 components, 278/278 tests, zero errors**, `checkOnly=false`. | Confirms the initial MMUAT package deployment and isolated Apex tests. Final counters replace the earlier 427-component progress display. F34's later actual deployment and final qualification are separately recorded; live workflow outcomes are independently reconciled. |
| Frozen-source check-only qualification | `0AfAd00000SpYyoKAF`, completed `2026-09-08T09:11:39Z`: **Succeeded, 423/423 components, 278/278 RunLocalTests, zero errors**, `checkOnly=true`. All 485 original/before/after source and manifest hashes match at 09:11:52 UTC. | Qualifies the pre-F34 bytes only; it is not another actual deployment. F34 was deliberately held until this capture, then its changed bytes were qualified separately below. |
| Final F34 deployment and combined qualification | Actual narrow `0AfAd00000SpkOrKAJ` passed **15/15 components and 24/24 class tests** at 10:04:43 UTC. Final check-only `0AfAd00000Spkn3KAB` passed **423/423 components and 281/281 RunLocalTests**, zero errors, at 10:14:56 UTC. All 485 before/after/inventory hashes and 48 reviewed F34 hashes match at 10:16:55 UTC. | The final check-only validates the combined source after the actual narrow release; it is not a second full-package actual deployment or a production release. Full native stored-template parity passes without weakened assertions. |
| Controlled volunteer receipt and routing | Before correction, Lead `00QAd00000URLgbMAH` produced two receipts and native Task `00TAd00000PO7pxMAD`. After entry five was set to FALSE, James Walsh / `VOL-002` / Lead `00QAd00000URPXJMA5` produced exactly one applicant receipt `1a07e20f3ae4af95`; the native-Task query returns zero records. | Confirms this real post-fix volunteer route. The receipt uses the Apex sender and the allocated controlled inbox; it is not a claim about every later live submission. |
| Logo and website publication | True opaque RGB PNG verified at 1500 × 767 with zero changed visible pixels on the white header. The actual James receipt uses its versioned URL; the exact hosted asset is a clear, opaque PNG. Current website **`8d1f7c19f4f18f73905147669e7a9147ed62d14c`**: 59/59 intended files match at 10:13:01 UTC, including F34's 14 maintained email sources; all 21 normal examples are unchanged. Form asset remains `20260908-1`. | Confirms actual received-message content and its image asset, plus root/clone/host byte agreement. The asset was inspected directly; a broad Gmail/Outlook UI matrix was not performed. |

Evidence: [catalogue](../tmp/nte-stress-20260907/catalog/README.md), [current 123-check form results](../tmp/nte-stress-20260907/form-engine-after-midnight-fix.json), [pricing matrix](../tmp/nte-stress-20260907/pricing-matrix-results.json), [panel results](../tmp/nte-stress-20260907/panel-ui-current.tap), [email contracts](../tmp/nte-stress-20260907/email-quality/contract-results.json), [report reconciliation](../tmp/nte-stress-20260907/metadata-report-execution-before-summary.json), [second check-only](../tmp/nte-stress-20260907/validate-second-report.json), [third check-only](../tmp/nte-stress-20260907/validate-third-report.json), [successful actual deployment](../tmp/nte-stress-20260907/deploy-package-report.json), [current hosted verification](../tmp/nte-stress-20260907/hosted-verification.json), [post-fix receipt verification](../tmp/nte-stress-20260907/email-quality/logo-fix/postfix-mail-verification.json), [zero post-fix native Tasks](../tmp/nte-stress-20260907/volunteer-postfix-native-tasks.json).

The initial 59-file publication at `64c3679b4d03c62093a8a6455cb4528cef05c1ba` remains recorded in [first-release verification](../tmp/nte-stress-20260907/hosted-first-release-verification.json). The subsequent `491cadd974b15d1b9da5542217e8d0cdc19834e1` publication added F33 and the `20260908-1` asset version without another Salesforce component deployment. The current **`8d1f7c19f4f18f73905147669e7a9147ed62d14c`** publication changes only 14 maintained email-source HTML files for F34; all 59 intended served files match, with all 21 ordinary examples unchanged. [Final F34 publication verification](../tmp/nte-stress-20260907/f34-website-release.json).

### Controlled live results

These completed steps use different evidence scopes. The HTTP allocation, representative browser journeys and later booking steps remain separately identified so that the same record is not counted again as a new submission.

The frozen harness ledger reconciles **172 actual business HTTP attempts**: 74 initial intake requests plus 98 preparation requests, yielding 171 unique correlated Leads and one proven rejection before Lead creation, with zero unexplained outcomes or POST retries. This finite harness total excludes the separately documented representative browser submissions and is not the number of complete journeys or delivered emails. Its 12 coverage inputs are snapshotted against the [final manifest](../tmp/nte-stress-20260907/catalog/coverage/final-01/FINAL_MANIFEST.json); the [registry reconciliation](../tmp/nte-stress-20260907/catalog/coverage/final-01/registry-reconciliation.json) and [coverage qualifications](../tmp/nte-stress-20260907/catalog/coverage/final-01/coverage-qualifications.md) preserve exact fixture variants, accepted outcomes and limits.

| Completed step | Observed result and limits |
| --- | --- |
| Allocated direct HTTP intake | **74 POST attempts: 73 correlated Leads and one proven rejection before Lead creation; no unexplained outcomes.** The allocation contains 67 valid-form payloads and seven deliberately raw payloads. The Lead outcomes are 68 ordinary creations, two pricing-review holds and three rejected updates. The earlier separate TLS failure was classified as transport not sent and is excluded from these 74 HTTP submissions. This is not execution of all 140 catalogue cases. |
| Price and reference rejection checks | `APP-EX-024` / Ashcombe Facilities and `APP-EX-025` / Kingswell Research were retained with `Pricing_Status__c = Review required`, zero listed total and no conversion in the intake snapshot: they remain Check pricing work, not complimentary approvals. `STAFF-EX-012`, `HEAVY-010` and `LOGO-004` retained their unmatched submissions as failed updates without a booking association. |
| Intake email audit | The saved Lead fields record **64 NTE applicant and 64 NTE internal Salesforce acceptances**, plus **six volunteer applicant and six volunteer internal acceptances**. These are unique recorded audit acceptances, not inbox delivery or proof of an exact emitted-message count. |
| Actual EOI invitation receipts | The controlled inbox contains the exhibitor invitation `1a07e274531f40f9` and partner/sponsor invitation `1a07e27452df0f8f`. Actual MIME checks verify the allocated recipient, no CC/BCC headers, matching HTML/plain-text personalisation and one correct application link each. This is receipt-content evidence; a direct Gmail UI screenshot/rendering matrix was not performed. |
| Three root representative bookings | The £800 exhibitor, £30,000 partner and £0 complimentary applications each have exact converted Account/Contact/Opportunity IDs and now pass the deployed Completed calculation. The final live assertion succeeds with zero DML and zero sends. Harbour retains its separate paid £50 top-up after a name correction and rejection of a repeated increase. Cedarhaven retains finance/event-contact facts while replacing vehicle details and clearing removed values. Willowbridge completes without invented payment. Final-pack fields are still empty; Completed is a preparation calculation, not a Closed Won stage or a sent pack. |
| Fenmere exact-identity lifecycle | One actual browser application, one API native LeadConvert into the explicit seeded Account/Leonie Contact, two real controller finance actions and two direct HTTP preparation POSTs produced an active £950 booking that passes Completed. The £800 space + £100 power + £50 original staff itemisation remains intact; three staff names add no further charge. Captured Account/Contact core fields and the competing £2,000 NTE2026 booking remain preserved. The decoy was updated later in the conversion transaction but has a tied timestamp, so a strictly newer LastModifiedDate is not claimed. |
| Actual representative inbox reconciliation | Original MIME reconciles **24 messages for the three root application journeys: eight Harbour, ten Cedarhaven and six Willowbridge; plus three Fenmere post-conversion messages**. This includes the three root internal application notices. Two internal notices without a booking reference were matched by exact source Lead headers; the 22-message booking-reference search alone was insufficient. The two earlier EOI invitations, guest/volunteer mail and obsolete-package failure notice are excluded from this 24 + 3 scope. |
| Bulk conversion and base finance | **34/34 intended valid bulk applications converted, with £212,397 booking value excluding VAT.** All 33 chargeable base bookings are paid and have exactly one BOOKING_CONFIRMED Sent dispatch; EX004 remains genuinely complimentary. These are recorded sandbox milestones and email-service acceptances, not money collected or delivered-mail proof. |
| Existing identity across event years | EX017's API conversion rolled back on duplicate detection; actual native UI conversion succeeded without changing or bypassing a duplicate rule. EX019 then reused the exact captured Account/Primary Contact for a separate NTE2028 booking, preserving the NTE2027 booking. Both have their own approval and booking-payment outcomes. The API/UI difference is not classified as a package defect. |
| Decided and deliberately held cases | The allocated EX022 application and EOI-EX-008/EOI-PS-010 interests were rejected through the controller. Duplicate observations EX020/PS020 stay unconverted pending policy. Pricing-review EX024/025 stay held; the obsolete-package PS018 was rejected before Lead creation. Keeping these cases out of Completed is expected. |
| Bulk EOI invitation sends | **16 reviewed invitations are Sent and all 16 interests progressed**, between 09:09:47 and 09:10:12 UTC; zero retries. The eight exhibitor and eight partner/sponsor requests use the appropriate enduring application URL, including 2026/2028/2029 cases. Each actual request and outcome is bound to its saved review hashes. These recipients use reserved example addresses; the two earlier controlled-inbox invitations remain a separate evidence scope. |
| Failed provisional followed by payment | On PS011, removing its Primary Contact Role before conversion made the provisional email Failed and its draft ineligible. Restoring the exact role, then recording invoice/payment, produced one booking-payment confirmation Sent while the provisional status remained Failed. This directly verifies the owner's decision to send payment confirmation immediately; no provisional retry was performed. |
| Cancelled-booking preparation | EX009's actual heavy-vehicle update applied while Closed Lost and before booking payment. Its original Qualification stage was then restored for active finance, followed by invoice/payment and one confirmation. This demonstrates accepted preparation on a cancelled booking without silently treating the stage as a payment. |
| Native booking-before-top-up finance | EX010 accepted a first top-up of **99 places, £4,950**, while its **£600 booking** was unpaid: 101 total staff. The actual Master Panel exposed Booking invoice → Staff top-up invoice, then Booking payment → Staff top-up payment. All four actions saved with Steven's audit name; exactly one booking confirmation was Sent and none was added for top-up payment. Contacts/roles were unchanged and only the 13 permitted finance/date fields changed among 89 compared booking fields. |
| Normal bulk preparation and completion | At **09:17:16 UTC**, **70 POSTs produced 70 exact correlated Leads and 70 Applied updates**, with 70 preservation guards passed across the 34 bulk bookings, zero retries and zero unknown outcomes. The 36 staff/heavy submissions were acknowledged and deleted; 34 logo declarations were retained. A subsequent separate read-only assertion verifies **all 34 bookings actually Complete**, with their exact Primary Contacts, original base finance, 33 single confirmation histories and three pack histories preserved. The assertion performs zero DML and zero email operations. |
| Edge preparation and restoration | At **09:47:57 UTC**, all **28 additional POSTs** were settled: **23 Applied and five expected Failed/rejected**, including two explicit ordinary-name restorations. Rejections covered a top-up reduction, repeated increase, incorrect base roster count and both wrong staff-form directions; each preserved the booking. Across normal plus edge preparation, **98 exact Leads and 98 preservation guards** are recorded, with 93 accepted updates, five retained expected rejections, zero POST retries and zero unexplained business outcomes. The 57 accepted staff/heavy Leads were acknowledged/deleted; 36 logo Leads retained. One read-only query timeout was recovered without another POST. |
| Initial and late final packs | Missing configuration queued zero. EX004 and EX002 each have one final pack Sent at 00:15:58 UTC. After EX005's actual logo declaration made it eligible, only EX005 received the later pack at 08:57:43 UTC; the first two histories were unchanged. The initial repeat queued zero/skipped two, and the later repeat queued zero/skipped one. Exact original routing, both pack URLs null, three preserved Sent rows, zero draft eligibility and zero globally queued packs were verified again at **09:38:17 UTC**. A reserved example PDF URL exercised routing only; real client pack contents and recipient delivery were not tested. |
| Post-pack top-up and separate edge finance | EX002's actual first one-place/£50 top-up after its pack reopened finance and changed Complete to false. Marking its top-up invoice/payment returned Complete to true while preserving the original booking finance, pack timestamp and single booking confirmation. EX021's first two-place/£100 top-up also passed its invoice/payment sequence. Each sequence changed only seven permitted top-up finance/date fields, preserved Contacts/roles and original dispatch histories, and created zero additional confirmation dispatches. Bulk recorded totals are £212,397 base + £5,100 top-ups = **£217,497 excluding VAT**; these are manual sandbox milestones, not real payment-processor charges. |
| Separate native CSV-prefix fixture | The actual hosted exhibitor-interest form created Harriet Benson / Company `=1+1`, Lead `00QAd00000USITlMAP`, at 09:39:38 UTC using a reserved example email. Native report 07's Details Only / UTF-8 CSV exported that exact field unescaped at 09:43:23 UTC. Text-only parsing found one exact matching record; no spreadsheet was opened or formula executed. Actual Master Panel Reject → OK then left this retained Lead Not Progressed, not converted and with no invitation or booking. Both inbound email statuses are Accepted by Salesforce, not delivery proof. Its intentionally unusual company name is the explicit name-edge test outside the original catalogue. |

Evidence: [74-case intake reconciliation](../tmp/nte-stress-20260907/bulk-harness/live-state-02/final-intake/cumulative-intake-summary.json), [retained application fields](../tmp/nte-stress-20260907/bulk-harness/live-state-02/final-intake/application-fields-query.json), [exact pre-Lead rejection proof](../tmp/nte-stress-20260907/intake-routing-APP-PS-018.json), [actual invitation MIME checks](../tmp/nte-stress-20260907/email-quality/inbox-journeys/invitation-verification.json), [three representative converted identities](../tmp/nte-stress-20260907/representative-converted-ids.json), [earlier native Cancel snapshot](../tmp/nte-stress-20260907/native-cancel-complimentary.json), [bulk finance progress](../tmp/nte-stress-20260907/panel-live-driver/current-progress.json), [16 immutable send results](../tmp/nte-stress-20260907/panel-live-driver/live-backend-01/phase-02-live/eoi-send16/result.json), [EX010 preservation](../tmp/nte-stress-20260907/panel-live-driver/live-backend-01/phase-02-live/resumed-readiness-finance/ex010-native-paid-preservation.json), [70 normal updates](../tmp/nte-stress-20260907/bulk-harness/preparation/normal70-completed/summary.json), [three settled pack histories](../tmp/nte-stress-20260907/dispatch-final-pack-plan/late-resume-01/all-settled/evidence.json), [exact routing restoration](../tmp/nte-stress-20260907/dispatch-final-pack-plan/late-resume-01/restoration/evidence.json). P16 and P17 retain newly exposed follow-up questions without treating expected rejection as valid-form loss.

The settled edge phase comprises 26 original HTTP cases plus two explicit restoration payloads. Seven separately recorded client-only cases were blocked with zero POSTs. Two exact live fixture gaps remain: a first **one-person** top-up while the base is unpaid, and an ambiguous duplicate reference. The actual 99-person unpaid-base case exercises the quantity-independent finance invariant, but is not relabelled as the exact one-person case. The two-place correction sequence and partner 6 → 8 name-count amendment likewise remain visible variants. No edge POST preceded the normal-34 Complete assertion. **Final readback now passes for all four edge-affected bookings**, and the deployed Completed controller response contains all 34 exact bulk booking IDs with their correct Primary Contact names/emails, recorded amounts and no remaining finance action. Its NTE2027 scope contains 33 allocated bulk rows among 38 total rows; NTE2028 contains the remaining allocated booking. These are read-only controller results, not a claim to have visually clicked every row in the browser.

Evidence: [all 98 preparation outcomes](../tmp/nte-stress-20260907/bulk-harness/preparation/all98-completed/summary.json), [final backend results](../tmp/nte-stress-20260907/panel-live-driver/FINAL_RESULTS.json), [final actual dashboard reconciliation](../tmp/nte-stress-20260907/panel-live-driver/live-backend-01/phase-02-live/final-dashboard-reconciliation/result.json), [normal all 34 actually Complete](../tmp/nte-stress-20260907/panel-live-driver/live-backend-01/phase-02-live/normal-complete34/executed/result.json), [final 140-case ledger](../tmp/nte-stress-20260907/catalog/coverage/final-01/case-coverage.json), [EX021 finance](../tmp/nte-stress-20260907/panel-live-driver/live-backend-01/phase-02-live/edge-topup-ex021/result.json), [EX002 finance](../tmp/nte-stress-20260907/panel-live-driver/live-backend-01/phase-02-live/edge-topup-ex002/result.json), [final pack and post-pack history result](../tmp/nte-stress-20260907/dispatch-final-pack-plan/final-mechanism-result.json), [final native Master/Home observations](../tmp/nte-stress-20260907/root-ui-resumed-20260908.json).

The final catalogue binds **37 original application cases to recorded conversions**: the 34 allocated bulk bookings and the three exact root native-UI conversions. Fenmere remains outside the original 140. The four unbound representative preparation IDs are `STAFF-EX-001`, `STAFF-PS-001`, `HEAVY-001` and `LOGO-001`; related actions were observed, but their exact catalogue fixtures must not be silently inferred. The two explicit exact live gaps are `STAFF-EX-002` (a first **one-person** top-up while the booking is unpaid) and `HEAVY-011` (an ambiguous duplicate booking reference). The actual 99-place unpaid-booking case tests a related invariant without closing the first exact gap. [Coverage by domain and unmapped cases](../tmp/nte-stress-20260907/catalog/coverage/final-01/coverage-summary.md), [final preparation-to-booking proof binding](../tmp/nte-stress-20260907/bulk-harness/preparation/all98-completed/final-state-proof-binding.json).

Final reports and protected records were reconciled after live mutations settled. NTE2027 has 38 readiness bookings at £249,347; the separate NTE2026 comparison booking contributes £2,000 and NTE2028 contributes £800, giving **£252,147 across events**. Finance 06 includes two unchanged older missing-price rows with blank confirmed values and excludes the two wholly complimentary bookings. Weekly Finance excludes those older rows by its date window. Pipeline 07 intentionally retains progressed/rejected unconverted history rather than showing only active work. These population differences are expected, and all nine report memberships and values match their definitions. All 2,057 retained pre-run Account/Contact/Lead/Opportunity records preserve their population and audit timestamps; all 103 saved walkthrough comparisons match, with no new dispatch or Task against its booking/contact. This is evidence for retained `queryAll` records and the available snapshots, not a complete pre-run backup or proof about hard-deleted records outside retention. [Final reports, full roster export and preservation](../tmp/nte-stress-20260907/metadata-final-reconciliation-20260908/RESULT.md).

The latest completion and preservation evidence is in [root final records](../tmp/nte-stress-20260907/root-representatives-final.json), the [actual completion assertions](../tmp/nte-stress-20260907/root-representatives-final.apex) and their [successful live result](../tmp/nte-stress-20260907/root-representatives-final.raw.json), plus [Fenmere's lifecycle result](../tmp/nte-stress-20260907/conversion-live-001/lifecycle-02/lifecycle-result.json) and [completed registry fragment](../tmp/nte-stress-20260907/conversion-live-001/registry-fragment.lifecycle-complete.json). The [actual inbox ledger](../tmp/nte-stress-20260907/email-quality/inbox-journeys/final-phase-ledger.json) contains 27 distinct message IDs, with [correction/rejection checks](../tmp/nte-stress-20260907/email-quality/inbox-journeys/final-corrections-verification.json) and a [final bounded count check](../tmp/nte-stress-20260907/email-quality/inbox-journeys/final-count-and-no-logo-proof.json) at 00:09:04 UTC. It finds one booking-payment confirmation each for Harbour, Cedarhaven and Fenmere, none for Willowbridge, and no extra success receipt from the rejected Harbour increase or separate logo acknowledgement within the recorded windows.

The [representative journey journal](NTE_REPRESENTATIVE_JOURNEY_JOURNAL_2026-09-08.md) and its [machine-readable companion](NTE_REPRESENTATIVE_JOURNEY_JOURNAL_2026-09-08.json) record exact case IDs, finance/correction steps, received messages and evidence boundaries. Willowbridge is catalogue APP-EX-003; APP-COMP-001 is its inbox alias, not another case. It distinguishes the three root native-UI conversions from Fenmere's API conversion, browser application entry from the two serializer-generated direct HTTP preparation POSTs, and both from the separate 74-request bulk intake. All four logo confirmations were simulated attestations because the client upload destination is pending; no file upload, genuine invoice issue, Stripe charge or final-pack send is implied. These are four completed preparation cases, not a final whole-run total.

## Consolidated corrections and required release work

**F01–F34 are implemented and deployed/published within their stated source scope.** The initial package passed 278 deployed tests; F34 passed all 24 actual class tests including its three new stored-template cases. The final combined check-only passes all 281 tests with exact source hashes. All intended public changes through F34 are byte-verified in the current 59-file website release. Live and isolated evidence are identified separately below. P1 denotes higher-impact integrity or finance behaviour; P2 denotes operational failures; P3 denotes presentation or lower-impact usability. Severity describes the reproduced/source-confirmed mechanism, not proof of a live incident unless actual evidence is stated.

### F01 — Keep malformed event codes out of new intake and default views — P2

**Trigger → before → after:** A main submission carries `ZZZZ`, or a supplementary-only event sorts above real event years → Home/Master Panel can default to an irrelevant event → new/changed main-intake codes must be `NTE` plus four digits, and default choices prefer canonical events from supported main records. Valid future years remain selectable. Existing irregular commercial events remain explicitly selectable for correction; there is no migration or deletion.

The resolver still defaults to the highest canonical event. Live future-year fixtures exposed the separate current-working-edition decision in P16; F01 does not claim to resolve that policy.

This prevents distorted starting queues without hiding historic records. The browser also blocks invalid edition configuration with a recipient-facing error.

**Evidence:** II-01, PB-07, metadata event-rule coordination, FORM-13; [input review](../tmp/nte-stress-20260907/input_integrity-findings.md), [panel backend](../tmp/nte-stress-20260907/panel-backend-findings.md), [metadata](../tmp/nte-stress-20260907/metadata-findings.md). Canonical/future/historical fixtures passed in the coordinated Apex deployment run.

### F02 — Use one usable booking-reference format throughout the journey — P1

**Trigger → before → after:** A browser receives `bad`, or an original application carries `BOOKING-001` → malformed HTML patterns can be ignored, while a nonblank unusable reference can reach preparation emails → browser patterns compile, inputs are trimmed/normalised, and application/notification guards use the existing bounded `NTE-...` grammar. Reminders and final packs also refuse unusable saved references. Existing identifiers are not silently rewritten.

This avoids inviting an applicant to complete forms that cannot accept the reference supplied. Example references now use valid syntax but remain examples.

**Evidence:** FORM-01, FB-EX-02, FBO-01, II-02, C03, DSP-8, EQ-4; [form findings](../tmp/nte-stress-20260907/form-engine-findings.md), [conversion](../tmp/nte-stress-20260907/conversion-findings.md), [dispatch](../tmp/nte-stress-20260907/dispatch-findings.md). Browser before/after and 80/81-character boundaries passed locally; the matching public forms/examples are published and byte-verified. The isolated reference guards passed in the coordinated deployment; wider live journey reconciliation remains separate.

### F03 — Submit the currently selected branches and freshly calculated values — P2

**Trigger → before → after:** Enter a companion, billing or second-contact detail, then switch its section off; alternatively restore or change a price/count control without its normal event → hidden copies or derived amounts can retain stale values → submission resynchronises applicable sections, counts, prices and copies, and disabled source fields are omitted.

The guest's discarded companion name no longer leaks through its hidden combined field. Switching paid → complimentary removes inapplicable billing/PO/contact requirements and payload fields while keeping values available if the applicant deliberately reopens them.

**Evidence:** FORM-02/07; [form harness](../tmp/nte-stress-20260907/form-engine-after.json), [other-form browser findings](../tmp/nte-stress-20260907/forms-browser-other-findings.md). Hidden payloads were checked with the source harness because the browser read surface masks them.

### F04 — Let applicants recover from corrected errors and interrupted submission — P2

**Trigger → before → after:** Submit two staff places with one name, then change only the quantity to one; or remove an incomplete optional vehicle → stale custom validity still blocks the corrected form → related changes clear and re-evaluate the error. A transport exception or cached Back restoration previously left Submit disabled; source now restores the controls and current validation state.

The staff and vehicle correction paths passed paired protected-browser before/after checks. Retry and duplicate-click guards pass isolated transport tests; live POST acceptance and Back-after-acceptance remain unproved here.

**Evidence:** FORM-03/10, FB-EX-01, FBO-03/04; [exhibitor browser evidence](../tmp/nte-stress-20260907/forms-browser-exhibitor-findings.md), [other-form browser evidence](../tmp/nte-stress-20260907/forms-browser-other-findings.md).

### F05 — Bound text correctly and isolate oversized roster submissions — P2

**Trigger → before → after:** Autofill/script values exceed a field limit, or individually valid base/top-up lists exceed their combined destination → data can reach an oversized payload; a bad top-up can consume the batch's in-memory allowance and roll back unrelated updates → explicit client length checks and combined-roster server checks reject it before accepted state changes.

Visible copied textareas receive their destination limits. The redundant partner roster copy into a 1,000-character legacy field is removed; its supported 32,768-character roster remains available. A later valid first top-up and unrelated booking can proceed after an oversized request.

**Evidence:** FORM-04/05/06, FB-EX-03, SUPP-04; [supplementary findings](../tmp/nte-stress-20260907/supplementary-findings.md). Local 40/41, 32,768/32,769 and combined-newline boundaries pass; the mixed-batch Apex regression passed in the coordinated deployment.

### F06 — Derive fixed prices from the actual application choices — P1

**Trigger → before → after:** Seven planned people are accompanied by a forged hidden total of two → the old pricing can charge £800 instead of £1,050 → the applicant's valid planned count is canonical and derived totals cannot override it. Lookalike discount categories, altered price labels, duplicated/removed packages and malformed selections no longer produce an apparently calculated valid/free price.

Only defined eligible categories receive power discounts. Whole-number/range checks reject invalid counts, browser exponent notation serialises as an ordinary integer, and decimal utility addition uses exact pence. No prices or retired catalogue choices are added.

**Evidence:** PR-1/4/5, FORM-08/09; [pricing findings and matrix](../tmp/nte-stress-20260907/pricing-findings.md). Browser/utility matrices pass. Direct-service malformed-multipicklist regressions passed; Salesforce may also reject or normalise some raw values earlier during field ingestion.

### F07 — Recalculate the current application at conversion without repricing history — P1

**Trigger → before → after:** An application changes from its original package/staff plan but retains stale or forged derived totals → conversion copies those old totals into the new booking → conversion obtains a fresh in-memory pricing snapshot from the current inputs and maps the calculated fields. Incomplete selections remain Check pricing instead of becoming complimentary.

The separate maintenance recalculation query now includes the staff field it reads, avoiding its missing-field exception. Existing payment/top-up facts, accepted historical prices and older bookings are preserved.

**Evidence:** PR-2/3, conversion stale-price section and coordinated metadata Flow; [pricing](../tmp/nte-stress-20260907/pricing-findings.md), [conversion](../tmp/nte-stress-20260907/conversion-findings.md), [metadata](../tmp/nte-stress-20260907/metadata-findings.md). The new-booking £1,550/£7,000 and protected synthetic older £777 scenarios passed as isolated native-conversion tests.

### F08 — Refuse internally inconsistent itemised financial emails — P1

**Trigger → before → after:** Saved rows say two sockets at £50 but socket total £50, with an overall £850 booking → aggregate-only validation can send the contradictory quote → each positive quantity requires a whole quantity, saved unit price and matching component total. Participant-inapplicable components cannot be hidden from the itemisation.

Approval and paid-confirmation readiness fail only the affected email; they do not rewrite saved money or erase recorded payment. Repair permits a controlled retry.

**Evidence:** C01; [conversion findings](../tmp/nte-stress-20260907/conversion-findings.md), tests `inconsistentItemisedPowerFailsOnlyItsBookingAndCanBeRepaired` and `inconsistentItemisationCannotBeSentAsAPaidConfirmation`. Both isolated Apex regressions passed in the successful deployment.

### F09 — Keep preparation links after conversion — P2

**Trigger → before → after:** Open either application before approval → its page exposes the heavy-vehicle preparation form and says it will arrive later → the premature callouts are removed, as expressly approved by the root. The application still asks whether logistics are needed; complete client terms remain.

Preparation links remain in the post-conversion message. This aligns the public pages with the existing review → booking journey without adding a gate.

**Evidence:** FORM-12 and corrected-source browser checks; [form findings](../tmp/nte-stress-20260907/form-engine-findings.md). Local browser absence verified; both application pages are included in the published 59-file byte verification.

### F10 — Do not trust workflow-owned success or decision fields on a new submission — P1

**Trigger → before → after:** A fresh interest claims Progressed/Rejected/Sent, or a fresh supplementary Lead claims Matched and Applied with a failed receipt → new work can disappear from active queues or skip normal payload validation → creation-only initialisation clears submitted workflow/email state. Genuine retry paths retain staff decisions and saved audit state.

This protects intake integrity without resetting later operational decisions. Public reachability of every internal audit field was not demonstrated; the source bypass, not an external exploit, is the established finding.

**Evidence:** INTAKE-01, II-03, SUPP-02; [intake](../tmp/nte-stress-20260907/intake-routing-findings.md), [supplementary](../tmp/nte-stress-20260907/supplementary-findings.md). Actual-create-Flow and active-queue regressions passed in the successful deployment.

### F11 — Retry only failed intake messages and preserve a durable result — P1

**Trigger → before → after:** Retry a receipt after only the internal notice failed, or fail the audit save after sending → both accepted messages can be repeated, or an accepted request can lack saved evidence → lock/re-read the Lead, skip accepted sides, check every send/save result and roll back newly queued messages if their audit cannot be saved.

Missing/short send results, exceptions, malformed/blank recipients and null requests now have explicit outcomes. A usable internal notice can still succeed when the applicant address is missing. If even failure recording cannot save, the exception surfaces instead of reporting success.

**Evidence:** INTAKE-02/04/06; [intake findings](../tmp/nte-stress-20260907/intake-routing-findings.md). Failure/retry cases passed in the isolated deployment suite; acceptance remains distinct from delivery.

### F12 — Handle ordinary intake batches within the shared email-call budget — P1

**Trigger → before → after:** A service receives 51+ two-message Leads, or NTE and volunteer work share one transaction → an invented 100-message cap fails all messages, or repeated ten-message calls exhaust the invocation budget → each service submits its complete list in one call and records retryable failures only when the shared invocation budget is unavailable.

This removes the identified cap without promising unlimited capacity: platform daily/provider restrictions still apply, and supplementary receipts retain a separate limit in P05.

**Evidence:** INTAKE-03; [intake tests](../tmp/nte-stress-20260907/intake-routing-findings.md). Passing isolated cases cover 60 NTE Leads/120 messages, 120 mixed Leads/240 messages/two calls, and a mocked 200-volunteer/400-message batch. They are not equivalent to live inbox sends.

### F13 — Fail a bad configured internal owner instead of silently notifying someone else — P2

**Trigger → before → after:** A nonblank NTE owner username does not identify an active User → routing can fall back to the inbound legacy owner → ownership is preserved and the internal send fails visibly; the applicant receipt can still succeed. Repair retries only the failed internal side.

An intentionally blank override retains the documented fallback. Volunteer internal recipients also require a usable active owner. This does not change unrelated ownership or introduce an alternative recipient.

**Evidence:** INTAKE-05; [intake findings](../tmp/nte-stress-20260907/intake-routing-findings.md), case `invalidConfiguredOwnerDoesNotFallBackToAnotherRecipient`. Final production owner/default-creator configuration remains a separate release dependency.

### F14 — Remove the second modern volunteer acknowledgement route — P1

**Trigger → observed before → corrected routing:** The canonical volunteer form with `useDefaultRule=0` submits one controlled application → Lead `00QAd00000URLgbMAH` produces two distinct applicant receipts, Gmail IDs `1a07e0e6418cf578` (native) and `1a07e0e625d016c6` (Apex), plus native Task `00TAd00000PO7pxMAD` → the root disables only the matching fifth auto-response entry by setting its formula to `FALSE`. The audited service remains the modern applicant sender; all five rule entries are retained and the first four compare unchanged. The internal notice went to Steven only.

**Status: actual duplicate confirmed, targeted MMUAT routing correction saved/retrieved, and a fresh post-fix one-receipt case verified.** James Walsh / `VOL-002`, Lead `00QAd00000URPXJMA5`, has exactly one observed applicant inbox receipt, `1a07e20f3ae4af95`, received at `2026-09-07T23:08:03Z`, with the Apex route and no native email Task. The correction was made through Salesforce Setup after a whole-rule metadata attempt failed on an unrelated legacy From address; that failed deployment is not the successful fix. No unrelated rule entry/template was changed. This live result, not Apex insert tests alone, verifies the native Web-to-Lead route for this case.

**Evidence:** INTAKE-07; [preflight rule](../tmp/nte-stress-20260907/preflight-metadata/autoResponseRules/Lead.autoResponseRules-meta.xml), [verified targeted correction](../tmp/nte-stress-20260907/routing-fix-verified.json), [retrieved corrected rule](../tmp/nte-stress-20260907/routing-after/unpackaged/unpackaged/autoResponseRules/Lead.autoResponseRules), [failed whole-rule attempt](../tmp/nte-stress-20260907/routing-deploy.json), [post-fix receipt](../tmp/nte-stress-20260907/email-quality/logo-fix/postfix-mail-verification.json), [post-fix native Task query](../tmp/nte-stress-20260907/volunteer-postfix-native-tasks.json). F31 addresses the separately reported image defect.

### F15 — Keep supplementary acknowledgements tied to the booking actually updated — P1

**Trigger → before → after:** Update booking A, fail its receipt, then change the retained Lead reference to B → retry can send A's submitted details to B's Primary Contact → successful processing stores a server-owned applied booking ID; retries require that identity and matching reference and never replay the data.

The receipt also takes its event from the matched booking, so a current-edition form can correctly acknowledge a valid NTE2028/29/30 booking. Exact reference matching remains independent of the submitted form year. Historic failed receipts without verified identity require P08 reconciliation.

**Evidence:** SUPP-01/05 and new applied-booking metadata; [supplementary findings](../tmp/nte-stress-20260907/supplementary-findings.md). Retargeting, missing/wrong/stale identity and multi-year receipt cases passed in the isolated deployment suite.

**Additional live evidence:** Harbour correction and Cedarhaven replacement receipts use the exact booking reference and Primary Contact inbox despite different submission/event contacts. Fenmere's receipt identifies its exact new booking rather than the prior-year decoy. [Actual correction receipts](../tmp/nte-stress-20260907/email-quality/inbox-journeys/final-corrections-verification.json) and [Fenmere lifecycle evidence](../tmp/nte-stress-20260907/conversion-live-001/lifecycle-02/RESULT.md) now complement the isolated checks.

### F16 — Require valid declarations and whole staff allocations before applying updates — P2

**Trigger → before → after:** An unsigned logo confirmation supplies a valid reference, or an old booking has planned staff `2.5` and two names → logo validation can return early and staff checks can truncate the allocation → every supplementary type passes declaration checks and whole valid allocation/count comparisons before any accepted state changes.

Invalid submissions retain the existing roster/logo/logistics and audit facts. Partial optional vehicle replacements and wrong staff-form types remain rejected. The accepted Closed Lost/post-pack update policy is covered by a regression and is not changed into a restriction.

**Evidence:** SUPP-03/06, catalogue CHK-01/02; [supplementary findings](../tmp/nte-stress-20260907/supplementary-findings.md). Raw scale-zero field coercion and real external logo upload are not proved by these service tests.

**Additional live evidence:** A paid Harbour top-up name correction preserves one place, £50 and all captured finance dates/by fields; a repeated increase is Failed and retained without changing the accepted booking. Cedarhaven's replacement clears the old trailer, registrations and haulier roster while preserving finance and event-contact facts. [Before correction](../tmp/nte-stress-20260907/representative-before-correction.json), [after correction](../tmp/nte-stress-20260907/representative-after-correction.json), [rejected repeat](../tmp/nte-stress-20260907/representative-supplementary-harbour.json), [final bookings](../tmp/nte-stress-20260907/root-representatives-final.json) and actual MIME agree. P02's rejection-reply decision remains pending.

### F17 — Hold the actual Primary Contact and reviewed booking details stable through dispatch — P2

**Trigger → before → after:** A Primary Contact/role or merged billing/staff detail changes while a worker is pending → some related data was unlocked or absent from the saved content fingerprint → sending paths lock the selected primary role/Contact and include current merged booking fields in the confirmation fingerprint. Changed content leaves the request unsent and recoverable; payment remains recorded.

Missing/ambiguous primaries still produce no email and no event-day/billing/submitter fallback. Panel reads remain ordinary nonlocking reads.

**Evidence:** DSP-2/5 and coordinated conversion/supplementary calls; [dispatch findings](../tmp/nte-stress-20260907/dispatch-findings.md), [fingerprint source check](../tmp/nte-stress-20260907/dispatch-source-check.json). Seventeen omitted native fields became zero in the static check. True competing transactions remain untested.

**Additional live evidence:** Fenmere uses the explicit seeded Leonie Contact while applicant Elliot stays event-contact data; captured core Contact/Account fields and the NTE2026 decoy remain preserved through conversion and preparation. Three actual received messages have the correct new booking and allocated recipient. The decoy has a tied pre-commit timestamp, so this does not prove the strictly newer-timestamp variant. See [conversion preservation](../tmp/nte-stress-20260907/conversion-live-001/RESULT.md) and [full lifecycle](../tmp/nte-stress-20260907/conversion-live-001/lifecycle-02/RESULT.md).

### F18 — Preserve literal recipient text and readable multiline alternatives — P2

**Trigger → before → after:** A company is `Harbour {NTE_PREPARATION_LINKS} & Sons`, a name contains `{!literal}`, or native HTML includes a newline followed by `<br>` → chained replacements can alter data/fail the email and text conversion can double spacing → maintained tokens are expanded once; inserted data stays literal/escaped; source newlines adjacent to a break are normalised without deleting intentional blank lines.

The five native approval/payment templates, preview generator, plain-text extraction and custom dispatch renderer change together. Existing client wording remains intact.

**Evidence:** C05, EQ-2/3, DSP-3; [email quality](../tmp/nte-stress-20260907/email-quality-findings.md), [conversion](../tmp/nte-stress-20260907/conversion-findings.md). Local contracts pass. **The native `literalTemplateSyntaxAndHtmlLookingNamesRemainRecipientText` render regression passed in the successful deployment**, covering the chosen comment markers and escaped/literal fixture data. This does not claim every possible native merge value was exercised.

### F19 — Reject unusable destinations and oversized personalised messages before queueing — P1/P2

**Trigger → before → after:** Configure `https://`, credentials or whitespace in a preparation URL; expand a short authored token to a subject over 255 or message over 32,000 characters → invalid links/content can reach dispatch or fail late → URL checks require a real HTTPS host without credentials/whitespace, and limits are checked after personalisation, during preview/queue and again before sending.

Only applicable participant/logistics links are required. Saved data is not rewritten, and the affected send receives an actionable explanation. F32 separately addresses aggregate batch size and passed its isolated runtime regressions; live-volume limits remain in P05.

**Evidence:** C02, DSP-4/7; [conversion](../tmp/nte-stress-20260907/conversion-findings.md), [dispatch](../tmp/nte-stress-20260907/dispatch-findings.md). The isolated Apex destination/content-boundary cases passed in the successful deployment.

### F20 — Keep long valid names and subjects inside email layouts — P2

**Trigger → before → after:** Use maximum-length unbroken names/organisation and a long valid subject → 375 px messages expand to 526–2,330 px; custom mail can reach 5,170 px → fixed table layout and long-word wrapping retain the available width.

All 21 source-template long fixtures and three custom categories now fit exactly at 375 and 768 px. Preparation buttons remain horizontal at the larger width and stacked at phone width; the Mission Motorsport logo/identity remain correct.

**Evidence:** EQ-1, DSP-6; [email browser measurements](../tmp/nte-stress-20260907/email-quality/browser-results.json), [email findings](../tmp/nte-stress-20260907/email-quality-findings.md). This is browser fixture evidence, not an Outlook/Gmail or live inbox matrix.

### F21 — Show the booking's paid money while its top-up is still outstanding — P1

**Trigger → before → after:** £1,000 booking paid/invoiced, £100 top-up unpaid/uninvoiced → Home removes the paid/invoiced booking value and shows £1,100 to collect → it shows £1,000 Paid, £1,000 Invoiced and £100 still to collect. Finance readiness independently counts the four agreed refiners, including simultaneous booking payment/top-up invoice work and a complimentary quote requirement.

Approved/provisional applications are labelled Approved applications rather than Confirmed Applications. Payment confirmed still means every applicable charge is paid; a partial Paid money headline is deliberately different.

**Evidence:** PB-01/02, UI-09/17; [panel backend](../tmp/nte-stress-20260907/panel-backend-findings.md), [panel UI](../tmp/nte-stress-20260907/panel-ui-findings.md). The eight-booking money reconciliation and all sixteen stored invoice/payment combinations passed in Apex; UI amount checks also pass locally.

### F22 — Make native finance views and reports agree with the combined charge workflow — P2

**Trigger → before → after:** Open native finance views for a paid booking with an unpaid top-up, or the cross-event report for quote-only/Check pricing work → booking-only overwritten definitions omit work; invalid prices can contribute confirmed value → generated predicates include both charges, quote order, pricing work and one Opportunity row per result.

Confirmed value is blank when saved pricing is invalid; a valid historical £700 Amount plus £50 top-up remains £750 rather than being silently repriced from a listed £800. Weekly reporting retains its rolling Last 7 Days behaviour. Old separate top-up views are not deleted; their proposed retirement is P09.

**Evidence:** META-01/02/04; [metadata findings](../tmp/nte-stress-20260907/metadata-findings.md). Definition/generated-source checks passed, the generated formulas/list definitions compiled in the successful deployment, and the 13-state finance fixtures passed. Historical Calculated-zero behaviour remains P04.

### F23 — Keep decided/ineligible work out of active queues and reject stale finance actions — P1/P2

**Trigger → before → after:** Replay a finance action after the booking became Closed Lost or noncommercial, open a global list containing rejected/progressed Leads, or inspect recent decided records → an ineligible action can write flags and native lists/history can imply active review → the locked action rechecks eligibility; native active lists exclude decided Leads; recent rows show their real Rejected/Invited/Queued/Converted outcomes.

Reports and work views use actual closed/lost semantics, including differently named lost stages, while retaining closed-won bookings. Repeated rejection cannot write a second decision. Misleading all-bookings shortcuts from Completed/final-pack views are removed through the coordinated panel changes; cross-event reporting remains. Preparation updates on closed bookings remain allowed.

**Evidence:** PB-03/08, META-05/07; [panel backend](../tmp/nte-stress-20260907/panel-backend-findings.md), [metadata](../tmp/nte-stress-20260907/metadata-findings.md). The generated package compiled and the isolated eligibility/history regressions passed; final live navigation acceptance remains a separate check.

### F24 — Show why a booking still needs preparation and include its real contact in reports — P2

**Trigger → before → after:** Logistics says `Awaiting transport plan`, or only the logo remains outstanding → a booking is incomplete but can disappear from Updates or show only apparently complete cells → every answer other than explicit No/completed Yes remains logistics work, and combined Updates displays the existing Logo status.

Reports now include logo/final-pack fields and the native Primary Contact column. The former `FULL_NAME` field was the Opportunity Owner, not the Primary Contact; separately identified event-day/secondary contacts remain.

**Evidence:** PB-04, UI-16, META-03 and logistics part of META-05; [metadata Analytics descriptions](../tmp/nte-stress-20260907/metadata-findings.md), [panel tests](../tmp/nte-stress-20260907/panel-backend-findings.md). Eighty readiness combinations and persisted unknown-logistics cases passed in Apex; logo-column binding passes local tests. Final real Lightning display acceptance remains separate.

### F25 — Stop pagination at the real accessible last page — P2

**Trigger → before → after:** Advance past offset 1,950, click Next repeatedly during loading, or remove the last row of a later page → repeated pages, skipped offsets or an empty stale page can result → server returns the accepted offset/last-page contract and the UI waits for it. The final 25 rows up to the existing latest-2,000 limit become accessible; shrinking queues return their valid last page.

The bound is visible instead of implying every historical result is accessible. This fixes navigation, not the larger-event scale limitation in P06.

**Evidence:** PB-05, UI-02; [backend findings](../tmp/nte-stress-20260907/panel-backend-findings.md), [panel local tests](../tmp/nte-stress-20260907/panel-ui-current.tap). The UI suite and persisted Apex paging/order regressions passed.

**Additional live evidence:** The actual NTE2027 Approved view showed 25 then 12 rows, disabled Next on the last page and enabled Previous. Switching the second page to the 17-row partner/sponsor refiner returned to its valid first page with both navigation buttons disabled. These interim data counts and the observed controls are recorded in the [native UI journal](../tmp/nte-stress-20260907/root-ui-resumed-20260908.json).

### F26 — Keep reviewed actions and recipient selection stable until the operation finishes — P1/P2

**Trigger → before → after:** Double-click a decision, change filters during draft preparation, fail recipient refresh then edit text, or reuse stale event/owner filters → duplicate actions or a broadened/stale sendable draft can result → controls lock before confirmation, refresh/late responses cannot change the pending work, failed refresh remains unsendable, and invalid explicit filters fail instead of falling back to another event/all owners.

The exact reviewed request is sent once. Subject/selection changes invalidate preview; disconnected or out-of-date responses cannot revive old modal state. Native server eligibility and duplicate guards remain necessary.

**Evidence:** UI-01/03/04/06/15, PB-06; [panel UI](../tmp/nte-stress-20260907/panel-ui-findings.md), [panel backend](../tmp/nte-stress-20260907/panel-backend-findings.md). Controlled asynchronous UI regressions and isolated native stale-filter cases passed; genuinely simultaneous transactions remain unproved.

**Additional live evidence:** The invitation composer initially selected all 15 eligible recipients, Clear produced a disabled Send to 0, Select all restored 15, and manual deselection followed by Refresh preserved 14 of 15. Scrolling the personalised email left the Send button at the same visible viewport position. These were preview-only checks; they did not send additional invitations. See the [native UI journal](../tmp/nte-stress-20260907/root-ui-resumed-20260908.json).

### F27 — Report queue and retry outcomes truthfully — P2

**Trigger → before → after:** Queue returns zero, provisional retry cannot enqueue, or an accepted retry's UI refresh fails → the UI can report a fabricated queued email or contradict success with a failure message → zero stays visible as No emails queued; provisional retry returns the persisted outcome; refresh failure is a separate warning about display refresh.

The retry captures the exact record ID for its full operation and preserves the saved request after uncertain network results. A queued or accepted request is never called delivered.

**Evidence:** C04, UI-05/07/08; [conversion](../tmp/nte-stress-20260907/conversion-findings.md), [panel UI](../tmp/nte-stress-20260907/panel-ui-findings.md). Local UI assertions, queue-failure injection and isolated retry service cases passed.

### F28 — Improve accessible controls, focus and concise operational copy — P3

**Trigger → before → after:** Use choice groups with a screen reader, keyboard the stage controls, tab a rich-text modal, return to a selected record or view narrow Home → unnamed groups, nonstandard keyboard roles, escaped focus, lost selection or misplaced controls can hinder use → groups are named, stages use native buttons, modal/return focus is handled, selection survives refresh, and the narrow header fits.

The composer removes repeated visible addresses while keeping accessible recipient labels and meaningful statuses. Form configuration failures use concise recipient-facing unavailable/retry text rather than API names. Actual Lightning now verifies selected composer, scrolling, pagination, detail and finance controls; full keyboard-focus, assistive-technology and physical-mobile acceptance is not established by those checks.

**Evidence:** FORM-11/13, FBO-02, UI-10/11/12/13/14; [forms](../tmp/nte-stress-20260907/form-engine-findings.md), [panel UI](../tmp/nte-stress-20260907/panel-ui-findings.md), [resumed actual panel checks](../tmp/nte-stress-20260907/root-ui-resumed-20260908.json). The independent panel review's initial browser-access failure remains a limit of that review; it does not negate or expand the later root browser evidence.

### F29 — Avoid rendering 500 complete emails just to open one draft — P2

**Trigger → before → after:** Prepare the supported maximum of 500 recipients → the service builds/stores each full preview despite an existing per-recipient preview endpoint → it returns one initial preview and produces others only when requested.

This reduces avoidable synchronous response/heap load while retaining exact selection and the 500-recipient ceiling. The original maximum-volume heap failure was not run in the org; the change removes demonstrated unnecessary allocation, not a reproduced live crash.

**Evidence:** DSP-1; [dispatch findings](../tmp/nte-stress-20260907/dispatch-findings.md), passing `largestDraftAndQueueKeepOnlyOneHtmlPreview` in the successful deployment. The separate aggregate guard is F32, with verification limits retained under P05.

### F30 — Let the documented Forms Administration permission set open the NTE workspace — P2

**Trigger → before → after:** Assign only `NTE_Forms_Administration`, documented as sufficient for the workspace → application visibility/controller access are missing → those existing app/class permissions are added in the generator.

This does not change the accepted sharing model or grant unrelated data access. The generated permission definition has passed its checks and compiled in the coordinated deployment; effective access for a real non-admin user is still unverified.

**Evidence:** META-06; [metadata findings](../tmp/nte-stress-20260907/metadata-findings.md). Definition checks pass; real permission impersonation has not occurred.

### F31 — Correct the garbled Mission Motorsport logo without changing the artwork — P2

**Trigger → observed before → corrected asset:** The owner opens either received volunteer acknowledgement and reports a garbled logo → both actual emails reference the same `.png` URL, served as `image/png`, but the file is WebP and relies on transparency over hidden RGB regions → the official 1500 × 767 artwork is re-encoded as a genuine opaque RGB PNG over the existing white header background. The rendered visible RGB pixels are identical: **zero changed visible pixels**, with no resizing or redrawing.

Both volunteer email templates add `?v=20260907-png` to the image URL so future emails request the corrected asset rather than the old cached URL. The corrected PNG and matching public sources/examples are published and byte-verified; the updated Salesforce templates were included in the successful package deployment. James Walsh's actual post-fix receipt `1a07e20f3ae4af95` uses the versioned URL. Its exact hosted image has the PNG signature, opaque RGB encoding and expected hash and was visually inspected as clear. The message's HTML/plain text agree and retain Mission Motorsport branding. Direct Gmail UI access was unavailable to that independent probe, so this is actual-message/asset evidence rather than a broad mail-client display claim. Old received messages may retain their earlier cached image; the exact Gmail proxy failure mechanism remains unproved.

**Evidence:** EQ-5; [logo verification](../tmp/nte-stress-20260907/email-quality/logo-fix/verification.json), [actual post-fix message/asset verification](../tmp/nte-stress-20260907/email-quality/logo-fix/postfix-mail-verification.json), [email-quality follow-up](../tmp/nte-stress-20260907/email-quality-findings.md), [hosted verification](../tmp/nte-stress-20260907/hosted-verification.json). PNG signature/encoding/dimensions/cache-version assertions passed. Original MIME/HTML, original served bytes and corrected proofs remain in the logo-fix evidence directory.

### F32 — Reject aggregate email content before it can exhaust the queue-building transaction — P2

**Trigger → before → source correction:** Select 500 recipients with a 32,000-character body, or individually valid messages whose tokens/escaping expand substantially → the former path can accumulate 16,000,000 raw message characters plus recipient-row overhead without an aggregate guard → a two-stage size preflight checks the eligible unchanged selection against current remaining transaction memory before retaining the dispatch collection, writing statuses or queueing a job.

The estimate includes raw, personalised and HTML-escaped content and probes one temporary row at a time. Oversized selections receive a concise instruction to shorten the message or select fewer recipients; the ordinary 500-recipient default message remains a required supported case. The estimate is conservative and may reject a batch that a particular platform allocation could fit; it is not a claim of an exact memory guarantee or a new fixed recipient cap.

**Status: deployed; all aggregate-size regressions and the ordinary 500-recipient case passed in the successful 278-test deployment.** The earlier third check-only run passed 276 tests and failed two newly added size fixtures because their chosen expansions did not exceed the actual validation-context allowance. The corrected fixtures derive their sizes from the reported runtime limit and prove their bounds before asserting rejection; the guard was not weakened. No original heap crash was intentionally executed, so the report does not claim a reproduced pre-fix live crash. Isolated passing cases do not certify every later live batch or allocation pattern.

**Evidence:** DSP-9; [dispatch evidence and size model](../tmp/nte-stress-20260907/dispatch-findings.md), [earlier third validation](../tmp/nte-stress-20260907/validate-third-report.json), [successful deployment/test results](../tmp/nte-stress-20260907/deploy-package-report.json), [queue-size source](../force-app/main/default/classes/NTEEmailDispatchService.cls). P05 retains live-volume qualification and the independent supplementary-receipt limit. P09 remains the unrelated old-list-view retirement decision.

### F33 — Refresh date limits when an open form crosses London midnight — P2

**Trigger → observed before → corrected behaviour:** The root opens exhibitor EOI on 7 September, leaves the tab open through London midnight and enters the valid new-day declaration `08/09/2026` → the stale `max=2026-09-07` rejects it, although a freshly opened volunteer page accepts 8 September → `assets/forms.js` refreshes date constraints during form-state synchronisation before validation and when a date field receives focus. The applicant's entered declaration date and date of birth are not changed or backdated.

The focused deterministic suite covers all ten forms at both BST and GMT midnight, preserves an earlier valid date, rejects genuinely future dates, checks picker refresh and verifies the DMY payload. **All 24 focused checks fail before and pass after**; the complete form suite is now **123 passed, zero failed, with 34,986 catalogue/boundary combinations**. Publication `491cadd974b15d1b9da5542217e8d0cdc19834e1` introduced form asset `20260908-1`, retained in the final F34 publication; all 59 intended served files match. This is a public-script correction; no Salesforce business rule or component changed for it.

**Evidence:** FORM-14; [form-engine follow-up](../tmp/nte-stress-20260907/form-engine-findings.md), [24 before failures](../tmp/nte-stress-20260907/form-engine-midnight-before.json), [24 after passes](../tmp/nte-stress-20260907/form-engine-midnight-after.json), [full updated suite](../tmp/nte-stress-20260907/form-engine-after-midnight-fix.json), [hosted verification](../tmp/nte-stress-20260907/hosted-verification.json). The clock fixture does not change the machine clock, and these isolated checks are not counted as 24 live submissions.

### F34 — Omit empty email details and use a complete greeting — P3

**Trigger → observed before → approved correction:** An application has no second/third vehicle or optional finance contact, or an imported Primary Contact has no FirstName → actual/native-rendered messages can show separator-only details such as `Item 2 - - -`, `Finance contact · ·` and `Hi ,` → omit wholly empty optional detail rows and use an appropriate complete greeting, while retaining populated client details, terms and the existing email timing/recipient rules.

The source correction covers 11 greetings, 14 optional rows and 12 joined cells across 14 maintained templates. Existing nonblank greetings and supplied client details stay intact; text values `0` and `false` are not treated as absent, and numeric/picklist/status rows keep their existing behaviour. Ordinary field merges retain their escaping and multiline handling. No recipient, sender, query, timing or finance rule changed.

**Status: corrected source deployed, published and qualified.** Actual deployment `0AfAd00000SpkOrKAJ` succeeded at **10:04:43 UTC**, with **15/15 components, 24/24 complete-class tests and zero errors**. All three new actual stored-template tests pass, including full HTML/plain-text parity. Final combined check-only `0AfAd00000Spkn3KAB` then passed **423 components and 281 tests**, with all source hashes unchanged. Local email contracts pass **311/311**, with **39/39 additional parity assertions** across 105 fresh fixtures; all 21 normal examples are byte-identical. No extra applicant message was sent or existing inbox message changed to perform this qualification.

The first attempt `0AfAd00000SpiOfKAJ` failed and rolled back with 23/24 tests, despite no component compile errors. Its actual optional-row test exposed Salesforce dropping real newlines inside formula branch literals, which joined a partially populated finance row to the following text row. The corrected source moves newline-only separators outside those formulas. Nine inline native merges supported the diagnosis; the subsequent deployed **stored-template** tests then passed without a transport-decoding workaround or weakened assertions.

The original 48-file candidate, corrected delta and hashes are saved independently. Canonical commit `8d1f7c19f4f18f73905147669e7a9147ed62d14c` publishes its 14 maintained email-source HTML changes, with all 59 intended files byte-verified at 10:13:01 UTC. The final source inventory and before/after validation hashes match across all 485 entries, including all 48 reviewed F34 files. Existing inbox messages are retained and cannot be rewritten by this correction.

**Evidence:** [F34 source, native probes and qualification boundaries](../tmp/nte-stress-20260907/email-quality/p11-review/README.md), [local parity results](../tmp/nte-stress-20260907/email-quality/p11-review/fixture-parity-results.json), [corrected candidate manifest](../tmp/nte-stress-20260907/email-quality/p11-review/F34-v2-file-manifest.json), [successful actual narrow deployment](../tmp/nte-stress-20260907/metadata-f34-v2-qualification-20260908/narrow-deploy.start.raw.json), [final combined qualification and hashes](../tmp/nte-stress-20260907/metadata-f34-v2-qualification-20260908/summary.json), [earlier failed and rolled-back deployment](../tmp/nte-stress-20260907/metadata-f34-qualification-20260908/narrow-deploy.failure-summary.json). Annual date configuration and the optional internal Open Lead link remain deferred P11 proposals.

## Preserved decisions, open risks and proposed follow-up

These entries are not implemented features or blanket approval requests. Some require a business decision; others require a bounded technical reproduction or a client asset before a change can be made concrete.

### P01 — Decide what happens to a provisional retry after payment confirmation

The immediate payment-confirmation decision is settled. The remaining edge is: provisional failed → payment recorded and confirmation sent → someone retries the old provisional. That could tell an already confirmed organisation its space is provisional again. Decide whether to suppress that retry, replace its content with appropriate preparation information, or use another explicit recovery. Retain the failed-send audit and do not undo payment. No chosen resolution or verified implementation is asserted. Source: conversion/dispatch findings and root's consolidation instruction.

### P02 — Decide how rejected supplementary submissions receive actionable feedback

Invalid/top-up-repeat submissions preserve the booking, but generic form navigation does not prove an update was accepted. The user-facing rejection reply is still pending. Decide the permitted recipient/content when an exact booking matches and when no booking can be found; the Primary Contact rule does not authorise silently emailing the form submitter. Do not call a simulated/browser thank-you an applied update. Sources: supplementary and other-form browser findings.

### P03 — Decide the permitted native conversion options

**No Opportunity:** native conversion can mark the application converted without a booking, bypassing the booking Flow. **Existing Opportunity:** conversion can replace a previously paid synthetic £777/NTE2098 exhibitor's fields with a £2,000/NTE2099 partner application while old payment/approval flags remain. Both isolated native-conversion characterisation tests now passed in deployment `0AfAd00000SpIFhKAN`; their success verifies the risky existing behaviour, not an approved target workflow. Actual operator UI/default qualification and the policy decision remain outstanding. Decide whether NTE must always create a new event booking or allow a tightly defined exception. Continue using explicit synthetic Account/Contact IDs in tests; never auto-merge genuine records. Sources: [conversion evidence](../tmp/nte-stress-20260907/conversion-findings.md), [successful characterisation tests](../tmp/nte-stress-20260907/deploy-package-report.json), catalogue DEC-02.

**Feasibility:** requiring a new booking can preserve reuse of existing Accounts and Contacts. A synchronous refusal must roll back the entire conversion before copied fields or messages can persist; merely skipping the booking copy would still lose the application from the active queue. A native-screen safeguard could check insertion provenance and prior booking history, but “inserted in this transaction” alone does not prove this conversion created the target. The demonstrated paid fixture itself was inserted earlier in the same transaction. A strict guarantee against every existing-Opportunity API choice would need a controlled NTE conversion service/action or a separately qualified creation-time provenance mechanism. No guard was implemented, and a timestamp or blank-field shortcut is not proposed as an equivalent fix. [Read-only design options and required rollback qualification](../tmp/nte-stress-20260907/panel-live-driver/P03_NEW_BOOKING_FEASIBILITY.md).

### P04 — Historical Calculated-zero records still need a separate reconciliation design

The root deliberately retained this run's saved-price predicate: Calculated plus zero can look ready in panel/report views without proving the exact complimentary category/space pair or itemised facts. New intake/conversion is stricter. A future correction needs a normalised eligibility fact, common predicates and an approved inventory/reconciliation of historic records. No historical backfill or repricing occurred. This is a known retained limit, not an unresolved choice about whether current ordinary paid prices may be zero. Sources: panel backend and META-01.

### P05 — Aggregate-size guard deployed/tested; live-volume qualification and supplementary limits remain

**Aggregate guard: implemented, deployed and verified by the isolated F32 regressions.** F29 removes unnecessary previews and F32 checks raw/personalised/escaped aggregate content before retaining dispatch rows. The normal-500, maximum-pair, personalisation and HTML-expansion cases all passed in the 278-test deployment; the 500 × 32,000 gap is no longer an unimplemented proposal or an unexecuted fixture. No pre-fix heap crash is claimed, and the completed bounded live run does not certify every volume/concurrency condition. Separately, the supplementary worker still records more than 100 acknowledgements as failed with separate-retry guidance even when data saves. Do not confuse that with F12's corrected NTE/volunteer intake batching. Forty-record page tests/finalizer helper tests do not prove live queue chaining or all daily limits. Sources: dispatch, supplementary and conversion findings, plus the final deployment result.

### P06 — Larger-event navigation and Home aggregation remain future work

The panel intentionally exposes only the latest 2,000 rows per view; F25 makes that boundary accurate and visible. Home still loads matching event Leads/Opportunities and is subject to query-row/heap limits; no 50,000-record run was performed. Cursor paging and server-side aggregation are potential scale changes, not claimed fixes. Existing newest-modified/ID order remains accepted. Search is optional U02; no new urgency/capacity sorting is proposed. Source: panel backend findings.

### P07 — Choose an accessible failed-intake recovery route

F11 makes the intake service safe for failed-side recovery, but no existing panel action exposes it to ordinary operators. Decide between a dedicated failed-intake queue/action and the administrative Flow/invocable route. There is no new automatic retry schedule and no claim that all intake failures can already be recovered through the panel. Source: intake findings.

### P08 — Reconcile old failed update receipts before retrying them

F15 deliberately refuses to rematch a historic applied receipt that lacks a verified saved booking identity. Some old failed receipts therefore require a reviewed association before retry. Do not guess from an edited reference, mass-backfill identities or replay old data. Source: SUPP-01.

### P09 — Decide whether to retire the three old separate top-up list views

Combined primary finance routes are corrected independently. The three obsolete top-up native views still exist, have no current navigation/code references outside generation/package records, and are not deleted by this run. A later explicit retirement should preserve current data and be included in a reviewed removal manifest. Source: metadata findings.

### P10 — CSV-prefix work declined; full-roster export qualified

**Decision closed: no further CSV-prefix work.** On 8 September the owner explicitly said names starting with `=` do not need to be accounted for. No export setting or input rule was changed; this is not a pending decision, release requirement or recommended follow-up.

For historical traceability, three formatted XLSX probes stored benign `=`, `+`, `-` and `@` values as explicit text with no formula nodes. The separate native Report 07 CSV retained Company `=1+1` without a protective prefix, SHA256 `91c5a26c7a05dafade09334c2d36c5e8114acb7d2bd75f165f48238bb0748c65`. No spreadsheet was opened or formula executed. The exact synthetic Lead was subsequently rejected through the native panel and remains a separately indexed fixture outside the original 140 cases.

**Separate export-format limitation, now qualified:** the Reports API returns only the first 254 characters plus an ellipsis for four long roster fields across 13 cells. The fresh native Report 08 **Details Only / CSV / UTF-8** export preserves every name in all 99/101-name rosters, with **2,080/2,080 source-cell comparisons passed**. Only embedded line endings were normalized; no text was trimmed, and 137 populated date/time cells were compared at native minute display precision. CSV SHA256: `b1ced4105dabbd786dd7af822dc456407b67a032cab6b40fc4868ccfb64dcdac`.

Use that verified Details Only CSV route when the team needs a complete roster. Salesforce documents truncation in report display, formatted Excel and Details Only XLSX, and identifies Details Only CSV/XLS for full long text. The audit verified CSV, not an XLS export. This is a native format limitation, not lost stored names or a package fix. This operational export guidance is separate from the declined prefix work. [Salesforce export guidance](https://help.salesforce.com/s/articleView?id=000389623&language=en_US&type=1), [final full-cell CSV qualification](../tmp/nte-stress-20260907/metadata-final-reconciliation-20260908/native-csv-reconciliation.json).

Evidence: [exact new native CSV probe](../tmp/nte-stress-20260907/root-csv-prefix/inspection.json), [preserved CSV bytes](../tmp/nte-stress-20260907/root-csv-prefix/native-report07.csv), [completed form/export/rejection journey](../tmp/nte-stress-20260907/root-csv-prefix/RESULT.md), [earlier export inspection](../tmp/nte-stress-20260907/metadata-export/RESULT.md), [XLSX results](../tmp/nte-stress-20260907/metadata-export/inspection-summary.json), [ordinary CSV results](../tmp/nte-stress-20260907/metadata-export/native-csv-inspection-summary.json). The extra synthetic Lead is retained as Not Progressed with no conversion/invitation and does not increase the original 140-case denominator.

### P11 — Retain the small email experience gaps for a separate scoped decision

The confirmed empty optional rows and blank-FirstName greeting are now approved F34 work, with its status tracked separately above. The remaining proposed improvements are a verified annual event date in footers and a direct Open Lead link in the partner internal application notice. No annual date should be inferred or the old 2027 date hardcoded into reusable mail. These two optional changes remain deferred; they are not included in F34. Source: email-quality remaining observations and final email review.

### P12 — Keep separate-submission and volunteer/guest policy questions explicit

Same-page repeated Submit is protected, but whether separate same-person/organisation submissions should be linked, blocked or kept remains undefined. Volunteer consent No and DOB inputs are captured; no minimum age, consent-based next step or guest/volunteer approval/conversion journey has been invented. Preserve the existing noncommercial intake and do not turn those Leads into exhibitor bookings. Sources: catalogue DEC-01/03/04 and other-form browser findings.

### P13 — Wait for actual client destinations and finance decisions

Final logo storage/upload, final-pack content and event-specific URLs, production NTE application URLs/terms, production owner/form IDs, Stripe merchant/bank verification, VAT and financial-document choices remain external dependencies. An enabled logo attestation while its upload destination is absent is not evidence of a file upload; any change to that self-declaration behaviour needs an explicit scope. No production charge, storage destination, document or final pack was invented. U15–U20 identify related optional proposals with their own dependencies.

### P14 — Keep remaining input/persistence probes distinct from established failures

The maintenance pricing methods still use partial-save results without exposing per-row outcomes; no ordinary failing persistence case was reproduced. Unexpected supplementary DML failures can still roll back their transaction; F05 isolates the demonstrated oversize payload only. Scale-zero input fields may coerce raw fractions before Apex sees them. Invisible-only Unicode format characters were raised for follow-up without a broad stripping rule. The named native escaping/comment-retention fixture now passed in the deployed suite; raw Web-to-Lead coercion and the other bounded probes need separate results before a broader defect or remedy is asserted. The native company-name dash observation is closed as private browser automation input handling: a real keyboard commit and collapsed native summary preserved the requested Harbour name; explicit API naming also persisted, and retrieved automation showed no naming override. No package naming defect or new fix is established. The [read-only investigation](../tmp/nte-stress-20260907/metadata-native-name-investigation.md) retains the observed evidence and its limits. The separately proven retired-picklist rejection and its feedback limitation are P17. Sources: pricing, supplementary, form-engine and input-integrity limitations, plus root's recorded native-conversion observations.

### P15 — Completed release qualification and explicit coverage limits

**The allocated release/verification work is complete.** Actual deployment of F01–F33 passed 423 components/278 tests; F34's actual narrow release passed 15/24. The final combined check-only `0AfAd00000Spkn3KAB` passed 423/281 with all 485 source/manifest hashes and 48 reviewed F34 hashes exact. The current preview has 59/59 files verified. Actual evidence includes all 34 bulk conversions and 33 base payments, 16 bulk invitations, 98 preparation submissions, native booking/top-up finance, initial two plus late one final pack with zero-message repeats and exact restoration, selected Lightning controls and native CSV/XLSX exports. The representative inbox scope remains 24 root application-journey messages plus three Fenmere lifecycle messages. These scopes must not be summed or described as an unlimited end-to-end test.

The normal all-34 Completed assertion, all 98 preparation outcomes, post-pack top-up/finance protocol, final affected-booking readbacks, all-34 Completed controller reconciliation and final native Home/Master observations pass to their stated limits. All nine final reports, full-roster native CSV and the retained/protected-data checks reconcile. The final original-case ledger is 110 live observations/14 browser-only/ten local-only/six unmapped, with 37 recorded conversions; additional cases remain separate. The two exact live gaps and four unbound representative fixture IDs are retained above. Full keyboard/focus/assistive-technology and physical-device coverage, genuine concurrency, full live platform-limit loads and a broad Outlook/Gmail rendering matrix remain unproved dimensions. These are coverage qualifications for a future scoped run, not unfinished execution or a claim that this run tested every permutation. P10's prefix work is explicitly declined. The [root resume record](../NTE_AUDIT_RESUME.md) retains exact results to prevent accidental replay.

### P16 — Decide which event Home and the Master Panel should open by default

After valid NTE2029 fixtures were introduced, the root observed both Home and a fresh Master Panel navigation open on NTE2029 while the working edition was NTE2027. The source chooses the highest canonical event when none is requested, so F01's protection against malformed/unrelated event codes works as designed but does not establish the current edition. Staff can select NTE2027, as the root did; an unnoticed default can still put their first review in another edition. Consider preferring a configured current edition when it exists, while retaining explicit future and historical choices. The default policy is **undecided and unimplemented**; choosing a current edition also requires maintaining that setting as the event changes. Root's live browser observations and the source resolver support this finding; the report author did not independently reproduce the browser states. Evidence: PB-Q01 in [panel backend findings](../tmp/nte-stress-20260907/panel-backend-findings.md), [root UI journal](../tmp/nte-stress-20260907/root-ui-resumed-20260908.json) and [event resolver](../force-app/main/default/classes/NTE_MasterPanelController.cls). The live backend scripts explicitly pin each registered event and do not inherit this default.

### P17 — Distinguish a rejected obsolete submission from the generic thank-you redirect

Raw case `APP-PS-018` supplied the removed `Troops' Track Day Partner` value. Salesforce's actual failure notice `1a07e30da806226e` matches the exact reference, company and submitted email and states the restricted-picklist error; eight saved queries found no Lead. This is a **proven expected platform rejection before Lead creation**, not a current valid-form loss, a routing failure or an unexplained missing record. The canonical application does not offer that retired package.

The same request received HTTP 200 with a redirect to the generic page whose heading is “Submission received”. An obsolete or altered payload can therefore receive success-sounding navigation despite rejection. The raw harness did not follow/render that redirect, so this is response and page-source evidence rather than a browser-render claim. INTAKE-08 proposes more accurate outcome-aware feedback. Its design remains undecided: the existing static redirect cannot prove a Lead was accepted, and a new acceptance/status endpoint would be a separately scoped architecture change. Preserve restricted-picklist validation; do not revive the retired package or retry the submission automatically. This is distinct from P02's feedback for a retained but rejected preparation update. Evidence: [read-only investigation](../tmp/nte-stress-20260907/intake-routing-APP-PS-018.md), [matched failure/query/transport proof](../tmp/nte-stress-20260907/intake-routing-APP-PS-018.json), [actual Salesforce failure notice verification](../tmp/nte-stress-20260907/email-quality/inbox-journeys/APP-PS-018-rejection-verification.json).

## Twenty optional future features

The following U01–U20 are ranked ideas, **not approvals or implemented fixes**. They come from the separate source-grounded proposal review. Their controls are optional and should fit existing forms/records/reports without adding a compulsory applicant stage. Each retains a real dependency or tradeoff; client-dependent ideas are not presented as ready Stripe or portal work.

### U01 — Put the booking reference into preparation links

- **Situation:** An applicant opens a staff, vehicle or logo link from their booking email, then switches back to copy a long booking reference.
- **Behaviour:** Prefill only the editable booking-reference field from the personalised link. Provide a small copy control alongside the reference where useful. Direct visitors can still type it.
- **Benefit:** Removes a repeated copy/paste task and reduces unmatched supplementary submissions caused by transcription mistakes.
- **Scope/dependencies:** Small. Update the static forms, native templates and custom email link builders together. Keep the same enduring form destinations and current form-edition rules. A link fragment is a candidate carrier; verify support across the actual email paths. This must not become a public booking lookup or contact-prefill endpoint.
- **Tradeoff:** Forwarded links carry the same reference. The prefill is a convenience, not identity verification; server-side matching and validation remain necessary.
- **Grounding:** Current preparation forms require manual `Target_Booking_Reference__c`; `assets/forms.js` has no URL-prefill reader.

### U02 — Find a booking without leaving the Master Panel

- **Situation:** Someone phones with a reference or organisation name while the team is several pages into a queue.
- **Behaviour:** A compact search control finds reference, organisation or main contact within the chosen event/time/owner scope. A result opens the existing detail or record. Show the actual search scope and provide Clear.
- **Benefit:** Replaces pagination and repeated navigation through native object lists during enquiries.
- **Scope/dependencies:** Medium. Add paginated server-side search to the existing controller and panel, preserving record permissions and current ordering. A searched recipient set must also be represented in the email draft selection; never silently send to the wider unsearched queue.
- **Tradeoff:** Broad names can return several records. Large-event searches need bounded queries; a small page-only browser filter would give misleading results.
- **Grounding:** `nteMasterPanel` currently offers event, time and owner filters plus 25-row pagination, but no text search.

### U03 — Remember and bookmark a working view

- **Situation:** A finance colleague repeatedly rebuilds the same event, owner and invoice view after navigating away.
- **Behaviour:** Restore the colleague's last panel view and allow an authenticated bookmark/link containing its event, owner, stage and refiner. Keep Reset available in the existing filter area.
- **Benefit:** Avoids repeated setup and lets colleagues open the same scope during a handover.
- **Scope/dependencies:** Small to medium. Persist view preferences or route state, without including recipient addresses or unsent email content. Validate old event/owner values and use existing access permissions.
- **Tradeoff:** Remembered filters can hide newer work. Keep the active filter values visible and fall back clearly if a saved value no longer exists.
- **Grounding:** `nteMasterPanel.js` initializes `timeRange`, `ownerId` and `viewKey` afresh; it does not currently restore a work view.

### U04 — Export a badge-ready staff list

- **Situation:** A badge supplier needs one person per row, while the existing staff report contains name lists inside booking rows.
- **Behaviour:** An optional export from the existing roster produces full name, organisation, booking reference and staff category per row, with an event/date-stamped filename. Preserve full names as supplied; do not guess first/surname splits.
- **Benefit:** Removes manual splitting of multiline names and copying booking identifiers into badge sheets.
- **Scope/dependencies:** Medium. Transform the accepted base and top-up name lists and use agreed supplier columns. Retain source references and surface incomplete or ambiguous input instead of inventing names. No new attendee data entry is required.
- **Tradeoff:** Identical names can represent different people. Do not merge them automatically. Exported files contain personal data and become stale after corrections.
- **Grounding:** `NTE_04_Staff_and_Accreditation_Roster` already reports headcounts and names, but as fields on each Opportunity rather than one person per row.

### U05 — Show exactly what an accepted update changed

- **Situation:** An organiser sees that logistics were updated but must open submissions and compare several fields to understand the change.
- **Behaviour:** Store an automatic before/after summary for each accepted staff or logistics update and expose View changes on the full booking record. Show removed optional items explicitly. Rejected submissions remain separate from accepted changes.
- **Benefit:** Speeds investigations and makes replacement of an old vehicle, haulier or name list easier to spot.
- **Scope/dependencies:** Medium. Capture the submitted answers and prior accepted values before the successful staff/heavy submission Lead is deleted, and save a durable change record linked to the booking. Preserve contacts and finance, and add no automatic rollback action. This is update history, not the removed per-record Email activity dialog.
- **Tradeoff:** Detailed snapshots need storage and retention decisions. Old changes cannot be reconstructed reliably if only the latest booking values survived.
- **Grounding:** `NTEUpdateSubmissionService` records latest-update stamps and replaces the full logistics set. Successful acknowledged staff/heavy submissions are deleted; retained failed/logo submissions do not provide complete accepted-update history. A durable before/after record would be new functionality.

### U06 — Export only changes since a supplier list was produced

- **Situation:** Badge or logistics files have already been sent out when several organisations correct their details.
- **Behaviour:** Save a baseline when a staff member exports a supplier file. A later Changes since export action produces the affected bookings with previous/current values or complete replacement rows. Staff decide how to distribute the correction.
- **Benefit:** Avoids repeatedly comparing full spreadsheets and resending unchanged organisations to suppliers.
- **Scope/dependencies:** Medium, after U04 and/or U09. Store the export's event, scope and snapshot. Compare only relevant roster/logistics fields. Where individual identity is ambiguous, report the changed booking instead of inventing person-to-person matches.
- **Tradeoff:** Someone must choose the correct baseline if different suppliers received different files. Keep the export timestamp and scope visible; do not mark bookings or final packs as resent.
- **Grounding:** Current reports show current records; they do not retain the data delivered in a previous supplier export. This adds an export comparison, separate from U05's individual-submission history.

### U07 — Flag a possible second application for the same event

- **Situation:** Two colleagues from one organisation apply separately, or an applicant submits again because they missed the acknowledgement.
- **Behaviour:** On application review, show a small advisory linking plausible existing applications/bookings for the same event. The team chooses whether they are distinct bookings and still uses native conversion matching.
- **Benefit:** Helps prevent duplicate booking work, duplicate finance requests and accidental duplicate approvals.
- **Scope/dependencies:** Medium. Use conservative, explainable organisation/contact comparisons within NTE/event scope. No automatic merge, rejection, Contact overwrite or conversion block. Agree the matching rules before implementation.
- **Tradeoff:** Similar company names and shared email addresses generate false positives; separate bookings from one organisation may be valid. The advisory must remain optional and specific.
- **Grounding:** Existing duplicate rules and native conversion focus on Lead/Contact/Account matching; that is different from flagging a second NTE application or booking for the same event.

### U08 — Recover an unfinished application on the same device

- **Situation:** An applicant loses progress on a long application after a refresh or interruption.
- **Behaviour:** Offer Save draft on this device and Restore draft, with automatic expiry and a clear discard option. Restore answers only into the same form edition; declarations, agreement ticks and signature dates must be completed again.
- **Benefit:** Reduces repeated typing and abandonment without requiring an account or portal.
- **Scope/dependencies:** Small to medium. Browser storage only, no server-side profile. Decide a short retention period and exclude sensitive free-text answers where appropriate. Revalidate current selections and prices when restoring.
- **Tradeoff:** A shared device can expose saved answers; storage can also be cleared by the browser. Make saving optional and describe its device-only nature once at the control.
- **Grounding:** `assets/forms.js` currently has no saved-draft storage. Existing form validation does not preserve work across a fresh load.

### U09 — Produce a gate-ready vehicle manifest

- **Situation:** The gate team needs to look up an individual arriving vehicle, but the current logistics export spreads three exhibited items and a haulier across a wide booking row.
- **Behaviour:** Export one exhibited item or haulier vehicle per row, grouped by the recorded delivery window, with registration, dimensions, weight, organisation, booking reference and the separately identified operational contact.
- **Benefit:** Makes the gate list easier to search and print without manually reshaping the existing report.
- **Scope/dependencies:** Medium. Transform the current fixed item fields and haulier fields into a compact export using existing delivery-window choices. Keep unknown registrations visible. Do not allocate slots or imply that a window reserves capacity.
- **Tradeoff:** Haulier and exhibit records can refer to related equipment; label their roles to avoid double-counting arrivals. A printed manifest becomes stale after replacements.
- **Grounding:** `NTE_05_Heavy_Vehicles_and_Logistics` already includes all relevant fields, but as a wide Opportunity report.

### U10 — Keep external invoice and payment references against the correct charge

- **Situation:** Finance can see that an invoice or payment was recorded but must search another system to locate the corresponding document or bank entry.
- **Behaviour:** Add optional external invoice/payment references against Booking and Staff top-up separately, available in their existing milestone workflow and full record. Existing file attachments can be linked to the relevant charge evidence.
- **Benefit:** Speeds reconciliation and reduces confusion between the original booking invoice and the single top-up invoice.
- **Scope/dependencies:** Small to medium. Add separate optional reference fields and report columns; preserve the current milestone dates/users and order. Accept references from the existing finance process without generating numbers or integrating Stripe.
- **Tradeoff:** Optional fields may be blank or mistyped, so references supplement rather than prove payment. They must not introduce a new compulsory finance step.
- **Grounding:** The package keeps separate booking/top-up flags, amounts and audit stamps, and already has PO fields; no dedicated external invoice/payment references were found.

### U11 — Copy the details finance needs for an invoice

- **Situation:** Staff preparing a manual invoice retype billing addresses, PO information and fixed-price items from several booking fields.
- **Behaviour:** A Copy invoice details action in the relevant finance context copies the saved billing details, booking reference and the applicable Booking or Staff top-up line items in a clean format.
- **Benefit:** Reduces copying errors while the existing external invoice process remains in use.
- **Scope/dependencies:** Small. Use saved fixed-price facts and explicit net-price labels; do not calculate unsettled tax, generate an invoice number, send an email or mark Invoice provided merely because someone copied text. Block an unpriced handoff.
- **Tradeoff:** The copied content can become stale, and the receiving finance system still applies the agreed tax/document rules. Keep output limited to what that process actually needs.
- **Grounding:** Billing/PO fields and separated charge amounts already exist; the panel currently exposes milestones and a cross-event report rather than a formatted copy action.

### U12 — Save an unsent mass-email draft

- **Situation:** A team member edits a reminder or invitation and gets interrupted before completing recipient review.
- **Behaviour:** An optional Save draft action preserves the message and intended selection for later reopening. On restore, rebuild eligibility and personalised previews; show changed or ineligible recipients before deliberate send.
- **Benefit:** Prevents lost writing and repeated selection work without automating communications.
- **Scope/dependencies:** Medium. Add durable draft storage to the existing composer/dispatch service. A saved draft must remain distinct from a queued send, and no saved preview can be treated as current approval to send.
- **Tradeoff:** Old drafts can contain outdated instructions or selections. Expiry and refreshed previews add some maintenance; recipient checks must remain at send time.
- **Grounding:** `nteMasterPanel.js` holds composer state in memory; existing durable dispatch records represent email requests/outcomes, not resumable unsent editorial drafts.

### U13 — Link an invitation to the application it produces

- **Situation:** The team wants to see which interests progressed into applications rather than comparing names across separate queues.
- **Behaviour:** Personalised invitations carry a non-authorising source token. A resulting application records that invitation/interest as its source and can be traced through conversion; direct applications remain direct.
- **Benefit:** Removes manual journey matching and supports useful source-to-application reporting using the existing reports.
- **Scope/dependencies:** Medium. Add source-token handling and a durable relationship. It must not grant access, bypass the human decision, identify the form submitter as the original invitee, or change the edition selected by the enduring application form.
- **Tradeoff:** A forwarded invitation describes the link's origin, not necessarily the applicant's identity. Do not label attribution as proof of identity or retrospectively guess historical links.
- **Grounding:** Current fields record form type, event and conversion classification; the invitation route marks the interest Progressed but no direct invitation-to-submitted-application relationship was found.

### U14 — Let applicants keep a copy of their answers

- **Situation:** An applicant needs their submitted name list or logistics details for a colleague and has no convenient copy.
- **Behaviour:** Offer an optional Download answers or print-friendly copy using the answers in the browser, including the booking reference, form edition and preparation timestamp.
- **Benefit:** Avoids screenshots and reconstructing complex answers when the applicant later needs to make a correction.
- **Scope/dependencies:** Small to medium. Use a recipient-focused print/download layout alongside the existing submission. Clearly label it a copy of answers; a static browser cannot certify Salesforce acceptance, so do not present it as an accepted booking or update receipt.
- **Tradeoff:** The downloaded file can contain personal details and later become outdated. It should contain only the applicant's answers, not internal processing notes or a fabricated success result.
- **Grounding:** Current forms show acknowledgements/previews but have no dedicated print/download answer copy. U08 saves an unfinished form; this creates a portable copy for the applicant.

### U15 — Record the exact terms edition attached to an application

- **Situation:** The annual terms document changes and the team needs to establish which configured edition accompanied an older application.
- **Behaviour:** Store a recognised terms-document version and stable document reference alongside the existing agreement, signature/date and form version, and retain that association on conversion.
- **Benefit:** Removes manual reconstruction from annual website changes and keeps the applicable document easier to retrieve.
- **Scope/dependencies:** Medium. **Client dependency:** the final terms document, its versioning owner and an archive/reference convention. Map permitted document versions through maintained configuration; preserve historical associations.
- **Tradeoff:** Someone must retain and version documents reliably. This records the configured document associated with the form; it does not prove that someone read it or make a legal conclusion.
- **Grounding:** The application stores agreement and form-version information and uses a configured terms URL, but no dedicated immutable terms-document version was found.

### U16 — Open the actual logo from the booking

- **Situation:** A booking says its logo was supplied, but marketing must still find the right file in the upload folder.
- **Behaviour:** Associate the received asset's stable file reference, filename and version with the booking, with an optional preview/Open logo action on the full record.
- **Benefit:** Reduces folder searches and use of an older organisation logo.
- **Scope/dependencies:** Medium. **Client dependency:** the final SharePoint destination, file-access permissions and a reliable method of associating an actual upload with its booking. Keep the existing completion rule unchanged unless separately approved; a thumbnail is not a new approval gate.
- **Tradeoff:** File links or permissions can change, and filenames alone can misidentify an organisation. Do not automatically attach a guessed match or claim a file exists from the current self-declaration alone.
- **Grounding:** `logo-upload.html` separates upload and confirmation; current processing records the provided flag/time without associating a specific uploaded asset.

### U17 — Add the event to a calendar from the final pack

- **Situation:** Attendees manually transcribe the venue and arrival time from final instructions into their calendars.
- **Behaviour:** Include an optional Add to calendar link in the existing final-pack email, using official event details and, where appropriate, the booking's applicable arrival information.
- **Benefit:** Reduces date, time and location transcription errors and makes the event easier to find on the day.
- **Scope/dependencies:** Small to medium. **Client dependency:** approved event start/end time, venue and final-pack content. Generate a standards-based calendar file with the intended timezone and stable event identity. No extra email or calendar-account connection is needed.
- **Tradeoff:** Downloaded calendar entries may not update automatically when plans change. Revisions need a defined update approach and cannot be assumed to reach every calendar.
- **Grounding:** Final-pack distribution exists, while its final content is awaited; no calendar-file feature is present.

### U18 — Track final-pack versions separately

- **Situation:** Instructions change after the first pack was sent and the team needs to know who received which revision.
- **Behaviour:** Give each event/participant pack an explicit version; save that version on every dispatch. Staff can deliberately prepare a revised version for a reviewed recipient set while previous send history remains intact.
- **Benefit:** Makes corrected-pack distribution and questions about received instructions easier to resolve.
- **Scope/dependencies:** Medium. **Policy decision required:** approve versioned packs, who releases a revision, and eligibility for corrected packs when a previously completed booking later reopens finance. Preserve duplicate prevention within each version and keep ordinary late-completer sending separate.
- **Tradeoff:** Versioning adds content administration and can encourage unnecessary resends if release ownership is unclear. Nothing should automatically resend when a file at a URL changes.
- **Grounding:** The desired workflow explicitly treats separately versioned packs as optional future work; current sent/queued history and explicit corrected resends are not themselves version tracking.

### U19 — Generate the agreed financial PDF from saved booking facts

- **Situation:** The team needs a consistent downloadable quote/invoice document without rebuilding the booking's itemisation elsewhere.
- **Behaviour:** Generate and retain a versioned PDF for the selected Booking or Staff top-up charge, preview it, and use the existing recipient and milestone workflow when it is deliberately issued.
- **Benefit:** Reduces document assembly and disagreement between the saved booking amounts and the document sent.
- **Scope/dependencies:** Medium to large. **Policy/client decisions required:** seller details, VAT treatment, quote/invoice/proforma designation, numbering, revision rules and document ownership if Stripe Invoicing is later chosen. Native PDF feasibility has been checked, but document generation is not implemented or approved. Fixed-price facts only; no revived manual-price feature.
- **Tradeoff:** Financial documents create lasting numbering and correction obligations. This is not a ready Stripe integration and must not accidentally issue a second formal invoice alongside another system.
- **Grounding:** `NTE_DESIRED_WORKFLOW.md` records the read-only native PDF check and explicitly leaves document generation as future work; proposal 11 still holds the relevant finance decisions.

### U20 — Let an applicant resolve “vehicles not known yet” as “none”

- **Situation:** An organisation originally did not know whether it would bring heavy equipment, then confirms it will bring none. The current form requires an item, so staff must handle the change.
- **Behaviour:** Offer a short No vehicles or heavy equipment answer that resolves the booking's unknown requirement using the same booking-reference matching. It would not require fictitious item or haulier details.
- **Benefit:** Removes a support exchange and an outstanding-logistics item for applicants with nothing to declare.
- **Scope/dependencies:** Small to medium. **Policy decision required:** the desired workflow explicitly leaves this self-service route undecided. The initial proposal is restricted to unknown → not required with no existing accepted item details; clearing previously declared vehicles needs its own explicit decision. Preserve contact and finance facts.
- **Tradeoff:** An incorrect “none” answer affects event planning. Keep an auditable explicit declaration and do not silently interpret an empty vehicle submission as “none”.
- **Grounding:** `heavy-vehicle-details.html` requires Item 1; `applyHeavyFields` sets the requirement to Yes. This is a new choice, not an existing form defect.

## Finding cross-reference and release record

The mappings below preserve the local findings even where one failure was independently found in several domains. Normal passing cases and explicit testing limitations remain in each linked domain report.

| Domain report | Local findings represented here |
| --- | --- |
| [Catalogue](../tmp/nte-stress-20260907/catalog-findings.md) | Planned counts/coverage table; CHK-01/02 → F16; DEC-01/03/04 → P12; DEC-02 → P03; DEP-01/02/03 → P13. |
| [Form engine](../tmp/nte-stress-20260907/form-engine-findings.md) | FORM-01 → F02; 02/07 → F03; 03/10 → F04; 04/05/06 → F05; 08/09 → F06; 11/13 → F28 and F01; 12 → F09; midnight follow-up 14 → F33. Remaining raw payload/transport/Unicode limits → P14/P15. |
| [Exhibitor browser](../tmp/nte-stress-20260907/forms-browser-exhibitor-findings.md) | FB-EX-01 → F04; 02 → F02; 03 → F05; price/branch/responsive checks → coverage and F03/F06; early preparation link → F09. |
| [Other-form browser](../tmp/nte-stress-20260907/forms-browser-other-findings.md) | FBO-01 → F02; 02 → F28; 03/04 → F04; normal/alternate/mobile paths → coverage; rejection/consent/logo/tool boundaries → P02/P12/P13/P15. |
| [Pricing](../tmp/nte-stress-20260907/pricing-findings.md) | PR-1/4/5 → F06; 2/3 → F07; maintenance save-result limitation → P14. |
| [Conversion](../tmp/nte-stress-20260907/conversion-findings.md) | C01 → F08; C02 → F19; C03 → F02; C04 → F27; C05 → F18; stale pricing → F07; immediate payment decision → scope; native options → P03; later provisional retry → P01. |
| [Intake](../tmp/nte-stress-20260907/intake-routing-findings.md) | INTAKE-01 → F10; 02/04/06 → F11; 03 → F12; 05 → F13; 07 → F14; 08 / APP-PS-018 matched platform rejection → P17 and live-intake evidence; recovery UI → P07. |
| [Supplementary](../tmp/nte-stress-20260907/supplementary-findings.md) | SUPP-01/05 → F15; 02 → F10; 03/06 → F16; 04 → F05; closed-booking policy → scope; >100 receipts → P05; historic identity → P08; rejection feedback → P02; remaining DML/coercion limits → P14. |
| [Dispatch/contact](../tmp/nte-stress-20260907/dispatch-findings.md) | DSP-1 → F29; 2/5 → F17; 3 → F18; 4/7 → F19; 6 → F20; 8 → F02; 9 → F32/P05. |
| [Email quality](../tmp/nte-stress-20260907/email-quality-findings.md) | EQ-1 → F20; 2/3 → F18; 4 → F02; received-logo follow-up EQ-5 → F31; other remaining observations → P11/P13/P15. |
| [Panel backend](../tmp/nte-stress-20260907/panel-backend-findings.md) | PB-01/02 → F21; 03/08 → F23; 04 → F24; 05 → F25; 06 → F26; 07 → F01; PB-Q01 current-edition default → P16; historical zero → P04; volume limits → P05/P06; allocated native-conversion phase → live-step evidence. |
| [Panel UI](../tmp/nte-stress-20260907/panel-ui-findings.md) | UI-01/03/04/06/15 → F26; 02 → F25; 05/07/08 → F27; 09/17 → F21; 10/11/12/13/14 → F28; 16 → F24; absent live UI evidence → P15. |
| [Metadata/reports](../tmp/nte-stress-20260907/metadata-findings.md) | META-01/02/04 → F22; 03 → F24; 05/07 → F23/F24; 06 → F30; coordinated rules/Flow/identity/tokens → F01/F07/F10/F15/F18; retirement/export/history/validation limits → P04/P09/P10/P15. |
| [Input integrity](../tmp/nte-stress-20260907/input_integrity-findings.md) | II-01 → F01; 02 → F02; 03 → F10; established nonfindings retained as limits in scope/P10/P14/P15. |

### Release evidence and final qualification

| Release fact | Verified result or scope boundary |
| --- | --- |
| Final source freeze, generated manifest and source hashes | All 423 component members and 484 canonical source paths reconcile; all 46 external-dependency fields are included. Final before/after/inventory hashes match across all 485 source/manifest entries at 10:16:55 UTC, including all 48 reviewed F34 files. Aggregate SHA256 `c128cbb66de6d6cc52625cadfc606a58e11f8fdb4d8fdf0d38037cad5e9adb77`. The earlier pre-F34 capture remains separately preserved. |
| Final local/generated test results | Form engine 123/123 checks and 34,986 combinations, including 24 midnight before-fail/after-pass checks; other recorded domain checks above. Final source reconciliation matches the reviewed deployed bytes. |
| MMUAT deployment ID, component result and actual Apex result | **`0AfAd00000SpIFhKAN` Succeeded: 423/423 components, 278/278 tests, zero errors**, completed `2026-09-07T23:05:33Z`; actual deployment, not check-only. Final counters supersede the earlier progress display. |
| Pre-F34 production-manifest check-only | **`0AfAd00000SpYyoKAF` Succeeded: 423/423 components, 278/278 RunLocalTests, zero errors**, completed 09:11:39 UTC, with its own before/after hashes matched. The initial CLI wait timed out; the same job was polled to success without resubmission. This is the pre-F34 qualification, not a deployment or validation of later changes. |
| Final combined production-manifest check-only | **`0AfAd00000Spkn3KAB` Succeeded: 423/423 components, 281/281 RunLocalTests, zero errors**, completed 10:14:56 UTC. All source and reviewed patch hashes match the final inventory. This is qualification of the combined sandbox source after F34's actual release, not a production deployment or another actual full-package release. |
| F34 email correction release | Corrected actual deployment **`0AfAd00000SpkOrKAJ` succeeded at 10:04:43 UTC: 15/15 components, 24/24 complete-class tests, zero errors**, including all three new stored-template methods. Local 311/311 contracts and 39/39 additional parity assertions pass; 21 normal examples remain byte-identical. The first attempt `0AfAd00000SpiOfKAJ` failed/rolled back at 23/24; the native newline issue was corrected without weakening its parity test. Its 14 maintained HTML sources are published, byte-verified and included in the successful final combined qualification. |
| Native volunteer auto-response correction and one-receipt live result | Entry five formula FALSE saved/retrieved, first four unchanged. Post-fix `VOL-002`, James Walsh / Lead `00QAd00000URPXJMA5`: exactly one applicant receipt `1a07e20f3ae4af95`, zero native email Tasks. |
| Allocated direct HTTP intake outcomes | Completed phase: 74 POST attempts, 73 correlated Leads, one exact obsolete-package platform rejection, no unknown outcomes. Includes two retained pricing-review holds and three safely rejected unmatched updates. Recorded NTE audit acceptances are 64 applicant + 64 internal; volunteer audit acceptances are six applicant + six internal. These are not delivery counts. |
| Bulk booking and preparation completion | 34 intended valid bulk conversions, £212,397 base value, 33 paid bases plus one complimentary; 70/70 normal Applied updates and actual all-34 Complete assertion before edges. Subsequent 28 edge/restoration POSTs settled as 23 Applied/five expected rejections. All 98 preservation guards passed, zero POST retries/unknown outcomes. Three paid top-ups total £5,100. Final affected-four readbacks and the deployed all-34 Completed controller reconciliation passed with correct Primary Contacts/amounts and no finance actions remaining. |
| Invitations, final packs and post-pack top-up | 16 bulk invitations Sent/progressed, zero retries. Initial two packs plus one late completer Sent, with zero queued by both immediate repeat requests. Restoration deployment `0AfAd00000SpdGvKAJ` succeeded 08:58:42 UTC; exact original routing and zero globally queued packs verified again 09:38:17 UTC. EX002's later £50 top-up reopened then completed finance without changing its pack or base confirmation history. Reserved recipient/URL use does not establish delivered real client pack content. |
| Representative workflows | The three root bookings and Fenmere separately pass the actual Completed calculation. Their final-pack fields are empty; the three tested packs belong to the separate bulk group. All logo entries in this audit are simulated declarations, not file uploads. |
| Final native Home and Master Panel | Actual NTE2027 Master: 38/38 Complete, zero preparation/finance work outstanding, 35 packs not sent/three sent. Actual Home: £249,347 approved/invoiced/paid, 38 approved/36 paid, zero still to collect; four pending applications total £2,800. Global NTE2027 figures include root/protected bookings and remain separate from the £217,497 two-event bulk total. The final desktop screenshot was inspected at 1082 × 911; no modal or viewport override remains. |
| Final original-case coverage | All 140 original cases retained: 110 live-submission observations, 14 browser-scenario-only, ten local-source-only and six without an exact execution mapping. The latter include two exact live gaps and four unbound representative preparation fixture IDs. Recorded original-case conversions total 37. Seventy-four additional indexed form cases remain outside the denominator; three further root action observations are unbound. |
| Actual controlled-inbox evidence | Original MIME verifies 24 messages for the three root application journeys plus three Fenmere lifecycle messages. The two EOI invitations, guest messages, pre/post-fix volunteer cases and APP-PS-018 platform failure remain separately counted. A 00:09:04 UTC bounded search finds exactly one booking-payment confirmation per paid representative, none for complimentary Willowbridge, and no extra confirmation after Harbour top-up payment. Final wider totals remain root-owned. |
| Protected Anthrion/legacy preservation reconciliation | Final stable-state check confirms unchanged populations/audit timestamps for all 2,057 retained pre-run rows (664 Accounts, 757 Contacts, 537 Leads, 99 Opportunities). All 103 protected walkthrough comparisons match; its £800 + £50 booking remains paid/Complete with no new dispatch or Task. Available retained records/snapshots are covered; a complete historical backup or hard-deletion recovery is not claimed. |
| Native report and export qualification | All nine final report memberships, definitions and aggregates reconcile: 12,301 full-cell matches plus 13 explained long-text prefixes, zero unexplained differences. All 205 repeated Primary Contact ID/name checks and 42 finance/pricing helper rows match. Fresh native Details Only CSV passes 2,080/2,080 source-cell checks and preserves full 99/101-name rosters. Earlier benign XLSX values are explicit text. The owner declined further work on the separately observed CSV prefix case; no formula execution or setting change occurred. |
| Canonical preview commit and hosted verification | **`8d1f7c19f4f18f73905147669e7a9147ed62d14c`**, `stevostar1234/nte27-web-to-lead-demo`; 59/59 root/clone/HTTPS-served files byte-verified at 10:13:01 UTC. F34 changes 14 maintained email sources; 21 normal examples are unchanged. Form asset remains `20260908-1`. Broader browser acceptance is not inferred from byte agreement. |
| Mission Motorsport logo correction | True opaque 1500 × 767 RGB PNG; zero changed visible pixels on white. James's received message uses `20260907-png`; exact hosted PNG/hash/clear artwork verified. Direct broad Gmail/Outlook UI coverage is not claimed. |
| London midnight form follow-up | F33 published in the current website release; 24 targeted failures before / 24 passes after across BST/GMT and all ten forms, with entered dates preserved. |
| Production Salesforce release / future NTE production hosting | Not authorised by this stress report. |

The [final combined qualification](../tmp/nte-stress-20260907/metadata-f34-v2-qualification-20260908/summary.json), [pre-F34 qualification record](../tmp/nte-stress-20260907/metadata-final-qualification-20260908/RESULT.md), [source inventory](../tmp/nte-stress-20260907/metadata-package-inventory.md), [final report/export/preservation result](../tmp/nte-stress-20260907/metadata-final-reconciliation-20260908/RESULT.md), [final publication](../tmp/nte-stress-20260907/f34-website-release.json) and immutable domain results supply the release detail. The preserved `tmp/nte-stress-20260907/source-before/` snapshot and domain-specific patches/hashes distinguish this run from unrelated earlier working-tree changes. This report makes no claim to exhaust every possible form value, stored history, concurrent transaction, browser, delivery provider or event volume.

## Saved completion state

The [root resume record](../NTE_AUDIT_RESUME.md) and final domain checkpoints preserve the completed run. The early pause's pack and native-conversion work has finished and is consolidated above. Do not replay successful invitations, forms, finance actions or packs from historical commands. Begin future work from these results and the user's subsequent policy selections.

The audit is complete for its recorded scope, with no execution or release work remaining in this run. Deployment and canonical publication, final combined qualification, allocated form/finance sequences, bulk/native panel reconciliation, combined coverage, final reports, full-roster CSV and protected-record checks are settled. Preserve the normal-34 Complete snapshot alongside the later successful finance-reopening checks; an expected temporary move back into finance does not erase the earlier passing baseline. Open policy choices, client assets and unproved dimensions remain explicitly numbered above; they are not silently approved or represented as passing tests.
