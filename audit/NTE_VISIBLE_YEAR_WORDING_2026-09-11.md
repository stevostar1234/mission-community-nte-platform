# NTE2027 versus NTE27 — visible wording inventory

Checked 11 September 2026. Read-only review requested by the owner; no form, email, Salesforce configuration, record, Stripe setting or public-site content was changed. No submissions, emails, links or payments were created.

## Finding

**The longer “NTE2027” wording remains visible in 19 published email examples, representing 16 stored templates and three additional Stripe variants.** One of those 16 is the retained generic staff receipt; the current staff-update workflow uses the two specific receipts instead. Five further types of generated communication and the Stripe checkout booking description also use the longer wording.

The published email examples contain fixed text. The stored Salesforce templates do not hard-code the literal “NTE2027”: the year label is filled into their copy when rendered. Both are included below because the recipient still sees the longer wording. The underlying Salesforce event identifier, year selectors, booking references, hidden inputs and internal configuration are deliberately excluded from the findings.

## Emails containing the longer wording

Every email in this table has a small section heading beginning **“NTE2027 · …”** and the footer **“NTE2027 • The Wing, Silverstone”**. Additional locations are specified. “Inbox preview” means the preview sentence that can appear alongside the subject in an email inbox.

| Email / published example | Where NTE2027 appears |
| --- | --- |
| [Exhibitor interest — applicant receipt](https://stevostar1234.github.io/nte27-web-to-lead-demo/email-templates/examples/exhibitor-interest-applicant-confirmation.html) | Section heading, inbox preview and footer. |
| [Exhibitor interest — internal notification](https://stevostar1234.github.io/nte27-web-to-lead-demo/email-templates/examples/exhibitor-interest-internal-notification.html) | Section heading, organisation-introduction sentence and footer. |
| [Partner / sponsor interest — applicant receipt](https://stevostar1234.github.io/nte27-web-to-lead-demo/email-templates/examples/partner-sponsor-interest-applicant-confirmation.html) | Section heading, inbox preview, thank-you paragraph and footer. |
| [Partner / sponsor interest — internal notification](https://stevostar1234.github.io/nte27-web-to-lead-demo/email-templates/examples/partner-sponsor-interest-internal-notification.html) | Section heading, inbox preview, organisation-introduction sentence and footer. |
| [Exhibitor application — internal notification](https://stevostar1234.github.io/nte27-web-to-lead-demo/email-templates/examples/exhibitor-application-internal-notification.html) | Section heading, organisation-introduction sentence and footer. The main heading already says “A new exhibitor application has been submitted.” |
| [Partner / sponsor application — internal notification](https://stevostar1234.github.io/nte27-web-to-lead-demo/email-templates/examples/partner-sponsor-application-internal-notification.html) | Section heading, organisation-introduction sentence and footer. The main heading already says “A new partner / sponsor application has been submitted.” |
| [Exhibitor provisional reservation — standard payment](https://stevostar1234.github.io/nte27-web-to-lead-demo/email-templates/examples/exhibitor-approved-confirmation.html) | Section heading, space-allocation sentence and footer. |
| [Exhibitor provisional reservation — Stripe](https://stevostar1234.github.io/nte27-web-to-lead-demo/email-templates/examples/exhibitor-stripe-provisional.html) | Section heading, space-allocation sentence and footer. |
| [Complimentary exhibitor confirmation](https://stevostar1234.github.io/nte27-web-to-lead-demo/email-templates/examples/government-charity-approved-confirmation.html) | Section heading, complimentary-space allocation sentence, confirmation paragraph and footer. |
| [Exhibitor payment / booking confirmation — standard payment](https://stevostar1234.github.io/nte27-web-to-lead-demo/email-templates/examples/exhibitor-payment-confirmed.html) | Section heading, payment thank-you / space-confirmation paragraph and footer. |
| [Exhibitor payment / booking confirmation — Stripe](https://stevostar1234.github.io/nte27-web-to-lead-demo/email-templates/examples/exhibitor-stripe-payment-confirmed.html) | Section heading, payment thank-you / space-confirmation paragraph and footer. |
| [Partner / sponsor payment / booking confirmation — standard payment](https://stevostar1234.github.io/nte27-web-to-lead-demo/email-templates/examples/partner-sponsor-payment-confirmed.html) | Section heading, payment thank-you / partnership-confirmation paragraph, logo-request paragraph and footer. |
| [Partner / sponsor payment / booking confirmation — Stripe](https://stevostar1234.github.io/nte27-web-to-lead-demo/email-templates/examples/partner-sponsor-stripe-payment-confirmed.html) | Section heading, payment thank-you / partnership-confirmation paragraph, logo-request paragraph and footer. |
| [Exhibitor staff-details receipt](https://stevostar1234.github.io/nte27-web-to-lead-demo/email-templates/examples/exhibitor-staff-update-applicant-confirmation.html) | Section heading and footer. |
| [Partner / sponsor staff-details receipt](https://stevostar1234.github.io/nte27-web-to-lead-demo/email-templates/examples/partner-sponsor-staff-update-applicant-confirmation.html) | Section heading and footer. |
| [Generic staff-details receipt — retained older template](https://stevostar1234.github.io/nte27-web-to-lead-demo/email-templates/examples/staff-update-applicant-confirmation.html) | Section heading and footer. Active in Salesforce and published as an example, but not selected by the current split staff-update handler. |
| [Vehicle / logistics-details receipt](https://stevostar1234.github.io/nte27-web-to-lead-demo/email-templates/examples/heavy-vehicle-details-applicant-confirmation.html) | Section heading, inbox preview and footer. |
| [Guest registration — applicant receipt](https://stevostar1234.github.io/nte27-web-to-lead-demo/email-templates/examples/guest-registration-applicant-confirmation.html) | Section heading, inbox preview, registration thank-you paragraph and footer. |
| [Guest registration — internal notification](https://stevostar1234.github.io/nte27-web-to-lead-demo/email-templates/examples/guest-registration-internal-notification.html) | Section heading, inbox preview, registration-introduction sentence, “Next steps” instruction and footer. |

## Generated emails and Stripe

These emails are composed by the management app, rather than being additional stored EmailTemplate records. Each uses **“NTE2027 • Exhibitors”** or **“NTE2027 • Partners & sponsors”** in the HTML header. The plain-text version includes **“Event: NTE2027”** unless the event label is already present in the entered message. The default subject and main paragraph use “NTE” without a year.

| Communication | Default subject |
| --- | --- |
| Application invitation | Your invitation to apply for NTE |
| Final information pack | Your NTE event information |
| Staff reminder | NTE staff details reminder |
| Vehicle / logistics reminder | NTE logistics details reminder |
| Logo reminder | NTE logo reminder |

Locations in the verified deployed implementation: [HTML header](</Users/stevo/Downloads/mission community updated datamodel/force-app/main/default/classes/NTEEmailDispatchService.cls:860>), [plain-text line](</Users/stevo/Downloads/mission community updated datamodel/force-app/main/default/classes/NTEEmailDispatchService.cls:441>), and [default subjects and messages](</Users/stevo/Downloads/mission community updated datamodel/force-app/main/default/classes/NTEEmailDispatchService.cls:784>). The generated-email footer itself does not contain the year. Staff can customise draft subjects/messages; arbitrary historical manual messages are outside this default-copy inventory.

**Stripe checkout booking description:** **“NTE2027 booking · [booking reference]”**. Both existing sandbox payment requests contain this longer wording. The deployed integration sends that description as the Stripe product name shown for the checkout item and as the payment description. This is confirmed from existing Salesforce data and deployed code; no checkout was initiated or payment made during this audit.

Implementation locations: [description construction](</Users/stevo/Downloads/mission community updated datamodel/force-app/main/default/classes/NTEStripeBookingService.cls:91>), [Stripe product name](</Users/stevo/Downloads/mission community updated datamodel/force-app/main/default/classes/NTEStripeClient.cls:47>), and [payment description](</Users/stevo/Downloads/mission community updated datamodel/force-app/main/default/classes/NTEStripeClient.cls:78>).

## Already using NTE27, or no longer wording found

- Both [standard partner / sponsor provisional reservation](https://stevostar1234.github.io/nte27-web-to-lead-demo/email-templates/examples/partner-sponsor-approved-confirmation.html) and [Stripe partner / sponsor provisional reservation](https://stevostar1234.github.io/nte27-web-to-lead-demo/email-templates/examples/partner-sponsor-stripe-provisional.html) use “NTE27” in their section heading, allocation sentence, main reservation paragraph and footer.
- The 15 maintained form/supporting HTML pages have no visible “NTE2027” branding, including document titles, accessibility labels and confirmation-preview text. The NTE pages use “NTE27” or “NTE 27”. This covers both interest forms, both application forms, guest registration, both staff forms, the generic staff redirect, vehicle details, logo upload, hub, thank-you, former sandbox-terms page and the two volunteer pages.
- Both volunteer email templates use Mission Motorsport branding and have no “NTE2027” wording.
- None of the 115 current Salesforce email-template subjects contains “NTE2027”; the maintained NTE subjects use plain “NTE”. Email HTML document titles also have no longer label.
- No additional literal “NTE2027” branding was found in the maintained Salesforce app interface source, form scripts or page accessibility text. Data values and event-code instructions were excluded as requested.
- The shared NTE logo has no year. Its form, Salesforce static-resource and content-asset files are identical.
- All 47 published older paths are redirect pages; none introduces separate “NTE2027” visible copy.
- The removed exhibitor / partner applicant application-received emails are not current templates or published examples. Their historical backups are not counted.

## Exact visible passages

These are extracted from the current published examples, which match the maintained files. Organisation/contact names below are illustrative preview data. The location links point to the maintained local preview source; the table above opens each published example.

### 1. Exhibitor interest — applicant receipt

Salesforce template: **NTE exhibitor expression of interest acknowledgement** (`NTE_Exhibitor_EOI_Acknowledgement`). Subject: “NTE exhibitor interest received”.

- [Inbox preview, line 11](</Users/stevo/Downloads/mission community updated datamodel/email-templates/examples/exhibitor-interest-applicant-confirmation.html:11>): “Thank you for your interest in exhibiting at NTE2027.”
- [Section heading, line 17](</Users/stevo/Downloads/mission community updated datamodel/email-templates/examples/exhibitor-interest-applicant-confirmation.html:17>): “NTE2027 · Expression of interest received”
- [Footer, line 19](</Users/stevo/Downloads/mission community updated datamodel/email-templates/examples/exhibitor-interest-applicant-confirmation.html:19>): “NTE2027 • The Wing, Silverstone”

### 2. Exhibitor interest — internal notification

Salesforce template: **Internal NTE exhibitor expression of interest notification** (`NTE_Exhibitor_EOI_Internal`). Subject: “New NTE exhibitor expression of interest”.

- [Section heading, line 17](</Users/stevo/Downloads/mission community updated datamodel/email-templates/examples/exhibitor-interest-internal-notification.html:17>): “NTE2027 · Internal notification”
- [Body / introduction, line 17](</Users/stevo/Downloads/mission community updated datamodel/email-templates/examples/exhibitor-interest-internal-notification.html:17>): “Horizon Mobility Ltd would like to exhibit at NTE2027.”
- [Footer, line 19](</Users/stevo/Downloads/mission community updated datamodel/email-templates/examples/exhibitor-interest-internal-notification.html:19>): “NTE2027 • The Wing, Silverstone”

### 3. Partner / sponsor interest — applicant receipt

Salesforce template: **NTE expression of interest acknowledgement** (`NTE_Partner_Sponsor_EOI_Acknowledgement`). Subject: “NTE expression of interest received”.

- [Inbox preview, line 11](</Users/stevo/Downloads/mission community updated datamodel/email-templates/examples/partner-sponsor-interest-applicant-confirmation.html:11>): “Thank you - your interest in partnering with NTE2027 is safely with our team.”
- [Section heading, line 17](</Users/stevo/Downloads/mission community updated datamodel/email-templates/examples/partner-sponsor-interest-applicant-confirmation.html:17>): “NTE2027 · Expression of interest received”
- [Body / introduction, line 18](</Users/stevo/Downloads/mission community updated datamodel/email-templates/examples/partner-sponsor-interest-applicant-confirmation.html:18>): “Thank you for telling us how Horizon Mobility Ltd would like to be involved with NTE2027. A member of the Mission Community team will review your interests and contact you to explore the most suitable opportunities.”
- [Footer, line 43](</Users/stevo/Downloads/mission community updated datamodel/email-templates/examples/partner-sponsor-interest-applicant-confirmation.html:43>): “NTE2027 • The Wing, Silverstone”

### 4. Partner / sponsor interest — internal notification

Salesforce template: **Internal NTE expression of interest notification** (`NTE_Partner_Sponsor_EOI_Internal`). Subject: “New NTE partner / sponsor expression of interest”.

- [Inbox preview, line 11](</Users/stevo/Downloads/mission community updated datamodel/email-templates/examples/partner-sponsor-interest-internal-notification.html:11>): “A new NTE2027 commercial expression of interest from Horizon Mobility Ltd is ready for review.”
- [Section heading, line 17](</Users/stevo/Downloads/mission community updated datamodel/email-templates/examples/partner-sponsor-interest-internal-notification.html:17>): “NTE2027 · Internal notification”
- [Body / introduction, line 17](</Users/stevo/Downloads/mission community updated datamodel/email-templates/examples/partner-sponsor-interest-internal-notification.html:17>): “Horizon Mobility Ltd would like to discuss partnering with or sponsoring NTE2027.”
- [Footer, line 41](</Users/stevo/Downloads/mission community updated datamodel/email-templates/examples/partner-sponsor-interest-internal-notification.html:41>): “NTE2027 • The Wing, Silverstone”

### 5. Exhibitor application — internal notification

Salesforce template: **Internal NTE exhibitor application notification** (`NTE_Exhibitor_Application_Internal`). Subject: “New NTE exhibitor application”.

- [Section heading, line 17](</Users/stevo/Downloads/mission community updated datamodel/email-templates/examples/exhibitor-application-internal-notification.html:17>): “NTE2027 · Internal notification”
- [Body / introduction, line 17](</Users/stevo/Downloads/mission community updated datamodel/email-templates/examples/exhibitor-application-internal-notification.html:17>): “Horizon Mobility Ltd has applied for exhibition space at NTE2027.”
- [Footer, line 54](</Users/stevo/Downloads/mission community updated datamodel/email-templates/examples/exhibitor-application-internal-notification.html:54>): “NTE2027 • The Wing, Silverstone”

### 6. Partner / sponsor application — internal notification

Salesforce template: **Internal NTE partner / sponsor application notification** (`NTE_Partner_Sponsor_Application_Internal`). Subject: “New NTE partner / sponsor application”.

- [Section heading, line 17](</Users/stevo/Downloads/mission community updated datamodel/email-templates/examples/partner-sponsor-application-internal-notification.html:17>): “NTE2027 · Internal notification”
- [Body / introduction, line 17](</Users/stevo/Downloads/mission community updated datamodel/email-templates/examples/partner-sponsor-application-internal-notification.html:17>): “Horizon Mobility Ltd has applied to participate at NTE2027.”
- [Footer, line 19](</Users/stevo/Downloads/mission community updated datamodel/email-templates/examples/partner-sponsor-application-internal-notification.html:19>): “NTE2027 • The Wing, Silverstone”

### 7. Exhibitor provisional reservation — standard payment

Salesforce template: **NTE approved exhibitor confirmation** (`NTE_Exhibitor_Approved`). Subject: “Your NTE space is provisionally reserved”.

- [Section heading, line 17](</Users/stevo/Downloads/mission community updated datamodel/email-templates/examples/exhibitor-approved-confirmation.html:17>): “NTE2027 · Exhibitor provisional reservation”
- [Body / introduction, line 17](</Users/stevo/Downloads/mission community updated datamodel/email-templates/examples/exhibitor-approved-confirmation.html:17>): “Horizon Mobility Ltd has been allocated exhibition space at NTE2027.”
- [Footer, line 25](</Users/stevo/Downloads/mission community updated datamodel/email-templates/examples/exhibitor-approved-confirmation.html:25>): “NTE2027 • The Wing, Silverstone”

### 8. Exhibitor provisional reservation — Stripe

Stripe presentation of the **Exhibitor provisional reservation — standard payment** stored template.

- [Section heading, line 17](</Users/stevo/Downloads/mission community updated datamodel/email-templates/examples/exhibitor-stripe-provisional.html:17>): “NTE2027 · Exhibitor provisional reservation”
- [Body / introduction, line 17](</Users/stevo/Downloads/mission community updated datamodel/email-templates/examples/exhibitor-stripe-provisional.html:17>): “Horizon Mobility Ltd has been allocated exhibition space at NTE2027.”
- [Footer, line 25](</Users/stevo/Downloads/mission community updated datamodel/email-templates/examples/exhibitor-stripe-provisional.html:25>): “NTE2027 • The Wing, Silverstone”

### 9. Complimentary exhibitor confirmation

Salesforce template: **NTE complimentary exhibitor confirmation** (`NTE_Complimentary_Exhibitor_Approved`). Subject: “Your complimentary NTE space is confirmed”.

- [Section heading, line 17](</Users/stevo/Downloads/mission community updated datamodel/email-templates/examples/government-charity-approved-confirmation.html:17>): “NTE2027 · Exhibitor confirmation”
- [Body / introduction, line 17](</Users/stevo/Downloads/mission community updated datamodel/email-templates/examples/government-charity-approved-confirmation.html:17>): “Forces Community Support has been allocated a complimentary exhibition space at NTE2027.”
- [Body / introduction, line 19](</Users/stevo/Downloads/mission community updated datamodel/email-templates/examples/government-charity-approved-confirmation.html:19>): “We are delighted to confirm your complimentary place at NTE2027.”
- [Footer, line 26](</Users/stevo/Downloads/mission community updated datamodel/email-templates/examples/government-charity-approved-confirmation.html:26>): “NTE2027 • The Wing, Silverstone”

### 10. Exhibitor payment / booking confirmation — standard payment

Salesforce template: **NTE exhibitor booking payment confirmation** (`NTE_Exhibitor_Payment_Confirmed`). Subject: “Your NTE exhibition space is confirmed”.

- [Section heading, line 17](</Users/stevo/Downloads/mission community updated datamodel/email-templates/examples/exhibitor-payment-confirmed.html:17>): “NTE2027 · Booking confirmed”
- [Body / introduction, line 18](</Users/stevo/Downloads/mission community updated datamodel/email-templates/examples/exhibitor-payment-confirmed.html:18>): “Thank you for your booking payment. We are delighted to confirm your exhibition space at NTE2027.”
- [Footer, line 24](</Users/stevo/Downloads/mission community updated datamodel/email-templates/examples/exhibitor-payment-confirmed.html:24>): “NTE2027 • The Wing, Silverstone”

### 11. Exhibitor payment / booking confirmation — Stripe

Stripe presentation of the **Exhibitor payment / booking confirmation — standard payment** stored template.

- [Section heading, line 17](</Users/stevo/Downloads/mission community updated datamodel/email-templates/examples/exhibitor-stripe-payment-confirmed.html:17>): “NTE2027 · Booking confirmed”
- [Body / introduction, line 18](</Users/stevo/Downloads/mission community updated datamodel/email-templates/examples/exhibitor-stripe-payment-confirmed.html:18>): “Thank you for your booking payment. We are delighted to confirm your exhibition space at NTE2027.”
- [Footer, line 24](</Users/stevo/Downloads/mission community updated datamodel/email-templates/examples/exhibitor-stripe-payment-confirmed.html:24>): “NTE2027 • The Wing, Silverstone”

### 12. Partner / sponsor payment / booking confirmation — standard payment

Salesforce template: **NTE partner / sponsor booking payment confirmation** (`NTE_Partner_Sponsor_Payment_Confirmed`). Subject: “Your NTE partnership / sponsorship is confirmed”.

- [Section heading, line 17](</Users/stevo/Downloads/mission community updated datamodel/email-templates/examples/partner-sponsor-payment-confirmed.html:17>): “NTE2027 · Booking confirmed”
- [Body / introduction, line 18](</Users/stevo/Downloads/mission community updated datamodel/email-templates/examples/partner-sponsor-payment-confirmed.html:18>): “Thank you for your booking payment. We are delighted to confirm your partnership / sponsorship at NTE2027.”
- [Body / introduction, line 21](</Users/stevo/Downloads/mission community updated datamodel/email-templates/examples/partner-sponsor-payment-confirmed.html:21>): “Please upload your latest company logo for NTE2027 marketing and event materials. We request the latest artwork from every participating organisation, as branding may have changed.”
- [Footer, line 27](</Users/stevo/Downloads/mission community updated datamodel/email-templates/examples/partner-sponsor-payment-confirmed.html:27>): “NTE2027 • The Wing, Silverstone”

### 13. Partner / sponsor payment / booking confirmation — Stripe

Stripe presentation of the **Partner / sponsor payment / booking confirmation — standard payment** stored template.

- [Section heading, line 17](</Users/stevo/Downloads/mission community updated datamodel/email-templates/examples/partner-sponsor-stripe-payment-confirmed.html:17>): “NTE2027 · Booking confirmed”
- [Body / introduction, line 18](</Users/stevo/Downloads/mission community updated datamodel/email-templates/examples/partner-sponsor-stripe-payment-confirmed.html:18>): “Thank you for your booking payment. We are delighted to confirm your partnership / sponsorship at NTE2027.”
- [Body / introduction, line 21](</Users/stevo/Downloads/mission community updated datamodel/email-templates/examples/partner-sponsor-stripe-payment-confirmed.html:21>): “Please upload your latest company logo for NTE2027 marketing and event materials. We request the latest artwork from every participating organisation, as branding may have changed.”
- [Footer, line 27](</Users/stevo/Downloads/mission community updated datamodel/email-templates/examples/partner-sponsor-stripe-payment-confirmed.html:27>): “NTE2027 • The Wing, Silverstone”

### 14. Exhibitor staff-details receipt

Salesforce template: **NTE exhibitor staff update acknowledgement** (`NTE_Exhibitor_Staff_Update_Acknowledgement`). Subject: “NTE exhibitor staff details updated”.

- [Section heading, line 17](</Users/stevo/Downloads/mission community updated datamodel/email-templates/examples/exhibitor-staff-update-applicant-confirmation.html:17>): “NTE2027 · Exhibitor staff details”
- [Footer, line 23](</Users/stevo/Downloads/mission community updated datamodel/email-templates/examples/exhibitor-staff-update-applicant-confirmation.html:23>): “NTE2027 • The Wing, Silverstone”

### 15. Partner / sponsor staff-details receipt

Salesforce template: **NTE partner / sponsor staff update acknowledgement** (`NTE_Partner_Staff_Update_Acknowledgement`). Subject: “NTE partner / sponsor staff details updated”.

- [Section heading, line 17](</Users/stevo/Downloads/mission community updated datamodel/email-templates/examples/partner-sponsor-staff-update-applicant-confirmation.html:17>): “NTE2027 · Partner / sponsor staff details”
- [Footer, line 22](</Users/stevo/Downloads/mission community updated datamodel/email-templates/examples/partner-sponsor-staff-update-applicant-confirmation.html:22>): “NTE2027 • The Wing, Silverstone”

### 16. Generic staff-details receipt — retained older template

Salesforce template: **NTE staff update acknowledgement** (`NTE_Staff_Update_Acknowledgement`). Subject: “Your NTE staff details”.

- [Section heading, line 17](</Users/stevo/Downloads/mission community updated datamodel/email-templates/examples/staff-update-applicant-confirmation.html:17>): “NTE2027 · Staff details”
- [Footer, line 19](</Users/stevo/Downloads/mission community updated datamodel/email-templates/examples/staff-update-applicant-confirmation.html:19>): “NTE2027 • The Wing, Silverstone”

### 17. Vehicle / logistics-details receipt

Salesforce template: **NTE vehicle and logistics acknowledgement** (`NTE_Heavy_Vehicle_Acknowledgement`). Subject: “NTE vehicle and logistics details received”.

- [Inbox preview, line 11](</Users/stevo/Downloads/mission community updated datamodel/email-templates/examples/heavy-vehicle-details-applicant-confirmation.html:11>): “Your NTE2027 vehicle, equipment and haulier details are safely with the operations team.”
- [Section heading, line 17](</Users/stevo/Downloads/mission community updated datamodel/email-templates/examples/heavy-vehicle-details-applicant-confirmation.html:17>): “NTE2027 · Logistics details received”
- [Footer, line 49](</Users/stevo/Downloads/mission community updated datamodel/email-templates/examples/heavy-vehicle-details-applicant-confirmation.html:49>): “NTE2027 • The Wing, Silverstone”

### 18. Guest registration — applicant receipt

Salesforce template: **NTE guest registration acknowledgement** (`NTE_Guest_Registration_Acknowledgement`). Subject: “NTE guest registration received”.

- [Inbox preview, line 11](</Users/stevo/Downloads/mission community updated datamodel/email-templates/examples/guest-registration-applicant-confirmation.html:11>): “Your NTE2027 guest registration is safely with the event team.”
- [Section heading, line 17](</Users/stevo/Downloads/mission community updated datamodel/email-templates/examples/guest-registration-applicant-confirmation.html:17>): “NTE2027 · Guest registration received”
- [Body / introduction, line 18](</Users/stevo/Downloads/mission community updated datamodel/email-templates/examples/guest-registration-applicant-confirmation.html:18>): “Thank you for registering for NTE2027 at Silverstone. We will use the information below to prepare for your visit and will send further event information closer to the date.”
- [Footer, line 43](</Users/stevo/Downloads/mission community updated datamodel/email-templates/examples/guest-registration-applicant-confirmation.html:43>): “NTE2027 • The Wing, Silverstone”

### 19. Guest registration — internal notification

Salesforce template: **Internal NTE guest registration notification** (`NTE_Guest_Registration_Internal`). Subject: “New NTE guest registration”.

- [Inbox preview, line 11](</Users/stevo/Downloads/mission community updated datamodel/email-templates/examples/guest-registration-internal-notification.html:11>): “A new NTE2027 guest registration from Alex Morgan is ready to process.”
- [Section heading, line 17](</Users/stevo/Downloads/mission community updated datamodel/email-templates/examples/guest-registration-internal-notification.html:17>): “NTE2027 · Internal notification”
- [Body / introduction, line 17](</Users/stevo/Downloads/mission community updated datamodel/email-templates/examples/guest-registration-internal-notification.html:17>): “Alex Morgan has registered to attend NTE2027.”
- [Body / introduction, line 23](</Users/stevo/Downloads/mission community updated datamodel/email-templates/examples/guest-registration-internal-notification.html:23>): “Record the primary and accompanying guest against NTE2027.”
- [Footer, line 41](</Users/stevo/Downloads/mission community updated datamodel/email-templates/examples/guest-registration-internal-notification.html:41>): “NTE2027 • The Wing, Silverstone”

## Verification and limits

- Canonical public repository: `stevostar1234/nte27-web-to-lead-demo`, branch `main`, commit `5fb41927a9e301aab921894af101891602ad72e6`. Checked at `2026-09-11T09:23:58.642597+00:00`.
- Read all 106 deployed HTML/JavaScript files discovered from the complete public repository tree: 104 HTML files and two scripts. Every request succeeded. The 59 current maintained paths match local bytes; the remaining 47 are the verified redirects. No separate SVG or web-manifest paths were present in this tree.
- Checked page text after HTML/entity parsing, inbox-preview text, document titles, alternative text, accessible labels, placeholders and form confirmation-preview attributes. Searched case-insensitively for NTE2027/NTE 2027 and common separator variants, and compared the short NTE27/NTE 27 forms.
- Queried all 115 native EmailTemplate records: 115 active, zero inactive. None has a literal longer label in HTML, plain text or subject. All 19 maintained HTML bodies, plain-text bodies and subjects match their package files after trimming boundary whitespace. The long-versus-short labels above follow their deployed rendering rules and current published examples.
- Retrieved the five current email/update/Stripe implementation classes from the sandbox. They match maintained source, apart from the final newline omitted by Salesforce retrieval. This verifies the generated header/plain-text and Stripe-description behavior independently of old reports.
- Read both existing sandbox payment descriptions; both begin “NTE2027 booking”. No provider credentials or payment URLs are included in this report.
- Searched the maintained metadata, UI, form scripts, generators and templates; excluded tests, audit history, backups, technical filenames/identifiers, hidden values and booking-reference examples from the recipient-copy findings.
- This is an inventory of maintained current copy and configured output. It is not a search of every past inbox message, externally authored final-pack PDF, client-owned external website, or arbitrary staff-written email.
- Raw read-only evidence and analysis: `tmp/nte-wording-audit-20260911/` (`email-templates.json`, `native-template-analysis.json`, `hosted-verification.json`, `hosted-visible-analysis.json`, `native/`, `payment-descriptions.json`). No deployment or publication was required.
