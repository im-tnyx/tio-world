import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tio_core/core.dart';
import 'package:tio_feature_nutrition/nutrition.dart';
import 'package:tio_shared/shared.dart';

void main() {
  testWidgets('renders the approved create body and reuses the disabled footer',
      (tester) async {
    await _pumpEditor(tester, draft: _completeDraft());

    expect(find.text('Log your meal'), findsOneWidget);
    expect(find.byKey(const ValueKey('meal-editor-create-body')), findsOneWidget);
    expect(find.byKey(const ValueKey('meal-editor-meal-name')), findsOneWidget);
    expect(find.text('290 kcal'), findsOneWidget);
    expect(find.text('13 g'), findsOneWidget);
    expect(find.text('43 g'), findsOneWidget);
    expect(find.text('8 g'), findsOneWidget);
    expect(find.text('Roti'), findsOneWidget);
    expect(find.text('Curd'), findsOneWidget);
    expect(find.text('Lunch'), findsOneWidget);
    expect(find.text('Sep 16, 13:15'), findsOneWidget);

    final primary = find.byKey(const ValueKey('meal-log-footer-primary'));
    expect(primary, findsOneWidget);
    expect(tester.widget<TioButton>(primary).onPressed, isNull);
    expect(find.text('Add more'), findsNothing);
  });

  testWidgets('quantity step rescales item nutrition and live meal totals',
      (tester) async {
    await _pumpEditor(tester, draft: _completeDraft());

    await tester.tap(find.byKey(const ValueKey('meal-editor-quantity-plus-0')));
    await tester.pump();

    expect(find.text('3'), findsOneWidget);
    expect(find.text('390 kcal'), findsOneWidget);
    expect(find.text('17 g'), findsOneWidget);
    expect(find.text('61 g'), findsOneWidget);
    expect(find.text('10 g'), findsOneWidget);
    expect(find.text('300 kcal · 12 g protein'), findsOneWidget);
  });

  testWidgets('delete recomputes totals and the final item cannot be removed',
      (tester) async {
    await _pumpEditor(tester, draft: _completeDraft());

    final curdDelete = find.byKey(const ValueKey('meal-editor-delete-1'));
    await tester.ensureVisible(curdDelete);
    await tester.pumpAndSettle();
    await tester.tap(curdDelete);
    await tester.pump();

    expect(find.text('Curd'), findsNothing);
    expect(find.text('1 item'), findsOneWidget);
    expect(find.text('200 kcal'), findsWidgets);

    final delete = find.byKey(const ValueKey('meal-editor-delete-0'));
    expect(delete, findsOneWidget);
    expect(tester.widget<IconButton>(delete).onPressed, isNull);
  });

  testWidgets('incomplete draft stays visibly unknown instead of fabricating values',
      (tester) async {
    final draft = MealLoggingDraft(
      captureSource: MealLogCaptureSource.text,
      items: [
        MealLoggingDraftItem(
          displayName: 'Dal',
          consumedNutritionSnapshot: NutritionSnapshot(
            schemaVersion: 1,
            nutrients: const {NutrientId.energy: 180},
          ),
        ),
      ],
    );

    await _pumpEditor(tester, draft: draft);

    expect(find.text('180 kcal'), findsWidgets);
    expect(find.text('— g'), findsNWidgets(3));
    expect(find.text('Quantity unknown'), findsOneWidget);
    expect(find.text('Unit unknown'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('meal-editor-quantity-plus-0')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('meal-editor-quantity-minus-0')),
      findsNothing,
    );
  });

  testWidgets('compact width and larger text scale do not overflow',
      (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await _pumpEditor(
      tester,
      draft: _completeDraft(),
      textScaler: const TextScaler.linear(1.5),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text('Log your meal'), findsOneWidget);
    expect(find.byKey(const ValueKey('meal-log-footer-primary')), findsOneWidget);
  });

  testWidgets('dark theme renders the same Meal Editor contract safely',
      (tester) async {
    await _pumpEditor(
      tester,
      draft: _completeDraft(),
      mode: TioThemeMode.dark,
    );

    expect(tester.takeException(), isNull);
    expect(find.text('Log your meal'), findsOneWidget);
    expect(find.byKey(const ValueKey('meal-editor-nutrition-summary')), findsOneWidget);
    expect(find.byKey(const ValueKey('meal-log-footer-primary')), findsOneWidget);
  });
}

Future<void> _pumpEditor(
  WidgetTester tester, {
  required MealLoggingDraft draft,
  TextScaler textScaler = TextScaler.noScaling,
  TioThemeMode mode = TioThemeMode.light,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      builder: (context, child) => TioTheme(
        config: TioThemeConfig(mode: mode),
        child: MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: textScaler),
          child: child ?? const SizedBox.shrink(),
        ),
      ),
      home: MealEditorCreatePage(
        initialDraft: draft,
        mealCategoryLabel: 'Lunch',
        dateTimeLabel: 'Sep 16, 13:15',
        onBack: () {},
      ),
    ),
  );
  await tester.pumpAndSettle();
}

MealLoggingDraft _completeDraft() {
  return MealLoggingDraft(
    mealName: 'Roti and curd',
    captureSource: MealLogCaptureSource.text,
    items: [
      _item(
        name: 'Roti',
        quantity: 2,
        unit: 'piece',
        energy: 200,
        protein: 8,
        carbs: 36,
        fat: 4,
      ),
      _item(
        name: 'Curd',
        quantity: 150,
        unit: 'g',
        energy: 90,
        protein: 5,
        carbs: 7,
        fat: 4,
      ),
    ],
  );
}

MealLoggingDraftItem _item({
  required String name,
  required num quantity,
  required String unit,
  required num energy,
  required num protein,
  required num carbs,
  required num fat,
}) {
  return MealLoggingDraftItem(
    displayName: name,
    quantity: quantity,
    servingUnit: unit,
    consumedNutritionSnapshot: NutritionSnapshot(
      schemaVersion: 1,
      nutrients: {
        NutrientId.energy: energy,
        NutrientId.protein: protein,
        NutrientId.carbohydrate: carbs,
        NutrientId.fat: fat,
      },
    ),
  );
}
