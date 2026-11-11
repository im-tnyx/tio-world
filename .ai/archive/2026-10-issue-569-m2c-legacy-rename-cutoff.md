# GitHub #569 — M2C Permanent Legacy Rename Cutoff

**Status:** **Validated / archived 2026-10-20.** [PR #594](https://github.com/im-tnyx/tio-world/pull/594) squash-merged as `main@20c1d21efe1760109b28daffa8990a9e77b4aca0` (verified `gh pr list --state merged` on 2026-10-20). Parent [GitHub #569](https://github.com/im-tnyx/tio-world/issues/569) stays OPEN. Production Move stays OFF. The historical status line is not the current handoff.
**Historical status:** **Status:** Ready for Review — exact-head code/database CI PASSED at `8ea0be95107d2712716d7c15624393045e6eb1fc`; P3 canonical Workout status drift addressed in subsequent docs-only review correction; merge review and hosted deployment NOT approved.
**Primary owner:** Supabase/Postgres implementation on the single remote branch `tnyx/issue-569-m2c-legacy-rename-cutoff`.
**Affected platforms:** Supabase versioned migration, SQL/security tests, GitHub CI.

## Owner Approval and Scope Boundary

**Trigger:** None — security prerequisite within already owner-approved Routine Move #569.
**Approval status:** Existing approved #569 scope.
**Approval evidence:** Owner-provided Windows Supabase CLI v2.121.0 generated `20261017154241_retire_legacy_routine_name_update.sql`, committed as `93aae09f` and pushed to GitHub; explicit remote implementation requested.
**In scope:** Narrow `authenticated UPDATE(name)` retirement and dependent SQL + concurrency test reconciliation.
**Explicit non-changes:** No table/column shapes, new server RPC, production SQL, hosted rollout, Move EXECUTE, Flutter UI, Create & Move, Program Delete, Release.

## Active Handoff

- **Planning owner:** GitHub #569 (Open); Linear TNYX-81 broad W4 backlog with TNYX-78/TNYX-80 dependencies.
- **Implementation owner:** This remote branch, not a second local editor.
- **Review owner:** GitHub security/manual reviewer after exact-head CI.
- **Implementation ownership state:** Active, PR validation pending.
- **Repository state last verified:** Base `main@1188346d90fd8e1a15b77d00eae48d369bd4d817`, branch scaffold `93aae09fcc6d8d1ee46619a36da890cdac9cd5b9` ahead 1/behind 0.
- **Branch:** `tnyx/issue-569-m2c-legacy-rename-cutoff`
- **Observed working-tree state:** Owner posted clean tracking `git status -sb` immediately after scaffold push. Cannot inspect their Windows checkout from remote connector.
- **Current implementation state:** `e317f563` supplies versioned cutoff and 3 SQL matrices; `dd9323dd` reconciles 2 concurrency harnesses and permanent-grant preflight.
- **Relevant execution surface:** GitHub workflow disposable local Supabase Postgres only. CI automatically replays all migrations.
- **Validation completed at SHA:** Supabase Database CI #39047957996 SUCCESS (46/46) and both attribution checks SUCCESS at `8ea0be95107d2712716d7c15624393045e6eb1fc`. This is the code-changing source SHA; docs-only follow-up does not alter SQL, workflows or scripts.
- **Validation remaining:** Verify required attribution/checks on the new docs-only HEAD; complete independent/owner manual merge gate and resolve P3 review thread. Hosted rollout, installed-client compatibility, and separate deploy/rollback remain gated. Full 64-migration replay/ledger, protected Rename/Update/Delete/Move races, matrices and lint PASSED at the recorded code SHA.
- **Current blocker:** Final review/merge gate and separate explicit hosted-dev-client rollout gate (no production writes performed).
- **Open review finding IDs:** P3 docs-status drift, PR #594 review thread `PRRT_kwDOTOXwB86th7JR` (addressed in this docs-only commit; verify and resolve after push). No new P1/P2 substantiated on prior code HEAD.
- **Next exact action:** Verify review correction and exact-head check status, reply/resolve P3 thread, then await explicit owner merge approval. Never deploy hosted SQL as part of this review.

## Discovery / Codebase Exploration

- Merged M1 Move RPC stays dormant (repository-only, no client EXECUTE); hosted Supabase has 62 migrations and still allows direct authenticated `UPDATE(name)`.
- Old SQL baselines `tnyx_78`, `tnyx_81`, `tnyx_526` expected direct Name UPDATE success; old TNYX-81/#526 race harnesses intentionally allowed it. M2C preflight PR #593 simulated the revoke in a temporary transaction.
- Existing protected 7-argument `update_user_workout_routine_with_composition` checks owner, source Program, revision and mutation token, and supports Name-only updates while preserving child identities.

## Clarification / Architecture Design

**Chosen:** One CLI-generated migration revokes `authenticated UPDATE(name)`, then asserts no effective direct UPDATE, retained metadata INSERT/SELECT and protected RPCs, and Move still dormant. No server-side client-version trust and no re-grant. SQL tests assert SQLSTATE 42501 for old clients, protected Rename success/replay and foreign-owner denial. Two races now pit a protected Rename winner against stale Update and Delete. The race harnesses target only the fixed GitHub disposable database, refuse libpq overrides, and ignore psqlrc.

**Rejected:** Broad table UPDATE, client-side `program_id` writes, new server API, unconditional older-client allowlist, silent production deploy, enabling Move now.

## Quality Review / Final Handoff

**Source DB checks validated at `8ea0be95` only.** Documentation-only P3 correction does not change runtime SQL/tests. Record post-doc-check HEAD and final review outcome separately. No hosted migration, Android/iOS release or Move EXECUTE authorization implied.
