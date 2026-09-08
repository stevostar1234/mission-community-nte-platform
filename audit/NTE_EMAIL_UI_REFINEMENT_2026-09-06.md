# NTE email UI and enduring application links

6 September 2026. Approved by the project owner through the annotated Master Panel request. This is an internal release record.

## Result

The shared invitation, reminder and final-pack composer now has a compact recipient list with one selected/available counter in a blue box beside it. Gold Select all, red Clear and blue Refresh are separate buttons outside the blue box, following the owner's visual follow-up. The editor and preview align. The header and Send footer remain outside the content's scrolling region.

Removed the repeated header/footer recipient summaries, instructional paragraphs, raw recipient-row URLs, event-code/reference row, duplicate preview address/destination, personalisation-token paragraph, preview heading, header kicker and duplicate Cancel control. Close and Escape remain available; field labels, recipient eligibility issues, prior-send details and actionable status/errors remain.

The Interests toolbar uses **Send to all** and preselects all eligible interests matching the current event/time/owner/view filters. Each row's **Send Application** opens only that interest. Refresh retains the reviewed selection and edited message; opening a composer does not queue or send an email.

Application invitations route to the configured exhibitor or partner/sponsor URL independently of event year. Future-year sandbox interests are eligible when all other requirements are met. Missing, malformed or non-HTTPS links still block sending. The final-pack year guard remains; the existing `Application_Event_Code__c` API name is retained and its label is now **Final Pack Event Code**.

## Confirmed maintenance rule

The client intends stable form URLs on its NTE website, updating content at those destinations each year. The current GitHub preview URLs remain in MMUAT until final client URLs arrive. The form's edition configuration determines the event assigned to a submission; reusing the invitation URL does not copy the inviting Lead's event into that submission. Annual dates, wording and pricing still require review.

This clarification is recorded in `NTE_DESIRED_WORKFLOW.md`, `NTE_CHANGE_PROPOSALS.md` and `FUTURE_NTE_MAINTENANCE.md`. The preference for sleek interfaces and minimal explanatory copy is saved in both the project `AGENTS.md` and `/Users/stevo/.codex/AGENTS.md`.

## Verification

- `npm run validate` passed, including generation and existing form/package checks. All 410 XML files parsed. The existing minimum text-size check was respected.
- Full MMUAT deployment `0AfAd00000Snvt3KAB`: 410/410 components and 163/163 Apex tests passed.
- Browser verification found a cramped Refresh label at 375px. A responsive CSS adjustment was deployed as `0AfAd00000SnvrSKAR` (1/1 LWC bundle). Rechecked in the browser: all three buttons had 88px client/scroll widths, with no label overflow.
- The owner's follow-up to separate the buttons from the counter box was deployed as `0AfAd00000Snu5mKAB` (1/1 component). At 1082 × 911, the blue counter ended at y=203.563px and the separate button group began at y=216.359px; the surrounding controls had a transparent background. At 375px, all three buttons had matching 97px client/scroll widths with no label overflow. The viewport override was reset.
- Final full-manifest check-only validation `0AfAd00000SnwQvKAJ`: 410/410 components and 163/163 tests passed. All manifest components appeared in the successful component list, and all 464 final source-file hashes still match the validated snapshot.
- Browser checks: six NTE2030 interests opened preselected, with no former event-link rejection; Clear produced zero selected and disabled Send; Select all and individual deselection worked; Refresh preserved five selected recipients and an edited subject. A single exhibitor's Send Application opened one selected recipient with the exhibitor destination; a partner invitation preview used the partner/sponsor destination. Staff reminders opened with three eligible recipients and the staff-update destination.
- At the normal 936 × 911 viewport, editor and preview both started at y=347.984px. Scrolling content from 0 to 203.5px left the Send footer unchanged at y=824.445–886px. At 375 × 811, the footer remained within the viewport, ending at y=798px. The temporary viewport override was reset.
- Keyboard checks: Tab from Send returned focus to Close; Escape closed the composer. The updated bulk invitation composer was left open with its normal selection defaults for the owner to review.
- No browser emails were sent, no forms were submitted and no genuine legacy contact/account was modified. The added routing tests use isolated synthetic records and bypass external delivery. This is a focused application-link regression check, not the declined unrelated-legacy conversion test project.

## Source and release evidence

Six Salesforce source files changed relative to the prior deployed snapshot: `NTEEmailDispatchService.cls`, its test class, the three `nteMasterPanel` files, and the routing field label metadata. The field label is also maintained in `scripts/build-communications.js`. No manifest additions were required.

Machine-readable results are under `tmp/nte-email-ui-20260906/`: organisation check, both deployment reports, final validation report, local validation logs, source hashes and `release-results.json`.

The public forms and email examples did not change in this refinement. All 21 files from the previous published update still match the verified hashes for preview commit `a355fb8c1b5985061fb74e57d3a88d56c72a055e`; no additional website publication was needed. Routine publication remains authorised whenever those files change.

Production Salesforce, the future client-hosted production website and Stripe remain separate releases. Final-pack content/links remain awaited.
