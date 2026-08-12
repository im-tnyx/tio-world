# Programs Screen

**Surface:** Nested Phone Workout flow
**Route:** No route exists yet
**Primary owner:** `apps/features/workout`
**Status:** Planned only.

## Purpose

Let the user choose and follow a structured multi-week Program. A Program sequences scheduled Routine sessions; it is not a loose collection of unrelated Quick Start workouts.

## Target Content

- Program Library with goal, duration, experience level, required equipment, and current enrolment state.
- Program detail with week/session sequence, upcoming Routine, completed sessions, and any supported schedule adjustment.
- Enrol/leave/replace Program actions with clear effects on future scheduled sessions.
- A Program session detail that opens the selected Routine and then the active-workout flow only after explicit confirmation.

## Navigation And Rules

- Programs is a Workout-owned top-level flow, not a primary tab.
- The next scheduled Program session is a valid entry to the active-workout flow; an unselected program is not.
- Routine Library can supply a Routine to a Program editor, but Program scheduling/business rules stay in Workout.

## Data And States

- Start with curated/local program content only when the source, licensing, and schema are approved.
- Show empty availability, no active Program, schedule conflict, invalid session, loading, failed update, and offline/pending state explicitly.
- Profile-derived training defaults may suggest a Program, but never enrol or replace one without the user's confirmation.

## Acceptance Criteria

- A Program shows its session sequence and the next actionable Routine clearly.
- Starting a workout requires a selected Routine/Program session.
- Changing a Program explains which future sessions change and preserves completed history.

## Related

- [Workout](workout.md)
- [Routine Library](routine-library.md)
- [Workout Insights](workout-insights.md)
