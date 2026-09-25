# Workout Exercises Presentation Library Relocation

**Status:** In review
**Primary owner:** `apps/features/workout`
**Affected platforms:** Flutter phone app (Android + iOS)

## Owner Approval and Scope Boundary

**Trigger:** New independently scoped product task/feature slice
**Approval status:** Approved
**Approval evidence:** On 2026-09-25 the owner directed that Exercise presentation move from Explore to Library before TNYX-262 and then approved execution with `AGENTS.md`, `.ai/workflow.md`, and `go`.
**Approved product/UI/data-shape boundaries:** Relocate the existing dedicated Exercises presentation implementation and its mirrored presentation tests from `presentation/explore/exercises/` to `presentation/library/exercises/`; update exports and canonical ownership documentation required by that move.
**Explicit non-changes:** No rendered UI, route/path/deep-link, search/filter, controller/state, catalog/data/domain, media-selection, accessibility, Supabase, persistence, W3B detail, Favorites, Custom Exercises, Folders, Program/Routine builder, or WorkoutSession change.

## Active Handoff

**Planning owner:** Codex
**Implementation owner:** Codex
**Review owner:** Codex automated review on PR #352; remediation by Codex
**Implementation ownership state:** Complete
**Ownership transition:** Not applicable
**Repository state last verified:** PR #352 is open from the tracked branch; before this review remediation, local `HEAD` and the upstream branch matched implementation commit `5e12b06ccf0481c66300e1a2f7b7aa0a003b139d`, one commit ahead of `origin/main`.
**Branch:** `tnyx/workout-library-exercises-presentation`
**Base SHA:** `549e5eac9b0c5c96de9e992927b8a2db910ff46b`
**Implementation commit SHA:** `5e12b06ccf0481c66300e1a2f7b7aa0a003b139d`
**Observed pre-commit working-tree state:** Task-scoped relocation, export, canonical docs, decision record, and task-governance changes only.
**Observed pre-commit changed files:** Eleven 100%-similarity source/test renames plus the public export, three canonical/governance docs, this task brief, and its active-task index entry.
**Delivery authorization:** On 2026-09-25 the owner explicitly authorized committing, pushing, and creating PR #352. Merge and external tracker mutation remain unauthorized. Related planning: TNYX-80, TNYX-82, TNYX-83; TNYX-262 remains deferred by owner direction.
**Current implementation state:** Production and mirrored test subtrees moved under Library; public export and canonical placement text updated; no runtime source content changed inside moved files.
**Relevant execution surface:** `apps/features/workout/lib/src/presentation/{explore,library}/`, mirrored Workout presentation tests, public presentation barrel, `docs/MODULE_OWNERSHIP.md`, `docs/screens/exercise-search.md`, and `.ai/DECISIONS.md`.
**Validation completed at SHA:** Implementation commit `5e12b06ccf0481c66300e1a2f7b7aa0a003b139d`: Workout analyze PASS; focused moved Exercises tests 58 PASS; full Workout tests 157 PASS; app analyze PASS; app Workout/Library/Exercises route tests 25 PASS; `git diff --check` PASS; all eleven moved source/test files detected as 100% renames; no current source/canonical-doc old-path reference remains.
**Validation remaining:** Exact-head remote CI and review completion on PR #352 after this documentation-only review remediation is pushed.
**Current blocker:** None.
**Open review finding IDs:** PR #352 P2 `discussion_r4106520881` identified the stale pre-push next action; addressed by this post-commit handoff refresh and pending thread resolution after push.
**Next exact action:** Verify exact-head PR #352 CI and review state. Merge and external tracker updates require separate authorization.

## Global UI / Design-System Guardrail

This is a pixel- and behavior-preserving internal ownership relocation. `.ai/tasks/design-system-token-consolidation.md`, `apps/core/lib/src/theme/README.md`, and `apps/features/AGENTS.md` were read before implementation. No visual code or reusable Core contract may change in this slice.

## 1. Discovery

### User Outcome

Make source ownership match the shipped navigation: Exercises is reached through Library, so its presentation implementation should be co-located below Library before Exercise Detail work begins.

### Success Criteria

- Production Exercises presentation files exist only under `presentation/library/exercises/`.
- Mirrored presentation tests exist only under `test/presentation/library/exercises/`.
- Public exports and imports resolve from the new path.
- Canonical docs describe the new placement without changing Exercise domain/data ownership.
- Runtime behavior and rendered output remain unchanged.

### Scope

- Move the existing Exercises controller, state, providers, page, taxonomy labels, widgets, and barrel file.
- Move the corresponding controller/page tests and fixtures.
- Update the Workout presentation barrel.
- Update exact canonical path/placement statements and the durable Library/Exercises decision note.

### Non-Goals

- TNYX-262 Exercise Detail or row tap behavior.
- Any new Library section, tab, state, repository, or canonical Exercise model.
- Any route, callback, catalog asset, media, Supabase, or persistence change.
- Refactoring code while moving it.

## 2. Codebase Exploration

### Verified Evidence

- Source/config inspected: the Exercises presentation subtree, Workout public presentation barrel, app route/tests, W3A/W6A docs, D-019/D-020, ADR-0011, and current repository status.
- Existing pattern to follow: `presentation/library/library.dart` and `library_page.dart` already own the Library presentation hierarchy; production and test presentation paths mirror one another.
- Tests or validation already present: focused `ExercisesController` and `ExercisesPage` suites plus app route coverage consume the package public export.
- Runtime navigation already is `Workout Home -> Library -> Exercises`; the current `explore/exercises` folder is only source placement and creates no `/explore` route.
- Live tracker text still records the earlier Explore placement. No matching child tracker exists, so the approved repository task brief records the superseding owner decision without mutating external trackers.

## 3. Clarification

### Decisions Required or Made

| Decision | Status | Rationale | Owner |
|---|---|---|---|
| Target production path is `presentation/library/exercises/` | Approved | Co-locates presentation with the only shipped user entry and the owner's requested ownership hierarchy | Owner |
| Domain/data remain under top-level `domain/exercises` and `data/exercises` | Locked | Library is presentation/navigation ownership only and must not create `LibraryExercise` truth | ADR-0011 / Owner |
| Move is path-only | Approved | Preserves every current UI and runtime contract before W3B | Owner |
| TNYX-262 remains deferred | Approved | Detail work starts only after this relocation is complete | Owner |

## 4. Architecture Design

### Chosen Approach

Move the complete Exercises presentation subtree and its mirrored tests as one atomic mechanical slice. Keep filenames, symbols, relative domain/data imports, provider contracts, public package API, routes, and widget behavior unchanged. Update only the barrel path and canonical ownership text that names the old folder.

### Ownership and Data Flow

```text
Workout Home -> Library route -> Exercises route
                               -> presentation/library/exercises
                               -> existing controller/provider
                               -> existing ExerciseCatalogRepository
                               -> existing bundled catalog source
```

Canonical `Exercise` stays in `apps/shared`; Workout Exercise domain/data stay under `apps/features/workout/lib/src/{domain,data}/exercises`.

### Alternative Rejected

Keeping the implementation under `presentation/explore/exercises` was rejected by the owner because Explore is not the current entry or presentation grouping. Moving domain/data under Library was also rejected because it would make Library a competing Exercise truth owner.

### Failure and Accessibility States

Unchanged. Existing loading, empty, no-match, missing/malformed catalog, unexpected failure, text-only media fallback, semantics, light/dark, and compact-width behavior remain covered by the moved tests.

## 5. Implementation Plan

- [x] Move production Exercises presentation files to `presentation/library/exercises/`.
- [x] Move mirrored tests to `test/presentation/library/exercises/`.
- [x] Update the public presentation barrel path.
- [x] Update canonical ownership/decision documentation that names the old path.
- [x] Prove zero old-path references remain.
- [x] Run focused validation and review the diff for behavior changes.

## 6. Quality Review

### Validation Run

```text
flutter analyze --no-pub
  workdir: apps/features/workout
  PASS — No issues found

flutter test --no-pub test\presentation\library\exercises
  workdir: apps/features/workout
  PASS — 58 tests

flutter test --no-pub
  workdir: apps/features/workout
  PASS — 157 tests

flutter analyze --no-pub
  workdir: apps/app
  PASS — No issues found

flutter test --no-pub test\app\workout_exercises_route_test.dart
  workdir: apps/app
  PASS — 25 tests

git diff --check HEAD
  PASS

Path/reference and rename audit
  PASS — eleven source/test files are 100% renames; current source and canonical docs contain no old placement reference
```

### Review Findings and Resolution

| ID | Severity | Status | Finding | Observed at SHA | Evidence or follow-up |
|---|---|---|---|---|---|
| None | — | Resolved | No behavior, UI, route, state, data, accessibility, or boundary regression found | worktree on `549e5eac` | Full diff, path/reference audit and validation above |

## 7. Final Handoff

### Changed Files

- `.ai/DECISIONS.md`
- `.ai/tasks/README.md`
- `.ai/tasks/workout-exercises-library-presentation-relocation.md`
- `apps/features/workout/lib/src/presentation/presentation.dart`
- `apps/features/workout/lib/src/presentation/library/exercises/**` (moved from `presentation/explore/exercises/**`)
- `apps/features/workout/test/presentation/library/exercises/**` (moved from `test/presentation/explore/exercises/**`)
- `docs/MODULE_OWNERSHIP.md`
- `docs/screens/exercise-search.md`

### Actual Behavior

Exercises presentation and its tests now live below the Library presentation hierarchy. The public package API, route, controller/state/provider behavior, UI, catalog, search/filter, media fallback, and navigation remain unchanged.

### Known Limitations

TNYX-262 and later Exercise capabilities remain unimplemented. Exact-head PR CI remains required after review remediation. Flutter test output retains the existing `uses-material-design` package warning; all tests pass and this slice changes no pubspec.

### Final Status

`REVIEW`
