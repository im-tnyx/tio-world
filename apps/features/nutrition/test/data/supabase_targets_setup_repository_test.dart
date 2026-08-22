import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tio_feature_nutrition/nutrition.dart';

void main() {
  group('SupabaseTargetsSetupRepository', () {
    final fakeUser = User(
      id: 'usr-456',
      appMetadata: const {},
      userMetadata: const {},
      aud: 'authenticated',
      createdAt: DateTime.now().toIso8601String(),
    );

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

    test(
        'saveTargetsSetup writes Nutrition-owned data without Body or Wellness mirrors',
        () async {
      final fakePostgrest = FakePostgrestClient();
      final repository = SupabaseTargetsSetupRepository(
        client: FakeSupabaseClient(
          currentUser: fakeUser,
          postgrestClient: fakePostgrest,
        ),
      );

      const recommendation = NutritionTargetRecommendation(
        caloriesKcal: 2450,
        proteinGrams: 165,
        carbsGrams: 280,
        fatGrams: 75,
        fiberGrams: 35,
        bmr: 1780,
        tdee: 2550,
      );

      const data = TargetsSetupData(
        dailySteps: 12000,
        sleepTargetMinutes: 450,
        sleepTimeMinutes: 1380,
        wakeTimeMinutes: 420,
        waterMl: 3200,
        goalPaceKgPerWeek: 0.75,
        heightCm: 171,
        currentWeightKg: 80,
        targetWeightKg: 74,
        activityLevel: 'active',
        recommendation: recommendation,
      );

      await repository.saveTargetsSetup(data);

      expect(fakePostgrest.upsertCalled, isTrue);
      expect(fakePostgrest.lastTable, 'user_nutrition_profiles');

      final payload = fakePostgrest.lastPayload!;
      expect(payload['user_id'], 'usr-456');
      expect(payload['height_cm'], 171);
      expect(payload['activity_level'], 'active');

      for (final wellnessMirror in const [
        'steps_target',
        'sleep_target_minutes',
        'bed_time',
        'wake_up_time',
        'water_target_ml',
      ]) {
        expect(payload.containsKey(wellnessMirror), isFalse,
            reason: '$wellnessMirror is Wellness-owned');
      }
      expect(payload.containsKey('current_weight_kg'), isFalse);
      expect(payload.containsKey('target_weight_kg'), isFalse);
      expect(payload.containsKey('weekly_weight_change_kg'), isFalse);

      final macros = payload['macro_targets'] as Map<String, dynamic>;
      expect(macros['calories'], 2450);
      expect(macros['protein'], 165);
      expect(macros['carbs'], 280);
      expect(macros['fat'], 75);
      expect(macros['fiber'], 35);
      expect(macros['bmr'], 1780);
      expect(macros['tdee'], 2550);
      expect(payload['updated_at'], isNotNull);
    });

    test(
        'saveTargetsSetup handles null recommendation without recreating Wellness mirrors',
        () async {
      final fakePostgrest = FakePostgrestClient();
      final repository = SupabaseTargetsSetupRepository(
        client: FakeSupabaseClient(
          currentUser: fakeUser,
          postgrestClient: fakePostgrest,
        ),
      );

      const data = TargetsSetupData(
        dailySteps: 8000,
        sleepTargetMinutes: 480,
        sleepTimeMinutes: 1320,
        wakeTimeMinutes: 360,
        waterMl: 2500,
        goalPaceKgPerWeek: 0.0,
        recommendation: null,
      );

      await repository.saveTargetsSetup(data);

      final payload = fakePostgrest.lastPayload!;
      expect(payload['macro_targets'], isEmpty);
      expect(payload.keys, containsAll(<String>['user_id', 'updated_at']));
      expect(payload.containsKey('steps_target'), isFalse);
      expect(payload.containsKey('sleep_target_minutes'), isFalse);
      expect(payload.containsKey('bed_time'), isFalse);
      expect(payload.containsKey('wake_up_time'), isFalse);
      expect(payload.containsKey('water_target_ml'), isFalse);
      expect(payload.containsKey('weekly_weight_change_kg'), isFalse);
    });

    test(
        'schema compatibility fallback writes Nutrition targets only, not Wellness mirrors',
        () async {
      final fakePostgrest = FallbackFakePostgrestClient();
      final repository = SupabaseTargetsSetupRepository(
        client: FakeSupabaseClient(
          currentUser: fakeUser,
          postgrestClient: fakePostgrest,
        ),
      );

      const data = TargetsSetupData(
        dailySteps: 9500,
        sleepTargetMinutes: 480,
        sleepTimeMinutes: 1320,
        wakeTimeMinutes: 360,
        waterMl: 2700,
        goalPaceKgPerWeek: 0.0,
        recommendation: NutritionTargetRecommendation(
          caloriesKcal: 2200,
          proteinGrams: 150,
          carbsGrams: 250,
          fatGrams: 70,
          fiberGrams: 30,
          bmr: 1650,
          tdee: 2400,
        ),
      );

      await repository.saveTargetsSetup(data);

      expect(fakePostgrest.lastTable, 'user_targets');
      final payload = fakePostgrest.lastPayload!;
      expect(payload['target_calories'], 2200);
      expect(payload['target_protein_grams'], 150);
      expect(payload['target_carbs_grams'], 250);
      expect(payload['target_fat_grams'], 70);
      expect(payload.containsKey('daily_steps'), isFalse);
      expect(payload.containsKey('sleep_target_minutes'), isFalse);
      expect(payload.containsKey('sleep_time_minutes'), isFalse);
      expect(payload.containsKey('wake_time_minutes'), isFalse);
      expect(payload.containsKey('water_ml'), isFalse);
    });

    test(
        'saveTargetsSetup propagates PostgrestException on failure without faking success',
        () async {
      final throwingPostgrest = ThrowingFakePostgrestClient();
      final repository = SupabaseTargetsSetupRepository(
        client: FakeSupabaseClient(
          currentUser: fakeUser,
          postgrestClient: throwingPostgrest,
        ),
      );

      const data = TargetsSetupData(
        dailySteps: 9000,
        sleepTargetMinutes: 480,
        sleepTimeMinutes: 1380,
        wakeTimeMinutes: 420,
        waterMl: 2800,
        goalPaceKgPerWeek: 0.5,
      );

      expect(
        () => repository.saveTargetsSetup(data),
        throwsA(isA<PostgrestException>()),
      );
    });

    test('getTargetsSetup returns null when no row is found in database', () async {
      final fakePostgrest = FakePostgrestClient(rowToReturn: null);
      final repository = SupabaseTargetsSetupRepository(
        client: FakeSupabaseClient(
          currentUser: fakeUser,
          postgrestClient: fakePostgrest,
        ),
      );

      final result = await repository.getTargetsSetup();
      expect(result, isNull);
      expect(fakePostgrest.lastTable, 'user_nutrition_profiles');
    });

    test(
        'getTargetsSetup keeps legacy Wellness mirrors read-compatible during O4C',
        () async {
      final canonicalRow = {
        'user_id': 'usr-456',
        'steps_target': 10000,
        'sleep_target_minutes': 450,
        'bed_time': '23:00:00',
        'wake_up_time': '07:00:00',
        'water_target_ml': 3000,
        'weekly_weight_change_kg': 0.5,
        'macro_targets': <String, dynamic>{},
        'updated_at': DateTime.now().toIso8601String(),
      };

      final fakePostgrest = FakePostgrestClient(rowToReturn: canonicalRow);
      final repository = SupabaseTargetsSetupRepository(
        client: FakeSupabaseClient(
          currentUser: fakeUser,
          postgrestClient: fakePostgrest,
        ),
      );

      final result = await repository.getTargetsSetup();
      expect(result, isNotNull);
      expect(result!.dailySteps, 10000);
      expect(result.sleepTargetMinutes, 450);
      expect(result.sleepTimeMinutes, 1380);
      expect(result.wakeTimeMinutes, 420);
      expect(result.waterMl, 3000);
      expect(result.goalPaceKgPerWeek, 0.5);
      expect(result.recommendation, isNull);
    });

    test('getTargetsSetup keeps old Body mirrors read-compatible', () async {
      final canonicalRow = {
        'user_id': 'usr-456',
        'steps_target': 10000,
        'sleep_target_minutes': 480,
        'bed_time': '23:00:00',
        'wake_up_time': '07:00:00',
        'water_target_ml': 3000,
        'weekly_weight_change_kg': 0.6,
        'current_weight_kg': 80,
        'target_weight_kg': 74,
        'macro_targets': <String, dynamic>{},
      };

      final repository = SupabaseTargetsSetupRepository(
        client: FakeSupabaseClient(
          currentUser: fakeUser,
          postgrestClient: FakePostgrestClient(rowToReturn: canonicalRow),
        ),
      );

      final result = await repository.getTargetsSetup();

      expect(result, isNotNull);
      expect(result!.goalPaceKgPerWeek, 0.6);
      expect(result.currentWeightKg, 80);
      expect(result.targetWeightKg, 74);
    });

    test('getTargetsSetup uses neutral compatibility pace when mirror is absent',
        () async {
      final canonicalRow = {
        'user_id': 'usr-456',
        'steps_target': 9000,
        'sleep_target_minutes': 480,
        'bed_time': '22:00:00',
        'wake_up_time': '06:00:00',
        'water_target_ml': 2600,
        'macro_targets': <String, dynamic>{},
      };

      final repository = SupabaseTargetsSetupRepository(
        client: FakeSupabaseClient(
          currentUser: fakeUser,
          postgrestClient: FakePostgrestClient(rowToReturn: canonicalRow),
        ),
      );

      final result = await repository.getTargetsSetup();

      expect(result, isNotNull);
      expect(result!.goalPaceKgPerWeek, 0.0);
      expect(result.currentWeightKg, isNull);
      expect(result.targetWeightKg, isNull);
    });

    test('getTargetsSetup parses macro_targets JSONB completely and accurately',
        () async {
      final canonicalRow = {
        'user_id': 'usr-456',
        'steps_target': 11000,
        'sleep_target_minutes': 510,
        'bed_time': '22:30:00',
        'wake_up_time': '07:00:00',
        'water_target_ml': 3500,
        'weekly_weight_change_kg': -0.5,
        'macro_targets': {
          'calories': 2150,
          'protein': 150,
          'carbs': 240,
          'fat': 65,
          'fiber': 32,
          'bmr': 1650,
          'tdee': 2400,
        },
      };

      final fakePostgrest = FakePostgrestClient(rowToReturn: canonicalRow);
      final repository = SupabaseTargetsSetupRepository(
        client: FakeSupabaseClient(
          currentUser: fakeUser,
          postgrestClient: fakePostgrest,
        ),
      );

      final result = await repository.getTargetsSetup();
      expect(result!.sleepTimeMinutes, (22 * 60) + 30);
      expect(result.wakeTimeMinutes, 7 * 60);
      expect(result.recommendation, isNotNull);
      expect(result.recommendation!.caloriesKcal, 2150);
      expect(result.recommendation!.proteinGrams, 150);
      expect(result.recommendation!.carbsGrams, 240);
      expect(result.recommendation!.fatGrams, 65);
      expect(result.recommendation!.fiberGrams, 32);
      expect(result.recommendation!.bmr, 1650);
      expect(result.recommendation!.tdee, 2400);
    });

    test('getTargetsSetup throws FormatException on missing required steps_target',
        () async {
      final invalidRow = {
        'user_id': 'usr-456',
        'steps_target': null,
        'sleep_target_minutes': 480,
        'bed_time': '23:00:00',
        'wake_up_time': '07:00:00',
        'water_target_ml': 2500,
        'weekly_weight_change_kg': 0.5,
      };

      final fakePostgrest = FakePostgrestClient(rowToReturn: invalidRow);
      final repository = SupabaseTargetsSetupRepository(
        client: FakeSupabaseClient(
          currentUser: fakeUser,
          postgrestClient: fakePostgrest,
        ),
      );

      await expectLater(
        repository.getTargetsSetup(),
        throwsA(isA<FormatException>()),
      );
    });

    test(
        'getTargetsSetup throws FormatException on missing required sleep_target_minutes',
        () async {
      final invalidRow = {
        'user_id': 'usr-456',
        'steps_target': 8000,
        'sleep_target_minutes': null,
        'bed_time': '23:00:00',
        'wake_up_time': '07:00:00',
        'water_target_ml': 2500,
        'weekly_weight_change_kg': 0.5,
      };

      final fakePostgrest = FakePostgrestClient(rowToReturn: invalidRow);
      final repository = SupabaseTargetsSetupRepository(
        client: FakeSupabaseClient(
          currentUser: fakeUser,
          postgrestClient: fakePostgrest,
        ),
      );

      await expectLater(
        repository.getTargetsSetup(),
        throwsA(isA<FormatException>()),
      );
    });

    test(
        'getTargetsSetup throws FormatException on invalid SQL TIME format in bed_time',
        () async {
      final invalidRow = {
        'user_id': 'usr-456',
        'steps_target': 8000,
        'sleep_target_minutes': 480,
        'bed_time': 'eleven_pm',
        'wake_up_time': '07:00:00',
        'water_target_ml': 2500,
        'weekly_weight_change_kg': 0.5,
      };

      final fakePostgrest = FakePostgrestClient(rowToReturn: invalidRow);
      final repository = SupabaseTargetsSetupRepository(
        client: FakeSupabaseClient(
          currentUser: fakeUser,
          postgrestClient: fakePostgrest,
        ),
      );

      await expectLater(
        repository.getTargetsSetup(),
        throwsA(isA<FormatException>()),
      );
    });

    test(
        'getTargetsSetup propagates query failure and does NOT return fabricated defaults',
        () async {
      final throwingPostgrest = ThrowingFakePostgrestClient();
      final repository = SupabaseTargetsSetupRepository(
        client: FakeSupabaseClient(
          currentUser: fakeUser,
          postgrestClient: throwingPostgrest,
        ),
      );

      await expectLater(
        repository.getTargetsSetup(),
        throwsA(isA<PostgrestException>()),
      );
    });
  });
}

class FakeSupabaseClient extends Fake implements SupabaseClient {
  FakeSupabaseClient({
    this.currentUser,
    FakeGoTrueClient? goTrueClient,
    FakePostgrestClient? postgrestClient,
  })  : _goTrueClient = goTrueClient ?? FakeGoTrueClient(currentUser: currentUser),
        _postgrestClient = postgrestClient ?? FakePostgrestClient();

  final User? currentUser;
  final FakeGoTrueClient _goTrueClient;
  final FakePostgrestClient _postgrestClient;

  @override
  GoTrueClient get auth => _goTrueClient;

  @override
  SupabaseQueryBuilder from(String table) => _postgrestClient.from(table);
}

class FakeGoTrueClient extends Fake implements GoTrueClient {
  FakeGoTrueClient({this.currentUser});

  @override
  final User? currentUser;
}

class FakePostgrestClient extends Fake {
  FakePostgrestClient({this.rowToReturn});

  final Map<String, dynamic>? rowToReturn;
  bool upsertCalled = false;
  String? lastTable;
  Map<String, dynamic>? lastPayload;

  SupabaseQueryBuilder from(String table) {
    lastTable = table;
    return FakeSupabaseQueryBuilder(this, table, rowToReturn: rowToReturn);
  }
}

class FallbackFakePostgrestClient extends FakePostgrestClient {
  bool _canonicalAttempted = false;

  @override
  SupabaseQueryBuilder from(String table) {
    lastTable = table;
    if (table == 'user_nutrition_profiles' && !_canonicalAttempted) {
      _canonicalAttempted = true;
      return FailingSchemaSupabaseQueryBuilder();
    }
    return FakeSupabaseQueryBuilder(this, table);
  }
}

class ThrowingFakePostgrestClient extends FakePostgrestClient {
  @override
  SupabaseQueryBuilder from(String table) {
    throw const PostgrestException(
      message: 'Simulated network connection failure',
    );
  }
}

class FakeSupabaseQueryBuilder extends Fake implements SupabaseQueryBuilder {
  FakeSupabaseQueryBuilder(this._client, this._table, {this.rowToReturn});
  final FakePostgrestClient _client;
  final String _table;
  final Map<String, dynamic>? rowToReturn;

  @override
  PostgrestFilterBuilder<dynamic> upsert(
    Object values, {
    String? onConflict,
    bool ignoreDuplicates = false,
    bool defaultToNull = true,
  }) {
    _client.upsertCalled = true;
    _client.lastTable = _table;
    if (values is Map<String, dynamic>) {
      _client.lastPayload = values;
    }
    return FakePostgrestFilterBuilder();
  }

  @override
  PostgrestFilterBuilder<List<Map<String, dynamic>>> select(
      [String columns = '*']) {
    return FakePostgrestSelectFilterBuilder(rowToReturn);
  }
}

class FailingSchemaSupabaseQueryBuilder extends Fake
    implements SupabaseQueryBuilder {
  @override
  PostgrestFilterBuilder<dynamic> upsert(
    Object values, {
    String? onConflict,
    bool ignoreDuplicates = false,
    bool defaultToNull = true,
  }) {
    return FailingSchemaPostgrestFilterBuilder();
  }
}

class FakePostgrestTransformBuilder<T> extends Fake
    implements PostgrestTransformBuilder<T> {
  FakePostgrestTransformBuilder(this._value);
  final T _value;

  @override
  Future<R> then<R>(
    FutureOr<R> Function(T value) onValue, {
    Function? onError,
  }) {
    return Future<T>.value(_value).then(onValue, onError: onError);
  }
}

class FakePostgrestFilterBuilder extends Fake
    implements PostgrestFilterBuilder<dynamic> {
  @override
  Future<R> then<R>(
    FutureOr<R> Function(dynamic value) onValue, {
    Function? onError,
  }) {
    return Future<dynamic>.value(<dynamic>[]).then(onValue, onError: onError);
  }
}

class FailingSchemaPostgrestFilterBuilder extends Fake
    implements PostgrestFilterBuilder<dynamic> {
  @override
  Future<R> then<R>(
    FutureOr<R> Function(dynamic value) onValue, {
    Function? onError,
  }) {
    return Future<dynamic>.error(
      const PostgrestException(
        message: 'Missing compatibility column',
        code: 'PGRST204',
      ),
    ).then(onValue, onError: onError);
  }
}

class FakePostgrestSelectFilterBuilder extends Fake
    implements PostgrestFilterBuilder<List<Map<String, dynamic>>> {
  FakePostgrestSelectFilterBuilder(this._row);
  final Map<String, dynamic>? _row;

  @override
  PostgrestFilterBuilder<List<Map<String, dynamic>>> eq(
      String column, Object value) {
    return this;
  }

  @override
  PostgrestTransformBuilder<Map<String, dynamic>?> maybeSingle() {
    return FakePostgrestTransformBuilder<Map<String, dynamic>?>(_row);
  }
}
