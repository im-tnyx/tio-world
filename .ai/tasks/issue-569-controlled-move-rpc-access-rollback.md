# GitHub #569 / Linear TNYX-81: Controlled Move RPC Access & Rollback (Option A)

**Status:** In progress — review/merge gate only; production Move remains OFF and hosted Move RPCs remain EXECUTE-denied.
**Primary owner:** GitHub #569 / Linear TNYX-81; Implementation owner: `im-tnyx`. Independent review owner: `im-tio` / independent reviewer.
**Affected platforms:** Supabase Postgres, Flutter Android/iOS (architecture, security boundary, and local runbook only).

## Owner Approval and Scope Boundary

**Trigger:** None beyond an implementation/security-readiness subtask of already owner-approved GitHub #569.
**Approval status:** Approved
**Approval evidence:** On 2026-10-23, owner explicitly selected Option A ("A") for controlled real-write QA: real-write testing must use an **isolated Supabase environment** (local Docker-based Supabase CLI or dedicated disposable staging project), while hosted Tio-world database Move RPCs remain strictly **EXECUTE-denied** (`authenticated = false`).
**Approved product/UI/data-shape boundaries:**
- No forward broad `GRANT EXECUTE ... TO authenticated` migration in `supabase/migrations/` (prevents premature network-level exposure on hosted project).
- Hosted Move RPCs remain dormant with `authenticated=false`, `anon=false`, `service_role=false`, `PUBLIC=false`.
- Isolated QA environment execution and rollback runbook documented in `docs/development/DEVELOPMENT_SETUP.md`.
- Production Flutter `routineMoveReleaseEnabledProvider` remains hard `false`.
**Explicit non-changes:**
- No hosted SQL writes or migration deployment.
- No production `GRANT EXECUTE`.
- No production Flutter Move activation.
- No direct table `UPDATE(program_id)` or `DELETE` grants.
- No real-user data modifications.
- No new table/column shape.
- No #567 Delete Program or real Move Undo implementation.
- No speculative backend/service infrastructure.
- No automatic merge.

## Active Handoff

**Planning owner:** [GitHub #569](https://github.com/im-tnyx/tio-world/issues/569) / [Linear TNYX-81](https://linear.app/tnyx/issue/TNYX-81)
**Implementation owner:** `im-tnyx`
**Review owner:** Independent reviewer (`im-tio` / owner)
**Implementation ownership state:** Active
**Ownership transition:** Not applicable
**Repository state last verified:** `main@edbb2743bc1e36a010f82de0f638290d17cd288b`
**Branch:** `docs/issue-569-controlled-move-rpc-access-rollback`
**HEAD SHA:** verified at branch creation
**Observed working-tree state:** Clean working tree, exact files owned
**PR / tracker:** GitHub #569, Linear TNYX-81
**Current implementation state:** Complete source-only documentation and runbook update
**Relevant execution surface:** `docs/development/DEVELOPMENT_SETUP.md`, `.ai/tasks/issue-569-controlled-move-rpc-access-rollback.md`, `.ai/tasks/README.md`
**Validation completed at SHA:** `git diff --check` PASS (exit 0)
**Validation remaining:** Exact-head PR CI (Docs Hygiene CI, Commit Attribution Guard), independent review
**Current blocker:** None for docs PR; production Move release and real Undo remain downstream gates
**Next exact action:** Open scoped GitHub PR, await exact-head CI, obtain independent review

## 1. Discovery

### User Outcome
A reviewed, tested, rollback-ready controlled access plan for Move Routine QA that allows real-write testing in an isolated local environment without exposing unfinished Move operations to ordinary users on hosted infrastructure.

### Success Criteria
- Independent re-verification of baseline evidence (`main@edbb2743`, 68 migrations, Move RPCs dormant, Database CI green, Flutter release OFF).
- Rigorous security threat model and authorization audit answering all 7 required security decisions.
- Explicit Owner Decision recorded: Option A (Isolated Supabase Environment QA).
- No deployable broad authenticated GRANT committed to `supabase/migrations/`.
- Isolated QA execution runbook and tested revocation rollback commands added to `docs/development/DEVELOPMENT_SETUP.md`.
- Clean documentation hygiene diff (exit 0) with zero trailing whitespace or line-ending defects.

### Scope
- `docs/development/DEVELOPMENT_SETUP.md`: update Move Routine real-write QA section to reflect Option A, add isolated Supabase execution runbook, exact grant/revoke SQL commands.
- `.ai/tasks/issue-569-controlled-move-rpc-access-rollback.md`: task brief.
- `.ai/tasks/README.md`: task index update.

### Non-Goals
- No SQL migrations added to `supabase/migrations/`.
- No hosted database mutations or `supabase db push`.
- No production feature flag change.
- No real post-commit Undo implementation (remains a future separate slice).
- No #567 Program Delete reparenting implementation.

## 2. Codebase Exploration

### Verified Evidence
- `main@edbb2743bc1e36a010f82de0f638290d17cd288b` clean and fast-forwarded with `origin/main`.
- 68 migrations in `supabase/migrations/`, matching hosted ledger ending at `20261021130000_harden_move_routine_permanent_owner.sql`.
- Both Move RPCs (`public.move_user_workout_routine` and `public.create_user_workout_program_and_move_routine`) use trusted `auth.users.is_anonymous IS FALSE` server guards and have `authenticated EXECUTE = false`.
- [Supabase Database CI Run #39843185413](https://github.com/im-tnyx/tio-world/actions/runs/39843185413) SUCCESS (3m 19s) on `main@edbb2743`.
- [Flutter CI Run #39778389063](https://github.com/im-tnyx/tio-world/actions/runs/39778389063) SUCCESS (4m 19s) on `main@edbb2743`.
- `routineMoveReleaseEnabledProvider = Provider<bool>((ref) => false)` in `apps/app/lib/app/composition/workout_providers.dart`.

## 3. Clarification (7 Security Decisions)

| Decision | Status | Rationale / Architecture Truth | Owner |
|---|---|---|---|
| 1. QA Environment | **Option A (Isolated)** | Real-write QA must use an isolated Supabase environment (local Docker CLI / disposable staging). Hosted Move RPCs remain EXECUTE-denied. | Owner approved (2026-10-23) |
| 2. Threat Model for `authenticated` Grant | **Verified** | Flutter debug flags are client UI filters, not security boundaries. Granting EXECUTE on hosted exposes PostgREST endpoints to all logged-in accounts before Undo and #567 exist. | Architect |
| 3. Existing Authorization Infrastructure | **Verified** | PostgREST only has `anon`, `authenticated`, `service_role`. No test-user role or QA group table exists. A hosted grant is strictly all-or-nothing. | Architect |
| 4. Exact Signatures & Minimum Grants | **Defined** | `public.move_user_workout_routine(uuid,uuid,uuid,bigint,uuid)` and `public.create_user_workout_program_and_move_routine(uuid,uuid,uuid,text,bigint,uuid)`. Function-only EXECUTE, zero table-level UPDATE/INSERT grants. | Architect |
| 5. Controls & Concurrency | **Verified** | Server-side `auth.users.is_anonymous is false`, account key share, ordered Program key share, private routine identity lock, CAS revision, SHA-256 idempotency hash. Concurrency proven in existing shell tests. | Architect |
| 6. Rollback & Failure Response | **Tested & Documented** | `REVOKE EXECUTE ON FUNCTION ... FROM authenticated`. Immediate mitigation returning `42501` to subsequent calls without routine data loss. Rehearsed in `tnyx_569_permanent_owner_move_guard.test.sql`. | Architect |
| 7. Ordinary User Protection | **Enforced via Option A** | By restricting real-write QA grants to isolated local environments, hosted database users have zero exposure to unfinished Move operations. | Owner & Architect |

## 4. Architecture Design

### Chosen Approach (Option A)
```text
Developer/QA Client (Debug + TIO_MOVE_ROUTINE_QA=true)
    ↓
Local / Isolated Supabase Runtime (Docker / Disposable Staging)
    ↓ [Local grant: authenticated EXECUTE=true]
Protected Move RPCs (CAS, Idempotency, Permanent Owner)
    ↓ [Rollback drill: REVOKE EXECUTE ... FROM authenticated]
PostgREST returns 42501 (Clean Fail-Closed)

Hosted Production Supabase Project:
    → Move RPCs remain EXECUTE-denied (authenticated=false)
    → Zero ordinary user exposure
    → Zero premature Advisor SECDEF warnings
```

### Alternative Rejected (Option B)
Granting broad `authenticated` EXECUTE directly on the hosted Supabase project via forward migration was rejected because a client debug flag is not a backend security boundary, and Move lacks post-commit Undo and #567 Program Delete reparenting.

## 5. Implementation Plan

- [x] Create dedicated branch `docs/issue-569-controlled-move-rpc-access-rollback`.
- [x] Update `docs/development/DEVELOPMENT_SETUP.md` with Option A architectural decision, local QA runbook, exact grant and revocation commands.
- [x] Create task brief `.ai/tasks/issue-569-controlled-move-rpc-access-rollback.md`.
- [x] Update task index `.ai/tasks/README.md`.
- [x] Run `git diff --check` and verify clean repository diff.
- [ ] Open GitHub PR, await exact-head Docs Hygiene CI and Commit Attribution Guard, request independent review.

## 6. Quality Review

### Validation Run
- Windows native `git diff --check`: PASS (exit 0, no output).
- Git status: clean, exactly three owned paths.

### Acceptance Evidence

| Criterion | Changed behavior / file | Test or manual evidence + actual result | Observed SHA / environment | Remaining risk |
|---|---|---|---|---|
| Option A Isolation | `docs/development/DEVELOPMENT_SETUP.md` | Documented local Supabase QA runbook, exact grant/revoke SQL | Exact branch HEAD | None; hosted project untouched |
| No broad migration | `supabase/migrations/` | Directory untouched; 68 migrations preserved | `edbb2743` | None |
| Task handoff brief | `.ai/tasks/issue-569-controlled-move-rpc-access-rollback.md` | Created from template, 7 decisions recorded | Exact branch HEAD | None |
| Diff hygiene | Repository | `git diff --check` exits 0 | Exact branch HEAD | None |

### Review Provenance
- Review owner: `im-tio` / independent reviewer
- Diff reviewed: `main@edbb2743...HEAD` (three documentation files)

## 7. Final Handoff

### Changed Files
- `docs/development/DEVELOPMENT_SETUP.md`
- `.ai/tasks/issue-569-controlled-move-rpc-access-rollback.md`
- `.ai/tasks/README.md`

### Actual Behavior
Records the completed security audit and owner-approved Option A access plan for Move Routine QA. Move RPCs remain EXECUTE-denied on hosted infrastructure, eliminating exposure to ordinary users. Local isolated execution and rollback commands are documented for authorized debug QA.

### Known Limitations
Production Move remains OFF; real post-commit Undo and #567 Program Delete reparenting remain separate future milestones.

### Final Status
`REVIEW` (PR ready for exact-head CI and independent review).
