import 'package:tio_shared/shared.dart';

import '../models/daily_nutrition_summary.dart';
import '../repositories/meal_log_range_read_repository.dart';
import '../repositories/meal_log_repository.dart';
import 'daily_nutrition_budget_resolver.dart';

/// Combines canonical selected-date budget truth with actual MealLog totals.
///
/// No daily totals are persisted here. A repository failure remains a failure;
/// a successful empty MealLog read is a known zero-consumption day.
final class DailyNutritionSummaryResolver {
  const DailyNutritionSummaryResolver({
    required MealLogRepository mealLogRepository,
    required DailyNutritionBudgetResolver budgetResolver,
  })  : _mealLogRepository = mealLogRepository,
        _budgetResolver = budgetResolver;

  static const coreNutrients = <NutrientId>[
    NutrientId.energy,
    NutrientId.carbohydrate,
    NutrientId.protein,
    NutrientId.fat,
    NutrientId.fiber,
  ];

  final MealLogRepository _mealLogRepository;
  final DailyNutritionBudgetResolver _budgetResolver;

  Future<DailyNutritionSummary> resolve(MealLogLocalDate localDate) async {
    final budget = await _budgetResolver.resolve(localDate);
    final entries = await _mealLogRepository.listByLocalDate(localDate);
    _requireEntriesMatchDate(entries, localDate);

    return DailyNutritionSummary(
      localDate: localDate,
      budget: budget,
      consumedTotals: _aggregate(entries),
    );
  }

  /// Resolves one inclusive visible Diary range with one MealLog range read and
  /// one canonical target read.
  Future<Map<MealLogLocalDate, DailyNutritionSummary>> resolveRange({
    required MealLogLocalDate startDate,
    required MealLogLocalDate endDate,
  }) async {
    _requireOrderedRange(startDate, endDate);
    final mealLogs = _mealLogRepository;
    if (mealLogs is! MealLogRangeReadRepository) {
      throw StateError(
        'MealLog range reads are unavailable for Daily Nutrition calendar progress.',
      );
    }
    final rangeRepository = mealLogs as MealLogRangeReadRepository;

    final dates = _inclusiveDates(startDate, endDate);
    final budgets = await _budgetResolver.resolveMany(dates);
    final entries = await rangeRepository.listByLocalDateRange(
      startDate: startDate,
      endDate: endDate,
    );

    final grouped = <MealLogLocalDate, List<MealLogEntry>>{};
    for (final entry in entries) {
      final date = entry.consumedLocalDate;
      if (!budgets.containsKey(date)) {
        throw StateError(
          'MealLog range read returned an entry outside the requested local-date range.',
        );
      }
      (grouped[date] ??= <MealLogEntry>[]).add(entry);
    }

    return Map<MealLogLocalDate, DailyNutritionSummary>.unmodifiable({
      for (final date in dates)
        date: DailyNutritionSummary(
          localDate: date,
          budget: budgets[date],
          consumedTotals: _aggregate(grouped[date] ?? const <MealLogEntry>[]),
        ),
    });
  }

  static Map<NutrientId, num> _aggregate(List<MealLogEntry> entries) {
    if (entries.isEmpty) {
      return <NutrientId, num>{
        for (final nutrient in coreNutrients) nutrient: 0,
      };
    }

    final totals = <NutrientId, num>{};
    for (final nutrient in coreNutrients) {
      num total = 0;
      var fullyKnown = true;
      for (final entry in entries) {
        final amount = entry.manualNutritionSnapshot?.amountFor(nutrient);
        if (amount == null) {
          fullyKnown = false;
          break;
        }
        total += amount;
      }
      if (fullyKnown) totals[nutrient] = total;
    }
    return totals;
  }

  static void _requireEntriesMatchDate(
    List<MealLogEntry> entries,
    MealLogLocalDate localDate,
  ) {
    for (final entry in entries) {
      if (entry.consumedLocalDate != localDate) {
        throw StateError(
          'MealLog selected-date read returned an entry for another local date.',
        );
      }
    }
  }

  static void _requireOrderedRange(
    MealLogLocalDate startDate,
    MealLogLocalDate endDate,
  ) {
    if (startDate.toIso8601String().compareTo(endDate.toIso8601String()) > 0) {
      throw ArgumentError.value(
        '${startDate.toIso8601String()}..${endDate.toIso8601String()}',
        'localDateRange',
        'startDate must not be after endDate',
      );
    }
  }

  static List<MealLogLocalDate> _inclusiveDates(
    MealLogLocalDate startDate,
    MealLogLocalDate endDate,
  ) {
    final start = DateTime.utc(startDate.year, startDate.month, startDate.day);
    final end = DateTime.utc(endDate.year, endDate.month, endDate.day);
    return <MealLogLocalDate>[
      for (var cursor = start;
          !cursor.isAfter(end);
          cursor = cursor.add(const Duration(days: 1)))
        MealLogLocalDate(
          year: cursor.year,
          month: cursor.month,
          day: cursor.day,
        ),
    ];
  }
}
