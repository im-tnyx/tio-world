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

Program is the reusable user workout container. A user-owned Program owns zero or more user-owned Routines. A newly created Program may be empty until the user adds its first Routine. Scheduling/following a Program is a separate TrainingPlan concern.

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

For a user-created My Program, initial editing is intentionally limited to the generated/renamable name and an optional image once the approved media capability exists. Description, goal, level, type and recommended-duration metadata are not requested from the user.

Tio-curated, coach-created and accepted AI-generated Programs may carry richer source metadata when their owning source slice defines it. That does not grant unrestricted user mutation of source-owned fields.

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

A user-created My Program may be renamed and may use an optional image once media support is approved. Tio/Coach/AI Programs may expose richer source metadata, with field-level edit authority defined by their source/adoption slice.

User-adjustable schedule or follow-duration/till-date controls belong to TrainingPlan/following state even when surfaced from Program context. They do not mutate reusable Program source metadata. Any future media persistence requires its own approved private Workout Storage slice.

## Acceptance Criteria

- Program creation begins with a visible generated non-blank name and permits rename before confirmation.
- A user-owned Program can own zero or more stable user-owned Routines; an empty new Program is valid but is not automatically executable.
- User-owned Routines cannot exist as orphan top-level Library items.
- A user-created My Program initially exposes name and optional image editing only; richer source metadata is not required from the user.
- Program and TrainingPlan remain separate; personal schedule/follow-duration changes are TrainingPlan-owned.
- Source/adopted content preserves lineage without silent source-update propagation.

## Related

- [Workout](workout.md)
- [Program-owned Routines](routine-library.md)
- [Library](library.md)
- [Workout Insights](workout-insights.md)
