@IsTest
private class NTEManualFinanceTest {
    @TestSetup static void access() {
        PermissionSet permission = [SELECT Id FROM PermissionSet WHERE Name='NTE_Forms_Administration'];
        if ([SELECT COUNT() FROM PermissionSetAssignment WHERE AssigneeId=:UserInfo.getUserId() AND PermissionSetId=:permission.Id]==0)
            insert new PermissionSetAssignment(AssigneeId=UserInfo.getUserId(), PermissionSetId=permission.Id);
    }
    private static Lead application(String key, Boolean free) {
        NTEInboundLeadService.bypassEmailDelivery=true;
        NTEExhibitorApprovalEmailService.bypassEmailDelivery=true;
        Lead value=new Lead(FirstName='Alex', LastName=key, Company='Manual Finance '+key,
            Email='finance.'+key.toLowerCase().replaceAll('[^a-z0-9.-]','-')+'@example.invalid',
            Web_Form_Type__c='Exhibitor Application', NTE_Event_Code__c='NTE2099', Booking_Reference__c='NTE-MANUAL-'+key,
            Exhibitor_Organisation_Category__c=free ? 'Charity - member of Cobseo' : 'CIC or Not for Profit',
            Exhibitor_Space_Selections__c=free ? 'COBSEO Charity - Single - Free' : 'Single Garage - Track Side - £799 + VAT',
            Planned_Exhibitor_Count__c='2', Total_Staff_Count__c=2, Stand_Power__c='No', Heavy_Vehicle_Required__c='No',
            Payment_Method__c=free ? null : 'Bank transfer', Invoice_Requested__c=free ? null : 'Yes', Quote_Required_for_PO__c='Yes', Purchase_Order__c='Yes',
            Purchase_Order_Number__c='PO-123', Supplier_Agreement_Required__c='Yes', Invoice_Additional_Information__c='Department 4\nCost centre 51');
        insert value; return value;
    }
    private static Database.LeadConvert convertRequest(Lead value) {
        Database.LeadConvert request=new Database.LeadConvert(); request.setLeadId(value.Id);
        request.setConvertedStatus([SELECT MasterLabel FROM LeadStatus WHERE IsConverted=true LIMIT 1].MasterLabel);
        request.setOpportunityName(value.Company); return request;
    }
    private static Opportunity convert(Lead value) {
        Database.LeadConvertResult result=Database.convertLead(convertRequest(value)); System.assert(result.isSuccess());
        return state(result.getOpportunityId());
    }
    private static Opportunity state(Id id) {
        return [SELECT Id, Name, Amount, Booking_Reference__c, NTE_Event_Code__c, LastModifiedDate,
            NTE_Source_Form_Type__c, NTE_Payment_Method__c, NTE_Approval_Email_Lead_Id__c,
            NTE_Approval_Email_Status__c, NTE_Approval_Email_Sent_At__c, NTE_Free_Space_Confirmed__c, NTE_Listed_Price_Total__c, NTE_Pricing_Status__c,
            NTE_Invoice_Required__c, NTE_Invoice_Requested__c, NTE_Quote_Required_for_PO__c, NTE_Quote_Provided__c, NTE_Invoice_Provided__c,
            NTE_PO_Confirmed__c, NTE_Payment_Received__c, NTE_Top_Up_Invoice_Required__c, NTE_Top_Up_Invoice_Provided__c,
            NTE_Top_Up_Payment_Received__c, NTE_Top_Up_Staff_Total__c, NTE_Top_Up_Payment_Requested_At__c,
            NTE_Finance_Requirements_Due__c, NTE_Finance_Payment_Due__c, NTE_Finance_Payment_Confirmed__c,
            NTE_Heavy_Vehicle_Required__c, NTE_Heavy_Vehicle_Update_Completed_At__c, NTE_Staff_Update_Completed_At__c,
            NTE_Logo_Update_Provided__c, NTE_Final_Pack_Status__c, NTE_Final_Pack_Sent_At__c FROM Opportunity WHERE Id=:id];
    }
    @IsTest static void conversionIsSilentAndRequiresANewBooking() {
        Lead lead=application('SILENT',false);
        Test.startTest(); Opportunity booking=convert(lead); Test.stopTest(); booking=state(booking.Id);
        System.assertEquals('Manual Finance SILENT - NTE2099',booking.Name);
        System.assertEquals(String.valueOf(lead.Id),booking.NTE_Approval_Email_Lead_Id__c);
        System.assertEquals(null,booking.NTE_Approval_Email_Sent_At__c);
        System.assertNotEquals('Pending',booking.NTE_Approval_Email_Status__c);
        System.assert(booking.NTE_Finance_Requirements_Due__c); System.assert(!booking.NTE_Finance_Payment_Due__c);
        System.assertEquals(0,[SELECT COUNT() FROM NTE_Payment_Request__c]);
        System.assertEquals(0,[SELECT COUNT() FROM Task WHERE WhatId=:booking.Id]);
    }
    @IsTest static void noOpportunityIsRejected() {
        Lead lead=application('NOBOOKING',false); Database.LeadConvert request=convertRequest(lead); request.setDoNotCreateOpportunity(true);
        Database.LeadConvertResult result=Database.convertLead(request,false);
        System.assert(!result.isSuccess()); System.assert(![SELECT IsConverted FROM Lead WHERE Id=:lead.Id].IsConverted);
    }
    @IsTest static void existingBookingIsRejectedWithoutChangingIt() {
        Lead first=application('FIRST',false); Opportunity booking=convert(first);
        Lead second=application('SECOND',false); Database.LeadConvert request=convertRequest(second);
        Lead saved=[SELECT ConvertedAccountId,ConvertedContactId FROM Lead WHERE Id=:first.Id];
        request.setAccountId(saved.ConvertedAccountId); request.setContactId(saved.ConvertedContactId); request.setOpportunityId(booking.Id);
        Database.LeadConvertResult result=Database.convertLead(request,false);
        System.assert(!result.isSuccess()); System.assertEquals(String.valueOf(first.Id),state(booking.Id).NTE_Approval_Email_Lead_Id__c);
    }
    @IsTest static void bankActionDoesNotTickRequirements() {
        Opportunity booking=convert(application('BANK',false));
        Test.startTest(); NTEFinanceService.sendFinanceAction(booking.Id,'BANK'); Test.stopTest();
        booking=state(booking.Id); System.assertEquals('Sent',booking.NTE_Approval_Email_Status__c);
        System.assert(!booking.NTE_Quote_Provided__c); System.assert(!booking.NTE_Invoice_Provided__c); System.assert(!booking.NTE_PO_Confirmed__c);
        System.assert(!booking.NTE_Finance_Requirements_Due__c); System.assert(booking.NTE_Finance_Payment_Due__c);
    }
    @IsTest static void checklistPersistsIndependently() {
        Opportunity booking=convert(application('CHECKLIST',false));
        NTEFinanceService.setRequirement(booking.Id,'NTE_PO_Confirmed__c',true);
        NTEFinanceService.setRequirement(booking.Id,'NTE_Invoice_Provided__c',true);
        booking=state(booking.Id); System.assert(booking.NTE_PO_Confirmed__c); System.assert(booking.NTE_Invoice_Provided__c);
        System.assert(!booking.NTE_Quote_Provided__c); System.assert(booking.NTE_Finance_Requirements_Due__c); System.assert(!booking.NTE_Finance_Payment_Due__c);
        for (NTEFinanceService.Requirement item:NTE_MasterPanelController.getDashboard('NTE2099','ALL',null,'REQUIREMENTS',25,0).rows[0].requirements)
            if (item.key=='NTE_Bank_Details_Provided__c') System.assertEquals('Provided Bank details for Bank transfer',item.label);
    }
    @IsTest static void quotationAndInvoiceShowOnlySuppliedDocumentNames() {
        Opportunity booking = new Opportunity(NTE_Quote_Required_for_PO__c='Yes', NTE_Invoice_Requested__c='Yes',
            NTE_Listed_Price_Total__c=800, NTE_Top_Up_Staff_Total__c=50,
            NTE_Invoiced_Company__c='  Élan R&D <Careers> Ltd  ', NTE_Trading_Name__c=' Careers & Futures ');
        List<NTEFinanceService.Requirement> rows = NTEFinanceService.requirements(booking);
        System.assertEquals(3, rows.size());
        for (NTEFinanceService.Requirement row : rows) System.assertEquals(
            'Name: Élan R&D <Careers> Ltd\nTrading name: Careers & Futures', row.detail);
        booking.NTE_Invoiced_Company__c=null; booking.NTE_Trading_Name__c='  ';
        for (NTEFinanceService.Requirement row : NTEFinanceService.requirements(booking)) System.assertEquals(null, row.detail);
        booking.NTE_Trading_Name__c='Trade name only';
        for (NTEFinanceService.Requirement row : NTEFinanceService.requirements(booking)) System.assertEquals('Trading name: Trade name only', row.detail);
    }
    @IsTest static void freeConfirmationAndJoiningInstructionsAreSeparate() {
        Opportunity booking=convert(application('FREE',true));
        update new Opportunity(Id=booking.Id,NTE_Staff_Update_Completed_At__c=System.now(),NTE_Logo_Update_Provided__c=true);
        System.assert(!NTE_MasterPanelController.isComplete(state(booking.Id)));
        Test.startTest(); NTEFinanceService.sendFinanceAction(booking.Id,'FREE'); Test.stopTest();
        booking=state(booking.Id); System.assertEquals(0,booking.NTE_Listed_Price_Total__c); System.assert(booking.NTE_Finance_Payment_Confirmed__c);
        System.assert(NTE_MasterPanelController.isComplete(booking)); System.assert(!booking.NTE_Quote_Provided__c);
        Integer before=Limits.getEmailInvocations(); NTEFinanceService.setJoiningInstructions(booking.Id,true);
        System.assertEquals(before,Limits.getEmailInvocations()); System.assertEquals('Sent',state(booking.Id).NTE_Final_Pack_Status__c);
        System.assertEquals(0,[SELECT COUNT() FROM NTE_Email_Dispatch__c WHERE Kind__c='FINAL_PACK']);
    }
    @IsTest static void paidConfirmationNeedsNoProcurementTicks() {
        Opportunity booking=convert(application('PAID',false));
        update new Opportunity(Id=booking.Id,NTE_Approval_Email_Sent_At__c=System.now());
        NTEEmailDispatchService.bypassEmailDelivery=true;
        Test.startTest(); NTE_MasterPanelController.updateMilestone(booking.Id,'PAYMENT_RECEIVED'); Test.stopTest();
        booking=state(booking.Id); System.assert(booking.NTE_Payment_Received__c); System.assert(!booking.NTE_Invoice_Provided__c); System.assert(!booking.NTE_Quote_Provided__c);
        System.assert(booking.NTE_Finance_Payment_Confirmed__c);
        System.assertEquals(1,[SELECT COUNT() FROM NTE_Email_Dispatch__c WHERE Opportunity__c=:booking.Id AND Kind__c='BOOKING_CONFIRMED']);
    }
    @IsTest static void commercialFreeSpacesConvertAndConfirmThroughTheManualAction() {
        List<Opportunity> bookings = new List<Opportunity>();
        for (String space : new List<String>{'COBSEO Charity - Single - Free', 'Non COBSEO Charity - Single - Free'}) {
            Lead lead = application('COMMERCIAL-FREE-' + bookings.size(), true);
            lead.Exhibitor_Organisation_Category__c = 'Employer - Automotive Sector';
            lead.Exhibitor_Space_Selections__c = space;
            update lead;
            Opportunity booking = convert(lead);
            System.assertEquals(0, booking.Amount);
            System.assertEquals('Calculated', booking.NTE_Pricing_Status__c);
            System.assert(!booking.NTE_Free_Space_Confirmed__c);
            System.assertEquals(null, booking.NTE_Approval_Email_Sent_At__c, 'Conversion remains silent.');
            bookings.add(booking);
        }
        update new Opportunity(Id = bookings[1].Id, NTE_Approval_Email_Status__c = 'Failed',
            NTE_Approval_Email_Kind__c = 'Free confirmation', NTE_Approval_Email_Error__c = 'The booking price needs review.');
        Test.startTest();
        for (Opportunity booking : bookings) NTEFinanceService.sendFinanceAction(booking.Id, 'FREE');
        Test.stopTest();
        Set<Id> bookingIds = new Map<Id, Opportunity>(bookings).keySet();
        for (Opportunity booking : bookings) {
            Opportunity outcome = state(booking.Id);
            System.assertEquals('Sent', outcome.NTE_Approval_Email_Status__c);
            System.assert(outcome.NTE_Free_Space_Confirmed__c);
            System.assert(outcome.NTE_Finance_Payment_Confirmed__c);
            System.assert(!outcome.NTE_Payment_Received__c);
            Boolean duplicateBlocked = false;
            try { NTEFinanceService.sendFinanceAction(booking.Id, 'FREE'); }
            catch (AuraHandledException expected) { duplicateBlocked = true; }
            System.assert(duplicateBlocked, 'A confirmed free space must not send twice.');
        }
        System.assertEquals(2, [SELECT COUNT() FROM Task WHERE WhatId IN :bookingIds
            AND Subject IN ('NTE booking provisional email - sent', 'NTE free-space confirmation email - sent')]);
        System.assertEquals(0, [SELECT COUNT() FROM NTE_Payment_Request__c WHERE Opportunity__c IN :bookingIds]);
    }
    @IsTest static void topUpPaymentCanPrecedeBasePayment() {
        Opportunity booking=convert(application('TOPUP',false));
        update new Opportunity(Id=booking.Id,NTE_Top_Up_Staff_Total__c=100,NTE_Top_Up_Payment_Requested_At__c=System.now());
        NTE_MasterPanelController.updateMilestone(booking.Id,'TOP_UP_PAYMENT_RECEIVED'); booking=state(booking.Id);
        System.assert(booking.NTE_Top_Up_Payment_Received__c); System.assert(!booking.NTE_Payment_Received__c);
        System.assert(!booking.NTE_Top_Up_Invoice_Provided__c); System.assertEquals(0,[SELECT COUNT() FROM NTE_Email_Dispatch__c]);
    }
    @IsTest static void laterTopUpReturnsPaidBookingThroughFinanceStages() {
        Opportunity booking=convert(application('LATER-TOPUP',false));
        update new Opportunity(Id=booking.Id,NTE_Approval_Email_Sent_At__c=System.now(),NTE_Payment_Received__c=true,NTE_PO_Confirmed__c=true);
        System.assert(state(booking.Id).NTE_Finance_Payment_Confirmed__c);
        update new Opportunity(Id=booking.Id,NTE_Top_Up_Staff_Total__c=50,NTE_Top_Up_Invoice_Required__c=true);
        booking=state(booking.Id);
        System.assert(booking.NTE_Finance_Requirements_Due__c);System.assert(!booking.NTE_Finance_Payment_Due__c);System.assert(!booking.NTE_Finance_Payment_Confirmed__c);
        NTE_MasterPanelController.DashboardRow row=NTE_MasterPanelController.getDashboard('NTE2099','ALL',null,'REQUIREMENTS',25,0).rows[0];
        System.assert(row.canSendTopUp);System.assert(!row.canSendBase);System.assert(!row.canMarkPaid);System.assert(!row.canMarkTopUpPaid);
        update new Opportunity(Id=booking.Id,NTE_Top_Up_Payment_Requested_At__c=System.now());
        booking=state(booking.Id);
        System.assert(!booking.NTE_Finance_Requirements_Due__c);System.assert(booking.NTE_Finance_Payment_Due__c);System.assert(!booking.NTE_Finance_Payment_Confirmed__c);
        row=NTE_MasterPanelController.getDashboard('NTE2099','ALL',null,'PAYMENT_DUE',25,0).rows[0];
        System.assert(!row.canSendTopUp);System.assert(!row.canSendBase);System.assert(!row.canMarkPaid);System.assert(row.canMarkTopUpPaid);
        NTE_MasterPanelController.updateMilestone(booking.Id,'TOP_UP_PAYMENT_RECEIVED');booking=state(booking.Id);
        System.assert(booking.NTE_Payment_Received__c);System.assert(booking.NTE_Finance_Payment_Confirmed__c);System.assert(!booking.NTE_Finance_Requirements_Due__c);System.assert(!booking.NTE_Finance_Payment_Due__c);
        System.assert(booking.NTE_PO_Confirmed__c);System.assert(!booking.NTE_Invoice_Provided__c);System.assert(!booking.NTE_Top_Up_Invoice_Provided__c);
        System.assertEquals(0,[SELECT COUNT() FROM NTE_Email_Dispatch__c]);
    }
    @IsTest static void newUnrequestedTopUpTakesPriorityOverExistingUnpaidBookingRequest() {
        Opportunity booking=convert(application('UNPAID-TOPUP',false));
        update new Opportunity(Id=booking.Id,NTE_Approval_Email_Sent_At__c=System.now(),NTE_Top_Up_Staff_Total__c=50);
        booking=state(booking.Id);System.assert(booking.NTE_Finance_Requirements_Due__c);System.assert(!booking.NTE_Finance_Payment_Due__c);
        System.assertEquals(0,NTE_MasterPanelController.getDashboard('NTE2099','ALL',null,'PAYMENT_DUE',25,0).rows.size());
        update new Opportunity(Id=booking.Id,NTE_Top_Up_Payment_Requested_At__c=System.now());
        booking=state(booking.Id);System.assert(!booking.NTE_Finance_Requirements_Due__c);System.assert(booking.NTE_Finance_Payment_Due__c);
    }

    @IsTest static void ordinaryConversionsKeepAllNativeOpportunityChoices() {
        Account organisation=new Account(Name='Unrelated conversion organisation');
        insert organisation;
        Contact contact=new Contact(AccountId=organisation.Id, FirstName='Ordinary', LastName='Contact',
            Email='ordinary-conversion@example.invalid');
        insert contact;
        Opportunity existing=new Opportunity(AccountId=organisation.Id, Name='Unrelated existing opportunity',
            StageName=[SELECT MasterLabel FROM OpportunityStage WHERE IsActive=true AND IsClosed=false ORDER BY SortOrder LIMIT 1].MasterLabel,
            CloseDate=Date.today().addDays(30), Amount=123.45);
        insert existing;
        List<Lead> leads=new List<Lead>();
        for (String choice : new List<String>{'No opportunity','New opportunity','Existing opportunity'})
            leads.add(new Lead(FirstName='Ordinary', LastName=choice, Company='Unrelated '+choice,
                Email='ordinary-'+leads.size()+'@example.invalid'));
        insert leads;
        List<Database.LeadConvert> requests=new List<Database.LeadConvert>();
        for (Lead lead : leads) {
            Database.LeadConvert request=convertRequest(lead);
            request.setAccountId(organisation.Id); request.setContactId(contact.Id);
            requests.add(request);
        }
        requests[0].setOpportunityName(null); requests[0].setDoNotCreateOpportunity(true);
        requests[2].setOpportunityName(null); requests[2].setOpportunityId(existing.Id);

        Test.startTest();
        List<Database.LeadConvertResult> results=Database.convertLead(requests,false);
        System.assertEquals(0,Limits.getQueueableJobs(),'Ordinary conversion must not queue NTE work.');
        System.assertEquals(0,Limits.getEmailInvocations(),'Ordinary conversion must not invoke NTE email.');
        Test.stopTest();

        System.assertEquals(3,results.size());
        for (Integer index=0; index<results.size(); index++) {
            System.assert(results[index].isSuccess(),String.valueOf(results[index].getErrors()));
            System.assertEquals(leads[index].Id,results[index].getLeadId());
            System.assertEquals(organisation.Id,results[index].getAccountId());
            System.assertEquals(contact.Id,results[index].getContactId());
        }
        System.assertEquals(null,results[0].getOpportunityId());
        System.assertNotEquals(null,results[1].getOpportunityId());
        System.assertNotEquals(existing.Id,results[1].getOpportunityId());
        System.assertEquals(existing.Id,results[2].getOpportunityId());
        System.assertEquals(3,[SELECT COUNT() FROM Lead WHERE IsConverted=true]);
        System.assertEquals(2,[SELECT COUNT() FROM Opportunity]);
        for (Opportunity booking : [SELECT Id,Name,Amount,NTE_Source_Form_Type__c,NTE_Event_Code__c,
            Booking_Reference__c,NTE_Approval_Email_Lead_Id__c,NTE_Approval_Email_Sent_At__c FROM Opportunity]) {
            System.assertEquals(booking.Id==existing.Id ? existing.Name : leads[1].Company,booking.Name,
                'The NTE guard must not append an event code or rename an ordinary opportunity.');
            if (booking.Id==existing.Id) System.assertEquals(existing.Amount,booking.Amount);
            System.assertEquals(null,booking.NTE_Source_Form_Type__c);
            System.assertEquals(null,booking.NTE_Event_Code__c);
            System.assertEquals(null,booking.Booking_Reference__c);
            System.assertEquals(null,booking.NTE_Approval_Email_Lead_Id__c);
            System.assertEquals(null,booking.NTE_Approval_Email_Sent_At__c);
        }
        System.assertEquals(0,[SELECT COUNT() FROM NTE_Payment_Request__c]);
        System.assertEquals(0,[SELECT COUNT() FROM NTE_Email_Dispatch__c]);
        System.assertEquals(0,[SELECT COUNT() FROM Task]);
    }

    private static Map<Id,Lead> conversionApplicationSnapshots(Set<Id> ids) {
        return new Map<Id,Lead>([SELECT Id,LastModifiedDate,OwnerId,Status,IsConverted,
            ConvertedAccountId,ConvertedContactId,ConvertedOpportunityId,FirstName,LastName,Company,Email,
            Web_Form_Type__c,NTE_Event_Code__c,Booking_Reference__c,Planned_Exhibitor_Count__c,Total_Staff_Count__c,
            Sponsor_Package__c,Exhibitor_Space_Selections__c,Listed_Price_Total__c,Total_Including_VAT__c,
            Pricing_Status__c,Pricing_Version__c,Payment_Method__c,Invoice_Required__c,Invoice_Requested__c,
            Quote_Required_for_PO__c,Purchase_Order__c,Purchase_Order_Number__c,Supplier_Agreement_Required__c,
            Invoice_Additional_Information__c,NTE_Application_Rejected__c,NTE_Applicant_Email_Status__c,
            NTE_Internal_Email_Status__c,NTE_Email_Error__c FROM Lead WHERE Id IN :ids]);
    }

    @IsTest static void mixedConversionBatchCommitsOnlyValidNewBookingsAndStaysSilent() {
        Lead prior=application('MIXED-PRIOR',false);
        Opportunity protectedBooking=convert(prior);
        Lead convertedPrior=[SELECT ConvertedAccountId,ConvertedContactId FROM Lead WHERE Id=:prior.Id];
        Opportunity beforeBooking=state(protectedBooking.Id);
        Lead paid=application('MIXED-PAID',false);
        Lead noBooking=application('MIXED-NONE',false);
        Lead reuse=application('MIXED-REUSE',false);
        Lead free=application('MIXED-FREE',true);
        paid.Payment_Method__c='Stripe'; paid.Invoice_Requested__c='No'; paid.Email='mixed-paid@example.invalid';
        noBooking.Web_Form_Type__c='Partner / Sponsor Application'; noBooking.Sponsor_Package__c='Champion Partner';
        free.Email='mixed-free@example.invalid';
        update new List<Lead>{paid,noBooking,free};
        Lead ordinary=new Lead(FirstName='Unrelated',LastName='Mixed batch',Company='Unrelated mixed conversion',
            Email='mixed-ordinary@example.invalid');
        insert ordinary;
        Set<Id> failedIds=new Set<Id>{noBooking.Id,reuse.Id};
        Map<Id,Lead> beforeApplications=conversionApplicationSnapshots(failedIds);
        Integer accountsBefore=[SELECT COUNT() FROM Account];
        Integer contactsBefore=[SELECT COUNT() FROM Contact];
        Integer opportunitiesBefore=[SELECT COUNT() FROM Opportunity];
        Database.LeadConvert paidRequest=convertRequest(paid);
        paidRequest.setAccountId(convertedPrior.ConvertedAccountId);
        paidRequest.setContactId(convertedPrior.ConvertedContactId);
        Database.LeadConvert noBookingRequest=convertRequest(noBooking);
        noBookingRequest.setOpportunityName(null); noBookingRequest.setDoNotCreateOpportunity(true);
        Database.LeadConvert reuseRequest=convertRequest(reuse);
        reuseRequest.setAccountId(convertedPrior.ConvertedAccountId);
        reuseRequest.setContactId(convertedPrior.ConvertedContactId);
        reuseRequest.setOpportunityName(null); reuseRequest.setOpportunityId(protectedBooking.Id);
        List<Lead> ordered=new List<Lead>{paid,noBooking,ordinary,reuse,free};

        Test.startTest();
        List<Database.LeadConvertResult> results=Database.convertLead(new List<Database.LeadConvert>{
            paidRequest,noBookingRequest,convertRequest(ordinary),reuseRequest,convertRequest(free)
        },false);
        System.assertEquals(0,Limits.getQueueableJobs(),'Conversion must not queue approval or payment work.');
        System.assertEquals(0,Limits.getEmailInvocations(),'Accepted conversions must remain silent.');
        Test.stopTest();

        System.assertEquals(ordered.size(),results.size());
        Set<Id> newBookingIds=new Set<Id>();
        Set<Id> nteBookingIds=new Set<Id>();
        for (Integer index=0; index<results.size(); index++) {
            Database.LeadConvertResult result=results[index];
            Boolean expectedSuccess=index!=1 && index!=3;
            System.assertEquals(expectedSuccess,result.isSuccess(),'Conversion '+index+': '+String.valueOf(result.getErrors()));
            if (expectedSuccess) {
                System.assertEquals(ordered[index].Id,result.getLeadId());
                System.assertNotEquals(null,result.getOpportunityId());
                System.assertNotEquals(protectedBooking.Id,result.getOpportunityId());
                newBookingIds.add(result.getOpportunityId());
                if (index!=2) nteBookingIds.add(result.getOpportunityId());
            } else {
                System.assert(String.valueOf(result.getErrors()).contains('Create a new Opportunity for each NTE application'),
                    'The intended guard, not an unrelated conversion error, must reject the request.');
                System.assertEquals(null,result.getOpportunityId());
            }
        }
        System.assertEquals(3,newBookingIds.size(),'Every successful application receives its own new opportunity.');
        System.assertEquals(2,nteBookingIds.size());
        System.assertEquals(convertedPrior.ConvertedAccountId,results[0].getAccountId());
        System.assertEquals(convertedPrior.ConvertedContactId,results[0].getContactId());
        Map<Id,Lead> afterApplications=conversionApplicationSnapshots(failedIds);
        for (Id failedId : failedIds)
            System.assertEquals(beforeApplications.get(failedId),afterApplications.get(failedId),
                'Rejected conversion must preserve the application and all captured routing/finance facts.');
        System.assertEquals(beforeBooking,state(protectedBooking.Id),'Attempted reuse must not overwrite the earlier booking.');
        System.assertEquals(accountsBefore+2,[SELECT COUNT() FROM Account],'Rejected conversion must not leave an orphan Account.');
        System.assertEquals(contactsBefore+2,[SELECT COUNT() FROM Contact],'Rejected conversion must not leave an orphan Contact.');
        System.assertEquals(opportunitiesBefore+3,[SELECT COUNT() FROM Opportunity]);
        System.assertEquals(4,[SELECT COUNT() FROM Lead WHERE IsConverted=true]);
        for (Opportunity booking : [SELECT Id,Name,Booking_Reference__c,NTE_Event_Code__c,NTE_Source_Form_Type__c,
            NTE_Approval_Email_Lead_Id__c,NTE_Approval_Email_Status__c,NTE_Approval_Email_Sent_At__c, NTE_Free_Space_Confirmed__c,
            NTE_Payment_Received__c,NTE_Finance_Requirements_Due__c,NTE_Finance_Payment_Due__c,
            NTE_Finance_Payment_Confirmed__c FROM Opportunity WHERE Id IN :nteBookingIds]) {
            Boolean paidBooking=booking.Id==results[0].getOpportunityId();
            Lead expected=paidBooking ? paid : free;
            System.assertEquals(expected.Company+' - NTE2099',booking.Name);
            System.assertEquals(expected.Booking_Reference__c,booking.Booking_Reference__c);
            System.assertEquals(String.valueOf(expected.Id),booking.NTE_Approval_Email_Lead_Id__c);
            System.assertEquals('NTE2099',booking.NTE_Event_Code__c);
            System.assertEquals('Exhibitor Application',booking.NTE_Source_Form_Type__c);
            System.assertEquals(null,booking.NTE_Approval_Email_Sent_At__c);
            System.assertNotEquals('Pending',booking.NTE_Approval_Email_Status__c);
            System.assertNotEquals('Sent',booking.NTE_Approval_Email_Status__c);
            System.assert(!booking.NTE_Payment_Received__c);
            System.assert(booking.NTE_Finance_Requirements_Due__c);
            System.assert(!booking.NTE_Finance_Payment_Due__c);
            System.assert(!booking.NTE_Finance_Payment_Confirmed__c,'A free booking still needs its manual confirmation.');
        }
        Id ordinaryBookingId=results[2].getOpportunityId();
        Opportunity ordinaryBooking=[SELECT Name,NTE_Source_Form_Type__c,NTE_Approval_Email_Lead_Id__c
            FROM Opportunity WHERE Id=:ordinaryBookingId];
        System.assertEquals(ordinary.Company,ordinaryBooking.Name);
        System.assertEquals(null,ordinaryBooking.NTE_Source_Form_Type__c);
        System.assertEquals(null,ordinaryBooking.NTE_Approval_Email_Lead_Id__c);
        System.assertEquals(0,[SELECT COUNT() FROM NTE_Email_Dispatch__c],'Neither accepted nor rejected conversions create dispatches.');
        System.assertEquals(0,[SELECT COUNT() FROM NTE_Payment_Request__c],'No conversion creates a payment request.');
        System.assertEquals(0,[SELECT COUNT() FROM Task],'No orphan or accepted-conversion email activity remains.');
    }

    private static void verifyInvoiceChoices(String method, Boolean partner) {
        for (String choice : new List<String>{'Yes','No'}) {
            Lead lead=application('INVOICE-'+method+'-'+partner+'-'+choice,false);
            lead.Payment_Method__c=method;
            lead.Invoice_Requested__c=choice;
            if (partner) { lead.Web_Form_Type__c='Partner / Sponsor Application'; lead.Sponsor_Package__c='Champion Partner'; }
            update lead;
            Opportunity booking=convert(lead);
            System.assertEquals(choice,booking.NTE_Invoice_Requested__c,'The applicant preference must survive conversion.');
            System.assertEquals(method,booking.NTE_Payment_Method__c);
            System.assertEquals('Yes',booking.NTE_Invoice_Required__c,'Billable status is independent of the invoice choice.');
            Boolean rejected=false;
            try { NTEFinanceService.setRequirement(booking.Id,'NTE_Invoice_Provided__c',true); }
            catch (AuraHandledException expected) { rejected=true; }
            System.assertEquals(choice=='No',rejected,'Only requested invoices belong on the checklist.');
            System.assertEquals(choice=='Yes',state(booking.Id).NTE_Invoice_Provided__c);
            System.assertEquals(0,[SELECT COUNT() FROM NTE_Payment_Request__c]);
            System.assertEquals(0,[SELECT COUNT() FROM NTE_Email_Dispatch__c]);
        }
    }
    @IsTest static void exhibitorStripeInvoiceChoiceIsIndependent() { verifyInvoiceChoices('Stripe',false); }
    @IsTest static void exhibitorBankInvoiceChoiceIsIndependent() { verifyInvoiceChoices('Bank transfer',false); }
    @IsTest static void partnerStripeInvoiceChoiceIsIndependent() { verifyInvoiceChoices('Stripe',true); }
    @IsTest static void partnerBankInvoiceChoiceIsIndependent() { verifyInvoiceChoices('Bank transfer',true); }
}
