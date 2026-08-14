import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:tio_app/app/onboarding/onboarding.dart';
import 'package:tio_feature_onboarding/onboarding.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  tearDown(() {
    SharedPreferencesAsyncPlatform.instance = null;
  });

  test('missing onboarding status defaults safely', () async {
    final repository = SharedPreferencesOnboardingStatusRepository();

    final snapshot = await repository.read();

    expect(snapshot.status, isNull);
    expect(snapshot.hasStoredContractVersion, isFalse);
  });

  for (final status in OnboardingStatus.values) {
    test('round-trips ${status.name} with stable storage keys', () async {
      final firstRepository = SharedPreferencesOnboardingStatusRepository();
      await firstRepository.write(status);

      final restartedRepository = SharedPreferencesOnboardingStatusRepository();
      final snapshot = await restartedRepository.read();

      expect(snapshot.status, status);
      expect(snapshot.hasStoredContractVersion, isTrue);
    });
  }

  test('treats an unknown stored value as incomplete instead of completed',
      () async {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.withData({
      'onboarding_status_contract_version': 1,
      'onboarding_status': 'unsupported',
    });

    final repository = SharedPreferencesOnboardingStatusRepository();
    final snapshot = await repository.read();

    expect(snapshot.status, isNull);
    expect(snapshot.hasStoredContractVersion, isTrue);
  });

  test('clear removes both status and schema metadata', () async {
    final repository = SharedPreferencesOnboardingStatusRepository();
    await repository.write(OnboardingStatus.inProgress);

    await repository.clear();

    final snapshot = await repository.read();
    expect(snapshot.status, isNull);
    expect(snapshot.hasStoredContractVersion, isFalse);
  });
}
