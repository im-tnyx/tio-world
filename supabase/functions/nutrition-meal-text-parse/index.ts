import { createSupabaseContext } from "npm:@supabase/server@1.7.0";

import { createMealTextParseDependencies } from "./composition.ts";
import { createMealTextHandler } from "./handler.ts";
import { mealParserDiagnostic } from "./diagnostics.ts";

function env(name: string): string {
  return Deno.env.get(name)?.trim() ?? "";
}

function canonicalCountryCode(value: unknown): string | null {
  if (typeof value !== "string") return null;
  const trimmed = value.trim();
  return /^[A-Z]{2}$/.test(trimmed) ? trimmed : null;
}

const handler = createMealTextHandler(createMealTextParseDependencies({
  readEnv: env,
  authenticate: async (request) => {
    const { data, error } = await createSupabaseContext(request, { auth: "user" });
    if (error != null || data == null) {
      if (error?.status !== 401) mealParserDiagnostic("auth_unavailable", { reason: "session_context" });
      return error?.status === 401
        ? { kind: "unauthorized" as const }
        : { kind: "unavailable" as const };
    }

    const { data: profile, error: profileError } = await data.supabase
      .from("user_profiles")
      .select("country_code")
      .maybeSingle();

    if (profileError != null) {
      mealParserDiagnostic("auth_unavailable", { reason: "profile_lookup" });
      return { kind: "unavailable" as const };
    }

    return {
      kind: "authenticated" as const,
      countryCode: canonicalCountryCode(profile?.country_code),
    };
  },
}));

Deno.serve(handler);
