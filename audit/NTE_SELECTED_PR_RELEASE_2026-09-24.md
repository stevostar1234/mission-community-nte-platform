# Selected PR follow-up — 24 September 2026

Status: approved implementation deployed and verified in MMUAT; canonical preview published. The note-length change is parked and the optional website-address remedy awaits a decision. This is internal release documentation, not a production-release approval.

Base: `stevostar1234/mission-community-nte-platform` main `d8d47785097638d57fa8244fcfd1e01b33849a0d`. Work is isolated in `tmp/nte-selected-pr-release-20260924/repository`; the original dirty workspace and its unrelated files are preserved.

GitHub API verification on 24 September reports the platform repository as **public**. This release preserves its existing visibility. Raw Salesforce queries, email probes and record baselines are kept in the ignored local evidence directory and are not part of the GitHub publication.

## Selected changes

| GitHub PR | Decision and practical effect |
| --- | --- |
| #1 logistics | Six logistics contact values survive deletion of the successfully acknowledged temporary Lead. They appear in a two-column Logistics contacts section on the NTE Opportunity page and in report NTE 05. No existing page/report field is removed, and no contact is added to the Master Panel or acknowledgement. |
| #2 intake/recovery | Omit owner rerouting changes, generated references and additional resend restrictions. Preserve manual top-up receipt with an unknown/zero quantity when a later staff form arrives: accept names without resetting receipt, inventing quantities/prices or creating another charge. |
| #3 panel | Omit the missing-payment-method hint, extra No heavy vehicle control and proposed follow-up restrictions. Staff retain full-record manual editing. |
| #4 forms | Align two stale hidden pricing-version literals with the already active `NTE27-2026-09-13-VAT` calculation. No catalogue price or VAT calculation changes. Omit the loading gate. A live non-submitting check reproduced `www.NTE.com` failing native URL validation; its narrowly scoped remedy awaits the owner's response. |
| #5 tooling | Keep the combined local test command, Windows path handling and CSV line-ending normalisation. These affect developer verification, not applicant or staff choices. The CSV contents are byte-identical after normalising CRLF to LF. |
| #6 free confirmation | Declined. Retain the existing £0 waiver → Requirements → Confirm Free space route. |
| #7 failure guide | Declined. Retain manual correction/resubmission with no reprocess button. |
| #8 note capacity | **Parked by the owner.** The Lead/form accepts 1,000 characters; the Opportunity field accepts 255. Both remain unchanged. See the deferred decision below. |
| #9 second review | Keep a small offline GitHub workflow to check generator reproducibility and run the local suites. It has read-only repository permission and no Salesforce/Pages deployment or email/payment access. Unselected policy changes and unapplied patch bundles are not imported. |

The Approved path and corresponding converted-booking queue headings become **Converted**. Internal keys, conversion behaviour and saved booking states remain unchanged.

NTE Relationships clears stale account/contact/booking cards after a load failure and recovers on the next successful load. The regression test specifically switches from a populated record to a failed second record and then a successful retry.

## Email Activity history

NTE intake, provisional/free confirmations, booking-payment confirmations, top-up payment requests, supplementary acknowledgements and reviewed bulk invitations/reminders request native Salesforce activity storage. Recipients, template wording, send timing and existing status handling are preserved. The native message retains its actual subject, recipient and rendered HTML/text; booking messages link to the Opportunity and its Primary Contact. Intake messages link to their Lead.

Supplementary acknowledgements are merged from their saved submission before deletion and sent as standalone content addressed to the booking's Primary Contact. The historical email no longer relies on a temporary Lead. A rollback-only native probe verified that Salesforce creates the EmailMessage and its linked Activity Task; no message was delivered. Unit tests additionally compare the exact original template rendering and exercise a full 100-message asynchronous batch.

Existing operational audit Tasks remain historical evidence. New free confirmations use an accurate free-space confirmation audit title rather than “provisional”. Past messages whose original body was not stored cannot be reconstructed faithfully; this release does not fabricate bodies or resend old messages to create history.

The owner clarified that genuinely failed booking sends may be retried, while already-sent emails use manual forwarding. The existing sent-timestamp guard stays unchanged. Editing an already-sent notification to Failed does not override that guard.

## Deferred note-length decision

Native Setup rejects an in-place Text → Long Text Area conversion because 16 saved versions of `NTE_Copy_Converted_Lead_to_Opportunity` reference the field (15 obsolete and one active). No field, Flow version or Opportunity was deleted or altered during inspection.

The owner explicitly parked the change. Options for later are (a) constrain the form and Lead input to 255 characters, preserving the destination field, or (b) introduce a 1,000-character replacement, migrate existing values, update the active mapping/page and retain the hidden old field while historic Flow versions depend on it. No option is currently approved. A note above 255 characters remains a known conversion risk and must be revisited before production readiness is declared.

## Preserved decisions

- Keep the current last-processed staff/logistics update behaviour. The owner declined the suggested freshness block after manual corrections.
- Do not add exception/dismissal/reprocess buttons, inferred payment methods or automatic booking references.
- Preserve manual waivers, independent finance checklist ticks and the single positive staff top-up policy.
- Do not replay historical submissions, booking emails, payments or fixture cleanup.
- Mission/volunteer record pages, all shared layouts/profiles and production assignments remain untouched.

## Validation and release evidence

Evidence directory: `tmp/nte-selected-pr-release-20260924/`. Raw exports and message probes remain local. The shareable source qualification is [NTE_SELECTED_PR_QUALIFICATION_2026-09-24.json](NTE_SELECTED_PR_QUALIFICATION_2026-09-24.json).

- Full check-only `0AfAd00000T4hKDKAZ`: **535 components / 439 tests passed**, zero component/test errors and no coverage warnings. All **623 source/manifest hashes** remained unchanged before the actual deployment.
- Actual narrow sandbox release `0AfAd00000T4hbxKAB`: **25 components passed**. It contains only 14 Apex classes, six fields, one NTE page, one LWC, two existing NTE permission sets and one report. No Flow, field deletion, profile, shared layout or non-NTE page is deployed.
- Native readback matches all 18 Apex/LWC source files. The NTE Opportunity page retains all 153 previous fields and adds six; NTE 05 retains all 34 previous columns and adds six. Both permission sets retain all previous entries and add only the six field permissions.
- A rollback-only integration probe against the released service verified both logistics contacts and two full rendered EmailMessages, each linked to its booking and Primary Contact, surviving temporary-Lead deletion within the transaction. The whole transaction rolled back: no test records or delivered messages remain. All **28 existing booking snapshots**, including modified timestamps and captured finance/email/update states, match the baseline.
- The actual Lightning UI displays **Converted** and all six editable logistics contact fields in the new section. Existing historic activities remain intact. Older deleted logistics submissions are not replayed or backfilled.
- `npm test` passes all local suites, including **154 form-engine checks / 35,536 finite combinations**, **90 component tests**, metadata/report checks, six page-isolation, five shared-picklist, seven Stripe-preflight and six volunteer-compatibility checks. Generator rebuild changes no files. CSV changes are line-ending normalisation only.
- Canonical preview commit **`afaa8043aa8fe6080f7e05a1ae9997b2b72de985`** passed its Pages build; both hosted HTML files byte-match the intended source. All 66 shared site files match between the platform and forms working copies. Only the two hidden pricing literals changed on the website.
- The first check-only attempt had two new test-assertion diagnostic errors (null assertion-message arguments), with the underlying native sends accepted. Correcting those diagnostic strings produced the final full pass; no runtime restriction was relaxed for the tests.

The lightweight GitHub check is retained because it checks the saved source and reviewer PRs independently of whatever is currently deployed in the sandbox. It does not replace native Salesforce tests or deploy anything. Windows path handling only normalises developer file paths; line-ending handling only keeps generated text consistent. Neither changes application submission or staff workflows.

Platform PRs #1, #2, #5 and #9 are superseded by the selected implementation; #3, #6 and #7 are declined. Their requested closures are completed after the verified source backup. #8 remains open and parked. Platform #4 and forms #1 remain open for the pending website decision; their pricing-literal subset is already incorporated. No entire mixed-scope PR is claimed as merged.
