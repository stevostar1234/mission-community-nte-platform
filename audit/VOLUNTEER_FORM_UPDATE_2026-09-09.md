# Mission Motorsport volunteer form update — 9 September 2026

The owner approved the changes in the forwarded client email and explicitly required preservation of the existing style. The revised form and its connected Salesforce fields are implemented in MMUAT, and the canonical preview is published. The wider package check is complete with zero errors.

## Delivered scope

- Section 2 now has an emergency-contact address/postcode and a same-as-mine checkbox. Selecting it submits the latest applicant address; deselecting it restores previously typed separate details. Hidden fields cannot submit stale or duplicate addresses.
- Section 4 adds Marshalling to both opportunities and skills, replaces the shop choice with Pop up shop, and uses Transport and Logistics with Car, van with trailer, minibus below it, matching the existing professional-skills treatment.
- New section 5 is Availability, with all five requested hours choices and Weekdays / Weekends / Any. Hours is a single choice using the existing checkbox cards; preferred days can be combined, with Any exclusive. Both questions require an answer. The client did not specify a time period, so the form does not invent one.
- Privacy and declaration is section 6; its content and consent behaviour are unchanged.
- Four new Lead fields capture the answers: NOK_Address__c, NOK_Postcode__c, Volunteer_Hours__c and Volunteer_Availability__c. The generator, volunteer permission set and production manifest include them. Old transport/shop values remain inactive to preserve saved history.
- The team notification includes hours and preference. Both volunteer email examples reflect the revised choices. Email design, routing and acknowledgement count are unchanged.
- Both stylesheets and the official Mission Motorsport logo are byte-identical to the previous published files. The form uses the existing grid, choice cards and section headings. No unrelated page source changed.

## Validation and publication

- `npm run validate` passes with the deployed field IDs in the form configuration.
- Maintained form-engine verification: **132 checks passed, zero failed**, including nine new behaviour checks for the emergency address, form restoration, value limits, exclusive choices and exact outgoing Salesforce values. Existing pricing/boundary coverage remains **34,986 combinations**. These run against an isolated DOM/transport fixture; no live Web-to-Lead submission occurs.
- Actual MMUAT deployment **0AfAd00000Sr5RIKAZ** succeeded at **2026-09-09T15:05:37.000Z**, **9/9 components and 16/16 focused Apex tests**, zero errors. The new native test saves the revised values in an isolated, rolled-back test record and renders the real stored team template in both HTML and plain text. The render asserts zero email invocations and zero DML statements, with all requested values and no unresolved merge markers.
- Full production-manifest check-only **0AfAd00000SrFnBKAV** succeeded at **2026-09-09T15:13:43.000Z**: **468/468 components and 299/299 RunLocalTests**, zero errors. All 468 expected member identities and 534 canonical source/manifest hashes reconcile, with no source changes during validation. [Exact qualification](VOLUNTEER_FORM_QUALIFICATION_2026-09-09.json).
- Canonical preview commit **7911fc465ced1b555790f7a68eeb7ccc9a537eda**, prepared from the latest remote main, changes exactly six intended website files. [Pages run](https://github.com/stevostar1234/nte27-web-to-lead-demo/actions/runs/34368247106) completed successfully. At **2026-09-09T15:09:50.886333+00:00**, **9/9** served files matched local source and the isolated checkout: the six changed files plus the two unchanged stylesheets and logo.
- [Published volunteer form](https://stevostar1234.github.io/nte27-web-to-lead-demo/volunteer-application.html).

Private execution evidence is retained under ignored `tmp/volunteer-update-20260909`, including the incremental diff, deployment reports, form results, field IDs, source hashes and hosted byte verification. The first CLI deployment invocation was rejected locally because this installed version requires a positive `--wait`; `--async` then started the single actual deployment above. The first hosted check encountered Python’s missing CA chain; verification succeeded using the system trust store. Neither caused a duplicate submission, email or deployment.

## Awaited inputs and limits

The Code of Conduct is not supplied. The requested open-and-scroll acknowledgement can be enabled when its actual content arrives, using an accessible reader with keyboard/touch scrolling and an acknowledgement that unlocks at the end. Reaching the end does not prove reading. No placeholder policy or blocking empty document was added. The technical basis is the [documented scroll-to-enable pattern](https://developer.mozilla.org/en-US/docs/Web/API/Element/scrollHeight#checking_that_the_user_has_read_a_text).

The owner will clarify the logo/branding request. No new branding is selected. No fresh live form submission, actual email, historical-record update, payment, production Salesforce deployment or unrelated P/U decision was performed. Existing successful audit and Stripe journeys are preserved. Visual/browser device testing was not repeated; preservation is verified through unchanged stylesheet/brand bytes, existing layout classes and the focused form-engine checks.
