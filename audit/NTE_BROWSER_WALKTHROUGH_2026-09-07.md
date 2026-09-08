# NTE exhibitor browser walkthrough — 7 September 2026

The new exhibitor journey reached **Completed** in the MMUAT Master Panel. Its £800 booking and one £50 staff top-up are independently invoiced/paid, the booking has three staff, preparation updates are complete, and Final pack not sent contains the booking. **Thirteen journey emails remain in the owner's inbox.** Actual payment transfers and logo-file delivery were not performed: finance milestones and the logo confirmation were sandbox simulations.

## Authorised scope

The owner requested an exhibitor expression of interest using their Anthrion address, browser-driven invitation/application/conversion/finance/reminder/update steps, and retention of the resulting emails. They subsequently added staff top-up testing. They also confirmed Matthew is no longer on the project and Steven should remain the sandbox creator/owner. This did not authorise genuine legacy-recipient sends, production deployment, Stripe transactions, or removal of the new walkthrough booking.

All applicant workflow mutations were performed through the browser: the public forms, Master Panel, standard Lead conversion, and finance confirmation dialogs. Gmail and Salesforce read-only queries verified outcomes. No API/script created, converted or paid the booking.

## Retained journey

| Item | Value |
| --- | --- |
| Organisation | Anthrion NTE Journey 07 Sep |
| Applicant and primary Contact | Steven Skyba, steven.skyba@anthrion.com |
| Event | NTE2027 |
| Booking reference | `NTE-1788793164136-7MGGTZFU` |
| Expression of interest | `00QAd00000UQg6gMAD` — invitation sent; progressed; now owned by Steven |
| Converted application | `00QAd00000UQsWXMA1` |
| New test Account | `001Ad0000192WHhIAM` |
| New test Contact | `003Ad000019lSnxIAE` |
| Opportunity | `006Ad00000UcnmPIAR` |
| Space | Single paddock-side garage with power, £800 excluding VAT |
| Additional staff | One place, £50 excluding VAT |
| Final staff names | Steven Skyba; Alexandra Example; Samuel Example |
| Final total | £850 excluding VAT |

[Open the booking](https://missionmotorsportnpc--mmuat.sandbox.lightning.force.com/lightning/r/Opportunity/006Ad00000UcnmPIAR/view).

## Observed results

1. Submitted the exhibitor interest. Applicant acknowledgement reached Anthrion. Reviewed the single recipient and exhibitor application URL in the panel before sending the invitation; it arrived and the interest left the open queue.
2. Submitted the paid exhibitor application with bank transfer, quotation and invoice requirements, two initial staff and a heavy-vehicle requirement. Its under-review acknowledgement and internal application notification reached the owner's inbox. The application was owned by Steven.
3. Used standard browser conversion with a new test Account, Contact and Opportunity. The conversion result showed the correct Contact email and £800 amount. The provisional reservation arrived before payment, with the correct organisation/reference, itemised price and all three preparation links.
4. Recorded Quote provided, Booking invoice provided and Booking payment received in that order. The record moved through the corresponding finance refiners. One booking-confirmation email arrived for the exact primary Contact.
5. Sent staff, logistics and logo reminders through their separate Remind All dialogs. Each preview and delivered message contained the correct booking reference, recipient and form destination.
6. Submitted two original staff names and one positive top-up request. Salesforce recorded three total staff, one £50 top-up, a new top-up invoice requirement, and retained the original booking invoice/payment.
7. Recorded Staff top-up invoice provided and Staff top-up payment received through the same combined finance refiners. They showed £50 and did not repeat the original booking payment or confirmation email.
8. Submitted logistics with two items and named haulier staff. The primary Contact and stored event-day/secondary contacts remained unchanged despite different supplementary contact names.
9. Submitted a replacement logistics form with revised first-vehicle details, a different delivery window, no second item and no haulier staff. The first vehicle changed and omitted second-item/haulier-staff values cleared. Unrelated contact/payment data stayed intact.
10. Submitted the logo-confirmation form for this synthetic booking. The external file-upload button was disabled because the client destination is not configured; **no logo file was uploaded**. Only confirmation matching and completion tracking were exercised.
11. Submitted a staff-name correction using the same top-up quantity of one. Corrected names saved. The £50 amount, booking payment time, top-up invoice time and top-up payment time remained unchanged.
12. Submitted an intentional second increase to two top-up places. Salesforce rejected it with “Additional staff can only be requested once for this booking.” No booking data changed; Taylor Example was not added; the accepted top-up stayed one place/£50. The failed submission is retained as Lead `00QAd00000UQtfVMAT`.
13. Refreshed the panel and verified Completed = 1 / 100%, Updates = 0, all outstanding finance refiners = 0, Payment confirmed = 1, Final pack not sent = 1 and Final pack sent = 0. The final pack was not distributed.

The panel's Completed classification is based on its readiness rules. The native Opportunity StageName remains Qualification; this walkthrough did not introduce a change to the separate standard Salesforce sales stage.

## Inbox evidence

Thirteen messages were verified with INBOX labels: interest acknowledgement, application invitation, application acknowledgement, one internal application notification, provisional reservation, one booking confirmation, three reminders, two staff acknowledgements and two logistics acknowledgements. Applicant messages use `steven.skyba@anthrion.com`; the internal application message went to the owner's Salesforce User email `steven.skyba@euroforce.com` and arrived in the same connected inbox. No messages were archived or deleted. Read/unread state was not changed by an explicit mailbox mutation.

Five panel dispatch records are Sent: INVITATION, BOOKING_CONFIRMED, STAFF_DUE, HEAVY_DUE and LOGO_DUE. Every one targets Anthrion, with no recorded dispatch error. Provisional receipt was separately verified in the inbox and booking state. There was no second booking confirmation after top-up payment/correction/rejection.

Raw message IDs, timestamps, recipients and reminder links are in `tmp/nte-browser-walkthrough-20260907/inbox-evidence.json`.

## Findings requiring follow-up

### Staff acknowledgement currency and plain-text presentation

The real exhibitor staff acknowledgement renders **££50.00 + VAT**. The source prepends a literal pound sign to a Salesforce currency merge field that already supplies it: `email-templates/source/exhibitor-staff-update-applicant-confirmation.html`, line 18. The saved monetary values are correct. Its plain-text alternative also concatenates several table labels/values without useful spacing. Both first and corrected-name acknowledgements provide evidence. These presentation defects were identified during testing and have not been changed in this walkthrough.

### Rejected supplementary updates need visible follow-up

The second increase is safely rejected server-side, but the browser still lands on the generic Submission received page. No explanatory rejection email was sent. The retained Lead contains Failed status and the actionable rejection reason. A future refinement should surface failed updates to the team and/or notify the established primary Contact, without claiming a static Web-to-Lead form can synchronously validate live booking state.

### Supplementary audit ownership remains separate

The explicit NTE inbound owner override correctly routed the new application to Steven. Supplementary submission audit Leads bypass that inbound owner assignment and inherited the org's fallback owner, Megan. The retained logo and rejected top-up Leads therefore remain Megan-owned; neither produced an internal notification in this walkthrough. Aligning these audit records with the booking's owner would make failed-update follow-up clearer. This finding does not change the verified primary-Contact routing of the booking emails.

### External logo upload remains untested

The client SharePoint/file-request destination is still absent. The form's confirmation can update Salesforce, but end-to-end file delivery and reconciliation cannot be qualified until the client supplies that destination. Completion in this run includes a deliberately simulated logo confirmation.

## Routing incident and corrective configuration

Before the first EOI submission, Default Lead Creator was changed from Matthew Braun to Steven Skyba through Setup. **Creator and owner are separate settings.** The EOI inherited Megan as its owner and Salesforce accepted an internal EOI notification for Megan (`mg@missionmotorsport.org`). The agent missed this separate ownership setting and disclosed the incident immediately. Delivery to Megan's inbox was not verified; the message cannot be recalled by this task.

Before submitting the application, the explicit NTE routing owner override was set to `steven.skyba@euroforce.com.mmuat`, deployed successfully, and the subsequent application's ownership/internal recipient were verified as Steven. The original EOI was also reassigned to Steven through the browser with the owner-notification checkbox left unchecked. No genuine legacy Account/Contact was used in the test.

## Source and validation

- Routing deployment: `0AfAd00000Soy7KKAR`, Succeeded.
- `npm run validate`: passed.
- Full production-manifest check-only validation in MMUAT: `0AfAd00000SoygoKAB`, 413/413 components and 180/180 tests passed.
- Source hash comparison against the preceding verified release found only `NTE_Routing_Config.Default.md-meta.xml` changed in package source. Browser-only Default Lead Creator and test-record ownership changes are documented above.
- No public form or email-template change was made in this walkthrough; the existing client preview publication remains current. No production deployment occurred.
- `tmp/nte-browser-walkthrough-20260907/assertions.json` records 17 passing evidence checks, including payment-history preservation, contact preservation, one-time top-up rejection, correct reminder dispatches and inbox retention. This is evidence for this journey, not a claim that every possible edge case or production dependency has been tested.

The new booking, its Account/Contact and retained audit records are left available for review. The existing application automatically removes successfully processed temporary staff/logistics Leads after acknowledgement; the agent did not run another dummy cleanup.
