import type { InterpretationResult, MealInterpreter } from "./types.ts";

export type MealInterpreterProvider = "gemini" | "openai";

export type InterpreterSelection =
  | {
      readonly ok: true;
      readonly primary: MealInterpreterProvider;
      readonly fallback: MealInterpreterProvider;
    }
  | { readonly ok: false };

/**
 * Parses `MEAL_INTERPRETER_PRIMARY`. Missing/empty keeps the Gemini default;
 * only the exact values `gemini` and `openai` are accepted. Any other value is
 * a configuration error and never silently selects a provider.
 */
export function parseInterpreterSelection(
  value: string | undefined | null,
): InterpreterSelection {
  const normalized = value?.trim() ?? "";
  if (normalized === "" || normalized === "gemini") {
    return { ok: true, primary: "gemini", fallback: "openai" };
  }
  if (normalized === "openai") {
    return { ok: true, primary: "openai", fallback: "gemini" };
  }
  return { ok: false };
}

/**
 * Runs the primary interpreter, then the fallback only when the primary is
 * `unavailable` (provider/transport/timeout/malformed output) and the parent
 * request is still active. `recognized` and `unrecognized` are final. Calls are
 * strictly sequential; providers never run in parallel.
 */
export class FallbackMealInterpreter implements MealInterpreter {
  readonly #primary: MealInterpreter;
  readonly #fallback: MealInterpreter;

  constructor(primary: MealInterpreter, fallback: MealInterpreter) {
    this.#primary = primary;
    this.#fallback = fallback;
  }

  async interpret(
    mealText: string,
    signal?: AbortSignal,
  ): Promise<InterpretationResult> {
    if (signal?.aborted) return { kind: "unavailable" };

    const first = await safeInterpret(this.#primary, mealText, signal);
    if (first.kind !== "unavailable") return first;
    if (signal?.aborted) return { kind: "unavailable" };

    const second = await safeInterpret(this.#fallback, mealText, signal);
    if (signal?.aborted) return { kind: "unavailable" };
    return second;
  }
}

/** Configuration error: never calls a provider. */
class MisconfiguredMealInterpreter implements MealInterpreter {
  async interpret(): Promise<InterpretationResult> {
    return { kind: "unavailable" };
  }
}

export function selectMealInterpreter(
  selectorValue: string | undefined | null,
  providers: Readonly<Record<MealInterpreterProvider, MealInterpreter>>,
): MealInterpreter {
  const selection = parseInterpreterSelection(selectorValue);
  if (!selection.ok) return new MisconfiguredMealInterpreter();
  return new FallbackMealInterpreter(
    providers[selection.primary],
    providers[selection.fallback],
  );
}

async function safeInterpret(
  interpreter: MealInterpreter,
  mealText: string,
  signal?: AbortSignal,
): Promise<InterpretationResult> {
  try {
    return await interpreter.interpret(mealText, signal);
  } catch {
    return { kind: "unavailable" };
  }
}
