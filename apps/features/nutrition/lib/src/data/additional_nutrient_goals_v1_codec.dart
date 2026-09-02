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
      // An explicit null means "use the recommendation"; any other non-numeric
      // value is malformed V1 rather than something to coerce or ignore.
      final rawCustom = entry['custom_value'];
      final double? customValue;
      if (rawCustom == null) {
        customValue = null;
      } else if (rawCustom is num) {
        customValue = rawCustom.toDouble();
      } else {
        throw FormatException(
          'Invalid additional_nutrient_goals.goals.$storageValue.custom_value.',
        );
      }
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

  /// Applies a single nutrient's change onto the freshly decoded envelope.
  ///
  /// Deliberately a one-nutrient delta rather than a full-set replacement.
  /// A screen's goal set is a snapshot from whenever it loaded, so writing all
  /// four authorized keys from it would delete a nutrient another client added
  /// in the meantime — re-reading first does not help, because the stale set
  /// still says "absent" for that nutrient. Only the key being edited is
  /// touched; every other entry, authorized or not, is carried through from
  /// the fresh envelope untouched.
  ///
  /// A null [goal] removes the nutrient; otherwise it is created or updated.
  static Map<String, Object?> encodeGoalDelta(
    AdditionalNutrientGoalsDecodeResult decoded,
    NutrientId nutrientId,
    AdditionalNutrientGoal? goal,
  ) {
    if (!decoded.goals.isWritable) {
      throw StateError(
        'This Additional Nutrient Goals schema is newer and read-only.',
      );
    }
    if (!AdditionalNutrientGoalSet.authorizedNutrients.contains(nutrientId)) {
      throw ArgumentError.value(
        nutrientId,
        'nutrientId',
        'Nutrient is outside Additional Nutrient Goals V1.',
      );
    }
    goal?.validate();

    final envelope = <String, Object?>{
      ...?decoded._rawEnvelope,
      'schema_version': schemaVersion,
    };
    final existingGoals = decoded._rawEnvelope?['goals'];
    final goals = existingGoals is Map
        ? _requireObject(existingGoals, 'additional_nutrient_goals.goals')
        : <String, Object?>{};

    final storageValue = nutrientId.storageValue;
    if (goal == null) {
      goals.remove(storageValue);
    } else {
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
