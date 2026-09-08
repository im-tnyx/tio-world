enum MealCategoriesValidationCode {
  malformedConfig,
  unsupportedSchemaVersion,
  emptyId,
  invalidId,
  blankDisplayName,
  negativeOrder,
  duplicateId,
  duplicateOrder,
  duplicateActiveDisplayName,
  duplicateDefaultKey,
  invalidDefaultMapping,
  missingCanonicalDefault,
  retainedIdentityRemoved,
  tooManyActiveCategories,
  tooFewActiveCategories,
  tooManyRetainedCategories,
  canonicalDefaultOrderViolated,
  invalidGeneratedId,
  idGenerationExhausted,
}

/// Deterministic failure raised when Meal Category state violates its domain
/// contract. Invalid persisted state is rejected rather than repaired or
/// truncated.
final class MealCategoriesValidationException implements Exception {
  const MealCategoriesValidationException({
    required this.code,
    required this.message,
  });

  final MealCategoriesValidationCode code;
  final String message;

  @override
  String toString() => 'MealCategoriesValidationException($code, $message)';
}
