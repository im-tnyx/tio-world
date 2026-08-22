# Product Onboarding O5A — Canonical Nutrition Profile + Targets Contracts

**Status:** Validated  
**Tracker:** GitHub Issue #64 ✅ closed  
**Parent O5:** #63  
**Parent Product Onboarding:** #40  
**Canonical ownership:** #44  
**Predecessor O4:** #58 ✅ / CI #1441  
**Successor:** O5B nutritionProfile runtime/draft/navigation/resume  
**O11 cleanup:** #54 BLOCKED until O10  
**Implementation PR:** #50 Draft/open/unmerged  
**Branch:** `agent/onboarding-slice-2-step-1-body-goal-ui`

## Final validated checkpoint

```text
3b2cc8b896186eb291bf577bcaaadda21b8a1b8e
Flutter CI #1449 / run 32571519752
Flutter analyze ✅
Dart analyze    ✅
Flutter tests   ✅
Dart tests      ✅
```

This exact SHA is the frozen O5A runtime/source checkpoint. Later task/tracker-only commits do not replace it unless runtime source changes and full CI is rerun.

## Validated outcome

Created backend-neutral canonical Nutrition owner contracts for the already-live Supabase tables:

```text
NutritionProfileData
NutritionProfileRepository
InMemoryNutritionProfileRepository
SupabaseNutritionProfileRepository

NutritionTargetsData
NutritionTargetCustomizationState
NutritionTargetsRepository
InMemoryNutritionTargetsRepository
SupabaseNutritionTargetsRepository
```

## Canonical Nutrition Profile contract

Exposes only Nutrition context:

```text
String? preferredDiet
Set<String>? allergies
Set<String>? dislikedFoods
Set<String>? medicalConditions
```

Live-schema null semantics are preserved:

```text
null  → unknown/unset
{}    → explicitly none
```

No common Profile, Body, Wellness, or numeric target legacy mirror is exposed through this canonical API.

## Canonical Nutrition Targets contract

Maps:

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

Strict storage mapping:

```text
unknown | recommended | custom | mixed
```

Null numeric values remain unknown/unset. Storage-level positive/nonnegative constraints are validated without introducing narrower product or clinical ranges.

## Supabase adapter validation

Profile adapter targets only:

```text
public.user_nutrition_profiles
user_id
preferred_diet
allergies
disliked_foods
medical_conditions
```

Targets adapter targets only:

```text
public.user_nutrition_targets
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

Both canonical adapters:

- signed-out read → null;
- signed-out write → fail closed;
- never call `signInAnonymously()`;
- fail strictly on malformed canonical rows;
- do not fallback-write `user_targets`;
- do not write `user_nutrition_profiles.macro_targets` from canonical Targets;
- do not persist common Profile/Body/Wellness mirrors.

## Compatibility boundary preserved

Existing mixed `TargetsSetupData` / `TargetsSetupRepository` / `SupabaseTargetsSetupRepository` remains untouched in O5A. The legacy Supabase writer blob remained:

```text
59a8d237987a4c6de8182659dc696cbac6413c7e
```

Its cutover/shutdown belongs to O5D after runtime ownership is proven.

## Validation history

- source implementation checkpoint: `ea3f79b6b7ce926eb5a588106019974d37f5c41d`;
- CI #1448 found only two `prefer_const_constructors` lint findings in the new test fixture;
- `3b2cc8b896186eb291bf577bcaaadda21b8a1b8e` fixed those two test-only lints;
- CI #1449 is the final full-green O5A checkpoint.

## Guardrails preserved

- no onboarding UI/runtime/flow change;
- no `NutritionOnboardingDraft` field design yet;
- no mode eligibility change;
- no Product Onboarding persistence cutover;
- no migration/schema change;
- no applied migration edit or legacy-column drop;
- no Settings UI work;
- no Nutrition recommendation formula change.

## Exit

**O5A validated. O5B may start from exact source checkpoint `3b2cc8b896186eb291bf577bcaaadda21b8a1b8e` / Flutter CI #1449.**
