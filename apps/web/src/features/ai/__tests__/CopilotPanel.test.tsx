import { render, screen } from "@testing-library/react";
import { afterEach, expect, it, vi } from "vitest";

import { CopilotPanel } from "../CopilotPanel";

afterEach(() => vi.unstubAllGlobals());

it("shows provider setup state without pretending an answer is available", async () => {
  vi.stubGlobal("fetch", vi.fn(async (url: string) => ({
    ok: true,
    json: async () => url.endsWith("/status") ? {
      configured: false, provider: "openai", model: "gpt-5.4-mini",
      daily_limit: 25, retention_days: 7,
    } : [],
  })));
  render(<CopilotPanel carrierId="tenant-a" carrierName="Northstar Freight (Demo)"
    canFinance={false} onClose={vi.fn()} onNavigate={vi.fn()} />);
  expect(await screen.findByText(/AI provider is not configured/i)).toBeVisible();
  expect(screen.getByLabelText("Your question")).toBeDisabled();
  expect(screen.getByRole("button", { name: "Send" })).toBeDisabled();
});
