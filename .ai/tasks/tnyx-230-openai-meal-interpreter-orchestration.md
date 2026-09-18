# TNYX-230 — N5D-7b — OpenAI meal interpreter + Gemini/OpenAI orchestration

**Status:** In progress
**Primary owner:** Nutrition (Supabase Edge Function `nutrition-meal-text-parse`)
**Affected platforms:** Supabase Edge Function source only; no Flutter, database, or deployment change

## Owner Approval and Scope Boundary

**Trigger:** New independently scoped server-source slice (TNYX-230)
**Approval status:** Approved
**Approval evidence:** Owner selected **Option 3** (configuration-selected primary interpreter, other provider as fallback) on 2026-09-18; recorded in Linear TNYX-230 "Owner-locked interpreter policy — 2026-09-18" and the owner implementation handoff for this slice.
**Approved product/UI/data-shape boundaries:** Add an OpenAI-backed `MealInterpreter` behind the existing provider-neutral seam; add a config-selected primary/fallback interpreter orchestrator; keep the existing `InterpretationResult` contract, request deadline, abort propagation, and FatSecret → Edamam factual resolution unchanged.
**Explicit non-changes:** Supabase deployment; secret creation/rotation/removal; Flutter/UI/Meal Editor; DB schema/RLS/RPC/migrations; `services/api`; broad TNYX-33 AI provider abstraction; FatSecret/Edamam resolver redesign; TNYX-229 deployment/live validation; TNYX-226 activation; MealLog persistence; parallel dual-provider calls.

## Active Handoff

**Planning owner:** Owner (Linear TNYX-230)
**Implementation owner:** Local Claude Code agent (this session)
**Review owner:** Pending draft PR review
**Implementation ownership state:** Active
**Ownership transition:** Not applicable
**Repository state last verified:** 2026-09-18
**Branch:** `tnyx/tnyx-230-n5d-7b-add-openai-meal-interpreter-geminiopenai`
**HEAD SHA:** Base `0111e23eea150bc24d6634a07887c1ef9fe43974` (clean `main` = `origin/main` at branch creation)
**Observed working-tree state:** Clean at start
**Observed uncommitted/dirty files:** None at start
**PR / tracker:** Linear TNYX-230 = In Progress; TNYX-229 = In Progress, blocked by TNYX-230; TNYX-226 = Backlog; TNYX-33 = related future platform work. Draft PR pending.
**Current implementation state:** See §5.
**Relevant execution surface:** `supabase/functions/nutrition-meal-text-parse/*`, this brief
**Validation completed at SHA:** See §6
**Validation remaining:** See §6
**Current blocker:** None for source. Live deployment remains TNYX-229.
**Open review finding IDs:** TNYX-230-R1, TNYX-230-R2, TNYX-230-R3 (see §6); PR #282 findings TNYX-230-G1/G2 resolved
**Next exact action:** Draft PR review. Do not merge or deploy.

## 1. Discovery

### User Outcome

The protected meal-text parser can use either Gemini or OpenAI as the language interpreter, selected by server-side configuration, with the other provider as a failure fallback — before TNYX-229 deploys the function.

### Success Criteria

- `MEAL_INTERPRETER_PRIMARY` selects the primary interpreter: missing/empty or `gemini` → Gemini primary + OpenAI fallback; `openai` → OpenAI primary + Gemini fallback; any other non-empty value → configuration error (sanitized `unavailable`, no provider called, no silent default).
- `recognized` and `unrecognized` from the primary return immediately; fallback runs only after primary `unavailable` and only while the parent `AbortSignal` is active.
- No parallel provider calls.
- OpenAI uses the Responses API with strict Structured Outputs (JSON Schema) and `store: false` (disables Responses application-state storage only; not a zero-retention guarantee).
- Both interpreters normalize to the same `InterpretationResult` via one shared parser, schema limits, and one shared instruction set.
- AI interpreters never produce calories/macros/micronutrients/gram or serving conversions; factual nutrition stays FatSecret → Edamam.

### Scope

OpenAI adapter, shared interpretation schema/prompt/parser helper, interpreter orchestrator, composition extraction (`composition.ts`) so `index.ts` wiring is testable, focused tests.

### Non-Goals

See Explicit non-changes above.

## 2. Codebase Exploration

### Verified Evidence

- Source/config inspected: `index.ts`, `types.ts`, `gemini_client.ts`, `gemini_client_test.ts`, `handler.ts`, `async_control.ts`, `resolver.ts`, `providers_test.ts`, `handler_test.ts`, `supabase/config.toml` (`[functions.nutrition-meal-text-parse] verify_jwt = true`).
- Existing pattern to follow: `GeminiMealInterpreter` (direct `fetch` via `fetchWithTimeout`, 8s per-provider timeout, parent-signal propagation, strict JSON parse → `unavailable` on any malformed output); `resolveWithFallback` (primary/secondary short-circuit + abort checks).
- Tests or validation already present: Deno `node:test` suites; baseline on base SHA: `deno check index.ts` PASS, `deno test --allow-read=<function dir>` 39 passed / 0 failed (Deno 2.9.7, machine-local toolchain, same tooling as TNYX-224 PR #280).
- Live state (read-only, prior TNYX-229 readiness pass): `nutrition-meal-text-parse` NOT DEPLOYED.

### OpenAI current-doc evidence (fetched 2026-09-18)

- Structured Outputs guide (`developers.openai.com/api/docs/guides/structured-outputs`): Responses API uses `text.format = { type: "json_schema", name, schema, strict: true }`; strict mode requires `additionalProperties: false`, every property in `required`, nullable via type arrays; `maxItems` supported. Output is `output[].content[]` with `type: "output_text"` or `"refusal"`.
- Data controls / conversation-state docs: Responses are stored by default (`store` defaults to true); `store: false` disables Responses application-state storage → set explicitly. It does **not** by itself mean zero provider-side retention: standard OpenAI abuse-monitoring logs may retain prompts/responses for up to 30 days unless the organization/project has approved Zero Data Retention or Modified Abuse Monitoring (separate account-level controls).
- Models catalog (`developers.openai.com/api/docs/models`) lists `gpt-5.6-luna` as the cost-optimized model ($0.20 / $1.20 per MTok). Model page (`/api/docs/models/gpt-5.6-luna`): supports Structured Outputs and `v1/responses`; reasoning effort supports `none, low, medium (default), high, xhigh, max`.

## 3. Clarification

| Decision | Status | Rationale | Owner |
|---|---|---|---|
| Primary/fallback policy | Made (Option 3) | Owner-locked 2026-09-18. | Owner |
| Selector name | `MEAL_INTERPRETER_PRIMARY` | Single bounded server-side selector; exact values `gemini` / `openai` after trimming; case-sensitive to avoid silent acceptance of unexpected spellings. | Implementation |
| Invalid selector behavior | Sanitized `unavailable`, no provider call | "Fail safely" without crashing boot into an unsanitized platform error and without silently choosing a provider. | Implementation |
| OpenAI default model | `gpt-5.6-luna` | Current cost-optimized catalog model that supports Structured Outputs + Responses API; short extraction task. `OPENAI_MODEL` overrides. | Implementation |
| OpenAI reasoning effort | `none`, only for the code-default model | Keeps latency inside the 8s per-provider budget (default would be `medium`). Not sent for an `OPENAI_MODEL` override because other models may reject/vary on the parameter. | Implementation |
| OpenAI refusal / non-`completed` status | `unavailable` | Not a semantic "no food" answer; lets the fallback provider try. | Implementation |
| Dependency | None added | Direct `fetch`, matching the Gemini adapter. | Implementation |

## 4. Architecture Design

### Chosen Approach

```text
index.ts (auth: createSupabaseContext auth:"user")
  → composition.ts createMealTextParseDependencies(readEnv, authenticate)
      → selectMealInterpreter(MEAL_INTERPRETER_PRIMARY, { gemini, openai })
          → FallbackMealInterpreter(primary, fallback)   // sequential, never parallel
      → FatSecretResolver (primary factual)
      → EdamamResolver when both EDAMAM_APP_ID/KEY present (factual fallback)
  → handler.ts (unchanged)
```

`interpretation_schema.ts` holds the shared item limit, instructions, candidate schema, and strict result parser used by both provider adapters.

### Ownership and Data Flow

Provider DTOs, prompts, API keys, and raw responses stay inside the Edge Function. The client sees only the existing provider-neutral `ParseResponse`.

### Alternative Rejected

- Parallel/racing both providers: rejected by owner policy (cost, no benefit for this slice).
- Throwing at boot on invalid selector: rejected; produces unsanitized platform errors instead of the Tio `unavailable` contract.
- Adding the `openai` npm SDK: rejected; direct `fetch` keeps parity with Gemini and avoids a dependency.

### Failure and Accessibility States

All provider failures, malformed output, refusals, timeouts, and misconfiguration normalize to `unavailable`; parent abort stops the chain. No UI in scope.

## 5. Implementation Plan

- [x] Shared schema/instructions/parser helper (`interpretation_schema.ts`); Gemini behavior preserved.
- [x] `OpenAIMealInterpreter` (`openai_client.ts`).
- [x] `FallbackMealInterpreter` + `selectMealInterpreter` (`interpreter_orchestrator.ts`).
- [x] Composition extracted to `composition.ts`; `index.ts` keeps auth and reads env.
- [x] Focused tests (OpenAI adapter, orchestrator, composition).
- [x] Deno check + tests + `git diff --check`.
- [ ] Draft PR review.

## 6. Quality Review

### Validation Run

Tooling: Deno 2.9.7 (machine-local toolchain, same as TNYX-224).

```text
deno check supabase/functions/nutrition-meal-text-parse/index.ts          PASS
deno check supabase/functions/nutrition-meal-text-parse/*.ts              PASS (all source + tests)
deno test --allow-read=supabase/functions/nutrition-meal-text-parse \
          supabase/functions/nutrition-meal-text-parse                    PASS — 72 passed / 0 failed
  (baseline on 0111e23e before changes: 39 passed / 0 failed)
git diff --check                                                          PASS
Changed paths: only supabase/functions/nutrition-meal-text-parse/* + this brief
Secret-pattern / console scan of changed files: none found
No network or env permission granted to tests.
```

Exact final PR-head validation is recorded in the draft PR body (avoids a self-referential SHA loop in this brief).

### Review Findings and Resolution

| ID | Severity | Status | Finding | Observed at SHA | Evidence or follow-up |
|---|---|---|---|---|---|
| TNYX-230-R1 | Medium | Open | `gpt-5.6-luna` default + `reasoning.effort: "none"` are not live-validated; wrong assumption would degrade to `unavailable` → Gemini fallback, never wrong nutrition. | branch | Validate during TNYX-229 live validation. |
| TNYX-230-R2 | Low | Open | Worst-case interpreter latency is primary timeout + fallback timeout (8s + 8s), still within the 45s request deadline. | branch | Accepted. |
| TNYX-230-R3 | Medium | Open | `store: false` is not zero retention; OpenAI abuse-monitoring logs may retain meal text up to 30 days absent approved ZDR / Modified Abuse Monitoring. | branch | TNYX-229 production privacy gate: confirm OpenAI account/project data-control status before live use. |
| TNYX-230-G1 | P2 | Resolved | `openai_client.ts` comment claimed meal text is never retained provider-side. | 9b54488c | Comment now scoped to Responses application-state storage; `store: false` and request behavior unchanged; retention carried as R3 / TNYX-229 gate. |
| TNYX-230-G2 | P3 | Resolved | Brief contained machine-specific absolute toolchain paths. | 9b54488c | Replaced with portable "machine-local toolchain" wording. |

## 7. Final Handoff

### Changed Files

```text
.ai/tasks/tnyx-230-openai-meal-interpreter-orchestration.md
supabase/functions/nutrition-meal-text-parse/interpretation_schema.ts
supabase/functions/nutrition-meal-text-parse/gemini_client.ts
supabase/functions/nutrition-meal-text-parse/openai_client.ts
supabase/functions/nutrition-meal-text-parse/openai_client_test.ts
supabase/functions/nutrition-meal-text-parse/interpreter_orchestrator.ts
supabase/functions/nutrition-meal-text-parse/interpreter_orchestrator_test.ts
supabase/functions/nutrition-meal-text-parse/composition.ts
supabase/functions/nutrition-meal-text-parse/composition_test.ts
supabase/functions/nutrition-meal-text-parse/handler_test.ts
supabase/functions/nutrition-meal-text-parse/index.ts
```

### Actual Behavior

Source only. Function remains NOT DEPLOYED. TNYX-229 remains the deployment/live-validation gate.

### Known Limitations

TNYX-230-R1/R2/R3 above. OpenAI provider-side retention (ZDR / Modified Abuse Monitoring status), FatSecret rotation, provider entitlement/India coverage, and durable nutrition-storage permission remain TNYX-229/production gates.

### Final Status

`REVIEW`
