import test from "node:test";
import assert from "node:assert/strict";

import { isSafeFoodIdentityMatch } from "./matching.ts";

import {
  FatSecretResolver,
  fatSecretRegionForCountry,
  resolveFatSecretServing,
  selectFatSecretMatch,
} from "./fatsecret_client.ts";
import {
  buildEdamamItem,
  EdamamResolver,
  measureIsCompatible,
} from "./edamam_client.ts";

test("FatSecret selects a deterministic valid match", () => {
  const result = selectFatSecretMatch("plain yogurt", [
    { food_id: "1", food_name: "Plain Yogurt", food_type: "Generic" },
    { food_id: "2", food_name: "Chocolate Cake", food_type: "Generic" },
  ]);

  assert.equal(result?.food_id, "1");
});

test("FatSecret ambiguous high-scoring match returns incomplete basis", () => {
  const result = selectFatSecretMatch("dal", [
    { food_id: "1", food_name: "Dal Curry" },
    { food_id: "2", food_name: "Dal Soup" },
  ]);

  assert.equal(result, null);
});

test("FatSecret missing serving returns incomplete basis", () => {
  assert.equal(
    resolveFatSecretServing(
      { foodName: "dahi", quantity: 150, unit: "g" },
      { food_name: "Plain Yogurt" },
    ),
    null,
  );
});

test("FatSecret scales factual nutrients for explicit metric quantity", () => {
  const result = resolveFatSecretServing(
    { foodName: "dahi", quantity: 200, unit: "g" },
    {
      food_name: "Plain Yogurt",
      servings: {
        serving: {
          metric_serving_amount: "100",
          metric_serving_unit: "g",
          calories: "60",
          protein: "4",
        },
      },
    },
  );

  assert.deepEqual(result, {
    displayName: "Plain Yogurt",
    quantity: 200,
    servingUnit: "g",
    nutritionSnapshot: {
      schemaVersion: 1,
      nutrients: { energy: 120, protein: 8 },
    },
  });
});

test("FatSecret transport/token failure is unavailable for US", async () => {
  const resolver = new FatSecretResolver({
    clientId: "test-id",
    clientSecret: "test-secret",
    fetchFn: async () => new Response("no", { status: 503 }),
  });

  assert.deepEqual(
    await resolver.resolve(
      { foodName: "dal", quantity: 1, unit: "katori" },
      undefined,
      { countryCode: "US" },
    ),
    { kind: "unavailable" },
  );
});

test("FatSecret country mapping allows only US under Basic entitlement", () => {
  assert.equal(fatSecretRegionForCountry("US"), "US");
  assert.equal(fatSecretRegionForCountry("IN"), null);
  assert.equal(fatSecretRegionForCountry("FR"), null);
  assert.equal(fatSecretRegionForCountry("ZZ"), null);
  assert.equal(fatSecretRegionForCountry("us"), null);
  assert.equal(fatSecretRegionForCountry("USA"), null);
  assert.equal(fatSecretRegionForCountry(undefined), null);
});

test("FatSecret missing country context is incomplete without provider calls", async () => {
  let calls = 0;
  const resolver = new FatSecretResolver({
    clientId: "test-id",
    clientSecret: "test-secret",
    fetchFn: async () => {
      calls += 1;
      return new Response("unexpected", { status: 500 });
    },
  });

  assert.deepEqual(
    await resolver.resolve({ foodName: "dal", quantity: 1, unit: "katori" }),
    { kind: "incomplete", reason: "region_unsupported" },
  );
  assert.equal(calls, 0);
});

test("FatSecret sends US as explicit region on search and detail", async () => {
  const requests: { url: string; body: string }[] = [];
  const resolver = new FatSecretResolver({
    clientId: "test-id",
    clientSecret: "test-secret",
    fetchFn: async (input, init) => {
      const url = String(input);
      const body = init?.body instanceof URLSearchParams ? init.body.toString() : "";
      requests.push({ url, body });

      if (url.includes("oauth.fatsecret.com")) {
        return Response.json({ access_token: "token", expires_in: 3600 });
      }
      if (url.includes("server.api")) {
        return Response.json({
          foods: {
            food: [{ food_id: "food-1", food_name: "Dal", food_type: "Generic" }],
          },
        });
      }
      return Response.json({
        food: {
          food_name: "Dal",
          servings: {
            serving: {
              number_of_units: "1",
              measurement_description: "katori",
              calories: "120",
            },
          },
        },
      });
    },
  });

  const result = await resolver.resolve(
    { foodName: "dal", quantity: 1, unit: "katori" },
    undefined,
    { countryCode: "US" },
  );

  assert.equal(result.kind, "resolved");
  assert.match(requests[1].body, /(?:^|&)region=US(?:&|$)/);
  assert.match(requests[2].url, /[?&]region=US(?:&|$)/);
});

test("FatSecret non-US countries fail closed before provider calls", async () => {
  for (const countryCode of ["IN", "FR", "ZZ"]) {
    let calls = 0;
    const resolver = new FatSecretResolver({
      clientId: "test-id",
      clientSecret: "test-secret",
      fetchFn: async () => {
        calls += 1;
        return new Response("unexpected", { status: 500 });
      },
    });

    assert.deepEqual(
      await resolver.resolve(
        { foodName: "dal", quantity: 1, unit: "katori" },
        undefined,
        { countryCode },
      ),
      { kind: "incomplete", reason: "region_unsupported" },
    );
    assert.equal(calls, 0, `${countryCode} must not call FatSecret under Basic entitlement`);
  }
});

test("Edamam compatible item measure is accepted", () => {
  assert.equal(measureIsCompatible("piece", "whole"), true);
  assert.equal(measureIsCompatible("g", "cup"), false);
});

test("Edamam normalizes factual nutrients only", () => {
  const result = buildEdamamItem(
    { foodName: "dahi", quantity: 150, unit: "g" },
    "Plain Yogurt",
    {
      ENERC_KCAL: { quantity: 90, unit: "kcal" },
      PROCNT: { quantity: 6, unit: "g" },
    },
  );

  assert.deepEqual(result, {
    displayName: "Plain Yogurt",
    quantity: 150,
    servingUnit: "g",
    nutritionSnapshot: {
      schemaVersion: 1,
      nutrients: { energy: 90, protein: 6 },
    },
  });
});

test("Edamam malformed parser response returns incomplete", async () => {
  const resolver = new EdamamResolver({
    appId: "test-id",
    appKey: "test-key",
    fetchFn: async () =>
      new Response(JSON.stringify({ parsed: [] }), {
        status: 200,
        headers: { "Content-Type": "application/json" },
      }),
  });

  assert.deepEqual(
    await resolver.resolve({ foodName: "dal", quantity: 1, unit: "katori" }),
    { kind: "incomplete", reason: "no_match" },
  );
});

test("Edamam network failure returns unavailable", async () => {
  const resolver = new EdamamResolver({
    appId: "test-id",
    appKey: "test-key",
    fetchFn: async () => {
      throw new Error("network down");
    },
  });

  assert.deepEqual(
    await resolver.resolve({ foodName: "dal", quantity: 1, unit: "katori" }),
    { kind: "unavailable" },
  );
});

test("Edamam successful factual resolver returns normalized item", async () => {
  let calls = 0;
  const resolver = new EdamamResolver({
    appId: "test-id",
    appKey: "test-key",
    fetchFn: async () => {
      calls += 1;
      if (calls === 1) {
        return new Response(JSON.stringify({
          parsed: [{
            food: { foodId: "food-1", label: "Plain Yogurt" },
            quantity: 150,
            measure: { uri: "measure:g", label: "g" },
          }],
        }), {
          status: 200,
          headers: { "Content-Type": "application/json" },
        });
      }
      return new Response(JSON.stringify({
        totalNutrients: {
          ENERC_KCAL: { quantity: 90, unit: "kcal" },
          PROCNT: { quantity: 6, unit: "g" },
        },
      }), {
        status: 200,
        headers: { "Content-Type": "application/json" },
      });
    },
  });

  const result = await resolver.resolve({
    foodName: "plain yogurt",
    quantity: 150,
    unit: "g",
  });

  assert.equal(result.kind, "resolved");
  if (result.kind !== "resolved") return;
  assert.deepEqual(result.item.nutritionSnapshot.nutrients, {
    energy: 90,
    protein: 6,
  });
});


test("factual identity accepts exact and safe reordered token matches", () => {
  assert.equal(isSafeFoodIdentityMatch("plain yogurt", "plain yogurt"), true);
  assert.equal(isSafeFoodIdentityMatch("plain yogurt", "yogurt plain"), true);
  assert.equal(isSafeFoodIdentityMatch("tomato", "tomatoes"), true);
});

test("factual identity rejects extra semantic and composite-food tokens", () => {
  assert.equal(isSafeFoodIdentityMatch("milk", "milk chocolate"), false);
  assert.equal(isSafeFoodIdentityMatch("rice", "rice pudding"), false);
  assert.equal(isSafeFoodIdentityMatch("rice", "rice cracker"), false);
  assert.equal(isSafeFoodIdentityMatch("yogurt", "yogurt dressing"), false);
});

test("FatSecret rejects ambiguous duplicate safe identities", () => {
  const result = selectFatSecretMatch("dal", [
    { food_id: "1", food_name: "Dal", food_type: "Generic" },
    { food_id: "2", food_name: "Dal", food_type: "Generic" },
  ]);

  assert.equal(result, null);
});

test("FatSecret resolver rejects materially expanded food identity", async () => {
  let calls = 0;
  const resolver = new FatSecretResolver({
    clientId: "test-id",
    clientSecret: "test-secret",
    fetchFn: async () => {
      calls += 1;
      if (calls === 1) {
        return new Response(JSON.stringify({
          access_token: "token",
          expires_in: 3600,
        }), { status: 200, headers: { "Content-Type": "application/json" } });
      }
      return new Response(JSON.stringify({
        foods: {
          food: [{ food_id: "food-1", food_name: "Milk Chocolate", food_type: "Generic" }],
        },
      }), { status: 200, headers: { "Content-Type": "application/json" } });
    },
  });

  assert.deepEqual(
    await resolver.resolve(
      { foodName: "milk", quantity: 100, unit: "g" },
      undefined,
      { countryCode: "US" },
    ),
    // A food came back and was rejected on identity: the same condition Edamam
    // reports as `name_mismatch`, not a search that found nothing.
    { kind: "incomplete", reason: "name_mismatch" },
  );
  assert.equal(calls, 2, "unsafe search result must not fetch provider detail");
});

test("Edamam rejects materially expanded food identity before nutrients call", async () => {
  let calls = 0;
  const resolver = new EdamamResolver({
    appId: "test-id",
    appKey: "test-key",
    fetchFn: async () => {
      calls += 1;
      return new Response(JSON.stringify({
        parsed: [{
          food: { foodId: "food-1", label: "Rice Pudding" },
          quantity: 1,
          measure: { uri: "measure:serving", label: "serving" },
        }],
      }), { status: 200, headers: { "Content-Type": "application/json" } });
    },
  });

  assert.deepEqual(
    await resolver.resolve({ foodName: "rice", quantity: 1, unit: "serving" }),
    { kind: "incomplete", reason: "name_mismatch" },
  );
  assert.equal(calls, 1, "unsafe identity must not request nutrient detail");
});

test("Edamam accepts safe reordered food identity", async () => {
  let calls = 0;
  const resolver = new EdamamResolver({
    appId: "test-id",
    appKey: "test-key",
    fetchFn: async () => {
      calls += 1;
      if (calls === 1) {
        return new Response(JSON.stringify({
          parsed: [{
            food: { foodId: "food-1", label: "Yogurt Plain" },
            quantity: 150,
            measure: { uri: "measure:g", label: "g" },
          }],
        }), { status: 200, headers: { "Content-Type": "application/json" } });
      }
      return new Response(JSON.stringify({
        totalNutrients: {
          ENERC_KCAL: { quantity: 90, unit: "kcal" },
        },
      }), { status: 200, headers: { "Content-Type": "application/json" } });
    },
  });

  const result = await resolver.resolve({
    foodName: "plain yogurt",
    quantity: 150,
    unit: "g",
  });
  assert.equal(result.kind, "resolved");
  assert.equal(calls, 2);
});

test("FatSecret accepts safe reordered food identity", () => {
  const result = selectFatSecretMatch("plain yogurt", [
    { food_id: "1", food_name: "Yogurt Plain", food_type: "Generic" },
  ]);

  assert.equal(result?.food_id, "1");
});
