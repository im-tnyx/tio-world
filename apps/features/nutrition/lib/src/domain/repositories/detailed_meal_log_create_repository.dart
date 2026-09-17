import 'package:tio_shared/shared.dart';

/// Confirmed provider-neutral facts for one detailed MealLog item create.
///
/// Durable item identity and parent identity are intentionally absent. The
/// database owns those facts and returns them through [MealLogEntry.detailed].
final class DetailedMealLogCreateItem {
  DetailedMealLogCreateItem({
    required String displayName,
    String? brandName,
    required num quantity,
    required String servingUnit,
    required this.nutritionSnapshot,
  })  : displayName = _requireNonBlank(displayName, 'displayName'),
        brandName = _normalizeOptionalText(brandName),
        quantity = _requirePositiveFinite(quantity, 'quantity'),
        servingUnit = _requireNonBlank(servingUnit, 'servingUnit');

  final String displayName;
  final String? brandName;
  final num quantity;
  final String servingUnit;
  final NutritionSnapshot nutritionSnapshot;
}

/// User/resolver-owned facts required to create one detailed MealLog entry.
///
/// Physical parent/item IDs, authenticated user identity, mode, revision and
/// database timestamps are store-owned and deliberately absent.
final class DetailedMealLogCreate {
  DetailedMealLogCreate({
    required String clientMutationId,
    required this.mealCategoryId,
    String? mealName,
    String? note,
    required this.consumedAt,
    required this.consumedLocalDate,
    String? consumedTimezoneId,
    this.consumedUtcOffsetMinutes,
    this.captureSource,
    required List<DetailedMealLogCreateItem> items,
  })  : clientMutationId = _normalizeClientMutationId(clientMutationId),
        mealName = _normalizeOptionalText(mealName),
        note = _normalizeOptionalText(note),
        consumedTimezoneId = _normalizeOptionalText(consumedTimezoneId),
        items = _validateAndCopyItems(items) {
    if (this.consumedTimezoneId == null &&
        consumedUtcOffsetMinutes == null) {
      throw ArgumentError(
        'Either consumedTimezoneId or consumedUtcOffsetMinutes must be provided.',
      );
    }
  }

  /// Stable UUID for this one logical create operation.
  ///
  /// Retry the same logical create with the same value. Never generate a new
  /// mutation identity merely because the transport outcome is unknown.
  final String clientMutationId;
  final String mealCategoryId;
  final String? mealName;
  final String? note;
  final DateTime consumedAt;
  final MealLogLocalDate consumedLocalDate;
  final String? consumedTimezoneId;
  final int? consumedUtcOffsetMinutes;
  final MealLogCaptureSource? captureSource;
  final List<DetailedMealLogCreateItem> items;
}

/// Optional detailed-create capability for canonical actual MealLog history.
///
/// This remains separate from [MealLogRepository] so established manual-only
/// test doubles/read harnesses are not forced to fabricate a detailed write API.
abstract interface class DetailedMealLogCreateRepository {
  Future<MealLogEntry> createDetailed(DetailedMealLogCreate input);
}

final _canonicalUuid = RegExp(
  r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
);

String _normalizeClientMutationId(String value) {
  if (value.trim() != value || !_canonicalUuid.hasMatch(value)) {
    throw ArgumentError.value(
      value,
      'clientMutationId',
      'must be a canonical UUID string',
    );
  }
  return value.toLowerCase();
}

String? _normalizeOptionalText(String? value) {
  if (value == null || value.trim().isEmpty) return null;
  return value;
}

String _requireNonBlank(String value, String name) {
  if (value.trim().isEmpty) {
    throw ArgumentError.value(value, name, 'must not be blank');
  }
  return value;
}

num _requirePositiveFinite(num value, String name) {
  if (!value.isFinite || value <= 0) {
    throw ArgumentError.value(value, name, 'must be finite and greater than zero');
  }
  return value;
}

List<DetailedMealLogCreateItem> _validateAndCopyItems(
  List<DetailedMealLogCreateItem> items,
) {
  if (items.isEmpty) {
    throw ArgumentError.value(
      items,
      'items',
      'must contain at least one confirmed item',
    );
  }
  return List<DetailedMealLogCreateItem>.unmodifiable(items);
}
