import test from "node:test";
import assert from "node:assert/strict";

import { mealParserDiagnostic } from "./diagnostics.ts";

test("diagnostics emit only bounded metadata", () => {
  const original = console.info;
  const lines: string[] = [];
  console.info = (value?: unknown) => lines.push(String(value));
  try {
    mealParserDiagnostic("interpreter_unavailable", {
      provider: "openai",
      reason: "http_error",
      httpStatus: 429,
    providerErrorCategory: "rate_limit",
      providerErrorCategory: "rate_limit",
    });
  } finally {
    console.info = original;
  }

  assert.equal(lines.length, 1);
  assert.deepEqual(JSON.parse(lines[0]), {
    component: "nutrition-meal-text-parse",
    stage: "interpreter_unavailable",
    provider: "openai",
    reason: "http_error",
    httpStatus: 429,
  });
  assert.equal(/mealText|authorization|token|key|url|body|user/i.test(lines[0]), false);
});
