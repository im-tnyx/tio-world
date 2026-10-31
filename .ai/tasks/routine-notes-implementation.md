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
**Repository state last verified:** 2026-10-31; the S1 security-test checkpoint starts from exact PR #717/local branch HEAD `2cd8fb7f36cff7bf5d9a431719098282e81709d9`; the GitHub CLI was unavailable, while the read-only connector refresh is recorded below
**Branch:** `tnyx/routine-notes-persistence`
**Starting branch HEAD SHA:** `2cd8fb7f36cff7bf5d9a431719098282e81709d9` (S1 task preflight)
**Validated pre-commit base SHA:** `2cd8fb7f36cff7bf5d9a431719098282e81709d9` (S1 tests ran against this base plus the allowlisted uncommitted test/handoff changes)
**Slice 1 commit:** `ec8a314e` (`feat(database): add routine notes persistence foundation`)
**Observed pre-commit working-tree state:** Clean before the S1 edits; only the allowlisted SQL test, focused Dart test and this handoff are dirty now
**Current commit scope:** Owner-authorized S1 checkpoint commit is limited to `.ai/tasks/routine-notes-implementation.md`, `supabase/tests/database/tnyx_81_routine_notes_persistence.test.sql` and `apps/features/workout/test/data/supabase_routine_notes_repository_test.dart`; no production source or migration is included
**PR / tracker:** Linear `TNYX-81` parent; no dedicated Notes issue created
**Current implementation state:** Domain, migration/RPC, repository adapter, Option A snapshot replay, body normalization, 50-total-quota remediation and the P1 fail-closed legacy-receipt guard are present locally at HEAD `2cd8fb7f`; hosted Notes migration remains unapplied
**Relevant execution surface:** `apps/shared`, `apps/features/workout`, `supabase/migrations`, `supabase/tests/database`
**Validation completed at working tree:** The hardened harness replayed 76 migration files on a disposable Docker database using the pre-Notes baseline and the exact migration boundary. Two legacy `NULL`-snapshot receipts failed atomically with SQLSTATE `P0001`; receipt rows, original mutation/reconciliation function definitions, the added column and migration ledger entries remained unchanged. The two-session test confirmed the `ACCESS EXCLUSIVE` lock blocks a concurrent legacy receipt write until the migration precondition is evaluated. The clean full sequence passed with non-NULL snapshots and the existing Routine Notes persistence/replay matrix. Pinned Supabase CLI `2.116.0` `db lint` exited `0`; local `db advisors` exited `0` with existing project-wide INFO/WARN findings, including the expected private receipt-table no-policy advisory. Effective Routine Note RPC grants, `SECURITY DEFINER` and empty `search_path` were verified. No production Dart files changed; the allowlisted focused repository test contains the local S1 regressions.
**Hosted evidence:** Exact project ref `oykupyiitspujzpwwvuj` was verified as the linked healthy Tio-world project. Hosted migration history ends at `20261028110000`; the Notes tables, mutation RPC and reconciliation RPC are absent on the hosted project, so the Notes migration remains unapplied and hosted Notes security is not verified. Last verified PR #717 state at exact head `2cd8fb7f36cff7bf5d9a431719098282e81709d9` was OPEN and `CHANGES_REQUESTED`; a fresh GitHub refresh during this S1 task failed with API connectivity.
**Validation remaining:** Independently run the hosted Security Advisor gate after the Notes migration is deployed; S1/S2 architecture and P3 recommendations remain separate owner decisions; hosted apply/deployment and merge remain out of scope.
**Current blocker:** Local S1 test coverage is complete. Hosted Notes security/Advisor evidence remains unavailable while migrations are unapplied.
**Review status:** The last exact-head hosted review remains `CHANGES_REQUESTED` for the separate S1/security evidence gate. Local S1 test additions are not hosted or reviewed. No hosted migration or Linear mutation was performed.
**Next exact action:** After a separately authorized commit/push, refresh PR #717 reviews, unresolved threads and CI at the exact pushed head. Keep PR #717 unmerged and do not apply the migration or release.

## 2026-10-31 — S1 security test coverage completion checkpoint

Owner conditionally approved retaining the existing public authenticated-only
`SECURITY DEFINER` Routine Notes RPC architecture on 2026-10-31. The rationale
is to preserve the already-reviewed trusted `auth.uid()` owner boundary,
transactional mutation path and immutable receipt replay contract without an
unapproved S2 architecture migration. This is conditional test coverage
approval, not production security approval.

Required conditions are effective PostgreSQL ACL verification for `PUBLIC`,
`anon`, `authenticated` and `service_role`; owner/schema/table/RLS checks;
empty `search_path` for Notes `SECURITY DEFINER` functions; explicit
`SECURITY INVOKER` inspection for trigger helpers; cross-user mutation and
receipt-isolation regressions; anonymous and `service_role` runtime denial;
and a hosted Security Advisor review after the Notes migrations are deployed.
The shared `public.set_row_updated_at()` helper was inspected without changing
it: it is `SECURITY INVOKER`, owned by `postgres`, has the existing PUBLIC
`EXECUTE` ACL, and uses `search_path=public, pg_temp`; this remains a documented
shared-helper risk review rather than a production grant change.

This checkpoint started from branch `tnyx/routine-notes-persistence` and exact
HEAD `2cd8fb7f36cff7bf5d9a431719098282e81709d9` for PR #717. The existing Dart
`account switch after mutation is reported as unknown` test was retained. New
focused Dart tests cover ambiguous mutation failure after an account switch
without reconciliation, and an account switch while reconciliation is in
flight; both require `RoutineNoteOutcomeUnknown` with
`RoutineNoteUncertainty.sessionChanged`. The fake gateway uses only
deterministic callbacks/completers.

The SQL matrix now covers effective public-RPC/legacy/private-helper ACLs,
PUBLIC catalog defaults via `pg_proc.proacl`, `aclexplode` and `acldefault`,
function/schema ownership and CREATE/USAGE inspection, Notes/receipt table
ACLs and RLS, cross-user update/delete/reconcile, same-mutation-UUID
account-switch isolation, and `anon`/`service_role` SQLSTATE `42501` runtime
denial. It passed on 2026-10-31 against a disposable Postgres container with
all 76 repository migrations replayed. `dart format` passed with direct Dart
3.12.2 and `dart analyze` reported no issues. The package-correct
`flutter test --reporter expanded --concurrency=1 --timeout 30s`
invocation passed all 7 tests with exit code `0`; the two newly added
account-switch regression tests also passed independently with exit code `0`.
The earlier root-checkout invocation exited `1` immediately because the root
package has no `flutter_test`/`test` dependency; the prior 90-second no-output
run was a runner/environment issue, not an async test failure. `git diff --check`
passed with `core.fsmonitor=false`.

The current working-tree changes are limited to the approved SQL test, focused
Dart test and this handoff. No migration, RPC, RLS, grant, production source,
Supabase configuration, hosted project, GitHub, Linear, commit or push was
changed. The GitHub CLI refresh failed with an API connectivity error, but the
read-only GitHub connector refresh succeeded on 2026-10-31: PR #717 remains
OPEN, non-draft and mergeable at exact head
`2cd8fb7f36cff7bf5d9a431719098282e81709d9`; the latest review is
`CHANGES_REQUESTED`, with 11 total review threads and 9 unresolved,
non-outdated threads. Hosted Notes migrations and Notes Security Advisor
coverage remain absent. Therefore local S1 test coverage is complete, while
the hosted post-deploy Advisor gate remains pending and S1 is not a hosted
security approval.

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
| Canonical ExerciseRef and adapter compatibility | `apps/shared/lib/src/workout/routine_note.dart` and focused test | Direct Dart format and analyze passed; package-correct Flutter test passed all 7 focused repository tests, including both account-switch regressions | Local direct Dart 3.12.2 / Flutter SDK package runner | No hosted/client parity claim until hosted evidence exists |
| SQL security and grants | Snapshot migration plus existing Notes RPCs | SQL matrix, db lint exit 0, local Advisor exit 0 with reported INFO/WARN findings, and explicit local client-grant/RPC query passed | Disposable Supabase Postgres | Hosted Notes objects are unapplied; hosted security review remains pending |
| Review-contract regression coverage | `supabase/tests/database/tnyx_81_routine_notes_persistence.test.sql`, `apps/shared/test/workout/routine_note_test.dart` | 76-migration replay, Unicode body parity, 500/501 scalar boundaries, 50-user quota and existing two-session harness passed; package-correct focused Flutter test passed all 7 repository tests, including the two new account-switch regressions | Disposable Docker Postgres / local Dart and Flutter SDK | Hosted PR head does not yet contain this remediation |
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
| `PR717-SNAPSHOT-TESTS` | Resolved locally | Four regression tests now cover cascade direct replay, complete JSONB equality, legacy-null fail-closed replay/reconciliation and trigger-failure rollback; disposable 76-migration replay and SQL matrix passed | Owner inspection and independent review |
| `PR717-BODY-NORMALIZATION` | Implemented locally | SQL and Dart now trim the approved Unicode White_Space set, reject empty normalized bodies and count Unicode scalar values; focused SQL parity cases and package-correct Flutter tests passed | Local SQL matrix, focused Flutter test and independent review |
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
