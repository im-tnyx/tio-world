import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tio_feature_nutrition/nutrition.dart';
import 'package:tio_shared/shared.dart';

/// Persistence boundary for Additional Nutrient Goals.
///
/// ## Why this is a gateway-payload test rather than a live PostgREST test
///
/// The TNYX-141 contract asks for a local PostgREST/Supabase integration proof
/// that an old-client core-target write preserves `additional_nutrient_goals`.
/// That is not executable here: Docker is not installed, the Supabase CLI is
/// not on PATH, and `npx supabase` would require a network download. Rather
/// than fake it with a mapper-only assertion, these tests pin the half of the
/// contract that actually lives in this repository — the exact payload sent to
/// PostgREST.
///
/// That is a real guarantee, because PostgREST's upsert compiles to
/// `INSERT ... ON CONFLICT (user_id) DO UPDATE SET <payload columns>`: a column
/// absent from the payload is never written, and one present with an explicit
/// null is written as null. So "core-five payload omits the key" and
/// "additional-goals payload carries only its own column" together decide the
/// preservation behaviour. The remaining half is documented PostgreSQL
/// semantics, and is listed as a deployment-gate verification item.
void main() {
  const coreTargets = NutritionTargetsData(
    caloriesKcal: 2000,
    proteinGrams: 150,
    carbohydrateGrams: 200,
    fatGrams: 55.6,
    fiberGrams: 28,
    customizationState: NutritionTargetCustomizationState.custom,
    customizedFields: {'calories', 'protein'},
    recommendationMetadata: {'source': 'onboarding', 'tdee': 2100},
  );

  group('core-five write preserves Additional Nutrient Goals', () {
    test('the upsert payload omits additional_nutrient_goals entirely',
        () async {
      final gateway = _FakeTargetsGateway();
      final repository = _repository(gateway: gateway);

      await repository.upsert(coreTargets);

      final payload = gateway.upsertPayloads.single;
      expect(
        payload.containsKey('additional_nutrient_goals'),
        isFalse,
        reason: 'An omitted column is left untouched by ON CONFLICT DO UPDATE. '
            'Sending an explicit null here would erase a newer client\'s goals.',
      );
      expect(payload.containsKey('additional_nutrient_goals'), isFalse);
    });

    test('it still writes every core-five column and its provenance', () async {
      final gateway = _FakeTargetsGateway();
      final repository = _repository(gateway: gateway);

      await repository.upsert(coreTargets);

      final payload = gateway.upsertPayloads.single;
      expect(payload['calories_kcal'], 2000);
      expect(payload['protein_grams'], 150);
      expect(payload['carbohydrate_grams'], 200);
      expect(payload['fat_grams'], 55.6);
      expect(payload['fiber_grams'], 28);
      expect(payload['customization_state'], 'custom');
      expect(
          payload['customized_fields'], containsAll(['calories', 'protein']));
      expect(payload['recommendation_metadata'], {
        'source': 'onboarding',
        'tdee': 2100,
      });
    });

    test('a goal-carrying row survives an old-client-shaped core write',
        () async {
      // The row already holds goals written by a newer client.
      final gateway = _FakeTargetsGateway(
        readResult: {
          'calories_kcal': 2000,
          'protein_grams': 150,
          'carbohydrate_grams': 200,
          'fat_grams': 55.6,
          'fiber_grams': 28,
          'customization_state': 'custom',
          'customized_fields': ['calories'],
          'recommendation_metadata': <String, Object?>{},
          'additional_nutrient_goals': {
            'schema_version': 1,
            'goals': {
              'sodium': {'custom_value': 1500},
            },
          },
        },
      );
      final repository = _repository(gateway: gateway);

      final before = await repository.read();
      expect(
          before!.additionalNutrientGoals.contains(NutrientId.sodium), isTrue);

      await repository.upsert(coreTargets);

      // The write carries no opinion about the column, so the stored value
      // cannot be replaced or cleared by it.
      expect(
        gateway.upsertPayloads.single.keys,
        isNot(contains('additional_nutrient_goals')),
      );
    });
  });

  group('Additional Nutrient Goals write preserves the core five', () {
    test('the payload carries only the user key and its own column', () async {
      final gateway = _FakeTargetsGateway(readResult: {
        'additional_nutrient_goals': null,
      });
      final repository = _repository(gateway: gateway);

      await repository.updateAdditionalNutrientGoal(
        NutrientId.sodium,
        const AdditionalNutrientGoal(nutrientId: NutrientId.sodium, customValue: 1500),
      );

      final payload = gateway.upsertPayloads.single;
      expect(payload.keys.toSet(), {'user_id', 'additional_nutrient_goals'});
      for (final coreColumn in [
        'calories_kcal',
        'protein_grams',
        'carbohydrate_grams',
        'fat_grams',
        'fiber_grams',
        'customization_state',
        'customized_fields',
        'recommendation_metadata',
      ]) {
        expect(
          payload.containsKey(coreColumn),
          isFalse,
          reason: '$coreColumn must be left untouched by a goals-only write.',
        );
      }
    });

    test('it re-reads before merging so concurrent unknown data is not lost',
        () async {
      final gateway = _FakeTargetsGateway(readResult: {
        'additional_nutrient_goals': {
          'schema_version': 1,
          'written_by': 'newer-client',
          'goals': {
            'added_sugar': {'custom_value': 25},
          },
        },
      });
      final repository = _repository(gateway: gateway);

      await repository.updateAdditionalNutrientGoal(
        NutrientId.vitaminD,
        const AdditionalNutrientGoal(nutrientId: NutrientId.vitaminD),
      );

      expect(
        gateway.readUserIds,
        isNotEmpty,
        reason: 'A merge must start from current stored state, not stale UI.',
      );
      final written = gateway.upsertPayloads.single['additional_nutrient_goals']
          as Map<String, Object?>;
      expect(written['written_by'], 'newer-client');
      expect(
        (written['goals']! as Map)['added_sugar'],
        {'custom_value': 25},
      );
      expect(
        (written['goals']! as Map)['vitamin_d'],
        {'custom_value': null},
      );
    });

    test('it refuses to overwrite an unsupported future schema', () async {
      final gateway = _FakeTargetsGateway(readResult: {
        'additional_nutrient_goals': {
          'schema_version': 2,
          'goals': <String, Object?>{},
        },
      });
      final repository = _repository(gateway: gateway);

      await expectLater(
        () => repository.updateAdditionalNutrientGoal(
          NutrientId.sodium,
          const AdditionalNutrientGoal(nutrientId: NutrientId.sodium),
        ),
        throwsStateError,
      );
      expect(
        gateway.upsertPayloads,
        isEmpty,
        reason: 'Nothing may be written when the stored schema is newer.',
      );
    });

    test('a signed-out write fails closed before touching the gateway',
        () async {
      final gateway = _FakeTargetsGateway();
      final repository = _repository(gateway: gateway, userId: null);

      await expectLater(
        () => repository.updateAdditionalNutrientGoal(
          NutrientId.sodium,
          const AdditionalNutrientGoal(nutrientId: NutrientId.sodium),
        ),
        throwsStateError,
      );
      expect(gateway.readUserIds, isEmpty);
      expect(gateway.upsertPayloads, isEmpty);
    });
  });

  group('concurrent edits from another client are never lost', () {
    // The screen holds a snapshot of the goal set from whenever it loaded.
    // The bug class this group pins is a full-set replacement: re-reading
    // before the write does not fix it, because the stale snapshot still
    // says "absent" for a nutrient another client has since configured, and
    // an absent authorized key means "delete this nutrient".
    const staleSnapshot = AdditionalNutrientGoalSet.empty();

    Map<String, dynamic> rowWithSodium() => {
          'additional_nutrient_goals': {
            'schema_version': 1,
            'goals': {
              'sodium': {'custom_value': 1500},
            },
          },
        };

    Map<String, Object?> goalsOf(_FakeTargetsGateway gateway) =>
        ((gateway.upsertPayloads.single['additional_nutrient_goals']
                as Map<String, Object?>)['goals']! as Map)
            .cast<String, Object?>();

    test('Sodium added by another client survives a local Vitamin D enable',
        () async {
      expect(
        staleSnapshot.contains(NutrientId.sodium),
        isFalse,
        reason: 'The screen loaded before the other client wrote Sodium.',
      );
      final gateway = _FakeTargetsGateway(readResult: rowWithSodium());
      final repository = _repository(gateway: gateway);

      await repository.updateAdditionalNutrientGoal(
        NutrientId.vitaminD,
        const AdditionalNutrientGoal(nutrientId: NutrientId.vitaminD),
      );

      final goals = goalsOf(gateway);
      expect(
        goals['sodium'],
        {'custom_value': 1500},
        reason: 'Editing Vitamin D must not touch Sodium.',
      );
      expect(goals['vitamin_d'], {'custom_value': null});
    });

    test('Sodium added by another client survives a local Vitamin D disable',
        () async {
      final gateway = _FakeTargetsGateway(readResult: {
        'additional_nutrient_goals': {
          'schema_version': 1,
          'goals': {
            'sodium': {'custom_value': 1500},
            'vitamin_d': {'custom_value': 18},
          },
        },
      });
      final repository = _repository(gateway: gateway);

      await repository.updateAdditionalNutrientGoal(NutrientId.vitaminD, null);

      final goals = goalsOf(gateway);
      expect(goals.containsKey('vitamin_d'), isFalse);
      expect(
        goals['sodium'],
        {'custom_value': 1500},
        reason: 'Turning one nutrient off is not a set replacement.',
      );
    });

    test('a local Sodium edit changes Sodium and nothing else', () async {
      final gateway = _FakeTargetsGateway(readResult: {
        'additional_nutrient_goals': {
          'schema_version': 1,
          'goals': {
            'sodium': {'custom_value': 1500},
            'vitamin_d': {'custom_value': 18},
            'saturated_fat': {'custom_value': null},
          },
        },
      });
      final repository = _repository(gateway: gateway);

      await repository.updateAdditionalNutrientGoal(
        NutrientId.sodium,
        const AdditionalNutrientGoal(
          nutrientId: NutrientId.sodium,
          customValue: 1200,
        ),
      );

      final goals = goalsOf(gateway);
      expect((goals['sodium']! as Map)['custom_value'], 1200);
      expect(goals['vitamin_d'], {'custom_value': 18});
      expect(goals['saturated_fat'], {'custom_value': null});
    });

    test('a local Sodium removal removes Sodium and nothing else', () async {
      final gateway = _FakeTargetsGateway(readResult: {
        'additional_nutrient_goals': {
          'schema_version': 1,
          'goals': {
            'sodium': {'custom_value': 1500},
            'vitamin_d': {'custom_value': 18},
          },
        },
      });
      final repository = _repository(gateway: gateway);

      await repository.updateAdditionalNutrientGoal(NutrientId.sodium, null);

      final goals = goalsOf(gateway);
      expect(goals.containsKey('sodium'), isFalse);
      expect(goals['vitamin_d'], {'custom_value': 18});
    });

    test('the in-memory repository loses nothing either', () async {
      // Test doubles that replace the whole set would let the production
      // regression pass unnoticed in every screen-level test.
      final repository = InMemoryNutritionTargetsRepository();
      await repository.upsert(const NutritionTargetsData(
        additionalNutrientGoals: AdditionalNutrientGoalSet.empty(),
      ));
      await repository.updateAdditionalNutrientGoal(
        NutrientId.sodium,
        const AdditionalNutrientGoal(
          nutrientId: NutrientId.sodium,
          customValue: 1500,
        ),
      );

      await repository.updateAdditionalNutrientGoal(
        NutrientId.vitaminD,
        const AdditionalNutrientGoal(nutrientId: NutrientId.vitaminD),
      );

      final goals = (await repository.read())!.additionalNutrientGoals;
      expect(goals[NutrientId.sodium]!.customValue, 1500);
      expect(goals.contains(NutrientId.vitaminD), isTrue);
    });
  });

  group('read', () {
    test('a null column reads as no configured goals', () async {
      final repository = _repository(
        gateway: _FakeTargetsGateway(readResult: {
          'calories_kcal': 2000,
          'customization_state': 'recommended',
          'customized_fields': <dynamic>[],
          'recommendation_metadata': <String, Object?>{},
          'additional_nutrient_goals': null,
        }),
      );

      final data = await repository.read();

      expect(data!.additionalNutrientGoals.isEmpty, isTrue);
      expect(data.additionalNutrientGoals.isWritable, isTrue);
    });

    test('an explicit zero override survives the read', () async {
      final repository = _repository(
        gateway: _FakeTargetsGateway(readResult: {
          'calories_kcal': 2000,
          'customization_state': 'recommended',
          'customized_fields': <dynamic>[],
          'recommendation_metadata': <String, Object?>{},
          'additional_nutrient_goals': {
            'schema_version': 1,
            'goals': {
              'trans_fat': {'custom_value': 0},
            },
          },
        }),
      );

      final data = await repository.read();

      expect(
          data!.additionalNutrientGoals[NutrientId.transFat]!.customValue, 0);
    });

    test('core-five values and provenance are unaffected by the new column',
        () async {
      final repository = _repository(
        gateway: _FakeTargetsGateway(readResult: {
          'calories_kcal': 2000,
          'protein_grams': 150,
          'carbohydrate_grams': 200,
          'fat_grams': 55.6,
          'fiber_grams': 28,
          'customization_state': 'custom',
          'customized_fields': ['calories'],
          'recommendation_metadata': {'source': 'onboarding'},
          'additional_nutrient_goals': {
            'schema_version': 1,
            'goals': {
              'sodium': {'custom_value': 1500},
            },
          },
        }),
      );

      final data = await repository.read();

      expect(data!.caloriesKcal, 2000);
      expect(data.proteinGrams, 150);
      expect(data.customizationState, NutritionTargetCustomizationState.custom);
      expect(data.customizedFields, {'calories'});
      expect(data.recommendationMetadata, {'source': 'onboarding'});
    });
  });

  test('customizedFields vocabulary stays core-five only', () async {
    final gateway = _FakeTargetsGateway();
    final repository = _repository(gateway: gateway);

    await repository.upsert(coreTargets);

    final customizedFields =
        (gateway.upsertPayloads.single['customized_fields']! as Iterable)
            .cast<String>()
            .toSet();
    for (final nutrientId in AdditionalNutrientGoalSet.authorizedNutrients) {
      expect(
        customizedFields,
        isNot(contains(nutrientId.storageValue)),
        reason: 'Additional Nutrient IDs never enter core-five provenance.',
      );
    }
  });
}

SupabaseNutritionTargetsRepository _repository({
  required NutritionTargetsTableGateway gateway,
  String? userId = 'user-1',
}) =>
    SupabaseNutritionTargetsRepository(
      client: SupabaseClient('https://example.invalid', 'anon-key'),
      gateway: gateway,
      currentUserId: () => userId,
    );

class _FakeTargetsGateway implements NutritionTargetsTableGateway {
  _FakeTargetsGateway({this.readResult});

  final Map<String, dynamic>? readResult;
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
  }
}
