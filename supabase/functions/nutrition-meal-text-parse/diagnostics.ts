export type MealParserDiagnosticProvider = "gemini" | "openai" | "fatsecret" | "edamam";
export type MealParserProviderErrorCategory =
  | "authentication"
  | "authorization_or_entitlement"
  | "rate_limit"
  | "invalid_request"
  | "unknown";

export type MealParserProviderErrorStatus =
  | "CANCELLED"
  | "UNKNOWN"
  | "INVALID_ARGUMENT"
  | "DEADLINE_EXCEEDED"
  | "NOT_FOUND"
  | "ALREADY_EXISTS"
  | "PERMISSION_DENIED"
  | "RESOURCE_EXHAUSTED"
  | "FAILED_PRECONDITION"
  | "ABORTED"
  | "OUT_OF_RANGE"
  | "UNIMPLEMENTED"
  | "INTERNAL"
  | "UNAVAILABLE"
  | "DATA_LOSS"
  | "UNAUTHENTICATED";

export function mealParserDiagnostic(
  stage: string,
  options: {
    readonly provider?: MealParserDiagnosticProvider;
    readonly reason?: string;
    readonly httpStatus?: number;
    readonly providerErrorCategory?: MealParserProviderErrorCategory;
    readonly providerErrorStatus?: MealParserProviderErrorStatus;
  } = {},
): void {
  const event: Record<string, string | number> = {
    component: "nutrition-meal-text-parse",
    stage,
  };
  if (options.provider !== undefined) event.provider = options.provider;
  if (options.reason !== undefined) event.reason = options.reason;
  if (options.httpStatus !== undefined) event.httpStatus = options.httpStatus;
  if (options.providerErrorCategory !== undefined) event.providerErrorCategory = options.providerErrorCategory;
  if (options.providerErrorStatus !== undefined) event.providerErrorStatus = options.providerErrorStatus;
  console.info(JSON.stringify(event));
}
