import 'package:flutter_test/flutter_test.dart';
import 'package:tio_feature_nutrition/nutrition.dart';

void main() {
  test('range read drains immutable-id keyset pages before returning', () async {
    final pages = _FakeRangePages({
      null: [_row('a'), _row('b')],
      'b': [_row('c'), _row('d')],
      'd': [_row('e')],
    });
    final gateway = PagedSupabaseMealLogTableGateway(
      delegate: _UnusedMealLogGateway(),
      rangePages: pages,
      pageSize: 2,
    );

    final rows = await gateway.listRowsByLocalDateRange(
      userId: 'user-1',
      startLocalDate: '2026-09-01',
      endLocalDate: '2026-09-30',
    );

    expect(rows.map((row) => row['id']), ['a', 'b', 'c', 'd', 'e']);
    expect(pages.calls, [
      ('user-1', '2026-09-01', '2026-09-30', null, 2),
      ('user-1', '2026-09-01', '2026-09-30', 'b', 2),
      ('user-1', '2026-09-01', '2026-09-30', 'd', 2),
    ]);
  });

  test('exact full page reads one terminal empty keyset page', () async {
    final pages = _FakeRangePages({
      null: [_row('a'), _row('b')],
      'b': const <Map<String, dynamic>>[],
    });
    final gateway = PagedSupabaseMealLogTableGateway(
      delegate: _UnusedMealLogGateway(),
      rangePages: pages,
      pageSize: 2,
    );

    final rows = await gateway.listRowsByLocalDateRange(
      userId: 'user-1',
      startLocalDate: '2026-09-01',
      endLocalDate: '2026-09-30',
    );

    expect(rows.map((row) => row['id']), ['a', 'b']);
    expect(pages.calls.map((call) => call.$4), [null, 'b']);
  });

  test('duplicate row across pages is rejected instead of double-counted',
      () async {
    final pages = _FakeRangePages({
      null: [_row('a'), _row('b')],
      'b': [_row('b'), _row('c')],
    });
    final gateway = PagedSupabaseMealLogTableGateway(
      delegate: _UnusedMealLogGateway(),
      rangePages: pages,
      pageSize: 2,
    );

    await expectLater(
      gateway.listRowsByLocalDateRange(
        userId: 'user-1',
        startLocalDate: '2026-09-01',
        endLocalDate: '2026-09-30',
      ),
      throwsStateError,
    );
  });

  test('page size must be positive', () {
    expect(
      () => PagedSupabaseMealLogTableGateway(
        delegate: _UnusedMealLogGateway(),
        rangePages: _FakeRangePages(const {}),
        pageSize: 0,
      ),
      throwsArgumentError,
    );
  });
}

Map<String, dynamic> _row(String id) => <String, dynamic>{'id': id};

final class _FakeRangePages implements MealLogRangePageTableGateway {
  _FakeRangePages(this.pages);

  final Map<String?, List<Map<String, dynamic>>> pages;
  final List<(String, String, String, String?, int)> calls = [];

  @override
  Future<List<Map<String, dynamic>>> listRowsByLocalDateRangePage({
    required String userId,
    required String startLocalDate,
    required String endLocalDate,
    required String? afterId,
    required int limit,
  }) async {
    calls.add((userId, startLocalDate, endLocalDate, afterId, limit));
    return pages[afterId] ?? const <Map<String, dynamic>>[];
  }
}

final class _UnusedMealLogGateway implements MealLogTableGateway {
  @override
  Future<Map<String, dynamic>> insertRow(Map<String, dynamic> payload) =>
      throw UnimplementedError();

  @override
  Future<List<Map<String, dynamic>>> listRowsByLocalDate({
    required String userId,
    required String localDate,
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
  Future<Map<String, dynamic>?> updateRow({
    required String userId,
    required String id,
    required int expectedRevision,
    required Map<String, dynamic> payload,
  }) =>
      throw UnimplementedError();
}
