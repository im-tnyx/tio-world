# Program-owned Routines

Document Status: Canonical Live Doc (merged W4 Create/Edit composer, atomic Name+Sets Edit and Core Routine actions; broader Workout execution gated)
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
- **W4A UI (merged PR #522; extended by #551/#577/#581):** The nullable app-level `routineRepositoryProvider` uses `SupabaseRoutineRepository` without an in-memory durability fallback. Program Detail reads owner-scoped Routine metadata and Routine card primary tap opens persisted read-only Detail when composition capability is available. The former overflow metadata Rename is historical: verified Routine 3-dot now opens a Core bottom sheet with real full **Edit Routine** (#577/#581), and Edit uses one atomic Name+composition Update; Move/Delete remain without live callbacks. Absent repository/auth/owner/session capability fails closed. This is not a shipped app-store release or Workout Start.
- **Next data gate:** W1/TNYX-78 broader Workout acceptance remains separately tracked; [GitHub #509](https://github.com/im-tnyx/tio-world/issues/509) is Closed. #530 merged read-only composition consumption; #551 merged the Create/Edit builder and Exercise picker; #576 supplied the approved atomic Name+composition RPC and #577 the guarded Flutter Edit; #581 supplied the Core actions sheet. Stable default `My Program` identity for direct Library-root Create, Workout Start and secure Routine Move/Delete remain separate gates. Additional Supabase table/column shape would need explicit Owner Approval.
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

**Delivery boundary (focused 2026-10-17 current-source verification):** Routine Detail (#530), Create/Edit Exercise+Set builder (#551), Program-scoped Library Add Routine (#566), single atomic Name+composition Edit (#576/#577), and guarded Core Routine-actions bottom sheet with real Edit (#581) are merged source. No distributed release/device QA is verified. Workout Start, direct Library-root default-Program quick-create, owner-safe Routine Move/Delete and broader W4 acceptance remain gated.

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

**2026-10-16 source/rollout update:** The owner-approved Name+composition migration `20261016120000` from merged PR #576 is **deployed on hosted Supabase and read-only schema/permissions verified**, including the `update_user_workout_routine_with_composition` seven-argument authenticated RPC. Legacy four-argument composition Save and direct metadata Name clients remain supported. This is database/runtime truth, **not Flutter Edit Name functionality or an app release**.

**Merged Flutter [PR #577](https://github.com/im-tnyx/tio-world/pull/577)** integrates the saved Name input with the shared Edit composer and the single atomic Name+composition Update, including a real card **Edit Routine** action. The former Rename-only sheet is no longer the card action. Source merge and hosted RPC deployment do not prove a distributed phone-app release.

**Routine 3-dot bottom sheet — owner revision 2026-10-16:** The owner explicitly **superseded** the former anchored `TioAnchoredPopup` design. Routine 3-dot must open a **Core bottom sheet** whose target entries are **Edit Routine, Move Routine and Delete Routine**. Reuse the Core sheet boundary without duplicating tokens: Routine actions use **`showTioEditorSheet` + `TioEditorSheet`**, matching the Select Set Type picker, including its own handle and compact header. Program's existing `TioSheet` / `TioGroupCard` rows remain distinct and unchanged. Show only real executable owner-verified capabilities, not inert placeholders. The bounded branch `tnyx/issue-526-routine-actions-bottom-sheet` introduces the UI surface and retains functional Edit; [#569](https://github.com/im-tnyx/tio-world/issues/569) still needs an atomic Move backend, destination selector and confirmation, while [#526](https://github.com/im-tnyx/tio-world/issues/526) still needs guarded Flutter Delete adapter/confirmation/unknown-outcome handling despite its deployed RPC. **The owner additionally approved matching outlined Set Type-style option cards and the same Routine sheet in both Program Detail and expanded Library Programs.** The action options keep the exact Set Type outlined-card border/padding/icon-area dimensions, instead of taller custom rows. Only the canonical shell-guarded full Edit action is wired there until independently delivered Move/Delete capabilities exist. PR #581 also addresses a P1 stale-callback review by rechecking current Routine/program identity and capability after sheet dismissal. **Until that UI branch merges, `main` continues to render the anchored popup, and the expanded Library has no Routine overflow. This change does not ship all three capabilities.**

Owner-approved #564 follow-up: its **UI-only Create/Edit/Detail parity sub-slice merged in PR #570**; editable saved Routine Name and Routine-card overflow Edit/Delete remain independently gated:
- Put Create **Save** and Edit **Update** in the same top-right composer action slot. Keep distinct guarded persistence adapters and their existing confirmation/cancel semantics; do not add a bottom duplicate action.
- Use an accessible leading **X** close action instead of the visible **Cancel** text in both modes; place the mode title start-aligned after X using existing Core `TioAppBar` placement. X still invokes the existing guarded Cancel callback and is disabled while writing; no new draft-discard/persistence behavior.
- On owner-verified read-only Detail, move the existing **Edit Routine** action from the top bar to the right of **Exercises** in that heading row; counts stay below. Preserve it for a historical ready-but-empty Routine and preserve its owner/session/weight-unit guard.
- Owner also requires the same top editable Routine Name input in Edit (prefilled saved name) instead of static name, plus Routine-card 3-dot **Edit Routine** into that full editor. **Those features are separately gated** until a reviewed atomic name+composition Update is available; current metadata rename and composition RPC are distinct. Do not expose a false combined Update or an enabled Delete without its independently authorized lifecycle.


Owner explicitly rejected separately maintained Create and Edit screen UI.
Merged #551 already uses a **single `RoutineComposerScreen`,
`RoutineComposerContent` and `RoutineComposerExerciseCard`** for both
routes, including the title bar, ordered Exercises, column headings, Set rows,
the 38dp Set/Input/Add Set surfaces, and Exercise `⋮` options. The same
composition is configured in Create mode (`Create Routine`, empty draft,
atomic Save) or Edit mode (`Edit Routine`, loaded owner Routine,
revision-guarded Update). Both modes reserve the same read-only PREVIOUS
header and 64dp Set-row slot from merged PR #570, displaying an unavailable dash
until genuine performed workout history exists. Existing Create/Edit route
entrypoint state owners remain thin adapters for different auth/persistence,
Custom preflight, unknown-write resolution and validation rules. This avoids
duplicated visual implementations without incorrectly unifying two distinct
database commands. No new DB schema, service, route, watch UI or visual redesign
is authorized. The #564 UI-parity sub-slice merged in PR #570 after exact-head CI/review and owner device QA. In that implementation, Create/Edit app-bar title typography remains 18sp/w800 and Routine Detail app-bar remains 20sp/w800. All three surfaces display Exercise names at 16sp/w500, maximum two lines with ellipsis. Read-only Routine Detail reserves the same trailing 48dp space used by the Create/Edit Exercise-row 3-dot action, without displaying an inert options button; this keeps long-name wrapping consistent at equal viewport sizes.

## Previous Workout values in Routine composer (merged #570 layout, history deferred)

The owner-approved shared Create/Edit Set grid is always laid out as
`SET | PREVIOUS | KG/LB | REPS` for weight-and-reps exercises. The
corresponding distance/time measurement profile keeps its existing units,
but uses the same 64dp PREVIOUS placeholder slot. The header and row
spacing are identical in Create and Edit. As merged in PR #570, these are
**presentation-only placeholders**, shown as `–` with an accessible
unavailable label; nothing is auto-filled. Template `SetPrescription` data
must never be passed off as performed workout history.

**Deferred performed-history interaction (not implemented):** When
actual completed `WorkoutSession`/`PerformedSet` history exists for
the authenticated owner and canonical Exercise identity, a matching
previous performed set may display a compact truthful value such as
`10kg x 10` (or correctly converted LB / a suitable typed profile).
Selecting an available previous value copies its supported load/reps
into that **one current draft Set** in Create or Edit without an automatic
Save, Update, history mutation or new logged session. When no matching
history exists, keep a dash; it is not tappable. Historical Set matching,
set type/ordering, unit conversion, mixed measurement profiles, ambiguous
sources, and edit-overwrite semantics need separately reviewed rules
rather than inferred values.

**Deferred preference:** Workout Runtime Settings (#48; W10/TNYX-87)
will eventually offer `Show Previous Workout Values` (preserve the
currently visible default unless the owner changes it). Its visibility
setting must feed a single canonical Workout preference into **both**
Create and Edit, hiding header and row cells together and returning that
space to the input columns. Setting persistence/eligibility must follow
the audited Workout Settings boundary; do not add local duplicate
booleans or Profile/Targets storage now. True performed data requires
W7/TNYX-84 and W8/TNYX-85; this Draft implements no schema,
`PerformedSet` repository, session history read or tap-to-copy.

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
numeric outlines. On the merged #551 baseline, Edit/PREVIOUS kept an
unboxed blue Set number, unlike Create's filled badge. The owner-approved
#564 follow-up merged in PR #570 uses the same Core `surfaceVariant`
filled Set badge in **both Create and Edit**. The preferred number/type
foreground stays on its existing theme role where readable (including the
Edit primary/blue number), but falls back to black or white when necessary
to achieve at least **4.5:1 contrast** against the filled background.
History-column visibility is **independent** of Set-number foreground:
Create retains the Create normal-Set theme foreground when PREVIOUS is
visible, whereas Edit explicitly selects its existing Edit primary/blue
preference (still subject to the same contrast fallback). This
applies to normal and W/F/D Set types, standard light/dark/Tio Dark and OS
high-contrast variants. Both modes reserve a read-only PREVIOUS
column; empty cells display only a dash and do not represent historic
WorkoutSession values. Both modes use the same 38dp filled, 14dp rounded
Set type control.
The 8-Set cap, input/focus behavior, button geometry and persistence
contracts remain unchanged.

Draft PR #574 (unmerged) proposes that Create and Edit Set Type selection
sheets share the same Workout-owned 38dp filled Normal/W/F/D indicator and
Core theme semantic foreground/contrast fallback as the existing Set row.
Both option rows and `Remove Set` use the reusable Core
`TioCardVariant.outlined` surface with 12dp horizontal/8dp vertical content
padding. An owner-approved, reversible **0.75dp outline trial** is isolated
to these picker cards via the existing `TioCardTokens.borderThin` token and
an outlined-only Core `outlinedBorderWidth` parameter; all other Core
outlined cards retain their default 1dp stroke. The resulting expected
standard-text height is 55.5dp (38dp badge + 8dp vertical padding per
side + 0.75dp outline per side), pending exact-head widget CI and device QA.
Large text may increase the height. The selection checkmark and accessible
selected state remain; Normal previews the selected Set's prospective
Normal-only number excluding special types. The outlined `Remove Set`
row retains its danger-colored trash icon and Create/Edit deletion behavior.

By explicit owner approval, Edit's obsolete `Rest & set details` selector
action is removed; saved per-Set `restSeconds` values survive Set type,
inline input and Update changes. Legacy Rest editing is no longer exposed
until the separately planned W4B2 Rest Timer/Notes flow (#532). No new Rest
Timer, Notes, schema/RPC or performed WorkoutSession behavior is part of
Draft PR #574.

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
