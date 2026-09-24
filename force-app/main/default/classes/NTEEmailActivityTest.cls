@IsTest
private class NTEEmailActivityTest {
    @IsTest
    static void preparationAcknowledgementsKeepTheMergedBodyOnTheBookingContact() {
        Account company = new Account(Name = 'Westhaven Training'); insert company;
        Contact recipient = new Contact(AccountId = company.Id, FirstName = 'Helen', LastName = 'Marsh',
            Email = 'booking-contact@example.invalid'); insert recipient;
        Opportunity booking = new Opportunity(Name = 'Westhaven booking', AccountId = company.Id,
            StageName = 'Prospecting', CloseDate = Date.today().addDays(30)); insert booking;
        Lead submission = new Lead(FirstName = 'Other', LastName = 'Submitter', Company = company.Name,
            Email = 'form-submitter@example.invalid', Target_Booking_Reference__c = 'NTE-ACTIVITY-TEST',
            Staff_Base_Names__c = 'Zoë Marsh\nOliver Carter', Event_Contact_Name__c = 'Logistics Person');
        insert submission;
        List<Messaging.SingleEmailMessage> messages = new List<Messaging.SingleEmailMessage>();
        Test.startTest();
        for (EmailTemplate template : [SELECT Id FROM EmailTemplate WHERE DeveloperName IN
            ('NTE_Exhibitor_Staff_Update_Acknowledgement', 'NTE_Partner_Staff_Update_Acknowledgement', 'NTE_Heavy_Vehicle_Acknowledgement')]) {
            Messaging.SingleEmailMessage expected = Messaging.renderStoredEmailTemplate(template.Id, submission.Id, null);
            Messaging.SingleEmailMessage actual = NTEUpdateSubmissionService.acknowledgementMessage(
                submission.Id, template.Id, recipient, booking.Id);
            System.assertEquals(expected.getSubject(), actual.getSubject());
            System.assertEquals(expected.getHtmlBody(), actual.getHtmlBody(), 'Retargeting must preserve the exact native template output.');
            System.assertEquals(expected.getPlainTextBody(), actual.getPlainTextBody());
            System.assertEquals(recipient.Id, actual.getTargetObjectId());
            System.assertEquals(new List<String>{recipient.Email}, actual.getToAddresses());
            System.assertEquals(booking.Id, actual.getWhatId());
            System.assertEquals(true, actual.getSaveAsActivity());
            System.assertEquals(null, actual.getTemplateId(), 'The retained email must not depend on a deleted temporary Lead.');
            messages.add(actual);
        }
        System.assertEquals(3, messages.size());
        delete submission;
        for (Messaging.SendEmailResult result : Messaging.sendEmail(messages, false)) {
            System.assert(result.isSuccess(), result.getErrors().isEmpty() ? '' : result.getErrors()[0].getMessage());
        }
        Test.stopTest();
        System.assertEquals(0, [SELECT COUNT() FROM Lead WHERE Id = :submission.Id]);
    }

    @IsTest
    static void topUpEmailKeepsItsContentAndBookingActivityRecipient() {
        Account company = new Account(Name = 'Westhaven Engineering'); insert company;
        Contact recipient = new Contact(AccountId = company.Id, FirstName = 'Oliver', LastName = 'Fenwick',
            Email = 'topup-contact@example.invalid'); insert recipient;
        Opportunity booking = new Opportunity(Name = 'Westhaven top-up', AccountId = company.Id,
            StageName = 'Prospecting', CloseDate = Date.today().addDays(30), Booking_Reference__c = 'NTE-ACTIVITY-TOPUP'); insert booking;
        booking = [SELECT Name, Account.Name, Booking_Reference__c FROM Opportunity WHERE Id = :booking.Id];
        NTE_Payment_Request__c payment = new NTE_Payment_Request__c(Net_Minor__c = 5000, Amount_Minor__c = 6000,
            Tax_Rate__c = 20, Payment_URL__c = 'https://buy.stripe.com/test_activity', Live_Mode__c = false);
        Test.startTest();
        Messaging.SingleEmailMessage message = NTEExhibitorApprovalEmailService.renderTopUpEmail(booking, recipient, payment);
        System.assertEquals(booking.Id, message.getWhatId());
        System.assertEquals(recipient.Id, message.getTargetObjectId());
        System.assertEquals(new List<String>{recipient.Email}, message.getToAddresses());
        System.assertEquals(true, message.getSaveAsActivity());
        System.assert(message.getHtmlBody().contains('£60.00'));
        System.assert(message.getPlainTextBody().contains('NTE-ACTIVITY-TOPUP'));
        Test.stopTest();
    }
}
