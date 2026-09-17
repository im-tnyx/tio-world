import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:tio_feature_nutrition/nutrition.dart';
import 'package:tio_shared/shared.dart';

void main() {
  const mutationId = '11111111-1111-4111-8111-111111111111';
  final context = MealEditorDetailedCreateContext(
    mealCategoryId: 'lunch',
    consumedLocalDateTime: DateTime(2026, 9, 17, 13, 15),
  );

  test('maps a complete draft and returns canonical repository result', () async {
    final repository = _RecordingRepository();
    final controller = MealEditorDetailedCreateController(
      repository: repository,
      uuidV4: () => mutationId,
    );

    final result = await controller.submit(
      draft: _completeDraft(),
      context: context,
    );

    expect(result, same(repository.result));
    expect(controller.state.status, MealEditorDetailedCreateStatus.succeeded);
    expect(repository.inputs, hasLength(1));
    final input = repository.inputs.single;
    expect(input.clientMutationId, mutationId);
    expect(input.mealCategoryId, 'lunch');
    expect(input.mealName, 'Roti and curd');
    expect(input.captureSource, MealLogCaptureSource.text);
    expect(input.items, hasLength(2));
    expect(input.items.first.displayName, 'Roti');
    expect(input.items.first.quantity, 2);
    expect(input.items.first.servingUnit, 'piece');
    expect(input.items.first.nutritionSnapshot.amountFor(NutrientId.energy), 200);
  });

  test('retry after known failure keeps the same mutation id for unchanged draft',
      () async {
    final repository = _RecordingRepository(failuresBeforeSuccess: 1);
    final controller = MealEditorDetailedCreateController(
      repository: repository,
      uuidV4: () => mutationId,
    );
    final draft = _completeDraft();

    expect(await controller.submit(draft: draft, context: context), isNull);
    expect(controller.state.status, MealEditorDetailedCreateStatus.failed);
    final result = await controller.submit(draft: draft, context: context);

    expect(result, same(repository.result));
    expect(repository.inputs, hasLength(2));
    expect(repository.inputs[0].clientMutationId, mutationId);
    expect(repository.inputs[1].clientMutationId, mutationId);
  });

  test('editing after known failure starts a new logical mutation', () async {
    final ids = <String>[
      '11111111-1111-4111-8111-111111111111',
      '22222222-2222-4222-8222-222222222222',
    ];
    final repository = _RecordingRepository(failuresBeforeSuccess: 1);
    final controller = MealEditorDetailedCreateController(
      repository: repository,
      uuidV4: () => ids.removeAt(0),
    );

    expect(
      await controller.submit(draft: _completeDraft(), context: context),
      isNull,
    );
    controller.draftChanged();
    final edited = MealLoggingDraft(
      mealName: 'Edited meal',
      captureSource: MealLogCaptureSource.text,
      items: _completeDraft().items,
    );
    await controller.submit(draft: edited, context: context);

    expect(repository.inputs[0].clientMutationId,
        '11111111-1111-4111-8111-111111111111');
    expect(repository.inputs[1].clientMutationId,
        '22222222-2222-4222-8222-222222222222');
  });

  test('ambiguous outcome freezes the same payload and mutation identity', () async {
    final repository = _RecordingRepository(outcomeUnknownBeforeSuccess: 1);
    final controller = MealEditorDetailedCreateController(
      repository: repository,
      uuidV4: () => mutationId,
    );
    final draft = _completeDraft();

    expect(await controller.submit(draft: draft, context: context), isNull);
    expect(controller.state.status, MealEditorDetailedCreateStatus.outcomeUnknown);
    expect(
      controller.canSubmit(draft: draft, context: context),
      isFalse,
    );

    final result = await controller.submit(draft: draft, context: context);
    expect(result, same(repository.result));
    expect(repository.inputs, hasLength(2));
    expect(repository.inputs[1].clientMutationId, mutationId);
  });

  test('second submit while in flight is ignored', () async {
    final repository = _BlockingRepository();
    final controller = MealEditorDetailedCreateController(
      repository: repository,
      uuidV4: () => mutationId,
    );
    final draft = _completeDraft();

    final first = controller.submit(draft: draft, context: context);
    await Future<void>.delayed(Duration.zero);
    final second = await controller.submit(draft: draft, context: context);

    expect(second, isNull);
    expect(repository.inputs, hasLength(1));
    repository.complete();
    await first;
  });

  test('incomplete item disables submission and never calls repository', () async {
    final repository = _RecordingRepository();
    final controller = MealEditorDetailedCreateController(
      repository: repository,
      uuidV4: () => mutationId,
    );
    final draft = MealLoggingDraft(
      captureSource: MealLogCaptureSource.text,
      items: [
        MealLoggingDraftItem(
          displayName: 'Dal',
          consumedNutritionSnapshot: NutritionSnapshot(
            schemaVersion: 1,
            nutrients: const {NutrientId.energy: 180},
          ),
        ),
      ],
    );

    expect(controller.canSubmit(draft: draft, context: context), isFalse);
    expect(await controller.submit(draft: draft, context: context), isNull);
    expect(repository.inputs, isEmpty);
    expect(controller.state.message,
        MealEditorDetailedCreateController.invalidMealMessage);
  });
}

class _RecordingRepository implements DetailedMealLogCreateRepository {
  _RecordingRepository({
    this.failuresBeforeSuccess = 0,
    this.outcomeUnknownBeforeSuccess = 0,
  });

  int failuresBeforeSuccess;
  int outcomeUnknownBeforeSuccess;
  final inputs = <DetailedMealLogCreate>[];
  final result = _entry();

  @override
  Future<MealLogEntry> createDetailed(DetailedMealLogCreate input) async {
    inputs.add(input);
    if (outcomeUnknownBeforeSuccess > 0) {
      outcomeUnknownBeforeSuccess--;
      throw const MealLogCreateOutcomeUnknown(clientMutationId: 'ignored');
    }
    if (failuresBeforeSuccess > 0) {
      failuresBeforeSuccess--;
      throw Exception('network');
    }
    return result;
  }
}

class _BlockingRepository implements DetailedMealLogCreateRepository {
  final inputs = <DetailedMealLogCreate>[];
  final _completer = Completer<MealLogEntry>();

  @override
  Future<MealLogEntry> createDetailed(DetailedMealLogCreate input) {
    inputs.add(input);
    return _completer.future;
  }

  void complete() => _completer.complete(_entry());
}

MealLoggingDraft _completeDraft() => MealLoggingDraft(
      mealName: 'Roti and curd',
      captureSource: MealLogCaptureSource.text,
      items: [
        _item('Roti', 2, 'piece', 200),
        _item('Curd', 150, 'g', 90),
      ],
    );

MealLoggingDraftItem _item(String name, num quantity, String unit, num energy) =>
    MealLoggingDraftItem(
      displayName: name,
      quantity: quantity,
      servingUnit: unit,
      consumedNutritionSnapshot: NutritionSnapshot(
        schemaVersion: 1,
        nutrients: {
          NutrientId.energy: energy,
          NutrientId.protein: 5,
          NutrientId.carbohydrate: 10,
          NutrientId.fat: 3,
        },
      ),
    );

MealLogEntry _entry() => MealLogEntry.detailed(
      id: 'entry-id',
      userId: 'user-id',
      mealCategoryId: 'lunch',
      mealName: 'Roti and curd',
      consumedAt: DateTime.utc(2026, 9, 17, 7, 45),
      consumedLocalDate: MealLogLocalDate(year: 2026, month: 9, day: 17),
      consumedUtcOffsetMinutes: 330,
      captureSource: MealLogCaptureSource.text,
      detailedItems: [
        MealLogItemSnapshot(
          id: 'item-id',
          mealLogEntryId: 'entry-id',
          displayName: 'Roti',
          quantity: 2,
          servingUnit: 'piece',
          nutritionSnapshot: NutritionSnapshot(
            schemaVersion: 1,
            nutrients: const {NutrientId.energy: 200},
          ),
        ),
      ],
      createdAt: DateTime.utc(2026, 9, 17, 7, 46),
      updatedAt: DateTime.utc(2026, 9, 17, 7, 46),
    );
