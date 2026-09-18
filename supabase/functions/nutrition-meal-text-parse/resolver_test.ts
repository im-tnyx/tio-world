import test from "node:test";
import assert from "node:assert/strict";

import { resolveWithFallback } from "./resolver.ts";
import type {
  FoodNutritionResolver,
  MealCandidate,
  ResolverResult,
} from "./types.ts";

const candidate: MealCandidate = {
  foodName: "dal",
  quantity: 1,
  unit: "katori",
};

const primaryItem = {
  displayName: "Dal",
  quantity: 1,
  servingUnit: "katori",
  nutritionSnapshot: {
    schemaVersion: 1,
    nutrients: { energy: 120 },
  },
} as const;

const secondaryItem = {
  displayName: "Dal",
  quantity: 1,
  servingUnit: "katori",
  nutritionSnapshot: {
    schemaVersion: 1,
    nutrients: { protein: 8 },
  },
} as const;

function resolver(
  name: "fatsecret" | "edamam",
  result: ResolverResult,
  onCall?: () => void,
): FoodNutritionResolver {
  return {
    name,
    async resolve() {
      onCall?.();
      return result;
    },
  };
}

test("primary factual success does not call secondary", async () => {
  let secondaryCalls = 0;
  const result = await resolveWithFallback(
    candidate,
    resolver("fatsecret", { kind: "resolved", item: primaryItem }),
    resolver("edamam", { kind: "resolved", item: secondaryItem }, () => {
      secondaryCalls += 1;
    }),
  );

  assert.deepEqual(result, { kind: "resolved", item: primaryItem });
  assert.equal(secondaryCalls, 0);
});

test("FatSecret incomplete can fall back to Edamam success", async () => {
  const result = await resolveWithFallback(
    candidate,
    resolver("fatsecret", { kind: "incomplete" }),
    resolver("edamam", { kind: "resolved", item: secondaryItem }),
  );

  assert.deepEqual(result, { kind: "resolved", item: secondaryItem });
});

test("successful fallback item contains one provider nutrition only", async () => {
  const result = await resolveWithFallback(
    candidate,
    resolver("fatsecret", { kind: "incomplete" }),
    resolver("edamam", { kind: "resolved", item: secondaryItem }),
  );

  assert.equal(result.kind, "resolved");
  if (result.kind !== "resolved") return;
  assert.deepEqual(result.item.nutritionSnapshot.nutrients, { protein: 8 });
  assert.equal("energy" in result.item.nutritionSnapshot.nutrients, false);
});

test("both factual resolvers incomplete returns incomplete", async () => {
  assert.deepEqual(
    await resolveWithFallback(
      candidate,
      resolver("fatsecret", { kind: "incomplete" }),
      resolver("edamam", { kind: "incomplete" }),
    ),
    { kind: "incomplete" },
  );
});

test("both factual resolvers unavailable returns unavailable", async () => {
  assert.deepEqual(
    await resolveWithFallback(
      candidate,
      resolver("fatsecret", { kind: "unavailable" }),
      resolver("edamam", { kind: "unavailable" }),
    ),
    { kind: "unavailable" },
  );
});
