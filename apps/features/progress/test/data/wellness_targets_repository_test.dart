import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tio_feature_progress/progress.dart';

void main() {
  group('canonical Wellness targets owner', () {
    test('in-memory repository preserves values and unknown nulls exactly', () async {
      final repository = InMemoryWellnessTargetsRepository();

      expect(await repository.read(), isNull);

      const data = WellnessTargetsData(
        dailySteps: 10000,
        waterMl: null,
        sleepTargetMinutes: 480,
        bedTimeMinutes: 1320,
        wakeTimeMinutes: null,
      );
      await repository.upsert(data);

      expect(repository.data, data);
      expect(await repository.read(), data);
      expect((await repository.read())?.waterMl, isNull);
      expect((await repository.read())?.wakeTimeMinutes, isNull);
    });

    test('in-memory repository rejects invalid canonical constraints', () async {
      final repository = InMemoryWellnessTargetsRepository();

      for (final data in [
        const WellnessTargetsData(dailySteps: -1),
        const WellnessTargetsData(waterMl: -1),
        const WellnessTargetsData(sleepTargetMinutes: -1),
        const WellnessTargetsData(bedTimeMinutes: -1),
        const WellnessTargetsData(wakeTimeMinutes: 1440),
      ]) {
        await expectLater(() => repository.upsert(data), throwsArgumentError);
      }
    });
  });

  group('SupabaseWellnessTargetsRepository', () {
    test('signed-out read returns null and write fails closed before gateway access',
        () async {
      final gateway = _FakeGateway();
      final repository = _repository(gateway: gateway, userId: null);

      expect(await repository.read(), isNull);
      await expectLater(
        () => repository.upsert(const WellnessTargetsData()),
        throwsStateError,
      );
      expect(gateway.readUserIds, isEmpty);
      expect(gateway.upsertPayloads, isEmpty);
    });

    test('returns null when canonical Wellness row does not exist', () async {
      final gateway = _FakeGateway(readResult: null);
      final repository = _repository(gateway: gateway);

      expect(await repository.read(), isNull);
      expect(gateway.readUserIds, ['user-1']);
    });

    test('strictly parses complete canonical Wellness row', () async {
      final repository = _repository(
        gateway: _FakeGateway(
          readResult: {
            'steps_target': 12000,
            'water_target_ml': 3200,
            'sleep_target_minutes': 450,
            'bed_time': '23:15:00',
            'wake_up_time': '06:45:00',
          },
        ),
      );

      expect(
        await repository.read(),
        const WellnessTargetsData(
          dailySteps: 12000,
          waterMl: 3200,
          sleepTargetMinutes: 450,
          bedTimeMinutes: 1395,
          wakeTimeMinutes: 405,
        ),
      );
    });

    test('canonical null fields remain null instead of becoming UI defaults',
        () async {
      final repository = _repository(
        gateway: _FakeGateway(
          readResult: {
            'steps_target': null,
            'water_target_ml': null,
            'sleep_target_minutes': null,
            'bed_time': null,
            'wake_up_time': null,
          },
        ),
      );

      expect(await repository.read(), const WellnessTargetsData());
    });

    test('rejects malformed canonical row instead of fabricating values', () async {
      final invalidRows = <Map<String, dynamic>>[
        {
          ..._validRow(),
          'steps_target': '10000',
        },
        {
          ..._validRow(),
          'water_target_ml': 2500.5,
        },
        {
          ..._validRow(),
          'sleep_target_minutes': -1,
        },
        {
          ..._validRow(),
          'bed_time': '24:00:00',
        },
        {
          ..._validRow(),
          'wake_up_time': '06:30:15',
        },
      ];

      for (final row in invalidRows) {
        final repository = _repository(gateway: _FakeGateway(readResult: row));
        await expectLater(repository.read(), throwsFormatException);
      }
    });

    test('upserts only canonical Wellness columns with deterministic SQL TIME',
        () async {
      final gateway = _FakeGateway();
      final repository = _repository(gateway: gateway);

      await repository.upsert(
        const WellnessTargetsData(
          dailySteps: 10000,
          waterMl: 2750,
          sleepTargetMinutes: 480,
          bedTimeMinutes: 1320,
          wakeTimeMinutes: 390,
        ),
      );

      expect(gateway.upsertPayloads, [
        {
          'user_id': 'user-1',
          'steps_target': 10000,
          'water_target_ml': 2750,
          'sleep_target_minutes': 480,
          'bed_time': '22:00:00',
          'wake_up_time': '06:30:00',
        }
      ]);
    });

    test('upsert includes nulls so canonical values can be intentionally cleared',
        () async {
      final gateway = _FakeGateway();
      final repository = _repository(gateway: gateway);

      await repository.upsert(const WellnessTargetsData());

      expect(gateway.upsertPayloads, [
        {
          'user_id': 'user-1',
          'steps_target': null,
          'water_target_ml': null,
          'sleep_target_minutes': null,
          'bed_time': null,
          'wake_up_time': null,
        }
      ]);
    });

    test('rejects invalid write before gateway access', () async {
      final gateway = _FakeGateway();
      final repository = _repository(gateway: gateway);

      await expectLater(
        () => repository.upsert(
          const WellnessTargetsData(bedTimeMinutes: 1440),
        ),
        throwsArgumentError,
      );
      expect(gateway.upsertPayloads, isEmpty);
    });

    test('surfaces canonical gateway failures', () async {
      final readRepository = _repository(
        gateway: _FakeGateway(readError: StateError('read failed')),
      );
      await expectLater(readRepository.read(), throwsStateError);

      final writeRepository = _repository(
        gateway: _FakeGateway(writeError: StateError('write failed')),
      );
      await expectLater(
        () => writeRepository.upsert(const WellnessTargetsData()),
        throwsStateError,
      );
    });
  });
}

SupabaseWellnessTargetsRepository _repository({
  required _FakeGateway gateway,
  String? userId = 'user-1',
}) {
  return SupabaseWellnessTargetsRepository(
    client: _UnusedSupabaseClient(),
    gateway: gateway,
    currentUserId: () => userId,
  );
}

Map<String, dynamic> _validRow() => {
      'steps_target': 10000,
      'water_target_ml': 2500,
      'sleep_target_minutes': 480,
      'bed_time': '22:00:00',
      'wake_up_time': '06:00:00',
    };

class _UnusedSupabaseClient extends Fake implements SupabaseClient {}

class _FakeGateway implements WellnessTargetsTableGateway {
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
