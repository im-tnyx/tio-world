import 'package:flutter_test/flutter_test.dart';
import 'package:tio_feature_nutrition/nutrition.dart';

void main() {
  test('range read drains every stable page before returning', () async {
    final pages = _FakeRangePages({
      0: [_row('a'), _row('b')],
      2: [_row('c'), _row('d')],
      4: [_row('e')],
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
      ('user-1', '2026-09-01', '2026-09-30', 0, 2),
      ('user-1', '2026-09-01', '2026-09-30', 2, 2),
      ('user-1', '2026-09-01', '2026-09-30', 4, 2),
    ]);
  });

  test('exact full page reads one terminal empty page', () async {
    final pages = _FakeRangePages({
      0: [_row('a'), _row('b')],
      2: const <Map<String, dynamic>>[],
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
    expect(pages.calls.map((call) => call.$4), [0, 2]);
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

  final Map<int, List<Map<String, dynamic>>> pages;
  final List<(String, String, String, int, int)> calls = [];

  @override
  Future<List<Map<String, dynamic>>> listRowsByLocalDateRangePage({
    required String userId,
    required String startLocalDate,
    required String endLocalDate,
    required int offset,
    required int limit,
  }) async {
    calls.add((userId, startLocalDate, endLocalDate, offset, limit));
    return pages[offset] ?? const <Map<String, dynamic>>[];
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
