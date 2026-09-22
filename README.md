# Mission Community NTE forms and Salesforce package

This repository contains the Salesforce source, forms, tests and release documentation for National Transition Event submissions in Mission Community.

The latest backend correction, 17 September, allows any organisation category to confirm either valid free-space choice. It is qualified and deployed in MMUAT with all 434 Apex tests passing. See [the release](audit/NTE_FREE_SPACE_CONFIRMATION_FIX_2026-09-17.md) and [current source qualification](audit/NTE_FREE_SPACE_CONFIRMATION_QUALIFICATION_2026-09-17.json); production deployment remains separate.

**15 September space-selection release:** any organisation type may request any listed exhibitor space; free choices show their £499 + VAT bundle value. Deployed to MMUAT and published to the canonical preview after 422 native tests. [Release evidence](audit/NTE_SPACE_SELECTION_RELEASE_2026-09-15.md) and [remaining form restrictions](audit/NTE_FORM_RESTRICTIONS_2026-09-15.md).

The complete private project checkpoint is [stevostar1234/mission-community-nte-platform](https://github.com/stevostar1234/mission-community-nte-platform). [Current publication and verification](audit/NTE_GITHUB_CHECKPOINT_2026-09-15.md) records this update; [the earlier checkpoint](audit/NTE_GITHUB_CHECKPOINT_2026-09-08.md) retains its original evidence.

**15 September 2026 package checkpoint:** start with [the current source and deployment guide](GITHUB_PROJECT_SNAPSHOT.md). The source includes the 14 September manual finance, VAT, flexible staff rosters, Update issues and final panel refinements, with the latest confirmed recovery decisions. Historical manuals and archived reconstruction bundles are retained for reference; the root source and `manifest/production-package.xml` are the current deployment basis.

The current release approach and Stripe account-transition steps are in [the production deployment plan](NTE_PRODUCTION_DEPLOYMENT_PLAN_2026-09-08.md). The [8 September dependency audit](audit/NTE_PACKAGE_DEPENDENCY_REVIEW_2026-09-08.md) extends the earlier field-only inventory, and [code metrics](audit/NTE_CODE_METRICS_2026-09-08.json) separate application code, tests, metadata and generated examples. Stripe Payment Links are implemented in MMUAT using the owner's test account, with manual request release and payment confirmation. Client-account configuration and production remain separately authorised releases.

Under the 13 September manual-finance workflow, each application creates a new Opportunity while allowing Account/Contact reuse. Conversion sends nothing. Staff release the applicable booking/free-space/top-up action from Requirements and record verified receipts in Payment required; a later top-up preserves the original payment. Requirement ticks are independent, and Completed uses actual payment/free confirmation and preparation. Joining instructions are sent and marked manually.

The latest approved **Invoice Requested** refinement separates the applicant's Yes/No answer from Payment Method and the existing billable flags. The exhibitor finance section is hidden and disabled at £0 and returns when a paid space, socket or staff extra creates a charge; partner finance remains visible. This refinement is released and qualified in MMUAT: 351 native tests passed, five fresh applications converted silently and the canonical preview is current. Exact older-fixture cleanup is recorded separately in the checkpoint. [Current release checkpoint](NTE_AUDIT_RESUME.md).

For the current business requirements, read [NTE_DESIRED_WORKFLOW.md](NTE_DESIRED_WORKFLOW.md). Proposed implementation changes and their approval status are recorded in [NTE_CHANGE_PROPOSALS.md](NTE_CHANGE_PROPOSALS.md). These distinguish the intended workflow from behaviour already implemented in the package.

The sole published and maintained form source is the client-facing repository at `https://github.com/stevostar1234/nte27-web-to-lead-demo`, currently published at `https://stevostar1234.github.io/nte27-web-to-lead-demo/`. This Salesforce package does not publish or expose a separate forms site.

The current visible copy and pricing catalogue are for NTE27. Form identities, booking references and the core Salesforce automation are edition-neutral; visible dates, prices and the versioned server-side pricing catalogue must be reviewed for every edition.

## Included journeys

- Partner / sponsor expression of interest
- Exhibitor expression of interest
- Partner / sponsor application
- Exhibitor application
- Guest registration
- Direct-link staff details update
- Direct-link heavy vehicle and logistics update
- Secure logo-upload handoff page

## Repository layout

- Root HTML and `assets/`: local validation fixtures retained for package compatibility; do not publish these as a separate forms site
- `force-app/`: Salesforce DX source (fields, Opportunity model, email templates, flows, Apex services, list views and permission set)
- `email-templates/source/`: editable email HTML sources
- `scripts/build-metadata.js`: reproducible Salesforce metadata and email-template build
- `config/salesforce-standard-values.json`: required NTE sales-stage definitions
- `scripts/prepare-shared-picklists.py`: local production overlay that preserves target picklist values/defaults
- `scripts/audit-package-dependencies.py`: current offline dependency audit using retrieved metadata and exact Tooling identities
- `tests/`: browser-side form tests
- `audit/ux-2026-08-17/`: release-review screenshots
- `PRODUCTION_READINESS_REVIEW_2026-08-17.md`: production risks and recommended controls

## Local validation

```sh
npm run validate
```

`npm run validate` regenerates the metadata and then runs every suite: the form unit and DOM-fixture tests, the Master Panel component tests, the report/metadata semantics checks (both against the generator and the generated files), the page-isolation, shared-picklist, Stripe pre-flight and volunteer compatibility checks. `npm run test:forms`, `test:panel`, `test:metadata`, `test:page-isolation` and `test:volunteer` run the individual groups. The repository sets `eol=lf` through `.gitattributes`, so the generated-text comparisons behave the same on Windows and macOS/Linux.

Credentials, authentication caches, temporary snapshots and raw business-record exports are excluded from Git. Historical audit links into `tmp/` refer to the retained local evidence workspace. The repository contains the current implementation and internal handoff documents; it does not activate production or publish another forms site.

See [NTE_MANAGEMENT_APP.md](NTE_MANAGEMENT_APP.md) for the daily Salesforce workspace, access model and app-specific record pages. See [SALESFORCE_DEPLOYMENT.md](SALESFORCE_DEPLOYMENT.md) for architecture, deployment and lifecycle checks, and [PRODUCTION_PACKAGE_SYNC.md](PRODUCTION_PACKAGE_SYNC.md) for the mandatory paired source/MMUAT release process. The inherited field inventory is retained in [pre-production-dependancies.md](pre-production-dependancies.md). Review [PRODUCTION_READINESS_REVIEW_2026-08-17.md](PRODUCTION_READINESS_REVIEW_2026-08-17.md) before production and [FUTURE_NTE_MAINTENANCE.md](FUTURE_NTE_MAINTENANCE.md) before preparing another NTE edition.

NTE record pages are specific to NTE Management. The same records retain their existing business views in Mission and other apps. Follow [the page-preservation checks](deployment/NTE_PAGE_ISOLATION.md) so an NTE release cannot replace the client's existing layouts or app assignments.
