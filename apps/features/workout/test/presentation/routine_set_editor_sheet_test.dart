import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tio_core/core.dart';
import 'package:tio_feature_workout/src/presentation/library/routines/routine_set_editor_sheet.dart';
import 'package:tio_shared/shared.dart';

void main() {
  testWidgets('missing optional Rest opens blank and saves without edits',
      (tester) async {
    SetPrescription? confirmed;
    await tester.pumpWidget(MaterialApp(
      builder: (context, child) => TioTheme(
        config: const TioThemeConfig(mode: TioThemeMode.light),
        child: child ?? const SizedBox.shrink(),
      ),
      home: Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              confirmed = await showTioEditorSheet<SetPrescription>(
                context: context,
                useSafeArea: true,
                builder: (_) => RoutineSetEditorSheet(
                  unit: WeightUnit.kg,
                  initial: SetPrescription(
                    reps: 8,
                    loadKg: 20,
                    restSeconds: null,
                  ),
                ),
              );
            },
            child: const Text('Open Set details'),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('Open Set details'));
    await tester.pumpAndSettle();

    final rest = find.byKey(const ValueKey('routine-set-rest'));
    expect(rest, findsOneWidget);
    expect(tester.widget<TioInput>(rest).controller!.text, isEmpty);

    await tester.tap(find.text('Save Set'));
    await tester.pumpAndSettle();
    expect(confirmed, isNotNull);
    expect(confirmed!.reps, 8);
    expect(confirmed!.loadKg, 20);
    expect(confirmed!.restSeconds, isNull);
    expect(find.byKey(const ValueKey('routine-set-validation-error')),
        findsNothing);
    expect(tester.takeException(), isNull);
  });
}
