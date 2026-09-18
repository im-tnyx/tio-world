import test from "node:test";
import assert from "node:assert/strict";

import {
  FallbackMealInterpreter,
  parseInterpreterSelection,
  selectMealInterpreter,
} from "./interpreter_orchestrator.ts";
import type { InterpretationResult, MealInterpreter } from "./types.ts";

const recognized: InterpretationResult = {
  kind: "recognized",
  items: [{ foodName: "dal", quantity: 1, unit: "katori" }],
};

function fake(
  result: InterpretationResult | (() => Promise<InterpretationResult>),
): MealInterpreter & { calls: number } {
  const interpreter = {
    calls: 0,
    async interpret() {
      interpreter.calls += 1;
      return typeof result === "function" ? result() : result;
    },
  };
  return interpreter;
}

test("selector missing/empty defaults to Gemini primary + OpenAI fallback", () => {
  for (const value of [undefined, null, "", "   "]) {
    assert.deepEqual(parseInterpreterSelection(value), {
      ok: true,
      primary: "gemini",
      fallback: "openai",
    });
  }
});

test("selector gemini selects Gemini primary", () => {
  assert.deepEqual(parseInterpreterSelection("gemini"), {
    ok: true,
    primary: "gemini",
    fallback: "openai",
  });
});

test("selector openai selects OpenAI primary", () => {
  assert.deepEqual(parseInterpreterSelection(" openai "), {
    ok: true,
    primary: "openai",
    fallback: "gemini",
  });
});

test("invalid selector is a configuration error", () => {
  for (const value of ["claude", "OpenAI", "gemini,openai", "both"]) {
    assert.deepEqual(parseInterpreterSelection(value), { ok: false });
  }
});

test("invalid selector fails safely without calling any provider", async () => {
  const gemini = fake(recognized);
  const openai = fake(recognized);
  const interpreter = selectMealInterpreter("anthropic", { gemini, openai });

  assert.deepEqual(await interpreter.interpret("dal"), { kind: "unavailable" });
  assert.equal(gemini.calls, 0);
  assert.equal(openai.calls, 0);
});

test("selected primary is called first", async () => {
  const order: string[] = [];
  const tracking = (name: string): MealInterpreter => ({
    async interpret() {
      order.push(name);
      return { kind: "unavailable" };
    },
  });

  await selectMealInterpreter("", { gemini: tracking("gemini"), openai: tracking("openai") })
    .interpret("dal");
  assert.deepEqual(order, ["gemini", "openai"]);

  order.length = 0;
  await selectMealInterpreter("openai", { gemini: tracking("gemini"), openai: tracking("openai") })
    .interpret("dal");
  assert.deepEqual(order, ["openai", "gemini"]);
});

test("recognized primary does not call fallback", async () => {
  const primary = fake(recognized);
  const fallback = fake(recognized);
  assert.deepEqual(
    await new FallbackMealInterpreter(primary, fallback).interpret("dal"),
    recognized,
  );
  assert.equal(fallback.calls, 0);
});

test("unrecognized primary does not call fallback", async () => {
  const primary = fake({ kind: "unrecognized" });
  const fallback = fake(recognized);
  assert.deepEqual(
    await new FallbackMealInterpreter(primary, fallback).interpret("asdf"),
    { kind: "unrecognized" },
  );
  assert.equal(fallback.calls, 0);
});

test("unavailable primary calls fallback and returns its recognized result", async () => {
  const primary = fake({ kind: "unavailable" });
  const fallback = fake(recognized);
  assert.deepEqual(
    await new FallbackMealInterpreter(primary, fallback).interpret("dal"),
    recognized,
  );
  assert.equal(primary.calls, 1);
  assert.equal(fallback.calls, 1);
});

test("throwing primary is treated as unavailable and falls back", async () => {
  const primary = fake(async () => {
    throw new Error("boom");
  });
  const fallback = fake(recognized);
  assert.deepEqual(
    await new FallbackMealInterpreter(primary, fallback).interpret("dal"),
    recognized,
  );
});

test("both unavailable returns unavailable", async () => {
  assert.deepEqual(
    await new FallbackMealInterpreter(
      fake({ kind: "unavailable" }),
      fake({ kind: "unavailable" }),
    ).interpret("dal"),
    { kind: "unavailable" },
  );
});

test("aborted parent before start calls no provider", async () => {
  const parent = new AbortController();
  parent.abort();
  const primary = fake(recognized);
  const fallback = fake(recognized);
  assert.deepEqual(
    await new FallbackMealInterpreter(primary, fallback).interpret("dal", parent.signal),
    { kind: "unavailable" },
  );
  assert.equal(primary.calls, 0);
  assert.equal(fallback.calls, 0);
});

test("parent aborted during primary does not start fallback", async () => {
  const parent = new AbortController();
  const primary = fake(async () => {
    parent.abort();
    return { kind: "unavailable" };
  });
  const fallback = fake(recognized);
  assert.deepEqual(
    await new FallbackMealInterpreter(primary, fallback).interpret("dal", parent.signal),
    { kind: "unavailable" },
  );
  assert.equal(fallback.calls, 0);
});

test("providers are never called in parallel", async () => {
  let active = 0;
  let maxActive = 0;
  const slow = (): MealInterpreter => ({
    async interpret() {
      active += 1;
      maxActive = Math.max(maxActive, active);
      await new Promise((resolve) => setTimeout(resolve, 5));
      active -= 1;
      return { kind: "unavailable" };
    },
  });
  await new FallbackMealInterpreter(slow(), slow()).interpret("dal");
  assert.equal(maxActive, 1);
});
