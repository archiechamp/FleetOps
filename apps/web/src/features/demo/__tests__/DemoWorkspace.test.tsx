import { render, screen } from "@testing-library/react";
import { afterEach, expect, it, vi } from "vitest";

import { DemoWorkspace } from "../DemoWorkspace";

const asset = {
  id: "11111111-1111-4111-8111-111111111111", unit_number: "DEMO-101",
  asset_type: "TRACTOR", make: "Freightliner", model: "Cascadia",
  model_year: 2024, ownership_type: "OWNED", status: "AVAILABLE",
  terminal: "Main terminal", odometer_miles: 128450,
  service_due_date: null, service_due_miles: null, service_note: null,
  gps_latitude: 41.8, gps_longitude: -87.6, gps_source: "Fictional demo",
  gps_observed_at: "2020-01-01T00:00:00", gps_received_at: "2020-01-01T00:02:00",
};

afterEach(() => vi.unstubAllGlobals());

it("labels an old position stale and preserves its observation time", async () => {
  vi.stubGlobal("fetch", vi.fn(async (url: string) => ({
    ok: true,
    json: async () => url.endsWith("/assets") ? [asset] : [],
  })));
  render(<DemoWorkspace view="GPS" carrierId="tenant-a" canCreate={false} canFinance={false} />);
  expect(await screen.findByText("Stale")).toBeVisible();
  expect(screen.getByText(/Observed .*2020/)).toBeVisible();
  expect(screen.getByText(/Read-only account/i)).toBeVisible();
});

it("keeps finance data out of a reader report", async () => {
  const fetchMock = vi.fn(async (url: string) => ({
    ok: true,
    json: async () => url.endsWith("/assets") ? [asset] : [],
  }));
  vi.stubGlobal("fetch", fetchMock);
  render(<DemoWorkspace view="Reports" carrierId="tenant-a" canCreate={false} canFinance={false} />);
  expect(await screen.findByText(/Finance report requires creator permission/i)).toBeVisible();
  expect(fetchMock.mock.calls.every(([url]) => !url.endsWith("/costs"))).toBe(true);
});

it("adds recorded USD cents exactly in the creator report", async () => {
  vi.stubGlobal("fetch", vi.fn(async (url: string) => ({
    ok: true,
    json: async () => url.endsWith("/assets") ? [asset] : url.endsWith("/costs") ? [
      { id: "a", asset_id: asset.id, unit_number: asset.unit_number, trip_reference: null, category: "FUEL", amount_usd: "0.10", occurred_on: "2026-11-20" },
      { id: "b", asset_id: asset.id, unit_number: asset.unit_number, trip_reference: null, category: "TOLLS", amount_usd: "0.20", occurred_on: "2026-11-21" },
    ] : [],
  })));
  render(<DemoWorkspace view="Reports" carrierId="tenant-a" canCreate={true} canFinance={true} />);
  expect(await screen.findByText("$0.30")).toBeVisible();
  expect(screen.getByText(/Mileage basis/)).toBeVisible();
});
