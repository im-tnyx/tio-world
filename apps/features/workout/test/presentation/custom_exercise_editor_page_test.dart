import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tio_core/core.dart';
import 'package:tio_feature_workout/workout.dart';
import 'package:tio_shared/shared.dart';

Future<CustomExercisesController> _pumpEditor(
  WidgetTester tester, {
  Exercise? exercise,
  _FakeRepository? repository,
}) async {
  final effectiveRepository = repository ??
      _FakeRepository(
        exercises: exercise == null ? const [] : [exercise],
      );
  final controller =
      CustomExercisesController(repository: effectiveRepository);
  await controller.load();
  addTearDown(controller.dispose);

  await tester.pumpWidget(
    MaterialApp(
      builder: (context, child) => TioTheme(
        config: const TioThemeConfig(mode: TioThemeMode.light),
        child: child ?? const SizedBox.shrink(),
      ),
      home: CustomExerciseEditorPage(
        controller: controller,
        exercise: exercise,
      ),
    ),
  );
  await tester.pumpAndSettle();
  return controller;
}

void main() {
  testWidgets('editor renders approved definition fields', (tester) async {
    await _pumpEditor(tester);

    expect(find.byKey(const ValueKey('custom-exercise-editor')), findsOneWidget);
    expect(find.byKey(const ValueKey('custom-exercise-name')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('custom-exercise-description')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('custom-exercise-type-field')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('custom-exercise-primary-field')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('custom-exercise-secondary-field')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('custom-exercise-equipment-field')),
      findsOneWidget,
    );
  });

  testWidgets(
      'Primary muscle opens Body Part groups before any muscle options',
      (tester) async {
    await _pumpEditor(tester);

    await tester.tap(
      find.byKey(const ValueKey('custom-exercise-primary-field')),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('custom-exercise-primary-group-chest')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('custom-exercise-primary-group-back')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('custom-exercise-primary-group-shoulders')),
      findsOneWidget,
    );
    expect(
      find.byKey(
        const ValueKey('custom-exercise-primary-muscle-quadriceps'),
      ),
      findsNothing,
    );

    await tester.tap(
      find.byKey(const ValueKey('custom-exercise-primary-group-chest')),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(
        const ValueKey(
          'custom-exercise-primary-muscle-pectoralis_major_sternal_head',
        ),
      ),
      findsOneWidget,
    );
    expect(
      find.byKey(
        const ValueKey('custom-exercise-primary-muscle-quadriceps'),
      ),
      findsNothing,
    );
  });

  testWidgets('Exercise Type opens all approved choices in a bottom sheet',
      (tester) async {
    await _pumpEditor(tester);

    await tester.tap(
      find.byKey(const ValueKey('custom-exercise-type-field')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Exercise Type'), findsWidgets);
    expect(
      find.byKey(const ValueKey('custom-exercise-type-weight_reps')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('custom-exercise-type-steps_duration')),
      findsOneWidget,
    );
    expect(find.text('Weight & Reps'), findsOneWidget);
    expect(find.text('Steps & Duration'), findsOneWidget);
  });

  testWidgets('Secondary muscles uses the full-list multi-select sheet',
      (tester) async {
    await _pumpEditor(tester);

    await tester.tap(
      find.byKey(const ValueKey('custom-exercise-secondary-field')),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('custom-exercise-secondary-quadriceps')),
      findsOneWidget,
    );
    expect(
      find.byKey(
        const ValueKey('custom-exercise-secondary-latissimus_dorsi'),
      ),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('custom-exercise-secondary-done')),
      findsOneWidget,
    );
  });

  testWidgets('archive failure is visible from the archive viewport',
      (tester) async {
    final exercise = Exercise(
      ref: UserCreatedExerciseRef(
        '10000000-0000-4000-8000-000000000001',
      ),
      displayName: 'My Cable Row',
      status: ExerciseStatus.active,
    );
    final repository = _FakeRepository(
      exercises: [exercise],
      archiveError: Exception('network down'),
    );
    await _pumpEditor(
      tester,
      exercise: exercise,
      repository: repository,
    );

    await tester.drag(
      find.byKey(const ValueKey('custom-exercise-editor-list')),
      const Offset(0, -900),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('custom-exercise-archive')),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(TioButton, 'Archive'));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('custom-exercise-action-error')),
      findsOneWidget,
    );
    expect(
      find.text('Could not archive exercise. Please try again.'),
      findsWidgets,
    );
    expect(
      find.byKey(const ValueKey('custom-exercise-archive')),
      findsOneWidget,
    );
  });

  testWidgets('save failure is visible from a scrolled viewport',
      (tester) async {
    final exercise = Exercise(
      ref: UserCreatedExerciseRef(
        '10000000-0000-4000-8000-000000000002',
      ),
      displayName: 'My Tempo Squat',
      status: ExerciseStatus.active,
    );
    final repository = _FakeRepository(
      exercises: [exercise],
      updateDefinitionError: Exception('network down'),
    );
    await _pumpEditor(
      tester,
      exercise: exercise,
      repository: repository,
    );

    await tester.drag(
      find.byKey(const ValueKey('custom-exercise-editor-list')),
      const Offset(0, -700),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('custom-exercise-save')),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('custom-exercise-action-error')),
      findsOneWidget,
    );
    expect(
      find.text('Could not update exercise. Please try again.'),
      findsWidgets,
    );
  });

  testWidgets('Equipment opens approved single-select choices',
      (tester) async {
    await _pumpEditor(tester);

    await tester.tap(
      find.byKey(const ValueKey('custom-exercise-equipment-field')),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('custom-exercise-equipment-barbell')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('custom-exercise-equipment-trap_bar')),
      findsOneWidget,
    );
  });
}

final class _FakeRepository implements UserExerciseRepository {
  _FakeRepository({
    required List<Exercise> exercises,
    this.archiveError,
    this.updateDefinitionError,
  }) : exercises = [...exercises];

  final List<Exercise> exercises;
  final Object? archiveError;
  final Object? updateDefinitionError;

  @override
  Future<List<Exercise>> list({bool includeArchived = false}) async =>
      List<Exercise>.unmodifiable(
        exercises.where(
          (exercise) =>
              includeArchived || exercise.status == ExerciseStatus.active,
        ),
      );

  @override
  Future<void> create({
    required UserCreatedExerciseRef id,
    required String displayName,
    CatalogExerciseRef? basedOnCatalogExercise,
    UserExerciseDefinition? definition,
  }) async {}

  @override
  Future<void> rename({
    required UserCreatedExerciseRef id,
    required String displayName,
  }) async {}

  @override
  Future<void> updateDefinition({
    required UserCreatedExerciseRef id,
    required UserExerciseDefinition definition,
  }) async {
    final error = updateDefinitionError;
    if (error != null) throw error;
  }

  @override
  Future<void> archive(UserCreatedExerciseRef id) async {
    final error = archiveError;
    if (error != null) throw error;
  }
}
