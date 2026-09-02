import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tio_core/core.dart';
import 'package:tio_feature_nutrition/nutrition.dart';
import 'package:tio_shared/shared.dart';

/// Additional Nutrient Goals screen.
///
/// The four row states the product depends on are Not set, Recommended,
/// Custom, and Unavailable. The screen must never invent a value it could not
/// derive, and must never lose an override the user already saved.
void main() {
  final now = DateTime(2026, 9, 2);
  final adultDob = DateTime(1990, 1, 1);
  final minorDob = DateTime(2015, 1, 1);

  late List<AdditionalNutrientGoalSet> saved;

  setUp(() => saved = []);

  Future<void> pumpPage(
    WidgetTester tester, {
    AdditionalNutrientGoalSet goals = const AdditionalNutrientGoalSet.empty(),
    int? caloriesKcal = 2000,
    DateTime? dateOfBirth,
    Future<void> Function(AdditionalNutrientGoalSet)? onSave,
  }) async {
    tester.view.physicalSize = const Size(390, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(MaterialApp(
      builder: (context, child) =>
          TioTheme(child: child ?? const SizedBox.shrink()),
      home: AdditionalNutrientGoalsPage(
        goals: goals,
        caloriesKcal: caloriesKcal,
        dateOfBirth: dateOfBirth ?? adultDob,
        now: now,
        onSave: onSave ?? (updated) async => saved.add(updated),
      ),
    ));
    await tester.pumpAndSettle();
  }

  Finder rowFor(NutrientId nutrientId) => find
      .byKey(ValueKey('additional-nutrient-${nutrientId.storageValue}-field'));

  group('row states', () {
    testWidgets('shows only the four authorized nutrients', (tester) async {
      await pumpPage(tester);

      expect(find.text('Saturated Fat'), findsOneWidget);
      expect(find.text('Trans Fat'), findsOneWidget);
      expect(find.text('Sodium'), findsOneWidget);
      expect(find.text('Vitamin D'), findsOneWidget);

      for (final excluded in ['Added Sugar', 'Cholesterol', 'Potassium']) {
        expect(find.text(excluded), findsNothing);
      }
    });

    testWidgets('an unconfigured nutrient reads as Not set', (tester) async {
      await pumpPage(tester);

      expect(find.text('Not set'), findsNWidgets(4));
      expect(find.text('Recommended'), findsNothing);
      expect(find.text('Custom'), findsNothing);
    });

    testWidgets('a nutrient on the recommendation shows the derived value',
        (tester) async {
      await pumpPage(
        tester,
        goals: const AdditionalNutrientGoalSet.empty().withGoal(
          const AdditionalNutrientGoal(nutrientId: NutrientId.saturatedFat),
        ),
      );

      // 10% of 2000 kcal at 9 kcal/g is 22.22..., displayed to one decimal.
      expect(find.text('22.2 g'), findsOneWidget);
      expect(find.text('Recommended'), findsOneWidget);
    });

    testWidgets('a custom override shows the override, not the recommendation',
        (tester) async {
      await pumpPage(
        tester,
        goals: const AdditionalNutrientGoalSet.empty().withGoal(
          const AdditionalNutrientGoal(
            nutrientId: NutrientId.vitaminD,
            customValue: 18,
          ),
        ),
      );

      expect(find.text('18 mcg'), findsOneWidget);
      expect(find.text('Custom'), findsOneWidget);
      expect(find.text('15 mcg'), findsNothing);
    });

    testWidgets('an explicit zero renders as zero, not as unset',
        (tester) async {
      await pumpPage(
        tester,
        goals: const AdditionalNutrientGoalSet.empty().withGoal(
          const AdditionalNutrientGoal(
            nutrientId: NutrientId.transFat,
            customValue: 0,
          ),
        ),
      );

      expect(find.text('0 g'), findsOneWidget);
      expect(find.text('Custom'), findsOneWidget);
    });

    testWidgets('an underivable recommendation reads as Unavailable',
        (tester) async {
      await pumpPage(
        tester,
        caloriesKcal: null,
        goals: const AdditionalNutrientGoalSet.empty().withGoal(
          const AdditionalNutrientGoal(nutrientId: NutrientId.saturatedFat),
        ),
      );

      expect(find.text('Unavailable'), findsOneWidget);
      expect(find.text('Recommended'), findsNothing);
    });

    testWidgets('a saved override survives the recommendation going away',
        (tester) async {
      await pumpPage(
        tester,
        dateOfBirth: null,
        goals: const AdditionalNutrientGoalSet.empty().withGoal(
          const AdditionalNutrientGoal(
            nutrientId: NutrientId.vitaminD,
            customValue: 18,
          ),
        ),
      );

      expect(
        find.text('18 mcg'),
        findsOneWidget,
        reason: 'A missing date of birth must not erase user intent.',
      );
    });

    testWidgets('the Vitamin D band follows age', (tester) async {
      await pumpPage(
        tester,
        dateOfBirth: DateTime(1950, 1, 1), // 76 on the fixed clock
        goals: const AdditionalNutrientGoalSet.empty().withGoal(
          const AdditionalNutrientGoal(nutrientId: NutrientId.vitaminD),
        ),
      );

      expect(find.text('20 mcg'), findsOneWidget);
    });
  });

  group('editor', () {
    testWidgets('states the strict sodium boundary in words', (tester) async {
      await pumpPage(tester);
      await tester.tap(rowFor(NutrientId.sodium));
      await tester.pumpAndSettle();

      expect(
        find.textContaining('less than 2,000 mg/day'),
        findsOneWidget,
        reason: 'Sodium is a strict boundary, never "at most".',
      );
    });

    testWidgets('states the at-most wording for the derived maxima',
        (tester) async {
      await pumpPage(tester);
      await tester.tap(rowFor(NutrientId.saturatedFat));
      await tester.pumpAndSettle();

      expect(find.textContaining('at most'), findsOneWidget);
    });

    testWidgets('saves a custom override', (tester) async {
      await pumpPage(tester);
      await tester.tap(rowFor(NutrientId.vitaminD));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const ValueKey('additional-nutrient-goal-input')),
        '18',
      );
      await tester.tap(find.byKey(const ValueKey(
        'additional-nutrient-goal-save',
      )));
      await tester.pumpAndSettle();

      expect(saved.single[NutrientId.vitaminD]!.customValue, 18);
    });

    testWidgets('saves an explicit zero rather than rejecting it',
        (tester) async {
      await pumpPage(tester);
      await tester.tap(rowFor(NutrientId.transFat));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const ValueKey('additional-nutrient-goal-input')),
        '0',
      );
      await tester.tap(find.byKey(const ValueKey(
        'additional-nutrient-goal-save',
      )));
      await tester.pumpAndSettle();

      expect(saved.single[NutrientId.transFat]!.customValue, 0);
    });

    testWidgets('rejects a non-numeric value without saving', (tester) async {
      await pumpPage(tester);
      await tester.tap(rowFor(NutrientId.sodium));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const ValueKey('additional-nutrient-goal-input')),
        '',
      );
      await tester.tap(find.byKey(const ValueKey(
        'additional-nutrient-goal-save',
      )));
      await tester.pumpAndSettle();

      expect(saved, isEmpty);
      expect(
        find.byKey(const ValueKey('additional-nutrient-goal-error')),
        findsOneWidget,
      );
    });

    testWidgets('Use Recommended clears the override but keeps the goal',
        (tester) async {
      await pumpPage(
        tester,
        goals: const AdditionalNutrientGoalSet.empty().withGoal(
          const AdditionalNutrientGoal(
            nutrientId: NutrientId.vitaminD,
            customValue: 18,
          ),
        ),
      );
      await tester.tap(rowFor(NutrientId.vitaminD));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey(
        'additional-nutrient-goal-use-recommended',
      )));
      await tester.pumpAndSettle();

      final result = saved.single;
      expect(result.contains(NutrientId.vitaminD), isTrue);
      expect(result[NutrientId.vitaminD]!.customValue, isNull);
    });

    testWidgets('Turn off removes the goal', (tester) async {
      await pumpPage(
        tester,
        goals: const AdditionalNutrientGoalSet.empty().withGoal(
          const AdditionalNutrientGoal(nutrientId: NutrientId.sodium),
        ),
      );
      await tester.tap(rowFor(NutrientId.sodium));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey(
        'additional-nutrient-goal-remove',
      )));
      await tester.pumpAndSettle();

      expect(saved.single.contains(NutrientId.sodium), isFalse);
    });

    testWidgets('offers no value entry when the recommendation is underivable',
        (tester) async {
      await pumpPage(tester, dateOfBirth: minorDob);
      await tester.tap(rowFor(NutrientId.vitaminD));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('additional-nutrient-goal-input')),
        findsNothing,
        reason: 'A custom value must not be used to bypass eligibility.',
      );
      expect(
        find.byKey(const ValueKey('additional-nutrient-goal-guidance')),
        findsOneWidget,
      );
    });

    testWidgets('a failed save keeps the sheet open and reports the error',
        (tester) async {
      await pumpPage(
        tester,
        onSave: (_) async => throw StateError('offline'),
      );
      await tester.tap(rowFor(NutrientId.vitaminD));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const ValueKey('additional-nutrient-goal-input')),
        '18',
      );
      await tester.tap(find.byKey(const ValueKey(
        'additional-nutrient-goal-save',
      )));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('additional-nutrient-goal-error')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('additional-nutrient-goal-save')),
        findsOneWidget,
        reason: 'The editor stays open so the user can retry.',
      );
    });
  });
}
