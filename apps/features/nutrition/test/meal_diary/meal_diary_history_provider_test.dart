import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tio_feature_nutrition/nutrition.dart';
import 'package:tio_shared/shared.dart';

void main() {
  final selectedDate = MealLogLocalDate(year: 2026, month: 9, day: 11);

  test('groups by retained category and orders latest activity first', () async {
    final categories = MealCategoriesConfig(
      items: [
        for (final item in MealCategoriesConfig.canonicalDefaults().orderedItems)
          if (item.id == 'meal_slot_2')
            item.renamed('Lunch Break').withActive(false)
          else
            item,
      ],
    );
    final repository = _FakeMealLogRepository({
      selectedDate: [
        _entry(
          id: 'breakfast',
          categoryId: 'meal_slot_1',
          mealName: 'Oats',
          consumedAt: DateTime.utc(2026, 9, 11, 2, 40),
          calories: 300,
          protein: 15,
        ),
        _entry(
          id: 'lunch-new',
          categoryId: 'meal_slot_2',
          mealName: null,
          captureSource: MealLogCaptureSource.quickAdd,
          note: 'Workout ke baad',
          consumedAt: DateTime.utc(2026, 9, 11, 9, 50),
          calories: 254,
          protein: 9,
        ),
        _entry(
          id: 'lunch-old',
          categoryId: 'meal_slot_2',
          mealName: 'Dal, 2 Roti, Ghee',
          consumedAt: DateTime.utc(2026, 9, 11, 7, 35),
          calories: 366,
          protein: 29,
        ),
      ],
    });
    final request = MealDiaryHistoryRequest(
      mealLogRepository: repository,
      mealCategoriesRepository: _FakeMealCategoriesRepository(categories),
      localDate: selectedDate,
    );
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final model = await container.read(mealDiaryHistoryProvider(request).future);

    expect(model.sections.map((section) => section.categoryDisplayName), [
      'Lunch Break',
      'Breakfast',
    ]);
    final lunch = model.sections.first;
    expect(lunch.entries.map((entry) => entry.id), ['lunch-new', 'lunch-old']);
    expect(lunch.caloriesKcal, 620);
    expect(lunch.proteinGrams, 38);
    expect(lunch.entries.first.displayTitle, 'Quick Add');
    expect(lunch.entries.first.note, 'Workout ke baad');
    expect(lunch.entries.first.loggedLocalDateTime?.hour, 15);
    expect(lunch.entries.first.loggedLocalDateTime?.minute, 20);
  });

  test('empty day does not depend on Meal Categories availability', () async {
    final categories = _ThrowingMealCategoriesRepository();
    final request = MealDiaryHistoryRequest(
      mealLogRepository: _FakeMealLogRepository(const {}),
      mealCategoriesRepository: categories,
      localDate: selectedDate,
    );
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final model = await container.read(mealDiaryHistoryProvider(request).future);

    expect(model.localDate, selectedDate);
    expect(model.isEmpty, isTrue);
    expect(categories.readCount, 0);
  });

  test('does not label an unnamed non-Quick-Add event as Quick Add', () async {
    final repository = _FakeMealLogRepository({
      selectedDate: [
        _entry(
          id: 'text-entry',
          categoryId: 'meal_slot_1',
          mealName: null,
          captureSource: MealLogCaptureSource.text,
          consumedAt: DateTime.utc(2026, 9, 11, 3),
          calories: 100,
          protein: 5,
        ),
      ],
    });
    final request = MealDiaryHistoryRequest(
      mealLogRepository: repository,
      mealCategoriesRepository:
          _FakeMealCategoriesRepository(MealCategoriesConfig.canonicalDefaults()),
      localDate: selectedDate,
    );
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final model = await container.read(mealDiaryHistoryProvider(request).future);

    expect(model.sections.single.entries.single.displayTitle, isNull);
  });

  test('unknown nutrient makes only that section aggregate unknown', () async {
    final repository = _FakeMealLogRepository({
      selectedDate: [
        _entry(
          id: 'known',
          categoryId: 'meal_slot_1',
          mealName: 'Known',
          consumedAt: DateTime.utc(2026, 9, 11, 4),
          calories: 100,
          protein: 10,
        ),
        _entry(
          id: 'missing-protein',
          categoryId: 'meal_slot_1',
          mealName: 'Missing protein',
          consumedAt: DateTime.utc(2026, 9, 11, 5),
          calories: 50,
          protein: null,
        ),
      ],
    });
    final request = MealDiaryHistoryRequest(
      mealLogRepository: repository,
      mealCategoriesRepository:
          _FakeMealCategoriesRepository(MealCategoriesConfig.canonicalDefaults()),
      localDate: selectedDate,
    );
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final section =
        (await container.read(mealDiaryHistoryProvider(request).future))
            .sections
            .single;

    expect(section.caloriesKcal, 150);
    expect(section.proteinGrams, isNull);
  });

  test('fails closed when a historical category identity cannot resolve', () async {
    final repository = _FakeMealLogRepository({
      selectedDate: [
        _entry(
          id: 'orphan',
          categoryId: 'missing-category',
          mealName: 'Meal',
          consumedAt: DateTime.utc(2026, 9, 11, 5),
          calories: 100,
          protein: 10,
        ),
      ],
    });
    final request = MealDiaryHistoryRequest(
      mealLogRepository: repository,
      mealCategoriesRepository:
          _FakeMealCategoriesRepository(MealCategoriesConfig.canonicalDefaults()),
      localDate: selectedDate,
    );
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await expectLater(
      container.read(mealDiaryHistoryProvider(request).future),
      throwsA(isA<StateError>()),
    );
  });
}

MealLogEntry _entry({
  required String id,
  required String categoryId,
  required String? mealName,
  MealLogCaptureSource? captureSource,
  String? note,
  required DateTime consumedAt,
  required num calories,
  required num? protein,
}) {
  final nutrients = <NutrientId, num>{NutrientId.energy: calories};
  if (protein != null) nutrients[NutrientId.protein] = protein;

  return MealLogEntry.manual(
    id: id,
    userId: 'user-1',
    mealCategoryId: categoryId,
    mealName: mealName,
    note: note,
    consumedAt: consumedAt,
    consumedLocalDate: MealLogLocalDate(year: 2026, month: 9, day: 11),
    consumedUtcOffsetMinutes: 330,
    captureSource: captureSource,
    manualNutritionSnapshot: NutritionSnapshot(
      schemaVersion: 1,
      nutrients: nutrients,
    ),
    createdAt: DateTime.utc(2026, 9, 11),
    updatedAt: DateTime.utc(2026, 9, 11),
  );
}

final class _FakeMealLogRepository implements MealLogRepository {
  _FakeMealLogRepository(this.entriesByDate);

  final Map<MealLogLocalDate, List<MealLogEntry>> entriesByDate;

  @override
  Future<MealLogEntry> createManual(ManualMealLogCreate input) =>
      throw UnimplementedError();

  @override
  Future<List<MealLogEntry>> listByLocalDate(MealLogLocalDate localDate) async =>
      List<MealLogEntry>.unmodifiable(entriesByDate[localDate] ?? const []);

  @override
  Future<MealLogEntry?> readById(String id) => throw UnimplementedError();
}

final class _FakeMealCategoriesRepository implements MealCategoriesRepository {
  _FakeMealCategoriesRepository(this.config);

  final MealCategoriesConfig config;

  @override
  Future<MealCategoriesConfig> read() async => config;

  @override
  Future<void> upsert(MealCategoriesConfig config) => throw UnimplementedError();
}

final class _ThrowingMealCategoriesRepository
    implements MealCategoriesRepository {
  int readCount = 0;

  @override
  Future<MealCategoriesConfig> read() async {
    readCount++;
    throw StateError('Meal Categories unavailable');
  }

  @override
  Future<void> upsert(MealCategoriesConfig config) => throw UnimplementedError();
}
