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

## Bugfix (cold start pill)

**Problem:** After app kill/relaunch, Play still detected the durable draft, but the mini pill stayed hidden until Play was pressed.
**Cause:** First restore often ran while autoDispose controllers were still null (auth settle). Later provider rebuilds replaced the controller without calling `restoreExisting` again, so memory draft stayed empty while the store still had the workout.
**Fix:** Re-run restore whenever draft/session controllers become available or are replaced (`ref.listen` in `WorkoutHomeBranch`).

## Review fixes (post `a5fb0f2a`)

- Mini-bar elapsed guards clock rollback like Log Workout.
- Mini-bar Discard is fail-closed (memory+store clear before session discard).
- Legacy session mini-bar ticker calls `updateElapsedDuration`.
- Unreadable durable draft is unknown: Play/restore fail closed (no fresh workout, no recovery UI).

## Active Handoff

**Implementation owner:** Cursor
**Implementation ownership state:** Complete
**Branch:** `feat/w7c-3-active-workout-execution-ui`
**PR / tracker:** #740
**Validation completed at SHA:** pending push
**Validation evidence:**
- play_start_flow + draft_controller + page fail-closed load + workout_home_branch_restore → passed
**Next exact action:** Commit + push to PR #740
