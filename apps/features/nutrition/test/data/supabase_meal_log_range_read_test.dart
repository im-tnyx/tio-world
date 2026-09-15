import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tio_feature_nutrition/nutrition.dart';
import 'package:tio_shared/shared.dart';

void main() {
  test('range read forwards canonical bounds, decodes rows, and sorts',
      () async {
    final gateway = _RangeGateway([
      _row(
        id: 'day-2-old',
        localDate: '2026-09-13',
        consumedAt: '2026-09-13T08:00:00Z',
      ),
      _row(
        id: 'day-1',
        localDate: '2026-09-12',
        consumedAt: '2026-09-12T12:00:00Z',
      ),
      _row(
        id: 'day-2-new',
        localDate: '2026-09-13',
        consumedAt: '2026-09-13T10:00:00Z',
      ),
    ]);
    final repository = SupabaseMealLogRepository(
      client: _UnusedSupabaseClient(),
      mealCategoriesRepository: InMemoryMealCategoriesRepository(),
      gateway: gateway,
      currentUserId: () => ' user-1 ',
    );

    final entries = await repository.listByLocalDateRange(
      startDate: MealLogLocalDate(year: 2026, month: 9, day: 12),
      endDate: MealLogLocalDate(year: 2026, month: 9, day: 13),
    );

    expect(gateway.calls, [
      ('user-1', '2026-09-12', '2026-09-13'),
    ]);
    expect(entries.map((entry) => entry.id), [
      'day-1',
      'day-2-new',
      'day-2-old',
    ]);
  });

  test('range read rejects inverted dates before gateway access', () async {
    final gateway = _RangeGateway(const []);
    final repository = SupabaseMealLogRepository(
      client: _UnusedSupabaseClient(),
      mealCategoriesRepository: InMemoryMealCategoriesRepository(),
      gateway: gateway,
      currentUserId: () => 'user-1',
    );

    await expectLater(
      () => repository.listByLocalDateRange(
        startDate: MealLogLocalDate(year: 2026, month: 9, day: 14),
        endDate: MealLogLocalDate(year: 2026, month: 9, day: 13),
      ),
      throwsArgumentError,
    );
    expect(gateway.calls, isEmpty);
  });

  test('range read fails closed when injected gateway lacks capability',
      () async {
    final repository = SupabaseMealLogRepository(
      client: _UnusedSupabaseClient(),
      mealCategoriesRepository: InMemoryMealCategoriesRepository(),
      gateway: _SingleDayOnlyGateway(),
      currentUserId: () => 'user-1',
    );

    await expectLater(
      () => repository.listByLocalDateRange(
        startDate: MealLogLocalDate(year: 2026, month: 9, day: 12),
        endDate: MealLogLocalDate(year: 2026, month: 9, day: 13),
      ),
      throwsStateError,
    );
  });
}

Map<String, dynamic> _row({
  required String id,
  required String localDate,
  required String consumedAt,
}) {
  return <String, dynamic>{
    'id': id,
    'user_id': 'user-1',
    'mode': 'manual',
    'meal_category_id': 'meal_slot_1',
    'meal_name': null,
    'note': null,
    'consumed_at': consumedAt,
    'consumed_local_date': localDate,
    'consumed_timezone_id': null,
    'consumed_utc_offset_minutes': 0,
    'capture_source': 'quick_add',
    'manual_nutrition_snapshot': <String, dynamic>{
      'schemaVersion': 1,
      'nutrients': <String, dynamic>{'energy': 100},
    },
    'created_at': consumedAt,
    'updated_at': consumedAt,
    'client_mutation_id': null,
    'revision': 1,
  };
}

class _UnusedSupabaseClient extends Fake implements SupabaseClient {}

class _RangeGateway implements MealLogTableGateway, MealLogRangeTableGateway {
  _RangeGateway(this.rows);

  final List<Map<String, dynamic>> rows;
  final List<(String, String, String)> calls = [];

  @override
  Future<List<Map<String, dynamic>>> listRowsByLocalDateRange({
    required String userId,
    required String startLocalDate,
    required String endLocalDate,
  }) async {
    calls.add((userId, startLocalDate, endLocalDate));
    return rows;
  }

  @override
  Future<Map<String, dynamic>> insertRow(Map<String, dynamic> payload) =>
      throw UnimplementedError();

  @override
  Future<Map<String, dynamic>?> updateRow({
    required String userId,
    required String id,
    required int expectedRevision,
    required Map<String, dynamic> payload,
  }) =>
      throw UnimplementedError();

  @override
  Future<Map<String, dynamic>?> readRow({
    required String userId,
    required String id,
  }) =>
      throw UnimplementedError();

  @override
  Future<Map<String, dynamic>?> readRowByClientMutationId({
    required String userId,
    required String clientMutationId,
  }) =>
      throw UnimplementedError();

  @override
  Future<List<Map<String, dynamic>>> listRowsByLocalDate({
    required String userId,
    required String localDate,
  }) =>
      throw UnimplementedError();
}

class _SingleDayOnlyGateway implements MealLogTableGateway {
  @override
  Future<Map<String, dynamic>> insertRow(Map<String, dynamic> payload) =>
      throw UnimplementedError();

  @override
  Future<Map<String, dynamic>?> updateRow({
    required String userId,
    required String id,
    required int expectedRevision,
    required Map<String, dynamic> payload,
  }) =>
      throw UnimplementedError();

  @override
  Future<Map<String, dynamic>?> readRow({
    required String userId,
    required String id,
  }) =>
      throw UnimplementedError();

  @override
  Future<Map<String, dynamic>?> readRowByClientMutationId({
    required String userId,
    required String clientMutationId,
  }) =>
      throw UnimplementedError();

  @override
  Future<List<Map<String, dynamic>>> listRowsByLocalDate({
    required String userId,
    required String localDate,
  }) =>
      throw UnimplementedError();
}
