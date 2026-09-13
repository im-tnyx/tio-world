import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tio_core/core.dart';
import 'package:tio_feature_nutrition/nutrition.dart';
import 'package:tio_shared/shared.dart';

const _openEditorKey = ValueKey('open-quick-add-policy-test');
final _now = DateTime(2026, 9, 12, 12);

void main() {
  testWidgets('Quick Add shows locked max/precision copy and gates the CTA',
      (tester) async {
    await _openEditor(tester);

    final primary = find.byKey(const ValueKey('meal-log-footer-primary'));
    final calories = find.byKey(const ValueKey('quick-add-calories'));
    final carbs = find.byKey(const ValueKey('quick-add-carbs'));

    await tester.enterText(calories, '10000');
    await tester.pumpAndSettle();
    expect(tester.widget<TioButton>(primary).onPressed, isNotNull);

    await tester.enterText(calories, '10000.1');
    await tester.pumpAndSettle();
    expect(find.text('Calories must be 10000 or less.'), findsOneWidget);
    expect(tester.widget<TioButton>(primary).onPressed, isNull);

    await tester.enterText(calories, '9999.99');
    await tester.pumpAndSettle();
    expect(find.text('Use at most 1 decimal place.'), findsOneWidget);
    expect(tester.widget<TioButton>(primary).onPressed, isNull);

    await tester.enterText(calories, '10000');
    await tester.enterText(carbs, '1000.1');
    await tester.pumpAndSettle();
    expect(find.text('Carbs must be 1000 or less.'), findsOneWidget);
    expect(tester.widget<TioButton>(primary).onPressed, isNull);

    await tester.enterText(carbs, '999.99');
    await tester.pumpAndSettle();
    expect(find.text('Use at most 1 decimal place.'), findsOneWidget);
    expect(tester.widget<TioButton>(primary).onPressed, isNull);

    await tester.enterText(carbs, '');
    await tester.pumpAndSettle();
    expect(find.text('Carbs must be 1000 or less.'), findsNothing);
    expect(find.text('Use at most 1 decimal place.'), findsNothing);
    expect(tester.widget<TioButton>(primary).onPressed, isNotNull);
  });

  testWidgets(
      'legacy out-of-policy Quick Edit hydrates unchanged and blocks save '
      'until corrected', (tester) async {
    await _openEditor(tester, initialEntry: _legacyEntry());

    final primary = find.byKey(const ValueKey('meal-log-footer-primary'));
    final calories = find.byKey(const ValueKey('quick-add-calories'));

    expect(_fieldText(tester, 'quick-add-calories'), '15000');
    expect(find.text('Calories must be 10000 or less.'), findsOneWidget);
    expect(tester.widget<TioButton>(primary).onPressed, isNull);

    await tester.enterText(calories, '10000');
    await tester.pumpAndSettle();

    expect(find.text('Calories must be 10000 or less.'), findsNothing);
    expect(tester.widget<TioButton>(primary).onPressed, isNotNull);
  });
}

Future<void> _openEditor(
  WidgetTester tester, {
  MealLogEntry? initialEntry,
}) async {
  final categories = InMemoryMealCategoriesRepository();
  final mealLogs = _NoopMealLogRepository(initialEntry);

  await tester.pumpWidget(
    MaterialApp(
      builder: (context, child) => TioTheme(
        config: const TioThemeConfig(mode: TioThemeMode.light),
        child: child ?? const SizedBox.shrink(),
      ),
      home: Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            key: _openEditorKey,
            onPressed: () async {
              await showQuickAddEditorSheet(
                context,
                clock: () => _now,
                mealCategoriesRepository: categories,
                mealLogRepository: mealLogs,
                initialEntry: initialEntry,
              );
            },
            child: const Text('Open'),
          ),
        ),
      ),
    ),
  );

  await tester.tap(find.byKey(_openEditorKey));
  await tester.pumpAndSettle();
  expect(find.byKey(const ValueKey('quick-add-editor')), findsOneWidget);
}

Finder _editableFinder(String key) => find.descendant(
      of: find.byKey(ValueKey(key)),
      matching: find.byType(EditableText),
    );

String _fieldText(WidgetTester tester, String key) =>
    tester.widget<EditableText>(_editableFinder(key)).controller.text;

final class _NoopMealLogRepository
    implements MealLogRepository, ManualMealLogUpdateRepository {
  _NoopMealLogRepository(this.initialEntry);

  final MealLogEntry? initialEntry;

  @override
  Future<MealLogEntry> createManual(ManualMealLogCreate input) =>
      throw UnimplementedError();

  @override
  Future<MealLogEntry> updateManual(ManualMealLogUpdate input) =>
      throw UnimplementedError();

  @override
  Future<MealLogEntry?> readById(String id) async => initialEntry;

  @override
  Future<List<MealLogEntry>> listByLocalDate(
    MealLogLocalDate localDate,
  ) async =>
      const [];
}

MealLogEntry _legacyEntry() {
  return MealLogEntry.manual(
    id: 'legacy-meal',
    userId: 'user-1',
    mealCategoryId: 'meal_slot_2',
    mealName: 'Legacy meal',
    note: 'Preserve note',
    consumedAt: DateTime.utc(2026, 9, 12, 4, 45),
    consumedLocalDate: MealLogLocalDate(year: 2026, month: 9, day: 12),
    consumedTimezoneId: 'Asia/Kolkata',
    consumedUtcOffsetMinutes: 330,
    captureSource: MealLogCaptureSource.quickAdd,
    manualNutritionSnapshot: NutritionSnapshot(
      schemaVersion: 1,
      nutrients: {
        NutrientId.energy: 15000,
        NutrientId.carbohydrate: 50,
        NutrientId.protein: 20,
        NutrientId.fat: 12,
      },
    ),
    revision: 3,
    createdAt: DateTime.utc(2026, 9, 12, 4, 46),
    updatedAt: DateTime.utc(2026, 9, 12, 4, 47),
  );
}
