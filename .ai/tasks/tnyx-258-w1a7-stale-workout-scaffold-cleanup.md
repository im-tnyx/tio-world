# TNYX-258 W1A7 — Stale shared Workout scaffold cleanup

**Status:** In progress — owner-authorized deletion-only implementation
**Primary owner:** `apps/shared` (deletion only)
**Affected platforms:** Shared pure-Dart package consumed by phone, Wear and feature packages; no runtime/UI change

## Owner Approval and Scope Boundary

**Trigger:** New independently scoped product task/feature slice (bounded W1 sub-slice under TNYX-78)
**Approval status:** Approved
**Approval evidence:** Owner authorized W1A7 readiness planning (tracker + this brief) on 2026-09-24. The W1A7 direction itself (Q6) was approved in W1A0 and recorded in ADR-0011 §5 / D-019. Owner authorized W1A7 implementation (deletion → validate → Draft PR → review readiness) on 2026-09-24; merge and W1A1 remain separately gated.
**Approved product/UI/data-shape boundaries:** Delete only the audited legacy scaffold listed under *Target Paths*. No replacement code.
**Explicit non-changes:** no replacement models; no W1A1 IDs / `ExerciseRef`; no `SetPrescription` / `PerformedSet`; no repository redesign; no feature UI; no Supabase; no Exercise JSON/assets (`apps/core/assets/exercises/` untracked owner files are never edited, staged, moved, stashed, reset or deleted); no Quick Start decision (D-010 / W1A6a); no persistence/migrations; no historical-doc rewrite (including Nutrition briefs); no automation/integration config change.

## Active Handoff

**Planning owner:** current planning agent
**Implementation owner:** current implementation agent
**Review owner:** Not assigned
**Implementation ownership state:** Active
**Ownership transition:** Not applicable
**Repository state last verified:** 2026-09-24 after `git fetch origin --prune`
**Branch:** `tnyx/tnyx-258-w1a7-stale-workout-scaffold-cleanup` from fresh `origin/main`
**HEAD SHA:** base `origin/main` = `2725d5abab10747ce1fbd3b6a3f208042878d8fb` (unchanged since readiness); live branch tip is authoritative
**Observed working-tree state:** clean except untracked owner assets `apps/core/assets/exercises/` (unrelated; preserve)
**Observed uncommitted/dirty files:** none besides the owner assets
**PR / tracker:** Linear TNYX-258 (child of TNYX-78); PR not yet opened
**Current implementation state:** Governance commit first; scaffold deletion follows the fresh consumer audit
**Relevant execution surface:** `apps/shared/lib/workout.dart`, `apps/shared/lib/src/workout/**`, this brief, `.ai/tasks/README.md`
**Validation completed at SHA:** readiness audit only at `2725d5ab` (see section 2)
**Validation remaining:** all implementation validation (section 6)
**Current blocker:** None
**Open review finding IDs:** None
**Next exact action:** Section 5 step 2 (fresh consumer audit).

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

## 5. Implementation Plan (requires owner authorization)

- [ ] 1. Fresh reconstruction: `git fetch origin --prune`, `git status --short --branch`, confirm `origin/main` SHA; preserve `apps/core/assets/exercises/`; create `tnyx/tnyx-258-w1a7-stale-workout-scaffold-cleanup` from fresh `origin/main`; commit this brief + README row first.
- [ ] 2. Repeat the section 2 inventory and consumer audit on the fresh base; confirm no newer W1A1+ files exist under the target paths. Any real consumer → stop as `BLOCKED`.
- [ ] 3. `git rm` exactly the 11 target files; no other `apps/**` change.
- [ ] 4. Re-scan for `tio_shared/workout.dart`, `src/workout`, and the six stale symbols in runtime/test code.
- [ ] 5. Validate (section 6).
- [ ] 6. Quality review of the diff: changed-file list = 11 deletions + task records (+ at most a minimal canonical-doc wording fix if a statement became false).
- [ ] 7. Push and open a Draft PR per `docs/PUSH_TEMPLATE.md` and `.github/PULL_REQUEST_TEMPLATE.md`; move TNYX-258 to `In Progress`/`In Review` as real state changes; keep TNYX-78 `In Progress`.

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

```text
Readiness audit only (section 2) at 2725d5ab. Implementation validation not run.
```

### Review Findings and Resolution

| ID | Severity | Status | Finding | Observed at SHA | Evidence or follow-up |
|---|---|---|---|---|---|
| — | — | — | None | — | — |

## 7. Final Handoff

### Changed Files

Readiness: this brief and `.ai/tasks/README.md` only.

### Actual Behavior

No change. Scaffold still present on `main`.

### Known Limitations

- Nutrition briefs keep historical references to the scaffold by design.
- W1A1 (canonical Workout IDs/value objects) follows W1A7 and needs its own authorization.

### Final Status

`REVIEW` — readiness complete; awaiting "authorize W1A7 implementation".
