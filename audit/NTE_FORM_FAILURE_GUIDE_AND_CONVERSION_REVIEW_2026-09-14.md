# Form failure guide and native conversion review — 14 September 2026

Status: complete. This is a documentation and read-only inspection follow-up to the [completed end-to-end audit](NTE_END_TO_END_AUDIT_2026-09-14.md). Its original release, counts, record preservation and once-only sends remain dated evidence. No new Salesforce deployment, provider change, form publication, fixture creation, conversion, merge, deletion or email/payment action was performed in this follow-up.

## Owner decisions

- Retain one positive staff top-up purchase. Same-quantity name corrections remain allowed; later extra purchases or reductions are handled directly by the team.
- Staff top-ups use Stripe only and do not ask for invoice/PO/supplier or other finance information again. Stripe's payment confirmation suffices; Salesforce still requires the existing manual top-up receipt marker. Do not send a second original-booking confirmation.
- Recover failed/unapplied submissions by manual entry/correction on the intended record or one fresh corrected applicant form. Do not add a correct-and-reprocess action or replay the old rejected source. The previously protected failed staff Lead remains untouched.
- Keep native Salesforce Account/Contact matching unchanged. The owner declined the suggested exact-name fallback after the sparse-data explanation. No further matching fixtures are required for that declined change.
- Client production, Stripe sandbox/live and final upload/website configuration remain awaited.

These decisions are recorded in the desired workflow, proposal 22 and audit checkpoint. The current conversation supersedes the earlier pending wording without changing the old test results.

## EuroForce observation

Native queries found the original same-day EuroForce Account with no phone, website, billing city or postcode. Its Steven Skyba Contact had no email, phone, mailing city or postcode. The owner's later conversion independently created another Account/Contact with an email and phone; that conversion was already complete before this inspection.

The native conversion modal for the owner's remaining expression-of-interest Lead showed **0 Account Matches** and **1 Contact Match detected**. Expanding Contact exposed the newer populated Steven Skyba/EuroForce Contact. The modal was cancelled. The original sparse Contact was not the suggested record. This supports sparse matching information as the explanation; it is not evidence that fuzzy matching is disabled or that every possible variation has been tested.

Salesforce documents that standard Account matching needs account-name match keys supported by billing city or postal code; name alone can fail to enter the comparison. Standard Contact/Lead rules include fuzzy name comparisons with supporting data such as email, phone or title/account. [Standard Account sparse-name limitation](https://help.salesforce.com/s/articleView?id=000386375&language=en_US&type=1), [standard Contact/Lead matching](https://help.salesforce.com/s/articleView?id=sales.matching_rules_standard_contact_rule.htm&language=en_US), [conversion considerations](https://help.salesforce.com/s/articleView?id=sales.leads_notes.htm&language=en_US).

Existing active standard Account/Contact rules and the NTE-specific nonblocking intake rule were retained. No exact-name rule, sharing bypass or automatic merge was added. Staff can continue to search for and deliberately select a record when it is not suggested.

Read-only evidence is in `tmp/nte-conversion-matching-20260914/`:

- `before/record-summary.json`: relevant existing records and their saved identification fields.
- `before/metadata/unpackaged/unpackaged/`: duplicate and matching metadata retrieved by job `09SAd00000QzeT2MAJ`. The unsupported `Settings:Lead` member returned a warning; retrieved duplicate metadata remains available. Empty standard matching containers are not evidence of disabled standard rules.
- `before/lead-settings/unpackaged/unpackaged/settings/LeadConfig.settings`: retrieved by `09SAd00000QzccYMAR`; `shouldLeadConvertRequireValidation=true`, Opportunity choice visible, and No Opportunity not preselected. An unsupported `Settings:LeadConvert` member was not used as a setting.
- `before/lead-rules.json`: the three active Lead validation rules for NTE event codes, mutually exclusive interest decisions and volunteer conduct acknowledgement.
- `native-ui-observation.md`: the observed modal and cancelled inspection.

Only the two NTE application types are subject to the existing new-Opportunity guard. Volunteer/beneficiary conversion is not broadened by this follow-up.

## Delivered guide

[Form submission failure and recovery guide](../output/NTE_Form_Submission_Failure_and_Recovery_Guide_2026-09-14.docx), 14 pages, 12 sections, 4,824 words. SHA256: `38eceba599355a45bf19f5e49ecf1d749e068c4ce060143cb2a7a7ec8f53cfe4`.

It documents 60 identified conditions across browser checks, native acceptance, pricing review, reference reconciliation, staff, logistics/logo, asynchronous processing and email handling. It also covers required/conditional answers for all ten public forms, later conversion/payment states and the selected manual recovery procedure. Its local F/S/P/R/T/L/A/E case labels are guide references, not new implementation proposal numbers.

Sources are the current ten public form files and shared engine/configuration; the intake, pricing, update, notification and panel services; the current native Lead rules; the completed E2E evidence; and official Salesforce references. Relevant case descriptions distinguish an observed current rule from a platform/configuration failure that could occur. No fresh destructive or failure-inducing live test was run to write this guide.

Material limits are explicit:

- The static thank-you redirect does not prove Salesforce saved a Lead or applied its booking update. Pre-Lead failures cannot appear in the Master Panel's Update issues graph. Native error/overflow email and Salesforce investigation may be needed. [Native Web-to-Lead failure causes](https://help.salesforce.com/s/articleView?id=000386751&language=en_US&type=1).
- NTE Customer Event intake has its existing Allow/Report-only exception. Other intake retains the active standard duplicate rule with Alert, so a repeat volunteer matching an existing Contact can be rejected before a Lead exists. This is inferred from the retrieved rule and Salesforce's documented Web-to-Lead behaviour; a repeat volunteer was not submitted in this review. The owner's decision leaves matching/rules unchanged. [Duplicate rules and Web-to-Lead](https://help.salesforce.com/s/articleView?id=000387310&language=en_US&type=1).
- Reference matching does not guess identity from company or submitter details. An unknown reference fails; a valid reference for another eligible booking can update that booking. The guide tells staff/applicants to use the intended booking's reference. No new identity restriction was introduced.
- The issues graph covers saved supplementary application/acknowledgement failures, not browser, native pre-insert, general intake or external logo-upload failures. Record permissions still apply despite its global event/date/owner scope.
- Corrected fresh submissions or manual edits do not automatically clear an older failed item. Successful staff/heavy source cleanup and email-only failure are distinguished from lost data.
- Severe platform/storage/configuration failures still require a maintainer; manual entry cannot repair a broken Salesforce dependency. The document does not claim to enumerate unknown future customisation/provider incidents.

## Document verification

The owner selected the System Design template. Its actual reference DOCX was cloned; the existing fonts, styles, theme, numbering and page geometry were retained. Content was adapted to the operational guide, with left-aligned prose, a useful page-number footer and no unnecessary architecture figure. The document marker ran once for one DOCX; no further creation marker was run for revisions.

The final DOCX contains all 60 case IDs, all twelve headings and five real source hyperlinks. Only four reference ZIP parts changed; twenty remain byte-identical. The reference and every final page were inspected. The final small wording correction changed only pages 8 and 14; the other twelve rendered PNGs are byte-identical to the already inspected set, and both changed pages were reinspected. No clipped text, split table rows, missing glyphs, orphan-note pages or template placeholders remain.

Build, source inventory, render comparison and QA evidence: `tmp/nte-form-failure-guide-20260914/`. Deliver only the final Word guide; QA images are internal. No application tests or successful end-to-end sends were repeated because this follow-up changes no executable source or configuration.
