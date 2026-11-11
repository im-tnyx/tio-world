# GitHub #569 / Linear TNYX-81 — M4A permanent-owner Move admission (source-only)

**Status:** In progress — implementation committed on isolated review branch, PR/CI and independent review pending.
**Primary owner:** Workout / Supabase security and data integrity.
**Affected platforms:** Supabase Postgres functions, disposable SQL test matrix and database CI. No Flutter, Wear OS or watchOS code changes.

## Owner Approval and Scope Boundary

**Trigger:** None. This is a bounded internal RPC authorization-hardening subtask of the previously approved #569 Move Routine capability; user explicitly directed starting the next task through merge gate, with NO MERGE.
**Approval evidence:** 2026-10-21 continuation instruction in project conversation. This permits repository implementation/PR/review; it does not authorize a hosted migration, GRANT, new production UI, real Move, five-second Undo or release.
**Scope:** Add an early, trusted `auth.users.is_anonymous IS FALSE` admission guard to BOTH existing dormant #569 SECDEF RPCs without changing their CAS/lock order/idempotency; keep client EXECUTE withheld; prove guest rejection under transaction-only CI grants and preserve existing #568 authority.
**Explicit non-changes:** No new table/column/RLS policy, direct Routine `UPDATE(program_id)`, new service/API, broad permission, auth metadata trust, UI/layout, flag flip, hosted writes, migration deploy or merge. Do not edit already-applied 20261017/20261018 migrations.

## Active Handoff

- **Planning owner:** [GitHub #569](https://github.com/im-tnyx/tio-world/issues/569), [Linear TNYX-81](https://linear.app/tnyx/issue/TNYX-81); upstream [#568](https://github.com/im-tnyx/tio-world/issues/568) / TNYX-78 remains separately release-gated.
- **Implementation owner:** Connected `im-tnyx` GitHub session, only this M4A branch/scope; **review owner:** independent `im-tio` requested at PR gate.
- **Implementation ownership state:** Active until PR review and handoff; no other #569 implementation PR was open when this branch was created.
- **Ownership transition:** Not applicable; new bounded security subtask, not a takeover of another branch.
- **Repository baseline:** protected `main@684d94ca0e7a01866a0bc06017ffc163cb54b0ab` from GitHub branch API on 2026-10-21. GitHub-connected branch `tnyx/issue-569-m4a-permanent-owner-move-guard-20261021`; owner Windows checkout, `git status`, local dirty/untracked files and local tooling were NOT accessible/inspected. No local checkout touched.
- **Live database baseline:** project `oykupyiitspujzpwwvuj`; 66 migrations applied through `20261019162535`. Repository #568 `20261021120000` source migration is not hosted. Two #569 Move functions are SECDEF with empty `search_path` and authenticated/anon/service-role EXECUTE false; direct `UPDATE(program_id)` denied. Do not confuse successful source replay with hosted activation.
- **Current implementation state:** M4A new `20261021130000` migration + focused disposable guest SQL regression + CI test step, branch-only. There are 68 repository migration files after this slice vs 66 hosted; both new 20261021 files are un-applied.
- **Validation completed:** GitHub connector source reads, live read-only Supabase catalog/migrations and static scope inspection. Do not claim actual SQL replay/CI/owner-local validation until receipts exist.
- **Validation remaining:** exact-head Supabase Database CI, attribution, native `git diff --check` receipt, code/security review, merge/rules/threads recheck, and separately authorized hosted tests prior to release.
- **Current blocker:** Independent PR review and CI required; production Move remains NO-GO even after this PR is approved.
- **Next exact action:** Open branch PR, verify exact-head checks/diff, request independent `im-tio` review, address real P1/P2 findings inside scoped ownership; stop at reviewed merge gate. NEVER merge without new owner instruction.

## 1. Discovery

The accepted #569 user outcome is atomic Move to an existing owner Program or atomic Create Program + Move, preserving stable Routine/Exercise/Set IDs, owner/CAS/replay semantics and protected permissions. Guest sign-ins with a valid Supabase Auth UID hold the SQL role `authenticated`; checking `auth.uid()` alone does not enforce the 2026-10-21 permanent-owner creation policy already hardened under #568.

Inspected root `AGENTS.md`, nested `apps/features/AGENTS.md`, `.ai/workflow.md`, `.ai/FEATURE_DEVELOPMENT.md`, canonical architecture/Supabase/Workout docs, PR/push templates, #569/#568 trackers, live provider and both 20261017/20261018 function bodies, #568 security-grant migration and SQL matrix, CI workflow, live Supabase ACL/migration state. `TNYX-81` is Backlog blocked by TNYX-78/TNYX-80; its broad status does not invalidate already merged #569 component code.

## 2. Architecture and decision

**Chosen:** Append one source migration with `CREATE OR REPLACE FUNCTION` for both existing Move signatures. Preserve their original implementation byte-for-byte apart from changing `CREATE` to `CREATE OR REPLACE` and inserting the same trusted `auth.users` permanent-account guard after the existing `auth.uid()` null check, before request validation, locks, mutation and replay. Keep `SECURITY DEFINER`, postgres ownership and `search_path=''`, explicit client `REVOKE ALL`. Isolated SQL test creates a genuine `auth.users.is_anonymous=true` fixture with owner root, temporarily grants EXECUTE in a rolled-back transaction, spoofs a false JWT claim, checks both RPCs reject with SQLSTATE 28000 before writes, and rechecks ACL/default/write boundaries.

**Rejected:** Trusting `request.jwt.claim.is_anonymous`, relying on SQL role `authenticated`, updating an already-applied migration, granting the two RPCs as part of the hardening subtask, shipping partial UI or changing backend identity architecture. No new stored function/helper because scope has exactly two stable existing RPC entrypoints.

**Compatibility:** Existing owner with `auth.users.is_anonymous=false` follows unchanged body. The regression matrix for owner isolation, idempotent retry, locking and concurrency remains separately responsible for behavior. This source slice deliberately leaves Move dormant; it does not enable any client.

## 3. Implemented files

- `supabase/migrations/20261021130000_harden_move_routine_permanent_owner.sql`: two exact-signature guarded replacements, no privilege grant.
- `supabase/tests/database/tnyx_569_permanent_owner_move_guard.test.sql`: role/ACL/SECDEF, authentic guest with spoofed JWT claim, no Move or orphan Program, temporary-grant rollback.
- `.github/workflows/supabase-db-ci.yml`: run the test before prior #569 matrices.
- This handoff and its entry in `.ai/tasks/README.md`.

## 4. Quality and release gate

| Gate | Evidence | Status |
|---|---|---|
| Preexisting functional contract | Original Move SQL bodies, prior CI matrices and approved ADR-0015 inspected | Source evidence only |
| Guest auth and ACL regression | New transactional SQL file + CI workflow wiring | Current-head CI pending |
| Exact head / changed paths | GitHub PR comparison and review thread scan | Pending PR |
| Native local diff | Owner-run Windows `git diff --check` at exact PR head | Pending, not run through connector |
| Independent review | Formal `im-tio` GitHub review, findings fixed and rechecked | Pending |
| Hosted rollout | Review new M4A and existing #568 repo-only migration separately before any `db push`; rollback and live ACL/Advisor review | NOT AUTHORIZED |
| Product release | `routineMoveReleaseEnabledProvider=false`, real-write Android/iOS QA, rollout and rollback plan, Undo release decision | NO-GO |

**Security operational caveat:** If this migration is later deployed, it still does NOT grant client Move RPC EXECUTE. A separate reviewed exact-signature grant migration and owner deployment approval are required. A Flutter compile-time false provider is not proof of an instantaneous remote kill switch once an RPC is publicly callable. The #568 source migration must not be silently deployed just to exercise #569.

## 5. Final Handoff

**Status:** REVIEW after PR creation while independent validation is pending; not PASS or merge-ready. No merge, no branch deletion, no hosted writes, no local commands and no device tests performed by this session.
