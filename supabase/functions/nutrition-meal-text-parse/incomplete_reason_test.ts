import test from "node:test";
import assert from "node:assert/strict";

import { EdamamResolver } from "./edamam_client.ts";
import { FatSecretResolver, resolveFatSecretServing } from "./fatsecret_client.ts";
import { createMealTextHandler } from "./handler.ts";
import {
  BARE_COUNT_UNIT,
  MAX_BARE_COUNT,
  MEAL_INTERPRETER_INSTRUCTIONS,
  parseInterpretationJson,
} from "./interpretation_schema.ts";
import { resolveWithFallback } from "./resolver.ts";
import type {
  FoodNutritionResolver,
  MealCandidate,
  MealInterpreter,
  ResolverResult,
} from "./types.ts";

// ---------------------------------------------------------------- interpreter

function interpret(items: readonly unknown[]) {
  return parseInterpretationJson(JSON.stringify({ items }));
}

function itemsOf(result: ReturnType<typeof parseInterpretationJson>) {
  assert.equal(result.kind, "recognized");
  return result.kind === "recognized" ? result.items : [];
}

test("a stated count without a unit becomes pieces", () => {
  const [banana] = itemsOf(
    interpret([{ foodName: "banana", quantity: 2, unit: null }]),
  );
  assert.deepEqual(banana, {
    foodName: "banana",
    quantity: 2,
    unit: BARE_COUNT_UNIT,
  });
  assert.equal(BARE_COUNT_UNIT, "piece");
});

test("a bare count is completed at the limit and not above it", () => {
  const [atLimit, above] = itemsOf(interpret([
    { foodName: "roti", quantity: MAX_BARE_COUNT, unit: null },
    { foodName: "chicken", quantity: MAX_BARE_COUNT + 1, unit: null },
  ]));
  assert.equal(atLimit.unit, "piece");
  // More likely a weight than a count, so it stays partial and is later asked
  // for an amount rather than resolving hundreds of pieces.
  assert.deepEqual(above, {
    foodName: "chicken",
    quantity: MAX_BARE_COUNT + 1,
    unit: null,
  });
});

test("only a bare count is completed", () => {
  const items = itemsOf(interpret([
    { foodName: "milk", quantity: 200, unit: "ml" },
    { foodName: "dal", quantity: null, unit: "g" },
    { foodName: "chai", quantity: null, unit: null },
  ]));
  assert.deepEqual(items, [
    { foodName: "milk", quantity: 200, unit: "ml" },
    { foodName: "dal", quantity: null, unit: "g" },
    { foodName: "chai", quantity: null, unit: null },
  ]);
});

test("a quantity that is not a positive finite number is never made a count", () => {
  // Zero, negative and non-finite amounts are rejected outright (the whole
  // interpretation is `unavailable`); none of them reaches a resolver as pieces.
  for (const quantity of ["0", "-2", "1e999", "-1e999"]) {
    assert.deepEqual(
      parseInterpretationJson(
        `{"items":[{"foodName":"banana","quantity":${quantity},"unit":null}]}`,
      ),
      { kind: "unavailable" },
      quantity,
    );
  }
});

test("a unit that was stated is never replaced by the bare-count unit", () => {
  const items = itemsOf(interpret([
    { foodName: "milk", quantity: 2, unit: "glass" },
    { foodName: "rice", quantity: 3, unit: "g" },
  ]));
  assert.deepEqual(items.map((item) => item.unit), ["glass", "g"]);
});

test("the interpreter is told the same rule the normalizer applies", () => {
  assert.ok(
    MEAL_INTERPRETER_INSTRUCTIONS.some((line) =>
      line.includes("without a unit") && line.includes(`"${BARE_COUNT_UNIT}"`)
    ),
  );
});

// ------------------------------------------------------------ resolver merge

function fixed(
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

const candidate: MealCandidate = { foodName: "dal", quantity: 1, unit: "g" };

test("the second resolver's reason explains an incomplete item", async () => {
  assert.deepEqual(
    await resolveWithFallback(
      candidate,
      fixed("fatsecret", { kind: "incomplete", reason: "region_unsupported" }),
      fixed("edamam", { kind: "incomplete", reason: "name_mismatch" }),
    ),
    { kind: "incomplete", reason: "name_mismatch" },
  );
});

test("the first reason is kept when the second could not answer", async () => {
  assert.deepEqual(
    await resolveWithFallback(
      candidate,
      fixed("fatsecret", { kind: "incomplete", reason: "no_match" }),
      fixed("edamam", { kind: "unavailable" }),
    ),
    { kind: "incomplete", reason: "no_match" },
  );
});

test("an incomplete item without a reason stays without one", async () => {
  assert.deepEqual(
    await resolveWithFallback(
      candidate,
      fixed("fatsecret", { kind: "incomplete" }),
      fixed("edamam", { kind: "incomplete" }),
    ),
    { kind: "incomplete" },
  );
});

// ----------------------------------------------------------- Edamam reasons

function edamamReturning(
  parsed: unknown,
  nutrients: unknown = { totalNutrients: {} },
): { resolver: EdamamResolver; calls: () => number } {
  let calls = 0;
  const resolver = new EdamamResolver({
    appId: "test-id",
    appKey: "test-key",
    fetchFn: async (input) => {
      calls += 1;
      const url = String(input instanceof Request ? input.url : input);
      const body = url.includes("/nutrients") ? nutrients : parsed;
      return new Response(JSON.stringify(body), {
        status: 200,
        headers: { "Content-Type": "application/json" },
      });
    },
  });
  return { resolver, calls: () => calls };
}

const banana = { foodId: "food-1", label: "Banana" };
const whole = { uri: "measure:whole", label: "Whole" };

test("Edamam reports each reason it stops an item for", async () => {
  const cases: ReadonlyArray<{
    readonly name: string;
    readonly candidate: MealCandidate;
    readonly parsed: unknown;
    readonly nutrients?: unknown;
    readonly reason: string;
  }> = [
    {
      name: "no amount",
      candidate: { foodName: "banana", quantity: null, unit: null },
      parsed: {},
      reason: "missing_amount",
    },
    {
      name: "nothing parsed",
      candidate: { foodName: "banana", quantity: 2, unit: "piece" },
      parsed: { parsed: [] },
      reason: "no_match",
    },
    {
      name: "a parsed entry with no food identity",
      candidate: { foodName: "banana", quantity: 2, unit: "piece" },
      parsed: {
        parsed: [{ food: { label: "Banana" }, quantity: 2, measure: whole }],
      },
      reason: "no_match",
    },
    {
      name: "a different food",
      candidate: { foodName: "banana", quantity: 2, unit: "piece" },
      parsed: {
        parsed: [{ food: { foodId: "f", label: "Apple Pie" }, quantity: 2, measure: whole }],
      },
      reason: "name_mismatch",
    },
    {
      // A food was found; it is the amount that did not come back.
      name: "a food with no parsed amount",
      candidate: { foodName: "banana", quantity: 2, unit: "piece" },
      parsed: { parsed: [{ food: banana, measure: whole }] },
      reason: "amount_mismatch",
    },
    {
      // A food was found; it is the unit that did not come back.
      name: "a food with no measure",
      candidate: { foodName: "banana", quantity: 2, unit: "piece" },
      parsed: { parsed: [{ food: banana, quantity: 2 }] },
      reason: "unit_mismatch",
    },
    {
      name: "a different amount",
      candidate: { foodName: "banana", quantity: 2, unit: "piece" },
      parsed: { parsed: [{ food: banana, quantity: 1, measure: whole }] },
      reason: "amount_mismatch",
    },
    {
      name: "a measure that is not the unit",
      candidate: { foodName: "banana", quantity: 2, unit: "piece" },
      parsed: {
        parsed: [{
          food: banana,
          quantity: 2,
          measure: { uri: "measure:cup", label: "Cup" },
        }],
      },
      reason: "unit_mismatch",
    },
    {
      name: "no nutrients back",
      candidate: { foodName: "banana", quantity: 2, unit: "piece" },
      parsed: { parsed: [{ food: banana, quantity: 2, measure: whole }] },
      nutrients: {},
      reason: "nutrients_missing",
    },
  ];

  for (const c of cases) {
    const { resolver } = edamamReturning(c.parsed, c.nutrients);
    assert.deepEqual(
      await resolver.resolve(c.candidate),
      { kind: "incomplete", reason: c.reason },
      c.name,
    );
  }
});

// --------------------------------------------------------- FatSecret reasons

function fatSecretReturning(
  search: unknown,
  detail: unknown = {},
): FatSecretResolver {
  const respond = (body: unknown) =>
    new Response(JSON.stringify(body), {
      status: 200,
      headers: { "Content-Type": "application/json" },
    });
  return new FatSecretResolver({
    clientId: "test-id",
    clientSecret: "test-secret",
    fetchFn: async (input) => {
      const url = String(input instanceof Request ? input.url : input);
      if (url.includes("oauth")) return respond({ access_token: "t", expires_in: 3600 });
      return respond(url.includes("/food/v5") ? detail : search);
    },
  });
}

const milkHit = {
  foods: { food: [{ food_id: "1", food_name: "Milk", food_type: "Generic" }] },
};
const grams = { metric_serving_amount: "100", metric_serving_unit: "g" };
const inUs = { countryCode: "US" };

test("FatSecret reports each reason it stops an item for", async () => {
  const cases: ReadonlyArray<{
    readonly name: string;
    readonly candidate: MealCandidate;
    readonly context?: { readonly countryCode: string };
    readonly search: unknown;
    readonly detail?: unknown;
    readonly reason: string;
  }> = [
    {
      name: "no amount",
      candidate: { foodName: "milk", quantity: null, unit: null },
      context: inUs,
      search: milkHit,
      reason: "missing_amount",
    },
    {
      name: "a country without a region",
      candidate: { foodName: "milk", quantity: 100, unit: "g" },
      context: { countryCode: "IN" },
      search: milkHit,
      reason: "region_unsupported",
    },
    {
      name: "a search that found nothing",
      candidate: { foodName: "milk", quantity: 100, unit: "g" },
      context: inUs,
      search: { foods: { total_results: "0" } },
      reason: "no_match",
    },
    {
      // Foods came back and none is a safe identity match.
      name: "only a different food",
      candidate: { foodName: "milk", quantity: 100, unit: "g" },
      context: inUs,
      search: {
        foods: { food: [{ food_id: "1", food_name: "Milk Chocolate", food_type: "Generic" }] },
      },
      reason: "name_mismatch",
    },
    {
      name: "no serving in the requested unit",
      candidate: { foodName: "milk", quantity: 2, unit: "katori" },
      context: inUs,
      search: milkHit,
      detail: { food: { servings: { serving: [{ ...grams, calories: "60" }] } } },
      reason: "unit_mismatch",
    },
    {
      // The serving fits; it is the nutrients that are missing.
      name: "a serving with no nutrient values",
      candidate: { foodName: "milk", quantity: 100, unit: "g" },
      context: inUs,
      search: milkHit,
      detail: { food: { servings: { serving: [grams] } } },
      reason: "nutrients_missing",
    },
  ];

  for (const c of cases) {
    assert.deepEqual(
      await fatSecretReturning(c.search, c.detail).resolve(c.candidate, undefined, c.context),
      { kind: "incomplete", reason: c.reason },
      c.name,
    );
  }
});

test("the FatSecret serving helper still returns null for an unusable serving", () => {
  const candidate: MealCandidate = { foodName: "milk", quantity: 100, unit: "g" };
  assert.equal(
    resolveFatSecretServing(candidate, { servings: { serving: [grams] } }),
    null,
  );
  assert.equal(
    resolveFatSecretServing(candidate, { servings: { serving: [{ ...grams, calories: "60" }] } })
      ?.nutritionSnapshot.nutrients.energy,
    60,
  );
});

test("Edamam makes no request for an item without an amount", async () => {
  const { resolver, calls } = edamamReturning({});
  await resolver.resolve({ foodName: "banana", quantity: null, unit: null });
  assert.equal(calls(), 0);
});

test("a counted item with no unit now reaches Edamam as pieces", async () => {
  // Interpreter output for "2 banana" → normalizer → resolver.
  const [item] = itemsOf(
    interpret([{ foodName: "banana", quantity: 2, unit: null }]),
  );
  const { resolver } = edamamReturning(
    { parsed: [{ food: banana, quantity: 2, measure: whole }] },
    {
      totalNutrients: {
        ENERC_KCAL: { quantity: 210, unit: "kcal" },
        PROCNT: { quantity: 2.6, unit: "g" },
      },
    },
  );
  const result = await resolver.resolve(item);
  assert.equal(result.kind, "resolved");
});

// ------------------------------------------------------- handler diagnostics

type Event = Record<string, unknown>;

async function capture<T>(
  run: () => Promise<T>,
): Promise<{ readonly value: T; readonly events: Event[] }> {
  const original = console.info;
  const events: Event[] = [];
  console.info = (value?: unknown) => {
    events.push(JSON.parse(String(value)) as Event);
  };
  try {
    return { value: await run(), events };
  } finally {
    console.info = original;
  }
}

function incompleteEvents(events: readonly Event[]): Event[] {
  return events.filter((event) => event.stage === "meal_incomplete");
}

function post(mealText: string): Request {
  return new Request("https://example.invalid/functions/v1/nutrition-meal-text-parse", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ schemaVersion: 1, mealText }),
  });
}

function interpreterOf(items: readonly MealCandidate[]): MealInterpreter {
  return {
    async interpret() {
      return { kind: "recognized", items };
    },
  };
}

const twoItems: readonly MealCandidate[] = [
  { foodName: "dal", quantity: 1, unit: "katori" },
  { foodName: "roti", quantity: 2, unit: "piece" },
];

const signedIn = (countryCode: string | null) => async () => ({
  kind: "authenticated" as const,
  countryCode,
});

test("an incomplete meal writes one event with the reason and nothing else", async () => {
  const mealText = "1 katori dal secret-marker";
  const handler = createMealTextHandler({
    authenticate: signedIn("IN"),
    interpreter: interpreterOf(twoItems),
    primaryResolver: fixed("fatsecret", { kind: "incomplete", reason: "region_unsupported" }),
    secondaryResolver: fixed("edamam", { kind: "incomplete", reason: "unit_mismatch" }),
  });

  const { value: response, events } = await capture(() => handler(post(mealText)));

  assert.deepEqual(await response.json(), { schemaVersion: 1, outcome: "incomplete" });
  // Two incomplete items, still exactly one event for the meal.
  assert.deepEqual(incompleteEvents(events), [
    {
      component: "nutrition-meal-text-parse",
      stage: "meal_incomplete",
      reason: "unit_mismatch",
    },
  ]);
  assert.equal(JSON.stringify(events).includes("secret-marker"), false);
  assert.equal(/dal|roti|katori/i.test(JSON.stringify(events)), false);
});

test("an incomplete item that gave no reason is reported as unknown", async () => {
  const handler = createMealTextHandler({
    authenticate: signedIn("IN"),
    interpreter: interpreterOf(twoItems),
    primaryResolver: fixed("fatsecret", { kind: "incomplete" }),
    secondaryResolver: fixed("edamam", { kind: "incomplete" }),
  });

  const { events } = await capture(() => handler(post("1 katori dal")));
  assert.deepEqual(incompleteEvents(events).map((event) => event.reason), ["unknown"]);
});

test("an account without a country is reported before any provider is called", async () => {
  let providerCalls = 0;
  const counting: FoodNutritionResolver = {
    name: "edamam",
    async resolve() {
      providerCalls += 1;
      return { kind: "incomplete" };
    },
  };
  const handler = createMealTextHandler({
    authenticate: signedIn(null),
    interpreter: {
      async interpret() {
        providerCalls += 1;
        return { kind: "unrecognized" };
      },
    },
    primaryResolver: counting,
    secondaryResolver: counting,
  });

  const { value: response, events } = await capture(() => handler(post("2 banana")));

  assert.deepEqual(await response.json(), { schemaVersion: 1, outcome: "incomplete" });
  assert.deepEqual(incompleteEvents(events).map((event) => event.reason), ["country_missing"]);
  assert.equal(providerCalls, 0);
});

test("a recognized meal with no items is reported as no_items", async () => {
  const handler = createMealTextHandler({
    authenticate: signedIn("IN"),
    interpreter: interpreterOf([]),
    primaryResolver: fixed("fatsecret", { kind: "unavailable" }),
    secondaryResolver: fixed("edamam", { kind: "unavailable" }),
  });

  const { events } = await capture(() => handler(post("nothing")));
  assert.deepEqual(incompleteEvents(events).map((event) => event.reason), ["no_items"]);
});

test("a resolved meal writes no incomplete event", async () => {
  const resolved: ResolverResult = {
    kind: "resolved",
    item: {
      displayName: "Roti",
      quantity: 2,
      servingUnit: "piece",
      nutritionSnapshot: { schemaVersion: 1, nutrients: { energy: 200 } },
    },
  };
  const handler = createMealTextHandler({
    authenticate: signedIn("IN"),
    interpreter: interpreterOf([{ foodName: "roti", quantity: 2, unit: "piece" }]),
    primaryResolver: fixed("fatsecret", resolved),
    secondaryResolver: fixed("edamam", resolved),
  });

  const { value: response, events } = await capture(() => handler(post("2 roti")));

  assert.equal((await response.json()).outcome, "success");
  assert.deepEqual(incompleteEvents(events), []);
});

const resolvedRoti: ResolverResult = {
  kind: "resolved",
  item: {
    displayName: "Roti",
    quantity: 2,
    servingUnit: "piece",
    nutritionSnapshot: { schemaVersion: 1, nutrients: { energy: 200 } },
  },
};

// Answers by food name, so one meal can mix outcomes.
function byFood(
  name: "fatsecret" | "edamam",
  results: Readonly<Record<string, ResolverResult>>,
): FoodNutritionResolver {
  return {
    name,
    async resolve(candidate) {
      return results[candidate.foodName] ?? { kind: "unavailable" };
    },
  };
}

test("one incomplete item among resolved ones still writes exactly one event", async () => {
  const results = {
    roti: resolvedRoti,
    dal: { kind: "incomplete", reason: "name_mismatch" } as ResolverResult,
    kheer: { kind: "incomplete", reason: "unit_mismatch" } as ResolverResult,
  };
  const handler = createMealTextHandler({
    authenticate: signedIn("IN"),
    interpreter: interpreterOf([
      { foodName: "roti", quantity: 2, unit: "piece" },
      { foodName: "dal", quantity: 1, unit: "katori" },
      { foodName: "kheer", quantity: 1, unit: "bowl" },
    ]),
    primaryResolver: byFood("fatsecret", results),
    secondaryResolver: byFood("edamam", results),
  });

  const { value: response, events } = await capture(() => handler(post("roti dal kheer")));

  assert.deepEqual(await response.json(), { schemaVersion: 1, outcome: "incomplete" });
  // The first item that stopped the meal, in the order the user gave them.
  assert.deepEqual(incompleteEvents(events), [
    {
      component: "nutrition-meal-text-parse",
      stage: "meal_incomplete",
      reason: "name_mismatch",
    },
  ]);
});

test("an incomplete item next to an unavailable one is still incomplete, once", async () => {
  const results = {
    dal: { kind: "incomplete", reason: "no_match" } as ResolverResult,
    roti: { kind: "unavailable" } as ResolverResult,
  };
  const handler = createMealTextHandler({
    authenticate: signedIn("IN"),
    interpreter: interpreterOf([
      { foodName: "roti", quantity: 2, unit: "piece" },
      { foodName: "dal", quantity: 1, unit: "katori" },
    ]),
    primaryResolver: byFood("fatsecret", results),
    secondaryResolver: byFood("edamam", results),
  });

  const { value: response, events } = await capture(() => handler(post("roti dal")));

  assert.equal((await response.json()).outcome, "incomplete");
  assert.deepEqual(incompleteEvents(events).map((event) => event.reason), ["no_match"]);
});

test("unrecognized and unavailable outcomes are unchanged and write no incomplete event", async () => {
  const cases: ReadonlyArray<{
    readonly name: string;
    readonly interpreter: MealInterpreter;
    readonly resolver: FoodNutritionResolver;
    readonly outcome: string;
  }> = [
    {
      name: "unrecognized text",
      interpreter: { async interpret() { return { kind: "unrecognized" }; } },
      resolver: fixed("edamam", { kind: "incomplete", reason: "no_match" }),
      outcome: "unrecognized",
    },
    {
      name: "interpreter unavailable",
      interpreter: { async interpret() { return { kind: "unavailable" }; } },
      resolver: fixed("edamam", { kind: "incomplete", reason: "no_match" }),
      outcome: "unavailable",
    },
    {
      name: "every resolver unavailable",
      interpreter: interpreterOf([{ foodName: "roti", quantity: 2, unit: "piece" }]),
      resolver: fixed("edamam", { kind: "unavailable" }),
      outcome: "unavailable",
    },
  ];

  for (const c of cases) {
    const handler = createMealTextHandler({
      authenticate: signedIn("IN"),
      interpreter: c.interpreter,
      primaryResolver: c.resolver,
      secondaryResolver: c.resolver,
    });
    const { value: response, events } = await capture(() => handler(post("2 roti")));
    assert.equal((await response.json()).outcome, c.outcome, c.name);
    assert.deepEqual(incompleteEvents(events), [], c.name);
  }
});
