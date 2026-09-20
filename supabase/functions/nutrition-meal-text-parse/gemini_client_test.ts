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


async function captureGeminiDiagnostic(
  response: Response,
  mealText = "200 g plain yogurt private meal text",
): Promise<Record<string, unknown>> {
  const original = console.info;
  const lines: string[] = [];
  console.info = (value?: unknown) => lines.push(String(value));
  try {
    const interpreter = new GeminiMealInterpreter({
      apiKey: "private-test-api-key",
      fetchFn: async () => response,
    });
    assert.deepEqual(await interpreter.interpret(mealText), {
      kind: "unavailable",
    });
  } finally {
    console.info = original;
  }
  assert.equal(lines.length, 1);
  return JSON.parse(lines[0]) as Record<string, unknown>;
}

test("Gemini HTTP error emits allowlisted provider status without raw message leakage", async () => {
  const event = await captureGeminiDiagnostic(Response.json({
    error: {
      code: 400,
      status: "INVALID_ARGUMENT",
      message: "private provider detail private-test-api-key private meal text",
      details: [{ arbitrary: "must not be logged" }],
    },
  }, { status: 400 }));

  assert.deepEqual(event, {
    component: "nutrition-meal-text-parse",
    stage: "interpreter_unavailable",
    provider: "gemini",
    reason: "http_error",
    httpStatus: 400,
    providerErrorStatus: "INVALID_ARGUMENT",
  });
  const serialized = JSON.stringify(event);
  assert.equal(serialized.includes("private provider detail"), false);
  assert.equal(serialized.includes("private-test-api-key"), false);
  assert.equal(serialized.includes("private meal text"), false);
  assert.equal(serialized.includes("arbitrary"), false);
});

test("Gemini unknown provider status is reduced to static UNKNOWN", async () => {
  const event = await captureGeminiDiagnostic(Response.json({
    error: {
      status: "SOME_NEW_PROVIDER_STATUS",
      message: "raw message must not be logged",
    },
  }, { status: 400 }));

  assert.equal(event.providerErrorStatus, "UNKNOWN");
  const serialized = JSON.stringify(event);
  assert.equal(serialized.includes("SOME_NEW_PROVIDER_STATUS"), false);
  assert.equal(serialized.includes("raw message"), false);
});

test("Gemini non-JSON HTTP error is reduced to static UNKNOWN", async () => {
  const event = await captureGeminiDiagnostic(
    new Response("private provider body", { status: 400 }),
  );

  assert.equal(event.providerErrorStatus, "UNKNOWN");
  assert.equal(JSON.stringify(event).includes("private provider body"), false);
});
