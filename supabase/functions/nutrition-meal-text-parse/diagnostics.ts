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

export type MealParserProviderErrorReason =
  | "SERVICE_DISABLED"
  | "BILLING_DISABLED"
  | "API_KEY_INVALID"
  | "API_KEY_SERVICE_BLOCKED"
  | "API_KEY_HTTP_REFERRER_BLOCKED"
  | "API_KEY_IP_ADDRESS_BLOCKED"
  | "API_KEY_ANDROID_APP_BLOCKED"
  | "API_KEY_IOS_APP_BLOCKED"
  | "RATE_LIMIT_EXCEEDED"
  | "RESOURCE_QUOTA_EXCEEDED"
  | "UNKNOWN";

export type MealParserProviderErrorField =
  | "contents"
  | "generation_config"
  | "response_format"
  | "schema"
  | "model"
  | "unknown";

/**
 * Why a meal ended `incomplete`. A closed set so an event can never carry meal
 * text, a provider body or user data; it says which check stopped the meal, not
 * what the user wrote.
 */
export type MealParserIncompleteReason =
  | "missing_amount"
  | "no_match"
  | "name_mismatch"
  | "amount_mismatch"
  | "unit_mismatch"
  | "nutrients_missing"
  | "region_unsupported"
  | "country_missing"
  | "no_items"
  | "unknown";

/** One event per `incomplete` meal. */
export function mealParserIncompleteDiagnostic(
  reason: MealParserIncompleteReason = "unknown",
): void {
  mealParserDiagnostic("meal_incomplete", { reason });
}

export function mealParserDiagnostic(
  stage: string,
  options: {
    readonly provider?: MealParserDiagnosticProvider;
    readonly reason?: string;
    readonly httpStatus?: number;
    readonly providerErrorCategory?: MealParserProviderErrorCategory;
    readonly providerErrorStatus?: MealParserProviderErrorStatus;
    readonly providerErrorReason?: MealParserProviderErrorReason;
    readonly providerErrorField?: MealParserProviderErrorField;
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
  if (options.providerErrorReason !== undefined) event.providerErrorReason = options.providerErrorReason;
  if (options.providerErrorField !== undefined) event.providerErrorField = options.providerErrorField;
  console.info(JSON.stringify(event));
}
