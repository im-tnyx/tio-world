# Product Onboarding O5D — Canonical Nutrition Persistence Cutover

**Status:** Active  
**Tracker:** GitHub Issue #67  
**Parent O5:** #63  
**Predecessor O5C:** #66 ✅ / CI #1481  
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

This exact SHA is the frozen O5C source/runtime baseline. Task/tracker-only commits after it do not replace validation evidence.

## Objective

Replace Product Onboarding completion writes through the legacy mixed `TargetsSetupRepository` with explicit canonical Nutrition owner writes:

```text
NutritionProfileRepository → public.user_nutrition_profiles
NutritionTargetsRepository → public.user_nutrition_targets
```

No UI, navigation, formula, eligibility or schema change belongs in O5D.

## Canonical mapping contract

### Nutrition Profile

Source: `OnboardingDraft.nutrition`.

```text
dietType.storageValue → preferredDiet
allergyRestrictions == null → allergies = null
allergyRestrictions == {none} → allergies = {}
other restrictions → storageValue strings
```

Keep `dislikedFoods` and `medicalConditions` null because O5B did not collect those Nutrition-specific concepts. Do not mirror common Profile health conditions into Nutrition Profile.

Write eligibility:

```text
Workout   ❌ Nutrition Profile
Nutrition ✅ Nutrition Profile
Hybrid    ✅ Nutrition Profile
```

Resolve eligibility from the active `OnboardingFlowPlan` containing `OnboardingStepId.nutritionProfile`, not from ad hoc mode conditionals.

### Nutrition Targets

Reuse the existing `CalculateNutritionTargetRecommendationUseCase` behavior. Successful recommendation maps losslessly to:

```text
caloriesKcal
proteinGrams
carbohydrateGrams
fatGrams
fiberGrams
```

O5D onboarding-generated targets are recommendation-derived:

```text
customizationState = recommended
customizedFields = {}
```

Recommendation metadata must remain conservative. Allowed initial metadata is source/calculation information already proven by existing recommendation output, for example `source: onboarding`, `bmr`, and `tdee`. Do not invent clinical confidence, formula versions, or user customization flags.

If recommendation inputs are insufficient/invalid, do not fabricate canonical numeric targets. Fail closed at the Nutrition Targets owner boundary unless existing completion policy explicitly permits an unknown target row and tests prove that behavior.

Write eligibility:

```text
Workout   ✅ Nutrition Targets
Nutrition ✅ Nutrition Targets
Hybrid    ✅ Nutrition Targets
```

Resolve this from active `OnboardingStepId.nutritionGoals` where practical.

## Persistence order

Target owner sequence:

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

Every owner boundary is fail-closed. A failure prevents all later owner writes and completion publication.

## Implementation slices

1. Add `NutritionProfileMapper` in onboarding domain usecases.
2. Add `NutritionTargetsMapper` in onboarding domain usecases, reusing current recommendation calculation.
3. Update `PersistOnboardingOwnerDataUseCase` constructor/fields/order to canonical Nutrition repositories.
4. Remove Product Onboarding completion dependency on `TargetsSetupRepository` / `TargetsSetupMapper`.
5. Add canonical Nutrition repository providers in app composition.
6. Update router/completion composition to pass canonical owners.
7. Add mapper and persistence-order/failure tests.
8. Add provider composition tests.
9. Run full four-gate CI on one exact source SHA.

## Compatibility boundary

The legacy mixed `TargetsSetupRepository` may remain in the codebase for compatibility reads or non-onboarding consumers during O5D, but Product Onboarding completion must stop calling `saveTargetsSetup`.

Do not delete legacy tables/columns or alter applied migrations. O11 owns physical cleanup after O10.

## Acceptance

- [ ] Nutrition Profile mapper preserves unknown vs explicit None;
- [ ] Nutrition Profile mapper persists only approved Nutrition context;
- [ ] Nutrition Profile write occurs only when `nutritionProfile` is active;
- [ ] Nutrition Targets mapper preserves current recommendation values;
- [ ] recommendation-derived targets use canonical recommended customization state;
- [ ] Product Onboarding completion uses `NutritionProfileRepository` and `NutritionTargetsRepository`;
- [ ] Product Onboarding completion never calls `TargetsSetupRepository.saveTargetsSetup`;
- [ ] Nutrition Profile failure blocks Workout/Targets/mode/completion;
- [ ] Workout failure blocks Nutrition Targets/mode/completion;
- [ ] Nutrition Targets failure blocks mode/completion;
- [ ] signed-out canonical adapters remain fail-closed with no auth mutation;
- [ ] production Supabase composition selects canonical Nutrition repositories;
- [ ] no UI/navigation/formula/eligibility/schema changes;
- [ ] four CI gates green on one exact source SHA.

## Exit

Freeze exact O5D source SHA + CI evidence, close #67 completed, update #63/#40/#44/#50 and durable trackers, then activate O5E integrated acceptance. O11 remains blocked until O10.
