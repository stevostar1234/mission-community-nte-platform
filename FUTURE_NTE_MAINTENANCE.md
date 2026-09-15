# Future NTE maintenance

The form integration is edition-neutral. Do not rename form types, source values, field API names or automations for each annual event.

Operational workflow updated 13 September 2026. Preserve the confirmed manual-finance rules below. The independent Invoice Requested refinement and final review await final release and qualification; use [the current checkpoint](NTE_AUDIT_RESUME.md) for actual deployment results rather than treating these maintenance instructions as test evidence.

Before opening the next edition:

1. Update visible dates, venue wording, prices and package descriptions in the HTML pages.
2. Update the matching allowlists in `force-app/main/default/classes/NTEPricingService.cls`, then increment the same pricing-version value in both Apex and `assets/forms.js`. Browser and server catalogues must stay in sync.
3. Update the visible year and date wording in `email-templates/source/`.
4. Confirm the Terms and Conditions URL and secure logo-upload URL in `assets/config.js`.
5. Review Salesforce picklist values when packages or exhibitor choices change. Preserve existing values so historic records remain readable.
6. Run `npm run validate`, then run a Salesforce dry-run deployment before deploying.
7. Complete the lifecycle checks in `SALESFORCE_DEPLOYMENT.md` with clearly labelled QA records.

The browser calculates the event code in the `Europe/London` time zone: submissions from 1 April through 31 December use the following calendar year, while 1 January through 31 March use the current calendar year. Leave `eventCodeOverride` empty in `assets/config.js` for normal operation. A temporary explicit override may be configured as `NTEYYYY` for a controlled release, but it must be removed after that release.

The automatic event code does not update the public edition content or pricing catalogue. Before 1 April each year, review every visible NTE year, event date, delivery window, email, package description and price, then update the matching browser and Apex pricing catalogues. Do not rely on the event-code rollover as proof that a new edition is ready to publish.

The 11 September 2026 cosmetic-branding decision fixes the current email presentation to **NTE27** independently of each record's event identifier. For a future edition, review the literal labels in `email-templates/source/`, both display-label replacements in `NTEExhibitorApprovalEmailService.cls` and `scripts/build-metadata.js`, and the generated HTML/plain-text labels in `NTEEmailDispatchService.cls`. Keep required template placeholders and functional event-code handling intact. Regenerate, deploy and publish the matching previews together. The later 11 September instruction makes new Stripe descriptions year-neutral: `NTE booking · [booking reference]` in `NTEStripeBookingService.cls` needs no annual copy change. Never rewrite an existing Stripe request's saved description as part of annual branding: it is part of that request's original retry payload.

Never reuse or hand-edit a booking reference. Partner / sponsor and exhibitor applications generate the authoritative reference; staff and vehicle forms match only that exact value.

Web-to-Lead field IDs, the organisation ID and the return URL are Salesforce-org-specific. Generate and verify production mappings; never copy the MMUAT values into production unchanged.

## Enduring application URLs and joining instructions

The client intends one enduring exhibitor application URL and one enduring partner/sponsor application URL on its NTE website. Configure `Exhibitor_Application_URL__c` and `Partner_Application_URL__c` once; update those fields only when the destinations move. Refresh annual wording, dates, prices and event configuration at the same URLs. Invitation eligibility depends on the participant type and a valid HTTPS destination, not a matching year. Future-year sandbox interests can use the same links. Until final client destinations are supplied, the current GitHub preview URLs remain the sandbox destinations.

The destination form determines the event assigned to an application using the London-date calculation or `eventCodeOverride` described above. The link does not carry the inviting Lead's event. A future-year dummy invitation can be sent today, but a submission still uses the current form edition; a controlled different-edition submission requires explicitly configuring that test edition. Never treat the ability to send an invitation as proof that a future edition's content or pricing is ready.

Proposal 22 replaces automated final-pack distribution with staff-sent customised joining instructions. Staff record **Final joining instructions sent** from Completed. The marker does not gate entry to Completed, and existing sent history must survive later preparation or top-up work. Do not restore an automated sender or configure `Application_Event_Code__c`, `Exhibitor_Final_Pack_URL__c` or `Partner_Final_Pack_URL__c` as annual launch steps. Those old settings are retirement candidates subject to the recorded dependency review; retain historical evidence and uncertain dependencies. Application invitations and preparation-form destinations remain configured independently.

Every application must create a new Opportunity, reusing Account/Contact where appropriate and appending the saved event code to its name. Conversion sends nothing and creates no payment request. Staff release booking, free-space and separate top-up communications from Requirements. The first verified Booking payment received action queues one confirmation for the exact booking and its Primary Contact; a top-up receipt does not repeat it. A free booking requires its explicit confirmation action without a fictitious payment. Existing successful submissions, sends and payments must not be replayed as annual setup or backfill.

## Keep the client preview published

The owner has authorised routine publication of relevant approved changes to the existing GitHub Pages preview at `https://stevostar1234.github.io/nte27-web-to-lead-demo/`. Whenever forms or email examples change, update the canonical forms repository, publish them and verify the hosted result in the same task. Do not leave only local copies or ask again for this routine publication.

Start from the latest remote `main` in an isolated checkout. Review the intended file changes, preserve unrelated content and never push the Salesforce package branch to the forms repository. Verify the GitHub Pages build and changed page content, then record the commit and deployment result in the implementation notes. This permission does not include production Salesforce deployment or the future NTE production website.

## Current pricing and finance

Only fixed-price catalogue choices and eligible complimentary spaces are supported. Unknown pricing requires review and must not become a free booking. Keep the browser and Apex catalogues on the same version. The retired manual-pricing fields must not be regenerated or restored from old audit fixtures.

Finance has three refiners: **Requirements, Payment required, Payment confirmed**. Persistent requirement checkboxes and contextual details appear in Requirements; they do not gate sending or completion, and sending never ticks them. Requirements contains the applicable manual base/free/top-up actions; Payment required contains the applicable receipt actions. Requirements takes precedence when another charge still awaits release. A paid booking's later positive staff purchase returns through Requirements → Payment required → Payment confirmed, preserving the base payment and all checklist history. Keep base/top-up amounts, request identities and receipt facts separate.

The approved **Invoice Requested** field is the applicant's independent Yes/No choice after Payment Method. Never infer it from Stripe/bank transfer or repurpose the existing billable-price flags. Quotation, PO/reference, supplier agreement and other billing requirements remain separate. Hide and disable the whole exhibitor finance section at a calculated £0; chargeable space, power or staff restores it. Partner finance remains visible. Carry this refinement through forms, Lead/Opportunity mapping, permissions, record pages, reports and email presentation, and qualify its final release before using it as the next-edition baseline.

Completed requires valid pricing, original paid/free confirmation, all actual charges paid, and applicable staff, heavy-vehicle and logo preparation. Logo updates remain in the delivery breakdown. Requirements uses its card links to Open full record and has no lower record pane; the other views retain their pane. Avoid restoring the Booking emails detail section, Email activity dialog, old quote/invoice finance refiners or duplicated row actions. Repeat reminders and operational dispatch records remain available outside those removed features.

## Maintain the restored email family

Both application-received applicant emails were retired on 10 September; retain the on-screen receipt and internal notification. Conversion now sends no message. Paid participants receive their provisional reservation and preparation links only after staff release the booking action, followed by one confirmed-space email when base payment is recorded. A fully complimentary booking receives its explicit free-space confirmation from Requirements. A staff top-up uses its own manual Stripe request and preserves original booking-payment and confirmation history. Do not regenerate retired receipt templates or reattach a conversion-time send action from an older release.

Preserve the client wording restored from commit `7e0d21c37b1eeeb2feb36c2bf695d9e1e46ae649`, including final-details timing, relevant Livery Bay information, staff/logo guidance and partner agreement/billing details. Update source templates, their generator mappings, Salesforce templates and published examples together. The common navy/white layout uses gold for exhibitors, blue for partner/sponsor and teal for complimentary messages. Preparation buttons follow the staff guidance and stack on narrow screens. Mission Motorsport volunteering uses its own official logo and charcoal/taupe palette.

The custom sender uses the same visual family. Its Salesforce preview substitutes the packaged logo and fits the preview column; the outgoing email retains a publicly accessible image URL. Verify both views when changing the shared design.

Failed manually requested booking emails can be retried from the Opportunity's full record using **Retry booking email**. Failed supplementary acknowledgements use **Retry update email** on the retained submission Lead. Failed custom/payment dispatches use the **NTE Email Failures** list (`/lightning/o/NTE_Email_Dispatch__c/list?filterName=NTE_Email_Failures`) and **Retry email** on the dispatch record. These actions validate the current failure/recipient state; permitted unpaid retries reuse the saved charge/link and preserve prior delivery history. An accepted payment confirmation must never be sent again, and paid-booking protections remain. Do not recreate panel email history or automated final-pack delivery to expose recovery actions.

Native `Blob.toPdf()` generated a valid synthetic PDF in MMUAT on 7 September, including an explicit API 67 check with zero DML and zero emails. Document generation is still a future feature. Before migrating it, check the production API/release configuration and actual document layout, images and fonts; a sandbox capability check is not a production qualification.
