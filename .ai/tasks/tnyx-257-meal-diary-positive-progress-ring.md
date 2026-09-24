# TNYX-257 — Meal Diary positive-only calendar progress ring

**Status:** In progress  
**Primary owner:** `apps/features/nutrition`  
**Affected platforms:** Flutter phone Meal Diary

## Owner Approval and Scope Boundary

**Trigger:** Unapproved product-visible UI/UX change  
**Approval status:** Approved  
**Approval evidence:** Owner approved GitHub #317 implementation with `Go follow agent.md` and clarified that while progress is `0` / no ring is being drawn, the empty progress track must not appear.  
**Approved product/UI/data-shape boundaries:** Meal Diary calendar progress decoration is visible only for exact positive calorie progress. `progress <= 0` means no progress decoration/track.  
**Explicit non-changes:** No Core calendar semantic change, no selected-date tonal-fill change, no future-date policy change, no Daily Nutrition zero-consumption change, no Nutrition target calculation change, no MealLog persistence change, no Supabase schema/RLS/RPC change, no N+1 reads, no unrelated Meal Diary redesign.

## Active Handoff

**Planning owner:** ChatGPT  
**Implementation owner:** ChatGPT  
**Review owner:** ChatGPT after implementation  
**Implementation ownership state:** Active  
**Ownership transition:** Not applicable  
**Repository state last verified:** Remote GitHub state at `main@5270c56031a4012ba52122d64de994af2a3c85cd`; branch created from that exact SHA. Connector session cannot inspect a local working tree, so no local `git status`/clean-worktree claim is made. GitHub had no open PR at task start.  
**Branch:** `tnyx/tnyx-257-meal-diary-positive-progress-ring`  
**HEAD SHA:** source/test/docs implementation at `d8c518a77f072f681d5af8efba0f7605a2d6d0f4`; resulting handoff-metadata SHA is tracked by the PR rather than recursively embedded here  
**Observed working-tree state:** Remote branch only; no local checkout available in this tool session.  
**Observed uncommitted/dirty files:** Unavailable; no local-worktree claim.  
**PR / tracker:** GitHub #317; Linear TNYX-257 (`In Progress`), parent TNYX-56, related TNYX-206.  
**Current implementation state:** Implementation and focused regression updates committed. Meal Diary now suppresses calendar decoration for non-positive calorie progress; Core and domain zero truth are unchanged.  
**Relevant execution surface:** `MealDiaryPage._calendarDecorationBuilder`, Daily Nutrition integration/recovery tests, `docs/screens/meal-diary.md`.  
**Validation completed at SHA:** `9e9a7152b7ed935c46cf376ce6050f14912e10df` — Flutter CI #2709 / run `35925479132` passed Bootstrap, Flutter analyze, Dart analyze, all Flutter package tests, and all Dart package tests.  
**Validation remaining:** CI for this resulting metadata-only handoff commit, then PR review/reconciliation. Runtime/source validation is green at `9e9a7152`. Local Flutter execution remains unavailable in this connector-only session.  
**Current blocker:** None.  
**Open review finding IDs:** None.  
**Next exact action:** Validate this metadata-only handoff head, then mark PR #326 Ready for Review and reconcile TNYX-257 to `In Review` if gates stay green.

## Global UI / Design-System Guardrail

Read before source changes:

- `AGENTS.md`
- `.ai/workflow.md`
- `.ai/FEATURE_DEVELOPMENT.md`
- `.ai/tasks/README.md`
- `.ai/tasks/design-system-token-consolidation.md`
- `apps/features/AGENTS.md`
- `apps/core/lib/src/theme/README.md`
- `docs/PUSH_TEMPLATE.md`
- `.github/PULL_REQUEST_TEMPLATE.md`

This slice changes visibility of an already-approved progress decoration only. It introduces no new visual token, geometry, color, typography, spacing, reusable Core component, or design-system contract.

## 1. Discovery

### User Outcome

Meal Diary calendar should not show an empty gray progress ring/track when calorie progress is zero. The ring should appear only after exact positive calorie progress exists.

### Success Criteria

- empty past/current date with positive target: no ring/track;
- logged date with exact zero calories: no ring/track;
- exact positive progress: existing ring remains;
- incomplete/missing calorie truth: no ring;
- missing/invalid target: no ring;
- future/disabled date: no ring;
- selected-day Daily Nutrition can still show `Eaten = 0`;
- Core `progress: null` vs `progress: 0` contract stays unchanged;
- bounded range read remains one range read, with no presentation N+1.

### Scope

- `apps/features/nutrition/lib/src/meal_diary/presentation/pages/meal_diary_page.dart`
- focused Meal Diary Daily Nutrition integration/recovery tests;
- `docs/screens/meal-diary.md`;
- this task brief / task index.

### Non-Goals

- no `DailyNutritionSummary` shape change;
- no `hasMealLogs` / `mealLogCount` field;
- no resolver aggregation change;
- no Core calendar/painter change;
- no Supabase or persistence change.

## 2. Codebase Exploration

### Verified Evidence

- Source/config inspected: current `DailyNutritionSummary`, `DailyNutritionSummaryResolver`, Meal Diary providers/page, Core calendar decoration/painter contract, relevant integration/recovery/domain tests, canonical Meal Diary docs.
- Existing pattern to follow: Core deliberately distinguishes `null` (no progress decoration) from `0` (known-zero track). Nutrition already owns the semantic mapping from calorie truth to generic `TioDateDecoration`.
- Tests or validation already present: integration tests cover positive progress, future clamping, empty-day zero decoration expectation, target refresh and over-target semantics; recovery tests currently expect a zero decoration after range recovery.
- Tracker reconciliation: GitHub #317 remained open and reproducible on current main. No dedicated Linear mirror existed, so TNYX-257 was created. TNYX-240 remains `In Progress` only for future parser follow-ups; its S1 PR #302 is already merged and live QA is recorded, and no open PR existed at this task start.

## 3. Clarification

### Decisions Required or Made

| Decision | Status | Rationale | Owner |
|---|---|---|---|
| Should a logged date with exact zero calories show a zero ring? | Approved: No | Owner clarified that progress `0` must show no empty track, regardless of whether a log exists. | Owner |
| Add `hasMealLogs` to the read model? | Rejected | Both empty and logged-zero dates intentionally render no ring, so activity presence is unnecessary for this UI rule. | Engineering |
| Change Core `progress: 0` semantics? | Rejected | Core's reusable known-zero contract remains valid for other consumers. Nutrition owns this domain-specific suppression. | Engineering |

## 4. Architecture Design

### Chosen Approach

Keep the existing read model and repository flow. In `MealDiaryPage._calendarDecorationBuilder()`, return `null` when `summary.calorieProgress` is null or non-positive. Existing positive-progress semantics, target checks and percentage accessibility text remain unchanged.

### Ownership and Data Flow

```text
bounded MealLog range read + Nutrition target
→ DailyNutritionSummaryResolver
→ DailyNutritionSummary.calorieProgress
→ MealDiaryPage domain mapping
   progress <= 0 → null
   progress > 0  → TioDateDecoration
→ generic TioDateCalendar
```

### Alternative Rejected

Adding `hasMealLogs` / `mealLogCount` to `DailyNutritionSummary` was considered under the original #317 wording. It is unnecessary after the owner's stronger rule because both no-log zero and logged-zero are intentionally hidden. Avoiding the field keeps the slice smaller and prevents speculative model surface.

### Failure and Accessibility States

- range/target error behavior remains unchanged;
- stale decoration remains cleared during range errors;
- zero progress has no ring semantics because there is no progress decoration;
- positive progress keeps the existing raw percentage semantics, including over-target percentages;
- selected-date semantics and tonal fill remain independent.

## 5. Implementation Plan

- [x] Suppress non-positive Meal Diary calendar progress in `_calendarDecorationBuilder`.
- [x] Update empty/zero integration expectations to `null`.
- [x] Add/retain explicit positive-progress regression.
- [x] Update recovery expectations so retry does not reintroduce a zero track.
- [x] Update canonical Meal Diary doc from “empty day may supply 0.0” to positive-only ring eligibility.
- [x] Run source/test exact-head CI; validate this final metadata-only handoff head before review readiness.

## 6. Quality Review

### Validation Run

```text
Committed-diff audit at source/test/docs SHA d8c518a77f072f681d5af8efba0f7605a2d6d0f4:
- main is merge-base; scoped changed paths are limited to Meal Diary plus task governance.
- Core calendar files are unchanged.
- production delta is one guard: progress <= 0 returns no decoration.
- focused regression delta covers past empty, today empty after target refresh, logged exact-zero, and recovery/retry.
- existing positive (0.4) and over-target calendar tests remain in place.

Exact source/test + prior handoff head `9e9a7152b7ed935c46cf376ce6050f14912e10df`:
- Flutter CI #2709 / run `35925479132`: PASS.
- Bootstrap workspace: PASS.
- Analyze Flutter packages: PASS.
- Analyze Dart packages: PASS.
- Test Flutter packages: PASS.
- Test Dart packages: PASS.
- Commit attribution guard #48: PASS.
- Non-required `github-advanced-security` run #216 failed before analysis while creating its review request with `SessionModelError / CAPIError 400: The requested model is not supported`; no code/security finding was produced.

Not available in this connector-only session:
- local git status / git diff --check
- local Flutter analyze/test

The resulting task-handoff commit is metadata-only and still receives exact-head CI before review readiness.
```

### Review Findings and Resolution

| ID | Severity | Status | Finding | Observed at SHA | Evidence or follow-up |
|---|---|---|---|---|---|
| | | Open | | | |

## 7. Final Handoff

### Changed Files

- `.ai/tasks/README.md`
- `.ai/tasks/tnyx-257-meal-diary-positive-progress-ring.md`
- `apps/features/nutrition/lib/src/meal_diary/presentation/pages/meal_diary_page.dart`
- `apps/features/nutrition/test/meal_diary/meal_diary_daily_nutrition_integration_test.dart`
- `apps/features/nutrition/test/meal_diary/meal_diary_daily_nutrition_recovery_test.dart`
- `docs/screens/meal-diary.md`

### Actual Behavior

Meal Diary creates a calendar progress decoration only when exact `calorieProgress > 0`. Empty dates and logged dates with exact zero calories render no progress ring/track. The selected-day Daily Nutrition summary still reports known-zero `Eaten = 0`. Core retains its generic `progress: 0` known-zero semantics.

### Known Limitations

Local Flutter validation could not be executed through the GitHub/Linear connector session. Runtime/source CI is green at `9e9a7152`; this final task-record-only commit still receives exact-head CI before review readiness.

### Final Status

`REVIEW` — runtime/source validation green; final metadata-only exact-head CI pending before marking PR Ready for Review.
