# TNYX-229 — Authenticated meal-parser smoke harness

**Status:** In progress
**Primary owner:** TNYX-229 / Nutrition runtime validation
**Affected platforms:** Flutter app composition + existing Nutrition parser adapter only

## Owner Approval and Scope Boundary

**Approval status:** Approved by owner via repeated `go` instruction after the exact bounded smoke-harness proposal.
**Approved boundary:** Add a non-product, debug/test-only execution surface that reuses the existing signed-in Supabase session and existing `MealTextParseRepository` / `MealTextParseController` path to invoke the already-deployed `nutrition-meal-text-parse` function with synthetic, non-personal meal text.
**Explicit non-changes:** No Add Food activation, no Meal Editor changes, no MealLog persistence, no schema/RLS/RPC/migration, no Edge Function source/config change, no secret change, no services/api, no auth weakening, no service-role use.

## Fresh Reconciliation — 2026-09-19

- `main` = `4d552e685e2928dd77a1c5e5a2ba31e8281e43e4`.
- Live `nutrition-meal-text-parse` is ACTIVE v1 with `verify_jwt=true`.
- Existing app composition already provides `SupabaseMealTextParseRepository` when Supabase is configured.
- Existing repository invokes `SupabaseClient.functions.invoke('nutrition-meal-text-parse', ...)`.
- Existing `MealTextParseController` owns normalization, duplicate suppression, safe failure mapping, and provider-neutral draft handling.
- Current Supabase docs confirm signed-in client invocation supplies the user session JWT and user auth context remains RLS-scoped.
- No existing dedicated non-product parser smoke surface was found on `main`.
- Existing TNYX-229 branch was stale; this slice starts from fresh current main on `tnyx/tnyx-229-authenticated-smoke-harness`.

## Frozen Architecture

```text
owner opens debug-only smoke entry
→ current signed-in app session
→ existing mealTextParseRepositoryProvider
→ SupabaseMealTextParseRepository
→ SupabaseClient.functions.invoke
→ deployed nutrition-meal-text-parse (verify_jwt=true)
→ existing MealTextParseController
→ sanitized outcome / provider-neutral draft + elapsed time
```

## Implementation Rules

- Debug-only/non-release entry surface. It must not become a product navigation destination.
- Reuse the current repository/controller. Do not create a second HTTP client or manually handle JWTs.
- Synthetic non-personal examples only.
- Show only sanitized status/outcome, elapsed time, and provider-neutral draft shape. Never display JWTs, keys, raw provider payloads, provider URLs, stack traces, or raw logs.
- No persistence.
- No changes to `AppRoutes` public product route catalog unless strictly necessary; prefer a debug-only route/string owned by app composition.
- TNYX-226 remains untouched and blocked until TNYX-229 handoff is explicitly cleared.

## Smoke Matrix

- success candidate: `200 g plain yogurt`
- unrecognized candidate: `qwerty asdf`
- incomplete candidate: `dal`
- unavailable: observe naturally only; do not mutate secrets to force it

The owner test account currently has intentionally saved `country_code = IN`. Current source must skip FatSecret for non-US and may use the configured secondary factual resolver.

## Validation

- focused Flutter analyze/tests for changed app surface
- verify release builds cannot navigate to/render the harness
- verify no source references to JWT/accessToken/service-role handling are added
- live owner smoke must be executed from a normal signed-in app session after the branch is run locally
- record only outcome enum / elapsed time / redacted draft shape in Linear

## Handoff

This slice does not itself clear TNYX-229 until authenticated live execution succeeds. Production provider entitlement, AI privacy/retention, and durable nutrition-storage gates remain separate.
