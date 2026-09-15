import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tio_core/core.dart';
import 'package:tio_feature_nutrition/nutrition.dart';

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
}
