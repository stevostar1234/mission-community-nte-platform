# NTE Management access — 11 September 2026

The owner authorised NTE sandbox testing access for Kate Lole and Tony Radford and requested simple onboarding for all production administrators and selected standard users. Proposal 15 records this approval. No production deployment is authorised by this sandbox task.

## Result

**NTE Management Access** (`NTE_Management_Access`) is deployed to MMUAT and assigned to both named users. Its status is **Updated**. It combines `NTE_Management_User` and `NTE_Stripe_Test_Operator`, so future NTE onboarding requires one permission set group assignment.

| User | Existing profile, preserved | Sandbox username | Group assignment |
| --- | --- | --- | --- |
| Kate Lole | Standard User | `kl@missioncommunity.org.mmuat` | `0PaAd00000OymvDKAR` |
| Tony Radford | System Administrator | `tr@missionmotorsport.org.mmuat` | `0PaAd00000OymvEKAR` |

Group ID: `0PGAd000000S71lOAC`. Salesforce's calculated group permission set is `0PSAd000004nMWXOA2`. Both users are active and hold Salesforce licences. Their existing direct assignments remain present. No other user was assigned this group.

The source change adds one generated permission set group and its production-manifest member. Existing permission-set definitions, Apex, object fields, forms, emails, prices, record sharing and Stripe configuration are unchanged. No application was submitted or converted, no operational email was sent and no payment/link was created. No website publication is needed for this access-only change.

## Verification

- Native group metadata was retrieved after deployment and exactly matches source; both expected constituent permission sets are present.
- All **298 effective field permissions** exactly match the union of the source permission sets. The calculated group grants the NTE application, six Apex entry points, Lead conversion, Run Reports, task access and the secure Stripe named-principal permission. Kate's Standard User profile also has event/task permissions and User External Credential access.
- The group grants create/read/edit on Lead, Account, Contact, Opportunity and NTE email dispatch, and read-only payment-request history. It grants no object-wide View All/Modify All, Modify All Data, View All Data or deletion rights. Tony retains his wider existing administrator profile permissions.
- Both users have read/edit access to **60 current client-test records**: 24 unconverted Leads, 18 bookings and their 18 Accounts. Both can read/edit the **18 linked Contacts**, and read the **14 linked email dispatches and one payment request**.
- The native NTE Operations & Finance folder contains all **nine packaged reports** and grants View to All Internal Users. Folder `AccessType=Hidden` is not evidence of denial: its separate enhanced-folder sharing entry explicitly grants access.
- Opportunity organisation-wide access is Read, but the existing packaged `NTE_Opportunities_Internal_Edit` criteria rule grants Edit on NTE Event Opportunities to All Internal Users. Direct `UserRecordAccess` checks confirm it works for Kate. No new public group, sharing rule or sharing automation was necessary.
- `npm run validate` passed. The build changed only the intended new group and production manifest. The initial assignment script had a local Apex map-syntax compilation error; it performed no DML. The corrected, sandbox-guarded and idempotent script inserted exactly two assignments successfully.
- The available browser session required a fresh login, so an interactive “Login As Kate/Tony” walkthrough was not performed. Access was verified through native assignments, effective permissions, metadata and per-user record-access checks. These checks do not claim that every user workflow was rerun.

Actual sandbox deployment: **`0AfAd00000St9iTKAR`**, successful, one component, zero component errors. No Apex changed, so the scoped permission-group deployment used NoTestRun. Full-manifest check-only validation **`0AfAd00000St9nJKAR`** completed successfully at **2026-09-11T08:11:47.000Z**, with **304/304 local tests**, zero component/test errors, **470 unique component identities** and **534 unchanged source/manifest hashes** reconciled. The component identities exactly match the prior 469 plus the new permission set group, with none missing or unexpected. [Exact qualification](NTE_MANAGEMENT_ACCESS_QUALIFICATION_2026-09-11.json).

Raw native evidence is under `tmp/nte-access-20260911/`, including before/after assignments, calculated group access, field/object permissions, folder sharing, record-access results and source hashes. No credential secret is included.

## Onboarding and production

Use **Setup → Permission Set Groups → NTE Management Access → Manage Assignments → Add Assignments**. Select the user and save; they can then refresh/sign in and choose **NTE Management** in the App Launcher. There is no need to assign either constituent separately. Salesforce documents this one-assignment model in [Permission Set Groups](https://trailhead.salesforce.com/content/learn/modules/permission-set-groups/get-started-with-permission-set-groups).

During the separately authorised production release, assign the group to every active System Administrator and the selected standard users. Add it to future user onboarding; the System Administrator profile does not automatically assign a custom group. The target must have suitable Salesforce licences and the reviewed NTE sharing/report-folder setup. The group simplifies NTE permissions; it does not replace Salesforce's underlying licence, profile and record-sharing controls.

The current second component is explicitly for the MMUAT Stripe test connection. During the approved client-account transition, replace it with the corresponding production-credential permission while keeping the same access group and one-assignment workflow. Secure principal use is controlled through [Salesforce external-credential principal access](https://help.salesforce.com/s/articleView?id=sf.nc_enable_ext_cred_principal.htm&language=en_US).

Current sandbox restrictions remain: eligible `NTE-STRIPE-` booking references and the approved `steven.skyba@anthrion.com` Primary Contact email. Operator access does not add Kate's or Tony's email to the booking-recipient allowlist, grant Stripe Dashboard access, change VAT or enable automatic payment confirmation.
