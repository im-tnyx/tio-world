import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tio_core/core.dart';
import 'package:tio_feature_workout/src/presentation/library/routines/routine_composer_screen.dart';

void main() {
  for (final mode in [RoutineComposerMode.create, RoutineComposerMode.edit]) {
    testWidgets('keyboard hide clears numeric focus in ${mode.name} mode',
        (tester) async {
      final focusNode = FocusNode();
      addTearDown(focusNode.dispose);
      addTearDown(tester.view.resetViewInsets);
      var lastValue = '';

      await tester.pumpWidget(MaterialApp(
        builder: (context, child) =>
            TioTheme(child: child ?? const SizedBox.shrink()),
        home: RoutineComposerScreen(
          mode: mode,
          pageKey: const ValueKey('test-composer'),
          cancelKey: const ValueKey('test-cancel'),
          cancelEnabled: true,
          cancel: () {},
          submitKey: const ValueKey('test-submit'),
          onSubmit: () {},
          content: Column(children: [
            TioInput.boxedNumber(
              key: const ValueKey('numeric'),
              focusNode: focusNode,
              onChanged: (value) => lastValue = value,
            ),
            const Expanded(child: SizedBox()),
          ]),
        ),
      ));
      final field = find.byKey(const ValueKey('numeric'));
      await tester.tap(field);
      await tester.enterText(field, '12');
      await tester.pump();
      expect(focusNode.hasFocus, isTrue);

      // Real Android/iOS keyboard show/hide changes viewInsets.
      tester.view.viewInsets = const FakeViewPadding(bottom: 300);
      await tester.pump();
      expect(focusNode.hasFocus, isTrue);

      tester.view.viewInsets = FakeViewPadding.zero;
      await tester.pump();
      expect(focusNode.hasFocus, isFalse);
      expect(lastValue, '12');
      expect(tester.takeException(), isNull);
    });
  }
}
