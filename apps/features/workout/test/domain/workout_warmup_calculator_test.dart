import 'package:flutter_test/flutter_test.dart';
import 'package:tio_feature_workout/workout.dart';

void main() {
  test('Tio default 40/60/80 method rounds 67 kg to nearest 2.5 kg', () {
    final settings = WorkoutWarmupSettings();
    final sets = WorkoutWarmupCalculator.calculate(
      workingWeightKg: 67,
      formula: settings.formula,
      roundingKg: 2.5,
    );
    expect(sets.map((set) => set.loadKg).toList(), [27.5, 40, 52.5]);
    expect(sets.map((set) => set.reps).toList(), [5, 5, 3]);
  });

  test('custom method and dumbbell increment yield distinct values', () {
    final sets = WorkoutWarmupCalculator.calculate(
      workingWeightKg: 67,
      formula: const [WarmupFormulaSet(percentage: .5, reps: 8)],
      roundingKg: 1,
    );
    expect(sets.single.loadKg, 34);
    expect(sets.single.reps, 8);
  });

  test('built-in methods match the warm-up method examples', () {
    final defaults = WorkoutWarmupSettings();
    expect(
      defaults.methods.map((method) => method.name).toList(),
      ['Classic', 'Strength', 'Barbell Ramp'],
    );
    expect(defaults.selectedMethod.isRecommended, isTrue);
    expect(defaults.methods[0].summary, '40% × 5 · 60% × 5 · 80% × 3');
    expect(
        defaults.methods[1].summary, '40% × 5 · 60% × 3 · 80% × 2 · 90% × 1');
    expect(
        defaults.methods[2].summary, 'Bar × 5 · 40% × 5 · 60% × 3 · 80% × 2');

    final strength = WorkoutWarmupCalculator.calculateMethod(
      method: defaults.methods[1],
      workingWeightKg: 100,
      roundingKg: 5,
    );
    expect(strength.map((set) => set.loadKg).toList(), [40, 60, 80, 90]);
    expect(strength.map((set) => set.reps).toList(), [5, 3, 2, 1]);

    final ramp = WorkoutWarmupCalculator.calculateMethod(
      method: defaults.methods[2],
      workingWeightKg: 100,
      roundingKg: 5,
    );
    expect(ramp.map((set) => set.loadKg).toList(), [20, 40, 60, 80]);
  });

  test('fixed and bar methods calculate without a working-weight target', () {
    final fixed = WorkoutWarmupMethod(
      id: 'fixed',
      name: 'Fixed',
      sets: const [
        WarmupMethodSet(type: WarmupSetLoadType.fixed, value: 17, reps: 8),
      ],
    );
    final bar = WorkoutWarmupMethod(
      id: 'bar',
      name: 'Bar',
      sets: const [WarmupMethodSet(type: WarmupSetLoadType.bar, reps: 5)],
    );
    expect(
      WorkoutWarmupCalculator.calculateMethod(
        method: fixed,
        roundingKg: 2.5,
      ).single.loadKg,
      17.5,
    );
    expect(
      WorkoutWarmupCalculator.calculateMethod(
        method: bar,
        roundingKg: 5,
      ).single.loadKg,
      20,
    );
    expect(
      () => WorkoutWarmupCalculator.calculateMethod(
        method: WorkoutWarmupSettings().selectedMethod,
        roundingKg: 5,
      ),
      throwsArgumentError,
    );
  });

  test('method selection serializes and legacy formulas migrate to Custom', () {
    final custom = WorkoutWarmupMethod(
      id: 'custom-1',
      name: 'Test',
      sets: const [
        WarmupMethodSet(type: WarmupSetLoadType.fixed, value: 12.5, reps: 6),
        WarmupMethodSet(type: WarmupSetLoadType.bar, reps: 3),
      ],
    );
    final selected = WorkoutWarmupSettings(
      methods: [...WorkoutWarmupMethod.builtIns, custom],
      selectedMethodId: custom.id,
    );
    final restored = WorkoutWarmupSettings.fromJson(selected.toJson());
    expect(restored.selectedMethod.name, 'Test');
    expect(restored.selectedMethod.summary, '12.5 kg × 6 · Bar × 3');

    final migrated = WorkoutWarmupSettings.fromJson({
      'enabled': false,
      'plateRoundingKg': 2.5,
      'dumbbellRoundingKg': 1.0,
      'formula': [
        {'percentage': .5, 'reps': 7},
      ],
    });
    expect(migrated.selectedMethod.name, 'Custom');
    expect(migrated.formula.single.percentage, .5);
    expect(migrated.formula.single.reps, 7);
    expect(migrated.enabled, isFalse);
  });

  test('invalid target, rounding, formula and persisted values are rejected',
      () {
    final defaults = WorkoutWarmupSettings();
    for (final target in [0.0, -1.0, double.nan, double.infinity]) {
      expect(
        () => WorkoutWarmupCalculator.calculate(
          workingWeightKg: target,
          formula: defaults.formula,
          roundingKg: 2.5,
        ),
        throwsArgumentError,
      );
    }
    expect(
        () => WorkoutWarmupSettings(plateRoundingKg: 0), throwsArgumentError);
    expect(
      () => WorkoutWarmupSettings(
        formula: const [WarmupFormulaSet(percentage: 1.5, reps: 5)],
      ),
      throwsArgumentError,
    );
    expect(
      () => WorkoutWarmupSettings.fromJson({
        'enabled': defaults.enabled,
        'plateRoundingKg': defaults.plateRoundingKg,
        'dumbbellRoundingKg': defaults.dumbbellRoundingKg,
        'formula': [
          {'percentage': 0.8, 'reps': 0}
        ],
      }),
      throwsFormatException,
    );
  });
}
