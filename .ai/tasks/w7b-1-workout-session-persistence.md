# Feature Task: W7B-1 Workout Session Persistence (Supabase Source-Only)

**2026-11-10 hosted deployment follow-up:** Source merged through PR #734. The separately owner-authorized testing-only deployment applied all three reviewed W7 migrations; ledger and verification evidence are in [the deployment receipt](w7-testing-only-hosted-migration-deployment.md). The owner-approved backup deferral was limited to this disposable testing rollout and did not change production recovery policy or authorize reset. No authenticated workout writes, device acceptance, release activation, or production readiness are claimed. A W7 trigger-helper Security Advisor finding remains for separate disposition.

**Status:** Source merged and hosted migration applied; trigger-helper Security Advisor disposition and broader W7 acceptance remain open
**Primary owner:** Antigravity
**Affected platforms:** Supabase (PostgreSQL Backend), GitHub CI

## Owner Approval and Scope Boundary

**Trigger:** Supabase table/column shape change & CI workflow integration
**Approval status:** Approved
**Approval evidence:** User prompt explicit instructions:
1. "GO — Tio-World W7B-1 Snapshot Contract Approval: मैं W7B-1 के पहले से निर्धारित two-table, source-only scope के भीतर rpc_start_workout_session में p_routine_snapshot jsonb जोड़ने की अनुमति देता हूँ।"
2. "Owner scope direction: I authorize the following narrowly scoped work for PR #734: 1. Fix the new independent-review P2 concurrency finding. 2. Add the W7B-1 security pgTAP and concurrency test steps to the existing .github/workflows/supabase-db-ci.yml. 3. Update the existing W7B-1 handoff and applicable Linear tracking to reflect verified status."
3. "PR #734 Final P2 Closure & Merge Readiness: 1. Fix P2 #4491456710 — Fail CI on pgTAP assertion failures. 2. Fix P2 #4491456719 — Concurrent Start idempotency in supabase/migrations/20261106073920_user_workout_sessions.sql."
4. "PR #734 Final Two P2 Corrections: 1. Fix P2 #4492021721 — Routine name integrity in rpc_start_workout_session. 2. Fix P2 #4492021727 — Terminal replay identity in rpc_complete_workout_session and rpc_discard_workout_session."
5. "GO — Approve PR #734 A/B/C/D bounded implementation: Owner contract approval for Gates A, B, C, D and review remediation."
6. "PR #734 Final P2 Compatibility Fix: Remove artificial 100-character snapshot name limit, align with existing source tables under 256 KiB ceiling, and extend pgTAP coverage to 82 assertions."

**Approved product/UI/data-shape boundaries:**
- Two owner-scoped tables: `public.user_workout_sessions` and `public.user_workout_performed_sets`.
- Partial unique index enforcing single active or paused session per user.
- 7 mutation RPCs (`rpc_start_workout_session`, `rpc_pause_workout_session`, `rpc_resume_workout_session`, `rpc_log_workout_performed_set`, `rpc_remove_workout_performed_set`, `rpc_complete_workout_session`, `rpc_discard_workout_session`).
- Consistent parent session (`user_workout_sessions`) -> child set (`user_workout_performed_sets`) lock hierarchy across all RPCs preventing `40P01` deadlocks.
- Contract Gate A (Mutation Recovery): Lookup-first idempotent set return without revision bump when payload is identical; strict OCC revision checking when payload is altered; read-after-write set deletion reconciliation (no tombstone tables); timestamp monotonic Pause/Resume retries across intervening mutations (`paused_at_utc` / `resumed_at_utc` matching with monotonic `last_transition_at_utc`).
- Contract Gate B (Historical Snapshot): Technical ceiling of 256 KiB (`octet_length <= 262144`); root and nested property key whitelists; canonical ExerciseRef regex (`^ex_[a-z0-9]+(?:_[a-z0-9]+)*$` or lowercase UUID); strict ISO-8601 UTC regex; unrestricted routine and exercise display names aligned with existing owner-writable source tables, validated for nonblank (`length(btrim(...)) > 0`), authoritative source name equality, and bounded under the 256 KiB technical ceiling; snapshot validation executed in `rpc_start_workout_session` and guarded via `BEFORE INSERT` trigger (`trg_user_workout_sessions_validate_snapshot`), eliminating row-level check re-validation on set mutations.
- Contract Gate C (Flexible Performed Sets): Hard limit of maximum 500 sets per session enforced under parent row lock in `rpc_log_workout_performed_set` (`count >= 500` raises `22023 session_performed_sets_limit_exceeded`); `set_index` range `0..999` enforced via `chk_user_workout_performed_sets_indices`; supports repeated exercise occurrences, extra sets beyond prescription, and sparse indices; updates and identical retries do not consume quota.
- Contract Gate D (Text Storage Protection): Maximum 65,536 UTF-8 bytes (`octet_length <= 65536`) enforced on `user_workout_sessions.notes`, `user_workout_sessions.discard_reason`, and `user_workout_performed_sets.notes`.
- Review findings remediation (P3 triage):
  * RLS policies updated to `using (user_id = (select auth.uid()))` for InitPlan evaluation.
  * Comprehensive explicit parameter NULL checks throwing `22023` for all required RPC arguments.
  * Permissive start timestamp plausibility window (`2020-01-01` to `now() + interval '1 day'`) for offline sync safety.
  * Ephemeral GitHub review thread IDs removed from SQL comments, replaced with invariant descriptions.
  * `rpc_start_workout_session` NULL-safe composition check (`if v_snap_ex is null`), safe UUID regex check before casting `exercise_ref::uuid`, and `FOR SHARE` locks on composition queries.
- CI integration of W7B-1 pgTAP suite with TAP-aware runner (`supabase/tests/database/run_pgtap.sh`) and 6-race concurrency harness (`supabase/tests/database/w7b_session_concurrency.sh`) into `.github/workflows/supabase-db-ci.yml`.

**Explicit non-changes:**
- No hosted Supabase migrations or writes (`oykupyiitspujzpwwvuj` untouched).
- No Flutter UI, gateway, or Dart domain modifications.
- No PR/RIR tables or indexes.
- No durable receipt table (`user_workout_mutation_receipts` deferred).
- No auto-merge or direct PR merge.

## Active Handoff

**Planning owner:** Antigravity
**Implementation owner:** Antigravity
**Review owner:** `im-tio`
**Implementation ownership state:** Active
**Ownership transition:** Not applicable
**Repository state last verified:** 2026-11-07 14:20 UTC+05:30
**Branch:** `feat/w7b-1-workout-session-persistence`
**PR:** https://github.com/im-tnyx/tio-world/pull/734
**PR Previous HEAD SHA:** `18db5b241f08c421b311df29224ece6d7b045865`
**Observed working-tree state:** Changes ready for commit
**Observed modified files:**
- `supabase/migrations/20261106073920_user_workout_sessions.sql`
- `supabase/tests/database/w7b_session_security.test.sql`
- `supabase/tests/database/w7b_session_concurrency.sh`
- `.ai/tasks/w7b-1-workout-session-persistence.md`
**PR / tracker:** Linear TNYX-84 (W7 Active Workout) - Restored to **In Progress**
**Current implementation state:** Full implementation and test coverage of approved Contract Gates A, B, C, D and review remediation complete. pgTAP test suite expanded to 82 assertions passing 100% on PostgreSQL 17; concurrency harness expanded from 5 to 6 races with Race 6 (concurrent idempotent set retry vs in-place set update) passing 100%; connection guard 11/11 tests passing; `git diff --check` passing with zero errors.
**Relevant execution surface:** `supabase/migrations/`, `supabase/tests/database/`, `.github/workflows/`
**Validation completed:**
- All migrations applied cleanly via `--single-transaction`.
- 82/82 pgTAP assertions pass in `supabase/tests/database/w7b_session_security.test.sql` with exit 0 via PostgreSQL 17 test harness.
- Negative TAP testing verified: assertion failure (`ok(false)`), plan mismatch, and fatal SQL syntax errors all exit with code 1.
- `supabase/tests/database/w7b_session_concurrency_guard.test.sh` passes 11/11 guard checks:
  - CI mode passes with exact loopback URL.
  - Local mode (`--local`) passes without `DATABASE_URL` and with exact loopback URL.
  - Rejects missing CI flag outside `--local`.
  - Rejects missing `DATABASE_URL` in CI.
  - Rejects unexpected/remote connection URIs in CI and in local `--local` mode.
  - Rejects all libpq environment overrides (`PGHOSTADDR`, `PGSERVICE`, `PGSERVICEFILE`, `PGHOST`, `PGPORT`, `PGDATABASE`, `PGUSER`, `PGOPTIONS`) in CI and in local mode.
  - Rejects unsupported arguments.
  - Security regression (4496780930): Sentinel password and connection string redaction verified across local mode, CI mode, and argument parsing; no credential or URL leakage in stdout/stderr, constant generic refusal message returned.
- `supabase/tests/database/w7b_session_concurrency.sh` passes across all 6 races:
  - Race 1: Finish vs Log Set (OCC rejection `stale_revision_conflict`, revision 2, 0 sets).
  - Race 2A: Log/Update vs Remove, Update wins (revision 3, reps 12, Remove fails with `stale_revision_conflict`, 0 deadlocks).
  - Race 2B: Remove vs Log/Update, Remove wins (revision 3, set deleted, Log fails with `stale_revision_conflict`, 0 deadlocks).
  - Race 3: Concurrent Identical Start Replay (Actor B blocks on advisory lock until Actor A commits, resumes idempotently returning existing session, exactly 1 session persisted, active, revision 1).
  - Race 4: Concurrent Conflicting Start Replay (Actor B blocks on advisory lock, resumes and is rejected with `duplicate_session_conflict` `23505`).
  - Race 5: Concurrent Cross-User Start (Actor B blocks on advisory lock, resumes and is rejected with `session_ownership_mismatch` `42501`).
  - Race 6: Concurrent Idempotent Set Retry vs In-Place Set Update (Actor A runs idempotent retry without revision bump, Actor B blocks on parent lock, unblocks and commits in-place update advancing revision to 3).
- `git diff --check` passes with zero errors.
**Current blocker:** None (Awaiting CI run and independent review on updated HEAD).
**Resolved review finding IDs:**
- `4490473095` (P1): Cross-user performed-set upsert / spoofing in `rpc_log_workout_performed_set` fixed by pre-selecting with `FOR UPDATE` to verify owner/session match, scoping `ON CONFLICT (id) DO UPDATE WHERE user_id = v_user_id AND session_id = p_session_id`, and asserting `returning id`. Tested in assertions 24-26.
- `4490473103` (P2): SQL three-valued logic bypass on `{}` in `private.is_valid_workout_session_snapshot_v1` fixed using `?` key checks and `is distinct from`. Tested in assertions 5-8.
- `4490473109` (P2): NULL / non-positive `p_expected_revision` bypassing OCC fixed across all 6 mutation RPCs by asserting `p_expected_revision is not null and p_expected_revision > 0` (`22023 invalid_expected_revision`). Tested in assertions 28-34, 73, 75.
- `4490473113` (P2): Prescription integrity cross-validated in `rpc_start_workout_session` against `user_workout_routine_sets`. Tested in assertions 11-12.
- `4490473120` (P2): Start replay recovery fixed in `rpc_start_workout_session` by pre-checking existing session ID and returning existing record on exact match before checking routine data. Tested in assertions 16-18, 51, 58.
- `4491035089` (P2): Inconsistent lock hierarchy between `rpc_log_workout_performed_set` and `rpc_remove_workout_performed_set` resolved by locking parent session `user_workout_sessions` first, then child set `user_workout_performed_sets` second in all RPCs. Verified via `w7b_session_concurrency.sh` with simultaneous Log vs Remove races (Update wins and Remove wins). Zero `40P01` deadlocks observed.
- `4491456710` (P2): Fail CI on pgTAP assertion failures resolved by introducing `supabase/tests/database/run_pgtap.sh`, using `psql --tuples-only --no-align` with `set -euo pipefail`, regex scanning for `# Looks like you (failed|planned)` and `^(not ok|.*not ok)`, and validating that passed assertion count matches planned count.
- `4491456719` (P2): Concurrent Start idempotency resolved by acquiring transaction-scoped advisory lock `pg_advisory_xact_lock(hashtext('workout_session_start'), hashtext(p_session_id::text))` before `SELECT ... FOR UPDATE`, adding `ON CONFLICT (id) DO NOTHING` on session insert, and handling conflict fallback with parameter equivalence check (`duplicate_session_conflict` `23505`) and cross-user ownership verification (`session_ownership_mismatch` `42501`). Tested in Races 3, 4, 5 of `w7b_session_concurrency.sh`.
- `4492021721` (P2): Routine name integrity in `rpc_start_workout_session` resolved by reading authoritative name from `user_workout_routines` under `FOR SHARE` lock, verifying `p_routine_snapshot->>'routine_name' is not distinct from v_routine_name` (`snapshot_routine_name_mismatch` `22023`), while preserving existing session start replay even after source routine rename or deletion. Tested in assertions 13-14, 51, 58.
- `4492021727` (P2): Terminal replay identity resolved in `rpc_complete_workout_session` (comparing normalized `nullif(btrim(p_notes), '')`) and `rpc_discard_workout_session` (comparing normalized `btrim(p_discard_reason)`), returning existing terminal session on exact match and raising `terminal_payload_conflict` (`23505`) on conflicting notes/reason. Tested in assertions 41-44, 46-48, 55-57.
- `im-tio` thread `PRRT_kwDOTOXwB860kRDo` (P2): Disposable connection guard bypass in `w7b_session_concurrency.sh` resolved by strictly enforcing the exact loopback disposable URL in both CI and local modes (`database_url="$expected_url"`), refusing any non-loopback/alternative `DATABASE_URL`, rejecting all libpq `PG*` connection overrides except `PGPASSWORD`, making local execution opt-in via `--local`, and adding `w7b_session_concurrency_guard.test.sh` to CI pipeline.
- `im-tio` thread `PRRT_kwDOTOXwB860qdai` / #4496780930 (P2): Credential disclosure in concurrency harness rejection message resolved by removing `${DATABASE_URL}` and `$arg` interpolations from error output, returning constant generic refusal messages (`Refusing W7B-1 concurrency race with non-disposable or alternative DATABASE_URL` and `Unsupported W7B-1 concurrency race harness argument`), and verifying in `w7b_session_concurrency_guard.test.sh` that synthetic sentinel passwords and full connection strings never appear in stdout or stderr.
- `im-tio` thread `PRRT_kwDOTOXwB8600dBy` / #4501071121 (P2): 100-character snapshot name limit incompatibility resolved by removing artificial 100-character caps from `routine_name` and `display_name` in `private.is_valid_workout_session_snapshot_v1`, keeping nonblank checks, key whitelists, canonical exercise ref regex, and 256 KiB ceiling. Authoritative stored names in `user_workout_routines.name` and `user_workout_exercises.display_name` exceeding 100 characters can now start workout sessions cleanly without error. Tested in assertions 64-66, 78-80.
- `im-tio` P3 findings (`#4499918985`, `#4499919004`, `#4499918994`, `#4499918991`, `#4499918998`, `#4499919000`):
  * `#4499918985`: `is_valid_workout_session_snapshot_v1` marked `STABLE`, `SET search_path = ''`, strict timestamp regex, canonical catalog regex.
  * `#4499919004` / `#4499918994`: RLS policies updated to `using (user_id = (select auth.uid()))` for InitPlan evaluation.
  * `#4499918991`: `rpc_start_workout_session` NULL-safe composition check (`if v_snap_ex is null`), safe UUID regex check before casting `exercise_ref::uuid`, `FOR SHARE` on composition child queries.
  * `#4499918998`: Explicit parameter NULL checks throwing `22023` for all required RPC arguments; permissive start timestamp plausibility window (`2020-01-01` to `now() + interval '1 day'`) for offline sync safety.
  * `#4499919000`: Ephemeral review thread IDs removed from SQL comments, replaced with invariant descriptions.
**Next exact action:** Commit and push HEAD checkpoint to PR #734, reply to remaining review threads, re-request review from `im-tio`, and monitor CI qualification.

## 1. Discovery

### User Outcome
Provide durable, multi-tenant secure, terminal-immutable PostgreSQL persistence for active and completed workout sessions and performed sets, adhering to W7A domain contracts and ADR-0011/ADR-0015.

### Success Criteria
1. Exact two-table schema with composite FK `(session_id, user_id)` on child sets.
2. Single active/paused session enforced by partial unique index `(user_id) WHERE (status IN ('active', 'paused'))`.
3. 7 `SECURITY DEFINER` RPCs with `search_path = ''` and parent row locking `FOR UPDATE`.
4. Consistent parent -> child lock hierarchy preventing PostgreSQL `40P01` deadlock.
5. Snapshot cross-validation in `rpc_start_workout_session` matching database routine composition and prescribed sets.
6. Deterministic snapshot validator `private.is_valid_workout_session_snapshot_v1` rejecting empty JSONB and missing required keys.
7. Account deletion cascade works cleanly without trigger blockage.
8. 100% passing pgTAP security tests (82 tests) on local disposable Supabase database.
9. Concurrency regression harness (6 races) for Finish vs Log Set, Log/Update vs Remove, and Idempotent Retry vs Update races.
10. CI integration into `.github/workflows/supabase-db-ci.yml`.
