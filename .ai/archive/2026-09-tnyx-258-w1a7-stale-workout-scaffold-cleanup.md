# TNYX-258 W1A7 — Stale shared Workout scaffold cleanup

**Status:** Validated
**Completion date:** 2026-09-24
**Primary owner:** `apps/shared` (deletion only)
**Affected platforms:** Shared pure-Dart package consumed by phone, Wear and feature packages; no runtime/UI change

## Owner Approval and Scope Boundary

**Trigger:** New independently scoped product task/feature slice (bounded W1 sub-slice under TNYX-78)
**Approval status:** Approved
**Approval evidence:** Owner authorized W1A7 readiness planning (tracker + this brief) on 2026-09-24. The W1A7 direction itself (Q6) was approved in W1A0 and recorded in ADR-0011 §5 / D-019. Owner authorized W1A7 implementation (deletion → validate → Draft PR → review readiness) on 2026-09-24 and the PR #327 merge separately on 2026-09-24; W1A1 remains separately gated.
**Approved product/UI/data-shape boundaries:** Delete only the audited legacy scaffold listed under *Target Paths*. No replacement code.
**Explicit non-changes:** no replacement models; no W1A1 IDs / `ExerciseRef`; no `SetPrescription` / `PerformedSet`; no repository redesign; no feature UI; no Supabase; no Exercise JSON/assets (`apps/core/assets/exercises/` untracked owner files are never edited, staged, moved, stashed, reset or deleted); no Quick Start decision (D-010 / W1A6a); no persistence/migrations; no historical-doc rewrite (including Nutrition briefs); no automation/integration config change.

## Active Handoff

**Planning owner:** current planning agent
**Implementation owner:** current implementation agent
**Review owner:** Not assigned
**Implementation ownership state:** Complete
**Ownership transition:** Not applicable
**Repository state last verified:** 2026-09-24 after `git fetch origin --prune`
**Branch:** `tnyx/tnyx-258-w1a7-stale-workout-scaffold-cleanup` (merged; deleted locally and on origin after merge at owner request)
**HEAD SHA:** merged PR head `3d21d68ee332f2ed4dc48d003784b3c4bc7e0fdb` on base `2725d5ab`; squash merge commit on `main` `ec1f94c97ecb4ced499080842e5c939bf09ae594` (tree identical to the PR head)
**Observed working-tree state:** clean except untracked owner assets `apps/core/assets/exercises/` (unrelated; preserve)
**Observed uncommitted/dirty files:** Not applicable (slice complete)
**PR / tracker:** [PR #327](https://github.com/im-tnyx/tio-world/pull/327) merged 2026-09-24T09:04:20Z (squash). Linear TNYX-258 `Done` (set by the GitHub integration on merge); parent TNYX-78 stays `In Progress` for the remaining W1 slices.
**Current implementation state:** Validated. The 11 stale scaffold files are gone from `main`; `MODULE_OWNERSHIP.md` and D-019 record the removal; no replacement code.
**Relevant execution surface:** `apps/shared/lib/workout.dart`, `apps/shared/lib/src/workout/**`, this brief, `.ai/tasks/README.md`
**Validation completed at SHA:** local workspace at `50b8658d` (section 6); exact head `3d21d68e`: Commit attribution guard SUCCESS (only required check), Attribution guard runner SUCCESS, Analyze and test SUCCESS, exact-head Codex review with no findings, 0 unresolved threads
**Validation remaining:** None.
**Current blocker:** None. The non-required `github-advanced-security` failure was the external TNYX-256 unsupported-model outage (no analysis ran), not a branch finding.
**Open review finding IDs:** None (W1A7-C1 Resolved)
**Next exact action:** None for W1A7 (archived). Next W1 slice is W1A1 canonical Workout IDs/value objects, which needs a fresh audit and separate owner authorization.

## Global UI / Design-System Guardrail

No Flutter UI work is in scope. Rendered UI must remain unchanged; any UI diff is a regression.

## 1. Discovery

### User Outcome

Remove the obsolete, unused shared Workout scaffold before W1A1 introduces canonical Workout identities, so legacy types cannot be reused as competing domain truth.

### Success Criteria

- Exactly the audited stale files are deleted; nothing else under `apps/**` changes.
- Zero external/runtime/test consumers confirmed immediately before deletion.
- `tio_shared` public API (`shared.dart`) is unchanged and every dependent package still analyzes and tests green.
- W1A1 remains separate and unstarted.

### Scope

Deletion of the 11 audited files under *Target Paths*, plus the brief/index updates for this slice.

### Non-Goals

See *Explicit non-changes*. W1A7 is subtraction only.

## 2. Codebase Exploration

### Verified Evidence

- Source/config inspected at `2725d5ab`: root and `apps/features/AGENTS.md`, `.ai/workflow.md`, `.ai/FEATURE_DEVELOPMENT.md`, `.ai/tasks/README.md`, `.ai/tasks/TEMPLATE.md`, [ADR-0011](../../docs/adr/0011-workout-canonical-identities-and-exercise-catalog.md), D-019 in [DECISIONS.md](../DECISIONS.md), [MODULE_OWNERSHIP.md](../../docs/MODULE_OWNERSHIP.md), [archived W1A0 brief](../archive/2026-09-tnyx-78-w1a0-workout-canonical-identities.md), `docs/PUSH_TEMPLATE.md`, `melos.yaml`, `apps/shared/lib/shared.dart`, the scaffold files, Linear TNYX-78.
- Architecture gate (unchanged on fresh main): ADR-0011 §1 durable Workout IDs/entities/value objects → `apps/shared`; Workout repository interfaces/data sources/controllers/UI → `apps/features/workout`; §4 `WorkoutSet` retired, `SetPrescription`/`PerformedSet` canonical; §5 scaffold non-canonical, removed in isolated W1A7 before W1A1. D-019 and MODULE_OWNERSHIP say the same.

### Target Paths (11 tracked files; no untracked/newer files present)

```text
apps/shared/lib/workout.dart                                        public entry: export 'src/workout/workout.dart'
apps/shared/lib/src/workout/workout.dart                            barrel
apps/shared/lib/src/workout/domain/domain.dart                      barrel
apps/shared/lib/src/workout/domain/models/models.dart               barrel
apps/shared/lib/src/workout/domain/models/exercise.dart             class Exercise
apps/shared/lib/src/workout/domain/models/set_type.dart             enum SetType
apps/shared/lib/src/workout/domain/models/training_session.dart     class TrainingSession
apps/shared/lib/src/workout/domain/models/workout.dart              class Workout
apps/shared/lib/src/workout/domain/models/workout_set.dart          class WorkoutSet
apps/shared/lib/src/workout/domain/repositories/repositories.dart   barrel
apps/shared/lib/src/workout/domain/repositories/workout_repository.dart  interface WorkoutRepository
```

These names are the legacy scaffold only, not future canonical W1A1+ contracts.

### Consumer Audit (`git grep` over tracked files at `2725d5ab`)

| Check | Result |
|---|---|
| `package:tio_shared/workout.dart` / `package:tio_shared/src/workout` imports | 0 |
| Relative imports into the scaffold from outside it | 0 (all `…/workout.dart` hits are `package:tio_feature_workout/workout.dart`, a different package) |
| `apps/shared/lib/shared.dart` export | none (exports app_mode, nutrition, network, result, device, contact) |
| Dedicated tests | none (`apps/shared/test` has app_mode, contact, network, nutrition only) |
| `TrainingSession` / `WorkoutSet` / `SetType` / `WorkoutRepository` in Dart outside scaffold | 0 |
| Generic `Exercise` / `Workout` as a Dart type outside scaffold | 0 (remaining hits are comments, UI strings, test names; no other declaration of either class) |
| `apps/wear`, `apps/watchos` references | 0 |
| yaml/json/gradle/sh config references | 0 |
| Internal-only references | scaffold barrels export each other; `workout_set.dart` → `set_type.dart`; `workout_repository.dart` → `../models/models.dart` (not external consumers) |

### Documentation References (classified)

| Reference | Class | Effect on W1A7 |
|---|---|---|
| ADR-0011 §4–5, D-019, `docs/MODULE_OWNERSHIP.md` Workout split | Current canonical architecture — describes the removal | Supports W1A7; update only if wording becomes false after deletion (decide at implementation, minimal) |
| Archived W1A0 brief | Historical record | None |
| `.ai/tasks/tnyx-66-nutrition-readiness-gate.md` (`TrainingSession` `String id` precedent) | Historical evidence in a Nutrition brief | Not a blocker; not rewritten by W1A7 |
| `.ai/tasks/tnyx-188-meal-log-capture-source.md` (`training_session.dart` ownership precedent) | Historical evidence in a Nutrition brief | Not a blocker; not rewritten by W1A7 |

Runtime dependencies: 0. Current canonical architecture dependencies on keeping the scaffold: 0.

### Tracker State at Readiness

- TNYX-78 `In Progress`; children before this slice: none; no existing W1A7 issue, GitHub issue, PR or branch.
- TNYX-258 created as child of TNYX-78: `Todo`, High (inherits parent), project Mobile App, milestone Workout.

## 3. Clarification

### Decisions Required or Made

| Decision | Status | Rationale | Owner |
|---|---|---|---|
| Delete the scaffold rather than deprecate/keep | Approved (W1A0 Q6, ADR-0011 §5) | Prevents competing identities before W1A1 | Owner |
| No replacement code in W1A7 | Locked | W1A1 owns canonical IDs/value objects | Owner |
| Branch/PR use child key TNYX-258, never TNYX-78 | Locked | The Linear GitHub integration auto-set TNYX-78 Done when PR #324 merged; child-key tracking keeps the parent `In Progress` | Planning |
| Separate planning PR | Not required | `AGENTS.md` / `.ai/workflow.md` only require the brief before source changes; W1A0 precedent committed its brief first on the slice branch. This brief is committed as the first commit of the implementation branch | Planning |
| Consumer found before deletion | Stop rule | `BLOCKED — consumer migration requires separate review`; never migrate under W1A7 | Owner |

## 4. Architecture Design

### Chosen Approach

Pure subtraction inside `apps/shared`. `shared.dart` is untouched because it never exported the scaffold. After deletion `apps/shared/lib/` keeps only `shared.dart` and non-Workout `src/*` modules until W1A1 adds canonical types.

### Alternative Rejected

- Keep scaffold alongside W1A1 types: competing `Workout`/`TrainingSession`/`WorkoutSet` truth.
- Rename/adapt scaffold into W1A1 types: mixes cleanup with new design and imports raw `String` identity assumptions.

### Failure and Accessibility States

Not applicable; no runtime or UI behavior.

## 5. Implementation Plan

- [x] 1. Fresh reconstruction: `git fetch origin --prune`, `git status --short --branch`, confirm `origin/main` SHA; preserve `apps/core/assets/exercises/`; create `tnyx/tnyx-258-w1a7-stale-workout-scaffold-cleanup` from fresh `origin/main`; commit this brief + README row first.
- [x] 2. Repeat the section 2 inventory and consumer audit on the fresh base; confirm no newer W1A1+ files exist under the target paths. Any real consumer → stop as `BLOCKED`.
- [x] 3. `git rm` exactly the 11 target files; no other `apps/**` change.
- [x] 4. Re-scan for `tio_shared/workout.dart`, `src/workout`, and the six stale symbols in runtime/test code.
- [x] 5. Validate (section 6).
- [x] 6. Quality review of the diff: changed-file list = 11 deletions + task records (+ at most a minimal canonical-doc wording fix if a statement became false).
- [x] 7. Pushed and opened Draft PR #327 per `docs/PUSH_TEMPLATE.md` and `.github/PULL_REQUEST_TEMPLATE.md`; moved TNYX-258 `In Progress` → `In Review` as real state changed; marked Ready after exact-head gates; owner-authorized squash merge `ec1f94c9` set TNYX-258 `Done`; TNYX-78 stayed `In Progress`.

## 6. Quality Review

### Validation Plan

`tio_shared` is a dependency of `apps/app`, `apps/wear`, `apps/core` and every `apps/features/*` package, so the full workspace set is proportionate:

```bash
git diff --check origin/main...HEAD
melos bootstrap
melos run analyze:dart
melos run analyze
melos run test
```

Plus the push-template scope audit (`merge-base --is-ancestor`, commit list, changed-file list). Record exact results with the validated SHA; if a command cannot run, record the reason instead of claiming a pass.

### Validation Run

Base `origin/main` `2725d5ab` (unchanged since readiness). Results at `50b8658d`:

```text
fresh pre-delete audit: inventory 11 tracked files, 0 untracked; external runtime/test
  consumers 0; shared.dart workout export none; wear/watchOS/config refs 0
post-delete scan: 0 matches in code/config; remaining matches are Markdown only
  (ADR-0011, D-019, MODULE_OWNERSHIP, archived W1A0 brief, tnyx-66/tnyx-188 Nutrition
  briefs, this brief)
git diff --check 2725d5ab...HEAD                          PASS
bash scripts/check_commit_attribution.sh 2725d5ab HEAD    PASS
merge-base --is-ancestor origin/main HEAD                 PASS
per package, mirroring flutter-ci.yml (pub get --enforce-lockfile; flutter analyze --no-pub
  or dart analyze .; flutter test --no-pub or dart test):
  apps/shared, apps/core, apps/app, apps/wear, all 12 apps/features/*
  pub get 16/16 PASS; analyze 16/16 "No issues found"; tests PASS in the 14 packages with
  a test dir (coaching, welcome have none); tio_shared 104 tests
```

Local melos is 8.x while `melos.yaml` targets the CI pin 2.9.0, so the equivalent per-package CI commands were run instead of `melos bootstrap/analyze/test`; Flutter CI on the PR runs the melos form. `flutter pub get` regenerated a tracked Wear `GeneratedPluginRegistrant.java` (pre-existing plugin-list drift); it was restored and is not part of this slice.

### Review Findings and Resolution

| ID | Severity | Status | Finding | Observed at SHA | Evidence or follow-up |
|---|---|---|---|---|---|
| W1A7-C1 | P2 | Resolved | Codex: after merge `docs/MODULE_OWNERSHIP.md` ("pending the isolated W1A7 cleanup") and D-019 ("scheduled for … W1A7 cleanup") would be false against the runtime tree | d865f1ba | The W1A7-C1 commit rewords only those two current statements to "removed by W1A7 (TNYX-258)"; ADR-0011 (decision record) and historical briefs unchanged |

## 7. Final Handoff

### Changed Files

- `.ai/tasks/tnyx-258-w1a7-stale-workout-scaffold-cleanup.md`, `.ai/tasks/README.md` (governance)
- `docs/MODULE_OWNERSHIP.md`, `.ai/DECISIONS.md` D-019: one-clause status wording only (W1A7-C1)
- deleted: `apps/shared/lib/workout.dart` and the 10 files under `apps/shared/lib/src/workout/**` listed in *Target Paths*

### Actual Behavior

No runtime, UI, routing, Supabase or asset change. `tio_shared` public API (`shared.dart`) unchanged. W1A1 not started. Owner assets `apps/core/assets/exercises/` untouched.

### Known Limitations

- Nutrition briefs keep historical references to the scaffold by design.
- W1A1 (canonical Workout IDs/value objects) follows W1A7 and needs its own authorization.

### Final Status

`PASS` — Validated and merged via PR #327 (`ec1f94c9`); archived 2026-09-24.
