# Representative NTE journey journal — 8 September 2026

**Internal evidence journal; the overall stress run remains in progress.** Harbour Cedar Engineering, Cedarhaven Mobility, Willowbridge Community Trust and Fenmere Robotics pass the deployed Completed preparation calculation. This does not mean a final pack was sent, a live invoice or Stripe charge was issued, or the wider catalogue is finished. The three root bookings retain Stage = Qualification and empty final-pack fields. All four logo confirmations were simulated attestations while the client upload destination is pending.

The [machine-readable companion](NTE_REPRESENTATIVE_JOURNEY_JOURNAL_2026-09-08.json) retains exact case IDs and evidence paths for coverage reconciliation. Willowbridge is catalogue `APP-EX-003`; `APP-COMP-001` is only its inbox-ledger alias. Fenmere and its two preparation entries are an extension outside the original 140-case catalogue, not additional catalogue passes.

## Identity and completion

| Canonical case | Booking and reference | Exact Contact | Result |
| --- | --- | --- | --- |
| APP-EX-001 — Harbour Cedar Engineering | `006Ad00000UdfWoIAJ`; `NTE-1788822910579-35U6ZJ84` | Amelia Hartley `003Ad000019n4GsIAI` | £800 original booking plus a separately invoiced/paid £50 top-up; three staff; no heavy vehicles; logo attestation; Completed |
| APP-PS-001 — Cedarhaven Mobility | `006Ad00000UdkWUIAZ`; `NTE-1788823250468-2JEPYTTC` | Oliver Ashford `003Ad000019nCcOIAU` | £30,000 Headline Partner; quote, invoice and payment recorded; three staff without a new staff charge; replacement logistics; logo attestation; Completed |
| APP-EX-003 — Willowbridge Community Trust | `006Ad00000UdoYLIAZ`; `NTE-1788823353859-UTYWAC2X` | Eleanor Whitcombe `003Ad000019nUQfIAM` | £0 complimentary booking; two staff; no heavy vehicles; logo attestation; Completed without inventing payment |
| CNV-LIVE-001 — Fenmere Robotics | `006Ad00000Ude5zIAB`; `NTE-1788824303908-EC562TQM` | Leonie Asquith `003Ad000019nIwAIAU` | £800 space + £100 power + £50 original staff = £950; invoice/payment recorded; three covered names; no new top-up; no heavy vehicles; logo attestation; active and Completed |

Root's [final assertion script](../tmp/nte-stress-20260907/root-representatives-final.apex) calls the deployed `isComplete` calculation for all three root bookings and verifies the three exact Primary Contact roles. Its [execution succeeded](../tmp/nte-stress-20260907/root-representatives-final.raw.json); the [saved records](../tmp/nte-stress-20260907/root-representatives-final.json) report zero DML and zero email invocations. Fenmere's [completed lifecycle result](../tmp/nte-stress-20260907/conversion-live-001/lifecycle-02/lifecycle-result.json) and [independent final check](../tmp/nte-stress-20260907/conversion-live-001/lifecycle-02/04-completed-captured/result.json) separately prove its active/Completed state with no extra sends. These are live read-only backend assertions, not new isolated deployment tests or an invented visual panel check.

## Methods kept separate

| Method | Bounded evidence in this journal |
| --- | --- |
| Browser public intake | Eight journal entries: two EOI submissions, the three root applications, guest registration, post-fix volunteer James and Fenmere's application. Four are booking applications. Their later changes are not counted as new applications. |
| Native Salesforce UI conversion | Three successful root representative conversions; the earlier complimentary Cancel left its Lead unconverted/no Opportunity at that snapshot. A fourth native conversion, APP-EX-017, has been reported by root and awaits the backend's saved authoritative evidence before inclusion here. |
| API native LeadConvert | One Fenmere conversion into its explicitly seeded Account and Leonie Contact. This exercises Salesforce native conversion by API; it is not an additional UI conversion. |
| Deployed controller through Apex | Fenmere's one `INVOICE_PROVIDED` action and one `PAYMENT_RECEIVED` action. The earlier compilation/projection-guard attempts had no business effects and are not counted as extra milestone actions. |
| Direct HTTP using current form serializer | Fenmere staff and logo, one POST each, with actual reconciliation. These are not browser-click submissions. The separate 74-request direct HTTP intake allocation remains separate: 73 Leads and one proven pre-Lead platform rejection. |
| Read-only verification | Root's three-booking assertion and Fenmere's completion/preservation checks perform no DML or sends. Actual inbox reads are counted as received-message evidence, not UI actions or Salesforce email calls. |

Root's supplementary records and receipts below prove the exact applied/rejected outcomes. Their complete browser-action totals remain part of root's final ledger; stored records alone are not used to invent a UI execution count. Evidence: [root registry](../tmp/nte-stress-20260907/catalog/fixture_registry.json), [representative intake](../tmp/nte-stress-20260907/representative-intake-after-04.json), [native Cancel](../tmp/nte-stress-20260907/native-cancel-complimentary.json), [Fenmere conversion](../tmp/nte-stress-20260907/conversion-live-001/RESULT.md), [Fenmere complete registry](../tmp/nte-stress-20260907/conversion-live-001/registry-fragment.lifecycle-complete.json), [Fenmere POST ledger](../tmp/nte-stress-20260907/conversion-live-001/lifecycle-02/forms-live-state/ledger.json), [74-request intake reconciliation](../tmp/nte-stress-20260907/bulk-harness/live-state-02/final-intake/cumulative-intake-summary.json).

## Harbour: paid top-up, correction and rejected repeat

Times below are UTC. The original £800 booking was invoiced at 23:46:28 on 7 September and payment recorded at 23:47:45. Its actual payment confirmation arrived at 23:47:46. The staff submission `00QAd00000URWQjMAP` then applied two covered names plus one additional place at £50; it left the original £800 payment intact. The top-up invoice was recorded on 8 September at 00:01:00 and payment at 00:01:42.

At 00:02:49, correction Lead `00QAd00000URXWTMA5` changed **Sophie Carrington to Sophia Carrington**, retaining one top-up place and £50. The [before](../tmp/nte-stress-20260907/representative-before-correction.json) and [after](../tmp/nte-stress-20260907/representative-after-correction.json) snapshots preserve original invoice/payment and top-up invoice/payment timestamps/by fields. Receipt `1a07e531becde2fa` confirms the corrected name, covered roster, one place and £50 in actual HTML and plain text.

The later increase, Lead `00QAd00000URXcvMAH` at 00:03:38, was **Failed and retained** with the one-purchase explanation. The [booking after rejection](../tmp/nte-stress-20260907/representative-after-rejected-increase.json) still has one place, £50, Sophia and the existing payment timestamp. The [submission query](../tmp/nte-stress-20260907/representative-supplementary-harbour.json) separately shows the successful staff Leads recoverably deleted, the logo audit retained, and the failed repeat retained. Bounded exact-reference inbox searches found no success receipt for the rejected increase and no duplicate booking-payment confirmation after the top-up payment. P02 still covers the pending applicant-facing rejection reply.

## Cedarhaven: complete replacement without changing contacts

Quote, invoice and original £30,000 payment are recorded at 23:45:37, 23:46:14 and 23:47:18. The paid confirmation is `1a07e44e4ec449d7`. Three staff names were received at 23:57:38. Initial logistics at 23:58:34 included a truck, trailer and two haulier staff names.

The replacement applied at 00:04:55 on 8 September: Monday 1 March 06:30–07:15, one revised 6.6 m electric cargo truck and a rigid transporter. The old trailer, Sunday window, equipment/haulier registrations and haulier staff names were cleared, not silently retained. The [earlier preparation snapshot](../tmp/nte-stress-20260907/representative-preparation-after-01.json), [final booking](../tmp/nte-stress-20260907/root-representatives-final.json) and actual replacement receipt `1a07e55087ba6edd` agree.

Georgia Merton remains submission-contact information. Oliver's exact Primary Contact role and recipient remain intact; Benjamin Ashford remains the separately stored event contact, and the finance contact remains separate. No submission contact is promoted into or used to overwrite the Primary Contact. The final role snapshot establishes these named bindings; a wider all-Contact preservation audit is still pending.

## Willowbridge: complimentary completion

The £0 complimentary booking sent its immediate confirmation `1a07e3a974c7da0f` at 23:36:03. Eleanor Whitcombe and Lucas Sullivan were received as the two covered staff at 23:56:13; the logo attestation followed at 23:59:31. Its invoice/payment flags remain false, and the final backend check passes Completed. Actual inbox reconciliation found no booking-payment confirmation for this complimentary case. The earlier cancelled native conversion caused no booking creation; a later explicit conversion created the recorded Opportunity.

## Fenmere: reused identity and a competing prior-year booking

The actual application was submitted at 23:39:50 for applicant Elliot Mercer, but conversion used exact newly seeded Account `001Ad0000193s4kIAA` and established-style Contact Leonie. Her name, email, title, phone and mobile were preserved; the Account's core details were preserved. Their NTE event/reference classifications correctly moved to the new 2027 booking. Elliot remained event-contact information. The £2,000 NTE2026 partner booking `006Ad00000UdgKiIAJ` retained its Daniel Primary Contact and commercial facts after the separately authorised Description update.

The provisional receipt at 23:45:03, payment confirmation at 00:01:20 and staff receipt at 00:05:54 all target Leonie's controlled inbox. The first two greet Leonie, and none picks up Daniel, the decoy reference/year or £2,000. Invoice and payment were recorded through the real controller at 00:00:35 and 00:01:19. The staff POST applies Elliot Mercer, Dina Ward and Rowena Cole as the three places already covered by £950, with zero new top-up. Its successful Lead `00QAd00000URXWUMA5` is recoverably deleted; logo Lead `00QAd00000URXufMAH` is retained. All captured core-identity/decoy hashes and the selected finance/contact fields remain unchanged after the two forms.

The [lifecycle handoff](../tmp/nte-stress-20260907/conversion-live-001/lifecycle-02/RESULT.md) retains three limits: the later decoy DML received a tied timestamp; logo attestation does not prove file upload; completion was asserted in the backend without a separate visual Master Panel check. A private logo guard wrongly expected deletion; it was corrected and the original evidence re-evaluated successfully without reposting. Earlier compile/projection mismatches had zero business effects. These are instrumentation corrections, not product fixes or extra sends.

## Actual inbox counts

| Scope | Acknowledgement / internal notice | Provisional or complimentary | Payment confirmation | Reminders | Staff receipts | Logistics receipts | Total |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| Harbour from application | 2 | 1 | 1 | 2 | 2 | 0 | 8 |
| Cedarhaven from application | 2 | 1 | 1 | 3 | 1 | 2 | 10 |
| Willowbridge from application | 2 | 1 | 0 | 2 | 1 | 0 | 6 |
| Fenmere post-conversion only | 0 | 1 | 1 | 0 | 1 | 0 | 3 |

The [final phase ledger](../tmp/nte-stress-20260907/email-quality/inbox-journeys/final-phase-ledger.json) holds **27 distinct received message IDs: 24 root + three Fenmere**. This is actual saved MIME, including the three root internal notices, not a count derived from Salesforce Sent flags. Twenty-two root messages matched booking-reference searches; two further internal notices were matched by their exact Lead headers. Internal notices go only to the approved Euroforce alias; post-conversion applicant messages go only to the exact Primary Contact's controlled Anthrion inbox, with no CC/BCC headers. Personalisation, readable multiline details, currency and HTML/plain-text meaning were checked.

The two earlier EOI invitations, two guest messages, the volunteer route/logo receipts and the obsolete-package failure notice are separately evidenced and excluded from 24 + 3. The [00:09:04 UTC search](../tmp/nte-stress-20260907/email-quality/inbox-journeys/final-count-and-no-logo-proof.json) finds one payment confirmation for each paid case, none for Willowbridge, and no Fenmere message after logo application within the observed window. [Correction verification](../tmp/nte-stress-20260907/email-quality/inbox-journeys/final-corrections-verification.json) covers the rejected increase and both replacement receipts. No broad Gmail/Outlook visual-rendering claim is made.

## Remaining work for resumption

- Attach the authoritative APP-EX-017 fourth native-UI conversion/approval result before counting it, then finish the allocated native duplicate cases. Do not change matching rules or bypass duplicate controls.
- Finish wider bulk preparation, finance, final-pack and repeat-send checks; reconcile exact outcomes in the shared catalogue ledger.
- Temporary pack configuration is now restored and verified: deployment `0AfAd00000SpJRtKAN`, original routing fields, both pack URLs null and zero globally Queued final packs. The separate EX004/EX002 initial pack sends are Sent and immediate replay queued zero. Finish the later EX005/EX002 pack-history protocol; the four earlier representative snapshots still have no pack send.
- Run the final nine-report reconciliation after finance is stable, and complete the protected Anthrion/legacy preservation comparison.
- Finish source/generator/manifest reconciliation and the final full check-only validation. The earlier actual deployment result remains 423 components / 278 tests.
- Follow root's [NTE_AUDIT_RESUME.md](../NTE_AUDIT_RESUME.md) when resuming. This journal does not replace the root's remaining-work allocation or approve new business policy.

F01–F33, P01–P17 and U01–U20 in the [main report](NTE_STRESS_TEST_AND_IMPROVEMENTS_2026-09-07.md) remain stable. The ordinary paid-confirmation and Closed Lost update decisions remain settled; pending policy items are still explicitly separate.
