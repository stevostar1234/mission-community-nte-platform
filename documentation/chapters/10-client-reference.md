# Form and Lightning component reference

The form specifications below include every Salesforce-mapped control, fixed hidden value, conditional requirement and option set extracted from the current HTML. Controls sharing one field are grouped; checkbox selections post semicolon-separated values. A missing HTML value attribute on an option means its text is the native submitted value. Numeric ranges are shortened only when the set is consecutive.

## exhibitor application

Source: exhibitor-application.html. Form configuration: class=main-column; data-web-to-lead=; data-form-kind=exhibitor; data-lead-source=Customer Event; data-use-default-rule=0; data-confirmation-preview=Thank you. We have received your NTE27 exhibitor application. The NTE team will review it and contact you with the outcome..

Section order: Join us at NTE27 → 1 Organisation → 2 Main contact → 3 Previous NTE events → 4 Exhibition space → Select one space → 5 Power and booking total → 6 Operations and accessibility → 7 Quotation and invoicing → 8 Final details and declaration → Application and confirmation emails.


| Salesforce Lead field | Control and exact input contract |
| --- | --- |
| Logo_Upload_URL__c | type=hidden |
| Web_Form_Type__c | type=hidden; value=Exhibitor Application |
| Form_Version__c | type=hidden; value=exhibitor-application-v10 |
| NTE_Event_Code__c | type=hidden |
| Booking_Reference__c | type=hidden |
| Event_Contact_Name__c | type=hidden; data-combine-fields=contact-first-name,contact-last-name |
| Event_Contact_Email__c | type=hidden; data-copy-value-from=email |
| Event_Contact_Title__c | type=hidden; data-copy-value-from=job-title |
| Sponsor_Package_Total__c | type=hidden; value=0 |
| Exhibitor_Space_Price__c | type=hidden; value=0 |
| Power_Socket_Unit_Price__c | type=hidden; value=0 |
| Power_Socket_Total__c | type=hidden; value=0 |
| Additional_Staff_Unit_Price__c | type=hidden; value=0 |
| Additional_Staff_Total__c | type=hidden; value=0 |
| Included_Staff_Count__c | type=hidden; value=0 |
| Total_Staff_Count__c | type=hidden; data-copy-value-from=planned-count |
| Additional_Staff_Required__c | type=hidden; value=No |
| Additional_Staff_Count__c | type=hidden; value=0 |
| Listed_Price_Total__c | type=hidden; value=0 |
| Pricing_Status__c | type=hidden; value=Calculated |
| Pricing_Version__c | type=hidden; value=NTE27-2026-09-10 |
| Invoice_Required__c | id=invoice-required; type=hidden; value=No |
| Company | Organisation name as it should appear in marketing. id=company; required=true |
| Exhibitor_Organisation_Category__c | Organisation category. id=organisation-category; required=true. Options: Employer - Automotive Sector; Employer - Manufacturing Sector; Employer - Renewable & Clean Energy Sector; Employer - Defence → Employer - Defence & Security; Employer - Built Environment; Employer - Facilities Management; Employer - Financial and Professional Services; Employer - Digital & Technologies; Employer - Training Provider from any industry; Employer - Landbased industry; Employer - Blue Light & NHS; Employer - Other Sectors not denoted above; Government or Government Agency; Local Government or LG related; Regular or Reserve Services, or Cadets; Trade Association; Charity - member of Cobseo; Charity - not a member of Cobseo; CIC or Not for Profit. |
| Website | Organisation website. id=website; type=url |
| Salutation | Title / prefix. id=salutation. Options: Mr.; Ms.; Mrs.; Dr.; Prof.; Mx.. |
| FirstName | First name. id=contact-first-name; required=true |
| LastName | Surname. id=contact-last-name; required=true |
| Title | Job title. id=job-title; required=true |
| Email | Email address. id=email; type=email; required=true |
| Event_Contact_Mobile__c | Mobile phone. id=mobile; type=tel; required=true |
| Phone | Landline or work phone. id=phone; type=tel; required=true |
| Secondary_Contact_Prefix__c | Prefix. id=second-prefix; visible only when second-contact-toggle in Yes |
| Secondary_Contact_Name__c | Full name. id=second-name; visible only when second-contact-toggle in Yes |
| Secondary_Contact_Title__c | Job title. id=second-title; visible only when second-contact-toggle in Yes |
| Secondary_Contact_Email__c | Email. id=second-email; type=email; visible only when second-contact-toggle in Yes |
| Secondary_Contact_Mobile__c | Mobile phone. id=second-mobile; type=tel; visible only when second-contact-toggle in Yes |
| Secondary_Contact_Phone__c | Work phone. id=second-phone; type=tel; visible only when second-contact-toggle in Yes |
| Previous_NTE_Events__c | NTE24. id=nte2024; type=checkbox; value=NTE2024<br>NTE25. id=nte2025; type=checkbox; value=NTE2025<br>NTE26. id=nte2026; type=checkbox; value=NTE2026 |
| Planned_Exhibitor_Count__c | How many people do you currently plan to bring, including yourself?. id=planned-count; type=number; required=true; min=1; max=99; step=1 |
| Exhibitor_Space_Selections__c | name=exhibitor-space; type=radio; value=Garage Space - reduced size with power - £599 + VAT; required=true<br>name=exhibitor-space; type=radio; value=Single Garage - Paddock Side with power - £799 + VAT<br>name=exhibitor-space; type=radio; value=Double Garage - Paddock Side with power - £1,299 + VAT<br>name=exhibitor-space; type=radio; value=Single Garage - Track Side - £799 + VAT<br>name=exhibitor-space; type=radio; value=Double Garage - Track Side - £1,299 + VAT<br>name=exhibitor-space; type=radio; value=Clean Energy Zone - Single - £499 + VAT<br>name=exhibitor-space; type=radio; value=Clean Energy Zone - Double - £849 + VAT<br>name=exhibitor-space; type=radio; value=Built Environment Zone - Single - £499 + VAT<br>name=exhibitor-space; type=radio; value=Built Environment Zone - Double - £849 + VAT<br>name=exhibitor-space; type=radio; value=Manufacturing Zone - Single - £499 + VAT<br>name=exhibitor-space; type=radio; value=Manufacturing Zone - Double - £849 + VAT<br>name=exhibitor-space; type=radio; value=Defence & Security Zone - Single - £499 + VAT<br>name=exhibitor-space; type=radio; value=Defence & Security Zone - Double - £849 + VAT<br>name=exhibitor-space; type=radio; value=Digital and Technologies Zone - Single - £499 + VAT<br>name=exhibitor-space; type=radio; value=Digital and Technologies Zone - Double - £849 + VAT<br>name=exhibitor-space; type=radio; value=FM Zone - Single - £499 + VAT<br>name=exhibitor-space; type=radio; value=FM Zone - Double - £849 + VAT<br>name=exhibitor-space; type=radio; value=Professional & Financial Zone - Single - £499 + VAT<br>name=exhibitor-space; type=radio; value=Professional & Financial Zone - Double - £849 + VAT<br>name=exhibitor-space; type=radio; value=Training & Education Zone - Single - £499 + VAT<br>name=exhibitor-space; type=radio; value=Any other business - Single - £499 + VAT<br>name=exhibitor-space; type=radio; value=Any other business - Double - £849 + VAT<br>name=exhibitor-space; type=radio; value=Local Government Authority - Single - £249.50 + VAT<br>name=exhibitor-space; type=radio; value=Blue Light - Single - £249.50 + VAT<br>name=exhibitor-space; type=radio; value=Trade Association - Single - £499 + VAT<br>name=exhibitor-space; type=radio; value=COBSEO Charity - Single - Free<br>name=exhibitor-space; type=radio; value=Non COBSEO Charity - Single - Free |
| Stand_Power__c | Yes. id=power-required-yes; name=power-required; type=radio; value=Yes; required=true<br>No. name=power-required; type=radio; value=No |
| Power_Socket_Count__c | Number of sockets. id=power-count; type=number; min=1; max=20; data-required-when-visible=true; visible only when power-required-yes in Yes |
| Exhibitor_Hall_Schedule__c | For garage exhibits and large stands in the halls, setting up between 14:00-18:00 hrs on Sunday is required. Please indicate you are able to do this.. id=sunday-setup. Options: Yes; No. |
| Stand_Equipment__c | Equipment beyond display stands and laptops. id=equipment; required=true |
| Heavy_Vehicle_Required__c | Will you bring cars, tractors or heavy items that need to be dropped off on a flatbed or trailer?. id=heavy-vehicle; required=true. Options: Yes; No; Not known yet. |
| Has_Special_Requirements__c | Do you have any accessibility requirements?. id=accessibility; required=true. Options: Yes; No. |
| Stand_Special_Requirements__c | Please tell us what you need. id=accessibility-details; data-required-when-visible=true; visible only when accessibility in Yes |
| Quote_Required_for_PO__c | Do you require a quotation before an invoice can be raised?. id=quote-for-po; required=true. Options: Yes; No. |
| Payment_Method__c | Do you require an invoice to be raised, or will you make payment by Stripe?. id=payment-method. Options: Bank transfer → Yes — invoice and payment by bank transfer; Stripe → No — payment will be via Stripe. |
| Purchase_Order__c | Do you require a purchase order or reference before an invoice can be issued?. id=purchase-order; data-required-when-visible=true; visible only when invoice-required in Yes. Options: Yes; No. |
| Purchase_Order_Number__c | Purchase order or reference details. id=purchase-order-number; data-required-when-visible=true; visible only when invoice-required in Yes AND purchase-order in Yes |
| Supplier_Agreement_Required__c | Will a supplier agreement be required?. id=supplier-agreement; data-required-when-visible=true; visible only when invoice-required in Yes. Options: Yes; No; Don't know. |
| Invoiced_Company__c | Legal organisation name for quotation and invoicing. id=invoice-company; data-required-when-visible=true; visible only when invoice-required in Yes |
| Trading_Name__c | Trading name, if different. id=trading-name; visible only when invoice-required in Yes |
| Invoice_Address__c | Billing address, including postcode. id=invoice-address; data-required-when-visible=true; visible only when invoice-required in Yes |
| Invoiced_Person__c | Finance contact name. id=invoice-person; data-required-when-visible=true; visible only when invoice-required in Yes |
| Invoiced_Email__c | Finance contact email address. id=invoice-email; type=email; data-required-when-visible=true; visible only when invoice-required in Yes |
| Invoice_Contact_Phone__c | Finance contact telephone number. id=invoice-phone; type=tel; data-required-when-visible=true; visible only when invoice-required in Yes |
| Invoice_Additional_Information__c | Additional quotation or invoice information. id=invoice-additional-information; data-required-when-visible=true; visible only when invoice-required in Yes AND invoice-additional-required in Yes |
| Industry_Body_Details__c | Industry body or trade association membership. id=industry-body; required=true |
| Event_Discovery_Source__c | How did you hear about NTE27?. id=discovery; required=true. Options: Previous exhibitor; E-mail invitation; Word of mouth from previous exhibitor; Word of mouth from previous attendees; Website; LinkedIn; Facebook; Instagram. |
| Declaration_Name__c | Digital signature (full name). id=declaration-name; required=true |
| Declaration_Date__c | Date. id=declaration-date; type=date; required=true |
| Terms_and_Conditions__c | I have read and agree to the NTE27 Privacy Policy .. id=terms; type=checkbox; required=true |



Additional controls drive visibility, derived values, acknowledgements or submission without posting their own Salesforce field.


| Control | Behaviour attributes |
| --- | --- |
| Add a second contact person | id=second-contact-toggle; type=checkbox  |
| Is there any additional information that must appear on the quotation or invoice? | id=invoice-additional-required; data-required-when-visible=true Options: Yes; No. |
| Submit exhibitor application | type=submit  |



## exhibitor interest

Source: exhibitor-interest.html. Form configuration: class=main-column; data-web-to-lead=; data-lead-source=Customer Event; data-use-default-rule=0; data-confirmation-preview=Thank you. We have received your NTE27 exhibitor expression of interest. The NTE team will review it and contact you about the next step..

Section order: About this form → 1 Organisation and contact → 2 Sponsorship and activities → Are you interested in Sponsorship Opportunities? → 3 Follow-up → Messages sent after submission.


| Salesforce Lead field | Control and exact input contract |
| --- | --- |
| Web_Form_Type__c | type=hidden; value=Exhibitor Expression of Interest |
| Form_Version__c | type=hidden; value=exhibitor-interest-v3 |
| NTE_Event_Code__c | type=hidden |
| Company | Organisation name. id=exhibitor-interest-company; required=true |
| Organisation_Type__c | Organisation type. id=exhibitor-interest-type; required=true. Options: Charity - COBSEO member; Charity - Non COBSEO member; Government Department or Agency; Industry Body / Trade Association; Employer - Automotive; Employer - Clean Energy; Employer - Blue Light Services / NHS; Employer - Built Environment; Employer - Manufacturing; Employer - Defence and Security; Employer - Financial and Professional Services; Employer - Digital and Technologies; Employer - Training and Education; Employer - Land-based; Employer - Other sector. |
| Website | Website. id=exhibitor-interest-website; type=url |
| FirstName | First name. id=exhibitor-interest-first-name; required=true |
| LastName | Surname. id=exhibitor-interest-last-name; required=true |
| Title | Job title. id=exhibitor-interest-title; required=true |
| Email | Email address. id=exhibitor-interest-email; type=email; required=true |
| Phone | Telephone number. id=exhibitor-interest-phone; type=tel; required=true |
| Exhibitor_Interest_Detail__c | Yes. name=exhibitor-sponsorship-interest; type=radio; value=Yes; required=true<br>No. name=exhibitor-sponsorship-interest; type=radio; value=No<br>Maybe. name=exhibitor-sponsorship-interest; type=radio; value=Maybe |
| Exhibitor_Community_Contribution__c | We work with a number of organisations that host value-adding activities such as workshops and skills advice at NTE. Is this something you could offer the event?. id=exhibitor-value-adding-activities |
| Preferred_Contact_Method__c | Preferred contact method. id=exhibitor-contact-method; required=true. Options: Email; Telephone; Video call; No preference. |
| Preferred_Contact_Time__c | Best time to contact you. id=exhibitor-contact-time |
| Event_Discovery_Source__c | How did you hear about NTE27?. id=exhibitor-interest-discovery; required=true. Options: Previous NTE event; NTE webinar or brochure; Email invitation; Recommendation or word of mouth; National Transition Event website; Mission Community website; LinkedIn; Other social media; Other. |
| Contact_Consent__c | I agree that Mission Community may contact me about exhibiting at NTE27.. id=exhibitor-interest-consent; type=checkbox; value=Yes; required=true |
| Declaration_Name__c | Digital signature (full name). id=exhibitor-interest-signature; required=true |
| Declaration_Date__c | Date. id=exhibitor-interest-signature-date; type=date; required=true |



Additional controls drive visibility, derived values, acknowledgements or submission without posting their own Salesforce field.


| Control | Behaviour attributes |
| --- | --- |
| Submit expression of interest | type=submit  |



## exhibitor staff update

Source: exhibitor-staff-update.html. Form configuration: class=main-column; data-web-to-lead=; data-form-kind=exhibitor-staff-update; data-lead-source=Customer Event; data-use-default-rule=0; data-confirmation-preview=Thank you. We have received your exhibitor staff details..

Section order: Before you begin → 1 Find your booking → 2 Names covered by your booking → 3 Additional top-up places → Staff details acknowledgement.


| Salesforce Lead field | Control and exact input contract |
| --- | --- |
| Web_Form_Type__c | type=hidden; value=Exhibitor Staff Update |
| Form_Version__c | type=hidden; value=exhibitor-staff-update-v1 |
| Staff_Update_Audience__c | type=hidden; value=Exhibitor |
| NTE_Event_Code__c | type=hidden |
| Total_Staff_Count__c | id=exhibitor-base-count; type=hidden |
| Planned_Exhibitor_Count__c | type=hidden; data-copy-value-from=exhibitor-base-count |
| Staff_Base_Names__c | type=hidden; data-copy-value-from=exhibitor-staff-names |
| Top_Up_Staff_Unit_Price__c | type=hidden; value=50 |
| Top_Up_Staff_Total__c | type=hidden; value=0 |
| Company | Organisation name. id=exhibitor-staff-company; required=true |
| FirstName | Your first name. id=exhibitor-staff-first-name; required=true |
| LastName | Your surname. id=exhibitor-staff-last-name; required=true |
| Email | Your email address. id=exhibitor-staff-email; type=email; required=true |
| Target_Booking_Reference__c | Booking reference. id=exhibitor-staff-reference; required=true; pattern=NTE-[A-Za-z0-9][A-Za-z0-9\-]{1,74}[A-Za-z0-9] |
| Top_Up_Staff_Required__c | Do you want to purchase any additional staff places?. id=top-up-required; required=true. Options: Yes; No. |
| Top_Up_Staff_Count__c | Total number of top-up staff places required. id=top-up-count; type=number; min=1; max=99; step=1; data-required-when-visible=true; visible only when top-up-required in Yes |
| Top_Up_Staff_Names__c | Names for the top-up places. id=top-up-names; data-required-when-visible=true; visible only when top-up-required in Yes |
| Declaration_Name__c | Digital signature (full name). id=exhibitor-staff-signature; required=true |
| Declaration_Date__c | Date. id=exhibitor-staff-date; type=date; required=true |



Additional controls drive visibility, derived values, acknowledgements or submission without posting their own Salesforce field.


| Control | Behaviour attributes |
| --- | --- |
| Names of staff already covered by your booking | id=exhibitor-staff-names; required=true  |
| Submit staff details | type=submit  |



## guest registration

Source: guest-registration.html. Form configuration: class=main-column; data-web-to-lead=; data-form-kind=guest; data-lead-source=Customer Event; data-use-default-rule=0; data-confirmation-preview=Thank you. We have received your NTE27 guest registration. The event team will send further information closer to the event..

Section order: 1 Your details → 2 Anyone accompanying you → 3 Accessibility → Registration emails.


| Salesforce Lead field | Control and exact input contract |
| --- | --- |
| Web_Form_Type__c | type=hidden; value=Guest Registration |
| Form_Version__c | type=hidden; value=guest-registration-v3 |
| NTE_Event_Code__c | type=hidden |
| Accompanying_Guest_Name__c | type=hidden; data-combine-fields=guest-companion-first-name,guest-companion-last-name |
| FirstName | First name. id=guest-first-name; required=true |
| LastName | Surname. id=guest-last-name; required=true |
| Email | Email address. id=guest-email; type=email; required=true |
| Phone | Phone number. id=guest-phone; type=tel; required=true |
| Company | Organisation. id=guest-organisation; required=true |
| Title | Job title. id=guest-title |
| Guest_Accompanying__c | Will anyone be accompanying you?. id=guest-accompanying; required=true. Options: Yes; No. |
| Accompanying_Guest_Email__c | Email address. id=guest-companion-email; type=email; data-required-when-visible=true; visible only when guest-accompanying in Yes |
| Guest_Accessibility_Required__c | Do you or anyone in your party have accessibility needs so we can make appropriate arrangements?. id=guest-accessibility; required=true. Options: Yes; No. |
| Guest_Accessibility_Details__c | Please tell us what arrangements would help. id=guest-accessibility-details; data-required-when-visible=true; visible only when guest-accessibility in Yes |
| Guest_Information_Declaration__c | I confirm that these details are accurate and, where I have provided another person's details, I have their permission to do so.. id=guest-declaration; type=checkbox; value=Yes; required=true |
| Declaration_Name__c | Digital signature (full name). id=guest-signature; required=true |
| Declaration_Date__c | Date. id=guest-signature-date; type=date; required=true |



Additional controls drive visibility, derived values, acknowledgements or submission without posting their own Salesforce field.


| Control | Behaviour attributes |
| --- | --- |
| First name | id=guest-companion-first-name; maxlength=40; data-required-when-visible=true  |
| Surname | id=guest-companion-last-name; maxlength=80; data-required-when-visible=true  |
| Submit guest registration | type=submit  |



## heavy vehicle details

Source: heavy-vehicle-details.html. Form configuration: class=main-column; data-web-to-lead=; data-lead-source=Customer Event; data-use-default-rule=0; data-confirmation-preview=Thank you. We have received your heavy vehicle, equipment and haulier details. The NTE team will reconcile them with your booking and contact you if anything further is needed..

Section order: Delivery and collection → 1 Organisation and contacts → 2 Vehicles and equipment → Item 1 → Item 2 → Item 3 → 3 Haulier → Logistics acknowledgement.


| Salesforce Lead field | Control and exact input contract |
| --- | --- |
| Web_Form_Type__c | type=hidden; value=Heavy Vehicle Details |
| Form_Version__c | type=hidden; value=heavy-vehicle-details-v5 |
| NTE_Event_Code__c | type=hidden |
| Event_Contact_Name__c | type=hidden; data-combine-fields=vehicle-first-name,vehicle-last-name |
| Event_Contact_Email__c | type=hidden; data-copy-value-from=vehicle-email |
| Event_Contact_Mobile__c | type=hidden; data-copy-value-from=vehicle-phone |
| Company | Name of exhibiting organisation. id=vehicle-company; required=true |
| FirstName | Main contact first name. id=vehicle-first-name; required=true |
| LastName | Main contact surname. id=vehicle-last-name; required=true |
| Email | Main contact email. id=vehicle-email; type=email; required=true |
| Phone | Main contact direct phone. id=vehicle-phone; type=tel; required=true |
| Target_Booking_Reference__c | Booking reference. id=vehicle-reference; required=true; pattern=NTE-[A-Za-z0-9][A-Za-z0-9\-]{1,74}[A-Za-z0-9] |
| Secondary_Contact_Name__c | Second contact. id=vehicle-second-contact; required=true |
| Secondary_Contact_Email__c | Second contact email. id=vehicle-second-email; type=email; required=true |
| Secondary_Contact_Phone__c | Second contact phone. id=vehicle-second-phone; type=tel; required=true |
| Delivery_Window__c | Planned delivery window. id=delivery-window; required=true. Options: Sunday 28 February between 14:00 - 18:00; Monday 1 March between 06:30 - 07:15. |
| Heavy_Item_1_Description__c | Manufacturer and model, or a clear description of the item being exhibited. id=item1-description; required=true |
| Heavy_Item_1_Registration__c | Registration, if known and applicable. id=item1-registration |
| Heavy_Item_1_Dimensions__c | Dimensions (L × W × H). id=item1-dimensions; required=true |
| Heavy_Item_1_Gross_Weight__c | Gross weight. id=item1-weight; required=true |
| Heavy_Item_2_Description__c | Manufacturer and model, or a clear description of the item being exhibited. id=item2-description |
| Heavy_Item_2_Registration__c | Registration, if known and applicable. id=item2-registration |
| Heavy_Item_2_Dimensions__c | Dimensions (L × W × H). id=item2-dimensions |
| Heavy_Item_2_Gross_Weight__c | Gross weight. id=item2-weight |
| Heavy_Item_3_Description__c | Manufacturer and model, or a clear description of the item being exhibited. id=item3-description |
| Heavy_Item_3_Registration__c | Registration, if known and applicable. id=item3-registration |
| Heavy_Item_3_Dimensions__c | Dimensions (L × W × H). id=item3-dimensions |
| Heavy_Item_3_Gross_Weight__c | Gross weight. id=item3-weight |
| Haulier_Name__c | Name of haulier delivering / collecting. id=haulier-name; required=true |
| Haulier_Staff__c | Names of haulier staff, if known. id=haulier-staff |
| Haulier_Vehicle_Type__c | Type of haulier vehicle. id=haulier-type; required=true |
| Haulier_Vehicle_Gross_Weight__c | Gross weight without exhibition item. id=haulier-weight; required=true |
| Haulier_Vehicle_Dimensions__c | Haulier vehicle dimensions (L × W × H). id=haulier-dimensions; required=true |
| Haulier_Vehicle_Registration__c | Haulier vehicle registration, if known. id=haulier-registration |
| Declaration_Name__c | Digital signature (full name). id=vehicle-signature; required=true |
| Declaration_Date__c | Date. id=vehicle-signature-date; type=date; required=true |



Additional controls drive visibility, derived values, acknowledgements or submission without posting their own Salesforce field.


| Control | Behaviour attributes |
| --- | --- |
| Submit logistics details | type=submit  |



## logo upload

Source: logo-upload.html. Form configuration: class=main-column; data-web-to-lead=; data-form-kind=logo-update; data-lead-source=Customer Event; data-use-default-rule=0; data-confirmation-preview=Thank you. Your NTE27 logo update has been submitted..

Section order: 1 Upload your file → 2 Confirm your upload.


| Salesforce Lead field | Control and exact input contract |
| --- | --- |
| Web_Form_Type__c | type=hidden; value=Logo Update |
| Form_Version__c | type=hidden; value=logo-update-v2 |
| NTE_Event_Code__c | type=hidden |
| Company | Organisation name. id=logo-company; required=true |
| FirstName | Your first name. id=logo-first-name; required=true |
| LastName | Your surname. id=logo-last-name; required=true |
| Email | Your email address. id=logo-email; type=email; required=true |
| Target_Booking_Reference__c | Booking reference. id=logo-booking-reference; required=true; maxlength=80; pattern=NTE-[A-Za-z0-9][A-Za-z0-9\-]{1,74}[A-Za-z0-9] |



Additional controls drive visibility, derived values, acknowledgements or submission without posting their own Salesforce field.


| Control | Behaviour attributes |
| --- | --- |
| Confirm logo upload | type=submit  |



## partner sponsor application

Source: partner-sponsor-application.html. Form configuration: class=main-column; data-web-to-lead=; data-lead-source=Customer Event; data-use-default-rule=0; data-confirmation-preview=Thank you. We have received your NTE27 partnership / sponsorship application. The NTE team will review it and contact you with the outcome..

Section order: About NTE27 → 1 Organisation and applicant → Contact on the day of NTE27 → 2 Packages → 3 Exhibition space → 4 Quotation and invoicing → 5 Declaration → Partnership and sponsorship emails.


| Salesforce Lead field | Control and exact input contract |
| --- | --- |
| Logo_Upload_URL__c | type=hidden |
| Web_Form_Type__c | type=hidden; value=Partner / Sponsor Application |
| Form_Version__c | type=hidden; value=partner-sponsor-application-v12 |
| NTE_Event_Code__c | type=hidden |
| Booking_Reference__c | type=hidden |
| Sponsored_Name__c | type=hidden; data-combine-fields=partner-first-name,partner-last-name |
| Event_Contact_Name__c | type=hidden; data-switch-copy=partner-day-contact-same |
| Event_Contact_Title__c | type=hidden; data-switch-copy=partner-day-contact-same |
| Event_Contact_Email__c | type=hidden; data-switch-copy=partner-day-contact-same |
| Event_Contact_Mobile__c | type=hidden; data-switch-copy=partner-day-contact-same |
| Sponsor_Package_Total__c | type=hidden; value=0 |
| Exhibitor_Space_Price__c | type=hidden; value=0 |
| Power_Socket_Unit_Price__c | type=hidden; value=0 |
| Power_Socket_Total__c | type=hidden; value=0 |
| Additional_Staff_Unit_Price__c | type=hidden; value=0 |
| Additional_Staff_Total__c | type=hidden; value=0 |
| Included_Staff_Count__c | type=hidden; value=0 |
| Total_Staff_Count__c | type=hidden; data-copy-value-from=partner-planned-count |
| Additional_Staff_Required__c | type=hidden; value=No |
| Additional_Staff_Count__c | type=hidden; value=0 |
| Listed_Price_Total__c | type=hidden; value=0 |
| Pricing_Status__c | type=hidden; value=Calculated |
| Pricing_Version__c | type=hidden; value=NTE27-2026-09-10 |
| Invoice_Required__c | type=hidden; value=Yes |
| Company | Organisation name as it should appear in marketing. id=partner-company; required=true |
| FirstName | First name. id=partner-first-name; required=true |
| LastName | Surname. id=partner-last-name; required=true |
| Title | Job title. id=partner-title; required=true |
| Email | Contact email. id=partner-email; type=email; required=true |
| Phone | Contact telephone. id=partner-phone; type=tel; required=true |
| Sponsor_Package__c | type=checkbox; value=Headline Partner<br>type=checkbox; value=Gold Partner<br>type=checkbox; value=Premier Partner<br>type=checkbox; value=Champion Partner<br>type=checkbox; value=Zone Sponsor<br>type=checkbox; value=Community Stage Sponsor<br>type=checkbox; value=Podcast Corner Sponsor<br>type=checkbox; value=Event Guide Sponsor<br>type=checkbox; value=Delegate Tote Bag Sponsor<br>type=checkbox; value=Helmet Bay Sponsor<br>type=checkbox; value=Auditorium Sponsor<br>type=checkbox; value=Live Stream Sponsor<br>type=checkbox; value=Wristband Sponsor<br>type=checkbox; value=Escapade Sponsor |
| Exhibitor_Hall_Schedule__c | For garage exhibits and large stands in the halls, setting up between 14:00-18:00 hrs on Sunday is required. Please indicate you are able to do this.. id=partner-sunday; required=true. Options: Yes; No. |
| Stand_Power__c | Will you require power on your stand?. id=partner-power; required=true. Options: Yes; No. |
| Stand_Equipment__c | Equipment beyond display stands and laptops. id=partner-equipment; required=true |
| Heavy_Vehicle_Required__c | Will you bring cars, tractors or heavy items that need to be dropped off on a flatbed or trailer?. id=partner-heavy-vehicle; required=true. Options: Yes; No; Not known yet. |
| Has_Special_Requirements__c | Do you have any accessibility requirements?. id=partner-accessibility; required=true. Options: Yes; No. |
| Stand_Special_Requirements__c | Accessibility details. id=partner-accessibility-details; data-required-when-visible=true; visible only when partner-accessibility in Yes |
| Planned_Exhibitor_Count__c | How many people do you currently plan to bring, including yourself?. id=partner-planned-count; type=number; required=true; min=1; max=99; step=1 |
| Stand_Extra_Notes__c | Anything else to share about your space?. id=partner-extra-notes; required=true |
| Quote_Required_for_PO__c | Do you require a quotation before an invoice can be raised?. id=partner-quote; required=true. Options: Yes; No. |
| Payment_Method__c | Do you require an invoice to be raised, or will you make payment by Stripe?. id=partner-payment-method; required=true. Options: Bank transfer → Yes — invoice and payment by bank transfer; Stripe → No — payment will be via Stripe. |
| Purchase_Order__c | Do you require a purchase order or reference before an invoice can be issued?. id=partner-po; required=true. Options: Yes; No. |
| Purchase_Order_Number__c | Purchase order or reference details. id=partner-po-number; data-required-when-visible=true; visible only when partner-po in Yes |
| Supplier_Agreement_Required__c | Will a supplier agreement be required?. id=partner-supplier-agreement; required=true. Options: Yes; No; Don't know. |
| Invoiced_Company__c | Legal organisation name for quotation and invoicing. id=partner-invoice-company; required=true |
| Trading_Name__c | Trading name, if different. id=partner-trading-name |
| Invoice_Address__c | Billing address, including postcode. id=partner-invoice-address; required=true |
| Invoiced_Person__c | Finance contact name. id=partner-invoice-person; required=true |
| Invoiced_Email__c | Finance contact email address. id=partner-invoice-email; type=email; required=true |
| Invoice_Contact_Phone__c | Finance contact telephone number. id=partner-invoice-phone; type=tel; required=true |
| Invoice_Additional_Information__c | Additional quotation or invoice information. id=partner-invoice-additional-information; data-required-when-visible=true; visible only when partner-invoice-additional-required in Yes |
| Declaration_Name__c | Digital signature (full name). id=partner-declaration-name; required=true |
| Declaration_Date__c | Date. id=partner-declaration-date; type=date; required=true |
| Terms_and_Conditions__c | I have read and agree to the NTE27 Privacy Policy .. id=partner-terms; type=checkbox; required=true |



Additional controls drive visibility, derived values, acknowledgements or submission without posting their own Salesforce field.


| Control | Behaviour attributes |
| --- | --- |
| Will the applicant be the main contact on the day of NTE27? | id=partner-day-contact-same; required=true Options: Yes; No. |
| First name | id=partner-day-first-name; maxlength=40; data-required-when-visible=true  |
| Surname | id=partner-day-last-name; maxlength=80; data-required-when-visible=true  |
| Job title | id=partner-day-title; maxlength=128; data-required-when-visible=true  |
| Email address | id=partner-day-email; type=email; maxlength=80; data-required-when-visible=true  |
| Mobile phone number | id=partner-day-mobile; type=tel; maxlength=40; data-required-when-visible=true  |
| Is there any additional information that must appear on the quotation or invoice? | id=partner-invoice-additional-required; required=true Options: Yes; No. |
| Submit partner / sponsor application | type=submit  |



Required checkbox groups: class=options-list; role=group; aria-labelledby=partner-packages-heading; data-required-checkbox-group=; data-required-message=Please select at least one package..

## partner sponsor interest

Source: partner-sponsor-interest.html. Form configuration: class=main-column; data-web-to-lead=; data-form-kind=partner-eoi; data-lead-source=Customer Event; data-use-default-rule=0; data-confirmation-preview=Thank you. We have received your expression of interest. A member of the Mission Community team will contact you to explore the most suitable NTE27 opportunities..

Section order: 1 Your organisation → 2 Your interest in NTE27 → 3 How should we contact you? → Messages sent after submission.


| Salesforce Lead field | Control and exact input contract |
| --- | --- |
| Web_Form_Type__c | type=hidden; value=Partner / Sponsor Expression of Interest |
| Form_Version__c | type=hidden; value=partner-sponsor-eoi-v3 |
| NTE_Event_Code__c | type=hidden |
| Company | Organisation name. id=eoi-company; required=true |
| Organisation_Type__c | Organisation type. id=eoi-organisation-type; required=true. Options: Charity - COBSEO member; Charity - Non COBSEO member; Government Department or Agency; Industry Body / Trade Association; Employer - Automotive; Employer - Clean Energy; Employer - Blue Light Services / NHS; Employer - Built Environment; Employer - Manufacturing; Employer - Defence and Security; Employer - Financial and Professional Services; Employer - Digital and Technologies; Employer - Training and Education; Employer - Land-based; Employer - Other sector. |
| Website | Website. id=eoi-website; type=url |
| FirstName | First name. id=eoi-first-name; required=true |
| LastName | Surname. id=eoi-last-name; required=true |
| Title | Job title. id=eoi-title; required=true |
| Email | Email address. id=eoi-email; type=email; required=true |
| Phone | Telephone number. id=eoi-phone; type=tel; required=true |
| Partner_Interest_Type__c | Are you interested in partnering, sponsoring, or discussing both?. id=eoi-interest-type; required=true. Options: Partnership; Sponsorship; Both - open to discussion; Not sure - I would like advice. |
| Partner_Interest_Areas__c | Strategic event partnership Support the wider NTE27 programme and Armed Forces community.. type=checkbox; value=Strategic event partnership<br>Event zone sponsorship Align your organisation with a sector or themed zone.. type=checkbox; value=Event zone sponsorship<br>Stage, content or thought leadership Contribute expertise, insight or stories to the event programme.. type=checkbox; value=Stage, content or thought leadership<br>Branding and delegate experience Explore event-guide, tote-bag, wristband and other visibility opportunities.. type=checkbox; value=Branding and delegate experience<br>Troops' Track Day Discuss opportunities connected with the Silverstone track experience.. type=checkbox; value=Troops' Track Day<br>Other or not sure Tell us what you have in mind below and we will help shape the conversation.. type=checkbox; value=Other or not sure |
| Partnership_Interest_Detail__c | Additional comments regarding desired sponsorship or partnership. id=eoi-interest-detail; required=true |
| Preferred_Contact_Method__c | Preferred contact method. id=eoi-contact-method; required=true. Options: Email; Telephone; Video call; No preference. |
| Preferred_Contact_Time__c | Best time to contact you. id=eoi-contact-time |
| Event_Discovery_Source__c | How did you hear about NTE27?. id=eoi-discovery; required=true. Options: Previous NTE event; NTE webinar or brochure; Email invitation; Recommendation or word of mouth; National Transition Event website; Mission Community website; LinkedIn; Other social media; Other. |
| Contact_Consent__c | I agree that Mission Community may contact me about NTE27 partnership and sponsorship opportunities.. id=eoi-consent; type=checkbox; value=Yes; required=true |
| Declaration_Name__c | Digital signature (full name). id=eoi-signature; required=true |
| Declaration_Date__c | Date. id=eoi-signature-date; type=date; required=true |



Additional controls drive visibility, derived values, acknowledgements or submission without posting their own Salesforce field.


| Control | Behaviour attributes |
| --- | --- |
| Submit expression of interest | type=submit  |



Required checkbox groups: class=choice-grid; role=group; aria-labelledby=eoi-opportunities-label; data-required-checkbox-group=; data-required-message=Please select at least one area of interest..

## partner sponsor staff update

Source: partner-sponsor-staff-update.html. Form configuration: class=main-column; data-web-to-lead=; data-form-kind=partner-staff-update; data-lead-source=Customer Event; data-use-default-rule=0; data-confirmation-preview=Thank you. We have received your partner / sponsor staff details..

Section order: Before you begin → 1 Find your booking → 2 Final staff details → Staff details acknowledgement.


| Salesforce Lead field | Control and exact input contract |
| --- | --- |
| Web_Form_Type__c | type=hidden; value=Partner / Sponsor Staff Update |
| Form_Version__c | type=hidden; value=partner-sponsor-staff-update-v1 |
| Staff_Update_Audience__c | type=hidden; value=Partner / sponsor |
| NTE_Event_Code__c | type=hidden |
| Planned_Exhibitor_Count__c | type=hidden; data-copy-value-from=partner-staff-total |
| Staff_Base_Names__c | type=hidden; data-copy-value-from=partner-staff-names |
| Company | Organisation name. id=partner-staff-company; required=true |
| FirstName | Your first name. id=partner-staff-first-name; required=true |
| LastName | Your surname. id=partner-staff-last-name; required=true |
| Email | Your email address. id=partner-staff-email; type=email; required=true |
| Target_Booking_Reference__c | Booking reference. id=partner-staff-reference; required=true; pattern=NTE-[A-Za-z0-9][A-Za-z0-9\-]{1,74}[A-Za-z0-9] |
| Total_Staff_Count__c | Final number attending, including you. id=partner-staff-total; type=number; required=true; min=1; max=99; step=1 |
| Declaration_Name__c | Digital signature (full name). id=partner-staff-signature; required=true |
| Declaration_Date__c | Date. id=partner-staff-date; type=date; required=true |



Additional controls drive visibility, derived values, acknowledgements or submission without posting their own Salesforce field.


| Control | Behaviour attributes |
| --- | --- |
| Full names of everyone attending | id=partner-staff-names; required=true  |
| Submit staff details | type=submit  |



## volunteer application

Source: volunteer-application.html. Form configuration: class=main-column; data-web-to-lead=; data-form-kind=volunteer; data-require-code-of-conduct=; data-lead-source=Volunteer Application; data-use-default-rule=0; data-return-path=volunteer-thank-you.html; data-confirmation-preview=Thank you. We have received your volunteer application and a member of the Mission Motorsport team will be in touch..

Section order: 1 Your details → 2 Emergency contact → 3 Armed Forces service → 4 How you would like to help → Which volunteering opportunities interest you? → Which skills or experience could you offer? → Where are you willing to travel? → 5 Availability → Hours willing to give per month → Preference → 6 Privacy and declaration → Volunteer Code of Conduct → Volunteer application emails.


| Salesforce Lead field | Control and exact input contract |
| --- | --- |
| Web_Form_Type__c | type=hidden; value=Volunteer Application |
| Volunteer_Form_Version__c | type=hidden; value=volunteer-application-v3 |
| Company | type=hidden; value=Individual Volunteer |
| Interested_in_Volunteering__c | type=hidden; value=1 |
| Consent_PII__c | type=hidden; data-checkbox-copy-from=volunteer-consent |
| Consent_Contact__c | type=hidden; data-checkbox-copy-from=volunteer-consent |
| Consent_Promotion__c | type=hidden; data-checkbox-copy-from=volunteer-consent |
| FirstName | Forename(s). id=volunteer-first-name; required=true |
| LastName | Surname. id=volunteer-last-name; required=true |
| Date_of_Birth__c | Date of birth. id=volunteer-dob; type=date; required=true |
| MobilePhone | Mobile number. id=volunteer-mobile; type=tel; required=true |
| Phone | Home telephone. id=volunteer-home-phone; type=tel |
| Email | Email address. id=volunteer-email; type=email; required=true |
| Street | Address. id=volunteer-address; required=true |
| PostalCode | Postcode. id=volunteer-postcode; required=true |
| NOK_Name__c | Full name. id=volunteer-emergency-name; required=true |
| NOK_Relationship__c | Relationship to you. id=volunteer-emergency-relationship; required=true |
| NOK_Phone__c | Telephone number. id=volunteer-emergency-phone; type=tel; required=true |
| NOK_Address__c | Emergency contact’s address. id=volunteer-emergency-address; required=true; data-required-when-visible=true; visible only when volunteer-emergency-same-address in No<br>type=hidden; data-copy-value-from=volunteer-address; visible only when volunteer-emergency-same-address in Yes |
| NOK_Postcode__c | Postcode. id=volunteer-emergency-postcode; required=true; data-required-when-visible=true; visible only when volunteer-emergency-same-address in No<br>type=hidden; data-copy-value-from=volunteer-postcode; visible only when volunteer-emergency-same-address in Yes |
| Volunteer_Armed_Forces_Service__c | Have you served, or are you currently serving, in HM Armed Forces?. id=volunteer-forces-service; required=true. Options: Yes; No. |
| Volunteer_Service_Details__c | Service, unit, station or ship. id=volunteer-service-details; visible only when volunteer-forces-service in Yes |
| Volunteer_Service_Dates__c | Dates in Service. id=volunteer-service-dates; visible only when volunteer-forces-service in Yes |
| Volunteer_Opportunities__c | Fundraising. type=checkbox; value=Fundraising<br>Transport and Logistics Car, van with trailer, minibus. type=checkbox; value=Transport and Logistics<br>Motorsport event support. type=checkbox; value=Motorsport Event Support<br>Marshalling. type=checkbox; value=Marshalling<br>Community outreach / awareness. type=checkbox; value=Community Outreach / Awareness<br>Professional skills HR, legal, finance, IT or project management. type=checkbox; value=Professional Skills<br>Mentoring and coaching. type=checkbox; value=Mentoring & Coaching<br>Team area co-ordinator. type=checkbox; value=Team Area Co-Ordinator<br>Vehicle maintenance / repairs in Wantage. type=checkbox; value=Vehicle Maintenance / Repairs (Wantage)<br>Pop up shop. type=checkbox; value=Pop up shop<br>Storekeeping in Wantage. type=checkbox; value=Storekeeping (Wantage)<br>Maintenance / DIY in Wantage. type=checkbox; value=Maintenance / DIY (Wantage) |
| Volunteer_Skills__c | Fundraising. type=checkbox; value=Fundraising<br>Transport and Logistics Car, van with trailer, minibus. type=checkbox; value=Transport and Logistics<br>Motorsport event support. type=checkbox; value=Motorsport Event Support<br>Marshalling. type=checkbox; value=Marshalling<br>Community outreach / awareness. type=checkbox; value=Community Outreach / Awareness<br>Professional skills HR, legal, finance, IT or project management. type=checkbox; value=Professional Skills<br>Mentoring and coaching. type=checkbox; value=Mentoring & Coaching<br>Team area co-ordinator. type=checkbox; value=Team Area Co-Ordinator<br>Vehicle maintenance / repairs in Wantage. type=checkbox; value=Vehicle Maintenance / Repairs (Wantage)<br>Pop up shop. type=checkbox; value=Pop up shop<br>Storekeeping in Wantage. type=checkbox; value=Storekeeping (Wantage)<br>Maintenance / DIY in Wantage. type=checkbox; value=Maintenance / DIY (Wantage) |
| Volunteer_Travel_Regions__c | East Midlands. type=checkbox; value=East Midlands<br>Greater London. type=checkbox; value=Greater London<br>North East England. type=checkbox; value=North East England<br>North West England. type=checkbox; value=North West England<br>Scotland. type=checkbox; value=Scotland<br>South West England. type=checkbox; value=South West England<br>South East England. type=checkbox; value=South East England<br>Wales. type=checkbox; value=Wales<br>West Midlands. type=checkbox; value=West Midlands<br>Yorkshire & the Humber. type=checkbox; value=Yorkshire & the Humber |
| Volunteer_DBS_Willing__c | Would you be willing to complete a DBS check if the role requires one?. id=volunteer-dbs; required=true. Options: Yes; No. |
| Volunteer_Hours__c | 0–4. type=checkbox; value=0-4<br>4–8. type=checkbox; value=4-8<br>8–16. type=checkbox; value=8-16<br>16+. type=checkbox; value=16+<br>Don’t know. type=checkbox; value=Don't know |
| Volunteer_Availability__c | Weekdays. type=checkbox; value=Weekdays<br>Weekends. type=checkbox; value=Weekends<br>Any. type=checkbox; value=Any |
| Volunteer_Code_Consent__c | I have read and understood the Code of Conduct and agree to follow it.. id=volunteer-conduct-acknowledgement; type=checkbox; value=1; required=true |
| Volunteer_Code_Version__c | type=hidden |
| Volunteer_Consent__c | Do you consent to Mission Motorsport using your personal information, contacting you about suitable opportunities, using approved images or stories for promotion, and using relevant medical information where needed?. id=volunteer-consent; required=true. Options: Yes; No. |
| Declaration_Name__c | Digital signature (full name). id=volunteer-signature; required=true |
| Declaration_Date__c | Date. id=volunteer-signature-date; type=date; required=true |



Additional controls drive visibility, derived values, acknowledgements or submission without posting their own Salesforce field.


| Control | Behaviour attributes |
| --- | --- |
| volunteer-emergency-same-address | id=volunteer-emergency-same-address; type=checkbox  |
| Submit volunteer application | type=submit  |



Required checkbox groups: class=choice-fieldset; data-required-checkbox-group=; data-required-message=Please select at least one volunteering opportunity.; class=choice-fieldset; data-required-checkbox-group=; data-required-message=Please select at least one skill or area of experience.; class=choice-fieldset; data-required-checkbox-group=; data-required-message=Please select at least one region.; class=choice-fieldset; data-required-checkbox-group=; data-single-choice-group=; data-required-message=Please select the hours you are willing to give per month.; class=choice-fieldset; data-required-checkbox-group=; data-exclusive-choice=Any; data-required-message=Please select your availability preference..

## Lightning component methods

All four bundles are listed below, including lifecycle methods, event handlers and derived getters. CSS controls responsive spacing, tables, state colours and dialog layout; it does not decide eligibility or prices. All server writes go through the Apex methods already documented.

### nteManagementHome

Exposed=true; API=67.0; targets=target=lightning__HomePage. 

Apex imports: getHomeDashboard → NTE_MasterPanelController.getHomeDashboard.


| Method or getter and source line | Role |
| --- | --- |
| connectedCallback()<br>Line 63 | Registers window-focus and document-visibility listeners and loads the event portfolio. |
| disconnectedCallback()<br>Line 69 | Removes both listeners, clears the refresh timer and increments requestSequence to discard any response arriving after removal. |
| handleWindowFocus = () =><br>Line 76 | Schedules a refresh when the window regains focus. |
| handleVisibilityChange = () =><br>Line 80 | Schedules a refresh only when document.visibilityState becomes visible. |
| scheduleLiveRefresh()<br>Line 86 | Replaces any pending refresh with a 150 ms timer, then calls loadDashboard. |
| get controlsDisabled()<br>Line 94 | Disables the event selector and refresh control while loading or when eventOptions is empty. |
| get showInitialLoading()<br>Line 98 | Shows the initial loading state only while loading and before a dashboard has been accepted. |
| handleEventChange(event)<br>Line 102 | Ignores an unchanged edition; otherwise stores event.detail.value, clears hasDashboard and loads the selected edition. |
| handleRefresh()<br>Line 112 | Reloads the currently selected event portfolio. |
| async loadDashboard()<br>Line 116 | Calls getHomeDashboard with the selected edition or null. A monotonically increasing requestSequence discards superseded responses; the latest response is parsed and applied, or the portfolio error state is shown. |
| applyDashboard(payload)<br>Line 141 | Loads event choices, returned edition, refresh time, headlines, pipeline, finance readiness and booking mix. Adds an unlisted returned edition to the selector and shows a pricing-check note only when pricingReviewCount is positive. |
| parseResponse(response)<br>Line 163 | Accepts an object directly, substitutes {} for a missing response, or JSON-parses a string. Invalid JSON throws the dashboard-response error. |
| normalizeEventOptions(options)<br>Line 174 | Accepts an array of strings or objects. Object value precedence is value, code, eventCode; label precedence is label, name, value. Entries without a value are removed. |
| normalizeHeadline(headline)<br>Line 186 | Produces Applications, Approved applications, Invoiced, Still to collect and Paid in that order. Resolves configured aliases from an array or object, formats each value and record count, and highlights Approved applications. |
| normalizePipeline(rows)<br>Line 205 | Accepts stage rows or a keyed object. Resolves exhibitor, partner and total amounts; a missing/zero total falls back to exhibitor plus partner. Each audience bar is scaled against that audience’s largest stage. Share uses the supplied nonzero percentage or total divided by the largest stage total; these overlapping stages are not an additive funnel. |
| normalizeReadiness(readiness)<br>Line 246 | Accepts an array or the configured quote/invoice/payment/paid object aliases. Each segment uses its supplied nonzero percentage or its value divided by the sum of the displayed readiness values, then formats the amount and width. |
| normalizeReadinessItem(item, index)<br>Line 271 | Resolves label/name, a normalised key, metricValue and percentage/share/progress; missing labels become Status plus a one-based index. |
| normalizeBookingMix(bookingMix)<br>Line 282 | Resolves exhibitor/exhibitors and partnerSponsor/partner/sponsors groups, totals their records and values, then presents each group’s contribution. |
| bookingGroup(source)<br>Line 293 | Reads the group record count and value. Average uses averageValue/average/avgValue when nonzero, otherwise value divided by records, or zero for an empty group. |
| presentBookingGroup(group, totalRecords, totalValue)<br>Line 300 | Formats record count and value with rounded percentages of the combined groups, and formats average booking value. A zero denominator yields 0%. |
| emptyBookingMix()<br>Line 310 | Initialises both participant groups to 0 records, £0 value and £0 average while no portfolio is available. |
| firstObject(parent, aliases)<br>Line 317 | Returns the first alias whose value is neither null nor undefined. Objects pass through; scalar values become { value }; no match returns {}. |
| metricValue(source)<br>Line 327 | Uses the first non-null value among value, amount, totalValue and total, converted through toNumber. |
| metricRecords(source)<br>Line 331 | Uses the first non-null value among records, recordCount and count, converted through toNumber. |
| toNumber(value)<br>Line 335 | Preserves finite numbers. For strings, removes all characters except digits, decimal point and minus sign before Number conversion. Missing, non-string and non-finite values become zero. |
| toKey(value, index = 0)<br>Line 346 | Converts camel case and non-alphanumeric separators to lowercase hyphenated keys; an empty result becomes item-<index>. |
| widthStyle(value)<br>Line 351 | Clamps the numeric percentage to 0–100 and returns a CSS width with two decimal places. |
| formatCurrency(value)<br>Line 356 | Formats the normalised number as GBP using en-GB with zero decimal places for portfolio headlines and charts. |
| formatDateTime(value)<br>Line 360 | Formats a valid Date or date value using en-GB day, abbreviated month, year and 24-hour time in the browser timezone. Invalid dates display an em dash. |



### nteMasterPanel

Exposed=true; API=65.0; targets=target=lightning__Tab; lightning__AppPage; lightning__HomePage. 

Apex imports: getDashboard → NTE_MasterPanelController.getDashboard; getCommunicationRecordIds → NTE_MasterPanelController.getCommunicationRecordIds; buildDraft → NTEEmailDispatchService.buildDraft; previewMessageJson → NTEEmailDispatchService.previewMessageJson; queueMessagesJson → NTEEmailDispatchService.queueMessagesJson; updateLeadDecision → NTE_MasterPanelController.updateLeadDecision; updateMilestone → NTE_MasterPanelController.updateMilestone.


| Method or getter and source line | Role |
| --- | --- |
| connectedCallback()<br>Line 95 | Registers focus/visibility listeners and loads the initial INTEREST view with All time, all owners and 25 rows per page. |
| disconnectedCallback()<br>Line 101 | Removes listeners; clears refresh, conversion-monitor and preview timers; invalidates dashboard/communication/preview sequences; and clears active communication state. |
| renderedCallback()<br>Line 116 | When modalNeedsFocus is set, focuses the dialog’s data-modal-focus control once and clears the flag. |
| handleWindowFocus = () =><br>Line 123 | Schedules a refresh after Salesforce regains focus, including a return from the separate conversion tab. |
| handleVisibilityChange = () =><br>Line 127 | Schedules a refresh when the document becomes visible. |
| scheduleLiveRefresh()<br>Line 133 | Debounces refresh by 150 ms while preserving row selection. Both scheduling and execution are suppressed during a record action, open communication dialog or communication preparation/send. |
| get eventOptions()<br>Line 144 | Returns response.eventOptions or an empty selector list. |
| get ownerOptions()<br>Line 148 | Returns response.ownerOptions; its fallback is one All owners choice with an empty value. |
| get guestBreakdown()<br>Line 152 | Presents overview key guests as pending versus captured. |
| get interestBreakdown()<br>Line 156 | Presents overview key interest as open versus decided. |
| get applicationBreakdown()<br>Line 160 | Presents overview key applications as awaiting review versus approved. |
| get bookingBreakdown()<br>Line 164 | Presents overview key approved as still in progress versus fully complete. Completion is rounded completed/total × 100, or zero when empty; the donut angle is that percentage × 3.6 degrees. |
| get quoteBreakdown()<br>Line 175 | Presents overview key quotes as outstanding versus provided. |
| get invoiceBreakdown()<br>Line 179 | Presents overview key invoices as outstanding versus provided. |
| get paymentBreakdown()<br>Line 183 | Presents overview key payments as outstanding versus received. |
| get logisticsBreakdown()<br>Line 187 | Presents overview key heavy as outstanding versus completed. |
| get staffBreakdown()<br>Line 191 | Presents overview key staff as outstanding versus completed. |
| get logoBreakdown()<br>Line 195 | Presents overview key logos as outstanding versus completed. |
| buildBreakdownMetric(key, inProgressLabel, completedLabel)<br>Line 199 | Finds the requested response.overview key, converts missing totals/counts to zero, clamps each progress width to 0–100%, and creates the accessible total/in-progress/completed description. |
| get pipeline()<br>Line 218 | Decorates response.pipeline with the active-stage class and aria-pressed value. The Completed tile appends the summary complete percentage, defaulting to 0%. |
| get activeStage()<br>Line 229 | Finds the STAGE_CONFIGURATION group containing viewKey; views outside the configured groups fall back to interest for path highlighting. |
| get stageOptions()<br>Line 233 | Maps the active stage’s configured refinement keys to response.workQueues and marks the selected option. A missing queue receives its key as label, count zero and the standard record icon. |
| get hasStageOptions()<br>Line 246 | Shows refinement controls when stageOptions contains at least one item. |
| get selectedQueue()<br>Line 250 | Uses response.selectedView for the record-list heading; fallback is NTE records with the selected-filter description. |
| get isGuestView()<br>Line 257 | True only for GUESTS. |
| get isInterestView()<br>Line 261 | True for INTEREST, INTEREST_EXHIBITOR or INTEREST_PARTNER. |
| get isApplicationView()<br>Line 265 | True for APPLICATION_REVIEW, APPLICATION_EXHIBITOR or APPLICATION_PARTNER. |
| get isFinanceView()<br>Line 269 | True for FINANCE_DUE, QUOTE_REQUIRED, INVOICE_REQUIRED, PAYMENT_DUE or PAYMENT_COMPLETE. |
| get financeAmountLabel()<br>Line 273 | Labels finance values Amount (inc VAT), including the actionable booking or top-up charge according to the current queue. |
| get hasRowActions()<br>Line 277 | Shows the action column if any row has an interest/application decision or any visible base/top-up quote, invoice or payment milestone action. |
| get isApprovedView()<br>Line 283 | True for APPROVED, APPROVED_EXHIBITOR or APPROVED_PARTNER. |
| get isCompletedView()<br>Line 287 | True for COMPLETED, FINAL_PACK_DUE or FINAL_PACK_SENT. |
| get isHeavyView()<br>Line 291 | True only for HEAVY_DUE. |
| get isStaffView()<br>Line 295 | True only for STAFF_DUE. |
| get isLogoView()<br>Line 299 | True only for LOGO_DUE. |
| get isUpdatesView()<br>Line 303 | True only for the combined READINESS_DUE view. |
| get isRecentView()<br>Line 307 | True only for RECENT. |
| get actionColumnLabel()<br>Line 311 | Uses Decision in interest views and Action elsewhere. |
| get canRemindAll()<br>Line 315 | Shows the bulk reminder entry point only in HEAVY_DUE, STAFF_DUE or LOGO_DUE. |
| get canDistributeFinalPack()<br>Line 319 | Shows final-pack distribution in COMPLETED and FINAL_PACK_DUE, excluding FINAL_PACK_SENT. |
| get communicationBusy()<br>Line 323 | True during draft preparation or email queuing. |
| get panelControlsDisabled()<br>Line 327 | Locks panel actions/filters during loading, a record action, communication preparation/queuing or any open communication dialog. |
| get visibleRows()<br>Line 331 | Adds the current panel lock to every row action. Invitation actions also keep their own Queued/Sent lock. |
| get visibleCommunicationRecipients()<br>Line 339 | Disables recipient selection while communication is busy or the server has marked that recipient ineligible. |
| get selectedEmailRecipients()<br>Line 343 | Includes only recipients whose selected and eligible flags are both true. |
| get selectedEmailRecipientCount()<br>Line 347 | Counts the eligible selected recipients used in the send request. |
| get availableRecipientCount()<br>Line 351 | Counts every eligible draft recipient, whether selected or not. |
| get sendCommunicationDisabled()<br>Line 355 | Blocks Send while busy, with a stale draft, when draft.canSend is false, with no selected recipient or more than recipientLimit (default 500), with blank trimmed subject/body, or until a current preview is ready and no preview is loading. |
| get sendCommunicationLabel()<br>Line 363 | Displays Queuing emails… during the send request; otherwise Send to <selected count>. |
| get recipientOptions()<br>Line 367 | Builds the preview selector from eligible selected recipients. Labels combine distinct nonempty company/name values; the option value is the source record ID. |
| get hasSelectedEmailRecipients()<br>Line 374 | Shows recipient-dependent preview controls when the selected eligible count is positive. |
| get tableClass()<br>Line 378 | Converts the view key to lowercase with hyphens to select the corresponding data-table CSS layout. |
| get selectedRecord()<br>Line 382 | Finds selectedRecordId among the current page’s rows for the detail sidebar. |
| get hasRows()<br>Line 386 | True when the current page contains at least one row. |
| get hasPrevious()<br>Line 390 | True when offsetRows is greater than zero. |
| get hasNext()<br>Line 394 | Prefers the server’s hasNextPage flag; if absent, checks offsetRows + 25 against totalRows. |
| get previousDisabled()<br>Line 398 | Disables Previous when the panel is locked or there is no earlier page. |
| get nextDisabled()<br>Line 402 | Disables Next when the panel is locked or there is no later page. |
| get pageLabel()<br>Line 406 | Displays the one-based visible range and total, or 0 records. If rowsLimited is true, appends the server’s accessibleRows as the latest records available. |
| async loadDashboard({ preserveSelection = true } = {})<br>Line 414 | Calls getDashboard with edition, time range, owner/null, view key, page size 25 and offset. Ignores superseded responses, adopts returned scope/pagination and decorates rows. Preserves the selected record if still on the page, otherwise selects the first row. Communication work prevents loading. |
| decorateRow(row, selectedId)<br>Line 454 | Combines server canMark flags with the current finance refinement to expose only relevant base/top-up actions. Derives Lead/Opportunity, guest/interest/application flags, contact links and detail fallbacks. Queued/Sent invitations disable their action; Opportunity details use Primary contact and optional event-day contact. |
| financeStatusForView(row)<br>Line 521 | Check pricing takes priority. Quote view says Quote required; invoice/payment views choose the base booking while its corresponding obligation remains outstanding, then the staff top-up. Paid view says Payment confirmed; combined view keeps the server label. |
| financeAmountForView(row)<br>Line 536 | Quote view uses baseAmount. Invoice/payment refinements use baseAmount while the base obligation is outstanding, then topUpAmount. Combined finance prioritises base quote/invoice, top-up invoice, base payment, then top-up payment. Otherwise returns the combined row.amount. |
| decorateRows()<br>Line 553 | Updates each row’s selected CSS class and accessible selection label after a sidebar selection change. |
| leadConversionPageReference(leadId)<br>Line 562 | Builds a standard__component reference to runtime_sales_lead__convertDesktopConsole, with the exact Lead ID in leadConvert__leadId. |
| statusClass(value)<br>Line 574 | Marks complete/provided/paid/payment confirmed/not required/not applicable as complete. Check pricing or text containing required/due/confirmed is due; remaining statuses are neutral. |
| emailStatusClass(status)<br>Line 585 | Maps Sent to complete, Failed to failed, Pending/Queued to due, and other or missing email states to neutral. |
| handleEventChange(event)<br>Line 592 | Stores the edition selector value and resets to the first page without preserving row selection; ignored while the panel is locked. |
| handleTimeChange(event)<br>Line 598 | Stores the All time/Today/7/30/90-day selector value and reloads from the first page; ignored while locked. |
| handleOwnerChange(event)<br>Line 604 | Stores the owner selector value and reloads from the first page; ignored while locked. |
| handleStageOptionSelect(event)<br>Line 610 | Uses the clicked refinement’s data-view as viewKey and reloads from page one. |
| handlePipelineSelect(event)<br>Line 616 | Uses the clicked stage’s configured combinedView, falling back to its data-view, then reloads from page one. |
| handleOverviewSelect(event)<br>Line 624 | Uses the clicked overview control’s data-view and reloads from page one. |
| handleSelectRow(event)<br>Line 630 | Selects the row’s data-id unless the click originated in a nested link, button or form control. |
| handleRowKeyDown(event)<br>Line 637 | Selects a focused row on Enter or Space; ignores bubbled key events from controls inside the row. |
| selectRecord(recordId)<br>Line 644 | Stores the selected row ID and updates row highlighting for the detail sidebar; ignored while the panel is locked. |
| handlePrevious()<br>Line 650 | Subtracts 25 from the offset, clamped at zero, and loads the earlier page without preserving row selection. |
| handleNext()<br>Line 656 | Adds 25 to the offset and loads the next page without preserving row selection. |
| handleRefresh()<br>Line 662 | Reloads the current scope and preserves selection when the panel is unlocked. |
| async handleConvertLead(event)<br>Line 667 | Opens a blank tab synchronously, generates the native conversion URL and navigates that tab. A blocked pop-up produces an actionable warning. A 750 ms monitor detects tab closure and schedules refresh; a navigation error closes the blank tab. |
| async handleLeadDecision(event)<br>Line 708 | Accepts INTEREST_NOT_PROGRESSED or APPLICATION_REJECTED from the clicked row, confirms the rejection, calls updateLeadDecision and reloads without preserving selection. Rejection retains the Lead. |
| handleOpenReminders(event)<br>Line 752 | Starts a communication draft using the current HEAVY_DUE, STAFF_DUE or LOGO_DUE view as the email kind. |
| handleOpenInvitations(event)<br>Line 756 | Starts an INVITATION draft for the clicked Lead ID, passed from the row’s data-id. |
| handleOpenFinalPack(event)<br>Line 762 | Starts a FINAL_PACK draft for the currently filtered completed/unsent scope. |
| async openCommunication(kind, event, recordId)<br>Line 766 | Uses one supplied record ID or calls getCommunicationRecordIds for the full current filter scope. Rejects empty or more-than-500 selections before buildDraft. Stores the original IDs, initially selects eligible recipients, opens the modal and invalidates competing dashboard requests. |
| applyCommunicationDraft(draft, selectEligible, selectedIds)<br>Line 801 | Stores the server draft and marks it fresh. Selects eligible recipients using either the supplied previous selection IDs or selectEligible. Sets subject/body and recipient labels, chooses the first selected preview recipient and immediately schedules preview. |
| async handleRefreshCommunication()<br>Line 819 | Rebuilds the draft for the original record ID set. Retains edited subject/body and previously selected IDs only when still eligible. Clears preview readiness until the rebuilt draft is previewed; ignores superseded responses. |
| handleCommunicationSubjectChange(event)<br>Line 843 | Stores the input subject and schedules a 300 ms preview refresh; ignored while preparing or queuing. |
| handleCommunicationMessageChange(event)<br>Line 849 | Stores the edited message body and schedules a 300 ms preview refresh; ignored while preparing or queuing. |
| handleRecipientSelection(event)<br>Line 855 | Updates only the clicked recipient’s selection, allowing selection only if eligible, then refreshes preview immediately. |
| handleSelectEligibleRecipients()<br>Line 866 | Selects every eligible draft recipient and refreshes preview immediately. |
| handleClearRecipients()<br>Line 872 | Clears all recipient selections and invalidates the preview immediately. |
| handlePreviewRecipientChange(event)<br>Line 878 | Stores the selected preview record ID and immediately requests its merged preview. |
| communicationRequest()<br>Line 884 | Builds kind, runId, subject, messageBody and the selected recipient recordId/fingerprint pairs. The same request contract is used for preview and queuing. |
| invalidateCommunicationPreview()<br>Line 894 | Cancels the timer, increments previewSequence and communicationVersion, clears the HTML and resets preview-ready/loading flags so obsolete content cannot enable Send. |
| queueCommunicationPreview(delay = 300)<br>Line 903 | Invalidates the previous preview, requires a fresh draft, ensures the preview ID is still selected and requires nonblank subject/body. Schedules renderCommunicationPreview after 300 ms by default, or immediately for selection/draft changes. |
| async renderCommunicationPreview(sequence)<br>Line 916 | Calls previewMessageJson with the current request and preview record ID. Accepts only the current sequence while the modal is open; swaps the hosted logo for the local static resource and adapts the preview width. A nonempty result enables preview readiness. |
| handleCloseCommunication({ deferFocus = false } = {})<br>Line 935 | Closes an idle dialog, invalidates preview/communication responses and clears the draft and recipients. Restores the launching control’s focus unless deferred for the post-send refresh. |
| async handleSendCommunication()<br>Line 948 | Snapshots the reviewed request, version and communication sequence, asks for send confirmation, then rechecks those values and preview readiness before queueMessagesJson. Zero queued rows force a recipient refresh; successful queuing closes the modal and reloads the panel. Skipped recipients produce a warning result. |
| showEmailToast(title, message, variant)<br>Line 985 | Displays the supplied queue result; errors remain sticky, while other toasts are dismissible. |
| handleModalFocus(event)<br>Line 989 | Remembers the currently focused dialog control for keyboard-boundary checks. |
| handleModalKeyDown(event)<br>Line 993 | Escape attempts to close the dialog; Tab/Shift+Tab wrap between its first and last enabled visible controls. |
| modalFocusableControls(dialog)<br>Line 1015 | Returns enabled visible buttons, Lightning inputs/textareas/comboboxes, links and tabindex=0 elements inside the dialog. |
| handleModalFocusOut(event)<br>Line 1020 | Returns escaped focus to the first or last control according to the Tab direction, unless the dialog is closed/busy or focus remains inside. |
| restoreModalFocus()<br>Line 1027 | On the next timer turn, returns focus to the connected launch control; if unavailable, uses the header refresh button. |
| resetAndLoad()<br>Line 1036 | Sets offsetRows to zero and calls loadDashboard with preserveSelection false. |
| async handleMilestone(event)<br>Line 1041 | Accepts only the five known base/top-up quote, invoice and payment actions, confirms the clicked booking/action, calls updateMilestone and reloads with that booking selected. Displays an Update not saved error on failure. |
| readError(error)<br>Line 1084 | Uses error.body.message, then error.message, then the Master Panel loading fallback. |



### nteRelatedOpportunities

Exposed=true; API=67.0; targets=target=lightning__RecordPage. Target configuration: targetConfig=objects=object=Account; Contact; Opportunity.

Apex imports: getRelationships → NTERelatedOpportunityController.getRelationships.


| Method or getter and source line | Role |
| --- | --- |
| wiredRelationships({ data, error })<br>Line 31 | Reactively calls getRelationships for recordId/objectApiName. On success adopts the server title/mode/empty text and normalises its account, contacts and opportunities; on failure shows the relationships loading error. |
| get showsOpportunities()<br>Line 47 | Shows the booking-history view when the server mode is opportunities. |
| get showsRelationships()<br>Line 51 | Shows the account/contact view when the server mode is relationships. |
| get objectApiNameIsContact()<br>Line 55 | True on Contact records, allowing Contact-specific presentation. |
| get hasOpportunities()<br>Line 59 | True when the returned booking-history list has at least one Opportunity. |
| get hasContacts()<br>Line 63 | True when the returned linked-contact list is nonempty. |
| get hasOpportunityRelationships()<br>Line 67 | True when the booking has an Account or at least one linked Contact to display. |
| normalizeOpportunity(item)<br>Line 71 | Adds the Lightning record URL, GBP amount with up to two decimals, and en-GB close date parsed at local noon. Missing amount/date displays an em dash; the contact label distinguishes Primary contact from Linked contact. |
| normalizeAccount(item)<br>Line 81 | Adds the Account’s /lightning/r/Account/<id>/view record link. |
| normalizeContact(item)<br>Line 88 | Adds the Contact record link, primary/role/linked-contact label, phone/email fallbacks and a mailto link only when an address exists. |



### nteRetryEmail

Exposed=true; API=67.0; targets=target=lightning__RecordAction. Target configuration: targetConfig=actionType=Action.

Apex imports: retryDispatch → NTEEmailDispatchService.retryDispatch; retryApprovalEmail → NTEExhibitorApprovalEmailService.retryApprovalEmail; retryAcknowledgement → NTEUpdateSubmissionService.retryAcknowledgement.


| Method or getter and source line | Role |
| --- | --- |
| async invoke()<br>Line 13 | Headless action guarded against simultaneous invocation. A 006 ID calls retryApprovalEmail; 00Q calls retryAcknowledgement and adapts its result; other IDs call retryDispatch. Notifies Lightning that the source record changed. A refresh failure retains the action result and asks for a page refresh; finally clears the running guard. |



## Shared public form engine functions

Source: assets/forms.js. Nested sync/validation closures belong to their named parent setup function.


| Function and line | Responsibility |
| --- | --- |
| setStatus<br>Line 70 | Sets the form status text/type and error/success accessibility presentation. |
| configureShell<br>Line 80 | Applies event/privacy/support/logo-destination configuration to shared page elements. |
| enableConditionalSections<br>Line 116 | Enables/disables conditional sections and their nested required controls when the controlling answer changes. |
| configureFieldConstraints<br>Line 148 | Applies standard/custom length limits and refreshed date boundaries. |
| enableCheckboxChoices<br>Line 174 | Wires required checkbox-group validity. |
| validateCheckboxChoices<br>Line 188 | Requires a selection in each active required checkbox group. |
| syncCombinedFields<br>Line 199 | Builds hidden combined/copied/switch-derived values from their visible source controls. |
| eventCodeFromParts<br>Line 227 | Returns the current year before April and following year from April onward. |
| pureDateParts<br>Line 231 | Parses a calendar date without accepting impossible dates. |
| eventCodeFor<br>Line 244 | Derives London-local year/month for the edition rollover. |
| resolveEventCode<br>Line 262 | Uses a valid explicit override or derives the current edition. |
| bookingReference<br>Line 271 | Generates a new reference in the supported NTE grammar using time/random identity. |
| populateSystemFields<br>Line 285 | Populates edition/reference/version-related hidden controls. |
| setPricingField<br>Line 294 | Writes a derived numeric/status field into the active form. |
| catalogPrice<br>Line 299 | Accepts a finite nonnegative fixed catalogue price. |
| calculatePartnerPricing<br>Line 307 | Sums validated selected package prices. |
| qualifiesForPowerDiscount<br>Line 314 | Checks the same five category labels as Apex. |
| includedStaffForSpace<br>Line 318 | Returns the two/four included-staff allowance from the exact space choice. |
| calculateExhibitorPricing<br>Line 327 | Calculates space, allowed sockets and initial additional staff from whole valid counts. |
| eligibleCategoriesForSpace<br>Line 363 | Returns the exact restricted-space eligible categories. |
| syncExhibitorEligibility<br>Line 374 | Disables ineligible space choices and invalidates a stale selection. |
| setupPackageSummary<br>Line 389 | Updates partner selected-package summary and hidden totals. |
| setupExhibitorEstimate<br>Line 423 | Wires exhibitor category/space/staff/socket choices to derived estimate, allowance and invoice state. |
| nonBlankLines<br>Line 525 | Returns nonempty roster lines. |
| setupStaffUpdates<br>Line 529 | Keeps roster-derived counts and separate exhibitor top-up estimate in sync. |
| collectFields<br>Line 549 | Collects only enabled selected/nonempty controls into API-name arrays. |
| hasBlankRequiredText<br>Line 567 | Rejects whitespace-only required text that native required alone would accept. |
| normalizeBookingReferences<br>Line 580 | Trims and uppercases supplied target references. |
| validateBookingReferences<br>Line 586 | Enforces the reference grammar before POST. |
| validateFieldLengths<br>Line 596 | Checks configured standard/custom text limits. |
| formatWebToLeadDate<br>Line 608 | Formats ISO browser dates as configured DMY or supported output. |
| setRuleError<br>Line 614 | Attaches a form-specific actionable custom-validity message. |
| validateCatalogPricing<br>Line 624 | Rejects unknown/tampered pricing selections even if a hidden total looks valid. |
| exhibitorSpacePrice<br>Line 641 | Resolves a selected exhibitor option through the actual catalogue. |
| packagePrice<br>Line 649 | Reads and validates the selected package catalogue value. |
| validateStaffUpdate<br>Line 657 | Checks audience, initial/top-up answer/count and roster consistency. |
| validateHeavyItems<br>Line 688 | Requires complete mandatory and partially started optional item groups. |
| missingFieldIds<br>Line 708 | Lists submitted custom API names missing their destination Web-to-Lead ID. |
| missingProductionConfig<br>Line 714 | Checks the actual configured endpoint, org, return destination and required links. |
| resolveReturnUrl<br>Line 723 | Resolves the form-specific or shared return page. |
| submitToSalesforce<br>Line 737 | Builds and submits the hidden native POST with standard names/custom 00N IDs. |
| syncFormState<br>Line 767 | Recomputes visibility, dates, references, derived values and prices immediately before validation. |
| clearRuleErrors<br>Line 781 | Clears earlier custom validity so corrected input can be resubmitted. |
| restoreSubmitControls<br>Line 785 | Restores controls after navigation interruption/back-forward restoration. |
| enableForms<br>Line 796 | Orchestrates all pre-submit checks, review mode, duplicate-click protection and native submission. |
| setupCodeOfConduct<br>Line 910 | Wires open/read-to-end/acknowledgement behaviour to the volunteer conduct reader. |


