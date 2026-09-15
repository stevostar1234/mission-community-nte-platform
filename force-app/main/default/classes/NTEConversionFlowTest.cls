@IsTest
private class NTEConversionFlowTest {
    @TestSetup
    static void assignFieldAccess() {
        PermissionSet permissionSetRecord = [
            SELECT Id
            FROM PermissionSet
            WHERE Name = 'NTE_Forms_Administration'
            LIMIT 1
        ];
        if ([
            SELECT COUNT()
            FROM PermissionSetAssignment
            WHERE AssigneeId = :UserInfo.getUserId()
            AND PermissionSetId = :permissionSetRecord.Id
        ] == 0) {
            insert new PermissionSetAssignment(
                AssigneeId = UserInfo.getUserId(),
                PermissionSetId = permissionSetRecord.Id
            );
        }
    }

    @IsTest
    static void convertedApplicationCopiesNteFieldsToOpportunity() {
        NTEInboundLeadService.bypassEmailDelivery = true;
        NTEExhibitorApprovalEmailService.bypassEmailDelivery = true;
        Lead application = new Lead(
            FirstName = 'NTE',
            LastName = 'Conversion Test',
            Company = 'NTE Conversion Test Organisation',
            Email = 'nte-conversion-test@example.invalid',
            Web_Form_Type__c = 'Exhibitor Application',
            Form_Version__c = 'Evergreen v2',
            Booking_Reference__c = 'NTE-TEST-CONVERSION-FLOW',
            NTE_Event_Code__c = 'NTE2027',
            Event_Contact_Name__c = 'NTE Event Contact',
            Event_Contact_Title__c = 'Programme Director',
            Event_Contact_Email__c = 'nte-event-contact@example.invalid',
            Event_Contact_Mobile__c = '+44 7700 900789',
            Alternative_Organisation_Name__c = 'NTE Former Name',
            Trading_Name__c = 'NTE Trading Name',
            Invoice_Required__c = 'Yes',
            Payment_Method__c = 'Bank transfer',
            Invoice_Additional_Information__c = 'Include department code MC-NTE27',
            Secondary_Contact_Prefix__c = 'Dr.',
            Secondary_Contact_Name__c = 'NTE Secondary Contact',
            Secondary_Contact_Title__c = 'Operations Lead',
            Secondary_Contact_Email__c = 'secondary@example.invalid',
            Secondary_Contact_Mobile__c = '+44 7700 900790',
            Secondary_Contact_Phone__c = '+44 20 7946 0101',
            Exhibitor_Organisation_Category__c = 'CIC or Not for Profit',
            Exhibitor_Space_Selections__c = 'Single Garage - Track Side - £799 + VAT',
            Planned_Exhibitor_Count__c = '2', Total_Staff_Count__c = 2, Stand_Power__c = 'No',
            Exhibitor_Hall_Schedule__c = 'Yes',
            Has_Special_Requirements__c = 'Yes',
            Industry_Body_Details__c = 'NTE QA Industry Body',
            Event_Discovery_Source__c = 'LinkedIn',
            Declaration_Name__c = 'NTE Conversion Test',
            Terms_and_Conditions__c = true
        );
        Database.insert(application, AccessLevel.SYSTEM_MODE);

        LeadStatus convertedStatus = [
            SELECT MasterLabel
            FROM LeadStatus
            WHERE IsConverted = true
            LIMIT 1
        ];
        Database.LeadConvert conversion = new Database.LeadConvert();
        conversion.setLeadId(application.Id);
        conversion.setConvertedStatus(convertedStatus.MasterLabel);
        conversion.setOpportunityName('NTE Conversion Test Participation');

        Test.startTest();
        Database.LeadConvertResult result = Database.convertLead(conversion);
        Test.stopTest();

        System.assert(result.isSuccess(), 'The standard Lead conversion should succeed.');
        Lead convertedLead = [
            SELECT ConvertedAccountId, ConvertedContactId, ConvertedOpportunityId
            FROM Lead
            WHERE Id = :application.Id
        ];
        Opportunity participation = [
            SELECT Booking_Reference__c, NTE_Event_Code__c, NTE_Source_Form_Type__c,
                   RecordType.DeveloperName,
                   NTE_Form_Version__c, NTE_Event_Contact_Name__c,
                   NTE_Event_Contact_Title__c, NTE_Event_Contact_Email__c, NTE_Event_Contact_Mobile__c,
                   NTE_Alternative_Organisation_Name__c, NTE_Trading_Name__c,
                   NTE_Invoice_Required__c, NTE_Payment_Method__c,
                   NTE_Invoice_Additional_Information__c, NTE_Secondary_Contact_Prefix__c,
                   NTE_Secondary_Contact_Name__c, NTE_Secondary_Contact_Title__c,
                   NTE_Secondary_Contact_Email__c, NTE_Secondary_Contact_Mobile__c, NTE_Secondary_Contact_Phone__c,
                   NTE_Exhibitor_Organisation_Category__c, NTE_Exhibitor_Hall_Schedule__c,
                   NTE_Has_Special_Requirements__c, NTE_Industry_Body_Details__c,
                   NTE_Event_Discovery_Source__c, NTE_Declaration_Name__c, NTE_Terms_Accepted__c
            FROM Opportunity
            WHERE Id = :convertedLead.ConvertedOpportunityId
        ];
        System.assertEquals('NTE-TEST-CONVERSION-FLOW', participation.Booking_Reference__c);
        System.assertEquals('NTE_Event_Opportunity', participation.RecordType.DeveloperName);
        System.assertEquals('NTE2027', participation.NTE_Event_Code__c);
        System.assertEquals('Exhibitor Application', participation.NTE_Source_Form_Type__c);
        System.assertEquals('Evergreen v2', participation.NTE_Form_Version__c);
        System.assertEquals('NTE Event Contact', participation.NTE_Event_Contact_Name__c);
        System.assertEquals('Programme Director', participation.NTE_Event_Contact_Title__c);
        System.assertEquals('nte-event-contact@example.invalid', participation.NTE_Event_Contact_Email__c);
        System.assertEquals('+44 7700 900789', participation.NTE_Event_Contact_Mobile__c);
        System.assertEquals('NTE Former Name', participation.NTE_Alternative_Organisation_Name__c);
        System.assertEquals('NTE Trading Name', participation.NTE_Trading_Name__c);
        System.assertEquals('Yes', participation.NTE_Invoice_Required__c);
        System.assertEquals('Bank transfer', participation.NTE_Payment_Method__c);
        System.assertEquals('Include department code MC-NTE27', participation.NTE_Invoice_Additional_Information__c);
        System.assertEquals('Dr.', participation.NTE_Secondary_Contact_Prefix__c);
        System.assertEquals('NTE Secondary Contact', participation.NTE_Secondary_Contact_Name__c);
        System.assertEquals('secondary@example.invalid', participation.NTE_Secondary_Contact_Email__c);
        System.assertEquals('CIC or Not for Profit', participation.NTE_Exhibitor_Organisation_Category__c);
        System.assertEquals('Yes', participation.NTE_Exhibitor_Hall_Schedule__c);
        System.assertEquals('Yes', participation.NTE_Has_Special_Requirements__c);
        System.assertEquals('NTE QA Industry Body', participation.NTE_Industry_Body_Details__c);
        System.assertEquals('LinkedIn', participation.NTE_Event_Discovery_Source__c);
        System.assertEquals('NTE Conversion Test', participation.NTE_Declaration_Name__c);
        System.assertEquals(true, participation.NTE_Terms_Accepted__c);

        Account organisation = [
            SELECT NTE_Participant__c, NTE_Event_Code__c, NTE_Source_Form_Type__c,
                   NTE_Booking_Reference__c, NTE_Last_Application_Date__c
            FROM Account
            WHERE Id = :convertedLead.ConvertedAccountId
        ];
        System.assertEquals(true, organisation.NTE_Participant__c);
        System.assertEquals('NTE2027', organisation.NTE_Event_Code__c);
        System.assertEquals('Exhibitor Application', organisation.NTE_Source_Form_Type__c);
        System.assertEquals('NTE-TEST-CONVERSION-FLOW', organisation.NTE_Booking_Reference__c);
        System.assertNotEquals(null, organisation.NTE_Last_Application_Date__c);

        Contact eventContact = [
            SELECT NTE_Participant__c, NTE_Event_Code__c, NTE_Source_Form_Type__c,
                   NTE_Booking_Reference__c, NTE_Last_Application_Date__c, NTE_Contact_Role__c
            FROM Contact
            WHERE Id = :convertedLead.ConvertedContactId
        ];
        System.assertEquals(true, eventContact.NTE_Participant__c);
        System.assertEquals('NTE2027', eventContact.NTE_Event_Code__c);
        System.assertEquals('Exhibitor Application', eventContact.NTE_Source_Form_Type__c);
        System.assertEquals('NTE-TEST-CONVERSION-FLOW', eventContact.NTE_Booking_Reference__c);
        System.assertEquals('Applicant / event contact', eventContact.NTE_Contact_Role__c);
        System.assertNotEquals(null, eventContact.NTE_Last_Application_Date__c);

        OpportunityContactRole primaryContactRole = [
            SELECT ContactId, IsPrimary
            FROM OpportunityContactRole
            WHERE OpportunityId = :convertedLead.ConvertedOpportunityId
              AND IsPrimary = true
            LIMIT 1
        ];
        System.assertEquals(convertedLead.ConvertedContactId, primaryContactRole.ContactId,
            'Lead conversion must preserve the applicant as the Opportunity primary contact for future reminders.');
        System.assertEquals(true, primaryContactRole.IsPrimary);

        List<Task> approvalAudits = [
            SELECT Subject, Description
            FROM Task
            WHERE WhatId = :convertedLead.ConvertedOpportunityId
            AND Subject LIKE 'NTE booking provisional email%'
        ];
        System.assertEquals(0, approvalAudits.size(), 'Conversion never sends an applicant email.');
    }

    @IsTest
    static void complimentaryConversionConfirmsOnlyWhenNoExtrasAreCharged() {
        NTEInboundLeadService.bypassEmailDelivery = true;
        NTEExhibitorApprovalEmailService.bypassEmailDelivery = true;
        Lead free = new Lead(
            FirstName = 'NTE', LastName = 'Complimentary Conversion', Company = 'NTE Complimentary Conversion',
            Email = 'complimentary-conversion@example.com', Web_Form_Type__c = 'Exhibitor Application',
            Booking_Reference__c = 'NTE-TEST-COMPLIMENTARY-CONVERSION', NTE_Event_Code__c = 'NTE2027',
            Exhibitor_Space_Selections__c = 'COBSEO Charity - Single - Free',
            Exhibitor_Organisation_Category__c = 'Charity - member of Cobseo',
            Stand_Power__c = 'No', Power_Socket_Count__c = 0,
            Planned_Exhibitor_Count__c = '2', Total_Staff_Count__c = 2,
            Additional_Staff_Required__c = 'No', Additional_Staff_Count__c = '0'
        );
        Lead extras = free.clone(false, false, false, false);
        extras.LastName = 'Complimentary Space With Extras'; extras.Company = 'NTE Charity Space With Extras';
        extras.Email = 'charity-extras-conversion@example.invalid';
        extras.Booking_Reference__c = 'NTE-TEST-CHARITY-EXTRAS-CONVERSION';
        extras.Stand_Power__c = 'Yes'; extras.Power_Socket_Count__c = 2;
        extras.Planned_Exhibitor_Count__c = '4'; extras.Total_Staff_Count__c = 4;
        extras.Additional_Staff_Required__c = 'Yes'; extras.Additional_Staff_Count__c = '2';
        Database.insert(new List<Lead>{free, extras}, AccessLevel.SYSTEM_MODE);

        Test.startTest();
        List<Database.LeadConvertResult> results = Database.convertLead(new List<Database.LeadConvert>{
            conversionFor(free), conversionFor(extras)
        }, false);
        for (Database.LeadConvertResult converted : results) { System.assert(converted.isSuccess()); NTEExhibitorApprovalEmailService.retryApprovalEmail(converted.getOpportunityId()); }
        Test.stopTest();
        for (Database.LeadConvertResult result : results) System.assert(result.isSuccess(), String.valueOf(result.getErrors()));
        Set<Id> bookingIds = new Set<Id>{results[0].getOpportunityId(), results[1].getOpportunityId()};
        Map<Id, Opportunity> bookings = new Map<Id, Opportunity>([SELECT Id, NTE_Listed_Price_Total__c,
            NTE_Invoice_Required__c, NTE_Approval_Email_Status__c FROM Opportunity WHERE Id IN :bookingIds]);
        System.assertEquals(0, bookings.get(results[0].getOpportunityId()).NTE_Listed_Price_Total__c,
            'The immediate complimentary confirmation must correspond to a genuine zero-charge booking.');
        System.assertEquals('No', bookings.get(results[0].getOpportunityId()).NTE_Invoice_Required__c);
        System.assert(bookings.get(results[1].getOpportunityId()).NTE_Listed_Price_Total__c > 0,
            'Paid power and extra staff remain chargeable even when the space itself is free.');
        System.assertEquals('Yes', bookings.get(results[1].getOpportunityId()).NTE_Invoice_Required__c);
        Map<Id, Task> audits = new Map<Id, Task>();
        for (Task audit : [SELECT WhatId, Subject, Description FROM Task WHERE WhatId IN :bookingIds
            AND Subject LIKE 'NTE booking provisional email%']) audits.put(audit.WhatId, audit);
        for (Id bookingId : bookingIds) {
            System.assertEquals('Sent', bookings.get(bookingId).NTE_Approval_Email_Status__c);
            System.assertEquals('NTE booking provisional email - sent', audits.get(bookingId).Subject);
        }
        System.assert(audits.get(results[0].getOpportunityId()).Description.contains('Template: NTE_Complimentary_Exhibitor_Approved'));
        System.assert(audits.get(results[1].getOpportunityId()).Description.contains('Template: NTE_Exhibitor_Approved'));
    }

    @IsTest
    static void partnerBankTransferConversionSendsPartnerProvisionalEmail() {
        NTEInboundLeadService.bypassEmailDelivery = true;
        NTEExhibitorApprovalEmailService.bypassEmailDelivery = true;
        Lead application = new Lead(
            FirstName = 'NTE',
            LastName = 'Partner Conversion',
            Company = 'NTE Partner Conversion',
            Email = 'partner-conversion@example.com',
            Web_Form_Type__c = 'Partner / Sponsor Application',
            Booking_Reference__c = 'NTE-TEST-PARTNER-CONVERSION',
            NTE_Event_Code__c = 'NTE2027',
            Sponsor_Package__c = 'Champion Partner',
            Planned_Exhibitor_Count__c = '2', Total_Staff_Count__c = 2,
            Invoice_Required__c = 'Yes',
            Payment_Method__c = 'Bank transfer'
        );
        Database.insert(application, AccessLevel.SYSTEM_MODE);

        Test.startTest();
        Database.LeadConvertResult result = Database.convertLead(conversionFor(application));
        NTEExhibitorApprovalEmailService.retryApprovalEmail(result.getOpportunityId());
        Test.stopTest();

        System.assert(result.isSuccess());
        Lead convertedLead = [SELECT ConvertedOpportunityId FROM Lead WHERE Id = :application.Id];
        Opportunity participation = [
            SELECT NTE_Invoice_Required__c, NTE_Payment_Method__c
            FROM Opportunity
            WHERE Id = :convertedLead.ConvertedOpportunityId
        ];
        System.assertEquals('Yes', participation.NTE_Invoice_Required__c);
        System.assertEquals('Bank transfer', participation.NTE_Payment_Method__c);
        Task approvalAudit = [
            SELECT Subject, Description FROM Task
            WHERE WhatId = :convertedLead.ConvertedOpportunityId
            AND Subject LIKE 'NTE booking provisional email%'
            LIMIT 1
        ];
        System.assertEquals('NTE booking provisional email - sent', approvalAudit.Subject, approvalAudit.Description);
        System.assert(approvalAudit.Description.contains('Template: NTE_Partner_Sponsor_Approved'));
    }

    @IsTest
    static void twelveConversionsCrossTheOldLimitWithoutFlowErrors() {
        NTEInboundLeadService.bypassEmailDelivery = true;
        NTEExhibitorApprovalEmailService.bypassEmailDelivery = true;
        NTEExhibitorApprovalEmailService.approvalSweepQueued = false;
        NTEExhibitorApprovalEmailService.approvalSweepEnqueueCount = 0;

        List<Lead> applications = new List<Lead>();
        for (Integer index = 0; index < 12; index++) {
            String token = EncodingUtil.convertToHex(
                Crypto.generateDigest('MD5', Blob.valueOf('NTE-BULK-' + String.valueOf(index)))
            ).substring(0, 12);
            applications.add(new Lead(
                FirstName = 'Bulk' + token.substring(0, 4),
                LastName = token.substring(4),
                Company = 'Organisation ' + token,
                Email = token.toLowerCase() + '@example.invalid',
                Web_Form_Type__c = 'Exhibitor Application',
                Booking_Reference__c = 'NTE-BULK-' + token,
                NTE_Event_Code__c = 'NTE2099',
                Exhibitor_Space_Selections__c = 'Single Garage - Track Side - £799 + VAT',
                Exhibitor_Organisation_Category__c = 'CIC or Not for Profit',
                Planned_Exhibitor_Count__c = '2', Total_Staff_Count__c = 2, Stand_Power__c = 'No'
            ));
        }
        Database.insert(applications, AccessLevel.SYSTEM_MODE);

        LeadStatus convertedStatus = [
            SELECT MasterLabel
            FROM LeadStatus
            WHERE IsConverted = true
            LIMIT 1
        ];
        List<Database.LeadConvert> conversions = new List<Database.LeadConvert>();
        for (Lead application : applications) {
            Database.LeadConvert conversion = new Database.LeadConvert();
            conversion.setLeadId(application.Id);
            conversion.setConvertedStatus(convertedStatus.MasterLabel);
            conversion.setOpportunityName(application.Company + ' Booking');
            conversions.add(conversion);
        }

        Test.startTest();
        List<Database.LeadConvertResult> results = Database.convertLead(conversions, false);
        Set<Id> opportunityIds = new Set<Id>();
        List<String> conversionErrors = new List<String>();
        for (Integer index = 0; index < results.size(); index++) {
            Database.LeadConvertResult result = results[index];
            if (result.isSuccess()) {
                opportunityIds.add(result.getOpportunityId());
            } else {
                conversionErrors.add('Index ' + String.valueOf(index) + ': ' + String.valueOf(result.getErrors()));
            }
        }
        System.assertEquals(0, conversionErrors.size(), String.join(conversionErrors, '\n'));
        System.assertEquals(0, Limits.getQueueableJobs());
        System.assertEquals(0, Limits.getEmailInvocations());
        Test.stopTest();

        System.assertEquals(12, opportunityIds.size());
        System.assertEquals(0, NTEExhibitorApprovalEmailService.approvalSweepEnqueueCount);
        System.assertEquals(0, [
            SELECT COUNT()
            FROM Task
            WHERE WhatId IN :opportunityIds
            AND Subject = 'NTE booking provisional email - sent'
        ]);
    }

    @IsTest
    static void mixedConversionsUseTheirExactBookingAfterAnotherBookingIsModified() {
        NTEInboundLeadService.bypassEmailDelivery = true;
        NTEExhibitorApprovalEmailService.bypassEmailDelivery = true;
        NTEExhibitorApprovalEmailService.skipProcessing = true;
        Lead older = targetApplication('Older unrelated', false);
        insert older;
        Database.LeadConvertResult olderResult = Database.convertLead(conversionFor(older));
        System.assert(olderResult.isSuccess());
        NTEExhibitorApprovalEmailService.skipProcessing = false;
        List<Lead> applications = new List<Lead>{targetApplication('Selected exhibitor', false), targetApplication('Selected partner', true)};
        insert applications;
        Test.startTest();
        List<Database.LeadConvertResult> results = Database.convertLead(new List<Database.LeadConvert>{
            conversionFor(applications[0]), conversionFor(applications[1])
        }, false);
        for (Database.LeadConvertResult result : results) System.assert(result.isSuccess(), String.valueOf(result.getErrors()));
        update new Opportunity(Id = olderResult.getOpportunityId(), Description = 'Modified after both selected applications were converted.');
        for (Database.LeadConvertResult converted : results) NTEExhibitorApprovalEmailService.retryApprovalEmail(converted.getOpportunityId());
        System.assertEquals(1, Limits.getQueueableJobs());
        System.assertEquals(0, Limits.getEmailInvocations());
        Test.stopTest();
        Set<Id> bookingIds = new Set<Id>{results[0].getOpportunityId(), results[1].getOpportunityId(), olderResult.getOpportunityId()};
        Id unrelatedId = olderResult.getOpportunityId();
        Map<Id, Opportunity> bookings = new Map<Id, Opportunity>([SELECT Id, Booking_Reference__c,
            NTE_Approval_Email_Lead_Id__c, NTE_Approval_Email_Status__c, NTE_Approval_Email_Recipient__c
            FROM Opportunity WHERE Id IN :bookingIds]);
        for (Integer index = 0; index < applications.size(); index++) {
            Opportunity booking = bookings.get(results[index].getOpportunityId());
            System.assertEquals(String.valueOf(applications[index].Id), booking.NTE_Approval_Email_Lead_Id__c);
            System.assertEquals(applications[index].Booking_Reference__c, booking.Booking_Reference__c);
            System.assertEquals('Sent', booking.NTE_Approval_Email_Status__c);
            System.assertEquals(applications[index].Email, booking.NTE_Approval_Email_Recipient__c);
            Task audit = [SELECT Description FROM Task WHERE WhatId = :booking.Id
                AND Subject = 'NTE booking provisional email - sent' LIMIT 1];
            System.assert(audit.Description.contains('Recipient: ' + applications[index].Email));
            System.assert(audit.Description.contains('Booking reference: ' + applications[index].Booking_Reference__c));
            System.assert(audit.Description.contains('Template: ' + (index == 0 ? 'NTE_Exhibitor_Approved' : 'NTE_Partner_Sponsor_Approved')));
        }
        System.assertEquals(null, bookings.get(olderResult.getOpportunityId()).NTE_Approval_Email_Status__c);
        System.assertEquals(0, [SELECT COUNT() FROM Task WHERE WhatId = :unrelatedId
            AND Subject LIKE 'NTE booking provisional email%']);
    }

    @IsTest
    static void existingSyntheticAccountAndContactKeepTheirIdentityAndReceiveTheirExactBooking() {
        NTEInboundLeadService.bypassEmailDelivery = true;
        NTEExhibitorApprovalEmailService.bypassEmailDelivery = true;
        Account organisation = new Account(Name = 'Alder Engineering', Phone = '020 7946 0012',
            Description = 'Established organisation details');
        insert organisation;
        Contact existingContact = new Contact(AccountId = organisation.Id, FirstName = 'Amira', LastName = 'Patel',
            Email = 'amira.patel@example.invalid', Phone = '020 7946 0013', Title = 'Account Director');
        insert existingContact;
        Lead application = targetApplication('Alder Engineering', false);
        application.Company = organisation.Name;
        application.FirstName = 'Elena'; application.LastName = 'Shaw';
        application.Email = 'elena.shaw@example.invalid';
        application.Phone = '020 7946 0099'; application.Title = 'Programme Manager';
        application.Event_Contact_Name__c = 'Ravi Morgan';
        application.Event_Contact_Email__c = 'ravi.morgan@example.invalid';
        insert application;
        Database.LeadConvert conversion = conversionFor(application);
        conversion.setAccountId(organisation.Id);
        conversion.setContactId(existingContact.Id);
        Test.startTest();
        Database.LeadConvertResult result = Database.convertLead(conversion);
        NTEExhibitorApprovalEmailService.retryApprovalEmail(result.getOpportunityId());
        Test.stopTest();
        System.assert(result.isSuccess(), String.valueOf(result.getErrors()));
        System.assertEquals(organisation.Id, result.getAccountId());
        System.assertEquals(existingContact.Id, result.getContactId());
        System.assertEquals(1, [SELECT COUNT() FROM Account]);
        System.assertEquals(1, [SELECT COUNT() FROM Contact]);
        Account preservedOrganisation = [SELECT Name, Phone, Description FROM Account WHERE Id = :organisation.Id];
        System.assertEquals('Alder Engineering', preservedOrganisation.Name);
        System.assertEquals('020 7946 0012', preservedOrganisation.Phone);
        System.assertEquals('Established organisation details', preservedOrganisation.Description);
        Contact preservedContact = [SELECT FirstName, LastName, Email, Phone, Title FROM Contact WHERE Id = :existingContact.Id];
        System.assertEquals('Amira', preservedContact.FirstName);
        System.assertEquals('Patel', preservedContact.LastName);
        System.assertEquals('amira.patel@example.invalid', preservedContact.Email);
        System.assertEquals('020 7946 0013', preservedContact.Phone);
        System.assertEquals('Account Director', preservedContact.Title);
        Id bookingId = result.getOpportunityId();
        Opportunity booking = [SELECT Booking_Reference__c, NTE_Event_Contact_Name__c, NTE_Event_Contact_Email__c,
            NTE_Approval_Email_Status__c, NTE_Approval_Email_Recipient__c FROM Opportunity WHERE Id = :bookingId];
        System.assertEquals(application.Booking_Reference__c, booking.Booking_Reference__c);
        System.assertEquals('Ravi Morgan', booking.NTE_Event_Contact_Name__c);
        System.assertEquals('ravi.morgan@example.invalid', booking.NTE_Event_Contact_Email__c);
        System.assertEquals('Sent', booking.NTE_Approval_Email_Status__c);
        System.assertEquals(existingContact.Email, booking.NTE_Approval_Email_Recipient__c);
        System.assertEquals(existingContact.Id, [SELECT ContactId FROM OpportunityContactRole
            WHERE OpportunityId = :bookingId AND IsPrimary = true].ContactId);
        Task audit = [SELECT Description FROM Task WHERE WhatId = :bookingId AND Subject = 'NTE booking provisional email - sent'];
        System.assert(audit.Description.contains('Recipient: ' + existingContact.Email));
        System.assert(!audit.Description.contains(application.Email));
    }

    @IsTest
    static void conversionRepricesCurrentInputsWithoutChangingOlderBookingFacts() {
        NTEInboundLeadService.bypassEmailDelivery = true;
        NTEExhibitorApprovalEmailService.bypassEmailDelivery = true;
        NTEExhibitorApprovalEmailService.skipProcessing = true;
        Lead previous = targetApplication('Beech Instruments', false);
        insert previous;
        Id oldBookingId = Database.convertLead(conversionFor(previous)).getOpportunityId();
        update new Opportunity(Id = oldBookingId, Amount = 777, NTE_Listed_Price_Total__c = 777,
            NTE_Exhibitor_Space_Price__c = 777, NTE_Invoice_Provided__c = true, NTE_Payment_Received__c = true);
        NTEExhibitorApprovalEmailService.skipProcessing = false;
        Lead exhibitor = targetApplication('Birch Mobility', false);
        Lead partner = targetApplication('Elm Logistics', true);
        insert new List<Lead>{exhibitor, partner};
        update new List<Lead>{
            new Lead(Id = exhibitor.Id, Exhibitor_Space_Selections__c = 'Double Garage - Track Side - £1,299 + VAT',
                Planned_Exhibitor_Count__c = '5', Stand_Power__c = 'Yes', Power_Socket_Count__c = 2,
                Total_Staff_Count__c = 2, Additional_Staff_Count__c = '0', Exhibitor_Space_Price__c = 0,
                Power_Socket_Total__c = 0, Additional_Staff_Total__c = 0, Listed_Price_Total__c = 0,
                Pricing_Status__c = 'Calculated', Invoice_Required__c = 'No'),
            new Lead(Id = partner.Id, Sponsor_Package__c = 'Champion Partner;Zone Sponsor',
                Sponsor_Package_Total__c = 1, Listed_Price_Total__c = 1, Pricing_Status__c = 'Calculated')
        };
        Test.startTest();
        List<Database.LeadConvertResult> results = Database.convertLead(new List<Database.LeadConvert>{
            conversionFor(exhibitor), conversionFor(partner)
        }, false);
        for (Database.LeadConvertResult converted : results) { System.assert(converted.isSuccess()); NTEExhibitorApprovalEmailService.retryApprovalEmail(converted.getOpportunityId()); }
        Test.stopTest();
        for (Database.LeadConvertResult result : results) System.assert(result.isSuccess(), String.valueOf(result.getErrors()));
        Set<Id> bookingIds = new Set<Id>{results[0].getOpportunityId(), results[1].getOpportunityId(), oldBookingId};
        Map<Id, Opportunity> bookings = new Map<Id, Opportunity>([SELECT Id, Amount, NTE_Listed_Price_Total__c,
            NTE_Exhibitor_Space_Price__c, NTE_Power_Socket_Total__c, NTE_Additional_Staff_Total__c,
            NTE_Initial_Staff_Count__c, NTE_Total_Staff_Count__c, NTE_Included_Staff_Count__c,
            NTE_Additional_Staff_Count__c, NTE_Invoice_Required__c, NTE_Sponsor_Package_Total__c,
            NTE_Pricing_Status__c, NTE_Approval_Email_Status__c, NTE_Invoice_Provided__c, NTE_Payment_Received__c
            FROM Opportunity WHERE Id IN :bookingIds]);
        Opportunity priced = bookings.get(results[0].getOpportunityId());
        System.assertEquals(1858.80, priced.Amount);
        System.assertEquals(1549, priced.NTE_Listed_Price_Total__c);
        System.assertEquals(1299, priced.NTE_Exhibitor_Space_Price__c);
        System.assertEquals(200, priced.NTE_Power_Socket_Total__c);
        System.assertEquals(50, priced.NTE_Additional_Staff_Total__c);
        System.assertEquals(5, priced.NTE_Initial_Staff_Count__c);
        System.assertEquals(5, priced.NTE_Total_Staff_Count__c);
        System.assertEquals(4, priced.NTE_Included_Staff_Count__c);
        System.assertEquals('1', priced.NTE_Additional_Staff_Count__c);
        System.assertEquals('Yes', priced.NTE_Invoice_Required__c);
        System.assertEquals('Calculated', priced.NTE_Pricing_Status__c);
        System.assertEquals('Sent', priced.NTE_Approval_Email_Status__c);
        System.assertEquals(7000, bookings.get(results[1].getOpportunityId()).NTE_Sponsor_Package_Total__c);
        System.assertEquals(8400, bookings.get(results[1].getOpportunityId()).Amount);
        System.assertEquals('Sent', bookings.get(results[1].getOpportunityId()).NTE_Approval_Email_Status__c);
        System.assertEquals(777, bookings.get(oldBookingId).Amount);
        System.assertEquals(777, bookings.get(oldBookingId).NTE_Listed_Price_Total__c);
        System.assertEquals(true, bookings.get(oldBookingId).NTE_Invoice_Provided__c);
        System.assertEquals(true, bookings.get(oldBookingId).NTE_Payment_Received__c);
        System.assertEquals(null, bookings.get(oldBookingId).NTE_Approval_Email_Status__c);
    }

    @IsTest
    static void incompleteCurrentSelectionCannotReuseItsEarlierCalculatedPrice() {
        NTEInboundLeadService.bypassEmailDelivery = true;
        NTEExhibitorApprovalEmailService.bypassEmailDelivery = true;
        Lead application = targetApplication('Rowan Equipment', false);
        insert application;
        update new Lead(Id = application.Id, Exhibitor_Space_Selections__c = null);
        Test.startTest();
        Database.LeadConvertResult result = Database.convertLead(conversionFor(application));
        NTEExhibitorApprovalEmailService.retryApprovalEmail(result.getOpportunityId());
        Test.stopTest();
        System.assert(result.isSuccess(), String.valueOf(result.getErrors()));
        Id bookingId = result.getOpportunityId();
        Opportunity booking = [SELECT NTE_Pricing_Status__c, NTE_Approval_Email_Status__c, NTE_Approval_Email_Error__c,
            NTE_Payment_Received__c FROM Opportunity WHERE Id = :bookingId];
        System.assertEquals('Review required', booking.NTE_Pricing_Status__c);
        System.assertEquals('Failed', booking.NTE_Approval_Email_Status__c);
        System.assert(booking.NTE_Approval_Email_Error__c.contains('price needs review'));
        System.assertEquals(false, booking.NTE_Payment_Received__c);
        System.assertEquals(0, [SELECT COUNT() FROM Task WHERE WhatId = :bookingId AND Subject = 'NTE booking provisional email - sent']);
    }

    @IsTest
    static void mismatchedConvertedLeadDoesNotSendToEitherBooking() {
        NTEInboundLeadService.bypassEmailDelivery = true;
        NTEExhibitorApprovalEmailService.bypassEmailDelivery = true;
        NTEExhibitorApprovalEmailService.skipProcessing = true;
        List<Lead> applications = new List<Lead>{targetApplication('Maple Software', false), targetApplication('Willow Services', false)};
        insert applications;
        List<Database.LeadConvertResult> results = Database.convertLead(new List<Database.LeadConvert>{
            conversionFor(applications[0]), conversionFor(applications[1])
        }, false);
        for (Database.LeadConvertResult result : results) System.assert(result.isSuccess(), String.valueOf(result.getErrors()));
        NTEExhibitorApprovalEmailService.skipProcessing = false;
        NTEExhibitorApprovalEmailService.Request request = new NTEExhibitorApprovalEmailService.Request();
        request.leadId = applications[0].Id; request.opportunityId = results[1].getOpportunityId();
        Test.startTest();
        NTEExhibitorApprovalEmailService.sendApprovalConfirmation(new List<NTEExhibitorApprovalEmailService.Request>{request, request});
        Test.stopTest();
        Id affectedId = results[1].getOpportunityId(); Id originalId = results[0].getOpportunityId();
        Opportunity affected = [SELECT NTE_Approval_Email_Status__c, NTE_Approval_Email_Error__c FROM Opportunity WHERE Id = :affectedId];
        System.assertEquals('Failed', affected.NTE_Approval_Email_Status__c);
        System.assert(affected.NTE_Approval_Email_Error__c.contains('could not be matched'));
        System.assertEquals(null, [SELECT NTE_Approval_Email_Status__c FROM Opportunity WHERE Id = :originalId].NTE_Approval_Email_Status__c);
        System.assertEquals(0, [SELECT COUNT() FROM Task WHERE Subject = 'NTE booking provisional email - sent']);
    }

    @IsTest
    static void publicRetryReportsQueueFailureTruthfullyWithoutLosingTheBooking() {
        NTEInboundLeadService.bypassEmailDelivery = true;
        NTEExhibitorApprovalEmailService.bypassEmailDelivery = true;
        NTEExhibitorApprovalEmailService.skipProcessing = true;
        Lead application = targetApplication('Oak Instrumentation', false);
        insert application;
        Id bookingId = Database.convertLead(conversionFor(application)).getOpportunityId();
        NTEExhibitorApprovalEmailService.skipProcessing = false;
        NTEExhibitorApprovalEmailService.simulateQueueFailure = true;
        Test.startTest();
        NTEExhibitorApprovalEmailService.ApprovalRetryResult result = NTEExhibitorApprovalEmailService.retryApprovalEmail(bookingId);
        System.assertEquals(0, result.queuedCount);
        System.assert(result.message.contains('could not be queued'));
        System.assertEquals(0, Limits.getQueueableJobs());
        Test.stopTest();
        Opportunity booking = [SELECT NTE_Approval_Email_Status__c, NTE_Approval_Email_Error__c, NTE_Listed_Price_Total__c
            FROM Opportunity WHERE Id = :bookingId];
        System.assertEquals('Failed', booking.NTE_Approval_Email_Status__c);
        System.assertEquals(result.message, booking.NTE_Approval_Email_Error__c);
        System.assertEquals(799, booking.NTE_Listed_Price_Total__c);
    }

    @IsTest
    static void publicRetryReportsOnlyItsExactQueuedBooking() {
        NTEInboundLeadService.bypassEmailDelivery = true;
        NTEExhibitorApprovalEmailService.bypassEmailDelivery = true;
        NTEExhibitorApprovalEmailService.skipProcessing = true;
        Lead application = targetApplication('Hazel Systems', true);
        insert application;
        Id bookingId = Database.convertLead(conversionFor(application)).getOpportunityId();
        NTEExhibitorApprovalEmailService.skipProcessing = false;
        Test.startTest();
        NTEExhibitorApprovalEmailService.ApprovalRetryResult result = NTEExhibitorApprovalEmailService.retryApprovalEmail(bookingId);
        System.assertEquals(1, result.queuedCount);
        System.assertEquals('Email queued.', result.message);
        System.assertEquals(1, Limits.getQueueableJobs());
        System.assertEquals(0, Limits.getEmailInvocations());
        Test.stopTest();
        System.assertEquals('Sent', [SELECT NTE_Approval_Email_Status__c FROM Opportunity WHERE Id = :bookingId].NTE_Approval_Email_Status__c);
        System.assertEquals(1, [SELECT COUNT() FROM Task WHERE WhatId = :bookingId AND Subject = 'NTE booking provisional email - sent']);
    }

    @IsTest
    static void noOpportunityConversionIsRejected() {
        // The owner requires a new Opportunity for every NTE application.
        NTEInboundLeadService.bypassEmailDelivery = true;
        NTEExhibitorApprovalEmailService.bypassEmailDelivery = true;
        Lead application = targetApplication('Pine Automation', false);
        insert application;
        Database.LeadConvert conversion = new Database.LeadConvert();
        conversion.setLeadId(application.Id);
        conversion.setConvertedStatus([SELECT MasterLabel FROM LeadStatus WHERE IsConverted = true LIMIT 1].MasterLabel);
        conversion.setDoNotCreateOpportunity(true);
        Test.startTest();
        Database.LeadConvertResult result = Database.convertLead(conversion, false);
        Test.stopTest();
        System.assert(!result.isSuccess(), String.valueOf(result.getErrors()));
        System.assertEquals(null, result.getOpportunityId());
        System.assertEquals(0, [SELECT COUNT() FROM Opportunity]);
        System.assertEquals(0, [SELECT COUNT() FROM Task WHERE Subject LIKE 'NTE booking provisional email%']);
        System.assertEquals(false, [SELECT IsConverted FROM Lead WHERE Id = :application.Id].IsConverted);
    }

    @IsTest
    static void existingBookingConversionIsRejected() {
        // Reject reuse before any existing booking facts can be overwritten.
        NTEInboundLeadService.bypassEmailDelivery = true;
        NTEExhibitorApprovalEmailService.bypassEmailDelivery = true;
        Account organisation = new Account(Name = 'Larch Engineering');
        insert organisation;
        Contact primary = new Contact(AccountId = organisation.Id, FirstName = 'Hannah', LastName = 'Cole', Email = 'hannah.cole@example.invalid');
        insert primary;
        String stage = [SELECT MasterLabel FROM OpportunityStage WHERE IsActive = true AND IsClosed = false ORDER BY SortOrder LIMIT 1].MasterLabel;
        Opportunity previous = new Opportunity(Name = 'Larch prior booking', AccountId = organisation.Id,
            StageName = stage, CloseDate = Date.today().addDays(30),
            RecordTypeId = [SELECT Id FROM RecordType WHERE SobjectType = 'Opportunity' AND DeveloperName = 'NTE_Event_Opportunity' LIMIT 1].Id,
            NTE_Source_Form_Type__c = 'Exhibitor Application', NTE_Event_Code__c = 'NTE2098',
            Booking_Reference__c = 'NTE-LARCH-PRIOR', Amount = 777, NTE_Listed_Price_Total__c = 777,
            NTE_Exhibitor_Space_Price__c = 777, NTE_Pricing_Status__c = 'Calculated',
            NTE_Invoice_Provided__c = true, NTE_Payment_Received__c = true, NTE_Approval_Email_Status__c = 'Sent');
        insert previous;
        insert new OpportunityContactRole(OpportunityId = previous.Id, ContactId = primary.Id, IsPrimary = true);
        Lead application = targetApplication('Larch Engineering', true);
        insert application;
        Database.LeadConvert conversion = new Database.LeadConvert();
        conversion.setLeadId(application.Id);
        conversion.setConvertedStatus([SELECT MasterLabel FROM LeadStatus WHERE IsConverted = true LIMIT 1].MasterLabel);
        conversion.setAccountId(organisation.Id);
        conversion.setContactId(primary.Id);
        conversion.setOpportunityId(previous.Id);
        Test.startTest();
        Database.LeadConvertResult result = Database.convertLead(conversion, false);
        Test.stopTest();
        System.assert(!result.isSuccess(), String.valueOf(result.getErrors()));
        System.assertEquals(null, result.getOpportunityId());
        System.assertEquals(1, [SELECT COUNT() FROM Opportunity]);
        Opportunity merged = [SELECT Booking_Reference__c, NTE_Event_Code__c, NTE_Source_Form_Type__c, Amount,
            NTE_Payment_Received__c, NTE_Approval_Email_Status__c FROM Opportunity WHERE Id = :previous.Id];
        System.assertEquals('NTE-LARCH-PRIOR', merged.Booking_Reference__c);
        System.assertEquals('NTE2098', merged.NTE_Event_Code__c);
        System.assertEquals('Exhibitor Application', merged.NTE_Source_Form_Type__c);
        System.assertEquals(777, merged.Amount);
        System.assertEquals(true, merged.NTE_Payment_Received__c,
            'Rejected conversion preserves the previous booking and payment.');
        System.assertEquals('Sent', merged.NTE_Approval_Email_Status__c);
        System.assertEquals(0, [SELECT COUNT() FROM Task WHERE Subject LIKE 'NTE booking provisional email%']);
    }

    private static Lead targetApplication(String label, Boolean partner) {
        String token = label.toLowerCase().replace(' ', '-');
        return new Lead(FirstName = 'Exact', LastName = label, Company = 'Exact Conversion ' + label,
            Email = token + '@example.invalid', Web_Form_Type__c = partner ? 'Partner / Sponsor Application' : 'Exhibitor Application',
            Booking_Reference__c = 'NTE-EXACT-' + token, NTE_Event_Code__c = 'NTE2099',
            Sponsor_Package__c = partner ? 'Champion Partner' : null,
            Exhibitor_Space_Selections__c = partner ? null : 'Single Garage - Track Side - £799 + VAT',
            Exhibitor_Organisation_Category__c = partner ? null : 'CIC or Not for Profit',
            Planned_Exhibitor_Count__c = '2', Total_Staff_Count__c = 2, Stand_Power__c = 'No',
            Invoice_Required__c = 'Yes', Payment_Method__c = 'Bank transfer');
    }

    private static Database.LeadConvert conversionFor(Lead application) {
        LeadStatus convertedStatus = [
            SELECT MasterLabel
            FROM LeadStatus
            WHERE IsConverted = true
            LIMIT 1
        ];
        Database.LeadConvert conversion = new Database.LeadConvert();
        conversion.setLeadId(application.Id);
        conversion.setConvertedStatus(convertedStatus.MasterLabel);
        conversion.setOpportunityName(application.Company + ' Booking');
        return conversion;
    }
}
