# Free-space confirmation correction — 17 September 2026

Proposal 31 implements the owner's selected simplicity finding **S01** and completes the downstream confirmation behaviour required by proposal 23. Other findings in the [simplicity audit](NTE_SIMPLICITY_AUDIT_2026-09-16.md) remain separate decisions.

## Corrected behaviour

Any organisation category can use either recognised complimentary exhibitor space. After the team approves a genuinely £0 booking, **Confirm Free space** sends the complimentary confirmation to its Primary Contact and records the free confirmation. A previous category-related failure can use the existing manual confirmation action again. This release does not automatically retry old bookings.

For example, an Employer - Automotive Sector application for either free space with two included staff and no power now passes the same confirmation rule as a charity application. Adding a standard £100 socket still makes the booking payable at £120 including VAT; it uses the paid provisional message. The separate category-based socket discount is unchanged.

The only runtime change removes the two obsolete organisation-category conjunctions from `isEligibleComplimentaryBooking` in [NTEExhibitorApprovalEmailService](../force-app/main/default/classes/NTEExhibitorApprovalEmailService.cls#L642). The existing shared helper therefore gives consistent results for saved-price validation, template selection, payment wording, email styling and the original-price check used by later staff top-ups.

Recognised space choices, coherent calculated totals, paid extras, VAT, explicit full waivers, human confirmation, Primary Contact routing and duplicate protection remain. No organisation is reclassified, no saved booking is repriced, and no operational email or payment is replayed. The forms already permit these choices, so website and email-template source files do not change.

## Regression evidence

- [Approval-email tests](../force-app/main/default/classes/NTEExhibitorApprovalEmailServiceTest.cls) exercise all **19 organisation categories × 2 free spaces**, checking accepted confirmation, correct HTML/text/template, Primary Contact, unchanged category/space/£0 amounts and one accepted message. Commercial free space with a paid socket remains payable. Unknown, uncalculated and inconsistent zero prices remain rejected.
- [Manual finance tests](../force-app/main/default/classes/NTEManualFinanceTest.cls) convert fresh commercial applications for both spaces, verify silent conversion, use the real manual confirmation action, recover a previous failure and reject a duplicate confirmation.
- [Staff top-up tests](../force-app/main/default/classes/NTEManualStripeTest.cls) cover a non-charity booking on each free space with a later £50 + VAT staff top-up, using mocked provider calls and no external payment. The original £0 booking and its free-confirmation history remain intact.
- Existing paid-booking, exhibitor/partner waiver, VAT, pricing, recipient and recovery tests remain part of the full Salesforce validation.

Check-only run `0AfAd00000SyKjhKAF`, using the **old helper with the new tests**, compiled all four classes and produced exactly six expected test failures out of 58 tests: the modified commercial confirmation test plus five new regression methods. The failures reproduce the obsolete price-review rejection in confirmation, retry and top-up paths. This run deployed nothing.

All local checks pass: forms and email assets/presentation, page isolation, volunteer compatibility, **154 form-engine checks / 35,536 combinations**, **89 panel checks**, metadata/report semantics, **five shared-picklist tests** and **seven Stripe-preflight tests**. An isolated build changed none of the **994 compared files**. Four of the **614 qualified source/manifest files** change: one runtime class and three existing test classes; the other 610 remain byte-identical.

## Release status

Full MMUAT check-only validation **`0AfAd00000SyKtNKAV` succeeded: 528 components / 434 tests, zero errors.** All six methods that failed with the old helper pass with the corrected source; all 58 methods in the three affected test classes pass as part of the full run.

Targeted MMUAT release **`0AfAd00000SyLRFKA3` succeeded with exactly four Apex classes**: the runtime helper and its three test classes. The release uses the same source hashes as the full validation; native readback matches all four bodies, allowing only Salesforce's omitted final newline. No other component was deployed by the actual release. [Current source hashes and machine-readable qualification](NTE_FREE_SPACE_CONFIRMATION_QUALIFICATION_2026-09-17.json).

The implementation and release evidence are included in the private `stevostar1234/mission-community-nte-platform` project. Production Salesforce remains a separately authorised release. Existing failed confirmations require the team's normal deliberate retry; this correction did not replay them.

Local operation results and rollback-only regression evidence are retained under `tmp/nte-free-confirmation-20260917/`. Existing successful submissions, sends, payments and historical audit fixtures are preserved.
