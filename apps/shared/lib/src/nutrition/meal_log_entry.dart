import 'meal_log_capture_source.dart';
import 'meal_log_item_snapshot.dart';
import 'meal_log_local_date.dart';
import 'meal_log_mode.dart';
import 'nutrition_snapshot.dart';

/// Canonical durable actual-meal history aggregate.
///
/// Manual/coarse entries own one explicit meal-level nutrition snapshot.
/// Detailed entries own one or more durable consumed item snapshots. The two
/// modes deliberately do not share or duplicate authoritative nutrition truth.
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
    required this.detailedItems,
    required this.revision,
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
  ///
  /// [revision] is the durable optimistic-concurrency identity. Newly-created
  /// entries start at `1`; every successful durable update advances it exactly
  /// once. `updatedAt` remains audit/presentation metadata and is not a stale-
  /// write token.
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
    int revision = 1,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) {
    final normalizedTimezoneId = _normalizeOptionalTimezoneId(
      consumedTimezoneId,
    );
    _validateTimeContext(
      consumedTimezoneId: normalizedTimezoneId,
      consumedUtcOffsetMinutes: consumedUtcOffsetMinutes,
    );
    _validateRevision(revision);

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
      detailedItems: const <MealLogItemSnapshot>[],
      revision: revision,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  /// Creates one durable detailed actual meal from confirmed consumed items.
  ///
  /// Every item must already represent final consumed quantity/unit/nutrition
  /// truth and must reference this same [id]. Temporary parse uncertainty belongs
  /// in `MealLoggingDraftItem`, not in the durable actual-history aggregate.
  ///
  /// No meal-level nutrition total is stored here for detailed mode. Consumers
  /// derive totals from [detailedItems], preventing a second authoritative value
  /// from drifting away from the item snapshots.
  factory MealLogEntry.detailed({
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
    required List<MealLogItemSnapshot> detailedItems,
    int revision = 1,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) {
    final normalizedTimezoneId = _normalizeOptionalTimezoneId(
      consumedTimezoneId,
    );
    _validateTimeContext(
      consumedTimezoneId: normalizedTimezoneId,
      consumedUtcOffsetMinutes: consumedUtcOffsetMinutes,
    );
    _validateRevision(revision);

    final items = _validateAndCopyDetailedItems(
      mealLogEntryId: id,
      items: detailedItems,
    );

    return MealLogEntry._(
      id: id,
      userId: userId,
      mode: MealLogMode.detailed,
      mealCategoryId: mealCategoryId,
      mealName: _normalizeOptionalMealName(mealName),
      note: _normalizeOptionalNote(note),
      consumedAt: consumedAt,
      consumedLocalDate: consumedLocalDate,
      consumedTimezoneId: normalizedTimezoneId,
      consumedUtcOffsetMinutes: consumedUtcOffsetMinutes,
      captureSource: captureSource,
      manualNutritionSnapshot: null,
      detailedItems: items,
      revision: revision,
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

  /// How this actual log was initiated/captured, independent of provider origin
  /// and independent of [mode].
  final MealLogCaptureSource? captureSource;

  /// Manual/coarse nutrition truth.
  ///
  /// This is always non-null for [MealLogMode.manual] and always null for
  /// [MealLogMode.detailed]. Detailed nutrition truth lives in
  /// [detailedItems].
  final NutritionSnapshot? manualNutritionSnapshot;

  /// Durable item snapshots for detailed mode.
  ///
  /// Manual/coarse entries expose an empty immutable list rather than fabricated
  /// items. Detailed entries contain at least one item, and every item references
  /// this entry's [id].
  final List<MealLogItemSnapshot> detailedItems;

  /// Monotonic durable version used for optimistic concurrency.
  final int revision;

  final DateTime createdAt;
  final DateTime updatedAt;

  static void _validateTimeContext({
    required String? consumedTimezoneId,
    required int? consumedUtcOffsetMinutes,
  }) {
    if (consumedTimezoneId == null && consumedUtcOffsetMinutes == null) {
      throw ArgumentError(
        'Either consumedTimezoneId or consumedUtcOffsetMinutes must be provided.',
      );
    }
  }

  static void _validateRevision(int revision) {
    if (revision < 1) {
      throw ArgumentError.value(revision, 'revision', 'must be at least 1');
    }
  }

  static List<MealLogItemSnapshot> _validateAndCopyDetailedItems({
    required String mealLogEntryId,
    required List<MealLogItemSnapshot> items,
  }) {
    if (items.isEmpty) {
      throw ArgumentError.value(
        items,
        'detailedItems',
        'must contain at least one durable item snapshot',
      );
    }

    final itemIds = <String>{};
    for (final item in items) {
      if (item.mealLogEntryId != mealLogEntryId) {
        throw ArgumentError.value(
          item.mealLogEntryId,
          'detailedItems',
          'every item must reference MealLogEntry id $mealLogEntryId',
        );
      }
      if (!itemIds.add(item.id)) {
        throw ArgumentError.value(
          item.id,
          'detailedItems',
          'item identities must be unique within one MealLogEntry',
        );
      }
    }

    return List<MealLogItemSnapshot>.unmodifiable(items);
  }

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
