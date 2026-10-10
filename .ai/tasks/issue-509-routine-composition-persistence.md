# GitHub #509 — Program-owned Routine composition persistence

**Status:** In progress
**Primary owner:** Workout persistence (`supabase/`, `apps/features/workout`)
**Affected platforms:** Flutter data/domain boundary and Supabase schema/RLS/RPC; no visible UI

## Owner Approval and Scope Boundary

**Trigger:** New bounded persistence slice + Supabase table/column shape change
**Approval status:** Approved for the exact physical contract documented in GitHub #509 on 2026-10-10.
**Approval evidence:** After the assistant explicitly asked whether the owner approved the exact #509 database schema/RPC proposal and described both new tables/two new Routine columns, the owner replied `go with follow agent.md` on 2026-10-10.
**Approved boundaries:** Two additive columns `user_workout_routines.composition_revision` and `last_composition_mutation_id`, owner-safe unique key, two relational child tables with positions and stable row identities, owner RLS/read-only Data API, narrow authenticated atomic save RPC, and repository/test support. Explicit physical details: GitHub #509.
**Explicit non-changes:** No product-visible UI, Routine builder, Program detail, default My Program identity, Exercise Favorites/Folders, TrainingPlan/WorkoutSession, Exercise measurements outside reps/loadKg/restSeconds, source/adoption, media/Storage, new services/API or production rollout.

## Active Handoff

**Planning owner:** Current repository agent
**Implementation owner:** Current repository agent — one bounded #509 slice
**Review owner:** Codex GitHub review and exact-head CI
**Implementation ownership state:** Active
**Repository state last verified:** Remote `main@c5a1852d00afeb987a1834a28a39d5c6185d9763` on 2026-10-10; GitHub no competing open Routine composition PR; Linear TNYX-78 In Progress, TNYX-81 Backlog/blocked.
**Branch:** `tnyx/issue-509-routine-composition-persistence`
**HEAD SHA:** Branch originally created at main SHA above; refresh before each push.
**Observed working-tree state:** Connector-only API session, no local worktree; no local dirty-state claim.
**Observed uncommitted/dirty files:** Not available from GitHub connector.
**PR / tracker:** GitHub #509; Linear TNYX-78 and TNYX-81; GitHub #475
**Current implementation state:** Approved DB-first slice committed to branch: one additive migration/RPC and focused transactional SQL regression matrix. No live deployment; feature repository adapter not yet implemented.
**Relevant execution surface:** `supabase/migrations`, `supabase/tests/database`, `apps/features/workout/lib/src/{domain,data}`, related tests.
**Validation completed at SHA:** Read-only source, live schema/constraints/indexes/privileges and accepted ADR reconciliation only.
**Validation remaining:** Migration SQL/db regression matrix, Flutter/Dart analyze/tests, Supabase database CI, security/Codex exact-head review. Live deployment is **not** authorized by PR creation/merge alone.
**Current blocker:** None for approved bounded implementation; no local Flutter/Dart/Supabase CLI present in connector-only session.
**Open review finding IDs:** None.
**Next exact action:** Open DB-foundation PR; request exact-head Codex and Supabase Database CI, address findings. Subsequent bounded feature repository adapter remains pending until schema foundation is validated.

## 1. Discovery

### User Outcome
Durably store ordered Routine Exercise references and prescribed sets inside exactly one user-owned Program/Routine without losing data, mixing user ownership, or enabling incomplete execution UI.

### Success Criteria
- Persist repeated canonical Exercise references with independent entry IDs/order.
- Persist ordered prescribed sets with positive reps, nullable finite nonnegative kg, nullable nonnegative rest seconds.
- Atomic RPC with authenticated owner identity, revision check and safe idempotent retry.
- Read owner-isolated ordered composition; preserve old Routine metadata repository semantics.
- SQL security/constraint/regression tests and Dart mapping/retry tests; no UI change.

### Scope
GitHub #509 exact approved database physical shape; new feature-owned repository boundary.

### Non-Goals
Default My Program, builder/detail/UI, delete/move Program/Routine, TrainingPlan/session, catalog mirroring, new backend.

## 2. Codebase Exploration

### Verified Evidence
- `RoutineComposition`, `RoutineExercise`, `SetPrescription`, `ExerciseRef` exist as immutable `apps/shared` contracts.
- `RoutineRepository` is metadata-only `list/create/rename`; preserve it.
- Live `public.user_workout_routines` has 6 columns, composite Program owner FK; `user_workout_exercises` has 12 columns and unique `(id,user_id)`.
- Existing grants: `authenticated` SELECT/INSERT/UPDATE(name) only on Program and Routine; both owner RLS enabled.
- Existing atomic security-definer RPC precedent: `supabase/migrations/20260917092920_create_detailed_meal_log_rpc.sql`; revision precedent: `20260912064635_add_meal_log_revision.sql`.

## 3. Clarification

| Decision | Status | Rationale | Owner |
|---|---|---|---|
| Two relational child tables rather than one JSONB column | Approved | Separate durable entries and owner-safe User Exercise FK | Owner via #509 |
| RPC transaction rather than direct child Data API writes | Approved | Atomic complete snapshot, least privilege | Owner via #509 |
| No new WorkoutSession snapshot model now | Approved non-goal | Preserve W4/W7 ownership | Owner via #509 |

## 4. Architecture Design

```text
Future W4 controller -> feature RoutineCompositionRepository
 -> Supabase RPC (owner-checked atomic save) + owner-scoped consistent read
 -> Routine -> RoutineExercise[] -> SetPrescription[]
```

- Independent stable UUIDs for repeated Exercise entries and Sets.
- Monotonic `composition_revision` and last mutation token for stale-write/retry checks.
- Schema-qualified SECURITY DEFINER with locked owner Routine and restricted execute; child tables SELECT-only authenticated with owner RLS.

**Rejected:** Client-side multi-request writes, duplicate catalog tables, premature `services/api`.

## 5. Implementation Plan

- [x] Commit proposed additive migration with exact approved tables/columns, owner-safe FKs/RLS and narrowly scoped save RPC; database execution not yet verified.
- [x] Add transactional SQL RLS/privilege/integrity/revision/idempotency regression matrix; execution pending CI.
- [ ] Feature-owned composition gateway/repository with validation and reconciliation.
- [ ] Tests and exact-head CI/security/Codex gate; no live apply.
- [ ] Update schema inventory and completion handoff after observed validation.

## 6. Quality Review

### Validation Run
Not run yet. GitHub connector cannot execute local `git diff --check`, Flutter, Dart or Supabase CLI; request executable checks in PR CI.

### Review Findings and Resolution
None yet.

## 7. Final Handoff

### Changed Files
- `.ai/tasks/README.md` + this handoff.
- `supabase/migrations/20261010061809_create_user_workout_routine_composition.sql`.
- `supabase/tests/database/tnyx_509_routine_composition.test.sql`.

### Actual Behavior
Migration/RPC and test source proposed on branch only; hosted database untouched. No Flutter/UI/runtime capability shipped.

### Known Limitations
No production editor/wiring until later approved W4; live database remains unchanged until separate deployment gate.

### Final Status
`PARTIAL` — active bounded implementation.
