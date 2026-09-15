@IsTest
private class NTEBookingEmailRetryServiceTest {
    @TestSetup
    static void setupBookings() {
        PermissionSet permission = [SELECT Id FROM PermissionSet WHERE Name='NTE_Forms_Administration' LIMIT 1];
        if ([SELECT COUNT() FROM PermissionSetAssignment WHERE AssigneeId=:UserInfo.getUserId()
            AND PermissionSetId=:permission.Id] == 0) {
            insert new PermissionSetAssignment(AssigneeId=UserInfo.getUserId(), PermissionSetId=permission.Id);
        }
        System.runAs(new User(Id=UserInfo.getUserId())) {
            Account company = new Account(Name='Booking retry organisation');
            insert company;
            Id recordType = [SELECT Id FROM RecordType WHERE SobjectType='Opportunity'
                AND DeveloperName='NTE_Event_Opportunity' LIMIT 1].Id;
            String stage = [SELECT MasterLabel FROM OpportunityStage WHERE IsActive=true AND IsClosed=false
                ORDER BY SortOrder LIMIT 1].MasterLabel;
            List<Opportunity> bookings = new List<Opportunity>();
            List<Contact> contacts = new List<Contact>();
            for (String key : new List<String>{'EXHIBITOR','PARTNER','OTHER'}) {
                Boolean partner = key == 'PARTNER';
                Decimal net = partner ? 2000 : 799;
                bookings.add(new Opportunity(Name='BOOKING-RETRY-'+key, AccountId=company.Id,
                    RecordTypeId=recordType, StageName=stage, CloseDate=Date.today().addDays(30),
                    Booking_Reference__c='NTE-BOOKING-RETRY-'+key, NTE_Event_Code__c='NTE2099',
                    NTE_Source_Form_Type__c=partner ? 'Partner / Sponsor Application' : 'Exhibitor Application',
                    NTE_Sponsor_Package__c=partner ? 'Champion Partner' : null,
                    NTE_Sponsor_Package_Total__c=partner ? net : 0,
                    NTE_Exhibitor_Space_Selections__c=partner ? null : 'Single Garage - Track Side - £799 + VAT',
                    NTE_Exhibitor_Organisation_Category__c='CIC or Not for Profit',
                    NTE_Exhibitor_Space_Price__c=partner ? 0 : net, NTE_Listed_Price_Total__c=net,
                    NTE_VAT_Rate__c=20, Amount=net*1.2, NTE_Pricing_Status__c='Calculated',
                    NTE_Payment_Method__c='Bank transfer', NTE_Invoice_Required__c='Yes',
                    NTE_Quote_Required_for_PO__c='No', NTE_Heavy_Vehicle_Required__c='No',
                    NTE_Initial_Staff_Count__c=2, NTE_Total_Staff_Count__c=2, NTE_Included_Staff_Count__c=2,
                    NTE_Approval_Email_Status__c='Sent', NTE_Approval_Email_Sent_At__c=System.now().addDays(-1)));
                contacts.add(new Contact(AccountId=company.Id, FirstName='Primary', LastName=key,
                    Email='booking-retry-'+key.toLowerCase()+'@example.invalid'));
            }
            insert bookings;
            insert contacts;
            List<OpportunityContactRole> roles = new List<OpportunityContactRole>();
            for (Integer i=0;i<bookings.size();i++) roles.add(new OpportunityContactRole(
                OpportunityId=bookings[i].Id, ContactId=contacts[i].Id, IsPrimary=true));
            insert roles;
        }
    }

    private static void configure() {
        NTEInboundLeadService.bypassEmailDelivery=true;
        NTEExhibitorApprovalEmailService.bypassEmailDelivery=true;
        NTEEmailDispatchService.skipEnqueue=true;
        NTEEmailDispatchService.bypassEmailDelivery=true;
        NTEEmailDispatchService.routingOverride=new NTE_Routing_Config__mdt(
            Exhibitor_Staff_Form_URL__c='https://forms.example.invalid/exhibitor-staff',
            Partner_Staff_Form_URL__c='https://forms.example.invalid/partner-staff',
            Heavy_Vehicle_Form_URL__c='https://forms.example.invalid/logistics',
            Logo_Update_Form_URL__c='https://forms.example.invalid/logo');
    }
    private static Id bookingId(String key) {
        String name='BOOKING-RETRY-'+key;
        return [SELECT Id FROM Opportunity WHERE Name=:name LIMIT 1].Id;
    }
    private static Opportunity paidBooking(String key) {
        Id id=bookingId(key);
        update new Opportunity(Id=id,NTE_Payment_Received__c=true,
            NTE_Payment_Received_At__c=System.now().addHours(-1),NTE_Payment_Recorded_By__c='Reviewed by NTE team');
        return paymentState(id);
    }
    private static Opportunity paymentState(Id id) {
        return [SELECT Id,Amount,NTE_Listed_Price_Total__c,NTE_Price_Adjustment__c,NTE_VAT_Total__c,
            NTE_Payment_Received__c,NTE_Payment_Received_At__c,NTE_Payment_Recorded_By__c,
            NTE_Top_Up_Payment_Received__c,NTE_Top_Up_Payment_At__c,NTE_Top_Up_Payment_By__c,
            NTE_Approval_Email_Status__c,NTE_Approval_Email_Sent_At__c FROM Opportunity WHERE Id=:id];
    }
    private static NTE_Email_Dispatch__c confirmation(Id id) {
        return [SELECT Id,Status__c,Sent_At__c,Error__c,Contact__c,Recipient__c,Dispatch_Key__c,Run_Id__c,Kind__c
            FROM NTE_Email_Dispatch__c WHERE Opportunity__c=:id AND Kind__c='BOOKING_CONFIRMED' LIMIT 1];
    }
    private static Integer confirmationCount(Id id) {
        return [SELECT COUNT() FROM NTE_Email_Dispatch__c WHERE Opportunity__c=:id AND Kind__c='BOOKING_CONFIRMED'];
    }

    @IsTest
    static void createsMissingPaidConfirmationOnlyOnceWithoutChangingPayment() {
        configure(); Opportunity paid=paidBooking('EXHIBITOR');
        // State after payment persisted but confirmation preparation failed before dispatch insertion.
        System.assertEquals(0,confirmationCount(paid.Id));
        Test.startTest();
        System.assertEquals(1,NTEBookingEmailRetryService.retryBookingEmail(paid.Id).queuedCount);
        NTE_Email_Dispatch__c queued=confirmation(paid.Id);
        System.assertEquals('BOOKING_PAYMENT',queued.Run_Id__c);
        System.assertEquals('Queued',queued.Status__c);
        System.assertEquals(0,NTEBookingEmailRetryService.retryBookingEmail(paid.Id).queuedCount);
        NTEEmailDispatchService.processQueued(new List<Id>{queued.Id},true);
        Test.stopTest();
        System.assertEquals('Sent',confirmation(paid.Id).Status__c);
        System.assertEquals(1,confirmationCount(paid.Id));
        System.assertEquals(JSON.serialize(paid),JSON.serialize(paymentState(paid.Id)));
        System.assertEquals(0,[SELECT COUNT() FROM NTE_Payment_Request__c]);
    }

    @IsTest
    static void failedPaidRetryUsesSameDispatchAndCurrentReviewedAmount() {
        configure(); Opportunity paid=paidBooking('EXHIBITOR');
        NTEEmailDispatchService.queueBookingConfirmation(paid.Id);
        NTE_Email_Dispatch__c failed=confirmation(paid.Id);
        NTEEmailDispatchService.simulatedFailures.add(paid.Id);
        NTEEmailDispatchService.processQueued(new List<Id>{failed.Id},true);
        System.assertEquals('Failed',confirmation(paid.Id).Status__c);
        NTEEmailDispatchService.simulatedFailures.clear();
        update new Opportunity(Id=paid.Id,Amount=1080.01);
        Opportunity revised=paymentState(paid.Id);
        Test.startTest();
        System.assertEquals(1,NTEBookingEmailRetryService.retryBookingEmail(paid.Id).queuedCount);
        NTEEmailDispatchService.processQueued(new List<Id>{failed.Id},true);
        Test.stopTest();
        System.assertEquals(failed.Id,confirmation(paid.Id).Id);
        System.assertEquals(failed.Dispatch_Key__c,confirmation(paid.Id).Dispatch_Key__c);
        System.assertEquals('Sent',confirmation(paid.Id).Status__c);
        System.assertEquals(1,confirmationCount(paid.Id));
        System.assertEquals(JSON.serialize(revised),JSON.serialize(paymentState(paid.Id)));
        String text=NTEEmailDispatchService.renderedText.get(paid.Id);
        System.assert(text.contains('£1080.01') && text.contains('Booking adjustment'));
    }

    @IsTest
    static void acceptedConfirmationCannotBeResentEvenAfterManualStatusChange() {
        configure(); Opportunity paid=paidBooking('EXHIBITOR');
        NTEEmailDispatchService.queueBookingConfirmation(paid.Id);
        Id dispatchId=confirmation(paid.Id).Id;
        NTEEmailDispatchService.processQueued(new List<Id>{dispatchId},true);
        NTE_Email_Dispatch__c accepted=confirmation(paid.Id);
        System.assertEquals('Sent',accepted.Status__c);
        Test.startTest();
        NTEEmailDispatchService.QueueResponse sent=NTEBookingEmailRetryService.retryBookingEmail(paid.Id);
        System.assertEquals(0,sent.queuedCount);System.assert(sent.message.contains('already been sent'));
        update new NTE_Email_Dispatch__c(Id=dispatchId,Status__c='Failed',Error__c='Later manual status correction');
        System.assertEquals(0,NTEBookingEmailRetryService.retryBookingEmail(paid.Id).queuedCount);
        Test.stopTest();
        System.assertEquals(accepted.Sent_At__c,confirmation(paid.Id).Sent_At__c);
        System.assertEquals('Failed',confirmation(paid.Id).Status__c,'Retry does not rewrite accepted history.');
        System.assertEquals(1,confirmationCount(paid.Id));
        System.assertEquals(JSON.serialize(paid),JSON.serialize(paymentState(paid.Id)));
    }

    @IsTest
    static void missingPrimaryRemainsFailedThenRecoversOnTheSameDispatch() {
        configure(); Opportunity paid=paidBooking('EXHIBITOR');
        OpportunityContactRole role=[SELECT Id,ContactId FROM OpportunityContactRole
            WHERE OpportunityId=:paid.Id AND IsPrimary=true LIMIT 1];
        delete role;
        System.assertEquals(0,NTEBookingEmailRetryService.retryBookingEmail(paid.Id).queuedCount);
        NTE_Email_Dispatch__c failed=confirmation(paid.Id);
        System.assertEquals('Failed',failed.Status__c);
        System.assert(failed.Error__c.contains('primary Contact'));
        System.assertEquals(0,NTEBookingEmailRetryService.retryBookingEmail(paid.Id).queuedCount);
        insert new OpportunityContactRole(OpportunityId=paid.Id,ContactId=role.ContactId,IsPrimary=true);
        Test.startTest();
        System.assertEquals(1,NTEBookingEmailRetryService.retryBookingEmail(paid.Id).queuedCount);
        NTEEmailDispatchService.processQueued(new List<Id>{failed.Id},true);
        Test.stopTest();
        System.assertEquals(failed.Id,confirmation(paid.Id).Id);
        System.assertEquals('Sent',confirmation(paid.Id).Status__c);
        System.assertEquals(role.ContactId,confirmation(paid.Id).Contact__c);
        System.assertEquals(JSON.serialize(paid),JSON.serialize(paymentState(paid.Id)));
    }

    @IsTest
    static void failedPaidPartnerConfirmationCanRecoverAfterFullWaiver() {
        configure(); Opportunity paid=paidBooking('PARTNER');
        NTEEmailDispatchService.queueBookingConfirmation(paid.Id);
        NTE_Email_Dispatch__c failed=confirmation(paid.Id);
        update new NTE_Email_Dispatch__c(Id=failed.Id,Status__c='Failed',Error__c='Earlier delivery failure');
        update new Opportunity(Id=paid.Id,Amount=0);
        Opportunity waived=paymentState(paid.Id);
        Test.startTest();
        System.assertEquals(1,NTEBookingEmailRetryService.retryBookingEmail(paid.Id).queuedCount);
        NTEEmailDispatchService.processQueued(new List<Id>{failed.Id},true);
        Test.stopTest();
        System.assertEquals('Sent',confirmation(paid.Id).Status__c);
        System.assertEquals(failed.Id,confirmation(paid.Id).Id);
        System.assertEquals(JSON.serialize(waived),JSON.serialize(paymentState(paid.Id)));
        String text=NTEEmailDispatchService.renderedText.get(paid.Id);
        System.assert(text.contains('No payment is due.') && text.contains('£0.00'));
        System.assertEquals(0,NTEBookingEmailRetryService.retryBookingEmail(paid.Id).queuedCount);
    }

    @IsTest
    static void unpaidAndFreeFailuresKeepUsingTheApprovalWorkflow() {
        configure();
        List<Id> ids=new List<Id>();
        for (Boolean free : new List<Boolean>{false,true}) {
            String key=free ? 'FREE' : 'UNPAID';
            Lead source=new Lead(FirstName='Original',LastName=key,Company='Retry '+key,
                Email='retry-'+key.toLowerCase()+'@example.invalid',Web_Form_Type__c='Exhibitor Application',
                NTE_Event_Code__c='NTE2099',Booking_Reference__c='NTE-RETRY-'+key,
                Exhibitor_Organisation_Category__c=free ? 'Charity - member of Cobseo' : 'CIC or Not for Profit',
                Exhibitor_Space_Selections__c=free ? 'COBSEO Charity - Single - Free' : 'Single Garage - Track Side - £799 + VAT',
                Planned_Exhibitor_Count__c='2',Total_Staff_Count__c=2,Stand_Power__c='No',Heavy_Vehicle_Required__c='No',
                Payment_Method__c=free ? null : 'Bank transfer',Invoice_Requested__c=free ? null : 'Yes');
            insert source;
            Database.LeadConvert conversion=new Database.LeadConvert();conversion.setLeadId(source.Id);
            conversion.setConvertedStatus([SELECT MasterLabel FROM LeadStatus WHERE IsConverted=true LIMIT 1].MasterLabel);
            conversion.setOpportunityName(source.Company);
            Database.LeadConvertResult converted=Database.convertLead(conversion);
            System.assert(converted.isSuccess());ids.add(converted.getOpportunityId());
        }
        List<Opportunity> failed=new List<Opportunity>();
        for (Id id : ids) failed.add(new Opportunity(Id=id,NTE_Approval_Email_Status__c='Failed',
            NTE_Approval_Email_Error__c='Earlier approval email failure'));
        update failed;
        Test.startTest();
        for (Id id : ids) System.assertEquals(1,NTEBookingEmailRetryService.retryBookingEmail(id).queuedCount);
        Test.stopTest();
        for (Opportunity booking : [SELECT Id,NTE_Approval_Email_Status__c,NTE_Approval_Email_Error__c,
            NTE_Payment_Received__c FROM Opportunity WHERE Id IN :ids]) {
            System.assertEquals('Sent',booking.NTE_Approval_Email_Status__c,'Approval recovery: '+booking.NTE_Approval_Email_Error__c);
            System.assert(!booking.NTE_Payment_Received__c);System.assertEquals(0,confirmationCount(booking.Id));
        }
    }

    @IsTest
    static void invalidOrUnavailableBookingsCannotCreateAConfirmation() {
        configure();Id ordinary=bookingId('OTHER');
        update new Opportunity(Id=ordinary,NTE_Source_Form_Type__c=null);
        for (Id candidate : new List<Id>{null,[SELECT Id FROM Account LIMIT 1].Id,ordinary}) {
            Boolean blocked=false;
            try { NTEBookingEmailRetryService.retryBookingEmail(candidate); }
            catch (AuraHandledException expected) { blocked=true; }
            System.assert(blocked);
        }
        System.assertEquals(0,[SELECT COUNT() FROM NTE_Email_Dispatch__c]);
    }

    @IsTest
    static void restrictedUserCannotInvokePaidRecovery() {
        User restricted=new User(Alias='nteretry',Email='restricted-retry@example.invalid',
            EmailEncodingKey='UTF-8',LastName='Restricted booking retry',LanguageLocaleKey='en_US',LocaleSidKey='en_GB',
            ProfileId=[SELECT Id FROM Profile WHERE Name='Minimum Access - Salesforce' LIMIT 1].Id,
            TimeZoneSidKey='Europe/London',Username='restricted-retry.'+System.now().getTime()+'@example.invalid');
        insert restricted;
        Id id=bookingId('EXHIBITOR');
        System.runAs(restricted) {
            Boolean blocked=false;
            try { NTEBookingEmailRetryService.retryBookingEmail(id); }
            catch (AuraHandledException expected) { blocked=true; }
            System.assert(blocked);
        }
        System.assertEquals(0,confirmationCount(id));
        System.assert(!paymentState(id).NTE_Payment_Received__c);
    }
}
