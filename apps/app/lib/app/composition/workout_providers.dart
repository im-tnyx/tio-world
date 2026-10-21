import 'package:flutter/foundation.dart' show kDebugMode;
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
  final sessionAsync = ref.watch(authSessionStateProvider);
  final auth = sessionAsync.isLoading || sessionAsync.hasError
      ? null : sessionAsync.valueOrNull;
  if (client == null || auth is! AuthSessionAuthenticated ||
      auth.session.userId != client.auth.currentUser?.id) {
    return null;
  }
  return SupabaseRoutineRepository.fromClient(
    client,
    crossOperationGate: ref.watch(routineMoveDeleteAttemptGateProvider),
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
  return SupabaseRoutineCompositionRepository.fromClient(
    client,
    crossOperationGate: ref.watch(routineMoveDeleteAttemptGateProvider),
  );
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

/// #568 first-Routine release hold. The hosted atomic default resolver exists,
/// but its authenticated EXECUTE grant remains revoked. Tests may override this
/// capability; a normal production build must never expose a broken write path.
final myProgramRoutineCreateReleaseEnabledProvider =
    Provider<bool>((ref) => false);

/// The staged atomic adapter is owner/login-cycle bound, with no local Program
/// INSERT or metadata-only fallback. A captured prior-session adapter loses
/// authority as soon as bootstrap/Auth/SDK identity changes.
final myProgramRoutineCreateRepositoryProvider =
    Provider<MyProgramRoutineCreateRepository?>((ref) {
  final client = ref.watch(supabaseClientProvider);
  final session = ref.watch(authSessionStateProvider);
  final auth = session.isLoading || session.hasError
      ? null : session.valueOrNull;
  if (client == null || auth is! AuthSessionAuthenticated ||
      auth.session.userId != client.auth.currentUser?.id ||
      auth.session.loginCycleId.trim().isEmpty) {
    return null;
  }
  final owner = auth.session.userId;
  final cycle = auth.session.loginCycleId;
  return SupabaseMyProgramRoutineCreateRepository(
    client: client,
    currentUserId: () {
      try {
        final current = ref.read(authSessionStateProvider);
        final state = current.isLoading || current.hasError
            ? null : current.valueOrNull;
        if (state is AuthSessionAuthenticated &&
            state.session.userId == owner &&
            state.session.loginCycleId == cycle &&
            client.auth.currentUser?.id == owner) {
          return owner;
        }
      } catch (_) {
        // A disposed or revoked session cannot dispatch an old owner's RPC.
      }
      return null;
    },
  );
});

/// Ephemeral owner/login-cycle pending Create identities, not persisted content.
final routinePendingCreateGateProvider = Provider<RoutinePendingCreateGate>(
  (ref) {
    final gate = RoutinePendingCreateGate();
    ref.onDispose(gate.dispose);
    return gate;
  },
);

/// Explicit production release hold for Routine Move #569.
/// Keep false until M3D3 owner-safe cross-operation/list reconciliation,
/// hosted atomic Create+Move RPC + least-privilege grants and device QA pass.
/// The app shell may prepare Move closures, but it must not expose a 3-dot
/// capability while any one of those release gates is incomplete.
final routineMoveReleaseEnabledProvider = Provider<bool>((ref) => false);

/// Opt-in visual QA of the existing Move selector on an Android/iOS DEBUG APK.
/// Neither profile/release builds nor ordinary debug builds expose it.
/// This is intentionally independent of the actual-write release capability;
/// RoutineMoveFlow must intercept both Move dispatch paths in preview mode.
final routineMoveUiPreviewEnabledProvider = Provider<bool>((ref) =>
    kDebugMode &&
    const bool.fromEnvironment('TIO_MOVE_ROUTINE_UI_PREVIEW',
        defaultValue: false));

/// Shared process-local Move/Delete arbitration, not a server CAS substitute.
final routineMoveDeleteAttemptGateProvider =
    Provider<RoutineMoveDeleteAttemptGate>(
  (ref) => RoutineMoveDeleteAttemptGate(),
);

/// Shared across all Routine Move routes, owners and login cycles.
final routineMoveAttemptGateProvider = Provider<RoutineMoveAttemptGate>(
  (ref) => RoutineMoveAttemptGate(),
);

/// Feature-owned modal flow; no Routine card calls it in this slice.
final routineMoveFlowProvider = Provider<RoutineMoveFlow>(
  (ref) => RoutineMoveFlow(),
);

/// Read-only cross-surface Program/Routine invalidation after a Move attempt.
/// One owner/login-cycle event; never proof of a committed Move or a retry.
final routineMoveRefreshSignalProvider = Provider<RoutineMoveRefreshSignal>((ref) {
  final signal = RoutineMoveRefreshSignal();
  ref.onDispose(signal.dispose);
  return signal;
});

/// Dormant owner/login-cycle-bound Move and atomic Create+Move adapter.
/// A captured old repository must NOT gain new-owner write authority.
final routineMoveRepositoryProvider =
    Provider<SupabaseRoutineMoveRepository?>((ref) {
  final client = ref.watch(supabaseClientProvider);
  final sessionAsync = ref.watch(authSessionStateProvider);
  final auth = sessionAsync.isLoading || sessionAsync.hasError
      ? null : sessionAsync.valueOrNull;
  if (client == null || auth is! AuthSessionAuthenticated ||
      auth.session.userId != client.auth.currentUser?.id) {
    return null;
  }
  final owner = auth.session.userId;
  final cycle = auth.session.loginCycleId;
  if (cycle == null || cycle.trim().isEmpty) return null;
  return SupabaseRoutineMoveRepository.fromClient(
    client: client,
    attemptGate: ref.watch(routineMoveAttemptGateProvider),
    crossOperationGate: ref.watch(routineMoveDeleteAttemptGateProvider),
    // Share only the owner-scoped pending bit, never a Create draft.
    pendingCreateForProgram: (owner, programId) =>
        ref.read(routinePendingCreateGateProvider)
            .hasPendingForOwnerProgram(owner: owner, programId: programId),
    currentLoginCycleId: () {
      try {
        final live = ref.read(authSessionStateProvider);
        final state = live.isLoading || live.hasError
            ? null : live.valueOrNull;
        if (state is AuthSessionAuthenticated &&
            state.session.userId == owner &&
            state.session.loginCycleId == cycle &&
            client.auth.currentUser?.id == owner) {
          return cycle;
        }
      } catch (_) {
        // Revoked/disposed session must not authorize an old adapter.
      }
      return null;
    },
  );
});

/// Same repository object and gate for both Move variants.
final routineCreateMoveRepositoryProvider =
    Provider<RoutineCreateMoveRepository?>((ref) {
  return ref.watch(routineMoveRepositoryProvider);
});

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
    crossOperationGate: ref.watch(routineMoveDeleteAttemptGateProvider),
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
