"""Offline release signing tests using throwaway keys only."""
import base64
import importlib.util
from pathlib import Path
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[2]
spec = importlib.util.spec_from_file_location(
    "payback_release_signing", ROOT / "scripts/check-update-signing-key.py"
)
checker = importlib.util.module_from_spec(spec)
spec.loader.exec_module(checker)


class ReleaseSigningTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.private_der = subprocess.check_output(
            ["openssl", "genpkey", "-algorithm", "ED25519", "-outform", "DER"])
        cls.public_der = subprocess.check_output(
            ["openssl", "pkey", "-inform", "DER", "-pubout", "-outform", "DER"],
            input=cls.private_der)

    def test_matching_key(self):
        checker.verify(self.private_der, self.public_der)
        checker.verify_secret(base64.b64encode(self.private_der).decode(), self.public_der)

    def test_wrong_key(self):
        other = subprocess.check_output(
            ["openssl", "genpkey", "-algorithm", "ED25519", "-outform", "DER"])
        with self.assertRaisesRegex(ValueError, "does not match"):
            checker.verify(other, self.public_der)

    def test_missing_or_invalid_keys(self):
        for data in (b"", b"not a key"):
            with self.subTest(data=data), self.assertRaises(ValueError):
                checker.verify(data, self.public_der)
        for encoded in ("", "not base64 !"):
            with self.subTest(encoded=encoded), self.assertRaises(ValueError):
                checker.verify_secret(encoded, self.public_der)

    def test_embedded_public_key_parser(self):
        encoded = base64.b64encode(self.public_der).decode()
        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp) / "version.rkt"
            path.write_text('(define update-public-key-b64\n  "' + encoded + '")')
            self.assertEqual(checker.trusted_public_key(path), self.public_der)
            path.write_text('(define update-public-key-b64 "Zm9v")')
            with self.assertRaisesRegex(ValueError, "not Ed25519"):
                checker.trusted_public_key(path)

    def test_canonical_manifest_origin(self):
        script = (ROOT / "scripts/make-update-manifest.sh").read_text()
        self.assertIn("https://github.com/turlamai/payback/releases/download/$TAG", script)
        self.assertNotIn("turinglambdaai/payback/releases/download", script)


if __name__ == "__main__":
    unittest.main()
