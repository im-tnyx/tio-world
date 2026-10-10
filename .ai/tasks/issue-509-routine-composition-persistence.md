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
**Current implementation state:** Approved database-first slice on branch: one additive migration/RPC, focused transactional security matrix and actual two-session Routine race test wired to CI. No live deployment; feature repository adapter not yet implemented.
**Relevant execution surface:** `supabase/migrations`, `supabase/tests/database`, `apps/features/workout/lib/src/{domain,data}`, related tests.
**Validation completed at SHA:** Supabase Database CI run `38032039764` on `c0b38e1dfa252bfeb54312772e90eecc17f88881`: **SUCCESS** after fixture typo fix; full migration replay, TNYX-509 SQL matrix, focused **two-session Routine revision race** (winner preserved, stale writer rejected), existing concurrency suite and DB lint all passed. This handoff-only commit advances the head; reverify exact-head CI.
**Validation remaining:** New exact-head CI after this handoff-only commit and Codex review/security findings. No Flutter/UI source changed and no local Flutter/Dart checks are claimed. Live deployment is **not** authorized by PR creation/merge alone.
**Current blocker:** None for approved bounded implementation; no local Flutter/Dart/Supabase CLI present in connector-only session.
**Open review finding IDs:** PR #511 threads `PRRT_kwDOTOXwB86rB1pV` (INSERT privilege), `PRRT_kwDOTOXwB86rB1pZ` (custom Exercise FK index), `PRRT_kwDOTOXwB86rB1pc` (quadratic JSONB accumulation). Patches are pending new exact-head CI and review; threads remain unresolved.
**Next exact action:** PR #511 is open. Audit Codex and new exact-head CI after this final handoff update; resolve security/review findings and stop at explicit owner merge gate. Feature repository adapter is the next separate bounded slice.

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
- [x] Add transactional SQL RLS/privilege/integrity/revision/idempotency matrix; executed PASS in DB CI `38031445331`.
- [ ] Feature-owned composition gateway/repository with validation and reconciliation.
- [ ] Final exact-head CI/Codex gate (prior DB CI `38031445331` PASS); no live apply.
- [ ] Update schema inventory and completion handoff after observed validation.

## 6. Quality Review

### Validation Run
Supabase Database CI `38032039764`: PASS at `c0b38e1dfa252bfeb54312772e90eecc17f88881`. Disposable complete migration replay, Routine matrix, exact Routine two-session stale-writer race, existing concurrency suite and DB lint passed. This handoff edit advances HEAD; current-head CI/Codex remain required. No local `git diff --check`, Flutter, Dart or Supabase CLI execution is claimed.

### Review Findings and Resolution
All three Codex P2 findings confirmed against source and the live old-schema grants. This review-fix commit constrains Routine INSERT to six legacy metadata columns, indexes the partial custom-Exercise FK, moves owner locking ahead of nested JSON work, and replaces quadratic array concatenation/duplicate scans with ordered set-based aggregation. SQL tests add denied revision/token injection, positive metadata INSERT grants, partial FK index existence, and bounded 350-Set payload coverage. **New head has not yet passed CI/re-review.** No live Supabase mutation, UI or Dart code changes.

## 7. Final Handoff

### Changed Files
- `.ai/tasks/README.md` + this handoff.
- `supabase/migrations/20261010061809_create_user_workout_routine_composition.sql`.
- `supabase/tests/database/tnyx_509_routine_composition.test.sql`.
- `supabase/tests/database/tnyx_509_routine_composition_concurrency.sh` — actual simultaneous authenticated saves.
- `.github/workflows/supabase-db-ci.yml` — both Routine SQL matrices wired into CI.

### Actual Behavior
Migration/RPC and SQL regression matrix committed on branch, tested on disposable CI database. Hosted Supabase untouched; no Flutter/UI/runtime capability shipped.

### Known Limitations
No production editor/wiring until later approved W4; live database remains unchanged until separate deployment gate.

### Final Status
`PARTIAL` — active bounded implementation.
