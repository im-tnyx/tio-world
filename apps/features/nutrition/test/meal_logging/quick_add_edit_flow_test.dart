import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tio_core/core.dart';
import 'package:tio_feature_nutrition/nutrition.dart';
import 'package:tio_shared/shared.dart';

void main() {
  testWidgets(
      'card tap reads canonical row and Quick Edit saves the same identity',
      (tester) async {
    final now = DateTime(2026, 9, 12, 11);
    final dateController = MealDiaryDateController(clock: () => now);
    final repository = _EditableMealLogRepository(_entry());
    final categories = _MealCategoriesRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          mealDiaryDateControllerProvider.overrideWith(
            (ref) => dateController,
          ),
          mealDiaryMealLogRepositoryProvider.overrideWithValue(repository),
        ],
        child: MaterialApp(
          builder: (context, child) => TioTheme(
            config: const TioThemeConfig(mode: TioThemeMode.light),
            child: child ?? const SizedBox.shrink(),
          ),
          home: Scaffold(
            body: MealDiaryPage(
              quickAddClock: () => now,
              mealCategoriesRepository: categories,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final selectedBefore = dateController.selectedDate;
    await tester.tap(
      find.byKey(const ValueKey('meal-diary-entry-meal-1')),
    );
    await tester.pumpAndSettle();

    expect(repository.readIds, ['meal-1']);
    expect(find.text('Quick Edit'), findsOneWidget);
    expect(find.text('Save Changes'), findsOneWidget);
    expect(find.text('Log Meal'), findsNothing);
    expect(_fieldText(tester, 'quick-add-meal-name'), 'Dal and roti');
    expect(_fieldText(tester, 'quick-add-calories'), '400');
    expect(_fieldText(tester, 'quick-add-carbs'), '50');
    expect(_fieldText(tester, 'quick-add-protein'), '20');
    expect(_fieldText(tester, 'quick-add-fat'), '12');
    expect(find.text('Lunch'), findsWidgets);

    await tester.enterText(
      _editableFinder('quick-add-meal-name'),
      'Updated dal and roti',
    );
    await tester.enterText(_editableFinder('quick-add-calories'), '425');
    await tester.tap(find.text('Save Changes'));
    await tester.pumpAndSettle();

    expect(repository.inputs, hasLength(1));
    final input = repository.inputs.single;
    expect(input.id, 'meal-1');
    expect(input.expectedRevision, 3);
    expect(input.note, 'Preserve this note');
    expect(input.manualNutritionSnapshot.amountFor(NutrientId.energy), 425);
    expect(repository.current.id, 'meal-1');
    expect(repository.current.captureSource, MealLogCaptureSource.quickAdd);
    expect(repository.current.mode, MealLogMode.manual);
    expect(repository.current.revision, 4);
    expect(repository.listRequests.length, greaterThanOrEqualTo(2));
    expect(dateController.selectedDate, selectedBefore);
    expect(find.text('Updated dal and roti'), findsOneWidget);
  });
}

Finder _editableFinder(String key) => find.descendant(
      of: find.byKey(ValueKey(key)),
      matching: find.byType(EditableText),
    );

String _fieldText(WidgetTester tester, String key) =>
    tester.widget<EditableText>(_editableFinder(key)).controller.text;

final class _EditableMealLogRepository
    implements MealLogRepository, ManualMealLogUpdateRepository {
  _EditableMealLogRepository(this.current);

  MealLogEntry current;
  final List<String> readIds = [];
  final List<MealLogLocalDate> listRequests = [];
  final List<ManualMealLogUpdate> inputs = [];

  @override
  Future<MealLogEntry?> readById(String id) async {
    readIds.add(id);
    return current.id == id ? current : null;
  }

  @override
  Future<List<MealLogEntry>> listByLocalDate(MealLogLocalDate localDate) async {
    listRequests.add(localDate);
    return current.consumedLocalDate == localDate ? [current] : const [];
  }

  @override
  Future<MealLogEntry> updateManual(ManualMealLogUpdate input) async {
    inputs.add(input);
    final previous = current;
    current = MealLogEntry.manual(
      id: previous.id,
      userId: previous.userId,
      mealCategoryId: input.mealCategoryId,
      mealName: input.mealName,
      note: input.note,
      consumedAt: input.consumedAt,
      consumedLocalDate: input.consumedLocalDate,
      consumedTimezoneId: input.consumedTimezoneId,
      consumedUtcOffsetMinutes: input.consumedUtcOffsetMinutes,
      captureSource: previous.captureSource,
      manualNutritionSnapshot: input.manualNutritionSnapshot,
      revision: input.expectedRevision + 1,
      createdAt: previous.createdAt,
      updatedAt: previous.updatedAt.add(const Duration(minutes: 1)),
    );
    return current;
  }

  @override
  Future<MealLogEntry> createManual(ManualMealLogCreate input) =>
      throw UnimplementedError();
}

final class _MealCategoriesRepository implements MealCategoriesRepository {
  @override
  Future<MealCategoriesConfig> read() async =>
      MealCategoriesConfig.canonicalDefaults();

  @override
  Future<void> upsert(MealCategoriesConfig config) =>
      throw UnimplementedError();
}

MealLogEntry _entry() {
  return MealLogEntry.manual(
    id: 'meal-1',
    userId: 'user-1',
    mealCategoryId: 'meal_slot_2',
    mealName: 'Dal and roti',
    note: 'Preserve this note',
    consumedAt: DateTime.utc(2026, 9, 12, 4, 45),
    consumedLocalDate: MealLogLocalDate(year: 2026, month: 9, day: 12),
    consumedTimezoneId: 'Asia/Kolkata',
    consumedUtcOffsetMinutes: 330,
    captureSource: MealLogCaptureSource.quickAdd,
    manualNutritionSnapshot: NutritionSnapshot(
      schemaVersion: 1,
      nutrients: {
        NutrientId.energy: 400,
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
