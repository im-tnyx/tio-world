const SEARCH_URL = "https://world.openfoodfacts.org/cgi/search.pl";
const TIMEOUT_MS = 6000;

export type OpenFoodFactsCategory = "resolved" | "incomplete" | "unavailable";
export interface OpenFoodFactsProbeResult {
  readonly query: string;
  readonly category: OpenFoodFactsCategory;
  readonly productName?: string;
  readonly per100g?: {
    readonly energyKcal: number;
    readonly proteinG: number;
    readonly carbsG: number;
    readonly fatG: number;
  };
}

export async function probeOpenFoodFacts(
  query: string,
  fetchFn: typeof fetch = fetch,
): Promise<OpenFoodFactsProbeResult> {
  const url = new URL(SEARCH_URL);
  url.searchParams.set("search_terms", query);
  url.searchParams.set("search_simple", "1");
  url.searchParams.set("action", "process");
  url.searchParams.set("json", "1");
  url.searchParams.set("page_size", "5");
  url.searchParams.set("fields", "product_name,nutriments");

  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), TIMEOUT_MS);
  let response: Response;
  try {
    response = await fetchFn(url, {
      signal: controller.signal,
      headers: { "User-Agent": "TioWorld-TNYX238-CapabilityProbe/1.0" },
    });
  } catch {
    return { query, category: "unavailable" };
  } finally {
    clearTimeout(timeout);
  }
  if (!response.ok) return { query, category: "unavailable" };

  try {
    const payload = await response.json() as Record<string, unknown>;
    const products = Array.isArray(payload.products) ? payload.products : [];
    for (const raw of products) {
      if (raw === null || typeof raw !== "object" || Array.isArray(raw)) continue;
      const product = raw as Record<string, unknown>;
      const nutriments = product.nutriments;
      if (nutriments === null || typeof nutriments !== "object" || Array.isArray(nutriments)) continue;
      const n = nutriments as Record<string, unknown>;
      const energyKcal = finite(n["energy-kcal_100g"]);
      const proteinG = finite(n.proteins_100g);
      const carbsG = finite(n.carbohydrates_100g);
      const fatG = finite(n.fat_100g);
      if ([energyKcal, proteinG, carbsG, fatG].some((v) => v === null)) continue;
      const productName = safeName(product.product_name);
      return {
        query,
        category: "resolved",
        ...(productName ? { productName } : {}),
        per100g: { energyKcal: energyKcal!, proteinG: proteinG!, carbsG: carbsG!, fatG: fatG! },
      };
    }
    return { query, category: "incomplete" };
  } catch {
    return { query, category: "unavailable" };
  }
}

function finite(value: unknown): number | null {
  return typeof value === "number" && Number.isFinite(value) && value >= 0 ? value : null;
}
function safeName(value: unknown): string | undefined {
  if (typeof value !== "string") return undefined;
  const clean = value.trim().replace(/[^\p{L}\p{N} .,'()&+\/-]/gu, "").slice(0, 120);
  return clean || undefined;
}
