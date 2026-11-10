# W7C-3 — Active workout mini bar when Log Workout is hidden

**Status:** VALIDATED
**Primary owner:** Owner (product) / Cursor (implementation)
**Affected platforms:** Flutter mobile Workout home / shell

## Owner Approval and Scope Boundary

**Trigger:** Unapproved product-visible UI/UX change
**Approval status:** Approved
**Approval evidence:** Owner asked for a tio-workspace-style pill above the bottom area with Resume/Discard when a workout is running but Log Workout is not on screen (including after app relaunch).
**Approved product/UI/data-shape boundaries:**
- Show a bottom mini bar/pill when a local draft or running legacy session exists and the user is on Workout home (Log Workout not visible).
- Actions: open/resume Log Workout; discard with existing confirmation.
- Hide Play FAB while the mini bar is shown.
**Explicit non-changes:** No redesign of Log Workout itself; no new recovery screens.

## Same-slice review correctness (bundled)

- Start-new replacement is fail-closed: memory clear must succeed before open; store emptiness verified.
- `removeSet` clears `activeRest` only when the resting setId is removed.
- Last-set exercise drop reindexes `_exerciseNotes` by index.

## Active Handoff

**Implementation owner:** Cursor
**Implementation ownership state:** Complete
**Branch:** `feat/w7c-3-active-workout-execution-ui`
**PR / tracker:** #740
**Validation completed at SHA:** `9db6d159`
**Validation evidence:**
- `flutter test test/presentation/workout_play_start_flow_test.dart test/presentation/active_workout_draft_controller_test.dart test/presentation/active_workout_mini_bar_test.dart test/presentation/workout_home_page_test.dart` → all passed
**Next exact action:** Wait for PR #740 CI + re-review after push
