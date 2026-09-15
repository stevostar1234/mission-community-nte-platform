# Workflow

The NTE Management app is the working area for enquiries, applications, bookings, preparation and finance. The Master Panel opens on Interest. Choose the event edition, then work through the relevant queue. Home provides the commercial portfolio. Guests and volunteers have separate intake paths described below.

## Master Panel orientation

The six stage buttons select views; they do not advance a record. One approved booking can appear in Approved, Finances and Updates at the same time. Completed is calculated from the booking's recorded requirements. The numbers are record counts, not a sequence of mutually exclusive funnel totals.

[FIGURE:01]

| Control | Operation and result |
| --- | --- |
| Event code | Limits the panel to one edition, such as NTE2027. The initial selection is the highest available canonical NTEYYYY code. Select an older edition explicitly when reviewing its records. |
| Time | All time, Today, Last 7 days, Last 30 days or Last 90 days. This filters the creation date of the Lead or Opportunity, not its most recent payment or update date. Today begins at the Salesforce user's local midnight; other ranges are rolling periods. |
| Owner | All owners, an active standard user or a queue. Applies to the current record's owner. An application and its converted booking can have different owners. |
| Refresh | Reloads the counts and rows. Returning focus from a conversion or record window also schedules a refresh. Controls are disabled while loading or preparing an email. |
| Interest and Applications | Combine exhibitor and partner / sponsor submissions. The two smaller buttons narrow the selected stage by participant type. Clicking the main stage again restores its combined view. |
| Approved | All in-scope converted bookings, including bookings still awaiting payment or preparation. The displayed word Approved is a panel label; the stored Opportunity Stage can still be Qualification. |
| Finances | All bookings with a quote, invoice or payment requirement or activity, including those already paid. Use its four smaller buttons for the current finance task. |
| Updates | Bookings missing staff details, confirmed vehicle requirements/details or logo confirmation. The three smaller buttons isolate each task. |
| Completed | Bookings with all applicable quote, invoice, payment, staff, logistics and logo requirements satisfied. The percentage is the integer percentage of approved bookings complete. Final-pack delivery is a separate status. |
| Record row | Selects a record and shows its details on the right. Enter or Space works when the row has keyboard focus. Selecting a row does not change Salesforce data. |
| Previous and Next | Moves through 25 records at a time. Rows are ordered by most recent modification, then Salesforce ID. A view exposes its latest 2,000 rows; the displayed total can be larger. Use a report or narrower filters for older records. |
| Open full record | Opens the selected Lead or Opportunity for complete fields, relationships, activities and email recovery. |
| Open global list | Opens the named native Salesforce list view. It is a separate view with its own filters. The panel's event, time and owner choices are not passed to it. |
| View cross-event report | Opens the relevant packaged report. It includes multiple editions; set its native report filters as needed. |
| View Weekly Finance Report | Appears in all finance views. Opens finance records modified in the last seven days. This uses a different date definition from the panel Time filter. |

The top Salesforce bar is standard functionality: App Launcher changes applications; Search searches accessible records; the navigation tabs open their object workspaces. The dropdown beside each object tab gives its native navigation choices. Favorites, Global Actions, Guidance Center, Help, Setup, Notifications and Profile belong to Salesforce. The project adds the NTE app navigation, Home, Master Panel, record-page arrangement, NTE fields, reports and actions explained here. Tasks and Calendar are standard activity workspaces; the project does not implement another task or calendar engine.

## Review expressions of interest

[FIGURE:19]

If the rightmost decision is clipped, scroll the table horizontally to reveal both actions. Send Application opens a draft. Reject opens a confirmation; Cancel leaves the record untouched, while OK records the decision and removes it from active review without deleting the Lead.

[FIGURE:18]

Open Interest, choose the correct participant subtype if needed, select a row and review the organisation, contact, interest detail and preferred contact arrangements in the right-hand panel. Send Application opens a draft for that one Lead. Send to all prepares the matching records across the whole filtered view, rather than only the visible page. More than 500 matches requires narrower filters.

[FIGURE:02]

The composer initially selects eligible recipients. Clear removes the selection; Select all selects every eligible recipient. Tick individual recipients to choose the exact audience. A disabled row shows why it cannot receive this message. Edit Subject and Message, then choose Preview for to inspect a particular recipient's personalised email. The preview expands tokens such as {ContactName}, {Organisation} and {ApplicationLink}. Refresh rechecks the originally loaded records while preserving the edited text and selected IDs that remain eligible. It does not discover newly added records; close and reopen the composer for a new view selection.

Send to N opens a final confirmation, then queues one email request per selected record. Queued means background processing is outstanding. Sent means Salesforce accepted the email, not that the inbox has confirmed delivery. The Lead is marked Progressed only after acceptance. A changed address, changed routing or changed decision can exclude a record at the final check. The accepted invitation uses the reusable exhibitor or partner application URL for the participant type.

Reject asks for confirmation, records Not Progressed and removes the interest from the active queue while retaining the Lead. It sends no rejection email. Interest with an invitation already queued or sent cannot be rejected through this action. The public application URL is reusable; an invitation is not an authentication token or a prerequisite enforced by the application form.

## Review and convert applications

An exhibitor or partner application creates a new Lead, calculates its current price and notifies the configured internal owner. The website displays a receipt page. There is no immediate applicant application-received email in the current implementation. Examine the selected space/packages, planned staff, power, invoice details and price before conversion. Resolve Pricing review required first.

[FIGURE:04]

Convert opens Salesforce's native conversion screen in a separate tab. Choose the intended Account and Contact and create a new Opportunity for this booking. Existing organisations and people may be reused across editions; the booking Opportunity should be new. Review the owner and converted Lead status. Complete Convert only when those selections represent the intended booking.

[FIGURE:05]

The conversion Flow copies the application into the exact converted Opportunity, assigns the NTE Event Opportunity record type and queues its booking email after the transaction commits. It also marks the converted Account and Contact as NTE participants. Closing or cancelling the native conversion screen makes no booking. Returning to the panel refreshes the queues.

The native screen currently permits Don't create an opportunity and choosing an existing Opportunity. Those paths are not guarded by project code: the first bypasses the booking Flow, and the second can replace an earlier booking's application and price fields. Follow the new-Opportunity procedure. The open conversion safeguard decision is recorded in the issues register.

Reject on an application records Application Rejected, retains the Lead and removes it from the active Applications queue. It does not send an email. Conversion, approval and payment are distinct: a converted paid application normally receives a provisional reservation message with preparation links. An eligible charity booking whose total is exactly zero receives a complimentary confirmed message immediately.

## Record finance progress

The four refiners show the next applicable finance work. Amounts displayed in the panel are pounds including VAT. A booking charge and a later staff top-up are stored and recorded separately. In a queue, Amount refers to the charge currently actionable; Payment confirmed shows the combined known booking and top-up amount.

[FIGURE:06]

| Button | Use it when | What is recorded |
| --- | --- | --- |
| Quote provided | The requested quote has actually been supplied. | Quote flag, timestamp and operator name. This unlocks invoice recording when a quote was required. |
| Booking invoice provided | The booking invoice or payment link has actually been supplied. | Base invoice flag, timestamp and operator name. Requires known pricing and any required quote. |
| Booking payment received | Finance has verified the actual base booking payment. | Base payment flag, timestamp and operator name; one booking-confirmation email request is prepared. |
| Staff top-up invoice provided | A separate invoice for the accepted additional places has been supplied. | Top-up invoice flag, timestamp and operator name. The base invoice and any required quote must already be recorded. |
| Staff top-up payment received | Finance has verified the separate top-up payment. | Top-up payment flag, timestamp and operator name. Requires the top-up invoice and completion of the base booking payment. It does not send a second booking confirmation. |

Every milestone button asks for confirmation. It records a fact; it does not create a formal quotation or invoice and does not charge a card. The server rechecks the record before saving. A repeated action cannot replace its original date/operator. A stale action against a cancelled or no-longer-eligible booking is rejected.

[FIGURE:07]

[FIGURE:08]

For Stripe bookings, the background process creates a fixed Payment Link and includes it in the provisional email. Successful acceptance of that email records the base invoice/payment-link milestone, and any requested quote milestone. It does not record payment. Finance compares the booking reference, amount, currency and merchant in Stripe with the saved payment request, then uses Booking payment received. A Stripe receipt and the NTE booking confirmation are separate messages.

A base payment can be recorded while a staff top-up invoice is still outstanding. A free base booking skips only its own finance steps; a positive top-up still needs its own invoice and payment. Unknown pricing never counts as a free booking. If payment is recorded but the confirmation fails, the payment remains recorded; recover the failed email separately.

## Complete staff vehicle and logo preparation

Preparations can be completed before payment. Open Updates to see the combined outstanding work; use Logistics outstanding, Staff updates or Logo updates for a focused list.

[FIGURE:09]

Staff updates shows planned and additional staff. Remind All opens a draft for eligible bookings in the filtered staff queue. Logistics outstanding includes a blank or unrecognised vehicle answer as well as Yes with no completed details; No is already complete for logistics. Logo updates contains bookings whose logo-provided flag is false. Each of these three views has Remind All; the combined Updates view has no bulk reminder because it would mix different requests.

[FIGURE:10]

[FIGURE:11]

All booking reminders go to the unique Primary Contact selected through Opportunity Contact Roles. Event-day contact, billing contact and supplementary form submitter are separate data. The right-hand panel shows the Primary Contact and event-day contact separately. Correct the actual Primary Contact relationship or Contact.Email when needed, then refresh the recipient preview. An outstanding reminder can be sent again in a later, separately reviewed run; the latest successful reminder time is available in the selected booking details.

Partner / sponsor staff form: enter the booking reference, final headcount and one attendee name per line. The headcount and name count must match and be between 1 and 99. A successful update replaces the partner roster and marks staff complete; it creates no extra staff charge.

Exhibitor staff form: enter the names covered by the original booking, one per line. Their number must equal the saved initial allocation. A first positive top-up can purchase 1 to 99 additional places at £50 per place excluding VAT, with a matching list of names. Subsequent submissions can correct names but cannot increase or reduce that accepted top-up quantity. Choosing No on a later correction preserves an already accepted top-up. The combined list becomes the roster; the original booking price and its finance milestones stay intact.

Heavy vehicle form: identify the booking, supply organisation/contact/declaration information, delivery window, item 1 and haulier details. Items 2 and 3 are optional, but any partly supplied item must include description, dimensions and gross weight; item 3 requires item 2. Registrations can be left blank. A valid update replaces the logistics fields, including clearing omitted optional items, sets Heavy Vehicle Required to Yes and stamps logistics complete. It does not replace booking contacts.

Logo form: upload through the configured external file-request destination, then confirm the upload with the booking reference. Confirmation marks Logo Provided and its date. Salesforce does not receive a file attachment or verify the external upload through this form. The current file-request destination is blank, so the external upload link needs configuration before this route can operate as intended. Logo confirmation Leads remain as audit records and receive no acknowledgement email.

Staff and vehicle forms first create a temporary Lead. Matching and application happen asynchronously. A successful receipt goes to the booking's Primary Contact. The temporary Lead is deleted after the details and receipt succeed. Invalid/unmatched submissions or failed receipts remain for review. A website thank-you page alone does not prove that matching or processing succeeded.

## Complete the booking and distribute the final pack

Completed requires known pricing, any requested quote, all applicable base and top-up invoices and payments, staff completion, a confirmed vehicle answer with details when Yes, and Logo Provided. There is no Mark complete button and no requirement to move Opportunity.StageName to Closed Won.

[FIGURE:12]

Final pack not sent excludes Sent and Queued records. Final pack sent shows completed bookings with a sent status. Distribute final pack on Completed or Final pack not sent prepares only completed, unsent eligible bookings, then uses the same recipient-selection and preview process as reminders. A pack already sent is never silently reset when a late top-up reopens finance. That booking may leave Completed until finance is resolved, but retains its pack history.

[FIGURE:13]

The Default routing record must contain the matching Final Pack Event Code and a valid HTTPS exhibitor or partner final-pack URL. Both final-pack URLs are blank in the current configuration. The composer therefore explains the missing link and leaves Send disabled. Supply the final content and destinations in configuration; the feature sends links rather than generating an event-information document.

## Use the event breakdown and guest list

[FIGURE:03]

The event breakdown at the bottom provides clickable summaries for guest registrations, expressions of interest, applications, approved-booking progress, quotes, invoices, payments, logistics, staff and logos. Each opens the corresponding queue. Interest totals include open and decided interests; Applications totals are current awaiting-review applications plus approved bookings. Guest totals are captured registrations, with no application approval stage. Do not add these different populations together as unique people.

Guest registrations remain Leads. The guest list shows the main guest, accompanying guest name/email and accessibility answer. An accompanying guest is stored on the same Lead, not a separate Contact or attendee object. Use the guest check-in/accessibility report for delivery planning and its native filters/export where appropriate. The project does not generate tickets, scan check-ins or implement a separate attendance portal.

## Use Home and understand its values

[FIGURE:14]

Home has an Event selector and Refresh. Its headline amounts are Applications, Approved applications, Invoiced, Still to collect and Paid. All are pounds including VAT and display rounded whole pounds; saved fields retain their decimal precision. Applications covers unconverted, unrejected commercial applications. Approved covers the booking population. Invoiced and Paid include only the charge amounts whose corresponding milestones are recorded; a paid base charge remains in Paid while a top-up is still outstanding. Still to collect includes unpaid billable amounts even before an invoice has been provided, so it can exceed the Payment required queue.

The Commercial pipeline compares counts and values by exhibitor and partner / sponsor. Relative value is against the largest stage value. The rows overlap, so percentages are not conversion rates. Revenue readiness splits amounts by their next finance step. Booking mix includes pending applications plus approved bookings, with counts, amounts and average values by participant type. A pricing-check note identifies records whose value cannot be included reliably.

## Use record pages and recover email failures

[FIGURE:15]

Open full record leads to the app's record page. Details contains the project field groups; the pencil or Edit changes the underlying record. Related contains native related lists and, for Account, Contact and Opportunity, the custom NTE Relationships component. The standard activity publisher provides Email, Log a Call, New Task and New Event. The timeline shows activities such as booking provisional email outcome Tasks. Manual Email does not automatically update NTE dispatch or milestone statuses.

[FIGURE:16]

On an Opportunity, NTE Relationships shows its Account and Contact Roles, identifying the actual Primary Contact. Native Add Contact Roles and Edit Contact Roles maintain that relationship. On an Account, the component lists its NTE Opportunities. On a Contact, it lists NTE bookings connected through Contact Roles. Each list is capped at 200 records. Products, Quotes, Partners, Notes and Files remain standard related lists; the project pricing engine does not create Product2 or OpportunityLineItem records.

[FIGURE:17]

| Recovery control | Record to open | Scope and prerequisites |
| --- | --- | --- |
| Retry booking email | Opportunity action menu | Retries an unsent provisional/complimentary booking email for exactly one converted application and its booking. Pending or Sent is not resent. Repair its recorded failure first. |
| Retry update email | Retained supplementary Lead | Requires Matched and Applied plus failed applicant receipt and a saved matching booking ID. Sends the receipt again without replaying staff, top-up or logistics changes. |
| Retry email | Failed NTE Email Dispatch | Reuses the failed invitation/reminder/final-pack/payment-confirmation request. Accepted requests are not sent again. A changed recipient normally needs a newly reviewed draft; booking-confirmation recovery deliberately permits repair of its current primary recipient. |

Read NTE Approval Email Error on the booking, NTE Email Error on an update Lead or Error on the dispatch before retrying. A missing template, missing Primary Contact, missing URL, changed booking amount or invalid saved reference requires correcting its cause. The retry action reports its result in a toast and refreshes the record. Standard record-page refresh may be needed if the browser cannot refresh the record cache.

NTE Unmatched Updates contains submissions needing matching/validation work. NTE Update Emails Failed contains applied updates whose receipt failed. NTE Email Dispatches and NTE Email Failures expose invitation, reminder, final-pack and booking-confirmation history. Provisional booking emails use the Opportunity status and activity Task instead of a dispatch record. Failed initial NTE/volunteer intake notifications use their Lead status fields and an administrator-invoked service retry; they do not use Retry update email.

## Volunteer applications

The separate Mission Motorsport volunteer form collects the applicant's contact/address/date of birth, emergency contact, service background, opportunities, skills, travel regions, DBS willingness and availability. The applicant opens the September 2026 Code of Conduct, scrolls to its end, ticks its acknowledgement and completes the declaration. One hours choice and either Any availability or selected days are permitted. Submission creates a Volunteer Application Lead and returns to volunteer-thank-you.html. The applicant and current active Lead owner receive separately audited messages. Volunteers are not included in the NTE Master Panel because their intake does not carry an NTE event code. Use the Volunteer Applications list and authorised volunteer field access.

## Changes cancellation and exceptions

Close Date is an expected date, not an expiry timer. Passing it does not cancel a booking or close a Payment Link. Closed Won remains eligible for NTE operations. Closed Lost is excluded from active panel views and blocks new payment-request emails, but existing external links remain open until handled in Stripe. Supplementary updates against a valid cancelled booking are accepted under the confirmed current workflow.

A refund, cancellation or changed commercial amount needs an explicit operational reconciliation. Preserve the original payment request. A saved Stripe net amount that no longer equals the booking blocks the automatic payment-confirmation email even if staff record payment. Use the agreed manual handling and the issues register; do not change an old payment snapshot simply to make an email pass validation.
