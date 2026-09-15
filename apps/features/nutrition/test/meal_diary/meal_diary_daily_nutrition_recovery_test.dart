import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tio_core/core.dart';
import 'package:tio_feature_nutrition/nutrition.dart';
import 'package:tio_shared/shared.dart';

final _now = DateTime(2026, 9, 13, 12);

void main() {
  testWidgets('range-only error exposes retry and recovers calendar summaries',
      (tester) async {
    final categories = InMemoryMealCategoriesRepository();
    final delegate = InMemoryMealLogRepository(
      mealCategoriesRepository: categories,
      clock: () => _now,
    );
    final mealLogs = _RangeFailingMealLogRepository(delegate);
    final targets = InMemoryNutritionTargetsRepository();
    await targets.upsert(const NutritionTargetsData(caloriesKcal: 2000));
    final dates = MealDiaryDateController(clock: () => _now);

    await _pumpDiary(
      tester,
      dates: dates,
      categories: categories,
      mealLogs: mealLogs,
      targets: targets,
    );

    expect(
      find.byKey(const ValueKey('meal-diary-daily-nutrition-error')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('meal-diary-daily-nutrition-retry')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('meal-diary-daily-nutrition-summary')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('meal-diary-summary-calendar-overlap')),
      findsNothing,
    );

    mealLogs.failRangeReads = false;
    await tester.tap(
      find.byKey(const ValueKey('meal-diary-daily-nutrition-retry')),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('meal-diary-daily-nutrition-error')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('meal-diary-daily-nutrition-summary')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('meal-diary-summary-calendar-overlap')),
      findsOneWidget,
    );

    final calendar = tester.widget<TioDateCalendar>(find.byType(TioDateCalendar));
    final decoration = calendar.decorationBuilder!(DateTime(2026, 9, 13));
    expect(decoration, isNotNull);
    expect(decoration!.progress, 0);
  });

  testWidgets(
      'previous-value range error clears stale calendar decorations until retry',
      (tester) async {
    final categories = InMemoryMealCategoriesRepository();
    final delegate = InMemoryMealLogRepository(
      mealCategoriesRepository: categories,
      clock: () => _now,
    );
    final mealLogs = _RangeFailingMealLogRepository(delegate)
      ..failRangeReads = false;
    final targets = InMemoryNutritionTargetsRepository();
    await targets.upsert(const NutritionTargetsData(caloriesKcal: 2000));
    final dates = MealDiaryDateController(clock: () => _now);

    await _pumpDiary(
      tester,
      dates: dates,
      categories: categories,
      mealLogs: mealLogs,
      targets: targets,
    );

    var calendar = tester.widget<TioDateCalendar>(find.byType(TioDateCalendar));
    expect(calendar.decorationBuilder, isNotNull);
    expect(
      calendar.decorationBuilder!(DateTime(2026, 9, 13))?.progress,
      0,
    );

    mealLogs.failRangeReads = true;
    final container = ProviderScope.containerOf(
      tester.element(find.byType(MealDiaryPage)),
    );
    container.invalidate(mealDiaryNutritionSummaryRangeProvider);
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('meal-diary-daily-nutrition-error')),
      findsOneWidget,
    );
    calendar = tester.widget<TioDateCalendar>(find.byType(TioDateCalendar));
    expect(
      calendar.decorationBuilder,
      isNull,
      reason: 'stale previous-value range truth must not remain visible on error',
    );

    mealLogs.failRangeReads = false;
    await tester.tap(
      find.byKey(const ValueKey('meal-diary-daily-nutrition-retry')),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('meal-diary-daily-nutrition-error')),
      findsNothing,
    );
    calendar = tester.widget<TioDateCalendar>(find.byType(TioDateCalendar));
    expect(calendar.decorationBuilder, isNotNull);
    expect(
      calendar.decorationBuilder!(DateTime(2026, 9, 13))?.progress,
      0,
    );
  });

  testWidgets('previous-value summary error keeps calendar handle unobstructed',
      (tester) async {
    final categories = InMemoryMealCategoriesRepository();
    final mealLogs = InMemoryMealLogRepository(
      mealCategoriesRepository: categories,
      clock: () => _now,
    );
    final targets = _ToggleFailingTargetsRepository();
    final dates = MealDiaryDateController(clock: () => _now);

    await _pumpDiary(
      tester,
      dates: dates,
      categories: categories,
      mealLogs: mealLogs,
      targets: targets,
    );

    expect(
      find.byKey(const ValueKey('meal-diary-daily-nutrition-summary')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('meal-diary-summary-calendar-overlap')),
      findsOneWidget,
    );

    targets.failReads = true;
    final container = ProviderScope.containerOf(
      tester.element(find.byType(MealDiaryPage)),
    );
    container.invalidate(mealDiaryDailyNutritionSummaryProvider);
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('meal-diary-daily-nutrition-error')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('meal-diary-summary-calendar-overlap')),
      findsNothing,
    );

    await tester.tap(find.byKey(const ValueKey('tio-date-calendar-handle')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('tio-date-calendar-month-pager')),
      findsOneWidget,
    );
  });

  testWidgets('retained summary keeps compact geometry while refresh is loading',
      (tester) async {
    final categories = InMemoryMealCategoriesRepository();
    final mealLogs = InMemoryMealLogRepository(
      mealCategoriesRepository: categories,
      clock: () => _now,
    );
    final targets = _BlockingTargetsRepository();
    final dates = MealDiaryDateController(clock: () => _now);

    await _pumpDiary(
      tester,
      dates: dates,
      categories: categories,
      mealLogs: mealLogs,
      targets: targets,
    );

    final summary =
        find.byKey(const ValueKey('meal-diary-daily-nutrition-summary'));
    expect(summary, findsOneWidget);
    expect(
      find.byKey(const ValueKey('meal-diary-summary-calendar-overlap')),
      findsOneWidget,
    );
    final initialTop = tester.getTopLeft(summary).dy;

    targets.blockNextRead();
    final container = ProviderScope.containerOf(
      tester.element(find.byType(MealDiaryPage)),
    );
    container.invalidate(mealDiaryDailyNutritionSummaryProvider);
    await tester.pump();
    await tester.pump();

    expect(summary, findsOneWidget);
    expect(
      find.byKey(const ValueKey('meal-diary-summary-calendar-overlap')),
      findsOneWidget,
    );
    expect(tester.getTopLeft(summary).dy, closeTo(initialTop, 0.01));

    targets.releaseBlockedRead();
    await tester.pumpAndSettle();

    expect(summary, findsOneWidget);
    expect(
      find.byKey(const ValueKey('meal-diary-summary-calendar-overlap')),
      findsOneWidget,
    );
    expect(tester.getTopLeft(summary).dy, closeTo(initialTop, 0.01));
  });

  testWidgets(
      'target change keeps retained summary geometry while refreshed truth loads',
      (tester) async {
    final categories = InMemoryMealCategoriesRepository();
    final mealLogs = InMemoryMealLogRepository(
      mealCategoriesRepository: categories,
      clock: () => _now,
    );
    final targets = _BlockingTargetsRepository();
    final dates = MealDiaryDateController(clock: () => _now);

    await _pumpDiary(
      tester,
      dates: dates,
      categories: categories,
      mealLogs: mealLogs,
      targets: targets,
    );

    final summary =
        find.byKey(const ValueKey('meal-diary-daily-nutrition-summary'));
    final targetValue =
        find.byKey(const ValueKey('daily-nutrition-target-calories'));
    expect(summary, findsOneWidget);
    expect(tester.widget<Text>(targetValue).data, '2000');
    expect(
      find.byKey(const ValueKey('meal-diary-summary-calendar-overlap')),
      findsOneWidget,
    );
    final initialTop = tester.getTopLeft(summary).dy;

    targets.blockNextRead();
    await targets.upsert(const NutritionTargetsData(caloriesKcal: 2200));
    await tester.pump();
    await tester.pump();

    expect(summary, findsOneWidget);
    expect(
      find.byKey(const ValueKey('meal-diary-daily-nutrition-loading')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('meal-diary-summary-calendar-overlap')),
      findsOneWidget,
    );
    expect(tester.widget<Text>(targetValue).data, '2000');
    expect(tester.getTopLeft(summary).dy, closeTo(initialTop, 0.01));

    targets.releaseBlockedRead();
    await tester.pumpAndSettle();

    expect(summary, findsOneWidget);
    expect(tester.widget<Text>(targetValue).data, '2200');
    expect(
      find.byKey(const ValueKey('meal-diary-summary-calendar-overlap')),
      findsOneWidget,
    );
    expect(tester.getTopLeft(summary).dy, closeTo(initialTop, 0.01));
  });
}

Future<void> _pumpDiary(
  WidgetTester tester, {
  required MealDiaryDateController dates,
  required MealCategoriesRepository categories,
  required MealLogRepository mealLogs,
  required NutritionTargetsRepository targets,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        mealDiaryDateControllerProvider.overrideWith((ref) => dates),
        mealDiaryMealLogRepositoryProvider.overrideWithValue(mealLogs),
        mealDiaryNutritionTargetsRepositoryProvider.overrideWithValue(targets),
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
  await tester.pumpAndSettle();
}

final class _RangeFailingMealLogRepository
    implements MealLogRepository, MealLogRangeReadRepository {
  _RangeFailingMealLogRepository(this.delegate);

  final InMemoryMealLogRepository delegate;
  bool failRangeReads = true;

  @override
  Future<MealLogEntry> createManual(ManualMealLogCreate input) =>
      delegate.createManual(input);

  @override
  Future<MealLogEntry?> readById(String id) => delegate.readById(id);

  @override
  Future<List<MealLogEntry>> listByLocalDate(MealLogLocalDate localDate) =>
      delegate.listByLocalDate(localDate);

  @override
  Future<List<MealLogEntry>> listByLocalDateRange({
    required MealLogLocalDate startDate,
    required MealLogLocalDate endDate,
  }) {
    if (failRangeReads) {
      throw StateError('temporary range read failure');
    }
    return delegate.listByLocalDateRange(
      startDate: startDate,
      endDate: endDate,
    );
  }
}

final class _ToggleFailingTargetsRepository
    implements NutritionTargetsRepository {
  bool failReads = false;
  NutritionTargetsData data = const NutritionTargetsData(caloriesKcal: 2000);

  @override
  Future<NutritionTargetsData?> read() async {
    if (failReads) throw StateError('temporary target read failure');
    return data;
  }

  @override
  Future<void> upsert(NutritionTargetsData targets) async {
    targets.validate();
    data = targets;
  }
}

final class _BlockingTargetsRepository
    implements NutritionTargetsRepository, NutritionTargetsChangeSource {
  NutritionTargetsData data = const NutritionTargetsData(caloriesKcal: 2000);
  final StreamController<int> _changes = StreamController<int>.broadcast();
  Completer<void>? _gate;
  var _revision = 0;

  @override
  Stream<int> get changes => _changes.stream;

  void blockNextRead() {
    _gate = Completer<void>();
  }

  void releaseBlockedRead() {
    final gate = _gate;
    _gate = null;
    if (gate != null && !gate.isCompleted) gate.complete();
  }

  @override
  Future<NutritionTargetsData?> read() async {
    final gate = _gate;
    if (gate != null) await gate.future;
    return data;
  }

  @override
  Future<void> upsert(NutritionTargetsData targets) async {
    targets.validate();
    data = targets;
    _changes.add(++_revision);
  }
}
