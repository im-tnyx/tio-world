import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tio_core/core.dart';
import 'package:tio_feature_workout/workout.dart';

import 'package:tio_feature_workout/src/presentation/widgets/workout_warmup_methods_sheet.dart';

void main() {
  testWidgets('method picker and editor fit compact light and dark screens',
      (tester) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    for (final mode in [TioThemeMode.light, TioThemeMode.dark]) {
      await tester.pumpWidget(MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: const TextScaler.linear(1.3),
          ),
          child: TioTheme(
            config: TioThemeConfig(mode: mode),
            child: child!,
          ),
        ),
        home: Scaffold(
          body: Builder(builder: (context) {
            return TextButton(
              onPressed: () => showWorkoutWarmupMethodsSheet(
                context,
                settings: WorkoutWarmupSettings(),
              ),
              child: const Text('Open methods'),
            );
          }),
        ),
      ));
      await tester.tap(find.text('Open methods'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.tap(find.byKey(const ValueKey('warmup-method-add')));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    }
  });

  testWidgets('method selector returns the chosen built-in method',
      (tester) async {
    WorkoutWarmupSettings? result;
    await tester.pumpWidget(_app(
      onOpen: (context) async {
        result = await showWorkoutWarmupMethodsSheet(
          context,
          settings: WorkoutWarmupSettings(),
        );
      },
    ));

    await tester.tap(find.text('Open methods'));
    await tester.pumpAndSettle();
    expect(find.text('Warm-up methods'), findsOneWidget);
    expect(find.text('Classic'), findsOneWidget);
    expect(find.text('Recommended'), findsOneWidget);
    expect(find.text('Strength'), findsOneWidget);
    expect(find.text('Barbell Ramp'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('warmup-method-strength')));
    await tester.tap(find.byKey(const ValueKey('warmup-methods-done')));
    await tester.pumpAndSettle();
    expect(result?.selectedMethodId, WorkoutWarmupMethod.strengthId);
    expect(result?.selectedMethod.name, 'Strength');
    expect(tester.takeException(), isNull);
  });

  testWidgets('plus adds a named method with editable set count',
      (tester) async {
    WorkoutWarmupSettings? result;
    await tester.pumpWidget(_app(
      onOpen: (context) async {
        result = await showWorkoutWarmupMethodsSheet(
          context,
          settings: WorkoutWarmupSettings(),
        );
      },
    ));

    await tester.tap(find.text('Open methods'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('warmup-method-add')));
    await tester.pumpAndSettle();
    expect(find.text('Add warm-up method'), findsOneWidget);

    await tester.enterText(
      find.descendant(
        of: find.byKey(const ValueKey('warmup-method-name')),
        matching: find.byType(EditableText),
      ),
      'Test',
    );
    await tester.tap(find.byKey(const ValueKey('warmup-method-add-set')));
    await tester.pumpAndSettle();
    expect(find.text('Set 2'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('warmup-method-save')));
    await tester.pumpAndSettle();
    expect(find.text('Test'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('warmup-methods-done')));
    await tester.pumpAndSettle();

    expect(result?.selectedMethod.name, 'Test');
    expect(result?.selectedMethod.sets, hasLength(2));
    expect(tester.takeException(), isNull);
  });
}

Widget _app({required ValueChanged<BuildContext> onOpen}) => MaterialApp(
      builder: (context, child) => TioTheme(child: child!),
      home: Scaffold(
        body: Builder(builder: (context) {
          return TextButton(
            onPressed: () => onOpen(context),
            child: const Text('Open methods'),
          );
        }),
      ),
    );
