# Programs Screen

Document Status: Canonical Live Doc
Last Verified: 2026-09-30
Owner: `apps/features/workout`
Truth Boundary: Authoritative for the Programs product contract and documented current/target behavior; runtime source wins for actual shipped behavior and trackers own delivery status.

**Surface:** Persisted Programs collection rendered directly on Library, with an optional nested management route
**Route:** Library `/workout/library`; optional `/workout/programs` (`AppRoutes.workoutPrograms`) management surface
**Primary owner:** `apps/features/workout`
**Status:** Minimal persisted Programs collection/create is implemented and composed directly on Library. The separate Programs route remains optional secondary management. Program detail/builder, Routine management, archive/delete, media and TrainingPlan handoff remain future slices.

## Purpose

Program is the reusable user workout container. A user-owned Program owns zero or more user-owned Routines. A newly created Program may be empty until the user adds its first Routine. Scheduling/following a Program is a separate TrainingPlan concern.

## Current Runtime

```text
Library
→ Programs header + folder-plus
→ persisted Programs collection directly on Library
→ Create Program
→ Program 1              // generated and visible, never a blank-name state
→ user may rename before confirmation
→ Create
→ persisted Program appears in the collection
```

Current behavior:

- Library renders the Programs collection directly in its default/selected Programs state.
- The tappable `Programs` header opens the existing Programs screen only as an optional secondary management route; it is not required to see the user's Programs.
- Library and the optional Programs screen reuse one feature-owned Programs surface/controller/create implementation over the canonical `ProgramRepository`; production app composition uses `SupabaseProgramRepository` when durable Supabase persistence is available and does not substitute an in-memory success path.
- Loading, empty, load-failure with retry, create-in-flight and create-failure states are explicit.
- Both the AppBar (+) action and the empty-state `Create Program` action open the canonical `showTioEditorSheet` / `TioEditorSheet` editor.
- The editor starts with a deterministic generated name such as `Program 1`. The user may edit it before confirmation. A failed write keeps the sheet and typed value visible.
- Library Program rows use a plain header treatment rather than a large/grouped Program card and expose a presentation-only expand/collapse chevron. Program-name navigation remains gated until real Program detail exists.\n- The approved dotted **Add new routine** card belongs under an expanded empty Program, but remains capability-gated until W4 supplies a real Program-owned Routine create handoff; it is not shipped as an inert/fake action.
- No standalone Routines row or top-level Create Routine action exists.

For explicit user-created Programs, initial creation is intentionally limited to the generated/renamable name. The separate default `My Program` used by direct Library Routine creation is a target ownership contract, not current runtime behavior. Description, goal, level, type, duration, image/media and scheduling are not part of this slice.

## Target Library Integration

GitHub #475 changes how this capability is entered without changing Program ownership:

- Programs is the default target Library category.
- Program content may render directly on Library.
- `/workout/programs` may remain as an optional secondary Programs collection/manage screen reached from the Programs header.
- The collection/manage screen is not a mandatory intermediate step before an individual Program.
- Tapping an individual Program opens Program detail directly once W4 supplies that capability.
- Program expand/collapse on Library is presentation state only.

The approved Library collection-composition slice is now the documented runtime direction. Program detail/Routine behavior remains gated by W4 and is not implied by rendering the existing collection on Library.

## Future Program Detail And Program-owned Routines

A Routine has its own stable identity/composition but belongs to exactly one user-owned Program. Program detail/builder will therefore be the management surface for its Routines when that separately approved capability lands.

```text
Program 1
├─ Routine 1
├─ Routine 2
└─ Routine 3
```

Routine creation inside a selected Program follows the same generated-name direction. There is no standalone user Routines collection/category in Library. The approved Library-level Routine quick-create entry is also allowed, but it must resolve exactly one owning Program before persistence; the direct entry targets the canonical default `My Program`, whose stable/idempotent identity mechanism is still a prerequisite and must not rely on mutable display-name matching.

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
