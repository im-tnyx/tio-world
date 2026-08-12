# Routine Library Screen

**Surface:** Nested Phone Workout flow
**Route:** No route exists yet
**Primary owner:** `apps/features/workout`
**Status:** Planned only.

## Purpose

Help the user browse, inspect, choose, and later create reusable single-session Routines. A Routine is the smallest workout plan unit; it can be scheduled directly or placed inside a Program.

## Target Content

- Search, filter, and categories for available Routines.
- Routine cards with title, objective, estimated duration, equipment, exercise count, and clear saved/scheduled state when those values exist.
- Routine detail: exercise order, planned sets/reps/rest, notes, and an explicit select/schedule action.
- Create/edit Routine entry. Adding or replacing an exercise opens the nested [Exercise Search](exercise-search.md) screen.

## Navigation And Rules

- Routine Library is reached from Workout in the guided layout. After the Library exists, a future custom layout may promote its canonical route as a shortcut without changing Workout ownership.
- Selecting a Routine creates a deliberate next step: schedule it, add it to a Program, or start that selected Routine's session. There is no global Quick Start action.
- A user returns to the exact Library filter/scroll state after inspecting a Routine.
- Whether entered from Workout, Home, or a promoted shortcut, Library uses the same filter/detail state and Workout-owned start command.

## Data And States

- Routine and exercise composition stay owned by Workout.
- Start with empty, loading, no-filter-match, invalid Routine, failed save, and offline/pending-save states.
- A user-created Routine must distinguish unsaved edits from a completed saved version once persistence exists.

## Acceptance Criteria

- Exercise selection is nested in Routine/Program editing and cannot start a workout by itself.
- A selected Routine is explicit before any active-workout session begins.
- List and detail remain usable with text-only metadata and accessible focus order.
- Promoting Library changes its navigation entry and active-destination presentation, not its route data, filters, save behavior, or active-workout ownership.

## Related

- [Workout](workout.md)
- [Programs](programs.md)
- [Exercise Search](exercise-search.md)
