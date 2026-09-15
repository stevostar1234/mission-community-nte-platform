# NTE Stripe app and Flow migration — decision brief

**14 September workflow update:** the later approved manual-finance and reconciliation releases supersede this assessment's conversion-time generation and historical-price confirmation assumptions. Conversion is silent; staff release booking/top-up requests from Requirements. VAT is confirmed at 20%, each conversion must create a new Opportunity, joining instructions are manual, and adjusted-booking receipt confirmation relies on deliberate staff reconciliation. Apply the architecture analysis to that current workflow, with new automatic-payment exception checks if approved; re-estimate against the current implementation before commitment. [Current meeting brief](../NTE_CLIENT_MEETING_QUESTIONS_2026-09-14.md), [authoritative workflow](../NTE_DESIRED_WORKFLOW.md). The original assessment below is dated design evidence, not a replacement for those later decisions.

Assessed 13 September 2026. This supplements the [initial app assessment](NTE_STRIPE_SALESFORCE_APP_ASSESSMENT_2026-09-13.md) after the owner clarified that the architect proposes generating links in Salesforce Flows and using the official app's listener for optional automatic payment updates. This is a feasibility assessment and estimate, not approval to install, replace code or enable automatic confirmation. The selected operational workflow remains manual confirmation.

## Recommendation and reasons for the client

Prefer the official Stripe app with Flows controlling the payment workflow if the client wants its Salesforce team to maintain that workflow and expects incoming payment updates. Permit a small, tested Apex action where complex parameters or concurrency require it. Do not retain the bespoke Stripe transport simply because it has already been written. Equally, do not promise a completely custom-Apex-free implementation before testing the installed package.

There is no documented Payment Links capability gap that categorically requires the existing integration. Stripe documents Payment Link creation/retrieval/update actions, general API access, and event-triggered Flows. The NTE rules still need to be configured or implemented; the app is an integration builder rather than an out-of-the-box NTE booking application. [Stripe overview](https://docs.stripe.com/use-stripe-apps/stripe-app-for-salesforce/overview), [Payment Links action reference](https://github.com/stripe/salesforce-connector-examples/blob/main/context/invocable-actions-reference.md#paymentlinks).

The strongest reason to retain the current route is delivery certainty: it already has recorded qualification against the selected manual workflow. A replacement inherits the specification and reusable tests, not their passing results. If the client only needs manual confirmation and prioritises the shortest release path, retaining it is reasonable. The app is not better in every dimension; it adds a managed dependency, deployment setup and operational monitoring, while reducing responsibility for integration infrastructure and making suitable business rules visible in Flow.

Suggested client explanation:

> We recommend the official Stripe app with Salesforce Flows because it provides a managed Stripe connection and payment-event listener, and lets the Salesforce team maintain the workflow. We will preserve the existing booking references, payment history, email templates and controls against incorrect or duplicate requests. Before switching, we will prove both application routes and the failure/recovery cases in a sandbox. A small Salesforce code helper may still be appropriate; the aim is a maintainable, tested integration.

## Listener and automatic confirmation are separate decisions

The app configures a hosted webhook endpoint and stores incoming Stripe events in Salesforce, where record-triggered Flows can process them. No separately hosted NTE HTTP worker is required for that route. [Stripe event configuration](https://docs.stripe.com/use-stripe-apps/stripe-app-for-salesforce/configure-events).

The current implementation also has no external HTTP worker: it makes outbound calls from Salesforce Apex and uses manual payment confirmation. Adopting the app adds a managed incoming-event route. That route could receive events for links created by the existing outbound implementation too; using the listener does not technically require replacing link generation. A full switch is justified by the client's Flow-maintenance preference, rather than by an artificial dependency between the two directions.

Preserve two explicit concepts:

- **Provider payment facts:** exact Stripe payment, amount, currency, merchant, test/live mode, success/refund/dispute state and processing evidence.
- **NTE booking confirmation:** the business decision that records the booking milestone and sends its confirmation email.

Under the currently selected manual route, events update provider facts and staff retain the confirmation action. If automatic confirmation is subsequently approved, validated eligible success can invoke the same booking-confirmation operation. Refund/dispute events should retain distinct financial states and flag exceptions; automatic refunds, cancellations or reversal of the original payment history are not implied.

Current source makes this distinction material: `NTE_MasterPanelController` explicitly calls `NTEEmailDispatchService.queueBookingConfirmation` after its payment action. Simply setting `NTE_Payment_Received__c` in a new Flow is not equivalent to that action. The automated route must integrate the audit fields, eligibility and one accepted confirmation while leaving a failed notification recoverable without undoing payment.

## Proposed Flow responsibilities

| Responsibility | Proposed behaviour |
| --- | --- |
| Request preparation | After the existing conversion/copy has completed, use its explicit Opportunity ID and Primary Contact. Save the approved charge and a durable unique request identity. Reuse the current payment-request object initially. |
| Link generation | In an asynchronous transaction, call the app to create the fixed Price and Payment Link. Preserve the current amount/tax policy, disabled invoice creation, fixed quantity, metadata and completed-session limit. Save provider IDs and verify the result before making it eligible for email. |
| Provisional email | Route the ready request into the existing NTE email service with the same recipient, rendered amount and payment button. Prevent the current generator and the new Flow from both handling a request. |
| Incoming payments | Process selected app events. Resolve the exact saved request using provider IDs and immutable request metadata, merchant and mode. Validate payment state and amount. Do not select the latest Opportunity for a Contact/Account. |
| Confirmation | Manual by default. If separately approved, eligible provider success invokes an audited, repeat-safe confirmation operation. Never equate link creation, checkout opening or an unverified event with a paid booking. |
| Recovery | Persist failures, attempt IDs and processing outcomes. Allow reviewed retry/reconciliation without creating a replacement link or repeating a successful email. Provide an actionable exception view and an owner for failed work. |

## Can this be entirely Flow and packaged actions?

The business workflow is feasible with the app and Flow orchestration. Whether every required input and safeguard can be implemented cleanly with only packaged actions is not yet proven in MMUAT, where the app is not installed.

The official reference requires a list of nested line-item objects for Payment Link creation and nested objects for metadata, invoice settings and restrictions. Stripe's reference notes warn about source-deploying some generated model types as Flow variables and propose small Apex helpers. However, other passages in those same notes show the supposedly unsupported variable pattern, and Salesforce's general Flow documentation supports appropriately defined Apex types. This is inconsistent reference guidance, not a confirmed universal Salesforce prohibition. An installed-package deployment and runtime test must settle it. [Stripe Flow notes](https://github.com/stripe/salesforce-connector-examples/blob/main/context/rules/flow-builder.mdc), [Salesforce Apex-defined type considerations](https://help.salesforce.com/s/articleView?id=sf.flow_considerations_apex_data_type.htm&language=en_US&type=5).

Stripe's working example also combines a Flow with a custom `CreateCheckoutSessionAction` helper. That demonstrates a supported architectural pattern; it is a Checkout Session example, not a drop-in Payment Links implementation and not a proposal to change our selected Stripe product. [Official Flow example](https://github.com/stripe/salesforce-connector-examples/blob/main/examples/force-app/main/default/flows/Create_Checkout_Session_from_Opportunity.flow-meta.xml), [helper example](https://github.com/stripe/salesforce-connector-examples/blob/main/examples/force-app/main/default/classes/CreateCheckoutSessionAction.cls).

The generic packaged action accepts a URL-encoded request and explicit API version, but returns raw JSON. It supplies another route through the official connection; constructing and validating complex payloads in text formulas is not automatically easier to maintain than a small typed helper. Preserve that as an option rather than claim it proves a clean zero-custom-code solution. [Official adapter reference](https://github.com/stripe/salesforce-connector-examples/blob/main/context/Stripe-Salesforce-Platform-Architecture.md).

## Safeguards and migration gates

1. **Stable creation and recovery:** retain the saved charge key and operation-specific retry keys across different Flow runs. A fresh Flow interview ID is not equivalent. Stripe can prune idempotency keys after at least 24 hours; preserve the existing conservative hold for an uncertain old creation rather than blindly creating another link. [Stripe idempotency](https://docs.stripe.com/api/idempotent_requests).
2. **Concurrent changes:** recheck the booking, recipient and saved charge when accepting a result and sending. The current code deliberately locks and rereads records after callouts. Flows do not offer all of Apex's transaction controls, so prove the replacement using unique records, state transitions and, where justified, a small locking/validation action. Neither approach creates an atomic transaction across Salesforce and Stripe. [Salesforce architecture guidance](https://architect.salesforce.com/docs/architect/decision-guides/guide/record-triggered).
3. **Callout ordering:** preserve after-commit execution and handle package log writes between multiple API calls. Verify the installed deferred-save action parameters. The app remains subject to Salesforce transaction limits. [Stripe configuration](https://docs.stripe.com/use-stripe-apps/stripe-app-for-salesforce/configuration), [Salesforce transaction-control guidance](https://help.salesforce.com/s/articleView?id=005167102&language=en_US&type=1).
4. **API compatibility:** existing requests pin `2026-08-26.dahlia`; the documented typed extension targets `2025-04-30.basil`. Either qualify a deliberate new-request version transition while retaining legacy retry handling, or use the app's version-capable action. Do not alter old request fingerprints or claim current tests qualify another API schema.
5. **Event correctness and recovery:** Stripe can repeat events and deliver them out of order. Record processing identity and ensure repeat delivery cannot repeat the booking action. Verify what happens when the listener accepts an event but a Salesforce Flow later fails; endpoint delivery is not proof of a completed NTE update. Reconcile stalled requests and unprocessed events. [Stripe event delivery](https://docs.stripe.com/webhooks#event-delivery-behaviors).
6. **Payment semantics:** the current method selection is card only. If delayed methods are enabled later, completion of Checkout is not sufficient proof of successful payment. Pending/failed events must not mark paid. Recheck current provider state when handling late success after a refund/dispute, and keep those exception states distinct. [Stripe fulfilment guidance](https://docs.stripe.com/checkout/fulfillment).
7. **Installation and operations:** qualify package access for standard users as well as administrators, subscribe to needed events, protect provider-event data and configure retention. Broad billing sync should remain disabled unless deliberately mapped. A shared Stripe merchant can generate unrelated events, so filter before NTE changes. Install/configure each Salesforce environment independently and record managed-package prerequisites. [Stripe configuration](https://docs.stripe.com/use-stripe-apps/stripe-app-for-salesforce/configuration).
8. **Existing business decisions:** P03 existing-Opportunity conversion, P01 provisional retry after confirmation and changed-price/cancelled-booking payment exceptions are not resolved by installing the app. Keep them separate from the architecture decision and qualify the applicable rules before automatic confirmation is activated.

## What can be retired

Once the candidate is proven, the custom direct HTTP path in `NTEStripeClient` and the link-generation queue/orchestration in `NTEStripeBookingService` can be retired or replaced. Preserve their safeguards in the new implementation. Shared email-readiness, saved-total and URL checks currently reference these classes, so those consumers must be refactored before deleting them. Update `build-stripe.js`, `build-stripe-bookings.js`, permissions, tests and manifests so obsolete components are not regenerated.

Keep the public forms, NTE apps, converted Opportunities, Primary Contact rule, payment-request data, existing issued links and email history. The business snapshot may keep its present object or move under a separately reviewed data migration; using the app does not require deleting it. No historic link should be reissued merely because the implementation changed. Retire old credentials only when dependencies and pending requests are resolved.

The safest transition is a separate test candidate followed by one active generator for new requests. Capture pending work at cutover, reconcile uncertain outcomes and preserve their original identity. Keeping a rollback route does not mean automatically falling back to it after an ambiguous API response.

## Planning estimate

These are engineering-effort allowances, not observed implementation times, a fixed quote, or a promise of autonomous work between sessions. Access, package installation eligibility and client decisions are prerequisites. Reuse existing forms, pricing and email services; allow small helpers where needed.

| Stage | Indicative effort |
| --- | --- |
| Install/configure an isolated candidate; prove Flow inputs, one Payment Link and one incoming payment event | 1–2 working days |
| Migrate both application routes, saved-request/retry safeguards and email handoff; add provider-status processing with manual confirmation | 2–3 further days |
| Extended failure/concurrency/access tests, existing-link continuity, release rehearsal and handover | 2–3 further days |
| Optional automatic booking confirmation with its audit, duplicate-event and exception tests | 1–3 additional days after the policy is approved |

Thus allow **5–8 working days for the Flow-led route with payment visibility and manual confirmation**, or **6–11 working days including automatic confirmation**. Production/client acceptance waiting time is additional. Strictly forbidding any custom Apex, substantially rewriting the existing email services, unexpected package limitations or expanding refund/top-up automation requires a revised estimate. Re-estimate after the first proof; no honest fixed completion promise is possible before it.

Minimum acceptance covers both participant types; exact new-year Opportunity matching; normal, declined, abandoned and recovered payments; duplicate creation and event delivery; wrong amount/currency/merchant/mode; a charge change during generation; timeout after a provider resource exists; failed email without reissuing a link; delayed/unprocessed events; refund/dispute visibility without unintended confirmation; standard-user operation; old-link continuity; and one accepted confirmation under each approved mode. Use new approved fixtures and preserve all completed payment/refund/send ledgers.

Only internal documentation and read-only public-reference captures changed in this follow-up. No managed package was installed, and no source code, Salesforce configuration, payment or email was changed.
