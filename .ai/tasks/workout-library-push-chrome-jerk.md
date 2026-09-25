# Workout Library push jerk — show Library/Exercises above the shell

**Status:** In progress
**Primary owner:** `apps/app` (router)
**Affected platforms:** Flutter phone app

## Owner Approval and Scope Boundary

**Trigger:** None. This is a regression fix inside the already approved W6A/W3A2b routes.
**Approval status:** Not required
**Approval evidence:** On 2026-09-26 the owner reported that tapping the Library card on the Workout screen jerks the screen, while back is fine, and asked for it to be fixed.
**Approved product/UI/data-shape boundaries:** Remove the jerk. Library and Exercises must look exactly as before, and Workout Home and its chrome stay still while they slide in or out.
**Explicit non-changes:** Route paths, deep links, App Mode/onboarding gating, `ChromePolicy` values, page UI, page transitions, persistence.

## Active Handoff

**Planning owner:** Current task agent
**Implementation owner:** Current task agent
**Review owner:** Not assigned
**Implementation ownership state:** Active
**Ownership transition:** Not applicable
**Repository state last verified:** 2026-09-26; branch created from `main` at `48d91f469882aeeef16f1d24bbdc8d36263d3906` with a clean tree
**Branch:** `tnyx/workout-library-push-chrome-jerk`
**HEAD SHA:** `48d91f46` plus uncommitted slice changes
**Observed working-tree state:** Only this slice's files modified
**Observed uncommitted/dirty files:** This slice's files only
**PR / tracker:** Owner report in chat; no GitHub issue existed (searched). No Linear issue: the workspace hit its free issue limit and the connector is unauthorized.
**Current implementation state:** Fix, regression test and docs complete; locally validated
**Relevant execution surface:** `apps/app/lib/app/router.dart`, `apps/app/test/app/workout_exercises_route_test.dart`
**Validation completed at SHA:** Local runs on the working tree (see Validation Run)
**Validation remaining:** CI at the PR head
**Current blocker:** None
**Open review finding IDs:** None
**Next exact action:** Commit, push, open the PR.

## 1. Discovery

### User Outcome

Opening Library from Workout Home slides it in smoothly, with nothing underneath jumping.

### Success Criteria

- While Library slides in, Workout Home keeps its vertical geometry, and the shell top bar and bottom navigation stay where they are.
- The same holds while Library slides out on back.
- The settled Library and Exercises layouts are unchanged.
- Deep links and gating behave as before.

### Scope

- `apps/app/lib/app/router.dart`
- `apps/app/test/app/workout_exercises_route_test.dart`
- `docs/screens/library.md`
- `docs/screens/exercise-search.md`

### Non-Goals

See Explicit non-changes.

## 2. Codebase Exploration

### Verified Evidence

- Library and Exercises were child routes of the Workout branch, rendered inside the branch navigator.
- Pushing Library rebuilt the shell with its path. `shellChromePolicyForPath` then returned `noBottomBar`, so `TioShell` removed its top bar and bottom navigation in the first frame of the push.
- Workout Home, still visible during the transition, relaid out from y 56–538 to y 0–600. That relayout was the jerk. It was reproduced by the new route test, which fails on `main` with exactly that change.
- Settings and Profile pages are root-navigator routes that cover the shell, and they do not show the problem.

## 3. Clarification

### Decisions Required or Made

| Decision | Status | Rationale | Owner |
|---|---|---|---|
| Keep the routes nested under `/workout`, but set `parentNavigatorKey: rootNavigatorKey` | Made | Same covering behavior as Settings. The paths, deep-link stack and `_owningShellPath` gating are unchanged | Task agent |

## 4. Architecture Design

### Chosen Approach

Library and Exercises render on the root navigator above the shell. The shell keeps its main chrome underneath and the pushed page covers it, so nothing underneath relayouts.

### Ownership and Data Flow

Router wiring only (`apps/app`). The feature pages are unchanged.

### Alternative Rejected

- **Top-level routes outside the shell:** a deep link would lose the Workout tab beneath it, and `/workout` gating would need rewiring.
- **Animating chrome hide/show in `TioShell`:** still relayouts the page underneath, and is a design-system change.

### Failure and Accessibility States

No semantics or focus change. Back and Android system back pop the root navigator.

## 5. Implementation Plan

- [x] Regression test that reproduces the jerk. It fails on `main`: Workout Home `(56, 538)` → `(0, 600)`.
- [x] `parentNavigatorKey: rootNavigatorKey` on both routes.
- [x] Deep-link back test asserts the chrome is present mid-transition.
- [x] Settled-geometry comparison before and after (temporary test, deleted).
- [x] Router comment and route docs updated.
- [x] `apps/app` analyze/tests.
- [ ] Commit, push, PR.

## 6. Quality Review

### Validation Run

```text
Route test file (26 tests) passes with the fix.
The new jerk test fails without the fix (Expected (56.0, 538.0), Actual (0.0, 600.0)).
apps/app: flutter analyze --no-pub → No issues found; flutter test --no-pub → 380 passed
git diff --check: clean
Owner check on device (2026-09-26, chat): "ab sahi h" after the change — the calendar no longer flashes under the system status bar
Temporary settled-geometry comparison, identical before and after:
- Library: page 0,0-800,600; AppBar 0,0-800,80; Exercises row 16,92-784,164
- Exercises: page 0,0-800,600; first row 16,88-321,109
```

### Review Findings and Resolution

| ID | Severity | Status | Finding | Observed at SHA | Evidence or follow-up |
|---|---|---|---|---|---|
| | | | | | |

## 7. Final Handoff

### Changed Files

See Scope, plus this brief and the `.ai/tasks/README.md` row.

### Actual Behavior

Library and Exercises open above the shell; Workout Home and its chrome stay still during push and pop.

### Known Limitations

Verified with widget tests and the owner's device check.

### Final Status

`IN PROGRESS`
