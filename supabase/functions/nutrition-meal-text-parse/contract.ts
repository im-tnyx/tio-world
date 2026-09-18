// Tio-owned, provider-neutral request/response contract for the meal-text
// parser. Nothing here may depend on FatSecret or Gemini shapes: those stay
// internal to fatsecret_client.ts / gemini_client.ts.

export const SCHEMA_VERSION = 1;
const MAX_MEAL_TEXT_LENGTH = 1000;
const KNOWN_REQUEST_KEYS = new Set(["schemaVersion", "mealText"]);

export type ParseOutcome = "success" | "unrecognized" | "incomplete" | "unavailable";

export interface ParseRequest {
  readonly mealText: string;
}

export interface NutritionSnapshotDto {
  readonly schemaVersion: number;
  readonly nutrients: Readonly<Record<string, number>>;
}

export interface ResponseItem {
  readonly displayName: string;
  readonly quantity: number;
  readonly servingUnit: string;
  readonly nutritionSnapshot: NutritionSnapshotDto;
}

export interface ParseResponse {
  readonly schemaVersion: number;
  readonly outcome: ParseOutcome;
  readonly mealName?: string;
  readonly items?: readonly ResponseItem[];
}

export type RequestValidation =
  | { readonly ok: true; readonly request: ParseRequest }
  | { readonly ok: false };

/**
 * Rejects anything that is not exactly the documented shape: an object with
 * only `schemaVersion` and `mealText`, a matching schema version, and
 * non-blank trimmed text within a bounded length. This deliberately rejects
 * unknown fields (for example a caller-supplied `userId` or `provider`)
 * instead of silently ignoring them.
 */
export function validateParseRequest(body: unknown): RequestValidation {
  if (body === null || typeof body !== "object" || Array.isArray(body)) {
    return { ok: false };
  }

  const keys = Object.keys(body as Record<string, unknown>);
  for (const key of keys) {
    if (!KNOWN_REQUEST_KEYS.has(key)) return { ok: false };
  }

  const record = body as Record<string, unknown>;
  if (record.schemaVersion !== SCHEMA_VERSION) return { ok: false };

  const rawText = record.mealText;
  if (typeof rawText !== "string") return { ok: false };

  const mealText = rawText.trim();
  if (mealText.length === 0 || mealText.length > MAX_MEAL_TEXT_LENGTH) {
    return { ok: false };
  }

  return { ok: true, request: { mealText } };
}

export function outcomeResponse(outcome: Exclude<ParseOutcome, "success">): ParseResponse {
  return { schemaVersion: SCHEMA_VERSION, outcome };
}

export function successResponse(
  mealName: string | undefined,
  items: readonly ResponseItem[],
): ParseResponse {
  return {
    schemaVersion: SCHEMA_VERSION,
    outcome: "success",
    ...(mealName ? { mealName } : {}),
    items,
  };
}
