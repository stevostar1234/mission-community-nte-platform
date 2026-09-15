# Focused Stripe failure demonstration — 11 September 2026

Five payment scenarios are complete in **client test stripe sandbox** (`acct_1UD8GwBcW1MkMYQ1`), using four bookings and only two new applications. Five checkout attempts produced two failed payments, one open dispute, and one authenticated payment that was fully refunded. No live money was involved.

The checkout journeys were exercised in the browser. Stripe's native payment, charge, dispute, refund and Payment Link records were independently read through the existing secure Salesforce Named Credential. The Stripe Dashboard remains signed out, so its visual presentation and Kate's notification configuration have **not** been verified or changed. A dashboard login was requested; credentials were not requested in chat.

## Open these examples in Stripe

Select **client test stripe sandbox** before opening the payment links below. These are Dashboard links to the resulting records, not links inviting another payment. Amounts include the existing illustrative 20% tax setting, which was unchanged.

| Booking | Amount | Observed result | What it demonstrates |
| --- | ---: | --- | --- |
| [Eastmere Technical Careers Ltd](https://dashboard.stripe.com/acct_1UD8GwBcW1MkMYQ1/test/payments/pi_3UEVY8BcW1MkMYQ10TgXJHCJ) | £718.80 | Issuer decline, `insufficient_funds`; £0 captured | Checkout displays an insufficient-funds error. The link remains usable for a legitimate retry. |
| [Caverton Precision Engineering Ltd](https://dashboard.stripe.com/acct_1UD8GwBcW1MkMYQ1/test/payments/pi_3UEVYvBcW1MkMYQ11hzwWm67) | £958.80 | Radar blocked; highest risk, score 86; £0 captured | Existing rule `block_if_high_fraud_dispute_score` stopped the attempt before the card network. No new rule was installed. |
| [Braeford Fleet Solutions Ltd](https://dashboard.stripe.com/acct_1UD8GwBcW1MkMYQ1/test/payments/pi_3UEVVwBcW1MkMYQ11IItk14x) | £2,400.00 | Successful charge followed by an open `product_not_received` dispute | Dispute `du_1UEVVxBcW1MkMYQ1nlzSmXD4` is `needs_response`, with no evidence submitted. It is intentionally left open for the demo. |
| [Merehaven Technology Group Ltd](https://dashboard.stripe.com/acct_1UD8GwBcW1MkMYQ1/test/payments/pi_3UEVaCBcW1MkMYQ11baRgcB0) | £2,400.00 | Failed 3DS authentication → successful authenticated retry → full refund | First attempt captured nothing. The retry completed a 3DS 2.1 challenge and captured once. Refund `re_3UEVaCBcW1MkMYQ118rJtchG` succeeded for all £2,400. |

Braeford's simulated evidence deadline is **20 September 2026, 00:59 BST** (19 September 23:59:59 UTC). No dispute acceptance, evidence submission or second refund was performed. The disputed charge is currently not refundable; refunding a separate, undisputed payment gave a clearer demonstration.

Stripe's published fake cards were used for the issuer decline, highest-risk block, product-not-received dispute and 3DS challenge. These are representative outcome tests, not a measurement of real-world fraud detection accuracy. [Stripe testing documentation](https://docs.stripe.com/testing).

## Findings that matter for the product

- **Recovery works:** the failed 3DS attempt was retried within the same PaymentIntent and produced exactly one successful charge.
- **Duplicate collection protection works:** each successful link has one completed checkout and is inactive. The refund did not reopen Merehaven's link. Opening its original URL shows “This payment link is no longer available. Please contact the NTE team.” Both declined links remain active with zero completed checkouts.
- **Manual Salesforce confirmation remains intact:** all four Opportunities still have payment received and finance payment confirmed set to false. These test bookings were never manually marked paid. Stripe refunds and disputes do not automatically alter a Salesforce booking or send a Salesforce space-confirmation email.
- **A historical success is insufficient for reconciliation:** Merehaven's PaymentIntent still says `succeeded` after its full refund; Braeford's original charge also succeeded before its dispute. Check the current refund/dispute state in Stripe before recording payment in Salesforce. Existing paid bookings likewise are not automatically reversed if a later dispute or refund occurs.
- **Current collection configuration is unchanged:** card payments, including eligible card-wallet presentation; one completed checkout per link; fixed GBP gross amount; no promotion codes; no Stripe Invoicing; Stripe automatic tax off because the agreed amount already includes the configured tax calculation. The client must still confirm the actual VAT treatment.

The new Caverton and Merehaven applications used the normal form serializer, submission route, conversion flow, link generation and provisional email path. Both used the owner's Anthrion test address and normal generated booking references. Eastmere and Braeford reused the two unpaid examples from the previous task. The other prepared demonstration Leads were not consumed. Native IDs and scoped evidence are in the [qualification record](NTE_STRIPE_FAILURE_DEMO_QUALIFICATION_2026-09-11.json); raw execution ledgers are in ignored `tmp/nte-stripe-failure-demo-20260911/`. Do not replay submissions, conversions, checkout attempts or the refund script.

## Proportionate client settings

These are recommendations, not account changes or accepted policy decisions.

| Area | Recommendation |
| --- | --- |
| Fraud screening | Keep Stripe's normal automatic protection and highest-risk blocking. Review the client's existing rules before adding anything. The sandbox already blocks the highest-risk example. |
| Authentication | Use Stripe's required/risk-based 3DS handling. Avoid forcing every payer through a challenge or rejecting cards solely because 3DS is unavailable. Add a targeted high-value rule only if the client wants the additional friction. |
| Card checks and reviews | Prefer the available risk-aware CVC/postcode checks. Retain an existing elevated-risk review queue if useful and included in their plan; a review flag is not necessarily a blocked or uncaptured payment. Avoid blanket foreign-card/prepaid bans and new paid fraud tooling without evidence of need. |
| Refunds and disputes | Keep full/partial refunds deliberate in the Dashboard. Enable the relevant dispute and fraud-warning alerts. Do not introduce automatic refunds, automatic dispute acceptance or a new paid dispute service by default. |
| Payment methods and receipts | Keep the current card route and separate bank-transfer option. Use recognised merchant/statement wording and the client's established receipt settings; any NTE-specific change must preserve their other business payments. |

Stripe documents the default screening, risk-aware card checks, review behavior and the conversion cost of indiscriminate 3DS. The exact plan and client rules still need inspection. [Radar rules](https://docs.stripe.com/radar/rules). Refunds can also be pending or fail in live operation; the successful simulated refund does not qualify settlement timing or every refund failure. [Refunds](https://docs.stripe.com/refunds).

The practical client questions for this follow-up are:

1. **Fraud preference:** keep standard protection and automatic 3DS, or request extra authentication above a specified amount? Standard protection is the recommendation.
2. **Payment choices:** are cards/card wallets and the existing bank-transfer route sufficient? Extra payment methods need their own qualification only if wanted.
3. **Customer communications:** should NTE payers receive Stripe payment and refund receipts alongside booking emails? Confirm the NTE statement wording and support contact while preserving the existing merchant identity.
4. **Refund behavior:** keep deliberate Dashboard refunds, or is there a specific automatic rule they actually require? Keep automation off initially.
5. **Notification routing:** should Kate receive NTE payment successes only, or also NTE refunds/disputes? Which email addresses should receive each selected event type?

Existing questions about tax, purchase orders and booking changes remain separate unresolved configuration decisions. The [client questionnaire](../NTE_STRIPE_CLIENT_CONFIGURATION_QUESTIONS.md) now asks for configuration and notification destinations rather than business staffing responsibilities.

## Kate's NTE-only notifications

There is a credible native route: **Stripe Workflows**, using a successful-payment trigger, NTE-specific conditions and **Email a team member**. Stripe documents these building blocks and independent execution of workflows. This should be a small Dashboard configuration without adding a Salesforce payment webhook. [Workflow components](https://docs.stripe.com/workflows/define-workflows).

Our actual PaymentIntents and Charges already contain `nte_booking`, `nte_charge_kind=Booking`, and `nte_operation=<Salesforce org>:<Opportunity>:Booking`. A proposed notification rule would require these NTE identifiers, send the booking reference, paid amount and payment link to Kate, and leave non-NTE events alone. Stripe's own demonstration describes filtering event-payload fields and using metadata conditions; exact field selection still needs testing in the account. [Stripe Workflows demonstration](https://stripe.com/nl/sessions/2025/introducing-stripe-workflows).

The ordinary successful-payment notification preference is an account/category setting, not a documented NTE product filter. Keep that broad preference off for Kate and leave the existing team's preferences intact. The workflow email action requires an internal email associated with the Stripe account; Kate's Salesforce access does not add her to Stripe. A filtered email does not confer NTE-only Dashboard data access: choose and verify a suitable Stripe role separately. [Account email notifications](https://support.stripe.com/questions/set-up-account-email-notifications?locale=en-GB).

Before activation, inspect the client's existing workflows, confirm the metadata filter and eligible recipient, preview the message, then test one NTE event and one unrelated event. Verify that only the NTE event emails Kate and existing processing is unchanged. Stripe supports sandbox testing, run history and disabling a workflow. No Kate invite or workflow has been created in this task. [Workflow setup and verification](https://docs.stripe.com/workflows/set-up).

If they also want refund or dispute emails, retrieve the associated Charge/PaymentIntent to check the NTE identifiers: our actual Refund and Dispute objects have empty metadata. Filtering those objects directly for `nte_booking` would miss them. Start with successful payments and add these extra event types only if requested.

UK public pricing currently includes **10,000 workflow steps per month**, then **£0.013 per extra step**. A simple notification is modest usage, but the allowance is shared with their other workflows and account pricing must be confirmed. [Stripe UK pricing](https://stripe.com/gb/pricing).

## Completion boundary

Payment simulations and native reconciliation are complete. Dashboard login, visual review and Kate's actual notification setup remain pending. No production deployment, live payment, global fraud-rule edit, payment-confirmation automation or public website change was made. No application source changed, so the already-passed Salesforce package tests were not repeated for this data-only demonstration. Client-account validation, wallet/device coverage, delayed methods, payouts, partial/failed refunds and dispute win/loss simulations are not claimed as tested here.
