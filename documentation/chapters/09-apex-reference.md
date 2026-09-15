# Apex class and method reference

The twelve implementation classes contain 301 extracted methods and constructors, including inner queue workers and DTO constructors. Every entry identifies its source signature/line and project purpose. Overloads remain separate. The accompanying archive contains the exact bodies; the runtime chapter explains cross-class orchestration and transaction boundaries. Standard library calls are not separately catalogued.

## VAT additions — 13 September 2026

The detailed method tables below originate from the 12 September manual; their line numbers refer to that dated archive. Current VAT source is identified by the [13 September qualification](../../audit/NTE_VAT_QUALIFICATION_2026-09-13.json). The following contract additions supersede the earlier monetary descriptions.

- NTEVat (force-app/main/default/classes/NTEVat.cls) supplies RATE=20, rate(savedRate), tax(net, savedRate) and gross(net, savedRate). A saved rate takes precedence; missing net stays null. VAT uses HALF_UP rounding to two decimal places once per base booking or separate top-up.
- NTEPricingService writes authoritative Lead VAT/gross fields and uses gross Opportunity Amount. Conversion freshly recalculates and copies the rate and total. NTEUpdateSubmissionService captures the first top-up rate and preserves it with the accepted quantity/price.
- NTEStripeClient.Charge now includes netMinor and vatRate. validateCharge checks net plus calculated VAT against gross; vatMessage creates the aggregate checkout disclosure. Link and PaymentIntent metadata retain net/VAT/rate; verifyLink validates those fields and disclosure before email use.
- NTEExhibitorApprovalEmailService and NTEEmailDispatchService load the saved rate and render net/VAT/gross totals for all payment methods, with gross amount checks. NTE_MasterPanelController uses gross actionable and summary values.

## NTEBookingContactService

public inherited sharing class NTEBookingContactService {. Source: force-app/main/default/classes/NTEBookingContactService.cls.


| Method signature | Purpose and behaviour |
| --- | --- |
| public static Map<Id, Contact> primaryContacts(Set<Id> bookingIds, AccessLevel accessLevel)<br>Source line 2 | Loads roles and Contacts for the supplied booking IDs in the requested USER_MODE or SYSTEM_MODE. The overload optionally locks them. Returns a Contact only for a booking with exactly one Primary role; it never chooses an event-day contact or arbitrary role as fallback. |
| public static Map<Id, Contact> primaryContacts(Set<Id> bookingIds, AccessLevel accessLevel, Boolean lockRecords)<br>Source line 8 | Loads roles and Contacts for the supplied booking IDs in the requested USER_MODE or SYSTEM_MODE. The overload optionally locks them. Returns a Contact only for a booking with exactly one Primary role; it never chooses an event-day contact or arbitrary role as fallback. |
| private static Map<Id, Id> singlePrimaryContactIds(List<OpportunityContactRole> roles)<br>Source line 31 | Indexes Primary roles by Opportunity. A second Primary role makes that booking ambiguous and removes it from the usable result. |



## NTEEmailDispatchService

public with sharing class NTEEmailDispatchService {. Source: force-app/main/default/classes/NTEEmailDispatchService.cls.

Public data contracts: Selection.recordId: Id; Selection.fingerprint: String; DraftRequest.kind: String; DraftRequest.runId: String; DraftRequest.subject: String; DraftRequest.messageBody: String; DraftRequest.recipients: List<Selection>; RecipientDTO.recordId: Id; RecipientDTO.name: String; RecipientDTO.company: String; RecipientDTO.email: String; RecipientDTO.reference: String; RecipientDTO.eventCode: String; RecipientDTO.link: String; RecipientDTO.eligible: Boolean; RecipientDTO.issue: String; RecipientDTO.fingerprint: String; RecipientDTO.lastSentAt: Datetime; RecipientDTO.previewHtml: String; DraftDTO.kind: String; DraftDTO.runId: String; DraftDTO.title: String; DraftDTO.subject: String; DraftDTO.messageBody: String; DraftDTO.previewHtml: String; DraftDTO.recipients: List<RecipientDTO>; DraftDTO.recipientCount: Integer; DraftDTO.skippedCount: Integer; DraftDTO.recipientLimit: Integer; DraftDTO.canSend: Boolean; QueueResponse.queuedCount: Integer; QueueResponse.skippedCount: Integer; QueueResponse.message: String; HistoryDTO.dispatchId: Id; HistoryDTO.recordId: Id; HistoryDTO.kind: String; HistoryDTO.recipient: String; HistoryDTO.status: String; HistoryDTO.subject: String; HistoryDTO.sentAt: Datetime; HistoryDTO.createdAt: Datetime; HistoryDTO.error: String; HistoryDTO.runId: String; HistoryDTO.canRetry: Boolean.


| Method signature | Purpose and behaviour |
| --- | --- |
| public static DraftDTO buildDraft(String kind, List<Id> recordIds)<br>Source line 80 | Builds a kind-specific editable subject/body and recipient eligibility snapshot for exactly the requested IDs. Does not render every recipient HTML or send messages. |
| public static String previewMessageJson(String requestJson, Id recordId)<br>Source line 105 | Strict JSON boundary that deserialises and validates a browser draft then returns one selected recipient preview. |
| public static String queueMessagesJson(String requestJson)<br>Source line 110 | Strict JSON boundary that validates a browser draft and serialises the queued/skipped response. |
| public static String previewMessage(DraftRequest request, Id recordId)<br>Source line 115 | Revalidates the selected recipient/fingerprint, personalises subject/body and returns that recipient HTML without creating dispatches. |
| public static QueueResponse queueMessages(DraftRequest request)<br>Source line 127 | Locks/reloads the exact selection, checks fingerprints and aggregate payload limits, persists unique dispatch rows, queues the saved IDs and returns accepted queue counts. |
| private static NTE_Email_Dispatch__c dispatchForRequest(DraftRequest request, RecipientDTO recipient)<br>Source line 158 | Creates a dispatch snapshot with the kind/run/record key, original recipient, reviewed content, personalised content and fingerprint. |
| private static void validateQueueSize(DraftRequest request, List<RecipientDTO> recipients)<br>Source line 170 | Checks combined raw, personalised and escaped HTML size before retaining a full bulk payload. Individually legal messages can still exceed the aggregate budget. |
| public static QueueResponse queueBookingConfirmation(Id opportunityId)<br>Source line 204 | Creates or reuses the unique first-base-payment confirmation dispatch. This automatic message has fixed project rendering and cannot be sent through the editable mass composer. |
| public static QueueResponse retryDispatch(Id dispatchId)<br>Source line 235 | Convenience entry point for the record action; delegates one failed dispatch ID to the same retry mechanism. |
| public static List<HistoryDTO> recentDispatches(List<Id> recordIds)<br>Source line 242 | Returns up to 1000 recent dispatch history DTOs for the selected source records, including outcome, recipient and retry information. |
| public static QueueResponse retryFailed(List<Id> dispatchIds)<br>Source line 266 | Reuses only Failed dispatches with their existing identities. Rechecks current eligibility/recipient/fingerprint; paid-confirmation recovery deliberately rebuilds its current valid primary-recipient presentation. |
| private static void enqueue(List<Id> dispatchIds)<br>Source line 334 | Schedules a worker only for the saved dispatch ID list; queue failure is converted into a truthful persisted failure outcome. |
| DispatchQueueable(List<Id> dispatchIds, Boolean bypassDelivery)<br>Source line 345 | Stores saved dispatch IDs and the controlled delivery-bypass flag for a worker page. |
| public void execute(QueueableContext context)<br>Source line 346 | The Queueable overload attaches its finalizer and processes a page; the Finalizer overload marks still-queued rows failed after an unexpected worker exception. Their parameter types distinguish the paths. |
| DispatchFinalizer(List<Id> dispatchIds)<br>Source line 360 | Captures the exact dispatch IDs whose pending state must be recovered after worker failure. |
| public void execute(FinalizerContext context)<br>Source line 361 | The Queueable overload attaches its finalizer and processes a page; the Finalizer overload marks still-queued rows failed after an unexpected worker exception. Their parameter types distinguish the paths. |
| private static void processQueued(List<Id> dispatchIds, Boolean bypassDelivery)<br>Source line 369 | Locks queued rows, reloads recipients and verifies unchanged reviewed facts, renders validated messages, sends bounded groups, maps individual outcomes, synchronises source status and chains remaining saved IDs. |
| private static void failQueued(List<Id> dispatchIds, String error)<br>Source line 483 | Marks only still-Queued target dispatches Failed with a bounded reason and updates related source status where applicable. |
| private static List<RecipientDTO> loadRecipients(String kind, List<Id> recordIds, Boolean lockRecords, Set<Id> allowedQueuedIds)<br>Source line 497 | Kind-specific query and eligibility engine for invitations, staff/vehicle/logo reminders, final packs and paid confirmations. Uses one Primary Contact for booking mail, validates route links/references and explains every exclusion. |
| private static void updateSourceStatuses(List<NTE_Email_Dispatch__c> dispatches, AccessLevel accessLevel)<br>Source line 626 | Synchronises invitation progression and final-pack state from dispatch outcomes. Sent history is preserved; reminder sends do not mark preparation complete. |
| private static Map<Id, RecipientDTO> recipientMap(List<RecipientDTO> recipients)<br>Source line 683 | Indexes recipient DTOs by target record ID for exact selection and outcome lookup. |
| private static Boolean sameRecipient(NTE_Email_Dispatch__c dispatch, RecipientDTO recipient)<br>Source line 688 | Compares the saved recipient association/address/fingerprint with the freshly loaded recipient to stop an old reviewed email reaching changed details. |
| private static Id targetId(NTE_Email_Dispatch__c dispatch)<br>Source line 692 | Returns the Lead or Opportunity target from a dispatch row. |
| private static String normalizeKind(String kind)<br>Source line 695 | Restricts the requested communication type to the implemented allowlist. |
| private static List<Id> validateIds(List<Id> recordIds, String kind)<br>Source line 700 | Enforces permitted object IDs, nonempty bounded selections and duplicate handling for the selected kind. |
| private static DraftRequest parseRequestJson(String requestJson)<br>Source line 716 | Rejects malformed, unknown-field or oversized JSON before strict DraftRequest deserialisation. |
| private static Map<Id, String> validateRequest(DraftRequest request)<br>Source line 730 | Validates run identity, subject/body lengths, token/content rules, selected IDs and required fingerprints for the reviewed draft. |
| private static String fingerprint(String kind, RecipientDTO recipient)<br>Source line 750 | Hashes kind plus recipient/booking/route facts that must remain unchanged between review and delivery. |
| private static String dispatchKey(String kind, String runId, Id recordId)<br>Source line 754 | Builds the stable SHA256 key from kind, run and target. Payment confirmation uses its fixed booking-payment run identity. |
| private static String hash(String value)<br>Source line 757 | Returns the SHA256 digest used for snapshot and idempotency identities. |
| private static String route(String kind, String sourceType, NTE_Routing_Config__mdt routing)<br>Source line 758 | Resolves application, staff, vehicle, logo or final-pack URL by kind and participant type from the Default routing metadata. |
| private static NTE_Routing_Config__mdt configuredRouting()<br>Source line 767 | Returns the current Default routing record or the injected test configuration. |
| private static Boolean validLink(String value)<br>Source line 770 | Validates configured HTTPS destinations before preview/queue/delivery. |
| private static String titleFor(String kind)<br>Source line 777 | Returns the kind-specific default composer title, subject or plain-text message. Personalisation occurs later against the selected recipient. |
| private static String subjectFor(String kind)<br>Source line 784 | Returns the kind-specific default composer title, subject or plain-text message. Personalisation occurs later against the selected recipient. |
| private static String bodyFor(String kind)<br>Source line 791 | Returns the kind-specific default composer title, subject or plain-text message. Personalisation occurs later against the selected recipient. |
| private static String personalise(String template, RecipientDTO recipient)<br>Source line 800 | Replaces the supported greeting, organisation, booking reference, event and route tokens in one pass; token-looking recipient values remain literal. |
| private static String normaliseLines(String text)<br>Source line 820 | Normalises CRLF/CR to LF for consistent editor and text-alternative handling. |
| private static String personalisedContentIssue(String subject, String body, RecipientDTO recipient)<br>Source line 821 | Rechecks expanded subject/body sizes and content after token expansion, including long recipient values. |
| private static String htmlFor(String kind, String subject, String body, RecipientDTO recipient)<br>Source line 832 | Builds the escaped branded HTML from the personalised plain-text composer content, including the appropriate route action. |
| private static String escape(String value)<br>Source line 875 | Escapes dynamic values for HTML output. |
| private static String emailError(Messaging.SendEmailResult result)<br>Source line 876 | Extracts a useful delivery error from a failed Salesforce send result. |
| private static QueueResponse resultFor(Integer queued, Integer skipped)<br>Source line 879 | Constructs the queue response with queued/skipped counts and operator-facing outcome text. |
| private static AuraHandledException handled(String message)<br>Source line 885 | Creates the AuraHandledException used for a controlled LWC-visible validation error. |



## NTEExhibitorApprovalEmailService

public without sharing class NTEExhibitorApprovalEmailService {. Source: force-app/main/default/classes/NTEExhibitorApprovalEmailService.cls.

Public data contracts: Request.leadId: Id; Request.opportunityId: Id; ApprovalRetryResult.queuedCount: Integer; ApprovalRetryResult.message: String.


| Method signature | Purpose and behaviour |
| --- | --- |
| public static void sendApprovalConfirmation(List<Request> requests)<br>Source line 42 | Invocable conversion entry point. Validates explicit Lead/Opportunity associations, coalesces requests into a saved pending batch and schedules processing after the conversion transaction commits. |
| public static ApprovalRetryResult retryApprovalEmail(Id opportunityId)<br>Source line 69 | User action for one failed booking. Requires an eligible unsent, non-pending booking and its exact converted source application; returns the queue outcome instead of claiming an email was delivered. |
| private static Set<Id> saveRequests(List<Request> requests)<br>Source line 106 | Deduplicates and validates requests, checks prior approval/audit evidence, writes Pending and batch identity on eligible bookings and returns the saved booking IDs. |
| ApprovalQueueable(String key, Boolean bypass, Boolean allowLead)<br>Source line 143 | Stores the batch key and delivery/test-source flags for the asynchronous approval worker. |
| public void execute(QueueableContext context)<br>Source line 146 | Queueable.execute attaches a finalizer and processes the saved batch; ApprovalFinalizer.execute marks only still-pending records in its batch failed after an unhandled worker error. The signature distinguishes the two implementations. |
| public static void resumeAfterStripe(String batchKey, Boolean bypassDelivery, Boolean allowTestLead)<br>Source line 160 | Resumes the same approval batch after payment-link work without generating a new conversion request. |
| public static void finishStripeBooking(Id paymentRequestId, String batchKey, Boolean bypassDelivery, Boolean allowTestLead)<br>Source line 163 | Resumes approval for the exact booking represented by a completed payment request, preserving the original batch identity. |
| ApprovalFinalizer(String key)<br>Source line 169 | Captures the approval batch key used to isolate unexpected-failure recovery. |
| public void execute(FinalizerContext context)<br>Source line 170 | Queueable.execute attaches a finalizer and processes the saved batch; ApprovalFinalizer.execute marks only still-pending records in its batch failed after an unhandled worker error. The signature distinguishes the two implementations. |
| private static void processRequests(List<Request> requests)<br>Source line 177 | Internal/test-facing bridge from explicit Request values into the same saved-request processing path. |
| private static void processPendingBatch(String batchKey, Boolean bypassDelivery, Boolean allowTestLead)<br>Source line 183 | Loads pending bookings for one batch, optionally one subset, validates source association, Primary Contact, saved price, template and preparation settings, coordinates Stripe readiness and sends in bounded pages. Persists individual accepted/failed outcomes and audit Tasks; chains remaining work. |
| private static void processPendingBatch(String batchKey, Boolean bypassDelivery, Boolean allowTestLead, Set<Id> onlyBookingIds)<br>Source line 187 | Loads pending bookings for one batch, optionally one subset, validates source association, Primary Contact, saved price, template and preparation settings, coordinates Stripe readiness and sends in bounded pages. Persists individual accepted/failed outcomes and audit Tasks; chains remaining work. |
| public static Messaging.SingleEmailMessage renderBookingEmail(Opportunity booking, Contact recipient, Id templateId, NTE_Routing_Config__mdt routing, Boolean paymentConfirmation)<br>Source line 320 | Renders the stored Contact/Opportunity template, supplies event/organisation/finance/payment/preparation markers, and builds a readable text alternative. The paymentConfirmation flag selects paid presentation without creating another payment request. |
| private static String replaceTemplateMarkers(String html, Map<String, String> replacements)<br>Source line 358 | Replaces only source-owned HTML comment markers in one pass. Recipient text that resembles a merge token remains literal data. |
| private static String plainTextFromHtml(String html)<br>Source line 376 | Removes layout-only markup while preserving meaningful paragraphs, itemised amounts and usable links. |
| private static String templateFor(Opportunity booking)<br>Source line 395 | Selects the exhibitor or partner provisional/complimentary stored template by saved participant type. |
| public static String savedPriceError(Opportunity booking)<br>Source line 400 | Checks saved status, base amount and itemised component consistency before any booking/paid confirmation. Rejects unknown zero, invalid quantities and participant-incompatible components. |
| private static Boolean validLineItem(String quantity, Decimal unitPrice, Decimal total)<br>Source line 418 | Validates a quantity, unit price and extended total as one internally consistent line. The String overload parses count text; the Decimal overload checks the numeric relationship. |
| private static Boolean validLineItem(Decimal quantity, Decimal unitPrice, Decimal total)<br>Source line 424 | Validates a quantity, unit price and extended total as one internally consistent line. The String overload parses count text; the Decimal overload checks the numeric relationship. |
| public static String paymentConfirmationError(Opportunity booking, NTE_Routing_Config__mdt routing)<br>Source line 430 | Applies the paid-confirmation prerequisites to the saved booking and preparation routing; payment history is not changed by a rendering failure. |
| private static String paymentNote(Opportunity booking, NTE_Payment_Request__c payment)<br>Source line 443 | Chooses provisional, complimentary, manual-payment or Stripe wording from saved booking/request facts. |
| private static String financeSummary(Opportunity booking, NTE_Payment_Request__c payment, Boolean paymentConfirmation)<br>Source line 455 | Builds the participant-specific net component table plus aggregate VAT and gross amounts for every payment method; Stripe uses the verified saved request. Paid presentation omits a new Pay Now request. |
| private static String stripePaymentButton(NTE_Payment_Request__c payment)<br>Source line 469 | Builds the payment call-to-action only from the verified saved Stripe request URL. |
| private static Decimal componentTotal(Opportunity booking)<br>Source line 473 | Sums the saved initial sponsor/space/power/staff components for itemisation consistency checks. |
| public static String preparationConfigurationError(Opportunity booking, NTE_Routing_Config__mdt routing)<br>Source line 477 | Validates the booking reference and the relevant staff/logo/vehicle destinations before promising the recipient can complete preparation. |
| private static String preparationLinks(Opportunity booking, NTE_Routing_Config__mdt routing)<br>Source line 485 | Builds the audience-specific preparation buttons, with vehicle details included when applicable. |
| private static String staffUrl(Opportunity booking, NTE_Routing_Config__mdt routing)<br>Source line 495 | Selects the partner or exhibitor staff form from routing metadata. |
| private static Boolean needsVehicleLink(Opportunity booking)<br>Source line 499 | Determines whether the saved heavy-vehicle answer requires exposing the vehicle-details route. |
| private static String shortEventLabel(String eventCode)<br>Source line 500 | Derives the recipient-facing short event label from the saved edition code. |
| private static Boolean validUrl(String value)<br>Source line 504 | Accepts usable HTTPS preparation destinations; invalid settings fail the affected booking email. |
| private static Boolean validBookingReference(String value)<br>Source line 512 | Checks the supported NTE reference grammar before emitting preparation instructions. |
| private static String button(String label, String url, String colour, Integer columnCount)<br>Source line 515 | Builds one escaped, consistently sized HTML preparation button for the current column count. |
| private static String quantityLabel(String label, String quantity, Decimal unitPrice)<br>Source line 523 | Formats a component quantity and unit amount for the saved itemisation. Overloads accept stored text or numeric quantities. |
| private static String quantityLabel(String label, Decimal quantity, Decimal unitPrice)<br>Source line 529 | Formats a component quantity and unit amount for the saved itemisation. Overloads accept stored text or numeric quantities. |
| private static String moneyRow(String label, Decimal value)<br>Source line 533 | Builds one escaped label/GBP amount row in the booking finance table. |
| private static Decimal amount(Opportunity booking)<br>Source line 537 | Resolves the booking base amount used by the renderer according to the saved pricing rules. |
| private static Decimal valueOrZero(Decimal value)<br>Source line 538 | Normalises a missing numeric component for validated arithmetic/presentation. |
| private static String money(Decimal value)<br>Source line 539 | Formats a Decimal as GBP with two decimal places. |
| private static String escape(String value)<br>Source line 540 | Escapes dynamic text for insertion into HTML. |
| private static Map<Id, Id> requestMap(List<Request> requests)<br>Source line 541 | Produces the explicit Opportunity-to-Lead request association and rejects conflicting mappings. |
| private static Opportunity failedUpdate(Id bookingId, String errorMessage)<br>Source line 551 | Builds a sparse Opportunity update setting failed approval status and bounded error text. |
| private static void failPendingBatch(String batchKey, String errorMessage)<br>Source line 554 | Marks still-pending members of the identified batch failed; does not demote accepted messages or another batch. |
| private static Task auditFor(Opportunity booking, String status, String outcome, String recipient, String templateName, String errorMessage)<br>Source line 562 | Constructs the completed Task audit containing booking, recipient, template, status and error/outcome evidence. |
| private static Boolean isEligibleComplimentaryBooking(Opportunity booking)<br>Source line 571 | Requires the supported zero-price charity exhibition choice and known saved zero-charge pricing; a missing amount alone is not complimentary. |
| private static String truncate(String value)<br>Source line 579 | Bounds audit/error text to its persistence limit. |



## NTEInboundLeadService

public with sharing class NTEInboundLeadService {. Source: force-app/main/default/classes/NTEInboundLeadService.cls.

Public data contracts: Request.leadId: Id; Request.isNewSubmission: Boolean.


| Method signature | Purpose and behaviour |
| --- | --- |
| public List<Messaging.SendEmailResult> send(List<Messaging.SingleEmailMessage> messages)<br>Source line 29 | Default delivery adapter delegates the complete message list to Messaging.sendEmail; a replaceable adapter supports deterministic partial-result tests. |
| EmailDispatch(Id leadId, Boolean applicant, Messaging.SingleEmailMessage message)<br>Source line 40 | Associates one message with its Lead ID and applicant-versus-internal audit side so results cannot be assigned to a different recipient. |
| public static void routeAndAcknowledge(List<Request> requests)<br>Source line 47 | Flow entry point for five NTE routes. Reloads Leads, resets forged creation decisions/statuses, recalculates application pricing, resolves the configured owner and templates, sends only required unaccepted receipt/notification sides and records per-side outcomes. Application applicant receipts remain suppressed. |
| private static void dispatchAndRecord(List<EmailDispatch> dispatches, Map<Id, Lead> audits, Map<Id, List<String>> errors)<br>Source line 175 | Coordinates delivery and durable audit updates around a savepoint so an audit persistence failure does not leave a falsely accepted intake state. |
| private static void sendDispatches(List<EmailDispatch> dispatches, Map<Id, Lead> audits, Map<Id, List<String>> errors)<br>Source line 195 | Submits the accumulated list within the shared email invocation budget and maps every returned result, missing result or exception back to its own audit side. |
| private static void writeAudits(Map<Id, Lead> audits, Map<Id, List<String>> errors)<br>Source line 221 | Persists applicant/internal status, timestamp and combined errors for each Lead. Successful sides remain accepted during a later failed-side retry. |
| private static Boolean isUsableEmail(String email)<br>Source line 233 | Checks the address shape required before attempting a message; a missing or malformed address becomes a visible delivery failure. |
| private static void setDispatchStatus(Lead audit, Boolean applicant, String status)<br>Source line 237 | Sets the applicant or internal notification status selected by the dispatch flag. |
| private static void fail(Lead audit, Boolean applicant, Map<Id, List<String>> errors, String message)<br>Source line 242 | Marks only the affected side Failed and appends the specific error to that Lead audit. |



## NTEPricingService

public without sharing class NTEPricingService {. Source: force-app/main/default/classes/NTEPricingService.cls.

Public data contracts: ConversionPricingRequest.leadId: Id; ConversionPricingResponse.pricedLead: Lead.


| Method signature | Purpose and behaviour |
| --- | --- |
| String status()<br>Source line 86 | Returns Review required when any selection/count/eligibility check failed; otherwise Calculated. This is the pricing-result status, not a payment state. |
| public static List<ConversionPricingResponse> priceApplicationsForConversion(List<ConversionPricingRequest> requests)<br>Source line 104 | Validates requested Lead IDs and supported application types, reloads current inputs, calculates each application and returns pricedLead responses in request order. It does not persist Lead prices or reprice another booking. |
| public static void recalculateLeads(Set<Id> leadIds)<br>Source line 132 | Maintenance entry point: reloads and reprices matching application Leads, then performs partial SYSTEM_MODE updates. SaveResult outcomes are not exposed; see the issues register before a historical migration. |
| private static List<Lead> loadLeadsForPricing(Set<Id> leadIds)<br>Source line 139 | Queries the source choices, staff allocation and component fields required for current Lead pricing; non-application or missing requested records cannot become valid conversion results. |
| public static void recalculateOpportunities(Set<Id> opportunityIds)<br>Source line 149 | Maintenance entry point for stored booking prices. Recalculates the initial components while preserving separately accepted staff top-up facts; partial DML outcomes are not returned. |
| private static void applyLeadPricing(Lead lead)<br>Source line 163 | Writes the calculated component, included/extra/total staff, listed total, status and catalogue version onto an in-memory application Lead, overriding browser-supplied derived prices. |
| private static void applyOpportunityPricing(Opportunity opportunity)<br>Source line 192 | Maps booking fields into the pricing calculator and writes current initial pricing components. Keeps the booking allocation/top-up separation described in the finance chapter. |
| public static Decimal componentTotal(Decimal sponsorTotal, Decimal spacePrice, Decimal powerTotal, Decimal staffTotal)<br>Source line 224 | Adds sponsor, exhibition space, power and additional initial staff amounts, treating null components as zero. VAT and later staff top-ups are outside this base total. |
| private static PricingResult calculate( String formType, String sponsorPackages, String exhibitorSpace, String category, String powerRequired, Decimal socketCount, String plannedStaffCount )<br>Source line 228 | Authoritative allowlist algorithm. Distinguishes partner package sums from one exhibitor space, checks active category/restricted-space eligibility and whole counts, derives included and chargeable staff, and returns Review required for invalid input. |
| private static Decimal includedStaffForSpace(String spaceName)<br>Source line 294 | Returns four included places for the explicit double-space allowlist and two for other recognised exhibitor spaces. |
| private static Boolean isApplication(String formType)<br>Source line 301 | Recognises only Partner / Sponsor Application and Exhibitor Application. |
| private static Boolean qualifiesForPowerDiscount(String category)<br>Source line 305 | Matches the five explicit qualifying organisation category labels; approximate or altered text cannot receive the discount. |
| private static Boolean isKnownExhibitorCategory(String category)<br>Source line 309 | Caches active schema picklist values and requires an exact recognised category. This makes the field definition part of the pricing contract. |
| private static Boolean isEligibleForRestrictedSpace(String spaceName, String category)<br>Source line 319 | Checks the category-to-space restrictions for charity, local government, blue-light and trade-association choices. |
| private static Decimal decimalFromText(String value)<br>Source line 331 | Parses a stored numeric text count; blank/unparseable input returns null for the caller to classify rather than inventing a valid allocation. |
| private static Decimal valueOrZero(Decimal value)<br>Source line 340 | Normalises a nullable amount to zero for arithmetic after eligibility checks. |



## NTERelatedOpportunityController

public with sharing class NTERelatedOpportunityController {. Source: force-app/main/default/classes/NTERelatedOpportunityController.cls.

Public data contracts: RelationshipResponse.mode: String; RelationshipResponse.title: String; RelationshipResponse.emptyMessage: String; RelationshipResponse.account: RelatedAccount; RelatedOpportunity.id: Id; RelatedOpportunity.name: String; RelatedOpportunity.eventCode: String; RelatedOpportunity.bookingType: String; RelatedOpportunity.stage: String; RelatedOpportunity.amount: Decimal; RelatedOpportunity.closeDate: Date; RelatedOpportunity.primaryContact: Boolean; RelatedAccount.id: Id; RelatedAccount.name: String; RelatedAccount.phone: String; RelatedAccount.website: String; RelatedContact.id: Id; RelatedContact.name: String; RelatedContact.title: String; RelatedContact.email: String; RelatedContact.phone: String; RelatedContact.role: String; RelatedContact.primaryContact: Boolean.


| Method signature | Purpose and behaviour |
| --- | --- |
| public RelatedOpportunity(Opportunity opportunityRecord, Boolean isPrimary)<br>Source line 21 | Projects the readable Opportunity into display fields, including event, reference, stage, amount and whether the current Contact role is Primary. |
| public RelatedAccount(Account accountRecord)<br>Source line 39 | Projects the linked Account into its display name and record link. |
| public RelatedContact(OpportunityContactRole roleRecord)<br>Source line 56 | Projects a Contact Role into Contact details, role and Primary indicator. |
| public static RelationshipResponse getRelationships(Id recordId, String objectApiName)<br>Source line 67 | Validates object/ID agreement and USER_MODE visibility. Account mode returns its NTE bookings; Contact mode follows its roles; Opportunity mode returns its Account and Contact roles. Caps list results at 200. |
| private static List<Opportunity> readableOpportunities(List<Opportunity> records)<br>Source line 169 | Applies readable-field filtering to the selected object records before creating response DTOs. Each helper handles its named SObject type. |
| private static List<OpportunityContactRole> readableRoles(List<OpportunityContactRole> records)<br>Source line 177 | Applies readable-field filtering to the selected object records before creating response DTOs. Each helper handles its named SObject type. |
| private static List<Account> readableAccounts(List<Account> records)<br>Source line 185 | Applies readable-field filtering to the selected object records before creating response DTOs. Each helper handles its named SObject type. |



## NTEStripeBookingService

public without sharing class NTEStripeBookingService {. Source: force-app/main/default/classes/NTEStripeBookingService.cls.


| Method signature | Purpose and behaviour |
| --- | --- |
| public static NTE_Stripe_Config__mdt configuration()<br>Source line 21 | Loads Default Stripe custom metadata or injected test configuration. |
| private static Boolean selected(Opportunity booking, NTE_Stripe_Config__mdt config)<br>Source line 24 | Applies Enabled and optional reference-prefix/recipient scope to a prospective booking. |
| private static String configurationError(NTE_Stripe_Config__mdt config)<br>Source line 31 | Checks required merchant/org/environment/tax configuration and the current Salesforce org binding. |
| private static List<Opportunity> bookings(String whereClause, Map<String, Object> binds, Boolean lockRows)<br>Source line 40 | Executes the fixed field-set SYSTEM_MODE query with supplied bind variables and optional row lock for booking or payment-request records. |
| private static List<NTE_Payment_Request__c> requests(String whereClause, Map<String, Object> binds, Boolean lockRows)<br>Source line 44 | Executes the fixed field-set SYSTEM_MODE query with supplied bind variables and optional row lock for booking or payment-request records. |
| public static Boolean prepareProvisionalBatch(String batchKey, Boolean bypassDelivery, Boolean allowTestLead)<br>Source line 49 | Inspects one approval batch, validates source bookings/contacts, creates or reuses their unique Booking payment requests, and schedules payment work. Returns whether approval must wait for that route. |
| private static Map<Id, List<Lead>> convertedApplications(Set<Id> bookingIds)<br>Source line 112 | Bulk-loads converted source Leads per booking so association checks do not query once per record. |
| private static String eligibilityError(Opportunity booking, Contact recipient, NTE_Stripe_Config__mdt config, Boolean allowTestLead, List<Lead> source)<br>Source line 121 | Rejects unsupported, unconverted/mismatched, paid/cancelled, wrong-org, invalid-price or unusable-recipient bookings before making a link. |
| private static String fingerprint(Opportunity booking, Contact recipient, NTE_Stripe_Config__mdt config)<br>Source line 142 | Hashes the booking identity, price components, recipient, event and payment configuration to bind external resources to the exact saved proposal. |
| PaymentWork(List<Id> values, String batchKey, Boolean bypass, Boolean allowLead)<br>Source line 157 | Stores request IDs and approval continuation context for callout-capable queue processing. |
| public void execute(QueueableContext context)<br>Source line 160 | PaymentWork.execute processes saved requests and continues the same approval workflow; PaymentFinalizer.execute records unhandled failures and resumes failure-aware approval handling. |
| PaymentFinalizer(List<Id> values, String batchKey)<br>Source line 171 | Captures request IDs and batch identity for bounded failure recovery. |
| public void execute(FinalizerContext context)<br>Source line 172 | PaymentWork.execute processes saved requests and continues the same approval workflow; PaymentFinalizer.execute records unhandled failures and resumes failure-aware approval handling. |
| private static void processPayment(Id requestId, Boolean allowTestLead)<br>Source line 185 | Locks/rechecks saved state before callouts, verifies account, creates/reuses Price and Link with stable keys, verifies the resulting contract and rechecks facts afterward. Ambiguous attempts older than 23 hours require review. |
| private static NTEStripeClient.Charge charge(NTE_Payment_Request__c payment)<br>Source line 234 | Builds the API client Charge contract solely from the saved payment-request snapshot. |
| private static Opportunity emailFailure(Id bookingId, String error)<br>Source line 241 | Creates a sparse failed approval update for the booking affected by a payment preparation failure. |
| public static void preloadEmailRequests(Set<Id> bookingIds)<br>Source line 244 | Bulk-loads payment requests into a transaction cache for approval rendering. |
| public static NTE_Payment_Request__c paymentForEmail(Id bookingId)<br>Source line 251 | Returns the cached saved Booking request used in the email finance table/payment button. |
| public static String emailReadinessError(Opportunity booking, Contact recipient)<br>Source line 255 | Verifies the current booking/recipient against the saved verified request, environment and recent verification before permitting email delivery. |
| public static void recordEmailAccepted(Opportunity booking, Opportunity updateRecord, Contact recipient, List<NTE_Payment_Request__c> paymentUpdates)<br>Source line 268 | Updates the payment request email audit and appropriate booking quote/invoice milestones after Salesforce accepts the provisional message. It never marks payment received. |



## NTEStripeClient

public without sharing class NTEStripeClient {. Source: force-app/main/default/classes/NTEStripeClient.cls.

Public data contracts: Charge.accountId: String; Charge.operationKey: String; Charge.bookingReference: String; Charge.chargeKind: String; Charge.currencyCode: String; Charge.amountMinor: Long; Charge.netMinor: Long; Charge.vatRate: Decimal; Charge.description: String; PaymentLink.id: String; PaymentLink.url: String; PaymentLink.priceId: String; PaymentLink.amountMinor: Long; PaymentLink.currencyCode: String.


| Method signature | Purpose and behaviour |
| --- | --- |
| public NTEStripeClient(String credential)<br>Source line 25 | Selects an allowed test/live named credential; all subsequent API calls use that protected endpoint identity. |
| public void verifyAccount(String expectedAccountId)<br>Source line 32 | Reads account and balance, checks the expected merchant and mode, and requires charges_enabled for live operation before permitting resource creation. |
| public String createPrice(Charge charge)<br>Source line 45 | Creates the one-time GBP Price with a year-neutral Product name, saved gross minor units, metadata and stable Price idempotency key. |
| public String createLink(Charge charge, String priceId)<br>Source line 60 | Creates a fixed quantity-one card Payment Link for the verified Price. Disables promotion codes, adjustable quantities, automatic tax and invoice creation; limits completed sessions to one. |
| public PaymentLink verifyLink(Charge charge, String linkId, String priceId)<br>Source line 89 | Retrieves the link and expanded Price and validates amount, currency, merchant mode, metadata, enabled options, quantity/session limits and payment URL before use in email. |
| public static Long toMinorUnits(Decimal amount)<br>Source line 127 | Converts GBP to exact pence using the explicit range and decimal-precision contract; rejects unsupported sub-penny or out-of-range charges. |
| public static Boolean validPaymentUrl(String value, Boolean liveMode)<br>Source line 133 | Checks the buy.stripe.com URL shape and test/live path rules, excluding unexpected query/fragment/host variants. |
| private static void validateCharge(Charge charge)<br>Source line 143 | Validates the saved charge identity, reference, amount and metadata needed for Price/Link requests. |
| private void requireVerifiedAccount(Charge charge)<br>Source line 153 | Requires a prior matching merchant/mode verification for the charge before any write or link acceptance. |
| private void verifyPrice(Charge charge, Map<String, Object> price, String expectedId)<br>Source line 158 | Validates the Price ID, active state, unit amount, currency, one-time billing and metadata against the charge snapshot. |
| private static void requireId(String value, String prefix)<br>Source line 168 | Checks the expected Stripe resource prefix and supported identifier shape. |
| private static Map<String, Object> objectValue(Map<String, Object> source, String key)<br>Source line 171 | Requires an object-shaped nested API response property rather than silently accepting an unexpected type. |
| private static Long longValue(Object value)<br>Source line 175 | Parses an API integer amount without accepting incompatible values. |
| private Map<String, Object> request(String method, String path, Map<String, String> values, String idempotencyKey)<br>Source line 180 | Central form-encoded HTTP transport with 20-second timeout, pinned Stripe API version, protected credential, stable idempotency header and bounded error handling. Parses object JSON responses. |



## NTEUpdateSubmissionJob

public with sharing class NTEUpdateSubmissionJob implements Queueable {. Source: force-app/main/default/classes/NTEUpdateSubmissionJob.cls.


| Method signature | Purpose and behaviour |
| --- | --- |
| public NTEUpdateSubmissionJob(String leadIdPayload, Boolean skipEmailDelivery)<br>Source line 5 | Stores the serialized Lead ID payload and controlled email-bypass flag for after-commit processing. |
| public void execute(QueueableContext context)<br>Source line 10 | Deserialises the exact queued IDs, invokes processLeadIds and records an unexpected worker failure against those source Leads. |



## NTEUpdateSubmissionService

public with sharing class NTEUpdateSubmissionService {. Source: force-app/main/default/classes/NTEUpdateSubmissionService.cls.

Public data contracts: Request.leadId: Id; AcknowledgementRetryResult.success: Boolean; AcknowledgementRetryResult.message: String; AcknowledgementRetryResult.leadId: Id; OrderedSubmission.submission: Lead.


| Method signature | Purpose and behaviour |
| --- | --- |
| public OrderedSubmission(Lead submission)<br>Source line 27 | Wraps a source Lead for stable chronological processing when several submissions target one booking. |
| public Integer compareTo(Object otherValue)<br>Source line 28 | Orders by CreatedDate and then ID so a batch has deterministic first-valid top-up ownership. |
| public static void applyUpdates(List<Request> requests)<br>Source line 36 | Invocable creation entry point. Resets submitted success/booking-identity audit values and queues supported supplementary Lead IDs; actual booking mutation occurs after commit. |
| public static void recordUnexpectedFailure(Set<Id> leadIds, Exception exceptionValue)<br>Source line 67 | Attempts to persist a bounded unexpected-worker error for the affected submission IDs while preserving accepted/applied evidence. |
| public static void processLeadIds(Set<Id> leadIds, Boolean skipEmailDelivery)<br>Source line 100 | Reloads and orders submissions, matches exact normalised references, rejects missing/ambiguous/invalid targets, validates each update and merges valid changes per booking. Saves booking plus applied audit atomically, sends receipts separately and deletes eligible successful temporary Leads. |
| private static OpportunityMatchIndex buildOpportunityMatchIndex(List<Opportunity> matchedOpportunities)<br>Source line 301 | Indexes eligible NTE booking references and marks duplicates ambiguous. Event code is not a second matching key; a unique reference is authoritative. |
| private static void applyPartnerStaffFields(Opportunity target, Lead source)<br>Source line 319 | Replaces the free partner staff count/names and completion metadata from the accepted roster; does not create exhibitor staff charges. |
| private static void applyExhibitorStaffFields(Opportunity target, Lead source, Opportunity existing)<br>Source line 326 | Applies initial names and the first valid immutable top-up purchase, calculates its separate amount and resets only its own invoice/payment milestones. Later name corrections preserve accepted quantities/finance. |
| private static Decimal initialStaffCount(Opportunity existing)<br>Source line 355 | Resolves the booking initial allocation from saved initial fields with the supported legacy fallback; invalid counts remain invalid. |
| private static String combineNames(String baseNames, String topUpNames)<br>Source line 360 | Joins initial and top-up roster lines into the final staff list while enforcing the stored long-text boundary. |
| private static Decimal decimalFromText(String value)<br>Source line 367 | Parses whole staff counts without turning malformed, fractional or missing values into a valid roster allocation. |
| private static String validationErrorFor(Lead source, Opportunity existing)<br>Source line 376 | Enforces form-to-booking audience, reference, declaration, roster count/name consistency, immutable top-up and complete heavy-item/contact requirements. Logo confirmation has its distinct lighter declaration rule. |
| private static Boolean incompleteOptionalItem(String description, String registration, String dimensions, String weight)<br>Source line 452 | Detects partially completed optional heavy-item groups so a replacement cannot silently clear a previously complete set. |
| private static Integer integerFromText(String value)<br>Source line 458 | Parses whole staff counts without turning malformed, fractional or missing values into a valid roster allocation. |
| private static Integer nonBlankLineCount(String value)<br>Source line 467 | Counts nonempty roster lines; the count must match the declared allocation. |
| private static void applyHeavyFields(Opportunity target, Lead source)<br>Source line 474 | Replaces the heavy item/haulier/delivery/contact fields from a complete valid submission and marks heavy details provided; stale optional fields are explicitly cleared. |
| private static void applyLogoFields(Opportunity target, Opportunity existing)<br>Source line 498 | Idempotently sets logo-provided state/time while retaining previous completion evidence on repeat declarations. |
| private static Boolean isValidBookingReference(String suppliedReference)<br>Source line 505 | Checks the normalised NTE reference grammar used for the exact booking match. |
| private static String acknowledgementTemplate(String formType)<br>Source line 513 | Selects the exhibitor staff, partner staff or heavy-vehicle receipt developer name. Logo updates do not request an acknowledgement email. |
| private static Id appliedBookingId(Lead submission)<br>Source line 520 | Reads the durable booking identity captured when the submission was applied; a current reference alone cannot manufacture that identity. |
| private static Boolean matchesAppliedBooking(Lead submission, Opportunity booking)<br>Source line 530 | Requires the saved applied identity/reference to agree with the booking before any receipt retry. |
| private static Lead acknowledgementAudit(Id leadId, String error)<br>Source line 537 | Builds the source Lead receipt acceptance/failure/timestamp update. |
| private static Messaging.SingleEmailMessage acknowledgementMessage(Id mergeLeadId, Id templateId, String primaryEmail)<br>Source line 547 | Builds the stored Lead-template receipt addressed to the matched booking Primary Contact, while using the preserved submission as merge context. |
| private static Map<Id, String> sendAcknowledgements(List<Lead> leads, Map<Id, String> templateByLeadId, Map<Id, Id> bookingIdByLeadId, Boolean skipEmailDelivery, AccessLevel contactAccessLevel)<br>Source line 558 | Loads templates and exact Primary Contacts in bulk, sends bounded receipt groups and maps outcomes per Lead. More than 100 receipts returns failure/retry guidance without undoing applied booking data. |
| public static AcknowledgementRetryResult retryAcknowledgement(Id leadId)<br>Source line 615 | User action retries only one failed receipt after verifying its applied booking and current Primary Contact. Does not replay booking field updates, rematch to another record or delete the source Lead. |
| private static Map<String, Id> templateIds(Set<String> developerNames)<br>Source line 665 | Maps the requested stored template developer names to Salesforce EmailTemplate IDs. |



## NTE_MasterPanelController

public with sharing class NTE_MasterPanelController {. Source: force-app/main/default/classes/NTE_MasterPanelController.cls.

Public data contracts: FilterOption.label: String; FilterOption.value: String; SummaryMetric.key: String; SummaryMetric.label: String; SummaryMetric.value: Integer; SummaryMetric.displayValue: String; SummaryMetric.detail: String; SummaryMetric.icon: String; EventOverviewRow.key: String; EventOverviewRow.groupKey: String; EventOverviewRow.label: String; EventOverviewRow.total: Integer; EventOverviewRow.inProgress: Integer; EventOverviewRow.completed: Integer; EventOverviewRow.detail: String; EventOverviewRow.icon: String; EventOverviewRow.viewKey: String; PipelineStep.key: String; PipelineStep.label: String; PipelineStep.count: Integer; PipelineStep.detail: String; PipelineStep.icon: String; PipelineStep.viewKey: String; WorkQueue.key: String; WorkQueue.label: String; WorkQueue.count: Integer; WorkQueue.detail: String; WorkQueue.icon: String; WorkQueue.reportUrl: String; WorkQueue.weeklyReportUrl: String; WorkQueue.listUrl: String; DashboardRow.recordId: Id; DashboardRow.objectApiName: String; DashboardRow.recordUrl: String; DashboardRow.typeLabel: String; DashboardRow.typeIcon: String; DashboardRow.name: String; DashboardRow.organisation: String; DashboardRow.stage: String; DashboardRow.eventCode: String; DashboardRow.ownerName: String; DashboardRow.bookingReference: String; DashboardRow.contactName: String; DashboardRow.contactIssue: String; DashboardRow.eventDayContactName: String; DashboardRow.eventDayContactEmail: String; DashboardRow.eventDayContactPhone: String; DashboardRow.approvalEmailStatus: String; DashboardRow.approvalEmailError: String; DashboardRow.approvalEmailSentAt: Datetime; DashboardRow.finalPackStatus: String; DashboardRow.finalPackSentAt: Datetime; DashboardRow.invitationStatus: String; DashboardRow.invitationSentAt: Datetime; DashboardRow.lastReminderSentAt: Datetime; DashboardRow.email: String; DashboardRow.phone: String; DashboardRow.packageOrSpace: String; DashboardRow.amount: Decimal; DashboardRow.baseAmount: Decimal; DashboardRow.topUpAmount: Decimal; DashboardRow.pricingReviewRequired: Boolean; DashboardRow.financeStatus: String; DashboardRow.staffStatus: String; DashboardRow.logisticsStatus: String; DashboardRow.logoStatus: String; DashboardRow.logoUpdateProvided: Boolean; DashboardRow.logoUpdateProvidedAt: Datetime; DashboardRow.quoteRequired: Boolean; DashboardRow.quoteProvided: Boolean; DashboardRow.invoiceRequired: Boolean; DashboardRow.invoiceProvided: Boolean; DashboardRow.paymentReceived: Boolean; DashboardRow.baseInvoiceRequired: Boolean; DashboardRow.baseInvoiceProvided: Boolean; DashboardRow.basePaymentReceived: Boolean; DashboardRow.topUpInvoiceRequired: Boolean; DashboardRow.topUpInvoiceProvided: Boolean; DashboardRow.topUpPaymentReceived: Boolean; DashboardRow.canMarkQuote: Boolean; DashboardRow.canMarkInvoice: Boolean; DashboardRow.canMarkPaid: Boolean; DashboardRow.canMarkTopUpInvoice: Boolean; DashboardRow.canMarkTopUpPaid: Boolean; DashboardRow.complete: Boolean; DashboardRow.modifiedAt: Datetime; DashboardRow.reportUrl: String; DashboardRow.sourceFormType: String; DashboardRow.accompanyingGuestName: String; DashboardRow.accompanyingGuestEmail: String; DashboardRow.guestAccessibility: String; DashboardRow.interestType: String; DashboardRow.interestAreas: String; DashboardRow.interestDetail: String; DashboardRow.preferredContact: String; DashboardRow.quoteRequirement: String; DashboardRow.paymentMethod: String; DashboardRow.plannedStaffCount: String; DashboardRow.additionalStaffCount: String; DashboardRow.heavyVehicleRequirement: String; DashboardRow.vehicleType: String; DashboardRow.vehicleRegistration: String; DashboardRow.vehicleDimensions: String; DashboardRow.haulierName: String; DashboardResponse.selectedEventCode: String; DashboardResponse.selectedTimeRange: String; DashboardResponse.selectedOwnerId: String; DashboardResponse.selectedViewKey: String; DashboardResponse.eventOptions: List<FilterOption>; DashboardResponse.ownerOptions: List<FilterOption>; DashboardResponse.summary: List<SummaryMetric>; DashboardResponse.overview: List<EventOverviewRow>; DashboardResponse.pipeline: List<PipelineStep>; DashboardResponse.workQueues: List<WorkQueue>; DashboardResponse.selectedView: WorkQueue; DashboardResponse.rows: List<DashboardRow>; DashboardResponse.totalRows: Integer; DashboardResponse.pageSize: Integer; DashboardResponse.offsetRows: Integer; DashboardResponse.accessibleRows: Integer; DashboardResponse.maxOffsetRows: Integer; DashboardResponse.hasNextPage: Boolean; DashboardResponse.rowsLimited: Boolean; DashboardResponse.refreshedAt: Datetime; HomeMetric.key: String; HomeMetric.label: String; HomeMetric.count: Integer; HomeMetric.value: Decimal; HomePipelineRow.key: String; HomePipelineRow.label: String; HomePipelineRow.count: Integer; HomePipelineRow.exhibitorCount: Integer; HomePipelineRow.partnerCount: Integer; HomePipelineRow.exhibitorValue: Decimal; HomePipelineRow.partnerValue: Decimal; HomePipelineRow.totalValue: Decimal; HomeBookingMixSegment.count: Integer; HomeBookingMixSegment.value: Decimal; HomeBookingMixSegment.averageValue: Decimal; HomeBookingMix.exhibitor: HomeBookingMixSegment; HomeBookingMix.partner: HomeBookingMixSegment; HomeDashboardResponse.selectedEventCode: String; HomeDashboardResponse.eventOptions: List<FilterOption>; HomeDashboardResponse.headlines: List<HomeMetric>; HomeDashboardResponse.pipeline: List<HomePipelineRow>; HomeDashboardResponse.revenueReadiness: List<HomeMetric>; HomeDashboardResponse.bookingMix: HomeBookingMix; HomeDashboardResponse.pricingReviewCount: Integer; HomeDashboardResponse.refreshedAt: Datetime; ActionResult.success: Boolean; ActionResult.message: String; ActionResult.completedAt: Datetime; ReminderDraft.viewKey: String; ReminderDraft.title: String; ReminderDraft.matchingCount: Integer; ReminderDraft.recipientCount: Integer; ReminderDraft.missingEmailCount: Integer; ReminderDraft.recipientLimit: Integer; ReminderDraft.canSend: Boolean; ReminderDraft.subject: String; ReminderDraft.messageBody: String; ReminderSendResult.success: Boolean; ReminderSendResult.sentCount: Integer; ReminderSendResult.failedCount: Integer; ReminderSendResult.skippedCount: Integer; ReminderSendResult.message: String; ReminderSendResult.completedAt: Datetime; ReminderRecipient.booking: Opportunity; ReminderRecipient.primaryContact: Contact; ReminderRecipient.updateUrl: String; UpdateEmailIssue.leadId: Id; UpdateEmailIssue.formType: String; UpdateEmailIssue.error: String.


| Method signature | Purpose and behaviour |
| --- | --- |
| public FilterOption(String labelValue, String storedValue)<br>Source line 62 | Constructs one label/value filter option consumed by the LWC. |
| public SummaryMetric(String metricKey, String metricLabel, Integer metricValue, String display, String metricDetail, String iconName)<br>Source line 75 | Constructs the named response record for summary counters, breakdown/progress rows, operational queues or commercial charts. Values are assembled by the corresponding aggregate helpers; constructors do not mutate records. |
| public EventOverviewRow(String rowKey, String rowGroup, String rowLabel, Integer totalValue, Integer progressValue, Integer completedValue, String rowDetail, String iconName, String targetView)<br>Source line 95 | Constructs the named response record for summary counters, breakdown/progress rows, operational queues or commercial charts. Values are assembled by the corresponding aggregate helpers; constructors do not mutate records. |
| public PipelineStep(String stepKey, String stepLabel, Integer stepCount, String stepDetail, String iconName, String targetView)<br>Source line 116 | Constructs the named response record for summary counters, breakdown/progress rows, operational queues or commercial charts. Values are assembled by the corresponding aggregate helpers; constructors do not mutate records. |
| public WorkQueue(String queueKey, String queueLabel, Integer queueCount, String queueDetail, String iconName, String relatedReportUrl, String relatedListUrl)<br>Source line 135 | Constructs the named response record for summary counters, breakdown/progress rows, operational queues or commercial charts. Values are assembled by the corresponding aggregate helpers; constructors do not mutate records. |
| public Integer compareTo(Object value)<br>Source line 221 | Sorts combined Lead/Opportunity dashboard rows deterministically by modification time and record ID, keeping pagination stable across tied timestamps. |
| private Integer compareRecordIds(DashboardRow other)<br>Source line 230 | Sorts combined Lead/Opportunity dashboard rows deterministically by modification time and record ID, keeping pagination stable across tied timestamps. |
| public HomeMetric(String metricKey, String metricLabel, Integer metricCount, Decimal metricValue)<br>Source line 266 | Constructs the named response record for summary counters, breakdown/progress rows, operational queues or commercial charts. Values are assembled by the corresponding aggregate helpers; constructors do not mutate records. |
| public HomePipelineRow(String rowKey, String rowLabel)<br>Source line 283 | Constructs the named response record for summary counters, breakdown/progress rows, operational queues or commercial charts. Values are assembled by the corresponding aggregate helpers; constructors do not mutate records. |
| public HomeBookingMixSegment()<br>Source line 299 | Constructs the named response record for summary counters, breakdown/progress rows, operational queues or commercial charts. Values are assembled by the corresponding aggregate helpers; constructors do not mutate records. |
| public HomeBookingMix()<br>Source line 309 | Constructs the named response record for summary counters, breakdown/progress rows, operational queues or commercial charts. Values are assembled by the corresponding aggregate helpers; constructors do not mutate records. |
| public ReminderRecipient(Opportunity bookingValue, Contact primaryContactValue, String formUrl)<br>Source line 357 | Captures a booking, exact Primary Contact and resolved form URL for the retained legacy reminder draft API. |
| public static HomeDashboardResponse getHomeDashboard(String eventCode)<br>Source line 364 | Builds the selected edition commercial portfolio: pending/approved value, independently invoiced/paid/outstanding base and top-up amounts, pricing-review count, readiness and participant mix. Excludes closed losses and unrelated record types. |
| public static DashboardResponse getDashboard(String eventCode, String timeRange, String ownerId, String viewKey, Integer pageSize, Integer offsetRows)<br>Source line 530 | Normalises event/time/owner/view/pagination, executes USER_MODE counts and row queries, and returns consistent cards, refiners, report links, details and navigation limits. |
| public static List<Id> getCommunicationRecordIds(String eventCode, String timeRange, String ownerId, String viewKey)<br>Source line 566 | Reloads the complete filtered target selection for a composer action, with strict stale-filter checks and a 501-record sentinel beyond the 500-recipient capacity. It does not use only the current page. |
| public static List<UpdateEmailIssue> getUpdateEmailIssues(Id opportunityId)<br>Source line 595 | Returns up to 100 recent failed supplementary receipts associated by saved booking reference, including submissions whose event code differs from the booking edition. |
| public static ActionResult updateLeadDecision(Id leadId, String decisionName)<br>Source line 613 | Locks and rechecks one active interest/application. Supports the permitted not-progressed/rejected decision, preserves accepted invitation/converted history and rejects stale or retired manual progression actions. |
| public static ReminderDraft getReminderDraft(String eventCode, String timeRange, String ownerId, String viewKey)<br>Source line 675 | Retained legacy read-only reminder API: returns audience/subject/body and a bounded eligible recipient draft. Current LWC uses NTEEmailDispatchService instead. |
| public static ReminderSendResult sendUpdateReminders(String eventCode, String timeRange, String ownerId, String viewKey, String subject, String messageBody)<br>Source line 716 | Retired send entry point always raises a handled instruction to use the reviewed communication composer. It does not send messages. |
| public static ActionResult updateMilestone(Id opportunityId, String actionName)<br>Source line 722 | Locks an eligible booking in USER_MODE, validates quote/base/top-up invoice/payment order, stamps the exact flag/time/user and rejects repeated actions. First base payment queues one confirmation; top-up payment does not. |
| private static Map<String, Integer> counts(String leadBase, String opportunityBase, Map<String, Object> leadBinds, Map<String, Object> opportunityBinds)<br>Source line 835 | Runs the scoped aggregate queries behind all operational counters using the shared finance/readiness clauses. |
| private static List<SummaryMetric> summary(Map<String, Integer> counts)<br>Source line 879 | Transforms scoped counts into top-level cards, event breakdowns, stage navigation or queue options respectively. These are views of the same bookings, not additive disjoint totals. |
| private static List<EventOverviewRow> overview(Map<String, Integer> counts)<br>Source line 891 | Transforms scoped counts into top-level cards, event breakdowns, stage navigation or queue options respectively. These are views of the same bookings, not additive disjoint totals. |
| private static List<PipelineStep> pipeline(Map<String, Integer> counts)<br>Source line 916 | Transforms scoped counts into top-level cards, event breakdowns, stage navigation or queue options respectively. These are views of the same bookings, not additive disjoint totals. |
| private static List<WorkQueue> workQueues(Map<String, Integer> counts, Map<String, String> reports)<br>Source line 930 | Transforms scoped counts into top-level cards, event breakdowns, stage navigation or queue options respectively. These are views of the same bookings, not additive disjoint totals. |
| private static WorkQueue queue(String key, String label, Map<String, Integer> counts, String detail, String icon, Map<String, String> reports, String listUrl)<br>Source line 958 | Constructs one queue with its count, explanatory detail, related report and native-list URL. |
| private static WorkQueue selectedView(String viewKey, Map<String, Integer> counts, Map<String, String> reports, List<WorkQueue> queues)<br>Source line 964 | Resolves the current queue descriptor from the normalised view key and computed counts. |
| private static List<DashboardRow> rows(String viewKey, String leadBase, String opportunityBase, Map<String, Object> leadBinds, Map<String, Object> opportunityBinds, Integer pageSize, Integer offsetRows, String reportUrl)<br>Source line 969 | Queries the required Lead/Opportunity fields for the chosen view, sorts/pages results, and for Recent merges both object types before slicing. |
| private static DashboardRow leadRow(Lead recordValue, String reportUrl)<br>Source line 1044 | Maps one Lead to panel columns/details, contact data, decision/invitation status and permitted review actions. |
| private static DashboardRow opportunityRow(Opportunity recordValue, String reportUrl)<br>Source line 1102 | Maps one booking and its exact Primary Contact to panel details, saved finance/readiness facts, missing-data reasons and next actions. |
| public static Boolean isComplete(Opportunity booking)<br>Source line 1180 | Single in-memory completion rule: resolved quote, known/settled applicable base and top-up finance, staff and logo provided, and No heavy vehicles or Yes plus details provided. Pack sending is separate. |
| private static Boolean isUpdateRequired(Opportunity booking)<br>Source line 1192 | Identifies missing staff/logo or unresolved required logistics; finance readiness is evaluated separately. |
| private static Decimal knownLeadValue(Lead recordValue)<br>Source line 1199 | Returns the known application listed value; unknown/review-required pricing is excluded rather than treated as free. |
| private static Decimal knownOpportunityValue(Opportunity recordValue)<br>Source line 1205 | Returns the known combined base and separate top-up commitment for commercial aggregation. |
| private static Decimal knownBaseOpportunityValue(Opportunity recordValue)<br>Source line 1210 | Resolves the known saved base amount without including later top-up money. |
| private static void addToMetric(HomeMetric metric, Decimal value)<br>Source line 1217 | Adds a qualifying record and known value to one Home metric. |
| private static void addToPipeline(HomePipelineRow row, Boolean exhibitor, Decimal value)<br>Source line 1222 | Adds count/value to the exhibitor or partner segment of a Home pipeline row. |
| private static void addToBookingMix(HomeBookingMix mix, Boolean exhibitor, Decimal value)<br>Source line 1235 | Accumulates exhibitor/partner counts and values for the booking mix. |
| private static void finalizeBookingMix(HomeBookingMix mix)<br>Source line 1241 | Calculates totals/segment proportions after accumulating the selected edition mix. |
| private static List<HomeMetric> orderedMetrics(Map<String, HomeMetric> metrics, List<String> keys)<br>Source line 1248 | Returns metrics or pipeline rows in the explicit display order rather than map iteration order. |
| private static List<HomePipelineRow> orderedPipeline(Map<String, HomePipelineRow> rowsByKey, List<String> keys)<br>Source line 1254 | Returns metrics or pipeline rows in the explicit display order rather than map iteration order. |
| private static Boolean isBaseBillable(Opportunity booking)<br>Source line 1260 | Returns true for Invoice Required Yes, a positive listed base total or pricing requiring review. Keeping unknown pricing billable prevents an incomplete record bypassing finance. |
| private static Boolean leadPricingNeedsReview(Lead recordValue)<br>Source line 1266 | Identifies missing/invalid pricing for an application Lead or booking; used to expose review work and withhold misleading financial readiness. |
| private static Boolean pricingNeedsReview(Opportunity booking)<br>Source line 1271 | Identifies missing/invalid pricing for an application Lead or booking; used to expose review work and withhold misleading financial readiness. |
| private static Boolean hasKnownPricing(String pricingStatus, Decimal listedTotal)<br>Source line 1275 | Implements the supported Calculated/non-null and known positive legacy pricing rule. Invalid/missing zero pricing is not accepted as complimentary. |
| private static Boolean isTopUpBillable(Opportunity booking)<br>Source line 1281 | Returns true when Top Up Invoice Required is set or the separate staff top-up amount is positive. |
| private static Boolean isBillable(Opportunity booking)<br>Source line 1286 | Returns whether either the base charge or the separate top-up requires finance. |
| private static Boolean baseInvoiceComplete(Opportunity booking)<br>Source line 1290 | Evaluates the named charge/milestone pair, treating a known non-billable charge as complete and requiring its own saved flag for a positive charge. |
| private static Boolean topUpInvoiceComplete(Opportunity booking)<br>Source line 1294 | Evaluates the named charge/milestone pair, treating a known non-billable charge as complete and requiring its own saved flag for a positive charge. |
| private static Boolean basePaymentComplete(Opportunity booking)<br>Source line 1298 | Evaluates the named charge/milestone pair, treating a known non-billable charge as complete and requiring its own saved flag for a positive charge. |
| private static Boolean topUpPaymentComplete(Opportunity booking)<br>Source line 1302 | Evaluates the named charge/milestone pair, treating a known non-billable charge as complete and requiring its own saved flag for a positive charge. |
| private static Decimal valueOrZero(Decimal value)<br>Source line 1306 | Converts null to zero after known-price eligibility has been determined. |
| private static String financeStatus(DashboardRow row)<br>Source line 1310 | Presents the next unresolved quote/invoice/payment or pricing-review state from the mapped booking facts. |
| private static String typeLabel(String formType)<br>Source line 1321 | Maps the supported form type to the participant label or icon used in panel rows. |
| private static String typeIcon(String formType)<br>Source line 1329 | Maps the supported form type to the participant label or icon used in panel rows. |
| private static String leadStage(Lead recordValue)<br>Source line 1337 | Presents recorded Converted, Rejected, Invited, Queued or current review state without reopening a decided Lead. |
| private static String preferredContact(String method, String timeValue)<br>Source line 1351 | Combines the saved preferred contact method and timing for the detail panel. |
| private static String leadViewClause(String viewKey)<br>Source line 1356 | Adds the exact interest/application/guest/recent Lead filter for a normalised queue key. |
| private static String activeInterestClause()<br>Source line 1367 | Excludes converted, progressed and not-progressed interests from active review. |
| private static String activeApplicationClause()<br>Source line 1372 | Excludes converted and rejected applications from active review. |
| private static String opportunityViewClause(String viewKey)<br>Source line 1376 | Selects the quote/invoice/payment, preparation, completed or approved booking subset for the chosen view. |
| private static String logisticsOutstandingClause()<br>Source line 1399 | Expresses unresolved heavy-vehicle state in SOQL, including unknown answers rather than assuming No. |
| private static String completeClause()<br>Source line 1404 | SOQL counterpart of isComplete, used by counts and final-pack/completed selection. Must stay aligned with the in-memory rule. |
| private static String billableClause()<br>Source line 1413 | Returns the SOQL predicate for any, base or separate top-up charge respectively. |
| private static String baseBillableClause()<br>Source line 1417 | Returns the SOQL predicate for any, base or separate top-up charge respectively. |
| private static String pricingReadyClause()<br>Source line 1421 | Returns the SOQL known-price or review-required predicate used consistently in finance queues. |
| private static String pricingReviewClause()<br>Source line 1426 | Returns the SOQL known-price or review-required predicate used consistently in finance queues. |
| private static String topUpBillableClause()<br>Source line 1432 | Returns the SOQL predicate for any, base or separate top-up charge respectively. |
| private static String anyInvoiceOutstandingClause()<br>Source line 1436 | Selects bookings with an unresolved applicable base or top-up invoice. |
| private static String allInvoicesProvidedClause()<br>Source line 1441 | Requires both applicable invoices or known non-billable exceptions. |
| private static String actionablePaymentClause()<br>Source line 1446 | Selects a payment that can be recorded now, respecting quote, invoice and booking-first order while allowing independent top-up invoice work. |
| private static String allPaymentsReceivedClause()<br>Source line 1452 | Requires both applicable base and top-up payments, allowing known non-billable charges to pass. |
| private static String quoteResolvedClause()<br>Source line 1457 | Accepts no quote requirement or a saved provided quote. |
| private static String notBillableClause()<br>Source line 1461 | Returns the complementary known non-billable predicates for combined, base or top-up finance. Unknown pricing is not equivalent to free. |
| private static String baseNotBillableClause()<br>Source line 1465 | Returns the complementary known non-billable predicates for combined, base or top-up finance. Unknown pricing is not equivalent to free. |
| private static String topUpNotBillableClause()<br>Source line 1471 | Returns the complementary known non-billable predicates for combined, base or top-up finance. Unknown pricing is not equivalent to free. |
| private static Integer viewCount(String viewKey, Map<String, Integer> counts)<br>Source line 1476 | Returns the count associated with a normalised view key. |
| private static void configurePagination(DashboardResponse response, Integer requestedOffset)<br>Source line 1480 | Clamps page size/offset to a valid accessible last page and the 2000-row browser cap, even when queues shrink between requests. |
| private static Integer countLead(String whereClause, Map<String, Object> binds)<br>Source line 1491 | Executes the named object bound aggregate count in USER_MODE. |
| private static Integer countOpportunity(String whereClause, Map<String, Object> binds)<br>Source line 1495 | Executes the named object bound aggregate count in USER_MODE. |
| private static String leadBaseWhere(String eventCode, String ownerId, Datetime sinceAt)<br>Source line 1499 | Builds the supported NTE Lead/event/owner/creation-date base predicate. |
| private static String opportunityBaseWhere(String eventCode, String ownerId, Datetime sinceAt)<br>Source line 1507 | Builds the NTE record type, supported participant, nonblank event, open-or-won, owner and creation-date base predicate. |
| private static Map<String, Object> baseBinds(String eventCode, String ownerId, Datetime sinceAt)<br>Source line 1520 | Produces bind variables for event, owner, time and required record type/form choices. |
| private static Map<String, Object> copyBindsWith(Map<String, Object> source, String bindName, Object bindValue)<br>Source line 1532 | Copies a query bind map before adding a view-specific parameter. |
| private static List<FilterOption> eventOptions()<br>Source line 1539 | Collects nonblank event codes from relevant main Leads/bookings and sorts them descending. Legacy codes remain selectable; unrelated/supplementary-only events do not become empty choices. |
| private static List<FilterOption> ownerOptions()<br>Source line 1571 | Returns selectable owner label/ID options for the dashboard scope. |
| private static Map<String, String> reportUrls()<br>Source line 1582 | Resolves the stored NTE report IDs and builds native Lightning URLs, including the weekly finance report. |
| private static String resolveEventCode(String requested, List<FilterOption> options)<br>Source line 1595 | Preserves an explicit available edition; otherwise selects the highest available canonical NTE plus four-digit year, then falls back to the first option only if no canonical code exists. |
| private static String communicationEventCode(String requested)<br>Source line 1605 | Strictly validates a communication edition rather than silently substituting another when a draft action is stale. |
| private static String normalizeTimeRange(String value)<br>Source line 1612 | Normalises dashboard time-range input to the supported choices. |
| private static String communicationTimeRange(String requested)<br>Source line 1617 | Rejects unsupported/stale communication time ranges instead of widening the intended recipient scope. |
| private static String normalizeViewKey(String value)<br>Source line 1625 | Maps aliases and supported panel view keys to the canonical queue; falls back only for ordinary dashboard navigation. |
| private static String normalizeOwnerId(String value)<br>Source line 1640 | Validates the selected owner ID or recognised all-owner choice before binding the query. |
| private static String normalizeReminderView(String value)<br>Source line 1651 | Restricts the retained reminder API to the supported outstanding preparation views. |
| private static List<Opportunity> reminderBookings(String eventCode, String timeRange, String ownerId, String viewKey)<br>Source line 1659 | Loads up to 2000 scoped candidate bookings for the retained legacy reminder draft, ordered by Account/name. |
| private static Map<Id, Contact> primaryContactsByOpportunity(List<Opportunity> bookings)<br>Source line 1678 | Delegates exact Primary Contact resolution for the selected reminder bookings. |
| private static String reminderTitle(String viewKey)<br>Source line 1686 | Supplies legacy kind-specific reminder presentation text; the active composer defaults are in NTEEmailDispatchService. |
| private static String reminderSubject(String viewKey)<br>Source line 1692 | Supplies legacy kind-specific reminder presentation text; the active composer defaults are in NTEEmailDispatchService. |
| private static String reminderBody(String viewKey)<br>Source line 1698 | Supplies legacy kind-specific reminder presentation text; the active composer defaults are in NTEEmailDispatchService. |
| private static String reminderUrl(String viewKey, String sourceFormType, NTE_Routing_Config__mdt routing)<br>Source line 1711 | Resolves the legacy reminder form destination from view, participant type and routing metadata. |
| private static String personaliseReminder(String templateBody, ReminderRecipient recipient)<br>Source line 1720 | Expands the retained legacy reminder body against one recipient snapshot. |
| private static Task reminderAuditTask(ReminderRecipient recipient, String viewKey, String subject, Boolean sent, String errorMessage)<br>Source line 1734 | Builds the historical reminder audit Task shape. The retired send entry point cannot dispatch through this path. |
| private static String closedTaskStatus()<br>Source line 1757 | Finds a usable closed Task status for audit creation rather than assuming a target-specific label. |
| private static Datetime sinceAt(String timeRange)<br>Source line 1770 | Converts the supported time-range choice into a CreatedDate lower-bound timestamp; all time has no lower bound. |
| private static String safeMessage(Exception exceptionValue)<br>Source line 1778 | Returns bounded useful exception text for the operator without replacing a specific controlled validation message. |
| private static AuraHandledException handled(String message)<br>Source line 1784 | Creates an AuraHandledException for a controlled Lightning-visible error. |



## VolunteerInboundLeadService

public with sharing class VolunteerInboundLeadService {. Source: force-app/main/default/classes/VolunteerInboundLeadService.cls.

Public data contracts: Request.leadId: Id; Request.isNewSubmission: Boolean.


| Method signature | Purpose and behaviour |
| --- | --- |
| public List<Messaging.SendEmailResult> send(List<Messaging.SingleEmailMessage> messages)<br>Source line 22 | Default send adapter calls Messaging.sendEmail for the complete list; tests substitute controlled per-message results. |
| Dispatch(Id leadId, Boolean applicant, Messaging.SingleEmailMessage message)<br>Source line 33 | Keeps the Lead, applicant/internal side and message together for exact result mapping. |
| public static void notifyOwner(List<Request> requests)<br>Source line 40 | Flow entry point restricted to the matching volunteer form type and LeadSource. Resets forged new-record acceptance, resolves applicant and current active owner independently, sends the two volunteer templates and preserves already accepted sides on retry. |
| private static void dispatchAndRecord(List<Dispatch> dispatches, Map<Id, Lead> audits, Map<Id, List<String>> errors)<br>Source line 134 | Wraps message and audit processing so persistence problems leave a recoverable outcome rather than pretending the stored audit is complete. |
| private static void sendDispatches(List<Dispatch> dispatches, Map<Id, Lead> audits, Map<Id, List<String>> errors)<br>Source line 154 | Sends the accumulated volunteer messages using the remaining shared invocation budget; records partial failures and missing results individually. |
| private static void writeAudits(Map<Id, Lead> audits, Map<Id, List<String>> errors)<br>Source line 180 | Saves the volunteer applicant/internal acceptance fields and errors on the source Lead. |
| private static Boolean isUsableEmail(String email)<br>Source line 192 | Rejects missing or malformed applicant/owner addresses before delivery. |
| private static void setStatus(Lead audit, Boolean applicant, String status)<br>Source line 196 | Writes the correct volunteer applicant or internal status field. |
| private static void fail(Lead audit, Boolean applicant, Map<Id, List<String>> errors, String message)<br>Source line 201 | Accumulates an error and marks just the affected volunteer delivery side Failed. |



## Apex test coverage by feature

These are the 17 packaged test classes. The named scenarios specify project invariants and provide examples for rebuilding behaviour. Fixture constructors, mocks and assertion helpers are omitted from the scenario list; they are retained in the source archive. No test class is a production trigger or scheduled job.

### NTEBookingPaymentEmailTest

Source: force-app/main/default/classes/NTEBookingPaymentEmailTest.cls.

booking Payment Confirms Each Exact Primary And Participant Template Once; stripe Confirmations Show Saved Paid Totals Without Another Payment Request; staff Top Up Never Repeats The Booking Confirmation; failed Provisional Does Not Delay Recorded Payment Confirmation; unusable Preparation Reference Keeps Payment And a Recoverable Confirmation; inconsistent Itemisation Cannot Be Sent As a Paid Confirmation; complimentary Top Up Payment Does Not Create a Booking Email; missing Primary Keeps Payment And Failed Request Then Retries After Repair; send Failure Keeps Payment And Retry Uses The Same Dispatch Only Once; missing Template Is Retryable Without Changing Payment; changed Primary Never Receives An Old Queued Snapshot; changed Booked Amount Leaves The Payment Confirmation Unsent; paid Confirmation Cannot Be Sent Through The Editable Mass Draft; milestone Queues An After Commit Worker.

### NTEConversionFlowTest

Source: force-app/main/default/classes/NTEConversionFlowTest.cls.

converted Application Copies Nte Fields To Opportunity; complimentary Conversion Confirms Only When No Extras Are Charged; partner Bank Transfer Conversion Sends Partner Provisional Email; twelve Conversions Cross The Old Limit Without Flow Errors; mixed Conversions Use Their Exact Booking After Another Booking Is Modified; existing Synthetic Account And Contact Keep Their Identity And Receive Their Exact Booking; conversion Reprices Current Inputs Without Changing Older Booking Facts; incomplete Current Selection Cannot Reuse Its Earlier Calculated Price; mismatched Converted Lead Does Not Send To Either Booking; public Retry Reports Queue Failure Truthfully Without Losing The Booking; public Retry Reports Only Its Exact Queued Booking; document Native No Opportunity Conversion Pending Owner Decision; document Native Existing Booking Conversion Pending Owner Decision.

### NTEEmailDispatchServiceTest

Source: force-app/main/default/classes/NTEEmailDispatchServiceTest.cls.

invitation Draft Routes Each Interest And Explains Exclusions; future Event Invitations Use Reusable Participant Links; exact Selection Is Idempotent And Progresses Only After Accepted Send; changed Email Before Queue Requires Another Reviewed Draft; changed Primary Contact After Queue Does Not Receive The Frozen Email; failed Only Retry Reuses Dispatch And Preserves Successful History; failed Retry Does Not Silently Switch To a New Recipient; queued Job Processes Only Its Saved Selection With Delivery Bypassed; completed Details And Missing Primary Contact Are Skipped; unpriced Zero Booking Does Not Become Eligible For a Final Pack; final Pack Needs Configured Event And Completion And Keeps Sent History; preview Escapes Editable Text And Routes Each Update Type; oversized Selection And Missing Or Unsafe Link Cannot Queue; json Preview And Queue Preserve Browser Payload And Exact Selection; json Boundary Rejects Malformed Unknown And Oversized Requests; json Boundary Retains Recipient Change Checks; largest Draft And Queue Keep Only One Html Preview; maximum Message And Selection Fail Before Rows Then Allow a Smaller Selection; combined Personalisation Budget Rejects Otherwise Valid Individual Messages; combined Html Escaping Budget Protects The Worker Payload; full Worker Page Maps Failures And Skips To Their Own Recipients; queued Source Rejects Another Draft Even With Another Run Id; reminder Kinds Remain Independent And Repeatable Until Complete; changed Final Pack Event Or Link Cannot Send Old Draft; token Looking Data Stays Literal And Text Keeps Paragraphs; contact Roles Use Exactly One Primary And Never Fallback; merged Booking Details Changed After Payment Require Retry; tampered Selection Does Not Cross Records Or Email Kinds; expanded Subject And Message Must Still Fit Their Limits; confirmation Still Sends When Provisional Failed And Queue Failure Is Recoverable; late Completer Gets Only Its Own Final Pack And Top Up Preserves Earlier Sent History; unusable Booking Reference Cannot Create Preparation Mail Or a Pack.

### NTEExhibitorApprovalEmailServiceTest

Source: force-app/main/default/classes/NTEExhibitorApprovalEmailServiceTest.cls.

text Alternative Preserves Details Without Hidden Layout Text; exhibitor Uses Primary Contact And Sends Only Once; partner Uses Partner Template And Preparation Form; complimentary Booking Confirms Only When No Charge Is Due; partner Reservation Uses Selected Names And Preserves Saved Combined Price; missing Primary Email Fails Without Fallback And Can Be Retried; absent Primary Role Fails Despite Usable Applicant And Day Contact; failed Send Retains Visible Failure And Only Successful Retry Is Sent; explicit Requests Coalesce One Post Commit Job; unpriced Booking Cannot Send a Confirmation Even When Marked Paid; blank Pricing Status Preserves Known Charge But Not Unknown Zero; inconsistent Saved Charge Needs Review Without Manual Adjustment; inconsistent Itemised Power Fails Only Its Booking And Can Be Repaired; additional Staff Charge Needs a Whole Quantity And Saved Unit Price; participant Type Cannot Hide An Unitemised Component; malformed Preparation Destinations Fail Only When Applicable; unusable Booking Reference Leaves Preparation Email Unsent; failed Job Recovery Touches Only Pending Bookings In Its Batch; stored Greetings Handle Missing And Escaped First Names; stored Optional Lead Rows Preserve Partial And Multiline Values; stored Partner Rows Keep Supplied Booking Contacts; literal Template Syntax And Html Looking Names Remain Recipient Text; more Than One Queue Page Drains Every Explicit Booking Exactly Once; salesforce Accepts Contact And Opportunity Template; empty Requests And Already Sent Retry Do Not Enqueue.

### NTEInboundLeadServiceTest

Source: force-app/main/default/classes/NTEInboundLeadServiceTest.cls.

routes Supported Lead And Builds Notifications; records Blank Applicant Email Then Retries Only That Message; invalid Configured Owner Does Not Fall Back To Another Recipient; records Salesforce Acceptance Without Duplicate Invocation; all Five Routes Use Their Matching Applicant And Owner Templates; large Mixed Intake Uses One Platform Email Invocation; partial Rejection And Missing Results Remain Retryable; retired Application Receipts Stay Suppressed During Internal Retry; thrown Send Failure Retains Lead And Can Recover; exhausted Invocation Budget Records Failure Instead Of Rolling Back Intake; failed Audit Save Cancels Attempt And Retains Recoverable Failure; forged Creation Decisions Cannot Hide Fresh Interest Or Application; retry Preserves Later Staff Decision And Invitation History; empty And Null Requests And Unsupported Forms Are No Ops; email Validation Rejects Missing Or Malformed Addresses.

### NTEMasterPanelFinanceTest

Source: force-app/main/default/classes/NTEMasterPanelFinanceTest.cls.

combined Refiners And Overview Count Each Booking Once; payment Required Contains Only An Actionable Next Payment; booking Invoice Precedes Top Up Without Combining Stored Milestones; booking Payment Precedes Top Up And Preserves Space Confirmation; booking Payment Does Not Wait For The Top Up Invoice; prematurely Invoiced Top Up Still Waits For Booking Payment; complimentary Booking Skips Only Its Own Finance Milestones; quote Must Be Provided Before Either Invoice Can Be Recorded; repeated Actions Preserve Recorded Dates Users And Separate Flags; unknown Pricing Cannot Appear Free Confirmed Or Payable Even With Old Flags; home Preserves Paid Booking Money When Top Up Is Still Outstanding; complimentary Quote Remains Visible Without Inventing a Payment; every Stored Invoice Payment Combination Keeps Actions And Counts Consistent; known Positive Legacy Charge Does Not Require a Migration.

### NTEMasterPanelReadinessTest

Source: force-app/main/default/classes/NTEMasterPanelReadinessTest.cls.

logo Alone Blocks Completion And Updates Counters Until Provided; panel Uses Primary Contact And Keeps Day Contact Separate; absent Primary Email Is Flagged Without Replacing It With Day Email; update Email Issues Use Booking Reference Across Submission Event Codes; final Pack Refiners And Communication Selection Separate Sent And Queued; reopened Top Up Finance Preserves Pack History And Never Reenters Unsent; interest Selection Respects Type Event Owner And Decision; queued Or Sent Invitation Cannot Be Rejected; unrecognised Logistics Cannot Disappear From Outstanding Work; every Logistics Staff And Logo Combination Uses One Completion Definition; communication Selection Returns Limit Sentinel Without Expanding Past501.

### NTEMetadataReportStressTest

Source: force-app/main/default/classes/NTEMetadataReportStressTest.cls.

confirmed Value Excludes Missing And Invalid Prices; native Finance Views Follow Both Charges And Booking First Order.

### NTEPanelStressTest

Source: force-app/main/default/classes/NTEPanelStressTest.cls.

inactive And Wrong Source Bookings Reject Every Stale Finance Action; closed Won Bookings Keep Legitimate Finance Work; stale Communication Filters Cannot Select Another Event Or All Owners; unrelated And Supplementary Events Do Not Become Empty Default Choices; valid Year Default Preserves Explicit Historical Code Selection; recent Rows Show Decisions Instead Of Reopening Review In Their Status; repeated Rejection Cannot Write a Second Decision; pagination Limit And Shrinking Queues Have An Explicit Stable Last Page; merged Recent Pages Remain Deterministic Across Both Record Objects; time Filters Use Submission Creation And Leave Future Years Independent; user Mode Rejects Restricted Reads And Actions Without Mutation.

### NTEPricingServiceTest

Source: force-app/main/default/classes/NTEPricingServiceTest.cls.

calculates Partner Packages And Flags Unavailable Selections; calculates Exhibitor Components And Discounts; flags Unknown Selections Instead Of Inventing Prices; prevents Restricted Space Eligibility Bypass; derives Large Space Allowance And Rejects Invalid Staff Totals.

### NTEPricingStressTest

Source: force-app/main/default/classes/NTEPricingStressTest.cls.

every Space Has Consistent Lead And Booking Components; every Category Uses Exact Discount And Restricted Space Rules; every Sponsor And Pair Uses Fixed Prices With No Staff Or Power Charge; malformed Duplicate Missing And Removed Packages Cannot Become Calculated; invalid Staff Counts Never Produce Complimentary Or Negative Pricing; invalid Power Counts Are Review Work And No Power Ignores Stale Counts; missing Unknown Or Lookalike Categories Cannot Claim a Power Discount; missing Removed Or Altered Space Labels Never Invent Free Prices; applicant Entered Count Overrides Forged Derived Totals And Prices; booked Initial Staff And Separate Finance Facts Survive Recalculation; bulk Persisted Lead Pricing Restores All Derived Values; conversion Pricing Uses Current Inputs In Request Order Without Saving; conversion Pricing Rejects Missing Or Non Application Requests; non Applications Null Inputs And Numeric Legacy Counts Are Safe.

### NTERelatedOpportunityControllerTest

Source: force-app/main/default/classes/NTERelatedOpportunityControllerTest.cls.

nte Opportunity Record Type Id; non Nte Opportunity Record Type Id; account Returns Only Nte Opportunities; contact Returns Its Nte Opportunities; opportunity Returns Account And Contacts; regular Crm Opportunity Cannot Use Nte Relationship Mode; user Mode Prevents Restricted User From Bypassing Crud And Field Access.

### NTEStripeBookingServiceTest

Source: force-app/main/default/classes/NTEStripeBookingServiceTest.cls.

exhibitor Request Email Preserves Manual Payment And Exact Gross; partner Email Keeps Partner Preparation And Saved Amount; outage Blocks Email Without Changing Payment; retry Uses Committed Request And The Original Idempotency Keys; failed Email Reuses Verified Link Without Another Charge; changed Amount Or Recipient Cannot Use An Old Request; ambiguous Creation Older Than Idempotency Window Requires Review; recipient Change After Verification Holds Email; disabled Out Of Scope And Unconverted Bookings Cannot Create Links; ordinary Form References Prepare Both Application Types; ordinary Form Scope Accepts Other Recipients; ordinary Form Scope Preserves Existing Request Identity; paid Cancelled And Wrong Org Hold The Request; bulk Preparation Does Not Query Per Booking; next Year Uses New Opportunity With The Same Account And Contact; live Mode Runs Through The Provisional Email; switching Environment Cannot Reuse An Earlier Test Request; switching Environment After Verification Holds The Email; link Timeout Preserves Price And Recovers The Same Request; past Close Date And Closed Won Do Not Expire a Booking.

### NTEStripeClientTest

Source: force-app/main/default/classes/NTEStripeClientTest.cls.

complete Fixed Link Contract And Stable Retries; no Writes Until Account And Mode Are Verified; changed Link Cannot Be Used In An Email; exact Pence And Url Boundaries; verified Live Account Creates The Same Fixed Payment Contract; live Configuration Rejects Wrong Mode And Unavailable Merchant.

### NTEUpdateSubmissionServiceTest

Source: force-app/main/default/classes/NTEUpdateSubmissionServiceTest.cls.

logo Update Matches Every Event Code And Retains Audit Leads; repeated Logo Update Is Idempotent And Retained; invalid Logo References Are Retained Without Changing Bookings; logo Update Cannot Target Regular Or Incomplete Nte Opportunities; unmatched Reference Retains Lead Without Changing Opportunity; non Nte Opportunity With Matching Reference Is Not Eligible; opportunity Match Index Rejects Ambiguous Reference; exhibitor Top Up Is Separated From Initial Booking Value; exact Reference Applies Heavy Vehicle Details; heavy Submission Sets Requirement Yes For Every Prior State; bulk Staff And Heavy Updates For One Booking Are Merged Without Duplicate Id Failure; empty And Unsupported Requests Are Handled Safely; invalid Payload Is Retained Without Marking Booking Complete; incomplete Heavy Payload Is Retained Without Marking Logistics Complete; missing Top Up Answer Remains Outstanding And Retains Lead; partner Staff Update Is Free And Becomes The Roster Source Of Truth; staff Forms Cannot Update The Wrong Booking Type; accepted Top Up Rejects Quantity Changes And Preserves Finance On Name Corrections; missing Primary Retains Applied Update And Retry Does Not Replay Its Data; blank Primary Email Does Not Fall Back To Event Contact Or Submitter; email Refusal Keeps Saved Details And Retries Only The Receipt; same Batch Top Ups Use The First Valid Accepted Purchase; oversized Top Up Does Not Consume The Purchase; oversized Batch Entry Cannot Lock Top Up Or Roll Back Other Bookings; invalid Legacy Staff Allocations Cannot Be Rounded Into Valid Rosters; receipts Use The Matched Booking Event Across Staff And Vehicle Forms; logo Confirmations Do Not Require Signature Or Date; other Preparation Forms Still Require Their Declarations; applied Receipt Cannot Be Retargeted By Editing Its Reference; receipt Without Verified Applied Identity Cannot Rematch Another Booking; closed Lost Booking Accepts First Top Up Heavy And Logo After Pack Was Sent; no New Top Up Corrects Base Names Without Changing Accepted Purchase Or Contacts; incomplete Optional Heavy Items Preserve The Full Previous Replacement; partner Rejects Missing Zero Negative And Mismatched Rosters; unexpected Queue Failure Is Recorded Without Throwing.

### NTE_MasterPanelControllerTest

Source: force-app/main/default/classes/NTE_MasterPanelControllerTest.cls.

nte Opportunity Record Type Id; non Nte Opportunity Record Type Id; dashboard Reconciles Filters Counts Pipeline And Rows; non Nte Record Types Cannot Contaminate Metrics Rows Actions Or Event Filters; home Dashboard Reconciles Counts Values And Finance Requirements; home Dashboard Uses Dynamic Event Selection And Empty Financial Totals; owner Time And Lead Views Are Applied; application Pagination Is Stable When Records Share a Timestamp; guest Queue Details Are Returned; partner Interest Queue Details Are Returned; exhibitor Interest Queue Details Are Returned; finance Aggregate Is Returned; lead Stage Subtype Views Return Combined And Narrowed Rows; application Subtype View Returns Narrowed Rows; converted Application Moves Into Approved Metrics; recent Converted Applications Show Their Recorded Outcome; approved Stage Subtype Views Return Narrowed Rows; finance And Update Subtype Views Return Narrowed Rows; logo Update View Counts Filters And Refreshes After Status Change; payment Required View Supports Marking Paid; top Up Invoice And Payment Are Tracked After The Booking; unconfirmed Logistics Cannot Be Completed; completion Requires Every Applicable Milestone; milestones Enforce Order And Record Audit; invalid Actions Are Rejected Without Mutation; rejection Leaves Active Queues And Manual Progress Is Retired; every Finance View Links To The Weekly And Cross Event Reports; reminder Draft Uses Primary Recipients And Old Sender Cannot Dispatch; reminder Composer Supports Future Events Without Hard Coded Years.

### VolunteerInboundLeadServiceTest

Source: force-app/main/default/classes/VolunteerInboundLeadServiceTest.cls.

saves Revised Volunteer Details And Renders Availability; rejects New Applications Without Current Code Acknowledgement; preserves Legacy Applications Without Retroactive Acknowledgement; records Blank Applicant Email Then Retries Only That Message; records Salesforce Acceptance Without Duplicate Invocation; partial Rejection And Missing Results Remain Retryable; thrown Send Failure Retains Lead And Can Recover; exhausted Invocation Budget Records Failure Instead Of Rolling Back Intake; failed Audit Save Cancels Attempt And Retains Recoverable Failure; empty And Null Requests And Unsupported Forms Are No Ops; email Validation Rejects Missing Or Malformed Addresses; bypass Records Not Attempted And Retains Lead; uses Lead Recipient And Current Active Owner Only; missing Owner Email Retains Lead And Retries Only Internal Notification; ignores Non Volunteer And Mismatched Source Records; forged Creation Acceptance Cannot Suppress Acknowledgements; mixed Nte And Volunteer Batch Shares Platform Budget Without Dropping Messages; full Trigger Batch Retains Every Individual Result.
