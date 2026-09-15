# Preserve the client's record views

Confirmed 15 September 2026. The app determines the page. NTE Management has dedicated Lead, Account, Contact and Opportunity pages; the same record can keep its existing business view in Mission or another app. No volunteer/NTE form-type switch or new record type is needed.

The production package must not contain shared page layouts, Profiles, other apps or their Lightning pages, shared compact layouts, or standard-object metadata containers that can replace global page defaults. New NTE custom fields and permission sets do not, by themselves, add those fields to an existing layout. Existing historical sponsorship fields and other client customisations remain unchanged.

Only these UI components are included:

- The `NTE_Management` app and its five `NTE_Management_*` pages.
- The two layouts for the new `NTE_Email_Dispatch__c` and `NTE_Payment_Request__c` objects.

The complete source and manifest pass the following check. It also runs through the normal test suite. Run it again after applying any target-specific overlay and before validating the frozen production candidate:

```sh
python3 scripts/check-nte-page-isolation.py candidate --source-dir force-app/main/default --manifest manifest/production-package.xml
```

Before production, retrieve the target's existing CustomApplication, FlexiPage, Layout and Profile metadata, plus the complete Lead, Account, Contact and Opportunity object definitions, into a separate project. Confirm that retrieval succeeded and includes all expected target components. Keep that project outside the deployment source; do not copy its apps, Profiles or layouts into the NTE package. Record a baseline:

```sh
python3 scripts/check-nte-page-isolation.py snapshot --source-dir TARGET_BEFORE/force-app/main/default --output target-pages-before.json
```

After the separately authorised release, freshly retrieve the same target scope into another directory and compare it:

```sh
python3 scripts/check-nte-page-isolation.py compare --baseline target-pages-before.json --source-dir TARGET_AFTER/force-app/main/default --output target-pages-comparison.json
```

The comparison protects existing layouts and their field order, existing pages and app definitions, profile page-layout/page assignments, and shared object view/compact/search defaults. It excludes only the explicitly owned NTE components. New NTE field permissions are not mistaken for changes to profile layout assignments. Missing components, added shared definitions or changed protected settings fail the comparison. A passed source check is not a substitute for the target baseline or for UI verification.

Verify the same accessible record in NTE Management and in its business app for each of Lead, Account, Contact and Opportunity. Check the client’s volunteer, beneficiary and donor views, the relevant user profiles, and desktop/phone assignments. Keep all existing layout/record-type combinations; never set NTE as the org-wide default or copy sandbox profile assignments into production. Existing client-defined pages that happen to contain historical NTE information are not an instruction to remove that information.

The 15 September MMUAT repair clears an older Lead global override and older Mission Community Lead overrides so those views use their existing Lead layout. Its two native metadata files are retained only in local audit evidence. They are **not production deployment components**. Do not replay that sandbox repair, apply the historical Mission navigation patch, or reset production defaults automatically. The production source check deliberately rejects such shared metadata.
