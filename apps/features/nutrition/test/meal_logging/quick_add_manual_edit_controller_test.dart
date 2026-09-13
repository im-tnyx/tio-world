import 'package:flutter_test/flutter_test.dart';
import 'package:tio_feature_nutrition/nutrition.dart';
import 'package:tio_shared/shared.dart';

void main() {
  QuickAddMealLogDraft draft({
    String categoryId = 'meal_slot_2',
    String? name = 'Dal and roti',
    DateTime? local,
    num calories = 420,
    num? carbs = 55,
    num? protein = 24.5,
    num? fat = 13,
  }) =>
      QuickAddMealLogDraft(
        mealCategoryId: categoryId,
        mealName: name,
        consumedLocalDateTime: local ?? DateTime(2026, 9, 12, 10, 15),
        caloriesKcal: calories,
        carbohydrateGrams: carbs,
        proteinGrams: protein,
        fatGrams: fat,
      );

  test('updates the same id and preserves hidden canonical facts', () async {
    final original = _entry();
    final repository = _RecordingUpdateRepository(current: original);
    final controller = QuickAddMealLogEditController(
      repository: repository,
      initialEntry: original,
      clock: () => DateTime(2026, 9, 12, 11),
    );
    addTearDown(controller.dispose);

    final updated = await controller.submit(draft());

    expect(controller.state.message, isNull);
    expect(updated, isNotNull);
    final input = repository.inputs.single;
    expect(input.id, original.id);
    expect(input.expectedRevision, 4);
    expect(input.note, 'Keep this note');
    expect(input.consumedAt, original.consumedAt);
    expect(input.consumedLocalDate, original.consumedLocalDate);
    expect(input.consumedTimezoneId, original.consumedTimezoneId);
    expect(
      input.consumedUtcOffsetMinutes,
      original.consumedUtcOffsetMinutes,
    );
    expect(input.manualNutritionSnapshot.amountFor(NutrientId.energy), 420);
    expect(input.manualNutritionSnapshot.amountFor(NutrientId.fiber), 8);
    expect(updated!.id, original.id);
    expect(updated.mode, MealLogMode.manual);
    expect(updated.captureSource, MealLogCaptureSource.quickAdd);
    expect(updated.revision, 5);
  });

  test('changed wall time writes the new local-date and offset context',
      () async {
    final original = _entry();
    final repository = _RecordingUpdateRepository(current: original);
    final controller = QuickAddMealLogEditController(
      repository: repository,
      initialEntry: original,
      clock: () => DateTime(2026, 9, 13, 12),
    );
    addTearDown(controller.dispose);
    final changed = DateTime(2026, 9, 13, 9, 45);

    await controller.submit(draft(local: changed));

    final input = repository.inputs.single;
    expect(input.consumedAt, changed.toUtc());
    expect(
      input.consumedLocalDate,
      MealLogLocalDate(year: 2026, month: 9, day: 13),
    );
    expect(input.consumedTimezoneId, isNull);
    expect(input.consumedUtcOffsetMinutes, changed.timeZoneOffset.inMinutes);
  });

  group('RF1 — unchanged time survives timezone/clock travel', () {
    test(
        'an unrelated edit succeeds even when the unchanged stored time now '
        'reads as future on the current clock', () async {
      final original = _entry();
      final repository = _RecordingUpdateRepository(current: original);
      // A clock earlier than the entry's own stored local wall time — the
      // same effect a backward timezone/device-clock change has: the
      // untouched meal now looks like it is in the future relative to "now",
      // even though nothing about its own time changed.
      final controller = QuickAddMealLogEditController(
        repository: repository,
        initialEntry: original,
        clock: () => DateTime(2026, 9, 12, 9),
      );
      addTearDown(controller.dispose);

      final updated = await controller.submit(
        draft(name: 'Renamed, unchanged time'),
      );

      expect(controller.state.message, isNull);
      expect(updated, isNotNull);
      final input = repository.inputs.single;
      expect(input.mealName, 'Renamed, unchanged time');
      // Canonical time facts are exactly preserved, not just "not rejected".
      expect(input.consumedAt, original.consumedAt);
      expect(input.consumedLocalDate, original.consumedLocalDate);
      expect(input.consumedTimezoneId, original.consumedTimezoneId);
      expect(
        input.consumedUtcOffsetMinutes,
        original.consumedUtcOffsetMinutes,
      );
    });

    test('a genuinely changed future time is still rejected', () async {
      final original = _entry();
      final repository = _RecordingUpdateRepository(current: original);
      final controller = QuickAddMealLogEditController(
        repository: repository,
        initialEntry: original,
        clock: () => DateTime(2026, 9, 12, 11),
      );
      addTearDown(controller.dispose);

      final future = DateTime(2026, 9, 12, 12);
      final updated = await controller.submit(draft(local: future));

      expect(updated, isNull);
      expect(
        controller.state.message,
        QuickAddMealLogEditController.futureMealMessage,
      );
      expect(repository.inputs, isEmpty);
    });
  });

  test('conflict reloads canonical state before a deliberate reapply',
      () async {
    final original = _entry();
    final latest = _entry(revision: 7, name: 'Changed elsewhere');
    var attempts = 0;
    late final _RecordingUpdateRepository repository;
    repository = _RecordingUpdateRepository(
      current: original,
      onUpdate: (input) async {
        attempts++;
        if (attempts == 1) {
          repository.current = latest;
          throw MealLogUpdateConflict(
            id: input.id,
            expectedRevision: input.expectedRevision,
            actualRevision: latest.revision,
          );
        }
        return _updatedFrom(latest, input);
      },
    );
    final controller = QuickAddMealLogEditController(
      repository: repository,
      initialEntry: original,
      clock: () => DateTime(2026, 9, 12, 11),
    );
    addTearDown(controller.dispose);

    expect(await controller.submit(draft()), isNull);
    expect(controller.state.status, QuickAddMealLogEditStatus.conflict);
    expect(controller.state.entry, same(latest));
    expect(controller.baseEntry.revision, 7);
    expect(controller.state.message,
        QuickAddMealLogEditController.conflictMessage);

    controller.draftChanged();
    final reapplied = await controller.submit(
      draft(name: 'My deliberate reapply'),
    );
    expect(reapplied, isNotNull);
    expect(repository.inputs.last.expectedRevision, 7);
    expect(repository.inputs.last.id, original.id);
  });

  test('unknown outcome retries the exact same update facts and revision',
      () async {
    final original = _entry();
    var attempts = 0;
    final repository = _RecordingUpdateRepository(
      current: original,
      onUpdate: (input) async {
        attempts++;
        if (attempts == 1) {
          throw MealLogUpdateOutcomeUnknown(
            id: input.id,
            expectedRevision: input.expectedRevision,
          );
        }
        return _updatedFrom(original, input);
      },
    );
    final controller = QuickAddMealLogEditController(
      repository: repository,
      initialEntry: original,
      clock: () => DateTime(2026, 9, 12, 11),
    );
    addTearDown(controller.dispose);

    expect(await controller.submit(draft()), isNull);
    expect(controller.state.isOutcomeUnknown, isTrue);
    expect(controller.state.locksDraft, isTrue);

    final reconciled = await controller.submit(draft(calories: 999));
    expect(reconciled, isNotNull);
    expect(repository.inputs, hasLength(2));
    expect(repository.inputs[1], same(repository.inputs[0]));
    expect(repository.inputs[1].expectedRevision, original.revision);
    expect(
      repository.inputs[1].manualNutritionSnapshot.amountFor(NutrientId.energy),
      420,
    );
  });
}

final class _RecordingUpdateRepository
    implements MealLogRepository, ManualMealLogUpdateRepository {
  _RecordingUpdateRepository({
    required MealLogEntry current,
    this.onUpdate,
  }) : _current = current;

  MealLogEntry _current;
  final Future<MealLogEntry> Function(ManualMealLogUpdate input)? onUpdate;
  final List<ManualMealLogUpdate> inputs = [];

  set current(MealLogEntry value) => _current = value;

  @override
  Future<MealLogEntry> updateManual(ManualMealLogUpdate input) async {
    inputs.add(input);
    final callback = onUpdate;
    final updated = callback == null
        ? _updatedFrom(_current, input)
        : await callback(input);
    _current = updated;
    return updated;
  }

  @override
  Future<MealLogEntry?> readById(String id) async =>
      _current.id == id ? _current : null;

  @override
  Future<MealLogEntry> createManual(ManualMealLogCreate input) =>
      throw UnimplementedError();

  @override
  Future<List<MealLogEntry>> listByLocalDate(
          MealLogLocalDate localDate) async =>
      const [];
}

MealLogEntry _updatedFrom(MealLogEntry base, ManualMealLogUpdate input) {
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

MealLogEntry _entry({int revision = 4, String? name = 'Dal and roti'}) {
  return MealLogEntry.manual(
    id: 'meal-1',
    userId: 'user-1',
    mealCategoryId: 'meal_slot_2',
    mealName: name,
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
    revision: revision,
    createdAt: DateTime.utc(2026, 9, 12, 4, 46),
    updatedAt: DateTime.utc(2026, 9, 12, 4, 47),
  );
}
