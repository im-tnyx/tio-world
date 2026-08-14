import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tio_feature_nutrition/nutrition.dart';

void main() {
  group('SupabaseTargetsSetupRepository', () {
    test('instantiates with client', () {
      expect(
        () => SupabaseTargetsSetupRepository(
          client: FakeSupabaseClient(),
        ),
        returnsNormally,
      );
    });

    test('saveTargetsSetup throws StateError when user is unauthenticated', () async {
      final repository = SupabaseTargetsSetupRepository(
        client: FakeSupabaseClient(currentUser: null),
      );

      const data = TargetsSetupData(
        dailySteps: 10000,
        sleepTargetMinutes: 480,
        sleepTimeMinutes: 1380,
        wakeTimeMinutes: 420,
        waterMl: 3000,
        goalPaceKgPerWeek: 0.5,
      );

      expect(
        () => repository.saveTargetsSetup(data),
        throwsStateError,
      );
    });

    test('getTargetsSetup returns null when user is unauthenticated', () async {
      final repository = SupabaseTargetsSetupRepository(
        client: FakeSupabaseClient(currentUser: null),
      );

      final result = await repository.getTargetsSetup();
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
