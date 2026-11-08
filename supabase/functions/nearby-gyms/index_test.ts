import { assertEquals, assertExists } from 'jsr:@std/assert@1';
import {
  calculateDistanceKm,
  corsHeaders,
  handleNearbyGyms,
} from './index.ts';

Deno.test('calculateDistanceKm calculates distance accurately between two coordinates', () => {
  // Distance between New Delhi (28.6139, 77.2090) and Jaipur (26.9124, 75.7873) is ~238 km
  const dist = calculateDistanceKm(28.6139, 77.209, 26.9124, 75.7873);
  assertEquals(dist >= 235 && dist <= 242, true);
});

Deno.test('handleNearbyGyms returns 200 for OPTIONS preflight', async () => {
  const req = new Request('http://localhost/nearby-gyms', {
    method: 'OPTIONS',
  });
  const res = await handleNearbyGyms(req);
  assertEquals(res.status, 200);
  assertEquals(res.headers.get('Access-Control-Allow-Origin'), '*');
});

Deno.test('handleNearbyGyms returns 500 when GOOGLE_PLACES_API_KEY is missing', async () => {
  const req = new Request('http://localhost/nearby-gyms', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ latitude: 26.85, longitude: 75.75 }),
  });
  const res = await handleNearbyGyms(req, () => undefined);
  assertEquals(res.status, 500);
  const data = await res.json();
  assertExists(data.error);
  assertEquals(data.error.includes('GOOGLE_PLACES_API_KEY'), true);
});

Deno.test('handleNearbyGyms returns 400 when both lat/lng and query are absent', async () => {
  const req = new Request('http://localhost/nearby-gyms', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({}),
  });
  const res = await handleNearbyGyms(req, () => 'fake-api-key');
  assertEquals(res.status, 400);
  const data = await res.json();
  assertExists(data.error);
});

Deno.test('handleNearbyGyms executes searchNearby and maps places with calculated distance', async () => {
  const mockFetcher = async (input: string | URL | Request, init?: RequestInit) => {
    assertEquals(
      input.toString(),
      'https://places.googleapis.com/v1/places:searchNearby',
    );
    const body = JSON.parse(init?.body as string);
    assertEquals(body.includedTypes, ['gym', 'fitness_center']);
    assertEquals(body.locationRestriction.circle.center.latitude, 26.85);

    return new Response(
      JSON.stringify({
        places: [
          {
            id: 'place_1',
            displayName: { text: 'Sky Fitness' },
            formattedAddress: 'Mansarovar, Jaipur',
            location: { latitude: 26.86, longitude: 75.76 },
          },
        ],
      }),
      { status: 200, headers: { 'Content-Type': 'application/json' } },
    );
  };

  const req = new Request('http://localhost/nearby-gyms', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ latitude: 26.85, longitude: 75.75 }),
  });

  const res = await handleNearbyGyms(req, () => 'fake-api-key', mockFetcher as any);
  assertEquals(res.status, 200);
  const data = await res.json();
  assertEquals(data.gyms.length, 1);
  assertEquals(data.gyms[0].name, 'Sky Fitness');
  assertEquals(data.gyms[0].address, 'Mansarovar, Jaipur');
  assertExists(data.gyms[0].distanceKm);
});

Deno.test('handleNearbyGyms executes searchText when query is provided', async () => {
  const mockFetcher = async (input: string | URL | Request, init?: RequestInit) => {
    assertEquals(
      input.toString(),
      'https://places.googleapis.com/v1/places:searchText',
    );
    const body = JSON.parse(init?.body as string);
    assertEquals(body.textQuery, 'Gold Gym');

    return new Response(
      JSON.stringify({
        places: [
          {
            id: 'place_2',
            displayName: { text: 'Gold Gym' },
            formattedAddress: 'Tonk Road, Jaipur',
            location: { latitude: 26.88, longitude: 75.8 },
          },
        ],
      }),
      { status: 200, headers: { 'Content-Type': 'application/json' } },
    );
  };

  const req = new Request('http://localhost/nearby-gyms', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ query: 'Gold Gym' }),
  });

  const res = await handleNearbyGyms(req, () => 'fake-api-key', mockFetcher as any);
  assertEquals(res.status, 200);
  const data = await res.json();
  assertEquals(data.gyms.length, 1);
  assertEquals(data.gyms[0].name, 'Gold Gym');
});
