# Library Screen

**Surface:** Nested phone Workout destination; not a bottom-nav tab now
**Route:** No route exists yet (planned canonical Workout-owned route)
**Primary owner:** `apps/features/workout`
**Status:** Planned only. Route and ownership contract; no visual specification.

## Purpose

Give the user one canonical hub for their Workout content: Programs, Routines, Training Plans and Exercises. Library is a navigation/collection surface. It does not own Program, Routine, TrainingPlan or Exercise truth; each section reads from and hands off to the owning capability.

## Entry Points

```text
Initial target:  Bottom navigation → Workout → Workout Home → Library entry → Library
Future:          Bottom navigation → Library (only if enabled in configurable navigation) → same Library
```

- Neither entry exists at runtime yet; the initial target is the approved first entry, not implemented behavior.
- There is exactly one Library route/screen. Every entry point opens the same route with the same state and ownership.
- Library is not a bottom-nav destination now. A future configurable navigation with three to six destinations may expose it only after its destination-readiness audit ([ADR-0005](../adr/0005-adaptive-navigation-and-action-entry.md), D-014, D-020).
- The Workout Home → Library entry remains available whether or not Library is selected in bottom navigation.
- Library is not a Workout-local content tab inside Workout Home.

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
- **Exercises** opens the dedicated Exercises screen. It is the first real section: W6A adds the Library route and this entry after W3A delivers the Exercises route/screen, which has no user-facing entry until then. The Library root never renders the Exercise catalog, list, search, Favorites, Custom Exercises or Folders; those belong to the Exercises capability. See [Exercises and Exercise Picker](exercise-search.md).

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
