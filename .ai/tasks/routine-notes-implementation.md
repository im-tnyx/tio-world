# Routine Notes Persistence Foundation

**Status:** In progress
**Primary owner:** Codex (current implementation session)
**Affected platforms:** Shared, Workout feature, Supabase database

## Owner Approval and Scope Boundary

**Trigger:** Supabase table/column shape change
**Approval status:** Approved
**Approval evidence:** Owner-approved Slice 1 implementation kickoff supplied on 2026-10-29: `Implement Slice 1 — Routine Notes Persistence Foundation`.
**Approved product/UI/data-shape boundaries:** Durable owner-scoped Routine and Exercise Notes foundation; stable UUID identity; canonical `ExerciseRef` serialization; five active Notes per canonical scope; 500-character normalized body; revision-checked protected mutations; durable `(user_id, mutation_id)` receipts; owner-scoped reads; no UI in this slice.
**Explicit non-changes:** No Notes UI, Routine Set or Rest Timer changes, WorkoutSession/history integration, post publishing, hosted migration apply, production privilege activation, issue/status mutation, merge or deployment. Commit, branch push and Draft PR creation are authorized only for this validated Slice 1 handoff.

## Active Handoff

**Planning owner:** Product owner / existing W4 planning
**Implementation owner:** Codex (current implementation session)
**Review owner:** Not assigned
**Implementation ownership state:** Active
**Ownership transition:** Not applicable
**Repository state last verified:** 2026-10-29; Slice 1 review-fix work is committed and pushed
**Branch:** `tnyx/routine-notes-persistence`
**Current branch HEAD SHA:** `30e0a7733c9ddba45957a846c4c60dd90b08a783`
**Validated code head SHA:** `435f74f92b4d503505f14173f28bcdf9dc4ab99a` (the later commits are documentation-only)
**Slice 1 commit:** `ec8a314e` (`feat(database): add routine notes persistence foundation`)
**Observed working-tree state:** Clean after review-fix commits; no unrelated files observed
**Observed uncommitted/dirty files:** None
**PR / tracker:** Linear `TNYX-81` parent; no dedicated Notes issue created
**Current implementation state:** Domain, migration/RPC, repository adapter and focused tests plus Slice 1 review fixes are committed and pushed in Draft PR #717; hosted migration unapplied
**Relevant execution surface:** `apps/shared`, `apps/features/workout`, `supabase/migrations`, `supabase/tests/database`
**Validation completed at working tree:** Dart format/analyze for the changed Workout test, transaction-scoped SQL migration plus Notes matrix replay with rollback, shell syntax validation for the race harness, and `git diff --check`.
**Validation remaining:** Independent review and owner merge approval. The local focused Flutter runner remains without diagnostics, but the authoritative Flutter CI `app-workout` test shard passed. Hosted apply/deployment remains out of scope.
**Current blocker:** Independent review and owner merge approval; hosted apply/deployment remains out of scope
**Open review finding IDs:** None; independent review remains pending
**Next exact action:** Keep Draft PR #717 unmerged until independent review and explicit merge authorization; do not apply the migration or release.

## 1. Discovery

### User Outcome

Later Routine Create/Edit Exercise-card slices can consume a real durable Notes repository without introducing a mock UI or a second Exercise identity model.

### Success Criteria

- Owner-secured Routine and Exercise Note reads and protected mutations exist locally.
- Routine Notes use `(user_id, routine_id)` and Exercise Notes use `(user_id, exercise_ref)`.
- Canonical catalog `ex_*` and Custom UUID `ExerciseRef` values round-trip unchanged.
- Quota, body validation, revision conflicts, transfer atomicity and durable mutation replay are enforced by the database contract.
- Slice remains isolated from UI, Set prescription, Rest Timer and hosted deployment.

### Scope

Domain model, repository contract/adapter, database migration with protected RPCs and mutation receipts, focused SQL and Dart tests, and this task handoff.

### Non-Goals

Notes rows, type sheet, swipe actions, Routine Create/Edit controller integration, WorkoutSession/history snapshots, post integration, migration apply, production grants, merge and release.

## 2. Codebase Exploration

### Verified Evidence

- `apps/shared/lib/src/workout/exercise_ref.dart` defines catalog IDs as `ex_*` and Custom Exercise IDs as canonical lowercase UUIDs.
- `supabase/migrations/20261010061809_create_user_workout_routine_composition.sql` establishes `user_workout_routines(id, user_id)` as a unique owner-matched key and validates Custom Exercise ownership/status in the existing RPC path.
- `supabase/migrations/20260929181247_create_user_workout_exercises.sql` defines Custom Exercise ownership and `active`/`archived` lifecycle.
- Existing Workout RPCs revoke broad client writes, use owner checks, fixed `search_path` and schema-qualified references.
- Existing Dart composition repositories map PostgREST failures into sanitized domain failure categories and never retry a mutation implicitly.
- Current GitHub/Linear reconciliation: `main` and `origin/main` were `9c782688...`; TNYX-81 is `Backlog`, blocked by TNYX-78 and TNYX-80; no dedicated Routine Notes implementation issue was found; #532 is closed and #589 remains Duplicate Routine planning.

## 3. Clarification

### Decisions Required or Made

| Decision | Status | Rationale | Owner |
|---|---|---|---|
| Routine Note ownership | Approved | Stable Routine identity | Product owner |
| Exercise Note ownership | Approved | Canonical `ExerciseRef`, not Routine entry identity | Product owner |
| Active scope quota | Approved | Five Notes per Routine or Exercise scope | Product owner |
| Body normalization | Approved | Trimmed, nonblank, maximum 500 characters | Product owner |
| Mutation receipts | Approved | Historical idempotency requires durable receipt rows | Product owner |
| Hosted deployment | Out of scope | Local migration and tests only | Product owner |

## 4. Architecture Design

### Chosen Approach

Use one `public.user_workout_routine_notes` table plus a private mutation-receipt table. Owner-scoped reads use RLS. All writes use narrow `SECURITY DEFINER` RPCs with trusted `auth.uid()`, fixed `search_path`, owner validation, deterministic scope locks, quota checks, revision checks and receipt replay.

### Ownership and Data Flow

```text
Future Note UI -> Workout controller -> RoutineNotesRepository
  -> SupabaseRoutineNotesRepository -> owner-scoped SELECT / protected RPC
  -> user_workout_routine_notes + private mutation receipts
```

### Alternative Rejected

Do not store Notes in Routine composition JSON, `RoutineExerciseEntry`, Tio-owned catalog definitions, or client-only state. Do not grant direct client table writes.

### Failure and Accessibility States

Slice 1 exposes sanitized outcomes for unauthorized, forbidden, invalid request, quota, revision conflict, mutation conflict, not-found, malformed data and unknown/unavailable outcomes. UI accessibility is deferred to the later approved UI slices.

## 5. Implementation Plan

- [x] Add shared `RoutineNote` identity/scope/body contract.
- [x] Add `RoutineNotesRepository` contract and Supabase adapter.
- [x] Add local migration for Notes, receipts, RLS, grants, indexes and protected RPCs.
- [x] Add SQL security, quota, concurrency and replay tests; wire the matrix and race harness into `.github/workflows/supabase-db-ci.yml`.
- [x] Add focused Dart model/adapter tests.
- [x] Complete CI execution of the SQL matrix/race harness and Flutter `app-workout` test shard; persistent local apply remains intentionally out of scope.
- [x] Keep migration unapplied and leave UI untouched.

## 6. Quality Review

### Validation Run

```text
Passed: changed Workout-test Dart format/analyze, `dart analyze` in
`apps/shared`, `git diff --check`, and shell syntax validation for
`supabase/tests/database/tnyx_81_routine_notes_concurrency.sh`.

Passed with bounded scope: the Notes migration and
`supabase/tests/database/tnyx_81_routine_notes_persistence.test.sql` were
replayed together inside one outer transaction against the running local
Supabase Postgres, and the transaction was rolled back. The SQL matrix passed;
this did not alter the local schema and is not a full reset/replay proof.

The local focused Flutter test produced no diagnostics during the bounded
runner window and was controlled-aborted; the authoritative GitHub Actions
`Test Flutter (app-workout)` shard passed in run `40877774631`. The exact
CI-only two-session race harness was not run locally because persistent Notes
migration apply/reset is prohibited for this slice. Supabase Database CI run
`40877774527` passed the complete migration replay, the Routine Notes SQL
matrix, the two-session quota/transfer race, and the database-lint guard.
Independent review remains pending.
```

### Acceptance Evidence (substantive scope)

| Criterion | Changed behavior / file | Test or manual evidence + actual result | Observed SHA / environment | Remaining risk |
|---|---|---|---|---|
| Durable owner-scoped Notes | `supabase/migrations/20261029120000_create_user_workout_routine_notes.sql` | SQL test authored; execution unavailable | Branch working tree | Hosted schema not changed |
| Canonical ExerciseRef round-trip | `apps/shared/lib/src/workout/routine_note.dart` | `apps/shared` analyze passed; targeted test not run | Local Windows checkout | Catalog availability is app-owned |
| Protected mutation behavior | Notes RPCs + Workout adapter | `apps/features/workout` analyze passed; targeted test not run | Local Windows checkout | Hosted grants not activated |
| SQL matrix and fixture correctness | `supabase/tests/database/tnyx_81_routine_notes_persistence.test.sql` | Transaction-scoped migration plus matrix replay passed and rolled back; quota, unique mutation IDs and transfer-source fixtures corrected | Local Supabase Postgres, disposable transaction | CI execution still required |
| Real concurrency coverage | `supabase/tests/database/tnyx_81_routine_notes_concurrency.sh`, `.github/workflows/supabase-db-ci.yml` | `bash -n` passed; CI run `40877774527` passed the exact two-session quota/transfer race after full migration replay | GitHub Actions disposable Postgres | Independent review remains pending |
| Wrong-owner read rejection | `apps/features/workout/test/data/supabase_routine_notes_repository_test.dart` | Fixture changes `user_id` to a different owner; Dart format/analyze passed and Flutter `app-workout` test shard passed in run `40877774631` | GitHub Actions Flutter CI | Local focused runner had no diagnostics |

### Review Provenance

**Review source / link:** chat-provided Slice 1 review-fix handoff, GitHub #716/#717, Linear `TNYX-81`, and repository source inspection
**Reviewer / relation to implementer:** Self-review pending independent review
**Diff or commit SHA actually reviewed:** `435f74f9`
**Review result and finding IDs/dispositions:** `PR717-FLUTTER-FIX`, `PR717-SQL-CI` and `PR717-CONCURRENCY` are resolved in source and CI. Run `40877774527` confirmed full migration replay, the Notes SQL matrix, the two-session quota/transfer race and the database-lint guard. Run `40877774631` confirmed the Flutter `app-workout` test shard. Independent review remains pending.
**Independent review?** No (self-review)
**Limitations and unmet required gates:** The local focused Flutter test produced no diagnostics before controlled abort; CI coverage passed. The exact CI-only concurrency harness was not run locally because persistent Notes migration apply/reset is prohibited for this slice. Local Supabase CLI `2.121.0` differs from CI's pinned `2.116.0`; no version change was made. Hosted schema apply/deployment, independent review and merge authorization remain pending. Dedicated Linear issue creation was not requested and no child issue was created.

### Review Findings and Resolution

| Finding ID | Status | Evidence | Remaining gate |
|---|---|---|---|
| `PR717-FLUTTER-FIX` | Resolved | Wrong-owner fixture now mutates `user_id` to `_other`; changed test formats/analyzes cleanly and the CI `app-workout` shard passed | Independent review |
| `PR717-SQL-CI` | Resolved | `.github/workflows/supabase-db-ci.yml` runs the Notes matrix with `ON_ERROR_STOP=1`; run `40877774527` passed it after full migration replay | Independent review |
| `PR717-SQL-FIXTURES` | Resolved | Local transaction-scoped matrix passed after quota count, mutation-id uniqueness and transfer-source corrections | CI confirmation |
| `PR717-CONCURRENCY` | Resolved | First CI run exposed a harness-only positional-argument bug; corrected run `40877774527` passed both two-session race assertions | Independent review |

## Exit Criteria

Slice 1 may be handed off as a Draft PR after source and CI validation, the migration remains unapplied, UI files remain unchanged, and the final report lists exact files, commands, results and remaining hosted/review gates. Merge/release remains blocked pending independent review and explicit owner authorization.
