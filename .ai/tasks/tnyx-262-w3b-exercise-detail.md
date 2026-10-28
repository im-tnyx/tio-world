# TNYX-262 W3B — Exercise Detail / About

**Status:** In progress
**Primary owner:** Current implementation agent
**Affected platforms:** Flutter phone (`apps/app`, `apps/features/workout`)

## Owner Approval and Scope Boundary

**Trigger:** New independently scoped product/UI feature slice
**Approval status:** Approved
**Approval evidence:** User request on 2026-10-28 for TNYX-262 / GitHub #557 W3B implementation using the owner-provided Exercise Detail/About contract.
**Approved product/UI/data-shape boundaries:** One canonical Exercise Detail/About surface for bundled catalog and active owner-scoped Custom Exercises; canonical media/instruction rendering; nested Workout navigation; explicit owner-only Edit entry reusing the existing editor.
**Explicit non-changes:** No second Exercise model/catalog, no Supabase schema/RLS/Storage change, no Custom media upload pipeline, no hard delete, no #556 thumbnail alignment work, no Wear/watch/video work, no WorkoutSession or Routine selection/save semantics redesign, no merge/push/PR/tracker mutation. The bounded Routine change is only the separate Info entry point and full-row selection feedback.

## Active Handoff

**Planning owner:** Current implementation agent
**Implementation owner:** Current implementation agent
**Review owner:** Current implementation agent; independent GitHub review remains a later gate
**Implementation ownership state:** Active
**Ownership transition:** Not applicable
**Repository state last verified:** 2026-10-28
**Branch:** `main`
**HEAD SHA:** `ad1c840ea68672fb50c4662ce00fbcdb90e7aef2`
**Observed working-tree state:** Clean before implementation; local `main` and GitHub `main` were verified at the same SHA before implementation. The current work remains uncommitted on `main`.
**Observed uncommitted/dirty files:** Task-scoped W3B source, tests, docs and dependency lock/generated registration changes listed below; no unrelated pre-existing dirty work was present at audit time.
**PR / tracker:** Linear `TNYX-262` is `Backlog`; Linear `TNYX-264` is `In Progress`; GitHub #557 and #556 are `OPEN`; no open W3B implementation PR exists. PR #710 is merged at `ca3817af` and its catalog/model/localization changes are present in `main`.
**Current implementation state:** Implemented locally. Dedicated catalog/active Custom rows and Routine Create/Edit picker Info actions open one canonical Detail/About presentation. Routine row taps still select/add; Info does not mutate pending selection. Custom Edit is explicit and owner/session gated.
**Relevant execution surface:** `apps/features/workout/lib/src/presentation/library/exercises/`, `apps/features/workout/test/`, `apps/app/lib/app/routing/shell/shell_route.dart`, `apps/core/lib/src/routing/routes/app_routes.dart`, related route/widget tests and package manifests.
**Validation completed at SHA:** Audit completed at `ad1c840e`; local implementation validation completed with focused Workout tests (`93` passed), app Workout route tests (`89` passed), core route-contract tests (`7` passed), and analyzer diagnostics reporting `No issues found` for Workout, app and core (Dart telemetry exit warning recorded below).
**Validation remaining:** Full monorepo `melos` validation, current-head CI, independent review, device/video QA and assistive-technology QA were not run in this local handoff.
**Current blocker:** No bounded implementation blocker. Merge/review remains gated by current-head CI, independent review, device/accessibility QA and tracker reconciliation; no PR was opened or merged.
**Open review finding IDs:** None for this new slice.
**Next exact action:** Owner review of the uncommitted diff and current-head CI/PR workflow; no external GitHub mutation was performed.

## 1. Discovery

### User Outcome

From `Workout Home → Library → Exercises`, tapping either a bundled catalog Exercise or an active owner-scoped Custom Exercise opens the same canonical About/Exercise Detail screen. The screen shows the current name, selected canonical media or truthful fallback, ordered localized instructions, available metadata, and an explicit owner-only Edit action for Custom Exercises.

### Success Criteria

- One shared detail presentation and route serve catalog and Custom `Exercise` identities.
- Catalog video uses `Exercise.media.urlFor(ExerciseMediaKind.video, gender: ...)`, auto-plays, loops, pauses when hidden/backgrounded, and disposes once.
- Missing/failed/offline media and missing instructions remain truthful and usable.
- Back returns to the existing Exercises route/context; Create Exercise still opens the existing editor directly.
- Custom detail rechecks current owner and active status before showing/editing; catalog has no Custom-only action.
- Focused tests cover navigation, identity/instruction order, media lifecycle/failures, owner gating, back behavior, themes, compact/large text and semantics.

## 2. Codebase Exploration

### Verified Evidence

- `Exercise` in `apps/shared/lib/src/workout/exercise.dart` already owns `localizedTitles`, ordered `localizedInstructions`, taxonomy, lifecycle and optional `ExerciseMedia`.
- `ExerciseMedia.urlFor` in `apps/shared/lib/src/workout/exercise_media.dart` is the existing gender/fallback selection policy; the app overrides `exerciseViewerMediaGenderProvider` from profile gender.
- `ExercisesPage` and `ExerciseListRow` are under `apps/features/workout/lib/src/presentation/library/exercises/`; W3B now separates row selection from Info navigation and routes dedicated catalog/Custom rows to the shared Detail presentation.
- Current Routine Create/Edit picker composition uses `ExercisesPage` directly; `RoutineExercisePickerPage` is not the active Create/Edit entry point. Both Create variants and Edit pass the same Info callback while preserving existing selection/add/save callbacks.
- The app nested Workout routes are wired in `apps/app/lib/app/routing/shell/shell_route.dart`; route contracts are in `apps/core/lib/src/routing/routes/app_routes.dart`.
- `tio_feature_workout` currently has no video-player dependency or reusable video component. The bounded implementation will add the compatible `video_player` package only for the phone detail surface and keep it behind a feature-owned lifecycle adapter for focused tests.
- PR #710 merged the localized catalog contract into current `main`; the bundled catalog has 118 rows, `schemaVersion: 1`, `catalogVersion: 4`, and source-provided `en` title/instruction content.

## 3. Clarification

| Decision | Status | Rationale | Owner |
|---|---|---|---|
| Use one route/presentation for catalog and Custom | Made | Matches TNYX-262/#557 and avoids a second Custom detail truth | Owner/agent |
| Resolve detail data through catalog/user repositories on open | Made | Rechecks canonical identity, active status and current owner instead of trusting stale row objects | Agent |
| Add `video_player` only in Workout feature | Made | No compatible existing player is present; valid canonical video playback is in W3B scope | Agent |
| Use locale-key fallback `full locale → language → en` | Made | Reuses canonical source-provided localization without inventing translations | Agent |
| Do not add Delete action | Made | W3B requires explicit Edit; destructive behavior is archive-gated and not necessary for this slice | Owner/agent |
| Add Routine picker Info as a separate action | Made | Owner clarification requires About access without triggering row selection or changing pending Exercises | Owner/agent |
| Keep normal row context with root Navigator push | Made | The existing imperative Library/picker stack preserves list state and scroll/selection context; direct deep links still have a canonical GoRouter child route | Agent |

## 4. Architecture Design

### Chosen Approach

`ExercisesPage` emits a feature callback for normal browse taps and a separate Info callback for Routine picker rows. App composition pushes the canonical `ExerciseDetailPage` with the root `Navigator` for normal/picker taps so the existing list route remains mounted underneath; the nested GoRouter child route remains available for direct `/workout/exercises/:exerciseId` deep links. `ExerciseDetailController` loads the identity from the canonical catalog or current owner-scoped user repository. `ExerciseDetailPage` renders the state, owns the explicit Edit action, and composes a feature-local video lifecycle adapter over `video_player`. The detail media item is kept alive while the scrollable content recycles off-screen children, so scrolling does not recreate or reload its controller.

### Ownership and Data Flow

```text
ExercisesPage row tap / Routine picker Info
  -> root Navigator canonical Detail page
  -> ExerciseDetailController
  -> catalog repository OR owner-scoped UserExerciseRepository
  -> canonical Exercise
  -> localized title/instructions + ExerciseMedia.urlFor
  -> detail presentation / lifecycle-safe video player
```

### Alternative Rejected

- A separate Custom Detail page/model was rejected because both sources are canonical `Exercise` values.
- Parsing catalog JSON in the widget was rejected because the existing repository/parser boundary is authoritative.
- A local fake/custom media URL or new Storage pipeline was rejected because Custom media persistence is separately gated.
- A direct route flip without a real detail screen was rejected by GitHub #557 and TNYX-262.

### Failure and Accessibility States

Loading, missing/inaccessible/archived identity, repository failure, no video URL, video initialization failure/offline failure, and missing instructions each receive a truthful UI state. Instructions are numbered in canonical order, scroll with short/large-text viewports, and expose readable semantics. Video is paused on route transition/app background and disposed on teardown.

## 5. Implementation Plan

- [x] Add focused W3B task/controller/state and video lifecycle adapter.
- [x] Add shared detail page with metadata, localized fallback, ordered instructions and owner-only Edit.
- [x] Add Workout route contract and app nested route wiring; preserve Create flow and list state.
- [x] Change normal catalog/Custom row taps to the shared detail callback without touching #556 geometry.
- [x] Add Routine Create/Edit Info entry point with separate callback and full-row selection feedback.
- [x] Add focused Workout/app widget and routing tests, including scroll-stable video lifecycle.
- [x] Run analyzer, focused tests, dependency resolution and `git diff --check`.
- [x] Update canonical Exercise screen documentation and this handoff with actual evidence.

## 6. Quality Review

### Validation Run

```text
G:\dev\flutter-sdk\bin\flutter.bat test test/presentation/library/exercises/exercise_detail_test.dart test/presentation/library/exercises/exercises_page_test.dart test/presentation/create_routine_page_test.dart test/presentation/edit_routine_page_test.dart
PASS — 93 tests.

G:\dev\flutter-sdk\bin\flutter.bat test test/app/workout_exercises_route_test.dart
PASS — 89 tests.

G:\dev\flutter-sdk\bin\flutter.bat test test/app_routes_test.dart
PASS — 7 tests.

G:\dev\flutter-sdk\bin\cache\dart-sdk\bin\dart.exe --disable-analytics analyze
Workout, app and core each reported `No issues found`.
The analyzer process exited non-zero afterward because Dart telemetry could not
update the machine-local session file under `C:\Users\SANTOSH\AppData\Roaming`;
this is recorded as an environment warning, not a source diagnostic.

G:\dev\flutter-sdk\bin\flutter.bat pub get (apps/features/workout and apps/app)
PASS — video_player dependency resolution completed; app Android plugin
registration was regenerated by Flutter.

git diff --check
PASS — no whitespace errors.
```

### Acceptance Evidence

| Criterion | Changed behavior / file | Test or manual evidence + actual result | Observed SHA / environment | Remaining risk |
|---|---|---|---|---|
| Shared catalog/Custom detail | Workout detail page/controller + app route | App route suite passed; catalog and Custom rows opened the same `ExerciseDetailPage` | Windows local checkout, uncommitted `main` | Device/auth lifecycle proof pending |
| Canonical video/instructions | Detail media/instruction widgets | Detail tests passed identity, ordered instructions, fallback, autoplay/loop/pause/dispose and scroll-stable controller behavior | Windows local checkout | Native player/device rendering pending |
| Context-preserving navigation | Exercises callback + root Navigator stack + deep-link child route | App route suite passed; picker Info/Create/Edit tests passed without selection mutation | Windows local checkout | Device back-stack proof pending |
| Owner-only Custom Edit | Session-aware detail action | Detail tests passed owner Edit and wrong-owner fail-closed behavior | Windows local checkout | Hosted auth/RLS not in scope |

### Review Provenance

**Review source / link:** self-review until a later PR review
**Reviewer / relation to implementer:** Current implementation agent / self-review
**Diff or commit SHA actually reviewed:** Working-tree diff against `ad1c840ea68672fb50c4662ce00fbcdb90e7aef2`
**Review result and finding IDs/dispositions:** Self-review completed; no open finding IDs. Formatter-only churn was removed from large pre-existing route/test files before handoff.
**Independent review?** No (self-review)
**Limitations and unmet required gates:** No current-head CI, independent review, device QA or accessibility technology QA yet.

## 7. Final Handoff

### Changed Files

- `.ai/tasks/tnyx-262-w3b-exercise-detail.md`
- `docs/screens/exercise-search.md`
- `apps/core/lib/src/routing/routes/app_routes.dart`
- `apps/core/test/app_routes_test.dart`
- `apps/features/workout/pubspec.yaml` and `pubspec.lock`
- `apps/features/workout/lib/src/presentation/library/exercises/exercise_detail_controller.dart`
- `exercise_detail_page.dart`, `exercise_detail_state.dart`, `exercise_video_player.dart`
- `exercises.dart`, `exercises_page.dart`, `widgets/exercise_list_row.dart`
- `create_routine_page.dart`, `edit_routine_page.dart`
- focused Workout Detail/Exercises/Create/Edit tests
- `apps/app/lib/app/router.dart`, `app/routing/shell/shell_route.dart`, `pubspec.lock`, generated Android plugin registration, and Workout route tests

### Actual Behavior

- Dedicated catalog and active owner-scoped Custom rows open one canonical Detail/About page.
- Routine Create/Edit picker rows retain existing selection/add/save behavior; trailing Info opens the same Detail without selecting, and selected feedback spans the complete row.
- Detail resolves canonical media through `ExerciseMedia.urlFor` and `exerciseViewerMediaGenderProvider`, loops valid video, pauses on route/app lifecycle changes, keeps its controller alive across scroll, and disposes on route teardown.
- Missing media/instructions, malformed/inaccessible Custom state and playback failure use truthful fallbacks.
- Custom Edit is shown only after current owner/active-session checks and reuses `CustomExerciseEditorPage`.

### Known Limitations

- No device/emulator video QA or assistive-technology QA was run.
- Full monorepo `melos analyze`/`melos test` was not run.
- No current W3B PR, current-head CI, independent review or tracker mutation exists; local `main` remains uncommitted.

### Final Status

`REVIEW`
