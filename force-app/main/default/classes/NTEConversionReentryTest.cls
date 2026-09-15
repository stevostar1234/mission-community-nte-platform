@IsTest
private class NTEConversionReentryTest {
    @TestSetup
    static void allowReviewedConvertedLeadEdits() {
        PermissionSet access = new PermissionSet(Name='NTEConversionReentryTestAccess',
            Label='NTE conversion reentry test access', PermissionsAllowViewEditConvertedLeads=true);
        insert access;
        insert new PermissionSetAssignment(AssigneeId=UserInfo.getUserId(), PermissionSetId=access.Id);
        PermissionSet forms = [SELECT Id FROM PermissionSet WHERE Name='NTE_Forms_Administration' LIMIT 1];
        if ([SELECT COUNT() FROM PermissionSetAssignment WHERE AssigneeId=:UserInfo.getUserId()
             AND PermissionSetId=:forms.Id] == 0) {
            insert new PermissionSetAssignment(AssigneeId=UserInfo.getUserId(), PermissionSetId=forms.Id);
        }
    }

    @IsTest
    static void reclassifyingConvertedApplicationPreservesReviewedBooking() {
        NTEInboundLeadService.bypassEmailDelivery=true;
        NTEExhibitorApprovalEmailService.bypassEmailDelivery=true;
        Lead application = new Lead(FirstName='Clara', LastName='Reentry', Company='NTE Reentry Engineering',
            Email='reentry@example.invalid', Web_Form_Type__c='Exhibitor Application',
            Booking_Reference__c='NTE-REENTRY-TEST', NTE_Event_Code__c='NTE2027',
            Exhibitor_Organisation_Category__c='CIC or Not for Profit',
            Exhibitor_Space_Selections__c='Single Garage - Track Side - £799 + VAT',
            Planned_Exhibitor_Count__c='2', Total_Staff_Count__c=2, Stand_Power__c='No',
            Payment_Method__c='Bank transfer', Invoice_Requested__c='Yes',
            Event_Contact_Name__c='Original applicant contact', Invoice_Additional_Information__c='Original billing instructions');
        insert application;
        Database.LeadConvert conversion = new Database.LeadConvert();
        conversion.setLeadId(application.Id);
        conversion.setConvertedStatus([SELECT MasterLabel FROM LeadStatus WHERE IsConverted=true LIMIT 1].MasterLabel);
        conversion.setOpportunityName(application.Company + '-');
        Database.LeadConvertResult converted = Database.convertLead(conversion);
        System.assert(converted.isSuccess());
        Id bookingId=converted.getOpportunityId();
        Opportunity initial = [SELECT Id, Name, Amount, NTE_Event_Contact_Name__c,
            NTE_Invoice_Additional_Information__c, NTE_Approval_Email_Status__c FROM Opportunity WHERE Id=:bookingId];
        System.assertEquals(958.80,initial.Amount,'The actual conversion still copies and prices the application.');
        System.assertEquals(application.Company + ' - NTE2027', initial.Name,
            'The untouched native conversion name must have one separator before the event code.');
        update new Opportunity(Id=bookingId, Amount=1080.01,
            NTE_Event_Contact_Name__c='Reviewed operations contact',
            NTE_Invoice_Additional_Information__c='Revised finance instructions');
        Opportunity reviewed = [SELECT Amount,NTE_Listed_Price_Total__c,NTE_VAT_Total__c,NTE_Price_Adjustment__c,
            NTE_Event_Contact_Name__c,NTE_Invoice_Additional_Information__c FROM Opportunity WHERE Id=:bookingId];
        Test.startTest();
        // Enter a fresh user context so the test-created converted-Lead permission is effective.
        System.runAs(new User(Id=UserInfo.getUserId())) {
            update new Lead(Id=application.Id,Web_Form_Type__c='Exhibitor Expression of Interest');
            update new Lead(Id=application.Id,Web_Form_Type__c='Exhibitor Application');
        }
        Test.stopTest();
        Opportunity afterEdit = [SELECT Amount,NTE_Listed_Price_Total__c,NTE_VAT_Total__c,NTE_Price_Adjustment__c,
            NTE_Event_Contact_Name__c,NTE_Invoice_Additional_Information__c,NTE_Approval_Email_Status__c
            FROM Opportunity WHERE Id=:bookingId];
        System.assertEquals(reviewed.Amount,afterEdit.Amount,'A later converted-Lead edit must not reprice the reviewed booking.');
        System.assertEquals(reviewed.NTE_Listed_Price_Total__c,afterEdit.NTE_Listed_Price_Total__c);
        System.assertEquals(reviewed.NTE_VAT_Total__c,afterEdit.NTE_VAT_Total__c);
        System.assertEquals(reviewed.NTE_Price_Adjustment__c,afterEdit.NTE_Price_Adjustment__c);
        System.assertEquals(reviewed.NTE_Event_Contact_Name__c,afterEdit.NTE_Event_Contact_Name__c);
        System.assertEquals(reviewed.NTE_Invoice_Additional_Information__c,afterEdit.NTE_Invoice_Additional_Information__c);
        System.assertEquals(initial.NTE_Approval_Email_Status__c,afterEdit.NTE_Approval_Email_Status__c);
        System.assertEquals(0,[SELECT COUNT() FROM NTE_Payment_Request__c WHERE Opportunity__c=:bookingId]);
    }
}
