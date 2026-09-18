import type {
  FoodNutritionResolver,
  MealCandidate,
  ResolverResult,
} from "./types.ts";

/**
 * Tries the primary resolver first. The secondary is invoked only when the
 * primary cannot safely produce a complete item. A successful item is returned
 * whole from one provider; nutrients are never merged across providers.
 */
export async function resolveWithFallback(
  candidate: MealCandidate,
  primary: FoodNutritionResolver,
  secondary: FoodNutritionResolver | null,
): Promise<ResolverResult> {
  const first = await primary.resolve(candidate);
  if (first.kind === "resolved" || secondary === null) return first;

  const second = await secondary.resolve(candidate);
  if (second.kind === "resolved") return second;

  if (first.kind === "incomplete" || second.kind === "incomplete") {
    return { kind: "incomplete" };
  }
  return { kind: "unavailable" };
}
