import 'package:tio_feature_progress/progress.dart' as body_owner;

import '../models/models.dart';
import 'goal_weight_follow_up_policy.dart';

/// Lossless mapper from the onboarding draft to the canonical Body owner.
///
/// Explicit Body intents map directly. A training-only path may establish a
/// loss/gain Body direction only through the user's actual Target Weight answer;
/// training labels themselves are never translated into Body goals.
class BodySetupMapper {
  const BodySetupMapper({
    this.followUpPolicy = const GoalWeightFollowUpPolicy(),
  });

  final GoalWeightFollowUpPolicy followUpPolicy;

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
      final derivedDirection = followUpPolicy.effectiveDirectionFor(
        mode: draft.selectedMode,
        selection: selection,
        currentWeightKg: currentWeight,
        targetWeightKg: draft.profile.targetWeightKg,
      );
      if (derivedDirection == null) {
        return body_owner.BodySetupData(currentWeightKg: currentWeight);
      }

      return body_owner.BodySetupData(
        currentWeightKg: currentWeight,
        activeGoal: body_owner.BodyGoalSetupData(
          goalType: derivedDirection == GoalWeightDirection.loss
              ? body_owner.BodyGoalType.loseWeight
              : body_owner.BodyGoalType.gainWeight,
          targetWeightKg: draft.profile.targetWeightKg,
          weeklyWeightChangeKg: draft.targets.goalPaceKgPerWeek,
          // Null explicitly records that Body direction came from Target Weight
          // rather than from a ranked Goal card.
          intentRank: null,
        ),
      );
    }

    final intent = bodyIntents.single;
    final goalType = _mapGoalType(intent);
    final rank = selection.primaryGoal == intent
        ? 1
        : selection.supportingGoal == intent
            ? 2
            : null;

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
