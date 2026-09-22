# TNYX-255 — Workout Home calendar-only shell foundation

## Status

READY FOR IMPLEMENTATION

## Baseline

- Issue: TNYX-255
- Base branch: `main`
- Base SHA: `dede901e816b994de72fc5653ca82235710c2905`
- Work branch: `tnyx/tnyx-255-w05-workout-home-calendar-only-shell-foundation`
- W0 gate: TNYX-77 Done / READY
- Open Workout PR overlap at audit: none found
- Existing TNYX-255 branch overlap before branch creation: none found
- Supabase schema change: none allowed or required

## Owner-approved slice

Create the smallest real Workout root presentation shell and reuse the existing Core `TioDateCalendar`. This is a presentation foundation only. It must not invent Workout domain or persistence truth.

## Source-of-truth boundaries

- `apps/features/workout` owns Workout presentation state and the root Workout surface.
- `apps/core` owns `TioDateCalendar` and generic calendar mechanics.
- app composition owns the resolved app-global Calendar Preferences value.
- TNYX-78 remains authoritative for canonical Workout domain/persistence.
- TNYX-79 remains authoritative for domain-backed selected-day Workout behavior and calendar decorations.
- `docs/screens/workout.md` describes the later target surface; its target sections are not current runtime truth.

## Allowed implementation

- real Workout root page/shell;
- caller-owned `selectedDate`;
- caller-owned `localToday`;
- caller-owned bounded `minDate` / `maxDate` suitable for navigation only;
- existing `TioDateCalendar`;
- resolved global first-day-of-week passed through app composition;
- compact/month display behavior already owned by Core;
- Today and selected-date semantics already owned by Core;
- tests for selected date, Today, range and week-start composition.

## Forbidden in this slice

- new Workout-specific calendar;
- Exercise/Routine/Program/TrainingPlan domain or persistence;
- PlannedWorkout/WorkoutSession persistence;
- completion fill, schedule dots, Rest Day truth, Week x/y or history markers;
- fake/mock production Workout data;
- speculative Supabase migrations/tables;
- feature-owned duplicate first-day-of-week preference;
- Workout domain imports into Core;
- treating UI as design-locked before owner review.

## Implementation shape

```text
apps/app composition
  -> resolvedFirstDayOfWeek
  -> Workout root page
       -> caller-owned selectedDate/localToday/range
       -> Core TioDateCalendar
```

The exact route/composition seam must be taken from current runtime source, not guessed from docs.

## Validation

Before handoff:

- format/analyze affected Dart packages;
- run focused Workout tests;
- run affected app routing/composition tests;
- run relevant Core calendar tests only if Core source changes (Core source changes are not expected);
- verify no Supabase migration/schema diff;
- verify no fake Workout decoration/data;
- verify branch remains scoped to TNYX-255.

## UI approval gate

This slice may establish the functional shell and reuse the approved shared calendar. Any new Workout-specific layout/pixel treatment remains provisional until owner review. Do not declare the Workout Home design locked from this slice.
