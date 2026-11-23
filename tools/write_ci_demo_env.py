"""Generate disposable CI-only credentials outside version control."""

import secrets
from pathlib import Path

target = Path(__file__).resolve().parents[1] / ".env.demo"
if target.exists():
    raise SystemExit("Refusing to replace an existing demo environment file")

values = {
    "FLEETOPS_TEST_SA_PASSWORD": "CiA1!" + secrets.token_urlsafe(28),
    "FLEETOPS_DEMO_RUNTIME_PASSWORD": "CiR1!" + secrets.token_urlsafe(28),
    "FLEETOPS_DEMO_SESSION_SECRET": secrets.token_urlsafe(48),
}
target.write_text("".join(f"{key}={value}\n" for key, value in values.items()), encoding="utf-8")
