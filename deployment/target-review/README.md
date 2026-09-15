# Changes to existing target components

The separately approved 15 September volunteer extension is documented in [VOLUNTEER_LEGACY_EXTENSION.md](../VOLUNTEER_LEGACY_EXTENSION.md). Its additive pages, layouts, native conversion mappings and staff field visibility must be generated from fresh target metadata. The older patches below do not implement that extension.

These two small changes were implemented and verified separately in MMUAT on 14 September. Their components are shared with existing Mission Motorsport work and are deliberately outside the NTE production manifest. The patches preserve the exact reviewed change without packaging a complete sandbox app/report definition over the client's existing configuration.

**15 September preservation decision:** keep production's existing business views and apps unchanged. These historical patches are not automatic production steps. Follow [the page-isolation checks](../NTE_PAGE_ISOLATION.md); any future change to a shared production component needs its own specific scope and approval. Do not include the separate MMUAT Lead-default repair in the NTE package.

| Patch | Intended change | Verified MMUAT release |
| --- | --- | --- |
| `mission-leads-tab.patch` | Add Leads navigation to the existing Mission app; preserve its other tabs and profile overrides. | `0AfAd00000Sul7QKAR` |
| `legacy-nte-volunteer-filter.patch` | Exclude Volunteer Application from the existing `ActivityReports/NTE27` report, preserving all its other filters, columns and settings. | `0AfAd00000SuvrVKAR` |

Before production, retrieve the actual Mission application and, if present, the corresponding legacy report. Review and apply only the intended addition to those target definitions, then validate that small release alongside the main rollout. Native metadata may have different line numbers or additional settings; these diffs are a change reference, not a command to replace the target wholesale. If the target already has the change, no duplicate addition is needed. Do not create a missing legacy report solely to reproduce the sandbox.

The normal NTE Master Panel, NTE Lead views and nine operational reports already exclude volunteers. Volunteers remain in Mission Motorsport's Leads workflow. [Original verification and preservation evidence](../../audit/NTE_END_TO_END_AUDIT_2026-09-14.md#mission-motorsport-separation).
