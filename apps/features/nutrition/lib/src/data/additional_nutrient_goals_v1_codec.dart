import 'package:tio_shared/shared.dart';

import '../domain/models/additional_nutrient_goal.dart';

/// Decode result keeps the opaque persistence envelope inside the data layer.
final class AdditionalNutrientGoalsDecodeResult {
  const AdditionalNutrientGoalsDecodeResult._({
    required this.goals,
    required Map<String, Object?>? rawEnvelope,
  }) : _rawEnvelope = rawEnvelope;

  final AdditionalNutrientGoalSet goals;
  final Map<String, Object?>? _rawEnvelope;
}

/// Versioned JSON codec for `additional_nutrient_goals`.
///
/// Unknown V1 top-level fields, nutrient entries, and fields inside known
/// nutrient entries are merge-preserved. Unsupported future versions are
/// decoded as read-only and can never be encoded by this client.
final class AdditionalNutrientGoalsV1Codec {
  const AdditionalNutrientGoalsV1Codec._();

  static const schemaVersion = 1;

  static AdditionalNutrientGoalsDecodeResult decode(Object? raw) {
    if (raw == null) {
      return const AdditionalNutrientGoalsDecodeResult._(
        goals: AdditionalNutrientGoalSet.empty(),
        rawEnvelope: null,
      );
    }

    final envelope = _requireObject(raw, 'additional_nutrient_goals');
    final rawVersion = envelope['schema_version'];
    if (rawVersion is! int || rawVersion < 1) {
      throw const FormatException(
        'Invalid additional_nutrient_goals.schema_version.',
      );
    }
    if (rawVersion > schemaVersion) {
      return AdditionalNutrientGoalsDecodeResult._(
        goals: const AdditionalNutrientGoalSet.unsupported(),
        rawEnvelope: Map.unmodifiable(envelope),
      );
    }

    final rawGoals = _requireObject(
      envelope['goals'],
      'additional_nutrient_goals.goals',
    );
    final goals = <AdditionalNutrientGoal>[];

    for (final nutrientId in AdditionalNutrientGoalSet.authorizedNutrients) {
      final storageValue = nutrientId.storageValue;
      if (!rawGoals.containsKey(storageValue)) continue;

      final entry = _requireObject(
        rawGoals[storageValue],
        'additional_nutrient_goals.goals.$storageValue',
      );
      if (!entry.containsKey('custom_value')) {
        throw FormatException(
          'Invalid additional_nutrient_goals.goals.$storageValue: '
          'missing custom_value.',
        );
      }
      final rawCustom = entry['custom_value'];
      if (rawCustom != null && rawCustom is! num) {
        throw FormatException(
          'Invalid additional_nutrient_goals.goals.$storageValue.custom_value.',
        );
      }
      final customValue = rawCustom?.toDouble();
      if (customValue != null && (!customValue.isFinite || customValue < 0)) {
        throw FormatException(
          'Invalid additional_nutrient_goals.goals.$storageValue.custom_value.',
        );
      }
      goals.add(AdditionalNutrientGoal(
        nutrientId: nutrientId,
        customValue: customValue,
      ));
    }

    return AdditionalNutrientGoalsDecodeResult._(
      goals: AdditionalNutrientGoalSet.fromGoals(goals),
      rawEnvelope: Map.unmodifiable(envelope),
    );
  }

  static Map<String, Object?> encodeUpdated(
    AdditionalNutrientGoalsDecodeResult decoded,
    AdditionalNutrientGoalSet updated,
  ) {
    if (!decoded.goals.isWritable || !updated.isWritable) {
      throw StateError(
        'This Additional Nutrient Goals schema is newer and read-only.',
      );
    }
    updated.validate();

    final envelope = <String, Object?>{
      ...?decoded._rawEnvelope,
      'schema_version': schemaVersion,
    };
    final existingGoals = decoded._rawEnvelope?['goals'];
    final goals = existingGoals is Map
        ? _requireObject(existingGoals, 'additional_nutrient_goals.goals')
        : <String, Object?>{};

    for (final nutrientId in AdditionalNutrientGoalSet.authorizedNutrients) {
      final storageValue = nutrientId.storageValue;
      final goal = updated[nutrientId];
      if (goal == null) {
        goals.remove(storageValue);
        continue;
      }

      final previous = goals[storageValue];
      final entry = previous is Map
          ? _requireObject(
              previous,
              'additional_nutrient_goals.goals.$storageValue',
            )
          : <String, Object?>{};
      entry['custom_value'] = goal.customValue;
      goals[storageValue] = entry;
    }

    envelope['goals'] = goals;
    return envelope;
  }
}

Map<String, Object?> _requireObject(Object? raw, String path) {
  if (raw is! Map) {
    throw FormatException('Invalid $path: expected JSON object.');
  }
  final result = <String, Object?>{};
  for (final entry in raw.entries) {
    if (entry.key is! String) {
      throw FormatException('Invalid $path: expected string keys.');
    }
    result[entry.key as String] = entry.value;
  }
  return result;
}

