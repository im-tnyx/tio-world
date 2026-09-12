import 'package:tio_shared/shared.dart';

import '../domain/repositories/manual_meal_log_update_repository.dart';
import '../domain/repositories/meal_categories_repository.dart';
import '../domain/repositories/meal_log_repository.dart';

/// Deterministic non-durable MealLog owner for tests and local composition.
///
/// Production history must use the Supabase adapter. This repository exists so
/// non-Supabase harnesses remain constructible without pretending the data is
/// durable or synced. It mirrors manual-create idempotency, optimistic manual
/// updates, and selected-day history ordering deterministically so local/test
/// behavior does not hide persistence-contract bugs.
final class InMemoryMealLogRepository
    implements MealLogRepository, ManualMealLogUpdateRepository {
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
  var _nextId = 1;

  @override
  Future<MealLogEntry> createManual(ManualMealLogCreate input) async {
    final existing = _manualCreatesByMutationId[input.clientMutationId];
    if (existing != null) {
      if (!_sameCreate(existing.input, input)) {
        throw MealLogCreateMutationConflict(
          clientMutationId: input.clientMutationId,
        );
      }
      // The create identity remains immutable, but the row may have been edited
      // after creation. Return canonical current state rather than a stale
      // pre-edit response snapshot.
      return _entries[existing.entry.id] ?? existing.entry;
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
