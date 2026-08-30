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

  /// Pops the currently open Settings editor sheet as if the user dismissed
  /// it (tapped the scrim / dragged it away), independent of that sheet's
  /// (private) widget type.
  void dismissOpenSheet(WidgetTester tester) {
    final sheetElement = tester
        .element(find.byKey(const ValueKey('daily-wellness-editor-sheet')));
    Navigator.of(sheetElement).pop();
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
      WeightUnit weightUnit = WeightUnit.kg,
      required Future<void> Function(double) onSave,
    }) async {
      await tester.pumpWidget(
        buildApp(
          BodyWeightSettingsPage(
            bodyState: stateWith(currentWeightKg: currentWeightKg),
            weightUnit: weightUnit,
            onRecordCurrentWeight: onSave,
            onSaveBodyGoal: (_) async {},
          ),
        ),
      );
      await tester
          .tap(find.byKey(const ValueKey('body-weight-current-weight-field')));
      await tester.pumpAndSettle();
    }

    testWidgets('opens in wheel mode by default, no manual text/keyboard icon',
        (tester) async {
      await openEditor(tester, currentWeightKg: 70, onSave: (_) async {});

      expect(find.byKey(const ValueKey('body-weight-wheel')), findsOneWidget);
      expect(find.byKey(const ValueKey('body-weight-wheel-manual-input')),
          findsNothing);
      expect(find.text('Type manually'), findsNothing);
      expect(find.byIcon(Icons.keyboard), findsNothing);
      expect(find.byKey(const ValueKey('body-weight-wheel-mode-toggle')),
          findsOneWidget);
    });

    testWidgets('pencil switches to manual entry and back', (tester) async {
      await openEditor(tester, currentWeightKg: 70, onSave: (_) async {});

      await tester
          .tap(find.byKey(const ValueKey('body-weight-wheel-mode-toggle')));
      await tester.pump();

      expect(find.byKey(const ValueKey('body-weight-wheel-manual-input')),
          findsOneWidget);
      expect(find.byKey(const ValueKey('body-weight-wheel')), findsNothing);

      await tester
          .tap(find.byKey(const ValueKey('body-weight-wheel-mode-toggle')));
      await tester.pump();

      expect(find.byKey(const ValueKey('body-weight-wheel')), findsOneWidget);
      expect(find.byKey(const ValueKey('body-weight-wheel-manual-input')),
          findsNothing);
    });

    testWidgets('typed value syncs back to the wheel', (tester) async {
      await openEditor(tester, currentWeightKg: 70, onSave: (_) async {});

      await tester
          .tap(find.byKey(const ValueKey('body-weight-wheel-mode-toggle')));
      await tester.pump();
      await tester.enterText(
        find.byKey(const ValueKey('body-weight-wheel-manual-input')),
        '82.5',
      );
      await tester.pump();
      await tester
          .tap(find.byKey(const ValueKey('body-weight-wheel-mode-toggle')));
      await tester.pump();

      final wheel = tester.widget<TioWeightWheel>(
          find.byKey(const ValueKey('body-weight-wheel')));
      expect(wheel.valueKg, 82.5);
    });

    testWidgets('wheel value syncs to the manual entry field', (tester) async {
      await openEditor(tester, currentWeightKg: 70, onSave: (_) async {});

      final wheel = tester.widget<TioWeightWheel>(
          find.byKey(const ValueKey('body-weight-wheel')));
      wheel.onChanged(75.0);
      await tester.pump();
      await tester
          .tap(find.byKey(const ValueKey('body-weight-wheel-mode-toggle')));
      await tester.pump();

      final field = tester.widget<TextField>(
          find.byKey(const ValueKey('body-weight-wheel-manual-input')));
      expect(field.controller?.text, '75.0');
    });

    testWidgets('mode switching alone never saves', (tester) async {
      var saveCalls = 0;
      await openEditor(
        tester,
        currentWeightKg: 70,
        onSave: (_) async => saveCalls++,
      );

      await tester
          .tap(find.byKey(const ValueKey('body-weight-wheel-mode-toggle')));
      await tester.pump();
      await tester
          .tap(find.byKey(const ValueKey('body-weight-wheel-mode-toggle')));
      await tester.pump();

      expect(saveCalls, 0);
    });

    testWidgets('manual entry clamps to the 30-200kg canonical range',
        (tester) async {
      double? saved;
      await openEditor(
        tester,
        currentWeightKg: 70,
        onSave: (weightKg) async => saved = weightKg,
      );

      await tester
          .tap(find.byKey(const ValueKey('body-weight-wheel-mode-toggle')));
      await tester.pump();
      await tester.enterText(
        find.byKey(const ValueKey('body-weight-wheel-manual-input')),
        '250',
      );
      await tester.pump();
      await tester
          .tap(find.byKey(const ValueKey('body-weight-current-weight-save')));
      await tester.pumpAndSettle();

      expect(saved, 200.0);
    });

    testWidgets('Save calls the Current Weight callback exactly once',
        (tester) async {
      var saveCalls = 0;
      double? saved;
      await openEditor(
        tester,
        currentWeightKg: 70,
        onSave: (weightKg) async {
          saveCalls++;
          saved = weightKg;
        },
      );

      final wheel = tester.widget<TioWeightWheel>(
          find.byKey(const ValueKey('body-weight-wheel')));
      wheel.onChanged(69.2);
      await tester.pump();
      await tester
          .tap(find.byKey(const ValueKey('body-weight-current-weight-save')));
      await tester.pumpAndSettle();

      expect(saveCalls, 1);
      expect(saved, 69.2);
    });

    testWidgets('kg/lb conversion: canonical kg storage is unaffected by unit',
        (tester) async {
      await openEditor(
        tester,
        currentWeightKg: 68.4,
        weightUnit: WeightUnit.lb,
        onSave: (_) async {},
      );

      final wheel = tester.widget<TioWeightWheel>(
          find.byKey(const ValueKey('body-weight-wheel')));
      expect(wheel.unit, WeightUnit.lb);
      expect(wheel.valueKg, 68.4); // storage stays kg regardless of display
      expect(wheel.showUnitSwitcher, isFalse);
    });
  });

  group('Body Goal flow', () {
    testWidgets('existing active goal shows confirmation before the sheet',
        (tester) async {
      await tester.pumpWidget(
        buildApp(
          BodyWeightSettingsPage(
            bodyState:
                stateWith(currentWeightKg: 70, activeGoal: activeLoseGoal),
            weightUnit: WeightUnit.kg,
            onRecordCurrentWeight: (_) async {},
            onSaveBodyGoal: (_) async {},
          ),
        ),
      );

      await tester
          .tap(find.byKey(const ValueKey('body-weight-body-goal-field')));
      await tester.pumpAndSettle();

      expect(find.text('Change Body Goal?'), findsOneWidget);
      expect(find.byKey(const ValueKey('body-goal-option-loseWeight')),
          findsNothing);
    });

    testWidgets('No on the confirmation opens no sheet and saves nothing',
        (tester) async {
      var saveCalls = 0;
      await tester.pumpWidget(
        buildApp(
          BodyWeightSettingsPage(
            bodyState:
                stateWith(currentWeightKg: 70, activeGoal: activeLoseGoal),
            weightUnit: WeightUnit.kg,
            onRecordCurrentWeight: (_) async {},
            onSaveBodyGoal: (_) async => saveCalls++,
          ),
        ),
      );

      await tester
          .tap(find.byKey(const ValueKey('body-weight-body-goal-field')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('No'));
      await tester.pumpAndSettle();

      expect(find.text('Change Body Goal?'), findsNothing);
      expect(find.byKey(const ValueKey('body-goal-option-loseWeight')),
          findsNothing);
      expect(saveCalls, 0);
    });

    testWidgets('Yes on the confirmation opens the Body Goal selection sheet',
        (tester) async {
      await tester.pumpWidget(
        buildApp(
          BodyWeightSettingsPage(
            bodyState:
                stateWith(currentWeightKg: 70, activeGoal: activeLoseGoal),
            weightUnit: WeightUnit.kg,
            onRecordCurrentWeight: (_) async {},
            onSaveBodyGoal: (_) async {},
          ),
        ),
      );

      await tester
          .tap(find.byKey(const ValueKey('body-weight-body-goal-field')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Yes'));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('body-goal-option-loseWeight')),
          findsOneWidget);
    });

    testWidgets(
        'no existing goal opens the selection sheet without confirmation',
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

      await tester
          .tap(find.byKey(const ValueKey('body-weight-body-goal-field')));
      await tester.pumpAndSettle();

      expect(find.text('Change Body Goal?'), findsNothing);
      expect(find.byKey(const ValueKey('body-goal-option-loseWeight')),
          findsOneWidget);
    });

    testWidgets('selection sheet contains goal choices only', (tester) async {
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

      expect(find.byKey(const ValueKey('body-goal-option-loseWeight')),
          findsOneWidget);
      expect(find.byKey(const ValueKey('body-goal-option-gainWeight')),
          findsOneWidget);
      expect(find.byKey(const ValueKey('body-goal-option-maintainWeight')),
          findsOneWidget);
      expect(find.byKey(const ValueKey('body-goal-option-recomposition')),
          findsNothing);
      expect(find.text('Target Weight'), findsNothing);
      expect(find.byType(Slider), findsNothing);
      expect(find.byKey(const ValueKey('body-weight-wheel')), findsNothing);
    });

    testWidgets(
        'Lose/Gain changed-goal flow gathers Target then Pace with exactly one final save',
        (tester) async {
      var saveCalls = 0;
      BodyGoalUpdate? saved;
      await tester.pumpWidget(
        buildApp(
          BodyWeightSettingsPage(
            bodyState:
                stateWith(currentWeightKg: 90, activeGoal: activeLoseGoal),
            weightUnit: WeightUnit.kg,
            onRecordCurrentWeight: (_) async {},
            onSaveBodyGoal: (update) async {
              saveCalls++;
              saved = update;
            },
          ),
        ),
      );

      await tester
          .tap(find.byKey(const ValueKey('body-weight-body-goal-field')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Yes'));
      await tester.pumpAndSettle();

      await tester
          .tap(find.byKey(const ValueKey('body-goal-option-gainWeight')));
      await tester.pumpAndSettle();
      expect(saveCalls, 0, reason: 'selecting a goal type must not persist');

      await tester
          .tap(find.byKey(const ValueKey('body-weight-body-goal-continue')));
      await tester.pumpAndSettle();

      // Now on the Target Weight step -- no goal selector, no pace control.
      expect(find.byKey(const ValueKey('body-goal-option-loseWeight')),
          findsNothing);
      expect(find.byType(Slider), findsNothing);
      final targetWheel = tester.widget<TioWeightWheel>(
          find.byKey(const ValueKey('body-weight-wheel')));
      targetWheel.onChanged(100.0);
      await tester.pump();

      await tester
          .tap(find.byKey(const ValueKey('body-weight-target-weight-confirm')));
      await tester.pumpAndSettle();
      expect(saveCalls, 0, reason: 'the Target step must not persist either');

      // Now on the Goal Pace step -- no goal selector, no target control.
      expect(find.byKey(const ValueKey('body-goal-option-gainWeight')),
          findsNothing);
      expect(find.byKey(const ValueKey('body-weight-wheel')), findsNothing);
      expect(find.byKey(const ValueKey('body-weight-goal-pace-slider')),
          findsOneWidget);

      await tester
          .tap(find.byKey(const ValueKey('body-weight-goal-pace-confirm')));
      await tester.pumpAndSettle();

      expect(saveCalls, 1);
      expect(saved?.goalType, BodyGoalType.gainWeight);
      expect(saved?.targetWeightKg, 100.0);
      expect(saved?.weeklyWeightChangeKg, isNotNull);
    });

    testWidgets(
        'cancelling the Target Weight step leaves the old goal unchanged',
        (tester) async {
      var saveCalls = 0;
      await tester.pumpWidget(
        buildApp(
          BodyWeightSettingsPage(
            bodyState:
                stateWith(currentWeightKg: 90, activeGoal: activeLoseGoal),
            weightUnit: WeightUnit.kg,
            onRecordCurrentWeight: (_) async {},
            onSaveBodyGoal: (_) async => saveCalls++,
          ),
        ),
      );

      await tester
          .tap(find.byKey(const ValueKey('body-weight-body-goal-field')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Yes'));
      await tester.pumpAndSettle();
      await tester
          .tap(find.byKey(const ValueKey('body-goal-option-gainWeight')));
      await tester.pumpAndSettle();
      await tester
          .tap(find.byKey(const ValueKey('body-weight-body-goal-continue')));
      await tester.pumpAndSettle();

      // Cancel out of the Target Weight step instead of confirming it.
      dismissOpenSheet(tester);
      await tester.pumpAndSettle();

      expect(saveCalls, 0);
      // Back on the page, the previous Lose goal is still shown.
      expect(find.text('Lose Weight'), findsOneWidget);
    });

    testWidgets('Maintain emits target=null and pace=null in one final save',
        (tester) async {
      var saveCalls = 0;
      BodyGoalUpdate? saved;
      await tester.pumpWidget(
        buildApp(
          BodyWeightSettingsPage(
            bodyState:
                stateWith(currentWeightKg: 70, activeGoal: activeLoseGoal),
            weightUnit: WeightUnit.kg,
            onRecordCurrentWeight: (_) async {},
            onSaveBodyGoal: (update) async {
              saveCalls++;
              saved = update;
            },
          ),
        ),
      );

      await tester
          .tap(find.byKey(const ValueKey('body-weight-body-goal-field')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Yes'));
      await tester.pumpAndSettle();

      await tester
          .tap(find.byKey(const ValueKey('body-goal-option-maintainWeight')));
      await tester.pumpAndSettle();
      await tester
          .tap(find.byKey(const ValueKey('body-weight-body-goal-continue')));
      await tester.pumpAndSettle();

      expect(saveCalls, 1);
      expect(saved?.goalType, BodyGoalType.maintainWeight);
      expect(saved?.targetWeightKg, isNull);
      expect(saved?.weeklyWeightChangeKg, isNull);
    });
  });

  group('Target Weight direct edit', () {
    testWidgets('opens a Target Weight-only sheet with no confirmation',
        (tester) async {
      await tester.pumpWidget(
        buildApp(
          BodyWeightSettingsPage(
            bodyState:
                stateWith(currentWeightKg: 90, activeGoal: activeLoseGoal),
            weightUnit: WeightUnit.kg,
            onRecordCurrentWeight: (_) async {},
            onSaveBodyGoal: (_) async {},
          ),
        ),
      );

      await tester
          .tap(find.byKey(const ValueKey('body-weight-target-weight-field')));
      await tester.pumpAndSettle();

      expect(find.text('Change Body Goal?'), findsNothing);
      expect(find.byKey(const ValueKey('body-goal-option-loseWeight')),
          findsNothing);
      expect(find.byType(Slider), findsNothing);
      expect(find.byKey(const ValueKey('body-weight-wheel')), findsOneWidget);
    });

    testWidgets('Lose direct edit requires target below current weight',
        (tester) async {
      var saveCalls = 0;
      await tester.pumpWidget(
        buildApp(
          BodyWeightSettingsPage(
            bodyState:
                stateWith(currentWeightKg: 90, activeGoal: activeLoseGoal),
            weightUnit: WeightUnit.kg,
            onRecordCurrentWeight: (_) async {},
            onSaveBodyGoal: (_) async => saveCalls++,
          ),
        ),
      );

      await tester
          .tap(find.byKey(const ValueKey('body-weight-target-weight-field')));
      await tester.pumpAndSettle();

      final wheel = tester.widget<TioWeightWheel>(
          find.byKey(const ValueKey('body-weight-wheel')));
      wheel.onChanged(95.0); // above current -- wrong direction for Lose
      await tester.pump();
      await tester
          .tap(find.byKey(const ValueKey('body-weight-target-weight-confirm')));
      await tester.pump();

      expect(saveCalls, 0);
      expect(find.textContaining('below Current Weight'), findsOneWidget);
    });

    testWidgets('Gain direct edit requires target above current weight',
        (tester) async {
      var saveCalls = 0;
      const activeGainGoal = BodyGoalState(
        goalType: BodyGoalType.gainWeight,
        startingWeightKg: 55,
        targetWeightKg: 70,
        weeklyWeightChangeKg: 0.5,
      );
      await tester.pumpWidget(
        buildApp(
          BodyWeightSettingsPage(
            bodyState:
                stateWith(currentWeightKg: 60, activeGoal: activeGainGoal),
            weightUnit: WeightUnit.kg,
            onRecordCurrentWeight: (_) async {},
            onSaveBodyGoal: (_) async => saveCalls++,
          ),
        ),
      );

      await tester
          .tap(find.byKey(const ValueKey('body-weight-target-weight-field')));
      await tester.pumpAndSettle();

      final wheel = tester.widget<TioWeightWheel>(
          find.byKey(const ValueKey('body-weight-wheel')));
      wheel.onChanged(55.0); // below current -- wrong direction for Gain
      await tester.pump();
      await tester
          .tap(find.byKey(const ValueKey('body-weight-target-weight-confirm')));
      await tester.pump();

      expect(saveCalls, 0);
      expect(find.textContaining('above Current Weight'), findsOneWidget);
    });

    testWidgets('direct Target edit preserves the existing Goal Pace',
        (tester) async {
      BodyGoalUpdate? saved;
      await tester.pumpWidget(
        buildApp(
          BodyWeightSettingsPage(
            bodyState:
                stateWith(currentWeightKg: 90, activeGoal: activeLoseGoal),
            weightUnit: WeightUnit.kg,
            onRecordCurrentWeight: (_) async {},
            onSaveBodyGoal: (update) async => saved = update,
          ),
        ),
      );

      await tester
          .tap(find.byKey(const ValueKey('body-weight-target-weight-field')));
      await tester.pumpAndSettle();

      final wheel = tester.widget<TioWeightWheel>(
          find.byKey(const ValueKey('body-weight-wheel')));
      wheel.onChanged(80.0);
      await tester.pump();
      await tester
          .tap(find.byKey(const ValueKey('body-weight-target-weight-confirm')));
      await tester.pumpAndSettle();

      expect(saved?.goalType, BodyGoalType.loseWeight);
      expect(saved?.targetWeightKg, 80.0);
      expect(saved?.weeklyWeightChangeKg, activeLoseGoal.weeklyWeightChangeKg);
    });
  });

  group('Goal Pace direct edit', () {
    testWidgets('opens a Goal Pace-only sheet with no confirmation',
        (tester) async {
      await tester.pumpWidget(
        buildApp(
          BodyWeightSettingsPage(
            bodyState:
                stateWith(currentWeightKg: 90, activeGoal: activeLoseGoal),
            weightUnit: WeightUnit.kg,
            onRecordCurrentWeight: (_) async {},
            onSaveBodyGoal: (_) async {},
          ),
        ),
      );

      await tester
          .tap(find.byKey(const ValueKey('body-weight-goal-pace-field')));
      await tester.pumpAndSettle();

      expect(find.text('Change Body Goal?'), findsNothing);
      expect(find.byKey(const ValueKey('body-goal-option-loseWeight')),
          findsNothing);
      expect(find.byKey(const ValueKey('body-weight-wheel')), findsNothing);
      expect(find.byKey(const ValueKey('body-weight-goal-pace-slider')),
          findsOneWidget);
    });

    testWidgets('stays within the 0.1-1.5 kg/week range with 0.1 increments',
        (tester) async {
      await tester.pumpWidget(
        buildApp(
          BodyWeightSettingsPage(
            bodyState:
                stateWith(currentWeightKg: 90, activeGoal: activeLoseGoal),
            weightUnit: WeightUnit.kg,
            onRecordCurrentWeight: (_) async {},
            onSaveBodyGoal: (_) async {},
          ),
        ),
      );

      await tester
          .tap(find.byKey(const ValueKey('body-weight-goal-pace-field')));
      await tester.pumpAndSettle();

      final slider = tester.widget<Slider>(
        find.byKey(const ValueKey('body-weight-goal-pace-slider')),
      );
      expect(slider.min, 0.1);
      expect(slider.max, 1.5);
      expect(slider.divisions, 14); // (1.5-0.1)/0.1 -> 0.1 increments
    });

    testWidgets('direct Pace edit preserves the existing Target Weight',
        (tester) async {
      BodyGoalUpdate? saved;
      await tester.pumpWidget(
        buildApp(
          BodyWeightSettingsPage(
            bodyState:
                stateWith(currentWeightKg: 90, activeGoal: activeLoseGoal),
            weightUnit: WeightUnit.kg,
            onRecordCurrentWeight: (_) async {},
            onSaveBodyGoal: (update) async => saved = update,
          ),
        ),
      );

      await tester
          .tap(find.byKey(const ValueKey('body-weight-goal-pace-field')));
      await tester.pumpAndSettle();
      await tester
          .tap(find.byKey(const ValueKey('body-weight-goal-pace-confirm')));
      await tester.pumpAndSettle();

      expect(saved?.goalType, BodyGoalType.loseWeight);
      expect(saved?.targetWeightKg, activeLoseGoal.targetWeightKg);
      expect(saved?.weeklyWeightChangeKg, isNotNull);
    });
  });
}
