import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_meal_log_repository.dart';

/// One immutable-id-keyset page of the canonical MealLog local-date range.
abstract interface class MealLogRangePageTableGateway {
  Future<List<Map<String, dynamic>>> listRowsByLocalDateRangePage({
    required String userId,
    required String startLocalDate,
    required String endLocalDate,
    required String? afterId,
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
    required String? afterId,
    required int limit,
  }) async {
    if (afterId != null && afterId.isEmpty) {
      throw ArgumentError.value(afterId, 'afterId', 'must be non-empty');
    }
    if (limit <= 0) {
      throw ArgumentError.value(limit, 'limit', 'must be positive');
    }

    var query = _client
        .from('meal_log_entries')
        .select(_columns)
        .eq('user_id', userId)
        .gte('consumed_local_date', startLocalDate)
        .lte('consumed_local_date', endLocalDate);
    if (afterId != null) {
      query = query.gt('id', afterId);
    }

    // Pagination uses the immutable unique row id rather than mutable Diary
    // presentation fields. The repository sorts the fully decoded result after
    // the complete read, so page order does not need to equal display order.
    final rows = await query.order('id').limit(limit);
    return [
      for (final row in rows) Map<String, dynamic>.from(row),
    ];
  }
}

/// Production gateway that keeps established MealLog CRUD behavior while
/// fully draining range reads used by calendar and selected-day summary truth.
///
/// Supabase/PostgREST applies a server row cap. Immutable-id keyset pages avoid
/// the duplicate/skip boundary drift that numeric offsets can produce when the
/// filtered range changes between independent page queries.
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
    final seenIds = <String>{};
    String? afterId;

    while (true) {
      final page = await _rangePages.listRowsByLocalDateRangePage(
        userId: userId,
        startLocalDate: startLocalDate,
        endLocalDate: endLocalDate,
        afterId: afterId,
        limit: _pageSize,
      );

      for (final row in page) {
        final id = _requireRowId(row);
        if (!seenIds.add(id)) {
          throw StateError(
            'MealLog range page source returned duplicate id "$id".',
          );
        }
      }
      rows.addAll(page);

      if (page.length < _pageSize) break;
      afterId = _requireRowId(page.last);
    }

    return List<Map<String, dynamic>>.unmodifiable(rows);
  }

  static int _requirePageSize(int value) {
    if (value <= 0) {
      throw ArgumentError.value(value, 'pageSize', 'must be positive');
    }
    return value;
  }

  static String _requireRowId(Map<String, dynamic> row) {
    final id = row['id'];
    if (id is! String || id.isEmpty) {
      throw const FormatException(
        'MealLog range page row requires a non-empty string id.',
      );
    }
    return id;
  }
}
