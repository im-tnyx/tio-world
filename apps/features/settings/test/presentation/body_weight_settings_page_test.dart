import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tio_core/core.dart';
import 'package:tio_feature_progress/progress.dart';
import 'package:tio_feature_settings/settings.dart';

void main() {
  Widget buildApp(
    BodyWeightSettingsPage page, {
    TioThemeMode mode = TioThemeMode.dark,
  }) {
    return MaterialApp(
      builder: (context, child) => TioTheme(
        config: TioThemeConfig(mode: mode),
        child: child ?? const SizedBox.shrink(),
      ),
      home: page,
    );
  }

  const activeLoseGoal = BodyGoalState(
    goalType: BodyGoalType.loseWeight,
    startingWeightKg: 71,
    targetWeightKg: 65,
    weeklyWeightChangeKg: 0.5,
    startedAt: null,
  );

  BodyState stateWith({
    double? currentWeightKg,
    BodyGoalState? activeGoal,
  }) {
    return BodyState(
      latestWeight: currentWeightKg == null
          ? null
          : BodyWeightEntry(
              weightKg: currentWeightKg,
              measuredAt: DateTime.utc(2026, 4, 20),
            ),
      activeGoal: activeGoal,
    );
  }

  testWidgets(
      'exactly four editable rows and two read-only rows for a directional goal',
      (tester) async {
    await tester.pumpWidget(
      buildApp(
        BodyWeightSettingsPage(
          bodyState: stateWith(
            currentWeightKg: 68.4,
            activeGoal: BodyGoalState(
              goalType: BodyGoalType.loseWeight,
              startingWeightKg: 71,
              targetWeightKg: 65,
              weeklyWeightChangeKg: 0.5,
              startedAt: DateTime.utc(2026, 4, 2),
            ),
          ),
          weightUnit: WeightUnit.kg,
          onRecordCurrentWeight: (_) async {},
          onSaveBodyGoal: (_) async {},
        ),
      ),
    );

    // 4 editable concepts.
    expect(find.byKey(const ValueKey('body-weight-current-weight-field')),
        findsOneWidget);
    expect(find.byKey(const ValueKey('body-weight-body-goal-field')),
        findsOneWidget);
    expect(find.byKey(const ValueKey('body-weight-target-weight-field')),
        findsOneWidget);
    expect(find.byKey(const ValueKey('body-weight-goal-pace-field')),
        findsOneWidget);
    expect(find.byIcon(Icons.edit_outlined), findsNWidgets(4));

    // 2 read-only concepts.
    expect(find.byKey(const ValueKey('body-weight-starting-weight-field')),
        findsOneWidget);
    expect(find.byKey(const ValueKey('body-weight-goal-started-field')),
        findsOneWidget);

    expect(find.text('68.4 kg'), findsOneWidget);
    expect(find.text('Lose Weight'), findsOneWidget);
    expect(find.text('65 kg'), findsOneWidget);
    expect(find.text('0.5 kg/week'), findsOneWidget);
    expect(find.text('71 kg'), findsOneWidget);
    expect(find.text('2 Apr 2026'), findsOneWidget);

    for (final absent in [
      'BMI',
      'Body Fat',
      'Activity Level',
      'Steps',
      'Water',
      'Sleep',
    ]) {
      expect(find.text(absent), findsNothing, reason: absent);
    }
  });

  testWidgets('Maintain hides Target Weight and Goal Pace', (tester) async {
    await tester.pumpWidget(
      buildApp(
        BodyWeightSettingsPage(
          bodyState: stateWith(
            currentWeightKg: 70,
            activeGoal: const BodyGoalState(
              goalType: BodyGoalType.maintainWeight,
              startingWeightKg: 70,
            ),
          ),
          weightUnit: WeightUnit.kg,
          onRecordCurrentWeight: (_) async {},
          onSaveBodyGoal: (_) async {},
        ),
      ),
    );

    expect(find.byKey(const ValueKey('body-weight-body-goal-field')),
        findsOneWidget);
    expect(find.byKey(const ValueKey('body-weight-target-weight-field')),
        findsNothing);
    expect(find.byKey(const ValueKey('body-weight-goal-pace-field')),
        findsNothing);
    expect(find.text('Maintain Weight'), findsOneWidget);
    // Only Current Weight + Body Goal editable now.
    expect(find.byIcon(Icons.edit_outlined), findsNWidgets(2));
  });

  testWidgets('legacy Recomposition hides Target/Pace and displays truthfully',
      (tester) async {
    await tester.pumpWidget(
      buildApp(
        BodyWeightSettingsPage(
          bodyState: stateWith(
            currentWeightKg: 70,
            activeGoal: const BodyGoalState(
              goalType: BodyGoalType.recomposition,
              startingWeightKg: 70,
            ),
          ),
          weightUnit: WeightUnit.kg,
          onRecordCurrentWeight: (_) async {},
          onSaveBodyGoal: (_) async {},
        ),
      ),
    );

    expect(find.text('Recomposition'), findsOneWidget);
    expect(find.byKey(const ValueKey('body-weight-target-weight-field')),
        findsNothing);
    expect(find.byKey(const ValueKey('body-weight-goal-pace-field')),
        findsNothing);
  });

  testWidgets('edit options exclude Recomposition', (tester) async {
    await tester.pumpWidget(
      buildApp(
        BodyWeightSettingsPage(
          bodyState: stateWith(
            currentWeightKg: 70,
            activeGoal: const BodyGoalState(
              goalType: BodyGoalType.recomposition,
              startingWeightKg: 70,
            ),
          ),
          weightUnit: WeightUnit.kg,
          onRecordCurrentWeight: (_) async {},
          onSaveBodyGoal: (_) async {},
        ),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('body-weight-body-goal-field')));
    await tester.pumpAndSettle();

    final sheet = find.byKey(const ValueKey('daily-wellness-editor-sheet'));
    expect(find.descendant(of: sheet, matching: find.text('Lose Weight')),
        findsOneWidget);
    expect(find.descendant(of: sheet, matching: find.text('Gain Weight')),
        findsOneWidget);
    expect(find.descendant(of: sheet, matching: find.text('Maintain Weight')),
        findsOneWidget);
    expect(find.descendant(of: sheet, matching: find.text('Recomposition')),
        findsNothing);
  });

  testWidgets(
      'missing Starting Weight and Goal Started show a truthful unknown state',
      (tester) async {
    await tester.pumpWidget(
      buildApp(
        BodyWeightSettingsPage(
          bodyState: stateWith(currentWeightKg: 70, activeGoal: null),
          weightUnit: WeightUnit.kg,
          onRecordCurrentWeight: (_) async {},
          onSaveBodyGoal: (_) async {},
        ),
      ),
    );

    expect(
      find.descendant(
        of: find.byKey(const ValueKey('body-weight-starting-weight-field')),
        matching: find.text('Not set'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('body-weight-goal-started-field')),
        matching: find.text('Not set'),
      ),
      findsOneWidget,
    );
    expect(find.text('Not set'), findsWidgets); // also Body Goal itself
  });

  testWidgets('displays in lb when WeightUnit.lb is selected', (tester) async {
    await tester.pumpWidget(
      buildApp(
        BodyWeightSettingsPage(
          bodyState: stateWith(
            currentWeightKg: 68.4,
            activeGoal: activeLoseGoal,
          ),
          weightUnit: WeightUnit.lb,
          onRecordCurrentWeight: (_) async {},
          onSaveBodyGoal: (_) async {},
        ),
      ),
    );

    expect(find.textContaining('lb'), findsWidgets);
    expect(find.textContaining('kg'), findsNothing);
  });

  testWidgets('trailing edit affordances align at the same x-position',
      (tester) async {
    await tester.pumpWidget(
      buildApp(
        BodyWeightSettingsPage(
          bodyState: stateWith(
            currentWeightKg: 68.4,
            activeGoal: activeLoseGoal,
          ),
          weightUnit: WeightUnit.kg,
          onRecordCurrentWeight: (_) async {},
          onSaveBodyGoal: (_) async {},
        ),
      ),
    );

    final xPositions = [
      for (var i = 0; i < 4; i++)
        tester.getCenter(find.byIcon(Icons.edit_outlined).at(i)).dx,
    ];
    final reference = xPositions.first;
    for (final x in xPositions) {
      expect((x - reference).abs(), lessThanOrEqualTo(2.0));
    }
  });

  group('Current Weight editor', () {
    Future<void> openEditor(
      WidgetTester tester, {
      double? currentWeightKg,
      required Future<void> Function(double) onSave,
    }) async {
      await tester.pumpWidget(
        buildApp(
          BodyWeightSettingsPage(
            bodyState: stateWith(currentWeightKg: currentWeightKg),
            weightUnit: WeightUnit.kg,
            onRecordCurrentWeight: onSave,
            onSaveBodyGoal: (_) async {},
          ),
        ),
      );
      await tester
          .tap(find.byKey(const ValueKey('body-weight-current-weight-field')));
      await tester.pumpAndSettle();
    }

    testWidgets('saves a new weight append (not an overwrite)', (tester) async {
      double? saved;
      await openEditor(
        tester,
        currentWeightKg: 70,
        onSave: (weightKg) async => saved = weightKg,
      );

      await tester.enterText(
        find.byKey(const ValueKey('body-weight-current-weight-input')),
        '69.2',
      );
      await tester
          .tap(find.byKey(const ValueKey('body-weight-current-weight-save')));
      await tester.pumpAndSettle();

      expect(saved, 69.2);
    });

    testWidgets('rejects a weight outside the 30-200kg canonical range',
        (tester) async {
      var saveCalls = 0;
      await openEditor(
        tester,
        currentWeightKg: 70,
        onSave: (_) async => saveCalls++,
      );

      await tester.enterText(
        find.byKey(const ValueKey('body-weight-current-weight-input')),
        '250',
      );
      await tester
          .tap(find.byKey(const ValueKey('body-weight-current-weight-save')));
      await tester.pump();

      expect(saveCalls, 0);
      expect(find.textContaining('between'), findsOneWidget);
    });
  });

  group('Body Goal editor', () {
    testWidgets('Lose requires target below current weight', (tester) async {
      await tester.pumpWidget(
        buildApp(
          BodyWeightSettingsPage(
            bodyState: stateWith(currentWeightKg: 70, activeGoal: null),
            weightUnit: WeightUnit.kg,
            onRecordCurrentWeight: (_) async {},
            onSaveBodyGoal: (_) async {},
          ),
        ),
      );
      await tester
          .tap(find.byKey(const ValueKey('body-weight-body-goal-field')));
      await tester.pumpAndSettle();

      await tester
          .tap(find.byKey(const ValueKey('body-goal-option-loseWeight')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('body-weight-target-weight-input')),
        '75', // above current -- wrong direction for Lose
      );
      await tester
          .tap(find.byKey(const ValueKey('body-weight-body-goal-save')));
      await tester.pump();

      expect(find.textContaining('below Current Weight'), findsOneWidget);
    });

    testWidgets('Gain requires target above current weight', (tester) async {
      await tester.pumpWidget(
        buildApp(
          BodyWeightSettingsPage(
            bodyState: stateWith(currentWeightKg: 60, activeGoal: null),
            weightUnit: WeightUnit.kg,
            onRecordCurrentWeight: (_) async {},
            onSaveBodyGoal: (_) async {},
          ),
        ),
      );
      await tester
          .tap(find.byKey(const ValueKey('body-weight-body-goal-field')));
      await tester.pumpAndSettle();

      await tester
          .tap(find.byKey(const ValueKey('body-goal-option-gainWeight')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('body-weight-target-weight-input')),
        '55', // below current -- wrong direction for Gain
      );
      await tester
          .tap(find.byKey(const ValueKey('body-weight-body-goal-save')));
      await tester.pump();

      expect(find.textContaining('above Current Weight'), findsOneWidget);
    });

    testWidgets('blocks a directional save with no canonical Current Weight',
        (tester) async {
      var saveCalls = 0;
      await tester.pumpWidget(
        buildApp(
          BodyWeightSettingsPage(
            bodyState: stateWith(currentWeightKg: null, activeGoal: null),
            weightUnit: WeightUnit.kg,
            onRecordCurrentWeight: (_) async {},
            onSaveBodyGoal: (_) async => saveCalls++,
          ),
        ),
      );
      await tester
          .tap(find.byKey(const ValueKey('body-weight-body-goal-field')));
      await tester.pumpAndSettle();

      await tester
          .tap(find.byKey(const ValueKey('body-goal-option-loseWeight')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('body-weight-target-weight-input')),
        '65',
      );
      await tester
          .tap(find.byKey(const ValueKey('body-weight-body-goal-save')));
      await tester.pump();

      expect(saveCalls, 0);
      expect(find.textContaining('Log your Current Weight'), findsOneWidget);
    });

    testWidgets('saves Maintain with null target and pace', (tester) async {
      BodyGoalUpdate? saved;
      await tester.pumpWidget(
        buildApp(
          BodyWeightSettingsPage(
            bodyState: stateWith(
              currentWeightKg: 70,
              activeGoal: activeLoseGoal,
            ),
            weightUnit: WeightUnit.kg,
            onRecordCurrentWeight: (_) async {},
            onSaveBodyGoal: (update) async => saved = update,
          ),
        ),
      );
      await tester
          .tap(find.byKey(const ValueKey('body-weight-body-goal-field')));
      await tester.pumpAndSettle();

      await tester
          .tap(find.byKey(const ValueKey('body-goal-option-maintainWeight')));
      await tester.pumpAndSettle();
      await tester
          .tap(find.byKey(const ValueKey('body-weight-body-goal-save')));
      await tester.pumpAndSettle();

      expect(saved?.goalType, BodyGoalType.maintainWeight);
      expect(saved?.targetWeightKg, isNull);
      expect(saved?.weeklyWeightChangeKg, isNull);
    });

    testWidgets('rejects Target Weight outside the 30-200kg canonical range',
        (tester) async {
      var saveCalls = 0;
      await tester.pumpWidget(
        buildApp(
          BodyWeightSettingsPage(
            bodyState: stateWith(currentWeightKg: 70, activeGoal: null),
            weightUnit: WeightUnit.kg,
            onRecordCurrentWeight: (_) async {},
            onSaveBodyGoal: (_) async => saveCalls++,
          ),
        ),
      );
      await tester
          .tap(find.byKey(const ValueKey('body-weight-body-goal-field')));
      await tester.pumpAndSettle();

      await tester
          .tap(find.byKey(const ValueKey('body-goal-option-loseWeight')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('body-weight-target-weight-input')),
        '10',
      );
      await tester
          .tap(find.byKey(const ValueKey('body-weight-body-goal-save')));
      await tester.pump();

      expect(saveCalls, 0);
      expect(find.textContaining('out of range'), findsOneWidget);
    });

    testWidgets('Goal Pace slider stays within the 0.1-1.5 kg/week range',
        (tester) async {
      await tester.pumpWidget(
        buildApp(
          BodyWeightSettingsPage(
            bodyState: stateWith(
              currentWeightKg: 70,
              activeGoal: activeLoseGoal,
            ),
            weightUnit: WeightUnit.kg,
            onRecordCurrentWeight: (_) async {},
            onSaveBodyGoal: (_) async {},
          ),
        ),
      );
      await tester
          .tap(find.byKey(const ValueKey('body-weight-body-goal-field')));
      await tester.pumpAndSettle();

      final slider = tester.widget<Slider>(
        find.byKey(const ValueKey('body-weight-goal-pace-slider')),
      );
      expect(slider.min, 0.1);
      expect(slider.max, 1.5);
      expect(slider.divisions, 14);
    });
  });
}
