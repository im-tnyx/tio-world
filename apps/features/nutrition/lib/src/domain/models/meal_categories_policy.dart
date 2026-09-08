import 'meal_categories_validation.dart';
import 'meal_category.dart';
import 'meal_category_defaults.dart';

/// Canonical validation owner for Meal Category configuration.
abstract final class MealCategoriesPolicy {
  static const int currentSchemaVersion = 1;
  static const int maxActiveMealCategories = 8;

  /// A configuration with nothing active is not a valid state to be in: every
  /// meal has to be filed under something, so the last active category cannot
  /// be archived away.
  static const int minActiveMealCategories = 1;

  /// A ceiling on retained identities, archived ones included.
  ///
  /// Archiving never deletes — that is what keeps a historical meal's category
  /// resolvable — so the retained set only ever grows. Unbounded, a client
  /// talking to the API directly could grow one row without limit, and the
  /// whole configuration is read, validated and rewritten on every single
  /// edit, so every later write would pay for it.
  ///
  /// Eight active plus twenty-four archived. Reaching it by hand means having
  /// created twenty-four custom categories; the way past it is to restore an
  /// archived one and rename it, reusing an identity rather than minting
  /// another.
  static const int maxRetainedMealCategories = 32;

  static final RegExp _whitespace = RegExp(r'\s+');
  static final RegExp _customIdPattern = RegExp(
    r'^meal_slot_[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
  );

  static bool isValidCustomId(String id) => _customIdPattern.hasMatch(id);

  static void validate({
    required int schemaVersion,
    required Iterable<MealCategory> items,
  }) {
    if (schemaVersion != currentSchemaVersion) {
      throw MealCategoriesValidationException(
        code: MealCategoriesValidationCode.unsupportedSchemaVersion,
        message: 'Unsupported Meal Categories schema version: $schemaVersion.',
      );
    }

    final ids = <String>{};
    final orders = <int>{};
    final activeNames = <String>{};
    final defaultKeys = <MealCategoryDefaultKey>{};
    var activeCount = 0;

    for (final item in items) {
      if (!ids.add(item.id)) {
        throw MealCategoriesValidationException(
          code: MealCategoriesValidationCode.duplicateId,
          message: 'Duplicate Meal Category id: ${item.id}.',
        );
      }
      if (!orders.add(item.order)) {
        throw MealCategoriesValidationException(
          code: MealCategoriesValidationCode.duplicateOrder,
          message: 'Duplicate Meal Category order: ${item.order}.',
        );
      }

      final defaultKey = item.defaultKey;
      if (defaultKey != null) {
        if (!defaultKeys.add(defaultKey)) {
          throw MealCategoriesValidationException(
            code: MealCategoriesValidationCode.duplicateDefaultKey,
            message:
                'Duplicate canonical defaultKey: ${defaultKey.storageValue}.',
          );
        }
        final definition = canonicalMealCategoryDefaultDefinitions
            .firstWhere((candidate) => candidate.key == defaultKey);
        if (definition.id != item.id) {
          throw MealCategoriesValidationException(
            code: MealCategoriesValidationCode.invalidDefaultMapping,
            message:
                '${defaultKey.storageValue} must retain id ${definition.id}.',
          );
        }
      } else if (!isValidCustomId(item.id)) {
        throw const MealCategoriesValidationException(
          code: MealCategoriesValidationCode.invalidId,
          message: 'Custom Meal Category id must use a lowercase UUID v4.',
        );
      }

      if (item.active) {
        activeCount++;
        final normalizedName =
            item.displayName.replaceAll(_whitespace, ' ').trim().toLowerCase();
        if (!activeNames.add(normalizedName)) {
          throw MealCategoriesValidationException(
            code: MealCategoriesValidationCode.duplicateActiveDisplayName,
            message:
                'Duplicate active Meal Category displayName: ${item.displayName}.',
          );
        }
      }
    }

    // Counted across everything retained, archived included: the archived set
    // is the half that grows without a natural bound.
    if (ids.length > maxRetainedMealCategories) {
      throw const MealCategoriesValidationException(
        code: MealCategoriesValidationCode.tooManyRetainedCategories,
        message:
            'At most $maxRetainedMealCategories Meal Categories may be kept.',
      );
    }

    if (activeCount > maxActiveMealCategories) {
      throw const MealCategoriesValidationException(
        code: MealCategoriesValidationCode.tooManyActiveCategories,
        message:
            'At most $maxActiveMealCategories Meal Categories may be active.',
      );
    }

    if (activeCount < minActiveMealCategories) {
      throw const MealCategoriesValidationException(
        code: MealCategoriesValidationCode.tooFewActiveCategories,
        message:
            'At least $minActiveMealCategories Meal Category must be active.',
      );
    }

    for (final definition in canonicalMealCategoryDefaultDefinitions) {
      final matchingId = items.where((item) => item.id == definition.id);
      if (matchingId.isEmpty ||
          matchingId.single.defaultKey != definition.key) {
        throw MealCategoriesValidationException(
          code: MealCategoriesValidationCode.missingCanonicalDefault,
          message: 'Missing canonical Meal Category ${definition.id}.',
        );
      }
    }

    _validateCanonicalDefaultOrder(items);
  }

  /// Breakfast, Lunch, Dinner and Snacks hold a fixed relative order.
  ///
  /// Anchored to durable identity rather than to `displayName`: renaming
  /// `meal_slot_2` from "Lunch" to "Pre Workout" leaves it occupying the Lunch
  /// anchor, so ordering never follows what a category happens to be called.
  ///
  /// Checked across every item, archived ones included. Keeping an archived
  /// default in its canonical slot is what lets a later restore land back
  /// between the right neighbours instead of at the end of the list. Custom
  /// categories, which carry no `defaultKey`, are free to sit anywhere between
  /// or around these anchors.
  static void _validateCanonicalDefaultOrder(Iterable<MealCategory> items) {
    var previousOrder = -1;
    MealCategoryDefaultKey? previousKey;

    for (final definition in canonicalMealCategoryDefaultDefinitions) {
      final anchor =
          items.firstWhere((item) => item.defaultKey == definition.key);
      if (anchor.order <= previousOrder) {
        throw MealCategoriesValidationException(
          code: MealCategoriesValidationCode.canonicalDefaultOrderViolated,
          message: '${definition.key.storageValue} must stay after '
              '${previousKey?.storageValue}.',
        );
      }
      previousOrder = anchor.order;
      previousKey = definition.key;
    }
  }
}
