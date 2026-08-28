import '../domain/body_setup.dart';

/// Pure mapping boundary from canonical Body owner rows to backend-neutral
/// domain state. Database querying stays in the Supabase repository; mapping is
/// isolated so malformed rows cannot silently become fabricated Body truth.
class BodyStateRowMapper {
  const BodyStateRowMapper();

  BodyState map({
    Map<String, dynamic>? latestWeightRow,
    Map<String, dynamic>? activeGoalRow,
  }) {
    return BodyState(
      latestWeight: _mapWeight(latestWeightRow),
      activeGoal: _mapGoal(activeGoalRow),
    );
  }

  BodyWeightEntry? _mapWeight(Map<String, dynamic>? row) {
    if (row == null) return null;

    final rawWeight = row['weight_kg'];
    if (rawWeight is! num || rawWeight <= 0) {
      throw const FormatException(
        'Missing or invalid canonical Body weight: weight_kg',
      );
    }

    final rawMeasuredAt = row['measured_at'];
    if (rawMeasuredAt is! String || rawMeasuredAt.trim().isEmpty) {
      throw const FormatException(
        'Missing or invalid canonical Body weight: measured_at',
      );
    }
    final measuredAt = DateTime.tryParse(rawMeasuredAt)?.toUtc();
    if (measuredAt == null) {
      throw const FormatException(
        'Missing or invalid canonical Body weight: measured_at',
      );
    }

    final rawSource = row['source'];
    if (rawSource != null && rawSource is! String) {
      throw const FormatException(
        'Invalid canonical Body weight provenance: source',
      );
    }

    return BodyWeightEntry(
      weightKg: rawWeight.toDouble(),
      measuredAt: measuredAt,
      source: rawSource as String?,
    );
  }

  BodyGoalState? _mapGoal(Map<String, dynamic>? row) {
    if (row == null) return null;

    final goalType = _parseGoalType(row['goal_type']);
    final startingWeight = _optionalPositiveNumber(
      row['starting_weight_kg'],
      field: 'starting_weight_kg',
    );
    final targetWeight = _optionalPositiveNumber(
      row['target_weight_kg'],
      field: 'target_weight_kg',
    );
    final weeklyPace = _optionalNonnegativeNumber(
      row['weekly_weight_change_kg'],
      field: 'weekly_weight_change_kg',
    );
    final intentRank = _optionalIntentRank(row['intent_rank']);
    final startedAt = _optionalDateTime(row['started_at'], field: 'started_at');

    final isDirectional = goalType == BodyGoalType.loseWeight ||
        goalType == BodyGoalType.gainWeight;
    if (!isDirectional && (targetWeight != null || weeklyPace != null)) {
      throw const FormatException(
        'Maintain/Recomposition canonical Body Goal cannot carry Target Weight or Goal Pace.',
      );
    }

    return BodyGoalState(
      goalType: goalType,
      startingWeightKg: startingWeight,
      targetWeightKg: targetWeight,
      weeklyWeightChangeKg: weeklyPace,
      intentRank: intentRank,
      startedAt: startedAt,
    );
  }

  BodyGoalType _parseGoalType(Object? raw) => switch (raw) {
        'lose_weight' => BodyGoalType.loseWeight,
        'gain_weight' => BodyGoalType.gainWeight,
        'maintain_weight' => BodyGoalType.maintainWeight,
        'recomposition' => BodyGoalType.recomposition,
        _ => throw const FormatException(
            'Missing or invalid canonical Body Goal: goal_type',
          ),
      };

  double? _optionalPositiveNumber(Object? raw, {required String field}) {
    if (raw == null) return null;
    if (raw is! num || raw <= 0) {
      throw FormatException('Invalid canonical Body Goal field: $field');
    }
    return raw.toDouble();
  }

  double? _optionalNonnegativeNumber(Object? raw, {required String field}) {
    if (raw == null) return null;
    if (raw is! num || raw < 0) {
      throw FormatException('Invalid canonical Body Goal field: $field');
    }
    return raw.toDouble();
  }

  int? _optionalIntentRank(Object? raw) {
    if (raw == null) return null;
    if (raw is! num || raw != raw.toInt()) {
      throw const FormatException(
        'Invalid canonical Body Goal field: intent_rank',
      );
    }
    final rank = raw.toInt();
    if (rank != 1 && rank != 2) {
      throw const FormatException(
        'Invalid canonical Body Goal field: intent_rank',
      );
    }
    return rank;
  }

  DateTime? _optionalDateTime(Object? raw, {required String field}) {
    if (raw == null) return null;
    if (raw is! String || raw.trim().isEmpty) {
      throw FormatException('Invalid canonical Body Goal field: $field');
    }
    final parsed = DateTime.tryParse(raw)?.toUtc();
    if (parsed == null) {
      throw FormatException('Invalid canonical Body Goal field: $field');
    }
    return parsed;
  }
}
