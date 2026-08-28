import '../models/models.dart';
import 'goal_pace_resolver.dart';
import 'sleep_schedule_helper.dart';

/// Validates the current target child step for navigation readiness.
///
/// Navigation validity is separate from product readiness:
/// - T1 steps (bridge, stepTarget, sleepTarget, waterTarget) have real validation.
/// - GoalPace validates only after Target Weight has established loss/gain.
/// - NutritionTarget remains calculation-blocked (formula authority unresolved).
///
/// [OnboardingCompletionValidator] separately gates overall completion;
/// this validator only determines whether Continue is enabled within Targets.
class TargetStepValidator {
  const TargetStepValidator();

  static const int minDailySteps = 2000;
  static const int maxDailySteps = 18000;
  static const int minSleepMinutes = SleepScheduleHelper.minDurationMinutes; // 240
  static const int maxSleepMinutes = SleepScheduleHelper.maxDurationMinutes; // 720
  static const int minWaterMl = 1000;
  static const int maxWaterMl = 8000;
  static const double minGoalPace = GoalPaceResolver.minPaceKgPerWeek; // 0.1
  static const double maxGoalPace = GoalPaceResolver.maxPaceKgPerWeek; // 1.5

  /// Returns `null` if valid, or an error string if not.
  String? validateCurrentStep(
    TargetsOnboardingDraft draft, {
    ProfileOnboardingDraft? profile,
    GoalWeightDirection? weightGoalDirection,
  }) {
    return switch (draft.currentStepId) {
      TargetStepId.bridge => null,
      TargetStepId.stepTarget => _validateSteps(draft.dailySteps),
      TargetStepId.sleepTarget => _validateSleep(draft.sleepTargetMinutes),
      TargetStepId.waterTarget => _validateWater(draft.waterMl),
      TargetStepId.goalPace => _validateGoalPace(
          draft.goalPaceKgPerWeek,
          weightGoalDirection,
        ),
      // NutritionTarget: navigation-passable to Review, but formula-blocked for completion
      TargetStepId.nutritionTarget => null,
    };
  }

  bool isCurrentStepValid(
    TargetsOnboardingDraft draft, {
    ProfileOnboardingDraft? profile,
    GoalWeightDirection? weightGoalDirection,
  }) =>
      validateCurrentStep(
        draft,
        profile: profile,
        weightGoalDirection: weightGoalDirection,
      ) ==
      null;

  String? _validateSteps(int steps) {
    if (steps < minDailySteps || steps > maxDailySteps) {
      return 'Choose a step target from $minDailySteps to $maxDailySteps steps/day.';
    }
    return null;
  }

  String? _validateSleep(int minutes) {
    if (minutes < minSleepMinutes || minutes > maxSleepMinutes) {
      return 'Choose a sleep duration from ${minSleepMinutes ~/ 60} '
          'to ${maxSleepMinutes ~/ 60} hours.';
    }
    return null;
  }

  String? _validateWater(int ml) {
    if (ml < minWaterMl || ml > maxWaterMl) {
      return 'Choose a water target from $minWaterMl to $maxWaterMl ml/day.';
    }
    return null;
  }

  String? _validateGoalPace(
    double pace,
    GoalWeightDirection? direction,
  ) {
    if (direction == null) {
      return 'Choose a target weight above or below your current weight before setting goal pace.';
    }

    if (pace < minGoalPace || pace > maxGoalPace) {
      return 'Choose a goal pace from $minGoalPace to $maxGoalPace kg/week.';
    }
    return null;
  }
}
