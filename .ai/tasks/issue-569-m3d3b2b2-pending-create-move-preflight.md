# #569 M3D3B2b2 — Pending Create versus Move Program dispatch preflight

**Status:** Implementation / CI pending
**Implementation owner:** Workout feature data/presentation and apps/app composition
**Approval:** Existing approved #569 Move Routine safety acceptance; user 2026-10-19 `Next work go with audit` after B2b1 merge. Normal internal correctness subtask; no new visible product/UI or Supabase shape.

## 1. Discovery
An atomic Create Routine produces a **new** RoutineId in its existing Program, while Move re-parents a **different existing** RoutineId. B2a/B2b1 guards are owner+Routine keyed, so a Create pending in the *source or destination Program* is not represented by that guard. Requirements #569 prevent active/in-flight Create conflicts, including lost RPC acknowledgment after auth/session rotation.

**Desired outcome:** Existing Move and Create+Move write paths must fail closed before RPC dispatch when the owner has an unconfirmed Create Routine in either affected Program. Only positive owner-scoped Create reconciliation or definitive rejection may clear the pending bit.

## 2. Codebase exploration
- Root AGENTS, nested feature rules, `.ai/workflow.md`, `.ai/FEATURE_DEVELOPMENT.md`, ADR-0015, canonical Routine screen doc, GitHub #569 and Linear TNYX-81 read.
- Current verified base: protected `main@d758f6652d23aa82c7542b75d940e4ce32e44e68`, #610 merged, post-merge Flutter #39207704722 SUCCESS 5/5; no open PR at audit.
- `RoutinePendingCreateGate` already persists exact pending owner/Program commands across login cycles; positive metadata+composition verification releases; negative/absent owner read never releases.
- `SupabaseRoutineMoveRepository` contains both protected Move variants and a separate same-Routine CAS/UNKNOWN gate, but previously had no pending Create Program visibility.
- Tio hosted Supabase 2026-10-19 read-only: 64 migrations; `move_user_workout_routine` authenticated EXECUTE=false; `create_user_workout_program_and_move_routine` absent; Delete EXECUTE true. No hosted mutations planned.
- Previous B2b1 `.ai/tasks` merged status text is historically stale, now superseded by verified [PR #610 post-merge handoff](https://github.com/im-tnyx/tio-world/pull/610#issuecomment-6260800044).

## 3. Clarification & architecture
**Decision:** Reuse the existing owner/Program pending Create gate; publish only a boolean predicate `hasPendingForOwnerProgram` (not its private command/draft) to the Move repository through the existing apps/app composition root. Require the Move repository's already validated owner/cycle. Check source and destination just before either RPC, **after** preserved same-Routine UNKNOWN/in-flight/stale-target precedence and **before** consuming the prepared capability or reserving a Move. Callback errors fail closed. Preserve pending across A→B→A. An owner B pending Create never blocks owner A. No Program-global lock, new persisted source of truth, server privileges or UI change.

**Explicit limits:** This is the Create-pending → Move dispatch preflight direction. An independent new Routine Create while a distinct Routine Move is already in-flight remains possible; these different RoutineIds do not conflict by themselves, and server CAS/Program ownership is final authority. Two-device Create versus Move and Program deletion races require server transactions; no false cross-device claims. M3D3B3 verified source/dest refresh and real five-second reverse Undo remain separately gated.

## 4. Implementation
- [x] Add owner-only boolean pending accessor to existing `RoutinePendingCreateGate`.
- [x] Inject callback from `routinePendingCreateGateProvider` into the existing Move data repository; do not reach UI draft from data.
- [x] Both existing Move and atomic Create+Move check source and destination Program before write; preserve stale/UNKNOWN semantics.
- [x] Add focused fake Move gateway tests for source, destination, other owner, callback failure; gate test for login-cycle retention and definite release.
- [ ] Exact-head GitHub Flutter CI and attribution.
- [ ] Codex/inline review and owner merge gate.

## 5. Quality Review
**Validation:** Pending GitHub exact-head CI. No local Windows checkout, `git status`, Flutter SDK, device QA or compiled APK run claimed.

## 6. Final Handoff
**Branch:** `tnyx/issue-569-m3d3b2b2-pending-create-move-preflight`.
**PR:** Not yet created.
**Release hold:** `routineMoveReleaseEnabledProvider=false`; debug Move preview zero-write; no hosted Supabase grant, migration or production activation.
**Next:** M3D3B3 owner-verified source/dest refresh; real five-second Undo after approved server contract.
