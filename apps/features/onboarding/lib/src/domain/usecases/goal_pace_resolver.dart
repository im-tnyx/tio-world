import '../models/goal_pace_mode.dart';
import '../models/goal_pace_warning.dart';
import '../models/profile_onboarding_draft.dart';

/// Pure Dart resolver for Goal Pace mode, warnings, and presentation metadata.
class GoalPaceResolver {
  const GoalPaceResolver._();

  static const double minPaceKgPerWeek = 0.1;
  static const double maxPaceKgPerWeek = 1.5;
  static const double defaultPaceKgPerWeek = 0.5;
  static const double aggressiveWarningThreshold = 1.0;
  static const double maintenanceDeltaThreshold = 0.5;

  /// Derive the goal pace mode from profile weights and goals.
  static GoalPaceMode resolveMode({
    required double? currentWeightKg,
    required double? targetWeightKg,
  }) {
    if (currentWeightKg == null || targetWeightKg == null) {
      return GoalPaceMode.maintenance;
    }

    final diff = targetWeightKg - currentWeightKg;
    if (diff > maintenanceDeltaThreshold) {
      return GoalPaceMode.gain;
    } else if (diff < -maintenanceDeltaThreshold) {
      return GoalPaceMode.loss;
    } else {
      return GoalPaceMode.maintenance;
    }
  }

  /// Derive reference product warning state from mode and selected pace.
  static GoalPaceWarning resolveWarning({
    required GoalPaceMode mode,
    required double paceKgPerWeek,
  }) {
    if (mode == GoalPaceMode.loss && paceKgPerWeek >= aggressiveWarningThreshold) {
      return GoalPaceWarning.aggressiveLoss;
    }
    if (mode == GoalPaceMode.gain && paceKgPerWeek >= aggressiveWarningThreshold) {
      return GoalPaceWarning.aggressiveGain;
    }
    return GoalPaceWarning.none;
  }

  /// Derive pace classification tag: 'Easy', 'Medium', or 'Aggressive'.
  static String paceTag(double paceKgPerWeek) {
    if (paceKgPerWeek < 0.4) return 'Easy';
    if (paceKgPerWeek <= 0.7) return 'Medium';
    return 'Aggressive';
  }

  /// Title for the Goal Pace screen based on profile goals and resolved mode.
  static String screenTitle({
    required ProfileGoal? primaryGoal,
    required GoalPaceMode mode,
  }) {
    return switch (mode) {
      GoalPaceMode.loss => 'How fast do you want to \nlose weight?',
      GoalPaceMode.gain => 'How fast do you want to \nbuild muscle?',
      GoalPaceMode.maintenance => 'How do you want to \nmaintain your weight?',
    };
  }

  /// Header description label inside the card.
  static String cardHeader({
    required GoalPaceMode mode,
    required ProfileGoal? primaryGoal,
  }) {
    return switch (mode) {
      GoalPaceMode.loss => 'Fat Loss',
      GoalPaceMode.gain => 'Muscle & Weight Gain',
      GoalPaceMode.maintenance => 'Maintenance',
    };
  }
}
