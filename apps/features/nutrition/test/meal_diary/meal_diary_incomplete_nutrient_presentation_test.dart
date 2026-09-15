import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tio_core/core.dart';
import 'package:tio_feature_nutrition/nutrition.dart';
import 'package:tio_shared/shared.dart';

void main() {
  final day = MealLogLocalDate(year: 2026, month: 9, day: 14);
  const targets = NutritionTargetsData(
    caloriesKcal: 2000,
    carbohydrateGrams: 250,
    proteinGrams: 150,
    fatGrams: 70,
    fiberGrams: 30,
  );

  testWidgets(
      'partial protein stays exact-unknown but renders confirmed minimum with missing count',
      (tester) async {
    final summary = await _resolver(
      _MealLogs([
        _entry(
          id: 'known-protein',
          date: day,
          nutrients: const {
            NutrientId.energy: 300,
            NutrientId.carbohydrate: 40,
            NutrientId.protein: 24,
            NutrientId.fat: 10,
            NutrientId.fiber: 5,
          },
        ),
        _entry(
          id: 'missing-protein',
          date: day,
          nutrients: const {
            NutrientId.energy: 200,
            NutrientId.carbohydrate: 25,
            NutrientId.fat: 8,
            NutrientId.fiber: 4,
          },
        ),
      ]),
      _TargetsRepository(targets),
    ).resolve(day);

    expect(summary.consumedAmountFor(NutrientId.protein), isNull);
    expect(summary.confirmedConsumedAmountFor(NutrientId.protein), 24);
    expect(summary.missingConsumedEntryCountFor(NutrientId.protein), 1);
    expect(summary.isConsumedIncompleteFor(NutrientId.protein), isTrue);
    expect(summary.progressFor(NutrientId.protein), isNull);

    final semantics = tester.ensureSemantics();
    await _pumpSummary(tester, summary);

    expect(
      _textAtKey(tester, const ValueKey('daily-nutrition-protein-value')),
      '24 g+ / 150 g',
    );
    expect(
      _textAtKey(tester, const ValueKey('daily-nutrition-incomplete-note')),
      '1 meal missing protein',
    );
    expect(
      find.byKey(const ValueKey('daily-nutrition-protein-progress')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('daily-nutrition-carbohydrate-progress')),
      findsOneWidget,
    );
    expect(
      find.semantics.byLabel(
        'Protein, at least 24 g consumed, 1 meal missing protein, total incomplete, 150 g target',
      ),
      findsOne,
    );
    semantics.dispose();
  });

  testWidgets('fully unavailable protein renders dash rather than zero-plus',
      (tester) async {
    final summary = await _resolver(
      _MealLogs([
        _entry(
          id: 'missing-a',
          date: day,
          nutrients: const {
            NutrientId.energy: 300,
            NutrientId.carbohydrate: 40,
            NutrientId.fat: 10,
            NutrientId.fiber: 5,
          },
        ),
        _entry(
          id: 'missing-b',
          date: day,
          nutrients: const {
            NutrientId.energy: 200,
            NutrientId.carbohydrate: 25,
            NutrientId.fat: 8,
            NutrientId.fiber: 4,
          },
        ),
      ]),
      _TargetsRepository(targets),
    ).resolve(day);

    expect(summary.consumedAmountFor(NutrientId.protein), isNull);
    expect(summary.confirmedConsumedAmountFor(NutrientId.protein), isNull);
    expect(summary.missingConsumedEntryCountFor(NutrientId.protein), 2);
    expect(summary.progressFor(NutrientId.protein), isNull);

    await _pumpSummary(tester, summary);

    expect(
      _textAtKey(tester, const ValueKey('daily-nutrition-protein-value')),
      '— / 150 g',
    );
    expect(
      _textAtKey(tester, const ValueKey('daily-nutrition-incomplete-note')),
      '2 meals missing protein',
    );
    expect(find.textContaining('0 g+'), findsNothing);
    expect(
      find.byKey(const ValueKey('daily-nutrition-protein-progress')),
      findsNothing,
    );
  });
}

String _textAtKey(WidgetTester tester, Key key) =>
    tester.widget<Text>(find.byKey(key)).data!;

Future<void> _pumpSummary(
  WidgetTester tester,
  DailyNutritionSummary summary,
) async {
  await tester.pumpWidget(
    MaterialApp(
      builder: (context, child) => TioTheme(
        config: const TioThemeConfig(mode: TioThemeMode.light),
        child: child ?? const SizedBox.shrink(),
      ),
      home: Scaffold(
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(TioSpacing.lg),
          child: MealDiaryDailyNutritionSummary(summary: summary),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
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
    mealCategoryId: 'meal_slot_2',
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

  @override
  Future<NutritionTargetsData?> read() async => value;

  @override
  Future<void> upsert(NutritionTargetsData targets) =>
      throw UnimplementedError();
}

final class _MealLogs implements MealLogRepository {
  _MealLogs(this.entries);

  final List<MealLogEntry> entries;

  @override
  Future<List<MealLogEntry>> listByLocalDate(MealLogLocalDate localDate) async =>
      [
        for (final entry in entries)
          if (entry.consumedLocalDate == localDate) entry,
      ];

  @override
  Future<MealLogEntry> createManual(ManualMealLogCreate input) =>
      throw UnimplementedError();

  @override
  Future<MealLogEntry?> readById(String id) => throw UnimplementedError();
}
