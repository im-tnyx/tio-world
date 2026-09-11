import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tio_feature_nutrition/nutrition.dart';
import 'package:tio_shared/shared.dart';

const _mutation1 = '11111111-1111-4111-8111-111111111111';

void main() {
  group('ManualMealLogCreate mutation identity', () {
    test('normalizes UUID casing and rejects non-canonical values', () {
      final input = _input(
        clientMutationId: 'AAAAAAAA-AAAA-4AAA-8AAA-AAAAAAAAAAAA',
      );
      expect(
        input.clientMutationId,
        'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
      );

      for (final invalid in [
        '',
        '  $_mutation1',
        'not-a-uuid',
        '11111111111141118111111111111111',
      ]) {
        expect(
          () => _input(clientMutationId: invalid),
          throwsArgumentError,
        );
      }
    });
  });

  group('SupabaseMealLogRepository writes', () {
    test('signed-out create fails before gateway access', () async {
      final gateway = _FakeMealLogGateway(
        insertResult: _row(clientMutationId: _mutation1),
      );
      final repository = _repository(gateway: gateway, userId: '  ');

      await expectLater(
        () => repository.createManual(_input()),
        throwsStateError,
      );
      expect(gateway.insertPayloads, isEmpty);
      expect(gateway.mutationReadCalls, isEmpty);
    });

    test('create writes stable mutation identity and hydrates DB fields',
        () async {
      final gateway = _FakeMealLogGateway(
        insertResult: _row(
          id: 'db-id-1',
          mealName: 'Lunch',
          note: 'After training',
          captureSource: 'quick_add',
          clientMutationId: _mutation1,
        ),
      );
      final repository = _repository(gateway: gateway, userId: ' user-1 ');

      final created = await repository.createManual(
        _input(
          mealName: 'Lunch',
          note: 'After training',
          captureSource: MealLogCaptureSource.quickAdd,
        ),
      );

      expect(gateway.mutationReadCalls.single, ('user-1', _mutation1));
      expect(gateway.insertPayloads, hasLength(1));
      final payload = gateway.insertPayloads.single;
      expect(payload.keys, {
        'user_id',
        'mode',
        'meal_category_id',
        'meal_name',
        'note',
        'consumed_at',
        'consumed_local_date',
        'consumed_timezone_id',
        'consumed_utc_offset_minutes',
        'capture_source',
        'manual_nutrition_snapshot',
        'client_mutation_id',
      });
      expect(payload['user_id'], 'user-1');
      expect(payload['mode'], 'manual');
      expect(payload['meal_category_id'], 'meal_slot_2');
      expect(payload['consumed_local_date'], '2026-09-11');
      expect(payload['capture_source'], 'quick_add');
      expect(payload['client_mutation_id'], _mutation1);
      expect(payload, isNot(contains('id')));
      expect(payload, isNot(contains('created_at')));
      expect(payload, isNot(contains('updated_at')));
      expect(created.id, 'db-id-1');
      expect(created.userId, 'user-1');
      expect(created.mode, MealLogMode.manual);
      expect(created.mealName, 'Lunch');
      expect(created.note, 'After training');
      expect(created.captureSource, MealLogCaptureSource.quickAdd);
      expect(created.createdAt, DateTime.utc(2026, 9, 11, 10));
      expect(created.updatedAt, DateTime.utc(2026, 9, 11, 10));
    });

    test('same-key retry returns existing row without a second insert',
        () async {
      final gateway = _FakeMealLogGateway(
        mutationReadSequence: [
          _row(id: 'already-created', clientMutationId: _mutation1),
        ],
      );
      final created = await _repository(gateway: gateway).createManual(_input());

      expect(created.id, 'already-created');
      expect(gateway.insertPayloads, isEmpty);
      expect(gateway.mutationReadCalls, [('user-1', _mutation1)]);
    });

    test('already-created retry survives category archived after commit',
        () async {
      final categories = InMemoryMealCategoriesRepository();
      final current = await categories.read();
      await categories.upsert(
        MealCategoriesConfig(
          items: current.items.map(
            (item) => item.id == 'meal_slot_2' ? item.withActive(false) : item,
          ),
        ),
      );
      final gateway = _FakeMealLogGateway(
        mutationReadSequence: [
          _row(id: 'already-created', clientMutationId: _mutation1),
        ],
      );

      final created = await _repository(
        gateway: gateway,
        mealCategoriesRepository: categories,
      ).createManual(_input());

      expect(created.id, 'already-created');
      expect(gateway.insertPayloads, isEmpty);
    });

    test('database uniqueness conflict reconciles the canonical row',
        () async {
      final gateway = _FakeMealLogGateway(
        insertError: const PostgrestException(
          message: 'duplicate',
          code: '23505',
        ),
        mutationReadSequence: [
          null,
          _row(id: 'winner', clientMutationId: _mutation1),
        ],
      );

      final created = await _repository(gateway: gateway).createManual(_input());

      expect(created.id, 'winner');
      expect(gateway.insertPayloads, hasLength(1));
      expect(gateway.mutationReadCalls, [
        ('user-1', _mutation1),
        ('user-1', _mutation1),
      ]);
    });

    test('response-loss failure reconciles committed row by same key', () async {
      final gateway = _FakeMealLogGateway(
        insertError: StateError('response lost'),
        mutationReadSequence: [
          null,
          _row(id: 'committed', clientMutationId: _mutation1),
        ],
      );

      final created = await _repository(gateway: gateway).createManual(_input());
      expect(created.id, 'committed');
      expect(gateway.insertPayloads, hasLength(1));
    });

    test('unconfirmed response-loss reports outcome unknown with same key',
        () async {
      final gateway = _FakeMealLogGateway(
        insertError: StateError('response lost'),
        mutationReadSequence: [null, null],
      );

      await expectLater(
        () => _repository(gateway: gateway).createManual(_input()),
        throwsA(
          isA<MealLogCreateOutcomeUnknown>().having(
            (error) => error.clientMutationId,
            'clientMutationId',
            _mutation1,
          ),
        ),
      );
      expect(gateway.insertPayloads, hasLength(1));
    });

    test('unavailable pre-reconciliation never attempts a blind insert',
        () async {
      final gateway = _FakeMealLogGateway(
        mutationReadSequence: [StateError('offline')],
      );

      await expectLater(
        () => _repository(gateway: gateway).createManual(_input()),
        throwsA(isA<MealLogCreateOutcomeUnknown>()),
      );
      expect(gateway.insertPayloads, isEmpty);
    });

    test('known database validation rejection is not mislabeled ambiguous',
        () async {
      const failure = PostgrestException(
        message: 'check rejected',
        code: '23514',
      );
      final gateway = _FakeMealLogGateway(
        insertError: failure,
        mutationReadSequence: [null],
      );

      await expectLater(
        () => _repository(gateway: gateway).createManual(_input()),
        throwsA(
          isA<PostgrestException>().having(
            (error) => error.code,
            'code',
            '23514',
          ),
        ),
      );
      expect(gateway.mutationReadCalls, hasLength(1));
    });

    test('same mutation id with different facts fails closed', () async {
      final gateway = _FakeMealLogGateway(
        mutationReadSequence: [
          _row(
            id: 'existing',
            mealName: 'Original',
            clientMutationId: _mutation1,
          ),
        ],
      );

      await expectLater(
        () => _repository(gateway: gateway).createManual(
          _input(mealName: 'Different'),
        ),
        throwsA(isA<MealLogCreateMutationConflict>()),
      );
      expect(gateway.insertPayloads, isEmpty);
    });

    test('blank optional text is persisted as null, not fabricated', () async {
      final gateway = _FakeMealLogGateway(
        insertResult: _row(clientMutationId: _mutation1),
      );
      final repository = _repository(gateway: gateway);

      await repository.createManual(
        _input(mealName: '  ', note: '\t'),
      );

      final payload = gateway.insertPayloads.single;
      expect(payload['meal_name'], isNull);
      expect(payload['note'], isNull);
    });

    test('missing and archived Meal Category ids fail before insert', () async {
      final missingGateway = _FakeMealLogGateway();
      await expectLater(
        () => _repository(gateway: missingGateway).createManual(
          _input(mealCategoryId: 'missing-category'),
        ),
        throwsArgumentError,
      );
      expect(missingGateway.insertPayloads, isEmpty);

      final categories = InMemoryMealCategoriesRepository();
      final current = await categories.read();
      await categories.upsert(
        MealCategoriesConfig(
          items: current.items.map(
            (item) => item.id == 'meal_slot_2' ? item.withActive(false) : item,
          ),
        ),
      );
      final archivedGateway = _FakeMealLogGateway();
      await expectLater(
        () => _repository(
          gateway: archivedGateway,
          mealCategoriesRepository: categories,
        ).createManual(_input()),
        throwsArgumentError,
      );
      expect(archivedGateway.insertPayloads, isEmpty);
    });
  });

  group('SupabaseMealLogRepository reads', () {
    test('signed-out read fails before gateway access', () async {
      final gateway = _FakeMealLogGateway();
      final repository = _repository(gateway: gateway, userId: null);

      await expectLater(() => repository.readById('row-1'), throwsStateError);
      expect(gateway.readCalls, isEmpty);
    });

    test('signed-out selected-day read fails before gateway access', () async {
      final gateway = _FakeMealLogGateway();
      final repository = _repository(gateway: gateway, userId: '  ');

      await expectLater(
        () => repository.listByLocalDate(
          MealLogLocalDate(year: 2026, month: 9, day: 11),
        ),
        throwsStateError,
      );
      expect(gateway.localDateReadCalls, isEmpty);
    });

    test('missing row returns null and keeps owner filter', () async {
      final gateway = _FakeMealLogGateway(readResult: null);

      expect(await _repository(gateway: gateway).readById('row-1'), isNull);
      expect(gateway.readCalls.single, ('user-1', 'row-1'));
    });

    test('selected-day read uses owner + stored date and deterministic order',
        () async {
      final gateway = _FakeMealLogGateway(
        localDateReadResults: [
          _row(
            id: 'row-c',
            consumedAt: '2026-09-11T06:00:00.000Z',
          ),
          _row(
            id: 'row-b',
            consumedAt: '2026-09-11T08:00:00.000Z',
          ),
          _row(
            id: 'row-a',
            consumedAt: '2026-09-11T08:00:00.000Z',
          ),
        ],
      );
      final repository = _repository(gateway: gateway, userId: ' user-1 ');
      final localDate = MealLogLocalDate(year: 2026, month: 9, day: 11);

      final entries = await repository.listByLocalDate(localDate);

      expect(gateway.localDateReadCalls.single, ('user-1', '2026-09-11'));
      expect(entries.map((entry) => entry.id), ['row-a', 'row-b', 'row-c']);
      expect(entries.every((entry) => entry.consumedLocalDate == localDate),
          isTrue);
    });

    test('selected-day empty result stays empty', () async {
      final gateway = _FakeMealLogGateway();
      final entries = await _repository(gateway: gateway).listByLocalDate(
        MealLogLocalDate(year: 2026, month: 9, day: 10),
      );

      expect(entries, isEmpty);
      expect(gateway.localDateReadCalls.single, ('user-1', '2026-09-10'));
    });

    test('selected-day historical read does not revalidate archived category',
        () async {
      final categories = InMemoryMealCategoriesRepository();
      final current = await categories.read();
      await categories.upsert(
        MealCategoriesConfig(
          items: current.items.map(
            (item) => item.id == 'meal_slot_2' ? item.withActive(false) : item,
          ),
        ),
      );
      final gateway = _FakeMealLogGateway(
        localDateReadResults: [_row(id: 'historical-row')],
      );

      final entries = await _repository(
        gateway: gateway,
        mealCategoriesRepository: categories,
      ).listByLocalDate(
        MealLogLocalDate(year: 2026, month: 9, day: 11),
      );

      expect(entries.single.id, 'historical-row');
      expect(entries.single.mealCategoryId, 'meal_slot_2');
    });

    test('selected-day malformed row fails closed instead of being skipped',
        () async {
      final malformed = _row(id: 'bad-row')..remove('created_at');
      final gateway = _FakeMealLogGateway(
        localDateReadResults: [
          _row(id: 'good-row'),
          malformed,
        ],
      );

      await expectLater(
        () => _repository(gateway: gateway).listByLocalDate(
          MealLogLocalDate(year: 2026, month: 9, day: 11),
        ),
        throwsFormatException,
      );
    });

    test('historical null mutation id still decodes every manual field',
        () async {
      final gateway = _FakeMealLogGateway(
        readResult: _row(
          id: 'row-1',
          mealName: 'Dinner',
          note: 'Late meal',
          captureSource: 'text',
          timezoneId: 'Asia/Kolkata',
          offsetMinutes: 330,
        ),
      );

      final entry = await _repository(gateway: gateway).readById('row-1');

      expect(entry, isNotNull);
      expect(entry!.id, 'row-1');
      expect(entry.userId, 'user-1');
      expect(entry.mealCategoryId, 'meal_slot_2');
      expect(entry.mealName, 'Dinner');
      expect(entry.note, 'Late meal');
      expect(entry.consumedAt, DateTime.utc(2026, 9, 11, 7, 30));
      expect(entry.consumedLocalDate.toIso8601String(), '2026-09-11');
      expect(entry.consumedTimezoneId, 'Asia/Kolkata');
      expect(entry.consumedUtcOffsetMinutes, 330);
      expect(entry.captureSource, MealLogCaptureSource.text);
      expect(entry.createdAt, DateTime.utc(2026, 9, 11, 10));
      expect(entry.updatedAt, DateTime.utc(2026, 9, 11, 10));
    });

    test('numeric-offset timestamp normalizes to canonical UTC', () async {
      final gateway = _FakeMealLogGateway(
        readResult: _row(consumedAt: '2026-09-11T13:00:00+05:30'),
      );

      final entry = await _repository(gateway: gateway).readById('row-1');
      expect(entry!.consumedAt, DateTime.utc(2026, 9, 11, 7, 30));
    });

    test('offset-less timestamps fail closed', () async {
      for (final row in [
        _row(consumedAt: '2026-09-11T07:30:00'),
        _row(createdAt: '2026-09-11T10:00:00'),
      ]) {
        final gateway = _FakeMealLogGateway(readResult: row);
        await expectLater(
          () => _repository(gateway: gateway).readById('row-1'),
          throwsFormatException,
        );
      }
    });

    test('snapshot preserves explicit zero, missing, and future keys', () async {
      final gateway = _FakeMealLogGateway(
        readResult: _row(
          snapshot: {
            'schemaVersion': 1,
            'nutrients': {
              'protein': 0,
              'future_nutrient': 17,
            },
          },
        ),
      );

      final entry = await _repository(gateway: gateway).readById('row-1');
      final snapshot = entry!.manualNutritionSnapshot!;

      expect(snapshot.containsNutrient(NutrientId.protein), isTrue);
      expect(snapshot.amountFor(NutrientId.protein), 0);
      expect(snapshot.containsNutrient(NutrientId.energy), isFalse);
    });

    test('offset-only row remains valid without fabricated timezone id',
        () async {
      final gateway = _FakeMealLogGateway(
        readResult: _row(timezoneId: null, offsetMinutes: 330),
      );

      final entry = await _repository(gateway: gateway).readById('row-1');
      expect(entry!.consumedTimezoneId, isNull);
      expect(entry.consumedUtcOffsetMinutes, 330);
    });

    test('unknown mode and capture source fail instead of being remapped',
        () async {
      for (final row in [
        _row(mode: 'future_mode'),
        _row(captureSource: 'future_capture'),
      ]) {
        final gateway = _FakeMealLogGateway(readResult: row);
        await expectLater(
          () => _repository(gateway: gateway).readById('row-1'),
          throwsFormatException,
        );
      }
    });

    test('malformed rows and owner mismatches fail closed', () async {
      final missingTimestamp = _row()..remove('created_at');
      for (final row in [
        missingTimestamp,
        _row(userId: 'other-user'),
        _row(timezoneId: null, offsetMinutes: null),
      ]) {
        final gateway = _FakeMealLogGateway(readResult: row);
        await expectLater(
          () => _repository(gateway: gateway).readById('row-1'),
          throwsFormatException,
        );
      }
    });

    test('blank read identity is rejected before gateway access', () async {
      final gateway = _FakeMealLogGateway();
      await expectLater(
        () => _repository(gateway: gateway).readById('  '),
        throwsArgumentError,
      );
      expect(gateway.readCalls, isEmpty);
    });
  });
}

SupabaseMealLogRepository _repository({
  required _FakeMealLogGateway gateway,
  String? userId = 'user-1',
  MealCategoriesRepository? mealCategoriesRepository,
}) {
  return SupabaseMealLogRepository(
    client: _UnusedSupabaseClient(),
    mealCategoriesRepository:
        mealCategoriesRepository ?? InMemoryMealCategoriesRepository(),
    gateway: gateway,
    currentUserId: () => userId,
  );
}

ManualMealLogCreate _input({
  String clientMutationId = _mutation1,
  String mealCategoryId = 'meal_slot_2',
  String? mealName,
  String? note,
  MealLogCaptureSource? captureSource,
}) {
  return ManualMealLogCreate(
    clientMutationId: clientMutationId,
    mealCategoryId: mealCategoryId,
    mealName: mealName,
    note: note,
    consumedAt: DateTime.utc(2026, 9, 11, 7, 30),
    consumedLocalDate: MealLogLocalDate(year: 2026, month: 9, day: 11),
    consumedTimezoneId: 'Asia/Kolkata',
    consumedUtcOffsetMinutes: 330,
    captureSource: captureSource,
    manualNutritionSnapshot: NutritionSnapshot(
      schemaVersion: 1,
      nutrients: {
        NutrientId.energy: 420,
        NutrientId.protein: 30,
      },
    ),
  );
}

Map<String, dynamic> _row({
  String id = 'row-1',
  String userId = 'user-1',
  String mode = 'manual',
  String mealCategoryId = 'meal_slot_2',
  String? mealName,
  String? note,
  String? timezoneId = 'Asia/Kolkata',
  int? offsetMinutes = 330,
  String? captureSource,
  Map<String, Object?>? snapshot,
  String consumedAt = '2026-09-11T07:30:00.000Z',
  String localDate = '2026-09-11',
  String createdAt = '2026-09-11T10:00:00.000Z',
  String updatedAt = '2026-09-11T10:00:00.000Z',
  String? clientMutationId,
}) {
  return <String, dynamic>{
    'id': id,
    'user_id': userId,
    'mode': mode,
    'meal_category_id': mealCategoryId,
    'meal_name': mealName,
    'note': note,
    'consumed_at': consumedAt,
    'consumed_local_date': localDate,
    'consumed_timezone_id': timezoneId,
    'consumed_utc_offset_minutes': offsetMinutes,
    'capture_source': captureSource,
    'manual_nutrition_snapshot': snapshot ??
        <String, Object?>{
          'schemaVersion': 1,
          'nutrients': <String, Object?>{
            'energy': 420,
            'protein': 30,
          },
        },
    'created_at': createdAt,
    'updated_at': updatedAt,
    'client_mutation_id': clientMutationId,
  };
}

class _UnusedSupabaseClient extends Fake implements SupabaseClient {}

class _FakeMealLogGateway implements MealLogTableGateway {
  _FakeMealLogGateway({
    this.insertResult,
    this.insertError,
    this.readResult,
    List<Object?> mutationReadSequence = const [],
    List<Map<String, dynamic>> localDateReadResults = const [],
  })  : _mutationReadSequence = List<Object?>.from(mutationReadSequence),
        _localDateReadResults = [
          for (final row in localDateReadResults) Map<String, dynamic>.from(row),
        ];

  final Map<String, dynamic>? insertResult;
  final Object? insertError;
  final Map<String, dynamic>? readResult;
  final List<Object?> _mutationReadSequence;
  final List<Map<String, dynamic>> _localDateReadResults;
  final List<Map<String, dynamic>> insertPayloads = [];
  final List<(String, String)> readCalls = [];
  final List<(String, String)> mutationReadCalls = [];
  final List<(String, String)> localDateReadCalls = [];

  @override
  Future<Map<String, dynamic>> insertRow(Map<String, dynamic> payload) async {
    insertPayloads.add(Map<String, dynamic>.from(payload));
    final error = insertError;
    if (error != null) throw error;
    final result = insertResult;
    if (result == null) throw StateError('No insert result configured.');
    return Map<String, dynamic>.from(result);
  }

  @override
  Future<Map<String, dynamic>?> readRow({
    required String userId,
    required String id,
  }) async {
    readCalls.add((userId, id));
    final result = readResult;
    return result == null ? null : Map<String, dynamic>.from(result);
  }

  @override
  Future<Map<String, dynamic>?> readRowByClientMutationId({
    required String userId,
    required String clientMutationId,
  }) async {
    mutationReadCalls.add((userId, clientMutationId));
    if (_mutationReadSequence.isEmpty) return null;

    final next = _mutationReadSequence.removeAt(0);
    if (next == null) return null;
    if (next is Map<String, dynamic>) {
      return Map<String, dynamic>.from(next);
    }
    throw next;
  }

  @override
  Future<List<Map<String, dynamic>>> listRowsByLocalDate({
    required String userId,
    required String localDate,
  }) async {
    localDateReadCalls.add((userId, localDate));
    return [
      for (final row in _localDateReadResults) Map<String, dynamic>.from(row),
    ];
  }
}
