import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tio_core/core.dart';
import 'package:tio_feature_nutrition/nutrition.dart';
import 'package:tio_shared/shared.dart';

void main() {
  testWidgets(
    'returning to Diary refreshes retained Meal Category display labels',
    (tester) async {
      final dateController = MealDiaryDateController(
        clock: () => DateTime(2026, 9, 11, 12),
      );
      final categories = _MutableMealCategoriesRepository(
        MealCategoriesConfig.canonicalDefaults(),
      );
      final mealLogs = _SingleDayMealLogRepository(
        _entry(),
      );

      late final GoRouter router;
      router = GoRouter(
        initialLocation: '/nutrition',
        routes: [
          GoRoute(
            path: '/nutrition',
            builder: (context, state) => Scaffold(
              body: MealDiaryPage(
                mealCategoriesRepository: categories,
              ),
            ),
          ),
          GoRoute(
            path: '/settings',
            builder: (context, state) => const Scaffold(
              body: Center(child: Text('Settings overlay')),
            ),
          ),
        ],
      );
      addTearDown(router.dispose);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            mealDiaryDateControllerProvider.overrideWith(
              (ref) => dateController,
            ),
            mealDiaryMealLogRepositoryProvider.overrideWithValue(mealLogs),
          ],
          child: MaterialApp.router(
            routerConfig: router,
            builder: (context, child) => TioTheme(
              config: const TioThemeConfig(mode: TioThemeMode.light),
              child: child ?? const SizedBox.shrink(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Lunch'), findsOneWidget);
      expect(categories.readCount, 1);

      unawaited(router.push<void>('/settings'));
      await tester.pumpAndSettle();
      expect(find.text('Settings overlay'), findsOneWidget);
      expect(categories.readCount, 1);

      categories.rename('meal_slot_2', 'Midday');

      router.pop();
      await tester.pumpAndSettle();

      expect(categories.readCount, 2);
      expect(find.text('Midday'), findsOneWidget);
      expect(find.text('Lunch'), findsNothing);
    },
  );
}

MealLogEntry _entry() {
  return MealLogEntry.manual(
    id: 'lunch-entry',
    userId: 'user-1',
    mealCategoryId: 'meal_slot_2',
    mealName: 'Dal and Roti',
    consumedAt: DateTime.utc(2026, 9, 11, 7, 30),
    consumedLocalDate: MealLogLocalDate(
      year: 2026,
      month: 9,
      day: 11,
    ),
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

final class _MutableMealCategoriesRepository
    implements MealCategoriesRepository {
  _MutableMealCategoriesRepository(this.config);

  MealCategoriesConfig config;
  int readCount = 0;

  void rename(String id, String displayName) {
    config = MealCategoriesConfig(
      schemaVersion: config.schemaVersion,
      items: [
        for (final item in config.orderedItems)
          if (item.id == id) item.renamed(displayName) else item,
      ],
    );
  }

  @override
  Future<MealCategoriesConfig> read() async {
    readCount += 1;
    return config;
  }

  @override
  Future<void> upsert(MealCategoriesConfig config) async {
    this.config = config;
  }
}

final class _SingleDayMealLogRepository implements MealLogRepository {
  _SingleDayMealLogRepository(this.entry);

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
