import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tio_core/core.dart';
import 'package:tio_feature_onboarding/onboarding.dart';
import 'package:tio_shared/shared.dart';

void main() {
  Widget buildScreen({
    required AppMode mode,
    GoalIntentSelection selection = const GoalIntentSelection(),
    ValueChanged<GoalIntent>? onGoalTapped,
  }) {
    return MaterialApp(
      builder: (context, child) =>
          TioTheme(child: child ?? const SizedBox.shrink()),
      home: Scaffold(
        body: SingleChildScrollView(
          child: GoalIntentScreen(
            mode: mode,
            selection: selection,
            onGoalTapped: onGoalTapped ?? (_) {},
          ),
        ),
      ),
    );
  }

  testWidgets('nutrition keeps the existing card style with four single-goal choices',
      (tester) async {
    GoalIntent? tapped;

    await tester.pumpWidget(
      buildScreen(
        mode: AppMode.nutrition,
        selection: const GoalIntentSelection(
          primaryGoal: GoalIntent.loseWeight,
        ),
        onGoalTapped: (goal) => tapped = goal,
      ),
    );

    expect(find.text('What do you want to achieve?'), findsOneWidget);
    expect(find.text('Choose your main goal.'), findsOneWidget);
    expect(find.text('Lose weight'), findsOneWidget);
    expect(find.text('Gain weight'), findsOneWidget);
    expect(find.text('Maintain weight'), findsOneWidget);
    expect(find.text('Recomposition'), findsOneWidget);
    expect(find.text('Build muscle'), findsNothing);

    final lossCard = find.byKey(const ValueKey('goal-intent-loseWeight'));
    expect(
      find.descendant(of: lossCard, matching: find.byIcon(Icons.check_circle)),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('goal-intent-gainWeight')));
    expect(tapped, GoalIntent.gainWeight);
  });

  testWidgets('workout shows six training-aware choices and existing selection state',
      (tester) async {
    await tester.pumpWidget(
      buildScreen(
        mode: AppMode.workout,
        selection: const GoalIntentSelection(
          primaryGoal: GoalIntent.buildMuscle,
          supportingGoal: GoalIntent.getStronger,
        ),
      ),
    );

    expect(
      find.text('Choose your main goal and one supporting goal.'),
      findsOneWidget,
    );
    expect(find.text('Gain weight'), findsNothing);
    expect(find.text('Maintain weight'), findsNothing);
    expect(find.text('Build muscle'), findsOneWidget);
    expect(find.text('Get stronger'), findsOneWidget);
    expect(find.text('Improve endurance'), findsOneWidget);
    expect(find.text('Stay fit'), findsOneWidget);
    expect(find.text('Burn fat through consistent training'), findsOneWidget);

    for (final key in ['buildMuscle', 'getStronger']) {
      final card = find.byKey(ValueKey('goal-intent-$key'));
      expect(
        find.descendant(of: card, matching: find.byIcon(Icons.check_circle)),
        findsOneWidget,
      );
    }
  });

  testWidgets('hybrid reuses the same six cards with body-aware loss copy',
      (tester) async {
    await tester.pumpWidget(buildScreen(mode: AppMode.hybrid));

    expect(find.text('Build muscle'), findsOneWidget);
    expect(find.text('Get stronger'), findsOneWidget);
    expect(find.text('Improve endurance'), findsOneWidget);
    expect(find.text('Stay fit'), findsOneWidget);
    expect(find.text('Recomposition'), findsOneWidget);
    expect(find.text('Gain weight'), findsNothing);
    expect(find.text('Burn fat and reach a healthier weight'), findsOneWidget);
  });
}
