import { render, screen } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { afterEach, expect, it, vi } from "vitest";

import { App } from "../../../app/App";

afterEach(() => vi.unstubAllGlobals());

it("carries a landing question into authenticated Copilot without querying AI before sign-in", async () => {
  let signedIn = false;
  const fetchMock = vi.fn(async (input: RequestInfo | URL, init?: RequestInit) => {
    const url = String(input);
    if (url.endsWith("/demo/login")) {
      expect(JSON.parse(String(init?.body))).toEqual({ username: "demo_creator" });
      signedIn = true;
      return { ok: true, json: async () => ({}) };
    }
    if (url.endsWith("/me")) return signedIn
      ? { ok: true, json: async () => ({ username: "demo_creator", carriers: [
        { id: "tenant-a", name: "Northstar Freight (Demo)", permissions: ["fleet.vehicle.read"] },
      ] }) }
      : { ok: false, status: 401, json: async () => ({ detail: "Sign in required" }) };
    if (url.endsWith("/ai/status")) return { ok: true, json: async () => ({
      configured: true, provider: "openai", model: "test-model", daily_limit: 25, retention_days: 7,
    }) };
    return { ok: true, json: async () => [] };
  });
  vi.stubGlobal("fetch", fetchMock);

  const user = userEvent.setup();
  render(<App />);
  await screen.findByRole("heading", { name: /Know your fleet/i });
  expect(fetchMock.mock.calls.every(([url]) => !String(url).includes("/ai/"))).toBe(true);

  await user.click(screen.getByRole("button", { name: "Which trucks need service?" }));
  expect(screen.getByRole("heading", { name: "Sign in to demo" })).toBeVisible();
  expect(screen.queryByLabelText("Demo password")).not.toBeInTheDocument();
  await user.click(screen.getByRole("button", { name: "Sign in" }));

  expect(await screen.findByRole("textbox", { name: "Your question" })).toHaveValue(
    "Which trucks need service?",
  );
  expect(screen.getByRole("complementary", { name: "AI Fleet panel" })).toBeVisible();
});
