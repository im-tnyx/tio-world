# Feature Task: W7C-2 Active Workout Resume/Recovery Screen and Route Foundation

**Status:** Validated; awaiting owner merge decision
**Primary owner:** Codex
**Affected platforms:** Flutter phone (`apps/features/workout`, `apps/app`, `apps/core` routing contracts)

## Owner Approval and Scope Boundary

**Trigger:** New independently scoped product task/feature slice; unapproved product-visible UI/UX change
**Approval status:** Approved
**Approval evidence:** Owner approval in the implementation request dated 2026-11-08 for the bounded W7C-2 Active Workout resume/recovery screen and `/workout/active` route foundation.

**Approved product/UI/data-shape boundaries:**
- Add `ActiveWorkoutPage` owned by `apps/features/workout`.
- Register authenticated `/workout/active` through existing `apps/core` and `apps/app` routing contracts with `NoBottomNav` presentation.
- Consume the existing `activeWorkoutControllerProvider` and actual `WorkoutSessionSnapshot` data.
- Render restoring/loading, active, paused, no-session, reconciliation-required, terminal and auth-invalidated states.
- Use existing controller-backed actions where current APIs and approved behavior support them; provide explicit reconciliation retry.
- Reuse existing Core components, typography, spacing, radius and theme contracts.

**Explicit non-changes:**
- No Routine Detail Start CTA, new workout creation or temporary production launcher.
- No Program/TrainingPlan launcher and no W3/W4 feature implementation.
- No new controller, timer, repository, workout engine, schema, migration, RLS/RPC or hosted Supabase change.
- No Wear OS, Apple Watch, AI integration or unrelated visual redesign/design-system infrastructure.

## Active Handoff

**Planning owner:** Codex
**Implementation owner:** Codex
**Review owner:** im-tio
**Implementation ownership state:** Active
**Ownership transition:** Previous read-only planning owner → Codex implementation owner after explicit owner approval
**Repository state last verified:** 2026-11-08 12:34 IST
**Branch:** `feat/w7c-2-active-workout-screen-route`
**HEAD SHA:** `42dddd59f34c96d3350cbc6415368da5a0b41d01`
**Observed working-tree state:** Clean branch; one focused PR commit series ahead of verified `origin/main`
**Observed uncommitted/dirty files:** None
**PR / tracker:** GitHub #738 (open); GitHub #737 focused tracker; parent Linear TNYX-84; Linear child creation blocked by workspace free-issue limit
**Current implementation state:** W7C-2 page, route, auth/chrome integration and focused tests are implemented and pushed. No automatic merge performed.
**Relevant execution surface:** `apps/features/workout`, `apps/app/lib/app/routing`, `apps/app/lib/app/composition`, `apps/core/lib/src/routing`
**Validation completed at SHA:** `42dddd59f34c96d3350cbc6415368da5a0b41d01` (local package analysis; exact-head CI and docs hygiene successful)
**Validation remaining:** Owner-authorized independent review by `i-the`; local Flutter widget tests remain unavailable on this Windows host because the Flutter wrapper hangs and direct tool invocation fails on the configured Git child process.
**Current blocker:** Merge remains intentionally held pending independent review/owner decision. W3/W4 remain blockers for future start/launcher flows.
**Open review finding IDs:** None for W7C-2
**Next exact action:** Obtain independent `i-the` review on PR #738, then recheck exact-head protections before any owner-authorized merge.

## Global UI / Design-System Guardrail

Before visual implementation, follow `.ai/tasks/design-system-token-consolidation.md`, `apps/core/lib/src/theme/README.md`, and `apps/features/AGENTS.md`. Use the public `package:tio_core/core.dart` boundary and existing `TioAppBar`, `TioCard`/`TioGroupCard`, `TioButton`, confirmation and status components. Do not add a feature-local token bag or change unrelated rendered geometry.

## 1. Discovery

### User Outcome

An authenticated user can safely open `/workout/active` to resume or recover an existing active/paused WorkoutSession, understand unavailable/reconciliation/auth states, and use only the already-supported controller actions.

### Success Criteria

- Existing active and paused sessions render their persisted `WorkoutSessionSnapshot` data.
- Restore loading, no-session, reconciliation, terminal and auth-invalidated states are explicit and safe.
- Reconciliation failure has an explicit retry path without blind replay.
- Account switch/logout redacts stale session state and disposes controller/listeners safely.
- The route is authenticated, focused, `NoBottomNav`, and supports safe Back navigation.
- No duplicate timers, controllers, repositories or workout engines are introduced.

### Scope

Feature-owned page, app-owned route registration, existing provider/controller integration, focused tests and required validation.

### Non-Goals

Routine/Program launchers, W3/W4, schema/RLS/RPC, hosted deployment, Wear/watch, AI, new design-system infrastructure and unrelated docs governance cleanup.

## 2. Codebase Exploration

### Verified Evidence

- W7C-1 merged in PR #736 at `main@01e8648312a9e52559c05bcaad16d23e1d0bf4be`; PR head `d13e2a314566bdf980befdbf9b93dd589522f02b` had successful Docs Hygiene and Flutter CI and independent approval.
- `apps/features/workout/lib/src/presentation/controllers/active_workout_controller.dart` and `active_workout_state.dart` provide restore, lifecycle, set, timer and reconciliation APIs.
- `apps/app/lib/app/composition/workout_providers.dart` owns the authenticated owner/login-cycle-bound `activeWorkoutControllerProvider`.
- `apps/core/lib/src/routing/routes/app_routes.dart` has Workout child route contracts but no `/workout/active` route yet.
- `apps/app/lib/app/routing/shell/shell_route.dart` registers Workout child routes on `rootNavigatorKey` for `NoBottomNav` focused presentation.
- `WorkoutSessionSnapshot` contains frozen routine/exercise display data, so resume rendering does not require current W3/W4 queries.
- Linear `TNYX-84` is `In Progress`; `TNYX-80` is `In Progress`; `TNYX-81` is `Backlog` and remains the broader start/launcher dependency chain.
- No dedicated W7C-2 Linear or GitHub issue existed during reconciliation. GitHub Issue #737 is now the focused tracker; Linear creation was blocked by the workspace free-issue limit.

### Existing pattern to follow

`WorkoutHomePage`, the existing Workout shell child routes, `activeWorkoutControllerProvider`, and public Core components documented in `apps/core/lib/src/theme/README.md`.

### Tests or validation already present

W7C-1 controller and provider lifecycle tests cover the underlying state/ownership behavior. W7C-2 page, routing and deep-link tests remain to be added.

## 3. Clarification

### Decisions Required or Made

| Decision | Status | Rationale | Owner |
|---|---|---|---|
| Resume/recovery-only route with no launcher | Approved | Avoids unapproved W3/W4 start flow and consumes canonical persisted snapshot | Owner |
| Feature owns screen; app owns route composition | Approved | Matches module ownership and keeps Workout business logic out of shell | Architecture |
| Controller owns elapsed/rest timing | Approved | Prevents duplicate timers and preserves W7C-1 lifecycle guarantees | Architecture |
| No new Core component/token contract | Approved | Existing Core surface covers this one-off workflow | Architecture |

## 4. Architecture Design

### Chosen Approach

Add a feature-owned `ActiveWorkoutPage` that watches `activeWorkoutControllerProvider`, invokes one restore path on mount, renders immutable controller state, and delegates supported actions. Register `/workout/active` as an authenticated Workout child route on the root navigator with `NoBottomNav` chrome.

### Ownership and Data Flow

```text
Authenticated route
  -> ActiveWorkoutPage (Workout feature)
  -> activeWorkoutControllerProvider (app composition)
  -> ActiveWorkoutController (Workout feature)
  -> WorkoutSessionRepository
  -> existing persistence gateway
```

### Alternative Rejected

- A route-local controller/timer was rejected because it would split lifecycle ownership and permit duplicate actions.
- A new launcher or Routine/Program lookup was rejected because it expands into W3/W4 and is outside this approval.
- A new shared Core Active Workout component was rejected because reuse evidence is limited to this workflow.

### Failure and Accessibility States

Explicit restoring, unavailable/no-session, reconciliation retry, terminal, auth-invalidated and action-pending states; semantic labels for status/action controls; disabled/loading actions during pending commands; light/dark and compact-width layout coverage.

## 5. Implementation Plan

- [x] Add `ActiveWorkoutPage` and export it through the Workout presentation barrels.
- [x] Register `AppRoutes.workoutActive` and `/workout/active` through existing shell routing/chrome policy.
- [x] Integrate provider restore, state rendering, supported actions, retry and safe Back behavior.
- [x] Add focused page/widget tests for active, paused, restore, no-session, reconciliation, terminal and auth-invalidated states.
- [x] Add routing/provider lifecycle tests for auth gating, account switch/logout, `NoBottomNav`, Back and disposal.
- [x] Run focused Dart analysis, review full diff, commit/push and open PR #738 against `main`.

## 6. Quality Review

### Validation Run

```text
Repository preflight: PASS (`main` and `origin/main` at 01e8648312a9e52559c05bcaad16d23e1d0bf4be; clean worktree before branch creation)
W7C-1 merged PR #736: PASS (Docs Hygiene CI and Flutter CI successful at PR head)
W7C-2 implementation validation: PASS at `42dddd59f34c96d3350cbc6415368da5a0b41d01` for `dart analyze --format=machine .` in `apps/features/workout`, `apps/core` and `apps/app`; `git diff --check` PASS.
Exact-head PR CI: PASS (`Flutter CI` run `42454495092` / #4447; `Docs Hygiene CI` run `42454495110` / #559; all required jobs successful).
Review-thread reconciliation: PASS; all three W7C-2 inline threads resolved, including the action-error rendering finding and two test findings.
```

### Acceptance Evidence (substantive scope)

| Criterion | Changed behavior / file | Test or manual evidence + actual result | Observed SHA / environment | Remaining risk |
|---|---|---|---|---|
| Active/paused snapshot rendering | `active_workout_page.dart`; `active_workout_page_test.dart` | Focused tests committed; exact-head app-workout shard PASS | `42dddd59` / Flutter CI | Local widget runner unavailable |
| Restore/no-session/reconciliation states | `active_workout_page.dart`; focused page tests | Exact-head app-workout shard PASS | `42dddd59` / Flutter CI | Local widget runner unavailable |
| Auth and provider lifecycle | `shell_route.dart`; session route policy tests | Exact-head app-workout shard PASS; static analysis PASS | `42dddd59` | Device/account-switch runtime evidence not run |
| Route chrome/deep-link/Back | `app_routes.dart`, `router.dart`, route tests | Exact-head app-workout shard PASS; Docs Hygiene PASS | `42dddd59` | Hosted/device visual evidence not run |

### Review Provenance

**Review source / link:** [GitHub PR #738](https://github.com/im-tnyx/tio-world/pull/738)
**Reviewer / relation to implementer:** im-tio / independent technical reviewer
**Diff or commit SHA actually reviewed:** Automated review feedback reconciled through `42dddd59f34c96d3350cbc6415368da5a0b41d01`; independent reviewer `i-the` remains requested/pending.
**Review result and finding IDs/dispositions:** Three automated P2 threads resolved: action errors rendered in active/paused states; terminal test uses actual completion transition; confirmation finder scoped to `BottomSheet`.
**Independent review?** Pending (`i-the` requested; no submitted independent approval yet)
**Limitations and unmet required gates:** Local Flutter widget tests did not complete on this Windows host. Cursor security/approval agents were `neutral` because their weekly quota was exhausted; no Supabase-sensitive code changed. Independent review and owner merge authorization remain open.

### Review Findings and Resolution

| ID | Severity | Status | Finding | Observed at SHA | Evidence or follow-up |
|---|---|---|---|---|---|
| | | | | | |

## 7. Final Handoff

### Changed Files

`.ai/tasks/w7c-2-active-workout-screen-route.md`, `.ai/tasks/w7c-1-active-workout-controller.md`, `.ai/tasks/README.md`, `apps/features/workout/lib/src/presentation/pages/active_workout_page.dart`, `apps/features/workout/lib/src/presentation/pages/pages.dart`, `apps/features/workout/test/presentation/active_workout_page_test.dart`, `apps/core/lib/src/routing/routes/app_routes.dart`, `apps/core/test/app_routes_test.dart`, `apps/app/lib/app/router.dart`, `apps/app/lib/app/routing/shell/shell_route.dart`, `apps/app/test/app/session/app_session_route_policy_test.dart`, `apps/app/test/app/workout_exercises_route_test.dart`.

### Actual Behavior

Authenticated `/workout/active` now renders persisted active/paused `WorkoutSessionSnapshot` data with explicit restoring, no-session, reconciliation retry, terminal and auth-invalidated states. It uses `TioAppBar`, `TioCard`, `TioButton`, existing confirmation patterns and `NoBottomNav`; action loading/duplicate prevention, action-error feedback, stale-session redaction and safe Back are covered without introducing a new controller, timer, repository or launcher.

### Known Limitations

Linear child issue creation is blocked by the workspace free-issue limit. GitHub Issue #737 is the active focused tracker. W3/W4-dependent launchers remain intentionally excluded.

### Final Status

`REVIEW`
