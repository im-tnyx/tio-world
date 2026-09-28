# Library Screen

Document Status: Canonical Live Doc
Last Verified: 2026-09-28
Owner: `apps/features/workout`
Truth Boundary: Authoritative for the Workout Library product contract, ownership, and documented current/target behavior; runtime source wins for actual shipped behavior and trackers own delivery status.

**Surface:** Nested phone Workout destination; not a bottom-nav tab now
**Route:** `/workout/library` (`AppRoutes.workoutLibrary`), nested in the Workout branch
**Primary owner:** `apps/features/workout`
**Status:** W6A (TNYX-266) implemented: Workout Home entry and a Library root with the Exercises section. Programs and Plans remain planned (W6B/W6C); user-owned Routines are managed inside their owning Program.

## Purpose

Give the user one canonical hub for Workout Programs, Training Plans and Exercises. Library is a navigation/collection surface. It does not own Program, Routine, TrainingPlan or Exercise truth.

A user-owned Routine keeps stable identity/composition but belongs to exactly one user-owned Program. Library therefore does not expose a standalone user Routines collection.

## Entry Points

```text
Initial target:  Bottom navigation → Workout → Workout Home → Library entry → Library
Future:          Bottom navigation → Library (only if enabled in configurable navigation) → same Library
```

- The Workout Home entry exists since W6A.
- There is exactly one Library route/screen. Every entry point opens the same route with the same state and ownership.
- Library is not a bottom-nav destination now. Future configurable navigation may promote the same route after its destination-readiness audit.
- The Workout Home → Library entry remains available whether or not Library is selected in bottom navigation.

## W6A Runtime

- `/workout/library` is a child of the Workout branch route and currently renders only the ready Exercises capability.
- Workout Home → Library and Library → Exercises use `push`; Workout presentation does not import route paths.
- The Library top bar search action opens Exercises search.
- There are no Programs, Plans, placeholders or create actions in current runtime.

## Target Sections

```text
Library
├─ Programs
│  └─ Program detail/builder
│     └─ Program-owned Routines
├─ Plans / Training Plans     // only once W9 exists
└─ Exercises → dedicated Exercises screen
```

- Sections are capability-gated. No production-looking placeholder stands in for an unbuilt capability.
- **Programs** is the user collection/management entry. User-owned Routine creation/editing is nested inside its owning Program.
- **Plans / Training Plans** appears only once the canonical TrainingPlan capability exists.
- **Exercises** opens the dedicated Exercises screen and remains the first implemented section.
- Library does not expose a standalone user Routines section or top-level Create Routine action.

## Minimal Program Creation Contract

Initial Program creation is deliberately small:

```text
Create Program
→ generated non-blank name is already visible (for example Program 1)
→ user may rename it
→ OK
→ Program exists and can own Routines
```

Blank-name fallback is not the user-facing contract because the create surface starts with a generated valid name. Description, image, level, goal, type, duration and similar metadata are not required during initial creation. They may be added later through Program editing only when a concrete approved slice needs them.

Schedule, start date, current week/progress and following state are not initial Program metadata. They belong to the later TrainingPlan/following boundary.

Optional Program/Routine images remain future metadata. This contract does not authorize a Supabase table/column or Storage bucket/upload implementation.

## Data And State Boundaries

```text
Program capability      → Program truth + Program→Routine ownership
Routine capability      → Routine identity/composition inside owning Program
TrainingPlan capability → scheduling/following truth
Exercise capability     → Exercise truth
Library                 → navigation + collection presentation
```

Library must not create competing copies such as `LibraryProgram`, `LibraryRoutine` or `LibraryExercise`.

## Acceptance Criteria

- One canonical Library route is reused by every entry point.
- The root shows only sections whose capability is ready.
- User-owned Routines are managed inside their owning Program, not a standalone Library collection.
- Initial Program creation has a visible generated non-blank name and optional rename before confirmation.
- Optional Program metadata and scheduling are not prerequisites for initial Program creation.
- Library → Exercises opens the dedicated Exercises screen.
- No Library-owned domain truth.

## Related

- [Workout](workout.md)
- [Exercises and Exercise Picker](exercise-search.md)
- [Program-owned Routines](routine-library.md)
- [Programs](programs.md)
- [Module ownership](../architecture/MODULE_OWNERSHIP.md)
