import 'package:flutter_test/flutter_test.dart';
import 'package:tio_feature_nutrition/nutrition.dart';
import 'package:tio_feature_onboarding/onboarding.dart';

/// Settings must never import Onboarding presentation, so the Nutrition
/// feature owns its own editable vocabulary. That duplication is only safe
/// while both sides agree on the exact canonical storage values -- otherwise
/// a Settings edit would silently write a token Onboarding cannot read back.
///
/// This test lives in `apps/app` because it is the only package that depends
/// on both features.
void main() {
  test('Diet Type storage values match the Onboarding enum exactly', () {
    final settingsValues = NutritionProfileVocabulary.dietTypes
        .map((choice) => choice.storageValue)
        .toList();
    final onboardingValues =
        NutritionDietType.values.map((type) => type.storageValue).toList();

    expect(settingsValues, onboardingValues);
    for (final value in settingsValues) {
      expect(
        NutritionDietType.tryFromStorage(value),
        isNotNull,
        reason: value,
      );
    }
  });

  test('every editable Diet Type value round-trips to a label', () {
    for (final choice in NutritionProfileVocabulary.dietTypes) {
      expect(
        NutritionProfileVocabulary.dietTypeLabel(choice.storageValue),
        choice.label,
      );
    }
  });

  test('an unknown stored Diet Type resolves to null, not a guess', () {
    expect(NutritionProfileVocabulary.dietTypeLabel(null), isNull);
    expect(NutritionProfileVocabulary.dietTypeLabel('carnivore'), isNull);
  });

  test('allergy storage values match Onboarding, excluding the none token', () {
    final settingsValues = NutritionProfileVocabulary.allergies
        .map((choice) => choice.storageValue)
        .toList();
    final onboardingValues = NutritionAllergyRestriction.values
        .where((value) => value != NutritionAllergyRestriction.none)
        .map((value) => value.storageValue)
        .toList();

    expect(settingsValues, onboardingValues);
    // "None" is an explicitly empty set in canonical storage. Offering it as
    // an editable token would let Settings persist a value the canonical
    // contract forbids.
    expect(settingsValues, isNot(contains('none')));
  });

  test('allergy labels drop unknown stored tokens instead of echoing them', () {
    expect(
      NutritionProfileVocabulary.allergyLabels({'lactose', 'shellfishy'}),
      ['Lactose'],
    );
    expect(NutritionProfileVocabulary.allergyLabels(<String>{}), isEmpty);
  });
}
