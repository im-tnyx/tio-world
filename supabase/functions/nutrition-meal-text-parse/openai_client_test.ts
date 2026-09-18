import test from "node:test";
import assert from "node:assert/strict";

import { extractStructuredText, OpenAIMealInterpreter } from "./openai_client.ts";
import { MAX_INTERPRETED_ITEMS } from "./interpretation_schema.ts";

function completed(payload: unknown): Response {
  return Response.json({
    status: "completed",
    output: [
      { type: "reasoning", summary: [] },
      {
        type: "message",
        role: "assistant",
        content: [{ type: "output_text", text: JSON.stringify(payload) }],
      },
    ],
  });
}

function interpreterReturning(
  response: Response | (() => Promise<Response>),
  captured?: { init?: RequestInit; url?: string },
): OpenAIMealInterpreter {
  return new OpenAIMealInterpreter({
    apiKey: "test-key",
    fetchFn: async (input, init) => {
      if (captured) {
        captured.url = String(input);
        captured.init = init;
      }
      return typeof response === "function" ? response() : response;
    },
  });
}

test("OpenAI recognized structured output normalizes to candidates", async () => {
  const result = await interpreterReturning(completed({
    mealName: "Lunch",
    items: [
      { foodName: "dal", quantity: 1, unit: "katori" },
      { foodName: "roti", quantity: null, unit: null },
    ],
  })).interpret("1 katori dal and roti");

  assert.deepEqual(result, {
    kind: "recognized",
    mealName: "Lunch",
    items: [
      { foodName: "dal", quantity: 1, unit: "katori" },
      { foodName: "roti", quantity: null, unit: null },
    ],
  });
});

test("OpenAI empty items returns unrecognized", async () => {
  assert.deepEqual(
    await interpreterReturning(completed({ mealName: null, items: [] })).interpret("hello"),
    { kind: "unrecognized" },
  );
});

test("OpenAI never forwards provider-invented nutrition fields", async () => {
  const result = await interpreterReturning(completed({
    mealName: null,
    calories: 999,
    items: [{ foodName: "dahi", quantity: 150, unit: "g", calories: 90, protein: 5 }],
  })).interpret("150g dahi");

  assert.equal(result.kind, "recognized");
  if (result.kind !== "recognized") return;
  assert.deepEqual(result.items, [{ foodName: "dahi", quantity: 150, unit: "g" }]);
  assert.deepEqual(Object.keys(result).sort(), ["items", "kind"]);
});

test("OpenAI malformed or unexpected responses return unavailable", async () => {
  const cases: (() => Response)[] = [
    () => new Response("{not-json", { status: 200 }),
    () => Response.json({ status: "completed", output: [] }),
    () => Response.json({ status: "incomplete", output: [] }),
    () => Response.json({
      status: "completed",
      output: [{ type: "message", content: [{ type: "output_text", text: "{bad" }] }],
    }),
    () => Response.json({
      status: "completed",
      output: [{ type: "message", content: [{ type: "refusal", refusal: "no" }] }],
    }),
    () => completed({ mealName: null, items: [{ foodName: "", quantity: null, unit: null }] }),
    () => completed({ mealName: null, items: [{ foodName: "x", quantity: -1, unit: "g" }] }),
    () => completed({
      mealName: null,
      items: Array.from({ length: MAX_INTERPRETED_ITEMS + 1 }, () => ({
        foodName: "rice",
        quantity: null,
        unit: null,
      })),
    }),
  ];

  for (const make of cases) {
    assert.deepEqual(await interpreterReturning(make()).interpret("rice"), {
      kind: "unavailable",
    });
  }
});

test("OpenAI HTTP failure returns unavailable", async () => {
  assert.deepEqual(
    await interpreterReturning(new Response("rate limited", { status: 429 })).interpret("dal"),
    { kind: "unavailable" },
  );
});

test("OpenAI transport failure returns unavailable", async () => {
  const interpreter = interpreterReturning(async () => {
    throw new Error("network down");
  });
  assert.deepEqual(await interpreter.interpret("dal"), { kind: "unavailable" });
});

test("OpenAI missing API key returns unavailable without a network call", async () => {
  let called = false;
  const interpreter = new OpenAIMealInterpreter({
    apiKey: "",
    fetchFn: async () => {
      called = true;
      return completed({ mealName: null, items: [] });
    },
  });
  assert.deepEqual(await interpreter.interpret("dal"), { kind: "unavailable" });
  assert.equal(called, false);
});

function hangingFetch(): typeof fetch {
  return (_input, init) =>
    new Promise<Response>((_resolve, reject) => {
      init?.signal?.addEventListener("abort", () => reject(new Error("aborted")), {
        once: true,
      });
    });
}

test("OpenAI timeout returns unavailable", async () => {
  const interpreter = new OpenAIMealInterpreter({
    apiKey: "test-key",
    timeoutMs: 5,
    fetchFn: hangingFetch(),
  });
  assert.deepEqual(await interpreter.interpret("150g dahi"), { kind: "unavailable" });
});

test("OpenAI respects parent abort", async () => {
  const parent = new AbortController();
  const interpreter = new OpenAIMealInterpreter({
    apiKey: "test-key",
    timeoutMs: 60_000,
    fetchFn: hangingFetch(),
  });
  const pending = interpreter.interpret("150g dahi", parent.signal);
  parent.abort();
  assert.deepEqual(await pending, { kind: "unavailable" });
});

test("OpenAI request uses Responses API, strict JSON schema, and store:false", async () => {
  const captured: { init?: RequestInit; url?: string } = {};
  await interpreterReturning(completed({ mealName: null, items: [] }), captured)
    .interpret("1 katori dal");

  assert.equal(captured.url, "https://api.openai.com/v1/responses");
  assert.equal(captured.init?.method, "POST");
  const headers = new Headers(captured.init?.headers);
  assert.equal(headers.get("authorization"), "Bearer test-key");

  const body = JSON.parse(String(captured.init?.body));
  assert.equal(body.store, false);
  assert.equal(body.model, "gpt-5.6-luna");
  assert.deepEqual(body.reasoning, { effort: "none" });
  assert.equal(body.text.format.type, "json_schema");
  assert.equal(body.text.format.strict, true);
  assert.equal(body.text.format.name, "meal_interpretation");

  const schema = body.text.format.schema;
  assert.equal(schema.additionalProperties, false);
  assert.deepEqual(schema.required, ["mealName", "items"]);
  assert.equal(schema.properties.items.maxItems, MAX_INTERPRETED_ITEMS);
  assert.equal(schema.properties.items.items.additionalProperties, false);
  assert.deepEqual(
    Object.keys(schema.properties.items.items.properties).sort(),
    ["foodName", "quantity", "unit"],
  );
  assert.match(body.instructions, /Do not calculate or invent calories/);
  assert.equal(body.input, "User meal text: 1 katori dal");
});

test("OpenAI honors OPENAI_MODEL override without default reasoning effort", async () => {
  const captured: { init?: RequestInit; url?: string } = {};
  const interpreter = new OpenAIMealInterpreter({
    apiKey: "test-key",
    model: " custom-model ",
    fetchFn: async (input, init) => {
      captured.url = String(input);
      captured.init = init;
      return completed({ mealName: null, items: [] });
    },
  });
  await interpreter.interpret("dal");

  const body = JSON.parse(String(captured.init?.body));
  assert.equal(body.model, "custom-model");
  assert.equal("reasoning" in body, false);
  assert.equal(body.store, false);
});

test("extractStructuredText rejects non-completed and refusal envelopes", () => {
  assert.equal(extractStructuredText(null), null);
  assert.equal(extractStructuredText({ status: "failed", output: [] }), null);
  assert.equal(
    extractStructuredText({
      status: "completed",
      output: [{ type: "message", content: [{ type: "output_text", text: "{}" }] }],
    }),
    "{}",
  );
});
