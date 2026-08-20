import '../models/profile_settings_update.dart';
import '../repositories/profile_account_repository.dart';
import '../repositories/profile_settings_repository.dart';

/// Coordinates Profile Settings persistence across the existing account and
/// profile ownership boundaries.
class SaveProfileSettingsUseCase {
  const SaveProfileSettingsUseCase({
    required ProfileAccountRepository accountRepository,
    required ProfileSettingsRepository profileSettingsRepository,
  })  : _accountRepository = accountRepository,
        _profileSettingsRepository = profileSettingsRepository;

  final ProfileAccountRepository _accountRepository;
  final ProfileSettingsRepository _profileSettingsRepository;

  Future<void> call({
    required String? persistedUsername,
    required String requestedUsername,
    required ProfileSettingsUpdate update,
  }) async {
    final normalizedPersisted = _normalizeUsername(persistedUsername ?? '');
    final normalizedRequested = _normalizeUsername(requestedUsername);

    if (normalizedRequested != normalizedPersisted) {
      if (normalizedRequested.isEmpty) {
        throw ArgumentError.value(
          requestedUsername,
          'requestedUsername',
          'Username is required.',
        );
      }
      await _accountRepository.updateUsername(normalizedRequested);
    }

    final normalizedName = update.name.trim();
    if (normalizedName.isEmpty) {
      throw ArgumentError.value(update.name, 'name', 'Name is required.');
    }
    if (update.heightCm <= 0) {
      throw ArgumentError.value(
        update.heightCm,
        'heightCm',
        'Height must be greater than zero.',
      );
    }
    if (update.currentWeightKg <= 0) {
      throw ArgumentError.value(
        update.currentWeightKg,
        'currentWeightKg',
        'Current weight must be greater than zero.',
      );
    }

    await _profileSettingsRepository.updateProfileSettings(
      ProfileSettingsUpdate(
        name: normalizedName,
        gender: update.gender,
        dateOfBirth: update.dateOfBirth,
        heightCm: update.heightCm,
        currentWeightKg: update.currentWeightKg,
      ),
    );
  }

  String _normalizeUsername(String value) => value.trim().toLowerCase();
}
