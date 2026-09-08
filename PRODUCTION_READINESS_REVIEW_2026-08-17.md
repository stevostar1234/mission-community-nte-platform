# NTE production-readiness review

Historical evidence: pricing-by-request scenarios and recommendations below were retired by the client on 6 September 2026. Follow NTE_DESIRED_WORKFLOW.md for current behaviour; do not restore those options or workflows.
Review date: 17 August 2026

Scope: public forms, Salesforce data model and automation, conversion, pricing, email, reports, NTE Management, hosting, privacy, accessibility and operations.

This is a production gate review, not a claim of legal, accessibility or security certification. MMUAT functional evidence is strong, but the critical and high items below should be resolved or explicitly accepted before enabling production submissions.

## Critical production gates

- **Replace every sandbox endpoint and identifier.** The current site posts to `test.salesforce.com`, uses the MMUAT organisation ID and sandbox return URLs. Production requires newly generated Web-to-Lead values and a production return URL.
- **Obtain final legal links and wording.** The current testing Terms page is not a substitute for client-approved NTE Terms and Conditions, Privacy Policy and consent wording.
- **Configure the secure logo destination.** The upload handoff is intentionally inactive until Mission Community provides and approves the File Request or equivalent secure upload URL.
- **Approve the pricing catalogue in writing.** Confirm all package, space, additional-staff and socket prices, including the £50 discounted socket rate for charity, government and blue-light applicants, before production.
- **Decide how price-on-request items become invoiceable.** Known fixed-price components are captured, but Troops’ Track Day and extra-large exhibitor space need an authorised manual price, approval owner and audit trail.
- **Run a production-specific release rehearsal.** Revalidate assignment, duplicate and auto-response rules, field-level security, sender identity, reports and all journeys in the target org; the existing evidence is from MMUAT.

## Commercial and finance controls

- The implementation stores summary prices, not Salesforce Products, Price Books or Opportunity Line Items. Finance can report totals now, but native quote/invoice line generation would be stronger with a normalised product model.
- VAT is not calculated or stored. The captured totals and Opportunity Amount are ex-VAT; finance must approve this convention and apply VAT in the downstream quoting/invoicing process.
- There is no resolved POA amount field. Add one or a proper line item before finance treats a POA Opportunity as complete.
- There are no invoice lifecycle fields for quote number, invoice number, issue date, due date, payment status, balance or credit/cancellation status.
- A paid application sets the invoice requirement, but an operational approval/payment gate is still needed before the booking is treated as fully confirmed.
- The finance report must distinguish listed total, approved override, VAT and final invoice total if manual negotiation or discounting is introduced.
- Current report totals include all matching history. Event-code filtering must be mandatory in the future Master Panel to avoid combining multiple NTE editions.
- Free space plus no extras correctly produces £0 and no invoice requirement; free space with sockets or staff becomes billable and must remain in finance reconciliation.

## Data model and workflow

- The pricing catalogue is duplicated in browser JavaScript and Apex. The server is authoritative, but both files and the version marker must be updated together so the displayed estimate matches the stored amount.
- The current pricing version name is NTE27-specific. Future-event maintenance needs an approved price effective date/version and evidence that older bookings retain their historic values.
- Browser-generated booking references reduce collisions and are unique in Salesforce, but a deliberate double submission creates two different references. Add duplicate-review guidance or a submission idempotency design if this becomes common.
- Standard manual Lead conversion can create or merge the wrong Account/Contact. Provide a conversion checklist or guided action covering duplicate selection and Opportunity naming.
- Account and Contact fields describe the latest NTE application. Multi-year participation history belongs on Opportunities; staff should not treat the Account flags as the complete attendance record.
- Staff names are stored as multiline text rather than individual attendee records. This is weak for personal badges, per-person access requirements, cancellations and check-in.
- Guest and accompanying-guest details share one Lead. A companion cannot be checked in, cancelled or reported independently without manual interpretation.
- Heavy logistics supports three item slots. Organisations with more items need a documented exception or a normalised related-item object.
- Successful staff and vehicle update Leads are deleted after processing, leaving the latest values and audit fields on the Opportunity but no immutable submission history. Confirm that this retention model meets operational and audit needs.
- Staff updates represent the replacement total of extra attendees, not an incremental charge. Make that clear in operator guidance to avoid adding the same charge twice.
- Exhibitor EOIs need an internal qualification status, owner action, follow-up date, outcome and rejection/closed reason for a managed funnel rather than an unstructured queue.

## Automation, errors and security

- `NTEPricingService` recalculates trusted values server-side, which protects against browser price tampering; retain this invariant in every future change.
- Pricing recalculation uses partial system-mode updates. Per-record failures must be surfaced to an exception list or alert rather than being silently skipped in bulk scenarios.
- The pricing service uses `without sharing` and system-mode DML. Complete a least-privilege review and document why each elevated operation is required.
- Failed update Leads retain detailed error and stack-trace information. Restrict those diagnostic fields because internal implementation details should not be broadly visible.
- The assignment owner is configured by a specific sandbox username. Replace this with a production-safe queue, Custom Metadata setting or documented service owner to avoid failure when a person changes role.
- The inbound email service caps work per transaction. Ordinary Web-to-Lead runs one submission at a time, but bulk imports need a documented limit and recovery process.
- The public forms use a honeypot but no CAPTCHA or rate limiter. Monitor Web-to-Lead limits and spam; add a stronger abuse control if traffic or bot submissions become material.

## Email and communications

- “Accepted by Salesforce” proves only that Salesforce accepted the send request. Add bounce/delivery monitoring and do not interpret that status as delivered or opened.
- There is no automatic retry or escalation for applicant/internal email failure. Add a visible failed-email work queue or monitored notification path.
- Validate the production org-wide sender, reply-to address, SPF/DKIM/DMARC alignment and email deliverability before launch.
- Test each message in Outlook desktop, Outlook web, Gmail and common mobile clients; Salesforce compilation and browser previews do not prove email-client rendering.
- Email logos are loaded from GitHub Pages. Consider a client-controlled durable asset host so acknowledgements do not depend on a personal GitHub Pages site.
- Revalidate that the generic Mission Motorsport Web-to-Lead response rule cannot match the production `Customer Event` classifications.

## Access, privacy and retention

- The user asked for broad NTE app/report visibility, but reports contain contact, accessibility and billing data. Confirm the audience and apply least-privilege sharing for sensitive operational fields.
- The permission set exposes many NTE fields to every assigned app user. Consider separate operations, finance and administrator permission sets with read/edit differences.
- Establish a retention/deletion schedule for unconverted Leads, guest details, accessibility information and diagnostic failures.
- Define who can export guest, staff, accessibility and finance reports and how exported files must be protected.
- Confirm lawful basis, privacy notice coverage and data-subject request handling for accompanying guests whose details are submitted by another person.

## Public-site UX, accessibility and ownership

- The partner/sponsor and exhibitor application links are currently visible on the public hub. Confirm whether applications should be public or invitation-only before launch.
- GitHub Pages is hosted under a personal account. Transfer operational ownership or document succession, repository access, branch protection and incident recovery before production.
- The site does not yet use a client-branded domain. A branded domain would improve trust and allow clearer ownership and security policy management.
- Google Fonts is a third-party dependency. Confirm the privacy/CSP position or self-host fonts; system fallbacks must remain acceptable.
- Selected-card styling uses modern `:has()` support. The controls remain usable without it, but include older enterprise browsers in compatibility testing if the client requires them.
- Required checkbox groups need explicit group-level accessible error association (`aria-describedby`/`aria-invalid`) in addition to focusing the first invalid control.
- The mobile EOI audit found a testing-notice/card overlap; it was fixed with explicit spacing and the public asset version was bumped. Preserve mobile regression evidence in future releases.
- A screenshot review cannot certify WCAG compliance. Run keyboard-only, screen-reader, zoom/reflow, contrast and automated accessibility checks with representative users.
- There is no automated cross-browser visual-regression suite. Add stable desktop/mobile captures for all conditional states before the next major form change.

## Release governance

- The generated `mission-community-forms/` mirror and Salesforce email metadata come from the build script. Always run `npm run validate`; do not hand-edit generated copies without regenerating and reviewing the result.
- Web-to-Lead field IDs are org-specific. Maintain a production mapping checklist and compare every submitted field with Salesforce describe metadata before enabling the live endpoint.
- Keep deployment manifests additive and continue the no-destructive-changes rule. Backfills should remain update-only and report their exact record counts.
- The Master Panel is still awaiting a selected design and has not been implemented. Do not describe it as a production feature until the user chooses a design and it passes Salesforce UI acceptance.
- Maintain an owner, due date and explicit acceptance decision for every critical/high item in this review before go-live.
