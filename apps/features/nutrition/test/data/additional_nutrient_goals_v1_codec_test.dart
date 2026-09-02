import 'package:flutter_test/flutter_test.dart';
import 'package:tio_feature_nutrition/nutrition.dart';
import 'package:tio_shared/shared.dart';

/// V1 persistence envelope for `additional_nutrient_goals`.
///
/// This column is shared with clients that may be newer or older than this
/// build, so the codec's real job is data safety rather than convenience: a
/// read-modify-write must not silently drop anything it did not understand,
/// and it must never rewrite a payload written by a newer schema.
void main() {
  Map<String, Object?> roundTrip(
    Object? stored,
    AdditionalNutrientGoalSet updated,
  ) =>
      AdditionalNutrientGoalsV1Codec.encodeUpdated(
        AdditionalNutrientGoalsV1Codec.decode(stored),
        updated,
      );

  group('decode', () {
    test('a null column means no payload, not a corrupt one', () {
      final decoded = AdditionalNutrientGoalsV1Codec.decode(null);

      expect(decoded.goals.isEmpty, isTrue);
      expect(decoded.goals.isWritable, isTrue);
    });

    test('a V1 envelope with empty goals is valid and configures nothing', () {
      final decoded = AdditionalNutrientGoalsV1Codec.decode({
        'schema_version': 1,
        'goals': <String, Object?>{},
      });

      expect(decoded.goals.isEmpty, isTrue);
      expect(decoded.goals.isWritable, isTrue);
    });

    test('a null custom_value means enabled on the recommendation', () {
      final decoded = AdditionalNutrientGoalsV1Codec.decode({
        'schema_version': 1,
        'goals': {
          'sodium': {'custom_value': null},
        },
      });

      expect(decoded.goals.contains(NutrientId.sodium), isTrue);
      expect(decoded.goals[NutrientId.sodium]!.customValue, isNull);
    });

    test('a numeric custom_value is an override', () {
      final decoded = AdditionalNutrientGoalsV1Codec.decode({
        'schema_version': 1,
        'goals': {
          'sodium': {'custom_value': 1500},
          'vitamin_d': {'custom_value': 18.5},
        },
      });

      expect(decoded.goals[NutrientId.sodium]!.customValue, 1500);
      expect(decoded.goals[NutrientId.vitaminD]!.customValue, 18.5);
    });

    test('an explicit zero decodes as zero, never as absent', () {
      final decoded = AdditionalNutrientGoalsV1Codec.decode({
        'schema_version': 1,
        'goals': {
          'trans_fat': {'custom_value': 0},
        },
      });

      expect(decoded.goals[NutrientId.transFat]!.customValue, 0);
      expect(decoded.goals[NutrientId.transFat]!.usesRecommendation, isFalse);
    });

    test('an absent nutrient key is not configured', () {
      final decoded = AdditionalNutrientGoalsV1Codec.decode({
        'schema_version': 1,
        'goals': {
          'sodium': {'custom_value': null},
        },
      });

      expect(decoded.goals.contains(NutrientId.vitaminD), isFalse);
    });

    test('rejects malformed known entries rather than guessing', () {
      final malformed = <Object?>[
        {
          'schema_version': 1,
          'goals': {'sodium': 'not-an-object'},
        },
        {
          'schema_version': 1,
          'goals': {
            'sodium': <String, Object?>{},
          },
        },
        {
          'schema_version': 1,
          'goals': {
            'sodium': {'custom_value': 'nope'},
          },
        },
        {
          'schema_version': 1,
          'goals': {
            'sodium': {'custom_value': -5},
          },
        },
      ];

      for (final payload in malformed) {
        expect(
          () => AdditionalNutrientGoalsV1Codec.decode(payload),
          throwsFormatException,
          reason: '$payload',
        );
      }
    });

    test('rejects a missing or invalid schema version', () {
      for (final payload in <Object?>[
        <String, Object?>{},
        {'goals': <String, Object?>{}},
        {'schema_version': 0, 'goals': <String, Object?>{}},
        {'schema_version': '1', 'goals': <String, Object?>{}},
      ]) {
        expect(
          () => AdditionalNutrientGoalsV1Codec.decode(payload),
          throwsFormatException,
          reason: '$payload',
        );
      }
    });

    test('reads an unsupported future schema as read-only', () {
      final decoded = AdditionalNutrientGoalsV1Codec.decode({
        'schema_version': 2,
        'goals': {
          'sodium': {'custom_value': 1200},
        },
      });

      expect(decoded.goals.isWritable, isFalse);
      expect(
        decoded.goals.isEmpty,
        isTrue,
        reason: 'Future data must not be interpreted with V1 rules.',
      );
    });
  });

  group('encode preserves data this build does not understand', () {
    test('keeps unknown nutrient entries untouched', () {
      final encoded = roundTrip(
        {
          'schema_version': 1,
          'goals': {
            'sodium': {'custom_value': 1500},
            'added_sugar': {'custom_value': 25, 'future_flag': true},
          },
        },
        AdditionalNutrientGoalSet.fromGoals([
          const AdditionalNutrientGoal(
            nutrientId: NutrientId.sodium,
            customValue: 1200,
          ),
        ]),
      );

      final goals = encoded['goals']! as Map<String, Object?>;
      expect((goals['sodium']! as Map)['custom_value'], 1200);
      expect(
        goals['added_sugar'],
        {'custom_value': 25, 'future_flag': true},
        reason: 'A nutrient outside V1 must survive a V1 edit verbatim.',
      );
    });

    test('keeps unknown top-level fields', () {
      final encoded = roundTrip(
        {
          'schema_version': 1,
          'goals': <String, Object?>{},
          'written_by': 'future-client',
          'future_settings': {'nested': true},
        },
        const AdditionalNutrientGoalSet.empty().withGoal(
          const AdditionalNutrientGoal(nutrientId: NutrientId.vitaminD),
        ),
      );

      expect(encoded['written_by'], 'future-client');
      expect(encoded['future_settings'], {'nested': true});
      expect(encoded['schema_version'], 1);
    });

    test('keeps unknown fields inside a known nutrient entry', () {
      final encoded = roundTrip(
        {
          'schema_version': 1,
          'goals': {
            'vitamin_d': {
              'custom_value': 18,
              'reminder_enabled': true,
              'note': 'set by a newer build',
            },
          },
        },
        AdditionalNutrientGoalSet.fromGoals([
          const AdditionalNutrientGoal(
            nutrientId: NutrientId.vitaminD,
            customValue: 20,
          ),
        ]),
      );

      final entry =
          (encoded['goals']! as Map<String, Object?>)['vitamin_d']! as Map;
      expect(entry['custom_value'], 20, reason: 'The edit still applies.');
      expect(entry['reminder_enabled'], isTrue);
      expect(entry['note'], 'set by a newer build');
    });

    test('survives a full read-modify-write cycle unchanged where untouched',
        () {
      final stored = <String, Object?>{
        'schema_version': 1,
        'unknown_root': [1, 2, 3],
        'goals': {
          'sodium': {'custom_value': null, 'unknown_entry_field': 'keep me'},
          'unknown_nutrient': {'custom_value': 7},
        },
      };

      final decoded = AdditionalNutrientGoalsV1Codec.decode(stored);
      final encoded = AdditionalNutrientGoalsV1Codec.encodeUpdated(
        decoded,
        decoded.goals,
      );

      expect(encoded['unknown_root'], [1, 2, 3]);
      final goals = encoded['goals']! as Map<String, Object?>;
      expect(goals['unknown_nutrient'], {'custom_value': 7});
      expect((goals['sodium']! as Map)['unknown_entry_field'], 'keep me');
      expect((goals['sodium']! as Map)['custom_value'], isNull);
    });
  });

  group('encode writes the V1 contract', () {
    test('Use Recommended keeps the key and nulls the override', () {
      final encoded = roundTrip(
        {
          'schema_version': 1,
          'goals': {
            'vitamin_d': {'custom_value': 18},
          },
        },
        const AdditionalNutrientGoalSet.empty().withGoal(
          const AdditionalNutrientGoal(nutrientId: NutrientId.vitaminD),
        ),
      );

      final goals = encoded['goals']! as Map<String, Object?>;
      expect(goals.containsKey('vitamin_d'), isTrue);
      expect((goals['vitamin_d']! as Map)['custom_value'], isNull);
    });

    test('disabling removes the nutrient key', () {
      final encoded = roundTrip(
        {
          'schema_version': 1,
          'goals': {
            'sodium': {'custom_value': 1500},
            'vitamin_d': {'custom_value': 18},
          },
        },
        AdditionalNutrientGoalSet.fromGoals([
          const AdditionalNutrientGoal(
            nutrientId: NutrientId.vitaminD,
            customValue: 18,
          ),
        ]),
      );

      final goals = encoded['goals']! as Map<String, Object?>;
      expect(goals.containsKey('sodium'), isFalse);
      expect(goals.containsKey('vitamin_d'), isTrue);
    });

    test('writes an explicit zero rather than dropping it', () {
      final encoded = roundTrip(
        null,
        AdditionalNutrientGoalSet.fromGoals([
          const AdditionalNutrientGoal(
            nutrientId: NutrientId.transFat,
            customValue: 0,
          ),
        ]),
      );

      final entry =
          (encoded['goals']! as Map<String, Object?>)['trans_fat']! as Map;
      expect(entry['custom_value'], 0);
      expect(entry.containsKey('custom_value'), isTrue);
    });

    test('creates a valid V1 envelope from a null column', () {
      final encoded = roundTrip(
        null,
        const AdditionalNutrientGoalSet.empty().withGoal(
          const AdditionalNutrientGoal(nutrientId: NutrientId.sodium),
        ),
      );

      expect(encoded['schema_version'], 1);
      expect(encoded['goals'], {
        'sodium': {'custom_value': null},
      });
    });

    test('never rewrites an unsupported future payload', () {
      final decoded = AdditionalNutrientGoalsV1Codec.decode({
        'schema_version': 2,
        'goals': {
          'sodium': {'custom_value': 1200},
        },
      });

      expect(
        () => AdditionalNutrientGoalsV1Codec.encodeUpdated(
          decoded,
          const AdditionalNutrientGoalSet.empty(),
        ),
        throwsStateError,
        reason: 'An older client must never downgrade newer data.',
      );
    });

    test('does not add an enabled flag alongside custom_value', () {
      final encoded = roundTrip(
        null,
        AdditionalNutrientGoalSet.fromGoals([
          const AdditionalNutrientGoal(
            nutrientId: NutrientId.sodium,
            customValue: 1500,
          ),
        ]),
      );

      final entry =
          (encoded['goals']! as Map<String, Object?>)['sodium']! as Map;
      expect(entry.keys, ['custom_value']);
    });

    test('does not persist derived or canonical truth', () {
      final encoded = roundTrip(
        null,
        AdditionalNutrientGoalSet.fromGoals([
          const AdditionalNutrientGoal(nutrientId: NutrientId.saturatedFat),
        ]),
      );

      final entry =
          (encoded['goals']! as Map<String, Object?>)['saturated_fat']! as Map;
      for (final forbidden in [
        'recommended_value',
        'unit',
        'enabled',
        'goal_type',
        'comparison',
        'source',
        'updated_at',
        'policy_version',
        'age',
        'date_of_birth',
        'calories',
      ]) {
        expect(
          entry.containsKey(forbidden),
          isFalse,
          reason: '$forbidden is runtime or canonical truth, not goal state.',
        );
      }
    });
  });
}
