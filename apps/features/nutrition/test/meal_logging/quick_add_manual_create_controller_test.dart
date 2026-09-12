import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:tio_feature_nutrition/nutrition.dart';
import 'package:tio_shared/shared.dart';

void main() {
  const firstMutationId = '11111111-1111-4111-8111-111111111111';
  const secondMutationId = '22222222-2222-4222-8222-222222222222';

  QuickAddMealLogDraft draft({
    String mealCategoryId = 'meal_slot_2',
    String? mealName = 'Dal and roti',
    num calories = 420,
    num? carbs = 55,
    num? protein = 24.5,
    num? fat,
    DateTime? consumedLocal,
  }) {
    return QuickAddMealLogDraft(
      mealCategoryId: mealCategoryId,
      mealName: mealName,
      caloriesKcal: calories,
      carbohydrateGrams: carbs,
      proteinGrams: protein,
      fatGrams: fat,
      consumedLocalDateTime:
          consumedLocal ?? DateTime(2026, 9, 12, 10, 15),
    );
  }

  test('submit maps the draft to canonical manual MealLog create facts',
      () async {
    final repository = _RecordingMealLogRepository();
    final local = DateTime(2026, 9, 12, 22, 35);
    final controller = QuickAddMealLogCreateController(
      repository: repository,
      clock: () => DateTime(2026, 9, 12, 22, 36),
      uuidV4: () => firstMutationId,
    );
    addTearDown(controller.dispose);

    final created = await controller.submit(
      draft(
        mealName: '   ',
        carbs: null,
        protein: 0,
        fat: 13.5,
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
    expect(controller.state.status, QuickAddMealLogCreateStatus.succeeded);
  });

  test('invalid canonical values fail closed before repository access',
      () async {
    final repository = _RecordingMealLogRepository();
    var mutationCalls = 0;
    final controller = QuickAddMealLogCreateController(
      repository: repository,
      clock: () => DateTime(2026, 9, 12, 10, 30),
      uuidV4: () {
        mutationCalls++;
        return firstMutationId;
      },
    );
    addTearDown(controller.dispose);

    for (final invalid in [
      draft(mealCategoryId: ''),
      draft(calories: -1),
      draft(calories: double.infinity),
      draft(protein: -1),
      draft(fat: double.nan),
    ]) {
      expect(await controller.submit(invalid), isNull);
      expect(controller.state.status, QuickAddMealLogCreateStatus.failed);
      expect(
        controller.state.message,
        QuickAddMealLogCreateController.invalidMealMessage,
      );
      controller.draftChanged();
    }

    expect(repository.inputs, isEmpty);
    expect(mutationCalls, 0);
  });

  test('future datetime fails before the repository is called', () async {
    final repository = _RecordingMealLogRepository();
    final controller = QuickAddMealLogCreateController(
      repository: repository,
      clock: () => DateTime(2026, 9, 12, 10),
      uuidV4: () => firstMutationId,
    );
    addTearDown(controller.dispose);

    final created = await controller.submit(
      draft(consumedLocal: DateTime(2026, 9, 12, 10, 1)),
    );

    expect(created, isNull);
    expect(repository.inputs, isEmpty);
    expect(controller.state.status, QuickAddMealLogCreateStatus.failed);
    expect(
      controller.state.message,
      QuickAddMealLogCreateController.futureMealMessage,
    );
  });

  test('pending submit suppresses a rapid duplicate action', () async {
    final gate = Completer<MealLogEntry>();
    final repository = _RecordingMealLogRepository(
      onCreate: (_) => gate.future,
    );
    var mutationCalls = 0;
    final controller = QuickAddMealLogCreateController(
      repository: repository,
      clock: () => DateTime(2026, 9, 12, 10, 30),
      uuidV4: () {
        mutationCalls++;
        return mutationCalls == 1 ? firstMutationId : secondMutationId;
      },
    );
    addTearDown(controller.dispose);

    final first = controller.submit(draft());
    await Future<void>.delayed(Duration.zero);
    expect(controller.state.isSubmitting, isTrue);
    expect(controller.state.locksDraft, isTrue);

    final duplicate = await controller.submit(draft());
    expect(duplicate, isNull);
    expect(repository.inputs, hasLength(1));
    expect(mutationCalls, 1);

    gate.complete(_entryFor(repository.inputs.single));
    await first;
    expect(controller.state.status, QuickAddMealLogCreateStatus.succeeded);
  });

  test('known failure retries unchanged draft with the same mutation identity',
      () async {
    var attempts = 0;
    final repository = _RecordingMealLogRepository(
      onCreate: (input) async {
        attempts++;
        if (attempts == 1) throw Exception('offline');
        return _entryFor(input);
      },
    );
    var mutationCalls = 0;
    final controller = QuickAddMealLogCreateController(
      repository: repository,
      clock: () => DateTime(2026, 9, 12, 10, 30),
      uuidV4: () {
        mutationCalls++;
        return mutationCalls == 1 ? firstMutationId : secondMutationId;
      },
    );
    addTearDown(controller.dispose);

    expect(await controller.submit(draft()), isNull);
    expect(controller.state.status, QuickAddMealLogCreateStatus.failed);
    expect(await controller.submit(draft()), isNotNull);

    expect(repository.inputs, hasLength(2));
    expect(repository.inputs[0].clientMutationId, firstMutationId);
    expect(repository.inputs[1].clientMutationId, firstMutationId);
    expect(mutationCalls, 1);
  });

  test('editing after a known failure starts a new logical mutation', () async {
    var attempts = 0;
    final repository = _RecordingMealLogRepository(
      onCreate: (input) async {
        attempts++;
        if (attempts == 1) throw Exception('offline');
        return _entryFor(input);
      },
    );
    var mutationCalls = 0;
    final controller = QuickAddMealLogCreateController(
      repository: repository,
      clock: () => DateTime(2026, 9, 12, 10, 30),
      uuidV4: () {
        mutationCalls++;
        return mutationCalls == 1 ? firstMutationId : secondMutationId;
      },
    );
    addTearDown(controller.dispose);

    expect(await controller.submit(draft()), isNull);
    controller.draftChanged();
    expect(controller.state.status, QuickAddMealLogCreateStatus.idle);

    expect(await controller.submit(draft(calories: 500)), isNotNull);
    expect(repository.inputs, hasLength(2));
    expect(repository.inputs[0].clientMutationId, firstMutationId);
    expect(repository.inputs[1].clientMutationId, secondMutationId);
  });

  test('unknown outcome freezes payload and retries the same mutation identity',
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
    final controller = QuickAddMealLogCreateController(
      repository: repository,
      clock: () => DateTime(2026, 9, 12, 10, 30),
      uuidV4: () {
        mutationCalls++;
        return mutationCalls == 1 ? firstMutationId : secondMutationId;
      },
    );
    addTearDown(controller.dispose);

    expect(await controller.submit(draft()), isNull);
    expect(controller.state.isOutcomeUnknown, isTrue);
    expect(controller.state.locksDraft, isTrue);
    expect(repository.inputs, hasLength(1));

    // Even if another caller supplies changed facts, the unresolved operation
    // remains authoritative until reconciliation succeeds.
    final reconciled = await controller.submit(draft(calories: 999));
    expect(reconciled, isNotNull);
    expect(repository.inputs, hasLength(2));
    expect(repository.inputs[1], same(repository.inputs[0]));
    expect(repository.inputs[1].clientMutationId, firstMutationId);
    expect(repository.inputs[1].manualNutritionSnapshot.amountFor(
      NutrientId.energy,
    ), 420);
    expect(mutationCalls, 1);
    expect(controller.state.status, QuickAddMealLogCreateStatus.succeeded);
  });

  test('mismatched unknown-outcome identity fails closed', () async {
    final repository = _RecordingMealLogRepository(
      onCreate: (input) async => throw const MealLogCreateOutcomeUnknown(
        clientMutationId: secondMutationId,
      ),
    );
    final controller = QuickAddMealLogCreateController(
      repository: repository,
      clock: () => DateTime(2026, 9, 12, 10, 30),
      uuidV4: () => firstMutationId,
    );
    addTearDown(controller.dispose);

    expect(await controller.submit(draft()), isNull);
    expect(controller.state.status, QuickAddMealLogCreateStatus.failed);
    expect(
      controller.state.message,
      QuickAddMealLogCreateController.genericFailureMessage,
    );
    expect(controller.state.locksDraft, isFalse);
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
