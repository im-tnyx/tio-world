import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tio_core/core.dart';
import 'package:tio_feature_workout/workout.dart';
import 'package:tio_shared/shared.dart';

void main() {
  testWidgets('Create reference empty state has disabled Save and Add exercise',
      (tester) async {
    final create = _Create();
    await tester.pumpWidget(MaterialApp(
      builder: (context, child) => TioTheme(
        config: TioThemeConfig(mode: TioThemeMode.dark),
        child: child ?? const SizedBox.shrink(),
      ),
      home: CreateRoutinePage(
        program: Program(
          id: ProgramId('11111111-1111-4111-8111-111111111111'),
          name: 'Program 1',
        ),
        initialName: 'Routine 1',
        createRepository: create,
        catalogRepository: _Catalog(),
        weightUnit: WeightUnit.kg,
      ),
    ));
    expect(find.text('Create Routine'), findsOneWidget);
    final name = find.descendant(
      of: find.byKey(const ValueKey('create-routine-name')),
      matching: find.byType(EditableText),
    );
    expect(tester.widget<EditableText>(name).controller.text, 'Routine 1');
    expect(find.textContaining('Get started by adding'), findsOneWidget);
    expect(find.byKey(const ValueKey('create-routine-add-exercise')),
        findsOneWidget);
    final save = tester.widget<TextButton>(
        find.byKey(const ValueKey('create-routine-save')));
    expect(save.onPressed, isNull);
    expect(create.calls, 0);
    await tester.tap(find.byKey(const ValueKey('create-routine-cancel')));
    await tester.pumpAndSettle();
    expect(create.calls, 0);
  });
}

class _Catalog extends Fake implements ExerciseCatalogRepository {}

class _Create extends Fake implements RoutineCreateRepository {
  int calls = 0;
  @override
  Future<int> create(RoutineCreateCommand command) async {
    calls++;
    return 1;
  }
}
