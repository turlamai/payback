"""Offline negative tests for the packaged macOS Cmd+Q rescue exception."""

import json
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
GUARD = ROOT / "scripts" / "e2e" / "check_macos_rescue.py"
E2E = ROOT / "scripts" / "e2e" / "e2e-macos.sh"


class MacOSRescueGuardTests(unittest.TestCase):
    def check_trace(self, payload=None):
        with tempfile.TemporaryDirectory() as folder:
            trace = Path(folder) / "trace.json"
            if payload is not None:
                trace.write_text(payload, encoding="utf-8")
            return subprocess.run(
                [sys.executable, str(GUARD), str(trace)],
                capture_output=True,
                check=False,
            ).returncode

    def test_only_explicit_boolean_true_allows_rescue(self):
        self.assertEqual(
            self.check_trace(json.dumps({
                "observations": {"correction-dismissal-observed": True}
            })),
            0,
        )

    def test_false_missing_or_truthy_string_cannot_bypass_cmdq(self):
        for payload in (
            {},
            {"observations": {}},
            {"observations": {"correction-dismissal-observed": False}},
            {"observations": {"correction-dismissal-observed": "true"}},
            {"observations": None},
            [],
        ):
            with self.subTest(payload=payload):
                self.assertEqual(self.check_trace(json.dumps(payload)), 1)

    def test_missing_or_corrupt_trace_fails_closed(self):
        self.assertEqual(self.check_trace(), 1)
        self.assertEqual(self.check_trace("{invalid-json"), 1)

    def test_strict_shell_guard_is_wired_and_parses(self):
        script = E2E.read_text(encoding="utf-8")
        self.assertIn(
            'if [[ "$strict" == "1" ]] && ! python3 "$repo/scripts/e2e/check_macos_rescue.py"',
            script,
        )
        subprocess.run(["bash", "-n", str(E2E)], check=True)


if __name__ == "__main__":
    unittest.main()
