# W7 Trigger Search-Path Hardening

**Status:** PR #747 open; local validation complete; required branch checks pass; full Supabase Database CI is in progress; independent review pending
**Planning owner:** Codex
**Implementation owner:** Codex
**Previous agent:** Codex (W7 hosted deployment handoff)
**Review owner:** Independent `im-tio` reviewer

## 1. Discovery

Fix the verified Supabase `function_search_path_mutable` warning on `public.trg_fn_validate_workout_session_snapshot()` without changing its body, behavior, ownership, invoker mode, signature, trigger binding, or hosted database state.

**Scope:** One CLI-generated forward migration setting this function's `search_path` to empty; focused catalog regression assertions in the existing W7 database test; this handoff. No applied migration edits, grants, reset, hosted apply, or user-data access.

**Non-goals:** Save/device E2E, Flutter/UI, RLS redesign, broad RPC/grant cleanup, production launch, and merge/deployment.

## 2. Codebase Exploration

- Verified Git root: `G:\projects\Tio-World`.
- Starting current GitHub `main` and local `main`: `cec78bb4e383afe4fc13eb7833e3bfed5b159b48`; implementation branch created separately from it. PR #746 is an independent docs-only PR and is not this branch's parent.
- Hosted project reverified read-only: `tio-world`, ref `oykupyiitspujzpwwvuj`, region `ap-south-1`.
- Hosted catalog: function owner `postgres`; `prosecdef=false`; `proconfig=NULL`; attached to `public.user_workout_sessions` as `BEFORE INSERT`; `anon` and `authenticated` have EXECUTE through PUBLIC/default ACL.
- Hosted function body calls `private.is_valid_workout_session_snapshot_v1/v2` with schema-qualified names and has no unqualified table/function references. The advisor finding identifies an unset search path; current evidence does not demonstrate exploitability.
- Planned fix: `ALTER FUNCTION public.trg_fn_validate_workout_session_snapshot() SET search_path = '';`. Existing trigger-function ACLs are out of scope unless local evidence shows a necessary execution failure.
- Existing W7 suites cover valid Routine V1 starts, valid ad-hoc V2 Save, invalid snapshots, RLS/direct-DML denial, Save-only/idempotency, and concurrency. Focused regression assertions cover pinned search path, invoker mode, owner, and unchanged BEFORE INSERT binding.
- CLI-generated migration: `20261110185621_w7_trigger_snapshot_search_path_hardening.sql` (Supabase CLI `2.116.0`).

## 3. Decisions

| Decision | Status | Rationale |
|---|---|---|
| Use ALTER FUNCTION instead of replacing function body | Chosen | Preserves body, owner, invoker mode, signature, and dependent trigger while pinning resolution context. |
| Revoke PUBLIC/anon EXECUTE | Out of scope | Trigger function is bound to table trigger; no evidence currently supports a privilege change, and it is not needed to clear the search-path advisory. |
| Test environment | Required | Use a uniquely named disposable local Supabase stack; never reset the existing persistent local project or hosted database. |

## 4. Validation Evidence

- Supabase CLI `2.116.0` generated `20261110185621_w7_trigger_snapshot_search_path_hardening.sql`; migration contains only `ALTER FUNCTION ... SET search_path = ''`.
- Isolated local project `w7triggerhardening`, PostgreSQL `17.6`, host port `56540`; existing local project on port `54322` was not reset or used. All **85/85** checked-in migration versions replayed in lexical timestamp order, each with `psql --single-transaction`; local ledger parity **85/85**, latest `20261110185621`.
- The first disposable `db start` attempt with migration files present hit the repository's legacy `LOCK TABLE` migration (`20260824070233`, SQLSTATE `25P01`). The isolated DB was reinitialized with migrations moved out, following `.github/workflows/supabase-db-ci.yml`; the subsequent explicit replay passed.
- pgTAP: `w7b_session_security.test.sql` **115/115**; `w7c_workout_save_metadata.test.sql` **28/28**; `w7c_save_only_workout.test.sql` **46/46**. Coverage includes Routine snapshot V1 start, ad-hoc V2 Save, invalid snapshots, owner-scoped SELECT/direct DML denial, save/idempotency, empty function search path, invoker mode, owner, trigger binding, and rejection of direct SQL invocation as `anon` despite its existing EXECUTE ACL.
- `w7b_session_concurrency_guard.test.sh` passed with container-only `PGDATA` unset. All **6** `w7b_session_concurrency.sh --local` races passed against the disposable DB; the test container used a loopback-only internal forwarder so the unchanged harness's exact `127.0.0.1:54322` guard resolves to its own PostgreSQL listener.
- `supabase db advisors --local --type security --level warn --fail-on none`: **No issues found**. `supabase db lint --local --schema public,private --level error --fail-on none`: no results.
- Local function body MD5 matches the pre-change hosted catalog (`d821afcc0e166ad97962eec46a90e82d`); owner remains `postgres`, `prosecdef=false`, effective `search_path=""`, and the existing anon/authenticated ACL is unchanged. pgTAP confirms the existing trigger path still succeeds through W7 Save and Routine start.
- Local validation does **not** establish that hosted configuration changed. No hosted migration, reset, write, or deployment was performed; the hosted Advisor finding remains until a separately approved deployment.

## 5. Active Handoff

**Branch:** `codex/w7-trigger-search-path-hardening`
**Base:** `main@cec78bb4e383afe4fc13eb7833e3bfed5b159b48`
**Initial HEAD:** `cec78bb4e383afe4fc13eb7833e3bfed5b159b48`
**Last commit agent:** Codex
**Last implementation commit SHA:** `7fe002022e5314cc4b1f281a9e52d681145fab51`
**PR:** https://github.com/im-tnyx/tio-world/pull/747
**Working tree:** Clean after publishing the three scoped paths; `.tmp/` local test workspace is ignored
**Hosted changes:** None; deployment is explicitly excluded
**Linear:** TNYX-84 remains In Progress; broader W3/W4 and Workout acceptance gates remain open
**Review gate:** GitHub identifies `im-tio` as PR author and rejects requesting a review from the author. A distinct reviewer identity is required; no approval was submitted.
**Next exact action:** Complete exact-head Supabase Database CI and obtain review from an independent GitHub identity. Keep TNYX-84 In Progress. Stop before merge or hosted deployment.
