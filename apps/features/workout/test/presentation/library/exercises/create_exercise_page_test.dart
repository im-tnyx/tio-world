import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tio_core/core.dart';
import 'package:tio_feature_workout/workout.dart';
import 'package:tio_shared/shared.dart';

Future<void> _pump(
  WidgetTester tester,
  UserExerciseRepository repository,
) async {
  await tester.pumpWidget(
    MaterialApp(
      builder: (context, child) => TioTheme(
        config: const TioThemeConfig(mode: TioThemeMode.light),
        child: child ?? const SizedBox.shrink(),
      ),
      home: CreateExercisePage(repository: repository),
    ),
  );
}

void main() {
  testWidgets('loads the durable source before showing the editor',
      (tester) async {
    final repository = _CreatePageRepository();
    await _pump(tester, repository);

    await tester.pump();
    expect(
      find.byKey(const ValueKey('create-exercise-loading')),
      findsOneWidget,
    );
    expect(find.byType(CustomExerciseEditorPage), findsNothing);

    repository.releaseLoad();
    await tester.pumpAndSettle();

    expect(find.byType(CustomExerciseEditorPage), findsOneWidget);
    expect(find.byType(ExercisesPage), findsNothing);
  });

  testWidgets('load failure stays on Create Exercise and Retry recovers',
      (tester) async {
    final repository = _CreatePageRepository(failFirstLoad: true);
    repository.releaseLoad();
    await _pump(tester, repository);
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('create-exercise-load-failure')),
      findsOneWidget,
    );
    expect(
      find.text('Could not load custom exercises. Please try again.'),
      findsOneWidget,
    );
    expect(find.byType(CustomExerciseEditorPage), findsNothing);

    await tester.tap(find.byKey(const ValueKey('create-exercise-retry')));
    await tester.pumpAndSettle();

    expect(find.byType(CustomExerciseEditorPage), findsOneWidget);
    expect(find.byType(ExercisesPage), findsNothing);
  });
}

final class _CreatePageRepository implements UserExerciseRepository {
  _CreatePageRepository({this.failFirstLoad = false});

  final bool failFirstLoad;
  final Completer<void> _loadGate = Completer<void>();
  var _loadCount = 0;

  void releaseLoad() {
    if (!_loadGate.isCompleted) _loadGate.complete();
  }

  @override
  Future<List<Exercise>> list({bool includeArchived = false}) async {
    _loadCount++;
    await _loadGate.future;
    if (failFirstLoad && _loadCount == 1) {
      throw StateError('synthetic load failure');
    }
    return const [];
  }

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
  }) async {}

  @override
  Future<void> archive(UserCreatedExerciseRef id) async {}
}
