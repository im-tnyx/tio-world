import { createSupabaseContext } from "npm:@supabase/server@1.7.0";

import { createMealTextParseDependencies } from "./composition.ts";
import { createMealTextHandler } from "./handler.ts";

function env(name: string): string {
  return Deno.env.get(name)?.trim() ?? "";
}

const handler = createMealTextHandler(createMealTextParseDependencies({
  readEnv: env,
  authenticate: async (request) => {
    const { data, error } = await createSupabaseContext(request, { auth: "user" });
    return error == null && data != null;
  },
}));

Deno.serve(handler);
