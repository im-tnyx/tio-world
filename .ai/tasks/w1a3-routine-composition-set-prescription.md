# W1A3 — Routine composition & SetPrescription domain foundation

**Status:** Ready
**Primary owner:** `apps/shared` Workout domain
**Affected platforms:** shared pure-Dart Workout contracts; no UI/runtime route/persistence change

## Owner Approval and Scope Boundary

**Trigger:** New independently scoped product task/feature slice
**Approval status:** `AWAITING OWNER APPROVAL`
**Approval evidence:** Owner approved the 2026-09-29 governance cleanup and next-slice planning only. Source implementation has not been approved.
**Approved product/UI/data-shape boundaries:** Planning/handoff only. Proposed implementation boundary is the smallest pure-Dart Routine composition + `SetPrescription` contract after a fresh implementation audit.
**Explicit non-changes:** No Flutter UI/routes, Supabase table/column/RLS/grant changes, repository/data-source/controller changes, `PerformedSet`/`WorkoutSession`, `TrainingPlan`/`PlannedWorkout`, generated Routine naming, move/copy/archive/delete lifecycle, Program provenance/adoption, Exercise Favorite/Folder/Custom persistence, media, or Quick Start decision.

## Active Handoff

**Planning owner:** Repository architecture audit
**Implementation owner:** None
**Review owner:** Unassigned
**Implementation ownership state:** Not started
**Ownership transition:** Not applicable
**Repository state last verified:** 2026-09-29, `main@bb525d5ba6ce938d5b5a01b12221389cb5b8f7fd`
**Branch:** `docs/w1-handoff-cleanup-routine-composition-plan` for planning/governance only
**HEAD SHA:** Planning branch; implementation branch not created
**Observed working-tree state:** GitHub connector branch; no local checkout claimed
**Observed uncommitted/dirty files:** Not observable through connector
**PR / tracker:** Parent Linear TNYX-78 is In Progress. Attempt to create a focused W1A3 child on 2026-09-29 failed because the Linear workspace exceeded its free issue limit; no child ID exists.
**Current implementation state:** Not started. Canonical Program/Routine identity and persistence are already complete; Routine composition is still absent.
**Relevant execution surface:** Proposed future implementation: `apps/shared/lib/src/workout/**` and `apps/shared/test/workout/**`.
**Validation completed at SHA:** Read-only architecture/source/tracker audit at `main@bb525d5ba6ce938d5b5a01b12221389cb5b8f7fd`.
**Validation remaining:** Fresh source audit immediately before implementation; focused pure-Dart tests/analyze; exact-head PR/CI review.
**Current blocker:** Implementation requires explicit owner approval. Focused Linear child creation is additionally blocked by workspace free issue limit.
**Open review finding IDs:** None
**Next exact action:** Owner approves or adjusts this exact bounded pure-Dart slice; then create an implementation branch/task checkpoint and implement only the approved contract.

## 1. Discovery

### User Outcome

Establish one canonical reusable Routine composition contract so later Program/Routine builders do not invent competing exercise/set shapes.

### Success Criteria

- one canonical ordered Routine composition shape references `ExerciseRef`;
- template/prescribed set truth uses `SetPrescription`;
- ordering is deterministic and identity-safe;
- the minimum prescription fields are justified by current audited product requirements;
- `SetPrescription` remains distinct from future performed-history `PerformedSet`;
- no persistence/UI/session/scheduling scope leaks into this slice.

### Scope

Proposed future implementation, after owner approval:

```text
Routine
  -> ordered composition entries
       -> ExerciseRef
       -> SetPrescription[]
```

Exact type names and exact `SetPrescription` fields are not frozen by this planning brief. They must be chosen from the fresh implementation audit and existing canonical product contracts.

### Non-Goals

See the explicit non-changes above. In particular, this slice does not implement W4 builders, W7 session logging, W9 scheduling, or W1B0 dynamic Exercise persistence.

## 2. Codebase Exploration

### Verified Evidence

- Root `AGENTS.md`, task governance and canonical Workout ADRs were reconciled before this planning update.
- ADR-0011 owns `ExerciseRef` identity and the terminology split `SetPrescription` vs `PerformedSet`.
- ADR-0015 owns Program-owned Routine semantics.
- Current shared source has canonical `ExerciseRef`, `Exercise`, `ProgramId`, `Program`, `RoutineId`, `Routine`, `TrainingPlanId`, `PlannedWorkoutId`, and `WorkoutSessionId`.
- Current `Routine` is intentionally minimal: `id + programId + name`; no composition contract exists.
- Repository search found no runtime `SetPrescription` or `PerformedSet` class and no canonical `TrainingPlan`, `PlannedWorkout`, or `WorkoutSession` entity implementation.
- PR #460 and PR #462 validated the Program/Routine domain foundations; their stale active task briefs are archived by the planning cleanup that created this brief.
- TNYX-81 W4 needs canonical Program/Routine composition/builders and remains blocked by TNYX-78.

### Existing pattern to follow

Use immutable pure-Dart value/entity contracts in `apps/shared`, with focused tests and public Workout barrel exports. Feature-specific repository/controller/UI ownership remains in `apps/features/workout`.

### Tests or validation already present

Focused tests exist for `ExerciseRef`, `Exercise`, `Program`, `ProgramId`, `Routine`, and `RoutineId`.

## 3. Clarification

### Decisions Required or Made

| Decision | Status | Rationale | Owner |
|---|---|---|---|
| Routine composition references canonical `ExerciseRef` | Architecture-locked | ADR-0011 forbids cloned catalog Exercise truth | ADR-0011 |
| Template sets are `SetPrescription`; performed history uses `PerformedSet` | Architecture-locked | Prevents template/history conflation | ADR-0011 |
| Exact ordered-entry type/name | To decide in implementation audit | Avoid speculative abstraction | Future approved slice |
| Exact `SetPrescription` fields/measurement kinds | To decide in implementation audit | ADR-0011 explicitly deferred these fields | Future approved slice |
| Persist composition now | Rejected for this slice | No approved schema shape; keep domain decision independent | Architecture |
| Implement `PerformedSet` now | Rejected for this slice | Belongs to performed-session/history contract | Future W1/W7 slice |

## 4. Architecture Design

### Chosen Approach

Extend canonical shared Workout domain only after owner approval. Prefer a small immutable ordered composition model that references `ExerciseRef` and contains prescription values without importing Flutter, Supabase, repositories, or presentation concerns.

### Ownership and Data Flow

```text
apps/shared canonical Routine composition
        ↓
future apps/features/workout Routine repository/controller
        ↓
future W4 Routine/Program builder UI
```

### Alternative Rejected

Do not let W4 widgets/controllers define ad-hoc exercise/set DTOs first and later migrate them into canonical domain. That would create competing truth and increase persistence/session migration risk.

### Failure and Accessibility States

Domain validation must reject structurally invalid prescription/composition values once exact fields are approved. Accessibility is not applicable to this pure-Dart slice.

## 5. Implementation Plan

- [ ] Re-audit current main, open PRs, canonical docs and TNYX-78 immediately before source edits.
- [ ] Obtain explicit owner approval for this exact bounded slice.
- [ ] Lock minimal ordered composition shape and exact `SetPrescription` fields from current requirements.
- [ ] Implement pure-Dart contracts in `apps/shared`.
- [ ] Export through the canonical Workout barrel.
- [ ] Add focused value/validation/order tests.
- [ ] Run applicable analyze/tests and exact-head PR review.
- [ ] Archive this brief only after validated merge.

## 6. Quality Review

### Validation Run

```text
Planning/read-only audit only. No source implementation or runtime validation has been performed for W1A3.
```

### Review Findings and Resolution

| ID | Severity | Status | Finding | Observed at SHA | Evidence or follow-up |
|---|---|---|---|---|---|
| W1A3-P1 | Planning | Open | Focused Linear child could not be created because workspace free issue limit is exceeded | 2026-09-29 | Keep TNYX-78 as tracker; do not invent an issue ID |

## 7. Final Handoff

### Changed Files

Planning brief only until owner approval.

### Actual Behavior

No runtime behavior changes.

### Known Limitations

Exact composition entry naming and `SetPrescription` measurement fields remain intentionally unresolved until the implementation audit. Linear child tracking is blocked by workspace issue limit.

### Final Status

`READY / AWAITING OWNER APPROVAL`
