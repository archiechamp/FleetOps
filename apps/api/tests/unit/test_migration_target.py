"""Production migration target cannot silently point at demo or disable TLS."""

import pytest

from app.core.migration_config import migration_target


def test_production_migration_needs_exact_approved_target(monkeypatch) -> None:
    monkeypatch.setenv("FLEETOPS_ENV", "production")
    monkeypatch.setenv("FLEETOPS_DATABASE_NAME", "fleetops_staging")
    monkeypatch.delenv("FLEETOPS_MIGRATION_APPROVED_TARGET", raising=False)
    with pytest.raises(RuntimeError, match="explicitly approved"):
        migration_target()


def test_production_migration_requires_verified_tls(monkeypatch) -> None:
    monkeypatch.setenv("FLEETOPS_ENV", "production")
    monkeypatch.setenv("FLEETOPS_DATABASE_NAME", "fleetops_staging")
    monkeypatch.setenv("FLEETOPS_MIGRATION_APPROVED_TARGET", "fleetops_staging")
    monkeypatch.setenv("FLEETOPS_SQL_MIGRATION_USER", "fleetops_migrator")
    monkeypatch.setenv("FLEETOPS_SQL_MIGRATION_PASSWORD", "test-only")
    monkeypatch.setenv("FLEETOPS_SQL_TRUST_SERVER_CERTIFICATE", "yes")
    with pytest.raises(RuntimeError, match="verified SQL TLS"):
        migration_target()


def test_production_migration_uses_separate_identity(monkeypatch) -> None:
    monkeypatch.setenv("FLEETOPS_ENV", "production")
    monkeypatch.setenv("FLEETOPS_DATABASE_NAME", "fleetops_staging")
    monkeypatch.setenv("FLEETOPS_MIGRATION_APPROVED_TARGET", "fleetops_staging")
    monkeypatch.setenv("FLEETOPS_SQL_MIGRATION_USER", "fleetops_migrator")
    monkeypatch.setenv("FLEETOPS_SQL_MIGRATION_PASSWORD", "test-only")
    monkeypatch.setenv("FLEETOPS_SQL_TRUST_SERVER_CERTIFICATE", "no")
    url, target = migration_target()
    assert target == "production@head"
    assert url.username == "fleetops_migrator"
    assert url.query["TrustServerCertificate"] == "no"


def test_isolated_test_database_can_select_production_branch(monkeypatch) -> None:
    monkeypatch.setenv("FLEETOPS_ENV", "test")
    monkeypatch.setenv("FLEETOPS_DATABASE_NAME", "fleetops_test_001")
    monkeypatch.setenv("FLEETOPS_TEST_SA_PASSWORD", "test-only")
    monkeypatch.setenv("FLEETOPS_TEST_MIGRATION_BRANCH", "production")
    url, target = migration_target()
    assert target == "production@head"
    assert url.database == "fleetops_test_001"
