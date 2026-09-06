import 'package:uuid/uuid.dart';

import '../models/meal_categories_policy.dart';
import '../models/meal_categories_validation.dart';

abstract interface class MealCategoryIdGenerator {
  /// Generates an opaque custom category ID that does not reuse any retained
  /// identity, including identities of archived categories.
  String generate(Iterable<String> retainedIds);
}

/// UUID-v4 implementation of the custom Meal Category identity contract.
final class UuidMealCategoryIdGenerator implements MealCategoryIdGenerator {
  UuidMealCategoryIdGenerator({
    String Function()? uuidV4,
    this.maxAttempts = 100,
  }) : _uuidV4 = uuidV4 ?? _defaultUuidV4 {
    if (maxAttempts <= 0) {
      throw ArgumentError.value(
        maxAttempts,
        'maxAttempts',
        'must be positive',
      );
    }
  }

  final String Function() _uuidV4;
  final int maxAttempts;

  static String _defaultUuidV4() => const Uuid().v4();

  @override
  String generate(Iterable<String> retainedIds) {
    final retained = retainedIds.toSet();
    for (var attempt = 0; attempt < maxAttempts; attempt++) {
      final suffix = _uuidV4().trim().toLowerCase();
      final candidate = 'meal_slot_$suffix';
      if (!MealCategoriesPolicy.isValidCustomId(candidate)) {
        throw const MealCategoriesValidationException(
          code: MealCategoriesValidationCode.invalidGeneratedId,
          message: 'Generated Meal Category suffix is not a UUID v4.',
        );
      }

      if (!retained.contains(candidate)) return candidate;
    }

    throw const MealCategoriesValidationException(
      code: MealCategoriesValidationCode.idGenerationExhausted,
      message: 'Unable to generate a unique Meal Category id.',
    );
  }
}
