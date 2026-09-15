# Project issues identified or reconfirmed during documentation

Reviewed 12 September 2026 against the maintained source and read-only MMUAT inspection. This file records findings, not approval to change the product. Existing audit P-numbers are preserved; DOC identifiers identify this documentation review. No business sends, submissions, conversions, deployments or financial changes were performed for this review.

## DOC01 — The metadata report test harness fails before completing

**Status:** Confirmed new finding. **Priority:** Medium, verification reliability.

Running `node tests/metadata-reports.test.js` in an isolated copy after a successful metadata build fails with `ReferenceError: write is not defined` at `evalmachine.<anonymous>:215`. The helper at [tests/metadata-reports.test.js:13](../tests/metadata-reports.test.js#L13) evaluates a slice of `scripts/build-metadata.js`. The preview test context at line 90 supplies `fs`, `path`, `root` and preview helpers, but not `write`. Its slice now includes the Stripe example-writing loop at [scripts/build-metadata.js:1441](../scripts/build-metadata.js#L1441), before the end boundary at line 1448.

This prevents the later preview/generated metadata assertions from running. It is not evidence that the reports themselves fail at runtime. The main build succeeded and regenerated zero differing files. Suggested correction: extract/evaluate only pure preview definitions, or move those definitions to an importable pure module. Simply adding a real filesystem writer to a test intended to inspect pure definitions would change that test's isolation contract. Then run the normal and `--generated` paths.

## DOC02 — One deployment lifecycle instruction still expects a retired application receipt

**Status:** Confirmed documentation inconsistency. **Priority:** Low.

[SALESFORCE_DEPLOYMENT.md:45](../SALESFORCE_DEPLOYMENT.md#L45) instructs the reader to confirm a booking reference appears in an acknowledgement after submitting an exhibitor or partner application. The current route in `NTEInboundLeadService.routeAndAcknowledge`, current stored template manifest and confirmed workflow deliberately send no applicant receipt at that stage. The reference is included in the booking email after conversion. A reconstruction using the old checklist could mistake correct current behaviour for a delivery failure. The new manual explains the current behaviour; the older checklist was not edited in this task.

## P03 — Native conversion can omit a booking or reuse an existing one

**Status:** Existing unresolved design decision, source reconfirmed. **Priority:** High where the operator chooses an unintended conversion target.

The actual native screen permits existing Opportunity selection and the option not to create an Opportunity. `NTE_Copy_Converted_Lead_to_Opportunity` runs only when `ConvertedOpportunityId` is non-null and writes directly to that ID. It does not prove that this conversion created the Opportunity. Selecting an existing booking can overwrite application/pricing fields while retaining its prior milestone history; choosing no Opportunity leaves the converted application without an NTE booking. The manual instructs creating a new Opportunity and allows Account/Contact reuse, but this is an operating procedure, not an enforced safeguard.

See [the existing P03 analysis](../audit/NTE_STRESS_TEST_AND_IMPROVEMENTS_2026-09-07.md#p03--decide-the-permitted-native-conversion-options). A control requires a separate selected design with rollback qualification. No guard is approved or implemented by this documentation task.

## P13 — Final packs and the logo file handoff need real destinations

**Status:** Confirmed configuration dependency. **Priority:** High for feature readiness.

`NTE_Routing_Config.Default` has empty `Exhibitor_Final_Pack_URL__c` and `Partner_Final_Pack_URL__c`. The live final-pack draft showed all 26 selected unsent completed bookings ineligible with a missing HTTPS destination and Send to 0 disabled. See [the captured screen](screenshots/13-final-pack-composer.png). `assets/config.js` also has empty `logoFileRequestUrl`. The app can record a logo update declaration, but this package has no binary upload storage.

Supply and verify the audience-specific final information links and external logo file-request destination. Production form hosting, routing username, client merchant, VAT/invoice policy and protected credentials also remain target configuration. The current enabled Stripe configuration is an owner-controlled test account bound to MMUAT, not a client production release.

## P02 and P17 — A generic return page cannot prove successful intake or an applied update

**Status:** Existing limitation, source reconfirmed. **Priority:** Medium.

`assets/forms.js` performs a native Web-to-Lead POST and redirects to a static return page. It receives no authenticated result proving that Salesforce accepted the Lead or that the later supplementary worker matched/applied it. A retired restricted picklist value may be rejected before a Lead exists; a validly created update can remain unmatched or fail validation. Applicant-facing failure/receipt policy is unresolved. The guide describes the actual acceptance boundary and recovery record fields, without presenting the return page as proof.

## P01 — A later manual provisional retry after payment can give conflicting stage language

**Status:** Existing unresolved policy; route-dependent. **Priority:** Medium.

The owner requires first base-payment confirmation to send even if the provisional email failed. The manual approval retry can then be considered separately; the correct treatment of an old provisional message after confirmation remains undecided. The Stripe coordinator has paid/snapshot readiness checks, so do not assume every Stripe retry follows the same path as a manual booking. Inspect the specific failed record and previously accepted confirmation before retrying. No blanket resend policy was introduced.

## P04 — Historical pricing flags can conceal incomplete component data

**Status:** Existing reconciliation need. **Priority:** Medium for financial interpretation.

Historical rows can have `Calculated` and a zero/non-null listed total without the complete current pricing evidence. Panel predicates and itemised email checks intentionally answer different questions; the email renderer rejects internally inconsistent component quantities/totals. The live Home screenshot still shows two records requiring a pricing check. No historical records were repriced. A repair should inventory affected rows and preserve accepted financial history before applying the current catalogue.

## P05 — A supplementary batch above one hundred receipts records failures even when data saves

**Status:** Confirmed implementation limit. **Priority:** Medium at bulk scale.

`NTEUpdateSubmissionService.sendAcknowledgements` has a bounded acknowledgement path. More than 100 requested receipt messages produces failure/retry guidance while applied Opportunity data is retained. This is distinct from initial NTE/volunteer intake batching and the dispatch service's 500-recipient draft limit. The current manual documents the boundary. A bulk-capacity change would require queue/recovery design and qualification; no live-volume failure was newly induced here.

## P06 — The panel row browser does not expose every row beyond its accessible cap

**Status:** Confirmed implementation limit. **Priority:** Medium for larger editions.

`NTE_MasterPanelController.configurePagination` bounds accessible rows at 2000 while summary counts can represent a larger set. The operator can use reports/native lists for broader work, but the panel is not a complete bulk browser above that limit. Home aggregation and Salesforce query/heap limits also need qualification for substantially larger data volumes. This review makes no claim that a specific larger-volume failure has occurred.

## P07 and P08 — Some failed-intake and historical receipt recovery still requires administrative work

**Status:** Existing recovery gaps. **Priority:** Medium.

Initial intake has audit fields but no dedicated Master Panel retry action. A retained supplementary Lead whose acknowledgement failed can use Retry update email only when its saved applied booking association is valid. Older applied records without that durable association cannot safely be rematched using a current reference alone. A tailored recovery must preserve already accepted receipts and previously applied data. The manual provides the supported retry routes and distinguishes these cases.

## P14 — Pricing maintenance helpers discard partial-save outcomes

**Status:** Confirmed code property; resulting data failure not reproduced. **Priority:** Medium for maintenance visibility.

`NTEPricingService.recalculateLeads` and `recalculateOpportunities` call `Database.update(..., false, AccessLevel.SYSTEM_MODE)` at lines 136 and 160 without inspecting the returned `SaveResult` entries. A target validation rule or other record-specific DML failure could therefore leave a subset unchanged without returning a per-record outcome to a maintenance caller. This is not evidence of failure on the normal conversion pricing path, which returns a repriced in-memory Lead. Before using a historical backfill, reconcile actual before/after values and consider returning explicit results in a separately approved change.

## P16 — A future canonical event can become the default working edition

**Status:** Existing unresolved policy, code reconfirmed. **Priority:** Low to medium.

`NTE_MasterPanelController.eventOptions` and `resolveEventCode` select the highest available canonical event when no explicit edition is supplied. Future fixtures or early registrations can make Home/Master Panel open a later year than the team intends to manage. Operators can select the correct event. An explicit working-edition preference remains a separate decision; the browser's April rollover and routing edition are related configuration but do not replace the panel's current resolver.

## Intentional boundaries that are not new defects

- Closed Lost bookings continue to accept valid preparation updates, including an otherwise valid first staff top-up after a pack. This is an explicitly confirmed rule, not an unresolved cancellation policy.
- Changed-booking payments and paid cancellations use the selected manual bank-transfer/refund/Closed Lost process. No automatic reprice/refund/cancellation synchronisation is expected.
- Automatic Stripe staff top-up links are not implemented; initial booking Payment Links are the qualified automated scope.
- The three retained legacy top-up list views are the existing P09 retirement choice, not evidence that the current combined finance queues are broken.
- P10 CSV prefix changes were explicitly declined. This register does not reopen that request.
- No age threshold or guest/volunteer duplicate-submission policy is invented by this review.
- All previously corrected F01–F34 items remain historical evidence. They have not been relabelled as newly open defects.

## Verification performed for this register

Read-only source analysis and MMUAT screenshots; successful native source retrieve with 63 compared bodies matching; isolated generator rebuild with zero output differences; passing forms/email/panel/form-engine/picklist/preflight suites. The metadata report harness failure is the one newly reproduced failing local suite. No full-org tests or business fixtures were replayed. See the manual's verification table for exact local counts.
