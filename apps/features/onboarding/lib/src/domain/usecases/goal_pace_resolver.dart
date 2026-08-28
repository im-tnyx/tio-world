import '../models/goal_pace_mode.dart';
import '../models/goal_pace_warning.dart';
import '../models/goal_weight_direction.dart';
import '../models/profile_onboarding_draft.dart';

/// Pure Dart resolver for Goal Pace mode, warnings, and presentation metadata.
class GoalPaceResolver {
  const GoalPaceResolver._();

  static const double minPaceKgPerWeek = 0.1;
  static const double maxPaceKgPerWeek = 1.5;
  static const double defaultPaceKgPerWeek = 0.5;
  static const double aggressiveWarningThreshold = 1.0;
  static const double maintenanceDeltaThreshold = 0.5;

  /// Runtime onboarding mode comes from the explicit Goal intent direction.
  static GoalPaceMode resolveModeForDirection(GoalWeightDirection? direction) {
    return switch (direction) {
      GoalWeightDirection.loss => GoalPaceMode.loss,
      GoalWeightDirection.gain => GoalPaceMode.gain,
      null => GoalPaceMode.maintenance,
    };
  }

  /// Legacy compatibility helper. New onboarding flow code must use
  /// [resolveModeForDirection] so measurement deltas never decide user intent.
  @Deprecated('Use resolveModeForDirection with explicit Goal intent.')
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

  static String screenTitleForDirection(GoalWeightDirection? direction) {
    return switch (direction) {
      GoalWeightDirection.loss => 'How fast do you want to \nlose weight?',
      GoalWeightDirection.gain => 'How fast do you want to \ngain weight?',
      null => 'How do you want to \nmaintain your weight?',
    };
  }

  static String cardHeaderForDirection(GoalWeightDirection? direction) {
    return switch (direction) {
      GoalWeightDirection.loss => 'Fat Loss',
      GoalWeightDirection.gain => 'Healthy Weight Gain',
      null => 'Maintenance',
    };
  }

  /// Compatibility title helper for legacy callers/tests.
  @Deprecated('Use screenTitleForDirection.')
  static String screenTitle({
    required ProfileGoal? primaryGoal,
    required GoalPaceMode mode,
  }) {
    return switch (mode) {
      GoalPaceMode.loss => screenTitleForDirection(GoalWeightDirection.loss),
      GoalPaceMode.gain => screenTitleForDirection(GoalWeightDirection.gain),
      GoalPaceMode.maintenance => screenTitleForDirection(null),
    };
  }

  /// Compatibility header helper for legacy callers/tests.
  @Deprecated('Use cardHeaderForDirection.')
  static String cardHeader({
    required GoalPaceMode mode,
    required ProfileGoal? primaryGoal,
  }) {
    return switch (mode) {
      GoalPaceMode.loss => cardHeaderForDirection(GoalWeightDirection.loss),
      GoalPaceMode.gain => cardHeaderForDirection(GoalWeightDirection.gain),
      GoalPaceMode.maintenance => cardHeaderForDirection(null),
    };
  }
}
