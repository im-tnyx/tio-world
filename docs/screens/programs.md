# Programs Screen

Document Status: Canonical Live Doc
Last Verified: 2026-10-11
Owner: `apps/features/workout`
Truth Boundary: Authoritative for the Programs product contract and documented current/target behavior; runtime source wins for actual shipped behavior and trackers own delivery status.

**Surface:** Persisted Programs collection rendered directly on Library, with an optional nested management route
**Route:** Library `/workout/library`; optional `/workout/programs` (`AppRoutes.workoutPrograms`) management surface
**Primary owner:** `apps/features/workout`
**Status:** Persisted Programs collection/create/rename is implemented directly on Library. W4A adds a bounded Program Detail screen with owner-scoped Routine list/create/rename in [#521](https://github.com/im-tnyx/tio-world/issues/521); full Program/Routine builder, media, archive/delete and TrainingPlan remain gated. The separate Programs route remains optional secondary management.

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
- Library Program rows retain plain header geometry, an expand/collapse chevron and 3-dot overflow. The approved [GitHub #524](https://github.com/im-tnyx/tio-world/issues/524) UI correction renders Program-owned Routine children when expanded, refreshes them on return from Detail, and uses standalone Routine cards in Detail (not one grouped Settings card); while #524 is in review these are not yet shipped on `main`. The overflow's real action stays **Edit Program** via `ProgramRepository.rename`. W4A adds a Program-name action that opens the selected Program Detail. Its metadata-only Routine list/create/rename uses the existing `RoutineRepository`, not a second Library domain source. Inline Routine rows, overflow Add Routine/Delete and the Exercise/set builder remain separate gated slices.
- The approved dotted **Add new routine** card belongs under an expanded empty Program, but remains separately gated. The #524 correction does not add Library create actions; the real Routine create action is the **sole + in Program Detail top app bar**, not a duplicate body Routines header or empty-state button.
- No standalone Routines row or top-level Create Routine action exists.

For explicit user-created Programs, initial creation is intentionally limited to the generated/renamable name. The separate default `My Program` used by direct Library Routine creation is a target ownership contract, not current runtime behavior. Description, goal, level, type, duration, image/media and scheduling are not part of this slice.

## GitHub #529 — Program-scoped Routine create entry (review branch, not released)

The owner-approved target for an expanded **owner-read and empty** Library Program is a **full-width rounded dotted/dashed-outline `+ Add new routine` card** with Core-owned colors, spacing and typography rather than passive `No routines yet` or a filled button. The dotted card and *all saved Routine cards* align to the Library's existing horizontal 16dp content margins on both sides, with **no extra left/start indentation**. Program row chevron and right-side 3-dot **glyphs** align visually to those same outer edges while retaining independent 48dp accessible touch targets, and Core Routine-card internal padding stays unchanged. The dashed outline uses a 1dp Core stroke, not the previous visually heavy 2dp stroke. Its action creates no Program or Routine metadata by itself; it navigates **directly from Library to the canonical guarded atomic `CreateRoutinePage`** tied to that selected `ProgramId`, **without showing or stacking `ProgramDetailPage`**. The app shell reuses the same protected Create callback used from Program Detail, resolving the suggested name through an authoritative owner-scoped `ProgramRoutinesController` read. After Cancel/Save/explicit unknown-outcome exit, navigation returns **directly to Library**, which re-reads persisted owner-scoped Routine children; an uncertain write is never claimed successful. On unknown outcomes the confirmation action reads **Exit to Library** for a Library-initiated Create and retains **Exit to Program** for a Program-Detail-initiated Create. A missing data source, create capability, or verified session must not expose a working Create action.

The Program-scoped **3-dot bottom sheet** preserves **Edit Program → existing Rename** and exposes **Add New Routine** when canonical Create is available. Dotted-card and bottom-sheet Add share one in-flight navigation gate across all Programs; another pending Create launch disables both entry points until that launch finishes. If a Routine Save is unconfirmed, Add is visibly disabled only for the affected Program, with an owner-scoped **Open Program to verify save** path to the existing Program Detail verification action; uncertain writes are never falsely acknowledged. Pending owner reads cannot push Create after Library is no longer the current route. It does not use the separate Routine-card anchored popup. The actual **Delete Program** action remains a separate approved product target, not a real current capability: authenticated direct DELETE was revoked, `ProgramRepository` has no delete method, and confirmation plus dependent Routine/history semantics require independently reviewed owner-safe backend and rollout contracts. Do not show a fake/inert Delete row or regrant direct table DELETE.

Implementation is being reviewed on `tnyx/issue-529-inline-add-routine` (GitHub #529); this subsection is **not** evidence of a merged main change, hosted DB deployment or installed phone-app release. Existing older "current runtime" statements above are historical and must be reconciled on merge.

## Target Library Integration

GitHub #475 changes how this capability is entered without changing Program ownership:

- Programs is the default target Library category.
- Program content may render directly on Library.
- `/workout/programs` may remain as an optional secondary Programs collection/manage screen reached from the Programs header.
- The collection/manage screen is not a mandatory intermediate step before an individual Program.
- Tapping the persisted Program name opens Program Detail directly once the W4A Routine repository provider is available; the app fails closed otherwise.
- Program expand/collapse on Library is presentation state only.

The approved Library collection composition remains unchanged. W4A makes only owner-scoped Program Detail and Routine metadata actions real; Program/Routine composition editing still requires later W4 slices.

### Approved Routine Card Visual Target (2026-10-11)

The owner-supplied reference establishes a horizontal, **one-Routine-per-card** presentation for Program Detail and Program-expanded Library: **left thumbnail/image → Routine title → right Play → right Routine 3-dot overflow**. The intended Routine-scoped overflow entries are **Edit**, **Change Picture** and **Delete**. The Routine 3-dot opens a **compact, floating, elevated popup card anchored to that 3-dot**, not a bottom sheet. Use Core `TioAnchoredPopup` / `TioCard` with governed spacing and accessible expanded/dismiss semantics; it must dismiss on outside tap without moving the Routine card. Until other action contracts are ready, the popup shows only the real **Edit → Rename Routine** option. This Routine menu is not the existing *Program*-scoped overflow bottom sheet. The Program Detail app bar still has the **only** Routine-create `+`; do not restore a second body `Routines` heading/create action.

This is **approved target UI**, not evidence that all actions are implemented. In the bounded [#524](https://github.com/im-tnyx/tio-world/issues/524) / [PR #525](https://github.com/im-tnyx/tio-world/pull/525) source, the separate cards use the existing icon as thumbnail fallback; Program Detail's Routine 3-dot opens an **Edit-only** menu invoking the already-real metadata Rename action. The Library's read-only inline cards do not fabricate a menu without an action. Functional Play/Active Workout, user-private Routine picture upload/change and owner-safe confirmed Delete are separately gated by [#526](https://github.com/im-tnyx/tio-world/issues/526). Do not render enabled but inert/misleading controls or introduce Storage/migration/RPC changes from this visual reference alone. Once the relevant capabilities exist, preserve per-Program ownership, 48dp accessible targets, light/dark support and empty/non-executable Routine behavior.

## Program Detail Metadata And Future Routine Builder

A Routine has stable identity/composition and belongs to exactly one user-owned Program. W4A Program Detail loads only that Program's Routine metadata, with generated editable names before create and existing names editable via Tio editor sheets. A save is owner-checked by existing RLS and FK; uncertain writes are reconciled using the same stable UUID. This does not expose Routine composition editing, picker or Workout Start.

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
- Program name opens only the implemented metadata Program Detail when durable Routine persistence is available; no placeholder builder/action is exposed.
- User-owned Routines are not exposed as orphan top-level Library items.
- Program and TrainingPlan remain separate.

Future acceptance remains owned by later slices for full Program/Routine builder and composition UI, inline Routine content, provenance/adoption, media, archive/delete and TrainingPlan handoff.

## Related

- [Workout](workout.md)
- [Program-owned Routines](routine-library.md)
- [Library](library.md)
- [Workout Insights](workout-insights.md)
