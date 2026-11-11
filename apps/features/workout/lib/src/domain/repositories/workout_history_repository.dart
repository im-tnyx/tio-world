import '../models/workout_history_entry.dart';

/// Read-only projection of the canonical W7 WorkoutSession persistence.
abstract interface class WorkoutHistoryRepository {
  Future<WorkoutHistoryPageResult> listCompletedHistory({
    WorkoutHistoryCursor? after,
  });
}
