import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tio_core/core.dart';
import 'package:tio_feature_onboarding/onboarding.dart';

void main() {
  testWidgets('uses the existing goal-card pattern without a personalized title',
      (tester) async {
    var selectedGoal = BodyGoal.loseWeight;

    Widget build() => MaterialApp(
          builder: (context, child) =>
              TioTheme(child: child ?? const SizedBox.shrink()),
          home: Scaffold(
            body: SingleChildScrollView(
              child: BodyGoalScreen(
                selectedGoal: selectedGoal,
                onSelected: (goal) => selectedGoal = goal,
              ),
            ),
          ),
        );

    await tester.pumpWidget(build());

    expect(find.text("What's your body goal?"), findsOneWidget);
    expect(find.textContaining('Hi '), findsNothing);
    expect(find.text('Lose weight'), findsOneWidget);
    expect(find.text('Gain weight'), findsOneWidget);
    expect(find.text('Maintain weight'), findsOneWidget);
    expect(find.text('Body recomposition'), findsOneWidget);

    final lossCard = find.byKey(const ValueKey('body-goal-loseWeight'));
    expect(
      find.descendant(of: lossCard, matching: find.byIcon(Icons.check_circle)),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('body-goal-gainWeight')));
    await tester.pumpWidget(build());

    expect(selectedGoal, BodyGoal.gainWeight);
    final gainCard = find.byKey(const ValueKey('body-goal-gainWeight'));
    expect(
      find.descendant(of: gainCard, matching: find.byIcon(Icons.check_circle)),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: lossCard,
        matching: find.byIcon(Icons.radio_button_unchecked),
      ),
      findsOneWidget,
    );
  });
}
