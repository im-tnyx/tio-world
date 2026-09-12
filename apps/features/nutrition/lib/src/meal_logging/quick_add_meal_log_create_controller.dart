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
/// immutable snapshot at submit time and is responsible for turning it into the
/// canonical persistence input. A retry of the same logical operation reuses
/// the same mutation UUID; an ambiguous outcome additionally freezes the exact
/// payload until the repository can reconcile it.
final class QuickAddMealLogCreateController extends ChangeNotifier {
  QuickAddMealLogCreateController({
    required MealLogRepository repository,
    DateTime Function()? clock,
    String Function()? uuidV4,
  })  : _repository = repository,
        _clock = clock ?? DateTime.now,
        _uuidV4 = uuidV4 ?? _defaultUuidV4;

  final MealLogRepository _repository;
  final DateTime Function() _clock;
  final String Function() _uuidV4;

  QuickAddMealLogCreateState _state = const QuickAddMealLogCreateState.idle();
  QuickAddMealLogCreateState get state => _state;

  QuickAddMealLogDraft? _retryDraft;
  ManualMealLogCreate? _retryInput;

  static String _defaultUuidV4() => const Uuid().v4();

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
      final now = _minuteOnly(_clock());
      if (draft.consumedLocalDateTime.isAfter(now)) {
        _setState(
          const QuickAddMealLogCreateState._(
            status: QuickAddMealLogCreateStatus.failed,
            message: 'Meal time cannot be in the future.',
          ),
        );
        _retryDraft = null;
        _retryInput = null;
        return null;
      }

      if (_state.status == QuickAddMealLogCreateStatus.failed &&
          frozenDraft == draft &&
          frozenInput != null) {
        input = frozenInput;
      } else {
        input = _buildInput(draft, clientMutationId: _uuidV4());
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
      _setState(
        const QuickAddMealLogCreateState._(
          status: QuickAddMealLogCreateStatus.outcomeUnknown,
          message: 'Save status is uncertain. Retry to check this same meal.',
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
          message: 'Review the meal details and try again.',
        ),
      );
      return null;
    } on Object {
      _setState(
        const QuickAddMealLogCreateState._(
          status: QuickAddMealLogCreateStatus.failed,
          message: "Couldn't log meal. Try again.",
        ),
      );
      return null;
    }
  }

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
    _state = next;
    notifyListeners();
  }
}
