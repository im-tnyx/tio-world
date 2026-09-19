import type { CanonicalNutrientKey, ResponseItem } from "./contract.ts";
import { mealParserDiagnostic } from "./diagnostics.ts";
import {
  canonicalSnapshot,
  finiteNonNegativeNumber,
  finitePositiveNumber,
  isSafeFoodIdentityMatch,
  normalizeUnit,
} from "./matching.ts";
import { fetchWithTimeout } from "./async_control.ts";
import type {
  FoodNutritionResolver,
  MealCandidate,
  ResolverResult,
} from "./types.ts";

const PARSER_URL = "https://api.edamam.com/api/food-database/v2/parser";
const NUTRIENTS_URL = "https://api.edamam.com/api/food-database/v2/nutrients";
const DEFAULT_TIMEOUT_MS = 6000;

interface EdamamOptions {
  readonly appId: string;
  readonly appKey: string;
  readonly timeoutMs?: number;
  readonly fetchFn?: typeof fetch;
}

interface ParsedFood {
  readonly food?: {
    readonly foodId?: string;
    readonly label?: string;
  };
  readonly quantity?: number;
  readonly measure?: {
    readonly uri?: string;
    readonly label?: string;
  };
}

interface EdamamNutrient {
  readonly quantity?: number;
  readonly unit?: string;
}

export class EdamamResolver implements FoodNutritionResolver {
  readonly name = "edamam" as const;

  readonly #appId: string;
  readonly #appKey: string;
  readonly #timeoutMs: number;
  readonly #fetch: typeof fetch;

  constructor(options: EdamamOptions) {
    this.#appId = options.appId;
    this.#appKey = options.appKey;
    this.#timeoutMs = options.timeoutMs ?? DEFAULT_TIMEOUT_MS;
    this.#fetch = options.fetchFn ?? fetch;
  }

  async resolve(candidate: MealCandidate, signal?: AbortSignal): Promise<ResolverResult> {
    if (!this.#appId || !this.#appKey) {
      mealParserDiagnostic("resolver_unavailable", { provider: "edamam", reason: "missing_configuration" });
      return { kind: "unavailable" };
    }
    if (candidate.quantity === null || candidate.unit === null) {
      return { kind: "incomplete" };
    }

    const parsed = await this.#parseCandidate(candidate, signal);
    if (parsed.kind !== "ok") return parsed.result;

    const foodId = parsed.value.food?.foodId;
    const label = parsed.value.food?.label;
    const quantity = finitePositiveNumber(parsed.value.quantity);
    const measureUri = parsed.value.measure?.uri;
    const measureLabel = parsed.value.measure?.label;

    if (
      !foodId ||
      !label ||
      quantity === null ||
      !measureUri ||
      !measureLabel ||
      !isSafeFoodIdentityMatch(candidate.foodName, label) ||
      !quantityMatches(candidate.quantity, quantity) ||
      !measureIsCompatible(candidate.unit, measureLabel)
    ) {
      return { kind: "incomplete" };
    }

    const nutrients = await this.#getNutrients({
      foodId,
      quantity,
      measureUri,
    }, signal);
    if (nutrients.kind !== "ok") return nutrients.result;

    const item = buildEdamamItem(candidate, label, nutrients.totalNutrients);
    return item === null ? { kind: "incomplete" } : { kind: "resolved", item };
  }

  async #parseCandidate(
    candidate: MealCandidate,
    signal?: AbortSignal,
  ): Promise<
    | { readonly kind: "ok"; readonly value: ParsedFood }
    | { readonly kind: "fail"; readonly result: ResolverResult }
  > {
    const url = this.#authenticatedUrl(PARSER_URL);
    url.searchParams.set(
      "ingr",
      `${candidate.quantity} ${candidate.unit} ${candidate.foodName}`,
    );
    url.searchParams.set("nutrition-type", "logging");

    const response = await this.#boundedFetch(url, {
      headers: { Accept: "application/json" },
    }, signal);
    if (response === null) {
      mealParserDiagnostic("resolver_unavailable", { provider: "edamam", reason: "transport_or_timeout" });
      return { kind: "fail", result: { kind: "unavailable" } };
    }
    if (!response.ok) {
      mealParserDiagnostic("resolver_unavailable", { provider: "edamam", reason: "http_error", httpStatus: response.status });
      return { kind: "fail", result: { kind: "unavailable" } };
    }

    try {
      const payload = (await response.json()) as Record<string, unknown>;
      const parsed = payload.parsed;
      if (!Array.isArray(parsed) || parsed.length === 0) {
        return { kind: "fail", result: { kind: "incomplete" } };
      }
      const first = parsed[0];
      if (first === null || typeof first !== "object" || Array.isArray(first)) {
        return { kind: "fail", result: { kind: "unavailable" } };
      }
      return { kind: "ok", value: first as ParsedFood };
    } catch {
      mealParserDiagnostic("resolver_unavailable", { provider: "edamam", reason: "malformed_response" });
      return { kind: "fail", result: { kind: "unavailable" } };
    }
  }

  async #getNutrients(input: {
    readonly foodId: string;
    readonly quantity: number;
    readonly measureUri: string;
  }, signal?: AbortSignal): Promise<
    | {
        readonly kind: "ok";
        readonly totalNutrients: Readonly<Record<string, EdamamNutrient>>;
      }
    | { readonly kind: "fail"; readonly result: ResolverResult }
  > {
    const url = this.#authenticatedUrl(NUTRIENTS_URL);
    const response = await this.#boundedFetch(url, {
      method: "POST",
      headers: {
        Accept: "application/json",
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        ingredients: [
          {
            quantity: input.quantity,
            measureURI: input.measureUri,
            foodId: input.foodId,
          },
        ],
      }),
    }, signal);
    if (response === null || !response.ok) {
      return { kind: "fail", result: { kind: "unavailable" } };
    }

    try {
      const payload = (await response.json()) as Record<string, unknown>;
      const raw = payload.totalNutrients;
      if (raw === null || typeof raw !== "object" || Array.isArray(raw)) {
        return { kind: "fail", result: { kind: "incomplete" } };
      }
      return {
        kind: "ok",
        totalNutrients: raw as Readonly<Record<string, EdamamNutrient>>,
      };
    } catch {
      return { kind: "fail", result: { kind: "unavailable" } };
    }
  }

  #authenticatedUrl(base: string): URL {
    const url = new URL(base);
    // Edamam authenticates these endpoints via query parameters. This URL is
    // never logged or included in thrown/client-visible errors.
    url.searchParams.set("app_id", this.#appId);
    url.searchParams.set("app_key", this.#appKey);
    return url;
  }

  async #boundedFetch(
    input: RequestInfo | URL,
    init?: RequestInit,
    signal?: AbortSignal,
  ): Promise<Response | null> {
    return fetchWithTimeout(this.#fetch, input, init, this.#timeoutMs, signal);
  }
}

function quantityMatches(expected: number, actual: number): boolean {
  return Math.abs(expected - actual) <= Math.max(0.0001, expected * 0.001);
}

export function measureIsCompatible(candidateUnit: string, providerMeasure: string): boolean {
  const candidate = normalizeUnit(candidateUnit);
  const provider = normalizeUnit(providerMeasure);
  if (candidate === provider) return true;

  if ((candidate === "item" || candidate === "piece") &&
      ["item", "piece", "whole", "unit"].includes(provider)) {
    return true;
  }
  return false;
}

export function buildEdamamItem(
  candidate: MealCandidate,
  label: string,
  totalNutrients: Readonly<Record<string, EdamamNutrient>>,
): ResponseItem | null {
  if (candidate.quantity === null || candidate.unit === null) return null;

  const mappings: Readonly<Record<CanonicalNutrientKey, string>> = {
    energy: "ENERC_KCAL",
    protein: "PROCNT",
    carbohydrate: "CHOCDF",
    fat: "FAT",
    fiber: "FIBTG",
    saturated_fat: "FASAT",
    trans_fat: "FATRN",
    added_sugar: "SUGAR.added",
    sodium: "NA",
    calcium: "CA",
    phosphorus: "P",
    vitamin_d: "VITD",
  };

  const nutrients: Partial<Record<CanonicalNutrientKey, number>> = {};
  for (const [target, source] of Object.entries(mappings) as [CanonicalNutrientKey, string][]) {
    const amount = finiteNonNegativeNumber(totalNutrients[source]?.quantity);
    if (amount !== null) nutrients[target] = amount;
  }

  const snapshot = canonicalSnapshot(nutrients);
  if (snapshot === null) return null;

  return {
    displayName: label.trim() || candidate.foodName,
    quantity: candidate.quantity,
    servingUnit: candidate.unit,
    nutritionSnapshot: snapshot,
  };
}
