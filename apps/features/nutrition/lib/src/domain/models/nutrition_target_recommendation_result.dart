import 'nutrition_target_recommendation.dart';

sealed class NutritionTargetRecommendationResult {
  const NutritionTargetRecommendationResult();

  bool get isReady => this is NutritionTargetRecommendationSuccess;
  NutritionTargetRecommendation? get recommendationOrNull => switch (this) {
        NutritionTargetRecommendationSuccess(:final recommendation) =>
          recommendation,
        _ => null,
      };
}

class NutritionTargetRecommendationSuccess
    extends NutritionTargetRecommendationResult {
  const NutritionTargetRecommendationSuccess(this.recommendation);

  final NutritionTargetRecommendation recommendation;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NutritionTargetRecommendationSuccess &&
          other.recommendation == recommendation;

  @override
  int get hashCode => recommendation.hashCode;
}

class NutritionTargetRecommendationInsufficientInput
    extends NutritionTargetRecommendationResult {
  const NutritionTargetRecommendationInsufficientInput({
    required this.missingFields,
  });

  final Set<String> missingFields;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NutritionTargetRecommendationInsufficientInput &&
          other.missingFields.length == missingFields.length &&
          other.missingFields.containsAll(missingFields);

  @override
  int get hashCode => Object.hashAllUnordered(missingFields);
}

class NutritionTargetRecommendationInvalidInput
    extends NutritionTargetRecommendationResult {
  const NutritionTargetRecommendationInvalidInput({required this.message});

  final String message;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NutritionTargetRecommendationInvalidInput &&
          other.message == message;

  @override
  int get hashCode => message.hashCode;
}
