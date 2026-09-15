# NTE app-specific record views — 15 September 2026

## Confirmed decision

The app selects the page. A person or organisation can participate in both Mission and NTE: NTE Management shows the NTE record pages, while Mission, Mission Community and other apps keep their existing business views. Do not infer the page from the submission type, volunteer status or NTE participation. No new record type or classification change is required.

Proposal 25 authorises correction in MMUAT and production preparation. Production deployment remains separately authorised and has not been performed.

## Cause and bounded correction

The current NTE package already assigns its Lead, Account, Contact and Opportunity pages only to `NTE_Management`, for desktop and phone. It does not contain Profiles, standard-object root definitions or shared business layouts.

The volunteer problem came from older sandbox Lead assignments:

- The global Lead View override selected `Lead_Record_Page`, whose Dynamic Forms included **Mission Community Lead**, **Sponsor Application** and **Exhibition Requirements**. The page pre-dates the current app work: created 21 July and last modified 6 August 2026. Its appearance was reproduced on the newly submitted volunteer in the Mission app before correction.
- `Mission_Community_Partnerships` also selected the older `Mission_Community_Lead_Record_Page` through two app overrides and 22 profile-specific overrides.

The two global Lead overrides and the 24 Mission Community Lead overrides were returned to **Default**. Salesforce now uses the existing assigned Lead layout outside the NTE app. Every other object/app setting was preserved. No layout, Lightning page definition, Profile, record type, field or business record was edited. The form-based fallback considered during investigation was declined by the owner and removed before deployment; the metadata generator is unchanged.

The original Lead layout already contains personal/service, next-of-kin, medical/accessibility, volunteering/interests and consent fields. Its 37 fields were retained as-is. No replacement volunteer layout was invented.

## Release and preservation evidence

- Full native before/after retrieval: 881 files each, including 33 apps, 38 Lightning pages, 136 layouts and 22 Profiles.
- Salesforce check-only **`0AfAd00000SwDRNKA3`**: succeeded, two components, zero errors.
- Actual MMUAT deployment **`0AfAd00000SwDsnKAF`**: succeeded, two components, zero errors. No Apex changed; this UI-only release used `NoTestRun`.
- All **136 layouts**, **38 page definitions** and **22 full Profile definitions** match the before snapshot. All other apps match, including NTE Management and Mission. The existing Account, Contact and Opportunity default assignments match.
- The protected comparison covers **225 shared definitions** and reports exactly the two intended changes: the Lead object view settings and the Mission Community app. It reports no added or missing definitions. Unrelated children of those two changed components also compare identically. This deliberate sandbox exception does not relax the zero-shared-change requirement for production.
- NTE Management and its five page definitions remain byte-identical. All **594 qualified Salesforce source/manifest hashes** from the earlier 422-test release still match. Those tests were not claimed as a new run for this repair.
- Form tests and all six new page-preservation test methods pass. Negative cases reject shared source/manifest components, wildcards, incorrect object/page assignments and changed or incomplete target baselines.

Raw native backups and the two sandbox repair files are retained locally in `tmp/nte-layout-isolation-20260915/`. They are excluded from production source and from the public website. Do not replay the repair or deploy its native app/object files into production.

## Browser verification

The actual Salesforce App Launcher was used to establish app context; metadata IDs embedded in direct app URLs were not treated as proof of the selected app. A pre-deployment tab initially retained the old page after reload; a fresh record view displayed the new native assignment. The completed checks use the visible app heading and rendered field/section labels.

- The same volunteer Lead in **Mission** and **Mission Community** shows the existing personal, service, next-of-kin, medical, volunteering/interests and consent details, with the old sponsor/exhibition sections absent.
- The same Lead in **NTE Management** shows the NTE submission, contacts, application, pricing, invoicing/procurement and logistics sections. Its form type and stored data were not changed.
- The existing E2E Account in **Mission** retains the original Partner page, including Partner Type, CIC Number, Sponsorship Level and Support Type.
- The associated Contact in **Mission** retains its original contact, role, communication and address fields.
- The associated Opportunity in **Mission** retains its original opportunity, stage, close date, amount, sales qualification and description fields.
- The same Account and Contact in **NTE Management** show their NTE participation sections. The same Opportunity in **NTE Management** shows booking/commercial status, event contacts, space, pricing, procurement, finance/payments, logistics and correspondence sections.

Existing historical Account sponsorship fields, including the client's earlier NTE-year fields, remain in the original business metadata. Preserving their existing layouts takes precedence over removing every historical field whose name contains NTE. Current NTE application/booking sections are confined to the NTE app pages.

## Production protection

[`scripts/check-nte-page-isolation.py`](../scripts/check-nte-page-isolation.py) checks both the complete candidate manifest and the source directory. It allows only the NTE app, its five pages and the two layouts for newly introduced NTE objects, and rejects shared object root definitions, Profiles, compact layouts, other apps and other pages. This also protects against an accidental source-directory deployment that includes files omitted from the manifest.

The required production process captures the actual target's existing apps, pages, layouts, Profile assignments and object defaults before deployment and compares a fresh retrieval afterward. Existing shared definitions must not change. This check and the app/object UI checks must be performed against the separately configured production candidate; MMUAT results do not certify an uninspected production org.

See [the production page-preservation instructions](../deployment/NTE_PAGE_ISOLATION.md) and [the sanitised qualification result](NTE_APP_PAGE_ISOLATION_QUALIFICATION_2026-09-15.json). No public form publication, new test record, conversion, email, payment or production deployment was required by this follow-up.
