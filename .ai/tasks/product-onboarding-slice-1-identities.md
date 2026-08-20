# Product Onboarding Slice 1 — Section and Step Identity Contract

**Status:** In progress
**Primary owner:** `apps/features/onboarding`
**Affected platforms:** Flutter phone app
**GitHub tracker:** #40
**Base:** `main` at `833fc625ea75a2b8f29f6338764ce977680bb897`

## Global UI / Design-System Guardrail

This slice is non-visual, but it touches onboarding presentation dispatch/state contracts. Before any Flutter UI implementation in this task, read and follow root `AGENTS.md`, `apps/features/AGENTS.md`, `apps/core/lib/src/theme/README.md`, and `.ai/tasks/design-system-token-consolidation.md`; inspect reusable `apps/core` UI through `package:tio_core/core.dart` first. No visual redesign is authorized.

Governance read for this slice was completed before source edits. No package-local `apps/features/onboarding/AGENTS.md` exists.

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
- Compile-safe progress/renderer/compatibility handling for future unscheduled identities.
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
- `OnboardingDraftSnapshotDtoMapper` previously serialized top-level `current_step_id` and `completed_step_ids` with enum `.name` and decoded by enum-name lookup.
- Current flow planner schedules only legacy runtime identities.
- Progress, primary section renderer, and compatibility section contain exhaustive enum switches that must account for appended values.
- `OnboardingDraftSnapshot.currentSchemaVersion` is `2`; no schema bump is required because legacy stored keys and payload shape remain unchanged.
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
| Schema version remains 2 | Implemented | Stored schema-v2 top-level keys/payload shape remain compatible | Onboarding data |

## 4. Architecture Design

### Chosen Approach

Add future conceptual enum values while retaining legacy values. Introduce a dedicated `OnboardingStepIdCodec` as the single storage-key boundary for top-level step IDs. Existing legacy IDs encode to exactly their historical strings, so schema-v2 payloads remain compatible. Future IDs get explicit stable keys but are not scheduled by the current flow.

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

No visible UI or accessibility behavior changes. Future unscheduled identities fail loudly through guarded progress/render paths if accidentally activated before their implementation slice.

## 5. Implementation Plan

- [x] Add future section identities while retaining legacy section IDs.
- [x] Add future top-level step identities while retaining legacy step IDs.
- [x] Add/export `OnboardingStepIdCodec` with explicit stable storage keys and legacy decode compatibility.
- [x] Update draft snapshot mapper top-level step serialization/deserialization to use the codec.
- [x] Keep `OnboardingDraftSnapshot.currentSchemaVersion == 2`; no payload-shape migration introduced.
- [x] Make progress builder/model compile-safe for future unscheduled step IDs without changing current denominator/order.
- [x] Make primary section renderer and compatibility section compile-safe for future unscheduled identities without creating screens.
- [x] Add codec tests plus mapper tests for legacy-key preservation, future-key round-trip, unknown-key fallback/ignore behavior.
- [x] Preserve existing exact mode-flow/Hybrid-Later/progress characterization tests unchanged.
- [ ] Run focused onboarding tests/analyze in a Flutter-capable validation environment and record exact outcome.

## 6. Quality Review

### Validation Run

```text
Static/source review completed.
Automated Flutter analyze/tests: NOT RUN in the available execution environment.
Reason: no Dart/Flutter toolchain is available here, and the branch head currently has no surfaced GitHub status checks/workflow run.
```

### Review Findings and Resolution

- Enum expansion initially exposed one additional exhaustive switch in `onboarding_compatibility_section.dart`; it was added to the guarded future-identity handling.
- Repository search found the remaining relevant `OnboardingStepId` control paths either already use non-exhaustive conditionals/default handling or are covered by the updated progress/renderer switches.
- `BuildOnboardingFlowUseCase`, resume checkpoint use case, controller, owner persistence, and `OnboardingState` runtime behavior were intentionally left unchanged because future identities are not active in Slice 1.
- Existing exact flow tests already lock Workout/Nutrition/Hybrid and Hybrid `Later` ordering, so no planner mutation was necessary.

## 7. Final Handoff

### Changed Files

- `.ai/tasks/README.md`
- `.ai/tasks/product-onboarding-slice-1-identities.md`
- `apps/features/onboarding/lib/src/domain/models/onboarding_section_id.dart`
- `apps/features/onboarding/lib/src/domain/models/onboarding_step_id.dart`
- `apps/features/onboarding/lib/src/domain/models/onboarding_step_id_codec.dart`
- `apps/features/onboarding/lib/src/domain/models/models.dart`
- `apps/features/onboarding/lib/src/data/mappers/onboarding_draft_snapshot_dto_mapper.dart`
- `apps/features/onboarding/lib/src/domain/usecases/build_onboarding_progress_plan_use_case.dart`
- `apps/features/onboarding/lib/src/domain/models/onboarding_progress_plan.dart`
- `apps/features/onboarding/lib/src/presentation/renderer/onboarding_section_renderer.dart`
- `apps/features/onboarding/lib/src/presentation/sections/onboarding_compatibility_section.dart`
- `apps/features/onboarding/test/data/onboarding_draft_snapshot_dto_mapper_test.dart`
- `apps/features/onboarding/test/domain/onboarding_step_id_codec_test.dart`

### Actual Behavior

Current user-visible Product Onboarding flow is intentionally unchanged. Legacy top-level draft keys remain unchanged. Future identities are defined but not scheduled.

### Known Limitations

- Automated analyze/tests still require a Flutter-capable validation run before this slice can be marked `Validated` or be considered merge-ready.
- Future identities remain intentionally inactive until later approved slices provide child flow/data contracts.

### Final Status

`REVIEW`
