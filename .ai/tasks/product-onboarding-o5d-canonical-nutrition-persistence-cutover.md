# Product Onboarding O5D — Canonical Nutrition Persistence Cutover

**Status:** Completed / validated  
**Tracker:** GitHub Issue #67 ✅  
**Parent O5:** #63  
**Predecessor O5C:** #66 ✅ / CI #1481  
**Successor O5E:** #68 ACTIVE  
**Parent Product Onboarding:** #40  
**Canonical ownership:** #44  
**O11 cleanup:** #54 BLOCKED until O10  
**Implementation PR:** #50 Draft/open/unmerged  
**Branch:** `agent/onboarding-slice-2-step-1-body-goal-ui`

## Starting validated checkpoint

```text
938d35ad605150cf6a062ba9badef70a8677b5a6
Flutter CI #1481 / run 32579778629
Flutter analyze ✅
Dart analyze    ✅
Flutter tests   ✅
Dart tests      ✅
```

## O5D validated checkpoint

```text
7af5ab0cb1bc37a84af568763a2214977dd57c0c
Flutter CI #1505 / run 32582725736
Flutter analyze ✅
Dart analyze    ✅
Flutter tests   ✅
Dart tests      ✅
```

This exact SHA freezes the O5D runtime/source result. Later docs/tracker-only commits do not replace it.

## Validated result

Product Onboarding completion persistence is now direct and canonical:

```text
NutritionProfileRepository → public.user_nutrition_profiles
NutritionTargetsRepository → public.user_nutrition_targets
```

`PersistOnboardingOwnerDataUseCase` no longer requires `TargetsSetupRepository`, no longer resolves canonical repositories through a legacy compatibility bundle, and writes directly through the two canonical Nutrition repository contracts.

Production router composition now injects:

```text
nutritionProfileRepositoryProvider
nutritionTargetsRepositoryProvider
```

Legacy `TargetsSetupRepository` remains available only for compatibility consumers outside Product Onboarding completion. O5D does not delete legacy schema or applied migrations.

## Canonical mapping contract

### Nutrition Profile

```text
dietType.storageValue → preferredDiet
allergyRestrictions == null → allergies = null
allergyRestrictions == {none} → allergies = {}
other restrictions → storageValue strings
```

`dislikedFoods` and `medicalConditions` stay null because current Product Onboarding does not collect those Nutrition-specific concepts. Common Profile health conditions are not mirrored into Nutrition Profile.

Eligibility:

```text
Workout   ❌ Nutrition Profile
Nutrition ✅ Nutrition Profile
Hybrid    ✅ Nutrition Profile
```

### Nutrition Targets

The existing `CalculateNutritionTargetRecommendationUseCase` behavior remains the calculation authority. Canonical persistence stores recommendation outputs only:

```text
caloriesKcal
proteinGrams
carbohydrateGrams
fatGrams
fiberGrams
customizationState = recommended
customizedFields = {}
recommendationMetadata
```

Eligibility:

```text
Workout   ✅ Nutrition Targets
Nutrition ✅ Nutrition Targets
Hybrid    ✅ Nutrition Targets
```

## Validated persistence order

```text
Profile
→ Body
→ Wellness
→ Nutrition Profile (if active)
→ Workout (if active)
→ Nutrition Targets
→ confirmed App Mode / active_tabs
→ completion publication
```

Every owner boundary remains fail-closed.

## Acceptance

- [x] Nutrition Profile mapper preserves unknown vs explicit None;
- [x] Nutrition Profile mapper persists only approved Nutrition context;
- [x] Nutrition Profile write occurs only when `nutritionProfile` is active;
- [x] Nutrition Targets mapper preserves current recommendation values;
- [x] recommendation-derived targets use canonical recommended customization state;
- [x] Product Onboarding completion uses `NutritionProfileRepository` and `NutritionTargetsRepository`;
- [x] Product Onboarding completion never calls `TargetsSetupRepository.saveTargetsSetup`;
- [x] Nutrition Profile failure blocks Workout/Targets/mode/completion;
- [x] Workout failure blocks Nutrition Targets/mode/completion;
- [x] Nutrition Targets failure blocks mode/completion;
- [x] signed-out canonical adapters remain fail-closed with no auth mutation;
- [x] production Supabase composition selects canonical Nutrition repositories;
- [x] no UI/navigation/formula/eligibility/schema changes;
- [x] four CI gates green on one exact source SHA.

## Exit

O5D is frozen at `7af5ab0cb1bc37a84af568763a2214977dd57c0c` / Flutter CI #1505. Issue #67 is completed. O5E #68 now owns integrated read/write/resume/failure/customization acceptance. O11 remains blocked until O10.