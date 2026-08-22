import 'package:tio_shared/shared.dart';

import '../models/goal_intent.dart';

/// Pure mode/compatibility policy for the unified onboarding Goal screen.
///
/// This does not persist canonical owner data. It only defines which onboarding
/// intents can be presented together before later owner-specific mapping.
class GoalIntentSelectionPolicy {
  const GoalIntentSelectionPolicy();

  static const _nutritionOptions = <GoalIntent>[
    GoalIntent.loseWeight,
    GoalIntent.gainWeight,
    GoalIntent.maintainWeight,
    GoalIntent.recomposition,
  ];

  static const _trainingOptions = <GoalIntent>[
    GoalIntent.loseWeight,
    GoalIntent.buildMuscle,
    GoalIntent.getStronger,
    GoalIntent.improveEndurance,
    GoalIntent.stayFit,
    GoalIntent.recomposition,
  ];

  static const _compatibleSupportingGoals = <GoalIntent, Set<GoalIntent>>{
    GoalIntent.loseWeight: {
      GoalIntent.getStronger,
      GoalIntent.improveEndurance,
    },
    GoalIntent.buildMuscle: {
      GoalIntent.getStronger,
      GoalIntent.recomposition,
    },
    GoalIntent.getStronger: {
      GoalIntent.loseWeight,
      GoalIntent.buildMuscle,
      GoalIntent.improveEndurance,
      GoalIntent.recomposition,
    },
    GoalIntent.improveEndurance: {
      GoalIntent.loseWeight,
      GoalIntent.getStronger,
      GoalIntent.stayFit,
    },
    GoalIntent.stayFit: {
      GoalIntent.improveEndurance,
    },
    GoalIntent.recomposition: {
      GoalIntent.buildMuscle,
      GoalIntent.getStronger,
    },
  };

  List<GoalIntent> optionsFor(AppMode mode) => switch (mode) {
        AppMode.nutrition => _nutritionOptions,
        AppMode.workout || AppMode.hybrid => _trainingOptions,
      };

  bool allowsSupportingGoal(AppMode mode) => mode != AppMode.nutrition;

  bool isVisible(AppMode mode, GoalIntent goal) => optionsFor(mode).contains(goal);

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
    return _compatibleSupportingGoals[primaryGoal]?.contains(supportingGoal) ??
        false;
  }

  /// Applies one card tap while preserving the screen's max-two contract.
  ///
  /// - Nutrition always keeps one primary selection.
  /// - Workout/Hybrid add or replace one compatible supporting selection.
  /// - Tapping an incompatible unselected goal starts a new primary selection.
  GoalIntentSelection applyTap({
    required AppMode mode,
    required GoalIntentSelection current,
    required GoalIntent tappedGoal,
  }) {
    if (!isVisible(mode, tappedGoal)) return current;

    if (!allowsSupportingGoal(mode)) {
      return GoalIntentSelection(primaryGoal: tappedGoal);
    }

    final primary = current.primaryGoal;
    final supporting = current.supportingGoal;
    if (primary == null) {
      return GoalIntentSelection(primaryGoal: tappedGoal);
    }

    if (tappedGoal == primary) {
      if (supporting == null) return current;
      return GoalIntentSelection(primaryGoal: supporting);
    }

    if (tappedGoal == supporting) {
      return GoalIntentSelection(primaryGoal: primary);
    }

    if (isCompatiblePair(
      mode: mode,
      primaryGoal: primary,
      supportingGoal: tappedGoal,
    )) {
      return GoalIntentSelection(
        primaryGoal: primary,
        supportingGoal: tappedGoal,
      );
    }

    return GoalIntentSelection(primaryGoal: tappedGoal);
  }

  /// Reconciles an existing selection after an App Mode change or draft restore.
  GoalIntentSelection reconcileForMode({
    required AppMode mode,
    required GoalIntentSelection selection,
  }) {
    final primary = selection.primaryGoal;
    final supporting = selection.supportingGoal;

    if (primary != null && isVisible(mode, primary)) {
      if (!allowsSupportingGoal(mode)) {
        return GoalIntentSelection(primaryGoal: primary);
      }
      if (supporting != null &&
          isCompatiblePair(
            mode: mode,
            primaryGoal: primary,
            supportingGoal: supporting,
          )) {
        return selection;
      }
      return GoalIntentSelection(primaryGoal: primary);
    }

    if (supporting != null && isVisible(mode, supporting)) {
      return GoalIntentSelection(primaryGoal: supporting);
    }

    return const GoalIntentSelection();
  }

  String? validate({
    required AppMode mode,
    required GoalIntentSelection selection,
  }) {
    final primary = selection.primaryGoal;
    if (primary == null) return 'Choose your main goal.';
    if (!isVisible(mode, primary)) return 'Choose a goal available in this mode.';

    final supporting = selection.supportingGoal;
    if (supporting == null) return null;
    if (!isCompatiblePair(
      mode: mode,
      primaryGoal: primary,
      supportingGoal: supporting,
    )) {
      return 'Choose a compatible supporting goal.';
    }
    return null;
  }
}
