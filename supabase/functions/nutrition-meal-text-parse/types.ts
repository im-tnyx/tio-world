import type { ResponseItem } from "./contract.ts";

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
  | { readonly kind: "incomplete" }
  | { readonly kind: "unavailable" };

export interface FoodNutritionResolver {
  readonly name: "fatsecret" | "edamam";
  resolve(candidate: MealCandidate, signal?: AbortSignal): Promise<ResolverResult>;
}

export interface MealInterpreter {
  interpret(mealText: string, signal?: AbortSignal): Promise<InterpretationResult>;
}
