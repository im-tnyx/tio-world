import 'package:flutter/material.dart';

import '../domain/repositories/active_workout_draft_store.dart';
import 'controllers/active_workout_controller.dart';
import 'controllers/active_workout_draft_controller.dart';
import 'controllers/active_workout_state.dart';
import 'widgets/workout_in_progress_dialog.dart';

enum _WorkoutPresence {
  absent,
  present,

  /// Secure-storage/keychain read failed. Do not treat as empty.
  unknown,
}

/// Opens Active Workout while guarding against duplicate starts.
///
/// When a local draft or running legacy session already exists, presents the
/// owner conflict card. Resume never creates a new draft; Start new permanently
/// replaces the old workout first.
///
/// An unreadable durable draft is fail-closed: Play does not open a fresh
/// workout and does not invent recovery UI.
Future<void> runWorkoutPlayStart({
  required BuildContext context,
  required void Function({required bool resumeExisting}) openActive,
  ActiveWorkoutDraftController? draftController,
  ActiveWorkoutDraftStore? draftStore,
  ActiveWorkoutController? sessionController,
  Future<bool> Function()? prepareNewWorkout,
}) async {
  final presence = await _workoutPresence(
    draftController: draftController,
    draftStore: draftStore,
    sessionController: sessionController,
  );
  if (!context.mounted) return;

  switch (presence) {
    case _WorkoutPresence.unknown:
      return;
    case _WorkoutPresence.absent:
      if (prepareNewWorkout != null) {
        final prepared = await prepareNewWorkout();
        if (!prepared) return;
      }
      if (!context.mounted) return;
      openActive(resumeExisting: false);
      return;
    case _WorkoutPresence.present:
      break;
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
      if (prepareNewWorkout != null) {
        final prepared = await prepareNewWorkout();
        if (!prepared) return;
      }
      if (!context.mounted) return;
      openActive(resumeExisting: false);
  }
}

Future<_WorkoutPresence> _workoutPresence({
  ActiveWorkoutDraftController? draftController,
  ActiveWorkoutDraftStore? draftStore,
  ActiveWorkoutController? sessionController,
}) async {
  if (sessionController != null) {
    await _ensureSessionRestored(sessionController);
    if (sessionController.state.isRunning) return _WorkoutPresence.present;
  }
  if (draftController?.draft != null) return _WorkoutPresence.present;
  if (draftStore == null) return _WorkoutPresence.absent;
  try {
    return await draftStore.load() != null
        ? _WorkoutPresence.present
        : _WorkoutPresence.absent;
  } catch (_) {
    // Transient secure-storage failure must not look like "no workout".
    return _WorkoutPresence.unknown;
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
