# Body Goal current-weight-first and mode Goal refinement

Status: Active

## Fresh audit

Current Product Onboarding Body Goal order is:

```text
Goal → Current Weight → Target Weight → Goal Pace
```

The unified Goal screen also exposes the same seven-card vocabulary for Workout and Hybrid, including both `Gain weight` and `Build muscle`. That is technically representable in the current mixed onboarding intent model, but it presents overlapping user-facing concepts in workout-aware modes.

## Accepted product behavior

### Body Goal order

Runtime Body Goal navigation must be:

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

Workout and Hybrid become outcome-focused:

```text
Fat Loss
Build Muscle
Boost Strength
Improve Endurance
Keep Fit
```

`Fat Loss` is a mode-specific presentation label for the existing `GoalIntent.loseWeight` compatibility/persistence intent in this bounded refinement. Do not introduce a new persisted enum, schema owner, migration, or workout-target database value in this slice.

`Gain Weight` and `Maintain Weight` remain valid Nutrition intents and decode-compatible domain values, but are not selectable cards in Workout or Hybrid.

## Ownership / compatibility constraints

- `body_weight_logs` remains the current/history weight owner.
- `user_body_goals` remains Body Goal / Target Weight / Goal Pace owner.
- `user_workout_targets` remains the Workout goals owner.
- Do not create a mixed replacement owner or schema migration.
- Do not delete `GoalIntent.gainWeight`, `GoalIntent.maintainWeight`, or legacy decode values.
- Existing training-only Target Weight behavior remains governed by `GoalWeightFollowUpPolicy` and current-vs-target derivation.
- Existing persisted/draft values must remain decodable; mode reconciliation may remove values that are no longer selectable in the active mode.

## Smallest implementation

1. Reorder `BodyGoalFlowPlan.orderedSteps` to Current Weight, Goal, Target Weight, Goal Pace.
2. Give Nutrition, Workout, and Hybrid explicit option lists in `GoalIntentSelectionPolicy`.
3. Hide Gain Weight / Maintain Weight from Workout and Hybrid.
4. Render the existing lose-weight intent as `Fat Loss` with workout-aware copy in Workout/Hybrid while retaining `Lose weight` in Nutrition.
5. Keep persistence/data ownership unchanged.
6. Update focused domain/presentation regressions, including navigation reconciliation affected by the new order.

## Focused regression expectations

- Nutrition still renders exactly Lose Weight / Gain Weight / Maintain Weight.
- Workout and Hybrid render exactly Fat Loss / Build Muscle / Boost Strength / Improve Endurance / Keep Fit.
- Hidden Workout/Hybrid Gain Weight and Maintain Weight taps are ignored by the policy.
- Reconciliation removes no-longer-visible Workout/Hybrid weight intents while preserving visible training intents.
- Full Body Goal plan order begins with Current Weight then Goal.
- Maintain Weight Nutrition plan becomes Current Weight → Goal and omits Target Weight / Goal Pace.
- Removing Target Weight / Goal Pace reconciles backward to Goal under the new order.

## Validation

Run focused onboarding domain/presentation tests, then full Flutter/Dart analysis/tests and Android exact-SHA validation per repository workflow.

## Merge guard

PR #50 stays Draft/open/unmerged. Do not mark Ready, merge, or enable auto-merge without explicit owner authorization.
