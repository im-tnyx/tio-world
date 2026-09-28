# My Program domain foundation

**Status:** In progress
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
**Implementation owner:** current repository agent
**Review owner:** current repository agent after implementation ownership is complete
**Implementation ownership state:** Active
**Ownership transition:** Not applicable
**Repository state last verified:** 2026-09-29, branch created from current `main` after PR #459 merge
**Branch:** `tnyx/my-program-domain-foundation`
**Observed working-tree state:** GitHub API branch, no local checkout available
**Observed uncommitted/dirty files:** Not observable through connector; branch was created from `main` before writes
**PR / tracker:** Linear TNYX-78 parent remains In Progress; focused child creation was previously blocked by workspace free issue limit
**Current implementation state:** audit complete; source edits starting
**Relevant execution surface:** `apps/shared/lib/src/workout/**`
**Validation completed at SHA:** Not yet
**Validation remaining:** exact branch diff audit; CI/analyze/test evidence after PR
**Current blocker:** None
**Open review finding IDs:** None
**Next exact action:** add ProgramId, Program, barrel exports and focused pure-Dart tests

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

- [ ] Add `ProgramId`.
- [ ] Add minimal `Program`.
- [ ] Export both from Workout barrel.
- [ ] Add focused pure-Dart tests.
- [ ] Audit exact branch delta and CI.

## 6. Quality Review

### Validation Run

```text
Not run yet.
```

### Review Findings and Resolution

| ID | Severity | Status | Finding | Observed at SHA | Evidence or follow-up |
|---|---|---|---|---|---|
| None | | | | | |

## 7. Final Handoff

### Changed Files

Pending.

### Actual Behavior

Pending.

### Known Limitations

Persistence, Program creation naming, Routine ownership implementation and UI remain later slices.

### Final Status

`REVIEW`
