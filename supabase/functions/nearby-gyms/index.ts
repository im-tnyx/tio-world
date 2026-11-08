// Supabase Edge Function: nearby-gyms
// Proxies Google Places API (New) to search for nearby gyms securely using server-held GOOGLE_PLACES_API_KEY.

export const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers':
    'authorization, x-client-info, apikey, content-type',
};

export function calculateDistanceKm(
  lat1: number,
  lon1: number,
  lat2: number,
  lon2: number,
): number {
  const R = 6371; // Earth's radius in kilometers
  const dLat = ((lat2 - lat1) * Math.PI) / 180;
  const dLon = ((lon2 - lon1) * Math.PI) / 180;
  const a =
    Math.sin(dLat / 2) * Math.sin(dLat / 2) +
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

export async function handleNearbyGyms(
  req: Request,
  envKeyGetter: (key: string) => string | undefined = (k) => Deno.env.get(k),
  fetcher: typeof fetch = fetch,
): Promise<Response> {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  const apiKey =
    envKeyGetter('GOOGLE_PLACES_API_KEY') ||
    envKeyGetter('GOOGLE_MAPS_API_KEY');

  if (!apiKey) {
    return new Response(
      JSON.stringify({
        error: 'GOOGLE_PLACES_API_KEY secret is not configured in Supabase.',
        gyms: [],
      }),
      {
        status: 500,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      },
    );
  }

  let body: {
    latitude?: number;
    longitude?: number;
    query?: string;
    radiusMeters?: number;
  } = {};

  try {
    body = await req.json();
  } catch {
    body = {};
  }

  const { latitude, longitude, query } = body;
  const radiusMeters = body.radiusMeters ?? 10000;

  let url = 'https://places.googleapis.com/v1/places:searchNearby';
  let requestBody: Record<string, unknown> = {};

  const cleanQuery = query?.trim();

  if (cleanQuery && cleanQuery.length > 0) {
    url = 'https://places.googleapis.com/v1/places:searchText';
    requestBody = {
      textQuery: cleanQuery,
      includedType: 'gym',
      maxResultCount: 15,
      ...(latitude != null && longitude != null
        ? {
            locationBias: {
              circle: {
                center: { latitude, longitude },
                radius: radiusMeters,
              },
            },
          }
        : {}),
    };
  } else if (latitude != null && longitude != null) {
    url = 'https://places.googleapis.com/v1/places:searchNearby';
    requestBody = {
      includedTypes: ['gym', 'fitness_center'],
      maxResultCount: 15,
      locationRestriction: {
        circle: {
          center: { latitude, longitude },
          radius: radiusMeters,
        },
      },
    };
  } else {
    return new Response(
      JSON.stringify({
        error: 'Either latitude/longitude or search query must be provided.',
        gyms: [],
      }),
      {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      },
    );
  }

  try {
    const googleRes = await fetcher(url, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'X-Goog-Api-Key': apiKey,
        'X-Goog-FieldMask':
          'places.id,places.displayName,places.formattedAddress,places.location',
      },
      body: JSON.stringify(requestBody),
    });

    if (!googleRes.ok) {
      const errText = await googleRes.text();
      return new Response(
        JSON.stringify({
          error: `Google Places API returned status ${googleRes.status}: ${errText}`,
          gyms: [],
        }),
        {
          status: googleRes.status >= 500 ? 502 : googleRes.status,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        },
      );
    }

    const data = await googleRes.json();
    const places = Array.isArray(data.places) ? data.places : [];

    const gyms: GymPlaceDto[] = places.map((place: any) => {
      const placeLat = place.location?.latitude;
      const placeLng = place.location?.longitude;
      let distanceKm: number | null = null;

      if (
        latitude != null &&
        longitude != null &&
        placeLat != null &&
        placeLng != null
      ) {
        distanceKm = calculateDistanceKm(latitude, longitude, placeLat, placeLng);
      }

      return {
        id: place.id ?? '',
        name: place.displayName?.text ?? 'Gym',
        address: place.formattedAddress ?? '',
        distanceKm,
        latitude: placeLat,
        longitude: placeLng,
      };
    });

    if (latitude != null && longitude != null) {
      gyms.sort(
        (a, b) => (a.distanceKm ?? 999999) - (b.distanceKm ?? 999999),
      );
    }

    return new Response(JSON.stringify({ gyms }), {
      status: 200,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  } catch (err: any) {
    return new Response(
      JSON.stringify({
        error: `Unexpected error invoking Google Places API: ${err?.message ?? err}`,
        gyms: [],
      }),
      {
        status: 500,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      },
    );
  }
}

// Default entry point for Deno server in Supabase Functions
if (import.meta.main) {
  Deno.serve((req) => handleNearbyGyms(req));
}
