# Extend the existing volunteer model

This is an additive, target-specific volunteer release approved under proposal 26. MMUAT is qualified; production deployment requires its own authorisation and a fresh target comparison. Never deploy copied sandbox business layouts or Profiles as part of the NTE core package.

## Data and conversion

The form retains the established Lead fields for names, contact details, address, date of birth, next of kin, volunteering and consent. New questions remain optional in Salesforce, so historical records can keep them blank. Existing structured military/service fields and the rich-text Skills Profile retain their original meanings and API names.

Fifteen new answer destinations are on Contact, exposed on Person Accounts through the corresponding `__pc` aliases. Two further Contact fields hold the volunteer declaration name/date. No duplicate Account fields are required. The native Lead mappings append the fifteen answer mappings to the target's existing configuration. The scoped `Volunteer_Conversion_Details` flow adds the volunteer role and copies declaration evidence into blank volunteer destinations only on conversion of an eligible volunteer application. It does not copy NTE declarations.

Native conversion preserves populated destination fields during reuse. A returning applicant's new submission remains on the converted Lead; staff should compare it before manually changing established details. No backfill, old-record rewrite or automatic record-type change is performed.

Future volunteer web submissions leave Company blank, enabling the native Person Account route. NTE organisation applications still supply Company. For a new volunteer, choose **Volunteer** as the Person Account record type and select **Don't create an opportunity upon conversion**. Reusing an existing beneficiary or donor preserves that record type and adds the volunteer role. Salesforce may initially show another record type according to the user's existing defaults; this release does not change global defaults.

Earlier volunteer web Leads with the former **Individual Volunteer** Company value are unchanged. If the team wants to convert one through the Person Account route, clear that placeholder on the individual Lead first. Do not automatically clear real organisation names.

## Lists and access

**Volunteer Applications** on Lead includes form type Volunteer Application, the existing Volunteering flag, or Lead Source Volunteer Application. The existing Accounts **Volunteers** register already includes the Volunteer Person Account type or the Volunteer flag and is preserved.

The owner chose visibility through the existing staff profiles, without assigning another permission set. MMUAT's **Admin** and **Standard** profiles now expose the 34 optional answer/declaration fields for reading and editing, plus three read-only Lead email-status/error fields. All other settings are preserved. Record sharing, object permissions, app access, guest/integration access and permission-set memberships are unchanged. Open record sharing alone does not provide field visibility.

For production, retrieve the actual internal staff profiles and field definitions, then prepare the separate, additive field-access candidate with `scripts/build-volunteer-profile-access.py --source /path/to/fresh-target/force-app/main/default --output /path/to/empty-access-candidate --profiles <approved-existing-profile-names>`. Review the exact field changes and qualify that candidate separately. Never copy the sandbox profile files into production. Existing **Volunteer Applications User** remains compatible for its current assignees or a later access model; this release does not require a new assignment. Native conversion permissions and Person Account record-type access remain governed by existing staff access.

## Preserve the actual target's pages

1. Retrieve the target's current Lead/Contact/Person Account layouts, applicable Account Lightning pages, native LeadConvertSettings, field definitions and existing Account record types. Capture current app and Profile assignments before preparing changes.
2. Confirm the existing Volunteer Person Account type and equivalent fields. Add only missing optional destinations; if a target already has a same-named field, compare its meaning and definition before deploying it. Check the target's established conversion maps rather than assuming MMUAT's count or configuration.
3. Run `scripts/build-volunteer-overlay.py` with the fresh metadata folder, Account RecordType query JSON and a reviewed target-specific configuration. Use an empty output directory. The default names match MMUAT; they are not a universal production prescription.
4. Inspect the separate candidate. It appends missing fields in grouped volunteer sections and preserves every existing section, action and assignment. Existing Account Dynamic Forms receive volunteer sections visible for the Volunteer type or volunteer flag. The tool stops on mapping conflicts or an ambiguous Details tab.
5. Keep the overlay separate from `manifest/production-package.xml`. The core NTE isolation checks must continue to pass. Validate the exact core plus reviewed overlay in the authorised target, including `VolunteerCompatibilityTest` and the relevant existing tests.
6. Compare native readback against the saved baseline. Refresh Salesforce before visual checks so cached layouts are replaced. Verify an old-style record with blank new answers, a new web application, conversion to a new Volunteer Person Account, and reuse of a beneficiary without overwriting its established information.

Example preparation, with target paths substituted deliberately:

```sh
python3 scripts/build-volunteer-overlay.py \
  --source /path/to/fresh-target/force-app/main/default \
  --output /path/to/empty-volunteer-candidate \
  --record-types-json /path/to/account-record-types.json \
  --config /path/to/reviewed-target-pages.json
```

RecordType JSON uses the Salesforce CLI result shape with `Id`, `DeveloperName`, `IsPersonType` and `IsActive`. Config contains `layouts` mapping existing layout names to Lead/Contact/PersonAccount and `pages` listing the applicable existing Account Lightning pages. No app or Profile reassignment is generated.

Before enabling the production website, set its own Web-to-Lead organisation/field IDs, endpoint and routing. Keep the established API names; sandbox field IDs cannot be reused. Verify one applicant acknowledgement and the agreed internal notification, without re-enabling an overlapping native auto-response. No production release is implied by the MMUAT tests or GitHub publication.
