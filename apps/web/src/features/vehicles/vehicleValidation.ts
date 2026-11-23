export const VEHICLE_TRIM_CHARACTERS =
  "\u0009-\u000d\u0020\u00a0\u1680\u2000-\u200a\u2028\u2029\u202f\u205f\u3000\ufeff";

const outerWhitespace = new RegExp(`^[${VEHICLE_TRIM_CHARACTERS}]+|[${VEHICLE_TRIM_CHARACTERS}]+$`, "g");

export type VehicleTextField = "unit_number" | "make" | "model";

export type TextValidationResult =
  | { valid: true; value: string; codeUnits: number }
  | { valid: false; error: string; codeUnits: number | null };

export function isWellFormedUnicode(value: string): boolean {
  for (let index = 0; index < value.length; index += 1) {
    const codeUnit = value.charCodeAt(index);
    if (codeUnit >= 0xd800 && codeUnit <= 0xdbff) {
      const nextCodeUnit = value.charCodeAt(index + 1);
      if (!(nextCodeUnit >= 0xdc00 && nextCodeUnit <= 0xdfff)) return false;
      index += 1;
    } else if (codeUnit >= 0xdc00 && codeUnit <= 0xdfff) {
      return false;
    }
  }
  return true;
}

export function validateVehicleText(field: VehicleTextField, input: string): TextValidationResult {
  if (!isWellFormedUnicode(input)) {
    return { valid: false, error: "Enter well-formed Unicode text.", codeUnits: null };
  }
  const value = input.replace(outerWhitespace, "");
  const maximumUnits = field === "unit_number" ? 30 : 80;
  if (value.length < 1) {
    return { valid: false, error: "This field is required.", codeUnits: 0 };
  }
  if (value.length > maximumUnits) {
    return {
      valid: false,
      error: `Use at most ${maximumUnits} UTF-16 code units; some symbols count as two.`,
      codeUnits: value.length,
    };
  }
  return { valid: true, value, codeUnits: value.length };
}
