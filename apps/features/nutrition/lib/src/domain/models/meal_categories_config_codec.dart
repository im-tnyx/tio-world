import 'meal_categories_config.dart';
import 'meal_categories_policy.dart';
import 'meal_categories_validation.dart';
import 'meal_category.dart';

/// Strict V1 codec for JSON-compatible Meal Category maps.
///
/// Null represents absent customization and is not materialized into defaults
/// here; callers resolve it through [MealCategoriesConfig.resolve].
abstract final class MealCategoriesConfigCodec {
  static const _configKeys = {'schema_version', 'items'};
  static const _requiredItemKeys = {
    'id',
    'display_name',
    'active',
    'order',
  };
  static const _allowedItemKeys = {..._requiredItemKeys, 'default_key'};

  static Map<String, Object?> encode(MealCategoriesConfig config) {
    config.validate();
    return <String, Object?>{
      'schema_version': config.schemaVersion,
      'items': <Object?>[
        for (final item in config.orderedItems)
          <String, Object?>{
            'id': item.id,
            'default_key': item.defaultKey?.storageValue,
            'display_name': item.displayName,
            'active': item.active,
            'order': item.order,
          },
      ],
    };
  }

  static MealCategoriesConfig? decode(Object? raw) {
    if (raw == null) return null;

    final map = _requireMap(raw, 'meal_categories_config');
    _requireExactKeys(map, _configKeys, 'meal_categories_config');

    final schemaVersion = map['schema_version'];
    if (schemaVersion is! int) {
      throw _malformed('schema_version must be an integer.');
    }
    if (schemaVersion != MealCategoriesPolicy.currentSchemaVersion) {
      throw MealCategoriesValidationException(
        code: MealCategoriesValidationCode.unsupportedSchemaVersion,
        message: 'Unsupported Meal Categories schema version: $schemaVersion.',
      );
    }

    final rawItems = map['items'];
    if (rawItems is! List<Object?>) {
      throw _malformed('items must be a list.');
    }

    final items = <MealCategory>[];
    for (var index = 0; index < rawItems.length; index++) {
      final itemMap = _requireMap(rawItems[index], 'items[$index]');
      _requireAllowedKeys(
        itemMap,
        required: _requiredItemKeys,
        allowed: _allowedItemKeys,
        path: 'items[$index]',
      );

      final id = itemMap['id'];
      final displayName = itemMap['display_name'];
      final active = itemMap['active'];
      final order = itemMap['order'];
      final rawDefaultKey = itemMap['default_key'];

      if (id is! String ||
          displayName is! String ||
          active is! bool ||
          order is! int) {
        throw _malformed('items[$index] contains an invalid field type.');
      }

      MealCategoryDefaultKey? defaultKey;
      if (rawDefaultKey != null) {
        if (rawDefaultKey is! String) {
          throw _malformed('items[$index].default_key must be a string/null.');
        }
        defaultKey = MealCategoryDefaultKey.fromStorageValue(rawDefaultKey);
        if (defaultKey == null) {
          throw _malformed(
            'items[$index].default_key is not a supported canonical key.',
          );
        }
      }

      items.add(
        MealCategory(
          id: id,
          defaultKey: defaultKey,
          displayName: displayName,
          active: active,
          order: order,
        ),
      );
    }

    final config = MealCategoriesConfig(
      schemaVersion: schemaVersion,
      items: items,
    );
    config.validate();
    return config;
  }

  static Map<String, Object?> _requireMap(Object? raw, String path) {
    if (raw is! Map<Object?, Object?>) {
      throw _malformed('$path must be an object.');
    }
    final result = <String, Object?>{};
    for (final entry in raw.entries) {
      final key = entry.key;
      if (key is! String) {
        throw _malformed('$path contains a non-string key.');
      }
      result[key] = entry.value;
    }
    return result;
  }

  static void _requireExactKeys(
    Map<String, Object?> map,
    Set<String> expected,
    String path,
  ) {
    final actual = map.keys.toSet();
    if (actual.length != expected.length || !actual.containsAll(expected)) {
      throw _malformed('$path does not match the V1 contract.');
    }
  }

  static void _requireAllowedKeys(
    Map<String, Object?> map, {
    required Set<String> required,
    required Set<String> allowed,
    required String path,
  }) {
    final actual = map.keys.toSet();
    if (!actual.containsAll(required) || !allowed.containsAll(actual)) {
      throw _malformed('$path does not match the V1 contract.');
    }
  }

  static MealCategoriesValidationException _malformed(String message) =>
      MealCategoriesValidationException(
        code: MealCategoriesValidationCode.malformedConfig,
        message: message,
      );
}
