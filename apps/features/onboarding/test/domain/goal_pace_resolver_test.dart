import 'package:flutter_test/flutter_test.dart';
import 'package:tio_feature_onboarding/onboarding.dart';

void main() {
  group('GoalPaceResolver.resolveMode', () {
    test('resolves loss when target weight is > 0.5 kg below current weight', () {
      final mode = GoalPaceResolver.resolveMode(
        currentWeightKg: 80.0,
        targetWeightKg: 75.0,
      );
      expect(mode, equals(GoalPaceMode.loss));
    });

    test('resolves gain when target weight is > 0.5 kg above current weight', () {
      final mode = GoalPaceResolver.resolveMode(
        currentWeightKg: 65.0,
        targetWeightKg: 70.0,
      );
      expect(mode, equals(GoalPaceMode.gain));
    });

    test('resolves maintenance when weight difference is within +/- 0.5 kg', () {
      expect(
        GoalPaceResolver.resolveMode(
          currentWeightKg: 70.0,
          targetWeightKg: 70.4,
        ),
        equals(GoalPaceMode.maintenance),
      );
      expect(
        GoalPaceResolver.resolveMode(
          currentWeightKg: 70.0,
          targetWeightKg: 69.6,
        ),
        equals(GoalPaceMode.maintenance),
      );
      expect(
        GoalPaceResolver.resolveMode(
          currentWeightKg: 70.0,
          targetWeightKg: 70.0,
        ),
        equals(GoalPaceMode.maintenance),
      );
    });

    test('resolves maintenance when weights are missing', () {
      expect(
        GoalPaceResolver.resolveMode(
          currentWeightKg: null,
          targetWeightKg: 70.0,
        ),
        equals(GoalPaceMode.maintenance),
      );
      expect(
        GoalPaceResolver.resolveMode(
          currentWeightKg: 70.0,
          targetWeightKg: null,
        ),
        equals(GoalPaceMode.maintenance),
      );
    });
  });

  group('GoalPaceResolver.resolveWarning', () {
    test('returns aggressiveLoss when mode is loss and pace >= 1.0 kg/week', () {
      expect(
        GoalPaceResolver.resolveWarning(
          mode: GoalPaceMode.loss,
          paceKgPerWeek: 1.0,
        ),
        equals(GoalPaceWarning.aggressiveLoss),
      );
      expect(
        GoalPaceResolver.resolveWarning(
          mode: GoalPaceMode.loss,
          paceKgPerWeek: 1.2,
        ),
        equals(GoalPaceWarning.aggressiveLoss),
      );
    });

    test('returns aggressiveGain when mode is gain and pace >= 1.0 kg/week', () {
      expect(
        GoalPaceResolver.resolveWarning(
          mode: GoalPaceMode.gain,
          paceKgPerWeek: 1.0,
        ),
        equals(GoalPaceWarning.aggressiveGain),
      );
    });

    test('returns none when pace < 1.0 kg/week', () {
      expect(
        GoalPaceResolver.resolveWarning(
          mode: GoalPaceMode.loss,
          paceKgPerWeek: 0.5,
        ),
        equals(GoalPaceWarning.none),
      );
      expect(
        GoalPaceResolver.resolveWarning(
          mode: GoalPaceMode.gain,
          paceKgPerWeek: 0.9,
        ),
        equals(GoalPaceWarning.none),
      );
      expect(
        GoalPaceResolver.resolveWarning(
          mode: GoalPaceMode.maintenance,
          paceKgPerWeek: 1.2,
        ),
        equals(GoalPaceWarning.none),
      );
    });
  });

  group('GoalPaceResolver.paceTag', () {
    test('classifies pace into Easy, Medium, Aggressive', () {
      expect(GoalPaceResolver.paceTag(0.2), equals('Easy'));
      expect(GoalPaceResolver.paceTag(0.3), equals('Easy'));
      expect(GoalPaceResolver.paceTag(0.4), equals('Medium'));
      expect(GoalPaceResolver.paceTag(0.5), equals('Medium'));
      expect(GoalPaceResolver.paceTag(0.7), equals('Medium'));
      expect(GoalPaceResolver.paceTag(0.8), equals('Aggressive'));
      expect(GoalPaceResolver.paceTag(1.2), equals('Aggressive'));
    });
  });

  group('GoalPaceResolver.screenTitle & cardHeader', () {
    test('returns meaningful title for lose weight goal', () {
      final title = GoalPaceResolver.screenTitle(
        primaryGoal: ProfileGoal.loseWeight,
        mode: GoalPaceMode.loss,
      );
      expect(title, equals('Target Fat Loss Pace'));
    });

    test('returns meaningful title for build muscle goal', () {
      final title = GoalPaceResolver.screenTitle(
        primaryGoal: ProfileGoal.buildMuscle,
        mode: GoalPaceMode.gain,
      );
      expect(title, equals('Muscle Gain Pace'));
    });

    test('returns maintenance title for maintenance mode', () {
      final title = GoalPaceResolver.screenTitle(
        primaryGoal: ProfileGoal.keepFit,
        mode: GoalPaceMode.maintenance,
      );
      expect(title, equals('Energy Balance & Maintenance'));
    });
  });
}
