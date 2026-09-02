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

  /// Each entry is one nutrient delta, matching the repository contract.
  late List<(NutrientId, AdditionalNutrientGoal?)> saved;

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
    Future<void> Function(NutrientId, AdditionalNutrientGoal?)? onSave,
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
        onSave: onSave ??
            (nutrientId, goal) async => saved.add((nutrientId, goal)),
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
          saved.single.$2!.customValue,
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

  group('Not set -> Recommended (review finding 6)', () {
    testWidgets('an unconfigured nutrient can opt into the recommendation',
        (tester) async {
      await pumpPage(tester);
      await tester.tap(rowFor(NutrientId.vitaminD));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('additional-nutrient-goal-use-recommended')),
        findsOneWidget,
        reason: 'Reaching the Recommended state must not require inventing a '
            'Custom value first.',
      );
    });

    testWidgets('it writes a key with a null custom value, fabricating nothing',
        (tester) async {
      await pumpPage(tester);
      await tester.tap(rowFor(NutrientId.vitaminD));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey(
        'additional-nutrient-goal-use-recommended',
      )));
      await tester.pumpAndSettle();

      final (nutrientId, goal) = saved.single;
      expect(nutrientId, NutrientId.vitaminD);
      expect(
        goal!.customValue,
        isNull,
        reason: 'custom_value null is the stored Recommended state.',
      );
      expect(goal.usesRecommendation, isTrue);
    });

    testWidgets('the resulting row reads Recommended, not Custom',
        (tester) async {
      // Re-render with the set the save above would have produced.
      await pumpPage(
        tester,
        goals: const AdditionalNutrientGoalSet.empty().withGoal(
          const AdditionalNutrientGoal(nutrientId: NutrientId.vitaminD),
        ),
      );

      expect(find.text('Recommended'), findsOneWidget);
      expect(find.text('Custom'), findsNothing);
      expect(find.text('15 mcg'), findsOneWidget);
    });

    testWidgets('a goal already on the recommendation offers no repeat action',
        (tester) async {
      await pumpPage(
        tester,
        goals: const AdditionalNutrientGoalSet.empty().withGoal(
          const AdditionalNutrientGoal(nutrientId: NutrientId.vitaminD),
        ),
      );
      await tester.tap(rowFor(NutrientId.vitaminD));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('additional-nutrient-goal-use-recommended')),
        findsNothing,
        reason: 'It is already in that state; the action would change nothing.',
      );
    });

    testWidgets('an unavailable recommendation still offers no enable action',
        (tester) async {
      await pumpPage(tester, dateOfBirth: minorDob);
      await tester.tap(rowFor(NutrientId.vitaminD));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('additional-nutrient-goal-use-recommended')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('additional-nutrient-goal-enable')),
        findsNothing,
      );
      expect(saved, isEmpty);
    });
  });

  group('nutrient-aware unavailable guidance (review finding 7)', () {
    Future<String> guidanceFor(
      WidgetTester tester,
      NutrientId nutrientId, {
      int? caloriesKcal = 2000,
      DateTime? dateOfBirth,
      bool withoutDateOfBirth = false,
    }) async {
      await pumpPage(
        tester,
        caloriesKcal: caloriesKcal,
        dateOfBirth: dateOfBirth,
        withoutDateOfBirth: withoutDateOfBirth,
      );
      await tester.tap(rowFor(nutrientId));
      await tester.pumpAndSettle();

      // Guidance is the canonical sheet's own supporting-text slot, so read
      // it off the component rather than from a feature-owned Text.
      return tester
          .widget<TioEditorSheet>(find.byType(TioEditorSheet))
          .supportingText!;
    }

    testWidgets('sodium never mentions Calories, which its rule does not use',
        (tester) async {
      final guidance = await guidanceFor(
        tester,
        NutrientId.sodium,
        withoutDateOfBirth: true,
      );

      expect(guidance, contains('date of birth'));
      expect(
        guidance.toLowerCase(),
        isNot(contains('calorie')),
        reason: 'Sodium is a fixed amount gated on age alone.',
      );
    });

    testWidgets('vitamin D never mentions Calories either', (tester) async {
      final guidance = await guidanceFor(
        tester,
        NutrientId.vitaminD,
        caloriesKcal: null,
        withoutDateOfBirth: true,
      );

      expect(guidance.toLowerCase(), isNot(contains('calorie')));
    });

    testWidgets('a calorie-derived nutrient names the Calories target',
        (tester) async {
      final guidance = await guidanceFor(
        tester,
        NutrientId.saturatedFat,
        caloriesKcal: null,
      );

      expect(guidance, contains('Calories target'));
      expect(
        guidance,
        isNot(contains('date of birth')),
        reason: 'The date of birth is present and fine; only Calories blocks.',
      );
    });

    testWidgets('under 19 states eligibility without blaming the date',
        (tester) async {
      final guidance = await guidanceFor(
        tester,
        NutrientId.vitaminD,
        dateOfBirth: minorDob,
      );

      expect(guidance, contains('ages 19 and over'));
      expect(
        guidance,
        isNot(contains('Add your date of birth')),
        reason: 'The date of birth is known and correct; nothing to fix.',
      );
      expect(guidance.toLowerCase(), isNot(contains('calorie')));
    });

    testWidgets('a calorie nutrient with no date of birth names both inputs',
        (tester) async {
      final guidance = await guidanceFor(
        tester,
        NutrientId.transFat,
        caloriesKcal: null,
        withoutDateOfBirth: true,
      );

      expect(guidance, contains('date of birth'));
      expect(guidance, contains('Calories target'));
    });

    testWidgets('no unavailable state allows enabling anything',
        (tester) async {
      for (final (nutrientId, calories, noDob) in <(NutrientId, int?, bool)>[
        (NutrientId.sodium, 2000, true),
        (NutrientId.vitaminD, 2000, true),
        (NutrientId.saturatedFat, null, false),
        (NutrientId.transFat, null, true),
      ]) {
        saved = [];
        await pumpPage(
          tester,
          caloriesKcal: calories,
          withoutDateOfBirth: noDob,
        );
        await tester.tap(rowFor(nutrientId));
        await tester.pumpAndSettle();

        expect(
          find.byKey(
            const ValueKey('additional-nutrient-goal-use-recommended'),
          ),
          findsNothing,
          reason: '$nutrientId',
        );
        expect(
          find.byKey(const ValueKey('additional-nutrient-goal-input')),
          findsNothing,
          reason: '$nutrientId',
        );
        expect(saved, isEmpty, reason: '$nutrientId');

        await tester.tap(find.byType(BackButton).first);
        await tester.pumpAndSettle();
      }
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
        tester
            .widget<TioEditorSheet>(find.byType(TioEditorSheet))
            .supportingText,
        isNotNull,
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

      expect(saved.single.$1, NutrientId.vitaminD);
      expect(saved.single.$2, isNull, reason: 'A null goal removes it.');
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

      expect(saved.single.$2!.customValue, 18);
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

      expect(saved.single.$2!.customValue, 0);
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

      final (nutrientId, goal) = saved.single;
      expect(nutrientId, NutrientId.vitaminD);
      expect(goal!.customValue, isNull);
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

      expect(saved.single.$1, NutrientId.sodium);
      expect(saved.single.$2, isNull, reason: 'A null goal removes it.');
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
        tester
            .widget<TioEditorSheet>(find.byType(TioEditorSheet))
            .supportingText,
        isNotNull,
      );
    });

    testWidgets('a failed save keeps the sheet open and reports the error',
        (tester) async {
      await pumpPage(
        tester,
        onSave: (_, __) async => throw StateError('offline'),
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

  group('canonical editor surface (Codex finding: TioEditorSheet)', () {
    testWidgets('the editor is the canonical sheet, not a raw column',
        (tester) async {
      await pumpPage(tester);
      await tester.tap(rowFor(NutrientId.vitaminD));
      await tester.pumpAndSettle();

      // The chrome this asserts is what keeps Save reachable above a raised
      // keyboard: the sheet owns viewInsets padding, the scrollable body and
      // the pinned action region.
      expect(find.byType(TioEditorSheet), findsOneWidget);
      expect(find.byKey(const ValueKey('tio-editor-sheet')), findsOneWidget);
    });

    testWidgets('the title and guidance use the canonical slots',
        (tester) async {
      await pumpPage(tester);
      await tester.tap(rowFor(NutrientId.vitaminD));
      await tester.pumpAndSettle();

      final sheet = tester.widget<TioEditorSheet>(find.byType(TioEditorSheet));
      expect(sheet.title, 'Vitamin D');
      expect(sheet.supportingText, contains('Recommended'));
    });

    testWidgets('the commit actions are pinned outside the scroll view',
        (tester) async {
      await pumpPage(tester);
      await tester.tap(rowFor(NutrientId.vitaminD));
      await tester.pumpAndSettle();

      final sheet = tester.widget<TioEditorSheet>(find.byType(TioEditorSheet));
      expect(sheet.actions, isNotNull);
      expect(
        find.descendant(
          of: find.byType(SingleChildScrollView),
          matching: find.byKey(const ValueKey('additional-nutrient-goal-save')),
        ),
        findsNothing,
        reason: 'Save inside the scroll view can fall below the fold.',
      );
    });
  });

  group('locale decimal separator (Codex finding)', () {
    testWidgets('a comma decimal is accepted and normalised', (tester) async {
      await pumpPage(tester);
      await tester.tap(rowFor(NutrientId.saturatedFat));
      await tester.pumpAndSettle();

      // What a comma-decimal keyboard sends for 22.5.
      await tester.enterText(
        find.byKey(const ValueKey('additional-nutrient-goal-input')),
        '22,5',
      );
      await tester.tap(find.byKey(const ValueKey(
        'additional-nutrient-goal-save',
      )));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('additional-nutrient-goal-error')),
        findsNothing,
      );
      expect(saved.single.$2!.customValue, 22.5);
    });

    testWidgets('the field does not silently drop the typed comma',
        (tester) async {
      await pumpPage(tester);
      await tester.tap(rowFor(NutrientId.saturatedFat));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const ValueKey('additional-nutrient-goal-input')),
        '22,5',
      );
      await tester.pump();

      expect(
        tester
            .widget<EditableText>(find.byType(EditableText).first)
            .controller
            .text,
        '22,5',
        reason: 'A stripped comma would turn 22,5 into an unintended 225.',
      );
    });
  });

  group('very small custom values (Codex finding)', () {
    testWidgets('a value far below the display default is never shown as 0',
        (tester) async {
      await pumpPage(
        tester,
        goals: const AdditionalNutrientGoalSet.empty().withGoal(
          const AdditionalNutrientGoal(
            nutrientId: NutrientId.saturatedFat,
            customValue: 0.0000001,
          ),
        ),
      );

      expect(
        find.text('0 g'),
        findsNothing,
        reason: 'An explicit zero means something else entirely here.',
      );
      expect(find.text('0.0000001 g'), findsOneWidget);
    });

    test('formatting stays nonzero past fixed notation', () {
      // Smaller than toStringAsFixed can express at all: the fallback is
      // Dart's shortest round-trippable form rather than a misleading "0".
      final text = formatNutrientAmount(NutrientId.saturatedFat, 1e-21);

      expect(text, isNot('0 g'));
      expect(double.parse(text.split(' ').first), 1e-21);
    });

    test('an explicit zero still formats as zero', () {
      expect(formatNutrientAmount(NutrientId.saturatedFat, 0), '0 g');
    });
  });
}
