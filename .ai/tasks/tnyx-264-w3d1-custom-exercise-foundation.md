# TNYX-264 W3D1 — Custom Exercise controller/composition foundation

**Status:** In progress
**Primary owner:** Workout Custom Exercises (apps/features/workout)
**Affected platforms:** Flutter phone foundation only; no visible UI in this slice

## Owner Approval and Scope Boundary

**Trigger:** New independently scoped product task/feature slice
**Approval status:** Approved
**Approval evidence:** On 2026-09-30, after a fresh audit proposed the exact bounded W3D1 foundation, the owner replied “Go next”.
**Approved boundaries:** Reuse validated W1B1 UserExerciseRepository/SupabaseUserExerciseRepository; wire fail-closed production composition; add testable UUID-v4 user Exercise ID generation; add immutable Custom Exercise controller/state for active list, create, rename, archive; add focused tests.
**Explicit non-changes:** No visible UI, no route/navigation change, no Library selector UI, no Favorites, no Exercise folders, no Exercise detail, no catalog-fork UI, no richer taxonomy/instructions/media fields, no Supabase migration/table/column/RLS/grant change, no Routine/Program builder or Active Workout integration.

## Active Handoff

**Planning owner:** Current repository agent
**Implementation owner:** Current repository agent
**Review owner:** Unassigned
**Implementation ownership state:** Active
**Ownership transition:** Not applicable
**Repository state last verified:** 2026-09-30, remote main@4881120c723430d6bda8999ce59bd4c7429d932b; no open PRs at slice start
**Branch:** tnyx/tnyx-264-w3d1-custom-exercise-foundation
**HEAD SHA:** 4881120c723430d6bda8999ce59bd4c7429d932b at branch creation
**Observed working-tree state:** Connector-managed remote branch from clean/synced main; no local working-tree state is claimed.
**Observed uncommitted/dirty files:** Not applicable to connector-only repository edits.
**PR / tracker:** Linear TNYX-264 (parent W3 TNYX-80)
**Current implementation state:** Planning/task brief only; production source not yet changed.
**Relevant execution surface:** apps/app/lib/app/composition/workout_providers.dart; Workout Exercise domain/data contracts; apps/features/workout/lib/src/presentation/library/exercises/*; focused Workout/app tests
**Validation completed at SHA:** None yet for this branch.
**Validation remaining:** Focused generator/controller/provider tests; analyze where available; exact branch scope/text review; PR review.
**Current blocker:** None for W3D1 foundation. Broader TNYX-264 visible UI remains a later slice.
**Open review finding IDs:** None.
**Next exact action:** Implement the approved non-UI foundation, validate, open a focused PR, and stop at review/merge gate.

## Global UI / Design-System Guardrail

This slice intentionally makes no Flutter production UI change. apps/core/lib/src/theme/README.md and apps/features/AGENTS.md were re-read during audit. Any later Custom Exercise UI slice requires its own approved visible scope.

## 1. Discovery

### User Outcome

Prepare the real Custom Exercise capability so later Library Exercises UI can use durable user-owned Exercise data without temporary/local state.

### Success Criteria

- Production composition exposes the canonical user-owned Exercise repository when Supabase is available and null otherwise.
- No in-memory production success fallback exists.
- User-created Exercise UUIDs are generated through a testable domain boundary.
- Controller loads active user Exercises and supports create, rename, archive.
- Create retry preserves one pending Exercise identity until the durable outcome is reconciled.
- State is immutable with explicit loading/load-failed/action-in-flight/action-error behavior.
- No visible UI, routing, or database shape changes occur.

### Scope

- Workout app composition Provider<UserExerciseRepository?>.
- UserExerciseIdGenerator + UUID-v4 implementation.
- CustomExercisesController + immutable state.
- Barrel exports required by the public Workout package.
- Focused unit/provider tests.

### Non-Goals

Library selector/cards/pills; visible Custom Exercise editor/list; Favorites; folders; catalog variation UI; new persisted fields; Supabase changes; Program/Routine composition; TrainingPlan/Active Workout.

## 2. Codebase Exploration

### Verified Evidence

- main@4881120c has no open PRs after #492 merged.
- TNYX-264 was reconciled: W3A is Done and W1B1 persistence is live/validated.
- UserExerciseRepository already exposes list/create/rename/archive and optional immutable catalog-source lineage.
- SupabaseUserExerciseRepository lists empty when signed out and write operations fail with Please sign in to save Exercises.
- programRepositoryProvider is the current durable fail-closed composition precedent.
- UuidProgramIdGenerator is the current UUID-v4/testability precedent.
- ProgramsController is the current persisted collection/stable-ID retry precedent.
- Current production source does not wire SupabaseUserExerciseRepository into app composition and has no Custom Exercise controller/state/UI.

## 3. Clarification

| Decision | Status | Rationale | Owner |
|---|---|---|---|
| First W3D slice is non-UI foundation | Approved | Avoid temporary Library UI before real capability backing | Owner |
| Reuse W1B1 persistence unchanged | Approved/current truth | Minimal name/status/lineage contract is live | Owner + W1B1 |
| Production repository fails closed without Supabase | Decided | No fake local durable success | Architecture |
| UUID generation uses feature-domain generator boundary | Decided | Testable and follows Program pattern | Architecture |
| Active view excludes archived rows by default | Decided/current contract | Archive preserves stable identity/history | W1B1/TNYX-264 |
| Richer taxonomy/instructions/media deferred | Approved non-goal | W1B1 does not persist them | Owner |

## 4. Architecture Design

Chosen flow: future UI -> CustomExercisesController -> UserExerciseRepository -> SupabaseUserExerciseRepository -> public.user_workout_exercises.
ID generation: CustomExercisesController -> UserExerciseIdGenerator -> UUID-v4 -> UserCreatedExerciseRef.

Rejected: in-memory production fallback; UUID calls in widgets; richer fields now; visible Library/Custom UI in this slice.

## 5. Implementation Plan

- [ ] Add UserExerciseIdGenerator and UUID-v4 implementation.
- [ ] Add immutable CustomExercisesState / CustomExercisesController.
- [ ] Preserve one pending Exercise ID across create retry/reconciliation.
- [ ] Add app-level userExerciseRepositoryProvider with fail-closed null behavior.
- [ ] Export new feature contracts through existing barrels only as needed.
- [ ] Add focused generator/controller/provider tests.
- [ ] Run exact scope/validation review.
- [ ] Open PR and request review.

## 6. Quality Review

### Validation Run

Not run yet.

### Review Findings and Resolution

| ID | Severity | Status | Finding | Observed at SHA | Evidence or follow-up |
|---|---|---|---|---|---|

## 7. Final Handoff

### Changed Files

Pending.

### Actual Behavior

No runtime behavior change yet.

### Known Limitations

Visible Custom Exercise UX, richer definition fields, Favorites, folders, catalog forks and Library integration remain later slices.

### Final Status

REVIEW