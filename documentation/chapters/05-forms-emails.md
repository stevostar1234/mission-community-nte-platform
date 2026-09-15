# Public forms and email presentation

## Form engine and submission contract

Every public form loads assets/config.js before assets/forms.js. window.NTE_CONFIG is the active configuration; NTE27_CONFIG is retained as an alias. The engine discovers form[data-web-to-lead] and controls marked data-sf-field. Ten pages submit; staff-update.html is a chooser, not an eleventh intake route. Supporting index, thank-you, volunteer-thank-you, code-of-conduct and preview pages do not create records by themselves.

The engine collects only enabled, nonempty controls and selected checkboxes/radios. Values are trimmed and multiple values for one Salesforce field are joined with semicolons. Terms_and_Conditions__c uses 1 for a selected checkbox. Standard mappings are Company→company, FirstName→first_name, LastName→last_name, Email→email, Phone→phone, MobilePhone→mobile, Title→title, Website→URL, Salutation→salutation, Street→street and PostalCode→zip. Custom fields use the target-org 00N IDs in customFieldIds, not their API names in the HTTP form body.

submitToSalesforce creates a hidden POST form with oid, retURL, lead_source and useDefaultRule, then native submit navigates to Salesforce. Current public pages explicitly set useDefaultRule=0. This does not suppress native Lead auto-response rules. No fetch callback receives a definitive Lead/application/update processing result. The return page is therefore a receipt screen, not proof of conversion, successful matching or accepted email delivery.

Mode review validates and shows the page's local confirmation preview without a network submission. Sandbox mode still submits to the configured endpoint and org. Any other non-review mode also uses the configured POST path; endpoint/org IDs determine the actual target. Missing endpoint/org/return destination, required terms destination or used custom field mapping blocks submission with an actionable unavailable message.

## Conditional controls and derived values

data-conditional-for names the controlling DOM ID; data-conditional-value accepts pipe-separated matching values and defaults to Yes. Hidden sections disable their own controls and data-required-when-visible makes them required only when shown. Nested conditions respect their parent's visibility. Disabled stale values are excluded from the outgoing payload.

data-combine-fields joins named controls with spaces, data-copy-value-from copies one control, data-checkbox-copy-from converts a checkbox/Yes answer to 1, and data-switch-copy chooses the relevant source set based on a Yes/No control. These support applicant/event-day contact selection, split names and hidden derived roster fields. syncFormState re-runs conditions and calculations immediately before validation/POST, normalises number inputs, copies derived fields and uppercases references. pageshow restores submit controls and recalculates state when returning from a native submission.

Standard and custom length limits match configured Salesforce lengths. Declaration dates range from 2026-01-01 through today's London date; date of birth ranges from 1900-01-01 through today. DMY mode converts browser YYYY-MM-DD values to DD/MM/YYYY for the current Web-to-Lead creator locale. Date format must be aligned with the destination org's creator locale during reconstruction. The browser validates calendar dates, required nonblank text, selected checkbox groups, known catalogue choices, reference grammar and form-specific roster/item rules.

The reference grammar is ^NTE-[A-Z0-9][A-Z0-9-]{1,74}[A-Z0-9]$. Main applications generate references; supplementary forms require the reference from the booking email. A hidden honeypot rejects filled automated submissions locally and a submitting flag prevents repeat clicks during navigation. These controls do not make Web-to-Lead an authenticated endpoint; server pricing, creation resets and update matching enforce the project's data rules.

## Form route catalogue

[FORMS_OVERVIEW]

Each form's complete control-to-field mapping, required conditions, option values and fixed hidden values appears in the form reference. Those details are part of the build specification: fields present in Salesforce but absent from a current form can be legacy retained fields or internal audit/derived values. Do not add every field to the public page merely because it exists in the dictionary.

Partner applications allow multiple packages and an event-day contact differing from the applicant. Exhibitor applications enforce one space and category eligibility, derive included/additional staff and invoice requirement, and show a separate savings explanation for qualifying space/power discounts. Invoice sections collect the legal billing organisation, trading name, billing address/contact, procurement answers, PO number where supplied and additional information. These values support the manual invoice process; the application does not create an invoice record.

Guests use one Lead for the main and optional accompanying guest, with conditional accessibility details. Volunteers use LeadSource=Volunteer Application and a hidden Company value, volunteer-specific source/version fields and no NTE_Event_Code__c. The volunteer Code of Conduct reader uses the September 2026 document version; only reaching the end of the opened rendered reader enables acknowledgement. Volunteer_Code_Required validates new v3 applications for the corresponding acknowledgement/version. Historical applications remain editable without retroactive acknowledgement.

The Code of Conduct text is maintained in config/volunteer-code-of-conduct.json. Paragraph order and list structure are preserved; eight paper-signature paragraphs marked omitFromReader are excluded from the online reader while digital declaration controls remain. The current HTML embeds that content; the main metadata build consumes its version for Salesforce validation but is not a general form-page generator.

## Stored and preview emails

The nineteen stored templates comprise seventeen NTE and two volunteer templates. The retired exhibitor/partner application-received templates are absent from the active source/manifest. The generic NTE_Staff_Update_Acknowledgement template remains as a legacy retained template; the active split staff routes use their specific exhibitor and partner templates.

[EMAIL_CATALOGUE]

email-templates/source contains the maintained HTML presentation sources. scripts/build-metadata.js compiles them into Salesforce email resources and text alternatives under force-app/main/default/email/unfiled$public, and builds recipient-facing examples under email-templates/examples. Additional Stripe preview variants are examples of conditional booking rendering; they are not separate Salesforce EmailTemplate records.

scripts/email-template-presentation.js compiles three authoring conventions. NTE_GREETING chooses a first-name greeting or a neutral greeting when blank. data-nte-optional hides a table row only when all its merge fields are blank. data-nte-join suppresses separators when one joined value is absent. Native merge values remain ordinary Salesforce fields; the compiler does not interpolate recipient data into formula string literals. nativeEmailTextFromHtml preserves line breaks outside Salesforce formula literals.

Classic currency merge fields already include the currency symbol. The template must not prepend a second pound sign; currencyPreview reproduces that behaviour in examples. Long text and partial optional contact/billing values retain their meaningful lines. The plain-text generator removes layout-only text and preserves usable URLs. The booking renderer separately replaces finance/payment/preparation comment tokens after Salesforce renders Contact/Opportunity merge fields.

Recipient language follows the participant route. EOI acknowledgement confirms interest; invitations request an application; paid booking conversion is provisional; eligible zero-charge charity conversion is confirmed; first recorded base payment sends the correct exhibitor or partner payment confirmation; supplements acknowledge the saved details; reminders request only the outstanding item. Final-pack emails provide the configured event-information destination. The final-pack and reminder composer uses generated subject/body content rather than an EmailTemplate record.

## Native delivery setup that changes this project

The active overlapping volunteer auto-response entry in MMUAT was disabled by setting its formula to FALSE while preserving its surrounding entries, sender and template. This prevents duplicate volunteer applicant acknowledgements now that VolunteerInboundLeadService sends them. On another org, inspect the actual matching rule and Web-to-Lead Default Response Template; do not overwrite the whole native auto-response container from the sandbox.

The two packaged duplicate rules separate Customer Event submissions from other Leads. NTE_Web_to_Lead_Duplicate_Report allows and reports a Contact match for Customer Event. Standard_Rule_for_Leads_with_Duplicate_Contacts is filtered to LeadSource not equal to Customer Event and retains its standard alert/report behaviour. Both reference Standard_Contact_Match_Rule_v1_1 with explicit Lead-to-Contact field mapping. This permits an existing person to submit a new NTE event/application/update while retaining duplicate information; it does not merge duplicate submissions.

Default Lead Creator, Default Lead Owner, notify-owner configuration, verified senders and overlapping native automations remain target-org setup. Their exact effect matters to internal notifications and date parsing. The maintained package does not contain profiles, assignment-rule or whole auto-response-rule replacements. Its current routing usernames and public field IDs are sandbox values to be mapped during installation.
