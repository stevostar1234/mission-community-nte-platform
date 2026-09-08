public with sharing class NTEEmailDispatchService {
    private static final Integer MAX_RECIPIENTS = 500;
    private static final Integer MAX_REQUEST_JSON_LENGTH = 300000;
    private static final Integer PAGE_SIZE = 40;
    private static final Set<String> KINDS = new Set<String>{'INVITATION', 'STAFF_DUE', 'HEAVY_DUE', 'LOGO_DUE', 'FINAL_PACK', 'BOOKING_CONFIRMED'};
    private static final Set<String> INTEREST_TYPES = new Set<String>{'Exhibitor Expression of Interest', 'Partner / Sponsor Expression of Interest'};
    private static final Set<String> APPLICATION_TYPES = new Set<String>{'Exhibitor Application', 'Partner / Sponsor Application'};
    private static final Set<String> TOKENS = new Set<String>{'ContactName', 'Organisation', 'BookingReference', 'EventCode', 'UpdateLink', 'ApplicationLink', 'FinalPackLink'};
    @TestVisible private static Boolean bypassEmailDelivery = false;
    @TestVisible private static Boolean skipEnqueue = false;
    @TestVisible private static Boolean simulateEnqueueFailure = false;
    @TestVisible private static Set<Id> simulatedFailures = new Set<Id>();
    @TestVisible private static NTE_Routing_Config__mdt routingOverride;
    @TestVisible private static Map<Id, String> renderedHtml = new Map<Id, String>();
    @TestVisible private static Map<Id, String> renderedText = new Map<Id, String>();
    @TestVisible private static Map<String, Id> confirmationTemplateOverride;

    public class Selection {
        @AuraEnabled public Id recordId;
        @AuraEnabled public String fingerprint;
    }
    public class DraftRequest {
        @AuraEnabled public String kind;
        @AuraEnabled public String runId;
        @AuraEnabled public String subject;
        @AuraEnabled public String messageBody;
        @AuraEnabled public List<Selection> recipients;
    }
    public class RecipientDTO {
        @AuraEnabled public Id recordId;
        @AuraEnabled public String name;
        @AuraEnabled public String company;
        @AuraEnabled public String email;
        @AuraEnabled public String reference;
        @AuraEnabled public String eventCode;
        @AuraEnabled public String link;
        @AuraEnabled public Boolean eligible;
        @AuraEnabled public String issue;
        @AuraEnabled public String fingerprint;
        @AuraEnabled public Datetime lastSentAt;
        @AuraEnabled public String previewHtml;
        private Id contactId;
        private String sourceType;
        private Opportunity booking;
        private Contact primaryContact;
        private String bookingSnapshot;
    }
    public class DraftDTO {
        @AuraEnabled public String kind;
        @AuraEnabled public String runId;
        @AuraEnabled public String title;
        @AuraEnabled public String subject;
        @AuraEnabled public String messageBody;
        @AuraEnabled public String previewHtml;
        @AuraEnabled public List<RecipientDTO> recipients;
        @AuraEnabled public Integer recipientCount;
        @AuraEnabled public Integer skippedCount;
        @AuraEnabled public Integer recipientLimit;
        @AuraEnabled public Boolean canSend;
    }
    public class QueueResponse {
        @AuraEnabled public Integer queuedCount;
        @AuraEnabled public Integer skippedCount;
        @AuraEnabled public String message;
    }
    public class HistoryDTO {
        @AuraEnabled public Id dispatchId;
        @AuraEnabled public Id recordId;
        @AuraEnabled public String kind;
        @AuraEnabled public String recipient;
        @AuraEnabled public String status;
        @AuraEnabled public String subject;
        @AuraEnabled public Datetime sentAt;
        @AuraEnabled public Datetime createdAt;
        @AuraEnabled public String error;
        @AuraEnabled public String runId;
        @AuraEnabled public Boolean canRetry;
    }

    @AuraEnabled
    public static DraftDTO buildDraft(String kind, List<Id> recordIds) {
        String selectedKind = normalizeKind(kind);
        if (selectedKind == 'BOOKING_CONFIRMED') throw handled('Booking confirmations are sent when booking payment is recorded.');
        List<Id> selectedIds = validateIds(recordIds, selectedKind);
        DraftDTO draft = new DraftDTO();
        draft.kind = selectedKind;
        draft.runId = EncodingUtil.convertToHex(Crypto.generateAesKey(128));
        draft.title = titleFor(selectedKind);
        draft.subject = subjectFor(selectedKind);
        draft.messageBody = bodyFor(selectedKind);
        draft.recipients = loadRecipients(selectedKind, selectedIds, false, new Set<Id>());
        draft.recipientCount = 0;
        draft.skippedCount = 0;
        draft.recipientLimit = MAX_RECIPIENTS;
        for (RecipientDTO recipient : draft.recipients) {
            if (recipient.eligible) {
                draft.recipientCount++;
                if (draft.previewHtml == null) draft.previewHtml = htmlFor(selectedKind, draft.subject, draft.messageBody, recipient);
            } else draft.skippedCount++;
        }
        draft.canSend = draft.recipientCount > 0;
        return draft;
    }

    @AuraEnabled
    public static String previewMessageJson(String requestJson, Id recordId) {
        return previewMessage(parseRequestJson(requestJson), recordId);
    }

    @AuraEnabled
    public static String queueMessagesJson(String requestJson) {
        return JSON.serialize(queueMessages(parseRequestJson(requestJson)));
    }

    public static String previewMessage(DraftRequest request, Id recordId) {
        Map<Id, String> fingerprints = validateRequest(request);
        if (!fingerprints.containsKey(recordId)) throw handled('Select a recipient from this draft.');
        RecipientDTO recipient = loadRecipients(request.kind, new List<Id>{recordId}, false, new Set<Id>())[0];
        if (!recipient.eligible || recipient.fingerprint != fingerprints.get(recordId)) {
            throw handled('This recipient or booking has changed. Refresh the recipient list before sending.');
        }
        String contentIssue = personalisedContentIssue(request.subject, request.messageBody, recipient);
        if (contentIssue != null) throw handled(contentIssue);
        return htmlFor(request.kind, request.subject.trim(), request.messageBody.trim(), recipient);
    }

    public static QueueResponse queueMessages(DraftRequest request) {
        Map<Id, String> fingerprints = validateRequest(request);
        List<Id> recordIds = new List<Id>(fingerprints.keySet());
        List<RecipientDTO> recipients = loadRecipients(request.kind, recordIds, true, new Set<Id>());
        Set<String> keys = new Set<String>();
        for (Id recordId : recordIds) keys.add(dispatchKey(request.kind, request.runId, recordId));
        Set<String> existingKeys = new Set<String>();
        for (NTE_Email_Dispatch__c existing : [SELECT Dispatch_Key__c FROM NTE_Email_Dispatch__c
            WHERE Dispatch_Key__c IN :keys WITH USER_MODE]) existingKeys.add(existing.Dispatch_Key__c);
        List<RecipientDTO> sendable = new List<RecipientDTO>();
        Integer skipped = 0;
        for (RecipientDTO recipient : recipients) {
            String key = dispatchKey(request.kind, request.runId, recipient.recordId);
            if (!recipient.eligible || recipient.fingerprint != fingerprints.get(recipient.recordId)
                || existingKeys.contains(key)) {
                skipped++;
                continue;
            }
            sendable.add(recipient);
        }
        validateQueueSize(request, sendable);
        List<NTE_Email_Dispatch__c> dispatches = new List<NTE_Email_Dispatch__c>();
        for (RecipientDTO recipient : sendable) dispatches.add(dispatchForRequest(request, recipient));
        if (!dispatches.isEmpty()) {
            Database.insert(dispatches, true, AccessLevel.USER_MODE);
            updateSourceStatuses(dispatches, AccessLevel.USER_MODE);
            enqueue(new List<Id>(new Map<Id, NTE_Email_Dispatch__c>(dispatches).keySet()));
        }
        return resultFor(dispatches.size(), skipped);
    }

    private static NTE_Email_Dispatch__c dispatchForRequest(DraftRequest request, RecipientDTO recipient) {
        return new NTE_Email_Dispatch__c(
            Kind__c = request.kind, Lead__c = request.kind == 'INVITATION' ? recipient.recordId : null,
            Opportunity__c = request.kind == 'INVITATION' ? null : recipient.recordId,
            Contact__c = recipient.contactId, Recipient__c = recipient.email, Event_Code__c = recipient.eventCode,
            Status__c = 'Queued', Subject__c = request.subject.trim(), Message__c = request.messageBody.trim(),
            Link__c = recipient.link, Run_Id__c = request.runId,
            Dispatch_Key__c = dispatchKey(request.kind, request.runId, recipient.recordId),
            Fingerprint__c = recipient.fingerprint
        );
    }

    private static void validateQueueSize(DraftRequest request, List<RecipientDTO> recipients) {
        if (recipients.isEmpty()) return;
        Integer availableBytes = Limits.getLimitHeapSize() - Limits.getHeapSize();
        // Reserve two UTF-16-sized representations: retained dispatch text and its write buffer.
        // JSON includes field names/envelope overhead. This deliberately avoids relying on String
        // interning or undocumented DML allocation behaviour. Probe only one recipient at a time.
        Integer bytesPerCharacter = 4;
        String subject = request.subject.trim();
        String messageBody = request.messageBody.trim();
        Integer minimumBytes = bytesPerCharacter * recipients.size() * (subject.length() + messageBody.length());
        String issue = 'This message is too large for the selected recipient list. Shorten the message or select fewer recipients.';
        if (minimumBytes > availableBytes) throw handled(issue);
        Integer estimatedBytes = 0;
        for (RecipientDTO recipient : recipients) {
            String contentIssue = personalisedContentIssue(subject, messageBody, recipient);
            if (contentIssue != null) throw handled(contentIssue);
            NTE_Email_Dispatch__c probe = dispatchForRequest(request, recipient);
            Integer rawCharacters = JSON.serialize(probe).length();
            probe.Subject__c = personalise(subject, recipient);
            probe.Message__c = personalise(messageBody, recipient);
            Integer personalisedCharacters = JSON.serialize(probe).length();
            Integer escapedCharacters = personalisedCharacters
                + escape(probe.Subject__c).length() - probe.Subject__c.length()
                + escape(probe.Message__c).length() - probe.Message__c.length();
            estimatedBytes += bytesPerCharacter * Math.max(rawCharacters, Math.max(personalisedCharacters, escapedCharacters));
            if (estimatedBytes > availableBytes) throw handled(issue);
        }
        if (Test.isRunningTest()) System.debug(LoggingLevel.INFO,
            'NTE dispatch size check: recipients=' + recipients.size() + ', estimatedBytes=' + estimatedBytes
            + ', availableBytes=' + availableBytes + ', heapAfterCheck=' + Limits.getHeapSize());
    }

    // Called only after the panel has recorded the booking-payment transition. The unique
    // booking key survives retries and later staff top-ups; notification failure never changes payment.
    public static QueueResponse queueBookingConfirmation(Id opportunityId) {
        List<Id> ids = validateIds(new List<Id>{opportunityId}, 'BOOKING_CONFIRMED');
        RecipientDTO recipient = loadRecipients('BOOKING_CONFIRMED', ids, true, new Set<Id>())[0];
        String key = dispatchKey('BOOKING_CONFIRMED', 'BOOKING_PAYMENT', opportunityId);
        List<NTE_Email_Dispatch__c> existing = [SELECT Id FROM NTE_Email_Dispatch__c
            WHERE Dispatch_Key__c = :key WITH USER_MODE LIMIT 1];
        if (!existing.isEmpty()) return resultFor(0, 1);
        NTE_Email_Dispatch__c dispatch = new NTE_Email_Dispatch__c(
            Kind__c = 'BOOKING_CONFIRMED', Opportunity__c = opportunityId,
            Contact__c = recipient.contactId, Recipient__c = recipient.email, Event_Code__c = recipient.eventCode,
            Status__c = recipient.eligible ? 'Queued' : 'Failed', Error__c = recipient.issue,
            Subject__c = 'Your NTE booking is confirmed', Message__c = 'Booking payment received.',
            Run_Id__c = 'BOOKING_PAYMENT', Dispatch_Key__c = key, Fingerprint__c = recipient.fingerprint
        );
        Database.insert(dispatch, AccessLevel.USER_MODE);
        if (!recipient.eligible) {
            QueueResponse failed = resultFor(0, 0);
            failed.message = 'Booking payment recorded. The confirmation email needs attention in NTE Email Failures.';
            return failed;
        }
        try {
            enqueue(new List<Id>{dispatch.Id});
        } catch (Exception queueFailure) {
            failQueued(new List<Id>{dispatch.Id}, 'The confirmation could not be queued. Retry this email. ' + queueFailure.getMessage());
            QueueResponse failed = resultFor(0, 0);
            failed.message = 'Booking payment recorded. The confirmation email could not be queued; retry it from NTE Email Failures.';
            return failed;
        }
        return resultFor(1, 0);
    }

    @AuraEnabled
    public static QueueResponse retryDispatch(Id dispatchId) {
        QueueResponse result = retryFailed(new List<Id>{dispatchId});
        if (result.queuedCount == 0) result.message = 'Email not queued. Check the Send Error on this email record.';
        return result;
    }

    @AuraEnabled
    public static List<HistoryDTO> recentDispatches(List<Id> recordIds) {
        Set<Id> ids = new Set<Id>(validateIds(recordIds, null));
        List<HistoryDTO> history = new List<HistoryDTO>();
        for (NTE_Email_Dispatch__c dispatch : [SELECT Id, Lead__c, Opportunity__c, Kind__c, Recipient__c,
            Status__c, Subject__c, Sent_At__c, CreatedDate, Error__c, Run_Id__c FROM NTE_Email_Dispatch__c
            WHERE Lead__c IN :ids OR Opportunity__c IN :ids WITH USER_MODE ORDER BY CreatedDate DESC LIMIT 1000]) {
            HistoryDTO item = new HistoryDTO();
            item.dispatchId = dispatch.Id;
            item.recordId = targetId(dispatch);
            item.kind = dispatch.Kind__c;
            item.recipient = dispatch.Recipient__c;
            item.status = dispatch.Status__c;
            item.subject = dispatch.Subject__c;
            item.sentAt = dispatch.Sent_At__c;
            item.createdAt = dispatch.CreatedDate;
            item.error = dispatch.Error__c;
            item.runId = dispatch.Run_Id__c;
            item.canRetry = dispatch.Status__c == 'Failed';
            history.add(item);
        }
        return history;
    }

    @AuraEnabled
    public static QueueResponse retryFailed(List<Id> dispatchIds) {
        if (dispatchIds == null || dispatchIds.isEmpty() || dispatchIds.size() > MAX_RECIPIENTS) {
            throw handled('Select between 1 and 500 failed emails to retry.');
        }
        Set<Id> ids = new Set<Id>();
        for (Id dispatchId : dispatchIds) {
            if (dispatchId == null || dispatchId.getSObjectType() != NTE_Email_Dispatch__c.SObjectType) {
                throw handled('Select failed emails from the email history.');
            }
            ids.add(dispatchId);
        }
        List<NTE_Email_Dispatch__c> failed = [SELECT Id, Kind__c, Lead__c, Opportunity__c, Contact__c,
            Recipient__c, Event_Code__c, Status__c, Fingerprint__c, Link__c, Sent_At__c, Error__c
            FROM NTE_Email_Dispatch__c WHERE Id IN :ids WITH USER_MODE FOR UPDATE];
        Map<String, List<Id>> idsByKind = new Map<String, List<Id>>();
        for (NTE_Email_Dispatch__c dispatch : failed) {
            if (dispatch.Status__c != 'Failed') continue;
            if (!idsByKind.containsKey(dispatch.Kind__c)) idsByKind.put(dispatch.Kind__c, new List<Id>());
            idsByKind.get(dispatch.Kind__c).add(targetId(dispatch));
        }
        Map<String, Map<Id, RecipientDTO>> recipientsByKind = new Map<String, Map<Id, RecipientDTO>>();
        for (String kind : idsByKind.keySet()) {
            recipientsByKind.put(kind, recipientMap(loadRecipients(kind, idsByKind.get(kind), true, new Set<Id>())));
        }
        List<Id> queuedIds = new List<Id>();
        List<NTE_Email_Dispatch__c> updates = new List<NTE_Email_Dispatch__c>();
        Set<String> queuedTargets = new Set<String>();
        for (NTE_Email_Dispatch__c dispatch : failed) {
            if (dispatch.Status__c != 'Failed') continue;
            RecipientDTO recipient = recipientsByKind.get(dispatch.Kind__c).get(targetId(dispatch));
            String targetKey = dispatch.Kind__c + '|' + String.valueOf(targetId(dispatch));
            if (queuedTargets.contains(targetKey)) {
                dispatch.Status__c = 'Skipped';
                dispatch.Error__c = 'Another failed email of this kind has already been selected for this recipient.';
            } else if (recipient == null || !recipient.eligible
                || (dispatch.Kind__c != 'BOOKING_CONFIRMED' && !sameRecipient(dispatch, recipient))) {
                dispatch.Status__c = dispatch.Kind__c == 'BOOKING_CONFIRMED' ? 'Failed' : 'Skipped';
                dispatch.Error__c = recipient != null && !recipient.eligible ? recipient.issue
                    : 'The recipient, booking or link has changed. Prepare a new draft.';
            } else {
                if (dispatch.Kind__c == 'BOOKING_CONFIRMED') {
                    dispatch.Contact__c = recipient.contactId;
                    dispatch.Recipient__c = recipient.email;
                    dispatch.Event_Code__c = recipient.eventCode;
                    dispatch.Fingerprint__c = recipient.fingerprint;
                }
                dispatch.Status__c = 'Queued';
                dispatch.Error__c = null;
                queuedIds.add(dispatch.Id);
                queuedTargets.add(targetKey);
            }
            updates.add(dispatch);
        }
        if (!updates.isEmpty()) {
            Database.update(updates, true, AccessLevel.USER_MODE);
            updateSourceStatuses(updates, AccessLevel.USER_MODE);
        }
        if (!queuedIds.isEmpty()) {
            try { enqueue(queuedIds); }
            catch (Exception queueFailure) {
                failQueued(queuedIds, 'The email could not be queued. Retry this email. ' + queueFailure.getMessage());
                throw handled('The email could not be queued. Its failed status has been retained.');
            }
        }
        return resultFor(queuedIds.size(), ids.size() - queuedIds.size());
    }

    private static void enqueue(List<Id> dispatchIds) {
        if (Test.isRunningTest() && simulateEnqueueFailure) throw handled('The email job could not be queued.');
        if (skipEnqueue && Test.isRunningTest()) return;
        if (Limits.getQueueableJobs() >= Limits.getLimitQueueableJobs()) {
            throw handled('The email could not be queued in this transaction. Retry this email.');
        }
        System.enqueueJob(new DispatchQueueable(dispatchIds, bypassEmailDelivery && Test.isRunningTest()));
    }
    private class DispatchQueueable implements Queueable {
        private List<Id> ids;
        private Boolean bypass;
        DispatchQueueable(List<Id> dispatchIds, Boolean bypassDelivery) { ids = dispatchIds; bypass = bypassDelivery; }
        public void execute(QueueableContext context) {
            System.attachFinalizer(new DispatchFinalizer(ids));
            List<Id> page = new List<Id>();
            List<Id> remaining = new List<Id>();
            for (Integer index = 0; index < ids.size(); index++) {
                if (index < PAGE_SIZE) page.add(ids[index]);
                else remaining.add(ids[index]);
            }
            processQueued(page, bypass);
            if (!remaining.isEmpty()) System.enqueueJob(new DispatchQueueable(remaining, bypass));
        }
    }
    private class DispatchFinalizer implements Finalizer {
        private List<Id> ids;
        DispatchFinalizer(List<Id> dispatchIds) { ids = dispatchIds; }
        public void execute(FinalizerContext context) {
            if (context.getResult() == ParentJobResult.SUCCESS) return;
            Exception failure = context.getException();
            failQueued(ids, 'The email job failed. '
                + (failure == null ? 'Retry the failed emails from the email history.' : failure.getMessage()));
        }
    }

    @TestVisible
    private static void processQueued(List<Id> dispatchIds, Boolean bypassDelivery) {
        if (dispatchIds.size() > PAGE_SIZE) throw handled('This email page exceeds the processing limit.');
        List<NTE_Email_Dispatch__c> dispatches = [SELECT Id, Kind__c, Lead__c, Opportunity__c, Contact__c,
            Recipient__c, Event_Code__c, Status__c, Subject__c, Message__c, Link__c, Fingerprint__c,
            Sent_At__c, Error__c FROM NTE_Email_Dispatch__c
            WHERE Id IN :dispatchIds AND Status__c = 'Queued' WITH USER_MODE FOR UPDATE];
        if (dispatches.isEmpty()) return;
        Set<Id> ownIds = new Map<Id, NTE_Email_Dispatch__c>(dispatches).keySet();
        Map<String, List<Id>> idsByKind = new Map<String, List<Id>>();
        for (NTE_Email_Dispatch__c dispatch : dispatches) {
            if (!idsByKind.containsKey(dispatch.Kind__c)) idsByKind.put(dispatch.Kind__c, new List<Id>());
            idsByKind.get(dispatch.Kind__c).add(targetId(dispatch));
        }
        Map<String, Map<Id, RecipientDTO>> recipientsByKind = new Map<String, Map<Id, RecipientDTO>>();
        for (String kind : idsByKind.keySet()) {
            recipientsByKind.put(kind, recipientMap(loadRecipients(kind, idsByKind.get(kind), true, ownIds)));
        }
        Map<String, Id> confirmationTemplateIds = new Map<String, Id>();
        if (idsByKind.containsKey('BOOKING_CONFIRMED')) {
            NTEStripeBookingService.preloadEmailRequests(new Set<Id>(idsByKind.get('BOOKING_CONFIRMED')));
            Set<String> templateNames = new Set<String>{'NTE_Exhibitor_Payment_Confirmed', 'NTE_Partner_Sponsor_Payment_Confirmed'};
            for (EmailTemplate emailTemplate : [SELECT Id, DeveloperName FROM EmailTemplate WHERE DeveloperName IN :templateNames]) {
                confirmationTemplateIds.put(emailTemplate.DeveloperName, emailTemplate.Id);
            }
        }
        if (Test.isRunningTest() && confirmationTemplateOverride != null) confirmationTemplateIds = confirmationTemplateOverride;
        List<NTE_Email_Dispatch__c> sendable = new List<NTE_Email_Dispatch__c>();
        List<Messaging.SingleEmailMessage> messages = new List<Messaging.SingleEmailMessage>();
        Set<String> sendingTargets = new Set<String>();
        for (NTE_Email_Dispatch__c dispatch : dispatches) {
            RecipientDTO recipient = recipientsByKind.get(dispatch.Kind__c).get(targetId(dispatch));
            String targetKey = dispatch.Kind__c + '|' + String.valueOf(targetId(dispatch));
            if (sendingTargets.contains(targetKey)) {
                dispatch.Status__c = 'Skipped';
                dispatch.Error__c = 'Another email of this kind is already being processed for this recipient.';
                continue;
            }
            if (recipient == null || !recipient.eligible || !sameRecipient(dispatch, recipient)) {
                dispatch.Status__c = dispatch.Kind__c == 'BOOKING_CONFIRMED' ? 'Failed' : 'Skipped';
                dispatch.Error__c = recipient != null && !recipient.eligible ? recipient.issue
                    : 'The recipient, booking or link changed after this email was queued. No email was sent.';
                continue;
            }
            Messaging.SingleEmailMessage email;
            if (dispatch.Kind__c == 'BOOKING_CONFIRMED') {
                String templateName = recipient.sourceType == 'Partner / Sponsor Application'
                    ? 'NTE_Partner_Sponsor_Payment_Confirmed' : 'NTE_Exhibitor_Payment_Confirmed';
                try {
                    if (!confirmationTemplateIds.containsKey(templateName)) throw handled('The booking confirmation email template is missing.');
                    email = NTEExhibitorApprovalEmailService.renderBookingEmail(recipient.booking,
                        recipient.primaryContact, confirmationTemplateIds.get(templateName), configuredRouting(), true);
                    dispatch.Subject__c = email.getSubject();
                } catch (Exception renderFailure) {
                    dispatch.Status__c = 'Failed';
                    dispatch.Error__c = ('The booking confirmation could not be prepared. ' + renderFailure.getMessage()).left(32000);
                    continue;
                }
            } else {
                String contentIssue = personalisedContentIssue(dispatch.Subject__c, dispatch.Message__c, recipient);
                if (contentIssue != null) {
                    dispatch.Status__c = 'Failed';
                    dispatch.Error__c = contentIssue;
                    continue;
                }
                email = new Messaging.SingleEmailMessage();
                email.setToAddresses(new List<String>{dispatch.Recipient__c});
                email.setSubject(personalise(dispatch.Subject__c, recipient));
                String plainText = normaliseLines(personalise(dispatch.Message__c, recipient));
                if (String.isNotBlank(recipient.reference) && !plainText.contains(recipient.reference)) {
                    plainText += '\n\nBooking reference: ' + recipient.reference;
                }
                if (!plainText.contains(recipient.eventCode)) plainText += '\nEvent: ' + recipient.eventCode;
                if (!plainText.contains(recipient.link)) plainText += '\n\n' + recipient.link;
                email.setPlainTextBody(plainText + '\n\nKind regards,\nThe National Transition Event Team\nMission Community');
                email.setHtmlBody(htmlFor(dispatch.Kind__c, dispatch.Subject__c, dispatch.Message__c, recipient));
                email.setSaveAsActivity(false);
            }
            messages.add(email);
            sendable.add(dispatch);
            sendingTargets.add(targetKey);
            if (Test.isRunningTest()) {
                renderedHtml.put(targetId(dispatch), email.getHtmlBody());
                renderedText.put(targetId(dispatch), email.getPlainTextBody());
            }
        }
        for (Integer startIndex = 0; startIndex < messages.size(); startIndex += 10) {
            List<Messaging.SingleEmailMessage> batch = new List<Messaging.SingleEmailMessage>();
            Integer endIndex = Math.min(startIndex + 10, messages.size());
            for (Integer index = startIndex; index < endIndex; index++) batch.add(messages[index]);
            List<Messaging.SendEmailResult> outcomes;
            String batchError;
            if (!(bypassDelivery && Test.isRunningTest())) {
                try { outcomes = Messaging.sendEmail(batch, false); }
                catch (Exception sendFailure) { batchError = sendFailure.getMessage(); }
            }
            for (Integer index = startIndex; index < endIndex; index++) {
                NTE_Email_Dispatch__c dispatch = sendable[index];
                Boolean sent = batchError == null && (outcomes == null ? !simulatedFailures.contains(targetId(dispatch))
                    : outcomes[index - startIndex].isSuccess());
                dispatch.Status__c = sent ? 'Sent' : 'Failed';
                if (sent) {
                    dispatch.Sent_At__c = System.now();
                    dispatch.Error__c = null;
                } else {
                    dispatch.Error__c = batchError != null ? batchError.left(32000) : outcomes == null ? 'Simulated delivery failure.'
                        : emailError(outcomes[index - startIndex]);
                }
            }
        }
        Database.update(dispatches, true, AccessLevel.USER_MODE);
        updateSourceStatuses(dispatches, AccessLevel.USER_MODE);
    }

    private static void failQueued(List<Id> dispatchIds, String error) {
        List<NTE_Email_Dispatch__c> failed = [SELECT Id, Kind__c, Lead__c, Opportunity__c, Recipient__c,
            Status__c, Sent_At__c FROM NTE_Email_Dispatch__c
            WHERE Id IN :dispatchIds AND Status__c = 'Queued' FOR UPDATE];
        for (NTE_Email_Dispatch__c dispatch : failed) {
            dispatch.Status__c = 'Failed';
            dispatch.Error__c = error == null ? 'The email job failed.' : error.left(32000);
        }
        if (!failed.isEmpty()) {
            Database.update(failed, true, AccessLevel.SYSTEM_MODE);
            updateSourceStatuses(failed, AccessLevel.SYSTEM_MODE);
        }
    }

    private static List<RecipientDTO> loadRecipients(String kind, List<Id> recordIds, Boolean lockRecords,
        Set<Id> allowedQueuedIds) {
        kind = normalizeKind(kind);
        Map<Id, RecipientDTO> recipients = new Map<Id, RecipientDTO>();
        Set<Id> ids = new Set<Id>(recordIds);
        NTE_Routing_Config__mdt routing = configuredRouting();
        Map<String, Object> binds = new Map<String, Object>{'ids' => ids};
        if (kind == 'INVITATION') {
            for (Lead interest : (List<Lead>)Database.queryWithBinds(
                'SELECT Id, Name, Company, Email, IsConverted, Web_Form_Type__c, NTE_Event_Code__c, '
                + 'NTE_Interest_Progressed__c, NTE_Interest_Not_Progressed__c, NTE_Application_Rejected__c, '
                + 'NTE_Invitation_Status__c, NTE_Invitation_Sent_At__c FROM Lead WHERE Id IN :ids'
                + (lockRecords ? ' FOR UPDATE' : ''), binds, AccessLevel.USER_MODE)) {
                RecipientDTO recipient = new RecipientDTO();
                recipient.recordId = interest.Id; recipient.name = interest.Name; recipient.company = interest.Company;
                recipient.email = interest.Email; recipient.eventCode = interest.NTE_Event_Code__c;
                recipient.sourceType = interest.Web_Form_Type__c; recipient.lastSentAt = interest.NTE_Invitation_Sent_At__c;
                recipient.link = route(kind, recipient.sourceType, routing);
                if (interest.IsConverted || !INTEREST_TYPES.contains(interest.Web_Form_Type__c)) recipient.issue = 'This record is not an open expression of interest.';
                else if (interest.NTE_Interest_Not_Progressed__c || interest.NTE_Application_Rejected__c) recipient.issue = 'This interest was not progressed.';
                else if (interest.NTE_Interest_Progressed__c || interest.NTE_Invitation_Status__c == 'Sent') recipient.issue = 'This interest has already been progressed or invited.';
                else if (interest.NTE_Invitation_Status__c == 'Queued' && allowedQueuedIds.isEmpty()) recipient.issue = 'An application invitation is already queued.';
                recipients.put(interest.Id, recipient);
            }
        } else {
            List<Opportunity> bookings = (List<Opportunity>)Database.queryWithBinds(
                'SELECT Id, Name, Account.Name, RecordType.DeveloperName, StageName, IsClosed, IsWon, '
                + 'Booking_Reference__c, NTE_Event_Code__c, NTE_Source_Form_Type__c, '
                + 'Amount, NTE_Payment_Method__c, NTE_Payment_Received_At__c, '
                + 'NTE_Exhibitor_Space_Selections__c, NTE_Exhibitor_Organisation_Category__c, NTE_Sponsor_Package__c, '
                + 'NTE_Sponsor_Package_Total__c, NTE_Exhibitor_Space_Price__c, '
                + 'NTE_Power_Socket_Count__c, NTE_Power_Socket_Unit_Price__c, NTE_Power_Socket_Total__c, '
                + 'NTE_Additional_Staff_Count__c, NTE_Additional_Staff_Unit_Price__c, NTE_Additional_Staff_Total__c, '
                + 'NTE_Pricing_Status__c, NTE_Quote_Required_for_PO__c, NTE_Quote_Provided__c, '
                + 'NTE_Invoice_Required__c, NTE_Listed_Price_Total__c, NTE_Invoice_Provided__c, NTE_Payment_Received__c, '
                + 'NTE_Top_Up_Invoice_Required__c, NTE_Top_Up_Staff_Total__c, NTE_Top_Up_Invoice_Provided__c, NTE_Top_Up_Payment_Received__c, '
                + 'NTE_Staff_Update_Completed_At__c, NTE_Heavy_Vehicle_Required__c, NTE_Heavy_Vehicle_Update_Completed_At__c, '
                + 'NTE_Logo_Update_Provided__c, NTE_Final_Pack_Status__c, NTE_Final_Pack_Sent_At__c '
                + (kind == 'BOOKING_CONFIRMED' ? ', NTE_Total_Staff_Count__c, NTE_Included_Staff_Count__c, '
                    + 'NTE_Trading_Name__c, NTE_Event_Contact_Name__c, NTE_Event_Contact_Email__c, '
                    + 'NTE_Stand_Equipment__c, NTE_Stand_Power__c, NTE_Invoice_Additional_Information__c, '
                    + 'NTE_Invoice_Address__c, NTE_Invoice_Contact_Phone__c, NTE_Invoiced_Company__c, '
                    + 'NTE_Invoiced_Email__c, NTE_Invoiced_Person__c, NTE_Purchase_Order_Number__c, '
                    + 'NTE_Purchase_Order__c, NTE_Supplier_Agreement_Required__c ' : '')
                + 'FROM Opportunity WHERE Id IN :ids' + (lockRecords ? ' FOR UPDATE' : ''), binds, AccessLevel.USER_MODE);
            Map<Id, Contact> contacts = NTEBookingContactService.primaryContacts(
                new Map<Id, Opportunity>(bookings).keySet(), AccessLevel.USER_MODE, lockRecords);
            for (Opportunity booking : bookings) {
                Contact contact = contacts.get(booking.Id);
                RecipientDTO recipient = new RecipientDTO();
                recipient.recordId = booking.Id; recipient.company = booking.Account == null ? booking.Name : booking.Account.Name;
                recipient.name = contact == null ? null : contact.Name; recipient.email = contact == null ? null : contact.Email;
                recipient.contactId = contact == null ? null : contact.Id; recipient.reference = booking.Booking_Reference__c;
                recipient.eventCode = booking.NTE_Event_Code__c; recipient.sourceType = booking.NTE_Source_Form_Type__c;
                recipient.booking = booking; recipient.primaryContact = contact;
                recipient.link = route(kind, recipient.sourceType, routing);
                if (kind == 'BOOKING_CONFIRMED') recipient.bookingSnapshot = JSON.serialize(new List<String>{
                    String.valueOf(booking.NTE_Listed_Price_Total__c), String.valueOf(booking.Amount),
                    String.valueOf(booking.NTE_Payment_Received_At__c), booking.NTE_Sponsor_Package__c,
                    booking.NTE_Exhibitor_Space_Selections__c, String.valueOf(booking.NTE_Sponsor_Package_Total__c),
                    String.valueOf(booking.NTE_Exhibitor_Space_Price__c), String.valueOf(booking.NTE_Power_Socket_Total__c),
                    String.valueOf(booking.NTE_Additional_Staff_Total__c), String.valueOf(booking.NTE_Power_Socket_Count__c),
                    String.valueOf(booking.NTE_Power_Socket_Unit_Price__c), String.valueOf(booking.NTE_Additional_Staff_Count__c),
                    String.valueOf(booking.NTE_Additional_Staff_Unit_Price__c), booking.NTE_Heavy_Vehicle_Required__c, route('STAFF_DUE', recipient.sourceType, routing),
                    route('LOGO_DUE', recipient.sourceType, routing), route('HEAVY_DUE', recipient.sourceType, routing),
                    String.valueOf(booking.NTE_Total_Staff_Count__c), String.valueOf(booking.NTE_Included_Staff_Count__c),
                    booking.NTE_Trading_Name__c, booking.NTE_Event_Contact_Name__c, booking.NTE_Event_Contact_Email__c,
                    booking.NTE_Stand_Equipment__c, booking.NTE_Stand_Power__c, booking.NTE_Invoice_Additional_Information__c,
                    booking.NTE_Invoice_Address__c, booking.NTE_Invoice_Contact_Phone__c, booking.NTE_Invoiced_Company__c,
                    booking.NTE_Invoiced_Email__c, booking.NTE_Invoiced_Person__c, booking.NTE_Purchase_Order_Number__c,
                    booking.NTE_Purchase_Order__c, booking.NTE_Supplier_Agreement_Required__c, booking.NTE_Payment_Method__c,
                    contact == null ? null : contact.FirstName, contact == null ? null : contact.LastName,
                    contact == null ? null : contact.Phone
                });
                if (booking.RecordType == null || booking.RecordType.DeveloperName != 'NTE_Event_Opportunity'
                    || !APPLICATION_TYPES.contains(booking.NTE_Source_Form_Type__c) || (booking.IsClosed && !booking.IsWon)) recipient.issue = 'This record is not an active NTE booking.';
                else if (contact == null) recipient.issue = 'A single primary Contact is required.';
                else if (String.isBlank(recipient.reference)) recipient.issue = 'The booking reference is missing.';
                else if (recipient.reference.trim().length() > 80
                    || !Pattern.matches('(?i)^NTE-[A-Z0-9][A-Z0-9-]{1,74}[A-Z0-9]$', recipient.reference.trim())) {
                    recipient.issue = 'The booking reference is invalid. Correct it before sending.';
                }
                else if (kind == 'BOOKING_CONFIRMED') recipient.issue = NTEExhibitorApprovalEmailService.paymentConfirmationError(booking, routing);
                else if (kind == 'STAFF_DUE' && booking.NTE_Staff_Update_Completed_At__c != null) recipient.issue = 'Staff details are already complete.';
                else if (kind == 'HEAVY_DUE' && (booking.NTE_Heavy_Vehicle_Required__c == 'No'
                    || (booking.NTE_Heavy_Vehicle_Required__c == 'Yes' && booking.NTE_Heavy_Vehicle_Update_Completed_At__c != null))) recipient.issue = 'Logistics details are already complete.';
                else if (kind == 'LOGO_DUE' && booking.NTE_Logo_Update_Provided__c) recipient.issue = 'The logo has already been provided.';
                else if (kind == 'FINAL_PACK') {
                    recipient.lastSentAt = booking.NTE_Final_Pack_Sent_At__c;
                    if (booking.NTE_Final_Pack_Status__c == 'Sent') recipient.issue = 'The final information has already been sent.';
                    else if (booking.NTE_Final_Pack_Status__c == 'Queued' && allowedQueuedIds.isEmpty()) recipient.issue = 'Final information is already queued.';
                    else if (routing == null || String.isBlank(routing.Application_Event_Code__c)
                        || recipient.eventCode != routing.Application_Event_Code__c) recipient.issue = 'The final information link is not configured for this event.';
                    else if (!NTE_MasterPanelController.isComplete(booking)) recipient.issue = 'This booking still has outstanding details or payment.';
                }
                recipients.put(booking.Id, recipient);
            }
        }
        for (NTE_Email_Dispatch__c dispatch : [SELECT Id, Lead__c, Opportunity__c, Status__c, Sent_At__c
            FROM NTE_Email_Dispatch__c WHERE Kind__c = :kind AND (Lead__c IN :ids OR Opportunity__c IN :ids)
            AND Status__c IN ('Queued', 'Sent') WITH USER_MODE]) {
            RecipientDTO recipient = recipients.get(targetId(dispatch));
            if (recipient == null) continue;
            if (dispatch.Status__c == 'Queued' && !allowedQueuedIds.contains(dispatch.Id)) recipient.issue = 'An email of this kind is already queued.';
            if (dispatch.Status__c == 'Sent') {
                if (recipient.lastSentAt == null || recipient.lastSentAt < dispatch.Sent_At__c) recipient.lastSentAt = dispatch.Sent_At__c;
                if (kind == 'INVITATION' || kind == 'FINAL_PACK' || kind == 'BOOKING_CONFIRMED') recipient.issue = 'This email has already been sent.';
            }
        }
        List<RecipientDTO> ordered = new List<RecipientDTO>();
        Set<Id> included = new Set<Id>();
        for (Id recordId : recordIds) {
            if (included.contains(recordId)) continue;
            included.add(recordId);
            RecipientDTO recipient = recipients.get(recordId);
            if (recipient == null) {
                recipient = new RecipientDTO(); recipient.recordId = recordId;
                recipient.issue = 'This record is no longer available to you.';
            }
            if (recipient.issue == null && String.isBlank(recipient.email)) recipient.issue = 'The recipient email address is missing.';
            if (recipient.issue == null && String.isBlank(recipient.eventCode)) recipient.issue = 'The event code is missing.';
            if (recipient.issue == null && kind != 'BOOKING_CONFIRMED' && !validLink(recipient.link)) recipient.issue = 'A valid HTTPS link has not been configured for this email.';
            recipient.eligible = recipient.issue == null;
            recipient.fingerprint = fingerprint(kind, recipient);
            ordered.add(recipient);
        }
        return ordered;
    }

    private static void updateSourceStatuses(List<NTE_Email_Dispatch__c> dispatches, AccessLevel accessLevel) {
        Map<Id, Lead> leads = new Map<Id, Lead>();
        Map<Id, Opportunity> bookings = new Map<Id, Opportunity>();
        Set<Id> leadIds = new Set<Id>();
        Set<Id> bookingIds = new Set<Id>();
        Set<Id> dispatchIds = new Set<Id>();
        for (NTE_Email_Dispatch__c dispatch : dispatches) {
            dispatchIds.add(dispatch.Id);
            if (dispatch.Kind__c == 'INVITATION' && dispatch.Lead__c != null) leadIds.add(dispatch.Lead__c);
            if (dispatch.Kind__c == 'FINAL_PACK' && dispatch.Opportunity__c != null) bookingIds.add(dispatch.Opportunity__c);
        }
        if (leadIds.isEmpty() && bookingIds.isEmpty()) return;
        Map<Id, String> currentStatuses = new Map<Id, String>();
        if (!leadIds.isEmpty()) for (Lead interest : (List<Lead>)Database.queryWithBinds(
            'SELECT Id, NTE_Invitation_Status__c FROM Lead WHERE Id IN :ids',
            new Map<String, Object>{'ids' => leadIds}, accessLevel)) currentStatuses.put(interest.Id, interest.NTE_Invitation_Status__c);
        if (!bookingIds.isEmpty()) for (Opportunity booking : (List<Opportunity>)Database.queryWithBinds(
            'SELECT Id, NTE_Final_Pack_Status__c FROM Opportunity WHERE Id IN :ids',
            new Map<String, Object>{'ids' => bookingIds}, accessLevel)) currentStatuses.put(booking.Id, booking.NTE_Final_Pack_Status__c);
        Set<Id> otherQueuedTargets = new Set<Id>();
        for (NTE_Email_Dispatch__c other : (List<NTE_Email_Dispatch__c>)Database.queryWithBinds(
            'SELECT Lead__c, Opportunity__c FROM NTE_Email_Dispatch__c WHERE Id NOT IN :dispatchIds '
            + 'AND Status__c = \'Queued\' AND ((Kind__c = \'INVITATION\' AND Lead__c IN :leadIds) '
            + 'OR (Kind__c = \'FINAL_PACK\' AND Opportunity__c IN :bookingIds))',
            new Map<String, Object>{'dispatchIds' => dispatchIds, 'leadIds' => leadIds, 'bookingIds' => bookingIds}, accessLevel)) otherQueuedTargets.add(targetId(other));
        for (NTE_Email_Dispatch__c dispatch : dispatches) {
            if (dispatch.Status__c != 'Sent' && (currentStatuses.get(targetId(dispatch)) == 'Sent'
                || (dispatch.Status__c != 'Queued' && otherQueuedTargets.contains(targetId(dispatch))))) continue;
            if (dispatch.Kind__c == 'INVITATION' && dispatch.Lead__c != null) {
                if (leads.containsKey(dispatch.Lead__c) && leads.get(dispatch.Lead__c).NTE_Invitation_Status__c == 'Sent'
                    && dispatch.Status__c != 'Sent') continue;
                if (leads.containsKey(dispatch.Lead__c) && leads.get(dispatch.Lead__c).NTE_Invitation_Status__c == 'Queued'
                    && dispatch.Status__c != 'Queued' && dispatch.Status__c != 'Sent') continue;
                Lead interest = new Lead(Id = dispatch.Lead__c, NTE_Invitation_Status__c = dispatch.Status__c);
                if (dispatch.Status__c == 'Sent') {
                    interest.NTE_Invitation_Sent_At__c = dispatch.Sent_At__c;
                    interest.NTE_Invitation_Recipient__c = dispatch.Recipient__c;
                    interest.NTE_Interest_Progressed__c = true;
                }
                leads.put(interest.Id, interest);
            } else if (dispatch.Kind__c == 'FINAL_PACK' && dispatch.Opportunity__c != null) {
                if (bookings.containsKey(dispatch.Opportunity__c) && bookings.get(dispatch.Opportunity__c).NTE_Final_Pack_Status__c == 'Sent'
                    && dispatch.Status__c != 'Sent') continue;
                if (bookings.containsKey(dispatch.Opportunity__c) && bookings.get(dispatch.Opportunity__c).NTE_Final_Pack_Status__c == 'Queued'
                    && dispatch.Status__c != 'Queued' && dispatch.Status__c != 'Sent') continue;
                Opportunity booking = new Opportunity(Id = dispatch.Opportunity__c, NTE_Final_Pack_Status__c = dispatch.Status__c);
                if (dispatch.Status__c == 'Sent') {
                    booking.NTE_Final_Pack_Sent_At__c = dispatch.Sent_At__c;
                    booking.NTE_Final_Pack_Recipient__c = dispatch.Recipient__c;
                }
                bookings.put(booking.Id, booking);
            }
        }
        if (!leads.isEmpty()) Database.update(leads.values(), true, accessLevel);
        if (!bookings.isEmpty()) Database.update(bookings.values(), true, accessLevel);
    }

    private static Map<Id, RecipientDTO> recipientMap(List<RecipientDTO> recipients) {
        Map<Id, RecipientDTO> result = new Map<Id, RecipientDTO>();
        for (RecipientDTO recipient : recipients) result.put(recipient.recordId, recipient);
        return result;
    }
    private static Boolean sameRecipient(NTE_Email_Dispatch__c dispatch, RecipientDTO recipient) {
        return dispatch.Fingerprint__c == recipient.fingerprint && dispatch.Recipient__c == recipient.email
            && dispatch.Contact__c == recipient.contactId && dispatch.Link__c == recipient.link;
    }
    private static Id targetId(NTE_Email_Dispatch__c dispatch) {
        return dispatch.Lead__c == null ? dispatch.Opportunity__c : dispatch.Lead__c;
    }
    private static String normalizeKind(String kind) {
        String value = String.isBlank(kind) ? '' : kind.trim().toUpperCase();
        if (!KINDS.contains(value)) throw handled('Choose an application invitation, update reminder or final information email.');
        return value;
    }
    private static List<Id> validateIds(List<Id> recordIds, String kind) {
        if (recordIds == null || recordIds.isEmpty() || recordIds.size() > MAX_RECIPIENTS) {
            throw handled('Select between 1 and 500 records. Narrow the filters to prepare a smaller recipient list.');
        }
        List<Id> result = new List<Id>();
        Set<Id> seen = new Set<Id>();
        for (Id recordId : recordIds) {
            if (recordId == null || (recordId.getSObjectType() != Lead.SObjectType && recordId.getSObjectType() != Opportunity.SObjectType)
                || (kind == 'INVITATION' && recordId.getSObjectType() != Lead.SObjectType)
                || (kind != null && kind != 'INVITATION' && recordId.getSObjectType() != Opportunity.SObjectType)) {
                throw handled('Choose records that match this email type.');
            }
            if (!seen.contains(recordId)) { result.add(recordId); seen.add(recordId); }
        }
        return result;
    }
    private static DraftRequest parseRequestJson(String requestJson) {
        if (String.isBlank(requestJson)) throw handled('Prepare and review the recipient list first.');
        if (requestJson.length() > MAX_REQUEST_JSON_LENGTH) {
            throw handled('This email draft is too large. Shorten the message or select fewer recipients.');
        }
        DraftRequest request;
        try {
            request = (DraftRequest)JSON.deserializeStrict(requestJson, DraftRequest.class);
        } catch (Exception malformedRequest) {
            throw handled('The email draft has an invalid format. Refresh the recipient list and try again.');
        }
        if (request == null) throw handled('Prepare and review the recipient list first.');
        return request;
    }
    private static Map<Id, String> validateRequest(DraftRequest request) {
        if (request == null) throw handled('Prepare and review the recipient list first.');
        request.kind = normalizeKind(request.kind);
        if (request.kind == 'BOOKING_CONFIRMED') throw handled('Booking confirmations are sent when booking payment is recorded.');
        if (String.isBlank(request.runId) || !Pattern.matches('[A-Za-z0-9_-]{16,64}', request.runId)) throw handled('Refresh this email draft before sending.');
        if (String.isBlank(request.subject) || request.subject.trim().length() > 255
            || request.subject.contains('\n') || request.subject.contains('\r')) throw handled('Enter a subject of no more than 255 characters on one line.');
        if (String.isBlank(request.messageBody) || request.messageBody.trim().length() > 32000) throw handled('Enter a message of no more than 32,000 characters.');
        Matcher placeholderMatcher = Pattern.compile('\\{([A-Za-z][A-Za-z0-9_]*)\\}').matcher(request.subject + '\n' + request.messageBody);
        while (placeholderMatcher.find()) if (!TOKENS.contains(placeholderMatcher.group(1))) throw handled('Remove the unrecognised placeholder {' + placeholderMatcher.group(1) + '} from the email.');
        if (request.recipients == null || request.recipients.isEmpty() || request.recipients.size() > MAX_RECIPIENTS) throw handled('Select between 1 and 500 recipients from this draft.');
        Map<Id, String> result = new Map<Id, String>();
        for (Selection selection : request.recipients) {
            if (selection == null || selection.recordId == null || String.isBlank(selection.fingerprint)) throw handled('Refresh the recipient list before sending.');
            if (result.containsKey(selection.recordId)) throw handled('Select each recipient only once.');
            result.put(selection.recordId, selection.fingerprint);
        }
        validateIds(new List<Id>(result.keySet()), request.kind);
        return result;
    }
    private static String fingerprint(String kind, RecipientDTO recipient) {
        return hash(JSON.serialize(new List<String>{kind, String.valueOf(recipient.recordId), String.valueOf(recipient.contactId),
            recipient.name, recipient.company, recipient.email, recipient.reference, recipient.eventCode, recipient.link, recipient.sourceType, recipient.bookingSnapshot}));
    }
    private static String dispatchKey(String kind, String runId, Id recordId) {
        return hash(kind + '|' + runId + '|' + String.valueOf(recordId));
    }
    private static String hash(String value) { return EncodingUtil.convertToHex(Crypto.generateDigest('SHA-256', Blob.valueOf(value))); }
    private static String route(String kind, String sourceType, NTE_Routing_Config__mdt routing) {
        if (kind == 'BOOKING_CONFIRMED' || routing == null) return null;
        Boolean partner = sourceType != null && sourceType.startsWith('Partner / Sponsor');
        if (kind == 'INVITATION') return partner ? routing.Partner_Application_URL__c : routing.Exhibitor_Application_URL__c;
        if (kind == 'FINAL_PACK') return partner ? routing.Partner_Final_Pack_URL__c : routing.Exhibitor_Final_Pack_URL__c;
        if (kind == 'HEAVY_DUE') return routing.Heavy_Vehicle_Form_URL__c;
        if (kind == 'LOGO_DUE') return routing.Logo_Update_Form_URL__c;
        return partner ? routing.Partner_Staff_Form_URL__c : routing.Exhibitor_Staff_Form_URL__c;
    }
    private static NTE_Routing_Config__mdt configuredRouting() {
        return routingOverride != null && Test.isRunningTest() ? routingOverride : NTE_Routing_Config__mdt.getInstance('Default');
    }
    private static Boolean validLink(String value) {
        if (String.isBlank(value) || value.length() > 255 || Pattern.compile('\\s').matcher(value).find()) return false;
        try {
            Url link = new Url(value);
            return link.getProtocol().toLowerCase() == 'https' && String.isNotBlank(link.getHost()) && String.isBlank(link.getUserInfo());
        } catch (Exception ignored) { return false; }
    }
    private static String titleFor(String kind) {
        if (kind == 'INVITATION') return 'Application invitations';
        if (kind == 'FINAL_PACK') return 'Final event information';
        if (kind == 'STAFF_DUE') return 'Staff update reminders';
        if (kind == 'HEAVY_DUE') return 'Logistics reminders';
        return 'Logo reminders';
    }
    private static String subjectFor(String kind) {
        if (kind == 'INVITATION') return 'Your invitation to apply for NTE';
        if (kind == 'FINAL_PACK') return 'Your NTE event information';
        if (kind == 'STAFF_DUE') return 'NTE staff details reminder';
        if (kind == 'HEAVY_DUE') return 'NTE logistics details reminder';
        return 'NTE logo reminder';
    }
    private static String bodyFor(String kind) {
        String message;
        if (kind == 'INVITATION') message = 'Thank you for your interest in NTE. We would like to invite {Organisation} to complete an application using the link below.';
        else if (kind == 'FINAL_PACK') message = 'Thank you for completing the arrangements for {Organisation}. Please use the link below for your arrival, setup and event information.';
        else if (kind == 'STAFF_DUE') message = 'Please provide the outstanding staff details for {Organisation}.';
        else if (kind == 'HEAVY_DUE') message = 'Please complete the outstanding logistics details for {Organisation}.';
        else message = 'Please upload the logo for {Organisation}.';
        return 'Hello {ContactName},\n\n' + message + '\n\n{UpdateLink}';
    }
    private static String personalise(String template, RecipientDTO recipient) {
        Map<String, String> values = new Map<String, String>{
            'ContactName' => String.isBlank(recipient.name) ? 'there' : recipient.name,
            'Organisation' => String.isBlank(recipient.company) ? 'your organisation' : recipient.company,
            'BookingReference' => String.isBlank(recipient.reference) ? '' : recipient.reference,
            'EventCode' => String.isBlank(recipient.eventCode) ? '' : recipient.eventCode,
            'UpdateLink' => recipient.link, 'ApplicationLink' => recipient.link, 'FinalPackLink' => recipient.link
        };
        Matcher tokens = Pattern.compile('\\{([A-Za-z][A-Za-z0-9_]*)\\}').matcher(template);
        List<String> parts = new List<String>();
        Integer position = 0;
        while (tokens.find()) {
            parts.add(template.substring(position, tokens.start()));
            String token = tokens.group(1);
            parts.add(values.containsKey(token) ? (values.get(token) == null ? '' : values.get(token)) : tokens.group(0));
            position = tokens.end();
        }
        parts.add(template.substring(position));
        return String.join(parts, '');
    }
    private static String normaliseLines(String text) { return text.replace('\r\n', '\n').replace('\r', '\n'); }
    private static String personalisedContentIssue(String subject, String body, RecipientDTO recipient) {
        if (String.isBlank(subject) || String.isBlank(body)) return 'Enter a subject and message before sending.';
        String renderedSubject = personalise(subject.trim(), recipient);
        if (renderedSubject.length() > 255 || renderedSubject.contains('\r') || renderedSubject.contains('\n')) {
            return 'The personalised subject must fit on one line and contain no more than 255 characters. Shorten the subject or remove a placeholder.';
        }
        if (personalise(body.trim(), recipient).length() > 32000) {
            return 'The personalised message exceeds 32,000 characters. Shorten the message or use fewer placeholders.';
        }
        return null;
    }
    private static String htmlFor(String kind, String subject, String body, RecipientDTO recipient) {
        String text = body.replace('{UpdateLink}', '').replace('{ApplicationLink}', '').replace('{FinalPackLink}', '').trim();
        String label = kind == 'INVITATION' ? 'Complete your application' : kind == 'FINAL_PACK' ? 'View event information'
            : kind == 'STAFF_DUE' ? 'Update staff details' : kind == 'HEAVY_DUE' ? 'Update logistics details' : 'Upload your logo';
        Boolean partner = recipient.sourceType != null && recipient.sourceType.startsWith('Partner / Sponsor');
        Boolean complimentary = !partner && recipient.booking != null && recipient.booking.NTE_Pricing_Status__c == 'Calculated'
            && recipient.booking.NTE_Listed_Price_Total__c == 0;
        String accent = partner ? '#20a7d8' : complimentary ? '#26867b' : '#b08a35';
        String buttonColour = partner ? '#0b668f' : complimentary ? '#176f66' : '#856624';
        String tint = partner ? '#eaf7fc' : complimentary ? '#eaf5f2' : '#f8f3e5';
        String kickerColour = partner ? '#8dd9f2' : complimentary ? '#9edcd0' : '#e8cc8b';
        String renderedSubject = escape(personalise(subject, recipient));
        String reference = String.isBlank(recipient.reference) ? ''
            : '<tr><td class="mobile-pad" style="padding:0 48px 24px;"><table role="presentation" width="100%" cellspacing="0" cellpadding="0" border="0" style="width:100%;background-color:'
            + tint + ';border-left:5px solid ' + accent + ';border-radius:8px;"><tr><td style="padding:18px 22px;">'
            + '<div style="font-size:12px;line-height:18px;font-weight:bold;letter-spacing:1.2px;text-transform:uppercase;color:' + buttonColour + ';">Booking reference</div>'
            + '<div style="margin-top:6px;font-size:18px;line-height:26px;font-weight:bold;color:#203442;">' + escape(recipient.reference) + '</div></td></tr></table></td></tr>';
        return '<!doctype html><html lang="en" xmlns="http://www.w3.org/1999/xhtml"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">'
            + '<meta name="x-apple-disable-message-reformatting"><title>' + renderedSubject + '</title>'
            + '<style>body,table,td,a{-webkit-text-size-adjust:100%;-ms-text-size-adjust:100%}table,td{mso-table-lspace:0;mso-table-rspace:0}table{border-collapse:collapse!important}img{border:0;height:auto;line-height:100%;outline:none;text-decoration:none}body{margin:0!important;padding:0!important;width:100%!important}@media screen and (max-width:620px){.email-shell{width:100%!important}.mobile-pad{padding-left:22px!important;padding-right:22px!important}.hero-title{font-size:30px!important;line-height:36px!important}.logo{width:150px!important}}</style>'
            + '</head><body style="margin:0;padding:0;background-color:#edf3f7;color:#263746;font-family:Arial,Helvetica,sans-serif;">'
            + '<table role="presentation" width="100%" cellspacing="0" cellpadding="0" border="0" style="width:100%;background-color:#edf3f7;"><tr><td align="center" style="padding:28px 12px;">'
            + '<table role="presentation" class="email-shell" width="680" cellspacing="0" cellpadding="0" border="0" style="width:680px;max-width:680px;table-layout:fixed;overflow-wrap:anywhere;word-break:break-word;background-color:#ffffff;border-radius:18px;overflow:hidden;box-shadow:0 12px 36px rgba(10,42,67,.12);">'
            + '<tr><td style="height:8px;background-color:' + accent + ';font-size:0;line-height:0;">&nbsp;</td></tr>'
            + '<tr><td class="mobile-pad" style="padding:24px 48px;background:#ffffff;"><a href="https://www.nationaltransitionevent.com/" target="_blank">'
            + '<img class="logo" src="https://stevostar1234.github.io/nte27-web-to-lead-demo/assets/nte-logo-white.png" width="160" alt="The National Transition Event" style="display:block;width:160px;max-width:100%;height:auto;"></a></td></tr>'
            + '<tr><td class="mobile-pad" style="padding:36px 48px 40px;background-color:#0b3553;color:#ffffff;">'
            + '<div style="margin:0 0 16px;font-size:12px;line-height:16px;font-weight:bold;letter-spacing:2px;text-transform:uppercase;color:' + kickerColour + ';">'
            + escape(recipient.eventCode) + ' &bull; ' + (partner ? 'Partners &amp; sponsors' : 'Exhibitors') + '</div>'
            + '<h1 class="hero-title" style="margin:0;font-size:38px;line-height:44px;font-weight:700;color:#ffffff;">' + renderedSubject + '</h1></td></tr>'
            + '<tr><td class="mobile-pad" style="padding:38px 48px 24px;font-size:17px;line-height:28px;color:#263746;">'
            + escape(normaliseLines(personalise(text, recipient))).replace('\n', '<br>') + '</td></tr>'
            + reference
            + '<tr><td class="mobile-pad" style="padding:0 48px 32px;"><table role="presentation" cellspacing="0" cellpadding="0" border="0"><tr>'
            + '<td align="center" bgcolor="' + buttonColour + '" style="background-color:' + buttonColour + ';border-radius:7px;">'
            + '<a href="' + escape(recipient.link) + '" style="display:inline-block;padding:14px 22px;background-color:' + buttonColour
            + ';color:#ffffff;text-decoration:none;font-size:15px;line-height:22px;font-weight:bold;border-radius:7px;">' + label + '</a></td></tr></table></td></tr>'
            + '<tr><td class="mobile-pad" style="padding:4px 48px 40px;"><p style="margin:0;font-size:16px;line-height:26px;color:#263746;">Kind regards,<br><strong>The National Transition Event Team</strong><br>Mission Community</p></td></tr>'
            + '<tr><td class="mobile-pad" style="padding:25px 48px;background-color:#092b43;color:#c8d9e3;text-align:center;">'
            + '<p style="margin:0;font-size:13px;line-height:22px;"><a href="https://www.nationaltransitionevent.com/" style="color:' + kickerColour + ';text-decoration:none;">nationaltransitionevent.com</a>'
            + '&nbsp;&nbsp; | &nbsp;&nbsp;<a href="mailto:nte@missioncommunity.org" style="color:' + kickerColour + ';text-decoration:none;">nte@missioncommunity.org</a></p>'
            + '</td></tr></table></td></tr></table></body></html>';
    }
    private static String escape(String value) { return value == null ? '' : value.escapeHtml4(); }
    private static String emailError(Messaging.SendEmailResult result) {
        return result.getErrors().isEmpty() ? 'Salesforce did not accept this email.' : result.getErrors()[0].getMessage().left(32000);
    }
    private static QueueResponse resultFor(Integer queued, Integer skipped) {
        QueueResponse result = new QueueResponse(); result.queuedCount = queued; result.skippedCount = skipped;
        result.message = queued + ' email' + (queued == 1 ? '' : 's') + ' queued.'
            + (skipped > 0 ? ' ' + skipped + ' skipped because they changed, were already queued or were no longer eligible.' : '');
        return result;
    }
    private static AuraHandledException handled(String message) {
        AuraHandledException result = new AuraHandledException(message); result.setMessage(message); return result;
    }
}
