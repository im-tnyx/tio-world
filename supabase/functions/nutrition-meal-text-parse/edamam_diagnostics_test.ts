import test from "node:test";
import assert from "node:assert/strict";

import { EdamamResolver } from "./edamam_client.ts";

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
