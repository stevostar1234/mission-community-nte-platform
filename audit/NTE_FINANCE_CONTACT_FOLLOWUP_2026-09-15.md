# Finance contact follow-up — 15 September 2026

Proposal 24 is implemented on both application forms. A separate finance person is preferred only when possible. The same name, email address and phone number may be entered for the main and finance contact.

Both forms now say: “Please provide the finance contact below, this should be different to the main contact if possible.” Existing required finance details, conditional visibility, separate Salesforce storage and primary-contact recipient routing are unchanged.

## Verification

- Four isolated form-engine submissions pass: exhibitor and partner/sponsor, each with Stripe and bank transfer, using identical main/finance name, email and phone. Transport was inert; no Lead, email or payment was created.
- Existing `tests/forms.test.js` passes; only its two old wording assertions needed updating.
- Shared form validation, billing-field handling, conversion mappings and Salesforce source contain no distinct-person validation. The current active Lead/Opportunity validation-rule inventory contains only `NTE_Interest_Decision_Exclusive`, `NTE_Intake_Event_Code` and `Volunteer_Code_Required`; none concerns finance contacts.
- All **594** qualified Salesforce source/manifest hashes remain unchanged from `NTE_SPACE_SELECTION_QUALIFICATION_2026-09-15.json`. No Salesforce deployment was needed. The earlier 422-test native qualification remains the backend evidence; no new native test run is claimed.
- Earlier public JavaScript history was checked: 23 distinct versions contained no direct finance-name/email/phone or distinct-person check. The old partner instruction did explicitly request a different person. Kate's exact reported warning was not reproduced; the owner confirmed no further investigation was needed once current behaviour worked.
- Recipient-copy search found no added reviewer, prototype or implementation commentary. The only public changes are the two guidance sentences.

## Publication

Canonical public preview commit: **617e2c5a06af41847a23767fba8860836573416a**. Both hosted HTML pages returned HTTP 200 and exactly matched the approved file hashes. The open partner form was refreshed and the new wording was verified in its rendered DOM. Shared JavaScript is unchanged.

| Form | Hosted source SHA-256 |
| --- | --- |
| exhibitor-application.html | `dd518151ba79d541f83fac2b08558ff0df5155c0e2d014daf8fa33fb9851ea4f` |
| partner-sponsor-application.html | `95881929c748030d1fbb848eeca6a120218d49235150f2e1a8dd0ee356ed9081` |

This source, the updated existing assertions and the workflow/handover documentation are included in the corresponding private `mission-community-nte-platform` follow-up commit. Production Salesforce, records and provider settings are unchanged.

Local evidence: `tmp/nte-finance-contact-20260915/` contains the four-case result, test log, active-rule inventory, unchanged-source comparison, reviewed publication diff and remote/hosted verification. Private publication is verified against the selected file manifest after commit; temporary files are not part of the repository.
