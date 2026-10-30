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
**Repository state last verified:** 2026-10-30; Option A is pushed, and the approved body/quota review remediation is the owner-authorized commit/push checkpoint; hosted review refresh remains required
**Branch:** `tnyx/routine-notes-persistence`
**Starting branch HEAD SHA:** `eab80a5c241f96ef650f517036d8e24f36567b53` (pre-commit checkpoint)
**Validated pre-commit base SHA:** `eab80a5c241f96ef650f517036d8e24f36567b53` (the approved four-file checkpoint was validated before commit/push)
**Slice 1 commit:** `ec8a314e` (`feat(database): add routine notes persistence foundation`)
**Observed pre-commit working-tree state:** The approved four-file checkpoint was present; no unrelated files observed
**Observed pre-commit files:** `.ai/tasks/routine-notes-implementation.md`, `supabase/tests/database/tnyx_81_routine_notes_concurrency.sh`, `supabase/tests/database/tnyx_81_routine_notes_persistence.test.sql`, `supabase/migrations/20261030065649_routine_note_mutation_result_snapshot.sql`
**PR / tracker:** Linear `TNYX-81` parent; no dedicated Notes issue created
**Current implementation state:** Domain, migration/RPC, repository adapter and Slice 1 review fixes are committed and pushed in PR #717; Option A is included at hosted head `0d0855860535eefa88908740e0f30b4281e04b1a`; the approved body-normalization and 50-total-quota remediation is the owner-authorized synchronization checkpoint; hosted migration unapplied
**Relevant execution surface:** `apps/shared`, `apps/features/workout`, `supabase/migrations`, `supabase/tests/database`
**Validation completed at working tree:** 75-migration replay, updated transaction-scoped Routine Notes SQL matrix with Unicode normalization, 500-scalar boundary and 50-user quota assertions, existing two-session quota/transfer/duplicate harness, `supabase db lint`, `supabase db advisors` and SQL `git diff --check` on a disposable Docker setup. Direct Dart formatting ran with the pinned SDK; focused Dart test execution remains unavailable because the local runner hangs without diagnostics after bounded interruption.
**Validation remaining:** Focused Dart test/analyze, independent review and owner merge approval. Hosted apply/deployment remains out of scope.
**Current blocker:** Focused Dart validation and independent review remain pending after the approved body-normalization and total-quota remediation; hosted apply/deployment remains out of scope
**Review status:** Review #5709395135 on hosted PR #717 at head `0d0855860535eefa88908740e0f30b4281e04b1a` confirmed CI success but kept `CHANGES_REQUESTED` for body-normalization parity and unrestricted cross-scope totals. Owner approved the exact remediation contract on 2026-10-30 and explicitly authorized commit/push; after the new head is pushed, hosted review and checks must be refreshed. No inline comments were returned for that review.
**Next exact action:** Complete the authorized commit/push checkpoint, then refresh hosted review and checks on the new head; keep PR #717 unmerged and do not apply the migration or release.

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
| Body normalization | Approved | Trim Unicode White_Space at both edges, reject empty normalized bodies, persist the normalized value, and enforce 500 Unicode scalar values/code points consistently in SQL and Dart | Product owner, 2026-10-30 |
| Total active Notes quota | Approved | Keep five active Notes per canonical scope and add a 50 active-Notes-per-user cap across Routine and Exercise scopes; transfers must satisfy destination and user-wide capacity | Product owner, 2026-10-30 |
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
Review remediation was validated on 2026-10-30 with Supabase CLI 2.116.0 and
a disposable Docker Postgres project on port 55442. All 75 repository
migrations replayed in single transactions. The updated SQL matrix passed with
Unicode White_Space trimming, whitespace-only rejection, 500/501 Unicode
scalar boundaries, the 50-active-Notes-per-user cap across distinct scopes,
immutable snapshot regressions and rollback. The existing two-session quota,
transfer and duplicate-result harness passed. `supabase db lint --local
--schema public,private --level error --fail-on none` and `supabase db
advisors --local --type all --level error --fail-on none` both passed.

The Dart formatter was run with the direct Dart 3.12.2 executable. Focused
Dart test execution was attempted with bounded timeout but hung without
diagnostics; no Dart test pass is claimed. Hosted Supabase was not changed.
Independent review and merge authorization remain pending; owner commit/push
authorization is recorded for this remediation checkpoint.
```

### Acceptance Evidence (substantive scope)

| Criterion | Changed behavior / file | Test or manual evidence + actual result | Observed SHA / environment | Remaining risk |
|---|---|---|---|---|
| Immutable mutation replay | `supabase/migrations/20261030065649_routine_note_mutation_result_snapshot.sql` | Additive snapshot column, private trigger, public wrapper and reconciliation passed in the SQL matrix after delete/update/transfer/cascade | Disposable Supabase Postgres, CLI 2.116.0 | Hosted schema not changed |
| Canonical ExerciseRef and adapter compatibility | `apps/shared/lib/src/workout/routine_note.dart` and focused test | Dart normalization source and test were formatted; focused Dart test/analyze could not complete because the local runner hung without diagnostics | Local direct Dart 3.12.2 | No hosted/client parity claim until focused Dart validation |
| SQL security and grants | Snapshot migration plus existing Notes RPCs | SQL matrix, db lint, db advisors and explicit client-grant query passed | Disposable Supabase Postgres | Independent review remains pending |
| Review-contract regression coverage | `supabase/tests/database/tnyx_81_routine_notes_persistence.test.sql`, `apps/shared/test/workout/routine_note_test.dart` | 75-migration replay, Unicode body parity, 500/501 scalar boundaries, 50-user quota and existing two-session harness passed; focused Dart test remains blocked by local runner hang | Disposable Docker Postgres / local Dart SDK | Hosted PR head does not yet contain this remediation |

### Review Provenance

**Review source / link:** chat-provided Slice 1 review-fix handoff, GitHub #716/#717, Linear `TNYX-81`, and repository source inspection
**Reviewer / relation to implementer:** Self-review pending independent review
**Diff or commit SHA actually reviewed:** hosted review #5709395135 reviewed head `0d0855860535eefa88908740e0f30b4281e04b1a`; the approved remediation is the post-head synchronization checkpoint
**Review result and finding IDs/dispositions:** Option A P2 replay findings are addressed by the pushed immutable snapshots. Review #5709395135 body-normalization and total-quota findings are implemented locally under the owner-approved contract and validated on the database surface. Independent review remains pending.
**Independent review?** No (self-review)
**Limitations and unmet required gates:** Focused Dart test/analyze, hosted schema apply/deployment, independent review and merge authorization remain pending. Dedicated Linear issue creation was not requested and no child issue was created.

### Review Findings and Resolution

| Finding ID | Status | Evidence | Remaining gate |
|---|---|---|---|
| `PR717-FLUTTER-FIX` | Resolved | Wrong-owner fixture now mutates `user_id` to `_other`; changed test formats/analyzes cleanly and the CI `app-workout` shard passed | Independent review |
| `PR717-SQL-CI` | Resolved | `.github/workflows/supabase-db-ci.yml` runs the Notes matrix with `ON_ERROR_STOP=1`; run `40877774527` passed it after full migration replay | Independent review |
| `PR717-SQL-FIXTURES` | Resolved | Local transaction-scoped matrix passed after quota count, mutation-id uniqueness and transfer-source corrections | CI confirmation |
| `PR717-CONCURRENCY` | Resolved | First CI run exposed a harness-only positional-argument bug; corrected run `40877774527` passed both two-session race assertions | Independent review |
| `PR717-SNAPSHOT-TESTS` | Resolved locally | Four regression tests now cover cascade direct replay, complete JSONB equality, legacy-null fail-closed replay/reconciliation and trigger-failure rollback; disposable 75-migration replay and SQL matrix passed | Owner inspection and independent review |
| `PR717-BODY-NORMALIZATION` | Implemented locally | SQL and Dart now trim the approved Unicode White_Space set, reject empty normalized bodies and count Unicode scalar values; focused SQL parity cases passed | Focused Dart test and independent review |
| `PR717-TOTAL-QUOTA` | Implemented locally | Five-per-scope quota remains and a serialized 50-active-Notes-per-user trigger rejects the 51st Note across distinct scopes; SQL quota matrix passed | Independent review |

## Exit Criteria

PR #717 remains Ready for Review, not Draft. The approved remediation is validated on the disposable database surface and is authorized for synchronization; the migration remains unapplied, UI files remain unchanged, and merge/release remain blocked pending focused Dart validation, new-head CI, independent review and explicit authorization.
