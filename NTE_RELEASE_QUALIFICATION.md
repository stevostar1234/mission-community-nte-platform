# NTE forms release qualification

Current 13 September manual-finance and invoice-choice qualification supersedes earlier workflow results: 351 native tests passed; MMUAT release `0AfAd00000SuVllKAF`, all 11 metadata retirements, nine native reports and the matching canonical preview are verified. Five fresh conversions and the £60 Stripe example are retained. See [the final audit](audit/NTE_MANUAL_FINANCE_FINAL_AUDIT_2026-09-13.md) and [current checkpoint](NTE_AUDIT_RESUME.md) for the completed 14 September cleanup evidence and remaining production decisions.

Historical evidence: pricing-by-request scenarios and recommendations below were retired by the client on 6 September 2026. Follow NTE_DESIRED_WORKFLOW.md for current behaviour; do not restore those options or workflows.
Qualification date: 17 August 2026

Salesforce target: Mission Motorsport MMUAT sandbox (`mission-mmuat`)

Public forms: <https://stevostar1234.github.io/nte27-web-to-lead-demo/>

Package repository: <https://github.com/stevostar1234/mission-community-nte-salesforce-package>

## Release outcome

The NTE public forms, Salesforce data model, conversion mapping, update automation, emails, permissions, list views and dedicated NTE Management workspace were deployed and exercised in MMUAT. The latest full deployment succeeded with 177 components and all 57 local org tests passing. No existing records, metadata deployments or work belonging to other users were deleted or overwritten.

The only deleted records were temporary Staff Update and Heavy Vehicle Update Leads whose matching Opportunity update and acknowledgement email had both completed successfully. Application, expression-of-interest, guest, unmatched and diagnostic Leads were retained.

## Final deployment evidence

- Pricing and Exhibitor EOI full deployment: `0AfAd00000SS7HlKAL` — succeeded; all four specified Apex test classes passed.
- Pricing and Exhibitor EOI dry run: `0AfAd00000SS7CvKAL` — succeeded; `NTEPricingServiceTest`, `NTEInboundLeadServiceTest`, `NTEUpdateSubmissionServiceTest` and `NTEConversionFlowTest` passed.
- Email-template and Forms Hub follow-up deployment: `0AfAd00000SS7w5KAD` — 16 components, succeeded.
- Pricing backfill updated 16 Leads and 11 Opportunities. It created and deleted no records.

- NTE Management app deployment: `0AfAd00000SQzkTKAT` — 177 components, 57 tests, succeeded with no component or test errors.
- Full validation deployment: `0AfAd00000SQygMKAT` — 152 components, 12 tests, succeeded with no warnings or errors.
- Full production deployment to MMUAT: `0AfAd00000SQyy5KAD` — 152 components, 12 tests, succeeded with no warnings or errors.
- Earlier complete package deployment: `0AfAd00000SQx4LKAT` — 151 components, 11 tests, succeeded.
- Local package validation: `npm run validate` passed, including metadata generation and static form tests.
- GitHub Pages deployment run `31886509083` succeeded. The live site contains every required public form, including Partner / Sponsor Application.

## End-to-end submission matrix

| Journey | Submitted | Converted | Retained unconverted | Result |
| --- | ---: | ---: | ---: | --- |
| Expression of Interest | 5 | 0 | 5 | All accepted, correctly classified and owned |
| Exhibitor Application | 6 | 5 | 1 | Free, paid, discounted and POA variants covered |
| Partner / Sponsor Application | 6 | 5 | 1 | Package, contact, PO and accessibility variants covered |
| Guest Registration | 20 | 0 | 20 | 10 accompanied, 10 unaccompanied, 6 accessibility cases |
| Staff Update | 8 successful final updates | n/a | 0 successful temporary Leads | Four Exhibitor and four Partner / Sponsor Opportunities updated |
| Heavy Vehicle Update | 8 successful final updates | n/a | 0 successful temporary Leads | Same eight Opportunities updated with all vehicle fields |

All retained application, expression-of-interest and guest Leads use `LeadSource = Customer Event`, carry the exact form identity in `Web_Form_Type__c`, and were assigned to Juan Felipe Mejia. Applicant and internal email audit fields recorded acceptance by Salesforce.

## Pricing and Exhibitor EOI extension

The 17 August extension introduced numeric, separately reportable package, exhibition-space, power and additional-staff values. Browser summaries are recalculated from an allowlisted Salesforce catalogue before routing or conversion. Price-on-request items remain explicitly flagged while their known listed-price components are retained.

Six additional submissions were retained for inspection:

| Variant | Lead | Booking reference | Outcome |
| --- | --- | --- | --- |
| Paid exhibitor | `00QAd00000Tpy7uMAB` | `NTE27-E2E-EX-PAID-0817` | Converted; £1,250 Opportunity |
| Discounted exhibitor | `00QAd00000Tq5irMAB` | `NTE27-E2E-EX-DISCOUNT-0817` | Converted; £499.50 Opportunity |
| Free charity exhibitor | `00QAd00000Tq68fMAB` | `NTE27-E2E-EX-FREE-0817` | Retained Lead; £0 and no invoice required |
| Multi-package partner | `00QAd00000Tq5kTMAR` | `NTE27-E2E-PS-MULTI-0817` | Converted; £20,000 Opportunity |
| Partner with POA item | `00QAd00000Tq5nhMAB` | `NTE27-E2E-PS-POA-0817` | Converted; POA flag plus £3,000 known component |
| Exhibitor EOI | `00QAd00000Tq5m5MAB` | — | Retained in Expressions of Interest; no prices shown or stored |

The finance-report API and independent SOQL aggregation agreed after conversion: sponsorship £92,000, exhibition spaces £2,598, power £1,200, additional staff £950 and listed ex-VAT total/Opportunity Amount £96,748 across 14 invoicing rows. Email audit fields for all six submissions recorded applicant and internal messages as accepted by Salesforce; that status does not prove mailbox delivery or opening.

## Converted application traceability

### Exhibitor applications

| Variant | Lead | Booking reference | Opportunity |
| --- | --- | --- | --- |
| Free COBSEO | `00QAd00000TnoPZMAZ` | `NTE-1786799885244-XSDKUCJ8` | `006Ad00000TkpN2IAJ` |
| Paid garage | `00QAd00000TnoRBMAZ` | `NTE-1786799887533-NZ2R8DAS` | `006Ad00000TkpN3IAJ` |
| Local-government discount | `00QAd00000TnoSnMAJ` | `NTE-1786799889885-8XYMWE98` | `006Ad00000TkpN4IAJ` |
| POA and add-ons | `00QAd00000TnoUPMAZ` | `NTE-1786799891618-6DCL5SMW` | `006Ad00000TkpN5IAJ` |
| Clean energy | `00QAd00000TnoW1MAJ` | `NTE-1786799894220-2FA8CULJ` | `006Ad00000TkpN6IAJ` |
| Intentionally unconverted free Non-COBSEO | `00QAd00000TnlDCMAZ` | `NTE-1786799896160-SJV3A44Z` | — |

### Partner / sponsor applications

| Lead | Booking reference | Opportunity |
| --- | --- | --- |
| `00QAd00000TnoZFMAZ` | `NTE-1786799973244-BZV486XJ` | `006Ad00000TkpN7IAJ` |
| `00QAd00000TnoarMAB` | `NTE-1786799974363-9HLYTNMW` | `006Ad00000TkpN8IAJ` |
| `00QAd00000TnoJ8MAJ` | `NTE-1786799975792-NDRBV6BJ` | `006Ad00000TkpN9IAJ` |
| `00QAd00000TnocTMAR` | `NTE-1786799977222-7PHVVLQ9` | `006Ad00000TkpNAIAZ` |
| `00QAd00000TnnYEMAZ` | `NTE-1786799978977-UYF4NU3W` | `006Ad00000TkpNBIAZ` |
| Intentionally unconverted `00QAd00000Tnoe5MAB` | `NTE-1786799980296-CWTZ8XDZ` | — |

Conversion testing verified the booking reference, source form and version, event and secondary contacts, organisation details, schedule, accessibility, declaration and terms, packages, exhibition space, equipment, power, staff, heavy-vehicle indicator and invoicing fields on the resulting Opportunities.

## Staff and heavy-vehicle automation

Four converted Exhibitor Opportunities and four converted Partner / Sponsor Opportunities received both Staff and Heavy Vehicle updates. Testing verified:

- event and secondary contacts;
- staff names, roles, emails, mobile numbers and accessibility requirements;
- delivery and collection windows;
- three-item descriptions, registrations, dimensions and weights;
- haulier details, vehicle type, dimensions, weight and registration;
- update type, source version and processed timestamp;
- preservation of Staff data when the later Heavy Vehicle update ran.

Successful temporary update Leads were deleted only after the Opportunity update and acknowledgement email succeeded.

## `tmpVar1` incident and containment

The original Flow-launched Queueable used a static collection binding which, under the Automated Process execution context, could fail with `System.QueryException: Variable does not exist: tmpVar1`. Because the exception escaped the asynchronous transaction, Salesforce generated Flow/Apex failure emails.

The final implementation now:

- passes primitive Lead ID strings into a dedicated top-level Queueable;
- uses parameterised `Database.queryWithBinds` calls;
- keeps the service `with sharing` and uses narrowly scoped system-mode DML only where the protected automation requires it;
- catches unexpected enqueue and asynchronous failures;
- retains the temporary Lead with `NTE_Update_Status__c = Failed` plus the error message and stack trace, instead of deleting it or allowing an unhandled failure email;
- deletes a temporary Lead only after a confirmed successful Opportunity update and acknowledgement email.

After the protected fix was deployed, 18 of 18 Queueable jobs completed, with no failed jobs and no new Flow Interview errors. This confirms the unhandled-error email path is contained.

Two failed diagnostic Leads are intentionally retained for review and must not be deleted:

- `00QAd00000TnqzFMAR` — captured the original `tmpVar1` failure.
- `00QAd00000Tnr45MAB` — captured the subsequent field-access failure used to verify containment.

## Unmatched update handling

Unmatched updates remain active as Leads, change no Opportunity, and are visible in **NTE Unmatched Updates**:

- Staff: `00QAd00000TnriPMAR`, reference `NTE-QA-NO-MATCH-STAFF-20260815`.
- Heavy Vehicle: `00QAd00000TnmarMAB`, reference `NTE-QA-NO-MATCH-HEAVY-20260815`.

Both record `NTE_Update_Status__c = No Matching Booking` and a clear diagnostic message.

## Classification, email and list-view isolation

Every NTE form submits `LeadSource = Customer Event` and records the exact form in `Web_Form_Type__c`. The active generic Web-to-Lead response rule matches `Website` and the legacy Partner / Sponsor source values, not `Customer Event`; therefore these NTE submissions are structurally excluded from the normal “Welcome to Mission Motorsport” response.

The package provides dedicated Lead views for all NTE web submissions, applications, Exhibitor applications, Partner / Sponsor applications, Expressions of Interest, Guest registrations and unmatched updates, plus the **NTE Event Participation** Opportunity view.

The NTE Management release also provides **NTE Organisations** and **NTE Contacts** list views. Eleven retained converted Accounts and eleven retained converted Contacts were classified through an update-only backfill. The app was assigned to all ten active human CRM users without broadening their existing object or record-level access. See [NTE_MANAGEMENT_APP.md](NTE_MANAGEMENT_APP.md).

## Outstanding client dependency

The Logo Upload page is prepared, but final secure upload delivery cannot be enabled until the client supplies the approved upload destination or service URL. The page does not falsely claim that an upload has completed.
