import 'package:tio_feature_nutrition/nutrition.dart' as nutrition_owner;

import '../models/models.dart';

/// Pure mapper from Product Onboarding Nutrition Profile answers to the
/// canonical Nutrition Profile owner contract.
class NutritionProfileMapper {
  const NutritionProfileMapper();

  nutrition_owner.NutritionProfileData map(NutritionOnboardingDraft draft) {
    final restrictions = draft.allergyRestrictions;
    final Set<String>? allergies;

    if (restrictions == null) {
      allergies = null;
    } else if (restrictions.isEmpty) {
      throw ArgumentError.value(
        restrictions,
        'allergyRestrictions',
        'An answered allergy selection cannot be empty.',
      );
    } else if (restrictions.contains(NutritionAllergyRestriction.none)) {
      if (restrictions.length != 1) {
        throw ArgumentError.value(
          restrictions,
          'allergyRestrictions',
          'None must be exclusive.',
        );
      }
      allergies = const <String>{};
    } else {
      allergies = Set.unmodifiable(
        restrictions.map((restriction) => restriction.storageValue),
      );
    }

    return nutrition_owner.NutritionProfileData(
      preferredDiet: draft.dietType?.storageValue,
      allergies: allergies,
      // O5B did not collect these Nutrition-specific concepts. Keep them
      // unknown rather than mirroring common Profile answers or fabricating
      // defaults.
      dislikedFoods: null,
      medicalConditions: null,
    );
  }
}
