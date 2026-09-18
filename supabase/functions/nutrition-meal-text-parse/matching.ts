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

export function tokenSimilarity(left: string, right: string): number {
  const a = new Set(normalizeName(left).split(" ").filter(Boolean));
  const b = new Set(normalizeName(right).split(" ").filter(Boolean));
  if (a.size === 0 || b.size === 0) return 0;

  let intersection = 0;
  for (const token of a) {
    if (b.has(token)) intersection += 1;
  }
  const union = new Set([...a, ...b]).size;
  return union === 0 ? 0 : intersection / union;
}

export function matchScore(query: string, providerName: string): number {
  const q = normalizeName(query);
  const p = normalizeName(providerName);
  if (!q || !p) return 0;
  if (q === p) return 100;
  if (p.startsWith(`${q} `) || q.startsWith(`${p} `)) return 92;

  const qTokens = q.split(" ").filter(Boolean);
  const pTokens = p.split(" ").filter(Boolean);
  if (qTokens.every((token) => pTokens.includes(token))) return 86;
  if (pTokens.every((token) => qTokens.includes(token))) return 84;

  return Math.round(tokenSimilarity(q, p) * 80);
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

  // A successful factual item must contain at least one known nutrient. Missing
  // nutrients stay absent; zero remains an explicit known zero.
  if (Object.keys(clean).length === 0) return null;

  return {
    schemaVersion: NUTRITION_SCHMA_VERSION,
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
