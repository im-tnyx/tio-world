import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tio_core/core.dart';
import 'package:tio_feature_nutrition/nutrition.dart';

/// Combined Macronutrients editor.
///
/// The three macros are edited together because each one's share and the
/// calorie reconciliation are defined by the other two. These tests pin that
/// the derived readouts follow the draft live, and that nothing rebalances
/// behind the user.
void main() {
  const coherent = NutritionTargetsData(
    caloriesKcal: 3220,
    proteinGrams: 161,
    carbohydrateGrams: 403,
    fatGrams: 107,
    fiberGrams: 30,
    customizationState: NutritionTargetCustomizationState.recommended,
    recommendationMetadata: {'source': 'onboarding', 'bmr': 1600},
  );

  Future<void> pumpSheet(
    WidgetTester tester, {
    required NutritionTargetsData current,
    required Future<void> Function(NutritionTargetsData) onSave,
  }) async {
    tester.view.physicalSize = const Size(420, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(MaterialApp(
      builder: (context, child) =>
          TioTheme(child: child ?? const SizedBox.shrink()),
      home: Scaffold(
        body: NutritionMacrosEditorSheet(current: current, onSave: onSave),
      ),
    ));
    await tester.pumpAndSettle();
  }

  String percentOf(WidgetTester tester, String id) => tester
      .widget<Text>(find.byKey(ValueKey('nutrition-macros-$id-percent')))
      .data!;

  String gramsOf(WidgetTester tester, String id) => tester
      .widget<Text>(find.byKey(ValueKey('nutrition-macros-$id-grams')))
      .data!;

  Future<void> moveSlider(
    WidgetTester tester,
    String id,
    double value,
  ) async {
    final slider = tester.widget<Slider>(
      find.byKey(ValueKey('nutrition-macros-$id-slider')),
    );
    slider.onChanged!(value);
    await tester.pumpAndSettle();
  }

  group('layout', () {
    testWidgets('every macro has a percent, grams, pencil and slider',
        (tester) async {
      await pumpSheet(tester, current: coherent, onSave: (_) async {});

      for (final id in ['protein', 'carbohydrate', 'fat']) {
        expect(find.byKey(ValueKey('nutrition-macros-$id-percent')),
            findsOneWidget);
        expect(
            find.byKey(ValueKey('nutrition-macros-$id-grams')), findsOneWidget);
        expect(find.byKey(ValueKey('nutrition-macros-$id-pencil')),
            findsOneWidget);
        expect(find.byKey(ValueKey('nutrition-macros-$id-slider')),
            findsOneWidget);
      }
    });

    testWidgets('Fiber and Calories are not part of this editor',
        (tester) async {
      await pumpSheet(tester, current: coherent, onSave: (_) async {});

      expect(find.text('Fiber'), findsNothing);
      expect(find.byKey(const ValueKey('nutrition-macros-fiber-slider')),
          findsNothing);
      // Target calories appears only as a comparison, never as an input here.
      expect(find.byKey(const ValueKey('nutrition-macros-calories-slider')),
          findsNothing);
    });
  });

  group('live derivation', () {
    testWidgets('changing one macro moves every percentage but no other grams',
        (tester) async {
      await pumpSheet(tester, current: coherent, onSave: (_) async {});

      expect(percentOf(tester, 'protein'), '20%');
      expect(percentOf(tester, 'carbohydrate'), '50%');
      expect(percentOf(tester, 'fat'), '30%');

      await moveSlider(tester, 'protein', 180);

      expect(gramsOf(tester, 'protein'), '180 g');
      // Percentages are relative, so all three move.
      expect(percentOf(tester, 'protein'), isNot('20%'));
      expect(percentOf(tester, 'carbohydrate'), isNot('50%'));
      expect(percentOf(tester, 'fat'), isNot('30%'));
      // Grams of the untouched macros are never rebalanced.
      expect(gramsOf(tester, 'carbohydrate'), '403 g');
      expect(gramsOf(tester, 'fat'), '107 g');
    });

    testWidgets('percentages always total 100', (tester) async {
      await pumpSheet(tester, current: coherent, onSave: (_) async {});
      await moveSlider(tester, 'protein', 173);

      final total = ['protein', 'carbohydrate', 'fat']
          .map((id) => int.parse(percentOf(tester, id).replaceAll('%', '')))
          .reduce((a, b) => a + b);

      expect(total, 100);
    });

    testWidgets('derived calories and difference update live', (tester) async {
      await pumpSheet(tester, current: coherent, onSave: (_) async {});

      String derived() => tester
          .widget<Text>(
              find.byKey(const ValueKey('nutrition-macros-derived-calories')))
          .data!;
      String difference() => tester
          .widget<Text>(
              find.byKey(const ValueKey('nutrition-macros-difference')))
          .data!;

      // 161*4 + 403*4 + 107*9 = 3219 against a 3220 kcal target.
      expect(derived(), '3219 kcal');
      expect(difference(), '1 kcal');

      await moveSlider(tester, 'protein', 180);

      // Only protein moved: 180*4 + 403*4 + 107*9 = 3295.
      expect(derived(), '3295 kcal');
      expect(difference(), '75 kcal');
    });

    testWidgets('the manual field drives the same single gram value',
        (tester) async {
      await pumpSheet(tester, current: coherent, onSave: (_) async {});

      await tester
          .tap(find.byKey(const ValueKey('nutrition-macros-protein-pencil')));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const ValueKey('nutrition-macros-protein-input')),
        '200',
      );
      await tester.pumpAndSettle();

      // One logical value: the slider follows the text, not a rival state.
      final slider = tester.widget<Slider>(
        find.byKey(const ValueKey('nutrition-macros-protein-slider')),
      );
      expect(slider.value, 200);
      expect(percentOf(tester, 'protein'), isNot('20%'));
    });
  });

  group('percentage denominator', () {
    testWidgets('shares come from macro energy, not the calorie target',
        (tester) async {
      // Macros imply 3217 kcal while the target says 3220; the split must be
      // the same either way, so a differing target cannot skew it.
      await pumpSheet(
        tester,
        current: const NutritionTargetsData(
          caloriesKcal: 8000,
          proteinGrams: 161,
          carbohydrateGrams: 403,
          fatGrams: 107,
        ),
        onSave: (_) async {},
      );

      expect(percentOf(tester, 'protein'), '20%');
      expect(percentOf(tester, 'carbohydrate'), '50%');
      expect(percentOf(tester, 'fat'), '30%');
    });

    testWidgets('an unknown macro shows an em dash, not 0%', (tester) async {
      await pumpSheet(
        tester,
        current: const NutritionTargetsData(
          caloriesKcal: 2000,
          proteinGrams: 150,
          carbohydrateGrams: 200,
        ),
        onSave: (_) async {},
      );

      expect(percentOf(tester, 'protein'), '—');
      expect(percentOf(tester, 'fat'), '—');
      expect(find.text('0%'), findsNothing);
    });

    testWidgets('all-zero macros show no fabricated split', (tester) async {
      await pumpSheet(
        tester,
        current: const NutritionTargetsData(
          caloriesKcal: 2000,
          proteinGrams: 0,
          carbohydrateGrams: 0,
          fatGrams: 0,
        ),
        onSave: (_) async {},
      );

      // Division by zero is undefined; 0/0/0 would imply a real distribution.
      expect(percentOf(tester, 'protein'), '—');
      expect(percentOf(tester, 'carbohydrate'), '—');
      expect(percentOf(tester, 'fat'), '—');
      // Explicit zero grams still reads as a real value.
      expect(gramsOf(tester, 'protein'), '0 g');
    });
  });

  group('coherence and saving', () {
    testWidgets('Save is disabled until something changes', (tester) async {
      await pumpSheet(tester, current: coherent, onSave: (_) async {});

      expect(
        tester
            .widget<TioButton>(
                find.byKey(const ValueKey('nutrition-macros-save')))
            .onPressed,
        isNull,
      );
    });

    testWidgets('a mismatch over the tolerance blocks Save', (tester) async {
      var saves = 0;
      await pumpSheet(
        tester,
        current: coherent,
        onSave: (_) async => saves++,
      );

      await moveSlider(tester, 'protein', 180);

      expect(
        tester
            .widget<TioButton>(
                find.byKey(const ValueKey('nutrition-macros-save')))
            .onPressed,
        isNull,
      );
      expect(saves, 0);
    });

    testWidgets('a coherent change saves and preserves everything else',
        (tester) async {
      NutritionTargetsData? saved;
      await pumpSheet(
        tester,
        current: coherent,
        onSave: (targets) async => saved = targets,
      );

      // 161 -> 160 protein drops 4 kcal, landing within tolerance.
      await moveSlider(tester, 'protein', 160);
      await tester.tap(find.byKey(const ValueKey('nutrition-macros-save')));
      await tester.pumpAndSettle();

      expect(saved!.proteinGrams, 160);
      expect(saved!.carbohydrateGrams, 403);
      expect(saved!.fatGrams, 107);
      expect(saved!.caloriesKcal, 3220);
      expect(saved!.fiberGrams, 30);
      expect(
          saved!.recommendationMetadata, {'source': 'onboarding', 'bmr': 1600});
      // Only the macro the user actually moved is claimed as customized.
      expect(saved!.customizedFields, {'protein'});
    });

    testWidgets('an incomplete row explains why there is nothing to compare',
        (tester) async {
      await pumpSheet(
        tester,
        current: const NutritionTargetsData(proteinGrams: 150),
        onSave: (_) async {},
      );

      expect(
        find.byKey(const ValueKey('nutrition-macros-coherence-unavailable')),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('nutrition-macros-coherence')),
          findsNothing);
    });

    testWidgets('a failed save keeps the sheet open and is retryable',
        (tester) async {
      await pumpSheet(
        tester,
        current: coherent,
        onSave: (_) async => throw Exception('offline'),
      );

      await moveSlider(tester, 'protein', 160);
      await tester.tap(find.byKey(const ValueKey('nutrition-macros-save')));
      await tester.pumpAndSettle();

      expect(
        find.text("Couldn't save. Check your connection and try again."),
        findsOneWidget,
      );
      expect(
        tester
            .widget<TioButton>(
                find.byKey(const ValueKey('nutrition-macros-save')))
            .onPressed,
        isNotNull,
      );
    });
  });
}
