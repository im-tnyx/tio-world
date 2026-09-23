# TNYX-255 — Workout Home calendar-only shell foundation

## Status

REVIEW — IMPLEMENTATION + CI PASS / DEVICE REVIEW DEFERRED

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

## Implementation handoff

- Draft PR: #320
- Validated head: `fd33ceb8c4ee73dab430d7985df88da522314b80`
- Branch compare at validation: 6 commits ahead / 0 behind `main`.
- GitHub Flutter CI run 2690: PASS.
- Analyze Flutter packages: PASS.
- Analyze Dart packages: PASS.
- Test Flutter packages: PASS.
- Test Dart packages: PASS.
- PR mergeability at validation: mergeable.
- Review comments/reviews at validation: none.
- Core calendar source changes: none.
- Supabase migration/schema changes: none.

Functional validation is complete. The remaining gate is owner UI review/confirmation; this slice must not be treated as design-locked before that review.


## Owner-approved continuation — Workout calendar top-bar parity

Owner approval received on 2026-09-23 to keep the shared calendar UI and add the same navigation treatment already used by Meal Diary:

- centred compact visible month/year label (for example `Sep 26`), derived from the calendar viewport rather than selected date;
- the same current-day calendar glyph on the right-side status action cluster when selection or viewport is away from Today;
- pressing the Today action selects the current local date and jumps the shared calendar back to the current week/month;
- when Today is selected and visible, the Today action is hidden;
- reuse existing Core `TioDateCalendar` mechanics and the existing app-shell Today glyph treatment; do not create a Workout-specific calendar visual language.

This continuation also closes the date-freshness seam required for the Today action: the Workout caller refreshes its local-day truth across midnight/app resume, following the already-audited Meal Diary pattern.

Still out of scope: Workout completion/schedule dots, Rest Day, Week x/y, Training Plan behavior, history, persistence, Supabase schema, Explore/Library, or W2 selected-day domain state.

### Validation additions

- focused Workout date-state tests for viewport month, Today-action visibility, jump-to-Today, and local-day refresh;
- Workout page test proves Core controller/range/week-start wiring;
- app composition test proves `ShellTab.workout` renders the compact visible month and the same Today glyph/action behavior;
- latest-head Flutter CI must pass before handoff.


## Final validation — top-bar parity continuation

Validated runtime/test head: `2984084c3bcb2ba688efb2ec85e585ffc5dfe1a3`

GitHub Flutter CI run 2703: PASS

- workspace bootstrap: PASS;
- Flutter analyze: PASS;
- Dart analyze: PASS;
- Flutter tests: PASS;
- Dart tests: PASS;
- source-head branch audit: 19 commits ahead / 0 behind `main`;
- PR mergeability before handoff: mergeable;
- Core calendar source changes: none;
- Supabase migration/schema changes: none;
- fake Workout completion/schedule/rest/history state: none.

The Workout shell now mirrors the approved Meal Diary calendar navigation contract: centred compact visible month/year, viewport-aware return-to-Today action using the same current-day calendar glyph treatment, jump-to-Today behavior, app-global week start, and local-day refresh across midnight/app resume.

Owner confirmed the existing calendar and approved this exact Meal Diary-parity top-bar direction. A later physical-device/pixel review is deferred because the owner cannot inspect the device UI at this time; do not treat that deferred check as permission to redesign the locked parity behavior.
