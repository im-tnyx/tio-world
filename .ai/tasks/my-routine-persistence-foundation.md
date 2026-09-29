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

**Planning owner:** Current repository agent
**Implementation owner:** Current repository agent
**Review owner:** Unassigned
**Implementation ownership state:** Active
**Repository state last verified:** remote `main@537fcbd5f973e13208206ed4099d75f119607cf9`
**Branch:** `tnyx/my-routine-persistence-foundation`
**HEAD SHA:** base at branch creation
**Observed working-tree state:** Connector-only session; local status unavailable.
**PR / tracker:** TNYX-78; PR pending.
**Current implementation state:** Approved persistence slice started.
**Validation remaining:** exact-head Flutter CI, Supabase Database CI, review, live deployment only after merge/authorization.
**Next exact action:** Add migration + minimal feature repository/adapter/tests.

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

## Implementation Plan

- [ ] Add minimum migration, ownership invariant, index, trigger, grants and owner RLS.
- [ ] Add `RoutineRepository` with list/create/rename only.
- [ ] Add Supabase gateway/adapter following Program repository conventions.
- [ ] Add focused repository tests.
- [ ] Validate exact-head CI/security/review.

## Final Handoff

Pending.
