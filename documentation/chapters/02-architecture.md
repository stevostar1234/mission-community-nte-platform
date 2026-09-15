# Solution architecture

The implementation is an unmanaged Salesforce DX metadata project for Mission Community's National Transition Event and a separate Mission Motorsport volunteer intake. The package API version is 67.0. Its runtime consists of four Lead-triggered Flows, twelve implementation Apex classes, four Lightning Web Components, native Salesforce record pages/reports and ten public Web-to-Lead forms. There is no custom Apex trigger, Apex REST intake endpoint, Experience Cloud site or separate application database in this package.

## System boundaries

[DIAGRAM:system]

| Layer | Responsibility | Maintained source |
| --- | --- | --- |
| Public website | Collects declarations, application selections, contact details and supplementary updates; calculates advisory estimates; submits a native HTML POST. | Root HTML pages; assets/config.js; assets/forms.js; assets/styles.css; assets/volunteer-styles.css. |
| Salesforce intake | Stores each submission as Lead, performs routing/pricing/notifications or schedules supplementary processing. | Four Flows in force-app/main/default/flows; NTEInboundLeadService, VolunteerInboundLeadService, NTEUpdateSubmissionService. |
| Booking and identity | Standard Lead conversion produces Account, Contact, Opportunity and Contact Role relationships; the conversion Flow adds the NTE booking snapshot. | NTE_Copy_Converted_Lead_to_Opportunity; NTEPricingService; NTEBookingContactService. |
| Operations | Filters work queues, applies staff decisions and finance milestones, presents reports and relationships. | nteMasterPanel, nteManagementHome, nteRelatedOpportunities; NTE_MasterPanelController; NTERelatedOpportunityController. |
| Communication | Sends intake receipts, provisional booking emails, reminders, final packs and payment confirmation with distinct audit/retry models. | NTEEmailDispatchService; NTEExhibitorApprovalEmailService; nteRetryEmail; stored email templates. |
| Payment provider | Creates and verifies booking-specific Stripe Prices and Payment Links. Finance records payment in Salesforce manually. | NTEStripeClient; NTEStripeBookingService; NTE_Payment_Request__c; environment credentials/configuration. |
| External event operations | Supplies formal invoices/quotes, partner agreements, external logo storage, final-pack content and manual payment/refund reconciliation. | Client-owned services and the configured URLs. These are dependencies, not implemented Salesforce services. |

The canonical preview website is https://stevostar1234.github.io/nte27-web-to-lead-demo/. It currently posts to MMUAT. The production NTE-hosted website is a separate deployment destination. The repository includes source, generated metadata, browser/email previews, local and Apex qualification code, maintenance scripts and historical release evidence. Historical screenshots, audit fixtures and retired templates are evidence rather than active runtime components.

## Physical objects and relationships

[DIAGRAM:data]

| Object | Purpose and key relationships |
| --- | --- |
| Lead | Submission envelope. Main NTE form types and volunteer applications remain Leads until a deliberate commercial application conversion. Supplements carry Target_Booking_Reference__c and are processed independently. ConvertedAccountId, ConvertedContactId and ConvertedOpportunityId identify the exact conversion results. |
| Account | Reusable organisation. Opportunity.AccountId identifies the organisation for each booking. Five NTE classification fields show the latest classified application; they are not an event-history collection. |
| Contact | Reusable person. Contact.AccountId is the native organisation link. Six NTE classification fields show latest participation and role label. The Contact's actual name/email are authoritative for booking correspondence. |
| Opportunity | One event booking under NTE_Event_Opportunity. Stores application snapshot, booking reference, event code, canonical initial price, later staff top-up, readiness, finance milestones and provisional/final-pack audit. |
| OpportunityContactRole | Standard junction between Opportunity and Contact. Exactly one IsPrimary=true role must resolve for automatic booking correspondence. Other linked Contacts can remain on the booking without becoming recipients. |
| NTE_Email_Dispatch__c | One queued invitation, reminder, final pack or payment-confirmation request. Optional lookups to Lead, Opportunity and Contact; unique external Dispatch_Key__c. Stores rendered-input snapshot, recipient, kind, outcome and attempt history fields. |
| NTE_Payment_Request__c | Saved original booking charge and Stripe identifiers. Optional Opportunity lookup; unique external Charge_Key__c. Stores merchant, environment, net/gross minor units, source fingerprint, Price/Link IDs, verification and email-delivery evidence. |
| NTE_Routing_Config__mdt | Default record holds owner usernames, preparation/application URLs and final-pack edition/URLs. It is configuration, not a transactional booking object. |
| NTE_Stripe_Config__mdt | Default record holds enablement, merchant/org binding, test/live mode, tax rate and optional scope filters. Credentials are separate. |
| Task | Native activity records retain provisional booking email outcome against WhatId=Opportunity and WhoId=Primary Contact. Other standard tasks/calendar activities are user managed. |

Custom dispatch lookups use SetNull on parent deletion; they are not master-detail relationships. The payment-request Opportunity lookup also uses SetNull. Their object-level sharing model is ReadWrite. Reference strings and saved Lead/booking ID text fields are deliberately different from Salesforce lookup relationships. A reference match must be unique within the eligible booking set before any update occurs.

The booking reference is an 80-character Text external ID on both Lead and Opportunity. Both objects enforce case-insensitive uniqueness within their own records. Server matching also rejects ambiguity defensively. Browser generation uses NTE- plus a millisecond timestamp and eight characters from an unambiguous alphabet. Server update matching trims and uppercases the reference and rejects ambiguity. The reference is a matching identifier, not an authenticated user session. Event code is a separate field; it is not embedded into the reference grammar.

Event-day contact fields, secondary-contact fields and invoicing-contact fields on the booking are snapshots of operational information. They do not create additional Contacts automatically and are not fallbacks for email routing. The initial conversion can reuse an existing Contact. Subsequent correspondence intentionally follows the current Primary Contact, subject to the queued message's change-detection rules.

## Intake and conversion sequence

[DIAGRAM:conversion]

1. The website synchronises conditional/derived fields, validates the form and submits to servlet.WebToLead. Hidden control names are native standard names or target-org custom field IDs.
2. Salesforce creates a Lead. Create-only NTE or volunteer Flow invokes its matching service. The service resets untrusted workflow/audit flags for a new submission, then performs only the relevant intake work.
3. NTEPricingService recalculates commercial application values from its server catalogue. Browser price fields are advisory. Applicant and internal notification results are recorded separately; the two commercial application types have no applicant intake receipt.
4. An operator converts an approved application using the standard Salesforce screen. The conversion Flow starts only when IsConverted becomes true, ConvertedOpportunityId is populated and Web_Form_Type__c is one of the two commercial application types.
5. The Flow calls priceApplicationsForConversion and receives a priced Lead value in Priced_Application. It looks up the NTE Opportunity RecordType by SobjectType and DeveloperName, updates the exact converted Opportunity, then queues the provisional/complimentary email. It classifies the converted Account and Contact in the same transaction.
6. The background booking worker resolves the exact saved converted Lead and current Primary Contact. For an enabled Stripe booking, payment work runs first and the verified link is included. For manual-payment or complimentary bookings, the corresponding stored template is rendered directly.
7. Salesforce acceptance records the email audit and activity. A failure leaves a visible, recoverable booking email status. It does not repeat conversion or silently select another booking.

No Flow changes the org-wide Lead conversion mappings. The full field-to-field assignments appear in the conversion mapping reference. Standard conversion determines the native organisation, person, Contact Role, Opportunity name, owner and initial stage/date choices; the NTE Flow supplies its additional snapshot and Amount. In particular, it does not set Closed Won to mean approved or paid.

## Supplementary submission sequence

[DIAGRAM:updates]

NTE_Supplementary_Update_Handler accepts Partner / Sponsor Staff Update, Exhibitor Staff Update, Heavy Vehicle Details and Logo Update on Lead creation. It calls applyUpdates, which resets the new update status and saved applied-booking identity, then schedules NTEUpdateSubmissionJob after the Lead commits. The job passes the exact Lead IDs to processLeadIds.

Submissions are processed in CreatedDate and ID order. The matching index contains supported commercial NTE Opportunities with nonblank event codes and matching references; it does not exclude Closed Lost. A malformed reference is Failed, no match is No Matching Booking, and more than one match is Ambiguous Booking Reference. An invalid payload is Failed with an error. These paths preserve the Lead and do not mark the booking complete.

Valid mutations and Matched and Applied audit are saved together behind a savepoint. The Lead receives the matched event code, saved booking ID and processing result. For multiple updates to one booking in the batch, the in-memory booking is updated after each accepted change so a second top-up cannot bypass the first purchase. Unexpected DML errors roll back the batch's booking/audit writes and retain failure information.

Acknowledgement is a separate phase after successful application. Staff and heavy-vehicle receipts use Lead merge data but the booking's actual Primary Contact email as the explicit recipient. A missing contact or send failure does not undo accepted data. Successful receipts normally permit deletion of those temporary Leads; deletion failure can leave a successfully processed Lead. Logo submissions are retained and send no receipt. An applied Lead's receipt retry verifies its saved booking identity and original reference, so editing the reference cannot retarget the receipt to another booking.

## Transaction and processing boundaries

| Boundary | Coupled effects | Recovery semantics |
| --- | --- | --- |
| Initial Lead intake | Email acceptance and Lead email-audit fields are coupled using a savepoint. | Failed audit persistence rolls back that send attempt and leaves retryable failure. Accepted applicant/internal messages are not repeated during a later service retry. |
| Conversion | NTE Opportunity copy, saved provisional request and Account/Contact classification participate in the conversion transaction. | Background work starts after commit. A stored batch key and exact Lead/Opportunity pair prevent unrelated bookings being selected. |
| Supplement application | Booking changes and applied update audit are one savepoint unit. | Receipt failure preserves accepted booking changes. A receipt retry never applies those changes again. |
| Dispatch worker | Salesforce send results, dispatch status and invitation/final-pack source status are saved in the worker transaction. | Unhandled failures roll back the worker and a finalizer records failures for still-queued requests. |
| Stripe callouts | External objects can exist before the final Salesforce save succeeds. | Stable operation keys and saved IDs recover the same request. Source/configuration changes or an old ambiguous operation require reconciliation. |
| Manual payment action | Payment fact is saved before confirmation preparation is attempted. | A notification error cannot undo the payment milestone. The failed confirmation has its own recovery route. |

## Edition behaviour

For public NTE forms, April to December selects the following year's edition; January to March selects the current year. The default timezone is Europe/London. A nonblank eventCodeOverride must be NTE followed by four digits and overrides the date calculation. The script recalculates edition at submission and pageshow, so a browser tab left open across the April boundary uses the new edition. A booking reference already generated in that tab is retained.

New or changed main-intake Lead edition/type values are checked by NTE_Intake_Event_Code. The rule does not retroactively invalidate unrelated edits to historical Leads. Supplementary forms match the booking reference and adopt the booking's event code, even if the website's current edition differs. Application invitations use reusable participant URLs and are not gated by the interest's year. Final packs are gated by the routing record's Final Pack Event Code.

NTE27 in current public/email display copy is separate from functional NTE_Event_Code__c. A new edition therefore needs a deliberate content/catalogue review as well as the automatic code rollover. Stripe descriptions for newly created requests are year-neutral. Saved historic descriptions, prices and milestones are not automatically rewritten.

## Documentation conventions

The workflow, implementation, data dictionary and reconstruction sections separate operating instructions from technical reference. Diagrams use a bounded purpose, labelled components and explicit direction; the data model names both logical entities and physical APIs and identifies relationship cardinality. These conventions follow Salesforce's published diagram guidance and data-model notation. [How to Build Salesforce Diagrams](https://architect.salesforce.com/docs/architect/reference-diagrams/guide/introduction.html) and [Salesforce Data Model Notation](https://architect.salesforce.com/docs/architect/reference-diagrams/guide/data-model-notation).

Explanations connect each custom component to its purpose, data changes and dependencies, consistent with Salesforce Admins' guidance on documenting why an implementation exists and how it works. Salesforce's guidance supplies conventions rather than a single mandatory Word template or a certification for this document. [How to Write Great Documentation to Help with Future Problem Solving](https://admin.salesforce.com/?p=185399).
