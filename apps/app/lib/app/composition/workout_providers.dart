import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tio_feature_workout/workout.dart';

import 'runtime_providers.dart';

/// Canonical Workout Profile owner used by Product Onboarding completion.
final workoutProfileRepositoryProvider =
    Provider<WorkoutProfileRepository>((ref) {
  final supabaseClient = ref.watch(supabaseClientProvider);
  if (supabaseClient != null) {
    return SupabaseWorkoutProfileRepository(client: supabaseClient);
  }
  return InMemoryWorkoutProfileRepository();
});

/// Canonical Workout Targets owner used by Product Onboarding completion.
final workoutTargetsRepositoryProvider =
    Provider<WorkoutTargetsRepository>((ref) {
  final supabaseClient = ref.watch(supabaseClientProvider);
  if (supabaseClient != null) {
    return SupabaseWorkoutTargetsRepository(client: supabaseClient);
  }
  return InMemoryWorkoutTargetsRepository();
});

/// User-owned Program persistence.
///
/// Unlike onboarding-era profile/target adapters, Programs must never report a
/// production success through an in-memory fallback. Null means durable Program
/// persistence is unavailable and the Programs screen fails closed.
final programRepositoryProvider = Provider<ProgramRepository?>((ref) {
  final supabaseClient = ref.watch(supabaseClientProvider);
  if (supabaseClient == null) return null;
  return SupabaseProgramRepository(client: supabaseClient);
});
