# TNYX-260 W1A2 — Canonical Exercise read model

**Status:** Validated
**Completion date:** 2026-09-24
**Primary owner:** `apps/shared`
**Affected platforms:** Shared pure-Dart contract for phone, Wear, and later approved Workout consumers; no runtime/UI change

## Owner Approval and Scope Boundary

**Trigger:** New independently scoped product task/feature slice
**Approval status:** Approved
**Approval evidence:** Owner approved the bounded W1A2 contract and authorized implementation through Draft PR plus exact-head checks/review on 2026-09-24; Ready for Review and the PR #333 merge were separately authorized the same day.
**Approved product/UI/data-shape boundaries:** One canonical pure-Dart `Exercise` and `ExerciseStatus` in `apps/shared`, Workout barrel export, focused tests, this task brief/index, validation, normal push, Draft PR, and exact-head checks/review.
**Explicit non-changes:** No Ready for Review or merge; no TNYX-78 completion or TNYX-261/W3A work; no catalog loader/parser/DTO/repository; no asset registration or Exercise asset modification; no licensing/media/standards work; no Supabase/persistence; no UI/router/navigation; no Favorites/Folders/Custom Exercise persistence or Exercise Detail; no unrelated cleanup.

## Active Handoff

**Planning owner:** Current task agent
**Implementation owner:** Codex, then Claude after an unexpected takeover at `eb4d6acf` (verified clean; no source change by the takeover)
**Review owner:** Owner (im-tnyx) deep reviews of `065ee279` and `3c9f24d4`; independent final review by Claude
**Implementation ownership state:** Complete
**Ownership transition:** Codex → Claude (unexpected takeover, 2026-09-24)
**Repository state last verified:** 2026-09-24 after `git fetch origin --prune` and `git pull --ff-only origin main`
**Branch:** `tnyx/tnyx-260-w1a2-canonical-exercise-read-model` (merged; retained on origin and locally, deletion separately gated)
**HEAD SHA:** merged PR head `3c9f24d4e7aa966fde8ede76d8a5340fc6f316f5` on base `f2e930c6`; squash merge commit on `main` `a30c148e200dbbdbbff9c5f3947315880603123f` (GitHub-verified)
**Observed working-tree state:** clean except untracked owner assets `apps/core/assets/exercises/`
**Observed uncommitted/dirty files:** Not applicable (slice complete)
**PR / tracker:** [PR #333](https://github.com/im-tnyx/tio-world/pull/333) merged 2026-09-24T17:21:23Z (squash). Linear TNYX-260 `Done` (set by the GitHub integration on merge; the Ready transition had briefly moved it `In Review` → `In Progress`). Parent TNYX-78 stays `In Progress`; TNYX-261 stays `Backlog`.
**Current implementation state:** Validated. `Exercise` and `ExerciseStatus` are on `main` and exported through the Workout barrel.
**Relevant execution surface:** `apps/shared/lib/src/workout/{exercise,exercise_status,workout}.dart`, `apps/shared/test/workout/exercise_test.dart`
**Validation completed at SHA:** source validated at `c6e58dfb` (section 6); later commits changed only this brief. Exact head `3c9f24d4`: Commit attribution guard SUCCESS (only required check), Attribution guard runner SUCCESS, Analyze and test SUCCESS, 0 unresolved review threads
**Validation remaining:** None.
**Current blocker:** None. The non-required `github-advanced-security` failure was the external TNYX-256 unsupported-model outage (5× `CAPIError 400`, no code-scanning analysis produced): no real security finding, not a security pass.
**Open review finding IDs:** None (F1 and F2 resolved)
**Next exact action:** None for W1A2 (archived). TNYX-261/W3A needs a fresh readiness audit and separate owner authorization.

## Global UI / Design-System Guardrail

No Flutter production UI, routing, visual token, or rendered behavior is in scope.

## 1. Discovery

### User Outcome

Provide one stable canonical `Exercise` read model before W3A so the catalog repository can return shared domain values without inventing a competing `CatalogExercise` truth.

### Success Criteria

- One `Exercise` type accepts both catalog and user-created `ExerciseRef` variants.
- The approved open-ended taxonomy and `ExerciseStatus` contract is immutable and value-semantic.
- No JSON, catalog lookup, persistence, UI, Supabase, asset, media, licensing, or standards coupling is introduced.
- Focused and full `apps/shared` validation passes.
- A Draft PR references TNYX-260 and remains behind the separate Ready/merge gate.

## 2. Codebase Exploration

### Verified Evidence

- Base `main`/`origin/main`: `f2e930c6ee1bc04590372c4986988219c8cb9952`; no competing TNYX-260/W1A2 PR or branch.
- TNYX-259 is `Done`; TNYX-260 was moved from `Todo` to `In Progress`; TNYX-261 remains `Backlog`.
- ADR-0011 and D-019 place durable pure-Dart Workout entities in `apps/shared`; repository/parser/data-source ownership remains in `apps/features/workout`.
- Existing `ExerciseRef` has `CatalogExerciseRef` (`ex_*`) and `UserCreatedExerciseRef` (UUID), so origin is derived and no mutable origin field is needed.
- Read-only catalog audit found 101 canonical IDs and supports the approved open-ended taxonomy fields. The owner assets remain untracked and protected.
- `apps/shared/pubspec.yaml` needs no dependency change; current Workout value objects use manual value equality and pure Dart.

## 3. Clarification

### Approved Exercise Contract

```text
Exercise
├─ ref: ExerciseRef                         required
├─ displayName: String                      required, nonblank
├─ muscleGroup: String?                     nullable, nonblank when present
├─ primaryMuscles: List<String>             default empty, immutable
├─ secondaryMuscles: List<String>           default empty, immutable
├─ primaryEquipment: String?                nullable, nonblank when present
├─ category: String?                        nullable, nonblank when present
├─ levels: List<String>                     default empty, immutable
└─ status: ExerciseStatus                   required

ExerciseStatus = active | archived
```

Collection tokens are nonblank and unique, duplicates are rejected without silent deduplication, input order is preserved and participates in equality, and unknown future taxonomy strings remain valid. Display text is preserved when nonblank. No taxonomy enum or JSON codec is introduced.

### Explicit Non-Goals

`id: String`, origin/owner/user/creator fields, slug, `exerciseType`, detailed equipment items, numeric/source IDs, goals, tracking, instructions/localization, media, standards, `basedOnExerciseId`, visibility/access, persistence, repositories, catalog assets/loaders, UI, Supabase, and W3A.

## 4. Architecture Design

- `Exercise` owns immutable canonical values and manual equality/hash semantics.
- `ExerciseStatus` is a small canonical lifecycle enum.
- `workout.dart` exports both types; `shared.dart` already exports the Workout barrel.
- W3 later maps validated catalog DTOs into `Exercise`; W1A2 has no raw JSON keys or catalog lookup.
- Rejected: closed taxonomy enums, feature-local `CatalogExercise`, JSON serialization, and package-based collection equality.

## 5. Implementation Plan

- [x] Add `exercise_status.dart`.
- [x] Add `exercise.dart` with validation, immutable collections, and value semantics.
- [x] Export both from `workout.dart`.
- [x] Add focused pure-Dart tests.
- [x] Confirm D-019 needs no restatement; implementation introduced no new durable architecture decision.
- [x] Validate, audit scope, commit, push, create Draft PR, and collect exact-head checks/review.

### Expected Files

```text
.ai/tasks/tnyx-260-w1a2-canonical-exercise-read-model.md
.ai/tasks/README.md
apps/shared/lib/src/workout/exercise.dart
apps/shared/lib/src/workout/exercise_status.dart
apps/shared/lib/src/workout/workout.dart
apps/shared/test/workout/exercise_test.dart
```

Expected unchanged: `apps/shared/pubspec.yaml`, `.ai/DECISIONS.md` unless new evidence requires a narrow clarification, `apps/features/workout/**`, `apps/core/assets/exercises/**`, `supabase/**`, `docs/screens/**`, and `docs/adr/**`.

## 6. Quality Review

### Validation Commands

```text
dart format --set-exit-if-changed <four changed Dart files>
cd apps/shared && dart pub get --enforce-lockfile
cd apps/shared && dart analyze .
cd apps/shared && dart test test/workout/exercise_test.dart
cd apps/shared && dart test
git diff --check origin/main...HEAD
bash scripts/check_commit_attribution.sh origin/main HEAD
```

### Validation Evidence

- `dart format --set-exit-if-changed` on the four changed Dart files: PASS after the first run formatted `exercise_test.dart`; repeat reported `0 changed`.
- `cd apps/shared && dart pub get --enforce-lockfile`: PASS; no `pubspec.yaml` or lockfile drift.
- `cd apps/shared && dart analyze .`: PASS (`No issues found!`).
- `cd apps/shared && dart test test/workout/exercise_test.dart`: PASS (`18` tests).
- `cd apps/shared && dart test`: PASS (`154` tests).
- Flutter `analyze --no-pub` across all remaining 15 Flutter packages: PASS.
- Flutter `test --no-pub` across the 13 remaining test-bearing Flutter packages: PASS; combined command exited `0`.
- `melos bootstrap`: unavailable because Melos 8.6.0 did not recognize the repository's current workspace configuration; direct package validation above was used instead.
- `git diff --check`: PASS before commit; only Git line-ending conversion warnings were emitted.
- Validation created no tracked drift and did not touch `apps/core/assets/exercises/`.
- Implementation commit: `f58097e3fe57fa4f2fdd1e8e4bba54441afc0aa3`.
- Implementation commit validated above; the Codex run recorded it as the validation SHA.

Rerun by the receiving agent at `eb4d6acff77719b9df2cf8095ae6be366b641a4f` (historical):

```text
dart format --set-exit-if-changed <four Dart files>     PASS (0 changed)
dart pub get --enforce-lockfile                         PASS
dart analyze .                                          PASS (No issues found!)
dart test test/workout/exercise_test.dart               PASS (18 tests)
dart test                                               PASS (154 tests)
git diff --check origin/main...HEAD                     PASS
bash scripts/check_commit_attribution.sh origin/main HEAD  PASS
scope: no apps/features, apps/core, supabase, docs or pubspec change   PASS
```

Remote evidence at `eb4d6acff77719b9df2cf8095ae6be366b641a4f` (historical):

```text
Commit attribution guard   success
Attribution guard runner   success
Flutter CI / Analyze and test   success
github-advanced-security   failure: 5x CAPIError 400 unsupported model, no code-scanning analysis
                           = known TNYX-256 external outage; non-required; not a security pass
Codex review               "Didn't find any major issues"; reviewed eb4d6acff7; 0 threads
```

At `065ee279` (brief-only change over `eb4d6acf`): attribution guard, attribution runner and Flutter CI succeeded; GHAS again the TNYX-256 outage. Codex retry was unavailable (usage quota); Codex is supplemental and this is not a code blocker. The owner deep review found no source defect and one governance finding (F1).

Validation at test-hardening SHA `c6e58dfbb6c6064cb1c44dc3882a8adae0e6337d`:

```text
dart format --set-exit-if-changed <four Dart files>     PASS (0 changed)
dart pub get --enforce-lockfile                         PASS
dart analyze .                                          PASS (No issues found!)
dart test test/workout/exercise_test.dart               PASS (18 tests)
dart test                                               PASS (154 tests)
git diff --check origin/main...HEAD                     PASS
bash scripts/check_commit_attribution.sh origin/main HEAD  PASS
scope: only the six expected files; no pubspec, assets, features, supabase or docs change
```

### Review Findings and Resolution

| ID | Severity | Status | Finding | Observed at SHA | Evidence or follow-up |
|---|---|---|---|---|---|
| F1 | P2 | Resolved | Handoff still listed pending exact-head checks/Codex, unassigned review owner and stale next action | `065ee279` | [PR #333 thread](https://github.com/im-tnyx/tio-world/pull/333); handoff refreshed in `e5b3a78b` |
| F2 | P3 | Resolved | Tests asserted only whitespace (not empty-string) taxonomy rejection and no null/empty-vs-present inequality | `065ee279` | Independent review; covered in `c6e58dfb`, contract unchanged |

## 7. Final Handoff

### Final Outcome

- Canonical `Exercise` lives once in `apps/shared`; `ExerciseStatus` = `active | archived`.
- `ExerciseRef` remains the identity boundary; catalog and user-created refs share one `Exercise` type with no origin, owner or user field.
- No JSON coupling, catalog loader/parser, persistence, UI, dependency or W3A implementation; owner Exercise assets untouched.

### Review Truth

- Independent exact-head review of `3c9f24d4`: clean. Owner final deep review of `3c9f24d4`: PASS with no P1/P2/P3 findings.
- Codex (supplemental, not a required merge gate): reviewed `eb4d6acf` clean; later attempts, including on Ready, were unavailable because of a usage quota.
- GHAS: known TNYX-256 outage; no code-scanning analysis produced; real security finding NO; security pass claimed NO.

### Final Status

`Validated` — merged via PR #333 (`a30c148e`). Archived 2026-09-24.
