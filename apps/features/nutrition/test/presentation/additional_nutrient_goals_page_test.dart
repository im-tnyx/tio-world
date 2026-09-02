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
    // A nullable parameter cannot distinguish "not specified" from "explicitly
    // absent", and defaulting a null back to an adult date of birth silently
    // turns a no-DOB test into an adult one.
    bool withoutDateOfBirth = false,
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
        dateOfBirth: withoutDateOfBirth ? null : (dateOfBirth ?? adultDob),
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
        withoutDateOfBirth: true,
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

  group('sodium comparator (review finding 2)', () {
    testWidgets('the row carries the strict comparator, not a bare boundary',
        (tester) async {
      await pumpPage(
        tester,
        goals: const AdditionalNutrientGoalSet.empty().withGoal(
          const AdditionalNutrientGoal(nutrientId: NutrientId.sodium),
        ),
      );

      expect(
        find.text('< 2000 mg'),
        findsOneWidget,
        reason: 'A bare "2000 mg" presents the forbidden boundary as the goal.',
      );
      expect(find.text('2000 mg'), findsNothing);
    });

    testWidgets('a custom sodium value keeps the comparator too',
        (tester) async {
      await pumpPage(
        tester,
        goals: const AdditionalNutrientGoalSet.empty().withGoal(
          const AdditionalNutrientGoal(
            nutrientId: NutrientId.sodium,
            customValue: 1500,
          ),
        ),
      );

      // The comparator belongs to the nutrient's policy, not to where the
      // number came from.
      expect(find.text('< 1500 mg'), findsOneWidget);
    });

    testWidgets('nutrients without a strict boundary show no comparator',
        (tester) async {
      await pumpPage(
        tester,
        goals: const AdditionalNutrientGoalSet.empty().withGoal(
          const AdditionalNutrientGoal(nutrientId: NutrientId.vitaminD),
        ),
      );

      expect(find.text('15 mcg'), findsOneWidget);
      expect(find.text('< 15 mcg'), findsNothing);
    });
  });

  group('custom value precision (review finding 1)', () {
    testWidgets(
        'a fractional value below the display default is not shown as 0',
        (tester) async {
      await pumpPage(
        tester,
        goals: const AdditionalNutrientGoalSet.empty().withGoal(
          const AdditionalNutrientGoal(
            nutrientId: NutrientId.transFat,
            customValue: 0.04,
          ),
        ),
      );

      expect(
        find.text('0 g'),
        findsNothing,
        reason: 'Rendering a real 0.04 g goal as "0 g" misreports it, and zero '
            'has its own distinct meaning here.',
      );
      expect(find.text('0.04 g'), findsOneWidget);
    });

    testWidgets('reopening and saving does not change the stored value',
        (tester) async {
      for (final value in <double>[0.04, 0.45, 1.25, 12.345, 0.001]) {
        saved = [];
        await pumpPage(
          tester,
          goals: const AdditionalNutrientGoalSet.empty().withGoal(
            AdditionalNutrientGoal(
              nutrientId: NutrientId.transFat,
              customValue: value,
            ),
          ),
        );

        await tester.tap(rowFor(NutrientId.transFat));
        await tester.pumpAndSettle();

        // Save without touching the field: the round trip must be lossless.
        await tester.tap(find.byKey(const ValueKey(
          'additional-nutrient-goal-save',
        )));
        await tester.pumpAndSettle();

        expect(
          saved.single[NutrientId.transFat]!.customValue,
          value,
          reason: 'Reopening and saving silently rewrote $value',
        );
      }
    });

    testWidgets('the editor prefills the exact stored value', (tester) async {
      await pumpPage(
        tester,
        goals: const AdditionalNutrientGoalSet.empty().withGoal(
          const AdditionalNutrientGoal(
            nutrientId: NutrientId.transFat,
            customValue: 0.45,
          ),
        ),
      );

      await tester.tap(rowFor(NutrientId.transFat));
      await tester.pumpAndSettle();

      expect(find.text('0.45'), findsOneWidget);
      expect(find.text('0.5'), findsNothing);
    });
  });

  group('unsupported future schema (review finding 3)', () {
    testWidgets('renders a read-only notice instead of editable rows',
        (tester) async {
      await pumpPage(
        tester,
        goals: const AdditionalNutrientGoalSet.unsupported(),
      );

      expect(
        find.byKey(const ValueKey('additional-nutrient-unsupported-schema')),
        findsOneWidget,
      );
      expect(
        find.text('Not set'),
        findsNothing,
        reason: 'Newer-schema data must not masquerade as unconfigured goals.',
      );
    });

    testWidgets('offers no row to tap, so no edit can be started',
        (tester) async {
      await pumpPage(
        tester,
        goals: const AdditionalNutrientGoalSet.unsupported(),
      );

      for (final nutrientId in [
        NutrientId.saturatedFat,
        NutrientId.transFat,
        NutrientId.sodium,
        NutrientId.vitaminD,
      ]) {
        expect(rowFor(nutrientId), findsNothing, reason: '$nutrientId');
      }
      expect(
        find.byKey(const ValueKey('additional-nutrient-goal-input')),
        findsNothing,
      );
      expect(saved, isEmpty);
    });
  });

  group('unavailable recommendation (frozen owner decision)', () {
    testWidgets('an unconfigured nutrient cannot be turned on', (tester) async {
      await pumpPage(tester, dateOfBirth: minorDob);
      await tester.tap(rowFor(NutrientId.vitaminD));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('additional-nutrient-goal-enable')),
        findsNothing,
        reason: 'Turning it on would create a goal that cannot be set.',
      );
      expect(
        find.byKey(const ValueKey('additional-nutrient-goal-input')),
        findsNothing,
        reason: 'A custom value must not bypass the eligibility rule.',
      );
      expect(
        find.byKey(const ValueKey('additional-nutrient-goal-guidance')),
        findsOneWidget,
      );
      expect(saved, isEmpty, reason: 'Nothing may be written.');
    });

    testWidgets('an already-configured custom goal keeps and shows its value',
        (tester) async {
      await pumpPage(
        tester,
        withoutDateOfBirth: true,
        goals: const AdditionalNutrientGoalSet.empty().withGoal(
          const AdditionalNutrientGoal(
            nutrientId: NutrientId.vitaminD,
            customValue: 18,
          ),
        ),
      );
      await tester.tap(rowFor(NutrientId.vitaminD));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('additional-nutrient-goal-preserved-custom')),
        findsOneWidget,
      );
      expect(find.text('18 mcg'), findsWidgets);
      expect(
        find.byKey(const ValueKey('additional-nutrient-goal-use-recommended')),
        findsNothing,
        reason: 'There is no recommendation to revert to.',
      );
    });

    testWidgets('an already-configured goal can still be turned off',
        (tester) async {
      await pumpPage(
        tester,
        withoutDateOfBirth: true,
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
        'additional-nutrient-goal-remove',
      )));
      await tester.pumpAndSettle();

      expect(saved.single.contains(NutrientId.vitaminD), isFalse);
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
      // Zero is a valid goal, so the copy must not imply it is rejected.
      expect(find.textContaining('more than zero'), findsNothing);
      expect(
          find.textContaining('Enter zero or a higher number'), findsOneWidget);
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
