# TNYX-274 W3A2a-F2 — Exercise catalog media (image/video URLs)

**Status:** In progress
**Primary owner:** `apps/shared` (canonical media value + selection rule) and `apps/features/workout` (catalog asset + row parser)
**Affected platforms:** Flutter consumers of `tio_shared` / `tio_feature_workout`; no UI or routing change

## Owner Approval and Scope Boundary

**Trigger:** New independently scoped product task/feature slice
**Approval status:** Approved
**Approval evidence:** On 2026-09-25 the owner approved TNYX-274 ("go follow agent.md") after narrowing it to media only, and recorded the decisions in Linear TNYX-274 and GitHub #342: remote provider URLs are owner-approved and owner-maintained; the list thumbnail is YES (in TNYX-272); media follows the user's gender with default/other/text-only fallback; full URLs are kept as curated; there is one catalog file.
**Approved product/UI/data-shape boundaries:** add the curated `media` object to each row of the existing Workout catalog asset exactly as in the owner source; keep `schemaVersion` 1 (additive optional field), bump `catalogVersion`; parse/validate media; add the canonical media value and gender selection rule to `Exercise` in `apps/shared`; tests; docs.
**Explicit non-changes:** no UI or rendering (phone list = TNYX-272, phone video = W3B/TNYX-262, watch = later slices); no other curated fields; no move to a shared catalog package or ADR boundary change (deferred); no Supabase; no router, Library or Workout Home change; no merge or branch deletion.

## Active Handoff

**Planning owner:** Current task agent
**Implementation owner:** Current task agent
**Review owner:** Exact-head self-review by the task agent (not independent); owner-account reviews and Codex when available
**Implementation ownership state:** Complete; no implementation-source edits remain
**Ownership transition:** Not applicable
**Repository state last verified:** 2026-09-25 after `git fetch --prune origin`; `origin/main` = `3eee03573b5fe4f1e958ef0ffb5cd98305632b7b`
**Branch:** `tnyx/tnyx-274-w3a2a-f2-add-exercise-media-imagevideo-urls-to-bundled` (from `origin/main`)
**HEAD SHA:** Current branch head (see Git/PR)
**Observed working-tree state:** owner asset directories under `apps/core/assets/` remain untracked and untouched (read-only source)
**Observed uncommitted/dirty files:** owner asset directories only
**PR / tracker:** Linear TNYX-274 `In Progress` (parent TNYX-270 `In Progress`; blocks TNYX-272 `Backlog`); GitHub #342
**Current implementation state:** Implemented and validated locally; Draft PR stage
**Relevant execution surface:** `apps/shared/lib/src/workout/`, `apps/shared/test/workout/`, `apps/features/workout/{assets/exercises,lib/src/data/exercises,test/data/exercises}`, `docs/screens/exercise-search.md`, `docs/MODULE_OWNERSHIP.md`
**Validation completed at SHA:** working tree on base `3eee0357` before the implementation commit, 2026-09-25 (see section 6)
**Validation remaining:** exact-head CI (attribution guard, Analyze and test) and exact-head review on the Draft PR
**Current blocker:** None
**Open review finding IDs:** None
**Next exact action:** Inspect Draft PR exact-head CI; Ready and merge need separate owner authorization.

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

`REVIEW`
