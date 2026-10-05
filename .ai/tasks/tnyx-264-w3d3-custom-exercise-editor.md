# TNYX-264 W3D3 — Custom Exercise editor and unified Exercises composition

**Status:** In progress
**Primary owner:** `apps/features/workout` Custom Exercises; `apps/app` only for composition/routing
**Affected platforms:** Flutter phone UI; existing Supabase persistence only

## Owner Approval and Scope Boundary

**Trigger:** New independently scoped product-visible feature slice.
**Approval status:** Approved.
**Approval evidence:** Owner said `Go` on 2026-10-01 for the visible W3D3 slice, then on 2026-10-04 explicitly rejected the simplified generic-selector UI and directed implementation to match the already documented owner-approved Custom Exercise interaction. On 2026-10-05 the exact 44-token Body Part presentation map was shown and the owner continued with `Go`, approving that exact presentation-only grouping for W3D3.

**Approved visible/data scope:** User-created Exercises composed into the canonical Exercises capability plus create/edit form over the already-live W3D2 definition contract: required name, optional description, one of the 11 Exercise Types, Primary muscle, Secondary muscles, Primary equipment, and existing archive lifecycle. The editor interaction must follow the owner-approved TNYX-264 direction: Exercise Type uses a Tio-owned single-select list with its capability-hint tags; Primary muscle is selected in one bottom-sheet accordion: tapping a Body Part expands its relevant muscles inline beneath that row, only one Body Part is expanded at a time, and tapping a muscle completes the single selection without opening a second sheet; Secondary muscles use the complete canonical muscle set as multi-select; Equipment is single-select. Body Part and capability tags are presentation-only and are never persisted. Reuse canonical `Exercise`, `UserCreatedExerciseRef`, `UserExerciseDefinition`, `UserExerciseRepository`, W3D1 controller foundation, and Tio Core UI.

**Explicit non-goals:** no media/Storage; no distance/duration/steps/weight/reps/+KG/-KG/x1/x2 execution semantics; no Favorites/Folders; no Routine/Program/Active Workout changes; no Supabase table/column/RLS/grant change; no broad GitHub #475 Library redesign; no new competing Exercise truth. A separate user-facing Custom Exercises collection is no longer a target.

## Active Handoff

**Planning/implementation owner:** ChatGPT repository architecture workflow
**Review owner:** Codex after PR creation
**Repository state last verified:** `main@c58689a8a7f183a0ca5fb644e4f69d67b2157bbe`
**Branch:** `tnyx/tnyx-264-w3d3-custom-exercise-editor`
**Working-tree visibility:** Connector-only execution; local worktree/toolchain is not available, so no local cleanliness or local Flutter-run claim.
**Tracker:** Linear TNYX-264, In Progress; W3D2 is validated/live.
**Current blocker:** Owner clarified on 2026-10-05 that the existing Primary muscle nested-sheet interaction is wrong; W3D3 must use a single bottom-sheet accordion with inline Body Part expansion. The owner-approved editor selectors, unified catalog + user-created Exercises composition, and exact 44-token Body Part presentation map are implemented. Flutter CI #2968 passed on reconciled head `5dd4452e4d0b72d5ac96ceb149dc33e2b0b6cf53`; the branch was 0 behind `main` with zero unresolved review threads. Fresh Codex exact-head review could not run because the Codex bot returned its code-review usage-limit message; the immediately preceding code head `b07d15c3aa718e48382f04f96559da9ebc2be91f` had a clean Codex review, and the two commits after it changed only this task handoff plus the canonical Exercise-search doc. That docs-only delta was manually reviewed against source and the 44-token map matches source exactly with zero duplicates. Asset remains separately gated by media/Storage architecture.
**Next exact action:** replace the nested Primary muscle picker with the approved single-sheet accordion, add focused widget coverage for inline expand/collapse + selection, then run exact-head Flutter CI and Codex review before merge. Do not widen into Favorites/Folders/Recent/media/Library redesign.

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
- [ ] Primary muscle UI interaction correction: keep one bottom sheet open, expand the tapped Body Part inline, collapse the previously expanded Body Part, and select one muscle from the inline subgroup; no nested/forward sheet. Exact 44-token grouping remains owner-approved and canonical.
- [x] Exercise Type UI implemented: Tio-owned bottom-sheet single-select list with the 11 approved capability hints.
- [x] Secondary muscle UI implemented: full canonical muscle list, multi-select, excluding Primary.
- [x] Equipment UI implemented: bottom-sheet single-select over the approved equipment taxonomy.
- [x] Add minimal route contracts and app composition needed to reach the real W3D capability.
- [x] Add focused controller/widget/router tests.
- [x] Update canonical Exercises/Library docs only for behavior actually delivered.
- [ ] Run exact-head hosted Flutter CI on the final handoff-only head; Codex exact-head review is unavailable due verified usage limit, so perform a manual docs-only delta review before merge.

## 5. Validation / Exit

Code validation is complete through Flutter CI #2968 on `5dd4452e4d0b72d5ac96ceb149dc33e2b0b6cf53`. Earlier run #2910 failed because edited retry generated a second Exercise ID; that defect and subsequent Codex findings were repaired with focused regression coverage. Fresh Codex exact-head review is currently blocked only by the bot's code-review usage limit; the previous code head `b07d15c3aa718e48382f04f96559da9ebc2be91f` received a clean Codex review, and later changes are governance/docs reconciliation only. Supabase migration/security validation is not rerun as a schema deployment because this slice changes no database shape; repository security assumptions remain unchanged in source/diff audit.
