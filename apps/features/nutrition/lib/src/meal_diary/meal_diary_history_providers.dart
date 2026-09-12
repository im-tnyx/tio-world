import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tio_shared/shared.dart';

import '../domain/models/meal_categories_config.dart';
import '../domain/repositories/meal_categories_repository.dart';
import '../domain/repositories/meal_log_repository.dart';

/// App-composition seam for the canonical MealLog repository consumed by the
/// Meal Diary.
///
/// The feature package deliberately has no opinion about Supabase versus a
/// local/test adapter. Production overrides this with the app-owned canonical
/// repository. A null default keeps isolated feature/widget harnesses honest:
/// they show no fabricated persisted history unless a repository is supplied.
final mealDiaryMealLogRepositoryProvider = Provider<MealLogRepository?>(
  (ref) => null,
);

/// Stable request identity for one selected Diary day.
///
/// Repository identity is part of equality so an auth/composition change gets
/// a fresh read even if the selected date did not move. Date equality is the
/// durable [MealLogLocalDate] identity, not a device-timezone conversion.
@immutable
final class MealDiaryHistoryRequest {
  const MealDiaryHistoryRequest({
    required this.mealLogRepository,
    required this.mealCategoriesRepository,
    required this.localDate,
  });

  factory MealDiaryHistoryRequest.forSelectedDate({
    required MealLogRepository mealLogRepository,
    required MealCategoriesRepository mealCategoriesRepository,
    required DateTime selectedDate,
  }) {
    return MealDiaryHistoryRequest(
      mealLogRepository: mealLogRepository,
      mealCategoriesRepository: mealCategoriesRepository,
      localDate: MealLogLocalDate(
        year: selectedDate.year,
        month: selectedDate.month,
        day: selectedDate.day,
      ),
    );
  }

  final MealLogRepository mealLogRepository;
  final MealCategoriesRepository mealCategoriesRepository;
  final MealLogLocalDate localDate;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MealDiaryHistoryRequest &&
          identical(other.mealLogRepository, mealLogRepository) &&
          identical(other.mealCategoriesRepository, mealCategoriesRepository) &&
          other.localDate == localDate;

  @override
  int get hashCode => Object.hash(
        identityHashCode(mealLogRepository),
        identityHashCode(mealCategoriesRepository),
        localDate,
      );
}

/// One compact, presentation-safe actual MealLog event.
@immutable
final class MealDiaryEntryReadModel {
  const MealDiaryEntryReadModel({
    required this.id,
    required this.displayTitle,
    required this.captureSource,
    required this.consumedAt,
    required this.loggedLocalDateTime,
    required this.caloriesKcal,
    required this.proteinGrams,
    required this.note,
  });

  final String id;

  /// The persisted meal name when present.
  ///
  /// `Quick Add` is the only V1 fallback and is source-aware: an unnamed log
  /// from another capture source stays unnamed rather than being mislabeled as
  /// Quick Add. This string is presentation only; it never writes mealName.
  final String? displayTitle;
  final MealLogCaptureSource? captureSource;

  /// Canonical instant used for ordering.
  final DateTime consumedAt;

  /// Reconstructed historical wall-clock value when an exact stored UTC
  /// offset is available. This deliberately does not call `toLocal()`, because
  /// today's device timezone must not rewrite how an old meal time is shown.
  ///
  /// A timezone id without an offset is not guessed here. Resolving IANA zone
  /// history needs a dedicated timezone resolver; until one is supplied, the
  /// visible time is omitted rather than silently using the current device
  /// zone.
  final DateTime? loggedLocalDateTime;

  final num? caloriesKcal;
  final num? proteinGrams;
  final String? note;
}

/// One Meal Category section for the selected day.
@immutable
final class MealDiarySectionReadModel {
  const MealDiarySectionReadModel({
    required this.categoryId,
    required this.categoryDisplayName,
    required this.entries,
    required this.latestConsumedAt,
    required this.caloriesKcal,
    required this.proteinGrams,
  });

  final String categoryId;
  final String categoryDisplayName;
  final List<MealDiaryEntryReadModel> entries;
  final DateTime latestConsumedAt;

  /// Null means the section total is unknown because at least one entry does
  /// not contain that nutrient. A partial sum would look authoritative while
  /// silently omitting data, so this is all-known-or-unknown.
  final num? caloriesKcal;
  final num? proteinGrams;
}

/// Complete immutable read model for one selected Diary local date.
@immutable
final class MealDiaryHistoryReadModel {
  const MealDiaryHistoryReadModel({
    required this.localDate,
    required this.sections,
  });

  final MealLogLocalDate localDate;
  final List<MealDiarySectionReadModel> sections;

  bool get isEmpty => sections.isEmpty;
}

/// Selected-date read owner.
///
/// A provider family is intentional here: changing the selected date changes
/// the provider key. Riverpod stops the old request from publishing into the
/// newly watched date, so a slow historical read cannot overwrite a newer
/// selection. The repositories remain the only persistence owners.
final mealDiaryHistoryProvider = FutureProvider.autoDispose
    .family<MealDiaryHistoryReadModel, MealDiaryHistoryRequest>(
  (ref, request) async {
    final categoriesRepository = request.mealCategoriesRepository;
    if (categoriesRepository is MealCategoriesChangeSource) {
      final subscription = categoriesRepository.changes.listen((_) {
        // The repository emits only after a confirmed local write. Rebuild the
        // same selected-day read model so current retained display names are
        // visible even though the Diary itself may have stayed mounted behind
        // Settings while the change was made.
        ref.invalidateSelf();
      });
      ref.onDispose(() {
        subscription.cancel();
      });
    }

    final results = await Future.wait<Object>([
      request.mealLogRepository.listByLocalDate(request.localDate),
      categoriesRepository.read(),
    ]);

    final entries = results[0] as List<MealLogEntry>;
    final categories = results[1] as MealCategoriesConfig;

    return _buildReadModel(
      localDate: request.localDate,
      entries: entries,
      categories: categories,
    );
  },
);

MealDiaryHistoryReadModel _buildReadModel({
  required MealLogLocalDate localDate,
  required List<MealLogEntry> entries,
  required MealCategoriesConfig categories,
}) {
  if (entries.isEmpty) {
    return MealDiaryHistoryReadModel(
      localDate: localDate,
      sections: const [],
    );
  }

  final grouped = <String, List<MealLogEntry>>{};
  for (final entry in entries) {
    if (entry.consumedLocalDate != localDate) {
      throw StateError(
        'MealLogRepository returned ${entry.id} outside requested local date '
        '$localDate.',
      );
    }
    grouped.putIfAbsent(entry.mealCategoryId, () => []).add(entry);
  }

  final sections = <MealDiarySectionReadModel>[];
  for (final group in grouped.entries) {
    final category = categories.findById(group.key);
    if (category == null) {
      throw StateError(
        'MealLogEntry category ${group.key} is not resolvable for history.',
      );
    }

    // Repository order is already newest `consumedAt` first with a stable id
    // tie-break. Grouping preserves that order; this defensive sort keeps the
    // read model correct for fake/test adapters as well.
    final ordered = [...group.value]
      ..sort((a, b) {
        final byTime = b.consumedAt.compareTo(a.consumedAt);
        return byTime != 0 ? byTime : a.id.compareTo(b.id);
      });

    final entryModels = List<MealDiaryEntryReadModel>.unmodifiable(
      ordered.map(_entryReadModel),
    );

    sections.add(
      MealDiarySectionReadModel(
        categoryId: category.id,
        categoryDisplayName: category.displayName,
        entries: entryModels,
        latestConsumedAt: ordered.first.consumedAt,
        caloriesKcal: _allKnownTotal(ordered, NutrientId.energy),
        proteinGrams: _allKnownTotal(ordered, NutrientId.protein),
      ),
    );
  }

  sections.sort((a, b) {
    final byLatest = b.latestConsumedAt.compareTo(a.latestConsumedAt);
    return byLatest != 0 ? byLatest : a.categoryId.compareTo(b.categoryId);
  });

  return MealDiaryHistoryReadModel(
    localDate: localDate,
    sections: List<MealDiarySectionReadModel>.unmodifiable(sections),
  );
}

MealDiaryEntryReadModel _entryReadModel(MealLogEntry entry) {
  final snapshot = entry.manualNutritionSnapshot;
  final offsetMinutes = entry.consumedUtcOffsetMinutes;
  final loggedLocalDateTime = offsetMinutes == null
      ? null
      : entry.consumedAt
          .toUtc()
          .add(Duration(minutes: offsetMinutes));

  return MealDiaryEntryReadModel(
    id: entry.id,
    displayTitle: entry.mealName ??
        (entry.captureSource == MealLogCaptureSource.quickAdd
            ? 'Quick Add'
            : null),
    captureSource: entry.captureSource,
    consumedAt: entry.consumedAt,
    loggedLocalDateTime: loggedLocalDateTime,
    caloriesKcal: snapshot?.amountFor(NutrientId.energy),
    proteinGrams: snapshot?.amountFor(NutrientId.protein),
    note: entry.note,
  );
}

num? _allKnownTotal(List<MealLogEntry> entries, NutrientId nutrient) {
  num total = 0;
  for (final entry in entries) {
    final amount = entry.manualNutritionSnapshot?.amountFor(nutrient);
    if (amount == null) return null;
    total += amount;
  }
  return total;
}
