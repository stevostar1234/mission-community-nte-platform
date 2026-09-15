# NTE client revisions — 10 September 2026

**Later 10 September follow-up:** privacy/livery links, visible 50% savings and internal “has been submitted” wording are now implemented with timing preserved. NTE2027 references were inspected and left unchanged. The table below records what remained at this earlier release; see [the current follow-up](NTE_CLIENT_FOLLOWUPS_2026-09-10.md) for completed selections and the current outstanding decisions.

Internal implementation and decision record. Source: Kate Lole’s **revised wording**, received 9 September at 15:02 UTC, plus her 16:46 UTC clarification that the logo question concerns the electronic signature. The owner selected the changes below, then explicitly requested complete removal of superseded garage choices and allowed disposable sandbox data to be removed. Production Salesforce and production website release are separate decisions.

## Selected changes

| Request | Result |
| --- | --- |
| Remove the logo signature, date and large tickbox | Removed all three controls and the Salesforce signature/date requirement for logo confirmations. Organisation, submitter details, exact booking reference and **Confirm logo upload** remain. Other preparation forms retain their declarations. |
| Revised introductions | Both application forms use Kate’s supplied paragraphs, including the exhibitor approval/payment note and the partner funding paragraph. |
| Show complimentary benefits beside the total | A charity selecting a free space sees **Included free: single exhibition space, one 6ft trestle table, one chair and two staff places** above the indicative total. The message disappears when the selection ceases to qualify. Paid sockets and additional staff remain chargeable. |
| Replace garage pricing everywhere in the current product | All five current form choices, browser and Salesforce calculations, Lead picklist choices, production source, current examples and relevant fixtures use the new prices below. The five superseded choices have been completely removed from native Salesforce, including inactive values. |
| Sunday setup wording | Both application forms use: “For garage exhibits and large stands in the halls, setting up between 14:00-18:00 hrs on Sunday is required. Please indicate you are able to do this.” |
| Partner inclusions | The package section states: “Your exhibitor space is included in the package price along with one power socket”. Existing allowance calculations already include that socket. |
| Stop both application-received emails | The exact original sources, examples, generated Salesforce templates and actual native template contents are backed up. Both templates and their active source/example files are removed from the current package and public preview. Applicant send routes, including retries, are suppressed. Internal notifications remain. |
| Revised partner provisional emails | Standard and Stripe variants use the supplied reservation and preparation wording, including staff names, latest artwork and Sunday setup. The vehicle paragraph appears when its Vehicle details link applies. |
| Actual package names under Allocation and charges | Partner provisional emails, including Stripe, display the selected package name or names with the saved combined charge. Multiple selections are joined with “ + ”. Display changes do not recalculate a saved payment request. |

### Garage catalogue

Prices exclude VAT. Original descriptions are retained.

| Space | Price | Included staff | Included power |
| --- | ---: | ---: | --- |
| Reduced-depth garage | £599 | 2 | Yes |
| Single paddock-side garage | £799 | 2 | Yes |
| Double paddock-side garage | £1,299 | 4 | Yes |
| Single track-side garage | £799 | 2 | No |
| Double track-side garage | £1,299 | 4 | No |

The charity total can still exceed £0 when the applicant requests chargeable extras. No arbitrary monetary valuation has been assigned to the free package.

### Email restoration

[Restoration instructions and backup](backups/2026-09-10-application-received/README.md). The ZIP contains the two original templates and the original route/generator for reference; restoration must selectively reintroduce the two routes, rather than overwrite later code. No historical application should receive a message merely because a template is restored.

## Workflow points that affect the selected changes

- **An invitation to apply is still different from approval of the completed booking.** Removing the received emails does not convert an application or reserve its package automatically. The team still reviews/converts it; conversion sends the provisional email. Complimentary conversion confirms a free booking. The on-screen submission acknowledgement remains.
- **Stripe payment confirmation is still manual.** Staff verify payment against the correct booking and record it using the existing payment action. This sends the space-confirmed email once. The revised provisional wording does not introduce a webhook or an automatic paid marker.
- **The logo destination is still a production dependency.** Removing the signature is complete, but the secure upload destination remains unconfigured. The form’s confirmation records that the applicant says they uploaded a file; it does not inspect the uploaded file. Supply the approved destination before enabling actual uploads.
- **Sunday is a wording change.** The existing exhibitor question remains optional; the existing partner question remains required. “No” does not block an application. Kate’s pasted “Optional / Drop Down / Yes / No” has not been turned into a control inside an email. Any change to optionality or enforcement needs a separate decision.
- **Financial wording needs a final commercial check before production.** The selected introduction says an invoice is issued upon booking. The current manual route sends a quotation/invoice separately, and the selected Stripe integration uses Payment Links with Stripe invoice creation disabled. The client still needs to settle the separate invoice process; wording alone does not create invoices.

## Remaining requests from Kate’s email

These are outstanding decisions or handover items, not changes quietly included in this release.

| Remaining request | How I would handle it | Size / decision |
| --- | --- | --- |
| Use NTE27 throughout all forms | Keep the canonical Salesforce value `NTE2027`, and derive `NTE27` for display. Update visible references and examples together, then check future years. This is feasible without changing record matching. The selected introductions and revised partner provisional copy already use the short display. | Small, sensible wording pass. Decide whether the same rule should apply to every email and the staff interface. |
| Add the supplied privacy link | Point the relevant privacy controls to [the NTE privacy notice](https://www.nationaltransitionevent.com/privacy). Keep separate booking terms where those are still required. Verify the final production terms destination. | Small; explicitly select it before changing the remaining forms. |
| Link to the maintained livery page | Use [Mission Motorsport’s livery page](https://www.missionmotorsport.org/livery) in the relevant vehicle instructions, so changes to guidance do not require copying it into every form. | Small. |
| Show what applicants save with a 50% discount | Add a clear saving beside the total, calculated from the corresponding full rate. For a qualifying £249.50 single space against the £499 rate, the saving is £249.50 excluding VAT. Calculate eligible power savings from the requested sockets and avoid counting a saving twice. | Small to medium; agree whether to show space savings, power savings or both. The free package benefit list is already done. |
| Partner/sponsor staff allocations | Add the requested package-specific allowances to both form and Salesforce calculations, confirmation wording and later staff updates. Agree what happens when an applicant chooses several packages, and whether/how excess staff are charged. | Medium; changes booking rules, not just labels. Existing partner staff numbers are not capped by the proposed table. |
| Explain the application decision timescale | Agree an actual service target and place it on the application/submission confirmation. The two emails where Kate suggested adding it are now removed. | Small after the team chooses a realistic timescale. Do not invent a promise. |
| Combine application receipt with provisional reservation / assume applicants are approved | The email reduction is implemented. Automatic booking approval is a separate rule: it would need a reliable invitation-to-application link, authority to approve the submitted selection and safe Account/Contact matching. | Medium to large. Keep manual conversion unless the client explicitly wants and defines automatic approval. |
| Internal notification wording and timing | Change the partner opening to “A new partner / sponsor application has been submitted.” Clarify that the internal notice follows submission and that provisional email delivery follows successful conversion. | Small wording change. Do not move its trigger merely to match an assumed workflow. |
| Automatic/bulk approval emails and logging | Provisional email sending already follows successful individual conversion, with booking-level audit and retry. Bulk **EOI invitations** already exist. For bulk application approval, add a reviewed batch with matching outcomes and unresolved cases held back. Keep each result against its exact Lead/Opportunity; an Account summary could link to those results. | Bulk conversion is a substantive feature. Decide whether it is needed; distinguish it from the existing bulk invitation action. No automatic decline email is currently provided by the Reject action. |
| Q1 — daily new-booking and Stripe-payment report | Provide separate, clearly named daily views for new submitted applications, approved bookings and payments recorded by staff, with a daily email subscription. Actual provider-payment reporting requires either Stripe’s own reporting or a reconciled integration; Salesforce’s manual marker is not proof that every provider payment has been recorded. | Reporting is straightforward once date definitions, recipients and time are agreed. Salesforce supports [scheduled report subscriptions](https://help.salesforce.com/s/articleView?id=sf.reports_subscribe_lex.htm&language=en_US&type=5). |
| Q2 — know when Stripe payment is received | Give the appropriate staff Stripe access and configure successful-payment notifications. They can check Payment Link payments in Stripe, then record receipt on the exact Salesforce booking. Add an Account summary only if required, preserving the booking/event distinction. | Access/notification setup and handover first; automatic Salesforce updates need a separately approved webhook/reconciliation feature. See [Stripe Payment Link payment handling](https://docs.stripe.com/payment-links/post-payment) and [team notification preferences](https://docs.stripe.com/get-started/account/teams). |
| Q3 — handover to Laura and future text edits | Supply the final static forms/assets, production configuration, a list of safe copy-edit locations and a short verification checklist. Keep field IDs, names, input values and scripts out of casual text edits. A new question needs coordinated form, Salesforce, email/report and validation changes. | Handover after production configuration is agreed. Text maintenance is practical; additional fields require the Salesforce developer’s involvement. |
| Q4 — Salesforce email templates | Yes: the maintained active templates are stored in Salesforce. Explain which text is editable there and how to bring edits back into the maintained source. Package names, charges and action links are dynamically rendered by code, so those parts are not ordinary static template text. | Mostly explanation and access/handover. Preserve merge markers and reconcile source after edits. |

Proposed partner staff allowances from the email: Headline 12; Gold 10; Premier 8; Champion 4; Zone Sponsor 6; Community Stage, Podcast, Event Guide, Delegate Tote Bag, Helmet Bay, Auditorium, Live Stream, Wristband and Escapade sponsors 4 each. Ordinary single/double exhibitor allocations already match the requested two/four places. “Podcast Sponsor” in the email corresponds to the current **Podcast Corner Sponsor** choice; a rename has not been silently made.

## NTE2029 investigation

The selector is populated from saved main-form Leads and qualifying bookings; it is not a hard-coded list of years. There was one NTE2029 Lead: **Cedarhaven Community Trust**, `00QAd00000URRcLMAX`, a synthetic partner/sponsor EOI from stress case `FX-EOI-PS-008`. It had `NTE_Interest_Progressed__c = true` and invitation status **Sent**. There were no NTE2029 Opportunities.

Progressed interests leave the active Interest queue but remain visible in the Recent submissions view and therefore keep their year available. That explains the apparently empty year. Under the owner’s dummy-cleanup instruction, this leftover record was recoverably deleted. Native queries now find no active NTE2029 Lead or booking, and the selector shows **NTE2028, NTE2027 and NTE2026**. No event-selector code change was necessary.

## Obsolete sandbox data and native picklist cleanup

The exact cleanup removed **37 dummy Leads, 16 dummy bookings, 22 attached email-dispatch records, one Salesforce payment-request record and 17 attached Tasks**. This includes the obsolete garage fixtures and their related preparation submissions, plus the NTE2029 EOI. Deletion was recoverable; no Accounts or Contacts were deleted, no Stripe provider payment/link was changed and no historical email was resent. The owner’s latest instruction supersedes earlier retention instructions for these exact disposable fixtures, including the old Anthrion walkthrough and the £960 exhibitor Stripe booking. The partner Stripe booking and dated audit/inbox evidence remain.

Salesforce’s native value-deletion jobs also updated **48 Leads already in the Recycle Bin**. Fifteen Account timestamps changed during cleanup; every one belongs to a removed dummy booking and remains present. All Contact timestamps are unchanged, and no records were added. The exact whitelisted IDs and side-effect checks are retained in `tmp/nte-client-revisions-20260910/cleanup-plan.json` and `cleanup-effects-verification.json`.

The current native field has **27 active values and zero inactive values**, matching the canonical source exactly. Its field ID is unchanged. **Six administrative deletion emails** are expected: five superseded garage prices, plus the unused **Extra Large Exhibitor Space – POA** value, whose retirement was already approved but whose inactive native value remained. These are Salesforce job notifications, separate from the removed applicant application-received emails.

The public repository also contained an obsolete duplicate under `mission-community-forms/`. Its 47 surviving page addresses now redirect to the corresponding maintained pages, preserving query parameters and fragments. Its stale assets and retired receipt examples were removed, so those older links cannot load an old garage catalogue.

## Verification and releases

**Complete in MMUAT and the existing client preview.** [Exact qualification](NTE_CLIENT_REVISIONS_QUALIFICATION_2026-09-10.json) records the following:

- Actual sandbox release **`0AfAd00000SrxQ1KAJ`**: **18/18 components and 193/193 affected tests**, including removal of the two stored templates.
- Final complete-manifest check-only **`0AfAd00000SrzrdKAB`**: **466/466 components and 302/302 RunLocalTests**, zero errors. All **530** canonical source/manifest hashes and all 466 component identities reconcile. Every Salesforce component changed during this task is accounted for in the actual release. Aggregate SHA256: `bb6069f36b6961fbbcef980da3ae906de3b0571fddd7db4071b94edf0a144a2f`.
- `npm run validate` passed after rebuilding the generated metadata. The form-engine stress suite passed **131 checks and 34,986 catalogue/boundary combinations**, with no failures. It checks the garage prices, allowances and extras, complimentary benefit visibility and other retained form rules.
- Four **actual stored-template renders** cover partner standard/Stripe provisional and payment-confirmed variants. The checks verify package names, saved prices, applicable preparation wording, HTML/plain text, merge markers and single currency symbols. **Zero DML and zero email invocations**; no new real submission, payment or applicant/booking email was sent.
- Canonical preview commit **[`3f3af51111acea1fdf29b9fce70805d9bb8f8521`](https://github.com/stevostar1234/nte27-web-to-lead-demo/commit/3f3af51111acea1fdf29b9fce70805d9bb8f8521)** is published: **111/111 served files byte-match**, and **13/13 retired paths return 404**. The release contains only the 82 intended website changes and preserves unrelated remote content.
- Browser inspection covers both revised forms, the free-allocation message beside the total, the unsigned logo form, standard/Stripe partner reservation examples and the legacy redirect preserving its query/fragment. The logo page has no horizontal overflow at 390px. No forms were submitted and no payment controls were used. User-facing copy was checked for implementation/reviewer commentary; references to the NTE team reviewing applications are legitimate recipient-facing workflow text.

Failed/cancelled candidates are retained only as internal evidence. The final check caught and removed two stale deployment-manifest references to the retired templates; a manifest/source check now guards against that omission. Browser and native-render coverage is not a complete email-client/device matrix.

The existing privacy/terms destinations, secure logo destination, final packs, client Stripe configuration, production credentials/field IDs and final handover remain production dependencies. This task does not authorise production Salesforce deployment or collection of real payments. Historical audits and the specifically requested receipt backup are internal evidence, not selectable product options.
