# NTE manual Stripe setup and qualification plan

Updated 8 September 2026. Internal working plan for the project owner and Mission Community.

**Selected route:** automatic creation of the correct Stripe payment request and provisional email, followed by **manual payment verification and recording in Salesforce**. The existing space-confirmation email follows that staff action. Automatic payment confirmation is not selected.

**Selected product, later 8 September:** Stripe Payment Links only. Do not use Stripe Invoicing or enable optional post-payment invoice creation. The client will confirm VAT and the remaining configuration; its separate invoice process still needs to be specified.

**Current dependency:** the owner confirmed that the client still needs to grant Stripe access. No Stripe sandbox, key, payment request or payment has been created or inspected for this project. The existing Salesforce MMUAT environment is Enterprise Edition, as verified in the [read-only feasibility evidence](audit/NTE_STRIPE_FEASIBILITY_2026-09-08.json). This packet defines the setup and test work; its cases are planned, not execution results.

The [earlier architecture plan](NTE_STRIPE_IMPLEMENTATION_PLAN_2026-09-08.md) remains the detailed reference for request identity, email sequencing, financial snapshots and recovery. Its automatic-route material is retained as an alternative, not current build scope. Proposal **11** remains the stable change number.

## 1. Environment to request from the client

Use **a dedicated general Stripe sandbox under the client's intended merchant account**, named for example `NTE Salesforce UAT`, connected to the existing Salesforce `mission-mmuat` sandbox and controlled test inboxes.

The client's Stripe administrator should:

1. Open the Stripe Dashboard account picker, then **Switch to sandbox → Create sandbox**.
2. Choose **Copy your account** for the correct merchant and give the sandbox an identifiable NTE name.
3. Open that sandbox and use **Settings → Team and security → Add member** to invite the owner's chosen Stripe login email. Give sufficient access within that sandbox to inspect payments/API logs and manage the required test configuration/keys. The admin can retain key creation if preferred.
4. Keep access specific to this sandbox. Live-payment access is not needed for this build. A Sandbox User role that only permits creating personal sandboxes is not a substitute for access to the existing shared NTE sandbox; verify the exact invitation and role.
5. Confirm the sandbox name/account identity and client finance contact. These non-secret identifiers can be recorded in the project.

Stripe documents sandbox creation and sandbox-specific invitations without access to live payment data. [Create a sandbox](https://docs.stripe.com/sandboxes/dashboard/manage), [manage access](https://docs.stripe.com/sandboxes/dashboard/manage-access).

Use a dedicated general sandbox because Stripe's built-in test-mode sandbox shares some settings with live mode. General sandboxes isolate configuration. [Testing environment comparison](https://docs.stripe.com/testing-use-cases).

**Copying is a starting point.** Stripe copies supported settings/capabilities, uses placeholder business data and does not keep the copy synchronized. Some domains/automations are excluded, and payment methods can be enabled for testing even when only pending live. Compare the chosen configuration rather than assuming copying proves parity. [Copy behaviour and exclusions](https://docs.stripe.com/sandboxes/dashboard/sandbox-settings).

If access takes time, local development and mocked tests can progress. An unrelated or anonymous Stripe sandbox can prove API mechanics but cannot certify the client's merchant configuration. Do not present it as the final client-equivalent environment.

## 2. What the owner/client supplies, and what Codex can do

| Work | Owner/client responsibility | Codex contribution |
| --- | --- | --- |
| Stripe ownership/access | Create the client-owned sandbox, invite the owner and complete any login/MFA | Inspect the granted environment, verify identity and document its configuration once accessible |
| Secure credentials | An authorised admin creates/installs a restricted sandbox API key | Specify resource permissions, configure the Salesforce credential definitions and test the callout without exposing secrets |
| Finance rules | Confirm seller, VAT treatment, invoice issuer, GBP/currency presentation and payment terms | Turn confirmed rules into saved line/net/tax/gross calculations and independently checked expected amounts |
| Remaining workflow decisions | Decide quote/PO clearance, P03 conversion policy, top-up scope/order, cancellation and P01 retry recovery | Prepare concrete options, implement chosen behaviour and prove preservation/rollback with synthetic records |
| Applicant/payment experience | Confirm branding, support details, payer receipt choice and finance recipients | Implement request creation, existing-email payment button, statuses, exact booking mapping, safe retries and manual payment evidence |
| Test recipients | Identify controlled applicant, Primary Contact and internal test inboxes | Build a recipient registry, run authorised synthetic journeys, inspect actual Salesforce emails and preserve evidence |
| Qualification | Client finance performs the final staff walkthrough and approves business results | Build automated tests, run sandbox journeys/failure cases, fix defects, maintain a results ledger and produce the release candidate |
| Production | Client enables/owns live merchant configuration; project owner authorises release separately | Compare settings, deploy the same qualified code, map live resources, verify readiness and document rollback/operations |

For the selected straightforward manual route, Salesforce can call Stripe directly through a Named Credential and External Credential. A webhook receiver, external queue/hosting and incoming Salesforce External Client App are not prerequisites. An on-demand Check Stripe aid can be scoped later without changing the human decision; it is not silently added by selecting manual confirmation. [Salesforce Named Credentials](https://developer.salesforce.com/docs/platform/named-credentials/guide/get-started.html).

## 3. Secure connection setup

Create a separate restricted sandbox key for this integration. Permissions should cover the necessary payment-link/price/product operations, plus read operations for identity and request verification. Invoice-creation permissions are not needed. Do not grant live payout/refund capabilities to the request-creation integration. Test-refund simulation can use a separately authorised sandbox operator.

Store the key in Salesforce's protected External Credential configuration, associated with the appropriate Named Credential. The owner/admin should enter sensitive values directly into the secured setup or another agreed secret store. **Do not paste keys into chat or send them by ordinary email.** A publishable key cannot create the server-side payment requests and is not needed in the static application forms for this hosted-payment design. [Stripe API keys](https://docs.stripe.com/keys).

The same Stripe API serves sandbox and live requests according to credentials/context; a Salesforce sandbox does not automatically make an external Stripe call safe. Use explicit environment/account binding, a test-only configuration and an authenticated read-only preflight before any mutation. Verify returned resources have the expected non-live mode before allowing a payment email. Qualify the precise preflight endpoint and restricted-key permissions during setup. Test wrong/live-mode responses with mocks, never by putting a live key into MMUAT to see what happens.

In addition to the Stripe boundary, pin the Salesforce test org, event and exact synthetic booking/recipient scope. The existing public preview still submits to MMUAT; make new Stripe activation apply only to the intended test fixtures while qualification is under way. Existing paid/unpaid audit records must not become a historical Stripe backfill.

## 4. Configuration agreement before claiming client equivalence

| Setting | How to establish the test baseline | What changes for production |
| --- | --- | --- |
| Merchant and country | Client's copied sandbox; verify its exact identity and account context | Verified live account, separately approved credentials/capabilities |
| Payment product | Dedicated Payment Links; optional post-payment invoice creation disabled | Same product/options; create/map live resources; retain separate finance invoice process |
| Prices and tax | Same agreed catalogue and saved net/tax/gross rules; synthetic organisations | Same policy/version; genuine approved bookings only |
| Currency and methods | GBP integration currency; explicitly selected cards/card wallets or other approved methods; review local-currency presentation | Recheck methods actually enabled live; pending/test availability is not evidence of live enablement |
| Branding, seller and support | Agreed logo, public name, receipt/invoice details and support destination; review placeholders | Verified live business information and actual support destinations |
| Quote/invoice documents | Same numbering policy, fields and PO rules; distinct test records | Live numbering and accounting ownership; no test numbers/objects copied as real invoices |
| API contract | Pin tested API version, exact request options, permissions and response validation | Same version/options; account-specific IDs/configuration |
| Salesforce code | One versioned source/generator/manifest and normal production code path | Deploy the exact qualified revision; no separate payment algorithm |
| People and email | Synthetic Contacts and explicitly controlled recipients; real Salesforce rendered emails | Actual sender/domain, staff permissions and agreed recipients |
| Finance operation | Staff check exact Stripe payment and record the correct charge | Same manual action, evidence and division of responsibility |

Maintain this comparison when configuration changes, and once again immediately before release. Stripe objects and keys are environment-specific; copying a Product/Price/customer ID from test into live does not make it usable there. [Environment-specific resources](https://docs.stripe.com/keys).

A mechanical connection proof can use an explicitly documented example price/tax fixture while finance decisions are pending. That proves transport and matching, not the client's final commercial calculation. Final acceptance must use the confirmed policy.

## 5. Exact behaviour the test implementation must demonstrate

Application with Stripe selected → staff conversion → saved charge → create/recover and verify Stripe request → existing provisional email with matching payment button → applicant pays a Stripe test payment → **Salesforce remains unpaid/provisional until staff verify and record it** → one existing space-confirmation email.

Store the booking/charge/request reference, amount, currency and request identity. The staff action should retain payment evidence/reference and recorder/time, with the actual Stripe paid time separate where collected. Staff verify full successful payment under the correct merchant and request; a click, receipt screenshot, pending payment or bank payout estimate is insufficient evidence.

The original booking and the single permitted staff top-up remain separate. The top-up must not clear booking payment, change its accepted amount or send another space confirmation. Existing quote/invoice-before-payment and booking-before-top-up rules remain unless expressly changed. The normal provisional email retains staff, vehicle, logo and agreement details. Paid space remains distinct from Completed and Final pack sent.

Use durable operation IDs and idempotent Stripe requests so retries recover the same request. Do not send a Stripe email until the link and complete amount are verified. A failed email reuses the saved payment request. Native Salesforce merge output and plain text must match the client preview. [Idempotent Stripe operations](https://docs.stripe.com/api/idempotent_requests).

## 6. Qualification sequence and evidence

| Phase | Work | Evidence required to advance |
| --- | --- | --- |
| 0. Access/configuration | Client creates sandbox; secure key and recipient registry; choose financial product/policy | Non-secret configuration record, exact test scope, successful authenticated read-only preflight |
| 1. Focused integration proof | One fresh exhibitor and one partner/sponsor booking; real Stripe sandbox calls and actual Salesforce emails | Exact Lead/Opportunity/request/payment IDs; correct saved/email/checkout gross amount; manual payment action and one confirmation |
| 2. Implementation qualification | Request persistence, email gating, manual evidence, retry/recovery and chosen policy guards | Meaningful local/Apex tests; actual sandbox failures/recovery; no orphaned or unexplained requests |
| 3. Extended journeys | Pricing variants, contact identities, top-up, mobile/payment behaviour and chosen finance policies | Case-by-case results with real sandbox/browser/inbox evidence identified separately from mocked results |
| 4. Volume and race testing | Local/Apex mocks for large volume; small bounded real overlaps in Salesforce/Stripe | No duplicate requests/confirmations or cross-booking changes; measured limits and known untested dimensions |
| 5. Client operations walkthrough | Finance staff locate Stripe payment, reject pending/wrong evidence, confirm booking, recover failed email and reconcile totals | Reviewed business acceptance and runbook usable by the actual operators |
| 6. Release qualification | Run required project validation, actual MMUAT deployment and full manifest check-only; compare source hashes; refresh relevant preview | Exact release revision and configuration; all required cases resolved; canonical preview verified |

Use fresh synthetic records and a persistent run ledger. Each row records case ID, source revision, configuration fingerprint, expected result, observed result, exact record/request IDs, evidence path and status. Resolve uncertain outcomes by querying the known identity; never repeat a submission because a browser or query timed out. Mark related evidence as related rather than relabelling it as exact-case coverage.

Take baseline snapshots of the existing protected records and include preservation checks for the records the new scope could affect. Do not restart the completed stress audit, replay successful old emails or mass-reprice existing bookings. Separate source/unit checks, mocked callouts, actual Stripe sandbox transactions, real inbox receipts and genuine concurrency in the final report. Inject nondeterministic provider errors such as 429/5xx with mocks or an explicitly identified test transport; do not provoke a Stripe outage or rate limit. Record injected faults separately from actual provider behaviour, then qualify the recovery against the known real sandbox request where applicable.

**Extensive testing does not mean high-volume traffic to Stripe.** Use configurable callout mocks with varied timing/errors for load tests. Stripe discourages load-testing its sandbox API because limits and gateway latency differ from live behaviour. Small, controlled real integration/race tests are a separate layer. [Stripe load-testing guidance](https://docs.stripe.com/rate-limits#load-testing).

## 7. Initial test catalogue — all planned

`A` = local/Apex tests, including HTTP mocks. `I` = actual MMUAT and Stripe sandbox integration. `B` = actual browser or inbox observation. `O` = operational/configuration review. A combined label requires evidence for each listed layer. This is a catalogue of **60 scenarios**, not a claim of 60 executed tests or exhaustive coverage. Variants expand after the product and policy decisions.

| ID | Scenario and required outcome | Layer |
| --- | --- | --- |
| MS01 | Stripe application receipt says under review and contains no payment/preparation link | A/I/B |
| MS02 | Fresh exhibitor conversion creates the exact request and complete provisional email | A/I/B |
| MS03 | Fresh partner/sponsor conversion follows the same sequence with correct package wording | A/I/B |
| MS04 | Rejected/unconverted application creates no request | A/I |
| MS05 | Bank-transfer route retains its existing finance and email behaviour | A/I/B |
| MS06 | Genuinely complimentary booking receives immediate confirmation and no charge | A/I/B |
| MS07 | GBP net, tax, gross and integer minor units reconcile to independent expectations | A/I |
| MS08 | Pence values and line-versus-total rounding follow the agreed tax policy | A/I |
| MS09 | Space, original staff and power itemisation reconcile without omitted/double charges | A/I/B |
| MS10 | Multiple sponsor packages reconcile with their saved total | A/I/B |
| MS11 | Allowed category discounts apply correctly; category does not invent VAT exemption | A/I |
| MS12 | Missing/removed/tampered pricing is held without an unpriced/free payment email | A/I |
| MS13 | Price changes after queueing make the old revision ineligible to send | A/I |
| MS14 | Existing Account/Contact reused for a new booking retains correct separate payment identity | A/I |
| MS15 | Existing/no-booking native/API conversion follows the chosen P03 guard and full rollback | A/I/O |
| MS16 | Similar names, duplicate emails/references and different event years cannot rematch a payment | A/I |
| MS17 | Repeat queueing/retry uses one logical payment request | A/I |
| MS18 | Two workers/staff acting concurrently cannot create two active requests | A/I |
| MS19 | Timeout after Stripe creation recovers the same remote request | A/I |
| MS20 | Salesforce save failure after remote creation leaves recoverable, identifiable work | A/I |
| MS21 | Old ambiguous operation beyond idempotency retention is reconciled before a replacement | A/O |
| MS22 | Injected API 429/5xx errors back off, stop sensibly and expose actionable work; real sandbox recovery is recorded separately | A/I |
| MS23 | Missing/revoked/underprivileged key fails without an incomplete email | A/I |
| MS24 | Wrong sandbox/account or mocked live response is refused before collection/send | A/I/O |
| MS25 | Ordinary successful test card payment produces correct Stripe evidence | I/B |
| MS26 | Decline/insufficient-funds test leaves booking unpaid | I/B |
| MS27 | 3D Secure success completes payment; abandonment/failure does not | I/B |
| MS28 | Browser closes after payment; staff still find the exact successful transaction | I/B |
| MS29 | Forwarded link/different payer still refers to original booking and preserves Contact data | A/I/B |
| MS30 | Reopening a paid link does not invite another normal payment | I/B |
| MS31 | Two already-open tabs or parallel payment attempts cannot silently create an overpayment | A/I/B |
| MS32 | Expired/deactivated/replaced request has truthful recovery and no wrong charge | A/I/B |
| MS33 | Selected phone browsers, card wallets and foreign-currency presentation match policy | I/B/O |
| MS34 | Delayed/partial/credit/out-of-band payment is not mistaken for full Stripe payment; mark inapplicable only when proven disabled | A/I/O |
| MS35 | Successful Stripe payment alone leaves Salesforce payment flag false and sends no space confirmation | A/I/B |
| MS36 | Staff verify exact full payment and record it; evidence and correct person/time retained | A/I/B |
| MS37 | Double-click, refresh and two staff confirmations generate one booking confirmation | A/I/B |
| MS38 | Wrong/pending/refunded evidence cannot be accepted through any implemented verification guard; staff runbook demonstrates refusal where verification is manual | A/I/O |
| MS39 | Existing authorised staff can record payment; credential access is limited to the intended integration principal without changing the accepted internal access model | A/I/O |
| MS40 | Separate Primary, event and billing contacts route the NTE email only to Primary | A/I/B |
| MS41 | Missing/multiple/changed Primary Contact fails safely and recovers without silent fallback | A/I/B |
| MS42 | Email failure before payment reuses its existing request on eligible retry | A/I/B |
| MS43 | Email failure after recorded payment preserves the payment and permits one confirmation retry | A/I/B |
| MS44 | Actual native HTML/plain-text amount, greeting, multiline details and button are correct | A/I/B |
| MS45 | No duplicate invoice email or unwanted recipient; classify Stripe test receipts separately | I/B/O |
| MS46 | First valid positive staff top-up has its own amount/request without altering base charge | A/I/B |
| MS47 | Names-only correction preserves top-up price/request/payment history | A/I |
| MS48 | Second increase/duplicate positive submission remains rejected under the one-top-up rule | A/I |
| MS49 | Top-up before base payment follows the selected order policy; real payment evidence is retained | A/I/O |
| MS50 | Top-up after base paid/pack sent preserves original confirmation and pack history | A/I/B |
| MS51 | Required quote/PO/agreement cases follow the selected issuance policy | A/I/O |
| MS52 | Cancellation/payment-method switch closes or safely holds earlier collection; existing preparation behaviour preserved | A/I/O |
| MS53 | Payment during replacement/cancellation becomes visible finance work; no automatic reinstatement/refund | A/I/O |
| MS54 | Paid-booking provisional retry follows selected P01 recovery, without a new payment demand | A/I/B/O |
| MS55 | Simulated refund/dispute preserves payment history and is handled by the named finance owner | I/O |
| MS56 | Home, Master Panel and finance reports reconcile base/top-up net/gross/tax without counting fees as unpaid booking money | A/I/B |
| MS57 | Large mocked batches respect callout/job/email budgets and isolate failures | A |
| MS58 | Bounded real overlap and failed-job recovery leave no unexplained pending/orphaned request | I/O |
| MS59 | Release switch, configuration drift, secret rotation and live-ID mapping are reviewable and recoverable | A/I/O |
| MS60 | Qualified source/manifest/preview hashes and protected-record snapshots match final evidence | A/I/B/O |

MS15/MS49/MS51–54 depend on unselected business policies. Keep them blocked by a named decision rather than writing tests that silently approve a recommendation. Tests must distinguish an enforced software guard from an operator instruction; the manual choice does not imply Stripe is automatically rechecked by Salesforce.

Use Stripe's documented test payment values for successful, declined and authentication cases; do not use real card details. Product-specific refund/dispute simulations are fake-money scenarios. [Stripe test scenarios](https://docs.stripe.com/testing).

## 8. Email and production differences we must explicitly qualify

Salesforce MMUAT can send actual NTE emails to the agreed controlled inboxes, so we can inspect real merge output and follow the real sandbox payment link. Preserve the strict Primary Contact routing and separately inventory internal recipients.

Stripe does **not automatically email customers in sandboxes by default**. Its documentation provides manual test invoice/receipt paths and recipient conditions. Therefore, a successful test payment with no automatic Stripe receipt is not automatically an integration failure; record the actual sender and mechanism. A manually sent Stripe receipt proves its content/delivery path, not live automatic triggering. [Sandbox email behaviour](https://docs.stripe.com/testing-use-cases#test-email), [test receipts](https://docs.stripe.com/receipts#test-receipts).

Test the actual selected email-client/browser combinations rather than claiming a browser preview proves Outlook or a physical phone. Leave untested physical devices/mail clients explicitly identified. Stripe sandbox payments do not traverse real card networks, so they cannot establish live issuer decisions, production fraud outcomes, actual payout settlement or the client's live fee contract. [Sandbox isolation](https://docs.stripe.com/sandboxes).

The target is **the same qualified application code and agreed configuration, with documented environment substitutions**. Absolute equivalence or a promise of perfection would hide real differences. Production readiness includes live account/capability, bank, sender/domain and configuration checks; after authorised launch, reconcile the first genuine business transaction under the normal flow. Do not use test cards in live mode or create artificial live transactions as an extension of this stress test.

## 9. Release gate and handover

Advance only when all release-required cases have exact evidence, no unresolved blocker can misroute or misstate money, the selected finance policies are signed off, and client finance can execute the manual workflow/recovery. Record every accepted limitation and why it is outside the release scope. A test count or code-coverage percentage alone is not sign-off.

Follow [the package synchronization rules](PRODUCTION_PACKAGE_SYNC.md): update source, generator and manifest together; validate; deploy the same changes to MMUAT; run the full manifest check-only with RunLocalTests and compare hashes. The existing 281-test result is a baseline, not proof of this integration. Approved form/email-preview changes must also be published to the existing canonical forms repository and verified; public examples use non-payable example links.

Promote the same qualified revision. Install the live credential separately and create/verify the needed live Stripe objects, expected merchant, permissions, receipt settings and financial policy. Production forms must point to the production Salesforce org/field IDs, and sender/ownership settings must be checked there. An environment change is more than swapping an API key.

Document how to retry failed creation versus failed email, find a Stripe payment by exact request, record base versus top-up payment, handle a duplicate/late payment, reconcile totals and escalate refunds/disputes. Assign a daily finance owner and cover. No payment-notification email is a substitute for checking the Dashboard when notifications are missing.

The release switch must stop new requests/emails without erasing records. Already-sent Stripe links need separate treatment during rollback; disabling Salesforce code does not necessarily close them. Preserve original payment and email history throughout.

## 10. Immediate client request — draft only

Please create a dedicated Stripe sandbox for the NTE Salesforce integration using **Copy your account**, and invite me to that specific sandbox with access to its payment records, API logs and required test configuration. Sandbox-only access is sufficient; I do not need access to live payments for this work. An authorised administrator can create the restricted test API key, which we will install securely in the Salesforce sandbox.

We will use Payment Links without Stripe Invoicing. Please confirm the separate formal-invoice process, applicable VAT treatment, intended payment methods/currency, and which finance staff should receive payment notifications. We will use fake payments and controlled inboxes to test the complete application, conversion, payment-link and manual-confirmation journey before a separate production release.

This is a draft for the owner to adapt/send; no message has been sent to the client.

## Current checkpoint

- Manual payment confirmation selected by the owner; automatic confirmation and its incoming infrastructure are outside this chosen route.
- Client Stripe access awaited. Payment Links is selected; tax, the separate invoice process, remaining P03/P01 and top-up/cancellation rules stay explicitly undecided.
- Setup responsibilities, configuration comparison, phased qualification and 60 proposed scenarios prepared.
- No implementation, Stripe call, new business-system mutation, new email, deployment or public-site publication performed in preparing this packet. Preparation can continue locally while access is arranged; connected proof depends on the client sandbox and secure credential.
