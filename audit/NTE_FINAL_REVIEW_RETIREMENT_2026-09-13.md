# NTE final review — bounded retirement audit

**Completion update, 14 September (Europe/London):** the root released all 11 approved retirements and completed the exact 109-record recoverable cleanup, 25 observed role cascades and seven unpaid test-link deactivations. All Accounts/Contacts and the ten UI/five INVOICE examples remain. The review below retains its capture-time findings; see [the final audit](NTE_MANUAL_FINANCE_FINAL_AUDIT_2026-09-13.md) and `tmp/nte-final-audit-20260913/cleanup-qualified.json` for actual execution and preserved failure/recovery evidence.

13 September 2026. Internal implementation and release evidence for proposal 22.

The owner authorises removal of obsolete items proven safe after the manual-finance workflow is qualified. This audit identifies an exact **11-component metadata retirement scope**, plus private Apex cleanup. It does not authorise deleting other fields, shared components, old evidence, or the ten retained `NTE-UI-20260913-*` examples. Native deletion, deployment and data cleanup are performed by the main release task, not by this audit.

The new applicant invoice requirement must use its own saved preference. `Invoice_Required__c` and `NTE_Invoice_Required__c` currently mean **billable booking**, including Stripe; top-up equivalents identify an actual separate charge. Those fields are active and are excluded from retirement.

## Evidence and limits

Read the current [desired workflow](../NTE_DESIRED_WORKFLOW.md), [proposal 22](../NTE_CHANGE_PROPOSALS.md#proposal-22--manual-finance-workflow-13-september-2026), [completed-audit checkpoint](../NTE_AUDIT_RESUME.md), [numbered stress audit](NTE_STRESS_TEST_AND_IMPROVEMENTS_2026-09-07.md) and [manual-finance implementation journal](../tmp/nte-manual-finance-20260913/IMPLEMENTATION.md) before applying this scope. Their dated successful submissions, sends and payments must not be replayed.

The review traces exact API names through current `force-app`, generators, manifest, tests, public HTML, assets and email sources/examples. It separately searches the captured native Apex bodies, triggers, email bodies and extra org metadata. The source can change during the coordinated final implementation; the release must qualify its final immutable candidate.

| Evidence | Coverage and result |
| --- | --- |
| [Exact native field identities](../tmp/nte-manual-finance-20260913/retirement-native-field-identities.json) | 654 native custom-field identities; candidate IDs are resolved to Opportunity or routing CMDT, rather than matched by unqualified field name. |
| [Native dependency edges](../tmp/nte-manual-finance-20260913/retirement-dependencies.json) | 3,039 distinct edges from 36 exact-ID batches. Source types include ApexClass, ApexTrigger, CustomField, EmailTemplate, FlexiPage, Flow, Layout, LWC and ValidationRule. This index supplies no complete census of report, permission, dynamic or external references; absence is not independent proof of safety. |
| [Native Apex classes](../tmp/nte-manual-finance-20260913/retirement-native-classes.json) and [triggers](../tmp/nte-manual-finance-20260913/retirement-native-triggers.json) | All 73 captured class bodies and two triggers searched. The five field candidates occur only in the two tests identified below. All eight proposed private-method bodies match their captured native bodies exactly. |
| [Extra org retrieve](../tmp/nte-manual-finance-20260913/retirement-org-retrieve.json) | Successful retrieve `09SAd00000QxjGfMAJ`: eight Flow files, one Workflow file, six LWC bundles/23 files, six Aura bundles/26 files and two custom-metadata records. No candidate runtime reference is present. The three obsolete routing settings occur only in the Default configuration record. |
| [Native NTE templates](../tmp/nte-manual-finance-20260913/retirement-native-emails.json) | 18 templates searched. The generic staff receipt has no current handler or indexed inbound dependency; its recorded last use is 19 August 2026, so it is historically used, not a template that has never existed in the workflow. |
| [Field inventory](../tmp/nte-manual-finance-20260913/retirement-field-inventory.json) | 360 captured package fields used as an initial inventory, then cross-checked against actual current references. A field's lack of static Apex references does not establish that it is unused by forms, native pages, reports or users. |
| [Initial active recipient population](../tmp/nte-manual-finance-20260913/retire-final-recipient-values.json), [final queryAll identities](../tmp/nte-final-audit-20260913/retirement-recipient-identities-queryall.json) and [routing values](../tmp/nte-manual-finance-20260913/retire-config-values.json) | Initial active query returned zero nonblank values. Final queryAll finds three previously deleted stress examples; each matches the prior VAT cleanup allowlist and the saved recipient/status/time backup exactly. Both final-pack URLs are null. The unused routing edition value is `NTE2027` and is backed up. Preserve these historical values in the audit backup; do not misreport queryAll population as zero. |
| [Before-package backup](../tmp/nte-manual-finance-20260913/native-backup) | Retrieve `09SAd00000QxhraMAB` preserves package metadata before the manual-finance implementation. It is rollback/history evidence, not a current-runtime dependency snapshot. |

The initial captured extra retrieve did not include a fresh census of outside-package reports, report types, layouts, profiles or permission sets. That gap is now narrowed by the supplemental native review below: 133 layouts, 22 profiles, 12 permission sets, 31 report types and 183 directly inspected report definitions, with no unexpected dependency found. Nine unchanged 2025 sample reports remain inaccessible; their exact responses and chronology are recorded without claiming their content was inspected. The final release must still successfully validate the exact post-destructive package before live deletion. An earlier sandboxed read failed at org authentication with `NamedOrgNotFoundError`; [attempt result](../tmp/nte-manual-finance-20260913/retirement-final-org.json). Later authorised read-only calls with the configured authentication succeeded. The earlier failure is not evidence that an org component is absent.

## Exact metadata scope

These components are safe retirement candidates within the implemented workflow **once the listed dependencies are removed, final native references are reconciled and destructive validation passes**. Do not expand the manifest automatically.

| Type / full name | Exact dependency and safe boundary |
| --- | --- |
| CustomField `Opportunity.NTE_Finance_Invoice_Due__c` | Native ID `00NAd00000Ib42JMAR`. Superseded formula for the old invoice refiner; no captured Apex/trigger/Flow/LWC consumer or indexed inbound edge. Current source still includes it in reports 06 and 09, `NTE_Invoices_Required`, both NTE permission sets and the generators. Remove those references first. This is the old **queue formula**, not an applicant requirement or billable flag. |
| CustomField `Opportunity.NTE_Final_Pack_Recipient__c` | Native ID `00NAd00000IZdCiMAL`. No current writer/reader outside the retired preservation-test reference and two permission sets. Active nonblank population is zero; queryAll includes three previously deleted stress examples whose exact recipient/status/time values remain backed up. Remove its generator, permissions and test reference. Preserve the current joining-instructions status, time and actor, and retained email dispatch/history evidence. |
| CustomField `NTE_Routing_Config__mdt.Application_Event_Code__c` | Native ID `00NAd00000IZdCVMA1`; parent `01IAd000003k3agMAA`. Retired final-pack edition gate, despite its old Application API name. Current invitations route from each actual Lead event with reusable participant links. Only the test fixture and Default CMDT value refer to it. Remove these and its generator/member. Preserve all actual event identity fields and browser edition configuration. |
| CustomField `NTE_Routing_Config__mdt.Exhibitor_Final_Pack_URL__c` | Native ID `00NAd00000IZdCXMA1`; same CMDT parent. Automated final-pack route removed; captured setting null. Remaining references are its fixture, config and generator. Preserve the active exhibitor application/staff/logistics/logo destinations. |
| CustomField `NTE_Routing_Config__mdt.Partner_Final_Pack_URL__c` | Native ID `00NAd00000IZdCZMA1`; same CMDT parent. Same proof and dependencies as exhibitor final-pack URL. Preserve active partner application/staff destinations. |
| ListView `Opportunity.NTE_Quotes_Required` | Old queue replaced by Requirements. Defined by `scripts/build-metadata.js`; `tests/forms.test.js` still demands its file. Remove generator/member/file and update the test to check the actual current finance views. |
| ListView `Opportunity.NTE_Invoices_Required` | Old queue replaced by Requirements. Also depends on the obsolete finance-invoice formula. Remove with that field; current report/payment/requirements views remain. |
| ListView `Opportunity.NTE_Top_Up_Invoices_Required` | Obsolete separate top-up queue, recreated by `scripts/build-communications.js`. Active top-up state is combined into Requirements / Payment required / Payment confirmed. |
| ListView `Opportunity.NTE_Top_Up_Payments_Due` | Same separate-queue retirement; do not remove the separate top-up amount, VAT, request, invoice/payment or timestamp fields. |
| ListView `Opportunity.NTE_Top_Up_Paid` | Same separate-queue retirement. Retiring the view deletes no payment history. |
| EmailTemplate `unfiled$public/NTE_Staff_Update_Acknowledgement` | Native ID `00XAd00000UKmH7MAL`, active in the captured snapshot, LastUsedDate `2026-08-19T13:19:21Z`. No current runtime caller, native extra-metadata reference or maintained public form link. Remove the generic mapping, native source pair and its two generic preview/source HTML files. **Keep** `NTE_Exhibitor_Staff_Update_Acknowledgement` and `NTE_Partner_Staff_Update_Acknowledgement`, their mappings and participant-specific pages. Preserve prior message/history evidence. |

Exact post-destructive manifest content, using the current package API version:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<Package xmlns="http://soap.sforce.com/2006/04/metadata">
    <types>
        <members>Opportunity.NTE_Finance_Invoice_Due__c</members>
        <members>Opportunity.NTE_Final_Pack_Recipient__c</members>
        <members>NTE_Routing_Config__mdt.Application_Event_Code__c</members>
        <members>NTE_Routing_Config__mdt.Exhibitor_Final_Pack_URL__c</members>
        <members>NTE_Routing_Config__mdt.Partner_Final_Pack_URL__c</members>
        <name>CustomField</name>
    </types>
    <types>
        <members>Opportunity.NTE_Quotes_Required</members>
        <members>Opportunity.NTE_Invoices_Required</members>
        <members>Opportunity.NTE_Top_Up_Invoices_Required</members>
        <members>Opportunity.NTE_Top_Up_Payments_Due</members>
        <members>Opportunity.NTE_Top_Up_Paid</members>
        <name>ListView</name>
    </types>
    <types>
        <members>unfiled$public/NTE_Staff_Update_Acknowledgement</members>
        <name>EmailTemplate</name>
    </types>
    <version>67.0</version>
</Package>
```

## Required coupled source changes

- `scripts/build-metadata.js`: remove the invoice-due formula definition and field entry, the two old quote/invoice list definitions, and the generic receipt mapping. Remove/replace the old invoice-due column in reports 06 and 09; using the active `NTE_Finance_Requirements_Due__c` keeps these reports aligned with the current queue. `allInvoicesFormula` is already unused; `quoteResolvedFormula` and `invoiceDueFormula` become dead when this retired field is removed.
- `scripts/build-communications.js`: remove the final-recipient field entry, three retired routing field entries, invoice-due registration and the complete three-top-up-view generation loop. Its `oppBase` constant becomes unused when that loop is removed. Retain all dispatch, live routing, retry-action and permission generation.
- Remove the obsolete values from `NTE_Routing_Config.Default`; removing only the generator seed does not erase an existing `<values>` element. Remove both NTE permission-set entries for the two retired Opportunity fields. Rebuild the final manifest so none of the 11 components is reintroduced.
- Remove the five field XML files, five view XML files, the generic `.email`/`.email-meta.xml` pair, `email-templates/source/staff-update-applicant-confirmation.html` and `email-templates/examples/staff-update-applicant-confirmation.html`. The exact generic preview filename has one maintained inbound source reference: the generic mapping in `build-metadata.js`. The similarly named exhibitor and partner files are different, active outputs.
- `NTEEmailDispatchServiceTest`: remove the retired routing fixture properties and assertions/assignment to the obsolete edition setting. Keep the future-event invitation test, its actual Lead event `NTE2030`, both reusable participant links, explicit `{EventCode}` rendering and settled dispatch assertions.
- `NTEUpdateSubmissionServiceTest`: replace the retired final-recipient preservation fixture/query/assertion with `NTE_Joining_Instructions_By__c`. Keep the status/time and original-payment preservation assertions and the accepted first-top-up/logistics/logo checks.
- `tests/forms.test.js`: change the source-file existence/filter checks from the retired quote/invoice views to the current Requirements, Payments Due and Payment Confirmed views. Preserve all NTE record-type isolation checks.
- Update current operational documentation to stop instructing staff to populate removed pack settings or use retired queues. The older `documentation/source-analysis` exports, file hashes and dated audits contain legitimate historical references and are evidence, not active runtime dependencies; preserve them as dated history rather than editing them to simulate a different past implementation.
- Publish the intended deletion of the two generic public HTML files to the existing canonical preview site from its current remote branch, and verify the maintained form/preview links. Do not delete or redirect participant-specific receipts.

## Private Apex scope

Seven methods have exactly one name occurrence in their captured native class body: the declaration. `closedTaskStatus` is called only by the unreachable `reminderAuditTask`. Its cache is used only by `closedTaskStatus`. There is no dynamic invocation mechanism for these private Apex methods, and current source/tests contain no other call site. Each of the eight native method bodies matches the local method body read for this audit.

| Class | Safe private removals |
| --- | --- |
| `NTE_MasterPanelController` | `actionablePaymentClause`, `allPaymentsReceivedClause`, `notBillableClause`, `personaliseReminder`, `reminderAuditTask`, `closedTaskStatus`, plus `cachedClosedTaskStatus`, the private `ReminderRecipient` class and the unused `bypassReminderDelivery` hook. |
| `NTEExhibitorApprovalEmailService` | `shortEventLabel`. Static NTE27 presentation no longer calls this old year-label helper; actual event identities remain unchanged. |
| `NTEUpdateSubmissionService` | `integerFromText`. Current intake uses its active numeric validation path. |

The private inner `NTE_MasterPanelController.ReminderRecipient` class is a transitive removal: its only non-declaration references were the signatures of `personaliseReminder` and `reminderAuditTask`, so it is orphaned after those removals. It does not carry a public API contract. The private `bypassReminderDelivery` test hook likewise has no source or test reference beyond its declaration. After the initial patch, the main task explicitly authorised removal of this class and hook; both are now removed within the same five-file scope.

Do **not** remove other similarly named invoice/payment helpers: `allInvoicesProvidedClause` feeds current invoice metrics; `anyInvoiceOutstandingClause` and `quoteResolvedClause` feed retained metric predicates. They are not dead merely because the old visible queue tabs are gone.

## Retained or uncertain components

| Item | Reason to retain |
| --- | --- |
| All current implementation classes and active LWC/Flow/Aura bundles | Current package services, controllers, jobs and guards have active runtime references. No complete class or bundle is proven dead. Native outside-package `NTERegistration*` services/REST endpoints are a separate shared application and are not retirement targets. |
| `NTEExhibitorApprovalEmailService.sendApprovalConfirmation` | Public invocable contract retained by tests/integration surface even though conversion Flow no longer calls it. Absence from that one Flow does not justify deleting the public API or the class. |
| Controller `getReminderDraft`, `sendUpdateReminders`, public DTOs and legacy view aliases | Public Aura interfaces/compatibility contracts. The legacy sender intentionally rejects attempts and directs users to recipient preview; that guard is useful behavior. Its public draft method still uses the other reminder helpers. Legacy view aliases route old links to the current finance queues. |
| Actual quote/invoice requirement, provided, date/user fields | Procurement checkboxes and invoice metrics still use them. No checklist gate should be reintroduced, but removing a gate does not remove the saved obligation/history. |
| Base/top-up billable and pricing/VAT fields | Active calculation, conversion, amount validation, payment safety and reporting dependencies. `NTE_Pricing_Ready__c` and the remaining finance formulas are also active. |
| `NTE_Final_Pack_Status__c`, `NTE_Final_Pack_Sent_At__c`, `NTE_Joining_Instructions_By__c` | Current manual joining-instructions marker plus preserved historical status/time. Old API naming does not make a reused field obsolete. |
| Email dispatch records, payment request objects, retry actions and recipient evidence | Shared invitations, reminders, booking/payment messages, idempotency, retries and historical evidence. Removing the automated final-pack route does not justify purging the shared dispatch framework or messages. |
| Lead consent/declaration, guest/volunteer/NOK fields and shared inherited fields | Some are primarily form/native-layout/audit data or have dynamic field mappings; others appear in native shared templates/layouts. Static Apex-reference counts are not a deletion criterion. Volunteer work is outside this cleanup. |
| `Lead.Logo_Upload_URL__c`, `Opportunity.NTE_Attendance_Status__c` and similar schema/page-only values | Source/schema/native-user or potential external usage remains; no evidence supports deleting saved values or user-maintained fields in this task. |
| Event codes, booking references and live application/staff/logistics/logo routing fields | Functional identity and active links. Retiring one obsolete routing default must not affect actual event values, matching, fingerprints or website configuration. |

## Release checks before considering retirement complete

1. Finish the selected UI/workflow/invoice-preference implementation and preserve already settled live test ledgers. Capture the exact final source and native data/configuration backups before destructive scope executes.
2. Remove the coupled references above. Rebuild once; verify the 11 components remain absent from maintained generated source/manifest, the retired API names remain only in the destructive manifest/history, and retained participant receipts/current requirements/payment views still exist.
3. Reconcile remaining accessible native references, then validate the exact final package **with** its post-destructive manifest and native Apex tests. A source-only build or normal deploy validation without the deletion manifest does not establish native deletion safety.
4. Have the main release task deploy/retire only that qualified immutable scope. Verify deleted component identities and retained fields, record counts/history, reports, permissions and current UI. Refresh recipient/configuration evidence if intervening activity occurred. Do not silently extend the destructive manifest when a dependency is discovered; remove its proven-obsolete reference or retain/report the candidate.
5. Verify the canonical preview publication for changed/deleted intended website files. Keep the dated backups and this exact scope with the resulting deploy/publication IDs. No replayed sends, new card payment, production release or unrelated record deletion is part of these checks.

At report creation, the audit has made no native change, send, deployment or metadata/data deletion. The main task separately authorises the scoped local private-code/test cleanup after this report is saved; final deployment/test results must be appended by the release task rather than inferred from this audit.

## Coordinated local edit outcome

After saving this scope, the main task explicitly assigned the five-class patch above, then the additional orphaned private class and hook. The eight private methods, `cachedClosedTaskStatus`, `ReminderRecipient` and `bypassReminderDelivery` are removed. The dispatch test no longer refers to the three obsolete routing fields; its future-event/link/rendering assertions remain. The supplementary-update test now verifies preservation of `NTE_Joining_Instructions_By__c` together with the existing joining status/time and original payment history.

The exact [five-file patch](../tmp/nte-manual-finance-20260913/retirement-private-source.patch), [before snapshot](../tmp/nte-manual-finance-20260913/retirement-private-before) and [source checks/hashes](../tmp/nte-manual-finance-20260913/retirement-private-source-checks.json) are preserved: four added lines, 100 removed. Checks establish absence of every intended removed identifier, unchanged public/protected/global method signatures, unchanged test-annotation counts and no added trailing whitespace. A broader `git diff --check` also sees one pre-existing trailing space in `NTEExhibitorApprovalEmailService`'s payment-confirmation guard (line 456 at this checkpoint); its identical presence in the before snapshot is verified and it was left outside this scoped patch.

No generator, metadata XML, manifest or other product file was edited by the audit worker. The main task owns those coupled edits and the native compiler/test/deployment qualification. No native Apex test result is claimed for this local source check.

## Supplemental native reference review

[Exact qualification](../tmp/nte-final-audit-20260913/retirement-native-tail-qualified.json) records the final read-only counts, field dates, permission-group identity, report omissions and deleted-record preservation. No native metadata, record, permission, email or payment was changed by these calls.

| Check | Result |
| --- | --- |
| Broader native retrieve `09SAd00000QxxTJMAZ` | 133 layouts, 22 profiles, 12 permission sets, 31 report types and the five candidate fields in two object files. There are no candidate field/template/view hits in layouts or report types. All 110 profile field entries are `readable=false` / `editable=false`. The only granting metadata entries are the expected four entries in `NTE_Management_User` and `NTE_Forms_Administration`. [Structural scan](../tmp/nte-final-audit-20260913/retirement-native-reference-structure.json). |
| Per-folder report inventory | All 13 folders from the native ReportFolder inventory were queried individually. They contain 192 distinct explicit Report members. [Folder/member inventory](../tmp/nte-final-audit-20260913/retirement-report-inventory.json). |
| Explicit report retrieve `09SAd00000QxvPuMAJ` | Retrieved 169/192 Report files. Only two candidate hits: `Opportunity.NTE_Finance_Invoice_Due__c` in NTE reports 06 and 09. These are the already identified columns to remove/replace. No external report hit. The successful job status does not imply every requested report was returned: 23 CRM sample reports were omitted, with 14 nonblank load errors and nine blank messages. [Retrieval](../tmp/nte-final-audit-20260913/retirement-reports-explicit-retrieve.json), [scan and exact omissions](../tmp/nte-final-audit-20260913/retirement-reports-initial-scan.json). |
| Analytics fallback | Read-only descriptions recovered 14 of the 23 omitted reports. Their report metadata and report-type metadata contain no candidate field, retired view, generic template name or generic template ID. The other nine return `FORBIDDEN`, specific error 103; a CLI exit code of zero for a streamed error body is not counted as a successful description. Direct report-content coverage is therefore **183/192**, not 192/192. [Qualified bodies and errors](../tmp/nte-final-audit-20260913/retirement-report-describe-qualified.json). |
| Inaccessible-report chronology | All nine inaccessible CRM sample reports retain LastModifiedDate `2025-10-30T10:14:18Z`. Four candidate fields were created `2026-09-05T20:13:02Z`; the invoice-queue formula was created `2026-09-07T22:58:42Z`. This supports the inference that those unchanged 2025 definitions did not acquire direct references to these later fields; it does not turn the unavailable contents into inspected evidence. No access settings were changed to inspect them. [Exact field creation dates](../tmp/nte-final-audit-20260913/retirement-candidate-field-dates.json). |
| Aggregated access permission set | `0PSAd000004nMWXOA2` / `NTE_Management_Access` has `Type=Group`, `IsOwnedByProfile=false`, no ProfileId, and PermissionSetGroupId `0PGAd000000S71lOAC`. It is Salesforce's aggregate for the existing **NTE Management Access** group, whose Status is `Updated`; it is not an additional independent permission set to delete. Components are `NTE_Management_User` (`0PSAd000004am0bOAA`) and `NTE_Stripe_Test_Operator` (`0PSAd000004mulZOAQ`). Preserve the group, component membership and assignments; verify it recalculates after the intended component permission update. [Aggregate](../tmp/nte-final-audit-20260913/retirement-aggregated-permission-set.json), [group](../tmp/nte-final-audit-20260913/retirement-management-permission-group.json), [components](../tmp/nte-final-audit-20260913/retirement-management-permission-group-components.json). |

The three nonblank final-recipient rows are already deleted examples from the completed stress run, not new active records. Each ID appears in the previously approved VAT cleanup allowlist, and each name, booking reference, recipient, final status and sent timestamp matches the pre-cleanup Opportunity backup exactly. [QueryAll identities](../tmp/nte-final-audit-20260913/retirement-recipient-identities-queryall.json), [preservation proof](../tmp/nte-final-audit-20260913/retirement-recipient-history-proof.json).

| Deleted Opportunity | Name | Booking reference |
| --- | --- | --- |
| `006Ad00000UdXYNIA3` | Kingswell Facilities NTE2027 | `NTE-1788822732167-L68TF6LG` |
| `006Ad00000UddEoIAJ` | Westhaven Trade Network NTE2027 | `NTE-1788822732037-YKC86PGP` |
| `006Ad00000UdmhrIAB` | Ashcombe Skills Partnership NTE2027 | `NTE-1788822732102-HKPJME9Q` |

No additional dependency blocker was found in the inspected native scope. The two expected native report columns and packaged permission entries still require their coordinated update, followed by exact destructive validation. The nine inaccessible report bodies remain an explicit coverage limit; they and the shared report/access configuration are retained unchanged.
