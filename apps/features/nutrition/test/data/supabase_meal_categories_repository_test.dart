import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tio_feature_nutrition/nutrition.dart';

void main() {
  group('SupabaseMealCategoriesRepository reads', () {
    test('signed-out read resolves defaults without gateway access', () async {
      final gateway = _FakeMealCategoriesGateway();
      final repository = _repository(gateway: gateway, userId: null);

      expect(await repository.read(), MealCategoriesConfig.canonicalDefaults());
      expect(gateway.readUserIds, isEmpty);
      expect(gateway.upsertPayloads, isEmpty);
    });

    test('missing owner row and SQL NULL resolve canonical defaults', () async {
      for (final row in <Map<String, dynamic>?>[
        null,
        <String, dynamic>{'meal_categories_config': null},
      ]) {
        final gateway = _FakeMealCategoriesGateway(readResult: row);

        expect(
          await _repository(gateway: gateway).read(),
          MealCategoriesConfig.canonicalDefaults(),
        );
        expect(gateway.readUserIds, ['user-1']);
      }
    });

    test('valid persisted V1 config decodes through the strict codec',
        () async {
      final expected = _customizedConfig(active: false);
      final gateway = _FakeMealCategoriesGateway(
        readResult: {
          'meal_categories_config': MealCategoriesConfigCodec.encode(expected),
        },
      );

      expect(await _repository(gateway: gateway).read(), expected);
    });

    test('malformed non-null config fails closed instead of defaulting',
        () async {
      final gateway = _FakeMealCategoriesGateway(
        readResult: {'meal_categories_config': 'malformed'},
      );

      await expectLater(
        _repository(gateway: gateway).read(),
        _throwsCode(MealCategoriesValidationCode.malformedConfig),
      );
    });

    test('unsupported future schema fails closed instead of defaulting',
        () async {
      final raw = MealCategoriesConfigCodec.encode(
        MealCategoriesConfig.canonicalDefaults(),
      )..['schema_version'] = 2;
      final gateway = _FakeMealCategoriesGateway(
        readResult: {'meal_categories_config': raw},
      );

      await expectLater(
        _repository(gateway: gateway).read(),
        _throwsCode(MealCategoriesValidationCode.unsupportedSchemaVersion),
      );
    });

    test('selected rows missing the owned column fail closed', () async {
      final gateway = _FakeMealCategoriesGateway(readResult: {});

      await expectLater(
        _repository(gateway: gateway).read(),
        throwsFormatException,
      );
    });
  });

  group('SupabaseMealCategoriesRepository writes', () {
    test('signed-out write fails before gateway mutation', () async {
      final gateway = _FakeMealCategoriesGateway();
      final repository = _repository(gateway: gateway, userId: '  ');

      await expectLater(
        () => repository.upsert(MealCategoriesConfig.canonicalDefaults()),
        throwsStateError,
      );
      expect(gateway.readUserIds, isEmpty);
      expect(gateway.upsertPayloads, isEmpty);
    });

    test('writes only current user_id and codec-encoded config', () async {
      final gateway = _FakeMealCategoriesGateway();
      final config = _customizedConfig(active: true);

      await _repository(gateway: gateway, userId: ' user-1 ').upsert(config);

      expect(gateway.readUserIds, isEmpty);
      expect(gateway.upsertPayloads, hasLength(1));
      final payload = gateway.upsertPayloads.single;
      expect(payload.keys, {'user_id', 'meal_categories_config'});
      expect(payload['user_id'], 'user-1');
      expect(
        payload['meal_categories_config'],
        MealCategoriesConfigCodec.encode(config),
      );
      expect(payload, isNot(contains('preferred_diet')));
      expect(payload, isNot(contains('allergies')));
      expect(payload, isNot(contains('disliked_foods')));
      expect(payload, isNot(contains('medical_conditions')));
      expect(payload, isNot(contains('other_diet_type')));
      expect(payload, isNot(contains('other_allergy_restriction')));
      expect(payload, isNot(contains('updated_at')));
    });

    test('first customization does not fabricate profile values', () async {
      final gateway = _FakeMealCategoriesGateway(readResult: null);
      final config = _customizedConfig(active: false);

      await _repository(gateway: gateway).upsert(config);

      expect(gateway.readUserIds, isEmpty);
      expect(gateway.upsertPayloads.single, {
        'user_id': 'user-1',
        'meal_categories_config': MealCategoriesConfigCodec.encode(config),
      });
    });

    test('archived retained identity remains in the encoded payload', () async {
      final gateway = _FakeMealCategoriesGateway();
      final config = _customizedConfig(active: false);

      await _repository(gateway: gateway).upsert(config);

      final encoded = gateway.upsertPayloads.single['meal_categories_config']!
          as Map<String, Object?>;
      final items = encoded['items']! as List<Object?>;
      expect(
        items,
        contains(
          containsPair(
            'id',
            'meal_slot_00000000-0000-4000-8000-000000000001',
          ),
        ),
      );
      expect(
        items.cast<Map<String, Object?>>().singleWhere(
              (item) =>
                  item['id'] ==
                  'meal_slot_00000000-0000-4000-8000-000000000001',
            )['active'],
        isFalse,
      );
    });

    test('ninth active category is rejected before gateway access', () {
      final gateway = _FakeMealCategoriesGateway();

      expect(
        () => MealCategoriesConfig(
          items: [
            ...MealCategoriesConfig.canonicalDefaults().items,
            for (var index = 0; index < 5; index++)
              MealCategory(
                id: 'meal_slot_00000000-0000-4000-8000-${(index + 1).toString().padLeft(12, '0')}',
                defaultKey: null,
                displayName: 'Custom ${index + 1}',
                active: true,
                order: index + 4,
              ),
          ],
        ),
        _throwsCode(MealCategoriesValidationCode.tooManyActiveCategories),
      );
      expect(gateway.upsertPayloads, isEmpty);
    });

    test('retained-ID database rejection propagates without fallback write',
        () async {
      final rejection = StateError('retained Meal Category identity removed');
      final gateway = _FakeMealCategoriesGateway(upsertError: rejection);

      await expectLater(
        () => _repository(gateway: gateway)
            .upsert(MealCategoriesConfig.canonicalDefaults()),
        throwsA(same(rejection)),
      );
      expect(gateway.upsertPayloads, hasLength(1));
      expect(gateway.readUserIds, isEmpty);
    });

    test('gateway failure propagates with no retry or fallback overwrite',
        () async {
      final failure = Exception('network/database failure');
      final gateway = _FakeMealCategoriesGateway(upsertError: failure);

      await expectLater(
        () => _repository(gateway: gateway)
            .upsert(MealCategoriesConfig.canonicalDefaults()),
        throwsA(same(failure)),
      );
      expect(gateway.upsertPayloads, hasLength(1));
    });
  });
}

SupabaseMealCategoriesRepository _repository({
  required _FakeMealCategoriesGateway gateway,
  String? userId = 'user-1',
}) {
  return SupabaseMealCategoriesRepository(
    client: _UnusedSupabaseClient(),
    gateway: gateway,
    currentUserId: () => userId,
  );
}

MealCategoriesConfig _customizedConfig({required bool active}) {
  return MealCategoriesConfig(
    items: [
      ...MealCategoriesConfig.canonicalDefaults().items,
      MealCategory(
        id: 'meal_slot_00000000-0000-4000-8000-000000000001',
        defaultKey: null,
        displayName: 'Pre Workout',
        active: active,
        order: 4,
      ),
    ],
  );
}

Matcher _throwsCode(MealCategoriesValidationCode code) => throwsA(
      isA<MealCategoriesValidationException>()
          .having((error) => error.code, 'code', code),
    );

class _UnusedSupabaseClient extends Fake implements SupabaseClient {}

class _FakeMealCategoriesGateway implements MealCategoriesTableGateway {
  _FakeMealCategoriesGateway({this.readResult, this.upsertError});

  final Map<String, dynamic>? readResult;
  final Object? upsertError;
  final List<String> readUserIds = [];
  final List<Map<String, dynamic>> upsertPayloads = [];

  @override
  Future<Map<String, dynamic>?> readRow(String userId) async {
    readUserIds.add(userId);
    return readResult;
  }

  @override
  Future<void> upsertRow(Map<String, dynamic> payload) async {
    upsertPayloads.add(Map<String, dynamic>.from(payload));
    final error = upsertError;
    if (error != null) throw error;
  }
}
