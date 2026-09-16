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
/// [consumedNutritionSnapshot] is also optional; when present, it represents
/// the consumed-total nutrition for this item's current quantity/serving, never
/// a per-serving value. A consumer that changes the quantity or serving must
/// replace/recompute the snapshot, or clear it when the corrected total is not
/// known. Inside a known [NutritionSnapshot], unknown nutrients stay unknown
/// while explicit zero remains known zero.
final class MealLoggingDraftItem {
  MealLoggingDraftItem({
    required String displayName,
    num? quantity,
    String? servingUnit,
    this.consumedNutritionSnapshot,
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

  /// Consumed-total canonical nutrition for this item's current amount.
  ///
  /// This is never a per-serving snapshot. If [quantity] or [servingUnit] is
  /// corrected, a newly constructed item must also replace/recompute this value
  /// or set it to `null` unless the existing snapshot is still known to describe
  /// the corrected consumed total.
  ///
  /// A null snapshot means nutrition has not been resolved for the item. Inside
  /// a non-null snapshot, an absent nutrient remains unknown while explicit
  /// zero remains known zero.
  final NutritionSnapshot? consumedNutritionSnapshot;

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
          other.consumedNutritionSnapshot == consumedNutritionSnapshot;

  @override
  int get hashCode => Object.hash(
        displayName,
        quantity,
        servingUnit,
        consumedNutritionSnapshot,
      );
}
