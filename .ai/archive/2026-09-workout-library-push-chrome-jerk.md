# Workout Library push jerk — show Library/Exercises above the shell

**Status:** Validated
**Completion date:** 2026-09-26
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
**Review owner:** Codex auto-review on PR #355; task agent self-review
**Implementation ownership state:** Complete
**Ownership transition:** Not applicable
**Repository state last verified:** 2026-09-26, after the PR #355 post-merge sync. GitHub `main`, `origin/main` and local `main` are all at `bea89d16198fde9e1a425c7ed3c34f5a256f07cd`.
**Branch:** `tnyx/workout-library-push-chrome-jerk` (merged and deleted locally and remotely at the owner's request)
**HEAD SHA:** Merged PR head `b86787b3b84bdf6a02ab0a67fe4e555f754f9d7f`. It was squash-merged to `main` as `bea89d16198fde9e1a425c7ed3c34f5a256f07cd`; the merge tree `59557677` is identical to the reviewed head.
**Observed working-tree state:** Not applicable (slice complete)
**Observed uncommitted/dirty files:** Not applicable (slice complete)
**PR / tracker:** PR #355. The fix came from an owner report in chat; no GitHub issue existed (searched). No Linear issue: the workspace hit its free issue limit and the connector is unauthorized.
**Current implementation state:** Fix, regression test and docs are complete and committed. They are validated alone and together with `main` (`TioAppBar`).
**Relevant execution surface:** `apps/app/lib/app/router.dart`, `apps/app/test/app/workout_exercises_route_test.dart`
**Validation completed at SHA:** `0dad39f9`, the tree combined with `main` `03bb578a`: `apps/app` and `apps/features/workout` analyze/test. Earlier runs at `8b6538e1` covered `apps/app` alone.
**Validation remaining:** None
**Current blocker:** None
**Open review finding IDs:** None
**Next exact action:** None for this slice.

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
- [x] Commit, push, PR #355.
- [x] Merge `main` (`03bb578a`, `TioAppBar`) into the branch and re-validate the combined tree.

## 6. Quality Review

### Validation Run

```text
Route test file (26 tests) passes with the fix.
The new jerk test fails without the fix (Expected (56.0, 538.0), Actual (0.0, 600.0)).
apps/app: flutter analyze --no-pub → No issues found; flutter test --no-pub → 380 passed
After merging main 03bb578a (TioAppBar) at 0dad39f9: apps/app analyze clean, 380 passed; apps/features/workout analyze clean, 157 passed; diff vs main limited to this slice's 6 files
git diff --check: clean
Owner device check (2026-09-26, chat):
- The owner described the symptom as the calendar showing under the system status bar for a moment, which matches the reproduced relayout.
- One interim message still reported the jerk, most likely on a build without the router change (route changes need a hot restart).
- After a restart the owner confirmed: "sahi h chek kiya".
Shell state trace with the fix (temporary test, deleted): isBottomNavVisible/isRootTopBarVisible stay true for every frame of the push and after settling
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

`PASS`: merged via PR #355 (`bea89d16`) on 2026-09-25T20:39:02Z (UTC). The gate was a matching head `b86787b3`, green CI (Analyze and test, Attribution guard runner, Commit attribution guard), 0 threads, and a Codex 👍 ("Didn't find any major issues"). The owner confirmed the fix on device. Linear was not updated: no issue exists (free issue limit), and the connector is unauthorized.
