import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tio_app/app/network_providers.dart';
import 'package:tio_feature_auth/auth.dart';
import 'package:tio_feature_nutrition/nutrition.dart';
import 'package:tio_feature_onboarding/onboarding.dart';
import 'package:tio_feature_profile/profile.dart';
import 'package:tio_feature_progress/progress.dart';
import 'package:tio_feature_workout/workout.dart';
import 'package:tio_shared/shared.dart';

final _moveSessionProvider = StateProvider<AuthSessionState>(
  (ref) => const AuthSessionUnauthenticated(),
);

ProviderContainer _moveContainer(
  _MoveAuth auth, AuthSessionState initial,
) => ProviderContainer(overrides: [
  supabaseClientProvider.overrideWithValue(_MoveClient(auth)),
  _moveSessionProvider.overrideWith((ref) => initial),
  authSessionStateProvider.overrideWith(
    (ref) => Stream.value(ref.watch(_moveSessionProvider)),
  ),
]);

void main() {
  test('Move denies missing, mismatched or incomplete authenticated sessions',
      () async {
    const owner = '11111111-1111-4111-8111-111111111111';
    const other = '22222222-2222-4222-8222-222222222222';
    for (final state in <AuthSessionState>[
      const AuthSessionUnauthenticated(),
      const AuthSessionUnknown(),
      const AuthSessionAuthenticated(
          AuthSession(userId: other, loginCycleId: 'cycle-a')),
      const AuthSessionAuthenticated(AuthSession(userId: owner)),
      const AuthSessionAuthenticated(
          AuthSession(userId: owner, loginCycleId: '')),
    ]) {
      final c = _moveContainer(_MoveAuth(_moveUser(owner)), state);
      await c.read(authSessionStateProvider.future);
      expect(c.read(routineMoveRepositoryProvider), isNull);
      expect(c.read(routineCreateMoveRepositoryProvider), isNull);
      c.dispose();
    }
    final c = _moveContainer(_MoveAuth(null),
      const AuthSessionAuthenticated(
          AuthSession(userId: owner, loginCycleId: 'cycle-a')));
    addTearDown(c.dispose);
    await c.read(authSessionStateProvider.future);
    expect(c.read(routineMoveRepositoryProvider), isNull);
  });

  test('Routine Delete fails closed without Supabase and retains shared gate', () {
    final container = ProviderContainer(overrides: [
      supabaseClientProvider.overrideWithValue(null),
    ]);
    addTearDown(container.dispose);
    final gate = container.read(routineDeleteAttemptGateProvider);
    final flow = container.read(routineDeleteFlowProvider);
    expect(container.read(routineDeleteRepositoryProvider), isNull);
    container.invalidate(routineDeleteRepositoryProvider);
    expect(container.read(routineDeleteRepositoryProvider), isNull);
    expect(identical(container.read(routineDeleteAttemptGateProvider), gate),
        isTrue, reason: 'attempt state must outlive repository recreation');
    expect(identical(container.read(routineDeleteFlowProvider), flow), isTrue,
        reason: 'Program and Library must share one action single-flight');
  });
  test('Move release capability is OFF even with valid auth', () async {
    const owner = '11111111-1111-4111-8111-111111111111';
    final c = _moveContainer(
      _MoveAuth(_moveUser(owner)),
      const AuthSessionAuthenticated(
        AuthSession(userId: owner, loginCycleId: 'cycle-a')),
    );
    addTearDown(c.dispose);
    await c.read(authSessionStateProvider.future);
    expect(c.read(routineMoveRepositoryProvider), isNotNull);
    expect(c.read(routineCreateMoveRepositoryProvider), isNotNull);
    expect(c.read(routineMoveReleaseEnabledProvider), isFalse,
        reason: 'backend + cross-mutation/refresh/device gates are not met');
    c.invalidate(routineMoveReleaseEnabledProvider);
    expect(c.read(routineMoveReleaseEnabledProvider), isFalse,
        reason: 'provider refresh must not enable a release capability');
  });

  test('Routine Move stays dormant without an authenticated Supabase client', () {
    final container = ProviderContainer(overrides: [
      supabaseClientProvider.overrideWithValue(null),
    ]);
    addTearDown(container.dispose);
    final gate = container.read(routineMoveAttemptGateProvider);
    final flow = container.read(routineMoveFlowProvider);
    expect(container.read(routineMoveRepositoryProvider), isNull);
    expect(container.read(routineCreateMoveRepositoryProvider), isNull);
    container.invalidate(routineMoveRepositoryProvider);
    expect(container.read(routineMoveRepositoryProvider), isNull);
    expect(identical(container.read(routineMoveAttemptGateProvider), gate), isTrue);
    expect(identical(container.read(routineMoveFlowProvider), flow), isTrue);
  });

  test('Move repository shares both capabilities, not the login-cycle state',
      () async {
    const owner = '11111111-1111-4111-8111-111111111111';
    final auth = _MoveAuth(_moveUser(owner));
    final c = _moveContainer(auth, const AuthSessionAuthenticated(
        AuthSession(userId: owner, loginCycleId: 'cycle-a')));
    addTearDown(c.dispose);
    await c.read(authSessionStateProvider.future);
    final gate = c.read(routineMoveAttemptGateProvider);
    final flow = c.read(routineMoveFlowProvider);
    final original = c.read(routineMoveRepositoryProvider)!;
    expect(identical(c.read(routineCreateMoveRepositoryProvider), original),
        isTrue);
    c.read(_moveSessionProvider.notifier).state =
        const AuthSessionAuthenticated(
            AuthSession(userId: owner, loginCycleId: 'cycle-b'));
    await c.read(authSessionStateProvider.future);
    c.invalidate(routineMoveRepositoryProvider);
    final replacement = c.read(routineMoveRepositoryProvider);
    expect(replacement, isA<SupabaseRoutineMoveRepository>());
    expect(identical(replacement, original), isFalse);
    expect(identical(c.read(routineCreateMoveRepositoryProvider), replacement),
        isTrue);
    expect(identical(c.read(routineMoveAttemptGateProvider), gate), isTrue);
    expect(identical(c.read(routineMoveFlowProvider), flow), isTrue);
    await expectLater(original.inspect(
      sourceProgramId: ProgramId('33333333-3333-4333-8333-333333333333'),
      routineId: RoutineId('44444444-4444-4444-8444-444444444444'),
    ), throwsA(isA<RoutineMoveException>().having(
        (e) => e.kind, 'kind', RoutineMoveFailureKind.unauthorized)));
  });

  test('Move rejects captured A adapter after logout and account B login',
      () async {
    const ownerA = '11111111-1111-4111-8111-111111111111';
    const ownerB = '22222222-2222-4222-8222-222222222222';
    final auth = _MoveAuth(_moveUser(ownerA));
    final c = _moveContainer(auth, const AuthSessionAuthenticated(
        AuthSession(userId: ownerA, loginCycleId: 'cycle-a')));
    addTearDown(c.dispose);
    await c.read(authSessionStateProvider.future);
    final old = c.read(routineMoveRepositoryProvider)!;
    final gate = c.read(routineMoveAttemptGateProvider);

    auth.currentUser = null;
    c.read(_moveSessionProvider.notifier).state =
        const AuthSessionUnauthenticated();
    await c.read(authSessionStateProvider.future);
    expect(c.read(routineMoveRepositoryProvider), isNull);
    await expectLater(old.inspect(
      sourceProgramId: ProgramId('33333333-3333-4333-8333-333333333333'),
      routineId: RoutineId('44444444-4444-4444-8444-444444444444'),
    ), throwsA(isA<RoutineMoveException>().having(
        (e) => e.kind, 'kind', RoutineMoveFailureKind.unauthorized)));

    auth.currentUser = _moveUser(ownerB);
    c.read(_moveSessionProvider.notifier).state =
        const AuthSessionAuthenticated(
            AuthSession(userId: ownerB, loginCycleId: 'cycle-b'));
    await c.read(authSessionStateProvider.future);
    final newRepo = c.read(routineMoveRepositoryProvider);
    expect(newRepo, isA<SupabaseRoutineMoveRepository>());
    expect(identical(old, newRepo), isFalse);
    expect(identical(c.read(routineCreateMoveRepositoryProvider), newRepo),
        isTrue);
    expect(identical(c.read(routineMoveAttemptGateProvider), gate), isTrue);
    await expectLater(old.inspect(
      sourceProgramId: ProgramId('33333333-3333-4333-8333-333333333333'),
      routineId: RoutineId('44444444-4444-4444-8444-444444444444'),
    ), throwsA(isA<RoutineMoveException>().having(
        (e) => e.kind, 'kind', RoutineMoveFailureKind.unauthorized)));
  });

  group('Network & Auth Providers', () {
    test('providers instantiate with safe unavailable defaults in container',
        () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final config = container.read(apiConfigProvider);
      expect(config.baseUrl, isNotEmpty);

      final capability = container.read(authCapabilityProvider);
      expect(capability.isAvailable, isFalse);
      expect(capability, isA<AuthCapabilityUnavailable>());

      final sessionRepo = container.read(authSessionRepositoryProvider);
      expect(sessionRepo, isA<InMemoryAuthSessionRepository>());

      final tokenProvider = container.read(authTokenProvider);
      expect(tokenProvider, isA<UnavailableAuthTokenProvider>());

      final authClient = container.read(authenticatedApiClientProvider);
      expect(authClient, isA<ApiClient>());

      final publicClient = container.read(publicApiClientProvider);
      expect(publicClient, isA<ApiClient>());

      final profileRepo = container.read(profileSetupRepositoryProvider);
      expect(profileRepo, isA<ProfileSetupRepository>());

      final wellnessRepo = container.read(wellnessTargetsRepositoryProvider);
      expect(wellnessRepo, isA<WellnessTargetsRepository>());

      final workoutProfileRepo =
          container.read(workoutProfileRepositoryProvider);
      expect(workoutProfileRepo, isA<InMemoryWorkoutProfileRepository>());

      final workoutTargetsRepo =
          container.read(workoutTargetsRepositoryProvider);
      expect(workoutTargetsRepo, isA<InMemoryWorkoutTargetsRepository>());
      expect(container.read(programRepositoryProvider), isNull);
      expect(container.read(userExerciseRepositoryProvider), isNull);

      final nutritionProfileRepo =
          container.read(nutritionProfileRepositoryProvider);
      expect(nutritionProfileRepo, isA<NutritionProfileRepository>());

      final nutritionTargetsRepo =
          container.read(nutritionTargetsRepositoryProvider);
      expect(nutritionTargetsRepo, isA<NutritionTargetsRepository>());

      final mealCategoriesRepo =
          container.read(mealCategoriesRepositoryProvider);
      expect(mealCategoriesRepo, isA<MealCategoriesRepository>());

      final mealTextParseRepo =
          container.read(mealTextParseRepositoryProvider);
      expect(mealTextParseRepo, isNull);

      final finalizer = container.read(onboardingRemoteFinalizerProvider);
      expect(finalizer, isA<OnboardingRemoteFinalizer>());
    });

    test('O9A finalization durability truth table fails closed', () {
      final unavailable = buildAppOnboardingCompletionValidator(
        hasSupabaseClient: false,
        hasAuthenticatedSupabaseUser: false,
      );
      expect(unavailable.hasDurableOwnerPersistence, isFalse);
      expect(unavailable.backendUserReady, isFalse);

      final unauthenticated = buildAppOnboardingCompletionValidator(
        hasSupabaseClient: true,
        hasAuthenticatedSupabaseUser: false,
      );
      expect(unauthenticated.hasDurableOwnerPersistence, isTrue);
      expect(unauthenticated.backendUserReady, isFalse);

      final authenticated = buildAppOnboardingCompletionValidator(
        hasSupabaseClient: true,
        hasAuthenticatedSupabaseUser: true,
      );
      expect(authenticated.hasDurableOwnerPersistence, isTrue);
      expect(authenticated.backendUserReady, isTrue);
    });

    test(
        'no-Supabase app completion validator blocks in-memory owner fallbacks',
        () {
      final container = ProviderContainer(
        overrides: [
          supabaseClientProvider.overrideWithValue(null),
        ],
      );
      addTearDown(container.dispose);

      expect(
        container.read(workoutProfileRepositoryProvider),
        isA<InMemoryWorkoutProfileRepository>(),
      );
      expect(
        container.read(workoutTargetsRepositoryProvider),
        isA<InMemoryWorkoutTargetsRepository>(),
      );
      expect(container.read(programRepositoryProvider), isNull);
      expect(container.read(userExerciseRepositoryProvider), isNull);
      expect(
        container.read(nutritionProfileRepositoryProvider),
        isA<InMemoryNutritionProfileRepository>(),
      );
      expect(
        container.read(nutritionTargetsRepositoryProvider),
        isA<InMemoryNutritionTargetsRepository>(),
      );
      expect(
        container.read(mealCategoriesRepositoryProvider),
        isA<InMemoryMealCategoriesRepository>(),
      );
      expect(
        container.read(mealTextParseRepositoryProvider),
        isNull,
      );

      final validator =
          container.read(appOnboardingCompletionValidatorProvider);
      expect(validator.hasDurableOwnerPersistence, isFalse);
      expect(validator.backendUserReady, isFalse);

      final eligibility = validator.evaluate(
        draft: OnboardingDraft(selectedMode: AppMode.workout),
        flowPlan: const BuildOnboardingFlowUseCase()(
          entryPath: OnboardingEntryPath.firstRun,
          mode: AppMode.workout,
        ),
      );
      expect(eligibility.isEligible, isFalse);
      expect(eligibility.message, contains('durable owner persistence'));
    });

    test('Supabase availability selects the canonical Wellness adapter', () {
      final container = ProviderContainer(
        overrides: [
          supabaseClientProvider.overrideWithValue(_FakeSupabaseClient()),
        ],
      );
      addTearDown(container.dispose);

      expect(
        container.read(wellnessTargetsRepositoryProvider),
        isA<SupabaseWellnessTargetsRepository>(),
      );
    });

    test('Supabase availability selects canonical Workout adapters', () {
      final container = ProviderContainer(
        overrides: [
          supabaseClientProvider.overrideWithValue(_FakeSupabaseClient()),
        ],
      );
      addTearDown(container.dispose);

      expect(
        container.read(workoutProfileRepositoryProvider),
        isA<SupabaseWorkoutProfileRepository>(),
      );
      expect(
        container.read(workoutTargetsRepositoryProvider),
        isA<SupabaseWorkoutTargetsRepository>(),
      );
      expect(
        container.read(programRepositoryProvider),
        isA<SupabaseProgramRepository>(),
      );
      expect(
        container.read(userExerciseRepositoryProvider),
        isA<SupabaseUserExerciseRepository>(),
      );
    });

    test('Supabase availability selects canonical Nutrition adapters', () {
      final container = ProviderContainer(
        overrides: [
          supabaseClientProvider.overrideWithValue(_FakeSupabaseClient()),
        ],
      );
      addTearDown(container.dispose);

      expect(
        container.read(nutritionProfileRepositoryProvider),
        isA<SupabaseNutritionProfileRepository>(),
      );
      expect(
        container.read(nutritionTargetsRepositoryProvider),
        isA<SupabaseNutritionTargetsRepository>(),
      );
      expect(
        container.read(mealCategoriesRepositoryProvider),
        isA<SupabaseMealCategoriesRepository>(),
      );
    });

    test('Supabase availability selects the Supabase meal-text parser', () {
      final container = ProviderContainer(
        overrides: [
          supabaseClientProvider.overrideWithValue(_FakeSupabaseClient()),
        ],
      );
      addTearDown(container.dispose);

      expect(
        container.read(mealTextParseRepositoryProvider),
        isA<SupabaseMealTextParseRepository>(),
      );
    });

    test(
        'Body onboarding composition delegates Wellness to the canonical provider',
        () async {
      final canonicalWellness = InMemoryWellnessTargetsRepository();
      final container = ProviderContainer(
        overrides: [
          wellnessTargetsRepositoryProvider
              .overrideWithValue(canonicalWellness),
        ],
      );
      addTearDown(container.dispose);

      final bodyRepository = container.read(bodySetupRepositoryProvider);
      expect(bodyRepository, isA<WellnessTargetsRepository>());

      final onboardingWellness = bodyRepository as WellnessTargetsRepository;
      const expected = WellnessTargetsData(
        dailySteps: 11111,
        waterMl: 2777,
        sleepTargetMinutes: 455,
        bedTimeMinutes: 1390,
        wakeTimeMinutes: 410,
      );

      await onboardingWellness.upsert(expected);

      expect(await canonicalWellness.read(), expected);
      expect(
        await container.read(wellnessTargetsRepositoryProvider).read(),
        expected,
      );
    });

    test(
        'overriding authCapabilityProvider to available selects FirebaseAuth adapters',
        () {
      final container = ProviderContainer(
        overrides: [
          authCapabilityProvider
              .overrideWithValue(const AuthCapabilityAvailable()),
        ],
      );
      addTearDown(container.dispose);

      final sessionRepo = container.read(authSessionRepositoryProvider);
      expect(sessionRepo, isA<FirebaseAuthSessionRepository>());

      final tokenProvider = container.read(authTokenProvider);
      expect(tokenProvider, isA<FirebaseAuthTokenProvider>());
    });

    test(
        'overriding authTokenProvider supplies custom provider to authenticated client',
        () async {
      final customTokenProvider = _CustomTokenProvider('mock-token-xyz');
      final container = ProviderContainer(
        overrides: [
          authTokenProvider.overrideWithValue(customTokenProvider),
        ],
      );
      addTearDown(container.dispose);

      final tokenProvider = container.read(authTokenProvider);
      expect(await tokenProvider.getIdToken(), 'mock-token-xyz');
    });
  });
}

class _MoveClient extends Fake implements SupabaseClient {
  _MoveClient(this.fakeAuth);
  final _MoveAuth fakeAuth;
  @override
  GoTrueClient get auth => fakeAuth;
}

class _MoveAuth extends Fake implements GoTrueClient {
  _MoveAuth(this.currentUser);
  @override
  User? currentUser;
}

User _moveUser(String id) => User(
  id: id,
  appMetadata: const {},
  userMetadata: const {},
  aud: 'authenticated',
  createdAt: '2026-10-18T00:00:00Z',
);

class _FakeSupabaseClient extends Fake implements SupabaseClient {}

class _CustomTokenProvider implements AuthTokenProvider {
  _CustomTokenProvider(this.token);

  final String token;

  @override
  Future<String?> getIdToken({bool forceRefresh = false}) async => token;
}
