"""Release publication gate checks the exact commit and all required jobs."""

import io
import json
import os
import unittest
from unittest.mock import patch

from tools.verify_release_checks import verify


class ReleaseChecksTests(unittest.TestCase):
    def _run(self, conclusions: dict[str, str]) -> None:
        checks = {"check_runs": [{"name": name, "status": "completed", "conclusion": result}
                                 for name, result in conclusions.items()]}
        response = io.BytesIO(json.dumps(checks).encode())
        with patch.dict(os.environ, {"GITHUB_REPOSITORY": "owner/FleetOps",
                                     "GITHUB_SHA": "a" * 40, "GITHUB_TOKEN": "test-token"}), \
                patch("tools.verify_release_checks.urlopen", return_value=response):
            verify()

    def test_all_green(self) -> None:
        self._run({name: "success" for name in ("unit", "integration", "selenium", "images")})

    def test_missing_or_failed_gate_blocks_publish(self) -> None:
        with self.assertRaises(RuntimeError):
            self._run({"unit": "success", "integration": "failure",
                       "selenium": "success"})


if __name__ == "__main__":
    unittest.main()
