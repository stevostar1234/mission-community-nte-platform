/** Finance action recovery and stale-browser regression checks. */
@IsTest
private class NTEFinanceEdgeRegressionTest {
    @TestSetup static void access() {
        PermissionSet permission = [SELECT Id FROM PermissionSet WHERE Name='NTE_Forms_Administration'];
        if ([SELECT COUNT() FROM PermissionSetAssignment WHERE AssigneeId=:UserInfo.getUserId() AND PermissionSetId=:permission.Id] == 0)
            insert new PermissionSetAssignment(AssigneeId=UserInfo.getUserId(), PermissionSetId=permission.Id);
    }
    private static void configure() {
        NTEInboundLeadService.bypassEmailDelivery=true;
        NTEExhibitorApprovalEmailService.bypassEmailDelivery=true;
        NTEStripeBookingService.suppressEnqueue=true;
        NTEStripeBookingService.configurationOverride=new NTE_Stripe_Config__mdt(Enabled__c=true,Live_Mode__c=false,
            Expected_Account_Id__c='acct_NTETest',Expected_Org_Id__c=UserInfo.getOrganizationId(),Tax_Rate__c=20);
    }
    private static Id booking(String key) {
        configure();
        Lead source=new Lead(FirstName='Alex',LastName=key,Company='Finance Audit '+key,
            Email='finance.'+key.toLowerCase()+'@example.invalid',Web_Form_Type__c='Exhibitor Application',
            NTE_Event_Code__c='NTE2099',Booking_Reference__c='NTE-FINANCE-AUDIT-'+key,
            Exhibitor_Organisation_Category__c='CIC or Not for Profit',
            Exhibitor_Space_Selections__c='Single Garage - Track Side - £799 + VAT',
            Planned_Exhibitor_Count__c='2',Total_Staff_Count__c=2,Stand_Power__c='No',Heavy_Vehicle_Required__c='No',
            Payment_Method__c='Bank transfer',Invoice_Requested__c='Yes',Quote_Required_for_PO__c='Yes');
        insert source;
        Database.LeadConvert request=new Database.LeadConvert(); request.setLeadId(source.Id);
        request.setConvertedStatus([SELECT MasterLabel FROM LeadStatus WHERE IsConverted=true LIMIT 1].MasterLabel);
        request.setOpportunityName(source.Company);
        Database.LeadConvertResult result=Database.convertLead(request);
        System.assert(result.isSuccess()); return result.getOpportunityId();
    }
    @IsTest static void alreadySentBankRequestRejectsAStaleSendAction() {
        Id id=booking('BANK-SENT');
        Datetime acceptedAt=System.now().addHours(-1);
        update new Opportunity(Id=id,NTE_Approval_Email_Status__c='Sent',NTE_Approval_Email_Kind__c='Provisional',
            NTE_Approval_Email_Sent_At__c=acceptedAt);
        // Represents the second browser tab still showing the original Requirements action.
        Test.startTest();
        Boolean blocked=false;
        try { NTEFinanceService.sendFinanceAction(id,'BANK'); }
        catch (AuraHandledException expected) { blocked=true; }
        Test.stopTest();
        Opportunity current=[SELECT NTE_Approval_Email_Status__c,NTE_Approval_Email_Sent_At__c FROM Opportunity WHERE Id=:id];
        System.assert(blocked,'A stale action must not send the accepted provisional message a second time.');
        System.assertEquals('Sent',current.NTE_Approval_Email_Status__c);
        System.assertEquals(acceptedAt,current.NTE_Approval_Email_Sent_At__c);
        System.assertEquals(0,[SELECT COUNT() FROM Task WHERE WhatId=:id AND Subject IN ('NTE booking provisional email - sent', 'NTE free-space confirmation email - sent')]);
    }
    @IsTest static void acceptedStripeRequestCannotBeResentAfterALaterFailureStatus() {
        Id id=booking('STRIPE-SENT');
        Datetime acceptedAt=System.now().addHours(-1);
        update new Opportunity(Id=id,NTE_Payment_Method__c='Stripe',NTE_Approval_Email_Status__c='Failed',
            NTE_Approval_Email_Sent_At__c=acceptedAt,NTE_Approval_Email_Kind__c='Provisional');
        Boolean blocked=false;
        try { NTEFinanceService.sendFinanceAction(id,'STRIPE'); }
        catch (AuraHandledException expected) { blocked=true; }
        System.assert(blocked,'An accepted timestamp remains authoritative after a later status failure.');
        System.assertEquals(0,[SELECT COUNT() FROM NTE_Payment_Request__c WHERE Opportunity__c=:id]);
        System.assertEquals(acceptedAt,[SELECT NTE_Approval_Email_Sent_At__c FROM Opportunity WHERE Id=:id].NTE_Approval_Email_Sent_At__c);
    }
    @IsTest static void pendingBaseRequestCannotQueueTwice() {
        Id id=booking('BANK-PENDING');
        update new Opportunity(Id=id,NTE_Approval_Email_Status__c='Pending',NTE_Approval_Email_Kind__c='Provisional');
        Integer before=Limits.getQueueableJobs();Boolean blocked=false;
        try { NTEFinanceService.sendFinanceAction(id,'BANK'); }
        catch (AuraHandledException expected) { blocked=true; }
        System.assert(blocked);System.assertEquals(before,Limits.getQueueableJobs());
        System.assertEquals('Pending',[SELECT NTE_Approval_Email_Status__c FROM Opportunity WHERE Id=:id].NTE_Approval_Email_Status__c);
    }
    @IsTest static void failedUnsentBankRequestCanRetryWithoutTickingRequirements() {
        Id id=booking('BANK-RETRY');
        update new Opportunity(Id=id,NTE_Approval_Email_Status__c='Failed',NTE_Approval_Email_Error__c='Earlier send failure');
        Test.startTest();NTEFinanceService.sendFinanceAction(id,'BANK');Test.stopTest();
        Opportunity current=[SELECT NTE_Approval_Email_Status__c,NTE_Approval_Email_Error__c,NTE_Approval_Email_Sent_At__c,
            NTE_Quote_Provided__c,NTE_Invoice_Provided__c,NTE_Finance_Payment_Due__c FROM Opportunity WHERE Id=:id];
        System.assertEquals('Sent',current.NTE_Approval_Email_Status__c,'Recovered bank request: '+current.NTE_Approval_Email_Error__c);
        System.assertNotEquals(null,current.NTE_Approval_Email_Sent_At__c);
        System.assert(!current.NTE_Quote_Provided__c);System.assert(!current.NTE_Invoice_Provided__c);
        System.assert(current.NTE_Finance_Payment_Due__c);
    }
    @IsTest static void waivedBookingCanConfirmAfterAcceptedProvisional() {
        Id id=booking('WAIVER');Datetime acceptedAt=System.now().addHours(-1);
        update new Opportunity(Id=id,NTE_Approval_Email_Status__c='Sent',NTE_Approval_Email_Kind__c='Provisional',
            NTE_Approval_Email_Sent_At__c=acceptedAt);
        update new Opportunity(Id=id,Amount=0);
        Test.startTest();NTEFinanceService.sendFinanceAction(id,'FREE');Test.stopTest();
        Opportunity current=[SELECT NTE_Approval_Email_Status__c,NTE_Approval_Email_Error__c,NTE_Approval_Email_Sent_At__c,
            NTE_Free_Space_Confirmed__c,NTE_Payment_Received__c,NTE_Finance_Payment_Confirmed__c FROM Opportunity WHERE Id=:id];
        System.assertEquals('Sent',current.NTE_Approval_Email_Status__c,'Waiver: '+current.NTE_Approval_Email_Error__c);
        System.assert(current.NTE_Free_Space_Confirmed__c);System.assert(!current.NTE_Payment_Received__c);
        System.assert(current.NTE_Finance_Payment_Confirmed__c);System.assertEquals(acceptedAt,current.NTE_Approval_Email_Sent_At__c);
        Boolean blocked=false;
        try { NTEFinanceService.sendFinanceAction(id,'FREE'); } catch (AuraHandledException expected) { blocked=true; }
        System.assert(blocked,'The newly accepted free confirmation must not repeat.');
        System.assertEquals(1,[SELECT COUNT() FROM Task WHERE WhatId=:id AND Subject IN ('NTE booking provisional email - sent', 'NTE free-space confirmation email - sent')]);
    }
    @IsTest static void failedWaiverRetryKeepsOriginalProvisionalTimestamp() {
        Id id=booking('WAIVER-RETRY');Datetime acceptedAt=System.now().addHours(-1);
        update new Opportunity(Id=id,NTE_Approval_Email_Status__c='Failed',NTE_Approval_Email_Kind__c='Free confirmation',
            NTE_Approval_Email_Sent_At__c=acceptedAt);
        update new Opportunity(Id=id,Amount=0);
        Test.startTest();NTEExhibitorApprovalEmailService.retryApprovalEmail(id);Test.stopTest();
        Opportunity current=[SELECT NTE_Approval_Email_Status__c,NTE_Approval_Email_Error__c,NTE_Approval_Email_Sent_At__c,
            NTE_Free_Space_Confirmed__c FROM Opportunity WHERE Id=:id];
        System.assertEquals('Sent',current.NTE_Approval_Email_Status__c,'Waiver retry: '+current.NTE_Approval_Email_Error__c);
        System.assert(current.NTE_Free_Space_Confirmed__c);System.assertEquals(acceptedAt,current.NTE_Approval_Email_Sent_At__c);
    }
    @IsTest static void deliveredTopUpRejectsAStaleSendAction() {
        Id id=booking('TOPUP-SENT');
        update new Opportunity(Id=id,NTE_Top_Up_Staff_Count__c=1,NTE_Top_Up_Staff_Unit_Price__c=50,
            NTE_Top_Up_Staff_Total__c=50,NTE_Top_Up_VAT_Rate__c=20);
        NTEFinanceService.sendFinanceAction(id,'TOP_UP');
        NTE_Payment_Request__c payment=[SELECT Id FROM NTE_Payment_Request__c WHERE Opportunity__c=:id AND Kind__c='Staff top-up'];
        Datetime acceptedAt=System.now().addHours(-1);
        update new NTE_Payment_Request__c(Id=payment.Id,Status__c='Sent',Delivered_At__c=acceptedAt);
        update new Opportunity(Id=id,NTE_Top_Up_Payment_Requested_At__c=acceptedAt);
        Boolean blocked=false;
        try { NTEFinanceService.sendFinanceAction(id,'TOP_UP'); }
        catch (AuraHandledException expected) { blocked=true; }
        payment=[SELECT Id,Status__c,Delivered_At__c FROM NTE_Payment_Request__c WHERE Id=:payment.Id];
        System.assert(blocked,'An accepted top-up request must not be requeued by a stale Requirements action.');
        System.assertEquals('Sent',payment.Status__c);System.assertEquals(acceptedAt,payment.Delivered_At__c);
        System.assertEquals(1,[SELECT COUNT() FROM NTE_Payment_Request__c WHERE Opportunity__c=:id]);
    }
    @IsTest static void undeliveredTopUpFailureCanRetryButCannotQueueTwice() {
        Id id=booking('TOPUP-RETRY');
        update new Opportunity(Id=id,NTE_Top_Up_Staff_Count__c=1,NTE_Top_Up_Staff_Unit_Price__c=50,
            NTE_Top_Up_Staff_Total__c=50,NTE_Top_Up_VAT_Rate__c=20);
        NTEFinanceService.sendFinanceAction(id,'TOP_UP');
        NTE_Payment_Request__c payment=[SELECT Id FROM NTE_Payment_Request__c WHERE Opportunity__c=:id AND Kind__c='Staff top-up'];
        update new NTE_Payment_Request__c(Id=payment.Id,Status__c='Needs review',Error__c='Temporary provider failure');
        NTEFinanceService.sendFinanceAction(id,'TOP_UP');
        NTE_Payment_Request__c queued=[SELECT Id,Status__c,Delivered_At__c,Error__c FROM NTE_Payment_Request__c WHERE Opportunity__c=:id AND Kind__c='Staff top-up'];
        System.assertEquals(payment.Id,queued.Id);System.assertEquals('Queued',queued.Status__c);
        System.assertEquals(null,queued.Error__c);System.assertEquals(null,queued.Delivered_At__c);
        Boolean blocked=false;
        try { NTEFinanceService.sendFinanceAction(id,'TOP_UP'); } catch (AuraHandledException expected) { blocked=true; }
        System.assert(blocked);System.assertEquals(1,[SELECT COUNT() FROM NTE_Payment_Request__c WHERE Opportunity__c=:id]);
    }
    @IsTest static void bankRequestDoesNotReviveAnUnsentHistoricalStripeAttempt() {
        Id id=booking('BANK-HISTORY');
        // Earlier Stripe attempt failed before its provisional email was accepted.
        NTE_Payment_Request__c historical=new NTE_Payment_Request__c(Opportunity__c=id,Kind__c='Booking',
            Charge_Key__c=UserInfo.getOrganizationId()+':'+id+':Booking',Status__c='Needs review',
            Net_Minor__c=79900,Amount_Minor__c=95880,Tax_Rate__c=20,Currency__c='gbp',Live_Mode__c=false,
            Stripe_Account__c='acct_NTETest',Source_Fingerprint__c='historical-stripe-attempt',Error__c='Historical Stripe failure',
            Price_Id__c='price_Historical',Link_Id__c='plink_Historical',Payment_URL__c='https://buy.stripe.com/test_Historical');
        insert historical;
        NTEStripeBookingService.configurationOverride.Enabled__c=false;
        Test.startTest();NTEFinanceService.sendFinanceAction(id,'BANK');Test.stopTest();
        Opportunity current=[SELECT NTE_Approval_Email_Status__c,NTE_Approval_Email_Error__c,NTE_Approval_Email_Sent_At__c
            FROM Opportunity WHERE Id=:id];
        System.assertEquals('Sent',current.NTE_Approval_Email_Status__c,'BANK must send a bank request: '+current.NTE_Approval_Email_Error__c);
        System.assertNotEquals(null,current.NTE_Approval_Email_Sent_At__c);
        System.assertEquals(1,[SELECT COUNT() FROM NTE_Payment_Request__c WHERE Opportunity__c=:id]);
        NTE_Payment_Request__c afterRequest=[SELECT Status__c,Delivered_At__c,Error__c FROM NTE_Payment_Request__c WHERE Id=:historical.Id];
        System.assertEquals('Needs review',afterRequest.Status__c);System.assertEquals(null,afterRequest.Delivered_At__c);
        System.assertEquals('Historical Stripe failure',afterRequest.Error__c,'The bank request does not rewrite provider history.');
        Opportunity displayed=[SELECT Id,Name,Account.Name,Amount,Booking_Reference__c,NTE_Source_Form_Type__c,NTE_Payment_Method__c,
            NTE_Listed_Price_Total__c,NTE_VAT_Rate__c,NTE_Sponsor_Package__c,NTE_Sponsor_Package_Total__c,
            NTE_Exhibitor_Space_Price__c,NTE_Power_Socket_Count__c,NTE_Power_Socket_Unit_Price__c,NTE_Power_Socket_Total__c,
            NTE_Additional_Staff_Count__c,NTE_Additional_Staff_Unit_Price__c,NTE_Additional_Staff_Total__c,
            NTE_Price_Adjustment__c,NTE_Heavy_Vehicle_Required__c,NTE_Exhibitor_Space_Selections__c,
            NTE_Exhibitor_Organisation_Category__c FROM Opportunity WHERE Id=:id];
        Contact recipient=NTEBookingContactService.primaryContacts(new Set<Id>{id},AccessLevel.SYSTEM_MODE,false).get(id);
        System.assertEquals(null,NTEStripeBookingService.emailReadinessError(displayed,recipient),
            'BANK remains independent even when the Stripe configuration is disabled.');
        Id templateId=[SELECT Id FROM EmailTemplate WHERE DeveloperName='NTE_Exhibitor_Approved' LIMIT 1].Id;
        String html=NTEExhibitorApprovalEmailService.renderBookingEmail(displayed,recipient,templateId,NTE_Routing_Config__mdt.getInstance('Default'),false).getHtmlBody();
        System.assert(html.contains('bank transfer'));
        System.assert(!html.contains('test_Historical'));System.assert(!html.contains('data-nte-payment-button'));
    }
}
