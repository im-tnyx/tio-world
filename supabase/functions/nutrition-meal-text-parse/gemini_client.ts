import type {
  InterpretationResult,
  MealCandidate,
  MealInterpreter,
} from "./types.ts";
import { fetchWithTimeout } from "./async_control.ts";
import { finitePositiveNumber } from "./matching.ts";

const DEFAULT_MODEL = "gemini-3.8-flash";
const DEFAULT_TIMEOUT_MS = 8000;
const MAX_ITEMS = 8;

interface GeminiClientOptions {
  readonly apiKey: string;
  readonly model?: string;
  readonly timeoutMs?: number;
  readonly fetchFn?: typeof fetch;
}

interface GeminiEnvelope {
  readonly candidates?: readonly {
    readonly content?: {
      readonly parts?: readonly { readonly text?: string }[];
    };
  }[];
}

const responseSchema = {
  type: "object",
  properties: {
    mealName: { type: ["string", "null"] },
    items: {
      type: "array",
      maxItems: MAX_ITEMS,
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

export class GeminiMealInterpreter implements MealInterpreter {
  readonly #apiKey: string;
  readonly #model: string;
  readonly #timeoutMs: number;
  readonly #fetch: typeof fetch;

  constructor(options: GeminiClientOptions) {
    this.#apiKey = options.apiKey;
    this.#model = options.model?.trim() || DEFAULT_MODEL;
    this.#timeoutMs = options.timeoutMs ?? DEFAULT_TIMEOUT_MS;
    this.#fetch = options.fetchFn ?? fetch;
  }

  async interpret(
    mealText: string,
    signal?: AbortSignal,
  ): Promise<InterpretationResult> {
    if (!this.#apiKey) return { kind: "unavailable" };

    const response = await fetchWithTimeout(
      this.#fetch,
      `https://generativelanguage.googleapis.com/v1beta/models/${encodeURIComponent(this.#model)}:generateContent`,
      {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "x-goog-api-key": this.#apiKey,
        },
        body: JSON.stringify({
          contents: [
            {
              role: "user",
              parts: [{ text: buildPrompt(mealText) }],
            },
          ],
          generationConfig: {
            responseMimeType: "application/json",
            responseSchema,
          },
        }),
      },
      this.#timeoutMs,
      signal,
    );

    if (response === null || !response.ok) return { kind: "unavailable" };

    try {
      const envelope = (await response.json()) as GeminiEnvelope;
      const text = envelope.candidates?.[0]?.content?.parts?.[0]?.text;
      if (typeof text !== "string" || text.trim().length === 0) {
        return { kind: "unavailable" };
      }
      return parseGeminiInterpretation(text);
    } catch {
      return { kind: "unavailable" };
    }
  }
}

function buildPrompt(mealText: string): string {
  return [
    "Extract meal items from the user's text for factual nutrition lookup.",
    "Do not calculate or invent calories, macros, micronutrients, gram weights, or serving conversions.",
    "Preserve only quantities and units explicitly stated or unambiguously expressed by the user.",
    "If an amount is missing, set quantity and unit to null rather than assuming 1 serving.",
    "Use short generic food names suitable for factual database lookup; do not add brands unless the user named one.",
    "If there is no meaningful food interpretation, return an empty items array.",
    `User meal text: ${mealText}`,
  ].join("\n");
}

export function parseGeminiInterpretation(text: string): InterpretationResult {
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
  if (!Array.isArray(rawItems) || rawItems.length > MAX_ITEMS) {
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
    items.push({
      foodName,
      quantity: quantity ?? null,
      unit,
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
