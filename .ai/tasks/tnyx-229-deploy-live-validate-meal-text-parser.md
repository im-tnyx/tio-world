# TNYX-229 — N5D-7a — Deploy and live-validate protected meal-text parser

**Status:** Blocked
**Primary owner:** Nutrition (Supabase Edge Function `nutrition-meal-text-parse`)
**Affected platforms:** Hosted Supabase Edge Function only; no Flutter, UI, database, or `services/api` change

## Owner Approval and Scope Boundary

**Trigger:** None for this pass (deployment/runtime-validation gate for already-merged source)
**Approval status:** Readiness audit authorized by owner on 2026-09-19. **Deployment NOT authorized.**
**Approval evidence:** Linear TNYX-229 description ("No deployment is authorized merely by creation of this issue") and the 2026-09-19 owner instruction for a final pre-deployment evidence audit only.
**Approved product/UI/data-shape boundaries:** Deploy exactly the merged `nutrition-meal-text-parse` from `main` with `verify_jwt = true`, then run a bounded authenticated smoke validation. Nothing else.
**Explicit non-changes:** Flutter/UI, Add Food activation (TNYX-226), Meal Editor, DB schema/RLS/RPC/migrations, `services/api`, parser redesign, service-role usage, secret creation/rotation/removal, automatic MealLog persistence.

## Active Handoff

**Planning owner:** Owner (Linear TNYX-229)
**Implementation owner:** Local Claude Code agent (readiness audit only)
**Review owner:** Owner
**Implementation ownership state:** Blocked
**Ownership transition:** Not applicable
**Repository state last verified:** 2026-09-19 (post-TNYX-234 re-audit)
**Branch:** `tnyx/tnyx-229-n5d-7a-deploy-and-live-validate-protected-meal-text-parser` (this brief only)
**HEAD SHA:** audited `main` = `316d9a8229a29935d6b9e6669cfcc4eb06c06e31`
**Observed working-tree state:** Clean `main` before this brief
**Observed uncommitted/dirty files:** None
**PR / tracker:** Linear TNYX-229 = In Progress; TNYX-226 = Backlog, blocked by TNYX-229; TNYX-230, TNYX-233, and TNYX-234 are Done/merged. No TNYX-229 PR.
**Current implementation state:** Post-TNYX-234 test-only re-audit complete. S1 is cleared in main. Runtime remains NOT DEPLOYED.
**Relevant execution surface:** `supabase/config.toml`, `supabase/functions/nutrition-meal-text-parse/**`, hosted project `oykupyiitspujzpwwvuj`
**Validation completed at SHA:** `316d9a82` source/config/runtime re-audit; prior parser CI remained green through TNYX-234 merge
**Validation remaining:** Technical runtime and authenticated E2E validation — NOT RUN until deployment is authorized.
**Current blocker:** Test-only deployment still requires a synthetic normal user with intentionally saved non-US `country_code`, explicit deployment authorization, and live runtime validation. Production gates stay OPEN.
**Open review finding IDs:** TNYX-229-B1 … B5; TNYX-229-S1 RESOLVED by TNYX-234
**Next exact action:** Prepare a synthetic normal test account through the normal app flow and intentionally save a non-US `country_code` (for example `IN`). Then, after separate explicit deployment authorization, deploy exact current `main` with `verify_jwt=true` and run authenticated smoke validation.

## 1. Discovery

### User Outcome

The merged protected parser is live behind `verify_jwt = true` and proven with a normal signed-in user session before TNYX-226 may activate Add Food text submit.

### Success Criteria

See Linear TNYX-229 Acceptance. This pass only proves pre-deployment readiness.

### Non-Goals

Deployment itself (until authorized), UI activation, any source change.

## 2. Codebase Exploration

### Verified Evidence (2026-09-19)

- `main` = `origin/main` = `f0e8ca40`; function dir and `supabase/config.toml` are byte-identical to `6d2b5803` (last green `supabase-functions-ci` run).
- `supabase/config.toml`: `[functions.nutrition-meal-text-parse] verify_jwt = true`.
- Deploy payload: `index.ts` + 12 relative non-test modules, all tracked; only external import `npm:@supabase/server@1.7.0`; no `deno.json`/import map; no untracked or ignored files in the function dir.
- Auth: `createSupabaseContext(request, { auth: "user" })`; 401 → `unauthorized`, other auth errors → sanitized `unavailable`.
- Country: caller-scoped `data.supabase.from("user_profiles").select("country_code").maybeSingle()`; RLS `user_profiles_select_own` (`auth.uid() = user_id`) scopes the row. Invalid/missing value → `null` → `incomplete` before any provider call. No India/US default; FatSecret receives explicit `region=<countryCode>`.
- No service-role/secret-key/admin usage; the only DB access is the RLS-scoped read above; no insert/update/rpc; no `console.*`; no secret-like literals.
- Env contract (source-derived): `MEAL_INTERPRETER_PRIMARY`, `GEMINI_API_KEY`, `GEMINI_MODEL`, `OPENAI_API_KEY`, `OPENAI_MODEL`, `FATSECRET_CLIENT_ID`, `FATSECRET_CLIENT_SECRET`, `EDAMAM_APP_ID`, `EDAMAM_APP_KEY`. Matches Linear.
- Gemini + OpenAI orchestration intact (`selectMealInterpreter`); OpenAI request keeps `store: false`.
- Deadlines: server `DEFAULT_REQUEST_DEADLINE_MS = 45_000`; Flutter `SupabaseMealTextParseRepository` `requestTimeout = 50s`.
- Flutter: no direct Gemini/OpenAI/FatSecret/Edamam endpoint or key reference under `apps/`.
- Live: project `ACTIVE_HEALTHY` (`ap-south-1`); Edge Functions = `google-login-admission` only; `nutrition-meal-text-parse` NOT DEPLOYED.
- Live data fact (TNYX-233 handoff): all existing `user_profiles` rows have `country_code IS NULL`, so any existing user would get `incomplete` without an intentional country value.
- `FatSecretResolver` still requests OAuth scope `basic` while sending `region`; FatSecret documents localized `region` as Premier-exclusive.

## 3. Clarification

| Decision | Status | Rationale | Owner |
|---|---|---|---|
| Deploy in this pass | Not authorized | Owner instruction | Owner |
| `MEAL_INTERPRETER_PRIMARY` absent | Accepted as Gemini default unless owner states otherwise | Source default; intentional value to be confirmed at deploy authorization | Owner |
| Smoke-test country value | Needs owner decision | A dedicated normal test user must have an intentional `country_code`; setting it is a production data write via that user's own RLS-scoped session | Owner |

## 4. Architecture Design

No change. Deploy exact merged source.

## 5. Implementation Plan — authenticated smoke plan (NOT EXECUTED)

Run only after explicit deployment authorization. Use Supabase CLI 2.116.0 syntax discovered via `--help`.

1. Re-verify `main` SHA, clean tree, function dir unchanged, live inventory.
2. Deploy: `supabase functions deploy nutrition-meal-text-parse --project-ref oykupyiitspujzpwwvuj` (no `--no-verify-jwt`; `verify_jwt = true` from `config.toml`; `--use-api` if Docker is unavailable).
3. Verify: `supabase functions list --project-ref oykupyiitspujzpwwvuj` shows `nutrition-meal-text-parse` ACTIVE, `verify_jwt: true`, new version, `index.ts` entrypoint; `google-login-admission` unchanged.
4. Negative auth (publishable key as `apikey` only):
   - no `Authorization` → expect 401 (platform JWT gate), handler not reached;
   - malformed/invalid JWT → expect 401;
   - no provider call may occur (check function logs show no invocation reaching provider work).
5. Authenticated: dedicated normal test user, session obtained by normal sign-in by the owner; `Authorization: Bearer <user access token>` + `apikey: <publishable key>`. Never service role.
6. Country: before test, confirm the test user's `user_profiles.country_code` is an intentional owner-chosen value (set only via that user's own session under `user_profiles_update_own`, with owner approval). Never infer from phone, locale, timezone, IP, language, or device.
7. Outcome matrix (synthetic, non-personal meal text):
   - `success`: explicit quantity + generic food (e.g. `200 g plain yogurt`);
   - `unrecognized`: non-food text (e.g. `qwerty asdf`);
   - `incomplete`: food without amount (e.g. `dal`), and a test user with `country_code` NULL;
   - `unavailable`: observe only if it occurs naturally; otherwise rely on the unit-test matrix (no secret mutation to force it).
   Confirm `success` items carry only `displayName`, `quantity`, `servingUnit`, `nutritionSnapshot` (schemaVersion 1) — provider-neutral and mappable to `MealLoggingDraft`.
8. Errors: every non-success body is exactly `{schemaVersion:1,outcome}` or `{error}`; no provider names, IDs, URLs, stack traces.
9. Latency: record wall-clock per call; must stay under the 45 s server deadline and the 50 s Flutter client timeout.
10. Persistence/logging: confirm no DB rows written by the function and function logs contain no meal text or provider payloads.
11. Evidence: record only status codes, outcome enums, latency, function version, and redacted shapes in Linear/GitHub. Never paste JWTs, keys, raw provider payloads, or personal meal text.

## 6. Quality Review

### Validation Run (at `f0e8ca40`, Deno 2.9.7 machine-local toolchain; commands mirror `.github/workflows/supabase-functions-ci.yml`)

```text
deno check supabase/functions/nutrition-meal-text-parse/index.ts           PASS
deno check supabase/functions/nutrition-meal-text-parse/*.ts               PASS
deno test --allow-read=supabase/functions/nutrition-meal-text-parse \
          supabase/functions/nutrition-meal-text-parse                     PASS — 78 passed / 0 failed
git diff --check                                                           PASS
supabase-functions-ci on 6d2b5803 (function dir identical to main)         success
```

### Gate Summary

| Gate | Result |
|---|---|
| Deployment payload readiness | PASS |
| Local validation | PASS (78/78) |
| Credential name presence (CLI `secrets list`, names only) | PRESENT: `GEMINI_API_KEY`, `OPENAI_API_KEY`, `FATSECRET_CLIENT_ID`, `FATSECRET_CLIENT_SECRET`, `EDAMAM_APP_ID`, `EDAMAM_APP_KEY`. ABSENT (optional): `MEAL_INTERPRETER_PRIMARY` (→ Gemini default), `GEMINI_MODEL`, `OPENAI_MODEL`. Presence only; validity not provable without a live call. |
| FatSecret rotation | ROTATION NOT EVIDENCED |
| OpenAI source storage setting | `store: false` present |
| OpenAI account/project data control | NOT EVIDENCED |
| Smoke plan | READY (§5), pending B5 decision |
| Technical runtime validation | NOT RUN |
| Authenticated E2E validation | NOT RUN |
| Country-aware localization/entitlement | OPEN |
| Durable nutrition-storage permission | OPEN |
| TNYX-226 activation | BLOCKED |
| Security advisors | Baseline unchanged (5 authenticated `SECURITY DEFINER` RPC warnings + leaked-password protection disabled); none introduced by TNYX-229; out of scope |

### Evidence Pass 2 (2026-09-19)

Reconciliation:
- `main` = `origin/main` = `f0e8ca40704dcf0612c147d7a1449608c1d026fb`; parser source/config unchanged since the first audit.
- Branch `tnyx/tnyx-229-n5d-7a-deploy-and-live-validate-protected-meal-text-parser` HEAD = `76410439` before this update; 1 ahead / 0 behind `main`; the only change is this brief; no PR.
- Live Edge Functions: `google-login-admission` only; `nutrition-meal-text-parse` NOT DEPLOYED.
- No new owner evidence in Linear TNYX-229 since the first audit checkpoint.

Secret-name metadata (names and `updated_at` only, via `supabase secrets list`): `FATSECRET_CLIENT_ID` / `FATSECRET_CLIENT_SECRET` 2026-09-18T06:13Z; `GEMINI_API_KEY` 2026-09-18T16:03Z; `OPENAI_API_KEY` 2026-09-18T16:07Z; `EDAMAM_APP_ID` / `EDAMAM_APP_KEY` 2026-09-18T16:03Z. `MEAL_INTERPRETER_PRIMARY`, `GEMINI_MODEL`, `OPENAI_MODEL` absent (optional).

| Gate | Result | Basis |
|---|---|---|
| B1 FatSecret rotation | **NOT EVIDENCED** | No owner/provider confirmation of regeneration; Supabase timestamp alone cannot prove provider-side rotation. |
| B2 OpenAI data control | **OPEN** | Source: `store: false` (openai_client.ts:72). Account/project posture: Unknown / not evidenced. Synthetic-live-test authorization: NOT RECORDED. |
| B3 Gemini posture | **OPEN** | Key type, billing plan, and retention/data-use posture for the configured project/key: not evidenced. Synthetic-live-test authorization: NOT RECORDED. |
| B4 FatSecret reachability/entitlement | **OPEN** | Network: INCOMPATIBLE on current evidence. Tier/region entitlement: UNKNOWN. Source/provider mismatch: YES (S1). |
| B5 dedicated test user | **OPEN** | Test user identified: NO. Proposed country: owner to choose. Path: that user's own session `PATCH /rest/v1/user_profiles` under `user_profiles_update_own` (no Flutter path writes `country_code` today). Owner authorization: NOT RECORDED. |
| Durable nutrition storage | **OPEN** | No written commercial/storage permission in tracker; FatSecret public terms limit indefinite storage to listed identifiers. |

B4 detail (FatSecret docs fetched 2026-09-19):
- OAuth 2.0 guide: tokens can only be requested from a finite set of IP addresses registered per key; CIDR ranges only on PREMIER / PREMIER Free. Earlier owner evidence showed IP-allowlist rejections. Supabase hosted Edge Functions have no stable egress IP. Network: INCOMPATIBLE unless the owner shows the restriction is lifted or covers Supabase egress.
- Localization guide: localization is "a premium feature only made available to select accounts"; `IN` is a listed region. The account tier is not evidenced, so entitlement is UNKNOWN.
- `foods.search` v3 docs list scope `premier`; the OAuth guide also lists a separate `localization` scope.
- Source (`fatsecret_client.ts:138`) requests only `scope: "basic"` but sends `region=<countryCode>` on `foods.search` (legacy `server.api`) and `food/v5`.

### Test-Only Gate (2026-09-19)

Owner decision frozen (2026-09-19): the app is in development/testing, and this feature has no real production users. A paid/Premier FatSecret plan is **not** required for current development. Premier/localization entitlement, static-egress architecture, durable/commercial storage permission, and production country coverage stay **production gates (OPEN)**. Technical testing uses synthetic, non-personal meal text only. Provider limitations may be recorded as expected, but TNYX-233 country rules must not be weakened: no silent country fallback.

Reconciliation: `main` = `f0e8ca40`; `supabase/` unchanged; branch HEAD `0bab5854` (2 ahead / 0 behind, brief only); no PR; live functions = `google-login-admission` only.

**FatSecret gate split**
- Development/test-only blocker: S1 (below). FatSecret live calls are also blocked until the exposed credential is rotated (B1).
- Production-only gates (OPEN, and they do not stop bounded dev testing): Premier/localization entitlement, full country coverage, static egress for the IP allowlist, and durable/commercial storage.

**S1 audit — `S1: SOURCE FIX REQUIRED`**
- The token request uses `scope: "basic"` (`fatsecret_client.ts:138`).
- Search uses `method=foods.search` on legacy `server.api` (v1); detail uses `food/v5`. Both send `region=<countryCode>`.
- FatSecret v1 `foods.search` docs: `region` and `language` are "Premier Exclusive"; region defaults to `US`; unentitled or unsupported behavior is not documented; the response has no field indicating region.
- The source only fails closed when FatSecret returns an explicit `error` (covered by the `ZZ` test). If FatSecret ignores `region` under `basic`, US results pass `selectFatSecretMatch` and return as `success` for a non-US user. The invariant is therefore **not guaranteed**.
- Edamam receives no country context. After fail-closed, a non-US user would reach Edamam; TNYX-233 approved this, and TNYX-234 asks the owner to reconfirm it.
- Smallest fix, tracked as **TNYX-234** (Backlog, blocks TNYX-229): while the source requests only `basic`, FatSecret runs only for `US`. Any other valid country returns `incomplete` before the token request (no FatSecret network call). Edamam fallback and missing-country behavior stay unchanged. Includes focused tests. Not implemented in TNYX-229.

**FatSecret credentials**
- `FATSECRET LIVE CALL: BLOCKED UNTIL ROTATION`.
- Current source has no FatSecret on/off switch. With credentials present and a valid country, the resolver always requests a token. Empty credentials would make it `unavailable` without a network call, but that is a secret mutation and needs separate authorization.
- After TNYX-234, a test user with a **non-US** country never contacts FatSecret, so the parser test can proceed without rotation. A `US` test user would call FatSecret and stays blocked until rotation.

**AI testing policy**
- `AI TEST-ONLY USE: CLEAR`. The owner policy allows synthetic, non-personal text only. Source keeps `store: false` (OpenAI), has no provider keys in Flutter, and does no parser logging or persistence.
- `AI PRODUCTION PRIVACY: OPEN`. Gemini and OpenAI account/project retention posture is still not evidenced. Gemini key-type and plan validity is unverified; if the key is rejected, the result becomes `unavailable` and falls back to OpenAI. This is an expected limitation, not a code defect.

**Test user — `TEST USER PLAN: READY` (plan only; owner executes)**
1. The owner creates a synthetic test account through the normal app sign-up. No personal data. The agent must not create accounts.
2. The account completes the normal profile setup, so `public.users` and `user_profiles` rows exist (`user_profiles.name` is NOT NULL; the app writes the row via `SupabaseUserProfileRepository` upsert).
3. Set the intentional country through that user's own session only: `PATCH /rest/v1/user_profiles?user_id=eq.<own id>` with `{"country_code":"<XX>"}` under `user_profiles_update_own`. Use a non-US code (e.g. `IN`) so FatSecret is not contacted after TNYX-234. No service role, no other user's row, no inference from phone/locale/timezone/IP.
4. Keep a second synthetic user, or a temporary own-row `NULL`, for the missing-country `incomplete` case.

**Test-only deploy shape (future, NOT EXECUTED; requires TNYX-234 merged and explicit test-only deployment authorization)**
1. Deploy exact reviewed `main` with `supabase functions deploy nutrition-meal-text-parse --project-ref oykupyiitspujzpwwvuj` (no `--no-verify-jwt`).
2. `supabase functions list`: `nutrition-meal-text-parse` ACTIVE, `verify_jwt: true`, version recorded; `google-login-admission` unchanged.
3. No `Authorization` header → 401.
4. Invalid JWT → 401.
5. Synthetic test-user JWT plus publishable key.
6. Test-user `country_code` = owner-chosen non-US code.
7. Synthetic text only.
8. Expected outcomes:
   - `success` only via Edamam, if Edamam is reachable and resolves (FatSecret skipped by TNYX-234).
   - `unrecognized` for non-food text.
   - `incomplete` for food without an amount, and for the `NULL`-country user.
   - `unavailable` is observed only if it happens naturally. It is not forced by mutating secrets.
9. Confirm no DB rows are written and function logs contain no meal text or provider payloads.
10. Every failure is exactly `{schemaVersion:1,outcome}` or `{error}`.
11. Latency stays under 45 s (server) and 50 s (Flutter).
FatSecret in this shape is **skipped by source (after TNYX-234)**, not bypassed by config.

**Product activation:** TNYX-226 stays BLOCKED on country localization entitlement, FatSecret network architecture, durable/commercial storage, and AI production privacy.

```text
Parser source readiness:                        PASS (except S1)
Local validation:                               PASS (78/78; unchanged source)
Test-only deployment shape:                     DEFINED (requires TNYX-234)
S1 silent-US-fallback safety:                   SOURCE FIX REQUIRED (TNYX-234)
FatSecret paid/Premier required for current dev: NO (production gate, deferred)
FatSecret live-call credential readiness:       BLOCKED UNTIL ROTATION (avoidable via non-US test after TNYX-234)
FatSecret production entitlement:               OPEN
Gemini/OpenAI synthetic test-only use:          CLEAR
Gemini/OpenAI production privacy:               OPEN
Synthetic test user plan:                       READY (owner executes)
Durable nutrition storage:                      OPEN
Technical runtime validation:                   NOT RUN
Authenticated E2E:                              NOT RUN
TNYX-226 activation:                            BLOCKED
```

**Verdict: `TNYX-229 TEST-ONLY GATE: SOURCE SAFETY CLEARED; DEPLOYMENT STILL REQUIRES EXPLICIT AUTHORIZATION + SYNTHETIC TEST USER`**

### Review Findings and Resolution

| ID | Severity | Status | Finding | Observed at SHA | Evidence or follow-up |
|---|---|---|---|---|---|
| TNYX-229-B1 | Blocker | Open | FatSecret credential rotation after prior exposure not evidenced. `FATSECRET_*` secret `updated_at` is unchanged since 2026-09-18 06:13Z. | f0e8ca40 | Owner confirmation (non-secret) that a new client secret was generated provider-side after the exposure and is the value now set in Supabase. |
| TNYX-229-B2 | Blocker | Open | OpenAI org/project retention posture not evidenced; `store: false` is not zero retention (TNYX-230-R3). OpenAI is the fallback, so meal text can reach it even with Gemini primary. | f0e8ca40 | Owner statement of the org/project data-control setting (ZDR / Modified Abuse Monitoring / standard 30-day) and explicit acceptance for live validation with synthetic text. |
| TNYX-229-B3 | Blocker | Open | Gemini key type/plan/data-handling posture not evidenced (prior audit: key-type migration; unpaid tier data may be used for product improvement). | f0e8ca40 | Owner confirmation of key type and paid/unpaid plan + retention posture, or explicit acceptance for synthetic-only smoke text. |
| TNYX-229-B4 | Blocker | Open | FatSecret reachability from hosted Edge Functions not evidenced: prior owner evidence showed a caller-IP allowlist; Supabase hosted Edge Functions have no stable egress IP. Also scope `basic` + explicit `region` (Premier-exclusive) may fail/ignore for non-US countries. | f0e8ca40 | Owner confirmation that the FatSecret IP restriction is removed/compatible, and the account tier for the chosen test country. Otherwise expect `unavailable`/`incomplete` from FatSecret and record it as provider-constrained. |
| TNYX-229-B5 | Blocker | Open | No intentional `country_code` exists for any live user; smoke test needs one. | f0e8ca40 | Owner picks the dedicated normal test user and country, and approves setting it through that user's own session. |
| TNYX-229-S1 | High | Open → TNYX-234 | Source requests OAuth scope `basic` but sends `region`. Localization needs premium entitlement and a `localization`/`premier` scope. If FatSecret ignores `region` under `basic`, a non-US user could silently get US data, contradicting the TNYX-233 no-silent-US rule. Behavior when unentitled is undocumented. | f0e8ca40 | Not a TNYX-229 change. Owner decides either a bounded source fix (request the entitled scope, or fail closed for non-US without entitlement) or US-only smoke validation with this limitation recorded. |

## 7. Final Handoff

### Changed Files

```text
.ai/tasks/tnyx-229-deploy-live-validate-meal-text-parser.md
```

### Actual Behavior

No deployment, secret mutation, source change, or provider call. `nutrition-meal-text-parse` remains NOT DEPLOYED.

### Known Limitations

Secret presence ≠ secret validity; provider acceptance is only provable after an authorized deploy.

### Final Status

`BLOCKED` — source safety is cleared; deployment/runtime validation has not run and still needs explicit authorization plus a synthetic non-US test user.


### Post-TNYX-234 re-audit (2026-09-19)

Fresh AGENTS.md reconciliation after PR #286 merge:

- `main` = `316d9a8229a29935d6b9e6669cfcc4eb06c06e31`.
- TNYX-234 is Done and its fail-closed source fix is present on `main`.
- Current `fatSecretRegionForCountry` allows only `US`; `IN`, `FR`, `ZZ`, or any other non-US/invalid value returns FatSecret `incomplete` before token/network work.
- Parser auth still uses `createSupabaseContext(request, { auth: "user" })` and reads only the signed-in user's `user_profiles.country_code`.
- `supabase/config.toml` still requires `verify_jwt = true`.
- Current Supabase docs confirm that `verify_jwt=true` performs a platform-level user-JWT check before handler execution, and user-scoped Authorization context applies RLS.
- Live Edge Function inventory still contains only `google-login-admission`; `nutrition-meal-text-parse` is NOT DEPLOYED.
- Live `user_profiles` currently has 3 rows and all have `country_code = NULL`.
- The connected Supabase capability still does not expose Edge Function secret inventory/rotation, so secret-name presence from earlier local CLI evidence remains historical evidence, not a fresh connector verification.
- No deployment, secret mutation, schema mutation, provider call, or Flutter/UI change was performed.

Updated gate split:

```text
TNYX-234 / S1 silent-US safety:                  CLEAR
Parser source/auth/config readiness:             PASS
Non-US FatSecret test behavior:                  PASS BY SOURCE (zero FatSecret network call)
Synthetic Gemini/OpenAI test-only use:           OWNER-APPROVED for non-personal text
Synthetic normal test user with country_code:    NOT YET PRESENT
Live parser deployment:                          NOT RUN
Authenticated runtime smoke:                     NOT RUN
FatSecret credential rotation for US calls:      OPEN (not needed for non-US test path)
FatSecret production entitlement/static egress:  OPEN
AI production privacy/retention posture:          OPEN
Durable nutrition storage permission:            OPEN
TNYX-226 product activation:                     BLOCKED
```

Test-only next boundary:
1. Owner creates/uses a synthetic normal user through the normal app flow.
2. That user explicitly saves a non-US country such as `IN` through its own account/profile path.
3. Reconfirm current main + live inventory.
4. Only after separate explicit owner authorization, deploy exact current `main` with `verify_jwt=true`.
5. Run unauthenticated denial + authenticated synthetic smoke tests.
