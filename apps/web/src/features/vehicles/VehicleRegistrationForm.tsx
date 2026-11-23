import { useState, type FormEvent } from "react";

import type { components } from "../../../../../packages/api-contracts/vehicle-openapi";
import { validateVehicleText } from "./vehicleValidation";

type VehicleCreate = components["schemas"]["VehicleCreate"];
type Field = keyof VehicleCreate;
type Errors = Partial<Record<Field, string>>;

export function VehicleRegistrationForm({ onSubmit }: { onSubmit: (value: VehicleCreate) => void }) {
  const [values, setValues] = useState({
    unit_number: "",
    make: "",
    model: "",
    model_year: "",
    ownership_type: "",
  });
  const [errors, setErrors] = useState<Errors>({});

  function submit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    const nextErrors: Errors = {};
    const text = {} as Pick<VehicleCreate, "unit_number" | "make" | "model">;
    for (const field of ["unit_number", "make", "model"] as const) {
      const result = validateVehicleText(field, values[field]);
      if (result.valid) text[field] = result.value;
      else nextErrors[field] = result.error;
    }
    if (!/^[0-9]{4}$/.test(values.model_year) || Number(values.model_year) < 1900 || Number(values.model_year) > 2100) {
      nextErrors.model_year = "Enter a year from 1900 through 2100.";
    }
    if (!["OWNED", "LEASED", "CONTRACTED"].includes(values.ownership_type)) {
      nextErrors.ownership_type = "Select an ownership type.";
    }
    setErrors(nextErrors);
    if (Object.keys(nextErrors).length !== 0) return;
    onSubmit({
      ...text,
      model_year: Number(values.model_year),
      ownership_type: values.ownership_type as VehicleCreate["ownership_type"],
    });
  }

  function textField(field: "unit_number" | "make" | "model", label: string) {
    return (
      <div>
        <label htmlFor={field}>{label}</label>
        <input
          id={field}
          value={values[field]}
          onChange={(event) => setValues((current) => ({ ...current, [field]: event.target.value }))}
          aria-invalid={errors[field] ? true : undefined}
          aria-describedby={errors[field] ? `${field}-error` : undefined}
          className="block w-full rounded border p-2"
        />
        {errors[field] && <p id={`${field}-error`} role="alert">{errors[field]}</p>}
      </div>
    );
  }

  return (
    <form onSubmit={submit} noValidate className="grid gap-4">
      {textField("unit_number", "Unit number")}
      {textField("make", "Make")}
      {textField("model", "Model")}
      <div>
        <label htmlFor="model_year">Model year</label>
        <input id="model_year" inputMode="numeric" value={values.model_year}
          onChange={(event) => setValues((current) => ({ ...current, model_year: event.target.value }))}
          aria-invalid={errors.model_year ? true : undefined}
          aria-describedby={errors.model_year ? "model_year-error" : undefined}
          className="block w-full rounded border p-2" />
        {errors.model_year && <p id="model_year-error" role="alert">{errors.model_year}</p>}
      </div>
      <div>
        <label htmlFor="ownership_type">Ownership type</label>
        <select id="ownership_type" value={values.ownership_type}
          onChange={(event) => setValues((current) => ({ ...current, ownership_type: event.target.value }))}
          aria-invalid={errors.ownership_type ? true : undefined}
          aria-describedby={errors.ownership_type ? "ownership_type-error" : undefined}
          className="block w-full rounded border p-2">
          <option value="">Select ownership</option>
          <option value="OWNED">Owned</option>
          <option value="LEASED">Leased</option>
          <option value="CONTRACTED">Contracted</option>
        </select>
        {errors.ownership_type && <p id="ownership_type-error" role="alert">{errors.ownership_type}</p>}
      </div>
      <button type="submit" className="rounded bg-slate-900 px-4 py-2 text-white">Register truck</button>
    </form>
  );
}
