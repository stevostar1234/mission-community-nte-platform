# NTE GitHub checkpoint — 8 September 2026

The owner requested a new GitHub repository containing the current complete project.

- Repository: [stevostar1234/mission-community-nte-platform](https://github.com/stevostar1234/mission-community-nte-platform)
- Visibility: **Private**, verified through the authenticated GitHub repository API.
- Branch: `main`.
- Initial contents commit: [`44d75ad6209749cc4c6905cd8a4ac26989913033`](https://github.com/stevostar1234/mission-community-nte-platform/commit/44d75ad6209749cc4c6905cd8a4ac26989913033).
- Verified initial contents: **655 files**, 8,523,849 bytes. Every remote Git blob identity matched the local staged snapshot, the recursive tree was complete, and every local source file still matched its checkpoint SHA256.
- This publication record and the related handoff updates are committed after that initial contents commit. The Salesforce implementation remains the same qualified source.

Included: current Salesforce source and complete/auxiliary manifests, forms/assets, email sources/previews, generators, tests, configuration, internal workflow/Stripe/production plans, audit summaries/screenshots, exact current qualification evidence and the original client brief.

Excluded: Git history from the earlier repositories, Salesforce authentication caches, credentials/private keys, installed dependencies, temporary snapshots and raw business-record exports. Text candidates and DOCX XML were scanned for common Stripe, GitHub and Salesforce credentials before uploading; no matches were found. This is a source/project checkpoint, with raw local audit evidence retained separately. Historical `tmp/` links refer to that preserved local workspace.

The snapshot was assembled in an isolated local Git repository; the working project's existing `origin` and `package` remotes and historical branch were preserved. For future full-project Git work, use the new private repository explicitly. The canonical public forms preview remains `stevostar1234/nte27-web-to-lead-demo`; no Salesforce package content was pushed there and no new Pages site was enabled.

The [dependency review](NTE_PACKAGE_DEPENDENCY_REVIEW_2026-09-08.md) and [qualification evidence](NTE_DEPENDENCY_QUALIFICATION_2026-09-08.json) establish the earlier 424-component package, 281 passing Apex tests and 486 matching source/manifest hashes. Stripe Payment Links was selected but not implemented at that initial checkpoint. The later authorised Stripe update below supersedes that implementation status; production remains untouched.


## Later Stripe implementation checkpoint

The private repository now includes the authorised owner-controlled Stripe sandbox integration, generated credential/configuration/payment-request metadata, client questionnaire, updated workflow/release notes, automated tests and maintained client previews. Secrets, CLI authentication files, raw mailbox/provider responses and synthetic record exports remain in ignored local storage and are excluded from the snapshot.

Final MMUAT check-only `0AfAd00000Sq7tKKAR` passed **464 components and 297 Apex tests**, with 530 unchanged source/manifest hashes. Canonical public preview commit `b81b8bced9c64a77aa7b1f31878ffca22dedaeb7` has 63/63 files byte-verified. [Exact qualification](NTE_STRIPE_QUALIFICATION_2026-09-08.json), [implementation and retained test evidence](NTE_STRIPE_SANDBOX_IMPLEMENTATION_2026-09-08.md). The owner paid both the £960 exhibitor and £2,400 partner tests. Each was verified, manually recorded in Salesforce and followed by exactly one corresponding confirmation; both payment links are now inactive after one checkout each. This checkpoint neither activates production nor claims all planned client acceptance scenarios are complete.
