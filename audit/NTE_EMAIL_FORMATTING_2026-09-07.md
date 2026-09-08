# NTE email formatting — 7 September 2026

Implemented in the maintained source, MMUAT and the canonical client preview site. No production deployment, record changes or live email sends were performed for these corrections. The completed Anthrion journey and its inbox messages are retained.

## Corrections

- Removed the extra literal pound symbol from the exhibitor staff-update acknowledgement and the exhibitor application internal notification. Salesforce's native Currency merge already supplies the symbol. The preview generator now uses the generated field types to reproduce that formatting, including two decimal places and grouping.
- Matched previews to Salesforce's native multiline HTML merging. Salesforce renders stored line breaks as a newline plus `<br>`; `white-space:pre-line` displayed both and doubled the spacing between names. Removed that extra whitespace styling from the maintained templates and made the previews reproduce native `<br>` output.
- Generated explicit readable text alternatives for all 21 stored templates, with separate paragraphs and table rows, decoded entities and usable links. Provisional/payment runtime text generation now also omits hidden preheaders, empty image links and non-breaking layout spaces.
- Removed the entire paragraph “A first request for top-up places is invoiced separately. Correcting names does not create another charge.” from the exhibitor staff acknowledgement, following the owner's browser annotation. The surrounding empty layout row was removed too. The top-up finance rules are unchanged.
- Recorded the owner's standing approval to correct email formatting issues in `AGENTS.md` and the desired workflow. Client terms and substantive wording remain unchanged except for that explicitly requested paragraph removal.

## Verification

| Check | Result |
| --- | --- |
| Local `npm run validate` | Build and form/email checks passed; all 21 templates regenerated |
| Template deployment `0AfAd00000Sp2vhKAB` | 21 components passed |
| Runtime text correction `0AfAd00000Sp3RxKAJ` | 2 components and 23 focused Apex tests passed |
| Native spacing deployment `0AfAd00000Sp3WnKAJ` | 21 components passed |
| Requested paragraph removal `0AfAd00000Sp3i5KAB` | 1 component passed |
| Final full-manifest check-only `0AfAd00000SotIyKAJ` | 413/413 components and 181/181 local Apex tests passed |
| Final source reconciliation | 473 source/manifest files inventoried; only email components and the approval service/test changed |
| Final preview commit `18171e8d80751272971acf4012a1611de976c53e` | Built by GitHub Pages; all 42 served template/source examples match local bytes |

The new automated checks reproduce currency merging and verify plain-text paragraph, row, entity and link handling. Actual MMUAT rendering was also exercised for the staff acknowledgement, provisional email and booking-payment confirmation, with assertions for single pound symbols, readable text and the paragraph removal. The render-only probe recorded **zero DML statements and zero email invocations**.

The native staff rendering probe used the retained, rejected second-top-up submission solely as merge data. Its preview therefore shows two requested places and £100. This is not an accepted charge or a new acknowledgement: the existing booking retains its previously accepted one-person £50 top-up. An initial probe attempted to render an already-converted application Lead; Salesforce correctly refused that unsupported merge target. The final probe uses a retained unconverted supplementary Lead and the existing booking/Contact, without creating replacement records or changing their state.

Browser verification confirmed single line spacing between staff names, one £ symbol, the removed paragraph and no horizontal page overflow. The published internal notification reads “2 at £50.00 each”. The partner provisional email retains its loaded logo and horizontally aligned preparation buttons. This verifies browser/native rendering; no new inbox delivery was needed, and already-delivered messages retain their original contents.

The first full check-only validation (`0AfAd00000Sp1DHKAZ`, 413 components and 180 tests) preceded the additional runtime-text and spacing refinements. The final validation above supersedes it. Intermediate public commits `5a9f178f8cf2f3446cc3bf65f3eda854de44e956` and `ca292a35f685043c43485c5a90695c5bf58f8c6f` were followed by the final paragraph-removal commit. The final hosted byte verification is authoritative.

Private evidence: `tmp/nte-email-formatting-20260907/`, including deployment responses, rendered HTML/text, hosted verification, source hashes and reconciliation. The separate rejection-feedback and supplementary-owner findings from the browser walkthrough remain outside this formatting change.
