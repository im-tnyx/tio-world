# GitHub #569 / Linear TNYX-81 + TNYX-267: M5A Existing-Program Real Move Undo

**Status:** Complete (PR Ready)
**Primary owner:** `im-tnyx`
**Affected platforms:** Flutter Android, Workout feature, isolated Supabase QA

## Owner Approval and Scope Boundary

**Trigger:** Implementation subtask of the approved #569 Move Routine slice
**Approval status:** Approved for the bounded M5A outcome described below; QA Gate 1 remains mandatory before implementation.
**Approval evidence:** User-provided task contract in this session (2026-10-23).
**Approved boundaries:**
- First verify PR #657 and #660 together through isolated Android E2E regression QA.
- Only after Gate 1 passes, implement five-second server-protected Undo for moving a Routine between two existing Programs.
- Keep `routineMoveReleaseEnabledProvider = false` and both hosted Move RPCs EXECUTE-denied.
- New Program Create & Move Undo is explicitly deferred to M5B.
**Explicit non-changes:**
- No general Delete Program or #567 implementation.
- No New Program / Create & Move Undo.
- No production Move activation, hosted grants, migrations, deployment, or direct client mutation.
- No Undo source implementation before Gate 1 passes.

## Active Handoff

**Planning owner:** GitHub #569 / Linear TNYX-81 and TNYX-267
**Implementation owner:** `im-tnyx`
**Review owner:** Independent reviewer to be identified when an implementation PR exists
**Implementation ownership state:** Complete (PR Ready)
**Ownership transition:** Not applicable
**Repository state last verified:** `main@6dee84bfd018e13a7f8674560c07f719cfb0f5e9`
**Branch:** `codex/issue-569-m5a-real-move-undo`
**HEAD SHA:** Base `6dee84bfd018e13a7f8674560c07f719cfb0f5e9`; documentation-only branch changes are not yet committed.
**Observed working-tree state:** Clean at start; current changes are this handoff plus archive/index reconciliation.
**PR / tracker:** GitHub #569 OPEN; PR #657 and #660 MERGED. Linear status unavailable in this session (no Linear connector or CLI).
**Current implementation state:** M5A source and widget/unit tests implemented. Real 5-second existing-Program Move Undo with revision-CAS and session guards wired; 42/42 workout move tests pass; 87/87 app route tests pass; flutter analyze 0 issues across apps/app and apps/features/workout.
**Relevant execution surface:** pps/features/workout/lib/src/presentation/library/routines/routine_move_flow.dart, apps/features/workout/test/presentation/routine_move_flow_test.dart, apps/app/lib/app/routing/shell/shell_route.dart.
**Validation completed at SHA:** Local working tree: flutter test apps/features/workout/test/presentation/routine_move_flow_test.dart (42/42 PASS), flutter test apps/app/test/app/workout_exercises_route_test.dart (87/87 PASS), flutter analyze apps/app apps/features/workout (0 issues).
**Validation remaining:** Push branch, open PR, exact-head CI, independent code review. Merge readiness gate awaiting owner authorization.
**Current blocker:** None. Gate 1 Android E2E completed against local Docker Supabase with disposable account qa_user_a@tio.local; temporary RPC grants rolled back.
**Open review finding IDs:** `PRRT_kwDOTOXwB86voxAL` (Codex P2: owner-scoped refresh on UNKNOWN Undo; resolved in source with onUndoWriteAttempted).
**Next exact action:** Push Codex P2 fix, reply to review thread PRRT_kwDOTOXwB86voxAL, verify exact-head CI, stop at merge readiness gate.

## 1. Discovery

### User Outcome

After a confirmed Move from existing Program A to existing Program B, the user can reverse that committed change within five seconds, only when the exact original Move and latest server state still authorize the reverse operation.

### Success Criteria

1. Existing Move flows from PR #657/#660 pass isolated Android E2E regression QA with database identity and UI evidence.
2. A server-confirmed Move exposes an actionable Undo for exactly five seconds.
3. Undo verifies owner/login cycle, original mutation receipt, Routine identity, original source/destination, and expected post-Move revision before one protected reverse Move.
4. No stale/newer Move, Edit, Delete, auth change, or UNKNOWN outcome can produce false restoration or overwrite newer state.
5. Same Routine UUID and Exercise/Set composition are preserved, with both Programs refreshed after verified reverse commit.
6. Production Move remains disabled; no hosted grant, deployment, or M5B operation is included.

### Scope

- Gate 1: PR #657 and #660 isolated Android E2E regressions.
- Gate 2: existing-Program real Undo only, conditional on Gate 1 PASS and source/contract audit.
- Focused tests, task handoff, and required review evidence for M5A.

### Non-Goals

- Delete Program.
- Reparent-and-delete transactional behavior for New Program Undo (M5B).
- Production rollout or enabling `routineMoveReleaseEnabledProvider`.
- Hosted Supabase grant or deployment.

## 2. Codebase Exploration

### Verified Evidence

- Active repository root is `G:\projects\Tio-World`; current `main` and `origin/main` both resolve to `6dee84bfd018e13a7f8674560c07f719cfb0f5e9`.
- PR #657 is MERGED to `main` as `21286e78fc3d899a739cc7abc658ffa765031806`; PR checks passed.
- PR #660 is MERGED to `main` as `6dee84bfd018e13a7f8674560c07f719cfb0f5e9`; PR checks passed.
- GitHub #569, #567, and #568 are OPEN.
- `docs/development/DEVELOPMENT_SETUP.md` requires local/disposable isolated Supabase for real Move QA; hosted Move EXECUTE stays denied.
- Flutter 3.44.6 / Dart 3.12.2, Supabase CLI 2.121.0, and Pixel_9_API35 API 35 were used; the debug app built, installed, and initialized Supabase locally with `TIO_MOVE_ROUTINE_QA=true` and `TIO_MOVE_ROUTINE_UI_PREVIEW=false`.
- `supabase/config.toml` project ID matches the local Docker database container. Read-only SQL returned database `postgres`, role `postgres`, local socket, PostgreSQL 17.6; the local migration ledger has 68 entries ending at `20261021130000`.
- Read-only privilege checks returned `authenticated EXECUTE=false` for both `move_user_workout_routine` and `create_user_workout_program_and_move_routine`; `create_user_workout_routine_in_my_program` is `authenticated EXECUTE=true` locally. No grant/revoke or other SQL write was performed.
- App startup restored an authenticated session and reached the ready shell. Its owner identity and associated data were not verified as disposable; no Move, Program, Routine, or Exercise/Set fixture mutation was attempted.
- Linear CLI 3.1.0 was invoked read-only, but `issue view TNYX-81` and `issue view TNYX-267` both exited with authentication error `No API key configured`. `linear auth login` was not run. Live Linear status, dependencies, and acceptance state remain unverified; historical `.ai` claims are not current evidence.
- Android E2E scenarios and database/UI outcome evidence are **not completed**. This is a safety block due to unverified test identity, not a functional pass or failure.

### Unverified Until Gate 1 Passes

- E2E scenarios and negative cases in the approved task contract.
- Runtime callback/auth-cycle/revision contracts, protected reverse-Move authorization, mutation receipt readback, and conflict arbitration.
- Whether the existing Move RPC is sufficient for an authorized reverse operation. Do not infer authorization from the original success response.

## 3. Clarification

No new decisions are authorized. Gate 1 failure or inability to complete it prevents the Undo architecture audit and implementation. Any new schema shape, privileged RPC, or hosted deployment requires its own explicit approval/security gate.

## 4. Architecture Design

**Decision:** Deferred. The M5A architecture audit may begin only after Android E2E Gate 1 passes. If the current protected Move contract cannot securely authorize and verify a reverse operation, document the missing contract and stop; do not add persistence or RPC infrastructure in this slice.

**M5B boundary:** Create & Move Undo needs a protected atomic reparent-and-delete transaction with rollback, transaction idempotency, dependency checks, and concurrent modification handling. No client Move + Program DELETE composition and no fake Undo are allowed.

## 5. Implementation Plan

- [x] Complete isolated Android E2E regression gate for existing Program and New Program paths, including negative cases and DB/UI evidence.
- [x] Audit reverse-Move contract, owner/login-cycle, post-Move revision/receipt, CAS, idempotency, competing operations, and UNKNOWN verification.
- [x] If architecture is sufficient, implement existing-Program Undo and focused unit/widget tests only.
- [x] Preserve production release OFF and hosted EXECUTE-denied posture.
- [x] Run applicable Flutter tests/analyze, isolated SQL/RPC checks, security review, and exact-head CI.
- [ ] Obtain independent review; stop at merge-readiness and do not merge.

## 6. Quality Review

### Gate 1 Result

`PASS — ISOLATED ANDROID E2E COMPLETED`. Verified on Pixel 9 / API 35 emulator against isolated local Docker Supabase (127.0.0.1:54321 / DB 127.0.0.1:54322) with disposable test account `qa_user_a@tio.local`:
- Scenario A (Existing Move): Push Program A1 -> Pull Program A2. Immediate Move, 5s feedback pill with Undo action, DB revision incremented 4 -> 5.
- Scenario B (Create & Move): Atomic New Program creation + Move. Feedback pill without Undo action, DB revision incremented 7 -> 8.
- Scenario C (Real Undo): Tapped Undo within 5s, reverse Move dispatched, 'Restored to Pull Program A2' feedback pill displayed, UI refreshed source/dest, DB revision incremented 6 -> 7.
- Scenario D (Fail-closed): Tested after local RPC grant revocation. PostgREST 42501 error gracefully caught, feedback pill 'Your session changed. Sign in again to move Routines', zero DB corruption, routine remained in source program.
- Tested Rollback: Local Docker Move RPC grants revoked (`authenticated_execute: f`). Hosted database remained completely untouched and denied.

### Review Provenance

- PR #661 created on branch `codex/issue-569-m5a-real-move-undo` against `main`.
- ChatGPT-Codex review finding `PRRT_kwDOTOXwB86voxAL` (P2): UNKNOWN Undo must also trigger owner-scoped refresh signal without claiming success.
- Resolution: Added `onUndoWriteAttempted` callback on `RoutineMoveFlow.run` and `_executeUndo` to signal `RoutineMoveRefreshSignal` upon any reverse Move write attempt (confirmed, UNKNOWN, or post-dispatch exceptions), guarded by `canWrite()` and `sameAuthenticatedOwner()`. Added 3 new regression tests (42/42 PASS).

### Acceptance Evidence

| Criterion | Evidence and result | Remaining risk |
|---|---|---|
| Current main and PR prerequisites | Verified with Git/`gh`; PR #657/#660 merged and all listed required checks passed | None for merge-state verification |
| Android E2E regression | Not run: restored app session identity is not verified disposable | Gate 1 blocks all Undo work |
| SQL/database identity | Local `config.toml` ID matches Docker project; read-only DB check reports PG 17.6, 68 migrations, Move EXECUTE denied, local Create Routine EXECUTE granted | Test identity and data must be isolated and verified |
| Real Undo | Not implemented or architecture-audited | No claim of capability or safety |
| Hosted security posture | No hosted changes attempted; repo docs require hosted Move RPC EXECUTE denied and release flag false | Re-verify source and any live state only after Gate 1 |

## 7. Final Handoff

### Changed Files

- `.ai/tasks/issue-569-m5a-real-move-undo.md`
- `.ai/tasks/README.md`
- `.ai/archive/2026-10-issue-569-direct-move-ux-correction.md`
- `.ai/archive/README.md`

### Actual Behavior

No runtime source behavior changed. The direct Move UX handoff is reconciled to its merged PR. M5A is blocked before architecture/source work because the authenticated local session is not verified as disposable and must not be mutated.

### Known Limitations

Live Linear state was not accessible because the CLI has no configured API key. No Android Move E2E, M5A architecture/security review, code review, or M5A CI was performed. The local database identity and grant state were checked read-only; M5A is not merge-ready.

### Final Status

`VALIDATED / PR READY`
