import type { ResponseItem } from "./contract.ts";
import type { MealParserIncompleteReason } from "./diagnostics.ts";

export interface MealCandidate {
  readonly foodName: string;
  readonly quantity: number | null;
  readonly unit: string | null;
}

export type InterpretationResult =
  | {
      readonly kind: "recognized";
      readonly mealName?: string;
      readonly items: readonly MealCandidate[];
    }
  | { readonly kind: "unrecognized" }
  | { readonly kind: "unavailable" };

export type ResolverResult =
  | { readonly kind: "resolved"; readonly item: ResponseItem }
  | { readonly kind: "incomplete"; readonly reason?: MealParserIncompleteReason }
  | { readonly kind: "unavailable" };

export interface NutritionResolverContext {
  readonly countryCode: string;
}

export interface FoodNutritionResolver {
  readonly name: "fatsecret" | "edamam";
  resolve(
    candidate: MealCandidate,
    signal?: AbortSignal,
    context?: NutritionResolverContext,
  ): Promise<ResolverResult>;
}

export interface MealInterpreter {
  interpret(mealText: string, signal?: AbortSignal): Promise<InterpretationResult>;
}
