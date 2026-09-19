export type MealParserDiagnosticProvider = "gemini" | "openai" | "fatsecret" | "edamam";

export function mealParserDiagnostic(
  stage: string,
  options: {
    readonly provider?: MealParserDiagnosticProvider;
    readonly reason?: string;
    readonly httpStatus?: number;
    readonly providerErrorCategory?: string;
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
  console.info(JSON.stringify(event));
}
