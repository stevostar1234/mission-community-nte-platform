# NTE independent implementation review — 22 September 2026

**Reviewer:** Claude (Fable 5.1), commissioned by Steven Skyba (Anthrion) for Mission Community / Mission Motorsport.
**Scope:** the `mission-community-nte-platform` repository (Salesforce DX source, generator, tests, documentation), the hosted public forms (`nte27-web-to-lead-demo`, which the platform repository mirrors byte for byte at its root), the MMUAT sandbox (metadata drift, data state, Master Panel walkthrough) and the NTE reports. The volunteer application form is **outside NTE scope** (it is a separate extra for the client's Mission app); its observations are recorded at the end for information only.
**Question asked:** does the implementation honour the agreed workflow — automated but recoverable, simple for a basic administrator, preventing problems before submission where possible — and can every record be moved through every stage manually as a fallback?

## 1. Result

No blocking defect was found. The workflow is implemented as agreed: expressions of interest and applications route and acknowledge themselves, conversion is silent and guarded, the three finance refiners are mutually exclusive and exhaustive, the supplementary update forms match bookings by exact reference and surface failures in **Update issues**, and staff can progress every stage from the Master Panel or the record page. The browser-side pricing catalogue and the server-side allowlist are in step (`NTE27-2026-09-13-VAT`).

Nineteen findings were recorded. Seven pull requests fix the ones that are defects or missing fallbacks (one of them, PR #8, waits on a sandbox housekeeping step); the rest are limitations or business decisions for the client, listed in §4. The repository and the sandbox match: a full metadata retrieval (617 components) showed only formatting differences, and the Apex, component, permission-set class access and custom-metadata values are identical.

| Area | Outcome |
| --- | --- |
| Metadata drift (repo vs MMUAT) | None beyond XML formatting |
| Org data state | Clean; no stuck records; Update issues 0 |
| Local suites (before this review) | Pass, except `page-isolation` on Windows (tooling bug, fixed) |
| Org Apex tests | 456/458 baseline; the 2 failures are in the out-of-scope volunteer test class |
| Reports vs panel | Consistent, one deliberate difference (P) |

## 2. Pull requests

All branches start `review/`; nothing was merged or deployed. Each Salesforce PR was validated with a **check-only** deployment of only its changed components against MMUAT, running the test classes that cover the changed code (nothing was saved to the org).

| PR | Title | Findings | Validation |
| --- | --- | --- | --- |
| platform #1 | Keep heavy-vehicle logistics contacts on the booking | A | Succeeded — 16 components, 166 tests, coverage 91.9% / 96.8% |
| platform #2 | Close intake, top-up and dispatch retry gaps (O02, O04, O07, O08) | B, C, D, E | Succeeded — 6 components, 164 tests, coverage 92.0% / 95.6% / 97.7% |
| platform #3 | Master Panel fallbacks: blank payment method hint and "No heavy vehicle" action | H, I | Succeeded — 3 components, 135 tests, coverage 96.6% |
| platform #4 + forms #1 | Harden the public forms: disabled-until-ready submit, website addresses, pricing default | K (O03) | Local form suites; no org metadata |
| platform #5 | Run every suite from `npm test`; keep the working tree LF on Windows (O10) | O, tooling | Local; no org metadata |
| platform #6 | Make the free-space confirmation editable as a manual fallback | G | See PR for the check-only result |
| platform #7 | Add the 22 September independent implementation review | — | Documentation |
| platform #8 | Give the converted space-position note the Lead field's capacity (O05) | F | **Blocked**: the API refuses Text → Long Text Area while recycled sandbox records hold values (12 found); needs the Recycle Bin emptied or a one-time manual type change (client decision) |

## 3. Findings

Severity: **Medium** = data loss or a stage the team cannot progress without an administrator; **Low** = confusing but recoverable; **Note** = limitation or decision.

| # | Severity | Finding | Where | Status |
| --- | --- | --- | --- | --- |
| A | Medium | The heavy-vehicle form requires a main and a second contact, but the update copied only delivery/item/haulier fields; the temporary Lead is then deleted, so both contacts were lost and the acknowledgement omitted the second contact. | `NTEUpdateSubmissionService.applyHeavyFields` | Fixed, PR #1 (six additive `NTE_Logistics_*` fields; panel, report, record page, email) |
| B | Low | Retrying an intake email (`isNewSubmission=false`) reassigned the Lead back to the configured owner, undoing a staff reassignment. (Prior audit O04) | `NTEInboundLeadService` | Fixed, PR #2 |
| C | Low | The top-up guard used the editable quantity as proof that no purchase existed; clearing it let a later form reset paid history and re-increment attendance. (O02) | `NTEUpdateSubmissionService` | Fixed, PR #2 (durable-evidence predicate; names-only correction leaves an accepted purchase untouched) |
| D | Low | Dispatch-record retry checked only `Status='Failed'`; an accepted email relabelled Failed could be resent and its timestamp replaced. (O07) | `NTEEmailDispatchService` | Fixed, PR #2 (shared accepted-send predicate in history, retry and worker) |
| E | Low | An application keyed in natively had no booking reference, so conversion produced a booking that emails and update forms refused. (O08) | `NTEInboundLeadService` | Fixed, PR #2 (reference generated at intake in the forms' format; supplied references kept; no back-fill) |
| F | Low | `Exhibitor_Space_Position__c` is LongTextArea(1000) on Lead and Text(255) on Opportunity; a valid long note blocked conversion. (O05) The public form does not collect the field, so only native entry is exposed. | generator | Fix ready in PR #8; deployment needs the sandbox Recycle Bin emptied or a manual type change first |
| G | Medium | `NTE_Free_Space_Confirmed__c` was read-only for NTE roles and locked on the record page, so a complimentary booking confirmed outside the email path could not be progressed without an administrator. | generator (permission sets, record page) | Fixed, PR #6 (reviewer may decline) |
| H | Low | A billable booking with a blank payment method showed no request button in Requirements and no reason. | `NTE_MasterPanelController`, `nteMasterPanel` | Fixed, PR #3 (hint) |
| I | Medium | A booking whose logistics answer is blank or "Not known yet" sat in Logistics outstanding with no route to "No" except editing the full record; it can never complete. | Master Panel | Fixed, PR #3 ("No heavy vehicle" action, refused when vehicle details exist) |
| J | Note | "Booking payment received" is hidden in Requirements even when the provisional email failed, although the backend allows it. | `nteMasterPanel.decorateRow` | Not changed: a failed provisional email makes the send button reappear on the card, so the recovery path exists inside the approved refiner design. |
| K | Low | Forms: bare hostnames in optional URL fields produced the generic "highlighted required fields" error; submit buttons were live before the engine loaded (O03); hidden `Pricing_Version__c` default was stale. | `assets/forms.js`, HTML | Fixed, PR #4 + forms PR #1 |
| L | Note | A booking confirmed as free and later charged (waiver reversed) needs manual field edits to leave Payment confirmed. | finance formulas | Limitation; documented here. PR #6 makes the flag editable, which is the manual route. |
| M | Note | Stripe idempotency keys exclude the amount, so a re-priced replacement link within the 23-hour reconciliation hold is refused (by design). | `NTEStripeBookingService` | Design note for the planned Stripe connected-app migration. |
| N | Note | Web-to-Lead is limited to 500 submissions per org per day; a deadline surge shared with other forms would queue leads into the default owner's email. | platform limit | Decision: monitor near deadlines or raise the limit with Salesforce. |
| O | Low | No `.gitattributes`; with `core.autocrlf=true` a Windows checkout rewrote ~500 files to CRLF, breaking generated-text comparisons; `page-isolation` test keyed paths with backslashes and failed on Windows; `npm test` ran three of eight suites (O10). | tooling | Fixed, PR #5 |
| P | Note | Report NTE_05 lists bookings with `Heavy Vehicle Required = Yes`; the panel's Logistics outstanding also includes blank/"Not known yet". | report vs panel | Deliberate difference (report = confirmed vehicles for the logistics team). Decision: leave, or add a "not confirmed" report. |
| Q | Note | The event code is calculated in the browser (month ≥ 4 → next year); the server only checks the `NTE####` shape. | forms, validation rule | Acceptable: staff can correct the code; the panel filters by code. |
| R | Note | Two deterministic Apex test failures in MMUAT: `VolunteerInboundLeadServiceTest` (`MIXED_DML_OPERATION` when inserting a queue beside a Lead; flow-trigger "Limit Exceeded" in a 120-lead mixed batch). | volunteer tests | Outside NTE scope; see §5. They do not affect NTE deployments validated with specified tests. |
| S | Note | The panel's default event is the highest year present (O13); a future-year record changes the default working event. | `resolveEventCode` | Policy decision, unchanged. |

### Confirmed correct

- Pricing: browser catalogue and `NTEPricingService` allowlist agree on every space, package, socket and staff price and on the 20% VAT handling.
- Finance: `NTE_Finance_Requirements_Due__c`, `NTE_Finance_Payment_Due__c` and `NTE_Finance_Payment_Confirmed__c` are exhaustive and mutually exclusive for every combination of billable/free base charge and top-up state.
- Conversion: `NTEConversionGuard` requires a fresh Opportunity per application and rejects reuse; rejected applications are recoverable by unticking the decision; the flow copies and re-prices only on the genuine conversion transition.
- Security: `with sharing`, `WITH USER_MODE` / `AccessLevel.USER_MODE` for panel reads and writes, `SYSTEM_MODE` limited to intake audits; permission-set class access identical between repo and org.
- Reports NTE_01–NTE_09 group by event code, lock the NTE record type and include the actual primary contact; their filters agree with the panel views (P excepted).
- Update issues: unmatched, ambiguous and failed supplementary submissions are retained with a plain-English reason and can be retried after the reference or booking is corrected.

## 4. Decisions for the client

1. **Free-space flag editable (G, PR #6):** accept the manual fallback, or keep the field locked to the panel action.
2. **Logistics report scope (P):** keep NTE_05 as "confirmed vehicles only", or add a report/list of bookings still to confirm.
3. **Web-to-Lead daily cap (N):** decide whether a deadline-week surge could approach 500 submissions across all forms; if so, request a limit increase in advance.
4. **Default event (S):** keep "highest year wins", or pin the working edition in `NTE_Routing_Config__mdt`.
5. **Stripe re-pricing hold (M):** acceptable for the interim Stripe link process; revisit in the connected-app design.
6. **Receipt in Requirements (J):** the reviewer confirmed the approved refiner rule; no change proposed.
7. **Space-position capacity (F, PR #8):** empty the MMUAT Recycle Bin (12 recycled bookings hold the field) and re-validate, or change the field type once by hand in Setup, or ask for an additive field instead.

## 5. Outside NTE scope — volunteer application (for information)

The volunteer form shares the form engine and the org but is not part of NTE and does not leak into NTE views, reports or flows (all NTE queries filter on NTE form types or a non-blank event code). Observations, in case the Mission-app owner wants them:

- The Code of Conduct version literal is triplicated (HTML, JSON, validation rule) with no cross-check; a new version published without redeploying the rule would silently reject submissions (Web-to-Lead still redirects to the thank-you page).
- Any Lead created with the volunteer type and source, including manual or imported records, triggers both emails; there is no suppression.
- The internal notification goes only to the record owner (the org default lead owner); if that is a queue or inactive user it fails until reassigned; no org-wide sender address is used.
- The audit-record DML in the service is unguarded on first save; a Lead validation error elsewhere would roll back the intake.
- Two deterministic test failures (R) in `VolunteerInboundLeadServiceTest`: the queue fixture needs `System.runAs` around its setup-object DML; the 120-lead mixed batch exceeds the flow-trigger limit.

## 6. Method and evidence

- Repository review of every Apex class, the Master Panel component, the generator, flows, permission sets, reports, list views and email templates; forms reviewed in the canonical `nte27-web-to-lead-demo` repository (the older `mission-community-nte-forms` repository is retired and redirect-only).
- MMUAT: full metadata retrieval compared with the repository; data-state queries for stuck records; Master Panel walked through Interest, Applications, Approved, Finances (Requirements / Payment required / Payment confirmed), Updates and the event breakdown; Apex tests run for the intake, update, finance and volunteer classes.
- Local suites run before and after each change; each Salesforce PR validated with a check-only deployment of its changed components and the covering test classes (results in §2 and in each PR).
- Nothing was deployed, merged or changed in the org.
