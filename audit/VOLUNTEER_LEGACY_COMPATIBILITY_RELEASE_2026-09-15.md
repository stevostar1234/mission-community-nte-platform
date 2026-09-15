# Volunteer legacy compatibility — 15 September 2026

Proposal 26 is implemented and verified in MMUAT. This extends the established volunteer data model while retaining historical information and the existing Mission record views. Production remains a separately authorised, target-derived release.

## Result

- The Volunteer Applications Lead list includes web form type, the existing volunteer flag or Volunteer Application source. The original Accounts Volunteers register continues to include Volunteer Person Accounts and other record types with the volunteer flag.
- Equivalent form answers retain their existing API fields. Fifteen new optional Contact destinations match the new Lead answer fields; Person Accounts use their standard `__pc` aliases. Two optional destinations preserve the volunteer declaration. No new information is required on historic records.
- All 25 existing native conversion mappings remain unchanged, with 15 answer mappings appended. Existing populated destination values are preserved; the submitted Lead retains the latest application for comparison. The conversion flow adds the volunteer role without reclassifying an existing beneficiary/donor and copies only volunteer declarations into blank volunteer destinations.
- Future volunteer form submissions leave Company blank for the existing Person Account route. NTE organisation applications are unchanged. Volunteers can convert without an Opportunity; the NTE-specific new-booking requirement does not apply to them.
- Optional volunteer sections were added to the three existing Lead/Contact/Person Account layouts and three applicable Account Lightning pages. Every original field, section, action and assignment is preserved. All seven page/layout/mapping definitions match the qualified native readback. NTE app pages and other app assignments remain unchanged.
- The owner declined a new permission-set assignment. A separate fresh-target overlay makes 34 answer/declaration fields readable/editable and three Lead email-status/error fields readable on Admin and Standard. All other retrieved profile settings are unchanged. The existing ten internal staff users are covered by these profiles; no new permission-set membership, sharing, object-access or guest/integration change was made.
- The owner explicitly retained Salesforce's standard semicolon display for multi-select fields. No custom display component or delimiter conversion was introduced.

## Qualification

Focused check `0AfAd00000SwL2LKAV` passed 28 components and 42 tests; actual deployment `0AfAd00000SwLiHKAV` used the same reviewed candidate. Full package check `0AfAd00000SwLwoKAF` passed **528 components / 429 Apex tests**, zero failures. The field-access check `0AfAd00000SwGXNKA3` and actual two-profile release `0AfAd00000SwUOzKAN` succeeded. Readback used the same full object scope as the baseline and confirms all unrelated profile settings are preserved.

The final local metadata rebuild is unchanged across **614 source/manifest hashes**. Form checks, six page-isolation tests and six volunteer compatibility tests pass. [Sanitised qualification and source hashes](VOLUNTEER_LEGACY_COMPATIBILITY_QUALIFICATION_2026-09-15.json).

Native before/after comparisons preserve all 22 original Profile settings apart from the later explicitly approved field access on two profiles. The platform automatically exposes new field/picklist metadata in retrieved Profiles and record types; original values remain. All applications are unchanged. The comparison also observed an unrelated Contact AllContacts list-column difference and an additional Lead_Record_Page1, neither present in this deployment. Those concurrent/platform changes were left alone.

## Fresh native and browser checks

Four fictional Leads exercise manual volunteer flag, legacy source-only, returning beneficiary and actual web submission. Two existing-style Person Accounts cover a legacy Volunteer with blank new fields and a returning beneficiary. One additional Person Account was created by the web Lead conversion.

- The manual flag-only and source-only Leads both appear in Volunteer Applications alongside web applicants.
- One actual Rowan Hazelwick public submission was made, without repeating it. Salesforce accepted its applicant and internal acknowledgements. This is acceptance evidence, not an inbox-delivery claim. Native conversion created a Volunteer Person Account with the submitted hours, opportunities, skills, region, availability, service answer, emergency details and declaration; no Opportunity was created.
- Daniel Mereford was converted into the existing Beneficiary Person Account. Its record type, established phone, date of birth, emergency-contact name and rich-text Skills Profile remain intact. Blank destinations receive new answers, the volunteer role is set and no Opportunity is created.
- The old-style Amelia Calverley Volunteer record displays the additional optional sections with blank answers. Its existing information remains present.
- The native Accounts Volunteers list visibly includes Amelia, Daniel and Rowan, proving both record-type and overlapping-role routes. The Mission pages visibly display the new fields. Standard semicolon rendering remains.

All **2,043 pre-existing active records** retain their IDs and modification timestamps, with no deletions: 304 Leads, 781 Accounts, 872 Contacts, 28 Opportunities and 58 Tasks. Five Leads appeared during the work: four allocated fictional cases and one independent submission, left untouched. No Opportunities or Tasks were added. Preserve these once-only results and fixtures; do not rerun submissions or conversions from older setup scripts.

The volunteer form change was published as `cc34220cddb26bf6a86754177f9a910af3b6e7da` and hosted bytes verified. Kate's subsequent form-opening-only publication is separately recorded in [the introduction release](NTE_APPLICATION_INTRODUCTIONS_2026-09-15.md).

## Production handover

Follow [the target-derived extension guide](../deployment/VOLUNTEER_LEGACY_EXTENSION.md). Do not place copied MMUAT business layouts, pages, Profiles or LeadConvertSettings into the NTE core deployment. Retrieve and extend production's current definitions, preserving its assignments and mappings.

For a new Person Account, staff choose the existing Volunteer record type and no Opportunity. Existing role/record-type defaults are not changed globally. Earlier Leads with the old Individual Volunteer Company placeholder remain untouched; clear that placeholder on the individual Lead if using the Person Account conversion route. Real organisation names must not be cleared automatically.

Local raw evidence is retained under `tmp/volunteer-compatibility-implementation-20260915/`; it is excluded from GitHub. No historical volunteer data was backfilled, reclassified or removed, and no production deployment occurred.
