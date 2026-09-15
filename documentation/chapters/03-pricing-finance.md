# Pricing and finance rules

The catalogue version is NTE27-2026-09-13-VAT. Package and item prices remain GBP excluding VAT. Apply 20% VAT to the net booking subtotal after discounts, rounded once to the nearest penny. Opportunity Amount, confirmed value, Home, panel and report payable totals include VAT; reports also retain explicit net and VAT columns. The payment request stores the same net and gross amounts in pence. NTEPricingService is authoritative; assets/forms.js mirrors its catalogue for immediate estimates. The form's exact option values, metadata picklists and Apex allowlists must agree. A label containing a price is a selection key, not a string from which the server parses an amount.

## Initial booking calculation

Partner / sponsor applications sum the distinct selected Sponsor_Package__c values, separated by semicolons. Empty, duplicate, removed or unknown selections require review. Planned staff must be a whole number from 1 to 99. Partner staff and power do not add prices in this catalogue. All selected package prices are combined into Sponsor_Package_Total__c and Listed_Price_Total__c.

Exhibitor applications select exactly one known Exhibitor_Space_Selections__c and a recognised active Exhibitor_Organisation_Category__c. Restricted spaces require their exact eligible category. A double garage or double zone includes four staff; every other current space includes two. Planned staff is a whole number from 1 to 99. Additional staff equals max(0, planned minus included), at £50 per person. Planned count entered on the form is authoritative over submitted hidden derived totals.

Power required Yes requires a whole socket count from 1 to 20. Each additional socket is £100, or £50 for the five exact qualifying categories. No clears chargeable socket quantity/value for pricing, even if a stale submitted socket count exists. A garage selection described as including power still permits additional sockets; the website explains that distinction. The base garage price already includes its stated standard power provision.

Exhibitor total = space price + socket quantity × socket unit price + additional staff quantity × £50. Sponsor package total is zero on an exhibitor result; exhibitor, power and additional-staff components are zero on a partner result. Unit prices are zero where the corresponding charge is not applicable. Invoice Required is Yes for a positive calculated total, otherwise No. Unsupported or incomplete input produces Review required instead of a fabricated free booking.

[CATALOGUE]

## Saved conversion price

The conversion operation recalculates from the current application's selections and planned count immediately before copying. priceApplicationsForConversion returns one ConversionPricingResponse per requested Lead in the same order and makes no Lead DML. The Flow copies the returned component totals, status, version, included/initial/total staff and invoice requirement, and copies the VAT rate and sets Opportunity.Amount to the returned total including VAT. The original application Lead's saved older estimate can consequently differ from the converted booking when the catalogue or application selections changed before approval.

NTE_Initial_Staff_Count__c captures the number originally purchased, including included and initial additional staff. NTE_Included_Staff_Count__c records the package allowance; NTE_Additional_Staff_Count__c is the initially charged excess. NTE_Total_Staff_Count__c becomes the current total after supplementary updates. These are different quantities and must not be collapsed into one field.

recalculateLeads and recalculateOpportunities are maintenance methods. They persist recalculated values using partial-save DML. Opportunity recalculation prefers the saved initial count, falls back to planned text if necessary, and fills Total Staff only if it is blank. These methods are not an automatic repricing trigger. Applying them to historical bookings changes their financial snapshot and requires an explicitly scoped migration.

## Complimentary bookings and worked examples

| Scenario | Calculation | Result |
| --- | --- | --- |
| Single track-side garage, two staff, no additional power | £799 space + £0 power + £0 additional staff | £799 net + £159.80 VAT = £958.80 including VAT. |
| Double zone at £849, six staff, one standard-rate socket | £849 + £100 + (6 − 4) × £50 | £1,049 net + £209.80 VAT = £1,258.80 including VAT; four staff included and two initially chargeable. |
| Eligible local-government single space, three staff, one discounted socket | £249.50 + £50 + (3 − 2) × £50 | £349.50 net + £69.90 VAT = £419.40 including VAT. Discounts apply before VAT. |
| Eligible COBSEO charity free space, two staff, no power | £0 + £0 + £0 | £0 net + £0 VAT = £0 total. Complimentary confirmation on conversion; preparation still required. |
| Same charity, three staff and one socket | £0 + £50 + £50 | £100 net + £20 VAT = £120 including VAT. Paid provisional workflow applies to the extras. |
| Premier Partner plus Zone Sponsor | £7,000 + £5,000 | £12,000 net + £2,400 VAT = £14,400 including VAT. Partner roster updates do not add staff charges. |
| Later exhibitor top-up of three places | 3 × £50 | Separate £150 net + £30 VAT = £180 top-up. Original booking amount and base payment remain unchanged. |

Only the exact COBSEO and non-COBSEO charity category/free-space pairings qualify for immediate complimentary confirmation, and only with Calculated status and total zero. A zero or missing value in another configuration is not sufficient. Payment-confirmation rendering also verifies saved itemisation: each priced line must have a valid whole quantity/unit/total relationship, components must be nonnegative, totals must agree, and a populated Opportunity.Amount must match the gross base booking total.

The client confirmed 20% VAT on all payable NTE prices on 13 September. config/nte-pricing.json is the versioned policy authority, generated into NTEVat and the browser calculation. Application VAT fields are calculated server-side; caller-supplied derived values cannot override them. Saved booking and top-up rates preserve accepted financial facts. The form shows one aggregate VAT amount and the gross total, and the 50% space/power saving includes the corresponding VAT saving. Invalid pricing retains no payable gross total.

## Staff top-up invariants

The first valid positive exhibitor top-up fixes the additional purchased quantity. Its names can be corrected later, including within a repeated submission, but its quantity cannot be increased or reduced through the public update path. A No answer on a later form preserves an existing positive purchase. Initial and top-up rosters are concatenated with newlines; the combined stored list cannot exceed 32,768 characters. Each individual count is limited to 99, so the current implementation can hold up to 198 combined initial-plus-top-up attendees when both component counts are valid.

Only the first positive top-up sets Top Up Invoice Required, unit price, net total and its own saved VAT rate, and resets the separate top-up invoice/payment flags and stamps. Correcting names preserves those finance facts. The initial booking price, invoice and payment never become the top-up fields. Partner staff updates replace the final roster and headcount without creating a top-up price. They do not enforce package-specific staffing allowances beyond the general count rules.

## Finance predicates

| Predicate | Exact business rule |
| --- | --- |
| Known pricing | Listed total is nonblank and nonnegative, with status Calculated; or legacy blank status with a strictly positive listed total. Blank-status zero, negative, missing or non-Calculated pricing requires review. |
| Base billable | Invoice Required is Yes, or listed total is positive, or pricing requires review. The last condition keeps unknown amounts in visible finance work. |
| Top-up billable | Top Up Invoice Required is true or top-up total is positive. |
| Quote resolved | Quote Required for PO is not Yes, or Quote Provided is true. |
| Invoice required view | Pricing review, or a resolved quote plus an outstanding base/top-up invoice. |
| Payment required view | Known pricing and either base invoice provided with base payment outstanding, or completed/not-applicable base payment plus provided top-up invoice with top-up payment outstanding. |
| Payment confirmed view | Known pricing, at least one billable charge, and all applicable invoices and payments recorded. A free booking is not a paid booking. |
| Completed | Known pricing; quote resolved; all applicable finance complete; staff timestamp populated; logo flag true; logistics No or Yes with a completion timestamp. |

The controller uses both in-memory predicates and matching SOQL clauses for rows/counts. Native list views use NTE_Pricing_Ready__c, NTE_Finance_Invoice_Due__c, NTE_Finance_Payment_Due__c and NTE_Finance_Payment_Confirmed__c formula fields to keep their filters within native list-view limits. Their complete formulas are in the field reference. NTE_Confirmed_Value__c represents known base plus top-up committed value, not payment received; use payment flags and paid-value calculations for collections.

## Stripe booking contract

NTEStripeBookingService selects supported positive-net Stripe bookings when the Default configuration is enabled and any optional reference scope matches. It binds the request to the exact Salesforce organisation, Stripe merchant and test/live environment. Existing saved requests remain subject to those checks even when ordinary scope filters later change. A booking outside the enabled selection follows the existing manual provisional route when no saved Stripe request exists.

The charge key is OrgId:OpportunityId:Booking. Charge_Key__c is a unique external ID. The saved request records the source Lead ID, booking reference, Primary Contact recipient, net minor units, tax rate, gross minor units, GBP currency, merchant, environment and a fingerprint of the relevant source/configuration. Description is NTE booking · followed by the booking reference. Source or recipient changes can invalidate that snapshot; the code does not silently mutate an already issued amount.

Gross = net + round(net × tax rate ÷ 100, 2), using HALF_UP rounding. Minor units are integer pence. The HTTP client validates a positive amount with no more than two decimal places, minimum 30 pence and maximum 99,999,999 pence. It pins Stripe API version 2026-08-26.dahlia and uses a 20-second callout timeout.

| Call | Request and verification |
| --- | --- |
| GET /v1/account and GET /v1/balance | Verify expected merchant and live/test mode before creation. Live mode additionally requires charges_enabled. |
| POST /v1/prices | Currency gbp, fixed gross unit_amount, tax_behavior=inclusive, product_data[name]=saved description, and operation/reference/kind metadata. Idempotency key is the saved operation key plus :price. |
| POST /v1/payment_links | Exactly one verified Price, quantity one, card method, no adjustable quantity, promotion codes, automatic tax or Stripe invoice creation. Billing address collection auto; customer creation if_required; completed sessions limited to one. Booking metadata and saved net/VAT minor units plus rate are copied onto the link and PaymentIntent. custom_text[submit][message] displays the net subtotal, aggregate VAT and gross total, which verifyLink checks before email eligibility. Idempotency key ends :link. |
| GET /v1/payment_links/{id} and its line_items | Verify mode, active status, allowed URL, all fixed settings, metadata, one line item, quantity, Price identity/currency and exact subtotal/total before emailing. |

Payment URLs must be HTTPS on buy.stripe.com with the expected test_ or live path form and no query, fragment, userinfo or alternate port. A saved Ready link must have been verified within five minutes and still match the booking before email. A new ambiguous creation attempt older than 23 hours is held for review rather than risk creating another link outside the recovery window. Each chained worker processes one request, then resumes the corresponding booking email and remaining batch.

The low-level Stripe client recognises Booking and Staff top-up charge kinds, but the released coordinator creates Booking requests only. Public staff top-ups use the manual Salesforce finance milestones; they do not automatically create another Stripe link. There is no webhook updating payment, refund or dispute state in Salesforce. Link completion, Stripe receipts and payouts must be reconciled operationally. Turning off the integration or setting Closed Lost does not deactivate an already issued Stripe link.

VAT is configured in config/nte-pricing.json and built into Salesforce and the form calculator together. Leads retain VAT_Rate__c, VAT_Total__c and Total_Including_VAT__c; bookings retain NTE_VAT_Rate__c with formula net/VAT/gross totals. The first accepted staff top-up captures its own rate; names-only corrections preserve it. Base and top-up VAT are rounded separately because they are separate charges. Stripe automatic tax remains disabled so VAT is not added again. Invalid pricing has no payable gross total.
