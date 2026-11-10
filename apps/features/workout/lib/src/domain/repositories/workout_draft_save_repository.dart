import 'package:tio_shared/shared.dart';

import '../models/active_workout_draft.dart';

/// Canonical completed-session read model for a Save-only workout.
/// The data comes from the existing session and performed-set tables.
final class SavedWorkoutDraftRecord {
  const SavedWorkoutDraftRecord({
    required this.sessionId,
    required this.ownerId,
    required this.saveRequestId,
    required this.revision,
    required this.title,
    required this.workoutAtUtc,
    required this.utcOffsetMinutes,
    required this.localDate,
    required this.description,
    required this.activityType,
    required this.gymName,
    required this.overallRpe,
    required this.durationSeconds,
    required this.snapshot,
    required this.performedSets,
  });

  final WorkoutSessionId sessionId;
  final String ownerId;
  final String saveRequestId;
  final int revision;
  final String title;
  final DateTime workoutAtUtc;
  final int utcOffsetMinutes;
  final String localDate;
  final String? description;
  final String? activityType;
  final String? gymName;
  final double? overallRpe;
  final int durationSeconds;
  final Map<String, dynamic> snapshot;
  final List<PerformedSet> performedSets;
}

/// One atomic Save followed by an owner-scoped canonical readback.
abstract interface class WorkoutDraftSaveRepository {
  Future<SavedWorkoutDraftRecord> saveDraft(ActiveWorkoutDraft draft);

  Future<SavedWorkoutDraftRecord?> getSavedDraft(WorkoutSessionId sessionId);
}
