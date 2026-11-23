import { readFileSync } from "node:fs";
import { resolve } from "node:path";
import { describe, expect, it } from "vitest";

import { isWellFormedUnicode, validateVehicleText } from "../vehicleValidation";

type VectorCase = {
  id: string;
  fields: Array<"unit_number" | "make" | "model">;
  parts: Array<{ text: string; repeat: number }>;
  valid: boolean;
  expected_units: number | null;
  expected_normalized?: string;
};

const fixturePath = resolve(process.cwd(), "../../tests/fixtures/vehicle_registration_vectors.json");
const vectors = JSON.parse(readFileSync(fixturePath, "utf8")) as {
  cases: VectorCase[];
  trim_code_points: string[];
};

describe("vehicle text UTF-16 validation", () => {
  for (const vector of vectors.cases) {
    for (const field of vector.fields) {
      it(`${vector.id} for ${field}`, () => {
        const input = vector.parts.map((part) => part.text.repeat(part.repeat)).join("");
        const result = validateVehicleText(field, input);
        expect(result.valid).toBe(vector.valid);
        expect(result.codeUnits).toBe(vector.expected_units);
        if (result.valid && vector.expected_normalized !== undefined) {
          expect(result.value).toBe(vector.expected_normalized);
        }
      });
    }
  }

  it("rejects lone surrogates without altering a valid pair", () => {
    expect(isWellFormedUnicode("\ud800")).toBe(false);
    expect(isWellFormedUnicode("\udc00")).toBe(false);
    expect(validateVehicleText("unit_number", "🚚")).toEqual({
      valid: true,
      value: "🚚",
      codeUnits: 2,
    });
  });

  it("trims every contract code point and retains U+0085", () => {
    for (const codePoint of vectors.trim_code_points) {
      const whitespace = String.fromCodePoint(Number.parseInt(codePoint, 16));
      expect(validateVehicleText("unit_number", `${whitespace}A${whitespace}`)).toEqual({
        valid: true,
        value: "A",
        codeUnits: 1,
      });
    }
    expect(validateVehicleText("unit_number", "\u0085A\u0085")).toEqual({
      valid: true,
      value: "\u0085A\u0085",
      codeUnits: 3,
    });
  });
});
