import { createSupabaseContext } from "npm:@supabase/server@1.7.0";

import { EdamamResolver } from "./edamam_client.ts";
import { FatSecretResolver } from "./fatsecret_client.ts";
import { GeminiMealInterpreter } from "./gemini_client.ts";
import { createMealTextHandler } from "./handler.ts";

function env(name: string): string {
  return Deno.env.get(name)?.trim() ?? "";
}

const interpreter = new GeminiMealInterpreter({
  apiKey: env("GEMINI_API_KEY"),
  model: env("GEMINI_MODEL") || undefined,
});

const primaryResolver = new FatSecretResolver({
  clientId: env("FATSECRET_CLIENT_ID"),
  clientSecret: env("FATSECRET_CLIENT_SECRET"),
});

const edamamAppId = env("EDAMAM_APP_ID");
const edamamAppKey = env("EDAMAM_APP_KEY");
const secondaryResolver = edamamAppId && edamamAppKey
  ? new EdamamResolver({ appId: edamamAppId, appKey: edamamAppKey })
  : null;

const handler = createMealTextHandler({
  authenticate: async (request) => {
    const { data, error } = await createSupabaseContext(request, { auth: "user" });
    return error == null && data != null;
  },
  interpreter,
  primaryResolver,
  secondaryResolver,
});

Deno.serve(handler);
