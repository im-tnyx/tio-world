import 'package:flutter/foundation.dart';
import 'package:tio_shared/shared.dart';
import 'package:uuid/uuid.dart';

import '../../../domain/repositories/meal_log_repository.dart';

typedef QuickAddCreateClock = DateTime Function();
typedef QuickAddMutationIdFactory = String Function();

enum QuickAddManualCreateStatus {
  idle,
  submitting,
  failed,
  outcomeUnknown,
  succeeded,
}

/// The route-local Quick Add facts captured at the moment the reader submits.
///
/// Strings stay strings here so the controller — not the widget — owns the
/// final parsing decision. That prevents presentation-only validation from
/// becoming the authority for what is persisted.
@immutable
final class QuickAddManualCreateDraft {
  const QuickAddManualCreateDraft({
    required this.mealCategoryId,
    required this.mealName,
    required this.caloriesText,
    required this.carbsText,
    required this.proteinText,
    required this.fatText,
    required this.consumedLocalDateTime,
  });

  final String mealCategoryId;
  final String mealName;
  final String caloriesText;
  final String carbsText;
  final String proteinText;
  final String fatText;
  final DateTime consumedLocalDateTime;
}

@immutable
final class QuickAddManualCreateState {
  const QuickAddManualCreateState({
    required this.status,
    this.errorMessage,
    this.createdEntry,
  });

  const QuickAddManualCreateState.idle()
      : status = QuickAddManualCreateStatus.idle,
        errorMessage = null,
        createdEntry = null;

  final QuickAddManualCreateStatus status;
  final String? errorMessage;
  final MealLogEntry? createdEntry;

  bool get isSubmitting => status == QuickAddManualCreateStatus.submitting;
  bool get isOutcomeUnknown =>
      status == QuickAddManualCreateStatus.outcomeUnknown;
}

/// Validation copy shared by the numeric rows and the final create mapper.
///
/// Blank is valid here because optional nutrients are allowed to be absent.
/// Calories' required-ness is enforced separately by [canSubmitDraft] and by
/// the final mapper, so an empty editor does not immediately paint an error.
String? quickAddNutritionValueError({
  required String label,
  required String text,
}) {
  final normalized = text.trim();
  if (normalized.isEmpty) return null;
  final value = double.tryParse(normalized);
  if (value == null || !value.isFinite) return 'Enter a number.';
  if (value < 0) return '$label cannot be negative.';
  return null;
}

/// Whether the current visible draft has enough locally valid information to
/// make the existing `Log Meal` action available.
///
/// This deliberately does not read the clock. The DateTime picker already owns
/// the live no-future interaction bound; the controller performs the defensive
/// real-clock check only when submit is actually requested. Avoiding a clock
/// read during every build also preserves Quick Add's one-shot draft snapshot
/// contract.
bool canSubmitDraft(QuickAddManualCreateDraft draft) {
  if (draft.mealCategoryId.trim().isEmpty) return false;
  if (draft.caloriesText.trim().isEmpty) return false;
  if (quickAddNutritionValueError(
        label: 'Calories',
        text: draft.caloriesText,
      ) !=
      null) {
    return false;
  }

  return <(String, String)>[
    ('Carbs', draft.carbsText),
    ('Protein', draft.proteinText),
    ('Fat', draft.fatText),
  ].every(
    (field) =>
        quickAddNutritionValueError(label: field.$1, text: field.$2) == null,
  );
}

/// Owns one Quick Add manual-create operation and its retry identity.
///
/// The editor owns draft lifetime; this controller owns the persistence
/// operation. In particular, an ambiguous repository outcome freezes the exact
/// [ManualMealLogCreate] and exposes only [retryUnknownOutcome], so a retry can
/// never accidentally mint a fresh idempotency key for a possibly-committed
/// meal.
final class QuickAddManualCreateController extends ChangeNotifier {
  QuickAddManualCreateController({
    required MealLogRepository repository,
    QuickAddCreateClock? clock,
    QuickAddMutationIdFactory? mutationIdFactory,
  })  : _repository = repository,
        _clock = clock ?? DateTime.now,
        _mutationIdFactory = mutationIdFactory ?? _defaultMutationId;

  static String _defaultMutationId() => const Uuid().v4();

  static const String genericFailureMessage =
      'Could not log this meal. Check your connection and try again.';
  static const String outcomeUnknownMessage =
      'Could not confirm whether this meal was logged. Retry to check the same save.';
  static const String missingCaloriesMessage =
      'Enter calories before logging this meal.';
  static const String missingMealCategoryMessage =
      'Choose a meal type before logging this meal.';
  static const String futureMealMessage =
      'Meal date and time cannot be in the future.';

  final MealLogRepository _repository;
  final QuickAddCreateClock _clock;
  final QuickAddMutationIdFactory _mutationIdFactory;

  QuickAddManualCreateState _state = const QuickAddManualCreateState.idle();
  QuickAddManualCreateState get state => _state;

  ManualMealLogCreate? _unknownOutcomeInput;
  bool _disposed = false;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  void _emit(QuickAddManualCreateState next) {
    if (_disposed) return;
    _state = next;
    notifyListeners();
  }

  /// Starts a new logical create from the current visible draft.
  ///
  /// While an outcome is unknown this method deliberately does nothing: only
  /// [retryUnknownOutcome] may continue that logical operation.
  Future<MealLogEntry?> submit(QuickAddManualCreateDraft draft) async {
    if (_state.isSubmitting || _state.isOutcomeUnknown) return null;

    final ManualMealLogCreate input;
    try {
      input = _buildInput(
        draft,
        clientMutationId: _mutationIdFactory(),
      );
    } on _QuickAddCreateValidationException catch (error) {
      _emit(
        QuickAddManualCreateState(
          status: QuickAddManualCreateStatus.failed,
          errorMessage: error.message,
        ),
      );
      return null;
    }

    return _perform(input);
  }

  /// Reconciles the exact logical create whose previous outcome was ambiguous.
  Future<MealLogEntry?> retryUnknownOutcome() async {
    if (_state.isSubmitting) return null;
    final input = _unknownOutcomeInput;
    if (!_state.isOutcomeUnknown || input == null) return null;
    return _perform(input);
  }

  ManualMealLogCreate _buildInput(
    QuickAddManualCreateDraft draft, {
    required String clientMutationId,
  }) {
    final categoryId = draft.mealCategoryId.trim();
    if (categoryId.isEmpty) {
      throw const _QuickAddCreateValidationException(
        missingMealCategoryMessage,
      );
    }

    final calories = _requiredAmount(
      label: 'Calories',
      text: draft.caloriesText,
    );
    final carbs = _optionalAmount(label: 'Carbs', text: draft.carbsText);
    final protein = _optionalAmount(
      label: 'Protein',
      text: draft.proteinText,
    );
    final fat = _optionalAmount(label: 'Fat', text: draft.fatText);

    final localConsumed = draft.consumedLocalDateTime;
    if (localConsumed.isAfter(_clock())) {
      throw const _QuickAddCreateValidationException(futureMealMessage);
    }

    final nutrients = <NutrientId, num>{
      NutrientId.energy: calories,
      if (carbs != null) NutrientId.carbohydrate: carbs,
      if (protein != null) NutrientId.protein: protein,
      if (fat != null) NutrientId.fat: fat,
    };

    return ManualMealLogCreate(
      clientMutationId: clientMutationId,
      mealCategoryId: categoryId,
      mealName: draft.mealName,
      note: null,
      consumedAt: localConsumed.toUtc(),
      consumedLocalDate: MealLogLocalDate(
        year: localConsumed.year,
        month: localConsumed.month,
        day: localConsumed.day,
      ),
      // Dart exposes the exact offset for this local DateTime. It does not
      // expose a trustworthy IANA zone identity, so none is fabricated.
      consumedUtcOffsetMinutes: localConsumed.timeZoneOffset.inMinutes,
      captureSource: MealLogCaptureSource.quickAdd,
      manualNutritionSnapshot: NutritionSnapshot(
        schemaVersion: 1,
        nutrients: nutrients,
      ),
    );
  }

  Future<MealLogEntry?> _perform(ManualMealLogCreate input) async {
    _emit(
      const QuickAddManualCreateState(
        status: QuickAddManualCreateStatus.submitting,
      ),
    );

    try {
      final created = await _repository.createManual(input);
      _unknownOutcomeInput = null;
      _emit(
        QuickAddManualCreateState(
          status: QuickAddManualCreateStatus.succeeded,
          createdEntry: created,
        ),
      );
      return created;
    } on MealLogCreateOutcomeUnknown catch (error) {
      // The repository must report the same id it was asked to reconcile. If
      // it does not, fail closed instead of preserving the wrong operation.
      if (error.clientMutationId != input.clientMutationId) {
        _unknownOutcomeInput = null;
        _emit(
          const QuickAddManualCreateState(
            status: QuickAddManualCreateStatus.failed,
            errorMessage: genericFailureMessage,
          ),
        );
        return null;
      }
      _unknownOutcomeInput = input;
      _emit(
        const QuickAddManualCreateState(
          status: QuickAddManualCreateStatus.outcomeUnknown,
          errorMessage: outcomeUnknownMessage,
        ),
      );
      return null;
    } catch (_) {
      _unknownOutcomeInput = null;
      _emit(
        const QuickAddManualCreateState(
          status: QuickAddManualCreateStatus.failed,
          errorMessage: genericFailureMessage,
        ),
      );
      return null;
    }
  }

  num _requiredAmount({required String label, required String text}) {
    if (text.trim().isEmpty) {
      throw const _QuickAddCreateValidationException(missingCaloriesMessage);
    }
    return _validatedAmount(label: label, text: text);
  }

  num? _optionalAmount({required String label, required String text}) {
    if (text.trim().isEmpty) return null;
    return _validatedAmount(label: label, text: text);
  }

  num _validatedAmount({required String label, required String text}) {
    final error = quickAddNutritionValueError(label: label, text: text);
    if (error != null) throw _QuickAddCreateValidationException(error);
    return double.parse(text.trim());
  }
}

final class _QuickAddCreateValidationException implements Exception {
  const _QuickAddCreateValidationException(this.message);

  final String message;
}
