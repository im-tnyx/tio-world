# W7 Testing-Only Hosted Migration Deployment

**Status:** Hosted schema/RPC deployment complete; overall handoff is **PARTIAL / BLOCKED** pending W7 Security Advisor disposition and separate Workout acceptance gates.
**Deployment operator:** Codex, using the owner-authorized Supabase CLI session
**Target:** Supabase `tio-world`, ref `oykupyiitspujzpwwvuj`, region `ap-south-1`
**Source checkpoint:** PR #745 merge `b12b52ed0323c1ec4c9d3cff289dc110a523a146`, contained in current GitHub `main@cec78bb4e383afe4fc13eb7833e3bfed5b159b48`
**Linear:** [TNYX-84](https://linear.app/tnyx/issue/TNYX-84), retained `In Progress`

## Owner Approval and Scope Boundary

**Approval:** Owner explicitly authorized “Go W7 testing-only Supabase migration” on 2026-11-10, limited to applying the three reviewed W7 migrations to the verified project and read-only verification. Owner confirmed no real end users, approximately 4–5 disposable testing accounts, and no predeployment backup requirement for this bounded testing rollout.

**Explicit non-changes:** No reset, restore, deletion, Edge Function/config update, extra schema/RPC/RLS/grant migration, authenticated workout write, synthetic Save test, device acceptance, release activation, Workout History work, or production launch. The backup deferral does not change production recovery requirements.

## Source, Project, and Migration Plan

- Git root: `G:\projects\Tio-World`; clean `main` at `cec78bb4e383afe4fc13eb7833e3bfed5b159b48` before the docs-only handoff branch.
- PR #745 is merged at `b12b52ed0323c1ec4c9d3cff289dc110a523a146`; current GitHub `main` is `cec78bb4e383afe4fc13eb7833e3bfed5b159b48`.
- The three local migration files match the merged source checkpoint. Inspected timezone remediation: `timestamptz` writes use `now()`, Start lower bound is explicit UTC, and future allowance is 24 elapsed hours.
- Verified project identity immediately before rollout: `tio-world`, ref `oykupyiitspujzpwwvuj`, `ACTIVE_HEALTHY`, PostgreSQL 17.6.1.155.
- Initial expected ledger in owner prompt: 81 through `20261031142025`. On continuation, live ledger showed 83 through `20261109121800`, with W7B and W7C metadata installed. The earlier chat may have applied those first two; its operator/result is not available in this chat. Read-only catalog matched their expected objects, so no migration was replayed.
- Repository-pinned Supabase CLI: `2.116.0` (`.github/workflows/supabase-db-ci.yml`). Exact-target `db push --dry-run --project-ref oykupyiitspujzpwwvuj --skip-vault` returned only `20261110044130_w7c_save_only_workout.sql`; `roles=[]`, `seeds=[]`.

## Migration Results

| Version | Migration | Result |
|---|---|---|
| `20261106073920` | `user_workout_sessions` | Present in hosted ledger before this continuation; expected tables, RLS, indexes, constraints, triggers, and lifecycle RPCs verified. |
| `20261109121800` | `w7c_workout_save_metadata` | Present in hosted ledger before this continuation; metadata columns/constraints and completion V2 verified. |
| `20261110044130` | `w7c_save_only_workout` | Applied successfully with CLI `2.116.0`; CLI output confirmed exactly this file and no roles/seeds. |

Postdeployment ledger: **84 migrations**, latest `20261110044130`; all three W7 versions/names appear in order. The repository contains 84 migration files. No unapproved migration was applied.

## Read-Only Verification

- Both tables exist: `public.user_workout_sessions` and `public.user_workout_performed_sets`; RLS is enabled on both.
- Owner-scoped SELECT policies use `auth.uid()`. `anon` has no table privileges. `authenticated` has SELECT only; direct INSERT/UPDATE/DELETE are denied.
- Verified user ownership cascade, composite session/user child FK, unique performed-set slot, status/timing/metadata constraints, and single-active-session and save-request indexes.
- Verified required indexes including `uq_user_workout_sessions_single_active`, `uq_user_workout_sessions_save_request`, `uq_user_workout_performed_sets_slot`, and the user/date, user/routine, and performed-set order indexes.
- Verified session immutability, performed-set parent-status, and snapshot-validation triggers.
- Verified W7 lifecycle RPCs, completion V2, and `rpc_save_workout_session_v1(uuid,uuid,integer,jsonb)`. All nine RPC `pg_proc.prosrc` MD5 digests match the corresponding merged migration source. RPC owner is `postgres`, `SECURITY DEFINER`, `search_path=''`; `authenticated` EXECUTE is granted; PUBLIC/anon EXECUTE is denied.
- No authenticated Save/workout mutation was run. No user workout rows were read.

## Security Advisor and Remaining Blocker

Current Security Advisor reports a W7 warning on `public.trg_fn_validate_workout_session_snapshot()` for mutable `search_path`. Catalog metadata also shows PUBLIC/anon EXECUTE on this trigger-only helper. This was not altered because the authorized migration boundary excluded extra grants/schema changes. Record a separately reviewed forward-only correction or explicit security disposition before treating this W7 security gate as closed.

Other findings include 25 authenticated SECURITY DEFINER notices (8 W7 RPCs; catalog privileges and search paths checked), two private RLS-enabled tables with no policies, and leaked-password protection disabled. A pre-final-migration scan showed 24 authenticated SECURITY DEFINER notices and the same private-table/Auth warnings; no earlier baseline predating W7 exists to classify every non-W7 item as historical.

## Tracker and Acceptance Handoff

- Linear deployment evidence comment: `65e73f27-357b-4f90-bef3-f46e35efa089`. TNYX-84 remains **In Progress**, blocked by TNYX-80/W3 and TNYX-81/W4; it was not marked Done.
- GitHub PR #745 remains merged. No GitHub issue, PR, or branch metadata was changed for deployment.
- Source migration checks were recorded on PR #745; this deployment turn ran CLI dry-run/apply and read-only catalog/ledger/Advisor checks. No Flutter, Android/iOS, or physical-device acceptance was run.
- Flutter/device authenticated Save testing may be proposed as a separate owner-approved task only after the W7 Security Advisor finding is dispositioned. Hosted schema deployment does not establish Save E2E or Workout Log production readiness.
- No repository runtime/schema changes are part of this handoff. This task file and index update are documentation-only and are being proposed through a protected-main PR.

## Active Handoff

**Planning owner:** Codex
**Implementation owner:** Codex (documentation-only reconciliation)
**Previous agent:** Not applicable
**Review owner:** Independent repository reviewer
**Implementation ownership state:** Active until documentation PR review/merge
**Branch:** `codex/w7-hosted-migration-deployment-receipt`
**Base:** `main@cec78bb4e383afe4fc13eb7833e3bfed5b159b48`
**Next exact action:** Validate the docs-only diff, publish one focused PR, and keep TNYX-84 In Progress. Separately obtain owner authorization for any W7 trigger-helper security correction; do not run Save/device acceptance in this task.
