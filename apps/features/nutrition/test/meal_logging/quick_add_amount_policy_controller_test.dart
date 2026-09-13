import 'package:flutter_test/flutter_test.dart';
import 'package:tio_feature_nutrition/nutrition.dart';
import 'package:tio_shared/shared.dart';

void main() {
  const mutationId = '11111111-1111-4111-8111-111111111111';
  final now = DateTime(2026, 9, 12, 11);

  test('create accepts exact policy boundaries', () async {
    final repository = _RecordingRepository(_entry());
    final controller = QuickAddMealLogCreateController(
      repository: repository,
      clock: () => now,
      uuidV4: () => mutationId,
    );
    addTearDown(controller.dispose);

    final created = await controller.submit(
      _draft(
        calories: 10000,
        carbs: 1000,
        protein: 1000,
        fat: 1000,
      ),
    );

    expect(created, isNotNull);
    expect(repository.creates, hasLength(1));
    final snapshot = repository.creates.single.manualNutritionSnapshot;
    expect(snapshot.amountFor(NutrientId.energy), 10000);
    expect(snapshot.amountFor(NutrientId.carbohydrate), 1000);
    expect(snapshot.amountFor(NutrientId.protein), 1000);
    expect(snapshot.amountFor(NutrientId.fat), 1000);
  });

  test('create blocks upper-bound and precision bypasses before repository',
      () async {
    final repository = _RecordingRepository(_entry());
    var uuidCalls = 0;
    final controller = QuickAddMealLogCreateController(
      repository: repository,
      clock: () => now,
      uuidV4: () {
        uuidCalls++;
        return mutationId;
      },
    );
    addTearDown(controller.dispose);

    expect(await controller.submit(_draft(calories: 10000.1)), isNull);
    expect(
      controller.state.message,
      QuickAddMealLogCreateController.invalidMealMessage,
    );
    controller.draftChanged();

    expect(await controller.submit(_draft(protein: 999.99)), isNull);
    expect(
      controller.state.message,
      QuickAddMealLogCreateController.invalidMealMessage,
    );

    expect(repository.creates, isEmpty);
    expect(uuidCalls, 0);
  });

  test('create preserves missing optional macros and explicit zero', () async {
    final repository = _RecordingRepository(_entry());
    final controller = QuickAddMealLogCreateController(
      repository: repository,
      clock: () => now,
      uuidV4: () => mutationId,
    );
    addTearDown(controller.dispose);

    await controller.submit(
      _draft(
        calories: 0,
        carbs: null,
        protein: 0,
        fat: null,
      ),
    );

    final snapshot = repository.creates.single.manualNutritionSnapshot;
    expect(snapshot.amountFor(NutrientId.energy), 0);
    expect(snapshot.containsNutrient(NutrientId.carbohydrate), isFalse);
    expect(snapshot.amountFor(NutrientId.protein), 0);
    expect(snapshot.containsNutrient(NutrientId.fat), isFalse);
  });

  test('edit accepts exact boundaries and preserves hidden nutrients', () async {
    final original = _entry();
    final repository = _RecordingRepository(original);
    final controller = QuickAddMealLogEditController(
      repository: repository,
      initialEntry: original,
      clock: () => now,
    );
    addTearDown(controller.dispose);

    final updated = await controller.submit(
      _draft(
        calories: 10000,
        carbs: 1000,
        protein: 1000,
        fat: 1000,
      ),
    );

    expect(updated, isNotNull);
    expect(repository.updates, hasLength(1));
    final snapshot = repository.updates.single.manualNutritionSnapshot;
    expect(snapshot.amountFor(NutrientId.energy), 10000);
    expect(snapshot.amountFor(NutrientId.carbohydrate), 1000);
    expect(snapshot.amountFor(NutrientId.protein), 1000);
    expect(snapshot.amountFor(NutrientId.fat), 1000);
    expect(snapshot.amountFor(NutrientId.fiber), 8);
  });

  test('edit blocks upper-bound and precision bypasses before repository',
      () async {
    final original = _entry();
    final repository = _RecordingRepository(original);
    final controller = QuickAddMealLogEditController(
      repository: repository,
      initialEntry: original,
      clock: () => now,
    );
    addTearDown(controller.dispose);

    expect(await controller.submit(_draft(fat: 1000.1)), isNull);
    expect(
      controller.state.message,
      QuickAddMealLogEditController.invalidMealMessage,
    );
    controller.draftChanged();

    expect(await controller.submit(_draft(carbs: 999.99)), isNull);
    expect(
      controller.state.message,
      QuickAddMealLogEditController.invalidMealMessage,
    );

    expect(repository.updates, isEmpty);
  });

  test('edit keeps removal distinct from explicit zero', () async {
    final original = _entry();
    final repository = _RecordingRepository(original);
    final controller = QuickAddMealLogEditController(
      repository: repository,
      initialEntry: original,
      clock: () => now,
    );
    addTearDown(controller.dispose);

    await controller.submit(
      _draft(
        calories: 0,
        carbs: null,
        protein: 0,
        fat: null,
      ),
    );

    final snapshot = repository.updates.single.manualNutritionSnapshot;
    expect(snapshot.amountFor(NutrientId.energy), 0);
    expect(snapshot.containsNutrient(NutrientId.carbohydrate), isFalse);
    expect(snapshot.amountFor(NutrientId.protein), 0);
    expect(snapshot.containsNutrient(NutrientId.fat), isFalse);
    expect(snapshot.amountFor(NutrientId.fiber), 8);
  });
}

QuickAddMealLogDraft _draft({
  num calories = 420,
  num? carbs = 55,
  num? protein = 24.5,
  num? fat = 13,
}) {
  return QuickAddMealLogDraft(
    mealCategoryId: 'meal_slot_2',
    mealName: 'Dal and roti',
    consumedLocalDateTime: DateTime(2026, 9, 12, 10, 15),
    caloriesKcal: calories,
    carbohydrateGrams: carbs,
    proteinGrams: protein,
    fatGrams: fat,
  );
}

final class _RecordingRepository
    implements MealLogRepository, ManualMealLogUpdateRepository {
  _RecordingRepository(this.current);

  MealLogEntry current;
  final creates = <ManualMealLogCreate>[];
  final updates = <ManualMealLogUpdate>[];

  @override
  Future<MealLogEntry> createManual(ManualMealLogCreate input) async {
    creates.add(input);
    current = _entryFromCreate(input);
    return current;
  }

  @override
  Future<MealLogEntry> updateManual(ManualMealLogUpdate input) async {
    updates.add(input);
    current = _entryFromUpdate(current, input);
    return current;
  }

  @override
  Future<MealLogEntry?> readById(String id) async =>
      current.id == id ? current : null;

  @override
  Future<List<MealLogEntry>> listByLocalDate(
    MealLogLocalDate localDate,
  ) async =>
      current.consumedLocalDate == localDate ? [current] : const [];
}

MealLogEntry _entry() {
  return MealLogEntry.manual(
    id: 'meal-1',
    userId: 'user-1',
    mealCategoryId: 'meal_slot_2',
    mealName: 'Dal and roti',
    note: 'Keep this note',
    consumedAt: DateTime.utc(2026, 9, 12, 4, 45),
    consumedLocalDate: MealLogLocalDate(year: 2026, month: 9, day: 12),
    consumedTimezoneId: 'Asia/Kolkata',
    consumedUtcOffsetMinutes: 330,
    captureSource: MealLogCaptureSource.quickAdd,
    manualNutritionSnapshot: NutritionSnapshot(
      schemaVersion: 1,
      nutrients: {
        NutrientId.energy: 400,
        NutrientId.carbohydrate: 50,
        NutrientId.protein: 20,
        NutrientId.fat: 12,
        NutrientId.fiber: 8,
      },
    ),
    revision: 3,
    createdAt: DateTime.utc(2026, 9, 12, 4, 46),
    updatedAt: DateTime.utc(2026, 9, 12, 4, 47),
  );
}

MealLogEntry _entryFromCreate(ManualMealLogCreate input) {
  final storedAt = DateTime.utc(2026, 9, 12, 5);
  return MealLogEntry.manual(
    id: 'created-meal',
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
    createdAt: storedAt,
    updatedAt: storedAt,
  );
}

MealLogEntry _entryFromUpdate(MealLogEntry base, ManualMealLogUpdate input) {
  return MealLogEntry.manual(
    id: base.id,
    userId: base.userId,
    mealCategoryId: input.mealCategoryId,
    mealName: input.mealName,
    note: input.note,
    consumedAt: input.consumedAt,
    consumedLocalDate: input.consumedLocalDate,
    consumedTimezoneId: input.consumedTimezoneId,
    consumedUtcOffsetMinutes: input.consumedUtcOffsetMinutes,
    captureSource: base.captureSource,
    manualNutritionSnapshot: input.manualNutritionSnapshot,
    revision: input.expectedRevision + 1,
    createdAt: base.createdAt,
    updatedAt: base.updatedAt.add(const Duration(minutes: 1)),
  );
}
