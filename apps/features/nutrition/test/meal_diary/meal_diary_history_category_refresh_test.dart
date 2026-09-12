import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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

  test('conflict reload refreshes the same selected-day model', () async {
    final localDate = MealLogLocalDate(year: 2026, month: 9, day: 11);
    final initial = MealCategoriesConfig.canonicalDefaults();
    final remote = MealCategoriesConfig(
      items: [
        for (final item in initial.orderedItems)
          if (item.id == 'meal_slot_2') item.renamed('Midday') else item,
      ],
    );
    final gateway = _ConflictMealCategoriesGateway(
      initialConfig: initial,
      conflictConfig: remote,
    );
    final categories = SupabaseMealCategoriesRepository(
      client: _UnusedSupabaseClient(),
      gateway: gateway,
      currentUserId: () => 'user-1',
    );
    final controller = MealCategoriesController(repository: categories);
    addTearDown(controller.dispose);
    await controller.load();

    final mealLogs = _SingleEntryMealLogRepository(_entry(localDate));
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

    final saved = await controller.rename(
      id: 'meal_slot_2',
      displayName: 'Local Lunch',
    );

    expect(saved, isFalse);
    expect(controller.state.actionError, MealCategoriesController.conflictReason);
    expect(
      controller.state.confirmed?.findById('meal_slot_2')?.displayName,
      'Midday',
    );

    // The rejected write itself is not a freshness event. The controller's
    // successful conflict-recovery read observes the newer canonical config,
    // and that observation invalidates the already-mounted Diary provider.
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

class _UnusedSupabaseClient extends Fake implements SupabaseClient {}

final class _ConflictMealCategoriesGateway
    implements MealCategoriesTableGateway {
  _ConflictMealCategoriesGateway({
    required MealCategoriesConfig initialConfig,
    required this.conflictConfig,
  }) : _storedConfig = initialConfig;

  final MealCategoriesConfig conflictConfig;
  MealCategoriesConfig _storedConfig;
  bool _conflictNextWrite = true;

  @override
  Future<Map<String, dynamic>?> readRow(String userId) async {
    return {
      'meal_categories_config': MealCategoriesConfigCodec.encode(_storedConfig),
    };
  }

  @override
  Future<void> upsertRow(Map<String, dynamic> payload) async {
    if (_conflictNextWrite) {
      _conflictNextWrite = false;
      _storedConfig = conflictConfig;
      throw const PostgrestException(
        message: 'concurrent Meal Categories update',
        code: '23514',
      );
    }

    _storedConfig = MealCategoriesConfig.resolve(
      MealCategoriesConfigCodec.decode(payload['meal_categories_config']),
    );
  }
}
