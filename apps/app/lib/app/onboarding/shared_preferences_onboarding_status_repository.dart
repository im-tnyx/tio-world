import 'package:shared_preferences/shared_preferences.dart';
import 'package:tio_feature_onboarding/onboarding.dart';

class SharedPreferencesOnboardingStatusRepository
    implements OnboardingStatusRepository {
  SharedPreferencesOnboardingStatusRepository({
    SharedPreferencesAsync? preferences,
  }) : _preferences = preferences ?? SharedPreferencesAsync();

  static const _statusKey = 'onboarding_status';
  static const _versionKey = 'onboarding_status_contract_version';
  static const _currentContractVersion = 1;

  final SharedPreferencesAsync _preferences;

  @override
  Future<void> clear() async {
    await _preferences.remove(_statusKey);
    await _preferences.remove(_versionKey);
  }

  @override
  Future<void> ensureInitialized() {
    return _preferences.setInt(_versionKey, _currentContractVersion);
  }

  @override
  Future<OnboardingStatusSnapshot> read() async {
    final version = await _preferences.getInt(_versionKey);
    final value = await _preferences.getString(_statusKey);

    return OnboardingStatusSnapshot(
      status: OnboardingStatus.fromStorageValue(value),
      hasStoredContractVersion: version != null,
    );
  }

  @override
  Future<void> write(OnboardingStatus status) async {
    await ensureInitialized();
    await _preferences.setString(_statusKey, status.storageValue);
  }
}
