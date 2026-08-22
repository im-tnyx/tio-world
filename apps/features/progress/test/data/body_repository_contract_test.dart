import 'package:flutter_test/flutter_test.dart';
import 'package:tio_feature_progress/progress.dart';

void main() {
  test('weight provenance values are stable domain semantics', () {
    expect(BodyWeightSources.onboardingSetup, 'onboarding_setup');
    expect(BodyWeightSources.profileSettings, 'profile_settings');
  });

  test('post-onboarding history command cannot impersonate onboarding retry',
      () async {
    final repository = InMemoryBodySetupRepository();

    await expectLater(
      () => repository.recordCurrentWeight(
        BodyWeightRecord(
          weightKg: 79,
          measuredAt: DateTime.utc(2026, 8, 21, 18),
          source: BodyWeightSources.onboardingSetup,
        ),
      ),
      throwsArgumentError,
    );

    expect(repository.weightEntries, isEmpty);
  });

  test('profile settings provenance records a new post-onboarding history row',
      () async {
    final repository = InMemoryBodySetupRepository(
      now: () => DateTime.utc(2026, 8, 21, 10),
    );

    await repository.saveBodySetup(
      const BodySetupData(currentWeightKg: 80),
    );
    await repository.recordCurrentWeight(
      BodyWeightRecord(
        weightKg: 79,
        measuredAt: DateTime.utc(2026, 8, 21, 18),
        source: BodyWeightSources.profileSettings,
      ),
    );

    expect(repository.weightEntries, hasLength(2));
    final state = await repository.getBodyState();
    expect(state.latestWeight?.weightKg, 79);
    expect(state.latestWeight?.source, BodyWeightSources.profileSettings);
  });
}
