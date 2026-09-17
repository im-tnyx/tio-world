import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tio_core/core.dart';
import 'package:tio_feature_nutrition/nutrition.dart';
import 'package:tio_shared/shared.dart';

void main() {
  testWidgets(
      'renders the approved create body and keeps footer disabled without save context',
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

  testWidgets('complete context activates Log Meal and emits canonical result',
      (tester) async {
    final repository = _WidgetRepository();
    MealLogEntry? created;
    await _pumpEditor(
      tester,
      draft: _completeDraft(),
      repository: repository,
      onCreated: (entry) => created = entry,
    );

    final primary = find.byKey(const ValueKey('meal-log-footer-primary'));
    expect(tester.widget<TioButton>(primary).onPressed, isNotNull);

    await tester.tap(primary);
    await tester.pumpAndSettle();

    expect(repository.inputs, hasLength(1));
    expect(repository.inputs.single.mealCategoryId, 'lunch');
    expect(repository.inputs.single.items, hasLength(2));
    expect(created, same(repository.result));
  });

  testWidgets(
      'in-flight submit uses existing loading state and suppresses duplicate tap',
      (tester) async {
    final repository = _BlockingWidgetRepository();
    await _pumpEditor(
      tester,
      draft: _completeDraft(),
      repository: repository,
    );

    final primary = find.byKey(const ValueKey('meal-log-footer-primary'));
    await tester.tap(primary);
    await tester.pump();

    expect(repository.inputs, hasLength(1));
    expect(tester.widget<TioButton>(primary).loading, isTrue);
    await tester.tap(primary);
    await tester.pump();
    expect(repository.inputs, hasLength(1));

    repository.complete();
    await tester.pumpAndSettle();
  });

  testWidgets('failed save shows concise footer note and draft stays editable',
      (tester) async {
    final repository = _WidgetRepository(failuresBeforeSuccess: 1);
    await _pumpEditor(
      tester,
      draft: _completeDraft(),
      repository: repository,
    );

    final primary = find.byKey(const ValueKey('meal-log-footer-primary'));
    await tester.tap(primary);
    await tester.pumpAndSettle();

    expect(find.text("Couldn't log meal. Try again."), findsOneWidget);
    final name = find.byKey(const ValueKey('meal-editor-meal-name'));
    expect(name, findsOneWidget);
    await tester.enterText(name, 'Edited after failure');
    await tester.pump();
    expect(find.text("Couldn't log meal. Try again."), findsNothing);
  });

  testWidgets(
      'ambiguous save locks draft controls and keeps frozen retry available',
      (tester) async {
    final repository = _WidgetRepository(outcomeUnknownBeforeSuccess: 1);
    MealLogEntry? created;
    var categoryTaps = 0;
    var dateTimeTaps = 0;
    var backTaps = 0;

    await _pumpEditor(
      tester,
      draft: _completeDraft(),
      repository: repository,
      onCreated: (entry) => created = entry,
      onBack: () => backTaps++,
      onMealCategoryTap: () => categoryTaps++,
      onDateTimeTap: () => dateTimeTaps++,
    );

    final primary = find.byKey(const ValueKey('meal-log-footer-primary'));
    await tester.tap(primary);
    await tester.pumpAndSettle();

    expect(
      find.text(MealEditorDetailedCreateController.outcomeUnknownMessage),
      findsOneWidget,
    );
    expect(repository.inputs, hasLength(1));
    expect(tester.widget<TioButton>(primary).onPressed, isNotNull);
    expect(
      tester
          .widget<TioInput>(find.byKey(const ValueKey('meal-editor-meal-name')))
          .enabled,
      isFalse,
    );
    expect(
      tester
          .widget<IconButton>(
            find.byKey(const ValueKey('meal-editor-quantity-plus-0')),
          )
          .onPressed,
      isNull,
    );
    expect(
      tester
          .widget<IconButton>(find.byKey(const ValueKey('meal-editor-delete-0')))
          .onPressed,
      isNull,
    );
    expect(tester.widget<BackButton>(find.byType(BackButton)).onPressed, isNull);

    await tester.tap(find.byKey(const ValueKey('meal-log-footer-category')));
    await tester.tap(find.byKey(const ValueKey('meal-log-footer-date-time')));
    await tester.pump();
    expect(categoryTaps, 0);
    expect(dateTimeTaps, 0);
    expect(backTaps, 0);

    await tester.tap(primary);
    await tester.pumpAndSettle();

    expect(repository.inputs, hasLength(2));
    expect(
      repository.inputs[1].clientMutationId,
      repository.inputs[0].clientMutationId,
    );
    expect(created, same(repository.result));
  });

  testWidgets(
      'incomplete draft remains disabled even when repository/context exist',
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

    await _pumpEditor(
      tester,
      draft: draft,
      repository: _WidgetRepository(),
    );

    expect(find.text('180 kcal'), findsWidgets);
    expect(find.text('— g'), findsNWidgets(3));
    expect(find.text('Quantity unknown'), findsOneWidget);
    expect(find.text('Unit unknown'), findsOneWidget);
    final primary = find.byKey(const ValueKey('meal-log-footer-primary'));
    expect(tester.widget<TioButton>(primary).onPressed, isNull);
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
    expect(find.byKey(const ValueKey('meal-editor-nutrition-summary')),
        findsOneWidget);
    expect(find.byKey(const ValueKey('meal-log-footer-primary')), findsOneWidget);
  });
}

Future<void> _pumpEditor(
  WidgetTester tester, {
  required MealLoggingDraft draft,
  TextScaler textScaler = TextScaler.noScaling,
  TioThemeMode mode = TioThemeMode.light,
  DetailedMealLogCreateRepository? repository,
  ValueChanged<MealLogEntry>? onCreated,
  VoidCallback? onBack,
  VoidCallback? onMealCategoryTap,
  VoidCallback? onDateTimeTap,
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
        mealCategoryId: repository == null ? null : 'lunch',
        consumedLocalDateTime:
            repository == null ? null : DateTime(2026, 9, 16, 13, 15),
        detailedCreateRepository: repository,
        onCreated: onCreated,
        onBack: onBack ?? () {},
        onMealCategoryTap: onMealCategoryTap,
        onDateTimeTap: onDateTimeTap,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

class _WidgetRepository implements DetailedMealLogCreateRepository {
  _WidgetRepository({
    this.failuresBeforeSuccess = 0,
    this.outcomeUnknownBeforeSuccess = 0,
  });

  int failuresBeforeSuccess;
  int outcomeUnknownBeforeSuccess;
  final inputs = <DetailedMealLogCreate>[];
  final result = _entry();

  @override
  Future<MealLogEntry> createDetailed(DetailedMealLogCreate input) async {
    inputs.add(input);
    if (outcomeUnknownBeforeSuccess > 0) {
      outcomeUnknownBeforeSuccess--;
      throw MealLogCreateOutcomeUnknown(
        clientMutationId: input.clientMutationId,
      );
    }
    if (failuresBeforeSuccess > 0) {
      failuresBeforeSuccess--;
      throw Exception('network');
    }
    return result;
  }
}

class _BlockingWidgetRepository implements DetailedMealLogCreateRepository {
  final inputs = <DetailedMealLogCreate>[];
  final _completer = Completer<MealLogEntry>();

  @override
  Future<MealLogEntry> createDetailed(DetailedMealLogCreate input) {
    inputs.add(input);
    return _completer.future;
  }

  void complete() => _completer.complete(_entry());
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

MealLogEntry _entry() => MealLogEntry.detailed(
      id: 'entry-id',
      userId: 'user-id',
      mealCategoryId: 'lunch',
      mealName: 'Roti and curd',
      consumedAt: DateTime.utc(2026, 9, 16, 7, 45),
      consumedLocalDate: MealLogLocalDate(year: 2026, month: 9, day: 16),
      consumedUtcOffsetMinutes: 330,
      captureSource: MealLogCaptureSource.text,
      detailedItems: [
        MealLogItemSnapshot(
          id: 'item-id',
          mealLogEntryId: 'entry-id',
          displayName: 'Roti',
          quantity: 2,
          servingUnit: 'piece',
          nutritionSnapshot: NutritionSnapshot(
            schemaVersion: 1,
            nutrients: const {NutrientId.energy: 200},
          ),
        ),
      ],
      createdAt: DateTime.utc(2026, 9, 16, 7, 46),
      updatedAt: DateTime.utc(2026, 9, 16, 7, 46),
    );
