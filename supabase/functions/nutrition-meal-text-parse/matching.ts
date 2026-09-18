import {
  CANONICAL_NUTRIENT_KEYS,
  NUTRITION_SCHEMA_VERSION,
  type CanonicalNutrientKey,
  type NutritionSnapshotDto,
} from "./contract.ts";

export function normalizeName(value: string): string {
  return value
    .normalize("NFKD")
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, " ")
    .trim()
    .replace(/\s+/g, " ");
}

/**
 * Conservative factual-food identity score.
 *
 * Provider labels are accepted only when they contain the same normalized food
 * tokens as the interpreted candidate. Token order, punctuation, and a small
 * set of deterministic singular/plural forms may differ. Extra semantic tokens
 * are rejected instead of being treated as a stronger prefix/containment match.
 */
export function matchScore(query: string, providerName: string): number {
  const queryNormalized = normalizeName(query);
  const providerNormalized = normalizeName(providerName);
  if (!queryNormalized || !providerNormalized) return 0;
  if (queryNormalized === providerNormalized) return 100;

  const queryTokens = canonicalFoodTokens(queryNormalized);
  const providerTokens = canonicalFoodTokens(providerNormalized);
  if (!sameTokenMultiset(queryTokens, providerTokens)) return 0;
  return 96;
}

export function isSafeFoodIdentityMatch(
  query: string,
  providerName: string,
): boolean {
  return matchScore(query, providerName) > 0;
}

function canonicalFoodTokens(normalizedName: string): string[] {
  return normalizedName
    .split(" ")
    .filter(Boolean)
    .map(canonicalFoodToken)
    .sort();
}

function canonicalFoodToken(token: string): string {
  if (token.length > 4 && token.endsWith("ies")) {
    return `${token.slice(0, -3)}y`;
  }
  if (token.length > 4 && token.endsWith("oes")) {
    return token.slice(0, -2);
  }
  if (
    token.length > 3 &&
    token.endsWith("s") &&
    !token.endsWith("ss") &&
    !token.endsWith("us") &&
    !token.endsWith("is") &&
    !token.endsWith("ses") &&
    !token.endsWith("xes") &&
    !token.endsWith("zes") &&
    !token.endsWith("ches") &&
    !token.endsWith("shes")
  ) {
    return token.slice(0, -1);
  }
  return token;
}

function sameTokenMultiset(left: readonly string[], right: readonly string[]): boolean {
  if (left.length !== right.length) return false;
  return left.every((token, index) => token === right[index]);
}

export function finitePositiveNumber(value: unknown): number | null {
  const parsed = typeof value === "number" ? value : Number(value);
  return Number.isFinite(parsed) && parsed > 0 ? parsed : null;
}

export function finiteNonNegativeNumber(value: unknown): number | null {
  const parsed = typeof value === "number" ? value : Number(value);
  return Number.isFinite(parsed) && parsed >= 0 ? parsed : null;
}

export function canonicalSnapshot(
  nutrients: Readonly<Partial<Record<CanonicalNutrientKey, number>>>,
): NutritionSnapshotDto | null {
  const clean: Partial<Record<CanonicalNutrientKey, number>> = {};
  for (const key of CANONICAL_NUTRIENT_KEYS) {
    const raw = nutrients[key];
    if (raw === undefined) continue;
    if (!Number.isFinite(raw) || raw < 0) return null;
    clean[key] = raw;
  }

  if (Object.keys(clean).length === 0) return null;

  return {
    schemaVersion: NUTRITION_SCHEMA_VERSION,
    nutrients: clean,
  };
}

export function normalizeUnit(value: string): string {
  const unit = normalizeName(value);
  const aliases: Readonly<Record<string, string>> = {
    gram: "g",
    grams: "g",
    kilogram: "kg",
    kilograms: "kg",
    milliliter: "ml",
    milliliters: "ml",
    millilitre: "ml",
    millilitres: "ml",
    liter: "l",
    liters: "l",
    litre: "l",
    litres: "l",
    ounce: "oz",
    ounces: "oz",
    tablespoon: "tbsp",
    tablespoons: "tbsp",
    teaspoon: "tsp",
    teaspoons: "tsp",
    pieces: "piece",
    items: "item",
    servings: "serving",
  };
  return aliases[unit] ?? unit;
}

export function toMetricAmount(
  quantity: number,
  unit: string,
): { readonly amount: number; readonly unit: "g" | "ml" } | null {
  const normalized = normalizeUnit(unit);
  if (!Number.isFinite(quantity) || quantity <= 0) return null;

  if (normalized === "g") return { amount: quantity, unit: "g" };
  if (normalized === "kg") return { amount: quantity * 1000, unit: "g" };
  if (normalized === "ml") return { amount: quantity, unit: "ml" };
  if (normalized === "l") return { amount: quantity * 1000, unit: "ml" };
  if (normalized === "oz") {
    return { amount: quantity * 28.349523125, unit: "g" };
  }
  return null;
}
