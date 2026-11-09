import { assertEquals, assertExists } from "jsr:@std/assert@1";
import { calculateDistanceKm, corsHeaders, handleNearbyGyms } from "./index.ts";

Deno.test("calculateDistanceKm calculates distance accurately between two coordinates", () => {
  // Distance between New Delhi (28.6139, 77.2090) and Jaipur (26.9124, 75.7873) is ~238 km
  const dist = calculateDistanceKm(28.6139, 77.209, 26.9124, 75.7873);
  assertEquals(dist >= 235 && dist <= 242, true);
});

Deno.test("handleNearbyGyms returns 200 for OPTIONS preflight", async () => {
  const req = new Request("http://localhost/nearby-gyms", {
    method: "OPTIONS",
  });
  const res = await handleNearbyGyms(req);
  assertEquals(res.status, 200);
  assertEquals(res.headers.get("Access-Control-Allow-Origin"), "*");
});

Deno.test("handleNearbyGyms returns 500 when GOOGLE_PLACES_API_KEY is missing", async () => {
  const req = new Request("http://localhost/nearby-gyms", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ latitude: 26.85, longitude: 75.75 }),
  });
  const res = await handleNearbyGyms(
    req,
    () => undefined,
    fetch,
    async () => true,
  );
  assertEquals(res.status, 503);
  const data = await res.json();
  assertExists(data.error);
  assertEquals(data.error.includes("GOOGLE_PLACES_API_KEY"), false);
});

Deno.test("handleNearbyGyms returns 400 when both lat/lng and query are absent", async () => {
  const req = new Request("http://localhost/nearby-gyms", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({}),
  });
  const res = await handleNearbyGyms(
    req,
    () => "fake-api-key",
    fetch,
    async () => true,
  );
  assertEquals(res.status, 400);
  const data = await res.json();
  assertExists(data.error);
});

Deno.test("handleNearbyGyms executes searchNearby and maps places with calculated distance", async () => {
  const mockFetcher = async (
    input: string | URL | Request,
    init?: RequestInit,
  ) => {
    assertEquals(
      input.toString(),
      "https://places.googleapis.com/v1/places:searchNearby",
    );
    const body = JSON.parse(init?.body as string);
    assertEquals(body.includedTypes, ["gym", "fitness_center"]);
    assertEquals(body.locationRestriction.circle.center.latitude, 26.85);

    return new Response(
      JSON.stringify({
        places: [
          {
            id: "place_1",
            displayName: { text: "Sky Fitness" },
            formattedAddress: "Mansarovar, Jaipur",
            location: { latitude: 26.86, longitude: 75.76 },
          },
        ],
      }),
      { status: 200, headers: { "Content-Type": "application/json" } },
    );
  };

  const req = new Request("http://localhost/nearby-gyms", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ latitude: 26.85, longitude: 75.75 }),
  });

  const res = await handleNearbyGyms(
    req,
    () => "fake-api-key",
    mockFetcher as any,
    async () => true,
  );
  assertEquals(res.status, 200);
  const data = await res.json();
  assertEquals(data.gyms.length, 1);
  assertEquals(data.gyms[0].name, "Sky Fitness");
  assertEquals(data.gyms[0].address, "Mansarovar, Jaipur");
  assertExists(data.gyms[0].distanceKm);
});

Deno.test("handleNearbyGyms executes searchText when query is provided", async () => {
  const mockFetcher = async (
    input: string | URL | Request,
    init?: RequestInit,
  ) => {
    assertEquals(
      input.toString(),
      "https://places.googleapis.com/v1/places:searchText",
    );
    const body = JSON.parse(init?.body as string);
    assertEquals(body.textQuery, "Gold Gym");

    return new Response(
      JSON.stringify({
        places: [
          {
            id: "place_2",
            displayName: { text: "Gold Gym" },
            formattedAddress: "Tonk Road, Jaipur",
            location: { latitude: 26.88, longitude: 75.8 },
          },
        ],
      }),
      { status: 200, headers: { "Content-Type": "application/json" } },
    );
  };

  const req = new Request("http://localhost/nearby-gyms", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ query: "Gold Gym" }),
  });

  const res = await handleNearbyGyms(
    req,
    () => "fake-api-key",
    mockFetcher as any,
    async () => true,
  );
  assertEquals(res.status, 200);
  const data = await res.json();
  assertEquals(data.gyms.length, 1);
  assertEquals(data.gyms[0].name, "Gold Gym");
});

Deno.test("handleNearbyGyms rejects anonymous callers before Places access", async () => {
  let placesCalled = false;
  const req = new Request("http://localhost/nearby-gyms", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ latitude: 26.85, longitude: 75.75 }),
  });
  const res = await handleNearbyGyms(
    req,
    () => "fake-api-key",
    async () => {
      placesCalled = true;
      return new Response("{}");
    },
    async () => false,
  );
  assertEquals(res.status, 401);
  assertEquals(placesCalled, false);
});

Deno.test("handleNearbyGyms bounds location, query, radius, and request size", async () => {
  const cases = [
    { latitude: 91, longitude: 0 },
    { latitude: 0 },
    { latitude: 0, longitude: 0, radiusMeters: 50001 },
    { query: "x".repeat(101) },
  ];
  for (const input of cases) {
    const req = new Request("http://localhost/nearby-gyms", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(input),
    });
    const res = await handleNearbyGyms(
      req,
      () => "fake-api-key",
      fetch,
      async () => true,
    );
    assertEquals(res.status, 400);
  }
});

Deno.test("handleNearbyGyms hides upstream error details", async () => {
  const req = new Request("http://localhost/nearby-gyms", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ query: "Gym" }),
  });
  const res = await handleNearbyGyms(
    req,
    () => "fake-api-key",
    async () => new Response("sensitive upstream payload", { status: 403 }),
    async () => true,
  );
  assertEquals(res.status, 502);
  const data = await res.json();
  assertEquals(
    JSON.stringify(data).includes("sensitive upstream payload"),
    false,
  );
});
