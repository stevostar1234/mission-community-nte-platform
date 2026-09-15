# NTE meeting examples — 14 September 2026

Completed at the owner’s explicit request. Retain these examples for the client meeting; do not replay the create, payment, refund or submission scripts. Earlier paid history was preserved.

## Stripe dashboard examples

Verified account `acct_1UD8GwBcW1MkMYQ1`, test mode only. These seven examples were created directly through the Stripe API using the sandbox’s existing secure Named Credential and official test PaymentMethods. They demonstrate provider outcomes; they are not seven newly completed Salesforce-to-Checkout journeys. No real money, Radar setting change, live activation or Salesforce payment confirmation occurred.

| Example | Company | Amount | Verified result |
| --- | --- | ---: | --- |
| [Normal Visa](https://dashboard.stripe.com/acct_1UD8GwBcW1MkMYQ1/test/payments/pi_3UFVGsBcW1MkMYQ119ie4uUN) | Astermere Engineering Ltd | £958.80 | Succeeded; normal risk 7 |
| [Normal Mastercard](https://dashboard.stripe.com/acct_1UD8GwBcW1MkMYQ1/test/payments/pi_3UFVGtBcW1MkMYQ11Vh9J0lA) | Bellwick Mobility Ltd | £2,400.00 | Succeeded; normal risk 44 |
| [High risk](https://dashboard.stripe.com/acct_1UD8GwBcW1MkMYQ1/test/payments/pi_3UFVGvBcW1MkMYQ10iPrUKCw) | Cedarhurst Technical Services Ltd | £958.80 | Blocked by existing highest-risk rule; score 87; £0 collected |
| [Medium risk](https://dashboard.stripe.com/acct_1UD8GwBcW1MkMYQ1/test/payments/pi_3UFVGwBcW1MkMYQ104UWxQq5) | Daleswick Careers Ltd | £958.80 | Succeeded; elevated risk 69; no review created |
| [Full refund](https://dashboard.stripe.com/acct_1UD8GwBcW1MkMYQ1/test/payments/pi_3UFVGxBcW1MkMYQ10oamGtxo) | Elmbrook Infrastructure Ltd | £2,400.00 | Full £2,400 refund succeeded |
| [Dispute](https://dashboard.stripe.com/acct_1UD8GwBcW1MkMYQ1/test/payments/pi_3UFVGzBcW1MkMYQ10GCuryzU) | Fairmere Training Ltd | £958.80 | Open product-not-received dispute, needs response |
| [Insufficient funds](https://dashboard.stripe.com/acct_1UD8GwBcW1MkMYQ1/test/payments/pi_3UFVM5BcW1MkMYQ106HoTEIw) | Glenmere Skills and Training Ltd | £958.80 | Declined: insufficient_funds; £0 collected |

The existing highest-risk block was exercised without altering rules. The elevated-risk result reflects this account’s actual configuration. The refund used requested_by_customer and the dispute was left open. Net/VAT descriptive metadata from the first six examples was normalised to plain integer pennies after a scientific-notation encoding issue; actual charge amounts and states were unchanged and verified. The seventh was correct at creation.

Official test values: [Stripe testing documentation](https://docs.stripe.com/testing).

## Five interests and five Stripe applications

All ten went through the current forms’ serializer and normal Web-to-Lead intake once each. Fresh native readback verifies New, unconverted, NTE2027, applicant email steven.skyba@anthrion.com, no converted Opportunity and no email error. All normal internal notifications were accepted by Salesforce. Interest acknowledgements were accepted; application acknowledgements remain Not required under the agreed workflow. Salesforce acceptance is not a separate inbox-delivery assertion.

| Reference | Company | Type | Lead |
| --- | --- | --- | --- |
| NTE-MEETING-20260914-A01 | Harborough Mobility Systems Ltd | Exhibitor Application | [Open record](https://missionmotorsportnpc--mmuat.sandbox.lightning.force.com/lightning/r/Lead/00QAd00000UcaIvMAJ/view) |
| NTE-MEETING-20260914-A02 | Veldon Renewable Energy Ltd | Exhibitor Application | [Open record](https://missionmotorsportnpc--mmuat.sandbox.lightning.force.com/lightning/r/Lead/00QAd00000UcaKXMAZ/view) |
| NTE-MEETING-20260914-A03 | Rowanbridge Veterans Network | Exhibitor Application | [Open record](https://missionmotorsportnpc--mmuat.sandbox.lightning.force.com/lightning/r/Lead/00QAd00000UcaNlMAJ/view) |
| NTE-MEETING-20260914-A04 | Fenbrook Digital Learning Ltd | Partner / Sponsor Application | [Open record](https://missionmotorsportnpc--mmuat.sandbox.lightning.force.com/lightning/r/Lead/00QAd00000UcaM9MAJ/view) |
| NTE-MEETING-20260914-A05 | Northwick Infrastructure Group Ltd | Partner / Sponsor Application | [Open record](https://missionmotorsportnpc--mmuat.sandbox.lightning.force.com/lightning/r/Lead/00QAd00000UcUGkMAN/view) |
| NTE-MEETING-20260914-I01 | Wrenford Precision Manufacturing Ltd | Exhibitor Expression of Interest | [Open record](https://missionmotorsportnpc--mmuat.sandbox.lightning.force.com/lightning/r/Lead/00QAd00000UcSvIMAV/view) |
| NTE-MEETING-20260914-I02 | Dalesmere Renewable Systems Ltd | Exhibitor Expression of Interest | [Open record](https://missionmotorsportnpc--mmuat.sandbox.lightning.force.com/lightning/r/Lead/00QAd00000UcZptMAF/view) |
| NTE-MEETING-20260914-I03 | Bramwell Digital Academy Ltd | Exhibitor Expression of Interest | [Open record](https://missionmotorsportnpc--mmuat.sandbox.lightning.force.com/lightning/r/Lead/00QAd00000UcUbiMAF/view) |
| NTE-MEETING-20260914-I04 | Hartbridge Mobility Group Ltd | Partner / Sponsor Expression of Interest | [Open record](https://missionmotorsportnpc--mmuat.sandbox.lightning.force.com/lightning/r/Lead/00QAd00000UcZrVMAV/view) |
| NTE-MEETING-20260914-I05 | Lindenvale Cyber Systems Ltd | Partner / Sponsor Expression of Interest | [Open record](https://missionmotorsportnpc--mmuat.sandbox.lightning.force.com/lightning/r/Lead/00QAd00000UcYfWMAV/view) |

All five applications select Stripe, have Calculated pricing, and reconcile net + VAT = gross. They cover a full requirement set, no requested documents, complimentary space with a £60 paid power extra, Champion Partner and Zone Sponsor. Gross amounts: £958.80, £1,318.80, £60, £2,400 and £6,000. They are ready for the owner to demonstrate conversion and then the explicit Requirements send action. No conversion or payment request was issued for them in this run.

## Evidence and preservation

- Root evidence: `tmp/nte-meeting-stripe-20260914/RESULTS.json`, `verified-six.json`, `insufficient-case.json`, `ten-leads-qualified.json` and metadata-only readback.
- Agent intake evidence: `interests/verified.json`, `applications/verified.json`, exact plans, requests, responses and once-only ledgers.
- Chrome Transactions visibly showed all seven new examples, including Failed / Insufficient funds. The dashboard was left open. An unrelated £1 incomplete invoice payment also appeared during the work; it is outside this run and was not touched.
- No product source, website, Salesforce metadata or Stripe settings changed. Normal intake emails only. Preserve all older retained records and these ten new Leads.
