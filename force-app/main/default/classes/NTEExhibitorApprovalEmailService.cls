public without sharing class NTEExhibitorApprovalEmailService {
    private static final Integer EMAIL_BATCH_SIZE = 10;
    private static final Integer QUEUE_PAGE_SIZE = 40;
    private static final String EXHIBITOR_FORM_TYPE = 'Exhibitor Application';
    private static final String PARTNER_FORM_TYPE = 'Partner / Sponsor Application';
    private static final Set<String> APPLICATION_TYPES = new Set<String>{EXHIBITOR_FORM_TYPE, PARTNER_FORM_TYPE};
    private static final String TASK_PREFIX = 'NTE booking provisional email - ';
    private static final Set<String> LEGACY_SENT_SUBJECTS = new Set<String>{
        'NTE exhibitor approval confirmation - sending', 'NTE exhibitor approval confirmation - sent'
    };
    @TestVisible private static Boolean bypassEmailDelivery = false;
    @TestVisible private static Boolean skipProcessing = false;
    @TestVisible private static Boolean allowUnconvertedLeadForTests = false;
    // One transaction token coalesces Flow invocations without searching unrelated conversions.
    @TestVisible private static Boolean approvalSweepQueued = false;
    @TestVisible private static Integer approvalSweepEnqueueCount = 0;
    @TestVisible private static Integer acceptedDispatchCount = 0;
    @TestVisible private static Map<Id, String> selectedTemplateByOpportunityId = new Map<Id, String>();
    @TestVisible private static Map<Id, String> recipientByOpportunityId = new Map<Id, String>();
    @TestVisible private static Map<Id, String> htmlByOpportunityId = new Map<Id, String>();
    @TestVisible private static Boolean simulateSendFailure = false;
    @TestVisible private static Boolean simulateQueueFailure = false;
    private static String transactionBatchKey;
    private static Set<Id> queuedInTransaction = new Set<Id>();

    public class Request {
        @InvocableVariable(required=true label='Converted Lead ID') public Id leadId;
        @InvocableVariable(required=true label='Converted Opportunity ID') public Id opportunityId;
    }
    public class ApprovalRetryResult {
        @AuraEnabled public Integer queuedCount;
        @AuraEnabled public String message;
    }
    private class Candidate {
        Opportunity booking;
        Contact recipient;
        String templateName;
        Task audit;
        Messaging.SingleEmailMessage message;
    }

    @InvocableMethod(label='Queue NTE Provisional Booking Email'
        description='Queues the explicitly converted exhibitor or partner/sponsor bookings for their primary Contact after commit.')
    public static void sendApprovalConfirmation(List<Request> requests) {
        if (skipProcessing) return;
        List<Request> freshRequests = new List<Request>();
        if (requests != null) {
            for (Request request : requests) {
                if (request != null && !queuedInTransaction.contains(request.opportunityId)) freshRequests.add(request);
            }
        }
        Set<Id> queuedIds = saveRequests(freshRequests);
        queuedInTransaction.addAll(queuedIds);
        if (queuedIds.isEmpty() || approvalSweepQueued) return;
        if (Limits.getQueueableJobs() >= Limits.getLimitQueueableJobs()) {
            failPendingBatch(transactionBatchKey, 'The email could not be queued. Retry the provisional email from the booking.');
            return;
        }
        try {
            if (simulateQueueFailure && Test.isRunningTest()) throw new ApprovalEmailException('The email job could not be scheduled.');
            System.enqueueJob(new ApprovalQueueable(transactionBatchKey, bypassEmailDelivery, allowUnconvertedLeadForTests));
            approvalSweepQueued = true;
            approvalSweepEnqueueCount++;
        } catch (Exception exceptionValue) {
            failPendingBatch(transactionBatchKey, 'The email could not be queued: ' + exceptionValue.getMessage());
        }
    }

    @AuraEnabled
    public static ApprovalRetryResult retryApprovalEmail(Id opportunityId) {
        if (opportunityId == null || opportunityId.getSObjectType() != Opportunity.SObjectType
            || !Schema.sObjectType.Opportunity.isUpdateable()) {
            throw new AuraHandledException('Select an NTE booking you can update.');
        }
        Opportunity booking = [
            SELECT Id, NTE_Source_Form_Type__c, NTE_Approval_Email_Status__c
            FROM Opportunity WHERE Id = :opportunityId WITH USER_MODE FOR UPDATE
        ];
        if (!APPLICATION_TYPES.contains(booking.NTE_Source_Form_Type__c)) {
            throw new AuraHandledException('Only NTE application bookings can receive this email.');
        }
        if (booking.NTE_Approval_Email_Status__c == 'Sent' || booking.NTE_Approval_Email_Status__c == 'Pending') {
            throw new AuraHandledException('This email has already been sent or is waiting to send.');
        }
        List<Lead> sourceLeads = [
            SELECT Id FROM Lead WHERE IsConverted = true AND ConvertedOpportunityId = :opportunityId
            AND Web_Form_Type__c IN :APPLICATION_TYPES ORDER BY ConvertedDate DESC, Id DESC LIMIT 2
        ];
        if (sourceLeads.size() != 1) {
            throw new AuraHandledException('A single converted application could not be matched to this booking.');
        }
        Request request = new Request();
        request.leadId = sourceLeads[0].Id;
        request.opportunityId = booking.Id;
        sendApprovalConfirmation(new List<Request>{request});
        Opportunity outcome = [SELECT NTE_Approval_Email_Status__c, NTE_Approval_Email_Error__c
            FROM Opportunity WHERE Id = :opportunityId WITH USER_MODE];
        ApprovalRetryResult result = new ApprovalRetryResult();
        result.queuedCount = outcome.NTE_Approval_Email_Status__c == 'Pending' ? 1 : 0;
        result.message = result.queuedCount == 1 ? 'Email queued.'
            : String.isBlank(outcome.NTE_Approval_Email_Error__c) ? 'The email could not be queued. Check the booking email status.'
            : outcome.NTE_Approval_Email_Error__c;
        return result;
    }

    private static Set<Id> saveRequests(List<Request> requests) {
        Map<Id, Id> leadIdsByBooking = requestMap(requests);
        Set<Id> queuedIds = new Set<Id>();
        if (leadIdsByBooking.isEmpty()) return queuedIds;
        if (transactionBatchKey == null) transactionBatchKey = EncodingUtil.convertToHex(Crypto.generateAesKey(128));
        List<Opportunity> bookings = [
            SELECT Id, NTE_Source_Form_Type__c, NTE_Approval_Email_Status__c
            FROM Opportunity WHERE Id IN :leadIdsByBooking.keySet() FOR UPDATE
        ];
        Set<Id> legacySentIds = new Set<Id>();
        for (Task audit : [
            SELECT WhatId FROM Task WHERE WhatId IN :leadIdsByBooking.keySet() AND Subject IN :LEGACY_SENT_SUBJECTS
        ]) legacySentIds.add(audit.WhatId);
        List<Opportunity> updates = new List<Opportunity>();
        for (Opportunity booking : bookings) {
            if (!APPLICATION_TYPES.contains(booking.NTE_Source_Form_Type__c)
                || booking.NTE_Approval_Email_Status__c == 'Sent'
                || booking.NTE_Approval_Email_Status__c == 'Pending'
                || legacySentIds.contains(booking.Id)) continue;
            updates.add(new Opportunity(
                Id = booking.Id, NTE_Approval_Email_Status__c = 'Pending',
                NTE_Approval_Email_Batch__c = transactionBatchKey,
                NTE_Approval_Email_Lead_Id__c = String.valueOf(leadIdsByBooking.get(booking.Id)),
                NTE_Approval_Email_Requested_At__c = System.now(),
                NTE_Approval_Email_Requested_By__c = UserInfo.getName(),
                NTE_Approval_Email_Recipient__c = null, NTE_Approval_Email_Error__c = null
            ));
            queuedIds.add(booking.Id);
        }
        if (!updates.isEmpty()) Database.update(updates, true, AccessLevel.SYSTEM_MODE);
        return queuedIds;
    }

    private class ApprovalQueueable implements Queueable {
        private String batchKey;
        private Boolean bypassDelivery;
        private Boolean allowTestLead;
        ApprovalQueueable(String key, Boolean bypass, Boolean allowLead) {
            batchKey = key; bypassDelivery = bypass; allowTestLead = allowLead;
        }
        public void execute(QueueableContext context) {
            System.attachFinalizer(new ApprovalFinalizer(batchKey));
            if (NTEStripeBookingService.prepareProvisionalBatch(batchKey, bypassDelivery, allowTestLead)) return;
            processPendingBatch(batchKey, bypassDelivery, allowTestLead);
            if ([SELECT COUNT() FROM Opportunity WHERE NTE_Approval_Email_Batch__c = :batchKey
                AND NTE_Approval_Email_Status__c = 'Pending'] > 0) {
                if (Limits.getQueueableJobs() < Limits.getLimitQueueableJobs()) {
                    System.enqueueJob(new ApprovalQueueable(batchKey, bypassDelivery, allowTestLead));
                } else {
                    failPendingBatch(batchKey, 'The remaining emails could not be queued. Retry the affected bookings.');
                }
            }
        }
    }
    public static void resumeAfterStripe(String batchKey, Boolean bypassDelivery, Boolean allowTestLead) {
        System.enqueueJob(new ApprovalQueueable(batchKey, bypassDelivery, allowTestLead));
    }
    public static void finishStripeBooking(Id paymentRequestId, String batchKey, Boolean bypassDelivery, Boolean allowTestLead) {
        NTE_Payment_Request__c payment = [SELECT Opportunity__c FROM NTE_Payment_Request__c WHERE Id = :paymentRequestId];
        processPendingBatch(batchKey, bypassDelivery, allowTestLead, new Set<Id>{payment.Opportunity__c});
    }
    private class ApprovalFinalizer implements Finalizer {
        private String batchKey;
        ApprovalFinalizer(String key) { batchKey = key; }
        public void execute(FinalizerContext context) {
            if (context.getResult() == ParentJobResult.SUCCESS) return;
            Exception failure = context.getException();
            failPendingBatch(batchKey, 'The email job failed. '
                + (failure == null ? 'Retry the affected bookings.' : failure.getMessage()));
        }
    }
    @TestVisible
    private static void processRequests(List<Request> requests) {
        if (saveRequests(requests).isEmpty()) return;
        processPendingBatch(transactionBatchKey, bypassEmailDelivery, allowUnconvertedLeadForTests);
    }

    @TestVisible
    private static void processPendingBatch(String batchKey, Boolean bypassDelivery, Boolean allowTestLead) {
        processPendingBatch(batchKey, bypassDelivery, allowTestLead, null);
    }
    private static void processPendingBatch(String batchKey, Boolean bypassDelivery, Boolean allowTestLead, Set<Id> onlyBookingIds) {
        if (onlyBookingIds == null) onlyBookingIds = new Map<Id, Opportunity>([SELECT Id FROM Opportunity
            WHERE NTE_Approval_Email_Batch__c = :batchKey AND NTE_Approval_Email_Status__c = 'Pending' LIMIT :QUEUE_PAGE_SIZE]).keySet();
        List<Opportunity> bookings = [
            SELECT Id, Name, OwnerId, Account.Name, Booking_Reference__c, Amount, StageName,
                NTE_Source_Form_Type__c, NTE_Event_Code__c, NTE_Payment_Method__c, NTE_Payment_Received__c,
                NTE_Quote_Required_for_PO__c, NTE_Pricing_Status__c,
                NTE_Exhibitor_Space_Selections__c, NTE_Exhibitor_Organisation_Category__c,
                NTE_Sponsor_Package__c, NTE_Sponsor_Package_Total__c, NTE_Exhibitor_Space_Price__c,
                NTE_Power_Socket_Count__c, NTE_Power_Socket_Unit_Price__c, NTE_Power_Socket_Total__c,
                NTE_Additional_Staff_Count__c, NTE_Additional_Staff_Unit_Price__c, NTE_Additional_Staff_Total__c,
                NTE_Listed_Price_Total__c, NTE_Heavy_Vehicle_Required__c,
                NTE_Approval_Email_Status__c, NTE_Approval_Email_Lead_Id__c,
                NTE_Approval_Email_Requested_At__c, NTE_Approval_Email_Requested_By__c
            FROM Opportunity WHERE NTE_Approval_Email_Batch__c = :batchKey
            AND NTE_Approval_Email_Status__c = 'Pending' AND Id IN :onlyBookingIds
            LIMIT :QUEUE_PAGE_SIZE FOR UPDATE
        ];
        if (bookings.isEmpty()) return;
        Set<Id> bookingIds = new Map<Id, Opportunity>(bookings).keySet();
        Set<Id> leadIds = new Set<Id>();
        for (Opportunity booking : bookings) {
            try { leadIds.add(Id.valueOf(booking.NTE_Approval_Email_Lead_Id__c)); }
            catch (Exception invalidReference) { /* Report the unmatched application below. */ }
        }
        Map<Id, Lead> leads = new Map<Id, Lead>([
            SELECT Id, IsConverted, ConvertedOpportunityId, Web_Form_Type__c FROM Lead WHERE Id IN :leadIds
        ]);
        Map<Id, Contact> contacts = NTEBookingContactService.primaryContacts(bookingIds, AccessLevel.SYSTEM_MODE, true);
        NTEStripeBookingService.preloadEmailRequests(bookingIds);
        Set<String> templateNames = new Set<String>{
            'NTE_Exhibitor_Approved', 'NTE_Complimentary_Exhibitor_Approved', 'NTE_Partner_Sponsor_Approved'
        };
        Map<String, Id> templateIds = new Map<String, Id>();
        for (EmailTemplate templateRecord : [SELECT Id, DeveloperName FROM EmailTemplate WHERE DeveloperName IN :templateNames]) {
            templateIds.put(templateRecord.DeveloperName, templateRecord.Id);
        }
        NTE_Routing_Config__mdt routing = NTE_Routing_Config__mdt.getInstance('Default');
        String closedStatus = [SELECT MasterLabel FROM TaskStatus WHERE IsClosed = true ORDER BY SortOrder LIMIT 1].MasterLabel;
        List<Candidate> candidates = new List<Candidate>();
        List<Opportunity> failedUpdates = new List<Opportunity>();
        List<Task> failureAudits = new List<Task>();
        for (Opportunity booking : bookings) {
            Contact contactRecord = contacts.get(booking.Id);
            String errorMessage;
            Lead sourceLead;
            try { sourceLead = leads.get(Id.valueOf(booking.NTE_Approval_Email_Lead_Id__c)); }
            catch (Exception invalidReference) { sourceLead = null; }
            if (!APPLICATION_TYPES.contains(booking.NTE_Source_Form_Type__c) || sourceLead == null
                || sourceLead.Web_Form_Type__c != booking.NTE_Source_Form_Type__c
                || ((!sourceLead.IsConverted || sourceLead.ConvertedOpportunityId != booking.Id) && !allowTestLead)) {
                errorMessage = 'The converted application could not be matched to this booking.';
            } else if (contactRecord == null || String.isBlank(contactRecord.Email)) {
                errorMessage = 'A primary Contact with an email address is required. No email was sent.';
            } else if (String.isBlank(booking.NTE_Event_Code__c) || String.isBlank(booking.Booking_Reference__c)) {
                errorMessage = 'The event code and booking reference are required before this email can be sent.';
            } else if (!validBookingReference(booking.Booking_Reference__c)) {
                errorMessage = 'The booking reference is not valid for the preparation forms. Correct it before retrying this email.';
            } else {
                errorMessage = preparationConfigurationError(booking, routing);
            }
            if (errorMessage == null) errorMessage = savedPriceError(booking);
            if (errorMessage == null) errorMessage = NTEStripeBookingService.emailReadinessError(booking, contactRecord);
            String templateName = templateFor(booking);
            if (errorMessage == null && !templateIds.containsKey(templateName)) errorMessage = 'The provisional booking email template was not found.';
            if (errorMessage == null) {
                try {
                    Candidate candidate = new Candidate();
                    candidate.booking = booking;
                    candidate.recipient = contactRecord;
                    candidate.templateName = templateName;
                    candidate.message = renderBookingEmail(booking, contactRecord, templateIds.get(templateName), routing, false);
                    candidate.audit = auditFor(booking, closedStatus, 'sending', contactRecord.Email, templateName, null);
                    candidates.add(candidate);
                    selectedTemplateByOpportunityId.put(booking.Id, templateName);
                    recipientByOpportunityId.put(booking.Id, contactRecord.Email);
                    htmlByOpportunityId.put(booking.Id, candidate.message.getHtmlBody());
                } catch (Exception renderFailure) {
                    errorMessage = 'The email could not be prepared: ' + renderFailure.getMessage();
                }
            }
            if (errorMessage != null) {
                failedUpdates.add(failedUpdate(booking.Id, errorMessage));
                failureAudits.add(auditFor(booking, closedStatus, 'failed', contactRecord == null ? null : contactRecord.Email, templateName, errorMessage));
            }
        }
        if (!failedUpdates.isEmpty()) Database.update(failedUpdates, true, AccessLevel.SYSTEM_MODE);
        if (!failureAudits.isEmpty()) Database.insert(failureAudits, true, AccessLevel.SYSTEM_MODE);
        if (candidates.isEmpty()) return;
        List<Task> pendingAudits = new List<Task>();
        for (Candidate candidate : candidates) pendingAudits.add(candidate.audit);
        Database.insert(pendingAudits, true, AccessLevel.SYSTEM_MODE);
        for (Integer startIndex = 0; startIndex < candidates.size(); startIndex += EMAIL_BATCH_SIZE) {
            Integer endIndex = Math.min(startIndex + EMAIL_BATCH_SIZE, candidates.size());
            List<Messaging.SingleEmailMessage> messages = new List<Messaging.SingleEmailMessage>();
            for (Integer index = startIndex; index < endIndex; index++) messages.add(candidates[index].message);
            List<Messaging.SendEmailResult> results;
            String batchError;
            if (!bypassDelivery) {
                try { results = Messaging.sendEmail(messages, false); }
                catch (Exception sendFailure) { batchError = sendFailure.getMessage(); }
            }
            List<Opportunity> updates = new List<Opportunity>();
            List<NTE_Payment_Request__c> paymentUpdates = new List<NTE_Payment_Request__c>();
            List<Task> audits = new List<Task>();
            for (Integer index = startIndex; index < endIndex; index++) {
                Candidate candidate = candidates[index];
                Boolean accepted = bypassDelivery && !simulateSendFailure;
                String errorMessage = simulateSendFailure ? 'The email was not accepted for delivery.' : batchError;
                if (!bypassDelivery && batchError == null) {
                    Messaging.SendEmailResult result = results[index - startIndex];
                    accepted = result.isSuccess();
                    if (!accepted) errorMessage = result.getErrors().isEmpty() ? 'Salesforce did not accept the email.' : result.getErrors()[0].getMessage();
                }
                updates.add(new Opportunity(
                    Id = candidate.booking.Id, NTE_Approval_Email_Status__c = accepted ? 'Sent' : 'Failed',
                    NTE_Approval_Email_Recipient__c = candidate.recipient.Email,
                    NTE_Approval_Email_Error__c = accepted ? null : truncate(errorMessage),
                    NTE_Approval_Email_Sent_At__c = accepted ? System.now() : null
                ));
                if (accepted) NTEStripeBookingService.recordEmailAccepted(candidate.booking, updates[updates.size() - 1], candidate.recipient, paymentUpdates);
                candidate.audit.Subject = TASK_PREFIX + (accepted ? 'sent' : 'failed');
                candidate.audit.Description += accepted ? '\nSalesforce accepted the email for delivery.' : '\n' + truncate(errorMessage);
                audits.add(candidate.audit);
                if (accepted) acceptedDispatchCount++;
            }
            // A failed status/audit write aborts the job; the finalizer reports failure after rollback.
            Database.update(updates, true, AccessLevel.SYSTEM_MODE);
            Database.update(audits, true, AccessLevel.SYSTEM_MODE);
            if (!paymentUpdates.isEmpty()) Database.update(paymentUpdates, true, AccessLevel.SYSTEM_MODE);
        }
    }

    public static Messaging.SingleEmailMessage renderBookingEmail(Opportunity booking, Contact recipient, Id templateId,
        NTE_Routing_Config__mdt routing, Boolean paymentConfirmation) {
        Messaging.SingleEmailMessage rendered = Messaging.renderStoredEmailTemplate(templateId, recipient.Id, booking.Id);
        Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
        message.setSubject(rendered.getSubject());
        String html = rendered.getHtmlBody();
        if (String.isBlank(html)) throw new ApprovalEmailException('The HTML email template is empty.');
        NTE_Payment_Request__c stripePayment = NTEStripeBookingService.paymentForEmail(booking.Id);
        if (paymentConfirmation && stripePayment != null && stripePayment.Net_Minor__c / 100 != amount(booking)) {
            throw new ApprovalEmailException('The booking amount differs from its saved Stripe request. Review the charge before sending confirmation.');
        }
        Map<String, String> replacements = new Map<String, String>{
            '{NTE_EVENT_LABEL}' => escape(booking.NTE_Event_Code__c),
            '{NTE_ORGANISATION}' => escape(booking.Account == null ? booking.Name : booking.Account.Name),
            '{NTE_FINANCE_SUMMARY}' => financeSummary(booking, stripePayment, paymentConfirmation)
                + (paymentConfirmation || stripePayment == null ? '' : stripePaymentButton(stripePayment)),
            '{NTE_PREPARATION_LINKS}' => preparationLinks(booking, routing)
        };
        if (!paymentConfirmation) replacements.put('{NTE_PAYMENT_NOTE}', escape(paymentNote(booking, stripePayment)));
        if (booking.NTE_Source_Form_Type__c == PARTNER_FORM_TYPE && !paymentConfirmation) {
            replacements.put('{NTE_AGREEMENT_NOTE}', stripePayment == null
                ? 'Your partnership / sponsorship agreement will be sent to you shortly for signing, along with a quotation or invoice as requested.'
                : 'Your partnership / sponsorship agreement will be sent to you shortly for signing.');
        }
        html = replaceTemplateMarkers(html, replacements);
        message.setHtmlBody(html);
        message.setPlainTextBody(plainTextFromHtml(html));
        message.setTargetObjectId(recipient.Id);
        message.setTreatTargetObjectAsRecipient(false);
        message.setToAddresses(new List<String>{recipient.Email});
        message.setWhatId(booking.Id);
        message.setSaveAsActivity(false);
        return message;
    }
    private static String replaceTemplateMarkers(String html, Map<String, String> replacements) {
        Matcher tokens = Pattern.compile('<!--NTE_TOKEN:(\\{NTE_[A-Z_]+\\})-->').matcher(html);
        String result = '';
        Integer copiedThrough = 0;
        Set<String> resolved = new Set<String>();
        while (tokens.find()) {
            String token = tokens.group(1);
            if (!replacements.containsKey(token)) throw new ApprovalEmailException('The email contains an unresolved template field.');
            result += html.substring(copiedThrough, tokens.start()) + replacements.get(token);
            resolved.add(token);
            copiedThrough = tokens.end();
        }
        result += html.substring(copiedThrough);
        if (!resolved.containsAll(replacements.keySet()) || result.contains('<!--NTE_TOKEN:')) {
            throw new ApprovalEmailException('The email contains a missing or unresolved template field.');
        }
        return result;
    }
    @TestVisible
    private static String plainTextFromHtml(String html) {
        String text = html.replaceAll('(?is)<head\\b.*?</head>', '')
            .replaceAll('(?is)<style\\b.*?</style>', '')
            .replaceAll('(?is)<script\\b.*?</script>', '')
            .replaceAll('(?is)<div\\b[^>]*class="preheader"[^>]*>.*?</div>', '')
            .replaceAll('(?is)<a\\b[^>]*>\\s*<img\\b[^>]*>\\s*</a>', '')
            .replaceAll('(?is)<a[^>]*href="([^"]+)"[^>]*>(.*?)</a>', '$2 ($1)')
            .replaceAll('(?i)<li\\b[^>]*>', '\n• ')
            .replaceAll('(?i)[\\r\\n]+[ \\t]*(?=<br\\s*/?>)', '')
            .replaceAll('(?i)<br\\s*/?>|</tr>|</li>', '\n')
            .replaceAll('(?i)</p>|</h[1-6]>|</div>|</ul>|</ol>|</table>', '\n\n')
            .replaceAll('(?i)</td>', '  ')
            .replaceAll('<[^>]+>', '').unescapeHtml4().replace('\u00a0', ' ')
            .replace('\r\n', '\n').replace('\r', '\n')
            .replaceAll('[ \t]+', ' ').replaceAll(' *\n *', '\n')
            .replaceAll('\n{3,}', '\n\n').trim();
        return text;
    }
    private static String templateFor(Opportunity booking) {
        if (booking.NTE_Source_Form_Type__c == PARTNER_FORM_TYPE) return 'NTE_Partner_Sponsor_Approved';
        return isEligibleComplimentaryBooking(booking) && amount(booking) == 0
            ? 'NTE_Complimentary_Exhibitor_Approved' : 'NTE_Exhibitor_Approved';
    }
    public static String savedPriceError(Opportunity booking) {
        Decimal total = booking.NTE_Listed_Price_Total__c;
        if ((!String.isBlank(booking.NTE_Pricing_Status__c) && booking.NTE_Pricing_Status__c != 'Calculated')
            || total == null || total < 0 || (booking.Amount != null && booking.Amount != total)
            || valueOrZero(booking.NTE_Sponsor_Package_Total__c) < 0
            || valueOrZero(booking.NTE_Exhibitor_Space_Price__c) < 0
            || valueOrZero(booking.NTE_Power_Socket_Total__c) < 0
            || valueOrZero(booking.NTE_Additional_Staff_Total__c) < 0
            || !validLineItem(booking.NTE_Power_Socket_Count__c, booking.NTE_Power_Socket_Unit_Price__c, booking.NTE_Power_Socket_Total__c)
            || !validLineItem(booking.NTE_Additional_Staff_Count__c, booking.NTE_Additional_Staff_Unit_Price__c, booking.NTE_Additional_Staff_Total__c)
            || (booking.NTE_Source_Form_Type__c == EXHIBITOR_FORM_TYPE && valueOrZero(booking.NTE_Sponsor_Package_Total__c) != 0)
            || (booking.NTE_Source_Form_Type__c == PARTNER_FORM_TYPE && valueOrZero(booking.NTE_Exhibitor_Space_Price__c) != 0)
            || componentTotal(booking) != total
            || (total == 0 && (booking.NTE_Pricing_Status__c != 'Calculated' || !isEligibleComplimentaryBooking(booking)))) {
            return 'The booking price needs review. No provisional email was sent. Check the selected package or space and its saved charges.';
        }
        return null;
    }
    private static Boolean validLineItem(String quantity, Decimal unitPrice, Decimal total) {
        Decimal count;
        try { count = String.isBlank(quantity) ? null : Decimal.valueOf(quantity.trim()); }
        catch (Exception invalidQuantity) { return false; }
        return validLineItem(count, unitPrice, total);
    }
    private static Boolean validLineItem(Decimal quantity, Decimal unitPrice, Decimal total) {
        if ((quantity != null && (quantity < 0 || quantity != quantity.setScale(0)))
            || (unitPrice != null && unitPrice < 0)) return false;
        if (quantity == null || quantity == 0) return valueOrZero(total) == 0;
        return unitPrice != null && total != null && quantity * unitPrice == total;
    }
    public static String paymentConfirmationError(Opportunity booking, NTE_Routing_Config__mdt routing) {
        if (booking == null || !booking.NTE_Payment_Received__c || !booking.NTE_Invoice_Provided__c
            || booking.NTE_Listed_Price_Total__c == null || booking.NTE_Listed_Price_Total__c <= 0) {
            return 'Record the booking invoice and booking payment before sending a space confirmation.';
        }
        if (!validBookingReference(booking.Booking_Reference__c)) {
            return 'The booking reference is not valid for the preparation forms. Correct it before retrying this email.';
        }
        String priceError = savedPriceError(booking);
        if (priceError != null) return priceError.replace('No provisional email was sent.', 'No booking confirmation was sent.');
        return preparationConfigurationError(booking, routing);
    }

    private static String paymentNote(Opportunity booking, NTE_Payment_Request__c payment) {
        if (isEligibleComplimentaryBooking(booking) && amount(booking) == 0) {
            return 'Your booking is complimentary and your space is confirmed. No payment is due.';
        }
        if (payment != null) return 'Your space is provisionally reserved. Please use the secure payment link below. Your space will be confirmed by the NTE Team.';
        return 'Your space is provisionally reserved. The NTE team will send your quotation or invoice with payment instructions. Your space will be confirmed when payment is recorded.';
    }
    private static String financeSummary(Opportunity booking, NTE_Payment_Request__c payment, Boolean paymentConfirmation) {
        String rows = booking.NTE_Source_Form_Type__c == PARTNER_FORM_TYPE
            ? moneyRow('Partner / sponsor package', booking.NTE_Sponsor_Package_Total__c)
            : moneyRow('Exhibition space', booking.NTE_Exhibitor_Space_Price__c);
        if (valueOrZero(booking.NTE_Power_Socket_Total__c) > 0) rows += moneyRow(quantityLabel('Power sockets', booking.NTE_Power_Socket_Count__c, booking.NTE_Power_Socket_Unit_Price__c), booking.NTE_Power_Socket_Total__c);
        if (valueOrZero(booking.NTE_Additional_Staff_Total__c) > 0) rows += moneyRow(quantityLabel('Additional staff places', booking.NTE_Additional_Staff_Count__c, booking.NTE_Additional_Staff_Unit_Price__c), booking.NTE_Additional_Staff_Total__c);
        rows += moneyRow(paymentConfirmation && payment == null ? 'Total paid · excluding VAT' : 'Booking total · excluding VAT', amount(booking));
        if (payment != null) {
            rows += moneyRow('VAT (' + String.valueOf(payment.Tax_Rate__c.setScale(2)) + '%)', (payment.Amount_Minor__c - payment.Net_Minor__c) / 100);
            rows += moneyRow(paymentConfirmation ? 'Total paid' : 'Total payable', payment.Amount_Minor__c / 100);
        }
        return '<table role="presentation" width="100%" cellspacing="0" cellpadding="0" border="0" style="width:100%;border:1px solid #dce7ed;border-radius:10px;overflow:hidden;">' + rows + '</table>';
    }
    private static String stripePaymentButton(NTE_Payment_Request__c payment) {
        if (!NTEStripeClient.validTestUrl(payment.Payment_URL__c)) throw new ApprovalEmailException('The Stripe payment link is not ready.');
        return '<table data-nte-payment-button="true" role="presentation" align="center" width="100%" cellspacing="0" cellpadding="0" border="0" style="width:100%;max-width:420px;margin:26px auto 10px;"><tr><td align="center" bgcolor="#0b668f" style="background-color:#0b668f;border-radius:10px;"><a href="' + escape(payment.Payment_URL__c) + '" aria-label="Pay Now with Stripe" style="display:block;padding:19px 20px;border-radius:10px;color:#ffffff;text-decoration:none;font-family:Arial,sans-serif;font-size:0;line-height:28px;text-align:left;"><span style="display:inline-block;width:56%;vertical-align:middle;font-size:21px;font-weight:bold;line-height:28px;">Pay Now </span><span style="display:inline-block;width:44%;vertical-align:middle;text-align:right;"><span style="display:inline-block;padding-left:14px;border-left:1px solid #b8d9e8;font-size:17px;font-weight:bold;line-height:26px;white-space:nowrap;"><img src="https://stevostar1234.github.io/nte27-web-to-lead-demo/assets/stripe-icon.png?v=20260909-1" width="22" height="22" alt="" role="presentation" style="display:inline-block;width:22px;height:22px;margin-right:7px;border:0;border-radius:4px;vertical-align:middle;">Stripe</span></span></a></td></tr></table>';
    }
    private static Decimal componentTotal(Opportunity booking) {
        return valueOrZero(booking.NTE_Sponsor_Package_Total__c) + valueOrZero(booking.NTE_Exhibitor_Space_Price__c)
            + valueOrZero(booking.NTE_Power_Socket_Total__c) + valueOrZero(booking.NTE_Additional_Staff_Total__c);
    }
    @TestVisible
    public static String preparationConfigurationError(Opportunity booking, NTE_Routing_Config__mdt routing) {
        if (routing == null || !validUrl(staffUrl(booking, routing)) || !validUrl(routing.Logo_Update_Form_URL__c)
            || (needsVehicleLink(booking) && !validUrl(routing.Heavy_Vehicle_Form_URL__c))) {
            return 'A staff, logo or applicable heavy-vehicle form URL is missing or invalid.';
        }
        return null;
    }
    private static String preparationLinks(Opportunity booking, NTE_Routing_Config__mdt routing) {
        String colour = booking.NTE_Source_Form_Type__c == PARTNER_FORM_TYPE ? '#0b668f'
            : isEligibleComplimentaryBooking(booking) && amount(booking) == 0 ? '#176f66' : '#856624';
        Integer columnCount = needsVehicleLink(booking) ? 3 : 2;
        String html = '<table role="presentation" width="100%" cellspacing="0" cellpadding="0" border="0" style="width:100%;table-layout:fixed;"><tr>'
            + button('Provide staff details', staffUrl(booking, routing), colour, columnCount)
            + button('Upload your logo', routing.Logo_Update_Form_URL__c, colour, columnCount);
        if (needsVehicleLink(booking)) html += button('Vehicle details', routing.Heavy_Vehicle_Form_URL__c, colour, columnCount);
        return html + '</tr></table>';
    }
    private static String staffUrl(Opportunity booking, NTE_Routing_Config__mdt routing) {
        if (routing == null) return null;
        return booking.NTE_Source_Form_Type__c == PARTNER_FORM_TYPE ? routing.Partner_Staff_Form_URL__c : routing.Exhibitor_Staff_Form_URL__c;
    }
    private static Boolean needsVehicleLink(Opportunity booking) { return booking.NTE_Heavy_Vehicle_Required__c != 'No'; }
    private static Boolean validUrl(String value) {
        if (String.isBlank(value) || value.length() > 255 || Pattern.compile('[\\s\\p{Cntrl}]').matcher(value).find()) return false;
        try {
            Url link = new Url(value);
            return link.getProtocol().toLowerCase() == 'https'
                && String.isNotBlank(link.getHost()) && String.isBlank(link.getUserInfo());
        } catch (Exception invalidLink) { return false; }
    }
    private static Boolean validBookingReference(String value) {
        return String.isNotBlank(value) && Pattern.matches('(?i)^NTE-[A-Z0-9][A-Z0-9-]{1,74}[A-Z0-9]$', value.trim());
    }
    private static String button(String label, String url, String colour, Integer columnCount) {
        return '<td class="action-column" width="' + (columnCount == 3 ? '33.33%' : '50%')
            + '" valign="top" style="padding:0 4px 8px;"><table role="presentation" width="100%" cellspacing="0" cellpadding="0" border="0"><tr>'
            + '<td align="center" bgcolor="' + colour + '" style="background-color:' + colour + ';border-radius:7px;">'
            + '<a class="email-button" href="' + escape(url) + '" style="display:block;padding:14px 10px;background-color:'
            + colour + ';color:#ffffff;text-decoration:none;border-radius:7px;font-size:14px;line-height:21px;font-weight:bold;">'
            + escape(label) + '</a></td></tr></table></td>';
    }
    private static String quantityLabel(String label, String quantity, Decimal unitPrice) {
        Decimal count;
        try { count = String.isBlank(quantity) ? null : Decimal.valueOf(quantity.trim()); }
        catch (Exception invalidQuantity) { return label; }
        return quantityLabel(label, count, unitPrice);
    }
    private static String quantityLabel(String label, Decimal quantity, Decimal unitPrice) {
        return quantity != null && quantity > 0 && unitPrice != null && unitPrice >= 0
            ? label + ' · ' + String.valueOf(quantity.intValue()) + ' × £' + money(unitPrice) : label;
    }
    private static String moneyRow(String label, Decimal value) {
        return '<tr><td style="padding:12px 18px;border-bottom:1px solid #e4edf2;">' + escape(label)
            + '</td><td align="right" style="padding:12px 18px;border-bottom:1px solid #e4edf2;white-space:nowrap;">£' + money(value) + '</td></tr>';
    }
    private static Decimal amount(Opportunity booking) { return booking.NTE_Listed_Price_Total__c; }
    private static Decimal valueOrZero(Decimal value) { return value == null ? 0 : value; }
    private static String money(Decimal value) { return String.valueOf(valueOrZero(value).setScale(2)); }
    private static String escape(String value) { return value == null ? '' : value.escapeHtml4(); }
    private static Map<Id, Id> requestMap(List<Request> requests) {
        Map<Id, Id> result = new Map<Id, Id>();
        if (requests == null) return result;
        for (Request request : requests) {
            if (request != null && request.leadId != null && request.opportunityId != null
                && request.leadId.getSObjectType() == Lead.SObjectType
                && request.opportunityId.getSObjectType() == Opportunity.SObjectType) result.put(request.opportunityId, request.leadId);
        }
        return result;
    }
    private static Opportunity failedUpdate(Id bookingId, String errorMessage) {
        return new Opportunity(Id = bookingId, NTE_Approval_Email_Status__c = 'Failed', NTE_Approval_Email_Error__c = truncate(errorMessage));
    }
    @TestVisible
    private static void failPendingBatch(String batchKey, String errorMessage) {
        if (String.isBlank(batchKey)) return;
        List<Opportunity> failures = new List<Opportunity>();
        for (Opportunity booking : [SELECT Id FROM Opportunity WHERE NTE_Approval_Email_Batch__c = :batchKey
            AND NTE_Approval_Email_Status__c = 'Pending' FOR UPDATE]) failures.add(failedUpdate(booking.Id, errorMessage));
        if (!failures.isEmpty()) Database.update(failures, true, AccessLevel.SYSTEM_MODE);
    }
    private static Task auditFor(Opportunity booking, String status, String outcome, String recipient, String templateName, String errorMessage) {
        return new Task(WhatId = booking.Id, OwnerId = booking.OwnerId, Status = status, ActivityDate = Date.today(),
            Subject = TASK_PREFIX + outcome,
            Description = 'Recipient: ' + (recipient == null ? 'No usable primary Contact email' : recipient)
                + '\nEvent: ' + booking.NTE_Event_Code__c + '\nBooking reference: ' + booking.Booking_Reference__c
                + '\nTemplate: ' + templateName + '\nRequested by: ' + booking.NTE_Approval_Email_Requested_By__c
                + '\nRequested at: ' + String.valueOf(booking.NTE_Approval_Email_Requested_At__c)
                + (errorMessage == null ? '' : '\n' + truncate(errorMessage)));
    }
    @TestVisible
    private static Boolean isEligibleComplimentaryBooking(Opportunity booking) {
        return booking != null && booking.NTE_Source_Form_Type__c == EXHIBITOR_FORM_TYPE
            && ((booking.NTE_Exhibitor_Space_Selections__c == 'COBSEO Charity - Single - Free'
                && booking.NTE_Exhibitor_Organisation_Category__c == 'Charity - member of Cobseo')
            || (booking.NTE_Exhibitor_Space_Selections__c == 'Non COBSEO Charity - Single - Free'
                && booking.NTE_Exhibitor_Organisation_Category__c == 'Charity - not a member of Cobseo'));
    }
    private static String truncate(String value) {
        if (String.isBlank(value)) return 'An unexpected email error occurred.';
        return value.length() > 30000 ? value.substring(0, 30000) : value;
    }
    private class ApprovalEmailException extends Exception {}
}
