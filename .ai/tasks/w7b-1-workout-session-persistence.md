# Feature Task: W7B-1 Workout Session Persistence (Supabase Source-Only)

**Status:** In review / Final P2 Closure complete
**Primary owner:** Antigravity
**Affected platforms:** Supabase (PostgreSQL Backend), GitHub CI

## Owner Approval and Scope Boundary

**Trigger:** Supabase table/column shape change & CI workflow integration
**Approval status:** Approved
**Approval evidence:** User prompt explicit instructions:
1. "GO — Tio-World W7B-1 Snapshot Contract Approval: मैं W7B-1 के पहले से निर्धारित two-table, source-only scope के भीतर rpc_start_workout_session में p_routine_snapshot jsonb जोड़ने की अनुमति देता हूँ।"
2. "Owner scope direction: I authorize the following narrowly scoped work for PR #734: 1. Fix the new independent-review P2 concurrency finding. 2. Add the W7B-1 security pgTAP and concurrency test steps to the existing .github/workflows/supabase-db-ci.yml. 3. Update the existing W7B-1 handoff and applicable Linear tracking to reflect verified status."
3. "PR #734 Final P2 Closure & Merge Readiness: 1. Fix P2 #4491456710 — Fail CI on pgTAP assertion failures. 2. Fix P2 #4491456719 — Concurrent Start idempotency in supabase/migrations/20261106073920_user_workout_sessions.sql."
**Approved product/UI/data-shape boundaries:**
- Two owner-scoped tables: `public.user_workout_sessions` and `public.user_workout_performed_sets`.
- Partial unique index enforcing single active or paused session per user.
- 7 mutation RPCs (`rpc_start_workout_session`, `rpc_pause_workout_session`, `rpc_resume_workout_session`, `rpc_log_workout_performed_set`, `rpc_remove_workout_performed_set`, `rpc_complete_workout_session`, `rpc_discard_workout_session`).
- Consistent parent session (`user_workout_sessions`) -> child set (`user_workout_performed_sets`) lock hierarchy across all RPCs preventing `40P01` deadlocks.
- `rpc_start_workout_session` accepts client-supplied `p_routine_snapshot jsonb` with server-side structural, ownership, composition, and prescribed sets cross-validation.
- Transaction-scoped advisory locking `pg_advisory_xact_lock(hashtext('workout_session_start'), hashtext(p_session_id::text))` plus `ON CONFLICT (id) DO NOTHING` and `SELECT ... FOR UPDATE` conflict recovery ensuring serial execution and idempotent start recovery across concurrent clients.
- Direct authenticated table DML denied; authenticated owner-only SELECT via RLS.
- Terminal session immutability and legitimate account deletion cascade safety.
- Microsecond pause duration fidelity with Dart `Duration.inMicroseconds`.
- Zero speculative constraints: `chk_user_workout_performed_sets_payload` dropped, speculative notes caps dropped.
- CI integration of W7B-1 pgTAP suite with TAP-aware runner (`supabase/tests/database/run_pgtap.sh`) and 5-race concurrency harness (`supabase/tests/database/w7b_session_concurrency.sh`) into `.github/workflows/supabase-db-ci.yml`.

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
**Repository state last verified:** 2026-11-06 16:45 UTC+05:30
**Branch:** `feat/w7b-1-workout-session-persistence`
**PR:** https://github.com/im-tnyx/tio-world/pull/734
**Observed working-tree state:** Changes ready for commit
**Observed modified files:**
- `supabase/migrations/20261106073920_user_workout_sessions.sql`
- `supabase/tests/database/run_pgtap.sh`
- `supabase/tests/database/w7b_session_concurrency.sh`
- `.github/workflows/supabase-db-ci.yml`
- `.ai/tasks/w7b-1-workout-session-persistence.md`
**PR / tracker:** Linear TNYX-84 (W7 Active Workout) - Restored to **In Progress**
**Current implementation state:** Remediation of all 8 review findings complete; local pgTAP suite (46 tests) passing 100% via `run_pgtap.sh`; 5-race concurrency harness passing 100%; CI workflow integration complete.
**Relevant execution surface:** `supabase/migrations/`, `supabase/tests/database/`, `.github/workflows/`
**Validation completed:**
- All migrations applied cleanly via `--single-transaction`.
- 46/46 pgTAP assertions pass in `supabase/tests/database/w7b_session_security.test.sql` with exit 0 via `run_pgtap.sh`.
- Negative TAP testing verified: assertion failure (`ok(false)`), plan mismatch, and fatal SQL syntax errors all exit with code 1.
- `supabase/tests/database/w7b_session_concurrency.sh --guard-only` passes with exit 0.
- `supabase/tests/database/w7b_session_concurrency.sh --local` passes with exit 0 across all 5 races:
  - Race 1: Finish vs Log Set (OCC rejection `stale_revision_conflict`, revision 2, 0 sets).
  - Race 2A: Log/Update vs Remove, Update wins (revision 3, reps 12, Remove fails with `stale_revision_conflict`, 0 deadlocks).
  - Race 2B: Remove vs Log/Update, Remove wins (revision 3, set deleted, Log fails with `stale_revision_conflict`, 0 deadlocks).
  - Race 3: Concurrent Identical Start Replay (Actor B blocks on advisory lock until Actor A commits, resumes idempotently returning existing session, exactly 1 session persisted, active, revision 1).
  - Race 4: Concurrent Conflicting Start Replay (Actor B blocks on advisory lock, resumes and is rejected with `duplicate_session_conflict` `23505`).
  - Race 5: Concurrent Cross-User Start (Actor B blocks on advisory lock, resumes and is rejected with `session_ownership_mismatch` `42501`).
- `git diff --check` passes with zero errors.
**Current blocker:** None (Awaiting independent review on updated HEAD).
**Resolved review finding IDs:**
- `4490473095` (P1): Cross-user performed-set upsert / spoofing in `rpc_log_workout_performed_set` fixed by pre-selecting with `FOR UPDATE` to verify owner/session match, scoping `ON CONFLICT (id) DO UPDATE WHERE user_id = v_user_id AND session_id = p_session_id`, and asserting `returning id`. Tested in assertions 22-24.
- `4490473103` (P2): SQL three-valued logic bypass on `{}` in `private.is_valid_workout_session_snapshot_v1` fixed using `?` key checks and `is distinct from`. Tested in assertions 5-8.
- `4490473109` (P2): NULL / non-positive `p_expected_revision` bypassing OCC fixed across all 6 mutation RPCs by asserting `p_expected_revision is not null and p_expected_revision > 0` (`22023 invalid_expected_revision`). Tested in assertions 26-32.
- `4490473113` (P2): Prescription integrity cross-validated in `rpc_start_workout_session` against `user_workout_routine_sets`. Tested in assertions 11-12.
- `4490473120` (P2): Start replay recovery fixed in `rpc_start_workout_session` by pre-checking existing session ID and returning existing record on exact match before checking routine data. Tested in assertions 14-16, 44.
- `4491035089` (P2): Inconsistent lock hierarchy between `rpc_log_workout_performed_set` and `rpc_remove_workout_performed_set` resolved by locking parent session `user_workout_sessions` first, then child set `user_workout_performed_sets` second in all RPCs. Verified via `w7b_session_concurrency.sh` with simultaneous Log vs Remove races (Update wins and Remove wins). Zero `40P01` deadlocks observed.
- `4491456710` (P2): Fail CI on pgTAP assertion failures resolved by introducing `supabase/tests/database/run_pgtap.sh`, using `psql --tuples-only --no-align` with `set -euo pipefail`, regex scanning for `# Looks like you (failed|planned)` and `^(not ok|.*\bnot ok\b)`, and validating that passed assertion count matches planned count.
- `4491456719` (P2): Concurrent Start idempotency resolved by acquiring transaction-scoped advisory lock `pg_advisory_xact_lock(hashtext('workout_session_start'), hashtext(p_session_id::text))` before `SELECT ... FOR UPDATE`, adding `ON CONFLICT (id) DO NOTHING` on session insert, and handling conflict fallback with parameter equivalence check (`duplicate_session_conflict` `23505`) and cross-user ownership verification (`session_ownership_mismatch` `42501`). Tested in Races 3, 4, 5 of `w7b_session_concurrency.sh`.
**Next exact action:** CI workflow run 42202562411 in progress for HEAD checkpoint `036e1013` (includes CI step replay of post-TNYX-81 migrations after staged notes harness reset). Awaiting independent review approval on PR #734.

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
8. 100% passing pgTAP security tests (46 tests) on local disposable Supabase database.
9. Two-session concurrency regression harness for Finish vs Log Set and Log/Update vs Remove races.
10. CI integration into `.github/workflows/supabase-db-ci.yml`.
