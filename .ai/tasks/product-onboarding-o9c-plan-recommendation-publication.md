# Product Onboarding O9C — Plan / Recommendation Publication Semantics

**Status:** Active  
**Tracker:** GitHub Issue #91  
**Parent O9:** #88  
**O9A:** #89 ✅ / CI #1627  
**O9B:** #90 ✅ / CI #1630  
**Parent Product Onboarding:** #40  
**Canonical ownership:** #44  
**Implementation PR:** #50 Draft/open/unmerged

## Starting exact validated checkpoint

```text
e287f5b8d2f1fa0f539cfe98b9f28a36971310e8
Flutter CI #1630 / run 32636442164 / job 97186849452 ✅
Android Native CI #42 / run 32636442150 / job 97186851647 ✅
```

Later O9B bookkeeping commits are docs-only and do not replace this runtime baseline.

## Audit result

Product Onboarding currently publishes recommendation/plan inputs into existing canonical owners only:

- `user_nutrition_targets` = calories/macros/fiber recommendation output + recommendation/customization metadata;
- `user_workout_targets` = goals, schedule and plan constraints, not a generated exercise program;
- `user_workout_profiles` = Workout context/capability;
- `users.plan` = subscription tier, not an onboarding-generated plan.

There is no separate onboarding meal-plan/workout-plan repository or canonical table to write during finalization. Do not create one in O9C.

`NutritionTargetsMapper` recalculates from the current draft at finalization. Successful calculation publishes `recommended` + empty `customizedFields` + `source=onboarding`; insufficient/invalid inputs publish an explicit canonical `unknown` row rather than invented numeric targets.

`dailyStepTarget` is currently forwarded to the Nutrition calculator but is not consumed by the current calculation formula. Therefore historical Wellness compatibility step defaults do not currently alter calories/macros; no source correction is justified without a real failing behavior.

## Acceptance matrix

```text
Workout
  Nutrition Targets ✅
  Nutrition Profile ❌
  Workout Profile ✅
  Workout Targets ✅

Nutrition
  Nutrition Profile ✅
  Nutrition Targets ✅
  Workout Profile/Targets ❌

Hybrid setupNow
  Nutrition Profile + Targets ✅
  Workout Profile + Targets ✅

Hybrid later
  Nutrition Profile + Targets ✅
  Workout Profile/Targets ❌
```

## Acceptance

- [ ] focused test validates all four publication variants;
- [ ] Nutrition recommendation output is `recommended`, has empty customized fields and `source=onboarding` metadata when calculable;
- [ ] Workout Targets retain only goal/schedule/constraint fields;
- [ ] Hybrid `later` preserves dormant Workout draft answers but publishes no active Workout canonical owners;
- [ ] no separate plan repository/table/model is added;
- [ ] no nutrition formula change;
- [ ] existing O9A/O9B tests remain green;
- [ ] all Flutter/Dart gates + Android native build green on exact SHA.

## Guardrails

- one durable owner per concept;
- no generated meal/workout program fabrication;
- no schema or migration edits;
- no O9D routing/draft lifecycle changes;
- no O11 cleanup;
- PR #50 remains Draft/open/unmerged.

## Exit

Freeze O9C exact CI, close #91, then activate O9D successful completion + draft lifecycle + post-onboarding routing.
