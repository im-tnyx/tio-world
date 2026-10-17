# GitHub #569 — M2C Permanent Legacy Rename Cutoff

**Status:** In progress — remote code awaits full disposable CI and review; hosted deployment NOT approved.
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
- **Validation completed at SHA:** None for this new cutoff. PR #593 preflight validated only its own prior SHA.
- **Validation remaining:** Full 64-migration replay/ledger, 2 protected Rename races, Rename/Delete/Move SQL, lint and exact-head required checks; review then deployment decision.
- **Current blocker:** Pending CI and review, later explicit hosted-dev-client rollout gate.
- **Open review finding IDs:** Not evaluated yet.
- **Next exact action:** Run/inspect Draft PR CI at current head, correct any concrete defects without applying hosted migration.

## Discovery / Codebase Exploration

- Merged M1 Move RPC stays dormant (repository-only, no client EXECUTE); hosted Supabase has 62 migrations and still allows direct authenticated `UPDATE(name)`.
- Old SQL baselines `tnyx_78`, `tnyx_81`, `tnyx_526` expected direct Name UPDATE success; old TNYX-81/#526 race harnesses intentionally allowed it. M2C preflight PR #593 simulated the revoke in a temporary transaction.
- Existing protected 7-argument `update_user_workout_routine_with_composition` checks owner, source Program, revision and mutation token, and supports Name-only updates while preserving child identities.

## Clarification / Architecture Design

**Chosen:** One CLI-generated migration revokes `authenticated UPDATE(name)`, then asserts no effective direct UPDATE, retained metadata INSERT/SELECT and protected RPCs, and Move still dormant. No server-side client-version trust and no re-grant. SQL tests assert SQLSTATE 42501 for old clients, protected Rename success/replay and foreign-owner denial. Two races now pit a protected Rename winner against stale Update and Delete. The race harnesses target only the fixed GitHub disposable database, refuse libpq overrides, and ignore psqlrc.

**Rejected:** Broad table UPDATE, client-side `program_id` writes, new server API, unconditional older-client allowlist, silent production deploy, enabling Move now.

## Quality Review / Final Handoff

**Not validated yet.** Record full database CI, required check outcome and review findings before ready-for-review/merge. No hosted migration, Android/iOS release or Move EXECUTE authorization implied by this task.
