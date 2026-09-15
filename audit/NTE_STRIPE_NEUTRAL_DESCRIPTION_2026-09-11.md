# Year-neutral Stripe description — 11 September 2026

Proposal 19 is implemented in source and MMUAT. New payment requests use **NTE booking · [booking reference]**. The Stripe client uses this saved description for the Product name displayed at checkout and the PaymentIntent description. Functional event codes and booking references are unchanged.

Only `NTEStripeBookingService.cls` and its existing test assertion changed. The metadata generator preserves these class bodies; the full build leaves the intended change intact. Forms, emails, pricing, tax, recipients and payment-confirmation behavior remain unchanged. Existing requests keep their original saved descriptions because those values form part of their creation/retry payload. No existing Stripe resource was renamed or payment demonstration repeated.

## Release evidence

| Check | Result |
| --- | --- |
| Local build and presentation validation | `npm run validate` passed |
| Actual MMUAT deployment | `0AfAd00000Stkq7KAB` — 2 components, 15 affected tests, zero errors |
| Full package check-only validation | `0AfAd00000Str6nKAB` — 470 components, 307 local tests, zero errors |
| Package reconciliation | 534 source/manifest hashes and all 470 component identities match the validated package |
| Native source readback | Both deployed class bodies match current source |
| Existing payment requests | All fields of all 9 captured requests unchanged; none created |
| Stripe configuration | Captured non-secret configuration unchanged |
| Scope comparison | Only the two intended class files differ among 643 captured source/public files; 641 unchanged |
| Preview publication | Not required: public forms, assets and email previews are unchanged |

Final native verification completed at **16:00:40 UTC**. See [structured qualification](NTE_STRIPE_NEUTRAL_DESCRIPTION_QUALIFICATION_2026-09-11.json). Raw local snapshots and the exact two-file patches are under `tmp/nte-stripe-neutral-20260911/`. The initial CLI argument rejection occurred locally before any deployment; the actual release and full validation each ran once. Preserve the prior payment demonstrations and their ledgers.

## Client access and remaining qualification

The [updated handover](../NTE_STRIPE_CLIENT_HANDOVER_2026-09-11.md) contains a ready-to-send access request, current Stripe role guidance and the route from the client's sandbox to a separately authorised production activation. Request an invitation to the developer's own work email, with Developer access assigned directly in the intended sandbox. Live Developer access can follow during production setup; alternatively a client administrator can configure the agreed live credential/settings securely. Dedicated restricted API keys should be created and qualified after access is granted, then stored in the matching Salesforce External Credential.

The client still needs to confirm merchant identity/readiness, tax examples, payment methods, receipts and notification choices. Copying a live account's settings into a sandbox does not copy Radar rules or create ongoing synchronisation. Existing test links cannot become live links; the current integration rejects live mode until the explicit production code/configuration work is completed.

The most useful next client-account checks are interrupted checkout, timeout/email-failure recovery, credential failure/recovery, an already-issued link after booking changes/cancellation, and positive/negative NTE notification filtering. Current Salesforce code does not automatically close or reprice issued links, or synchronise refunds/disputes/payment success. This advice does not authorise those workflow changes. Further partial-refund, wallet/mobile or other cases should follow the selected payment methods and requirements, rather than a large indiscriminate fixture set.

No new Leads, operational emails, Stripe payments/refunds/disputes, account settings, notifications, live credentials or production deployments were created by this follow-up.
