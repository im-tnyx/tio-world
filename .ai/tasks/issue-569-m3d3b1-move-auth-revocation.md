# #569 M3D3B1 — Enabled-test-only Move selector Auth-cycle revocation

**Status:** In progress
**Primary owner:** `apps/app` app-router widget tests
**Affected platforms:** Flutter Android/iOS widget regression only

## Owner Approval and Scope Boundary

**Trigger:** None. Internal regression subtask within the owner-approved #569 Move Routine lifecycle, after merged #605.
**Approval status:** Not required for this internal test slice; owner explicitly requested next task with fresh AGENTS.md audit on 2026-10-18.
**Approved boundaries:** Cover the *existing* app-composed Move destination sheet under a **test-only** enabled provider, authenticated matching SDK/bootstrap owner, and revocation on same-user new login cycle before any confirmation/write. Reuse real app router, `RoutineMoveFlow`, and feature controller with a controlled read-only fake gateway.
**Explicit non-changes:** No production feature-flag enablement, UI/UX change, feature/domain code, RPC grant/migration/deployment, cross-operation arbitration, source+destination refresh behavior, merge or physical device QA.

## Active Handoff

- **Planning/Implementation owner:** This bounded `apps/app` test-only slice; no concurrent implementation owner identified from remote GitHub open PRs.
- **Review owner:** Independent review pending; Draft PR #606 will be handed to reviewers after exact-head checks. No `APPROVED` review claimed.
- **Implementation ownership state:** Test implementation complete; handed to independent review. Only task/index handoff updates after source/test verification; no production code change.
- **Repository state last verified:** Protected `main@bd55f80eb0171590544205fc41a36451ab550a65`; parent #605 squash merged and post-merge Flutter CI eventually SUCCESS 5/5; no other open PR at task creation.
- **Branch:** `tnyx/issue-569-m3d3b1-move-auth-revocation`, created from exact `main@bd55f80e`.
- **Observed working tree:** GitHub API remote-only; Windows local `git status -sb`, dirt and local Flutter runner cannot be inspected. No force update, reset, stash, branch deletion or local sync.
- **PR/tracker:** [Draft PR #606](https://github.com/im-tnyx/tio-world/pull/606) open, GitHub #569 and #568 Open; Linear TNYX-81 broad Backlog with TNYX-78/80 blockers.
- **Validation:** Source/test + task handoff HEAD `70dfc1c126bd548a3f670831e738da7d1a5543c7` [Flutter CI #39147438818](https://github.com/im-tnyx/tio-world/actions/runs/39147438818) **SUCCESS 5/5** (Analyze, app-workout, nutrition-onboarding, core-wear, aggregate), plus Commit attribution guard and runner **2/2 SUCCESS**. Historical `aa3e004c` analyzer failed on one missing-braces lint and was corrected at `1b4990d1`; earlier superseded CI attempts do not count as current-pass evidence. Latest docs-only handoff HEAD after this update needs its own CI. No local Flutter runner or Windows working tree inspection.
- **Next exact action:** Verify latest docs-only PR-head checks, mark PR #606 Ready for Review, process any independent/Codex P1/P2 inline findings before separate owner `Go merge`. Keep Move release OFF.

## Discovery / Architecture

- Root `AGENTS.md`, `.ai/workflow.md`, `.ai/FEATURE_DEVELOPMENT.md`, `.github/PUSH_TEMPLATE.md`, `.github/PULL_REQUEST_TEMPLATE.md`, task index, ADR-0015, Workout canonical Routine doc, Module Ownership, auth-sensitive Supabase strategy, actual providers/shell/flow/gateway and existing app-widget fixtures inspected.
- `routineMoveReleaseEnabledProvider` in `apps/app/lib/app/composition/workout_providers.dart` is production hard `false` (must remain so).
- `shell_route.dart` app-owned `moveRoutine` pins bootstrap owner, Auth login-cycle, SDK current user and denies pending source Create; `RoutineMoveFlow` dispatches only after verified target and confirmation. Both visible surfaces consume the nullable callback. `_guardRoutineOptionsSheet` removes old-session modal contents on an Auth-cycle change.
- M3D3A #605 merged real-app release-OFF checks only; no enabled-path selector/auth-cycle regression.
- Existing `apps/app/test/app/workout_exercises_route_test.dart` uses `_routineTestAuthStateProvider` for same-account new-cycle simulation; its dormant Move fixture uses non-UUID `test-user` and a throw-on-call Fake gateway, so a separate **test-only** valid-UUID fixture is needed for real inspect.
- Chosen: add opt-in test fixture mode, leave defaults and production untouched, exercise authentic `RoutineMoveFlow` on real app-router sheet and revoke before confirmation. Alternate rejected: modify live release flag, mock the Move UI, invent gateway server privileges or combine with global mutation arbitration.

## Implementation and quality plan

- [x] Test-local UUID matching Auth/bootstrap/SDK + inert owner-scoped inspect response; reject/count all Move writes.
- [x] Two-surface widget regression on Program Detail and expanded Library: real 3-dot > Move > selector, same-account fresh login cycle dismisses private sheet and issues zero writes; first app-workout CI shard passed.
- [x] Exact source/test analyzer + Flutter CI [#39147438818](https://github.com/im-tnyx/tio-world/actions/runs/39147438818) 5/5 and required attribution 2/2; complete diff audited three scoped files, `ahead=5`, `behind=0` at source/test + prior task handoff `70dfc1c1`. Later handoff-only commits need separate checks.
- [ ] Review P1/P2 findings; keep M3D3B2 Create/Edit/Delete/Move arbitration and M3D3B3 owner-safe list refresh/UNKNOWN reconciliation as separate future slices.

## Release / security hold

No authenticated hosted Move client EXECUTE, atomic Create+Move RPC deployment, #568 canonical My Program, owner-safe full refresh, or device QA is asserted. Feature stays **OFF** and this test-only branch cannot ship an enabled Move UI.

## Final handoff

**Status:** REVIEW handoff for completed test-only behavior. Validated source/test HEAD `70dfc1c1` CI 7/7 PASS. Latest docs-only SHA, independent review and separate `Go merge` still pending; PR #606 unmerged, no feature activation.
