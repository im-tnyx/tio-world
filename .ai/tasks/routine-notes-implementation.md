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
**Repository state last verified:** 2026-10-30; this authorized four-file checkpoint starts from hosted PR #717 head `eea5338a0b19ae17848f5057f18128096d97db7e` and contains the P1 migration-order fix plus its focused validation changes; after push, GitHub PR history and exact-head CI are authoritative
**Branch:** `tnyx/routine-notes-persistence`
**Starting branch HEAD SHA:** `eea5338a0b19ae17848f5057f18128096d97db7e` (current task preflight)
**Validated pre-commit base SHA:** `eea5338a0b19ae17848f5057f18128096d97db7e` (P1 migration-order validation ran against this base plus the uncommitted four-file change set)
**Slice 1 commit:** `ec8a314e` (`feat(database): add routine notes persistence foundation`)
**Observed pre-commit working-tree state:** The approved four-file checkpoint was present; no unrelated files observed
**Current commit scope:** `.ai/tasks/routine-notes-implementation.md`, `supabase/migrations/20261030081321_routine_note_legacy_receipt_gate.sql`, `supabase/tests/database/tnyx_81_routine_notes_legacy_receipt_gate.sh`, `supabase/tests/database/tnyx_81_routine_notes_persistence.test.sql`; the existing Option A implementation and unrelated repository state are preserved
**PR / tracker:** Linear `TNYX-81` parent; no dedicated Notes issue created
**Current implementation state:** Domain, migration/RPC, repository adapter, Option A snapshot replay, body normalization and 50-total-quota remediation are hosted at PR #717 head `eea5338a`; this four-file checkpoint adds the P1 fail-closed legacy-receipt guard inside the snapshot migration transaction before trigger/RPC replacement, while the separate `20261030081321` gate remains defense-in-depth; hosted Notes migration is unapplied
**Relevant execution surface:** `apps/shared`, `apps/features/workout`, `supabase/migrations`, `supabase/tests/database`
**Validation completed at working tree:** The hardened harness replayed 76 migration files on a disposable Docker database using the pre-Notes baseline and the exact migration boundary. Two legacy `NULL`-snapshot receipts failed atomically with SQLSTATE `P0001`; receipt rows, original mutation/reconciliation function definitions, the added column and migration ledger entries remained unchanged. The two-session test confirmed the `ACCESS EXCLUSIVE` lock blocks a concurrent legacy receipt write until the migration precondition is evaluated. The clean full sequence passed with non-NULL snapshots and the existing Routine Notes persistence/replay matrix. Pinned Supabase CLI `2.116.0` `db lint` exited `0`; local `db advisors` exited `0` with existing project-wide INFO/WARN findings, including the expected private receipt-table no-policy advisory. Effective Routine Note RPC grants, `SECURITY DEFINER` and empty `search_path` were verified. No Dart files changed.
**Hosted evidence:** Exact project ref `oykupyiitspujzpwwvuj` was verified as the linked healthy Tio-world project. Hosted migration history ends at `20261028110000`; the Notes tables, mutation RPC and reconciliation RPC are absent on the hosted project, so the Notes migration remains unapplied and hosted Notes security is not verified. Current PR #717 head is `eea5338a0b19ae17848f5057f18128096d97db7e`; current checks were successful, but hosted review remains `CHANGES_REQUESTED`.
**Validation remaining:** After this checkpoint is pushed, refresh PR #717 at the exact new head and recheck reviews, threads and CI. S1/S2 architecture and the P3 recommendations remain separate owner decisions; hosted apply/deployment and merge remain out of scope.
**Current blocker:** No local P1 validation failure remains. Hosted Notes security and migration application remain intentionally unverified/unapplied; the latest hosted review decision must be re-evaluated at the pushed head.
**Review status:** Review `5712332272` on hosted PR #717 at pre-checkpoint head `eea5338a0b19ae17848f5057f18128096d97db7e` remains `CHANGES_REQUESTED` for the late legacy-receipt gate and separate hosted security evidence concerns. This checkpoint addresses the P1 gate locally under the approved no-backfill contract; post-push GitHub review state is authoritative. No hosted migration or Linear mutation was performed.
**Next exact action:** Refresh PR #717, reviews, unresolved threads and CI at the pushed exact head. Keep PR #717 unmerged and do not apply the migration or release.

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
| Legacy NULL-snapshot receipts | Approved | If any existing receipt has `result_snapshot IS NULL`, the new migration aborts with `routine_note_legacy_receipt_snapshot_required`; no synthetic backfill, delete or rewrite is permitted | Product owner, 2026-10-30 |
| Hosted deployment | Out of scope | Local migration and tests only | Product owner |
| S1/S2 RPC security architecture | Pending separate approval | S1 current public authenticated-only `SECURITY DEFINER` wrappers with documented rationale versus S2 private implementation plus minimal public `SECURITY INVOKER` wrappers | Product owner |
| Receipt retention | Proposed, pending separate approval | Keep immutable receipts for at least 30 days or the supported retry/reconciliation horizon; consider permanent minimal tombstones after snapshot expiry; expired IDs must not silently execute again | Product owner |
| Cross-user Note UUID conflict | Proposed, pending separate approval | Keep a generic non-disclosing invalid/unavailable outcome for occupied foreign IDs and missing IDs; update Dart mapping only in a separately approved contract change | Product owner |
| Custom Exercise lifecycle | Proposed, pending separate approval | Keep archive-only authenticated behavior; preserve `ON DELETE NO ACTION`; evaluate service-role deletion and define archived-Note policy before any hard-delete path | Product owner |

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
- [x] Add the additive fail-closed legacy-receipt migration gate and migration-boundary regression harness; commit/push is authorized only within the current four-file task scope.

## 6. Quality Review

### Validation Run

```text
The legacy-receipt gate was validated on 2026-10-30 with Supabase CLI 2.116.0
and a disposable Docker Postgres project on port 55452. The repository has 76
migrations after this additive migration. The 75-migration baseline replay was
followed by two synthetic legacy receipts with `result_snapshot IS NULL`.
Running the new migration with `psql --single-transaction` failed with exit 3
and the deterministic error
`routine_note_legacy_receipt_snapshot_required`; both receipts remained byte-
for-byte unchanged and the gate version was absent from the migration ledger.

A clean baseline with an existing valid snapshot applied the gate successfully;
the snapshot JSONB remained exactly unchanged and the gate ledger entry was
recorded once. The gate harness and full Routine Notes SQL matrix passed,
including replay/reconciliation, and the existing two-session quota/transfer/
duplicate harness passed in an isolated Linux Docker container. `supabase db
lint` exited 0 with warnings, while local `supabase db advisors` exited 0 with
INFO/WARN findings including the private receipt-table no-policy advisory.
Effective local RPC grants plus `SECURITY DEFINER`/empty `search_path`
properties were verified: both Notes RPCs are executable by `authenticated`,
not by `anon` or `service_role`, and direct mutation-table privileges are not
granted to those roles. Hosted Supabase was not changed.

The exact linked hosted project `oykupyiitspujzpwwvuj` was verified read-only.
Hosted Advisor returned 47 project-wide WARN/INFO findings and no Routine Notes
finding, but the hosted migration history ends before the Notes migrations and
the Notes table/RPC objects are absent there. This is hosted project evidence,
not a hosted Notes security pass.
```

### Acceptance Evidence (substantive scope)

| Criterion | Changed behavior / file | Test or manual evidence + actual result | Observed SHA / environment | Remaining risk |
|---|---|---|---|---|
| Immutable mutation replay | `supabase/migrations/20261030065649_routine_note_mutation_result_snapshot.sql` | Additive snapshot column, private trigger, public wrapper and reconciliation passed in the SQL matrix after delete/update/transfer/cascade | Disposable Supabase Postgres, CLI 2.116.0 | Hosted schema not changed |
| Canonical ExerciseRef and adapter compatibility | `apps/shared/lib/src/workout/routine_note.dart` and focused test | Dart normalization source and test were formatted; focused Dart test/analyze could not complete because the local runner hung without diagnostics | Local direct Dart 3.12.2 | No hosted/client parity claim until focused Dart validation |
| SQL security and grants | Snapshot migration plus existing Notes RPCs | SQL matrix, db lint exit 0, local Advisor exit 0 with reported INFO/WARN findings, and explicit local client-grant/RPC query passed | Disposable Supabase Postgres | Hosted Notes objects are unapplied; hosted security review remains pending |
| Review-contract regression coverage | `supabase/tests/database/tnyx_81_routine_notes_persistence.test.sql`, `apps/shared/test/workout/routine_note_test.dart` | 75-migration replay, Unicode body parity, 500/501 scalar boundaries, 50-user quota and existing two-session harness passed; focused Dart test remains blocked by local runner hang | Disposable Docker Postgres / local Dart SDK | Hosted PR head does not yet contain this remediation |
| Legacy receipt migration boundary | `supabase/migrations/20261030081321_routine_note_legacy_receipt_gate.sql`, `supabase/tests/database/tnyx_81_routine_notes_legacy_receipt_gate.sh` | Two legacy NULL receipts fail closed without mutation or ledger success; clean valid snapshot is preserved; clean gate, normal SQL matrix and hardened cleanup harness pass | Disposable Docker Postgres, CLI 2.116.0 | Hosted migration not applied; commit/push is authorized by the current task but independent review remains required |

### Review Provenance

**Review source / link:** chat-provided Slice 1 review-fix handoff, GitHub #716/#717, Linear `TNYX-81`, and repository source inspection
**Reviewer / relation to implementer:** Self-review pending independent review
**Diff or commit SHA actually reviewed:** hosted review #5709617294 reviewed head `a6034ccf15724d6827aa4f0a84321d5f48412c83`; the legacy-receipt gate is the post-review local remediation checkpoint
**Review result and finding IDs/dispositions:** Option A replay, body-normalization and total-quota findings are addressed by the pushed/local validated changes. Review #5709617294's legacy-receipt finding is implemented locally under the owner-approved no-backfill contract. Security architecture and P3 policy findings remain decision-ready only. Independent review remains pending.
**Independent review?** No (self-review)
**Limitations and unmet required gates:** Hosted schema apply/deployment, hosted Notes Security Advisor evidence, S1/S2 owner decision, P3 dispositions, independent review, post-push CI/review refresh and merge authorization remain pending. Dedicated Linear issue creation was not requested and no child issue was created.

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
| `PR717-LEGACY-RECEIPT-GATE` | Implemented locally | Locked receipt table, deterministic `routine_note_legacy_receipt_snapshot_required` failure, unchanged legacy rows, no false ledger entry, clean-state snapshot preservation and hardened cleanup pass | Post-push independent review |
| `PR717-SECURITY-DEFINER` | Open — decision-ready | Local grants, owner checks, `SECURITY DEFINER` and empty `search_path` verified; hosted Advisor returned project-wide findings but hosted Notes objects are absent; S1/S2 architecture choice not approved | Owner S1/S2 decision and post-apply hosted evidence |
| `PR717-P3-DISPOSITIONS` | Open — decision-ready | Receipt retention, cross-user Note ID signalling and Custom Exercise archive/hard-delete lifecycle recommendations are documented; no policy implementation changed | Explicit owner dispositions |

### Decision-ready follow-ups from review #5709617294

**Security boundary recommendation:** Retain the current public authenticated-only
`SECURITY DEFINER` wrappers as S1 for this compatibility-sensitive Notes slice
only if the owner accepts the documented rationale and exact hosted Security
Advisor evidence is obtained for the intended project. Local evidence confirms
`search_path = ''`, `postgres` ownership, `auth.uid()` checks and authenticated-
only `EXECUTE`; local advisors are not hosted evidence. S2 (private implementation
functions with a minimal public authenticated wrapper) is the safer future
boundary but requires a separate owner-approved migration, grant, PostgREST and
client-compatibility review. Neither option is implemented here.

**P3 recommendation — receipt retention:** retain immutable receipts for 30 days
after `created_at`, or longer if the supported offline retry/reconciliation
horizon is formally longer. Pruning before that horizon can turn a delayed retry
into a new mutation; pruning after it reduces private payload retention and
storage growth. A private scheduled cleanup must be separately approved and
must not be client-callable.

**P3 recommendation — cross-user Note ID conflicts:** return the same generic
invalid/unavailable mutation outcome for a foreign UUID and a non-existent UUID;
do not reveal whether another user's Note ID exists. Preserve current owner
checks and avoid changing the public contract in this slice.

**P3 recommendation — Custom Exercise lifecycle:** keep owner Custom Exercises
archive-only for now. Authenticated hard-delete is denied, the composition FK is
`ON DELETE NO ACTION`, and existing Notes use the canonical Exercise UUID text
without a cleanup FK. Any future hard-delete would require an explicit
composition/Note preservation or deletion policy and a separate protected
lifecycle slice; no orphan cleanup is implemented here.

### Migration lock operational note

`20261030081321_routine_note_legacy_receipt_gate.sql` takes an
`ACCESS EXCLUSIVE` lock on `private.user_workout_routine_note_mutations` before
checking for legacy `NULL` snapshots. This serializes the precondition against
receipt writes and reconciliation reads/operations, and also conflicts with
other table-level access such as concurrent DDL. The lock, precondition and
failure are inside one migration transaction: a failed check raises
`routine_note_legacy_receipt_snapshot_required`, rolls back the migration and
does not record the gate in `supabase_migrations.schema_migrations`.

Run this migration in a controlled release window after checking active
receipt-operation sessions and blockers. If it fails, preserve the evidence,
confirm the migration ledger has no successful gate entry, resolve the legacy
receipt condition under the approved no-backfill procedure, confirm no blocked
receipt operation remains, and retry only after the release owner approves the
window. Do not apply it to hosted Supabase from this task.

## Exit Criteria

PR #717 remains Ready for Review, not Draft. This four-file checkpoint contains the locally validated P1 migration-order correction; after push, GitHub PR history and exact-head CI become the authoritative synchronization evidence. Hosted migration remains unapplied, UI files remain unchanged, and merge/release remain blocked pending post-push review/CI, S1/S2 security decision, P3 dispositions and merge authorization.
