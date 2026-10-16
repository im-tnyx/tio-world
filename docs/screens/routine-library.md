# Program-owned Routines

Document Status: Canonical Live Doc (merged W4 Create/Edit composer and read-only Detail; #564 name Update parity still gated)
Last Verified: 2026-10-16 (bounded current-state reconciliation; older subsections retain historical dates)
Owner: `apps/features/workout`
Truth Boundary: Authoritative for Program-owned Routine behavior, merged Create/Edit composition, read-only Detail and remaining gated capabilities. Checked-in runtime proves implementation; merge does not prove app-store release.

**Surface:** Nested Phone Workout flow inside an owning Program
**Route:** Program Detail is pushed from the selected Library Program name above `/workout/library`; no standalone Routine route exists.
**Primary owner:** `apps/features/workout`
**Historical 2026-10-12 baseline (superseded by current-runtime note immediately below):** W4A [#521](https://github.com/im-tnyx/tio-world/issues/521) (closed) / [PR #522](https://github.com/im-tnyx/tio-world/pull/522) (merged at `12999565`) implements Program-owned Routine metadata list/create/rename through durable persistence. The ordered Exercise/set database foundation and feature composition adapter were merged via PR #511/#513. [PR #530](https://github.com/im-tnyx/tio-world/pull/530) subsequently **squash-merged into `main` at `0c2a6cd0`**, adding owner-scoped **read-only Routine Detail** from saved Routine cards using the nullable composition provider and Workout-owned read controller. This is verified repository implementation, **not** confirmation of a published phone app release. Exercise picker and composition editor were gated at that historical checkpoint but subsequently merged through #551; Workout Start and broader W4 acceptance remain separately gated.

**Current Flutter runtime (verified GitHub `main@5aec6ef1`, 2026-10-16):** Consolidated W4 [PR #551](https://github.com/im-tnyx/tio-world/pull/551) is **merged**, including the existing owner-verified Create/Edit state adapters, canonical shared `RoutineComposerScreen`, real Exercise picker, revision-guarded Set composition Update and safe unknown-outcome flow. [PR #566](https://github.com/im-tnyx/tio-world/pull/566) then merged the selected-Program Library Add Routine entry. On this main snapshot, Create has top-right **Save**, Edit has bottom **Update**, Routine Detail has top-bar **Edit Routine**, and the Routine-card overflow `Edit` still opens metadata **Rename**. These differences motivate [GitHub #564](https://github.com/im-tnyx/tio-world/issues/564). Prior #532/#533 text below is historical implementation/planning evidence, not a currently open Draft or a mandate to retain two user-facing editors. A GitHub merge does not establish a published mobile app release.

## Purpose

A Routine is a stable reusable workout composition built from canonical Exercises. For user-owned content, every saved Routine belongs to exactly one user-owned Program.

Routine keeps its own `RoutineId` and owning `ProgramId`. Ordered Exercise references and prescription/template state use separate immutable `RoutineComposition`, `RoutineExercise`, and `SetPrescription` domain values. Their relational database/RPC foundation is deployed; the feature-owned composition adapter projects those models while retaining persisted entry/set UUIDs in immutable envelopes. The W4A metadata repository provider and ProgramRoutinesController remain scoped to Routine names/list. Merged PR #530 provides a separate nullable app composition repository provider and owner-scoped **read-only** Routine Detail controller for persisted Exercise/Set display; this read-only Detail path itself does not mutate composition; merged #551 separately supplies guarded Create/Edit. Program ownership does not mean embedding anonymous Routine JSON or removing Routine identity.

## Target Flow

Primary Program-context flow:

```text
Library
→ Program
→ Add Routine
→ generated non-blank name is visible (for example Routine 1)
→ user may rename
→ add Exercises / prescriptions
→ save inside the owning Program
```

Approved direct Library entry:

```text
Library
→ Routine quick action / Create Routine
→ resolve exactly one canonical default My Program
→ create/edit Routine
→ save inside My Program
```

There is no standalone `Library → Routines` collection/category. A Library-level create entry is permitted because entry location is not ownership: the Routine still cannot be persisted until exactly one owning Program is resolved. The default `My Program` must be resolved idempotently through a stable identity contract; mutable display-name matching is not sufficient and runtime implementation remains gated until W1 defines that mechanism.

## Initial Routine Metadata

The first Routine slice needs only the metadata required to identify and compose the Routine. A name is present from creation because the flow generates one before confirmation. An optional Routine image may be added by a later editing/media slice; it is not required to create a Routine and does not authorize Storage work now.

Exercise selection opens the canonical Workout Exercise picker. Routine composition references canonical Exercise identities rather than cloning Exercise definitions.

## Navigation And Rules

- Routine create/edit is normally entered from its owning Program. A Library-level create entry may also start the flow, but it must resolve the canonical owning `My Program` before persistence.
- A Routine cannot be saved as an orphan user Library item.
- Program adoption/copy may create user-owned Routine copies as part of the adopted Program structure while retaining approved source lineage.
- Starting an active workout from a Routine remains a deliberate selected-context flow; this document does not implement Active Workout.
- Scheduling/following a reusable Program/Routine is a later TrainingPlan concern.

## Data And States

- Routine identity/composition stays Workout-owned.
- **Shipped minimal Routine metadata persistence:** The original six columns `public.user_workout_routines(id, user_id, program_id, name, created_at, updated_at)` remain live, with owner RLS and the composite `(program_id, user_id)` Program foreign key. `RoutineRepository` and `SupabaseRoutineRepository` expose `list(programId)`, `create(routine)`, and `rename(id, name)`. Authenticated clients have SELECT, INSERT limited to those six metadata columns, and UPDATE(name); direct delete, ownership changes and moves remain unavailable.
- **Deployed composition database foundation:** Migration `20261010061809_create_user_workout_routine_composition.sql` from [#511](https://github.com/im-tnyx/tio-world/pull/511) was applied and independently hosted-verified on 2026-10-11. Routine adds `composition_revision` and `last_composition_mutation_id`; ordered Exercise/set child tables have owner-safe FKs and authenticated owner SELECT only. The narrow atomic save RPC manages revision/idempotency and child writes; direct client revision/token writes are denied. See [schema inventory](../data/SUPABASE_SCHEMA.md).
- **Approved adapter slice:** `RoutineCompositionRepository` / `SupabaseRoutineCompositionRepository` implement owner-scoped reads drained through empty UUID-cursor pages and bracketed by the parent revision/mutation token. These are validated independent requests, not one database transaction. Saves call the existing RPC once with frozen IDs/token/expected revision; ambiguous replies use read-only reconciliation and may remain explicitly unknown. Feature analysis and 84 focused tests passed for the approved adapter slice; reviewed PR #513 merged at `dfe9cee7389165f0a485623a1e3e69477eb1dc37`.
- **W4A UI (merged PR #522):** The nullable app-level `routineRepositoryProvider` uses `SupabaseRoutineRepository` without an in-memory durability fallback. Selected Program names open `ProgramDetailPage` when the repository exists; `ProgramRoutinesController` owns Program-scoped Routine list, generated-name metadata creation, persisted rename, failure/retry and ambiguous-save reconciliation. On current merged `main`, the Routine card's **primary tap** opens selected owner-scoped **read-only Routine Detail** while the separate overflow **Edit → Rename** retains metadata rename. Absent repository/auth capability fails closed. After #551 the Create/Edit Exercise+Set editor exists on merged main, but the repository is **not** evidence of an app-store release or Workout Start.
- **Next data gate:** W1/TNYX-78 remains In Progress for broader Workout acceptance; [GitHub #509](https://github.com/im-tnyx/tio-world/issues/509) is Closed after the composition persistence foundation and Flutter adapter were merged. Composition provider/controller **read-only consumption** was merged via PR #530, and the visible Routine Create/Edit builder subsequently merged in PR #551; stable default `My Program` identity and atomic Name+composition Update remain separately gated. The adapter merge alone did not approve composition editing or Workout Start. Any additional Supabase table/column shape still requires explicit Owner Approval.
- **Separate W1 decision:** direct Library Create Routine remains blocked on stable, idempotent default `My Program` identity independent of its mutable display name.
- The historical W1B0 Program privilege-hardening slice is complete; it was not approval for Routine composition or Exercise Favorites/Folders persistence.
- Completed WorkoutSession history must not be silently rewritten by later Routine edits.

## Acceptance Criteria

- Every saved user-owned Routine has one owning Program.
- Routine has stable identity and is not anonymous nested data.
- No standalone Library Routines collection/category exists; a create entry action does not create standalone Routine ownership.
- Exercise selection is nested in Routine editing and cannot start a workout by itself.
- Optional image/metadata does not block initial Routine creation.
- Scheduling/following remains separate from reusable Routine truth.

**Delivery boundary:** Read-only Routine Detail (#530) and Create/Edit Exercise+Set builder (#551) are merged into `main`, but no distributed release is verified. Workout Start, atomic Name+composition Update and secure Routine Delete are separate gates.

## Related

- [Workout](workout.md)
- [Library](library.md)
- [Programs](programs.md)
- [Exercise Search](exercise-search.md)

## Historical W4B Exercise replacement (merged via #551)

The owner approved `Replace Exercise` alongside `Remove Exercise` in the
existing Create/Edit Exercise `⋮` sheet. Merged PR #551 reuses the canonical
Exercise picker, keeps the replaced Exercise's ordered position, and gives
the selected Exercise a **new entry UUID and blank Set 1 UUID**. It does not
copy prescriptions, range modes or targets between potentially incompatible
Exercise measurement types. Canceling the sheet/picker leaves the draft
unchanged; Edit writes only after explicit Update. Current-owner/Custom
preflight, auth/session revocation, eight-Set cap, and nullable target
contracts remain in force. Source code is merged on `main`; release/device verification was not established by the code merge alone.

## One canonical Create/Edit Routine composer — merged #551

Owner-approved #564 follow-up (UI-only bounded branch, **not yet on main**):
- Put Create **Save** and Edit **Update** in the same top-right composer action slot. Keep distinct guarded persistence adapters and their existing confirmation/cancel semantics; do not add a bottom duplicate action.
- On owner-verified read-only Detail, move the existing **Edit Routine** action from the top bar to the right of **Exercises** in that heading row; counts stay below. Preserve it for a historical ready-but-empty Routine and preserve its owner/session/weight-unit guard.
- Owner also requires the same top editable Routine Name input in Edit (prefilled saved name) instead of static name, plus Routine-card 3-dot **Edit Routine** into that full editor. **Those features are separately gated** until a reviewed atomic name+composition Update is available; current metadata rename and composition RPC are distinct. Do not expose a false combined Update or an enabled Delete without its independently authorized lifecycle.


Owner explicitly rejected separately maintained Create and Edit screen UI.
Merged #551 already uses a **single `RoutineComposerScreen`,
`RoutineComposerContent` and `RoutineComposerExerciseCard`** for both
routes, including the title bar, ordered Exercises, column headings, Set rows,
the 38dp Set/Input/Add Set surfaces, and Exercise `⋮` options. The same
composition is configured in Create mode (`Create Routine`, empty draft,
atomic Save) or Edit mode (`Edit Routine`, loaded owner Routine, read-only
PREVIOUS column and revision-guarded Update). Existing Create/Edit route
entrypoint state owners remain thin adapters for different auth/persistence,
Custom preflight, unknown-write resolution and validation rules. This avoids
duplicated visual implementations without incorrectly unifying two distinct
database commands. No new DB schema, service, route, watch UI or visual redesign
is authorized. The later #564 UI-parity changes require their own exact-head Flutter CI, independent review and device QA before merge.

## Numeric Set field focus dismissal (merged #551; release/device QA unverified)

Create and Edit share the same Routine composer. Touching outside a
focused boxed Set numeric field removes its focus outline; switching
from KG to REPS still focuses the selected field. Hiding the on-screen
keyboard explicitly dismisses focus on a visible-to-hidden IME event
rather than leaving a numeric field permanently selected. Typed values
are retained. This does not change the 38dp layout, visual styling,
nullable Set targets, or generic TioInput forms.

## SET badge and boxed input corner alignment (merged #551; release/device QA unverified)

The Create Routine SET-number filled badge and KG/LB/REPS/Range/KM/TIME
outlined input fields use one matching **14dp** corner radius, governed
by Core `TioInputTokens.radius`. The Set number's InkWell splash/tap
shape follows that same radius. The previous Set number used
`TioRadius.md` (12dp), causing a visible mismatch against Core's 14dp
numeric outlines. Edit retains its approved unboxed blue Set number.
38dp visible minimum heights and widths, 8-Set cap, input/focus
behavior, button shapes, and all persistence contracts remain unchanged.

## Swipe-to-delete Set action (merged #551; release/device QA unverified)

Swiping a Routine Set left reveals a compact right-aligned red
`Delete` control, matching the 38dp boxed Set/input height and 14dp
rounded input shape. The exposed remainder of the row stays the screen's
normal background, **not a full-width red stripe**. Swipe crossing the
reveal threshold (including a quick flick) gives selection haptics;
tapping Delete gives deletion haptics. A deliberately long left swipe
continues to remove the chosen Set on release with the deletion haptic;
a short flick alone never auto-deletes, and reversing before release
does not remove. Deletion is still an in-memory Routine draft action
until Create Save/Edit Update; deleting the last Set obeys the existing
Exercise removal policy. Actual touch and OLED/light appearance still
need device QA.

## Dynamic swipe reveal shape (merged #551; release/device QA unverified)

The red Delete action starts hidden. While dragging a Set left, its
rounded shape grows **horizontally** with the exposed row area, staying
fully visible with the same 8dp gap as the KG/REPS fields; it does
not touch the moving field, crop its corners or become a red strip. Its
normal painted minimum height remains **38dp**, with the existing 14dp
rounded corners. On partial release it settles to the usual 96dp
Delete width; deliberate full swipe still removes the Set, with
selection and deletion haptic feedback intact. Physical-device
validation remains pending.

## Delete action gap, label and height (merged #551; release/device QA unverified)

Owner clarified that, while swiping, the Delete shape must not stick
directly to the numeric field: preserve **8dp** of clear space between
the moving field edge and the red capsule, matching the KG/REPS field
gap. The capsule still expands with the swipe: its painted width equals
the revealed region **minus 8dp**, and the settled 96dp reveal therefore
shows an **88dp** action plus the 8dp gap. The Delete label is
**explicitly white** while swiping and once revealed (including the
temporarily disabled drag state). Its 14dp corner radius and
**38dp painted minimum height** align vertically with KG/REPS fields.
Short swipe/tap, full-swipe deletion and the two haptic stages are
unchanged. Real device screenshot/touch verification is still pending.

## Delete painted-height correction (merged #551; release/device QA unverified)

The Delete action must appear **exactly 38dp tall at normal text scale**,
not merely request a 38dp *minimum*. Enforce the 38dp painted Material
button height explicitly while keeping Material's padded tap-target
policy; large accessibility text is permitted to grow rather than clip.
Its top/bottom align with boxed REPS/KG inputs; the 8dp horizontal gap,
14dp corner radius, swipe-progressive width and settled 88dp capsule
remain. Use the theme's owned `TioPalette.white` token for the visible
Delete label (including during disabled drag); never introduce raw
framework colors into production UI.

## Add Exercises selection-mode UI (merged #551; release/device QA unverified)

In Create/Edit Routine `Add Exercise` context only, reuse the canonical
`ExercisesPage` with transient, insertion-ordered multi-selection by
canonical Exercise identity. A selected Exercise displays a small round
check on its image; missing artwork uses a visible accessible checkmark.
When zero Exercises are selected, no bottom Add button or reserved space
appears. The first selection reveals `Add 1 exercise`; further
selections update to `Add N exercises`. Search/filter changes do not
clear selection. Confirmation appends individually identified Exercise
entries with new blank Set 1 drafts, without persistence until Save/
Update; Back discards pending picks. Normal Library browsing remains
unchanged, and Replace Exercise keeps single selection. This behavior
is owner-approved under existing PR #551, not released.
