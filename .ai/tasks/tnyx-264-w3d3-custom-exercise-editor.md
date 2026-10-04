# TNYX-264 W3D3 — Visible Custom Exercise editor and collection

**Status:** In progress
**Primary owner:** `apps/features/workout` Custom Exercises; `apps/app` only for composition/routing
**Affected platforms:** Flutter phone UI; existing Supabase persistence only

## Owner Approval and Scope Boundary

**Trigger:** New independently scoped product-visible feature slice.
**Approval status:** Approved.
**Approval evidence:** Owner said `Go` on 2026-10-01 for the visible W3D3 slice, then on 2026-10-04 explicitly rejected the simplified generic-selector UI and directed implementation to match the already documented owner-approved Custom Exercise interaction.

**Approved visible/data scope:** User-created Exercises composed into the canonical Exercises capability plus create/edit form over the already-live W3D2 definition contract: required name, optional description, one of the 11 Exercise Types, Primary muscle, Secondary muscles, Primary equipment, and existing archive lifecycle. The editor interaction must follow the owner-approved TNYX-264 direction: Exercise Type uses a Tio-owned single-select list with its capability-hint tags; Primary muscle is selected through derived Body Part grouping then a single muscle; Secondary muscles use the complete canonical muscle set as multi-select; Equipment is single-select. Body Part and capability tags are presentation-only and are never persisted. Reuse canonical `Exercise`, `UserCreatedExerciseRef`, `UserExerciseDefinition`, `UserExerciseRepository`, W3D1 controller foundation, and Tio Core UI.

**Explicit non-goals:** no media/Storage; no distance/duration/steps/weight/reps/+KG/-KG/x1/x2 execution semantics; no Favorites/Folders; no Routine/Program/Active Workout changes; no Supabase table/column/RLS/grant change; no broad GitHub #475 Library redesign; no new competing Exercise truth. A separate user-facing Custom Exercises collection is no longer a target.

## Active Handoff

**Planning/implementation owner:** ChatGPT repository architecture workflow
**Review owner:** Codex after PR creation
**Repository state last verified:** `main@c58689a8a7f183a0ca5fb644e4f69d67b2157bbe`
**Branch:** `tnyx/tnyx-264-w3d3-custom-exercise-editor`
**Working-tree visibility:** Connector-only execution; local worktree/toolchain is not available, so no local cleanliness or local Flutter-run claim.
**Tracker:** Linear TNYX-264, In Progress; W3D2 is validated/live.
**Current blocker:** The owner-approved editor selectors and unified catalog + user-created Exercises composition are implemented on the branch, including `Custom` badge/tag rows, shared search/filter participation where taxonomy exists, Custom-focused navigation on the same route, and removal of the separate collection page/route. Exact-head Flutter CI and fresh Codex review are still pending. The inferred full Body Part → 44-muscle membership is not yet backed by a separate canonical mapping source, so that mapping remains an explicit validation risk rather than silently claimed product truth. Asset remains separately gated by media/Storage architecture.
**Next exact action:** run exact-head hosted Flutter CI, repair any compile/test findings, then obtain a fresh Codex review with zero unresolved threads. Do not widen into Favorites/Folders/Recent/media/Library redesign.

## 1. Discovery

### User Outcome
Users see user-created Exercises on the same canonical Exercises screen as catalog Exercises, distinguished by a `Custom` badge/tag; they can create a complete structured definition, edit that definition later, and archive an Exercise without creating a second domain model.

### Success Criteria
- The canonical `/workout/exercises` screen composes catalog Exercises and active user-created Exercises in one presentation surface; Custom rows carry a `Custom` badge/tag instead of living behind a separate collection screen.
- A Custom-focused entry may open the same canonical Exercises surface in a Custom-focused/filter state; it must not introduce a second user-facing collection truth.
- Create writes name + one atomic `UserExerciseDefinition` with a stable UUID.
- Edit preserves identity/owner/lineage/lifecycle while updating name and definition.
- Primary/secondary muscle validation remains domain-owned; UI cannot persist duplicate secondary or primary overlap.
- Archive remains soft lifecycle change.
- Missing durable persistence fails closed; no in-memory production success.
- UI uses public Tio Core components/tokens and accessible labels.
- Existing catalog Browse screen remains canonical and unchanged except bounded navigation/composition if required.

## 2. Codebase Exploration

Verified on 2026-10-01:
- W3D1 `CustomExercisesController` already owns load/create-name/rename/archive and stable-id reconciliation.
- W3D2 `UserExerciseDefinition` and `UserExerciseRepository.updateDefinition` own structured definition validation/persistence.
- App composition already exposes nullable `userExerciseRepositoryProvider` backed by Supabase only.
- `exerciseTaxonomyLabel` is the existing presentation label helper.
- `ExerciseType` owns the 11 durable storage identities.
- Library currently exposes Programs + Browse Exercises only; GitHub #475 documents future Custom Exercise collection composition.
- No schema change is required.

## 3. Architecture Design

```text
App route/composition
  -> canonical Workout ExercisesPage (catalog + user-created composition)
    -> CustomExerciseEditorPage for create/edit
    -> CustomExercisesController
      -> UserExerciseRepository
        -> SupabaseUserExerciseRepository
          -> existing owner-scoped user_workout_exercises
```

Feature widgets render state and emit intent only. The controller owns write sequencing/reconciliation. Domain validation remains in `UserExerciseDefinition`.

## 4. Implementation Plan

- [x] Extend controller create/edit operations to accept validated structured definitions without splitting identity/lifecycle ownership.
- [x] Add provider/composition seam for nullable durable repository.
- [x] Replace the separate user-facing Custom Exercises collection with unified composition on canonical `/workout/exercises`; Custom rows show a `Custom` badge/tag and remain normal canonical `Exercise` items.
- [x] Custom-focused navigation reuses `/workout/exercises?custom=true`; the separate collection route/page is removed from the active branch.
- [x] Primary muscle UI implemented: Body Part → Primary muscle single-select; focused regression exists. Exact full grouping still needs canonical evidence/reconciliation before final validation.
- [x] Exercise Type UI implemented: Tio-owned bottom-sheet single-select list with the 11 approved capability hints.
- [x] Secondary muscle UI implemented: full canonical muscle list, multi-select, excluding Primary.
- [x] Equipment UI implemented: bottom-sheet single-select over the approved equipment taxonomy.
- [x] Add minimal route contracts and app composition needed to reach the real W3D capability.
- [x] Add focused controller/widget/router tests.
- [x] Update canonical Exercises/Library docs only for behavior actually delivered.
- [ ] Run exact-head hosted Flutter CI and Codex review before merge.

## 5. Validation / Exit

No completion claim until exact-head tests/CI and review are verified. Flutter CI run #2910 failed on the prior head because the edited retry generated a second Exercise ID; the current repair scopes pending create identity to one editor draft and adds focused same-draft/new-draft regression coverage. This repair is not validated until a newer exact-head run passes. Supabase migration/security validation is not rerun as a schema deployment because this slice changes no database shape; repository security assumptions must remain unchanged in source/diff audit.
