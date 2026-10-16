import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tio_core/core.dart';
import 'package:tio_feature_workout/workout.dart';
import 'package:tio_shared/shared.dart';
import 'package:tio_feature_workout/src/presentation/library/routines/routine_composer_screen.dart';

void main() {
  testWidgets('Create Save and Edit Update share the same top action slot',
      (tester) async {
    final rightEdges = <double>[];
    final topEdges = <double>[];
    var submits = 0;
    var cancels = 0;
    final titleStarts = <double>[];

    for (final mode in [RoutineComposerMode.create, RoutineComposerMode.edit]) {
      await tester.pumpWidget(MaterialApp(
        builder: (context, child) =>
            TioTheme(child: child ?? const SizedBox.shrink()),
        home: RoutineComposerScreen(
          mode: mode,
          pageKey: const ValueKey('shared-composer'),
          cancelKey: const ValueKey('shared-cancel'),
          cancelEnabled: true,
          cancel: () => cancels++,
          submitKey: const ValueKey('shared-submit'),
          onSubmit: () => submits++,
          content: const SizedBox.expand(),
        ),
      ));

      final close = find.byKey(const ValueKey('shared-cancel'));
      final title = find.byKey(const ValueKey('routine-composer-title'));
      final submit = find.byKey(const ValueKey('shared-submit'));
      expect(close, findsOneWidget);
      expect(tester.widget<IconButton>(close).tooltip, 'Cancel');
      expect(
        find.descendant(of: close, matching: find.byIcon(Icons.close_rounded)),
        findsOneWidget,
      );
      expect(find.text('Cancel'), findsNothing);
      expect(title, findsOneWidget);
      expect(
        tester.widget<Text>(title).data,
        mode == RoutineComposerMode.create ? 'Create Routine' : 'Edit Routine',
      );
      expect(
        tester.widget<Text>(title).style?.fontSize,
        TioFontSize.size18,
        reason: 'Keep the originally approved shared app-bar title size',
      );
      expect(
        tester.widget<Text>(title).style?.fontWeight,
        TioFontWeight.w800,
        reason: 'Create and Edit app-bar typography must not follow exercise names',
      );
      expect(tester.getTopLeft(title).dx, greaterThan(tester.getCenter(close).dx));
      expect(tester.getTopLeft(title).dx, lessThan(tester.getCenter(submit).dx));
      titleStarts.add(tester.getTopLeft(title).dx);
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
      await tester.tap(close);
      await tester.pump();
    }

    expect(submits, 2);
    expect(cancels, 2);
    expect(titleStarts[0], closeTo(titleStarts[1], 1));
    expect(rightEdges[0], closeTo(rightEdges[1], 1));
    expect(topEdges[0], closeTo(topEdges[1], 1));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Edit Update is not exposed before its submit capability',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      builder: (context, child) =>
          TioTheme(child: child ?? const SizedBox.shrink()),
      home: RoutineComposerScreen(
        mode: RoutineComposerMode.edit,
        pageKey: const ValueKey('shared-composer'),
        cancelKey: const ValueKey('shared-cancel'),
        cancelEnabled: true,
        cancel: () {},
        submitKey: null,
        content: const SizedBox.expand(),
      ),
    ));
    expect(find.text('Update'), findsNothing);
    expect(
      tester.widget<IconButton>(
        find.byKey(const ValueKey('shared-cancel')),
      ).onPressed,
      isNotNull,
    );
    expect(
      tester.widget<Scaffold>(
        find.byKey(const ValueKey('shared-composer')),
      ).bottomNavigationBar,
      isNull,
    );
  });

  testWidgets('X and start-aligned title stay usable at compact width',
      (tester) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;

    for (final theme in [TioThemeMode.light, TioThemeMode.dark]) {
      for (final mode in [
        RoutineComposerMode.create,
        RoutineComposerMode.edit,
      ]) {
        var cancelled = false;
        await tester.pumpWidget(MaterialApp(
          builder: (context, child) => TioTheme(
            config: TioThemeConfig(mode: theme),
            child: child ?? const SizedBox.shrink(),
          ),
          home: RoutineComposerScreen(
            mode: mode,
            pageKey: const ValueKey('compact-composer'),
            cancelKey: const ValueKey('compact-close'),
            cancelEnabled: true,
            cancel: () => cancelled = true,
            submitKey: const ValueKey('compact-submit'),
            onSubmit: () {},
            content: const SizedBox.expand(),
          ),
        ));
        final close = find.byKey(const ValueKey('compact-close'));
        final title = find.byKey(const ValueKey('routine-composer-title'));
        final submit = find.byKey(const ValueKey('compact-submit'));
        expect(close, findsOneWidget);
        expect(title, findsOneWidget);
        expect(submit, findsOneWidget);
        final titleStyle = tester.widget<Text>(title).style;
        expect(titleStyle?.fontSize, TioFontSize.size18);
        expect(titleStyle?.fontWeight, TioFontWeight.w800);
        expect(tester.getTopRight(close).dx,
            lessThan(tester.getTopRight(submit).dx));
        expect(tester.takeException(), isNull);
        await tester.tap(close);
        await tester.pump();
        expect(cancelled, isTrue);
      }
    }
  });

  testWidgets('Create and Edit exercise names use 16sp w500 without resizing the app bar',
      (tester) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.view.physicalSize = const Size(320, 720);
    tester.view.devicePixelRatio = 1;
    const title = 'Barbell Standing Military Press (Without Rack)';
    double? previousStart;
    double? headerToSetSpacing;
    const setId = '44444444-4444-4444-8444-444444444444';
    final entry = RoutineCompositionEntry(
      id: '33333333-3333-4333-8333-333333333333',
      exercise: ExerciseRef.catalog('ex_bench_press'),
      sets: [
        RoutineCompositionSet(
          id: setId,
          prescription: SetPrescription(reps: 8),
        ),
      ],
    );
    for (final theme in [TioThemeMode.light, TioThemeMode.dark]) {
      for (final mode in [RoutineComposerMode.create, RoutineComposerMode.edit]) {
        await tester.pumpWidget(MaterialApp(
          builder: (context, child) => TioTheme(
            config: TioThemeConfig(mode: theme),
            child: child ?? const SizedBox.shrink(),
          ),
          home: Scaffold(
            body: RoutineComposerExerciseCard(
              mode: mode,
              entry: entry,
              index: 0,
              totalEntries: 1,
              title: title,
              thumbnailUrl: null,
              exerciseType: null,
              showRangeDraft: false,
              unit: WeightUnit.kg,
              enabled: false,
              moveUp: () {},
              moveDown: () {},
              showOptions: () {},
              selectRepetitionMode: () {},
              buildSetRow: (set, index) => RoutineSetInputRow(
                set: set,
                index: index,
                normalNumber: index + 1,
                onTypePressed: () {},
                unit: WeightUnit.kg,
                enabled: false,
                showPrevious: true,
                useEditSetNumberColor: mode == RoutineComposerMode.edit,
                isOpen: false,
                onOpenChanged: (_) {},
                onChanged: (_) {},
                onValidityChanged: (_) {},
                onRemove: () {},
              ),
              addSet: () {},
            ),
          ),
        ));
        final exerciseName = find.text(title);
        expect(exerciseName, findsOneWidget);
        final label = tester.widget<Text>(exerciseName);
        expect(label.style?.fontSize, TioFontSize.size16);
        expect(label.style?.fontWeight, TioFontWeight.w500);
        expect(label.maxLines, 2);
        expect(label.overflow, TextOverflow.ellipsis);
        expect(find.text('SET'), findsOneWidget);
        final previous = find.text('PREVIOUS');
        expect(previous, findsOneWidget,
            reason: 'Both composer modes reserve the same history header');
        final start = tester.getTopLeft(previous).dx;
        if (previousStart != null) {
          expect(start, closeTo(previousStart, 0.01));
        }
        previousStart = start;
        // Both modes show only an unavailable placeholder until actual
        // performed Set history is available, never prescribed targets.
        final previousCell = find.byKey(
          const ValueKey('routine-set-previous-$setId'),
        );
        expect(previousCell, findsOneWidget);
        expect(tester.widget<Text>(previousCell).data, '–');
        final setBox = find.byKey(const ValueKey('routine-set-type-box-$setId'));
        expect(setBox, findsOneWidget);
        final relativeGap =
            tester.getTopLeft(setBox).dy - tester.getBottomLeft(previous).dy;
        if (headerToSetSpacing != null) {
          expect(relativeGap, closeTo(headerToSetSpacing, 0.01));
        }
        headerToSetSpacing = relativeGap;
        final options = find.byTooltip('Exercise options');
        expect(options, findsOneWidget);
        expect(
          tester.getTopRight(exerciseName).dx,
          closeTo(tester.getTopLeft(options).dx, 0.01),
          reason: 'Name width ends before the reserved 3-dot action slot',
        );
        expect(tester.takeException(), isNull);
      }
    }
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
