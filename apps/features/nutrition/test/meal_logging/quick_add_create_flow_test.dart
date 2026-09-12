import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tio_core/core.dart';
import 'package:tio_feature_nutrition/nutrition.dart';
import 'package:tio_shared/shared.dart';

final _now = DateTime(2026, 9, 12, 10, 30);

void main() {
  testWidgets('valid Quick Add creates durable history and refreshes today',
      (tester) async {
    final categories = InMemoryMealCategoriesRepository();
    final mealLogs = InMemoryMealLogRepository(
      mealCategoriesRepository: categories,
      clock: () => _now,
    );
    final dates = await _pumpDiary(
      tester,
      categories: categories,
      mealLogs: mealLogs,
    );

    await _openQuickAdd(tester);

    final logButton = find.byKey(const ValueKey('meal-log-footer-primary'));
    expect(tester.widget<TioButton>(logButton).onPressed, isNull);

    await tester.enterText(
      find.byKey(const ValueKey('quick-add-calories')),
      '420',
    );
    await tester.enterText(
      find.byKey(const ValueKey('quick-add-protein')),
      '24',
    );
    await tester.pumpAndSettle();

    expect(tester.widget<TioButton>(logButton).onPressed, isNotNull);
    await tester.tap(logButton);
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('quick-add-editor')), findsNothing);
    expect(dates.selectedDate, DateTime(2026, 9, 12));

    final entries = await mealLogs.listByLocalDate(
      MealLogLocalDate(year: 2026, month: 9, day: 12),
    );
    expect(entries, hasLength(1));
    final entry = entries.single;
    expect(entry.captureSource, MealLogCaptureSource.quickAdd);
    expect(entry.mealName, isNull);
    expect(entry.note, isNull);
    expect(entry.manualNutritionSnapshot!.amountFor(NutrientId.energy), 420);
    expect(entry.manualNutritionSnapshot!.amountFor(NutrientId.protein), 24);
    expect(
      entry.manualNutritionSnapshot!.containsNutrient(NutrientId.carbohydrate),
      isFalse,
    );
    expect(entry.manualNutritionSnapshot!.containsNutrient(NutrientId.fat),
        isFalse);

    // Unnamed Quick Add is a presentation fallback only; the stored name above
    // remains null while the refreshed Diary renders the normal card.
    expect(
      find.byKey(const ValueKey('meal-diary-entry-in_memory_meal_log_1')),
      findsOneWidget,
    );
    expect(find.text('Quick Add'), findsOneWidget);
  });

  testWidgets('logging from a historical Diary day never moves its selection',
      (tester) async {
    final categories = InMemoryMealCategoriesRepository();
    final mealLogs = InMemoryMealLogRepository(
      mealCategoriesRepository: categories,
      clock: () => _now,
    );
    final dates = await _pumpDiary(
      tester,
      categories: categories,
      mealLogs: mealLogs,
    );
    final yesterday = DateTime(2026, 9, 11);
    dates.select(yesterday);
    await tester.pumpAndSettle();

    await _openQuickAdd(tester);
    await tester.enterText(
      find.byKey(const ValueKey('quick-add-calories')),
      '250',
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('meal-log-footer-primary')));
    await tester.pumpAndSettle();

    expect(dates.selectedDate, yesterday);
    expect(find.byKey(const ValueKey('meal-diary-empty-day-note')),
        findsOneWidget);
    expect(
      await mealLogs.listByLocalDate(
        MealLogLocalDate(year: 2026, month: 9, day: 11),
      ),
      isEmpty,
    );
    expect(
      await mealLogs.listByLocalDate(
        MealLogLocalDate(year: 2026, month: 9, day: 12),
      ),
      hasLength(1),
    );
  });

  testWidgets('pending save uses governed loading and blocks draft edits',
      (tester) async {
    final categories = InMemoryMealCategoriesRepository();
    final pending = _PendingMealLogRepository();
    await _pumpDiary(
      tester,
      categories: categories,
      mealLogs: pending,
    );

    await _openQuickAdd(tester);
    await tester.enterText(
      find.byKey(const ValueKey('quick-add-calories')),
      '500',
    );
    await tester.pumpAndSettle();

    final logButton = find.byKey(const ValueKey('meal-log-footer-primary'));
    await tester.tap(logButton);
    await tester.pump();

    expect(tester.widget<TioButton>(logButton).loading, isTrue);
    expect(
      tester
          .widget<TioInput>(
            find.byKey(const ValueKey('quick-add-calories')),
          )
          .enabled,
      isFalse,
    );

    final input = pending.inputs.single;
    pending.complete(_entryFor(input));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('quick-add-editor')), findsNothing);
  });
}

Future<MealDiaryDateController> _pumpDiary(
  WidgetTester tester, {
  required MealCategoriesRepository categories,
  required MealLogRepository mealLogs,
}) async {
  final dates = MealDiaryDateController(clock: () => _now);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        mealDiaryDateControllerProvider.overrideWith((ref) => dates),
        mealDiaryMealLogRepositoryProvider.overrideWithValue(mealLogs),
      ],
      child: MaterialApp(
        builder: (context, child) => TioTheme(
          config: const TioThemeConfig(mode: TioThemeMode.light),
          child: child ?? const SizedBox.shrink(),
        ),
        home: Scaffold(
          body: MealDiaryPage(
            quickAddClock: () => _now,
            mealCategoriesRepository: categories,
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return dates;
}

Future<void> _openQuickAdd(WidgetTester tester) async {
  await tester.tap(find.byKey(const ValueKey('meal-diary-add-food-action')));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const ValueKey('add-food-quick-add')));
  await tester.pumpAndSettle();
}

final class _PendingMealLogRepository implements MealLogRepository {
  final _pending = Completer<MealLogEntry>();
  final inputs = <ManualMealLogCreate>[];

  void complete(MealLogEntry entry) => _pending.complete(entry);

  @override
  Future<MealLogEntry> createManual(ManualMealLogCreate input) {
    inputs.add(input);
    return _pending.future;
  }

  @override
  Future<List<MealLogEntry>> listByLocalDate(MealLogLocalDate localDate) async =>
      const [];

  @override
  Future<MealLogEntry?> readById(String id) async => null;
}

MealLogEntry _entryFor(ManualMealLogCreate input) {
  final timestamp = DateTime.utc(2026, 9, 12, 5);
  return MealLogEntry.manual(
    id: 'pending-entry',
    userId: 'user-1',
    mealCategoryId: input.mealCategoryId,
    mealName: input.mealName,
    note: input.note,
    consumedAt: input.consumedAt,
    consumedLocalDate: input.consumedLocalDate,
    consumedTimezoneId: input.consumedTimezoneId,
    consumedUtcOffsetMinutes: input.consumedUtcOffsetMinutes,
    captureSource: input.captureSource,
    manualNutritionSnapshot: input.manualNutritionSnapshot,
    createdAt: timestamp,
    updatedAt: timestamp,
  );
}
