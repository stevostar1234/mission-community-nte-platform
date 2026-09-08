# NTE Management app

Last deployment review: 18 August 2026

Salesforce target: Mission Motorsport MMUAT sandbox (`mission-mmuat`)

Application API name: `NTE_Management`

## Purpose

NTE Management is the app-scoped daily workspace for NTE enquiries, applications, participants, bookings, event delivery and follow-up. It is additive: it does not replace or modify the existing Mission Community or prototype applications.

## Navigation and Master Panel

The fixed navigation opens on **Master Panel**, followed by Home, Leads, Accounts, Contacts, Opportunities, Tasks, Calendar, Dashboards, Reports and Forms. Master Panel is the live event workbench and provides:

- dynamic Event code, Time and Owner filters;
- a bottom-of-page event overview table covering guest registrations, expressions of interest, applications, finance, approved bookings, logistics confirmation and staff updates, split into total, in-progress and completed values;
- the Interest → Applications → Approved → Finances → Updates → Completed pipeline;
- combined stage views that open immediately, with centred optional subtype filters for exhibitor and partner/sponsor interest, applications and approvals; quotes required, invoices required, payments required and completed payments; and heavy-vehicle and staff updates;
- a true-completion percentage based on approved bookings that have every applicable quote, invoice, payment, staff and heavy-vehicle milestone complete;
- queue-specific operational tables that remove non-applicable fields and surface the contact, application, finance, staff or vehicle details needed for that queue;
- a Convert action on every unconverted application Lead that opens Salesforce's standard Account, Contact and Opportunity matching screen; returning through the Master Panel navigation reloads all figures;
- paginated record drill-down with contact, booking, readiness and finance details; and
- audited Quote provided, Invoice provided and Payment received milestones in the required order.

The custom home page also provides direct access to:

- applications;
- expressions of interest;
- guest registrations;
- unmatched staff or vehicle updates needing attention;
- confirmed event participation;
- NTE organisations and NTE contacts;
- tasks, calendar, reports, dashboards and the live public-form directory.

The app uses the supplied NTE logo without redrawing it. Its app chrome and custom components use a midnight blue, NTE gold and white palette, with responsive layouts for desktop and mobile.

## App-scoped record pages

The app assigns dedicated Dynamic Forms pages for Lead, Account, Contact and Opportunity on both large and small form factors. These assignments apply only while users work in NTE Management.

Each page uses Salesforce's standard Highlights Panel action source. This preserves the actions configured on the assigned page layout—including Convert on unconverted Leads and Edit, Delete, Clone and other applicable record actions—while respecting each user's permissions. New remains available from the corresponding object list view.

- **Lead:** submission status, person and organisation, contact preferences, enquiry or application details, guest information, invoicing, logistics, update processing, activities and related records.
- **Opportunity:** booking and commercial details, primary and secondary contacts, sponsorship, exhibition, stand and staff requirements, invoicing, heavy-vehicle logistics, update audit, activities and related records.
- **Account:** NTE classification and traceability, organisation details, activities, contacts, opportunities and other configured related lists.
- **Contact:** NTE classification and event role, contact and address details, activities, account, opportunities and other configured related lists.

## Classification and list views

Converted Exhibitor and Partner / Sponsor applications now classify the resulting Account and Contact automatically. The conversion flow writes the NTE participant flag, event code, source form, booking reference and latest application date; Contact also records the event role.

The package provides:

- **NTE Organisations** on Account;
- **NTE Contacts** on Contact;
- the existing NTE Lead queue views; and
- **NTE Event Participation** on Opportunity.

It also provides Opportunity list views for Quotes required, Invoices required, Payments due, Heavy vehicle updates due and Staff updates due. Staff and heavy-vehicle form processing stamps completion timestamps on the booking so Master Panel and the operational reports use the same evidence.

The idempotent post-deployment backfill classified 11 retained Accounts and 11 retained Contacts created by earlier NTE conversions. It performed 22 updates and no deletes.

## Access model

`NTE_Management_User` exposes the application, its tabs and the NTE classification fields. It was assigned to all 10 active human CRM users in MMUAT: four Standard Users and six System Administrators.

The permission set deliberately does not grant new Account, Contact, Lead or Opportunity CRUD or sharing access. Existing profiles, permission sets, ownership and sharing rules continue to determine which records each person can read or change. Guest, automated-process, Chatter-only and machine integration identities cannot use this CRM Lightning app and were not assigned it.

## Deployment and verification

- Successful full deployment: `0AfAd00000SQzkTKAT`
- Components: 177 of 177
- Local org tests: 57 of 57 passed
- Component errors: 0
- Test errors: 0
- App menu verification: `NTE Management` is visible
- Permission assignments verified: 10 active human CRM users
- NTE classifications verified: 11 Accounts and 11 Contacts
- Account and Contact list-view records verified through the Salesforce API
- Local metadata generation and static tests: `npm run validate`

Master Panel was deployed additively on 17 August 2026:

- Successful scoped deployment: `0AfAd00000SSEMUKA5`
- Components: 20 of 20
- Apex tests: 10 of 10 passed
- Component errors: 0
- Test errors: 0
- Controller coverage: 375 of 416 lines (90.1%)
- Live NTE2027 reconciliation: 47 submitted, 15 confirmed, 14 in progress and 1 complete (6%)
- Queue reconciliation: 3 quotes required, 14 invoices required, 0 payments due, 1 heavy update, 7 staff updates, 6 applications for review, 6 expressions of interest, 20 guests and 62 most recent records
- Browser verification: all core views, empty state, record detail and drill-down destinations passed with no console errors
- Permission verification: all 10 active human CRM users retain `NTE_Management_User`

The 17 August UX refinement was deployed additively without deleting or replacing other teams' metadata:

- Controller, test and Lightning component deployment: `0AfAd00000SSoZdKAL`
- Apex tests: 5 of 5 passed; controller coverage 459 of 494 lines (92.9%)
- Record-icon presentation deployment: `0AfAd00000SSkuEKAT`
- Contextual queue-action deployment: `0AfAd00000SSiu4KAD`
- Browser verification: queue-specific columns, amounts, light operations rail, standalone record icons and bottom event overview passed
- Refresh behaviour: dashboard reads are imperative and non-cacheable; a successful milestone reloads all queue, pipeline and overview data together

The selected stage-navigation design was deployed additively on 17 August 2026:

- Controller, tests and Lightning component deployment: `0AfAd00000ST6rVKAT`
- Final Lightning styling deployment: `0AfAd00000ST7FhKAL`
- Apex tests: 9 of 9 passed; component errors: 0; test errors: 0
- Live NTE2027 verification: 6 interest, 6 applications, 15 approved, 12 finance actions, 7 updates and 3 fully completed bookings (20%)
- Main stages load combined records immediately; optional centred subtype selectors contain no redundant combined option
- Completion now requires the quote when requested, invoice and payment when billable, staff update, and heavy-vehicle update when required
- Browser verification covered all six main stages and every subtype selector; no application console errors were present

The finance reconciliation, completion rules and native Salesforce Path refinement were deployed additively on 18 August 2026:

- Controller, tests and Lightning component deployment: `0AfAd00000ST8OgKAL`
- Final selected-stage presentation deployment: `0AfAd00000STAa9KAH`
- Apex tests: 13 of 13 passed; component errors: 0; test errors: 0
- Live NTE2027 path: 6 interest, 6 applications, 15 approved, 14 distinct finance records, 9 updates and 2 fully completed bookings (13%)
- Finance overview: 3 quotes = 1 open + 2 provided; 14 invoices = 10 open + 4 provided; 4 payments = 2 due + 2 paid
- Finance refiners: 1 quote required, 10 invoices required, 2 payments required and 2 completed payments. They are non-additive because the same booking can appear in more than one milestone view.
- Completion treats null or `Not known yet` logistics as outstanding and requires a heavy-vehicle update when vehicles are confirmed
- Stage navigation uses the official Salesforce Lightning Design System Path blueprint and was verified without overlap at a 1082 × 904 authenticated browser viewport
- Local metadata generation and form tests: `npm run validate` passed

Application conversion was added to Master Panel on 18 August 2026:

- Lightning component deployment: `0AfAd00000STnEvKAL`
- Application rows use Convert instead of Open and retain Open full record in the selected-record panel
- Conversion uses Salesforce's standard matching screen rather than automatically creating duplicate Accounts or Contacts
- Returning through the persistent Master Panel navigation triggers a full non-cacheable dashboard reload
- Apex test run `707Ad00001NwCOj`: 15 of 15 passed, including an isolated Lead conversion proving the application count decreases and the approved Opportunity metrics increase; test-run coverage 89%
- Live browser verification opened the native conversion screen from an Application row without submitting or changing a sandbox record

The deployed metadata compiled successfully in Salesforce. The public form journeys were visually reviewed at desktop and mobile widths; evidence is retained under `audit/ux-2026-08-17/`. Salesforce Lightning visual acceptance still requires a user with an authenticated MMUAT browser session.

## Safe maintenance

Regenerate metadata with `npm run build` and validate with `npm run validate` before deploying. The app's assignments are intentionally scoped to `NTE_Management`; preserve that scope when changing record pages so other administrators' applications remain unaffected.

The classification backfill is at `scripts/post-deploy/backfill-nte-participant-classification.apex`. It is repeatable and update-only.

The Master Panel milestone backfill is at `scripts/backfill-master-panel-milestones.apex`. It is idempotent, update-only and restricted to the documented MMUAT release-qualification bookings. `scripts/verify-master-panel.apex` is read-only and reconciles the summary, pipeline and queue counts without changing records.
