import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:tio_feature_nutrition/nutrition.dart';
import 'package:tio_shared/shared.dart';

import 'package:tio_feature_nutrition/src/meal_logging/presentation/controllers/quick_add_manual_create_controller.dart';

void main() {
  const firstMutationId = '11111111-1111-4111-8111-111111111111';
  const secondMutationId = '22222222-2222-4222-8222-222222222222';

  QuickAddManualCreateDraft draft({
    String mealCategoryId = 'meal_slot_2',
    String mealName = 'Dal and roti',
    String calories = '420',
    String carbs = '55',
    String protein = '24.5',
    String fat = '',
    DateTime? consumedLocal,
  }) {
    return QuickAddManualCreateDraft(
      mealCategoryId: mealCategoryId,
      mealName: mealName,
      caloriesText: calories,
      carbsText: carbs,
      proteinText: protein,
      fatText: fat,
      consumedLocalDateTime:
          consumedLocal ?? DateTime(2026, 9, 12, 10, 15),
    );
  }

  test('validity requires calories and category while blank macros stay valid',
      () {
    expect(canSubmitDraft(draft()), isTrue);
    expect(canSubmitDraft(draft(calories: '')), isFalse);
    expect(canSubmitDraft(draft(mealCategoryId: '')), isFalse);
    expect(canSubmitDraft(draft(carbs: '', protein: '', fat: '')), isTrue);
    expect(canSubmitDraft(draft(protein: '-1')), isFalse);
    expect(canSubmitDraft(draft(fat: '1e400')), isFalse);
  });

  test('submit maps the draft to canonical manual MealLog create facts',
      () async {
    final repository = _RecordingMealLogRepository();
    final local = DateTime(2026, 9, 12, 22, 35);
    final controller = QuickAddManualCreateController(
      repository: repository,
      clock: () => DateTime(2026, 9, 12, 22, 36),
      mutationIdFactory: () => firstMutationId,
    );
    addTearDown(controller.dispose);

    final created = await controller.submit(
      draft(
        mealName: '   ',
        carbs: '',
        protein: '0',
        fat: '13.5',
        consumedLocal: local,
      ),
    );

    expect(created, isNotNull);
    expect(repository.inputs, hasLength(1));
    final input = repository.inputs.single;
    expect(input.clientMutationId, firstMutationId);
    expect(input.mealCategoryId, 'meal_slot_2');
    expect(input.mealName, isNull);
    expect(input.note, isNull);
    expect(input.captureSource, MealLogCaptureSource.quickAdd);
    expect(input.consumedAt, local.toUtc());
    expect(
      input.consumedLocalDate,
      MealLogLocalDate(year: 2026, month: 9, day: 12),
    );
    expect(input.consumedTimezoneId, isNull);
    expect(input.consumedUtcOffsetMinutes, local.timeZoneOffset.inMinutes);
    final snapshot = input.manualNutritionSnapshot;
    expect(snapshot.amountFor(NutrientId.energy), 420);
    expect(snapshot.containsNutrient(NutrientId.carbohydrate), isFalse);
    expect(snapshot.amountFor(NutrientId.protein), 0);
    expect(snapshot.amountFor(NutrientId.fat), 13.5);
    expect(controller.state.status, QuickAddManualCreateStatus.succeeded);
  });

  test('future datetime fails before the repository is called', () async {
    final repository = _RecordingMealLogRepository();
    final controller = QuickAddManualCreateController(
      repository: repository,
      clock: () => DateTime(2026, 9, 12, 10),
      mutationIdFactory: () => firstMutationId,
    );
    addTearDown(controller.dispose);

    final created = await controller.submit(
      draft(consumedLocal: DateTime(2026, 9, 12, 10, 1)),
    );

    expect(created, isNull);
    expect(repository.inputs, isEmpty);
    expect(controller.state.status, QuickAddManualCreateStatus.failed);
    expect(
      controller.state.errorMessage,
      QuickAddManualCreateController.futureMealMessage,
    );
  });

  test('pending submit suppresses a rapid duplicate action', () async {
    final gate = Completer<MealLogEntry>();
    final repository = _RecordingMealLogRepository(
      onCreate: (_) => gate.future,
    );
    var mutationCalls = 0;
    final controller = QuickAddManualCreateController(
      repository: repository,
      clock: () => DateTime(2026, 9, 12, 10, 30),
      mutationIdFactory: () {
        mutationCalls++;
        return mutationCalls == 1 ? firstMutationId : secondMutationId;
      },
    );
    addTearDown(controller.dispose);

    final first = controller.submit(draft());
    await Future<void>.delayed(Duration.zero);
    expect(controller.state.isSubmitting, isTrue);

    final duplicate = await controller.submit(draft());
    expect(duplicate, isNull);
    expect(repository.inputs, hasLength(1));
    expect(mutationCalls, 1);

    gate.complete(_entryFor(repository.inputs.single));
    await first;
    expect(controller.state.status, QuickAddManualCreateStatus.succeeded);
  });

  test('unknown outcome freezes input and retries the same mutation identity',
      () async {
    var attempt = 0;
    final repository = _RecordingMealLogRepository(
      onCreate: (input) async {
        attempt++;
        if (attempt == 1) {
          throw MealLogCreateOutcomeUnknown(
            clientMutationId: input.clientMutationId,
          );
        }
        return _entryFor(input);
      },
    );
    var mutationCalls = 0;
    final controller = QuickAddManualCreateController(
      repository: repository,
      clock: () => DateTime(2026, 9, 12, 10, 30),
      mutationIdFactory: () {
        mutationCalls++;
        return mutationCalls == 1 ? firstMutationId : secondMutationId;
      },
    );
    addTearDown(controller.dispose);

    expect(await controller.submit(draft()), isNull);
    expect(controller.state.isOutcomeUnknown, isTrue);
    expect(repository.inputs, hasLength(1));

    // A changed visible draft cannot start a second logical create while the
    // first outcome is unknown.
    expect(
      await controller.submit(draft(calories: '999')),
      isNull,
    );
    expect(repository.inputs, hasLength(1));
    expect(mutationCalls, 1);

    final reconciled = await controller.retryUnknownOutcome();
    expect(reconciled, isNotNull);
    expect(repository.inputs, hasLength(2));
    expect(repository.inputs[1], same(repository.inputs[0]));
    expect(repository.inputs[1].clientMutationId, firstMutationId);
    expect(mutationCalls, 1);
    expect(controller.state.status, QuickAddManualCreateStatus.succeeded);
  });
}

final class _RecordingMealLogRepository implements MealLogRepository {
  _RecordingMealLogRepository({this.onCreate});

  final Future<MealLogEntry> Function(ManualMealLogCreate input)? onCreate;
  final List<ManualMealLogCreate> inputs = [];

  @override
  Future<MealLogEntry> createManual(ManualMealLogCreate input) async {
    inputs.add(input);
    final callback = onCreate;
    if (callback != null) return callback(input);
    return _entryFor(input);
  }

  @override
  Future<MealLogEntry?> readById(String id) async => null;

  @override
  Future<List<MealLogEntry>> listByLocalDate(
    MealLogLocalDate localDate,
  ) async =>
      const [];
}

MealLogEntry _entryFor(ManualMealLogCreate input) {
  final storedAt = DateTime.utc(2026, 9, 12, 5);
  return MealLogEntry.manual(
    id: '00000000-0000-4000-8000-000000000001',
    userId: '00000000-0000-4000-8000-000000000002',
    mealCategoryId: input.mealCategoryId,
    mealName: input.mealName,
    note: input.note,
    consumedAt: input.consumedAt,
    consumedLocalDate: input.consumedLocalDate,
    consumedTimezoneId: input.consumedTimezoneId,
    consumedUtcOffsetMinutes: input.consumedUtcOffsetMinutes,
    captureSource: input.captureSource,
    manualNutritionSnapshot: input.manualNutritionSnapshot,
    createdAt: storedAt,
    updatedAt: storedAt,
  );
}
