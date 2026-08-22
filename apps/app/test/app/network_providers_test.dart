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

void main() {
  group('Network & Auth Providers', () {
    test('providers instantiate with safe unavailable defaults in container', () {
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

      final workoutRepo = container.read(workoutPreferencesRepositoryProvider);
      expect(workoutRepo, isA<WorkoutPreferencesRepository>());

      final nutritionProfileRepo =
          container.read(nutritionProfileRepositoryProvider);
      expect(nutritionProfileRepo, isA<NutritionProfileRepository>());

      final nutritionTargetsRepo =
          container.read(nutritionTargetsRepositoryProvider);
      expect(nutritionTargetsRepo, isA<NutritionTargetsRepository>());

      final targetsRepo = container.read(targetsSetupRepositoryProvider);
      expect(targetsRepo, isA<TargetsSetupRepository>());

      final finalizer = container.read(onboardingRemoteFinalizerProvider);
      expect(finalizer, isA<OnboardingRemoteFinalizer>());
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

    test('Supabase availability selects both canonical Nutrition adapters', () {
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
    });

    test('legacy Targets provider exposes canonical Supabase owner bundle', () {
      final container = ProviderContainer(
        overrides: [
          supabaseClientProvider.overrideWithValue(_FakeSupabaseClient()),
        ],
      );
      addTearDown(container.dispose);

      final legacy = container.read(targetsSetupRepositoryProvider);
      expect(legacy, isA<CanonicalNutritionOwnerRepositories>());
      final bundle = legacy as CanonicalNutritionOwnerRepositories;
      expect(
        bundle.nutritionProfileRepository,
        isA<SupabaseNutritionProfileRepository>(),
      );
      expect(
        bundle.nutritionTargetsRepository,
        isA<SupabaseNutritionTargetsRepository>(),
      );
    });

    test('Body onboarding composition delegates Wellness to the canonical provider',
        () async {
      final canonicalWellness = InMemoryWellnessTargetsRepository();
      final container = ProviderContainer(
        overrides: [
          wellnessTargetsRepositoryProvider.overrideWithValue(canonicalWellness),
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

    test('overriding authCapabilityProvider to available selects FirebaseAuth adapters', () {
      final container = ProviderContainer(
        overrides: [
          authCapabilityProvider.overrideWithValue(const AuthCapabilityAvailable()),
        ],
      );
      addTearDown(container.dispose);

      final sessionRepo = container.read(authSessionRepositoryProvider);
      expect(sessionRepo, isA<FirebaseAuthSessionRepository>());

      final tokenProvider = container.read(authTokenProvider);
      expect(tokenProvider, isA<FirebaseAuthTokenProvider>());
    });

    test('overriding authTokenProvider supplies custom provider to authenticated client', () async {
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

class _FakeSupabaseClient extends Fake implements SupabaseClient {}

class _CustomTokenProvider implements AuthTokenProvider {
  _CustomTokenProvider(this.token);

  final String token;

  @override
  Future<String?> getIdToken({bool forceRefresh = false}) async => token;
}
