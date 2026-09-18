# TNYX-224 — N5D-6 — Supabase Edge Function protected meal-text parser

**Status:** In progress
**Primary owner:** Nutrition (Supabase Edge Function boundary)
**Affected platforms:** Supabase (`supabase/functions`); no Flutter or database-shape change

## Owner Approval and Scope Boundary

**Trigger:** New independently scoped product task/feature slice (server implementation)
**Approval status:** Approved
**Approval evidence:** Owner prompt of 2026-09-18 explicitly opens the TNYX-224 implementation gate using FatSecret Free/Basic for development; follow-up owner prompt authorizes Edamam as a second factual resolver/fallback. Linear TNYX-224 records both decisions.
**Approved product/UI/data-shape boundaries:** One authenticated Nutrition-owned Supabase Edge Function; Gemini only for structured interpretation; FatSecret + Edamam for factual nutrition resolution; no provider-data persistence; no schema/RLS/RPC change; no Flutter/UI change; no `services/api`.
**Explicit non-changes:** TNYX-225, TNYX-226, AddFoodSheet, Meal Editor UI, provider provenance columns, database migrations, broad TNYX-33 AI abstraction, proxy/static-egress infrastructure.

## Active Handoff

**Planning owner:** Prior audit + current fresh reconciliation
**Implementation owner:** ChatGPT (current session)
**Review owner:** Not applicable yet
**Implementation ownership state:** Active
**Ownership transition:** Interrupted prior implementation → current implementation owner
**Repository state last verified:** 2026-09-18
**Branch:** `tnyx/tnyx-224-n5d-6-supabase-edge-function-protected-meal-text-parser`
**Base main SHA:** `7c7df7b30256091301d93325c031440f6b44d526`
**Observed working-tree state:** GitHub API branch audit: 1 commit ahead / 0 behind before takeover. User confirmed branch push. This API-based session cannot inspect the user's post-push local working tree directly.
**Observed uncommitted/dirty files:** None observable remotely. Before takeover the pushed delta contained this task brief plus `supabase/functions/nutrition-meal-text-parse/contract.ts`.
**PR / tracker:** No PR yet; Linear TNYX-224 = `In Progress`
**Current implementation state:** Provider-neutral schema-v1 contract exists; bounded Edge Function implementation is continuing.
**Relevant execution surface:** `supabase/functions/nutrition-meal-text-parse/*`, `supabase/config.toml`, this task brief
**Validation completed at SHA:** None for current implementation tree yet
**Validation remaining:** focused Deno/unit validation, branch scope audit, exact-head checks; live smoke only after deployment gates
**Current blocker:** No code blocker. Live FatSecret validation remains gated by rotated exposed credential and account IP restriction. Edge Function secret names cannot be enumerated with the available Supabase connector, so runtime presence must be verified without exposing values before deployment.
**Open review finding IDs:** TNYX-224-G2 (Deferred provenance); TNYX-224-G3 (live deployment gate)
**Next exact action:** Implement authenticated handler, Gemini interpreter, FatSecret primary resolver, Edamam fallback, deterministic normalization/tests; validate; then create a focused draft PR. Do not merge.

## 1. Discovery

### User Outcome

Provide the real protected server implementation behind the existing provider-neutral meal-text parser contract:

```text
authenticated Flutter user
→ Supabase Edge Function
→ Gemini structured interpretation only
→ FatSecret factual resolver
→ Edamam factual fallback when needed
→ exactly one factual provider per successful item
→ Tio-owned normalized response
→ later TNYX-225 remote repository adapter
```

### Success Criteria

- Authenticated Supabase user is required.
- Request remains `{ schemaVersion: 1, mealText }`; caller cannot select user/provider/model.
- Gemini may extract food/quantity/unit intent but never supplies canonical nutrition.
- Every successful item is backed by exactly one factual provider response.
- FatSecret is the V1 primary resolver; Edamam is a bounded secondary fallback.
- Returned nutrition uses existing Tio `NutritionSnapshot` schema version 1 and canonical nutrient IDs.
- Unknown nutrients remain absent; no unknown-to-zero conversion.
- Provider/network/runtime failures are sanitized.
- No raw meal text/provider payload/provider IDs are persisted or logged.
- No Flutter, database schema, RLS, RPC, migration, or `services/api` change.

### Non-Goals

TNYX-225/TNYX-226, product-visible Add Food activation, voice/photo/search/barcode, provider provenance persistence, broad provider framework, caching tables, static-egress proxy, long-running jobs.

## 2. Codebase Exploration

### Verified Evidence

- Root `AGENTS.md`, canonical architecture/Supabase/secrets docs, ADR-0007, `.ai` workflow/task rules, push/PR templates read fresh.
- No applicable nested `AGENTS.md` exists under `supabase/` or `supabase/functions/`.
- Live Supabase project `tio-world` (`oykupyiitspujzpwwvuj`) is `ACTIVE_HEALTHY` in `ap-south-1`.
- Live Edge Function inventory still contains only `google-login-admission`; no nutrition parser is deployed.
- Project supports both a legacy anon key and a current publishable key. Secret values are never recorded here.
- Current Supabase docs (2026-09-18) recommend authenticated-user Edge Functions use platform JWT verification plus `@supabase/server` user auth context. This supersedes the older prompt example that treated `verify_jwt=false` as the likely default.
- Existing `google-login-admission` supplies the repo pattern for `Deno.serve`, `Deno.env.get`, and sanitized errors.
- Current Tio `NutritionSnapshot` contract uses schema version 1 in runtime/tests and stores only explicitly known nutrients.
- Canonical current nutrient IDs: `energy`, `protein`, `carbohydrate`, `fat`, `fiber`, `saturated_fat`, `trans_fat`, `added_sugar`, `sodium`, `calcium`, `phosphorus`, `vitamin_d`.
- Repository convention repeatedly names Gemini as the server-side AI provider direction; no OpenAI implementation/convention is present.
- Current official provider docs rechecked: FatSecret OAuth2 client-credentials/basic flow and latest food detail API; Edamam Food Database v2 parser/nutrients; Gemini structured-output support and current stable Flash models.

## 3. Clarification

| Decision | Status | Rationale | Owner |
|---|---|---|---|
| Implementation may proceed before Premier/India/storage rights | Made | Owner explicitly separated implementation gate from production/UI activation gate. | Owner |
| LLM interpreter | Made: Gemini | Existing repo convention repeatedly names Gemini; keep adapter local, not TNYX-33. | Current implementation within approved scope |
| Factual provider order | Made: FatSecret → Edamam | Owner explicitly authorized both; exactly one provider supplies each successful item's nutrition. | Owner |
| Cross-provider nutrient blending | Forbidden | A successful item must have one factual source basis. | Owner |
| Auth strategy | Made: platform `verify_jwt=true` + function-side `@supabase/server` user auth | Current Supabase docs support current signing keys and authenticated-user calls; no home-grown JWT. | Current docs + approved auth boundary |
| Provider provenance persistence | Deferred | Not required for this slice; no domain/database fields added. | Owner |
| Deployment | Not yet | Requires source validation, rotated exposed FatSecret secret, runtime secret presence, and safe provider connectivity. | Owner prompt |

## 4. Architecture Design

### Chosen Approach

Keep small internal adapters inside the function directory:

```text
index.ts
  → auth boundary
  → GeminiMealInterpreter
  → resolveCandidate(primary FatSecret, secondary Edamam)
  → provider-neutral response

Providers return one InternalResolvedFood each.
Provider DTOs/IDs never cross contract.ts.
```

### Failure Semantics

- `unrecognized`: no meaningful meal interpretation.
- `incomplete`: meaning exists but a save-ready factual item cannot be safely resolved.
- `unavailable`: both usable provider paths are unavailable or protected runtime failed.
- invalid request: HTTP 400 sanitized error.
- unauthenticated: HTTP 401, normally rejected by platform before handler.

## 5. Implementation Plan

- [x] Provider-neutral request/response contract foundation.
- [ ] Reconcile contract with exact Tio nutrient schema.
- [ ] Add internal candidate/resolved-food contracts and normalization helpers.
- [ ] Add Gemini structured interpreter with bounded timeout and strict validation.
- [ ] Add FatSecret OAuth2/search/detail resolver with deterministic match/serving rules.
- [ ] Add Edamam parser/nutrients fallback with deterministic match/serving rules.
- [ ] Add primary/secondary orchestration without nutrient blending.
- [ ] Add authenticated HTTP handler and `supabase/config.toml` function config.
- [ ] Add focused unit tests with provider HTTP test doubles.
- [ ] Run validation and scope audit.
- [ ] Create focused draft PR; do not merge.

## 6. Quality Review

### Validation Run

```text
Not run yet for the current implementation tree.
```

### Review Findings and Resolution

| ID | Severity | Status | Finding | Observed at SHA | Evidence or follow-up |
|---|---|---|---|---|---|
| TNYX-224-G1 | Blocker | Resolved | Provider selection was previously unresolved. | `7c7df7b3` | Owner approved FatSecret Free/Basic development and Edamam fallback; Linear records both decisions. |
| TNYX-224-G2 | Deferred | Deferred | Durable provider provenance has no current domain/DB home. | `7c7df7b3` | Explicitly out of scope; no persistence field added. |
| TNYX-224-G3 | High | Open | Live FatSecret call must not use the previously exposed secret and current account IP restrictions may block Edge Function egress. | live/provider state | Rotate secret before first deployed call; if IP restriction blocks, record live validation BLOCKED without adding proxy infrastructure. |

## 7. Final Handoff

### Changed Files

In progress; exact list will be refreshed after validation.

### Actual Behavior

No product-visible behavior yet. TNYX-225 and TNYX-226 remain unchanged.

### Known Limitations

- FatSecret Free/Basic is a development stepping stone; India/Premier remains a production gate.
- Durable provider nutrient-storage permission remains a production activation gate.
- Live provider validation is not allowed until the exposed FatSecret credential is rotated and runtime secret presence/connectivity is verified.

### Final Status

`PARTIAL`
