# Current State

Last verified from current branch/runtime trackers: 2026-08-22.

This is the concise handoff for the next agent. Runtime source remains behavior truth. For Product Onboarding sequencing, read `.ai/tasks/product-onboarding-canonical-execution.md` first.

## Read order

1. `.ai/CURRENT.md`
2. `.ai/tasks/product-onboarding-canonical-execution.md`
3. `.ai/tasks/product-onboarding-o4-wellness.md`
4. active focused O4 task once created from the audit
5. GitHub Issue #58 and Draft PR #50

## Canonical persistence owners

```text
users                      → account/domain root + contacts/status
user_profiles              → common Profile
user_app_preferences       → App Mode + active_tabs
body_weight_logs           → current/history weight
user_body_goals            → Body Goal + Target Weight + Goal Pace
user_wellness_targets      → steps/water/sleep/bed/wake targets
user_nutrition_profiles    → diet/allergy/food context
user_nutrition_targets     → calories/macros/fiber + target state
user_workout_profiles      → workout context/capability
user_workout_targets       → workout goals/plan constraints
onboarding_drafts          → draft/resume orchestration only
```

Legacy mixed columns remain temporarily. Destructive cleanup is O11/#54 and stays blocked until O10 acceptance.

## Validated Product Onboarding foundation

```text
O1 durable App Mode / active_tabs               ✅ #11 / CI #1240
O2 common User Profile owner + userProfile      ✅ #53 / CI #1279
O3 canonical Body Goal end-to-end               ✅ #55 / CI #1354
```

O3 final exact source checkpoint:

```text
75237e6c31222f4b08f3cdd41353121aa1ca3afc
Flutter CI #1354 / run 32562632629
Flutter analyze ✅
Dart analyze    ✅
Flutter tests   ✅
Dart tests      ✅
```

O3D additionally removed ongoing Body-owned mirror writes from Nutrition persistence while retaining legacy row read compatibility. No schema cleanup was performed.

## Current Product Onboarding sequence

```text
O1 App Mode                                     ✅
O2 User Profile                                 ✅
O3 Body Goal                                    ✅ #55 / CI #1354
→ O4 Wellness                                   ACTIVE #58
→ O5 Nutrition                                  BLOCKED by O4
→ O6 Workout
→ O7 Health Connections
→ O8 Review + resume/edit-back
→ O9 Plan Building/finalization
→ O10 final acceptance
→ O11 Canonical Schema Cleanup                  BLOCKED #54
```

Only one Product Onboarding slice/sub-slice is active at a time.

## O4 target boundary

Canonical durable Wellness owner:

```text
user_wellness_targets
  steps_target
  water_target_ml
  sleep_target_minutes
  bed_time
  wake_up_time
```

Current historical Targets flow still contains Wellness-oriented child screens/values. O4 must audit runtime placement, serialized draft compatibility, repository contracts and persistence before deciding the smallest safe focused cutover sequence.

Nutrition may consume Wellness values as recommendation inputs where necessary; that does not make Nutrition their durable owner.

## Current work — O4 audit

Tracker: #58  
Parent: #40  
Canonical ownership: #44

Before source changes:
- inspect existing `TargetStepId` / `TargetsFlowPlan` Wellness children;
- inspect `TargetsOnboardingDraft` storage/resume shape;
- inspect Wellness-related screens and validators;
- locate any existing `user_wellness_targets` domain/repository adapter;
- inspect `SupabaseTargetsSetupRepository` remaining Wellness writes;
- identify calculation-only dependencies from Nutrition;
- create one focused O4A task/issue from the audit.

## Guardrails

- one canonical durable owner per concept;
- no fabricated Wellness defaults;
- preserve current UI unless semantic wiring only requires movement;
- no applied migration edits;
- no legacy-column drops;
- no permanent dual-write synchronization;
- legacy mirrors may remain read-compatible until O11;
- no O5 source work before O4 integrated acceptance.
