# Current project and deployment source — 15 September 2026

The complete project is maintained in the private [mission-community-nte-platform repository](https://github.com/stevostar1234/mission-community-nte-platform). This checkpoint contains the current Salesforce implementation and the supporting website, email, test and handover work. It does not deploy Salesforce or activate payments.

## Start here

| Purpose | Current files |
| --- | --- |
| Salesforce source and complete manifest | `force-app/`, `sfdx-project.json`, `manifest/production-package.xml` |
| Intended workflow and owner decisions | [Desired workflow](NTE_DESIRED_WORKFLOW.md), [approved proposals](NTE_CHANGE_PROPOSALS.md) |
| Current qualification and completed testing | [Audit checkpoint](NTE_AUDIT_RESUME.md), [14 September end-to-end audit](audit/NTE_END_TO_END_AUDIT_2026-09-14.md), [source and release identity](audit/NTE_GITHUB_PACKAGE_BASELINE_2026-09-15.json) |
| Production preparation and release | [Deployment plan](NTE_PRODUCTION_DEPLOYMENT_PLAN_2026-09-08.md), [Salesforce deployment](SALESFORCE_DEPLOYMENT.md), [package synchronisation](PRODUCTION_PACKAGE_SYNC.md) |
| Public forms and email presentation | Root HTML, `assets/`, `config/`, `email-templates/` |
| Metadata generation and local checks | `scripts/`, `tests/`, `package.json` |
| Stripe account transition | [Client handover](NTE_STRIPE_CLIENT_HANDOVER_2026-09-11.md), `config/stripe-sandbox.example.json`, `config/stripe-live.example.json` |
| Failure recovery | [Current guide](output/NTE_Form_Submission_Failure_and_Recovery_Guide_2026-09-14.docx), [review and decisions](audit/NTE_FORM_FAILURE_GUIDE_AND_CONVERSION_REVIEW_2026-09-14.md) |
| Changes to existing shared components | [Target review patches](deployment/target-review/README.md) for Mission's Leads navigation and the legacy report's volunteer exclusion |

## Verified implementation

The 14 September full MMUAT validation `0AfAd00000Sv0pZKAR` passed 509 components and 421 Apex tests. The unchanged candidate was deployed as `0AfAd00000SuzzyKAB`. The later one-component `0AfAd00000Sv63lKAB` changed the payment chart label to Confirmed. This checkpoint matches all 594 relevant qualified source/manifest hashes after accounting for those two final LWC file hashes.

Conversion is silent and each NTE application requires a new Opportunity. Requirements actions deliberately release Stripe, bank-transfer or free-space messages; checklist ticks are independent. Payment receipt is manual. A single later Stripe staff top-up keeps the original payment history and does not repeat finance questions. Staff names are not counted. Joining instructions are sent and marked manually. Native Account/Contact matching stays unchanged. Failed submissions are recovered by manual correction or a fresh applicant form.

An isolated local rebuild reproduces the current generated source exactly. No sandbox journeys, emails or payments are replayed as part of this repository checkpoint. The dated audit remains the record of native qualification; production must validate its own configured candidate.

## Prepare production from the root source

1. Clone the repository or download the current branch. Use the root `force-app/` and complete manifest, not an older reconstruction ZIP.
2. Run the maintained metadata build and local checks. Apply target configuration only after building.
3. Follow the production plan to preserve the target's shared picklists, rules, app customisations and record access. Review the two supplemental patches against the actual target components.
4. Replace MMUAT-specific routing, organisation/field IDs, preview URLs and merchant settings with the approved production values. Install API secrets separately in protected credentials. The repository intentionally retains the qualified sandbox configuration; it is not a ready-configured production merchant.
5. Validate the exact configured candidate in the authorised production org, then release it through the separately approved deployment. Do not run destructive manifests or backfill scripts automatically; their target-specific scope must first be checked.

The canonical public forms preview remains [nte27-web-to-lead-demo](https://github.com/stevostar1234/nte27-web-to-lead-demo). This private repository does not create a second Pages site. Final NTE hosting and client Stripe sandbox/live configuration remain outstanding.

## Historical work and exclusions

Earlier audits, screenshots, the original client brief and the 12 September reconstruction manual/source archive are retained as dated project history. They predate the subsequent manual-finance and staff-roster changes. Their old field counts, quote/invoice refiners, conversion-time sends and final-pack instructions must not override the current desired workflow or root source. See [the output index](output/README.md).

Authentication caches, API secrets, private keys, raw mailbox/provider/business-record exports, installed dependencies and temporary working snapshots are excluded. Historical links into `tmp/` refer to the retained local evidence workspace. The repository includes the deployment manifests and current source hash evidence, without importing sandbox applicants or test payments into production.
