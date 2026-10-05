import 'package:tio_shared/shared.dart';

import '../../../domain/exercises/user_exercise_definition.dart';

/// Presentation metadata for the owner-approved Custom Exercise type selector.
///
/// The enum value is the only durable truth. Labels, examples and hint tags are
/// UI guidance and are never persisted independently.
final class CustomExerciseTypeOption {
  const CustomExerciseTypeOption({
    required this.type,
    required this.label,
    required this.example,
    required this.hints,
  });

  final ExerciseType type;
  final String label;
  final String example;
  final List<String> hints;
}

const customExerciseTypeOptions = <CustomExerciseTypeOption>[
  CustomExerciseTypeOption(
    type: ExerciseType.weightReps,
    label: 'Weight & Reps',
    example: 'Bench press, Squat, Deadlift',
    hints: ['KG', 'REPS'],
  ),
  CustomExerciseTypeOption(
    type: ExerciseType.distanceDuration,
    label: 'Distance & Duration',
    example: 'Running, Cycling, Swimming',
    hints: ['KM', 'TIME'],
  ),
  CustomExerciseTypeOption(
    type: ExerciseType.duration,
    label: 'Duration',
    example: 'Plank, Wall Sit',
    hints: ['TIME'],
  ),
  CustomExerciseTypeOption(
    type: ExerciseType.dumbbellX2Simultaneous,
    label: 'Dumbbell x2 Simultaneous',
    example: 'Dumbbell bench press, Dumbbell fly',
    hints: ['KG', 'REPS', 'x2'],
  ),
  CustomExerciseTypeOption(
    type: ExerciseType.dumbbellX1AlternatingSides,
    label: 'Dumbbell x1 Alt Sides',
    example: 'One-arm row, Alternating curls',
    hints: ['KG', 'REPS', 'x1'],
  ),
  CustomExerciseTypeOption(
    type: ExerciseType.dumbbellX1Simultaneous,
    label: 'Dumbbell x1 Simultaneous',
    example: 'Pullover, Goblet squat',
    hints: ['KG', 'REPS', 'x1'],
  ),
  CustomExerciseTypeOption(
    type: ExerciseType.dumbbellX2AlternatingLegs,
    label: 'Dumbbell x2 Alt Legs',
    example: 'Lunges, Bulgarian split squats',
    hints: ['KG', 'REPS', 'x2'],
  ),
  CustomExerciseTypeOption(
    type: ExerciseType.dumbbellX1AlternatingLegs,
    label: 'Dumbbell x1 Alt Legs',
    example: 'Lunges, Bulgarian split squats',
    hints: ['KG', 'REPS', 'x1'],
  ),
  CustomExerciseTypeOption(
    type: ExerciseType.fullBodyweight,
    label: 'Full Bodyweight',
    example: 'Pull-ups, Dips',
    hints: ['+KG', 'REPS'],
  ),
  CustomExerciseTypeOption(
    type: ExerciseType.assistedBodyweight,
    label: 'Assisted Bodyweight',
    example: 'Assisted pull-up, Assisted dip',
    hints: ['-KG', 'REPS'],
  ),
  CustomExerciseTypeOption(
    type: ExerciseType.stepsDuration,
    label: 'Steps & Duration',
    example: 'Step mill, Elliptical, Stair climbing',
    hints: ['STEPS', 'TIME'],
  ),
];

CustomExerciseTypeOption customExerciseTypeOptionFor(ExerciseType type) =>
    customExerciseTypeOptions.firstWhere((option) => option.type == type);

String customExerciseTypeLabel(ExerciseType type) =>
    customExerciseTypeOptionFor(type).label;

/// Derived presentation grouping for Primary muscle selection.
///
/// Body Part is navigation only. The selected muscle token remains the sole
/// persisted value.
final class CustomExerciseBodyPartOption {
  const CustomExerciseBodyPartOption({
    required this.id,
    required this.label,
    required this.muscles,
  });

  final String id;
  final String label;
  final List<String> muscles;
}

const customExercisePrimaryBodyParts = <CustomExerciseBodyPartOption>[
  CustomExerciseBodyPartOption(
    id: 'chest',
    label: 'Chest',
    muscles: [
      'pectoralis_major_sternal_head',
      'pectoralis_major_clavicular_head',
      'serratus_anterior',
      'serratus_anterior_alternate',
    ],
  ),
  CustomExerciseBodyPartOption(
    id: 'back',
    label: 'Back',
    muscles: [
      'trapezius_lower_fibers',
      'trapezius_upper_fibers',
      'trapezius_middle_fibers',
      'teres_major',
      'latissimus_dorsi',
      'erector_spinae',
    ],
  ),
  CustomExerciseBodyPartOption(
    id: 'shoulders',
    label: 'Shoulders',
    muscles: [
      'deltoid_anterior',
      'deltoid_lateral',
      'deltoid_posterior',
      'infraspinatus',
      'teres_minor',
    ],
  ),
  CustomExerciseBodyPartOption(
    id: 'biceps',
    label: 'Biceps',
    muscles: [
      'biceps_brachii',
      'brachialis',
    ],
  ),
  CustomExerciseBodyPartOption(
    id: 'triceps',
    label: 'Triceps',
    muscles: ['triceps_brachii'],
  ),
  CustomExerciseBodyPartOption(
    id: 'quadriceps',
    label: 'Quadriceps',
    muscles: [
      'quadriceps',
      'sartorius',
    ],
  ),
  CustomExerciseBodyPartOption(
    id: 'hamstrings',
    label: 'Hamstrings',
    muscles: [
      'hamstrings',
      'popliteus',
    ],
  ),
  CustomExerciseBodyPartOption(
    id: 'hips',
    label: 'Hips',
    muscles: [
      'pectineus',
      'tensor_fasciae_latae',
      'iliopsoas',
      'adductor_longus',
      'adductor_magnus',
      'gluteus_maximus',
      'gluteus_medius',
      'gluteus_minimus',
      'gracilis',
      'deep_hip_external_rotators',
    ],
  ),
  CustomExerciseBodyPartOption(
    id: 'calves',
    label: 'Calves',
    muscles: [
      'gastrocnemius',
      'soleus',
      'tibialis_anterior',
    ],
  ),
  CustomExerciseBodyPartOption(
    id: 'forearms',
    label: 'Forearms',
    muscles: [
      'brachioradialis',
      'wrist_extensors',
      'wrist_flexors',
    ],
  ),
  CustomExerciseBodyPartOption(
    id: 'neck',
    label: 'Neck',
    muscles: [
      'sternocleidomastoid',
      'splenius',
      'levator_scapulae',
    ],
  ),
  CustomExerciseBodyPartOption(
    id: 'waist_abs',
    label: 'Waist / Abs',
    muscles: [
      'rectus_abdominis',
      'transverse_abdominis',
      'obliques',
    ],
  ),
];

CustomExerciseBodyPartOption? customExerciseBodyPartForMuscle(String? muscle) {
  if (muscle == null) return null;
  for (final option in customExercisePrimaryBodyParts) {
    if (option.muscles.contains(muscle)) return option;
  }
  return null;
}

List<String> customExerciseAllMuscles() {
  final muscles = UserExerciseDefinition.muscleTokens.toList(growable: false);
  muscles.sort();
  return muscles;
}
