# TNYX-272 — W3A2b Exercises screen & route

**Status:** In progress
**Primary owner:** `apps/features/workout` (presentation), with route contract in `apps/core` and router wiring in `apps/app`
**Affected platforms:** Phone (Android + iOS). Wear OS / watchOS: none.

## Owner Approval and Scope Boundary

**Trigger:** New independently scoped product task/feature slice (product-visible UI + route)
**Approval status:** Approved
**Approval evidence:** Owner instruction "Start TNYX-272 — W3A2b Exercises screen & route" (2026-09-25), plus the Linear TNYX-272 approved UI/route contract and its owner contract update (list thumbnail, 2026-09-25). Owner top-bar revision (2026-09-25, after the first Draft PR commit, with the Tnyx-hub Exercise library top bar as reference): search is a top-bar icon, the field is not always open, and filter is also a top-bar icon.
**Approved product/UI/data-shape boundaries:**

- Route `/workout/exercises` as `AppRoutes.workoutExercises`, nested in the Workout branch; standard AppBar/back; bottom navigation hidden; direct deep link follows `/workout` behavior; no `/explore/...` route; no temporary production entry.
- Top bar: back, title `Exercises`, search icon, filter icon. The search icon swaps the title for a `Search exercises` field with a close action (clears the text), and the field is never open by default. The filter icon (primary color while filters are active) opens a bottom sheet with Muscle / Equipment / Category single-select filters, `Clear all`, `Show results`. Reference-only extras (create `+`, category icon row) are excluded.
- Row: thumbnail (canonical `ExerciseMedia.urlFor`, image then thumbnail kind), name, `Primary equipment • Muscle group`; text-only when media is unusable; no icon, chevron, favorite/folder action, video or tap behavior.
- States: loading, empty catalog, search/filter no-match, missing catalog, malformed catalog, unexpected failure; no Retry for bundled-asset failures.

**Explicit non-changes:** No Workout Home entry, Library (W6A), Exercise Detail (W3B), Favorites/Custom/Folders (W3C–W3E), video, standards, Supabase/persistence, Wear OS/watchOS UI, shared catalog package move, new icons, design-system refactors. No Supabase table/column change. Owner files under `apps/core/assets/**` stay untracked and untouched.

## Active Handoff

**Planning owner:** Claude (this session)
**Implementation owner:** Claude (this session)
**Review owner:** Codex review on the PR; owner final review
**Implementation ownership state:** Active
**Ownership transition:** Not applicable
**Repository state last verified:** 2026-09-25, local `main` = `origin/main` = GitHub `main` = `18bef68a`
**Branch:** `tnyx/tnyx-272-w3a2b-exercises-screen-route` (from `18bef68a`)
**HEAD SHA:** see PR head (implementation committed on top of `18bef68a`)
**Observed working-tree state:** clean except owner-untracked `apps/core/assets/{exercises,ic_body_part,ic_equipment,musclemap}/`
**Observed uncommitted/dirty files:** none after commit. During implementation (2026-09-25, ~18:53 IST) the four owner-untracked folders `apps/core/assets/{exercises,ic_body_part,ic_equipment,musclemap}/` disappeared from the working tree. No command in this task targeted that path. They are not in the Recycle Bin, and the cause is not established. They were never staged; reported to the owner, not restored.
**PR / tracker:** Linear TNYX-272 (In Progress); Draft PR (see Final Handoff)
**Current implementation state:** Implementation and local validation complete; Draft PR handoff
**Relevant execution surface:** `apps/features/workout/lib/src/presentation/explore/exercises/`, `apps/core/lib/src/routing/routes/app_routes.dart`, `apps/app/lib/app/router.dart`, `apps/app/lib/app/app_mode/app_mode_route_policy.dart`
**Validation completed at SHA:** working tree = committed head (see Validation Run)
**Validation remaining:** GitHub CI on the PR head; owner review
**Current blocker:** none
**Open review finding IDs:** none
**Next exact action:** owner review of the Draft PR; Ready/merge only on a separate owner instruction

## Global UI / Design-System Guardrail

Read `.ai/tasks/design-system-token-consolidation.md` guardrails, `apps/core/lib/src/theme/README.md` and `apps/features/AGENTS.md`. Consume `package:tio_core/core.dart`: `TioInput` (search), `TioButton` (filter action and sheet actions), `showTioEditorSheet` / `TioEditorSheet` (filter sheet), `TioGroupCard` (list grouping), governed `TioSpacing` / `TioRadius` / `TioSize` / typography and `context.tioColors`. No feature token bag; no new core component (no reuse evidence yet).

## 1. Discovery

### User Outcome

A phone user can open the dedicated Exercises screen, see every active built-in Exercise with its image, search by name, and narrow by one Muscle, Equipment and/or Category value.

### Success Criteria

- `/workout/exercises` renders the Exercises screen inside the Workout branch with AppBar/back and no bottom navigation.
- A direct deep link lands on the screen with `/workout` beneath it, and follows the same onboarding/App Mode gating as `/workout`.
- Search and filters use `ExerciseCatalogQuery`; widgets never read JSON or the repository directly.
- Each row shows the thumbnail chosen by `ExerciseMedia.urlFor` for the viewer's gender; a missing or failed image leaves a clean text-only row.
- All six states render controlled copy; bundled-asset failures have no Retry.
- No Workout Home entry exists.

### Scope

Workout-owned controller/state, Exercises page, search, filter sheet, rows, states; `AppRoutes.workoutExercises`; nested router wiring; App Mode redirect for nested Workout paths; tests; docs.

### Non-Goals

See Explicit non-changes above.

## 2. Codebase Exploration

### Verified Evidence

- Source/config inspected: `ExerciseCatalog`, `ExerciseCatalogQuery`, `ExerciseCatalogRepository`, `AssetBundleExerciseCatalogSource` and typed source exceptions (`apps/features/workout/lib/src/{domain,data}/exercises/`); `Exercise` / `ExerciseMedia` (`apps/shared/lib/src/workout/`); `AppRoutes` / `FeatureRoutes` / `ChromePolicy` (`apps/core/lib/src/routing/routes/`); `goRouterProvider`, `shellChromePolicyForPath` (`apps/app/lib/app/router.dart`); `appModeRedirect` (`apps/app/lib/app/app_mode/app_mode_route_policy.dart`); `profileDataProvider` (`apps/app/lib/app/network_providers.dart`, exposes `ProfileGender`).
- Existing pattern to follow: `ChangeNotifier` controllers exposed through `ChangeNotifierProvider.autoDispose` (`workoutDateControllerProvider`, Meal Diary); AppBar pages (`ArchivedMealCategoriesPage`, `MealDiarySettingsPage`); feature `ChoiceChip` selection inside `TioEditorSheet` (`glass_size_bottom_sheet.dart`); router passes app-owned values into feature pages by constructor (`WorkoutHomePage(resolvedFirstDayOfWeek:)`).
- Tests or validation already present: catalog source/parser/query tests; `app_mode_router_test.dart` (non-root shell paths → `ChromePolicy.noBottomBar`); `app_mode_route_policy_test.dart`; no golden files exist in the repository.
- Catalog facts (`catalogVersion` 2): 101 rows; every row has a male `imageUrl`; 4 rows also carry `thumbnailUrl`; muscle groups 10, equipment 11, categories 4, all snake_case tokens.

### Tracker reconciliation (2026-09-25)

- Linear TNYX-272: Backlog → In Progress; blocker TNYX-274 Done; no comments.
- Linear TNYX-270 description still says "text-only list / no remote media" — superseded by the TNYX-272 owner contract update (list thumbnail, 2026-09-25) and TNYX-274; not a blocker.
- `docs/screens/exercise-search.md` says "No route exists yet" — updated by this slice.
- GitHub: #343/#344 merged; no TNYX-272 branch, PR or issue existed.

## 3. Clarification

### Decisions Required or Made

| Decision | Status | Rationale | Owner |
|---|---|---|---|
| Route chrome `ChromePolicy.noBottomBar` nested under `/workout` | Made | Approved "bottom nav hidden" + branch nesting; nested shell paths already resolve to `noBottomBar` | Engineering |
| Nested Workout paths inherit `/workout` onboarding/App Mode gating in `appModeRedirect` | Made | "Deep-link fallback follows approved `/workout` behavior"; today only exact shell roots are gated | Engineering |
| Profile gender → `ExerciseMediaGender` mapped in `apps/app` (`exerciseMediaGenderForProfile`) and supplied by overriding the Workout-declared `exerciseViewerMediaGenderProvider` in `main.dart` | Made | Workout cannot import Profile; follows the existing feature-provider override pattern (Meal Diary repositories). `ref.listen` re-resolves thumbnails when the profile loads without reloading the catalog or clearing the search; the controller owns media selection through `ExerciseMedia.urlFor` | Engineering |
| Thumbnail = `urlFor(image) ?? urlFor(thumbnail)` | Made | Linear row contract (imageUrl, falling back to thumbnailUrl) | Owner contract |
| Search applies immediately (no debounce) | Made | Local query over a bundled catalog of ~100 rows; debounce adds timers without benefit | Engineering |
| Filter options derived from active catalog values; labels humanized from taxonomy tokens (`ez_bar` → `EZ bar`) | Made | No existing label registry; controlled display copy stays in presentation | Engineering |
| Filter sheet edits a draft; `Show results` applies, `Clear all` clears the draft | Made | Standard sheet semantics inside approved controls | Engineering |
| Unsupported schema version shown as malformed catalog | Made | Both mean this app version cannot read its bundled catalog | Engineering |
| No Retry on any failure state | Made | All failures come from the bundled asset; no approved Retry control | Owner contract |
| Search and filter move into the top bar as icons; search field opens on demand with autofocus and a clear-on-close action; filter icon hidden while searching | Made | Owner top-bar revision matching the Tnyx-hub reference; search-mode state lives in the controller (`isSearching`) | Owner |

## 4. Architecture Design

### Chosen Approach

```text
ExerciseCatalogRepository (AssetBundleExerciseCatalogSource via exerciseCatalogRepositoryProvider)
        ↓
ExercisesController (ChangeNotifier): load, map failures, hold query + media gender
        ↓ ExerciseCatalogQuery.apply
ExercisesState (immutable): status, items (Exercise + thumbnail Uri + metadata label), filter options
        ↓
ExercisesPage → search TioInput / filter sheet / rows / state messages
```

### Ownership and Data Flow

`apps/core` owns `AppRoutes.workoutExercises`. `apps/app` nests the route in the Workout branch, maps profile gender, and gates nested paths. `apps/features/workout/lib/src/presentation/explore/exercises/` owns controller, state, page and widgets.

### Alternative Rejected

- Riverpod `AsyncNotifier`: no precedent in this repo's features; `ChangeNotifier` controllers are the established pattern.
- Top-level `parentNavigatorKey: rootNavigatorKey` route (like Settings): would leave the Workout branch and break branch-nested back behavior.
- Page constructor parameter for gender: a profile arriving after the screen opens would have to notify the controller during build; a root-overridden provider plus `ref.listen` avoids that.

### Failure and Accessibility States

Loading spinner with semantics label; text messages for empty / no-match / missing / malformed / unexpected, announced as live regions; thumbnails excluded from semantics; rows expose name + metadata as text, no button semantics; filter action reports the active filter count in its semantics value.

## 5. Implementation Plan

- [x] `AppRoutes.workoutExercises` + core route test
- [x] Controller/state + tests
- [x] Page, search, filter sheet, rows, states + widget tests
- [x] Router wiring, App Mode nested gating, gender mapping + app tests
- [x] Docs (`exercise-search.md`, `MODULE_OWNERSHIP.md`; `workout.md` / `library.md` already consistent)
- [x] Validation + visual render check

## 6. Quality Review

### Validation Run

Local, Windows, repository Flutter SDK, on the committed tree (2026-09-25). The local `melos` does not recognise the workspace, so per-package commands matching the CI steps were run:

```text
apps/features/workout   flutter analyze --no-pub  → No issues found
apps/features/workout   flutter test --no-pub     → 148 passed (56 new under test/presentation/explore; rerun after the top-bar revision)
apps/core               flutter analyze --no-pub  → No issues found
apps/core               flutter test --no-pub     → 324 passed
apps/app                flutter analyze --no-pub  → No issues found
apps/app                flutter test --no-pub     → 373 passed (19 new in workout_exercises_route_test.dart)
apps/features/onboarding (depends on workout) analyze → No issues; test → 450 passed
git diff --check                                  → clean
```

Visual check: a temporary, uncommitted render test produced PNGs of the page and the filter sheet: light and dark, 390dp and 320dp, with and without loaded thumbnails. Title, search, filter action, rows, 56dp rounded thumbnails, the text-only fallback alignment and the sheet actions were inspected. The repository has no committed golden-file pattern, so no goldens were added.

`dart format` was applied only to new files. Edits to existing files were kept format-neutral, because the formatter rewrote unrelated lines in `router.dart`, `app_mode_route_policy.dart` and `main.dart`; those rewrites were reverted.

### Review Findings and Resolution

| ID | Severity | Status | Finding | Observed at SHA | Evidence or follow-up |
|---|---|---|---|---|---|

## 7. Final Handoff

### Changed Files

- `apps/core/lib/src/routing/routes/app_routes.dart`, `apps/core/test/app_routes_test.dart`: `AppRoutes.workoutExercises`.
- `apps/features/workout/lib/src/presentation/explore/exercises/`: `exercises_state.dart`, `exercises_controller.dart`, `exercises_providers.dart`, `exercise_taxonomy_labels.dart`, `exercises_page.dart`, `widgets/exercise_list_row.dart`, `widgets/exercise_filter_sheet.dart`, `exercises.dart`; `presentation/presentation.dart` export.
- `apps/features/workout/test/presentation/explore/exercises/`: fixtures, controller tests, page tests.
- `apps/app/lib/app/router.dart`: nested Workout child route and explicit chrome policy entry.
- `apps/app/lib/app/app_mode/app_mode_route_policy.dart`: nested tab paths inherit their tab root's gating.
- `apps/app/lib/app/profile/exercise_media_gender.dart`, `apps/app/lib/main.dart`: profile gender → media gender override.
- `apps/app/test/app/workout_exercises_route_test.dart`.
- `docs/screens/exercise-search.md`, `docs/MODULE_OWNERSHIP.md`, this brief, `.ai/tasks/README.md`.

### Actual Behavior

The behavior matches the approved contract recorded in the Owner Approval section and `docs/screens/exercise-search.md#dedicated-exercises-screen-w3a2b`. Nothing links to `/workout/exercises` yet.

### Known Limitations

- No user-facing entry until W6A (by design).
- The active filter count is not shown as a number; the filter icon turns primary while any filter is active, and its tooltip carries the count.
- Thumbnails depend on provider URLs and the network. When offline or on failure, the row is text-only.
- Unsupported catalog schema versions share the malformed-catalog copy.
- The top-bar search field renders 48dp (the standard `TioInput` minimum). The owner wants 46dp through a reusable `TioInput` variant; this belongs to the existing reusable field system issue GitHub #24 (requirement added there; the duplicate #347 was closed).
- Top-bar height: owner decision (2026-09-25) keeps one universal token, `topBarHeight = TioSize.dp56`, for the whole app; any future change is made only in that token. No change was needed, and Linear TNYX-275 / GitHub #346 are closed.

### Final Status

`REVIEW`: implementation and local validation are complete; the Draft PR awaits CI and owner review.
