import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tio_core/core.dart';
import 'package:tio_feature_nutrition/nutrition.dart';
import 'package:tio_shared/shared.dart';

final _now = DateTime(2026, 9, 13, 12);
final _today = DateTime(2026, 9, 13);
final _todayLocalDate = MealLogLocalDate(year: 2026, month: 9, day: 13);

void main() {
  testWidgets(
      'selected day and calendar ring share canonical budget and MealLog truth',
      (tester) async {
    final categories = InMemoryMealCategoriesRepository();
    final mealLogs = InMemoryMealLogRepository(
      mealCategoriesRepository: categories,
      clock: () => _now,
    );
    final targets = InMemoryNutritionTargetsRepository();
    await targets.upsert(
      const NutritionTargetsData(
        caloriesKcal: 2000,
        carbohydrateGrams: 250,
        proteinGrams: 150,
        fatGrams: 70,
        fiberGrams: 30,
      ),
    );
    await mealLogs.createManual(
      ManualMealLogCreate(
        clientMutationId: '00000000-0000-4000-8000-000000000206',
        mealCategoryId: 'meal_slot_1',
        consumedAt: _now,
        consumedLocalDate: _todayLocalDate,
        consumedUtcOffsetMinutes: 0,
        captureSource: MealLogCaptureSource.quickAdd,
        manualNutritionSnapshot: NutritionSnapshot(
          schemaVersion: 1,
          nutrients: const {
            NutrientId.energy: 800,
            NutrientId.carbohydrate: 90,
            NutrientId.protein: 70,
            NutrientId.fat: 30,
            NutrientId.fiber: 10,
          },
        ),
      ),
    );
    final dates = MealDiaryDateController(clock: () => _now);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          mealDiaryDateControllerProvider.overrideWith((ref) => dates),
          mealDiaryMealLogRepositoryProvider.overrideWithValue(mealLogs),
          mealDiaryNutritionTargetsRepositoryProvider.overrideWithValue(targets),
        ],
        child: MaterialApp(
          builder: (context, child) => TioTheme(
            config: const TioThemeConfig(mode: TioThemeMode.light),
            child: child ?? const SizedBox.shrink(),
          ),
          home: Scaffold(
            body: MealDiaryPage(mealCategoriesRepository: categories),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('meal-diary-daily-nutrition-summary')),
      findsOneWidget,
    );
    expect(find.text('800 kcal'), findsOneWidget);
    expect(find.text('1200 kcal'), findsOneWidget);
    expect(find.text('Workout'), findsNothing);

    final calendar = tester.widget<TioDateCalendar>(find.byType(TioDateCalendar));
    expect(calendar.decorationBuilder, isNotNull);
    final todayDecoration = calendar.decorationBuilder!(_today);
    expect(todayDecoration, isNotNull);
    expect(todayDecoration!.progress, 0.4);
    expect(todayDecoration.semanticsLabel, contains('800 of 2000'));

    // The range is clamped to the Diary's actual selectable horizon. A future
    // disabled cell must not gain a fabricated zero-progress ring.
    expect(
      calendar.decorationBuilder!(DateTime(2026, 9, 14)),
      isNull,
    );
  });

  testWidgets('changing selected date recomputes summary without moving it',
      (tester) async {
    final categories = InMemoryMealCategoriesRepository();
    final mealLogs = InMemoryMealLogRepository(
      mealCategoriesRepository: categories,
      clock: () => _now,
    );
    final targets = InMemoryNutritionTargetsRepository();
    await targets.upsert(const NutritionTargetsData(caloriesKcal: 2000));
    final dates = MealDiaryDateController(clock: () => _now);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          mealDiaryDateControllerProvider.overrideWith((ref) => dates),
          mealDiaryMealLogRepositoryProvider.overrideWithValue(mealLogs),
          mealDiaryNutritionTargetsRepositoryProvider.overrideWithValue(targets),
        ],
        child: MaterialApp(
          builder: (context, child) => TioTheme(
            config: const TioThemeConfig(mode: TioThemeMode.light),
            child: child ?? const SizedBox.shrink(),
          ),
          home: Scaffold(
            body: MealDiaryPage(mealCategoriesRepository: categories),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final yesterday = DateTime(2026, 9, 12);
    dates.select(yesterday);
    await tester.pumpAndSettle();

    expect(dates.selectedDate, yesterday);
    expect(find.text('0 kcal'), findsOneWidget);
    // Target and Remaining are both the untouched Standard-strategy target.
    expect(find.text('2000 kcal'), findsNWidgets(2));
    expect(find.text('Workout'), findsNothing);
  });

  testWidgets('without target composition the legacy isolated diary stays honest',
      (tester) async {
    final dates = MealDiaryDateController(clock: () => _now);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          mealDiaryDateControllerProvider.overrideWith((ref) => dates),
        ],
        child: MaterialApp(
          builder: (context, child) => TioTheme(
            config: const TioThemeConfig(mode: TioThemeMode.light),
            child: child ?? const SizedBox.shrink(),
          ),
          home: const Scaffold(body: MealDiaryPage()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('meal-diary-daily-nutrition-summary')),
      findsNothing,
    );
    expect(
      tester.widget<TioDateCalendar>(find.byType(TioDateCalendar)).decorationBuilder,
      isNull,
    );
  });
}
