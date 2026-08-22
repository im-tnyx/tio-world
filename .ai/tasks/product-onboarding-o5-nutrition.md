# Product Onboarding O5 — Canonical Nutrition Profile + Targets

**Status:** In progress  
**Tracker:** GitHub Issue #63  
**Parent Product Onboarding:** #40  
**Canonical ownership:** #44  
**Predecessor O4:** #58 ✅ / CI #1441  
**Active slice:** O5A #64  
**Post-onboarding Settings consumer:** #46 planning-only  
**O11 cleanup:** #54 BLOCKED until O10  
**Implementation PR:** #50 Draft/open/unmerged  
**Branch:** `agent/onboarding-slice-2-step-1-body-goal-ui`

## Starting validated runtime checkpoint

```text
d70de933dc0cc01f1c6544d37f625fb01937b309
Flutter CI #1441 / run 32570394147
Flutter analyze ✅
Dart analyze    ✅
Flutter tests   ✅
Dart tests      ✅
```

This SHA is the exact O4 final runtime baseline. Documentation/tracker commits after it do not replace the runtime validation checkpoint.

## Canonical owner target

```text
public.user_nutrition_profiles
  → Nutrition context/profile only

public.user_nutrition_targets
  → calories/macros/fiber + customization state/metadata
```

Body, common Profile and Wellness remain separate canonical owners.

## Verified live schema

### `user_nutrition_profiles`

Canonical O5 Profile API may expose only:

```text
preferred_diet
allergies[]
disliked_foods[]
medical_conditions[]
```

Transitional legacy/mixed fields remain physically present but are not canonical Nutrition Profile API:

```text
height_cm
current_weight_kg
target_weight_kg
weekly_weight_change_kg
bed_time
wake_up_time
activity_level
steps_target
water_target_ml
sleep_target_minutes
macro_targets
```

### `user_nutrition_targets`

Already live:

```text
calories_kcal
protein_grams
carbohydrate_grams
fat_grams
fiber_grams
customization_state
customized_fields[]
recommendation_metadata jsonb
```

`customization_state` values are constrained by the live database to:

```text
unknown
recommended
custom
mixed
```

RLS is enabled on both owner tables.

## Verified current app state

- `NutritionOnboardingDraft` is empty.
- stable future IDs `nutritionProfile` and `nutritionGoals` already exist but are not active in the runtime flow;
- a dormant `nutritionPreferences` compatibility renderer explicitly states real Nutrition owner contracts are missing;
- current active `targets` contains the Nutrition Target screen;
- current Nutrition domain exposes only mixed `TargetsSetupData` / `TargetsSetupRepository`;
- `SupabaseTargetsSetupRepository` still writes numeric targets into `user_nutrition_profiles.macro_targets`, carries legacy Profile values, can fall back to `user_targets`, and attempts anonymous auth when signed out.

## Execution order

```text
O5A canonical Nutrition Profile + Targets repository contracts ACTIVE #64
→ O5B nutritionProfile runtime/draft/navigation/resume
→ O5C nutritionGoals runtime ownership + legacy Targets compatibility
→ O5D canonical persistence cutover + mixed writer shutdown
→ O5E integrated read/write/resume/failure/customization acceptance
```

Only one O5 sub-slice is active at a time.

## Mode eligibility boundary

O5A does not alter runtime flow. Current Product Onboarding includes legacy Nutrition Target in all selected-mode flows, while Settings #46 is Nutrition/Hybrid only. O5B/O5C must resolve Product Onboarding eligibility explicitly from approved product behavior before changing mode-specific flow.

## Guardrails

- preserve current UI/runtime during O5A;
- no applied migration edits or schema changes in O5A;
- no legacy-column drops;
- no permanent dual-write synchronization;
- no fabricated diet/allergy/target defaults;
- canonical owner writes fail closed when signed out;
- no repository-owned anonymous authentication;
- BMR/TDEE are recommendation context/metadata, not editable Nutrition targets;
- PR #50 remains Draft/open/unmerged;
- O11 remains blocked until O10.

## Current work

**Execute O5A #64 only from `.ai/tasks/product-onboarding-o5a-canonical-nutrition-contracts.md`.**
