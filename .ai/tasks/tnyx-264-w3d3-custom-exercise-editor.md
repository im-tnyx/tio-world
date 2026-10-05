# TNYX-264 W3D3 — Custom Exercise editor and unified Exercises composition

**Status:** In progress
**Primary owner:** `apps/features/workout` Custom Exercises; `apps/app` only for composition/routing
**Affected platforms:** Flutter phone UI; existing Supabase persistence only

## Owner Approval and Scope Boundary

**Trigger:** New independently scoped product-visible feature slice.
**Approval status:** Approved.
**Approval evidence:** Owner said `Go` on 2026-10-01 for the visible W3D3 slice, then on 2026-10-04 explicitly rejected the simplified generic-selector UI and directed implementation to match the already documented owner-approved Custom Exercise interaction. On 2026-10-05 the exact 44-token Body Part presentation map was shown and the owner continued with `Go`, approving that exact presentation-only grouping for W3D3. On 2026-10-05 the owner also confirmed the current functional UI is sufficiently correct for this slice; additional visual polish and icon refinement may follow later and are not a W3D3 merge blocker.

**Approved visible/data scope:** User-created Exercises composed into the canonical Exercises capability plus create/edit form over the already-live W3D2 definition contract: required name, optional description, one of the 11 Exercise Types, Primary muscle, Secondary muscles, Primary equipment, and existing archive lifecycle. The editor interaction must follow the owner-approved TNYX-264 direction: Exercise Type uses a Tio-owned single-select list with its capability-hint tags; Primary muscle is selected in one bottom-sheet accordion: tapping a Body Part expands its relevant muscles inline beneath that row, only one Body Part is expanded at a time, and tapping a muscle completes the single selection without opening a second sheet; Secondary muscles use the complete canonical muscle set as multi-select; Equipment is single-select. Body Part and capability tags are presentation-only and are never persisted. Reuse canonical `Exercise`, `UserCreatedExerciseRef`, `UserExerciseDefinition`, `UserExerciseRepository`, W3D1 controller foundation, and Tio Core UI.

**Explicit non-goals:** no media/Storage; no distance/duration/steps/weight/reps/+KG/-KG/x1/x2 execution semantics; no Favorites/Folders; no Routine/Program/Active Workout changes; no Supabase table/column/RLS/grant change; no broad GitHub #475 Library redesign; no new competing Exercise truth. A separate user-facing Custom Exercises collection is no longer a target. Additional iconography and visual polish are deferred follow-up work and must not silently widen this slice.

## Active Handoff

**Planning/implementation owner:** ChatGPT repository architecture workflow
**Review owner:** Codex after PR creation
**Repository state last verified before this handoff-only update:** `main@c58689a8a7f183a0ca5fb644e4f69d67b2157bbe`
**Branch:** `tnyx/tnyx-264-w3d3-custom-exercise-editor`
**Working-tree visibility:** Connector-only execution; local worktree/toolchain is not available, so no local cleanliness or local Flutter-run claim.
**Tracker:** Linear TNYX-264, In Progress; W3D2 is validated/live.
**Current state:** Functional W3D3 implementation is complete within the approved slice. The canonical `/workout/exercises` screen composes bundled + user-created Exercises; Custom rows carry a presentation-only `Custom` badge, and the Library Custom Exercises entry focuses the same canonical route instead of establishing a second collection. The Primary muscle selector uses the owner-approved single-bottom-sheet inline accordion with the exact approved 44-token Body Part map. Exercise Type, Secondary muscles, Equipment, create/edit/archive and failure reconciliation are implemented with focused coverage. Visual polish/icons are intentionally deferred.
**Last fully reviewed code head:** `beecb0675725f1a5bc4c27f635d216080b41cbde`.
**Verified evidence on that head:** Flutter CI `37271874901` PASS; Commit attribution guard PASS; zero unresolved review threads; Codex exact-head review reported no major issues. GitHub Advanced Security failed before meaningful analysis because the scanning agent exceeded its monthly quota (HTTP 402); this is infrastructure/account quota evidence, not a security pass and not a product-vulnerability finding.
**Supabase verification:** W3D3 introduces no migration/RLS/grant change. Hosted `public.user_workout_exercises` remains the validated 12-column W3D2 contract with owner-scoped SELECT/INSERT/UPDATE policies and least-privilege column grants; no authenticated DELETE is exposed. Security Advisor remains at the pre-existing baseline (five authenticated SECURITY DEFINER warnings plus leaked-password protection disabled), with no W3D3-specific database finding.
**Next exact action:** after this handoff-only commit, refresh base/head scope evidence, run/inspect exact-head hosted Flutter CI and attribution guard, request Codex review on the new head, verify zero unresolved threads and zero drift from `main`, then stop for explicit merge authorization. Do not widen into visual polish/icons, Favorites/Folders/Recent/media/Library redesign.

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

Verified on 2026-10-01 and reconciled again during PR #497 review:
- W3D1 `CustomExercisesController` owns load/create-name/rename/archive and stable-id reconciliation.
- W3D2 `UserExerciseDefinition` and `UserExerciseRepository.updateDefinition` own structured definition validation/persistence.
- App composition exposes nullable `userExerciseRepositoryProvider` backed by Supabase only.
- `exerciseTaxonomyLabel` is the existing presentation label helper.
- `ExerciseType` owns the 11 durable storage identities.
- The canonical Exercises surface remains the single browse/search/filter truth; Custom-focused navigation is a filtered state of that route.
- No W3D3 schema change is required.

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
- [x] Primary muscle UI interaction corrected: one bottom sheet stays open, the tapped Body Part expands inline, the previously expanded Body Part collapses, and selecting one inline muscle completes the choice; no nested/forward sheet. Exact 44-token grouping remains owner-approved and canonical.
- [x] Exercise Type UI implemented: Tio-owned bottom-sheet single-select list with the 11 approved capability hints.
- [x] Secondary muscle UI implemented: full canonical muscle list, multi-select, excluding Primary.
- [x] Equipment UI implemented: bottom-sheet single-select over the approved equipment taxonomy.
- [x] Add minimal route contracts and app composition needed to reach the real W3D capability.
- [x] Add focused controller/widget/router tests.
- [x] Update canonical Exercises/Library docs only for behavior actually delivered.
- [x] Validate code head `beecb0675725f1a5bc4c27f635d216080b41cbde`: Flutter CI PASS, attribution guard PASS, Codex exact-head review clean, zero unresolved threads.
- [ ] Validate the final evidence-only handoff head after this documentation update before merge authorization.

## 5. Validation / Exit

The last functional code head `beecb0675725f1a5bc4c27f635d216080b41cbde` is validated by hosted Flutter CI `37271874901`, the Commit attribution guard, and an exact-head Codex review with no major issues; GitHub had zero unresolved review threads. Earlier implementation defects and review findings were corrected with focused regressions before that head.

The GitHub Advanced Security run on `beecb067...` did not complete meaningful analysis because its scanning model session exceeded the monthly quota and returned HTTP 402. Record that as an external scanner/account-quota failure, not as a security pass and not as product-vulnerability evidence.

Supabase W3D2 remains deployed and hosted-verified: migration `20260930180700_add_custom_exercise_definition_fields` is present and `public.user_workout_exercises` has the expected 12-column owner-scoped contract. W3D3 itself changes no migration, RLS policy, database grant, Storage policy or privileged function.

The final merge gate is evidence-only: refresh parent-to-head audit on the new handoff commit, inspect exact-head hosted checks, obtain/inspect a fresh Codex review, ensure zero unresolved threads and zero drift from `main`, then require explicit owner merge authorization. Visual polish and icons remain a later bounded follow-up.
