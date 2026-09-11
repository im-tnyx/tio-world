import 'package:tio_shared/shared.dart';

/// User/resolver-owned facts required to create one manual MealLog entry.
///
/// Physical row identity, authenticated user identity, mode, and database
/// timestamps are intentionally absent. The repository/database own those
/// persistence facts and return the canonical [MealLogEntry] after creation.
final class ManualMealLogCreate {
  ManualMealLogCreate({
    required this.mealCategoryId,
    String? mealName,
    String? note,
    required this.consumedAt,
    required this.consumedLocalDate,
    String? consumedTimezoneId,
    this.consumedUtcOffsetMinutes,
    this.captureSource,
    required this.manualNutritionSnapshot,
  })  : mealName = _normalizeOptionalText(mealName),
        note = _normalizeOptionalText(note),
        consumedTimezoneId = _normalizeOptionalText(consumedTimezoneId) {
    if (this.consumedTimezoneId == null &&
        consumedUtcOffsetMinutes == null) {
      throw ArgumentError(
        'Either consumedTimezoneId or consumedUtcOffsetMinutes must be provided.',
      );
    }
  }

  final String mealCategoryId;
  final String? mealName;
  final String? note;
  final DateTime consumedAt;
  final MealLogLocalDate consumedLocalDate;
  final String? consumedTimezoneId;
  final int? consumedUtcOffsetMinutes;
  final MealLogCaptureSource? captureSource;
  final NutritionSnapshot manualNutritionSnapshot;

  static String? _normalizeOptionalText(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    return value;
  }
}

/// Canonical Nutrition-owned persistence boundary for actual MealLog history.
///
/// TNYX-195 intentionally exposes only the manual create/read foundation.
/// Update, delete, idempotency, stale-write handling, offline replay and Diary
/// read models belong to later bounded slices and are not frozen here.
abstract interface class MealLogRepository {
  /// Persists one manual/coarse actual meal and returns the durable canonical
  /// aggregate, including store-owned identity and timestamps.
  Future<MealLogEntry> createManual(ManualMealLogCreate input);

  /// Reads one canonical manual MealLog entry by opaque row identity.
  ///
  /// Returns `null` only when that identity is not visible for the current
  /// repository owner. Invalid/blank identities are caller errors.
  Future<MealLogEntry?> readById(String id);
}
