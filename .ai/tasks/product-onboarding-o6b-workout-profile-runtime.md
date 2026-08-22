# Product Onboarding O6B — workoutProfile Runtime + Legacy Resume

**Status:** Active  
**Tracker:** GitHub Issue #71  
**Parent O6:** #69  
**Predecessor O6A:** #70 ✅ / CI #1509  
**Parent Product Onboarding:** #40  
**Canonical ownership:** #44  
**O11 cleanup:** #54 BLOCKED until O10  
**Implementation PR:** #50 Draft/open/unmerged  
**Branch:** `agent/onboarding-slice-2-step-1-body-goal-ui`

## Starting validated checkpoint

```text
cd764653146d4514fb4e56ef893e92846327ae2e
Flutter CI #1509 / run 32584462360
Flutter analyze ✅
Dart analyze    ✅
Flutter tests   ✅
Dart tests      ✅
```

## Objective

Activate the already-defined canonical top-level identity:

```text
OnboardingStepId.workoutProfile
OnboardingSectionId.workoutProfile
```

in place of the active legacy top-level `workoutPreferences / workout` identity while preserving the current Workout child flow, screens, answers, validation, progress geometry and navigation behavior.

O6B is an identity/runtime/draft/resume migration only. It does not activate `workoutTargets`, map ordered Workout goals, or cut completion persistence to the new canonical Workout repositories.

## Mode / branch contract

```text
Workout
  ... → workoutProfile → nutritionGoals → review

Nutrition
  no workoutProfile

Hybrid setupNow
  ... → nutritionProfile → workoutIntro → workoutProfile → nutritionGoals → review

Hybrid later
  ... → nutritionProfile → workoutIntro → nutritionGoals → review
```

Hybrid `Later` remains a skip-for-this-run decision and must not clear Workout draft/owner data.

## Transitional child-flow contract

Keep `WorkoutFlowPlan` and `WorkoutOnboardingDraft` unchanged in O6B. Preserve the exact current order:

```text
gymAccess
→ equipment (home only)
→ experienceLevel
→ focusAreas
→ trainingDays
→ workoutDuration
→ workoutSplit
→ healthConcerns
→ specialEvent
```

This deliberately leaves future Workout Targets children inside the one Workout child flow for one migration slice. O6C will activate `workoutTargets` and split target-owned runtime semantics. O6B must not reorder screens merely to match future persistence ownership.

## Legacy draft compatibility

Normalize historical durable top-level identity losslessly:

```text
currentStepId = workoutPreferences
→ workoutProfile

completedStepIds contains workoutPreferences
→ workoutProfile
```

Preserve:

- `WorkoutOnboardingDraft.currentStepId`;
- all existing Workout draft answers;
- conditional equipment eligibility;
- current validation behavior.

`OnboardingStepIdCodec` keeps decoding the historical `workoutPreferences` key. New saves naturally encode `workoutProfile`.

## Required runtime updates

1. `BuildOnboardingFlowUseCase` activates `workoutProfile` for Workout and Hybrid setupNow.
2. `OnboardingDraft` normalizes legacy current/completed `workoutPreferences` identity.
3. `BuildOnboardingProgressPlanUseCase` flattens the existing Workout child flow under `workoutProfile`.
4. `OnboardingState` previous-screen logic follows `workoutProfile`.
5. `OnboardingController` next/back/completed invalidation follows `workoutProfile`.
6. `PreserveOnboardingResumeCheckpointUseCase` compares/validates Workout cursors under `workoutProfile`.
7. `OnboardingSectionRenderer` renders the existing Workout UI for `workoutProfile`; no visual changes.
8. `PersistOnboardingOwnerDataUseCase` treats `workoutProfile` as the active Workout branch but still calls the existing broad `WorkoutPreferencesRepository` until O6D.
9. Add focused flow/draft/resume/controller/progress/renderer/persistence tests and update stale identity assertions.
10. Run full four-gate CI on one exact source SHA.

## Guardrails

- no UI redesign or visual token/value change;
- no child Workout screen reorder in O6B;
- no `workoutTargets` top-level activation;
- no ordered Workout-goal mapping;
- no canonical Workout completion repository cutover;
- no schema/migration change or applied migration edit;
- no legacy-column drop;
- no permanent dual write;
- no fabricated answers/defaults;
- preserve Hybrid `Later` data;
- O6C waits for O6B exact full CI green;
- O11 remains blocked until O10;
- PR #50 remains Draft/open/unmerged.

## Acceptance

- [ ] Workout active flow uses `workoutProfile`, never active `workoutPreferences`;
- [ ] Hybrid setupNow uses `workoutIntro → workoutProfile`;
- [ ] Hybrid later excludes `workoutProfile` and preserves Workout draft values;
- [ ] Nutrition excludes `workoutProfile`;
- [ ] legacy current `workoutPreferences` resumes as `workoutProfile` with the same child cursor/data;
- [ ] legacy completed `workoutPreferences` becomes completed `workoutProfile`;
- [ ] current Workout child order/screens/validation are unchanged;
- [ ] progress/back/next/resume checkpoint semantics remain continuous;
- [ ] broad completion writer remains enabled only for flows containing `workoutProfile`;
- [ ] `workoutTargets` remains inactive;
- [ ] no UI/form/schema/persistence-contract change;
- [ ] Flutter analyze + Dart analyze + Flutter tests + Dart tests green on one exact source SHA.

## Exit

Freeze exact O6B source SHA + CI evidence, close #71 completed, update #69/#40/#44/#50 and durable trackers, then activate O6C `workoutTargets` runtime + ordered Workout-goal mapping + legacy resume.