import { createSupabaseContext } from "npm:@supabase/server@1.7.0";

import { probeFatSecretIndiaCapability } from "./fatsecret_capability_probe.ts";

function env(name: string): string {
  return Deno.env.get(name)?.trim() ?? "";
}

Deno.serve(async (request) => {
  if (request.method !== "POST") {
    return Response.json({ error: "method_not_allowed" }, { status: 405 });
  }

  const { data, error } = await createSupabaseContext(request, { auth: "user" });
  if (error != null || data == null) {
    return Response.json({ error: "unauthorized" }, { status: 401 });
  }

  const result = await probeFatSecretIndiaCapability({
    clientId: env("FATSECRET_CLIENT_ID"),
    clientSecret: env("FATSECRET_CLIENT_SECRET"),
  });

  return Response.json({ countryCode: "IN", synthetic: true, result });
});
