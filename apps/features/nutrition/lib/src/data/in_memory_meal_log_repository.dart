import 'package:tio_shared/shared.dart';

import '../domain/repositories/meal_log_repository.dart';

/// Deterministic non-durable MealLog owner for tests and local composition.
///
/// Production history must use the Supabase adapter. This repository exists so
/// non-Supabase harnesses remain constructible without pretending the data is
/// durable or synced.
final class InMemoryMealLogRepository implements MealLogRepository {
  InMemoryMealLogRepository({
    DateTime Function()? clock,
    String userId = 'in_memory_meal_log_user',
  })  : _clock = clock ?? DateTime.now,
        _userId = _requireNonBlank(userId, 'userId');

  final DateTime Function() _clock;
  final String _userId;
  final Map<String, MealLogEntry> _entries = {};
  var _nextId = 1;

  @override
  Future<MealLogEntry> createManual(ManualMealLogCreate input) async {
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
    return entry;
  }

  @override
  Future<MealLogEntry?> readById(String id) async {
    _requireNonBlank(id, 'id');
    return _entries[id];
  }

  static String _requireNonBlank(String value, String name) {
    if (value.trim().isEmpty) {
      throw ArgumentError.value(value, name, 'must not be blank');
    }
    return value;
  }
}
