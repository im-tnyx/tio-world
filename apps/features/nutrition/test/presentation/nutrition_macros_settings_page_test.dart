import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tio_core/core.dart';
import 'package:tio_feature_nutrition/nutrition.dart';

/// Macronutrients screen.
///
/// The three macros live on a screen rather than a sheet: their sliders, live
/// shares and the calorie reconciliation already fill the height, and exact
/// entry still needs a keyboard on top of that. Exact entry therefore opens one
/// small sheet holding a single number, which returns its value to this
/// screen's draft instead of saving on its own.
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

  Future<void> pumpPage(
    WidgetTester tester, {
    required NutritionTargetsData targets,
    required Future<void> Function(NutritionTargetsData) onSave,
  }) async {
    tester.view.physicalSize = const Size(420, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(MaterialApp(
      builder: (context, child) =>
          TioTheme(child: child ?? const SizedBox.shrink()),
      home: NutritionMacrosSettingsPage(targets: targets, onSave: onSave),
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
    tester
        .widget<Slider>(find.byKey(ValueKey('nutrition-macros-$id-slider')))
        .onChanged!(value);
    await tester.pumpAndSettle();
  }

  Future<void> enterExact(
    WidgetTester tester,
    String id,
    String text,
  ) async {
    await tester.tap(find.byKey(ValueKey('nutrition-macros-$id-pencil')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(ValueKey('nutrition-macros-$id-input')),
      text,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(ValueKey('nutrition-macros-$id-apply')));
    await tester.pumpAndSettle();
  }

  group('layout', () {
    testWidgets('is a screen with a pinned Save, not a sheet', (tester) async {
      await pumpPage(tester, targets: coherent, onSave: (_) async {});

      expect(find.byType(Scaffold), findsOneWidget);
      expect(find.text('Macronutrients'), findsOneWidget);
      expect(
          find.byKey(const ValueKey('nutrition-macros-save')), findsOneWidget);
    });

    testWidgets('every macro has a percent, grams, pencil and slider',
        (tester) async {
      await pumpPage(tester, targets: coherent, onSave: (_) async {});

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

    testWidgets('no text field is shown until the pencil is tapped',
        (tester) async {
      await pumpPage(tester, targets: coherent, onSave: (_) async {});

      // A slider and a text field for the same value must never compete for
      // attention on the same row.
      expect(find.byType(TioInput), findsNothing);
    });

    testWidgets('Fiber and Calories are not edited here', (tester) async {
      await pumpPage(tester, targets: coherent, onSave: (_) async {});

      expect(find.byKey(const ValueKey('nutrition-macros-fiber-slider')),
          findsNothing);
      expect(find.byKey(const ValueKey('nutrition-macros-calories-slider')),
          findsNothing);
    });
  });

  group('exact entry', () {
    testWidgets('opens one focused sheet holding a single number',
        (tester) async {
      await pumpPage(tester, targets: coherent, onSave: (_) async {});

      await tester
          .tap(find.byKey(const ValueKey('nutrition-macros-protein-pencil')));
      await tester.pumpAndSettle();

      expect(
          find.byKey(const ValueKey('tio-editor-sheet')), findsOneWidget);
      // Only the macro being edited gets a field.
      expect(find.byType(TioInput), findsOneWidget);
      expect(
        find.byKey(const ValueKey('nutrition-macros-protein-input')),
        findsOneWidget,
      );
    });

    testWidgets('applying a value updates the same single gram value',
        (tester) async {
      await pumpPage(tester, targets: coherent, onSave: (_) async {});
      await enterExact(tester, 'protein', '200');

      expect(gramsOf(tester, 'protein'), '200 g');
      // One logical value: the slider follows the entered number.
      expect(
        tester
            .widget<Slider>(
                find.byKey(const ValueKey('nutrition-macros-protein-slider')))
            .value,
        200,
      );
    });

    testWidgets('cancelling the sheet leaves the value untouched',
        (tester) async {
      await pumpPage(tester, targets: coherent, onSave: (_) async {});

      await tester
          .tap(find.byKey(const ValueKey('nutrition-macros-protein-pencil')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('nutrition-macros-protein-input')),
        '999',
      );
      await tester.pumpAndSettle();
      Navigator.of(tester.element(find.byKey(
        const ValueKey('nutrition-macros-protein-input'),
      ))).pop();
      await tester.pumpAndSettle();

      expect(gramsOf(tester, 'protein'), '161 g');
    });

    testWidgets('keyboard Done applies through the existing exact-entry path',
        (tester) async {
      await pumpPage(tester, targets: coherent, onSave: (_) async {});

      await tester
          .tap(find.byKey(const ValueKey('nutrition-macros-protein-pencil')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('nutrition-macros-protein-input')),
        '202',
      );
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      expect(gramsOf(tester, 'protein'), '202 g');
    });

    testWidgets('a blank entry clears the macro to unset, not zero',
        (tester) async {
      await pumpPage(tester, targets: coherent, onSave: (_) async {});
      await enterExact(tester, 'protein', '');

      expect(gramsOf(tester, 'protein'), 'Not set');
      // An unknown macro makes the whole split undefined.
      expect(percentOf(tester, 'protein'), '—');
    });

    testWidgets('a negative value is rejected', (tester) async {
      await pumpPage(tester, targets: coherent, onSave: (_) async {});

      await tester
          .tap(find.byKey(const ValueKey('nutrition-macros-protein-pencil')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('nutrition-macros-protein-input')),
        '-5',
      );
      await tester.pumpAndSettle();

      // The formatter strips the sign, so the field can never hold one.
      expect(
        tester
            .widget<TioInput>(
                find.byKey(const ValueKey('nutrition-macros-protein-input')))
            .controller!
            .text,
        '5',
      );
    });
  });

  group('live derivation', () {
    testWidgets('changing one macro moves every percentage but no other grams',
        (tester) async {
      await pumpPage(tester, targets: coherent, onSave: (_) async {});

      expect(percentOf(tester, 'protein'), '20%');
      expect(percentOf(tester, 'carbohydrate'), '50%');
      expect(percentOf(tester, 'fat'), '30%');

      await moveSlider(tester, 'protein', 180);

      expect(gramsOf(tester, 'protein'), '180 g');
      expect(percentOf(tester, 'protein'), isNot('20%'));
      expect(percentOf(tester, 'carbohydrate'), isNot('50%'));
      expect(percentOf(tester, 'fat'), isNot('30%'));
      // Grams of the untouched macros are never rebalanced.
      expect(gramsOf(tester, 'carbohydrate'), '403 g');
      expect(gramsOf(tester, 'fat'), '107 g');
    });

    testWidgets('percentages always total 100', (tester) async {
      await pumpPage(tester, targets: coherent, onSave: (_) async {});
      await moveSlider(tester, 'protein', 173);

      final total = ['protein', 'carbohydrate', 'fat']
          .map((id) => int.parse(percentOf(tester, id).replaceAll('%', '')))
          .reduce((a, b) => a + b);

      expect(total, 100);
    });

    testWidgets('derived calories and difference update live', (tester) async {
      await pumpPage(tester, targets: coherent, onSave: (_) async {});

      String derived() => tester
          .widget<Text>(
              find.byKey(const ValueKey('nutrition-macros-derived-calories')))
          .data!;
      String difference() => tester
          .widget<Text>(
              find.byKey(const ValueKey('nutrition-macros-difference')))
          .data!;

      // 161*4 + 403*4 + 107*9 = 3219 against a 3220 kcal target: 1 kcal short.
      expect(derived(), '3219 kcal');
      expect(difference(), '-1 kcal');

      await moveSlider(tester, 'protein', 180);

      // Only protein moved: 180*4 + 403*4 + 107*9 = 3295, now over.
      expect(derived(), '3295 kcal');
      expect(difference(), '+75 kcal');
    });
  });

  group('percentage denominator', () {
    testWidgets('shares come from macro energy, not the calorie target',
        (tester) async {
      await pumpPage(
        tester,
        targets: const NutritionTargetsData(
          caloriesKcal: 8000,
          proteinGrams: 161,
          carbohydrateGrams: 403,
          fatGrams: 107,
        ),
        onSave: (_) async {},
      );

      // A wildly different target must not skew the composition.
      expect(percentOf(tester, 'protein'), '20%');
      expect(percentOf(tester, 'carbohydrate'), '50%');
      expect(percentOf(tester, 'fat'), '30%');
    });

    testWidgets('an unknown macro shows an em dash, not 0%', (tester) async {
      await pumpPage(
        tester,
        targets: const NutritionTargetsData(
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
      await pumpPage(
        tester,
        targets: const NutritionTargetsData(
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
    Finder save() => find.byKey(const ValueKey('nutrition-macros-save'));

    testWidgets('Save is disabled until something changes', (tester) async {
      await pumpPage(tester, targets: coherent, onSave: (_) async {});

      expect(tester.widget<TioButton>(save()).onPressed, isNull);
    });

    testWidgets('the difference is signed so direction is visible',
        (tester) async {
      await pumpPage(tester, targets: coherent, onSave: (_) async {});

      String difference() => tester
          .widget<Text>(
              find.byKey(const ValueKey('nutrition-macros-difference')))
          .data!;

      // Over the target.
      await moveSlider(tester, 'protein', 200);
      expect(difference(), startsWith('+'));

      // Under it. Magnitude alone would look identical to the case above.
      await moveSlider(tester, 'protein', 100);
      expect(difference(), startsWith('-'));
    });

    testWidgets('Reset restores the stored values and unblocks the screen',
        (tester) async {
      var saves = 0;
      await pumpPage(tester, targets: coherent, onSave: (_) async => saves++);

      final reset = find.byKey(const ValueKey('nutrition-macros-reset'));
      // Nothing to discard yet.
      expect(tester.widget<TioButton>(reset).onPressed, isNull);

      await moveSlider(tester, 'protein', 300);
      expect(gramsOf(tester, 'protein'), '300 g');
      expect(tester.widget<TioButton>(reset).onPressed, isNotNull);

      await tester.tap(reset);
      await tester.pumpAndSettle();

      // Back to what is saved -- not to a recommendation, and without writing.
      expect(gramsOf(tester, 'protein'), '161 g');
      expect(gramsOf(tester, 'carbohydrate'), '403 g');
      expect(gramsOf(tester, 'fat'), '107 g');
      expect(saves, 0);
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
      await pumpPage(tester, targets: coherent, onSave: (_) async => saves++);

      await moveSlider(tester, 'protein', 180);

      expect(tester.widget<TioButton>(save()).onPressed, isNull);
      expect(saves, 0);
      expect(find.byKey(const ValueKey('nutrition-macros-coherence')),
          findsOneWidget);
    });

    testWidgets('a coherent change saves and preserves everything else',
        (tester) async {
      NutritionTargetsData? saved;
      await pumpPage(
        tester,
        targets: coherent,
        onSave: (targets) async => saved = targets,
      );

      // 161 -> 160 protein drops 4 kcal, landing within tolerance.
      await moveSlider(tester, 'protein', 160);
      await tester.tap(save());
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

    testWidgets('an incomplete row explains there is nothing to compare',
        (tester) async {
      await pumpPage(
        tester,
        targets: const NutritionTargetsData(proteinGrams: 150),
        onSave: (_) async {},
      );

      expect(
        find.byKey(const ValueKey('nutrition-macros-coherence-unavailable')),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('nutrition-macros-coherence')),
          findsNothing);
    });

    testWidgets('a failed save keeps the screen open and is retryable',
        (tester) async {
      await pumpPage(
        tester,
        targets: coherent,
        onSave: (_) async => throw Exception('offline'),
      );

      await moveSlider(tester, 'protein', 160);
      await tester.tap(save());
      await tester.pumpAndSettle();

      expect(
        find.text("Couldn't save. Check your connection and try again."),
        findsOneWidget,
      );
      expect(tester.widget<TioButton>(save()).onPressed, isNotNull);
    });
  });
}
