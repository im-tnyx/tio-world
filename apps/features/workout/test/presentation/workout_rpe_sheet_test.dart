import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tio_core/core.dart';
import 'package:tio_feature_workout/src/presentation/widgets/workout_rpe_sheet.dart';

void main() {
  Widget buildSheet({
    required int setNumber,
    double? loadKg,
    int? reps,
    double? initialRpe,
    ValueChanged<double?>? onDone,
    TioThemeMode mode = TioThemeMode.dark,
  }) {
    return MaterialApp(
      builder: (context, child) => TioTheme(
        config: TioThemeConfig(mode: mode),
        child: child ?? const SizedBox.shrink(),
      ),
      home: Scaffold(
        body: WorkoutRpeSheet(
          setNumber: setNumber,
          loadKg: loadKg,
          reps: reps,
          initialRpe: initialRpe,
          onDone: onDone ?? (_) {},
        ),
      ),
    );
  }


  for (final mode in [
    TioThemeMode.light,
    TioThemeMode.dark,
    TioThemeMode.tioDark,
  ]) {
    testWidgets('selected RPE option uses onPrimary contrast in ${mode.name}',
        (tester) async {
      await tester.pumpWidget(buildSheet(
        setNumber: 1,
        mode: mode,
      ));
      await tester.pumpAndSettle();
      final option = find.byKey(const ValueKey('rpe-option-7.5'));
      final optionText = find.descendant(
        of: option,
        matching: find.text('7.5'),
      );
      final colors = tester.element(option).tioColors;
      expect(tester.widget<Text>(optionText).style?.color,
          colors.textPrimary);
      await tester.tap(option);
      await tester.pumpAndSettle();
      // The selected circular background is primary. Fixed white can become
      // invisible against light/accent primary themes; onPrimary is the
      // theme-owned contrasting foreground.
      expect(tester.widget<Text>(optionText).style?.color, colors.onPrimary);
      expect(colors.onPrimary, isNot(colors.primary));
      await tester.tap(option);
      await tester.pumpAndSettle();
      expect(tester.widget<Text>(optionText).style?.color,
          colors.textPrimary);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('renders initial unselected state with 0 and Select RPE',
      (tester) async {
    await tester.pumpWidget(
      buildSheet(
        setNumber: 1,
        loadKg: 0,
        reps: 0,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Log Set RPE'), findsOneWidget);
    expect(find.text('Set 1: 0kg x 0 reps'), findsOneWidget);
    expect(find.text('0'), findsOneWidget);
    expect(find.text('Select RPE'), findsOneWidget);
    expect(find.text('Done'), findsOneWidget);

    for (final val in RpeMetadata.values) {
      expect(
        find.byKey(ValueKey('rpe-option-${RpeMetadata.format(val)}')),
        findsOneWidget,
      );
    }
  });

  testWidgets('selecting 7.5 updates display to Vigorous Effort and 3 more reps',
      (tester) async {
    double? result;
    await tester.pumpWidget(
      buildSheet(
        setNumber: 2,
        loadKg: 80,
        reps: 8,
        onDone: (val) => result = val,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Set 2: 80kg x 8 reps'), findsOneWidget);

    // Tap 7.5
    await tester.tap(find.byKey(const ValueKey('rpe-option-7.5')));
    await tester.pumpAndSettle();

    expect(find.text('7.5'), findsNWidgets(2)); // Big number and option pill
    expect(find.text('Vigorous Effort'), findsOneWidget);
    expect(find.text('Could have maybe done 3 more reps'), findsOneWidget);

    // Tap Done
    await tester.tap(find.byKey(const ValueKey('rpe-sheet-done-button')));
    await tester.pumpAndSettle();

    expect(result, 7.5);
  });

  testWidgets('selecting 10 updates display to Max Effort', (tester) async {
    double? result;
    await tester.pumpWidget(
      buildSheet(
        setNumber: 1,
        loadKg: 100,
        reps: 5,
        onDone: (val) => result = val,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('rpe-option-10')));
    await tester.pumpAndSettle();

    expect(find.text('Max Effort'), findsOneWidget);
    expect(find.text("Couldn't have done more reps"), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('rpe-sheet-done-button')));
    await tester.pumpAndSettle();

    expect(result, 10.0);
  });

  testWidgets('tapping already selected option deselects and returns 0 on done',
      (tester) async {
    double? result;
    await tester.pumpWidget(
      buildSheet(
        setNumber: 1,
        initialRpe: 8.0,
        onDone: (val) => result = val,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Hard Effort'), findsOneWidget);

    // Deselect 8
    await tester.tap(find.byKey(const ValueKey('rpe-option-8')));
    await tester.pumpAndSettle();

    expect(find.text('0'), findsOneWidget);
    expect(find.text('Select RPE'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('rpe-sheet-done-button')));
    await tester.pumpAndSettle();

    expect(result, 0.0);
  });

  testWidgets('renders reusable TioButton for Done action', (tester) async {
    await tester.pumpWidget(
      buildSheet(
        setNumber: 1,
        loadKg: 0,
        reps: 0,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(TioButton), findsOneWidget);
    expect(find.byKey(const ValueKey('rpe-sheet-done-button')), findsOneWidget);
  });

  testWidgets('sliding from 6 to 8 updates selection to 8 and displays description',
      (tester) async {
    double? result;
    await tester.pumpWidget(
      buildSheet(
        setNumber: 1,
        loadKg: 50,
        reps: 10,
        onDone: (val) => result = val,
      ),
    );
    await tester.pumpAndSettle();

    // Tap 6 first
    await tester.tap(find.byKey(const ValueKey('rpe-option-6')));
    await tester.pumpAndSettle();
    expect(find.text('Light Effort'), findsOneWidget);

    // Now slide from option 6 to option 8
    final option6 = find.byKey(const ValueKey('rpe-option-6'));
    final option8 = find.byKey(const ValueKey('rpe-option-8'));

    final start = tester.getCenter(option6);
    final end = tester.getCenter(option8);

    final gesture = await tester.startGesture(start);
    await tester.pump();
    await gesture.moveTo(end);
    await tester.pumpAndSettle();
    await gesture.up();
    await tester.pumpAndSettle();

    expect(find.text('Hard Effort'), findsOneWidget);
    expect(find.text('Could have done 2 more reps'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('rpe-sheet-done-button')));
    await tester.pumpAndSettle();

    expect(result, 8.0);
  });
}
