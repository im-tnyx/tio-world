import 'nutrition_snapshot.dart';

/// Durable consumed-item truth for one detailed [MealLogEntry].
///
/// This value deliberately owns only provider-independent facts required to
/// reconstruct what the user confirmed as consumed. Provider/catalog IDs,
/// serving-catalog identities, raw provider payloads and AI metadata are
/// separate provenance concerns and must never replace [nutritionSnapshot] as
/// historical nutrition truth.
final class MealLogItemSnapshot {
  MealLogItemSnapshot({
    required String id,
    required String mealLogEntryId,
    required String displayName,
    String? brandName,
    required num quantity,
    required String servingUnit,
    required this.nutritionSnapshot,
  })  : id = _requireIdentity(id, 'id'),
        mealLogEntryId = _requireIdentity(
          mealLogEntryId,
          'mealLogEntryId',
        ),
        displayName = _requireNonBlankText(displayName, 'displayName'),
        brandName = _normalizeOptionalText(brandName),
        quantity = _validateQuantity(quantity),
        servingUnit = _requireNonBlankText(servingUnit, 'servingUnit');

  /// Opaque durable child-row identity.
  final String id;

  /// Opaque durable parent [MealLogEntry] identity.
  final String mealLogEntryId;

  /// Human-readable item identity frozen at final confirmation time.
  final String displayName;

  /// Optional brand text frozen with the consumed item.
  final String? brandName;

  /// Final confirmed consumed quantity for [servingUnit].
  final num quantity;

  /// Final confirmed provider-neutral unit label such as `g`, `ml`, `piece`,
  /// or `cup`.
  final String servingUnit;

  /// Canonical consumed-total nutrition for this final quantity/serving.
  ///
  /// An empty current-registry snapshot remains representable so an older
  /// client does not reject a future snapshot merely because every serialized
  /// nutrient identity is unknown to its current registry.
  final NutritionSnapshot nutritionSnapshot;

  static String _requireIdentity(String value, String name) {
    if (value.isEmpty || value.trim() != value) {
      throw ArgumentError.value(
        value,
        name,
        'must be a non-empty identity without outer whitespace',
      );
    }
    return value;
  }

  static String _requireNonBlankText(String value, String name) {
    if (value.trim().isEmpty) {
      throw ArgumentError.value(
        value,
        name,
        'must contain at least one non-whitespace character',
      );
    }
    return value;
  }

  static String? _normalizeOptionalText(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    return value;
  }

  static num _validateQuantity(num value) {
    if (!value.isFinite || value <= 0) {
      throw ArgumentError.value(
        value,
        'quantity',
        'must be finite and greater than zero',
      );
    }
    return value;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MealLogItemSnapshot &&
          other.id == id &&
          other.mealLogEntryId == mealLogEntryId &&
          other.displayName == displayName &&
          other.brandName == brandName &&
          other.quantity == quantity &&
          other.servingUnit == servingUnit &&
          other.nutritionSnapshot == nutritionSnapshot;

  @override
  int get hashCode => Object.hash(
        id,
        mealLogEntryId,
        displayName,
        brandName,
        quantity,
        servingUnit,
        nutritionSnapshot,
      );
}
