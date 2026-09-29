# W1A3 — Routine composition & SetPrescription domain foundation

**Status:** In progress
**Primary owner:** `apps/shared` Workout domain
**Affected platforms:** shared pure-Dart Workout contracts; no UI/runtime route/persistence change

## Owner Approval and Scope Boundary

**Trigger:** New independently scoped product task/feature slice
**Approval status:** `APPROVED`
**Approval evidence:** Owner said `Go` on 2026-09-29 after the fresh next-slice audit identified W1A3 as the smallest unblocked Workout domain slice and presented the exact pure-Dart boundary.
**Approved product/UI/data-shape boundaries:** Implement only the shared pure-Dart Routine composition contract: `RoutineComposition` keyed by `RoutineId`, ordered `RoutineExercise` entries referencing canonical `ExerciseRef`, and `SetPrescription` with required positive `reps`, optional non-negative finite `loadKg`, and optional non-negative `restSeconds`. `null` means unspecified; zero remains an explicit value for optional load/rest. Composition stays separate from the currently persisted minimal `Routine` entity so the existing repository cannot silently drop composition.
**Explicit non-changes:** No Flutter UI/routes, Supabase table/column/RLS/grant changes, repository/data-source/controller changes, `PerformedSet`/`WorkoutSession`, `TrainingPlan`/`PlannedWorkout`, generated Routine naming, move/copy/archive/delete lifecycle, Program provenance/adoption, Exercise Favorite/Folder/Custom persistence, media, or Quick Start decision.

## Active Handoff

**Planning owner:** Repository architecture audit
**Implementation owner:** Current repository agent on `tnyx/tnyx-78-w1a3-routine-composition`
**Review owner:** Manual Codex-style review because automated Codex code-review quota is exhausted
**Implementation ownership state:** Implementation complete; final handoff validation pending
**Ownership transition:** Not applicable
**Repository state last verified:** 2026-09-29, `main@013299af005bc54e1a3d8afecece6486174f228b`
**Branch:** `tnyx/tnyx-78-w1a3-routine-composition`
**HEAD SHA:** branch created from `013299af005bc54e1a3d8afecece6486174f228b`; source implementation not yet written at this checkpoint
**Observed working-tree state:** GitHub connector branch; no local checkout claimed
**Observed uncommitted/dirty files:** Not observable through connector
**PR / tracker:** Parent Linear TNYX-78 is In Progress. Attempt to create a focused W1A3 child on 2026-09-29 failed because the Linear workspace exceeded its free issue limit; no child ID exists.
**Current implementation state:** Owner-approved and ready for source implementation. Canonical Program/Routine identity and persistence are complete; Routine composition is absent. Fresh audit also confirmed that adding composition directly to `Routine` would create a misleading persistence contract because `RoutineRepository.create(Routine)` currently persists only `id/programId/name`; W1A3 therefore uses a separate canonical composition value contract.
**Relevant execution surface:** `apps/shared/lib/src/workout/**`, `apps/shared/test/workout/**`, this task brief, and the canonical Workout ADR/decision text that currently defers `SetPrescription` fields.
**Validation completed at SHA:** PR #471 source head `07ed2915bd59706237943e379a400b252d905088`: Flutter Analyze PASS, Dart Analyze PASS, Flutter tests PASS, Dart tests PASS, required Commit attribution guard PASS. Supplemental GitHub Advanced Security failed before repository analysis because `claude-opus-5[ReasoningEffort=medium]` is unsupported; no repository finding was produced. Manual Codex-style review found no source/domain blocker.
**Validation remaining:** final exact-head repository revalidation after this handoff-only task update.
**Current blocker:** None inside the approved slice. Automated Codex review is unavailable because code-review quota is exhausted; focused Linear child creation remains unavailable because of the workspace free issue limit, so parent TNYX-78 remains the tracker.
**Open review finding IDs:** None
**Next exact action:** Revalidate the new docs-only exact head, then hand PR #471 back for owner merge approval.

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
Routine(id/program/name)                 existing persisted metadata contract

RoutineComposition(routineId)            new W1A3 value contract
  -> ordered RoutineExercise[]
       -> ExerciseRef
       -> SetPrescription[]
```

The composition contract is intentionally separate from the persisted minimal `Routine` entity until a later persistence slice explicitly stores composition.

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
| Ordered-entry type | Approved: `RoutineExercise` | Small value contract; preserves list order and canonical `ExerciseRef` without inventing persistence identity | Owner-approved implementation audit |
| Repeated Exercise in one Routine | Approved: allowed | No product rule forbids repeats; list order distinguishes entries and avoids an invented uniqueness constraint | Architecture |
| Separate durable composition-entry ID | Deferred | Current slice has no composition persistence/update contract; adding a row identity now would be speculative | Architecture |
| `SetPrescription` fields | Approved: `reps`, optional `loadKg`, optional `restSeconds` | Current W7/Active Workout requirements explicitly need sets/reps/load/rest; kg matches canonical mass storage convention; duration/distance/RPE/RIR are not yet locked | Owner-approved implementation audit |
| Empty composition / empty set list | Approved: allowed | Existing Routine can already exist before composition; execution-readiness is a later W4/W7 policy, not this value contract | Architecture |
| Persist composition now | Rejected for this slice | No approved schema shape; keep domain decision independent | Architecture |
| Implement `PerformedSet` now | Rejected for this slice | Belongs to performed-session/history contract | Future W1/W7 slice |

## 4. Architecture Design

### Chosen Approach

Add immutable `RoutineComposition`, `RoutineExercise`, and `SetPrescription` contracts in `apps/shared`. `RoutineComposition` holds `RoutineId` plus an ordered, defensively copied list of entries. `RoutineExercise` holds canonical `ExerciseRef` plus an ordered, defensively copied list of prescribed sets. `SetPrescription` validates positive reps, finite non-negative kg load when supplied, and non-negative rest seconds when supplied. Do not add composition to `Routine` or change repository/persistence contracts in this slice.

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

- [x] Re-audit current main, open PRs, canonical docs and TNYX-78 immediately before source edits.
- [x] Obtain explicit owner approval for this exact bounded slice.
- [x] Lock minimal ordered composition shape and exact `SetPrescription` fields from current requirements.
- [x] Implement pure-Dart contracts in `apps/shared`.
- [x] Export through the canonical Workout barrel.
- [x] Add focused value/validation/order tests.
- [x] Run applicable analyze/tests and source-head PR review; final docs-only exact-head revalidation remains.
- [ ] Archive this brief only after validated merge.

## 6. Quality Review

### Validation Run

Source head `07ed2915bd59706237943e379a400b252d905088` on PR #471:

```text
Analyze Flutter packages: PASS
Analyze Dart packages: PASS
Test Flutter packages: PASS
Test Dart packages: PASS
Commit attribution guard: PASS (required by current main branch protection)
github-advanced-security: supplemental/non-required infrastructure failure before analysis; requested model unsupported; no repository finding
```

Automated Codex code review is unavailable because the repository bot reports exhausted review quota. Manual Codex-style review found no source/domain blocker. This task-handoff edit moves HEAD, so final exact-head revalidation remains required.

### Review Findings and Resolution

| ID | Severity | Status | Finding | Observed at SHA | Evidence or follow-up |
|---|---|---|---|---|---|
| W1A3-P1 | Planning | Open | Focused Linear child could not be created because workspace free issue limit is exceeded | 2026-09-29 | Keep TNYX-78 as tracker; do not invent an issue ID |

## 7. Final Handoff

### Changed Files

`apps/shared/lib/src/workout/{set_prescription,routine_exercise,routine_composition}.dart`, Workout barrel exports, focused shared tests, ADR-0011, `.ai/DECISIONS.md`, and task/index governance.

### Actual Behavior

Shared pure-Dart callers can construct immutable ordered `RoutineComposition` values keyed by `RoutineId`, with ordered/repeatable `RoutineExercise` entries and immutable `SetPrescription` values. Existing Routine persistence behavior is unchanged and does not claim composition durability.

### Known Limitations

Composition persistence, performed-set history, duration/distance prescriptions, RPE/RIR, builder UI and execution-readiness remain outside this slice. Linear child tracking is blocked by workspace issue limit.

### Final Status

`IN PROGRESS / IMPLEMENTATION COMPLETE / FINAL EXACT-HEAD REVALIDATION PENDING`
