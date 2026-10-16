import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tio_core/core.dart';
import 'package:tio_feature_workout/src/presentation/library/routines/routine_composer_screen.dart';

void main() {
  testWidgets('Create Save and Edit Update share the same top action slot',
      (tester) async {
    final rightEdges = <double>[];
    final topEdges = <double>[];
    var submits = 0;

    for (final mode in [RoutineComposerMode.create, RoutineComposerMode.edit]) {
      await tester.pumpWidget(MaterialApp(
        builder: (context, child) =>
            TioTheme(child: child ?? const SizedBox.shrink()),
        home: RoutineComposerScreen(
          mode: mode,
          pageKey: const ValueKey('shared-composer'),
          cancelKey: const ValueKey('shared-cancel'),
          cancelEnabled: true,
          cancel: () {},
          submitKey: const ValueKey('shared-submit'),
          onSubmit: () => submits++,
          content: const SizedBox.expand(),
        ),
      ));

      final submit = find.byKey(const ValueKey('shared-submit'));
      expect(submit, findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(TioAppBar),
          matching: submit,
        ),
        findsOneWidget,
      );
      expect(tester.widget<TextButton>(submit).child,
          isA<Text>());
      expect(
        (tester.widget<TextButton>(submit).child! as Text).data,
        mode == RoutineComposerMode.create ? 'Save' : 'Update',
      );
      expect(
        tester.widget<Scaffold>(
          find.byKey(const ValueKey('shared-composer')),
        ).bottomNavigationBar,
        isNull,
      );
      rightEdges.add(tester.getTopRight(submit).dx);
      topEdges.add(tester.getTopLeft(submit).dy);
      await tester.tap(submit);
      await tester.pump();
    }

    expect(submits, 2);
    expect(rightEdges[0], closeTo(rightEdges[1], 1));
    expect(topEdges[0], closeTo(topEdges[1], 1));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Edit Update is not exposed before its submit capability',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      builder: (context, child) =>
          TioTheme(child: child ?? const SizedBox.shrink()),
      home: const RoutineComposerScreen(
        mode: RoutineComposerMode.edit,
        pageKey: ValueKey('shared-composer'),
        cancelKey: ValueKey('shared-cancel'),
        cancelEnabled: true,
        cancel: () {},
        submitKey: null,
        content: SizedBox.expand(),
      ),
    ));
    expect(find.text('Update'), findsNothing);
    expect(
      tester.widget<Scaffold>(
        find.byKey(const ValueKey('shared-composer')),
      ).bottomNavigationBar,
      isNull,
    );
  });

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
