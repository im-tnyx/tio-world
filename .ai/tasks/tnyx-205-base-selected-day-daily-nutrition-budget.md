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
**Review owner:** Codex reviewed exact source/checkpoint head `3567ce72f6c28afe363e510a1f4ecaeed3f3fe4f`; fresh review required after R1 correction
**Implementation ownership state:** Active through superseding validation/re-review
**Ownership transition:** Review returned one actionable P2; implementation ownership returned to ChatGPT for the correction. R1 is now source-resolved, but review ownership has not yet been re-established on the new exact head.
**Repository state last verified:** Exact parent/merge base remains `main@6985de54184d8a3fdcdc865a3dcef263efa2d863`; pre-review scope audit was ahead 7 / behind 0 with exactly 6 intended paths.
**Branch:** `tnyx/tnyx-205-n11a-base-selected-day-dailynutritionbudget-resolver`
**HEAD SHA:** R1 source/test correction head `c94b44b88e506a7bdf17b7caff741fb4e5783723`; this task-brief reconciliation commit moves HEAD docs-only and therefore fresh exact-head CI remains mandatory.
**Observed working-tree state:** Owner reported clean synced `main` before branch creation; this remote connector does not expose the owner's local branch worktree.
**Observed uncommitted/dirty files:** None reported by owner on synced `main`; no remote API evidence of out-of-scope files.
**PR / tracker:** Draft PR #266 open; Linear `TNYX-205` remains `In Progress`.
**Current implementation state:** Bounded domain implementation plus R1 correction are present. Resolver documentation/tests now match the frozen repository read contract: repository `null` means target unavailable under that boundary and carries no cause discriminator; resolver does not infer/create Auth state; thrown read/validation failures still propagate.
**Relevant execution surface:** `apps/features/nutrition/lib/src/domain/**`, canonical `NutritionTargetsRepository`, existing `MealLogLocalDate` selected-day identity in `apps/shared`.
**Validation completed at SHA:** GitHub Actions #2489 / run `34758207394` passed Flutter analyze, Dart analyze, Flutter tests and Dart tests at superseded head `3567ce72f6c28afe363e510a1f4ecaeed3f3fe4f`.
**Validation remaining:** Fresh parent-to-head scope audit, superseding exact-head CI, fresh Codex/independent review of R1 correction.
**Current blocker:** None in source; readiness is gated on superseding exact-head validation/re-review.
**Open review finding IDs:** None — `TNYX-205-R1` source-resolved pending fresh review confirmation.
**Next exact action:** Audit parent-to-current-head scope, run exact-head CI, reply/resolve the original review thread with evidence, then trigger fresh Codex review on the validated head.

## 1. Discovery

### User Outcome

Give Meal Diary/Daily Summary consumers one explicit selected-day target-budget contract so historical dates do not silently fall back to today and future N11/N10 adjustments have one owner seam.

### Success Criteria

- Consumer passes an explicit local calendar date.
- Canonical `NutritionTargetsRepository` remains the only base-target owner.
- Standard strategy returns the canonical target unchanged as `strategyAdjustedTarget`.
- A repository `null` result remains unavailable budget truth, never a zero-filled budget.
- Partial canonical target fields remain null/unknown instead of becoming zero.
- Repository-thrown read/validation failures stay failures; the resolver does not reinterpret or create Auth/session state.
- Later schedule/workout policy can be inserted behind the resolver without forcing consumers to reinterpret target storage.

### Scope

- `DailyNutritionBudget` immutable read model.
- One Nutrition-domain resolver/use case accepting an explicit selected local date and reading canonical targets.
- Public Nutrition-domain exports.
- Focused domain tests.
- Minimal canonical doc reconciliation only if implementation status text becomes stale.

### Non-Goals

Full N11 schedule models/storage, fasting protocols, calorie-cycling configuration, Workout calorie integration, N3A summary UI/read model, Meal Diary calendar progress wiring, Supabase changes, target editor changes, Auth/session-state redesign.

## 2. Codebase Exploration

### Verified Evidence

- `NutritionTargetsData` is the canonical daily target value contract; nullable nutrient values mean unknown/unset and validation does not fabricate defaults.
- `NutritionTargetsRepository.read()` returns `NutritionTargetsData?`; the interface does not expose an absence-cause enum/result.
- `SupabaseNutritionTargetsRepository` reads the canonical `user_nutrition_targets` owner and requires no date-specific schema for this slice.
- Existing canonical data test `supabase_canonical_nutrition_repositories_test.dart` explicitly locks signed-out target reads to `null` and signed-out writes to fail closed before gateway access.
- Existing frozen task `.ai/tasks/production-hardening-repository-owned-anonymous-auth.md` states that read paths may return `null` where the existing domain contract models signed-out/no-row as absent state; repositories must not own Auth-session creation.
- Therefore N11A does not claim that repository `null` proves a row was queried and absent. It only means canonical target data is unavailable from this repository read. Thrown repository failures remain distinguishable and propagate.
- `apps/app` already composes one canonical `nutritionTargetsRepositoryProvider`; its Settings-facing `nutritionTargetsDataProvider` intentionally substitutes an all-null object for first-time editing, so N11A depends on the repository boundary rather than that presentation convenience provider when absence matters.
- `MealLogLocalDate` is the existing Nutrition-bounded date-only/calendar-identity value object and is publicly exported by `package:tio_shared/shared.dart`. It avoids timezone-moving `DateTime` semantics and is already what Meal Diary uses for selected-day history.
- No `DailyNutritionBudget` runtime implementation existed on `main` before this branch.
- `docs/screens/meal-diary.md` already reserves calorie progress for a shared `DailyNutritionBudget(date)` contract and explicitly forbids fabricating a denominator. Its current wording remains accurate because TNYX-205 adds the domain foundation but does not wire progress UI.
- Linear `TNYX-64` freezes the durable boundary: canonical target → schedule resolve(date) → strategy-adjusted target → later optional N10 workout policy → daily budget.
- Linear `TNYX-206` is the immediate consumer after this slice and requires selected-date target truth with missing values preserved as unavailable.

Pre-existing documentation drift observed but not owned by this bounded slice: `docs/screens/nutrition-targets.md` still says planned/no route although runtime Settings target surfaces exist; portions of `docs/DEVELOPMENT_SETUP.md` / `docs/SUPABASE_STRATEGY.md` also retain older repository-state wording. Runtime/source and current architecture docs win; this task does not silently use those stale statements as implementation truth.

### Existing pattern to follow

Feature-owned immutable models + use cases under `apps/features/nutrition/lib/src/domain`, repository injection for canonical persistence/read ownership, and public barrel exports through `models.dart` / `usecases.dart`.

### Tests or validation already present

Canonical target model/repository and MealLog date identity have existing coverage. TNYX-205 adds focused resolver coverage at `apps/features/nutrition/test/domain/daily_nutrition_budget_resolver_test.dart`, including explicit repository-null/unavailable semantics after R1.

## 3. Clarification

### Decisions Required or Made

| Decision | Status | Rationale | Owner |
|---|---|---|---|
| Reuse `NutritionTargetsRepository` rather than add a budget table/repository | Locked | Budget is derived read truth, not duplicate persistence | TNYX-54/TNYX-205 |
| Reuse existing `MealLogLocalDate` for selected-day identity in V1 | Locked for this slice | Avoid raw `DateTime` timezone semantics and avoid creating a competing date-only model; broader naming/generalization can wait for evidence from more consumers | Implementation audit |
| Repository `null` means target unavailable to N11A; resolver does not infer the cause | Implemented after R1 | Existing canonical repository/test intentionally permits signed-out/no-row reads to return null. Adding Auth ownership or silently changing repository-wide semantics would broaden the slice and violate frozen boundaries. | Runtime/source + R1 audit |
| Thrown repository/read failures propagate | Locked | Preserves actual error truth rather than converting exceptions into unavailable target | TNYX-205 |
| Standard strategy returns canonical target unchanged | Locked | Current/default strategy has no date-specific adjustment | TNYX-64/TNYX-205 |
| Validate a present repository target at the resolver boundary | Implemented | Canonical adapters validate on write/read already; resolver also fails closed if a custom/future adapter violates that contract instead of publishing invalid budget truth | Implementation audit |
| Do not introduce a placeholder NutritionSchedule model | Locked | Full schedule rules/storage are later N11 slices; speculative models would broaden scope | TNYX-205 |
| No app/UI provider wiring yet | Locked | N11A owns the reusable domain contract; N3A can compose it at the consuming read-model boundary | Bounded-slice audit |

## 4. Architecture Design

### Chosen Approach

`DailyNutritionBudget` carries explicit `localDate`, `baseTarget`, and `strategyAdjustedTarget`. `DailyNutritionBudgetResolver` is constructed with `NutritionTargetsRepository`; `resolve(localDate)` reads canonical target truth, returns `null` when the repository reports unavailable target data, validates/preserves a present target, and for Standard returns it unchanged as the strategy-adjusted target. The resolver deliberately does not infer whether a repository `null` came from no row versus the repository's existing signed-out read behavior; app/session ownership remains outside Nutrition.

### Ownership and Data Flow

```text
selected MealLogLocalDate
        +
NutritionTargetsRepository.read()
        ↓
DailyNutritionBudgetResolver
        ↓
null  // canonical target unavailable under repository contract
  OR
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
- Changing `SupabaseNutritionTargetsRepository.read()` globally to throw when signed out: rejected because existing canonical source/tests explicitly freeze signed-out reads as null and such a change would alter unrelated Settings/onboarding readers.
- Injecting Auth/session state into `DailyNutritionBudgetResolver`: rejected because Nutrition budget resolution must not become an Auth owner and the app session boundary already owns authentication lifecycle.

### Failure and Accessibility States

No UI in this slice. Domain semantics preserve repository `null` as unavailable target truth, while thrown read/validation failures remain failures. Nullable nutrients inside a present target remain nullable for future consumers to render as unavailable rather than zero.

## 5. Implementation Plan

- [x] Add `DailyNutritionBudget` domain model.
- [x] Add `DailyNutritionBudgetResolver` using `NutritionTargetsRepository`.
- [x] Export both through Nutrition public domain barrels.
- [x] Add focused tests for Standard, explicit historical date, unavailable/null target, partial/null values, read failure propagation, and fail-closed invalid canonical target handling.
- [x] Reconcile `docs/screens/meal-diary.md` need: no edit required because the existing statement that progress wiring remains later is still accurate.
- [x] Resolve `TNYX-205-R1` wording/test contract mismatch without changing frozen repository/Auth behavior.
- [ ] Run superseding exact-head repository validation and fresh review before review handoff.

## 6. Quality Review

### Validation Run

```text
Original reviewed source/checkpoint head: 3567ce72f6c28afe363e510a1f4ecaeed3f3fe4f
Base/merge-base: 6985de54184d8a3fdcdc865a3dcef263efa2d863
Ahead 7 / behind 0
Exactly 6 intended paths
GitHub Actions #2489 / run 34758207394:
- Flutter analyze: success
- Dart analyze: success
- Flutter tests: success
- Dart tests: success

R1 source/test correction head: c94b44b88e506a7bdf17b7caff741fb4e5783723
Fresh exact-head validation pending after this task-brief reconciliation commit.
```

### Review Findings and Resolution

| ID | Severity | Status | Finding | Observed at SHA | Evidence or follow-up |
|---|---|---|---|---|---|
| TNYX-205-R1 | P2 | Resolved in source; fresh review pending | Resolver documentation/task contract claimed `null` means only confirmed absent canonical row, but `SupabaseNutritionTargetsRepository.read()` intentionally returns `null` for signed-out reads too. Do not misclassify or invent Auth semantics at the budget boundary. | `3567ce72f6c28afe363e510a1f4ecaeed3f3fe4f` | Codex comment `3999692588`. At `c94b44b88e506a7bdf17b7caff741fb4e5783723`, resolver docs now define repository null as unavailable without cause inference; a focused regression covers null/unavailable behavior; thrown failures remain failures; no repository/Auth behavior changed. |

## 7. Final Handoff

### Changed Files

Current intended set before final validation:

- `.ai/tasks/tnyx-205-base-selected-day-daily-nutrition-budget.md`
- `apps/features/nutrition/lib/src/domain/models/daily_nutrition_budget.dart`
- `apps/features/nutrition/lib/src/domain/models/models.dart`
- `apps/features/nutrition/lib/src/domain/usecases/daily_nutrition_budget_resolver.dart`
- `apps/features/nutrition/lib/src/domain/usecases/usecases.dart`
- `apps/features/nutrition/test/domain/daily_nutrition_budget_resolver_test.dart`

### Actual Behavior

A caller supplies one explicit `MealLogLocalDate`. The resolver reads the canonical Nutrition Targets owner. A repository `null` yields unavailable budget truth without fabricating data or inferring the absence cause; a present valid target yields a `DailyNutritionBudget` whose Standard strategy-adjusted target is exactly the canonical base target; null nutrient fields remain null; thrown read/validation failures propagate.

### Known Limitations

Standard strategy only. Current target storage is not effective-dated, so this foundation preserves the selected date as resolver identity but does not invent historical target/schedule snapshots. Repository `null` does not carry a cause discriminator in the existing canonical interface; app/session state remains owned outside this resolver. No schedule persistence/history, Workout calorie policy, summary UI, or calendar progress wiring belongs to TNYX-205.

### Final Status

`PARTIAL` — R1 is source-resolved; superseding exact-head validation and fresh review remain.
