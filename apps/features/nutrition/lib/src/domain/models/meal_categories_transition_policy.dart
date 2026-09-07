import 'meal_categories_config.dart';
import 'meal_categories_validation.dart';

/// Validates changes between two persisted Meal Categories configurations.
///
/// Ordinary upsert may change presentation and active state, but it is not a
/// destructive identity-removal operation. Retained IDs remain available for
/// future historical MealLog resolution and ID-collision checks.
abstract final class MealCategoriesTransitionPolicy {
  static void validate({
    required MealCategoriesConfig previous,
    required MealCategoriesConfig next,
  }) {
    previous.validate();
    next.validate();

    final nextIds = next.items.map((item) => item.id).toSet();
    for (final previousItem in previous.items) {
      if (!nextIds.contains(previousItem.id)) {
        throw MealCategoriesValidationException(
          code: MealCategoriesValidationCode.retainedIdentityRemoved,
          message:
              'Retained Meal Category id cannot be removed: ${previousItem.id}.',
        );
      }
    }
  }
}
