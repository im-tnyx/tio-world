import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tio_feature_workout/workout.dart';

void main() {
  group('SupabaseWorkoutPreferencesRepository', () {
    final fakeUser = User(
      id: 'usr-123',
      appMetadata: const {},
      userMetadata: const {},
      aud: 'authenticated',
      createdAt: DateTime.now().toIso8601String(),
    );

    test('instantiates with client', () {
      expect(
        () => SupabaseWorkoutPreferencesRepository(
          client: FakeSupabaseClient(),
        ),
        returnsNormally,
      );
    });

    test('saveWorkoutPreferences throws StateError when user is unauthenticated', () async {
      final repository = SupabaseWorkoutPreferencesRepository(
        client: FakeSupabaseClient(currentUser: null),
      );

      const data = WorkoutPreferencesData(
        gymAccess: WorkoutGymAccess.gym,
        equipment: {WorkoutEquipment.dumbbells, WorkoutEquipment.bench},
        experienceLevel: WorkoutExperienceLevel.intermediate,
        focusAreas: {WorkoutFocusArea.chest, WorkoutFocusArea.arms},
        trainingDays: {WorkoutTrainingDay.monday, WorkoutTrainingDay.friday},
        workoutDuration: WorkoutDuration.sixtyMinutes,
        workoutSplit: WorkoutSplit.upperLower,
      );

      expect(
        () => repository.saveWorkoutPreferences(data),
        throwsStateError,
      );
    });

    test('getWorkoutPreferences returns null when user is unauthenticated', () async {
      final repository = SupabaseWorkoutPreferencesRepository(
        client: FakeSupabaseClient(currentUser: null),
      );

      final result = await repository.getWorkoutPreferences();
      expect(result, isNull);
    });

    test('saveWorkoutPreferences writes to canonical user_workout_profiles table with exact canonical keys', () async {
      final fakePostgrest = FakePostgrestClient();
      final repository = SupabaseWorkoutPreferencesRepository(
        client: FakeSupabaseClient(currentUser: fakeUser, postgrestClient: fakePostgrest),
      );

      const data = WorkoutPreferencesData(
        gymAccess: WorkoutGymAccess.home,
        equipment: {WorkoutEquipment.dumbbells, WorkoutEquipment.mat, WorkoutEquipment.bands},
        experienceLevel: WorkoutExperienceLevel.advanced,
        focusAreas: {WorkoutFocusArea.fullBody, WorkoutFocusArea.cardio},
        trainingDays: {WorkoutTrainingDay.monday, WorkoutTrainingDay.wednesday, WorkoutTrainingDay.friday},
        workoutDuration: WorkoutDuration.ninetyMinutes,
        workoutSplit: WorkoutSplit.ppl,
        specialEvent: 'Marathon next month',
        healthConcerns: 'Lower back stiffness',
      );

      await repository.saveWorkoutPreferences(data);

      expect(fakePostgrest.upsertCalled, isTrue);
      expect(fakePostgrest.lastTable, 'user_workout_profiles');

      final payload = fakePostgrest.lastPayload!;
      expect(payload['user_id'], 'usr-123');
      expect(payload['workout_location'], 'home');
      expect(payload['available_equipment'], ['dumbbells', 'mat', 'bands']);
      expect(payload['experience_level'], 'advanced');
      expect(payload['focus_areas'], ['fullBody', 'cardio']);
      expect(payload['training_days'], ['monday', 'wednesday', 'friday']);
      expect(payload['workout_duration_mins'], 90);
      expect(payload['split_program'], 'ppl');
      expect(payload['special_event_goal'], 'Marathon next month');
      expect(payload['health_concerns'], ['Lower back stiffness']);
      expect(payload['updated_at'], isNotNull);
    });

    test('saveWorkoutPreferences writes null for auto duration and empty list for no health concerns', () async {
      final fakePostgrest = FakePostgrestClient();
      final repository = SupabaseWorkoutPreferencesRepository(
        client: FakeSupabaseClient(currentUser: fakeUser, postgrestClient: fakePostgrest),
      );

      const data = WorkoutPreferencesData(
        gymAccess: WorkoutGymAccess.gym,
        equipment: {},
        experienceLevel: WorkoutExperienceLevel.fresh,
        focusAreas: {WorkoutFocusArea.chest},
        trainingDays: {WorkoutTrainingDay.tuesday, WorkoutTrainingDay.thursday},
        workoutDuration: WorkoutDuration.auto,
        workoutSplit: WorkoutSplit.auto,
        specialEvent: null,
        healthConcerns: null,
      );

      await repository.saveWorkoutPreferences(data);

      final payload = fakePostgrest.lastPayload!;
      expect(payload['workout_duration_mins'], isNull);
      expect(payload['special_event_goal'], isNull);
      expect(payload['health_concerns'], isEmpty);
    });

    test('saveWorkoutPreferences propagates PostgrestException on write failure and does NOT fake success', () async {
      final throwingPostgrest = ThrowingFakePostgrestClient();
      final repository = SupabaseWorkoutPreferencesRepository(
        client: FakeSupabaseClient(currentUser: fakeUser, postgrestClient: throwingPostgrest),
      );

      const data = WorkoutPreferencesData(
        gymAccess: WorkoutGymAccess.gym,
        equipment: {WorkoutEquipment.barbell},
        experienceLevel: WorkoutExperienceLevel.beginner,
        focusAreas: {WorkoutFocusArea.legs},
        trainingDays: {WorkoutTrainingDay.monday},
        workoutDuration: WorkoutDuration.thirtyMinutes,
        workoutSplit: WorkoutSplit.fullBody,
      );

      expect(
        () => repository.saveWorkoutPreferences(data),
        throwsA(isA<PostgrestException>()),
      );
    });

    test('getWorkoutPreferences returns null when no canonical row is found', () async {
      final fakePostgrest = FakePostgrestClient(rowToReturn: null);
      final repository = SupabaseWorkoutPreferencesRepository(
        client: FakeSupabaseClient(currentUser: fakeUser, postgrestClient: fakePostgrest),
      );

      final result = await repository.getWorkoutPreferences();
      expect(result, isNull);
      expect(fakePostgrest.lastTable, 'user_workout_profiles');
    });

    test('getWorkoutPreferences reads and maps canonical row correctly', () async {
      final canonicalRow = {
        'user_id': 'usr-123',
        'workout_location': 'home',
        'available_equipment': ['dumbbells', 'kettlebell'],
        'experience_level': 'intermediate',
        'focus_areas': ['shoulders', 'arms'],
        'training_days': ['tuesday', 'saturday'],
        'workout_duration_mins': 60,
        'split_program': 'upperLower',
        'special_event_goal': 'Summer trip',
        'health_concerns': ['Knee surgery in 2024'],
        'updated_at': DateTime.now().toIso8601String(),
      };

      final fakePostgrest = FakePostgrestClient(rowToReturn: canonicalRow);
      final repository = SupabaseWorkoutPreferencesRepository(
        client: FakeSupabaseClient(currentUser: fakeUser, postgrestClient: fakePostgrest),
      );

      final result = await repository.getWorkoutPreferences();
      expect(result, isNotNull);
      expect(result!.gymAccess, WorkoutGymAccess.home);
      expect(result.equipment, {WorkoutEquipment.dumbbells, WorkoutEquipment.kettlebell});
      expect(result.experienceLevel, WorkoutExperienceLevel.intermediate);
      expect(result.focusAreas, {WorkoutFocusArea.shoulders, WorkoutFocusArea.arms});
      expect(result.trainingDays, {WorkoutTrainingDay.tuesday, WorkoutTrainingDay.saturday});
      expect(result.workoutDuration, WorkoutDuration.sixtyMinutes);
      expect(result.workoutSplit, WorkoutSplit.upperLower);
      expect(result.specialEvent, 'Summer trip');
      expect(result.healthConcerns, 'Knee surgery in 2024');
    });

    test('getWorkoutPreferences maps null workout_duration_mins to WorkoutDuration.auto', () async {
      final canonicalRow = {
        'user_id': 'usr-123',
        'workout_location': 'gym',
        'available_equipment': <String>[],
        'experience_level': 'fresh',
        'focus_areas': ['fullBody'],
        'training_days': ['monday'],
        'workout_duration_mins': null,
        'split_program': 'auto',
        'special_event_goal': null,
        'health_concerns': <String>[],
      };

      final fakePostgrest = FakePostgrestClient(rowToReturn: canonicalRow);
      final repository = SupabaseWorkoutPreferencesRepository(
        client: FakeSupabaseClient(currentUser: fakeUser, postgrestClient: fakePostgrest),
      );

      final result = await repository.getWorkoutPreferences();
      expect(result!.workoutDuration, WorkoutDuration.auto);
      expect(result.specialEvent, isNull);
      expect(result.healthConcerns, isNull);
    });

    test('getWorkoutPreferences maps multiple health_concerns TEXT[] to comma-separated string', () async {
      final canonicalRow = {
        'user_id': 'usr-123',
        'workout_location': 'gym',
        'available_equipment': ['mat'],
        'experience_level': 'beginner',
        'focus_areas': ['abs'],
        'training_days': ['sunday'],
        'workout_duration_mins': 120,
        'split_program': 'bodyPart',
        'health_concerns': ['Asthma', 'Lower back pain'],
      };

      final fakePostgrest = FakePostgrestClient(rowToReturn: canonicalRow);
      final repository = SupabaseWorkoutPreferencesRepository(
        client: FakeSupabaseClient(currentUser: fakeUser, postgrestClient: fakePostgrest),
      );

      final result = await repository.getWorkoutPreferences();
      expect(result!.workoutDuration, WorkoutDuration.oneHundredTwentyMinutes);
      expect(result.healthConcerns, 'Asthma, Lower back pain');
    });

    test('getWorkoutPreferences throws FormatException on invalid workout_location', () async {
      final invalidRow = {
        'user_id': 'usr-123',
        'workout_location': 'outdoors',
        'available_equipment': <String>[],
        'experience_level': 'beginner',
        'focus_areas': ['abs'],
        'training_days': ['sunday'],
        'workout_duration_mins': 30,
        'split_program': 'fullBody',
      };

      final fakePostgrest = FakePostgrestClient(rowToReturn: invalidRow);
      final repository = SupabaseWorkoutPreferencesRepository(
        client: FakeSupabaseClient(currentUser: fakeUser, postgrestClient: fakePostgrest),
      );

      await expectLater(
        repository.getWorkoutPreferences(),
        throwsA(isA<FormatException>()),
      );
    });

    test('getWorkoutPreferences throws FormatException on unsupported workout_duration_mins', () async {
      final invalidRow = {
        'user_id': 'usr-123',
        'workout_location': 'gym',
        'available_equipment': <String>[],
        'experience_level': 'beginner',
        'focus_areas': ['abs'],
        'training_days': ['sunday'],
        'workout_duration_mins': 45, // Not in standard [30, 60, 90, 120]
        'split_program': 'fullBody',
      };

      final fakePostgrest = FakePostgrestClient(rowToReturn: invalidRow);
      final repository = SupabaseWorkoutPreferencesRepository(
        client: FakeSupabaseClient(currentUser: fakeUser, postgrestClient: fakePostgrest),
      );

      await expectLater(
        repository.getWorkoutPreferences(),
        throwsA(isA<FormatException>()),
      );
    });

    test('getWorkoutPreferences propagates query failure and does NOT return fabricated defaults', () async {
      final throwingPostgrest = ThrowingFakePostgrestClient();
      final repository = SupabaseWorkoutPreferencesRepository(
        client: FakeSupabaseClient(currentUser: fakeUser, postgrestClient: throwingPostgrest),
      );

      await expectLater(
        repository.getWorkoutPreferences(),
        throwsA(isA<PostgrestException>()),
      );
    });

    test('canonical save and read roundtrip preserves all supported workout values', () async {
      final memoryPostgrest = MemoryFakePostgrestClient();
      final repository = SupabaseWorkoutPreferencesRepository(
        client: FakeSupabaseClient(currentUser: fakeUser, postgrestClient: memoryPostgrest),
      );

      const originalData = WorkoutPreferencesData(
        gymAccess: WorkoutGymAccess.gym,
        equipment: {WorkoutEquipment.barbell, WorkoutEquipment.bench, WorkoutEquipment.dumbbells},
        experienceLevel: WorkoutExperienceLevel.advanced,
        focusAreas: {WorkoutFocusArea.chest, WorkoutFocusArea.back, WorkoutFocusArea.legs},
        trainingDays: {
          WorkoutTrainingDay.monday,
          WorkoutTrainingDay.tuesday,
          WorkoutTrainingDay.thursday,
          WorkoutTrainingDay.friday,
        },
        workoutDuration: WorkoutDuration.sixtyMinutes,
        workoutSplit: WorkoutSplit.upperLower,
        specialEvent: 'Powerlifting Meet in 8 weeks',
        healthConcerns: 'Left shoulder impingement',
      );

      await repository.saveWorkoutPreferences(originalData);
      final loadedData = await repository.getWorkoutPreferences();

      expect(loadedData, isNotNull);
      expect(loadedData, equals(originalData));
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

class MemoryFakePostgrestClient extends FakePostgrestClient {
  final Map<String, Map<String, dynamic>> _storage = {};

  @override
  SupabaseQueryBuilder from(String table) {
    lastTable = table;
    return MemoryFakeSupabaseQueryBuilder(this, table, _storage);
  }
}

class ThrowingFakePostgrestClient extends FakePostgrestClient {
  @override
  SupabaseQueryBuilder from(String table) {
    throw const PostgrestException(message: 'Simulated connection failure');
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
  PostgrestFilterBuilder<List<Map<String, dynamic>>> select([String columns = '*']) {
    return FakePostgrestSelectFilterBuilder(rowToReturn);
  }
}

class MemoryFakeSupabaseQueryBuilder extends Fake implements SupabaseQueryBuilder {
  MemoryFakeSupabaseQueryBuilder(this._client, this._table, this._storage);
  final FakePostgrestClient _client;
  final String _table;
  final Map<String, Map<String, dynamic>> _storage;

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
      final userId = values['user_id'] as String;
      _storage[userId] = Map<String, dynamic>.from(values);
    }
    return FakePostgrestFilterBuilder();
  }

  @override
  PostgrestFilterBuilder<List<Map<String, dynamic>>> select([String columns = '*']) {
    return MemoryFakePostgrestSelectFilterBuilder(_storage);
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

class FakePostgrestSelectFilterBuilder extends Fake
    implements PostgrestFilterBuilder<List<Map<String, dynamic>>> {
  FakePostgrestSelectFilterBuilder(this._row);
  final Map<String, dynamic>? _row;

  @override
  PostgrestFilterBuilder<List<Map<String, dynamic>>> eq(String column, Object value) {
    return this;
  }

  @override
  PostgrestTransformBuilder<Map<String, dynamic>?> maybeSingle() {
    return FakePostgrestTransformBuilder<Map<String, dynamic>?>(_row);
  }
}

class MemoryFakePostgrestSelectFilterBuilder extends Fake
    implements PostgrestFilterBuilder<List<Map<String, dynamic>>> {
  MemoryFakePostgrestSelectFilterBuilder(this._storage);
  final Map<String, Map<String, dynamic>> _storage;
  final List<String> _targetUserId = [];

  @override
  PostgrestFilterBuilder<List<Map<String, dynamic>>> eq(String column, Object value) {
    if (column == 'user_id') {
      _targetUserId.add(value as String);
    }
    return this;
  }

  @override
  PostgrestTransformBuilder<Map<String, dynamic>?> maybeSingle() {
    final target = _targetUserId.isNotEmpty ? _targetUserId.last : null;
    final row = (target != null && _storage.containsKey(target))
        ? _storage[target]
        : null;
    return FakePostgrestTransformBuilder<Map<String, dynamic>?>(row);
  }
}
