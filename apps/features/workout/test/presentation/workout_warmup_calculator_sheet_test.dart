import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tio_core/core.dart';
import 'package:tio_feature_workout/workout.dart';

import 'package:tio_feature_workout/src/presentation/widgets/workout_warmup_calculator_sheet.dart';

void main() {
  testWidgets('selected method previews rounded sets and inserts explicitly',
      (tester) async {
    List<WarmupCalculatedSet>? accepted;
    await tester.pumpWidget(MaterialApp(
      builder: (context, child) => TioTheme(child: child!),
      home: Scaffold(
        body: Builder(builder: (context) {
          return TextButton(
            onPressed: () async {
              accepted = await showWorkoutWarmupCalculatorSheet(
                context,
                settings: WorkoutWarmupSettings(plateRoundingKg: 2.5),
                availableSlots: 3,
              );
            },
            child: const Text('Open calculator'),
          );
        }),
      ),
    ));

    await tester.tap(find.text('Open calculator'));
    await tester.pumpAndSettle();
    expect(find.text('Warm-up Calculator'), findsOneWidget);
    expect(find.text('Classic'), findsOneWidget);
    expect(find.byKey(const ValueKey('warmup-preview-set-0')), findsOneWidget);
    expect(
        tester
            .widget<TioButton>(
              find.byKey(const ValueKey('warmup-add-sets')),
            )
            .enabled,
        isFalse);
    expect(accepted, isNull);

    await tester.enterText(
      find.descendant(
        of: find.byKey(const ValueKey('warmup-target-weight')),
        matching: find.byType(EditableText),
      ),
      '67',
    );
    await tester.pumpAndSettle();
    expect(find.text('27.5 kg × 5'), findsOneWidget);
    expect(find.text('40 kg × 5'), findsOneWidget);
    expect(find.text('52.5 kg × 3'), findsOneWidget);
    expect(
        tester
            .widget<TioButton>(
              find.byKey(const ValueKey('warmup-add-sets')),
            )
            .enabled,
        isTrue);

    await tester.tap(find.byKey(const ValueKey('warmup-add-sets')));
    await tester.pumpAndSettle();
    expect(accepted!.map((set) => set.loadKg).toList(), [27.5, 40, 52.5]);
  });

  testWidgets('dumbbell exercise uses the configured dumbbell increment',
      (tester) async {
    List<WarmupCalculatedSet>? accepted;
    final settings = WorkoutWarmupSettings(
      plateRoundingKg: 5,
      dumbbellRoundingKg: 1,
    );
    await tester.pumpWidget(MaterialApp(
      builder: (context, child) => TioTheme(child: child!),
      home: Scaffold(
        body: Builder(builder: (context) {
          return TextButton(
            onPressed: () async {
              accepted = await showWorkoutWarmupCalculatorSheet(
                context,
                settings: settings,
                availableSlots: 3,
                initialWeightKg: 67,
                isDumbbell: true,
              );
            },
            child: const Text('Open calculator'),
          );
        }),
      ),
    ));
    await tester.tap(find.text('Open calculator'));
    await tester.pumpAndSettle();
    expect(find.text('27 kg × 5'), findsOneWidget);
    expect(find.text('40 kg × 5'), findsOneWidget);
    expect(find.text('54 kg × 3'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('warmup-add-sets')));
    await tester.pumpAndSettle();
    expect(accepted!.map((set) => set.loadKg).toList(), [27, 40, 54]);
  });
}
