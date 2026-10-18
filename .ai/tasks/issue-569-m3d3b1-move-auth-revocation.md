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
- **Review owner:** Not assigned; independent review after exact-head validation.
- **Implementation ownership state:** Active; prior #605 merged and source/test ownership closed.
- **Repository state last verified:** Protected `main@bd55f80eb0171590544205fc41a36451ab550a65`, parent #605 squash merged. At planning audit post-merge `main` CI checks: core-wear/analyze succeeded, app-workout/nutrition-onboarding still in progress. Read current CI again before review.
- **Branch:** `tnyx/issue-569-m3d3b1-move-auth-revocation`, created from exact `main@bd55f80e`.
- **Observed working tree:** GitHub API remote-only; Windows local `git status -sb`, dirt and local Flutter runner cannot be inspected. No force update, reset, stash, branch deletion or local sync.
- **PR/tracker:** GitHub #569 Open; #568 My Program Open; Linear TNYX-81 Backlog with TNYX-78/80 blockers. No other open PR at task start.
- **Next exact action:** Add strictly test-local valid UUID auth/SDK/bootstrap Move fixture, real read-only Move inspect gateway, and app-router selector dismissal regression across both Routine action surfaces. Verify Flutter CI at new exact HEAD before review handoff. Do not merge or activate.

## Discovery / Architecture

- Root `AGENTS.md`, `.ai/workflow.md`, `.ai/FEATURE_DEVELOPMENT.md`, `.github/PUSH_TEMPLATE.md`, `.github/PULL_REQUEST_TEMPLATE.md`, task index, ADR-0015, Workout canonical Routine doc, Module Ownership, auth-sensitive Supabase strategy, actual providers/shell/flow/gateway and existing app-widget fixtures inspected.
- `routineMoveReleaseEnabledProvider` in `apps/app/lib/app/composition/workout_providers.dart` is production hard `false` (must remain so).
- `shell_route.dart` app-owned `moveRoutine` pins bootstrap owner, Auth login-cycle, SDK current user and denies pending source Create; `RoutineMoveFlow` dispatches only after verified target and confirmation. Both visible surfaces consume the nullable callback. `_guardRoutineOptionsSheet` removes old-session modal contents on an Auth-cycle change.
- M3D3A #605 merged real-app release-OFF checks only; no enabled-path selector/auth-cycle regression.
- Existing `apps/app/test/app/workout_exercises_route_test.dart` uses `_routineTestAuthStateProvider` for same-account new-cycle simulation; its dormant Move fixture uses non-UUID `test-user` and a throw-on-call Fake gateway, so a separate **test-only** valid-UUID fixture is needed for real inspect.
- Chosen: add opt-in test fixture mode, leave defaults and production untouched, exercise authentic `RoutineMoveFlow` on real app-router sheet and revoke before confirmation. Alternate rejected: modify live release flag, mock the Move UI, invent gateway server privileges or combine with global mutation arbitration.

## Implementation and quality plan

- [ ] Test-local UUID matching Auth/bootstrap/SDK + inert owner-scoped inspect response; reject/count all Move writes.
- [ ] One focused two-surface widget regression: open actual Routine 3-dot > Move > destination selector, change same-account login cycle, assert stale selector removed and write-count zero.
- [ ] Scope and branch ancestry/changed-file audit, analyzer + widget/test shard via CI; record exact SHA and results.
- [ ] Review P1/P2 findings; keep M3D3B2 Create/Edit/Delete/Move arbitration and M3D3B3 owner-safe list refresh/UNKNOWN reconciliation as separate future slices.

## Release / security hold

No authenticated hosted Move client EXECUTE, atomic Create+Move RPC deployment, #568 canonical My Program, owner-safe full refresh, or device QA is asserted. Feature stays **OFF** and this test-only branch cannot ship an enabled Move UI.

## Final handoff

**Status:** IN PROGRESS, validation and review not yet run for this branch.
