# Mission Motorsport volunteer follow-up — 10 September 2026

The owner asked to implement Tony’s latest emailed corrections and explicitly excluded branding. Tony’s 08:37 UTC email supplied `Mission Motorsport - Volunteer Code of Conduct.docx`; his 08:40 UTC follow-up clarified **Hours willing to give per month**. The earlier requirement to preserve the form’s style remains in force.

## Implemented scope

- The Availability legend, required-answer message, existing Salesforce hours field label and team notification now specify **per month**. The five range values, selection rules and field ID are unchanged.
- Section 6 contains a collapsible Code of Conduct reader. All 101 supplied body paragraphs, including the declaration and original paper-signature text, are retained in order, with the September 2026 version. The reader uses the existing palette, borders and typography; all added CSS is scoped to this new control. The global stylesheet and existing logo are unchanged.
- The reader has native keyboard/touch scrolling and a labelled, focusable region. Its required acknowledgement starts disabled and unchecked. Opening and reaching the end enables it without ticking it. Submission requires a separate explicit tick; partial scrolling, closed/zero-height readers, restored ticks and disabled-control manipulation cannot pass the ordinary form validator. A fully visible document still requires opening. Reopening an already completed reader retains the deliberate tick; form reset clears it.
- New Lead fields `Volunteer_Code_Consent__c` and `Volunteer_Code_Version__c` store the acknowledgement and `September 2026`. The current form identifies itself as `volunteer-application-v3`. A native validation rule rejects new v3 volunteer applications with missing consent or a missing/wrong document version. It does not require retrospective consent from historical applications.
- Native field definitions confirm the monthly label, Checkbox acknowledgement and Text(80) version, and the form uses the actual deployed field IDs. The field generator, volunteer permission set, native email HTML/plain text, tests and complete production manifest contain the same change. Production Salesforce deployment is not authorised or performed.
- Branding guidelines were excluded; no branding attachment was downloaded or used. Email routes, previous volunteer choices/address behaviour and the separate NTE client-revision/cleanup changes are preserved.

## Source and content fidelity

Original DOCX SHA256: `ac4d85765e6726e86b1385fee18f4875cd66163210b15123e266bf3b18a2c939` (94,108 bytes). The original is retained under `audit/backups/2026-09-10-volunteer-code-of-conduct/`. It has no tracked changes or tables. All six rendered pages were inspected using the bundled document runtime. The attachment’s policy wording was transcribed, not rewritten. `config/volunteer-code-of-conduct.json` records the source paragraphs and hash; the form tests assert exact paragraph order/text and matching version. The repeated page furniture appears once in the reader.

Email evidence: Gmail thread `1a08a779410beda7`; document message `1a08a779410beda7`; monthly-hours clarification `1a08a7a13d902ae6`. No reply was sent.

## Verification and release

- `npm run validate` passes; a post-ID `npm test` passes with both actual MMUAT field mappings.
- The isolated form engine passes **139 checks, zero failures**, retaining **34,986** catalogue/boundary combinations across all ten forms. Eight new checks cover the consent reader and submission behaviour. These are isolated DOM/transport checks, not a claim of browser/device visual testing.
- Actual MMUAT deployment **`0AfAd00000SrqQCKAZ`** succeeded at **2026-09-10T10:26:08.000Z**, **7/7 components and 18/18 focused Apex tests**, zero errors. The test stores acknowledgement/version and renders the real stored team email in HTML/plain text, including the monthly label, with zero sends or DML during rendering. Two new native tests cover rejected consent/version combinations and unchanged legacy applications; test records roll back.
- Full-manifest check-only **`0AfAd00000Ss3X3KAJ`** succeeded at **2026-09-10T10:33:19.000Z**: **469/469 components and 304/304 RunLocalTests**, zero errors. All **469 unique manifest members** and **533 canonical source/manifest hashes** reconcile, with no source changes during validation. Aggregate SHA256 `39f123aacee3f888ba0dc8443ca5a6814e9c28d1bb46dd33daab94a5427db96a`. [Exact qualification](VOLUNTEER_CODE_OF_CONDUCT_QUALIFICATION_2026-09-10.json).
- Canonical preview commit **`39f5d35215b5c9f7d563f2c49b10c16e7e0f229e`** contains exactly six intended files, prepared from remote main `3f3af51111acea1fdf29b9fce70805d9bb8f8521`. [Pages deployment](https://github.com/stevostar1234/nte27-web-to-lead-demo/actions/runs/34466239405) completed successfully. At **2026-09-10T10:30:19.568877+00:00**, **10/10** targeted hosted files byte-matched both the local source and isolated checkout: six changed files plus the unchanged global stylesheet, logo, volunteer thank-you page and applicant email example. [Published form](https://stevostar1234.github.io/nte27-web-to-lead-demo/volunteer-application.html).

Private execution evidence remains in ignored `tmp/volunteer-conduct-20260910`. No live form submissions, operational email sends, historical journey replays or fixture cleanup occurred.

## Practical limit

Reaching the end is an interaction requirement; it cannot prove that somebody read or understood the document. Like other values in the existing public Web-to-Lead interface, a determined caller can forge a direct request or identify it as an older form version. The UI and scoped native validation enforce this version’s ordinary submission flow without disrupting historical records. The owner’s branding clarification remains separate.

## Later owner correction — paper-signature section removed

The owner explicitly requested removing the eight final paper-signature paragraphs, from “Volunteer Name” through the Mission Motorsport countersignature/date. The reader now ends after the three Volunteer Declaration statements. All 93 remaining document paragraphs, the acknowledgement, scroll gate and digital form signature are retained. The supplied source DOCX remains untouched; the source JSON retains all 101 original paragraphs and marks the eight authorised omissions. The existing paragraph-parity assertion now follows those omissions.

`npm test` and all **8 focused conduct checks** pass. Canonical preview **`5fb41927a9e301aab921894af101891602ad72e6`**, based on latest remote **`24da51ef84e51f0b3bea7d12cc9eb4d8929b1a8d`**, changes only `volunteer-application.html` (eight deletions). [Pages deployment](https://github.com/stevostar1234/nte27-web-to-lead-demo/actions/runs/34474750662) succeeded; **6/6** served page/assets match at **2026-09-10T12:06:37.593305+00:00**. [Exact follow-up verification](VOLUNTEER_CODE_OF_CONDUCT_TRIM_2026-09-10.json). This text-only correction required no Salesforce change or new native deployment. No submissions, emails, fixtures, styling or branding were changed. The original release qualification above remains dated evidence.
