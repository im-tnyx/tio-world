import test from "node:test";
import assert from "node:assert/strict";

import {
  GeminiMealInterpreter,
  parseGeminiInterpretation,
} from "./gemini_client.ts";

test("Gemini parses structured interpretation without nutrition truth", () => {
  const result = parseGeminiInterpretation(JSON.stringify({
    mealName: "Lunch",
    items: [
      { foodName: "dal", quantity: 1, unit: "katori" },
      { foodName: "roti", quantity: 2, unit: "piece" },
    ],
  }));

  assert.equal(result.kind, "recognized");
  if (result.kind !== "recognized") return;
  assert.equal(result.mealName, "Lunch");
  assert.deepEqual(result.items, [
    { foodName: "dal", quantity: 1, unit: "katori" },
    { foodName: "roti", quantity: 2, unit: "piece" },
  ]);
  assert.equal("nutritionSnapshot" in result.items[0], false);
});

test("Gemini malformed JSON returns unavailable", () => {
  assert.deepEqual(parseGeminiInterpretation("{not-json"), {
    kind: "unavailable",
  });
});

test("Gemini empty item list returns unrecognized", () => {
  assert.deepEqual(
    parseGeminiInterpretation(JSON.stringify({ mealName: null, items: [] })),
    { kind: "unrecognized" },
  );
});

test("Gemini transport failure returns unavailable", async () => {
  const interpreter = new GeminiMealInterpreter({
    apiKey: "test-key",
    fetchFn: async () => {
      throw new Error("network down");
    },
  });

  assert.deepEqual(await interpreter.interpret("1 katori dal"), {
    kind: "unavailable",
  });
});

test("Gemini timeout returns unavailable", async () => {
  const interpreter = new GeminiMealInterpreter({
    apiKey: "test-key",
    timeoutMs: 5,
    fetchFn: (_input, init) =>
      new Promise<Response>((_resolve, reject) => {
        init?.signal?.addEventListener("abort", () => reject(new Error("aborted")), {
          once: true,
        });
      }),
  });

  assert.deepEqual(await interpreter.interpret("150g dahi"), {
    kind: "unavailable",
  });
});
