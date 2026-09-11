# TNYX-199 — N4B Manual MealLog selected-day Diary sections & read-only cards

**Status:** Validated
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
**Review owner:** PR review / owner device review
**Implementation ownership state:** Complete
**Ownership transition:** Not applicable
**Repository state last verified:** 2026-09-11 through GitHub repository API. Base `main` = `7a96e382d36d295f821826cb9d49fd38b0f533a9`; implementation source head `a25d53e5b6e857d737327fde94295c23a1b2be52` was `11 ahead / 0 behind`, with the same merge base and 9 scoped changed files. This API-based session has no local checkout, so local `git status -sb` was unavailable and no local user work was touched.
**Branch:** `tnyx/tnyx-199-n4b-manual-meallog-selected-day-diary-sections-read-only`
**HEAD SHA:** This final handoff/evidence commit follows validated implementation source SHA `a25d53e5b6e857d737327fde94295c23a1b2be52`; use live PR #258 metadata for the resulting branch head.
**Observed working-tree state:** Not applicable in API-based implementation session; repository writes were made only through the GitHub branch API.
**Observed uncommitted/dirty files:** Not observable through repository API; no local files were modified by this session.
**PR / tracker:** Draft PR #258; Linear `TNYX-199` moves to `In Review` after this validated handoff; parent `TNYX-57` remains the broader backlog owner.
**Current implementation state:** Bounded read-only selected-day Diary history slice implemented and CI-validated; no mutation behavior added.
**Relevant execution surface:** `apps/features/nutrition/lib/src/meal_diary/**`, `apps/app/lib/main.dart`, focused Nutrition Meal Diary tests, `docs/screens/meal-diary.md`, this task brief.
**Validation completed at SHA:** `a25d53e5b6e857d737327fde94295c23a1b2be52` — Flutter CI #2395 / run `34634021191` passed bootstrap, Flutter analyze, Dart analyze, all Flutter-package tests, and all Dart-package tests.
**Validation remaining:** Final PR review and owner visual/device review. If implementation source changes after `a25d53e5...`, rerun exact-source validation; governance-only evidence edits do not supersede the recorded source result.
**Current blocker:** None.
**Open review finding IDs:** None.
**Next exact action:** Review PR #258. Do not merge until explicitly authorized.

**Repository note:** An accidental unused sibling remote branch `tnyx/tnyx-199-n4b-manual-meallog-selected-day-diary-sections-read-only-check` exists only from the base SHA and is not part of PR #258. It was not deleted because branch deletion requires explicit owner instruction.

## Global UI / Design-System Guardrail

This slice follows `apps/features/AGENTS.md`, `.ai/tasks/design-system-token-consolidation.md`, and `apps/core/lib/src/theme/README.md`.

- Reuses `package:tio_core/core.dart`, `TioCard`, `TioButton`, and governed theme roles.
- Meal Diary section/card composition stays feature-owned; no new Core component/token contract was introduced.
- No feature-local token/theme catalog was introduced.
- The visible change is limited to approved persisted MealLog history rendering plus explicit loading/empty/error states.

## 1. Discovery

### User Outcome

A user browsing any selectable Diary date can see actual manual meals saved for that intended local date, grouped by durable Meal Category and ordered by latest activity, with compact nutrition and note/time presentation that honors Meal Diary settings.

### Success Criteria

- Selected date loads canonical `MealLogEntry` history from `MealLogRepository.listByLocalDate`.
- One durable log produces one card.
- Sections are ordered by latest actual entry; entries within a section are newest first.
- Section labels resolve current retained `MealCategory.displayName`, including archived historical categories.
- Missing calorie/protein facts remain unknown instead of becoming fabricated zero.
- `showMealTimes`, `mealNotesEnabled`, and `showMealNotePreview` affect presentation only.
- Unnamed Quick Add history renders `Quick Add` only when `captureSource == MealLogCaptureSource.quickAdd`; stored `mealName` remains null.
- Date changes are race-safe so a slower old request cannot overwrite the newer selection.
- Loading, empty, and retryable error states are explicit.

### Scope

Selected-day read model/provider, repository/category composition, read-only sections/cards, focused tests, and Meal Diary docs reconciliation.

### Non-Goals

Everything under Explicit non-changes above. This slice does not mutate MealLog history.

## 2. Codebase Exploration

### Verified Evidence

- `MealLogRepository.listByLocalDate(MealLogLocalDate)` owns selected-day canonical history and deterministic newest-first repository order.
- `MealLogEntry` carries durable category identity, nullable name/note, canonical `consumedAt`, persisted local-date identity, timezone/offset context, capture source, and manual nutrition snapshot.
- `NutritionSnapshot` distinguishes absent nutrients from known zero values.
- `MealCategoriesConfig.findById` resolves retained archived category identities.
- `MealDiaryDisplayPreferences` already owns the three presentation flags.
- `MealDiaryDateController` owns selected date and future-date exclusion.
- App composition already owns canonical `mealLogRepositoryProvider` and `mealCategoriesRepositoryProvider`.
- Existing Core `TioCard` is sufficient; no new reusable visual contract was justified.

### Existing pattern followed

Feature provider/read model sequences repository reads; widgets render immutable state. `apps/app` only overrides the feature repository seam with the canonical app repository.

## 3. Clarification

| Decision | Status | Rationale | Owner |
|---|---|---|---|
| Blank Quick Add name displays `Quick Add` | Owner-approved | Capture source already records how it was logged; fallback is presentation-only | Owner / Nutrition |
| Blank non-Quick-Add name gets no `Quick Add` fallback | Locked | Source-aware fallback must not invent identity | Nutrition |
| Missing calories/protein stay unknown | Locked | `NutritionSnapshot` differentiates absent from zero | Shared/Nutrition |
| Section ordering ignores configured category order | Locked | N4 requires latest actual activity | TNYX-57 |
| Archived historical categories remain resolvable | Locked | Retained identity protects history | TNYX-67 |
| Display flags never change data/chronology | Locked | N14 is presentation-only | TNYX-198 |
| Historical visible time never silently uses current device timezone | Locked | Stored offset/context protects historical meaning | TNYX-114 |

## 4. Architecture Design

### Chosen Approach

`MealDiaryHistoryRequest` keys a `FutureProvider.autoDispose.family` by repository identity plus durable local date. It reads MealLogs and Meal Categories concurrently, builds immutable section/card models, and lets `MealDiaryPage` render the watched selected-date result. Switching dates switches provider keys, preventing a late old-date completion from publishing into the new date.

### Ownership and Data Flow

```text
MealDiaryDateController.selectedDate
        ↓
MealDiaryHistoryRequest
        ↓
mealDiaryHistoryProvider
        ├─ MealLogRepository.listByLocalDate(...)
        └─ MealCategoriesRepository.read()
                ↓
immutable section/card read model
                ↓
MealDiaryHistoryView
        + MealDiaryDisplayPreferences
                ↓
TioCard / governed Core rendering
```

### Alternative Rejected

Direct repository calls/grouping in `MealDiaryPage` were rejected because they would mix persistence sequencing, aggregation, stale-result handling and rendering inside a widget.

### Failure and Accessibility States

- Initial read renders an explicit loading state.
- Successful empty read renders `Nothing is logged for this day.`
- Failure renders clear copy plus governed Retry action.
- Cards/section totals have text equivalents and do not rely on color.
- Note icon is secondary and semantically labeled; preview is at most one ellipsized line.
- Unknown nutrient facts are omitted rather than shown as zero.

## 5. Implementation Plan

- [x] Add immutable selected-day Diary request/read models with date-keyed race isolation.
- [x] Resolve retained categories and aggregate calories/protein per section without partial totals.
- [x] Add source-aware `Quick Add` title fallback and stored-offset historical-time reconstruction.
- [x] Inject canonical MealLog repository through app composition without moving business logic into `apps/app`.
- [x] Render loading, retryable error, empty, section headers and compact governed cards.
- [x] Apply N14 display preferences without changing chronology or stored notes.
- [x] Preserve existing calendar/FAB/Add Food/Quick Add shell behavior.
- [x] Add focused provider/widget tests for ordering, archived categories, missing nutrients, fallback, preferences and stale date responses.
- [x] Reconcile `docs/screens/meal-diary.md` with current persistence/read runtime.
- [x] Run parent-to-head scope audit and CI validation.

## 6. Quality Review

### Validation Run

```text
Base SHA: 7a96e382d36d295f821826cb9d49fd38b0f533a9
Validated implementation SHA: a25d53e5b6e857d737327fde94295c23a1b2be52
Scope audit: 11 ahead / 0 behind, exact merge base, 9 changed files, all TNYX-199-owned
Flutter CI #2395 / run 34634021191 / job 103377445899
- Bootstrap workspace: PASS
- Analyze Flutter packages: PASS
- Analyze Dart packages: PASS
- Test Flutter packages: PASS
- Test Dart packages: PASS
```

Local validation was not separately run because this session operates through repository APIs and had no usable local checkout; GitHub CI supplied the canonical full-workspace validation.

### Review Findings and Resolution

| ID | Severity | Status | Finding | Observed at SHA | Evidence or follow-up |
|---|---|---|---|---|---|
| T199-R1 | Medium | Resolved | New widget tests manually disposed `ChangeNotifier` instances also owned by `ProviderScope`, risking double-dispose | `dea8c739...` | Removed duplicate teardown in `4ce94807...`; CI #2395 passed |
| T199-R2 | Low | Resolved | Retry closure needed explicit nullable-request narrowing for static safety | `985a2204...` | Explicit non-null request in `a25d53e5...`; Flutter analyze passed |

## 7. Final Handoff

### Changed Files

- `.ai/tasks/tnyx-199-meal-diary-selected-day-read-cards.md`
- `apps/app/lib/main.dart`
- `apps/features/nutrition/lib/src/meal_diary/meal_diary.dart`
- `apps/features/nutrition/lib/src/meal_diary/meal_diary_history_providers.dart`
- `apps/features/nutrition/lib/src/meal_diary/presentation/pages/meal_diary_page.dart`
- `apps/features/nutrition/lib/src/meal_diary/presentation/widgets/meal_diary_history_view.dart`
- `apps/features/nutrition/test/meal_diary/meal_diary_history_provider_test.dart`
- `apps/features/nutrition/test/meal_diary/meal_diary_history_view_test.dart`
- `docs/screens/meal-diary.md`

### Actual Behavior

- Selected Diary date reads canonical persisted manual MealLogs.
- History groups by durable Meal Category and resolves current retained display labels.
- Latest-activity section renders first; newest entry renders first within a section.
- Known section calories/protein aggregate; missing nutrient facts do not become zero or partial authoritative totals.
- Each durable MealLog is one compact governed card.
- Persisted meal name is used when present; unnamed Quick Add history shows `Quick Add` only as a display fallback.
- Meal time/note visibility follows N14 preferences without mutating chronology or note data.
- Historical wall time uses stored UTC offset when available and is omitted rather than guessed when safe reconstruction is unavailable.
- Loading, empty, retryable error and rapid-date-switch stale-result behavior are covered.

### Known Limitations

Quick Add create/save activation, edit/delete/move, card-to-editor navigation, detailed item/photo rendering, daily summary/calendar rings and broader offline/replay mutation behavior remain intentionally deferred to their owning slices.

### Final Status

`REVIEW`
