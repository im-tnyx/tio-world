import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_meal_log_repository.dart';

/// One stable ordered page of the canonical MealLog local-date range query.
abstract interface class MealLogRangePageTableGateway {
  Future<List<Map<String, dynamic>>> listRowsByLocalDateRangePage({
    required String userId,
    required String startLocalDate,
    required String endLocalDate,
    required int offset,
    required int limit,
  });
}

/// Supabase page source for [PagedSupabaseMealLogTableGateway].
final class SupabaseMealLogRangePageTableGateway
    implements MealLogRangePageTableGateway {
  const SupabaseMealLogRangePageTableGateway(this._client);

  static const _columns =
      'id, user_id, mode, meal_category_id, meal_name, note, consumed_at, '
      'consumed_local_date, consumed_timezone_id, consumed_utc_offset_minutes, '
      'capture_source, manual_nutrition_snapshot, created_at, updated_at, '
      'client_mutation_id, revision';

  final SupabaseClient _client;

  @override
  Future<List<Map<String, dynamic>>> listRowsByLocalDateRangePage({
    required String userId,
    required String startLocalDate,
    required String endLocalDate,
    required int offset,
    required int limit,
  }) async {
    if (offset < 0) {
      throw ArgumentError.value(offset, 'offset', 'must be non-negative');
    }
    if (limit <= 0) {
      throw ArgumentError.value(limit, 'limit', 'must be positive');
    }

    final rows = await _client
        .from('meal_log_entries')
        .select(_columns)
        .eq('user_id', userId)
        .gte('consumed_local_date', startLocalDate)
        .lte('consumed_local_date', endLocalDate)
        .order('consumed_local_date')
        .order('consumed_at', ascending: false)
        .order('id')
        .range(offset, offset + limit - 1);
    return [
      for (final row in rows) Map<String, dynamic>.from(row),
    ];
  }
}

/// Production gateway that keeps established MealLog CRUD behavior while
/// fully draining range reads used by calendar progress.
///
/// Supabase/PostgREST applies a server row cap. Reading stable ordered pages
/// avoids treating a truncated visible range as complete nutrition truth.
final class PagedSupabaseMealLogTableGateway
    implements MealLogTableGateway, MealLogRangeTableGateway {
  PagedSupabaseMealLogTableGateway({
    required MealLogTableGateway delegate,
    required MealLogRangePageTableGateway rangePages,
    int pageSize = 500,
  })  : _delegate = delegate,
        _rangePages = rangePages,
        _pageSize = _requirePageSize(pageSize);

  factory PagedSupabaseMealLogTableGateway.supabase(
    SupabaseClient client, {
    int pageSize = 500,
  }) {
    return PagedSupabaseMealLogTableGateway(
      delegate: SupabaseMealLogTableGateway(client),
      rangePages: SupabaseMealLogRangePageTableGateway(client),
      pageSize: pageSize,
    );
  }

  final MealLogTableGateway _delegate;
  final MealLogRangePageTableGateway _rangePages;
  final int _pageSize;

  @override
  Future<Map<String, dynamic>> insertRow(Map<String, dynamic> payload) =>
      _delegate.insertRow(payload);

  @override
  Future<Map<String, dynamic>?> updateRow({
    required String userId,
    required String id,
    required int expectedRevision,
    required Map<String, dynamic> payload,
  }) =>
      _delegate.updateRow(
        userId: userId,
        id: id,
        expectedRevision: expectedRevision,
        payload: payload,
      );

  @override
  Future<Map<String, dynamic>?> readRow({
    required String userId,
    required String id,
  }) =>
      _delegate.readRow(userId: userId, id: id);

  @override
  Future<Map<String, dynamic>?> readRowByClientMutationId({
    required String userId,
    required String clientMutationId,
  }) =>
      _delegate.readRowByClientMutationId(
        userId: userId,
        clientMutationId: clientMutationId,
      );

  @override
  Future<List<Map<String, dynamic>>> listRowsByLocalDate({
    required String userId,
    required String localDate,
  }) =>
      _delegate.listRowsByLocalDate(userId: userId, localDate: localDate);

  @override
  Future<List<Map<String, dynamic>>> listRowsByLocalDateRange({
    required String userId,
    required String startLocalDate,
    required String endLocalDate,
  }) async {
    final rows = <Map<String, dynamic>>[];
    for (var offset = 0;; offset += _pageSize) {
      final page = await _rangePages.listRowsByLocalDateRangePage(
        userId: userId,
        startLocalDate: startLocalDate,
        endLocalDate: endLocalDate,
        offset: offset,
        limit: _pageSize,
      );
      rows.addAll(page);
      if (page.length < _pageSize) break;
    }
    return List<Map<String, dynamic>>.unmodifiable(rows);
  }

  static int _requirePageSize(int value) {
    if (value <= 0) {
      throw ArgumentError.value(value, 'pageSize', 'must be positive');
    }
    return value;
  }
}
