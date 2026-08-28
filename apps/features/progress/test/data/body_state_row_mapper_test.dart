import 'package:flutter_test/flutter_test.dart';
import 'package:tio_feature_progress/progress.dart';
import 'package:tio_feature_progress/src/data/body_state_row_mapper.dart';

void main() {
  const mapper = BodyStateRowMapper();

  test('missing canonical rows stay unknown instead of fabricating defaults', () {
    final state = mapper.map();

    expect(state.latestWeight, isNull);
    expect(state.activeGoal, isNull);
  });

  test('maps latest weight and active directional Body Goal exactly', () {
    final state = mapper.map(
      latestWeightRow: {
        'weight_kg': 79.4,
        'measured_at': '2026-08-21T16:00:00.000Z',
        'source': 'profile_settings',
      },
      activeGoalRow: {
        'goal_type': 'lose_weight',
        'starting_weight_kg': 82,
        'target_weight_kg': 74,
        'weekly_weight_change_kg': 0.4,
        'intent_rank': 1,
        'started_at': '2026-08-20T10:30:00.000Z',
      },
    );

    expect(state.latestWeight?.weightKg, 79.4);
    expect(
      state.latestWeight?.measuredAt,
      DateTime.utc(2026, 8, 21, 16),
    );
    expect(state.latestWeight?.source, 'profile_settings');

    final goal = state.activeGoal;
    expect(goal?.goalType, BodyGoalType.loseWeight);
    expect(goal?.startingWeightKg, 82);
    expect(goal?.targetWeightKg, 74);
    expect(goal?.weeklyWeightChangeKg, 0.4);
    expect(goal?.intentRank, 1);
    expect(goal?.startedAt, DateTime.utc(2026, 8, 20, 10, 30));
  });

  test('preserves null legacy provenance instead of inventing a source', () {
    final state = mapper.map(
      latestWeightRow: {
        'weight_kg': 71,
        'measured_at': '2026-08-21T10:00:00.000Z',
        'source': null,
      },
    );

    expect(state.latestWeight?.weightKg, 71);
    expect(state.latestWeight?.source, isNull);
  });

  test('rejects malformed canonical weight instead of defaulting it', () {
    expect(
      () => mapper.map(
        latestWeightRow: {
          'weight_kg': 0,
          'measured_at': '2026-08-21T10:00:00.000Z',
          'source': 'profile_settings',
        },
      ),
      throwsFormatException,
    );
  });

  test('rejects unknown Body Goal storage value', () {
    expect(
      () => mapper.map(
        activeGoalRow: {
          'goal_type': 'build_muscle',
          'starting_weight_kg': 80,
          'target_weight_kg': null,
          'weekly_weight_change_kg': null,
          'intent_rank': 1,
          'started_at': '2026-08-21T10:00:00.000Z',
        },
      ),
      throwsFormatException,
    );
  });

  test('rejects nondirectional Body Goal follow-up corruption', () {
    expect(
      () => mapper.map(
        activeGoalRow: {
          'goal_type': 'maintain_weight',
          'starting_weight_kg': 80,
          'target_weight_kg': 75,
          'weekly_weight_change_kg': null,
          'intent_rank': 1,
          'started_at': '2026-08-21T10:00:00.000Z',
        },
      ),
      throwsFormatException,
    );
  });
}
