import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tio_core/core.dart';

void main() {
  Widget buildTestApp(Widget child) {
    return MaterialApp(
      theme: ThemeData(
        extensions: const [TioColors.light],
      ),
      home: Scaffold(
        body: child,
      ),
    );
  }

  Widget buildTioThemedTestApp(Widget child) {
    return MaterialApp(
      builder: (context, child) =>
          TioTheme(child: child ?? const SizedBox.shrink()),
      home: Scaffold(body: child),
    );
  }

  group('TioInput', () {
    testWidgets('renders standard input field with label and placeholder',
        (tester) async {
      var changedValue = '';
      await tester.pumpWidget(
        buildTestApp(
          TioInput(
            label: 'Email',
            hint: 'user@example.com',
            onChanged: (val) => changedValue = val,
          ),
        ),
      );

      expect(find.text('Email'), findsOneWidget);
      expect(find.text('user@example.com'), findsOneWidget);

      await tester.enterText(find.byType(TextFormField), 'hello@tio.fit');
      expect(changedValue, 'hello@tio.fit');
    });

    testWidgets(
        'renders compactNumber variant with bold text and center alignment',
        (tester) async {
      var changedNumber = '';
      await tester.pumpWidget(
        buildTestApp(
          TioInput.compactNumber(
            value: '12',
            hint: '0',
            onChanged: (val) => changedNumber = val,
          ),
        ),
      );

      expect(find.text('12'), findsOneWidget);

      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.textAlign, TextAlign.center);
      expect(textField.keyboardType,
          const TextInputType.numberWithOptions(decimal: true));

      await tester.enterText(find.byType(TextFormField), '15');
      expect(changedNumber, '15');
    });

    testWidgets('compactNumber selectAllOnFocus selects text when focused',
        (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          TioInput.compactNumber(
            value: '80',
            onChanged: (_) {},
          ),
        ),
      );

      await tester.tap(find.byType(TextFormField));
      await tester.pumpAndSettle();

      final editableText =
          tester.widget<EditableText>(find.byType(EditableText));
      expect(editableText.controller.selection.baseOffset, 0);
      expect(editableText.controller.selection.extentOffset, 2);
    });

    testWidgets(
        'numericEditor preserves dense exact-entry presentation and behavior',
        (tester) async {
      var submitted = '';
      await tester.pumpWidget(
        buildTioThemedTestApp(
          TioInput.numericEditor(
            value: '28',
            hint: 'Not set',
            suffixText: 'g',
            autofocus: true,
            onChanged: (_) {},
            onSubmitted: (value) => submitted = value,
          ),
        ),
      );

      final component = tester.widget<TioInput>(find.byType(TioInput));
      final field = tester.widget<TextField>(find.byType(TextField));
      final decoration = field.decoration!;

      expect(component.variant, TioInputVariant.numericEditor);
      expect(field.textAlign, TextAlign.start);
      expect(
        field.keyboardType,
        const TextInputType.numberWithOptions(decimal: true),
      );
      expect(field.textInputAction, TextInputAction.done);
      expect(field.autofocus, isTrue);
      expect(field.enabled, isTrue);
      expect(decoration.isDense, isTrue);
      expect(decoration.hintText, 'Not set');
      expect(decoration.hintStyle!.fontSize,
          TioInputTokens.numericEditorHintFontSize);
      expect(decoration.hintStyle!.color, TioColors.light.textMuted);
      expect(decoration.suffixText, 'g');
      expect(decoration.suffixStyle!.fontSize,
          TioInputTokens.numericEditorSuffixFontSize);
      expect(decoration.suffixStyle!.color, TioColors.light.textSecondary);
      expect(field.style!.fontSize, TioInputTokens.numericEditorTextFontSize);
      expect(field.style!.fontWeight, TioFontWeight.w700);
      expect(field.style!.color, TioColors.light.textPrimary);
      expect(decoration.filled, isTrue,
          reason: 'retains the active TioTheme fill behavior');
      expect(decoration.contentPadding, isNull,
          reason: 'dense padding remains owned by the active theme');

      final effectiveDecoration =
          tester.widget<InputDecorator>(find.byType(InputDecorator)).decoration;
      final effectiveBorder =
          effectiveDecoration.enabledBorder! as OutlineInputBorder;
      expect(
        effectiveBorder.borderRadius,
        BorderRadius.circular(TioInputTokens.radius),
      );
      expect(effectiveDecoration.filled, isTrue,
          reason: 'matches the previous raw dense editor fill behavior');

      final editableText =
          tester.widget<EditableText>(find.byType(EditableText));
      expect(editableText.controller.selection,
          const TextSelection.collapsed(offset: 2),
          reason: 'numericEditor must not inherit select-all table behavior');

      await tester.testTextInput.receiveAction(TextInputAction.done);
      expect(submitted, '28');
    });

    testWidgets('numericEditor forwards formatter and enabled state',
        (tester) async {
      var changed = '';
      await tester.pumpWidget(
        buildTestApp(
          TioInput.numericEditor(
            onChanged: (value) => changed = value,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          ),
        ),
      );

      await tester.enterText(find.byType(TextFormField), '1a2b');
      expect(changed, '12');

      await tester.pumpWidget(
        buildTestApp(
          TioInput.numericEditor(
            enabled: false,
            onChanged: (_) {},
          ),
        ),
      );

      expect(tester.widget<TextField>(find.byType(TextField)).enabled, isFalse);
    });

    testWidgets('renders error text when provided', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          TioInput(
            value: 'invalid',
            errorText: 'Invalid email address',
            onChanged: (_) {},
          ),
        ),
      );

      expect(find.text('Invalid email address'), findsOneWidget);
    });
  });

  // Phase #24-A: five additive optional parameters. Each test proves the value
  // reaches the underlying field, and that omitting it leaves today's
  // behaviour untouched — this slice migrates no consumer and is intended to
  // change nothing that currently renders.
  group('TioInput API foundation', () {
    group('validator', () {
      testWidgets('is forwarded to the underlying form field', (tester) async {
        String? seen;
        await tester.pumpWidget(
          buildTestApp(
            Form(
              child: TioInput(
                value: 'abc',
                onChanged: (_) {},
                validator: (v) {
                  seen = v;
                  return 'always invalid';
                },
              ),
            ),
          ),
        );

        final form = tester.state<FormState>(find.byType(Form));
        expect(form.validate(), isFalse);
        await tester.pump();

        expect(seen, 'abc', reason: 'validator receives the field value');
        expect(find.text('always invalid'), findsOneWidget);
      });

      testWidgets('omitting it introduces no validation behaviour',
          (tester) async {
        await tester.pumpWidget(
          buildTestApp(
            Form(child: TioInput(value: 'abc', onChanged: (_) {})),
          ),
        );

        final form = tester.state<FormState>(find.byType(Form));
        expect(form.validate(), isTrue,
            reason: 'a field with no validator never fails validation');
      });

      testWidgets('does not validate until the form asks', (tester) async {
        var calls = 0;
        await tester.pumpWidget(
          buildTestApp(
            Form(
              child: TioInput(
                onChanged: (_) {},
                validator: (_) {
                  calls++;
                  return null;
                },
              ),
            ),
          ),
        );

        await tester.enterText(find.byType(TextFormField), 'typing');
        await tester.pump();

        // No autovalidateMode is exposed, so merely typing must not validate.
        expect(calls, 0);
      });
    });

    testWidgets('autofillHints are forwarded exactly', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          TioInput(
            onChanged: (_) {},
            autofillHints: const [AutofillHints.email],
          ),
        ),
      );

      final field = tester.widget<TextField>(find.byType(TextField));
      expect(field.autofillHints, const [AutofillHints.email]);
    });

    testWidgets('inputFormatters are honored by the underlying input',
        (tester) async {
      var changed = '';
      await tester.pumpWidget(
        buildTestApp(
          TioInput(
            onChanged: (v) => changed = v,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          ),
        ),
      );

      await tester.enterText(find.byType(TextFormField), 'a1b2c3');
      expect(changed, '123', reason: 'non-digits are filtered out');
    });

    testWidgets('textCapitalization is forwarded, defaulting to none',
        (tester) async {
      await tester.pumpWidget(
        buildTestApp(TioInput(onChanged: (_) {})),
      );
      expect(
        tester.widget<TextField>(find.byType(TextField)).textCapitalization,
        TextCapitalization.none,
      );

      await tester.pumpWidget(
        buildTestApp(
          TioInput(
            onChanged: (_) {},
            textCapitalization: TextCapitalization.sentences,
          ),
        ),
      );
      expect(
        tester.widget<TextField>(find.byType(TextField)).textCapitalization,
        TextCapitalization.sentences,
      );
    });

    testWidgets('suffixText is configured when supplied', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          TioInput(
            value: '2000',
            onChanged: (_) {},
            suffixText: 'kcal',
          ),
        ),
      );

      final decoration =
          tester.widget<TextField>(find.byType(TextField)).decoration!;
      expect(decoration.suffixText, 'kcal');
    });

    testWidgets('no suffix or prefix is added by default', (tester) async {
      await tester.pumpWidget(
        buildTestApp(TioInput(value: '2000', onChanged: (_) {})),
      );

      final decoration =
          tester.widget<TextField>(find.byType(TextField)).decoration!;
      expect(decoration.suffixText, isNull);
      // No prefix parameter is exposed, so the decoration must never gain one.
      expect(decoration.prefixText, isNull);
    });

    group('regression — defaults unchanged', () {
      testWidgets('standard geometry stays 14dp radius and 52dp min height',
          (tester) async {
        await tester.pumpWidget(buildTestApp(TioInput(onChanged: (_) {})));

        expect(TioInputTokens.radius, TioSize.dp14);
        expect(TioInputTokens.minHeight, TioSize.dp52);

        final border = tester
            .widget<TextField>(find.byType(TextField))
            .decoration!
            .enabledBorder! as OutlineInputBorder;
        expect(
          border.borderRadius,
          BorderRadius.circular(TioInputTokens.radius),
        );
      });

      testWidgets('leading and trailing still reach the decoration',
          (tester) async {
        await tester.pumpWidget(
          buildTestApp(
            TioInput(
              onChanged: (_) {},
              leading: const Icon(Icons.alternate_email),
              trailing: const Icon(Icons.check),
            ),
          ),
        );

        final decoration =
            tester.widget<TextField>(find.byType(TextField)).decoration!;
        expect(decoration.prefixIcon, isNotNull);
        expect(decoration.suffixIcon, isNotNull);
      });

      testWidgets('compactNumber still centers and uses a decimal keyboard',
          (tester) async {
        await tester.pumpWidget(
          buildTestApp(
            TioInput.compactNumber(value: '12', onChanged: (_) {}),
          ),
        );

        final field = tester.widget<TextField>(find.byType(TextField));
        expect(field.textAlign, TextAlign.center);
        expect(
          field.keyboardType,
          const TextInputType.numberWithOptions(decimal: true),
        );
        expect(field.textCapitalization, TextCapitalization.none);
        expect(field.decoration!.suffixText, isNull);
      });

      testWidgets('standard variant remains the default', (tester) async {
        await tester.pumpWidget(
          buildTestApp(TioInput(onChanged: (_) {})),
        );

        expect(
          tester.widget<TioInput>(find.byType(TioInput)).variant,
          TioInputVariant.standard,
        );
      });
    });
  });

  // Phase #24-C: TioInput.multiline, migrating the Workout notes-field
  // family (Equipment, Special Event, Health Concerns). Every property here
  // is evidenced by at least one real consumer -- see the task brief.
  group('TioInput.multiline', () {
    testWidgets('forwards maxLines and minLines exactly', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          TioInput.multiline(onChanged: (_) {}, maxLines: 6, minLines: 4),
        ),
      );

      final field = tester.widget<TextField>(find.byType(TextField));
      expect(field.maxLines, 6);
      expect(field.minLines, 4);
    });

    testWidgets('defaults textCapitalization to sentences', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          TioInput.multiline(onChanged: (_) {}, maxLines: 4, minLines: 3),
        ),
      );

      expect(
        tester.widget<TextField>(find.byType(TextField)).textCapitalization,
        TextCapitalization.sentences,
      );
    });

    testWidgets('textCapitalization default is still overridable',
        (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          TioInput.multiline(
            onChanged: (_) {},
            maxLines: 4,
            minLines: 3,
            textCapitalization: TextCapitalization.none,
          ),
        ),
      );

      expect(
        tester.widget<TextField>(find.byType(TextField)).textCapitalization,
        TextCapitalization.none,
      );
    });

    testWidgets(
        'uses the evidenced 16dp radius, distinct from the standard 14dp field',
        (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          TioInput.multiline(onChanged: (_) {}, maxLines: 4, minLines: 3),
        ),
      );

      final border = tester
          .widget<TextField>(find.byType(TextField))
          .decoration!
          .enabledBorder! as OutlineInputBorder;
      expect(
        border.borderRadius,
        BorderRadius.circular(TioInputTokens.multilineRadius),
      );
      expect(TioInputTokens.multilineRadius, isNot(TioInputTokens.radius),
          reason: 'multiline and standard are separate current contracts');
    });

    testWidgets('unfocused border uses a fixed alpha with no light/dark branch',
        (tester) async {
      Future<OutlineInputBorder> borderFor(TioThemeMode mode) async {
        await tester.pumpWidget(
          MaterialApp(
            builder: (context, child) => TioTheme(
              config: TioThemeConfig(mode: mode),
              child: child ?? const SizedBox.shrink(),
            ),
            home: Scaffold(
              body: TioInput.multiline(
                onChanged: (_) {},
                maxLines: 4,
                minLines: 3,
              ),
            ),
          ),
        );
        return tester
            .widget<TextField>(find.byType(TextField))
            .decoration!
            .enabledBorder! as OutlineInputBorder;
      }

      final lightBorder = await borderFor(TioThemeMode.light);
      final darkBorder = await borderFor(TioThemeMode.dark);

      // outlineStrong's own base colour legitimately differs between themes
      // -- only the alpha this component applies must stay theme-independent.
      expect(lightBorder.borderSide.color.a, darkBorder.borderSide.color.a,
          reason: 'the notes-field border alpha does not branch on theme, '
              'unlike the standard field');
      expect(lightBorder.borderSide.color.a, TioOpacity.opacity40);
    });

    testWidgets(
        'fills with the surface colour, matching the raw fields it replaces',
        (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          TioInput.multiline(onChanged: (_) {}, maxLines: 4, minLines: 3),
        ),
      );

      final decoration =
          tester.widget<TextField>(find.byType(TextField)).decoration!;
      expect(decoration.filled, isTrue);
      expect(decoration.fillColor, TioColors.light.surface);
    });

    testWidgets(
        'default content padding equals EdgeInsets.all(lg), matching two of '
        'three current consumers without an override', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          TioInput.multiline(onChanged: (_) {}, maxLines: 4, minLines: 3),
        ),
      );

      final decoration =
          tester.widget<TextField>(find.byType(TextField)).decoration!;
      expect(decoration.contentPadding, const EdgeInsets.all(TioSpacing.lg));
    });

    testWidgets(
        'contentPadding remains overridable for the one consumer '
        'that needs a different shape', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          TioInput.multiline(
            onChanged: (_) {},
            maxLines: 4,
            minLines: 3,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: TioSpacing.lg,
              vertical: TioSpacing.md,
            ),
          ),
        ),
      );

      final decoration =
          tester.widget<TextField>(find.byType(TextField)).decoration!;
      expect(
        decoration.contentPadding,
        const EdgeInsets.symmetric(
          horizontal: TioSpacing.lg,
          vertical: TioSpacing.md,
        ),
      );
    });

    testWidgets('hintStyle override replaces the computed default exactly',
        (tester) async {
      const override = TextStyle(fontSize: 14, color: Color(0xFF123456));
      await tester.pumpWidget(
        buildTestApp(
          TioInput.multiline(
            onChanged: (_) {},
            maxLines: 4,
            minLines: 3,
            hint: 'e.g. Knee pain, back ache, asthma...',
            hintStyle: override,
          ),
        ),
      );

      final decoration =
          tester.widget<TextField>(find.byType(TextField)).decoration!;
      expect(decoration.hintStyle, override);
    });

    testWidgets('omitting hintStyle falls back to the standard computed hint',
        (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          TioInput.multiline(onChanged: (_) {}, maxLines: 4, minLines: 3),
        ),
      );

      final decoration =
          tester.widget<TextField>(find.byType(TextField)).decoration!;
      expect(
          decoration.hintStyle!.fontSize, TioInputTokens.standardHintFontSize);
      expect(decoration.hintStyle!.color, TioColors.light.textMuted);
    });

    testWidgets(
        'textAlignVertical is null by default, matching the '
        'Equipment consumer that never set one', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          TioInput.multiline(onChanged: (_) {}, maxLines: 4, minLines: 3),
        ),
      );

      expect(
        tester.widget<TextField>(find.byType(TextField)).textAlignVertical,
        isNull,
      );
    });

    testWidgets('textAlignVertical.top is honored when supplied',
        (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          TioInput.multiline(
            onChanged: (_) {},
            maxLines: 4,
            minLines: 3,
            textAlignVertical: TextAlignVertical.top,
          ),
        ),
      );

      expect(
        tester.widget<TextField>(find.byType(TextField)).textAlignVertical,
        TextAlignVertical.top,
      );
    });

    testWidgets(
        'textInputAction is null by default, letting Flutter choose newline '
        'vs done from keyboardType exactly as the raw fields did',
        (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          TioInput.multiline(onChanged: (_) {}, maxLines: 4, minLines: 3),
        ),
      );

      expect(
        tester.widget<TextField>(find.byType(TextField)).textInputAction,
        isNull,
      );
    });

    testWidgets(
        'keyboardType defaults to text, matching the Equipment '
        'consumer that never set one', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          TioInput.multiline(onChanged: (_) {}, maxLines: 4, minLines: 3),
        ),
      );

      expect(
        tester.widget<TextField>(find.byType(TextField)).keyboardType,
        TextInputType.text,
      );
    });

    testWidgets('keyboardType.multiline is honored when supplied',
        (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          TioInput.multiline(
            onChanged: (_) {},
            maxLines: 4,
            minLines: 3,
            keyboardType: TextInputType.multiline,
          ),
        ),
      );

      expect(
        tester.widget<TextField>(find.byType(TextField)).keyboardType,
        TextInputType.multiline,
      );
    });

    testWidgets(
        'controller and value forwarding works like every other variant',
        (tester) async {
      var changed = '';
      final controller = TextEditingController(text: 'existing notes');
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        buildTestApp(
          TioInput.multiline(
            controller: controller,
            onChanged: (v) => changed = v,
            maxLines: 4,
            minLines: 3,
          ),
        ),
      );

      expect(find.text('existing notes'), findsOneWidget);

      await tester.enterText(find.byType(TextFormField), 'updated notes');
      expect(changed, 'updated notes');
      expect(controller.text, 'updated notes');
    });

    testWidgets('enabled false disables the field', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          TioInput.multiline(
            onChanged: (_) {},
            maxLines: 4,
            minLines: 3,
            enabled: false,
          ),
        ),
      );

      expect(tester.widget<TextField>(find.byType(TextField)).enabled, isFalse);
    });

    testWidgets('readOnly true prevents edits but keeps the field enabled',
        (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          TioInput.multiline(
            onChanged: (_) {},
            maxLines: 4,
            minLines: 3,
            readOnly: true,
          ),
        ),
      );

      final field = tester.widget<TextField>(find.byType(TextField));
      expect(field.readOnly, isTrue);
      expect(field.enabled, isTrue);
    });

    testWidgets(
        'inputFormatters and validator are forwarded like every other variant',
        (tester) async {
      var changed = '';
      await tester.pumpWidget(
        buildTestApp(
          Form(
            child: TioInput.multiline(
              onChanged: (v) => changed = v,
              maxLines: 4,
              minLines: 3,
              inputFormatters: [FilteringTextInputFormatter.deny(RegExp('x'))],
              validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
            ),
          ),
        ),
      );

      await tester.enterText(find.byType(TextFormField), 'oxk');
      expect(changed, 'ok', reason: 'the x is filtered out');

      final form = tester.state<FormState>(find.byType(Form));
      await tester.enterText(find.byType(TextFormField), '');
      expect(form.validate(), isFalse);
      await tester.pump();
      expect(find.text('Required'), findsOneWidget);
    });

    testWidgets(
        'does not affect standard, compactNumber or numericEditor defaults',
        (tester) async {
      // Regression: adding the multiline variant, and widening
      // textInputAction to nullable, must not change any existing variant's
      // rendered behaviour.
      await tester.pumpWidget(buildTestApp(TioInput(onChanged: (_) {})));
      var field = tester.widget<TextField>(find.byType(TextField));
      expect(field.textInputAction, TextInputAction.next);
      expect(
        (field.decoration!.enabledBorder! as OutlineInputBorder).borderRadius,
        BorderRadius.circular(TioInputTokens.radius),
      );

      await tester.pumpWidget(
        buildTestApp(TioInput.compactNumber(value: '1', onChanged: (_) {})),
      );
      field = tester.widget<TextField>(find.byType(TextField));
      expect(field.textInputAction, TextInputAction.next);

      await tester.pumpWidget(
        buildTioThemedTestApp(
          TioInput.numericEditor(value: '1', onChanged: (_) {}),
        ),
      );
      field = tester.widget<TextField>(find.byType(TextField));
      expect(field.textInputAction, TextInputAction.done);
    });
  });
}
