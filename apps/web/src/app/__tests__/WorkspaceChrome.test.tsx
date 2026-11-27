import { render, screen } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { expect, it, vi } from "vitest";

import { CarrierBar, WorkspaceHeader, WorkspaceNav } from "../WorkspaceChrome";
import { hostedErrorDetail } from "../hostedApi";

it("uses the same workspace heading, carrier selector, and navigation for both modes", async () => {
  const onCarrier = vi.fn();
  const onView = vi.fn();
  render(<><WorkspaceHeader environment="Hosted staging" />
    <CarrierBar id="tenant-a" carriers={[{ id: "tenant-a", name: "Fictional carrier" }]}
      onChange={onCarrier} account="Clerk pilot" access="Read-only fleet access" />
    <WorkspaceNav view="Overview" onChange={onView} /></>);
  expect(screen.getByRole("heading", { name: "Fleet vehicles" })).toBeVisible();
  expect(screen.getByRole("combobox", { name: "Carrier" })).toHaveValue("tenant-a");
  expect(screen.getByRole("option", { name: "Fictional carrier" })).toBeVisible();
  await userEvent.click(screen.getByRole("button", { name: "Reports" }));
  expect(onView).toHaveBeenCalledWith("Reports");
  expect(onCarrier).not.toHaveBeenCalled();
});

it("turns structured API validation details into readable messages", () => {
  expect(hostedErrorDetail([{ msg: "Extra inputs are not permitted" }], "Request failed"))
    .toBe("Extra inputs are not permitted");
  expect(hostedErrorDetail({ code: "unknown" }, "Request failed")).toBe("Request failed");
});
