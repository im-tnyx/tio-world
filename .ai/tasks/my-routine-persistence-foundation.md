# My Routine persistence foundation

**Status:** In progress
**Primary owner:** `supabase/` + `apps/features/workout`
**Affected platforms:** Supabase Postgres/RLS and Workout feature data/domain repository boundary

## Owner Approval and Scope Boundary

**Trigger:** New independently scoped persistence slice + Supabase table shape change
**Approval status:** Approved
**Approval evidence:** Owner requested “Next audit ke baad go”; the fresh post-PR #462 audit resolved the minimum Routine persistence shape and the pre-authorized go applies to that exact bounded result.
**Approved data shape:** `public.user_workout_routines(id uuid PK, user_id uuid NOT NULL, program_id uuid NOT NULL, name text NOT NULL, created_at timestamptz NOT NULL, updated_at timestamptz NOT NULL)`; parent ownership key `user_workout_programs(id,user_id)`; composite FK `(program_id,user_id) -> user_workout_programs(id,user_id) ON DELETE CASCADE`; nonblank name; owner RLS; minimal list/create/rename repository.
**Explicit non-changes:** No Routine composition/exercise/set tables; no ordering; no move/copy/delete/archive repository API; no generated naming; no UI/routes/controllers; no media; no provenance/revision/source persistence; no TrainingPlan/session behavior; no authoritative Tio/Coach source tables.

## Active Handoff

**Planning owner:** Current repository agent for deployment readiness only.
**Implementation owner:** None; repository implementation merged.
**Review owner:** Completed for PR #463.
**Implementation ownership state:** Inactive until a separately authorized live deployment step.
**Repository state last verified:** remote `main@71fef2c9e2393e89c4cf415799a5ae8f5e7e4d8a`.
**Branch / PR:** Source branch merged; GitHub PR #463 squash-merged as `71fef2c9e2393e89c4cf415799a5ae8f5e7e4d8a`.
**Tracker:** TNYX-78 remains In Progress because W1 is broader than this slice.
**Current implementation state:** Repository migration, owner-safe Routine repository, focused Flutter tests and focused database security matrix are merged.
**Validation completed:** Final PR head `0674cc502066fd9cddb3f4f35e80322707584254`; Flutter CI #2853 and Supabase Database CI #84 passed; 0 unresolved review threads.
**Hosted state:** `public.user_workout_routines` is still absent. No Routine migration has been applied live.
**Migration lineage prerequisite:** Program migration identity is being reconciled repo-only to the existing hosted version `20260929040034`; Routine remains `20260929050000`.
**Current blocker:** No product/code blocker. Live deployment remains intentionally unperformed and requires explicit owner authorization after migration-lineage reconciliation is merged.
**Next exact action:** Finish the repo-only lineage reconciliation, then perform a fresh live deployment gate before any `apply_migration`.

## Discovery / Architecture

ADR-0015 requires each saved user Routine to belong to exactly one user-owned Program. Live `user_workout_programs` is the current owner table and live Routine table is absent. Direct Routine `user_id` supports efficient owner RLS, while a composite parent FK prevents a caller from pairing their own `user_id` with another user's `program_id`.

```text
user_workout_programs
  UNIQUE (id, user_id)
        ↑ composite owner FK
user_workout_routines
  id
  user_id
  program_id
  name
  created_at
  updated_at
```

Authenticated clients receive only `SELECT`, `INSERT`, and column-level `UPDATE(name)`. They do not receive Routine `DELETE` or direct `program_id`/`user_id` update privileges, so deferred move/delete semantics are not exposed through the Data API.

## Implementation Plan

- [x] Add minimum migration, ownership invariant, index, trigger, grants and owner RLS.
- [x] Add `RoutineRepository` with list/create/rename only.
- [x] Add Supabase gateway/adapter following Program repository conventions.
- [x] Add focused repository tests.
- [x] Add focused SQL matrix for same-owner FK, RLS and least-privilege grants.
- [x] Run exact-source-head Flutter and Supabase Database CI.
- [ ] Verify final PR head after this handoff-only update.

## Quality Review

### Validation Run

- Flutter CI #2852: **success** at `3a84a334f6185c245b1e15ee020f2c65dc591b49`.
- Supabase Database CI #83: **success** at the same SHA.
- The DB job replayed all migrations from scratch, verified the migration ledger, ran the new TNYX-78 Routine SQL matrix, and rejected newly introduced database lint errors.
- Repository rulesets endpoint returned no rulesets. Branch-protection details could not be independently read because the connected GitHub integration returned HTTP 403 for that administration-protected endpoint. Required-check status is therefore not inferred from names; Flutter CI and Supabase Database CI remain explicit task/PR merge gates.
- Live Supabase was not modified during PR validation.

### Review Findings and Resolution

| ID | Severity | Status | Finding | Resolution |
|---|---|---|---|---|
| ROUTINE-P1 | P1 | Resolved | Flutter test imported nonexistent `package:workout`, causing CI #2848 analyze failure. | Corrected package import; later exact-source-head Flutter CI #2852 passed. |
| ROUTINE-P2 | P2 | Resolved | Routine auth adapter did not trim/reject blank injected user IDs like the existing Program adapter; test also bypassed public package boundary. | Aligned auth handling and switched test to `package:tio_feature_workout/workout.dart`. |
| ROUTINE-P3 | P1 | Resolved | Generic migration replay did not directly prove the new composite ownership FK/RLS/rename-only/no-delete contract. | Added `tnyx_78_user_workout_routines.test.sql` and wired it into Supabase DB CI; #83 passed. |

No open review findings remain.

## Final Handoff

### Changed Areas

- minimal Routine migration and owner integrity constraint;
- least-privilege Routine RLS/grants;
- feature Routine repository + Supabase adapter;
- repository tests;
- focused Supabase SQL security matrix + CI step.

### Actual Behavior

Signed-in users can list Routines for one owned Program, create a Routine only under a Program owned by the same user, and rename their own Routine. Signed-out reads return empty; signed-out writes fail. Authenticated clients cannot directly move a Routine by changing `program_id`, change `user_id`, or delete Routine rows through the new table privileges.

### Known Limitations

Composition, ordering, generated naming, move/copy/delete/archive product semantics, UI, source provenance and TrainingPlan/session behavior remain intentionally deferred. Live deployment and live advisor verification remain pending after the merged PR and require a separately authorized hosted step.

### Final Status

`MERGED / AWAITING LIVE DEPLOYMENT`
