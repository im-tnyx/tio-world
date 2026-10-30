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
**Repository state last verified:** 2026-10-30; Option A snapshot remediation and regression tests are validated in the approved commit/push checkpoint
**Branch:** `tnyx/routine-notes-persistence`
**Starting branch HEAD SHA:** `eab80a5c241f96ef650f517036d8e24f36567b53` (pre-commit checkpoint)
**Validated pre-commit base SHA:** `eab80a5c241f96ef650f517036d8e24f36567b53` (the approved four-file checkpoint was validated before commit/push)
**Slice 1 commit:** `ec8a314e` (`feat(database): add routine notes persistence foundation`)
**Observed pre-commit working-tree state:** The approved four-file checkpoint was present; no unrelated files observed
**Observed pre-commit files:** `.ai/tasks/routine-notes-implementation.md`, `supabase/tests/database/tnyx_81_routine_notes_concurrency.sh`, `supabase/tests/database/tnyx_81_routine_notes_persistence.test.sql`, `supabase/migrations/20261030065649_routine_note_mutation_result_snapshot.sql`
**PR / tracker:** Linear `TNYX-81` parent; no dedicated Notes issue created
**Current implementation state:** Domain, migration/RPC, repository adapter and Slice 1 review fixes are committed and pushed in PR #717; Option A immutable result snapshots plus the four focused regression tests are included in the approved four-file commit/push checkpoint; hosted migration unapplied
**Relevant execution surface:** `apps/shared`, `apps/features/workout`, `supabase/migrations`, `supabase/tests/database`
**Validation completed at working tree:** 74-migration replay, transaction-scoped Routine Notes SQL matrix with all four immutable-snapshot regressions, `supabase db lint`, `supabase db advisors`, prior Flutter/Dart checks, and `git diff --check` on the disposable validation setup.
**Validation remaining:** Independent review and owner merge approval. The local focused Flutter runner remains without diagnostics, but the authoritative Flutter CI `app-workout` test shard passed. Hosted apply/deployment remains out of scope.
**Current blocker:** Body normalization approval remains separate; independent review and owner merge approval remain pending; hosted apply/deployment remains out of scope
**Review status:** Local Option A findings are addressed in the approved four-file checkpoint. Hosted PR #717 still has 8 unresolved, non-outdated review threads at the last verified hosted PR head `eab80a5c241f96ef650f517036d8e24f36567b53`, with hosted review decision `CHANGES_REQUESTED`. The new checkpoint must be independently reviewed after its head is pushed; hosted threads must be refreshed against that new head. Body normalization remains a separate pending Owner Approval and is not considered addressed.
**Next exact action:** Keep PR #717 unmerged until new-head CI, independent review and explicit merge authorization; do not apply the migration or release.

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
| Body normalization | Separate approval pending | Exact whitespace and Unicode character-count policy remains on HOLD; this slice does not change it | Product owner |
| Mutation receipts | Option A approved | Successful mutation responses are stored as private immutable JSONB snapshots and replayed exactly | Product owner |
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
- [x] Add the additive immutable result-snapshot migration and replay/reconciliation regression coverage.

## 6. Quality Review

### Validation Run

```text
Option A and the four regression-test additions passed locally on 2026-10-30
using Supabase CLI 2.116.0 and a disposable Docker Postgres project on port
55422. All 74 repository migrations replayed in single transactions. The
updated Routine Notes SQL matrix passed with rollback, including direct
mutation replay after Routine cascade deletion, complete JSONB payload
equality, legacy-null snapshot fail-closed behavior, snapshot-trigger failure
rollback, and a normal mutation after failure injection removal. The existing
two-session race harness was not changed by this test-only slice. `supabase db lint --local --schema public,private
--level error --fail-on none` and `supabase db advisors --local --type all
--level error --fail-on none` both passed. Function grants were separately
verified: the public wrapper is authenticated-only; the legacy function and
private trigger are not executable by client roles.

`flutter test test/data/supabase_routine_notes_repository_test.dart` passed
with 6 tests, `flutter test test/workout/routine_note_test.dart` passed with
4 tests, Workout `flutter analyze` passed, and Dart format check passed with
0 changed files. `git diff --check` passed. Native `bash -n` was unavailable
on Windows (`Bash/E_ACCESSDENIED`), but the script executed successfully in
the disposable Linux validation container.

Body normalization remains unchanged and separately unapproved. Hosted
Supabase was not changed. Independent review and merge authorization remain
pending.
```

### Acceptance Evidence (substantive scope)

| Criterion | Changed behavior / file | Test or manual evidence + actual result | Observed SHA / environment | Remaining risk |
|---|---|---|---|---|
| Immutable mutation replay | `supabase/migrations/20261030065649_routine_note_mutation_result_snapshot.sql` | Additive snapshot column, private trigger, public wrapper and reconciliation passed in the SQL matrix after delete/update/transfer/cascade | Disposable Supabase Postgres, CLI 2.116.0 | Hosted schema not changed |
| Canonical ExerciseRef and adapter compatibility | Existing shared model/repository files | Shared RoutineNote test passed with 4 tests; Workout repository test passed with 6 tests; Workout analyze passed | Local Flutter 3.44.6 / Dart 3.12.2 | No Dart source change in this slice |
| SQL security and grants | Snapshot migration plus existing Notes RPCs | SQL matrix, db lint, db advisors and explicit client-grant query passed | Disposable Supabase Postgres | Independent review remains pending |
| Replay/concurrency regression coverage | `supabase/tests/database/tnyx_81_routine_notes_persistence.test.sql` | Full migration replay and all four immutable-snapshot regression assertions passed; concurrency harness was unchanged and not rerun for this test-only slice | Disposable Docker Postgres | Hosted PR head still does not contain the local test diff |

### Review Provenance

**Review source / link:** chat-provided Slice 1 review-fix handoff, GitHub #716/#717, Linear `TNYX-81`, and repository source inspection
**Reviewer / relation to implementer:** Self-review pending independent review
**Diff or commit SHA actually reviewed:** base `eab80a5c241f96ef650f517036d8e24f36567b53` plus uncommitted Option A working-tree changes
**Review result and finding IDs/dispositions:** Option A P2 replay findings are addressed locally by immutable snapshots and regression coverage. Body normalization and unrelated P2/P3 findings remain out of scope. Independent review remains pending.
**Independent review?** No (self-review)
**Limitations and unmet required gates:** Hosted schema apply/deployment, independent review and merge authorization remain pending. Body normalization approval remains separate. Dedicated Linear issue creation was not requested and no child issue was created.

### Review Findings and Resolution

| Finding ID | Status | Evidence | Remaining gate |
|---|---|---|---|
| `PR717-FLUTTER-FIX` | Resolved | Wrong-owner fixture now mutates `user_id` to `_other`; changed test formats/analyzes cleanly and the CI `app-workout` shard passed | Independent review |
| `PR717-SQL-CI` | Resolved | `.github/workflows/supabase-db-ci.yml` runs the Notes matrix with `ON_ERROR_STOP=1`; run `40877774527` passed it after full migration replay | Independent review |
| `PR717-SQL-FIXTURES` | Resolved | Local transaction-scoped matrix passed after quota count, mutation-id uniqueness and transfer-source corrections | CI confirmation |
| `PR717-CONCURRENCY` | Resolved | First CI run exposed a harness-only positional-argument bug; corrected run `40877774527` passed both two-session race assertions | Independent review |
| `PR717-SNAPSHOT-TESTS` | Resolved locally | Four regression tests now cover cascade direct replay, complete JSONB equality, legacy-null fail-closed replay/reconciliation and trigger-failure rollback; disposable 74-migration replay and SQL matrix passed | Owner inspection and independent review |

## Exit Criteria

PR #717 remains Ready for Review, not Draft. The approved four-file checkpoint is validated for commit/push; the migration remains unapplied, UI files remain unchanged, and merge/release remain blocked pending new-head CI, independent review and explicit authorization.
