import 'package:flutter_test/flutter_test.dart';
import 'package:tio_feature_profile/profile.dart';

void main() {
  const update = ProfileSettingsUpdate(
    name: '  Santosh Jangid  ',
    gender: ProfileGender.male,
    dateOfBirth: _dob,
    heightCm: 180,
    currentWeightKg: 80,
  );

  test('unchanged normalized username skips account mutation', () async {
    final calls = <String>[];
    final account = _RecordingAccountRepository(calls);
    final settings = _RecordingProfileSettingsRepository(calls);
    final useCase = SaveProfileSettingsUseCase(
      accountRepository: account,
      profileSettingsRepository: settings,
    );

    await useCase(
      persistedUsername: 'santosh',
      requestedUsername: ' SANTOSH ',
      update: update,
    );

    expect(account.updatedUsernames, isEmpty);
    expect(calls, ['profile']);
    expect(settings.lastUpdate?.name, 'Santosh Jangid');
  });

  test('changed username uses account owner before profile partial update', () async {
    final calls = <String>[];
    final account = _RecordingAccountRepository(calls);
    final settings = _RecordingProfileSettingsRepository(calls);
    final useCase = SaveProfileSettingsUseCase(
      accountRepository: account,
      profileSettingsRepository: settings,
    );

    await useCase(
      persistedUsername: 'santosh',
      requestedUsername: ' Santosh.Fit ',
      update: update,
    );

    expect(account.updatedUsernames, ['santosh.fit']);
    expect(calls, ['username', 'profile']);
  });

  test('username failure prevents profile mutation', () async {
    final calls = <String>[];
    final account = _RecordingAccountRepository(
      calls,
      error: const UsernameUnavailableException(
        reason: UsernameAvailabilityReason.taken,
      ),
    );
    final settings = _RecordingProfileSettingsRepository(calls);
    final useCase = SaveProfileSettingsUseCase(
      accountRepository: account,
      profileSettingsRepository: settings,
    );

    await expectLater(
      () => useCase(
        persistedUsername: 'santosh',
        requestedUsername: 'taken_name',
        update: update,
      ),
      throwsA(isA<UsernameUnavailableException>()),
    );

    expect(calls, ['username']);
    expect(settings.lastUpdate, isNull);
  });

  test('blank changed username is rejected before any mutation', () async {
    final calls = <String>[];
    final account = _RecordingAccountRepository(calls);
    final settings = _RecordingProfileSettingsRepository(calls);
    final useCase = SaveProfileSettingsUseCase(
      accountRepository: account,
      profileSettingsRepository: settings,
    );

    await expectLater(
      () => useCase(
        persistedUsername: 'santosh',
        requestedUsername: '   ',
        update: update,
      ),
      throwsArgumentError,
    );

    expect(calls, isEmpty);
  });
}

final _dob = DateTime(1995, 6, 5);

class _RecordingAccountRepository extends Fake
    implements ProfileAccountRepository {
  _RecordingAccountRepository(this.calls, {this.error});

  final List<String> calls;
  final Object? error;
  final List<String> updatedUsernames = [];

  @override
  Future<void> updateUsername(String username) async {
    calls.add('username');
    updatedUsernames.add(username);
    if (error case final value?) throw value;
  }
}

class _RecordingProfileSettingsRepository extends Fake
    implements ProfileSettingsRepository {
  _RecordingProfileSettingsRepository(this.calls);

  final List<String> calls;
  ProfileSettingsUpdate? lastUpdate;

  @override
  Future<void> updateProfileSettings(ProfileSettingsUpdate update) async {
    calls.add('profile');
    lastUpdate = update;
  }
}
