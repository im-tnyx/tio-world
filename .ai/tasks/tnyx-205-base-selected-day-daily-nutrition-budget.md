# TNYX-205 — Base selected-day DailyNutritionBudget resolver foundation

**Status:** In progress
**Primary owner:** `apps/features/nutrition`
**Affected platforms:** Phone Nutrition domain contract; no UI/platform rendering change in this slice

## Owner Approval and Scope Boundary

**Trigger:** New independently scoped product task/feature slice
**Approval status:** Approved
**Approval evidence:** Owner said `go` on 2026-09-13 after TNYX-209 was merged and local `main` was confirmed clean/synced at `6985de54184d8a3fdcdc865a3dcef263efa2d863`, with explicit instruction to follow root `AGENTS.md`.
**Approved product/UI/data-shape boundaries:** Implement only the N11A selected-local-date `DailyNutritionBudget` foundation backed by the canonical Nutrition Targets owner. Standard strategy only: strategy-adjusted target equals the canonical base target.
**Explicit non-changes:** No visible UI; no Eating Style/fasting/calorie-cycling editor or persistence; no Workout calorie term; no Daily Summary card/calendar wiring; no Supabase table/column/RLS/migration change; no AI text logging; no Diet Plan implementation; no generic target narrowing.

## Active Handoff

**Planning owner:** ChatGPT
**Implementation owner:** ChatGPT
**Review owner:** Unassigned until implementation handoff
**Implementation ownership state:** Active
**Ownership transition:** Not applicable
**Repository state last verified:** Remote `main` and owner-confirmed local `main` both `6985de54184d8a3fdcdc865a3dcef263efa2d863`; task branch created from that exact SHA.
**Branch:** `tnyx/tnyx-205-n11a-base-selected-day-dailynutritionbudget-resolver`
**HEAD SHA:** task-brief commit pending connector result at creation checkpoint
**Observed working-tree state:** Owner reported `## main...origin/main` before task branch creation; this connector does not expose the owner's local worktree.
**Observed uncommitted/dirty files:** None reported by owner on synced `main`.
**PR / tracker:** Linear `TNYX-205` is `In Progress`; stale `blockedBy TNYX-209` relation removed after TNYX-209 Done/merge/sync. No PR yet.
**Current implementation state:** Audit complete enough to begin the bounded domain foundation; no source implementation existed on `main` for `DailyNutritionBudget`.
**Relevant execution surface:** `apps/features/nutrition/lib/src/domain/**`, canonical `NutritionTargetsRepository`, existing `MealLogLocalDate` selected-day identity in `apps/shared`.
**Validation completed at SHA:** None for TNYX-205 source yet.
**Validation remaining:** Focused Nutrition tests/analyze, repository-required CI, parent-to-head scope audit.
**Current blocker:** None.
**Open review finding IDs:** None.
**Next exact action:** Add the minimal budget read model + resolver and focused pure-domain tests without UI/schema changes.

## 1. Discovery

### User Outcome

Give Meal Diary/Daily Summary consumers one explicit selected-day target-budget contract so historical dates do not silently fall back to today and future N11/N10 adjustments have one owner seam.

### Success Criteria

- Consumer passes an explicit local calendar date.
- Canonical `NutritionTargetsRepository` remains the only base-target owner.
- Standard strategy returns the canonical target unchanged as `strategyAdjustedTarget`.
- Absent canonical target returns unavailable (`null`), never a zero-filled budget.
- Partial canonical target fields remain null/unknown instead of becoming zero.
- Repository/read failures stay failures; they are not converted into “no target”.
- Later schedule/workout policy can be inserted behind the resolver without forcing consumers to reinterpret target storage.

### Scope

- `DailyNutritionBudget` immutable read model.
- One Nutrition-domain resolver/use case accepting an explicit selected local date and reading canonical targets.
- Public Nutrition-domain exports.
- Focused domain tests.
- Minimal canonical doc reconciliation only if implementation status text becomes stale.

### Non-Goals

Full N11 schedule models/storage, fasting protocols, calorie-cycling configuration, Workout calorie integration, N3A summary UI/read model, Meal Diary calendar progress wiring, Supabase changes, target editor changes.

## 2. Codebase Exploration

### Verified Evidence

- `NutritionTargetsData` is the canonical daily target value contract; nullable nutrient values mean unknown/unset and validation does not fabricate defaults.
- `NutritionTargetsRepository.read()` returns `NutritionTargetsData?`; `null` already represents no canonical target row.
- `SupabaseNutritionTargetsRepository` reads the canonical `user_nutrition_targets` owner and requires no date-specific schema for this slice.
- `apps/app` already composes one canonical `nutritionTargetsRepositoryProvider`; its Settings-facing `nutritionTargetsDataProvider` intentionally substitutes an all-null object for first-time editing, so N11A must depend on the repository boundary rather than that presentation convenience provider when absence matters.
- `MealLogLocalDate` is the existing Nutrition-bounded date-only/calendar-identity value object. It avoids timezone-moving `DateTime` semantics and is already what Meal Diary uses for selected-day history.
- No `DailyNutritionBudget` runtime implementation exists on `main`.
- `docs/screens/meal-diary.md` already reserves calorie progress for a shared `DailyNutritionBudget(date)` contract and explicitly forbids fabricating a denominator.
- Linear `TNYX-64` freezes the durable boundary: canonical target → schedule resolve(date) → strategy-adjusted target → later optional N10 workout policy → daily budget.
- Linear `TNYX-206` is the immediate consumer after this slice and requires selected-date target truth with missing values preserved as unavailable.

Pre-existing documentation drift observed but not owned by this bounded slice: `docs/screens/nutrition-targets.md` still says planned/no route although runtime Settings target surfaces exist; portions of `docs/DEVELOPMENT_SETUP.md` / `docs/SUPABASE_STRATEGY.md` also retain older repository-state wording. Runtime/source and current architecture docs win; this task must not silently use those stale statements as implementation truth.

### Existing pattern to follow

Feature-owned immutable models + use cases under `apps/features/nutrition/lib/src/domain`, repository injection for canonical persistence/read ownership, and public barrel exports through `models.dart` / `usecases.dart`.

### Tests or validation already present

Canonical target model/repository and MealLog date identity have existing coverage. TNYX-205-specific tests do not exist yet.

## 3. Clarification

### Decisions Required or Made

| Decision | Status | Rationale | Owner |
|---|---|---|---|
| Reuse `NutritionTargetsRepository` rather than add a budget table/repository | Locked | Budget is derived read truth, not duplicate persistence | TNYX-54/TNYX-205 |
| Reuse existing `MealLogLocalDate` for selected-day identity in V1 | Locked for this slice | Avoid raw `DateTime` timezone semantics and avoid creating a competing date-only model; broader naming/generalization can wait for evidence from more consumers | Implementation audit |
| Resolver returns `null` only when canonical target row is absent | Locked | Distinguishes unavailable target from repository failure and preserves unknown fields | TNYX-205 |
| Standard strategy returns canonical target unchanged | Locked | Current/default strategy has no date-specific adjustment | TNYX-64/TNYX-205 |
| Do not introduce a placeholder NutritionSchedule model | Locked | Full schedule rules/storage are later N11 slices; speculative models would broaden scope | TNYX-205 |
| No app/UI provider wiring yet | Locked | N11A owns the reusable domain contract; N3A can compose it at the consuming read-model boundary | Bounded-slice audit |

## 4. Architecture Design

### Chosen Approach

Add `DailyNutritionBudget` with explicit `localDate`, `baseTarget`, and `strategyAdjustedTarget`. Add `DailyNutritionBudgetResolver` constructed with `NutritionTargetsRepository`; `resolve(localDate)` reads canonical target truth, returns `null` when absent, validates/preserves it, and for Standard returns it unchanged as the strategy-adjusted target.

### Ownership and Data Flow

```text
selected MealLogLocalDate
        +
NutritionTargetsRepository.read()
        ↓
DailyNutritionBudgetResolver
        ↓
DailyNutritionBudget
  baseTarget
  strategyAdjustedTarget  // Standard == base today
        ↓
N3A / future consumers
```

Later N11 schedule and N10 workout policy are inserted behind/after this resolver boundary; canonical target storage remains unchanged.

### Alternative Rejected

- Raw `DateTime`: rejected because a selected Diary day is calendar identity, not an instant.
- New `NutritionLocalDate`: rejected for V1 because it would duplicate an already proven Nutrition date-only identity solely to improve naming.
- Persisted daily budget rows: rejected because they duplicate derived target truth and create historical synchronization problems before schedule history semantics are designed.
- Placeholder schedule enum/model now: rejected as speculative broad N11 implementation.

### Failure and Accessibility States

No UI in this slice. Domain semantics distinguish absent target (`null`) from repository/read failure (exception). Nullable nutrients remain nullable for future consumers to render as unavailable rather than zero.

## 5. Implementation Plan

- [ ] Add `DailyNutritionBudget` domain model.
- [ ] Add `DailyNutritionBudgetResolver` using `NutritionTargetsRepository`.
- [ ] Export both through Nutrition public domain barrels.
- [ ] Add focused tests for Standard, explicit historical date, absent row, partial/null values, and read failure propagation.
- [ ] Reconcile `docs/screens/meal-diary.md` only if its implementation-status wording becomes stale.
- [ ] Run focused/package validation then exact-head CI/scope audit before review.

## 6. Quality Review

### Validation Run

```text
Not run yet.
```

### Review Findings and Resolution

| ID | Severity | Status | Finding | Observed at SHA | Evidence or follow-up |
|---|---|---|---|---|---|
| — | — | — | No review findings yet | — | — |

## 7. Final Handoff

### Changed Files

Pending.

### Actual Behavior

Pending implementation.

### Known Limitations

Standard strategy only. No schedule persistence/history, Workout calorie policy, summary UI, or calendar progress wiring in TNYX-205.

### Final Status

`PARTIAL`
