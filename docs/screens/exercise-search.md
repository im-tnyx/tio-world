# Exercises Screen And Exercise Picker

**Surface:** Nested phone Workout flow; never a primary tab
**Route:** No route exists yet
**Primary owner:** `apps/features/workout`
**Status:** Planned only. The current Workout route is a shell placeholder.

## Purpose

One Exercise capability serves two presentation contexts. Both use the same canonical `Exercise`, the same Workout-owned Exercise repository/catalog data and the same search/filter primitives where appropriate; neither creates a second Exercise truth.

1. **Dedicated Exercises screen** — browse, search, filter and open Exercise detail. Later W3 slices add Favorites, Custom Exercises and Folders here.
2. **Exercise picker/search context** — choose, add or replace an Exercise while building or editing a Routine/Program.

Neither context is a direct workout-start surface, and neither replaces the Routine/Program-first flow.

## Entry And Exit Flow

Dedicated Exercises screen:

```text
Workout Home
  -> Library
  -> Exercises
  -> dedicated Exercises screen (list / search / filters)
  -> Exercise detail
```

Exercise picker context:

```text
Routine or Program builder
  -> add / replace exercise in a selected session
  -> Exercise picker/search
  -> exercise detail / confirm selection
  -> return to the owning Routine or Program editor
```

- Neither context is a bottom tab or the first Workout screen. The dedicated Exercises screen is reached from [Library](library.md); the Library root itself does not render the Exercise list.
- Browsing the dedicated Exercises screen never starts a WorkoutSession.
- In picker mode, selecting an exercise only adds or replaces it in the in-progress Routine/Program edit state and returns to that builder. It does not start a workout session.
- The active workout flow may show exercise information for its already-selected exercises, but it must not turn either context into an unscoped global Quick Start path.

## First-Slice Data Source

The built-in Exercise catalog is versioned, bundled application content owned by the Workout capability. The canonical built-in identity is the record's stable `ex_*` ID. Title, slug, instructions, muscle/equipment metadata, media and standards links may evolve without redefining identity, and legacy/numeric/source IDs remain lookup metadata only.

The catalog is intentionally evolving. Its current exercise count is not an architecture constraint, new well-formed `ex_*` identities may be added without redesigning the domain, and identity must never be re-derived from mutable title or slug values. Once shipped, an `ex_*` ID is durable unless an explicit migration is approved.

Built-in catalog rows are not mirrored into Supabase. User-created Exercises are separate user-owned dynamic data for later approved persistence work. Routine/Program/Plan/Session/Favorite/Folder contracts reference Exercises rather than cloning catalog truth, and completed sessions must eventually snapshot the performed data needed to keep history stable when catalog content changes.

The exact physical asset path, loader, schema-validation implementation, standards evaluation logic, and licensing/attribution gate are deferred to the W3 Exercise catalog slice. Bundled catalog content cannot ship until asset ownership/path, schema validation, source/licence/attribution and media policy are approved. Widgets must not read raw JSON directly.

## Target Content

- Search field with debounced, local matching by display name and approved aliases.
- Filters such as muscle group, equipment, category, and difficulty only when the bundled schema supports them.
- Result list with name, key metadata, and a concise visual/text cue.
- Exercise detail with validated instructions, equipment and target area; picker mode adds selection confirmation.
- Empty search, no-filter-match, malformed/missing catalog, and unavailable-media fallback states.

## Data And Safety Boundaries

- Treat the JSON catalog as application content, not an unvalidated API response or medical advice.
- Every catalog version needs source/attribution and licence verification before it is shipped.
- Parse and validate catalog data behind a Workout-owned repository or data source; widgets do not read JSON directly.
- No remote search, user-generated exercise database, image download, analytics, or backend API is implied by the first slice.
- The screen must not claim injury prevention, medical suitability, or personalized form advice.

## Acceptance Criteria

- The dedicated Exercises screen is reached from Library → Exercises; picker mode is reached only from a Routine/Program exercise-selection context.
- Both contexts use the same canonical Exercise and catalog repository.
- In picker mode, search, filter, selection, and return preserve the editor state safely.
- The catalog supports stable IDs and schema validation, with a clear fallback when content cannot load.
- Text labels and details remain usable without images, colour, or network access.

## Related

- [Workout](workout.md)
- [Library](library.md)
- [Screen catalog](README.md)
- [Module ownership](../MODULE_OWNERSHIP.md)
