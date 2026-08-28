# Product Onboarding O5C — Nutrition Goals Runtime + Legacy Targets Compatibility

**Status:** Validated  
**Tracker:** GitHub Issue #66  
**Parent O5:** #63  
**Predecessor O5B:** #65 ✅ / CI #1460  
**Parent Product Onboarding:** #40  
**Canonical ownership:** #44  
**O11 cleanup:** #54 BLOCKED until O10  
**Implementation PR:** #50 Draft/open/unmerged  
**Branch:** `agent/onboarding-slice-2-step-1-body-goal-ui`

## Exact validated O5C checkpoint

```text
938d35ad605150cf6a062ba9badef70a8677b5a6
Flutter CI #1481 / run 32579778629
Flutter analyze ✅
Dart analyze    ✅
Flutter tests   ✅
Dart tests      ✅
```

This SHA is the frozen O5C runtime/source checkpoint. Later task/tracker-only commits do not replace it.

## Validated outcome

The existing calculated Nutrition Target now has stable active Product Onboarding ownership:

```text
OnboardingStepId.nutritionGoals
OnboardingSectionId.nutritionGoals
```

Mode placement:

```text
Workout:
userProfile → bodyGoal → wellnessGoals → workoutPreferences → nutritionGoals → review

Nutrition:
userProfile → bodyGoal → wellnessGoals → nutritionProfile → nutritionGoals → review

Hybrid later:
userProfile → bodyGoal → wellnessGoals → nutritionProfile → workoutIntro → nutritionGoals → review

Hybrid setup now:
userProfile → bodyGoal → wellnessGoals → nutritionProfile → workoutIntro
→ workoutPreferences → nutritionGoals → review
```

Workout, Nutrition and Hybrid all retain the existing Nutrition Target experience. O5C changed ownership identity only; UI, formulas, eligibility and target values were preserved.

## Legacy compatibility

Legacy active cursor:

```text
targets + TargetStepId.nutritionTarget
        ↓ normalize/resume
nutritionGoals + existing Nutrition Target value
```

Legacy Goal Pace and Wellness target cursors continue to normalize to Body Goal and Wellness respectively. Generic/older target checkpoints remain meaning-preserving rather than being blindly reinterpreted.

`TargetsOnboardingDraft` / `TargetStepId.nutritionTarget` remain compatibility/value storage. Active top-level flow plans no longer use `OnboardingStepId.targets` for Nutrition Target ownership.

## Acceptance

- [x] mode eligibility explicitly resolved from checked-in evidence;
- [x] Workout, Nutrition and Hybrid active plans contain `nutritionGoals` at the existing Nutrition Target position;
- [x] active runtime no longer uses top-level `targets` for Nutrition Target ownership;
- [x] existing Nutrition Target screen and calculation behavior unchanged;
- [x] legacy `targets + nutritionTarget` resumes under `nutritionGoals` without value loss;
- [x] next/back/progress/completion invalidation are section-aware;
- [x] later valid checkpoints remain later;
- [x] serialization compatibility explicit and tested;
- [x] no canonical persistence/schema/formula/mixed-writer or eligibility change;
- [x] all four CI gates green on one exact source SHA.

## Handoff

O5C is complete. O5D owns canonical Nutrition Profile/Targets persistence cutover and shutdown of the legacy mixed `TargetsSetupRepository` completion writer. No legacy-column drops occur in O5D; physical cleanup remains O11 after O10.
