import 'package:tio_shared/shared.dart';

import '../domain/repositories/meal_categories_repository.dart';
import '../domain/repositories/meal_log_repository.dart';

/// Deterministic non-durable MealLog owner for tests and local composition.
///
/// Production history must use the Supabase adapter. This repository exists so
/// non-Supabase harnesses remain constructible without pretending the data is
/// durable or synced.
final class InMemoryMealLogRepository implements MealLogRepository {
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
  var _nextId = 1;

  @override
  Future<MealLogEntry> createManual(ManualMealLogCreate input) async {
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
    return entry;
  }

  @override
  Future<MealLogEntry?> readById(String id) async {
    _requireNonBlank(id, 'id');
    return _entries[id];
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

  static String _requireNonBlank(String value, String name) {
    if (value.trim().isEmpty) {
      throw ArgumentError.value(value, name, 'must not be blank');
    }
    return value;
  }
}
