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

test("Gemini sends the current structured-output request envelope", async () => {
  let requestBody: unknown;

  const interpreter = new GeminiMealInterpreter({
    apiKey: "test-key",
    fetchFn: async (_input, init) => {
      requestBody = JSON.parse(String(init?.body));
      return new Response(JSON.stringify({
        candidates: [{
          content: {
            parts: [{
              text: JSON.stringify({
                mealName: null,
                items: [{ foodName: "yogurt", quantity: 200, unit: "g" }],
              }),
            }],
          },
        }],
      }), { status: 200 });
    },
  });

  const result = await interpreter.interpret("200 g plain yogurt");
  assert.equal(result.kind, "recognized");

  const body = requestBody as {
    generationConfig?: {
      responseFormat?: {
        text?: {
          mimeType?: string;
          schema?: unknown;
        };
      };
      responseMimeType?: unknown;
      responseSchema?: unknown;
    };
  };

  assert.equal(
    body.generationConfig?.responseFormat?.text?.mimeType,
    "application/json",
  );
  assert.ok(body.generationConfig?.responseFormat?.text?.schema);
  assert.equal(body.generationConfig?.responseMimeType, undefined);
  assert.equal(body.generationConfig?.responseSchema, undefined);
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
