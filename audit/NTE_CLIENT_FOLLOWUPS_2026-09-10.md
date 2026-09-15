# Selected client follow-ups — 10 September 2026

The requested form and email changes are implemented in MMUAT and published on the existing client preview. Proposal 14 preserves application/conversion timing, pricing rules and the restricted Stripe test configuration. The additional ten records are unconverted and ready for client testing.

## Delivered

- **Privacy:** both exhibitor and partner/sponsor application declarations now link to the supplied [NTE privacy notice](https://www.nationaltransitionevent.com/privacy), with an accurate “NTE27 Privacy Policy” label. The supplied destination returns HTTP 200. The volunteer form retains its own Mission Motorsport privacy notice. This link does not purport to supply separate booking terms.
- **Livery:** linked “Livery Bay” to [Mission Motorsport’s livery page](https://www.missionmotorsport.org/livery) in the exhibitor provisional, complimentary and payment-confirmation source templates. Their standard and Stripe variants inherit the link; HTML and native plain text both include its destination. No unrelated logistics wording was changed.
- **50% savings:** the exhibitor estimate shows eligible space savings and requested discounted power savings. A Blue Light or local-government £249.50 space saves £249.50 against the standard £499 rate; eligible sockets save £50 each. The form states savings excluding VAT beside the payable estimate. Free allocations retain their benefits list and are not assigned an invented 50% saving. Changing category, space or power updates/clears the saving correctly. Staff and package pricing are unchanged.
- **Internal application openings:** “A new partner / sponsor application has been submitted.” and “A new exhibitor application has been submitted.” The corresponding preview text also says submitted. The existing submission-time notification route is unchanged.
- **Stripe divider:** the shared payment-button renderer and preview generator now produce a 34px divider with equal 19px upper/lower gaps in the 72px button. Verified in the hosted email; the Stripe icon loads normally.
- **New test data:** five interests and five applications, including three Stripe selections, all using steven.skyba@anthrion.com. Ten POSTs, no retries, all ten unconverted. Five EOI receipts and ten internal notifications are accepted; the removed application receipts correctly remain Not required. [Names and exact Salesforce links](NTE_ADDITIONAL_CLIENT_TEST_RECORDS_2026-09-10.md).

## Stripe answer

A fresh read-only check through the Salesforce Named Credential verified the configured Stripe account and test mode. The existing test route is enabled for the exact MMUAT org, `NTE-STRIPE-` booking references and Primary Contact email `steven.skyba@anthrion.com`.

**Initial submission does not create a Payment Link.** Normal successful approval/conversion creates the booking, then eligible Stripe requests and their provisional emails. The three new Stripe applications have the required reference prefix and recipient, with no quotation prerequisite, so they are prepared for that client test.

**Ordinary public-form references start `NTE-` and are currently outside the restricted test prefix.** Selecting Stripe on an arbitrary submission does not, by itself, qualify it for test link generation. No allowlist or account configuration was widened in this task. Successful checkout still requires the chosen manual Salesforce payment-confirmation action. This follow-up did not create a new payment link, collect a payment, replay an earlier checkout or resend an old email.

## NTE2027 — inspected and unchanged

**16 active stored templates and 19 hosted email examples** still display the full event code for NTE2027 records. Other generated invitations, reminders and final packs can display it too. No visible NTE2027 wording remains in the maintained forms; nine forms populate the hidden Salesforce event code dynamically. All relevant event literals and merge tokens were compared before/after and preserved. [Full reference inventory](NTE2027_REFERENCE_INVENTORY_2026-09-10.md).

## Release evidence

Actual MMUAT **0AfAd00000SrqLMKAZ** passed **6 components / 37 affected tests**. Final full check-only **0AfAd00000SsD4zKAF** passed **469 components / 304 tests**, with zero errors, **469 matching members / 533 unchanged source and manifest hashes**. Current form checks: **140 passed, zero failed**, including **34,986 catalogue/boundary combinations**.

The exact deployment, full-package qualification, hashes, hosted verification and finite test limits are recorded in [the qualification](NTE_CLIENT_FOLLOWUPS_QUALIFICATION_2026-09-10.json).

The existing preview was prepared from canonical commit `39f5d35215b5c9f7d563f2c49b10c16e7e0f229e` in an isolated checkout and published as **`24da51ef84e51f0b3bea7d12cc9eb4d8929b1a8d`**, changing exactly **28 intended website files**. The Pages build passed and **31/31 reviewed files** were byte-verified. The subsequent separate volunteer correction, commit `5fb41927a9e301aab921894af101891602ad72e6`, removes paper-signature lines; its current hosted page also matches local source and preserves this release’s shared asset references. No unrelated source was overwritten.

Six native stored-template renders verified HTML/text, links and wording without DML or sends. The full form-engine run includes the new category/space/power savings transitions and the current volunteer reader. Browser inspection verifies the actual form estimate, privacy link and published payment button. These checks do not constitute an Outlook/Apple Mail/Gmail client matrix.

## Decisions still outside this follow-up

The four newly selected items in the [earlier client-request table](NTE_CLIENT_REVISIONS_2026-09-10.md)—privacy, livery links in emails, discount savings and internal opening wording—are now delivered. Global shortening of dynamic email event labels was inspected only. Partner staff allowances, decision timescales, automatic/bulk approval, new scheduled reports and client handover choices remain as previously documented. The secure logo destination, actual final packs, client financial settings and separately agreed booking terms remain dependencies. No production Salesforce or live-payment release was performed.
