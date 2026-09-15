# NTE2026 and NTE2028 dummy cleanup — 11 September 2026

The owner requested removal of the NTE2026 and NTE2028 dummy records. The narrower enquiry/booking cleanup is complete in MMUAT. The associated organisation/contact deletion was rejected by automatic approval review and remains unexecuted.

## Removed and verified

| Year | Record | Salesforce ID |
| --- | --- | --- |
| NTE2026 | Elmbridge Trade Network — Freya Cameron, expression of interest | `00QAd00000URMxgMAH` |
| NTE2028 | Westhaven Communications — Henry Sinclair, expression of interest | `00QAd00000URRMDMA5` |
| NTE2026 | Fenmere Robotics - NTE2026 — comparison booking | `006Ad00000UdgKiIAJ` |

Two linked sent email-dispatch history rows were also deleted: `a08Ad00000bw5lEIAQ` and `a08Ad00000bwH9dIAE`. These were Salesforce history entries; no inbox message was removed or resent. The booking’s single contact role was backed up before the parent was deleted.

The five explicitly deleted records are verified as `IsDeleted=true` through queryAll. Deletion used ordinary recoverable Salesforce DML, with exact IDs, a complete field backup and change-detection guards. No purge or permanent-delete operation was performed.

After commit, the real Master Panel controller returns exactly one event option, **NTE2027**, and selects it by default. That verification used zero DML statements and zero email invocations. No active 2026/2028 Lead or Opportunity remains.

Preservation checks match the captured IDs, classifications/references and modification timestamps for **44 NTE2027 bookings, 137 NTE2027 Leads, 115 NTE2027 Accounts and 115 NTE2027 Contacts**. All 720 Accounts and 811 Contacts remain. All **534 source/manifest hashes** are unchanged. This was a data-only change: no metadata deployment, full regression rerun or preview publication was needed.

## Retained records requiring specific approval

Automatic approval review rejected the wider deletion with this reason: “The deletion script targets broad related Account and Contact sets that include active NTE2027-linked records and real-looking data, so its scope exceeds the user’s authorization and risks irreversible data loss.” The rejected script did not execute. The completed narrower operation contains no Account or Contact DML.

The following 13 identities retain their NTE2026/NTE2028 classification. They do not populate the Master Panel event selector. Further deletion requires specific approval after that review rejection.

| Type | Year | Name | Salesforce ID |
| --- | --- | --- | --- |
| Account | NTE2028 | NTE FUTURE ISOLATION TEST ONLY NTE2028 CQ | `001Ad000017drRKIAY` |
| Account | NTE2028 | NTE FUTURE ISOLATION TEST ONLY NTE2028 CI | `001Ad000017drRLIAY` |
| Account | NTE2028 | NTE FUTURE ISOLATION TEST ONLY NTE2028 CD | `001Ad000017drRMIAY` |
| Account | NTE2028 | NTE FUTURE ISOLATION TEST ONLY NTE2028 CP | `001Ad000017drRNIAY` |
| Account | NTE2028 | NTE FUTURE ISOLATION TEST ONLY NTE2028 CC | `001Ad000017drROIAY` |
| Account | NTE2028 | Hartwell Precision Engineering | `001Ad0000193oxfIAA` |
| Contact | NTE2028 | FutureNTE2028CQ Isolation1005 | `003Ad000017pN1FIAU` |
| Contact | NTE2028 | FutureNTE2028CI Isolation1006 | `003Ad000017pN1GIAU` |
| Contact | NTE2028 | FutureNTE2028CD Isolation1007 | `003Ad000017pN1HIAU` |
| Contact | NTE2028 | FutureNTE2028CP Isolation1008 | `003Ad000017pN1IIAU` |
| Contact | NTE2028 | FutureNTE2028CC Isolation1009 | `003Ad000017pN1JIAU` |
| Contact | NTE2026 | Daniel Vale | `003Ad000019nIwBIAU` |
| Contact | NTE2028 | Sofia Ellison | `003Ad000019ncw5IAA` |

The five “NTE FUTURE ISOLATION TEST ONLY” organisations and their contacts are older explicit isolation fixtures. Hartwell/Sofia also appeared in the earlier cross-year NTE2027/NTE2028 identity test. Daniel is the NTE2026 comparison Contact on the Fenmere account. **Fenmere Robotics (`001Ad0000193s4kIAA`) and Leonie Asquith (`003Ad000019nIwAIAU`) are classified NTE2027 and were excluded from every proposed deletion.**

The read-only dependency inventory found no active booking on the six candidate Accounts, no active converted Lead linked to these candidates, and no related cases, assets, campaigns, child Accounts, contracts, orders, Tasks or Events. This evidence is preserved for review; it is not an override of the approval rejection.

## Evidence and continuation

- Executed exact scope: `tmp/nte-year-cleanup-20260911/approved-scope-plan.json`.
- Backups: `backup-Lead.json`, `backup-Opportunity.json`, `backup-NTE_Email_Dispatch__c.json`, `backup-Account.json`, `backup-Contact.json`, `backup-OpportunityContactRole.json` in the same directory.
- Successful mutation result: `delete-year-entries-result.json`.
- Independent post-commit read: `panel-after.json`.
- Record/source preservation: `verification-summary.json` and the before/after snapshots.
- Wider rejected scripts now have a failing safety assertion to prevent accidental replay. Do not rerun the completed deletion or use the rejected script as an approval bypass.

The prior dated stress-audit preservation statements remain historical evidence. This explicit user-requested removal supersedes retention only for the five executed IDs and the dependent 2026 booking role. NTE2027 testing and the newly assigned Kate/Tony access remain intact.
