@IsTest
private class NTEMasterPanelReadinessTest {
    private static Id recordTypeId;
    private static String stageName;

    @TestSetup
    static void fixtures() {
        for (String permissionName : new List<String>{'NTE_Forms_Administration', 'NTE_Management_User'}) {
            PermissionSet permissions = [SELECT Id FROM PermissionSet WHERE Name = :permissionName LIMIT 1];
            if ([SELECT COUNT() FROM PermissionSetAssignment WHERE AssigneeId = :UserInfo.getUserId()
                AND PermissionSetId = :permissions.Id] == 0) {
                insert new PermissionSetAssignment(AssigneeId = UserInfo.getUserId(), PermissionSetId = permissions.Id);
            }
        }
        System.runAs(new User(Id = UserInfo.getUserId())) {
            NTEInboundLeadService.bypassEmailDelivery = true;
            Account organisation = new Account(Name = 'NTE Readiness Synthetic');
            insert organisation;
            List<Opportunity> bookings = new List<Opportunity>{
                booking(organisation.Id, 'Logo outstanding', 'NTE2099', false, null),
                booking(organisation.Id, 'Ready for pack', 'NTE2099', true, null),
                booking(organisation.Id, 'Pack already sent', 'NTE2099', true, 'Sent'),
                booking(organisation.Id, 'Pack queued', 'NTE2099', true, 'Queued'),
                booking(organisation.Id, 'Different event', 'NTE2098', true, null)
            };
            insert bookings;
            Contact primary = new Contact(AccountId = organisation.Id, FirstName = 'Primary', LastName = 'Applicant',
                Email = 'primary-applicant@example.invalid', Phone = '+44 7700 900456', MobilePhone = '+44 7700 900457');
            insert primary;
            List<OpportunityContactRole> roles = new List<OpportunityContactRole>();
            for (Opportunity booking : bookings) {
                if (booking.Name == 'Logo outstanding') continue;
                roles.add(new OpportunityContactRole(OpportunityId = booking.Id, ContactId = primary.Id, IsPrimary = true));
            }
            insert roles;
            insert new List<Lead>{
                interest('Exhibitor', 'Exhibitor Expression of Interest', 'NTE2099'),
                interest('Partner', 'Partner / Sponsor Expression of Interest', 'NTE2099'),
                interest('Another event', 'Exhibitor Expression of Interest', 'NTE2098')
            };
        }
    }

    @IsTest
    static void logoAloneBlocksCompletionAndUpdatesCountersUntilProvided() {
        Opportunity logo = readiness('Logo outstanding');
        System.assertEquals(false, NTE_MasterPanelController.isComplete(logo));
        NTE_MasterPanelController.DashboardResponse before =
            NTE_MasterPanelController.getDashboard('NTE2099', 'ALL', null, 'READINESS_DUE', 25, 0);
        System.assertEquals(1, before.totalRows);
        System.assertEquals(logo.Id, before.rows[0].recordId);
        System.assertEquals(false, before.rows[0].complete);
        Map<String, Integer> beforeCounts = counts(before);
        System.assertEquals(1, beforeCounts.get('READINESS_DUE'));
        System.assertEquals(1, beforeCounts.get('LOGO_DUE'));
        System.assertEquals(3, beforeCounts.get('COMPLETED'));
        NTE_MasterPanelController.EventOverviewRow logoOverview;
        for (NTE_MasterPanelController.EventOverviewRow item : before.overview) {
            if (item.key == 'logos') logoOverview = item;
        }
        System.assertNotEquals(null, logoOverview);
        System.assertEquals('DELIVERY', logoOverview.groupKey);
        System.assertEquals('Logo updates', logoOverview.label);
        System.assertEquals('LOGO_DUE', logoOverview.viewKey);
        System.assertEquals(4, logoOverview.total);
        System.assertEquals(1, logoOverview.inProgress);
        System.assertEquals(3, logoOverview.completed);
        System.assertEquals(new Set<Id>{logo.Id}, new Set<Id>(NTE_MasterPanelController.getCommunicationRecordIds(
            'NTE2099', 'ALL', null, logoOverview.viewKey)));
        NTE_MasterPanelController.HomeDashboardResponse home = NTE_MasterPanelController.getHomeDashboard('NTE2099');
        for (NTE_MasterPanelController.HomePipelineRow row : home.pipeline) {
            if (row.key == 'UPDATES') System.assertEquals(1, row.count);
            if (row.key == 'COMPLETED') System.assertEquals(3, row.count);
        }
        logo.NTE_Logo_Update_Provided__c = true;
        logo.NTE_Logo_Update_Provided_At__c = System.now();
        update logo;
        System.assertEquals(true, NTE_MasterPanelController.isComplete(logo));
        Test.startTest();
        NTE_MasterPanelController.DashboardResponse after =
            NTE_MasterPanelController.getDashboard('NTE2099', 'ALL', null, 'COMPLETED', 25, 0);
        Test.stopTest();
        System.assertEquals(4, after.totalRows);
        System.assertEquals(0, counts(after).get('READINESS_DUE'));
        for (NTE_MasterPanelController.EventOverviewRow item : after.overview) {
            if (item.key == 'logos') {
                System.assertEquals(0, item.inProgress);
                System.assertEquals(4, item.completed);
            }
        }
        for (NTE_MasterPanelController.DashboardRow row : after.rows) System.assertEquals(true, row.complete);
    }

    @IsTest
    static void panelUsesPrimaryContactAndKeepsDayContactSeparate() {
        Test.startTest();
        NTE_MasterPanelController.DashboardResponse response =
            NTE_MasterPanelController.getDashboard('NTE2099', 'ALL', null, 'APPROVED', 25, 0);
        Test.stopTest();
        NTE_MasterPanelController.DashboardRow ready;
        NTE_MasterPanelController.DashboardRow missing;
        for (NTE_MasterPanelController.DashboardRow row : response.rows) {
            if (row.name == 'Ready for pack') ready = row;
            if (row.name == 'Logo outstanding') missing = row;
        }
        System.assertEquals('Primary Applicant', ready.contactName);
        System.assertEquals('primary-applicant@example.invalid', ready.email);
        System.assertEquals('+44 7700 900456', ready.phone);
        System.assertEquals('Event Day Person', ready.eventDayContactName);
        System.assertEquals('day-contact@example.invalid', ready.eventDayContactEmail);
        System.assertEquals('+44 7700 900999', ready.eventDayContactPhone);
        System.assertEquals('Logistics Lead', ready.logisticsContactName, 'Logistics contacts are shown separately from the primary and event day contacts.');
        System.assertEquals('logistics-lead@example.invalid', ready.logisticsContactEmail);
        System.assertEquals('+44 7700 900700', ready.logisticsContactPhone);
        System.assertEquals('Logistics Second', ready.logisticsSecondContactName);
        System.assertEquals('logistics-second@example.invalid', ready.logisticsSecondContactEmail);
        System.assertEquals('+44 7700 900701', ready.logisticsSecondContactPhone);
        System.assertEquals(null, missing.logisticsContactName, 'Bookings without a logistics submission expose no logistics contacts.');
        System.assertEquals(null, missing.logisticsSecondContactName);
        System.assertEquals(null, ready.contactIssue);
        System.assertEquals(null, missing.contactName);
        System.assertEquals(null, missing.email);
        System.assertEquals(null, missing.phone);
        System.assertEquals('Primary contact required', missing.contactIssue);
        System.assertEquals('day-contact@example.invalid', missing.eventDayContactEmail);
    }

    @IsTest
    static void absentPrimaryEmailIsFlaggedWithoutReplacingItWithDayEmail() {
        update new Contact(Id = [SELECT Id FROM Contact WHERE LastName = 'Applicant' LIMIT 1].Id, Email = null);
        Test.startTest();
        NTE_MasterPanelController.DashboardResponse response =
            NTE_MasterPanelController.getDashboard('NTE2099', 'ALL', null, 'FINAL_PACK_DUE', 25, 0);
        Test.stopTest();
        System.assertEquals(1, response.totalRows);
        System.assertEquals('Primary Applicant', response.rows[0].contactName);
        System.assertEquals(null, response.rows[0].email);
        System.assertEquals('Primary contact email required', response.rows[0].contactIssue);
        System.assertEquals('day-contact@example.invalid', response.rows[0].eventDayContactEmail);
    }

    @IsTest
    static void updateEmailIssuesUseBookingReferenceAcrossSubmissionEventCodes() {
        NTEInboundLeadService.bypassEmailDelivery = true;
        NTEUpdateSubmissionService.bypassEmailDelivery = true;
        Opportunity original = [SELECT Id, Booking_Reference__c, NTE_Event_Code__c, Amount,
            NTE_Staff_Update_Completed_At__c, NTE_Heavy_Vehicle_Required__c,
            NTE_Heavy_Vehicle_Update_Completed_At__c, NTE_Logo_Update_Provided__c,
            NTE_Event_Contact_Name__c, NTE_Event_Contact_Email__c,
            NTE_Last_Update_Type__c, NTE_Last_Update_Processed_At__c
            FROM Opportunity WHERE Name = 'Ready for pack' LIMIT 1];
        Opportunity otherBooking = [SELECT Booking_Reference__c FROM Opportunity
            WHERE Name = 'Different event' LIMIT 1];

        // Add stored audit rows after creation so the create-only update flow
        // never processes a new form submission during this read-only test.
        List<Lead> submissions = new List<Lead>();
        for (Integer index = 0; index < 4; index++) submissions.add(new Lead(
            LastName = 'Update email audit ' + index, Company = 'NTE Synthetic Update Audit',
            Email = 'update-audit-' + index + '@example.invalid'));
        insert submissions;
        for (Lead submission : submissions) {
            submission.Web_Form_Type__c = 'Heavy Vehicle Details';
            submission.Target_Booking_Reference__c = original.Booking_Reference__c;
            submission.NTE_Event_Code__c = 'NTE2100';
            submission.NTE_Update_Status__c = 'Matched and Applied';
            submission.NTE_Applicant_Email_Status__c = 'Failed';
            submission.NTE_Email_Error__c = 'Synthetic acknowledgement failure';
        }
        submissions[1].Target_Booking_Reference__c = otherBooking.Booking_Reference__c;
        submissions[2].NTE_Applicant_Email_Status__c = 'Accepted by Salesforce';
        submissions[3].NTE_Update_Status__c = 'Failed';
        update submissions;

        Test.startTest();
        List<NTE_MasterPanelController.UpdateEmailIssue> issues =
            NTE_MasterPanelController.getUpdateEmailIssues(original.Id);
        System.assertEquals(0, Limits.getEmailInvocations(), 'Reading saved email failures must not send email.');
        System.assertEquals(0, Limits.getQueueableJobs(), 'Reading saved email failures must not queue an update or retry.');
        System.assertEquals(0, Limits.getDmlStatements(), 'Reading saved email failures must not write records.');
        Test.stopTest();

        System.assertEquals(1, issues.size(), 'Only failed acknowledgements for applied updates with the exact booking reference belong to this booking.');
        System.assertEquals(submissions[0].Id, issues[0].leadId, 'A later form event code must not hide a failure matched by the booking reference.');
        System.assertEquals('Heavy Vehicle Details', issues[0].formType);
        System.assertEquals('Synthetic acknowledgement failure', issues[0].error);
        Opportunity afterRead = [SELECT Id, Booking_Reference__c, NTE_Event_Code__c, Amount,
            NTE_Staff_Update_Completed_At__c, NTE_Heavy_Vehicle_Required__c,
            NTE_Heavy_Vehicle_Update_Completed_At__c, NTE_Logo_Update_Provided__c,
            NTE_Event_Contact_Name__c, NTE_Event_Contact_Email__c,
            NTE_Last_Update_Type__c, NTE_Last_Update_Processed_At__c
            FROM Opportunity WHERE Id = :original.Id];
        System.assertEquals(original, afterRead, 'Reading email issues must leave the booking and its update history unchanged.');
    }

    @IsTest
    static void finalPackRefinersAndCommunicationSelectionSeparateSentAndQueued() {
        NTE_MasterPanelController.DashboardResponse due =
            NTE_MasterPanelController.getDashboard('NTE2099', 'ALL', null, 'FINAL_PACK_DUE', 25, 0);
        System.assertEquals(1, due.totalRows);
        System.assertEquals('Ready for pack', due.rows[0].name);
        System.assertEquals('Not sent', due.rows[0].finalPackStatus);
        Test.startTest();
        NTE_MasterPanelController.DashboardResponse sent =
            NTE_MasterPanelController.getDashboard('NTE2099', 'ALL', null, 'FINAL_PACK_SENT', 25, 0);
        Boolean rejected = false;
        try { NTE_MasterPanelController.getCommunicationRecordIds('NTE2099', 'ALL', null, 'COMPLETED'); } catch (AuraHandledException expected) { rejected=true; }
        System.assert(rejected);
        Test.stopTest();
        System.assertEquals(1, sent.totalRows);
        System.assertEquals('Pack already sent', sent.rows[0].name);
        System.assertEquals('Sent', sent.rows[0].finalPackStatus);
        System.assertNotEquals(null, sent.rows[0].finalPackSentAt);
        System.assertEquals(1, counts(due).get('FINAL_PACK_DUE'));
        System.assertEquals(1, counts(due).get('FINAL_PACK_SENT'));
        for (NTE_MasterPanelController.WorkQueue queue : due.workQueues) {
            if (new Set<String>{'COMPLETED', 'FINAL_PACK_DUE', 'FINAL_PACK_SENT'}.contains(queue.key)) {
                System.assertEquals(null, queue.listUrl, 'A completed/pack filter must not link to an unfiltered booking list.');
            }
            if (queue.key == 'APPROVED') System.assertNotEquals(null, queue.listUrl);
        }
    }

    @IsTest
    static void reopenedTopUpFinancePreservesPackHistoryAndNeverReentersUnsent() {
        Opportunity sent = [SELECT Id, NTE_Final_Pack_Sent_At__c FROM Opportunity WHERE Name = 'Pack already sent' LIMIT 1];
        Datetime originalSentAt = sent.NTE_Final_Pack_Sent_At__c;
        update new Opportunity(Id = sent.Id, NTE_Top_Up_Staff_Total__c = 50,
            NTE_Top_Up_Invoice_Required__c = true, NTE_Top_Up_Invoice_Provided__c = false,
            NTE_Top_Up_Payment_Received__c = false);
        System.assertEquals(false, NTE_MasterPanelController.isComplete(readiness('Pack already sent')));
        update new Opportunity(Id = sent.Id, NTE_Top_Up_Invoice_Provided__c = true, NTE_Top_Up_Payment_Received__c = true);
        Test.startTest();
        NTE_MasterPanelController.DashboardResponse sentAgain =
            NTE_MasterPanelController.getDashboard('NTE2099', 'ALL', null, 'FINAL_PACK_SENT', 25, 0);
        Test.stopTest();
        System.assertEquals(1, sentAgain.totalRows);
        System.assertEquals(sent.Id, sentAgain.rows[0].recordId);
        System.assertEquals(originalSentAt, sentAgain.rows[0].finalPackSentAt);
    }

    @IsTest
    static void interestSelectionRespectsTypeEventOwnerAndDecision() {
        Lead exhibitor = [SELECT Id FROM Lead WHERE LastName = 'Exhibitor' LIMIT 1];
        Lead partner = [SELECT Id FROM Lead WHERE LastName = 'Partner' LIMIT 1];
        Test.startTest();
        System.assertEquals(new Set<Id>{exhibitor.Id}, new Set<Id>(NTE_MasterPanelController.getCommunicationRecordIds(
            'NTE2099', 'ALL', UserInfo.getUserId(), 'INTEREST_EXHIBITOR')));
        System.assertEquals(new Set<Id>{partner.Id}, new Set<Id>(NTE_MasterPanelController.getCommunicationRecordIds(
            'NTE2099', 'ALL', null, 'INTEREST_PARTNER')));
        NTE_MasterPanelController.updateLeadDecision(exhibitor.Id, 'INTEREST_NOT_PROGRESSED');
        System.assertEquals(new Set<Id>{partner.Id}, new Set<Id>(NTE_MasterPanelController.getCommunicationRecordIds(
            'NTE2099', 'ALL', null, 'INTEREST')));
        Test.stopTest();
    }

    @IsTest
    static void queuedOrSentInvitationCannotBeRejected() {
        Lead exhibitor = [SELECT Id FROM Lead WHERE LastName = 'Exhibitor' LIMIT 1];
        Test.startTest();
        for (String status : new List<String>{'Queued', 'Sent'}) {
            update new Lead(Id = exhibitor.Id, NTE_Invitation_Status__c = status);
            Boolean rejected = false;
            try { NTE_MasterPanelController.updateLeadDecision(exhibitor.Id, 'INTEREST_NOT_PROGRESSED'); }
            catch (AuraHandledException expected) { rejected = true; }
            System.assert(rejected, 'An invitation with status ' + status + ' must not be rejected.');
        }
        Test.stopTest();
        System.assertEquals(false, [SELECT NTE_Interest_Not_Progressed__c FROM Lead WHERE Id = :exhibitor.Id].NTE_Interest_Not_Progressed__c);
    }

    @IsTest
    static void unrecognisedLogisticsCannotDisappearFromOutstandingWork() {
        Opportunity source = readiness('Ready for pack');
        update new Opportunity(Id = source.Id, NTE_Heavy_Vehicle_Required__c = 'Awaiting transport plan');
        Test.startTest();
        NTE_MasterPanelController.DashboardResponse panel =
            NTE_MasterPanelController.getDashboard('NTE2099', 'ALL', null, 'HEAVY_DUE', 25, 0);
        NTE_MasterPanelController.HomeDashboardResponse home = NTE_MasterPanelController.getHomeDashboard('NTE2099');
        List<Id> reminderIds = NTE_MasterPanelController.getCommunicationRecordIds('NTE2099', 'ALL', null, 'HEAVY_DUE');
        Test.stopTest();
        System.assertEquals(1, panel.totalRows);
        System.assertEquals(source.Id, panel.rows[0].recordId);
        System.assertEquals('Not confirmed', panel.rows[0].logisticsStatus);
        System.assertEquals(false, panel.rows[0].complete);
        System.assertEquals(2, counts(panel).get('READINESS_DUE'), 'The separate missing logo remains outstanding as well.');
        System.assertEquals(2, counts(panel).get('COMPLETED'));
        System.assertEquals(new Set<Id>{source.Id}, new Set<Id>(reminderIds));
        for (NTE_MasterPanelController.HomePipelineRow row : home.pipeline) {
            if (row.key == 'UPDATES') System.assertEquals(2, row.count);
            if (row.key == 'COMPLETED') System.assertEquals(2, row.count);
        }
    }

    @IsTest
    static void everyLogisticsStaffAndLogoCombinationUsesOneCompletionDefinition() {
        Opportunity sample = readiness('Ready for pack');
        for (String logistics : new List<String>{null, 'No', 'Yes', 'Not known yet', 'Awaiting transport plan'}) {
            for (Boolean timestampPresent : new List<Boolean>{false, true}) {
                for (Boolean staffPresent : new List<Boolean>{false, true}) {
                    for (Boolean logoPresent : new List<Boolean>{false, true}) {
                        sample.NTE_Heavy_Vehicle_Required__c = logistics;
                        sample.NTE_Heavy_Vehicle_Update_Completed_At__c = timestampPresent ? System.now() : null;
                        sample.NTE_Staff_Update_Completed_At__c = staffPresent ? System.now() : null;
                        sample.NTE_Logo_Update_Provided__c = logoPresent;
                        Boolean logisticsComplete = logistics == 'No' || (logistics == 'Yes' && timestampPresent);
                        System.assertEquals(logisticsComplete && staffPresent && logoPresent,
                            NTE_MasterPanelController.isComplete(sample), JSON.serialize(new List<Object>{
                                logistics, timestampPresent, staffPresent, logoPresent}));
                    }
                }
            }
        }
    }

    @IsTest
    static void communicationSelectionReturnsLimitSentinelWithoutExpandingPast501() {
        Id accountId = [SELECT Id FROM Account LIMIT 1].Id;
        List<Opportunity> more = new List<Opportunity>();
        for (Integer index = 0; index < 505; index++) more.add(booking(accountId, 'Selection ' + index, 'NTE2099', false, null));
        insert more;
        Test.startTest();
        List<Id> selected = NTE_MasterPanelController.getCommunicationRecordIds('NTE2099', 'ALL', null, 'LOGO_DUE');
        Test.stopTest();
        System.assertEquals(501, selected.size(), 'The preview must detect an oversized selection without loading unlimited records.');
        System.assertEquals(501, new Set<Id>(selected).size());
    }

    private static Opportunity booking(Id accountId, String name, String eventCode, Boolean logoProvided, String packStatus) {
        if (recordTypeId == null) recordTypeId = [SELECT Id FROM RecordType WHERE SobjectType = 'Opportunity'
            AND DeveloperName = 'NTE_Event_Opportunity' LIMIT 1].Id;
        if (stageName == null) stageName = [SELECT MasterLabel FROM OpportunityStage WHERE IsActive = true
            AND IsClosed = false ORDER BY SortOrder LIMIT 1].MasterLabel;
        return new Opportunity(
            RecordTypeId = recordTypeId, Name = name, AccountId = accountId, StageName = stageName,
            CloseDate = Date.today().addDays(30), NTE_Event_Code__c = eventCode,
            NTE_Source_Form_Type__c = 'Exhibitor Application', Booking_Reference__c = 'NTE-READINESS-' + eventCode + '-' + name,
            NTE_Free_Space_Confirmed__c = true, NTE_Approval_Email_Sent_At__c = System.now(), NTE_Invoice_Required__c = 'No', NTE_Listed_Price_Total__c = 0, Amount = 0,
            NTE_Pricing_Status__c = 'Calculated', NTE_Quote_Required_for_PO__c = 'No',
            NTE_Heavy_Vehicle_Required__c = 'No', NTE_Staff_Update_Completed_At__c = System.now(),
            NTE_Logo_Update_Provided__c = logoProvided,
            NTE_Event_Contact_Name__c = 'Event Day Person', NTE_Event_Contact_Email__c = 'day-contact@example.invalid',
            NTE_Event_Contact_Mobile__c = '+44 7700 900999',
            NTE_Logistics_Contact_Name__c = logoProvided ? 'Logistics Lead' : null,
            NTE_Logistics_Contact_Email__c = logoProvided ? 'logistics-lead@example.invalid' : null,
            NTE_Logistics_Contact_Phone__c = logoProvided ? '+44 7700 900700' : null,
            NTE_Logistics_Second_Contact_Name__c = logoProvided ? 'Logistics Second' : null,
            NTE_Logistics_Second_Contact_Email__c = logoProvided ? 'logistics-second@example.invalid' : null,
            NTE_Logistics_Second_Contact_Phone__c = logoProvided ? '+44 7700 900701' : null,
            NTE_Final_Pack_Status__c = packStatus, NTE_Final_Pack_Sent_At__c = packStatus == 'Sent' ? System.now() : null
        );
    }
    private static Lead interest(String name, String formType, String eventCode) {
        return new Lead(LastName = name, Company = 'NTE Interest ' + name, Email = name.replace(' ', '-') + '@example.invalid',
            Web_Form_Type__c = formType, NTE_Event_Code__c = eventCode);
    }
    private static Opportunity readiness(String name) {
        return [SELECT Id, NTE_Approval_Email_Sent_At__c, NTE_Free_Space_Confirmed__c, NTE_Pricing_Status__c, NTE_Quote_Required_for_PO__c, NTE_Quote_Provided__c,
            NTE_Invoice_Required__c, NTE_Listed_Price_Total__c, NTE_Invoice_Provided__c, NTE_Payment_Received__c,
            NTE_Top_Up_Invoice_Required__c, NTE_Top_Up_Staff_Total__c, NTE_Top_Up_Invoice_Provided__c,
            NTE_Top_Up_Payment_Received__c, NTE_Heavy_Vehicle_Required__c,
            NTE_Heavy_Vehicle_Update_Completed_At__c, NTE_Staff_Update_Completed_At__c,
            NTE_Logo_Update_Provided__c FROM Opportunity WHERE Name = :name LIMIT 1];
    }
    private static Map<String, Integer> counts(NTE_MasterPanelController.DashboardResponse response) {
        Map<String, Integer> result = new Map<String, Integer>();
        for (NTE_MasterPanelController.WorkQueue queue : response.workQueues) result.put(queue.key, queue.count);
        return result;
    }
}
