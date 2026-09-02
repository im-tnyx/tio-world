import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tio_feature_nutrition/nutrition.dart';
import 'package:tio_shared/shared.dart';

import 'fake_nutrition_targets_table.dart';

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
      final gateway = FakeNutritionTargetsTable();
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
      final gateway = FakeNutritionTargetsTable();
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
      final gateway = FakeNutritionTargetsTable(
        row: {
          'user_id': 'user-1',
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

  group('a goals-only write leaves the core five alone', () {
    test('it writes the goals column and nothing else', () async {
      final table = FakeNutritionTargetsTable(row: {
        'user_id': 'user-1',
        'calories_kcal': 2000,
        'protein_grams': 150,
        'customization_state': 'custom',
        'customized_fields': ['calories'],
        'recommendation_metadata': {'source': 'onboarding'},
        'additional_nutrient_goals': null,
      });
      final repository = _repository(gateway: table);

      await repository.updateAdditionalNutrientGoal(
        NutrientId.sodium,
        const AdditionalNutrientGoal(
          nutrientId: NutrientId.sodium,
          customValue: 1500,
        ),
      );

      final row = table.row!;
      expect(row['calories_kcal'], 2000);
      expect(row['protein_grams'], 150);
      expect(row['customization_state'], 'custom');
      expect(row['customized_fields'], ['calories']);
      expect(row['recommendation_metadata'], {'source': 'onboarding'});
      expect(table.storedGoalEntries['sodium'], {'custom_value': 1500});
    });

    test('it never falls back to a blind whole-row upsert', () async {
      final table = FakeNutritionTargetsTable(row: _rowWith(null));
      final repository = _repository(gateway: table);

      await repository.updateAdditionalNutrientGoal(
        NutrientId.sodium,
        const AdditionalNutrientGoal(nutrientId: NutrientId.sodium),
      );

      // An upsert here would be last-writer-wins by construction, which is
      // the whole defect this path exists to avoid.
      expect(table.operations, isNot(contains('upsertRow')));
      expect(table.operations, contains('cas-ok'));
    });

    test('it refuses to overwrite an unsupported future schema', () async {
      final table = FakeNutritionTargetsTable(
        row: _rowWith({
          'schema_version': 2,
          'goals': <String, Object?>{},
        }),
      );
      final repository = _repository(gateway: table);
      final before = table.version;

      await expectLater(
        () => repository.updateAdditionalNutrientGoal(
          NutrientId.sodium,
          const AdditionalNutrientGoal(nutrientId: NutrientId.sodium),
        ),
        throwsStateError,
      );
      expect(table.version, before, reason: 'Nothing may be written.');
      expect(
        table.operations,
        isNot(anyElement(anyOf('cas-ok', 'insert-ok', 'upsertRow'))),
      );
    });

    test('a signed-out write fails closed before touching the gateway',
        () async {
      final table = FakeNutritionTargetsTable();
      final repository = _repository(gateway: table, userId: null);

      await expectLater(
        () => repository.updateAdditionalNutrientGoal(
          NutrientId.sodium,
          const AdditionalNutrientGoal(nutrientId: NutrientId.sodium),
        ),
        throwsStateError,
      );
      expect(table.operations, isEmpty);
    });
  });

  group('delta identity', () {
    // The nutrient key and the goal carry the same fact twice, and
    // `goal.validate()` only proves the goal's own nutrient is authorized —
    // not that it is the one being written.
    const mismatched = AdditionalNutrientGoal(
      nutrientId: NutrientId.vitaminD,
      customValue: 18,
    );

    test('a matching identity is accepted', () async {
      final table = FakeNutritionTargetsTable(row: _rowWith(null));
      final repository = _repository(gateway: table);

      await repository.updateAdditionalNutrientGoal(
        NutrientId.vitaminD,
        mismatched,
      );

      expect(table.storedGoalEntries['vitamin_d'], {'custom_value': 18});
    });

    test('a mismatched identity is rejected', () async {
      final table = FakeNutritionTargetsTable(row: _rowWith(null));
      final repository = _repository(gateway: table);

      await expectLater(
        () => repository.updateAdditionalNutrientGoal(
          NutrientId.sodium,
          mismatched,
        ),
        throwsArgumentError,
      );
    });

    test('a mismatch touches the gateway not at all', () async {
      final table = FakeNutritionTargetsTable(row: _rowWith(null));
      final repository = _repository(gateway: table);

      await expectLater(
        () => repository.updateAdditionalNutrientGoal(
          NutrientId.sodium,
          mismatched,
        ),
        throwsArgumentError,
      );

      // Not even a read: a caller bug should surface before any I/O, and
      // certainly before 18 mcg of Vitamin D lands under the Sodium key.
      expect(table.operations, isEmpty);
      expect(table.storedGoals, isNull);
    });

    test('the codec rejects it too', () {
      expect(
        () => AdditionalNutrientGoalsV1Codec.encodeGoalDelta(
          AdditionalNutrientGoalsV1Codec.decode(null),
          NutrientId.sodium,
          mismatched,
        ),
        throwsArgumentError,
      );
    });

    test('the in-memory owner behaves identically', () async {
      // Its failure mode is the opposite one — `withGoal` follows
      // `goal.nutrientId`, so it would write Vitamin D while production wrote
      // 18 under Sodium. Divergence on a bad call is worse than either.
      final repository = InMemoryNutritionTargetsRepository();

      await expectLater(
        () => repository.updateAdditionalNutrientGoal(
          NutrientId.sodium,
          mismatched,
        ),
        throwsArgumentError,
      );
      expect(await repository.read(), isNull);
    });
  });

  group('concurrent writers never lose each other\'s deltas', () {
    // A per-nutrient API fixes the stale-snapshot deletion but not the
    // read-modify-write race: two clients can read the same envelope, each add
    // a different nutrient, and each write the whole column back. These tests
    // land the competing writer in the window between this writer's read and
    // its write, which is the only place the race actually happens.

    /// Applies one nutrient through a second, independent client.
    Future<void> otherClient(
      FakeNutritionTargetsTable table,
      NutrientId nutrientId,
      AdditionalNutrientGoal? goal,
    ) =>
        _repository(gateway: table).updateAdditionalNutrientGoal(
          nutrientId,
          goal,
        );

    test('same predecessor: A adds Vitamin D, B adds Sodium, both survive',
        () async {
      final table = FakeNutritionTargetsTable(row: _rowWith(_envelope({})));
      final b = _repository(gateway: table);

      // B has now read E0. A reads the same E0 inside this window and wins.
      table.onAfterRead = () => otherClient(
            table,
            NutrientId.vitaminD,
            const AdditionalNutrientGoal(nutrientId: NutrientId.vitaminD),
          );

      await b.updateAdditionalNutrientGoal(
        NutrientId.sodium,
        const AdditionalNutrientGoal(
          nutrientId: NutrientId.sodium,
          customValue: 1500,
        ),
      );

      final goals = table.storedGoalEntries;
      expect(
        goals['vitamin_d'],
        {'custom_value': null},
        reason: "B's write must not erase A's delta.",
      );
      expect(goals['sodium'], {'custom_value': 1500});
      expect(
        table.operations,
        containsAllInOrder(['cas-conflict', 'read', 'cas-ok']),
        reason: 'B must lose the swap, re-read, and rebuild on fresh state.',
      );
    });

    test('same predecessor, reversed: A adds Sodium, B adds Vitamin D',
        () async {
      final table = FakeNutritionTargetsTable(row: _rowWith(_envelope({})));
      final b = _repository(gateway: table);

      table.onAfterRead = () => otherClient(
            table,
            NutrientId.sodium,
            const AdditionalNutrientGoal(
              nutrientId: NutrientId.sodium,
              customValue: 1500,
            ),
          );

      await b.updateAdditionalNutrientGoal(
        NutrientId.vitaminD,
        const AdditionalNutrientGoal(nutrientId: NutrientId.vitaminD),
      );

      final goals = table.storedGoalEntries;
      expect(goals['sodium'], {'custom_value': 1500});
      expect(goals['vitamin_d'], {'custom_value': null});
    });

    test('a concurrent disable does not resurrect the disabled nutrient',
        () async {
      final table = FakeNutritionTargetsTable(
        row: _rowWith(_envelope({
          'sodium': {'custom_value': 1500},
          'vitamin_d': {'custom_value': 18},
        })),
      );
      final b = _repository(gateway: table);

      // A turns Sodium off while B is editing Vitamin D.
      table.onAfterRead = () => otherClient(table, NutrientId.sodium, null);

      await b.updateAdditionalNutrientGoal(
        NutrientId.vitaminD,
        const AdditionalNutrientGoal(
          nutrientId: NutrientId.vitaminD,
          customValue: 20,
        ),
      );

      final goals = table.storedGoalEntries;
      expect(
        goals.containsKey('sodium'),
        isFalse,
        reason: "B rebuilt on A's envelope, so the removal stands.",
      );
      expect(goals['vitamin_d'], {'custom_value': 20});
    });

    test('everything this build does not understand survives a retry',
        () async {
      final table = FakeNutritionTargetsTable(
        row: _rowWith({
          'schema_version': 1,
          'written_by': 'newer-client',
          'goals': {
            'added_sugar': {'custom_value': 25, 'future_flag': true},
            'vitamin_d': {'custom_value': 18, 'note': 'from a newer build'},
          },
        }),
      );
      final b = _repository(gateway: table);

      table.onAfterRead = () => otherClient(
            table,
            NutrientId.saturatedFat,
            const AdditionalNutrientGoal(
              nutrientId: NutrientId.saturatedFat,
            ),
          );

      await b.updateAdditionalNutrientGoal(
        NutrientId.vitaminD,
        const AdditionalNutrientGoal(
          nutrientId: NutrientId.vitaminD,
          customValue: 20,
        ),
      );

      final envelope = table.storedGoals! as Map<String, Object?>;
      final goals = table.storedGoalEntries;
      expect(envelope['written_by'], 'newer-client');
      expect(goals['added_sugar'], {'custom_value': 25, 'future_flag': true});
      expect(goals['saturated_fat'], {'custom_value': null});
      expect((goals['vitamin_d']! as Map)['custom_value'], 20);
      expect(
        (goals['vitamin_d']! as Map)['note'],
        'from a newer build',
        reason: 'An unknown field inside the edited entry survives too.',
      );
    });

    test('a schema that turns unsupported mid-retry still fails closed',
        () async {
      final table = FakeNutritionTargetsTable(row: _rowWith(_envelope({})));
      final b = _repository(gateway: table);

      table.onAfterRead = () async {
        // Another client migrates the envelope forward under us.
        table.writeConcurrently({
          'schema_version': 2,
          'goals': <String, Object?>{},
        });
      };

      await expectLater(
        () => b.updateAdditionalNutrientGoal(
          NutrientId.sodium,
          const AdditionalNutrientGoal(nutrientId: NutrientId.sodium),
        ),
        throwsStateError,
      );
      expect(
        (table.storedGoals! as Map)['schema_version'],
        2,
        reason: 'An older client must never downgrade newer data.',
      );
    });

    test('sustained contention fails loudly instead of overwriting', () async {
      final table = FakeNutritionTargetsTable(row: _rowWith(_envelope({})));
      final b = _repository(gateway: table);

      var landed = 0;
      void armConcurrentWriter() {
        table.onAfterRead = () async {
          landed++;
          table.writeConcurrently(_envelope({
            'vitamin_d': {'custom_value': landed},
          }));
          armConcurrentWriter();
        };
      }

      armConcurrentWriter();

      await expectLater(
        () => b.updateAdditionalNutrientGoal(
          NutrientId.sodium,
          const AdditionalNutrientGoal(nutrientId: NutrientId.sodium),
        ),
        throwsStateError,
      );

      expect(
        landed,
        SupabaseNutritionTargetsRepository.maxWriteAttempts,
        reason: 'Retries are bounded, not infinite.',
      );
      final goals = table.storedGoalEntries;
      expect(
        goals.containsKey('sodium'),
        isFalse,
        reason: 'Giving up must not write a stale envelope.',
      );
      expect((goals['vitamin_d']! as Map)['custom_value'], landed);
    });

    test('a missing row is created rather than upserted', () async {
      final table = FakeNutritionTargetsTable();
      final repository = _repository(gateway: table);

      await repository.updateAdditionalNutrientGoal(
        NutrientId.sodium,
        const AdditionalNutrientGoal(nutrientId: NutrientId.sodium),
      );

      expect(table.operations, contains('insert-ok'));
      expect(table.operations, isNot(contains('upsertRow')));
      expect(table.storedGoalEntries['sodium'], {'custom_value': null});
    });

    test('losing the race to create the row merges instead of clobbering',
        () async {
      final table = FakeNutritionTargetsTable();
      final b = _repository(gateway: table);

      // B saw no row. A creates it first, in the window before B's insert.
      table.onAfterRead = () async => table.createConcurrently(_envelope({
            'vitamin_d': {'custom_value': 18},
          }));

      await b.updateAdditionalNutrientGoal(
        NutrientId.sodium,
        const AdditionalNutrientGoal(
          nutrientId: NutrientId.sodium,
          customValue: 1500,
        ),
      );

      final goals = table.storedGoalEntries;
      expect(
        goals['vitamin_d'],
        {'custom_value': 18},
        reason: "A's row must not be replaced by B's blind insert.",
      );
      expect(goals['sodium'], {'custom_value': 1500});
      expect(
        table.operations,
        containsAllInOrder(['insert-conflict', 'read', 'cas-ok']),
      );
    });

    test('an unrelated insert failure is not mistaken for a lost race',
        () async {
      final table = FailingInsertTargetsTable(
        const PostgrestException(message: 'permission denied', code: '42501'),
      );
      final repository = _repository(gateway: table);

      await expectLater(
        () => repository.updateAdditionalNutrientGoal(
          NutrientId.sodium,
          const AdditionalNutrientGoal(nutrientId: NutrientId.sodium),
        ),
        throwsA(isA<PostgrestException>()),
      );
    });

    test('the in-memory owner loses nothing either', () async {
      // A test double that replaced the whole set would let the production
      // regression pass unnoticed in every screen-level test.
      final repository = InMemoryNutritionTargetsRepository();
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
        gateway: FakeNutritionTargetsTable(row: {
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
        gateway: FakeNutritionTargetsTable(row: {
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
        gateway: FakeNutritionTargetsTable(row: {
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
    final gateway = FakeNutritionTargetsTable();
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

/// A seeded row. The fake stamps its own version, so none is written here —
/// a hand-picked literal can collide with a later stamp and let a stale
/// compare-and-swap pass.
Map<String, dynamic> _rowWith(Object? goals) => {
      'user_id': 'user-1',
      'additional_nutrient_goals': goals,
    };

Map<String, Object?> _envelope(Map<String, Object?> goals) => {
      'schema_version': 1,
      'goals': goals,
    };

SupabaseNutritionTargetsRepository _repository({
  required NutritionTargetsTableGateway gateway,
  String? userId = 'user-1',
}) =>
    SupabaseNutritionTargetsRepository(
      client: SupabaseClient('https://example.invalid', 'anon-key'),
      gateway: gateway,
      currentUserId: () => userId,
    );
