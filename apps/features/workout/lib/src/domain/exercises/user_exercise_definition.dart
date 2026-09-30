import 'package:tio_shared/shared.dart';

/// Validated mutable definition fields for one user-owned canonical Exercise.
///
/// This is a write value, not a second Exercise entity.
final class UserExerciseDefinition {
  UserExerciseDefinition({
    String? description,
    this.exerciseType,
    String? primaryMuscle,
    List<String> secondaryMuscles = const [],
    String? primaryEquipment,
  })  : description = _normalizeDescription(description),
        primaryMuscle = _validateOptionalToken(
          primaryMuscle,
          muscleTokens,
          'primaryMuscle',
        ),
        secondaryMuscles = _validateSecondaryMuscles(
          secondaryMuscles,
          primaryMuscle,
        ),
        primaryEquipment = _validateOptionalToken(
          primaryEquipment,
          equipmentTokens,
          'primaryEquipment',
        );

  final String? description;
  final ExerciseType? exerciseType;
  final String? primaryMuscle;
  final List<String> secondaryMuscles;
  final String? primaryEquipment;

  static const muscleTokens = <String>{
    'sternocleidomastoid',
    'pectoralis_major_sternal_head',
    'pectoralis_major_clavicular_head',
    'deltoid_anterior',
    'deltoid_lateral',
    'brachioradialis',
    'rectus_abdominis',
    'sartorius',
    'serratus_anterior',
    'pectineus',
    'transverse_abdominis',
    'tensor_fasciae_latae',
    'iliopsoas',
    'wrist_extensors',
    'wrist_flexors',
    'deltoid_posterior',
    'trapezius_lower_fibers',
    'trapezius_upper_fibers',
    'trapezius_middle_fibers',
    'infraspinatus',
    'teres_major',
    'teres_minor',
    'latissimus_dorsi',
    'erector_spinae',
    'adductor_longus',
    'adductor_magnus',
    'gluteus_maximus',
    'gluteus_medius',
    'hamstrings',
    'gracilis',
    'levator_scapulae',
    'popliteus',
    'splenius',
    'triceps_brachii',
    'biceps_brachii',
    'brachialis',
    'obliques',
    'quadriceps',
    'gastrocnemius',
    'tibialis_anterior',
    'soleus',
    'gluteus_minimus',
    'deep_hip_external_rotators',
    'serratus_anterior_alternate',
  };

  static const equipmentTokens = <String>{
    'barbell',
    'bodyweight',
    'cable',
    'dumbbell',
    'ez_bar',
    'lever_machine',
    'sled_machine',
    'smith_machine',
    'weighted',
    'band',
    'kettlebell',
    'medicine_ball',
    'power_sled',
    'resistance_band',
    'stability_ball',
    'suspension',
    'trap_bar',
    'wheel_roller',
  };

  static String? _normalizeDescription(String? value) {
    if (value == null) return null;
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  static String? _validateOptionalToken(
    String? value,
    Set<String> allowed,
    String name,
  ) {
    if (value == null) return null;
    if (!allowed.contains(value)) {
      throw ArgumentError.value(value, name, 'is not an approved token');
    }
    return value;
  }

  static List<String> _validateSecondaryMuscles(
    List<String> values,
    String? primaryMuscle,
  ) {
    final copy = List<String>.of(values);
    final seen = <String>{};
    for (final value in copy) {
      if (!muscleTokens.contains(value)) {
        throw ArgumentError.value(
          values,
          'secondaryMuscles',
          'contains an unapproved token',
        );
      }
      if (value == primaryMuscle) {
        throw ArgumentError.value(
          values,
          'secondaryMuscles',
          'must not contain the primary muscle',
        );
      }
      if (!seen.add(value)) {
        throw ArgumentError.value(
          values,
          'secondaryMuscles',
          'must not contain duplicates',
        );
      }
    }
    return List<String>.unmodifiable(copy);
  }
}
