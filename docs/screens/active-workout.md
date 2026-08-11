# Active Workout Screen

**Surface:** Nested Phone Workout execution flow
**Route:** No route exists yet
**Primary owner:** `apps/features/workout`
**Status:** Planned only; no workout execution or local persistence is verified in current source.

## Purpose

Guide the user through one already-selected Routine or Program session and record the work performed. It is not a direct entry screen and it does not provide a standalone Quick Start workout.

## Entry Rule

An active session can begin only after the user explicitly selects:

- a Routine from [Routine Library](routine-library.md), or
- a scheduled session in a [Program](programs.md).

The screen shows the selected plan context at the top so the user knows what is being performed.

## Target Content

- Session header: selected Routine/Program, elapsed time, finish/discard action, and truthful save/sync status.
- Ordered exercise list from the selected plan.
- Per-exercise set input for the approved values such as weight, reps, and completion state.
- Rest timer that is tied to an action only when the configured workout behavior supports it.
- Exercise information from the selected catalog entry; changing the plan uses an explicit edit flow, not unscoped search.
- Finish review with incomplete-set handling before the session is saved to history.

## Data And State Boundaries

- Workout owns session state, validation, rest timing, completion rules, and repository events.
- The first implementation must decide local persistence and pending-sync behavior before it claims reliable history.
- Back/close must offer resume, discard, or save-as-incomplete behavior when safe; it must never lose recorded user input silently.
- Require loading-plan, invalid-plan, timer interruption, failed local save, pending sync, offline, and finish-confirmation states.
- Active-session state is independent from the selected navigation layout. If Workout or Library is hidden/reordered, a persistent shell/Home Resume entry must still reach this canonical session.
- A mode/layout change during a live session preserves recorded input and cannot start a duplicate session. Any destructive discard remains an explicit Workout-owned confirmation.

## Acceptance Criteria

- The selected Routine/Program session is visible and cannot change invisibly mid-workout.
- Set changes have accessible labels, validation feedback, and a clear saved/pending state.
- Finishing produces a Workout-owned history event that can later feed Workout Insights and Progress.
- No active session is created from a global Quick Start button.
- Resume from Home, Workout, Library, or persistent chrome restores the same session and saved/pending state.

## Related

- [Workout](workout.md)
- [Routine Library](routine-library.md)
- [Programs](programs.md)
- [Workout Insights](workout-insights.md)
