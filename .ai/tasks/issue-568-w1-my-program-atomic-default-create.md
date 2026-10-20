# GitHub #568 — W1 My Program Identity and Atomic First Routine Create

**Status:** Source merged 2026-10-19; hosted preflight pending; production Move OFF (2026-10-20 read)
**Primary owner:** W1 / Supabase-Postgres
**Affected platforms:** Supabase Database, CI

## Owner Approval and Scope Boundary

**Trigger:** Supabase table/column shape change
**Approval status:** Approved
**Approval evidence:** GitHub PR #619 owner "Go" on 2026-10-19 approving exact column/index shape: `user_workout_programs.is_default boolean NOT NULL DEFAULT false` + partial unique index `UNIQUE(user_id) WHERE is_default`, with same-migration privilege narrowing to `INSERT(id, user_id, name)` only, and dormant server-authoritative first-Routine composer RPC delegating to existing `create_user_workout_routine_with_composition`.
**Approved product/UI/data-shape boundaries:**
- Add `is_default boolean NOT NULL DEFAULT false` to `public.user_workout_programs`.
- Create partial unique index `idx_user_workout_programs_owner_default` on `public.user_workout_programs (user_id) WHERE is_default`.
- Revoke table-level `INSERT` on `public.user_workout_programs` from `authenticated`.
- Grant column-level `INSERT (id, user_id, name)` on `public.user_workout_programs` to `authenticated` (server generates/defaults timestamps and protects `is_default`).
- Create `public.create_user_workout_routine_in_my_program(uuid, text, uuid, jsonb)` returning `jsonb` (`program_id`, `composition_revision`), `SECURITY DEFINER`, `search_path = ''`.
- Revoke all `EXECUTE` on the new function from `public`, `anon`, `authenticated`, `service_role` (dormant until later release gate).
**Explicit non-changes:**
- No hosted Supabase DDL execution or deployment.
- No client `EXECUTE` grant on `create_user_workout_routine_in_my_program`.
- No activation of Move Routine (#569) or deletion (#567).
- No Flutter UI changes, repository integration, or real Undo.
- No fabricated quotas (#554).
- Preserve unrelated dirty files in original checkout (`apps/features/nutrition/pubspec.lock`, Wear `GeneratedPluginRegistrant.java`).

## Active Handoff

**Planning owner:** W1 identity/security architecture
**Implementation owner:** W1 Supabase / Postgres
**Review owner:** Independent security and concurrency review
**Implementation ownership state:** Active
**Ownership transition:** Not applicable
**Repository state last verified:** `main@3d75d1b1224519d8a2a49c6528b1b4641fe5ebf0`
**Branch:** `tnyx/issue-568-w1-my-program-atomic-default-create`
**HEAD SHA:** In progress
**Observed working-tree state:** Clean separate worktree at `G:\projects\Tio-World-w1`
**Observed uncommitted/dirty files:** Preserved in primary worktree
**PR / tracker:** GitHub #568, #569, PR #619; Linear TNYX-78, TNYX-81
**Current implementation state:** Migration `20261019162535_w1_my_program_atomic_default_create.sql` created via official Windows CLI v2.121.0. Column-level narrowing and dormant RPC implemented. Tests and CI wired.
**Relevant execution surface:** `supabase/migrations/`, `supabase/tests/database/`, `.github/workflows/supabase-db-ci.yml`
**Validation completed at SHA:** Pending exact-head CI run
**Validation remaining:** GitHub Actions Supabase Database CI and commit attribution run
**Current blocker:** None
**Open review finding IDs:** None
**Next exact action:** Run review, commit changes, push branch, open PR, and verify required checks.

## 1. Discovery

### User Outcome
A first-time user entering the direct Library "Create Routine" flow without an existing Program has their Routine saved under a canonical, lazily-established default Program named "My Program" (`is_default = true`). Failed or cancelled composition rolls back cleanly with no empty default Program left behind. The default Program cannot be deleted, cannot be spoofed by client-side direct writes, and retains its default identity even if renamed.

### Success Criteria
1. At most one default Program (`is_default = true`) per authenticated user in Postgres.
2. Malicious client attempts to insert or update `is_default` fail with permission denied (`42501`).
3. Legacy client inserts (`id, user_id, name`) and renames (`name`) remain fully operational with timestamps and `is_default` server-managed.
4. Calling `create_user_workout_routine_in_my_program` resolves an existing default or lazily creates "My Program", delegating to the existing atomic composition writer in one transaction.
5. Incomplete/invalid composition rolls back the entire transaction, leaving zero empty Programs.
6. Concurrent first-time creates serialize cleanly via `FOR NO KEY UPDATE` on the user account row without deadlocks.
7. RPC starts completely dormant with `EXECUTE` revoked.

### Scope
- Migration `20261019162535_w1_my_program_atomic_default_create.sql`.
- Update `supabase/tests/database/tnyx_78_user_workout_program_privileges.test.sql`.
- Add `supabase/tests/database/tnyx_568_w1_my_program_atomic_default_create.test.sql`.
- Add `supabase/tests/database/tnyx_568_w1_my_program_atomic_default_create_concurrency.sh`.
- Wire CI steps into `.github/workflows/supabase-db-ci.yml`.

### Non-Goals
- No Flutter UI or client repository changes.
- No live database push.
- No client RPC permissions.

## 2. Codebase Exploration

### Verified Evidence
- `public.user_workout_programs` previously had table-wide `INSERT` granted to `authenticated` in `20260929040034_create_user_workout_programs.sql`.
- `create_user_workout_routine_with_composition` in `20261013080000_create_user_workout_routine_with_composition.sql` provides the canonical composition writer with comprehensive validation, custom exercise active check, and revision CAS.
- Serializing absent-default creation via `FOR NO KEY UPDATE` on `public.users` self-conflicts across concurrent sessions for the same user while remaining compatible with `FOR KEY SHARE` used by foreign key validation and account deletion checks.

## 3. Clarification

### Decisions Made

| Decision | Status | Rationale | Owner |
|---|---|---|---|
| Lazy default Program user behavior | Approved | Preserves empty Library for new users | Owner |
| `is_default boolean NOT NULL DEFAULT false` + partial index | Approved | Enforces single default per user at database level | Owner |
| Authenticated INSERT column narrowing | Approved | Prevents client spoofing of `is_default` marker | Owner |
| `FOR NO KEY UPDATE` on `public.users` | Approved | Serializes concurrent first creates without FK deadlock | Owner / Codex P2 |
| Dormant RPC with revoked EXECUTE | Approved | Staged rollout; client grant only after client integration | Owner |

## 4. Architecture Design

### Chosen Approach
1. Add `is_default` column and partial unique index on `(user_id) WHERE is_default`.
2. Revoke table-wide `INSERT` from `authenticated`, grant `INSERT (id, user_id, name)`.
3. Server-authoritative RPC `create_user_workout_routine_in_my_program` checks authentication, serializes on `users` with `FOR NO KEY UPDATE`, looks up default Program `FOR KEY SHARE`, lazily inserts default Program if missing, and delegates to `create_user_workout_routine_with_composition`.

## 5. Implementation Plan
- [x] Create clean worktree `G:\projects\Tio-World-w1` on branch `tnyx/issue-568-w1-my-program-atomic-default-create`.
- [x] Generate migration with official Supabase CLI v2.121.0 (`20261019162535_w1_my_program_atomic_default_create.sql`).
- [x] Implement schema addition, index, ACL narrowing, and dormant RPC.
- [x] Update `tnyx_78_user_workout_program_privileges.test.sql`.
- [x] Write SQL test matrix `tnyx_568_w1_my_program_atomic_default_create.test.sql`.
- [x] Write two-session concurrency script `tnyx_568_w1_my_program_atomic_default_create_concurrency.sh`.
- [x] Wire tests in `.github/workflows/supabase-db-ci.yml`.
- [x] Perform review and commit changes.
- [x] Push and open PR #620.
- [x] Fix P2-A (tnyx_569 stale test assertion).
- [x] Fix P2-B (psql variable substitution in dollar quotes).
- [x] Fix P2-C (Routine composition payload format: entry/set UUIDs and ex_* reference).

## 6. Quality Review

### Validation Run
- Commit attribution guard: PASS.
- Supabase Database CI: validating exact-head CI run for PR #620.

### Review Findings and Resolution
- P1 Table INSERT hazard: Addressed by narrowing authenticated INSERT in the same migration.
- P2 Concurrency serialization: Addressed by using `FOR NO KEY UPDATE` on `public.users`.
- P2 Server-managed timestamps: Addressed by omitting `created_at` and `updated_at` from client INSERT grant.
- P2-A Stale #569 Move test assertions: Fixed `tnyx_569_atomic_create_program_move.test.sql` lines 43-51 to assert 6 columns (including `is_default`) and column-level `(id, user_id, name)` INSERT instead of revoked table-wide INSERT.
- P2-B Test psql variable substitution in dollar quotes: Fixed `tnyx_568_w1_my_program_atomic_default_create.test.sql` by defining `pg_temp.valid_exercises()` so dynamic SQL evaluation executes valid JSON without psql variable substitution failure. Inlined JSON in concurrency script.
- P2-C Routine composition test payload structure: `save_user_workout_routine_composition` requires explicit client-generated UUID `id` on each exercise entry and each set, catalog exercises formatted as `ex_*`, and unique IDs per routine/set. Addressed by parametrizing `pg_temp.valid_exercises(p_entry_id, p_set_id)` with default UUIDs, passing distinct UUIDs for secondary routine creates, and updating concurrency script with valid payloads.

## 7. Final Handoff

### Changed Files
- `supabase/migrations/20261019162535_w1_my_program_atomic_default_create.sql`
- `supabase/tests/database/tnyx_78_user_workout_program_privileges.test.sql`
- `supabase/tests/database/tnyx_568_w1_my_program_atomic_default_create.test.sql`
- `supabase/tests/database/tnyx_568_w1_my_program_atomic_default_create_concurrency.sh`
- `supabase/tests/database/tnyx_569_atomic_create_program_move.test.sql`
- `.github/workflows/supabase-db-ci.yml`
- `.ai/tasks/issue-568-w1-my-program-atomic-default-create.md`
- `.ai/tasks/README.md`


## Post-merge source and hosted preflight (2026-10-20)

**Fresh base:** protected `main@6810ce2f199db61022cfc12590b67e3022ea81e0`, read via GitHub; this docs-only reconciliation is not a new schema/Flutter slice.
**Source evidence:** [PR #620](https://github.com/im-tnyx/tio-world/pull/620) merged on 2026-10-19 as `4d7e7986fb93b0aae14c38f2b9c236585eac61bf`. Exact PR source HEAD `f5b77383b51eec24f874d70a6ad171a7cdf1bd2e`: [Supabase Database CI #39292962703](https://github.com/im-tnyx/tio-world/actions/runs/39292962703) completed SUCCESS. GitHub reports zero formal review submissions and zero inline review threads for PR #620; do not infer independent GitHub approval from CI or older chat audits.
**Current repository/hosted delta:** `main` has 66 SQL migrations; connected Tio-tnyx hosted Postgres has 65 applied through `20261018100000`. Source-only `20261019162535_w1_my_program_atomic_default_create.sql` remains NOT applied. Live `public.user_workout_programs.is_default` is absent and `public.create_user_workout_routine_in_my_program` is absent. Live existing Move and atomic Create & Move RPCs exist as `SECURITY DEFINER`, but `anon`, `authenticated`, and `service_role` have `EXECUTE=false` on both. Read-only verification; no mutation, grant, flag change, or client rollout.
**Truth reconciliation:** The earlier "Implementation Plan", "Active Handoff", and "Quality Review" entries above refer to the historical implementation PR before merge. The dated post-merge record here wins for merge/deployment state. GitHub #568 and #569 stay OPEN; Linear TNYX-78 remains In Progress and TNYX-81 Backlog (blocked by TNYX-78 and TNYX-80).

### Next safe gate, still not a deployment authorization

1. Owner's Windows checkout: read-only `git status -sb`, `git fetch origin --prune`, `git rev-parse origin/main`, official CLI `--version` / `db push --help`, `migration list --linked`, and **only if its help supports it** `db push --dry-run --linked`. Verify linked project ref `oykupyiitspujzpwwvuj` without sharing tokens/credentials. Do not reset, checkout over dirty worktrees, run live SQL fixtures, or issue `db push` without `--dry-run`.
2. Independently review the exact source-only #568 migration for legacy `INSERT(id,user_id,name)` compatibility, row/column ACLs, `SECURITY DEFINER` auth ownership, `is_default` uniqueness, first-Create rollback, two-device races, old app clients, and account-delete lock-order safety. Correlate with the successful disposable CI and existing security/performance advisories, which are not all fixed by this slice.
3. Separately authorize any hosted migration apply **only after** clean preflight and owner deployment approval. Verify ledger, column/index/default constraint, disabled new RPC grant, preserved Program operations, and post-apply advisors. Even a successful dormant #568 deployment must **not** enable `#569` Move or real five-second Undo.
4. Move release remains an independent future review gate for two Move RPC `EXECUTE` grants, Flutter release-provider change, physical Android/iOS end-to-end writes, and Undo contract. Keep `routineMoveReleaseEnabledProvider` false until these independent gates pass.

**Scope of this reconciliation:** update the existing task brief and task-index row only. No schema source or migrations changed, no hosted deploy, no `EXECUTE`, no issue completion, no new design, and no claim of local Windows verification.
