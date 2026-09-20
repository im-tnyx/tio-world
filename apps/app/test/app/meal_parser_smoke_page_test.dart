import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tio_app/app/meal_parser_smoke_page.dart';
import 'package:tio_core/core.dart';
import 'package:tio_feature_nutrition/nutrition.dart';
import 'package:tio_shared/shared.dart';

void main() {
  testWidgets(
    'Open Food Facts capability renders bounded provenance and nutrition',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) =>
              TioTheme(child: child ?? const SizedBox.shrink()),
          home: MealParserSmokePage(
            repository: _UnusedMealTextParseRepository(),
            runOpenFoodFactsProbe: () async => {
              'synthetic': true,
              'provider': 'open_food_facts',
              'results': [
                {
                  'query': 'plain yogurt',
                  'category': 'resolved',
                  'productName': 'Plain Yogurt',
                  'per100g': {
                    'energyKcal': 61,
                    'proteinG': 3.5,
                    'carbsG': 4.7,
                    'fatG': 3.3,
                  },
                },
                {
                  'query': 'dahi',
                  'category': 'unavailable',
                },
              ],
            },
          ),
        ),
      );

      await tester.tap(find.text('Open Food Facts capability'));
      await tester.pumpAndSettle();

      expect(
        find.text(
          'plain yogurt: resolved | Plain Yogurt | '
          '61 kcal, P 3.5g, C 4.7g, F 3.3g /100g',
        ),
        findsOneWidget,
      );
      expect(find.text('dahi: unavailable'), findsOneWidget);
      expect(find.textContaining('token'), findsNothing);
      expect(find.textContaining('http'), findsNothing);
    },
  );

  testWidgets(
    'Open Food Facts capability fails closed on malformed response',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) =>
              TioTheme(child: child ?? const SizedBox.shrink()),
          home: MealParserSmokePage(
            repository: _UnusedMealTextParseRepository(),
            runOpenFoodFactsProbe: () async => {
              'results': 'invalid',
            },
          ),
        ),
      );

      await tester.tap(find.text('Open Food Facts capability'));
      await tester.pumpAndSettle();

      expect(
        find.text('Open Food Facts capability probe failed safely.'),
        findsOneWidget,
      );
    },
  );
}

final class _UnusedMealTextParseRepository implements MealTextParseRepository {
  @override
  Future<MealLoggingDraft> parseMealText(String text) {
    throw UnimplementedError('Meal parser is not used by these widget tests.');
  }
}
