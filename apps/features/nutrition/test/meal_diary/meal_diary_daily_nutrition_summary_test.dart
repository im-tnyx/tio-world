import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tio_core/core.dart';
import 'package:tio_feature_nutrition/nutrition.dart';
import 'package:tio_shared/shared.dart';

void main() {
  testWidgets('shows compact workout-OFF equation and supported nutrient cells',
      (tester) async {
    await _pumpSummary(tester, summary: _summary());

    expect(find.text('Daily Nutrition'), findsNothing);
    expect(find.text('Target - Eaten = Remaining'), findsNothing);
    expect(find.text('−'), findsOneWidget);
    expect(find.text('='), findsOneWidget);
    expect(
      _textAtKey(tester, const ValueKey('daily-nutrition-target-calories')),
      '2000',
    );
    expect(
      _textAtKey(tester, const ValueKey('daily-nutrition-eaten-calories')),
      '800',
    );
    expect(
      _textAtKey(tester, const ValueKey('daily-nutrition-remaining-calories')),
      '1200',
    );
    expect(find.text('Workout'), findsNothing);
    expect(
      find.byKey(const ValueKey('daily-nutrition-carbohydrate-progress')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('daily-nutrition-protein-progress')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('daily-nutrition-fat-progress')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('daily-nutrition-fiber-progress')),
      findsOneWidget,
    );
  });

  testWidgets('preserves signed over-target Remaining truth', (tester) async {
    await _pumpSummary(
      tester,
      summary: _summary(
        calories: 2300,
        carbohydrate: 260,
        protein: 170,
        fat: 80,
        fiber: 35,
      ),
    );

    expect(
      _textAtKey(tester, const ValueKey('daily-nutrition-remaining-calories')),
      '-300',
    );
    expect(find.text('Workout'), findsNothing);
  });

  testWidgets('omits a nutrient cell when consumed truth is unknown',
      (tester) async {
    await _pumpSummary(
      tester,
      summary: _summary(
        consumed: {
          NutrientId.energy: 800,
          NutrientId.carbohydrate: 90,
          NutrientId.protein: 70,
          NutrientId.fat: 30,
        },
      ),
    );

    expect(find.text('Carbs'), findsOneWidget);
    expect(find.text('Protein'), findsOneWidget);
    expect(find.text('Fat'), findsOneWidget);
    expect(find.text('Fiber'), findsNothing);
  });

  testWidgets('omits a nutrient cell when target truth is unknown',
      (tester) async {
    final date = MealLogLocalDate(year: 2026, month: 9, day: 13);
    const targets = NutritionTargetsData(
      caloriesKcal: 2000,
      carbohydrateGrams: 250,
      proteinGrams: 150,
      fatGrams: 70,
      fiberGrams: null,
    );
    await _pumpSummary(
      tester,
      summary: DailyNutritionSummary(
        localDate: date,
        budget: DailyNutritionBudget(
          localDate: date,
          baseTarget: targets,
          strategyAdjustedTarget: targets,
        ),
        consumedTotals: const {
          NutrientId.energy: 800,
          NutrientId.carbohydrate: 90,
          NutrientId.protein: 70,
          NutrientId.fat: 30,
          NutrientId.fiber: 10,
        },
      ),
    );

    expect(find.text('Fiber'), findsNothing);
  });

  for (final mode in [TioThemeMode.light, TioThemeMode.dark]) {
    testWidgets('renders compact card without overflow in ${mode.name} large text',
        (tester) async {
      tester.view.physicalSize = const Size(320, 760);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await _pumpSummary(
        tester,
        summary: _summary(),
        mode: mode,
        textScaler: const TextScaler.linear(1.5),
      );

      expect(
        find.byKey(const ValueKey('meal-diary-daily-nutrition-summary')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });
  }
}

String _textAtKey(WidgetTester tester, Key key) =>
    tester.widget<Text>(find.byKey(key)).data!;

Future<void> _pumpSummary(
  WidgetTester tester, {
  required DailyNutritionSummary summary,
  TioThemeMode mode = TioThemeMode.light,
  TextScaler textScaler = TextScaler.noScaling,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(textScaler: textScaler),
        child: TioTheme(
          config: TioThemeConfig(mode: mode),
          child: child ?? const SizedBox.shrink(),
        ),
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

DailyNutritionSummary _summary({
  num calories = 800,
  num carbohydrate = 90,
  num protein = 70,
  num fat = 30,
  num fiber = 10,
  Map<NutrientId, num>? consumed,
}) {
  final date = MealLogLocalDate(year: 2026, month: 9, day: 13);
  const targets = NutritionTargetsData(
    caloriesKcal: 2000,
    carbohydrateGrams: 250,
    proteinGrams: 150,
    fatGrams: 70,
    fiberGrams: 30,
  );
  return DailyNutritionSummary(
    localDate: date,
    budget: DailyNutritionBudget(
      localDate: date,
      baseTarget: targets,
      strategyAdjustedTarget: targets,
    ),
    consumedTotals: consumed ??
        {
          NutrientId.energy: calories,
          NutrientId.carbohydrate: carbohydrate,
          NutrientId.protein: protein,
          NutrientId.fat: fat,
          NutrientId.fiber: fiber,
        },
  );
}
