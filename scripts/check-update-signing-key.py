#!/usr/bin/env python3
"""Fail closed unless the release Ed25519 key matches Payback's updater trust root."""
import base64
import binascii
import hmac
import os
from pathlib import Path
import re
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[1]
SPKI_PREFIX = bytes.fromhex("302a300506032b6570032100")


def trusted_public_key(source_path=ROOT / "app/version.rkt"):
    source = Path(source_path).read_text(encoding="utf-8")
    match = re.search(r'\(define\s+update-public-key-b64\s+"([A-Za-z0-9+/=]+)"\s*\)', source)
    if not match:
        raise ValueError("missing embedded updater public key")
    try:
        der = base64.b64decode(match.group(1), validate=True)
    except (binascii.Error, ValueError) as exc:
        raise ValueError("invalid embedded updater public key") from exc
    if len(der) != 44 or not der.startswith(SPKI_PREFIX):
        raise ValueError("embedded updater key is not Ed25519 SPKI DER")
    return der


def verify(private_der, expected_public_der):
    if not private_der:
        raise ValueError("missing release Ed25519 private key")
    result = subprocess.run(
        ["openssl", "pkey", "-inform", "DER", "-pubout", "-outform", "DER"],
        input=private_der, stdout=subprocess.PIPE, stderr=subprocess.PIPE, check=False,
    )
    if result.returncode != 0 or not result.stdout:
        raise ValueError("invalid release Ed25519 private key")
    if not hmac.compare_digest(result.stdout, expected_public_der):
        raise ValueError("release Ed25519 key does not match app/version.rkt")


def verify_secret(encoded, expected_public_der):
    if not encoded:
        raise ValueError("missing UPDATE_ED25519_PRIVATE_KEY_B64")
    try:
        private_der = base64.b64decode(encoded, validate=True)
    except (binascii.Error, ValueError) as exc:
        raise ValueError("invalid base64 release signing key") from exc
    verify(private_der, expected_public_der)


def main():
    try:
        verify_secret(os.environ.get("UPDATE_ED25519_PRIVATE_KEY_B64", ""),
                      trusted_public_key())
    except (ValueError, OSError) as exc:
        print(f"::error::{exc}", file=sys.stderr)
        return 1
    print("Ed25519 release key matches embedded updater trust root")
    return 0


if __name__ == "__main__":
    sys.exit(main())
