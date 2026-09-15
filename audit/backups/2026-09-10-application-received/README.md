# Application-received email backup — 10 September 2026

The owner approved stopping both exhibitor and partner/sponsor application-received emails. `application-received-originals.zip` preserves the eight original source/example/Salesforce HTML and metadata files, the original generator and send-route class, and a read-only export of both actual MMUAT templates. `SHA256.json` identifies the original maintained files.

The two templates are removed from Salesforce and the maintained package; their source/example files are preserved only in this restoration archive. The applicant send routes and retired public preview links are removed. Internal application notifications and conversion emails remain active.

To restore after an owner decision:

1. Review the original two template contents from this archive against the then-current workflow. Do not overwrite the entire generator or routing class with these historical copies.
2. Restore the two applicant template names in `NTEInboundLeadService.TEMPLATES_BY_FORM`; retain the current retry and acceptance-preservation logic.
3. Restore the two source files and their entries in the generator's email-template map, then regenerate the metadata/examples and manifest. Omit the receipt-retirement destructive manifest from that restoration release.
4. Restore the two form preview links and include their source/example pages in the next authorised preview publication.
5. Verify new-intake dispatch and failed-only retries, deploy to the intended authorised org, render both stored templates, and perform the normal package qualification. Reactivation must not automatically resend old applications.

This archive contains no credentials or live payment links. The native backup includes only the two requested email templates.
