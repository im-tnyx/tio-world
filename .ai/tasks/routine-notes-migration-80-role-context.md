# Routine Notes migration 80 final role and ledger write

**Status:** In progress
**Parent:** [TNYX-81](https://linear.app/tnyx/issue/TNYX-81) remains the broader W4 Backlog epic. This slice does not change that status.
**Repository anchor:** `main@accb5ad49e74e3cc861a793df7d5c0edf21a84aa` (PR #727 merged)

## Owner Approval and Scope Boundary

**Trigger:** None. This is the next implementation correction inside the already approved migration 80 source slice.
**Approval status:** Approved
**Approval evidence:** Owner authorized source correction, disposable testing, and a focused PR for the CLI ledger `INSERT` failure. Hosted deployment, merge, and Notes activation remain unauthorized.
**Approved boundaries:** Final role statement in `20261031130000_routine_note_receipt_scheduled_cleanup.sql`, the linked-login regression, and this handoff.
**Explicit non-changes:** Hosted `db push`, migration repair, manual ledger `INSERT`, hosted role/grant/extension/job changes, migration 81, and Notes activation.

## Active Handoff

**Planning owner:** Repository owner
**Implementation owner:** Cursor agent (this session)
**Review owner:** Pending independent `im-tio` review
**Implementation ownership state:** Active
**Ownership transition:** Codex → Cursor agent (this session)
**Repository state last verified:** `main` and `origin/main` at `accb5ad49e74e3cc861a793df7d5c0edf21a84aa`; implementation branch `fix/tnyx81-migration80-ledger-write`; one worktree.
**Observed uncommitted/dirty files:** `.ai/tasks/routine-notes-production-deployment-approval.md` existed before this slice and stays unstaged. `git stash list` is empty.
**PR / tracker:** PR #727 merged. TNYX-81 Backlog. No concurrent implementation owner was modifying this slice.
**Current implementation state:** Final `reset role` replaced with `set role postgres` after disposable execution showed that statement restores the migration principal and lets the CLI-equivalent ledger insert commit.
**Relevant execution surface:** Supabase CLI 2.114.0 linked-login batch. `RESET ALL` does not clear `SET ROLE`. The final `RESET ROLE` does.
**Validation completed at SHA:** Pending this branch's commit.
**Validation remaining:** Disposable regression, relevant local SQL matrices, `git diff --check`, PR CI.
**Current blocker:** None for source review. Hosted migration 80 retry is still gated.
**Open review finding IDs:** None yet.
**Next exact action:** Finish disposable qualification, open the focused PR, and stop before merge.

## Scope and evidence

- PR #727 fixed the scheduler grant (`XX000`, no possible grantors) by restoring `postgres` before `GRANT ... WITH SET TRUE`. Hosted CLI 2.114.0 then reached the appended ledger insert and failed with `42501 permission denied for schema supabase_migrations`.
- CLI 2.114.0 source appends `INSERT INTO supabase_migrations.schema_migrations(version, name, statements) VALUES($1, $2, $3)` in the same transaction and does not re-assert the role. CLI 2.116.0 does, via the fix for supabase/cli#6236, so Database CI's 2.116.0 replay cannot reproduce this 2.114.0 failure.
- In scope: the final role statement, regression coverage of the ledger insert, and this handoff.
- Out of scope: hosted writes, migration 81, Notes activation, broad grants, and edits to the deployment packet.

## Diagnosis

The linked session user is `cli_login_postgres` (`NOINHERIT`, `SET` on `postgres` only). `RESET ALL` leaves `current_user = postgres`. The migration's final `RESET ROLE` returns `cli_login_postgres`, which lacks `USAGE` on `supabase_migrations` and `INSERT` on `schema_migrations`. `postgres` has both. Replacing that final statement with `SET ROLE postgres` succeeds while `current_user` is the scheduler role, because PostgreSQL authorizes `SET ROLE` for the session user. The earlier `reset role` before the second owner function remains; the next statement sets the owner role again.

## Validation

Disposable proof, not hosted execution:

- `bash supabase/tests/database/tnyx_81_cleanup_grant_context.sh` on isolated `postgres:17`: PASS. Original final `RESET ROLE` then the ledger insert returns SQLSTATE `42501` and rolls the marker, roles, and ledger row back. Corrected `SET ROLE postgres` commits the insert as `postgres` while `session_user` stays `cli_login_postgres`. A non-superuser grantor keeps `SET=true`, `INHERIT=false`, `ADMIN=false`.
- Actual `20261031130000` source on disposable `public.ecr.aws/supabase/postgres:17.11.0.006`, where `postgres` is not superuser: session `SET ROLE postgres` as `cli_login_postgres`, then the migration. The original final `reset role` reached both `cron.schedule` calls and failed the CLI 2.114.0 statement `INSERT INTO supabase_migrations.schema_migrations(version, name, statements) VALUES($1, $2, $3)` with `42501`. Disconnect rolled back the extension, roles, functions, policies, expiry index, and jobs. The corrected file then committed that insert with `current_user=postgres`. Both jobs are owned by `routine_note_receipt_cleanup_scheduler`. Cleanup roles stay nosuperuser, noinherit, and nobypassrls; the owner cannot log in. The explicit postgres membership is `SET=true`, `ADMIN=false`; this image also records `INHERIT=true` because `postgres` itself has `INHERIT`, plus a separate `supabase_admin` admin membership from role creation.
- CLI 2.114.0 `db push --db-url` to that disposable database, with startup `options=-c role=postgres`, applied even a final `reset role`. `RESET ROLE` restores a startup role GUC; it does not restore the login role. That invocation is not the hosted passwordless step-down and is not 42501 evidence. The hosted path's post-connect `SET ROLE` was reproduced with psql, above.
- Receipt cleanup, RLS, and retention SQL matrices were not run. The already-running local stack ledger ends at `20260817185654`, and the disposable migration-80 database does not contain the prior Notes schema. Replaying those matrices there, or onto the running stack, was not done. Database CI remains the full replay gate.
- `git diff --check`: recorded with the commit. Hosted advisor, hosted push, and migration 81 were not run.

## Handoff

Keep the hosted ledger at its observed 79-applied prefix. Do not retry migration 80, apply migration 81, or enable Notes until this correction is reviewed and the remaining deployment gates are approved separately. Migration 81 still needs its own owner approval.
