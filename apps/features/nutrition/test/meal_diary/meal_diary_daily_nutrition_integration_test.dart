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

    final summaryCard =
        find.byKey(const ValueKey('meal-diary-daily-nutrition-summary'));
    expect(summaryCard, findsOneWidget);
    expect(
      _textAtKey(tester, const ValueKey('daily-nutrition-eaten-calories')),
      '800',
    );
    expect(
      _textAtKey(tester, const ValueKey('daily-nutrition-remaining-calories')),
      '1200',
    );
    expect(
      find.descendant(of: summaryCard, matching: find.text('Carbs')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: summaryCard, matching: find.text('Protein')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: summaryCard, matching: find.text('Fat')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: summaryCard, matching: find.text('Fiber')),
      findsOneWidget,
    );
    expect(find.text('Workout'), findsNothing);

    final calendar = tester.widget<TioDateCalendar>(find.byType(TioDateCalendar));
    expect(calendar.decorationBuilder, isNotNull);
    final todayDecoration = calendar.decorationBuilder!(_today);
    expect(todayDecoration, isNotNull);
    expect(todayDecoration!.progress, 0.4);
    expect(todayDecoration.semanticsLabel, contains('800 of 2000'));

    // The resolved read-only summary visually consumes most of the calendar's
    // transparent 42dp handle-clearance band. The visible handle therefore sits
    // only about 10dp above the card instead of leaving the old ~48dp void.
    final grabber = find.byKey(const ValueKey('tio-date-calendar-grabber'));
    final visibleGap =
        tester.getTopLeft(summaryCard).dy - tester.getBottomLeft(grabber).dy;
    expect(visibleGap, inInclusiveRange(8, 14));

    // The overlapped summary is pointer-transparent, so the calendar keeps the
    // complete handle target rather than trading accessibility for compactness.
    await tester.tap(find.byKey(const ValueKey('tio-date-calendar-handle')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('tio-date-calendar-month-pager')),
      findsOneWidget,
    );

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
    expect(
      _textAtKey(tester, const ValueKey('daily-nutrition-eaten-calories')),
      '0',
    );
    expect(
      _textAtKey(tester, const ValueKey('daily-nutrition-target-calories')),
      '2000',
    );
    expect(
      _textAtKey(tester, const ValueKey('daily-nutrition-remaining-calories')),
      '2000',
    );
    expect(find.text('Carbs'), findsOneWidget);
    expect(find.text('Protein'), findsOneWidget);
    expect(find.text('Fat'), findsOneWidget);
    expect(find.text('Fiber'), findsOneWidget);
    expect(find.text('Workout'), findsNothing);
  });

  testWidgets('target save refreshes mounted summary and calendar denominator',
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

    expect(
      _textAtKey(tester, const ValueKey('daily-nutrition-target-calories')),
      '2000',
    );

    await targets.upsert(const NutritionTargetsData(caloriesKcal: 2200));
    await tester.pumpAndSettle();

    expect(
      _textAtKey(tester, const ValueKey('daily-nutrition-target-calories')),
      '2200',
    );
    expect(
      _textAtKey(tester, const ValueKey('daily-nutrition-remaining-calories')),
      '2200',
    );
    final calendar = tester.widget<TioDateCalendar>(find.byType(TioDateCalendar));
    final todayDecoration = calendar.decorationBuilder!(_today);
    expect(todayDecoration, isNotNull);
    expect(todayDecoration!.progress, 0);
    expect(todayDecoration.semanticsLabel, contains('0 of 2200'));
  });

  testWidgets('daily summary error offers retry and can recover in place',
      (tester) async {
    final categories = InMemoryMealCategoriesRepository();
    final mealLogs = InMemoryMealLogRepository(
      mealCategoriesRepository: categories,
      clock: () => _now,
    );
    final targets = _FailingTargetsRepository();
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
      find.byKey(const ValueKey('meal-diary-daily-nutrition-error')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('meal-diary-daily-nutrition-retry')),
      findsOneWidget,
    );

    targets.failReads = false;
    await tester.tap(
      find.byKey(const ValueKey('meal-diary-daily-nutrition-retry')),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('meal-diary-daily-nutrition-summary')),
      findsOneWidget,
    );
    expect(
      _textAtKey(tester, const ValueKey('daily-nutrition-target-calories')),
      '2000',
    );
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

final class _FailingTargetsRepository implements NutritionTargetsRepository {
  bool failReads = true;
  NutritionTargetsData data = const NutritionTargetsData(caloriesKcal: 2000);

  @override
  Future<NutritionTargetsData?> read() async {
    if (failReads) throw StateError('temporary target read failure');
    return data;
  }

  @override
  Future<void> upsert(NutritionTargetsData targets) async {
    targets.validate();
    data = targets;
  }
}

String _textAtKey(WidgetTester tester, Key key) =>
    tester.widget<Text>(find.byKey(key)).data!;
