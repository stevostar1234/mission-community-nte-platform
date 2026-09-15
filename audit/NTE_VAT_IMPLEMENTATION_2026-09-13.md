# NTE VAT implementation — 13 September 2026

Proposal 21 is implemented in MMUAT and published on the canonical client preview. The client’s clarified rule is 20% VAT added to payable net NTE prices, after discounts. Package and item prices remain net; the total section displays one aggregate VAT amount and the total including VAT. For example, a £599 garage shows **£599.00 + £119.80 VAT**, with **£718.80 total including VAT**.

## Released behaviour

| Area | Result |
| --- | --- |
| Forms | Exhibitor application, partner/sponsor application and exhibitor staff top-up show the net subtotal, one VAT amount and gross total. Package/space/socket/staff prices remain net. Complimentary benefits remain visible; chargeable extras still attract VAT. The 50% space/power saving includes the VAT saving. |
| Pricing | config/nte-pricing.json sets version NTE27-2026-09-13-VAT and vatRate 20. scripts/build-vat.js generates the shared NTEVat policy and browser rate/version. GBP VAT rounds HALF_UP to pence once per separate charge. Unknown pricing stays unknown; free charges remain zero. |
| Salesforce | Eleven new Lead/Opportunity VAT fields store or calculate saved rate, VAT and gross totals. Application-derived amounts are recalculated server-side. Native conversion freshly prices the application and sets Opportunity Amount to the gross base booking. Component/catalogue prices remain net. Dynamic Forms, access and list views include the new fields. |
| Finance and reporting | Home, Master Panel, finance queues and confirmed value use gross charge amounts. Each base charge and top-up contributes once. Monetary reports expose net/VAT/gross columns and totals; existing filters and milestone timing are unchanged. |
| Emails | Internal application, all booking provisional/paid/complimentary variations, and exhibitor staff/top-up acknowledgement show the applicable net/VAT/gross amounts. The selected package names and existing client prose remain. Actual Salesforce HTML and plain text were checked, as well as real received messages. |
| Stripe | The fixed GBP Price contains the gross amount once. Checkout discloses the saved net subtotal, VAT and gross total. Payment Link and PaymentIntent metadata include net/VAT minor units and rate. The adapter verifies them before email eligibility. Automatic tax and invoice creation remain disabled. |
| Staff top-ups | The first accepted top-up saves its own rate and net price. It is calculated and invoiced separately; names-only corrections preserve accepted quantity, rate and finance facts. Original booking Amount and base payment are unchanged. |

The existing NTE Management Access group is Updated and gives Kate Lole and Tony Radford readable access to all 11 new VAT fields. Their assignments and profiles were not changed.

## Qualification

- Core actual MMUAT release **0AfAd00000SuQSjKAN**: 487 components, 318 tests, zero errors.
- Stripe disclosure actual release **0AfAd00000SuQXZKA3**: four Apex components, 26 affected tests, zero errors.
- Final complete-manifest check-only **0AfAd00000SuQanKAF**: **487 components, 318 RunLocalTests, zero errors**.
- All **553 canonical source/manifest hashes** and 487 component identities reconcile. Aggregate SHA256 `e3761746d633a8f5a412f05207e89b558fa4bce7fb9782ae89126423bf43e9f6`. All 20 changed native Apex class bodies match source. Later edits affect internal documentation only.
- `npm run validate` passes after final regeneration and priced-form cache-version checks. Covered cases include discounts before VAT, rounding, complimentary zeros, invalid pricing, caller-supplied totals, saved rates, separately rounded top-ups and repeated calculation without extra VAT.
- All 17 supplementary submissions applied: ten temporary staff/vehicle audit Leads were deleted by the existing successful-update workflow; seven logo audit Leads remain. No unknown submission outcomes or replays.
- **21 native email renders** pass HTML/plain-text checks: 18 booking/internal variants and three staff-top-up totals. Native render checks sent no emails; temporary staff contexts were rolled back.
- **35 actual received messages** were verified: 15 provisional/complimentary, nine paid confirmations, ten staff/vehicle acknowledgements and one internal partner notification. The 31 messages containing prices pass net/VAT/gross checks in HTML and plain text; the other four have no financial section. No unresolved merge tokens or doubled currency symbols. No queued, sending or failed dispatches remain.
- Browser presentation checks cover standard and discounted exhibitor totals, complimentary benefits, combined partner packages and the published staff top-up. A requested small viewport was ignored by the in-app browser; this run does not claim a new mobile-width check. Local form calculations and hosted byte parity are separately verified.

### Native reports

All nine maintained NTE reports match their deployed definitions, intended records, source currency values and applicable grouped/grand totals. **817 currency cells** reconcile.

| Report | Rows | Currency cells checked | Result |
| --- | ---: | ---: | --- |
| NTE 01 Guest Check In and Accessibility | 0 | 0 | Passed |
| NTE 02 Partner Sponsor Event Operations | 6 | 66 | Passed |
| NTE 03 Exhibitor Event Operations | 9 | 117 | Passed |
| NTE 04 Staff and Accreditation Roster | 15 | 60 | Passed |
| NTE 05 Heavy Vehicles and Logistics | 3 | 0 | Passed |
| NTE 06 Finance and Invoicing | 13 | 182 | Passed |
| NTE 07 Application and EOI Pipeline | 10 | 90 | Passed |
| NTE 08 Event Delivery Readiness | 15 | 120 | Passed |
| NTE 09 Weekly Finance Report | 13 | 182 | Passed |

The older report named NTE27 was also inspected. It contains Lead identity/contact fields and RowCount, with no price or monetary columns; no VAT edit was applicable.

## Replacement examples and cleanup

The [record directory](NTE_VAT_TEST_RECORDS_2026-09-13.md) contains 25 fictional examples, five each at interest, application review, finance outstanding, finance-settled/preparation-outstanding and completed positions. All applicant addresses use the owner’s Anthrion email. Fifteen native conversions created 15 new Accounts, 15 Contacts and 15 Opportunities with the normal Primary Contact relationship.

The owner authorised replacing the existing dummy population. Exact backed-up, recoverable deletion removed **154 proven dummy Leads, 54 dummy Opportunities, nine old payment-request rows and 67 old email-dispatch rows**. This includes two older yearless bookings independently identified by their linked `.example` applicant addresses. All nine retired Stripe test links are now inactive (three were newly deactivated; six were already inactive). Historical Stripe payments, refunds and disputes remain provider history; none was deleted or replayed.

Preservation checks confirm **249 unrelated Leads, all 728 pre-existing Accounts and all 819 pre-existing Contacts** are unchanged, including their LastModifiedDate values. No production data was touched. Existing accounts/contacts are retained because they can support other Mission Community records; only exact proven NTE fixture Leads/bookings/history were selected for cleanup.

### Test money and workflow results

The converted group, including two later staff top-ups, reconciles to **£49,993.50 net + £9,998.70 VAT = £59,992.20**. Invoiced gross is £41,033.40; paid gross is £32,094.60; outstanding gross is £27,897.60. The five unconverted applications total £18,178.20 including VAT. Home rounds its headline display to pounds; stored fields and reports retain pence.

Four new Stripe links were created and verified in the owner-controlled test account `acct_1UD8GwBcW1MkMYQ1`. U03 and C03 completed one simulated card payment each, for **£2,400 and £12,000**. Exact successful Session, PaymentIntent and captured Charge amounts, metadata, mode and automatic used-link closure were checked. The manual Salesforce payment action then produced one confirmation each. No real money moved. F03 and F04 remain active/unpaid for client testing, at £1,558.80 and £7,200. A03/A04 remain unconverted with Stripe selected for a fresh conversion demo. Bank-transfer milestones are simulated, not actual bank transfers.

The five example groups are disjoint purposes; existing app views overlap. The final counters are Interest 5, Applications 5, Approved 15, Finances 13, Updates 10 and Completed 5. The five finance-outstanding examples comprise one quote, one invoice and three payments, including the separate unpaid top-up.

## Preview publication

Canonical repository: `stevostar1234/nte27-web-to-lead-demo`. Published main commit **b144063b4546f1294e068dd554ef24ce0bd0d12a**, prepared from current remote **f55cdf2b761ee36af057f768dcd3bdc7224543a2**, contains only the 20 intended website files. All 20 hosted files return successfully and exactly match local SHA256 hashes. The three priced forms request forms.js and styles.css revision `20260913-vat`; unrelated forms retain their prior cache versions. The recipient-copy scan has zero reviewer/developer/testing commentary findings.

[Exhibitor form](https://stevostar1234.github.io/nte27-web-to-lead-demo/exhibitor-application.html), [partner/sponsor form](https://stevostar1234.github.io/nte27-web-to-lead-demo/partner-sponsor-application.html), [exhibitor staff form](https://stevostar1234.github.io/nte27-web-to-lead-demo/exhibitor-staff-update.html).

## Scope and release limits

This is a VAT release to the existing implementation. Manual payment confirmation, client email timing, one-time top-up limits, current cancellation/refund behaviour and changed-price request validation remain as selected. No Stripe app/Flow replacement or automatic payment reconciliation is introduced. The 20% calculation is the confirmed single-rate policy; different future exemptions or item-specific rates would need an approved policy update.

The Stripe disclosure and saved metadata do **not** generate formal VAT invoices or Stripe Tax accounting entries. Stripe invoice creation remains excluded by the existing Payment Links-only decision. The client’s separate financial-document process, client merchant credentials/configuration and qualification, and authorised production deployment remain launch work. There is no unresolved VAT implementation or sandbox workflow defect identified by these checks; finite testing cannot establish every future configuration.

Current workflow, deployment, finance, field, Flow and configuration Markdown references are updated. Previously dated Word/PDF exports, source archives and historical audit reports remain evidence of their own release. Production is not deployed and no live key/account has been activated by this task.

## Evidence and repeat-run controls

[Machine-readable qualification](NTE_VAT_QUALIFICATION_2026-09-13.json) retains exact source/member hashes, deployment identities, record directory, report results, Stripe verification, preservation and access summaries, publication digests and private evidence-file hashes. Raw record snapshots, messages and request ledgers remain under ignored `tmp/nte-vat-20260913/`; credentials are not exported.

Earlier diagnostic jobs `0AfAd00000SuQHRKA3` and `0AfAd00000SuQKfKAN` identified compile/query/old-net-expectation issues. Actual attempt `0AfAd00000SuQMHKA3` rolled back after one stale email assertion. The first Stripe-disclosure attempt `0AfAd00000SuQULKA3` had a test-fixture compile error. All were corrected before the successful releases; their failed evidence is retained and is not relabelled as a pass. A read-only preservation query exceeded the request-header limit and was safely repeated in bounded batches; a verifier expectation was corrected to distinguish 15 Opportunity-audited approval emails from nine payment dispatch records.

All submission, conversion, cleanup, payment and send attempts have settled evidence. **Do not replay any completed ledger or repay U03/C03.** Fresh client demonstrations can use the explicitly unpaid/unconverted examples in the directory.
