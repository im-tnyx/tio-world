import test from "node:test";
import assert from "node:assert/strict";
import { readFileSync } from "node:fs";

import { createMealTextHandler } from "./handler.ts";
import type {
  FoodNutritionResolver,
  MealInterpreter,
  ResolverResult,
} from "./types.ts";

function resolver(
  name: "fatsecret" | "edamam",
  result: ResolverResult,
): FoodNutritionResolver {
  return {
    name,
    async resolve() {
      return result;
    },
  };
}

const recognized: MealInterpreter = {
  async interpret() {
    return {
      kind: "recognized",
      mealName: "Lunch",
      items: [{ foodName: "dal", quantity: 1, unit: "katori" }],
    };
  },
};

const factualItem = {
  displayName: "Dal",
  quantity: 1,
  servingUnit: "katori",
  nutritionSnapshot: {
    schemaVersion: 1,
    nutrients: { energy: 120, protein: 8 },
  },
} as const;

function request(body: unknown): Request {
  return new Request("https://example.invalid/functions/v1/nutrition-meal-text-parse", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(body),
  });
}

test("unauthenticated request is rejected with 401", async () => {
  const handler = createMealTextHandler({
    authenticate: async () => false,
    interpreter: recognized,
    primaryResolver: resolver("fatsecret", { kind: "resolved", item: factualItem }),
  });

  const response = await handler(request({ schemaVersion: 1, mealText: "dal" }));
  assert.equal(response.status, 401);
  assert.deepEqual(await response.json(), { error: "unauthorized" });
});

test("invalid JSON returns invalid_request", async () => {
  const handler = createMealTextHandler({
    authenticate: async () => true,
    interpreter: recognized,
    primaryResolver: resolver("fatsecret", { kind: "resolved", item: factualItem }),
  });

  const response = await handler(new Request("https://example.invalid", {
    method: "POST",
    body: "{bad-json",
  }));
  assert.equal(response.status, 400);
  assert.deepEqual(await response.json(), { error: "invalid_request" });
});

test("blank meal text returns invalid_request", async () => {
  const handler = createMealTextHandler({
    authenticate: async () => true,
    interpreter: recognized,
    primaryResolver: resolver("fatsecret", { kind: "resolved", item: factualItem }),
  });

  const response = await handler(request({ schemaVersion: 1, mealText: "   " }));
  assert.equal(response.status, 400);
  assert.deepEqual(await response.json(), { error: "invalid_request" });
});

test("wrong schema version returns invalid_request", async () => {
  const handler = createMealTextHandler({
    authenticate: async () => true,
    interpreter: recognized,
    primaryResolver: resolver("fatsecret", { kind: "resolved", item: factualItem }),
  });

  const response = await handler(request({ schemaVersion: 2, mealText: "dal" }));
  assert.equal(response.status, 400);
  assert.deepEqual(await response.json(), { error: "invalid_request" });
});

test("primary factual success returns provider-neutral Tio response", async () => {
  const handler = createMealTextHandler({
    authenticate: async () => true,
    interpreter: recognized,
    primaryResolver: resolver("fatsecret", { kind: "resolved", item: factualItem }),
  });

  const response = await handler(request({ schemaVersion: 1, mealText: "1 katori dal" }));
  assert.equal(response.status, 200);
  assert.deepEqual(await response.json(), {
    schemaVersion: 1,
    outcome: "success",
    mealName: "Lunch",
    items: [factualItem],
  });
});

test("Indian-style unresolved meal remains incomplete, never fabricated success", async () => {
  const handler = createMealTextHandler({
    authenticate: async () => true,
    interpreter: {
      async interpret() {
        return {
          kind: "recognized",
          items: [{ foodName: "dal bati", quantity: 1, unit: "plate" }],
        };
      },
    },
    primaryResolver: resolver("fatsecret", { kind: "incomplete" }),
    secondaryResolver: resolver("edamam", { kind: "incomplete" }),
  });

  const response = await handler(request({ schemaVersion: 1, mealText: "1 plate dal bati" }));
  assert.deepEqual(await response.json(), {
    schemaVersion: 1,
    outcome: "incomplete",
  });
});

test("both provider failures return unavailable", async () => {
  const handler = createMealTextHandler({
    authenticate: async () => true,
    interpreter: recognized,
    primaryResolver: resolver("fatsecret", { kind: "unavailable" }),
    secondaryResolver: resolver("edamam", { kind: "unavailable" }),
  });

  const response = await handler(request({ schemaVersion: 1, mealText: "1 katori dal" }));
  assert.deepEqual(await response.json(), {
    schemaVersion: 1,
    outcome: "unavailable",
  });
});

test("source contains no raw meal/provider logging", () => {
  const files = ["./handler.ts", "./gemini_client.ts", "./fatsecret_client.ts", "./edamam_client.ts"];
  for (const file of files) {
    const source = readFileSync(new URL(file, import.meta.url), "utf8");
    assert.equal(/console\.(log|info|debug|warn|error)\s*\(/.test(source), false, file);
  }
});
