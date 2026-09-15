# Cosmetic NTE27 wording — release record

Completed 11 September 2026 under the owner's explicit cosmetic-only approval (proposal 16).

**Cosmetic NTE27 branding, 11 September — complete:** proposal 16 uses fixed NTE27 display wording across all 17 NTE templates and their generated HTML/plain-text communications, with the same label for new Stripe requests. Required booking-template placeholders remain, with constant display replacements. Actual MMUAT **`0AfAd00000StDxOKAV`** passed **18 components / 87 affected tests**; full check-only **`0AfAd00000StLJpKAN`** passed **304 local tests**, zero errors, with **470 unique component identities and 534 source/manifest hashes** reconciled. Twenty-one native email renders and six live draft previews passed with zero DML/sends. Preview **`f55cdf2b761ee36af057f768dcd3bdc7224543a2`** changes 31 intended files; all 106 deployed page/script paths were checked, with 59 current files matching and 47 redirects. Functional event codes, explicit EventCode tokens and both existing Stripe request payloads remain unchanged. [Release and retained wording](NTE_COSMETIC_BRANDING_2026-09-11.md); [qualification](NTE_COSMETIC_BRANDING_QUALIFICATION_2026-09-11.json). No historical send/payment was replayed or production deployed.

## Result

All normal recipient-facing NTE year branding now displays **NTE27**: 12 Lead-based templates have literal wording; the five booking templates retain their required display markers, which the booking renderer now fills with the constant NTE27. The preview generator uses the same constants. This covers all 21 NTE preview variants; the two Mission Motorsport volunteer previews are unchanged.

Generated invitations, staff reminders, logistics reminders, logo reminders and final-pack emails use NTE27 in the HTML header and appended plain-text event label. New Stripe requests use **NTE27 booking · [booking reference]**. Existing subjects continue to use plain NTE without a year.

Only five production-code expressions changed, across the booking-email sender, generated-email sender and new Stripe-request description. All 417 captured forms, configuration, object-field, Flow and UI files are byte-identical. Other client wording, merge data, links, pricing, VAT, recipients, routing, eligibility and timings are unchanged. The required-marker validator is preserved.

## Wording deliberately retained

| Location | Reason |
| --- | --- |
| Actual event identifiers, event selectors/report groupings, booking references and event-format validation guidance | They represent or validate real event data. They continue using the existing values and logic. |
| Explicitly inserted `{EventCode}` placeholders in custom messages | This token's purpose is to show the actual identifier. Default message branding no longer uses it; its functional meaning remains intact. |
| Two existing Stripe requests and their already-created provider objects | The saved description is part of their original creation/retry payload. It is preserved across every captured field and timestamp. New requests use NTE27. |
| Previously delivered messages and dated audit/restoration copies | Historical material is preserved; no successful email or payment was repeated to alter earlier wording. |

Stripe rejects reused idempotency keys with different request parameters; preserving an earlier request's saved wording avoids changing that payload during a cosmetic release. The integration's operation keys, booking references, fingerprints, money and source event identifiers are unchanged. [Stripe's idempotency rules](https://docs.stripe.com/api/idempotent_requests).

The booking display markers themselves remain in five templates because the sender validates their presence. Their replacement value is now constant NTE27; this is not an outstanding visible-wording issue and does not use the actual event identifier for branding.

## Verification

- `npm run validate` passed. The generated source and previews retain every non-year text/markup change exactly; public email links and required booking markers are unchanged.
- Actual release `0AfAd00000StDxOKAV`: 18/18 components, 87/87 affected tests, zero errors. Regressions cover real event identity behind a static header, explicit event-code placeholders, correct amounts/manual payment confirmation, preserved template checks and retries of an older Stripe description with the same keys and payload.
- Full check-only `0AfAd00000StLJpKAN`: 304/304 local tests, zero errors. All 470 unique component identities and 534 candidate source/manifest hashes reconcile. Aggregate SHA256: `af914290598d66ebb76784c4bc09123d9554839f01d4c1f108cb6a8ecd300b82`.
- All 19 maintained native templates match the deployed source in HTML, plain text and subject. All 115 sandbox template subjects are preserved; 12 stored templates changed, while the five booking templates receive their new wording through the renderer.
- Twenty-one real stored-email renders cover all 17 NTE templates, including standard/Stripe provisional and paid variants and a complimentary context. HTML/plain text show NTE27, no unresolved markers and no doubled currency symbols. All calls assert zero DML and zero email invocations.
- Six read-only management-app previews cover exhibitor/partner invitations, exhibitor/partner staff reminders, logistics and logo reminders. Actual event identity remains NTE2027. Final-pack destinations remain unconfigured; their gates and shared rendering path are covered by the isolated Salesforce tests, with no routing configuration or pack send changed.
- The initially selected Rookhaven interest had already been invited during client testing, so the renderer correctly excluded it. The successful read-only check used the still-open Briarcrest interest; no stage/status was reset and no invitation resent.
- Both existing Salesforce payment-request records are identical across every captured field and timestamp. No Stripe API mutation, new link or payment occurred in this task.
- Canonical preview commit `f55cdf2b761ee36af057f768dcd3bdc7224543a2` publishes only the 31 approved source/example HTML paths from the then-current main branch. All 106 deployed HTML/JavaScript paths were read: 59 maintained files match and 47 old paths remain redirects. No published visible NTE2027 branding remains in the maintained pages/examples.

## Resolved and unrelated check findings

The first candidate `0AfAd00000StJzZKAV` failed the existing booking required-marker checks and rolled back atomically. The corrected release preserves the markers and changes only their cosmetic replacement values. No validation was removed or weakened.

The optional standalone report-test harness (`tests/metadata-reports.test.js`) has a pre-existing `ReferenceError: write is not defined` at its generator-extraction boundary. It fails identically in the untouched source snapshot. It is outside this wording change and was not modified; the required local validation and full native package tests pass.

## Maintenance and evidence

The year label is deliberately static. A future edition needs a coordinated copy update in the email sources, booking-renderer/preview constants, generated communication labels and new Stripe description. Functional event-code rollover does not update these labels. The maintenance guide now records those locations and preserving existing request payloads.

Implementation: `email-templates/source/`, `scripts/build-metadata.js`, `NTEExhibitorApprovalEmailService.cls`, `NTEEmailDispatchService.cls` and `NTEStripeBookingService.cls`. The complete package is current; production deployment remains separately authorised.

Private evidence: `tmp/nte-branding-20260911/` contains the restoration snapshot, source hashes, exact release manifest and results, actual rendered email bodies, preview checks, payment preservation snapshots, publication commit and hosted verification. [Machine-readable qualification](NTE_COSMETIC_BRANDING_QUALIFICATION_2026-09-11.json). The earlier [wording inventory](NTE_VISIBLE_YEAR_WORDING_2026-09-11.md) remains a dated before-change record.
