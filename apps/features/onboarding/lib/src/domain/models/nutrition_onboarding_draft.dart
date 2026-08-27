import 'nutrition_allergy_restriction.dart';
import 'nutrition_diet_type.dart';
import 'nutrition_profile_step_id.dart';

class NutritionOnboardingDraft {
  const NutritionOnboardingDraft({
    this.currentStepId = NutritionProfileStepId.dietType,
    this.dietType,
    this.otherDietType = '',
    this.allergyRestrictions,
    this.otherAllergyRestriction = '',
  });

  final NutritionProfileStepId currentStepId;
  final NutritionDietType? dietType;
  final String otherDietType;

  /// `null` means unanswered. `{NutritionAllergyRestriction.none}` means the
  /// user explicitly selected None. An empty set is invalid/incomplete state.
  final Set<NutritionAllergyRestriction>? allergyRestrictions;
  final String otherAllergyRestriction;

  NutritionOnboardingDraft copyWith({
    NutritionProfileStepId? currentStepId,
    NutritionDietType? dietType,
    bool clearDietType = false,
    String? otherDietType,
    Set<NutritionAllergyRestriction>? allergyRestrictions,
    bool clearAllergyRestrictions = false,
    String? otherAllergyRestriction,
  }) {
    return NutritionOnboardingDraft(
      currentStepId: currentStepId ?? this.currentStepId,
      dietType: clearDietType ? null : dietType ?? this.dietType,
      otherDietType: otherDietType ?? this.otherDietType,
      allergyRestrictions: clearAllergyRestrictions
          ? null
          : allergyRestrictions ?? this.allergyRestrictions,
      otherAllergyRestriction:
          otherAllergyRestriction ?? this.otherAllergyRestriction,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! NutritionOnboardingDraft ||
        currentStepId != other.currentStepId ||
        dietType != other.dietType ||
        otherDietType != other.otherDietType ||
        otherAllergyRestriction != other.otherAllergyRestriction) {
      return false;
    }
    final left = allergyRestrictions;
    final right = other.allergyRestrictions;
    if (left == null || right == null) return left == right;
    return left.length == right.length && left.every(right.contains);
  }

  @override
  int get hashCode => Object.hash(
        currentStepId,
        dietType,
        otherDietType,
        allergyRestrictions == null
            ? null
            : Object.hashAllUnordered(allergyRestrictions!),
        otherAllergyRestriction,
      );
}
