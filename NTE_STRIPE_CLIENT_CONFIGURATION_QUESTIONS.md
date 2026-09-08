# Stripe configuration for NTE

Please confirm the details below for the exhibitor and partner/sponsor payment process.

The agreed process uses **Stripe Payment Links**, with no Stripe invoices. The application becomes a provisional booking when Mission Community converts it. The booking email includes the amount due, payment link and preparation links. Staff check the successful Stripe payment and then record payment in NTE Management to confirm the space.

| Question | Client response |
| --- | --- |
| **1. Merchant account.** Which legal entity and Stripe account will receive these payments? Who can invite us to its sandbox and configure the production account? | |
| **2. Prices and VAT.** The current NTE catalogue lists prices excluding VAT. What VAT treatment applies to exhibition space, sponsorship, power and staff places? Are any customers or packages treated differently? Please provide worked examples of the final amount to collect. | |
| **3. Currency.** Should the booking price be GBP? Is Stripe offering customers a local-currency equivalent acceptable, or must checkout display and collect GBP only? | |
| **4. Payment methods.** Are cards and supported card wallets sufficient? Are any additional methods required? Should the existing separate bank-transfer option remain? | |
| **5. Amount and timing.** Is the whole amount payable in one payment? Are deposits, instalments, discounts or negotiated prices needed? | |
| **6. Financial documents.** Who supplies any quotation, proforma or VAT invoice outside Stripe? What company details, VAT number, purchase-order information and numbering are required? Can sending the combined payment email satisfy the “Quote provided” and existing invoice/link-provided milestones? | |
| **7. Purchase orders.** If an applicant requires a quotation or purchase order, can we send their payment link immediately on conversion, or must a staff member release it later? | |
| **8. Payment deadline.** How long is the provisional space held? Who follows up on unpaid bookings, and when should a link be closed? | |
| **9. Confirmation.** Which staff members verify successful payments and mark them received? Who covers absences? Should they record the Stripe payment reference and verification notes? | |
| **10. Notifications.** Should Stripe email a payment receipt to the payer? Which staff need payment-success, failure, refund or dispute notifications? Should these come from Stripe, Salesforce or both? | |
| **11. Recipients.** Booking emails currently go to the booking’s Primary Contact only. Is a separate copy to a finance contact required? A payer’s Stripe receipt can go to a different address from the booking email. | |
| **12. Staff top-up.** Should the one permitted additional staff purchase receive its own payment link immediately, including when the original booking is still unpaid? Should it have the same payment deadline and tax treatment? | |
| **13. Changes and cancellations.** Who approves revised amounts, cancellation and refunds? What should happen to an existing link after a price change or cancellation, and to money received after cancellation? | |
| **14. Already-paid bookings.** If the provisional email failed but payment has since been confirmed, should its retry be suppressed or replaced with a message that contains no payment request? | |
| **15. Conversion.** Should every application create a new booking while allowing reuse of the organisation and contact? What should happen if staff try to convert into an existing booking? | |
| **16. Checkout identity.** Please provide the merchant display name, logo, support email/phone, website, statement descriptor, terms and privacy URLs. Who will approve how these appear? | |
| **17. Finance reconciliation.** Who checks collected amounts, Stripe fees, payouts, refunds and disputes? What exports or references do they need? | |
| **18. Acceptance and launch.** Who signs off the sandbox journeys and account configuration? Who approves production activation and owns support after launch? | |

Please invite the developer through Stripe rather than sending passwords or secret keys in this document. Production bank details and identity verification should be completed by the account owner inside Stripe.

