import 'package:tio_feature_progress/progress.dart' as body_owner;

import '../models/models.dart';

/// Lossless mapper from the onboarding draft to the canonical Body owner.
///
/// Only explicit Body intents are mapped. Training goals are never translated
/// into Body goals and Body direction is never inferred from numbers/BMI.
class BodySetupMapper {
  const BodySetupMapper();

  body_owner.BodySetupData map(OnboardingDraft draft) {
    final selection = draft.goalSelection;
    final bodyIntents = selection.goals.where(_isBodyIntent).toList();
    if (bodyIntents.length > 1) {
      throw StateError(
        'Unified Goal selection contains multiple Body intents: $bodyIntents',
      );
    }

    final rawCurrentWeight = draft.profile.currentWeightKg;
    final currentWeight = rawCurrentWeight != null && rawCurrentWeight > 0
        ? rawCurrentWeight
        : null;

    if (bodyIntents.isEmpty) {
      return body_owner.BodySetupData(currentWeightKg: currentWeight);
    }

    final intent = bodyIntents.single;
    final goalType = _mapGoalType(intent);
    final rank = selection.primaryGoal == intent ? 1 : 2;

    final requiredDirection = switch (intent) {
      GoalIntent.loseWeight => GoalWeightDirection.loss,
      GoalIntent.gainWeight => GoalWeightDirection.gain,
      _ => null,
    };
    final directional = requiredDirection != null;
    final targetWeight = directional &&
            draft.profile.targetWeightDirection == requiredDirection
        ? draft.profile.targetWeightKg
        : null;
    final pace = directional ? draft.targets.goalPaceKgPerWeek : null;

    return body_owner.BodySetupData(
      currentWeightKg: currentWeight,
      activeGoal: body_owner.BodyGoalSetupData(
        goalType: goalType,
        targetWeightKg: targetWeight,
        weeklyWeightChangeKg: pace,
        intentRank: rank,
      ),
    );
  }

  bool _isBodyIntent(GoalIntent intent) => switch (intent) {
        GoalIntent.loseWeight ||
        GoalIntent.gainWeight ||
        GoalIntent.maintainWeight ||
        GoalIntent.recomposition => true,
        GoalIntent.buildMuscle ||
        GoalIntent.getStronger ||
        GoalIntent.improveEndurance ||
        GoalIntent.stayFit => false,
      };

  body_owner.BodyGoalType _mapGoalType(GoalIntent intent) => switch (intent) {
        GoalIntent.loseWeight => body_owner.BodyGoalType.loseWeight,
        GoalIntent.gainWeight => body_owner.BodyGoalType.gainWeight,
        GoalIntent.maintainWeight => body_owner.BodyGoalType.maintainWeight,
        GoalIntent.recomposition => body_owner.BodyGoalType.recomposition,
        _ => throw StateError('Not a Body Goal intent: $intent'),
      };
}
