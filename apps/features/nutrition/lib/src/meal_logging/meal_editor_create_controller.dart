import 'package:flutter/foundation.dart';
import 'package:tio_shared/shared.dart';

/// Derived nutrition shown by the create-mode Meal Editor.
///
/// A nutrient total is `null` when any current draft item does not know that
/// nutrient. Summing only the known subset would understate the meal and turn
/// incomplete parser truth into a misleading authoritative-looking number.
final class MealEditorNutritionSummary {
  const MealEditorNutritionSummary({
    required this.energyKcal,
    required this.proteinGrams,
    required this.carbohydrateGrams,
    required this.fatGrams,
  });

  final num? energyKcal;
  final num? proteinGrams;
  final num? carbohydrateGrams;
  final num? fatGrams;
}

/// Owns discardable create-mode Meal Editor state before any durable write.
///
/// This controller deliberately knows nothing about AI/provider schemas,
/// Supabase, `MealLogEntry` persistence, meal-category repositories, or routes.
/// It starts from the canonical provider-neutral [MealLoggingDraft], keeps local
/// corrections in memory, and can emit a corrected draft for a later explicit
/// persistence boundary.
final class MealEditorCreateController extends ChangeNotifier {
  MealEditorCreateController({required MealLoggingDraft initialDraft})
      : _captureSource = initialDraft.captureSource,
        _mealName = initialDraft.mealName,
        _items = List<MealLoggingDraftItem>.of(initialDraft.items);

  final MealLogCaptureSource _captureSource;
  String? _mealName;
  final List<MealLoggingDraftItem> _items;

  MealLogCaptureSource get captureSource => _captureSource;
  String? get mealName => _mealName;
  List<MealLoggingDraftItem> get items =>
      List<MealLoggingDraftItem>.unmodifiable(_items);

  MealEditorNutritionSummary get nutritionSummary => MealEditorNutritionSummary(
        energyKcal: _completeTotal(NutrientId.energy),
        proteinGrams: _completeTotal(NutrientId.protein),
        carbohydrateGrams: _completeTotal(NutrientId.carbohydrate),
        fatGrams: _completeTotal(NutrientId.fat),
      );

  /// Current corrected provider-neutral draft.
  MealLoggingDraft get draft => MealLoggingDraft(
        mealName: _mealName,
        captureSource: _captureSource,
        items: _items,
      );

  void updateMealName(String value) {
    final normalized = value.trim().isEmpty ? null : value;
    if (normalized == _mealName) return;
    _mealName = normalized;
    notifyListeners();
  }

  bool canIncrementQuantity(int index) => _itemAt(index).quantity != null;

  bool canDecrementQuantity(int index) {
    final quantity = _itemAt(index).quantity;
    return quantity != null && quantity > 1;
  }

  bool incrementQuantity(int index) {
    final quantity = _itemAt(index).quantity;
    if (quantity == null) return false;
    return updateQuantity(index, quantity + 1);
  }

  bool decrementQuantity(int index) {
    final quantity = _itemAt(index).quantity;
    if (quantity == null || quantity <= 1) return false;
    return updateQuantity(index, quantity - 1);
  }

  /// Changes a known quantity while preserving consumed-total semantics.
  ///
  /// The draft contract has no provider serving/base snapshot yet, so this
  /// controller does not invent unit conversions. For a correction that keeps
  /// the same provider-neutral [MealLoggingDraftItem.servingUnit], a known
  /// consumed snapshot can be deterministically rescaled by `new / old`.
  /// Unknown nutrition remains unknown and explicit zero remains zero.
  ///
  /// Returns false when the current quantity is unknown, the requested value is
  /// invalid, or rescaling would violate [NutritionSnapshot] invariants.
  bool updateQuantity(int index, num quantity) {
    if (!quantity.isFinite || quantity <= 0) return false;

    final current = _itemAt(index);
    final previousQuantity = current.quantity;
    if (previousQuantity == null) return false;
    if (previousQuantity == quantity) return true;

    final ratio = quantity / previousQuantity;
    NutritionSnapshot? scaledSnapshot;
    final snapshot = current.consumedNutritionSnapshot;
    if (snapshot != null) {
      try {
        scaledSnapshot = NutritionSnapshot(
          schemaVersion: snapshot.schemaVersion,
          nutrients: {
            for (final entry in snapshot.nutrients.entries)
              entry.key: entry.value * ratio,
          },
        );
      } on ArgumentError {
        return false;
      }
    }

    _items[index] = MealLoggingDraftItem(
      displayName: current.displayName,
      quantity: quantity,
      servingUnit: current.servingUnit,
      consumedNutritionSnapshot: scaledSnapshot,
    );
    notifyListeners();
    return true;
  }

  bool canRemoveItem(int index) {
    _itemAt(index);
    return _items.length > 1;
  }

  /// Removes one local draft item, but never constructs an empty valid draft.
  bool removeItem(int index) {
    _itemAt(index);
    if (_items.length <= 1) return false;
    _items.removeAt(index);
    notifyListeners();
    return true;
  }

  num? _completeTotal(NutrientId nutrient) {
    num total = 0;
    for (final item in _items) {
      final snapshot = item.consumedNutritionSnapshot;
      if (snapshot == null || !snapshot.containsNutrient(nutrient)) {
        return null;
      }
      total += snapshot.amountFor(nutrient)!;
    }
    return total;
  }

  MealLoggingDraftItem _itemAt(int index) {
    RangeError.checkValidIndex(index, _items, 'index');
    return _items[index];
  }
}
