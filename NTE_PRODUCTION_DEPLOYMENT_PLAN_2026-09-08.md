# NTE production deployment and Stripe account transition

Prepared 8 September 2026; operational workflow updated 13 September. Internal release plan, not evidence of a production deployment.

The selected Stripe design is **Payment Links only, with manual request release and payment confirmation**. Proposal 22 requires a new Opportunity per application while allowing Account/Contact reuse. Conversion copies and prices the application but sends no email, creates no payment request and confirms no space. Staff use **Requirements → Payment required → Payment confirmed**; checklists remain independent. A later staff top-up has its own manual Stripe request and receipt. Completed uses actual paid/free confirmation and preparation; staff send and mark joining instructions manually.

Stripe Invoicing and optional post-payment invoice creation remain excluded. The client confirmed 20% VAT added to net NTE prices on 13 September; the separate formal invoice process and remaining merchant configuration still require completion. The latest approved refinement makes invoice Yes/No independent of payment method and hides inapplicable finance/procurement details for £0 bookings while retaining explicit free confirmation. It is being implemented and qualified. Final candidate qualification, safe metadata retirement and older-fixture cleanup must not be inferred complete from this plan. MMUAT uses the owner-controlled test account; this plan has not connected the client's account or deployed production. [Current checkpoint](NTE_AUDIT_RESUME.md).

## Recommended deployment method

**15 September record-view boundary:** preserve every existing production business layout and page assignment. NTE pages are assigned only through the `NTE_Management` app, irrespective of whether the same record also belongs to another workflow. Follow [the mandatory source/target page checks](deployment/NTE_PAGE_ISOLATION.md) before and after release. Do not import the separate sandbox Lead-default repair, shared Profiles/layouts, other app definitions or global view overrides into the production candidate.

Use this versioned Salesforce DX source and the complete `manifest/production-package.xml`, deployed through Salesforce CLI/Metadata API. Keep one reviewed release candidate, its configuration, validation result and source hashes together in GitHub. An automated CI release with a protected production environment can execute the same process later; it is not needed to introduce another packaging system now.

| Option | Fit for this project |
| --- | --- |
| Source-controlled CLI/Metadata API release | Recommended. Already matches the generator, complete manifest, sandbox tests and source qualification process. Supports target comparison, check-only validation and a precisely identified release. |
| Change Sets | Possible, but manual component selection and environment configuration would create a second way of assembling this already versioned package. Public forms still require a separate release. |
| Salesforce DevOps Center | Useful if the wider team already adopts it. It can provide the team's change/release workflow, but configuration and training are additional work. |
| Unlocked or managed package | A different lifecycle with its own dependency and upgrade rules. This single-client implementation does not currently need that migration. The present “package” is a Metadata API deployment bundle, not a managed AppExchange package. |

Salesforce documents assembling and deploying versioned source, validating the target and using quick deployment for an eligible validated job. Validate the actual production candidate, because sandbox success does not qualify a different org. [Salesforce CLI deployment commands](https://github.com/salesforcecli/plugin-deploy-retrieve#sf-project-deploy-quick).

## Production access and ownership

Codex can assist with the production inspection, comparison, validation, deployment and verification through a named, client-authorised Salesforce login. Use normal OAuth/web login and the client's MFA rather than sharing passwords or tokens in chat. Start with read-only operations. The client remains the owner of the org, merchant account and release decision.

The current discussion does not grant production access or authorise deployment. Prepare a concrete target diff and validation result first; final release approval then applies to that exact candidate and its configuration. Do not use broad production access as a substitute for these controls.

## Release sequence

1. **Freeze and identify the candidate.** Finish proposal 22 and the independent invoice-choice/£0 refinement, then record the exact source revision and final qualification. Keep any authorised metadata retirement and older-fixture cleanup evidence distinct; neither is complete merely because earlier tests passed. Preserve real records, existing financial/communication history, dated audit evidence and all ten NTE-UI-20260913 fixtures.
2. **Inspect production without writes.** Verify org identity/edition/API compatibility, installed packages, existing NTE components, fields, record types, sales processes, picklists, duplicate and matching rules, active automations, sharing, permissions, sender configuration and capacity. Locate collisions by metadata type and API name, including namespaced or deleted-field conflicts.
3. **Back up the affected target definitions.** Save the exact current metadata and record the relevant data-preservation baseline. Retrieve shared containers in full so an intended NTE addition does not remove another team's entries. Raw business-record backups remain in approved private storage, outside the source repository.
4. **Prepare an isolated production candidate.** Run the generator and local validation first. Compare field types, lengths, precision, required/unique flags, formulas, relationships and picklists. Preserve live financial facts. Reconcile shared standard picklists and rules against the retrieved production definitions; add only the approved NTE requirements.
5. **Apply target configuration.** Set production routing usernames, real form/preparation/logo destinations, sender/support settings and event configuration. Staff own customised joining-instructions content and distribution; do not restore the retired automated final-pack sender or configure its unused URLs. Stripe secrets are installed separately in protected credentials. Do not deploy the sandbox owner or assume its default Lead creator/owner exists in production.
6. **Validate the exact production candidate.** Use the complete manifest and RunLocalTests against production. Inspect every component/test failure and the actual coverage requirement. Record successful job identity, hashes and configuration. Do not rebuild or edit the candidate after validation; any change requires a new validation.
7. **Release the approved candidate.** Within Salesforce's current eligibility window, quick-deploy that successful production validation; otherwise validate again. Agree the timing with the team, especially where shared metadata changes. Confirm component results. Following the owner's 11 September decision, assign **NTE Management Access** (`NTE_Management_Access`) once to every active System Administrator and the selected standard users, and include the group in future NTE onboarding. Verify the target's Salesforce licences, packaged NTE internal sharing rule and report-folder access. The group's Stripe component now grants use of both environment principals; keep the one-group assignment model and securely configure only the appropriate target credentials. [Access instructions](NTE_MANAGEMENT_APP.md#access-model).
8. **Configure and verify intake.** Set Web-to-Lead enablement, Default Lead Creator, Default Lead Owner, notifications, email sender/domain and exact auto-response exceptions. Retrieve production organisation/field IDs and remap the forms. A source field API name stays portable; its Web-to-Lead HTML ID does not.
9. **Publish the production website deliberately.** The existing GitHub Pages site remains the client preview. The final NTE-hosted forms must point to the correct production Salesforce org and field IDs, with production URLs and edition settings. Verify the actual hosted pages and controlled authorised journeys before wider use. Preserve the established Primary Contact routing.
10. **Operate and reconcile.** Staff release the applicable base or top-up request from Requirements; finance checks Stripe or the bank receipt and records the exact charge from Payment required. Preserve original payment when a later top-up reopens Requirements. Procurement checkboxes do not gate sending or Completed and are never ticked by sending. Staff send joining instructions themselves and record the marker from Completed. Reconcile the first genuine business payment, the NTE confirmation and finance reporting after launch. Maintain the retry and incident runbook, named finance owner and absence cover.

Illustrative validation commands, with a real approved production alias substituted at release time:

```sh
sf project deploy validate --manifest manifest/production-package.xml --target-org APPROVED_PRODUCTION_ALIAS --test-level RunLocalTests
sf project deploy quick --job-id SUCCESSFUL_PRODUCTION_VALIDATION_ID --target-org APPROVED_PRODUCTION_ALIAS
```

These commands are documentation only and have not been executed against production.

## Shared metadata and overwriting

For ordinary unmanaged metadata, the component's type and full API name identify it. Deploying `Lead.Some_Field__c` updates that existing field when compatible; another person's having created it does not itself create a duplicate or conflict. The real risks are incompatible types/lengths, changed formulas or requirements, removed picklist choices, a managed namespace, and broader automation or permissions relying on the existing definition.

The 46 previously inherited fields are already in source and the full manifest. The refreshed audit found no additional missing custom fields in its scanned scope. It did find an omitted **OpportunityStage** component: the NTE sales process references six stage values, including `Proposal` and `Negotiation`, whose existence should not depend on a prior sandbox build. Their exact current MMUAT definitions are now generated from `config/salesforce-standard-values.json` and included in the package.

Both `LeadSource` and `OpportunityStage` are shared org settings. Before production, retrieve those target value sets and prepare an overlay:

```sh
python3 scripts/prepare-shared-picklists.py --target-dir RETRIEVED_TARGET/force-app/main/default --output-dir NEW_RELEASE_OVERLAY
```

The tool retains target values, order, defaults and existing noncritical attributes; it adds missing required values and refuses conflicting stage closed/won semantics. Its report identifies retained differences for review. Apply the reviewed overlay only to the isolated release copy **after building**, then validate that exact copy. Running the generator afterward would replace the overlay with the MMUAT baseline.

The duplicate-rule package also references Salesforce's standard Contact matching rule. It is active in MMUAT; an empty Metadata API matching-rule retrieval does not mean it is absent. The successful native MatchingRule query is recorded in the audit. Verify it and the target's overlapping duplicate rules rather than inventing a custom replacement or copying unrelated rules.

Keep the deprecated volunteer auto-response adjustment narrowly scoped to the actual target entry. Do not deploy whole sandbox auto-response/assignment-rule containers over production. Do not run existing pricing/classification backfills or the manual-pricing destructive-change manifest as routine installation steps; each needs a target inventory, preservation plan and authorised migration scope.

## VAT baseline and current workflow to carry into production

The **13 September VAT baseline**, before proposal 22, had 487 component identities and passed 318 RunLocalTests in MMUAT. [VAT qualification](audit/NTE_VAT_QUALIFICATION_2026-09-13.json) identifies that exact source. The later manual-finance baseline passed 502 components / 334 local tests; the current checkpoint records subsequent UI checks and pending refinements. These dated results do not identify the final production candidate. Capture new hashes and final validation after all approved changes settle.

Carry the net catalogue, 20% rate, 11 VAT fields, gross conversion Amount, aggregate form/email breakdown and gross report/finance semantics together. Reconcile paid, discounted, complimentary and separate staff top-up examples in the actual target. Include the qualified independent invoice choice without treating it as a billable-amount flag or inferring it from payment method. Explicit free confirmation needs no fictitious receipt; £0 presentation follows the approved refinement. The existing NTE access group includes the baseline VAT and operational fields; verify all final fields, its calculated status and target assignments. Do not import MMUAT fixtures or test Stripe resources into production.

The Stripe Price already includes VAT, so automatic tax remains disabled. Checkout text and metadata disclose the saved net/VAT/gross breakdown; this is not Stripe Tax reporting or a formal VAT invoice. The client’s separate financial-document process remains a launch dependency. Keep Stripe disabled while preparing the isolated target candidate, then activate only with the authorised client merchant, mode, credentials and production qualification.

## Switching Stripe environments

**Test/live support checkpoint, 11 September:** proposal 20 released explicit test/live support with separate `NTE_Stripe_Test` and `NTE_Stripe_Live` credentials, expected merchant/org and saved mode checks. Recipient/reference filters are blank. That candidate passed 314 local tests and 474 component identities reconciled; the later VAT and manual-finance baselines supersede those package totals. MMUAT remains connected to the owner's test sandbox. Client test/live transitions require secure credentials, exact target config, fresh qualification and separate authorised production deployment; no further code edit is required simply to accept live mode. Prepare production with Stripe disabled, then bind its exact org, live account and `Live_Mode__c=true` before authorised activation. Test requests are not transferable. [Dated evidence](audit/NTE_STRIPE_LIVE_READINESS_2026-09-11.md); [account access and setup sequence](NTE_STRIPE_CLIENT_HANDOVER_2026-09-11.md).

With account identity, credentials and resources held in configuration, the application code can remain the same. The switch requires configuration and qualification, not changing every form or manually editing payment URLs.

1. Client activates the appropriate live Stripe services and verifies the merchant, payout account and available payment methods.
2. Create a separate restricted live credential and install it securely in production Salesforce. Keep MMUAT bound to sandbox credentials.
3. Bind production to the expected client merchant and live environment. Reproduce the agreed branding, GBP/tax policy, methods, receipts and finance notification settings. Keep invoice generation disabled.
4. After authorised activation, the adapter creates or reuses the exact booking or staff top-up Price/Payment Link only when staff release that request. Conversion remains silent. No manual catalogue mapping is needed for this fixed-amount route. Test resources and payment links are not live resources; no test-payment history or test booking is promoted into live finance.
5. Run read-only configuration checks and inspect the live setup before enabling creation for the agreed prospective booking scope. Reconcile the first genuine authorised transaction after launch.

Stripe uses environment-specific keys and objects; a test object cannot be used for a live payment. [Stripe API keys and environments](https://docs.stripe.com/keys). Live service activation requires the client's account/business verification. [Stripe account setup](https://docs.stripe.com/get-started/account/set-up).

## Using the owner's Stripe account first

The owner-controlled account and dedicated sandbox were subsequently created and used for the recorded tests. Keep those fictional applicants and payment histories identified as test evidence. Normal simulated Payment Links payments do not move money; no further owner-account creation or old payment replay is required for the handover. [Stripe testing](https://docs.stripe.com/testing).

Later, connect the same integration code to the client's sandbox using its own credential/account binding and resources. Match the client's actual settings and rerun the complete representative journeys plus configuration-sensitive cases. Keep the owner's old test links and records identified as belonging to that earlier environment; do not relabel them as client payments. Then follow the client-sandbox-to-live steps above.

The change is primarily configuration and a further qualification pass. The owner's sandbox proves the integration mechanics; only the client's environment can establish its merchant-specific configuration and operational acceptance. The later authorised implementation has created and connected the owner-controlled test sandbox; the original planning review itself created no account or paid service.

## Rollback and checkpoint

Keep the previous source revision and affected production metadata snapshot. An incident switch must stop manual Stripe sends and new request processing while preserving payment evidence and manual reconciliation. Conversion itself sends nothing. Already-issued Stripe links require separate handling; switching Salesforce off does not close them or stop unrelated bank/free-space communications. Restoring code does not undo sent emails, external payments or data changes.

The new GitHub repository is a private project checkpoint containing current source, tests, generators, configuration, plans, audit summaries and the original client brief. The canonical public preview repository remains separate. Credentials, authentication caches, temporary org snapshots and raw business-record exports stay outside Git. Historical links into `tmp/` refer to the preserved local audit workspace; the new qualification summary and code/dependency inventories are versioned for the checkpoint.
