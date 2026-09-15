# Reconstruction and administration

## Reconstruction baseline

The companion source archive is the exact maintained implementation used for this manual. Start from that archive in an isolated working directory. Its SHA256 manifest identifies every included file. The guide explains the relationships and decisions that a source tree alone cannot convey; the archive supplies the exact code, formulas, email HTML, assets and metadata definitions needed to reproduce the implementation without transcribing hundreds of API names or rewriting algorithms from prose.

This is an unnamespaced Salesforce DX project, package directory force-app, source API 67.0. It is a Metadata API deployment bundle, not a managed or unlocked package. Individual component versions remain those in their metadata, including API 65.0 for nteMasterPanel. The observed org is an Enterprise sandbox, MMUAT. All screenshots show the 12 September 2026 state; their record counts are examples, not seed data or acceptance targets. The source working tree contains changes newer than its last commit, so use the archive manifest rather than a Git commit alone to identify this baseline.

The main build uses Node built-ins and local modules. package.json defines build as node scripts/build-metadata.js, test as node tests/forms.test.js and validate as build followed by that single test entry point. The additional suites below are separate commands. Python maintenance tools use the standard library. No database seed, site build framework or npm dependency installation is required to regenerate the supplied metadata and email examples.

## Target decisions and configuration values

The following values cannot be invented from source. They belong to the destination organisation. The manual specifies where and how each is used; the owner must supply them before the corresponding feature can operate.

| Required value | Where to set it | Effect and current baseline |
| --- | --- | --- |
| Target organisation and public Lead field IDs | assets/config.js orgId, endpoint and customFieldIds | Current values target MMUAT. Retrieve the destination IDs after deploying fields. IDs beginning 00N belong to that org; API names are portable. |
| NTE routing user | NTE_Routing_Config.Default Owner_Username__c | Exact active User.Username; current value is steven.skyba@euroforce.com.mmuat. NTE intake uses it for ownership and internal notification. |
| Public form hosting and return pages | assets/config.js and NTE_Routing_Config.Default | Current site is the canonical GitHub Pages preview. Production hosting and final URLs must be supplied. Maintain page filenames or update every referring URL. |
| Application edition | Routing Application_Event_Code__c and browser event configuration | Current routing is NTE2027. Browser edition normally rolls over in April, London time; invitation eligibility must agree with the advertised edition. |
| Final event information | Exhibitor_Final_Pack_URL__c and Partner_Final_Pack_URL__c | Both are blank. Supply real HTTPS destinations before final-pack sending becomes eligible. |
| Logo file intake destination | assets/config.js logoFileRequestUrl | Blank in the baseline. The logo workflow records a declaration/update; Salesforce does not store an uploaded binary in this implementation. Supply the external file-request destination to complete the participant's file handoff. |
| Lead creator locale and default ownership | Web-to-Lead setup | Current browser date output is DMY. Default Lead Creator must parse that format; volunteer owner notification follows the resolved Lead owner. |
| Public contact and privacy destinations | assets/config.js supportEmail, termsUrl, termsLinkLabel | Current support is nte@missioncommunity.org and privacy points to nationaltransitionevent.com/privacy. Confirm destination wording and ownership for the release edition. |
| Merchant and tax policy | NTE_Stripe_Config.Default and external credentials | Baseline is an enabled owner-controlled test account, bound to MMUAT, with the client-confirmed 20% VAT policy. Client merchant identity, live activation and the separate formal invoice process still require target configuration and qualification. |
| Native email delivery settings | Target organisation delivery, sender and auto-response setup | Preserve unrelated routes. Disable only a matching duplicate volunteer applicant response; the source package does not replace the complete native rule container. |

## Assemble the Salesforce implementation

Build the candidate first with node scripts/build-metadata.js. That writes generated fields, flows, list views, reports, permissions, Lightning app/pages, email resources and examples, then invokes the communications, Stripe credential and Stripe booking metadata generators. Apex class bodies, LWC source, public HTML and form JavaScript remain maintained source files. Editing generated XML without updating its generator is a temporary overlay that a later build will overwrite.

Compare the candidate's object/field catalogue with the target before applying it. The package includes the inherited Lead fields used by the forms, so they are not an undocumented installation dependency. Existing fields with the same API name still require compatible types, lengths, precision, picklists and relationship targets. Existing legacy NTE registration objects are outside this package and are not migration destinations. No script automatically transfers their historical records into Opportunities.

The package also depends on standard Account, Contact, Lead, Opportunity, OpportunityContactRole, Task, Event, User, RecordType and EmailTemplate behaviour. Duplicate rules reference the standard Contact matching rule Standard_Contact_Match_Rule_v1_1. The NTE Event Opportunity record type and its sales process, Opportunity stages and LeadSource entries must be deployable together. The complete manifest includes the project-owned dependencies; target-specific profiles, native Lead conversion mappings, matching-rule availability, Web-to-Lead setup and organisation-wide email settings are evaluated in the target.

Shared LeadSource and OpportunityStage definitions affect other applications. Retrieve their complete target definitions into a separate source-format directory. Run scripts/prepare-shared-picklists.py with --required-dir pointing to the candidate's force-app/main/default, --target-dir pointing to the retrieved target force-app/main/default and --output-dir pointing to a new empty overlay directory. The helper preserves target values/attributes, adds missing required values as non-default, and rejects incompatible closed/won flags. Inspect merge-report.json and copy the two resulting standardValueSets files into the isolated candidate after its last build. Do not rebuild away that overlay.

Use the supplied complete manifest for target validation. An illustrative candidate command is sf project deploy start --manifest manifest/production-package.xml --target-org TARGET --dry-run --test-level RunLocalTests. TARGET is the authorised destination alias, not a literal org name. The actual release uses the exact validated candidate and target; remove --dry-run for an authorised normal deployment or use an eligible validation job's quick-deploy path. The documentation task performed no deployment.

Assign the permission set group NTE_Management_Access to active administrators and selected operations users who need the application. Its components are NTE_Management_User and NTE_Stripe_Test_Operator, the latter labelled NTE Stripe Payment Operator and granting both environment principals. NTE_Forms_Administration is a separate broader administrative permission set; Volunteer_Applications_User serves volunteer processing. Apply the intended app/page assignments and verify the target user's licence and record visibility. The packaged NTE internal sharing rule grants Edit for NTE Event Opportunities to all internal users; the report folder grants View to that group. These are concrete access choices in this design, not automatic behaviour of an LWC.

## Configure public intake

Use the field reference to enumerate the custom Lead fields present on each page. Obtain each destination field's Web-to-Lead ID through generated Web-to-Lead HTML or Salesforce field metadata, and replace the matching API-name entry in customFieldIds. Retain the standard HTTP names listed in the forms chapter. Check that every used custom API has an ID and that the orgId, endpoint and returnUrl point to the same intended environment. A 00N ID from MMUAT cannot be reused just because the destination field has the same API name.

Publish the root HTML pages, assets directory and required email examples together to the chosen static host. The browser loads assets/config.js followed by assets/forms.js; CSS and logo/icon assets are shared. Preserve relative paths. staff-update.html routes people to the exhibitor or partner staff form. index.html is the form hub; thank-you.html and volunteer-thank-you.html are the distinct completion pages. The standalone code-of-conduct page and embedded volunteer reader must use the maintained September 2026 text/version together. The preview repository is stevostar1234/nte27-web-to-lead-demo; the Salesforce source branch is not a website release branch.

Configure Web-to-Lead enablement, Default Lead Creator, Default Lead Owner, owner notifications and overlapping Lead automations in the target. Preserve existing assignment and auto-response entries other than a reviewed overlap. NTE pages post lead_source=Customer Event; volunteer pages post Volunteer Application. useDefaultRule=0 does not eliminate the need to inspect native auto-response rules. Initial NTE application acknowledgements have been retired; the first approval-stage email is the booking message after conversion. EOI, guest and volunteer receipts follow their own routes.

After configuration, qualify each form using new controlled records for that target: verify exact persisted field values, workflow routing and the resulting email's real merged body. This is a new-target reconstruction step. Do not resubmit the previously completed September MMUAT stress fixtures or repeat their accepted emails.

## Configure the Stripe booking route

The exact runtime configuration is NTE_Stripe_Config.Default, not the example JSON files. The JSON examples support the read-only preflight tool and deliberately start disabled. For a new target, begin with Enabled__c=false. Populate Expected_Org_Id__c with the destination's 18-character org ID, Expected_Account_Id__c with the selected acct_ merchant ID, Live_Mode__c with the intended environment and Tax_Rate__c with the approved percentage. Reference_Prefix__c and Allowed_Email__c optionally restrict activation scope; both are blank in the MMUAT baseline.

The named credentials are NTE_Stripe_Test and NTE_Stripe_Live, each using its corresponding external credential and NTEApplication named principal. Configure that principal's ApiKey authentication parameter separately. The custom Authorization header is Bearer followed by the protected ApiKey value. Credentials are intentionally absent from the source archive and documentation. The endpoint is https://api.stripe.com. The Stripe Payment Operator component permission grants use of the principals; it does not supply a key or choose the active environment.

The browser, dashboard and email renderer present GBP and the Stripe adapter requires gbp. Use GBP booking amounts in the destination. This implementation does not convert an Opportunity in another currency into GBP; a multi-currency deployment needs a separately designed currency contract before enabling the route.

Copy the appropriate config/stripe-sandbox.example.json or stripe-live.example.json to a private target configuration file, fill the expected account/environment and run python3 scripts/stripe-preflight.py --config PRIVATE_CONFIG. The tool prompts invisibly for a key and reads account and balance information. Its successful result confirms account identity/mode, and in live mode checks charges_enabled. It explicitly does not claim that Payment Links were tested or Salesforce was connected. The Apex adapter performs its own verification and needs permissions for account/balance reads and Price/Payment Link creation and retrieval.

When the new target is qualified and activation is approved, enable the selected scope in custom metadata. Converting an eligible paid application then prepares its one booking payment request and link before the provisional email. Accepted delivery stamps the invoice and any quote milestone required for that Stripe route. Payment remains manually confirmed in the Master Panel after finance verification. There is no webhook, Stripe Invoice generation, automatic refund, recurring charge or automatic staff top-up link in this package.

## Feature verification and evidence

This documentation review regenerated the full metadata in an isolated copy and compared the outputs with the source baseline: zero changed generated files. A read-only native retrieve from MMUAT also matched all 29 Apex bodies, 15 LWC source files and 19 stored email bodies after line-ending/outer-whitespace normalisation. This is evidence for those compared artefacts, not a claim that every org setting or every metadata byte matches.

| Local verification | Result from this documentation review | What it establishes |
| --- | --- | --- |
| forms.test.js | Passed | Form/schema invariants and its included email presentation checks. |
| email-assets.test.js and email-template-presentation.test.js | Passed | Referenced local presentation assets and the source compiler's optional/partial/multiline merge behaviour. |
| panel-ui-stress.test.js | 32 checks passed | Component state and action protections exercised by the local harness. |
| stress-form-engine.test.js | 140 checks passed across 34986 catalogue and boundary combinations | Browser engine date, conditional, mapping, catalogue and submission boundaries within the harness. |
| shared-picklists.test.py | 5 tests passed | Preservation/addition/conflict behaviour of the target picklist overlay. |
| stripe-preflight.test.py | 7 tests passed | Account/environment/key-input validation with controlled responses. |
| metadata-reports.test.js | Fails before completing | Preview-definition extraction includes a generator write without providing write in its VM context. Recorded in PROJECT_DOCUMENTATION_ISSUES.md; no source fix was made. |

The supplied 17 Apex test classes describe project-specific cases in the Apex test reference. The documentation review did not rerun business sends, conversions, external charges or the completed full-org stress audit. Earlier native test/deployment evidence remains in the dated audit records, including the 11 September qualification. Local verification is not a substitute for qualifying the destination's native conversion, real merge output and configuration-sensitive behaviour.

## Recover incomplete work

| Observed condition | Inspect | Project-specific recovery |
| --- | --- | --- |
| Initial EOI or volunteer receipt/internal notice failed | Lead applicant/internal statuses and error field, configured user/Lead owner and template | Correct the cause first. Initial intake has no dedicated panel retry; a narrowly scoped administrator invocation must be evaluated against already accepted sides to avoid duplicate mail. |
| Provisional booking email failed | Opportunity approval status/error, one converted application, Primary Contact and payment request | Correct the recorded cause and use Retry booking email. It rejects Pending/Sent and unsafe source associations. Do not reconvert the Lead to resend. |
| Payment request needs review or has an ambiguous old external response | NTE_Payment_Request__c status/error, snapshot/account/mode and Stripe resources | Reconcile the existing request/resources manually. Do not replace its key or create a second charge to make a failed email pass. The adapter protects the 23-hour ambiguity boundary. |
| Supplementary Lead unmatched or validation failed | Target_Booking_Reference__c, match/error fields and relevant Opportunity | Correct the reference/required data under an approved support action. Inspect duplicate references and Closed Lost state. The normal flow runs on creation; editing a retained Lead alone does not requeue it. |
| Supplement applied but receipt failed | Applied booking ID, acknowledgement status/error and current Primary Contact | Use Retry update email on the retained Lead. This retries the receipt only; it does not reapply field changes or reroute to a different booking. |
| Editable communication failed | Dispatch type, target, saved recipient/fingerprint, error and source state | Retry email on the failed dispatch record after correcting the cause. Changed recipients/eligibility can require a newly reviewed draft instead. Preserve already Sent records. |
| Pricing requires review | Saved catalogue version, selected labels, category, counts and component amounts | Correct the specific inconsistency. A historical reprice is a financial-data migration; a general code release does not authorise it. |
| Final-pack Send is disabled | Both route destination settings and recipient eligibility messages | Supply the correct final-pack URL for each audience and refresh the draft. Completing a booking does not send its pack automatically. |

## Maintenance files and their roles

| File or group | Purpose and effect |
| --- | --- |
| scripts/build-metadata.js | Main generator, source catalogue and metadata/email orchestration. Owns generated definitions; rerun before applying a target overlay. |
| scripts/build-communications.js | Dispatch schema, communication status fields, retry actions and related permissions/metadata. |
| scripts/build-stripe.js and build-stripe-bookings.js | Named/external credential definitions and the payment-request/configuration schema with access requirements. |
| scripts/email-formatting.js and email-template-presentation.js | Native currency-aware previews, optional rows, greetings, joins and readable text alternatives. |
| scripts/normalise-staff-count-fields.mjs | Normalises staff count field definitions. It writes metadata and is not a general record-data migration. |
| scripts/prepare-shared-picklists.py | Read-only input comparison producing a target-preserving local release overlay. |
| scripts/audit-package-dependencies.py and audit-pre-production-dependencies.mjs | Examine source/manifest and locally retrieved target definitions for missing dependencies or incompatible baselines. They do not replace fresh target inspection. |
| scripts/post-deploy/backfill-nte-opportunity-record-type.apex | Constrained update of qualifying NTE Opportunities to the NTE record type; inspect candidate rows before running. |
| scripts/post-deploy/backfill-nte-participant-classification.apex | Backfills current Account/Contact participant classification from relevant applications. Classification is a current summary, not an event history table. |
| scripts/post-deploy/backfill-nte-pricing.apex | Recalculates existing application/booking monetary fields against the deployed catalogue. Run only for a separately inventoried financial migration. |
| scripts/backfill-master-panel-milestones.apex | Historical fixture milestone repair. It is not a routine setup or release step. |
| scripts/qa and scripts/verify-master-panel.apex | Controlled submission/conversion and operational verification helpers. Several create or mutate records; do not run them against completed fixtures as documentation checks. |
| scripts/project-metrics.py | Source inventory and metrics, not runtime business logic. |
| config/salesforce-standard-values.json | Required shared-value baseline consumed by the metadata generator. Reconcile target values after generation. |
| config/volunteer-code-of-conduct.json | Maintained conduct content/version and deliberate online-reader omissions. |
| NTE_DESIRED_WORKFLOW.md and NTE_CHANGE_PROPOSALS.md | Confirmed workflow and stable decision numbers. Unselected proposals are not implemented requirements. |
| NTE_AUDIT_RESUME.md and audit directory | Dated evidence, retained fixtures, unresolved decisions and recovery checkpoints. Historical statements must be read with their date and subsequent decisions. |

## Maintaining this manual

Update the workflow narrative and screenshots when operators gain a new action or a stage changes. Update field/form/method references from the same frozen source candidate as the release. A changed catalogue requires the browser values, Apex allowlists, generated picklists, saved version and worked examples to agree. A changed email needs native merged-output verification as well as the HTML preview. A changed form needs both its API-name mapping and the destination org's public field ID mapping considered.

The documentation source and extraction scripts are supplied under documentation. Their coverage register ties the reference sections to the included files and hashes. Issues identified during this task are kept in the separate Markdown register; they are not silently changed in the implementation described here.
