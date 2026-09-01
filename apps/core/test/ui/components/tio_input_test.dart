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

  // Phase #24-A: six additive optional parameters. Each test proves the value
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

    testWidgets('prefixText and suffixText are configured when supplied',
        (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          TioInput(
            value: '2000',
            onChanged: (_) {},
            prefixText: '~',
            suffixText: 'kcal',
          ),
        ),
      );

      final decoration =
          tester.widget<TextField>(find.byType(TextField)).decoration!;
      expect(decoration.prefixText, '~');
      expect(decoration.suffixText, 'kcal');
    });

    testWidgets('no prefix or suffix is added by default', (tester) async {
      await tester.pumpWidget(
        buildTestApp(TioInput(value: '2000', onChanged: (_) {})),
      );

      final decoration =
          tester.widget<TextField>(find.byType(TextField)).decoration!;
      expect(decoration.prefixText, isNull);
      expect(decoration.suffixText, isNull);
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
    });
  });
}
