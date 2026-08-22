# Current State

Last verified from current branch/runtime trackers and exact CI evidence: 2026-08-22.

Runtime source remains behavior truth. Product Onboarding sequencing is owned by `.ai/tasks/product-onboarding-canonical-execution.md`.

## Read order

1. `.ai/CURRENT.md`
2. `.ai/tasks/product-onboarding-canonical-execution.md`
3. `.ai/tasks/product-onboarding-o6-workout.md`
4. `.ai/tasks/product-onboarding-o6a-canonical-workout-contracts.md`
5. GitHub Issues #70/#69/#40/#44 and Draft PR #50
6. `.ai/tasks/product-onboarding-o5e-integrated-nutrition-acceptance.md` for the validated predecessor

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
b017f6c31c9c89a6df1ba6b670ea0ea04d635941
Flutter CI #1507 / run 32583620248
Flutter analyze ✅
Dart analyze    ✅
Flutter tests   ✅
Dart tests      ✅
```

This is the frozen O5E source/runtime checkpoint. Later docs/tracker-only commits do not replace it.

## Current sequence

```text
O1 App Mode                                      ✅ #11 / CI #1240
O2 User Profile                                  ✅ #53 / CI #1279
O3 Body Goal                                     ✅ #55 / CI #1354
O4 Wellness                                      ✅ #58 / CI #1441
O5 Nutrition Profile + Targets                   ✅ #63 / CI #1507
   O5A canonical owner contracts                 ✅ #64 / CI #1449
   O5B nutritionProfile runtime/draft/resume     ✅ #65 / CI #1460
   O5C nutritionGoals runtime + legacy resume    ✅ #66 / CI #1481
   O5D canonical persistence cutover             ✅ #67 / CI #1505
   O5E integrated acceptance                     ✅ #68 / CI #1507
→ O6 Workout Profile + Targets                   ACTIVE #69
   → O6A canonical owner contracts               ACTIVE #70
   O6B workoutProfile runtime/draft/resume
   O6C workoutTargets runtime + legacy resume
   O6D canonical persistence cutover
   O6E integrated acceptance
→ O7 Health Connections
→ O8 Review + resume/edit-back
→ O9 Plan Building/finalization
→ O10 final acceptance
→ O11 Canonical Schema Cleanup                   BLOCKED #54
```

Only one Product Onboarding sub-slice is active at a time.

## O5 validated result

O5E freezes the integrated canonical Nutrition contract across Workout, Nutrition, Hybrid setupNow and Hybrid later. Canonical Nutrition Profile provenance, Nutrition Targets recommendation/customization state, legacy `targets + nutritionTarget` resume, fail-closed ordering, retry/idempotence and direct production canonical providers are covered on CI #1507.

Product Onboarding completion remains independent of `TargetsSetupRepository`; that repository is compatibility-only outside completion.

## Current O6A objective

The current broad `WorkoutPreferencesRepository` mixes Profile context with Target planning. O6 splits the already-live owners:

```text
WorkoutProfileRepository → user_workout_profiles
WorkoutTargetsRepository → user_workout_targets
```

Workout Profile initially owns current source/schema context:

```text
workout_location
available_equipment
experience_level
focus_areas
health_concerns
```

Workout Targets owns:

```text
primary/supporting workout goals + original ranks
training_days
preferred_duration_mins
split_program
special_event
special_event_date
```

Training goal values are only `build_muscle`, `get_stronger`, `improve_endurance`, and `stay_fit`. Body-direction goals remain Body-owned. `special_event_date` stays null until a real source exists.

O6A is domain/repository/adapters/tests only. No onboarding runtime, UI, completion cutover or schema change belongs in O6A.

## Guardrails

- follow `.ai/tasks/product-onboarding-o6a-canonical-workout-contracts.md`;
- no UI/navigation/runtime step change in O6A;
- no `PersistOnboardingOwnerDataUseCase` cutover in O6A;
- no migration/schema change or applied migration edit;
- no legacy-column drop;
- no permanent dual write;
- no fabricated workout goals/event dates/defaults;
- Hybrid `Later` remains preserve/skip, never delete/reset;
- O6B stays blocked until O6A exact full CI green;
- O11 remains blocked until O10;
- PR #50 remains Draft/open/unmerged.