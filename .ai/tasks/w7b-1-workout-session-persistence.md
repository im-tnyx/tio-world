# Feature Task: W7B-1 Workout Session Persistence (Supabase Source-Only)

**Status:** In review / Final Remediation complete
**Primary owner:** Antigravity
**Affected platforms:** Supabase (PostgreSQL Backend), GitHub CI

## Owner Approval and Scope Boundary

**Trigger:** Supabase table/column shape change & CI workflow integration
**Approval status:** Approved
**Approval evidence:** User prompt explicit instructions:
1. "GO — Tio-World W7B-1 Snapshot Contract Approval: मैं W7B-1 के पहले से निर्धारित two-table, source-only scope के भीतर rpc_start_workout_session में p_routine_snapshot jsonb जोड़ने की अनुमति देता हूँ।"
2. "Owner scope direction: I authorize the following narrowly scoped work for PR #734: 1. Fix the new independent-review P2 concurrency finding. 2. Add the W7B-1 security pgTAP and concurrency test steps to the existing .github/workflows/supabase-db-ci.yml. 3. Update the existing W7B-1 handoff and applicable Linear tracking to reflect verified status."
**Approved product/UI/data-shape boundaries:**
- Two owner-scoped tables: `public.user_workout_sessions` and `public.user_workout_performed_sets`.
- Partial unique index enforcing single active or paused session per user.
- 7 mutation RPCs (`rpc_start_workout_session`, `rpc_pause_workout_session`, `rpc_resume_workout_session`, `rpc_log_workout_performed_set`, `rpc_remove_workout_performed_set`, `rpc_complete_workout_session`, `rpc_discard_workout_session`).
- Consistent parent session (`user_workout_sessions`) -> child set (`user_workout_performed_sets`) lock hierarchy across all RPCs preventing `40P01` deadlocks.
- `rpc_start_workout_session` accepts client-supplied `p_routine_snapshot jsonb` with server-side structural, ownership, composition, and prescribed sets cross-validation.
- Direct authenticated table DML denied; authenticated owner-only SELECT via RLS.
- Terminal session immutability and legitimate account deletion cascade safety.
- Microsecond pause duration fidelity with Dart `Duration.inMicroseconds`.
- Zero speculative constraints: `chk_user_workout_performed_sets_payload` dropped, speculative notes caps dropped.
- CI integration of W7B-1 pgTAP suite and concurrency regression harness into `.github/workflows/supabase-db-ci.yml`.

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
**Repository state last verified:** 2026-11-06 15:30 UTC+05:30
**Branch:** `feat/w7b-1-workout-session-persistence`
**PR:** https://github.com/im-tnyx/tio-world/pull/734
**PR Previous HEAD SHA:** `3a0b45c28a388cd50058d513bcd3a6e9cd7f72c0`
**Observed working-tree state:** Changes ready for commit
**Observed modified files:**
- `supabase/migrations/20261106073920_user_workout_sessions.sql`
- `supabase/tests/database/w7b_session_security.test.sql`
- `supabase/tests/database/w7b_session_concurrency.sh`
- `.github/workflows/supabase-db-ci.yml`
- `.ai/tasks/w7b-1-workout-session-persistence.md`
**PR / tracker:** Linear TNYX-84 (W7 Active Workout) - Restored to **In Progress**
**Current implementation state:** Remediation of all 6 review findings complete; local pgTAP suite (46 tests) passing 100%; dual concurrency harness passing 100%; CI workflow integration complete.
**Relevant execution surface:** `supabase/migrations/`, `supabase/tests/database/`, `.github/workflows/`
**Validation completed:**
- All 82 migrations applied cleanly via `--single-transaction`.
- 46/46 pgTAP assertions pass in `supabase/tests/database/w7b_session_security.test.sql` with exit 0.
- `supabase db lint --local --schema public,private --level error` produces 0 issues.
- `supabase/tests/database/w7b_session_concurrency.sh --guard-only` passes with exit 0.
- `supabase/tests/database/w7b_session_concurrency.sh` (Finish vs Log Set, Update vs Remove, Remove vs Update) passes with exit 0 and zero 40P01 deadlocks.
- `tnyx_78_user_workout_routines.test.sql` and `tnyx_568_w1_my_program_atomic_default_create.test.sql` pass with exit 0.
- `git diff --check` passes with zero errors.
**Current blocker:** None (Awaiting independent review on updated HEAD).
**Resolved review finding IDs:**
- `4490473095` (P1): Cross-user performed-set upsert / spoofing in `rpc_log_workout_performed_set` fixed by pre-selecting with `FOR UPDATE` to verify owner/session match, scoping `ON CONFLICT (id) DO UPDATE WHERE user_id = v_user_id AND session_id = p_session_id`, and asserting `returning id`. Tested in assertions 22-24.
- `4490473103` (P2): SQL three-valued logic bypass on `{}` in `private.is_valid_workout_session_snapshot_v1` fixed using `?` key checks and `is distinct from`. Tested in assertions 5-8.
- `4490473109` (P2): NULL / non-positive `p_expected_revision` bypassing OCC fixed across all 6 mutation RPCs by asserting `p_expected_revision is not null and p_expected_revision > 0` (`22023 invalid_expected_revision`). Tested in assertions 26-32.
- `4490473113` (P2): Prescription integrity cross-validated in `rpc_start_workout_session` against `user_workout_routine_sets`. Tested in assertions 11-12.
- `4490473120` (P2): Start replay recovery fixed in `rpc_start_workout_session` by pre-checking existing session ID and returning existing record on exact match before checking routine data. Tested in assertions 14-16, 44.
- `4491035089` (P2): Inconsistent lock hierarchy between `rpc_log_workout_performed_set` and `rpc_remove_workout_performed_set` resolved by locking parent session `user_workout_sessions` first, then child set `user_workout_performed_sets` second in all RPCs. Verified via `w7b_session_concurrency.sh` with simultaneous Log vs Remove races (Update wins and Remove wins). Zero `40P01` deadlocks observed.
**Next exact action:** Commit and push remediations to PR #734, reply to review thread `4491035089`, and request re-review from `im-tio`.

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
