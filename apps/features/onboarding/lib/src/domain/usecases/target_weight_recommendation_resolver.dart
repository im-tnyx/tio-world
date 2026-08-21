import '../models/goal_weight_direction.dart';

/// Produces a deterministic starting Target Weight for eligible weight goals.
///
/// The recommendation is a starting point only. User-selected values remain
/// authoritative after they are stored in the onboarding draft.
class TargetWeightRecommendationResolver {
  const TargetWeightRecommendationResolver();

  static const double _defaultDirectionalChange = 0.05;
  static const double _minimumBmi = 18.5;
  static const double _maximumBmiForGainRecommendation = 30.0;
  static const double _minimumWeightKg = 30.0;
  static const double _maximumWeightKg = 200.0;

  double? resolve({
    required GoalWeightDirection? direction,
    required double? currentWeightKg,
    required double? heightCm,
  }) {
    if (direction == null || currentWeightKg == null || currentWeightKg <= 0) {
      return null;
    }

    var target = switch (direction) {
      GoalWeightDirection.loss =>
        currentWeightKg * (1.0 - _defaultDirectionalChange),
      GoalWeightDirection.gain =>
        currentWeightKg * (1.0 + _defaultDirectionalChange),
    };

    if (heightCm != null && heightCm > 0) {
      final heightM = heightCm / 100.0;
      final heightSquared = heightM * heightM;
      final minimumWeightForBmi = _minimumBmi * heightSquared;
      final maximumWeightForGain =
          _maximumBmiForGainRecommendation * heightSquared;

      switch (direction) {
        case GoalWeightDirection.loss:
          // Only apply the lower-BMI guardrail when it still preserves a
          // downward target. Goal direction is never reversed by the guardrail.
          if (minimumWeightForBmi < currentWeightKg &&
              target < minimumWeightForBmi) {
            target = minimumWeightForBmi;
          }
          break;
        case GoalWeightDirection.gain:
          // Likewise, only cap an upward recommendation when the cap remains
          // above the current weight.
          if (maximumWeightForGain > currentWeightKg &&
              target > maximumWeightForGain) {
            target = maximumWeightForGain;
          }
          break;
      }
    }

    target = target.clamp(_minimumWeightKg, _maximumWeightKg);
    return (target * 10).round() / 10.0;
  }
}
