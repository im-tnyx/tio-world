import 'package:flutter/material.dart';

import '../domain/repositories/active_workout_draft_store.dart';
import 'controllers/active_workout_controller.dart';
import 'controllers/active_workout_draft_controller.dart';
import 'widgets/workout_in_progress_dialog.dart';

/// Opens Active Workout from Play, guarding against duplicate starts.
///
/// When a local draft or running legacy session already exists, presents the
/// owner conflict card. Resume never creates a new draft; Start new permanently
/// replaces the old workout first.
Future<void> runWorkoutPlayStart({
  required BuildContext context,
  required void Function({required bool resumeExisting}) openActive,
  ActiveWorkoutDraftController? draftController,
  ActiveWorkoutDraftStore? draftStore,
  ActiveWorkoutController? sessionController,
}) async {
  final inProgress = await _hasWorkoutInProgress(
    draftController: draftController,
    draftStore: draftStore,
    sessionController: sessionController,
  );
  if (!context.mounted) return;

  if (!inProgress) {
    openActive(resumeExisting: false);
    return;
  }

  final action = await showWorkoutInProgressDialog(context);
  if (!context.mounted) return;
  switch (action) {
    case null:
    case WorkoutInProgressAction.cancel:
      return;
    case WorkoutInProgressAction.resume:
      openActive(resumeExisting: true);
      return;
    case WorkoutInProgressAction.startNew:
      await _replaceInProgressWorkout(
        draftController: draftController,
        draftStore: draftStore,
        sessionController: sessionController,
      );
      if (!context.mounted) return;
      openActive(resumeExisting: false);
  }
}

Future<bool> _hasWorkoutInProgress({
  ActiveWorkoutDraftController? draftController,
  ActiveWorkoutDraftStore? draftStore,
  ActiveWorkoutController? sessionController,
}) async {
  if (sessionController?.state.isRunning == true) return true;
  if (draftController?.draft != null) return true;
  if (draftStore == null) return false;
  try {
    return await draftStore.load() != null;
  } catch (_) {
    return false;
  }
}

Future<void> _replaceInProgressWorkout({
  ActiveWorkoutDraftController? draftController,
  ActiveWorkoutDraftStore? draftStore,
  ActiveWorkoutController? sessionController,
}) async {
  if (draftController != null) {
    await draftController.discardForReplacement();
  } else if (draftStore != null) {
    try {
      await draftStore.delete();
    } catch (_) {}
  }

  final session = sessionController;
  if (session != null && session.state.isRunning) {
    await session.discardSession(reason: 'replaced_by_new_workout');
  }
}
