# Exercises Screen And Exercise Picker

Document Status: Canonical Live Doc
Last Verified: 2026-10-01
Owner: `apps/features/workout`
Truth Boundary: Authoritative for the Exercises screen/picker product contract, ownership, and documented current/target behavior; runtime source wins for actual shipped behavior and trackers own delivery status.

**Surface:** Nested phone Workout flow; never a primary tab
**Route:** `/workout/exercises` (`AppRoutes.workoutExercises`), nested in the Workout branch
**Primary owner:** `apps/features/workout`
**Status:** Dedicated Exercises screen implemented (W3A2b, TNYX-272) and user-reachable through Workout Home → Library → Exercises (W6A, TNYX-266). Minimal user-owned Exercise persistence is live from W1B1, and W3D1 adds non-UI repository composition plus Custom Exercise controller/identity-generation foundation. The current W3D3 branch temporarily contains a separate `/workout/custom-exercises` collection/editor, but owner correction on 2026-10-04 supersedes that collection as the final UX: catalog + user-created Exercises must compose on the canonical `/workout/exercises` surface, with user-created rows carrying a `Custom` badge/tag. Detail, picker mode and visible Favorites/Folders remain separately planned.

## Custom Exercises Runtime And Corrected Target

The current W3D3 branch temporarily contains a separate `/workout/custom-exercises` route reached from Library → Custom Exercises. That route reuses canonical `Exercise` / `UserCreatedExerciseRef` and the existing user Exercise repository, but the separate collection presentation is now an interim implementation rather than the final product target.

Owner correction on 2026-10-04 requires one canonical Exercises presentation surface:

```text
/workout/exercises
├─ user-created Exercise rows   [Custom]
└─ bundled catalog Exercise rows
```

User-created Exercises must appear on the same canonical Exercises screen as catalog Exercises and remain normal canonical `Exercise` items. A `Custom` badge/tag is presentation metadata derived from identity/source, not a second domain model. Search/filter should compose over both sources where the relevant taxonomy exists. Tapping a Custom row enters its edit/detail flow; successful create/edit returns to the same canonical Exercises surface. A Library `Custom Exercises` entry may open this same surface in a Custom-focused/filter state, but must not establish another collection truth. `Recent Exercises` remains capability-gated on real workout-history data and must not be fabricated.

The editor itself remains W3D3-owned and exposes required name plus optional description, Exercise Type, Primary muscle, Secondary muscles, and Equipment using the already-live W3D2 persistence contract. Optional single-value selections can be cleared, secondary muscles cannot duplicate the primary muscle, archive requires destructive confirmation, and pending writes keep the editor mounted until their result is known. Media/Storage and execution-measurement semantics remain outside W3D3.

## Purpose

One Exercise capability serves two presentation contexts. Both use the same canonical `Exercise`, the same Workout-owned Exercise repository/catalog data and the same search/filter primitives where appropriate; neither creates a second Exercise truth.

1. **Dedicated Exercises screen** — browse, search and filter the unified canonical Exercise presentation. The bundled catalog and active user-created Exercises compose here; user-created rows carry a `Custom` badge/tag. Exercise detail is added by its own slice. Later W3 slices add Favorites and Folders without introducing another Exercise truth.
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

## Future Library Exercises Category

GitHub #475 defines a future Library category selector in which **Exercises** is the second category after Programs.

That target category does not move canonical Exercise truth into Library. It composes/navigates W3-owned collection views as their capabilities become real:

```text
Exercises category
├─ Create a custom exercise    // W3D
├─ Favorite Exercises          // W3C
├─ Custom Exercises            // W3D
└─ user-created folders...     // W3E
```

The canonical `/workout/exercises` screen is the single Exercise browsing/search/filter surface. Under the corrected W3D direction it composes bundled catalog rows with active user-created rows; `Custom Exercises` is therefore a focused view/state over that same screen, not a second collection route. In the future #475 Library Exercises category, **Browse exercises** opens the normal unified state, while **Custom Exercises** may open the same route focused to user-created rows. `Create a custom exercise` enters the W3D editor and returns to the unified screen. Until W3C/W3D/W3E capabilities are real, Library must not render fake Favorite/Custom/Folder production entries.

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

- Neither context is a bottom tab or the first Workout screen. In the current runtime, the dedicated Exercises screen is reached from [Library](library.md) through the Exercises navigation row. In the future #475 category UI, the secondary Browse exercises action opens the same `/workout/exercises` route; Library still does not duplicate catalog truth or render a second catalog implementation.
- Browsing the dedicated Exercises screen never starts a WorkoutSession.
- In picker mode, selecting an exercise only adds or replaces it in the in-progress Routine/Program edit state and returns to that builder. It does not start a workout session.
- The active workout flow may show exercise information for its already-selected exercises, but it must not turn either context into an unscoped global Quick Start path.

## First-Slice Data Source

The built-in Exercise catalog is versioned, bundled application content owned by the Workout capability. The canonical built-in identity is the record's stable `ex_*` ID. Title, slug, instructions, muscle/equipment metadata, media and standards links may evolve without redefining identity, and legacy/numeric/source IDs remain lookup metadata only.

The catalog is intentionally evolving. Its current exercise count is not an architecture constraint, new well-formed `ex_*` identities may be added without redesigning the domain, and identity must never be re-derived from mutable title or slug values. Once shipped, an `ex_*` ID is durable unless an explicit migration is approved.

Built-in catalog rows are not mirrored into Supabase. User-created Exercises are separate user-owned dynamic data persisted through the validated W1B1 `user_workout_exercises` boundary; its minimum durable shape supports active/archive lifecycle, display name, stable UUID identity and optional immutable catalog-source lineage. Additional taxonomy beyond the live W3D2 Exercise Type/muscle/equipment fields, plus instructions and user-created media persistence, remain separately gated. Routine/Program/Plan/Session/Favorite/Folder contracts reference Exercises rather than cloning catalog truth, and completed sessions must eventually snapshot the performed data needed to keep history stable when catalog content changes.

W3D2 is merged and live. Canonical `Exercise` supports optional description and Exercise Type, reuses primary/secondary muscles and primary equipment, and structured user Exercise definitions round-trip through `UserExerciseRepository`; rename preserves these fields. Migration `20260930180700_add_custom_exercise_definition_fields.sql` is deployed and hosted-verified on the existing owner-scoped `public.user_workout_exercises` boundary, which now has 12 columns. Authenticated access remains least-privilege with no DELETE and immutable identity/owner/catalog-lineage/timestamps; repository and hosted migration identity are reconciled. Name-only creation remains supported with no fabricated legacy taxonomy. Body Part stays derived presentation grouping. Visible Custom Exercise editing is being delivered through W3D3, but the owner-corrected final composition is the canonical `/workout/exercises` screen with user-created rows marked `Custom`; the separate `/workout/custom-exercises` collection currently present on the branch is transitional and must not be treated as final product architecture. Media/Storage and execution measurement semantics remain separate gated slices.

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

- The dedicated Exercises screen is currently reached from Library → Exercises (user-facing since W6A); after the #475 category UI lands, the Exercises category's secondary **Browse exercises** action opens the same canonical route. Picker mode is reached only from a Routine/Program exercise-selection context.
- Both contexts use the same canonical Exercise and catalog repository.
- W3A exposes no Exercise detail navigation; detail appears only once W3B is ready.
- In picker mode, search, filter, selection, and return preserve the editor state safely.
- The catalog supports stable IDs and schema validation, with a clear fallback when content cannot load.
- Text labels and details remain usable without images, colour, or network access.

## Related

- [Workout](workout.md)
- [Library](library.md)
- [Screen catalog](README.md)
- [Module ownership](../architecture/MODULE_OWNERSHIP.md)
