# Requirements UI design QA

Status: **passed for the selected visual design** — 13 September 2026, MMUAT deployment `0AfAd00000SuUhdKAF`. The later independent-invoice/receipt changes are separately qualified in the final release evidence.

## Approved design

The final approved reference is `codex-clipboard-cc069da2-875b-4488-a063-78fadc832d2a.png`: full-width slate header, white identity text, gold underline, gold Requirements/Details headings and alternating rows. The owner additionally requested a gold Open full record button. This supersedes the earlier partial-header experiments.

Reference: the owner-selected requirements ledger screenshot `codex-clipboard-8c33a614-5503-4989-8279-252ae2da6a70.png`, plus the blue-checkbox reference and subsequent six browser annotations. The later annotations explicitly replace the original neutral header with the existing NTE gold, add a navy outline and direct record link, and remove the lower detail pane only from Requirements. No new artwork is required.

## Verified result

- Native Salesforce screenshots were viewed beside the selected reference in the same browser tool call. The cards preserve the aligned vertical checklist, adjacent details, readable totals and compact treatment for bookings with no checklist.
- Existing NTE gold is `#f0b323`; outlines and heading text use existing navy `#071f35`. Native checked controls are blue. Toolbar-to-card and inter-card spacing is 16px at desktop width.
- All 15 visible cards passed overflow checks at 1435px and 390px viewports. The mobile card width was 312px; no action or full-record link crossed its border. Long names and references wrap.
- Every card links to its own Opportunity. The Bracken full-record link was opened and its exact booking reference verified. Requirements has no complementary detail pane; other views retain it.
- Headers read Requirements and Details. Paid exhibitor records read Exhibitor booking; partner records show their actual package names, separated cleanly when multiple are selected. Staff top-ups and complimentary bookings retain their distinct labels. No Original booking paid subtitle is present.
- Long notes retain all data and offer View full details / Show less. The 5,801-character edge case was expanded through its final Division 36 entry, with a bounded scroll area; short notes remain directly visible.
- All ten new application examples were verified against native Salesforce values. Mixed and fully checked cases retained their saved checklists after reload. Neither state triggered a payment request or booking email.
- Browser console errors: none. Local panel tests: 38 passed. Deployment: 1 LWC and 16 affected Apex tests passed.

## Resolved findings

An earlier native generic definition-list style squeezed amounts onto multiple lines; explicit summary-cell layout fixed it. Earlier uppercase/small table text was corrected. The long-notes case now uses expandable details so it does not dominate the page. The final annotated refinement was retested at both widths.

## Evidence

Authenticated screenshot evidence is in the task's browser tool results for the MMUAT Master Panel, including the side-by-side reference comparison and mobile capture. Structured data and source hashes are under `tmp/nte-requirements-ui-20260913/`; deployment reports are under `tmp/nte-manual-finance-20260913/`. No standalone screenshot file was returned by the native browser capture API.

## Final selected-style check

UI13 was compared with that exact reference in the same browser tool call. Native desktop cards retain the selected hierarchy with the requested gold button. At 390×844 all 14 cards had matching client/scroll widths of 312px, and the bottom chart region had matching widths of 333px. Long names, notes and package names wrap. Chart labels now sit below proportional bars so zero/small counts remain visible; 0 awaiting review, 2 outstanding and uneven green/orange ratios were inspected. The viewport override was reset. No checkboxes or finance actions were changed during this visual pass. Evidence: `tmp/nte-final-audit-20260913/ui13-native-responsive-qa.json` and the paired CUA images.
