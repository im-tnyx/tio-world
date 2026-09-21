import test from "node:test";
import assert from "node:assert/strict";

import { EdamamResolver, edamamMeasureCategory } from "./edamam_client.ts";

const candidate = { foodName: "plain yogurt", quantity: 200, unit: "g" } as const;

async function captureDiagnostic(response: Response): Promise<Record<string, unknown>> {
  const original = console.info;
  const lines: string[] = [];
  console.info = (value?: unknown) => lines.push(String(value));
  try {
    const resolver = new EdamamResolver({
      appId: "test-app-id",
      appKey: "test-app-key",
      fetchFn: async () => response,
    });
    assert.deepEqual(await resolver.resolve(candidate), { kind: "unavailable" });
  } finally {
    console.info = original;
  }
  assert.equal(lines.length, 1);
  return JSON.parse(lines[0]) as Record<string, unknown>;
}

test("Edamam 401 diagnostic classifies authentication without raw body leakage", async () => {
  const event = await captureDiagnostic(Response.json({
    code: "authentication_failed",
    message: "secret provider detail test-app-key",
  }, { status: 401 }));

  assert.deepEqual(event, {
    component: "nutrition-meal-text-parse",
    stage: "resolver_unavailable",
    provider: "edamam",
    reason: "http_error",
    httpStatus: 401,
    providerErrorCategory: "authentication",
  });
  assert.equal(JSON.stringify(event).includes("secret provider detail"), false);
  assert.equal(JSON.stringify(event).includes("test-app-key"), false);
});

test("Edamam entitlement-shaped error is reduced to an allowlisted category", async () => {
  const event = await captureDiagnostic(Response.json({
    code: "subscription_required",
    message: "raw message must not be logged",
  }, { status: 401 }));

  assert.equal(event.providerErrorCategory, "authorization_or_entitlement");
  assert.equal(JSON.stringify(event).includes("raw message"), false);
});

test("Edamam 401 quota signal is classified without leaking provider detail", async () => {
  const event = await captureDiagnostic(Response.json({
    message: "Daily API quota limit reached for private account detail",
  }, { status: 401 }));

  assert.equal(event.providerErrorCategory, "rate_limit");
  assert.equal(JSON.stringify(event).includes("private account detail"), false);
});

test("Edamam wrong-API credential signal is classified as authentication", async () => {
  const event = await captureDiagnostic(Response.json({
    message: "Unauthorized app_id=test-app-key. This app_id is for another API.",
  }, { status: 401 }));

  assert.equal(event.providerErrorCategory, "authentication");
  assert.equal(JSON.stringify(event).includes("test-app-key"), false);
});

test("Edamam non-JSON 401 remains safely unknown", async () => {
  const event = await captureDiagnostic(new Response("private provider body", { status: 401 }));
  assert.equal(event.providerErrorCategory, "unknown");
  assert.equal(JSON.stringify(event).includes("private provider body"), false);
});

test("Edamam resolver-success measure categories are closed and normalized", () => {
  const cases = [
    ["piece", "piece"],
    ["pieces", "piece"],
    ["item", "item"],
    ["items", "item"],
    ["whole", "whole"],
    ["unit", "unit"],
    ["g", "metric"],
    ["gram", "metric"],
    ["grams", "metric"],
    ["kg", "metric"],
    ["kilogram", "metric"],
    ["kilograms", "metric"],
    ["ml", "metric"],
    ["milliliter", "metric"],
    ["milliliters", "metric"],
    ["millilitre", "metric"],
    ["millilitres", "metric"],
    ["l", "metric"],
    ["liter", "metric"],
    ["liters", "metric"],
    ["litre", "metric"],
    ["litres", "metric"],
    ["oz", "metric"],
    ["ounce", "metric"],
    ["ounces", "metric"],
    ["unexpected-safe-fixture", "other"],
  ] as const;

  for (const [label, expected] of cases) {
    assert.equal(edamamMeasureCategory(label), expected, label);
  }
});

async function captureResolver(
  candidate: { readonly foodName: string; readonly quantity: number; readonly unit: string },
  fetchFn: typeof fetch,
  timeoutMs?: number,
): Promise<{ readonly result: Awaited<ReturnType<EdamamResolver["resolve"]>>; readonly events: Record<string, unknown>[] }> {
  const original = console.info;
  const lines: string[] = [];
  console.info = (value?: unknown) => lines.push(String(value));
  try {
    const resolver = new EdamamResolver({
      appId: "test-app-id",
      appKey: "test-app-key",
      fetchFn,
      timeoutMs,
    });
    return {
      result: await resolver.resolve(candidate),
      events: lines.map((line) => JSON.parse(line) as Record<string, unknown>),
    };
  } finally {
    console.info = original;
  }
}

function successfulEdamamFetch(
  label: string,
  measureLabel: string,
  extras: Readonly<Record<string, string>> = {},
): typeof fetch {
  let calls = 0;
  return async () => {
    calls += 1;
    if (calls === 1) {
      return Response.json({
        parsed: [{
          food: { foodId: extras.foodId ?? "food-id", label },
          quantity: 2,
          measure: { uri: extras.measureUri ?? "measure:whole", label: measureLabel },
          ...extras,
        }],
      });
    }
    return Response.json({
      totalNutrients: {
        ENERC_KCAL: { quantity: 200, unit: "kcal" },
        PROCNT: { quantity: 8, unit: "g" },
      },
      ...extras,
    });
  };
}

function parserSuccessThen(
  secondRequest: (input: RequestInfo | URL, init?: RequestInit) => Promise<Response>,
): typeof fetch {
  let calls = 0;
  return async (input, init) => {
    calls += 1;
    if (calls === 1) {
      return Response.json({
        parsed: [{
          food: { foodId: "food-id", label: "Roti" },
          quantity: 2,
          measure: { uri: "measure:whole", label: "whole" },
        }],
      });
    }
    return secondRequest(input, init);
  };
}

test("successful Edamam resolution emits one bounded serving diagnostic without changing its item", async () => {
  const { result, events } = await captureResolver(
    { foodName: "roti", quantity: 2, unit: "piece" },
    successfulEdamamFetch("Roti", "whole", { measureUri: "measure-uri-secret-sentinel" }),
  );

  assert.deepEqual(result, {
    kind: "resolved",
    item: {
      displayName: "Roti",
      quantity: 2,
      servingUnit: "piece",
      nutritionSnapshot: {
        schemaVersion: 1,
        nutrients: { energy: 200, protein: 8 },
      },
    },
  });
  assert.deepEqual(events, [{
    component: "nutrition-meal-text-parse",
    stage: "resolver_resolved",
    provider: "edamam",
    measureCategory: "whole",
  }]);
});

test("successful resolver-success diagnostic never serializes provider or request sentinels", async () => {
  const sentinels = {
    foodId: "food-id-secret-sentinel",
    measureUri: "measure-uri-secret-sentinel",
    providerBody: "provider-body-secret-sentinel",
    jwt: "jwt-secret-sentinel",
    credential: "credential-secret-sentinel",
    nutrient: "nutrient-secret-sentinel",
  };
  const { events } = await captureResolver(
    { foodName: "food-name-secret-sentinel", quantity: 2, unit: "piece" },
    successfulEdamamFetch("food-name-secret-sentinel", "whole", sentinels),
  );

  assert.deepEqual(events, [{
    component: "nutrition-meal-text-parse",
    stage: "resolver_resolved",
    provider: "edamam",
    measureCategory: "whole",
  }]);
  const serialized = JSON.stringify(events);
  for (const sentinel of ["food-name-secret-sentinel", ...Object.values(sentinels)]) {
    assert.equal(serialized.includes(sentinel), false, sentinel);
  }
});

test("Edamam failures emit no resolver-success diagnostic", async () => {
  const cases: ReadonlyArray<{ readonly name: string; readonly fetchFn: typeof fetch }> = [
    { name: "no_match", fetchFn: async () => Response.json({ parsed: [] }) },
    {
      name: "name_mismatch",
      fetchFn: async () => Response.json({
        parsed: [{ food: { foodId: "food-id", label: "Apple Pie" }, quantity: 2, measure: { uri: "measure:whole", label: "whole" } }],
      }),
    },
    {
      name: "amount_mismatch",
      fetchFn: async () => Response.json({
        parsed: [{ food: { foodId: "food-id", label: "Roti" }, quantity: 1, measure: { uri: "measure:whole", label: "whole" } }],
      }),
    },
    {
      name: "unit_mismatch",
      fetchFn: async () => Response.json({
        parsed: [{ food: { foodId: "food-id", label: "Roti" }, quantity: 2, measure: { uri: "measure:cup", label: "cup" } }],
      }),
    },
    {
      name: "nutrients_missing",
      fetchFn: successfulEdamamFetch("Roti", "whole", { totalNutrients: "" }),
    },
    {
      name: "nutrients_transport",
      fetchFn: parserSuccessThen(async () => {
        throw new Error("transport");
      }),
    },
    {
      name: "nutrients_http",
      fetchFn: parserSuccessThen(async () =>
        new Response("provider-body-secret-sentinel", { status: 500 })
      ),
    },
    {
      name: "nutrients_malformed",
      fetchFn: parserSuccessThen(async () => new Response("{", { status: 200 })),
    },
  ];

  for (const c of cases) {
    const { events } = await captureResolver(
      { foodName: "roti", quantity: 2, unit: "piece" },
      c.fetchFn,
    );
    assert.equal(events.some((event) => event.stage === "resolver_resolved"), false, c.name);
  }
});

test("Edamam nutrients timeout emits no resolver-success diagnostic", async () => {
  const fetchFn = parserSuccessThen((_input, init) =>
    new Promise<Response>((_resolve, reject) => {
      const signal = init?.signal;
      if (signal?.aborted) {
        reject(new Error("aborted"));
        return;
      }
      signal?.addEventListener("abort", () => reject(new Error("aborted")), { once: true });
    })
  );

  const { result, events } = await captureResolver(
    { foodName: "roti", quantity: 2, unit: "piece" },
    fetchFn,
    5,
  );

  assert.deepEqual(result, { kind: "unavailable" });
  assert.equal(events.some((event) => event.stage === "resolver_resolved"), false);
  assert.equal(
    events.some((event) =>
      event.stage === "resolver_unavailable" &&
      event.provider === "edamam" &&
      event.reason === "transport_or_timeout"
    ),
    true,
  );
});
