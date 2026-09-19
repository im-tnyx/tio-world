import { fetchWithTimeout } from "./async_control.ts";

const TOKEN_URL = "https://oauth.fatsecret.com/connect/token";
const SEARCH_URL = "https://platform.fatsecret.com/rest/server.api";
const FOOD_URL = "https://platform.fatsecret.com/rest/food/v5";
const TIMEOUT_MS = 6000;

export type FatSecretCapabilityStage = "token" | "search_default" | "detail_default";
export type FatSecretCapabilityCategory =
  | "ok"
  | "authentication"
  | "authorization_or_entitlement"
  | "rate_limit"
  | "invalid_request"
  | "unavailable";

export interface FatSecretCapabilityResult {
  readonly stage: FatSecretCapabilityStage;
  readonly category: FatSecretCapabilityCategory;
  readonly httpStatus?: number;
}

export async function probeFatSecretIndiaCapability(options: {
  readonly clientId: string;
  readonly clientSecret: string;
  readonly fetchFn?: typeof fetch;
  readonly timeoutMs?: number;
}): Promise<readonly FatSecretCapabilityResult[]> {
  const fetchFn = options.fetchFn ?? fetch;
  const timeoutMs = options.timeoutMs ?? TIMEOUT_MS;
  const results: FatSecretCapabilityResult[] = [];

  if (!options.clientId || !options.clientSecret) {
    return [{ stage: "token", category: "authentication" }];
  }

  const tokenResponse = await fetchWithTimeout(fetchFn, TOKEN_URL, {
    method: "POST",
    headers: {
      Authorization: `Basic ${btoa(`${options.clientId}:${options.clientSecret}`)}`,
      "Content-Type": "application/x-www-form-urlencoded",
    },
    body: new URLSearchParams({ grant_type: "client_credentials", scope: "basic" }),
  }, timeoutMs);
  if (tokenResponse === null) return [{ stage: "token", category: "unavailable" }];
  if (!tokenResponse.ok) {
    return [{ stage: "token", category: categoryForStatus(tokenResponse.status), httpStatus: tokenResponse.status }];
  }

  let token = "";
  try {
    const payload = await tokenResponse.json() as Record<string, unknown>;
    token = typeof payload.access_token === "string" ? payload.access_token : "";
  } catch {
    return [{ stage: "token", category: "unavailable", httpStatus: tokenResponse.status }];
  }
  if (!token) return [{ stage: "token", category: "unavailable", httpStatus: tokenResponse.status }];
  results.push({ stage: "token", category: "ok", httpStatus: tokenResponse.status });

  const searchResponse = await fetchWithTimeout(fetchFn, SEARCH_URL, {
    method: "POST",
    headers: {
      Authorization: `Bearer ${token}`,
      "Content-Type": "application/x-www-form-urlencoded",
    },
    body: new URLSearchParams({
      method: "foods.search",
      search_expression: "plain yogurt",
      max_results: "1",
      page_number: "0",
      format: "json",
    }),
  }, timeoutMs);
  if (searchResponse === null) return [...results, { stage: "search_default", category: "unavailable" }];
  if (!searchResponse.ok) {
    return [...results, { stage: "search_default", category: categoryForStatus(searchResponse.status), httpStatus: searchResponse.status }];
  }

  let foodId = "";
  try {
    const payload = await searchResponse.json() as Record<string, unknown>;
    if (payload.error !== undefined) {
      return [...results, { stage: "search_default", category: "authorization_or_entitlement", httpStatus: searchResponse.status }];
    }
    const foods = payload.foods;
    const rawFood = foods !== null && typeof foods === "object"
      ? (foods as Record<string, unknown>).food
      : undefined;
    const first = Array.isArray(rawFood) ? rawFood[0] : rawFood;
    if (first !== null && typeof first === "object" && !Array.isArray(first)) {
      const rawId = (first as Record<string, unknown>).food_id;
      foodId = typeof rawId === "string" || typeof rawId === "number" ? String(rawId) : "";
    }
  } catch {
    return [...results, { stage: "search_default", category: "unavailable", httpStatus: searchResponse.status }];
  }
  if (!foodId) return [...results, { stage: "search_default", category: "invalid_request", httpStatus: searchResponse.status }];
  results.push({ stage: "search_default", category: "ok", httpStatus: searchResponse.status });

  const detailUrl = new URL(FOOD_URL);
  detailUrl.searchParams.set("food_id", foodId);
  detailUrl.searchParams.set("format", "json");
  const detailResponse = await fetchWithTimeout(fetchFn, detailUrl, {
    headers: { Authorization: `Bearer ${token}` },
  }, timeoutMs);
  if (detailResponse === null) return [...results, { stage: "detail_default", category: "unavailable" }];
  if (!detailResponse.ok) {
    return [...results, { stage: "detail_default", category: categoryForStatus(detailResponse.status), httpStatus: detailResponse.status }];
  }
  try {
    const payload = await detailResponse.json() as Record<string, unknown>;
    if (payload.error !== undefined) {
      return [...results, { stage: "detail_default", category: "authorization_or_entitlement", httpStatus: detailResponse.status }];
    }
  } catch {
    return [...results, { stage: "detail_default", category: "unavailable", httpStatus: detailResponse.status }];
  }

  return [...results, { stage: "detail_default", category: "ok", httpStatus: detailResponse.status }];
}

function categoryForStatus(status: number): FatSecretCapabilityCategory {
  if (status === 401) return "authentication";
  if (status === 403) return "authorization_or_entitlement";
  if (status === 429) return "rate_limit";
  if (status >= 400 && status < 500) return "invalid_request";
  return "unavailable";
}
