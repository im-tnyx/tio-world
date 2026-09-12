import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tio_feature_nutrition/nutrition.dart';
import 'package:tio_shared/shared.dart';

void main() {
  test('successful Meal Category write refreshes the same selected-day model',
      () async {
    final localDate = MealLogLocalDate(year: 2026, month: 9, day: 11);
    final categories = InMemoryMealCategoriesRepository();
    final mealLogs = _SingleEntryMealLogRepository(
      _entry(localDate),
    );
    final request = MealDiaryHistoryRequest(
      mealLogRepository: mealLogs,
      mealCategoriesRepository: categories,
      localDate: localDate,
    );
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final provider = mealDiaryHistoryProvider(request);
    final subscription = container.listen(
      provider,
      (_, __) {},
      fireImmediately: true,
    );
    addTearDown(subscription.close);

    final before = await container.read(provider.future);
    expect(before.sections.single.categoryDisplayName, 'Lunch');

    final renamed = MealCategoriesConfig(
      items: [
        for (final item
            in MealCategoriesConfig.canonicalDefaults().orderedItems)
          if (item.id == 'meal_slot_2') item.renamed('Midday') else item,
      ],
    );
    await categories.upsert(renamed);

    // Repository change streams are deliberately asynchronous so a successful
    // write finishes before dependent readers start their refresh.
    await Future<void>.delayed(Duration.zero);

    final after = await container.read(provider.future);
    expect(after.sections.single.categoryDisplayName, 'Midday');
  });
}

MealLogEntry _entry(MealLogLocalDate localDate) {
  return MealLogEntry.manual(
    id: 'lunch-entry',
    userId: 'user-1',
    mealCategoryId: 'meal_slot_2',
    mealName: 'Dal and Roti',
    consumedAt: DateTime.utc(2026, 9, 11, 7, 30),
    consumedLocalDate: localDate,
    consumedUtcOffsetMinutes: 330,
    captureSource: MealLogCaptureSource.quickAdd,
    manualNutritionSnapshot: NutritionSnapshot(
      schemaVersion: 1,
      nutrients: const {
        NutrientId.energy: 420,
        NutrientId.protein: 18,
      },
    ),
    createdAt: DateTime.utc(2026, 9, 11, 7, 30),
    updatedAt: DateTime.utc(2026, 9, 11, 7, 30),
  );
}

final class _SingleEntryMealLogRepository implements MealLogRepository {
  _SingleEntryMealLogRepository(this.entry);

  final MealLogEntry entry;

  @override
  Future<MealLogEntry> createManual(ManualMealLogCreate input) =>
      throw UnimplementedError();

  @override
  Future<List<MealLogEntry>> listByLocalDate(MealLogLocalDate localDate) async {
    return localDate == entry.consumedLocalDate ? [entry] : const [];
  }

  @override
  Future<MealLogEntry?> readById(String id) => throw UnimplementedError();
}
