import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:tio_feature_nutrition/nutrition.dart';
import 'package:tio_shared/shared.dart';

void main() {
  final localNow = DateTime(2026, 9, 12, 10, 30);
  final draft = QuickAddMealLogDraft(
    mealCategoryId: 'meal_slot_2',
    mealName: 'Dal and roti',
    consumedLocalDateTime: DateTime(2026, 9, 12, 9, 15),
    caloriesKcal: 420,
    carbohydrateGrams: 58,
    proteinGrams: 24,
    fatGrams: 11,
  );

  test('maps one valid Quick Add draft to canonical manual create facts',
      () async {
    final repository = _RecordingMealLogRepository();
    final controller = QuickAddMealLogCreateController(
      repository: repository,
      clock: () => localNow,
      uuidV4: () => '11111111-1111-4111-8111-111111111111',
    );

    final entry = await controller.submit(draft);

    expect(entry, isNotNull);
    expect(repository.inputs, hasLength(1));
    final input = repository.inputs.single;
    expect(input.clientMutationId, '11111111-1111-4111-8111-111111111111');
    expect(input.mealCategoryId, 'meal_slot_2');
    expect(input.mealName, 'Dal and roti');
    expect(input.note, isNull);
    expect(input.captureSource, MealLogCaptureSource.quickAdd);
    expect(input.consumedAt, draft.consumedLocalDateTime.toUtc());
    expect(
      input.consumedLocalDate,
      MealLogLocalDate(year: 2026, month: 9, day: 12),
    );
    expect(
      input.consumedUtcOffsetMinutes,
      draft.consumedLocalDateTime.timeZoneOffset.inMinutes,
    );
    expect(input.consumedTimezoneId, isNull);
    expect(input.manualNutritionSnapshot.amountFor(NutrientId.energy), 420);
    expect(
      input.manualNutritionSnapshot.amountFor(NutrientId.carbohydrate),
      58,
    );
    expect(input.manualNutritionSnapshot.amountFor(NutrientId.protein), 24);
    expect(input.manualNutritionSnapshot.amountFor(NutrientId.fat), 11);
    expect(controller.state.status, QuickAddMealLogCreateStatus.succeeded);
  });

  test('blank optional values remain absent rather than becoming zero',
      () async {
    final repository = _RecordingMealLogRepository();
    final controller = QuickAddMealLogCreateController(
      repository: repository,
      clock: () => localNow,
      uuidV4: () => '22222222-2222-4222-8222-222222222222',
    );

    await controller.submit(
      QuickAddMealLogDraft(
        mealCategoryId: 'meal_slot_1',
        mealName: '   ',
        consumedLocalDateTime: DateTime(2026, 9, 12, 8),
        caloriesKcal: 300,
      ),
    );

    final input = repository.inputs.single;
    expect(input.mealName, isNull);
    expect(input.manualNutritionSnapshot.containsNutrient(NutrientId.energy),
        isTrue);
    expect(
      input.manualNutritionSnapshot
          .containsNutrient(NutrientId.carbohydrate),
      isFalse,
    );
    expect(input.manualNutritionSnapshot.containsNutrient(NutrientId.protein),
        isFalse);
    expect(input.manualNutritionSnapshot.containsNutrient(NutrientId.fat),
        isFalse);
  });

  test('ambiguous outcome retries the exact frozen payload and mutation id',
      () async {
    var uuidCalls = 0;
    final repository = _RecordingMealLogRepository(
      onCreate: (input, call) async {
        if (call == 1) {
          throw MealLogCreateOutcomeUnknown(
            clientMutationId: input.clientMutationId,
          );
        }
        return _entryFor(input);
      },
    );
    final controller = QuickAddMealLogCreateController(
      repository: repository,
      clock: () => localNow,
      uuidV4: () {
        uuidCalls++;
        return '33333333-3333-4333-8333-333333333333';
      },
    );

    expect(await controller.submit(draft), isNull);
    expect(controller.state.status, QuickAddMealLogCreateStatus.outcomeUnknown);
    expect(controller.state.locksDraft, isTrue);

    final reconciled = await controller.submit(
      QuickAddMealLogDraft(
        mealCategoryId: 'meal_slot_4',
        mealName: 'this changed draft must be ignored while unknown',
        consumedLocalDateTime: DateTime(2026, 9, 11, 18),
        caloriesKcal: 999,
      ),
    );

    expect(reconciled, isNotNull);
    expect(uuidCalls, 1);
    expect(repository.inputs, hasLength(2));
    expect(
      repository.inputs[1].clientMutationId,
      repository.inputs[0].clientMutationId,
    );
    expect(repository.inputs[1].mealCategoryId, repository.inputs[0].mealCategoryId);
    expect(repository.inputs[1].mealName, repository.inputs[0].mealName);
    expect(repository.inputs[1].consumedAt, repository.inputs[0].consumedAt);
    expect(
      repository.inputs[1].manualNutritionSnapshot,
      repository.inputs[0].manualNutritionSnapshot,
    );
  });

  test('editing after a known failure starts a new logical mutation', () async {
    var call = 0;
    final ids = <String>[
      '44444444-4444-4444-8444-444444444444',
      '55555555-5555-4555-8555-555555555555',
    ];
    final repository = _RecordingMealLogRepository(
      onCreate: (input, _) async {
        call++;
        if (call == 1) throw Exception('known rejection');
        return _entryFor(input);
      },
    );
    final controller = QuickAddMealLogCreateController(
      repository: repository,
      clock: () => localNow,
      uuidV4: () => ids.removeAt(0),
    );

    expect(await controller.submit(draft), isNull);
    expect(controller.state.status, QuickAddMealLogCreateStatus.failed);

    controller.draftChanged();
    final changed = QuickAddMealLogDraft(
      mealCategoryId: draft.mealCategoryId,
      mealName: 'Changed meal',
      consumedLocalDateTime: draft.consumedLocalDateTime,
      caloriesKcal: draft.caloriesKcal,
    );
    expect(await controller.submit(changed), isNotNull);

    expect(repository.inputs, hasLength(2));
    expect(repository.inputs[0].clientMutationId,
        '44444444-4444-4444-8444-444444444444');
    expect(repository.inputs[1].clientMutationId,
        '55555555-5555-4555-8555-555555555555');
  });

  test('rapid duplicate submit is ignored while the first call is pending',
      () async {
    final pending = Completer<MealLogEntry>();
    final repository = _RecordingMealLogRepository(
      onCreate: (input, _) => pending.future,
    );
    final controller = QuickAddMealLogCreateController(
      repository: repository,
      clock: () => localNow,
      uuidV4: () => '66666666-6666-4666-8666-666666666666',
    );

    final first = controller.submit(draft);
    final second = controller.submit(draft);
    await Future<void>.delayed(Duration.zero);

    expect(repository.inputs, hasLength(1));
    expect(controller.state.isSubmitting, isTrue);
    expect(await second, isNull);

    pending.complete(_entryFor(repository.inputs.single));
    expect(await first, isNotNull);
  });

  test('future consumed datetime is rejected before repository access',
      () async {
    final repository = _RecordingMealLogRepository();
    final controller = QuickAddMealLogCreateController(
      repository: repository,
      clock: () => localNow,
      uuidV4: () => '77777777-7777-4777-8777-777777777777',
    );

    final result = await controller.submit(
      QuickAddMealLogDraft(
        mealCategoryId: 'meal_slot_1',
        consumedLocalDateTime: DateTime(2026, 9, 12, 10, 31),
        caloriesKcal: 100,
      ),
    );

    expect(result, isNull);
    expect(repository.inputs, isEmpty);
    expect(controller.state.status, QuickAddMealLogCreateStatus.failed);
    expect(controller.state.message, 'Meal time cannot be in the future.');
  });
}

typedef _CreateBehavior = Future<MealLogEntry> Function(
  ManualMealLogCreate input,
  int call,
);

final class _RecordingMealLogRepository implements MealLogRepository {
  _RecordingMealLogRepository({_CreateBehavior? onCreate})
      : _onCreate = onCreate;

  final _CreateBehavior? _onCreate;
  final inputs = <ManualMealLogCreate>[];

  @override
  Future<MealLogEntry> createManual(ManualMealLogCreate input) async {
    inputs.add(input);
    final behavior = _onCreate;
    if (behavior != null) return behavior(input, inputs.length);
    return _entryFor(input);
  }

  @override
  Future<List<MealLogEntry>> listByLocalDate(MealLogLocalDate localDate) async =>
      const [];

  @override
  Future<MealLogEntry?> readById(String id) async => null;
}

MealLogEntry _entryFor(ManualMealLogCreate input) {
  final now = DateTime.utc(2026, 9, 12, 5);
  return MealLogEntry.manual(
    id: 'entry-${input.clientMutationId}',
    userId: 'user-1',
    mealCategoryId: input.mealCategoryId,
    mealName: input.mealName,
    note: input.note,
    consumedAt: input.consumedAt,
    consumedLocalDate: input.consumedLocalDate,
    consumedTimezoneId: input.consumedTimezoneId,
    consumedUtcOffsetMinutes: input.consumedUtcOffsetMinutes,
    captureSource: input.captureSource,
    manualNutritionSnapshot: input.manualNutritionSnapshot,
    createdAt: now,
    updatedAt: now,
  );
}
