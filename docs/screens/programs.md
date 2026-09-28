# Programs Screen

Document Status: Planned/Future Doc
Last Verified: 2026-09-28
Owner: `apps/features/workout`
Truth Boundary: Authoritative for the planned Programs product contract and ownership; not evidence the screen is implemented or scheduled.

**Surface:** Nested Phone Workout flow reached from Library
**Route:** No route exists yet
**Primary owner:** `apps/features/workout`
**Status:** Planned only.

## Purpose

Program is the reusable user workout container. A user-owned Program owns one or more user-owned Routines. Scheduling/following a Program is a separate TrainingPlan concern.

## Minimal Create Flow

```text
Library
→ Programs
→ Create Program
→ Program 1              // generated and visible, never a blank-name state
→ user may rename
→ OK
→ Program detail
→ Add Routine
```

Initial creation does not require description, image, level, goal, type, duration, schedule or other planning metadata. Those fields may be introduced later in Program editing when a concrete approved use case needs them.

## Program-owned Routines

A Routine has its own stable identity/composition but belongs to exactly one user-owned Program. Program detail/builder is therefore the management surface for its Routines.

```text
Program 1
├─ Routine 1
├─ Routine 2
└─ Routine 3
```

Routine creation follows the same generated-name direction inside the Program. There is no standalone user Routines collection in Library.

## Provenance And Adoption

Tio-curated source Programs remain read-only. Explicit Add to Library / Use creates a user-owned Program copy and the editable Program-owned Routine structure required for independent changes while retaining approved source/revision lineage. Source updates must never silently mutate the user copy.

User-created, accepted AI-generated and future coach-created reusable content remain one canonical Program capability distinguished by provenance/ownership, not parallel Program models.

## TrainingPlan Boundary

Reusable Program structure does not own the user's actual start date, current week/progress or follow schedule.

```text
Program
→ explicit Start / Schedule
→ TrainingPlan setup
→ user-specific schedule / PlannedWorkout state
```

Profile/Workout settings may later suggest defaults, but must not silently mutate existing Program or TrainingPlan truth.

## Optional Metadata And Media

Description, image, level, goal, type, duration and similar metadata are optional later editing concerns. Program/Routine images are not required for the initial Program/Routine creation slices. Any future media persistence must use the approved private Workout Storage boundary and requires a concrete approved data/media slice.

## Acceptance Criteria

- Program creation begins with a visible generated non-blank name and permits rename before confirmation.
- A user-owned Program can own multiple stable user-owned Routines.
- User-owned Routines cannot exist as orphan top-level Library items.
- Optional metadata is not required to create the initial Program.
- Program and TrainingPlan remain separate.
- Source/adopted content preserves lineage without silent source-update propagation.

## Related

- [Workout](workout.md)
- [Program-owned Routines](routine-library.md)
- [Library](library.md)
- [Workout Insights](workout-insights.md)
