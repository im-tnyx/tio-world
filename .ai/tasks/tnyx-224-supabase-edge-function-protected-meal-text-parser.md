# TNYX-224 — N5D-6 — Supabase Edge Function protected meal-text parser

**Status:** In progress
**Primary owner:** Nutrition (Supabase Edge Function boundary)
**Affected platforms:** Supabase Edge Function only; no Flutter or database-shape change

## Owner Approval and Scope Boundary

**Trigger:** Existing approved product/server slice; this is continuation and pre-PR cleanup, not a new slice.
**Approval status:** Approved
**Approval evidence:** Owner decisions on 2026-09-18 opened TNYX-224 implementation using FatSecret Free/Basic for development and Edamam as factual fallback. Latest owner handoff explicitly keeps Gemini as the only interpreter for this bounded PR and defers OpenAI evaluation.
**Approved boundaries:** Authenticated Nutrition-owned Supabase Edge Function; Gemini language interpretation only; FatSecret primary factual resolver; Edamam factual fallback; exactly one factual provider per successful item; provider-neutral Tio response; no persistence.
**Explicit non-changes:** TNYX-225, TNYX-226, Flutter/UI, database tables/columns, migrations, RLS, RPC, `services/api`, OpenAI interpreter orchestration, proxy/static-egress infrastructure, live deployment.

## Active Handoff

**Planning owner:** Existing TNYX-224 plan
**Implementation owner:** ChatGPT (current continuation)
**Review owner:** Pending draft PR review
**Implementation ownership state:** Complete for source/pre-PR implementation
**Ownership transition:** Interrupted implementation → current implementation owner
**Repository state last verified:** 2026-09-18
**Branch:** `tnyx/tnyx-224-n5d-6-supabase-edge-function-protected-meal-text-parser`
**Base main SHA:** `7c7df7b30256091301d93325c031440f6b44d526`
**Final implementation/test SHA:** `9e7b86069e49e5b45db9332ea65b06a547488d1c`
**Observed repository state at implementation/test SHA:** 18 commits ahead / 0 behind `main`; expected TNYX-224 scope only.
**Observed uncommitted/dirty files:** Not observable through GitHub API; user-local unrelated work was not touched.
**PR / tracker:** No PR at this checkpoint; Linear TNYX-224 = `In Progress`; TNYX-225/TNYX-226 unchanged.
**Current implementation state:** Source complete and focused tests committed. Known Gemini malformed-JSON typo and nutrition schema-version typo are fixed.
**Relevant execution surface:** `.ai/tasks/tnyx-224-supabase-edge-function-protected-meal-text-parser.md`, `supabase/config.toml`, `supabase/functions/nutrition-meal-text-parse/*`
**Validation completed at implementation/test SHA:** TypeScript PASS; focused tests 28/28 PASS; exact source/test blobs were matched to GitHub blob SHAs before validation.
**Validation protocol note:** This handoff-only brief commit moves branch HEAD after the implementation/test SHA. Exact PR-head TypeScript/tests/scope/diff validation is rerun after this file is pushed and recorded in the draft PR and Linear comment rather than creating a self-referential SHA loop in this brief.
**Current blocker:** None for source/PR readiness. Live provider validation remains intentionally not run.
**Open review finding IDs:** TNYX-224-G2 (Deferred provenance); TNYX-224-G3 (production/live-provider gate)
**Next exact action:** Push this reconciled brief, rerun exact-head validation, create draft PR, fresh-read PR, sync Linear. Do not merge.

## 1. Discovery

### User Outcome

Provide the protected parser source behind the existing provider-neutral Nutrition contract:

```text
authenticated Supabase user
→ nutrition-meal-text-parse
→ Gemini structured interpretation
→ FatSecret factual resolver
→ Edamam factual fallback
→ exactly one factual provider per successful item
→ Tio-owned provider-neutral response
→ later TNYX-225 Flutter adapter
```

### Success Criteria

- Authenticated Supabase user required.
- Request is only `{ schemaVersion: 1, mealText }`.
- Gemini extracts meal/item/quantity/unit intent and never supplies canonical nutrition truth.
- FatSecret is primary factual nutrition resolver.
- Edamam is secondary factual fallback.
- A successful item is sourced wholly from one factual provider; nutrients are never blended.
- Missing/ambiguous facts return `incomplete`; provider/runtime failure returns sanitized `unavailable`.
- Tio `NutritionSnapshot` schema version 1 and canonical nutrient IDs are preserved.
- Unknown nutrients stay absent; no unknown-to-zero conversion.
- No raw meal text/provider payload/provider IDs are persisted or logged.
- No Flutter, database schema, RLS, RPC, migration, or `services/api` change.

### Non-Goals

OpenAI interpreter fallback, TNYX-225/TNYX-226, Add Food activation, voice/photo/search/barcode, provider provenance persistence, caching tables, static-egress proxy, production licensing solution, live deployment.

## 2. Codebase Exploration

### Verified Evidence

- Root `AGENTS.md`, `.ai` workflow/task rules, canonical architecture/Supabase docs, ADR-0007, `docs/PUSH_TEMPLATE.md`, and PR template were reconciled before continuation.
- No nested `AGENTS.md` applies under `supabase/functions`.
- Live Supabase project `tio-world` (`oykupyiitspujzpwwvuj`) is healthy in `ap-south-1`.
- Live Edge Function inventory contains only `google-login-admission`; `nutrition-meal-text-parse` is not deployed.
- Current Supabase docs: signed-in user calls keep `verify_jwt = true` and use `auth: "user"` in `@supabase/server`; `createSupabaseContext` is appropriate for custom sanitized 401 handling.
- `@supabase/server@1.7.0` remains pinned; GitHub latest release on 2026-09-18 is `server-v1.7.0`, so no dependency change is required.
- Provider secrets remain environment-only and are not printed, persisted, or committed.
- OpenAI is explicitly deferred from this bounded PR.

## 3. Clarification

| Decision | Status | Rationale |
|---|---|---|
| Interpreter | Gemini only | Establish one measurable baseline; OpenAI requires a later approved benchmark/scope. |
| Factual provider order | FatSecret → Edamam | Owner-approved factual resolver order. |
| Cross-provider nutrient blending | Forbidden | One successful item must have exactly one factual source basis. |
| Auth | `verify_jwt=true` + `@supabase/server` `auth: "user"` | Current Supabase authenticated-user guidance. |
| Custom 401 | `createSupabaseContext` | Keeps sanitized Tio response while validating user auth. |
| Database access | None | Parser requires no DB read/write or privileged client. |
| Provider provenance persistence | Deferred | No schema/domain mutation in TNYX-224. |
| Deployment | Not run | Pre-PR source work only; live credential/provider gates remain. |

## 4. Architecture Design

```text
index.ts
  → Supabase user auth
  → GeminiMealInterpreter
  → resolveWithFallback(
       FatSecretResolver,
       EdamamResolver
     )
  → provider-neutral ParseResponse
```

Provider DTOs, tokens, IDs, prompts, and raw responses remain internal. Resolver orchestration returns a whole item from one provider and cannot merge nutrients.

## 5. Implementation Plan

- [x] Provider-neutral request/response contract.
- [x] Exact Tio nutrient schema v1 mapping.
- [x] Internal candidate/resolver contracts and normalization helpers.
- [x] Gemini structured interpreter with bounded timeout and strict parsing.
- [x] Malformed Gemini JSON maps to `unavailable`.
- [x] FatSecret OAuth2/search/detail resolver with deterministic matching/serving conversion.
- [x] Edamam parser/nutrients factual fallback.
- [x] Primary/secondary orchestration with no nutrient blending.
- [x] Authenticated HTTP handler and `verify_jwt=true` function config.
- [x] Focused tests committed.
- [x] Source/test snapshot TypeScript validation.
- [x] Source/test snapshot focused tests.
- [ ] Exact final PR-head validation after this handoff-only brief commit.
- [ ] Draft PR creation and post-PR verification.
- [ ] Linear exact-head/PR comment sync.

## 6. Quality Review

### Validation Run

Validated implementation/test SHA:

```text
9e7b86069e49e5b45db9332ea65b06a547488d1c
```

Results:

```text
TypeScript production type-check: PASS
Focused tests: PASS
Count: 28 passed / 0 failed
Remote blob reconciliation: PASS
@supabase/server pin: 1.7.0, current latest release verified
```

Focused coverage includes authenticated rejection, invalid request shapes, Gemini valid/malformed/failure/timeout behavior, FatSecret matching/ambiguity/missing serving/quantity scaling/failure, Edamam normalization/malformed/failure/success, primary short-circuit, fallback, both-incomplete, both-unavailable, Indian-style unresolved input, no cross-provider nutrient mixing, and no parser/provider logging.

### Review Findings and Resolution

| ID | Severity | Status | Finding | Evidence |
|---|---|---|---|---|
| TNYX-224-G1 | Blocker | Resolved | Provider selection/readiness was previously unresolved. | Owner-approved FatSecret + Edamam development path. |
| TNYX-224-G4 | High | Resolved | Gemini malformed JSON returned invalid discriminator `unavaile`. | Fixed before tests; malformed JSON test passes. |
| TNYX-224-G5 | High | Resolved | `NUTRITION_SCHMA_VERSION` typo broke canonical snapshot typing/runtime. | Corrected to `NUTRITION_SCHEMA_VERSION`; type-check and provider tests pass. |
| TNYX-224-G2 | Deferred | Deferred | Durable provider provenance has no current DB/domain home. | Explicitly out of scope; no persistence field added. |
| TNYX-224-G3 | High | Open | Live provider/deployment validation is gated by credential/runtime/provider restrictions. | No deployment/live call in this PR. |

## 7. Final Handoff

### Changed Files

```text
.ai/tasks/tnyx-224-supabase-edge-function-protected-meal-text-parser.md
supabase/config.toml
supabase/functions/nutrition-meal-text-parse/contract.ts
supabase/functions/nutrition-meal-text-parse/types.ts
supabase/functions/nutrition-meal-text-parse/matching.ts
supabase/functions/nutrition-meal-text-parse/resolver.ts
supabase/functions/nutrition-meal-text-parse/gemini_client.ts
supabase/functions/nutrition-meal-text-parse/fatsecret_client.ts
supabase/functions/nutrition-meal-text-parse/edamam_client.ts
supabase/functions/nutrition-meal-text-parse/handler.ts
supabase/functions/nutrition-meal-text-parse/index.ts
supabase/functions/nutrition-meal-text-parse/gemini_client_test.ts
supabase/functions/nutrition-meal-text-parse/resolver_test.ts
supabase/functions/nutrition-meal-text-parse/providers_test.ts
supabase/functions/nutrition-meal-text-parse/handler_test.ts
```

### Actual Behavior

Source is ready for review. The function is protected by Supabase user JWT validation and in-function `auth: "user"`, interprets language with Gemini only, resolves factual nutrition through FatSecret then Edamam, and returns provider-neutral Tio outcomes without DB persistence.

### Deployment / Live Validation

```text
Supabase deployment: NOT DEPLOYED
Live provider validation: NOT RUN
```

### Known Production Gates

- FatSecret Free/Basic remains a development limitation.
- India/Premier/provider strategy remains a later production activation gate.
- Durable/commercial nutrition-storage permission remains a production gate.
- Previously exposed FatSecret credentials must not be used for first live validation; secrets must be rotated/verified server-side without pasting values.
- TNYX-225 remains the later Flutter adapter slice.
- TNYX-226 remains the later product-visible activation slice.

### Final Status

`REVIEW`
