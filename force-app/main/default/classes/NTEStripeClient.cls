/** Server-side Payment Links contract. Credentials are supplied by the Named Credential. */
public without sharing class NTEStripeClient {
    public static final String API_VERSION = '2026-08-26.dahlia';
    public class StripeException extends Exception {}
    public class Charge {
        public String accountId;
        public String operationKey;
        public String bookingReference;
        public String chargeKind;
        public String currencyCode;
        public Long amountMinor;
        public String description;
    }
    public class PaymentLink {
        public String id;
        public String url;
        public String priceId;
        public Long amountMinor;
        public String currencyCode;
    }

    private String credentialName;
    private String verifiedAccountId;
    public NTEStripeClient(String credential) {
        if (credential != 'NTE_Stripe_Test') throw new StripeException('The Stripe test credential is required.');
        credentialName = credential;
    }

    // This release deliberately has no live-mode path. Read-only checks precede all writes.
    public void verifyTestAccount(String expectedAccountId) {
        verifiedAccountId = null;
        if (String.isBlank(expectedAccountId) || !Pattern.matches('^acct_[A-Za-z0-9]+$', expectedAccountId)) {
            throw new StripeException('The expected Stripe account is missing or invalid.');
        }
        Map<String, Object> account = request('GET', '/v1/account', null, null);
        if (account.get('id') != expectedAccountId) throw new StripeException('The Stripe account does not match this configuration.');
        Map<String, Object> balance = request('GET', '/v1/balance', null, null);
        if (balance.get('livemode') != false) throw new StripeException('Stripe test mode could not be verified.');
        verifiedAccountId = expectedAccountId;
    }

    public String createPrice(Charge charge) {
        validateCharge(charge);
        requireVerifiedAccount(charge);
        Map<String, String> values = new Map<String, String>{
            'currency' => charge.currencyCode, 'unit_amount' => String.valueOf(charge.amountMinor),
            'tax_behavior' => 'inclusive', 'product_data[name]' => charge.description,
            'metadata[nte_operation]' => charge.operationKey,
            'metadata[nte_booking]' => charge.bookingReference,
            'metadata[nte_charge_kind]' => charge.chargeKind
        };
        Map<String, Object> price = request('POST', '/v1/prices', values, charge.operationKey + ':price');
        verifyPrice(charge, price, null);
        return (String)price.get('id');
    }

    public String createLink(Charge charge, String priceId) {
        validateCharge(charge);
        requireVerifiedAccount(charge);
        requireId(priceId, 'price_');
        verifyPrice(charge, request('GET', '/v1/prices/' + priceId, null, null), priceId);
        Map<String, String> values = new Map<String, String>{
            'line_items[0][price]' => priceId, 'line_items[0][quantity]' => '1',
            'line_items[0][adjustable_quantity][enabled]' => 'false',
            'payment_method_types[0]' => 'card', 'allow_promotion_codes' => 'false',
            'automatic_tax[enabled]' => 'false', 'invoice_creation[enabled]' => 'false',
            'billing_address_collection' => 'auto', 'customer_creation' => 'if_required',
            'restrictions[completed_sessions][limit]' => '1', 'submit_type' => 'pay',
            'after_completion[type]' => 'hosted_confirmation',
            'after_completion[hosted_confirmation][custom_message]' => 'Thank you. The NTE team will confirm your payment and update your booking.',
            'inactive_message' => 'This payment link is no longer available. Please contact the NTE team.',
            'metadata[nte_operation]' => charge.operationKey,
            'metadata[nte_booking]' => charge.bookingReference,
            'metadata[nte_charge_kind]' => charge.chargeKind,
            'payment_intent_data[metadata][nte_operation]' => charge.operationKey,
            'payment_intent_data[metadata][nte_booking]' => charge.bookingReference,
            'payment_intent_data[metadata][nte_charge_kind]' => charge.chargeKind,
            'payment_intent_data[description]' => charge.description
        };
        Map<String, Object> link = request('POST', '/v1/payment_links', values, charge.operationKey + ':link');
        requireId((String)link.get('id'), 'plink_');
        if (link.get('livemode') != false) throw new StripeException('Stripe returned a payment link outside test mode.');
        return (String)link.get('id');
    }

    public PaymentLink verifyLink(Charge charge, String linkId, String priceId) {
        validateCharge(charge);
        requireVerifiedAccount(charge);
        requireId(linkId, 'plink_'); requireId(priceId, 'price_');
        Map<String, Object> link = request('GET', '/v1/payment_links/' + linkId, null, null);
        if (link.get('id') != linkId || link.get('livemode') != false || link.get('active') != true
            || link.get('currency') != charge.currencyCode || link.get('allow_promotion_codes') != false
            || objectValue(link, 'invoice_creation').get('enabled') != false
            || objectValue(link, 'automatic_tax').get('enabled') != false
            || objectValue(link, 'metadata').get('nte_operation') != charge.operationKey
            || objectValue(link, 'metadata').get('nte_booking') != charge.bookingReference
            || objectValue(link, 'metadata').get('nte_charge_kind') != charge.chargeKind) {
            throw new StripeException('The saved Stripe link no longer matches the booking charge.');
        }
        List<Object> methods = (List<Object>)link.get('payment_method_types');
        if (methods == null || methods.size() != 1 || methods[0] != 'card') throw new StripeException('The Stripe payment methods have changed.');
        if (longValue(objectValue(objectValue(link, 'restrictions'), 'completed_sessions').get('limit')) != 1) {
            throw new StripeException('The Stripe link does not have the required payment limit.');
        }
        String url = (String)link.get('url');
        if (!validTestUrl(url)) throw new StripeException('The Stripe payment URL is invalid.');
        Map<String, Object> lines = request('GET', '/v1/payment_links/' + linkId + '/line_items?limit=2', null, null);
        List<Object> data = (List<Object>)lines.get('data');
        if (lines.get('has_more') != false || data == null || data.size() != 1) throw new StripeException('The Stripe link contains unexpected line items.');
        Map<String, Object> line = (Map<String, Object>)data[0];
        if (longValue(line.get('quantity')) != 1 || longValue(line.get('amount_total')) != charge.amountMinor
            || longValue(line.get('amount_subtotal')) != charge.amountMinor || line.get('currency') != charge.currencyCode
            || objectValue(line, 'adjustable_quantity').get('enabled') != false) {
            throw new StripeException('The Stripe total does not match the saved amount.');
        }
        Map<String, Object> price = objectValue(line, 'price');
        verifyPrice(charge, price, priceId);
        PaymentLink result = new PaymentLink();
        result.id = linkId; result.url = url; result.priceId = priceId;
        result.amountMinor = charge.amountMinor; result.currencyCode = charge.currencyCode;
        return result;
    }

    public static Long toMinorUnits(Decimal amount) {
        if (amount == null || amount <= 0 || amount != amount.setScale(2) || amount * 100 > 99999999) {
            throw new StripeException('A positive GBP amount with no more than two decimal places is required.');
        }
        return (amount * 100).longValue();
    }
    public static Boolean validTestUrl(String value) {
        if (String.isBlank(value) || value.length() > 255 || Pattern.compile('[\\s\\p{Cntrl}]').matcher(value).find()) return false;
        try {
            Url url = new Url(value);
            return url.getProtocol() == 'https' && url.getHost() == 'buy.stripe.com'
                && String.isBlank(url.getUserInfo()) && url.getPort() == -1
                && Pattern.matches('^/test_[A-Za-z0-9]+$', url.getPath())
                && String.isBlank(url.getQuery()) && String.isBlank(url.getRef());
        } catch (Exception invalidUrl) { return false; }
    }
    private static void validateCharge(Charge charge) {
        if (charge == null || String.isBlank(charge.operationKey) || charge.operationKey.length() > 100
            || !Pattern.matches('^[A-Za-z0-9:_-]+$', charge.operationKey)
            || String.isBlank(charge.bookingReference) || charge.bookingReference.length() > 80
            || (charge.chargeKind != 'Booking' && charge.chargeKind != 'Staff top-up')
            || charge.currencyCode != 'gbp' || charge.amountMinor == null || charge.amountMinor < 30 || charge.amountMinor > 99999999
            || String.isBlank(charge.description) || charge.description.length() > 250) {
            throw new StripeException('The Stripe charge configuration is invalid.');
        }
    }
    private void requireVerifiedAccount(Charge charge) {
        if (verifiedAccountId == null || charge.accountId != verifiedAccountId) {
            throw new StripeException('Verify the configured Stripe test account before accessing a payment request.');
        }
    }
    private static void verifyPrice(Charge charge, Map<String, Object> price, String expectedId) {
        requireId((String)price.get('id'), 'price_');
        if ((expectedId != null && price.get('id') != expectedId) || price.get('livemode') != false
            || price.get('active') != true || price.get('type') != 'one_time'
            || price.get('currency') != charge.currencyCode || longValue(price.get('unit_amount')) != charge.amountMinor
            || price.get('tax_behavior') != 'inclusive'
            || objectValue(price, 'metadata').get('nte_operation') != charge.operationKey) {
            throw new StripeException('The Stripe price does not match the saved charge.');
        }
    }
    private static void requireId(String value, String prefix) {
        if (String.isBlank(value) || !Pattern.matches('^' + prefix + '[A-Za-z0-9]+$', value)) throw new StripeException('Stripe returned an invalid resource identifier.');
    }
    private static Map<String, Object> objectValue(Map<String, Object> source, String key) {
        Object value = source.get(key);
        return value instanceof Map<String, Object> ? (Map<String, Object>)value : new Map<String, Object>();
    }
    private static Long longValue(Object value) {
        if (value == null) return null;
        Decimal numeric = Decimal.valueOf(String.valueOf(value));
        return numeric == numeric.setScale(0) ? numeric.longValue() : null;
    }
    private Map<String, Object> request(String method, String path, Map<String, String> values, String idempotencyKey) {
        HttpRequest request = new HttpRequest();
        request.setEndpoint('callout:' + credentialName + path);
        request.setMethod(method); request.setTimeout(20000);
        request.setHeader('Stripe-Version', API_VERSION);
        if (idempotencyKey != null) request.setHeader('Idempotency-Key', idempotencyKey);
        if (values != null) {
            request.setHeader('Content-Type', 'application/x-www-form-urlencoded');
            List<String> keys = new List<String>(values.keySet()); keys.sort();
            List<String> pairs = new List<String>();
            for (String key : keys) pairs.add(EncodingUtil.urlEncode(key, 'UTF-8') + '=' + EncodingUtil.urlEncode(values.get(key), 'UTF-8'));
            request.setBody(String.join(pairs, '&'));
        }
        HttpResponse response;
        try { response = new Http().send(request); }
        catch (Exception transportError) { throw new StripeException('Stripe could not be reached. Reconcile or retry this same payment request.'); }
        if (response.getStatusCode() < 200 || response.getStatusCode() >= 300) {
            // Provider bodies can contain credentials or payer details; never persist them in a booking error.
            throw new StripeException('Stripe returned HTTP ' + response.getStatusCode() + '. Check the connection and this request in Stripe.');
        }
        try { return (Map<String, Object>)JSON.deserializeUntyped(response.getBody()); }
        catch (Exception invalidResponse) { throw new StripeException('Stripe returned an unreadable response. Reconcile this same payment request.'); }
    }
}
