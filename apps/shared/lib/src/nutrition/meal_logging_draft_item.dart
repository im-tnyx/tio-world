import 'nutrition_snapshot.dart';

/// One editable item inside a meal logging draft.
///
/// This is intentionally provider-neutral. A future parser or food provider
/// may know catalog IDs, serving IDs, confidence scores, or raw source payloads,
/// but none of those become canonical draft truth here. The draft keeps only
/// the minimum facts the Meal Editor can review and correct.
///
/// [quantity] and [servingUnit] are independently optional so an incomplete
/// parse can remain editable without fabricating a missing amount or unit.
/// Nutrition is also optional; when present, [NutritionSnapshot] preserves the
/// canonical distinction between an unknown nutrient and a known zero.
final class MealLoggingDraftItem {
  MealLoggingDraftItem({
    required String displayName,
    num? quantity,
    String? servingUnit,
    this.nutritionSnapshot,
  })  : displayName = _validateDisplayName(displayName),
        quantity = _validateQuantity(quantity),
        servingUnit = _normalizeServingUnit(servingUnit);

  /// Human-readable food/item identity owned by the draft, not a provider ID.
  final String displayName;

  /// Parsed or user-corrected amount when known.
  ///
  /// Zero is not a meaningful consumed quantity, so present values must be
  /// finite and strictly positive. `null` means the amount is not known yet.
  final num? quantity;

  /// Provider-neutral serving/unit label such as `g`, `ml`, `piece`, or `cup`.
  ///
  /// This field is deliberately a label rather than a catalog serving ID. A
  /// blank value is normalized to `null` so unknown never becomes fake data.
  final String? servingUnit;

  /// Known canonical nutrition for this draft item, when available.
  ///
  /// A null snapshot means nutrition has not been resolved for the item. Inside
  /// a non-null snapshot, an absent nutrient remains unknown while explicit
  /// zero remains known zero.
  final NutritionSnapshot? nutritionSnapshot;

  static String _validateDisplayName(String value) {
    if (value.trim().isEmpty) {
      throw ArgumentError.value(
        value,
        'displayName',
        'must contain at least one non-whitespace character',
      );
    }
    return value;
  }

  static num? _validateQuantity(num? value) {
    if (value == null) return null;
    if (!value.isFinite || value <= 0) {
      throw ArgumentError.value(
        value,
        'quantity',
        'must be finite and greater than zero when present',
      );
    }
    return value;
  }

  static String? _normalizeServingUnit(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    return value;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MealLoggingDraftItem &&
          other.displayName == displayName &&
          other.quantity == quantity &&
          other.servingUnit == servingUnit &&
          other.nutritionSnapshot == nutritionSnapshot;

  @override
  int get hashCode => Object.hash(
        displayName,
        quantity,
        servingUnit,
        nutritionSnapshot,
      );
}
