import '../models/active_workout_draft.dart';

/// Durable local state for the authenticated owner. A failed operation throws.
abstract interface class ActiveWorkoutDraftStore {
  Future<ActiveWorkoutDraft?> load();

  /// Atomically replaces the previously committed revision on this device.
  Future<void> save(ActiveWorkoutDraft draft);

  /// Explicit user discard or confirmed canonical Save only.
  Future<void> delete();
}
