# Source coverage and references

## What this baseline contains

The coverage inventory accounts for 764 maintained files and 473 metadata XML definitions. The functional reference covers 342 packaged fields, 12 implementation Apex classes with 301 methods and constructors, 17 Apex test classes, four LWC bundles with 148 methods/getters and bound handlers, 46 top-level public form-engine functions, ten Web-to-Lead form routes containing 374 mapped controls, four active flows, nineteen stored email templates, nine reports and their folder, and twenty-five native list views. Repeated generated assets and dated audit evidence are indexed in the companion manifest rather than described as separate business features.

The archive includes the current source, configuration, forms, email sources/examples, metadata, scripts and tests needed to reconstruct the implemented behaviour. It also includes this manual's Markdown chapters, extraction/build scripts and original screenshots. SHA256SUMS.txt identifies the exact bytes; documentation/source-analysis/file-coverage.csv maps the reviewed source files to their role/reference section. Authentication caches, credentials, Git internals, temporary native retrieves, raw business exports and operating-system files are excluded. Exclusion is not a claim that an excluded file supplies an implemented feature.

## Trace a feature to its implementation

| Feature | Primary implementation | Reference sections |
| --- | --- | --- |
| Interest and guest intake | Public form, NTE_Inbound_Lead_Routing, NTEInboundLeadService | Workflow, forms, flow reference, Lead dictionary, email catalogue. |
| Invitation and decision | nteMasterPanel, NTE_MasterPanelController, NTEEmailDispatchService | Workflow, runtime, Apex methods, dispatch schema. |
| Application and pricing | Partner/exhibitor pages, assets/forms.js, NTEPricingService | Form control contracts, price catalogue, Lead/Opportunity mapping. |
| Conversion and approval | Native conversion, NTE_Copy_Converted_Lead_to_Opportunity, NTEExhibitorApprovalEmailService | Workflow, conversion sequence, exact Flow assignments, approval methods. |
| Initial Stripe booking link | NTEStripeBookingService, NTEStripeClient, payment/configuration metadata | Finance contract, payment request dictionary, credentials and reconstruction. |
| Quote invoice and payment milestones | NTE_MasterPanelController, Opportunity formulas, finance reports | Finance predicates, button operations, fields and native report definitions. |
| Staff top-up and heavy vehicle updates | Supplementary form pages, NTEUpdateSubmissionJob/Service | Update workflow, matching and validation, exact field definitions. |
| Logo confirmation | logo-upload.html and supplementary handler | Workflow, external file destination configuration and retained logo audit Lead. |
| Editable reminders and final packs | nteMasterPanel and NTEEmailDispatchService | Composer screenshots, snapshot/retry rules, routing and dispatch fields. |
| Portfolio and relationship history | nteManagementHome, nteRelatedOpportunities, related Apex controllers | Home values, Account/Contact/OCR model, methods and page layouts. |
| Retry record actions | nteRetryEmail and three quick-action definitions | Supported recovery table and exact object-specific Apex route. |
| Volunteer intake and conduct | volunteer-application.html, conduct configuration, volunteer Flow/service | Form reference, validation rule, independent owner/applicant receipts. |
| Generated metadata and previews | build-metadata and helper generators | Reconstruction order, catalogue, configuration and source archive. |

## Evidence precedence

The current source and the confirmed desired-workflow/decision records define this manual's implemented behaviour. The live screenshots establish the actual rendered operator surfaces and the displayed configuration-dependent outcome at capture time. The read-only native retrieve compared selected deployed code/email bodies with the local source; it did not recreate production configuration or prove every future execution path.

client needs.docx is the earlier requirements traceability review, with an evidence window ending 1 September 2026. Its historical implementation gaps are not automatically current defects. Later approved September changes include booking/payment email sequencing, staff pricing, volunteer content/Code of Conduct, application access and the owner-controlled Stripe test route. The original client boundary leaves general attendee ticketing in Eventbrite and manual quote/invoice work in the finance system, with logos/artwork held externally. No Eventbrite, Xero or SharePoint synchronisation is implemented by this source. Invited commercial application links are reusable public URLs; the package does not implement authenticated or expiring invitation tokens.

NTE_DESIRED_WORKFLOW.md and NTE_CHANGE_PROPOSALS.md preserve accepted requirements and approvals. NTE_AUDIT_RESUME.md and the numbered September stress audit preserve completed fixtures, results and unresolved P-numbered decisions. The separate PROJECT_DOCUMENTATION_ISSUES.md records findings from this documentation review and distinguishes confirmed defects, configuration dependencies, operating limits and unselected policy changes.

## Salesforce documentation sources

The manual follows Salesforce's guidance to explain the purpose, operation and maintenance of a solution, and to use separate focused architecture/process/data views. Salesforce does not prescribe one universal Word template for every implementation. This is alignment with the cited guidance, not a claim of Salesforce certification.

Salesforce Architects reference diagrams guidance: https://architect.salesforce.com/docs/architect/reference-diagrams/guide/introduction.html. Applied here through separate system, data and process diagrams with explicit scope and readable flow direction.

Salesforce Architects data model notation: https://architect.salesforce.com/docs/architect/reference-diagrams/guide/data-model-notation. Applied through logical and API names, relationship direction, cardinality and an explicit distinction between lookups, role associations and conversion references.

Salesforce Admins documentation guidance: https://admin.salesforce.com/?p=185399. Applied through workflow-first instructions, feature purpose, configuration and source traceability. These primary sources were researched for this documentation task on 12 September 2026. All project-specific rules, values and API names come from the supplied implementation and verified project records.

## Reconstruction completeness

The implemented software can be rebuilt from the companion archive using the build/configuration sequence and exact references in this manual. A complete production operating service additionally needs the client-owned values listed in Reconstruction and administration: target org IDs and setup, routing user, production hosting, logo/final-pack destinations, sender settings, client merchant/credentials and financial policy. Their current absence is stated at the point where the feature depends on them. The manual does not conceal those gaps by inventing production settings or treating unapproved proposals as existing functionality.
