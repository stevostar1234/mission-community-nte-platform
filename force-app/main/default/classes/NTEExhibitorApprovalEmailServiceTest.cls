@IsTest
private class NTEExhibitorApprovalEmailServiceTest {
    private class Fixture {
        Lead application;
        Opportunity booking;
        Contact primary;
        NTEExhibitorApprovalEmailService.Request request() {
            NTEExhibitorApprovalEmailService.Request result = new NTEExhibitorApprovalEmailService.Request();
            result.leadId = application.Id;
            result.opportunityId = booking.Id;
            return result;
        }
    }
    @TestSetup
    static void assignFieldAccess() {
        PermissionSet permissions = [SELECT Id FROM PermissionSet WHERE Name = 'NTE_Forms_Administration' LIMIT 1];
        if ([SELECT COUNT() FROM PermissionSetAssignment WHERE AssigneeId = :UserInfo.getUserId()
            AND PermissionSetId = :permissions.Id] == 0) {
            insert new PermissionSetAssignment(AssigneeId = UserInfo.getUserId(), PermissionSetId = permissions.Id);
        }
    }

    @IsTest
    static void textAlternativePreservesDetailsWithoutHiddenLayoutText() {
        String html = '<head><title>Hidden title</title><style>.hidden{display:none}</style></head>'
            + '<div class="preheader">Hidden preview</div><table><tr><td>&nbsp;</td></tr></table>'
            + '<a href="https://example.com/logo"><img src="logo.png" alt="Logo"></a>'
            + '<p>Hello &lt;Team&gt; &amp; friends.</p><table><tr><td>Names</td><td>Alex<br>Jo</td></tr>'
            + '<tr><td>Total</td><td>&pound;1,234.50</td></tr></table>'
            + '<p><a href="https://example.com/?a=1&amp;b=2">Open booking</a></p>';
        System.assertEquals('Hello <Team> & friends.\n\nNames Alex\nJo\nTotal £1,234.50\n\n'
            + 'Open booking (https://example.com/?a=1&b=2)',
            NTEExhibitorApprovalEmailService.plainTextFromHtml(html));
        System.assertEquals('Zoë\n李\nSøren', NTEExhibitorApprovalEmailService.plainTextFromHtml('<p>Zoë\n<br>李\r\n<br>Søren</p>'),
            'Native Salesforce source newlines beside break tags must not double-space each name.');
        System.assertEquals('First\n\nSecond', NTEExhibitorApprovalEmailService.plainTextFromHtml('<p>First\n<br>\n<br>Second</p>'),
            'An intentional empty line represented by two break tags must remain.');
    }

    @IsTest
    static void exhibitorUsesPrimaryContactAndSendsOnlyOnce() {
        Fixture fixture = booking('EXHIBITOR', false);
        Test.startTest();
        deliver(fixture);
        deliver(fixture);
        Test.stopTest();
        Opportunity result = state(fixture.booking.Id);
        System.assertEquals('Sent', result.NTE_Approval_Email_Status__c, 'Provisional email error: ' + result.NTE_Approval_Email_Error__c);
        System.assertEquals(fixture.primary.Email.toLowerCase(), result.NTE_Approval_Email_Recipient__c);
        System.assertNotEquals(null, result.NTE_Approval_Email_Sent_At__c);
        System.assertEquals(1, auditCount(fixture.booking.Id));
        String html = NTEExhibitorApprovalEmailService.htmlByOpportunityId.get(fixture.booking.Id);
        System.assert(html.contains('Hi Primary'));
        System.assert(html.contains('provisionally reserved'));
        System.assert(html.contains('exhibitor-staff-update.html'));
        System.assert(html.contains('heavy-vehicle-details.html'));
        System.assert(html.contains('logo-upload.html'));
        System.assert(!html.contains('event-day@example.invalid'));
        System.assert(!html.contains('applicant-EXHIBITOR@example.invalid'));
        System.assert(!html.contains('{NTE_'));
        System.assertEquals('NTE_Exhibitor_Approved',
            NTEExhibitorApprovalEmailService.selectedTemplateByOpportunityId.get(fixture.booking.Id));
        System.assertEquals(false, result.NTE_Quote_Provided__c);
        System.assertEquals(false, result.NTE_Invoice_Provided__c);
        System.assertEquals(false, result.NTE_Payment_Received__c);
    }

    @IsTest
    static void partnerUsesPartnerTemplateAndPreparationForm() {
        Fixture fixture = booking('PARTNER', true);
        fixture.booking.NTE_Payment_Method__c = 'Bank transfer';
        Database.update(fixture.booking, AccessLevel.SYSTEM_MODE);
        Test.startTest();
        deliver(fixture);
        Test.stopTest();
        System.assertEquals('Sent', state(fixture.booking.Id).NTE_Approval_Email_Status__c);
        System.assertEquals('NTE_Partner_Sponsor_Approved',
            NTEExhibitorApprovalEmailService.selectedTemplateByOpportunityId.get(fixture.booking.Id));
        String html = NTEExhibitorApprovalEmailService.htmlByOpportunityId.get(fixture.booking.Id);
        System.assert(html.contains('partner-sponsor-staff-update.html'));
        System.assert(html.contains('payment instructions'));
        System.assert(!html.contains('exhibitor-staff-update.html'));
        System.assert(!html.contains('buy.stripe.com'));
    }

    @IsTest
    static void complimentaryBookingConfirmsOnlyWhenNoChargeIsDue() {
        Fixture free = booking('FREE', false);
        Fixture extras = booking('EXTRAS', false);
        for (Fixture fixture : new List<Fixture>{free, extras}) {
            fixture.booking.NTE_Exhibitor_Space_Selections__c = 'COBSEO Charity - Single - Free';
            fixture.booking.NTE_Exhibitor_Organisation_Category__c = 'Charity - member of Cobseo';
            fixture.booking.NTE_Exhibitor_Space_Price__c = 0;
            fixture.booking.Amount = fixture == free ? 0 : 60;
            fixture.booking.NTE_Listed_Price_Total__c = fixture == free ? 0 : 50;
            fixture.booking.NTE_Power_Socket_Total__c = fixture == free ? 0 : 50;
            fixture.booking.NTE_Power_Socket_Count__c = fixture == free ? 0 : 1;
            fixture.booking.NTE_Power_Socket_Unit_Price__c = fixture == free ? 0 : 50;
            Database.update(fixture.booking, AccessLevel.SYSTEM_MODE);
        }
        Test.startTest();
        deliver(free);
        deliver(extras);
        Test.stopTest();
        System.assert(NTEExhibitorApprovalEmailService.htmlByOpportunityId.get(free.booking.Id).contains('No payment is due.'));
        String extrasHtml = NTEExhibitorApprovalEmailService.htmlByOpportunityId.get(extras.booking.Id);
        System.assert(extrasHtml.contains('provisionally reserved'));
        System.assert(!extrasHtml.contains('No payment is due.'));
        System.assertEquals('NTE_Exhibitor_Approved',
            NTEExhibitorApprovalEmailService.selectedTemplateByOpportunityId.get(extras.booking.Id));
    }

    @IsTest
    static void partnerReservationUsesSelectedNamesAndPreservesSavedCombinedPrice() {
        Fixture fixture = booking('PACKAGE-NAMES', true);
        fixture.booking.NTE_Sponsor_Package__c = 'Gold Partner;Event Guide Sponsor';
        fixture.booking.NTE_Heavy_Vehicle_Required__c = 'No';
        fixture.booking.NTE_Event_Code__c = 'NTE2028';
        Database.update(fixture.booking, AccessLevel.SYSTEM_MODE);
        Test.startTest();
        deliver(fixture);
        Test.stopTest();
        String html = NTEExhibitorApprovalEmailService.htmlByOpportunityId.get(fixture.booking.Id);
        System.assertNotEquals(null, html, 'Reservation error: ' + state(fixture.booking.Id).NTE_Approval_Email_Error__c);
        String charges = html.substring(html.indexOf('Allocation and charges'), html.indexOf('Staff details and event preparation'));
        System.assert(charges.contains('Gold Partner + Event Guide Sponsor'));
        System.assert(!charges.contains('Partner / sponsor package'));
        System.assert(charges.contains('£2000.00'), 'Use the saved combined price, not the current catalogue sum.');
        System.assert(html.contains('reserve your partner / sponsor package at NTE27.'));
        System.assert(html.contains('Your partner / sponsor package will be confirmed once payment has been received.'));
        System.assert(!html.contains('items on flatbed trailers'), 'Do not refer to an omitted Vehicle details link.');
        System.assert(html.contains('setting up between 14:00-18:00 hrs on Sunday is required.'));
        System.assert(!html.contains('{NTE_'));
        String plain = NTEExhibitorApprovalEmailService.plainTextFromHtml(html);
        System.assert(plain.contains('Gold Partner + Event Guide Sponsor'));
        System.assert(plain.contains('NTE27'));
        System.assertEquals('NTE2028', fixture.booking.NTE_Event_Code__c, 'Static email branding preserves the actual booking event.');
        System.assert(!plain.contains('££'));
        System.assertEquals(0, Limits.getEmailInvocations());
    }

    @IsTest
    static void missingPrimaryEmailFailsWithoutFallbackAndCanBeRetried() {
        Fixture fixture = booking('MISSING-EMAIL', false);
        fixture.primary.Email = null;
        Database.update(fixture.primary, AccessLevel.SYSTEM_MODE);
        Test.startTest();
        deliver(fixture);
        Opportunity failed = state(fixture.booking.Id);
        System.assertEquals('Failed', failed.NTE_Approval_Email_Status__c);
        System.assert(failed.NTE_Approval_Email_Error__c.contains('primary Contact'));
        System.assertEquals(null, failed.NTE_Approval_Email_Sent_At__c);
        fixture.primary.Email = 'repaired-primary@example.invalid';
        Database.update(fixture.primary, AccessLevel.SYSTEM_MODE);
        deliver(fixture);
        Test.stopTest();
        System.assertEquals('Sent', state(fixture.booking.Id).NTE_Approval_Email_Status__c);
        System.assertEquals('repaired-primary@example.invalid', state(fixture.booking.Id).NTE_Approval_Email_Recipient__c);
        System.assertEquals(2, auditCount(fixture.booking.Id));
    }

    @IsTest
    static void absentPrimaryRoleFailsDespiteUsableApplicantAndDayContact() {
        Fixture fixture = booking('MISSING-ROLE', false);
        delete [SELECT Id FROM OpportunityContactRole WHERE OpportunityId = :fixture.booking.Id];
        Test.startTest();
        deliver(fixture);
        Test.stopTest();
        System.assertEquals('Failed', state(fixture.booking.Id).NTE_Approval_Email_Status__c);
        System.assertEquals(0, NTEExhibitorApprovalEmailService.acceptedDispatchCount);
    }

    @IsTest
    static void failedSendRetainsVisibleFailureAndOnlySuccessfulRetryIsSent() {
        Fixture fixture = booking('SEND-FAILURE', false);
        NTEExhibitorApprovalEmailService.simulateSendFailure = true;
        Test.startTest();
        deliver(fixture);
        System.assertEquals('Failed', state(fixture.booking.Id).NTE_Approval_Email_Status__c);
        NTEExhibitorApprovalEmailService.simulateSendFailure = false;
        deliver(fixture);
        deliver(fixture);
        Test.stopTest();
        System.assertEquals('Sent', state(fixture.booking.Id).NTE_Approval_Email_Status__c);
        System.assertEquals(1, NTEExhibitorApprovalEmailService.acceptedDispatchCount);
        System.assertEquals(2, auditCount(fixture.booking.Id));
    }

    @IsTest
    static void explicitRequestsCoalesceOnePostCommitJob() {
        Fixture first = booking('QUEUED-FIRST', false);
        Fixture second = booking('QUEUED-SECOND', true);
        Test.startTest();
        for (Integer index = 0; index < 100; index++) {
            NTEExhibitorApprovalEmailService.sendApprovalConfirmation(
                new List<NTEExhibitorApprovalEmailService.Request>{first.request(), null}
            );
        }
        NTEExhibitorApprovalEmailService.sendApprovalConfirmation(
            new List<NTEExhibitorApprovalEmailService.Request>{second.request()}
        );
        System.assertEquals(1, Limits.getQueueableJobs());
        System.assertEquals(0, Limits.getEmailInvocations());
        System.assertEquals('Pending', state(first.booking.Id).NTE_Approval_Email_Status__c);
        System.assertEquals('Pending', state(second.booking.Id).NTE_Approval_Email_Status__c);
        Test.stopTest();
        System.assertEquals('Sent', state(first.booking.Id).NTE_Approval_Email_Status__c,
            'Provisional email error: ' + state(first.booking.Id).NTE_Approval_Email_Error__c);
        System.assertEquals('Sent', state(second.booking.Id).NTE_Approval_Email_Status__c,
            'Provisional email error: ' + state(second.booking.Id).NTE_Approval_Email_Error__c);
    }

    @IsTest
    static void unpricedBookingCannotSendAConfirmationEvenWhenMarkedPaid() {
        Fixture fixture = booking('UNPRICED', true);
        fixture.booking.NTE_Pricing_Status__c = 'Review required';
        fixture.booking.Amount = 0;
        fixture.booking.NTE_Listed_Price_Total__c = 0;
        fixture.booking.NTE_Sponsor_Package_Total__c = 0;
        fixture.booking.NTE_Payment_Received__c = true;
        Database.update(fixture.booking, AccessLevel.SYSTEM_MODE);
        Test.startTest();
        deliver(fixture);
        Test.stopTest();
        Opportunity result = state(fixture.booking.Id);
        System.assertEquals('Failed', result.NTE_Approval_Email_Status__c);
        System.assert(result.NTE_Approval_Email_Error__c.contains('existing payment'));
        System.assertEquals(null, result.NTE_Approval_Email_Sent_At__c);
        System.assertEquals(true, result.NTE_Payment_Received__c, 'Email validation must not rewrite existing payment history.');
        System.assertEquals(0, NTEExhibitorApprovalEmailService.acceptedDispatchCount);
        System.assert(!NTEExhibitorApprovalEmailService.htmlByOpportunityId.containsKey(fixture.booking.Id));
    }

    @IsTest
    static void blankPricingStatusPreservesKnownChargeButNotUnknownZero() {
        Fixture priced = booking('LEGACY-CHARGE', false);
        Fixture unknown = booking('LEGACY-UNKNOWN', true);
        priced.booking.NTE_Pricing_Status__c = null;
        unknown.booking.NTE_Pricing_Status__c = null;
        unknown.booking.Amount = 0;
        unknown.booking.NTE_Listed_Price_Total__c = 0;
        unknown.booking.NTE_Sponsor_Package_Total__c = 0;
        Database.update(new List<Opportunity>{priced.booking, unknown.booking}, AccessLevel.SYSTEM_MODE);
        Test.startTest();
        deliver(priced);
        deliver(unknown);
        Test.stopTest();
        System.assertEquals('Sent', state(priced.booking.Id).NTE_Approval_Email_Status__c);
        System.assertEquals('Failed', state(unknown.booking.Id).NTE_Approval_Email_Status__c);
        System.assertEquals(1, NTEExhibitorApprovalEmailService.acceptedDispatchCount);
    }

    @IsTest
    static void inconsistentSavedChargeNeedsReviewWithoutManualAdjustment() {
        Fixture fixture = booking('INCONSISTENT-CHARGE', false);
        fixture.booking.Amount = 700;
        fixture.booking.NTE_Listed_Price_Total__c = 700;
        Database.update(fixture.booking, AccessLevel.SYSTEM_MODE);
        Test.startTest();
        deliver(fixture);
        Test.stopTest();
        System.assertEquals('Failed', state(fixture.booking.Id).NTE_Approval_Email_Status__c);
        System.assertEquals(0, NTEExhibitorApprovalEmailService.acceptedDispatchCount);
        Opportunity retained = [SELECT Amount, NTE_Listed_Price_Total__c, NTE_Exhibitor_Space_Price__c
            FROM Opportunity WHERE Id = :fixture.booking.Id];
        System.assertEquals(700, retained.Amount);
        System.assertEquals(700, retained.NTE_Listed_Price_Total__c);
        System.assertEquals(800, retained.NTE_Exhibitor_Space_Price__c);
    }

    @IsTest
    static void inconsistentItemisedPowerFailsOnlyItsBookingAndCanBeRepaired() {
        Fixture affected = booking('POWER-ARITHMETIC', false);
        Fixture healthy = booking('POWER-HEALTHY', true);
        affected.booking.NTE_Power_Socket_Count__c = 2;
        affected.booking.NTE_Power_Socket_Unit_Price__c = 50;
        affected.booking.NTE_Power_Socket_Total__c = 50;
        affected.booking.Amount = 850;
        affected.booking.NTE_Listed_Price_Total__c = 850;
        update affected.booking;
        Test.startTest();
        NTEExhibitorApprovalEmailService.processRequests(new List<NTEExhibitorApprovalEmailService.Request>{
            affected.request(), healthy.request()
        });
        System.assertEquals('Failed', state(affected.booking.Id).NTE_Approval_Email_Status__c,
            'An item showing 2 × £50 cannot be sent with a £50 saved charge even when the booking sum balances.');
        System.assertEquals('Sent', state(healthy.booking.Id).NTE_Approval_Email_Status__c);
        System.assert(!NTEExhibitorApprovalEmailService.htmlByOpportunityId.containsKey(affected.booking.Id));
        System.assertEquals(850, [SELECT Amount FROM Opportunity WHERE Id = :affected.booking.Id].Amount,
            'Readiness validation must preserve the saved monetary facts.');
        update new Opportunity(Id = affected.booking.Id, NTE_Power_Socket_Total__c = 100,
            Amount = 1080, NTE_Listed_Price_Total__c = 900);
        deliver(affected);
        deliver(healthy);
        Test.stopTest();
        System.assertEquals('Sent', state(affected.booking.Id).NTE_Approval_Email_Status__c);
        System.assertEquals(2, NTEExhibitorApprovalEmailService.acceptedDispatchCount);
        System.assertEquals(2, auditCount(affected.booking.Id));
        System.assertEquals(1, auditCount(healthy.booking.Id));
    }

    @IsTest
    static void additionalStaffChargeNeedsAWholeQuantityAndSavedUnitPrice() {
        Fixture fixture = booking('STAFF-ARITHMETIC', false);
        Test.startTest();
        for (String quantity : new List<String>{'two', '1.5', '-2', '0'}) {
            update new Opportunity(Id = fixture.booking.Id, NTE_Additional_Staff_Count__c = quantity,
                NTE_Additional_Staff_Unit_Price__c = 50, NTE_Additional_Staff_Total__c = 100,
                Amount = 1080, NTE_Listed_Price_Total__c = 900);
            deliver(fixture);
            System.assertEquals('Failed', state(fixture.booking.Id).NTE_Approval_Email_Status__c,
                'Invalid additional-staff quantity: ' + quantity);
        }
        update new Opportunity(Id = fixture.booking.Id, NTE_Additional_Staff_Count__c = '2',
            NTE_Additional_Staff_Unit_Price__c = null);
        deliver(fixture);
        System.assertEquals('Failed', state(fixture.booking.Id).NTE_Approval_Email_Status__c);
        update new Opportunity(Id = fixture.booking.Id, NTE_Additional_Staff_Unit_Price__c = 50);
        deliver(fixture);
        Test.stopTest();
        System.assertEquals('Sent', state(fixture.booking.Id).NTE_Approval_Email_Status__c);
        System.assertEquals(1, NTEExhibitorApprovalEmailService.acceptedDispatchCount);
    }

    @IsTest
    static void participantTypeCannotHideAnUnitemisedComponent() {
        Fixture exhibitor = booking('HIDDEN-SPONSOR', false);
        Fixture partner = booking('HIDDEN-SPACE', true);
        update new List<Opportunity>{
            new Opportunity(Id = exhibitor.booking.Id, NTE_Exhibitor_Space_Price__c = 700, NTE_Sponsor_Package_Total__c = 100),
            new Opportunity(Id = partner.booking.Id, NTE_Exhibitor_Space_Price__c = 100, NTE_Sponsor_Package_Total__c = 1900)
        };
        Test.startTest();
        NTEExhibitorApprovalEmailService.processRequests(new List<NTEExhibitorApprovalEmailService.Request>{
            exhibitor.request(), partner.request()
        });
        Test.stopTest();
        System.assertEquals('Failed', state(exhibitor.booking.Id).NTE_Approval_Email_Status__c);
        System.assertEquals('Failed', state(partner.booking.Id).NTE_Approval_Email_Status__c);
        System.assertEquals(0, NTEExhibitorApprovalEmailService.acceptedDispatchCount);
    }

    @IsTest
    static void malformedPreparationDestinationsFailOnlyWhenApplicable() {
        Opportunity exhibitor = new Opportunity(NTE_Source_Form_Type__c = 'Exhibitor Application', NTE_Heavy_Vehicle_Required__c = 'No');
        NTE_Routing_Config__mdt routing = validRouting();
        for (String url : new List<String>{null, '', 'https://', 'https:///staff', 'http://forms.example.invalid/staff',
            'https://forms example.invalid/staff', 'https://forms.example.invalid/ staff',
            'https://forms.example.invalid/staff\n', 'https://user:password@forms.example.invalid/staff'}) {
            routing.Exhibitor_Staff_Form_URL__c = url;
            System.assertNotEquals(null, NTEExhibitorApprovalEmailService.preparationConfigurationError(exhibitor, routing),
                'An unusable preparation destination must not reach the applicant: ' + url);
        }
        routing = validRouting();
        routing.Heavy_Vehicle_Form_URL__c = 'https://';
        routing.Partner_Staff_Form_URL__c = null;
        System.assertEquals(null, NTEExhibitorApprovalEmailService.preparationConfigurationError(exhibitor, routing),
            'An exhibitor who does not need logistics should not wait on unrelated destinations.');
        exhibitor.NTE_Heavy_Vehicle_Required__c = 'Yes';
        System.assertNotEquals(null, NTEExhibitorApprovalEmailService.preparationConfigurationError(exhibitor, routing));
        exhibitor.NTE_Heavy_Vehicle_Required__c = null;
        System.assertNotEquals(null, NTEExhibitorApprovalEmailService.preparationConfigurationError(exhibitor, routing));
        routing = validRouting();
        exhibitor.NTE_Source_Form_Type__c = 'Partner / Sponsor Application';
        routing.Exhibitor_Staff_Form_URL__c = null;
        System.assertEquals(null, NTEExhibitorApprovalEmailService.preparationConfigurationError(exhibitor, routing));
        routing.Logo_Update_Form_URL__c = 'https://';
        System.assertNotEquals(null, NTEExhibitorApprovalEmailService.preparationConfigurationError(exhibitor, routing));
    }

    @IsTest
    static void unusableBookingReferenceLeavesPreparationEmailUnsent() {
        Fixture fixture = booking('REFERENCE-READINESS', false);
        update new Opportunity(Id = fixture.booking.Id, Booking_Reference__c = 'BOOKING-001');
        Test.startTest();
        deliver(fixture);
        Test.stopTest();
        System.assertEquals('Failed', state(fixture.booking.Id).NTE_Approval_Email_Status__c);
        System.assert(state(fixture.booking.Id).NTE_Approval_Email_Error__c.contains('booking reference'));
        System.assertEquals(0, NTEExhibitorApprovalEmailService.acceptedDispatchCount);
        System.assertEquals('BOOKING-001', [SELECT Booking_Reference__c FROM Opportunity WHERE Id = :fixture.booking.Id].Booking_Reference__c);
    }

    @IsTest
    static void failedJobRecoveryTouchesOnlyPendingBookingsInItsBatch() {
        Fixture pending = booking('JOB-PENDING', false);
        Fixture sent = booking('JOB-SENT', false);
        Fixture unrelated = booking('JOB-UNRELATED', true);
        update new List<Opportunity>{
            new Opportunity(Id = pending.booking.Id, NTE_Approval_Email_Status__c = 'Pending', NTE_Approval_Email_Batch__c = 'affected-batch'),
            new Opportunity(Id = sent.booking.Id, NTE_Approval_Email_Status__c = 'Sent', NTE_Approval_Email_Batch__c = 'affected-batch',
                NTE_Approval_Email_Sent_At__c = System.now(), NTE_Payment_Received__c = true),
            new Opportunity(Id = unrelated.booking.Id, NTE_Approval_Email_Status__c = 'Pending', NTE_Approval_Email_Batch__c = 'other-batch')
        };
        Test.startTest();
        NTEExhibitorApprovalEmailService.failPendingBatch('affected-batch', 'The email job failed. Retry this booking.');
        System.assertEquals('Failed', state(pending.booking.Id).NTE_Approval_Email_Status__c);
        System.assertEquals('Pending', state(unrelated.booking.Id).NTE_Approval_Email_Status__c);
        System.assertEquals('Sent', state(sent.booking.Id).NTE_Approval_Email_Status__c);
        System.assertEquals(true, state(sent.booking.Id).NTE_Payment_Received__c);
        System.assertNotEquals(null, state(sent.booking.Id).NTE_Approval_Email_Sent_At__c);
        deliver(pending);
        Test.stopTest();
        System.assertEquals('Sent', state(pending.booking.Id).NTE_Approval_Email_Status__c);
        System.assertEquals('Pending', state(unrelated.booking.Id).NTE_Approval_Email_Status__c);
        System.assertEquals(1, NTEExhibitorApprovalEmailService.acceptedDispatchCount);
    }

    private static NTE_Routing_Config__mdt validRouting() {
        return new NTE_Routing_Config__mdt(Exhibitor_Staff_Form_URL__c = 'https://forms.example.invalid/exhibitor-staff',
            Partner_Staff_Form_URL__c = 'https://forms.example.invalid/partner-staff',
            Heavy_Vehicle_Form_URL__c = 'https://forms.example.invalid/logistics',
            Logo_Update_Form_URL__c = 'https://forms.example.invalid/logo');
    }

    @IsTest
    static void storedGreetingsHandleMissingAndEscapedFirstNames() {
        Fixture fixture = booking('GREETING-FORMAT', true);
        Set<String> bookingNames = new Set<String>{'NTE_Exhibitor_Approved', 'NTE_Partner_Sponsor_Approved',
            'NTE_Complimentary_Exhibitor_Approved', 'NTE_Exhibitor_Payment_Confirmed', 'NTE_Partner_Sponsor_Payment_Confirmed'};
        Set<String> names = new Set<String>(bookingNames);
        names.addAll(new Set<String>{'NTE_Exhibitor_EOI_Acknowledgement', 'NTE_Partner_Sponsor_EOI_Acknowledgement',
            'NTE_Guest_Registration_Acknowledgement', 'Volunteer_Application_Acknowledgement'});
        List<EmailTemplate> templates = [SELECT Id, DeveloperName FROM EmailTemplate WHERE DeveloperName IN :names];
        System.assertEquals(9, templates.size());
        Test.startTest();
        for (String firstName : new List<String>{'Alex', null, 'A <b>&{x}</b> "O\'Neil"'}) {
            update new Contact(Id = fixture.primary.Id, FirstName = firstName);
            update new Lead(Id = fixture.application.Id, FirstName = firstName);
            String greeting = firstName == null ? 'Hello,' : 'Hi ' + firstName + ',';
            for (EmailTemplate templateRecord : templates) {
                Boolean bookingTemplate = bookingNames.contains(templateRecord.DeveloperName);
                Messaging.SingleEmailMessage rendered = Messaging.renderStoredEmailTemplate(templateRecord.Id,
                    bookingTemplate ? fixture.primary.Id : fixture.application.Id,
                    bookingTemplate ? fixture.booking.Id : null);
                String html = rendered.getHtmlBody();
                System.assert(NTEExhibitorApprovalEmailService.plainTextFromHtml(html).contains(greeting), templateRecord.DeveloperName);
                System.assert(rendered.getPlainTextBody().contains(greeting), 'Native text greeting: ' + templateRecord.DeveloperName);
                System.assert(!html.contains('Hi ,') && !html.contains('{!IF('));
                System.assert(!html.contains('<b>&{x}</b>'), 'Recipient markup remains escaped native field data.');
            }
        }
        System.assertEquals(0, Limits.getEmailInvocations(), 'Rendering must not send lifecycle email.');
        Test.stopTest();
    }

    @IsTest
    static void storedOptionalLeadRowsPreservePartialAndMultilineValues() {
        Fixture fixture = booking('OPTIONAL-LEAD-ROWS', false);
        Map<String, Id> templates = new Map<String, Id>();
        for (EmailTemplate templateRecord : [SELECT Id, DeveloperName FROM EmailTemplate WHERE DeveloperName IN
            ('NTE_Exhibitor_Application_Internal', 'NTE_Partner_Sponsor_Application_Internal', 'NTE_Heavy_Vehicle_Acknowledgement')]) {
            templates.put(templateRecord.DeveloperName, templateRecord.Id);
        }
        System.assertEquals(3, templates.size());
        Test.startTest();
        for (String name : templates.keySet()) {
            Messaging.SingleEmailMessage rendered = Messaging.renderStoredEmailTemplate(templates.get(name), fixture.application.Id, null);
            String text = NTEExhibitorApprovalEmailService.plainTextFromHtml(rendered.getHtmlBody());
            System.assert(!text.contains('Finance contact'), 'An absent contact has no row: ' + name);
            System.assert(!rendered.getPlainTextBody().contains('Finance contact'));
            assertNativeTextParity(text, rendered.getPlainTextBody(), 'Native HTML/text optional-row parity: ' + name);
            if (name == 'NTE_Heavy_Vehicle_Acknowledgement') {
                System.assert(!text.contains('Item 2') && !text.contains('Item 3'));
                System.assert(!rendered.getPlainTextBody().contains('Item 2') && !rendered.getPlainTextBody().contains('Item 3'));
            }
        }
        update new Lead(Id = fixture.application.Id, Invoiced_Email__c = 'finance@example.invalid',
            Heavy_Item_2_Description__c = 'Lift "A" & {literal}', Heavy_Item_2_Dimensions__c = '0',
            Heavy_Item_2_Gross_Weight__c = 'false', Haulier_Staff__c = 'Alex <b>&{x}</b>\nZoë "O\'Neil"');
        for (String name : templates.keySet()) {
            Messaging.SingleEmailMessage rendered = Messaging.renderStoredEmailTemplate(templates.get(name), fixture.application.Id, null);
            String text = NTEExhibitorApprovalEmailService.plainTextFromHtml(rendered.getHtmlBody());
            assertNativeTextParity(text, rendered.getPlainTextBody(), 'Native HTML/text partial-row parity: ' + name);
            if (name == 'NTE_Heavy_Vehicle_Acknowledgement') {
                System.assert(text.contains('Item 2 Lift "A" & {literal} - 0 - false'), 'Zero/false text is supplied information.');
                System.assert(text.contains('Alex <b>&{x}</b>\nZoë "O\'Neil"'), 'Native multiline values remain readable.');
                System.assert(!rendered.getHtmlBody().contains('<b>&{x}</b>'));
                System.assert(!text.contains('Item 3') && !text.contains(' - - '));
                System.assert(rendered.getPlainTextBody().contains('Lift "A" & {literal} - 0 - false'));
            } else {
                System.assert(text.contains('Finance contact finance@example.invalid'));
                System.assert(!text.contains('Finance contact ·') && !text.contains('finance@example.invalid ·'));
                System.assert(rendered.getPlainTextBody().contains('Finance contact finance@example.invalid'));
            }
        }
        update new Lead(Id = fixture.application.Id, Invoiced_Person__c = 'Alex & "Team"', Invoice_Contact_Phone__c = '07700 900123');
        Messaging.SingleEmailMessage populated = Messaging.renderStoredEmailTemplate(
            templates.get('NTE_Exhibitor_Application_Internal'), fixture.application.Id, null);
        System.assert(NTEExhibitorApprovalEmailService.plainTextFromHtml(populated.getHtmlBody())
            .contains('Finance contact Alex & "Team" · finance@example.invalid · 07700 900123'));
        assertNativeTextParity(NTEExhibitorApprovalEmailService.plainTextFromHtml(populated.getHtmlBody()),
            populated.getPlainTextBody(), 'Native HTML/text populated-row parity');
        System.assertEquals(0, Limits.getEmailInvocations());
        Test.stopTest();
    }

    private static void assertNativeTextParity(String htmlText, String nativeText, String context) {
        String expected = htmlText.replaceAll('\\s+', ' ').trim();
        String actual = nativeText.replaceAll('\\s+', ' ').trim();
        if (expected == actual) return;
        Integer position = 0;
        Integer commonLength = Math.min(expected.length(), actual.length());
        while (position < commonLength && expected.substring(position, position + 1) == actual.substring(position, position + 1)) position++;
        Integer start = Math.max(0, position - 50);
        System.assert(false, context + ' at character ' + position
            + '; expected ' + JSON.serialize(expected.substring(start, Math.min(expected.length(), position + 120)))
            + '; actual ' + JSON.serialize(actual.substring(start, Math.min(actual.length(), position + 120))));
    }

    @IsTest
    static void storedPartnerRowsKeepSuppliedBookingContacts() {
        Fixture fixture = booking('OPTIONAL-BOOKING-ROWS', true);
        List<EmailTemplate> templates = [SELECT Id, DeveloperName FROM EmailTemplate WHERE DeveloperName IN
            ('NTE_Partner_Sponsor_Approved', 'NTE_Partner_Sponsor_Payment_Confirmed')];
        System.assertEquals(2, templates.size());
        Test.startTest();
        for (EmailTemplate templateRecord : templates) {
            String html = Messaging.renderStoredEmailTemplate(templateRecord.Id, fixture.primary.Id, fixture.booking.Id).getHtmlBody();
            String text = NTEExhibitorApprovalEmailService.plainTextFromHtml(html);
            System.assert(text.contains('Event contact Event Day Contact · event-day@example.invalid'));
            System.assert(!text.contains('Finance contact'));
        }
        update new Opportunity(Id = fixture.booking.Id, NTE_Event_Contact_Name__c = null,
            NTE_Event_Contact_Email__c = null, NTE_Invoiced_Person__c = 'Accounts & "Team"');
        for (EmailTemplate templateRecord : templates) {
            Messaging.SingleEmailMessage rendered = Messaging.renderStoredEmailTemplate(templateRecord.Id, fixture.primary.Id, fixture.booking.Id);
            String text = NTEExhibitorApprovalEmailService.plainTextFromHtml(rendered.getHtmlBody());
            System.assert(!text.contains('Event contact'));
            System.assert(text.contains('Finance contact Accounts & "Team"'));
            System.assert(!text.contains('Accounts & "Team" ·'));
            System.assert(!rendered.getPlainTextBody().contains('Event contact'));
            System.assert(rendered.getPlainTextBody().contains('Finance contact Accounts & "Team"'));
        }
        System.assertEquals(0, Limits.getEmailInvocations());
        Test.stopTest();
    }

    @IsTest
    static void literalTemplateSyntaxAndHtmlLookingNamesRemainRecipientText() {
        Fixture fixture = booking('LITERAL-TEXT', true);
        update new Account(Id = fixture.booking.AccountId, Name = 'Harbour {NTE_PREPARATION_LINKS} & Sons');
        update new Contact(Id = fixture.primary.Id, FirstName = 'Alex <img src=x>',
            LastName = 'O\'Neil <!--NTE_TOKEN:{NTE_PAYMENT_NOTE}-->');
        update new Opportunity(Id = fixture.booking.Id,
            NTE_Invoice_Additional_Information__c = 'Keep {!literal}\n</td><a href="https://text.example.invalid">Billing & collections</a>');
        Test.startTest();
        deliver(fixture);
        Test.stopTest();
        System.assertEquals('Sent', state(fixture.booking.Id).NTE_Approval_Email_Status__c,
            'Ordinary record text that resembles a template token is not an unresolved field.');
        String html = NTEExhibitorApprovalEmailService.htmlByOpportunityId.get(fixture.booking.Id);
        System.assert(html.contains('Harbour {NTE_PREPARATION_LINKS} &amp; Sons'));
        System.assert(!html.contains('<img src=x>'), 'Native Contact merge values must remain text, not HTML.');
        String text = NTEExhibitorApprovalEmailService.plainTextFromHtml(html);
        System.assert(text.contains('Alex <img src=x>'));
        System.assert(text.contains('O\'Neil <!--NTE_TOKEN:{NTE_PAYMENT_NOTE}-->'));
        System.assert(text.contains('Keep {!literal}'));
        System.assert(text.contains('</td><a href="https://text.example.invalid">Billing & collections</a>'));
        System.assert(!html.contains('<a href="https://text.example.invalid">'), 'Native multiline merge content must remain text.');
        System.assert(!html.contains('<!--NTE_TOKEN:'));
    }

    @IsTest
    static void moreThanOneQueuePageDrainsEveryExplicitBookingExactlyOnce() {
        Fixture seed = booking('PAGE-0', false);
        List<Lead> applications = new List<Lead>();
        List<Opportunity> bookings = new List<Opportunity>();
        for (Integer index = 1; index < 41; index++) {
            Lead application = seed.application.clone(false, false, false, false);
            application.Company = 'Cedar Works ' + index;
            application.LastName = 'Cedar ' + index;
            application.Email = 'page-' + index + '@example.invalid';
            application.Booking_Reference__c = 'NTE-APPROVAL-PAGE-' + index;
            applications.add(application);
            Opportunity booking = seed.booking.clone(false, false, false, false);
            booking.Name = application.Company + ' Booking';
            booking.Booking_Reference__c = application.Booking_Reference__c;
            bookings.add(booking);
        }
        insert applications;
        insert bookings;
        List<OpportunityContactRole> roles = new List<OpportunityContactRole>();
        List<NTEExhibitorApprovalEmailService.Request> requests = new List<NTEExhibitorApprovalEmailService.Request>{seed.request()};
        Set<Id> bookingIds = new Set<Id>{seed.booking.Id};
        for (Integer index = 0; index < bookings.size(); index++) {
            roles.add(new OpportunityContactRole(OpportunityId = bookings[index].Id, ContactId = seed.primary.Id, IsPrimary = true));
            NTEExhibitorApprovalEmailService.Request request = new NTEExhibitorApprovalEmailService.Request();
            request.leadId = applications[index].Id; request.opportunityId = bookings[index].Id;
            requests.add(request); bookingIds.add(bookings[index].Id);
        }
        insert roles;
        Test.startTest();
        NTEExhibitorApprovalEmailService.processRequests(requests);
        System.assertEquals(40, [SELECT COUNT() FROM Opportunity WHERE Id IN :bookingIds AND NTE_Approval_Email_Status__c = 'Sent']);
        System.assertEquals(1, [SELECT COUNT() FROM Opportunity WHERE Id IN :bookingIds AND NTE_Approval_Email_Status__c = 'Pending']);
        String batchKey = [SELECT NTE_Approval_Email_Batch__c FROM Opportunity WHERE Id = :seed.booking.Id].NTE_Approval_Email_Batch__c;
        NTEExhibitorApprovalEmailService.processPendingBatch(batchKey, true, true);
        NTEExhibitorApprovalEmailService.processPendingBatch(batchKey, true, true);
        Test.stopTest();
        System.assertEquals(41, NTEExhibitorApprovalEmailService.acceptedDispatchCount);
        System.assertEquals(41, [SELECT COUNT() FROM Task WHERE WhatId IN :bookingIds AND Subject = 'NTE booking provisional email - sent']);
        System.assertEquals(0, [SELECT COUNT() FROM Opportunity WHERE Id IN :bookingIds AND NTE_Approval_Email_Status__c = 'Pending']);
    }

    @IsTest
    static void salesforceAcceptsContactAndOpportunityTemplate() {
        Fixture fixture = booking('RENDER', false);
        NTEExhibitorApprovalEmailService.bypassEmailDelivery = false;
        Test.startTest();
        deliver(fixture);
        System.assertEquals(1, Limits.getEmailInvocations());
        Test.stopTest();
        Opportunity result = state(fixture.booking.Id);
        System.assertEquals('Sent', result.NTE_Approval_Email_Status__c, 'Provisional email error: ' + result.NTE_Approval_Email_Error__c);
    }

    @IsTest
    static void emptyRequestsAndAlreadySentRetryDoNotEnqueue() {
        Fixture fixture = booking('NO-REPEAT', false);
        fixture.booking.NTE_Approval_Email_Status__c = 'Sent';
        Database.update(fixture.booking, AccessLevel.SYSTEM_MODE);
        Test.startTest();
        NTEExhibitorApprovalEmailService.sendApprovalConfirmation(null);
        NTEExhibitorApprovalEmailService.sendApprovalConfirmation(new List<NTEExhibitorApprovalEmailService.Request>{null});
        Boolean rejected = false;
        try { NTEExhibitorApprovalEmailService.retryApprovalEmail(fixture.booking.Id); }
        catch (AuraHandledException expected) { rejected = true; }
        System.assert(rejected);
        System.assertEquals(0, Limits.getQueueableJobs());
        Test.stopTest();
    }

    private static Fixture booking(String suffix, Boolean partner) {
        NTEInboundLeadService.bypassEmailDelivery = true;
        NTEExhibitorApprovalEmailService.bypassEmailDelivery = true;
        NTEExhibitorApprovalEmailService.allowUnconvertedLeadForTests = true;
        Fixture fixture = new Fixture();
        String formType = partner ? 'Partner / Sponsor Application' : 'Exhibitor Application';
        fixture.application = new Lead(
            FirstName = 'Applicant', LastName = suffix, Company = 'NTE Synthetic ' + suffix,
            Email = 'applicant-' + suffix + '@example.invalid', Web_Form_Type__c = formType,
            NTE_Event_Code__c = 'NTE2099', Booking_Reference__c = 'NTE-APPROVAL-' + suffix,
            Planned_Exhibitor_Count__c = '2', Total_Staff_Count__c = 2, Stand_Power__c = 'No',
            Exhibitor_Space_Selections__c = partner ? null : 'Single Garage - Track Side - £799 + VAT',
            Exhibitor_Organisation_Category__c = partner ? null : 'CIC or Not for Profit',
            Sponsor_Package__c = partner ? 'Champion Partner' : null
        );
        Database.insert(fixture.application, AccessLevel.SYSTEM_MODE);
        Account organisation = new Account(Name = fixture.application.Company);
        Database.insert(organisation, AccessLevel.SYSTEM_MODE);
        fixture.primary = new Contact(
            FirstName = 'Primary', LastName = suffix, AccountId = organisation.Id,
            Email = 'primary-' + suffix + '@example.invalid'
        );
        Database.insert(fixture.primary, AccessLevel.SYSTEM_MODE);
        String stage = [SELECT MasterLabel FROM OpportunityStage WHERE IsActive = true ORDER BY SortOrder LIMIT 1].MasterLabel;
        fixture.booking = new Opportunity(
            Name = organisation.Name + ' Booking', AccountId = organisation.Id, StageName = stage,
            CloseDate = Date.today().addDays(30), NTE_Source_Form_Type__c = formType,
            NTE_Event_Code__c = 'NTE2099', Booking_Reference__c = fixture.application.Booking_Reference__c,
            NTE_Event_Contact_Name__c = 'Event Day Contact', NTE_Event_Contact_Email__c = 'event-day@example.invalid',
            NTE_Exhibitor_Space_Selections__c = fixture.application.Exhibitor_Space_Selections__c,
            NTE_Exhibitor_Organisation_Category__c = fixture.application.Exhibitor_Organisation_Category__c,
            NTE_Sponsor_Package__c = fixture.application.Sponsor_Package__c,
            NTE_Sponsor_Package_Total__c = partner ? 2000 : 0, NTE_Exhibitor_Space_Price__c = partner ? 0 : 800,
            NTE_Listed_Price_Total__c = partner ? 2000 : 800, Amount = partner ? 2400 : 960,
            NTE_Total_Staff_Count__c = 2, NTE_Initial_Staff_Count__c = 2, NTE_Included_Staff_Count__c = 2,
            NTE_Heavy_Vehicle_Required__c = 'Yes', NTE_Pricing_Status__c = 'Calculated',
            NTE_Payment_Method__c = 'Bank transfer', NTE_Invoice_Required__c = 'Yes'
        );
        Database.insert(fixture.booking, AccessLevel.SYSTEM_MODE);
        Database.insert(new OpportunityContactRole(
            OpportunityId = fixture.booking.Id, ContactId = fixture.primary.Id, IsPrimary = true
        ), AccessLevel.SYSTEM_MODE);
        return fixture;
    }
    private static void deliver(Fixture fixture) {
        NTEExhibitorApprovalEmailService.processRequests(new List<NTEExhibitorApprovalEmailService.Request>{fixture.request()});
    }
    private static Opportunity state(Id bookingId) {
        return [SELECT NTE_Approval_Email_Status__c, NTE_Approval_Email_Error__c, NTE_Approval_Email_Sent_At__c,
            NTE_Approval_Email_Recipient__c, NTE_Quote_Provided__c, NTE_Invoice_Provided__c, NTE_Payment_Received__c
            FROM Opportunity WHERE Id = :bookingId];
    }
    private static Integer auditCount(Id bookingId) {
        return [SELECT COUNT() FROM Task WHERE WhatId = :bookingId AND Subject LIKE 'NTE booking provisional email%'];
    }
}
