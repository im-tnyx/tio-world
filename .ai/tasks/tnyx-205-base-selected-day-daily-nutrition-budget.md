# TNYX-205 — Base selected-day DailyNutritionBudget resolver foundation

**Status:** Review handoff — final exact-head CI gate
**Primary owner:** `apps/features/nutrition`
**Affected platforms:** Phone Nutrition domain contract; no UI/platform rendering change in this slice

## Owner Approval and Scope Boundary

**Trigger:** New independently scoped product task/feature slice
**Approval status:** Approved
**Approval evidence:** Owner said `go` on 2026-09-13 after TNYX-209 was merged and local `main` was confirmed clean/synced at `6985de54184d8a3fdcdc865a3dcef263efa2d863`, with explicit instruction to follow root `AGENTS.md`.
**Approved product/UI/data-shape boundaries:** Implement only the N11A selected-local-date `DailyNutritionBudget` foundation backed by the canonical Nutrition Targets owner. Standard strategy only: strategy-adjusted target equals the canonical base target.
**Explicit non-changes:** No visible UI; no Eating Style/fasting/calorie-cycling editor or persistence; no Workout calorie term; no Daily Summary card/calendar wiring; no Supabase table/column/RLS/migration change; no AI text logging; no Diet Plan implementation; no generic target narrowing; no Auth/session redesign.

## Active Handoff

**Planning owner:** ChatGPT
**Implementation owner:** Inactive after validated source/review handoff
**Review owner:** Owner / final review
**Implementation ownership state:** Released after R1 correction, exact-source validation, and clean Codex re-review
**Ownership transition:** ChatGPT implementation → Codex independent review → ChatGPT R1 correction → Codex clean re-review → owner review
**Repository state last verified:** Exact parent/merge base `main@6985de54184d8a3fdcdc865a3dcef263efa2d863`; parent-to-reviewed-head audit reported ahead 11 / behind 0 with exactly 6 intended paths.
**Branch:** `tnyx/tnyx-205-n11a-base-selected-day-dailynutritionbudget-resolver`
**Reviewed source/head before this handoff commit:** `4c94c21f932aa8e0bdad0384471b021a35b08784`
**Observed working-tree state:** Owner reported clean synced `main` before branch creation; this remote connector does not expose the owner's local branch worktree.
**Observed uncommitted/dirty files:** None reported by owner on synced `main`; no remote API evidence of out-of-scope files.
**PR / tracker:** Draft PR #266 open; Linear `TNYX-205` remains `In Progress` until this final docs-only handoff head passes exact-head CI.
**Current implementation state:** Bounded N11A domain foundation complete. `DailyNutritionBudget` and `DailyNutritionBudgetResolver` are implemented and exported. Standard strategy preserves canonical targets. Repository null remains unavailable target truth without cause inference; thrown failures propagate. No UI/schema/Workout/full-N11 work was added.
**Relevant execution surface:** `apps/features/nutrition/lib/src/domain/**`, canonical `NutritionTargetsRepository`, existing `MealLogLocalDate` selected-day identity in `apps/shared`.
**Validation completed at reviewed source head:** GitHub Actions #2493 / run `34759348802` passed Flutter analyze, Dart analyze, Flutter tests and Dart tests at `4c94c21f932aa8e0bdad0384471b021a35b08784`.
**Review completed at reviewed source head:** Fresh Codex re-review reported “Didn't find any major issues” for reviewed commit `4c94c21f93`; original R1 thread is resolved.
**Validation remaining:** This final task-brief handoff commit is docs-only and therefore creates a new exact HEAD. Run/verify repository CI on that exact final HEAD before marking PR/Linear `In Review`. If it passes and no code/task content changes follow, no further task-brief mutation is required; live PR/Linear carry the final exact-head readiness state.
**Current blocker:** Final docs-only exact-head CI only.
**Open review finding IDs:** None.
**Next exact action:** Verify CI on this final handoff HEAD, refresh scope/PR metadata, then move PR/Linear to review handoff. Do not merge without explicit owner permission.

## 1. Discovery

### User Outcome

Give Meal Diary/Daily Summary consumers one explicit selected-day target-budget contract so historical dates do not silently fall back to today and future N11/N10 adjustments have one owner seam.

### Success Criteria

- Consumer passes an explicit local calendar date.
- Canonical `NutritionTargetsRepository` remains the only base-target owner.
- Standard strategy returns the canonical target unchanged as `strategyAdjustedTarget`.
- A repository `null` result remains unavailable budget truth, never a zero-filled budget.
- Partial canonical target fields remain null/unknown instead of becoming zero.
- Repository-thrown read/validation failures stay failures; resolver does not reinterpret or create Auth/session state.
- Later schedule/workout policy can be inserted behind the resolver without forcing consumers to reinterpret target storage.

### Scope

- `DailyNutritionBudget` immutable read model.
- `DailyNutritionBudgetResolver` accepting an explicit selected local date and reading canonical targets.
- Public Nutrition-domain exports.
- Focused domain tests.
- Task/PR/tracker reconciliation.

### Non-Goals

Full N11 schedule models/storage, fasting protocols, calorie-cycling configuration, Workout calorie integration, N3A summary UI/read model, Meal Diary calendar progress wiring, Supabase changes, target editor changes, Auth/session-state redesign.

## 2. Codebase Exploration

### Verified Evidence

- `NutritionTargetsData` is the canonical daily target value contract; nullable nutrient values mean unknown/unset and validation does not fabricate defaults.
- `NutritionTargetsRepository.read()` returns `NutritionTargetsData?`; the interface exposes no absence-cause enum/result.
- `SupabaseNutritionTargetsRepository` owns canonical `user_nutrition_targets` reads and requires no date-specific schema for N11A.
- Existing canonical repository tests explicitly lock signed-out target reads to `null` and signed-out writes to fail closed before gateway access.
- Frozen production-hardening governance states read paths may return `null` where their existing contract models signed-out/no-row as absent state; repositories must not own Auth-session creation.
- Therefore N11A treats repository `null` only as unavailable target data and does not infer why it is unavailable.
- `MealLogLocalDate` is the existing Nutrition-bounded date-only/calendar identity and is already used by Meal Diary selected-day history.
- `docs/screens/meal-diary.md` already reserves selected-day calorie progress for `DailyNutritionBudget(date)` and forbids fabricated denominators; no canonical screen-doc edit is required in this foundation slice.
- Linear TNYX-64 locks the long-term flow: canonical target → schedule resolve(date) → strategy-adjusted target → later optional workout policy → daily budget.
- Linear TNYX-206 is the immediate consumer after this slice.

Pre-existing unrelated documentation drift remains outside scope; runtime/source and current architecture docs win.

## 3. Clarification

| Decision | Status | Rationale |
|---|---|---|
| Reuse `NutritionTargetsRepository` | Locked | Budget is derived read truth, not duplicate persistence |
| Reuse `MealLogLocalDate` in V1 | Locked for slice | Avoid raw `DateTime` and avoid a competing date-only model |
| Repository `null` = target unavailable to N11A, cause not inferred | Implemented after R1 | Matches frozen repository behavior without making Nutrition an Auth owner |
| Thrown read/validation failures propagate | Implemented | Preserve actual failure truth |
| Standard strategy returns canonical target unchanged | Implemented | No date-specific strategy adjustment yet |
| Validate present target at resolver boundary | Implemented | Fail closed if a future/custom adapter violates canonical target validity |
| No placeholder NutritionSchedule model | Locked | Full schedule semantics belong to later N11 slices |
| No app/UI provider wiring | Locked | N3A composes the domain contract at the consuming read-model boundary |

## 4. Architecture Design

```text
selected MealLogLocalDate
        +
NutritionTargetsRepository.read()
        ↓
DailyNutritionBudgetResolver
        ↓
null  // target unavailable under repository contract
  OR
DailyNutritionBudget
  baseTarget
  strategyAdjustedTarget  // Standard == base today
        ↓
N3A / future consumers
```

Rejected alternatives: raw `DateTime`, a duplicate `NutritionLocalDate`, persisted daily-budget rows, speculative full schedule models, changing canonical signed-out repository behavior, or injecting Auth/session ownership into the resolver.

## 5. Implementation

- [x] Added `DailyNutritionBudget` domain model.
- [x] Added `DailyNutritionBudgetResolver` using `NutritionTargetsRepository`.
- [x] Exported both through Nutrition public barrels.
- [x] Added focused tests for Standard behavior, explicit historical date, repository-null/unavailable semantics, nullable fields, thrown failures, and invalid target fail-closed behavior.
- [x] Kept visible UI, schema/RLS, Workout calories, full NutritionSchedule, AI logging and Diet Plan out of scope.
- [x] Reviewed canonical Meal Diary documentation; no edit required.

## 6. Quality Review

### Validation

Reviewed implementation head:

```text
4c94c21f932aa8e0bdad0384471b021a35b08784
GitHub Actions #2493 / run 34759348802
Flutter analyze ✅
Dart analyze    ✅
Flutter tests   ✅
Dart tests      ✅
```

This final handoff commit is docs-only and must receive its own exact-head CI before external readiness is claimed.

### Review Findings

| ID | Severity | Status | Finding | Observed at SHA | Resolution |
|---|---|---|---|---|---|
| TNYX-205-R1 | P2 | Resolved | Initial resolver docs claimed `null` meant only a confirmed absent row, but canonical Supabase target reads intentionally also return `null` when signed out. | `3567ce72f6c28afe363e510a1f4ecaeed3f3fe4f` | Resolver/task contract now defines repository null as unavailable without cause inference; regression added; no repository/Auth behavior changed; exact source CI #2493 green; review thread resolved. |

Fresh Codex re-review on `4c94c21f93` reported no major issues.

## 7. Final Handoff

### Changed Files

Exactly 6 intended paths at reviewed implementation head:

- `.ai/tasks/tnyx-205-base-selected-day-daily-nutrition-budget.md`
- `apps/features/nutrition/lib/src/domain/models/daily_nutrition_budget.dart`
- `apps/features/nutrition/lib/src/domain/models/models.dart`
- `apps/features/nutrition/lib/src/domain/usecases/daily_nutrition_budget_resolver.dart`
- `apps/features/nutrition/lib/src/domain/usecases/usecases.dart`
- `apps/features/nutrition/test/domain/daily_nutrition_budget_resolver_test.dart`

### Actual Behavior

A caller supplies one explicit `MealLogLocalDate`. The resolver reads canonical Nutrition Targets. Repository `null` yields unavailable budget truth without fabricated zero or auth-cause inference. A present valid target yields `DailyNutritionBudget`; under Standard, `strategyAdjustedTarget` is the same canonical target. Nullable target fields remain nullable. Thrown read/validation failures propagate.

### Known Limitations

Standard strategy only. Canonical targets are not effective-dated in this slice, so the selected date is preserved as resolver identity but historical target/schedule snapshots are not invented. Repository null has no cause discriminator. No schedule persistence/history, Workout calorie policy, summary UI or calendar progress wiring is implemented here.

### Next Slice

After explicit merge + post-merge sync, the owner-approved next Nutrition slice is `TNYX-206` — N3A Base Daily Nutrition Summary. Do not start it before TNYX-205 merge/sync.

### Merge Gate

No merge is authorized by this handoff. Merge requires explicit owner permission and the repository post-merge sync workflow afterward.
