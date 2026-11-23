import { render, screen } from "@testing-library/react";
import { afterEach, expect, it, vi } from "vitest";

import { CopilotPanel } from "../CopilotPanel";

afterEach(() => vi.unstubAllGlobals());

it("allows database questions when the AI provider is not configured", async () => {
  vi.stubGlobal("fetch", vi.fn(async (url: string) => ({
    ok: true,
    json: async () => url.endsWith("/status") ? {
      configured: false, provider: "openai", model: "gpt-5.4-mini",
      daily_limit: 25, retention_days: 7,
    } : [],
  })));
  render(<CopilotPanel carrierId="tenant-a" carrierName="Northstar Freight (Demo)"
    canFinance={false} onClose={vi.fn()} onNavigate={vi.fn()} />);
  expect(await screen.findByText(/Database answers available; AI provider not configured/i)).toBeVisible();
  expect(screen.getByLabelText("Your question")).toBeEnabled();
  expect(screen.getByRole("button", { name: "Send" })).toBeDisabled();
});
