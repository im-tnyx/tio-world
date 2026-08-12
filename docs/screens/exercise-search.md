# Exercise Search Screen

**Surface:** Nested phone Workout flow; never a primary tab
**Route:** No route exists yet
**Primary owner:** `apps/features/workout`
**Status:** Planned only. The current Workout route is a shell placeholder.

## Purpose

Let the user find a known exercise when building, editing, or reviewing a Routine or Program session. This screen is not a direct workout-start surface and it does not replace the Routine/Program-first flow.

## Entry And Exit Flow

```text
Workout
  -> Routine or Program
  -> add / replace exercise in a selected session
  -> Exercise Search
  -> exercise detail / confirm selection
  -> return to the owning Routine or Program editor
```

- Exercise Search is not a bottom tab and is not launched as the first Workout screen.
- Selecting an exercise only adds or replaces it in the in-progress Routine/Program edit state. It does not start a workout session.
- The active workout flow may show exercise information for its already-selected exercises, but it must not turn Exercise Search into an unscoped global Quick Start path.

## First-Slice Data Source

The first version uses a versioned, bundled JSON exercise catalog owned by `apps/features/workout`, for example a feature asset such as `assets/exercises.json`. This is a delivery approach, not an existing file or runtime capability.

The implementation task must define and validate the JSON schema before adding data. At minimum, each record needs a stable ID, display name, primary muscle group, equipment, category, and safe instruction/reference fields. Optional media, secondary muscles, alternatives, and difficulty require the same schema and licensing review.

## Target Content

- Search field with debounced, local matching by display name and approved aliases.
- Filters such as muscle group, equipment, category, and difficulty only when the bundled schema supports them.
- Result list with name, key metadata, and a concise visual/text cue.
- Exercise detail with validated instructions, equipment, target area, and selection confirmation.
- Empty search, no-filter-match, malformed/missing catalog, and unavailable-media fallback states.

## Data And Safety Boundaries

- Treat the JSON catalog as application content, not an unvalidated API response or medical advice.
- Every catalog version needs source/attribution and licence verification before it is shipped.
- Parse and validate catalog data behind a Workout-owned repository or data source; widgets do not read JSON directly.
- No remote search, user-generated exercise database, image download, analytics, or backend API is implied by the first slice.
- The screen must not claim injury prevention, medical suitability, or personalized form advice.

## Acceptance Criteria

- A user reaches Exercise Search only from a selected Routine/Program exercise-selection context.
- Search, filter, selection, and return preserve the editor state safely.
- The catalog supports stable IDs and schema validation, with a clear fallback when content cannot load.
- Text labels and details remain usable without images, colour, or network access.

## Related

- [Workout](workout.md)
- [Screen catalog](README.md)
- [Module ownership](../MODULE_OWNERSHIP.md)
