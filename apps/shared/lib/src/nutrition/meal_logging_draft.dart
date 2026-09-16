import 'meal_log_capture_source.dart';
import 'meal_logging_draft_item.dart';

/// Provider-neutral, discardable meal state awaiting explicit user review.
///
/// A parser, search result, repeat flow, or another future capture adapter may
/// create this draft, but the draft itself is not durable actual-history truth.
/// It becomes eligible for persistence only after a later Meal Editor flow has
/// let the user review/correct it and explicitly confirms `Log Meal`.
final class MealLoggingDraft {
  MealLoggingDraft({
    String? mealName,
    required this.captureSource,
    required List<MealLoggingDraftItem> items,
  })  : mealName = _normalizeMealName(mealName),
        items = List<MealLoggingDraftItem>.unmodifiable(
          _validateAndCopyItems(items),
        );

  /// Suggested/editable meal name. Blank is represented as unknown.
  final String? mealName;

  /// How the user initiated this meal capture, independent of AI/provider.
  ///
  /// Natural-language capture uses [MealLogCaptureSource.text]. Provider or
  /// model identity does not belong here.
  final MealLogCaptureSource captureSource;

  /// Editable parsed items. A successful draft must contain at least one item.
  ///
  /// A parser result with no identifiable items is a parse/recovery failure,
  /// not an empty meal that should move toward durable history.
  final List<MealLoggingDraftItem> items;

  static String? _normalizeMealName(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    return value;
  }

  static List<MealLoggingDraftItem> _validateAndCopyItems(
    List<MealLoggingDraftItem> items,
  ) {
    if (items.isEmpty) {
      throw ArgumentError.value(
        items,
        'items',
        'must contain at least one draft item',
      );
    }
    return List<MealLoggingDraftItem>.of(items);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! MealLoggingDraft ||
        other.mealName != mealName ||
        other.captureSource != captureSource ||
        other.items.length != items.length) {
      return false;
    }

    for (var index = 0; index < items.length; index++) {
      if (other.items[index] != items[index]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(
        mealName,
        captureSource,
        Object.hashAll(items),
      );
}
