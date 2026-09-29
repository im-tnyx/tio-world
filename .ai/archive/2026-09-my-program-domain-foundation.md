# My Program domain foundation

**Status:** Validated
**Completion date:** 2026-09-29
**Primary owner:** `apps/shared` Workout domain
**Affected platforms:** shared pure-Dart contract; no UI/runtime route/persistence change

## Owner Approval and Scope Boundary

**Trigger:** New independently scoped product task/feature slice
**Approval status:** Approved
**Approval evidence:** Owner said `Go` after the 2026-09-29 audit proposed exactly `ProgramId` plus the minimal user-owned `Program` pure-Dart contract and tests.
**Approved product/UI/data-shape boundaries:** Add Program identity and the smallest Program entity invariant needed before Program-owned Routine work.
**Explicit non-changes:** No Routine, repository/data source/controller, generated-name algorithm, Flutter UI/route, Supabase/table/column/RLS, Storage/image, TrainingPlan, Tio/Coach/AI source Program implementation.

## Active Handoff

**Planning owner:** current repository agent
**Implementation owner:** None; completed implementation is merged.
**Review owner:** Completed
**Implementation ownership state:** Complete
**Ownership transition:** Not applicable
**Repository state last verified:** 2026-09-29, branch created from current `main` after PR #459 merge
**Branch:** `tnyx/my-program-domain-foundation`
**Observed working-tree state:** GitHub API branch, no local checkout available
**Observed uncommitted/dirty files:** Not observable through connector; branch was created from `main` before writes
**PR / tracker:** Linear TNYX-78 parent remains In Progress; focused child creation was previously blocked by workspace free issue limit
**Current implementation state:** ProgramId + minimal Program + exports + focused tests implemented; self-review complete
**Relevant execution surface:** `apps/shared/lib/src/workout/**`
**Validation completed at SHA:** `dc163bb57546e85925c25a8a951e678dc4471681` API scope/ancestry audit: branch ahead 7, behind 0, merge-base equals main `fbc5f0d`; exactly 7 expected files changed
**Validation remaining:** None for this bounded task.
**Current blocker:** None; task is complete and archived.
**Open review finding IDs:** None
**Next exact action:** open PR, inspect exact-head CI, then independent review

## 1. Discovery

### User Outcome

Establish the smallest canonical My Program domain foundation so later user Program persistence and Program-owned Routine work have stable identity and name invariants.

### Success Criteria

- `ProgramId` is a distinct canonical UUID-backed Workout identity.
- `Program` carries `ProgramId` and a non-blank name.
- Name preserves the supplied non-blank text; generated naming remains a later creation/use-case concern.
- `apps/shared` remains pure Dart.
- Focused tests cover identity, equality and Program name invariants.

### Scope

`apps/shared` Program identity/entity contract, exports and tests only.

### Non-Goals

No ownership/user ID field without persistence/auth evidence; no provenance/source enum; no revision; no routines collection; no metadata/image; no repository; no UI; no Supabase.

## 2. Codebase Exploration

### Verified Evidence

- ADR-0015 requires Program identity/minimal ownership before saved Routine and keeps exact persistence schema deferred.
- Existing `TrainingPlanId`, `PlannedWorkoutId`, and `WorkoutSessionId` are distinct UUID-backed value types using shared canonical UUID validation.
- Existing `Exercise` demonstrates pure-Dart entity validation with non-blank human-readable text.
- No `ProgramId`, Program runtime entity, Program repository, Program route or Program presentation implementation exists on audited `main`.
- TNYX-259's old W1A4 deferral predates ADR-0015 sequencing and must not force Routine-first implementation.

## 3. Clarification

| Decision | Status | Rationale | Owner |
|---|---|---|---|
| Program identity uses canonical UUID | Locked | Matches existing Workout root-ID pattern | Workout domain |
| Minimal Program contains id + name only | Locked for this slice | Avoids speculative persistence/provenance/composition fields | Owner-approved slice |
| No owner/user ID field yet | Locked for this slice | User ownership is semantic here; persistence/auth representation is deferred | Workout domain |
| Generated `Program N` naming | Deferred | Creation behavior belongs to later use-case/controller slice | Later My Program creation slice |

## 4. Architecture Design

### Chosen Approach

Add `ProgramId` beside existing Workout IDs and a small immutable `Program` entity beside `Exercise`. Reuse canonical UUID validation and the existing non-blank entity-validation style.

### Ownership and Data Flow

```text
apps/shared ProgramId + Program
        ↓ later
apps/features/workout repository/use case/controller
        ↓ later
user Program persistence / UI
```

### Alternative Rejected

Adding provenance, owner ID, Routine children or persistence DTOs now is rejected because those shapes require their own concrete slices and evidence.

### Failure and Accessibility States

Domain constructors reject invalid UUIDs and blank names. Accessibility is not applicable because this slice has no UI.

## 5. Implementation Plan

- [x] Add `ProgramId`.
- [x] Add minimal `Program`.
- [x] Export both from Workout barrel.
- [x] Add focused pure-Dart tests.
- [ ] Audit exact-head CI after PR; API branch delta is already clean.

## 6. Quality Review

### Validation Run

```text
GitHub API scope/ancestry audit at `dc163bb5`: `main` is the merge base, ahead 7 / behind 0, and exactly 7 expected task files differ. Local `dart test` / `git diff --check` were not executable in the connector-only environment; do not treat them as passed.
```

### Review Findings and Resolution

| ID | Severity | Status | Finding | Observed at SHA | Evidence or follow-up |
|---|---|---|---|---|---|
| None | | | | | |

## 7. Final Handoff

### Changed Files

`.ai/tasks/README.md`, `.ai/tasks/my-program-domain-foundation.md`, `apps/shared/lib/src/workout/program_id.dart`, `apps/shared/lib/src/workout/program.dart`, `apps/shared/lib/src/workout/workout.dart`, `apps/shared/test/workout/program_id_test.dart`, `apps/shared/test/workout/program_test.dart`

### Actual Behavior

`ProgramId` now provides a distinct canonical UUID-backed Program identity. `Program` now provides immutable id + non-blank name domain truth. No persistence or UI behavior was added.

### Known Limitations

Persistence, Program creation naming, Routine ownership implementation and UI remain later slices.

### Final Status

`VALIDATED`


## Archive closure

PR #460 merged the approved `ProgramId` + minimal `Program(id, name)` foundation as `e36c10f51f3b10882983912dddd99237791fc6e4`. Exact PR head `ca2059e411c645c9032f0b817929638a7c92393b` had Flutter CI run #2842 complete successfully. Later Program persistence work was delivered separately; this archived task remains domain-foundation evidence only.
