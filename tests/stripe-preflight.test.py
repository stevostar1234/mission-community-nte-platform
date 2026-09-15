import importlib.util
from pathlib import Path
import unittest

spec = importlib.util.spec_from_file_location("stripe_preflight", Path(__file__).resolve().parents[1] / "scripts/stripe-preflight.py")
subject = importlib.util.module_from_spec(spec)
spec.loader.exec_module(subject)


class PreflightTests(unittest.TestCase):
    def setUp(self):
        self.config = {"environment": "test", "expected_account_id": "acct_Fixture"}
        self.calls = []

    def fetch(self, endpoint):
        self.calls.append(endpoint)
        return {"id": "acct_Fixture", "country": "GB", "default_currency": "gbp"} if endpoint == "/v1/account" else {"livemode": False}

    def test_verified_account_exposes_no_key_or_payment_claim(self):
        result = subject.verify(self.config, "rk_test_synthetic", self.fetch)
        self.assertTrue(result["verified"])
        self.assertFalse(result["payment_links_tested"])
        self.assertFalse(result["salesforce_connected"])
        self.assertNotIn("synthetic", str(result))
        self.assertEqual(["/v1/account", "/v1/balance"], self.calls)

    def test_wrong_environment_and_publishable_keys_are_rejected_before_network(self):
        for key in ["sk_live_synthetic", "rk_live_synthetic", "pk_test_synthetic", "", "rk_test_bad\nvalue"]:
            with self.subTest(key_type=key[:7]), self.assertRaises(subject.PreflightError):
                subject.verify(self.config, key, self.fetch)
        self.assertEqual([], self.calls)

    def test_wrong_account_prevents_further_requests(self):
        self.config["expected_account_id"] = "acct_Different"
        with self.assertRaises(subject.PreflightError):
            subject.verify(self.config, "rk_test_synthetic", self.fetch)
        self.assertEqual(["/v1/account"], self.calls)

    def test_live_or_unknown_mode_is_rejected(self):
        for mode in [True, None, 0, "false"]:
            def fetch(endpoint):
                return {"id": "acct_Fixture"} if endpoint == "/v1/account" else {"livemode": mode}
            with self.subTest(mode=mode), self.assertRaises(subject.PreflightError):
                subject.verify(self.config, "rk_test_synthetic", fetch)

    def test_configuration_requires_known_mode_and_account(self):
        for replacement in [{"environment": "unknown"}, {"expected_account_id": None}]:
            with self.subTest(replacement=replacement), self.assertRaises(subject.PreflightError):
                subject.verify(self.config | replacement, "rk_test_synthetic", self.fetch)
        self.assertEqual([], self.calls)


    def test_live_account_is_verified_without_creating_resources(self):
        self.config["environment"] = "live"
        def fetch(endpoint):
            self.calls.append(endpoint)
            return {"id": "acct_Fixture", "charges_enabled": True} if endpoint == "/v1/account" else {"livemode": True}
        result = subject.verify(self.config, "rk_live_synthetic", fetch)
        self.assertTrue(result["livemode"])
        self.assertFalse(result["payment_links_tested"])
        self.assertEqual(["/v1/account", "/v1/balance"], self.calls)

    def test_live_account_requires_live_mode_and_payment_capability(self):
        self.config["environment"] = "live"
        for mode, enabled in [(False, True), (True, False), (None, True), (True, None)]:
            def fetch(endpoint):
                return {"id": "acct_Fixture", "charges_enabled": enabled} if endpoint == "/v1/account" else {"livemode": mode}
            with self.subTest(mode=mode, enabled=enabled), self.assertRaises(subject.PreflightError):
                subject.verify(self.config, "rk_live_synthetic", fetch)


if __name__ == "__main__":
    unittest.main()
