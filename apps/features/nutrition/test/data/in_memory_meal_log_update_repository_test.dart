import 'package:flutter_test/flutter_test.dart';
import 'package:tio_feature_nutrition/nutrition.dart';
import 'package:tio_shared/shared.dart';

const _mutation = '11111111-1111-4111-8111-111111111111';

void main() {
  test('manual update keeps identity/provenance and advances revision once',
      () async {
    var now = DateTime.utc(2026, 9, 12, 8);
    final categories = InMemoryMealCategoriesRepository();
    final repository = InMemoryMealLogRepository(
      mealCategoriesRepository: categories,
      clock: () => now,
      userId: 'owner-1',
    );
    final created = await repository.createManual(_createInput());

    expect(created.revision, 1);
    now = DateTime.utc(2026, 9, 12, 9);
    final updated = await repository.updateManual(
      _updateInput(
        id: created.id,
        expectedRevision: created.revision,
        mealName: 'Updated lunch',
        note: 'Less oil',
      ),
    );

    expect(updated.id, created.id);
    expect(updated.userId, created.userId);
    expect(updated.mode, MealLogMode.manual);
    expect(updated.captureSource, created.captureSource);
    expect(updated.createdAt, created.createdAt);
    expect(updated.updatedAt, now);
    expect(updated.revision, 2);
    expect(updated.mealName, 'Updated lunch');
    expect(updated.note, 'Less oil');
    expect(updated.manualNutritionSnapshot!.amountFor(NutrientId.energy), 510);
  });

  test('stale revision fails without overwriting the durable row', () async {
    final repository = InMemoryMealLogRepository(
      mealCategoriesRepository: InMemoryMealCategoriesRepository(),
    );
    final created = await repository.createManual(_createInput());
    final winner = await repository.updateManual(
      _updateInput(
        id: created.id,
        expectedRevision: 1,
        mealName: 'Winner',
      ),
    );

    await expectLater(
      () => repository.updateManual(
        _updateInput(
          id: created.id,
          expectedRevision: 1,
          mealName: 'Stale overwrite',
        ),
      ),
      throwsA(
        isA<MealLogUpdateConflict>()
            .having((error) => error.expectedRevision, 'expectedRevision', 1)
            .having((error) => error.actualRevision, 'actualRevision', 2),
      ),
    );

    final current = await repository.readById(created.id);
    expect(current!.mealName, winner.mealName);
    expect(current.revision, 2);
  });

  test('missing update target is distinct from stale conflict', () async {
    final repository = InMemoryMealLogRepository(
      mealCategoriesRepository: InMemoryMealCategoriesRepository(),
    );

    await expectLater(
      () => repository.updateManual(
        _updateInput(id: 'missing-row', expectedRevision: 1),
      ),
      throwsA(
        isA<MealLogUpdateNotFound>()
            .having((error) => error.id, 'id', 'missing-row'),
      ),
    );
  });

  test('retaining archived category is allowed during unrelated edit',
      () async {
    final categories = InMemoryMealCategoriesRepository();
    final repository = InMemoryMealLogRepository(
      mealCategoriesRepository: categories,
    );
    final created = await repository.createManual(_createInput());
    await _archiveCategory(categories, created.mealCategoryId);

    final updated = await repository.updateManual(
      _updateInput(
        id: created.id,
        expectedRevision: created.revision,
        mealCategoryId: created.mealCategoryId,
        mealName: 'Still historical category',
      ),
    );

    expect(updated.mealCategoryId, created.mealCategoryId);
    expect(updated.revision, 2);
  });

  test('moving to archived destination category is rejected', () async {
    final categories = InMemoryMealCategoriesRepository();
    final repository = InMemoryMealLogRepository(
      mealCategoriesRepository: categories,
    );
    final created = await repository.createManual(_createInput());
    await _archiveCategory(categories, 'meal_slot_2');

    await expectLater(
      () => repository.updateManual(
        _updateInput(
          id: created.id,
          expectedRevision: created.revision,
          mealCategoryId: 'meal_slot_2',
        ),
      ),
      throwsArgumentError,
    );

    expect((await repository.readById(created.id))!.revision, 1);
  });
}

ManualMealLogCreate _createInput() {
  return ManualMealLogCreate(
    clientMutationId: _mutation,
    mealCategoryId: 'meal_slot_1',
    mealName: 'Lunch',
    consumedAt: DateTime.utc(2026, 9, 12, 6, 30),
    consumedLocalDate: MealLogLocalDate(year: 2026, month: 9, day: 12),
    consumedUtcOffsetMinutes: 330,
    captureSource: MealLogCaptureSource.quickAdd,
    manualNutritionSnapshot: NutritionSnapshot(
      schemaVersion: 1,
      nutrients: {
        NutrientId.energy: 500,
        NutrientId.protein: 25,
      },
    ),
  );
}

ManualMealLogUpdate _updateInput({
  required String id,
  required int expectedRevision,
  String mealCategoryId = 'meal_slot_1',
  String? mealName = 'Lunch',
  String? note,
}) {
  return ManualMealLogUpdate(
    id: id,
    expectedRevision: expectedRevision,
    mealCategoryId: mealCategoryId,
    mealName: mealName,
    note: note,
    consumedAt: DateTime.utc(2026, 9, 12, 7),
    consumedLocalDate: MealLogLocalDate(year: 2026, month: 9, day: 12),
    consumedUtcOffsetMinutes: 330,
    manualNutritionSnapshot: NutritionSnapshot(
      schemaVersion: 1,
      nutrients: {
        NutrientId.energy: 510,
        NutrientId.protein: 26,
      },
    ),
  );
}

Future<void> _archiveCategory(
  InMemoryMealCategoriesRepository repository,
  String id,
) async {
  final current = await repository.read();
  await repository.upsert(
    MealCategoriesConfig(
      items: current.items.map(
        (item) => item.id == id ? item.withActive(false) : item,
      ),
    ),
  );
}
