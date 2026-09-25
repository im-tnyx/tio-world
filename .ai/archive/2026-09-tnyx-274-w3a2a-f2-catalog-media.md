# TNYX-274 W3A2a-F2 — Exercise catalog media (image/video URLs)

**Status:** Validated
**Completion date:** 2026-09-25
**Primary owner:** `apps/shared` (canonical media value + selection rule) and `apps/features/workout` (catalog asset + row parser)
**Affected platforms:** Flutter consumers of `tio_shared` / `tio_feature_workout`; no UI or routing change

## Owner Approval and Scope Boundary

**Trigger:** New independently scoped product task/feature slice
**Approval status:** Approved
**Approval evidence:** On 2026-09-25 the owner approved TNYX-274 ("go follow agent.md") after narrowing it to media only, and authorized the Draft → Ready transition and review gate, then the PR #343 squash merge, post-merge sync and brief archive, the same day. Decisions are recorded in Linear TNYX-274 and GitHub #342: remote provider URLs are owner-approved and owner-maintained; the list thumbnail is YES (in TNYX-272); media follows the user's gender with default/other/text-only fallback; full URLs are kept as curated; there is one catalog file.
**Approved product/UI/data-shape boundaries:** add the curated `media` object to each row of the existing Workout catalog asset exactly as in the owner source; keep `schemaVersion` 1 (additive optional field), bump `catalogVersion`; parse/validate media; add the canonical media value and gender selection rule to `Exercise` in `apps/shared`; tests; docs.
**Explicit non-changes (initial implementation scope; later lifecycle actions were separately authorized as recorded above):** no UI or rendering (phone list = TNYX-272, phone video = W3B/TNYX-262, watch = later slices); no other curated fields; no move to a shared catalog package or ADR boundary change (deferred); no Supabase; no router, Library or Workout Home change.

## Active Handoff

**Planning owner:** Current task agent
**Implementation owner:** Current task agent
**Review owner:** Exact-head self-review by the task agent (not independent). The Ready-triggered Codex review gave 👍 (no suggestions) at 11:27Z; no owner-account review was posted before merge.
**Implementation ownership state:** Complete
**Ownership transition:** Not applicable
**Repository state last verified:** 2026-09-25 after the PR #343 post-merge sync; GitHub `main`, `origin/main` and local `main` all at `bb2961eb2d85d1a9b2a27c59637b582e627a4301`
**Branch:** `tnyx/tnyx-274-w3a2a-f2-add-exercise-media-imagevideo-urls-to-bundled` (merged; retained, deletion separately gated)
**HEAD SHA:** merged PR head `a5a62259059794aa66000245832b92687126dbc7` on base `3eee0357`; squash merge commit on `main` `bb2961eb2d85d1a9b2a27c59637b582e627a4301` (GitHub-verified; merge tree identical to reviewed head)
**Observed working-tree state:** Not applicable (slice complete); owner asset directories under `apps/core/assets/` remain untracked and untouched
**Observed uncommitted/dirty files:** Not applicable (slice complete)
**PR / tracker:** [PR #343](https://github.com/im-tnyx/tio-world/pull/343) merged 2026-09-25T11:42:08Z (squash). Linear TNYX-274 `Done` (set by the GitHub integration on merge; moved to `In Review` manually at Ready). GitHub #342 closed as completed. Parent TNYX-270 stays `In Progress`; TNYX-272 is `Backlog` and its blocker is now done.
**Current implementation state:** Validated. On `main`: every catalog row carries curated per-gender `media` (`catalogVersion` 2, `schemaVersion` 1), and `Exercise.media` with `ExerciseMedia.urlFor(kind, gender:)` lives in `apps/shared`.
**Relevant execution surface:** `apps/shared/lib/src/workout/`, `apps/shared/test/workout/`, `apps/features/workout/{assets/exercises,lib/src/data/exercises,test/data/exercises}`, `docs/screens/exercise-search.md`, `docs/MODULE_OWNERSHIP.md`
**Validation completed at SHA:** exact-head CI PASS (Commit attribution guard, Attribution guard runner, Analyze and test) on implementation commit `67ce4e2f` and on merged head `a5a62259`, with 0 review threads at merge. GHAS failed before analysis (`CAPIError 400` unsupported model, TNYX-256 outage; no real security finding, not a security pass). Local per-package validation: section 6.
**Validation remaining:** None.
**Current blocker:** None
**Open review finding IDs:** None
**Next exact action:** None for TNYX-274 (archived). Next work is TNYX-272 — W3A2b — Exercises screen & route (`Backlog`, list thumbnail YES via `ExerciseMedia.urlFor`), which needs explicit owner approval before implementation. Phone video stays with W3B (TNYX-262), and watch media rendering and the shared catalog package move stay with later slices. The Library / Workout Home entry remains W6A (TNYX-266).

## Global UI / Design-System Guardrail

No production UI or visual change is in scope.

## 1. Discovery

### User Outcome

The canonical Exercise catalog carries per-gender image, thumbnail and video URLs, so TNYX-272 can show list thumbnails and W3B can play video, and the right variant is picked for the user's gender.

### Success Criteria

- Every catalog row carries the owner's curated `media` object byte-for-byte, and no other new field.
- `Exercise.media` exposes typed, https-validated URLs and one shared selection rule: preferred gender → `defaultGender` → `videoFallbackGender` (video only) → the other gender → none.
- Invalid media fails the whole catalog with row/field diagnostics, as other fields do.
- Existing behavior and tests are unchanged apart from the documented contract updates.

### Scope

See **Approved product/UI/data-shape boundaries**.

### Non-Goals

See **Explicit non-changes**.

## 2. Codebase Exploration

### Verified Evidence

Recorded at task start, on base `3eee0357`:

- `Exercise` (`apps/shared/lib/src/workout/exercise.dart`) doc comment kept media outside the W1A2 contract. D-019 / ADR-0011 only state that media may evolve without redefining identity; they have no prohibition, so this slice updates the doc comment.
- `ExerciseCatalogRowDto` reads the consumed keys and ignores unknown ones; `toExercise` maps `ArgumentError` names to JSON paths.
- Owner source media (101 rows, row ids aligned 1:1 with the shipped asset): keys `type` (`video` 100 / `image` 1), `defaultGender` (`male` 100 / `female` 1), `male` + `female` objects with `imageUrl` / `videoUrl` / `thumbnailUrl` (string or null), plus an optional `videoFallbackGender` (1 row). All 397 URLs are `https`. Every `defaultGender` variant has an `imageUrl`.
- The shipped asset is `json.dumps(indent=2, ensure_ascii=False)` + a trailing newline, so it can be regenerated deterministically.
- User gender source: onboarding `ProfileGender { male, female, other }` / `users.gender`. Mapping it to the media gender happens in the consuming controller (TNYX-272), not in this slice.

## 3. Clarification

| Decision | Status | Rationale | Owner |
|---|---|---|---|
| Keep `schemaVersion` 1 | Made | `media` is additive and optional; older parsers ignore unknown keys | Owner/agent |
| Bump `catalogVersion` 1 → 2 | Made | The catalog content changed | Agent |
| Honour `videoFallbackGender` | Made | It is curated data; it is equivalent to the general fallback with two genders | Agent |
| `media` optional on `Exercise` | Made | User-created exercises have no catalog media | Agent |

## 4. Architecture Design

### Chosen Approach

`apps/shared`: `ExerciseMediaGender`, `ExerciseMediaType`, `ExerciseMediaKind`, `ExerciseMediaVariant` (https-only URIs) and `ExerciseMedia` with `urlFor(kind, {gender})`. `Exercise` gains an optional `media`. `apps/features/workout`: the row DTO reads optional `media` and maps validation errors to `media.*` paths. The asset is regenerated from the owner source.

### Ownership and Data Flow

```text
catalog asset (media) → document decoder → row DTO/parser → Exercise.media (apps/shared) → urlFor(kind, gender)
```

### Alternative Rejected

- Selection logic in widgets: rejected; it must be one shared, testable rule.
- Relative paths + `mediaBaseUrl`: rejected by the owner; full URLs stay.

### Failure and Accessibility States

Invalid media fails the catalog like any invalid field. Missing variant or asset → `urlFor` returns null → callers fall back to text-only.

## 5. Implementation Plan

- [x] Canonical media types + selection rule + `Exercise.media` in `apps/shared`, with tests.
- [x] Row DTO media parsing and diagnostics, with parser tests.
- [x] Regenerate the catalog asset with media; bump `catalogVersion`; update the production-asset test.
- [x] Docs.
- [x] Validate, commit, push, open a Draft PR.

## 6. Quality Review

### Validation Run

```text
dart format (touched Dart files)                                      PASS
Per-package, as CI does (local melos did not recognise the workspace, so commands ran directly in each package):
  apps/shared           dart analyze PASS | dart test PASS (166)
  apps/features/workout flutter analyze PASS | flutter test PASS (92; +10 media tests)
  apps/core             analyze PASS | test PASS (323)
  apps/app              analyze PASS | test PASS (354)
  apps/wear             analyze PASS | test PASS (9)
  other apps/features/* analyze PASS | tests PASS (account_setup 38, auth 159, home 1, nutrition 873, onboarding 450, profile 68, progress 51, settings 236, splash 12; coaching/welcome have no tests)
Asset regeneration check: 101 rows, 0 mismatch against owner source (text fields + media), media last key, catalogVersion 2, schemaVersion 1
git diff --check                                                      PASS
Tool side effects from `pub get` (nutrition pubspec.lock, wear GeneratedPluginRegistrant.java) restored, not committed
```

### Review Findings and Resolution

| ID | Severity | Status | Finding | Observed at SHA | Evidence or follow-up |
|---|---|---|---|---|---|

## 7. Final Handoff

### Changed Files

- `.ai/tasks/README.md`, `.ai/tasks/tnyx-274-w3a2a-f2-catalog-media.md`
- `apps/shared/lib/src/workout/exercise_media.dart` (new), `exercise.dart`, `workout.dart`
- `apps/shared/test/workout/exercise_media_test.dart` (new)
- `apps/features/workout/assets/exercises/exercise_catalog.json`
- `apps/features/workout/lib/src/data/exercises/exercise_catalog_row_dto.dart`
- `apps/features/workout/test/data/exercises/exercise_catalog_parser_test.dart`, `asset_bundle_exercise_catalog_source_test.dart`
- `docs/screens/exercise-search.md`, `docs/MODULE_OWNERSHIP.md`

### Actual Behavior

Every catalog row carries the owner-curated `media`. `Exercise.media` exposes https-validated per-gender URLs. `ExerciseMedia.urlFor(kind, gender:)` resolves the viewer's gender, then `defaultGender`, then `videoFallbackGender` (video), then the other variant, else null. Invalid media fails the catalog with `media.*` diagnostics. Every exercise resolves an image for male, female and unknown viewers.

### Known Limitations

No UI yet (TNYX-272 renders the list thumbnail). Mapping profile gender to `ExerciseMediaGender` happens in the TNYX-272 controller. The other curated fields and the shared catalog package move are deferred.

### Final Status

`Validated` — merged via PR #343 (`bb2961eb`). Archived 2026-09-25. TNYX-270 remains `In Progress` until TNYX-272 is complete.
