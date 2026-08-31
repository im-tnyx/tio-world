import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tio_core/core.dart';
import 'package:tio_feature_nutrition/nutrition.dart';

/// Core five Nutrition Targets editor.
///
/// Covers what a user can actually do to the canonical row: read it truthfully,
/// change one value, be stopped when the row would become incoherent, and never
/// have an untouched target rewritten underneath them.
void main() {
  const recommended = NutritionTargetsData(
    caloriesKcal: 1900,
    proteinGrams: 150,
    carbohydrateGrams: 200,
    fatGrams: 55.6,
    fiberGrams: 28,
    customizationState: NutritionTargetCustomizationState.recommended,
    recommendationMetadata: {'source': 'onboarding', 'bmr': 1600},
  );

  Future<void> pumpPage(
    WidgetTester tester, {
    required NutritionTargetsData targets,
    required Future<void> Function(NutritionTargetsData) onSave,
  }) async {
    tester.view.physicalSize = const Size(390, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(MaterialApp(
      builder: (context, child) =>
          TioTheme(child: child ?? const SizedBox.shrink()),
      home: NutritionTargetsSettingsPage(targets: targets, onSave: onSave),
    ));
    await tester.pumpAndSettle();
  }

  Future<void> openEditor(WidgetTester tester, NutritionTargetField f) async {
    await tester
        .tap(find.byKey(ValueKey('nutrition-target-${f.storageValue}-field')));
    await tester.pumpAndSettle();
  }

  Future<void> type(
    WidgetTester tester,
    NutritionTargetField f,
    String text,
  ) async {
    await tester.enterText(
      find.byKey(ValueKey('nutrition-target-${f.storageValue}-input')),
      text,
    );
    await tester.pumpAndSettle();
  }

  Finder saveOf(NutritionTargetField f) =>
      find.byKey(ValueKey('nutrition-target-${f.storageValue}-save'));

  group('rows', () {
    testWidgets('renders all five core targets with their units',
        (tester) async {
      await pumpPage(tester, targets: recommended, onSave: (_) async {});

      for (final field in NutritionTargetField.values) {
        expect(
          find.byKey(ValueKey('nutrition-target-${field.storageValue}-field')),
          findsOneWidget,
          reason: field.storageValue,
        );
      }

      expect(find.text('1900 kcal'), findsOneWidget);
      expect(find.text('150 g'), findsOneWidget);
      expect(find.text('200 g'), findsOneWidget);
      expect(find.text('55.6 g'), findsOneWidget);
      expect(find.text('28 g'), findsOneWidget);
    });

    testWidgets('an unset target reads as Not set, never as zero',
        (tester) async {
      await pumpPage(
        tester,
        targets: const NutritionTargetsData(),
        onSave: (_) async {},
      );

      expect(find.text('Not set'), findsNWidgets(5));
      expect(find.textContaining('0 kcal'), findsNothing);
      expect(find.textContaining('0 g'), findsNothing);
    });

    testWidgets('additional nutrient goals are not exposed here',
        (tester) async {
      await pumpPage(tester, targets: recommended, onSave: (_) async {});

      for (final absent in [
        'Sodium',
        'Saturated Fat',
        'Trans Fat',
        'Vitamin D',
        'Added Sugar',
        'Cholesterol',
        'Additional Nutrient Goals',
      ]) {
        expect(find.text(absent), findsNothing, reason: absent);
      }
    });
  });

  group('card hierarchy', () {
    testWidgets('Calories, Macronutrients and Fiber are separate sections',
        (tester) async {
      await pumpPage(tester, targets: recommended, onSave: (_) async {});

      final calories = tester.getTopLeft(find.text('DAILY CALORIE GOAL')).dy;
      final macros = tester.getTopLeft(find.text('MACRONUTRIENTS')).dy;
      final fiber = tester.getTopLeft(find.text('FIBER')).dy;

      expect(macros, greaterThan(calories));
      expect(fiber, greaterThan(macros));

      // Fiber must not be grouped with the three energy macros.
      expect(find.byType(NutritionSettingsGroupCard), findsNWidgets(3));
    });

    testWidgets('every row carries a pencil edit affordance', (tester) async {
      await pumpPage(tester, targets: recommended, onSave: (_) async {});

      expect(find.byIcon(Icons.edit_outlined), findsNWidgets(5));
      // A pencil already means "edit"; a chevron beside it would be redundant.
      expect(find.byIcon(Icons.chevron_right_rounded), findsNothing);
    });
  });

  group('derived percentages', () {
    testWidgets('macro rows show a read-only share totalling 100%',
        (tester) async {
      await pumpPage(
        tester,
        targets: const NutritionTargetsData(
          caloriesKcal: 3220,
          proteinGrams: 161,
          carbohydrateGrams: 403,
          fatGrams: 107,
          fiberGrams: 30,
        ),
        onSave: (_) async {},
      );

      expect(find.text('50%'), findsOneWidget);
      expect(find.text('20%'), findsOneWidget);
      expect(find.text('30%'), findsOneWidget);
    });

    testWidgets('Calories and Fiber never show a percentage', (tester) async {
      await pumpPage(
        tester,
        targets: const NutritionTargetsData(
          caloriesKcal: 3220,
          proteinGrams: 161,
          carbohydrateGrams: 403,
          fatGrams: 107,
          fiberGrams: 30,
        ),
        onSave: (_) async {},
      );

      final caloriesRow = tester.widget<NutritionValueRow>(
        find.byKey(const ValueKey('nutrition-target-calories-field')),
      );
      final fiberRow = tester.widget<NutritionValueRow>(
        find.byKey(const ValueKey('nutrition-target-fiber-field')),
      );

      expect(caloriesRow.annotation, isNull);
      expect(fiberRow.annotation, isNull);
    });

    testWidgets('an unknown macro shows no fabricated percentage',
        (tester) async {
      await pumpPage(
        tester,
        targets: const NutritionTargetsData(
          caloriesKcal: 2000,
          proteinGrams: 150,
          carbohydrateGrams: 200,
        ),
        onSave: (_) async {},
      );

      expect(find.textContaining('%'), findsNothing);
      expect(find.text('0%'), findsNothing);
    });

    testWidgets('percentages are display-only and never persisted',
        (tester) async {
      NutritionTargetsData? saved;
      await pumpPage(
        tester,
        targets: const NutritionTargetsData(
          caloriesKcal: 3220,
          proteinGrams: 161,
          carbohydrateGrams: 403,
          fatGrams: 107,
        ),
        onSave: (targets) async => saved = targets,
      );

      await openEditor(tester, NutritionTargetField.fiber);
      await type(tester, NutritionTargetField.fiber, '30');
      await tester.tap(saveOf(NutritionTargetField.fiber));
      await tester.pumpAndSettle();

      // Only the five canonical fields exist; nothing percentage-shaped is
      // written, and no percentage editing surface was introduced.
      expect(saved!.customizedFields, {'fiber'});
      expect(find.text('Percentage'), findsNothing);
      expect(find.text('Grams'), findsNothing);
    });
  });

  group('calories from macros', () {
    testWidgets('shows a quiet informational line when coherent',
        (tester) async {
      await pumpPage(tester, targets: recommended, onSave: (_) async {});

      expect(
        find.byKey(const ValueKey('nutrition-targets-macro-calories')),
        findsOneWidget,
      );
      expect(find.text('Calories from macros'), findsOneWidget);
      expect(find.text('1900.4 kcal'), findsOneWidget);
      // Coherent means nothing to fix, so no warning treatment.
      expect(
        find.byKey(const ValueKey('nutrition-targets-coherence-warning')),
        findsNothing,
      );
    });

    testWidgets('is replaced by the warning when the mismatch is material',
        (tester) async {
      await pumpPage(
        tester,
        targets: const NutritionTargetsData(
          caloriesKcal: 1200,
          proteinGrams: 150,
          carbohydrateGrams: 200,
          fatGrams: 55.6,
        ),
        onSave: (_) async {},
      );

      expect(
        find.byKey(const ValueKey('nutrition-targets-macro-calories')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('nutrition-targets-coherence-warning')),
        findsOneWidget,
      );
    });

    testWidgets('neither appears while the macros are incomplete',
        (tester) async {
      await pumpPage(
        tester,
        targets: const NutritionTargetsData(caloriesKcal: 2000),
        onSave: (_) async {},
      );

      expect(
        find.byKey(const ValueKey('nutrition-targets-macro-calories')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('nutrition-targets-coherence-warning')),
        findsNothing,
      );
    });
  });

  group('editing', () {
    testWidgets('Save stays disabled until the value changes', (tester) async {
      await pumpPage(tester, targets: recommended, onSave: (_) async {});
      await openEditor(tester, NutritionTargetField.fiber);

      expect(
          tester
              .widget<TioButton>(saveOf(NutritionTargetField.fiber))
              .onPressed,
          isNull);

      await type(tester, NutritionTargetField.fiber, '30');
      expect(
          tester
              .widget<TioButton>(saveOf(NutritionTargetField.fiber))
              .onPressed,
          isNotNull);
    });

    testWidgets('a valid edit preserves every untouched field', (tester) async {
      NutritionTargetsData? saved;
      await pumpPage(
        tester,
        targets: recommended,
        onSave: (targets) async => saved = targets,
      );

      await openEditor(tester, NutritionTargetField.fiber);
      await type(tester, NutritionTargetField.fiber, '30');
      await tester.tap(saveOf(NutritionTargetField.fiber));
      await tester.pumpAndSettle();

      expect(saved!.fiberGrams, 30);
      expect(saved!.caloriesKcal, 1900);
      expect(saved!.proteinGrams, 150);
      expect(saved!.carbohydrateGrams, 200);
      expect(saved!.fatGrams, 55.6);
      expect(
          saved!.recommendationMetadata, {'source': 'onboarding', 'bmr': 1600});
      expect(saved!.customizedFields, {'fiber'});
      expect(
          saved!.customizationState, NutritionTargetCustomizationState.mixed);
    });

    testWidgets('blank clears the target to unset rather than zero',
        (tester) async {
      NutritionTargetsData? saved;
      await pumpPage(
        tester,
        targets: recommended,
        onSave: (targets) async => saved = targets,
      );

      await openEditor(tester, NutritionTargetField.fiber);
      await type(tester, NutritionTargetField.fiber, '');
      await tester.tap(saveOf(NutritionTargetField.fiber));
      await tester.pumpAndSettle();

      expect(saved!.fiberGrams, isNull);
    });

    testWidgets('cancelling without Save persists nothing', (tester) async {
      var saves = 0;
      await pumpPage(
        tester,
        targets: recommended,
        onSave: (_) async => saves++,
      );

      await openEditor(tester, NutritionTargetField.protein);
      await type(tester, NutritionTargetField.protein, '999');
      Navigator.of(tester.element(find.byType(TextField))).pop();
      await tester.pumpAndSettle();

      expect(saves, 0);
      expect(find.text('150 g'), findsOneWidget);
    });
  });

  group('validation', () {
    testWidgets('calories must be greater than zero', (tester) async {
      await pumpPage(tester, targets: recommended, onSave: (_) async {});
      await openEditor(tester, NutritionTargetField.calories);
      await type(tester, NutritionTargetField.calories, '0');

      expect(find.text('Calories must be greater than zero.'), findsOneWidget);
      expect(
        tester
            .widget<TioButton>(saveOf(NutritionTargetField.calories))
            .onPressed,
        isNull,
      );
    });

    testWidgets('a value too large to store is blocked', (tester) async {
      await pumpPage(tester, targets: recommended, onSave: (_) async {});
      await openEditor(tester, NutritionTargetField.calories);
      await type(tester, NutritionTargetField.calories, '99999999999');

      // A storage limit, not a health judgement: the column is an integer.
      expect(find.text('That value is too large to store.'), findsOneWidget);
      expect(
        tester
            .widget<TioButton>(saveOf(NutritionTargetField.calories))
            .onPressed,
        isNull,
      );
    });

    testWidgets('an unusually high but storable target is allowed',
        (tester) async {
      NutritionTargetsData? saved;
      await pumpPage(
        tester,
        targets: const NutritionTargetsData(caloriesKcal: 2000),
        onSave: (targets) async => saved = targets,
      );

      await openEditor(tester, NutritionTargetField.calories);
      await type(tester, NutritionTargetField.calories, '9000');
      await tester.tap(saveOf(NutritionTargetField.calories));
      await tester.pumpAndSettle();

      // Recommended is not the same as allowed. No invented upper bound blocks
      // a legitimately unusual target.
      expect(saved!.caloriesKcal, 9000);
    });

    testWidgets('zero is a valid macro target', (tester) async {
      NutritionTargetsData? saved;
      await pumpPage(
        tester,
        targets: const NutritionTargetsData(fiberGrams: 20),
        onSave: (targets) async => saved = targets,
      );

      await openEditor(tester, NutritionTargetField.fiber);
      await type(tester, NutritionTargetField.fiber, '0');
      await tester.tap(saveOf(NutritionTargetField.fiber));
      await tester.pumpAndSettle();

      expect(saved!.fiberGrams, 0);
      expect(saved!.fiberGrams, isNot(isNull));
    });
  });

  group('coherence', () {
    testWidgets(
        'a mismatch over the tolerance blocks Save and shows both sides',
        (tester) async {
      var saves = 0;
      await pumpPage(
        tester,
        targets: recommended,
        onSave: (_) async => saves++,
      );

      await openEditor(tester, NutritionTargetField.calories);
      await type(tester, NutritionTargetField.calories, '1200');
      await tester.tap(saveOf(NutritionTargetField.calories));
      await tester.pumpAndSettle();

      expect(saves, 0);
      final error = tester.widget<Text>(
        find.byKey(const ValueKey('nutrition-target-editor-error')),
      );
      expect(error.data, contains('1200'));
      expect(error.data, contains('1900.4'));
      expect(error.data, contains('700.4'));
    });

    testWidgets('a change within the tolerance saves', (tester) async {
      NutritionTargetsData? saved;
      await pumpPage(
        tester,
        targets: recommended,
        onSave: (targets) async => saved = targets,
      );

      await openEditor(tester, NutritionTargetField.calories);
      await type(tester, NutritionTargetField.calories, '1902');
      await tester.tap(saveOf(NutritionTargetField.calories));
      await tester.pumpAndSettle();

      expect(saved!.caloriesKcal, 1902);
    });

    testWidgets('a partial row is never falsely blocked', (tester) async {
      NutritionTargetsData? saved;
      await pumpPage(
        tester,
        targets: const NutritionTargetsData(),
        onSave: (targets) async => saved = targets,
      );

      await openEditor(tester, NutritionTargetField.calories);
      await type(tester, NutritionTargetField.calories, '2200');
      await tester.tap(saveOf(NutritionTargetField.calories));
      await tester.pumpAndSettle();

      // Macros are unknown, so there is nothing to compare against.
      expect(saved!.caloriesKcal, 2200);
      expect(find.byKey(const ValueKey('nutrition-target-editor-error')),
          findsNothing);
    });

    testWidgets('an incoherent stored row warns on the page itself',
        (tester) async {
      await pumpPage(
        tester,
        targets: const NutritionTargetsData(
          caloriesKcal: 1200,
          proteinGrams: 150,
          carbohydrateGrams: 200,
          fatGrams: 55.6,
        ),
        onSave: (_) async {},
      );

      expect(
        find.byKey(const ValueKey('nutrition-targets-coherence-warning')),
        findsOneWidget,
      );
      expect(find.text('1200 kcal'), findsWidgets);
    });
  });

  testWidgets('a failed save keeps the sheet open and is retryable',
      (tester) async {
    await pumpPage(
      tester,
      targets: recommended,
      onSave: (_) async => throw Exception('offline'),
    );

    await openEditor(tester, NutritionTargetField.fiber);
    await type(tester, NutritionTargetField.fiber, '31');
    await tester.tap(saveOf(NutritionTargetField.fiber));
    await tester.pumpAndSettle();

    expect(
        find.byKey(const ValueKey('nutrition-editor-sheet')), findsOneWidget);
    expect(
      find.text("Couldn't save. Check your connection and try again."),
      findsOneWidget,
    );
    expect(
        tester.widget<TioButton>(saveOf(NutritionTargetField.fiber)).onPressed,
        isNotNull);
  });
}
