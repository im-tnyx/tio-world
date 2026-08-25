# Body Goal current-weight-first and mode Goal refinement

Status: Complete / Frozen

## Fresh audit

Current Product Onboarding Body Goal order was:

```text
Goal → Current Weight → Target Weight → Goal Pace
```

The unified Goal screen also exposed the same seven-card vocabulary for Workout and Hybrid, including both `Gain weight` and `Build muscle`. That was technically representable in the mixed onboarding intent model, but presented overlapping user-facing concepts in workout-aware modes.

## Accepted product behavior

### Body Goal order

Runtime Body Goal navigation is:

```text
Current Weight → Goal → Target Weight → Goal Pace
```

Target Weight and Goal Pace remain conditional under the existing `GoalWeightFollowUpPolicy`.

### Goal cards by App Mode

Nutrition remains weight-direction focused:

```text
Lose Weight
Gain Weight
Maintain Weight
```

Workout and Hybrid are outcome-focused:

```text
Fat Loss
Build Muscle
Boost Strength
Improve Endurance
Keep Fit
```

`Fat Loss` is a mode-specific presentation label for the existing `GoalIntent.loseWeight` compatibility/persistence intent in this bounded refinement. No new persisted enum, schema owner, migration, or workout-target database value was introduced.

`Gain Weight` and `Maintain Weight` remain valid Nutrition intents and decode-compatible domain values, but are not selectable cards in Workout or Hybrid.

## Ownership / compatibility constraints

- `body_weight_logs` remains the current/history weight owner.
- `user_body_goals` remains Body Goal / Target Weight / Goal Pace owner.
- `user_workout_targets` remains the Workout goals owner.
- No mixed replacement owner or schema migration was introduced.
- `GoalIntent.gainWeight`, `GoalIntent.maintainWeight`, and legacy decode values remain available for compatibility.
- Existing training-only Target Weight behavior remains governed by `GoalWeightFollowUpPolicy` and current-vs-target derivation.
- Existing persisted/draft values remain decodable; mode reconciliation removes values that are no longer selectable in the active mode while retaining visible training intents.

## Implemented

1. Reordered `BodyGoalFlowPlan.orderedSteps` to Current Weight, Goal, Target Weight, Goal Pace.
2. Gave Nutrition, Workout, and Hybrid explicit option lists in `GoalIntentSelectionPolicy`.
3. Hid Gain Weight / Maintain Weight from Workout and Hybrid.
4. Rendered the existing lose-weight intent as `Fat Loss` with workout-aware copy in Workout/Hybrid while retaining `Lose weight` in Nutrition.
5. Kept persistence/data ownership unchanged.
6. Updated focused domain, presentation, router, migration/resume, and controller regressions for the new order and visibility contract.
7. Historical Workout/Hybrid Maintain-plus-training drafts reconcile to the visible training-only intent, preserving target-derived weight direction rather than restoring a hidden card.

## Focused regression expectations

- Nutrition renders exactly Lose Weight / Gain Weight / Maintain Weight.
- Workout and Hybrid render exactly Fat Loss / Build Muscle / Boost Strength / Improve Endurance / Keep Fit.
- Hidden Workout/Hybrid Gain Weight and Maintain Weight taps are ignored by the policy.
- Reconciliation removes no-longer-visible Workout/Hybrid weight intents while preserving visible training intents.
- Full Body Goal plan order begins with Current Weight then Goal.
- Maintain Weight Nutrition plan becomes Current Weight → Goal and omits Target Weight / Goal Pace.
- Removing Target Weight / Goal Pace reconciles backward to Goal under the new order.
- Fresh Profile completion enters Current Weight, then Goal.

## Validation / accepted checkpoint

Accepted runtime/source-test SHA:

```text
011b9265fdbccfb52c215c2e456cc14c032eea44
```

Exact-SHA validation:

```text
Flutter CI #2052 / run 32884195902 ✅
- Flutter analyze ✅
- Dart analyze ✅
- Flutter tests ✅
- Dart tests ✅

Android Native CI #464 / run 32884195871 ✅
- Phone Android debug APK ✅
- Wear Android debug APK ✅
```

## Merge guard

PR #50 remains Draft/open/unmerged. Do not mark Ready, merge, or enable auto-merge without explicit owner authorization.
