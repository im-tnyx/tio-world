import type { InterpretationResult, MealInterpreter } from "./types.ts";
import {
  mealParserDiagnostic,
  type MealParserProviderErrorStatus,
} from "./diagnostics.ts";
import { fetchWithTimeout } from "./async_control.ts";
import {
  geminiInterpretationSchema,
  MEAL_INTERPRETER_INSTRUCTIONS,
  mealTextInput,
  parseInterpretationJson,
} from "./interpretation_schema.ts";

const DEFAULT_MODEL = "gemini-3.8-flash";
const DEFAULT_TIMEOUT_MS = 8000;

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
    if (!this.#apiKey) {
      mealParserDiagnostic("interpreter_unavailable", { provider: "gemini", reason: "missing_configuration" });
      return { kind: "unavailable" };
    }

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
            responseFormat: {
              text: {
                mimeType: "application/json",
                schema: geminiInterpretationSchema,
              },
            },
          },
        }),
      },
      this.#timeoutMs,
      signal,
    );

    if (response === null) {
      mealParserDiagnostic("interpreter_unavailable", { provider: "gemini", reason: "transport_or_timeout" });
      return { kind: "unavailable" };
    }
    if (!response.ok) {
      mealParserDiagnostic("interpreter_unavailable", {
        provider: "gemini",
        reason: "http_error",
        httpStatus: response.status,
        providerErrorStatus: await geminiErrorStatus(response),
      });
      return { kind: "unavailable" };
    }

    try {
      const envelope = (await response.json()) as GeminiEnvelope;
      const text = envelope.candidates?.[0]?.content?.parts?.[0]?.text;
      if (typeof text !== "string" || text.trim().length === 0) {
        mealParserDiagnostic("interpreter_unavailable", { provider: "gemini", reason: "malformed_response" });
        return { kind: "unavailable" };
      }
      const result = parseGeminiInterpretation(text);
      if (result.kind === "unavailable") mealParserDiagnostic("interpreter_unavailable", { provider: "gemini", reason: "malformed_response" });
      return result;
    } catch {
      mealParserDiagnostic("interpreter_unavailable", { provider: "gemini", reason: "malformed_response" });
      return { kind: "unavailable" };
    }
  }
}

function buildPrompt(mealText: string): string {
  return [...MEAL_INTERPRETER_INSTRUCTIONS, mealTextInput(mealText)].join("\n");
}

/** Kept for existing callers/tests; normalization is shared across providers. */
export function parseGeminiInterpretation(text: string): InterpretationResult {
  return parseInterpretationJson(text);
}


const GEMINI_ERROR_STATUSES: ReadonlySet<MealParserProviderErrorStatus> = new Set([
  "CANCELLED",
  "UNKNOWN",
  "INVALID_ARGUMENT",
  "DEADLINE_EXCEEDED",
  "NOT_FOUND",
  "ALREADY_EXISTS",
  "PERMISSION_DENIED",
  "RESOURCE_EXHAUSTED",
  "FAILED_PRECONDITION",
  "ABORTED",
  "OUT_OF_RANGE",
  "UNIMPLEMENTED",
  "INTERNAL",
  "UNAVAILABLE",
  "DATA_LOSS",
  "UNAUTHENTICATED",
]);

async function geminiErrorStatus(
  response: Response,
): Promise<MealParserProviderErrorStatus> {
  try {
    const payload = await response.clone().json() as Record<string, unknown>;
    const error = payload.error;
    if (error !== null && typeof error === "object" && !Array.isArray(error)) {
      const status = (error as Record<string, unknown>).status;
      if (
        typeof status === "string" &&
        GEMINI_ERROR_STATUSES.has(status as MealParserProviderErrorStatus)
      ) {
        return status as MealParserProviderErrorStatus;
      }
    }
  } catch {
    // Never log or propagate raw Gemini response content.
  }
  return "UNKNOWN";
}
