# Product Onboarding O5B — Nutrition Profile Runtime + Draft + Resume

**Status:** Validated  
**Tracker:** GitHub Issue #65 ✅  
**Parent O5:** #63  
**Predecessor O5A:** #64 ✅ / CI #1449  
**Successor O5C:** #66 ACTIVE  
**Parent Product Onboarding:** #40  
**Canonical ownership:** #44  
**Implementation PR:** #50 Draft/open/unmerged  
**Branch:** `agent/onboarding-slice-2-step-1-body-goal-ui`

## Final validated source checkpoint

```text
a8d63137794f6c495a276643134f75365ed48eba
Flutter CI #1460 / run 32577510268
Flutter analyze ✅
Dart analyze    ✅
Flutter tests   ✅
Dart tests      ✅
```

This exact source SHA is the O5B runtime checkpoint. Later task/tracker-only commits do not replace it.

## Validated outcome

A real typed `nutritionProfile` Product Onboarding section is active for Nutrition and Hybrid modes and absent in Workout mode.

```text
Nutrition
userProfile
→ bodyGoal
→ wellnessGoals
→ nutritionProfile
   Diet Type
   → Food Allergies & Restrictions
→ targets (legacy Nutrition Target until O5C)
→ review

Hybrid
userProfile
→ bodyGoal
→ wellnessGoals
→ nutritionProfile
→ workoutIntro
→ optional workoutPreferences
→ targets (legacy Nutrition Target until O5C)
→ review

Workout
nutritionProfile absent
```

## Validated contracts

```text
NutritionProfileStepId
  dietType
  allergiesRestrictions

NutritionDietType
  vegetarian
  nonVegetarian
  vegan
  eggitarian
  other

NutritionAllergyRestriction
  none
  lactose
  gluten
  nuts
  seafood
  other

NutritionOnboardingDraft
  currentStepId
  dietType?
  allergyRestrictions? // null = unanswered; {none} = explicit none
```

Rules validated:

- unanswered and explicit `None` remain distinct;
- `None` is exclusive with every other allergy/restriction option;
- selecting a non-None option removes `None`;
- selecting `None` clears other selections;
- dormant Nutrition Profile answers survive mode changes;
- hidden Nutrition Profile values are not required in Workout mode.

## Resume / serialization

Draft snapshot schema v5 carries the typed Nutrition Profile child cursor and answers additively. Legacy payloads with no Nutrition Profile data restore as unanswered rather than receiving fabricated defaults.

## UI result

Existing onboarding selection-card/design-system patterns are reused. O5B did not introduce a visual redesign or a new feature-local visual token contract.

## Validation history

CI #1455 exposed one `use_super_parameters` lint in the new controller wrapper.  
CI #1456 then exposed one stale app navigation test.  
CI #1457 exposed five stale pre-O5B progress/plan expectations and two invalid Nutrition section test seeds.  
The final source checkpoint `a8d63137794f6c495a276643134f75365ed48eba` reconciled those tests without changing production O5B semantics; CI #1460 is full green.

## Non-goals preserved

- no canonical Nutrition Profile persistence wiring;
- no Nutrition Goal runtime ownership move;
- no target recommendation/formula change;
- no Supabase migration/schema change;
- no legacy mixed-writer shutdown;
- no post-onboarding Settings implementation;
- no legacy-column drop.

## Acceptance

- [x] Nutrition + Hybrid activate `nutritionProfile` directly after Wellness;
- [x] Workout excludes it;
- [x] Diet Type uses only approved options;
- [x] Allergies/Restrictions uses only approved options and exclusive None;
- [x] unanswered and explicit None remain distinct;
- [x] typed draft/DTO round-trip is lossless;
- [x] legacy drafts do not receive fabricated Nutrition answers;
- [x] mode changes preserve dormant Nutrition values;
- [x] progress/next/back/completion invalidation is Nutrition Profile-owned;
- [x] legacy Nutrition Target remains under `targets` unchanged;
- [x] existing UI/design-system patterns are preserved;
- [x] no persistence/schema/formula change;
- [x] full four-gate CI is green on one exact O5B source SHA.

## Exit

**O5B is validated and complete. Active successor is O5C #66 from `.ai/tasks/product-onboarding-o5c-nutrition-goals-runtime.md`.**
