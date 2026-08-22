# Product Onboarding O5A — Canonical Nutrition Profile + Targets Contracts

**Status:** Active  
**Tracker:** GitHub Issue #64  
**Parent O5:** #63  
**Parent Product Onboarding:** #40  
**Canonical ownership:** #44  
**Predecessor O4:** #58 ✅ / CI #1441  
**O11 cleanup:** #54 BLOCKED until O10  
**Implementation PR:** #50 Draft/open/unmerged  
**Branch:** `agent/onboarding-slice-2-step-1-body-goal-ui`

## Starting validated checkpoint

```text
d70de933dc0cc01f1c6544d37f625fb01937b309
Flutter CI #1441 / run 32570394147
Flutter analyze ✅
Dart analyze    ✅
Flutter tests   ✅
Dart tests      ✅
```

## Goal

Create backend-neutral Nutrition Profile and Nutrition Targets owner contracts for the already-live canonical Supabase tables before Product Onboarding activates Nutrition-specific runtime sections.

```text
Nutrition Profile domain
        ↓
NutritionProfileRepository
        ↓
public.user_nutrition_profiles
        ↓ context fields only

Nutrition Targets domain
        ↓
NutritionTargetsRepository
        ↓
public.user_nutrition_targets
```

## Live schema evidence

### Profile fields allowed in O5A canonical API

```text
preferred_diet
allergies[]
disliked_foods[]
medical_conditions[]
```

Do not surface legacy Body/Profile/Wellness/target mirrors that still physically exist in `user_nutrition_profiles`.

### Target fields

```text
calories_kcal
protein_grams
carbohydrate_grams
fat_grams
fiber_grams
customization_state
customized_fields[]
recommendation_metadata
```

Live `customization_state` constraint:

```text
unknown | recommended | custom | mixed
```

## Chosen contract direction

### `NutritionProfileData`

Backend-neutral fields:

```text
String? preferredDiet
Set<String> allergies
Set<String> dislikedFoods
Set<String> medicalConditions
```

Do not invent enum option sets in O5A. The live table has no value constraints for these fields and the current Product Onboarding UI has not yet approved/activated a typed option set.

### `NutritionTargetsData`

Backend-neutral fields:

```text
int? caloriesKcal
double? proteinGrams
double? carbohydrateGrams
double? fatGrams
double? fiberGrams
NutritionTargetCustomizationState customizationState
Set<String> customizedFields
Map<String, Object?> recommendationMetadata
```

Null numeric values mean unknown/unset. Metadata must remain an object. The domain should validate live storage constraints without inventing narrower product ranges.

### Repositories

```text
NutritionProfileRepository
  read()
  upsert(profile)

NutritionTargetsRepository
  read()
  upsert(targets)
```

Signed-out reads return null. Signed-out writes throw a clear authenticated-user requirement error without changing auth state.

## Implementation plan

- [ ] add `NutritionProfileData` + validation/equality if useful;
- [ ] add `NutritionTargetCustomizationState` storage mapping;
- [ ] add `NutritionTargetsData` + storage-level validation;
- [ ] add canonical repository interfaces;
- [ ] add in-memory repositories preserving null/value semantics;
- [ ] add testable Supabase table gateways;
- [ ] add `SupabaseNutritionProfileRepository` targeting only Nutrition context columns;
- [ ] add `SupabaseNutritionTargetsRepository` targeting only `user_nutrition_targets`;
- [ ] export new contracts/adapters through the public Nutrition package barrel;
- [ ] add strict parse/write tests including signed-out fail-closed behavior;
- [ ] verify legacy `TargetsSetupRepository` production source is unchanged by O5A;
- [ ] run full Flutter/Dart CI and record one exact source SHA.

## Supabase adapter constraints

Profile write payload may contain only:

```text
user_id
preferred_diet
allergies
disliked_foods
medical_conditions
```

Targets write payload may contain only:

```text
user_id
calories_kcal
protein_grams
carbohydrate_grams
fat_grams
fiber_grams
customization_state
customized_fields
recommendation_metadata
```

No canonical adapter may call `signInAnonymously()`, write `macro_targets`, write `user_targets`, or persist common Profile/Body/Wellness mirrors.

## Out of scope

- no onboarding UI or section activation;
- no `NutritionOnboardingDraft` field design;
- no mode eligibility changes;
- no Product Onboarding persistence cutover;
- no replacement/deletion of `TargetsSetupRepository` yet;
- no migration/schema change;
- no legacy column cleanup;
- no Settings UI work from #46;
- no formula changes to Nutrition recommendations.

## Acceptance

- [ ] Profile contract exposes only Nutrition context fields;
- [ ] Targets contract maps all live canonical Nutrition target fields;
- [ ] nullable/unknown values are preserved;
- [ ] customization state mapping is strict and lossless;
- [ ] in-memory repositories are deterministic;
- [ ] Supabase Profile adapter writes/reads only canonical context fields;
- [ ] Supabase Targets adapter writes/reads only `user_nutrition_targets` fields;
- [ ] signed-out writes fail closed with no auth side effect;
- [ ] malformed canonical rows fail strictly instead of fabricating defaults;
- [ ] no UI/runtime/schema changes;
- [ ] legacy mixed Targets compatibility source remains unchanged;
- [ ] full four-gate CI green on one exact O5A source SHA.

## Exit

O5A closes only when the canonical contracts and both adapters are proven on one exact full-CI-green source checkpoint. O5B then activates the Nutrition Profile runtime/draft boundary.
