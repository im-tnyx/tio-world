import 'package:test/test.dart';
import 'package:tio_shared/shared.dart';

void main() {
  group('MealLogLocalDate', () {
    test('preserves a valid local calendar date as value identity', () {
      final first = MealLogLocalDate(year: 2026, month: 9, day: 11);
      final second = MealLogLocalDate(year: 2026, month: 9, day: 11);

      expect(first, second);
      expect(first.hashCode, second.hashCode);
      expect(first.toIso8601String(), '2026-09-11');
      expect(first.toString(), '2026-09-11');
    });

    test('round-trips the canonical YYYY-MM-DD representation', () {
      final date = MealLogLocalDate.fromIso8601String('2024-02-29');

      expect(date.year, 2024);
      expect(date.month, 2);
      expect(date.day, 29);
      expect(date.toIso8601String(), '2024-02-29');
    });

    test('rejects invalid or non-canonical calendar dates', () {
      expect(
        () => MealLogLocalDate(year: 2026, month: 2, day: 29),
        throwsArgumentError,
      );
      expect(
        () => MealLogLocalDate(year: 0, month: 1, day: 1),
        throwsArgumentError,
      );
      expect(
        () => MealLogLocalDate.fromIso8601String('2026-9-11'),
        throwsFormatException,
      );
      expect(
        () => MealLogLocalDate.fromIso8601String('2026-02-29'),
        throwsFormatException,
      );
    });
  });

  group('MealLogEntry.manual', () {
    final nutrition = NutritionSnapshot(
      schemaVersion: 1,
      nutrients: const <NutrientId, num>{
        NutrientId.energy: 420,
        NutrientId.protein: 28,
      },
    );
    final consumedAt = DateTime.utc(2026, 9, 11, 6, 30);
    final consumedLocalDate = MealLogLocalDate(
      year: 2026,
      month: 9,
      day: 11,
    );
    final createdAt = DateTime.utc(2026, 9, 11, 6, 31);
    final updatedAt = DateTime.utc(2026, 9, 11, 6, 32);

    MealLogEntry build({
      String? mealName = 'Breakfast',
      String? note,
    }) {
      return MealLogEntry.manual(
        id: 'meal-log-1',
        userId: 'user-1',
        mealCategoryId: 'breakfast',
        mealName: mealName,
        note: note,
        consumedAt: consumedAt,
        consumedLocalDate: consumedLocalDate,
        consumedTimezoneId: 'Asia/Kolkata',
        consumedUtcOffsetMinutes: 330,
        captureSource: MealLogCaptureSource.quickAdd,
        manualNutritionSnapshot: nutrition,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );
    }

    test('creates a first-class manual actual-history aggregate', () {
      final entry = build(note: 'Workout ke baad khaya');

      expect(entry.id, 'meal-log-1');
      expect(entry.userId, 'user-1');
      expect(entry.mode, MealLogMode.manual);
      expect(entry.mealCategoryId, 'breakfast');
      expect(entry.mealName, 'Breakfast');
      expect(entry.note, 'Workout ke baad khaya');
      expect(entry.consumedAt, consumedAt);
      expect(entry.consumedLocalDate, consumedLocalDate);
      expect(entry.consumedTimezoneId, 'Asia/Kolkata');
      expect(entry.consumedUtcOffsetMinutes, 330);
      expect(entry.captureSource, MealLogCaptureSource.quickAdd);
      expect(entry.manualNutritionSnapshot, same(nutrition));
      expect(entry.createdAt, createdAt);
      expect(entry.updatedAt, updatedAt);
    });

    test('normalizes blank meal name to absent without fabricating fallback', () {
      expect(build(mealName: null).mealName, isNull);
      expect(build(mealName: '').mealName, isNull);
      expect(build(mealName: '   \t').mealName, isNull);
    });

    test('keeps nonblank note text and normalizes blank note to absent', () {
      const exactNote = '  Restaurant meal, oil thoda zyada tha  ';

      expect(build(note: exactNote).note, exactNote);
      expect(build(note: null).note, isNull);
      expect(build(note: '').note, isNull);
      expect(build(note: '   \t').note, isNull);
    });

    test('keeps user-intended local date separate from chronology instant', () {
      final entry = MealLogEntry.manual(
        id: 'meal-log-travel',
        userId: 'user-1',
        mealCategoryId: 'dinner',
        consumedAt: DateTime.utc(2026, 9, 11, 6, 30),
        consumedLocalDate: MealLogLocalDate(
          year: 2026,
          month: 9,
          day: 10,
        ),
        consumedTimezoneId: 'America/Los_Angeles',
        consumedUtcOffsetMinutes: -420,
        manualNutritionSnapshot: nutrition,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );

      expect(entry.consumedAt, DateTime.utc(2026, 9, 11, 6, 30));
      expect(entry.consumedLocalDate.toIso8601String(), '2026-09-10');
      expect(entry.consumedUtcOffsetMinutes, -420);
    });

    test('accepts timezone ID or UTC offset independently', () {
      final timezoneOnly = MealLogEntry.manual(
        id: 'meal-log-timezone-only',
        userId: 'user-1',
        mealCategoryId: 'snack',
        consumedAt: consumedAt,
        consumedLocalDate: consumedLocalDate,
        consumedTimezoneId: 'Asia/Kolkata',
        manualNutritionSnapshot: nutrition,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );
      final offsetOnly = MealLogEntry.manual(
        id: 'meal-log-offset-only',
        userId: 'user-1',
        mealCategoryId: 'snack',
        consumedAt: consumedAt,
        consumedLocalDate: consumedLocalDate,
        consumedUtcOffsetMinutes: 330,
        manualNutritionSnapshot: nutrition,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );

      expect(timezoneOnly.consumedTimezoneId, 'Asia/Kolkata');
      expect(timezoneOnly.consumedUtcOffsetMinutes, isNull);
      expect(timezoneOnly.captureSource, isNull);
      expect(offsetOnly.consumedTimezoneId, isNull);
      expect(offsetOnly.consumedUtcOffsetMinutes, 330);
      expect(offsetOnly.captureSource, isNull);
    });

    test('rejects missing or blank-only consumed-time context', () {
      MealLogEntry create({String? timezoneId}) {
        return MealLogEntry.manual(
          id: 'meal-log-missing-context',
          userId: 'user-1',
          mealCategoryId: 'snack',
          consumedAt: consumedAt,
          consumedLocalDate: consumedLocalDate,
          consumedTimezoneId: timezoneId,
          manualNutritionSnapshot: nutrition,
          createdAt: createdAt,
          updatedAt: updatedAt,
        );
      }

      expect(create, throwsArgumentError);
      expect(() => create(timezoneId: '   \t'), throwsArgumentError);
    });
  });
}
