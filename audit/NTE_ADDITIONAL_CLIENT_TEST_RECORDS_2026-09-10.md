# Additional client testing records — 10 September 2026

Five new interests and five new applications were submitted once each through the current Web-to-Lead forms. All ten remain unconverted. Applicant, event and finance email fields use **steven.skyba@anthrion.com**. The names and organisations are fictional.

| Stage | Organisation / brand | Contact | Payment selection / amount excluding VAT | Salesforce record |
|---|---|---|---|---|
| Open interest | Rookhaven Advanced Components Ltd | Isla Penrose | — | [I01](https://missionmotorsportnpc--mmuat.sandbox.lightning.force.com/lightning/r/Lead/00QAd00000UWULLMA5/view) |
| Open interest | Briarcrest Energy Services Ltd | Owen Caldwell | — | [I02](https://missionmotorsportnpc--mmuat.sandbox.lightning.force.com/lightning/r/Lead/00QAd00000UWfLKMA1/view) |
| Open interest | Marlowden Skills Partnership Ltd | Naomi Westcott | — | [I03](https://missionmotorsportnpc--mmuat.sandbox.lightning.force.com/lightning/r/Lead/00QAd00000UWgNpMAL/view) |
| Open interest | Avenholt Cyber Systems Ltd | Leo Hartwell | — | [I04](https://missionmotorsportnpc--mmuat.sandbox.lightning.force.com/lightning/r/Lead/00QAd00000UWgPRMA1/view) |
| Open interest | Dovewick Mobility Group Ltd | Clara Fenwick | — | [I05](https://missionmotorsportnpc--mmuat.sandbox.lightning.force.com/lightning/r/Lead/00QAd00000UWFdvMAH/view) |
| Application review | Limebrook Precision Systems Ltd / Limebrook Precision | Harriet Redmond | Stripe · £599.00 | [A01](https://missionmotorsportnpc--mmuat.sandbox.lightning.force.com/lightning/r/Lead/00QAd00000UWgUHMA1/view) |
| Application review | Ashcombe Horizon Group Ltd / Ashcombe Horizon | Nathan Bellamy | Stripe · £7,000.00 | [A02](https://missionmotorsportnpc--mmuat.sandbox.lightning.force.com/lightning/r/Lead/00QAd00000UW8kZMAT/view) |
| Application review | Westermoor Electric Vehicles Ltd / Westermoor EV | Freya March | Stripe · £949.00 | [A03](https://missionmotorsportnpc--mmuat.sandbox.lightning.force.com/lightning/r/Lead/00QAd00000UWVkOMAX/view) |
| Application review | Silverwick Infrastructure Ltd / Silverwick Works | Adam Fairburn | Bank transfer · £5,000.00 | [A04](https://missionmotorsportnpc--mmuat.sandbox.lightning.force.com/lightning/r/Lead/00QAd00000UWgR3MAL/view) |
| Application review | Hawthorn Reach Veterans Trust / Hawthorn Reach | Leila Chesworth | Complimentary · £0.00 | [A05](https://missionmotorsportnpc--mmuat.sandbox.lightning.force.com/lightning/r/Lead/00QAd00000UWgSfMAL/view) |

All five interest acknowledgements and ten internal notifications were accepted by Salesforce. The five applicant application acknowledgements correctly show **Not required**. No errors, bookings, conversions or payment requests were created for these ten references. These are submissions with Stripe selected, not completed payments.

## Testing Stripe

Convert Limebrook Precision Systems, Ashcombe Horizon Group or Westermoor Electric Vehicles to a new booking using the normal approval process. Keep the booking’s Primary Contact email as **steven.skyba@anthrion.com**. Their references begin `NTE-STRIPE-`, satisfying the current sandbox test restriction. After successful conversion, the existing workflow creates the itemised test Payment Link and includes it in the provisional reservation email. All three have quotation required set to No.

Ordinary public form references begin `NTE-`, so they do not currently qualify for the restricted Stripe test route. This task did not broaden that setting. Successful test checkout does not automatically mark Salesforce paid: the chosen manual payment-confirmation action remains in place. No payment or old email was replayed.

## Evidence

- Single-attempt ledger: `tmp/nte-client-followups-20260910/intake/ledger.json`.
- Per-record statuses and exact native readbacks: `tmp/nte-client-followups-20260910/intake/result.json`.
- Independent coordinator query: `tmp/nte-client-followups-20260910/independent-native.json`.
- The earlier 25 cases and the owner’s later changes to their stages remain preserved.
