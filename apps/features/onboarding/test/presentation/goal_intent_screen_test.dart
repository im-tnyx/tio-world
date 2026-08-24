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

  testWidgets('nutrition keeps Tio card style with three weight choices',
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
    expect(find.text('Recomposition'), findsNothing);
    expect(find.text('Build muscle'), findsNothing);

    final lossCard = find.byKey(const ValueKey('goal-intent-loseWeight'));
    expect(
      find.descendant(of: lossCard, matching: find.byIcon(Icons.check_circle)),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('goal-intent-gainWeight')));
    expect(tapped, GoalIntent.gainWeight);
  });

  testWidgets('workout shows seven refined choices and three selected cards',
      (tester) async {
    await tester.pumpWidget(
      buildScreen(
        mode: AppMode.workout,
        selection: const GoalIntentSelection(
          primaryGoal: GoalIntent.loseWeight,
          supportingGoal: GoalIntent.buildMuscle,
          tertiaryGoal: GoalIntent.getStronger,
        ),
      ),
    );

    expect(
      find.text('Choose what fits you. Select up to two training goals.'),
      findsOneWidget,
    );
    expect(find.text('Lose weight'), findsOneWidget);
    expect(find.text('Gain weight'), findsOneWidget);
    expect(find.text('Maintain weight'), findsOneWidget);
    expect(find.text('Build muscle'), findsOneWidget);
    expect(find.text('Boost strength'), findsOneWidget);
    expect(find.text('Improve endurance'), findsOneWidget);
    expect(find.text('Keep fit'), findsOneWidget);
    expect(find.text('Recomposition'), findsNothing);

    for (final key in ['loseWeight', 'buildMuscle', 'getStronger']) {
      final card = find.byKey(ValueKey('goal-intent-$key'));
      expect(
        find.descendant(of: card, matching: find.byIcon(Icons.check_circle)),
        findsOneWidget,
      );
    }
  });

  testWidgets('hybrid reuses same Tio seven-card vocabulary and copy',
      (tester) async {
    await tester.pumpWidget(buildScreen(mode: AppMode.hybrid));

    expect(find.text('Reduce body weight and body fat'), findsOneWidget);
    expect(find.text('Gain body weight gradually and healthily'), findsOneWidget);
    expect(find.text('Increase muscle size and lean mass'), findsOneWidget);
    expect(find.text('Improve strength and lifting performance'), findsOneWidget);
    expect(find.text('Improve cardio, stamina and conditioning'), findsOneWidget);
    expect(find.text('Maintain overall fitness, energy and health'), findsOneWidget);
    expect(find.text('Recomposition'), findsNothing);
  });
}
