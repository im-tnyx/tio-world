# Product Onboarding Slice 1 — Section and Step Identity Contract

**Status:** In progress
**Primary owner:** `apps/features/onboarding`
**Affected platforms:** Flutter phone app
**GitHub tracker:** #40
**Base:** `main` at `833fc625ea75a2b8f29f6338764ce977680bb897`

## Global UI / Design-System Guardrail

This slice is non-visual, but it touches onboarding presentation dispatch/state contracts. Before any Flutter UI implementation in this task, read and follow root `AGENTS.md`, `apps/features/AGENTS.md`, `apps/core/lib/src/theme/README.md`, and `.ai/tasks/design-system-token-consolidation.md`; inspect reusable `apps/core` UI through `package:tio_core/core.dart` first. No visual redesign is authorized.

## 1. Discovery

### User Outcome

Prepare migration-safe Product Onboarding section/step identities so later slices can split Profile, Body Goal, Wellness, Nutrition, Workout, Health Connections, and Plan Building without breaking existing drafts or changing the current visible onboarding flow.

### Success Criteria

- Future top-level section/step identities exist without deleting legacy identities.
- Persisted top-level step IDs no longer depend on direct enum `.name` parsing at the DTO boundary.
- Existing schema-v2 drafts using current keys still round-trip and resume safely.
- Current Workout/Nutrition/Hybrid visible flow and progress remain unchanged.
- Existing Hybrid `Workout Intro → Later` behavior remains regression-protected.
- No new screen, screen move, visual change, Supabase schema change, owner persistence refactor, Gym/Equipment work, or Congratulations change occurs in this slice.

### Scope

- `OnboardingSectionId` / `OnboardingStepId` future identity foundation.
- Stable top-level step storage codec with legacy compatibility.
- Draft DTO use of the codec for `current_step_id` / `completed_step_ids`.
- Compile-safe progress/renderer handling for future unscheduled identities.
- Focused characterization/regression tests.

### Non-Goals

- Activating `userProfile`, `bodyGoal`, `wellnessGoals`, `nutritionProfile`, `workoutProfile`, `nutritionGoals`, `workoutTargets`, `healthConnections`, or `planBuilding` in the runtime flow.
- Moving Profile Goal/Target Weight.
- Creating or modifying workout environment/equipment UI.
- Changing Review, completion, Plan Building, Congratulations, database tables, repositories, or canonical owner persistence.

## 2. Codebase Exploration

### Verified Evidence

- `main` is `833fc625ea75a2b8f29f6338764ce977680bb897`.
- Current `OnboardingSectionId`: `appMode`, `profile`, `mobile`, `workoutIntro`, `workout`, `nutritionIntro`, `nutrition`, `targets`, `review`.
- Current `OnboardingStepId`: `mode`, `profileBasics`, `mobile`, `workoutIntro`, `workoutPreferences`, `nutritionIntro`, `nutritionPreferences`, `targets`, `review`.
- `OnboardingDraftSnapshotDtoMapper` serializes top-level `current_step_id` and `completed_step_ids` with enum `.name` and decodes by enum-name lookup.
- Current flow planner schedules only legacy runtime identities.
- Progress and renderer use exhaustive enum switches.
- `OnboardingDraftSnapshot.currentSchemaVersion` is `2`; no schema bump is required if stored keys remain backward-compatible.
- No package-local `apps/features/onboarding/AGENTS.md` exists; root + `apps/features/AGENTS.md` apply.

### Existing Pattern to Follow

Keep current flow planner/runtime behavior intact and introduce compatibility at the domain/data boundary before later slices activate new identities.

### Tests or Validation Already Present

- `test/domain/build_onboarding_flow_use_case_test.dart`
- `test/domain/build_onboarding_progress_plan_use_case_test.dart`
- `test/data/onboarding_draft_snapshot_dto_mapper_test.dart`
- `test/domain/onboarding_controller_test.dart`

## 3. Clarification

### Decisions Required or Made

| Decision | Status | Rationale | Owner |
|---|---|---|---|
| Slice 1 implementation can start | Approved | User explicitly approved the audited Slice 1 scope | Product owner |
| Visible onboarding flow stays unchanged | Approved | Identity foundation only | Product + Onboarding |
| Legacy enum identities remain available | Approved | Existing drafts/resume compatibility | Onboarding |
| Future identities are unscheduled in Slice 1 | Approved | Screen restructuring belongs to later slices | Onboarding |
| Schema version remains 2 if payload shape/keys stay compatible | Approved implementation direction | Avoid unnecessary migration | Onboarding data |

## 4. Architecture Design

### Chosen Approach

Add future conceptual enum values while retaining legacy values. Introduce a dedicated `OnboardingStepIdCodec` as the single storage-key boundary for top-level step IDs. Existing legacy IDs encode to exactly their current strings, so schema-v2 payloads remain compatible. Future IDs get explicit stable keys but are not scheduled by the current flow.

Future conceptual identities prepared in this slice:

```text
userProfile
bodyGoal
wellnessGoals
nutritionProfile
workoutProfile
nutritionGoals
workoutTargets
healthConnections
planBuilding
```

Existing `workoutIntro` and `review` remain reusable stable concepts. `mode`, `mobile`, `profileBasics`, `workoutPreferences`, `nutritionIntro`, `nutritionPreferences`, and `targets` remain legacy compatibility identities until their active consumers are migrated in later approved slices.

### Ownership and Data Flow

```text
OnboardingDraft
→ OnboardingDraftSnapshotDtoMapper
→ OnboardingStepIdCodec
→ stable persisted string
```

### Alternative Rejected

- Directly renaming/removing legacy enum values.
- Auto-mapping every old draft to future steps before those future steps are active.
- Bumping schema version solely because future enum values were added.
- Activating future sections in the runtime flow in this slice.

### Failure and Accessibility States

No visible UI or accessibility behavior changes. Future unscheduled identities fail/guard safely if accidentally routed before their implementation slice.

## 5. Implementation Plan

- [ ] Add future section identities while retaining legacy section IDs.
- [ ] Add future top-level step identities while retaining legacy step IDs.
- [ ] Add/export `OnboardingStepIdCodec` with explicit stable storage keys and legacy decode compatibility.
- [ ] Update draft snapshot mapper top-level step serialization/deserialization to use the codec.
- [ ] Keep `OnboardingDraftSnapshot.currentSchemaVersion == 2` unless an actual payload change becomes necessary.
- [ ] Make progress builder/model compile-safe for future unscheduled step IDs without changing current denominator/order.
- [ ] Make section renderer compile-safe for future unscheduled section IDs without creating new screens.
- [ ] Add/extend tests for legacy round-trip, future-key codec round-trip, current mode flow, Hybrid Later, and progress regression.
- [ ] Run focused onboarding tests/analyze where available; record exact outcome.

## 6. Quality Review

### Validation Run

```text
Not run yet.
```

### Review Findings and Resolution

Pending implementation.

## 7. Final Handoff

### Changed Files

Pending.

### Actual Behavior

Expected: no user-visible runtime change.

### Known Limitations

Future identities are intentionally not active until later approved slices provide their child flow/data contracts.

### Final Status

`REVIEW`
