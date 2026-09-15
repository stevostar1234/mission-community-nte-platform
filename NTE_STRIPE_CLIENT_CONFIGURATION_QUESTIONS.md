# Stripe configuration for NTE

Please confirm the details below for the exhibitor and partner/sponsor payment process.

The agreed process uses **Stripe Payment Links**, with no Stripe invoices. After review, each application becomes a new booking; the organisation and contact may be reused. Conversion sends no email and confirms no space. Staff release the booking message from **Requirements**, then check and record the payment from **Payment required** to confirm the space. A free space is confirmed separately without a payment.

Once the applicable payments and staff, vehicle and logo preparation are complete, the team sends the joining instructions and records them as sent. Requirement checkboxes do not delay completion.

**Invoice Requested** is a separate Yes/No choice after Payment Method. Either payment method can be used with either invoice answer. Quotation, invoice and other requirement checkboxes are recorded independently; sending never ticks them. The exhibitor finance section is hidden when the total is £0 and returns when a paid space, socket or additional staff creates a charge. Partner finance remains visible. This refinement is agreed; final release confirmation is pending.

| Question | Client response |
| --- | --- |
| **1. Merchant account.** Which legal entity and Stripe account will receive these payments? Please arrange access to the intended live account and NTE sandbox together. Developer plus Sandbox Administrator covers integration work; Administrator is appropriate if we also need to manage team invitations and bank/payout settings during setup. | |
| **2. Prices and VAT — confirmed 13 September.** Add 20% VAT to all payable NTE prices after discounts, including staff top-ups. Show net package/item prices and aggregate VAT/gross totals. | Confirmed by the client through the project owner. |
| **3. Currency.** Should the booking price be GBP? Is Stripe offering customers a local-currency equivalent acceptable, or must checkout display and collect GBP only? | |
| **4. Payment methods.** Stripe and bank transfer remain available. Are cards and supported card wallets sufficient for Stripe, or are additional methods required? | |
| **5. Amount and timing.** Is the whole amount payable in one payment? Are deposits, instalments, discounts or negotiated prices needed? | |
| **6. Financial documents.** Which quotation, proforma or VAT invoice details are required outside Stripe: company details, VAT number, purchase-order information and numbering? | Invoice Requested is independent of payment method. Sending a payment message does not mark quotation or invoice work complete. Document details remain to be confirmed. |
| **7. Payment-request release — confirmed 13 September.** Staff release the applicable Stripe or bank-transfer booking message from Requirements. Conversion sends nothing, and unchecked requirements do not prevent release. | Confirmed through the project owner. |
| **8. Payment deadline.** How long is the provisional space held, and when should an unpaid link be closed? Are automatic reminders required? | |
| **9. Fraud and authentication.** We recommend standard Stripe fraud protection, highest-risk blocking and automatic 3D Secure. Is extra authentication above a particular payment amount required? Are any existing fraud rules mandatory for NTE? | |
| **10. Notifications.** Should payers receive Stripe payment and refund receipts? Should Kate receive NTE payment successes only, or also NTE refunds/disputes? Please specify the email address for each selected notification category. Existing notifications for other business payments should continue unchanged. | |
| **11. Recipients.** Booking emails currently go to the booking’s Primary Contact only. Is a separate copy to a finance contact required? A payer’s Stripe receipt can go to a different address from the booking email. | |
| **12. Staff top-up.** The one permitted additional staff purchase has its own manually released Stripe link and separate payment record, with 20% VAT. Should it have the same payment deadline as the booking? | Separate manual request confirmed. A later top-up returns the booking to Requirements while preserving the original payment. Deadline remains to be confirmed. |
| **13. Changes and cancellations.** For agreed changes, is a manually requested bank transfer and confirmation acceptable? We recommend closing the superseded unpaid link. For cancellations, should staff refund the agreed amount in Stripe and mark the booking Closed Lost? Are there cancellation charges or partial-refund rules to apply? | |
| **14. Already-paid bookings.** A paid booking must not receive another payment request. If its earlier provisional email failed, does the team need a separate message containing preparation information only? | |
| **15. Conversion — confirmed 13 September.** Every application must create a new booking; the organisation and contact may be reused. Converting without a booking or into an existing booking is refused. | Confirmed through the project owner. |
| **16. Checkout identity.** Please provide the merchant display name, logo, support email/phone, website, statement descriptor, terms and privacy URLs. Should NTE have distinct payment wording within the existing merchant account? | |
| **17. Finance reconciliation.** Are the Stripe Dashboard and standard exports sufficient? Are additional booking references, payment-reference fields or verification notes required in the NTE records? | |

Please invite the developer through Stripe rather than sending passwords or secret keys in this document. Production bank details and identity verification should be completed by the account owner inside Stripe.
