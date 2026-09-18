# TNYX-224 — N5D-6 — Supabase Edge Function protected meal-text parser

**Status:** Needs decision
**Primary owner:** Nutrition (Supabase Edge Function boundary)
**Affected platforms:** Supabase (`supabase/functions`); no Flutter change in this slice

## Owner Approval and Scope Boundary

**Trigger:** New independently scoped product task/feature slice (server implementation) — approval already exists at the architecture level (TNYX-221 audit + TNYX-207 owner clarifications), but the concrete nutrition provider itself is an unresolved decision, not merely an implementation detail.
**Approval status:** Not required for the *boundary* (Supabase Edge Function is owner-approved via TNYX-221/TNYX-207); `AWAITING OWNER DECISION` for the *provider*.
**Approval evidence:** TNYX-221 "Re-audit correction — 2026-09-18" (Supabase Edge Function chosen over waiting for `services/api`); TNYX-207 "Owner clarification — real API-backed activation only — 2026-09-18" (no fake/mock/placeholder parser).
**Approved product/UI/data-shape boundaries:** One Nutrition-owned Supabase Edge Function; no schema/RLS/RPC change; no Flutter UI change; no `services/api`.
**Explicit non-changes:** `AddFoodSheet`, Meal Editor UI, TNYX-225 (Flutter remote adapter), TNYX-226 (Add Food activation) — all out of scope for this slice.

## Active Handoff

**Planning owner:** Claude (this audit)
**Implementation owner:** Not started
**Review owner:** Not applicable
**Implementation ownership state:** Not started
**Ownership transition:** Not applicable
**Repository state last verified:** 2026-09-18
**Branch:** `main`
**HEAD SHA:** `7c7df7b30256091301d93325c031440f6b44d526`
**Observed working-tree state:** Clean (`git status --short --branch` → `## main...origin/main`, no output)
**Observed uncommitted/dirty files:** None
**PR / tracker:** None opened; Linear TNYX-224 remains `Todo`
**Current implementation state:** No source changed. Audit-only.
**Relevant execution surface:** `supabase/functions/*` (future), `apps/features/nutrition` (unchanged)
**Validation completed at SHA:** Not applicable — no code changed
**Validation remaining:** All (blocked on decision below)
**Current blocker:** Provider selection gate unresolved (see below)
**Open review finding IDs:** None
**Next exact action:** Owner selects a concrete nutrition-truth provider (or approves one of the options below); implementation resumes only after that decision.

## 1. Discovery

### User Outcome

Activate the real production `What did you eat?` meal-logging flow by giving `MealTextParseRepository` a real, protected server implementation: Flutter → Supabase Edge Function → real provider/API → Tio-owned normalized response → `MealLoggingDraft`.

### Success Criteria

- One authenticated, protected Nutrition Edge Function exists.
- Every `success` outcome is backed by a real, non-fabricated nutrition source (see gate below) and is Meal-Editor-save-ready.
- `unrecognized` / `incomplete` / `unavailable` are the only non-success outcomes; no fake success.
- No provider secret, DTO, or raw payload reaches Flutter.

### Scope

Server-side Supabase Edge Function only (per TNYX-224 Linear description). See non-goals.

### Non-Goals

`AddFoodSheet`/UI activation (TNYX-226), Flutter remote repository adapter (TNYX-225), `services/api`, schema/RLS/RPC changes, voice/photo/search/saved/recent/barcode, background jobs, broad AI-provider platform abstraction. TNYX-227 is Canceled and must not be implemented.

## 2. Codebase Exploration

### Verified Evidence

- `git log --oneline -15` / `git status --short --branch`: `main` clean at `7c7df7b3`; PRs #268, #270, #271, #273, #275, #276, #277 merged in sequence for the N5D/N20A foundation.
- `AGENTS.md`, `README.md`, `docs/ARCHITECTURE.md`, `docs/SUPABASE_STRATEGY.md`, `docs/SUPABASE_SERVER_ACCESS.md`, `docs/SECRETS_AND_ENVIRONMENTS.md`, `docs/DATA_PRIVACY_GOVERNANCE.md`, ADR-0007, `.ai/README.md`, `.ai/workflow.md`, `.ai/FEATURE_DEVELOPMENT.md`, `.ai/tasks/README.md`/`TEMPLATE.md`, `docs/PUSH_TEMPLATE.md`, `.github/PULL_REQUEST_TEMPLATE.md` — all read fresh this session.
- **Stale-doc note:** `docs/SUPABASE_STRATEGY.md` still describes a `backend/` workspace (`backend/api`, `backend/ai-coach`, `backend/jobs`) and says "choose the exact runtime for Gemini later." This predates ADR-0007, which supersedes it: canonical future path is `services/api` (Node.js + TypeScript + Fastify), not `backend/`. `docs/ARCHITECTURE.md` and ADR-0007 are the current truth; `SUPABASE_STRATEGY.md`'s Edge-Function-for-small-protected-AI-request guidance is still directionally valid and is exactly what TNYX-221 relied on, but its repository-shape section is stale and should be corrected in a separate docs slice, not silently followed for folder naming.
- Linear reconciled: TNYX-207 (Backlog, parent), TNYX-220 (Done, PR #277), TNYX-221 (Done — audit; chose Supabase Edge Function over waiting for `services/api`), TNYX-224 (Todo — this task), TNYX-225 (Backlog, blocked by TNYX-224), TNYX-226 (Backlog, blocked by TNYX-225), TNYX-227 (**Canceled** — must not be implemented), TNYX-26/27/33 (Backlog — `services/api` scaffold / JWT middleware / AI provider abstraction; related future work, not blockers for TNYX-224 per TNYX-221's re-audit).
- GitHub reconciled: issue #269 (N5D UI/flow clarification, open, planning-only), PR #276 (TNYX-219 Meal Editor Log Meal activation, merged), PR #277 (TNYX-220 parser contract/controller foundation, merged).
- Runtime source inspected:
  - `apps/features/nutrition/lib/src/domain/repositories/meal_text_parse_repository.dart` — provider-neutral `MealTextParseRepository.parseMealText(String)` returning `MealLoggingDraft`, with `MealTextParseFailure(reason)` for `unrecognized`/`incomplete`/`unavailable`. No implementation exists yet (contract only).
  - `apps/features/nutrition/lib/src/meal_logging/meal_text_parse_controller.dart` — idle/processing/failed/succeeded controller; duplicate-submit suppression; retry preserves text; enforces `captureSource == MealLogCaptureSource.text` on success.
  - `apps/shared/lib/src/nutrition/meal_logging_draft.dart` + `meal_logging_draft_item.dart` — draft requires ≥1 item; each item has `displayName`, optional `quantity` (>0 if present), optional `servingUnit`, optional `consumedNutritionSnapshot`. **No provenance fields** (no `providerKey`, `sourceFoodId`, `sourceServingId`).
  - `apps/shared/lib/src/nutrition/nutrition_snapshot.dart` — provider-independent nutrient map keyed by canonical `NutrientId`; explicitly notes "source and capture provenance belongs to the entity that owns this value object, not to the snapshot itself."
  - `apps/shared/lib/src/nutrition/meal_log_item_snapshot.dart` (durable child row) — same shape as the draft item plus `id`/`mealLogEntryId`; comment explicitly says provider/catalog IDs "must never replace `nutritionSnapshot`" but **no field exists to store them**.
  - `apps/features/nutrition/lib/src/domain/repositories/detailed_meal_log_create_repository.dart` — `DetailedMealLogCreateItem`/`DetailedMealLogCreate` confirm the exact save-readiness contract: `displayName`, `quantity>0`, `servingUnit`, `nutritionSnapshot` are all required for a real create; **no provenance fields** here either.
  - `apps/features/nutrition/lib/src/meal_logging/presentation/widgets/add_food_sheet.dart` — confirms `What did you eat?` is currently rendered **disabled/inert** (`Semantics(enabled: false)`, `ExcludeSemantics`, copy says "Not available yet"). Matches expected current state; this task must not change it.
  - `supabase/functions/google-login-admission/index.ts` + `supabase/config.toml` — only existing Edge Function; shows the repo's pattern for `Deno.serve`, sanitized error responses (`{ error: 'admission_unavailable' }`, no internals leaked), and `[functions.<name>]` config block. No Nutrition/parser function exists yet, confirming the expected current state.
- Existing pattern to follow: `google-login-admission`'s sanitized-error-response and `Deno.env.get(...)` secret-access pattern is the closest current template for a new protected function.
- Tests or validation already present: none for a parser Edge Function (none exists). `apps/features/nutrition/test/meal_logging/meal_diary_add_food_flow_test.dart` covers the current disabled Add Food UI only.

## 3. Clarification

### Decisions Required or Made

| Decision | Status | Rationale | Owner |
|---|---|---|---|
| Protected execution boundary: Supabase Edge Function vs `services/api` | **Made** | TNYX-221 re-audit (2026-09-18): Edge Functions are GA, support deployment-managed secrets and outbound calls; this is one bounded synchronous request, not orchestration/queues; `services/api` prerequisites (TNYX-26/27/33) are not blockers for this first path. | Owner (recorded in Linear) |
| Concrete nutrition/food-data provider (FatSecret, Edamam, Gemini, USDA, or another) | **Not made** | No Linear issue, doc, or ADR names a provider for N5D. TNYX-224's own description says "the selected third-party AI/food parsing provider" as if one exists, but no artifact selects it. The only place FatSecret/Edamam appear is TNYX-92 (`N18C — AI planner, provider resolution & nutrition validation pipeline`), which is Backlog, unstarted, and scoped to the unrelated N18 Diet Plan feature (TNYX-89) — it illustrates a `FoodDataProvider` interface shape, not an approved decision binding TNYX-224. TNYX-33 (`B4.1 — Define AI provider abstraction`) is also Backlog. | **Owner — blocking** |
| Whether provider provenance (`providerKey`/`sourceFoodId`/`sourceServingId`) must become part of the draft/durable shape | **Not made** | Current `MealLoggingDraftItem`, `MealLogItemSnapshot`, and `DetailedMealLogCreateItem` have zero fields for this. If the selected provider gives stable food/serving IDs that the product wants to keep (e.g. for repeat-logging or correction quality), that is a **separate bounded prerequisite** requiring its own Owner Approval under the Supabase table/column-shape gate — it must not be folded into TNYX-224. | Owner — separate follow-up, not blocking TNYX-224's Edge Function shape itself |

## 4. Architecture Design

### Chosen Approach

Not implemented. Blocked — see Provider Selection Gate below.

### Ownership and Data Flow (once unblocked)

```text
Flutter (authenticated) -> MealTextParseRepository (remote, TNYX-225, later)
  -> Supabase Edge Function (this task)
    -> validate Supabase auth session (never trust body user_id)
    -> real provider/API call (server-only secret)
    -> provider response validation
    -> Tio-owned normalization + Meal-Editor-readiness check
  -> success | unrecognized | incomplete | unavailable
```

### Alternative Rejected

Waiting for `services/api` (TNYX-26/27/33) before any live parser — rejected by TNYX-221's 2026-09-18 re-audit because Edge Functions already satisfy the auth/secret/bounded-request requirements for this one synchronous use case.

### Failure and Accessibility States

`unrecognized` / `incomplete` / `unavailable` per `MealTextParseFailureReason`; no UI in this slice.

## 5. Implementation Plan

- [ ] **BLOCKED** — do not start until the Provider Selection Gate is resolved by the owner.

## 6. Quality Review

### Validation Run

```text
Not run yet. No source changed in this audit.
```

### Review Findings and Resolution

| ID | Severity | Status | Finding | Observed at SHA | Evidence or follow-up |
|---|---|---|---|---|---|
| TNYX-224-G1 | Blocker | Open | No concrete nutrition/food-data provider is selected for N5D; TNYX-224's description presupposes one ("the selected third-party AI/food parsing provider") that does not exist in any tracker/doc. | `7c7df7b3` | See Clarification table; owner decision required before implementation. |
| TNYX-224-G2 | Deferred | Open | Provider provenance (`providerKey`/`sourceFoodId`/`sourceServingId`) has no home in current domain/DB shape. Not a TNYX-224 blocker by itself, but must be raised as its own approval-gated prerequisite if the selected provider's stable IDs are meant to survive past the draft. | `7c7df7b3` | Raise as a separate task once provider is selected, only if product requires persisting provenance. |

## Provider Research Update — 2026-09-18

Fresh evidence-based provider audit performed (official docs/terms for FatSecret Platform API, Edamam Food Database/Nutrition Analysis API, USDA FoodData Central, IFCT 2017/NIN). Full comparison delivered to the owner in chat and posted to TNYX-224 as a Linear comment. Key new evidence not previously known:

- **Durable-storage conflict:** FatSecret's public "storable data" policy (`platform.fatsecret.com/docs/guides/storable-data`) permits only IDs (`food_id`, `serving_id`, etc.) to be cached indefinitely — all nutrient values must be deleted/re-requested within 24 hours, no documented edition exception. Edamam permits caching only 4 of Tio's 12 canonical `NutrientId` values (protein, fat, net carbs, calories) even on paid plans, and explicitly forbids reusing cached data to rebuild a copy of its dataset. Both conflict with TNYX-113's already-locked frozen/durable `NutritionSnapshot` rule unless a written commercial exception is obtained.
- **FatSecret India access:** Free tiers (Basic, Premier Free) are US-only datasets; India-market data requires the paid Premier tier, and Premier's own documentation does not explicitly list India among its countries — needs direct confirmation.
- **IFCT/NIN:** Canonical data is published by NIN (ICMR) directly; the community GitHub redistribution is AGPL-3.0. Whether that license reaches the underlying data values if ingested into Tio's own schema is unclear from public sources — `needs legal/provider confirmation`, not assumed either way.
- **Provenance recommendation:** Option C (valuable but safely deferrable) — consistent with the repo's own repeated decision across TNYX-216/217/218. No separate prerequisite issue proposed.

This does not change TNYX-224's scope, sequence, or non-goals. Still `BLOCKED` pending the owner decisions listed in the chat report (provider + two FatSecret confirmations, or an explicit choice to start with the internal-catalog path instead).

## 7. Final Handoff

### Changed Files

- `.ai/tasks/tnyx-224-supabase-edge-function-protected-meal-text-parser.md` (this brief, created)
- Linear TNYX-224 (audit comment added; status left at `Todo`)

No Flutter, Supabase function, migration, or secret was created or changed.

### Actual Behavior

Unchanged. `AddFoodSheet`'s `What did you eat?` remains disabled/inert; no Edge Function exists in `supabase/functions/`.

### Known Limitations

Provider selection gate open; provider provenance decision open. Both must resolve before implementation.

### Final Status

`BLOCKED`
