import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tio_core/core.dart';
import 'package:tio_feature_workout/workout.dart';
import 'package:tio_shared/shared.dart';

void main() {
  for (final mode in [TioThemeMode.dark, TioThemeMode.light]) {
    testWidgets('Set 1 and 2 have visible filled rounded boxes in '
        '${mode.name}', (tester) async {
      tester.view.physicalSize = const Size(320, 720);
      tester.view.devicePixelRatio = 1;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      const ids = [
        '55555555-5555-4555-8555-555555555555',
        '66666666-6666-4666-8666-666666666666',
      ];
      final palette =
          mode == TioThemeMode.dark ? TioColors.oled : TioColors.light;
      await tester.pumpWidget(MaterialApp(
        builder: (context, child) => TioTheme(
          config: TioThemeConfig(mode: mode),
          child: child ?? const SizedBox.shrink(),
        ),
        home: Scaffold(
          body: Column(children: [
            for (var index = 0; index < ids.length; index++)
              RoutineSetInputRow(
                set: RoutineCompositionSet(
                  id: ids[index],
                  prescription: SetPrescription(reps: 8),
                ),
                index: index,
                normalNumber: index + 1,
                onTypePressed: () {},
                unit: WeightUnit.kg,
                enabled: true,
                isOpen: false,
                onOpenChanged: (_) {},
                onChanged: (_) {},
                onValidityChanged: (_) {},
                onRemove: () {},
              ),
            TioButton.supporting(
              key: const ValueKey('test-add-set'),
              label: 'Add Set',
              leading: const Icon(Icons.add),
              expand: true,
              onPressed: () {},
            ),
          ]),
        ),
      ));
      final addSet = find.byKey(const ValueKey('test-add-set'));
      final filledButton = find.descendant(
        of: addSet,
        matching: find.byType(FilledButton),
      );
      expect(filledButton, findsOneWidget);
      // The default Material tap area can exceed the visual button body.
      // Match the actual filled Material surface, not just the style token.
      final filledSurface = find.descendant(
        of: filledButton,
        matching: find.byType(Material),
      );
      expect(filledSurface, findsWidgets);
      expect(tester.getSize(filledSurface.first).height, TioSize.dp38);
      for (var index = 0; index < ids.length; index++) {
        final box = find.byKey(ValueKey('routine-set-type-box-${ids[index]}'));
        expect(box, findsOneWidget);
        final decoration = tester.widget<Container>(box).decoration!
            as BoxDecoration;
        expect(decoration.color, palette.surfaceVariant);
        expect(decoration.color, isNot(palette.background));
        final expectedRadius = BorderRadius.circular(TioInputTokens.radius);
        expect(decoration.borderRadius, expectedRadius,
            reason: 'SET surface and boxed KG/REPS outlines must match');
        final setTap = find.byKey(ValueKey('routine-set-type-${ids[index]}'));
        expect(tester.widget<InkWell>(setTap).borderRadius, expectedRadius,
            reason: 'Ink/tap clipping must follow the painted SET radius');
        expect(tester.getSize(box).width, TioSize.dp38);
        final setHeight = tester.getSize(box).height;
        final weight = find.byKey(
          ValueKey('routine-set-weight-${ids[index]}'),
        );
        final reps = find.byKey(
          ValueKey('routine-set-reps-${ids[index]}'),
        );
        expect(setHeight, TioSize.dp38);
        expect(tester.getSize(weight).height, setHeight);
        expect(tester.getSize(reps).height, setHeight);
        // The screenshot concern is the *painted outline*, not just the
        // surrounding TioInput size. InputDecorator owns the outlined shape.
        for (final input in [weight, reps]) {
          final outline = find.descendant(
            of: input, matching: find.byType(InputDecorator),
          );
          expect(outline, findsOneWidget);
          expect(tester.getSize(outline).height, setHeight);
          final field = tester.widget<TextField>(
            find.descendant(of: input, matching: find.byType(TextField)),
          );
          final enabledBorder = field.decoration!.enabledBorder;
          final focusedBorder = field.decoration!.focusedBorder;
          expect(enabledBorder, isA<OutlineInputBorder>());
          expect(focusedBorder, isA<OutlineInputBorder>());
          expect((enabledBorder! as OutlineInputBorder).borderRadius,
              decoration.borderRadius);
          expect((focusedBorder! as OutlineInputBorder).borderRadius,
              decoration.borderRadius);
          expect(tester.getTopLeft(outline).dy,
              closeTo(tester.getTopLeft(box).dy, 0.01),
              reason: 'Visible SET and outlined input top edges must align');
          expect(tester.getBottomLeft(outline).dy,
              closeTo(tester.getBottomLeft(box).dy, 0.01),
              reason: 'Visible SET and outlined input bottom edges must align');
        }
        expect(tester.getSize(filledSurface.first).height, setHeight);
        expect(find.text('${index + 1}'), findsOneWidget);
        expect(find.byKey(ValueKey('routine-set-type-${ids[index]}')),
            findsOneWidget);
      }
      expect(tester.takeException(), isNull);
    });

    testWidgets('swipe shows compact rounded Delete with tactile feedback in '
        '${mode.name}', (tester) async {
      tester.view.physicalSize = const Size(320, 720);
      tester.view.devicePixelRatio = 1;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      final feedback = <String>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'HapticFeedback.vibrate') {
            feedback.add(call.arguments as String? ?? '');
          }
          return null;
        },
      );
      addTearDown(() => tester.binding.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null));
      const id = '55555555-5555-4555-8555-555555555555';
      final colors = mode == TioThemeMode.dark
          ? TioColors.oled : TioColors.light;
      var open = false;
      var deletes = 0;
      await tester.pumpWidget(MaterialApp(
        builder: (context, child) => TioTheme(
          config: TioThemeConfig(mode: mode),
          child: child ?? const SizedBox.shrink(),
        ),
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) => RoutineSetInputRow(
              set: RoutineCompositionSet(
                id: id,
                prescription: SetPrescription(reps: 10),
              ),
              index: 0,
              normalNumber: 1,
              onTypePressed: () {},
              unit: WeightUnit.kg,
              enabled: true,
              isOpen: open,
              onOpenChanged: (value) => setState(() => open = value),
              onChanged: (_) {},
              onValidityChanged: (_) {},
              onRemove: () => deletes++,
            ),
          ),
        ),
      ));
      final swipe = find.byKey(const ValueKey('routine-set-swipe-$id'));
      final delete = find.byKey(const ValueKey('routine-set-remove-$id'));
      // At rest no hidden oversized red shape may be painted.
      expect(delete, findsNothing);
      final gesture = await tester.startGesture(tester.getCenter(swipe));
      await gesture.moveBy(const Offset(-55, 0));
      await tester.pump();
      expect(delete, findsOneWidget);
      final shortWidth = tester.getSize(delete).width;
      expect(shortWidth, closeTo(55 - TioSpacing.sm, 1));
      // The complete rounded capsule is exposed, not cropped by the
      // displaced Set foreground.
      expect(tester.getTopLeft(delete).dx,
          closeTo(tester.getTopRight(swipe).dx + TioSpacing.sm, 1),
          reason: 'Delete needs the same 8dp gap as adjacent numeric fields');

      await gesture.moveBy(const Offset(-70, 0));
      await tester.pump();
      final wideWidth = tester.getSize(delete).width;
      expect(wideWidth, closeTo(125 - TioSpacing.sm, 1));
      expect(wideWidth, greaterThan(shortWidth));
      expect(tester.getTopLeft(delete).dx,
          closeTo(tester.getTopRight(swipe).dx + TioSpacing.sm, 1),
          reason: 'Delete needs the same 8dp gap as adjacent numeric fields');
      expect(deletes, 0,
          reason: 'Drag movement alone must not delete the Set');
      await gesture.up();
      await tester.pumpAndSettle();
      // The settled 96dp reveal includes 8dp of exposed background gap.
      expect(tester.getSize(delete).width,
          TioSize.dp48 + TioSize.dp48 - TioSpacing.sm);
      expect(open, isTrue);
      expect(deletes, 0);
      expect(feedback, contains('HapticFeedbackType.selectionClick'));

      final action = tester.widget<TextButton>(delete);
      expect(action.onPressed, isNotNull);
      expect(action.style!.backgroundColor!.resolve({}), colors.danger);
      expect(action.style!.foregroundColor!.resolve({}), Colors.white);
      expect(action.style!.foregroundColor!
          .resolve({WidgetState.disabled}), Colors.white);
      final whiteLabel = find.descendant(
        of: delete, matching: find.text('Delete'),
      );
      expect(whiteLabel, findsOneWidget,
          reason: 'Delete label remains visible after settling');
      expect(tester.widget<Text>(whiteLabel).style!.color, Colors.white);
      expect(action.style!.minimumSize!.resolve({}),
          const Size(0, TioSize.dp38));
      expect(action.style!.fixedSize!.resolve({})!.height,
          TioSize.dp38,
          reason: 'Painted Delete surface must be 38dp, not only minimum');
      expect(action.style!.tapTargetSize, MaterialTapTargetSize.padded,
          reason: 'Keep standard Material tap-target policy');
      final shape = action.style!.shape!.resolve({});
      expect(shape, isA<RoundedRectangleBorder>());
      expect((shape! as RoundedRectangleBorder).borderRadius,
          BorderRadius.circular(TioInputTokens.radius));
      // The row behind the action must stay black/normal surface; only
      // the Delete button may paint the destructive fill.
      expect(find.byWidgetPredicate((widget) =>
          widget is ColoredBox && widget.color == colors.danger),
          findsNothing);
      final material = find.descendant(
        of: delete,
        matching: find.byType(Material),
      );
      expect(material, findsWidgets);
      expect(tester.getSize(material.first).height, TioSize.dp38);
      final repsField = find.byKey(const ValueKey('routine-set-reps-$id'));
      expect(tester.getTopLeft(material.first).dy,
          closeTo(tester.getTopLeft(repsField).dy, 0.01),
          reason: 'Delete and REPS top edges must align');
      expect(tester.getBottomLeft(material.first).dy,
          closeTo(tester.getBottomLeft(repsField).dy, 0.01));
      await tester.tap(delete);
      await tester.pumpAndSettle();
      expect(deletes, 1);
      expect(feedback, contains('HapticFeedbackType.mediumImpact'));
      expect(tester.takeException(), isNull);
    });

    testWidgets('Edit PREVIOUS Set number is blue on matching filled '
        '38dp Create badge in ${mode.name}', (tester) async {
      tester.view.physicalSize = const Size(320, 720);
      tester.view.devicePixelRatio = 1;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      const id = '55555555-5555-4555-8555-555555555555';
      var selections = 0;
      final palette =
          mode == TioThemeMode.dark ? TioColors.oled : TioColors.light;
      await tester.pumpWidget(MaterialApp(
        builder: (context, child) => TioTheme(
          config: TioThemeConfig(mode: mode),
          child: child ?? const SizedBox.shrink(),
        ),
        home: Scaffold(
          // Deliberately supply a tall bounded viewport: the filled
          // SET surface must shrink-wrap to 38dp rather than fill 712dp.
          // Real Create/Edit page compositions are checked separately.
          body: RoutineSetInputRow(
            set: RoutineCompositionSet(
              id: id,
              prescription: SetPrescription(reps: 8),
            ),
            index: 0,
            normalNumber: 1,
            onTypePressed: () => selections++,
            unit: WeightUnit.kg,
            enabled: true,
            showPrevious: true,
            useEditSetNumberColor: true,
            isOpen: false,
            onOpenChanged: (_) {},
            onChanged: (_) {},
            onValidityChanged: (_) {},
            onRemove: () {},
          ),
        ),
      ));
      final setBox = find.byKey(const ValueKey('routine-set-type-box-$id'));
      final decoration =
          tester.widget<Container>(setBox).decoration! as BoxDecoration;
      expect(decoration.color, palette.surfaceVariant,
          reason: 'Edit and Create must share the filled SET badge surface');
      expect(decoration.color, isNot(palette.background));
      expect(decoration.borderRadius,
          BorderRadius.circular(TioInputTokens.radius));
      expect(tester.getSize(setBox).height, TioSize.dp38);
      expect(tester.getSize(setBox).width, TioSize.dp38);
      final number = find.descendant(of: setBox, matching: find.text('1'));
      expect(number, findsOneWidget);
      expect(tester.widget<Text>(number).style!.color, palette.primary);
      final weight = find.byKey(const ValueKey('routine-set-weight-$id'));
      final reps = find.byKey(const ValueKey('routine-set-reps-$id'));
      for (final input in [weight, reps]) {
        expect(tester.getSize(input).height, TioSize.dp38);
        final outline = find.descendant(
          of: input, matching: find.byType(InputDecorator),
        );
        expect(outline, findsOneWidget);
        expect(tester.getSize(outline).height, TioSize.dp38);
        // Prove the painted field and SET control are aligned on both edges.
        expect(tester.getTopLeft(outline).dy,
            closeTo(tester.getTopLeft(setBox).dy, 0.01));
        expect(tester.getBottomLeft(outline).dy,
            closeTo(tester.getBottomLeft(setBox).dy, 0.01));
      }
      await tester.tap(find.byKey(const ValueKey('routine-set-type-$id')));
      expect(selections, 1,
          reason: 'Edit blue number inside filled badge must open Set Type selection');
      expect(tester.takeException(), isNull);
    });
  }

  // All Set types share this 38dp filled badge in Create and Edit.
  // High-contrast mode reverses surface brightness and cannot reuse a fixed
  // semantic foreground safely.
  for (final mode in [
    TioThemeMode.light,
    TioThemeMode.dark,
    TioThemeMode.tioDark,
  ]) {
    for (final highContrast in [false, true]) {
      testWidgets('Set type contrast >= 4.5 in ${mode.name} '
          'highContrast=$highContrast for Create and Edit', (tester) async {
        tester.view.physicalSize = const Size(320, 720);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        const id = '55555555-5555-4555-8555-555555555555';
        final baseColors = switch (mode) {
          TioThemeMode.light => TioColors.light,
          TioThemeMode.dark => TioColors.oled,
          TioThemeMode.tioDark => TioColors.dark,
          TioThemeMode.system => throw StateError('Explicit test mode required'),
        };
        final expectedColors = highContrast ? baseColors.highContrast : baseColors;

        for (final showPrevious in [false, true]) {
          for (final setType in RoutineSetType.values) {
            await tester.pumpWidget(MaterialApp(
              builder: (context, child) => TioTheme(
                config: TioThemeConfig(mode: mode, highContrast: highContrast),
                child: child ?? const SizedBox.shrink(),
              ),
              home: Scaffold(
                body: RoutineSetInputRow(
                  set: RoutineCompositionSet(
                    id: id,
                    prescription: SetPrescription(reps: 8, setType: setType),
                  ),
                  index: 0,
                  normalNumber: 1,
                  unit: WeightUnit.kg,
                  enabled: true,
                  showPrevious: showPrevious,
                  isOpen: false,
                  onTypePressed: () {},
                  onOpenChanged: (_) {},
                  onChanged: (_) {},
                  onValidityChanged: (_) {},
                  onRemove: () {},
                ),
              ),
            ));
            final box = find.byKey(const ValueKey('routine-set-type-box-$id'));
            final surface = tester.widget<Container>(box).decoration! as BoxDecoration;
            expect(surface.color, expectedColors.surfaceVariant);
            final badgeText = tester.widget<Text>(
              find.descendant(of: box, matching: find.byType(Text)),
            );
            final ink = badgeText.style!.color!;
            final contrastRatio = _contrastRatio(ink, surface.color!);
            expect(contrastRatio, greaterThanOrEqualTo(4.5),
                reason: '${mode.name}, highContrast=$highContrast, '
                    'showPrevious=$showPrevious, setType=${setType.name}');
            expect(tester.getSize(box).width, TioSize.dp38);
            expect(tester.getSize(box).height, TioSize.dp38);
            if (showPrevious && setType == RoutineSetType.normal && !highContrast) {
              expect(ink, expectedColors.primary,
                  reason: 'Keep the current Edit number color where readable');
            }
            expect(tester.takeException(), isNull);
          }
        }
      });
    }
  }

  testWidgets('inline row preserves kg when lb display is unchanged', (tester) async {
    final values = <SetPrescription>[];
    final validity = <bool>[];
    const id = '55555555-5555-4555-8555-555555555555';
    await tester.pumpWidget(MaterialApp(
      builder: (context, child) => TioTheme(
        config: const TioThemeConfig(mode: TioThemeMode.dark),
        child: child ?? const SizedBox.shrink(),
      ),
      home: Scaffold(body: RoutineSetInputRow(
        set: RoutineCompositionSet(id: id,
          prescription: SetPrescription(reps: 8, loadKg: 12.54321, restSeconds: 60)),
        index: 0,
        normalNumber: 1,
        onTypePressed: () {},
        unit: WeightUnit.lb,
        enabled: true,
        isOpen: false,
        onOpenChanged: (_) {},
        onChanged: values.add,
        onValidityChanged: validity.add,
        onRemove: () {},
      )),
    ));
    final reps = find.byKey(const ValueKey('routine-set-reps-$id'));
    await tester.enterText(reps, '');
    await tester.pump();
    // Empty targets are a valid nullable Routine prescription.
    expect(validity, isEmpty);
    expect(values.single.reps, isNull);
    await tester.enterText(reps, '10');
    await tester.pump();
    expect(validity, isEmpty);
    expect(values.last.reps, 10);
    expect(values.last.loadKg, 12.54321);
    expect(values.last.restSeconds, 60);
  });

  testWidgets('unspecified Range shows Min/Max without fabricating Reps',
      (tester) async {
    const id = '55555555-5555-4555-8555-555555555555';
    final edits = <SetPrescription>[];
    final valid = <bool>[];
    await tester.pumpWidget(MaterialApp(
      builder: (context, child) => TioTheme(
        config: const TioThemeConfig(mode: TioThemeMode.dark),
        child: child ?? const SizedBox.shrink(),
      ),
      home: Scaffold(body: RoutineSetInputRow(
        set: RoutineCompositionSet(
          id: id, prescription: SetPrescription()),
        index: 0,
        normalNumber: 1,
        onTypePressed: () {},
        unit: WeightUnit.kg,
        enabled: true,
        showRangeDraft: true,
        isOpen: false,
        onOpenChanged: (_) {},
        onChanged: edits.add,
        onValidityChanged: valid.add,
        onRemove: () {},
      )),
    ));
    final min = find.byKey(const ValueKey('routine-set-reps-$id'));
    final max = find.byKey(const ValueKey('routine-set-reps-max-$id'));
    expect(min, findsOneWidget);
    expect(max, findsOneWidget);
    expect(tester.widget<TioInput>(min).controller!.text, isEmpty);
    expect(tester.widget<TioInput>(max).controller!.text, isEmpty);
    expect(edits, isEmpty);
    expect(valid, isEmpty);
    await tester.enterText(max, '12');
    await tester.pump();
    expect(valid.last, isFalse);
    expect(edits, isEmpty);
    await tester.enterText(min, '8');
    await tester.pump();
    expect(valid.last, isTrue);
    expect(edits.single.reps, 8);
    expect(edits.single.repsMax, 12);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'Edit range shows distinct outlined Min/Max and Previous at 320dp',
      (tester) async {
    tester.view.physicalSize = const Size(320, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    const id = '55555555-5555-4555-8555-555555555555';
    await tester.pumpWidget(MaterialApp(
      builder: (context, child) => TioTheme(
        config: const TioThemeConfig(mode: TioThemeMode.dark),
        child: child ?? const SizedBox.shrink(),
      ),
      home: Scaffold(
        body: RoutineSetInputRow(
          set: RoutineCompositionSet(
            id: id,
            prescription: SetPrescription(
              reps: 8,
              repsMax: 12,
              loadKg: 20,
            ),
          ),
          index: 0,
          normalNumber: 1,
          onTypePressed: () {},
          unit: WeightUnit.kg,
          enabled: true,
          showPrevious: true,
          isOpen: false,
          onOpenChanged: (_) {},
          onChanged: (_) {},
          onValidityChanged: (_) {},
          onRemove: () {},
        ),
      ),
    ));
    for (final suffix in ['weight', 'reps', 'reps-max']) {
      final input = find.byKey(ValueKey('routine-set-$suffix-$id'));
      expect(input, findsOneWidget);
      final field = tester.widget<TextField>(find.descendant(
        of: input,
        matching: find.byType(TextField),
      ));
      expect(tester.widget<TioInput>(input).variant,
          TioInputVariant.boxedNumber);
      expect(field.decoration!.enabledBorder, isA<OutlineInputBorder>());
      expect(field.decoration!.focusedBorder, isA<OutlineInputBorder>());
      expect(field.decoration!.hintText, '–');
      expect(field.textAlign, TextAlign.center);
      expect(tester.getSize(input).height, TioSize.dp38);
      final outline = find.descendant(
        of: input, matching: find.byType(InputDecorator),
      );
      expect(outline, findsOneWidget);
      expect(tester.getSize(outline).height, TioSize.dp38);
    }
    expect(find.byKey(const ValueKey('routine-set-range-separator-$id')),
        findsOneWidget);
    // The Edit/PREVIOUS Rep Range already occupies the full available row.
    final swipe = find.byKey(const ValueKey('routine-set-swipe-$id'));
    expect(tester.getTopRight(
        find.byKey(const ValueKey('routine-set-reps-max-$id'))).dx,
        closeTo(tester.getTopRight(swipe).dx, 0.01));
    expect(find.text('to'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('External Set edit refreshes inline values without overwriting weight',
      (tester) async {
    const id = '55555555-5555-4555-8555-555555555555';
    final current = ValueNotifier<SetPrescription>(
      SetPrescription(reps: 8, loadKg: 12.5, restSeconds: 60),
    );
    addTearDown(current.dispose);
    final emitted = <SetPrescription>[];
    await tester.pumpWidget(MaterialApp(
      builder: (context, child) => TioTheme(
        config: const TioThemeConfig(mode: TioThemeMode.light),
        child: child ?? const SizedBox.shrink(),
      ),
      home: Scaffold(body: ValueListenableBuilder<SetPrescription>(
        valueListenable: current,
        builder: (_, prescription, __) => RoutineSetInputRow(
          set: RoutineCompositionSet(id: id, prescription: prescription),
          index: 0,
          normalNumber: 1,
          onTypePressed: () {},
          unit: WeightUnit.kg,
          enabled: true,
          isOpen: false,
          onOpenChanged: (_) {},
          onChanged: (next) {
            emitted.add(next);
            current.value = next;
          },
          onValidityChanged: (_) {},
          onRemove: () {},
        ),
      )),
    ));
    current.value = SetPrescription(reps: 14, loadKg: 32.75, restSeconds: 45);
    await tester.pump();
    await tester.pump();
    final reps = find.byKey(const ValueKey('routine-set-reps-$id'));
    final weight = find.byKey(const ValueKey('routine-set-weight-$id'));
    expect(tester.widget<TioInput>(reps).controller!.text, '14');
    expect(tester.widget<TioInput>(weight).controller!.text, '32.75');
    expect(emitted, isEmpty);
    await tester.enterText(reps, '15');
    await tester.pump();
    expect(emitted.last.reps, 15);
    expect(emitted.last.loadKg, 32.75);
    expect(emitted.last.restSeconds, 45);
  });

  testWidgets('inline echo marker is consumed before later sheet round-trip',
      (tester) async {
    const id = '55555555-5555-4555-8555-555555555555';
    final current = ValueNotifier<SetPrescription>(
      SetPrescription(reps: 8, loadKg: 10, restSeconds: 45),
    );
    addTearDown(current.dispose);
    final emitted = <SetPrescription>[];
    await tester.pumpWidget(MaterialApp(
      builder: (context, child) => TioTheme(
        config: const TioThemeConfig(mode: TioThemeMode.light),
        child: child ?? const SizedBox.shrink(),
      ),
      home: Scaffold(body: ValueListenableBuilder<SetPrescription>(
        valueListenable: current,
        builder: (_, prescription, __) => RoutineSetInputRow(
          set: RoutineCompositionSet(id: id, prescription: prescription),
          index: 0,
          normalNumber: 1,
          onTypePressed: () {},
          unit: WeightUnit.kg,
          enabled: true,
          isOpen: false,
          onOpenChanged: (_) {},
          onChanged: (value) {
            emitted.add(value);
            current.value = value;
          },
          onValidityChanged: (_) {},
          onRemove: () {},
        ),
      )),
    ));
    final reps = find.byKey(const ValueKey('routine-set-reps-$id'));
    final weight = find.byKey(const ValueKey('routine-set-weight-$id'));

    // The immediate parent rebuild is the one and only local echo.
    await tester.enterText(weight, '20');
    await tester.pump();
    expect(current.value.loadKg, 20);
    // Two later external advanced-sheet values, the second equals an
    // earlier inline edit but is NOT a stale echo.
    current.value = SetPrescription(reps: 8, loadKg: 30, restSeconds: 45);
    await tester.pump();
    expect(tester.widget<TioInput>(weight).controller!.text, '30');
    current.value = SetPrescription(reps: 8, loadKg: 20, restSeconds: 45);
    await tester.pump();
    expect(tester.widget<TioInput>(weight).controller!.text, '20');
    await tester.enterText(reps, '9');
    await tester.pump();
    expect(emitted.last.reps, 9);
    expect(emitted.last.loadKg, 20);
    expect(emitted.last.restSeconds, 45);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Switching typed fixed Reps to range requires explicit Max',
      (tester) async {
    const id = '55555555-5555-4555-8555-555555555555';
    final current = ValueNotifier<SetPrescription>(
      SetPrescription(reps: 8),
    );
    addTearDown(current.dispose);
    final validity = <bool>[];
    await tester.pumpWidget(MaterialApp(
      builder: (context, child) => TioTheme(
        config: const TioThemeConfig(mode: TioThemeMode.light),
        child: child ?? const SizedBox.shrink(),
      ),
      home: Scaffold(body: ValueListenableBuilder<SetPrescription>(
        valueListenable: current,
        builder: (_, prescription, __) => RoutineSetInputRow(
          set: RoutineCompositionSet(id: id, prescription: prescription),
          index: 0,
          normalNumber: 1,
          onTypePressed: () {},
          unit: WeightUnit.kg,
          enabled: true,
          isOpen: false,
          onOpenChanged: (_) {},
          onChanged: (next) => current.value = next,
          onValidityChanged: validity.add,
          onRemove: () {},
        ),
      )),
    ));

    // The domain model uses a provisional Max to represent range mode,
    // but no user has typed that Max in this row.
    current.value = SetPrescription(reps: 8, repsMax: 8);
    await tester.pump();
    await tester.pump();
    final max = find.byKey(const ValueKey('routine-set-reps-max-$id'));
    expect(tester.widget<TioInput>(max).controller!.text, isEmpty);
    expect(validity.last, isFalse);

    await tester.enterText(max, '12');
    await tester.pump();
    expect(validity.last, isTrue);
    expect(current.value.reps, 8);
    expect(current.value.repsMax, 12);
  });

  testWidgets('Treadmill uses optional KM/TIME with canonical meters and seconds',
      (tester) async {
    const id = '55555555-5555-4555-8555-555555555555';
    final current = ValueNotifier<SetPrescription>(SetPrescription());
    addTearDown(current.dispose);
    final validity = <bool>[];
    await tester.pumpWidget(MaterialApp(
      builder: (context, child) => TioTheme(
        config: const TioThemeConfig(mode: TioThemeMode.dark),
        child: child ?? const SizedBox.shrink(),
      ),
      home: Scaffold(body: ValueListenableBuilder<SetPrescription>(
        valueListenable: current,
        builder: (_, value, __) => RoutineSetInputRow(
          set: RoutineCompositionSet(id: id, prescription: value),
          index: 0,
          normalNumber: 1,
          onTypePressed: () {},
          unit: WeightUnit.kg,
          exerciseType: ExerciseType.distanceDuration,
          enabled: true,
          isOpen: false,
          onOpenChanged: (_) {},
          onChanged: (value) => current.value = value,
          onValidityChanged: validity.add,
          onRemove: () {},
        ),
      )),
    ));
    expect(find.byKey(const ValueKey('routine-set-weight-$id')), findsNothing);
    expect(find.byKey(const ValueKey('routine-set-reps-$id')), findsNothing);
    final km = find.byKey(const ValueKey('routine-set-distance-$id'));
    final time = find.byKey(const ValueKey('routine-set-duration-$id'));
    expect(tester.widget<TioInput>(km).controller!.text, isEmpty);
    expect(tester.widget<TioInput>(time).controller!.text, isEmpty);
    final swipe = find.byKey(const ValueKey('routine-set-swipe-$id'));
    expect(tester.getTopRight(time).dx,
        closeTo(tester.getTopRight(swipe).dx, 0.01));
    for (final input in [km, time]) {
      final outline = find.descendant(
        of: input, matching: find.byType(InputDecorator),
      );
      expect(outline, findsOneWidget);
      expect(tester.getSize(outline).height, TioSize.dp38);
    }
    await tester.enterText(km, '2.5');
    await tester.pump();
    expect(current.value.distanceMeters, 2500.0);
    expect(current.value.durationSeconds, isNull);
    expect(current.value.reps, isNull);
    await tester.enterText(time, '15:05');
    await tester.pump();
    expect(current.value.durationSeconds, 905);
    await tester.enterText(time, '15:');
    await tester.pump();
    expect(validity.last, isFalse);
    expect(current.value.durationSeconds, 905);
    await tester.enterText(time, '');
    await tester.pump();
    expect(validity.last, isTrue);
    expect(current.value.durationSeconds, isNull);
    expect(current.value.distanceMeters, 2500.0);
  });

  testWidgets('TIME-only Set hides KG/REPS/KM and preserves optional duration',
      (tester) async {
    const id = '55555555-5555-4555-8555-555555555555';
    final current = ValueNotifier<SetPrescription>(SetPrescription());
    addTearDown(current.dispose);
    await tester.pumpWidget(MaterialApp(
      builder: (context, child) => TioTheme(
        config: const TioThemeConfig(mode: TioThemeMode.light),
        child: child ?? const SizedBox.shrink(),
      ),
      home: Scaffold(body: ValueListenableBuilder<SetPrescription>(
        valueListenable: current,
        builder: (_, value, __) => RoutineSetInputRow(
          set: RoutineCompositionSet(id: id, prescription: value),
          index: 0,
          normalNumber: 1,
          onTypePressed: () {},
          unit: WeightUnit.kg,
          exerciseType: ExerciseType.duration,
          enabled: true,
          isOpen: false,
          onOpenChanged: (_) {},
          onChanged: (value) => current.value = value,
          onValidityChanged: (_) {},
          onRemove: () {},
        ),
      )),
    ));
    for (final hidden in ['weight', 'reps', 'distance']) {
      expect(find.byKey(ValueKey('routine-set-$hidden-$id')), findsNothing);
    }
    final time = find.byKey(const ValueKey('routine-set-duration-$id'));
    expect(time, findsOneWidget);
    // TIME-only Set remains full width when no KG/REPS fields are present.
    final swipe = find.byKey(const ValueKey('routine-set-swipe-$id'));
    expect(tester.getTopRight(time).dx,
        closeTo(tester.getTopRight(swipe).dx, 0.01));
    final timeOutline = find.descendant(
      of: time, matching: find.byType(InputDecorator),
    );
    expect(timeOutline, findsOneWidget);
    expect(tester.getSize(timeOutline).height, TioSize.dp38);
    await tester.enterText(time, '1:30');
    await tester.pump();
    expect(current.value.durationSeconds, 90);
    expect(current.value.reps, isNull);
    expect(current.value.loadKg, isNull);
    expect(current.value.distanceMeters, isNull);
  });

  testWidgets('Create fixed Set has outlined blank Reps without fabricated Max',
      (tester) async {
    tester.view.physicalSize = const Size(320, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    const id = '55555555-5555-4555-8555-555555555555';
    await tester.pumpWidget(MaterialApp(
      builder: (context, child) => TioTheme(
        config: const TioThemeConfig(mode: TioThemeMode.light),
        child: child ?? const SizedBox.shrink(),
      ),
      home: Scaffold(
        body: RoutineSetInputRow(
          set: RoutineCompositionSet(
            id: id,
            prescription: SetPrescription(reps: 1),
          ),
          index: 0,
          normalNumber: 1,
          onTypePressed: () {},
          unit: WeightUnit.kg,
          enabled: true,
          startWithBlankReps: true,
          isOpen: false,
          onOpenChanged: (_) {},
          onChanged: (_) {},
          onValidityChanged: (_) {},
          onRemove: () {},
        ),
      ),
    ));
    final reps = find.byKey(const ValueKey('routine-set-reps-$id'));
    final cell = tester.widget<TioInput>(reps);
    expect(cell.controller!.text, isEmpty);
    expect(cell.textAlign, TextAlign.center);
    expect(cell.variant, TioInputVariant.boxedNumber);
    expect(find.byKey(const ValueKey('routine-set-reps-max-$id')),
        findsNothing);
    expect(find.byKey(const ValueKey('routine-set-range-separator-$id')),
        findsNothing);
    final field = tester.widget<TextField>(find.descendant(
      of: reps,
      matching: find.byType(TextField),
    ));
    expect(field.decoration!.enabledBorder, isA<OutlineInputBorder>());
    expect(tester.takeException(), isNull);
  });
}

double _contrastRatio(Color first, Color second) {
  final a = first.computeLuminance();
  final b = second.computeLuminance();
  return a > b ? (a + 0.05) / (b + 0.05) : (b + 0.05) / (a + 0.05);
}
