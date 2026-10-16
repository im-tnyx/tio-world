# Library Screen

Document Status: Canonical Live Doc
Last Verified: 2026-10-12
Owner: `apps/features/workout`
Truth Boundary: Authoritative for the Workout Library product contract, ownership, and documented current/target behavior; runtime source wins for actual shipped behavior and trackers own delivery status.

**Surface:** Nested phone Workout destination; not a bottom-nav tab now
**Route:** `/workout/library` (`AppRoutes.workoutLibrary`), nested in the Workout branch
**Primary owner:** `apps/features/workout`
**Status (focused source verification 2026-10-17, `main@633dbf38`):** `/workout/library` displays owner-scoped persisted Programs, expanded Routine rows and the unified Exercises actions; selected Program names open Program Detail. Merged PR #566 adds a Program-scoped dashed **Add new routine** empty-state card and real **Add New Routine** in the Program 3-dot bottom sheet when authenticated Create is available. Both open the existing guarded Program-owned composer; they do not add a Library-root default `My Program` shortcut. Saved Routine cards open read-only Detail; merged #577 wires real full-composer Edit with atomic Name+Sets Update, and #581 renders the shared Core actions bottom sheet for current verified capabilities, not fake Move/Delete rows. Dedicated Exercises browse/create/edit and Routine-context picker are available through their respective feature flows. `Your Plan`, Favorites/Folders, Workout Start, secure Routine Move/Delete and Program Delete remain separately gated; no published device release is implied.

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
- Workout Home → Library and Library → canonical Exercises use `push`, so back retraces Exercises → Library → Workout Home. The app shell supplies the callbacks; Workout presentation does not import route paths.
- The Library top bar has one search icon (tooltip `Search exercises`). It pushes `/workout/exercises?search=true`, which opens Exercises with its top-bar search field already active and focused; back returns to Library.
- Library shows the currently available category pills `Programs` and `Exercises`. `Your Plan` is absent until a real applicable/followed TrainingPlan capability is available. Programs is the default content.
- With no explicit selection, the full pill strip remains visible and Programs content renders the persisted Program collection directly on Library. Explicit Programs selection collapses the strip to circular X + selected Programs while preserving that same inline collection.
- Selecting Exercises collapses the strip to circular X + selected Exercises. With durable user-Exercise persistence available, it shows exactly two current standalone action cards: **Create Exercise** and **Exercises**. If that repository capability is unavailable, Library fails closed by hiding Create Exercise while keeping Exercises available. No `TioGroupCard` wraps the action cards, and no Exercise rows render inside Library.
- **Create Exercise** opens the feature-owned Create Exercise page directly over Library. That page loads the existing W3D `CustomExercisesController` and renders the existing `CustomExerciseEditorPage`; it does **not** mount `/workout/exercises` first. Back or a successful save returns to the same selected Exercises Library state.
- **Exercises** pushes normal `/workout/exercises`, where bundled catalog and active user-created Exercises compose together. User-created rows carry the presentation-only `Custom` badge/tag and open the existing edit flow.
- The previous Library `Custom Exercises` row and Custom-only `?custom=true` product mode are retired. A legacy `custom=true` query no longer filters the canonical page.
- The Programs section shows persisted owner-scoped Programs with expanded Routine children (#525) and read-only Detail (#530). Verified Program-scoped Create from the expanded empty-Program dashed card and **Add New Routine** Program 3-dot option merged in #566; both remain capability-, auth- and owner-gated and resolve the selected `ProgramId`. Program 3-dot still has real Edit Program/Rename, but no enabled Delete Program. Routine cards use a separate Core actions sheet (#581) exposing only executable owner-verified actions, currently real Edit via #577; Move/Delete are not supplied without their own secure integration. The optional `/workout/programs` route remains available, and Library's Exercises category uses standalone Create Exercise / Exercises cards; no top-level Routines category, `Your Plan` placeholder or future Favorites/Folders.

## Target Sections

GitHub #475 defines the approved target Library navigation while preserving capability ownership:

```text
Library
├─ Programs        // default selected category
├─ Exercises       // second category
└─ Your Plan       // only when a real followed/applicable TrainingPlan exists

quick actions
├─ Routine
└─ Explore
```

The target category strip is presentation/navigation only; it never creates Library-owned Program, Routine, Exercise or TrainingPlan truth.

### Target category-selection interaction

The owner-provided screenshots are reference only for the category-pill selection interaction. They do not define the Tio Library top bar. Category names/content remain Tio-owned and selected/unselected visuals must use the Tio design system:

```text
all-category state
[ Programs ] [ Exercises ] [ Your Plan* ]

explicit selection
[ X ] [ Programs selected ]
        or
[ X ] [ Exercises selected ]
        or
[ X ] [ Your Plan selected ]
```

- the full selector row shows all currently available category pills horizontally;
- Programs is the default Library content when the screen opens;
- selecting a category collapses the selector to a circular X/clear control plus the selected highlighted pill and temporarily hides the other pills;
- tapping X clears the explicit selection, restores the full available category strip, and returns content to Programs;
- Exercises is always available after Programs;
- Your Plan is rendered only when a real followed/applicable TrainingPlan exists;
- there is no Routines category/tab;
- selected/unselected pill appearance must use the Tio design system; the reference establishes only the pill-selection interaction, not the Library top-bar design or a pixel-for-pixel style copy.


### Programs

Programs is the default category.

- Persisted Programs render directly on Library. W4A added owner-scoped Program Detail/Routine metadata. The merged #551 Create/Edit composer, #566 selected-Program Library Add Routine entry, #577 atomic full Routine Edit, and #581 current-capability Routine actions sheet extend that implementation. Direct Library-root default `My Program` quick-create, TrainingPlan scheduling and owner-safe Move/Delete remain separately gated.
- The Programs header may open the secondary Programs collection/manage route, but that route is not a mandatory intermediate step before an individual Program.
- An individual Program opens Program detail directly.
- Program-owned Routine rows are presentation of the same canonical `RoutineRepository` read under that Program (no Library-owned duplicate). A Program can collapse to hide children, re-expand to reload, or return from Program Detail to refresh Routine children without restarting Library. This is implemented on merged `main` by PR #525, with Routine child-row read-only Detail navigation added by PR #530. Routine reads and taps remain repository/capability-gated.
- There is no standalone Routines category or Routines collection.
- Library may expose a **Routine** quick-create entry. That entry is not orphan ownership: before a Routine is persisted it must resolve exactly one owning Program.
- The approved direct Library Routine behavior targets the canonical default `My Program`. If that Program does not yet exist, runtime implementation must create/resolve it idempotently before Routine persistence. Display name alone is not a sufficient identity contract, so the W1 persistence/domain mechanism remains a prerequisite.

See [Programs](programs.md) and [Program-owned Routines](routine-library.md).

### Exercises

Exercises is the second category.

Selecting it keeps Library chrome in the owner-approved explicit-selection state:

```text
[ X ] [ Exercises selected ]

Create Exercise
Exercises
```

The selected Library state does **not** render Exercise rows. The current actions are separate cards, not grouped rows:

```text
[ Create Exercise card ]

[ Exercises card ]
```

- `TioGroupCard` is not used for this Exercises action surface.
- **Create Exercise** is rendered only when canonical durable user-created Exercise persistence is available; otherwise the card is hidden rather than navigating to a dead create flow.
- **Create Exercise** enters the existing W3D user-created Exercise flow directly over Library. It does not route through the Exercises browse screen, and it does not create a second editor, controller contract, repository, or Exercise model. Back/save returns to the selected Exercises Library state.
- **Exercises** opens the canonical `/workout/exercises` browse/search/filter screen.
- Bundled/catalog Exercises and active user-created Exercises compose together only on that canonical screen.
- User-created rows remain normal canonical `Exercise` items and carry the presentation-only `Custom` badge/tag.
- There is no separate Custom Exercises screen/collection or Custom-only product state.
- Favorites and Folders remain W3C/W3E capabilities and must integrate with canonical Exercise identity when implemented. Until then they are hidden; once real, each Library entry is an additional standalone card alongside Create Exercise and Exercises.

### Your Plan

`Your Plan` is the third category **only when** the user has a real followed/applicable canonical TrainingPlan.

```text
real followed/applicable TrainingPlan
→ show Your Plan

no applicable TrainingPlan
→ hide Your Plan completely
```

There is no disabled/empty placeholder tab. The view is supplied by W9/TNYX-86 and W6C/TNYX-268; Library owns no scheduling or TrainingPlan truth.

### Current-runtime distinction

The existing category strip, inline Programs collection and Exercise entry geometry remain unchanged. Merged #525 provides owner-scoped expanded Routine rows and #530 read-only Routine Detail. Merged #566 adds selected-Program dashed empty-state Add Routine and Program-scoped Add New Routine; #577 wires the existing guarded full composer Edit; #581 changes only the Routine-card 3-dot surface to the shared Core sheet. Other #475 behavior remains capability-gated: direct Library-root `My Program` quick-create, Routine/Explore shortcuts, Delete Program, Routine Move/Delete, Favorites/Folders and `Your Plan`.

## Minimal Program Creation Contract

Explicit Program creation presents an already generated non-blank name such as `Program 1` before confirmation. The user may rename it before OK. Blank-name fallback is not the user-facing contract.

The approved direct Library Create Routine entry has a separate ownership requirement: it targets one canonical default Program presented as `My Program`. Runtime implementation must resolve/create that default idempotently and must not treat the mutable display name as the durable identity. Any Supabase table/column shape needed to provide a stable default-Program discriminator requires its own approved persistence slice.

For a user-created Program, the initial editable surface remains minimal. Richer source metadata is not requested from the user. Tio-curated, coach-created and accepted AI-generated Programs may carry richer source metadata under their own source/adoption contracts.

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

Current runtime remains truth until the target slices ship. Target acceptance is:

- One canonical Library route is reused by every entry point.
- Programs is the default target category; Exercises is second.
- The provided reference is used only for category-pill selection interaction, not for top-bar design.
- The category selector can show the full available pill strip, then collapse to circular X + selected highlighted pill after an explicit selection.
- Clearing selection restores the full strip and default Programs content.
- Your Plan is shown only with a real followed/applicable canonical TrainingPlan and hidden otherwise.
- No standalone Routines category/collection exists.
- When the direct Routine-create prerequisite is ready (including stable/idempotent canonical `My Program` identity), the approved **Routine** quick-action card is required and must start that Program-owned creation flow.
- When the Explore capability/route is ready, the approved **Explore** quick-action card is required and must hand off to the canonical Explore capability rather than a Library-owned copy.
- If either prerequisite capability is not ready, Library must not show a fake/non-functional production quick-action for it.
- A Library-level Routine create entry may exist only when the saved Routine resolves exactly one owning Program before persistence.
- Direct Library Routine creation targets one canonical default `My Program`; the durable/idempotent identity mechanism must be defined before runtime implementation.
- Programs may render directly on Library while the Programs collection/manage route remains optional secondary navigation.
- Selecting Exercises currently shows only **Create Exercise** and **Exercises** actions; it does not embed the Exercise list.
- Each current action is its own standalone card; do not group them inside `TioGroupCard`.
- **Create Exercise** is capability-gated on the canonical durable user-Exercise repository and is hidden when that capability is unavailable.
- **Create Exercise** reuses W3D ownership through the direct feature-owned create page and returns to selected Library on back/save; **Exercises** alone opens the canonical unified `/workout/exercises` browse route.
- Future Favorites/Folders entries remain capability-gated and, once real, appear as their own standalone cards.
- Library never owns competing Program, Routine, Exercise or TrainingPlan truth.
- Existing dedicated Program/Exercise routes remain current runtime until explicitly reconciled by an approved implementation slice.

## Related

- [Workout](workout.md)
- [Exercises and Exercise Picker](exercise-search.md)
- [Program-owned Routines](routine-library.md)
- [Programs](programs.md)
- [Module ownership](../architecture/MODULE_OWNERSHIP.md)
