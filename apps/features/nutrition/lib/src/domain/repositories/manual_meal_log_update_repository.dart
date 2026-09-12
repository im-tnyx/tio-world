import 'package:tio_shared/shared.dart';

import 'meal_log_repository.dart';

/// Raised when a manual MealLog update targets a row that is not visible to
/// the current repository owner.
final class MealLogUpdateNotFound implements Exception {
  const MealLogUpdateNotFound({required this.id});

  final String id;

  @override
  String toString() => 'MealLogUpdateNotFound(id: $id)';
}

/// Raised when a caller tries to update from a stale durable revision.
final class MealLogUpdateConflict implements Exception {
  const MealLogUpdateConflict({
    required this.id,
    required this.expectedRevision,
    this.actualRevision,
  });

  final String id;
  final int expectedRevision;
  final int? actualRevision;

  @override
  String toString() =>
      'MealLogUpdateConflict(id: $id, expectedRevision: $expectedRevision, '
      'actualRevision: $actualRevision)';
}

/// Raised when an update may already have reached durable storage but its
/// result cannot yet be reconciled safely.
///
/// A retry must reuse the same [id], [expectedRevision], and intended facts.
/// Generating a fresh expected revision without reading canonical state can
/// silently overwrite a newer edit.
final class MealLogUpdateOutcomeUnknown implements Exception {
  const MealLogUpdateOutcomeUnknown({
    required this.id,
    required this.expectedRevision,
    this.cause,
  });

  final String id;
  final int expectedRevision;
  final Object? cause;

  @override
  String toString() =>
      'MealLogUpdateOutcomeUnknown(id: $id, '
      'expectedRevision: $expectedRevision)';
}

/// Caller-owned editable facts for one existing manual MealLog entry.
///
/// Durable identity, authenticated owner, mode, capture source, create time,
/// and the next revision are deliberately absent. The caller supplies only the
/// revision it originally read; the database owns the successful `+1`.
final class ManualMealLogUpdate {
  ManualMealLogUpdate({
    required String id,
    required this.expectedRevision,
    required String mealCategoryId,
    String? mealName,
    String? note,
    required this.consumedAt,
    required this.consumedLocalDate,
    String? consumedTimezoneId,
    this.consumedUtcOffsetMinutes,
    required this.manualNutritionSnapshot,
  })  : id = _requireCanonicalIdentity(id, 'id'),
        mealCategoryId =
            _requireCanonicalIdentity(mealCategoryId, 'mealCategoryId'),
        mealName = _normalizeOptionalText(mealName),
        note = _normalizeOptionalText(note),
        consumedTimezoneId = _normalizeOptionalText(consumedTimezoneId) {
    if (expectedRevision < 1) {
      throw ArgumentError.value(
        expectedRevision,
        'expectedRevision',
        'must be at least 1',
      );
    }
    if (this.consumedTimezoneId == null &&
        consumedUtcOffsetMinutes == null) {
      throw ArgumentError(
        'Either consumedTimezoneId or consumedUtcOffsetMinutes must be provided.',
      );
    }
  }

  final String id;
  final int expectedRevision;
  final String mealCategoryId;
  final String? mealName;
  final String? note;
  final DateTime consumedAt;
  final MealLogLocalDate consumedLocalDate;
  final String? consumedTimezoneId;
  final int? consumedUtcOffsetMinutes;
  final NutritionSnapshot manualNutritionSnapshot;

  static String _requireCanonicalIdentity(String value, String name) {
    if (value.isEmpty || value.trim() != value) {
      throw ArgumentError.value(
        value,
        name,
        'must be nonblank without surrounding whitespace',
      );
    }
    return value;
  }

  static String? _normalizeOptionalText(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    return value;
  }
}

/// Additive update capability for canonical MealLog repositories.
///
/// The create/read/list interface remains source-compatible for existing read
/// harnesses and test doubles. Production repository owners implement this
/// capability when they support the TNYX-203 optimistic update contract.
abstract interface class ManualMealLogUpdateRepository {
  Future<MealLogEntry> updateManual(ManualMealLogUpdate input);
}

/// Canonical manual-update entry point from a [MealLogRepository] reference.
extension MealLogRepositoryManualUpdate on MealLogRepository {
  Future<MealLogEntry> updateManual(ManualMealLogUpdate input) {
    final repository = this;
    if (repository is! ManualMealLogUpdateRepository) {
      throw UnsupportedError(
        '${repository.runtimeType} does not support manual MealLog updates.',
      );
    }
    return repository.updateManual(input);
  }
}
