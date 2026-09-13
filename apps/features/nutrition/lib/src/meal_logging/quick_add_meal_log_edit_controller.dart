import 'package:flutter/foundation.dart';
import 'package:tio_shared/shared.dart';

import '../domain/repositories/manual_meal_log_update_repository.dart';
import '../domain/repositories/meal_log_repository.dart';
import 'quick_add_meal_log_create_controller.dart';

enum QuickAddMealLogEditStatus {
  idle,
  submitting,
  failed,
  outcomeUnknown,
  conflict,
  succeeded,
}

@immutable
final class QuickAddMealLogEditState {
  const QuickAddMealLogEditState._({
    required this.status,
    this.message,
    this.entry,
  });

  const QuickAddMealLogEditState.idle()
      : this._(status: QuickAddMealLogEditStatus.idle);

  final QuickAddMealLogEditStatus status;
  final String? message;
  final MealLogEntry? entry;

  bool get isSubmitting => status == QuickAddMealLogEditStatus.submitting;
  bool get isOutcomeUnknown =>
      status == QuickAddMealLogEditStatus.outcomeUnknown;
  bool get locksDraft => isSubmitting || isOutcomeUnknown;
}

/// Owns one canonical manual MealLog edit and its optimistic retry facts.
///
/// The entry passed to the constructor must come from `readById` immediately
/// before the editor opens. The controller never accepts the Diary's lossy
/// card read model as update truth. A conflict reloads the latest canonical
/// row and makes it the new base; the presentation then replaces the visible
/// draft so the reader must deliberately make their change again.
final class QuickAddMealLogEditController extends ChangeNotifier {
  QuickAddMealLogEditController({
    required MealLogRepository repository,
    required MealLogEntry initialEntry,
    DateTime Function()? clock,
  })  : _repository = repository,
        _baseEntry = _requireEditable(initialEntry),
        _clock = clock ?? DateTime.now;

  static const String futureMealMessage = 'Meal time cannot be in the future.';
  static const String invalidMealMessage =
      'Review the meal details and try again.';
  static const String genericFailureMessage =
      "Couldn't save changes. Try again.";
  static const String outcomeUnknownMessage =
      'Save status is uncertain. Retry to check these same changes.';
  static const String conflictMessage =
      'This meal changed elsewhere. The latest version is shown — make your '
      'change again.';
  static const String notFoundMessage = 'This meal is no longer available.';

  final MealLogRepository _repository;
  final DateTime Function() _clock;

  MealLogEntry _baseEntry;
  MealLogEntry get baseEntry => _baseEntry;

  QuickAddMealLogEditState _state = const QuickAddMealLogEditState.idle();
  QuickAddMealLogEditState get state => _state;

  QuickAddMealLogDraft? _retryDraft;
  ManualMealLogUpdate? _retryInput;
  bool _disposed = false;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  /// Clears a known failure once any editable fact changes. An ambiguous
  /// outcome remains locked because its exact input may already be durable.
  void draftChanged() {
    if (_state.status != QuickAddMealLogEditStatus.failed &&
        _state.status != QuickAddMealLogEditStatus.conflict) {
      return;
    }
    _retryDraft = null;
    _retryInput = null;
    _setState(const QuickAddMealLogEditState.idle());
  }

  Future<MealLogEntry?> submit(QuickAddMealLogDraft draft) async {
    if (_state.isSubmitting) return null;

    ManualMealLogUpdate input;
    final frozenInput = _retryInput;
    final frozenDraft = _retryDraft;

    if (_state.isOutcomeUnknown && frozenInput != null) {
      input = frozenInput;
    } else {
      final validationMessage = _validateDraft(draft);
      if (validationMessage != null) {
        _clearRetry();
        _setFailure(validationMessage);
        return null;
      }

      // Only a genuinely changed time can be a future time. Comparing the
      // draft to the current device clock unconditionally would reject an
      // untouched historical meal after the device's timezone/wall-clock has
      // moved forward of that stored value — an unrelated name/macro edit
      // must still be allowed to save unchanged canonical time facts.
      final originalLocal = editableLocalDateTime(_baseEntry)!;
      if (draft.consumedLocalDateTime != originalLocal) {
        final now = _minuteOnly(_clock());
        if (draft.consumedLocalDateTime.isAfter(now)) {
          _clearRetry();
          _setFailure(futureMealMessage);
          return null;
        }
      }

      if (_state.status == QuickAddMealLogEditStatus.failed &&
          frozenDraft == draft &&
          frozenInput != null) {
        input = frozenInput;
      } else {
        try {
          input = _buildInput(draft);
        } on ArgumentError {
          _clearRetry();
          _setFailure(invalidMealMessage);
          return null;
        }
        _retryDraft = draft;
        _retryInput = input;
      }
    }

    _setState(
      const QuickAddMealLogEditState._(
        status: QuickAddMealLogEditStatus.submitting,
      ),
    );

    try {
      final entry = await _repository.updateManual(input);
      _baseEntry = _requireEditable(entry);
      _clearRetry();
      _setState(
        QuickAddMealLogEditState._(
          status: QuickAddMealLogEditStatus.succeeded,
          entry: entry,
        ),
      );
      return entry;
    } on MealLogUpdateOutcomeUnknown {
      _setState(
        const QuickAddMealLogEditState._(
          status: QuickAddMealLogEditStatus.outcomeUnknown,
          message: outcomeUnknownMessage,
        ),
      );
      return null;
    } on MealLogUpdateConflict {
      await _reloadAfterConflict(input.id);
      return null;
    } on MealLogUpdateNotFound {
      _clearRetry();
      _setFailure(notFoundMessage);
      return null;
    } on UnsupportedError {
      _clearRetry();
      _setFailure('Editing is not available for this meal yet.');
      return null;
    } on ArgumentError {
      _clearRetry();
      _setFailure(invalidMealMessage);
      return null;
    } on Object {
      _setFailure(genericFailureMessage);
      return null;
    }
  }

  Future<void> _reloadAfterConflict(String id) async {
    _clearRetry();
    try {
      final latest = await _repository.readById(id);
      if (latest == null) {
        _setFailure(notFoundMessage);
        return;
      }
      _baseEntry = _requireEditable(latest);
      _setState(
        QuickAddMealLogEditState._(
          status: QuickAddMealLogEditStatus.conflict,
          message: conflictMessage,
          entry: latest,
        ),
      );
    } on Object {
      _setFailure(
        'This meal changed elsewhere, but the latest version could not be '
        'loaded. Try again.',
      );
    }
  }

  ManualMealLogUpdate _buildInput(QuickAddMealLogDraft draft) {
    final base = _baseEntry;
    final baseSnapshot = base.manualNutritionSnapshot!;
    final nutrients = Map<NutrientId, num>.of(baseSnapshot.nutrients);

    nutrients[NutrientId.energy] = draft.caloriesKcal;
    _replaceOptional(
      nutrients,
      NutrientId.carbohydrate,
      draft.carbohydrateGrams,
    );
    _replaceOptional(nutrients, NutrientId.protein, draft.proteinGrams);
    _replaceOptional(nutrients, NutrientId.fat, draft.fatGrams);

    final originalLocal = editableLocalDateTime(base)!;
    final timeChanged = draft.consumedLocalDateTime != originalLocal;
    final local = draft.consumedLocalDateTime;

    return ManualMealLogUpdate(
      id: base.id,
      expectedRevision: base.revision,
      mealCategoryId: draft.mealCategoryId,
      mealName: draft.mealName,
      // Quick Add does not expose notes. Preserve the canonical fact instead
      // of treating absence from this editor as a request to erase it.
      note: base.note,
      consumedAt: timeChanged ? local.toUtc() : base.consumedAt,
      consumedLocalDate: timeChanged
          ? MealLogLocalDate(
              year: local.year,
              month: local.month,
              day: local.day,
            )
          : base.consumedLocalDate,
      consumedTimezoneId: timeChanged ? null : base.consumedTimezoneId,
      consumedUtcOffsetMinutes: timeChanged
          ? local.timeZoneOffset.inMinutes
          : base.consumedUtcOffsetMinutes,
      manualNutritionSnapshot: NutritionSnapshot(
        schemaVersion: baseSnapshot.schemaVersion,
        nutrients: nutrients,
      ),
    );
  }

  static DateTime? editableLocalDateTime(MealLogEntry entry) {
    final offsetMinutes = entry.consumedUtcOffsetMinutes;
    if (offsetMinutes == null) return null;
    final wall = entry.consumedAt.toUtc().add(Duration(minutes: offsetMinutes));
    return DateTime(
      wall.year,
      wall.month,
      wall.day,
      wall.hour,
      wall.minute,
    );
  }

  static MealLogEntry _requireEditable(MealLogEntry entry) {
    if (entry.mode != MealLogMode.manual ||
        entry.manualNutritionSnapshot == null ||
        editableLocalDateTime(entry) == null) {
      throw ArgumentError.value(
        entry.id,
        'entry',
        'must be a manual MealLog with exact consumed-time context',
      );
    }
    return entry;
  }

  String? _validateDraft(QuickAddMealLogDraft draft) {
    if (draft.mealCategoryId.trim().isEmpty) return invalidMealMessage;
    if (!_isValidAmount(draft.caloriesKcal)) return invalidMealMessage;
    for (final value in <num?>[
      draft.carbohydrateGrams,
      draft.proteinGrams,
      draft.fatGrams,
    ]) {
      if (value != null && !_isValidAmount(value)) return invalidMealMessage;
    }
    return null;
  }

  bool _isValidAmount(num value) => value.isFinite && value >= 0;

  static void _replaceOptional(
    Map<NutrientId, num> nutrients,
    NutrientId nutrient,
    num? value,
  ) {
    if (value == null) {
      nutrients.remove(nutrient);
    } else {
      nutrients[nutrient] = value;
    }
  }

  DateTime _minuteOnly(DateTime value) => DateTime(
        value.year,
        value.month,
        value.day,
        value.hour,
        value.minute,
      );

  void _clearRetry() {
    _retryDraft = null;
    _retryInput = null;
  }

  void _setFailure(String message) {
    _setState(
      QuickAddMealLogEditState._(
        status: QuickAddMealLogEditStatus.failed,
        message: message,
      ),
    );
  }

  void _setState(QuickAddMealLogEditState next) {
    if (_disposed) return;
    _state = next;
    notifyListeners();
  }
}
