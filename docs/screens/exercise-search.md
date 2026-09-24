# Exercises Screen And Exercise Picker

**Surface:** Nested phone Workout flow; never a primary tab
**Route:** No route exists yet
**Primary owner:** `apps/features/workout`
**Status:** Planned only. The current Workout route is a shell placeholder.

## Purpose

One Exercise capability serves two presentation contexts. Both use the same canonical `Exercise`, the same Workout-owned Exercise repository/catalog data and the same search/filter primitives where appropriate; neither creates a second Exercise truth.

1. **Dedicated Exercises screen** — browse, search and filter the catalog. Exercise detail is added by its own slice. Later W3 slices add Favorites, Custom Exercises and Folders here.
2. **Exercise picker/search context** — choose, add or replace an Exercise while building or editing a Routine/Program.

Neither context is a direct workout-start surface, and neither replaces the Routine/Program-first flow.

## Incremental Delivery

The long-term Exercises capability includes detail, but each slice ships only what exists:

```text
W3A (TNYX-261)  Exercises route/screen + catalog/list, search, basic filters; no detail destination
W6A (TNYX-266)  Library route with Workout Home entry; Library -> Exercises makes W3A user-reachable
W3B (TNYX-262)  Exercise detail; detail navigation becomes available once W3B is ready
W3C-W3E         Favorites, Custom Exercises, Folders
```

W3A is the capability foundation: it delivers the Exercises route, screen and catalog repository, but has no user-facing entry of its own. The user-facing `Workout Home → Library → Exercises` path arrives with W6A. W3A must not add an interim entry elsewhere (for example a temporary Workout Home shortcut) without owner approval, and must not ship a fake, placeholder or unimplemented detail destination. Until W3B is ready, picker mode confirms a selection from the result list.

## Entry And Exit Flow

Dedicated Exercises screen:

```text
Workout Home
  -> Library
  -> Exercises
  -> dedicated Exercises screen (list / search / filters)
  -> Exercise detail (once W3B is ready)
```

Exercise picker context:

```text
Routine or Program builder
  -> add / replace exercise in a selected session
  -> Exercise picker/search
  -> confirm selection (exercise detail once W3B is ready)
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
- Exercise detail (W3B) with validated instructions, equipment and target area; picker mode adds selection confirmation.
- Empty search, no-filter-match, malformed/missing catalog, and unavailable-media fallback states.

## Data And Safety Boundaries

- Treat the JSON catalog as application content, not an unvalidated API response or medical advice.
- Every catalog version needs source/attribution and licence verification before it is shipped.
- Parse and validate catalog data behind a Workout-owned repository or data source; widgets do not read JSON directly.
- No remote search, user-generated exercise database, image download, analytics, or backend API is implied by the first slice.
- The screen must not claim injury prevention, medical suitability, or personalized form advice.

## Acceptance Criteria

- The dedicated Exercises screen is reached from Library → Exercises (user-facing once W6A lands); picker mode is reached only from a Routine/Program exercise-selection context.
- Both contexts use the same canonical Exercise and catalog repository.
- W3A exposes no Exercise detail navigation; detail appears only once W3B is ready.
- In picker mode, search, filter, selection, and return preserve the editor state safely.
- The catalog supports stable IDs and schema validation, with a clear fallback when content cannot load.
- Text labels and details remain usable without images, colour, or network access.

## Related

- [Workout](workout.md)
- [Library](library.md)
- [Screen catalog](README.md)
- [Module ownership](../MODULE_OWNERSHIP.md)
