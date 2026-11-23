"""Read-only HTTP checks against a running isolated local demo stack."""

import os
from collections.abc import Iterator
from contextlib import contextmanager
from uuid import UUID

import httpx


@contextmanager
def _client(username: str) -> Iterator[tuple[httpx.Client, str]]:
    base = os.environ["FLEETOPS_DEMO_BASE_URL"].rstrip("/")
    with httpx.Client(base_url=base, timeout=10) as client:
        login = client.post("/api/v1/demo/login", json={"username": username},
                            headers={"X-Demo-Request": "fleetops-ui"})
        assert login.status_code == 200
        me = client.get("/api/v1/me")
        assert me.status_code == 200
        yield client, me.json()["carriers"][0]["id"]


def test_reader_can_inspect_inventory_but_not_finance_or_documents() -> None:
    with _client("demo_reader") as (client, tenant):
        headers = {"X-Tenant-Id": tenant}
        assets = client.get("/api/v1/demo/assets", headers=headers)
        assert assets.status_code == 200
        assert all(item["asset_type"] in ("TRACTOR", "TRAILER") for item in assets.json())
        assert client.get("/api/v1/demo/costs", headers=headers).status_code == 403
        assert client.get("/api/v1/demo/documents", headers=headers).status_code == 403
        assert client.post("/api/v1/demo/assignments", headers={
            **headers, "X-Demo-Request": "fleetops-ui"}, json={
            "trip_reference": "DENIED", "truck_asset_id": str(UUID(int=1)),
            "starts_at": "2026-12-01T00:00:00Z", "ends_at": "2026-12-02T00:00:00Z",
        }).status_code == 403


def test_unknown_carrier_and_direct_document_probe_are_denied() -> None:
    with _client("demo_creator") as (client, tenant):
        wrong = {"X-Tenant-Id": str(UUID(int=3))}
        assert client.get("/api/v1/demo/assets", headers=wrong).status_code == 403
        assert client.get("/api/v1/demo/documents/00000000-0000-0000-0000-000000000001/file",
                          headers={"X-Tenant-Id": tenant}).status_code == 404


def test_unauthenticated_inventory_is_rejected() -> None:
    base = os.environ["FLEETOPS_DEMO_BASE_URL"].rstrip("/")
    with httpx.Client(base_url=base, timeout=10) as client:
        assert client.get("/api/v1/demo/assets", headers={
            "X-Tenant-Id": str(UUID(int=1))}).status_code == 401


def test_unknown_demo_account_cannot_sign_in() -> None:
    base = os.environ["FLEETOPS_DEMO_BASE_URL"].rstrip("/")
    with httpx.Client(base_url=base, timeout=10) as client:
        response = client.post("/api/v1/demo/login", json={"username": "unknown"},
                               headers={"X-Demo-Request": "fleetops-ui"})
        assert response.status_code == 401
        assert client.get("/api/v1/me").status_code == 401
