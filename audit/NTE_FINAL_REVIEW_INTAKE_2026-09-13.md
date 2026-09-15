# NTE final review — intake, pricing and preparation

13 September 2026. Internal review evidence; source inspection and inert local tests only.

No new production defect was substantiated in this bounded intake/pricing review. One reproducible test-maintenance defect remains: the form-engine savings assertions still expect the wording and amounts from before VAT was added. The current displayed savings are arithmetically correct.

The owner's new independent **Invoice requested: Yes/No**, **Payment method first**, and **hide/disable all finance questions for a genuinely £0 exhibitor booking** requirements are being implemented by the main task. They are expressly excluded from the new-findings count below. This review does not qualify that concurrent implementation or repeat its acknowledged starting omissions.

## Confirmed finding

### INTAKE-20260913-01 — Update obsolete net-only savings assertions — P3, test maintenance

**Evidence:** [tests/stress-form-engine.test.js:422](../tests/stress-form-engine.test.js#L422), with further obsolete assertions at lines 424, 428 and 433. The corresponding presentation is [assets/forms.js:515–520](../assets/forms.js#L515).

**Minimal reproducer:** run `node tests/stress-form-engine.test.js` without any build step. Result from the inspected source: **139 checks passed, 1 failed, 34,986 catalogue/boundary combinations**. The failing test is `discount savings show only selected eligible space and power reductions`.

For the Blue Light £249.50 space and two discounted sockets, the test expects `£349.50 ex VAT (£249.50 on your space + £100.00 on 2 power sockets)`. Current output is `50% discount applied: you save £419.40 including VAT on your space and power sockets.` The net saving is £249.50 + £100 = £349.50; applying 20% gives £419.40. The product output agrees with the approved VAT presentation.

**Impact:** the regression suite exits with failure. Because the first assertion throws, the later transitions within that same test do not execute in that run. Treating this as a product regression could also incorrectly restore obsolete net-only copy.

**Recommended correction:** update the expectations to the current VAT-inclusive presentation: £419.40 for the selected space plus two sockets, £299.40 for the space alone, and £180 for three discounted charity sockets. Preserve checks that eligibility changes hide stale savings and that a free space does not invent a 50% space saving. No application pricing change is warranted by this failure.

**Independent confirmation:** an additional inert-DOM probe completed the entire savings/eligibility sequence with the current VAT-inclusive amounts; all steps passed. This report does not edit the source or test.

## Work checked

| Area | Evidence and result |
| --- | --- |
| Fixed catalogue and discounts | Reviewed [NTEPricingService.cls](../force-app/main/default/classes/NTEPricingService.cls), the browser catalogue and the current application choices. The 27 fixed exhibitor spaces, 14 partner packages, exact category restrictions, discounted sockets and two/four-person exhibitor allocations agree. Paddock/reduced-depth garage power is included in the space; separately selected sockets are additional. Partner staff remain uncharged, as required. No new mismatch found. |
| Server-derived amounts | Pricing ignores supplied component amounts and derives them from the application type, recognised selection, category, socket count and planned attendance. Invalid/unknown/incomplete inputs remain `Review required`; positive extras on a complimentary space are chargeable. [NTEPricingService.cls:179](../force-app/main/default/classes/NTEPricingService.cls#L179), [calculation](../force-app/main/default/classes/NTEPricingService.cls#L265). |
| VAT | [NTEVat.cls:4–10](../force-app/main/default/classes/NTEVat.cls#L4) calculates aggregate tax once per charge, rounds to pence using HALF_UP and adds it to net. The browser calculates in pence. Conversion copies the freshly calculated gross booking amount and VAT rate; the staff top-up keeps its own saved tax rate and amount. No double-VAT path found in these intake/preparation methods. |
| Conversion | [NTEConversionGuard.cls:29–47](../force-app/main/default/classes/NTEConversionGuard.cls#L29) rejects missing, existing or already claimed booking targets before the application-copy Flow; it requires a new Opportunity and appends the saved event code. Account/Contact reuse remains possible. [NTE_Copy_Converted_Lead_to_Opportunity.flow-meta.xml](../force-app/main/default/flows/NTE_Copy_Converted_Lead_to_Opportunity.flow-meta.xml) uses an in-memory current pricing snapshot, copies application/contact/operations/billing fields to the new booking, and does not itself invoke an applicant send or Stripe creation. Existing native conversion test source includes Account/Contact reuse, older-booking preservation, no-booking rejection and existing-booking rejection; those tests were not executed again in this review. |
| Conditional serialization | [assets/forms.js:117–145](../assets/forms.js#L117) handles nested conditions, [773–784](../assets/forms.js#L773) refreshes conditions and derived fields immediately before validation, and [555–570](../assets/forms.js#L555) omits disabled/empty controls. Copied hidden fields use only enabled source controls. Additional probes below found no stale non-finance branch payload. |
| Staff updates | [NTEUpdateSubmissionService.cls:327–354](../force-app/main/default/classes/NTEUpdateSubmissionService.cls#L327) preserves an accepted top-up quantity, price and finance facts during name correction. [Validation at 399–429](../force-app/main/default/classes/NTEUpdateSubmissionService.cls#L399) rejects further increases, reductions, wrong booking types, mismatched name counts and oversized combined rosters. A names-only update does not consume the allowance. Same-batch processing updates the locked in-memory booking before validating the next submission. |
| Vehicles and established contacts | [NTEUpdateSubmissionService.cls:433–448](../force-app/main/default/classes/NTEUpdateSubmissionService.cls#L433) validates required information and optional-item order/completeness before applying fields. [476–497](../force-app/main/default/classes/NTEUpdateSubmissionService.cls#L476) replaces the complete vehicle/haulier information, including null optional fields. It does not write Contact records, contact roles, existing booking contact fields or base-payment fields. |
| Logo and matching | Logo updates use the exact booking reference and retained audit Lead; repeated confirmations preserve the original provided timestamp. Signature/date removal is an approved earlier change. Matching is restricted to eligible NTE bookings, and ambiguous references fail without an applied update. [Matching](../force-app/main/default/classes/NTEUpdateSubmissionService.cls#L131), [logo update](../force-app/main/default/classes/NTEUpdateSubmissionService.cls#L500). The absence of a real upload destination remains the existing documented dependency, not a newly discovered defect. |

## Fresh local verification

- `node tests/forms.test.js` — **passed**, including its required email-presentation/source checks.
- `node tests/stress-form-engine.test.js` — **139 passed / 1 failed**, with **34,986** catalogue/boundary combinations. The single failure is the stale test above.
- Four additional checks executed the maintained forms through the existing test harness's inert `Element.submit()` implementation. **All four passed**:
  1. Type a second contact and accessibility details on the exhibitor form, switch both branches off without dispatching change events, then request submission. The obsolete contact/accessibility fields are absent from the captured payload.
  2. Enter a separate partner event-day contact, switch to the applicant without change events, update the applicant name/email, then request submission. The event-day hidden fields contain the current applicant identity.
  3. Enter a one-place exhibitor top-up and its name, switch the top-up answer to No without change events, then request submission. Prior quantity/names are absent and the client top-up amount is zero. The server separately preserves any previously accepted purchase when applying a names-only request.
  4. Exercise Blue Light space/sockets, space-only, local-government eligibility, complimentary charity space, charity sockets and a return to a commercial category. Savings amounts and hiding behavior agree with 20% VAT.

The suite and extra probes never perform HTTP requests: transport is captured in an in-memory `posts` array. These results establish the selected browser-script behavior, not Salesforce acceptance or email delivery. No build script ran, and no production/source files were edited by this reviewer.

## Existing decisions and limits

The [current desired workflow](../NTE_DESIRED_WORKFLOW.md), [proposal 22](../NTE_CHANGE_PROPOSALS.md#proposal-22--manual-finance-workflow-13-september-2026), [checkpoint](../NTE_AUDIT_RESUME.md) and [numbered audit](NTE_STRESS_TEST_AND_IMPROVEMENTS_2026-09-07.md) govern this review. Proposal 22 supersedes the older conversion-time sends and resolves the old P03 question in favor of a new booking per application.

P02/P17 rejected-submission feedback, P12 separate-submission policy, P13 real client destinations, P14 partial-save/raw-input qualification and U20 an unknown-to-no-vehicle self-service route remain previously recorded items. They are not new findings or approvals. P10 remains declined. The current unique booking-reference field metadata also prevents interpreting a possible repeat browser payload as proof that duplicate-reference records can be created.

No fresh native Apex run, hosted-page inspection, Salesforce conversion, form POST, email send, payment, fixture cleanup or deployment took place. All recorded histories and the ten `NTE-UI-20260913-R01`–`R10` examples are untouched. Native concurrency, platform coercion and live governor-limit behavior are not requalified by this local review.

## Inspected-source fingerprint

These hashes identify the source state inspected before the main task's concurrent finance follow-up; later edits must be qualified separately.

| File | SHA-256 |
| --- | --- |
| `assets/forms.js` | `6ddadf8683d2f7dc908993da941ab3b73376b49131194790ebec3cb9207e3328` |
| `exhibitor-application.html` | `7d24d0c87f41b44bad637cf9198de5209c18177d8fd1552999ccb52647554df7` |
| `partner-sponsor-application.html` | `231e66857a6f0a5fc2f057ec3eafb6f0638d9c1d8f2f26ef6ea48a05b594ab1b` |
| `tests/stress-form-engine.test.js` | `cfdf8dafbd5109f2e4620434516ca0683fad9440204b73a53283071210dc5392` |
| `NTEPricingService.cls` | `c1c68c395adfd2f5eb2f46406fb681b410635bae36651a2659a8efa1be9587b0` |
| `NTEVat.cls` | `28002114b07b3bd9764c3719888fd538bf2fe69f2a728d86cbc7f8481efbfc5a` |
| `NTEConversionGuard.cls` | `bb4624c4bd6026345c392de34bc9c8f23aee0aed0c0eddf8591883da89ac9e20` |
| `NTEUpdateSubmissionService.cls` | `9c9e145c1beeab058cb4dd47deb7ae8d7b45067234db1dc1d64d9b3c20904c45` |
| `NTE_Copy_Converted_Lead_to_Opportunity.flow-meta.xml` | `b0e845e7b4f05331db56c558d72ec00c8ec294ceabfcd942b708c7b6465cef87` |
