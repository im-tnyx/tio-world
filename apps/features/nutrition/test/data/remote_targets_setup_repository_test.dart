import 'package:flutter_test/flutter_test.dart';
import 'package:tio_feature_nutrition/nutrition.dart';

void main() {
  group('TargetsSetupDtoMapper', () {
    test('maps TargetsSetupData to verified backend JSON schema with lossless precision', () {
      const data = TargetsSetupData(
        dailySteps: 10000,
        sleepTargetMinutes: 450, // 7.5 hours
        sleepTimeMinutes: 1320, // 22:00
        wakeTimeMinutes: 360, // 06:00
        waterMl: 2500, // 2500 ml
        goalPaceKgPerWeek: 0.5,
      );

      const mapper = TargetsSetupDtoMapper();
      final payload = mapper.toRequestPayload(data, fallbackTargetWeightKg: 58.5);

      expect(payload['stepTarget'], 10000);
      expect(payload['sleepTarget'], 7.5); // decimal hours preserved
      expect(payload['sleepTime'], '22:00');
      expect(payload['wakeTime'], '06:00');
      expect(payload['waterTarget'], 2500); // exact ml preserved
      expect(payload['goalPaceKgPerWeek'], 0.5);
      expect(payload['targetWeight'], 58.5);
    });

    test('formatMinutesToHHMM handles midnight and boundaries correctly', () {
      expect(TargetsSetupDtoMapper.formatMinutesToHHMM(0), '00:00');
      expect(TargetsSetupDtoMapper.formatMinutesToHHMM(360), '06:00');
      expect(TargetsSetupDtoMapper.formatMinutesToHHMM(1320), '22:00');
      expect(TargetsSetupDtoMapper.formatMinutesToHHMM(1410), '23:30');
    });
  });

  group('RemoteTargetsSetupRepository', () {
    test('delegates mapped payload to remote data source on saveTargetsSetup', () async {
      final fakeDataSource = _FakeTargetsSetupRemoteDataSource();
      final repository = RemoteTargetsSetupRepository(
        remoteDataSource: fakeDataSource,
        targetWeightResolver: () => 65.0,
      );

      const data = TargetsSetupData(
        dailySteps: 8000,
        sleepTargetMinutes: 480,
        sleepTimeMinutes: 1380,
        wakeTimeMinutes: 420,
        waterMl: 3000,
        goalPaceKgPerWeek: 0.25,
      );

      await repository.saveTargetsSetup(data);

      expect(fakeDataSource.lastSavedPayload, isNotNull);
      expect(fakeDataSource.lastSavedPayload?['stepTarget'], 8000);
      expect(fakeDataSource.lastSavedPayload?['sleepTarget'], 8.0);
      expect(fakeDataSource.lastSavedPayload?['waterTarget'], 3000);
      expect(fakeDataSource.lastSavedPayload?['targetWeight'], 65.0);
      expect(await repository.getTargetsSetup(), isNull);
    });
  });
}

class _FakeTargetsSetupRemoteDataSource implements TargetsSetupRemoteDataSource {
  Map<String, dynamic>? lastSavedPayload;

  @override
  Future<void> saveTargetsSetup(Map<String, dynamic> data) async {
    lastSavedPayload = data;
  }
}
