# Exercises Screen And Exercise Picker

**Surface:** Nested phone Workout flow; never a primary tab
**Route:** `/workout/exercises` (`AppRoutes.workoutExercises`), nested in the Workout branch
**Primary owner:** `apps/features/workout`
**Status:** Dedicated Exercises screen implemented (W3A2b, TNYX-272) and user-reachable through Workout Home → Library → Exercises (W6A, TNYX-266); detail, picker mode and Favorites/Custom/Folders remain planned.

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

W3A2a (TNYX-270) landed the bundled catalog boundary. The Workout-owned asset `apps/features/workout/assets/exercises/exercise_catalog.json` is registered in `tio_feature_workout` (asset key `packages/tio_feature_workout/assets/exercises/exercise_catalog.json`). `ExerciseCatalogDocumentDecoder` validates its `schemaVersion` / `catalogVersion` / `exercises` document envelope (supported `schemaVersion`: 1), `AssetBundleExerciseCatalogSource` is the production source over an injected `AssetBundle`, and the W3A1 `ExerciseCatalogParser` and repository remain the canonical row validation and mapping to `Exercise`. Missing-asset, asset-load, invalid-document, unsupported-schema and invalid-row failures are distinct typed exceptions.

The shipped catalog carries the approved text fields (ID, title, muscle group, primary/secondary muscles, primary equipment, category, levels, archived/custom flags). Since TNYX-274 (`catalogVersion` 2, `schemaVersion` still 1) it also carries each row's owner-curated `media` object: `type`, `defaultGender`, optional `videoFallbackGender`, and `male` / `female` variants with `imageUrl`, `thumbnailUrl` and `videoUrl` as full provider URLs (owner-approved and owner-maintained). The owner updates those URLs in the catalog JSON directly. `Exercise.media` exposes them as https-validated URLs. `ExerciseMedia.urlFor` is the single selection rule for phone and watch: the viewer's gender, then `defaultGender`, then `videoFallbackGender` for video, then the other variant, else none (text-only). The app composition root maps the signed-in profile's gender to a media gender (`other` or unknown means none) and supplies it through `exerciseViewerMediaGenderProvider`, because Workout does not read Profile; the consuming controller then selects media through `ExerciseMedia.urlFor`. Phone surfaces may show image and video; watch surfaces show images only. Instructions, standards, icons and provider/source metadata are not shipped, and standards evaluation logic remains deferred. Source/licence/attribution rights for the shipped catalog version are owner-attested, with evidence retained outside the repository; this is not an independent legal verification. The Exercises screen and route are described under [Dedicated Exercises Screen (W3A2b)](#dedicated-exercises-screen-w3a2b); the user-facing Library entry arrived with W6A. Widgets must not read raw JSON directly.

## Dedicated Exercises Screen (W3A2b)

W3A2b (TNYX-272) delivered the dedicated screen; W6A (TNYX-266) made it reachable through Workout Home → Library → Exercises. Workout Home deliberately has no direct Exercises entry.

- **Route:** `/workout/exercises` is a child of the Workout branch route, shown on the root navigator above the shell. It covers the bottom navigation and root top bar (`ChromePolicy.noBottomBar`) instead of the shell hiding them, so Workout Home underneath never relayouts during the push or pop transition. The page has a standard AppBar with back. A direct deep link opens the screen with `/workout` beneath it, and the screen follows the same onboarding and App Mode gating as `/workout`, so a mode without the Workout tab is redirected exactly as `/workout` would be.
- **Ownership:** `apps/features/workout/lib/src/presentation/library/exercises/` owns `ExercisesController` (a `ChangeNotifier` behind `exercisesControllerProvider`), the immutable `ExercisesState`, `ExercisesPage`, the filter sheet and the rows. `exerciseCatalogRepositoryProvider` supplies the bundled `AssetBundleExerciseCatalogSource`. The presentation subtree is co-located with its shipped Library entry, but Library remains a navigation/collection surface: canonical Exercise domain/data ownership stays under the Workout Exercise capability, and the Library root still does not render the catalog.
- **Search and filters:** the top bar reads back, `Exercises`, a search icon and a filter icon. The search icon swaps the title for a `Search exercises` field; its close action hides the field and clears the text. The field is closed by default, except when opened through Library's search icon or the `?search=true` deep link (`ExercisesPage.startSearching`), which open the screen with the field active and focused. While the field is open, the filter icon is hidden. The filter icon turns the primary color while any filter is active, and its tooltip announces the active count. It opens a sheet with single-select Muscle, Equipment and Category chips, `Clear all` and `Show results`. Choices stay a draft until `Show results`, and dismissing the sheet applies nothing. All matching goes through `ExerciseCatalogQuery`, and search applies as the user types. Filter values come from active Exercises, and labels are sentence-case forms of the taxonomy tokens (for example `Upper arms`, `EZ bar`).
- **Rows:** a thumbnail, the Exercise name and `Primary equipment • Muscle group`. The thumbnail is `urlFor(image)`, then `urlFor(thumbnail)`, for the viewer's media gender. With no usable URL, or when the image fails to load, the row is text-only with no placeholder. Rows have no icon, chevron, favorite/folder action, video or tap behavior until Exercise Detail (W3B) exists.
- **States:** loading, empty catalog, search/filter no-match, missing bundled catalog, malformed catalog (including an unsupported schema version) and unexpected failure. Every failure comes from the bundled asset, so none of them offers Retry.

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

- The dedicated Exercises screen is reached from Library → Exercises (user-facing since W6A); picker mode is reached only from a Routine/Program exercise-selection context.
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
