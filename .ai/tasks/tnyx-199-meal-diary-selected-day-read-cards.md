# TNYX-199 — N4B Manual MealLog selected-day Diary sections & read-only cards

**Status:** In progress
**Primary owner:** `apps/features/nutrition`
**Affected platforms:** Flutter phone app

## Owner Approval and Scope Boundary

**Trigger:** New independently scoped product task/feature slice + product-visible UI change
**Approval status:** Approved
**Approval evidence:** Owner approved proceeding after the fresh N0/readiness audit and explicitly approved `Quick Add` as a source-aware display-only fallback for unnamed Quick Add history cards.
**Approved product/UI/data-shape boundaries:** Selected-day canonical MealLog reads, dynamic Meal Category sections, compact read-only Diary cards, N14 display preferences, loading/empty/error states, focused tests, and stale Meal Diary documentation reconciliation. No data-shape change.
**Explicit non-changes:** No Quick Add create/save activation, edit/delete/move, card-to-editor navigation, item-level detail/photos, N3 daily summary/calendar rings, Supabase schema/RLS/migration, Meal Category management changes, or Meal Plan.

## Active Handoff

**Planning owner:** Current AI session
**Implementation owner:** Current AI session
**Review owner:** Unassigned
**Implementation ownership state:** Active
**Ownership transition:** Not applicable
**Repository state last verified:** 2026-09-11 through GitHub repository API. `main` = `7a96e382d36d295f821826cb9d49fd38b0f533a9`; no open PRs were present at readiness time. This API-based session has no local working tree, so local `git status -sb` is not available; equivalent remote branch/base evidence is used and local user work is untouched.
**Branch:** `tnyx/tnyx-199-n4b-manual-meallog-selected-day-diary-sections-read-only`
**HEAD SHA:** starts from `7a96e382d36d295f821826cb9d49fd38b0f533a9`; refresh from GitHub after each commit.
**Observed working-tree state:** Not applicable in API-based implementation session; no local checkout is modified.
**Observed uncommitted/dirty files:** Not observable through repository API; no local files are modified by this session.
**PR / tracker:** Linear `TNYX-199` In Progress; parent `TNYX-57` Backlog; no PR yet.
**Current implementation state:** Readiness complete; implementation not yet started.
**Relevant execution surface:** `apps/features/nutrition/lib/src/meal_diary/**`, `apps/app/lib/app/router.dart`, focused Nutrition tests, `docs/screens/meal-diary.md`, this task brief.
**Validation completed at SHA:** Not run yet.
**Validation remaining:** focused Nutrition tests/analyze plus parent-to-head scope audit; broader checks as practical.
**Current blocker:** None.
**Open review finding IDs:** None.
**Next exact action:** Build the selected-day read model/controller, wire canonical repositories at app composition, render governed read-only sections/cards, add focused tests, then validate and open a draft/review PR without merging.

## Global UI / Design-System Guardrail

This slice follows `apps/features/AGENTS.md`, `.ai/tasks/design-system-token-consolidation.md`, and `apps/core/lib/src/theme/README.md`.

- Reuse `package:tio_core/core.dart` and existing `TioCard`/theme roles.
- Keep Meal Diary section/card composition feature-owned; no new Core component or token contract is justified by one consumer.
- Do not introduce feature-local theme/token bags or raw repeated visual values.
- The visible change is limited to the owner-approved rendering of actual persisted MealLog history and its explicit loading/empty/error states.

## 1. Discovery

### User Outcome

A user browsing any selectable Diary date can see the actual manual meals saved for that intended local date, grouped by their durable Meal Category, ordered by latest activity, with compact nutrition and note/time presentation that honors Meal Diary settings.

### Success Criteria

- Selected date loads canonical `MealLogEntry` history from `MealLogRepository.listByLocalDate`.
- One durable log produces one card.
- Sections are ordered by latest actual entry; entries within each section are newest first.
- Section label resolves through current retained `MealCategory.displayName`, including archived historical categories.
- Known calories/protein aggregate correctly; missing nutrient facts remain unknown instead of becoming zero.
- `showMealTimes`, `mealNotesEnabled`, and `showMealNotePreview` affect presentation only.
- Unnamed Quick Add history renders `Quick Add` only when `captureSource == MealLogCaptureSource.quickAdd`; persisted `mealName` remains null.
- Selected-date changes are race-safe and cannot let an older async result overwrite the newer selection.
- Loading, empty, and retryable error states are explicit.

### Scope

Selected-day read controller/read model, repository/category composition, read-only sections/cards, focused widget/controller tests, and Meal Diary docs reconciliation.

### Non-Goals

Everything under Explicit non-changes above. In particular, this slice does not mutate MealLog history.

## 2. Codebase Exploration

### Verified Evidence

- `MealLogRepository.listByLocalDate(MealLogLocalDate)` exists and requires grouping by persisted `consumedLocalDate`; it returns deterministic newest-first chronology with opaque-id tie-break.
- `MealLogEntry` stores `mealCategoryId`, nullable `mealName`, nullable `note`, canonical `consumedAt`, persisted `consumedLocalDate`, timezone/offset context, `captureSource`, and a nullable aggregate-level `manualNutritionSnapshot` that is required for current manual construction.
- `NutritionSnapshot` distinguishes absent nutrients from explicitly-known zero values.
- `MealCategoriesConfig.findById` can resolve retained archived categories; custom ordering is not Diary ordering.
- `MealDiaryDisplayPreferences` already owns the three required presentation flags and its controller falls back safely to defaults on local-preference read failure.
- `MealDiaryDateController` owns selected date and date policy; future dates remain unreachable.
- App composition already owns canonical `mealLogRepositoryProvider` and `mealCategoriesRepositoryProvider`.
- `MealDiaryPage` currently does not consume MealLog history and retains stale placeholder/history comments.
- Existing Core `TioCard` supports governed surface variants and optional tap behavior; no new Core card contract is needed.
- `docs/screens/meal-diary.md` is stale where it says no MealLog data source/persistence exists.

### Existing pattern to follow

Feature controller/notifier sequences repository reads; widgets render immutable read state. App shell injects canonical repositories. UI consumes Core components and runtime theme roles.

### Tests or validation already present

- Meal Diary widget tests cover calendar/date navigation, rollover, lifecycle, and short viewport behavior.
- MealLog repository tests cover selected-day read behavior.
- Meal Categories tests cover retained category identity/config resolution.

## 3. Clarification

### Decisions Required or Made

| Decision | Status | Rationale | Owner |
|---|---|---|---|
| Blank Quick Add name displays `Quick Add` | Owner-approved | Capture source already records how the log was created; fallback is presentation only and must not fabricate stored `mealName` | Owner / Nutrition |
| Blank non-Quick-Add name gets no fabricated Quick Add title | Locked | Fallback is source-aware, not a universal substitute for missing meal identity | Nutrition |
| Missing calories/protein stay unknown | Locked | `NutritionSnapshot` explicitly distinguishes absence from known zero | Shared/Nutrition contract |
| Section ordering ignores user category order | Locked | TNYX-57 requires latest actual activity ordering | TNYX-57 |
| Historical category can be archived | Locked | Retained category identity remains resolvable for history | TNYX-67 |
| Display flags never change chronology/data | Locked | N14 display preferences are presentation-only | TNYX-198 |
| Historical time display must not silently use current-device timezone | Locked | TNYX-114 separates canonical instant, intended local date, and logging timezone/offset context | TNYX-114 |

## 4. Architecture Design

### Chosen Approach

Add a Nutrition-owned immutable selected-day read model plus controller that loads MealLog history and Meal Categories together, builds presentation-safe section/entry models, and publishes loading/data/error state. `MealDiaryPage` observes date + display preferences and delegates the history body to the read model.

### Ownership and Data Flow

```text
MealDiaryDateController.selectedDate
        ↓
MealDiary selected-day controller
        ├─ MealLogRepository.listByLocalDate(MealLogLocalDate)
        └─ MealCategoriesRepository.read()
                ↓
        immutable section/card read model
                ↓
MealDiaryPage / feature-owned widgets
        + MealDiaryDisplayPreferences
                ↓
        governed TioCard/theme rendering
```

App composition injects the existing canonical repositories. No widget reaches Supabase directly.

### Alternative Rejected

Do not group/read directly inside `MealDiaryPage` with `FutureBuilder` and direct repository calls. That would mix repository sequencing, grouping/aggregation, stale-result handling, and presentation in the widget, contrary to repository/controller boundaries and harder to test deterministically.

### Failure and Accessibility States

- Initial load shows an explicit loading state.
- Empty successful read shows an explicit empty-day message.
- Read failure preserves no fabricated history and offers a retry action.
- Card/section text does not rely on color alone.
- Note icon is semantic/secondary; note preview is one line with ellipsis.
- Unknown nutrient amounts are omitted rather than rendered as zero.

## 5. Implementation Plan

- [ ] Add immutable selected-day Diary read models and controller with request-generation race protection.
- [ ] Resolve categories and aggregate known calories/protein per section.
- [ ] Add source-aware title fallback and deterministic stored-time presentation helper.
- [ ] Wire `MealLogRepository` and `MealCategoriesRepository` into `MealDiaryPage` from app composition without moving business logic into `apps/app`.
- [ ] Render loading, error/retry, empty, section headers, and compact governed `TioCard` entries.
- [ ] Apply N14 display preferences without changing ordering/data.
- [ ] Preserve existing calendar/FAB/Quick Add shell behavior.
- [ ] Add focused controller/read-model and widget tests including stale-response, archived category, missing nutrient, Quick Add fallback, preference toggles, and ordering.
- [ ] Reconcile `docs/screens/meal-diary.md` with current persisted/read runtime.
- [ ] Refresh this handoff and run parent-to-head scope audit/validation.

## 6. Quality Review

### Validation Run

```text
Not run yet.
```

### Review Findings and Resolution

| ID | Severity | Status | Finding | Observed at SHA | Evidence or follow-up |
|---|---|---|---|---|---|
| | | | | | |

## 7. Final Handoff

### Changed Files

Not yet implemented.

### Actual Behavior

Not yet implemented.

### Known Limitations

Create/save, edit/delete/move, card-to-editor navigation, daily summary/rings, and detailed item/photo rendering remain intentionally deferred.

### Final Status

`PARTIAL`
