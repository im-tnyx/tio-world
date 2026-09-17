import 'package:flutter/foundation.dart';
import 'package:tio_shared/shared.dart';
import 'package:uuid/uuid.dart';

import '../domain/repositories/detailed_meal_log_create_repository.dart';

enum MealEditorDetailedCreateStatus {
  idle,
  submitting,
  failed,
  outcomeUnknown,
  succeeded,
}

@immutable
final class MealEditorDetailedCreateContext {
  const MealEditorDetailedCreateContext({
    required this.mealCategoryId,
    required this.consumedLocalDateTime,
  });

  final String mealCategoryId;
  final DateTime consumedLocalDateTime;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MealEditorDetailedCreateContext &&
          other.mealCategoryId == mealCategoryId &&
          other.consumedLocalDateTime == consumedLocalDateTime;

  @override
  int get hashCode => Object.hash(mealCategoryId, consumedLocalDateTime);
}

@immutable
final class MealEditorDetailedCreateState {
  const MealEditorDetailedCreateState._({
    required this.status,
    this.message,
    this.entry,
  });

  const MealEditorDetailedCreateState.idle()
      : this._(status: MealEditorDetailedCreateStatus.idle);

  final MealEditorDetailedCreateStatus status;
  final String? message;
  final MealLogEntry? entry;

  bool get isSubmitting => status == MealEditorDetailedCreateStatus.submitting;
  bool get isOutcomeUnknown =>
      status == MealEditorDetailedCreateStatus.outcomeUnknown;
  bool get locksDraft => isSubmitting || isOutcomeUnknown;
}

final class MealEditorDetailedCreateController extends ChangeNotifier {
  MealEditorDetailedCreateController({
    required DetailedMealLogCreateRepository repository,
    String Function()? uuidV4,
  })  : _repository = repository,
        _uuidV4 = uuidV4 ?? _defaultUuidV4;

  static const invalidMealMessage = 'Review the meal details and try again.';
  static const genericFailureMessage = "Couldn't log meal. Try again.";
  static const outcomeUnknownMessage =
      'Save status is uncertain. Retry to check this same meal.';

  final DetailedMealLogCreateRepository _repository;
  final String Function() _uuidV4;

  MealEditorDetailedCreateState _state =
      const MealEditorDetailedCreateState.idle();
  MealEditorDetailedCreateState get state => _state;

  _RetryDraft? _retryDraft;
  DetailedMealLogCreate? _retryInput;
  bool _disposed = false;

  static String _defaultUuidV4() => const Uuid().v4();

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  bool canSubmit({
    required MealLoggingDraft draft,
    required MealEditorDetailedCreateContext context,
  }) => _validateDraft(draft, context) == null && !_state.locksDraft;

  void draftChanged() {
    if (_state.status != MealEditorDetailedCreateStatus.failed) return;
    _retryDraft = null;
    _retryInput = null;
    _setState(const MealEditorDetailedCreateState.idle());
  }

  Future<MealLogEntry?> submit({
    required MealLoggingDraft draft,
    required MealEditorDetailedCreateContext context,
  }) async {
    if (_state.isSubmitting) return null;

    DetailedMealLogCreate input;
    final frozenInput = _retryInput;
    final frozenDraft = _retryDraft;

    if (_state.isOutcomeUnknown && frozenInput != null) {
      input = frozenInput;
    } else {
      final validationMessage = _validateDraft(draft, context);
      if (validationMessage != null) {
        _retryDraft = null;
        _retryInput = null;
        _setState(
          const MealEditorDetailedCreateState._(
            status: MealEditorDetailedCreateStatus.failed,
            message: invalidMealMessage,
          ),
        );
        return null;
      }

      final retryDraft = _RetryDraft(draft: draft, context: context);
      if (_state.status == MealEditorDetailedCreateStatus.failed &&
          frozenDraft == retryDraft &&
          frozenInput != null) {
        input = frozenInput;
      } else {
        try {
          input = _buildInput(
            draft,
            context,
            clientMutationId: _uuidV4(),
          );
        } on ArgumentError {
          _retryDraft = null;
          _retryInput = null;
          _setState(
            const MealEditorDetailedCreateState._(
              status: MealEditorDetailedCreateStatus.failed,
              message: invalidMealMessage,
            ),
          );
          return null;
        }
        _retryDraft = retryDraft;
        _retryInput = input;
      }
    }

    _setState(
      const MealEditorDetailedCreateState._(
        status: MealEditorDetailedCreateStatus.submitting,
      ),
    );

    try {
      final entry = await _repository.createDetailed(input);
      _retryDraft = null;
      _retryInput = null;
      _setState(
        MealEditorDetailedCreateState._(
          status: MealEditorDetailedCreateStatus.succeeded,
          entry: entry,
        ),
      );
      return entry;
    } on MealLogCreateOutcomeUnknown {
      _setState(
        const MealEditorDetailedCreateState._(
          status: MealEditorDetailedCreateStatus.outcomeUnknown,
          message: outcomeUnknownMessage,
        ),
      );
      return null;
    } on StateError {
      _setState(
        const MealEditorDetailedCreateState._(
          status: MealEditorDetailedCreateStatus.failed,
          message: 'Please sign in and try again.',
        ),
      );
      return null;
    } on ArgumentError {
      _setState(
        const MealEditorDetailedCreateState._(
          status: MealEditorDetailedCreateStatus.failed,
          message: invalidMealMessage,
        ),
      );
      return null;
    } on Object {
      _setState(
        const MealEditorDetailedCreateState._(
          status: MealEditorDetailedCreateStatus.failed,
          message: genericFailureMessage,
        ),
      );
      return null;
    }
  }

  String? _validateDraft(
    MealLoggingDraft draft,
    MealEditorDetailedCreateContext context,
  ) {
    if (context.mealCategoryId.trim().isEmpty || draft.items.isEmpty) {
      return invalidMealMessage;
    }
    for (final item in draft.items) {
      if (item.displayName.trim().isEmpty ||
          item.quantity == null ||
          !item.quantity!.isFinite ||
          item.quantity! <= 0 ||
          item.servingUnit == null ||
          item.servingUnit!.trim().isEmpty ||
          item.consumedNutritionSnapshot == null) {
        return invalidMealMessage;
      }
    }
    return null;
  }

  DetailedMealLogCreate _buildInput(
    MealLoggingDraft draft,
    MealEditorDetailedCreateContext context, {
    required String clientMutationId,
  }) {
    final local = context.consumedLocalDateTime;
    return DetailedMealLogCreate(
      clientMutationId: clientMutationId,
      mealCategoryId: context.mealCategoryId,
      mealName: draft.mealName,
      note: null,
      consumedAt: local.toUtc(),
      consumedLocalDate: MealLogLocalDate(
        year: local.year,
        month: local.month,
        day: local.day,
      ),
      consumedUtcOffsetMinutes: local.timeZoneOffset.inMinutes,
      captureSource: draft.captureSource,
      items: [
        for (final item in draft.items)
          DetailedMealLogCreateItem(
            displayName: item.displayName,
            quantity: item.quantity!,
            servingUnit: item.servingUnit!,
            nutritionSnapshot: item.consumedNutritionSnapshot!,
          ),
      ],
    );
  }

  void _setState(MealEditorDetailedCreateState next) {
    if (_disposed) return;
    _state = next;
    notifyListeners();
  }
}

@immutable
final class _RetryDraft {
  const _RetryDraft({required this.draft, required this.context});

  final MealLoggingDraft draft;
  final MealEditorDetailedCreateContext context;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _RetryDraft && other.draft == draft && other.context == context;

  @override
  int get hashCode => Object.hash(draft, context);
}
