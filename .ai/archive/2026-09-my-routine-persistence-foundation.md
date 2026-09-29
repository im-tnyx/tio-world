# My Routine persistence foundation

**Status:** Validated
**Completion date:** 2026-09-29
**Primary owner:** `supabase/` + `apps/features/workout`
**Affected platforms:** Supabase Postgres/RLS and Workout feature data/domain repository boundary

## Owner Approval and Scope Boundary

**Trigger:** New independently scoped persistence slice + Supabase table shape change
**Approval status:** Approved
**Approval evidence:** Owner requested “Next audit ke baad go”; the fresh post-PR #462 audit resolved the minimum Routine persistence shape and the pre-authorized go applies to that exact bounded result.
**Approved data shape:** `public.user_workout_routines(id uuid PK, user_id uuid NOT NULL, program_id uuid NOT NULL, name text NOT NULL, created_at timestamptz NOT NULL, updated_at timestamptz NOT NULL)`; parent ownership key `user_workout_programs(id,user_id)`; composite FK `(program_id,user_id) -> user_workout_programs(id,user_id) ON DELETE CASCADE`; nonblank name; owner RLS; minimal list/create/rename repository.
**Explicit non-changes:** No Routine composition/exercise/set tables; no ordering; no move/copy/delete/archive repository API; no generated naming; no UI/routes/controllers; no media; no provenance/revision/source persistence; no TrainingPlan/session behavior; no authoritative Tio/Coach source tables.

## Active Handoff

**Planning owner:** None; this bounded persistence slice is complete.
**Implementation owner:** None; source merged and hosted migration deployed.
**Review owner:** Completed.
**Implementation ownership state:** Inactive.
**Repository state:** Source merged via PR #463 as `71fef2c9e2393e89c4cf415799a5ae8f5e7e4d8a`; current post-deploy reconciliation base is `main@e9aa69b5f1176d87bcf79bca7ccdf407645da28e`.
**Tracker:** TNYX-78 remains In Progress because W1 is broader than this persistence slice.
**Source validation:** Final PR head `0674cc502066fd9cddb3f4f35e80322707584254`; Flutter CI #2853 and Supabase Database CI #84 passed; 0 unresolved review threads.
**Hosted deployment:** `20260929050000_create_user_workout_routines` was deployed on 2026-09-29 using Supabase CLI v2.116.0 after `migration list` and `db push --dry-run` proved it was the only pending migration.
**Hosted verification:** Repository/live migration history is 51 / 51 by version + name; `public.user_workout_routines` is live with the approved six-column shape, owner-safe composite FK, trigger, RLS, grants and policies; no production rows were inserted.
**Security result:** No new Routine-specific Security Advisor finding.
**Performance follow-up:** Supabase Performance Advisor reports INFO `unindexed_foreign_keys` for `user_workout_routines_program_owner_fkey`. The existing `(user_id, program_id, created_at DESC)` index contains both columns but is not recognized as a covering index for FK order `(program_id,user_id)`. This is a non-blocking optimization follow-up, not a deployment/security failure.
**Follow-up boundary:** Composition, ordering, generated naming, move/copy/delete/archive product semantics, UI, source provenance and TrainingPlan/session behavior remain separate future slices.

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
- [x] Verify final PR head and post-merge hosted deployment.

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

Composition, ordering, generated naming, move/copy/delete/archive product semantics, UI, source provenance and TrainingPlan/session behavior remain intentionally deferred. Supabase Performance Advisor INFO `unindexed_foreign_keys` for the composite Program-owner FK remains a separate non-blocking optimization follow-up.

### Final Status

`VALIDATED`


## Post-deploy verification

- Supabase CLI v2.116.0 matched the repository DB CI version.
- Pre-deploy `migration list` showed the first 50 migrations aligned and only `20260929050000` pending remotely.
- `db push --dry-run` listed only `20260929050000_create_user_workout_routines.sql`.
- `db push` applied exactly that migration.
- Final CLI list and independent Supabase verification show 51 repository migrations and 51 live migrations with zero repo-only or live-only versions.
- Live catalog snapshot: 16 ordinary `public` tables, 158 columns, 16 primary keys, 17 foreign keys, 5 unique constraints, 56 checks, 96 total constraint records, 44 indexes and RLS enabled on all 16 tables.
- `user_workout_routines` has 0 rows after deployment; no production test fixtures were inserted.
- Authenticated privileges are SELECT, INSERT and column-level UPDATE on `name`; DELETE, table-level UPDATE, `program_id` UPDATE and `user_id` UPDATE are not granted.
- Security Advisor has no Routine-specific finding. Pre-existing SECURITY DEFINER executable warnings and leaked-password-protection warning remain outside this slice.
- Performance Advisor reports one new Routine-specific INFO finding for the composite FK index order. No schema mutation was made during post-deploy reconciliation.
