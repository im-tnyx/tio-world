# Routine Notes Persistence Foundation

**Status:** Validated — PR #717 merged on 2026-10-31; hosted deployment remains separate
**Primary owner:** Codex (current implementation session)
**Affected platforms:** Shared, Workout feature, Supabase database

## Owner Approval and Scope Boundary

**Trigger:** Supabase table/column shape change
**Approval status:** Approved
**Approval evidence:** Owner-approved Slice 1 implementation kickoff supplied on 2026-10-29: `Implement Slice 1 — Routine Notes Persistence Foundation`.
**Approved product/UI/data-shape boundaries:** Durable owner-scoped Routine and Exercise Notes foundation; stable UUID identity; canonical `ExerciseRef` serialization; five active Notes per canonical scope; 500-character normalized body; revision-checked protected mutations; durable `(user_id, mutation_id)` receipts; owner-scoped reads; no UI in this slice.
**Explicit non-changes:** No Notes UI, Routine Set or Rest Timer changes, WorkoutSession/history integration, post publishing, hosted migration apply, production privilege activation, or deployment. Commit, branch push, PR creation and later PR merge were separately authorized for this Slice 1. At archive creation, GitHub #716 status/update could not be verified; its post-merge status was subsequently refreshed, updated with exact evidence, and closed after its validation criteria were confirmed complete.

## Archived Handoff — Historical Slice 1 Checkpoint

**Final disposition (2026-10-31):** PR #717 merged after exact-head independent `im-tio` approval, 24/24 external review threads resolved, and required CI passed. Final PR HEAD: `9516c4735be0ea4e99f5384bd50087c8aa406c8d`; merge commit: `58b5161879d40d2c44e749a61e078294304d2092`. Post-merge `main` and `origin/main` were verified equal at the merge commit. GitHub #716 was updated with the merge, approval, CI and no-deployment evidence and closed after the validation acceptance criteria were confirmed complete: https://github.com/im-tnyx/tio-world/issues/716#issuecomment-6546518502. Linear TNYX-81 remains Backlog because broader W4 work is incomplete. Hosted Notes migration/scheduler/security verification and production deployment were not performed. This task brief and archive index are reconciled in a documentation-only follow-up PR.

**Planning owner:** Product owner / existing W4 planning
**Implementation owner:** Codex (current implementation session)
**Review owner:** Not assigned
**Implementation ownership state:** Validated
**Ownership transition:** Implementation slice closed after PR #717 merge; no active source owner remains for this brief.
**Source-fix push verified:** 2026-10-31; commit `82fe4a360af726161ae3c8876a99a177546d7b70` contains the repository/test fixes and initial handoff reconciliation, and was verified on `tnyx/routine-notes-persistence`. This docs-only follow-up records the post-push checkpoint.
**Branch:** `tnyx/routine-notes-persistence`
**Historical Slice 1 starting branch HEAD:** `b622ac2f46bab324fd86a4d7cc825c664b0eca57`
**Historical Slice 1 pre-commit base:** `b622ac2f46bab324fd86a4d7cc825c664b0eca57`; that earlier task's follow-up documentation commit is `9d5dbda8`
**Slice 1 commit:** `ec8a314e` (`feat(database): add routine notes persistence foundation`)
**Observed starting working-tree state:** Existing local SQL normalization/index migration and SQL regression changes were present before receipt-retention work; they were preserved in the scoped commit. Current scope also included the receipt-retention migration, Dart repository/result mapping, focused tests and this handoff.
**Historical commit scope at source-fix push:** Commit `82fe4a36` contained the two Routine Notes review fixes and initial handoff reconciliation; it was normally pushed and verified under the attached 2026-10-31 authorization. At that checkpoint, PR #717 had not yet merged and its review threads had not yet been resolved. The subsequent merge and review closure are recorded in the Final disposition above. Hosted migration apply, scheduler creation and other hosted mutations remain unperformed.
**PR / tracker:** Linear `TNYX-81` parent; no dedicated Notes issue created
**Merged implementation state:** The approved 30-day full-snapshot retention contract is implemented in the migration merged by PR #717, including a local disposable-database `pg_cron` cleanup schedule and successful-job-history pruning. The cleanup preserves `mutation_id`, `request_hash` and tombstone metadata, redacts only the Note body, and retains explicit `expired` replay/reconciliation behavior. The local behavior and regression matrix were validated before merge. Hosted enforcement is not active or claimed; hosted extension/scheduler configuration and production validation remain separate gates.
**Relevant execution surface:** `apps/shared`, `apps/features/workout`, `supabase/migrations`, `supabase/tests/database`
**Prior Slice 1 validation checkpoint:** The hardened harness replayed 76 migration files on a disposable Docker database using the pre-Notes baseline and the exact migration boundary. Two legacy `NULL`-snapshot receipts failed atomically with SQLSTATE `P0001`; receipt rows, original mutation/reconciliation function definitions, the added column and migration ledger entries remained unchanged. The two-session test confirmed the `ACCESS EXCLUSIVE` lock blocks a concurrent legacy receipt write until the migration precondition is evaluated. The clean full sequence passed with non-NULL snapshots and the existing Routine Notes persistence/replay matrix. Pinned Supabase CLI `2.116.0` `db lint` exited `0`; local `db advisors` exited `0` with existing project-wide INFO/WARN findings, including the expected private receipt-table no-policy advisory. Effective Routine Note RPC grants, `SECURITY DEFINER` and empty `search_path` were verified. At that checkpoint no production Dart files changed; current bounded review remediation now changes only the Routine Notes repository and its focused test.
**Hosted evidence:** The Notes migrations remain unapplied and hosted Notes-specific Security Advisor evidence is pending. No hosted security approval is claimed.
**Current validation:** Prior local SQL persistence/retention matrix, expired-retry concurrency race, migration replay, `db lint`, local advisors and ACL checks remain as recorded below and are local-only. For the two current Dart findings, direct Flutter test runner passed `supabase_routine_notes_repository_test.dart` 11/11, direct Dart formatting/check left 2 files unchanged, and Workout package analysis reported no issues. The Flutter command printed a pre-existing `uses-material-design` package warning; it exited 0. `git diff --check` passed before the scoped commit. No SQL or migration changed in this remediation.
**PR snapshot immediately after source-fix push (2026-10-31):** PR #717 was OPEN, non-draft, unmerged, head `82fe4a360af726161ae3c8876a99a177546d7b70`, base `main`, merge state `BLOCKED`, and review decision `CHANGES_REQUESTED`. That head's first check refresh had 8 pending, 3 skipped, 0 failed and 0 passed. There were 22 review threads; 18 were unresolved/non-outdated. Codex finding `4431238409` was outdated (thread remains unresolved in GitHub metadata) after this repository path changed; `4431238413` remained unresolved/non-outdated. The latest independent `im-tio` review was on prior head `4d2f2063` and requests changes over incomplete retention; no independent review of `82fe4a36` existed at that checkpoint. Current Linear state at the same task reconciliation: TNYX-81 is Backlog and blocked by TNYX-78 and TNYX-80; TNYX-78 and TNYX-80 are In Progress. Linear search found no dedicated Routine Notes issue, so TNYX-81 remains the broad planning parent; no tracker was changed. A later handoff-only commit will trigger fresh docs/attribution CI and requires another live refresh.
**Receipt-cleanup architecture gate:** The approved local implementation uses a bounded private `pg_cron` sweep. Hosted extension availability/privileges, schedule registration, job ownership and monitoring remain unverified and unauthorized. Therefore this work does not claim production enforcement. See the latest validation checkpoint below for the local scheduler/function role boundary and remaining deployment gates.
**Next exact action at the preceding checkpoint:** After the handoff-only sync push, refresh CI/reviews and reassess the retention finding. This was superseded by the 2026-10-31 owner authorization and scheduled-cleanup implementation checkpoint below.

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
| S1/S2 RPC security architecture | S1 conditionally approved for Slice 1 | Retain current authenticated-only public `SECURITY DEFINER` wrappers with verified ACL/ownership/schema/RLS/search_path/helper/cross-owner checks; this is not production approval. S2 remains a separately reviewed alternative. Hosted Notes deployment and Notes-specific Advisor evidence remain mandatory gates. | Product owner, 2026-10-31 |
| Receipt retention | 30 days approved; local scheduled enforcement implemented | Keep full snapshots through 30 days from `created_at`; then redact Note body and retain mutation ID, request hash and identifying tombstone metadata; expired reconciliation is explicit and expired IDs never execute again. Hosted scheduler deployment remains unauthorized and unverified. | Product owner, 2026-10-31 |
| Cross-user Note UUID conflict | Owner-scoped identity approved and implemented in this remediation | Use `(user_id, id)` as the Notes primary key and scope duplicate checks to authenticated `auth.uid()`; preserve the public Note DTO and same-owner duplicate conflict while permitting the same UUID in different owner namespaces. | Product owner, 2026-10-31 |
| Custom Exercise lifecycle | Archive-only behavior confirmed for this PR | Keep authenticated hard-delete denied and preserve `ON DELETE NO ACTION`; a future privileged hard-delete requires its own approved composition/Note lifecycle contract. | Product owner |

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
| Review-contract regression coverage | `supabase/tests/database/tnyx_81_routine_notes_persistence.test.sql`, `apps/shared/test/workout/routine_note_test.dart` | Prior 76-migration replay and SQL matrix passed; package-correct Flutter test passed all 7 repository tests, including account-switch regressions | Disposable Docker Postgres / local Dart and Flutter SDK | Hosted Note migrations and Notes-specific Advisor evidence remain pending |
| Legacy receipt migration boundary | `supabase/migrations/20261030081321_routine_note_legacy_receipt_gate.sql`, `supabase/tests/database/tnyx_81_routine_notes_legacy_receipt_gate.sh` | Two legacy NULL receipts fail closed without mutation or ledger success; clean valid snapshot is preserved; clean gate, normal SQL matrix and hardened cleanup harness pass | Disposable Docker Postgres, CLI 2.116.0 | Hosted migration not applied; independent review remains required |

### Review Provenance

**Review source / link:** chat-provided Slice 1 review-fix handoff, GitHub #716/#717, Linear `TNYX-81`, and repository source inspection
**Reviewer / relation to implementer:** Self-review pending independent review
**Diff or commit SHA actually reviewed:** hosted review #5709617294 reviewed head `a6034ccf15724d6827aa4f0a84321d5f48412c83`; the legacy-receipt gate is the post-review local remediation checkpoint
**Review result and finding IDs/dispositions:** Immutable replay, body-normalization, total-quota, legacy-receipt gate, migration order and mutation-ID preservation are present in pushed history. Current hosted `im-tio` review remains `CHANGES_REQUESTED` on `4d2f2063`; it says receipt retention is only access-time and incomplete. New current-head Codex findings `4431238409` and `4431238413` are locally fixed and tested in the pending worktree diff. The original mutation-ID session-change finding was fixed in pushed history at `b622ac2f`. At that earlier checkpoint, only the scheduler mechanism remained unapproved; the owner later authorized a local disposable implementation, recorded below. Cross-user Note UUID and Custom Exercise lifecycle decisions remain separate.
**Independent review?** No (self-review)
**Limitations and unmet required gates:** Hosted schema apply/deployment and Notes-specific Security Advisor evidence remain pending. S1 is conditionally approved for this Slice 1 boundary, not production-verified. P3 owner decisions, independent approval, exact post-push CI/review and merge authorization remain separate gates. Dedicated Linear issue creation was not requested and no child issue was created.

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
| `PR717-MUTATION-ID-SESSION-CHANGE` | Resolved in pushed history | Commit `b622ac2f` passes the original mutation UUID into `_checkOwner`; focused tests assert UUID, session-changed reason and no reconciliation | New-head independent review |
| `4431238409` / `PR717-READ-SESSION-SWITCH` | Fixed and pushed in `82fe4a36`; GitHub thread is outdated but unresolved | `read()` now returns `RoutineNoteException(unauthorized)` on owner change; focused regression verifies no stale data, mutation call or reconciliation | Independent new-head review; thread state unchanged |
| `4431238413` / `PR717-MALFORMED-RPC-RESULT` | Fixed and pushed in `82fe4a36`; GitHub thread remains unresolved/current | `_noteResult()` maps parse `TypeError` to `RoutineNoteException(malformedData)`; numeric `last_mutation_id` regression passes; applied/expired mapping regressions remain green | Independent new-head review; thread state unchanged |
| `PR717-SECURITY-DEFINER` | S1 conditionally approved for Slice 1 | Local grants, ownership, RLS, `SECURITY DEFINER`, empty `search_path`, helper execution and cross-owner tests recorded; hosted Notes objects remain absent | Hosted deployment and Notes-specific Security Advisor/security review |
| `PR717-RECEIPT-RETENTION` | Implemented and locally scheduled; hosted enforcement pending | Owner-approved 30-day full snapshots and redacted permanent tombstones are enforced by bounded `pg_cron` cleanup in the migration; SQL matrix and two-session cleanup/reconciliation race passed locally | Hosted deployment, scheduler permissions/operations and Notes-specific Security Advisor remain unauthorized/unverified |
| `PR717-P3-A-UUID-SIGNAL` | Owner-approved and pushed in `f97e8480` | Global Note UUID collision check/primary key replaced by `(user_id, id)` identity; regression verifies cross-owner reuse, RLS isolation and same-owner duplicate rejection | Exact-head CI passed; fresh independent acceptance pending |
| `PR717-P3-B-CUSTOM-EXERCISE-LIFECYCLE` | Future lifecycle requirement; not a PR #717 defect | Authenticated hard-delete is denied, Routine composition uses `ON DELETE NO ACTION`, archive is supported, and Note creation rejects archived Custom Exercises | No hard-delete feature in this PR |

### Decision-ready follow-ups from review #5709617294

**Security boundary decision:** Owner conditionally approved S1 on 2026-10-31
for this Slice 1 compatibility boundary: retain the current authenticated-only
public `SECURITY DEFINER` wrappers subject to effective ACL, ownership/schema,
RLS, empty `search_path`, helper execution and cross-owner checks. This is not
production security approval. Hosted Notes migrations and Notes-specific
Security Advisor evidence remain mandatory after deployment. S2 remains a
possible separately reviewed alternative and is not authorized by this decision.

**Receipt retention owner decision and partial implementation (2026-10-31):** the owner
approved 30 days from `created_at`, then Note-body redaction with a permanent
idempotency tombstone. The local migration redacts during authenticated
reconciliation or duplicate retry and returns `status: expired`; `mutation_id`,
`request_hash` and mutation metadata remain. No approved scheduler/cleanup runner
exists in repository configuration, migrations, functions or workflows, so
inactive users' snapshots are not redacted at the deadline. Do not report the
retention policy fully enforced until an existing safe cleanup path is wired or
new scheduling infrastructure is separately approved.

**Scheduler architecture gate:** Checked-in `supabase/config.toml`, migrations,
functions, GitHub workflows and deployment docs contain no approved scheduled
receipt-cleanup invocation. Prefer a narrow database-native `pg_cron` batch job
if the hosted project already supports it and owner approves the extension/job
privileges: bounded batches, `FOR UPDATE SKIP LOCKED`, idempotent body redaction,
`mutation_id`/`request_hash` tombstone preservation, run-failure/lag monitoring,
and rollback by unscheduling. A protected scheduled Edge Function would still
need scheduler setup, protected credentials, network retry/authorization,
monitoring and deployment/rollback, adding an unnecessary HTTP trust boundary
for a database-local operation. Hosted extension availability, job role and
operational ownership are not verified. Owner approval is required to choose
and authorize either invocation path at the time of that earlier audit; the
owner's later local-disposable authorization and implementation are recorded
in the checkpoint below.

**P3-A cross-user Note UUID signaling — owner-approved remediation (2026-10-31):**
the Notes primary key is `(user_id, id)` and create collision checks are scoped
to the authenticated `auth.uid()` owner. The public RoutineNote shape remains
unchanged, and same-owner duplicate IDs still return the existing conflict.
The SQL matrix and two-session disposable-Postgres race verify cross-user UUID
reuse without cross-owner reads or mutation. The migration is not applied to
hosted Supabase.

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

## 2026-10-31 — Scheduled receipt cleanup implementation checkpoint

Owner authorization: local implementation and validation only in disposable
Postgres project `tnyx717receipt20261031`. No hosted Supabase operation is
authorized. Program/Routine sharing, AI content, Notes UI, Routine Create/Edit,
WorkoutSession/history and changes to the personal RoutineId / user+ExerciseRef
Notes scopes remain out of scope.

### Implementation files in the pending worktree

* `supabase/migrations/20261031130000_routine_note_receipt_scheduled_cleanup.sql`
  installs local `pg_cron`, creates a private sweep function and invoker history
  pruner, registers five-minute and daily schedules, and uses batches capped at
  500 with oldest-first ordering and `FOR UPDATE SKIP LOCKED`.
* `supabase/tests/database/tnyx_81_routine_note_receipt_cleanup.test.sql`
  covers effective role/ACL/RLS behavior, expiry boundaries, dormant and
  repeated cleanup, body redaction, permanent tombstones, retry/reconcile,
  owner isolation, malformed snapshots, batch continuation and scheduling.
* `supabase/tests/database/tnyx_81_routine_note_receipt_cleanup_concurrency.sh`
  covers two-worker batches, cleanup/reconciliation and cleanup/mutation locks,
  scheduler failure/recovery and failure-history preservation.
* `.github/workflows/supabase-db-ci.yml` wires the matrix and concurrency
  harness into the existing database workflow.

### Local disposable evidence

The named disposable DB reported PostgreSQL 17.6, `pg_cron` 1.6.4,
`cron.use_background_workers=off`, and 79 migration ledger entries. Its existing
draft schema was older than the current pending migration in three details
(pruner owner, split RLS policies and explicit role SET membership). The local
database was aligned to the current draft for regression validation; this is
not evidence of a fresh full migration replay on that exact database.

* `tnyx_81_routine_notes_persistence.test.sql` passed with `psql -v
  ON_ERROR_STOP=1`.
* `tnyx_81_routine_note_receipt_cleanup.test.sql` passed after the disposable
  schema was aligned to the current draft. It covered the 30-day cutoff,
  tombstone/hash preservation, repeated calls, expired retry refusal,
  cross-owner isolation, malformed/null fail-closed cases and 511-row batch
  continuation.
* `tnyx_81_routine_note_receipt_cleanup_concurrency.sh` passed in the same
  disposable container: two concurrent workers processed distinct 500-row
  batches; locked receipts were skipped then handled later; reconciliation and
  duplicate mutation serialized safely; cron failure was recorded, recovery
  succeeded, and failed history was retained.
* Focused Flutter repository test passed 11/11 with Flutter 3.44.6 using the
  bounded verbose runner. The normal sandbox invocation produced no output and
  was interrupted; the elevated rerun passed.
* `git diff --check` passed after the task brief update.
* Supabase CLI `db lint --db-url` could not authenticate to this container's
  non-TLS local listener (TLS and password negotiation errors); do not claim a
  lint result for this DB. Earlier local lint/advisor evidence predates this
  cleanup migration. Hosted Advisor has not run.

### Role, scheduling and operational limits

`private.cleanup_expired_user_workout_routine_note_receipts()` is narrowly
`SECURITY DEFINER`, owned by `routine_note_receipt_cleanup_owner`, has empty
`search_path`, exact scheduler EXECUTE, column-scoped receipt access and split
owner RLS policies. The scheduler has no receipt-table privileges. History
pruning is `SECURITY INVOKER`; the scheduler can see/prune only its own cron
history and the bounded function retains failed runs. Client roles have no
`cron` schema USAGE or cleanup function EXECUTE.

PostgreSQL 17 creates an automatic creator membership when `postgres` creates
the helper roles. The membership is only for trusted `postgres`; its
`supabase_admin`-recorded ADMIN option cannot be revoked by the migration
principal. The migration explicitly grants effective `SET TRUE`, and tests
assert effective `SET ROLE` plus no application-role membership. This local
Supabase privilege nuance needs independent reviewer acceptance.

Expiry cadence is five minutes and history pruning is daily at 03:17 UTC in
the disposable environment. This is not a ten-minute SLA: run duration, receipt
arrival rate and backlog capacity are not measured. Alerting/lag monitoring
must be defined before production activation. Rollback requires unscheduling
both jobs before dropping the functions/roles/extension; redacted Note bodies
are not recoverable and must never be restored from receipts.

### Review and release gates

Immediately before this checkpoint update, PR #717 was OPEN, non-draft and
unmerged at hosted head `a0285c7bec483cd94e6905414593f266fd5eb3d9`, base
`9c782688acd13efd189b7827c139dea3aca1a5d6`, review `CHANGES_REQUESTED`, with
18 unresolved/non-outdated and 4 unresolved/outdated review threads. Exact-head
CI was green: Database `41189728092`, Flutter `41189728017`, Docs Hygiene
`41189728023`, attribution `41189726348`. These checks predate this pending
diff and are not current-head validation.

P3-A owner-scoped UUID identity was pushed in `f97e8480` under explicit owner
approval. The focused SQL matrix and a two-session same-UUID cross-owner race
passed on the named disposable database. P3-B is a future lifecycle requirement:
Custom Exercise hard-delete is denied, archive is supported, and Routine
composition uses `ON DELETE NO ACTION`. Both dispositions were sent to the
reviewer for acceptance. Twenty verified threads were individually resolved;
the lifecycle and S1/hosted-security threads remain open pending reviewer
acceptance.
Hosted pg_cron enablement, hosted schedule, Notes migration apply, hosted
Security Advisor, deployment and production data changes remain unauthorized.

### Post-push verification — 2026-10-31

Commit `90bd5a52a16da0b85cdc32c02fe96f5e5d76cf62`
(`fix(database): enforce routine note receipt retention`) was pushed normally
to `tnyx/routine-notes-persistence`. GitHub confirms the same exact PR head,
base `9c782688acd13efd189b7827c139dea3aca1a5d6`, PR OPEN/non-draft/unmerged.
Exact-head workflows passed: Database `41206647348` (migration replay plus SQL
matrix and race harness), Flutter `41206647418` (analyze and all three package
shards), Docs Hygiene `41206647470`, and attribution `41206644723`. Cursor
Bugbot and Cursor Approval/Security Agents were skipped, not passes.

Historical checkpoint at `90bd5a52` (superseded by the owner-scoped UUID
checkpoint below): fresh independent review was requested from `im-tio` on this head. At the
latest refresh the review decision remained `CHANGES_REQUESTED`, inherited
from older head `a0285c7bec483cd94e6905414593f266fd5eb3d9`; the reviewer had not
yet submitted a new review. Thread counts remained 22 total, 18 unresolved
non-outdated and 4 unresolved outdated. No thread was resolved. Merge state was
`CLEAN`, but merge is blocked until the reviewer responds, P3 dispositions are
accepted where needed, and blocking threads are individually reconciled.

### Owner-scoped Note UUID and final review checkpoint — 2026-10-31

Commit `f97e8480aa03a28bb7b9ca585fe4dbcab018ff7e`
(`fix(database): scope routine note ids by owner`) is pushed to
`tnyx/routine-notes-persistence`. It changes Note identity from global `id` to
`(user_id, id)`, scopes create-collision lookup to authenticated ownership, and
adds SQL assertions for same-UUID cross-owner reuse/RLS isolation plus
same-owner duplicate rejection. The public Note DTO is unchanged. The owner
approved this schema shape on 2026-10-31.

PASS on the named disposable project `tnyx717receipt20261031`: migration
registered and `PRIMARY KEY (user_id, id)` verified; Routine Notes SQL matrix
passed; two authenticated sessions concurrently created distinct Notes with
the same UUID; temporary race accounts were removed. Exact-head checks on
`f97e8480` passed: Database CI `41210167681` (full migration replay and
SQL/race suites), Flutter CI `41210167566` (analyze and all three package
shards), Docs Hygiene `41210167679`, and attribution `41210165246`. Cursor
Bugbot and Cursor Approval/Security agents were `neutral` because usage limits
prevented them from starting; they are not passes.

The connected Linear PR mirror was refreshed at `2026-10-31T14:35:04Z` and
reported exact head `f97e8480aa03a28bb7b9ca585fe4dbcab018ff7e`, base
`9c782688acd13efd189b7827c139dea3aca1a5d6`, OPEN/non-draft, unmerged, and
review requested from `im-tio`. The latest submitted independent decision is
still `CHANGES_REQUESTED` from an earlier head; there is no fresh exact-head
approval. The mirror reports 22 inline threads: 20 individually resolved, 2
current threads open, 0 outdated unresolved. Per-thread evidence and disposition
are recorded below. A direct `gh` refresh was unavailable, so these remote
values are attributed to the connected PR mirror, not a direct GitHub API call.
No hosted Notes migration, pg_cron installation/schedule, hosted Advisor,
deployment or production change was performed.

#### Inline review thread reconciliation at `f97e8480`

`CI` below means the exact-head Database/Flutter/Docs Hygiene evidence above;
each disposition was individually checked in the connected PR thread mirror.
“Ack: prior review” records explicit acknowledgement in `im-tio`'s earlier
review; otherwise no reviewer acceptance is inferred. Fixed-thread resolution
is justified by the cited code/test evidence, not by treating missing reviewer
acknowledgement as approval.

| Thread ID | Anchor / reviewer / severity | State | Fix or disposition and regression evidence | Reviewer acknowledgement / resolution |
|---|---|---|---|---|
| `PRRT_kwDOTOXwB86xtCjL` | Notes migration:271 / im-tio / P2 | Current, resolved | Immutable result snapshot in `0d085586`; replay/delete/cascade SQL matrix, CI | Re-reviewed; fixed and resolved |
| `PRRT_kwDOTOXwB86x3LGY` | Notes migration:179 / im-tnyx / P2 | Current, resolved | SQL/Dart normalization in `9d5dbda8`; whitespace/code-point boundary matrix, CI | Ack: prior review; fixed and resolved |
| `PRRT_kwDOTOXwB86x3LGc` | `routine_note.dart`:86 / im-tnyx / P2 | Outdated, resolved | Dart trim/code-point alignment in `a6034ccf`/`9d5dbda8`; model tests, CI | Ack: prior review; fixed and resolved |
| `PRRT_kwDOTOXwB86x3LGg` | Notes migration:271 / im-tnyx / P2 | Current, resolved | Immutable snapshot replay in `0d085586`; deletion/cascade/legacy SQL tests, CI | No separate reviewer acknowledgement recorded; code/test fix verified and resolved |
| `PRRT_kwDOTOXwB86x3LGk` | Notes migration:201 / im-tnyx / P2 | Current, resolved | Per-scope and total per-user caps in `a6034ccf`/`9d5dbda8`; quota matrix, CI | Ack: prior review; fixed and resolved |
| `PRRT_kwDOTOXwB86x3LGn` | Notes migration:359 / im-tnyx / P3 | Outdated, resolved | Owner-scoped PK and collision lookup in `f97e8480`; RLS, duplicate and two-session SQL tests | Evidence reply posted; resolved for implemented finding |
| `PRRT_kwDOTOXwB86x3LGs` | Notes migration:62 / im-tnyx / P3 | Current, resolved | Scheduled 30-day redaction in `90bd5a52`; expiry/batch/race matrix, CI | Ack: prior review; fixed and resolved |
| `PRRT_kwDOTOXwB86x3LGw` | Notes migration:9 / im-tnyx / P3 | Current, open | Not a PR defect: authenticated hard-delete denied, FK `NO ACTION`, archived Exercise rejected by Notes create; lifecycle remains separate | Evidence reply posted; reviewer disposition pending; not resolved |
| `PRRT_kwDOTOXwB86x91cq` | Snapshot migration:98 / im-tio / P1 | Current, resolved | Legacy-receipt gate moved before wrapper change in `2cd8fb7f`; full migration-sequence regression harness, CI | Re-reviewed; fixed and resolved |
| `PRRT_kwDOTOXwB86x91cw` | Task handoff:30 / im-tio / P3 | Outdated, resolved | Handoff checkpoints corrected in `d3e7c9d8` and this record; docs diff check | No separate reviewer acknowledgement recorded; stale statement superseded and resolved |
| `PRRT_kwDOTOXwB86yGTp4` | Snapshot migration:104 / im-tio / P2 | Current, open | S1 only conditionally approved for Slice 1 test/compatibility; local ACL/RLS/ownership/search_path tests; hosted Notes Advisor/deployment not verified | Evidence reply posted; reviewer says hosted/security boundary disposition pending; not resolved |
| `PRRT_kwDOTOXwB86yPTfm` | Task handoff:139 / im-tio / P3 | Current, resolved | S1 table aligned to conditional owner decision in `d3e7c9d8`; docs hygiene | Ack: prior review; fixed and resolved |
| `PRRT_kwDOTOXwB86yPTlD` | Workout Notes repository:285 / Codex / P2 | Outdated, resolved | Session-switch mutation receipt preserved in `b622ac2f`; focused repository test, CI | Ack: im-tio review on `a0285c7b`; fixed and resolved |
| `PRRT_kwDOTOXwB86yPTlG` | Notes migration:357 / Codex / P3 | Current, resolved | Same owner-scoped identity fix in `f97e8480`; RLS, duplicate and two-session SQL tests | Evidence reply posted; resolved for implemented finding |
| `PRRT_kwDOTOXwB86yPZP9` | Snapshot migration:60 / Codex / P2 | Current, resolved | 30-day cleanup in `90bd5a52`; expiry/tombstone/concurrency matrix, CI | Ack: prior review; fixed and resolved |
| `PRRT_kwDOTOXwB86yPZQB` | Notes migration:180 / Codex / P2 | Current, resolved | Normalize before hash/length in `9d5dbda8`; direct RPC Unicode-boundary tests, CI | Ack: prior review; fixed and resolved |
| `PRRT_kwDOTOXwB86yPZQC` | Contract migration:94 / Codex / P2 | Current, resolved | Unfiltered owner index in `9d5dbda8`; catalog/index assertions, CI | Ack: prior review; fixed and resolved |
| `PRRT_kwDOTOXwB86yPaZn` | Notes migration:179 / im-tio / P2 | Current, resolved | Approved whitespace normalization before request hash in `9d5dbda8`; NBSP direct-RPC test, CI | Ack: prior review; fixed and resolved |
| `PRRT_kwDOTOXwB86yPaZq` | Snapshot migration:60 / im-tio / P2 | Current, resolved | 30-day cleanup in `90bd5a52`; dormant receipt, batch and race tests, CI | Ack: prior review; fixed and resolved |
| `PRRT_kwDOTOXwB86yPaZr` | Contract migration:94 / im-tio / P2 | Current, resolved | Non-partial `user_id` quota index in `9d5dbda8`; catalog assertion, CI | Ack: prior review; fixed and resolved |
| `PRRT_kwDOTOXwB86yPoTj` | Workout repository:104 / Codex / P2 | Outdated, resolved | Read session-switch now reports a read error, not a fake mutation receipt, in `82fe4a36`; focused test, CI | Ack: im-tio review on `a0285c7b`; fixed and resolved |
| `PRRT_kwDOTOXwB86yPoTm` | `routine_note.dart`:115 / Codex / P2 | Current, resolved | Malformed RPC map conversion in `82fe4a36`; wrong-type `last_mutation_id` test, CI | No separate reviewer acknowledgement recorded; code/test fix verified and resolved |

The two open threads are the P3-B future lifecycle disposition and conditional
S1/hosted-security boundary. Both have factual evidence replies; reviewer
acceptance remains pending. Do not merge while the independent review decision
is `CHANGES_REQUESTED` or these dispositions remain unresolved.

## 2026-10-31 — Pre-push repository review checkpoint

At the connected PR mirror refresh, PR #717 remains OPEN and unmerged at
`2de278a19f2c7d90e4f860d8b1f44fab5e15db5d`. The Codex review on that head
identified two repository findings, now fixed in the local worktree:

* `PRRT_kwDOTOXwB86ySBND` — successful HTTP 2xx response decode errors are
  ambiguous; reconcile with the same mutation ID.
* `PRRT_kwDOTOXwB86ySBNE` — a failed reconciliation request, including expired
  JWT/401, cannot prove the original mutation rolled back; preserve
  `RoutineNoteOutcomeUnknown` and the original mutation ID.

The focused Flutter repository suite passed 14/14 on 2026-10-31 using Flutter
3.44.6; `dart format` reported no changes and `git diff --check` passed. The
two fixes have not yet been committed or pushed. Current hosted PR state still
has four open threads: these two findings plus the existing P3-B Custom
Exercise lifecycle and conditional S1/hosted-security boundary. The aggregate
review decision remains `CHANGES_REQUESTED`; fresh exact-head review and checks
are required after push. Do not merge or resolve threads as part of this local
fix checkpoint.

## 2026-10-31 — Exact-head merge-gate checkpoint

Review-fix commit `a58942cf82b89c7a54eda1840572a1ea724cdd34` is pushed to
`tnyx/routine-notes-persistence`. Focused Flutter repository tests passed
14/14, Flutter package analysis reported no issues, `dart format` made no
changes, and `git diff --check` passed. Exact-head GitHub checks passed:

* Database CI: `41216527235`.
* Flutter CI and all three package shards: `41216527293`.
* Docs Hygiene: `41216527240`.
* Commit attribution: `41216527227`.

Cursor Bugbot and Cursor Approval/Security agents were neutral because their
usage limits prevented review. A fresh `@codex review` request was posted, but
Codex reported its review usage limit; no new Codex review is available for
this head. `im-tio` re-review is requested; the last submitted independent
decision remains `CHANGES_REQUESTED` on an earlier head. Four inline threads
were open at the initial post-push review snapshot. The two fixed P2 findings
(`PRRT_kwDOTOXwB86ySBND`, `PRRT_kwDOTOXwB86ySBNE`) were resolved on 2026-10-31
after explicit owner authorization, evidence replies, and 14/14 focused
repository tests. Two current threads remain open: P3-B lifecycle and
conditional S1/hosted-security. PR is OPEN, in review and unmerged; merge is
BLOCKED until fresh independent approval and remaining review dispositions.
Hosted migrations, scheduler activation, Notes-specific hosted Advisor and
production deployment are not claimed.
