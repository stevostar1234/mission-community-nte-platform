# Stripe sandbox implementation — 8 September 2026

Internal implementation and qualification record. The manual Payment Links integration is installed and enabled for the restricted MMUAT test scope below. Both exhibitor and partner journeys have reached verified test payment and manual space confirmation. Client-specific qualification and production activation remain separate work. This does not reopen the completed September stress-audit journeys.

## Scope and ownership

The owner authorised a claimed, owner-controlled Stripe sandbox, setup of the manual Payment Links workflow, and provisional test settings while the client supplies its configuration. The owner chose `steven.skyba@anthrion.com`, claimed the sandbox, explicitly approved Stripe CLI Administrator access to that sandbox, and entered its secret key directly in Salesforce's encrypted External Credential principal. No secret belongs in source, this report, GitHub or an email.

- Stripe account: `acct_1UD8GwBcW1MkMYQ1`, **client test stripe sandbox**. Account/balance checks confirm GB, GBP and test mode.
- Salesforce: MMUAT `00DAd00000A95VlMAJ`; Named/External Credential `NTE_Stripe_Test`; principal `NTEApplication`, authentication parameter `ApiKey`.
- The sandbox rollout checks the exact Salesforce org, Stripe account, `NTE-STRIPE-` booking-reference prefix and Primary Contact email `steven.skyba@anthrion.com`.
- Provisional fixture settings: GBP, full fixed payment, card, quantity one, one completed Checkout session per link, no promotion codes, no automatic tax, and **Stripe invoice creation disabled**. The 20% test tax rate is illustrative, not the client's VAT decision.
- Production is not authorised or enabled. This release explicitly rejects live Stripe mode. Ordinary existing bookings are outside this test rollout.

## Opportunity and payment request identity

The Opportunity remains the booking and the source of its saved price and application details. `NTE_Payment_Request__c` is a related internal payment history record, not another booking. It stores the requested net/tax/gross amount, exact Opportunity ID, Stripe identities, stable retry key, verification outcome and accepted-email timestamp. A change to an Opportunity cannot silently rewrite the amount of an already-created request.

Conversion supplies `Lead.ConvertedOpportunityId` explicitly. The coordinator never chooses an Opportunity by Account, Contact, latest date or similar name. A new Opportunity under an existing organisation/contact receives its own request and idempotency key. The automated returning-participant test exercises native conversion, asserts a different Opportunity/request/key, and preserves the old booking's payment history and paid status.

The owner's questions about reusing an old Opportunity do **not** approve changing P03. Native conversion into an existing Opportunity can still overwrite old NTE fields before Stripe processing. Paid state, a changed existing request, or multiple converted applications will hold Stripe work, but these checks cannot roll back the earlier conversion and are not a universal legacy-booking guard. Recommended decision: require a new Opportunity for each NTE application while permitting Account/Contact reuse. This policy remains unimplemented pending the owner's selection and separate regression qualification.

## Processing and failure behaviour

1. The normal conversion commits its Opportunity and queues the existing provisional email.
2. The coordinator saves a durable charge request from that exact Opportunity and commits it before a separate job calls Stripe.
3. The Stripe client verifies account/test mode, creates or recovers a fixed Price and Payment Link using stable idempotency keys, and reads back the link and its line item to verify amount, currency and restrictions.
4. After callouts it re-reads the booking and Primary Contact under locks. Changed details hold the request for review. The verified link and financial breakdown enter the existing provisional email, with the existing preparation links.
5. Salesforce accepting the email records the invoice/link milestone and, where requested, the quote milestone under the already-agreed combined itemised-email workflow. It does not establish receipt of a purchase order. An email failure does not record successful provision or payment.
6. A Stripe payment alone leaves Salesforce unpaid/provisional. Staff verify the exact successful charge in Stripe, then use the existing Booking payment received action. That existing action records payment and queues one space confirmation.

Failed creation retries retain the saved request and keys. Ambiguous creation older than 23 hours is held for reconciliation instead of issuing another create call after Stripe's idempotency retention window. Failed-email retries reuse the request. A stale link is re-verified. This is not a claim that Stripe and Salesforce form a distributed transaction; operators still reconcile uncertain provider outcomes.

## Deployment and automated evidence

- Foundation deployment `0AfAd00000Sq95WKAR`: five components and four tests. The subsequent foundation full validation `0AfAd00000SqFKbKAN` passed 429 components and 285 tests.
- Client readback hardening deployment `0AfAd00000SqG0XKAV`: two components and four tests passed. It adds fixed-quantity and reused-Price verification.
- Actual Salesforce Named Credential preflight successfully verified the claimed test account and the standalone £960 contract link. This proves native authenticated callouts, not a booking payment journey.
- Coordinator deployment `0AfAd00000SqI0jKAF`: 40 components installed with rollout disabled. Earlier rejected deployment/test attempts rolled back and are retained locally. The final focused run `707Ad00001QeiFH` passed all **13 coordinator tests**, including native next-year conversion, exact financial output, manual-payment separation, failed-email retry, API failure, changed recipient/amount, aged uncertain creation and bulk preparation.
- The four separate Stripe email examples use the maintained templates and show the itemised amount and manual-confirmation wording. Their preview payment controls cannot collect a payment.
- Full coordinator check-only `0AfAd00000SqI8oKAF` passed 464 reported components and 297 local Apex tests, with zero errors. The explicit test-scope enablement deployed as `0AfAd00000SqIFFKA3`.
- Actual inbox review found that the partner provisional email still promised a later quotation although this agreed combined email supplies it. The Stripe-specific agreement sentence now only promises the agreement for signing; the existing bank-transfer wording is preserved. Stripe confirmation totals now read **Total paid**. Actual correction deployment `0AfAd00000SqJ9hKAF` passed three components and **68 tests**. The earlier candidate `0AfAd00000SqIiHKAV` failed the strict missing-marker checks and rolled back; the correction scopes the partner-only marker without weakening those checks.
- Native render-only verification used the exact two new bookings and the final stored templates. HTML/plain-text assertions passed for the corrected agreement sentence, paid-total label, preparation links and absence of a payment control in confirmation. It invoked no sends and made no record changes. Previously received messages are retained, not resent for wording changes.
- Final complete-manifest check-only `0AfAd00000Sq7tKKAR` succeeded at 17:30:35 UTC: **464/464 components, 297/297 local tests, zero errors**, with all **530** source/manifest hashes and member identities reconciled in [exact qualification](NTE_STRIPE_QUALIFICATION_2026-09-08.json). The final hash inventory excludes `.DS_Store` and `.gitkeep`, which the earlier 532-file working snapshot included.

## Retained sandbox journeys

| Evidence | Exhibitor | Partner / sponsor |
| --- | --- | --- |
| Reference | `NTE-STRIPE-20260908-EX01` | `NTE-STRIPE-20260908-PS01` |
| Converted Lead | `00QAd00000USvIDMA1` | `00QAd00000USvIEMA1` |
| Exact Opportunity | `006Ad00000UfHV3IAN` | `006Ad00000UfHV4IAN` |
| Payment request | `a09Ad00000Ow4mzIAB` | `a09Ad00000Ow4n0IAB` |
| Stripe link | `plink_1UDSLJBcW1MkMYQ1enhCzd5P` | `plink_1UDSLMBcW1MkMYQ1hw30KafH` |
| Net / illustrative VAT / gross | £800 / £160 / **£960** | £2,000 / £400 / **£2,400** |
| Provisional email | Sent and received 16:57:59 UTC | Sent and received 16:58:01 UTC |
| Invoice/link provided | Yes | Yes |
| Requested quote provided | Not requested | Yes, by the combined email |
| Stripe payment | Succeeded and captured, test mode | Succeeded and captured, test mode |
| Salesforce manual confirmation | Recorded 17:08:13 UTC | Recorded 17:37:53 UTC |
| Space-confirmation email | One Sent and received, 17:08:14 UTC | One Sent and received, 17:37:54 UTC |

The owner completed the **£960 exhibitor** payment in Stripe. Provider verification matched `pi_3UDSQ8BcW1MkMYQ11RhVXAAd` and captured charge `ch_3UDSQ8BcW1MkMYQ11UI2gLoY` to GBP 960.00, the exact booking/operation metadata and test mode; there was no Stripe invoice, refund or dispute. Stripe subsequently reported this exact link inactive, with completed-session count **1** against limit **1**. The Salesforce readback after payment still showed unpaid and no payment timestamp, proving the manual separation. Only after checking that evidence did the existing `PAYMENT_RECEIVED` action record the payment. Dispatch `a08Ad00000bxQu2IAE` sent one space confirmation to `steven.skyba@anthrion.com`.

Actual inbox messages `1a081f47ffa73418` (exhibitor provisional), `1a081f48b28029ba` (partner provisional) and `1a081fde56fa6a74` (exhibitor confirmed) were read in HTML/plain text. Correct booking-specific links, amounts and preparation routes were verified. The original confirmation's earlier “Total payable” label and partner's earlier quotation sentence are historical observations corrected in the final source/render above; do not send replacements.

The owner subsequently completed the **£2,400 partner** payment after Bitwarden interrupted automated card entry. Provider verification matched `pi_3UDSvhBcW1MkMYQ11gXg38kj` and captured charge `ch_3UDSvhBcW1MkMYQ11GWSWl51` to GBP 2,400.00, exact booking/operation metadata and test mode, with no invoice, refund or dispute. Salesforce was still unpaid before the manual action. That action recorded payment at 17:37:53 UTC and dispatch `a08Ad00000bxS4cIAE` sent the single partner confirmation at 17:37:54 UTC. Inbox message `1a082190fa9ddf7a` has correct HTML/plain-text net/VAT/paid totals, the partner preparation links and no payment button. This actual message uses the corrected final wording. Both links are now inactive, each with one completed session against a limit of one. Several other open/unpaid sessions from earlier page openings are not extra payments. Do not create replacement links, repeat either payment or resend either confirmation. The standalone contract link `plink_1UDRZmBcW1MkMYQ1tgJwCSUO` is a separate unbound fixture and must not be confused with either booking.

Existing native Opportunity stages were preserved. Payment confirmation does not imply preparation Completed, final-pack distribution or Closed Won. This checkpoint verifies the new payment route and focused failure/regression cases; it is not all 60 scenarios in the qualification catalogue, browser coverage on every device, or notification/receipt acceptance for the client's account.

Local raw evidence and private tooling: ignored `tmp/nte-stripe-20260908`. Never re-run a creation/conversion/payment from a stale journal; inspect its exact record/provider IDs first.

## Remaining client and release work

The [client questionnaire](../NTE_STRIPE_CLIENT_CONFIGURATION_QUESTIONS.md) covers VAT worked examples, merchant identity, currency presentation, documents/POs, receipts and internal notifications, deadlines, cancellation/refund ownership, conversion policy, top-ups and sign-off.

Automatic Stripe generation for the single staff top-up is not wired in this checkpoint. Existing separate top-up finance and manual actions remain. Its collection order and client exceptions need qualification before that branch is enabled. The 60 scenarios in the manual setup plan are a planned qualification catalogue, not 60 completed tests.

Moving to the client's **sandbox** requires its own secure secret, expected account/configuration, permitted test recipients and repeated end-to-end tests. Test Price/Link/payment IDs are account-specific and are not transferred. Moving to **production** additionally requires the deliberately reviewed live credential/mode support, client financial settings, Salesforce release validation, permission assignment, secure live secret entry and authorised activation. Swapping a secret alone is insufficient, and this test-only release cannot collect live payments.

## Primary references

- [Stripe sandboxes](https://docs.stripe.com/sandboxes) and [test payments](https://docs.stripe.com/testing): simulated payment environments and test credentials/cards.
- [Payment Link creation](https://docs.stripe.com/api/payment-link/create), [Price creation](https://docs.stripe.com/api/prices/create), and [idempotent requests](https://docs.stripe.com/api/idempotent_requests).
- [Salesforce custom headers and API keys](https://help.salesforce.com/s/articleView?id=sf.nc_custom_headers_and_api_keys.htm&language=en_US&type=5) and [secure External Credential population](https://developer.salesforce.com/docs/platform/named-credentials/guide/nc-populate-external-credentials.html).


## Client preview publication

Canonical repository `stevostar1234/nte27-web-to-lead-demo`: initial Stripe examples commit `1e3fcf459e52cf00ccad3ae1a43623d44ddaf3bc`, followed by final wording commit **`b81b8bced9c64a77aa7b1f31878ffca22dedaeb7`**. All **63/63** intended hosted files byte-match the maintained source, verified 17:27:39 UTC. Browser review confirmed the partner provisional layout/payment breakdown, shortened agreement sentence, disabled preview payment control, and exhibitor confirmation with its paid total and no payment button. The four new examples contain illustrative catalogue fixtures, not the actual £960/£2,400 test bookings. No payment can be collected from their preview controls.
