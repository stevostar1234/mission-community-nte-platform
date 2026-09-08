# Future NTE maintenance

The form integration is edition-neutral. Do not rename form types, source values, field API names or automations for each annual event.

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

Never reuse or hand-edit a booking reference. Partner / sponsor and exhibitor applications generate the authoritative reference; staff and vehicle forms match only that exact value.

Web-to-Lead field IDs, the organisation ID and the return URL are Salesforce-org-specific. Generate and verify production mappings; never copy the MMUAT values into production unchanged.

## Enduring application URLs and final-pack settings

The client intends one enduring exhibitor application URL and one enduring partner/sponsor application URL on its NTE website. Configure `Exhibitor_Application_URL__c` and `Partner_Application_URL__c` once; update those fields only when the destinations move. Refresh annual wording, dates, prices and event configuration at the same URLs. Invitation eligibility depends on the participant type and a valid HTTPS destination, not a matching year. Future-year sandbox interests can use the same links. Until final client destinations are supplied, the current GitHub preview URLs remain the sandbox destinations.

The destination form determines the event assigned to an application using the London-date calculation or `eventCodeOverride` described above. The link does not carry the inviting Lead's event. A future-year dummy invitation can be sent today, but a submission still uses the current form edition; a controlled different-edition submission requires explicitly configuring that test edition. Never treat the ability to send an invitation as proof that a future edition's content or pricing is ready.

For each new final pack, update `NTE_Routing_Config.Default.Application_Event_Code__c` with the matching `NTEYYYY` value and the approved final-pack destinations. This field is now labelled **Final Pack Event Code**; its API name is retained for compatibility. Final-pack sends stop if the booking event differs from this setting. Application invitations do not use it.

Configure `Exhibitor_Final_Pack_URL__c` and `Partner_Final_Pack_URL__c` only when the approved packs are ready. Keep them blank until then. Pack dispatch history belongs to the booking and must not be reset when its preparation or top-up finance reopens. Update-form destinations remain configured independently.

The current phase retains manual quote/invoice/payment handling. Stripe generation remains on hold. The owner approved the booking-payment confirmation email on 7 September: the first saved Booking payment received transition queues one confirmation for the exact booking and its primary Contact. Top-up payments do not repeat it. Preserve provisional email → payment → confirmation; no historical backfill or route that skips the provisional message is required.

## Keep the client preview published

The owner has authorised routine publication of relevant approved changes to the existing GitHub Pages preview at `https://stevostar1234.github.io/nte27-web-to-lead-demo/`. Whenever forms or email examples change, update the canonical forms repository, publish them and verify the hosted result in the same task. Do not leave only local copies or ask again for this routine publication.

Start from the latest remote `main` in an isolated checkout. Review the intended file changes, preserve unrelated content and never push the Salesforce package branch to the forms repository. Verify the GitHub Pages build and changed page content, then record the commit and deployment result in the implementation notes. This permission does not include production Salesforce deployment or the future NTE production website.

## Current pricing and finance

Only fixed-price catalogue choices and eligible complimentary spaces are supported. Unknown pricing requires review and must not become a free booking. Keep the browser and Apex catalogues on the same version. The retired manual-pricing fields must not be regenerated or restored from old audit fixtures.

Finance has four combined refiners: Quotes required, Invoice required, Payment required, Payment confirmed. Keep booking/top-up fields and history separate and show booking actions first. Logo updates belong in the delivery breakdown. Avoid restoring the redundant Booking emails detail section, Email activity button/dialog or duplicated row actions in the detail pane. Repeat reminders and operational dispatch records remain available outside that removed panel feature.

## Maintain the restored email family

Keep application receipts separate from conversion messages. Both paid participant types receive an under-review receipt, then a provisional reservation after conversion, then a confirmed-space email when booking payment is recorded. A fully complimentary booking confirms at conversion. Staff top-ups preserve the original booking-payment history.

Preserve the client wording restored from commit `7e0d21c37b1eeeb2feb36c2bf695d9e1e46ae649`, including final-details timing, relevant Livery Bay information, staff/logo guidance and partner agreement/billing details. Update source templates, their generator mappings, Salesforce templates and published examples together. The common navy/white layout uses gold for exhibitors, blue for partner/sponsor and teal for complimentary messages. Preparation buttons follow the staff guidance and stack on narrow screens. Mission Motorsport volunteering uses its own official logo and charcoal/taupe palette.

The custom sender uses the same visual family. Its Salesforce preview substitutes the packaged logo and fits the preview column; the outgoing email retains a publicly accessible image URL. Verify both views when changing the shared design.

Failed conversion emails can be retried from the Opportunity's full record using **Retry booking email**. Failed supplementary acknowledgements use **Retry update email** on the retained submission Lead. Failed custom/payment dispatches use the **NTE Email Failures** list (`/lightning/o/NTE_Email_Dispatch__c/list?filterName=NTE_Email_Failures`) and **Retry email** on the dispatch record. These actions validate the current failure/recipient state; an accepted payment confirmation must never be sent again. Do not recreate panel email history to expose these recovery actions.

Native `Blob.toPdf()` generated a valid synthetic PDF in MMUAT on 7 September, including an explicit API 67 check with zero DML and zero emails. Document generation is still a future feature. Before migrating it, check the production API/release configuration and actual document layout, images and fonts; a sandbox capability check is not a production qualification.
