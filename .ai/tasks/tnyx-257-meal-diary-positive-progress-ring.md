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
**HEAD SHA:** `5270c56031a4012ba52122d64de994af2a3c85cd` before this task brief commit  
**Observed working-tree state:** Remote branch only; no local checkout available in this tool session.  
**Observed uncommitted/dirty files:** Unavailable; no local-worktree claim.  
**PR / tracker:** GitHub #317; Linear TNYX-257 (`In Progress`), parent TNYX-56, related TNYX-206.  
**Current implementation state:** Governance/readiness complete; source edits not yet started.  
**Relevant execution surface:** `MealDiaryPage._calendarDecorationBuilder`, Daily Nutrition integration/recovery tests, `docs/screens/meal-diary.md`.  
**Validation completed at SHA:** Not run yet for this slice.  
**Validation remaining:** Focused Nutrition tests, package analyze/tests as available, exact-head GitHub CI.  
**Current blocker:** None.  
**Open review finding IDs:** None.  
**Next exact action:** Make the smallest Nutrition-owned caller change so non-positive progress returns no decoration, update focused regressions and canonical Meal Diary docs, then validate.

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

- [ ] Suppress non-positive Meal Diary calendar progress in `_calendarDecorationBuilder`.
- [ ] Update empty/zero integration expectations to `null`.
- [ ] Add/retain explicit positive-progress regression.
- [ ] Update recovery expectations so retry does not reintroduce a zero track.
- [ ] Update canonical Meal Diary doc from “empty day may supply 0.0” to positive-only ring eligibility.
- [ ] Run focused validation and exact-head CI.

## 6. Quality Review

### Validation Run

```text
Not run yet.
```

### Review Findings and Resolution

| ID | Severity | Status | Finding | Observed at SHA | Evidence or follow-up |
|---|---|---|---|---|---|
| | | Open | | | |

## 7. Final Handoff

### Changed Files

Pending implementation.

### Actual Behavior

Pending implementation.

### Known Limitations

None known inside the approved scope.

### Final Status

`REVIEW`
