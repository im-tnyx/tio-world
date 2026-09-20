import {
  canonicalSnapshot,
  finiteNonNegativeNumber,
  finitePositiveNumber,
  isSafeFoodIdentityMatch,
  matchScore,
  normalizeName,
  normalizeUnit,
  toMetricAmount,
} from "./matching.ts";
import { fetchWithTimeout } from "./async_control.ts";
import type { CanonicalNutrientKey, ResponseItem } from "./contract.ts";
import type {
  FoodNutritionResolver,
  MealCandidate,
  NutritionResolverContext,
  ResolverResult,
} from "./types.ts";

const TOKEN_URL = "https://oauth.fatsecret.com/connect/token";
const SEARCH_URL = "https://platform.fatsecret.com/rest/server.api";
const FOOD_URL = "https://platform.fatsecret.com/rest/food/v5";
const DEFAULT_TIMEOUT_MS = 6000;
const MIN_MATCH_SCORE = 96;

interface FatSecretOptions {
  readonly clientId: string;
  readonly clientSecret: string;
  readonly timeoutMs?: number;
  readonly fetchFn?: typeof fetch;
}

interface FatSecretSearchFood {
  readonly food_id?: string | number;
  readonly food_name?: string;
  readonly food_type?: string;
  readonly brand_name?: string;
}

interface FatSecretServing {
  readonly serving_id?: string | number;
  readonly serving_description?: string;
  readonly metric_serving_amount?: string | number;
  readonly metric_serving_unit?: string;
  readonly number_of_units?: string | number;
  readonly measurement_description?: string;
  readonly calories?: string | number;
  readonly protein?: string | number;
  readonly carbohydrate?: string | number;
  readonly fat?: string | number;
  readonly fiber?: string | number;
  readonly saturated_fat?: string | number;
  readonly trans_fat?: string | number;
  readonly added_sugars?: string | number;
  readonly sodium?: string | number;
  readonly calcium?: string | number;
  readonly phosphorus?: string | number;
  readonly vitamin_d?: string | number;
}

interface CachedToken {
  readonly value: string;
  readonly expiresAtMs: number;
}

export class FatSecretResolver implements FoodNutritionResolver {
  readonly name = "fatsecret" as const;

  readonly #clientId: string;
  readonly #clientSecret: string;
  readonly #timeoutMs: number;
  readonly #fetch: typeof fetch;
  #token: CachedToken | null = null;
  #tokenPromise: Promise<string | null> | null = null;

  constructor(options: FatSecretOptions) {
    this.#clientId = options.clientId;
    this.#clientSecret = options.clientSecret;
    this.#timeoutMs = options.timeoutMs ?? DEFAULT_TIMEOUT_MS;
    this.#fetch = options.fetchFn ?? fetch;
  }

  async resolve(
    candidate: MealCandidate,
    signal?: AbortSignal,
    context?: NutritionResolverContext,
  ): Promise<ResolverResult> {
    if (!this.#clientId || !this.#clientSecret) return { kind: "unavailable" };
    if (candidate.quantity === null || candidate.unit === null) {
      return { kind: "incomplete", reason: "missing_amount" };
    }

    const region = fatSecretRegionForCountry(context?.countryCode);
    if (region === null) return { kind: "incomplete", reason: "region_unsupported" };

    const token = await this.#getToken(signal);
    if (token === null) return { kind: "unavailable" };

    const search = await this.#search(candidate.foodName, token, region, signal);
    if (search.kind !== "ok") return search.result;

    const match = selectFatSecretMatch(candidate.foodName, search.foods);
    if (match === null) {
      // Foods came back but none is a safe identity match (or two tie): that is
      // `name_mismatch`, the same condition Edamam reports. `no_match` is only
      // for a search that found nothing.
      return {
        kind: "incomplete",
        reason: search.foods.length === 0 ? "no_match" : "name_mismatch",
      };
    }
    if (match.food_id === undefined) {
      return { kind: "incomplete", reason: "no_match" };
    }

    const detail = await this.#getFood(String(match.food_id), token, region, signal);
    if (detail.kind !== "ok") return detail.result;

    const serving = fatSecretServingOutcome(candidate, detail.food);
    return serving.item === null
      ? { kind: "incomplete", reason: serving.reason }
      : { kind: "resolved", item: serving.item };
  }

  async #getToken(signal?: AbortSignal): Promise<string | null> {
    if (this.#token !== null && this.#token.expiresAtMs > Date.now()) {
      return this.#token.value;
    }
    if (this.#tokenPromise !== null) return this.#tokenPromise;

    this.#tokenPromise = this.#requestToken(signal);
    try {
      return await this.#tokenPromise;
    } finally {
      this.#tokenPromise = null;
    }
  }

  async #requestToken(signal?: AbortSignal): Promise<string | null> {
    if (!this.#clientId || !this.#clientSecret) return null;
    const response = await this.#boundedFetch(TOKEN_URL, {
      method: "POST",
      headers: {
        Authorization: `Basic ${btoa(`${this.#clientId}:${this.#clientSecret}`)}`,
        "Content-Type": "application/x-www-form-urlencoded",
      },
      body: new URLSearchParams({
        grant_type: "client_credentials",
        scope: "basic",
      }),
    }, signal);
    if (response === null || !response.ok) return null;

    try {
      const body = (await response.json()) as Record<string, unknown>;
      const accessToken = typeof body.access_token === "string" ? body.access_token : "";
      const expiresIn = finitePositiveNumber(body.expires_in) ?? 3600;
      if (!accessToken) return null;
      this.#token = {
        value: accessToken,
        expiresAtMs: Date.now() + Math.max(60, expiresIn - 60) * 1000,
      };
      return accessToken;
    } catch {
      return null;
    }
  }

  async #search(
    query: string,
    token: string,
    region: string,
    signal?: AbortSignal,
  ): Promise<
    | { readonly kind: "ok"; readonly foods: readonly FatSecretSearchFood[] }
    | { readonly kind: "fail"; readonly result: ResolverResult }
  > {
    const body = new URLSearchParams({
      method: "foods.search",
      search_expression: query,
      max_results: "8",
      page_number: "0",
      format: "json",
      region,
    });
    const response = await this.#boundedFetch(SEARCH_URL, {
      method: "POST",
      headers: {
        Authorization: `Bearer ${token}`,
        "Content-Type": "application/x-www-form-urlencoded",
      },
      body,
    }, signal);
    if (response === null || !response.ok) {
      return { kind: "fail", result: { kind: "unavailable" } };
    }

    try {
      const payload = (await response.json()) as Record<string, unknown>;
      if (payload.error !== undefined) {
        return { kind: "fail", result: { kind: "unavailable" } };
      }
      const foodsContainer = payload.foods;
      if (foodsContainer === null || typeof foodsContainer !== "object") {
        return { kind: "ok", foods: [] };
      }
      const rawFood = (foodsContainer as Record<string, unknown>).food;
      const foods = toArray(rawFood).filter(isSearchFood);
      return { kind: "ok", foods };
    } catch {
      return { kind: "fail", result: { kind: "unavailable" } };
    }
  }

  async #getFood(
    foodId: string,
    token: string,
    region: string,
    signal?: AbortSignal,
  ): Promise<
    | { readonly kind: "ok"; readonly food: Record<string, unknown> }
    | { readonly kind: "fail"; readonly result: ResolverResult }
  > {
    const url = new URL(FOOD_URL);
    url.searchParams.set("food_id", foodId);
    url.searchParams.set("format", "json");
    url.searchParams.set("region", region);

    const response = await this.#boundedFetch(url, {
      headers: { Authorization: `Bearer ${token}` },
    }, signal);
    if (response === null || !response.ok) {
      return { kind: "fail", result: { kind: "unavailable" } };
    }

    try {
      const payload = (await response.json()) as Record<string, unknown>;
      if (payload.error !== undefined) {
        return { kind: "fail", result: { kind: "unavailable" } };
      }
      const raw = payload.food;
      const food = raw !== null && typeof raw === "object" && !Array.isArray(raw)
        ? raw as Record<string, unknown>
        : payload;
      return { kind: "ok", food };
    } catch {
      return { kind: "fail", result: { kind: "unavailable" } };
    }
  }

  async #boundedFetch(
    input: RequestInfo | URL,
    init?: RequestInit,
    signal?: AbortSignal,
  ): Promise<Response | null> {
    return fetchWithTimeout(this.#fetch, input, init, this.#timeoutMs, signal);
  }
}

export function fatSecretRegionForCountry(countryCode: string | undefined): string | null {
  if (countryCode === undefined) return null;
  const trimmed = countryCode.trim();
  return trimmed === "US" ? trimmed : null;
}

function toArray(value: unknown): unknown[] {
  if (Array.isArray(value)) return value;
  if (value === null || value === undefined) return [];
  return [value];
}

function isSearchFood(value: unknown): value is FatSecretSearchFood {
  return value !== null && typeof value === "object" && !Array.isArray(value);
}

export function selectFatSecretMatch(
  query: string,
  foods: readonly FatSecretSearchFood[],
): FatSecretSearchFood | null {
  const ranked = foods
    .filter((food) =>
      typeof food.food_name === "string" &&
      food.food_name.trim().length > 0 &&
      isSafeFoodIdentityMatch(query, food.food_name)
    )
    .map((food) => {
      const genericBonus = normalizeName(food.food_type ?? "") === "generic" ? 2 : 0;
      return { food, score: matchScore(query, food.food_name!) + genericBonus };
    })
    .filter((entry) => entry.score >= MIN_MATCH_SCORE)
    .sort((a, b) => b.score - a.score);

  const top = ranked[0];
  if (top === undefined) return null;

  const second = ranked[1];
  if (
    second !== undefined &&
    second.score === top.score &&
    String(second.food.food_id ?? "") !== String(top.food.food_id ?? "")
  ) {
    return null;
  }
  return top.food;
}

export function resolveFatSecretServing(
  candidate: MealCandidate,
  food: Record<string, unknown>,
): ResponseItem | null {
  return fatSecretServingOutcome(candidate, food).item;
}

/**
 * The serving item, or why there is none: no serving fits the requested unit
 * (`unit_mismatch`) or the serving that fits carries no usable nutrients
 * (`nutrients_missing`).
 */
function fatSecretServingOutcome(
  candidate: MealCandidate,
  food: Record<string, unknown>,
):
  | { readonly item: ResponseItem; readonly reason?: undefined }
  | { readonly item: null; readonly reason: "unit_mismatch" | "nutrients_missing" } {
  const noServing = { item: null, reason: "unit_mismatch" } as const;
  if (candidate.quantity === null || candidate.unit === null) return noServing;

  const servingsContainer = food.servings;
  if (servingsContainer === null || typeof servingsContainer !== "object") return noServing;
  const servings = toArray((servingsContainer as Record<string, unknown>).serving)
    .filter((value): value is FatSecretServing =>
      value !== null && typeof value === "object" && !Array.isArray(value)
    );
  if (servings.length === 0) return noServing;

  const chosen = chooseServing(candidate, servings);
  if (chosen === null) return noServing;

  const nutrients: Partial<Record<CanonicalNutrientKey, number>> = {};
  const mappings: readonly [CanonicalNutrientKey, keyof FatSecretServing][] = [
    ["energy", "calories"],
    ["protein", "protein"],
    ["carbohydrate", "carbohydrate"],
    ["fat", "fat"],
    ["fiber", "fiber"],
    ["saturated_fat", "saturated_fat"],
    ["trans_fat", "trans_fat"],
    ["added_sugar", "added_sugars"],
    ["sodium", "sodium"],
    ["calcium", "calcium"],
    ["phosphorus", "phosphorus"],
    ["vitamin_d", "vitamin_d"],
  ];
  for (const [target, source] of mappings) {
    const amount = finiteNonNegativeNumber(chosen.serving[source]);
    if (amount !== null) nutrients[target] = amount * chosen.scale;
  }

  const snapshot = canonicalSnapshot(nutrients);
  if (snapshot === null) return { item: null, reason: "nutrients_missing" };

  const rawName = food.food_name;
  const displayName = typeof rawName === "string" && rawName.trim()
    ? rawName.trim()
    : candidate.foodName;

  return {
    item: {
      displayName,
      quantity: candidate.quantity,
      servingUnit: candidate.unit,
      nutritionSnapshot: snapshot,
    },
  };
}

function chooseServing(
  candidate: MealCandidate,
  servings: readonly FatSecretServing[],
): { readonly serving: FatSecretServing; readonly scale: number } | null {
  if (candidate.quantity === null || candidate.unit === null) return null;
  const metricTarget = toMetricAmount(candidate.quantity, candidate.unit);
  if (metricTarget !== null) {
    const compatible = servings.flatMap((serving) => {
      const providerAmount = finitePositiveNumber(serving.metric_serving_amount);
      const providerUnit = normalizeUnit(serving.metric_serving_unit ?? "");
      if (providerAmount === null) return [];

      const providerMetric = providerUnit === "g"
        ? { amount: providerAmount, unit: "g" as const }
        : providerUnit === "ml"
        ? { amount: providerAmount, unit: "ml" as const }
        : providerUnit === "oz"
        ? { amount: providerAmount * 28.349523125, unit: "g" as const }
        : null;
      if (providerMetric === null || providerMetric.unit !== metricTarget.unit) return [];

      const scale = metricTarget.amount / providerMetric.amount;
      if (!Number.isFinite(scale) || scale <= 0) return [];
      return [{ serving, scale, distance: Math.abs(Math.log(scale)) }];
    });
    compatible.sort((a, b) => a.distance - b.distance);
    const best = compatible[0];
    return best ? { serving: best.serving, scale: best.scale } : null;
  }

  const unit = normalizeUnit(candidate.unit);
  const compatible = servings.flatMap((serving) => {
    const measurement = normalizeUnit(serving.measurement_description ?? "");
    if (measurement !== unit) return [];
    const providerUnits = finitePositiveNumber(serving.number_of_units) ?? 1;
    const scale = candidate.quantity! / providerUnits;
    if (!Number.isFinite(scale) || scale <= 0) return [];
    return [{ serving, scale }];
  });
  if (compatible.length !== 1) return null;
  return compatible[0];
}
