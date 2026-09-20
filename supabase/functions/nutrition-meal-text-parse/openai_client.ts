import type { InterpretationResult, MealInterpreter } from "./types.ts";
import { mealParserDiagnostic } from "./diagnostics.ts";
import { fetchWithTimeout } from "./async_control.ts";
import {
  MEAL_INTERPRETER_INSTRUCTIONS,
  mealTextInput,
  openAiInterpretationSchema,
  parseInterpretationJson,
} from "./interpretation_schema.ts";

// Cost-optimized current catalog model with Structured Outputs + Responses API
// support. `OPENAI_MODEL` overrides it.
export const OPENAI_DEFAULT_MODEL = "gpt-5.6-luna";
// Short extraction does not need deliberation; the model's default effort would
// spend most of the per-provider budget. Only applied to the default model,
// because an overridden model may not accept the same effort value.
const DEFAULT_MODEL_REASONING_EFFORT = "none";
const DEFAULT_TIMEOUT_MS = 8000;
const MAX_OUTPUT_TOKENS = 2048;
const RESPONSES_URL = "https://api.openai.com/v1/responses";

interface OpenAIClientOptions {
  readonly apiKey: string;
  readonly model?: string;
  readonly timeoutMs?: number;
  readonly fetchFn?: typeof fetch;
}

interface OpenAIResponseEnvelope {
  readonly status?: string;
  readonly output?: readonly {
    readonly type?: string;
    readonly content?: readonly {
      readonly type?: string;
      readonly text?: string;
    }[];
  }[];
}

export class OpenAIMealInterpreter implements MealInterpreter {
  readonly #apiKey: string;
  readonly #model: string;
  readonly #timeoutMs: number;
  readonly #fetch: typeof fetch;

  constructor(options: OpenAIClientOptions) {
    this.#apiKey = options.apiKey;
    this.#model = options.model?.trim() || OPENAI_DEFAULT_MODEL;
    this.#timeoutMs = options.timeoutMs ?? DEFAULT_TIMEOUT_MS;
    this.#fetch = options.fetchFn ?? fetch;
  }

  async interpret(
    mealText: string,
    signal?: AbortSignal,
  ): Promise<InterpretationResult> {
    if (!this.#apiKey) {
      mealParserDiagnostic("interpreter_unavailable", { provider: "openai", reason: "missing_configuration" });
      return { kind: "unavailable" };
    }

    const response = await fetchWithTimeout(
      this.#fetch,
      RESPONSES_URL,
      {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          Authorization: `Bearer ${this.#apiKey}`,
        },
        body: JSON.stringify({
          model: this.#model,
          // Disable Responses application-state storage for meal text. Provider
          // abuse-monitoring retention is governed separately by the OpenAI
          // account/data-control configuration.
          store: false,
          instructions: MEAL_INTERPRETER_INSTRUCTIONS.join("\n"),
          input: mealTextInput(mealText),
          max_output_tokens: MAX_OUTPUT_TOKENS,
          ...(this.#model === OPENAI_DEFAULT_MODEL
            ? { reasoning: { effort: DEFAULT_MODEL_REASONING_EFFORT } }
            : {}),
          text: {
            format: {
              type: "json_schema",
              name: "meal_interpretation",
              strict: true,
              schema: openAiInterpretationSchema,
            },
          },
        }),
      },
      this.#timeoutMs,
      signal,
    );

    if (response === null) {
      mealParserDiagnostic("interpreter_unavailable", { provider: "openai", reason: "transport_or_timeout" });
      return { kind: "unavailable" };
    }
    if (!response.ok) {
      mealParserDiagnostic("interpreter_unavailable", { provider: "openai", reason: "http_error", httpStatus: response.status });
      return { kind: "unavailable" };
    }

    try {
      const envelope = (await response.json()) as OpenAIResponseEnvelope;
      const text = extractStructuredText(envelope);
      if (text === null) {
        mealParserDiagnostic("interpreter_unavailable", { provider: "openai", reason: "malformed_response" });
        return { kind: "unavailable" };
      }
      const result = parseInterpretationJson(text);
      if (result.kind === "unavailable") mealParserDiagnostic("interpreter_unavailable", { provider: "openai", reason: "malformed_response" });
      return result;
    } catch {
      mealParserDiagnostic("interpreter_unavailable", { provider: "openai", reason: "malformed_response" });
      return { kind: "unavailable" };
    }
  }
}

/**
 * Returns the single structured output text of a completed response, or null
 * for incomplete/failed responses, refusals, or unexpected shapes.
 */
export function extractStructuredText(
  envelope: OpenAIResponseEnvelope | null,
): string | null {
  if (envelope === null || typeof envelope !== "object") return null;
  if (envelope.status !== "completed" || !Array.isArray(envelope.output)) {
    return null;
  }

  let text: string | null = null;
  for (const item of envelope.output) {
    if (item?.type !== "message" || !Array.isArray(item.content)) continue;
    for (const part of item.content) {
      if (part?.type === "refusal") return null;
      if (part?.type === "output_text" && typeof part.text === "string" && text === null) {
        text = part.text;
      }
    }
  }

  return text !== null && text.trim().length > 0 ? text : null;
}
