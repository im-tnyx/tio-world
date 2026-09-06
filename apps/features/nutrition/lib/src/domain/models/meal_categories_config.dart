import 'meal_categories_policy.dart';
import 'meal_category.dart';
import 'meal_category_defaults.dart';

/// Versioned, repository-neutral Meal Category configuration.
///
/// A null persisted config is intentionally distinct from a customized config
/// and resolves to [canonicalDefaults] at runtime.
final class MealCategoriesConfig {
  MealCategoriesConfig({
    this.schemaVersion = MealCategoriesPolicy.currentSchemaVersion,
    required Iterable<MealCategory> items,
  }) : items = List<MealCategory>.unmodifiable(items);

  final int schemaVersion;
  final List<MealCategory> items;

  factory MealCategoriesConfig.canonicalDefaults() => MealCategoriesConfig(
        items: canonicalMealCategoryDefaultDefinitions
            .map((definition) => definition.resolve()),
      )..validate();

  static MealCategoriesConfig resolve(MealCategoriesConfig? customized) {
    final resolved = customized ?? MealCategoriesConfig.canonicalDefaults();
    resolved.validate();
    return resolved;
  }

  void validate() => MealCategoriesPolicy.validate(
        schemaVersion: schemaVersion,
        items: items,
      );

  List<MealCategory> get orderedItems {
    validate();
    final ordered = items.toList()
      ..sort((a, b) {
        final byOrder = a.order.compareTo(b.order);
        return byOrder != 0 ? byOrder : a.id.compareTo(b.id);
      });
    return List<MealCategory>.unmodifiable(ordered);
  }

  List<MealCategory> get activeItems => List<MealCategory>.unmodifiable(
        orderedItems.where((item) => item.active),
      );

  MealCategory? findById(String id) {
    validate();
    for (final item in items) {
      if (item.id == id) return item;
    }
    return null;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! MealCategoriesConfig ||
        schemaVersion != other.schemaVersion ||
        items.length != other.items.length) {
      return false;
    }
    for (var index = 0; index < items.length; index++) {
      if (items[index] != other.items[index]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(schemaVersion, Object.hashAll(items));
}
