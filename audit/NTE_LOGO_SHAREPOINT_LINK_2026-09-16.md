# Logo SharePoint link — 16 September 2026

Proposal 29 is complete. Laura Westrope’s email of 16 September, 13:58 UTC, supplied the new SharePoint file-request URL. The owner explicitly requested adding it to the logo form. The superseded folder link inside the quoted August correspondence was not used.

The existing `logoFileRequestUrl` configuration now contains the supplied URL. The logo form opens it in a separate tab with an accessible label, preserving the original form for the existing unsigned booking-reference confirmation. Its configuration asset version is refreshed. Salesforce emails continue directing applicants to the logo form; no email template, Salesforce field, workflow, sharing permission or business record was changed. The supplied 113-character URL fits the existing 255-character Lead field used by application forms.

Only `assets/config.js` and `logo-upload.html` were published to the canonical forms repository, based on fresh remote commit `1267cc056930c567d3bcf28d6dff05f1c45e16b1`. Release commit: `1b071a50bd4221d5d76519fed85ff7a5a910f948`. Both hosted files match the maintained source byte-for-byte. Source and release notes are also retained in the existing private project repository for the production handover.

Verification: the existing form suite passes; the live button is enabled with the exact supplied URL and no form console errors or warnings. Clicking it in Chrome opens a new SharePoint tab titled **Exhibitor and Sponsor Logos**, with **Select files** visible and no sign-in prompt. The original confirmation form stays open. Direct navigation in the in-app browser also reached the guest file request; that browser did not expose the new tab after clicking, so Chrome provided the actual new-tab verification.

No file was uploaded and no confirmation was submitted. These checks establish the working upload handoff and guest landing page, not storage of a real applicant file. Historical sandbox journey results and the separately qualified Salesforce source remain unchanged. Final production form hosting is still a separate client dependency.

[Structured evidence](NTE_LOGO_SHAREPOINT_LINK_2026-09-16.json). [Published logo form](https://stevostar1234.github.io/nte27-web-to-lead-demo/logo-upload.html).
