import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tio_feature_nutrition/nutrition.dart';
import 'package:tio_shared/shared.dart';

const _mutation = 'a2180000-0000-4000-8000-000000000101';
const _parentId = 'a2180000-0000-4000-8000-000000000102';
const _item1Id = 'a2180000-0000-4000-8000-000000000103';
const _item2Id = 'a2180000-0000-4000-8000-000000000104';

void main() {
  group('DetailedMealLogCreate', () {
    test('normalizes mutation identity and optional blank text', () {
      final input = _input(
        clientMutationId: 'A2180000-0000-4000-8000-000000000101',
        mealName: '  ',
        note: '\t',
      );

      expect(input.clientMutationId, _mutation);
      expect(input.mealName, isNull);
      expect(input.note, isNull);
      expect(input.items, hasLength(2));
      expect(() => input.items.add(_item('Extra', 1)), throwsUnsupportedError);
    });

    test('rejects invalid mutation ids, empty items and invalid quantities', () {
      expect(
        () => _input(clientMutationId: 'not-a-uuid'),
        throwsArgumentError,
      );
      expect(
        () => DetailedMealLogCreate(
          clientMutationId: _mutation,
          mealCategoryId: 'meal_slot_2',
          consumedAt: DateTime.utc(2026, 9, 17, 12),
          consumedLocalDate: MealLogLocalDate(
            year: 2026,
            month: 9,
            day: 17,
          ),
          consumedUtcOffsetMinutes: 330,
          items: const [],
        ),
        throwsArgumentError,
      );
      for (final quantity in [0, -1, double.infinity, double.nan]) {
        expect(
          () => DetailedMealLogCreateItem(
            displayName: 'Dal',
            quantity: quantity,
            servingUnit: 'bowl',
            nutritionSnapshot: _nutrition(220),
          ),
          throwsArgumentError,
        );
      }
    });
  });

  group('InMemoryMealLogRepository detailed create', () {
    test('creates durable-looking detailed history and reconciles same key',
        () async {
      final repository = InMemoryMealLogRepository(
        mealCategoriesRepository: InMemoryMealCategoriesRepository(),
        clock: () => DateTime.utc(2026, 9, 17, 13),
        userId: 'user-1',
      );
      final input = _input();

      final first = await repository.createDetailed(input);
      final retry = await repository.createDetailed(input);

      expect(identical(first, retry), isTrue);
      expect(first.mode, MealLogMode.detailed);
      expect(first.userId, 'user-1');
      expect(first.revision, 1);
      expect(first.detailedItems.map((item) => item.displayName), [
        'Dal',
        'Roti',
      ]);
      expect(first.detailedItems.every((item) => item.mealLogEntryId == first.id),
          isTrue);
      expect(first.manualNutritionSnapshot, isNull);
    });

    test('same mutation id with different item facts fails closed', () async {
      final repository = InMemoryMealLogRepository(
        mealCategoriesRepository: InMemoryMealCategoriesRepository(),
      );
      await repository.createDetailed(_input());

      await expectLater(
        () => repository.createDetailed(
          _input(items: [_item('Dal', 2), _item('Roti', 2)]),
        ),
        throwsA(isA<MealLogCreateMutationConflict>()),
      );
    });
  });

  group('SupabaseMealLogRepository detailed create', () {
    test('signed-out create fails before mutation read or RPC', () async {
      final parent = _ParentGateway();
      final rpc = _DetailedCreateGateway(resultId: _parentId);
      final items = _ItemGateway();
      final repository = _repository(
        parent: parent,
        rpc: rpc,
        items: items,
        userId: '   ',
      );

      await expectLater(() => repository.createDetailed(_input()), throwsStateError);
      expect(parent.mutationReads, isEmpty);
      expect(rpc.params, isEmpty);
    });

    test('RPC receives provider-neutral facts and hydrates durable IDs', () async {
      final parent = _ParentGateway(
        mutationSequence: [null],
        readById: {_parentId: _detailedRow()},
      );
      final rpc = _DetailedCreateGateway(resultId: _parentId);
      final items = _ItemGateway(rows: [_itemRow1(), _itemRow2()]);
      final repository = _repository(parent: parent, rpc: rpc, items: items);

      final created = await repository.createDetailed(_input());

      expect(rpc.params, hasLength(1));
      final params = rpc.params.single;
      expect(params.keys, {
        'p_client_mutation_id',
        'p_meal_category_id',
        'p_meal_name',
        'p_note',
        'p_consumed_at',
        'p_consumed_local_date',
        'p_consumed_timezone_id',
        'p_consumed_utc_offset_minutes',
        'p_capture_source',
        'p_items',
      });
      expect(params, isNot(contains('user_id')));
      expect(params, isNot(contains('id')));
      final sentItems = params['p_items'] as List<dynamic>;
      expect(sentItems, hasLength(2));
      expect((sentItems.first as Map<String, dynamic>).keys, {
        'display_name',
        'brand_name',
        'quantity',
        'serving_unit',
        'nutrition_snapshot',
      });
      expect(created.id, _parentId);
      expect(created.mode, MealLogMode.detailed);
      expect(created.detailedItems.map((item) => item.id), [_item1Id, _item2Id]);
      expect(created.detailedItems.map((item) => item.displayName), ['Dal', 'Roti']);
      expect(items.entryIdCalls, [[_parentId]]);
    });

    test('same-key pre-reconciliation returns existing aggregate without RPC',
        () async {
      final parent = _ParentGateway(
        mutationSequence: [_detailedRow()],
      );
      final rpc = _DetailedCreateGateway(resultId: _parentId);
      final items = _ItemGateway(rows: [_itemRow1(), _itemRow2()]);

      final created = await _repository(
        parent: parent,
        rpc: rpc,
        items: items,
      ).createDetailed(_input());

      expect(created.id, _parentId);
      expect(rpc.params, isEmpty);
      expect(items.entryIdCalls, [[_parentId]]);
    });

    test('RPC mutation conflict maps to canonical repository conflict', () async {
      final parent = _ParentGateway(mutationSequence: [null]);
      final rpc = _DetailedCreateGateway(
        error: const PostgrestException(
          message: 'meal_log_create_mutation_conflict',
          code: 'P0001',
        ),
      );

      await expectLater(
        () => _repository(
          parent: parent,
          rpc: rpc,
          items: _ItemGateway(),
        ).createDetailed(_input()),
        throwsA(
          isA<MealLogCreateMutationConflict>().having(
            (error) => error.clientMutationId,
            'clientMutationId',
            _mutation,
          ),
        ),
      );
    });

    test('ambiguous RPC failure reconciles by the same mutation id', () async {
      final parent = _ParentGateway(
        mutationSequence: [null, _detailedRow()],
      );
      final rpc = _DetailedCreateGateway(error: StateError('response lost'));
      final items = _ItemGateway(rows: [_itemRow1(), _itemRow2()]);

      final created = await _repository(
        parent: parent,
        rpc: rpc,
        items: items,
      ).createDetailed(_input());

      expect(created.id, _parentId);
      expect(parent.mutationReads, [
        ('user-1', _mutation),
        ('user-1', _mutation),
      ]);
    });

    test('unconfirmed ambiguous outcome preserves the same mutation id', () async {
      final parent = _ParentGateway(mutationSequence: [null, null]);
      final rpc = _DetailedCreateGateway(error: StateError('response lost'));

      await expectLater(
        () => _repository(
          parent: parent,
          rpc: rpc,
          items: _ItemGateway(),
        ).createDetailed(_input()),
        throwsA(
          isA<MealLogCreateOutcomeUnknown>().having(
            (error) => error.clientMutationId,
            'clientMutationId',
            _mutation,
          ),
        ),
      );
    });
  });

  group('SupabaseMealLogRepository detailed reads', () {
    test('readById hydrates detailed children in persisted position order',
        () async {
      final parent = _ParentGateway(readById: {_parentId: _detailedRow()});
      final items = _ItemGateway(rows: [_itemRow2(), _itemRow1()]);

      final entry = await _repository(
        parent: parent,
        rpc: _DetailedCreateGateway(resultId: _parentId),
        items: items,
      ).readById(_parentId);

      expect(entry, isNotNull);
      expect(entry!.mode, MealLogMode.detailed);
      expect(entry.detailedItems.map((item) => item.displayName), ['Dal', 'Roti']);
      expect(items.entryIdCalls.single, [_parentId]);
    });

    test('selected-day mixed modes batch detailed children once', () async {
      final parent = _ParentGateway(
        localDateRows: [
          _manualRow(id: 'manual-1'),
          _detailedRow(id: _parentId),
          _detailedRow(
            id: 'a2180000-0000-4000-8000-000000000105',
            consumedAt: '2026-09-17T13:00:00.000Z',
          ),
        ],
      );
      const secondParent = 'a2180000-0000-4000-8000-000000000105';
      final items = _ItemGateway(rows: [
        _itemRow1(),
        _itemRow2(),
        _itemRow(
          id: 'a2180000-0000-4000-8000-000000000106',
          parentId: secondParent,
          position: 0,
          name: 'Rice',
          quantity: 1,
          unit: 'bowl',
          calories: 300,
        ),
      ]);

      final entries = await _repository(
        parent: parent,
        rpc: _DetailedCreateGateway(resultId: _parentId),
        items: items,
      ).listByLocalDate(
        MealLogLocalDate(year: 2026, month: 9, day: 17),
      );

      expect(items.entryIdCalls, [
        [_parentId, secondParent],
      ]);
      expect(entries.map((entry) => entry.id), [
        secondParent,
        _parentId,
        'manual-1',
      ]);
      expect(entries.map((entry) => entry.mode), [
        MealLogMode.detailed,
        MealLogMode.detailed,
        MealLogMode.manual,
      ]);
    });

    test('detailed row with no children fails closed', () async {
      final parent = _ParentGateway(readById: {_parentId: _detailedRow()});

      await expectLater(
        () => _repository(
          parent: parent,
          rpc: _DetailedCreateGateway(resultId: _parentId),
          items: _ItemGateway(),
        ).readById(_parentId),
        throwsFormatException,
      );
    });

    test('unknown parent mode fails closed', () async {
      final row = _manualRow(id: 'unknown-mode')..['mode'] = 'future_mode';
      final parent = _ParentGateway(readById: {'unknown-mode': row});

      await expectLater(
        () => _repository(
          parent: parent,
          rpc: _DetailedCreateGateway(resultId: _parentId),
          items: _ItemGateway(),
        ).readById('unknown-mode'),
        throwsFormatException,
      );
    });
  });
}

SupabaseMealLogRepository _repository({
  required _ParentGateway parent,
  required _DetailedCreateGateway rpc,
  required _ItemGateway items,
  String? userId = 'user-1',
}) {
  return SupabaseMealLogRepository(
    client: SupabaseClient('http://localhost', 'test-anon-key'),
    mealCategoriesRepository: InMemoryMealCategoriesRepository(),
    gateway: parent,
    detailedCreateGateway: rpc,
    itemReadGateway: items,
    currentUserId: () => userId,
  );
}

DetailedMealLogCreate _input({
  String clientMutationId = _mutation,
  String? mealName = 'Lunch',
  String? note = 'After training',
  List<DetailedMealLogCreateItem>? items,
}) {
  return DetailedMealLogCreate(
    clientMutationId: clientMutationId,
    mealCategoryId: 'meal_slot_2',
    mealName: mealName,
    note: note,
    consumedAt: DateTime.utc(2026, 9, 17, 12),
    consumedLocalDate: MealLogLocalDate(year: 2026, month: 9, day: 17),
    consumedTimezoneId: 'Asia/Kolkata',
    consumedUtcOffsetMinutes: 330,
    captureSource: MealLogCaptureSource.text,
    items: items ?? [_item('Dal', 1), _item('Roti', 2, calories: 240)],
  );
}

DetailedMealLogCreateItem _item(
  String name,
  num quantity, {
  num calories = 220,
}) {
  return DetailedMealLogCreateItem(
    displayName: name,
    quantity: quantity,
    servingUnit: name == 'Roti' ? 'piece' : 'bowl',
    nutritionSnapshot: _nutrition(calories),
  );
}

NutritionSnapshot _nutrition(num calories) {
  return NutritionSnapshot(
    schemaVersion: 1,
    nutrients: <NutrientId, num>{
      NutrientId.energy: calories,
    },
  );
}

Map<String, dynamic> _detailedRow({
  String id = _parentId,
  String consumedAt = '2026-09-17T12:00:00.000Z',
}) {
  return <String, dynamic>{
    'id': id,
    'user_id': 'user-1',
    'mode': 'detailed',
    'meal_category_id': 'meal_slot_2',
    'meal_name': 'Lunch',
    'note': 'After training',
    'consumed_at': consumedAt,
    'consumed_local_date': '2026-09-17',
    'consumed_timezone_id': 'Asia/Kolkata',
    'consumed_utc_offset_minutes': 330,
    'capture_source': 'text',
    'manual_nutrition_snapshot': null,
    'created_at': '2026-09-17T12:00:01.000Z',
    'updated_at': '2026-09-17T12:00:01.000Z',
    'client_mutation_id': _mutation,
    'revision': 1,
  };
}

Map<String, dynamic> _manualRow({required String id}) {
  return <String, dynamic>{
    'id': id,
    'user_id': 'user-1',
    'mode': 'manual',
    'meal_category_id': 'meal_slot_2',
    'meal_name': 'Quick add',
    'note': null,
    'consumed_at': '2026-09-17T11:00:00.000Z',
    'consumed_local_date': '2026-09-17',
    'consumed_timezone_id': null,
    'consumed_utc_offset_minutes': 330,
    'capture_source': 'quick_add',
    'manual_nutrition_snapshot': _nutrition(350).toJson(),
    'created_at': '2026-09-17T11:00:01.000Z',
    'updated_at': '2026-09-17T11:00:01.000Z',
    'client_mutation_id': null,
    'revision': 1,
  };
}

Map<String, dynamic> _itemRow1() => _itemRow(
      id: _item1Id,
      parentId: _parentId,
      position: 0,
      name: 'Dal',
      quantity: 1,
      unit: 'bowl',
      calories: 220,
    );

Map<String, dynamic> _itemRow2() => _itemRow(
      id: _item2Id,
      parentId: _parentId,
      position: 1,
      name: 'Roti',
      quantity: 2,
      unit: 'piece',
      calories: 240,
    );

Map<String, dynamic> _itemRow({
  required String id,
  required String parentId,
  required int position,
  required String name,
  required num quantity,
  required String unit,
  required num calories,
}) {
  return <String, dynamic>{
    'id': id,
    'meal_log_entry_id': parentId,
    'position': position,
    'display_name': name,
    'brand_name': null,
    'quantity': quantity,
    'serving_unit': unit,
    'nutrition_snapshot': _nutrition(calories).toJson(),
  };
}

final class _ParentGateway
    implements MealLogTableGateway, MealLogRangeTableGateway {
  _ParentGateway({
    List<Map<String, dynamic>?>? mutationSequence,
    Map<String, Map<String, dynamic>>? readById,
    List<Map<String, dynamic>>? localDateRows,
    List<Map<String, dynamic>>? rangeRows,
  })  : mutationSequence = mutationSequence ?? <Map<String, dynamic>?>[],
        readById = readById ?? <String, Map<String, dynamic>>{},
        localDateRows = localDateRows ?? <Map<String, dynamic>>[],
        rangeRows = rangeRows ?? <Map<String, dynamic>>[];

  final List<Map<String, dynamic>?> mutationSequence;
  final Map<String, Map<String, dynamic>> readById;
  final List<Map<String, dynamic>> localDateRows;
  final List<Map<String, dynamic>> rangeRows;
  final List<(String, String)> mutationReads = [];
  var _mutationIndex = 0;

  @override
  Future<Map<String, dynamic>> insertRow(Map<String, dynamic> payload) =>
      throw StateError('manual insert not used');

  @override
  Future<Map<String, dynamic>?> updateRow({
    required String userId,
    required String id,
    required int expectedRevision,
    required Map<String, dynamic> payload,
  }) => throw StateError('manual update not used');

  @override
  Future<Map<String, dynamic>?> readRow({
    required String userId,
    required String id,
  }) async => readById[id];

  @override
  Future<Map<String, dynamic>?> readRowByClientMutationId({
    required String userId,
    required String clientMutationId,
  }) async {
    mutationReads.add((userId, clientMutationId));
    if (_mutationIndex >= mutationSequence.length) return null;
    return mutationSequence[_mutationIndex++];
  }

  @override
  Future<List<Map<String, dynamic>>> listRowsByLocalDate({
    required String userId,
    required String localDate,
  }) async => List<Map<String, dynamic>>.from(localDateRows);

  @override
  Future<List<Map<String, dynamic>>> listRowsByLocalDateRange({
    required String userId,
    required String startLocalDate,
    required String endLocalDate,
  }) async => List<Map<String, dynamic>>.from(rangeRows);
}

final class _DetailedCreateGateway implements DetailedMealLogCreateGateway {
  _DetailedCreateGateway({this.resultId, this.error});

  final String? resultId;
  final Object? error;
  final List<Map<String, dynamic>> params = [];

  @override
  Future<String> createDetailed(Map<String, dynamic> value) async {
    params.add(Map<String, dynamic>.from(value));
    if (error != null) throw error!;
    return resultId!;
  }
}

final class _ItemGateway implements MealLogItemReadGateway {
  _ItemGateway({List<Map<String, dynamic>>? rows})
      : rows = rows ?? <Map<String, dynamic>>[];

  final List<Map<String, dynamic>> rows;
  final List<List<String>> entryIdCalls = [];

  @override
  Future<List<Map<String, dynamic>>> listItemRowsByEntryIds(
    List<String> entryIds,
  ) async {
    entryIdCalls.add(List<String>.from(entryIds));
    final requested = entryIds.toSet();
    return [
      for (final row in rows)
        if (requested.contains(row['meal_log_entry_id']))
          Map<String, dynamic>.from(row),
    ];
  }
}
