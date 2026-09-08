# Project interface and copy guidance

- Keep every public form, email and supporting page natural, concise and clearly written for its actual recipient.
- Avoid formulaic or conspicuously AI-styled copy, repetitive assurances, unnecessary labels and over-explanation.
- Prefer sleek, visually clear interfaces: use layout, spacing, colour and direct control labels instead of explanatory subtitles. Remove duplicate counters, repeated recipient details and redundant controls. Keep essential accessible labels, actionable errors and meaningful status information.
- State security or process guidance once, only where it helps the user complete the task.
- Do not expose review notes, implementation rationale, architecture decisions, prototype language or fourth-wall commentary in the interface.
- Do not explain eligibility or approval stages on pages that users can only receive after completing those stages.
- Put project reasoning, traceability and internal warnings in documentation or the chat handoff instead of the product.
- Before every release, search all user-facing copy for reviewer, prototype, testing or implementation commentary and remove or rewrite it for the recipient.
- The owner authorises correcting email formatting issues whenever found. Preserve client wording and workflow; verify real Salesforce merge output as well as previews, including single currency symbols, readable text alternatives and multiline details. Keep the sandbox and client previews current with these corrections.

# Desired workflow and change decisions

- The September 2026 stress audit is complete for its recorded scope. Before follow-up work, read [NTE_AUDIT_RESUME.md](NTE_AUDIT_RESUME.md) and [the numbered audit](audit/NTE_STRESS_TEST_AND_IMPROVEMENTS_2026-09-07.md). Preserve verified records/results and do not repeat successful sends or submissions. Remaining P-numbered decisions and U-numbered ideas are not approved changes; P10 was explicitly declined. Keep the checkpoint current when the owner chooses follow-up work.

- Before NTE work, read [NTE_DESIRED_WORKFLOW.md](NTE_DESIRED_WORKFLOW.md) and the relevant entries in [NTE_CHANGE_PROPOSALS.md](NTE_CHANGE_PROPOSALS.md).
- When the user supplies changed client requirements, update the desired workflow and its decision history. Keep confirmed rules, undecided questions and implementation approvals distinct.
- Preserve stable proposal numbers and record the user's selections. An assistant recommendation or a documented desired rule is not itself approval to implement or deploy it.
- Current explicit user instructions take precedence over these notes. If old audits or existing tests contradict the confirmed desired workflow, identify that conflict instead of silently restoring the old behaviour.

# Keep the client preview site current

- The user has authorised publishing relevant approved form and email-preview changes to the existing GitHub Pages site whenever those files need updating. Include publication and verification in the same task; do not leave the client preview behind the implemented workflow or ask again for routine publication within this scope.
- Publish to the canonical `stevostar1234/nte27-web-to-lead-demo` repository and verify the hosted pages. Prepare the change from the current remote branch, preserve unrelated work, and publish only the intended website files; never push the Salesforce package branch to the forms repository.
- Maintain the desired workflow and release evidence with the publication result. This standing permission concerns the existing client preview site; production Salesforce deployment and the future NTE-hosted production website remain separately authorised releases.
