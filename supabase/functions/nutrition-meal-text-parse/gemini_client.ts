import type { InterpretationResult, MealInterpreter } from "./types.ts";
import {
  mealParserDiagnostic,
  type MealParserProviderErrorField,
  type MealParserProviderErrorReason,
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
            responseMimeType: "application/json",
            responseSchema: geminiInterpretationSchema,
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
      const metadata = await geminiErrorMetadata(response);
      mealParserDiagnostic("interpreter_unavailable", {
        provider: "gemini",
        reason: "http_error",
        httpStatus: response.status,
        providerErrorStatus: metadata.status,
        providerErrorReason: metadata.reason,
        providerErrorField: metadata.field,
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

const GEMINI_ERROR_STATUSES: ReadonlySet<MealParserProviderErrorStatus> = new Set<MealParserProviderErrorStatus>([
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

const GEMINI_ERROR_REASONS: ReadonlySet<MealParserProviderErrorReason> =
  new Set<MealParserProviderErrorReason>([
    "SERVICE_DISABLED",
    "BILLING_DISABLED",
    "API_KEY_INVALID",
    "API_KEY_SERVICE_BLOCKED",
    "API_KEY_HTTP_REFERRER_BLOCKED",
    "API_KEY_IP_ADDRESS_BLOCKED",
    "API_KEY_ANDROID_APP_BLOCKED",
    "API_KEY_IOS_APP_BLOCKED",
    "RATE_LIMIT_EXCEEDED",
    "RESOURCE_QUOTA_EXCEEDED",
    "UNKNOWN",
  ]);

const GOOGLE_ERROR_INFO_TYPE = "type.googleapis.com/google.rpc.ErrorInfo";
const GOOGLE_BAD_REQUEST_TYPE = "type.googleapis.com/google.rpc.BadRequest";

interface GeminiErrorMetadata {
  readonly status: MealParserProviderErrorStatus;
  readonly reason: MealParserProviderErrorReason;
  readonly field: MealParserProviderErrorField;
}

async function geminiErrorMetadata(
  response: Response,
): Promise<GeminiErrorMetadata> {
  let status: MealParserProviderErrorStatus = "UNKNOWN";
  let reason: MealParserProviderErrorReason = "UNKNOWN";
  let field: MealParserProviderErrorField = "unknown";

  try {
    const payload = await response.clone().json() as Record<string, unknown>;
    const error = asRecord(payload.error);
    if (error === null) return { status, reason, field };

    const rawStatus = error.status;
    if (
      typeof rawStatus === "string" &&
      GEMINI_ERROR_STATUSES.has(rawStatus as MealParserProviderErrorStatus)
    ) {
      status = rawStatus as MealParserProviderErrorStatus;
    }

    const details = error.details;
    if (!Array.isArray(details)) return { status, reason, field };

    for (const rawDetail of details) {
      const detail = asRecord(rawDetail);
      if (detail === null) continue;

      if (
        detail["@type"] === GOOGLE_ERROR_INFO_TYPE &&
        detail.domain === "googleapis.com" &&
        reason === "UNKNOWN"
      ) {
        const rawReason = detail.reason;
        if (
          typeof rawReason === "string" &&
          GEMINI_ERROR_REASONS.has(rawReason as MealParserProviderErrorReason)
        ) {
          reason = rawReason as MealParserProviderErrorReason;
        }
      }

      if (detail["@type"] === GOOGLE_BAD_REQUEST_TYPE && field === "unknown") {
        field = badRequestFieldCategory(detail);
      }
    }
  } catch {
    // Never log or propagate raw Gemini response content.
  }

  return { status, reason, field };
}

function badRequestFieldCategory(
  detail: Readonly<Record<string, unknown>>,
): MealParserProviderErrorField {
  const rawViolations = Array.isArray(detail.fieldViolations)
    ? detail.fieldViolations
    : Array.isArray(detail.field_violations)
    ? detail.field_violations
    : [];

  for (const rawViolation of rawViolations) {
    const violation = asRecord(rawViolation);
    const rawField = violation?.field;
    if (typeof rawField !== "string") continue;

    const compact = rawField.toLowerCase().replace(/[^a-z0-9]/g, "");
    if (compact.includes("schema")) return "schema";
    if (compact.includes("responseformat")) return "response_format";
    if (compact.includes("generationconfig")) return "generation_config";
    if (compact.includes("contents")) return "contents";
    if (compact.includes("model")) return "model";
  }

  return "unknown";
}

function asRecord(value: unknown): Readonly<Record<string, unknown>> | null {
  return value !== null && typeof value === "object" && !Array.isArray(value)
    ? value as Readonly<Record<string, unknown>>
    : null;
}
