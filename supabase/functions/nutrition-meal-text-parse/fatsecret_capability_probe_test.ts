import test from "node:test";
import assert from "node:assert/strict";

import { probeFatSecretIndiaCapability } from "./fatsecret_capability_probe.ts";

function json(value: unknown, status = 200): Response {
  return Response.json(value, { status });
}

test("probe validates token, default search, and default detail without changing production routing", async () => {
  const requests: Array<{ url: string; init?: RequestInit }> = [];
  const responses = [
    json({ access_token: "synthetic-token", expires_in: 3600 }),
    json({ foods: { food: [{ food_id: "123", food_name: "Plain Yogurt" }] } }),
    json({ food: { food_id: "123", food_name: "Plain Yogurt" } }),
  ];
  const result = await probeFatSecretIndiaCapability({
    clientId: "test-client",
    clientSecret: "test-secret",
    fetchFn: async (input, init) => {
      requests.push({ url: String(input), init });
      return responses.shift()!;
    },
  });

  assert.deepEqual(result.map(({ stage, category }) => ({ stage, category })), [
    { stage: "token", category: "ok" },
    { stage: "search_default", category: "ok" },
    { stage: "detail_default", category: "ok" },
  ]);
  assert.doesNotMatch(String(requests[1].init?.body), /region=/);
  assert.doesNotMatch(requests[2].url, /region=/);
});

test("probe reports bounded auth failure and never returns provider body", async () => {
  const result = await probeFatSecretIndiaCapability({
    clientId: "test-client",
    clientSecret: "test-secret",
    fetchFn: async () => new Response("private provider body", { status: 401 }),
  });
  assert.deepEqual(result, [{ stage: "token", category: "authentication", httpStatus: 401 }]);
  assert.equal(JSON.stringify(result).includes("private provider body"), false);
});

test("probe stops safely when default search is forbidden", async () => {
  let call = 0;
  const result = await probeFatSecretIndiaCapability({
    clientId: "test-client",
    clientSecret: "test-secret",
    fetchFn: async () => {
      call += 1;
      return call === 1
        ? json({ access_token: "synthetic-token" })
        : new Response("entitlement detail", { status: 403 });
    },
  });
  assert.deepEqual(result.map(({ stage, category }) => ({ stage, category })), [
    { stage: "token", category: "ok" },
    { stage: "search_default", category: "authorization_or_entitlement" },
  ]);
  assert.equal(JSON.stringify(result).includes("entitlement detail"), false);
});
