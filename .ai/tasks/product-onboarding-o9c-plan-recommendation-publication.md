# Product Onboarding O9C — Plan / Recommendation Publication Semantics

**Status:** Completed ✅  
**Tracker:** GitHub Issue #91 ✅  
**Parent O9:** #88  
**O9A:** #89 ✅ / CI #1627  
**O9B:** #90 ✅ / CI #1630  
**Parent Product Onboarding:** #40  
**Canonical ownership:** #44  
**Implementation PR:** #50 Draft/open/unmerged

## Exact validated checkpoint

```text
b5fe3ce741c3ba093e284ae0dbf893ae4e960ca9
Flutter CI #1634 / run 32637390199 / job 97189092932 ✅
Android Native CI #46 / run 32637390197 / job 97189105902 ✅
```

## Frozen result

Product Onboarding publishes recommendation/plan inputs into existing canonical owners only:

- `user_nutrition_targets` = calories/macros/fiber recommendation output + recommendation/customization metadata;
- `user_workout_targets` = goals, schedule and plan constraints, not a generated exercise program;
- `user_workout_profiles` = Workout context/capability;
- `users.plan` = subscription tier, not onboarding-generated plan output.

There is no separate onboarding meal-plan/workout-plan repository or canonical table to write during finalization.

`NutritionTargetsMapper` recalculates from the current draft at finalization. Successful calculation publishes `recommended` + empty `customizedFields` + `source=onboarding`; insufficient/invalid inputs publish explicit canonical `unknown` rather than invented numeric targets.

`dailyStepTarget` is currently forwarded to the Nutrition calculator but is not consumed by the current formula, so historical Wellness compatibility step defaults do not currently alter calories/macros.

## Acceptance matrix — validated

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
  dormant Workout draft answers preserved ✅
```

## Acceptance

- [x] focused test validates all four publication variants;
- [x] Nutrition recommendation output is `recommended`, has empty customized fields and `source=onboarding` metadata when calculable;
- [x] Workout Targets retain only goal/schedule/constraint fields;
- [x] Hybrid `later` preserves dormant Workout draft answers but publishes no active Workout canonical owners;
- [x] no separate plan repository/table/model added;
- [x] no nutrition formula change;
- [x] existing O9A/O9B tests remain green;
- [x] all Flutter/Dart gates + Android native build green on exact SHA.

## Exit

O9C is frozen complete. Continue O9D successful completion + draft lifecycle + post-onboarding routing.
