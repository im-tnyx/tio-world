import type { InterpretationResult, MealCandidate } from "./types.ts";
import { finitePositiveNumber } from "./matching.ts";

/**
 * Provider-neutral interpretation rules shared by every AI meal interpreter.
 * Provider adapters only differ in transport/DTO shape; the business rules,
 * item limit, and normalization below must stay single-sourced.
 */
export const MAX_INTERPRETED_ITEMS = 8;

/** The unit of a stated count that arrived without one ("2 bananas"). */
export const BARE_COUNT_UNIT = "piece";

/**
 * Above this a bare number is more likely a weight than a count ("chicken
 * 200"), so it is left without a unit and the resolvers ask for an amount
 * instead of resolving hundreds of pieces.
 */
export const MAX_BARE_COUNT = 50;

export const MEAL_INTERPRETER_INSTRUCTIONS: readonly string[] = [
  "Extract meal items from the user's text for factual nutrition lookup.",
  "Do not calculate or invent calories, macros, micronutrients, gram weights, or serving conversions.",
  "Preserve only quantities and units explicitly stated or unambiguously expressed by the user.",
  "If an amount is missing, set quantity and unit to null rather than assuming 1 serving.",
  "If a count is given without a unit (for example \"2 bananas\"), return the count as the quantity and \"piece\" as the unit.",
  "Use short generic food names suitable for factual database lookup; do not add brands unless the user named one.",
  "If there is no meaningful food interpretation, return an empty items array.",
];

export function mealTextInput(mealText: string): string {
  return `User meal text: ${mealText}`;
}

/** Gemini `responseSchema` (OpenAPI subset). */
export const geminiInterpretationSchema = {
  type: "object",
  properties: {
    mealName: { type: ["string", "null"] },
    items: {
      type: "array",
      maxItems: MAX_INTERPRETED_ITEMS,
      items: {
        type: "object",
        properties: {
          foodName: { type: "string" },
          quantity: { type: ["number", "null"] },
          unit: { type: ["string", "null"] },
        },
        required: ["foodName", "quantity", "unit"],
      },
    },
  },
  required: ["mealName", "items"],
} as const;

/**
 * OpenAI strict Structured Outputs schema. Same fields and limit as Gemini;
 * strict mode additionally requires `additionalProperties: false`.
 */
export const openAiInterpretationSchema = {
  type: "object",
  additionalProperties: false,
  properties: {
    mealName: { type: ["string", "null"] },
    items: {
      type: "array",
      maxItems: MAX_INTERPRETED_ITEMS,
      items: {
        type: "object",
        additionalProperties: false,
        properties: {
          foodName: { type: "string" },
          quantity: { type: ["number", "null"] },
          unit: { type: ["string", "null"] },
        },
        required: ["foodName", "quantity", "unit"],
      },
    },
  },
  required: ["mealName", "items"],
} as const;

/**
 * Strictly normalizes a provider's structured JSON text. Any deviation from the
 * schema is `unavailable`; an empty item list is the semantic `unrecognized`.
 * Only foodName/quantity/unit/mealName are read, so provider-invented fields
 * (e.g. calories) can never cross into the Tio contract.
 */
export function parseInterpretationJson(text: string): InterpretationResult {
  let decoded: unknown;
  try {
    decoded = JSON.parse(text);
  } catch {
    return { kind: "unavailable" };
  }

  if (decoded === null || typeof decoded !== "object" || Array.isArray(decoded)) {
    return { kind: "unavailable" };
  }

  const record = decoded as Record<string, unknown>;
  const rawItems = record.items;
  if (!Array.isArray(rawItems) || rawItems.length > MAX_INTERPRETED_ITEMS) {
    return { kind: "unavailable" };
  }
  if (rawItems.length === 0) return { kind: "unrecognized" };

  const items: MealCandidate[] = [];
  for (const raw of rawItems) {
    if (raw === null || typeof raw !== "object" || Array.isArray(raw)) {
      return { kind: "unavailable" };
    }
    const item = raw as Record<string, unknown>;
    const foodName = typeof item.foodName === "string" ? item.foodName.trim() : "";
    if (!foodName) return { kind: "unavailable" };

    const quantity = item.quantity === null
      ? null
      : finitePositiveNumber(item.quantity);
    if (item.quantity !== null && quantity === null) {
      return { kind: "unavailable" };
    }

    const unit = item.unit === null
      ? null
      : typeof item.unit === "string" && item.unit.trim().length > 0
      ? item.unit.trim()
      : null;
    if (item.unit !== null && unit === null) {
      return { kind: "unavailable" };
    }

    // Quantity and unit are a pair. A partial amount is not promoted to a
    // fabricated complete candidate; factual resolvers will map this to
    // `incomplete`.
    //
    // The one exception is a stated count without a unit ("2 bananas"). That
    // is an unambiguous number of pieces, so it is completed here rather than
    // depending on whether the model happened to answer "pieces". A large bare
    // number stays partial (see MAX_BARE_COUNT), and so does a unit without a
    // quantity.
    const isBareCount =
      unit === null && quantity !== null && quantity <= MAX_BARE_COUNT;
    items.push({
      foodName,
      quantity: quantity ?? null,
      unit: isBareCount ? BARE_COUNT_UNIT : unit,
    });
  }

  const mealName = typeof record.mealName === "string" && record.mealName.trim()
    ? record.mealName.trim()
    : undefined;

  return {
    kind: "recognized",
    ...(mealName ? { mealName } : {}),
    items,
  };
}
