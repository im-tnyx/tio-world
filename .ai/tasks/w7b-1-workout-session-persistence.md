# Feature Task: W7B-1 Workout Session Persistence (Supabase Source-Only)

**Status:** In progress
**Primary owner:** Antigravity
**Affected platforms:** Supabase (PostgreSQL Backend)

## Owner Approval and Scope Boundary

**Trigger:** Supabase table/column shape change
**Approval status:** Approved
**Approval evidence:** User prompt explicit instruction: "GO — Tio-World W7B-1 Snapshot Contract Approval: मैं W7B-1 के पहले से निर्धारित two-table, source-only scope के भीतर rpc_start_workout_session में p_routine_snapshot jsonb जोड़ने की अनुमति देता हूँ।"
**Approved product/UI/data-shape boundaries:**
- Two owner-scoped tables: `public.user_workout_sessions` and `public.user_workout_performed_sets`.
- Partial unique index enforcing single active or paused session per user.
- 7 mutation RPCs (`rpc_start_workout_session`, `rpc_pause_workout_session`, `rpc_resume_workout_session`, `rpc_log_workout_performed_set`, `rpc_remove_workout_performed_set`, `rpc_complete_workout_session`, `rpc_discard_workout_session`).
- `rpc_start_workout_session` accepts client-supplied `p_routine_snapshot jsonb` with server-side structural, ownership and composition cross-validation.
- Direct authenticated table DML denied; authenticated owner-only SELECT via RLS.
- Terminal session immutability and legitimate account deletion cascade safety.
- Microsecond pause duration fidelity with Dart `Duration.inMicroseconds`.
- Zero speculative constraints: `chk_user_workout_performed_sets_payload` dropped, speculative notes caps dropped.

**Explicit non-changes:**
- No hosted Supabase migrations or writes.
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
**Repository state last verified:** 2026-11-06 13:10 UTC+05:30
**Branch:** `feat/w7b-1-workout-session-persistence`
**HEAD SHA:** `9fdc31950bd642cec1ec48c2fc95f6e581468203`
**Observed working-tree state:** Clean (apart from new migration and task brief)
**Observed uncommitted/dirty files:** `supabase/migrations/20261106073920_user_workout_sessions.sql`, `.ai/tasks/w7b-1-workout-session-persistence.md`
**PR / tracker:** Linear TNYX-84 (W7 Active Workout)
**Current implementation state:** Writing migration SQL and pgTAP test suite.
**Relevant execution surface:** `supabase/migrations/`, `supabase/tests/database/`
**Validation completed at SHA:** Pending migration apply and pgTAP execution on local stack.
**Validation remaining:** Local pgTAP security suite, dual-session concurrency test, `git diff --check`.
**Current blocker:** None (owner approval received).
**Open review finding IDs:** None.
**Next exact action:** Author `supabase/migrations/20261106073920_user_workout_sessions.sql` and `supabase/tests/database/w7b_session_security.test.sql`.

## 1. Discovery

### User Outcome
Provide durable, multi-tenant secure, terminal-immutable PostgreSQL persistence for active and completed workout sessions and performed sets, adhering to W7A domain contracts and ADR-0011/ADR-0015.

### Success Criteria
1. Exact two-table schema with composite FK `(session_id, user_id)` on child sets.
2. Single active/paused session enforced by partial unique index `(user_id) WHERE (status IN ('active', 'paused'))`.
3. 7 `SECURITY DEFINER` RPCs with `search_path = ''` and parent row locking `FOR UPDATE`.
4. Snapshot cross-validation in `rpc_start_workout_session` matching database routine composition.
5. Deterministic snapshot validator `private.is_valid_workout_session_snapshot_v1`.
6. Account deletion cascade works cleanly without trigger blockage.
7. 100% passing pgTAP security tests on local disposable Supabase database.
