// Supabase Edge Function: nearby-gyms
// Proxies Google Places API (New) with signed-in-user validation and bounded input.

export const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

const maximumBodyBytes = 4096;
const maximumQueryLength = 100;
const maximumRadiusMeters = 50000;
const minimumRadiusMeters = 1000;
const maximumResults = 15;

type EnvironmentGetter = (key: string) => string | undefined;
type UserVerifier = (
  req: Request,
  env: EnvironmentGetter,
) => Promise<boolean>;

export function calculateDistanceKm(
  lat1: number,
  lon1: number,
  lat2: number,
  lon2: number,
): number {
  const R = 6371;
  const dLat = ((lat2 - lat1) * Math.PI) / 180;
  const dLon = ((lon2 - lon1) * Math.PI) / 180;
  const a = Math.sin(dLat / 2) * Math.sin(dLat / 2) +
    Math.cos((lat1 * Math.PI) / 180) *
      Math.cos((lat2 * Math.PI) / 180) *
      Math.sin(dLon / 2) *
      Math.sin(dLon / 2);
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  return Math.round(R * c * 100) / 100;
}

export interface GymPlaceDto {
  id: string;
  name: string;
  address: string;
  distanceKm: number | null;
  latitude?: number;
  longitude?: number;
}

async function verifySignedInUser(
  req: Request,
  env: EnvironmentGetter,
): Promise<boolean> {
  const authorization = req.headers.get("authorization");
  const supabaseUrl = env("SUPABASE_URL");
  const publishableKey = env("SUPABASE_ANON_KEY");
  if (
    !authorization?.startsWith("Bearer ") || !supabaseUrl || !publishableKey
  ) {
    return false;
  }
  try {
    const response = await fetch(
      `${supabaseUrl.replace(/\/$/, "")}/auth/v1/user`,
      {
        headers: {
          apikey: publishableKey,
          authorization,
        },
      },
    );
    if (!response.ok) return false;
    const user: unknown = await response.json();
    return typeof user === "object" && user !== null &&
      "id" in user && typeof user.id === "string" && user.id.length > 0;
  } catch {
    return false;
  }
}

function jsonResponse(body: Record<string, unknown>, status: number): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

export async function handleNearbyGyms(
  req: Request,
  envKeyGetter: EnvironmentGetter = (key) => Deno.env.get(key),
  fetcher: typeof fetch = fetch,
  userVerifier: UserVerifier = verifySignedInUser,
): Promise<Response> {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }
  if (req.method !== "POST") {
    return jsonResponse({ error: "Method not allowed", gyms: [] }, 405);
  }

  if (!await userVerifier(req, envKeyGetter)) {
    return jsonResponse({ error: "Authentication required", gyms: [] }, 401);
  }

  const apiKey = envKeyGetter("GOOGLE_PLACES_API_KEY");
  if (!apiKey) {
    return jsonResponse({
      error: "Gym search is temporarily unavailable",
      gyms: [],
    }, 503);
  }

  const contentLength = Number(req.headers.get("content-length") ?? "0");
  if (contentLength > maximumBodyBytes) {
    return jsonResponse({ error: "Invalid search request", gyms: [] }, 400);
  }

  let body: unknown;
  try {
    const raw = await req.text();
    if (new TextEncoder().encode(raw).length > maximumBodyBytes) {
      return jsonResponse({ error: "Invalid search request", gyms: [] }, 400);
    }
    body = JSON.parse(raw);
  } catch {
    return jsonResponse({ error: "Invalid search request", gyms: [] }, 400);
  }
  if (typeof body !== "object" || body === null || Array.isArray(body)) {
    return jsonResponse({ error: "Invalid search request", gyms: [] }, 400);
  }

  const input = body as Record<string, unknown>;
  const latitude = input.latitude;
  const longitude = input.longitude;
  const rawQuery = input.query;
  const rawRadius = input.radiusMeters;
  const hasLatitude = latitude !== undefined && latitude !== null;
  const hasLongitude = longitude !== undefined && longitude !== null;
  if (hasLatitude !== hasLongitude) {
    return jsonResponse({ error: "Invalid search request", gyms: [] }, 400);
  }
  if (
    hasLatitude &&
    (typeof latitude !== "number" || !Number.isFinite(latitude) ||
      latitude < -90 || latitude > 90 ||
      typeof longitude !== "number" || !Number.isFinite(longitude) ||
      longitude < -180 || longitude > 180)
  ) {
    return jsonResponse({ error: "Invalid search request", gyms: [] }, 400);
  }
  if (
    rawQuery !== undefined && rawQuery !== null && typeof rawQuery !== "string"
  ) {
    return jsonResponse({ error: "Invalid search request", gyms: [] }, 400);
  }
  const query = typeof rawQuery === "string" ? rawQuery.trim() : "";
  if (query.length > maximumQueryLength) {
    return jsonResponse({ error: "Invalid search request", gyms: [] }, 400);
  }
  const radiusMeters = rawRadius === undefined || rawRadius === null
    ? 10000
    : rawRadius;
  if (
    typeof radiusMeters !== "number" || !Number.isInteger(radiusMeters) ||
    radiusMeters < minimumRadiusMeters || radiusMeters > maximumRadiusMeters
  ) {
    return jsonResponse({ error: "Invalid search request", gyms: [] }, 400);
  }
  if (!query && !hasLatitude) {
    return jsonResponse({ error: "Invalid search request", gyms: [] }, 400);
  }

  const hasCoordinates = hasLatitude && hasLongitude;
  const url = query
    ? "https://places.googleapis.com/v1/places:searchText"
    : "https://places.googleapis.com/v1/places:searchNearby";
  const requestBody: Record<string, unknown> = query
    ? {
      textQuery: query,
      includedType: "gym",
      maxResultCount: maximumResults,
      ...(hasCoordinates
        ? {
          locationBias: {
            circle: {
              center: { latitude, longitude },
              radius: radiusMeters,
            },
          },
        }
        : {}),
    }
    : {
      includedTypes: ["gym", "fitness_center"],
      maxResultCount: maximumResults,
      locationRestriction: {
        circle: {
          center: { latitude, longitude },
          radius: radiusMeters,
        },
      },
    };

  try {
    const googleRes = await fetcher(url, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "X-Goog-Api-Key": apiKey,
        "X-Goog-FieldMask":
          "places.id,places.displayName,places.formattedAddress,places.location",
      },
      body: JSON.stringify(requestBody),
    });
    if (!googleRes.ok) {
      return jsonResponse({
        error: "Gym search is temporarily unavailable",
        gyms: [],
      }, 502);
    }

    const data: unknown = await googleRes.json();
    const places =
      typeof data === "object" && data !== null && "places" in data &&
        Array.isArray(data.places)
        ? data.places.slice(0, maximumResults)
        : [];
    const gyms: GymPlaceDto[] = places.map((value: unknown) => {
      const place = typeof value === "object" && value !== null
        ? value as Record<string, unknown>
        : {};
      const displayName =
        typeof place.displayName === "object" && place.displayName !== null &&
          "text" in place.displayName &&
          typeof place.displayName.text === "string"
          ? place.displayName.text
          : "Gym";
      const location =
        typeof place.location === "object" && place.location !== null
          ? place.location as Record<string, unknown>
          : {};
      const placeLat = typeof location.latitude === "number" &&
          Number.isFinite(location.latitude)
        ? location.latitude
        : undefined;
      const placeLng = typeof location.longitude === "number" &&
          Number.isFinite(location.longitude)
        ? location.longitude
        : undefined;
      const placeId = typeof place.id === "string" ? place.id : "";
      const address = typeof place.formattedAddress === "string"
        ? place.formattedAddress
        : "";
      const distanceKm =
        hasCoordinates && placeLat !== undefined && placeLng !== undefined
          ? calculateDistanceKm(
            latitude as number,
            longitude as number,
            placeLat,
            placeLng,
          )
          : null;
      return {
        id: placeId,
        name: displayName,
        address,
        distanceKm,
        ...(placeLat === undefined ? {} : { latitude: placeLat }),
        ...(placeLng === undefined ? {} : { longitude: placeLng }),
      };
    });

    if (hasCoordinates) {
      gyms.sort((a, b) =>
        (a.distanceKm ?? Infinity) - (b.distanceKm ?? Infinity)
      );
    }
    return jsonResponse({ gyms }, 200);
  } catch {
    return jsonResponse({
      error: "Gym search is temporarily unavailable",
      gyms: [],
    }, 502);
  }
}

if (import.meta.main) {
  Deno.serve((req) => handleNearbyGyms(req));
}
