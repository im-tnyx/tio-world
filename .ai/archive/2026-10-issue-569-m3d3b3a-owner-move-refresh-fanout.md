# GitHub #569 — M3D3B3a owner-cycle Move list refresh fan-out

**Status:** **Validated / archived 2026-10-20.** [PR #612](https://github.com/im-tnyx/tio-world/pull/612) squash-merged as `main@4b9404f4e6a93239f8ddab597eb6b55efdb7c1b0` (verified `gh pr list --state merged` on 2026-10-20). Parent [GitHub #569](https://github.com/im-tnyx/tio-world/issues/569) stays OPEN. Production Move stays OFF. The historical status line is not the current handoff.
**Historical status:** **Status:** Implementation on scoped branch, exact-head CI and review pending
**Owner:** Workout feature presentation + thin apps/app wiring/tests
**Approved boundary:** Follow-up correctness subtask under owner-approved #569 after merged #611. Owner `Next work go with audit` on 2026-10-19. **NO MERGE** in this turn.

## Discovery and system audit
- Read fresh root `AGENTS.md`, nested `apps/features/AGENTS.md`, `.ai/workflow.md`, `.ai/FEATURE_DEVELOPMENT.md`, Push/PR template; ADR-0015, canonical Routine doc, GitHub #569 and Linear TNYX-81 (Backlog, blocked by TNYX-78/80).
- Protected `main@948ad092562eab45590eac42411a61d93c28a52a`, [PR #611](https://github.com/im-tnyx/tio-world/pull/611) squash merged, [post-merge main CI #39214261385](https://github.com/im-tnyx/tio-world/actions/runs/39214261385) SUCCESS 5/5, no open PR on branch creation.
- Actual `RoutineMoveFlow.run` returns **bool = needs owner re-read after an attempted write**, including an UNKNOWN result, never proof of commit. Existing `ProgramDetailPage._moveRoutine` and `InlineProgramRoutines._moveRoutine` reread **only source Program**. Library destination expanded Routine list and Program collection (atomic New Program) remained stale.
- `ProgramsSurface` already owns `_routineRefreshVersion`; it can refresh all expanded Routine list controllers without recreating/collapsing the persisted Program cards. `ProgramsController.load()` rereads the Program collection, appropriate only if the atomic path may have created a Program.
- Read-only hosted Supabase: 64 applied migrations; `move_user_workout_routine` SECURITY DEFINER but authenticated EXECUTE **false**; atomic Create+Move RPC **not deployed**; Delete RPC authenticated EXECUTE true. Advisor includes existing authenticated SECURITY DEFINER warnings, not new code findings. No hosted writes/grants/DDL.

## Narrow architecture
1. Add feature-owned process-local `RoutineMoveRefreshSignal` with exact owner+login-cycle event; it carries **no Routine contents or claim of Move success**.
2. App shell emits once **only after** `RoutineMoveFlow.run` requests refresh and the original session still matches, including an UNKNOWN/definite post-dispatch failure. No cross-account old-route refresh, no automatic retry, no optimistic move.
3. For **existing** Program Move, bump `ProgramsSurface._routineRefreshVersion` so source **and destination** expanded Routine lists reload without collapsing their expansion. Do not gratuitously reread Program collection.
4. For **atomic Create & Move** after an attempted RPC, re-read persisted Programs plus their owner-scoped Routine children; a new Program is rendered only if actually returned by ProgramRepository.list. Errors and UNKNOWN do not invent created Program or a success state.
5. Mounted Program Detail listens to the same owner-cycle signal and reloads its ProgramRoutineController. Shell returns `false` to old source-only Move callback after publishing the fan-out (avoids duplicate source read), but retains the underlying flow's attempted/UNKNOWN semantics.
6. Existing no-write debug preview returns false, so no Move refresh is emitted. All production Move execution/permission gates remain OFF.

## Tests / independent review
- Feature signal unit coverage: owner mismatch, same owner new login-cycle, atomic Program-list bit, invalid identity.
- Flutter Library widgets: both expanded source/destination Routine lists update while staying expanded; UNKNOWN read does not fabricate a Move; atomic New Program appears only after persisted read; stale event from another owner/login-cycle cannot read owner list.
- Program Detail widgets: same-cycle refresh reads current source; cross-owner or old-cycle signal ignored.
- [ ] Exact-head Flutter analyzer/test CI and required commit attribution.
- [ ] Codex review/inline findings, owner merge gate.
- [ ] Follow-up B3b: **owner-safe UNKNOWN read verification and safe manual recheck after ambiguous RPC**, preserving do-not-retry and no claimed transaction result without durable server evidence. Do not conflate a read of destination membership with proof this specific RPC committed.

## Explicit exclusions
No new UI, no destructive Program lifecycle, no 5-second actual reverse Move Undo, no server migrations/grants/RPC deployment, no cross-device event stream, no domain ID changes, no production Move activation. `routineMoveReleaseEnabledProvider=false` remains hard OFF.

## Final handoff
**Branch:** `tnyx/issue-569-m3d3b3a-move-refresh-fanout`.
**Base:** protected `main@948ad092562eab45590eac42411a61d93c28a52a`.
**Tooling limitation:** GitHub connector cannot inspect user's local Windows `G:\projects\Tio-World` git status/worktrees, run local Flutter or device QA. Preserve user worktrees/stashes; GitHub exact-head CI must validate.
