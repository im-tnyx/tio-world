import 'package:flutter/material.dart';

import '../domain/repositories/active_workout_draft_store.dart';
import 'controllers/active_workout_controller.dart';
import 'controllers/active_workout_draft_controller.dart';
import 'controllers/active_workout_state.dart';
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
      final replaced = await _replaceInProgressWorkout(
        draftController: draftController,
        draftStore: draftStore,
        sessionController: sessionController,
      );
      if (!context.mounted || !replaced) return;
      openActive(resumeExisting: false);
  }
}

Future<bool> _hasWorkoutInProgress({
  ActiveWorkoutDraftController? draftController,
  ActiveWorkoutDraftStore? draftStore,
  ActiveWorkoutController? sessionController,
}) async {
  if (sessionController != null) {
    await _ensureSessionRestored(sessionController);
    if (sessionController.state.isRunning) return true;
  }
  if (draftController?.draft != null) return true;
  if (draftStore == null) return false;
  try {
    return await draftStore.load() != null;
  } catch (_) {
    return false;
  }
}

Future<void> _ensureSessionRestored(ActiveWorkoutController controller) async {
  final status = controller.state.status;
  if (status == ActiveWorkoutStatus.initial ||
      status == ActiveWorkoutStatus.restoring) {
    await controller.restoreActiveSession();
  }
}

Future<bool> _replaceInProgressWorkout({
  ActiveWorkoutDraftController? draftController,
  ActiveWorkoutDraftStore? draftStore,
  ActiveWorkoutController? sessionController,
}) async {
  // Fail closed: memory and durable draft must both be gone before Start new.
  // Clearing the store alone is not enough while an in-memory draft can still
  // commit a later mutation and resurrect the workout.
  if (draftController != null) {
    final cleared = await draftController.discardForReplacement();
    if (!cleared || draftController.draft != null) return false;
  } else if (draftStore != null) {
    try {
      await draftStore.delete();
    } catch (_) {
      return false;
    }
  }

  if (draftStore != null) {
    try {
      if (await draftStore.load() != null) return false;
    } catch (_) {
      return false;
    }
  }

  if (sessionController != null) {
    await _ensureSessionRestored(sessionController);
    if (sessionController.state.isRunning) {
      final discarded = await sessionController.discardSession(
        reason: 'replaced_by_new_workout',
      );
      if (!discarded && sessionController.state.isRunning) {
        return false;
      }
    }
  }

  return true;
}
