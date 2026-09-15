# Volunteer field compatibility review — 15 September 2026

Status: read-only assessment. The owner explicitly requested discussion before implementation. No volunteer field, form, layout, conversion mapping, record or production setting was changed. This review follows the separately completed NTE app-page repair.

## Recommended approach

Keep the existing volunteer data model and API names. Reuse each existing field when the new question has the same meaning; add optional fields only for genuinely new questions. Preserve old field values, data types, choices, permissions, mappings and all existing page sections. Older records must remain viewable and editable with the new answers blank/not recorded. Do not infer answers, rewrite historic consent or migrate volunteers into a separate NTE model.

Show the new answers in a clearly separate Volunteer application section on the appropriate Mission pages. This is a proposed, specifically reviewed extension to the volunteer view, not permission to replace other business pages or import sandbox layouts into production. Keep NTE pages app-specific. A person may be both a beneficiary and volunteer; preserve existing record classification and the volunteer flag.

## Confirmed findings

1. The new form reuses standard Lead identity/contact/address fields plus the eight established custom volunteer fields: date of birth, three next-of-kin fields, the volunteering checkbox and three existing consent fields. Shared declaration fields remain separate captured application evidence.
2. The existing 37-field Lead layout has no monthly hours, availability, opportunities, skills, travel regions, DBS willingness, new emergency address or Code of Conduct fields. It also omits standard MobilePhone; the form correctly distinguishes mobile from optional home Phone. These are display gaps, not missing submissions. A count-only query confirmed that the recent volunteer submission has a saved monthly-hours answer without reading its value.
3. The newly added custom questions are optional at Salesforce field level. The Code of Conduct rule applies only on creation of the current v3 form, not retrospectively when historical records are edited.
4. The native conversion configuration has 25 existing custom mappings. It already maps Date_of_Birth__c to Contact.Birthdate__c; next-of-kin and consent fields to their existing Contact fields; and Interested_in_Volunteering__c to Contact.Is_Volunteer__c. Different API names across objects are expected when connected by the saved mapping. Preserve all 25 mappings.
5. None of the Volunteer_* questions, new emergency address/postcode or application declaration fields has a native custom conversion mapping. New monthly hours/availability/etc have no matching destination fields on Contact/Person Account in the inspected metadata. Their source Lead remains, but the new answers will not automatically appear on the converted volunteer record.
6. The existing Accounts Volunteers view includes the Volunteer Person Account record type OR the Is_Volunteer__pc flag. A count-only query found three matching Person Accounts: one Volunteer and two Beneficiaries. This confirms that overlapping roles already exist. The public form currently supplies Company = Individual Volunteer. Under native Lightning conversion, populated Company selects the business-account route; this needs a volunteer-specific decision/correction before new applications join that existing Person Account register. Do not change NTE organisation conversion or reclassify existing beneficiaries.
7. The new Lead list named Volunteer Applications filters on Web_Form_Type__c = Volunteer Application. An older manually entered Lead with that field blank is excluded from that particular list, although its record remains. Preserve current lists and, if approved, provide a combined volunteer view using the existing volunteer flag as well as the new form type.

## Meaning differences to preserve

The new Yes/No Armed Forces question and free-text service/unit/date answers are not equivalent to the old structured Service, Relationship to Forces, Service Number, Rank and service-end fields. Keep the structured fields intact; do not guess their values from free text or redirect a Yes/No answer into a different picklist. Similarly, the new skills checklist is not a replacement for the existing rich-text Skills Profile. Any desired future consolidation requires an explicit semantic mapping.

## Field-by-field evidence

The table compares the current form with the freshly retrieved MMUAT Lead layout and native custom conversion settings. Standard Lead fields use Salesforce standard conversion rules. A dash means no custom conversion mapping was found, not that the submitted Lead value is lost.

| Form API name | On existing Lead layout | Current conversion destination |
| --- | --- | --- |
| `Web_Form_Type__c` | No | — |
| `Volunteer_Form_Version__c` | No | — |
| `Company` | No | Standard Salesforce mapping |
| `Interested_in_Volunteering__c` | Yes | `Contact.Is_Volunteer__c` |
| `Consent_PII__c` | Yes | `Contact.Consent_PII__c` |
| `Consent_Contact__c` | Yes | `Contact.Consent_Contact__c` |
| `Consent_Promotion__c` | Yes | `Contact.Consent_Promotion__c` |
| `FirstName` | Yes | Standard Salesforce mapping |
| `LastName` | Yes | Standard Salesforce mapping |
| `Date_of_Birth__c` | Yes | `Contact.Birthdate__c` |
| `MobilePhone` | No | Standard Salesforce mapping |
| `Phone` | Yes | Standard Salesforce mapping |
| `Email` | Yes | Standard Salesforce mapping |
| `Street` | Yes | Standard Salesforce mapping |
| `PostalCode` | Yes | Standard Salesforce mapping |
| `NOK_Name__c` | Yes | `Contact.NOK_Name__c` |
| `NOK_Relationship__c` | Yes | `Contact.NOK_Relationship__c` |
| `NOK_Phone__c` | Yes | `Contact.NOK_Phone__c` |
| `NOK_Address__c` | No | — |
| `NOK_Postcode__c` | No | — |
| `Volunteer_Armed_Forces_Service__c` | No | — |
| `Volunteer_Service_Details__c` | No | — |
| `Volunteer_Service_Dates__c` | No | — |
| `Volunteer_Opportunities__c` | No | — |
| `Volunteer_Skills__c` | No | — |
| `Volunteer_Travel_Regions__c` | No | — |
| `Volunteer_DBS_Willing__c` | No | — |
| `Volunteer_Hours__c` | No | — |
| `Volunteer_Availability__c` | No | — |
| `Volunteer_Code_Consent__c` | No | — |
| `Volunteer_Code_Version__c` | No | — |
| `Volunteer_Consent__c` | No | — |
| `Declaration_Name__c` | No | — |
| `Declaration_Date__c` | No | — |

LeadSource is also supplied as Volunteer Application by the form configuration; it is not a data-sf-field control. The actual web form translates the API names to environment-specific Web-to-Lead field IDs. Production must use its own organisation/field IDs.

## Scope of a later approved implementation

- Compare the real production legacy field definitions and mappings before building the candidate; MMUAT is the evidence source for this review. Preserve target-specific field definitions rather than blindly replacing them with sandbox copies.
- Add only the missing display controls and optional destination fields; retain current details and native actions. Do not require new answers on old records.
- Agree and qualify volunteer conversion into the existing Person Account/volunteer model, including reuse of an existing beneficiary who also volunteers. Preserve existing Account/Contact data during reuse.
- Add the new answer mappings without removing any existing mapping. Keep the original submitted Lead and application evidence.
- Check old/new list visibility and the separate Mission volunteer permission set. Existing NTE access is not a substitute for volunteer access.
- Use fresh approved tests for an old-style record with blanks, a complete new form, conversion to a new volunteer and reuse of an existing volunteer/beneficiary. Confirm the new details remain visible after conversion and other apps stay unchanged.

No implementation is approved by this recommendation. No old record cleanup, backfill, merge, reclassification, production deployment or retrospective mandatory-field rule is proposed.

## Primary sources and local evidence

- [Salesforce: conversion rules, Person Accounts, standard/custom mappings and preservation of existing values](https://help.salesforce.com/s/articleView?id=sf.leads_notes.htm&language=en_US&type=5).
- [Current volunteer form](../volunteer-application.html), [field generator](../scripts/build-metadata.js), [inherited field inventory](../pre-production-dependancies.md).
- Native page/field snapshot: local tmp/nte-layout-isolation-20260915/native-after/.
- Native conversion settings, count-only queries and detailed mapping JSON: local tmp/volunteer-compatibility-20260915/.

The production org has not been inspected or changed in this review.
