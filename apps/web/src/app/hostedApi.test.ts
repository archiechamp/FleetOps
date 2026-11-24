import { afterEach, expect, it, vi } from "vitest";

import { hostedJson } from "./hostedApi";

afterEach(() => {
  vi.useRealTimers();
  vi.unstubAllGlobals();
});

it("retries a transient database outage and returns the authorized carrier", async () => {
  vi.useFakeTimers();
  const fetchMock = vi.fn()
    .mockResolvedValueOnce({ ok: false, status: 503 })
    .mockResolvedValueOnce({ ok: true, json: async () => ({ carriers: [{ id: "one" }] }) });
  vi.stubGlobal("fetch", fetchMock);

  const result = hostedJson<{ carriers: { id: string }[] }>("/api/v1/me", "session-token");
  await vi.advanceTimersByTimeAsync(1500);
  expect(await result).toEqual({ carriers: [{ id: "one" }] });
  expect(fetchMock).toHaveBeenCalledTimes(2);
  expect(fetchMock.mock.calls[1][1].headers.Authorization).toBe("Bearer session-token");
});

it("does not retry an unauthorized carrier selection", async () => {
  const fetchMock = vi.fn().mockResolvedValue({ ok: false, status: 403,
    json: async () => ({ detail: "Carrier access denied" }) });
  vi.stubGlobal("fetch", fetchMock);
  await expect(hostedJson("/api/v1/assets", "session-token", "other-carrier"))
    .rejects.toThrow("Carrier access denied");
  expect(fetchMock).toHaveBeenCalledTimes(1);
});
