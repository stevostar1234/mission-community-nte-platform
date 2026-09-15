# NTE27 webinar invitation handover — 15 September 2026

Three standalone Classic Custom HTML invitations are complete for exhibitors, partners/sponsors and charities. The source is the owner's supplied **NTE27 Webinar invitation wording x3.docx**, matching Kate's 15 September request. The owner explicitly selected Classic HTML templates for coworker upload.

[Download the handover archive](../output/NTE27-Webinar-Invitations.zip). It includes three HTML files, three matching text alternatives and UPLOAD-NOTES.txt. Canonical source is `email-templates/webinar-invitations-2026-10-13/`.

**Subject for all three:** Invitation to the NTE27 Launch Webinar.

The navy/gold/white shell, NTE logo and footer match the established NTE email design. All supplied body paragraphs, bullets, emphasis and registration wording are retained. The placeholder salutation is replaced with the Classic `{!Contact.FirstName}` merge and the standard NTE team signature completes the closing. Upload as Custom HTML without an additional letterhead. Upload notes explain the Lead-recipient variant and the final recipient preview.

## Verification

- Parsed each Word section and hyperlink relationship; HTML body paragraphs exactly match the supplied words in their original order, apart from the intended greeting/signature substitutions.
- All three HTML and plain-text greetings successfully render through Salesforce's native Classic stored-template merge using the existing fictional Contact. No unresolved merge tokens remain. The rendered HTML bodies still match the supplied wording. Temporary private templates were rolled back in the same transaction; no invitation was sent.
- All three desktop layouts were reviewed; the shared layout was also checked at 390px. Logo loaded, the registration callout and footer remain readable, and the document has no horizontal overflow. Native mail-client differences remain subject to the coworker's final production recipient preview.
- The supplied Teams registration destination opens **National Transition Event 2027 Launch Webinar**, Tuesday **13 October at 13:00**. All three invitations use the same supplied link. No registration was submitted.
- Recipient copy contains no internal review, implementation or testing commentary. Upload guidance is separate from the email bodies.

[Content, merge and archive hashes](NTE_WEBINAR_INVITATIONS_2026-09-15.json). The first combined native render attempt exceeded the anonymous Apex script-size limit and made no change; separate successful renders completed all three checks.

These files do not add booking automation, recipient lists, schedules or live email templates. Coworker production upload and the client's eventual invitation sends are outside this completed file handover.
