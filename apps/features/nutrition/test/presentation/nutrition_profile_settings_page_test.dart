import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tio_core/core.dart';
import 'package:tio_feature_nutrition/nutrition.dart';

/// Nutrition Profile edit parity coverage.
///
/// The canonical owner's `upsert` replaces the whole row, so the single most
/// important guarantee here is that editing one field never drops the fields
/// this screen does not render.
void main() {
  Widget host(Widget child) => MaterialApp(
        builder: (context, appChild) =>
            TioTheme(child: appChild ?? const SizedBox.shrink()),
        home: child,
      );

  Future<void> pumpPage(
    WidgetTester tester, {
    required NutritionProfileData profile,
    required Future<void> Function(NutritionProfileData) onSave,
  }) async {
    tester.view.physicalSize = const Size(390, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(host(
      NutritionProfileSettingsPage(profile: profile, onSave: onSave),
    ));
    await tester.pumpAndSettle();
  }

  group('summaries', () {
    testWidgets('an unanswered profile reads as Not set, never as None',
        (tester) async {
      await pumpPage(
        tester,
        profile: const NutritionProfileData(),
        onSave: (_) async {},
      );

      expect(find.text('Diet Type'), findsOneWidget);
      expect(find.text('Allergies & Restrictions'), findsOneWidget);
      expect(find.text('Not set'), findsNWidgets(2));
      expect(find.text('None'), findsNothing);
    });

    testWidgets('an explicitly empty allergy set reads as None',
        (tester) async {
      await pumpPage(
        tester,
        profile: const NutritionProfileData(allergies: <String>{}),
        onSave: (_) async {},
      );

      expect(find.text('None'), findsOneWidget);
      // Diet Type is still genuinely unknown.
      expect(find.text('Not set'), findsOneWidget);
    });

    testWidgets('answered values render canonical labels', (tester) async {
      await pumpPage(
        tester,
        profile: const NutritionProfileData(
          preferredDiet: 'non_vegetarian',
          allergies: {'lactose', 'nuts'},
        ),
        onSave: (_) async {},
      );

      expect(find.text('Non-Vegetarian'), findsOneWidget);
      expect(find.text('Lactose, Nuts'), findsOneWidget);
      expect(find.text('Not set'), findsNothing);
    });

    testWidgets('an unrecognised stored diet value is not invented',
        (tester) async {
      await pumpPage(
        tester,
        profile: const NutritionProfileData(preferredDiet: 'carnivore'),
        onSave: (_) async {},
      );

      expect(find.text('carnivore'), findsNothing);
      expect(find.text('Not set'), findsNWidgets(2));
    });
  });

  group('Diet Type editor', () {
    testWidgets('offers exactly the canonical options and no free text',
        (tester) async {
      await pumpPage(
        tester,
        profile: const NutritionProfileData(),
        onSave: (_) async {},
      );

      await tester
          .tap(find.byKey(const ValueKey('nutrition-profile-diet-type-field')));
      await tester.pumpAndSettle();

      expect(
          find.byKey(const ValueKey('nutrition-editor-sheet')), findsOneWidget);
      for (final value in [
        'vegetarian',
        'non_vegetarian',
        'vegan',
        'eggitarian',
        'other',
      ]) {
        expect(
          find.byKey(ValueKey('nutrition-diet-option-$value')),
          findsOneWidget,
          reason: value,
        );
      }
      // V1 has no canonical column for onboarding's free-text "Other" detail.
      expect(find.byType(TextField), findsNothing);
    });

    testWidgets('Save stays disabled until the selection actually changes',
        (tester) async {
      var saves = 0;
      await pumpPage(
        tester,
        profile: const NutritionProfileData(preferredDiet: 'vegan'),
        onSave: (_) async => saves++,
      );

      await tester
          .tap(find.byKey(const ValueKey('nutrition-profile-diet-type-field')));
      await tester.pumpAndSettle();

      final save = find.byKey(const ValueKey('nutrition-diet-type-save'));
      expect(tester.widget<TioButton>(save).onPressed, isNull);

      await tester
          .tap(find.byKey(const ValueKey('nutrition-diet-option-vegan')));
      await tester.pumpAndSettle();
      expect(tester.widget<TioButton>(save).onPressed, isNull);

      await tester
          .tap(find.byKey(const ValueKey('nutrition-diet-option-vegetarian')));
      await tester.pumpAndSettle();
      expect(tester.widget<TioButton>(save).onPressed, isNotNull);
      expect(saves, 0);
    });

    testWidgets('saving Diet Type preserves every unrendered canonical field',
        (tester) async {
      NutritionProfileData? saved;
      await pumpPage(
        tester,
        profile: const NutritionProfileData(
          preferredDiet: 'vegetarian',
          allergies: {'gluten'},
          dislikedFoods: {'okra'},
          medicalConditions: {'diabetes'},
        ),
        onSave: (profile) async => saved = profile,
      );

      await tester
          .tap(find.byKey(const ValueKey('nutrition-profile-diet-type-field')));
      await tester.pumpAndSettle();
      await tester
          .tap(find.byKey(const ValueKey('nutrition-diet-option-vegan')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('nutrition-diet-type-save')));
      await tester.pumpAndSettle();

      expect(saved, isNotNull);
      expect(saved!.preferredDiet, 'vegan');
      expect(saved!.allergies, {'gluten'});
      expect(saved!.dislikedFoods, {'okra'});
      expect(saved!.medicalConditions, {'diabetes'});
      expect(
          find.byKey(const ValueKey('nutrition-editor-sheet')), findsNothing);
    });

    testWidgets('a failed save keeps the sheet open and surfaces the error',
        (tester) async {
      await pumpPage(
        tester,
        profile: const NutritionProfileData(preferredDiet: 'vegan'),
        onSave: (_) async => throw Exception('offline'),
      );

      await tester
          .tap(find.byKey(const ValueKey('nutrition-profile-diet-type-field')));
      await tester.pumpAndSettle();
      await tester
          .tap(find.byKey(const ValueKey('nutrition-diet-option-vegetarian')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('nutrition-diet-type-save')));
      await tester.pumpAndSettle();

      expect(
          find.byKey(const ValueKey('nutrition-editor-sheet')), findsOneWidget);
      expect(
        find.text("Couldn't save. Check your connection and try again."),
        findsOneWidget,
      );
    });
  });

  group('Allergies & Restrictions editor', () {
    Future<void> openAllergies(WidgetTester tester) async {
      await tester
          .tap(find.byKey(const ValueKey('nutrition-profile-allergies-field')));
      await tester.pumpAndSettle();
    }

    testWidgets('an unanswered profile cannot be saved with nothing selected',
        (tester) async {
      await pumpPage(
        tester,
        profile: const NutritionProfileData(),
        onSave: (_) async {},
      );
      await openAllergies(tester);

      final save = find.byKey(const ValueKey('nutrition-allergies-save'));
      expect(tester.widget<TioButton>(save).onPressed, isNull);
    });

    testWidgets('choosing None clears restrictions and saves an empty set',
        (tester) async {
      NutritionProfileData? saved;
      await pumpPage(
        tester,
        profile: const NutritionProfileData(
          preferredDiet: 'vegan',
          allergies: {'nuts', 'gluten'},
          dislikedFoods: {'okra'},
        ),
        onSave: (profile) async => saved = profile,
      );
      await openAllergies(tester);

      await tester
          .tap(find.byKey(const ValueKey('nutrition-allergy-option-none')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('nutrition-allergies-save')));
      await tester.pumpAndSettle();

      expect(saved, isNotNull);
      // Explicitly answered "no restrictions": an empty set, never null.
      expect(saved!.allergies, isNotNull);
      expect(saved!.allergies, isEmpty);
      expect(saved!.preferredDiet, 'vegan');
      expect(saved!.dislikedFoods, {'okra'});
    });

    testWidgets('choosing a restriction clears None, preserving exclusivity',
        (tester) async {
      NutritionProfileData? saved;
      await pumpPage(
        tester,
        profile: const NutritionProfileData(allergies: <String>{}),
        onSave: (profile) async => saved = profile,
      );
      await openAllergies(tester);

      await tester
          .tap(find.byKey(const ValueKey('nutrition-allergy-option-none')));
      await tester.pumpAndSettle();
      await tester
          .tap(find.byKey(const ValueKey('nutrition-allergy-option-seafood')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('nutrition-allergies-save')));
      await tester.pumpAndSettle();

      expect(saved!.allergies, {'seafood'});
    });

    testWidgets('multiple restrictions are selectable together',
        (tester) async {
      NutritionProfileData? saved;
      await pumpPage(
        tester,
        profile: const NutritionProfileData(),
        onSave: (profile) async => saved = profile,
      );
      await openAllergies(tester);

      await tester
          .tap(find.byKey(const ValueKey('nutrition-allergy-option-lactose')));
      await tester.pumpAndSettle();
      await tester
          .tap(find.byKey(const ValueKey('nutrition-allergy-option-nuts')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('nutrition-allergies-save')));
      await tester.pumpAndSettle();

      expect(saved!.allergies, {'lactose', 'nuts'});
    });

    testWidgets(
        'deselecting the last restriction blocks an empty-but-unanswered save',
        (tester) async {
      await pumpPage(
        tester,
        profile: const NutritionProfileData(allergies: {'nuts'}),
        onSave: (_) async {},
      );
      await openAllergies(tester);

      await tester
          .tap(find.byKey(const ValueKey('nutrition-allergy-option-nuts')));
      await tester.pumpAndSettle();

      // Neither None nor any restriction is chosen: this is not an answer.
      final save = find.byKey(const ValueKey('nutrition-allergies-save'));
      expect(tester.widget<TioButton>(save).onPressed, isNull);
    });

    testWidgets('the editor never offers None as a stored token',
        (tester) async {
      NutritionProfileData? saved;
      await pumpPage(
        tester,
        profile: const NutritionProfileData(),
        onSave: (profile) async => saved = profile,
      );
      await openAllergies(tester);

      await tester
          .tap(find.byKey(const ValueKey('nutrition-allergy-option-none')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('nutrition-allergies-save')));
      await tester.pumpAndSettle();

      expect(saved!.allergies, isNot(contains('none')));
    });
  });
}
