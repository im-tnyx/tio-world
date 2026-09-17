import 'package:test/test.dart';
import 'package:tio_shared/shared.dart';

void main() {
  group('MealLogEntry.detailed', () {
    final consumedAt = DateTime.utc(2026, 9, 17, 3, 15);
    final consumedLocalDate = MealLogLocalDate(
      year: 2026,
      month: 9,
      day: 17,
    );
    final createdAt = DateTime.utc(2026, 9, 17, 3, 16);
    final updatedAt = DateTime.utc(2026, 9, 17, 3, 17);

    NutritionSnapshot nutrition(num calories, {num? protein}) {
      return NutritionSnapshot(
        schemaVersion: 1,
        nutrients: <NutrientId, num>{
          NutrientId.energy: calories,
          if (protein != null) NutrientId.protein: protein,
        },
      );
    }

    MealLogItemSnapshot item({
      String id = 'item-1',
      String mealLogEntryId = 'meal-detailed-1',
      String displayName = 'Roti',
      num quantity = 2,
      String servingUnit = 'piece',
      NutritionSnapshot? snapshot,
    }) {
      return MealLogItemSnapshot(
        id: id,
        mealLogEntryId: mealLogEntryId,
        displayName: displayName,
        quantity: quantity,
        servingUnit: servingUnit,
        nutritionSnapshot: snapshot ?? nutrition(220, protein: 7),
      );
    }

    MealLogEntry build({
      String id = 'meal-detailed-1',
      String? mealName = 'Lunch',
      String? note,
      MealLogCaptureSource? captureSource = MealLogCaptureSource.text,
      List<MealLogItemSnapshot>? items,
      int revision = 1,
      String? consumedTimezoneId = 'Asia/Kolkata',
      int? consumedUtcOffsetMinutes = 330,
    }) {
      return MealLogEntry.detailed(
        id: id,
        userId: 'user-1',
        mealCategoryId: 'meal_slot_2',
        mealName: mealName,
        note: note,
        consumedAt: consumedAt,
        consumedLocalDate: consumedLocalDate,
        consumedTimezoneId: consumedTimezoneId,
        consumedUtcOffsetMinutes: consumedUtcOffsetMinutes,
        captureSource: captureSource,
        detailedItems: items ?? <MealLogItemSnapshot>[item()],
        revision: revision,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );
    }

    test('creates detailed actual history without manual nutrition truth', () {
      final second = item(
        id: 'item-2',
        displayName: 'Dal',
        quantity: 1,
        servingUnit: 'bowl',
        snapshot: nutrition(180, protein: 10),
      );
      final entry = build(
        note: 'Post-workout lunch',
        items: <MealLogItemSnapshot>[item(), second],
      );

      expect(entry.id, 'meal-detailed-1');
      expect(entry.userId, 'user-1');
      expect(entry.mode, MealLogMode.detailed);
      expect(entry.mealCategoryId, 'meal_slot_2');
      expect(entry.mealName, 'Lunch');
      expect(entry.note, 'Post-workout lunch');
      expect(entry.captureSource, MealLogCaptureSource.text);
      expect(entry.manualNutritionSnapshot, isNull);
      expect(entry.detailedItems, hasLength(2));
      expect(entry.detailedItems.first.displayName, 'Roti');
      expect(entry.detailedItems.last.displayName, 'Dal');
      expect(entry.revision, 1);
      expect(entry.createdAt, createdAt);
      expect(entry.updatedAt, updatedAt);
    });

    test('normalizes optional meal name and note without inventing fallbacks', () {
      final entry = build(mealName: '   ', note: '\t');

      expect(entry.mealName, isNull);
      expect(entry.note, isNull);
    });

    test('requires at least one durable detailed item', () {
      expect(
        () => build(items: <MealLogItemSnapshot>[]),
        throwsArgumentError,
      );
    });

    test('rejects an item attached to a different MealLog identity', () {
      final foreign = item(mealLogEntryId: 'another-meal');

      expect(
        () => build(items: <MealLogItemSnapshot>[foreign]),
        throwsArgumentError,
      );
    });

    test('rejects duplicate item identities within one aggregate', () {
      final first = item();
      final duplicate = item(
        displayName: 'Duplicate identity',
        snapshot: nutrition(100),
      );

      expect(
        () => build(items: <MealLogItemSnapshot>[first, duplicate]),
        throwsArgumentError,
      );
    });

    test('defensively copies the caller-owned detailed item list', () {
      final source = <MealLogItemSnapshot>[item()];
      final entry = build(items: source);

      source.add(
        item(
          id: 'item-2',
          displayName: 'Curd',
          quantity: 150,
          servingUnit: 'g',
          snapshot: nutrition(90, protein: 5),
        ),
      );

      expect(entry.detailedItems, hasLength(1));
      expect(
        () => entry.detailedItems.add(
          item(
            id: 'item-3',
            displayName: 'Salad',
            snapshot: nutrition(40),
          ),
        ),
        throwsUnsupportedError,
      );
    });

    test('shares the existing consumed-time and revision invariants', () {
      expect(
        () => build(
          consumedTimezoneId: null,
          consumedUtcOffsetMinutes: null,
        ),
        throwsArgumentError,
      );
      expect(() => build(revision: 0), throwsArgumentError);
    });

    test('keeps capture source orthogonal to detailed mode', () {
      final entry = build(captureSource: MealLogCaptureSource.quickAdd);

      expect(entry.mode, MealLogMode.detailed);
      expect(entry.captureSource, MealLogCaptureSource.quickAdd);
    });
  });

  test('manual MealLog keeps detailed items empty', () {
    final entry = MealLogEntry.manual(
      id: 'manual-1',
      userId: 'user-1',
      mealCategoryId: 'meal_slot_1',
      consumedAt: DateTime.utc(2026, 9, 17, 3),
      consumedLocalDate: MealLogLocalDate(
        year: 2026,
        month: 9,
        day: 17,
      ),
      consumedUtcOffsetMinutes: 330,
      captureSource: MealLogCaptureSource.quickAdd,
      manualNutritionSnapshot: NutritionSnapshot(
        schemaVersion: 1,
        nutrients: const <NutrientId, num>{NutrientId.energy: 300},
      ),
      createdAt: DateTime.utc(2026, 9, 17, 3, 1),
      updatedAt: DateTime.utc(2026, 9, 17, 3, 1),
    );

    expect(entry.mode, MealLogMode.manual);
    expect(entry.manualNutritionSnapshot, isNotNull);
    expect(entry.detailedItems, isEmpty);
  });
}
