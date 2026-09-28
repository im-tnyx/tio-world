# Program-owned Routines

Document Status: Planned/Future Doc
Last Verified: 2026-09-28
Owner: `apps/features/workout`
Truth Boundary: Authoritative for the planned user-owned Routine product contract; not evidence the screen is implemented or scheduled.

**Surface:** Nested Phone Workout flow inside an owning Program
**Route:** No route exists yet
**Primary owner:** `apps/features/workout`
**Status:** Planned only. Filename retained for link stability.

## Purpose

A Routine is a stable reusable workout composition built from canonical Exercises. For user-owned content, every saved Routine belongs to exactly one user-owned Program.

Routine keeps its own `RoutineId`, ordering, Exercise references and prescription/template state so editing and history references remain safe. Program ownership does not mean embedding anonymous Routine JSON or removing Routine identity.

## Target Flow

```text
Library
→ Programs
→ Program
→ Add Routine
→ generated non-blank name is visible (for example Routine 1)
→ user may rename
→ add Exercises / prescriptions
→ save inside the owning Program
```

There is no standalone `Library → Routines` collection and no top-level Create Routine action.

## Initial Routine Metadata

The first Routine slice needs only the metadata required to identify and compose the Routine. A name is present from creation because the flow generates one before confirmation. An optional Routine image may be added by a later editing/media slice; it is not required to create a Routine and does not authorize Storage work now.

Exercise selection opens the canonical Workout Exercise picker. Routine composition references canonical Exercise identities rather than cloning Exercise definitions.

## Navigation And Rules

- Routine create/edit is entered from its owning Program.
- A Routine cannot be saved as an orphan user Library item.
- Program adoption/copy may create user-owned Routine copies as part of the adopted Program structure while retaining approved source lineage.
- Starting an active workout from a Routine remains a deliberate selected-context flow; this document does not implement Active Workout.
- Scheduling/following a reusable Program/Routine is a later TrainingPlan concern.

## Data And States

- Routine identity/composition stays Workout-owned.
- Persistence/repository/table/RLS shape remains deferred to W1B0 and requires its own approved slice.
- Completed WorkoutSession history must not be silently rewritten by later Routine edits.

## Acceptance Criteria

- Every saved user-owned Routine has one owning Program.
- Routine has stable identity and is not anonymous nested data.
- No standalone Library Routines collection exists.
- Exercise selection is nested in Routine editing and cannot start a workout by itself.
- Optional image/metadata does not block initial Routine creation.
- Scheduling/following remains separate from reusable Routine truth.

## Related

- [Workout](workout.md)
- [Library](library.md)
- [Programs](programs.md)
- [Exercise Search](exercise-search.md)
