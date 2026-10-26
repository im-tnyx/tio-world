import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tio_core/core.dart';
import 'package:tio_feature_progress/src/presentation/weight/progress_weight_log_sheet.dart';

void main() {
  testWidgets('owner deactivation removes root modal and private draft',
      (tester) async {
    final active = ValueNotifier<bool>(true);
    addTearDown(active.dispose);
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => TioTheme(
          config: const TioThemeConfig(mode: TioThemeMode.dark),
          child: child ?? const SizedBox.shrink(),
        ),
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => showProgressWeightLogSheet(
                context: context,
                unit: WeightUnit.kg,
                currentWeightKg: null,
                sessionActive: active,
                onSubmit: (_) async {},
              ),
              child: const Text('Open log'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open log'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('progress-log-save')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('progress-log-note-toggle')));
    await tester.pumpAndSettle();
    final note = find.descendant(
      of: find.byKey(const ValueKey('progress-log-note-field')),
      matching: find.byType(EditableText),
    );
    await tester.enterText(note, 'Private old-owner note');
    active.value = false;
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('tio-editor-sheet')), findsNothing);
    expect(find.text('Private old-owner note'), findsNothing);
    expect(find.text('Open log'), findsOneWidget);
    // A blank root modal would also hide its content. Assert the route itself
    // has been removed and no longer blocks the underlying application.
    final navigator = tester.state<NavigatorState>(find.byType(Navigator));
    expect(navigator.canPop(), isFalse);
  });
}
