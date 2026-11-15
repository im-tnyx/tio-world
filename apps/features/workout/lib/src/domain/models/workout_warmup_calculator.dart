import 'routine_composition_limits.dart';

enum WarmupSetLoadType { percent, fixed, bar }

/// One typed rule in a reusable warm-up method.
///
/// Percent [value] is a ratio (0.4 = 40%); Fixed [value] is kilograms; Bar
/// does not use a value and resolves to the standard 20 kg bar.
final class WarmupMethodSet {
  const WarmupMethodSet({
    required this.type,
    required this.reps,
    this.value,
  });

  final WarmupSetLoadType type;
  final double? value;
  final int reps;

  bool get isValid {
    if (reps < 1 || reps > 30) return false;
    return switch (type) {
      WarmupSetLoadType.percent =>
        value != null && value!.isFinite && value! >= .1 && value! <= 1,
      WarmupSetLoadType.fixed =>
        value != null && value!.isFinite && value! > 0 && value! <= 1000,
      WarmupSetLoadType.bar => value == null,
    };
  }

  String get summary {
    final load = switch (type) {
      WarmupSetLoadType.percent => '${(value! * 100).round()}%',
      WarmupSetLoadType.fixed => '${_formatWeight(value!)} kg',
      WarmupSetLoadType.bar => 'Bar',
    };
    return '$load × $reps';
  }

  Map<String, Object> toJson() => {
        'type': type.name,
        if (value != null) 'value': value!,
        'reps': reps,
      };

  factory WarmupMethodSet.fromJson(Map<String, dynamic> json) {
    final typeName = json['type'];
    final reps = json['reps'];
    final rawValue = json['value'];
    if (typeName is! String || reps is! int) {
      throw const FormatException('Invalid warm-up method set.');
    }
    final type = WarmupSetLoadType.values
        .where((item) => item.name == typeName)
        .firstOrNull;
    if (type == null || (rawValue != null && rawValue is! num)) {
      throw const FormatException('Invalid warm-up method set.');
    }
    final result = WarmupMethodSet(
      type: type,
      value: (rawValue as num?)?.toDouble(),
      reps: reps,
    );
    if (!result.isValid) {
      throw const FormatException('Invalid warm-up method set.');
    }
    return result;
  }
}

/// Named method supplied by the product or created by the user.
final class WorkoutWarmupMethod {
  WorkoutWarmupMethod({
    required this.id,
    required this.name,
    required List<WarmupMethodSet> sets,
    this.isRecommended = false,
  }) : sets = List.unmodifiable(sets) {
    if (id.trim().isEmpty ||
        name.trim().isEmpty ||
        name.trim().length > 40 ||
        this.sets.isEmpty ||
        this.sets.length > RoutineCompositionLimits.maxSetsPerExercise ||
        this.sets.any((set) => !set.isValid)) {
      throw ArgumentError('Invalid warm-up method.');
    }
  }

  static final List<WorkoutWarmupMethod> builtIns = List.unmodifiable([
    WorkoutWarmupMethod(
      id: classicId,
      name: 'Classic',
      isRecommended: true,
      sets: const [
        WarmupMethodSet(type: WarmupSetLoadType.percent, value: .4, reps: 5),
        WarmupMethodSet(type: WarmupSetLoadType.percent, value: .6, reps: 5),
        WarmupMethodSet(type: WarmupSetLoadType.percent, value: .8, reps: 3),
      ],
    ),
    WorkoutWarmupMethod(
      id: strengthId,
      name: 'Strength',
      sets: const [
        WarmupMethodSet(type: WarmupSetLoadType.percent, value: .4, reps: 5),
        WarmupMethodSet(type: WarmupSetLoadType.percent, value: .6, reps: 3),
        WarmupMethodSet(type: WarmupSetLoadType.percent, value: .8, reps: 2),
        WarmupMethodSet(type: WarmupSetLoadType.percent, value: .9, reps: 1),
      ],
    ),
    WorkoutWarmupMethod(
      id: barbellRampId,
      name: 'Barbell Ramp',
      sets: const [
        WarmupMethodSet(type: WarmupSetLoadType.bar, reps: 5),
        WarmupMethodSet(type: WarmupSetLoadType.percent, value: .4, reps: 5),
        WarmupMethodSet(type: WarmupSetLoadType.percent, value: .6, reps: 3),
        WarmupMethodSet(type: WarmupSetLoadType.percent, value: .8, reps: 2),
      ],
    ),
  ]);

  static const classicId = 'classic';
  static const strengthId = 'strength';
  static const barbellRampId = 'barbell-ramp';
  static const legacyCustomId = 'legacy-custom';

  final String id;
  final String name;
  final List<WarmupMethodSet> sets;
  final bool isRecommended;

  String get summary => sets.map((set) => set.summary).join(' · ');

  Map<String, Object> toJson() => {
        'id': id,
        'name': name,
        'isRecommended': isRecommended,
        'sets': sets.map((set) => set.toJson()).toList(),
      };

  factory WorkoutWarmupMethod.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final name = json['name'];
    final rawSets = json['sets'];
    final recommended = json['isRecommended'];
    if (id is! String ||
        name is! String ||
        rawSets is! List ||
        (recommended != null && recommended is! bool)) {
      throw const FormatException('Invalid warm-up method.');
    }
    return WorkoutWarmupMethod(
      id: id,
      name: name,
      isRecommended: recommended as bool? ?? false,
      sets: rawSets
          .map((item) => WarmupMethodSet.fromJson(
                Map<String, dynamic>.from(item as Map),
              ))
          .toList(),
    );
  }
}

/// Legacy editable percentage rule. Kept for formula-only storage migration
/// and compatibility with existing calculation call sites.
final class WarmupFormulaSet {
  const WarmupFormulaSet({required this.percentage, required this.reps});

  final double percentage;
  final int reps;

  bool get isValid =>
      percentage.isFinite &&
      percentage >= .1 &&
      percentage <= 1 &&
      reps > 0 &&
      reps <= 30;

  Map<String, Object> toJson() => {'percentage': percentage, 'reps': reps};

  factory WarmupFormulaSet.fromJson(Map<String, dynamic> json) {
    final percentage = json['percentage'];
    final reps = json['reps'];
    if (percentage is! num || reps is! int) {
      throw const FormatException('Invalid warm-up formula set.');
    }
    final result = WarmupFormulaSet(
      percentage: percentage.toDouble(),
      reps: reps,
    );
    if (!result.isValid) {
      throw const FormatException('Invalid warm-up formula set.');
    }
    return result;
  }
}

/// Device-local settings. The method collection includes the product defaults
/// and any user-created method; formulas are ratios, not whole percentages.
final class WorkoutWarmupSettings {
  factory WorkoutWarmupSettings({
    bool enabled = true,
    double plateRoundingKg = 5,
    double dumbbellRoundingKg = 1,
    List<WarmupFormulaSet>? formula,
    List<WorkoutWarmupMethod>? methods,
    String? selectedMethodId,
  }) {
    final resolvedMethods = _resolveMethods(methods, formula);
    final resolvedId = selectedMethodId ??
        (methods == null && formula != null && !_isDefaultFormula(formula)
            ? WorkoutWarmupMethod.legacyCustomId
            : WorkoutWarmupMethod.classicId);
    return WorkoutWarmupSettings._(
      enabled: enabled,
      plateRoundingKg: plateRoundingKg,
      dumbbellRoundingKg: dumbbellRoundingKg,
      methods: resolvedMethods,
      selectedMethodId: resolvedId,
    );
  }

  WorkoutWarmupSettings._({
    required this.enabled,
    required this.plateRoundingKg,
    required this.dumbbellRoundingKg,
    required List<WorkoutWarmupMethod> methods,
    required this.selectedMethodId,
  }) : methods = List.unmodifiable(methods) {
    final ids = this.methods.map((method) => method.id).toSet();
    final names =
        this.methods.map((method) => method.name.trim().toLowerCase()).toList();
    if (!plateRoundingOptions.contains(plateRoundingKg) ||
        !dumbbellRoundingOptions.contains(dumbbellRoundingKg) ||
        ids.length != this.methods.length ||
        names.toSet().length != names.length ||
        this.methods.length > maxMethods ||
        !ids.contains(selectedMethodId)) {
      throw ArgumentError('Invalid warm-up calculator settings.');
    }
  }

  static const maxMethods = 40;
  static const legacyFormulaKey = 'formula';
  static const plateRoundingOptions = [.5, 1.0, 2.5, 5.0, 10.0];
  static const dumbbellRoundingOptions = [.5, 1.0, 2.0, 2.5, 5.0];
  static final List<WarmupFormulaSet> defaultFormula = List.unmodifiable([
    const WarmupFormulaSet(percentage: .40, reps: 5),
    const WarmupFormulaSet(percentage: .60, reps: 5),
    const WarmupFormulaSet(percentage: .80, reps: 3),
  ]);

  final bool enabled;
  final double plateRoundingKg;
  final double dumbbellRoundingKg;
  final List<WorkoutWarmupMethod> methods;
  final String selectedMethodId;

  WorkoutWarmupMethod get selectedMethod =>
      methods.firstWhere((method) => method.id == selectedMethodId);

  /// Compatibility view for formula-only callers. Typed methods should use
  /// [selectedMethod] so Fixed and Bar rules are not dropped.
  List<WarmupFormulaSet> get formula => List.unmodifiable([
        for (final set in selectedMethod.sets)
          if (set.type == WarmupSetLoadType.percent)
            WarmupFormulaSet(percentage: set.value!, reps: set.reps),
      ]);

  WorkoutWarmupSettings copyWith({
    bool? enabled,
    double? plateRoundingKg,
    double? dumbbellRoundingKg,
    List<WarmupFormulaSet>? formula,
    List<WorkoutWarmupMethod>? methods,
    String? selectedMethodId,
  }) {
    var nextMethods = methods ?? this.methods;
    var nextSelectedId = selectedMethodId ?? this.selectedMethodId;
    if (formula != null && methods == null) {
      final old = selectedMethod;
      final replacement = WorkoutWarmupMethod(
        id: old.id,
        name: old.name,
        isRecommended: old.isRecommended,
        sets: [
          for (final set in formula)
            WarmupMethodSet(
              type: WarmupSetLoadType.percent,
              value: set.percentage,
              reps: set.reps,
            ),
        ],
      );
      nextMethods = [
        for (final method in this.methods)
          if (method.id == old.id) replacement else method,
      ];
    }
    return WorkoutWarmupSettings._(
      enabled: enabled ?? this.enabled,
      plateRoundingKg: plateRoundingKg ?? this.plateRoundingKg,
      dumbbellRoundingKg: dumbbellRoundingKg ?? this.dumbbellRoundingKg,
      methods: nextMethods,
      selectedMethodId: nextSelectedId,
    );
  }

  Map<String, Object> toJson() => {
        'schemaVersion': 2,
        'enabled': enabled,
        'plateRoundingKg': plateRoundingKg,
        'dumbbellRoundingKg': dumbbellRoundingKg,
        'selectedMethodId': selectedMethodId,
        'methods': methods.map((method) => method.toJson()).toList(),
        // Keep older app versions' view useful during a downgrade.
        legacyFormulaKey: (formula.isEmpty ? defaultFormula : formula)
            .map((set) => set.toJson())
            .toList(),
      };

  factory WorkoutWarmupSettings.fromJson(Map<String, dynamic> json) {
    try {
      final enabled = json['enabled'] as bool;
      final plate = (json['plateRoundingKg'] as num).toDouble();
      final dumbbell = (json['dumbbellRoundingKg'] as num).toDouble();
      final rawMethods = json['methods'];
      if (rawMethods is List) {
        final methods = rawMethods
            .map((item) => WorkoutWarmupMethod.fromJson(
                  Map<String, dynamic>.from(item as Map),
                ))
            .toList();
        final selected = json['selectedMethodId'];
        if (selected is! String) {
          throw const FormatException('Missing selected warm-up method.');
        }
        return WorkoutWarmupSettings(
          enabled: enabled,
          plateRoundingKg: plate,
          dumbbellRoundingKg: dumbbell,
          methods: methods,
          selectedMethodId: selected,
        );
      }
      final rawFormula = json[legacyFormulaKey];
      if (rawFormula == null) {
        return WorkoutWarmupSettings(
          enabled: enabled,
          plateRoundingKg: plate,
          dumbbellRoundingKg: dumbbell,
        );
      }
      final formula = (rawFormula as List)
          .map((item) => WarmupFormulaSet.fromJson(
                Map<String, dynamic>.from(item as Map),
              ))
          .toList();
      return WorkoutWarmupSettings(
        enabled: enabled,
        plateRoundingKg: plate,
        dumbbellRoundingKg: dumbbell,
        formula: formula,
      );
    } catch (_) {
      throw const FormatException('Invalid warm-up calculator settings.');
    }
  }

  static List<WorkoutWarmupMethod> _resolveMethods(
    List<WorkoutWarmupMethod>? methods,
    List<WarmupFormulaSet>? legacyFormula,
  ) {
    final provided = methods ?? WorkoutWarmupMethod.builtIns;
    final byId = {for (final method in provided) method.id: method};
    final resolved = [
      for (final method in WorkoutWarmupMethod.builtIns)
        byId[method.id] ?? method,
      for (final method in provided)
        if (!WorkoutWarmupMethod.builtIns
            .any((builtin) => builtin.id == method.id))
          method,
    ];
    if (methods == null &&
        legacyFormula != null &&
        !_isDefaultFormula(legacyFormula)) {
      resolved.add(WorkoutWarmupMethod(
        id: WorkoutWarmupMethod.legacyCustomId,
        name: 'Custom',
        sets: [
          for (final set in legacyFormula)
            WarmupMethodSet(
              type: WarmupSetLoadType.percent,
              value: set.percentage,
              reps: set.reps,
            ),
        ],
      ));
    }
    return resolved;
  }

  static bool _isDefaultFormula(List<WarmupFormulaSet> formula) =>
      formula.length == defaultFormula.length &&
      List.generate(formula.length, (index) {
        final actual = formula[index];
        final expected = defaultFormula[index];
        return actual.percentage == expected.percentage &&
            actual.reps == expected.reps;
      }).every((matches) => matches);
}

final class WarmupCalculatedSet {
  const WarmupCalculatedSet({
    required this.rule,
    required this.reps,
    required this.loadKg,
  });

  final WarmupMethodSet rule;
  final int reps;
  final double loadKg;

  double? get percentage =>
      rule.type == WarmupSetLoadType.percent ? rule.value : null;

  String get formulaLabel => rule.summary;
}

/// Pure weight calculation for percentage, fixed-weight, and standard-bar rules.
abstract final class WorkoutWarmupCalculator {
  static const standardBarbellWeightKg = 20.0;

  static List<WarmupCalculatedSet> calculate({
    required double workingWeightKg,
    required List<WarmupFormulaSet> formula,
    required double roundingKg,
  }) {
    if (!workingWeightKg.isFinite ||
        workingWeightKg <= 0 ||
        !roundingKg.isFinite ||
        roundingKg <= 0 ||
        formula.isEmpty ||
        formula.length > RoutineCompositionLimits.maxSetsPerExercise ||
        formula.any((set) => !set.isValid)) {
      throw ArgumentError('Invalid warm-up calculation input.');
    }
    final method = WorkoutWarmupMethod(
      id: 'calculation',
      name: 'Calculation',
      sets: [
        for (final set in formula)
          WarmupMethodSet(
            type: WarmupSetLoadType.percent,
            value: set.percentage,
            reps: set.reps,
          ),
      ],
    );
    return calculateMethod(
      workingWeightKg: workingWeightKg,
      method: method,
      roundingKg: roundingKg,
    );
  }

  static List<WarmupCalculatedSet> calculateMethod({
    required WorkoutWarmupMethod method,
    required double roundingKg,
    double? workingWeightKg,
  }) {
    if (!roundingKg.isFinite ||
        roundingKg <= 0 ||
        method.sets.isEmpty ||
        method.sets.length > RoutineCompositionLimits.maxSetsPerExercise ||
        method.sets.any((set) => !set.isValid)) {
      throw ArgumentError('Invalid warm-up calculation input.');
    }
    final needsWorkingWeight =
        method.sets.any((set) => set.type == WarmupSetLoadType.percent);
    if (needsWorkingWeight &&
        (workingWeightKg == null ||
            !workingWeightKg.isFinite ||
            workingWeightKg <= 0)) {
      throw ArgumentError('A positive working weight is required.');
    }
    return List.unmodifiable(method.sets.map((rule) {
      final raw = switch (rule.type) {
        WarmupSetLoadType.percent => workingWeightKg! * rule.value!,
        WarmupSetLoadType.fixed => rule.value!,
        WarmupSetLoadType.bar => standardBarbellWeightKg,
      };
      final rounded = (raw / roundingKg).round() * roundingKg;
      if (!raw.isFinite || !rounded.isFinite || rounded < 0) {
        throw ArgumentError('Invalid warm-up calculation result.');
      }
      return WarmupCalculatedSet(
        rule: rule,
        reps: rule.reps,
        loadKg: rounded,
      );
    }));
  }
}

String _formatWeight(double value) =>
    value == value.roundToDouble() ? value.toStringAsFixed(0) : '$value';
