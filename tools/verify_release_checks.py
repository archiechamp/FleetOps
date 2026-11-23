"""Refuse image publication unless the exact commit passed required CI jobs."""

import json
import os
from urllib.request import Request, urlopen

REQUIRED = frozenset({"unit", "integration", "selenium", "images"})


def verify() -> None:
    repository = os.environ["GITHUB_REPOSITORY"]
    commit = os.environ["GITHUB_SHA"]
    token = os.environ["GITHUB_TOKEN"]
    request = Request(
        f"https://api.github.com/repos/{repository}/commits/{commit}/check-runs?per_page=100",
        headers={"Authorization": f"Bearer {token}", "Accept": "application/vnd.github+json",
                 "X-GitHub-Api-Version": "2022-11-28"},
    )
    with urlopen(request, timeout=15) as response:
        checks = json.load(response)["check_runs"]
    passing = {check["name"] for check in checks
               if check["status"] == "completed" and check["conclusion"] == "success"}
    missing = REQUIRED - passing
    if missing:
        raise RuntimeError("Required checks are not green for this commit: "
                           + ", ".join(sorted(missing)))
    print("All four required checks passed on the release commit")


if __name__ == "__main__":
    verify()
