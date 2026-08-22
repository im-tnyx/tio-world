# Product Onboarding O5 — Canonical Nutrition Profile + Targets

**Status:** In progress — O5D validated; O5E integrated acceptance ACTIVE  
**Tracker:** GitHub Issue #63  
**Parent Product Onboarding:** #40  
**Canonical ownership:** #44  
**Predecessor O4:** #58 ✅ / CI #1441  
**O5A:** #64 ✅ / CI #1449  
**O5B:** #65 ✅ / CI #1460  
**O5C:** #66 ✅ / CI #1481  
**O5D:** #67 ✅ / CI #1505  
**Active slice:** O5E #68  
**O11 cleanup:** #54 BLOCKED until O10  
**Implementation PR:** #50 Draft/open/unmerged  
**Branch:** `agent/onboarding-slice-2-step-1-body-goal-ui`

## Latest validated runtime checkpoint

```text
7af5ab0cb1bc37a84af568763a2214977dd57c0c
Flutter CI #1505 / run 32582725736
Flutter analyze ✅
Dart analyze    ✅
Flutter tests   ✅
Dart tests      ✅
```

This is the frozen O5D runtime/source checkpoint. Later tracker-only commits do not replace it.

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
O5D canonical persistence cutover + mixed writer shutdown      ✅ #67 / CI #1505
→ O5E integrated read/write/resume/failure/customization       ACTIVE #68
```

Only one O5 sub-slice is active at a time.

## Validated runtime through O5D

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

## O5D validated cutover

Product Onboarding completion now writes:

```text
Nutrition Profile draft
→ NutritionProfileRepository
→ user_nutrition_profiles

existing calculated Nutrition recommendation
→ NutritionTargetsRepository
→ user_nutrition_targets
```

The completion use case no longer requires `TargetsSetupRepository`; app router composition passes both canonical Nutrition repositories directly. Legacy mixed repository behavior remains compatibility-only outside Product Onboarding completion.

Canonical allergy semantics remain:

```text
unanswered → null
explicit None → empty set
selected restrictions → storage strings
```

Fail-closed owner order remains:

```text
Profile → Body → Wellness → Nutrition Profile(if active)
→ Workout(if active) → Nutrition Targets → App preferences → completion
```

## O5E — ACTIVE #68

Focused task:

```text
.ai/tasks/product-onboarding-o5e-integrated-nutrition-acceptance.md
```

O5E validates the integrated canonical O5 boundary across Workout, Nutrition and Hybrid:

- canonical Profile/Targets round-trip;
- provenance and customization-state preservation;
- legacy resume compatibility without legacy completion writes;
- failure/retry ordering and idempotence;
- production canonical provider composition;
- exact full four-gate CI acceptance.

## Guardrails

- no UI/navigation/formula/eligibility change;
- no schema/migration change;
- no applied migration edits;
- no legacy-column drops;
- no permanent dual write;
- no recreation of Body/Wellness/Profile mirrors in Nutrition tables;
- O6 remains blocked until O5E exact full CI green;
- O11 remains blocked until O10;
- PR #50 remains Draft/open/unmerged.

## Current work

**Execute O5E #68 only from `.ai/tasks/product-onboarding-o5e-integrated-nutrition-acceptance.md`.**