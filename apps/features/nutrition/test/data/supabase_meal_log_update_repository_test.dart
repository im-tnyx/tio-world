import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tio_feature_nutrition/nutrition.dart';
import 'package:tio_shared/shared.dart';

const _mutation = '11111111-1111-4111-8111-111111111111';

void main() {
  test('conditional update writes only editable facts and returns revision + 1',
      () async {
    final before = _row(revision: 1, mealName: 'Lunch');
    final after = _row(
      revision: 2,
      mealName: 'Updated lunch',
      note: 'Less oil',
      consumedAt: '2026-09-12T07:00:00.000Z',
      snapshot: _updatedSnapshot,
      updatedAt: '2026-09-12T09:00:00.000Z',
    );
    final gateway = _UpdateGateway(
      readSequence: [before],
      updateResult: after,
    );
    final repository = _repository(gateway: gateway);

    final updated = await repository.updateManual(
      _updateInput(mealName: 'Updated lunch', note: 'Less oil'),
    );

    expect(gateway.updateCalls.single, ('user-1', 'row-1', 1));
    final payload = gateway.updatePayloads.single;
    expect(payload.keys, {
      'meal_category_id',
      'meal_name',
      'note',
      'consumed_at',
      'consumed_local_date',
      'consumed_timezone_id',
      'consumed_utc_offset_minutes',
      'manual_nutrition_snapshot',
    });
    expect(payload, isNot(contains('id')));
    expect(payload, isNot(contains('user_id')));
    expect(payload, isNot(contains('mode')));
    expect(payload, isNot(contains('capture_source')));
    expect(payload, isNot(contains('client_mutation_id')));
    expect(payload, isNot(contains('created_at')));
    expect(payload, isNot(contains('updated_at')));
    expect(payload, isNot(contains('revision')));

    expect(updated.id, 'row-1');
    expect(updated.revision, 2);
    expect(updated.captureSource, MealLogCaptureSource.quickAdd);
    expect(updated.createdAt, DateTime.utc(2026, 9, 12, 8));
    expect(updated.mealName, 'Updated lunch');
    expect(updated.note, 'Less oil');
  });

  test('stale revision is rejected before conditional update', () async {
    final gateway = _UpdateGateway(
      readSequence: [_row(revision: 2, mealName: 'Winner')],
    );

    await expectLater(
      () => _repository(gateway: gateway).updateManual(_updateInput()),
      throwsA(
        isA<MealLogUpdateConflict>()
            .having((error) => error.expectedRevision, 'expectedRevision', 1)
            .having((error) => error.actualRevision, 'actualRevision', 2),
      ),
    );

    expect(gateway.updateCalls, isEmpty);
  });

  test('conditional no-match reconciles newer row as stale conflict', () async {
    final gateway = _UpdateGateway(
      readSequence: [
        _row(revision: 1),
        _row(revision: 2, mealName: 'Concurrent winner'),
      ],
      updateResult: null,
    );

    await expectLater(
      () => _repository(gateway: gateway).updateManual(_updateInput()),
      throwsA(
        isA<MealLogUpdateConflict>()
            .having((error) => error.actualRevision, 'actualRevision', 2),
      ),
    );

    expect(gateway.updateCalls, hasLength(1));
    expect(gateway.readCalls, hasLength(2));
  });

  test('response loss reconciles exact committed update', () async {
    final gateway = _UpdateGateway(
      readSequence: [
        _row(revision: 1),
        _row(
          revision: 2,
          mealName: 'Updated lunch',
          note: 'Less oil',
          consumedAt: '2026-09-12T07:00:00.000Z',
          snapshot: _updatedSnapshot,
          updatedAt: '2026-09-12T09:00:00.000Z',
        ),
      ],
      updateError: StateError('response lost'),
    );

    final updated = await _repository(gateway: gateway).updateManual(
      _updateInput(mealName: 'Updated lunch', note: 'Less oil'),
    );

    expect(updated.revision, 2);
    expect(updated.mealName, 'Updated lunch');
    expect(gateway.updateCalls, hasLength(1));
  });

  test('unreadable response-loss outcome stays unknown for exact operation',
      () async {
    final gateway = _UpdateGateway(
      readSequence: [
        _row(revision: 1),
        StateError('offline during reconciliation'),
      ],
      updateError: StateError('response lost'),
    );

    await expectLater(
      () => _repository(gateway: gateway).updateManual(_updateInput()),
      throwsA(
        isA<MealLogUpdateOutcomeUnknown>()
            .having((error) => error.id, 'id', 'row-1')
            .having((error) => error.expectedRevision, 'expectedRevision', 1),
      ),
    );
  });

  test('same-input retry after outcome unknown reconciles canonical N+1',
      () async {
    final intended = _updateInput(mealName: 'Updated lunch', note: 'Less oil');
    final gateway = _UpdateGateway(
      readSequence: [
        _row(revision: 1),
        StateError('offline during reconciliation'),
        _row(
          revision: 2,
          mealName: 'Updated lunch',
          note: 'Less oil',
          consumedAt: '2026-09-12T07:00:00.000Z',
          snapshot: _updatedSnapshot,
          updatedAt: '2026-09-12T09:00:00.000Z',
        ),
      ],
      updateError: StateError('response lost'),
    );
    final repository = _repository(gateway: gateway);

    await expectLater(
      () => repository.updateManual(intended),
      throwsA(isA<MealLogUpdateOutcomeUnknown>()),
    );

    final retried = await repository.updateManual(intended);

    expect(retried.revision, 2);
    expect(retried.mealName, 'Updated lunch');
    expect(retried.note, 'Less oil');
    expect(gateway.updateCalls, hasLength(1));
    expect(gateway.readCalls, hasLength(3));
  });

  test('retaining current archived category skips active-category rejection',
      () async {
    final categories = InMemoryMealCategoriesRepository();
    await _archiveCategory(categories, 'meal_slot_1');
    final gateway = _UpdateGateway(
      readSequence: [_row(revision: 1, mealCategoryId: 'meal_slot_1')],
      updateResult: _row(
        revision: 2,
        mealCategoryId: 'meal_slot_1',
        consumedAt: '2026-09-12T07:00:00.000Z',
        snapshot: _updatedSnapshot,
        updatedAt: '2026-09-12T09:00:00.000Z',
      ),
    );

    final updated = await _repository(
      gateway: gateway,
      categories: categories,
    ).updateManual(_updateInput(mealCategoryId: 'meal_slot_1'));

    expect(updated.mealCategoryId, 'meal_slot_1');
    expect(updated.revision, 2);
  });

  test('moving to archived destination is rejected before durable write',
      () async {
    final categories = InMemoryMealCategoriesRepository();
    await _archiveCategory(categories, 'meal_slot_2');
    final gateway = _UpdateGateway(
      readSequence: [_row(revision: 1, mealCategoryId: 'meal_slot_1')],
    );

    await expectLater(
      () => _repository(gateway: gateway, categories: categories).updateManual(
        _updateInput(mealCategoryId: 'meal_slot_2'),
      ),
      throwsArgumentError,
    );

    expect(gateway.updateCalls, isEmpty);
  });

  test('missing target is reported distinctly', () async {
    final gateway = _UpdateGateway(readSequence: [null]);

    await expectLater(
      () => _repository(gateway: gateway).updateManual(_updateInput()),
      throwsA(isA<MealLogUpdateNotFound>()),
    );
    expect(gateway.updateCalls, isEmpty);
  });

  test('update result cannot mutate immutable capture provenance', () async {
    final gateway = _UpdateGateway(
      readSequence: [_row(revision: 1, captureSource: 'quick_add')],
      updateResult: _row(
        revision: 2,
        captureSource: 'text',
        consumedAt: '2026-09-12T07:00:00.000Z',
        snapshot: _updatedSnapshot,
        updatedAt: '2026-09-12T09:00:00.000Z',
      ),
    );

    await expectLater(
      () => _repository(gateway: gateway).updateManual(_updateInput()),
      throwsFormatException,
    );
  });
}

SupabaseMealLogRepository _repository({
  required _UpdateGateway gateway,
  InMemoryMealCategoriesRepository? categories,
}) {
  return SupabaseMealLogRepository(
    client: _UnusedSupabaseClient(),
    mealCategoriesRepository: categories ?? InMemoryMealCategoriesRepository(),
    gateway: gateway,
    currentUserId: () => 'user-1',
  );
}

ManualMealLogUpdate _updateInput({
  String mealCategoryId = 'meal_slot_1',
  String? mealName = 'Lunch',
  String? note,
}) {
  return ManualMealLogUpdate(
    id: 'row-1',
    expectedRevision: 1,
    mealCategoryId: mealCategoryId,
    mealName: mealName,
    note: note,
    consumedAt: DateTime.utc(2026, 9, 12, 7),
    consumedLocalDate: MealLogLocalDate(year: 2026, month: 9, day: 12),
    consumedTimezoneId: 'Asia/Kolkata',
    consumedUtcOffsetMinutes: 330,
    manualNutritionSnapshot: NutritionSnapshot.fromJson(_updatedSnapshot),
  );
}

const _updatedSnapshot = <String, Object?>{
  'schemaVersion': 1,
  'nutrients': <String, Object?>{
    'energy': 510,
    'protein': 26,
  },
};

Map<String, dynamic> _row({
  int revision = 1,
  String id = 'row-1',
  String userId = 'user-1',
  String mode = 'manual',
  String mealCategoryId = 'meal_slot_1',
  String? mealName = 'Lunch',
  String? note,
  String consumedAt = '2026-09-12T06:30:00.000Z',
  String localDate = '2026-09-12',
  String? timezoneId = 'Asia/Kolkata',
  int? offsetMinutes = 330,
  String? captureSource = 'quick_add',
  Map<String, Object?> snapshot = const <String, Object?>{
    'schemaVersion': 1,
    'nutrients': <String, Object?>{
      'energy': 500,
      'protein': 25,
    },
  },
  String createdAt = '2026-09-12T08:00:00.000Z',
  String updatedAt = '2026-09-12T08:00:00.000Z',
  String? clientMutationId = _mutation,
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
    'manual_nutrition_snapshot': snapshot,
    'created_at': createdAt,
    'updated_at': updatedAt,
    'client_mutation_id': clientMutationId,
    'revision': revision,
  };
}

Future<void> _archiveCategory(
  InMemoryMealCategoriesRepository repository,
  String id,
) async {
  final current = await repository.read();
  await repository.upsert(
    MealCategoriesConfig(
      items: current.items.map(
        (item) => item.id == id ? item.withActive(false) : item,
      ),
    ),
  );
}

class _UnusedSupabaseClient extends Fake implements SupabaseClient {}

class _UpdateGateway implements MealLogTableGateway {
  _UpdateGateway({
    List<Object?> readSequence = const [],
    this.updateResult,
    this.updateError,
  }) : _readSequence = List<Object?>.from(readSequence);

  final List<Object?> _readSequence;
  final Map<String, dynamic>? updateResult;
  final Object? updateError;
  final List<(String, String)> readCalls = [];
  final List<(String, String, int)> updateCalls = [];
  final List<Map<String, dynamic>> updatePayloads = [];

  @override
  Future<Map<String, dynamic>> insertRow(Map<String, dynamic> payload) {
    throw UnsupportedError('Insert is not used by update tests.');
  }

  @override
  Future<Map<String, dynamic>?> updateRow({
    required String userId,
    required String id,
    required int expectedRevision,
    required Map<String, dynamic> payload,
  }) async {
    updateCalls.add((userId, id, expectedRevision));
    updatePayloads.add(Map<String, dynamic>.from(payload));
    final error = updateError;
    if (error != null) throw error;
    final result = updateResult;
    return result == null ? null : Map<String, dynamic>.from(result);
  }

  @override
  Future<Map<String, dynamic>?> readRow({
    required String userId,
    required String id,
  }) async {
    readCalls.add((userId, id));
    if (_readSequence.isEmpty) return null;
    final next = _readSequence.removeAt(0);
    if (next == null) return null;
    if (next is Map<String, dynamic>) {
      return Map<String, dynamic>.from(next);
    }
    throw next;
  }

  @override
  Future<Map<String, dynamic>?> readRowByClientMutationId({
    required String userId,
    required String clientMutationId,
  }) {
    throw UnsupportedError('Create reconciliation is not used by update tests.');
  }

  @override
  Future<List<Map<String, dynamic>>> listRowsByLocalDate({
    required String userId,
    required String localDate,
  }) {
    throw UnsupportedError('History reads are not used by update tests.');
  }
}
