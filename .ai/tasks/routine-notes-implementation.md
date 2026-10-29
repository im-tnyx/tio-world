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
**Repository state last verified:** 2026-10-29; `main` clean before branch creation
**Branch:** `tnyx/routine-notes-persistence`
**HEAD SHA:** `9c782688acd13efd189b7827c139dea3aca1a5d6` at branch creation
**Observed working-tree state:** Clean before implementation
**Observed uncommitted/dirty files:** None before implementation
**PR / tracker:** Linear `TNYX-81` parent; no dedicated Notes issue created
**Current implementation state:** Domain, migration/RPC, repository adapter and focused tests added locally; hosted migration unapplied
**Relevant execution surface:** `apps/shared`, `apps/features/workout`, `supabase/migrations`, `supabase/tests/database`
**Validation completed at SHA:** Dart format, package analyze and `git diff --check` completed on the working tree; exact Supabase CLI binary was verified, but its local database harness cannot start without Docker
**Validation remaining:** SQL replay/security tests and targeted Flutter tests; `supabase db start` could not produce a usable local harness because the Docker daemon endpoint is unavailable, and the targeted Dart test invocation produced no diagnostics before controlled abort
**Current blocker:** Local SQL/test execution is tool-limited by the unavailable Docker daemon; hosted apply/deployment remains out of scope
**Open review finding IDs:** None
**Next exact action:** Commit only the approved Slice 1 files, push `tnyx/routine-notes-persistence`, open a Draft PR linked to GitHub #716 / Linear `TNYX-81`, and keep it unmerged pending SQL/Flutter execution and independent review.

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

Notes rows, type sheet, swipe actions, Routine Create/Edit controller integration, WorkoutSession/history snapshots, post integration, migration apply, production grants, commit, merge and release.

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
- [x] Add SQL security, quota, concurrency and replay tests.
- [x] Add focused Dart model/adapter tests.
- [ ] Run SQL replay/security tests and targeted Flutter tests; current Docker/test-runner limitations are recorded.
- [x] Keep migration unapplied and leave UI untouched.

## 6. Quality Review

### Validation Run

```text
Passed: Dart format (changed Dart files), `dart analyze` in `apps/shared`,
`dart analyze` in `apps/features/workout`, and `git diff --check`.
Not completed: SQL replay/security test. The exact local Supabase CLI
`G:\dev\supabase-cli\v2.121.0\supabase.exe` is present, but the Docker daemon
endpoint `npipe:////./pipe/dockerDesktopLinuxEngine` is unavailable. The
targeted Dart test invocation also produced no diagnostics and was controlled
aborted; it is not reported as passed.
```

### Acceptance Evidence (substantive scope)

| Criterion | Changed behavior / file | Test or manual evidence + actual result | Observed SHA / environment | Remaining risk |
|---|---|---|---|---|
| Durable owner-scoped Notes | `supabase/migrations/20261029120000_create_user_workout_routine_notes.sql` | SQL test authored; execution unavailable | Branch working tree | Hosted schema not changed |
| Canonical ExerciseRef round-trip | `apps/shared/lib/src/workout/routine_note.dart` | `apps/shared` analyze passed; targeted test not run | Local Windows checkout | Catalog availability is app-owned |
| Protected mutation behavior | Notes RPCs + Workout adapter | `apps/features/workout` analyze passed; targeted test not run | Local Windows checkout | Hosted grants not activated |

### Review Provenance

**Review source / link:** chat-provided approved implementation handoff, GitHub #716, Linear `TNYX-81`, and repository source inspection
**Reviewer / relation to implementer:** Self-review pending independent review
**Diff or commit SHA actually reviewed:** Working-tree source review only; commit SHA will be recorded after the authorized commit
**Review result and finding IDs/dispositions:** Not reviewed
**Independent review?** No (self-review)
**Limitations and unmet required gates:** Local Docker daemon is unavailable, so the SQL harness could not start; `psql` was not available on PATH. The targeted Dart test invocation produced no diagnostics before controlled abort. Local Supabase CLI `2.121.0` differs from CI's pinned `2.116.0`; no version change was made. Hosted schema validation and deployment are not part of this slice. Dedicated Linear issue creation was rejected by the connector risk policy and was not retried.

## Exit Criteria

Slice 1 may be handed off as a Draft PR after local source/tests are validated as far as available tooling permits, the migration remains unapplied, UI files remain unchanged, and the final report lists exact files, commands, results and remaining hosted/CI/review gates. Merge/release remains blocked pending SQL/Flutter execution and independent review.
