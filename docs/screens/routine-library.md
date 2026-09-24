# Routines (Library → Routines)

**Surface:** Nested Phone Workout flow; the Routines section of [Library](library.md)
**Route:** No route exists yet
**Primary owner:** `apps/features/workout`
**Status:** Planned only.

## Purpose

Help the user browse, inspect, choose, and later create reusable single-session Routines. A Routine is the smallest workout plan unit; it can be scheduled directly or placed inside a Program.

This document covers the Routines capability and the Routines section reached through `Library → Routines`. It does not own the top-level Library route; see [Library](library.md). The filename is kept for link stability.

## Target Content

- Search, filter, and categories for available Routines.
- Routine cards with title, objective, estimated duration, equipment, exercise count, and clear saved/scheduled state when those values exist.
- Routine detail: exercise order, planned sets/reps/rest, notes, and an explicit select/schedule action.
- Create/edit Routine entry. Adding or replacing an exercise opens the nested [Exercise Search](exercise-search.md) screen.

## Navigation And Rules

- Routines are reached from Workout Home → Library → Routines, and from Routine/Program builders where a Routine is chosen. Library route promotion into future custom navigation is governed by [Library](library.md), not by this document.
- Selecting a Routine creates a deliberate next step: schedule it, add it to a Program, or start that selected Routine's session. There is no global Quick Start action.
- A user returns to the exact Routines list search/filter/scroll state after inspecting a Routine.
- Whether entered from Library, Workout Home or a builder, Routines use the same Routines browse/list state (search, filter, detail) and Workout-owned start command.

## Data And States

- Routine and exercise composition stay owned by Workout.
- Start with empty, loading, no-filter-match, invalid Routine, failed save, and offline/pending-save states.
- A user-created Routine must distinguish unsaved edits from a completed saved version once persistence exists.

## Acceptance Criteria

- Exercise selection is nested in Routine/Program editing and cannot start a workout by itself.
- A selected Routine is explicit before any active-workout session begins.
- List and detail remain usable with text-only metadata and accessible focus order.
- Library entry points (Workout Home or a future promoted Library) change only navigation presentation, not Routine data, Routines browse/list state, save behavior, or active-workout ownership.

## Related

- [Workout](workout.md)
- [Library](library.md)
- [Programs](programs.md)
- [Exercise Search](exercise-search.md)
