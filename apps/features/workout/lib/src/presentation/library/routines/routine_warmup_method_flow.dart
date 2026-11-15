import 'package:flutter/material.dart';
import 'package:tio_shared/shared.dart';

import '../../../domain/models/workout_warmup_calculator.dart';
import '../../controllers/workout_runtime_settings_controller.dart';
import '../../widgets/workout_warmup_methods_sheet.dart';

final class RoutineWarmupMethodSelection {
  const RoutineWarmupMethodSelection({
    required this.settings,
    required this.sets,
  });

  final WorkoutWarmupSettings settings;
  final List<WarmupCalculatedSet> sets;
}

Future<RoutineWarmupMethodSelection?> chooseRoutineWarmupMethod(
  BuildContext context, {
  required WorkoutRuntimeSettingsController controller,
  required int availableSetSlots,
  required double? workingWeightKg,
  required bool isDumbbell,
}) async {
  await controller.loadWarmupSettings();
  if (!context.mounted) return null;
  final current = controller.warmupSettings;
  if (current == null) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Warm-up methods are unavailable. Try again.'),
    ));
    return null;
  }
  final next = await showWorkoutWarmupMethodsSheet(
    context,
    settings: current,
    availableSetSlots: availableSetSlots,
  );
  if (!context.mounted || next == null) return null;
  try {
    final sets = WorkoutWarmupCalculator.calculateMethod(
      method: next.selectedMethod,
      workingWeightKg: workingWeightKg,
      roundingKg: isDumbbell ? next.dumbbellRoundingKg : next.plateRoundingKg,
    );
    return RoutineWarmupMethodSelection(settings: next, sets: sets);
  } on ArgumentError {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text(
        'Enter a positive working weight before using a percentage method.',
      ),
    ));
    return null;
  }
}

bool isWarmupDumbbellExercise(ExerciseType? type) => const {
      ExerciseType.dumbbellX2Simultaneous,
      ExerciseType.dumbbellX1AlternatingSides,
      ExerciseType.dumbbellX1Simultaneous,
      ExerciseType.dumbbellX2AlternatingLegs,
      ExerciseType.dumbbellX1AlternatingLegs,
    }.contains(type);
