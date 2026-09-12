import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tio_core/core.dart';
import 'package:tio_feature_nutrition/nutrition.dart';

Future<void> _pump(
  WidgetTester tester, {
  required MealDiaryDisplayPreferencesController controller,
}) async {
  await controller.load();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        mealDiaryDisplayPreferencesControllerProvider.overrideWith(
          (ref) => controller,
        ),
      ],
      child: MaterialApp(
        builder: (context, child) => TioTheme(
          config: const TioThemeConfig(mode: TioThemeMode.light),
          child: child ?? const SizedBox.shrink(),
        ),
        home: MealDiarySettingsPage(onMealCategoriesPressed: () {}),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Switch _switchIn(WidgetTester tester, String key) {
  return tester.widget<Switch>(
    find.descendant(
      of: find.byKey(ValueKey(key)),
      matching: find.byType(Switch),
    ),
  );
}

void main() {
  testWidgets('N14 defaults render true, true, false', (tester) async {
    final controller = MealDiaryDisplayPreferencesController(_MemoryRepository());

    await _pump(tester, controller: controller);

    expect(
      _switchIn(tester, 'meal-diary-settings-show-times').value,
      isTrue,
    );
    expect(
      _switchIn(tester, 'meal-diary-settings-meal-notes').value,
      isTrue,
    );
    expect(
      _switchIn(tester, 'meal-diary-settings-note-preview').value,
      isFalse,
    );
    expect(
      _switchIn(tester, 'meal-diary-settings-section-nutrition').value,
      isTrue,
    );
  });

  testWidgets(
      'one section nutrition switch exists and toggling it changes '
      'canonical state', (tester) async {
    final repository = _MemoryRepository();
    final controller = MealDiaryDisplayPreferencesController(repository);

    await _pump(tester, controller: controller);

    expect(
      find.byKey(const ValueKey('meal-diary-settings-section-nutrition')),
      findsOneWidget,
    );
    // The owner lock is one switch for the whole trailing group, never
    // separate Calories/Protein rows.
    expect(find.textContaining('Calories'), findsNothing);
    expect(find.textContaining('Protein'), findsNothing);

    await tester.tap(
      find.byKey(const ValueKey('meal-diary-settings-section-nutrition')),
    );
    await tester.pumpAndSettle();

    expect(controller.preferences.showMealSectionNutrition, isFalse);
    expect(repository.value.showMealSectionNutrition, isFalse);
    expect(
      _switchIn(tester, 'meal-diary-settings-section-nutrition').value,
      isFalse,
    );
  });

  testWidgets('Meal Notes OFF disables preview without clearing its value',
      (tester) async {
    final repository = _MemoryRepository(
      value: const MealDiaryDisplayPreferences(showMealNotePreview: true),
    );
    final controller = MealDiaryDisplayPreferencesController(repository);

    await _pump(tester, controller: controller);

    expect(
      _switchIn(tester, 'meal-diary-settings-note-preview').value,
      isTrue,
    );
    expect(
      _switchIn(tester, 'meal-diary-settings-note-preview').onChanged,
      isNotNull,
    );

    await tester.tap(
      find.byKey(const ValueKey('meal-diary-settings-meal-notes')),
    );
    await tester.pumpAndSettle();

    final disabledPreview =
        _switchIn(tester, 'meal-diary-settings-note-preview');
    expect(controller.preferences.mealNotesEnabled, isFalse);
    expect(controller.preferences.showMealNotePreview, isTrue);
    expect(repository.value.showMealNotePreview, isTrue);
    expect(disabledPreview.value, isTrue);
    expect(disabledPreview.onChanged, isNull);

    await tester.tap(
      find.byKey(const ValueKey('meal-diary-settings-meal-notes')),
    );
    await tester.pumpAndSettle();

    final restoredPreview =
        _switchIn(tester, 'meal-diary-settings-note-preview');
    expect(controller.preferences.mealNotesEnabled, isTrue);
    expect(restoredPreview.value, isTrue);
    expect(restoredPreview.onChanged, isNotNull);
  });

  testWidgets('save failure restores confirmed state and surfaces an error',
      (tester) async {
    final repository = _MemoryRepository(writeError: StateError('disk full'));
    final controller = MealDiaryDisplayPreferencesController(repository);

    await _pump(tester, controller: controller);

    await tester.tap(
      find.byKey(const ValueKey('meal-diary-settings-show-times')),
    );
    await tester.pumpAndSettle();

    expect(controller.preferences.showMealTimes, isTrue);
    expect(
      _switchIn(tester, 'meal-diary-settings-show-times').value,
      isTrue,
    );
    expect(
      find.byKey(const ValueKey('meal-diary-settings-save-error')),
      findsOneWidget,
    );
  });

  testWidgets('disabled preview row is inert while Meal Notes is OFF',
      (tester) async {
    final controller = MealDiaryDisplayPreferencesController(
      _MemoryRepository(
        value: const MealDiaryDisplayPreferences(mealNotesEnabled: false),
      ),
    );

    await _pump(tester, controller: controller);

    final row = find.byKey(
      const ValueKey('meal-diary-settings-note-preview'),
    );
    expect(
      _switchIn(tester, 'meal-diary-settings-note-preview').onChanged,
      isNull,
    );

    await tester.tap(row);
    await tester.pumpAndSettle();

    expect(controller.preferences.mealNotesEnabled, isFalse);
    expect(controller.preferences.showMealNotePreview, isFalse);
  });
}

class _MemoryRepository implements MealDiaryDisplayPreferencesRepository {
  _MemoryRepository({
    this.value = const MealDiaryDisplayPreferences(),
    this.writeError,
  });

  MealDiaryDisplayPreferences value;
  final Object? writeError;

  @override
  Future<MealDiaryDisplayPreferences> read() async => value;

  @override
  Future<void> write(MealDiaryDisplayPreferences preferences) async {
    if (writeError case final error?) throw error;
    value = preferences;
  }

  @override
  Future<void> clear() async => value = const MealDiaryDisplayPreferences();
}
