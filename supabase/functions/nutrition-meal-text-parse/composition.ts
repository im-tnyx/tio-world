import { EdamamResolver } from "./edamam_client.ts";
import { FatSecretResolver } from "./fatsecret_client.ts";
import { GeminiMealInterpreter } from "./gemini_client.ts";
import type { MealTextHandlerDependencies } from "./handler.ts";
import { selectMealInterpreter } from "./interpreter_orchestrator.ts";
import { OpenAIMealInterpreter } from "./openai_client.ts";

export interface MealTextParseCompositionOptions {
  /** Server-side environment reader; returns "" for missing names. */
  readonly readEnv: (name: string) => string;
  readonly authenticate: MealTextHandlerDependencies["authenticate"];
  /** Test seam only; production uses global fetch. */
  readonly fetchFn?: typeof fetch;
}

export function createMealTextParseDependencies(
  options: MealTextParseCompositionOptions,
): MealTextHandlerDependencies {
  const { readEnv, fetchFn } = options;

  const interpreter = selectMealInterpreter(readEnv("MEAL_INTERPRETER_PRIMARY"), {
    gemini: new GeminiMealInterpreter({
      apiKey: readEnv("GEMINI_API_KEY"),
      model: readEnv("GEMINI_MODEL") || undefined,
      fetchFn,
    }),
    openai: new OpenAIMealInterpreter({
      apiKey: readEnv("OPENAI_API_KEY"),
      model: readEnv("OPENAI_MODEL") || undefined,
      fetchFn,
    }),
  });

  const primaryResolver = new FatSecretResolver({
    clientId: readEnv("FATSECRET_CLIENT_ID"),
    clientSecret: readEnv("FATSECRET_CLIENT_SECRET"),
    fetchFn,
  });

  const edamamAppId = readEnv("EDAMAM_APP_ID");
  const edamamAppKey = readEnv("EDAMAM_APP_KEY");
  const secondaryResolver = edamamAppId && edamamAppKey
    ? new EdamamResolver({ appId: edamamAppId, appKey: edamamAppKey, fetchFn })
    : null;

  return {
    authenticate: options.authenticate,
    interpreter,
    primaryResolver,
    secondaryResolver,
  };
}
