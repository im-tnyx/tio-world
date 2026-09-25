# Library Screen

**Surface:** Nested phone Workout destination; not a bottom-nav tab now
**Route:** `/workout/library` (`AppRoutes.workoutLibrary`), nested in the Workout branch
**Primary owner:** `apps/features/workout`
**Status:** W6A (TNYX-266) implemented: Workout Home entry and a Library root with the Exercises section. Programs, Routines and Plans sections remain planned (W6B/W6C).

## Purpose

Give the user one canonical hub for their Workout content: Programs, Routines, Training Plans and Exercises. Library is a navigation/collection surface. It does not own Program, Routine, TrainingPlan or Exercise truth; each section reads from and hands off to the owning capability.

## Entry Points

```text
Initial target:  Bottom navigation → Workout → Workout Home → Library entry → Library
Future:          Bottom navigation → Library (only if enabled in configurable navigation) → same Library
```

- The Workout Home entry exists since W6A: a `TioGroupCard` holding one `TioSettingsNavigationRow` (folder icon, `Library`, `Browse exercises`, chevron) below the calendar. The future bottom-nav entry does not exist.
- There is exactly one Library route/screen. Every entry point opens the same route with the same state and ownership.
- Library is not a bottom-nav destination now. A future configurable navigation with three to six destinations may expose it only after its destination-readiness audit ([ADR-0005](../adr/0005-adaptive-navigation-and-action-entry.md), D-014, D-020).
- The Workout Home → Library entry remains available whether or not Library is selected in bottom navigation.
- Library is not a Workout-local content tab inside Workout Home.

## W6A Runtime

- `/workout/library` is a child of the Workout branch route: the bottom navigation and root top bar are hidden (`ChromePolicy.noBottomBar`), and the page has an AppBar with back and the title `Library`. A direct deep link lands with `/workout` beneath it and follows `/workout` onboarding and App Mode gating.
- Workout Home → Library and Library → Exercises use `push`, so back retraces Exercises → Library → Workout Home. The app shell supplies both callbacks (`WorkoutHomePage.onLibraryPressed`, `LibraryPage.onExercisesPressed`); Workout presentation does not import route paths.
- There are no sub-tabs, grid/list toggle, placeholders, or Create/Favorites/Custom rows until their capabilities exist.

## Target Sections

```text
Library
├─ Programs
├─ Routines
├─ Plans / Training Plans
└─ Exercises → dedicated Exercises screen
```

- Sections are capability-gated: a section appears only when its owning capability is implemented. No placeholder or production-looking empty section stands in for an unbuilt capability.
- **Programs** and **Routines** are relationship/ownership views (for example Saved/Following and Created by me) over canonical Program and Routine identities; create/edit hands off to their builders. See [Programs](programs.md) and [Routines](routine-library.md).
- **Plans / Training Plans** is a view over the canonical TrainingPlan capability and appears only once that capability exists.
- **Exercises** opens the dedicated Exercises screen. It is the first real section: since W6A the Library root shows one `Exercises` row (fitness icon, `Browse all exercises`, chevron) that pushes `/workout/exercises`, so back returns to Library. The Library root never renders the Exercise catalog, list, search, Favorites, Custom Exercises or Folders; those belong to the Exercises capability. See [Exercises and Exercise Picker](exercise-search.md).

## Data And State Boundaries

```text
Program capability      → Program truth
Routine capability      → Routine truth
TrainingPlan capability → TrainingPlan truth
Exercise capability     → Exercise truth (including Favorites, Custom, Folders)
Library                 → navigation + user relationship/collection queries + presentation
```

- Library must not create competing copies such as `LibraryProgram`, `LibraryRoutine` or `LibraryExercise`.
- Leaving Library and returning must not reset Workout Home selected-date or active-session state.

## Acceptance Criteria

- One canonical Library route is reused by every entry point.
- The root shows only sections whose capability is ready.
- Library → Exercises opens the dedicated Exercises screen; the Library root shows no Exercise rows.
- No Library-owned domain truth.

## Related

- [Workout](workout.md)
- [Exercises and Exercise Picker](exercise-search.md)
- [Routines](routine-library.md)
- [Programs](programs.md)
- [Module ownership](../MODULE_OWNERSHIP.md)
