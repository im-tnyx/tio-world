import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tio_core/core.dart';
import 'package:tio_feature_nutrition/nutrition.dart';
import 'package:tio_shared/shared.dart';

final _today = DateTime(2026, 9, 11, 12);

void main() {
  testWidgets('renders dynamic sections and default time/note presentation',
      (tester) async {
    final dateController = MealDiaryDateController(clock: () => _today);
    addTearDown(dateController.dispose);
    final categories = _FakeMealCategoriesRepository(
      MealCategoriesConfig.canonicalDefaults(),
    );
    final mealLogs = _ImmediateMealLogRepository({
      _localDate(11): [
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
          note: 'Workout ke baad liya tha',
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

    await _pump(
      tester,
      dateController: dateController,
      mealLogs: mealLogs,
      categories: categories,
    );
    await tester.pumpAndSettle();

    expect(find.text('Quick Add'), findsOneWidget);
    expect(find.text('620 kcal · 38g protein'), findsOneWidget);
    expect(find.byKey(const ValueKey('meal-diary-entry-note-lunch-new')),
        findsOneWidget);
    expect(
      find.byKey(const ValueKey('meal-diary-entry-note-preview-lunch-new')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('meal-diary-entry-time-lunch-new')),
      findsOneWidget,
    );

    final lunchY = tester
        .getTopLeft(find.byKey(const ValueKey('meal-diary-section-meal_slot_2')))
        .dy;
    final breakfastY = tester
        .getTopLeft(find.byKey(const ValueKey('meal-diary-section-meal_slot_1')))
        .dy;
    expect(lunchY, lessThan(breakfastY));

    final newestLunchY = tester
        .getTopLeft(find.byKey(const ValueKey('meal-diary-entry-lunch-new')))
        .dy;
    final olderLunchY = tester
        .getTopLeft(find.byKey(const ValueKey('meal-diary-entry-lunch-old')))
        .dy;
    expect(newestLunchY, lessThan(olderLunchY));
  });

  testWidgets('display preferences hide time and reveal one-line note preview',
      (tester) async {
    final dateController = MealDiaryDateController(clock: () => _today);
    addTearDown(dateController.dispose);
    final categories = _FakeMealCategoriesRepository(
      MealCategoriesConfig.canonicalDefaults(),
    );
    final mealLogs = _ImmediateMealLogRepository({
      _localDate(11): [
        _entry(
          id: 'meal',
          categoryId: 'meal_slot_2',
          mealName: 'Banana Shake',
          note: 'Workout ke baad liya tha aur note kaafi lamba hai',
          consumedAt: DateTime.utc(2026, 9, 11, 9, 50),
          calories: 254,
          protein: 9,
        ),
      ],
    });
    final preferences = MealDiaryDisplayPreferencesController(
      _FakeDisplayPreferencesRepository(
        const MealDiaryDisplayPreferences(
          showMealTimes: false,
          mealNotesEnabled: true,
          showMealNotePreview: true,
        ),
      ),
    );
    addTearDown(preferences.dispose);
    await preferences.load();

    await _pump(
      tester,
      dateController: dateController,
      mealLogs: mealLogs,
      categories: categories,
      preferences: preferences,
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('meal-diary-entry-time-meal')),
      findsNothing,
    );
    final preview = tester.widget<Text>(
      find.byKey(const ValueKey('meal-diary-entry-note-preview-meal')),
    );
    expect(preview.maxLines, 1);
    expect(preview.overflow, TextOverflow.ellipsis);
  });

  testWidgets('a slower old date read cannot overwrite the newer selection',
      (tester) async {
    final dateController = MealDiaryDateController(clock: () => _today);
    addTearDown(dateController.dispose);
    final categories = _FakeMealCategoriesRepository(
      MealCategoriesConfig.canonicalDefaults(),
    );
    final mealLogs = _ControlledMealLogRepository();

    await _pump(
      tester,
      dateController: dateController,
      mealLogs: mealLogs,
      categories: categories,
    );
    await tester.pump();
    expect(mealLogs.requests, [_localDate(11)]);

    dateController.select(DateTime(2026, 9, 10));
    await tester.pump();
    expect(mealLogs.requests, [_localDate(11), _localDate(10)]);

    mealLogs.complete(
      _localDate(10),
      [
        _entry(
          id: 'new-date',
          categoryId: 'meal_slot_1',
          mealName: 'Newer selection',
          consumedAt: DateTime.utc(2026, 9, 10, 2),
          calories: 200,
          protein: 10,
          localDay: 10,
        ),
      ],
    );
    await tester.pumpAndSettle();
    expect(find.text('Newer selection'), findsOneWidget);

    mealLogs.complete(
      _localDate(11),
      [
        _entry(
          id: 'old-date',
          categoryId: 'meal_slot_1',
          mealName: 'Old slow result',
          consumedAt: DateTime.utc(2026, 9, 11, 2),
          calories: 100,
          protein: 5,
        ),
      ],
    );
    await tester.pumpAndSettle();

    expect(find.text('Newer selection'), findsOneWidget);
    expect(find.text('Old slow result'), findsNothing);
  });
}

Future<void> _pump(
  WidgetTester tester, {
  required MealDiaryDateController dateController,
  required MealLogRepository mealLogs,
  required MealCategoriesRepository categories,
  MealDiaryDisplayPreferencesController? preferences,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        mealDiaryDateControllerProvider.overrideWith((ref) => dateController),
        mealDiaryMealLogRepositoryProvider.overrideWithValue(mealLogs),
        if (preferences != null)
          mealDiaryDisplayPreferencesControllerProvider
              .overrideWith((ref) => preferences),
      ],
      child: MaterialApp(
        builder: (context, child) => TioTheme(
          config: const TioThemeConfig(mode: TioThemeMode.light),
          child: child ?? const SizedBox.shrink(),
        ),
        home: Scaffold(
          body: MealDiaryPage(mealCategoriesRepository: categories),
        ),
      ),
    ),
  );
}

MealLogLocalDate _localDate(int day) =>
    MealLogLocalDate(year: 2026, month: 9, day: day);

MealLogEntry _entry({
  required String id,
  required String categoryId,
  required String? mealName,
  String? note,
  required DateTime consumedAt,
  required num calories,
  required num protein,
  int localDay = 11,
}) {
  return MealLogEntry.manual(
    id: id,
    userId: 'user-1',
    mealCategoryId: categoryId,
    mealName: mealName,
    note: note,
    consumedAt: consumedAt,
    consumedLocalDate: _localDate(localDay),
    consumedUtcOffsetMinutes: 330,
    captureSource: MealLogCaptureSource.quickAdd,
    manualNutritionSnapshot: NutritionSnapshot(
      schemaVersion: 1,
      nutrients: {
        NutrientId.energy: calories,
        NutrientId.protein: protein,
      },
    ),
    createdAt: DateTime.utc(2026, 9, localDay),
    updatedAt: DateTime.utc(2026, 9, localDay),
  );
}

final class _ImmediateMealLogRepository implements MealLogRepository {
  _ImmediateMealLogRepository(this.entriesByDate);

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

final class _ControlledMealLogRepository implements MealLogRepository {
  final Map<MealLogLocalDate, Completer<List<MealLogEntry>>> _completers = {};
  final List<MealLogLocalDate> requests = [];

  @override
  Future<MealLogEntry> createManual(ManualMealLogCreate input) =>
      throw UnimplementedError();

  @override
  Future<List<MealLogEntry>> listByLocalDate(MealLogLocalDate localDate) {
    requests.add(localDate);
    return (_completers[localDate] ??= Completer<List<MealLogEntry>>()).future;
  }

  void complete(MealLogLocalDate date, List<MealLogEntry> entries) {
    _completers[date]!.complete(entries);
  }

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

final class _FakeDisplayPreferencesRepository
    implements MealDiaryDisplayPreferencesRepository {
  _FakeDisplayPreferencesRepository(this.value);

  MealDiaryDisplayPreferences value;

  @override
  Future<void> clear() async {
    value = const MealDiaryDisplayPreferences();
  }

  @override
  Future<MealDiaryDisplayPreferences> read() async => value;

  @override
  Future<void> write(MealDiaryDisplayPreferences preferences) async {
    value = preferences;
  }
}
