# Open exhibitor space requests — release checkpoint

Proposal 23 is approved for MMUAT and the canonical preview. Production Salesforce deployment remains separate. The source changes remove organisation-category gates for all listed spaces and add the comparative £499 + VAT value to both complimentary selections. Extra charges and VAT are unchanged; free selection does not automatically approve a booking.

The four modified Salesforce files are the pricing service and its pricing, stress and conversion tests. No metadata fields, catalogue values or production manifest members are added or removed. All other 590 qualified source/manifest hashes match the prior GitHub baseline. Removed the obsolete browser eligibility functions and disabled-option CSS; no unrelated field or validation changes.

Local form tests pass. Form-engine stress passes 154 checks / 35,536 combinations. The isolated generator reproduces 660 compared files exactly; metadata/report checks pass.

Full check-only **`0AfAd00000Sw2KfKAJ`** passed **509 components / 422 tests**, zero errors. Actual MMUAT deployment **`0AfAd00000Sw3DVKAZ`** applied the exact qualified 594-source-hash candidate, with 509 successful components and no errors. All 509 manifest member identities reconcile after Salesforce's normal Report-folder type representation. Readback of all four changed Apex classes matches the source apart from Salesforce omitting the final newline. [Exact source hashes and qualification](NTE_SPACE_SELECTION_QUALIFICATION_2026-09-15.json).

The public candidate was prepared from canonical main `eb07a0b6990ae5c2dbbc43a0a523136194828bd5`. It contains 12 intended files: exhibitor wording, shared JavaScript/CSS cleanup, and the current script revision on all ten forms. Every original file matches that remote baseline. New script revision: `20260915-spaces-1`.

Published canonical commit **`31c568e7529acee99c6717c0dbf162982a3940ea`**. All **12/12 hosted files** are HTTP 200 and byte-identical to the reviewed source. The actual browser confirms commercial free selections, £0 finance hiding, £120 total for one standard paid socket with full Stripe/invoice requirements, £299.40 total and saving for a discounted space, and preservation of a free selection after changing category to CIC. The complete value callout fits the inspected desktop layout. No browser form was submitted. Local tests cover the broader permutations; this release did not repeat all prior device/end-to-end journeys.

Evidence: `tmp/nte-space-eligibility-20260915/`. No real form submissions, operational emails, payments, fixture conversions, retrospective repricing or record cleanup are performed by this release. Rollback-only native test data is not operational data.

[Remaining form restrictions and practical exceptions](NTE_FORM_RESTRICTIONS_2026-09-15.md). The 14 September failure guide is preserved as a dated document, with its superseded space-eligibility rule called out in the current guide index.
