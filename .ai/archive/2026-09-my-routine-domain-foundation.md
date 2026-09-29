# My Routine domain foundation

**Status:** Validated
**Completion date:** 2026-09-29
**Primary owner:** `apps/shared` Workout domain
**Affected platforms:** Shared pure-Dart Workout domain

## Owner Approval and Scope Boundary

**Trigger:** New independently scoped product task/feature slice
**Approval status:** Approved
**Approval evidence:** Owner said `Go` after the read-only audit proposed exactly `RoutineId + Routine(id, programId, name)` as the next bounded W1 domain slice.
**Approved product/UI/data-shape boundaries:** Add a canonical UUID-backed `RoutineId` and minimal pure-Dart `Routine` carrying `RoutineId id`, owning `ProgramId programId`, and non-blank `name`, with focused tests and public Workout barrel exports.
**Explicit non-changes:** No Supabase Routine table/migration/RLS; no Routine repository/data source/controller; no Program embedding of Routine collections; no ExerciseRef composition; no SetPrescription or ordered-set structure; no generated `Routine N` behavior; no UI/routes; no image/media; no delete/archive semantics; no provenance/revision/source fields; no TrainingPlan/session behavior.

## Active Handoff

**Planning owner:** Current repository agent
**Implementation owner:** None; completed implementation is merged.
**Review owner:** Completed
**Implementation ownership state:** Complete
**Ownership transition:** Not applicable
**Repository state last verified:** remote `main@50cca711e8f617cd8eda3d9be590ef7e2ed33d19`
**Branch:** `tnyx/my-routine-domain-foundation`
**HEAD SHA:** `50cca711e8f617cd8eda3d9be590ef7e2ed33d19` at branch creation
**Observed working-tree state:** Connector-only session; no local checkout available.
**Observed uncommitted/dirty files:** Not observable in connector-only session.
**PR / tracker:** Linear TNYX-78; no focused child issue available from prior tracker audit.
**Current implementation state:** Approved domain slice started; source changes not yet written.
**Relevant execution surface:** `apps/shared/lib/src/workout/**`, `apps/shared/test/workout/**`.
**Validation completed at SHA:** Read-only architecture/runtime audit only.
**Validation remaining:** None for this bounded task.
**Current blocker:** None; task is complete and archived.
**Open review finding IDs:** None.
**Next exact action:** Implement RoutineId and minimal Routine contract/tests only.

## 1. Discovery

### User Outcome

Establish stable Routine identity and explicit owning-Program relationship before Routine persistence/composition/UI work.

### Success Criteria

- `RoutineId` is a distinct canonical UUID-backed Workout identity.
- `Routine` requires `RoutineId id`, `ProgramId programId`, and a non-blank name.
- The owning Program relationship is explicit without embedding Routine collections into `Program`.
- Shared contract remains pure Dart.
- Focused tests cover identity, ownership, name validation, and equality.
- No deferred composition/persistence/UI behavior is introduced.

### Scope

Two domain files, Workout barrel exports, focused tests, and compact task handoff updates.

### Non-Goals

Everything in Explicit non-changes.

## 2. Codebase Exploration

### Verified Evidence

- ADR-0015: a saved user-owned Routine has stable `RoutineId`, belongs to exactly one user-owned Program, is not an orphan Library object, and exact composition/persistence remain separate slices.
- Current `main`: `ProgramId` + minimal `Program(id, name)` exist; no `RoutineId` or `Routine` exists.
- Live Supabase: `user_workout_programs` exists; no Routine table exists.
- Existing ID/entity precedent: `ProgramId` canonical UUID wrapper and `Program` non-blank-name validation/equality.

## 3. Clarification

| Decision | Status | Rationale | Owner |
|---|---|---|---|
| Routine owns explicit ProgramId reference | Approved | ADR-0015 requires exactly one owning user Program | Owner |
| Program embeds Routine list | Deferred/rejected for this slice | Would widen composition and mutation semantics | Architecture |
| Routine composition shape | Deferred | SetPrescription/order semantics not locked | Future slice |

## 4. Architecture Design

```text
Routine
├─ id: RoutineId
├─ programId: ProgramId
└─ name: String
```

Routine references its owner by stable identity. No circular aggregate embedding is introduced.

## 5. Implementation Plan

- [ ] Add `RoutineId` following canonical Workout UUID identity pattern.
- [ ] Add minimal `Routine` with id/programId/non-blank name.
- [ ] Export both from Workout barrel.
- [ ] Add focused tests.
- [ ] Inspect exact branch diff and GitHub CI/review.

## 6. Quality Review

### Validation Run

```text
Not run yet.
```

### Review Findings and Resolution

| ID | Severity | Status | Finding | Observed at SHA | Evidence or follow-up |
|---|---|---|---|---|---|

## 7. Final Handoff

### Changed Files

Pending.

### Actual Behavior

Pending.

### Known Limitations

Connector-only session has no local checkout, so local commands cannot be claimed.

### Final Status

`VALIDATED`


## Archive closure

PR #462 merged the approved `RoutineId` + minimal `Routine(id, programId, name)` foundation as `537fcbd5f973e13208206ed4099d75f119607cf9`. Exact PR head `259a1ec8e39e3e1f6bac53534562f98319c36704` had Flutter CI run #2846 complete successfully. Routine composition and `SetPrescription` remain separate W1 work.
