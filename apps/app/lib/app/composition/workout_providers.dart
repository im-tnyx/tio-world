import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tio_feature_workout/workout.dart';
import 'package:tio_feature_auth/auth.dart' show AuthSessionAuthenticated;

import 'auth_providers.dart';

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

/// Persisted user-owned Routines (metadata only in W4A).
/// Null disables the Program Detail entry; never fall back to fake local saves.
final routineRepositoryProvider = Provider<RoutineRepository?>((ref) {
  final client = ref.watch(supabaseClientProvider);
  if (client == null) return null;
  return SupabaseRoutineRepository.fromClient(client);
});

/// Read-only Routine composition persistence (W4A owner-bound Detail).
/// Null means no authenticated durable client, never a fake composition.
final routineCompositionRepositoryProvider =
    Provider<RoutineCompositionRepository?>((ref) {
  final client = ref.watch(supabaseClientProvider);
  if (client == null) return null;
  return SupabaseRoutineCompositionRepository.fromClient(client);
});

/// User-owned Custom Exercise persistence.
///
/// Null means durable user Exercise persistence is unavailable. There is no
/// in-memory production success fallback for user-created Exercises.
final userExerciseRepositoryProvider =
    Provider<UserExerciseRepository?>((ref) {
  final supabaseClient = ref.watch(supabaseClientProvider);
  if (supabaseClient == null) return null;
  return SupabaseUserExerciseRepository(client: supabaseClient);
});

/// Atomic nonempty Routine creation (#535/#536). A null production client is
/// NOT permission to fall back to the legacy metadata-only CREATE route.
final routineCreateRepositoryProvider = Provider<RoutineCreateRepository?>((ref) {
  final client = ref.watch(supabaseClientProvider);
  if (client == null) return null;
  return SupabaseRoutineCreateRepository(client: client);
});

/// Ephemeral owner/login-cycle pending Create identities, not persisted content.
final routinePendingCreateGateProvider = Provider<RoutinePendingCreateGate>(
  (ref) {
    final gate = RoutinePendingCreateGate();
    ref.onDispose(gate.dispose);
    return gate;
  },
);
