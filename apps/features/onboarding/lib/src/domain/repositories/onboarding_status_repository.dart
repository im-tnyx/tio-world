import '../models/models.dart';

abstract interface class OnboardingStatusRepository {
  Future<OnboardingStatusSnapshot> read();

  Future<void> ensureInitialized();

  Future<void> write(OnboardingStatus status);

  Future<void> clear();
}

class NoOpOnboardingStatusRepository implements OnboardingStatusRepository {
  const NoOpOnboardingStatusRepository();

  @override
  Future<void> clear() async {}

  @override
  Future<void> ensureInitialized() async {}

  @override
  Future<OnboardingStatusSnapshot> read() async {
    return const OnboardingStatusSnapshot(
      status: null,
      hasStoredContractVersion: false,
    );
  }

  @override
  Future<void> write(OnboardingStatus status) async {}
}
