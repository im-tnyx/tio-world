# Current State

Last verified from current branch/runtime trackers and canonical owner contracts: 2026-08-22.

Runtime source remains behavior truth. For Product Onboarding sequencing, read `.ai/tasks/product-onboarding-canonical-execution.md` first.

## Read order

1. `.ai/CURRENT.md`
2. `.ai/tasks/product-onboarding-canonical-execution.md`
3. `.ai/tasks/product-onboarding-o5-nutrition.md`
4. `.ai/tasks/product-onboarding-o5d-canonical-nutrition-persistence-cutover.md`
5. GitHub Issues #67/#63/#40/#44 and Draft PR #50
6. `.ai/tasks/product-onboarding-o5c-nutrition-goals-runtime.md` for validated predecessor evidence

## Canonical persistence owners

```text
users                      → account/domain root + contacts/status
user_profiles              → common Profile
user_app_preferences       → App Mode + active_tabs
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
938d35ad605150cf6a062ba9badef70a8677b5a6
Flutter CI #1481 / run 32579778629
Flutter analyze ✅
Dart analyze    ✅
Flutter tests   ✅
Dart tests      ✅
```

This is the frozen O5C runtime/source checkpoint. Later task/tracker-only commits do not replace it.

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
   → O5D canonical persistence cutover           ACTIVE #67
   O5E integrated acceptance
→ O6 Workout
→ O7 Health Connections
→ O8 Review + resume/edit-back
→ O9 Plan Building/finalization
→ O10 final acceptance
→ O11 Canonical Schema Cleanup                   BLOCKED #54
```

Only one Product Onboarding sub-slice is active at a time.

## O5C validated result

Active calculated Nutrition Target ownership is `nutritionGoals` in Workout, Nutrition and Hybrid. Legacy `targets + nutritionTarget` resumes losslessly under the stable section. Existing UI, formula, target values and eligibility are unchanged.

## Current O5D objective

Cut Product Onboarding completion persistence to explicit canonical Nutrition owners:

```text
Nutrition/Hybrid:
Onboarding Nutrition Profile → NutritionProfileRepository → user_nutrition_profiles

Workout/Nutrition/Hybrid:
calculated Nutrition Target → NutritionTargetsRepository → user_nutrition_targets
```

Canonical allergy semantics:

```text
null onboarding answer → canonical allergies = null
explicit None          → canonical allergies = {}
selected restrictions  → canonical storage strings
```

O5D must remove `TargetsSetupRepository.saveTargetsSetup` from Product Onboarding completion ownership. It must not change UI/navigation/formulas/mode eligibility or schema.

Target persistence order:

```text
Profile → Body → Wellness → Nutrition Profile(if active)
→ Workout(if active) → Nutrition Targets → App Mode/preferences → completion
```

## Guardrails

- follow `.ai/tasks/product-onboarding-o5d-canonical-nutrition-persistence-cutover.md`;
- no UI/navigation/formula/eligibility change;
- no migration/schema change or applied migration edit;
- no legacy-column drop;
- no permanent dual write;
- no recreation of Wellness/Body/Profile mirrors in Nutrition owners;
- O5E stays blocked until #67 exact full CI green;
- O11 remains blocked until O10;
- PR #50 remains Draft/open/unmerged.
