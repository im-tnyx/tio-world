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
  return SupabaseRoutineRepository.fromClient(
    client,
    currentLoginCycleId: () {
      try {
        final current = ref.read(authSessionStateProvider);
        final auth = current.isLoading || current.hasError
            ? null : current.valueOrNull;
        if (auth is AuthSessionAuthenticated &&
            auth.session.userId == client.auth.currentUser?.id) {
          return auth.session.loginCycleId;
        }
      } catch (_) {
        // Revoked auth/disposed provider must invalidate stale metadata.
      }
      return null;
    },
  );
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

/// One in-process safety gate for ALL Delete adapters/routes and login cycles.
/// Never key its lifetime to one Routine card or a reconstructed repository.
final routineDeleteAttemptGateProvider = Provider<RoutineDeleteAttemptGate>(
  (ref) => RoutineDeleteAttemptGate(),
);

/// One cross-surface action guard, with business/UI flow owned by Workout.
final routineDeleteFlowProvider = Provider<RoutineDeleteFlow>(
  (ref) => RoutineDeleteFlow(),
);

/// Owner-scoped destructive capability, never an in-memory fallback.
/// Refreshing auth can rebuild this adapter, but the caller-owned attempt
/// gate remains stable for the lifetime of the ProviderContainer.
final routineDeleteRepositoryProvider = Provider<RoutineDeleteRepository?>((ref) {
  final client = ref.watch(supabaseClientProvider);
  final sessionAsync = ref.watch(authSessionStateProvider);
  final auth = sessionAsync.isLoading || sessionAsync.hasError
      ? null : sessionAsync.valueOrNull;
  if (client == null || auth is! AuthSessionAuthenticated ||
      auth.session.userId != client.auth.currentUser?.id) {
    return null;
  }
  return SupabaseRoutineDeleteRepository.fromClient(
    client: client,
    attemptGate: ref.watch(routineDeleteAttemptGateProvider),
    currentLoginCycleId: () {
      // Re-read the LIVE auth cycle; never close over the opening JWT.
      try {
        final value = ref.read(authSessionStateProvider);
        final state = value.isLoading || value.hasError
            ? null : value.valueOrNull;
        if (state is AuthSessionAuthenticated &&
            state.session.userId == client.auth.currentUser?.id) {
          return state.session.loginCycleId;
        }
      } catch (_) {
        // Disposal/session changes revoke this stale adapter capability.
      }
      return null;
    },
  );
});
