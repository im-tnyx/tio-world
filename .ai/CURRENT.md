# Current State

Last verified from current branch/runtime trackers and exact CI evidence: 2026-08-22.

Runtime source remains behavior truth. Product Onboarding sequencing is owned by `.ai/tasks/product-onboarding-canonical-execution.md`.

## Read order

1. `.ai/CURRENT.md`
2. `.ai/tasks/product-onboarding-canonical-execution.md`
3. `.ai/tasks/product-onboarding-o6-workout.md`
4. `.ai/tasks/product-onboarding-o6c-workout-targets-runtime.md`
5. GitHub Issues #72/#69/#40/#44 and Draft PR #50
6. `.ai/tasks/product-onboarding-o6b-workout-profile-runtime.md` for validated predecessor evidence

## Canonical persistence owners

```text
users                      → account/domain root + contacts/status
user_profiles              → common Profile
user_app_preferences       → App Mode + active_tabs
user_devices               → device owner
body_weight_logs           → current/history weight
user_body_goals            → Body Goal + Target Weight + Goal Pace
user_wellness_targets      → steps/water/sleep/bed/wake targets
user_nutrition_profiles    → nutrition context only
user_nutrition_targets     → calories/macros/fiber + customization state
user_workout_profiles      → workout context/capability
user_workout_targets       → workout goals/schedule/plan constraints
onboarding_drafts          → draft/resume orchestration only
```

Legacy mixed columns remain temporarily. Destructive cleanup is O11/#54 and stays blocked until O10 acceptance.

## Latest exact validated Product Onboarding checkpoint

```text
48f0d1ff562fee7dda5647476ff706d1886dde11
Flutter CI #1511 / run 32585811984
Flutter analyze ✅
Dart analyze    ✅
Flutter tests   ✅
Dart tests      ✅
```

This is the frozen O6B source/runtime checkpoint. Tracker-only commits after it do not replace exact runtime validation.

## Current sequence

```text
O1 App Mode                                      ✅ #11 / CI #1240
O2 User Profile                                  ✅ #53 / CI #1279
O3 Body Goal                                     ✅ #55 / CI #1354
O4 Wellness                                      ✅ #58 / CI #1441
O5 Nutrition Profile + Targets                   ✅ #63 / CI #1507
→ O6 Workout Profile + Targets                   ACTIVE #69
   O6A canonical owner contracts                 ✅ #70 / CI #1509
   O6B workoutProfile runtime + legacy resume    ✅ #71 / CI #1511
   → O6C workoutTargets runtime + ordered goals  ACTIVE #72
   O6D canonical persistence cutover
   O6E integrated acceptance
→ O7 Health Connections
→ O8 Review + resume/edit-back
→ O9 Plan Building/finalization
→ O10 final acceptance
→ O11 Canonical Schema Cleanup                   BLOCKED #54
```

Only one Product Onboarding sub-slice is active at a time.

## Validated through O6B

O6A established direct canonical Workout Profile/Targets repository contracts. O6B activated canonical top-level `workoutProfile`, migrated historical `workoutPreferences` storage forward, preserved Hybrid `Later` data, and kept the existing child screens/behavior unchanged on CI #1511.

## Current O6C objective

Activate `workoutTargets` as the second canonical Workout runtime section:

```text
workoutProfile
  gymAccess → equipment(home) → experienceLevel → focusAreas → healthConcerns
→ workoutTargets
  trainingDays → workoutDuration → workoutSplit → specialEvent
```

`healthConcerns` moves next to Profile-owned context; the screen itself does not change.

O6C also:

- advances onboarding draft schema to v4 so O6B broad drafts migrate safely;
- maps only training intents from ordered unified Goal selection into Workout Targets while preserving original rank 1/2;
- leaves Body-direction goals Body-owned;
- never fabricates Workout goals, durations, or special-event dates;
- keeps the broad completion writer until O6D.

Focused task: `.ai/tasks/product-onboarding-o6c-workout-targets-runtime.md` / Issue #72.

## Guardrails

- no visual redesign/copy/field/value change;
- only documented owner-driven `healthConcerns` ordering adjustment;
- no canonical Workout completion persistence cutover in O6C;
- no schema/database migration or applied migration edit;
- no legacy-column drop;
- no permanent dual write;
- Hybrid `Later` preserves stored Workout data;
- O6D waits for O6C exact full CI green;
- O11 remains blocked until O10;
- PR #50 remains Draft/open/unmerged.