import 'package:tio_shared/shared.dart';

import '../models/goal_intent.dart';

/// Pure mode/selection policy for the unified onboarding Goal screen.
///
/// Presentation stays one flat Tio card list. This policy keeps Body weight
/// state and Workout training priorities independently selectable before later
/// owner-specific mapping.
class GoalIntentSelectionPolicy {
  const GoalIntentSelectionPolicy();

  static const _nutritionOptions = <GoalIntent>[
    GoalIntent.loseWeight,
    GoalIntent.gainWeight,
    GoalIntent.maintainWeight,
  ];

  static const _workoutOptions = <GoalIntent>[
    GoalIntent.loseWeight,
    GoalIntent.gainWeight,
    GoalIntent.maintainWeight,
    GoalIntent.buildMuscle,
    GoalIntent.getStronger,
    GoalIntent.improveEndurance,
    GoalIntent.stayFit,
  ];

  static const _weightStateGoals = <GoalIntent>{
    GoalIntent.loseWeight,
    GoalIntent.gainWeight,
    GoalIntent.maintainWeight,
  };

  static const _trainingGoals = <GoalIntent>{
    GoalIntent.buildMuscle,
    GoalIntent.getStronger,
    GoalIntent.improveEndurance,
    GoalIntent.stayFit,
  };

  List<GoalIntent> optionsFor(AppMode mode) => switch (mode) {
        AppMode.nutrition => _nutritionOptions,
        AppMode.workout || AppMode.hybrid => _workoutOptions,
      };

  bool allowsSupportingGoal(AppMode mode) => mode != AppMode.nutrition;

  bool isVisible(AppMode mode, GoalIntent goal) => optionsFor(mode).contains(goal);

  bool isWeightStateGoal(GoalIntent goal) => _weightStateGoals.contains(goal);

  bool isTrainingGoal(GoalIntent goal) => _trainingGoals.contains(goal);

  bool isCompatiblePair({
    required AppMode mode,
    required GoalIntent primaryGoal,
    required GoalIntent supportingGoal,
  }) {
    if (!allowsSupportingGoal(mode) || primaryGoal == supportingGoal) {
      return false;
    }
    if (!isVisible(mode, primaryGoal) || !isVisible(mode, supportingGoal)) {
      return false;
    }
    if (isWeightStateGoal(primaryGoal) && isWeightStateGoal(supportingGoal)) {
      return false;
    }
    return true;
  }

  /// Applies one card tap while preserving one Body weight-state choice and at
  /// most two Workout training priorities.
  ///
  /// The normalized slot order is Body first (when selected), followed by the
  /// training selections. This makes owner mapping deterministic while the UI
  /// remains a single flat card list.
  GoalIntentSelection applyTap({
    required AppMode mode,
    required GoalIntentSelection current,
    required GoalIntent tappedGoal,
  }) {
    if (!isVisible(mode, tappedGoal)) return current;

    if (mode == AppMode.nutrition) {
      return GoalIntentSelection(primaryGoal: tappedGoal);
    }

    var bodyGoal = _bodyGoalOf(current);
    final trainingGoals = _trainingGoalsOf(current).toList();

    if (isWeightStateGoal(tappedGoal)) {
      bodyGoal = bodyGoal == tappedGoal ? null : tappedGoal;
    } else if (isTrainingGoal(tappedGoal)) {
      final existingIndex = trainingGoals.indexOf(tappedGoal);
      if (existingIndex >= 0) {
        trainingGoals.removeAt(existingIndex);
      } else if (trainingGoals.length < 2) {
        trainingGoals.add(tappedGoal);
      } else {
        // Preserve the first training priority and replace only supporting.
        trainingGoals[1] = tappedGoal;
      }
    }

    return _compose(bodyGoal: bodyGoal, trainingGoals: trainingGoals);
  }

  /// Reconciles an existing selection after an App Mode change or draft restore.
  /// Legacy Recomposition remains decode-compatible but is intentionally not
  /// fabricated into a new Body/training combination.
  GoalIntentSelection reconcileForMode({
    required AppMode mode,
    required GoalIntentSelection selection,
  }) {
    final visibleGoals = selection.goals.where((goal) => isVisible(mode, goal));

    if (mode == AppMode.nutrition) {
      for (final goal in visibleGoals) {
        if (isWeightStateGoal(goal)) {
          return GoalIntentSelection(primaryGoal: goal);
        }
      }
      return const GoalIntentSelection();
    }

    GoalIntent? bodyGoal;
    final trainingGoals = <GoalIntent>[];
    for (final goal in visibleGoals) {
      if (bodyGoal == null && isWeightStateGoal(goal)) {
        bodyGoal = goal;
      } else if (isTrainingGoal(goal) && trainingGoals.length < 2) {
        trainingGoals.add(goal);
      }
    }
    return _compose(bodyGoal: bodyGoal, trainingGoals: trainingGoals);
  }

  String? validate({
    required AppMode mode,
    required GoalIntentSelection selection,
  }) {
    final goals = selection.goals.toList();
    if (goals.isEmpty) return 'Choose at least one goal.';
    if (goals.any((goal) => !isVisible(mode, goal))) {
      return 'Choose goals available in this mode.';
    }

    final bodyCount = goals.where(isWeightStateGoal).length;
    final trainingCount = goals.where(isTrainingGoal).length;

    if (mode == AppMode.nutrition) {
      if (bodyCount != 1 || trainingCount != 0 || goals.length != 1) {
        return 'Choose one weight goal.';
      }
      return null;
    }

    if (bodyCount > 1) return 'Choose only one weight goal.';
    if (trainingCount > 2) return 'Choose up to two training goals.';
    if (bodyCount + trainingCount != goals.length) {
      return 'Choose goals available in this mode.';
    }
    return null;
  }

  GoalIntent? _bodyGoalOf(GoalIntentSelection selection) {
    for (final goal in selection.goals) {
      if (isWeightStateGoal(goal)) return goal;
    }
    return null;
  }

  Iterable<GoalIntent> _trainingGoalsOf(GoalIntentSelection selection) sync* {
    for (final goal in selection.goals) {
      if (isTrainingGoal(goal)) yield goal;
    }
  }

  GoalIntentSelection _compose({
    required GoalIntent? bodyGoal,
    required List<GoalIntent> trainingGoals,
  }) {
    final normalizedTraining = trainingGoals.take(2).toList();
    final ordered = <GoalIntent>[
      if (bodyGoal != null) bodyGoal,
      ...normalizedTraining,
    ];
    return GoalIntentSelection(
      primaryGoal: ordered.isNotEmpty ? ordered[0] : null,
      supportingGoal: ordered.length > 1 ? ordered[1] : null,
      tertiaryGoal: ordered.length > 2 ? ordered[2] : null,
    );
  }
}
