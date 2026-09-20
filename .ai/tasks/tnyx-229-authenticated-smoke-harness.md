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

## Reachability Follow-up — 2026-09-19

- The registered route was not practically reachable on Android: the standard
  Flutter `--route` / Android `route` launch extra was replaced by the normal
  `splash -> home` bootstrap redirect, and the app exposes no debug menu or
  generic deep-link entry.
- The bounded fix consumes only the exact
  `/_debug/meal-parser-smoke` platform startup route in non-release builds,
  waits for the normal authenticated bootstrap to reach `Ready`, and then
  opens the existing harness once.
- Unrelated startup routes remain ignored. The route registration and startup
  selector both fail closed in release mode.
- Launch command: `flutter run -d emulator-5554 --route=/_debug/meal-parser-smoke --dart-define-from-file=.runtime.qa.json`.

## Authenticated Live Smoke — 2026-09-19

The app restored the existing normal Supabase user session through the regular
`AppSessionBootstrapController` path and reached `AppSessionBootstrapReady`
before opening the harness. No JWT, key, credential, raw response, header, or
sensitive session object was printed or copied.

| Synthetic case | Controller status | elapsedMs | Draft shape | Sanitized message |
|---|---|---:|---|---|
| `200 g plain yogurt` | `failed` | 8008 | no draft | `Couldn't process that meal right now. Try again.` |
| `qwerty asdf` | `failed` | 1425 | no draft | `Couldn't process that meal right now. Try again.` |
| `dal` | `failed` | 3241 | no draft | `Couldn't process that meal right now. Try again.` |

All three failures map to the controller's safe `unavailable` presentation.
The client intentionally collapses transport/auth/provider/runtime details to
that same boundary, so the exact live server-side cause cannot be derived from
the safe harness output. The owner account country was not changed.

Gate result from this run:

- technical runtime validation: `FAIL`
- authenticated end-to-end validation: `FAIL`
- country-aware localization/entitlement gate: `OPEN`
- durable nutrition-storage gate: `OPEN`
- TNYX-226 activation: `BLOCKED`

Validation after the reachability fix:

- `cd apps/app && flutter analyze`: PASS
- `cd apps/app && flutter test test/app/meal_parser_smoke_route_test.dart`: PASS (3 tests)
- focused router stability + smoke-route tests: PASS (4 tests)
- `cd apps/app && flutter test`: PASS (323 tests)
- focused Nutrition controller/repository tests: PASS (30 tests)
- debug build/install/start on `emulator-5554`: PASS; authenticated smoke page reached
- live synthetic smoke outcomes: FAIL as recorded above

## Handoff

This slice does not itself clear TNYX-229 until authenticated live execution succeeds. Production provider entitlement, AI privacy/retention, and durable nutrition-storage gates remain separate.


## FatSecret IN Capability Follow-up — 2026-09-19

Owner approved extending this existing debug-only harness to invoke the separately deployed authenticated diagnostic Edge Function `tnyx-229-fatsecret-in-probe`.

- Reuse the existing `SupabaseClient.functions.invoke` authenticated session path.
- Invoke only the diagnostic function; it owns the synthetic `plain yogurt` + `region=IN` provider probe server-side.
- Display only bounded `stage`, `category`, and optional numeric `httpStatus`.
- Do not display/copy JWTs, provider tokens, credentials, raw provider bodies, URLs/query strings, or identity/session data.
- This remains non-release/debug-only and introduces no product navigation.
- No production parser routing change, persistence, schema/RLS/RPC, secret mutation, deployment, or TNYX-226 work is part of this Flutter follow-up.


## Fresh Runtime Reconciliation — 2026-09-20

The earlier `ACTIVE v1` / first-smoke state above is historical and must not be treated as current runtime truth.

Current verified live state:
- production `nutrition-meal-text-parse`: ACTIVE v21
- `verify_jwt=true`
- live bundle SHA-256: `ac1dbdd45de10311e370cc8b7c2f16fee091445262e4a4400b3d16a01a8e9553`
- v21 is the owner-authorized bounded Gemini request-contract deployment from Draft PR #292
- exact underlying Flutter smoke-harness source head already CI-validated: `83392b32e7e9baf7cf88b10a7d7e390d90aabbc1`
- Flutter CI run #2662: PASS
- TNYX-238 is now Done with Open Food Facts candidate verdict `PARTIAL`; it does not provide a generic production resolver for common Indian home-food terms and does not clear TNYX-229/TNYX-226

Latest known production-parser runtime evidence predates v21:
- v15 authenticated `200 g plain yogurt` reached the parser but produced no draft
- correlated diagnostics at that time showed Gemini HTTP 400 and Edamam HTTP 401/authentication
- Gemini HTTP 400 was subsequently addressed and v21 deployed
- there is no recorded authenticated production-parser smoke after v21 deployment

### Next exact runtime gate

Run exactly one existing `Success candidate` (`200 g plain yogurt`) through this normal signed-in debug harness against live v21.

Record only:
- controller `status`
- `elapsedMs`
- sanitized controller message
- if a draft is returned: item count / captureSource / mealName only
- safe server diagnostic stage/provider/reason/httpStatus only if separately visible through the approved redacted diagnostic surface

Do not expose JWT/access tokens, provider credentials, provider bodies/URLs, identity/profile data, or raw meal/provider logs.

### Decision rule

- If the v21 authenticated request returns a provider-neutral draft, continue TNYX-229 acceptance reconciliation before considering TNYX-226.
- If it still fails, do not guess or add another resolver. Use only the existing redacted diagnostics to identify the current failing stage/provider, then take one bounded corrective slice based on that evidence.
- TNYX-226 remains blocked until TNYX-229 is explicitly cleared.

No new production routing, deployment, secret/config, schema/RLS/RPC, or product UI change is authorized by this reconciliation.


## Successful authenticated production smoke — 2026-09-20

After the owner created a new Edamam **Food Database API** application, directly validated its App ID/Key pair with the official parser endpoint (`HTTP 200`), and updated the matching Supabase secrets, the existing authenticated smoke harness succeeded for the first time.

Fresh state:
- harness branch head: `4523af44b709f88fcbb1a615eb725e81643e124f` before this docs-only reconciliation
- working tree reported clean by owner
- live `nutrition-meal-text-parse`: ACTIVE v25
- `verify_jwt=true`
- bundle SHA-256 unchanged: `ac1dbdd45de10311e370cc8b7c2f16fee091445262e4a4400b3d16a01a8e9553`
- unchanged bundle hash plus successful direct Edamam credential validation is consistent with the runtime blocker being credential/config-side rather than a parser-code change

Exactly one normal signed-in `Success candidate` (`200 g plain yogurt`) produced:
- controller status: `succeeded`
- elapsed: `4803 ms`
- item count: `1`
- `captureSource: text`
- `mealName: Plain yogurt`
- no failure message
- no server failure diagnostic in the correlated window

Evidence boundary:
- this proves the normal authenticated app → repository → protected Edge Function → provider-neutral draft path works on the current live function;
- it does not identify which interpreter succeeded because success diagnostics are intentionally absent;
- for the owner account with `country_code=IN`, current routing makes Edamam the factual fallback path after the primary resolver cannot serve that market, but no success-provider event is emitted, so provider attribution should not be overstated;
- the smoke UI does not expose nutrition values, so this run validates draft construction/reachability, not factual nutrition-value quality.

### Current TNYX-229 technical gate

- deployed function active with JWT verification: PASS
- normal authenticated end-to-end success: PASS
- provider-neutral draft readiness: PASS
- safe failure sanitization: previously observed PASS
- unavailable behavior: previously observed live and covered by focused tests
- unauthenticated denial: covered by `verify_jwt=true` plus handler test returning HTTP 401
- no persistence/UI/schema/services-api changes: PASS for this slice
- representative live `unrecognized`: still to run
- representative live `incomplete`: still to run
- country-aware provider entitlement/commercial coverage: OPEN
- durable nutrition-storage permission: OPEN
- TNYX-226 activation: BLOCKED until the remaining live matrix is reconciled and the separate product-activation gates are explicitly decided

### Next exact live matrix

Run exactly once each, without changing secrets/config:
1. `Unrecognized candidate` → synthetic `qwerty asdf`
2. `Incomplete candidate` → synthetic `dal`

Record only controller status, elapsedMs, sanitized message, and draft shape if any. Inspect only approved redacted server diagnostics if a failure/provider error is separately visible.

Do not intentionally force `unavailable` by breaking credentials or configuration; that outcome already has live evidence and deterministic test coverage.
