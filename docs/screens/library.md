# Library Screen

Document Status: Canonical Live Doc
Last Verified: 2026-09-29
Owner: `apps/features/workout`
Truth Boundary: Authoritative for the Workout Library product contract, ownership, and documented current/target behavior; runtime source wins for actual shipped behavior and trackers own delivery status.

**Surface:** Nested phone Workout destination; not a bottom-nav tab now
**Route:** `/workout/library` (`AppRoutes.workoutLibrary`), nested in the Workout branch
**Primary owner:** `apps/features/workout`
**Status:** W6A plus the bounded W6B Program collection/create foundation are implemented: Workout Home entry, Library Programs + Exercises entries, persisted Programs collection/create, and Exercises browse/search. Program detail/Routine management and Plans remain planned; user-owned Routines stay inside their owning Program.

## Purpose

Give the user one canonical hub for their Workout content: Programs, Training Plans and Exercises. Library is a navigation/collection surface. It does not own Program, Routine, TrainingPlan or Exercise truth. User-owned Routines keep stable identity but are managed inside their owning Program rather than a standalone Library collection.

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

## Current Runtime

- `/workout/library` is a child of the Workout branch route, shown on the root navigator above the shell. It covers the bottom navigation and root top bar (`ChromePolicy.noBottomBar`) instead of the shell hiding them, so Workout Home underneath does not jump while Library slides in or out. The page has an AppBar with back and the title `Library`. A direct deep link lands with `/workout` beneath it and follows `/workout` onboarding and App Mode gating.
- Workout Home → Library and Library → Exercises use `push`, so back retraces Exercises → Library → Workout Home. The app shell supplies both callbacks (`WorkoutHomePage.onLibraryPressed`, `LibraryPage.onExercisesPressed`); Workout presentation does not import route paths.
- The Library top bar has one search icon (tooltip `Search exercises`). It pushes `/workout/exercises?search=true`, which opens Exercises with its top-bar search field already active and focused; back returns to Library.
- Library now shows `Programs` above `Exercises`. Programs pushes `/workout/programs`, where persisted user Programs load through the canonical `ProgramRepository`. The screen has AppBar Create (+), a generated editable initial name, honest loading/empty/load-failure-retry/create-failure states, and display-only Program rows until detail/builder work lands.
- There are no sub-tabs, grid/list toggle, standalone Routines row, Program-detail placeholder, or Create/Favorites/Custom Exercise rows until their capabilities exist.

## Target Sections

```text
Library
├─ Programs
│  └─ Program detail/builder → Program-owned Routines
├─ Plans / Training Plans
└─ Exercises → dedicated Exercises screen
```

- Sections are capability-gated: a section appears only when its owning capability is implemented. No placeholder or production-looking empty section stands in for an unbuilt capability.
- **Programs** is the user-owned Program collection/management entry. The current shipped slice lists persisted Programs and creates a new empty Program with a generated editable name. Program rows are display-only until Program detail/builder lands. Routine create/edit remains nested inside the owning Program; there is no standalone user Routines section or top-level Create Routine action. See [Programs](programs.md) and [Program-owned Routines](routine-library.md).
- **Plans / Training Plans** is a view over the canonical TrainingPlan capability and appears only once that capability exists.
- **Exercises** opens the dedicated Exercises screen. It is the first real section: since W6A the Library root shows one `Exercises` row (fitness icon, `Browse all exercises`, chevron) that pushes `/workout/exercises`, so back returns to Library. The Library root never renders the Exercise catalog, list, search, Favorites, Custom Exercises or Folders; those belong to the Exercises capability. See [Exercises and Exercise Picker](exercise-search.md).

## Minimal Program Creation Contract

Initial Program creation presents an already generated non-blank name such as `Program 1` before confirmation. The user may rename it before OK. Blank-name fallback is not the user-facing contract.

For a user-created My Program, the initial editable surface is name plus an optional image once media support is approved. Richer source metadata is not requested from the user. Tio-curated, coach-created and accepted AI-generated Programs may carry richer source metadata under their own source/adoption contracts.

Schedule, start/end or follow-duration/till-date state belongs to the later TrainingPlan/following boundary even when edited from Program context. Optional Program/Routine images do not authorize Supabase schema or Storage work in this slice.

## Data And State Boundaries

```text
Program capability      → Program truth + Program→Routine ownership
Routine capability      → stable Routine identity/composition inside owning Program
TrainingPlan capability → scheduling/following truth
Exercise capability     → Exercise truth (including Favorites, Custom, Folders)
Library                 → navigation + user relationship/collection queries + presentation
```

- Library must not create competing copies such as `LibraryProgram`, `LibraryRoutine` or `LibraryExercise`.
- Leaving Library and returning must not reset Workout Home selected-date or active-session state.

## Acceptance Criteria

- One canonical Library route is reused by every entry point.
- The root shows only sections whose capability is ready.
- User-owned Routines are managed inside their owning Program, not a standalone Library collection.
- Initial Program creation uses a visible generated non-blank name with optional rename before confirmation; optional metadata/scheduling is not a prerequisite.
- Library → Exercises opens the dedicated Exercises screen; the Library root shows no Exercise rows.
- No Library-owned domain truth.

## Related

- [Workout](workout.md)
- [Exercises and Exercise Picker](exercise-search.md)
- [Program-owned Routines](routine-library.md)
- [Programs](programs.md)
- [Module ownership](../architecture/MODULE_OWNERSHIP.md)
