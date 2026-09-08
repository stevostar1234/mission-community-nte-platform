#!/usr/bin/env python3
"""Read-only Stripe test-account verification. Never prints or persists the supplied key."""
import argparse
import getpass
import json
import os
from pathlib import Path
import re
import stat
import sys
import urllib.error
import urllib.request

API_VERSION = "2026-08-26.dahlia"


class PreflightError(Exception):
    pass


class NoRedirect(urllib.request.HTTPRedirectHandler):
    def redirect_request(self, req, fp, code, msg, headers, newurl):
        raise PreflightError("Stripe returned a redirect; no credential was forwarded.")


def verify(config, key, fetch=None):
    if config.get("environment") != "test" or config.get("production_activation_allowed") is not False:
        raise PreflightError("This preflight accepts a test configuration with production activation disabled.")
    account_id = config.get("expected_account_id", "")
    if not isinstance(account_id, str) or not re.fullmatch(r"acct_[A-Za-z0-9]+", account_id):
        raise PreflightError("Set the expected Stripe sandbox account ID before connecting.")
    if not re.fullmatch(r"(?:sk_test_|rk_test_|rkcs_test_)[A-Za-z0-9_-]+", key):
        raise PreflightError("A Stripe secret or restricted test key is required. Live and publishable keys are rejected.")

    def stripe_get(endpoint):
        request = urllib.request.Request(
            "https://api.stripe.com" + endpoint,
            headers={"Authorization": "Bearer " + key, "Stripe-Version": API_VERSION},
            method="GET",
        )
        try:
            with urllib.request.build_opener(NoRedirect()).open(request, timeout=20) as response:
                result = json.load(response)
                if not isinstance(result, dict):
                    raise PreflightError("Stripe returned an unexpected response.")
                return result
        except urllib.error.HTTPError as error:
            # Error responses can repeat key fragments. Do not print the body or exception.
            raise PreflightError(f"Stripe returned HTTP {error.code}. Check test-key permissions; claimable keys cannot access all endpoints.") from None
        except (urllib.error.URLError, TimeoutError, ValueError):
            raise PreflightError("The Stripe response could not be verified. No settings or payments were changed.") from None

    read = fetch or stripe_get
    account = read("/v1/account")
    if account.get("id") != account_id:
        raise PreflightError("The key belongs to a different Stripe account.")
    balance = read("/v1/balance")
    if balance.get("livemode") is not False:
        raise PreflightError("Stripe test mode was not verified.")
    return {
        "verified": True, "account_id": account_id, "livemode": False,
        "country": account.get("country"), "default_currency": account.get("default_currency"),
        "charges_enabled": account.get("charges_enabled"), "api_version": API_VERSION,
        "payment_links_tested": False, "salesforce_connected": False,
    }


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--config", required=True, type=Path)
    parser.add_argument("--key-file", type=Path, help="Optional private file containing only the test key; otherwise enter it invisibly.")
    parser.add_argument("--output", type=Path, help="Optional destination for the non-secret verification result.")
    args = parser.parse_args()
    try:
        if args.key_file:
            if args.key_file.is_symlink():
                raise PreflightError("Use a private key file, not a symbolic link.")
            info = args.key_file.stat()
            if not stat.S_ISREG(info.st_mode) or info.st_uid != os.getuid() or stat.S_IMODE(info.st_mode) & 0o077:
                raise PreflightError("The key file must belong to you and have owner-only permissions, such as 0600.")
            key = args.key_file.read_text().strip()
        else:
            if not sys.stdin.isatty():
                raise PreflightError("Use an interactive terminal or an owner-only key file; never put the key in command arguments.")
            key = getpass.getpass("Stripe test key (hidden): ").strip()
        result = verify(json.loads(args.config.read_text()), key)
        rendered = json.dumps(result, indent=2) + "\n"
        if args.output:
            args.output.write_text(rendered)
        print(rendered, end="")
    except (PreflightError, OSError, ValueError) as error:
        message = str(error) if isinstance(error, PreflightError) else "The configuration or private key file could not be read."
        print(json.dumps({"verified": False, "error": message}), file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
