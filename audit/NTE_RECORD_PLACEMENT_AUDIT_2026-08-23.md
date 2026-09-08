# NTE record placement and dashboard reconciliation

Date: 23 August 2026  
Target: Mission Motorsport MMUAT sandbox (`00DAd00000A95VlMAJ`)  
Scope: NTE2027, NTE2028, NTE2029 and NTE2030

## Outcome

Every current primary NTE Lead and active NTE Opportunity was independently classified against the Master Panel predicates and the Home dashboard calculations. No placement, event-isolation, conversion-mapping, relationship or Home arithmetic mismatch remains in the current data.

The reported PA18 problem was an unstable pagination boundary caused by records sharing the same `LastModifiedDate`. The controller now sorts by `LastModifiedDate DESC, Id DESC` and applies the same record-ID tie-breaker after combining rows. PA18 is now the first record in both the combined Applications queue and the partner/sponsor refinement.

## Population and relationship checks

- Event-coded Leads: 239
- Primary form Leads: 235
- Deliberately retained supplementary update Leads: 4 (1 Heavy Vehicle Details, 3 Staff Details Update)
- Active NTE Opportunities: 81
- Converted application Leads: 61
- Direct POA E2E Opportunities without a source Lead: 20
- Opportunity Contact Roles: 81
- Distinct related Accounts: 62
- Distinct primary Contacts: 62

All 61 converted application Leads have one exact Opportunity match by booking reference, event code and source form type. All 81 Opportunities have an Account and exactly one primary Contact Role; every primary Contact belongs to the Opportunity Account.

The shared, clearly labelled POA test Account and Contact were marked as NTE participants so the NTE Account and Contact list views now cover all 62 related Accounts and all 62 related Contacts. No client record was changed for that correction.

## Master Panel reconciliation

| Event | Interest | Applications | Guests | Approved | Finance | Updates | Completed |
|---|---:|---:|---:|---:|---:|---:|---:|
| NTE2027 | 28 | 63 | 41 | 62 | 60 | 26 | 12 |
| NTE2028 | 3 | 4 | 2 | 5 | 5 | 4 | 1 |
| NTE2029 | 4 | 6 | 4 | 6 | 5 | 4 | 2 |
| NTE2030 | 6 | 7 | 6 | 8 | 7 | 5 | 2 |
| **Global** | **41** | **80** | **53** | **81** | **77** | **39** | **17** |

Every primary Lead and Opportunity matched its expected combined queue, subtype and refiner. All 17 completed bookings are excluded from every applicable finance, heavy-vehicle and staff outstanding predicate.

## Home reconciliation

| Event | Applications | Confirmed Applications | Invoiced | Still to collect | Paid |
|---|---|---|---|---|---|
| NTE2027 | 63 / £229,439 | 62 / £450,971.95 | 18 / £149,237.60 | 46 / £312,604.95 | 14 / £138,367 |
| NTE2028 | 4 / £49,299 | 5 / £8,899 | 3 / £6,400 | 3 / £3,099 | 2 / £5,800 |
| NTE2029 | 6 / £54,300 | 6 / £11,648 | 3 / £7,799 | 3 / £5,149 | 2 / £6,499 |
| NTE2030 | 7 / £60,748 | 8 / £19,748.50 | 3 / £11,100 | 5 / £9,448.50 | 2 / £10,300 |

For every event:

- exhibitor and partner/sponsor subtype values sum to the displayed pipeline totals;
- booking mix equals open commercial applications plus approved Opportunities;
- revenue readiness is mutually exclusive;
- paid plus still-to-collect value equals confirmed known-price value;
- converted source Leads are represented by their Opportunities and are not double-counted.

## Fixes deployed during this audit

1. Stable Master Panel pagination with an ID tie-breaker.
2. Regression coverage for 31 same-timestamp application records crossing a page boundary.
3. Automatic Master Panel and Home refresh when the page regains focus or visibility.
4. Request sequencing so overlapping refreshes cannot replace newer results with stale responses.
5. Conversion-window close monitoring followed by a Master Panel refresh.
6. `FOR UPDATE` locking when confirming a price-on-request total.
7. Invoice list-view filtering aligned to the actionable invoice queue by excluding unresolved required quotes.
8. Heavy-vehicle list-view filtering aligned to the logistics queue by including blank and `Not known yet` declarations.
9. Lead queue list views aligned to the Master Panel by excluding converted Leads from interest, application and guest work queues.

Validation/deployment evidence:

- Pagination controller deployment: `0AfAd00000SZzEzKAL` (22/22 tests)
- List-view deployment: `0AfAd00000SZyduKAD`
- Final controller and dashboard deployment: `0AfAd00000SZzenKAD` (22/22 tests; 96.4% controller coverage)
- Lead queue list-view deployment: `0AfAd00000Sa01NKAR`
- Local form test suite: passed
- `NTERelatedOpportunityControllerTest`: 7/7 passed (`707Ad00001OdHQX`)

## Current semantic decisions requiring confirmation

These are not current placement errors.

1. **Invoice lifecycle versus actionable queue.** Event Breakdown counts every uninvoiced billable booking. The invoice refiner intentionally excludes bookings still blocked by an outstanding required quote. For example, NTE2030 has 4 uninvoiced bookings: 2 awaiting quotes and 2 ready for invoicing. The current drill-down therefore shows 2 actionable records. The interface should eventually state this distinction or use a three-part breakdown.
2. **Logo is an independent task.** Every current Opportunity has Logo Provided = false, including completed bookings. Logo submission is not currently a completion gate. Decide whether that is intentional before changing completion rules.
3. **Recent is a record feed.** It can show both the converted Lead and resulting Opportunity; it is not a unique-submission count.

## Current data notes

- Three older test Opportunities have different `Amount` and `NTE_Listed_Price_Total__c` values. New agreed-price confirmations write both fields consistently:
  - `006Ad00000To0gvIAB`: £2,998.55 vs £3,000
  - `006Ad00000TkpN5IAJ`: £100,000 vs £800
  - `006Ad00000TkpN9IAJ`: £100,000 vs £3,000
- The open-pipeline report sums raw listed components for price-on-request records. That number must not be presented as confirmed pipeline value; Home correctly excludes unresolved price-on-request values.
- No successful live Logo Update submission exists yet, so the positive removal-from-Logo-Due route is covered by Apex tests but not by a retained live example.

## Future architectural limits

No architectural changes were made for these items.

1. Master Panel offset pagination is capped at 1,950 and row retrieval at 2,000. Cursor pagination is required before a single event approaches that volume.
2. NTE Account/Contact related components use a 200-record limit without pagination or a truncation warning. Current maximum is 20 and is safe.
3. Global list-view and report links do not inherit the selected event, time or owner filters.
4. Time filtering is based on record creation time, not milestone activity time.
5. Manual/imported NTE Opportunities contribute when their NTE fields are valid, but imports must also mark their Account and Contact as NTE participants for list-view visibility.
6. User-mode results depend on record sharing and field access. Permission and sharing changes must be regression-tested with a standard NTE user.

## Safety

No records were deleted. Only the two clearly labelled shared POA test participant flags were updated. Deployments were scoped to the components listed above.
