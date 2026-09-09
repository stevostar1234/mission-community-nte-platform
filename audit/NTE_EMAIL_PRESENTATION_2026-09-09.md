# NTE email presentation — 9 September 2026

The owner's annotated email corrections are implemented in the maintained source, deployed to MMUAT and published to the canonical client preview. This is a presentation release; manual payment confirmation and the two completed Stripe test journeys are preserved.

## Inbox investigation

The received £960 exhibitor email was the correct booking-confirmation route for `NTE-STRIPE-20260908-EX01`, but retained the earlier incorrect **Total payable** label in both HTML and plain text. Gmail message `1a081fde56fa6a74` was sent on 8 September at **17:08:14 UTC / 18:08:14 BST**. The previous wording correction, deployment `0AfAd00000SqJ9hKAF`, completed at **17:22:24 UTC / 18:22:24 BST**. Changing a template cannot update a previously delivered message.

The later £2,400 partner confirmation, Gmail message `1a082190fa9ddf7a` for `NTE-STRIPE-20260908-PS01`, was sent at **17:37:54 UTC / 18:37:54 BST** and correctly says **Total paid** in both formats. These messages do not show a wrong-template routing issue. The owner-authorised inbox search found the earlier exhibitor message as the confirmation containing the payable wording. No old message was resent.

## Approved changes

- Paid confirmations: introductory text → staff details and event preparation → booking charges → booking details. Partner agreement prose remains with the introductory material, followed by the same preparation/charges/details sequence.
- Provisional booking emails: introductory text → allocation and charges, including the Stripe button when applicable → staff details and event preparation → booking details. Existing partner organisation, package and billing details retain their relative order.
- Removed the repeated **Booking payment received** callout from both paid confirmation templates.
- Confirmed Stripe totals retain the saved net, tax and gross figures and say **Total paid**. Bank-transfer confirmations say **Total paid · excluding VAT**, because their saved booking amount is net. Complimentary confirmations retain their no-payment wording; no paid amount is invented.
- Removed all three CRM sections and the remaining standalone Lead ID row. All 21 maintained source emails and 25 examples were scanned for CRM sections, raw record IDs, the old payment-button label and reviewer/testing commentary, with no matches.
- Enlarged and centred the payment button. **Pay Now** occupies the main area; a short internal divider separates the small Stripe icon and **Stripe** label. The live email has one anchor around the entire control and one saved payment URL in its plain-text alternative. Public examples have no payment URL.
- Provisional Stripe wording now ends **Your space will be confirmed by the NTE Team.**
- Exhibitor preparation wording now says **You can also request additional staff places as separately invoiced top-ups if required.** This does not change top-up eligibility, limits, invoicing or payment automation.
- Amount cells keep each currency value on one line at phone widths.

The Stripe icon is an unchanged 96×96 PNG from [Stripe's official company-information page](https://stripe.com/newsroom/information), displayed at 22×22. Its [official source asset](https://images.stripeassets.com/fzn2n1nzq965/4vVgZi0ZMoEzOhkcv7EVwK/8cce6fdcf2733b2ec8e99548908847ed/favicon.png?w=96&h=96) is saved as `assets/stripe-icon.png` for the existing preview/email asset host.

## Validation and release

- `npm run validate` passed after the final presentation changes.
- Actual sandbox deployment **`0AfAd00000Sr51SKAR`** completed **2026-09-09T13:21:56.000Z**, with **12/12 components and 82/82 focused Apex tests**, zero errors.
- Full production-manifest **check-only** validation **`0AfAd00000Sr6vBKAR`** completed **2026-09-09T13:30:05.000Z**, with **464/464 components and 298/298 RunLocalTests**, zero errors. All 464 member identities and **530 source/manifest file hashes** reconcile; no source changed during qualification. Aggregate SHA256: `548cd56567b0df63a2f841b2b6b0970ff449fbbde8c2bd3cb5fcf7bf53ae69a5`.
- Eight real Salesforce stored-template renders passed: provisional and confirmed Stripe emails for both retained test bookings, plus the four revised internal Lead templates. Checks cover readable HTML/plain text, exact saved £960/£2,400 paid totals, resolved merge markers, one currency symbol, stage-specific link presence, correct order, and absent CRM IDs. The render operation asserted **zero email invocations and zero DML statements**.
- Desktop and phone browser checks covered all four Stripe variants, with the payment control checked at **375px and 320px**. No horizontal overflow, wrapped currency amounts or missing Stripe icon remained. Six existing public-preview tabs were refreshed.
- Canonical preview commit **`b77b9baee9062e163a08164578ef419d5fd197a4`** changes exactly 23 intended files: nine sources, nine ordinary examples, four Stripe examples and one icon. **64/64** intended hosted files byte-match the maintained root and isolated website checkout, verified **2026-09-09T13:24:11.125131+00:00**.

[Exact qualification](NTE_EMAIL_QUALIFICATION_2026-09-09.json). Private raw inbox/render/deployment evidence and publication checks are under ignored `tmp/nte-email-revision-20260909`. Credentials and raw exports are excluded from the project checkpoint.

## Retained failed attempts and scope limits

The first actual candidate, `0AfAd00000Sr6GrKAJ`, rolled back after one new assertion compared the literal middle dot against HTML-encoded output. The corrected assertion checks decoded readable text and retains the exact **Total paid · excluding VAT** requirement; the final 82-test run passed. The first render-only harness used a converted Lead, which Salesforce refuses for Lead-template rendering. It was rerun using the existing owner-addressed unconverted Lead `00QAd00000URX9tMAH`; no record was created or edited. Both initial results remain in private evidence.

The canonical preview's diff check reported six whitespace-only blank lines left where CRM sections were removed. They do not affect email content and were retained to keep generated/deployed source identical. Existing unrelated generated-metadata whitespace was not changed.

Browser inspection does not represent a complete Outlook/Apple Mail/Gmail client matrix. Old delivered emails retain their original content. This release creates no new payment request, payment, booking milestone or email resend. No Stripe settings or production Salesforce environment were changed. The previous Stripe qualification's client-configuration and live-activation limitations still apply; P01/P03 and other unapproved policy proposals remain unchanged.
