@IsTest
private class NTEStripeClientTest {
    private static final String ACCOUNT = 'acct_NTETest';
    private class Mock implements HttpCalloutMock {
        String scenario; Boolean liveMode;
        Integer writes = 0;
        Integer calls = 0;
        NTEStripeClient.Charge expectedCharge = charge();
        String expectedVatMessage = 'Subtotal £800.00 + £160.00 VAT (20%). Total £960.00 including VAT.';
        Map<String, String> priceBody;
        Map<String, String> linkBody;
        List<String> idempotencyKeys = new List<String>();
        Mock(String variant) { scenario = variant; liveMode = false; }
        Mock(String variant, Boolean live) { scenario = variant; liveMode = live; }
        Mock(String variant, NTEStripeClient.Charge expected, String expectedMessage) {
            scenario = variant; liveMode = false; expectedCharge = expected; expectedVatMessage = expectedMessage;
        }
        public HttpResponse respond(HttpRequest request) {
            calls++;
            System.assertEquals('2026-08-26.dahlia', request.getHeader('Stripe-Version'));
            System.assert(request.getEndpoint().startsWith('callout:NTE_Stripe_' + (liveMode ? 'Live' : 'Test') + '/v1/'));
            if (scenario == 'timeout') throw new CalloutException('Synthetic timeout with private detail');
            String endpoint = request.getEndpoint();
            Object body;
            if (endpoint.endsWith('/account')) body = new Map<String, Object>{'id' => scenario == 'wrongAccount' ? 'acct_Other' : ACCOUNT, 'charges_enabled' => scenario != 'disabledMerchant'};
            else if (endpoint.endsWith('/balance')) body = new Map<String, Object>{'livemode' => scenario == 'live' ? !liveMode : liveMode};
            else if (endpoint.endsWith('/prices')) {
                writes++;
                System.assertEquals('POST', request.getMethod());
                idempotencyKeys.add(request.getHeader('Idempotency-Key'));
                priceBody = decode(request.getBody());
                System.assertEquals(String.valueOf(expectedCharge.amountMinor), priceBody.get('unit_amount'));
                System.assertEquals('inclusive', priceBody.get('tax_behavior'));
                body = price();
            } else if (endpoint.contains('/prices/')) body = price();
            else if (request.getMethod() == 'POST') {
                writes++;
                idempotencyKeys.add(request.getHeader('Idempotency-Key'));
                Map<String, String> values = decode(request.getBody());
                linkBody = values;
                System.assertEquals('false', values.get('invoice_creation[enabled]'));
                System.assertEquals('false', values.get('automatic_tax[enabled]'));
                System.assertEquals('false', values.get('line_items[0][adjustable_quantity][enabled]'));
                System.assertEquals('1', values.get('restrictions[completed_sessions][limit]'));
                System.assertEquals('card', values.get('payment_method_types[0]'));
                System.assertEquals('operation-one', values.get('payment_intent_data[metadata][nte_operation]'));
                System.assertEquals(expectedVatMessage, values.get('custom_text[submit][message]'));
                for (String prefix : new List<String>{'metadata', 'payment_intent_data[metadata]'}) {
                    System.assertEquals(String.valueOf(expectedCharge.netMinor), values.get(prefix + '[nte_net_minor]'));
                    System.assertEquals(String.valueOf(expectedCharge.amountMinor - expectedCharge.netMinor), values.get(prefix + '[nte_vat_minor]'));
                    System.assertEquals('20.00', values.get(prefix + '[nte_vat_rate]'));
                }
                body = link();
            } else if (endpoint.contains('/line_items')) {
                body = new Map<String, Object>{'has_more' => false, 'data' => new List<Object>{
                    new Map<String, Object>{'quantity' => 1, 'amount_total' => scenario == 'wrongAmount' ? expectedCharge.amountMinor - 1 : expectedCharge.amountMinor,
                        'amount_subtotal' => expectedCharge.amountMinor, 'currency' => 'gbp', 'price' => price(),
                        'adjustable_quantity' => new Map<String, Object>{'enabled' => scenario == 'adjustable'}}
                }};
            } else body = link();
            HttpResponse response = new HttpResponse();
            response.setStatusCode(scenario == 'forbidden' ? 403 : scenario == 'unauthorized' ? 401 : scenario == 'rateLimit' ? 429 : 200);
            response.setBody(scenario == 'forbidden' ? '{"error":{"message":"private provider content"}}'
                : scenario == 'malformed' ? 'not-json' : JSON.serialize(body));
            return response;
        }
        private Map<String, Object> price() {
            return new Map<String, Object>{'id' => 'price_Test', 'livemode' => scenario == 'priceMode' ? !liveMode : liveMode, 'active' => true,
                'currency' => 'gbp', 'unit_amount' => expectedCharge.amountMinor, 'type' => 'one_time', 'tax_behavior' => 'inclusive',
                'metadata' => new Map<String, Object>{'nte_operation' => 'operation-one'}};
        }
        private Map<String, Object> link() {
            return new Map<String, Object>{'id' => 'plink_Test', 'livemode' => scenario == 'linkMode' ? !liveMode : liveMode, 'active' => scenario != 'inactive',
                'currency' => 'gbp', 'allow_promotion_codes' => false, 'payment_method_types' => new List<String>{'card'},
                'url' => scenario == 'badUrl' ? 'https://buy.stripe.com.evil.invalid/test_Test' : 'https://buy.stripe.com/' + (liveMode ? 'LiveExample123' : 'test_Test'),
                'invoice_creation' => new Map<String, Object>{'enabled' => scenario == 'invoice'},
                'automatic_tax' => new Map<String, Object>{'enabled' => false},
                'restrictions' => new Map<String, Object>{'completed_sessions' => new Map<String, Object>{'limit' => 1}},
                'metadata' => new Map<String, Object>{'nte_operation' => 'operation-one', 'nte_booking' => 'NTE-STRIPE-ONE', 'nte_charge_kind' => 'Booking', 'nte_net_minor' => String.valueOf(expectedCharge.netMinor), 'nte_vat_minor' => scenario == 'vatMismatch' ? '1' : String.valueOf(expectedCharge.amountMinor - expectedCharge.netMinor), 'nte_vat_rate' => '20.00'},
                'custom_text' => new Map<String,Object>{'submit' => new Map<String,Object>{'message' => expectedVatMessage}}};
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
        value.chargeKind = 'Booking'; value.currencyCode = 'gbp'; value.amountMinor = 96000; value.netMinor = 80000; value.vatRate = 20;
        value.description = 'NTE2027 booking · NTE-STRIPE-ONE'; return value;
    }
    @IsTest static void completeFixedLinkContractAndStableRetries() {
        Mock mock = new Mock('normal'); Test.setMock(HttpCalloutMock.class, mock);
        NTEStripeClient client = new NTEStripeClient('NTE_Stripe_Test');
        client.verifyAccount(ACCOUNT);
        String price = client.createPrice(charge());
        String link = client.createLink(charge(), price);
        NTEStripeClient.PaymentLink verified = client.verifyLink(charge(), link, price);
        System.assertEquals(96000L, verified.amountMinor); System.assertEquals('gbp', verified.currencyCode);
        System.assertEquals('https://buy.stripe.com/test_Test', verified.url);
        client.createPrice(charge()); client.createLink(charge(), price);
        System.assertEquals(new List<String>{'operation-one:price', 'operation-one:link', 'operation-one:price', 'operation-one:link'}, mock.idempotencyKeys);
    }
    @IsTest static void inclusivePennyChargeCreatesAndVerifiesExactSavedAmounts() {
        NTEStripeClient.Charge revised = charge(); revised.netMinor = 42; revised.amountMinor = 51;
        System.assertEquals(0.50, NTEVat.gross(0.42, 20), 'This saved gross cannot be reproduced by net-first VAT rounding.');
        String expectedMessage = 'Subtotal £0.42 + £0.09 VAT (20%). Total £0.51 including VAT.';
        Mock mock = new Mock('normal', revised, expectedMessage); Test.setMock(HttpCalloutMock.class, mock);
        NTEStripeClient client = new NTEStripeClient('NTE_Stripe_Test'); client.verifyAccount(ACCOUNT);
        String price = client.createPrice(revised); String link = client.createLink(revised, price);
        NTEStripeClient.PaymentLink verified = client.verifyLink(revised, link, price);
        System.assertEquals(51L, verified.amountMinor); System.assertEquals('gbp', verified.currencyCode);
        System.assertEquals('price_Test', verified.priceId); System.assertEquals('plink_Test', verified.id);
        System.assertEquals('https://buy.stripe.com/test_Test', verified.url);
        System.assertEquals('51', mock.priceBody.get('unit_amount'));
        System.assertEquals('price_Test', mock.linkBody.get('line_items[0][price]'));
        System.assertEquals(expectedMessage, mock.linkBody.get('custom_text[submit][message]'));
        for (String prefix : new List<String>{'metadata', 'payment_intent_data[metadata]'}) {
            System.assertEquals('42', mock.linkBody.get(prefix + '[nte_net_minor]'));
            System.assertEquals('9', mock.linkBody.get(prefix + '[nte_vat_minor]'));
        }
        System.assertEquals(2, mock.writes);
        System.assertEquals(new List<String>{'operation-one:price', 'operation-one:link'}, mock.idempotencyKeys);
    }
    @IsTest static void inconsistentPennyTotalRejectsBeforeAnyResourceRequest() {
        NTEStripeClient.Charge inconsistent = charge(); inconsistent.netMinor = 41; inconsistent.amountMinor = 51;
        Mock mock = new Mock('normal'); Test.setMock(HttpCalloutMock.class, mock);
        NTEStripeClient client = new NTEStripeClient('NTE_Stripe_Test'); client.verifyAccount(ACCOUNT);
        Integer preflightCalls = mock.calls;
        for (String operation : new List<String>{'price', 'link', 'verify'}) {
            Boolean rejected = false;
            try {
                if (operation == 'price') client.createPrice(inconsistent);
                else if (operation == 'link') client.createLink(inconsistent, 'price_Test');
                else client.verifyLink(inconsistent, 'plink_Test', 'price_Test');
            } catch (NTEStripeClient.StripeException expected) {
                rejected = true; System.assertEquals('The Stripe charge configuration is invalid.', expected.getMessage());
            }
            System.assert(rejected, operation); System.assertEquals(preflightCalls, mock.calls, operation);
        }
        System.assertEquals(0, mock.writes);
    }
    @IsTest static void minimumGbpChargeAcceptsThirtyPenceAndRejectsTwentyNine() {
        NTEStripeClient.Charge belowMinimum = charge(); belowMinimum.netMinor = 24; belowMinimum.amountMinor = 29;
        System.assert(NTEVat.consistentTotal(0.24, 20, 0.29), 'The rejected amount must have a valid VAT breakdown.');
        Mock rejectedMock = new Mock('normal'); Test.setMock(HttpCalloutMock.class, rejectedMock);
        NTEStripeClient client = new NTEStripeClient('NTE_Stripe_Test'); client.verifyAccount(ACCOUNT);
        Integer preflightCalls = rejectedMock.calls; Boolean rejected = false;
        try { client.createPrice(belowMinimum); }
        catch (NTEStripeClient.StripeException expected) {
            rejected = true; System.assertEquals('The Stripe charge configuration is invalid.', expected.getMessage());
        }
        System.assert(rejected); System.assertEquals(preflightCalls, rejectedMock.calls); System.assertEquals(0, rejectedMock.writes);

        NTEStripeClient.Charge minimum = charge(); minimum.netMinor = 25; minimum.amountMinor = 30;
        Mock acceptedMock = new Mock('normal', minimum, 'Subtotal £0.25 + £0.05 VAT (20%). Total £0.30 including VAT.');
        Test.setMock(HttpCalloutMock.class, acceptedMock);
        String price = client.createPrice(minimum); String link = client.createLink(minimum, price);
        NTEStripeClient.PaymentLink verified = client.verifyLink(minimum, link, price);
        System.assertEquals(30L, verified.amountMinor); System.assertEquals('30', acceptedMock.priceBody.get('unit_amount'));
        System.assertEquals('25', acceptedMock.linkBody.get('metadata[nte_net_minor]'));
        System.assertEquals('5', acceptedMock.linkBody.get('metadata[nte_vat_minor]'));
        System.assertEquals(2, acceptedMock.writes);
    }
    @IsTest static void noWritesUntilAccountAndModeAreVerified() {
        for (String scenario : new List<String>{'wrongAccount', 'live', 'forbidden', 'unauthorized', 'rateLimit', 'timeout', 'malformed'}) {
            Mock mock = new Mock(scenario); Test.setMock(HttpCalloutMock.class, mock);
            NTEStripeClient client = new NTEStripeClient('NTE_Stripe_Test'); Boolean failed = false;
            try { client.verifyAccount(ACCOUNT); client.createPrice(charge()); }
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
        for (String scenario : new List<String>{'vatMismatch', 'inactive', 'invoice', 'badUrl', 'wrongAmount', 'adjustable', 'priceMode', 'linkMode'}) {
            Test.setMock(HttpCalloutMock.class, new Mock(scenario));
            NTEStripeClient client = new NTEStripeClient('NTE_Stripe_Test'); client.verifyAccount(ACCOUNT);
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
            'https://buy.stripe.com/test_123?amount=1', 'https://attacker@buy.stripe.com/test_123'}) System.assert(!NTEStripeClient.validPaymentUrl(url, false));
    }

    @IsTest static void verifiedLiveAccountCreatesTheSameFixedPaymentContract() {
        Mock mock = new Mock('normal', true); Test.setMock(HttpCalloutMock.class, mock);
        NTEStripeClient client = new NTEStripeClient('NTE_Stripe_Live'); client.verifyAccount(ACCOUNT);
        String price = client.createPrice(charge()); String link = client.createLink(charge(), price);
        NTEStripeClient.PaymentLink verified = client.verifyLink(charge(), link, price);
        System.assertEquals('https://buy.stripe.com/LiveExample123', verified.url);
        System.assertEquals(96000L, verified.amountMinor); System.assertEquals(2, mock.writes);
        System.assert(NTEStripeClient.validPaymentUrl(verified.url, true));
        System.assert(!NTEStripeClient.validPaymentUrl(verified.url, false));
        System.assert(!NTEStripeClient.validPaymentUrl('https://buy.stripe.com/test_Test', true));
    }
    @IsTest static void liveConfigurationRejectsWrongModeAndUnavailableMerchant() {
        for (String variant : new List<String>{'live', 'disabledMerchant', 'wrongAccount'}) {
            Mock mock = new Mock(variant, true); Test.setMock(HttpCalloutMock.class, mock);
            Boolean rejected = false;
            try { NTEStripeClient client = new NTEStripeClient('NTE_Stripe_Live'); client.verifyAccount(ACCOUNT); client.createPrice(charge()); }
            catch (NTEStripeClient.StripeException expected) { rejected = true; }
            System.assert(rejected, variant); System.assertEquals(0, mock.writes);
        }
    }
}
