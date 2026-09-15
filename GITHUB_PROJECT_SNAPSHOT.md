# Current project and deployment source — 15 September 2026

The complete project is maintained in the private [mission-community-nte-platform repository](https://github.com/stevostar1234/mission-community-nte-platform). This checkpoint contains the current Salesforce implementation and the supporting website, email, test and handover work. It does not deploy Salesforce or activate payments.

## Start here

| Purpose | Current files |
| --- | --- |
| Salesforce source and complete manifest | `force-app/`, `sfdx-project.json`, `manifest/production-package.xml` |
| Intended workflow and owner decisions | [Desired workflow](NTE_DESIRED_WORKFLOW.md), [approved proposals](NTE_CHANGE_PROPOSALS.md) |
| Current qualification and completed testing | [Audit checkpoint](NTE_AUDIT_RESUME.md), [14 September end-to-end audit](audit/NTE_END_TO_END_AUDIT_2026-09-14.md), [current source and release identity](audit/NTE_SPACE_SELECTION_QUALIFICATION_2026-09-15.json) |
| Production preparation and release | [Deployment plan](NTE_PRODUCTION_DEPLOYMENT_PLAN_2026-09-08.md), [Salesforce deployment](SALESFORCE_DEPLOYMENT.md), [package synchronisation](PRODUCTION_PACKAGE_SYNC.md) |
| Public forms and email presentation | Root HTML, `assets/`, `config/`, `email-templates/` |
| Metadata generation and local checks | `scripts/`, `tests/`, `package.json` |
| Stripe account transition | [Client handover](NTE_STRIPE_CLIENT_HANDOVER_2026-09-11.md), `config/stripe-sandbox.example.json`, `config/stripe-live.example.json` |
| Failure recovery | [14 September guide](output/NTE_Form_Submission_Failure_and_Recovery_Guide_2026-09-14.docx), [current restrictions and superseded space rule](audit/NTE_FORM_RESTRICTIONS_2026-09-15.md), [recovery decisions](audit/NTE_FORM_FAILURE_GUIDE_AND_CONVERSION_REVIEW_2026-09-14.md) |
| Preserve existing business record views | [App-specific page boundary and deployment checks](deployment/NTE_PAGE_ISOLATION.md); historical [target-review patches](deployment/target-review/README.md) must not be applied automatically |

## Verified implementation

The 15 September full MMUAT validation `0AfAd00000Sw2KfKAJ` passed 509 components and 422 Apex tests. The exact candidate was deployed as `0AfAd00000Sw3DVKAZ`; all 594 source/manifest hashes are recorded in the current qualification. Any organisation may now request any listed exhibitor space, with the NTE team deciding approval. Both free choices show the £499 + VAT bundle value. The paired public preview `31c568e7529acee99c6717c0dbf162982a3940ea` has 12/12 files byte-verified. The earlier GitHub baseline and 14 September releases remain historical evidence. The later finance-contact wording follow-up is published as `617e2c5a06af41847a23767fba8860836573416a` with both HTML files verified; matching main/finance details are allowed on both applications, and the Salesforce source hashes remain unchanged. [Follow-up evidence](audit/NTE_FINANCE_CONTACT_FOLLOWUP_2026-09-15.md).

Conversion is silent and each NTE application requires a new Opportunity. Requirements actions deliberately release Stripe, bank-transfer or free-space messages; checklist ticks are independent. Payment receipt is manual. A single later Stripe staff top-up keeps the original payment history and does not repeat finance questions. Staff names are not counted. Joining instructions are sent and marked manually. Native Account/Contact matching stays unchanged. Failed submissions are recovered by manual correction or a fresh applicant form.

The 15 September app-view follow-up repaired two older MMUAT Lead assignment components (`0AfAd00000SwDsnKAF`). The same records show NTE pages only in NTE Management, with original business views retained in Mission and Mission Community. All existing layouts, page definitions and Profiles remain unchanged. New candidate/baseline checks prevent those shared definitions from entering the production release. The sandbox repair files stay outside production source. [Verified scope](audit/NTE_APP_PAGE_ISOLATION_2026-09-15.md).

The subsequent volunteer extension is approved and complete in MMUAT. New optional answers are visible on existing Mission pages and map to Contact/Person Account destinations; historic values, existing mappings and overlapping beneficiary roles are preserved. Full validation passed 528 components / 429 tests. Existing Admin and Standard profiles received additive field visibility without new permission-set assignments. These shared page/layout/mapping/access additions must be prepared from fresh production metadata, separately from the NTE core package. [Release and 614 source/manifest hashes](audit/VOLUNTEER_LEGACY_COMPATIBILITY_RELEASE_2026-09-15.md), [target-derived production guide](deployment/VOLUNTEER_LEGACY_EXTENSION.md).

Kate's latest application introductions are live in public commit `1267cc0`. The three Classic HTML webinar invitations, text alternatives and coworker upload notes are in [the handover archive](output/NTE27-Webinar-Invitations.zip) and `email-templates/webinar-invitations-2026-10-13/`. They are manual invitation assets, outside the booking automation and production package manifest. Native merges and the registration destination are verified; no invitations have been sent. [Evidence](audit/NTE_WEBINAR_INVITATIONS_2026-09-15.md).

An isolated local rebuild reproduces the current generated source exactly. No sandbox journeys, emails or payments are replayed as part of this repository checkpoint. The dated audit remains the record of native qualification; production must validate its own configured candidate.

## Prepare production from the root source

1. Clone the repository or download the current branch. Use the root `force-app/` and complete manifest, not an older reconstruction ZIP.
2. Run the maintained metadata build and local checks. Apply target configuration only after building.
3. Follow the production plan to preserve the target's shared picklists, rules, app customisations and record access. Run the page-isolation candidate check and capture the target's existing page/layout baseline. Keep existing apps, business layouts, Profiles and shared object defaults out of the deployment source. Historical supplemental patches are not automatic production steps.
4. Replace MMUAT-specific routing, organisation/field IDs, preview URLs and merchant settings with the approved production values. Install API secrets separately in protected credentials. The repository intentionally retains the qualified sandbox configuration; it is not a ready-configured production merchant.
5. Validate the exact configured candidate in the authorised production org, then release it through the separately approved deployment. Do not run destructive manifests or backfill scripts automatically; their target-specific scope must first be checked.

The canonical public forms preview remains [nte27-web-to-lead-demo](https://github.com/stevostar1234/nte27-web-to-lead-demo). This private repository does not create a second Pages site. Final NTE hosting and client Stripe sandbox/live configuration remain outstanding.

## Historical work and exclusions

Earlier audits, screenshots, the original client brief and the 12 September reconstruction manual/source archive are retained as dated project history. They predate the subsequent manual-finance and staff-roster changes. Their old field counts, quote/invoice refiners, conversion-time sends and final-pack instructions must not override the current desired workflow or root source. See [the output index](output/README.md).

Authentication caches, API secrets, private keys, raw mailbox/provider/business-record exports, installed dependencies and temporary working snapshots are excluded. Historical links into `tmp/` refer to the retained local evidence workspace. The repository includes the deployment manifests and current source hash evidence, without importing sandbox applicants or test payments into production.
