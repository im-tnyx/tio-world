import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tio_feature_nutrition/nutrition.dart';
import 'package:tio_shared/shared.dart';

const _mutation = '11111111-1111-4111-8111-111111111111';

void main() {
  test('in-memory create retry fails closed after later edit changes facts',
      () async {
    final repository = InMemoryMealLogRepository(
      mealCategoriesRepository: InMemoryMealCategoriesRepository(),
    );
    final create = _createInput();
    final created = await repository.createManual(create);
    await repository.updateManual(
      ManualMealLogUpdate(
        id: created.id,
        expectedRevision: created.revision,
        mealCategoryId: created.mealCategoryId,
        mealName: 'Edited after create',
        consumedAt: created.consumedAt,
        consumedLocalDate: created.consumedLocalDate,
        consumedUtcOffsetMinutes: created.consumedUtcOffsetMinutes,
        manualNutritionSnapshot: created.manualNutritionSnapshot!,
      ),
    );

    await expectLater(
      () => repository.createManual(create),
      throwsA(isA<MealLogCreateMutationConflict>()),
    );
  });

  test('Supabase create retry fails closed after later edit changes facts',
      () async {
    final gateway = _CreateRetryGateway(
      mutationRow: _row(revision: 2, mealName: 'Edited after create'),
    );
    final repository = _repository(gateway);

    await expectLater(
      () => repository.createManual(_createInput()),
      throwsA(isA<MealLogCreateMutationConflict>()),
    );
    expect(gateway.insertCalls, 0);
  });

  test('revision 2 same mutation plus different create facts stays conflict',
      () async {
    final gateway = _CreateRetryGateway(
      mutationRow: _row(
        revision: 2,
        mealName: 'Existing edited meal',
        captureSource: 'quick_add',
      ),
    );
    final repository = _repository(gateway);

    await expectLater(
      () => repository.createManual(
        _createInput(
          mealName: 'Different logical create',
          energy: 700,
          consumedAt: DateTime.utc(2026, 9, 12, 8),
        ),
      ),
      throwsA(isA<MealLogCreateMutationConflict>()),
    );
    expect(gateway.insertCalls, 0);
  });

  test('revision 2 row may reconcile when current facts still exactly match',
      () async {
    final gateway = _CreateRetryGateway(
      mutationRow: _row(
        revision: 2,
        mealName: 'Original create',
        consumedAt: '2026-09-12T06:30:00.000Z',
        energy: 500,
      ),
    );
    final repository = _repository(gateway);

    final retry = await repository.createManual(_createInput());

    expect(retry.revision, 2);
    expect(retry.mealName, 'Original create');
    expect(gateway.insertCalls, 0);
  });

  test('edited same-mutation row rejects capture provenance mismatch', () async {
    final gateway = _CreateRetryGateway(
      mutationRow: _row(
        revision: 2,
        mealName: 'Original create',
        consumedAt: '2026-09-12T06:30:00.000Z',
        energy: 500,
        captureSource: 'text',
      ),
    );
    final repository = _repository(gateway);

    await expectLater(
      () => repository.createManual(_createInput()),
      throwsA(isA<MealLogCreateMutationConflict>()),
    );
    expect(gateway.insertCalls, 0);
  });
}

SupabaseMealLogRepository _repository(_CreateRetryGateway gateway) {
  return SupabaseMealLogRepository(
    client: _UnusedSupabaseClient(),
    mealCategoriesRepository: InMemoryMealCategoriesRepository(),
    gateway: gateway,
    currentUserId: () => 'user-1',
  );
}

ManualMealLogCreate _createInput({
  String mealName = 'Original create',
  num energy = 500,
  DateTime? consumedAt,
}) {
  return ManualMealLogCreate(
    clientMutationId: _mutation,
    mealCategoryId: 'meal_slot_1',
    mealName: mealName,
    consumedAt: consumedAt ?? DateTime.utc(2026, 9, 12, 6, 30),
    consumedLocalDate: MealLogLocalDate(year: 2026, month: 9, day: 12),
    consumedUtcOffsetMinutes: 330,
    captureSource: MealLogCaptureSource.quickAdd,
    manualNutritionSnapshot: NutritionSnapshot(
      schemaVersion: 1,
      nutrients: {NutrientId.energy: energy},
    ),
  );
}

Map<String, dynamic> _row({
  required int revision,
  required String mealName,
  String captureSource = 'quick_add',
  String consumedAt = '2026-09-12T07:00:00.000Z',
  num energy = 510,
}) {
  return <String, dynamic>{
    'id': 'row-1',
    'user_id': 'user-1',
    'mode': 'manual',
    'meal_category_id': 'meal_slot_1',
    'meal_name': mealName,
    'note': null,
    'consumed_at': consumedAt,
    'consumed_local_date': '2026-09-12',
    'consumed_timezone_id': null,
    'consumed_utc_offset_minutes': 330,
    'capture_source': captureSource,
    'manual_nutrition_snapshot': <String, Object?>{
      'schemaVersion': 1,
      'nutrients': <String, Object?>{'energy': energy},
    },
    'created_at': '2026-09-12T08:00:00.000Z',
    'updated_at': '2026-09-12T09:00:00.000Z',
    'client_mutation_id': _mutation,
    'revision': revision,
  };
}

class _UnusedSupabaseClient extends Fake implements SupabaseClient {}

class _CreateRetryGateway implements MealLogTableGateway {
  _CreateRetryGateway({required this.mutationRow});

  final Map<String, dynamic> mutationRow;
  var insertCalls = 0;

  @override
  Future<Map<String, dynamic>> insertRow(Map<String, dynamic> payload) {
    insertCalls += 1;
    throw StateError('create retry must not insert');
  }

  @override
  Future<Map<String, dynamic>?> updateRow({
    required String userId,
    required String id,
    required int expectedRevision,
    required Map<String, dynamic> payload,
  }) {
    throw UnsupportedError('update is not used in this suite');
  }

  @override
  Future<Map<String, dynamic>?> readRow({
    required String userId,
    required String id,
  }) {
    throw UnsupportedError('readById is not used in this suite');
  }

  @override
  Future<Map<String, dynamic>?> readRowByClientMutationId({
    required String userId,
    required String clientMutationId,
  }) async {
    return Map<String, dynamic>.from(mutationRow);
  }

  @override
  Future<List<Map<String, dynamic>>> listRowsByLocalDate({
    required String userId,
    required String localDate,
  }) {
    throw UnsupportedError('history reads are not used in this suite');
  }
}
