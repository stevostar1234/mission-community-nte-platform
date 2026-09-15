# NTE final review — access, reports and release prerequisites

Reviewed 13 September 2026. Internal review of the proposal 22 manual-finance baseline and current local source. The selected UI13 appearance is reported by the coordinating task as deployed and passing its affected checks. Independent applicant invoice choice and £0 finance-detail hiding are being implemented concurrently; this review does not qualify their final implementation or declare retirement, fixture cleanup or the final package release complete.

## Outcome and scope

No new confirmed CRUD/FLS denial or lost record-page field was identified in the reviewed baseline. The permission sets include the current operational fields, interactive controller reads/writes use user-mode access at their entry boundary, and retained native evidence verifies Kate and Tony's group assignment and new-field access. The local report/UI/shared-picklist checks passed.

The material remaining review items are the obsolete invoice-work column still present in two finance reports, a difference between report and panel population rules, and an unqualified difference between displayed finance stages and the payment-receipt endpoint. The latter two are described below without claiming an observed corrupt record or requiring a blanket restriction on manual staff corrections/retries. Two operational handover documents were corrected within this review's explicit follow-up authorisation.

Read: `AGENTS.md`, `NTE_AUDIT_RESUME.md`, the desired workflow and proposal 22, relevant numbered stress-audit findings/decisions, manual-finance implementation/evidence, the earlier access/dependency qualification, current Apex/LWC integration, permissions/groups/sharing, four record pages, nine reports, finance formulas, manifests and production/client handover instructions.

No native submissions, emails, payments, conversions, deployments, configuration changes, test executions, record updates or deletions were performed. No native API/CLI request was needed. All NTE-UI fixtures and earlier histories remain untouched by this review. Local generators were not run. Changes are limited to this report and the two explicitly assigned operational Markdown documents.

## Findings and bounded gaps

### AR01 — Obsolete invoice-work status remains visible in native finance reports

**Confirmed source/UI-definition mismatch, already within the recorded retirement scope.** Both `NTE_06_Finance_and_Invoicing` and `NTE_09_Weekly_Finance_Report` retain `Opportunity.NTE_Finance_Invoice_Due__c`, alongside the new Requirements/Payment required/Payment confirmed columns. The old formula still derives invoice work from the billable flag, quote gate and invoice checkbox. A paid booking with an unticked invoice checklist can therefore show this old “NTE Finance Invoice Required” status while the new finance status is Payment confirmed. Sending correctly leaves that checkbox unticked under proposal 22, so this is not resolved by normal action completion.

Evidence: [old formula](../force-app/main/default/objects/Opportunity/fields/NTE_Finance_Invoice_Due__c.field-meta.xml), [finance report](../force-app/main/default/reports/NTE_Operations/NTE_06_Finance_and_Invoicing.report-meta.xml), [weekly report](../force-app/main/default/reports/NTE_Operations/NTE_09_Weekly_Finance_Report.report-meta.xml), [generator](../scripts/build-metadata.js), and the existing retirement candidate in [the implementation checkpoint](../tmp/nte-manual-finance-20260913/IMPLEMENTATION.md).

Action: include the obsolete report columns in the previously approved, dependency-qualified retirement of this formula. Preserve the independent invoice checkbox and its history. Do not clear historical flags or remove the field before its full dependency evidence and exact destructive scope are settled. The new independent applicant invoice-choice work should also distinguish the user-facing labels of the retained billable flags (`Invoice_Required__c`, `NTE_Invoice_Required__c`) from an actual invoice request; that integration is owned by the coordinating task and is not counted as a second defect here.

### AR02 — Payment receipt accepts a broader state than the displayed Payment required stage

**Confirmed endpoint behaviour; intended manual exception policy needs acceptance.** In the reviewed `NTE_MasterPanelController.updateMilestone`, the locked query loads the base/top-up request timestamps, but the two receipt branches check valid pricing, billability and already-paid status without requiring a prior accepted request or the Payment required formula. Thus the method accepts a previously unpaid charge in Requirements. A stale Payment required page can also remain open while a later staff purchase returns the booking to Requirements; its receipt call does not recheck that new combined state.

Evidence: [receipt endpoint](../force-app/main/default/classes/NTE_MasterPanelController.cls), specifically the `PAYMENT_RECEIVED` and `TOP_UP_PAYMENT_RECEIVED` branches; [display predicates](../force-app/main/default/objects/Opportunity/fields/NTE_Finance_Payment_Due__c.field-meta.xml); [manual-finance tests](../force-app/main/default/classes/NTEManualFinanceTest.cls). No live mutation was used to reproduce this source-level behaviour.

Impact is a workflow-state discrepancy, not demonstrated wrong-amount collection, payment loss or duplicate confirmation. The endpoint still checks record eligibility, user-mode access, valid pricing and already-recorded payment. Staff may legitimately need to record an independently verified receipt or correct records, so this review does **not** recommend automatically removing that flexibility. If Payment required is intended as a mandatory server transition, add a narrow locked check with tests for never-released and stale-view cases; if broader manual recording is intentional, document/test that exception. Do not make quote/invoice ticks prerequisites.

`setRequirement`, `sendFinanceAction` and `setJoiningInstructions` also have broader active-booking access than their stage-specific UI placement. That alone is not a demonstrated integrity defect: checklists are explicitly correctable, permitted retries reuse existing unpaid requests, and the joining marker does not gate completion. No blanket extra stage lock is proposed for those methods.

### AR03 — The two finance reports use a wider booking population than the panel

**Definition difference; no incorrect current row was established.** Reports 06 and 09 now filter only `(open OR won) AND NTE Event Opportunity record type`. The Master Panel's `opportunityBaseWhere` also requires a nonblank event code and one of the two commercial application source types. A manually created, legacy or incomplete Opportunity in that record type can appear in the native report and receive formula statuses despite being absent from every panel finance view.

Evidence: the report filter blocks in [report 06](../force-app/main/default/reports/NTE_Operations/NTE_06_Finance_and_Invoicing.report-meta.xml) and [report 09](../force-app/main/default/reports/NTE_Operations/NTE_09_Weekly_Finance_Report.report-meta.xml), the final finance-report definition loop in [the generator](../scripts/build-metadata.js), and `opportunityBaseWhere` in [the controller](../force-app/main/default/classes/NTE_MasterPanelController.cls).

The reports intentionally span events, and a broader diagnostic finance report could be useful; it must not be described as exact panel reconciliation without accounting for this difference. At final report qualification, compare record IDs against the commercial panel scope and identify any extra rows. Align the filters only if matching that scope is the intended report contract. This is not a request to delete or conceal unmatched legacy records.

### AR04 — Operational handover described superseded automation — corrected locally

The Stripe handover still described conversion-time link creation, automatic quote/invoice milestones, unresolved P03 conversion policy and unimplemented staff top-up links. The production plan instructed configuring automated final-pack URLs and used earlier package counts as if current.

Within the explicit follow-up assignment, updated [the Stripe client handover](../NTE_STRIPE_CLIENT_HANDOVER_2026-09-11.md) and [the production deployment plan](../NTE_PRODUCTION_DEPLOYMENT_PLAN_2026-09-08.md) to the approved manual workflow. They now distinguish new-Opportunity conversion, manual base/free/top-up actions, independent ticks/invoice choice, separate receipt history, manual joining instructions and pending qualification. Earlier test counts and native results remain explicitly dated. The handover also corrects the old disabled-Stripe fallback description: current Stripe coordinator/email checks hold a payable Stripe request instead of sending an incomplete payment email.

The coordinating task was notified that the separate client questionnaire still contained already-resolved questions about automatic ticks, conversion-time release, top-up timing and new-Opportunity conversion. That third document is outside this review's edit assignment.

## Access and field propagation evidence

- `NTE_Management_Access` combines `NTE_Management_User` and the Stripe operator permission set. The latter's API name still contains `Test`, but its current label is **NTE Stripe Payment Operator** and its source grants use of both separately configured test/live principals. This is a historical API name, not evidence that live operation needs another permission set. Credentials remain target configuration; permission to use a principal does not populate its secret.
- Both NTE operational permission sets contained 317 field-permission entries in the reviewed baseline, including every packaged Opportunity, Account, Contact, dispatch and payment-request field. NTE-specific Lead coverage excludes the separately managed volunteer-only fields as expected. New status formulas are readable and not editable. Payment-request history is read-only through these sets. No object deletion, object-wide View All/Modify All, View All Data or Modify All Data grant was found in them.
- The [13 September native access verification](../tmp/nte-manual-finance-20260913/access-verified.json) at 19:12 UTC records group status Updated, unchanged Kate/Tony assignments and all seven new operational fields readable; six persisted fields are editable and the Requirements formula is not. Earlier [native access qualification](NTE_MANAGEMENT_ACCESS_2026-09-11.md) verifies both users' record access and the report folder. These are retained native results, not a fresh Login As walkthrough.
- Interactive finance/checklist/milestone operations use `AccessLevel.USER_MODE` for their current-record reads and persisted changes. The panel and related-record controller use user-mode queries; related-record responses additionally strip unreadable fields. Existing negative tests cover a Minimum Access user being denied reads/actions. The approval/Stripe workers deliberately use system-mode processing after an authorised entry; this review did not identify a new unconstrained user-supplied record query at that boundary.
- `NTE_Operations` grants folder View to All Internal Users. The existing `NTE_Opportunities_Internal_Edit` rule shares the NTE record type with internal users at Edit. These are the documented accepted sharing model, not newly introduced permissions. The payment-request object's internal sharing model is ReadWrite, but the NTE operator sets grant only object Read; object CRUD remains necessary.
- All four dynamic record pages retain their recorded field sets: Lead 133, Opportunity 149, Account 19 and Contact 22, with no duplicate field items. The [before/after preservation evidence](../tmp/nte-manual-finance-20260913/layout-field-preservation.json) confirms no removed baseline field. The four page overrides are present for Large/Small form factors in the NTE application. Current card links use the Opportunity identity and do not replace the full record's stored fields.
- Requirements details are supplied through `NTEFinanceService.FIELDS` and the panel's combined Opportunity query. The reviewed query includes the request/checklist/billing fields used by the DTO; no unqueried field access was identified in that path. The pending independent invoice-choice field needs its own complete form → Lead → conversion → Opportunity → FLS → card/full-page/report qualification.
- All 46 entries in the inherited external-field manifest are also in the main production manifest. Missing inherited package fields were not found by that exact comparison. This does not prove that every external production automation or shared metadata dependency has been discovered.

## Reporting and local verification

Executed only these local, non-generating checks:

| Check | Result | Limit |
| --- | --- | --- |
| `node tests/metadata-reports.test.js --generated` | Passed | Pure generator definitions and existing generated files; no Salesforce Analytics run |
| `node tests/panel-ui-stress.test.js` | 38/38 passed | Actual JavaScript with mocked endpoints; no fresh Lightning browser session |
| `python3 tests/shared-picklists.test.py` | 5/5 passed | Local preservation/error cases; not a production target comparison |
| XML field/page/manifest inspection | No missing inherited manifest entry or duplicate record-page field found | Baseline snapshot while coordinating implementation continues |

All nine report definitions had unique columns. The seven Opportunity reports lock the NTE record type and retain closed-won while excluding closed-lost records. Reports include the actual native Primary Contact column. Report 09 retains `LAST_UPDATE` / `INTERVAL_LAST7`; report 06 remains all-time from its configured start date. VAT fields are included beside net totals, and the three new finance formulas do not depend on procurement ticks. The legacy invoice-work column is the exception described in AR01. Existing native report/currency results remain dated evidence and were not rerun here.

Source hashes captured during review, before any later coordinated refinement:

| Class | SHA-256 |
| --- | --- |
| NTEFinanceService | `f63423a47c76fb2ab2885715047e0db61e7ad8f0c6498b251f097aeab823d2c4` |
| NTE_MasterPanelController | `52521fa6f91773489301056b5737c872622c2c215a88d549303376bfce9f4d92` |
| NTEExhibitorApprovalEmailService | `1587a29fe4abcbbcd7cd39caca9f6352f5dc1fe8403fa24370a0d52df0e4b47b` |
| NTEEmailDispatchService | `824de8ce5b88c029c74833b748c9abec6eab58b9b8bca5579cb72077aedeee18` |

## Production prerequisites and remaining limits

These are established launch dependencies, not new optional features:

1. **Exact final candidate.** Finish the pending refinement, any approved safe retirement and final source/native/preview qualification. Record the exact current source hashes and validation result; do not reuse 314/318/334-test results as proof of subsequently edited source. Production remains a separate authorised release.
2. **Target metadata comparison.** Retrieve the actual production definitions, including shared LeadSource/OpportunityStage, standard matching/duplicate rules, record types, sales process, external automation and permissions. Preserve unrelated values/rules with the existing reviewed overlay workflow. Indexed absence alone is insufficient evidence for deleting a field or shared class.
3. **Actual operator profile and licence.** The NTE permission sets do not explicitly grant standard-field FLS; their successful use also depends on the users' profile/other permissions and record sharing. Verify the selected Standard User and administrators in the target, plus group recalculation, conversion, standard-field read/edit, report folder, Task and secure-principal access. Retained Kate/Tony evidence supports MMUAT but does not certify every future user/profile.
4. **Production forms and routing.** Source still targets the MMUAT endpoint/org/field IDs and preview preparation URLs, with the sandbox owner username. `assets/config.js` has a blank actual logo file-request destination. Retrieve/remap production IDs, confirm the real logo destination, owner/creator, sender/domain, Web-to-Lead settings and narrow auto-response exception, then verify the actual hosted production pages. Automated final-pack URLs are no longer a launch prerequisite under proposal 22; staff need the content/process for their manual joining instructions.
5. **Client Stripe configuration.** Current source binds the owner test account and MMUAT, with live mode false. Securely qualify the client's restricted credentials, org/account/mode, merchant activation, finance notification and receipt choices. Keep new requests disabled during the target setup; existing links require separate preservation/reconciliation. Standard Salesforce access does not grant Stripe Dashboard membership.
6. **Finance ownership.** The client still owns formal invoice numbering/content and bank/Stripe reconciliation. Independent invoice choice and a checked “provided” box do not establish a formal invoice or verified payment. Revised-price/cancellation/late-payment exceptions and finance cover remain operating decisions; do not silently add refund automation, webhooks or a new price-adjustment path.

No production org was inspected. No fresh restricted-user browser walkthrough, assistive-technology session, large-volume run or simultaneous live transaction was performed. Existing caps, generic Web-to-Lead acceptance/rejection feedback and historical Calculated-zero uncertainty remain the separately recorded P-numbered issues; this review does not reopen declined P10 or convert those proposals into implementation approval.
