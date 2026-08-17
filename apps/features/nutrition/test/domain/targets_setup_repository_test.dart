import 'package:flutter_test/flutter_test.dart';
import 'package:tio_feature_nutrition/nutrition.dart';

void main() {
  group('InMemoryTargetsSetupRepository', () {
    test('round trips targets setup data with recommendation', () async {
      final repository = InMemoryTargetsSetupRepository();
      expect(await repository.getTargetsSetup(), isNull);

      const data = TargetsSetupData(
        dailySteps: 10000,
        sleepTargetMinutes: 480,
        sleepTimeMinutes: 1320,
        wakeTimeMinutes: 360,
        waterMl: 2500,
        goalPaceKgPerWeek: 0.5,
        recommendation: NutritionTargetRecommendation(
          bmr: 1650,
          tdee: 2550,
          caloriesKcal: 2000,
          proteinGrams: 140,
          carbsGrams: 220,
          fatGrams: 60,
          fiberGrams: 28,
        ),
      );

      await repository.saveTargetsSetup(data);
      final retrieved = await repository.getTargetsSetup();

      expect(retrieved, equals(data));
      expect(retrieved?.dailySteps, 10000);
      expect(retrieved?.waterMl, 2500);
      expect(retrieved?.recommendation?.caloriesKcal, 2000);
    });

    test('overwrites previous targets setup on subsequent save', () async {
      final repository = InMemoryTargetsSetupRepository();

      const first = TargetsSetupData(
        dailySteps: 8000,
        sleepTargetMinutes: 420,
        sleepTimeMinutes: 1380,
        wakeTimeMinutes: 420,
        waterMl: 2000,
        goalPaceKgPerWeek: 0.25,
      );

      const second = TargetsSetupData(
        dailySteps: 12000,
        sleepTargetMinutes: 540,
        sleepTimeMinutes: 1260,
        wakeTimeMinutes: 360,
        waterMl: 3500,
        goalPaceKgPerWeek: 0.75,
      );

      await repository.saveTargetsSetup(first);
      await repository.saveTargetsSetup(second);

      final retrieved = await repository.getTargetsSetup();
      expect(retrieved, equals(second));
    });
  });
}
