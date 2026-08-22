# Product Onboarding O5 — Canonical Nutrition Profile + Targets

**Status:** In progress  
**Tracker:** GitHub Issue #63  
**Parent Product Onboarding:** #40  
**Canonical ownership:** #44  
**Predecessor O4:** #58 ✅ / CI #1441  
**O5A:** #64 ✅ / CI #1449  
**Active slice:** O5B #65  
**Post-onboarding Settings consumer:** #46 planning-only  
**O11 cleanup:** #54 BLOCKED until O10  
**Implementation PR:** #50 Draft/open/unmerged  
**Branch:** `agent/onboarding-slice-2-step-1-body-goal-ui`

## Latest validated runtime checkpoint

```text
3b2cc8b896186eb291bf577bcaaadda21b8a1b8e
Flutter CI #1449 / run 32571519752
Flutter analyze ✅
Dart analyze    ✅
Flutter tests   ✅
Dart tests      ✅
```

This is the exact O5A source baseline. Later task/tracker-only commits do not replace it.

## Canonical owners

```text
public.user_nutrition_profiles → Nutrition context only
public.user_nutrition_targets  → calories/macros/fiber + customization state/metadata
```

Body, common Profile and Wellness remain separate canonical owners.

## O5A — VALIDATED #64

Canonical backend-neutral contracts now exist:

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

Canonical Profile preserves nullable arrays so unknown/unset remains distinct from explicitly none. Canonical adapters fail closed when signed out and never mutate auth state.

The legacy mixed `TargetsSetupRepository` remains untouched until O5D.

## Execution order

```text
O5A canonical Nutrition Profile + Targets repository contracts ✅ #64 / CI #1449
→ O5B nutritionProfile runtime/draft/navigation/resume           ACTIVE #65
→ O5C nutritionGoals runtime ownership + legacy Targets compatibility
→ O5D canonical persistence cutover + mixed writer shutdown
→ O5E integrated read/write/resume/failure/customization acceptance
```

Only one O5 sub-slice is active at a time.

## O5B — ACTIVE #65

Focused task:

```text
.ai/tasks/product-onboarding-o5b-nutrition-profile-runtime.md
```

### Mode eligibility

Approved architecture and #46 product scope align on:

```text
Workout   ❌ nutritionProfile
Nutrition ✅ nutritionProfile
Hybrid    ✅ nutritionProfile
```

Dormant answers survive mode changes. O5B does not alter legacy all-mode Nutrition Target behavior; O5C owns that question.

### First-run fields

Activate only concepts that have both product-defined options and unambiguous canonical ownership:

```text
Diet Type
  Vegetarian
  Non-Vegetarian
  Vegan
  Eggitarian
  Other

Food Allergies & Restrictions
  None
  Lactose
  Gluten
  Nuts
  Seafood
  Other
```

`None` is exclusive. Unanswered remains distinct from explicit None.

Deferred in O5B:

- Diet Style / Preference: no separate live canonical field;
- disliked foods: first-run capture not approved;
- Nutrition-specific medical conditions: avoid duplicating common Health Conditions;
- free-text `Other`: no dedicated canonical field approved.

### Runtime placement

```text
Nutrition:
userProfile → bodyGoal → wellnessGoals → nutritionProfile → targets → review

Hybrid:
userProfile → bodyGoal → wellnessGoals → nutritionProfile
→ workoutIntro → optional workoutPreferences → targets → review

Workout:
unchanged
```

## Guardrails

- follow design-system/UI governance before presentation work;
- reuse existing selection patterns, no visual redesign;
- no canonical persistence wiring in O5B;
- no Nutrition Goal runtime move until O5C;
- no migrations/schema changes;
- no legacy mixed writer changes;
- no additional first-run fields beyond the approved O5B scope;
- no O5C until #65 exact full CI green;
- O11 remains blocked until O10;
- PR #50 remains Draft/open/unmerged.

## Current work

**Execute O5B #65 only from `.ai/tasks/product-onboarding-o5b-nutrition-profile-runtime.md`.**
