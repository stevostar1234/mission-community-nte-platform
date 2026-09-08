# NTE workflow implementation — 5 September 2026

Governing decisions: [desired workflow](../NTE_DESIRED_WORKFLOW.md) and [approval register](../NTE_CHANGE_PROPOSALS.md). This is internal release evidence, not applicant-facing copy.

## Scope

Approved proposals 1–10 are implemented in source. Proposal 9 uses **Send Application** and **Reject**; there is no manual already-invited action. Proposal 7 is enforced in Salesforce with explanatory static-form copy. Stripe integration (11) remains on hold and the separate payment-confirmation email (12) is not enabled.

- Receipts acknowledge applications under review. Conversion queues an explicit booking request after commit; both participant types receive their provisional booking details and preparation links through the single coordinator. Payment/price instructions continue through the manual process until Stripe is integrated.
- The Master Panel and all booking communications use the Opportunity's Primary Contact. Event-day information remains separate. Missing or ambiguous primary contacts prevent sending.
- Staff, vehicle and logo updates preserve established contacts. Valid vehicle submissions replace the logistics details. A first valid positive staff top-up locks further purchases while allowing name corrections and preserving financial history. The original booking and top-up have separate invoice/payment actions and refiners.
- Completion, counters, update views and pack eligibility include the logo requirement.
- The shared email service provides HTML and plaintext, editable safe text, actual recipient selection and preview, asynchronous batches of 40 for selections up to 500, saved individual outcomes, duplicate prevention and failed-only retries. Queuing and execution recheck the reviewed recipient, destination, event and eligibility.
- Invitations mark Progressed only after Salesforce accepts the send. Final-pack history survives reopened readiness. Failed supplementary acknowledgements retain the accepted update and can retry the email without reapplying the form.

## Configuration still required

`NTE_Routing_Config.Default` has the following settings:

| Setting | Current purpose/state |
| --- | --- |
| `Application_Event_Code__c` | `NTE2027`; guards both invitations and final packs. Update alongside event-specific destinations for future events. |
| `Exhibitor_Application_URL__c` | Existing exhibitor application on the authorised client review site. |
| `Partner_Application_URL__c` | Existing partner/sponsor application on the authorised client review site. |
| `Exhibitor_Final_Pack_URL__c` | Blank pending approved client content/link. |
| `Partner_Final_Pack_URL__c` | Blank pending approved client content/link. |

The final-pack tool is implemented but a missing valid destination makes affected recipients ineligible. Existing staff/heavy/logo form routing is retained. The final SharePoint logo-upload location, final NTE-hosted form destinations and Stripe account/document/tax decisions remain client dependencies.

## Verification

- Verified CLI target `mission-mmuat`: organisation `00DAd00000A95VlMAJ`, `IsSandbox = true`.
- `npm run validate`: passed; source templates, generated Salesforce email files and client examples are consistent.
- `git diff --check`: passed. Metadata XML parses successfully.
- Final full MMUAT deployment `0AfAd00000Snlk1KAB` succeeded: **410/410 components and 162/162 Apex tests**. The matching final check-only run `0AfAd00000SnlldKAB` also passed **410/410 and 162/162**.
- Browser verification found and resolved an input-serialization problem not exercised by direct Apex calls: the invitation preview received an empty draft type. Preview and send now share an explicit, size-limited JSON request boundary with strict deserialization and unchanged recipient revalidation. Three additional Apex tests cover valid browser payloads, malformed/oversized/unknown fields and changed recipients. The corrected HTML preview and edited subject were verified in MMUAT.
- All 464 Salesforce source file hashes match the snapshot used for the successful final deployment. No Salesforce source changed after that deployment began.
- Tests use synthetic records and Salesforce's isolated Apex test execution. No real legacy recipient was used for a test send, and no existing booking data was migrated.
- Existing unrelated working-tree changes were preserved. No production deployment, Stripe connection, payment transaction or new access restriction is included.

## Client review site

The canonical forms remote is `origin`, `stevostar1234/nte27-web-to-lead-demo`. This publication was prepared from remote `main` at `4ef753514a3cc506f5213d7a50f7cb5a74c7306b`. The Salesforce package uses the separate `package` remote.

The owner subsequently authorised publishing these updates and keeping the existing preview site current whenever relevant approved changes are made. [The forms-only patch](NTE_CLIENT_PREVIEW_UPDATE_2026-09-05.patch) was applied to a clean checkout of that verified client-site commit. The release preserves unrelated content and excludes the Salesforce package.

Published commit: [`a355fb8c1b5985061fb74e57d3a88d56c72a055e`](https://github.com/stevostar1234/nte27-web-to-lead-demo/commit/a355fb8c1b5985061fb74e57d3a88d56c72a055e). It updates 21 form/email HTML files plus the repository's internal publication guidance. GitHub Pages reported `built` for this exact commit at 20:56:57 UTC on 5 September 2026. All 21 changed HTML files were fetched from their usual hosted URLs and matched the approved source byte for byte; relative links and assets were checked before publication.

The standing publication permission is recorded in the desired workflow, maintenance guide and both repositories' `AGENTS.md` instructions. Future relevant changes include publication and hosted verification in the same task, without another routine publication question.

## Release result

Approved proposals 1–10 are deployed to MMUAT and pass the full package release checks. The matching client preview forms and email examples are now published and verified. Production deployment remains a separate release step. Final-pack distribution remains unavailable until valid client destinations are configured; Stripe remains on hold.

Browser checks already confirmed:

- Interests expose Send Application / Reject. Both routes were verified with example-address interests: Silverstone Community Fund receives the partner/sponsor application and Beacon Technical College receives the exhibitor application. Their HTML previews personalise the name and organisation and render the correct action button. Editing a subject refreshes the displayed HTML and enables sending only after the new preview succeeds.
- Finances show independent initial and staff top-up invoice/payment refiners.
- Primary contact and Event day contact are separately labelled.
- Updates include logistics, staff and logo refiners. Applying the agreed logo requirement changes NTE2027 Completed from 17 to 5 without modifying booking data.
- Remind All loads the 30 staff-due recipients and displays personalised HTML with the booking reference and correct participant-type staff link. Clearing the selection disables sending and removes the preview; selecting one visible checkbox restores the corresponding preview. Keyboard Space also changes selection and disables sending when the last selected recipient is removed. The initial automation attempt targeted the styled native input; the visible label and keyboard controls work without a code change.
- Completed shows Final pack not sent / Final pack sent. All five eligible bookings are excluded from sending while the required pack links are blank; the send button remains disabled.
- Email activity opens and reports the saved state. No Send, Reject, Retry or finance mutation was executed through the browser.

Salesforce's [LWC Apex method guidance](https://developer.salesforce.com/docs/platform/lwc/guide/apex-expose-method.html) documents that inner-class request parameters are unsupported. The browser result, not only compilation and Apex unit tests, is the acceptance check for the corrected transport.
