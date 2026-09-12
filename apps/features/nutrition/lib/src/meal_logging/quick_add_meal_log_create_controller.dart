import 'package:flutter/foundation.dart';
import 'package:tio_shared/shared.dart';
import 'package:uuid/uuid.dart';

import '../domain/repositories/meal_log_repository.dart';

enum QuickAddMealLogCreateStatus {
  idle,
  submitting,
  failed,
  outcomeUnknown,
  succeeded,
}

@immutable
final class QuickAddMealLogDraft {
  const QuickAddMealLogDraft({
    required this.mealCategoryId,
    required this.consumedLocalDateTime,
    required this.caloriesKcal,
    this.mealName,
    this.carbohydrateGrams,
    this.proteinGrams,
    this.fatGrams,
  });

  final String mealCategoryId;
  final String? mealName;
  final DateTime consumedLocalDateTime;
  final num caloriesKcal;
  final num? carbohydrateGrams;
  final num? proteinGrams;
  final num? fatGrams;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is QuickAddMealLogDraft &&
          other.mealCategoryId == mealCategoryId &&
          other.mealName == mealName &&
          other.consumedLocalDateTime == consumedLocalDateTime &&
          other.caloriesKcal == caloriesKcal &&
          other.carbohydrateGrams == carbohydrateGrams &&
          other.proteinGrams == proteinGrams &&
          other.fatGrams == fatGrams;

  @override
  int get hashCode => Object.hash(
        mealCategoryId,
        mealName,
        consumedLocalDateTime,
        caloriesKcal,
        carbohydrateGrams,
        proteinGrams,
        fatGrams,
      );
}

@immutable
final class QuickAddMealLogCreateState {
  const QuickAddMealLogCreateState._({
    required this.status,
    this.message,
    this.entry,
  });

  const QuickAddMealLogCreateState.idle()
      : this._(status: QuickAddMealLogCreateStatus.idle);

  final QuickAddMealLogCreateStatus status;
  final String? message;
  final MealLogEntry? entry;

  bool get isSubmitting => status == QuickAddMealLogCreateStatus.submitting;
  bool get isOutcomeUnknown =>
      status == QuickAddMealLogCreateStatus.outcomeUnknown;
  bool get locksDraft => isSubmitting || isOutcomeUnknown;
}

/// Owns one Quick Add manual-create operation and its retry identity.
///
/// The editor owns the mutable route-local draft. This controller sees only an
/// immutable snapshot at submit time and is responsible for validating and
/// turning it into the canonical persistence input. A retry of the same logical
/// operation reuses the same mutation UUID; an ambiguous outcome additionally
/// freezes the exact payload until the repository can reconcile it.
final class QuickAddMealLogCreateController extends ChangeNotifier {
  QuickAddMealLogCreateController({
    required MealLogRepository repository,
    DateTime Function()? clock,
    String Function()? uuidV4,
  })  : _repository = repository,
        _clock = clock ?? DateTime.now,
        _uuidV4 = uuidV4 ?? _defaultUuidV4;

  static const String futureMealMessage = 'Meal time cannot be in the future.';
  static const String invalidMealMessage =
      'Review the meal details and try again.';
  static const String genericFailureMessage = "Couldn't log meal. Try again.";
  static const String outcomeUnknownMessage =
      'Save status is uncertain. Retry to check this same meal.';

  final MealLogRepository _repository;
  final DateTime Function() _clock;
  final String Function() _uuidV4;

  QuickAddMealLogCreateState _state = const QuickAddMealLogCreateState.idle();
  QuickAddMealLogCreateState get state => _state;

  QuickAddMealLogDraft? _retryDraft;
  ManualMealLogCreate? _retryInput;
  bool _disposed = false;

  static String _defaultUuidV4() => const Uuid().v4();

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  /// A known failure did not leave an unresolved durable outcome. Once the
  /// reader changes any submit-relevant fact, that old operation is no longer
  /// the logical operation they intend to send, so its retry identity must not
  /// follow the edited draft.
  ///
  /// An ambiguous outcome is intentionally different: the draft is locked by
  /// the presentation and this method does nothing until the exact frozen
  /// operation is reconciled.
  void draftChanged() {
    if (_state.status != QuickAddMealLogCreateStatus.failed) return;
    _retryDraft = null;
    _retryInput = null;
    _setState(const QuickAddMealLogCreateState.idle());
  }

  Future<MealLogEntry?> submit(QuickAddMealLogDraft draft) async {
    if (_state.isSubmitting) return null;

    ManualMealLogCreate input;
    final frozenInput = _retryInput;
    final frozenDraft = _retryDraft;

    if (_state.isOutcomeUnknown && frozenInput != null) {
      // The server may already have committed this exact operation. Until it is
      // reconciled, accepting a changed payload/new key could create a second
      // actual meal, so the ambiguous input remains authoritative.
      input = frozenInput;
    } else {
      final validationMessage = _validateDraft(draft);
      if (validationMessage != null) {
        _retryDraft = null;
        _retryInput = null;
        _setState(
          QuickAddMealLogCreateState._(
            status: QuickAddMealLogCreateStatus.failed,
            message: validationMessage,
          ),
        );
        return null;
      }

      final now = _minuteOnly(_clock());
      if (draft.consumedLocalDateTime.isAfter(now)) {
        _retryDraft = null;
        _retryInput = null;
        _setState(
          const QuickAddMealLogCreateState._(
            status: QuickAddMealLogCreateStatus.failed,
            message: futureMealMessage,
          ),
        );
        return null;
      }

      if (_state.status == QuickAddMealLogCreateStatus.failed &&
          frozenDraft == draft &&
          frozenInput != null) {
        input = frozenInput;
      } else {
        try {
          input = _buildInput(draft, clientMutationId: _uuidV4());
        } on ArgumentError {
          _retryDraft = null;
          _retryInput = null;
          _setState(
            const QuickAddMealLogCreateState._(
              status: QuickAddMealLogCreateStatus.failed,
              message: invalidMealMessage,
            ),
          );
          return null;
        }
        _retryDraft = draft;
        _retryInput = input;
      }
    }

    _setState(
      const QuickAddMealLogCreateState._(
        status: QuickAddMealLogCreateStatus.submitting,
      ),
    );

    try {
      final entry = await _repository.createManual(input);
      _retryDraft = null;
      _retryInput = null;
      _setState(
        QuickAddMealLogCreateState._(
          status: QuickAddMealLogCreateStatus.succeeded,
          entry: entry,
        ),
      );
      return entry;
    } on MealLogCreateOutcomeUnknown {
      // Any ambiguous repository result means this exact create may already be
      // durable. Keep the original frozen input authoritative even if a broken
      // adapter reports inconsistent error metadata; unlocking here would let
      // the UI mint a second logical create before the first is reconciled.
      _setState(
        const QuickAddMealLogCreateState._(
          status: QuickAddMealLogCreateStatus.outcomeUnknown,
          message: outcomeUnknownMessage,
        ),
      );
      return null;
    } on StateError {
      _setState(
        const QuickAddMealLogCreateState._(
          status: QuickAddMealLogCreateStatus.failed,
          message: 'Please sign in and try again.',
        ),
      );
      return null;
    } on ArgumentError {
      _setState(
        const QuickAddMealLogCreateState._(
          status: QuickAddMealLogCreateStatus.failed,
          message: invalidMealMessage,
        ),
      );
      return null;
    } on Object {
      _setState(
        const QuickAddMealLogCreateState._(
          status: QuickAddMealLogCreateStatus.failed,
          message: genericFailureMessage,
        ),
      );
      return null;
    }
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

  ManualMealLogCreate _buildInput(
    QuickAddMealLogDraft draft, {
    required String clientMutationId,
  }) {
    final nutrients = <NutrientId, num>{
      NutrientId.energy: draft.caloriesKcal,
      if (draft.carbohydrateGrams != null)
        NutrientId.carbohydrate: draft.carbohydrateGrams!,
      if (draft.proteinGrams != null) NutrientId.protein: draft.proteinGrams!,
      if (draft.fatGrams != null) NutrientId.fat: draft.fatGrams!,
    };
    final local = draft.consumedLocalDateTime;

    return ManualMealLogCreate(
      clientMutationId: clientMutationId,
      mealCategoryId: draft.mealCategoryId,
      mealName: draft.mealName,
      note: null,
      consumedAt: local.toUtc(),
      consumedLocalDate: MealLogLocalDate(
        year: local.year,
        month: local.month,
        day: local.day,
      ),
      // Dart exposes the exact offset for this local DateTime. It does not
      // expose a trustworthy IANA zone identity, so none is fabricated.
      consumedUtcOffsetMinutes: local.timeZoneOffset.inMinutes,
      captureSource: MealLogCaptureSource.quickAdd,
      manualNutritionSnapshot: NutritionSnapshot(
        schemaVersion: 1,
        nutrients: nutrients,
      ),
    );
  }

  DateTime _minuteOnly(DateTime value) => DateTime(
        value.year,
        value.month,
        value.day,
        value.hour,
        value.minute,
      );

  void _setState(QuickAddMealLogCreateState next) {
    if (_disposed) return;
    _state = next;
    notifyListeners();
  }
}
