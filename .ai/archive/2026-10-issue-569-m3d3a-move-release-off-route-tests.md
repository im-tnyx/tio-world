# #569 M3D3A — App-router Move release-OFF regression

**Status:** **Validated / archived 2026-10-20.** [PR #605](https://github.com/im-tnyx/tio-world/pull/605) squash-merged as `main@bd55f80eb0171590544205fc41a36451ab550a65` (verified `gh pr list --state merged` on 2026-10-20). Parent [GitHub #569](https://github.com/im-tnyx/tio-world/issues/569) stays OPEN. Production Move stays OFF. The historical status line is not the current handoff.
**Historical status:** **Status:** In progress
**PR review state:** Ready for Review; Codex review findings under correction, independent approval pending.
**Primary owner:** `apps/app` authenticated shell/widget tests
**Affected platforms:** Flutter Android/iOS tests only

## Owner Approval and Scope Boundary

**Trigger:** None; this is an internal test-only subtask within the owner-approved Move Routine #569.
**Approval status:** Not required; owner requested continuation after approving and merging PR #604.
**Approved boundaries:** Verify both existing Program Detail and expanded Library real Routine 3-dot action sheets hide Move while the production capability is OFF, including an authenticated app session and non-null Move adapters.
**Explicit non-changes:** No production code/UI, feature behavior, new route, auth grants, Supabase migration/RPC or deployment, `routineMoveReleaseEnabledProvider` flip, merge, schema or physical QA.

## Active Handoff

- **Planning / Implementation owner:** current `apps/app` test slice; one active implementation owner for this branch
- **Review owner:** Codex automated review submitted two documentation P1 findings on PR #605; both are addressed in this governance-only follow-up. Independent approval remains pending.
- **Implementation ownership state:** Test implementation complete; governance-only Codex findings being corrected inside the same bounded slice; no production changes or ownership transfer of source files.
- **Repository state last verified:** protected `main@d3753bcda7cc0dae6a61d0c3914d78e6500fc3ea`, PR #604 squash merged, post-merge Flutter CI #39141831465 SUCCESS, zero open PRs before branch creation
- **Branch:** `tnyx/issue-569-m3d3a-move-release-off-route-tests`
- **Observed working tree:** remote GitHub connector branch from exact main commit; Windows local checkout and `git status -sb` **not observable**, no local file operations, force updates, or cleanup
- **PR/tracker:** GitHub #569 remains Open; Linear TNYX-81 broad Backlog blocked by TNYX-78/80
- **Validation:** source/test HEAD `974e8e1a5cc826cbfa1a3bf50d591bbe3d148793` [Flutter CI #39143637835](https://github.com/im-tnyx/tio-world/actions/runs/39143637835) SUCCESS (5/5 jobs); later handoff-only HEAD `ebd01c6bd93347d7c4483c179087ad648e5c0442` [Flutter CI #39144387950](https://github.com/im-tnyx/tio-world/actions/runs/39144387950) also SUCCESS (5/5 jobs). Any new Codex-disposition docs-only HEAD requires its own checks. No local Flutter runner or Windows `git status` verification; independent approval pending.
- **Next exact action:** verify CI for Codex finding corrections on latest HEAD, reply to both [Codex inline findings](https://github.com/im-tnyx/tio-world/pull/605/files), resolve threads only after verified fix, then hand off for independent review. Keep Move OFF; no merge without separate `Go merge`.

## Discovery / verified evidence

- Root and feature `AGENTS.md`, `.ai/workflow.md`, `.ai/FEATURE_DEVELOPMENT.md`, `docs/adr/0015-program-owned-routine-and-program-source-boundary.md`, Core theme README, and existing app Workout tests re-read at `main@d3753bcd`.
- App shell `apps/app/lib/app/routing/shell/shell_route.dart` passes nullable `onMoveRoutine` to **both** Program Detail and expanded Library only when `routineMoveReleaseEnabledProvider` permits it; provider in `apps/app/lib/app/composition/workout_providers.dart` is hard `false`.
- `RoutineMetadataCard` owns the existing Core sheet: `routine-move-<id>` appears only when its `onMove` callback is non-null. `workout_exercises_route_test.dart` already mounts real router, Routine lists, two action-sheet surfaces and valid auth/bootstrap fixture.
- Review note on PR #604 [discussion_r4307599583](https://github.com/im-tnyx/tio-world/pull/604#discussion_r4307599583) was explicitly deferred as an activation gate, not a fixed test.
- Hosted atomic Create+Move RPC missing and authenticated existing Move EXECUTE denied at prior verified hosted read; no release permissible.

## Architecture decision and scope

- **Chosen:** app-router widget tests with injected inert Move repository/adapter and valid owner/login-cycle/SDK user; assert Move absence on both actual production-composed action sheets, and Edit remains available. No fake Move RPC calls.
- **Rejected:** exposing a temporary release flag, writing a separate widget sheet, or weakening client permission for test setup.
- **Owner boundaries:** `apps/app/test/app/workout_exercises_route_test.dart` only for code, plus this task/index; no feature/core production edits.
- **Failure/auth behavior:** Tests must not dispatch writes. The release flag remains `false`. Existing auth-revocation widget tests remain unchanged.

## Implementation / quality

- [x] Added an inert Move gateway and matching Auth/SDK user fixture only in existing app test.
- [x] Added two real router tests: Program Detail and expanded Library with non-null adapter/alias, matching owner and release OFF; Flutter CI SUCCESS on source/test `974e8e1a` and follow-up handoff-only `ebd01c6b`, each 5/5 jobs.
- [x] Scoped remote source write touched only the existing app widget test and task/index; no production code or hosted Supabase change.
- [x] Inspected complete 3-file PR diff and app-route tests; no production source changes. `974e8e1a` [Flutter CI #39143637835](https://github.com/im-tnyx/tio-world/actions/runs/39143637835) SUCCESS 5/5 and `ebd01c6b` [Flutter CI #39144387950](https://github.com/im-tnyx/tio-world/actions/runs/39144387950) SUCCESS 5/5; current corrections require new HEAD validation.
- [ ] Leave separate M3D3 enabled-path auth-cycle revocation, cross-operation arbitration, verified refresh/reconciliation and hosted RPC security rollout unclaimed.

## Codex Review Finding Continuity

- **P1 / 4307769061:** [Task status contract](https://github.com/im-tnyx/tio-world/pull/605#discussion_r4307769061), observed `ebd01c6b`. Corrected the top-level task status to allowed `In progress`; PR review phase is recorded separately. Fix pending exact-new-HEAD validation/review-thread disposition.
- **P1 / 4307769064:** [Stale validation claims](https://github.com/im-tnyx/tio-world/pull/605#discussion_r4307769064), observed `ebd01c6b`. Updated checked item and final handoff to distinguish verified successful source/test and handoff CI from subsequent pending docs CI. Fix pending exact-new-HEAD validation/review-thread disposition.

## Final handoff

**Actual behavior:** Test-only app-router coverage added on isolated branch. It injects an inert Move gateway, a consistent SDK/authenticated owner and asserts both real action sheets keep Edit but omit Move while release is OFF. Test execution and Flutter CI succeeded on source/test `974e8e1a` (5/5) and handoff `ebd01c6b` (5/5); no runtime release.
**Final status:** REVIEW for test scope only. Flutter CI verified successful through `ebd01c6b`; Codex disposition docs changes require exact-new-HEAD validation, then independent approval. PR #605 remains unmerged.
