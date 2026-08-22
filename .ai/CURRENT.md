# Current State

Last verified from current branch/runtime trackers and exact CI evidence: 2026-08-22.

Runtime source remains behavior truth. Product Onboarding sequencing is owned by `.ai/tasks/product-onboarding-canonical-execution.md`.

## Read order

1. `.ai/CURRENT.md`
2. `.ai/tasks/product-onboarding-canonical-execution.md`
3. `.ai/tasks/product-onboarding-o5-nutrition.md`
4. `.ai/tasks/product-onboarding-o5e-integrated-nutrition-acceptance.md`
5. GitHub Issues #68/#63/#40/#44 and Draft PR #50
6. `.ai/tasks/product-onboarding-o5d-canonical-nutrition-persistence-cutover.md` for the validated predecessor

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
user_workout_targets       → workout goals/plan constraints
onboarding_drafts          → draft/resume orchestration only
```

Legacy mixed columns remain temporarily. Destructive cleanup is O11/#54 and stays blocked until O10 acceptance.

## Latest exact validated Product Onboarding checkpoint

```text
7af5ab0cb1bc37a84af568763a2214977dd57c0c
Flutter CI #1505 / run 32582725736
Flutter analyze ✅
Dart analyze    ✅
Flutter tests   ✅
Dart tests      ✅
```

This is the frozen O5D source/runtime checkpoint. Later docs/tracker-only commits do not replace it.

## Current sequence

```text
O1 App Mode                                      ✅ #11 / CI #1240
O2 User Profile                                  ✅ #53 / CI #1279
O3 Body Goal                                     ✅ #55 / CI #1354
O4 Wellness                                      ✅ #58 / CI #1441
→ O5 Nutrition Profile + Targets                 ACTIVE #63
   O5A canonical owner contracts                 ✅ #64 / CI #1449
   O5B nutritionProfile runtime/draft/resume     ✅ #65 / CI #1460
   O5C nutritionGoals runtime + legacy resume    ✅ #66 / CI #1481
   O5D canonical persistence cutover             ✅ #67 / CI #1505
   → O5E integrated acceptance                   ACTIVE #68
→ O6 Workout
→ O7 Health Connections
→ O8 Review + resume/edit-back
→ O9 Plan Building/finalization
→ O10 final acceptance
→ O11 Canonical Schema Cleanup                   BLOCKED #54
```

Only one Product Onboarding sub-slice is active at a time.

## O5D validated result

Product Onboarding completion now depends directly on canonical Nutrition owners:

```text
Nutrition/Hybrid nutritionProfile
→ NutritionProfileRepository
→ user_nutrition_profiles

Workout/Nutrition/Hybrid nutritionGoals
→ NutritionTargetsRepository
→ user_nutrition_targets
```

`PersistOnboardingOwnerDataUseCase` no longer requires `TargetsSetupRepository`. App router composition passes `nutritionProfileRepositoryProvider` and `nutritionTargetsRepositoryProvider` directly. Legacy `TargetsSetupRepository` remains compatibility-only outside Product Onboarding completion.

Canonical allergy semantics are preserved:

```text
unanswered → null
explicit None → empty set
selected restrictions → stable storage strings
```

Fail-closed owner order remains:

```text
Profile → Body → Wellness → Nutrition Profile(if active)
→ Workout(if active) → Nutrition Targets → App Mode/preferences → completion
```

## Current O5E objective

Validate the integrated O5 contract across Workout, Nutrition and Hybrid:

- canonical Nutrition Profile and Targets read/write round-trip;
- legacy `targets + nutritionTarget` resume compatibility without restoring legacy completion writes;
- failure/retry ordering across Nutrition Profile, Workout and Nutrition Targets;
- exact null vs explicit-empty allergy semantics;
- recommendation/customization state preservation;
- production canonical repository composition;
- one exact full four-gate CI-green acceptance checkpoint.

Focused task: `.ai/tasks/product-onboarding-o5e-integrated-nutrition-acceptance.md` / Issue #68.

## Guardrails

- no UI/navigation/formula/eligibility change in O5E;
- no migration/schema change or applied migration edit;
- no legacy-column drop;
- no permanent dual write;
- no recreation of Wellness/Body/Profile mirrors in Nutrition owners;
- O6 stays blocked until O5E exact full CI green;
- O11 remains blocked until O10;
- PR #50 remains Draft/open/unmerged.