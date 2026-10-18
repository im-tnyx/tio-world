# #569 M3D3A — App-router Move release-OFF regression

**Status:** In Review (PR #605 ready-for-review gate)
**Primary owner:** `apps/app` authenticated shell/widget tests
**Affected platforms:** Flutter Android/iOS tests only

## Owner Approval and Scope Boundary

**Trigger:** None; this is an internal test-only subtask within the owner-approved Move Routine #569.
**Approval status:** Not required; owner requested continuation after approving and merging PR #604.
**Approved boundaries:** Verify both existing Program Detail and expanded Library real Routine 3-dot action sheets hide Move while the production capability is OFF, including an authenticated app session and non-null Move adapters.
**Explicit non-changes:** No production code/UI, feature behavior, new route, auth grants, Supabase migration/RPC or deployment, `routineMoveReleaseEnabledProvider` flip, merge, schema or physical QA.

## Active Handoff

- **Planning / Implementation owner:** current `apps/app` test slice; one active implementation owner for this branch
- **Review owner:** independent PR review pending; no approval implied
- **Implementation ownership state:** Test implementation complete; handed to review (no production changes)
- **Repository state last verified:** protected `main@d3753bcda7cc0dae6a61d0c3914d78e6500fc3ea`, PR #604 squash merged, post-merge Flutter CI #39141831465 SUCCESS, zero open PRs before branch creation
- **Branch:** `tnyx/issue-569-m3d3a-move-release-off-route-tests`
- **Observed working tree:** remote GitHub connector branch from exact main commit; Windows local checkout and `git status -sb` **not observable**, no local file operations, force updates, or cleanup
- **PR/tracker:** GitHub #569 remains Open; Linear TNYX-81 broad Backlog blocked by TNYX-78/80
- **Validation:** source/test HEAD `974e8e1a5cc826cbfa1a3bf50d591bbe3d148793` [Flutter CI #39143637835](https://github.com/im-tnyx/tio-world/actions/runs/39143637835) SUCCESS (5/5 jobs); independent review pending. GitHub API inspection only, no local Flutter runner or Windows `git status` verification. Any later handoff-only commit requires its own checks.
- **Next exact action:** complete PR #605 Ready for Review transition after latest-head checks; request/await independent reviewer. Keep Move OFF; do not merge without separate `Go merge`.

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
- [x] Added two real router tests: Program Detail and expanded Library with non-null adapter/alias, matching owner and release OFF; runtime execution/CI validation still pending.
- [x] Scoped remote source write touched only the existing app widget test and task/index; no production code or hosted Supabase change.
- [x] Inspected the complete 3-file PR diff and app-route tests; no production source changes. `974e8e1a` Flutter CI SUCCESS (5/5, including app-workout and Analyze); pre-final handoff commit attribution was reported passing in prior task work. New handoff commit checks must be verified separately.
- [ ] Leave separate M3D3 enabled-path auth-cycle revocation, cross-operation arbitration, verified refresh/reconciliation and hosted RPC security rollout unclaimed.

## Final handoff

**Actual behavior:** Test-only app-router coverage added on isolated branch. It injects an inert Move gateway, a consistent SDK/authenticated owner and asserts both real action sheets keep Edit but omit Move while release is OFF. Test execution and CI are pending; no runtime release.
**Final status:** REVIEW for test scope only. Latest validated source/test SHA `974e8e1a` succeeded; independent approval and merge remain pending, as does any CI created by this handoff-only commit.
