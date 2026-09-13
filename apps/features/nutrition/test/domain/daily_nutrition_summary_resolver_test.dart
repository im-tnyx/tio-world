import 'package:flutter_test/flutter_test.dart';
import 'package:tio_feature_nutrition/nutrition.dart';
import 'package:tio_shared/shared.dart';

void main() {
  final day = MealLogLocalDate(year: 2026, month: 9, day: 13);
  final previousDay = MealLogLocalDate(year: 2026, month: 9, day: 12);
  final targets = _TargetsRepository(
    const NutritionTargetsData(
      caloriesKcal: 2000,
      carbohydrateGrams: 250,
      proteinGrams: 150,
      fatGrams: 70,
      fiberGrams: 30,
    ),
  );

  test('derives workout-OFF Target - Eaten = Remaining from canonical truth',
      () async {
    final mealLogs = _MealLogs([
      _entry(
        id: 'a',
        date: day,
        nutrients: {
          NutrientId.energy: 350,
          NutrientId.carbohydrate: 40,
          NutrientId.protein: 20,
          NutrientId.fat: 10,
          NutrientId.fiber: 5,
        },
      ),
      _entry(
        id: 'b',
        date: day,
        nutrients: {
          NutrientId.energy: 650,
          NutrientId.carbohydrate: 80,
          NutrientId.protein: 50,
          NutrientId.fat: 25,
          NutrientId.fiber: 10,
        },
      ),
    ]);
    final summary = await _resolver(mealLogs, targets).resolve(day);

    expect(summary.targetCaloriesKcal, 2000);
    expect(summary.eatenCaloriesKcal, 1000);
    expect(summary.remainingCaloriesKcal, 1000);
    expect(summary.calorieProgress, 0.5);
    expect(summary.consumedAmountFor(NutrientId.carbohydrate), 120);
    expect(summary.consumedAmountFor(NutrientId.protein), 70);
    expect(summary.consumedAmountFor(NutrientId.fat), 35);
    expect(summary.consumedAmountFor(NutrientId.fiber), 15);
    expect(summary.progressFor(NutrientId.fiber), 0.5);
  });

  test('preserves unknown nutrient instead of presenting a partial daily sum',
      () async {
    final mealLogs = _MealLogs([
      _entry(
        id: 'known',
        date: day,
        nutrients: {
          NutrientId.energy: 300,
          NutrientId.carbohydrate: 40,
          NutrientId.protein: 20,
          NutrientId.fat: 10,
          NutrientId.fiber: 5,
        },
      ),
      _entry(
        id: 'fiber-unknown',
        date: day,
        nutrients: {
          NutrientId.energy: 200,
          NutrientId.carbohydrate: 25,
          NutrientId.protein: 10,
          NutrientId.fat: 8,
        },
      ),
    ]);
    final summary = await _resolver(mealLogs, targets).resolve(day);

    expect(summary.eatenCaloriesKcal, 500);
    expect(summary.consumedAmountFor(NutrientId.carbohydrate), 65);
    expect(summary.consumedAmountFor(NutrientId.fiber), isNull);
    expect(summary.progressFor(NutrientId.fiber), isNull);
  });

  test('successful empty day is known zero consumption, not unknown', () async {
    final summary = await _resolver(_MealLogs(const []), targets).resolve(day);

    expect(summary.eatenCaloriesKcal, 0);
    expect(summary.remainingCaloriesKcal, 2000);
    expect(summary.calorieProgress, 0);
    for (final nutrient in DailyNutritionSummaryResolver.coreNutrients) {
      expect(summary.consumedAmountFor(nutrient), 0);
    }
  });

  test('missing target row keeps budget-derived values unavailable', () async {
    final summary = await _resolver(
      _MealLogs([
        _entry(
          id: 'meal',
          date: day,
          nutrients: {NutrientId.energy: 400},
        ),
      ]),
      _TargetsRepository(null),
    ).resolve(day);

    expect(summary.eatenCaloriesKcal, 400);
    expect(summary.targetCaloriesKcal, isNull);
    expect(summary.remainingCaloriesKcal, isNull);
    expect(summary.calorieProgress, isNull);
  });

  test('visible range uses one range read and one canonical target read',
      () async {
    final mealLogs = _MealLogs([
      _entry(
        id: 'previous',
        date: previousDay,
        nutrients: {NutrientId.energy: 500},
      ),
      _entry(
        id: 'today',
        date: day,
        nutrients: {NutrientId.energy: 1000},
      ),
    ]);
    final rangeTargets = _TargetsRepository(targets.value);

    final summaries = await _resolver(mealLogs, rangeTargets).resolveRange(
      startDate: previousDay,
      endDate: day,
    );

    expect(mealLogs.rangeReadCount, 1);
    expect(mealLogs.singleDayReadCount, 0);
    expect(rangeTargets.readCount, 1);
    expect(summaries[previousDay]!.calorieProgress, 0.25);
    expect(summaries[day]!.calorieProgress, 0.5);
  });

  test('rejects an inverted visible range before reading repositories',
      () async {
    final mealLogs = _MealLogs(const []);
    final rangeTargets = _TargetsRepository(targets.value);

    await expectLater(
      () => _resolver(mealLogs, rangeTargets).resolveRange(
        startDate: day,
        endDate: previousDay,
      ),
      throwsArgumentError,
    );
    expect(mealLogs.rangeReadCount, 0);
    expect(rangeTargets.readCount, 0);
  });
}

DailyNutritionSummaryResolver _resolver(
  MealLogRepository mealLogs,
  NutritionTargetsRepository targets,
) {
  return DailyNutritionSummaryResolver(
    mealLogRepository: mealLogs,
    budgetResolver: DailyNutritionBudgetResolver(
      nutritionTargetsRepository: targets,
    ),
  );
}

MealLogEntry _entry({
  required String id,
  required MealLogLocalDate date,
  required Map<NutrientId, num> nutrients,
}) {
  return MealLogEntry.manual(
    id: id,
    userId: 'user-1',
    mealCategoryId: 'meal_slot_1',
    consumedAt: DateTime.utc(date.year, date.month, date.day, 12),
    consumedLocalDate: date,
    consumedUtcOffsetMinutes: 0,
    manualNutritionSnapshot: NutritionSnapshot(
      schemaVersion: 1,
      nutrients: nutrients,
    ),
    createdAt: DateTime.utc(date.year, date.month, date.day, 12),
    updatedAt: DateTime.utc(date.year, date.month, date.day, 12),
  );
}

final class _TargetsRepository implements NutritionTargetsRepository {
  _TargetsRepository(this.value);

  final NutritionTargetsData? value;
  int readCount = 0;

  @override
  Future<NutritionTargetsData?> read() async {
    readCount++;
    return value;
  }

  @override
  Future<void> upsert(NutritionTargetsData targets) =>
      throw UnimplementedError();
}

final class _MealLogs implements MealLogRepository, MealLogRangeReadRepository {
  _MealLogs(this.entries);

  final List<MealLogEntry> entries;
  int singleDayReadCount = 0;
  int rangeReadCount = 0;

  @override
  Future<List<MealLogEntry>> listByLocalDate(MealLogLocalDate localDate) async {
    singleDayReadCount++;
    return [
      for (final entry in entries)
        if (entry.consumedLocalDate == localDate) entry,
    ];
  }

  @override
  Future<List<MealLogEntry>> listByLocalDateRange({
    required MealLogLocalDate startDate,
    required MealLogLocalDate endDate,
  }) async {
    rangeReadCount++;
    final start = startDate.toIso8601String();
    final end = endDate.toIso8601String();
    return [
      for (final entry in entries)
        if (entry.consumedLocalDate.toIso8601String().compareTo(start) >= 0 &&
            entry.consumedLocalDate.toIso8601String().compareTo(end) <= 0)
          entry,
    ];
  }

  @override
  Future<MealLogEntry> createManual(ManualMealLogCreate input) =>
      throw UnimplementedError();

  @override
  Future<MealLogEntry?> readById(String id) => throw UnimplementedError();
}
