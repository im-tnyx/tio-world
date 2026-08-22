# Product Onboarding O5B — Nutrition Profile Runtime + Draft + Resume

**Status:** Active  
**Tracker:** GitHub Issue #65  
**Parent O5:** #63  
**Predecessor O5A:** #64 ✅ / CI #1449  
**Parent Product Onboarding:** #40  
**Canonical ownership:** #44  
**Product option evidence:** #46  
**O11 cleanup:** #54 BLOCKED until O10  
**Implementation PR:** #50 Draft/open/unmerged  
**Branch:** `agent/onboarding-slice-2-step-1-body-goal-ui`

## Starting validated checkpoint

```text
3b2cc8b896186eb291bf577bcaaadda21b8a1b8e
Flutter CI #1449 / run 32571519752
Flutter analyze ✅
Dart analyze    ✅
Flutter tests   ✅
Dart tests      ✅
```

This exact SHA is the frozen O5A runtime/source baseline. Later task/tracker-only commits do not replace it.

## Outcome

Activate a real typed `nutritionProfile` Product Onboarding section for Nutrition and Hybrid modes without changing canonical persistence yet.

```text
Nutrition / Hybrid
wellnessGoals
  ↓
nutritionProfile
  Diet Type
  → Food Allergies & Restrictions
  ↓
later eligible section

Workout
wellnessGoals
  ↓
current Workout path
```

O5B owns draft/runtime/navigation/resume only. O5D owns canonical persistence wiring.

## Mode eligibility

Historical approved onboarding architecture requires users to see only relevant feature branches, and #46 uses the same Nutrition visibility:

```text
Workout   ❌
Nutrition ✅
Hybrid    ✅
```

Dormant Nutrition Profile draft answers survive mode changes but are neither rendered nor required in Workout mode.

O5B does not change the current legacy all-mode Nutrition Target under `targets`; O5C owns that migration.

## Approved first-run fields

Use only option sets already documented in #46 and concepts that map unambiguously to the canonical Profile owner.

### Diet Type

```text
Vegetarian      → vegetarian
Non-Vegetarian  → non_vegetarian
Vegan           → vegan
Eggitarian      → eggitarian
Other           → other
```

### Food Allergies & Restrictions

```text
None      → none
Lactose   → lactose
Gluten    → gluten
Nuts      → nuts
Seafood   → seafood
Other     → other
```

Selection rules:

- unanswered is distinct from explicit `None`;
- `None` is exclusive with every other option;
- selecting any non-None option removes `None`;
- selecting `None` clears all other selected options.

## Deferred fields

Do not collect in O5B:

- Diet Style / Preference because no separate unambiguous live canonical field exists;
- disliked foods because first-run capture interaction is not approved;
- Nutrition-specific medical conditions because common Profile already owns Health Conditions;
- free-text detail for `Other` because no dedicated canonical field is approved.

## Typed draft contracts

Target pure-Dart contracts:

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
  allergyRestrictions? // null unanswered; {none} explicit none
```

Keep these onboarding/product-option enums local to onboarding. O5D maps them to O5A's backend-neutral string-based `NutritionProfileData`.

## Serialization/resume

Extend the existing `nutrition` draft DTO additively. Do not bump schema version unless current compatibility code proves it necessary.

Stable serialized values should not depend on display labels. Use explicit storage/codecs where needed.

Required resume behavior:

- current `nutritionProfile` child restores exactly;
- legacy drafts with no Nutrition Profile fields remain unanswered, not defaulted;
- later top-level checkpoints remain later when dormant Nutrition values exist;
- changing mode away from Nutrition/Hybrid preserves dormant answers;
- changing back restores answers and reconciles a valid current child.

## Runtime placement

Insert top-level `nutritionProfile` immediately after `wellnessGoals` for Nutrition + Hybrid.

Nutrition mode:

```text
userProfile
→ bodyGoal
→ wellnessGoals
→ nutritionProfile
→ targets (legacy Nutrition Target until O5C)
→ review
```

Hybrid mode:

```text
userProfile
→ bodyGoal
→ wellnessGoals
→ nutritionProfile
→ workoutIntro
→ workoutPreferences when selected
→ targets (legacy Nutrition Target until O5C)
→ review
```

Workout mode remains unchanged.

## UI governance

Before production presentation changes, read/follow:

```text
.ai/tasks/design-system-token-consolidation.md
apps/core/lib/src/theme/README.md
apps/features/AGENTS.md
```

Reuse existing onboarding selection-card/header/progress/button patterns through public `tio_core` contracts. O5B is pixel-pattern preserving, not a redesign.

## Implementation plan

- [ ] read UI governance and inspect reusable current selection screens;
- [ ] add typed Nutrition Profile step/option contracts;
- [ ] expand `NutritionOnboardingDraft` with unknown-safe values;
- [ ] add `NutritionProfileFlowPlan`;
- [ ] extend DTO serialization and focused codec tests;
- [ ] activate `nutritionProfile` in Nutrition + Hybrid flow plans after Wellness;
- [ ] add section progress ownership and current-child reconciliation;
- [ ] add Diet Type screen using existing single-select pattern;
- [ ] add Allergies & Restrictions screen using existing multi-select pattern;
- [ ] implement exclusive-None selection policy in pure domain/controller logic;
- [ ] add controller update/next/back/validation/invalidation behavior;
- [ ] preserve dormant values across mode changes;
- [ ] verify legacy `targets` Nutrition Target remains unchanged;
- [ ] add flow/controller/renderer/resume/widget tests;
- [ ] run full Flutter/Dart CI and freeze one exact source SHA.

## Non-goals

- no canonical Nutrition Profile persistence wiring;
- no Nutrition Goal/Target runtime migration;
- no changes to recommendation formulas;
- no Supabase migration/schema change;
- no legacy mixed writer changes;
- no Settings implementation from #46;
- no additional diet/profile fields beyond the two approved first-run concepts;
- no visual redesign.

## Acceptance

- [ ] Nutrition + Hybrid plans activate `nutritionProfile` directly after Wellness;
- [ ] Workout plan excludes it;
- [ ] Diet Type supports only approved options;
- [ ] Allergies/Restrictions supports only approved options and exclusive None;
- [ ] unanswered and explicit None remain distinct;
- [ ] typed draft/DTO round-trip is lossless;
- [ ] no defaults are fabricated for legacy drafts;
- [ ] mode changes preserve dormant Nutrition values;
- [ ] progress/next/back/completion invalidation is Nutrition Profile-owned;
- [ ] legacy Nutrition Target remains under `targets` unchanged;
- [ ] existing UI pattern/design-system contracts are reused;
- [ ] no persistence/schema/formula change;
- [ ] full four-gate CI green on one exact O5B source SHA.

## Exit

O5B closes only after runtime/draft/navigation/resume behavior is validated on one exact full-CI-green source checkpoint. O5C then moves Nutrition Target runtime ownership to `nutritionGoals`.
