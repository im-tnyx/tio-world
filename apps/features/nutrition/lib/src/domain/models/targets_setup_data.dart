import 'nutrition_target_recommendation.dart';

/// Immutable domain model representing user daily targets and nutritional setup data.
class TargetsSetupData {
  const TargetsSetupData({
    required this.dailySteps,
    required this.sleepTargetMinutes,
    required this.sleepTimeMinutes,
    required this.wakeTimeMinutes,
    required this.waterMl,
    required this.goalPaceKgPerWeek,
    this.recommendation,
  });

  final int dailySteps;
  final int sleepTargetMinutes;
  final int sleepTimeMinutes;
  final int wakeTimeMinutes;
  final int waterMl;
  final double goalPaceKgPerWeek;
  final NutritionTargetRecommendation? recommendation;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is TargetsSetupData &&
            runtimeType == other.runtimeType &&
            dailySteps == other.dailySteps &&
            sleepTargetMinutes == other.sleepTargetMinutes &&
            sleepTimeMinutes == other.sleepTimeMinutes &&
            wakeTimeMinutes == other.wakeTimeMinutes &&
            waterMl == other.waterMl &&
            (goalPaceKgPerWeek - other.goalPaceKgPerWeek).abs() < 0.001 &&
            recommendation == other.recommendation;
  }

  @override
  int get hashCode => Object.hash(
        dailySteps,
        sleepTargetMinutes,
        sleepTimeMinutes,
        wakeTimeMinutes,
        waterMl,
        goalPaceKgPerWeek,
        recommendation,
      );

  @override
  String toString() {
    return 'TargetsSetupData(steps: $dailySteps, water: ${waterMl}ml, sleep: ${sleepTargetMinutes}m, calories: ${recommendation?.caloriesKcal})';
  }
}
