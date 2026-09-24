# TNYX-269 W3A1 — Exercise catalog data foundation

**Status:** Validated
**Completion date:** 2026-09-24
**Primary owner:** `apps/features/workout` (domain/data only)
**Affected platforms:** Workout feature package; no runtime UI, routing or rendered change

## Owner Approval and Scope Boundary

**Trigger:** New independently scoped product task/feature slice
**Approval status:** Approved
**Approval evidence:** On 2026-09-24 the owner approved the W3A split (after the W3A readiness audit returned `READY_FOR_OWNER_APPROVAL`) and authorized W3A1 only, through Draft PR and exact-head review; Ready for Review and the PR #335 merge were separately authorized the same day. W3A2 is not authorized.
**Approved product/UI/data-shape boundaries:** Workout-owned catalog row DTO/validation, mapping to canonical `Exercise`, `ExerciseCatalog`, repository contract, pure search/filter query and tests with synthetic fixtures.
**Explicit non-changes:** no real asset loading/`AssetBundle` source, asset move/registration or pubspec asset change; no catalog version/envelope; no UI, presentation controller, router/route contract, Library or Workout Home entry; no media, standards, Supabase/persistence, Favorites/Custom/Folders or Exercise Detail; no `apps/core`, `apps/app` or `apps/shared` change.

### Protected owner work (read-only, never staged)

`apps/core/assets/exercises/`, `apps/core/assets/ic_body_part/`, `apps/core/assets/ic_equipment/`, `apps/core/assets/musclemap/` (untracked owner work). Tests use invented synthetic fixtures only; no owner rows, titles, instructions, media URLs or legacy IDs. Licensing was audited as `LICENSING_EVIDENCE_MISSING`; W3A1 ships no catalog content.

## Active Handoff

**Planning owner:** Current task agent
**Implementation owner:** Current task agent
**Review owner:** Independent exact-head review by the task agent; Codex (supplemental)
**Implementation ownership state:** Complete
**Ownership transition:** Not applicable
**Repository state last verified:** 2026-09-24 after `git fetch origin --prune` and `git pull --ff-only origin main`
**Branch:** `tnyx/tnyx-269-w3a1-exercise-catalog-data-foundation` (merged; retained, deletion separately gated)
**HEAD SHA:** merged PR head `e9f2b81466e81b7f04b236e1842ffa1818f8182d` on base `74032ddb`; squash merge commit on `main` `8cd61a48d650ce832ac311af767416c03304fc26` (GitHub-verified)
**Observed working-tree state:** clean except the protected untracked owner assets above
**Observed uncommitted/dirty files:** Not applicable (slice complete)
**PR / tracker:** [PR #335](https://github.com/im-tnyx/tio-world/pull/335) merged 2026-09-24T19:16:32Z (squash). Linear TNYX-269 `Done` (set by the GitHub integration on merge; moved to `In Review` manually at Ready). Parent TNYX-261 stays `In Progress`; W3A2 TNYX-270 stays `Backlog`.
**Current implementation state:** Validated. The Exercise catalog data foundation is on `main`: row DTO/parser, `ExerciseCatalog` (built-in refs only), `ExerciseCatalogRepository`, `DecodedRowsExerciseCatalogRepository`, `ExerciseCatalogQuery`, `InvalidExerciseCatalogException`.
**Relevant execution surface:** `apps/features/workout/lib/src/{domain,data}/exercises/**`, `apps/features/workout/test/{domain,data}/exercises/**`
**Validation completed at SHA:** source validated at `186606ea` (section 6); later commits changed only this brief. Exact head `e9f2b814`: Commit attribution guard SUCCESS (only required check), Attribution guard runner SUCCESS, Analyze and test SUCCESS, Codex review with no findings, 0 unresolved threads
**Validation remaining:** None.
**Current blocker:** None. The non-required `github-advanced-security` failure was the external TNYX-256 unsupported-model outage (5× `CAPIError 400`, no code-scanning analysis): no real security finding, not a security pass.
**Open review finding IDs:** None (R1 resolved)
**Next exact action:** None for W3A1 (archived). W3A2 (TNYX-270) needs licence/source/attribution evidence, asset move/registration approval, a catalog versioning decision, and visible UI / route presentation approval before a readiness audit.

## Global UI / Design-System Guardrail

No Flutter UI work is in scope.

## 1. Discovery

### User Outcome

W3A2 and later consumers (Exercises screen, builder picker, Exercise Detail) get one validated, reusable path from decoded catalog rows to canonical `Exercise` values, without a competing Exercise model and without shipping unlicensed content.

### Scope

```text
decoded rows (List<Object?>)
→ Workout-owned row DTO + strict validation (data boundary)
→ canonical Exercise (apps/shared)
→ ExerciseCatalog (ordered all + byRef)
→ ExerciseCatalogRepository + pure ExerciseCatalogQuery
```

### Non-Goals

See *Explicit non-changes*.

## 2. Codebase Exploration

### Verified Evidence (at `74032ddb`)

- `Exercise`, `ExerciseRef`, `ExerciseStatus` are on `main` in `apps/shared` (W1A1/W1A2); `ExerciseRef.catalog` throws `ArgumentError` for non-`ex_*` values; `Exercise` rejects blank/duplicate taxonomy with `ArgumentError`.
- Workout package is layer-first (`domain/models`, `domain/repositories`, `data/…`), repository interfaces are `abstract interface class`; tests use `flutter_test` and `package:tio_feature_workout/workout.dart`. TNYX-78 folder map targets `domain/exercises` and `data/exercises`.
- Readiness audit (owner file, read-only): bare array of 101 rows; consumed fields always present; no duplicate/invalid IDs; no licence/attribution evidence.

## 3. Clarification

| Decision | Status | Rationale | Owner |
|---|---|---|---|
| Split W3A into W3A1 (TNYX-269) and W3A2 (TNYX-270) | Approved | Data foundation can land without shipping content | Owner |
| Parser accepts decoded rows, not a document | Approved | Bare-array vs versioned envelope is a W3A2 owner decision | Owner |
| Consumed required fields: `id`, `title`, `muscleGroup`, `primaryMuscles`, `secondaryMuscles`, `equipment.primary`, `category`, `levels`, `isArchived`, `isCustom`; unknown keys ignored | Approved | Audit evidence | Owner |
| Bundled row with `isCustom: true` is invalid | Approved | Catalog rows are never user-created | Owner |
| One invalid row fails the whole catalog, with row/field diagnostics; duplicate refs fail | Approved | Bundled content must not silently lose stable IDs | Owner |
| Search: `displayName` only, case-insensitive substring, trimmed/collapsed whitespace; order by name then id; archived hidden | Approved | Audit search contract | Owner |
| Filters: nullable single-select `muscleGroup`, `primaryEquipment`, `category` | Approved | `levels`/`exerciseType` do not discriminate | Owner |
| Value rules (blank/duplicate) reuse canonical `Exercise` validation; DTO checks presence/types | Locked (engineering) | One rule source | Planning |

## 4. Architecture Design

Expected files:

```text
apps/features/workout/lib/src/domain/exercises/{exercises,exercise_catalog,exercise_catalog_query,exercise_catalog_repository,invalid_exercise_catalog_exception}.dart
apps/features/workout/lib/src/data/exercises/{exercises,exercise_catalog_row_dto,exercise_catalog_parser,decoded_rows_exercise_catalog_repository}.dart
apps/features/workout/lib/src/{domain/domain.dart,data/data.dart}   (barrel exports; DTO not exported)
apps/features/workout/test/{domain,data}/exercises/*_test.dart
```

## 5. Implementation Plan

- [x] Domain: `ExerciseCatalog`, `ExerciseCatalogQuery`, repository interface, invalid-catalog exception + issues.
- [x] Data: row DTO, parser, decoded-rows repository.
- [x] Tests with synthetic fixtures.
- [x] Validate, audit scope, commit, push, Draft PR, exact-head review.

## 6. Quality Review

### Validation Commands

```text
dart format --set-exit-if-changed <changed Dart files>
cd apps/features/workout && flutter pub get && flutter analyze && flutter test
git diff --check origin/main...HEAD
bash scripts/check_commit_attribution.sh origin/main HEAD
```

### Validation Evidence

At source SHA `6b66ad01c1fbde3fb2fc94f88e3856b2998a4945` (tracked tree identical to the validated working tree):

```text
dart format --set-exit-if-changed <14 changed Dart files>    PASS (0 changed after one format pass)
cd apps/features/workout && flutter pub get                   PASS (no tracked drift)
cd apps/features/workout && flutter analyze                   PASS (No issues found!)
flutter test test/data/exercises test/domain/exercises        PASS (40 tests)
cd apps/features/workout && flutter test                      PASS (59 tests)
git diff --check origin/main...HEAD                           PASS
bash scripts/check_commit_attribution.sh origin/main HEAD     PASS
scope: only apps/features/workout lib/test + this brief/index; no assets, pubspec, core, app, shared or supabase
content: no owner catalog rows/titles/media URLs/legacy IDs (synthetic fixtures only)
```

`melos` was not used (local Melos 8.x does not match the CI pin); the package-scoped Flutter commands above cover the only changed package.

Review fix R1 at `186606ea` (tracked tree identical to the validated working tree): format PASS (0 changed), `flutter analyze` PASS, focused 41 PASS, full Workout 60 PASS.

### Review Findings and Resolution

| ID | Severity | Status | Finding | Observed at SHA | Evidence or follow-up |
|---|---|---|---|---|---|
| R1 | P2 | Resolved | `ExerciseCatalog` accepted user-created refs, mixing user-owned data into the built-in catalog | `1b949063` | [PR #335 Codex thread](https://github.com/im-tnyx/tio-world/pull/335); factory rejects non-`CatalogExerciseRef` in `186606ea`, with a test |

Remote evidence at `b5a78278` (Draft PR #335, brief-only change over the source commit): Commit attribution guard, Attribution guard runner and Flutter CI `Analyze and test` succeeded; `github-advanced-security` failed with the known TNYX-256 unsupported-model outage (5× `CAPIError 400`, no code-scanning analysis) — not a security pass, no finding. Independent review of the full diff: no findings; 0 review threads. Codex (supplemental): quota-limited on the first attempt; a later owner-triggered review of `1b949063` raised R1.

## 7. Final Handoff

### Final Outcome

- Workout-owned catalog foundation maps decoded rows to canonical shared `Exercise` values; the DTO stays inside the data boundary and `Exercise` has no JSON knowledge.
- One invalid or duplicate row fails the whole catalog with row/field diagnostics; `ExerciseCatalog` holds built-in (`CatalogExerciseRef`) exercises only.
- Search is `displayName`-only; filters are `muscleGroup`, `primaryEquipment`, `category`; archived exercises are hidden from browse.
- No catalog asset bundled/moved/registered, no UI/routing/media/standards/persistence; owner assets untouched; synthetic fixtures only.

### Final Status

`Validated` — merged via PR #335 (`8cd61a48`). Archived 2026-09-24. W3A1 success does not make W3A2 licensing-ready; TNYX-270 stays gated by licence/source/attribution evidence, asset move/registration, catalog versioning, and visible UI / route presentation approval.
