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


function multiItemInterpreter(names: readonly string[]): MealInterpreter {
  return {
    async interpret() {
      return {
        kind: "recognized",
        mealName: "Meal",
        items: names.map((foodName) => ({ foodName, quantity: 1, unit: "serving" })),
      };
    },
  };
}

function factualItemFor(displayName: string) {
  return {
    displayName,
    quantity: 1,
    servingUnit: "serving",
    nutritionSnapshot: {
      schemaVersion: 1,
      nutrients: { energy: 100 },
    },
  } as const;
}

function delay(ms: number): Promise<void> {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

test("multi-item resolution uses bounded concurrency and preserves item order", async () => {
  let active = 0;
  let maxActive = 0;
  const primary: FoodNutritionResolver = {
    name: "fatsecret",
    async resolve(candidate) {
      active += 1;
      maxActive = Math.max(maxActive, active);
      await delay(candidate.foodName === "first" ? 30 : 5);
      active -= 1;
      return { kind: "resolved", item: factualItemFor(candidate.foodName) };
    },
  };

  const handler = createMealTextHandler({
    authenticate: async () => true,
    interpreter: multiItemInterpreter(["first", "second", "third", "fourth"]),
    primaryResolver: primary,
    requestDeadlineMs: 1_000,
    itemConcurrency: 2,
  });

  const response = await handler(request({ schemaVersion: 1, mealText: "multi" }));
  const payload = await response.json() as { outcome: string; items?: { displayName: string }[] };
  assert.equal(payload.outcome, "success");
  assert.deepEqual(payload.items?.map((item) => item.displayName), [
    "first",
    "second",
    "third",
    "fourth",
  ]);
  assert.equal(maxActive, 2, "independent items should run concurrently but stay bounded");
});

test("overall deadline expiration maps to unavailable", async () => {
  const primary: FoodNutritionResolver = {
    name: "fatsecret",
    async resolve() {
      return await new Promise<ResolverResult>(() => {});
    },
  };

  const handler = createMealTextHandler({
    authenticate: async () => true,
    interpreter: multiItemInterpreter(["slow"]),
    primaryResolver: primary,
    requestDeadlineMs: 20,
    itemConcurrency: 2,
  });

  const response = await handler(request({ schemaVersion: 1, mealText: "slow" }));
  assert.deepEqual(await response.json(), {
    schemaVersion: 1,
    outcome: "unavailable",
  });
});

test("deadline never returns partial success after one item has resolved", async () => {
  const primary: FoodNutritionResolver = {
    name: "fatsecret",
    async resolve(candidate) {
      if (candidate.foodName === "fast") {
        return { kind: "resolved", item: factualItemFor("fast") };
      }
      return await new Promise<ResolverResult>(() => {});
    },
  };

  const handler = createMealTextHandler({
    authenticate: async () => true,
    interpreter: multiItemInterpreter(["fast", "slow"]),
    primaryResolver: primary,
    requestDeadlineMs: 20,
    itemConcurrency: 2,
  });

  const response = await handler(request({ schemaVersion: 1, mealText: "fast and slow" }));
  const payload = await response.json() as { outcome: string; items?: unknown };
  assert.equal(payload.outcome, "unavailable");
  assert.equal("items" in payload, false);
});

test("deadline abort reaches provider work and cannot mix fallback nutrients", async () => {
  let secondaryAborted = false;
  const primary: FoodNutritionResolver = {
    name: "fatsecret",
    async resolve() {
      return { kind: "incomplete" };
    },
  };
  const secondary: FoodNutritionResolver = {
    name: "edamam",
    async resolve(_candidate, signal) {
      return await new Promise<ResolverResult>((resolve) => {
        signal?.addEventListener("abort", () => {
          secondaryAborted = true;
          resolve({ kind: "unavailable" });
        }, { once: true });
      });
    },
  };

  const handler = createMealTextHandler({
    authenticate: async () => true,
    interpreter: multiItemInterpreter(["fallback"]),
    primaryResolver: primary,
    secondaryResolver: secondary,
    requestDeadlineMs: 20,
    itemConcurrency: 2,
  });

  const response = await handler(request({ schemaVersion: 1, mealText: "fallback" }));
  const payload = await response.json() as { outcome: string; items?: unknown };
  assert.equal(payload.outcome, "unavailable");
  assert.equal("items" in payload, false);
  assert.equal(secondaryAborted, true);
});
