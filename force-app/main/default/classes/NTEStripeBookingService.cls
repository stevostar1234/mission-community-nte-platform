/** Coordinates saved booking charges, committed Stripe work and the existing provisional email. */
public without sharing class NTEStripeBookingService {
    @TestVisible private static NTE_Stripe_Config__mdt configurationOverride;
    @TestVisible private static Boolean suppressEnqueue = false;
    private static Map<Id, NTE_Payment_Request__c> emailRequests = new Map<Id, NTE_Payment_Request__c>();
    private static Set<Id> loadedEmailRequests = new Set<Id>();
    private static Organization currentOrg;
    private static final String BOOKING_FIELDS = 'Id, Name, CreatedDate, Account.Name, Amount, Booking_Reference__c, StageName, '
        + 'NTE_Source_Form_Type__c, NTE_Event_Code__c, NTE_Payment_Method__c, NTE_Payment_Received__c, '
        + 'NTE_Quote_Required_for_PO__c, NTE_Quote_Provided__c, NTE_Pricing_Status__c, NTE_Exhibitor_Space_Selections__c, '
        + 'NTE_Exhibitor_Organisation_Category__c, NTE_Sponsor_Package__c, NTE_Sponsor_Package_Total__c, '
        + 'NTE_Exhibitor_Space_Price__c, NTE_Power_Socket_Count__c, NTE_Power_Socket_Unit_Price__c, NTE_Power_Socket_Total__c, '
        + 'NTE_Additional_Staff_Count__c, NTE_Additional_Staff_Unit_Price__c, NTE_Additional_Staff_Total__c, '
        + 'NTE_Listed_Price_Total__c, NTE_Price_Adjustment__c, NTE_VAT_Rate__c, NTE_Heavy_Vehicle_Required__c, NTE_Approval_Email_Status__c, '
        + 'NTE_Approval_Email_Kind__c, NTE_Approval_Email_Lead_Id__c, NTE_Approval_Email_Batch__c, NTE_Top_Up_Staff_Total__c, NTE_Top_Up_VAT_Rate__c, '
        + 'NTE_Top_Up_Staff_Count__c, NTE_Top_Up_Staff_Unit_Price__c, NTE_Top_Up_Payment_Received__c, NTE_Top_Up_Payment_Requested_At__c';
    private static final String REQUEST_FIELDS = 'Id, Opportunity__c, Charge_Key__c, Kind__c, Status__c, Amount_Minor__c, '
        + 'Net_Minor__c, Tax_Rate__c, Currency__c, Live_Mode__c, Stripe_Account__c, Source_Fingerprint__c, Source_Lead_Id__c, Reference__c, '
        + 'Description__c, Price_Id__c, Link_Id__c, Payment_URL__c, First_Attempt_At__c, Verified_At__c, Error__c, '
        + 'Delivered_At__c, Recipient__c, Batch_Key__c';

    public static NTE_Stripe_Config__mdt configuration() {
        return Test.isRunningTest() && configurationOverride != null ? configurationOverride : NTE_Stripe_Config__mdt.getInstance('Default');
    }
    private static Boolean selected(Opportunity booking, NTE_Stripe_Config__mdt config) {
        return booking.NTE_Payment_Method__c == 'Stripe' && NTEVat.bookingGross(booking.NTE_Listed_Price_Total__c, booking.NTE_VAT_Rate__c, booking.Amount) > 0
            && config != null && config.Enabled__c
            && (String.isBlank(config.Reference_Prefix__c)
                || (String.isNotBlank(booking.Booking_Reference__c)
                    && booking.Booking_Reference__c.startsWith(config.Reference_Prefix__c)));
    }
    private static String configurationError(NTE_Stripe_Config__mdt config) {
        if (config == null || !config.Enabled__c) return 'Stripe payment requests are disabled. Review this booking before retrying.';
        if (currentOrg == null) currentOrg = [SELECT Id FROM Organization LIMIT 1];
        Organization org = currentOrg;
        if (String.valueOf(org.Id) != config.Expected_Org_Id__c) return 'This Stripe configuration does not belong to this Salesforce organisation.';
        if (String.isBlank(config.Expected_Account_Id__c)
            || config.Tax_Rate__c == null || config.Tax_Rate__c < 0 || config.Tax_Rate__c > 100 || config.Tax_Rate__c != NTEVat.RATE) return 'The Stripe configuration is incomplete.';
        return null;
    }
    private static List<Opportunity> bookings(String whereClause, Map<String, Object> binds, Boolean lockRows) {
        return (List<Opportunity>)Database.queryWithBinds('SELECT ' + BOOKING_FIELDS + ' FROM Opportunity WHERE '
            + whereClause + (lockRows ? ' FOR UPDATE' : ''), binds, AccessLevel.SYSTEM_MODE);
    }
    private static List<NTE_Payment_Request__c> requests(String whereClause, Map<String, Object> binds, Boolean lockRows) {
        return (List<NTE_Payment_Request__c>)Database.queryWithBinds('SELECT ' + REQUEST_FIELDS + ' FROM NTE_Payment_Request__c WHERE '
            + whereClause + (lockRows ? ' FOR UPDATE' : ''), binds, AccessLevel.SYSTEM_MODE);
    }

    public static Boolean prepareProvisionalBatch(String batchKey, Boolean bypassDelivery, Boolean allowTestLead) {
        List<Opportunity> candidates = bookings('NTE_Approval_Email_Batch__c = :batch AND NTE_Approval_Email_Status__c = \'Pending\'',
            new Map<String, Object>{'batch' => batchKey}, true);
        if (candidates.isEmpty()) return false;
        Set<Id> ids = new Map<Id, Opportunity>(candidates).keySet();
        Map<Id, NTE_Payment_Request__c> saved = new Map<Id, NTE_Payment_Request__c>();
        for (NTE_Payment_Request__c payment : requests('Opportunity__c IN :ids AND Kind__c = \'Booking\'', new Map<String, Object>{'ids' => ids}, true)) {
            saved.put(payment.Opportunity__c, payment);
        }
        NTE_Stripe_Config__mdt config = configuration();
        Set<Id> selectedIds = new Set<Id>();
        for (Opportunity booking : candidates) if (NTEVat.bookingGross(booking.NTE_Listed_Price_Total__c, booking.NTE_VAT_Rate__c, booking.Amount) > 0 && booking.NTE_Approval_Email_Kind__c != 'Free confirmation'
            && booking.NTE_Payment_Method__c == 'Stripe') selectedIds.add(booking.Id);
        if (selectedIds.isEmpty()) return false;
        Map<Id, Contact> contacts = NTEBookingContactService.primaryContacts(selectedIds, AccessLevel.SYSTEM_MODE, true);
        Map<Id, List<Lead>> sourceLeads = convertedApplications(selectedIds);
        String configError = configurationError(config);
        List<NTE_Payment_Request__c> pending = new List<NTE_Payment_Request__c>();
        List<NTE_Payment_Request__c> held = new List<NTE_Payment_Request__c>();
        List<Opportunity> failed = new List<Opportunity>();
        for (Opportunity booking : candidates) {
            if (!selectedIds.contains(booking.Id)) continue;
            NTE_Payment_Request__c payment = saved.get(booking.Id);
            String error = configError;
            if (error == null) error = eligibilityError(booking, contacts.get(booking.Id), config, allowTestLead, sourceLeads.get(booking.Id));
            String fingerprint = error == null ? fingerprint(booking, contacts.get(booking.Id), config) : null;
            if (error == null && payment != null && (payment.Source_Fingerprint__c != fingerprint
                || (payment.Live_Mode__c == true) != (config.Live_Mode__c == true))) {
                error = 'The booking or payment configuration has changed. Review the existing Stripe request before replacing it.';
            }
            if (error != null) {
                failed.add(emailFailure(booking.Id, error));
                if (payment != null) { payment.Status__c = 'Needs review'; payment.Error__c = error; held.add(payment); }
                continue;
            }
            if (payment == null) {
                Decimal net = booking.NTE_Listed_Price_Total__c;
                Decimal gross = NTEVat.bookingGross(net, booking.NTE_VAT_Rate__c, booking.Amount);
                payment = new NTE_Payment_Request__c(
                    Opportunity__c = booking.Id, Charge_Key__c = UserInfo.getOrganizationId() + ':' + booking.Id + ':Booking',
                    Kind__c = 'Booking', Status__c = 'Queued', Net_Minor__c = NTEStripeClient.toMinorUnits(net),
                    Amount_Minor__c = NTEStripeClient.toMinorUnits(gross), Tax_Rate__c = NTEVat.rate(booking.NTE_VAT_Rate__c),
                    Currency__c = 'gbp', Live_Mode__c = config.Live_Mode__c == true, Stripe_Account__c = config.Expected_Account_Id__c, Source_Fingerprint__c = fingerprint,
                    Source_Lead_Id__c = booking.NTE_Approval_Email_Lead_Id__c, Reference__c = booking.Booking_Reference__c,
                    Description__c = 'NTE booking · ' + booking.Booking_Reference__c,
                    First_Attempt_At__c = System.now(), Batch_Key__c = batchKey, Recipient__c = contacts.get(booking.Id).Email
                );
            } else if (payment.Batch_Key__c == batchKey && payment.Status__c == 'Ready' && payment.Verified_At__c != null && payment.Verified_At__c > System.now().addMinutes(-5)) {
                continue;
            } else {
                payment.Status__c = 'Queued'; payment.Error__c = null; payment.Batch_Key__c = batchKey;
            }
            pending.add(payment);
        }
        if (!failed.isEmpty()) update failed;
        if (!held.isEmpty()) update held;
        if (pending.isEmpty()) return false;
        upsert pending Charge_Key__c;
        List<Id> requestIds = new List<Id>(); for (NTE_Payment_Request__c payment : pending) requestIds.add(payment.Id);
        if (!(Test.isRunningTest() && suppressEnqueue)) System.enqueueJob(new PaymentWork(requestIds, batchKey, bypassDelivery, allowTestLead));
        return true;
    }

    private static Map<Id, List<Lead>> convertedApplications(Set<Id> bookingIds) {
        Map<Id, List<Lead>> result = new Map<Id, List<Lead>>();
        for (Lead application : [SELECT Id, ConvertedOpportunityId, Web_Form_Type__c FROM Lead
            WHERE IsConverted = true AND ConvertedOpportunityId IN :bookingIds]) {
            if (!result.containsKey(application.ConvertedOpportunityId)) result.put(application.ConvertedOpportunityId, new List<Lead>());
            result.get(application.ConvertedOpportunityId).add(application);
        }
        return result;
    }
    private static String eligibilityError(Opportunity booking, Contact recipient, NTE_Stripe_Config__mdt config, Boolean allowTestLead, List<Lead> source) {
        if (!selected(booking, config)) return 'This booking does not require an enabled Stripe payment request.';
        if (booking.NTE_Payment_Received__c || booking.StageName == 'Closed Lost') return 'Review the existing payment or cancellation before sending a payment request.';
        if (booking.NTE_Approval_Email_Status__c != 'Pending') return 'The provisional email is no longer pending.';
        if (recipient == null || String.isBlank(recipient.Email)) {
            return 'The primary Contact needs an email address before sending a payment request.';
        }
        if (String.isNotBlank(config.Allowed_Email__c) && !recipient.Email.equalsIgnoreCase(config.Allowed_Email__c)) {
            return 'The primary Contact does not match the configured payment recipient filter.';
        }
        String pricingError = NTEExhibitorApprovalEmailService.savedPriceError(booking);
        if (pricingError != null) return pricingError;
        String preparationError = NTEExhibitorApprovalEmailService.preparationConfigurationError(booking, NTE_Routing_Config__mdt.getInstance('Default'));
        if (preparationError != null) return preparationError;
        if (String.isBlank(booking.NTE_Event_Code__c) || String.isBlank(booking.NTE_Approval_Email_Lead_Id__c)) return 'The converted application identity is missing.';
        if (!(Test.isRunningTest() && allowTestLead)) {
            if (source == null || source.size() != 1 || String.valueOf(source[0].Id) != booking.NTE_Approval_Email_Lead_Id__c
                || source[0].Web_Form_Type__c != booking.NTE_Source_Form_Type__c) return 'A single converted application must match this booking before creating a payment request.';
        }
        return null;
    }
    private static String fingerprint(Opportunity booking, Contact recipient, NTE_Stripe_Config__mdt config) {
        // Retain the repeated recipient to preserve snapshots from the earlier fixed-recipient rollout.
        return EncodingUtil.convertToHex(Crypto.generateDigest('SHA-256', Blob.valueOf(JSON.serialize(new List<Object>{
            booking.Id, booking.NTE_Approval_Email_Lead_Id__c, booking.Booking_Reference__c, booking.NTE_Event_Code__c,
            booking.NTE_Source_Form_Type__c, booking.NTE_Listed_Price_Total__c, booking.NTE_VAT_Rate__c, booking.Amount,
            booking.NTE_Sponsor_Package__c, booking.NTE_Exhibitor_Space_Selections__c,
            booking.NTE_Sponsor_Package_Total__c, booking.NTE_Exhibitor_Space_Price__c,
            booking.NTE_Power_Socket_Count__c, booking.NTE_Power_Socket_Unit_Price__c, booking.NTE_Power_Socket_Total__c,
            booking.NTE_Additional_Staff_Count__c, booking.NTE_Additional_Staff_Unit_Price__c, booking.NTE_Additional_Staff_Total__c,
            recipient.Id, recipient.Email.toLowerCase(), config.Expected_Account_Id__c, NTEVat.rate(booking.NTE_VAT_Rate__c),
            config.Expected_Org_Id__c, recipient.Email.toLowerCase(), NTEStripeClient.API_VERSION
        }))));
    }
    private class PaymentWork implements Queueable, Database.AllowsCallouts {
        List<Id> ids; String batch; Boolean bypassDelivery; Boolean allowTestLead;
        PaymentWork(List<Id> values, String batchKey, Boolean bypass, Boolean allowLead) {
            ids = values; batch = batchKey; bypassDelivery = bypass; allowTestLead = allowLead;
        }
        public void execute(QueueableContext context) {
            System.attachFinalizer(new PaymentFinalizer(ids, batch));
            processPayment(ids[0], allowTestLead);
            NTEExhibitorApprovalEmailService.finishStripeBooking(ids[0], batch, bypassDelivery, allowTestLead);
            ids.remove(0);
            if (!ids.isEmpty()) System.enqueueJob(new PaymentWork(ids, batch, bypassDelivery, allowTestLead));
            else NTEExhibitorApprovalEmailService.resumeAfterStripe(batch, bypassDelivery, allowTestLead);
        }
    }
    private class PaymentFinalizer implements Finalizer {
        List<Id> ids; String batch;
        PaymentFinalizer(List<Id> values, String batchKey) { ids = values.clone(); batch = batchKey; }
        public void execute(FinalizerContext context) {
            if (context.getResult() == ParentJobResult.SUCCESS) return;
            List<NTE_Payment_Request__c> updates = new List<NTE_Payment_Request__c>();
            for (Id id : ids) updates.add(new NTE_Payment_Request__c(Id = id, Status__c = 'Needs review',
                Error__c = 'The payment job stopped unexpectedly. Reconcile this saved request before retrying.'));
            if (!updates.isEmpty()) update updates;
            List<Opportunity> failures = new List<Opportunity>();
            for (Opportunity booking : [SELECT Id FROM Opportunity WHERE NTE_Approval_Email_Batch__c = :batch AND NTE_Approval_Email_Status__c = 'Pending']) {
                failures.add(emailFailure(booking.Id, 'The Stripe payment job stopped. Review the saved request before retrying the booking email.'));
            }
            if (!failures.isEmpty()) update failures;
        }
    }
    @TestVisible private static void processPayment(Id requestId, Boolean allowTestLead) {
        List<NTE_Payment_Request__c> found = requests('Id = :id', new Map<String, Object>{'id' => requestId}, false);
        if (found.isEmpty()) return;
        NTE_Payment_Request__c payment = found[0];
        if (payment.Status__c != 'Queued') return;
        NTE_Stripe_Config__mdt config = configuration();
        String error = configurationError(config);
        List<Opportunity> matched = bookings('Id = :id', new Map<String, Object>{'id' => payment.Opportunity__c}, false);
        Contact recipient;
        if (matched.isEmpty()) error = 'The booking no longer exists.';
        else {
            recipient = NTEBookingContactService.primaryContacts(new Set<Id>{payment.Opportunity__c}, AccessLevel.SYSTEM_MODE, false).get(payment.Opportunity__c);
            if (error == null) error = paymentEligibility(payment.Kind__c, matched[0], recipient, config, allowTestLead,
                convertedApplications(new Set<Id>{payment.Opportunity__c}).get(payment.Opportunity__c));
            if (error == null && (payment.Source_Fingerprint__c != paymentFingerprint(payment.Kind__c, matched[0], recipient, config)
                || (payment.Live_Mode__c == true) != (config.Live_Mode__c == true))) error = 'The booking changed before Stripe processing. Review the saved payment request.';
        }
        if (error == null && String.isBlank(payment.Link_Id__c)
            && (payment.First_Attempt_At__c == null || payment.First_Attempt_At__c < System.now().addHours(-23))) {
            error = 'The original creation outcome needs reconciliation. Do not create a replacement request automatically.';
        }
        if (error == null) {
            try {
                NTEStripeClient client = new NTEStripeClient(payment.Live_Mode__c == true ? 'NTE_Stripe_Live' : 'NTE_Stripe_Test');
                client.verifyAccount(payment.Stripe_Account__c);
                NTEStripeClient.Charge charge = charge(payment);
                if (String.isBlank(payment.Price_Id__c)) payment.Price_Id__c = client.createPrice(charge);
                if (String.isBlank(payment.Link_Id__c)) payment.Link_Id__c = client.createLink(charge, payment.Price_Id__c);
                NTEStripeClient.PaymentLink link = client.verifyLink(charge, payment.Link_Id__c, payment.Price_Id__c);
                payment.Payment_URL__c = link.url; payment.Verified_At__c = System.now();
            } catch (NTEStripeClient.StripeException failure) { error = failure.getMessage(); }
        }
        // Callouts hold no database locks. Re-read the exact booking before accepting their result.
        matched = bookings('Id = :id', new Map<String, Object>{'id' => payment.Opportunity__c}, true);
        NTE_Payment_Request__c latest = requests('Id = :id', new Map<String, Object>{'id' => requestId}, true)[0];
        if (latest.Status__c != 'Queued' || latest.Batch_Key__c != payment.Batch_Key__c) return;
        if (error == null && !matched.isEmpty()) {
            recipient = NTEBookingContactService.primaryContacts(new Set<Id>{payment.Opportunity__c}, AccessLevel.SYSTEM_MODE, true).get(payment.Opportunity__c);
            config = configuration(); error = configurationError(config);
            if (error == null) error = paymentEligibility(payment.Kind__c, matched[0], recipient, config, allowTestLead,
                convertedApplications(new Set<Id>{payment.Opportunity__c}).get(payment.Opportunity__c));
            if (error == null && (payment.Source_Fingerprint__c != paymentFingerprint(payment.Kind__c, matched[0], recipient, config)
                || (payment.Live_Mode__c == true) != (config.Live_Mode__c == true))) error = 'The booking changed while Stripe was processing. Review the saved request before sending.';
        }
        if (matched.isEmpty()) error = 'The booking no longer exists.';
        payment.Status__c = error == null ? 'Ready' : 'Needs review'; payment.Error__c = error;
        update payment;
        if (error != null && !matched.isEmpty() && payment.Kind__c == 'Booking') update emailFailure(payment.Opportunity__c, error);
    }
    private static NTEStripeClient.Charge charge(NTE_Payment_Request__c payment) {
        NTEStripeClient.Charge value = new NTEStripeClient.Charge();
        value.accountId = payment.Stripe_Account__c; value.operationKey = payment.Charge_Key__c;
        value.bookingReference = payment.Reference__c; value.chargeKind = payment.Kind__c;
        value.currencyCode = payment.Currency__c; value.amountMinor = payment.Amount_Minor__c.longValue();
        value.netMinor = payment.Net_Minor__c.longValue(); value.vatRate = payment.Tax_Rate__c;
        value.description = payment.Description__c; return value;
    }
    private static Opportunity emailFailure(Id bookingId, String error) {
        return new Opportunity(Id = bookingId, NTE_Approval_Email_Status__c = 'Failed', NTE_Approval_Email_Error__c = error);
    }
    public static void preloadEmailRequests(Set<Id> bookingIds) {
        for (Id bookingId : bookingIds) emailRequests.remove(bookingId);
        for (NTE_Payment_Request__c payment : requests('Opportunity__c IN :ids AND Kind__c = \'Booking\'', new Map<String, Object>{'ids' => bookingIds}, false)) {
            emailRequests.put(payment.Opportunity__c, payment);
        }
        loadedEmailRequests.addAll(bookingIds);
    }
    public static NTE_Payment_Request__c paymentForEmail(Id bookingId) {
        if (!loadedEmailRequests.contains(bookingId)) preloadEmailRequests(new Set<Id>{bookingId});
        return emailRequests.get(bookingId);
    }
    public static String emailReadinessError(Opportunity booking, Contact recipient) {
        if (booking.NTE_Payment_Method__c != 'Stripe'
            || NTEVat.bookingGross(booking.NTE_Listed_Price_Total__c, booking.NTE_VAT_Rate__c, booking.Amount) <= 0) return null;
        NTE_Payment_Request__c payment = paymentForEmail(booking.Id);
        NTE_Stripe_Config__mdt config = configuration();
        String error = configurationError(config);
        if (error != null) return error;
        if (payment == null || payment.Status__c != 'Ready' || payment.Verified_At__c == null
            || payment.Verified_At__c < System.now().addMinutes(-5) || !NTEStripeClient.validPaymentUrl(payment.Payment_URL__c, payment.Live_Mode__c)
            || (payment.Live_Mode__c == true) != (config.Live_Mode__c == true)) return 'The Stripe payment request is not ready. Retry the booking email after reviewing its payment request.';
        if (booking.NTE_Payment_Received__c || booking.StageName == 'Closed Lost' || recipient == null
            || String.isBlank(recipient.Email) || payment.Source_Fingerprint__c != fingerprint(booking, recipient, config)) return 'The booking changed after Stripe verification. Review its payment request before sending.';
        return null;
    }
    public static void recordEmailAccepted(Opportunity booking, Opportunity updateRecord, Contact recipient, List<NTE_Payment_Request__c> paymentUpdates) {
        if (booking.NTE_Payment_Method__c != 'Stripe') return;
        NTE_Payment_Request__c payment = paymentForEmail(booking.Id);
        if (payment == null) return;
        paymentUpdates.add(new NTE_Payment_Request__c(Id = payment.Id, Delivered_At__c = payment.Delivered_At__c == null ? System.now() : payment.Delivered_At__c, Recipient__c = recipient.Email));
    }

    private static String paymentEligibility(String kind, Opportunity booking, Contact recipient, NTE_Stripe_Config__mdt config, Boolean allowTestLead, List<Lead> source) {
        if (kind == 'Booking') return eligibilityError(booking, recipient, config, allowTestLead, source);
        if (kind != 'Staff top-up') return 'This payment request type is not supported.';
        if (booking.StageName == 'Closed Lost' || booking.NTE_Top_Up_Payment_Received__c || booking.NTE_Top_Up_Staff_Total__c == null || booking.NTE_Top_Up_Staff_Total__c <= 0) return 'There is no unpaid staff top-up for this booking.';
        if (!validTopUpPricing(booking)) return 'Check the staff top-up quantity, unit price and total before sending.';
        if (recipient == null || String.isBlank(recipient.Email)) return 'The primary Contact needs an email address.';
        if (String.isNotBlank(config.Allowed_Email__c) && !recipient.Email.equalsIgnoreCase(config.Allowed_Email__c)) return 'The primary Contact does not match the payment recipient filter.';
        String pricingError = NTEExhibitorApprovalEmailService.savedPriceError(booking);
        if (pricingError != null) return pricingError;
        if (NTEVat.rate(booking.NTE_Top_Up_VAT_Rate__c) != config.Tax_Rate__c) return 'Review the staff top-up VAT rate before sending.';
        if (String.isBlank(booking.Booking_Reference__c) || String.isBlank(booking.NTE_Approval_Email_Lead_Id__c)) return 'The converted application identity is missing.';
        if (!(Test.isRunningTest() && allowTestLead) && (source == null || source.size() != 1 || String.valueOf(source[0].Id) != booking.NTE_Approval_Email_Lead_Id__c || source[0].Web_Form_Type__c != booking.NTE_Source_Form_Type__c)) return 'A single converted application must match this booking.';
        return null;
    }
    @TestVisible private static Boolean validTopUpPricing(Opportunity booking) {
        Decimal quantity = booking.NTE_Top_Up_Staff_Count__c;
        Decimal unitPrice = booking.NTE_Top_Up_Staff_Unit_Price__c;
        Decimal total = booking.NTE_Top_Up_Staff_Total__c;
        // Use the accepted purchase's saved unit price, including historical prices.
        return quantity != null && quantity > 0 && quantity == quantity.setScale(0)
            && unitPrice != null && unitPrice > 0 && total != null && total > 0
            && (quantity * unitPrice).setScale(2, RoundingMode.HALF_UP) == total;
    }
    private static String paymentFingerprint(String kind, Opportunity booking, Contact recipient, NTE_Stripe_Config__mdt config) {
        if (kind == 'Booking') return fingerprint(booking, recipient, config);
        return EncodingUtil.convertToHex(Crypto.generateDigest('SHA-256', Blob.valueOf(JSON.serialize(new List<Object>{
            kind, booking.Id, booking.NTE_Approval_Email_Lead_Id__c, booking.Booking_Reference__c, booking.NTE_Event_Code__c,
            booking.NTE_Top_Up_Staff_Total__c, booking.NTE_Top_Up_VAT_Rate__c, booking.NTE_Top_Up_Staff_Count__c,
            recipient.Id, recipient.Email.toLowerCase(), config.Expected_Account_Id__c, config.Expected_Org_Id__c, NTEStripeClient.API_VERSION
        }))));
    }
    public static void requestTopUp(Id bookingId) {
        Opportunity booking = bookings('Id = :id', new Map<String,Object>{'id'=>bookingId}, true)[0];
        if (booking.NTE_Top_Up_Payment_Requested_At__c != null)
            throw new TopUpException('The staff top-up payment request has already been sent. Refresh to record payment when it is received.');
        Contact recipient = NTEBookingContactService.primaryContacts(new Set<Id>{bookingId}, AccessLevel.SYSTEM_MODE, true).get(bookingId);
        NTE_Stripe_Config__mdt config = configuration();
        String error = configurationError(config);
        if (error == null) error = paymentEligibility('Staff top-up', booking, recipient, config, false, convertedApplications(new Set<Id>{bookingId}).get(bookingId));
        if (error != null) throw new TopUpException(error);
        List<NTE_Payment_Request__c> found = requests('Opportunity__c = :id AND Kind__c = \'Staff top-up\'', new Map<String,Object>{'id'=>bookingId}, true);
        String snapshot = paymentFingerprint('Staff top-up', booking, recipient, config);
        NTE_Payment_Request__c payment;
        if (found.isEmpty()) {
            Decimal net = booking.NTE_Top_Up_Staff_Total__c;
            payment = new NTE_Payment_Request__c(Opportunity__c=bookingId, Kind__c='Staff top-up',
                Charge_Key__c=UserInfo.getOrganizationId()+':'+bookingId+':TopUp',
                Net_Minor__c=NTEStripeClient.toMinorUnits(net), Amount_Minor__c=NTEStripeClient.toMinorUnits(NTEVat.gross(net, booking.NTE_Top_Up_VAT_Rate__c)),
                Tax_Rate__c=NTEVat.rate(booking.NTE_Top_Up_VAT_Rate__c), Currency__c='gbp', Live_Mode__c=config.Live_Mode__c,
                Stripe_Account__c=config.Expected_Account_Id__c, Source_Fingerprint__c=snapshot,
                Source_Lead_Id__c=booking.NTE_Approval_Email_Lead_Id__c, Reference__c=booking.Booking_Reference__c,
                Description__c='NTE staff top-up · '+booking.Booking_Reference__c, First_Attempt_At__c=System.now());
        } else {
            payment = found[0];
            if (payment.Status__c == 'Sent' || payment.Delivered_At__c != null)
                throw new TopUpException('The staff top-up payment request has already been sent. Refresh to record payment when it is received.');
            if (payment.Status__c == 'Queued') throw new TopUpException('This staff top-up payment email is already queued.');
            if (payment.Source_Fingerprint__c != snapshot || payment.Live_Mode__c != config.Live_Mode__c) throw new TopUpException('The staff top-up or payment configuration has changed. Review the saved Stripe request.');
        }
        payment.Status__c='Queued'; payment.Error__c=null; payment.Recipient__c=recipient.Email;
        payment.Batch_Key__c=EncodingUtil.convertToHex(Crypto.generateAesKey(128));
        upsert payment Charge_Key__c;
        if (!(Test.isRunningTest() && suppressEnqueue)) System.enqueueJob(new TopUpWork(payment.Id, payment.Batch_Key__c));
    }
    private class TopUpWork implements Queueable, Database.AllowsCallouts {
        Id paymentId; String batch;
        TopUpWork(Id id, String batchKey) { paymentId=id; batch=batchKey; }
        public void execute(QueueableContext context) {
            System.attachFinalizer(new PaymentFinalizer(new List<Id>{paymentId}, batch));
            processPayment(paymentId, false);
            deliverTopUp(paymentId, false);
        }
    }
    @TestVisible private static void deliverTopUp(Id paymentId, Boolean bypassDelivery) {
        NTE_Payment_Request__c payment = requests('Id = :id', new Map<String,Object>{'id'=>paymentId}, false)[0];
        if (payment.Kind__c != 'Staff top-up' || payment.Status__c != 'Ready') return;
        Opportunity booking = bookings('Id = :id', new Map<String,Object>{'id'=>payment.Opportunity__c}, true)[0];
        payment = requests('Id = :id', new Map<String,Object>{'id'=>paymentId}, true)[0];
        if (payment.Status__c != 'Ready') return;
        Contact recipient = NTEBookingContactService.primaryContacts(new Set<Id>{booking.Id}, AccessLevel.SYSTEM_MODE, true).get(booking.Id);
        NTE_Stripe_Config__mdt config = configuration();
        String error = configurationError(config);
        if (error == null) error = paymentEligibility('Staff top-up', booking, recipient, config, false, convertedApplications(new Set<Id>{booking.Id}).get(booking.Id));
        if (error == null && (payment.Source_Fingerprint__c != paymentFingerprint('Staff top-up', booking, recipient, config)
            || payment.Verified_At__c == null || payment.Verified_At__c < System.now().addMinutes(-5)
            || !NTEStripeClient.validPaymentUrl(payment.Payment_URL__c, payment.Live_Mode__c))) error = 'The staff top-up payment request needs verification before sending.';
        if (error == null) {
            try {
                Messaging.SingleEmailMessage message = NTEExhibitorApprovalEmailService.renderTopUpEmail(booking, recipient, payment);
                if (!bypassDelivery) {
                    Messaging.SendEmailResult sent = Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{message}, false)[0];
                    if (!sent.isSuccess()) error = sent.getErrors()[0].getMessage();
                }
            } catch (Exception failure) { error = failure.getMessage(); }
        }
        if (error != null) { payment.Status__c='Needs review'; payment.Error__c=error; update payment; return; }
        if (payment.Delivered_At__c == null) payment.Delivered_At__c=System.now();
        payment.Recipient__c=recipient.Email; payment.Error__c=null; payment.Status__c='Sent'; update payment;
        update new Opportunity(Id=booking.Id, NTE_Top_Up_Payment_Requested_At__c=System.now());
        insert new Task(WhatId=booking.Id, Subject='NTE staff top-up payment email - sent',
            Status=[SELECT MasterLabel FROM TaskStatus WHERE IsClosed=true ORDER BY SortOrder LIMIT 1].MasterLabel,
            ActivityDate=Date.today(), Description='Recipient: '+recipient.Email+'\nPayment request: '+payment.Id);
    }
    public class TopUpException extends Exception {}
}
