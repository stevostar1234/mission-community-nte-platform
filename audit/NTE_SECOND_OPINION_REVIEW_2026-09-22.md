# NTE second-opinion review of the 22 September pull requests

22 September 2026 · Reviewer: Claude (Opus 5.5), for Steven Skyba · Findings, questions and follow-up patches

**Scope.** This review covers the pull requests Claude (Fable 5.1) opened earlier today:

- platform [#1](https://github.com/stevostar1234/mission-community-nte-platform/pull/1)–[#8](https://github.com/stevostar1234/mission-community-nte-platform/pull/8)
- forms [stevostar1234/nte27-web-to-lead-demo#1](https://github.com/stevostar1234/nte27-web-to-lead-demo/pull/1)
- the write-up in [#7](https://github.com/stevostar1234/mission-community-nte-platform/pull/7)
- anything else noticed on the way

None of those pull requests was merged, closed or changed. Proposed changes are provided as patches in `audit/second-opinion-2026-09-22/`, for whoever reviews them to apply or drop.

**Org use.** Nothing was deployed. MMUAT was used only for:

- check-only (`--dry-run`) validations
- read-only queries

The volunteer form stays outside NTE scope. It appears here only where an NTE pull request touches it, or where it affects the NTE release process.

Every finding below was checked against the code or the org. Several came from independent sub-reviews and were re-verified before inclusion. Two claims in the earlier write-up turned out to be wrong (§3.7 and §3.8). Items that need a decision rather than a fix are marked **Question**.

## 1. Verdict per pull request

| PR | Verdict | Main reason | Follow-up patch |
| --- | --- | --- | --- |
| #1 Logistics contacts | Merge, together with the preview mirror | Correct and well tested. The hosted client preview has identical copies of the changed email and would fall behind. | `forms-mirror-of-platform-pr1-email-preview.patch` (forms repo) |
| #2 Intake, top-up, dispatch guards | Merge after patch | Breaks the normal local suite (`tests/forms.test.js`). The new rejection message tells staff to use a "reprocess" action that doesn't exist. | `pr2-intake-and-update-guards.patch` |
| #3 Master Panel fallbacks | Merge after patch | "No heavy vehicle" also overrides an applicant's explicit **Yes**, which takes a confirmed vehicle off the logistics list. | `pr3-master-panel-fallbacks.patch` |
| #4 + forms #1 Form hardening | Merge after patch, in both repos | The new website rule accepts junk that the old engine blocked (checked in Chromium 152). The button is enabled before set-up finishes. There is no no-JavaScript notice. The volunteer page is changed. | `pr4-forms-hardening.patch` + `forms-pr1-forms-hardening.patch` |
| #5 Tooling | Merge first | Correct. Optional: explicit binary patterns. | none |
| #6 Free space editable | **Client decision**. If kept, apply the patch. | A hand tick marks the booking confirmed without sending the applicant their confirmation, staff-details and logo links. | `pr6-free-space-help-text.patch` |
| #7 Write-up | Merge after corrections | Three factual errors, and no status for the 16 September audit items that no pull request covers. | `pr7-write-up-corrections.patch` |
| #8 Space-position capacity | Keep as draft | The blocker was misdiagnosed. No live or recycled booking holds a value today, and validation still fails. | none (options in §3.8) |

**Recommended order:** #5 → #2 (patched) → #1 (+ preview mirror) → #3 (patched) → #4 + forms #1 (patched, together) → #6 if accepted (patched) → #7 (corrected). #8 waits for the decision in §3.8.

## 2. Cross-PR checks

- **Merging:** #1–#7 merge into `main` without conflicts. #8 conflicts with #6 only in `tests/metadata-reports.test.js`, where both add assertions at the same point; keep both blocks.
- **Generator:** after merging everything, `node scripts/build-metadata.js` reproduces every committed generated file exactly (0 changed files). The same holds for #5, #6 and #8 on their own, and for the final tree with every follow-up patch.
- **Local suites on the combined tree:** all pass except `tests/forms.test.js`, which fails because of #2 (§3.2, finding 2.1). This went unnoticed because the repository has no CI; this pull request adds one (§5).
- **Combined sandbox validation, as submitted:** #1, #2, #3 and #6 had only been validated one at a time. Validated together, check-only, `0AfAd00000T2OS9KAN` succeeded:
  - 22/22 components and 370/370 tests across all 28 NTE test classes, 0 errors
  - coverage: `NTEUpdateSubmissionService` 92.1%, `NTE_MasterPanelController` 96.6%, `NTEInboundLeadService` 97.7%, `NTEEmailDispatchService` 95.6%
- **Combined validation with every follow-up patch applied:** check-only `0AfAd00000T2PhZKAV` succeeded, 22/22 components and 371/371 tests, 0 errors, same coverage.

## 3. Findings by pull request

Severity:
- **Must fix:** breaks the build or tests, or causes wrong data or a lost operational step in normal use.
- **Should fix:** misleading or confusing behaviour, an edge case, or a test that doesn't prove its claim.
- **Nit:** polish.
- **Question:** the owner or client needs to confirm what is intended.

Line numbers refer to the pull request branch unless stated.

### 3.1 PR #1: logistics contacts

The core change is right.

- The form maps the main contact to `Event_Contact_Name__c` (joined from first name and surname by the engine) plus `Email` and `Phone`, and the second contact to `Secondary_Contact_*`.
- The service already refuses a submission unless all six values are present (`NTEUpdateSubmissionService.cls:472-474`).
- Types and lengths match the Lead source fields exactly.
- The optional email row renders correctly for all eight blank/filled combinations, in both the HTML and text versions.
- An invalid or partial submission leaves the six fields untouched.

| # | Severity | Finding | Proposed change |
| --- | --- | --- | --- |
| 1.1 | Should fix (process) | `email-templates/examples/` and `source/heavy-vehicle-details-applicant-confirmation.html` are byte-identical in both repos on `main`. The client preview (nte27-web-to-lead-demo) is not updated, so merging #1 alone leaves it showing the old acknowledgement. `AGENTS.md` asks for previews to be kept current and for real Salesforce merge output to be checked. A check-only deploy does not render the email. | Merge the forms-repo mirror patch with #1. After the eventual real deployment, render the template once for full, name-only and email-plus-phone second contacts. |
| 1.2 | Question | The acknowledgement now shows the second contact's name, email and phone, but the main contact row still shows only the name. This is new client-facing content, and it's asymmetric. | Ask the client whether they want the main contact's email and phone echoed too, or the second contact reduced to a name. |
| 1.3 | Nit | The record page's logistics section is now 19 fields on the left and 6 on the right (`scripts/build-metadata.js`, opportunity sections). The NTE_05 report description doesn't mention the new contact columns. | Move the six `NTE_Logistics_*` fields to the right-hand column, and extend the report description. |

Earlier heavy-vehicle submissions cannot be back-filled, because their temporary Leads are gone. The PR says so, and that's correct.

### 3.2 PR #2: intake, top-up and dispatch guards

The four changes are logically sound when the data is consistent:

- **O04:** only the create flow routes owners.
- **O08:** the generated reference matches the browser format exactly: `NTE-` + milliseconds + 8 characters from the same 32-character alphabet, 26 characters in total. It passes every consumer's validator, and the field is unique and case-insensitive.
- **O02:** every field in the predicate is a top-up field. `NTE_Top_Up_Invoice_Required__c` is only ever set by the first top-up purchase.
- **O07:** `Status__c` is a Text field, so `Skipped` is valid.

| # | Severity | Finding | Proposed change (in the patch) |
| --- | --- | --- | --- |
| 2.1 | **Must fix** | `node tests/forms.test.js` fails on this branch and on any merge that includes it. Line 704 asserts the source text `previousTopUpCount == 0 && requestedTopUpCount > 0`, which the PR replaced. The PR description lists only the sandbox validation. | Assert the new durable-evidence rule and the held-for-repair branch instead. |
| 2.2 | Should fix | The new rejection message (`NTEUpdateSubmissionService.cls:476-479`) ends "…then reprocess this submission". That action doesn't exist, and the owner declined a correct-and-reprocess action (`audit/NTE_END_TO_END_AUDIT_2026-09-14.md`, "Failed update correction"). The agreed recovery is manual correction or one fresh form. The advice also misleads in the edge case the PR itself raises: after a hand-ticked "NTE Top-up Payment Required", following it records the places with no unit price or total, and the Stripe top-up send then refuses ("There is no unpaid staff top-up"). | Plain-English wording that points to the booking record or a fresh staff form, and to clearing the payment fields if nothing was bought. A negative count typed by hand is treated like a blank one (`<= 0`). |
| 2.3 | Should fix | The O07 test (`NTEEmailDispatchServiceTest.cls:231`) uses an INVITATION. The old code already refused to resend those, because the Lead is marked invited. So the test fails on the old code only for the message and `canRetry`, not for the actual "no second send". The kinds that really were resent are preparation reminders and BOOKING_CONFIRMED. | New test `acceptedReminderRelabelledFailedIsNotSentAgain`, using a STAFF_DUE reminder, which the old code does resend. |
| 2.4 | Should fix | `retryFailed` skips non-Failed rows before checking `alreadyAccepted` (line 295). Retry on a genuinely Sent dispatch therefore says "Check the Send Error on this email record", and that field is blank. | Check acceptance first, so Sent rows get the accepted-email guidance. Covered by the new test. |
| 2.5 | Nit | A hand-queued dispatch that already has `Sent_At__c` becomes `Skipped` (line 418). The panel's last-sent date and the duplicate guards read `Status = 'Sent'`, so the accepted email disappears from both. It is hard to reach in practice. | Restore `Sent` instead, and keep the guidance text. |
| 2.6 | Should fix | The test helper `colleague()` (`NTEInboundLeadServiceTest.cls:69`) takes whichever active standard user is oldest in the target org, falling back to a profile named "Standard User". In production that could be an integration or minimum-access user who can't own Leads, which would fail the deployment's tests. | Always create a user with the runner's profile and a unique username, the same pattern `NTEUpdateIssuesPanelTest` already uses. |
| 2.7 | Question | After O04, a Lead that was never routed at intake is not routed by a retry once the routing is fixed (for example, the configured owner was inactive). The notification goes to the new owner, but the Lead stays with the default owner. This follows the audit's wording. | Put "reassign the Lead by hand after repairing routing" in the release notes, or allow a retry to route when `OwnerId` is still the creator. |
| 2.8 | Question | O08 fills a missing reference only when the Lead is created. An application whose type is set later, or whose reference is cleared before conversion, still converts without one. The audit made the whole fix conditional on "if native entry is supported". | Confirm whether keying applications directly into Salesforce is a supported route. If it is, consider a conversion-guard message for a blank reference. |
| 2.9 | Question | The reused guidance "Forward the original email" can't be followed. Every NTE send uses `setSaveAsActivity(false)` with no BCC, so staff have no copy to forward. The wording predates this PR, and the audit asked for it to be reused. | Owner's choice, for example "…and will not be sent again. If it did not arrive, contact the recipient directly." |

Inaccuracies in the PR description:
- The worker uses an inline `Sent_At__c` check rather than the shared helper.
- The note about the hand-ticked field understates the risk: any of the five non-quantity evidence fields set by hand blocks a first top-up.
- It doesn't mention that `routesSupportedLeadAndBuildsNotifications` was rewritten, legitimately, because it asserted the behaviour O04 removes.

**The patched branch validates:** check-only `0AfAd00000T2P1dKAF` succeeded, 6/6 components and 369/369 tests across all 28 NTE test classes, 0 errors, with unchanged coverage.

### 3.3 PR #3: Master Panel fallbacks

| # | Severity | Finding | Proposed change (in the patch) |
| --- | --- | --- | --- |
| 3.1 | **Must fix** | "No heavy vehicle" is offered, and accepted, for bookings whose applicant answered **Yes** but hasn't sent the details yet. The code says so (`NTE_MasterPanelController.cls:840`, "…or an unconfirmed Yes"; the row flag at line 1391). The PR text, the write-up's finding I and the open workflow question (`NTE_DESIRED_WORKFLOW.md:252`, "unknown → not required") all describe only blank or "Not known yet". One click on a Yes row: <ul><li>takes it out of Logistics outstanding</li><li>stops the heavy-vehicle reminders (`HEAVY_DUE` treats `No` as complete)</li><li>removes it from NTE_05, the logistics team's list, which filters on `Yes`</li></ul> The confirmation dialog doesn't mention that the applicant said Yes. | Refuse Yes on the server, with a pointer to the full record, and don't offer it on the row. Tested. If the owner wants staff to override a Yes from the panel, it needs its own explicitly worded confirmation instead. |
| 3.2 | Should fix | The confirmation reads "…It leaves Logistics outstanding…" (`nteMasterPanel.js:770`), which suggests the booking stays outstanding. | "…It will move out of Logistics outstanding. Vehicle details sent later will still be applied." |
| 3.3 | Should fix | Unlike the milestone and decision handlers, the new handler doesn't set `isActionPending` before its dialog. A focus or visibility refresh can start while the dialog is open. If it's still loading when OK is clicked, `saveFinanceChange` returns without calling Apex or showing a toast. | Hold refreshes during the dialog, as `handleMilestone` does, and show a toast if the dialog itself fails. Added to the shared "locks before confirmation" and "cancel" panel tests (92/92 pass). |
| 3.4 | Nit | The payment-method hint names Stripe even when the Stripe configuration is disabled. It also carries `role="status"` on static text. `NTE_Payment_Method__c` is a restricted picklist (Bank transfer, Stripe), so the hint condition itself is correct. | "Set the payment method on the full record to enable the payment request." Drop the role. |
| 3.5 | Question | Nothing records that staff, not the applicant, set "No". Only `LastModifiedBy` is kept. | If the client wants this traceable, add confirmed-by/at fields as the payment milestones have. |
| 3.6 | Question | The action doesn't check Update issues. An applicant's heavy-vehicle form that failed validation can sit there while staff confirm "No". | Optionally warn when an unapplied Heavy Vehicle Details submission exists for the same reference. |

The write-up rates finding I as Medium ("no route to 'No' except editing the full record"). `NTE_Heavy_Vehicle_Required__c` is an editable Text(40) field for NTE users, so the route existed. The button is a convenience, closer to Low.

The PR description is slightly inaccurate:
- The hint was added to the Requirements card footer only, not the table cell. That's harmless, because Requirements renders cards.
- The card already showed "Payment method: Not stated". What was missing was the instruction.

### 3.4 PR #4 and forms PR #1: public form hardening

Both repos' changed files are byte-identical, blob for blob, before and after the follow-up patch. Every form re-enables on a normal load and after a Back restore (`pageshow`).

| # | Severity | Finding | Proposed change (in both patches) |
| --- | --- | --- | --- |
| 4.1 | **Must fix** | Once `https://` is added to anything without a scheme, the browser's URL check accepts almost everything. The old engine blocked these values. With the PR, all of them are posted to `Lead.Website`, and `{!Lead.Website}` appears in the partner/sponsor EOI acknowledgement and internal email:<ul><li>`N/A` → `https://N/A`</li><li>`tbc`, `none`, `-`, `example`</li><li>`someone@example.org` → `https://someone@example.org`</li><li>`https//example.org`</li><li>`not a website`</li></ul>Re-checked here in Chromium 152. The new error message is effectively only reached by a bare `https://`. The test fixture validates with Node's stricter `URL`, so the suite didn't notice. | A website must be an http(s) address with a real host name and no user name. A rejected entry is left as typed. `www.example.org`, ports, international domains and `//example.org` are still accepted, confirmed in Chromium 152 and Node. The message becomes "Enter a website address such as www.example.org, or leave it blank." |
| 4.2 | Should fix | The button is enabled at `assets/forms.js:789`, before the Code of Conduct set-up, the honeypot and the submit handler are installed. The 16 September O03 fix said "enable only after complete setup". If set-up throws after that line, the visitor gets a live button that does a native GET to the same page and loses what they typed, which is the O03 failure itself. | Enable at the end of each form's set-up, and only when its system fields were filled. |
| 4.3 | Should fix | O03 also asked for "a concise static loading/unavailable state and no-JavaScript contact route". There is none. A visitor without JavaScript finishes the form and finds a grey button with no explanation. | A one-line `<noscript>` notice on each NTE form, using the existing contact address (`nte@missioncommunity.org`, already `supportEmail` in `assets/config.js`). |
| 4.4 | Should fix (scope) | The PR changes the volunteer form's behaviour: its submit button now starts disabled. It also bumps the volunteer thank-you page, which isn't mentioned. The owner asked for NTE changes to leave the Mission app's volunteer pages alone. | Revert both. The cache-buster on `volunteer-application.html` stays because the asset-version test requires it, and it is behaviour-neutral. If the Mission owner wants the same protection, it is a one-attribute change. |
| 4.5 | Nit | Only one form is checked for re-enabling. The fixture's `requestSubmit` ignores the disabled state, so removing the enable line broke just one test. | Every form is now checked after start-up, and junk website values are tested (stress suite 165/165). |
| 4.6 | Nit | The pricing-default test depends on attribute order and could pass without matching anything. `documentation/chapters/10-client-reference.md` and `documentation/source-analysis/forms.json` still show the old `NTE27-2026-09-10` default. | Not patched. Make the match order-independent, and refresh the generated docs when next rebuilt. |

The PR description says a form without its engine "would post without … validation". In fact the forms have no `action`, so a native submit is a GET to the same page and nothing reaches Salesforce. The fix is still right: it stops the visitor losing their entries. The PR also bumped three non-form pages, not two.

### 3.5 PR #5: tooling

Correct.

- All 932 text blobs in the index are LF. The only CRLF file is renormalised.
- `.docx`, `.asset` and `.resource` files are detected as binary even without explicit patterns.
- `npm test` covers every suite.
- The page-isolation fix is right.

Nits:
- Adding explicit `*.docx`, `*.xlsx`, `*.asset` and `*.resource` binary lines would remove any reliance on auto-detection.
- The forms repo has no `.gitattributes`, and its checkout here uses `core.autocrlf=true`. Its blobs are all LF today, so the same file there is optional hygiene.

### 3.6 PR #6: free-space confirmation editable

| # | Severity | Finding | Proposed change |
| --- | --- | --- | --- |
| 6.1 | **Must fix if kept** (otherwise close) | The free-space confirmation email is the message that sends a complimentary booking its "Staff details and event preparation" section and the staff-details and logo links (`government-charity-approved-confirmation.html`, `partner-sponsor-free-confirmed.html`). Ticking the newly editable box by hand has these effects, without any warning:<ul><li>The booking moves to Payment confirmed and can reach Completed (finance formulas).</li><li>The Requirements action disappears.</li><li>`NTEFinanceService.cls:91` refuses a later send ("already confirmed").</li><li>The applicant never receives their confirmation or preparation links.</li><li>Only `LastModifiedBy` records who ticked it.</li></ul>A basic administrator sees an unticked "NTE Free Space Confirmed" box on a record they believe is confirmed. `FUTURE_NTE_MAINTENANCE.md` says a complimentary booking "receives its explicit free-space confirmation from Requirements". | Recommendation: keep the field locked unless the client has a real "confirmed outside the email" case. If kept, apply `pr6-free-space-help-text.patch`, which adds field help text saying that ticking it sends nothing and pointing to **Confirm Free space** (the generator gains `inlineHelpText` support). |
| 6.2 | Should fix (description) | "Unticking it returns the booking to Requirements where Confirm Free space can be sent again" is true only when the flag was set by the approval-email path (`NTEExhibitorApprovalEmailService.cls:357`). If it was set by a sent BOOKING_CONFIRMED dispatch (`NTEEmailDispatchService.cls:480`), `confirmedBookingIds` (`NTEExhibitorApprovalEmailService.cls:165`) refuses the resend. The booking then sits in Requirements with an action that fails. | Correct the description, or also let a hand untick clear that path. |

The write-up rates G as Medium ("could not be progressed without an administrator"). The panel's Confirm Free space action already progresses these bookings, and its failure path is retryable. The remaining case, a booking confirmed outside email, is a policy choice, so Low or Question fits better.

### 3.7 PR #7: the write-up

**Factual corrections**, in `pr7-write-up-corrections.patch`:

1. §2 still says "See PR for the check-only result" for #6. It succeeded: 4 components, 105 tests.
2. **#8 (§2, F, §4.7).** "12 recycled bookings hold the field; empty the Recycle Bin" does not hold up.
   - Tonight's read-only query with all rows found 97 recycled Opportunities, and none of them, live or recycled, has `NTE_Exhibitor_Space_Position__c` set.
   - The check-only validation still fails with "Cannot change type due to existing data" (`0AfAd00000T2OlVKAV`).
3. **Finding R and §5.** These describe "two deterministic Apex test failures". Org history says otherwise:
   - Both `VolunteerInboundLeadServiceTest` methods passed in every recorded run on 14, 15 and 17 September, including the 17 September full validation `0AfAd00000SyKtNKAV` (434/434).
   - They failed only in the two asynchronous test runs on 22 September (13:20 and 13:25 UTC).
   - They pass again at deploy time: check-only `0AfAd00000T2P3FKAV` ran both volunteer classes, 25/25.
   - So the failure depends on how the tests are run, and it doesn't block the documented `RunLocalTests` release validation on current evidence.

**Missing context.** The write-up gives "no blocking defect" as its overall result. It doesn't say which findings from the 16 September simplicity audit remain open. Several were re-checked today and are still present in `main`; see §4.

**Process.** The 16 September audit records every finding except S01 as "unchanged and unapproved". `AGENTS.md` says a recommendation is not approval.
- As review branches, the PRs are fine.
- But none of them updates `NTE_CHANGE_PROPOSALS.md`, `NTE_AUDIT_RESUME.md` or the desired workflow's open question on heavy-vehicle handling.
- Whoever merges should record the owner's selection there.

### 3.8 PR #8: space-position capacity

| # | Severity | Finding | Proposed change |
| --- | --- | --- | --- |
| 8.1 | **Must fix (diagnosis)** | The blocker isn't the Recycle Bin (evidence in §3.7). "Emptying the Recycle Bin and re-validating" is therefore not a reliable way forward. | Choose one of:<ol><li>Change the field type once by hand in MMUAT Setup (Text → Long Text Area 1,000; Setup keeps the values), then validate and deploy #8 so source and org agree.</li><li>An additive `LongTextArea` destination. The audit allowed this, but it leaves two fields.</li></ol>The audit ruled out truncation. |
| 8.2 | Question | Does production already have `NTE_Exhibitor_Space_Position__c`? If NTE isn't in production yet, #8 creates the field as a Long Text Area and there's no blocker there. If it exists with history, the same refusal is likely. | Check before the production release plan relies on #8. |
| 8.3 | Should fix | The test converts a single-line 616-character note. O05's verify list asked for 255, 256 and 1,000 characters and for multiline text. | Use an exactly 1,000-character note containing a line break once the change can be validated. Not patched, because #8 can't be validated yet. |

The claim that the public forms don't collect this field is true. Only `assets/config.js` maps its Web-to-Lead ID.

## 4. Items from the 16 September audit that no pull request covers

These were re-checked in `main` today. They remain open and unapproved; this review doesn't implement them.

| ID | Status today | Note |
| --- | --- | --- |
| O01 | Still present | Delayed preparation jobs write the full roster or logistics replacement without a freshness check. A queued old form can overwrite a newer manual correction. |
| O06 | Still present | `nteRelatedOpportunities.js`: the error branch keeps the previous record's account, contacts and opportunities. That is a wrong-person risk after a failed load. The fix is small: clear them on error. |
| O12 | Still present | `scripts/post-deploy/backfill-nte-pricing.apex` is still in the post-deploy folder. |
| O14 | Still present | The update job ID from `System.enqueueJob` is discarded (`NTEUpdateSubmissionService.cls:94`). |
| O15 | Still present | Relationship queries stop at `LIMIT 200` with no "more" indicator. |
| O16 | Still present | Home formats money with no pence. |
| S05 | Still present | More than 100 supplementary acknowledgements in one batch fail as a whole, by design, with a retry message. |
| O09, O11, O13, O17–O20, S02–S04, S06, S07, C01–C05, R02 | Not re-checked here | See the 16 September audit. O13 appears as S in the earlier write-up. |

## 5. Other observations

- **No CI.** Nothing runs the local suites on a pull request, which is how 2.1 slipped through. This PR adds `.github/workflows/local-suites.yml`. On every pull request and on `main` it checks that the generator reproduces the committed metadata, then runs `npm test`. It needs no secrets and doesn't contact Salesforce. It is fully useful after #5 merges, because `npm test` then runs every suite. Drop it if Actions minutes are a concern.
- **Web-to-Lead's daily limit (write-up N).** Submissions over the limit aren't queued. Salesforce emails them to the Default Lead Creator, and someone has to key them in. That is exactly the native-entry route #2's O08 change protects.
- **Production configuration.**
  - `manifest/production-package.xml` deploys `NTE_Routing_Config.Default`, which holds the preview-site form URLs and the MMUAT owner username.
  - The production plan (step 5) and `PRODUCTION_PACKAGE_SYNC.md` already say to replace them.
  - Keep that step immediately after the deploy: until it runs, production emails would send applicants to the preview site, whose forms post to MMUAT.
- **Secrets scan:** clean. Only synthetic Stripe keys, in `tests/stripe-preflight.test.py`.

## 6. Questions for the owner or client

1. PR #6: should staff be able to tick "free space confirmed" without sending the confirmation email? If yes, is the help-text warning enough?
2. PR #3: may staff change an applicant's **Yes** to **No** from the panel, or only on the full record? Should the change be traceable (by/at fields)?
3. PR #1: echo the main contact's email and phone in the acknowledgement too, or show only the second contact's name?
4. PR #2: is entering applications directly in Salesforce a supported route? After O04, is "reassign by hand after fixing routing" acceptable?
5. PR #2: what should the "already accepted" message tell staff, given no copy of sent emails is kept?
6. PR #8: manual type change in MMUAT Setup, or an additive field? Does production already have the field?
7. Record the selections in `NTE_CHANGE_PROPOSALS.md` and `NTE_AUDIT_RESUME.md` when merging.

## 7. Patches and how to apply them

Each patch is a `git format-patch` commit made on top of the named pull request branch. None of these patches touches volunteer behaviour.

| File | Apply to | Contents |
| --- | --- | --- |
| `pr2-intake-and-update-guards.patch` | platform `review/intake-and-update-guards` | 2.1–2.6 |
| `pr3-master-panel-fallbacks.patch` | platform `review/master-panel-fallbacks` | 3.1–3.4 |
| `pr4-forms-hardening.patch` | platform `review/forms-hardening` | 4.1–4.5, with tests |
| `forms-pr1-forms-hardening.patch` | forms `review/forms-hardening` | Same site files as the PR 4 patch, byte-identical |
| `pr6-free-space-help-text.patch` | platform `review/field-capacity-and-manual-fallback` | 6.1 help text, generator support, metadata test |
| `pr7-write-up-corrections.patch` | platform `review/independent-review-write-up` | §3.7 corrections and a pointer here |
| `forms-mirror-of-platform-pr1-email-preview.patch` | forms, a new branch from `main` | 1.1 |

```sh
git checkout review/intake-and-update-guards
git am audit/second-opinion-2026-09-22/pr2-intake-and-update-guards.patch
```

**Evidence**, all check-only in MMUAT, nothing saved:

| ID | What | Result |
| --- | --- | --- |
| `0AfAd00000T2OS9KAN` | #1+#2+#3+#6 as submitted | Succeeded, 22/22, 370/370 |
| `0AfAd00000T2P1dKAF` | #2 with its follow-up | Succeeded, 6/6, 369/369 |
| `0AfAd00000T2PhZKAV` | #1+#2+#3+#6 with every follow-up, plus #4, #5, #7 (no metadata) | Succeeded, 22/22, 371/371 |
| `0AfAd00000T2OlVKAV` | #8 on its own | Failed, "Cannot change type due to existing data" |
| `0AfAd00000T2P3FKAV` | Both volunteer test classes at deploy time | Succeeded, 25/25 |

**Local:** with every follow-up patch, the combined tree passes `npm test` (all nine suites) and regenerates with no drift.
