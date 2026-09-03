import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tio_core/core.dart';
import 'package:tio_feature_nutrition/nutrition.dart';
import 'package:tio_shared/shared.dart';

/// Additional Nutrition is a read-only calculated reference surface in V1.
///
/// The previous editing contract — enabled/not-configured state, Use
/// Recommended, Turn off, Custom overrides — is superseded. These tests exist
/// largely to keep it from coming back by accident, and to pin the numbers the
/// screen is allowed to show.
void main() {
  final now = DateTime(2026, 9, 3);
  final adultDob = DateTime(1990, 1, 1); // 36 on the fixed clock

  Future<void> pumpPage(
    WidgetTester tester, {
    int? caloriesKcal = 2000,
    DateTime? dateOfBirth,
    // A nullable parameter cannot distinguish "not specified" from "explicitly
    // absent", and defaulting a null back to an adult date of birth silently
    // turns a no-DOB test into an adult one.
    bool withoutDateOfBirth = false,
  }) async {
    tester.view.physicalSize = const Size(390, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(MaterialApp(
      builder: (context, child) =>
          TioTheme(child: child ?? const SizedBox.shrink()),
      home: AdditionalNutrientGoalsPage(
        caloriesKcal: caloriesKcal,
        dateOfBirth: withoutDateOfBirth ? null : (dateOfBirth ?? adultDob),
        now: now,
      ),
    ));
    await tester.pumpAndSettle();
  }

  Finder rowFor(NutrientId nutrientId) => find
      .byKey(ValueKey('additional-nutrient-${nutrientId.storageValue}-row'));

  group('surface shape', () {
    testWidgets('shows exactly seven rows', (tester) async {
      await pumpPage(tester);

      for (final nutrientId
          in AdditionalNutrientRecommendationPolicy.displayOrder) {
        expect(rowFor(nutrientId), findsOneWidget, reason: '$nutrientId');
      }
      expect(
        AdditionalNutrientRecommendationPolicy.displayOrder,
        hasLength(7),
      );
    });

    testWidgets('rows appear in the deterministic label order', (tester) async {
      await pumpPage(tester);

      const expected = [
        'Saturated Fat',
        'Trans Fat',
        'Added Sugar',
        'Sodium',
        'Calcium',
        'Phosphorus',
        'Vitamin D',
      ];

      final rendered = tester
          .widgetList<Text>(find.byType(Text))
          .map((text) => text.data)
          .where(expected.contains)
          .toList();

      expect(
        rendered,
        expected,
        reason: 'Row order is owned by the policy and must not drift.',
      );
    });

    testWidgets('a divider separates every pair of rows, none after the last',
        (tester) async {
      await pumpPage(tester);

      // Six dividers for seven rows: n-1, never a trailing one, so the card's
      // rounded edge stays clean.
      expect(find.byType(Divider), findsNWidgets(6));
    });
  });

  group('the superseded editing contract is gone', () {
    testWidgets('no edit affordance, no editor, no goal-state controls',
        (tester) async {
      await pumpPage(tester);

      expect(find.byType(NutritionEditPencil), findsNothing);
      expect(find.byIcon(Icons.edit), findsNothing);
      expect(find.byIcon(Icons.edit_rounded), findsNothing);
      expect(find.byIcon(Icons.chevron_right), findsNothing);
      expect(find.byType(TioEditorSheet), findsNothing);
      expect(find.text('Use Recommended'), findsNothing);
      expect(find.text('Turn off'), findsNothing);
      expect(find.text('Custom'), findsNothing);
      expect(find.text('Recommended'), findsNothing);
      expect(find.text('Not set'), findsNothing);
      expect(find.byType(TextField), findsNothing);
    });

    testWidgets('tapping a row opens nothing', (tester) async {
      await pumpPage(tester);

      await tester.tap(rowFor(NutrientId.sodium), warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(find.byType(TioEditorSheet), findsNothing);
      expect(find.byType(TextField), findsNothing);
      expect(find.text('Save'), findsNothing);
    });
  });

  group('calculated values', () {
    testWidgets('saturated fat is 10% of Calories at 9 kcal/g', (tester) async {
      await pumpPage(tester, caloriesKcal: 2000);
      // (0.10 * 2000) / 9 = 22.22...
      expect(find.text('22.2 g'), findsOneWidget);
    });

    testWidgets('trans fat is 1% of Calories at 9 kcal/g', (tester) async {
      await pumpPage(tester, caloriesKcal: 2000);
      // (0.01 * 2000) / 9 = 2.22...
      expect(find.text('2.2 g'), findsOneWidget);
    });

    testWidgets('added sugar is under 10% of Calories at 4 kcal/g',
        (tester) async {
      await pumpPage(tester, caloriesKcal: 2000);
      // (0.10 * 2000) / 4 = 50, and the rule is strictly below that.
      expect(find.text('< 50 g'), findsOneWidget);
      expect(
        find.text('50 g'),
        findsNothing,
        reason: 'A bare 50 g presents the forbidden boundary as the goal.',
      );
    });

    testWidgets('sodium is a strict adult boundary, grouped for prose',
        (tester) async {
      await pumpPage(tester);

      expect(find.text('< 2,000 mg'), findsOneWidget);
      expect(find.text('2,000 mg'), findsNothing);
    });

    testWidgets('phosphorus is a flat adult target', (tester) async {
      await pumpPage(tester);
      expect(find.text('700 mg'), findsOneWidget);
    });

    testWidgets('vitamin D is 15 mcg for 19-70', (tester) async {
      await pumpPage(tester, dateOfBirth: DateTime(1990, 1, 1)); // 36
      expect(find.text('15 mcg'), findsOneWidget);
    });

    testWidgets('vitamin D is 20 mcg for 71 and over', (tester) async {
      await pumpPage(tester, dateOfBirth: DateTime(1950, 1, 1)); // 76
      expect(find.text('20 mcg'), findsOneWidget);
    });

    testWidgets('calcium is 1,000 mg for 19-50', (tester) async {
      await pumpPage(tester, dateOfBirth: DateTime(1990, 1, 1)); // 36
      expect(find.text('1,000 mg'), findsOneWidget);
    });

    testWidgets('calcium is 1,200 mg for 71 and over', (tester) async {
      await pumpPage(tester, dateOfBirth: DateTime(1950, 1, 1)); // 76
      expect(find.text('1,200 mg'), findsOneWidget);
    });
  });

  group('unavailable states', () {
    testWidgets('calcium 51-70 is Unavailable without reference sex',
        (tester) async {
      await pumpPage(tester, dateOfBirth: DateTime(1966, 1, 1)); // 60

      // The 51-70 band differs by health reference sex, which Tio does not own
      // yet (TNYX-142). Identity gender is not a substitute, so no number is
      // invented.
      expect(find.text('Unavailable'), findsOneWidget);

      // Every other row still resolves, so this is a targeted gap.
      expect(find.text('< 2,000 mg'), findsOneWidget);
      expect(find.text('700 mg'), findsOneWidget);
      expect(find.text('15 mcg'), findsOneWidget);
    });

    testWidgets('calorie-derived rows are Unavailable without Calories',
        (tester) async {
      await pumpPage(tester, caloriesKcal: null);

      // Saturated fat, trans fat and added sugar.
      expect(find.text('Unavailable'), findsNWidgets(3));

      // Age-derived rows are unaffected.
      expect(find.text('< 2,000 mg'), findsOneWidget);
      expect(find.text('1,000 mg'), findsOneWidget);
      expect(find.text('700 mg'), findsOneWidget);
      expect(find.text('15 mcg'), findsOneWidget);
    });

    testWidgets('every row is Unavailable without a date of birth',
        (tester) async {
      await pumpPage(tester, withoutDateOfBirth: true);

      expect(find.text('Unavailable'), findsNWidgets(7));
    });

    testWidgets('every row is Unavailable below the adult minimum',
        (tester) async {
      await pumpPage(tester, dateOfBirth: DateTime(2015, 1, 1)); // 11

      expect(find.text('Unavailable'), findsNWidgets(7));
    });
  });
}
