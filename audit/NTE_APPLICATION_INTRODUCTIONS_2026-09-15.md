# Application introductions — 15 September 2026

The owner explicitly requested Kate's amended wording for the Exhibitor and Partner/Sponsor forms. Source: her email **Amended wording for the Exhibitor and Partner/Sponsor application forms**, sent at 13:59 UTC on 15 September, Gmail message `1a0a55d4f929760a`.

The first three paragraphs of each introduction now match the supplied copy, with ordinary HTML whitespace between sentences. The exhibitor approval/payment paragraph and partner support paragraph already matched and remain unchanged. No questions, prices, validations, field mappings, emails or Salesforce functionality changed for this wording request.

Published to the existing `stevostar1234/nte27-web-to-lead-demo` main branch as `1267cc0` (two HTML files; six lines replaced). Both hosted files match source byte-for-byte:

| Page | SHA-256 |
| --- | --- |
| Exhibitor application | `1265727160a929fbceedc8d614bcd83deb1fe084ebe99c3babc95b799b7c978f` |
| Partner/sponsor application | `f1098655d2ffd5135c475532ff45ae15eef5905c0095aef86031ce949a5d35cd` |

The existing introduction assertion was updated to the latest approved wording. Form checks and both six-case page/volunteer compatibility suites pass. No form submission or email was needed to verify this prose-only update; separate volunteer integration tests are recorded in their own release.

The owner also asked about replacing semicolons in native volunteer multi-select fields. After reviewing Salesforce's standard rendering, they explicitly chose to leave it unchanged. No extra preferences component, duplicate fields or delimiter change was implemented.
