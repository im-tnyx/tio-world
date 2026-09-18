// Tio-owned, provider-neutral request/response contract for the meal-text parser.
// Provider/model DTOs and identifiers must stay inside the Edge Function.

export const SCHEMA_VERSION = 1;
export const NUTRITION_SCHEMA_VERSION = 1;
const MAX_MEAL_TEXT_LENGTH = 1000;
const KNOWN_REQUEST_KEYS = new Set(["schemaVersion", "mealText"]);

export const CANONICAL_NUTRIENT_KEYS = [
  "energy",
  "protein",
  "carbohydrate",
  "fat",
  "fiber",
  "saturated_fat",
  "trans_fat",
  "added_sugar",
  "sodium",
  "calcium",
  "phosphorus",
  "vitamin_d",
] as const;

export type CanonicalNutrientKey = (typeof CANONICAL_NUTRIENT_KEYS)[number];
export type ParseOutcome = "success" | "unrecognized" | "incomplete" | "unavailable";

export interface ParseRequest {
  readonly mealText: string;
}

export interface NutritionSnapshotDto {
  readonly schemaVersion: number;
  readonly nutrients: Readonly<Partial<Record<CanonicalNutrientKey, number>>>;
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
 * only schemaVersion and mealText, a matching schema version, and bounded
 * non-blank trimmed text. Caller-supplied identity/provider/model fields are
 * deliberately rejected rather than ignored.
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

export function outcomeResponse(
  outcome: Exclude<ParseOutcome, "success">,
): ParseResponse {
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
