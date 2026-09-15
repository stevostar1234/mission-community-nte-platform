# Official Stripe app for Salesforce — architecture assessment

**14 September workflow update:** use the later approved manual request-release, 20% VAT, new-Opportunity and manual joining-instructions rules when implementing an app-based candidate. This assessment's earlier conversion-time sequence and dated implementation totals are historical. The current meeting brief also highlights that automatic payment confirmation needs verified handling for staff-adjusted bookings. [Meeting questions](../NTE_CLIENT_MEETING_QUESTIONS_2026-09-14.md), [current workflow](../NTE_DESIRED_WORKFLOW.md).

Assessed 13 September 2026 against the current NTE source and official Stripe documentation. The owner confirmed the exact [Stripe, Inc. AppExchange listing](https://appexchange.salesforce.com/appxListingDetail?listingId=4dff0f8e-0b10-47c2-a3a3-f3905e7f7927). This is a proposed architecture assessment, not approval to install, migrate, remove metadata or activate payments. Native read-only inspection found four installed MMUAT packages and no Stripe package.

## Recommendation

**Later owner clarification:** the architect specifically proposes Flow-led generation and optional automatic payment updates. The [Flow migration decision brief](NTE_STRIPE_FLOW_MIGRATION_DECISION_2026-09-13.md) assesses that broader replacement, identifies inconsistent reference guidance about zero-custom-Apex inputs, and provides a staged estimate. Its recommendation for the stated Flow-maintenance preference supplements the narrower transport-adapter option below. No migration or automatic-confirmation approval is inferred.

Run a focused sandbox proof of concept using the official app as the Stripe connection behind the existing NTE booking services. Adoption is reasonable if it preserves the existing Payment Links contract and gives the client a useful managed connection or payment-event visibility. The present one-off/manual-confirmation workflow alone does not make a package migration necessary. The app is an integration builder, so NTE-specific orchestration, financial validation, recipient selection and email handling still need maintaining. [Stripe overview](https://docs.stripe.com/use-stripe-apps/stripe-app-for-salesforce/overview).

Do not discard the existing integration before that proof. A second viable option is to keep outbound link creation as implemented and use the app only for incoming payment events. That offers a narrower initial change, but retains the custom outbound client and two integration configurations. Choose one responsible path for each operation; do not run two link generators or confirmation senders.

The latest recorded NTE baseline is the 11 September live-readiness release: 474 components / 314 tests / 538 canonical hashes. Live mode is already supported through separate credentials and explicit merchant/environment checks. This assessment does not revert to the older test-only assumptions, and those test results do not qualify the proposed app integration.

## Can the same workflow work?

Yes. Stripe's own action catalogue contains create, retrieve, list-line-items and update Payment Link actions. Its raw API adapter also documents an explicit API version, custom idempotency key and raw JSON responses. Therefore preserving actual Stripe Payment Links is a documented route, without making Stripe invoices part of the workflow. [Official action reference](https://github.com/stripe/salesforce-connector-examples/blob/main/context/invocable-actions-reference.md#paymentlinks), [official adapter reference](https://github.com/stripe/salesforce-connector-examples/blob/main/context/Stripe-Salesforce-Platform-Architecture.md).

The proposed sequence is:

1. Applicant chooses Stripe on the existing exhibitor or partner/sponsor application.
2. The existing conversion process supplies the exact converted Opportunity and Primary Contact.
3. NTE saves the booking-specific payment request, approved amount and retry identity.
4. The adapter asks the app to create the Price and Payment Link, then reads them back through the app and performs the existing verification.
5. Only after successful verification does the existing provisional-allocation email include the saved link.
6. The applicant pays on Stripe. Receipts and selected team notifications follow the agreed configuration.
7. Optionally, the app records provider payment facts for staff to review in Salesforce.
8. Mission Community deliberately records payment received. The current NTE confirmation service sends its one confirmation.

A provider-success field is different from `NTE_Payment_Received__c`. Event synchronization must not silently complete that manual milestone, send another booking confirmation, or turn refunds/disputes into automatic cancellation decisions. Exact Opportunity/charge matching remains essential when the same Account or Contact participates in several years.

## What stays, changes and could later retire

| Current component | Proposed treatment |
| --- | --- |
| Public forms, Lead fields and application receipts | Keep. Stripe remains a payment-method choice. |
| Conversion flow, Opportunity/Account/Contact model, NTE Management and Master Panel | Keep. Preserve the exact converted booking and existing business stages. |
| `NTE_Payment_Request__c` and its existing rows | Keep as the NTE charge snapshot, request identity and dispatch/recovery history. Optional app/provider-status references can be added separately. The app's synced objects do not automatically replace this purpose. |
| `NTEStripeBookingService` | Keep its business logic, asynchronous queue, consistency checks and recovery. Adapt connection selection only where needed. |
| `NTEStripeClient` | Refactor its HTTP/authentication transport to use the package. Retain the amount, merchant, mode, URL, Price, Link, metadata and single-use verification contract. Most of this class is protection and validation, not just HTTP plumbing. |
| Approval/confirmation email services, templates and dispatch history | Keep. Preserve verified link insertion, saved paid totals, exact Primary Contact and one accepted confirmation. |
| `NTE_Stripe_Config__mdt` | Retain NTE enablement, expected merchant/org, mode and financial settings. Add an explicit reference/mapping to the app's Salesforce Stripe Account record. Its Salesforce record ID is different from the provider's `acct_...` ID. |
| `NTE_Stripe_Test` / `NTE_Stripe_Live` credentials | Leave available during migration/rollback. Retire only when no active request or component needs the direct transport and removal is separately reviewed. The app is configured with its own account credentials. |
| Stripe operator permissions and `NTE_Management_Access` | Amend to grant the necessary app access; preserve existing NTE user assignments and operational permissions. |
| Tests, deployment scripts and package manifest | Add app-integration tests and record exact managed-package/API-extension prerequisites. Install those versions before NTE code that references them in each target org. Do not copy Stripe's managed implementation into our package. |

Installation itself should not require deleting NTE fields. Stripe's package uses the `stripeGC` namespace and the inspected NTE source has no existing package references. This is not a guarantee that installation has no effects: review global security settings, permission grants, data mappings and activated automation. Full billing sync should start disabled so default customer/billing mappings do not create or modify unrelated CRM records.

## Setup and migration steps

1. Use a separate development sandbox if available. Capture the current metadata/configuration and pending requests, preserve completed test journeys, and agree which new fixtures may be used. If MMUAT must be used, scope the trial to dedicated records without replacing the ordinary generator immediately.
2. Install the official app for administrators initially, check Lightning Web Security compatibility, complete the authorization wizard and configure the Stripe sandbox connection with its publishable key and appropriately restricted key. Install the required API extension. Billing/CPQ/subscription extensions are optional for different use cases and are not needed for the proposed NTE Payment Links route. [Installation guide](https://docs.stripe.com/use-stripe-apps/stripe-app-for-salesforce/installation-guide).
3. Inspect the installed action/parameter signatures. Build one transport adapter that preserves the current request body, merchant/mode checks, API version and stable operation keys. Complete the source changes and tests in an isolated candidate.
4. Choose whether payment-event visibility is wanted. The app can create webhook endpoints and store events in `stripeGC__Stripe_Event__c`. Subscribe only to agreed event categories and map relevant records deliberately. Filter NTE metadata before business updates, and configure access, retention, duplicate-event handling and alert ownership. An event-type subscription may still ingest non-NTE events from a shared merchant account. [Event configuration](https://docs.stripe.com/use-stripe-apps/stripe-app-for-salesforce/configure-events).
5. Prove both booking routes and the failure/retry cases below. Compare the generated Stripe resources and actual rendered emails with the current contract. Keep the manual-payment action in control of confirmation.
6. Switch new requests to the qualified adapter. Preserve existing links and request histories; reconcile pending/uncertain outcomes before routing them differently. Do not recreate historical Prices/links, reuse a fresh random retry identity, or generate a second request merely because the transport changed.
7. Update deployment prerequisites and rollback instructions. Install/configure the app independently in production, then validate the exact NTE candidate against those package versions and complete the separately authorized client/live release. Sandbox credentials, connection records and test resource IDs do not become production resources by copying them.

Stripe specifically instructs configuring its app separately in each Salesforce org and excluding its connection/configuration records from sandbox cloning. Its configuration documentation also describes transaction tracking, API-extension upgrade effects and log-retention controls. [Configuration guide](https://docs.stripe.com/use-stripe-apps/stripe-app-for-salesforce/configuration).

## Technical gates before adopting it

- **API version and historical retries:** NTE currently pins `2026-08-26.dahlia`; the documented packaged API extension targets `2025-04-30.basil`. The documented raw adapter can set the version per call. Verify this in the installed version and retain the current version where possible. NTE includes the API version in its source fingerprint: changing the constant globally can hold existing requests for review. Any version transition needs explicit handling for already-saved requests.
- **Stable retry keys:** pass the existing operation key and the `:price` / `:link` suffixes explicitly. Automatically generated keys or a new Flow interview ID on retry do not provide the existing cross-retry guarantee. Do not fall back to another generator automatically after an uncertain outcome.
- **Salesforce transaction boundaries:** NTE makes several API calls before saving the verified result. Package logging/sync may save records between calls. Verify the installed controls for deferring DML and flushing logs so later callouts remain valid. Keep generation asynchronous after conversion commits.
- **Financial and payment-link parity:** verify saved GBP amount, tax policy, one-time Price, one completed-session limit, disabled quantity adjustment, disabled promotion codes, disabled automatic tax under the current fixed-rate setup, disabled invoice creation, metadata on the Link and PaymentIntent, exact hosted URL and expected merchant/environment. Client-approved policy changes remain separate.
- **Provider facts versus staff decision:** imported success/refund/dispute facts must not overwrite manual confirmation or silently reverse previous accounting. Completion alone is not sufficient for asynchronous payment methods; validate the selected event and actual payment state if such methods are introduced.
- **Permissions and data ownership:** qualify Kate's standard-user route as well as administrator access. Retain the Primary Contact recipient rule. Leave broad billing/customer sync disabled unless specifically mapped and approved.
- **Upgrades and deployment:** pin and document package/API-extension versions, test upgrades, and requalify source that depends on the managed namespace. Salesforce automation/storage/API limits still apply.

Minimum proof: exhibitor and partner conversion/link/email; Account/Contact reuse with a different Opportunity; repeat conversion/queue/retry; timeout after Price or Link creation; failed email with saved-link reuse; wrong merchant/mode/amount; repeated click after completed checkout; payment success with no automatic NTE confirmation followed by exactly one manual confirmation; duplicate/delayed events if enabled; existing issued-link continuity; actual standard-user access. Use new explicitly allocated fixtures and never replay the preserved completed payment/refund ledgers.

## Cost and choice

The official AppExchange listing currently shows **US$1 per company as a one-time payment**, and notes nonprofit discounts. It directs readers to Stripe pricing. Confirm current commercial terms with Stripe; that listing amount is not a statement that processing, other optional products or implementation work are free. [Listing and pricing details](https://appexchange.salesforce.com/appxListingDetail?listingId=4dff0f8e-0b10-47c2-a3a3-f3905e7f7927).

The practical choice is between retaining the proven focused connection, adding the app only for events, or adopting the app behind the existing NTE services. The recommended next decision is a bounded app-backed transport proof with optional event visibility; wholesale replacement of the booking system is unnecessary. Installation, migration and event-driven behavior remain unapproved at this assessment checkpoint.

Private source/reference captures and the read-only installed-package inventory are retained under `tmp/nte-stripe-app-review-20260913`. No integration code, Salesforce metadata, provider setting, booking/payment record or public page was changed during this review.
