# Workout Insights Screen

**Surface:** Nested Phone Workout flow
**Route:** No route exists yet
**Primary owner:** `apps/features/workout`
**Status:** Planned only; all visualizations require recorded workout history.

## Purpose

Explain training history, balance, and consistency through three complementary views. It is a Workout feature screen, not a generic analytics tab and not a medical recovery assessment.

## Target Views

| View | User question | Minimum behavior |
| :--- | :--- | :--- |
| Muscle heatmap | Which body regions have recorded training volume? | Body-region display, legend, period selection, and text values. |
| Training radar map | How balanced is recorded training across the approved dimensions? | Radial visual plus the same values in a table/list; no colour-only interpretation. |
| Workout calendar | When were sessions planned and completed? | Week/month navigation, accessible date labels, and planned/completed/rest states. |

The screen may use a segmented control or sub-routes; it must not create a new bottom-navigation tab.

## Data And Safety Boundaries

- Inputs are recorded Workout history and approved schedule data only.
- No history shows an explanatory empty state and links to Routine Library or Programs.
- Recovery context can appear only after the independent Recovery contract is approved; it must be labelled and never presented as medical readiness.
- Charts and maps need screen-reader summaries, high-contrast treatment, reduced-motion-safe transitions, and values that remain understandable without colour or graphics.

## Acceptance Criteria

- Every visual names its date range, metric, and source data.
- Heatmap, radar map, and calendar agree with the underlying recorded history.
- Missing, partial, stale, and failed-to-load data cannot look like a real zero-value result.

## Related

- [Workout](workout.md)
- [Recovery](recovery.md)
- [Progress](progress.md)
