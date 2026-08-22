import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tio_core/core.dart';
import 'package:tio_feature_profile/profile.dart';

void main() {
  group('SupabaseUserProfileRepository', () {
    test('requires an authenticated user before canonical read/write', () async {
      final gateway = _FakeGateway();
      final repository = _repository(gateway: gateway, userId: null);

      await expectLater(repository.read(), throwsStateError);
      await expectLater(repository.upsert(_profile()), throwsStateError);
      expect(gateway.readUserIds, isEmpty);
      expect(gateway.upsertPayloads, isEmpty);
    });

    test('returns null when no canonical user_profiles row exists', () async {
      final gateway = _FakeGateway(readResult: null);
      final repository = _repository(gateway: gateway);

      expect(await repository.read(), isNull);
      expect(gateway.readUserIds, ['user-1']);
    });

    test('strictly parses the canonical common Profile row', () async {
      final repository = _repository(
        gateway: _FakeGateway(
          readResult: {
            'name': 'Jane Doe',
            'gender': 'female',
            'date_of_birth': '1998-12-10',
            'height_cm': 165,
            'activity_level': 'very_active',
            'health_conditions': ['low_blood_pressure', 'other'],
            'other_health_condition': 'Example condition',
            'unit_preferences': {
              'weight': 'lb',
              'height': 'ft_in',
              'distance': 'mi',
              'volume': 'fl_oz',
            },
          },
        ),
      );

      final profile = await repository.read();

      expect(profile, isNotNull);
      expect(profile!.name, 'Jane Doe');
      expect(profile.gender, ProfileGender.female);
      expect(profile.dateOfBirth, DateTime(1998, 12, 10));
      expect(profile.heightCm, 165);
      expect(profile.activityLevel, ProfileActivityLevel.veryActive);
      expect(
        profile.healthConditions,
        const {
          ProfileHealthCondition.lowBloodPressure,
          ProfileHealthCondition.other,
        },
      );
      expect(profile.otherHealthCondition, 'Example condition');
      expect(profile.unitPreferences, MeasurementUnitPreferences.imperial);
    });

    test('rejects malformed canonical state instead of inventing defaults',
        () async {
      final invalidRows = <Map<String, dynamic>>[
        {
          ..._validRow(),
          'gender': null,
        },
        {
          ..._validRow(),
          'date_of_birth': 'not-a-date',
        },
        {
          ..._validRow(),
          'height_cm': 0,
        },
        {
          ..._validRow(),
          'activity_level': 'veryActive',
        },
        {
          ..._validRow(),
          'health_conditions': ['none', 'diabetes'],
        },
        {
          ..._validRow(),
          'unit_preferences': {
            'weight': 'stone',
            'height': 'cm',
            'distance': 'km',
            'volume': 'ml',
          },
        },
      ];

      for (final row in invalidRows) {
        final repository = _repository(
          gateway: _FakeGateway(readResult: row),
        );
        await expectLater(repository.read(), throwsFormatException);
      }
    });

    test('upserts only canonical common Profile columns', () async {
      final gateway = _FakeGateway();
      final repository = _repository(gateway: gateway);

      await repository.upsert(
        UserProfileData(
          name: 'Jane Doe',
          gender: ProfileGender.female,
          dateOfBirth: DateTime(1998, 12, 10),
          unitPreferences: MeasurementUnitPreferences.imperial,
          heightCm: 165,
          activityLevel: ProfileActivityLevel.veryActive,
          healthConditions: const {
            ProfileHealthCondition.lowBloodPressure,
            ProfileHealthCondition.other,
          },
          otherHealthCondition: 'Example condition',
        ),
      );

      expect(gateway.upsertPayloads, [
        {
          'user_id': 'user-1',
          'name': 'Jane Doe',
          'gender': 'female',
          'date_of_birth': '1998-12-10',
          'height_cm': 165.0,
          'activity_level': 'very_active',
          'health_conditions': ['low_blood_pressure', 'other'],
          'other_health_condition': 'Example condition',
          'unit_preferences': {
            'weight': 'lb',
            'height': 'ft_in',
            'distance': 'mi',
            'volume': 'fl_oz',
          },
        }
      ]);
    });

    test('surfaces canonical gateway failures', () async {
      final readRepository = _repository(
        gateway: _FakeGateway(readError: StateError('read failed')),
      );
      await expectLater(readRepository.read(), throwsStateError);

      final writeRepository = _repository(
        gateway: _FakeGateway(writeError: StateError('write failed')),
      );
      await expectLater(writeRepository.upsert(_profile()), throwsStateError);
    });
  });
}

SupabaseUserProfileRepository _repository({
  required _FakeGateway gateway,
  String? userId = 'user-1',
}) {
  return SupabaseUserProfileRepository(
    client: _UnusedSupabaseClient(),
    gateway: gateway,
    currentUserId: () => userId,
  );
}

UserProfileData _profile() => UserProfileData(
      name: 'Jane Doe',
      gender: ProfileGender.female,
      dateOfBirth: DateTime(1998, 12, 10),
      unitPreferences: MeasurementUnitPreferences.metric,
      heightCm: 165,
      activityLevel: ProfileActivityLevel.light,
      healthConditions: const {ProfileHealthCondition.none},
    );

Map<String, dynamic> _validRow() => {
      'name': 'Jane Doe',
      'gender': 'female',
      'date_of_birth': '1998-12-10',
      'height_cm': 165,
      'activity_level': 'light',
      'health_conditions': ['none'],
      'other_health_condition': null,
      'unit_preferences': {
        'weight': 'kg',
        'height': 'cm',
        'distance': 'km',
        'volume': 'ml',
      },
    };

class _UnusedSupabaseClient extends Fake implements SupabaseClient {}

class _FakeGateway implements UserProfileTableGateway {
  _FakeGateway({this.readResult, this.readError, this.writeError});

  final Map<String, dynamic>? readResult;
  final Object? readError;
  final Object? writeError;
  final List<String> readUserIds = [];
  final List<Map<String, dynamic>> upsertPayloads = [];

  @override
  Future<Map<String, dynamic>?> readRow(String userId) async {
    readUserIds.add(userId);
    if (readError case final error?) throw error;
    return readResult;
  }

  @override
  Future<void> upsertRow(Map<String, dynamic> payload) async {
    if (writeError case final error?) throw error;
    upsertPayloads.add(Map<String, dynamic>.from(payload));
  }
}
