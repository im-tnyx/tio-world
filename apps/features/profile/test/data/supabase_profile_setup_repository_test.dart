import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tio_feature_profile/profile.dart';

void main() {
  group('SupabaseProfileSetupRepository', () {
    test('instantiates with client', () {
      expect(
        () => SupabaseProfileSetupRepository(
          client: FakeSupabaseClient(),
        ),
        returnsNormally,
      );
    });

    test('saveProfileSetup throws StateError when user is unauthenticated', () async {
      final repository = SupabaseProfileSetupRepository(
        client: FakeSupabaseClient(currentUser: null),
      );

      final data = ProfileSetupData(
        name: 'Jane Doe',
        gender: ProfileGender.female,
        goals: const {ProfileGoal.boostStrength},
        dateOfBirth: DateTime(1998, 12, 10),
        heightCm: 165,
        currentWeightKg: 58,
        activityLevel: ProfileActivityLevel.light,
        healthConditions: const {ProfileHealthCondition.none},
      );

      expect(
        () => repository.saveProfileSetup(data),
        throwsStateError,
      );
    });

    test('getProfileSetup returns null when user is unauthenticated', () async {
      final repository = SupabaseProfileSetupRepository(
        client: FakeSupabaseClient(currentUser: null),
      );

      final result = await repository.getProfileSetup();
      expect(result, isNull);
    });
  });
}

class FakeSupabaseClient extends Fake implements SupabaseClient {
  FakeSupabaseClient({this.currentUser});

  final User? currentUser;

  @override
  GoTrueClient get auth => FakeGoTrueClient(currentUser: currentUser);
}

class FakeGoTrueClient extends Fake implements GoTrueClient {
  FakeGoTrueClient({this.currentUser});

  @override
  final User? currentUser;
}
