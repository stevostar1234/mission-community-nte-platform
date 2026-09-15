@IsTest
private class NTEUpdateIssuesPanelTest {
    private static final String LONG_NAMES = 'Elena Stone\nTom O\'Neill\nFrançois Martin\nMina Patel\n'
        + 'A staff roster kept as submitted, including punctuation, Unicode and multiple lines.';

    @TestSetup
    static void createIssueFixtures() {
        for (PermissionSet permissions : [SELECT Id FROM PermissionSet
            WHERE Name IN ('NTE_Forms_Administration', 'NTE_Management_User')]) {
            if ([SELECT COUNT() FROM PermissionSetAssignment WHERE AssigneeId = :UserInfo.getUserId()
                AND PermissionSetId = :permissions.Id] == 0) {
                insert new PermissionSetAssignment(AssigneeId = UserInfo.getUserId(), PermissionSetId = permissions.Id);
            }
        }
        User otherOwner = new User(Alias = 'updissue', Email = 'update.issue.owner@example.invalid',
            EmailEncodingKey = 'UTF-8', LastName = 'Update issue owner', LanguageLocaleKey = 'en_US', LocaleSidKey = 'en_GB',
            ProfileId = UserInfo.getProfileId(), TimeZoneSidKey = 'Europe/London',
            Username = 'nte.issue.owner.' + UserInfo.getOrganizationId() + '.' + System.now().getTime() + '@example.invalid');
        insert otherOwner;
        System.runAs(new User(Id = UserInfo.getUserId())) {
            List<Lead> submissions = new List<Lead>();
            for (String name : new List<String>{'Missing event', 'Unknown booking', 'Ambiguous booking', 'Invalid logo',
                'Applied email failed', 'Applied email accepted', 'Applied no email', 'Pending', 'Volunteer failed', 'Application failed'}) {
                submissions.add(new Lead(LastName = name, Company = 'Update issues ' + name,
                    Email = name.replace(' ', '.').toLowerCase() + '@example.invalid', Phone = '+44 7700 900123',
                    OwnerId = otherOwner.Id, Booking_Reference__c = 'INCIDENTAL-' + name));
            }
            // Populate retained audit states after insert, without invoking the create-only submission flow.
            insert submissions;
            configure(submissions[0], 'Exhibitor Staff Update', 'No Matching Booking', null, null, 'No booking reference was supplied.');
            submissions[0].NTE_Applicant_Email_Status__c = 'Failed';
            submissions[0].NTE_Email_Error__c = 'This email error must not replace the data failure reason.';
            submissions[0].Staff_Base_Names__c = LONG_NAMES;
            submissions[0].Top_Up_Staff_Required__c = 'Yes';
            submissions[0].Top_Up_Staff_Count__c = 3;
            submissions[0].Top_Up_Staff_Names__c = 'Ava Green\nOmar Shah';
            configure(submissions[1], 'Partner / Sponsor Staff Update', 'No Matching Booking', 'NO-SUCH-BOOKING', 'NTE2097', 'No booking matches this reference.');
            submissions[1].Total_Staff_Count__c = 9;
            submissions[1].Staff_Base_Names__c = 'Sam Ellis';
            configure(submissions[2], 'Heavy Vehicle Details', 'Ambiguous Booking Reference', 'DUPLICATE-REF', null, 'More than one booking matches this reference.');
            submissions[2].Event_Contact_Name__c = 'Mara Evans';
            submissions[2].Secondary_Contact_Name__c = 'Luke Reed';
            submissions[2].Secondary_Contact_Email__c = 'luke.reed@example.invalid';
            submissions[2].Secondary_Contact_Phone__c = '+44 7700 900456';
            submissions[2].Delivery_Window__c = 'Sunday 28 February between 14:00 - 18:00';
            submissions[2].Heavy_Item_1_Description__c = 'Display vehicle';
            submissions[2].Heavy_Item_1_Registration__c = 'NTE 123';
            submissions[2].Heavy_Item_1_Dimensions__c = '5m × 2m × 2m';
            submissions[2].Heavy_Item_1_Gross_Weight__c = '2 tonnes';
            submissions[2].Haulier_Name__c = 'Fielding Transport';
            submissions[2].Haulier_Staff__c = 'Driver one\nDriver two';
            submissions[2].Haulier_Vehicle_Type__c = 'Flatbed';
            submissions[2].Haulier_Vehicle_Dimensions__c = '8m × 3m × 3m';
            submissions[2].Haulier_Vehicle_Gross_Weight__c = '8 tonnes';
            configure(submissions[3], 'Logo Update', 'Failed', 'UNKNOWN-LOGO-REF', 'NTE2099', null);
            submissions[3].Logo_Upload_URL__c = 'https://example.invalid/submitted-logo.svg';
            configure(submissions[4], 'Exhibitor Staff Update', 'Matched and Applied', 'APPLIED-BOOKING', 'NTE2097', 'A stale data error must not be shown.');
            submissions[4].NTE_Applicant_Email_Status__c = 'Failed';
            submissions[4].NTE_Email_Error__c = 'Acknowledgement rejected by the mail service.';
            submissions[4].Staff_Base_Names__c = LONG_NAMES;
            configure(submissions[5], 'Heavy Vehicle Details', 'Matched and Applied', 'ACCEPTED-BOOKING', 'NTE2097', null);
            submissions[5].NTE_Applicant_Email_Status__c = 'Accepted by Salesforce';
            configure(submissions[6], 'Logo Update', 'Matched and Applied', 'LOGO-BOOKING', 'NTE2097', null);
            submissions[6].NTE_Applicant_Email_Status__c = 'Not required';
            configure(submissions[7], 'Exhibitor Staff Update', 'Pending', 'PENDING-BOOKING', null, null);
            submissions[7].NTE_Applicant_Email_Status__c = 'Failed';
            configure(submissions[8], 'Volunteer Application', 'Failed', null, null, 'Unrelated volunteer failure');
            submissions[8].NTE_Applicant_Email_Status__c = 'Failed';
            configure(submissions[9], 'Exhibitor Application', 'Failed', null, 'NTE2097', 'Unrelated application failure');
            submissions[9].OwnerId = UserInfo.getUserId();
            update submissions;
            for (Lead submission : submissions) Test.setCreatedDate(submission.Id, System.now().addDays(-180));
        }
    }

    private static void configure(Lead submission, String formType, String status, String reference, String eventCode, String error) {
        submission.Web_Form_Type__c = formType;
        submission.NTE_Update_Status__c = status;
        submission.Target_Booking_Reference__c = reference;
        submission.NTE_Event_Code__c = eventCode;
        submission.NTE_Update_Error__c = error;
    }

    @IsTest
    static void globalCountAndRowsKeepEverySupportedFailureOutsideSelectedFilters() {
        Map<Id, Lead> before = new Map<Id, Lead>([SELECT Id, LastModifiedDate, NTE_Update_Status__c,
            NTE_Update_Error__c, NTE_Applicant_Email_Status__c, NTE_Email_Error__c FROM Lead]);
        Test.startTest();
        NTE_MasterPanelController.DashboardResponse issues = NTE_MasterPanelController.getDashboard(
            'NTE2097', 'TODAY', UserInfo.getUserId(), 'UPDATE_ISSUES', 25, 0);
        NTE_MasterPanelController.DashboardResponse ordinary = NTE_MasterPanelController.getDashboard(
            'NTE2097', 'ALL', UserInfo.getUserId(), 'APPLICATION_REVIEW', 25, 0);
        System.assertEquals(0, Limits.getDmlStatements(), 'Issue discovery is read-only.');
        System.assertEquals(0, Limits.getEmailInvocations(), 'Opening an issue must not replay an acknowledgement.');
        Test.stopTest();
        System.assertEquals('UPDATE_ISSUES', issues.selectedViewKey);
        System.assertEquals('NTE2097', issues.selectedEventCode);
        System.assertEquals('TODAY', issues.selectedTimeRange);
        System.assertEquals(UserInfo.getUserId(), issues.selectedOwnerId);
        System.assertEquals(5, issues.updateIssueCount);
        System.assertEquals(5, issues.totalRows);
        System.assertEquals(5, issues.rows.size());
        System.assertEquals(5, issues.selectedView.count);
        System.assertEquals('Update issues', issues.selectedView.label);
        System.assertEquals(new Set<String>{'Missing event', 'Unknown booking', 'Ambiguous booking', 'Invalid logo', 'Applied email failed'}, names(issues));
        System.assertEquals(null, row(issues, 'Missing event').eventCode);
        System.assertEquals(null, row(issues, 'Missing event').bookingReference);
        System.assertEquals('NO-SUCH-BOOKING', row(issues, 'Unknown booking').bookingReference);
        System.assertEquals('DUPLICATE-REF', row(issues, 'Ambiguous booking').bookingReference);
        System.assertEquals(5, ordinary.updateIssueCount, 'The issue count remains global on an ordinary filtered view.');
        System.assertEquals(1, ordinary.totalRows, 'Supplementary issues must not enter normal application counts.');
        System.assertEquals(new Set<String>{'Application failed'}, names(ordinary));
        Map<Id, Lead> after = new Map<Id, Lead>([SELECT Id, LastModifiedDate, NTE_Update_Status__c,
            NTE_Update_Error__c, NTE_Applicant_Email_Status__c, NTE_Email_Error__c FROM Lead]);
        System.assertEquals(JSON.serialize(before), JSON.serialize(after), 'Read-only discovery must preserve every captured issue field.');
    }

    @IsTest
    static void rowsDistinguishUnappliedDataFromEmailFailureAndKeepSubmittedDetails() {
        Test.startTest();
        NTE_MasterPanelController.DashboardResponse issues = NTE_MasterPanelController.getDashboard(
            null, 'ALL', null, 'UPDATE_ISSUES', 25, 0);
        Test.stopTest();
        NTE_MasterPanelController.DashboardRow dataFailure = row(issues, 'Missing event');
        System.assertEquals('NOT_APPLIED', dataFailure.updateIssueKind);
        System.assertEquals('Update not applied', dataFailure.updateIssueLabel);
        System.assertEquals('No Matching Booking', dataFailure.updateStatus);
        System.assertEquals('No booking reference was supplied.', dataFailure.updateIssueReason);
        System.assertEquals('Lead', dataFailure.objectApiName);
        System.assertEquals('/lightning/r/Lead/' + dataFailure.recordId + '/view', dataFailure.recordUrl);
        System.assertEquals('Update issues Missing event', dataFailure.organisation);
        System.assertEquals('Missing event', dataFailure.contactName);
        System.assertNotEquals(null, dataFailure.submittedAt);
        System.assertEquals(LONG_NAMES, details(dataFailure).get('Staff_Base_Names__c'));
        System.assertEquals(3, Decimal.valueOf(details(dataFailure).get('Top_Up_Staff_Count__c')));
        System.assertEquals('Ava Green\nOmar Shah', details(dataFailure).get('Top_Up_Staff_Names__c'));
        NTE_MasterPanelController.DashboardRow emailFailure = row(issues, 'Applied email failed');
        System.assertEquals('EMAIL_FAILED', emailFailure.updateIssueKind);
        System.assertEquals('Acknowledgement email failed', emailFailure.updateIssueLabel);
        System.assertEquals('Matched and Applied', emailFailure.updateStatus);
        System.assertEquals('Acknowledgement rejected by the mail service.', emailFailure.updateIssueReason);
        System.assertEquals(LONG_NAMES, details(emailFailure).get('Staff_Base_Names__c'));
        System.assertEquals('5m × 2m × 2m', details(row(issues, 'Ambiguous booking')).get('Heavy_Item_1_Dimensions__c'));
        System.assertEquals('Driver one\nDriver two', details(row(issues, 'Ambiguous booking')).get('Haulier_Staff__c'));
        System.assertEquals('https://example.invalid/submitted-logo.svg', details(row(issues, 'Invalid logo')).get('Logo_Upload_URL__c'));
        System.assertEquals('The update was not applied. Open the submission to review its details.', row(issues, 'Invalid logo').updateIssueReason);
    }

    @IsTest
    static void issuePaginationUsesCreationOrderAndDoesNotMoveEditedFailures() {
        List<Lead> extra = new List<Lead>();
        for (Integer index = 0; index < 31; index++) extra.add(new Lead(LastName = 'Paged issue ' + index,
            Company = 'Stable supplementary issues', Email = 'paged.issue.' + index + '@example.invalid'));
        insert extra;
        Datetime newestCreated = System.now().addDays(-2);
        for (Integer index = 0; index < extra.size(); index++) {
            configure(extra[index], 'Logo Update', 'Failed', index == 0 ? null : 'UNKNOWN-' + index, null, 'Saved issue ' + index);
            Test.setCreatedDate(extra[index].Id, newestCreated.addDays(-Math.max(0, index - 1)));
        }
        update extra;
        List<Id> expected = new List<Id>();
        for (Lead submission : [SELECT Id FROM Lead WHERE Web_Form_Type__c IN ('Partner / Sponsor Staff Update', 'Exhibitor Staff Update', 'Heavy Vehicle Details', 'Logo Update')
            AND (NTE_Update_Status__c IN ('No Matching Booking', 'Ambiguous Booking Reference', 'Failed')
            OR (NTE_Update_Status__c = 'Matched and Applied' AND NTE_Applicant_Email_Status__c = 'Failed'))
            ORDER BY CreatedDate DESC, Id DESC]) expected.add(submission.Id);
        NTE_MasterPanelController.DashboardResponse beforeSecond = NTE_MasterPanelController.getDashboard(
            'NTE2097', 'TODAY', UserInfo.getUserId(), 'UPDATE_ISSUES', 25, 25);
        update new Lead(Id = expected[30], NTE_Update_Error__c = 'Updated review note; submission order stays fixed.');
        Test.startTest();
        NTE_MasterPanelController.DashboardResponse first = NTE_MasterPanelController.getDashboard(
            'NTE2097', 'TODAY', UserInfo.getUserId(), 'UPDATE_ISSUES', 25, 0);
        NTE_MasterPanelController.DashboardResponse second = NTE_MasterPanelController.getDashboard(
            'NTE2097', 'TODAY', UserInfo.getUserId(), 'UPDATE_ISSUES', 25, 25);
        Test.stopTest();
        List<Id> actual = new List<Id>();
        for (NTE_MasterPanelController.DashboardRow record : first.rows) actual.add(record.recordId);
        for (Integer index = 0; index < second.rows.size(); index++) {
            actual.add(second.rows[index].recordId);
            System.assertEquals(beforeSecond.rows[index].recordId, second.rows[index].recordId);
        }
        System.assertEquals(expected, actual);
        System.assertEquals(36, first.totalRows);
        System.assertEquals(first.totalRows, first.updateIssueCount);
        System.assertEquals(25, first.rows.size());
        System.assertEquals(11, second.rows.size());
        System.assertEquals(true, first.hasNextPage);
        System.assertEquals(false, second.hasNextPage);
        System.assertEquals(actual.size(), new Set<Id>(actual).size());
    }

    @IsTest
    static void finalIssuePageHonoursCapWhenPageSizeDoesNotDivideTheLimit() {
        List<Lead> extra = new List<Lead>();
        for (Integer index = 0; index < 1996; index++) extra.add(new Lead(LastName = 'Capped issue ' + index,
            Company = 'Supplementary issue cap'));
        insert extra;
        for (Lead submission : extra) configure(submission, 'Logo Update', 'Failed', null, null, 'Retained submission');
        update extra;
        List<Lead> expectedTail = [SELECT Id FROM Lead WHERE Web_Form_Type__c IN ('Partner / Sponsor Staff Update', 'Exhibitor Staff Update', 'Heavy Vehicle Details', 'Logo Update')
            AND (NTE_Update_Status__c IN ('No Matching Booking', 'Ambiguous Booking Reference', 'Failed')
            OR (NTE_Update_Status__c = 'Matched and Applied' AND NTE_Applicant_Email_Status__c = 'Failed'))
            ORDER BY CreatedDate DESC, Id DESC LIMIT 12 OFFSET 1989];
        Test.startTest();
        NTE_MasterPanelController.DashboardResponse lastPage = NTE_MasterPanelController.getDashboard(
            'NTE2097', 'TODAY', UserInfo.getUserId(), 'UPDATE_ISSUES', 13, 10000);
        Test.stopTest();
        System.assertEquals(2001, lastPage.updateIssueCount);
        System.assertEquals(2001, lastPage.totalRows);
        System.assertEquals(2000, lastPage.accessibleRows);
        System.assertEquals(true, lastPage.rowsLimited);
        System.assertEquals(1989, lastPage.offsetRows);
        System.assertEquals(false, lastPage.hasNextPage);
        System.assertEquals(11, lastPage.rows.size(), 'The partial final page must not expose record 2,001.');
        System.assertEquals(12, expectedTail.size());
        for (Integer index = 0; index < lastPage.rows.size(); index++) {
            System.assertEquals(expectedTail[index].Id, lastPage.rows[index].recordId);
        }
        System.assertNotEquals(expectedTail[11].Id, lastPage.rows[lastPage.rows.size() - 1].recordId);
    }

    @IsTest
    static void globalIssueReadEnforcesUserPermissionsAndDoesNotEnableBulkCommunication() {
        User restricted = new User(Alias = 'updrstr', Email = 'update.issue.restricted@example.invalid',
            EmailEncodingKey = 'UTF-8', LastName = 'Restricted issue reader', LanguageLocaleKey = 'en_US', LocaleSidKey = 'en_GB',
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'Minimum Access - Salesforce' LIMIT 1].Id,
            TimeZoneSidKey = 'Europe/London', Username = 'nte.issue.restricted.' + UserInfo.getOrganizationId() + '.' + System.now().getTime() + '@example.invalid');
        insert restricted;
        System.runAs(restricted) {
            Boolean blocked = false;
            try { NTE_MasterPanelController.getDashboard(null, 'ALL', null, 'UPDATE_ISSUES', 25, 0); }
            catch (AuraHandledException expected) { blocked = true; }
            System.assert(blocked, 'The global query must not bypass USER_MODE access.');
        }
        Boolean communicationBlocked = false;
        try { NTE_MasterPanelController.getCommunicationRecordIds('NTE2097', 'ALL', null, 'UPDATE_ISSUES'); }
        catch (AuraHandledException expected) { communicationBlocked = true; }
        System.assert(communicationBlocked, 'An issue view is not a new bulk acknowledgement or replay action.');
    }

    private static Set<String> names(NTE_MasterPanelController.DashboardResponse response) {
        Set<String> result = new Set<String>();
        for (NTE_MasterPanelController.DashboardRow record : response.rows) result.add(record.name);
        return result;
    }
    private static NTE_MasterPanelController.DashboardRow row(NTE_MasterPanelController.DashboardResponse response, String name) {
        for (NTE_MasterPanelController.DashboardRow record : response.rows) if (record.name == name) return record;
        System.assert(false, 'Missing issue ' + name); return null;
    }
    private static Map<String, String> details(NTE_MasterPanelController.DashboardRow row) {
        Map<String, String> result = new Map<String, String>();
        for (NTE_MasterPanelController.UpdateIssueDetail detail : row.updateDetails) {
            System.assert(String.isNotBlank(detail.label));
            result.put(detail.key, detail.value);
        }
        return result;
    }
}
