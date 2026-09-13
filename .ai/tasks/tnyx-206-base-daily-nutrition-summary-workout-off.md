# TNYX-206 — N3A Base Daily Nutrition Summary (workout OFF)

**Status:** In progress  
**Primary owner:** `apps/features/nutrition`  
**Affected platforms:** Flutter phone Meal Diary

## Owner Approval and Scope Boundary

**Trigger:** New independently scoped product task/feature slice + product-visible UI/UX change  
**Approval status:** Approved  
**Approval evidence:** Owner said `go` after TNYX-205 PR #266 was squash-merged, local `main`/`origin/main` were both verified at `2866ded8a963b64a99e41b5007da4753a922c7cc`, and the post-merge working tree was clean.  
**Approved product/UI/data-shape boundaries:** Add the selected-day N3A Daily Nutrition Summary directly below the existing Meal Diary calendar; show workout-OFF `Target - Eaten = Remaining`; show Carbs/Protein/Fat/Fiber consumed-vs-target progress where truth is available; feed the calendar primary progress ring from the same selected-day budget/actual truth; preserve a structural seam for later N3B Workout term.  
**Explicit non-changes:** No Workout calorie calculation/term or N10 setting, no full N11 Eating Style UI, no Meal Diary redesign outside the approved summary/ring insertion, no Supabase table/column/migration/RLS change, no Core calendar visual/API redesign, no AI logging/Search/Saved/Recent work.

## Active Handoff

**Planning owner:** ChatGPT  
**Implementation owner:** ChatGPT  
**Review owner:** None active until implementation validation handoff  
**Implementation ownership state:** Active  
**Ownership transition:** Not applicable  
**Repository state last verified:** `main@2866ded8a963b64a99e41b5007da4753a922c7cc`; local post-merge sync explicitly confirmed clean by owner; fresh remote compare identical.  
**Branch:** `tnyx/tnyx-206-n3a-base-daily-nutrition-summary-workout-off`  
**HEAD SHA:** `2866ded8a963b64a99e41b5007da4753a922c7cc` at branch creation; this brief is the first branch commit.  
**Observed working-tree state:** Connector/API session; no local dirty tree is claimed.  
**Observed uncommitted/dirty files:** Not applicable / unavailable through connector session.  
**PR / tracker:** Linear TNYX-206; no PR yet.  
**Current implementation state:** Fresh audit complete; source implementation not started at brief creation.  
**Relevant execution surface:** Meal Diary selected-date read models, DailyNutritionBudget resolver, MealLog repository read boundary, Meal Diary page + calendar decoration.  
**Validation completed at SHA:** Historical prerequisite TNYX-205 exact-head CI is merged; no TNYX-206 validation yet.  
**Validation remaining:** Focused Nutrition tests/analyze, full Flutter CI on exact PR head, independent review/Codex review.  
**Current blocker:** None after TNYX-205 merge/sync.  
**Open review finding IDs:** None.  
**Next exact action:** Implement the bounded Nutrition read-model/range-read foundation, summary widget, page wiring, and focused regressions without expanding scope.

## Global UI / Design-System Guardrail

Read before source work:

- `AGENTS.md`
- `apps/features/AGENTS.md`
- `.ai/FEATURE_DEVELOPMENT.md`
- `.ai/tasks/design-system-token-consolidation.md`
- `apps/core/lib/src/theme/README.md`

TNYX-206 is an approved visible addition, but it is not permission for unrelated visual cleanup. The summary stays Nutrition-owned, reuses public Core components/primitives such as `TioCard`, `TioSpacing`, `TioSize`, theme semantic colors and Material progress primitives, and does not introduce a feature token bag or a new Core component without reuse evidence.

## 1. Discovery

### User Outcome

When the user browses a Meal Diary date, they can see that day’s calorie target/eaten/remaining and core nutrient progress, while the same calorie truth decorates the calendar date with a progress ring.

### Success Criteria

- Selected date is the single date identity for summary computation; browsing history never substitutes Today.
- Calories show `Target - Eaten = Remaining` with Workout excluded.
- Target calories come from `DailyNutritionBudget.strategyAdjustedTarget`.
- Eaten values come only from actual canonical MealLog rows for the selected local date.
- Remaining stays signed (over-budget may be negative); it is not display-clamped to zero.
- Carbs/Protein/Fat/Fiber compare consumed truth with canonical base targets; Standard strategy does not silently rescale them.
- Unknown target or consumed nutrient stays unavailable rather than becoming fake zero.
- A successful empty MealLog read is a known zero consumed day, not an unavailable day.
- Calendar ring uses the same budget + eaten rules; ring progress clamps to `0..1` while over-budget truth remains detectable in the summary model.
- Visible calendar dates are fetched in a bounded range, not one network query per day.
- Existing Diary date navigation, history, Quick Add/Edit and floating-action geometry remain intact.

### Scope

- Nutrition-owned daily summary domain/read model and resolver.
- Efficient inclusive MealLog local-date range read capability implemented by production and in-memory adapters without schema changes.
- Feature-side provider/composition seam for canonical Nutrition Targets repository.
- Selected-day summary state plus visible-range calendar-progress state.
- Nutrition-owned summary widget inserted below the existing calendar clearance and above selected-day meal history.
- Calendar `TioDateDecoration.progress` + accessible semantics supplied by Nutrition.
- Quick Add/Edit invalidation extended to refresh affected summary/ring truth.
- Focused domain/data/provider/widget/page regressions and canonical Meal Diary doc reconciliation.

### Non-Goals

- Workout calories / 4-value runtime layout / N10 setting.
- New Nutrition Schedule persistence or settings UI.
- Full N11 fasting/calorie-cycling implementation.
- MealLog delete/move/full editor.
- Any new Supabase schema, migration, RLS policy or duplicate daily-total table.
- A Core `TioProgress` component or calendar redesign.
- Unrelated Meal Diary spacing/card/calendar/FAB redesign.

## 2. Codebase Exploration

### Verified Evidence

- `MealDiaryPage` currently renders `TioDateCalendar`, a fixed calendar-handle clearance, then `MealDiaryHistoryView`; it intentionally passes no `decorationBuilder` because N3 was not implemented.
- `TioDateCalendar` already accepts caller-owned `TioDateDecorationBuilder`; Core never computes Nutrition semantics.
- `TioDateDecoration.progress` already distinguishes `null` (unavailable) from `0.0` (known zero) and requires a normalized `0..1` caller value.
- `DailyNutritionBudgetResolver` is merged from TNYX-205 and is the only strategy-adjusted target boundary. Standard currently returns the validated canonical target unchanged.
- `MealDiaryHistoryReadModel` depends on Meal Categories for non-empty section presentation and currently exposes only Calories/Protein section aggregates; deriving the N3 summary from this presentation model would couple nutrient truth to category-label availability.
- `NutritionSnapshot` supports canonical nutrient lookup with absent != zero semantics.
- `NutritionTargetsData` supports Calories, Protein, Carbs, Fat and Fiber with nullable unknown fields.
- `MealLogRepository` currently reads one `MealLogLocalDate`; `SupabaseMealLogRepository` filters the persisted `consumed_local_date`. No range read exists yet.
- Production app composition already overrides `mealDiaryMealLogRepositoryProvider` with the canonical app `mealLogRepositoryProvider`; canonical `nutritionTargetsRepositoryProvider` also exists in app composition.
- `nutritionTargetsDataProvider` intentionally maps a missing target row to an empty editable Settings model, so it must not be used by N3 where unavailable target truth must remain unavailable.
- Core theme/design-system docs provide `TioCard` and governed primitives; no reusable `TioProgress` component exists.

### Existing Pattern to Follow

- Provider-family selected-date reads keyed by repository identity + durable `MealLogLocalDate`.
- Repository persistence truth remains below presentation.
- All-known-or-unknown aggregation: if any logged entry lacks a nutrient, that consumed nutrient aggregate is unknown instead of a partial sum.
- Successful empty repository result can produce known zero totals because the complete selected-day actual set is known empty.

### Tests / Validation Already Present

- Meal Diary date/navigation/short-viewport/midnight tests protect current page behavior.
- Meal Diary history provider tests protect category grouping and absent-vs-known nutrient aggregates.
- TioDateCalendar tests cover supplied progress decorations and semantics.
- TNYX-205 resolver tests cover selected date, unavailable target and repository failures.

## 3. Clarification

### Decisions Required or Made

| Decision | Status | Rationale | Owner |
|---|---|---|---|
| Summary totals source | Locked | Read canonical MealLog entries directly through a Nutrition resolver; do not derive business truth from category-dependent presentation sections. | Nutrition |
| Empty day consumption | Locked | A successful complete empty MealLog read is known zero for N3 core consumed nutrients; this is different from a failed/unavailable read. | Nutrition |
| Partial nutrient aggregation | Locked | Any entry missing that nutrient makes the selected-day consumed aggregate unavailable; never display a partial sum as complete. | Nutrition |
| Macro/fiber target owner | Locked | Use `DailyNutritionBudget.baseTarget` in N3A; V1 strategy/workout rules do not silently scale macros/fiber. | Nutrition |
| Calorie target owner | Locked | Use `DailyNutritionBudget.strategyAdjustedTarget.caloriesKcal`. | Nutrition |
| Remaining | Locked | `target - eaten`, signed; negative means over budget and is not clamped. | Nutrition |
| Ring progress | Locked | `eaten / target`, visual value clamped to `0..1`; unavailable if target/eaten unavailable. | Nutrition |
| Visible range reads | Locked | Add optional `MealLogRangeReadRepository` capability and implement it in canonical production/in-memory adapters; avoid 7–31 separate Supabase queries. | Nutrition data boundary |
| Core changes | Locked | None expected; existing generic `TioDateDecoration` contract is sufficient. | Core remains unchanged |
| App composition | Locked | Add only the thin repository provider override needed to expose canonical Nutrition Targets to the feature, mirroring existing MealLog composition. | `apps/app` composition only |

## 4. Architecture Design

### Chosen Approach

Create a Nutrition-owned immutable daily summary/read model plus resolver that combines:

```text
explicit MealLogLocalDate
  + DailyNutritionBudgetResolver (canonical target → strategy target)
  + canonical MealLog actual rows
        ↓
DailyNutritionSummary
  - budget? (target unavailable stays unavailable)
  - consumed core nutrient snapshot/all-known totals
  - calorie remaining / raw over-budget truth
  - normalized ring progress when calculable
```

For the calendar, one inclusive range MealLog read + one budget range resolution produces per-date summaries/decorations for the visible week/month. No daily totals are persisted.

### Ownership and Data Flow

```text
apps/app composition
  -> canonical NutritionTargetsRepository + MealLogRepository
  -> Nutrition feature providers
  -> DailyNutritionSummary resolver/read model
  -> MealDiaryPage
       -> Nutrition summary widget
       -> TioDateCalendar(decorationBuilder: generic progress only)
       -> existing MealDiaryHistoryView
```

### Alternative Rejected

1. Deriving totals from `MealDiaryHistoryReadModel`: rejected because non-empty history additionally depends on Meal Categories label resolution and is a presentation grouping model, not the daily nutrient truth owner.
2. One `listByLocalDate` query for every visible calendar day: rejected because a month page could fan out into dozens of Supabase reads.
3. Persisting daily totals/targets: rejected because actual MealLogs and canonical targets already own truth and N3 requires derived rendering only.
4. Putting Nutrition progress semantics into Core: rejected because Core’s generic decoration contract is already sufficient.

### Failure and Accessibility States

- MealLog read failure is a retryable summary/calendar read failure; it is not converted to zero.
- Target repository `null` keeps target/remaining/ring unavailable while successful MealLog consumption can still remain truthful.
- Unknown individual nutrient displays an unavailable text alternative instead of a fabricated amount/bar.
- Calorie and nutrient values remain visible as text; progress bars/rings are supplemental.
- Calendar decorations carry Nutrition-owned semantic labels.
- Compact widths must wrap/reflow without overflow; dark/light use semantic theme colors.

## 5. Implementation Plan

- [ ] Add optional inclusive local-date range read capability; implement in Supabase + in-memory adapters with focused data tests.
- [ ] Extend `DailyNutritionBudgetResolver` with bounded multi-date resolution so calendar consumers still use the same budget owner without repeated canonical target reads.
- [ ] Add `DailyNutritionSummary` model/resolver with exact null/zero/over-budget rules and focused domain tests.
- [ ] Add feature providers for canonical targets repo, selected-day summary and visible-range summaries.
- [ ] Track calendar visible range in Nutrition date state without changing selection/navigation behavior.
- [ ] Add Nutrition-owned Daily Summary widget using governed Core UI/primitives.
- [ ] Wire summary + calendar decorations into `MealDiaryPage` and extend create/edit invalidation.
- [ ] Add app composition override for the canonical Nutrition Targets repository.
- [ ] Add light/dark, compact-width, accessibility, selected-date, unavailable/zero and over-budget widget/page regressions.
- [ ] Reconcile `docs/screens/meal-diary.md` once runtime behavior is implemented.
- [ ] Audit exact branch scope, open Draft PR, run exact-head CI, independently review and trigger Codex review.

## 6. Quality Review

### Validation Run

```text
Not run yet for TNYX-206.
```

### Review Findings and Resolution

| ID | Severity | Status | Finding | Observed at SHA | Evidence or follow-up |
|---|---|---|---|---|---|
| None | — | — | No review pass yet. | — | — |

## 7. Final Handoff

### Changed Files

Pending implementation.

### Actual Behavior

Pending implementation.

### Known Limitations

- N3A intentionally has no Workout term. N3B remains the later consumer/integration slice.
- TNYX-205 currently supports Standard strategy only; future N11 date-specific strategies extend the existing budget resolver seam rather than the summary consumer contract.

### Final Status

`PARTIAL` — implementation in progress.
