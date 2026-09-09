# Production package and MMUAT synchronisation

Every approved Salesforce change must be represented in the versioned production source and deployed to the `mission-mmuat` sandbox in the same change set. MMUAT must never become the only copy of a fix, and the production manifest must never lag behind what is demonstrated.

## Release invariant

For each Salesforce change:

1. Update the source definitions and, where generated, `scripts/build-metadata.js`.
2. Run `npm run validate` and confirm the build leaves the intended source in place.
3. Add every new deployable component to `manifest/production-package.xml`.
4. Deploy the same source to `mission-mmuat` with an appropriate Apex test level.
5. Verify the feature in MMUAT and record the deployment ID.
6. Run the full production manifest as a check-only deployment with all local tests:

   ```sh
   sf project deploy start --manifest manifest/production-package.xml --target-org mission-mmuat --dry-run --test-level RunLocalTests
   ```

7. Compare the final Git diff with the successful deployment component list before committing. Generated metadata, its generator and its tests must be committed together.

Retiring schema also requires the matching removal manifest, not just omission from `production-package.xml`. The 6 September retirement uses `manifest/retire-manual-pricing.post-destructiveChanges.xml` after the new active package is deployed. On any other org, inventory and archive obsolete Flow versions and their failed interviews before deleting dependencies; keep the current active flow and live/paused interviews. `FlowInterview.FlowVersionViewId` can store a 15-character string: normalize version IDs appropriately and cross-check with an unfiltered inventory instead of trusting an 18-character filter returning zero. Record the backup, cleanup and schema-removal evidence before the final full check-only validation. Never purge deleted fields by default.

Production deployment is a separate, explicitly authorised release step. A successful MMUAT deployment or validation does not authorise a production deployment.

When approved changes affect the forms or email examples, also publish the matching files to the existing canonical GitHub preview site and verify the hosted pages. The owner has given standing permission for this routine preview publication. Use the latest forms-repository branch in an isolated checkout and preserve unrelated content; do not push the Salesforce package branch to that repository.

## Current baseline

- **Latest email presentation qualification, 9 September:** actual sandbox release `0AfAd00000Sr51SKAR` passed **12/12 components and 82/82 tests**. Full check-only `0AfAd00000Sr6vBKAR` passed **464/464 components and 298/298 RunLocalTests**, zero errors; all **530** source/manifest hashes and component identities reconcile. Eight deployed-template renders verified the approved order and payment wording with zero sends/DML. Canonical preview `b77b9baee9062e163a08164578ef419d5fd197a4` has **64/64** intended files byte-verified. [Release/inbox investigation](audit/NTE_EMAIL_PRESENTATION_2026-09-09.md), [exact qualification](audit/NTE_EMAIL_QUALIFICATION_2026-09-09.json).
- **Previous Stripe sandbox qualification, 8 September:** full check-only `0AfAd00000Sq7tKKAR`, completed 8 September at **17:30:35 UTC — 464/464 components and 297/297 RunLocalTests passed, zero errors**. All 464 successful member identities and 530 source/manifest hashes reconcile. Aggregate SHA256 `5eb39508695aa2f7a5ebea6e85fe4b471a976a3c81436429b30060b3a3441f51`. Final actual wording deployment `0AfAd00000SqJ9hKAF` passed three components and 68 tests; foundation/coordinator/config deployments are listed in [exact qualification](audit/NTE_STRIPE_QUALIFICATION_2026-09-08.json). The secret is held only in the External Credential. This is a restricted test-only integration; production requires its own reviewed configuration and authorised activation.
- **Previous public preview, 8 September:** canonical commit `b81b8bced9c64a77aa7b1f31878ffca22dedaeb7`; **63/63 intended files byte-verified** at 17:27:39 UTC. Four Stripe-specific examples were added; final agreement/paid-total wording matches Salesforce. Public payment controls have no payment URL. [Journey and release evidence](audit/NTE_STRIPE_SANDBOX_IMPLEMENTATION_2026-09-08.md).
- Earlier dependency full check-only validation: `0AfAd00000SqBX7KAN`, completed 8 September 2026 at **15:03:16 UTC — 424/424 components and 281/281 RunLocalTests passed, zero errors**. All 424 successful component identities and 486 source/manifest hashes match. This adds the missing OpportunityStage dependency; actual one-component MMUAT deployment `0AfAd00000SqBTtKAN` succeeded and its definition exactly matches the earlier sandbox snapshot. [Current qualification](audit/NTE_DEPENDENCY_QUALIFICATION_2026-09-08.json), [dependency review](audit/NTE_PACKAGE_DEPENDENCY_REVIEW_2026-09-08.md).
- Previous stress-audit full check-only validation: `0AfAd00000Spkn3KAB`, completed 8 September 2026 at 10:14:56 UTC — **423/423 components and 281/281 RunLocalTests passed, zero errors**. All 423 component members, 484 canonical source paths and 485 source/manifest hashes match; there are no missing or unexpected members or changed source files. Aggregate SHA256: `c128cbb66de6d6cc52625cadfc606a58e11f8fdb4d8fdf0d38037cad5e9adb77`. [Exact final qualification](tmp/nte-stress-20260907/metadata-f34-v2-qualification-20260908/summary.json).
- Matching actual MMUAT releases: full deployment `0AfAd00000SpIFhKAN` passed 423/423 components and 278/278 tests, followed by F34 email-formatting deployment `0AfAd00000SpkOrKAJ` on 8 September at 10:04:43 UTC, with 15/15 components and 24/24 class tests. The final full validation above includes the three added actual stored-template tests. The first F34 candidate `0AfAd00000SpiOfKAJ` failed one new parity test and rolled back; its corrected v2 and full final validation passed without weakening the assertions. The prior field retirement remains applied.
- Current release and workflow evidence: [September stress audit — fixes, decisions and 20 feature ideas](audit/NTE_STRESS_TEST_AND_IMPROVEMENTS_2026-09-07.md). All nine native reports and the full-roster CSV reconcile, 34 bulk and four separate representative preparation journeys reached Completed, and all 2,057 retained pre-run records remain unchanged. The earlier [email formatting](audit/NTE_EMAIL_FORMATTING_2026-09-07.md), [restoration and cleanup](audit/NTE_EMAIL_RESTORATION_2026-09-07.md) and [protected walkthrough](audit/NTE_BROWSER_WALKTHROUGH_2026-09-07.md) remain in their dated records. These bounded results do not certify every live concurrency, device or delivery condition.
- Previous stress-audit public preview commit: `8d1f7c19f4f18f73905147669e7a9147ed62d14c` in the canonical forms repository; **59/59 intended hosted files byte-match current source**, verified 8 September at 10:13:01 UTC. This adds 14 email-source corrections to `491cadd974b15d1b9da5542217e8d0cdc19834e1`; all 21 ordinary examples remain byte-identical. The maintained forms script remains revision `20260908-1`. [Exact hosted verification](tmp/nte-stress-20260907/f34-website-release.json).
- Native sandbox routing outside the package: Default Lead Creator and Default Lead Owner are Steven, Notify Default Lead Owner is disabled, and only the obsolete volunteer auto-response entry `01RAd000003M01F` has formula `FALSE`. Four unrelated entries are unchanged; an actual new volunteer submission produced one receipt. Reconcile the corresponding native settings separately in any authorised production release.
- Temporary final-pack configuration was restored exactly after the three reserved-recipient dispatch checks. Both real final-pack URLs remain blank, queued pack count is zero, and the original routing metadata SHA256 remains `731087d1b28c53f981615437a6ec3a1a50c343da11e2ca05c0b326ab6f615687`. Real client pack contents, logo destination and Stripe remain pending client input. No production deployment occurred.
- Canonical Salesforce source: `force-app/main/default`
- Complete deployment manifest: `manifest/production-package.xml`
- Canonical public forms: `stevostar1234/nte27-web-to-lead-demo`
- Public forms are not packaged as a Salesforce tab or Lightning component.
- NTE Management opens on Home; Master Panel is the second tab.
- The report folder includes `NTE_09_Weekly_Finance_Report`, which uses Salesforce's rolling Last 7 Days filter.
- The 46 inherited Lead fields documented in `pre-production-dependancies.md` are included directly in this package.

## Production prerequisites

- Follow [the production release plan](NTE_PRODUCTION_DEPLOYMENT_PLAN_2026-09-08.md). Retrieve and reconcile target LeadSource/OpportunityStage values with `scripts/prepare-shared-picklists.py` after building an isolated release copy, preserving other teams' values/defaults. Validate the exact reviewed target candidate; do not run the generator after applying the overlay.
- Replace the MMUAT Web-to-Lead organisation ID and custom-field IDs in the canonical forms repository after the production fields exist.
- Replace the MMUAT NTE routing owner override (`steven.skyba@euroforce.com.mmuat`) with the verified intended production username before release. Set the production Web-to-Lead Default Lead Creator and Default Lead Owner separately; changing the creator does not change fallback ownership or internal notification recipients. A blank NTE owner override preserves inbound ownership and must be reviewed against the target org's default owner. Inspect the production native auto-response rules so the modern volunteer application has only its intended acknowledgement route.
- Assign `NTE_Management_User` or `NTE_Forms_Administration` only to authorised staff.
- Run controlled form, conversion, pricing-validation, finance-milestone, staff-update and heavy-vehicle-update tests before publishing production URLs.
- Do not deploy the retired forms hub or the deleted team-facing forms site.
