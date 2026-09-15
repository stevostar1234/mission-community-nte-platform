# Runtime implementation

## Persisted processing states

The status fields below represent different operations. Do not infer that a payment is collected because a request is Ready, that an update failed because its receipt failed, or that a booking is complete because an email is Sent. Several audit statuses are stored as Text, so the service's exact strings are part of the implementation contract.

| Operation | Stored states and transitions |
| --- | --- |
| Initial NTE or volunteer receipt and internal notice | Not Attempted becomes Accepted by Salesforce or Failed independently for each side. The retired commercial applicant receipt uses Not required. Only unaccepted required sides are retried. |
| Supplementary data application | New work is Pending. It becomes Matched and Applied, No Matching Booking, Ambiguous Booking Reference or Failed. Matched and Applied can coexist with a failed applicant-email status. |
| Provisional or complimentary booking email | Saved request is Pending, then Sent or Failed. Sent is not resent; a failed eligible booking can save another Pending attempt through its supported retry action. |
| Editable or paid-confirmation dispatch | Queued becomes Sent, Failed or Skipped. Failed retries reuse the saved dispatch identity; Skipped reflects a now-ineligible or changed reviewed target. Invitation and final-pack source fields mirror their dispatch outcome. |
| Stripe payment request | A saved request is Queued, then Ready or Needs review. A retry can reuse the same request/resources and reverify them. Ready requires a valid snapshot and recent verification before email; Delivered At records accepted email, while manual Opportunity flags record payment. |

The method catalogue later in this document lists every extracted implementation method and constructor with its signature, source line and responsibility. This chapter explains the collaborations and algorithms that those methods implement. Test-only switches are dependency seams for qualification, not production configuration.

## Primary Contact resolution

NTEBookingContactService uses inherited sharing and accepts an explicit AccessLevel. primaryContacts resolves only OpportunityContactRole rows with IsPrimary=true. singlePrimaryContactIds removes any booking with more than one such role, including duplicate role rows pointing to the same Contact. It returns no recipient for that booking. The service then loads the actual Contact records, optionally locking roles and Contacts. Send workflows lock the Opportunity first, then resolve/lock the contact relationships so a concurrent recipient change cannot silently redirect a queued message.

The result is a Map keyed by Opportunity ID. It contains Contact name, email, phone and mobile values. Panel display prefers Phone then MobilePhone. The service does not invent a recipient from Account, an event-day email or a Lead. NTERelatedOpportunityController uses the actual Account/Contact Role graph to display related bookings; Account mode and Contact mode intentionally use different relationship queries.

## Initial NTE and volunteer intake

NTEInboundLeadService is a create/retry service called through Request.leadId and Request.isNewSubmission. It locks unconverted supported Leads and only resets public-submitted email/decision flags for a new submission. A transaction-level processed set prevents repeat work on the same Lead. A later retry preserves invitation/rejection decisions and previously accepted applicant/internal messages. NTERouting Default usernames are resolved to active Users per form route; a configured invalid owner records an internal failure instead of notifying an arbitrary fallback. With no configured override, the existing active user owner is used; queues do not provide an individual internal-email recipient.

An applicant message renders against the Lead and targets Lead.Email. The internal message uses the same Lead merge context, sets treatTargetObjectAsRecipient=false and supplies the chosen owner's email explicitly. EOI and guest routes have both templates. Commercial application routes have only the internal template. A null applicant template produces the recorded Not required outcome and stays suppressed during internal retry.

The Sender interface isolates Messaging.sendEmail. Pending messages are sent together within the available platform invocation budget, with result positions mapped back to their exact Lead and audience. Missing result entries, rejected messages, exceptions and exhausted budget become per-message failures. writeAudits persists the separate statuses and combined error text. dispatchAndRecord uses a savepoint so accepted-send audit failure can cancel that attempt before recording retryable failure.

VolunteerInboundLeadService applies the same applicant/owner acceptance pattern to Leads whose Web_Form_Type__c and LeadSource both equal Volunteer Application. It uses Volunteer_Applicant_Email_Status__c, Volunteer_Internal_Email_Status__c and Volunteer_Email_Error__c, its own pair of Mission Motorsport templates and the current active Lead owner. It does not run NTE pricing or NTE metadata owner routing.

## Provisional and complimentary booking emails

NTEExhibitorApprovalEmailService retains its historical class name but handles both commercial participant types. sendApprovalConfirmation accepts exact Lead/Opportunity pairs from the Flow. saveRequests rejects mismatches and already sent/pending work, preserves legacy activity evidence that would imply an earlier send, and saves Pending, source Lead ID, batch key, requested timestamp and requesting user. Requests from the same transaction coalesce under one random batch key and Queueable.

ApprovalQueueable attaches ApprovalFinalizer, asks NTEStripeBookingService to prepare selected payment requests, and otherwise drains pending bookings in pages of 40. Sending is performed in groups of ten messages. A chained job continues remaining work. A failed job's finalizer marks only still-pending bookings in its own batch as Failed; it does not touch another conversion's requests.

Each send loads the saved converted Lead, verifies its ConvertedOpportunityId and form type, resolves the current Primary Contact, validates reference, stored price and preparation configuration, then renders the matching stored template against Contact and Opportunity. renderBookingEmail replaces explicit NTE_TOKEN comment markers with an itemised finance summary and the appropriate action links. Missing or unresolved markers fail the message rather than display template syntax. plainTextFromHtml preserves visible paragraphs, rows and link destinations while removing CSS/head/script/hidden preheader text.

Exhibitor and partner provisional templates provide their respective staff form, logo confirmation and vehicle form when logistics is not explicitly No. An eligible zero-price charity uses NTE_Complimentary_Exhibitor_Approved. Payment-confirmation rendering reuses this presentation pipeline but requires base invoice/payment recorded, positive valid pricing and preparation links; a saved Stripe request must still agree with the current net amount. Paid rendering does not generate another Payment Link.

Successful acceptance stamps the booking's sent time and actual recipient and adds an outcome Task. Stripe's recordEmailAccepted additionally records invoice/link delivery and the payment request's Delivered_At__c and Recipient__c, without recording payment. A failed provisional remains recoverable through the Opportunity action. That recovery requires exactly one qualifying converted application for the booking, cannot resend Sent or Pending, and does not undo any other milestone.

## Editable invitations reminders and final packs

NTEEmailDispatchService implements an exact-selection email queue. Kind values are INVITATION, STAFF_DUE, HEAVY_DUE, LOGO_DUE, FINAL_PACK and BOOKING_CONFIRMED. BOOKING_CONFIRMED is reserved for the payment transition and cannot be prepared through the editable bulk composer.

buildDraft validates 1 to 500 IDs of the correct object type, resolves current eligibility and returns a random run ID, editable subject/body, recipient rows, eligible/skipped counts and a first preview. A Selection contains recordId and fingerprint. DraftRequest carries kind, runId, subject, messageBody and those selections. The browser uses JSON boundary methods because they preserve the exact selected payload. deserializeStrict rejects unknown properties; request JSON is limited to 300,000 characters, subject to 255 without line breaks, and body to 32,000. The run ID must be 16 to 64 alphanumeric/underscore/hyphen characters. Duplicate recipient IDs and unknown tokens are rejected.

Allowed tokens are {ContactName}, {Organisation}, {BookingReference}, {EventCode}, {UpdateLink}, {ApplicationLink} and {FinalPackLink}. Personalisation is one pass; recipient data that happens to resemble a token is kept literal rather than expanded again. HTML output escapes editable and recipient text. Missing reference/event/action link content is appended where required by the template. The worker verifies expanded subject/body limits as well as the raw editable limits. Aggregate heap estimation includes the escaped personalised HTML and serialized payload, so a large individually valid message/selection can require a smaller audience.

The fingerprint includes message kind, record/participant identity, current contact/company/email, reference, event and chosen link. Booking confirmation also includes the booking snapshot used to render its financial content. queueMessages rereads and locks the selected records and excludes changed or ineligible recipients. Dispatch_Key__c is a SHA-256 of kind, run ID and source record ID. The same queued selection is idempotent; a separately reviewed reminder run is allowed while that preparation remains outstanding.

DispatchQueueable processes at most 40 saved dispatch IDs per page and chains the rest. It rechecks eligibility and fingerprint after queueing. Each message result updates only its own dispatch. A changed recipient or completed requirement produces Skipped; a booking-confirmation problem remains Failed so the saved payment has a visible recoverable notification. updateSourceStatuses synchronises only invitation and final-pack status, recipient and sent time. Sent is not demoted by a later failure, and a queued request cannot be replaced by a second draft for the same target/kind.

retryFailed takes only Failed dispatch records. It reuses their IDs and selection snapshot, rejecting changed eligibility/recipients rather than silently sending to someone new. Booking-confirmation retry is the deliberate exception: it rebuilds the current valid booking/Primary Contact snapshot after repair. queueBookingConfirmation uses a stable kind plus BOOKING_PAYMENT plus Opportunity key, so the first base payment transition creates at most one automatic request. Existing Failed needs retry; existing Sent is not repeated. Finalizers record still-queued failures after an unexpected worker rollback.

## Supplementary validation and mutation

NTEUpdateSubmissionService validates the form's supported audience before changing a booking. Partner staff updates must target a Partner / Sponsor Application; exhibitor staff updates must target an Exhibitor Application. Non-logo forms require a supplied declaration name and date. Staff forms check integer ranges and nonblank line counts. Exhibitor logic compares against the saved initial quantity and any accepted top-up before calculating the new roster. Numeric legacy values must be valid whole numbers; invalid historic text cannot be rounded into an allocation.

Heavy-vehicle validation requires the supplied main/secondary contact fields, delivery window, first item and haulier fields expected by that form. The form field reference lists each required control. applyHeavyFields copies the delivery/item/haulier values only, replacing the full logistics snapshot. applyLogoFields changes the logo flag and sets its timestamp only when first provided or missing; repeated confirmation preserves an existing date.

sendAcknowledgements resolves applicable stored templates and actual primary emails. At most 100 acknowledgement messages are supported in this phase. A larger set records an actionable receipt failure for the accepted updates rather than pretending to send a subset. Receipts are sent in groups of ten. retryAcknowledgement uses user-mode access and a locked Lead to retry one accepted update's receipt. It neither changes the booking again nor deletes the Lead during that explicit retry.

## Master Panel and Home controller

NTE_MasterPanelController builds DashboardResponse from event/owner options, filtered counts, pipeline and breakdown models, view definitions and paged DashboardRow values. Lead base filtering requires a nonblank event code; Opportunity base filtering additionally requires NTE_Event_Opportunity, a supported commercial source type and an open or Closed Won booking. Today/rolling date filters use CreatedDate. Counts are independent COUNT queries over the complete matching population; displayed rows are capped at 2,000 and sliced after deterministic modification-date/ID sorting.

For each booking row the controller derives billability, eligible next actions, finance status, staff/logistics/logo status, completion and actual Primary Contact. It queries successful reminder history for only the current page. A Lead row derives invitation/rejection/conversion state without treating a converted or rejected submission as a new application. WorkQueue DTOs provide the named native report/list destinations; reports are looked up by DeveloperName rather than fixed Salesforce IDs.

updateLeadDecision locks and validates an open in-scope Lead, then writes only the appropriate rejection flags. updateMilestone locks a valid booking, verifies pricing and ordering, and stamps the exact requested finance fact. Both use USER_MODE. getCommunicationRecordIds returns up to 501 IDs as an explicit over-limit sentinel and rejects stale/invalid communication filters instead of broadening the audience. getUpdateEmailIssues finds applied update Leads with failed receipts by booking reference, including submissions whose original website edition differs.

getHomeDashboard calculates commercial metrics from the selected edition, keeping base and top-up monetary facts separate. Unknown prices contribute no amount and increase the pricing review count. The displayed Home rows overlap as described in the workflow chapter. getReminderDraft remains a compatibility/read helper with its historical 100-recipient limit; sendUpdateReminders is deliberately disabled and instructs callers to use the recipient preview. The current LWC uses NTEEmailDispatchService, whose reviewed recipient limit is 500. Legacy reminder Task/personalisation helpers do not constitute another active send path.

## Lightning components

| Bundle | Exposed surface | Behaviour and integration |
| --- | --- | --- |
| nteMasterPanel | Lightning tab / app page / home page targets declared in its bundle metadata. | Imperative getDashboard loads the panel. STAGE_CONFIGURATION maps six stages to combined/refined view keys. Row decoration controls column sets, amount meanings, action visibility and contact links. Calls the decision/milestone services and exact-selection email JSON APIs. |
| nteManagementHome | Home page. | Imperative getHomeDashboard populates headlines, pipeline, readiness and booking mix. Formats GBP and en-GB dates, scales comparison bars and shows pricing-review count. Event change/refocus refreshes the data. |
| nteRelatedOpportunities | Record pages with recordId and objectApiName. | Reactive @wire calls getRelationships. Account/Contact display booking lists; Opportunity displays account/contact relationships. Native record URLs and email links are built from returned data. |
| nteRetryEmail | Headless record action. | @api invoke chooses booking retry for 006 Opportunity IDs, supplementary receipt retry for 00Q Lead IDs, otherwise dispatch retry. Its running flag prevents duplicate invocation; it reports the service outcome and refreshes the record cache. |

nteMasterPanel invalidates stale asynchronous responses using separate dashboard, composer and preview sequences. Refocus refresh is delayed 150 ms and suppressed during a modal/action. Conversion opens a blank tab synchronously to avoid a blocked popup, obtains the native conversion URL through NavigationMixin, then watches for window closure every 750 ms. Subject/body edits debounce server preview by 300 ms; Send stays disabled until the preview corresponds to the current version and selection. The dialog traps keyboard focus, supports Escape when idle, and restores focus to the originating control or Refresh.

The component's HTML selects view-specific table columns and the right-hand detail groups. Its CSS supplies the gold/navy NTE appearance, responsive grid/table, status pills, modal and loading treatments. The custom NTE_OneRegionHomeTemplate Aura bundle gives Home a full-width region for nteManagementHome. The application explicitly overrides Home and Account/Contact/Lead/Opportunity View pages within NTE Management, with desktop and mobile record-page assignments. Native mobile record detail is retained alongside desktop Dynamic Forms.

## Access that the implementation depends on

NTE_Management_Access combines NTE_Management_User and NTE_Stripe_Test_Operator. The latter's current label is NTE Stripe Payment Operator and it grants both configured environment principals despite its historical API name. Assign the group to NTE administrators and selected standard users. Volunteer_Applications_User is separate and adds the volunteer Lead fields/service; it is not a member of the NTE group. NTE_Forms_Administration remains an alternative administration permission set with overlapping NTE grants, not the standard onboarding group.

NTE Management grants create/read/edit for Lead, Account, Contact, Opportunity, Task, Event and NTE_Email_Dispatch__c, read-only payment-request access, the NTE record type/tab/application and required Apex actions. It grants ConvertLeads, RunReports and EditTask. It does not grant deletion or blanket View All/Modify All. The packaged criterion-based Opportunity rule gives all internal users Edit access to the NTE record type; the NTE Operations & Finance report folder is shared View to all internal users. Field-level grants and native object permissions are listed in the configuration reference.

Interactive panel, relationship and retry entry points use user-mode checks. Internal pricing, conversion email and Stripe coordination deliberately use system-mode operations to complete their saved workflow. This distinction is material to recreating the behaviour: record visibility in the operator workspace, Primary Contact resolution and background workflow identity cannot be replaced by a blanket sharing assumption.
