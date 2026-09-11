import 'meal_log_capture_source.dart';
import 'meal_log_local_date.dart';
import 'meal_log_mode.dart';
import 'nutrition_snapshot.dart';

/// Canonical durable actual-meal history aggregate.
///
/// This slice intentionally exposes manual-mode construction only. Detailed
/// construction is added later after the item snapshot semantics are frozen;
/// provider/item placeholders do not belong in this contract yet.
final class MealLogEntry {
  const MealLogEntry._({
    required this.id,
    required this.userId,
    required this.mode,
    required this.mealCategoryId,
    required this.mealName,
    required this.note,
    required this.consumedAt,
    required this.consumedLocalDate,
    required this.consumedTimezoneId,
    required this.consumedUtcOffsetMinutes,
    required this.captureSource,
    required this.manualNutritionSnapshot,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Creates a first-class manual/coarse actual meal log.
  ///
  /// [consumedAt] is an already-resolved canonical instant. This aggregate
  /// deliberately does not resolve local time, timezone rules, or DST. The
  /// separately supplied [consumedLocalDate] remains the user's intended Diary
  /// date identity even if the device timezone later changes.
  ///
  /// At least one meaningful consumed-time context value is required:
  /// [consumedTimezoneId] or [consumedUtcOffsetMinutes]. This preserves enough
  /// context for deterministic historical presentation/edit reconstruction
  /// without making this aggregate responsible for timezone resolution.
  factory MealLogEntry.manual({
    required String id,
    required String userId,
    required String mealCategoryId,
    String? mealName,
    String? note,
    required DateTime consumedAt,
    required MealLogLocalDate consumedLocalDate,
    String? consumedTimezoneId,
    int? consumedUtcOffsetMinutes,
    MealLogCaptureSource? captureSource,
    required NutritionSnapshot manualNutritionSnapshot,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) {
    final normalizedTimezoneId = _normalizeOptionalTimezoneId(
      consumedTimezoneId,
    );
    if (normalizedTimezoneId == null && consumedUtcOffsetMinutes == null) {
      throw ArgumentError(
        'Either consumedTimezoneId or consumedUtcOffsetMinutes must be provided.',
      );
    }

    return MealLogEntry._(
      id: id,
      userId: userId,
      mode: MealLogMode.manual,
      mealCategoryId: mealCategoryId,
      mealName: _normalizeOptionalMealName(mealName),
      note: _normalizeOptionalNote(note),
      consumedAt: consumedAt,
      consumedLocalDate: consumedLocalDate,
      consumedTimezoneId: normalizedTimezoneId,
      consumedUtcOffsetMinutes: consumedUtcOffsetMinutes,
      captureSource: captureSource,
      manualNutritionSnapshot: manualNutritionSnapshot,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  final String id;
  final String userId;
  final MealLogMode mode;
  final String mealCategoryId;

  /// User-entered name. Blank input is represented as absent rather than a
  /// fabricated display fallback such as `Quick Log`.
  final String? mealName;

  /// Optional meal-level context about the actual eating event.
  ///
  /// Blank input is represented as absent. Nonblank text is preserved as
  /// entered; visibility preferences must not rewrite or clear this data.
  final String? note;

  /// Already-resolved canonical instant used for chronology.
  final DateTime consumedAt;

  /// User-intended calendar date used for durable Diary grouping.
  final MealLogLocalDate consumedLocalDate;

  /// Timezone identity when the caller can provide one.
  final String? consumedTimezoneId;

  /// Resolved offset context in minutes when available.
  final int? consumedUtcOffsetMinutes;

  /// How this actual log was initiated/captured, independent of provider origin.
  final MealLogCaptureSource? captureSource;

  /// Manual/coarse nutrition truth.
  ///
  /// The field is nullable at the aggregate level so future detailed-mode
  /// construction can share this same canonical type. [MealLogEntry.manual]
  /// always requires and supplies a non-null value.
  final NutritionSnapshot? manualNutritionSnapshot;

  final DateTime createdAt;
  final DateTime updatedAt;

  static String? _normalizeOptionalMealName(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    return value;
  }

  static String? _normalizeOptionalNote(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    return value;
  }

  static String? _normalizeOptionalTimezoneId(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    return value;
  }
}
