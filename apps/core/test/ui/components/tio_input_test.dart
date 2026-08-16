import 'package:flutter/material.dart';
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
    testWidgets('renders standard input field with label and placeholder', (tester) async {
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

    testWidgets('renders compactNumber variant with bold text and center alignment', (tester) async {
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
      expect(textField.keyboardType, const TextInputType.numberWithOptions(decimal: true));

      await tester.enterText(find.byType(TextFormField), '15');
      expect(changedNumber, '15');
    });

    testWidgets('compactNumber selectAllOnFocus selects text when focused', (tester) async {
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

      final editableText = tester.widget<EditableText>(find.byType(EditableText));
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
}
