"""The fictional seed cannot run against an unapproved database target."""

import pytest

from tools import seed_staging_fictional_fleet


def test_seed_refuses_non_staging_database(monkeypatch) -> None:
    monkeypatch.setenv("FLEETOPS_ENV", "production")
    monkeypatch.setenv("FLEETOPS_STAGING_FICTIONAL_SEED", "approved")
    monkeypatch.setenv("FLEETOPS_STAGING_DEMO_TENANT_ID",
                       "a56c2a37-9aec-462f-8044-87ab76f9beef")
    monkeypatch.setattr(seed_staging_fictional_fleet, "migration_target",
                        lambda: (type("URL", (), {"database": "other-database"})(),
                                 "production@head"))
    monkeypatch.setattr(seed_staging_fictional_fleet, "create_engine",
                        lambda url: (_ for _ in ()).throw(AssertionError("unexpected database connection")))
    with pytest.raises(RuntimeError, match="non-staging"):
        seed_staging_fictional_fleet.seed()
