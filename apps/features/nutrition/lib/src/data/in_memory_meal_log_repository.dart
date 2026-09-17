import 'package:tio_shared/shared.dart';

import '../domain/repositories/detailed_meal_log_create_repository.dart';
import '../domain/repositories/manual_meal_log_update_repository.dart';
import '../domain/repositories/meal_categories_repository.dart';
import '../domain/repositories/meal_log_range_read_repository.dart';
import '../domain/repositories/meal_log_repository.dart';

/// Deterministic non-durable MealLog owner for tests and local composition.
///
/// Production history must use the Supabase adapter. This repository exists so
/// non-Supabase harnesses remain constructible without pretending the data is
/// durable or synced. It mirrors manual/detailed create idempotency, optimistic
/// manual updates, selected-day history ordering, and bounded local-date range
/// reads deterministically so local/test behavior does not hide persistence-
/// contract bugs.
final class InMemoryMealLogRepository implements
    MealLogRepository,
    DetailedMealLogCreateRepository,
    ManualMealLogUpdateRepository,
    MealLogRangeReadRepository {
  InMemoryMealLogRepository({
    required MealCategoriesRepository mealCategoriesRepository,
    DateTime Function()? clock,
    String userId = 'in_memory_meal_log_user',
  })  : _mealCategoriesRepository = mealCategoriesRepository,
        _clock = clock ?? DateTime.now,
        _userId = _requireNonBlank(userId, 'userId');

  final MealCategoriesRepository _mealCategoriesRepository;
  final DateTime Function() _clock;
  final String _userId;
  final Map<String, MealLogEntry> _entries = {};
  final Map<String, _ManualCreateRecord> _manualCreatesByMutationId = {};
  final Map<String, _DetailedCreateRecord> _detailedCreatesByMutationId = {};
  var _nextId = 1;
  var _nextItemId = 1;

  @override
  Future<MealLogEntry> createManual(ManualMealLogCreate input) async {
    final existing = _manualCreatesByMutationId[input.clientMutationId];
    if (existing != null) {
      if (!_sameCreate(existing.input, input)) {
        throw MealLogCreateMutationConflict(
          clientMutationId: input.clientMutationId,
        );
      }
      final current = _entries[existing.entry.id] ?? existing.entry;
      // Mirror production's fail-closed rule. Once the row is edited, the
      // create operation can no longer be safely reconciled from current row
      // facts alone without a durable immutable create fingerprint.
      if (current.revision != 1 || !_matchesCreateInput(current, input)) {
        throw MealLogCreateMutationConflict(
          clientMutationId: input.clientMutationId,
        );
      }
      return current;
    }

    await _requireActiveMealCategory(input.mealCategoryId);
    final now = _clock().toUtc();
    final id = 'in_memory_meal_log_${_nextId++}';
    final entry = MealLogEntry.manual(
      id: id,
      userId: _userId,
      mealCategoryId: input.mealCategoryId,
      mealName: input.mealName,
      note: input.note,
      consumedAt: input.consumedAt.toUtc(),
      consumedLocalDate: input.consumedLocalDate,
      consumedTimezoneId: input.consumedTimezoneId,
      consumedUtcOffsetMinutes: input.consumedUtcOffsetMinutes,
      captureSource: input.captureSource,
      manualNutritionSnapshot: input.manualNutritionSnapshot,
      createdAt: now,
      updatedAt: now,
    );
    _entries[id] = entry;
    _manualCreatesByMutationId[input.clientMutationId] = _ManualCreateRecord(
      input: input,
      entry: entry,
    );
    return entry;
  }

  @override
  Future<MealLogEntry> createDetailed(DetailedMealLogCreate input) async {
    final existing = _detailedCreatesByMutationId[input.clientMutationId];
    if (existing != null) {
      if (!_sameDetailedCreate(existing.input, input)) {
        throw MealLogCreateMutationConflict(
          clientMutationId: input.clientMutationId,
        );
      }
      final current = _entries[existing.entry.id] ?? existing.entry;
      if (current.revision != 1 ||
          !_matchesDetailedCreateInput(current, input)) {
        throw MealLogCreateMutationConflict(
          clientMutationId: input.clientMutationId,
        );
      }
      return current;
    }

    await _requireActiveMealCategory(input.mealCategoryId);
    final now = _clock().toUtc();
    final id = 'in_memory_meal_log_${_nextId++}';
    final items = [
      for (final item in input.items)
        MealLogItemSnapshot(
          id: 'in_memory_meal_log_item_${_nextItemId++}',
          mealLogEntryId: id,
          displayName: item.displayName,
          brandName: item.brandName,
          quantity: item.quantity,
          servingUnit: item.servingUnit,
          nutritionSnapshot: item.nutritionSnapshot,
        ),
    ];
    final entry = MealLogEntry.detailed(
      id: id,
      userId: _userId,
      mealCategoryId: input.mealCategoryId,
      mealName: input.mealName,
      note: input.note,
      consumedAt: input.consumedAt.toUtc(),
      consumedLocalDate: input.consumedLocalDate,
      consumedTimezoneId: input.consumedTimezoneId,
      consumedUtcOffsetMinutes: input.consumedUtcOffsetMinutes,
      captureSource: input.captureSource,
      detailedItems: items,
      createdAt: now,
      updatedAt: now,
    );
    _entries[id] = entry;
    _detailedCreatesByMutationId[input.clientMutationId] = _DetailedCreateRecord(
      input: input,
      entry: entry,
    );
    return entry;
  }

  @override
  Future<MealLogEntry> updateManual(ManualMealLogUpdate input) async {
    final existing = _entries[input.id];
    if (existing == null) {
      throw MealLogUpdateNotFound(id: input.id);
    }
    if (existing.revision != input.expectedRevision) {
      throw MealLogUpdateConflict(
        id: input.id,
        expectedRevision: input.expectedRevision,
        actualRevision: existing.revision,
      );
    }
    if (existing.mode != MealLogMode.manual) {
      throw StateError('Detailed MealLog updates are not supported in this slice.');
    }

    if (input.mealCategoryId != existing.mealCategoryId) {
      await _requireActiveMealCategory(input.mealCategoryId);
    }

    final updated = MealLogEntry.manual(
      id: existing.id,
      userId: existing.userId,
      mealCategoryId: input.mealCategoryId,
      mealName: input.mealName,
      note: input.note,
      consumedAt: input.consumedAt.toUtc(),
      consumedLocalDate: input.consumedLocalDate,
      consumedTimezoneId: input.consumedTimezoneId,
      consumedUtcOffsetMinutes: input.consumedUtcOffsetMinutes,
      captureSource: existing.captureSource,
      manualNutritionSnapshot: input.manualNutritionSnapshot,
      revision: existing.revision + 1,
      createdAt: existing.createdAt,
      updatedAt: _clock().toUtc(),
    );
    _entries[input.id] = updated;
    return updated;
  }

  @override
  Future<MealLogEntry?> readById(String id) async {
    _requireNonBlank(id, 'id');
    return _entries[id];
  }

  @override
  Future<List<MealLogEntry>> listByLocalDate(
    MealLogLocalDate localDate,
  ) async {
    final entries = _entries.values
        .where((entry) => entry.consumedLocalDate == localDate)
        .toList()
      ..sort(_compareDiaryOrder);
    return List<MealLogEntry>.unmodifiable(entries);
  }

  @override
  Future<List<MealLogEntry>> listByLocalDateRange({
    required MealLogLocalDate startDate,
    required MealLogLocalDate endDate,
  }) async {
    final start = startDate.toIso8601String();
    final end = endDate.toIso8601String();
    if (start.compareTo(end) > 0) {
      throw ArgumentError.value(
        '$start..$end',
        'localDateRange',
        'startDate must not be after endDate',
      );
    }

    final entries = _entries.values.where((entry) {
      final date = entry.consumedLocalDate.toIso8601String();
      return date.compareTo(start) >= 0 && date.compareTo(end) <= 0;
    }).toList()
      ..sort(_compareDiaryRangeOrder);
    return List<MealLogEntry>.unmodifiable(entries);
  }

  Future<void> _requireActiveMealCategory(String id) async {
    if (id.isEmpty || id.trim() != id) {
      throw ArgumentError.value(
        id,
        'mealCategoryId',
        'must be a canonical Meal Category identity',
      );
    }
    final config = await _mealCategoriesRepository.read();
    final category = config.findById(id);
    if (category == null || !category.active) {
      throw ArgumentError.value(
        id,
        'mealCategoryId',
        'must reference an active Meal Category',
      );
    }
  }

  static int _compareDiaryOrder(MealLogEntry left, MealLogEntry right) {
    final byConsumedAt = right.consumedAt.compareTo(left.consumedAt);
    if (byConsumedAt != 0) return byConsumedAt;
    return left.id.compareTo(right.id);
  }

  static int _compareDiaryRangeOrder(MealLogEntry left, MealLogEntry right) {
    final byDate = left.consumedLocalDate
        .toIso8601String()
        .compareTo(right.consumedLocalDate.toIso8601String());
    if (byDate != 0) return byDate;
    return _compareDiaryOrder(left, right);
  }

  static bool _sameCreate(
    ManualMealLogCreate left,
    ManualMealLogCreate right,
  ) {
    return left.clientMutationId == right.clientMutationId &&
        left.mealCategoryId == right.mealCategoryId &&
        left.mealName == right.mealName &&
        left.note == right.note &&
        left.consumedAt.toUtc() == right.consumedAt.toUtc() &&
        left.consumedLocalDate == right.consumedLocalDate &&
        left.consumedTimezoneId == right.consumedTimezoneId &&
        left.consumedUtcOffsetMinutes == right.consumedUtcOffsetMinutes &&
        left.captureSource == right.captureSource &&
        left.manualNutritionSnapshot == right.manualNutritionSnapshot;
  }

  static bool _sameDetailedCreate(
    DetailedMealLogCreate left,
    DetailedMealLogCreate right,
  ) {
    if (left.clientMutationId != right.clientMutationId ||
        left.mealCategoryId != right.mealCategoryId ||
        left.mealName != right.mealName ||
        left.note != right.note ||
        left.consumedAt.toUtc() != right.consumedAt.toUtc() ||
        left.consumedLocalDate != right.consumedLocalDate ||
        left.consumedTimezoneId != right.consumedTimezoneId ||
        left.consumedUtcOffsetMinutes != right.consumedUtcOffsetMinutes ||
        left.captureSource != right.captureSource ||
        left.items.length != right.items.length) {
      return false;
    }
    for (var index = 0; index < left.items.length; index++) {
      final leftItem = left.items[index];
      final rightItem = right.items[index];
      if (leftItem.displayName != rightItem.displayName ||
          leftItem.brandName != rightItem.brandName ||
          leftItem.quantity != rightItem.quantity ||
          leftItem.servingUnit != rightItem.servingUnit ||
          leftItem.nutritionSnapshot != rightItem.nutritionSnapshot) {
        return false;
      }
    }
    return true;
  }

  static bool _matchesCreateInput(
    MealLogEntry entry,
    ManualMealLogCreate input,
  ) {
    return entry.mode == MealLogMode.manual &&
        entry.mealCategoryId == input.mealCategoryId &&
        entry.mealName == input.mealName &&
        entry.note == input.note &&
        entry.consumedAt == input.consumedAt.toUtc() &&
        entry.consumedLocalDate == input.consumedLocalDate &&
        entry.consumedTimezoneId == input.consumedTimezoneId &&
        entry.consumedUtcOffsetMinutes == input.consumedUtcOffsetMinutes &&
        entry.captureSource == input.captureSource &&
        entry.manualNutritionSnapshot == input.manualNutritionSnapshot;
  }

  static bool _matchesDetailedCreateInput(
    MealLogEntry entry,
    DetailedMealLogCreate input,
  ) {
    if (entry.mode != MealLogMode.detailed ||
        entry.mealCategoryId != input.mealCategoryId ||
        entry.mealName != input.mealName ||
        entry.note != input.note ||
        entry.consumedAt != input.consumedAt.toUtc() ||
        entry.consumedLocalDate != input.consumedLocalDate ||
        entry.consumedTimezoneId != input.consumedTimezoneId ||
        entry.consumedUtcOffsetMinutes != input.consumedUtcOffsetMinutes ||
        entry.captureSource != input.captureSource ||
        entry.detailedItems.length != input.items.length) {
      return false;
    }
    for (var index = 0; index < input.items.length; index++) {
      final durable = entry.detailedItems[index];
      final requested = input.items[index];
      if (durable.displayName != requested.displayName ||
          durable.brandName != requested.brandName ||
          durable.quantity != requested.quantity ||
          durable.servingUnit != requested.servingUnit ||
          durable.nutritionSnapshot != requested.nutritionSnapshot) {
        return false;
      }
    }
    return true;
  }

  static String _requireNonBlank(String value, String name) {
    if (value.trim().isEmpty) {
      throw ArgumentError.value(value, name, 'must not be blank');
    }
    return value;
  }
}

final class _ManualCreateRecord {
  const _ManualCreateRecord({required this.input, required this.entry});

  final ManualMealLogCreate input;
  final MealLogEntry entry;
}

final class _DetailedCreateRecord {
  const _DetailedCreateRecord({required this.input, required this.entry});

  final DetailedMealLogCreate input;
  final MealLogEntry entry;
}
