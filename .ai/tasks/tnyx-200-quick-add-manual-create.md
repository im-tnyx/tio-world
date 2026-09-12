# TNYX-200 — Quick Add manual MealLog create / Log Meal activation

**Status:** Ready
**Primary owner:** `apps/features/nutrition` with `apps/app` composition reuse
**Affected platforms:** Flutter Android + iOS

## Owner Approval and Scope Boundary

**Trigger:** New independently scoped product task/feature slice
**Approval status:** Approved
**Approval evidence:** On 2026-09-12, after PR #258 was merged and local `main` was post-merge synced, the owner said `go` to the proposed bounded `TNYX-115A` readiness action: create a child slice for Quick Add manual MealLog create / `Log Meal` activation, run the fresh N0 audit, and prepare the focused task brief before any source implementation.
**Approved product/UI/data-shape boundaries:** Activate the existing owner-approved Quick Add create surface only. Preserve the current field geometry and DateTime/Meal Type interactions; wire the existing `Log Meal` commit to the canonical manual MealLog repository with production-safe pending/retry behavior. No database shape change is required or approved.
**Explicit non-changes:** No edit/delete/move/card-tap flow, no note field/UI, no Fiber/micronutrient expansion, no detailed Meal Editor or item snapshots, no offline queue, no stale-edit/version strategy, no daily summary/calendar calorie rings, no Meal Plan, no schema/RLS/grant/index/function migration, no new Core visual contract, and no unrelated UI redesign.

`READY` below applies only to TNYX-200. It does not mark broad TNYX-115 complete.

## Active Handoff

**Planning owner:** ChatGPT
**Implementation owner:** None — source implementation has not started
**Review owner:** Owner / later review session
**Implementation ownership state:** Not started
**Ownership transition:** Not applicable
**Repository state last verified:** 2026-09-12
**Branch:** `tnyx/tnyx-200-n20c-1-quick-add-manual-meallog-create-log-meal-activation`
**HEAD SHA:** Branch created from `main` at `22ab43cbc613078fd98713ddfd4e0ff6a0a5c9b6`; this brief commit becomes the first branch-only commit.
**Observed working-tree state:** Owner-provided local PowerShell evidence before this readiness audit showed clean `main`, then a successful `--ff-only` post-merge sync with `main == origin/main == 22ab43cbc613078fd98713ddfd4e0ff6a0a5c9b6`. This API-authored readiness branch does not claim the owner's local checkout was switched to it.
**Observed uncommitted/dirty files:** Owner-provided `git status -sb` showed no modified/untracked files before the post-merge sync.
**PR / tracker:** Linear TNYX-200 — `Todo`, child of TNYX-115. No open GitHub PR overlap was found during readiness. No PR exists for this branch yet.
**Current implementation state:** Canonical manual MealLog persistence, create idempotency/reconciliation, selected-day reads/cards, Meal Categories, Quick Add shell and DateTime picker are merged. The existing Quick Add `Log Meal` callback remains disabled and no production create controller exists yet.
**Relevant execution surface:** `apps/features/nutrition/lib/src/meal_logging`, `apps/features/nutrition/lib/src/meal_diary`, `apps/app` composition seam, focused Nutrition/app tests, `docs/screens/meal-diary.md`.
**Validation completed at SHA:** Read-only readiness audit on `main` `22ab43cb...`, including current GitHub/Linear/runtime source and live Supabase schema/security inspection.
**Validation remaining:** After implementation: focused controller/widget/integration tests; scope/diff audit; `melos bootstrap`, Flutter/Dart analyze, Flutter/Dart tests; exact-head CI before review. No Supabase migration validation is expected because schema changes are out of scope.
**Current blocker:** None for this create-only slice.
**Open review finding IDs:** None
**Next exact action:** On the next explicit owner `Go`, move TNYX-200 to `In Progress`, assign one Implementation owner, verify branch/head/overlap again, then implement only the plan below.

## Global UI / Design-System Guardrail

This slice changes behavior of an existing UI but does not authorize a redesign. Root `AGENTS.md`, `apps/features/AGENTS.md`, `.ai/tasks/design-system-token-consolidation.md`, and `apps/core/lib/src/theme/README.md` were read during readiness.

Preserve the current Quick Add rendered geometry, spacing, typography, colors, controls, footer layout, picker presentation and safe-area behavior. Reuse existing `TioButton` loading/disabled semantics and existing `MealLogActionFooter`; do not hand-roll new button/loading chrome or introduce a new token/component contract.

## 1. Discovery

### User Outcome

A user who already knows coarse nutrition values can finally complete the existing Quick Add flow and create one durable manual meal without duplicate-history risk:

```text
Meal Diary [+]
→ Add Food
→ Quick Add
→ enter/confirm values
→ Log Meal
→ durable manual MealLogEntry
→ editor closes after confirmation
→ affected selected-day Diary history refreshes
```

### Success Criteria

- valid create drafts can submit; invalid or incomplete drafts cannot;
- Calories is required for this owner-approved V1 Quick Add create; optional Carbs/Protein/Fat remain absent when blank;
- one submit creates one canonical manual `MealLogEntry` through `MealLogRepository.createManual`;
- the request carries `captureSource = MealLogCaptureSource.quickAdd` and no fake item/catalog identity;
- one logical create owns one stable UUID mutation identity; ambiguous outcome retry uses the exact same mutation payload/identity;
- pending state prevents rapid duplicate submission and never navigates as success before durable confirmation;
- failed save preserves the draft and exposes a retryable failure state;
- success refreshes the affected Diary read model without changing the Diary's selected date;
- current visible Quick Add design is preserved except for the already-designed CTA becoming enabled/loading/error-capable.

### Scope

- Existing Quick Add fields: optional meal name; required Calories; optional Carbs, Protein, Fat.
- Existing active Meal Category selection/suggestion.
- Existing current-local one-shot DateTime draft and no-future picker policy.
- Canonical `NutritionSnapshot` mapping.
- Stable UUID mutation identity generation with deterministic test injection.
- Create-only submit controller/state.
- Canonical repository call and error handling.
- Confirmed-success return to `MealDiaryPage` plus affected history refresh.
- Focused docs/comment reconciliation where current text still says MealLog persistence is unavailable.

### Non-Goals

- Existing manual MealLog edit/save/delete/move.
- Note field or N14 note editing in Quick Add. This child writes `note = null`; parent TNYX-115 remains responsible for later note/edit preservation rules.
- Detailed item logging, serving/provider provenance, search/photo/voice/AI flows.
- New schema, RLS, grants, indexes, functions, RPCs, or backend/service work.
- Offline-success, durable mutation queue or background replay.
- Daily summary, calendar progress, Recent/Saved/Meal Plan.

## 2. Codebase Exploration

### Verified Evidence

- Source/config inspected: root `AGENTS.md`; `apps/features/AGENTS.md`; root/docs README; `docs/ARCHITECTURE.md`; `docs/MODULE_OWNERSHIP.md`; `docs/DEVELOPMENT_SETUP.md`; `docs/ROADMAP.md`; `docs/SUPABASE_STRATEGY.md`; `docs/screens/meal-diary.md`; `.ai/README.md`; `.ai/CURRENT.md`; `.ai/DECISIONS.md`; `.ai/workflow.md`; `.ai/FEATURE_DEVELOPMENT.md`; `.ai/tasks/README.md`; `.ai/tasks/TEMPLATE.md`; `.ai/tasks/design-system-token-consolidation.md`; Core theme README; TNYX-66/114/115/158/196/198/199; current Quick Add, Meal Diary, MealLog repository/adapters/providers/tests; live Supabase `meal_log_entries`.
- Current `main`: PR #258 merged as `22ab43cbc613078fd98713ddfd4e0ff6a0a5c9b6`; owner-provided local post-merge evidence showed local/remote exact match and clean baseline.
- No open GitHub PR overlap was found during this audit.
- Linear prerequisites: TNYX-67, TNYX-114, TNYX-158, TNYX-195, TNYX-196, TNYX-198 and TNYX-199 are Done. Broad TNYX-113/TNYX-115/TNYX-116 remain larger parent contracts; their open status does not erase the completed manual-create foundations.
- `MealLogRepository` currently exposes `createManual`, `readById`, and `listByLocalDate`; update/delete are intentionally absent and therefore excluded here.
- `ManualMealLogCreate` requires a canonical UUID mutation id, active Meal Category id, already-resolved consumed instant/local-date plus timezone id or exact offset, optional meal name/note/capture source, and canonical `NutritionSnapshot`.
- `SupabaseMealLogRepository.createManual` already pre-reconciles by `clientMutationId`, validates active category for a new insert, and throws `MealLogCreateOutcomeUnknown` when the server outcome remains ambiguous.
- Nutrition already directly depends on `uuid`; `UuidMealCategoryIdGenerator` provides an existing injectable UUID-v4 pattern.
- `mealLogRepositoryProvider` is app-owned composition. TNYX-199 already overrides the feature-level `mealDiaryMealLogRepositoryProvider` with that same canonical instance, so TNYX-200 must reuse this seam rather than add another store/provider owner.
- Quick Add already owns current-local draft DateTime, Meal Category selection/suggestion, input controllers, numeric validation, and the approved DateTime picker interaction. `Log Meal` is present but has no callback.
- Existing `TioButton` already owns loading state, loading label, duplicate-tap suppression and progress semantics.
- `mealDiaryHistoryProvider` is date/repository keyed and has no MealLog mutation stream; successful create therefore needs an explicit targeted refresh of the affected currently-observed date rather than a second history cache.
- Live Supabase `public.meal_log_entries` is RLS-enabled. Read-only inspection confirmed `UNIQUE (user_id, client_mutation_id)`, own-row SELECT/INSERT/UPDATE/DELETE policies, authenticated CRUD grants, `mode = manual`, time-context-required, capture-source and canonical nutrition checks, plus the user/local-date/consumed-time read index. No DDL is needed.

### Existing pattern to follow

```text
apps/app composition
  -> canonical MealLogRepository
  -> feature seam
  -> Nutrition-owned controller/use case
  -> repository
  -> Supabase or in-memory adapter
```

Presentation renders controller state/actions; it must not call Supabase or invent persistence mapping directly.

### Tests or validation already present

- `meal_diary_add_food_flow_test.dart`: current Quick Add field/date/category/validation/disabled CTA behavior.
- repository mapping/idempotency tests for Supabase and in-memory MealLog adapters.
- selected-day provider/view tests and category-refresh tests.
- app provider composition tests.
- Final merged TNYX-199 current head passed full Flutter/Dart CI before merge; TNYX-200 still requires its own exact-head validation after implementation.

### Stale records found during audit

These are reported, not silently followed:

1. `.ai/tasks/shared-date-time-wheel-quick-add.md` still contains an old handoff saying PR #217 is open/draft, while GitHub shows #217 merged as `8379067f...`; current runtime includes the picker.
2. `.ai/CURRENT.md` is an August 23 Product Onboarding snapshot and is not current Nutrition truth.
3. `docs/DEVELOPMENT_SETUP.md` still says the Supabase workspace/config is absent and points a future backend to `backend`; both are stale against runtime/root architecture.
4. `docs/SUPABASE_STRATEGY.md` and parts of `docs/MODULE_OWNERSHIP.md` retain older `backend/*`/future-Supabase wording. Root `AGENTS.md`, current runtime and `docs/ARCHITECTURE.md` establish active Supabase and future `services/api` as canonical.

These documentation deltas do not block TNYX-200 and must not cause backend/schema work to enter this slice.

## 3. Clarification

### Decisions Required or Made

| Decision | Status | Rationale | Owner |
|---|---|---|---|
| Split full TNYX-115 and implement create only first | Approved | Repository supports safe manual create/read but not update/delete; one small slice is reviewable and does not freeze edit concurrency prematurely. | Owner + readiness audit |
| Keep current Quick Add visible field set | Approved | TNYX-158 owner-approved V1 intentionally excludes Fiber/micros and there is no approval to redesign. | Owner |
| Notes remain out of TNYX-200 | Approved boundary | Adding a note field is a visible expansion and broad TNYX-115 owns note/edit preservation. Create-only writes `note = null`. | Owner-approved bounded scope |
| Calories required; optional macros blank = absent | Locked | TNYX-158 V1 contract and `NutritionSnapshot` missing-vs-zero semantics. | Existing product contract |
| Final save online-required | Locked | TNYX-196. Do not report offline success or add a queue. | Existing owner decision |
| Same mutation ID on ambiguous retry | Locked | TNYX-196 + database uniqueness. New ID after unknown outcome risks duplicates. | Existing reliability contract |
| Do not move Diary selected date after create | Locked by existing UX boundary | Quick Add is independent of the historical day being viewed; opening/closing it does not change Diary selection. | Existing TNYX-158/TNYX-114 behavior |
| Persist exact local offset when no trustworthy IANA zone id source exists | Ready engineering application of TNYX-114 | The draft is a concrete local `DateTime`; persist `toUtc()`, its date identity and its actual `timeZoneOffset`. Do not fabricate a zone id. | TNYX-114 contract |

No unresolved owner/product/schema decision remains for this bounded create slice.

## 4. Architecture Design

### Chosen Approach

Add a Nutrition-owned create controller/state boundary between Quick Add presentation and `MealLogRepository`.

The route-local text/category/date draft may remain presentation-owned; submission converts one validated snapshot of that draft into an immutable `ManualMealLogCreate`. The controller owns pending/failure/retry/success state and the stable mutation attempt identity.

### Ownership and Data Flow

```text
QuickAddEditorSheet
  -> validate/snapshot current draft
  -> Quick Add create controller
       -> generate one UUID-v4 for a new logical attempt
       -> build/freeze ManualMealLogCreate
       -> MealLogRepository.createManual
            -> SupabaseMealLogRepository | InMemoryMealLogRepository
            -> public.meal_log_entries (production)

confirmed MealLogEntry
  -> close Quick Add with canonical result
  -> MealDiaryPage
  -> invalidate/reload matching active MealDiaryHistoryRequest when created date is currently observed
```

For create mapping:

```text
meal name blank       -> null
Calories present      -> NutrientId.energy
Carbs present         -> NutrientId.carbohydrate
Protein present       -> NutrientId.protein
Fat present           -> NutrientId.fat
blank optional macro  -> absent
captureSource         -> quickAdd
note                  -> null
consumedAt            -> draft local DateTime.toUtc()
consumedLocalDate     -> draft year/month/day
consumedTimezoneId    -> null unless a trustworthy platform zone id source already exists
consumedUtcOffsetMinutes -> draft.timeZoneOffset.inMinutes
```

The controller must defensively reject a future draft at submit against the real current-local clock even though the picker already constrains it.

### Retry state contract

```text
idle
  -> submitting(new frozen input + mutation id)
  -> success
  -> known failure       -> preserve draft; user may retry
  -> outcome unknown     -> preserve exact frozen input + same mutation id
                            and reconcile that attempt before any new logical create
```

An ambiguous outcome is not permission to edit-and-resubmit with a new id. The UI may lock submission-relevant controls or otherwise prevent starting a different logical attempt until the frozen retry is reconciled; exact mechanics must preserve the current visual contract and be covered by tests.

### Alternative Rejected

- Widget calls `SupabaseClient` directly — violates feature/data boundaries and RLS/repository architecture.
- Widget calls repository directly with all retry state inline — puts idempotency business rules in presentation and makes ambiguous-outcome safety fragile.
- New MealLog change-stream abstraction — unnecessary for a create-only slice; explicit targeted invalidation is smaller.
- Force Diary selection to the created date — breaks the existing invariant that Quick Add does not mutate the historical day the reader is viewing.
- Add note/Fiber/micros while activating save — broadens visible scope and parent acceptance unnecessarily.
- New schema/RPC — existing create/reconciliation contract and live table are sufficient.

### Failure and Accessibility States

- invalid/incomplete draft: CTA disabled; existing per-field error semantics remain;
- pending: use governed `TioButton` loading semantics; duplicate tap unavailable;
- recoverable known failure: preserve draft and show concise retry-oriented error without claiming success;
- ambiguous outcome: explain that save status must be checked/retried, preserve the same attempt, and never create a fresh mutation identity automatically;
- success: dismiss only after repository confirmation;
- signed-out or active-category rejection: fail visibly, preserve draft;
- no new color-only error or custom progress control.

## 5. Implementation Plan

- [ ] Freshly verify TNYX-200, branch head, current `main`, and no overlapping active PR before source edits; move Linear to `In Progress` and record Implementation owner.
- [ ] Add a focused Quick Add manual-create controller/state with injectable repository, clock/mutation-ID seam as needed for deterministic tests.
- [ ] Centralize/create submission parsing so Calories-required and optional-nutrient missing-vs-zero semantics are authoritative at submit, not only visual-row hints.
- [ ] Build canonical `NutritionSnapshot` and `ManualMealLogCreate` with Quick Add capture source and TNYX-114 time facts.
- [ ] Preserve stable mutation identity/input through ambiguous-outcome reconciliation; prevent duplicate/premature new attempt.
- [ ] Extend `MealLogActionFooter` only as necessary to pass through existing `TioButton` loading semantics; preserve geometry.
- [ ] Wire Quick Add to the canonical MealLog repository seam; no app-layer import from Nutrition.
- [ ] Return the confirmed `MealLogEntry` from the editor and refresh the matching active selected-day history without changing Diary selection.
- [ ] Replace stale disabled-CTA tests with create/pending/error/retry/success/no-date-jump regressions; retain existing input/date/category/layout regressions.
- [ ] Reconcile stale Quick Add runtime comments and `docs/screens/meal-diary.md` to current create behavior.
- [ ] Run focused validation, full Flutter/Dart validation, exact scope audit and final Codex-style review before Ready-for-Review handoff.

## 6. Quality Review

### Validation Run

```text
Readiness only — no production source implementation yet.

Verified:
- owner-provided local main/origin sync at 22ab43cb...
- no open GitHub PR overlap
- current root/nested governance + canonical docs/runtime source
- Linear dependencies/current statuses
- live Supabase meal_log_entries shape, unique mutation invariant, RLS policies and grants
```

### Review Findings and Resolution

| ID | Severity | Status | Finding | Observed at SHA | Evidence or follow-up |
|---|---|---|---|---|---|
| T200-R0 | Governance | Deferred | Several historical docs/handoffs retain stale Supabase/backend/PR status wording. | `22ab43cb...` | Runtime/root architecture wins; recorded under stale records above. Do not widen TNYX-200 into broad docs cleanup. |

## 7. Final Handoff

### Changed Files

Readiness checkpoint only:

- `.ai/tasks/tnyx-200-quick-add-manual-create.md`

No production/source/test/schema file has been changed by this readiness action.

### Actual Behavior

Unchanged. Quick Add `Log Meal` remains disabled until the next separately authorized implementation action.

### Known Limitations

- TNYX-200 does not complete broad TNYX-115 edit/delete/note acceptance.
- MealLog repository still intentionally has no update/delete contract.
- Quick Add note/Fiber/micros remain deferred.
- No durable offline create queue exists; V1 save is online-required.

### Final Status

`PASS — READY for TNYX-200 create-only implementation; implementation not started.`
