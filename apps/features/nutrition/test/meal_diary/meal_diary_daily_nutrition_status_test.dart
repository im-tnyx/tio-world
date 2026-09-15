import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tio_core/core.dart';
import 'package:tio_feature_nutrition/nutrition.dart';
import 'package:tio_shared/shared.dart';

void main() {
  testWidgets('error status uses the governed ghost retry action',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          builder: (context, child) => TioTheme(
            config: const TioThemeConfig(mode: TioThemeMode.light),
            child: child ?? const SizedBox.shrink(),
          ),
          home: const Scaffold(
            body: MealDiaryDailyNutritionSummaryStatus.error(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final retryFinder =
        find.byKey(const ValueKey('meal-diary-daily-nutrition-retry'));
    expect(retryFinder, findsOneWidget);

    final retry = tester.widget<TioButton>(retryFinder);
    expect(retry.variant, TioButtonVariant.ghost);
    expect(retry.label, 'Retry');

    await tester.tap(retryFinder);
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  testWidgets('over-target macro semantics announce the raw exact percentage',
      (tester) async {
    final semanticsHandle = tester.ensureSemantics();
    try {
      final date = MealLogLocalDate(year: 2026, month: 9, day: 13);
      const targets = NutritionTargetsData(
        caloriesKcal: 2000,
        carbohydrateGrams: 250,
        proteinGrams: 150,
        fatGrams: 70,
        fiberGrams: 30,
      );
      final summary = DailyNutritionSummary(
        localDate: date,
        budget: DailyNutritionBudget(
          localDate: date,
          baseTarget: targets,
          strategyAdjustedTarget: targets,
        ),
        consumedTotals: const {
          NutrientId.energy: 2300,
          NutrientId.carbohydrate: 260,
          NutrientId.protein: 170,
          NutrientId.fat: 80,
          NutrientId.fiber: 35,
        },
      );

      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => TioTheme(
            config: const TioThemeConfig(mode: TioThemeMode.light),
            child: child ?? const SizedBox.shrink(),
          ),
          home: Scaffold(body: MealDiaryDailyNutritionSummary(summary: summary)),
        ),
      );
      await tester.pumpAndSettle();

      final carbsSemantics =
          find.bySemanticsLabel('Carbs, 260 g consumed, 250 g target');
      expect(carbsSemantics, findsOneWidget);
      expect(tester.getSemantics(carbsSemantics).value, '104 percent');

      final progress = tester.widget<LinearProgressIndicator>(
        find.byKey(const ValueKey('daily-nutrition-carbohydrate-progress')),
      );
      expect(progress.value, 1);
    } finally {
      semanticsHandle.dispose();
    }
  });
}
