# Library Screen

Document Status: Canonical Live Doc
Last Verified: 2026-09-30
Owner: `apps/features/workout`
Truth Boundary: Authoritative for the Workout Library product contract, ownership, and documented current/target behavior; runtime source wins for actual shipped behavior and trackers own delivery status.

**Surface:** Nested phone Workout destination; not a bottom-nav tab now
**Route:** `/workout/library` (`AppRoutes.workoutLibrary`), nested in the Workout branch
**Primary owner:** `apps/features/workout`
**Status:** Current runtime remains W6A plus the bounded W6B Program collection/create foundation: Workout Home entry, Library Programs + Exercises navigation rows, persisted Programs collection/create, and dedicated Exercises browse/search. GitHub #475 now defines a newer owner-approved Library category IA, but that target is not yet implemented. Program detail/Routine management, Exercise Favorites/Custom/Folders UI and TrainingPlan/Your Plan remain capability-gated.

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
- Workout Home → Library and Library → Exercises use `push`, so back retraces Exercises → Library → Workout Home. The app shell supplies both callbacks (`WorkoutHomePage.onLibraryPressed`, `LibraryPage.onExercisesPressed`); Workout presentation does not import route paths.
- The Library top bar has one search icon (tooltip `Search exercises`). It pushes `/workout/exercises?search=true`, which opens Exercises with its top-bar search field already active and focused; back returns to Library.
- Library now shows `Programs` above `Exercises`. Programs pushes `/workout/programs`, where persisted user Programs load through the canonical `ProgramRepository`. The screen has AppBar Create (+), a generated editable initial name, honest loading/empty/load-failure-retry/create-failure states, and display-only Program rows until detail/builder work lands.
- There are no sub-tabs, grid/list toggle, standalone Routines row, Program-detail placeholder, or Create/Favorites/Custom Exercise rows until their capabilities exist.

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

### Programs

Programs is the default category.

- Programs render directly on Library when the W4/W6B Program-owned Routine capability is ready.
- The Programs header may open the secondary Programs collection/manage route, but that route is not a mandatory intermediate step before an individual Program.
- An individual Program opens Program detail directly.
- Program-owned Routine rows may expand/collapse inline in Library presentation without changing persistence.
- There is no standalone Routines category or Routines collection.
- Library may expose a **Routine** quick-create entry. That entry is not orphan ownership: before a Routine is persisted it must resolve exactly one owning Program.
- The approved direct Library Routine behavior targets the canonical default `My Program`. If that Program does not yet exist, runtime implementation must create/resolve it idempotently before Routine persistence. Display name alone is not a sufficient identity contract, so the W1 persistence/domain mechanism remains a prerequisite.

See [Programs](programs.md) and [Program-owned Routines](routine-library.md).

### Exercises

Exercises is the second category.

Target Library Exercises content begins with these capability-owned entries:

```text
Create a custom exercise
Favorite Exercises
Custom Exercises
<user-created Exercise folders...>
```

- **Create a custom exercise** and **Custom Exercises** are W3D capabilities.
- **Favorite Exercises** is the W3C relationship/smart view.
- user-created folders are W3E many-to-many Exercise collections.
- These entries appear only when their real capability is implemented; Library must not render fake production affordances.
- Library composes/navigates these Exercise-owned views and never duplicates their repositories or domain truth.
- The existing dedicated `/workout/exercises` catalog/search screen remains the canonical browse/search surface until a later implementation slice explicitly reconciles how catalog browsing is reached from the new category UI.

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

The current shipped Library still shows Programs and Exercises as navigation rows and pushes the dedicated Programs/Exercises routes. It does not yet render this target category strip, Routine/Explore quick cards, inline Program content, Exercise smart-view entries or Your Plan. Those remain future capability-gated implementation slices.

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
- Your Plan is shown only with a real followed/applicable canonical TrainingPlan and hidden otherwise.
- No standalone Routines category/collection exists.
- A Library-level Routine create entry may exist only when the saved Routine resolves exactly one owning Program before persistence.
- Direct Library Routine creation targets one canonical default `My Program`; the durable/idempotent identity mechanism must be defined before runtime implementation.
- Programs may render directly on Library while the Programs collection/manage route remains optional secondary navigation.
- Exercises category composes W3-owned Create Custom, Favorites, Custom and folder views only as those capabilities become real.
- Library never owns competing Program, Routine, Exercise or TrainingPlan truth.
- Existing dedicated Program/Exercise routes remain current runtime until explicitly reconciled by an approved implementation slice.

## Related

- [Workout](workout.md)
- [Exercises and Exercise Picker](exercise-search.md)
- [Program-owned Routines](routine-library.md)
- [Programs](programs.md)
- [Module ownership](../architecture/MODULE_OWNERSHIP.md)
