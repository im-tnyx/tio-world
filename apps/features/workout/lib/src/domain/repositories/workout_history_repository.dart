import '../models/workout_history_entry.dart';
import 'package:tio_shared/shared.dart';

/// Read-only projection of the canonical W7 WorkoutSession persistence.
abstract interface class WorkoutHistoryRepository {
  Future<WorkoutHistoryPageResult> listCompletedHistory({
    WorkoutHistoryCursor? after,
  });

  Future<WorkoutHistoryDetail?> getCompletedHistoryDetail(
    WorkoutSessionId sessionId,
  );
}
