# NTE email restoration and sandbox cleanup — 7 September 2026

Implemented in the versioned source and MMUAT. The matching client previews are published. Production Salesforce and Stripe integration were not changed. No live email or Web-to-Lead submission was sent during this release.

## Confirmed behaviour

| Trigger | Email |
| --- | --- |
| Exhibitor or partner/sponsor application arrives | Separate application acknowledgement: under review |
| Paid application is converted | Provisional space reserved, with booking information and preparation links |
| Fully complimentary application is converted | Space confirmed immediately; no payment required |
| Booking payment is recorded as received | One corresponding exhibitor or partner/sponsor space-confirmed email |
| Staff top-up payment is recorded | No repeat of the original booking confirmation |

The owner's final clarification is preserved: provisional message → payment → confirmation. No alternate path skips or supersedes the provisional message. Stripe generation remains on hold; the current manual payment process continues. There is no historical payment-email backfill.

The first saved booking-payment transition queues an after-commit notification for the exact Opportunity and its primary Contact. A stable per-booking dispatch key prevents another accepted confirmation on repeat clicks, later top-ups or retries. Missing contact/configuration, changed recipient or charge details, rendering/send failures and queue failures remain recoverable without clearing the saved payment milestone. Public mass-email requests cannot manufacture this internal payment-confirmation kind.

## Client wording and design

Restored substantive client wording from the last complete 2 September versions, identified by commit `7e0d21c37b1eeeb2feb36c2bf695d9e1e46ae649`. The former partner/sponsor confirmation content belongs in its conversion template, while the separate under-review receipt remains. Restoration preserves final-event-details timing, relevant Livery Bay information, fresh-logo guidance, staff details, package/equipment information, billing/PO/supplier information and the separate partnership agreement. It does not restore retired pricing-by-request choices or manual-price functionality.

All 21 maintained templates and 21 examples share the supplied partner/sponsor EOI aesthetic. The custom invitation, reminder and final-pack renderer uses the same family. Navy and white are shared; exhibitor accents are gold, partner/sponsor accents blue and complimentary accents teal. Preparation actions follow the staff guidance, sit horizontally where supported and stack on narrow screens. Plain-text alternatives remain available.

Mission Motorsport volunteer pages and emails use its official logo and a charcoal/taupe/white palette, without NTE branding. The logo was taken unchanged from the official Mission Motorsport website header. Form fields, consents and conditional service questions remain intact.

## Panel and recipient verification

- Removed the individual Email activity button and its complete panel dialog, state and handlers. Operational dispatch storage remains available outside that removed interface.
- Remind All and View cross-event report both render with background `rgb(240, 179, 35)` and text `rgb(7, 31, 53)`.
- The live reminder preview uses the existing packaged Salesforce logo because Lightning blocks the external image. Only the preview substitutes the image URL; the outgoing email retains its public URL. Its inner email table fits the preview column. Browser verification measured 583 px client width and 583 px scroll width, with the logo successfully loaded. Send remained visible in the footer.
- Conversion already used the exact `$Record.ConvertedOpportunityId` in the baseline. The worker also verifies the converted Lead/Opportunity relationship. A focused mixed-conversion test now modifies an older unrelated booking last and confirms that only the two newly converted bookings receive their own correct templates/primary recipients. No legacy-contact conversion or real-recipient test send was performed.

Failure recovery remains outside the panel: **Retry booking email** on the full Opportunity, **Retry update email** on a retained supplementary Lead, and **Retry email** on a failed dispatch in the NTE Email Failures list. These are validated retry actions, not general resend controls. The new record actions compiled in the full deployment; their service paths are covered by Apex tests. The actions themselves were not invoked against live records.

## Validation and publication

| Evidence | Result |
| --- | --- |
| Full MMUAT deployment `0AfAd00000SotVqKAJ` | 413/413 components, 180/180 Apex tests |
| Preview-only LWC correction `0AfAd00000Sov6DKAR` | 1/1 component |
| Final full-manifest check-only `0AfAd00000SooWBKAZ` | 413/413 components, 180/180 Apex tests |
| Final local `npm run validate` | Build and form tests passed; 21 email templates generated |
| Final source reconciliation | All 413 manifest components and 473 source/manifest files match the validated release |
| GitHub Pages commit `9f19c00cf23ba593183b26ac393b97fbedbea23a` | Exact commit built; all 48 intended served files match local bytes |

The 180-test suite includes ten focused payment-email cases and the mixed-conversion routing check. It covers failure/retry, missing template/contact, changed recipient/amount, duplicate prevention, top-up isolation and after-commit work. An older complimentary fixture included chargeable sockets/staff; its assertions now distinguish a genuinely zero-charge booking from complimentary space with chargeable extras. Two earlier deployments rolled back on compile/test failures before these corrections; their raw results remain in the evidence directory.

Browser checks covered the live panel/reminder composer, representative restored/provisional/complimentary/paid-confirmation emails and volunteer form/email. The provisional preparation actions were horizontal at 1280 px and stacked at 390 px without page overflow. The volunteer form also fitted a 390 px viewport, including its conditional service fields. This verifies browser rendering, not every Outlook/Gmail client or real inbox delivery.

Only the 48 intended website files were published from a fresh checkout of canonical `stevostar1234/nte27-web-to-lead-demo` main. The package branch, internal notes and cleanup backups were not published. Final shipped-copy scans and `git diff --check` passed.

## Recoverable dummy cleanup

The exact inventory was backed up and hashed before cleanup. Immediately beforehand, all candidate modification stamps were unchanged, the org was verified as MMUAT sandbox `00DAd00000A95VlMAJ`, and there were no pending email dispatches, active async jobs, active Apex triggers or delete-triggered Flows.

| Deleted object | Count | Bulk job |
| --- | ---: | --- |
| Solely attached NTE email histories | 16 | `750Ad00000TIzHIIA1` |
| Approved dummy Leads | 277 | `750Ad00000TIs68IAD` |
| Approved dummy Opportunities | 96 | `750Ad00000TItwdIAD` |

Every exact ID succeeded and was subsequently returned with `IsDeleted=true`. These were ordinary soft deletions; nothing was hard-deleted or purged from the Recycle Bin. The explicitly approved Gary Testman test Lead was included, while its London Superway legacy Account and Contacts were preserved.

No Account or Contact was deleted. Verification confirmed the 78 protected Accounts, 79 protected Contacts, four supplementary-only Leads outside panel row views, 13 shared duplicate groups and 41 preserved Contact memberships remain. Scoped dummy child data was backed up; normal parent-deletion effects are documented in the inventory. The four supplementary-only Leads may retain an event in the dropdown but do not produce panel rows.

After cleanup, cross-year queries returned **zero panel Leads, zero panel bookings and zero active dispatch records**, with no pending async work. The refreshed browser showed every pipeline and breakdown count at zero.

## Native PDF capability

`Blob.toPdf()` compiled and generated a valid 1,317-byte PDF from synthetic HTML in MMUAT, including a second probe explicitly using API 67. Both probes recorded zero DML statements and zero emails. No document-generation feature was implemented.

The method is native Apex. Salesforce documents the enhanced Visualforce rendering engine as a **Spring ’26 update enforced in Summer ’26**, rather than a new Winter ’26 class. See the [official developer release guide](https://developer.salesforce.com/blogs/2026/01/developers-guide-to-the-spring-26-release). This supports expecting the native capability in production on the corresponding release, but production was not inspected. Qualify the actual HTML, fonts, image access, permissions and release/API configuration there before a document feature is migrated; a sandbox pass is not an unconditional production guarantee.

## Evidence location and remaining dependencies

Raw deployment, validation, publication, PDF and private cleanup evidence: `tmp/nte-email-refresh-20260907/`. Template restoration provenance: `tmp/nte-emails-20260907/template-restoration-evidence.json`. Keep these private; they are not website artifacts. The cleanup inventory contains full readable before-images and detailed preservation/cascade boundaries, not a guarantee that generated history can be reconstructed from CSV alone.

Stripe credentials/account decisions, final-pack content, client-hosted production destinations and the requested logo-upload destination remain client dependencies. These changes do not qualify production Salesforce or replace later controlled end-to-end inbox/form testing. The sandbox panel is cleared for that next testing round.
