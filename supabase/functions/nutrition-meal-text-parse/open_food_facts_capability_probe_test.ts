import test from "node:test";
import assert from "node:assert/strict";
import { probeOpenFoodFacts } from "./open_food_facts_capability_probe.ts";

test("maps one complete factual product", async () => {
  const result = await probeOpenFoodFacts("plain yogurt", async () => Response.json({
    products: [{ product_name: "Plain Yogurt", nutriments: {
      "energy-kcal_100g": 61, proteins_100g: 3.5, carbohydrates_100g: 4.7, fat_100g: 3.3,
    } }],
  }));
  assert.equal(result.category, "resolved");
  assert.deepEqual(result.per100g, { energyKcal: 61, proteinG: 3.5, carbsG: 4.7, fatG: 3.3 });
});

test("does not fabricate a missing nutrient", async () => {
  const result = await probeOpenFoodFacts("dal", async () => Response.json({
    products: [{ product_name: "Dal", nutriments: { "energy-kcal_100g": 100, proteins_100g: 5 } }],
  }));
  assert.deepEqual(result, { query: "dal", category: "incomplete" });
});

test("malformed provider response is unavailable", async () => {
  const result = await probeOpenFoodFacts("roti", async () => new Response("not-json"));
  assert.deepEqual(result, { query: "roti", category: "unavailable" });
});
