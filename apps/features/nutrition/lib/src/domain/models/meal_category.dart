import 'meal_categories_validation.dart';
import 'meal_category_display_name_policy.dart';

/// Canonical semantic role of a built-in Meal Category.
///
/// This key supports default/reset/localization behavior. It is not the
/// durable identity stored by a future MealLog.
enum MealCategoryDefaultKey {
  breakfast('breakfast'),
  lunch('lunch'),
  dinner('dinner'),
  snacks('snacks');

  const MealCategoryDefaultKey(this.storageValue);

  final String storageValue;

  static MealCategoryDefaultKey? fromStorageValue(String value) {
    for (final key in values) {
      if (key.storageValue == value) return key;
    }
    return null;
  }
}

/// Stable Meal Category identity and its current user-facing presentation.
///
/// [id] is immutable and intentionally separate from [displayName]. Renaming,
/// reordering, or archiving a category never changes its durable identity.
///
/// [displayName] is canonicalized by [MealCategoryDisplayNamePolicy] here, in
/// the constructor, rather than at each call site. The codec, the controller
/// and any direct caller therefore all get the same stored value and the same
/// refusals: there is no route into this type that skips the name contract.
final class MealCategory {
  MealCategory({
    required String id,
    required this.defaultKey,
    required String displayName,
    required this.active,
    required int order,
  })  : id = _validateId(id),
        displayName = MealCategoryDisplayNamePolicy.canonicalize(displayName),
        order = _validateOrder(order);

  final String id;
  final MealCategoryDefaultKey? defaultKey;
  final String displayName;
  final bool active;
  final int order;

  MealCategory renamed(String value) => MealCategory(
        id: id,
        defaultKey: defaultKey,
        displayName: value,
        active: active,
        order: order,
      );

  MealCategory reordered(int value) => MealCategory(
        id: id,
        defaultKey: defaultKey,
        displayName: displayName,
        active: active,
        order: value,
      );

  MealCategory withActive(bool value) => MealCategory(
        id: id,
        defaultKey: defaultKey,
        displayName: displayName,
        active: value,
        order: order,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MealCategory &&
          id == other.id &&
          defaultKey == other.defaultKey &&
          displayName == other.displayName &&
          active == other.active &&
          order == other.order;

  @override
  int get hashCode => Object.hash(id, defaultKey, displayName, active, order);
}

String _validateId(String value) {
  if (value.isEmpty) {
    throw const MealCategoriesValidationException(
      code: MealCategoriesValidationCode.emptyId,
      message: 'Meal Category id must not be empty.',
    );
  }
  if (value.trim() != value) {
    throw const MealCategoriesValidationException(
      code: MealCategoriesValidationCode.invalidId,
      message: 'Meal Category id must not contain surrounding whitespace.',
    );
  }
  return value;
}

int _validateOrder(int value) {
  if (value < 0) {
    throw const MealCategoriesValidationException(
      code: MealCategoriesValidationCode.negativeOrder,
      message: 'Meal Category order must be non-negative.',
    );
  }
  return value;
}
