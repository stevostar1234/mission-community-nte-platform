# Volunteer service choices — 17 September 2026

Proposal 30 is complete. Tony’s emails at 08:31 and 09:01 UTC request four service checkboxes and confirm removal of the “Service, unit, station or ship” text box. The owner authorised this change.

After a Yes answer to served/currently serving, the form now offers **British Army**, **Royal Navy**, **Royal Air Force** and **Royal Marines**. Multiple selections are allowed. Service details retain their previous optional status and Dates in Service remains. Choosing No hides and disables these controls, excluding stale selections from the submitted values; returning to Yes restores the applicant’s choices.

Selected labels use the existing `Volunteer_Service_Details__c` field, serialised with the existing semicolon convention. Its Lead/Contact LongTextArea definition and native conversion mapping are unchanged, so historical free text and existing page visibility are preserved. The 53-character all-services value fits the 1,000-character field. No new field, Salesforce deployment, data change or backfill was needed. The current v3 form identifier and Code of Conduct validation remain unchanged; Tony’s separate final wording sign-off remains a client dependency.

Only `volunteer-application.html` changed in the canonical public repository, based on `1b071a50bd4221d5d76519fed85ff7a5a910f948`. Published commit `a0bd0812dd250f877a90a38a64183b371e246538` completed Pages run `35205984842` successfully. Hosted HTML matches source SHA256 `3499499839265954214fc2b6d413f844f1325ce2fd1affd75dff3f5e6909643a`.

Verification: the existing form suite passes; 26 focused volunteer form-engine checks and six compatibility checks pass. An inert local DOM probe passes all 16 selection combinations plus Yes→No and Yes→No→Yes, including exact existing-field payload values and retained service dates. The live browser shows all four choices, accepts British Army plus Royal Marines together, and hides/disables all choices on No. Desktop layout and the absence of page warnings/errors were checked. No live application, consent or email was submitted. Native conversion was not rerun for this HTML-only change; the unchanged mapping retains its separate 15 September qualification.

[Structured evidence](VOLUNTEER_SERVICE_CHOICES_2026-09-17.json). [Published volunteer form](https://stevostar1234.github.io/nte27-web-to-lead-demo/volunteer-application.html).
