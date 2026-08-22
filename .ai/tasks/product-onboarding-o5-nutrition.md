# Product Onboarding O5 — Canonical Nutrition Profile + Targets

**Status:** In progress  
**Tracker:** GitHub Issue #63  
**Parent Product Onboarding:** #40  
**Canonical ownership:** #44  
**Predecessor O4:** #58 ✅ / CI #1441  
**O5A:** #64 ✅ / CI #1449  
**O5B:** #65 ✅ / CI #1460  
**O5C:** #66 ✅ / CI #1481  
**Active slice:** O5D #67  
**O11 cleanup:** #54 BLOCKED until O10  
**Implementation PR:** #50 Draft/open/unmerged  
**Branch:** `agent/onboarding-slice-2-step-1-body-goal-ui`

## Latest validated runtime checkpoint

```text
938d35ad605150cf6a062ba9badef70a8677b5a6
Flutter CI #1481 / run 32579778629
Flutter analyze ✅
Dart analyze    ✅
Flutter tests   ✅
Dart tests      ✅
```

This is the frozen O5C runtime/source checkpoint. Later tracker-only commits do not replace it.

## Canonical owners

```text
public.user_nutrition_profiles → Nutrition context only
public.user_nutrition_targets  → calories/macros/fiber + customization state/metadata
```

Body, common Profile and Wellness remain separate canonical owners.

## Execution order

```text
O5A canonical Nutrition Profile + Targets repository contracts ✅ #64 / CI #1449
O5B nutritionProfile runtime/draft/navigation/resume           ✅ #65 / CI #1460
O5C nutritionGoals runtime + legacy Targets compatibility      ✅ #66 / CI #1481
→ O5D canonical persistence cutover + mixed writer shutdown    ACTIVE #67
→ O5E integrated read/write/resume/failure/customization acceptance
```

Only one O5 sub-slice is active at a time.

## Validated runtime through O5C

```text
Workout:
wellnessGoals → workoutPreferences → nutritionGoals → review

Nutrition:
wellnessGoals → nutritionProfile → nutritionGoals → review

Hybrid:
wellnessGoals → nutritionProfile → workoutIntro
→ optional workoutPreferences → nutritionGoals → review
```

`nutritionProfile` is Nutrition/Hybrid only. `nutritionGoals` stays all-mode. Legacy `targets + nutritionTarget` resumes losslessly to active `nutritionGoals`.

## O5D — ACTIVE #67

Focused task:

```text
.ai/tasks/product-onboarding-o5d-canonical-nutrition-persistence-cutover.md
```

Required completion cutover:

```text
Nutrition Profile draft
→ NutritionProfileRepository
→ user_nutrition_profiles

existing calculated Nutrition recommendation
→ NutritionTargetsRepository
→ user_nutrition_targets
```

Canonical allergy semantics:

```text
unanswered → null
explicit None → empty set
selected restrictions → storage strings
```

Product Onboarding completion must stop calling the legacy mixed `TargetsSetupRepository.saveTargetsSetup` writer. The legacy repository can remain for compatibility consumers until later cleanup.

Fail-closed owner order:

```text
Profile → Body → Wellness → Nutrition Profile(if active)
→ Workout(if active) → Nutrition Targets → App preferences → completion
```

## Guardrails

- no UI/navigation/formula/eligibility change;
- no schema/migration change;
- no applied migration edits;
- no legacy-column drops;
- no permanent dual write;
- no recreation of Body/Wellness/Profile mirrors in Nutrition tables;
- no O5E until #67 exact full CI green;
- O11 remains blocked until O10;
- PR #50 remains Draft/open/unmerged.

## Current work

**Execute O5D #67 only from `.ai/tasks/product-onboarding-o5d-canonical-nutrition-persistence-cutover.md`.**
