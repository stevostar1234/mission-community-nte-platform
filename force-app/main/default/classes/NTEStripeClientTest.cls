@IsTest
private class NTEStripeClientTest {
    private static final String ACCOUNT = 'acct_NTETest';
    private class Mock implements HttpCalloutMock {
        String scenario;
        Integer writes = 0;
        List<String> idempotencyKeys = new List<String>();
        Mock(String variant) { scenario = variant; }
        public HttpResponse respond(HttpRequest request) {
            System.assertEquals('2026-08-26.dahlia', request.getHeader('Stripe-Version'));
            System.assert(request.getEndpoint().startsWith('callout:NTE_Stripe_Test/v1/'));
            String endpoint = request.getEndpoint();
            Object body;
            if (endpoint.endsWith('/account')) body = new Map<String, Object>{'id' => scenario == 'wrongAccount' ? 'acct_Other' : ACCOUNT};
            else if (endpoint.endsWith('/balance')) body = new Map<String, Object>{'livemode' => scenario == 'live'};
            else if (endpoint.endsWith('/prices')) {
                writes++;
                System.assertEquals('POST', request.getMethod());
                idempotencyKeys.add(request.getHeader('Idempotency-Key'));
                System.assert(request.getBody().contains('unit_amount=96000'));
                body = price();
            } else if (endpoint.contains('/prices/')) body = price();
            else if (request.getMethod() == 'POST') {
                writes++;
                idempotencyKeys.add(request.getHeader('Idempotency-Key'));
                Map<String, String> values = decode(request.getBody());
                System.assertEquals('false', values.get('invoice_creation[enabled]'));
                System.assertEquals('false', values.get('automatic_tax[enabled]'));
                System.assertEquals('false', values.get('line_items[0][adjustable_quantity][enabled]'));
                System.assertEquals('1', values.get('restrictions[completed_sessions][limit]'));
                System.assertEquals('card', values.get('payment_method_types[0]'));
                System.assertEquals('operation-one', values.get('payment_intent_data[metadata][nte_operation]'));
                body = link();
            } else if (endpoint.contains('/line_items')) {
                body = new Map<String, Object>{'has_more' => false, 'data' => new List<Object>{
                    new Map<String, Object>{'quantity' => 1, 'amount_total' => scenario == 'wrongAmount' ? 95999 : 96000,
                        'amount_subtotal' => 96000, 'currency' => 'gbp', 'price' => price(),
                        'adjustable_quantity' => new Map<String, Object>{'enabled' => scenario == 'adjustable'}}
                }};
            } else body = link();
            HttpResponse response = new HttpResponse();
            response.setStatusCode(scenario == 'forbidden' ? 403 : 200);
            response.setBody(scenario == 'forbidden' ? '{"error":{"message":"private provider content"}}'
                : scenario == 'malformed' ? 'not-json' : JSON.serialize(body));
            return response;
        }
        private Map<String, Object> price() {
            return new Map<String, Object>{'id' => 'price_Test', 'livemode' => false, 'active' => true,
                'currency' => 'gbp', 'unit_amount' => 96000, 'type' => 'one_time', 'tax_behavior' => 'inclusive',
                'metadata' => new Map<String, Object>{'nte_operation' => 'operation-one'}};
        }
        private Map<String, Object> link() {
            return new Map<String, Object>{'id' => 'plink_Test', 'livemode' => false, 'active' => scenario != 'inactive',
                'currency' => 'gbp', 'allow_promotion_codes' => false, 'payment_method_types' => new List<String>{'card'},
                'url' => scenario == 'badUrl' ? 'https://buy.stripe.com.evil.invalid/test_Test' : 'https://buy.stripe.com/test_Test',
                'invoice_creation' => new Map<String, Object>{'enabled' => scenario == 'invoice'},
                'automatic_tax' => new Map<String, Object>{'enabled' => false},
                'restrictions' => new Map<String, Object>{'completed_sessions' => new Map<String, Object>{'limit' => 1}},
                'metadata' => new Map<String, Object>{'nte_operation' => 'operation-one', 'nte_booking' => 'NTE-STRIPE-ONE', 'nte_charge_kind' => 'Booking'}};
        }
    }
    private static Map<String, String> decode(String body) {
        Map<String, String> values = new Map<String, String>();
        for (String pair : body.split('&')) {
            List<String> parts = pair.split('=', 2);
            values.put(EncodingUtil.urlDecode(parts[0], 'UTF-8'), EncodingUtil.urlDecode(parts[1], 'UTF-8'));
        }
        return values;
    }
    private static NTEStripeClient.Charge charge() {
        NTEStripeClient.Charge value = new NTEStripeClient.Charge();
        value.accountId = ACCOUNT; value.operationKey = 'operation-one'; value.bookingReference = 'NTE-STRIPE-ONE';
        value.chargeKind = 'Booking'; value.currencyCode = 'gbp'; value.amountMinor = 96000;
        value.description = 'NTE2027 booking · NTE-STRIPE-ONE'; return value;
    }
    @IsTest static void completeFixedLinkContractAndStableRetries() {
        Mock mock = new Mock('normal'); Test.setMock(HttpCalloutMock.class, mock);
        NTEStripeClient client = new NTEStripeClient('NTE_Stripe_Test');
        client.verifyTestAccount(ACCOUNT);
        String price = client.createPrice(charge());
        String link = client.createLink(charge(), price);
        NTEStripeClient.PaymentLink verified = client.verifyLink(charge(), link, price);
        System.assertEquals(96000L, verified.amountMinor); System.assertEquals('gbp', verified.currencyCode);
        System.assertEquals('https://buy.stripe.com/test_Test', verified.url);
        client.createPrice(charge()); client.createLink(charge(), price);
        System.assertEquals(new List<String>{'operation-one:price', 'operation-one:link', 'operation-one:price', 'operation-one:link'}, mock.idempotencyKeys);
    }
    @IsTest static void noWritesUntilAccountAndModeAreVerified() {
        for (String scenario : new List<String>{'wrongAccount', 'live', 'forbidden', 'malformed'}) {
            Mock mock = new Mock(scenario); Test.setMock(HttpCalloutMock.class, mock);
            NTEStripeClient client = new NTEStripeClient('NTE_Stripe_Test'); Boolean failed = false;
            try { client.verifyTestAccount(ACCOUNT); client.createPrice(charge()); }
            catch (NTEStripeClient.StripeException failure) {
                failed = true; System.assert(!failure.getMessage().contains('private provider content'));
            }
            System.assert(failed, scenario); System.assertEquals(0, mock.writes, scenario);
        }
        Boolean missingPreflight = false;
        try { new NTEStripeClient('NTE_Stripe_Test').createPrice(charge()); }
        catch (NTEStripeClient.StripeException expected) { missingPreflight = true; }
        System.assert(missingPreflight);
    }
    @IsTest static void changedLinkCannotBeUsedInAnEmail() {
        for (String scenario : new List<String>{'inactive', 'invoice', 'badUrl', 'wrongAmount', 'adjustable'}) {
            Test.setMock(HttpCalloutMock.class, new Mock(scenario));
            NTEStripeClient client = new NTEStripeClient('NTE_Stripe_Test'); client.verifyTestAccount(ACCOUNT);
            Boolean rejected = false;
            try { client.verifyLink(charge(), 'plink_Test', 'price_Test'); }
            catch (NTEStripeClient.StripeException expected) { rejected = true; }
            System.assert(rejected, scenario);
        }
    }
    @IsTest static void exactPenceAndUrlBoundaries() {
        System.assertEquals(96000L, NTEStripeClient.toMinorUnits(960));
        System.assertEquals(31L, NTEStripeClient.toMinorUnits(0.31));
        for (Decimal value : new List<Decimal>{null, 0, -1, 0.001, 1000000}) {
            Boolean rejected = false;
            try { NTEStripeClient.toMinorUnits(value); } catch (NTEStripeClient.StripeException expected) { rejected = true; }
            System.assert(rejected);
        }
        for (String url : new List<String>{null, 'http://buy.stripe.com/test_123', 'https://buy.stripe.com/live_123',
            'https://buy.stripe.com/test_123?amount=1', 'https://attacker@buy.stripe.com/test_123'}) System.assert(!NTEStripeClient.validTestUrl(url));
    }
}
