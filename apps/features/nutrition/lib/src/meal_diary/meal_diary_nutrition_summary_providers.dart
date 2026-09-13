import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tio_shared/shared.dart';

import '../domain/domain.dart';

/// App-composition seam for canonical Nutrition Targets used by Meal Diary.
///
/// Production overrides this with the app-owned repository. A null default
/// prevents isolated feature harnesses from inventing target truth.
final mealDiaryNutritionTargetsRepositoryProvider =
    Provider<NutritionTargetsRepository?>((ref) => null);

final _nutritionTargetsChangesProvider = StreamProvider.autoDispose
    .family<int, NutritionTargetsChangeSource>((ref, source) => source.changes);

@immutable
final class MealDiaryDailySummaryRequest {
  const MealDiaryDailySummaryRequest({
    required this.mealLogRepository,
    required this.nutritionTargetsRepository,
    required this.localDate,
  });

  factory MealDiaryDailySummaryRequest.forSelectedDate({
    required MealLogRepository mealLogRepository,
    required NutritionTargetsRepository nutritionTargetsRepository,
    required DateTime selectedDate,
  }) {
    return MealDiaryDailySummaryRequest(
      mealLogRepository: mealLogRepository,
      nutritionTargetsRepository: nutritionTargetsRepository,
      localDate: MealLogLocalDate(
        year: selectedDate.year,
        month: selectedDate.month,
        day: selectedDate.day,
      ),
    );
  }

  final MealLogRepository mealLogRepository;
  final NutritionTargetsRepository nutritionTargetsRepository;
  final MealLogLocalDate localDate;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MealDiaryDailySummaryRequest &&
          identical(other.mealLogRepository, mealLogRepository) &&
          identical(
            other.nutritionTargetsRepository,
            nutritionTargetsRepository,
          ) &&
          other.localDate == localDate;

  @override
  int get hashCode => Object.hash(
        identityHashCode(mealLogRepository),
        identityHashCode(nutritionTargetsRepository),
        localDate,
      );
}

@immutable
final class MealDiarySummaryRangeRequest {
  const MealDiarySummaryRangeRequest({
    required this.mealLogRepository,
    required this.nutritionTargetsRepository,
    required this.startDate,
    required this.endDate,
  });

  factory MealDiarySummaryRangeRequest.fromVisibleDates({
    required MealLogRepository mealLogRepository,
    required NutritionTargetsRepository nutritionTargetsRepository,
    required DateTime firstDate,
    required DateTime lastDate,
  }) {
    return MealDiarySummaryRangeRequest(
      mealLogRepository: mealLogRepository,
      nutritionTargetsRepository: nutritionTargetsRepository,
      startDate: MealLogLocalDate(
        year: firstDate.year,
        month: firstDate.month,
        day: firstDate.day,
      ),
      endDate: MealLogLocalDate(
        year: lastDate.year,
        month: lastDate.month,
        day: lastDate.day,
      ),
    );
  }

  final MealLogRepository mealLogRepository;
  final NutritionTargetsRepository nutritionTargetsRepository;
  final MealLogLocalDate startDate;
  final MealLogLocalDate endDate;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MealDiarySummaryRangeRequest &&
          identical(other.mealLogRepository, mealLogRepository) &&
          identical(
            other.nutritionTargetsRepository,
            nutritionTargetsRepository,
          ) &&
          other.startDate == startDate &&
          other.endDate == endDate;

  @override
  int get hashCode => Object.hash(
        identityHashCode(mealLogRepository),
        identityHashCode(nutritionTargetsRepository),
        startDate,
        endDate,
      );
}

final mealDiaryDailyNutritionSummaryProvider = FutureProvider.autoDispose
    .family<DailyNutritionSummary, MealDiaryDailySummaryRequest>(
  (ref, request) {
    _watchTargetChanges(ref, request.nutritionTargetsRepository);
    return _resolver(request).resolve(request.localDate);
  },
);

final mealDiaryNutritionSummaryRangeProvider = FutureProvider.autoDispose
    .family<
        Map<MealLogLocalDate, DailyNutritionSummary>,
        MealDiarySummaryRangeRequest>(
  (ref, request) {
    _watchTargetChanges(ref, request.nutritionTargetsRepository);
    return _resolver(request).resolveRange(
      startDate: request.startDate,
      endDate: request.endDate,
    );
  },
);

void _watchTargetChanges(
  Ref ref,
  NutritionTargetsRepository repository,
) {
  if (repository is! NutritionTargetsChangeSource) return;
  final source = repository as NutritionTargetsChangeSource;
  ref.watch(_nutritionTargetsChangesProvider(source));
}

DailyNutritionSummaryResolver _resolver(Object request) {
  final MealLogRepository mealLogs;
  final NutritionTargetsRepository targets;
  switch (request) {
    case MealDiaryDailySummaryRequest():
      mealLogs = request.mealLogRepository;
      targets = request.nutritionTargetsRepository;
    case MealDiarySummaryRangeRequest():
      mealLogs = request.mealLogRepository;
      targets = request.nutritionTargetsRepository;
    default:
      throw ArgumentError.value(request, 'request');
  }

  return DailyNutritionSummaryResolver(
    mealLogRepository: mealLogs,
    budgetResolver: DailyNutritionBudgetResolver(
      nutritionTargetsRepository: targets,
    ),
  );
}
