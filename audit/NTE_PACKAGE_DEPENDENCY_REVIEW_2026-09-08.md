# NTE package dependency review and checkpoint

Completed 8 September 2026. Internal engineering record. Scope authorised by the owner: recheck earlier inherited dependencies, incorporate required missing metadata, prepare production guidance and upload the current project to a new GitHub repository.

## Outcome

**All 46 previously inherited fields were already present. No additional missing custom fields were found in the scanned source/MMUAT scope. One missing metadata component was found and incorporated: `StandardValueSet:OpportunityStage`.** The complete package now contains 424 manifest members and has passed MMUAT check-only validation with all 281 Apex tests.

The Opportunity sales process requires `Qualification`, `Needs Analysis`, `Proposal`, `Negotiation`, `Closed Won` and `Closed Lost`. Its BusinessProcess and RecordType were packaged, but the underlying stage definitions were not. A sandbox where those values already exist masks this installation dependency. The exact current six-value MMUAT definition is now generated from [the versioned definition](../config/salesforce-standard-values.json) and included in the full manifest.

This completes the requested source/sandbox check, not production certification. Production metadata, active automation and configuration have not been inspected in this task.

## Checks performed

| Check | Result |
| --- | --- |
| Historical inherited-field manifest | All 46/46 definitions exist locally and in the full manifest. |
| Complete custom-field inventory | 306 definitions: Lead 139, Opportunity 131, Account 5, Contact 6, email dispatch 15 and routing configuration 10. No listed field lacks source and no local field is omitted from the full manifest. |
| Fresh metadata retrieval | Read-only API retrieval `09SAd00000Qkso3MAB` succeeded into an isolated local project. Covered the four core objects, relevant standard/global value sets and lead/matching-rule containers. |
| Exact Tooling dependency identities | Read 1,619 graph edges; 974 belong to exact current package components. Resolved field IDs to their objects rather than matching an API name across unrelated team fields. No unresolved external custom component remained in those edges. |
| Source and retrieved field references | No additional referenced snapshot field absent from local definitions; no global value-set reference requiring an unbundled definition. |
| Sales process and stage definitions | Six required values now present in the generated OpportunityStage component and manifest. |
| Standard Contact matching rule | Native read-only query confirms `Standard_Contact_Match_Rule_v1_1` is Active for Contact. Empty standard matching-rule retrieval files do not disprove its existence. |
| Other automation | Eight unmanaged Flow definitions observed, six active: four packaged Flows plus `customer_satisfaction` and `net_promoter_score`. No unmanaged Apex triggers observed. The unrelated Flows were not copied, changed or certified for production. |
| Shared-picklist preparation | Current MMUAT overlay adds no values and has no retained attribute differences. Five independent preservation/conflict tests pass. |

The graph's actual source coverage here was ApexClass, CustomField, CustomTab, EmailTemplate and Layout. It did not provide complete Flow/LWC/dynamic-reference coverage. Source inspection, metadata retrieval and full native validation complement it; none alone proves a clean production installation. Rows such as `User → User`, `Report → Report` and `RecordType → RecordType` identify Salesforce schema entities, not missing team-owned records or deployable components.

The [machine-readable review](NTE_PACKAGE_DEPENDENCIES_2026-09-08.json) records counts, observations, evidence fingerprints and limits. Reproduce it with `scripts/audit-package-dependencies.py` using the retained isolated snapshot. The earlier [46-field inventory](../pre-production-dependancies.md) is preserved and linked to this broader review.

## Shared settings and remaining external requirements

- **Target picklists:** LeadSource and OpportunityStage affect the wider org. Retrieve the target and use [the overlay preparer](../scripts/prepare-shared-picklists.py) after building the release copy. It preserves other values/defaults and existing attributes; incompatible closed/won semantics stop preparation. Review its differences before validating the exact target candidate.
- **Duplicate/matching rules:** the package references the standard Contact matching rule and changes the shared Lead-versus-Contact duplicate rule's filter. Verify the actual target rule, order and surrounding rules rather than treating every standard component as disposable.
- **Core Salesforce configuration:** suitable Lead conversion status, Task completion status, permissions/licences, report access, API/async/email capacity and shared record-type behaviour still require target checks. Standard entities do not need to be copied from a coworker's metadata.
- **Native intake and email:** Default Lead Creator, Default Lead Owner, Notify Default Lead Owner, Web-to-Lead configuration, sender/domain and the narrow duplicate volunteer auto-response exception remain target-specific settings. Do not overwrite complete sandbox auto-response/assignment-rule containers in production.
- **External destinations and finance:** production form/field IDs, final NTE/preparation/logo/pack destinations, merchant credentials, VAT and notification recipients are configuration dependencies. Payment Links and manual confirmation are now selected; Stripe integration is not implemented by this audit.
- **Historical data:** deployment does not authorise repricing, migration emails, schema purges or old audit replay. Existing backfill/destructive scripts are retained work, not automatic release steps.

An existing component's creator does not itself cause a collision. For ordinary unmanaged metadata, deployment uses the component type and API name and updates a compatible existing definition. Type changes, shortened fields, new required/unique constraints, formula/picklist changes, managed namespaces and shared automation can cause failures or change existing behaviour. Production requires its own comparison and preservation plan; the team's old build must not be overwritten merely because it is old.

## Implementation and verification evidence

- Added the OpportunityStage definition, its generator input and its full-manifest member. Existing source files under `force-app` remained byte-identical after the build; the stage definition is the only new deployable source file.
- Actual one-component MMUAT deployment `0AfAd00000SqBTtKAN` succeeded with zero errors. Its XML exactly matches the fresh pre-deployment sandbox definition, so no new business stage or changed probability was introduced into MMUAT.
- Full check-only `0AfAd00000SqBX7KAN` completed at **15:03:16 UTC**, with **424/424 components, 281/281 tests and zero errors**. All 424 successful component identities match the manifest, normalising the report-folder entry. All **486 source/manifest hashes** remain exact.
- `npm run validate` passes. Five local tests cover preserving another team's values/default, retaining target probability, refusing conflicting won semantics, detecting duplicate values and leaving no partial overlay on an incomplete snapshot.
- No new form/email-preview content changed, so the canonical hosted preview remains at `8d1f7c19f4f18f73905147669e7a9147ed62d14c`; this task did not publish another forms site.
- No production operation, Stripe connection, application submission, genuine-recipient test send, record migration or historical audit replay occurred.

[Exact qualification and source hashes](NTE_DEPENDENCY_QUALIFICATION_2026-09-08.json). The preceding full release and stress-audit evidence remain preserved; this follow-up adds a packaging dependency and does not rerun or expand the earlier live-journey claims.

## Production and GitHub handoff

[The production plan](../NTE_PRODUCTION_DEPLOYMENT_PLAN_2026-09-08.md) recommends the existing source-controlled CLI/Metadata API release, with read-only production inspection, a preserved target snapshot, reviewed configuration, target validation and a separately approved deployment. The client can grant a named OAuth login for this work when ready; access has not been assumed here.

The new private [mission-community-nte-platform repository](https://github.com/stevostar1234/mission-community-nte-platform) contains all current source, tests, generators, configuration, plans, audit summaries/screenshots and the original client brief. All 655 initial file blobs were verified against the local snapshot. Authentication caches, credentials, temporary snapshots and raw business-record exports are excluded. Historical `tmp/` evidence remains in the preserved local workspace. [Publication record](NTE_GITHUB_CHECKPOINT_2026-09-08.md).
