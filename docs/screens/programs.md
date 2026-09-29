# Programs Screen

Document Status: Canonical Live Doc
Last Verified: 2026-09-29
Owner: `apps/features/workout`
Truth Boundary: Authoritative for the Programs product contract and documented current/target behavior; runtime source wins for actual shipped behavior and trackers own delivery status.

**Surface:** Nested Phone Workout flow reached from Library
**Route:** `/workout/programs` (`AppRoutes.workoutPrograms`), nested in the Workout branch
**Primary owner:** `apps/features/workout`
**Status:** Minimal persisted Programs collection/create is implemented. Program detail/builder, Routine management, archive/delete, media and TrainingPlan handoff remain future slices.

## Purpose

Program is the reusable user workout container. A user-owned Program owns zero or more user-owned Routines. A newly created Program may be empty until the user adds its first Routine. Scheduling/following a Program is a separate TrainingPlan concern.

## Current Runtime

```text
Library
→ Programs
→ persisted Programs collection
→ Create Program
→ Program 1              // generated and visible, never a blank-name state
→ user may rename before confirmation
→ Create
→ persisted Program appears in the collection
```

Current behavior:

- Library shows a real `Programs` navigation row above Exercises.
- The Programs screen reads through the canonical `ProgramRepository`; production app composition uses `SupabaseProgramRepository` when durable Supabase persistence is available and does not substitute an in-memory success path.
- Loading, empty, load-failure with retry, create-in-flight and create-failure states are explicit.
- Both the AppBar (+) action and the empty-state `Create Program` action open the canonical `showTioEditorSheet` / `TioEditorSheet` editor.
- The editor starts with a deterministic generated name such as `Program 1`. The user may edit it before confirmation. A failed write keeps the sheet and typed value visible.
- Program rows are display-only in this first slice. There is no chevron, tap target or fake detail destination.
- No standalone Routines row or top-level Create Routine action exists.

For a user-created My Program, initial creation is intentionally limited to the generated/renamable name. Description, goal, level, type, duration, image/media and scheduling are not part of this slice.

## Future Program Detail And Program-owned Routines

A Routine has its own stable identity/composition but belongs to exactly one user-owned Program. Program detail/builder will therefore be the management surface for its Routines when that separately approved capability lands.

```text
Program 1
├─ Routine 1
├─ Routine 2
└─ Routine 3
```

Routine creation follows the same generated-name direction inside the Program. There is no standalone user Routines collection in Library.

## Provenance And Adoption

Tio-curated source Programs remain read-only. Explicit Add to Library / Use creates a user-owned Program copy and the editable Program-owned Routine structure required for independent changes while retaining approved source/revision lineage. Source updates must never silently mutate the user copy.

User-created, accepted AI-generated and future coach-created reusable content remain one canonical Program capability distinguished by provenance/ownership, not parallel Program models. Those source/adoption flows are not implemented by the current minimal collection/create slice.

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

A future approved Program detail slice may allow rename management and optional image/media under the appropriate private Workout Storage contract. Tio/Coach/AI Programs may expose richer source metadata, with field-level edit authority defined by their source/adoption slice.

User-adjustable schedule or follow-duration/till-date controls belong to TrainingPlan/following state even when surfaced from Program context. They do not mutate reusable Program source metadata.

## Acceptance Criteria

Current shipped foundation:

- Program creation begins with a visible generated non-blank name and permits editing before confirmation.
- The Programs collection is persisted through the canonical Program repository boundary.
- Loading, empty, load-failure/retry and create-failure states are honest.
- Production has no in-memory Program durability fallback.
- A user-owned Program can exist with zero Routines.
- Program rows do not pretend detail/builder capability exists.
- User-owned Routines are not exposed as orphan top-level Library items.
- Program and TrainingPlan remain separate.

Future acceptance remains owned by later slices for Program detail/builder, Program-owned Routine composition/management, provenance/adoption, media, archive/delete and TrainingPlan handoff.

## Related

- [Workout](workout.md)
- [Program-owned Routines](routine-library.md)
- [Library](library.md)
- [Workout Insights](workout-insights.md)
