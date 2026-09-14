import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tio_core/core.dart';
import 'package:tio_feature_nutrition/nutrition.dart';
import 'package:tio_feature_nutrition/src/meal_diary/presentation/widgets/meal_diary_history_view.dart';
import 'package:tio_shared/shared.dart';

void main() {
  final day = MealLogLocalDate(year: 2026, month: 9, day: 14);

  testWidgets('section header renders confirmed protein minimum with plus',
      (tester) async {
    final semantics = tester.ensureSemantics();
    await _pumpHistory(
      tester,
      day: day,
      entries: [
        _entry(id: 'known', day: day, calories: 100, protein: 24),
        _entry(id: 'missing', day: day, calories: 200),
      ],
    );

    final summary = find.byKey(
      const ValueKey('meal-diary-section-summary-meal_slot_2'),
    );
    expect(summary, findsOneWidget);
    expect(find.descendant(of: summary, matching: find.text('300 kcal')),
        findsOneWidget);
    expect(
      find.descendant(of: summary, matching: find.text('24g+')),
      findsOneWidget,
    );
    expect(
      find.semantics.byLabel(
        '300 kcal, at least 24 grams protein, 1 meal missing protein, total incomplete',
      ),
      findsOne,
    );
    semantics.dispose();
  });

  testWidgets('section header keeps protein visible as dash when all are missing',
      (tester) async {
    await _pumpHistory(
      tester,
      day: day,
      entries: [
        _entry(id: 'missing-a', day: day, calories: 100),
        _entry(id: 'missing-b', day: day, calories: 200),
      ],
    );

    final summary = find.byKey(
      const ValueKey('meal-diary-section-summary-meal_slot_2'),
    );
    expect(summary, findsOneWidget);
    expect(
      find.descendant(of: summary, matching: find.text('—')),
      findsOneWidget,
    );
    expect(find.descendant(of: summary, matching: find.text('0g+')), findsNothing);
  });
}

Future<void> _pumpHistory(
  WidgetTester tester, {
  required MealLogLocalDate day,
  required List<MealLogEntry> entries,
}) async {
  final mealLogs = _MealLogs(entries);
  final categories = _MealCategories();
  final request = MealDiaryHistoryRequest(
    mealLogRepository: mealLogs,
    mealCategoriesRepository: categories,
    localDate: day,
  );

  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        builder: (context, child) => TioTheme(
          config: const TioThemeConfig(mode: TioThemeMode.light),
          child: child ?? const SizedBox.shrink(),
        ),
        home: Scaffold(
          body: SingleChildScrollView(
            child: MealDiaryHistoryView(
              date: DateTime(day.year, day.month, day.day),
              request: request,
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

MealLogEntry _entry({
  required String id,
  required MealLogLocalDate day,
  required num calories,
  num? protein,
}) {
  return MealLogEntry.manual(
    id: id,
    userId: 'user-1',
    mealCategoryId: 'meal_slot_2',
    mealName: id,
    consumedAt: DateTime.utc(day.year, day.month, day.day, 12),
    consumedLocalDate: day,
    consumedUtcOffsetMinutes: 0,
    manualNutritionSnapshot: NutritionSnapshot(
      schemaVersion: 1,
      nutrients: {
        NutrientId.energy: calories,
        if (protein != null) NutrientId.protein: protein,
      },
    ),
    createdAt: DateTime.utc(day.year, day.month, day.day, 12),
    updatedAt: DateTime.utc(day.year, day.month, day.day, 12),
  );
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

final class _MealCategories implements MealCategoriesRepository {
  @override
  Future<MealCategoriesConfig> read() async =>
      MealCategoriesConfig.canonicalDefaults();

  @override
  Future<void> upsert(MealCategoriesConfig config) => throw UnimplementedError();
}
