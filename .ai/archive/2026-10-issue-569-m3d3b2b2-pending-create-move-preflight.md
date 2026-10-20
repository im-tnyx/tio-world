# #569 M3D3B2b2 — Pending Create versus Move Program dispatch preflight

**Status:** **Validated / archived 2026-10-20.** [PR #611](https://github.com/im-tnyx/tio-world/pull/611) squash-merged as `main@948ad092562eab45590eac42411a61d93c28a52a` (verified `gh pr list --state merged` on 2026-10-20). Parent [GitHub #569](https://github.com/im-tnyx/tio-world/issues/569) stays OPEN. Production Move stays OFF. The historical status line is not the current handoff.
**Historical status:** **Status:** Ready for Review #611, Codex P2 fix submitted; exact-head CI/re-review pending. NOT MERGED.
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
- [ ] Exact repaired HEAD GitHub Flutter CI and attribution (previous `3d81c5d` 5/5 + 2/2 PASS; later source changes invalidate that evidence).
- [ ] Codex P2 #4311021045 disposition after exact-head validation; then review/merge gate. Owner has NOT approved merge.

### Codex P2 error precedence remediation (2026-10-19)
- On Ready-for-Review, exact source HEAD `3d81c5df`, [Codex P2 #4311021045](https://github.com/im-tnyx/tio-world/pull/611#discussion_r4311021045) confirmed a real ordering bug. When a Routine Edit/Delete result is UNKNOWN or its post-inspection shared generation is stale, the owner+Program pending Create check was evaluated too early, emitting `inProgress` instead of `RoutineMoveOutcomeUnknown` / `staleTarget`, obscuring vital **do not retry** guidance. Affects both existing Move and atomic Create&Move.
- Repair `3b5d3fb8`: perform the existing same-Routine uncertain, inFlight and generation checks **before** the pending Create preflight, then reserve with `cross.tryStart` synchronously before RPC. Pending Create still blocks before any write and does not consume the one-use Move target. No new gate, schema, RPC or UI.
- Regression tests `e86e55df`: four cases, both Move variants × (shared UNKNOWN vs stale-generation), with positive pending Create and zero RPCs / zero pending-lookup calls when a higher-priority error is present. Original five pending-Create regression cases remain, nine focused tests total.
- Prior `3d81c5df` Flutter CI 5/5 + attribution 2/2 PASS **predates the repair**. Do not count it as validation. Latest repair+handoff HEAD CI, Codex re-review and unresolved-thread resolution pending. Any updated handoff-only commit requires new exact-head validation.

## 5. Quality Review
**Validation:** Source/test HEAD `30a96c5c` [Flutter CI #39209803598](https://github.com/im-tnyx/tio-world/actions/runs/39209803598) analyzer and core-wear PASS, app-workout and nutrition in progress at first checkpoint; [attribution #39209803599](https://github.com/im-tnyx/tio-world/actions/runs/39209803599) 2/2 PASS. This documentation-only update changes HEAD; verify its own latest checks before claiming full green. No local Windows checkout, `git status`, Flutter SDK, device QA or APK build.

## 6. Final Handoff
**Branch:** `tnyx/issue-569-m3d3b2b2-pending-create-move-preflight`.
**PR:** [Ready for Review #611](https://github.com/im-tnyx/tio-world/pull/611), OPEN and UNMERGED. Owner only said `Go next`, not `Go merge`.
**Release hold:** `routineMoveReleaseEnabledProvider=false`; debug Move preview zero-write; no hosted Supabase grant, migration or production activation.
**Next:** M3D3B3 owner-verified source/dest refresh; real five-second Undo after approved server contract.
