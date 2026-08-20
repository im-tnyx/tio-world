import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tio_feature_profile/profile.dart';

void main() {
  test('updateProfileSettings requires an authenticated user', () async {
    final repository = SupabaseProfileSettingsRepository(
      client: _FakeSupabaseClient(),
    );

    await expectLater(
      () => repository.updateProfileSettings(
        ProfileSettingsUpdate(
          name: 'Santosh Jangid',
          gender: ProfileGender.male,
          dateOfBirth: DateTime(1995, 6, 5),
          heightCm: 180,
          currentWeightKg: 80,
        ),
      ),
      throwsStateError,
    );
  });
}

class _FakeSupabaseClient extends Fake implements SupabaseClient {
  @override
  GoTrueClient get auth => _FakeGoTrueClient();
}

class _FakeGoTrueClient extends Fake implements GoTrueClient {
  @override
  User? get currentUser => null;
}
