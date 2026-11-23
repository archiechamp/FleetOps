import { render, screen } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { expect, it, vi } from "vitest";

import { VehicleRegistrationForm } from "../VehicleRegistrationForm";

it("keeps missing and over-limit values editable without submitting", async () => {
  const submit = vi.fn();
  const user = userEvent.setup();
  render(<VehicleRegistrationForm onSubmit={submit} />);
  await user.click(screen.getByRole("button", { name: /register truck/i }));
  expect(screen.getByLabelText(/unit number/i)).toHaveAttribute("aria-invalid", "true");
  expect(screen.getAllByText("This field is required.").length).toBeGreaterThan(0);
  expect(submit).not.toHaveBeenCalled();

  const unit = screen.getByLabelText(/unit number/i);
  await user.type(unit, "A".repeat(31));
  await user.click(screen.getByRole("button", { name: /register truck/i }));
  expect(unit).toHaveValue("A".repeat(31));
  expect(screen.getByText(/at most 30 UTF-16 code units/i)).toBeVisible();
  expect(submit).not.toHaveBeenCalled();
});

it("submits exact-limit supplementary values unchanged", async () => {
  const submit = vi.fn();
  const user = userEvent.setup();
  render(<VehicleRegistrationForm onSubmit={submit} />);
  await user.type(screen.getByLabelText(/unit number/i), "🚚".repeat(15));
  await user.type(screen.getByLabelText(/^make/i), "M".repeat(80));
  await user.type(screen.getByLabelText(/^model$/i), "🚚".repeat(40));
  await user.type(screen.getByLabelText(/model year/i), "2025");
  await user.selectOptions(screen.getByLabelText(/ownership/i), "OWNED");
  await user.click(screen.getByRole("button", { name: /register truck/i }));
  expect(submit).toHaveBeenCalledWith({
    unit_number: "🚚".repeat(15),
    make: "M".repeat(80),
    model: "🚚".repeat(40),
    model_year: 2025,
    ownership_type: "OWNED",
  });
});
