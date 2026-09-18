import test from "node:test";
import assert from "node:assert/strict";
import { readFileSync } from "node:fs";

import { createMealTextParseDependencies } from "./composition.ts";

const authenticate = async () => ({ kind: "authenticated" as const, countryCode: "IN" });

function envFrom(values: Readonly<Record<string, string>>) {
  const read: string[] = [];
  return {
    read,
    readEnv: (name: string) => {
      read.push(name);
      return values[name] ?? "";
    },
  };
}

function recordingFetch(urls: string[]): typeof fetch {
  return async (input) => {
    urls.push(String(input));
    return new Response("unavailable", { status: 503 });
  };
}

test("composition reads interpreter, selector, and factual provider env names", () => {
  const env = envFrom({});
  createMealTextParseDependencies({ readEnv: env.readEnv, authenticate });

  for (const name of [
    "MEAL_INTERPRETER_PRIMARY",
    "GEMINI_API_KEY",
    "GEMINI_MODEL",
    "OPENAI_API_KEY",
    "OPENAI_MODEL",
    "FATSECRET_CLIENT_ID",
    "FATSECRET_CLIENT_SECRET",
    "EDAMAM_APP_ID",
    "EDAMAM_APP_KEY",
  ]) {
    assert.ok(env.read.includes(name), name);
  }
});

test("default composition calls Gemini first then OpenAI fallback", async () => {
  const urls: string[] = [];
  const deps = createMealTextParseDependencies({
    readEnv: envFrom({ GEMINI_API_KEY: "g", OPENAI_API_KEY: "o" }).readEnv,
    authenticate,
    fetchFn: recordingFetch(urls),
  });

  assert.deepEqual(await deps.interpreter.interpret("dal"), { kind: "unavailable" });
  assert.equal(urls.length, 2);
  assert.match(urls[0], /generativelanguage\.googleapis\.com/);
  assert.equal(urls[1], "https://api.openai.com/v1/responses");
});

test("openai selector composition calls OpenAI first then Gemini fallback", async () => {
  const urls: string[] = [];
  const deps = createMealTextParseDependencies({
    readEnv: envFrom({
      MEAL_INTERPRETER_PRIMARY: "openai",
      GEMINI_API_KEY: "g",
      OPENAI_API_KEY: "o",
      OPENAI_MODEL: "custom-model",
    }).readEnv,
    authenticate,
    fetchFn: recordingFetch(urls),
  });

  await deps.interpreter.interpret("dal");
  assert.equal(urls[0], "https://api.openai.com/v1/responses");
  assert.match(urls[1], /generativelanguage\.googleapis\.com/);
});

test("invalid selector composition makes no provider call", async () => {
  const urls: string[] = [];
  const deps = createMealTextParseDependencies({
    readEnv: envFrom({
      MEAL_INTERPRETER_PRIMARY: "gpt",
      GEMINI_API_KEY: "g",
      OPENAI_API_KEY: "o",
    }).readEnv,
    authenticate,
    fetchFn: recordingFetch(urls),
  });

  assert.deepEqual(await deps.interpreter.interpret("dal"), { kind: "unavailable" });
  assert.deepEqual(urls, []);
});

test("factual resolver composition is unchanged: FatSecret primary, Edamam only as a pair", () => {
  const withPair = createMealTextParseDependencies({
    readEnv: envFrom({ EDAMAM_APP_ID: "a", EDAMAM_APP_KEY: "k" }).readEnv,
    authenticate,
  });
  assert.equal(withPair.primaryResolver.name, "fatsecret");
  assert.equal(withPair.secondaryResolver?.name, "edamam");

  const partial = createMealTextParseDependencies({
    readEnv: envFrom({ EDAMAM_APP_ID: "a" }).readEnv,
    authenticate,
  });
  assert.equal(partial.primaryResolver.name, "fatsecret");
  assert.equal(partial.secondaryResolver, null);
});

test("composition passes authenticate through unchanged", () => {
  const deps = createMealTextParseDependencies({
    readEnv: envFrom({}).readEnv,
    authenticate,
  });
  assert.equal(deps.authenticate, authenticate);
});

test("index.ts keeps signed-in user auth and no privileged client", () => {
  const source = readFileSync(new URL("./index.ts", import.meta.url), "utf8");
  assert.match(source, /createSupabaseContext\(request, \{ auth: "user" \}\)/);
  assert.match(source, /readEnv: env/);
  assert.equal(/service_role|SERVICE_ROLE|SECRET_KEYS/i.test(source), false);
});
